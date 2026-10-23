/*
 * motion.h - tilting the table by moving the phone (the accelerometer): the option "MOTION TILT" of
 * the Android version. Shared with tools/motiontest.c, which checks it on made-up movements.
 *
 * The accelerometer gives the phone's acceleration with gravity (m/s², the axes of the screen held
 * upright: x to its right, y up it, z out of it). Gravity is followed slowly (0.3 s): what is left is
 * the phone's own movement, smoothed over 10 ms (gravity is not followed while the phone moves: a
 * shake pulled it, and the stop then read stronger than the push, the other way). Two directions
 * count: across the screen (x: left or right) and vertical (along gravity, whatever the angle the
 * phone is held at). A shake is a strong movement in one of them, above MOTION_KICK and clearly more
 * than in the other one, for 15 ms at least (a tap on the screen is shorter): across, its tilt to the
 * side of the push (the first half of the movement: the stop after it, the other way, can be the
 * stronger); vertical, up or down first, the upper tilt (2.7: only a push up the screen, and a shake
 * begun downwards did nothing). After a tilt, nothing for MOTION_QUIET seconds. While the phone's own vibration motor runs (the game's rumble), the
 * threshold is half as high again: an accelerometer read 50 times a second sees a strong motor as a
 * slow shake.
 */
#ifndef PB_MOTION_H
#define PB_MOTION_H

#include <math.h>
#include <stdbool.h>
#include <string.h>

#define MOTION_KICK  9.0f       /* m/s², the movement of a shake */
#define MOTION_QUIET 0.35       /* s: nothing after one */
#define MOTION_HOLD  0.1        /* s: its tilt pressed so long (the game wants a release between two) */

enum { MOTION_NONE = 0, MOTION_LEFT, MOTION_RIGHT, MOTION_UP };

typedef struct {
    bool init;
    double t;                   /* time of the last sample */
    float g[3];                 /* gravity, followed slowly */
    float mv[3];                /* the phone's movement, smoothed */
    int cand;                   /* the tilt the movement is making now (MOTION_*)... */
    double cand_t;              /* ...since then */
    int push;                   /* the side the phone was pushed to first (MOTION_LEFT, RIGHT; 0: calm) */
    double calm_t;              /* it has hardly moved across since then (< 0: it moves) */
    double quiet_until;         /* no tilt before */
    long count[4];              /* samples without a tilt, tilts found (statistics) */
} Motion;

static inline void motion_reset(Motion *m) { memset(m, 0, sizeof *m); }

/* A sample at t seconds (any clock, increasing), `shaking` while the vibration motor runs: the tilt it
 * makes (MOTION_*), or MOTION_NONE. */
static inline int motion_sample(Motion *m, double t, float ax, float ay, float az, bool shaking)
{
    float a[3] = { ax, ay, az };
    if (!m->init || t < m->t || t - m->t > 0.5) {       /* the first sample, or after a pause */
        for (int i = 0; i < 3; i++) { m->g[i] = a[i]; m->mv[i] = 0; }
        m->init = true;
        m->t = t;
        return MOTION_NONE;
    }
    float dt = (float)(t - m->t), k = dt / 0.3f, s = 1.0f - expf(-dt / 0.010f);
    if (k > 1) k = 1;
    m->t = t;
    float lin[3], moving = 0;
    for (int i = 0; i < 3; i++) {
        lin[i] = a[i] - m->g[i];
        m->mv[i] += (lin[i] - m->mv[i]) * s;
        moving += m->mv[i] * m->mv[i];
    }
    if (moving < 3.0f * 3.0f)
        for (int i = 0; i < 3; i++) m->g[i] += lin[i] * k;
    float gl = sqrtf(m->g[0] * m->g[0] + m->g[1] * m->g[1] + m->g[2] * m->g[2]);
    float v = gl > 1 ? (m->mv[0] * m->g[0] + m->mv[1] * m->g[1] + m->mv[2] * m->g[2]) / gl : m->mv[1];
    float h = m->mv[0], H = fabsf(h), V = fabsf(v), kick = shaking ? 1.5f * MOTION_KICK : MOTION_KICK;
    if (H >= kick / 3) m->calm_t = -1;                     /* the push forgotten after 60 ms of calm */
    else if (m->calm_t < 0) m->calm_t = t;
    else if (t - m->calm_t > 0.06) m->push = MOTION_NONE;
    if (!m->push && H > kick / 2) m->push = h < 0 ? MOTION_LEFT : MOTION_RIGHT;
    int dir = MOTION_NONE;
    if (H > kick && H > 1.5f * V) dir = m->push ? m->push : h < 0 ? MOTION_LEFT : MOTION_RIGHT;
    else if (V > kick && V > 1.5f * H) dir = MOTION_UP;
    if (dir != m->cand) { m->cand = dir; m->cand_t = t; }
    int tilt = MOTION_NONE;
    if (dir && t >= m->quiet_until && t - m->cand_t >= 0.015) {
        tilt = dir;
        m->quiet_until = t + MOTION_QUIET;
    }
    m->count[tilt]++;
    return tilt;
}

#endif
