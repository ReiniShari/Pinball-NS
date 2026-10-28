/*
 * metal_render.h - draws the display list of the touch interface (and the game image) with
 * Metal: the same drawing as the OpenGL ES renderer of Android (platform/android/gles_render.c),
 * with the same shaders written in the Metal shading language, compiled when the app starts.
 */
#ifndef PB_METAL_RENDER_H
#define PB_METAL_RENDER_H

#include "../apple/objc_c.h"
#include "../mobile/ui.h"

#define MR_FRAMES 3                     /* frames the GPU may still be drawing */

typedef struct {
    id device, queue;
    id pso_shape, pso_text, pso_game;
    id tex_font;
    id tex_game[MR_FRAMES], vbuf[MR_FRAMES], cmd[MR_FRAMES];
    int slot;
    bool ok;
    char error[600];                    /* why the setup failed (for the log file) */
} MtlRenderer;

bool mr_init(MtlRenderer *r, id device);
/* one frame: waits until the GPU is done with the oldest frame, uploads the game image
 * (px: stride x fh pixels 0x00RRGGBB, may be NULL), draws the list into the next drawable of
 * the CAMetalLayer and presents it */
void mr_frame(MtlRenderer *r, id layer, const UiList *list, int width, int height,
              const uint32_t *px, int stride, int fw, int fh);

#endif
