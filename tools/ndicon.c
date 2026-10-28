/*
 * ndicon.c - the icon of Pinball NS: the right flipper key of the Blue table, drawn by the screen
 * of the Android version itself (platform/mobile/design.c, 32 x 32 game pixels), at whole
 * enlargements (each pixel of the key: a square of SCALE x SCALE pixels).
 *
 *   ndicon -key SIZE SCALE out.png   the key alone, centred on a transparent SIZE x SIZE image
 *                                    (foreground of the adaptive icon of Android)
 *   ndicon -bg SIZE out.png          the blue of the table (background of the adaptive icon)
 *   ndicon -flat SIZE SCALE out.png  the key on the blue (icon of older launchers)
 *   ndicon -ico out.ico              the Windows icon: 32 x 32 and its enlargements x2, x4, x8;
 *                                    16, 24 and 48 drawn at their own size
 *   ndicon -icns out.icns            the macOS icon: the key on the blue of the table, rounded as the
 *                                    icons of macOS, PNG images of 16 to 512 pixels
 */
#include "../platform/mobile/design.h"
#include "png_write.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define BLUE 0xFF005AFFu

static int write_icon(const char *path, int size, int scale, bool key, uint32_t bg)
{
    uint32_t k[ND_ICON * ND_ICON];
    nd_icon(k, ND_ICON);
    uint32_t *img = (uint32_t *)malloc((size_t)size * size * 4);
    if (!img) return 1;
    for (int i = 0; i < size * size; i++) img[i] = bg;
    if (key) {
        int n = ND_ICON * scale, o = (size - n) / 2;
        for (int y = 0; y < n; y++)
            for (int x = 0; x < n; x++) {
                int X = o + x, Y = o + y;
                if (X < 0 || Y < 0 || X >= size || Y >= size) continue;
                uint32_t c = k[(y / scale) * ND_ICON + x / scale];
                if (c >> 24) img[Y * size + X] = c;
            }
    }
    int r = png_write_rgba(path, img, size, size, size, 1);
    free(img);
    return r ? 1 : 0;
}

static void put32(uint8_t *p, uint32_t v) { p[0] = (uint8_t)v; p[1] = (uint8_t)(v >> 8); p[2] = (uint8_t)(v >> 16); p[3] = (uint8_t)(v >> 24); }
static void put16(uint8_t *p, unsigned v) { p[0] = (uint8_t)v; p[1] = (uint8_t)(v >> 8); }

/* .ico with 32-bit images (BITMAPINFOHEADER, colours bottom-up, then the 1-bit mask) */
static int write_ico(const char *path)
{
    static const int sizes[] = { 16, 24, 32, 48, 64, 128, 256 };
    enum { N = sizeof sizes / sizeof sizes[0] };
    uint8_t *img[N];
    uint32_t len[N];
    for (int i = 0; i < N; i++) {
        int s = sizes[i], scale = s >= ND_ICON ? s / ND_ICON : 1, n = s >= ND_ICON ? ND_ICON : s;
        if (s == 48) { scale = 1; n = 48; }
        uint32_t k[64 * 64];
        nd_icon(k, n);
        int mrow = ((s + 31) / 32) * 4;
        len[i] = 40 + (uint32_t)s * s * 4 + (uint32_t)mrow * s;
        img[i] = (uint8_t *)calloc(1, len[i]);
        if (!img[i]) return 1;
        uint8_t *h = img[i];
        put32(h, 40); put32(h + 4, (uint32_t)s); put32(h + 8, (uint32_t)s * 2);
        put16(h + 12, 1); put16(h + 14, 32);
        uint8_t *px = h + 40, *mask = px + (size_t)s * s * 4;
        for (int y = 0; y < s; y++)
            for (int x = 0; x < s; x++) {
                uint32_t c = k[(y / scale) * n + x / scale];
                uint8_t *q = px + ((size_t)(s - 1 - y) * s + x) * 4;
                q[0] = (uint8_t)c; q[1] = (uint8_t)(c >> 8); q[2] = (uint8_t)(c >> 16); q[3] = (uint8_t)(c >> 24);
                if (!(c >> 24)) mask[(size_t)(s - 1 - y) * mrow + x / 8] |= (uint8_t)(0x80 >> (x % 8));
            }
    }
    FILE *f = fopen(path, "wb");
    if (!f) return 1;
    uint8_t hdr[6] = { 0, 0, 1, 0, N, 0 };
    fwrite(hdr, 1, 6, f);
    uint32_t off = 6 + 16 * N;
    for (int i = 0; i < N; i++) {
        uint8_t e[16] = { 0 };
        e[0] = (uint8_t)(sizes[i] >= 256 ? 0 : sizes[i]);
        e[1] = e[0];
        put16(e + 4, 1); put16(e + 6, 32);
        put32(e + 8, len[i]); put32(e + 12, off);
        fwrite(e, 1, 16, f);
        off += len[i];
    }
    for (int i = 0; i < N; i++) { fwrite(img[i], 1, len[i], f); free(img[i]); }
    return fclose(f) ? 1 : 0;
}

/* .icns: "icns", its length, then (type, length, PNG) for each size; the key, 32 pixels drawn at whole
 * enlargements, centred on the blue of the table with rounded corners (16 pixels: drawn at that size) */
static int write_icns(const char *path)
{
    static const struct { char type[5]; int size; } ent[] = {
        { "icp4", 16 }, { "icp5", 32 }, { "icp6", 64 }, { "ic07", 128 }, { "ic08", 256 }, { "ic09", 512 } };   /* (PNG stored: 1024 left out) */
    enum { N = sizeof ent / sizeof ent[0] };
    uint8_t *png[N];
    uint32_t len[N], total = 8;
    char tmp[600];
    snprintf(tmp, sizeof tmp, "%s.tmp.png", path);
    for (int i = 0; i < N; i++) {
        int s = ent[i].size, n = s >= ND_ICON ? ND_ICON : s, scale = s >= ND_ICON ? (s * 13 / 16 + ND_ICON / 2) / ND_ICON : 1;
        if (scale < 1) scale = 1;
        uint32_t k[64 * 64];
        nd_icon(k, n);
        uint32_t *img = (uint32_t *)calloc((size_t)s * s, 4);
        if (!img) return 1;
        int r = s / 5, m = s / 16;                     /* the rounded square of macOS's icons, its margin */
        for (int y = 0; y < s; y++)
            for (int x = 0; x < s; x++) {
                int dx = x < m + r ? m + r - x : x > s - 1 - m - r ? x - (s - 1 - m - r) : 0;
                int dy = y < m + r ? m + r - y : y > s - 1 - m - r ? y - (s - 1 - m - r) : 0;
                bool in = x >= m && y >= m && x < s - m && y < s - m && dx * dx + dy * dy <= r * r;
                if (in) img[y * s + x] = BLUE;
            }
        int kn = n * scale, o = (s - kn) / 2;
        for (int y = 0; y < kn; y++)
            for (int x = 0; x < kn; x++) {
                uint32_t c = k[(y / scale) * n + x / scale];
                if ((c >> 24) && o + x < s && o + y < s) img[(o + y) * s + o + x] = c;
            }
        if (png_write_rgba(tmp, img, s, s, s, 1)) { free(img); return 1; }
        free(img);
        FILE *f = fopen(tmp, "rb");
        if (!f) return 1;
        fseek(f, 0, SEEK_END);
        long n2 = ftell(f);
        fseek(f, 0, SEEK_SET);
        png[i] = (uint8_t *)malloc((size_t)n2);
        if (!png[i] || fread(png[i], 1, (size_t)n2, f) != (size_t)n2) { fclose(f); return 1; }
        fclose(f);
        len[i] = (uint32_t)n2;
        total += 8 + len[i];
    }
    remove(tmp);
    FILE *f = fopen(path, "wb");
    if (!f) return 1;
    uint8_t h[8];
    h[0] = 'i'; h[1] = 'c'; h[2] = 'n'; h[3] = 's';
    h[4] = (uint8_t)(total >> 24); h[5] = (uint8_t)(total >> 16); h[6] = (uint8_t)(total >> 8); h[7] = (uint8_t)total;
    fwrite(h, 1, 8, f);
    for (int i = 0; i < N; i++) {
        uint32_t l = len[i] + 8;
        memcpy(h, ent[i].type, 4);
        h[4] = (uint8_t)(l >> 24); h[5] = (uint8_t)(l >> 16); h[6] = (uint8_t)(l >> 8); h[7] = (uint8_t)l;
        fwrite(h, 1, 8, f);
        fwrite(png[i], 1, len[i], f);
        free(png[i]);
    }
    return fclose(f) ? 1 : 0;
}

int main(int argc, char **argv)
{
    if (argc == 3 && !strcmp(argv[1], "-icns")) return write_icns(argv[2]);
    if (argc == 5 && !strcmp(argv[1], "-key")) return write_icon(argv[4], atoi(argv[2]), atoi(argv[3]), true, 0);
    if (argc == 4 && !strcmp(argv[1], "-bg")) return write_icon(argv[3], atoi(argv[2]), 1, false, BLUE);
    if (argc == 5 && !strcmp(argv[1], "-flat")) return write_icon(argv[4], atoi(argv[2]), atoi(argv[3]), true, BLUE);
    if (argc == 3 && !strcmp(argv[1], "-ico")) return write_ico(argv[2]);
    fprintf(stderr, "usage: ndicon -key SIZE SCALE out.png | -bg SIZE out.png | -flat SIZE SCALE out.png | -ico out.ico | "
                    "-icns out.icns\n");
    return 2;
}
