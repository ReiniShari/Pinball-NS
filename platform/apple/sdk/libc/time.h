/* mini SDK (see ../README.md): the clock functions used by platform/macos and platform/desktop (Darwin) */
#ifndef PNS_TIME_H
#define PNS_TIME_H

#include <sys/types.h>

typedef long time_t;
struct timespec { time_t tv_sec; long tv_nsec; };
typedef enum { CLOCK_REALTIME = 0, CLOCK_MONOTONIC_RAW = 4, CLOCK_MONOTONIC = 6, CLOCK_UPTIME_RAW = 8 } clockid_t;
#define TIME_UTC 1

int clock_gettime(clockid_t clock, struct timespec *t);
int nanosleep(const struct timespec *req, struct timespec *rem);
time_t time(time_t *t);
int timespec_get(struct timespec *t, int base);

#endif
