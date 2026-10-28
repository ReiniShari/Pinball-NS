/*
 * motiontest.c - platform/mobile/motion.h (the tilt by moving the phone) on made-up movements of a
 * phone held in portrait, 100 samples a second (or 50, 200, 400), the time of each a little irregular,
 * each sample the mean of the movement since the one before (as an accelerometer filters it):
 *   - none must make a tilt: the phone still, handled, turned, carried while walking, shaken by its
 *     vibration motor (the game's rumble), tapped on its screen (lightly, hard, very hard, near its edges:
 *     the flippers, a tap on the game), knocked on its back, the slightest touch on a side;
 *   - each tap on the left or right side makes one tilt of that side (2.8: also short or long jolts,
 *     during the rumble; 2.9: light taps, from 3 m/s²), each vertical shake (up or down first, the phone held up or lying flat) one
 *     upper tilt (also during the rumble, at 50 samples a second; the front-end tells when its motor
 *     runs, and 50 ms after).
 *
 *   motiontest [-seeds N]   all the cases (each with N draws of the noise and of the times of the
 *                           samples: all must pass), "ALL OK" at the end (exit status 0)
 *   motiontest -trace NAME DRAW   every sample of the case whose name contains NAME, that draw, with the
 *                           detector's state and the tilts it makes
 */
#include "../platform/mobile/motion.h"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define PI 3.14159265358979

static uint32_t rng = 1;
static double rnd(void) { rng = rng * 1664525u + 1013904223u; return (rng >> 8) / 16777216.0; }
static double gauss(void) { double s = 0; for (int i = 0; i < 6; i++) s += rnd(); return (s - 3) * 1.41; }

typedef struct {
    const char *name;
    int kind;               /* the movement */
    double amp;             /* its strength (m/s²) */
    double rate;            /* samples a second */
    int expect[4];          /* tilts expected: none, left, right, up (-1: any; -N, N > 1: at least N) */
    double width;           /* taps: the length of the jolt (s; 0: 8 ms) */
} Case;

enum { STILL, HANDLED, TURNED, WALKING, RUMBLE, SCREEN_TAPS, EDGE_TAPS, BACK_KNOCKS, SIDE_L, SIDE_R, SIDE_L_RUMBLE,
       NUDGE_L, VERT_UP, VERT_DOWN, VERT_FLAT };

/* the angle the phone is held at, back from upright (VERT_FLAT: lying flat) */
static double held_at(const Case *c) { return (c->kind == VERT_FLAT ? 90 : 40) * PI / 180; }

/* a tap on a side at 0.3 s of every second: a jolt of `w` seconds, then the hand stops the phone (the
 * other way, weaker and longer) */
static double side_tap(double ph, double amp, double w)
{
    if (ph >= 0.3 && ph < 0.3 + w) return amp * sin(PI * (ph - 0.3) / w);
    if (ph >= 0.3 + w && ph < 0.3 + 4 * w) return -0.4 * amp * sin(PI * (ph - 0.3 - w) / (3 * w));
    return 0;
}

/* the phone's movement at t (m/s², the axes of the screen), its gravity apart */
static void movement(const Case *c, double t, double a[3])
{
    a[0] = a[1] = a[2] = 0;
    double ph = fmod(t, 1.0);                       /* taps and nudges: one a second, at 0.3 s */
    double push = 0.08;                             /* a nudge: the push, then as long to stop */
    double w = c->width > 0 ? c->width : 0.008;
    switch (c->kind) {
    case HANDLED:                                   /* slow movements of the hands */
        a[0] = c->amp * sin(2 * PI * 0.7 * t) + 0.5 * c->amp * sin(2 * PI * 1.9 * t + 1);
        a[1] = c->amp * sin(2 * PI * 0.5 * t + 2) + 0.5 * c->amp * sin(2 * PI * 1.3 * t);
        a[2] = c->amp * sin(2 * PI * 1.1 * t + 3);
        break;
    case WALKING:                                   /* steps, 1.8 a second */
        a[1] = c->amp * sin(2 * PI * 1.8 * t);
        a[2] = 0.6 * c->amp * sin(2 * PI * 1.8 * t + 0.5);
        a[0] = 0.3 * c->amp * sin(2 * PI * 0.9 * t);
        break;
    case RUMBLE:                                    /* the motor: 160 Hz, 60 ms on every 100 ms, mostly across */
    case SIDE_L_RUMBLE:
        if (fmod(t, 0.1) < 0.06)
            for (int i = 0; i < 3; i++) a[i] = (c->kind == RUMBLE ? c->amp : 4.0) * (i ? 0.3 : 1.0) * sin(2 * PI * 160 * t + i);
        if (c->kind == RUMBLE) break;
        a[0] += side_tap(ph, 25, w);
        break;
    case SIDE_L: case SIDE_R: {                     /* a finger taps a side: pushes the phone the other way */
        double v = side_tap(ph, c->amp, w);
        a[0] = c->kind == SIDE_L ? v : -v;
        a[1] = 0.1 * v;
        a[2] = 0.2 * v * (fmod(t, 2.0) < 1.0 ? 1 : -1);
        break;
    }
    case NUDGE_L: case VERT_UP: case VERT_DOWN: case VERT_FLAT: {
        double v = 0;
        if (ph >= 0.3 && ph < 0.3 + push) v = c->amp * sin(PI * (ph - 0.3) / push);
        else if (ph >= 0.3 + push && ph < 0.3 + 2 * push) v = -c->amp * sin(PI * (ph - 0.3 - push) / push);
        if (c->kind == NUDGE_L) a[0] -= v;          /* the phone moved to the left and back */
        else {                                      /* up or down in the room */
            double s = c->kind == VERT_DOWN ? -v : v, th = held_at(c);
            a[1] += s * cos(th);
            a[2] += s * sin(th);
        }
        break;
    }
    case SCREEN_TAPS: case EDGE_TAPS: {             /* a thumb on the screen, 5 a second, pushing the phone back */
        double tp = fmod(t, 0.2);
        if (tp < 0.015) {
            double v = c->amp * sin(PI * tp / 0.015);
            a[2] = -v;                              /* near an edge, the phone turns a little: across too */
            a[0] = (c->kind == EDGE_TAPS ? (fmod(t, 0.4) < 0.2 ? 0.6 : -0.6) : 0.15) * v;
            a[1] = -0.1 * v;
        }
        break;
    }
    case BACK_KNOCKS: {                             /* knocks on the back of the phone */
        double tp = fmod(t, 0.5);
        if (tp < 0.008) {
            double v = c->amp * sin(PI * tp / 0.008);
            a[2] = v;
            a[0] = 0.3 * v * (fmod(t, 1.0) < 0.5 ? 1 : -1);
        }
        break;
    }
    default: break;
    }
}

/* gravity: the phone held 40 degrees back from upright, turned slowly in TURNED */
static void gravity(const Case *c, double t, double g[3])
{
    double tilt = held_at(c), roll = c->kind == TURNED ? 0.6 * sin(2 * PI * 0.25 * t) : 0;
    g[0] = 9.81 * cos(tilt) * sin(roll);
    g[1] = 9.81 * cos(tilt) * cos(roll);
    g[2] = 9.81 * sin(tilt);
}

static const char *trace_name;
static int trace_draw = -1;

static int run(const Case *c, uint32_t seed, bool quiet)
{
    bool trace = trace_name && strstr(c->name, trace_name) && (int)seed == trace_draw;
    Motion m;
    motion_reset(&m);
    rng = 12345 + seed * 7919;
    long got[4] = { 0, 0, 0, 0 };
    const double secs = 10.0;
    double prev = 0;
    for (double t = 0; t < secs; t += (1.0 + 0.1 * (rnd() * 2 - 1)) / c->rate) {
        /* the mean of the movement since the sample before (0.25 ms steps) */
        double acc[3] = { 0, 0, 0 }, g[3];
        int n = 0;
        for (double u = prev; u < t || n == 0; u += 0.00025, n++) {
            double a[3];
            movement(c, u, a);
            gravity(c, u, g);
            for (int i = 0; i < 3; i++) acc[i] += a[i] + g[i];
        }
        prev = t;
        bool motor = (c->kind == RUMBLE || c->kind == SIDE_L_RUMBLE) && fmod(t, 0.1) < 0.06 + 0.05;
        float sx = (float)(acc[0] / n + 0.15 * gauss()), sy = (float)(acc[1] / n + 0.15 * gauss()), sz = (float)(acc[2] / n + 0.15 * gauss());
        int r = motion_sample(&m, 1000.0 + t, sx, sy, sz, motor);
        if (r) got[r]++;
        if (trace)
            printf("t %7.4f  jolt %6.2f %6.2f %6.2f  base %6.2f  tap %d peak %5.2f calm %.3f%s\n", t, m.prev[0], m.prev[1], m.prev[2],
                   m.base[0], m.tap, m.tap_peak, m.calm, r ? (r == MOTION_LEFT ? "  LEFT" : r == MOTION_RIGHT ? "  RIGHT" : "  UP") : "");
    }
    bool ok = true;
    for (int i = 1; i < 4; i++)
        if (c->expect[i] >= 0 ? got[i] != c->expect[i] : c->expect[i] < -1 && got[i] < -c->expect[i]) ok = false;
    if (!quiet || !ok) {
        printf("%-50s %s  left %ld right %ld up %ld", c->name, ok ? "ok  " : "FAIL", got[1], got[2], got[3]);
        if (seed) printf(" (draw %u)", seed);
        printf("\n");
    }
    return ok;
}

int main(int argc, char **argv)
{
    int seeds = argc > 2 && !strcmp(argv[1], "-seeds") ? atoi(argv[2]) : 1;
    if (argc > 3 && !strcmp(argv[1], "-trace")) { trace_name = argv[2]; trace_draw = atoi(argv[3]); seeds = trace_draw + 1; }
    const Case cases[] = {
        { "still",                                        STILL,       0,   100, { 0, 0, 0, 0 } },
        { "handled (slow movements, 2.5 m/s2)",           HANDLED,     2.5, 100, { 0, 0, 0, 0 } },
        { "turned left and right",                        TURNED,      0,   100, { 0, 0, 0, 0 } },
        { "walking",                                      WALKING,     3,   100, { 0, 0, 0, 0 } },
        { "the vibration motor (6 m/s2)",                 RUMBLE,      6,   100, { 0, 0, 0, 0 } },
        { "a strong vibration motor (12 m/s2)",           RUMBLE,      12,  100, { 0, 0, 0, 0 } },
        { "a strong vibration motor, 50 a second",        RUMBLE,      12,  50,  { 0, 0, 0, 0 } },
        { "a strong vibration motor, 400 a second",       RUMBLE,      12,  400, { 0, 0, 0, 0 } },
        { "taps on the screen (6 m/s2)",                  SCREEN_TAPS, 6,   100, { 0, 0, 0, 0 } },
        { "hard taps on the screen (25 m/s2)",            SCREEN_TAPS, 25,  100, { 0, 0, 0, 0 } },
        { "very hard taps on the screen, 400 a second",   SCREEN_TAPS, 35,  400, { 0, 0, 0, 0 } },
        { "hard taps near the edges of the screen",       EDGE_TAPS,   25,  200, { 0, 0, 0, 0 } },
        { "knocks on the back (30 m/s2)",                 BACK_KNOCKS, 30,  200, { 0, 0, 0, 0 } },
        { "the slightest touch on a side (1 m/s2)",       SIDE_L,      1,   200, { 0, 0, 0, 0 } },
        { "light taps on the left side (4 m/s2)",         SIDE_L,      4,   200, { 0, 10, 0, 0 } },
        { "light taps on the right side (3 m/s2)",        SIDE_R,      3,   200, { 0, 0, 10, 0 } },
        { "light taps, 100 a second (5 m/s2, 6 of 10)",   SIDE_R,      5,   100, { 0, -1, -6, 0 } },   /* (smeared: rarely the other side) */
        { "handled roughly (5 m/s2)",                     HANDLED,     5,   200, { 0, 0, 0, 0 } },
        { "taps on the left side (12 m/s2)",              SIDE_L,      12,  200, { 0, 10, 0, 0 } },
        { "taps on the right side (12 m/s2)",             SIDE_R,      12,  200, { 0, 0, 10, 0 } },
        { "taps on the left side, 100 a second (9 of 10)", SIDE_L,     20,  100, { 0, -9, 0, 0 } },
        { "taps on the right side, 100 a second (9 of 10)", SIDE_R,    20,  100, { 0, 0, -9, 0 } },
        { "taps on the left side, 200 a second",          SIDE_L,      20,  200, { 0, 10, 0, 0 } },
        { "taps on the right side, 400 a second",         SIDE_R,      20,  400, { 0, 0, 10, 0 } },
        { "hard taps on the left side (40 m/s2)",         SIDE_L,      40,  200, { 0, 10, 0, 0 } },
        { "short taps on the right side (4 ms)",          SIDE_R,      25,  200, { 0, 0, 10, 0 }, 0.004 },
        { "long taps on the left side (15 ms)",           SIDE_L,      15,  100, { 0, 10, 0, 0 }, 0.015 },
        { "taps on the right side, 50 a second",          SIDE_R,      40,  50,  { -1, -1, -1, 0 } },
        { "taps on the left side during the rumble",      SIDE_L_RUMBLE, 0, 200, { 0, 10, 0, 0 } },
        { "the same, 100 samples a second (8 of 10)",     SIDE_L_RUMBLE, 0, 100, { 0, -8, 0, 0 } },
        { "a shake left and back (15 m/s2)",              NUDGE_L,     15,  100, { -1, -1, -1, 0 } },
        { "vertical shakes, up first",                    VERT_UP,     15,  100, { 0, 0, 0, 10 } },
        { "vertical shakes, down first",                  VERT_DOWN,   15,  100, { 0, 0, 0, 10 } },
        { "vertical shakes, 15 m/s2, 50 a second",        VERT_DOWN,   15,  50,  { 0, 0, 0, 10 } },
        { "vertical shakes, 12 m/s2, 200 a second",       VERT_DOWN,   12,  200, { 0, 0, 0, 10 } },
        { "vertical shakes, the phone lying flat",        VERT_FLAT,   15,  100, { 0, 0, 0, 10 } },
    };
    int bad = 0;
    for (size_t i = 0; i < sizeof cases / sizeof cases[0]; i++)
        for (int k = 0; k < seeds; k++) bad += !run(&cases[i], (uint32_t)k, k > 0);
    printf(bad ? "%d FAILED\n" : "ALL OK\n", bad);
    return bad ? 1 : 0;
}
