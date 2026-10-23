/*
 * gles_render.h - draws the display list of the touch interface (and the game image)
 * with OpenGL ES 2. Used by the Android front-end, and by a Linux test that runs the
 * same shaders with Mesa.
 */
#ifndef PB_GLES_RENDER_H
#define PB_GLES_RENDER_H

#include <GLES2/gl2.h>
#include <stdbool.h>
#include <stdint.h>
#include "../mobile/ui.h"

typedef struct {
    GLuint prog_shape, prog_text, prog_game, tex_font, tex_game;
    GLint u_shape_screen, u_shape_rect, u_shape_radius, u_shape_color, u_shape_border, u_shape_bw;
    GLint u_text_screen, u_text_color, u_text_tex;
    GLint u_game_screen, u_game_tex, u_game_texsize, u_game_scale, u_game_filter, u_game_frect, u_game_colors;
    bool ok;
} GlRenderer;

bool gr_init(GlRenderer *r);                                           /* needs a current context */
void gr_upload(GlRenderer *r, const uint32_t *pixels, int stride, int h); /* the game image */
void gr_draw(GlRenderer *r, const UiList *list, int width, int height, int fw, int fh);

#endif
