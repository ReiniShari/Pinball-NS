/* mini SDK (see ../README.md): unistd of iOS (Darwin, arm64) */
#ifndef PNS_UNISTD_H
#define PNS_UNISTD_H

#include <sys/types.h>

#define R_OK 4
#define W_OK 2
#define X_OK 1
#define F_OK 0

int close(int fd);
ssize_t read(int fd, void *buf, size_t n);
ssize_t write(int fd, const void *buf, size_t n);
int fsync(int fd);
int unlink(const char *path);
int access(const char *path, int mode);
int usleep(unsigned int usec);
unsigned int sleep(unsigned int sec);

#endif
