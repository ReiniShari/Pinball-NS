/* mock (tests on Linux) */
#pragma once
#include <stdint.h>
typedef struct ARect { int32_t left, top, right, bottom; } ARect;
typedef struct ANativeWindow ANativeWindow;
int32_t ANativeWindow_setBuffersGeometry(ANativeWindow *window, int32_t width, int32_t height, int32_t format);
