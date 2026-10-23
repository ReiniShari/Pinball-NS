/*
 * uisim.c - runs the mobile version (app.c + ui.c + the game) on Linux, with scripted
 * touches and a software renderer for the display list, to test the touch interface.
 *
 *   uisim [-size WxH] [-dir DIR] [-shot PREFIX] [-insets T,B,L,R,CORNER] cmd...
 *   cmds: w:N  d:ID:X:Y  m:ID:X:Y  u:ID:X:Y  tap:X:Y  hold:X:Y:N  back  p:BTN:N
 *         import:PATH  suspend  restart  s:NAME  bot:N:SEED (random touches on the flippers)
 *         c:NAME (the picture sent to the screen, in pixels of the game)  info / cab (layout)
 *         bonus:STAGE (the slot sends the ball to a bonus stage, as pbdebug -bonus)
 *         cs:N:NAME (N frames in a row, each as c: does: NAME_000...)
 *         catch:top|bottom, evo:top|bottom (the mode starts when the ball is in that half, as
 *         pbdebug -force), hit:N (the catch mode Pokemon hit every N frames, ball in the bottom
 *         half), up:N (the ball thrown up into the top half N frames after the third hit), vlog
 *         (writes to video memory during special modes, by page), tr:N (the status
 *         bar's position and the ball's, N frames), rec:NAME[:special] / rec:off (every frame
 *         from now on, as c: does, NAME_FRAME.png; special: only during a special mode),
 *         glitch:N:SEED (as bot:, and every picture very different from both its neighbours
 *         while they look alike is reported: NAME_glitchK_f_a/b/c.png),
 *         vtrace:T0:T1:F0:F1 (writes to the tiles T0..T1 of the top page between frames F0 and
 *         F1, out of time included, with the writer), perf:N:SEED (as bot:, the time of each frame:
 *         app_run_frame, then app_build + app_frame)
 */
#include "../platform/mobile/app.h"
#include "engine.h"
#include "../src/front/font5x7.h"
#include "../src/game/pinball_us.h"
#include "png_write.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include "botrand.h"
#include <string.h>
#include <sys/stat.h>
#include <time.h>
#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#endif

#ifdef APP_PROF
extern double app_prof[3];
#endif

static double now_ms(void)
{
#ifdef _WIN32
    static LARGE_INTEGER f;
    LARGE_INTEGER c;
    if (!f.QuadPart) QueryPerformanceFrequency(&f);
    QueryPerformanceCounter(&c);
    return (double)c.QuadPart * 1000.0 / (double)f.QuadPart;
#else
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec * 1000.0 + t.tv_nsec / 1e6;
#endif
}

static MobileApp app;
static int W = 1080, H = 2400;
static uint32_t *fb;
static double now;
static const char *prefix = "ui";
static int ins[5];                    /* -insets T,B,L,R,CORNER: camera cut-out, rounded corners */
static char dir[512] = "uisim_data";

/* ---------------- software renderer ---------------- */

static void blend(uint32_t *d, uint32_t c, float a)
{
    if (a <= 0) return;
    if (a > 1) a = 1;
    float r = (float)((c >> 16) & 255), g = (float)((c >> 8) & 255), b = (float)(c & 255);
    float dr = (float)((*d >> 16) & 255), dg = (float)((*d >> 8) & 255), db = (float)(*d & 255);
    uint32_t R = (uint32_t)(dr + (r - dr) * a + 0.5f), G = (uint32_t)(dg + (g - dg) * a + 0.5f), B = (uint32_t)(db + (b - db) * a + 0.5f);
    *d = (R << 16) | (G << 8) | B;
}

static void draw_shape(const UiItem *it)
{
    float cx = it->x + it->w / 2, cy = it->y + it->h / 2, hw = it->w / 2, hh = it->h / 2;
    float r = fminf(it->radius, fminf(hw, hh));
    int x0 = (int)floorf(it->x - 1), x1 = (int)ceilf(it->x + it->w + 1);
    int y0 = (int)floorf(it->y - 1), y1 = (int)ceilf(it->y + it->h + 1);
    if (x0 < 0) x0 = 0;
    if (y0 < 0) y0 = 0;
    if (x1 > W) x1 = W;
    if (y1 > H) y1 = H;
    float fa = (float)(it->color >> 24) / 255.f, ba = (float)(it->border >> 24) / 255.f;
    for (int y = y0; y < y1; y++)
        for (int x = x0; x < x1; x++) {
            float qx = fabsf(x + 0.5f - cx) - (hw - r), qy = fabsf(y + 0.5f - cy) - (hh - r);
            float ox = fmaxf(qx, 0), oy = fmaxf(qy, 0);
            float d = sqrtf(ox * ox + oy * oy) + fminf(fmaxf(qx, qy), 0) - r;
            float cov = 0.5f - d;
            if (cov <= 0) continue;
            if (cov > 1) cov = 1;
            uint32_t *p = &fb[y * W + x];
            if (it->border_w > 0 && ba > 0) {
                float inb = 0.5f + (d + it->border_w);          /* 1 inside the border band */
                if (inb > 1) inb = 1;
                if (inb < 0) inb = 0;
                /* fill first, then the border on top */
                blend(p, it->color, fa * cov * (1 - inb));
                blend(p, it->border, ba * cov * inb);
            } else {
                blend(p, it->color, fa * cov);
            }
        }
}

static void draw_text(const UiList *l, const UiItem *it)
{
    const char *s = l->text + it->text;
    float x = it->x, a = (float)(it->color >> 24) / 255.f;
    int px = (int)it->px;
    if (px < 1) px = 1;
    while (*s) {
        uint32_t cp = utf8_next(&s);
        const FontGlyph *g = font_glyph(cp);
        for (int r = 0; r < FONT_H; r++)
            for (int c = 0; c < FONT_W; c++)
                if (g->rows[r] & (0x10 >> c))
                    for (int yy = 0; yy < px; yy++)
                        for (int xx = 0; xx < px; xx++) {
                            int X = (int)x + c * px + xx, Y = (int)it->y + r * px + yy;
                            if (X >= 0 && X < W && Y >= 0 && Y < H) blend(&fb[Y * W + X], it->color, a);
                        }
        x += FONT_CELL_W * px;
    }
}

static void draw_game(const UiItem *it)
{
    int fw, fh, stride;
    const uint32_t *px = app_frame(&app, &fw, &fh, &stride);
    if (!px) return;
    for (int y = (int)it->y; y < (int)(it->y + it->h); y++) {
        if (y < 0 || y >= H) continue;
        int sy = (int)((y + 0.5f - it->y) * fh / it->h);
        if (sy < 0 || sy >= fh) continue;
        for (int x = (int)it->x; x < (int)(it->x + it->w); x++) {
            if (x < 0 || x >= W) continue;
            int sx = (int)((x + 0.5f - it->x) * fw / it->w);
            if (sx < 0 || sx >= fw) continue;
            fb[y * W + x] = px[sy * stride + sx] & 0xFFFFFF;
        }
    }
}

static UiList list;

static void render(void)
{
    app_build(&app, &list);
    for (int i = 0; i < list.n; i++) {
        const UiItem *it = &list.item[i];
        if (it->kind == UI_SHAPE) draw_shape(it);
        else if (it->kind == UI_TEXT) draw_text(&list, it);
        else draw_game(it);
    }
}

#ifdef UISIM_GL
/* the same display list drawn by the OpenGL ES renderer of the Android version (Mesa) */
#include "../platform/android/gles_render.h"
#include <EGL/egl.h>
#include <EGL/eglext.h>
static GlRenderer gr;
static bool gl_ready;
static void gl_init(void)
{
    EGLDisplay dpy = eglGetPlatformDisplay(EGL_PLATFORM_SURFACELESS_MESA, EGL_DEFAULT_DISPLAY, NULL);
    if (dpy == EGL_NO_DISPLAY || !eglInitialize(dpy, NULL, NULL)) { fprintf(stderr, "no EGL\n"); exit(1); }
    eglBindAPI(EGL_OPENGL_ES_API);
    const EGLint ca[] = { EGL_SURFACE_TYPE, EGL_PBUFFER_BIT, EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
                          EGL_RED_SIZE, 8, EGL_GREEN_SIZE, 8, EGL_BLUE_SIZE, 8, EGL_NONE };
    EGLConfig cfg; EGLint n = 0;
    if (!eglChooseConfig(dpy, ca, &cfg, 1, &n) || n < 1) { fprintf(stderr, "no EGL config\n"); exit(1); }
    const EGLint sa[] = { EGL_WIDTH, W, EGL_HEIGHT, H, EGL_NONE };
    EGLSurface s = eglCreatePbufferSurface(dpy, cfg, sa);
    const EGLint xa[] = { EGL_CONTEXT_CLIENT_VERSION, 2, EGL_NONE };
    EGLContext c = eglCreateContext(dpy, cfg, EGL_NO_CONTEXT, xa);
    if (!eglMakeCurrent(dpy, s, s, c)) { fprintf(stderr, "eglMakeCurrent failed 0x%x\n", eglGetError()); exit(1); }
    printf("GL: %s / %s\n", (const char *)glGetString(GL_RENDERER), (const char *)glGetString(GL_VERSION));
    if (!gr_init(&gr)) { fprintf(stderr, "renderer init failed\n"); exit(1); }
    gl_ready = true;
}

static void shot(const char *name)
{
    if (!gl_ready) gl_init();
    app_build(&app, &list);
    int fw, fh, stride;
    const uint32_t *px = app_frame(&app, &fw, &fh, &stride);
    if (px) gr_upload(&gr, px, stride, fh);
    gr_draw(&gr, &list, W, H, px ? fw : 0, px ? fh : 0);
    glFinish();
    uint8_t *rgba = (uint8_t *)malloc((size_t)W * H * 4);
    glReadPixels(0, 0, W, H, GL_RGBA, GL_UNSIGNED_BYTE, rgba);
    for (int y = 0; y < H; y++)
        for (int x = 0; x < W; x++) {
            const uint8_t *q = rgba + ((size_t)(H - 1 - y) * W + x) * 4;
            fb[y * W + x] = ((uint32_t)q[0] << 16) | ((uint32_t)q[1] << 8) | q[2];
        }
    free(rgba);
    char p[600];
    snprintf(p, sizeof p, "%s_%s.png", prefix, name);
    png_write_rgb(p, fb, W, H, W, 1);
}
#else
static void shot(const char *name)
{
    render();
    char p[600];
    snprintf(p, sizeof p, "%s_%s.png", prefix, name);
    png_write_rgb(p, fb, W, H, W, 1);
}
#endif

/* ---------------- driving ---------------- */

static uint8_t pad;
static long frames;

/* catch:HALF / evo:HALF: the next time the ball is in that half, the mode starts (the game's own
 * routine, as pbdebug -force); hit:N: the catch mode Pokemon is hit every N frames */
static int force_kind, force_half, hit_every;
static long up_after = -1, up_at = -1;   /* up:N: the ball thrown up N frames after the third hit */
static char rec_name[64];             /* rec:NAME: every frame as c: does (NAME_FRAME.png), rec:off */
static bool rec_special;              /* rec:NAME:special: only while a special mode is on */
static void rec_frame(void);
static bool hk_cry_log(GBC *g, void *u)       /* cries: the game plays them with the interrupts off */
{
    (void)u;
    if (!g->frozen) printf("frame %ld: cry (14:4000)\n", frames);
    return false;
}

/* vlog: the CPU's writes to video memory during a special mode, by page (ranges of each frame) */
static bool vlog_on;
static long vlog_frame = -1;
static int vlog_lo[2][2], vlog_hi[2][2], vlog_n[2][2], vlog_q[2][2];
static void vlog_flush(void)
{
    for (int p = 0; p < 2; p++)
        for (int b = 0; b < 2; b++)
            if (vlog_n[p][b])
                printf("vram frame %ld stage %d page %s bank %d: %d writes %04X-%04X (%d in queue entries)\n", vlog_frame,
                       app.pb ? gbc_read(&app.pb->g, W_CurrentStage) : -1, p ? "top" : "main", b, vlog_n[p][b],
                       0x8000 + vlog_lo[p][b], 0x8000 + vlog_hi[p][b], vlog_q[p][b]);
    memset(vlog_n, 0, sizeof vlog_n);
    memset(vlog_q, 0, sizeof vlog_q);
}
static void vlog_fn(GBC *g, int page, int bank, uint16_t off, uint8_t v, void *u)
{
    (void)v; (void)u;
    if (!gbc_read(g, W_InSpecialMode) || g->frozen || page > 1) return;
    if (frames != vlog_frame) { vlog_flush(); vlog_frame = frames; }
    if (!vlog_n[page][bank] || off < vlog_lo[page][bank]) vlog_lo[page][bank] = off;
    if (!vlog_n[page][bank] || off > vlog_hi[page][bank]) vlog_hi[page][bank] = off;
    vlog_n[page][bank]++;
    if (app.pb->st.nforced > 0) vlog_q[page][bank]++;
}
/* vtrace:T0:T1:F0:F1: every write to the tiles T0..T1 (bank 0) of the top page between frames
 * F0 and F1, out of time included, with the writer and its stack */
static int vt_t0 = -1, vt_t1, vt_f0, vt_f1;
static void vtrace_fn(GBC *g, int page, int bank, uint16_t off, uint8_t v, void *u)
{
    (void)u;
    if (page != PB_PAGE_TOP || bank != 0 || off >= 0x1800 || frames < vt_f0 || frames > vt_f1) return;
    int t = off >> 4;
    if (t < vt_t0 || t > vt_t1) return;
    Pinball *pb = app.pb;
    printf("vt f%ld tile %d %04X=%02X frozen %d other_run %d stretch %d nforced %d stage %d pc %02X:%04X stack", frames, t,
           0x8000 + off, v, g->frozen, pb->other_run, g->stretch, pb->st.nforced, gbc_read(g, W_CurrentStage),
           (int)g->s.rom_bank, g->s.pc);
    for (int i = 0; i < 8; i++)
        printf(" %04X", gbc_read(g, (uint16_t)(g->s.sp + 2 * i)) | gbc_read(g, (uint16_t)(g->s.sp + 2 * i + 1)) << 8);
    printf("\n");
}
static bool force_hooked;
static bool hk_force(GBC *g, void *u)
{
    (void)u;
    if (!force_kind || g->frozen) return false;
    uint8_t st = gbc_read(g, W_CurrentStage);
    if (gbc_read(g, W_CurrentScreen) != SCREEN_PINBALL_GAME || ((st & 1) != 0) != (force_half == 1)) return false;
    if (gbc_read(g, W_InSpecialMode) || !gbc_read(g, W_PinballIsVisible)) return false;
    if (force_kind == 2 && gbc_read(g, 0xD460) == 0) { gbc_write(g, 0xD300, 0x12); gbc_write(g, 0xD460, 1); }
    GBCState *s = &g->s;
    gbc_push(g, s->pc);
    s->hram[0x8A - 0x80] = s->a;                          /* hFarCallTempA */
    s->a = 4;
    uint16_t addr = force_kind == 1 ? 0x403F : 0x4AB3;    /* StartCatchEmMode / StartEvolutionMode */
    s->h = (uint8_t)(addr >> 8);
    s->l = (uint8_t)addr;
    s->pc = 0x054F;                                       /* BankSwitch */
    printf("frame %ld: %s mode started (stage %d)\n", frames, force_kind == 1 ? "catch" : "evolution", st);
    force_kind = 0;
    return true;
}

static void frame(void)
{
    /* as the device: the interface is built at every frame (layout, key animations) */
    app_build(&app, &list);
    now += 70224.0 / 4194304.0;
    app_update(&app, now);
    app_set_pad(&app, pad);
    if (hit_every > 0 && app.pb && frames % hit_every == 0) {
        GBC *g = &app.pb->g;
        /* only where the ball can hit it: on the billboard, in the bottom half */
        if (gbc_read(g, W_InSpecialMode) && gbc_read(g, W_SpecialMode) == 0 && gbc_read(g, 0xD5BB) &&
            (gbc_read(g, W_CurrentStage) & 1)) {
            gbc_write(g, 0xD5BF, 1);                      /* wBallHitWildMon: the ball hit the Pokemon */
            printf("frame %ld: Pokemon hit (hits so far %d)\n", frames, gbc_read(g, 0xD5C0));
            if (up_after >= 0 && gbc_read(g, 0xD5C0) == 2) up_at = frames + up_after;   /* this one is the third */
        }
    }
    if (frames == up_at && app.pb) {
        /* the ball thrown up from the top of the bottom half: it goes on into the top half */
        GBC *g = &app.pb->g;
        gbc_write(g, W_BallYPos + 1, 0x30);               /* position, previous position */
        gbc_write(g, 0xD4BA, 0x31);
        gbc_write(g, 0xD4BD, 0x00);                       /* Y velocity -6 pixels a frame (1/256ths) */
        gbc_write(g, 0xD4BE, 0xFA);
        printf("frame %ld: ball thrown up (stage %d)\n", frames, gbc_read(g, W_CurrentStage));
    }
    app_run_frame(&app);
    if (rec_name[0]) rec_frame();
    int16_t tmp[4096];
    while (app_audio_queued(&app) > 2048) app_audio_pull(&app, tmp, 1024);
    app_take_haptic(&app);
    frames++;
}

static void rec_frame(void)
{
    if (rec_special && (!app.pb || !gbc_read(&app.pb->g, W_InSpecialMode))) return;
    app_build(&app, &list);
    int fw, fh, stride;
    const uint32_t *px = app_frame(&app, &fw, &fh, &stride);
    char p[600];
    snprintf(p, sizeof p, "%s_%s_%06ld.png", prefix, rec_name, frames);
    if (px) png_write_rgb(p, px, fw, fh, stride, 1);
}

/* glitch:N:SEED: the bot plays N frames; a frame very different from both its neighbours while
 * they look alike (one odd picture) is reported, with the three pictures (NAME_glitchK_a/b/c) */
static uint32_t *gl_buf[3];
static int gl_w, gl_h;
static long gl_found;
static void png3(const char *tag, int k, uint32_t *const b[3])
{
    static const char *const sfx[3] = { "a", "b", "c" };
    for (int i = 0; i < 3; i++) {
        char p[600];
        snprintf(p, sizeof p, "%s_glitch%d_%s_%s.png", prefix, k, tag, sfx[i]);
        png_write_rgb(p, b[i], gl_w, gl_h, gl_w, 1);
    }
}
static long gl_diff(const uint32_t *a, const uint32_t *b, int n)
{
    long d = 0;
    for (int i = 0; i < n; i++) d += (a[i] & 0xFFFFFF) != (b[i] & 0xFFFFFF);
    return d;
}
static void glitch_frame(long k)
{
    app_build(&app, &list);
    int fw, fh, stride;
    const uint32_t *px = app_frame(&app, &fw, &fh, &stride);
    if (!px) return;
    if (!gl_buf[0]) for (int i = 0; i < 3; i++) gl_buf[i] = (uint32_t *)calloc((size_t)ND_MAX_W * ND_MAX_H, 4);
    if (fw != gl_w || fh != gl_h) { gl_w = fw; gl_h = fh; k = 0; }
    uint32_t *t = gl_buf[0];                             /* oldest becomes the newest */
    gl_buf[0] = gl_buf[1]; gl_buf[1] = gl_buf[2]; gl_buf[2] = t;
    for (int y = 0; y < fh; y++) memcpy(gl_buf[2] + (size_t)y * fw, px + (size_t)y * stride, (size_t)fw * 4);
    if (k < 2) return;
    int n = fw * fh;
    long d01 = gl_diff(gl_buf[0], gl_buf[1], n), d12 = gl_diff(gl_buf[1], gl_buf[2], n), d02 = gl_diff(gl_buf[0], gl_buf[2], n);
    long lim = n / 20;                                   /* 5 % of the picture */
    if (d01 > lim && d12 > lim && d02 * 4 < d01 && d02 * 4 < d12) {
        gl_found++;
        printf("frame %ld: odd picture (%ld and %ld pixels from its neighbours, which differ by %ld) screen %d stage %d\n",
               frames - 1, d01, d12, d02, app.pb ? pb_screen(app.pb) : -1, app.pb ? pb_stage(app.pb) : -1);
        if (gl_found <= 12) png3("f", (int)gl_found, gl_buf);
    }
}

static int btn(const char *n)
{
    if (!strcmp(n, "a")) return GBC_A;
    if (!strcmp(n, "b")) return GBC_B;
    if (!strcmp(n, "sel")) return GBC_SELECT;
    if (!strcmp(n, "start")) return GBC_START;
    if (!strcmp(n, "right")) return GBC_RIGHT;
    if (!strcmp(n, "left")) return GBC_LEFT;
    if (!strcmp(n, "up")) return GBC_UP;
    if (!strcmp(n, "down")) return GBC_DOWN;
    fprintf(stderr, "bad button %s\n", n);
    exit(2);
}

int main(int argc, char **argv)
{
    engine_from_env();
    for (int i = 1; i < argc; i++) {
        char *a = argv[i];
        if (!strcmp(a, "-size")) { sscanf(argv[++i], "%dx%d", &W, &H); continue; }
        if (!strcmp(a, "-dir")) { snprintf(dir, sizeof dir, "%s", argv[++i]); continue; }
        if (!strcmp(a, "-shot")) { prefix = argv[++i]; continue; }
        if (!strcmp(a, "-insets")) { sscanf(argv[++i], "%d,%d,%d,%d,%d", &ins[0], &ins[1], &ins[2], &ins[3], &ins[4]); continue; }
        if (i == 1 || argv[i - 1][0] != '-') break;
    }
    mkdir(dir, 0755);
    fb = (uint32_t *)calloc((size_t)W * H, 4);
    app_init(&app, dir, 48000);
    app_layout(&app, W, H);
    app_set_insets(&app, ins[0], ins[1], ins[2], ins[3], ins[4]);
    for (int i = 1; i < argc; i++) {
        char *a = argv[i];
        if (!strcmp(a, "-size") || !strcmp(a, "-dir") || !strcmp(a, "-shot") || !strcmp(a, "-insets")) { i++; continue; }
        float x, y; int id, n, seed;
        if (!strncmp(a, "w:", 2)) { n = atoi(a + 2); for (int k = 0; k < n; k++) frame(); }
        else if (sscanf(a, "d:%d:%f:%f", &id, &x, &y) == 3) app_touch(&app, UI_DOWN, id, x, y);
        else if (sscanf(a, "m:%d:%f:%f", &id, &x, &y) == 3) app_touch(&app, UI_MOVE, id, x, y);
        else if (sscanf(a, "u:%d:%f:%f", &id, &x, &y) == 3) app_touch(&app, UI_UP, id, x, y);
        else if (sscanf(a, "tap:%f:%f", &x, &y) == 2) {
            app_touch(&app, UI_DOWN, 9, x, y); for (int k = 0; k < 4; k++) frame();
            app_touch(&app, UI_UP, 9, x, y); frame();
        } else if (sscanf(a, "hold:%f:%f:%d", &x, &y, &n) == 3) {
            app_touch(&app, UI_DOWN, 8, x, y); for (int k = 0; k < n; k++) frame();
            app_touch(&app, UI_UP, 8, x, y); frame();
        } else if (!strcmp(a, "back")) app_back(&app);
        else if (!strcmp(a, "info") || !strcmp(a, "cab")) {
            /* the layout: the canvas, the game, the keys and the menu entries, in screen pixels */
            Ui *u = &app.ui;
            static const char *names[ND_NBTN] = { "lflip", "rflip", "pad", "menu", "start" };
            printf("canvas %dx%d scale %.3f game %d,%d %dx%d\n", u->nd.cw, u->nd.ch, u->nd.scale, u->nd.gx, u->nd.gy,
                   u->nd.gw, u->nd.gh);
            for (int k = 0; k < ND_NBTN; k++) {
                NdRect r = u->nd.btn[k];
                printf("  %s at %.0f,%.0f (%.0fx%.0f)\n", names[k], (r.x + r.w / 2.0f) * u->nd.scale, (r.y + r.h / 2.0f) * u->nd.scale,
                       r.w * u->nd.scale, r.h * u->nd.scale);
            }
            if (!strcmp(a, "info"))
                for (int k = 0; k < UI_MENU_ITEMS; k++) { UiRect r = ui_menu_item(u, k); printf("  menu item %d at %.0f,%.0f\n", k, r.x + r.w / 2, r.y + r.h / 2); }
        }
        else if (!strcmp(a, "vram") && app.pb) {
            /* the main page: registers, BG palettes, BG and window maps (tile, attributes) */
            const GBCState *s = &app.pb->g.s;
            const GBCPage *pg = &s->page[PB_PAGE_MAIN];
            uint8_t lcdc = s->io[0x40];
            printf("LCDC %02X SCX %d SCY %d WX %d WY %d screen %d\n", lcdc, s->io[0x43], s->io[0x42], s->io[0x4B], s->io[0x4A], pb_screen(app.pb));
            for (int p = 0; p < 8; p++) {
                printf("  bgpal %d:", p);
                for (int c = 0; c < 4; c++) printf(" %04X", pg->bgpal[p * 8 + c * 2] | (pg->bgpal[p * 8 + c * 2 + 1] << 8));
                printf("\n");
            }
            for (int w = 0; w < 2; w++) {
                uint16_t map = (lcdc & (w ? 0x40 : 0x08)) ? 0x1C00 : 0x1800;
                printf("  %s map %04X\n", w ? "window" : "bg", 0x8000 + map);
                for (int r = 0; r < 32; r++) {
                    printf("  %2d:", r);
                    for (int c = 0; c < 20; c++) printf(" %02X/%02X", pg->vram[0][map + r * 32 + c], pg->vram[1][map + r * 32 + c]);
                    printf("\n");
                }
            }
        }
        else if (!strcmp(a, "btn")) printf("buttons %02X field %d haptic %d\n", ui_buttons(&app.ui), app.ui.field, app.ui.haptic);
        else if (!strncmp(a, "p:", 2)) {
            char nm[16]; n = 1;
            sscanf(a + 2, "%15[^:]:%d", nm, &n);
            pad |= (uint8_t)btn(nm);
            for (int k = 0; k < n; k++) frame();
            pad &= (uint8_t)~btn(nm);
            frame();
        } else if (!strncmp(a, "import:", 7)) {
            FILE *f = fopen(a + 7, "rb");
            static uint8_t buf[8 << 20];
            size_t r = f ? fread(buf, 1, sizeof buf, f) : 0;
            if (f) fclose(f);
            printf("import %s: %s\n", a + 7, app_import_rom(&app, buf, r) ? "ok" : "refused");
        } else if (!strcmp(a, "suspend")) app_suspend(&app);
        else if (!strcmp(a, "restart")) {
            app_free(&app);
            app_init(&app, dir, 48000);
            app_layout(&app, W, H);
            app_set_insets(&app, ins[0], ins[1], ins[2], ins[3], ins[4]);
        } else if (!strncmp(a, "s:", 2)) shot(a + 2);
        else if (!strncmp(a, "c:", 2)) {
            /* the image before scaling to the screen: pixel perfect at any integer zoom */
            app_build(&app, &list);
            int fw, fh, stride;
            const uint32_t *px = app_frame(&app, &fw, &fh, &stride);
            char p[600];
            snprintf(p, sizeof p, "%s_%s.png", prefix, a + 2);
            if (px) png_write_rgb(p, px, fw, fh, stride, 1);
        } else if (sscanf(a, "cs:%d:", &n) == 1 && strchr(a + 3, ':')) {
            /* N frames in a row, each one as c: does (NAME_000.png...) */
            const char *nm = strchr(a + 3, ':') + 1;
            for (int k = 0; k < n; k++) {
                frame();
                app_build(&app, &list);
                int fw, fh, stride;
                const uint32_t *px = app_frame(&app, &fw, &fh, &stride);
                char p[600];
                snprintf(p, sizeof p, "%s_%s_%03d.png", prefix, nm, k);
                if (px) png_write_rgb(p, px, fw, fh, stride, 1);
            }
        } else if ((!strncmp(a, "catch:", 6) || !strncmp(a, "evo:", 4)) && app.pb) {
            force_kind = a[0] == 'c' ? 1 : 2;
            force_half = strstr(a, "bottom") != NULL;
            if (!force_hooked) gbc_add_hook(&app.pb->g, 0, R_ResolveGameObjectCollisions, hk_force, NULL);
            force_hooked = true;
        } else if (!strncmp(a, "rec:", 4)) {
            if (!strcmp(a + 4, "off")) rec_name[0] = 0;
            else {
                snprintf(rec_name, sizeof rec_name, "%s", a + 4);
                char *c = strchr(rec_name, ':');
                rec_special = c && !strcmp(c + 1, "special");
                if (c) *c = 0;
            }
        } else if (!strcmp(a, "nodeflicker")) {
            app.no_deflicker = true;
        } else if (!strcmp(a, "cries") && app.pb) {
            gbc_add_hook(&app.pb->g, 0x14, 0x4000, hk_cry_log, NULL);
        } else if (sscanf(a, "vtrace:%d:%d:%d:%d", &vt_t0, &vt_t1, &vt_f0, &vt_f1) == 4 && app.pb) {
            app.pb->g.vram_fn = vtrace_fn;
        } else if (!strcmp(a, "vlog") && app.pb) {
            app.pb->g.vram_fn = vlog_fn;
            vlog_on = true;
        } else if (sscanf(a, "up:%d", &n) == 1) {
            up_after = n;
        } else if (sscanf(a, "hit:%d", &n) == 1) {
            hit_every = n;
        } else if (sscanf(a, "tr:%d", &n) == 1 && app.pb) {
            /* N frames, each one with the window's position and the ball's (the status bar) */
            for (int k = 0; k < n; k++) {
                frame();
                GBC *g = &app.pb->g;
                printf("tr %4d stage %2d hWY %3d WY %3d LCDC %02X ball %3d,%3d  D4B3-D4BE:", k, gbc_read(g, W_CurrentStage),
                       gbc_read(g, H_WY), g->s.io[0x4A], g->s.io[0x40],
                       gbc_read(g, W_BallXPos + 1), gbc_read(g, W_BallYPos + 1));
                for (int i = 0; i < 12; i++) printf(" %02X", gbc_read(g, (uint16_t)(0xD4B3 + i)));
                printf("  KEY1 %02X", g->s.io[0x4D]);
                printf("\n");
            }
        } else if (sscanf(a, "bonus:%d", &n) == 1) {
            /* as the "go to bonus" reward of the slot, once the ball is in the bottom half */
            GBC *g = app.pb ? &app.pb->g : NULL;
            int k = 0;
            for (; g && k < 20000; k++) {
                uint8_t st = gbc_read(g, W_CurrentStage);
                if (gbc_read(g, W_CurrentScreen) == SCREEN_PINBALL_GAME && (st == 1 || st == 5) && !gbc_read(g, W_InSpecialMode) &&
                    gbc_read(g, W_PinballIsVisible) && !gbc_read(g, 0xD495))
                    break;
                frame();
            }
            if (!g || k == 20000) { fprintf(stderr, "bonus %d: the ball never reached a table\n", n); continue; }
            gbc_write(g, 0xD495, 1);                              /* wGoingToBonusStage */
            gbc_write(g, W_MoveToNextScreenState, 1);
            gbc_write(g, 0xD497, (uint8_t)n);                     /* wNextStage */
        }
        else if (sscanf(a, "glitch:%d:%d", &n, &seed) == 2) {
            srand((unsigned)seed);
            float gx, gy, gw, gh;
            for (int k = 0; k < n; k++) {
                nd_game_rect(&app.ui.nd, &gx, &gy, &gw, &gh);
                if (k % 6 == 0) {
                    app_touch(&app, UI_CANCEL, 0, 0, 0);
                    if (rand() % 100 < 45) app_touch(&app, UI_DOWN, 1, gx + gw * 0.2f, gy + gh * 0.7f);
                    if (rand() % 100 < 45) app_touch(&app, UI_DOWN, 2, gx + gw * 0.8f, gy + gh * 0.7f);
                }
                if (k % 600 == 300 && app.pb && !pb_in_game(app.pb)) { pad |= GBC_A; frame(); pad &= (uint8_t)~GBC_A; }
                frame();
                glitch_frame(k);
            }
            app_touch(&app, UI_CANCEL, 0, 0, 0);
            printf("glitch: %ld odd pictures in %d frames\n", gl_found, n);
        }
        else if (sscanf(a, "perf:%d:%d", &n, &seed) == 2) {
            /* as bot:, each frame timed: app_run_frame (the game, its picture's background), then
             * app_build + app_frame (the controls, the picture shown), as the Android glue does */
            srand((unsigned)seed);
            float gx, gy, gw, gh;
            nd_game_rect(&app.ui.nd, &gx, &gy, &gw, &gh);
            double sum[2] = { 0, 0 }, mx[2] = { 0, 0 };
#ifdef APP_PROF
            memset(app_prof, 0, sizeof app_prof);
#endif
            long mxf[2] = { 0, 0 }, hist[2][24] = { { 0 } };
            for (int k = 0; k < n; k++) {
                if (k % 6 == 0) {
                    app_touch(&app, UI_CANCEL, 0, 0, 0);
                    if (rand() % 100 < 45) app_touch(&app, UI_DOWN, 1, gx + gw * 0.2f, gy + gh * 0.7f);
                    if (rand() % 100 < 45) app_touch(&app, UI_DOWN, 2, gx + gw * 0.8f, gy + gh * 0.7f);
                }
                double t0 = now_ms();
                frame();
                double t1 = now_ms();
                app_build(&app, &list);
                int fw, fh, stride;
                app_frame(&app, &fw, &fh, &stride);
                double t2 = now_ms(), d[2] = { t1 - t0, t2 - t1 };
                for (int i = 0; i < 2; i++) {
                    sum[i] += d[i];
                    if (d[i] > mx[i]) { mx[i] = d[i]; mxf[i] = frames; }
                    int b = (int)(d[i] * 8);
                    hist[i][b < 23 ? b : 23]++;
                }
            }
            app_touch(&app, UI_CANCEL, 0, 0, 0);
            static const char *const what[2] = { "app_run_frame", "app_build + app_frame" };
            for (int i = 0; i < 2; i++) {
                printf("perf %s: mean %.3f ms, max %.2f ms (frame %ld); by 1/8 ms:", what[i], sum[i] / (n ? n : 1), mx[i], mxf[i]);
                for (int b = 0; b < 24; b++) if (hist[i][b]) printf(" %.3f:%ld", b / 8.0, hist[i][b]);
                printf("\n");
            }
#ifdef APP_PROF
            printf("perf parts: the game %.3f ms, the flicker filter %.3f ms, the background %.3f ms a frame\n",
                   app_prof[0] / (n ? n : 1), app_prof[1] / (n ? n : 1), app_prof[2] / (n ? n : 1));
#endif
        }
        else if (sscanf(a, "bot:%d:%d", &n, &seed) == 2) {
            srand((unsigned)seed);
            float gx, gy, gw, gh;
            nd_game_rect(&app.ui.nd, &gx, &gy, &gw, &gh);
            for (int k = 0; k < n; k++) {
                if (k % 6 == 0) {
                    app_touch(&app, UI_CANCEL, 0, 0, 0);
                    if (rand() % 100 < 45) app_touch(&app, UI_DOWN, 1, gx + gw * 0.2f, gy + gh * 0.7f);
                    if (rand() % 100 < 45) app_touch(&app, UI_DOWN, 2, gx + gw * 0.8f, gy + gh * 0.7f);
                }
                frame();
            }
            app_touch(&app, UI_CANCEL, 0, 0, 0);
        } else fprintf(stderr, "unknown command %s\n", a);
    }
    printf("frames=%ld game=%d menu=%d screen=%d quit=%d\n", frames, app_has_game(&app), app.ui.menu_open,
           app.pb ? pb_screen(app.pb) : -1, app.quit);
    app_free(&app);
    return 0;
}
