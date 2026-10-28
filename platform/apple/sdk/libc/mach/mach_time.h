/* mini SDK (see ../../README.md): the clock of the display link's times (platform/macos) */
#ifndef PNS_MACH_TIME_H
#define PNS_MACH_TIME_H

#include <stdint.h>

typedef struct mach_timebase_info { uint32_t numer, denom; } mach_timebase_info_data_t, *mach_timebase_info_t;

uint64_t mach_absolute_time(void);
int mach_timebase_info(mach_timebase_info_t info);      /* kern_return_t */

#endif
