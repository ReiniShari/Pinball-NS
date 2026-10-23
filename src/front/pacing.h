/*
 * pacing.h - the pace of the game on a screen with its own refresh rate, and its sound on a sound
 * card with its own clock; shared by the front-ends, tested by tools/pacetest.c.
 *
 * The game makes 59.7275 frames a second; screens refresh at 60, 90, 120, 144 Hz... Paced by the
 * sound card (as up to 2.0), the number of frames run before each refresh depended on when the
 * card had last taken samples: 0, 1 or 2, irregularly. Every frame dropped or shown twice is a
 * jolt of the motion, and the game's fast animations (lights blinking every 2 or 4 frames) blink
 * irregularly: the "flicker" and the "slowdowns" seen on a phone.
 *
 * Here the screen sets the pace. The front-end gives the time of each refresh (the vertical blank
 * itself where the system tells it: Choreographer on Android, D3DKMT on Windows); their spacing
 * gives the refresh period. When `num` frames of the game fit `den` refreshes (60 Hz: 1 in 1,
 * 120 Hz: 1 in 2, 90 Hz: 2 in 3, 144 Hz: 5 in 12...) within 1.5 %, the game runs exactly that many:
 * at 60 frames a second instead of 59.73 (+0.46 %, not perceptible), and every frame stays on the
 * screen for the same number of refreshes, or a fixed pattern of them (90 Hz: 2, 1, 2, 1...).
 * Otherwise, or when the refreshes do not fall on a regular grid (a display that has none, or whose
 * times are not known: then more than 5 % of them out of step), the frames follow the game's own
 * rate as closely as the refreshes allow.
 *
 * The sound follows the frames (SoundPacer): the emulator makes its samples at the rate that gives
 * the card exactly what it plays, corrected by at most 0.5 % to keep the waiting samples near a
 * target (the card's clock is never exactly the screen's). The card's rate is the nominal one,
 * unless it is measured more than 2 % away by windows of a few seconds (the Android emulator's:
 * 41.7 kHz for 48 kHz); a card held by the system is not measured. The target grows on a device
 * that leaves the card short now and then (2.5).
 */
#ifndef PB_PACING_H
#define PB_PACING_H

#include <math.h>
#include <stdbool.h>
#include <string.h>

#define PACER_GAME_PERIOD (70224.0 / 4194304.0)     /* a frame of the game, seconds */
#define PACER_MAX_DEN 12
#define PACER_STEP 0.25                             /* out of step: farther from a whole refresh */

typedef struct {
    double last;          /* time of the previous refresh (0: none yet) */
    double period;        /* refresh period (0: unknown) */
    double base;          /* the period is measured from this refresh... */
    long base_n;          /* ...and the refreshes counted since: the time of one refresh may be
                           * off by a millisecond (Windows), the sum of hundreds of them is not */
    int num, den;         /* `num` game frames every `den` refreshes (den 0: none fits) */
    int count;            /* toward the next frames (locked): num per refresh, den per frame */
    double owed;          /* time owed to the emulation (not locked, or a refresh out of step) */
    double fps;           /* game frames a second actually run */
    double cand;          /* a spacing that is no whole number of refreshes, seen in a row... */
    int cand_n;
    int same_r, same_n;   /* ...or the same number of refreshes (2, 3) every time: the rate changed */
    double irregular;     /* share of the refreshes out of step lately (smoothed) */
    bool locked;          /* frames counted in refreshes (num/den), else in time */
} Pacer;

static inline void pacer_reset(Pacer *p)
{
    memset(p, 0, sizeof *p);
    p->fps = 1.0 / PACER_GAME_PERIOD;
}

/* After a pause (menu, background, a stall): the next refresh starts afresh, nothing owed. */
static inline void pacer_restart(Pacer *p)
{
    p->last = 0;
    p->count = 0;
    p->owed = 0;
    p->cand_n = 0;
    p->same_n = 0;
}

/* the smallest den (then num) such that num / den game frames a refresh is within 1.5 % of the
 * game's own rate; 0 if none */
static inline int pacer_ratio(double period, int *num)
{
    double x = period / PACER_GAME_PERIOD;              /* game frames a refresh, at the game's rate */
    for (int den = 1; den <= PACER_MAX_DEN; den++) {
        int n = (int)floor(x * den + 0.5);
        if (n >= 1 && n <= 4 * den && fabs((double)n / den - x) < x * 0.015) { *num = n; return den; }
    }
    *num = 0;
    return 0;
}

static inline void pacer_new_period(Pacer *p, double period, double now)
{
    p->period = period;
    p->base = now;
    p->base_n = 0;
    p->cand_n = p->same_n = 0;
}

/* How many refreshes `dt` is (1, or more after missed ones; rounded), measuring the period on the
 * way. */
static inline int pacer_refreshes(Pacer *p, double now, double dt)
{
    if (p->period <= 0) { pacer_new_period(p, dt, now); return 1; }
    double x = dt / p->period;
    int r = (int)floor(x + 0.5);
    /* on the grid: 1 refresh, or more after missed ones (up to 2.4: 4 at most, and a phone at
     * 120 Hz that missed 5 lost a frame of the game) */
    bool step = r >= 1 && r <= 32 && fabs(x - r) <= PACER_STEP;
    p->irregular += ((step ? 0.0 : 1.0) - p->irregular) * 0.02;
    if (!step) {
        /* no whole number of refreshes: a time known badly (counted as rounded), or the rate
         * changed (90 Hz to 60 Hz: 1.5): measured again once the same spacing is seen 8 times */
        if (p->cand_n > 0 && fabs(dt - p->cand) < p->cand * 0.1) {
            p->cand += (dt - p->cand) * 0.25;
            if (++p->cand_n >= 8) { pacer_new_period(p, p->cand, now); return 1; }
        } else {
            p->cand = dt;
            p->cand_n = 1;
        }
        p->same_n = 0;
        if (r < 1) return 0;
        if (r > 4) r = 4;
        p->base_n += r;
        return r;
    }
    p->cand_n = 0;
    /* 2 (3...) refreshes every time, 16 times in a row: the rate went down (120 Hz to 60 Hz when
     * the system grants the rate asked for; a device that draws every other refresh only) */
    if (r >= 2 && r == p->same_r) {
        if (++p->same_n >= 16) { pacer_new_period(p, p->period * r, now); return 1; }
    } else {
        p->same_r = r;
        p->same_n = r >= 2;
    }
    p->base_n += r;
    if (p->base_n >= 4) p->period = (now - p->base) / p->base_n;
    if (p->base_n >= 2400) {                            /* 40 s at 60 Hz: the last 20 s from now on */
        p->base = now - p->period * 1200;
        p->base_n = 1200;
    }
    return r;
}

/* A refresh happened at `now` (seconds): how many game frames to run before the next picture
 * (0 to max). */
static inline int pacer_frames(Pacer *p, double now, int max)
{
    if (p->last <= 0) { p->last = now; return 1; }
    double dt = now - p->last;
    p->last = now;
    if (dt <= 0) return 0;
    if (dt > 0.25) {                                    /* stopped meanwhile: go on */
        p->count = 0;
        p->owed = 0;
        p->base = now;
        p->base_n = 0;
        return 1;
    }

    int r = pacer_refreshes(p, now, dt);
    int num, den = pacer_ratio(p->period, &num);
    if (den != p->den || num != p->num) { p->den = den; p->num = num; p->count = 0; }

    /* counted in refreshes while they fall on their grid (fewer than 5 % out of step to start,
     * 15 % to stop: no back and forth); else in time (the time owed is kept while the measure of
     * the period moves) */
    bool locked = p->den && p->irregular < (p->locked ? 0.15 : 0.05);
    if (locked != p->locked) { p->locked = locked; p->count = 0; p->owed = 0; }
    int n;
    if (locked) {
        p->count += r * p->num;
        n = p->count / p->den;
        p->count -= n * p->den;
        p->fps = p->num / (p->den * p->period);
    } else {
        p->owed += dt;
        n = (int)floor(p->owed / PACER_GAME_PERIOD);
        p->owed -= n * PACER_GAME_PERIOD;
        p->fps = 1.0 / PACER_GAME_PERIOD;
    }
    if (n > max) { n = max; p->count = 0; p->owed = 0; }       /* far behind: catch up no further */
    return n;
}

/* The rate (samples a second of the game's time) at which the emulator must make its sound for
 * the card to play `card_rate` samples a second while the frames run at p->fps, corrected toward
 * `target` waiting samples. */
static inline double pacer_sound_rate(const Pacer *p, double card_rate, double waiting, double target)
{
    double err = (target - waiting) / target;   /* > 0: too few waiting, make a little more */
    if (err > 1) err = 1;
    if (err < -1) err = -1;
    return card_rate / (p->fps * PACER_GAME_PERIOD) * (1.0 + 0.005 * err);
}

/* ------------------------------------------------------------------ the sound */

#define SOUND_WINDOW 4.0          /* seconds of a measure of the card's rate */
#define SOUND_HELD   0.1          /* the card took nothing for longer: held by the system */

typedef struct {
    double nominal;       /* the card's nominal rate (frames a second) */
    double rate;          /* the rate used: nominal, or measured if far from it */
    double measured;      /* the last measure (0: none yet) */
    double t0, asked0;    /* start of the measure: time, frames asked for (asked0 < 0: not taken) */
    int off;              /* measures in a row more than 2 % off the nominal rate */
    double last_asked, last_move;   /* the card's progress: frames asked for, when they last changed */
    double level;         /* frames waiting for the card, smoothed */
    double target;        /* frames to keep waiting: base, more on a device that keeps it short */
    double base;          /* the target asked for */
    double last_call;     /* time of the last sound_pace (0: none) */
    double started;       /* the stream's start (it fills its buffer: no shortage counted) */
    double calm;          /* seconds without a shortage */
    double last_raise;
} SoundPacer;

enum { SOUND_KEEP, SOUND_PAD, SOUND_FLUSH };

static inline void sound_reset(SoundPacer *s, double nominal, double target)
{
    memset(s, 0, sizeof *s);
    s->nominal = s->rate = nominal;
    s->target = s->level = s->base = target;
    s->asked0 = -1;
}

/* A new stream, opened at `now`: its first half second (it fills its buffer) is not measured. */
static inline void sound_restart(SoundPacer *s, double now)
{
    s->t0 = now + 0.5;
    s->asked0 = -1;
    s->last_move = now;
    s->level = s->target;
    s->last_call = 0;
    s->started = now;
}

/* Before a frame of the game, at `now`: the card has asked for `asked` frames in all (any origin)
 * and `waiting` frames wait for it; `frames_left` frames of the game are about to be run before the
 * next picture, this one included. Returns what to do first: SOUND_PAD (silence: *pad frames; nothing
 * waits, at the start or after a stall; not before: the frames about to be made may well come in
 * time, and silence added then would be a gap; only what these frames will not make up: after a
 * stall the frames run to catch up already bring the sound back near the target; or the target
 * raised), SOUND_FLUSH (drop what waits: far ahead, the card stalled or held); *rate: the rate at
 * which to make the frame's sound (pb_set_audio_rate). */
static inline int sound_pace(SoundPacer *s, const Pacer *p, double now, double asked, double waiting,
                             int frames_left, double *rate, double *pad)
{
    /* The card's rate, measured by windows of SOUND_WINDOW seconds. A phone's card is within a few
     * hundredths of a percent of its rate: the correction takes it. A card more than 2 % off in two
     * measures in a row (5 % in one: the Android emulator's) is followed. A card held by the system
     * (nothing taken for SOUND_HELD s: a call, a notification, another output) starts the measure
     * again. Up to 2.4 the measure ran from the start of the stream: a card held a second or two
     * left it a few percent off, followed for minutes, the sound short of samples (gaps, the music
     * dragging) or flushed. */
    bool resumed = false;                   /* the card takes again after being held */
    if (asked != s->last_asked) {
        resumed = now - s->last_move > SOUND_HELD && s->last_asked > 0;
        s->last_asked = asked;
        s->last_move = now;
    } else if (now - s->last_move > SOUND_HELD && s->asked0 >= 0) {
        s->t0 = now + 0.5;
        s->asked0 = -1;
    }
    if (s->t0 > 0 && now >= s->t0) {
        if (s->asked0 < 0) { s->asked0 = asked; s->t0 = now; }
        else if (now - s->t0 >= SOUND_WINDOW) {
            s->measured = (asked - s->asked0) / (now - s->t0);
            double off = fabs(s->measured / s->nominal - 1);
            if (off > 0.02 && s->measured > s->nominal * 0.7 && s->measured < s->nominal * 1.3) s->off += off > 0.05 ? 2 : 1;
            else s->off = 0;
            s->rate = s->off >= 2 ? s->measured : s->nominal;
            s->asked0 = asked;
            s->t0 = now;
        }
    }
    /* A device that leaves the frames late now and then, longer than the sound waiting lasts, has
     * the card find too few samples: the target is raised (up to 3 times the one asked for, a
     * second apart) when what waits falls under a quarter of it, the frames made without a pause
     * and the stream started 2 s before; lowered again after a minute without. */
    double dt = s->last_call > 0 ? now - s->last_call : 1.0;
    bool running = dt < 0.25 && now - s->started > 2.0;
    s->last_call = now;
    if (running) s->calm += dt;
    double raised = 0;
    if (running && waiting < s->target * 0.25 && now - s->last_raise > 1.0 && s->target < s->base * 3) {
        double t = s->target * 1.5 < s->base * 3 ? s->target * 1.5 : s->base * 3;
        raised = t - s->target;
        s->target = t;
        s->last_raise = now;
        s->calm = 0;
    } else if (s->calm > 60 && s->target > s->base) {
        s->target = s->target / 1.5 > s->base ? s->target / 1.5 : s->base;
        s->calm = 30;
    }
    int act = SOUND_KEEP;
    *pad = 0;
    if (waiting < 1) {
        double coming = frames_left * s->rate / p->fps;     /* what the frames left will make */
        *pad = s->target - coming;
        if (*pad > 0) act = SOUND_PAD; else *pad = 0;
        s->level = s->target;
    } else if (waiting > s->target + s->base * 3 || (resumed && waiting > s->target * 1.5)) {
        /* far ahead: the card stalled; or the frames made while it was held: the sound goes on
         * with the game's (they would have been late by as much, drained at 0.5 % for long) */
        act = SOUND_FLUSH;
        s->level = s->target;
    } else if (raised > 0) {
        /* half the raise in silence now, what waits about to run out anyway (filled at 0.5 % a
         * second, the rest takes seconds: the card would find it short meanwhile) */
        *pad = raised * 0.5;
        act = SOUND_PAD;
        s->level += (waiting - s->level) * 0.05;
    } else {
        s->level += (waiting - s->level) * 0.05;
    }
    *rate = pacer_sound_rate(p, s->rate, s->level, s->target);
    return act;
}

#endif
