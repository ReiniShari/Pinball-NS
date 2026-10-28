/* mini SDK (see ../../README.md): the CoreFoundation functions used by platform/macos */
#ifndef PNS_COREFOUNDATION_H
#define PNS_COREFOUNDATION_H

#include <stdint.h>

typedef const void *CFTypeRef;
typedef const struct __CFAllocator *CFAllocatorRef;
typedef const struct __CFData *CFDataRef;
typedef long CFIndex;
typedef uint8_t UInt8;

CFDataRef CFDataCreate(CFAllocatorRef allocator, const UInt8 *bytes, CFIndex length);
void CFRelease(CFTypeRef cf);

#endif
