/*
 * deflicker.h - the game's 30 Hz flicker, shown as the Game Boy Color showed it.
 *
 * Some effects of the game change a pixel between two colours at every frame (the striped arc
 * of the Red table, the strip under its billboard, dithered areas...). The GBC's LCD was slow:
 * such a pixel was seen as the mix of both colours. A modern screen shows it sharp, 30 times a
 * second: a flicker. A pixel that has, in the last six frames, the colours A, B, A, B, A, B (it
 * keeps alternating) is shown as the mix of A and B; any other pixel is shown as it is. What
 * moves stays sharp, and so does a ball that trembles for a moment on a flipper (two positions
 * in turn for a few frames: with four frames only, it was shown as a ghost). The emulation
 * itself (its pictures, the tests' fingerprints) is not changed: this filters what is put on the
 * screen.
 */
#ifndef PB_DEFLICKER_H
#define PB_DEFLICKER_H

#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define DEFLICKER_PREV 5                 /* previous frames compared with the new one */

typedef struct {
    uint32_t *prev[DEFLICKER_PREV], *out; /* the previous frames (newest first), the filtered one */
    int w, h, frames;                    /* size, frames kept at that size */
    size_t cap;
} Deflicker;

static inline void deflicker_free(Deflicker *d)
{
    for (int i = 0; i < DEFLICKER_PREV; i++) free(d->prev[i]);
    free(d->out);
    memset(d, 0, sizeof *d);
}

/* A new frame of the game (w x h, `stride` pixels a row): returns the picture to show (w x h,
 * stride w), valid until the next call; NULL if out of memory (show px then). */
static inline const uint32_t *deflicker_frame(Deflicker *d, const uint32_t *px, int w, int h, int stride)
{
    size_t n = (size_t)w * (size_t)h;
    if (n > d->cap) {
        deflicker_free(d);
        bool ok = true;
        for (int i = 0; i < DEFLICKER_PREV; i++) ok = (d->prev[i] = (uint32_t *)malloc(n * 4)) != NULL && ok;
        d->out = (uint32_t *)malloc(n * 4);
        if (!ok || !d->out) { deflicker_free(d); return NULL; }
        d->cap = n;
    }
    if (w != d->w || h != d->h) { d->w = w; d->h = h; d->frames = 0; }
    uint32_t *oldest = d->prev[DEFLICKER_PREV - 1];             /* becomes the newest */
    for (int y = 0; y < h; y++) {
        const uint32_t *c = px + (size_t)y * stride;
        size_t r = (size_t)y * w;
        const uint32_t *p1 = d->prev[0] + r, *p2 = d->prev[1] + r, *p3 = d->prev[2] + r, *p4 = d->prev[3] + r, *p5 = d->prev[4] + r;
        uint32_t *o = d->out + r, *keep = oldest + r;              /* keep: p5, read before it is written */
        if (d->frames < DEFLICKER_PREV) {
            memcpy(o, c, (size_t)w * 4);
            memcpy(keep, c, (size_t)w * 4);
        } else {
            for (int x = 0; x < w; x++) {
                uint32_t a = c[x], b = p1[x], v = a;
                /* A B A B A B: the mix (each channel (a + b) / 2, rounded down) */
                if (a != b && a == p2[x] && b == p3[x] && a == p4[x] && b == p5[x]) v = (a & b) + (((a ^ b) >> 1) & 0x7F7F7F);
                o[x] = v;
                keep[x] = a;                                        /* the frame kept (one pass) */
            }
        }
    }
    memmove(&d->prev[1], &d->prev[0], sizeof d->prev[0] * (DEFLICKER_PREV - 1));
    d->prev[0] = oldest;
    if (d->frames < DEFLICKER_PREV) d->frames++;
    return d->out;
}

#endif
