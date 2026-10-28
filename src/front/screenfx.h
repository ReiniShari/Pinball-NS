/*
 * screenfx.h - the screen filters and colours of the Android version (platform/android/gles_render.c:
 * FS_GAME, the same arithmetic) in software, for the Windows version (2.8): the game's picture made k
 * times larger, each of its pixels a cell of k x k.
 *   - colours: black and white (the luminance), or the four greens of the first Game Boy's screen
 *     (0F380F, 306230, 8BAC0F, 9BBC0F, in shades between them);
 *   - DOT: each pixel a round dot, a little glow between them (its 9 neighbours, weighted by their
 *     distance, a little wider when they are dark; the shader's mix(1.2 mid, sum, 0.65) folded into the
 *     weights: 0.65 each, 1.07 the middle one);
 *   - LCD: the grid of a liquid crystal screen, the red, green and blue of each cell side by side (in
 *     the game's own colours only).
 * The weights of each point of a cell are computed once for the cell size (the luminance of a neighbour
 * in FX_LUMQ steps); then only the cells whose neighbourhood changed since the last picture are made
 * again (on a table: a few hundred pixels a frame), 4 points at a time (SSE2), and a cell whose 9 colours
 * are those of a cell already made by the same call is copied (the white of the table, its repeated
 * patterns: during a fade or on a new screen, every cell changes). By bands of rows, which the caller can
 * share out between threads.
 */
#ifndef PB_SCREENFX_H
#define PB_SCREENFX_H

#include <math.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#if defined(_M_X64) || defined(__x86_64__) || defined(__SSE2__)
#include <emmintrin.h>
#define FX_SSE2 1
#endif

enum { FX_FILTER_NONE = 0, FX_FILTER_DOT, FX_FILTER_LCD, FX_FILTERS };
enum { FX_COLORS_ORIGINAL = 0, FX_COLORS_BW, FX_COLORS_GREEN, FX_COLORSETS };

#define FX_LUMQ   32               /* DOT: the luminance of a neighbour, in steps (its weight depends on it) */
#define FX_MAXK   16               /* the largest cell */
#define FX_MEMO   2048             /* cells made by a call, remembered by their 9 colours */

typedef struct {
    int filter, colors, k, kp, w, h;   /* what the buffers were made for; kp: k rounded up to 4 */
    uint32_t *toned;               /* the picture in its colours, w x h */
    uint32_t *prev;                /* the picture of the last call, w x h */
    uint8_t *dirty;                /* cells to make again, w x h */
    uint32_t *out;                 /* the result, (w k) x (h k) */
    float *wdot;                   /* DOT: [9][FX_LUMQ][k][kp] */
    float *lcd;                    /* LCD: [3][k][kp] */
} ScreenFx;

static inline void screenfx_free(ScreenFx *f)
{
    free(f->toned); free(f->prev); free(f->dirty); free(f->out); free(f->wdot); free(f->lcd);
    memset(f, 0, sizeof *f);
}

static inline uint32_t screenfx_tone(int colors, uint32_t p)
{
    if (colors == FX_COLORS_ORIGINAL) return p & 0xFFFFFFu;
    float r = ((p >> 16) & 255) / 255.f, g = ((p >> 8) & 255) / 255.f, b = (p & 255) / 255.f;
    float l = r * 0.299f + g * 0.587f + b * 0.114f, c[3];
    if (colors == FX_COLORS_BW) c[0] = c[1] = c[2] = l;
    else {
        static const float G[4][3] = { { 0.0588f, 0.2196f, 0.0588f }, { 0.1882f, 0.3843f, 0.1882f },
                                       { 0.5451f, 0.6745f, 0.0588f }, { 0.6078f, 0.7373f, 0.0588f } };
        float t = l * 3;
        int i = t < 1 ? 0 : t < 2 ? 1 : 2;
        float u = t - i;
        for (int k = 0; k < 3; k++) c[k] = G[i][k] + (G[i + 1][k] - G[i][k]) * u;
    }
    uint32_t o = 0;
    for (int k = 0; k < 3; k++) o = (o << 8) | (uint32_t)(fminf(fmaxf(c[k], 0), 1) * 255.f + 0.5f);
    return o;
}

/* The picture px (w x h, stride) for this filter, these colours and cells of k x k (1..FX_MAXK): what
 * changed is found, the tables made if needed. Then screenfx_rows makes the cells of the rows asked for
 * (all of them: 0..h), and f->out is the result. False if out of memory. */
static inline bool screenfx_begin(ScreenFx *f, const uint32_t *px, int w, int h, int stride, int filter, int colors, int k)
{
    if (filter == FX_FILTER_NONE) k = 1;
    if (k < 1) k = 1;
    if (k > FX_MAXK) k = FX_MAXK;
    int kp = (k + 3) & ~3;
    bool fresh = !f->out || f->w != w || f->h != h || f->k != k || f->filter != filter || f->colors != colors;
    if (fresh) {
        if (f->w != w || f->h != h || f->k != k || !f->out) {
            free(f->toned); free(f->prev); free(f->dirty); free(f->out); free(f->wdot); free(f->lcd);
            f->toned = (uint32_t *)malloc((size_t)w * h * 4);
            f->prev = (uint32_t *)malloc((size_t)w * h * 4);
            f->dirty = (uint8_t *)malloc((size_t)w * h);
            f->out = (uint32_t *)malloc((size_t)w * k * h * k * 4);
            f->wdot = (float *)calloc((size_t)9 * FX_LUMQ * k * kp, sizeof(float));
            f->lcd = (float *)calloc((size_t)3 * k * kp, sizeof(float));
            if (!f->toned || !f->prev || !f->dirty || !f->out || !f->wdot || !f->lcd) { screenfx_free(f); return false; }
        }
        f->w = w; f->h = h; f->k = k; f->kp = kp; f->filter = filter; f->colors = colors;
        /* the weights of the 9 neighbours of each point of a cell (DOT), its grid and subpixels (LCD) */
        for (int j = 0; j < k; j++)
            for (int i = 0; i < k; i++) {
                float fx = (i + 0.5f) / k - 0.5f, fy = (j + 0.5f) / k - 0.5f;
                for (int o = 0; o < 9; o++) {
                    float ox = (float)(o % 3 - 1), oy = (float)(o / 3 - 1), d = sqrtf((fx - ox) * (fx - ox) + (fy - oy) * (fy - oy));
                    for (int q = 0; q < FX_LUMQ; q++) {
                        float lum = (q + 0.5f) / FX_LUMQ, spread = 1.05f + (0.95f - 1.05f) * lum;
                        f->wdot[((size_t)(o * FX_LUMQ + q) * k + j) * kp + i] = expf(-2.4f * d * spread) * (o == 4 ? 1.07f : 0.65f);
                    }
                }
                float gx = (i + 0.5f) / k, gy = (j + 0.5f) / k, ex = fminf(gx, 1 - gx), ey = fminf(gy, 1 - gy);
                float lw = fmaxf(1.5f / k, 0.1f), sx = fminf(ex / lw, 1), sy = fminf(ey / lw, 1);
                sx = sx * sx * (3 - 2 * sx);
                sy = sy * sy * (3 - 2 * sy);
                float grid = 0.5f + 0.5f * sx * sy;
                static const float centre[3] = { 1 / 6.f, 0.5f, 5 / 6.f };
                for (int c = 0; c < 3; c++)
                    f->lcd[(c * k + j) * kp + i] =
                        (colors == FX_COLORS_ORIGINAL ? 0.75f + 0.25f * cosf(6.2831853f * (gx - centre[c])) : 0.75f) * grid * 1.4f;
            }
    }
    /* the colours, and what changed (a cell changes with its neighbours) */
    memset(f->dirty, fresh ? 1 : 0, (size_t)w * h);
    for (int y = 0; y < h; y++) {
        const uint32_t *row = px + (size_t)y * stride;
        uint32_t *pv = f->prev + (size_t)y * w, *tn = f->toned + (size_t)y * w;
        for (int x = 0; x < w; x++) {
            uint32_t p = row[x] & 0xFFFFFFu;
            if (!fresh && p == pv[x]) continue;
            pv[x] = p;
            tn[x] = screenfx_tone(colors, p);
            if (fresh) continue;
            for (int dy = -1; dy <= 1; dy++)
                for (int dx = -1; dx <= 1; dx++) {
                    int X = x + dx, Y = y + dy;
                    if (X >= 0 && X < w && Y >= 0 && Y < h) f->dirty[Y * w + X] = 1;
                }
        }
    }
    return true;
}

/* a row of n points (n a multiple of 4) from its channels (0..1) into pixels 0x00RRGGBB */
static inline void fx_pack(const float *r, const float *g, const float *b, uint32_t *dst, int n)
{
#ifdef FX_SSE2
    const __m128 lo = _mm_setzero_ps(), hi = _mm_set1_ps(255.f);
    for (int i = 0; i < n; i += 4) {
        __m128i R = _mm_cvtps_epi32(_mm_min_ps(_mm_max_ps(_mm_mul_ps(_mm_loadu_ps(r + i), hi), lo), hi));
        __m128i G = _mm_cvtps_epi32(_mm_min_ps(_mm_max_ps(_mm_mul_ps(_mm_loadu_ps(g + i), hi), lo), hi));
        __m128i B = _mm_cvtps_epi32(_mm_min_ps(_mm_max_ps(_mm_mul_ps(_mm_loadu_ps(b + i), hi), lo), hi));
        _mm_storeu_si128((__m128i *)(dst + i), _mm_or_si128(_mm_or_si128(_mm_slli_epi32(R, 16), _mm_slli_epi32(G, 8)), B));
    }
#else
    for (int i = 0; i < n; i++) {
        uint32_t v = 0;
        const float c[3] = { r[i], g[i], b[i] };
        for (int ch = 0; ch < 3; ch++) v = (v << 8) | (uint32_t)(fminf(fmaxf(c[ch], 0), 1) * 255.f + 0.5f);
        dst[i] = v;
    }
#endif
}

/* the cells of the picture's rows y0..y1-1 that changed */
static inline void screenfx_rows(ScreenFx *f, int y0, int y1)
{
    int w = f->w, h = f->h, k = f->k, kp = f->kp, ow = w * k;
    float R[FX_MAXK], G[FX_MAXK], B[FX_MAXK];
    uint32_t tmp[FX_MAXK];
    /* the cells made by this call, by their 9 colours (a hash; the colours checked) */
    static const int NONE = -1;
    int memo[FX_MEMO];
    for (int i = 0; i < FX_MEMO; i++) memo[i] = NONE;
    for (int y = y0; y < y1 && y < h; y++)
        for (int x = 0; x < w; x++) {
            if (!f->dirty[y * w + x]) continue;
            uint32_t *o = f->out + (size_t)y * k * ow + (size_t)x * k;
            if (f->filter == FX_FILTER_NONE) { *o = f->toned[y * w + x]; continue; }
            /* the 9 neighbours (the edges repeat, as the shader clamps) */
            uint32_t nb[9];
            uint64_t key = 1469598103934665603ull;
            for (int on = 0; on < 9; on++) {
                int X = x + on % 3 - 1, Y = y + on / 3 - 1;
                X = X < 0 ? 0 : X >= w ? w - 1 : X;
                Y = Y < 0 ? 0 : Y >= h ? h - 1 : Y;
                nb[on] = f->toned[Y * w + X];
                key = (key ^ nb[on]) * 1099511628211ull;
            }
            if (f->filter == FX_FILTER_LCD) key = nb[4] * 2654435761u;
            int slot = (int)((key >> 20) & (FX_MEMO - 1)), seen = memo[slot];
            if (seen != NONE) {
                int sx = seen % w, sy = seen / w;
                bool same = true;
                for (int on = 0; on < 9 && same; on++) {
                    int X = sx + on % 3 - 1, Y = sy + on / 3 - 1;
                    X = X < 0 ? 0 : X >= w ? w - 1 : X;
                    Y = Y < 0 ? 0 : Y >= h ? h - 1 : Y;
                    same = f->filter == FX_FILTER_LCD ? (on != 4 || f->toned[Y * w + X] == nb[4]) : f->toned[Y * w + X] == nb[on];
                }
                if (same) {
                    const uint32_t *s = f->out + (size_t)sy * k * ow + (size_t)sx * k;
                    for (int j = 0; j < k; j++) memcpy(o + (size_t)j * ow, s + (size_t)j * ow, (size_t)k * 4);
                    continue;
                }
            }
            memo[slot] = y * w + x;
            if (f->filter == FX_FILTER_LCD) {
                uint32_t p = nb[4];
                float c[3] = { ((p >> 16) & 255) / 255.f, ((p >> 8) & 255) / 255.f, (p & 255) / 255.f };
                for (int j = 0; j < k; j++) {
                    const float *lr = f->lcd + (size_t)(0 * k + j) * kp, *lg = f->lcd + (size_t)(1 * k + j) * kp, *lb = f->lcd + (size_t)(2 * k + j) * kp;
                    for (int i = 0; i < kp; i++) { R[i] = c[0] * lr[i]; G[i] = c[1] * lg[i]; B[i] = c[2] * lb[i]; }
                    fx_pack(R, G, B, tmp, kp);
                    memcpy(o + (size_t)j * ow, tmp, (size_t)k * 4);
                }
                continue;
            }
            /* DOT: the weights of each neighbour, by its luminance */
            float cr[9], cg[9], cb[9];
            const float *wt[9];
            for (int on = 0; on < 9; on++) {
                uint32_t p = nb[on];
                cr[on] = ((p >> 16) & 255) / 255.f;
                cg[on] = ((p >> 8) & 255) / 255.f;
                cb[on] = (p & 255) / 255.f;
                int q = (int)((cr[on] * 0.30f + cg[on] * 0.59f + cb[on] * 0.11f) * FX_LUMQ);
                q = q < 0 ? 0 : q >= FX_LUMQ ? FX_LUMQ - 1 : q;
                wt[on] = f->wdot + (size_t)(on * FX_LUMQ + q) * k * kp;
            }
            for (int j = 0; j < k; j++) {
#ifdef FX_SSE2
                for (int i = 0; i < kp; i += 4) {
                    __m128 ar = _mm_setzero_ps(), ag = ar, ab = ar;
                    for (int on = 0; on < 9; on++) {
                        __m128 wv = _mm_loadu_ps(wt[on] + j * kp + i);
                        ar = _mm_add_ps(ar, _mm_mul_ps(_mm_set1_ps(cr[on]), wv));
                        ag = _mm_add_ps(ag, _mm_mul_ps(_mm_set1_ps(cg[on]), wv));
                        ab = _mm_add_ps(ab, _mm_mul_ps(_mm_set1_ps(cb[on]), wv));
                    }
                    _mm_storeu_ps(R + i, ar);
                    _mm_storeu_ps(G + i, ag);
                    _mm_storeu_ps(B + i, ab);
                }
#else
                for (int i = 0; i < kp; i++) {
                    float ar = 0, ag = 0, ab = 0;
                    for (int on = 0; on < 9; on++) {
                        float wv = wt[on][j * kp + i];
                        ar += cr[on] * wv; ag += cg[on] * wv; ab += cb[on] * wv;
                    }
                    R[i] = ar; G[i] = ag; B[i] = ab;
                }
#endif
                fx_pack(R, G, B, tmp, kp);
                memcpy(o + (size_t)j * ow, tmp, (size_t)k * 4);
            }
        }
}

#endif
