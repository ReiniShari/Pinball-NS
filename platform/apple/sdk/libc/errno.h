/* mini SDK (see ../README.md): errno of iOS (Darwin, arm64) */
#ifndef PNS_ERRNO_H
#define PNS_ERRNO_H

extern int *__error(void);
#define errno (*__error())
#define ENOENT 2
#define EINTR  4
#define EIO    5
#define EEXIST 17
#define EAGAIN 35

#endif
