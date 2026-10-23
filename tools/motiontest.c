/*
 * motiontest.c - platform/mobile/motion.h (the tilt by moving the phone) on made-up movements of a
 * phone held in portrait, 100 samples a second (or 50), the time of each a little irregular:
 *   - none must make a tilt: the phone still, handled, turned, carried while walking, shaken by its
 *     vibration motor (the game's rumble), tapped on its screen (lightly, hard, very hard), a weak
 *     nudge;
 *   - each nudge left or right makes one tilt of its direction, each vertical shake (up or down first,
 *     up or down the screen, the phone held up or lying flat) one upper tilt (also during the rumble,
 *     at 50 samples a second; the front-end tells when its motor runs, and 50 ms after).
 *
 *   motiontest          all the cases, "ALL OK" at the end (exit status 0)
 */
#include "../platform/mobile/motion.h"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define PI 3.14159265358979

static uint32_t rng = 1;
static double rnd(void) { rng = rng * 1664525u + 1013904223u; return (rng >> 8) / 16777216.0; }
static double gauss(void) { double s = 0; for (int i = 0; i < 6; i++) s += rnd(); return (s - 3) * 1.41; }

typedef struct {
    const char *name;
    int kind;               /* the movement */
    double amp;             /* its strength (m/s²) */
    double rate;            /* samples a second */
    int expect[4];          /* tilts expected: none, left, right, up (-1: any) */
} Case;

enum { STILL, HANDLED, TURNED, WALKING, RUMBLE, TAPS, NUDGE_L, NUDGE_R, NUDGE_U, NUDGE_D, NUDGE_L_RUMBLE,
       VERT_UP, VERT_DOWN, VERT_FLAT };

/* the angle the phone is held at, back from upright (VERT_FLAT: lying flat) */
static double held_at(const Case *c) { return (c->kind == VERT_FLAT ? 90 : 40) * PI / 180; }

/* the phone's movement at t (m/s², the axes of the screen), the gravity of a phone held 40 degrees
 * back from upright apart */
static void movement(const Case *c, double t, double a[3])
{
    a[0] = a[1] = a[2] = 0;
    double ph = fmod(t, 1.0);                       /* nudges: one a second, at 0.3 s */
    double push = 0.08;                             /* the push, then as long to stop */
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
    case NUDGE_L_RUMBLE:
        if (fmod(t, 0.1) < 0.06)
            for (int i = 0; i < 3; i++) a[i] = (c->kind == RUMBLE ? c->amp : 4.0) * (i ? 0.3 : 1.0) * sin(2 * PI * 160 * t + i);
        if (c->kind == RUMBLE) break;
        /* fall through: and nudges */
    case NUDGE_L: case NUDGE_R: case NUDGE_U: case NUDGE_D: case VERT_UP: case VERT_DOWN: case VERT_FLAT: {
        double amp = c->kind == NUDGE_L_RUMBLE ? 20 : c->amp, v = 0;
        if (ph >= 0.3 && ph < 0.3 + push) v = amp * sin(PI * (ph - 0.3) / push);
        else if (ph >= 0.3 + push && ph < 0.3 + 2 * push) v = -amp * sin(PI * (ph - 0.3 - push) / push);
        if (c->kind == NUDGE_L || c->kind == NUDGE_L_RUMBLE) a[0] -= v;
        if (c->kind == NUDGE_R) a[0] += v;
        if (c->kind == NUDGE_U) a[1] += v;                  /* up the screen */
        if (c->kind == NUDGE_D) a[1] -= v;
        if (c->kind >= VERT_UP) {                           /* up or down in the room */
            double s = c->kind == VERT_DOWN ? -v : v, th = held_at(c);
            a[1] += s * cos(th);
            a[2] += s * sin(th);
        }
        break;
    }
    case TAPS: {                                    /* a thumb on the screen, 5 a second, pushing the phone back */
        double tp = fmod(t, 0.2);
        if (tp < 0.015) {
            double v = c->amp * sin(PI * tp / 0.015);
            a[2] = -v;
            a[0] = 0.15 * v;
            a[1] = -0.1 * v;
        }
        break;
    }
    default: break;
    }
}

static int run(const Case *c)
{
    Motion m;
    motion_reset(&m);
    rng = 12345;
    long got[4] = { 0, 0, 0, 0 };
    const double secs = 10.0;
    for (double t = 0; t < secs; t += (1.0 + 0.1 * (rnd() * 2 - 1)) / c->rate) {
        double a[3];
        movement(c, t, a);
        /* gravity: the phone held 40 degrees back from upright, turned slowly in TURNED */
        double tilt = held_at(c), roll = c->kind == TURNED ? 0.6 * sin(2 * PI * 0.25 * t) : 0;
        double gx = 9.81 * cos(tilt) * sin(roll), gy = 9.81 * cos(tilt) * cos(roll), gz = 9.81 * sin(tilt);
        bool motor = (c->kind == RUMBLE || c->kind == NUDGE_L_RUMBLE) && fmod(t, 0.1) < 0.06 + 0.05;
        int r = motion_sample(&m, 1000.0 + t, (float)(a[0] + gx + 0.15 * gauss()), (float)(a[1] + gy + 0.15 * gauss()),
                              (float)(a[2] + gz + 0.15 * gauss()), motor);
        if (r) got[r]++;
    }
    bool ok = true;
    for (int i = 1; i < 4; i++) if (c->expect[i] >= 0 && got[i] != c->expect[i]) ok = false;
    printf("%-44s %s  left %ld right %ld up %ld\n", c->name, ok ? "ok  " : "FAIL", got[1], got[2], got[3]);
    return ok;
}

int main(void)
{
    const Case cases[] = {
        { "still",                                    STILL,   0,   100, { 0, 0, 0, 0 } },
        { "handled (slow movements, 2.5 m/s2)",       HANDLED, 2.5, 100, { 0, 0, 0, 0 } },
        { "turned left and right",                    TURNED,  0,   100, { 0, 0, 0, 0 } },
        { "walking",                                  WALKING, 3,   100, { 0, 0, 0, 0 } },
        { "the vibration motor (6 m/s2)",             RUMBLE,  6,   100, { 0, 0, 0, 0 } },
        { "a strong vibration motor (12 m/s2)",       RUMBLE,  12,  100, { 0, 0, 0, 0 } },
        { "a strong vibration motor, 50 a second",    RUMBLE,  12,  50,  { 0, 0, 0, 0 } },
        { "taps on the screen (6 m/s2)",              TAPS,    6,   100, { 0, 0, 0, 0 } },
        { "hard taps on the screen (25 m/s2)",        TAPS,    25,  100, { 0, 0, 0, 0 } },
        { "very hard taps on the screen (35 m/s2)",   TAPS,    35,  100, { 0, 0, 0, 0 } },
        { "weak nudges left (5 m/s2)",                NUDGE_L, 5,   100, { 0, 0, 0, 0 } },
        { "nudges down the screen (18 m/s2)",         NUDGE_D, 18,  100, { 0, 0, 0, 10 } },
        { "nudges left (15 m/s2)",                    NUDGE_L, 15,  100, { 0, 10, 0, 0 } },
        { "nudges right (15 m/s2)",                   NUDGE_R, 15,  100, { 0, 0, 10, 0 } },
        { "nudges up (15 m/s2)",                      NUDGE_U, 15,  100, { 0, 0, 0, 10 } },
        { "nudges left (15 m/s2), 50 samples a second", NUDGE_L, 15, 50,  { 0, 10, 0, 0 } },
        { "nudges left (12 m/s2), 200 samples a second", NUDGE_L, 12, 200, { 0, 10, 0, 0 } },
        { "nudges right (30 m/s2)",                   NUDGE_R, 30,  100, { 0, 0, 10, 0 } },
        { "vertical shakes, up first",                VERT_UP, 15,  100, { 0, 0, 0, 10 } },
        { "vertical shakes, down first",              VERT_DOWN, 15, 100, { 0, 0, 0, 10 } },
        { "vertical shakes, 15 m/s2, 50 a second",    VERT_DOWN, 15, 50,  { 0, 0, 0, 10 } },
        { "vertical shakes, 12 m/s2, 200 a second",   VERT_DOWN, 12, 200, { 0, 0, 0, 10 } },
        { "vertical shakes, the phone lying flat",    VERT_FLAT, 15, 100, { 0, 0, 0, 10 } },
        { "nudges left (20 m/s2) during the rumble",  NUDGE_L_RUMBLE, 0, 100, { 0, 10, 0, 0 } },
        { "the same, 50 samples a second",            NUDGE_L_RUMBLE, 0, 50,  { 0, 10, 0, 0 } },
    };
    int bad = 0;
    for (size_t i = 0; i < sizeof cases / sizeof cases[0]; i++) bad += !run(&cases[i]);
    printf(bad ? "%d FAILED\n" : "ALL OK\n", bad);
    return bad ? 1 : 0;
}
