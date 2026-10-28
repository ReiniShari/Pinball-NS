/*
 * metal_render.c - Metal renderer of the touch interface (see metal_render.h).
 *
 * As on Android (platform/android/gles_render.c, the same arithmetic): shapes are rounded
 * rectangles drawn with a signed distance, text uses a texture made from the bitmap font, and the
 * game image is enlarged with a "sharp bilinear" filter (whole-pixel enlargement, then a one-pixel
 * smooth transition), so that the pixels of the game stay crisp at the size of any iPhone screen.
 * Over the whole picture (the game and its controls alike), the screen filters and the colours of
 * the menu (ui.h): dots, LCD; black and white, the greens of the Game Boy.
 */
#include "metal_render.h"
#include "../../src/front/font5x7.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Metal values */
enum {
    PIXEL_BGRA8 = 80, PIXEL_R8 = 10, USAGE_SHADER_READ = 1, BLEND_ONE = 1, BLEND_ONE_MINUS_SRC_ALPHA = 5,
    LOAD_CLEAR = 2, STORE_STORE = 1, PRIM_TRIANGLE = 3, PRIM_TRIANGLE_STRIP = 4
};

#define ATLAS_COLS 16
#define ATLAS_W    128
#define ATLAS_H    128
#define GAME_TEX_W 1024           /* the canvas of the screen (design.h: ND_MAX_W x ND_MAX_H) */
#define GAME_TEX_H 1024
#define VB_FLOATS  (128 * 1024)   /* vertices of one frame: x, y, u, v */

static const char *MSL =
    "#include <metal_stdlib>\n"
    "using namespace metal;\n"
    "struct VOut { float4 position [[position]]; float2 pos; float2 uv; };\n"
    "vertex VOut vs_main(uint vid [[vertex_id]], const device float4 *v [[buffer(0)]],\n"
    "                    constant float2 &screen [[buffer(1)]]) {\n"
    "  float4 a = v[vid];\n"
    "  VOut o;\n"
    "  o.position = float4(a.x / screen.x * 2.0f - 1.0f, 1.0f - a.y / screen.y * 2.0f, 0.0f, 1.0f);\n"
    "  o.pos = a.xy;\n"
    "  o.uv = a.zw;\n"
    "  return o;\n"
    "}\n"
    /* rounded rectangle: centre and half size, radius, fill, border */
    "struct Shape { float4 rect; float4 color; float4 border; float radius; float bw; };\n"
    "fragment float4 fs_shape(VOut i [[stage_in]], constant Shape &s [[buffer(0)]]) {\n"
    "  float2 q = abs(i.pos - s.rect.xy) - (s.rect.zw - float2(s.radius));\n"
    "  float d = length(max(q, float2(0.0f))) + min(max(q.x, q.y), 0.0f) - s.radius;\n"
    "  float cov = clamp(0.5f - d, 0.0f, 1.0f);\n"
    "  float inb = s.bw > 0.0f ? clamp(0.5f + d + s.bw, 0.0f, 1.0f) : 0.0f;\n"
    "  float af = s.color.a * cov * (1.0f - inb);\n"
    "  float ab = s.border.a * cov * inb;\n"
    "  float3 rgb = s.border.rgb * ab + s.color.rgb * af * (1.0f - ab);\n"
    "  return float4(rgb, ab + af * (1.0f - ab));\n"
    "}\n"
    "fragment float4 fs_text(VOut i [[stage_in]], texture2d<float> tex [[texture(0)]],\n"
    "                        constant float4 &color [[buffer(0)]]) {\n"
    "  constexpr sampler sm(filter::nearest, address::clamp_to_edge);\n"
    "  float a = tex.sample(sm, i.uv).r * color.a;\n"
    "  return float4(color.rgb * a, a);\n"
    "}\n"
    /* The game image, uv in texels; the pixels are 0x00RRGGBB, in memory order B, G, R: a BGRA texture.
     * filter: 0 sharp pixels; over frect (texels: x0, y0, x1, y1), 1 dots, 2 LCD; colors: 0 the game's,
     * 1 black and white, 2 the four greens of the Game Boy (see gles_render.c) */
    "struct Game { float4 frect; float2 texsize; float2 scale; float2 fsize; float filter; float colors; };\n"
    "float3 tone(float3 c, float colors) {\n"
    "  if (colors < 0.5f) return c;\n"
    "  float l = dot(c, float3(0.299f, 0.587f, 0.114f));\n"
    "  if (colors < 1.5f) return float3(l);\n"
    "  float t = l * 3.0f;\n"                                  /* 0F380F 306230 8BAC0F 9BBC0F */
    "  if (t < 1.0f) return mix(float3(0.0588f, 0.2196f, 0.0588f), float3(0.1882f, 0.3843f, 0.1882f), float3(t));\n"
    "  if (t < 2.0f) return mix(float3(0.1882f, 0.3843f, 0.1882f), float3(0.5451f, 0.6745f, 0.0588f), float3(t - 1.0f));\n"
    "  return mix(float3(0.5451f, 0.6745f, 0.0588f), float3(0.6078f, 0.7373f, 0.0588f), float3(t - 2.0f));\n"
    "}\n"
    "float3 texel(texture2d<float> tex, constant Game &g, float2 p) {\n"   /* the neighbours taken inside the rectangle */
    "  constexpr sampler sm(filter::linear, address::clamp_to_edge);\n"
    "  p = clamp(p, g.frect.xy, g.frect.zw - float2(1.0f));\n"
    "  return tone(tex.sample(sm, (p + float2(0.5f)) / g.texsize).rgb, g.colors);\n"
    "}\n"
    "float3 dot_of(texture2d<float> tex, constant Game &g, float2 p, float2 o, float2 f) {\n"
    "  float3 c = texel(tex, g, p + o);\n"
    "  float spread = mix(1.05f, 0.95f, dot(c, float3(0.30f, 0.59f, 0.11f)));\n"
    "  return c * exp(-2.4f * length(f - o) * spread);\n"
    "}\n"
    "fragment float4 fs_game(VOut i [[stage_in]], texture2d<float> tex [[texture(0)]],\n"
    "                        constant Game &g [[buffer(0)]]) {\n"
    "  constexpr sampler sm(filter::linear, address::clamp_to_edge);\n"
    "  float2 uv = i.uv;\n"
    "  if (g.filter > 0.5f && uv.x >= g.frect.x && uv.x < g.frect.z && uv.y >= g.frect.y && uv.y < g.frect.w) {\n"
    "    float2 p = floor(uv);\n"
    "    float3 col;\n"
    "    if (g.filter < 1.5f) {\n"
    "      float2 f = fract(uv) - float2(0.5f);\n"
    "      float3 mid = dot_of(tex, g, p, float2(0.0f, 0.0f), f);\n"
    "      float3 s = mid + dot_of(tex, g, p, float2(-1.0f, -1.0f), f) + dot_of(tex, g, p, float2(0.0f, -1.0f), f)\n"
    "               + dot_of(tex, g, p, float2(1.0f, -1.0f), f) + dot_of(tex, g, p, float2(-1.0f, 0.0f), f)\n"
    "               + dot_of(tex, g, p, float2(1.0f, 0.0f), f) + dot_of(tex, g, p, float2(-1.0f, 1.0f), f)\n"
    "               + dot_of(tex, g, p, float2(0.0f, 1.0f), f) + dot_of(tex, g, p, float2(1.0f, 1.0f), f);\n"
    "      col = mix(1.2f * mid, s, float3(0.65f));\n"
    "    } else {\n"
    "      float2 gc = fract(uv);\n"
    "      float2 e = min(gc, float2(1.0f) - gc);\n"            /* to the border of the cell */
    "      float2 lw = max(float2(1.5f) / g.scale, float2(0.1f));\n"   /* the grid: a pixel and a half of the screen */
    "      float grid = mix(0.5f, 1.0f, smoothstep(0.0f, lw.x, e.x) * smoothstep(0.0f, lw.y, e.y));\n"
    "      float3 sub = g.colors < 0.5f ? float3(0.75f) + 0.25f * cos(6.2831853f * (float3(gc.x) - float3(0.16666667f, 0.5f, 0.83333333f)))\n"
    "                                  : float3(0.75f);\n"
    "      col = texel(tex, g, p) * sub * grid * 1.4f;\n"
    "    }\n"
    "    return float4(saturate(col), 1.0f);\n"
    "  }\n"
    "  float2 t = floor(uv);\n"
    "  float2 c = fract(uv) - float2(0.5f);\n"
    "  float2 range = float2(0.5f) - float2(0.5f) / g.scale;\n"
    "  float2 f = (c - clamp(c, -range, range)) * g.scale + float2(0.5f);\n"
    /* the transition of the last row and column stays in the picture (past it, the texture keeps an
     * older, larger picture) */
    "  float4 p = tex.sample(sm, clamp(t + f, float2(0.5f), g.fsize - float2(0.5f)) / g.texsize);\n"
    "  return float4(tone(p.rgb, g.colors), 1.0f);\n"
    "}\n";

typedef struct { float rect[4], color[4], border[4], radius, bw, pad[2]; } ShapeU;   /* 64 bytes */
typedef struct { float frect[4], texsize[2], scale[2], fsize[2], filter, colors; } GameU;    /* 48 bytes */

static void set_error(MtlRenderer *r, const char *what, id err)
{
    id d = err ? msg(err, "localizedDescription") : nil;
    snprintf(r->error, sizeof r->error, "%s%s%s", what, d ? ": " : "", d ? cstr(d) : "");
}

static id make_pso(MtlRenderer *r, id lib, const char *fs)
{
    id vf = msg_id(lib, "newFunctionWithName:", nsstr("vs_main"));
    id ff = msg_id(lib, "newFunctionWithName:", nsstr(fs));
    id pso = nil;
    if (vf && ff) {
        id d = new_of("MTLRenderPipelineDescriptor");
        msg_set(d, "setVertexFunction:", vf);
        msg_set(d, "setFragmentFunction:", ff);
        id ca = MSG1(id, NSUInteger, msg(d, "colorAttachments"), "objectAtIndexedSubscript:", 0);
        msg_setu(ca, "setPixelFormat:", PIXEL_BGRA8);
        msg_setb(ca, "setBlendingEnabled:", true);
        msg_setu(ca, "setSourceRGBBlendFactor:", BLEND_ONE);
        msg_setu(ca, "setDestinationRGBBlendFactor:", BLEND_ONE_MINUS_SRC_ALPHA);
        msg_setu(ca, "setSourceAlphaBlendFactor:", BLEND_ONE);
        msg_setu(ca, "setDestinationAlphaBlendFactor:", BLEND_ONE_MINUS_SRC_ALPHA);
        id err = nil;
        pso = MSG(id, (id, id *), r->device, "newRenderPipelineStateWithDescriptor:error:", d, &err);
        if (!pso) set_error(r, fs, err);
        release(d);
    } else {
        set_error(r, "shader function missing", nil);
    }
    release(vf);
    release(ff);
    return pso;
}

static id make_texture(MtlRenderer *r, NSUInteger format, NSUInteger w, NSUInteger h)
{
    id d = MSG(id, (NSUInteger, NSUInteger, NSUInteger, BOOL), CLASS("MTLTextureDescriptor"),
               "texture2DDescriptorWithPixelFormat:width:height:mipmapped:", format, w, h, (BOOL)NO);
    if (!d) return nil;
    msg_setu(d, "setUsage:", USAGE_SHADER_READ);
    return msg_id(r->device, "newTextureWithDescriptor:", d);
}

static void upload(id tex, int w, int h, const void *data, int bytes_per_row)
{
    PnsRegion rg = { { 0, 0, 0 }, { (NSUInteger)w, (NSUInteger)h, 1 } };
    MSG(void, (PnsRegion, NSUInteger, const void *, NSUInteger), tex, "replaceRegion:mipmapLevel:withBytes:bytesPerRow:",
        rg, 0, data, (NSUInteger)bytes_per_row);
}

bool mr_init(MtlRenderer *r, id device)
{
    memset(r, 0, sizeof *r);
    r->device = device;
    if (!device) { set_error(r, "no Metal device", nil); return false; }
    r->queue = msg(device, "newCommandQueue");
    id err = nil;
    id lib = MSG(id, (id, id, id *), device, "newLibraryWithSource:options:error:", nsstr(MSL), nil, &err);
    if (!lib) { set_error(r, "shaders", err); return false; }
    r->pso_shape = make_pso(r, lib, "fs_shape");
    r->pso_text = make_pso(r, lib, "fs_text");
    r->pso_game = make_pso(r, lib, "fs_game");
    release(lib);
    if (!r->queue || !r->pso_shape || !r->pso_text || !r->pso_game) return false;

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
    r->tex_font = make_texture(r, PIXEL_R8, ATLAS_W, ATLAS_H);
    if (!r->tex_font) { set_error(r, "font texture", nil); return false; }
    upload(r->tex_font, ATLAS_W, ATLAS_H, atlas, ATLAS_W);

    /* the canvas, once per frame in flight; black at first (the filter reads one texel past
     * the edge of the picture) */
    uint32_t *black = (uint32_t *)calloc((size_t)GAME_TEX_W * GAME_TEX_H, 4);
    for (int k = 0; k < MR_FRAMES; k++) {
        r->tex_game[k] = make_texture(r, PIXEL_BGRA8, GAME_TEX_W, GAME_TEX_H);
        r->vbuf[k] = MSG(id, (NSUInteger, NSUInteger), device, "newBufferWithLength:options:",
                         (NSUInteger)VB_FLOATS * sizeof(float), 0);
        if (!r->tex_game[k] || !r->vbuf[k]) { free(black); set_error(r, "textures", nil); return false; }
        if (black) upload(r->tex_game[k], GAME_TEX_W, GAME_TEX_H, black, GAME_TEX_W * 4);
    }
    free(black);
    r->ok = true;
    return true;
}

static void rgba(float out[4], uint32_t c)
{
    out[0] = ((c >> 16) & 255) / 255.f;
    out[1] = ((c >> 8) & 255) / 255.f;
    out[2] = (c & 255) / 255.f;
    out[3] = (c >> 24) / 255.f;
}

/* vertices for the next draw: NULL when the frame's buffer is full */
static float *vspace(float *vb, int *used, int n_floats, id enc, id buf)
{
    if (*used + n_floats > VB_FLOATS) return NULL;
    float *p = vb + *used;
    MSG(void, (id, NSUInteger, NSUInteger), enc, "setVertexBuffer:offset:atIndex:", buf, (NSUInteger)*used * sizeof(float), 0);
    *used += n_floats;
    return p;
}

static void draw(id enc, int prim, int count)
{
    MSG(void, (NSUInteger, NSUInteger, NSUInteger), enc, "drawPrimitives:vertexStart:vertexCount:",
        (NSUInteger)prim, 0, (NSUInteger)count);
}

void mr_frame(MtlRenderer *r, id layer, const UiList *l, int w, int h, const uint32_t *px, int stride, int fw, int fh)
{
    if (!r->ok || w <= 0 || h <= 0) return;
    int s = r->slot;
    if (r->cmd[s]) {                        /* the GPU must be done with this slot's texture and vertices */
        msg_void(r->cmd[s], "waitUntilCompleted");
        release(r->cmd[s]);
        r->cmd[s] = nil;
    }
    if (px && stride > 0 && stride <= GAME_TEX_W && fh > 0)
        upload(r->tex_game[s], stride, fh > GAME_TEX_H ? GAME_TEX_H : fh, px, stride * 4);

    id drawable = msg(layer, "nextDrawable");
    if (!drawable) return;
    id rpd = msg(CLASS("MTLRenderPassDescriptor"), "renderPassDescriptor");
    id ca = MSG1(id, NSUInteger, msg(rpd, "colorAttachments"), "objectAtIndexedSubscript:", 0);
    msg_set(ca, "setTexture:", msg(drawable, "texture"));
    msg_setu(ca, "setLoadAction:", LOAD_CLEAR);
    msg_setu(ca, "setStoreAction:", STORE_STORE);
    MSG1(void, PnsClearColor, ca, "setClearColor:", ((PnsClearColor){ 0, 0, 0, 1 }));
    id cb = msg(r->queue, "commandBuffer");
    id enc = msg_id(cb, "renderCommandEncoderWithDescriptor:", rpd);
    if (!enc) return;
    float screen[2] = { (float)w, (float)h };
    MSG(void, (const void *, NSUInteger, NSUInteger), enc, "setVertexBytes:length:atIndex:", screen, sizeof screen, 1);

    float *vb = (float *)MSG0(void *, r->vbuf[s], "contents");
    int used = 0;
    id cur = nil;
    for (int i = 0; i < l->n; i++) {
        const UiItem *it = &l->item[i];
        id pso = it->kind == UI_SHAPE ? r->pso_shape : it->kind == UI_TEXT ? r->pso_text : r->pso_game;
        if (it->kind == UI_GAME && (fw <= 0 || fh <= 0)) continue;
        if (pso != cur) { msg_set(enc, "setRenderPipelineState:", pso); cur = pso; }
        if (it->kind == UI_SHAPE) {
            ShapeU u;
            memset(&u, 0, sizeof u);
            u.rect[0] = it->x + it->w / 2;
            u.rect[1] = it->y + it->h / 2;
            u.rect[2] = it->w / 2;
            u.rect[3] = it->h / 2;
            float rad = it->radius;
            if (rad > it->w / 2) rad = it->w / 2;
            if (rad > it->h / 2) rad = it->h / 2;
            u.radius = rad;
            rgba(u.color, it->color);
            rgba(u.border, it->border);
            u.bw = it->border_w;
            float *v = vspace(vb, &used, 16, enc, r->vbuf[s]);
            if (!v) break;
            float x0 = it->x - 1, y0 = it->y - 1, x1 = it->x + it->w + 1, y1 = it->y + it->h + 1;
            float q[16] = { x0, y0, 0, 0,  x1, y0, 0, 0,  x0, y1, 0, 0,  x1, y1, 0, 0 };
            memcpy(v, q, sizeof q);
            MSG(void, (const void *, NSUInteger, NSUInteger), enc, "setFragmentBytes:length:atIndex:", &u, sizeof u, 0);
            draw(enc, PRIM_TRIANGLE_STRIP, 4);
        } else if (it->kind == UI_TEXT) {
            const char *t = l->text + it->text;
            int n = 0;
            for (const char *c = t; *c && n < 128; n++) utf8_next(&c);
            if (n == 0) continue;
            float *v = vspace(vb, &used, n * 24, enc, r->vbuf[s]);
            if (!v) break;
            float x = it->x, y = it->y, p = it->px;
            for (int k = 0; k < n; k++) {
                int gi = (int)(font_glyph(utf8_next(&t)) - font_glyphs);
                float u0 = (float)((gi % ATLAS_COLS) * 8) / ATLAS_W, v0 = (float)((gi / ATLAS_COLS) * 8) / ATLAS_H;
                float u1 = u0 + (float)FONT_W / ATLAS_W, v1 = v0 + (float)FONT_H / ATLAS_H;
                float gx1 = x + FONT_W * p, gy1 = y + FONT_H * p;
                float g[24] = { x, y, u0, v0,  gx1, y, u1, v0,  x, gy1, u0, v1,
                                gx1, y, u1, v0,  gx1, gy1, u1, v1,  x, gy1, u0, v1 };
                memcpy(v + k * 24, g, sizeof g);
                x += FONT_CELL_W * p;
            }
            float col[4];
            rgba(col, it->color);
            MSG(void, (const void *, NSUInteger, NSUInteger), enc, "setFragmentBytes:length:atIndex:", col, sizeof col, 0);
            MSG(void, (id, NSUInteger), enc, "setFragmentTexture:atIndex:", r->tex_font, 0);
            draw(enc, PRIM_TRIANGLE, n * 6);
        } else {
            float *v = vspace(vb, &used, 16, enc, r->vbuf[s]);
            if (!v) break;
            float x0 = it->x, y0 = it->y, x1 = it->x + it->w, y1 = it->y + it->h;
            float q[16] = { x0, y0, 0, 0,  x1, y0, (float)fw, 0,  x0, y1, 0, (float)fh,  x1, y1, (float)fw, (float)fh };
            memcpy(v, q, sizeof q);
            GameU u = { { it->fx0, it->fy0, it->fx1, it->fy1 }, { (float)GAME_TEX_W, (float)GAME_TEX_H }, { it->w / fw, it->h / fh },
                        { (float)fw, (float)fh }, (float)it->filter, (float)it->colors };
            MSG(void, (const void *, NSUInteger, NSUInteger), enc, "setFragmentBytes:length:atIndex:", &u, sizeof u, 0);
            MSG(void, (id, NSUInteger), enc, "setFragmentTexture:atIndex:", r->tex_game[s], 0);
            draw(enc, PRIM_TRIANGLE_STRIP, 4);
        }
    }
    msg_void(enc, "endEncoding");
    msg_set(cb, "presentDrawable:", drawable);
    msg_void(cb, "commit");
    retain(cb);
    r->cmd[s] = cb;
    r->slot = (s + 1) % MR_FRAMES;
}
