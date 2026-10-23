/*
 * pacetest.c - src/front/pacing.h on simulated screens and sound cards, without the game.
 *
 * A screen refreshes (60, 59.94, 90, 120, 144 Hz..., switching rate, missing refreshes now and
 * then, or with the time of each refresh known only within a millisecond, as on Windows); a sound
 * card takes its samples by bursts at its own rate (its clock a little off, or 13 % off as the
 * Android emulator's). At each refresh the front-end's loop is played: pacer_frames, then for each
 * frame sound_pace and the samples of a frame at the rate given. Checked, after a few seconds:
 *   - judder: a frame of the game shown for a number of refreshes outside its pattern (60 Hz: 1;
 *     120 Hz: 2; 90 Hz: 1 or 2...), a missed refresh excused;
 *   - the game's speed (frames a second) and the pitch correction (at most 0.5 %);
 *   - the sound: no underrun (the card finds too few samples), no flush, the waiting samples near
 *     the target.
 * The pace of the versions up to 2.0 (the frames run while the card wants samples) is played too:
 * its judder must be seen.
 *
 *   pacetest            all the cases, "ALL OK" at the end (exit status 0)
 *   pacetest -v         and the frames shown too long or skipped, the silences added
 *   pacetest -trace N T0 T1 [D]   each refresh of case N (from 0) between T0 and T1 seconds
 *                       (D: the draw of the random events, as -seeds numbers them)
 *   pacetest -seeds K   all the cases with K draws of the random events (missed refreshes...),
 *                       the failures only
 */
#include "../src/front/pacing.h"
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define CLOCK 4194304.0
#define TARGET 2048.0
#define RING 16384.0

typedef struct {
    const char *name;
    double hz, hz2, switch_at;      /* refresh rate (then hz2 from switch_at seconds) */
    double miss;                    /* probability that a refresh is missed by the app */
    double jitter;                  /* the time of a refresh known within +- jitter seconds */
    double card, burst;             /* the card's real rate, frames per burst */
    double stall_at, stall;         /* the app stops for `stall` seconds at stall_at */
    double nominal;                 /* the card's nominal rate */
    int allow_underruns;            /* underruns, silences added and frames lost allowed (a stall) */
    int old;                        /* the pace up to 2.0 (frames run while the card wants samples):
                                     * the judder must be seen, or the test sees nothing */
    double irr_min, irr_max;        /* no regular refreshes: each one irr_min..irr_max s after the
                                     * previous (androidmock on the emulator): the game's own rate */
    double cstall_at, cstall;       /* the card takes nothing for `cstall` seconds from cstall_at (its
                                     * stream held by the system: a call, another output...) */
    int miss_run;                   /* each missed refresh is followed by miss_run - 1 more (a phone
                                     * too slow now and then: a frame of work longer than refreshes) */
} Case;

static uint32_t rng = 12345;
static double rnd(void) { rng = rng * 1664525u + 1013904223u; return (rng >> 8) / 16777216.0; }

static int verbose, quiet, trace_case = -1, case_no;
static uint32_t seed = 12345;
static int draw;
static double trace_t0, trace_t1;

/* while the card is held and 2 s after (the frames made meanwhile flushed, then the waiting refilled) */
static bool held_after(const Case *c, double t)
{
    return c->cstall > 0 && t >= c->cstall_at && t < c->cstall_at + c->cstall + 2.0;
}

static int run(const Case *c)
{
    Pacer p;
    SoundPacer s;
    pacer_reset(&p);
    sound_reset(&s, c->nominal, TARGET);
    sound_restart(&s, 0);
    rng = seed;

    const double end = 60.0, warm = 15.0;
    double t_vsync = 0.02, t_card = 0.0;
    double waiting = 0, asked = 0, carry = 0;
    long frame = 0;                         /* frames run */
    long shown = -1, shown_for = 0;         /* the frame on the screen, refreshes it stayed */
    int excused = 0;                        /* a missed refresh: the next durations are excused */
    long judder = 0, underruns = 0, flushes = 0, pads = 0, frames_warm = 0, refreshes_warm = 0;
    long long_gaps = 0;                     /* no frame made for longer than the sound waiting lasts
                                             * (TARGET less a burst): a gap in the sound is due */
    double last_proc = -1;
    double level_min = 1e9, level_max = 0, dev_max = 0;
    int printed = 0;

    int miss_left = 0;
    while (t_vsync < end) {
        if (c->cstall > 0 && t_card >= c->cstall_at && t_card < c->cstall_at + c->cstall) t_card = c->cstall_at + c->cstall;
        if (t_card <= t_vsync) {                            /* the card takes a burst */
            if (waiting < c->burst && t_card > warm && t_card > 1.0 && !held_after(c, t_card)) {
                underruns++;
                if (case_no == trace_case && t_card >= trace_t0 && t_card <= trace_t1)
                    printf("    %.4f: the card finds %.0f frames\n", t_card, waiting);
            }
            waiting = waiting > c->burst ? waiting - c->burst : 0;
            asked += c->burst;
            t_card += c->burst / c->card;
            continue;
        }
        double hz = (c->switch_at > 0 && t_vsync >= c->switch_at) ? c->hz2 : c->hz;
        double now = t_vsync;
        bool missed = miss_left > 0 || rnd() < c->miss || (c->stall > 0 && now >= c->stall_at && now < c->stall_at + c->stall);
        if (miss_left > 0) miss_left--;
        else if (missed && c->miss_run > 1) miss_left = c->miss_run - 1;
        if (!missed) {
            double seen = now + (c->jitter > 0 ? (rnd() * 2 - 1) * c->jitter : 0);
            int n = pacer_frames(&p, seen, 4);
            if (c->old) {
                n = 0;
                for (double w = waiting; n < 4 && w < TARGET; w += 70224.0 * c->nominal / CLOCK) n++;
            }
            for (int k = 0; k < n; k++) {
                double rate = c->nominal;
                double pad;
                int act = c->old ? SOUND_KEEP : sound_pace(&s, &p, seen, asked, waiting, n - k, &rate, &pad);
                if (act == SOUND_PAD) {
                    if (verbose && now > warm) printf("    pad at %.4f: %.0f waiting, %.0f added\n", now, waiting, pad);
                    waiting += floor(pad);
                    if (now > warm && !held_after(c, now)) pads++;
                }
                else if (act == SOUND_FLUSH) { waiting = 0; if (now > warm && !held_after(c, now)) flushes++; }
                carry += 70224.0 * rate / CLOCK;
                double made = floor(carry);
                carry -= made;
                waiting += made;
                if (waiting > RING) waiting = RING;
                if (now > warm && !c->old) {
                    double dev = fabs(rate * p.fps * PACER_GAME_PERIOD / s.rate - 1);
                    if (dev > dev_max) dev_max = dev;
                }
                frame++;
            }
            if (case_no == trace_case && now >= trace_t0 && now <= trace_t1)
                printf("    %.4f: %d frames, %4.0f waiting (level %6.1f), period %.4f ms, %d/%d, cand %d same %d base %ld\n",
                       now, n, waiting, s.level, p.period * 1000, p.num, p.den, p.cand_n, p.same_n, p.base_n);
            if (now > warm) { frames_warm += n; refreshes_warm++; }
            if (now > warm && !held_after(c, now)) {
                if (waiting < level_min) level_min = waiting;
                if (waiting > level_max) level_max = waiting;
            }
        }
        /* the refresh shows the last frame run */
        long vis = frame - 1;
        if (vis != shown) {
            if (shown >= 0 && now > warm) {
                /* how long the previous frames stayed: frames skipped (0) and the one shown */
                int lo = p.den ? p.den / (p.num ? p.num : 1) : 0, hi = p.den ? (p.den + p.num - 1) / p.num : 99;
                if (!p.den) { lo = (int)floor(PACER_GAME_PERIOD * hz); hi = lo + 1; }
                bool bad = shown_for < lo || shown_for > hi || (vis - shown > 1 && lo > 0);
                if (bad && !excused) {
                    judder++;
                    if (verbose && printed < 20) {
                        printf("    t=%.4f frame %ld shown %ld refreshes (%d..%d), %ld skipped\n", now, shown, shown_for, lo, hi, vis - shown - 1);
                        printed++;
                    }
                }
            }
            if (excused) excused--;
            shown = vis;
            shown_for = 0;
        }
        shown_for++;
        if (!missed) {
            if (last_proc >= 0 && now - last_proc > (TARGET - c->burst) / c->card && now > warm) long_gaps++;
            last_proc = now;
        }
        if (missed) {
            excused = 2 + c->miss_run;
            if (case_no == trace_case && now >= trace_t0 && now <= trace_t1) printf("    %.4f: missed\n", now);
        }
        t_vsync += c->irr_max > 0 ? c->irr_min + rnd() * (c->irr_max - c->irr_min) : 1.0 / hz;
    }

    double fps = frames_warm / (end - warm);
    double expect = p.den ? p.num / (p.den * p.period) : 1.0 / PACER_GAME_PERIOD;
    if (c->irr_max > 0) {
        bool good = !p.locked && fabs(fps * PACER_GAME_PERIOD - 1) < 0.005 && flushes == 0 && pads == 0 && underruns == 0;
        if (!quiet || !good) printf("%-34s %s  locked %d  fps %7.3f  sound: underruns %ld pads %ld flushes %ld level %4.0f..%4.0f\n", c->name,
               good ? "ok  " : "FAIL", p.locked, fps, underruns, pads, flushes, level_min, level_max);
        return good;
    }
    if (c->old) {
        bool seen_judder = judder > 0;
        if (!quiet || !seen_judder) printf("%-34s %s  fps %7.3f  judder %ld (expected: the pace up to 2.0)\n", c->name, seen_judder ? "ok  " : "FAIL", fps, judder);
        return seen_judder;
    }
    bool ok = judder == 0 && flushes == 0 && ((pads <= long_gaps && underruns <= 4 * long_gaps) || c->allow_underruns) &&
              (fabs(fps / expect - 1) < 0.002 || c->allow_underruns) && fabs(fps * PACER_GAME_PERIOD - 1) < 0.02 && dev_max <= 0.00501 &&
              level_min > TARGET * 0.25 && level_max < s.target * 2.5;
    if (quiet && !ok) printf("(draw %d) ", draw);
    if (!quiet || !ok) printf("%-34s %s  ratio %2d/%-2d fps %7.3f  judder %ld  sound: underruns %ld pads %ld flushes %ld level %4.0f..%4.0f correction %.3f %%  card %.0f%s  target %.0f\n",
           c->name, ok ? "ok  " : "FAIL", p.num, p.den, fps, judder, underruns, pads, flushes, level_min, level_max,
           dev_max * 100, s.rate, s.rate != s.nominal ? " (measured)" : "", s.target);
    return ok;
}

int main(int argc, char **argv)
{
    int first = 0;
    verbose = argc > 1 && argv[1][0] == '-' && argv[1][1] == 'v';
    if (argc > 4 && !strcmp(argv[1], "-trace")) {
        trace_case = atoi(argv[2]);
        trace_t0 = atof(argv[3]);
        trace_t1 = atof(argv[4]);
        if (argc > 5) first = atoi(argv[5]);
    }
    const double N = 48000;
    const Case cases[] = {
        { "60 Hz, card 48 kHz",                     60, 0, 0, 0, 0, N, 192, 0, 0, N, 0 },
        { "60 Hz, card +100 ppm, bursts 480",       60, 0, 0, 0, 0, N * 1.0001, 480, 0, 0, N, 0 },
        { "60 Hz, card -300 ppm, bursts 1024",      60, 0, 0, 0, 0, N * 0.9997, 1024, 0, 0, N, 0 },
        { "59.94 Hz",                               59.94, 0, 0, 0, 0, N, 240, 0, 0, N, 0 },
        { "120 Hz",                                 120, 0, 0, 0, 0, N, 96, 0, 0, N, 0 },
        { "90 Hz",                                  90, 0, 0, 0, 0, N, 192, 0, 0, N, 0 },
        { "144 Hz",                                 144, 0, 0, 0, 0, N, 192, 0, 0, N, 0 },
        { "165 Hz",                                 165, 0, 0, 0, 0, N, 192, 0, 0, N, 0 },
        { "75 Hz",                                  75, 0, 0, 0, 0, N, 192, 0, 0, N, 0 },
        { "100 Hz",                                 100, 0, 0, 0, 0, N, 192, 0, 0, N, 0 },
        { "120 Hz, then 60 Hz at 2 s (granted)",    120, 60, 2.0, 0, 0, N, 192, 0, 0, N, 0 },
        { "90 Hz, then 60 Hz at 3 s",               90, 60, 3.0, 0, 0, N, 192, 0, 0, N, 0 },
        { "60 Hz, 1 % of refreshes missed",         60, 0, 0, 0.01, 0, N, 192, 0, 0, N, 0 },
        { "120 Hz, 2 % missed",                     120, 0, 0, 0.02, 0, N, 192, 0, 0, N, 0 },
        { "60 Hz, refresh times +-1 ms (Windows)",  60, 0, 0, 0, 0.001, N, 441, 0, 0, N, 0 },
        { "144 Hz, refresh times +-1 ms",           144, 0, 0, 0, 0.001, N, 441, 0, 0, N, 0 },
        { "60 Hz, emulator card 41.7 kHz",          60, 0, 0, 0, 0, 41700, 1024, 0, 0, N, 0 },
        { "60 Hz, a 300 ms stall at 30 s",          60, 0, 0, 0, 0, N, 192, 30, 0.3, N, 1 },
        { "no regular refreshes (15-32 ms)",        60, 0, 0, 0, 0, N, 480, 0, 0, N, 0, 0, 0.015, 0.032 },
        { "60 Hz, the card held 3 s at 20 s",       60, 0, 0, 0, 0, N, 192, 0, 0, N, 0, 0, 0, 0, 20, 3 },
        { "120 Hz, the card held 1 s at 8 s",       120, 0, 0, 0, 0, N, 96, 0, 0, N, 0, 0, 0, 0, 8, 1 },
        { "60 Hz, 3 % missed by 3 (slow phone)",    60, 0, 0, 0.01, 0, N, 192, 0, 0, N, 1, 0, 0, 0, 0, 0, 3 },
        { "120 Hz, 4 % missed by 5, bursts 960",    120, 0, 0, 0.008, 0, N, 960, 0, 0, N, 1, 0, 0, 0, 0, 0, 5 },
        { "2.0: 60 Hz, paced by the card",          60, 0, 0, 0, 0, N, 192, 0, 0, N, 0, 1 },
        { "2.0: 120 Hz, paced by the card",         120, 0, 0, 0, 0, N, 96, 0, 0, N, 0, 1 },
    };
    int bad = 0, seeds = argc > 2 && !strcmp(argv[1], "-seeds") ? atoi(argv[2]) : 1;
    quiet = seeds > 1;
    for (int k = first; k < first + seeds; k++) {
        seed = 12345u + (uint32_t)k * 7919u;
        draw = k;
        for (size_t i = 0; i < sizeof cases / sizeof cases[0]; i++) {
            case_no = (int)i;
            bad += !run(&cases[i]);
        }
    }
    if (seeds > 1) printf("%d cases x %d draws of the random events\n", (int)(sizeof cases / sizeof cases[0]), seeds);
    printf(bad ? "%d FAILED\n" : "ALL OK\n", bad);
    return bad ? 1 : 0;
}
