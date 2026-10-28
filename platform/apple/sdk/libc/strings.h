/* mini SDK (see ../README.md): strings of iOS (Darwin, arm64) */
#ifndef PNS_STRINGS_H
#define PNS_STRINGS_H

#include <stddef.h>

int strcasecmp(const char *a, const char *b);
int strncasecmp(const char *a, const char *b, size_t n);
void bzero(void *p, size_t n);

#endif
