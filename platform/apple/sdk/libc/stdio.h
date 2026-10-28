/* mini SDK (see ../README.md): stdio of iOS (Darwin, arm64) */
#ifndef PNS_STDIO_H
#define PNS_STDIO_H

#include <stdarg.h>
#include <stddef.h>

typedef struct __sFILE FILE;
extern FILE *__stdinp, *__stdoutp, *__stderrp;
#define stdin  __stdinp
#define stdout __stdoutp
#define stderr __stderrp
#define EOF (-1)
#define SEEK_SET 0
#define SEEK_CUR 1
#define SEEK_END 2
#define BUFSIZ 1024
#define FILENAME_MAX 1024

FILE *fopen(const char *restrict path, const char *restrict mode);
int fclose(FILE *f);
size_t fread(void *restrict p, size_t size, size_t n, FILE *restrict f);
size_t fwrite(const void *restrict p, size_t size, size_t n, FILE *restrict f);
int fseek(FILE *f, long off, int whence);
long ftell(FILE *f);
int fflush(FILE *f);
int fileno(FILE *f);
int fgetc(FILE *f);
char *fgets(char *restrict s, int n, FILE *restrict f);
int fputc(int c, FILE *f);
int fputs(const char *restrict s, FILE *restrict f);
int putchar(int c);
int puts(const char *s);
int printf(const char *restrict fmt, ...);
int fprintf(FILE *restrict f, const char *restrict fmt, ...);
int vfprintf(FILE *restrict f, const char *restrict fmt, va_list ap);
int sprintf(char *restrict s, const char *restrict fmt, ...);
int snprintf(char *restrict s, size_t n, const char *restrict fmt, ...);
int vsnprintf(char *restrict s, size_t n, const char *restrict fmt, va_list ap);
int sscanf(const char *restrict s, const char *restrict fmt, ...);
int rename(const char *from, const char *to);
int remove(const char *path);
void perror(const char *s);

#endif
