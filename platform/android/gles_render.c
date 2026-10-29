/*
 * gles_render.c - OpenGL ES 2 renderer of the touch interface (see gles_render.h).
 *
 * Shapes are rounded rectangles drawn with a signed distance (anti-aliased edges and
 * borders), text uses a texture made from the bitmap font, and the game image is
 * enlarged with a "sharp bilinear" filter: whole-pixel enlargement, then a one-pixel
 * smooth transition, so that pixels stay crisp at any screen size. Over the whole picture
 * (the game and its controls alike), the screen filters and the colours of the menu (ui.h):
 * dots, LCD; black and white, the greens of the Game Boy (the same arithmetic as
 * tools/uisim.c).
 */
#include "gles_render.h"
#include "../../src/front/font5x7.h"
#include <stdio.h>
#include <string.h>

#ifdef __ANDROID__
#include <android/log.h>
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, "PinballTC", __VA_ARGS__)
#else
#define LOGE(...) (fprintf(stderr, __VA_ARGS__), fputc('\n', stderr))
#endif

static const char *VS_SHAPE =
    "attribute vec2 a_pos;\n"
    "uniform vec2 u_screen;\n"
    "varying vec2 v_pos;\n"
    "void main() { v_pos = a_pos; gl_Position = vec4(a_pos.x / u_screen.x * 2.0 - 1.0, 1.0 - a_pos.y / u_screen.y * 2.0, 0.0, 1.0); }\n";

static const char *FS_SHAPE =
    "#ifdef GL_FRAGMENT_PRECISION_HIGH\nprecision highp float;\n#else\nprecision mediump float;\n#endif\n"
    "varying vec2 v_pos;\n"
    "uniform vec4 u_rect;\n"        /* centre, half size */
    "uniform float u_radius;\n"
    "uniform vec4 u_color;\n"
    "uniform vec4 u_border;\n"
    "uniform float u_bw;\n"
    "void main() {\n"
    "  vec2 q = abs(v_pos - u_rect.xy) - (u_rect.zw - vec2(u_radius));\n"
    "  float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - u_radius;\n"
    "  float cov = clamp(0.5 - d, 0.0, 1.0);\n"
    "  float inb = u_bw > 0.0 ? clamp(0.5 + d + u_bw, 0.0, 1.0) : 0.0;\n"
    "  float af = u_color.a * cov * (1.0 - inb);\n"
    "  float ab = u_border.a * cov * inb;\n"
    "  vec3 rgb = u_border.rgb * ab + u_color.rgb * af * (1.0 - ab);\n"
    "  gl_FragColor = vec4(rgb, ab + af * (1.0 - ab));\n"
    "}\n";

static const char *VS_TEX =
    "attribute vec2 a_pos;\n"
    "attribute vec2 a_uv;\n"
    "uniform vec2 u_screen;\n"
    "varying vec2 v_uv;\n"
    "void main() { v_uv = a_uv; gl_Position = vec4(a_pos.x / u_screen.x * 2.0 - 1.0, 1.0 - a_pos.y / u_screen.y * 2.0, 0.0, 1.0); }\n";

static const char *FS_TEXT =
    "precision mediump float;\n"
    "varying vec2 v_uv;\n"
    "uniform sampler2D u_tex;\n"
    "uniform vec4 u_color;\n"
    "void main() { float a = texture2D(u_tex, v_uv).a * u_color.a; gl_FragColor = vec4(u_color.rgb * a, a); }\n";

/* The game image. u_filter: 0 sharp pixels; over u_frect (texels: x0, y0, x1, y1), 1 dots: each
 * pixel a round dot fading out from its centre, a little wider when bright, the dots of the
 * neighbours lighting the gaps (the classic "dot" filter of the emulators); 2 LCD: the cells of a
 * liquid crystal screen, their red, green and blue side by side (in colour), a darker grid between
 * them. u_colors: 0 the game's, 1 black and white (the brightness of each colour), 2 the four greens
 * of the Game Boy's screen, in shades between them. */
static const char *FS_GAME =
    "#ifdef GL_FRAGMENT_PRECISION_HIGH\nprecision highp float;\n#else\nprecision mediump float;\n#endif\n"
    "varying vec2 v_uv;\n"          /* in texels */
    "uniform sampler2D u_tex;\n"
    "uniform vec2 u_texsize;\n"
    "uniform vec2 u_scale;\n"
    "uniform float u_filter;\n"
    "uniform float u_colors;\n"
    "uniform vec4 u_frect;\n"
    "uniform vec2 u_fsize;\n"      /* the picture in the texture (texels) */
    "vec3 tone(vec3 c) {\n"
    "  if (u_colors < 0.5) return c;\n"
    "  float l = dot(c, vec3(0.299, 0.587, 0.114));\n"
    "  if (u_colors < 1.5) return vec3(l);\n"
    "  float t = l * 3.0;\n"                                   /* 0F380F 306230 8BAC0F 9BBC0F */
    "  if (t < 1.0) return mix(vec3(0.0588, 0.2196, 0.0588), vec3(0.1882, 0.3843, 0.1882), t);\n"
    "  if (t < 2.0) return mix(vec3(0.1882, 0.3843, 0.1882), vec3(0.5451, 0.6745, 0.0588), t - 1.0);\n"
    "  return mix(vec3(0.5451, 0.6745, 0.0588), vec3(0.6078, 0.7373, 0.0588), t - 2.0);\n"
    "}\n"
    "vec3 texel(vec2 p) {\n"       /* frame pixels are 0x00RRGGBB; the neighbours taken inside the rectangle */
    "  p = clamp(p, u_frect.xy, u_frect.zw - 1.0);\n"
    "  return tone(texture2D(u_tex, (p + 0.5) / u_texsize).bgr);\n"
    "}\n"
    "vec3 dot_of(vec2 p, vec2 o, vec2 f) {\n"
    "  vec3 c = texel(p + o);\n"
    "  float spread = mix(1.05, 0.95, dot(c, vec3(0.30, 0.59, 0.11)));\n"
    "  return c * exp(-2.4 * length(f - o) * spread);\n"
    "}\n"
    "void main() {\n"
    "  if (u_filter > 0.5 && v_uv.x >= u_frect.x && v_uv.x < u_frect.z && v_uv.y >= u_frect.y && v_uv.y < u_frect.w) {\n"
    "    vec2 p = floor(v_uv);\n"
    "    vec3 col;\n"
    "    if (u_filter < 1.5) {\n"
    "      vec2 f = fract(v_uv) - 0.5;\n"
    "      vec3 mid = dot_of(p, vec2(0.0, 0.0), f);\n"
    "      vec3 s = mid + dot_of(p, vec2(-1.0, -1.0), f) + dot_of(p, vec2(0.0, -1.0), f) + dot_of(p, vec2(1.0, -1.0), f)\n"
    "             + dot_of(p, vec2(-1.0, 0.0), f) + dot_of(p, vec2(1.0, 0.0), f)\n"
    "             + dot_of(p, vec2(-1.0, 1.0), f) + dot_of(p, vec2(0.0, 1.0), f) + dot_of(p, vec2(1.0, 1.0), f);\n"
    "      col = mix(1.2 * mid, s, 0.65);\n"
    "    } else {\n"
    "      vec2 g = fract(v_uv);\n"
    "      vec2 e = min(g, 1.0 - g);\n"                       /* to the border of the cell */
    "      vec2 lw = max(1.5 / u_scale, vec2(0.1));\n"        /* the grid: a pixel and a half of the screen */
    "      float grid = mix(0.5, 1.0, smoothstep(0.0, lw.x, e.x) * smoothstep(0.0, lw.y, e.y));\n"
    "      vec3 sub = u_colors < 0.5 ? 0.75 + 0.25 * cos(6.2831853 * (g.x - vec3(0.16666667, 0.5, 0.83333333))) : vec3(0.75);\n"
    "      col = texel(p) * sub * grid * 1.4;\n"
    "    }\n"
    "    gl_FragColor = vec4(clamp(col, 0.0, 1.0), 1.0);\n"
    "    return;\n"
    "  }\n"
    "  vec2 t = floor(v_uv);\n"
    "  vec2 c = fract(v_uv) - 0.5;\n"
    "  vec2 range = 0.5 - 0.5 / u_scale;\n"
    "  vec2 f = (c - clamp(c, -range, range)) * u_scale + 0.5;\n"
    /* the transition of the last row and column stays in the picture: past it, the texture keeps
     * an older, larger picture (2.9: a line of the old screen at the bottom and the right edge) */
    "  vec4 p = texture2D(u_tex, clamp(t + f, vec2(0.5), u_fsize - 0.5) / u_texsize);\n"
    "  gl_FragColor = vec4(tone(p.bgr), 1.0);\n"
    "}\n";

#define ATLAS_COLS 16
#define ATLAS_W    128
#define ATLAS_H    128
#define GAME_TEX_W 1024           /* the game image (256 x 290 at most) or the New Mode canvas */
#define GAME_TEX_H 1024

static GLuint compile(GLenum type, const char *src, bool *ok)
{
    GLuint s = glCreateShader(type);
    glShaderSource(s, 1, &src, NULL);
    glCompileShader(s);
    GLint st = 0;
    glGetShaderiv(s, GL_COMPILE_STATUS, &st);
    if (!st) {
        char log[1024];
        glGetShaderInfoLog(s, sizeof log, NULL, log);
        LOGE("shader: %s", log);
        *ok = false;
    }
    return s;
}

static GLuint program(const char *vs, const char *fs, bool *ok)
{
    GLuint p = glCreateProgram();
    GLuint v = compile(GL_VERTEX_SHADER, vs, ok), f = compile(GL_FRAGMENT_SHADER, fs, ok);
    glAttachShader(p, v);
    glAttachShader(p, f);
    glBindAttribLocation(p, 0, "a_pos");
    glBindAttribLocation(p, 1, "a_uv");
    glLinkProgram(p);
    GLint st = 0;
    glGetProgramiv(p, GL_LINK_STATUS, &st);
    if (!st) {
        char log[1024];
        glGetProgramInfoLog(p, sizeof log, NULL, log);
        LOGE("program: %s", log);
        *ok = false;
    }
    glDeleteShader(v);
    glDeleteShader(f);
    return p;
}

bool gr_init(GlRenderer *r)
{
    memset(r, 0, sizeof *r);
    bool ok = true;
    r->prog_shape = program(VS_SHAPE, FS_SHAPE, &ok);
    r->u_shape_screen = glGetUniformLocation(r->prog_shape, "u_screen");
    r->u_shape_rect = glGetUniformLocation(r->prog_shape, "u_rect");
    r->u_shape_radius = glGetUniformLocation(r->prog_shape, "u_radius");
    r->u_shape_color = glGetUniformLocation(r->prog_shape, "u_color");
    r->u_shape_border = glGetUniformLocation(r->prog_shape, "u_border");
    r->u_shape_bw = glGetUniformLocation(r->prog_shape, "u_bw");
    r->prog_text = program(VS_TEX, FS_TEXT, &ok);
    r->u_text_screen = glGetUniformLocation(r->prog_text, "u_screen");
    r->u_text_color = glGetUniformLocation(r->prog_text, "u_color");
    r->u_text_tex = glGetUniformLocation(r->prog_text, "u_tex");
    r->prog_game = program(VS_TEX, FS_GAME, &ok);
    r->u_game_screen = glGetUniformLocation(r->prog_game, "u_screen");
    r->u_game_tex = glGetUniformLocation(r->prog_game, "u_tex");
    r->u_game_texsize = glGetUniformLocation(r->prog_game, "u_texsize");
    r->u_game_scale = glGetUniformLocation(r->prog_game, "u_scale");
    r->u_game_filter = glGetUniformLocation(r->prog_game, "u_filter");
    r->u_game_frect = glGetUniformLocation(r->prog_game, "u_frect");
    r->u_game_colors = glGetUniformLocation(r->prog_game, "u_colors");
    r->u_game_fsize = glGetUniformLocation(r->prog_game, "u_fsize");

    /* font atlas: glyph i in cell (i % 16, i / 16), 8 x 8 pixels per cell */
    font_init();
    static uint8_t atlas[ATLAS_W * ATLAS_H];
    memset(atlas, 0, sizeof atlas);
    for (int i = 0; i < FONT_NGLYPHS && i < ATLAS_COLS * (ATLAS_H / 8); i++) {
        int cx = (i % ATLAS_COLS) * 8, cy = (i / ATLAS_COLS) * 8;
        for (int y = 0; y < FONT_H; y++)
            for (int x = 0; x < FONT_W; x++)
                if (font_glyphs[i].rows[y] & (0x10 >> x)) atlas[(cy + y) * ATLAS_W + cx + x] = 255;
    }
    glGenTextures(1, &r->tex_font);
    glBindTexture(GL_TEXTURE_2D, r->tex_font);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_ALPHA, ATLAS_W, ATLAS_H, 0, GL_ALPHA, GL_UNSIGNED_BYTE, atlas);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    /* game image: the core's frame buffer (256 pixels wide, up to 320 lines), or the picture
     * of the cabinet in New Mode (up to 1024 x 1024) */
    glGenTextures(1, &r->tex_game);
    glBindTexture(GL_TEXTURE_2D, r->tex_game);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 4);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, GAME_TEX_W, GAME_TEX_H, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    r->ok = ok;
    return ok;
}

void gr_upload(GlRenderer *r, const uint32_t *px, int stride, int h)
{
    if (!px || stride <= 0 || stride > GAME_TEX_W || h <= 0) return;
    if (h > GAME_TEX_H) h = GAME_TEX_H;
    glBindTexture(GL_TEXTURE_2D, r->tex_game);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 4);
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, stride, h, GL_RGBA, GL_UNSIGNED_BYTE, px);
}

static void set_rgba(GLint loc, uint32_t c)
{
    glUniform4f(loc, ((c >> 16) & 255) / 255.f, ((c >> 8) & 255) / 255.f, (c & 255) / 255.f, (c >> 24) / 255.f);
}

void gr_draw(GlRenderer *r, const UiList *l, int w, int h, int fw, int fh)
{
    glViewport(0, 0, w, h);
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    glEnableVertexAttribArray(0);
    static float verts[24 * 128];

    for (int i = 0; i < l->n; i++) {
        const UiItem *it = &l->item[i];
        if (it->kind == UI_SHAPE) {
            glUseProgram(r->prog_shape);
            glDisableVertexAttribArray(1);
            glUniform2f(r->u_shape_screen, (float)w, (float)h);
            glUniform4f(r->u_shape_rect, it->x + it->w / 2, it->y + it->h / 2, it->w / 2, it->h / 2);
            float rad = it->radius;
            if (rad > it->w / 2) rad = it->w / 2;
            if (rad > it->h / 2) rad = it->h / 2;
            glUniform1f(r->u_shape_radius, rad);
            set_rgba(r->u_shape_color, it->color);
            set_rgba(r->u_shape_border, it->border);
            glUniform1f(r->u_shape_bw, it->border_w);
            float x0 = it->x - 1, y0 = it->y - 1, x1 = it->x + it->w + 1, y1 = it->y + it->h + 1;
            float q[8] = { x0, y0, x1, y0, x0, y1, x1, y1 };
            glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, q);
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        } else if (it->kind == UI_TEXT) {
            glUseProgram(r->prog_text);
            glEnableVertexAttribArray(1);
            glUniform2f(r->u_text_screen, (float)w, (float)h);
            set_rgba(r->u_text_color, it->color);
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D, r->tex_font);
            glUniform1i(r->u_text_tex, 0);
            const char *s = l->text + it->text;
            float x = it->x, y = it->y, px = it->px;
            int n = 0;
            while (*s && n < 128) {
                int gi = (int)(font_glyph(utf8_next(&s)) - font_glyphs);
                float u0 = (float)((gi % ATLAS_COLS) * 8) / ATLAS_W, v0 = (float)((gi / ATLAS_COLS) * 8) / ATLAS_H;
                float u1 = u0 + (float)FONT_W / ATLAS_W, v1 = v0 + (float)FONT_H / ATLAS_H;
                float gx1 = x + FONT_W * px, gy1 = y + FONT_H * px;
                float g[24] = { x, y, u0, v0,  gx1, y, u1, v0,  x, gy1, u0, v1,
                                gx1, y, u1, v0,  gx1, gy1, u1, v1,  x, gy1, u0, v1 };
                memcpy(verts + n * 24, g, sizeof g);
                n++;
                x += FONT_CELL_W * px;
            }
            glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 16, verts);
            glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 16, verts + 2);
            glDrawArrays(GL_TRIANGLES, 0, n * 6);
        } else if (fw > 0 && fh > 0) {
            glUseProgram(r->prog_game);
            glEnableVertexAttribArray(1);
            glUniform2f(r->u_game_screen, (float)w, (float)h);
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D, r->tex_game);
            glUniform1i(r->u_game_tex, 0);
            glUniform2f(r->u_game_texsize, (float)GAME_TEX_W, (float)GAME_TEX_H);
            float ty0 = 0, ty1 = (float)fh;            /* the lines of the picture shown (sy0, sy1) */
            if (it->sy1 > it->sy0) { ty0 = it->sy0; ty1 = it->sy1; }
            glUniform2f(r->u_game_scale, it->w / fw, it->h / (ty1 - ty0));
            glUniform1f(r->u_game_filter, (float)it->filter);
            glUniform4f(r->u_game_frect, it->fx0, it->fy0, it->fx1, it->fy1);
            glUniform1f(r->u_game_colors, (float)it->colors);
            glUniform2f(r->u_game_fsize, (float)fw, (float)fh);
            float x0 = it->x, y0 = it->y, x1 = it->x + it->w, y1 = it->y + it->h;
            float q[16] = { x0, y0, 0, ty0,  x1, y0, (float)fw, ty0,  x0, y1, 0, ty1,  x1, y1, (float)fw, ty1 };
            glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 16, q);
            glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 16, q + 2);
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        }
    }
    glDisableVertexAttribArray(1);
}
