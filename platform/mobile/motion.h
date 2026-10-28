/*
 * motion.h - tilting the table by moving the phone (the accelerometer): the option "MOTION TILT" of
 * the Android version. Shared with tools/motiontest.c, which checks it on made-up movements.
 *
 * The accelerometer gives the phone's acceleration with gravity (m/s², the axes of the screen held
 * upright: x to its right, y up it, z out of it; a phone pushed to its right reads x > 0). Gravity is
 * followed slowly (0.3 s): what is left is the phone's own movement (gravity is not followed while the
 * phone moves: a shake pulled it, and the stop then read stronger than the push, the other way).
 *
 *   - A tap on a side of the phone (2.8) tilts the table that way: a tap on its left side pushes it to
 *     the right, a short jolt across the screen (x) above MOTION_TAP, clearly stronger than along the
 *     other axes (a tap on the screen, the flippers, pushes it along z), after a calm, and over at once:
 *     then the hand holding the phone stops it, the other way and weaker. The tilt comes MOTION_TAP_WAIT
 *     after the jolt, once it is seen to be over and the phone at rest again (or stopped): the vibration
 *     motor, a shake, a phone handled, jolt again or for longer, and do nothing. (Up to 2.7 the side of
 *     a shake, the first half of the movement; a tap was too short to count.) 2.9: a light tap is enough
 *     (from 3 m/s², the jolt read over two samples; about 7 in 2.8): the jolt is measured from the
 *     movement of the 50 ms before it (the phone turned or carried drifts more than a light tap moves it).
 *   - A vertical shake (along gravity, whatever the angle the phone is held at, up or down first; 2.7)
 *     the upper tilt: a movement smoothed over 10 ms above MOTION_KICK and clearly more than across, for
 *     15 ms at least (a tap on the screen is shorter), reached in 60 ms from rest (the phone moved about
 *     slowly is not shaken).
 * After a tilt, nothing for MOTION_QUIET seconds. While the phone's own vibration motor runs (the game's
 * rumble), the thresholds are half as high again (taps: as in 2.8). The front-ends also ignore the
 * accelerometer just after a finger comes down on the screen (a tap on the screen is not a tilt).
 */
#ifndef PB_MOTION_H
#define PB_MOTION_H

#include <math.h>
#include <stdbool.h>
#include <string.h>

#define MOTION_TAP      1.4f    /* m/s², the jolt of a tap on a side (2.9: a light tap; 5 in 2.8) */
#define MOTION_TAP_SHAKE 7.5f   /* the same while the phone's vibration motor runs (2.8's) */
#define MOTION_TAP_WAIT 0.035   /* s: a tap is over this soon after its jolt */
#define MOTION_KICK     9.0f    /* m/s², the movement of a vertical shake */
#define MOTION_QUIET    0.35    /* s: nothing after a tilt */
#define MOTION_HOLD     0.1     /* s: its tilt pressed so long (the game wants a release between two) */

enum { MOTION_NONE = 0, MOTION_LEFT, MOTION_RIGHT, MOTION_UP };

typedef struct {
    bool init;
    double t;                   /* time of the last sample */
    float g[3];                 /* gravity, followed slowly */
    float mv[3];                /* the phone's movement, smoothed */
    int cand;                   /* the vertical shake being made (MOTION_UP)... */
    double cand_t;              /* ...since then */
    double v_low_t;             /* the last sample moving vertically less than a third of a shake */
    float prev[3];              /* the jolt of the sample before */
    float base[3];              /* the movement just before a jolt (taps: what it stands out from)... */
    double base_t;              /* ...followed then (a jolt longer than 0.1 s is a hand moving the phone) */
    double hi_t;                /* the last sample moving across more than half a tap */
    double rise_t;              /* the first one of the jolt going on... */
    float rise_x;               /* ...and its way (the stop after it, the other way, is not the tap) */
    double calm;                /* the calm across before it (s) */
    int tap;                    /* a tap being checked: its side (MOTION_LEFT, RIGHT), 0 none */
    double tap_t;               /* its jolt */
    float tap_peak, tap_x;      /* its strongest sample across, and the sign of the jolt */
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
        m->hi_t = t - 1;
        m->v_low_t = t;
        m->prev[0] = m->prev[1] = m->prev[2] = 0;
        m->base[0] = m->base[1] = m->base[2] = 0;
        m->base_t = t;
        m->tap = 0;
        m->cand = MOTION_NONE;
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
    float scale = shaking ? 1.5f : 1.0f, tap = shaking ? MOTION_TAP_SHAKE : MOTION_TAP, kick = MOTION_KICK * scale;
    int tilt = MOTION_NONE;

    /* taps on the sides: the movement across, from what it was over the 50 ms before the jolt (2.9:
     * the phone turned or carried slowly drifts far more than a light tap moves it). A jolt shorter
     * than a sample can be cut in two by the samples (each reads half of it): two in a row the same
     * way count together, on each axis (a knock on the screen or the back, along z, does not become a
     * tap on a side in its second half). */
    float jo[3];
    for (int i = 0; i < 3; i++) jo[i] = lin[i] - m->base[i];
    float X = jo[0], AX = fabsf(X), J[3];
    for (int i = 0; i < 3; i++) {
        float v = fabsf(jo[i]);
        J[i] = (jo[i] > 0) == (m->prev[i] > 0) ? fmaxf(v, 0.75f * (v + fabsf(m->prev[i]))) : v;
        if (i) J[i] = fmaxf(J[i], 0.75f * fabsf(m->prev[i]));    /* (the other axes: whatever its sign now) */
        m->prev[i] = jo[i];
    }
    bool still = !m->tap && AX < tap / 2 && t - m->hi_t > 0.012;
    if (still || t - m->base_t > 0.1) {                            /* no jolt: the reference follows */
        float sb = 1.0f - expf(-dt / 0.050f);
        for (int i = 0; i < 3; i++) m->base[i] += jo[i] * sb;
        if (still) m->base_t = t;
    }
    float JX = J[0], JY = J[1], JZ = J[2];
    if (AX >= tap / 2) {
        if (t - m->hi_t > 0.012) { m->calm = t - m->hi_t; m->rise_t = t; m->rise_x = X; }   /* a new jolt */
        m->hi_t = t;
    }
    if (m->tap) {
        double since = t - m->tap_t;
        bool same = (X > 0) == (m->tap_x > 0);
        if (since <= 0.012 && same && JX > m->tap_peak) m->tap_peak = JX;   /* the jolt goes on */
        else if (since > 0.012 && same && AX >= 0.5f * fmaxf(tap, m->tap_peak)) m->tap = 0;   /* again: shaken, or moved */
        else if (!same && AX > 2.0f * m->tap_peak) m->tap = 0;              /* not a stop: a movement */
        if (m->tap && since <= 0.012 && JZ > 1.2f * m->tap_peak) m->tap = 0;   /* the screen pushed */
        if (m->tap && since >= MOTION_TAP_WAIT) {
            /* (2.9) and the phone at rest again, or stopped by the hand (the other way, weaker): a
             * hand moving it goes on moving */
            bool rest = (X > 0) == (m->tap_x > 0) ? AX < fmaxf(0.6f * tap, 0.25f * m->tap_peak) : AX < 0.7f * m->tap_peak;
            if (t >= m->quiet_until && rest) tilt = m->tap;
            m->tap = 0;
        }
    } else if (t >= m->quiet_until && JX >= tap && JX >= 1.5f * JY && JX >= 1.2f * JZ && m->calm >= 0.04 && t - m->rise_t <= 0.012 &&
               (X > 0) == (m->rise_x > 0)) {
        m->tap = X > 0 ? MOTION_LEFT : MOTION_RIGHT;   /* pushed to the right: tapped on its left side */
        m->tap_t = t;
        m->tap_peak = JX;
        m->tap_x = X;
    }

    /* vertical shakes: the smoothed movement along gravity */
    float gl = sqrtf(m->g[0] * m->g[0] + m->g[1] * m->g[1] + m->g[2] * m->g[2]);
    float v = gl > 1 ? (m->mv[0] * m->g[0] + m->mv[1] * m->g[1] + m->mv[2] * m->g[2]) / gl : m->mv[1];
    float H = fabsf(m->mv[0]), V = fabsf(v);
    if (V < kick / 3) m->v_low_t = t;
    /* (2.8: and quickly, from rest: the hands moving the phone about slowly are not a shake) */
    int dir = V > kick && V > 1.5f * H && (m->cand || t - m->v_low_t <= 0.06) ? MOTION_UP : MOTION_NONE;
    if (dir != m->cand) { m->cand = dir; m->cand_t = t; }
    if (!tilt && dir && t >= m->quiet_until && t - m->cand_t >= 0.015) tilt = dir;

    if (tilt) {
        m->quiet_until = t + MOTION_QUIET;
        m->tap = 0;
    }
    m->count[tilt]++;
    return tilt;
}

#endif
