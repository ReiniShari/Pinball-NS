/* mini SDK (see ../README.md): fcntl of iOS (Darwin, arm64) */
#ifndef PNS_FCNTL_H
#define PNS_FCNTL_H

#include <sys/types.h>

#define O_RDONLY 0x0000
#define O_WRONLY 0x0001
#define O_RDWR   0x0002
#define O_APPEND 0x0008
#define O_CREAT  0x0200
#define O_TRUNC  0x0400
#define O_EXCL   0x0800

int open(const char *path, int flags, ...);

#endif
