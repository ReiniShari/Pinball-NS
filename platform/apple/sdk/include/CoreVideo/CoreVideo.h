/* mini SDK (see ../../README.md): the display link of CoreVideo used by platform/macos (a call at each
 * refresh of the display) */
#ifndef PNS_COREVIDEO_H
#define PNS_COREVIDEO_H

#include <stdint.h>

typedef int32_t CVReturn;
typedef uint64_t CVOptionFlags;
typedef uint32_t CGDirectDisplayID;
typedef struct __CVDisplayLink *CVDisplayLinkRef;

typedef struct CVSMPTETime {
    int16_t subframes, subframeDivisor;
    uint32_t counter, type, flags;
    int16_t hours, minutes, seconds, frames;
} CVSMPTETime;

typedef struct CVTimeStamp {
    uint32_t version;
    int32_t videoTimeScale;
    int64_t videoTime;
    uint64_t hostTime;              /* mach_absolute_time */
    double rateScalar;
    int64_t videoRefreshPeriod;
    CVSMPTETime smpteTime;
    uint64_t flags;
    uint64_t reserved;
} CVTimeStamp;

typedef CVReturn (*CVDisplayLinkOutputCallback)(CVDisplayLinkRef link, const CVTimeStamp *now, const CVTimeStamp *output,
                                               CVOptionFlags flags_in, CVOptionFlags *flags_out, void *context);

CVReturn CVDisplayLinkCreateWithActiveCGDisplays(CVDisplayLinkRef *link);
CVReturn CVDisplayLinkSetOutputCallback(CVDisplayLinkRef link, CVDisplayLinkOutputCallback callback, void *context);
CVReturn CVDisplayLinkSetCurrentCGDisplay(CVDisplayLinkRef link, CGDirectDisplayID display);
CVReturn CVDisplayLinkStart(CVDisplayLinkRef link);
CVReturn CVDisplayLinkStop(CVDisplayLinkRef link);
void CVDisplayLinkRelease(CVDisplayLinkRef link);

#endif
