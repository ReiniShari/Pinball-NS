/*
 * mkzip.c - writes a zip archive of a directory tree, without compression, keeping the Unix
 * permissions (the executable of an iPhone or Mac app must stay executable in its .ipa or .zip).
 * Used by platform/ios/build_ipa.sh and platform/macos/build_mac.sh where no zip program is
 * installed (Windows).
 *
 *   mkzip out.zip DIR [EXEC_NAME...]   the files and folders under DIR, named relative to DIR;
 *                                      files called EXEC_NAME get the mode 0755, others 0644
 */
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef _WIN32
#include <windows.h>
#else
#include <dirent.h>
#include <sys/stat.h>
#endif

#define MAXE 4096

typedef struct { char *name; uint32_t crc, size, offset; uint32_t mode; } Entry;

static Entry ents[MAXE];
static int nents;
static char **execs;
static int nexecs;
static uint32_t crc_table[256];

static uint32_t crc32(uint32_t c, const uint8_t *p, size_t n)
{
    c = ~c;
    while (n--) c = crc_table[(c ^ *p++) & 255] ^ (c >> 8);
    return ~c;
}

static void put16(FILE *f, unsigned v) { fputc(v & 255, f); fputc((v >> 8) & 255, f); }
static void put32(FILE *f, uint32_t v) { put16(f, v & 0xFFFF); put16(f, v >> 16); }

static bool is_exec(const char *name)
{
    const char *b = strrchr(name, '/');
    b = b ? b + 1 : name;
    for (int i = 0; i < nexecs; i++) if (!strcmp(b, execs[i])) return true;
    return false;
}

static void add(const char *rel, bool dir)
{
    if (nents >= MAXE) { fprintf(stderr, "mkzip: too many files\n"); exit(1); }
    size_t n = strlen(rel);
    Entry *e = &ents[nents++];
    e->name = (char *)malloc(n + 2);
    memcpy(e->name, rel, n + 1);
    if (dir) { e->name[n] = '/'; e->name[n + 1] = 0; }
    e->mode = dir ? 040755 : is_exec(rel) ? 0100755 : 0100644;
}

/* the tree, folders before their contents, names sorted */
static int cmp(const void *a, const void *b) { return strcmp(*(char *const *)a, *(char *const *)b); }

static void walk(const char *root, const char *rel)
{
    char *names[MAXE];
    bool dirs[MAXE];
    int n = 0;
    char path[2048];
    snprintf(path, sizeof path, "%s%s%s", root, rel[0] ? "/" : "", rel);
#ifdef _WIN32
    char pat[2100];
    snprintf(pat, sizeof pat, "%s/*", path);
    WIN32_FIND_DATAA fd;
    HANDLE h = FindFirstFileA(pat, &fd);
    if (h == INVALID_HANDLE_VALUE) return;
    do {
        if (!strcmp(fd.cFileName, ".") || !strcmp(fd.cFileName, "..") || n >= MAXE) continue;
        names[n] = _strdup(fd.cFileName);
        dirs[n] = (fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0;
        n++;
    } while (FindNextFileA(h, &fd));
    FindClose(h);
#else
    DIR *d = opendir(path);
    if (!d) return;
    struct dirent *de;
    while ((de = readdir(d)) != NULL) {
        if (!strcmp(de->d_name, ".") || !strcmp(de->d_name, "..") || n >= MAXE) continue;
        char p[2300];
        snprintf(p, sizeof p, "%s/%s", path, de->d_name);
        struct stat st;
        if (stat(p, &st) != 0) continue;
        names[n] = strdup(de->d_name);
        dirs[n] = S_ISDIR(st.st_mode);
        n++;
    }
    closedir(d);
#endif
    /* sort names (keeping the folder flags with them) */
    for (int i = 1; i < n; i++)
        for (int j = i; j > 0 && cmp(&names[j - 1], &names[j]) > 0; j--) {
            char *t = names[j]; names[j] = names[j - 1]; names[j - 1] = t;
            bool u = dirs[j]; dirs[j] = dirs[j - 1]; dirs[j - 1] = u;
        }
    for (int i = 0; i < n; i++) {
        char r[2048];
        snprintf(r, sizeof r, "%s%s%s", rel, rel[0] ? "/" : "", names[i]);
        add(r, dirs[i]);
        if (dirs[i]) walk(root, r);
        free(names[i]);
    }
}

int main(int argc, char **argv)
{
    if (argc < 3) { fprintf(stderr, "usage: mkzip out.zip DIR [EXEC_NAME...]\n"); return 2; }
    for (uint32_t i = 0; i < 256; i++) {
        uint32_t c = i;
        for (int k = 0; k < 8; k++) c = (c & 1) ? 0xEDB88320u ^ (c >> 1) : c >> 1;
        crc_table[i] = c;
    }
    execs = argv + 3;
    nexecs = argc - 3;
    walk(argv[2], "");
    FILE *out = fopen(argv[1], "wb");
    if (!out) { fprintf(stderr, "mkzip: cannot write %s\n", argv[1]); return 1; }
    uint32_t off = 0;
    for (int i = 0; i < nents; i++) {
        Entry *e = &ents[i];
        uint8_t *data = NULL;
        size_t size = 0;
        if (e->name[strlen(e->name) - 1] != '/') {
            char p[2300];
            snprintf(p, sizeof p, "%s/%s", argv[2], e->name);
            FILE *f = fopen(p, "rb");
            if (!f) { fprintf(stderr, "mkzip: cannot read %s\n", p); return 1; }
            fseek(f, 0, SEEK_END);
            size = (size_t)ftell(f);
            fseek(f, 0, SEEK_SET);
            data = (uint8_t *)malloc(size ? size : 1);
            if (fread(data, 1, size, f) != size) { fprintf(stderr, "mkzip: cannot read %s\n", p); return 1; }
            fclose(f);
        }
        e->crc = crc32(0, data, size);
        e->size = (uint32_t)size;
        e->offset = off;
        unsigned nl = (unsigned)strlen(e->name);
        put32(out, 0x04034B50); put16(out, 10); put16(out, 0); put16(out, 0);   /* stored */
        put16(out, 0); put16(out, 0x21);                                        /* 1980-01-01 */
        put32(out, e->crc); put32(out, e->size); put32(out, e->size);
        put16(out, nl); put16(out, 0);
        fwrite(e->name, 1, nl, out);
        if (size) fwrite(data, 1, size, out);
        off += 30 + nl + (uint32_t)size;
        free(data);
    }
    uint32_t cd = off;
    for (int i = 0; i < nents; i++) {
        Entry *e = &ents[i];
        unsigned nl = (unsigned)strlen(e->name);
        put32(out, 0x02014B50); put16(out, (3 << 8) | 20); put16(out, 10);      /* made by Unix */
        put16(out, 0); put16(out, 0); put16(out, 0); put16(out, 0x21);
        put32(out, e->crc); put32(out, e->size); put32(out, e->size);
        put16(out, nl); put16(out, 0); put16(out, 0); put16(out, 0);
        put16(out, 0); put32(out, e->mode << 16 | (e->mode & 040000 ? 0x10 : 0));
        put32(out, e->offset);
        fwrite(e->name, 1, nl, out);
        off += 46 + nl;
    }
    put32(out, 0x06054B50); put16(out, 0); put16(out, 0);
    put16(out, (unsigned)nents); put16(out, (unsigned)nents);
    put32(out, off - cd); put32(out, cd); put16(out, 0);
    if (fclose(out) != 0) return 1;
    printf("%s: %d entries, %u bytes\n", argv[1], nents, off + 22);
    return 0;
}
