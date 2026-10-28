/* mini SDK (see ../../README.md): the CoreGraphics functions used by platform/macos (a picture
 * made from the pixels of the game, a colour) */
#ifndef PNS_COREGRAPHICS_H
#define PNS_COREGRAPHICS_H

#include <CoreGraphics/CGGeometry.h>
#include <CoreFoundation/CoreFoundation.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

typedef struct CGColorSpace *CGColorSpaceRef;
typedef struct CGDataProvider *CGDataProviderRef;
typedef struct CGImage *CGImageRef;
typedef struct CGColor *CGColorRef;
typedef uint32_t CGBitmapInfo;
typedef int32_t CGColorRenderingIntent;

enum { kCGImageAlphaNoneSkipFirst = 6, kCGBitmapByteOrder32Little = 2 << 12, kCGRenderingIntentDefault = 0 };

CGColorSpaceRef CGColorSpaceCreateDeviceRGB(void);
void CGColorSpaceRelease(CGColorSpaceRef space);
CGDataProviderRef CGDataProviderCreateWithCFData(CFDataRef data);
void CGDataProviderRelease(CGDataProviderRef provider);
CGImageRef CGImageCreate(size_t width, size_t height, size_t bitsPerComponent, size_t bitsPerPixel, size_t bytesPerRow,
                         CGColorSpaceRef space, CGBitmapInfo bitmapInfo, CGDataProviderRef provider, const CGFloat *decode,
                         bool shouldInterpolate, CGColorRenderingIntent intent);
void CGImageRelease(CGImageRef image);
CGColorRef CGColorCreateGenericRGB(CGFloat red, CGFloat green, CGFloat blue, CGFloat alpha);
void CGColorRelease(CGColorRef color);

#endif
