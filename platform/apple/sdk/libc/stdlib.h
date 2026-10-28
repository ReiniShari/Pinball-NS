/* mini SDK (see ../README.md): stdlib of iOS (Darwin, arm64) */
#ifndef PNS_STDLIB_H
#define PNS_STDLIB_H

#include <stddef.h>

#define EXIT_SUCCESS 0
#define EXIT_FAILURE 1
#define RAND_MAX 0x7fffffff

void *malloc(size_t size);
void *calloc(size_t n, size_t size);
void *realloc(void *p, size_t size);
void free(void *p);
void abort(void) __attribute__((noreturn));
void exit(int status) __attribute__((noreturn));
int atoi(const char *s);
long atol(const char *s);
double atof(const char *s);
long strtol(const char *restrict s, char **restrict end, int base);
unsigned long strtoul(const char *restrict s, char **restrict end, int base);
double strtod(const char *restrict s, char **restrict end);
int abs(int v);
long labs(long v);
void qsort(void *base, size_t n, size_t size, int (*cmp)(const void *, const void *));
char *getenv(const char *name);
int rand(void);
void srand(unsigned seed);

#endif
