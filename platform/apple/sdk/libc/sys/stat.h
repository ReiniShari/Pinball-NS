/* mini SDK (see ../../README.md): mkdir of iOS (Darwin, arm64). No struct stat: not used. */
#ifndef PNS_SYS_STAT_H
#define PNS_SYS_STAT_H

#include <sys/types.h>

#define S_IRWXU 0000700
#define S_IRWXG 0000070
#define S_IRWXO 0000007

int mkdir(const char *path, mode_t mode);
int chmod(const char *path, mode_t mode);

#endif
