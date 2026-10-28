/* mini SDK (see ../../README.md): the geometry types of CoreGraphics (64-bit) */
#ifndef PNS_CGGEOMETRY_H
#define PNS_CGGEOMETRY_H

typedef double CGFloat;
typedef struct CGPoint { CGFloat x, y; } CGPoint;
typedef struct CGSize { CGFloat width, height; } CGSize;
typedef struct CGRect { CGPoint origin; CGSize size; } CGRect;

#endif
