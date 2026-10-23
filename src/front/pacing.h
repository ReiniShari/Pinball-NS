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
 * the card exactly what it plays, corrected by at most 0.5 % to keep the lowest of what waits, over
 * the last seconds, at a target (the card's clock is never exactly the screen's); the correction
 * moves over seconds, the pitch never wavers. The card's rate is its nominal one, unless measured
 * steadily far from it (the Android emulator's: 41.7 kHz for 48 kHz); a card held by the system is
 * not measured. The target grows on a device that leaves the card short now and then, without a
 * silence: a frame of the game is added (2.7).
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
    double first_t;       /* its first measure: the spacing of the first refreshes, from this time */
    int first_n;
    double base;          /* the period is measured from this refresh... */
    long base_n;          /* ...and the refreshes counted since: the time of one refresh may be
                           * off by a millisecond (Windows), the sum of hundreds of them is not */
    long base_min;        /* the period kept until base_n reaches this (a base begun after a pause) */
    int num, den;         /* `num` game frames every `den` refreshes (den 0: none fits) */
    double count;         /* toward the next frames (locked): num per refresh, den per frame */
    double owed;          /* time owed to the emulation (not locked, or a refresh out of step) */
    double fps;           /* game frames a second actually run */
    double cand;          /* a spacing that is no whole number of refreshes, seen in a row... */
    int cand_n;
    int same_r, same_n;   /* ...or the same number of refreshes (2, 3) every time: the rate changed */
    double irregular;     /* share of the refreshes out of step lately (smoothed) */
    bool locked;          /* frames counted in refreshes (num/den), else in time */
    long dropped;         /* frames not run: too far behind to catch up (statistics) */
} Pacer;

static inline void pacer_reset(Pacer *p)
{
    memset(p, 0, sizeof *p);
    p->fps = 1.0 / PACER_GAME_PERIOD;
}

/* After a pause (menu, background, a stall): the next refresh starts afresh, nothing owed, and the
 * measure of the period begins again there. Up to 2.7 the base of the measure was kept: the time of the
 * pause was counted as refreshes' (half a minute of play, then 2 s in the menu: a period 7 % too long),
 * the base moved on at the same rate after 40 s: the game ran its frames at the screen's rate but made
 * its sound for a slower one, 1 to 2 % lower and slower, skipped now and then; or a ratio such as 6/5
 * was found, the game 20 % too fast. */
static inline void pacer_restart(Pacer *p)
{
    p->last = 0;
    p->count = 0;
    p->owed = 0;
    p->cand_n = 0;
    p->same_n = 0;
    p->base_n = 0;
    p->base_min = p->period > 0 ? 30 : 0;           /* (the period known: kept until well measured again) */
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
    p->base_min = 0;
    p->cand_n = p->same_n = 0;
}

/* How many refreshes `dt` is (1, or more after missed ones; off their grid, a fraction), measuring
 * the period on the way. */
static inline double pacer_refreshes(Pacer *p, double now, double dt)
{
    if (p->period <= 0) {
        /* the first period: the mean of 8 spacings (a time known within a millisecond made one alone
         * 15 % off at 144 Hz, the refreshes then off its grid, measured again only slowly) */
        if (p->first_n == 0) p->first_t = now - dt;
        if (++p->first_n >= 8) { pacer_new_period(p, (now - p->first_t) / p->first_n, now); p->first_n = 0; }
        return 1;
    }
    double x = dt / p->period;
    int r = (int)floor(x + 0.5);
    /* on the grid: 1 refresh, or more after missed ones (up to 2.4: 4 at most, and a phone at
     * 120 Hz that missed 5 lost a frame of the game) */
    bool step = r >= 1 && r <= 32 && fabs(x - r) <= PACER_STEP;
    if (!step) {
        /* No whole number of refreshes: a time known badly (counted as rounded), or the rate changed
         * (60 Hz to 120 Hz, a phone touched: 0.5; 90 Hz to 60 Hz: 1.5), measured again once the same
         * spacing is seen 8 times; from the second one, counted as it is, a fraction of a refresh (up
         * to 2.6 rounded: the refreshes of a screen gone from 60 to 120 Hz, each counted whole, ran the
         * game twice as fast until measured). Only spacings that do not repeat make the refreshes
         * irregular. */
        bool same = p->cand_n > 0 && fabs(dt - p->cand) < p->cand * 0.1;
        p->irregular += ((same ? 0.0 : 1.0) - p->irregular) * 0.02;
        if (same) {
            p->cand += (dt - p->cand) * 0.25;
            if (++p->cand_n >= 8) { pacer_new_period(p, p->cand, now); return 1; }
        } else {
            p->cand = dt;
            p->cand_n = 1;
        }
        p->same_n = 0;
        if (same || fabs(x - 0.5) < 0.06) {
            /* a new rate (60 to 120 Hz: a half, the first one too): the measure of the period begins
             * again after it (a base across the change measured neither rate) */
            p->base = now;
            p->base_n = 0;
            p->base_min = 30;
            return same ? (x < 4 ? x : 4) : 0.5;
        }
        if (r > 0) p->base_n += r;
        return r < 1 ? 0 : r > 4 ? 4 : r;
    }
    p->irregular += (0.0 - p->irregular) * 0.02;
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
    if (p->base_n >= 4 && p->base_n >= p->base_min) p->period = (now - p->base) / p->base_n;
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
    if (p->last <= 0) { p->last = now; p->base = now; p->base_n = 0; return 1; }
    double dt = now - p->last;
    p->last = now;
    if (dt <= 0) return 0;
    if (dt > 0.25) {                                    /* stopped meanwhile: go on */
        p->count = 0;
        p->owed = 0;
        p->base = now;
        p->base_n = 0;
        p->base_min = p->period > 0 ? 30 : 0;
        return 1;
    }

    double r = pacer_refreshes(p, now, dt);
    int num, den = pacer_ratio(p->period, &num);
    if (den != p->den || num != p->num) {
        /* the part of a frame counted so far is kept (a rate going back and forth lost one each time) */
        p->count = p->den && den ? p->count * den / p->den : 0;
        p->den = den;
        p->num = num;
    }

    /* counted in refreshes while they fall on their grid (fewer than 5 % out of step to start,
     * 15 % to stop: no back and forth), from 60 refreshes measured (times known within a
     * millisecond at 144 Hz gave a period 2.5 % off after a few: the wrong ratio, then a change of
     * it); else in time (the time owed is kept while the measure of the period moves) */
    bool locked = p->den && p->irregular < (p->locked ? 0.15 : 0.05) && (p->locked || p->base_n >= 60);
    if (locked != p->locked) { p->locked = locked; p->count = 0; p->owed = 0; }
    int n;
    if (locked) {
        p->count += r * p->num;
        n = (int)floor(p->count / p->den + 1e-9);
        p->count -= n * p->den;
        p->fps = p->num / (p->den * p->period);
    } else {
        p->owed += dt;
        n = (int)floor(p->owed / PACER_GAME_PERIOD);
        p->owed -= n * PACER_GAME_PERIOD;
        p->fps = 1.0 / PACER_GAME_PERIOD;
    }
    if (n > max) { p->dropped += n - max; n = max; p->count = 0; p->owed = 0; }   /* far behind: catch up no further */
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
#define SOUND_HELD   0.5          /* the card took nothing for longer: held by the system */
#define SOUND_LIMIT  32768.0      /* frames a front-end can keep waiting, by default (the Android ring) */
#define SOUND_SMOOTH 2.0          /* seconds: how slowly the correction of the rate moves */
#define SOUND_SPAN   8            /* seconds: the level is the lowest of what waited over as many */
#define SOUND_FOLLOW 0.03         /* a card measured this far off its nominal rate, steadily: followed */

typedef struct {
    double nominal;       /* the card's nominal rate (frames a second) */
    double rate;          /* the rate used: nominal, or measured if far from it */
    double measured;      /* the last measure (0: none yet) */
    double t0, asked0;    /* start of the measure: time, frames asked for (asked0 < 0: not taken) */
    double off[3];        /* the last measures, relative to the nominal rate (newest first) */
    int n_off;
    double last_asked, last_move;   /* the card's progress: frames asked for, when they last changed */
    double still;         /* the longest time the card took nothing while the frames ran (decays) */
    double level;         /* frames waiting for the card: the lowest of the last SOUND_SPAN seconds */
    double low[SOUND_SPAN];   /* the lowest of each of these seconds (low[low_i]: this one) */
    int low_i, low_n;
    double low_t;             /* start of this second */
    double target;        /* frames to keep waiting: base, more on a device that keeps it short */
    double base;          /* the target asked for */
    double corr;          /* the correction of the rate in use (-0.005..0.005), moving slowly */
    double fps;           /* the frames a second the rate is made for, moving slowly */
    double last_call;     /* time of the last sound_pace (0: none) */
    double started;       /* the stream's start (it fills its buffer: no shortage counted) */
    double calm;          /* seconds without a shortage */
    double last_raise, last_flush;
    bool building;        /* the target was raised: what waits has not reached it yet */
    int owed;             /* frames of the game to add (SOUND_EXTRA), a raise made at once */
    bool rerated;         /* the card's rate just changed (followed): what waits was made for the old one */
    double limit;         /* frames the front-end can keep waiting (SOUND_LIMIT unless it says less) */
    long extra;           /* frames of the game added to keep the card fed (statistics) */
} SoundPacer;

/* what to do before a frame of the game (sound_pace) */
enum { SOUND_KEEP, SOUND_PAD, SOUND_FLUSH, SOUND_EXTRA, SOUND_TRIM };

static inline void sound_reset(SoundPacer *s, double nominal, double target)
{
    memset(s, 0, sizeof *s);
    s->nominal = s->rate = nominal;
    s->target = s->level = s->base = target;
    s->asked0 = -1;
    s->limit = SOUND_LIMIT;
}

/* the most the target may grow to: 5 times the one asked for, 60 % of what can wait */
static inline double sound_cap(const SoundPacer *s)
{
    return s->base * 5 < s->limit * 0.6 ? s->base * 5 : s->limit * 0.6;
}

/* the level starts afresh at `v` (a new stream, a flush, silence added) */
static inline void sound_level_reset(SoundPacer *s, double v, double now)
{
    s->level = v;
    s->low[0] = v;
    s->low_i = 0;
    s->low_n = 1;
    s->low_t = now;
}

/* A new stream, opened at `now`: its first half second (it fills its buffer) is not measured. */
static inline void sound_restart(SoundPacer *s, double now)
{
    s->t0 = now + 0.5;
    s->asked0 = -1;
    s->last_move = now;
    sound_level_reset(s, s->target, now);
    s->last_call = 0;
    s->started = now;
    s->still = 0;
    s->corr = 0;
}

/* Before a frame of the game, at `now`: the card has asked for `asked` frames in all (any origin)
 * and `waiting` frames wait for it; `frames_left` frames of the game are about to be run before the
 * next picture, this one included. Returns what to do first:
 *   SOUND_PAD    silence (*pad frames): nothing waits (the start, a stall), up to the target less
 *                what these frames will make;
 *   SOUND_FLUSH  drop what waits: the card was held by the system (the sound goes on with the game's),
 *                or far too much waits;
 *   SOUND_EXTRA  run one more frame of the game before the picture: the card is about to find too
 *                little (a device that takes its samples late and all at once, found out); the game
 *                goes a frame ahead, its sound goes on without a gap;
 *   SOUND_TRIM   drop the *pad oldest frames of what waits: for SOUND_SPAN seconds it never fell to
 *                twice the target (the card slowed down a while: a busy phone); the sound back in time
 *                at once (a skip) instead of late by a third of a second, drained at 0.5 % for a minute
 *                (the pitch that much higher);
 * and *rate: the rate at which to make the frame's sound (pb_set_audio_rate). */
static inline int sound_pace(SoundPacer *s, const Pacer *p, double now, double asked, double waiting,
                             int frames_left, double *rate, double *pad)
{
    double fps = p->fps > 1 ? p->fps : 1.0 / PACER_GAME_PERIOD;
    double dt = s->last_call > 0 ? now - s->last_call : 1.0;
    bool running = dt < 0.25 && now - s->started > 2.0;       /* frames made without a pause */
    s->last_call = now;
    if (dt >= 0.25) s->last_move = now;                     /* the game paused: not the card */
    /* How long the card can stay without taking anything, then take it all at once (Bluetooth: up
     * to a fifth of a second; a mixer busy with other sounds): meanwhile what waits grows by as
     * much, which is not "far ahead" (not flushed: the card is about to take it). The longest such
     * time, the frames running, decaying by half a minute. */
    s->still *= dt < 0.25 ? 1.0 - dt / 30.0 : 1.0;
    bool resumed = false;                   /* the card takes again after being held */
    bool held = false;                      /* it takes nothing: held by the system */
    if (asked != s->last_asked) {
        double gap = now - s->last_move;
        if (running && gap < SOUND_HELD && gap > s->still) s->still = gap;
        resumed = gap >= SOUND_HELD && s->last_asked > 0;
        s->last_asked = asked;
        s->last_move = now;
    } else if (now - s->last_move > SOUND_HELD) {
        held = true;
        if (s->asked0 >= 0) {
            s->t0 = now + 0.5;
            s->asked0 = -1;
        }
    }

    /* The card's rate, measured by windows of SOUND_WINDOW seconds. A phone's card is within a few
     * hundredths of a percent of its rate, which the correction takes: its nominal rate is kept. Only
     * a card measured more than 3 % off three times in a row, the same way and within 1 % (the Android
     * emulator's: 41.7 kHz for 48 kHz), is followed. Up to 2.6 two measures more than 2 % off, either
     * way, were enough: a Bluetooth output, which takes its samples late then all at once, gave such
     * measures by chance (a window ending while it was late, the next one while it caught up), and the
     * sound was made 2 to 4 % slower or faster for seconds: the music dragged, then rushed. */
    if (s->t0 > 0 && now >= s->t0) {
        if (s->asked0 < 0) { s->asked0 = asked; s->t0 = now; }
        else if (now - s->t0 >= SOUND_WINDOW) {
            s->measured = (asked - s->asked0) / (now - s->t0);
            s->off[2] = s->off[1];
            s->off[1] = s->off[0];
            s->off[0] = s->measured / s->nominal - 1;
            if (s->n_off < 3) s->n_off++;
            double lo = s->off[0], hi = s->off[0];
            for (int i = 1; i < s->n_off; i++) {
                if (s->off[i] < lo) lo = s->off[i];
                if (s->off[i] > hi) hi = s->off[i];
            }
            double was = s->rate;
            if (s->n_off == 3 && (lo > SOUND_FOLLOW || hi < -SOUND_FOLLOW) && hi - lo < 0.01 && hi < 0.3 && lo > -0.3)
                s->rate = s->nominal * (1 + (s->off[0] + s->off[1] + s->off[2]) / 3);
            else if (s->n_off >= 2 && fabs(s->off[0]) < SOUND_FOLLOW / 2 && fabs(s->off[1]) < SOUND_FOLLOW / 2)
                s->rate = s->nominal;
            if (fabs(s->rate / was - 1) > 0.02) s->rerated = true;
            s->asked0 = asked;
            s->t0 = now;
        }
    }

    /* The target is raised when what waits falls under a quarter of it, the frames made without a
     * pause and the stream started 2 s before (a card that takes big bursts, or late; a device whose
     * pictures take long now and then), up to sound_cap, once the previous raise is made, not just
     * after a flush; lowered again after two minutes without. */
    double cap = sound_cap(s), late = s->still * s->rate * 1.25 + 256;
    if (cap > s->limit * 0.9 - late) cap = s->limit * 0.9 - late;       /* room for the peaks */
    if (cap < s->base) cap = s->base;
    if (s->target > cap) s->target = cap;           /* a card found later to take its samples later */
    if (running) s->calm += dt;
    /* (a raise is made before the next one: what waits reaches the target, or 10 s) */
    if (s->building && (waiting >= s->target * 0.9 || now - s->last_raise > 10.0)) s->building = false;
    if (running && !held && !s->building && waiting < s->target * 0.25 && now - s->last_raise > 1.0 &&
        now - s->last_flush > 2.0 && s->target < cap) {
        s->target = s->target * 1.5 < cap ? s->target * 1.5 : cap;
        s->last_raise = now;
        s->calm = 0;
        s->building = true;
        s->owed = 1;
    } else if (s->calm > 120 && s->target > s->base) {
        s->target = s->target / 1.25 > s->base ? s->target / 1.25 : s->base;
        s->calm = 60;
    }
    int act = SOUND_KEEP;
    *pad = 0;
    /* far ahead: the card stalled (held, the ring filled meanwhile), not what a card that took
     * nothing for a while is about to take at once (the longest it did so is learned only once
     * seen: a threshold just above it flushed the first peaks); three quarters of what can wait */
    double flush_at = s->limit * 0.75;
    if (flush_at < s->target + late) flush_at = s->target + late < s->limit * 0.9 ? s->target + late : s->limit * 0.9;
    /* What is regulated is the low point of what waits, not its mean: a card that takes its samples
     * late and all at once leaves peaks above the target, and finds little only when it has caught
     * up, every few seconds. The level is the lowest of the last SOUND_SPAN seconds (2.5, 2.6: smoothed,
     * rising again within a second, and between two low points the sound was made slower, the next
     * low point lower: the target raised again and again). */
    if (now - s->low_t >= 1.0) {
        s->low_i = (s->low_i + 1) % SOUND_SPAN;
        s->low[s->low_i] = waiting;
        if (s->low_n < SOUND_SPAN) s->low_n++;
        s->low_t = now;
    } else if (waiting < s->low[s->low_i]) {
        s->low[s->low_i] = waiting;
    }
    if (held) {
        /* the card held: nothing measured, nothing dropped (what is made beyond the ring's room is,
         * by the front-end); it is flushed when the card takes again */
    } else if (waiting < 1) {
        /* (the start: the target whole, the first frames of a screen not yet measured can come late) */
        double coming = running ? frames_left * s->rate / fps : 0;     /* what the frames left will make */
        *pad = s->target - coming;
        if (*pad > 0) act = SOUND_PAD; else *pad = 0;
        sound_level_reset(s, s->target, now);
    } else if (waiting > flush_at || (resumed && waiting > s->target * 1.5) || (s->rerated && waiting > s->target * 2)) {
        /* or the frames made while the card was held: the sound goes on with the game's (they
         * would have been late by as much, drained at 0.5 % for long); or made for a rate found
         * wrong */
        act = SOUND_FLUSH;
        sound_level_reset(s, s->target, now);
        s->last_flush = now;
        s->rerated = false;
    } else {
        s->rerated = false;
        double lo = s->low[0];
        for (int i = 1; i < s->low_n; i++) if (s->low[i] < lo) lo = s->low[i];
        s->level = lo;
        /* (what is dropped: the excess of the last two seconds, the whole of it at once) */
        if (running && s->low_n == SOUND_SPAN && now - s->started > 20 && s->target <= s->base && lo > s->target * 2 &&
            lo - s->target > (late > 2048 ? late : 2048) && frames_left == 1) {
            double recent = s->low[s->low_i], before = s->low[(s->low_i + SOUND_SPAN - 1) % SOUND_SPAN];
            act = SOUND_TRIM;
            *pad = (recent < before ? recent : before) - s->target;
            sound_level_reset(s, s->target, now);
        }
        /* the target raised: one frame of the game more, its sound at once, after the frames of this
         * picture (2.5, 2.6: half the raise in silence, a gap the player heard; the 0.5 % alone takes
         * seconds, the card short meanwhile) */
        else if (s->owed > 0 && frames_left == 1) { act = SOUND_EXTRA; s->owed--; s->extra++; }
    }
    /* the rate: what the card plays per frame, corrected by at most 0.5 % toward the target; the
     * correction moves over seconds (a pitch that never wavers), as the rate of the frames does */
    double err = (s->target - s->level) / s->target;
    if (err > 1) err = 1;
    if (err < -1) err = -1;
    double k = dt < 0.25 && !held ? dt / SOUND_SMOOTH : 0;
    if (k > 1) k = 1;
    s->corr += (0.005 * err - s->corr) * k;
    s->fps = s->fps > 0 ? s->fps + (fps - s->fps) * k : fps;
    *rate = s->rate / (s->fps * PACER_GAME_PERIOD) * (1.0 + s->corr);
    return act;
}

#endif
