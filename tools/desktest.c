/*
 * desktest.c - the core of the desktop versions (platform/desktop/desk.c) without a window: a ROM,
 * keys, gamepad inputs, clicks and touches, and the pictures the window would show, saved (PNG).
 *
 *   desktest -cfg FILE ROM cmd...
 *   cmds: w:N (frames)  key:VK (pressed and released, hexadecimal DK_* / virtual-key code)
 *         hold:VK:N (held N frames)  pad:BITS:N (gamepad inputs held N frames, hexadecimal PAD_* bits)
 *         tap:X:Y (a click / a finger, window pixels)  size:WxH (the window)  s:NAME (the window's
 *         picture: NAME.png)  info (the settings, the game)  bot:N:SEED (random flippers and tilts)
 * The settings file is read and written as the front-ends do.
 */
#include "../platform/desktop/desk.h"
#include "png_write.h"
#include "botrand.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static Desk D;
static int W = 576, H = 870;
static double now = 100.0;

static void frame(void)
{
    desk_frame(&D);
    int16_t tmp[4096];
    while (D.pb && pb_audio(D.pb, tmp, 2048) > 0) {}
    now += 70224.0 / 4194304.0;
    desk_tick(&D, now);
}

static void shot(const char *name)
{
    DeskPicture p;
    desk_picture(&D, W, H, &p);
    uint32_t *buf = (uint32_t *)malloc((size_t)W * H * 4);
    if (!buf) return;
    desk_blit(&p, buf, W, H, W);
    char path[600];
    snprintf(path, sizeof path, "%s.png", name);
    png_write_rgb(path, buf, W, H, W, 1);
    free(buf);
    printf("%s: picture %dx%d at %d,%d size %dx%d%s\n", path, p.w, p.h, p.x, p.y, p.dw, p.dh, p.smooth ? " smooth" : "");
}

int main(int argc, char **argv)
{
    const char *cfg = "desktest.cfg";
    int i = 1;
    if (i + 1 < argc && !strcmp(argv[i], "-cfg")) { cfg = argv[i + 1]; i += 2; }
    if (i >= argc) { fprintf(stderr, "usage: desktest [-cfg FILE] ROM cmd...\n"); return 2; }
    desk_init(&D, cfg);
    char err[1024];
    if (!desk_open_rom(&D, argv[i], err, sizeof err)) { fprintf(stderr, "%s\n", err); return 1; }
    for (i++; i < argc; i++) {
        const char *a = argv[i];
        unsigned v;
        int n, x, y;
        if (sscanf(a, "w:%d", &n) == 1) for (int k = 0; k < n; k++) frame();
        else if (sscanf(a, "key:%x", &v) == 1) {
            int act = desk_key(&D, v, true, false);
            frame();
            desk_key(&D, v, false, false);
            frame();
            if (act > DESK_REDRAW) printf("key %X: action %d\n", v, act);
        } else if (sscanf(a, "hold:%x:%d", &v, &n) == 2) {
            desk_key(&D, v, true, false);
            for (int k = 0; k < n; k++) frame();
            desk_key(&D, v, false, false);
            frame();
        } else if (sscanf(a, "pad:%x:%d", &v, &n) == 2) {
            desk_pad(&D, (long)v);
            for (int k = 0; k < n; k++) frame();
            desk_pad(&D, 0);
            frame();
        } else if (sscanf(a, "tap:%d:%d", &x, &y) == 2) {
            desk_pointer(&D, 0, 1, (float)x, (float)y);
            for (int k = 0; k < 4; k++) frame();
            desk_pointer(&D, 1, 1, (float)x, (float)y);
            frame();
        } else if (sscanf(a, "size:%dx%d", &x, &y) == 2) { W = x; H = y; }
        else if (!strncmp(a, "s:", 2)) shot(a + 2);
        else if (sscanf(a, "bot:%d:%d", &n, &x) == 2) {
            bot_srand((uint32_t)x);
            for (int k = 0; k < n; k++) {
                if (k % 6 == 0) {
                    desk_key(&D, DK_LSHIFT, bot_rand() % 100 < 45, false);
                    desk_key(&D, DK_RSHIFT, bot_rand() % 100 < 45, false);
                }
                if (k % 600 == 300 && D.pb && !pb_in_game(D.pb)) { desk_key(&D, 'X', true, false); frame(); desk_key(&D, 'X', false, false); }
                frame();
            }
            desk_keys_released(&D);
        } else if (!strcmp(a, "info")) {
            printf("handheld %d narrow %d filter %d colors %d hidden %d page %d paused %d screen %d stage %d menu %d quit %d\n",
                   D.handheld, D.narrow, D.filter, D.colors, D.ui.hide_controls, D.page, D.paused,
                   D.pb ? pb_screen(D.pb) : -1, D.pb ? pb_stage(D.pb) : -1, D.ui.menu_open, D.quit);
        } else fprintf(stderr, "unknown command %s\n", a);
    }
    desk_free(&D);
    return 0;
}
