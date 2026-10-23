/*
 * pacetest.c - src/front/pacing.h on simulated screens and sound cards, without the game.
 *
 * A screen refreshes (60, 59.94, 90, 120, 144 Hz..., switching rate, now and then for a moment as a
 * phone does when it is touched, missing refreshes, or with the time of each refresh known only within
 * a millisecond, as on Windows); the game thread stalls now and then (a picture that takes long); a
 * sound card takes its samples by bursts at its own rate (its clock a little off, or 13 % off as the
 * Android emulator's; held by the system for seconds; or taking each burst late, up to a fifth of a
 * second, then catching up, as a Bluetooth output). At each refresh the front-end's loop is played:
 * pacer_frames, then for each frame sound_pace and the samples of a frame at the rate given.
 *
 * What the player would see and hear is checked:
 *   - judder: a frame of the game shown for a number of refreshes outside its pattern (60 Hz: 1;
 *     120 Hz: 2; 90 Hz: 1 or 2...), a missed refresh excused;
 *   - the game's speed (frames a second), against the screen's real rate (up to 2.7 against the rate the
 *     pacer had measured: a period measured wrong after a pause in the menu was not seen);
 *   - the pitch of the sound against the card's REAL rate (up to 2.6 the test measured it against the
 *     rate the regulator had chosen to follow, and missed the music made 2 to 4 % slower or faster for
 *     seconds on a Bluetooth output): at most 0.5 % off, moving slowly; and the frames a second the sound
 *     is made for against those the screen really gets (a period measured wrong: the sound made for a
 *     slower screen, lower and slower);
 *   - the sound's events, each one a gap or a jump heard: underruns (the card finds too few samples),
 *     silences added, flushes, frames added to keep the card fed (a frame of the game skipped).
 *     None once the device is known (after 10 s), a few at the start on a device that takes its
 *     samples late or in big bursts; around a stall or a held card, what it costs.
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
#define RING 32768.0
#define LEARN 10.0                          /* the device is learned by then */

enum { K_NORMAL, K_JITTER, K_STALL, K_EMULATOR, K_IRREGULAR, K_OLD };

typedef struct {
    const char *name;
    int kind;
    double hz, hz2, switch_at;      /* refresh rate (then hz2 from switch_at seconds) */
    double miss;                    /* probability that a refresh is missed by the app */
    double jitter;                  /* the time of a refresh known within +- jitter seconds */
    double card, burst;             /* the card's real rate, frames per burst */
    double stall_at, stall;         /* the app stops for `stall` seconds at stall_at */
    double nominal;                 /* the card's nominal rate */
    double irr_min, irr_max;        /* no regular refreshes: each one irr_min..irr_max s after the
                                     * previous (androidmock on the emulator): the game's own rate */
    double cstall_at, cstall;       /* the card takes nothing for `cstall` seconds from cstall_at (its
                                     * stream held by the system: a call, another output...) */
    int miss_run;                   /* each missed refresh is followed by miss_run - 1 more (a phone
                                     * too slow now and then: a frame of work longer than refreshes) */
    double cjitter;                 /* each burst taken up to this many seconds late, the next ones
                                     * catching up (Bluetooth output, a busy audio mixer) */
    double pjitter;                 /* each burst taken up to this many seconds late, no catching up
                                     * beyond the nominal time (a callback thread woken late) */
    double hiccup_every, hiccup;    /* the game thread stops for up to `hiccup` s, every
                                     * `hiccup_every` s on average (a picture that took long) */
    double boost_every, boost;      /* the screen goes to hz2 for `boost` s every `boost_every` s on
                                     * average (a phone raising its rate while it is touched) */
    double target;                  /* the front-end's target (0: TARGET) */
    double learn;                   /* the device is learned by then (0: LEARN) */
    int late_ok;                    /* a stall longer than all before may come after it: a gap, once */
    double cslow_at, cslow, cslow_by;   /* the card takes its samples cslow_by slower for cslow seconds
                                         * from cslow_at (a busy device): what waits grows meanwhile */
    double pause_every, pause;          /* the game paused (the menu, the background) for `pause` seconds
                                         * every `pause_every`: pacer_restart at each refresh meanwhile */
    int judder_ok;                      /* frames out of their pattern allowed (a screen changing its rate
                                         * just as the game comes back from a pause) */
    int lossy;                      /* frames may be lost (more missed than caught up at once) */
} Case;

static uint32_t rng = 12345;
static double rnd(void) { rng = rng * 1664525u + 1013904223u; return (rng >> 8) / 16777216.0; }

static int verbose, quiet, trace_case = -1, case_no;
static uint32_t seed = 12345;
static int draw;
static double trace_t0, trace_t1;

/* around a stall of the game or of the card: what it costs is allowed (2 s after) */
static bool excused_at(const Case *c, double t)
{
    if (c->cstall > 0 && t >= c->cstall_at && t < c->cstall_at + c->cstall + 2.0) return true;
    if (c->stall > 0 && t >= c->stall_at && t < c->stall_at + c->stall + 2.0) return true;
    if (c->cslow > 0 && t >= c->cslow_at && t < c->cslow_at + c->cslow + SOUND_SPAN + 2.0) return true;
    if (c->pause_every > 0) {                           /* in a pause, and the second after it */
        double ph = fmod(t, c->pause_every + c->pause);
        if (ph >= c->pause_every || ph < 1.0) return true;
    }
    return false;
}

typedef struct {
    long judder, frames_warm, refreshes_warm;
    long ev_learn, ev_steady;               /* events heard: underruns, silences, flushes, frames added */
    long underruns, pads, flushes, extras;  /* all of them, the start excepted */
    double pitch_max, pitch_sum, pitch_sq;  /* the pitch against the card's real rate (steady) */
    long pitch_n;
    double wobble;                          /* the most the pitch moved within a second (steady) */
    double level_min, level_max, lat_sum;   /* what waits (steady) */
    long lat_n;
    double last_event;
    double paused_time;                     /* in pauses (steady): not counted in the speed */
    double belief_max;                      /* the frames a second believed against the real ones */
    double expect_sum;                      /* the frames a second expected, summed over the refreshes */
    long expect_n;
} Stats;

static void event(Stats *st, const Case *c, double t, long *count)
{
    if (t < 1.0) return;                    /* the start: the stream fills */
    (*count)++;
    if (excused_at(c, t)) return;
    if (t - st->last_event < 0.1) { st->last_event = t; return; }     /* the same gap */
    st->last_event = t;
    if (t < (c->learn > 0 ? c->learn : LEARN)) st->ev_learn++;
    else st->ev_steady++;
}

static int run(const Case *c)
{
    Pacer p;
    SoundPacer s;
    Stats st;
    memset(&st, 0, sizeof st);
    st.level_min = 1e9;
    pacer_reset(&p);
    double target = c->target > 0 ? c->target : TARGET;
    const double learn = c->learn > 0 ? c->learn : LEARN;
    sound_reset(&s, c->nominal, target);
    sound_restart(&s, 0);
    rng = seed;

    const double end = 60.0, warm = 3.0;
    double t_vsync = 0.02, t_card = 0.0, t_nominal = 0.0;
    double waiting = 0, asked = 0, carry = 0;
    long frame = 0;                         /* frames run */
    long shown = -1, shown_for = 0;         /* the frame on the screen, refreshes it stayed */
    int excused = 0;                        /* a missed refresh: the next durations are excused */
    int printed = 0;
    double next_hiccup = c->hiccup_every > 0 ? c->hiccup_every * (0.5 + rnd()) : 1e9, hiccup_end = -1;
    double next_boost = c->boost_every > 0 ? c->boost_every * (0.5 + rnd()) : 1e9, boost_end = -1;
    double pitch_win[64];                   /* the pitch of the last second, to see it move */
    int pw_n = 0, pw_i = 0;
    double pw_t = 0;

    int miss_left = 0;
    double hz_last = c->hz;                 /* the screen's rate at the last refresh */
    while (t_vsync < end) {
        if (c->cstall > 0 && t_card >= c->cstall_at && t_card < c->cstall_at + c->cstall) t_card = t_nominal = c->cstall_at + c->cstall;
        if (t_card <= t_vsync) {                            /* the card takes a burst */
            if (waiting < c->burst && t_card > warm) {
                event(&st, c, t_card, &st.underruns);
                if (case_no == trace_case && t_card >= trace_t0 && t_card <= trace_t1)
                    printf("    %.4f: the card finds %.0f frames\n", t_card, waiting);
            }
            waiting = waiting > c->burst ? waiting - c->burst : 0;
            asked += c->burst;
            bool slow = c->cslow > 0 && t_card >= c->cslow_at && t_card < c->cslow_at + c->cslow;
            t_nominal += c->burst / (c->card * (slow ? 1 - c->cslow_by : 1));  /* jitter: a pull late, the next ones catch up */
            if (c->cjitter > 0) t_card = fmax(t_card, t_nominal + rnd() * c->cjitter);
            else if (c->pjitter > 0) t_card = t_nominal + rnd() * c->pjitter;
            else t_card = t_nominal;
            continue;
        }
        double now = t_vsync;
        /* the rate of the screen: hz, then hz2 (a switch), or hz2 for a moment (touched) */
        if (now >= next_boost) { boost_end = now + c->boost * (0.5 + rnd()); next_boost = boost_end + c->boost_every * (0.5 + rnd()); }
        double hz = (c->switch_at > 0 && now >= c->switch_at) || now < boost_end ? c->hz2 : c->hz;
        if (now >= next_hiccup) { hiccup_end = now + c->hiccup * (0.3 + 0.7 * rnd()); next_hiccup = hiccup_end + c->hiccup_every * (0.5 + rnd()); }
        bool missed = miss_left > 0 || rnd() < c->miss || (c->stall > 0 && now >= c->stall_at && now < c->stall_at + c->stall) ||
                      now < hiccup_end;
        bool paused = c->pause_every > 0 && fmod(now, c->pause_every + c->pause) >= c->pause_every;
        if (paused) {                                   /* the menu: the screen refreshes, the game waits */
            pacer_restart(&p);
            excused = 10;                               /* (its rate measured again after it) */
            missed = true;
        }
        hz_last = hz;
        if (miss_left > 0) miss_left--;
        else if (missed && !paused && c->miss_run > 1) miss_left = c->miss_run - 1;
        if (!missed) {
            double seen = now + (c->jitter > 0 ? (rnd() * 2 - 1) * c->jitter : 0);
            int n = pacer_frames(&p, seen, 6);
            if (c->kind == K_OLD) {
                n = 0;
                for (double w = waiting; n < 4 && w < TARGET; w += 70224.0 * c->nominal / CLOCK) n++;
            }
            bool extra_done = false;
            for (int k = 0; k < n; k++) {
                double rate = c->nominal;
                double pad;
                int act = c->kind == K_OLD ? SOUND_KEEP : sound_pace(&s, &p, seen, asked, waiting, n - k, &rate, &pad);
                if (act == SOUND_PAD) {
                    if (verbose && now > warm) printf("    pad at %.4f: %.0f waiting, %.0f added\n", now, waiting, pad);
                    waiting += floor(pad);
                    if (now > warm) event(&st, c, now, &st.pads);
                } else if (act == SOUND_FLUSH) {
                    if (verbose && now > warm) printf("    flush at %.4f: %.0f waiting\n", now, waiting);
                    waiting = 0;
                    if (now > warm) event(&st, c, now, &st.flushes);
                } else if (act == SOUND_TRIM) {
                    if (verbose) printf("    trim at %.4f: %.0f waiting, %.0f dropped\n", now, waiting, pad);
                    waiting -= pad;
                    if (now > warm) event(&st, c, now, &st.flushes);
                } else if (act == SOUND_EXTRA && !extra_done && k == n - 1) {
                    /* not heard: a frame of the game skipped */
                    if (verbose) printf("    frame added at %.4f: %.0f waiting\n", now, waiting);
                    extra_done = true;
                    n++;
                    excused = 2;
                    if (now > warm) st.extras++;
                }
                carry += 70224.0 * rate / CLOCK;
                double made = floor(carry);
                carry -= made;
                waiting += made;
                if (waiting > RING) waiting = RING;
                if (now > learn && c->kind != K_OLD && !excused_at(c, now)) {
                    /* the pitch: the samples made a second of real time against what the card plays;
                     * the frames a second believed against the real ones (a screen at one rate) */
                    double pitch = rate * p.fps * PACER_GAME_PERIOD / c->card - 1;
                    if (p.locked && p.den && c->boost <= 0 && (c->switch_at <= 0 || now > c->switch_at + 3)) {
                        double belief = fabs(p.fps / (hz * p.num / p.den) - 1);
                        if (belief > st.belief_max) st.belief_max = belief;
                    }
                    double a = fabs(pitch);
                    if (a > st.pitch_max) st.pitch_max = a;
                    st.pitch_sum += pitch;
                    st.pitch_sq += pitch * pitch;
                    st.pitch_n++;
                    if (now - pw_t >= 1.0 / 32) {
                        pw_t = now;
                        pitch_win[pw_i] = pitch;
                        pw_i = (pw_i + 1) % 32;
                        if (pw_n < 32) pw_n++;
                        double lo = 1, hi = -1;
                        for (int i = 0; i < pw_n; i++) { if (pitch_win[i] < lo) lo = pitch_win[i]; if (pitch_win[i] > hi) hi = pitch_win[i]; }
                        if (pw_n == 32 && hi - lo > st.wobble) st.wobble = hi - lo;
                    }
                }
                frame++;
            }
            if (case_no == trace_case && now >= trace_t0 && now <= trace_t1)
                printf("    %.4f: %d frames, %4.0f waiting (level %6.1f target %5.0f corr %+.3f%%), period %.4f ms, %d/%d\n",
                       now, n, waiting, s.level, s.target, s.corr * 100, p.period * 1000, p.num, p.den);
            if (now > learn) {
                st.frames_warm += n;
                st.refreshes_warm++;
                /* the frames a second this refresh is worth: its screen's rate by the ratio, or the game's */
                st.expect_sum += p.locked && p.den && !p.cand_n ? hz * p.num / p.den : 1.0 / PACER_GAME_PERIOD;
                st.expect_n++;
            }
            if (now > learn && !excused_at(c, now)) {
                if (waiting < st.level_min) st.level_min = waiting;
                if (waiting > st.level_max) st.level_max = waiting;
                st.lat_sum += waiting;
                st.lat_n++;
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
                if (bad && !excused && !(now < boost_end + 0.5 && c->boost > 0)) {
                    st.judder++;
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
        if (paused && now > learn) st.paused_time += 1.0 / hz;
        if (missed && !paused) {
            excused = 2 + c->miss_run;
            if (case_no == trace_case && now >= trace_t0 && now <= trace_t1) printf("    %.4f: missed\n", now);
        }
        t_vsync += c->irr_max > 0 ? c->irr_min + rnd() * (c->irr_max - c->irr_min) : 1.0 / hz;
    }

    double fps = st.frames_warm / (end - learn - st.paused_time);
    double expect = st.expect_n ? st.expect_sum / st.expect_n : 1.0 / PACER_GAME_PERIOD;
    /* (a screen changing its rate now and then: the game's own rate or the screen's, nothing else) */
    if (c->boost > 0 && fps > 59.7275 * 0.998 && fps < 60 * 1.002) expect = fps;
    double pitch_mean = st.pitch_n ? st.pitch_sum / st.pitch_n : 0;
    double pitch_sd = st.pitch_n ? sqrt(fmax(0, st.pitch_sq / st.pitch_n - pitch_mean * pitch_mean)) : 0;
    double lat = st.lat_n ? st.lat_sum / st.lat_n / c->card * 1000 : 0;
    /* the pitch: never more than 0.5 % off, and moving by less than 0.3 % (5 cents) within a second */
    bool pitch_ok = st.pitch_max <= 0.0051 && st.wobble <= (c->kind == K_EMULATOR ? 0.005 : 0.003) && st.belief_max < 0.002;
    bool good;
    switch (c->kind) {
    case K_OLD:
        good = st.judder > 0;
        if (!quiet || !good) printf("%-44s %s  fps %7.3f  judder %ld (expected: the pace up to 2.0)\n", c->name, good ? "ok  " : "FAIL", fps, st.judder);
        return good;
    case K_IRREGULAR:
        good = !p.locked && fabs(fps * PACER_GAME_PERIOD - 1) < 0.005 && st.ev_learn + st.ev_steady == 0 && st.extras <= 2 && pitch_ok;
        break;
    case K_JITTER:
        /* a card that takes its samples late or in big bursts: a few adaptations at the start */
        /* (frames lost: their sound is lost with them, a gap each time at most) */
        good = st.judder == 0 && st.ev_learn <= 2 && st.ev_steady <= (c->lossy ? p.dropped : 0) + c->late_ok && st.extras <= 3 && pitch_ok &&
               (fabs(fps / expect - 1) < 0.002 || c->lossy);
        break;
    case K_EMULATOR:
        /* 13 % off: flushed until followed (three measures, 12 s), then nothing */
        good = st.judder == 0 && st.ev_steady == 0 && st.extras <= 2 && pitch_ok && fabs(fps / expect - 1) < 0.002;
        break;
    default:
        good = st.judder <= c->judder_ok && st.ev_learn + st.ev_steady == 0 && st.extras <= (c->kind == K_STALL ? 2 : 1) && pitch_ok &&
               (fabs(fps / expect - 1) < 0.002 || (c->kind == K_STALL && !c->pause_every)) && fabs(fps * PACER_GAME_PERIOD - 1) < 0.02;
        break;
    }
    if (quiet && !good) printf("(draw %d) ", draw);
    if (!quiet || !good)
        printf("%-44s %s  %2d/%-2d fps %6.3f judder %ld | events %ld+%ld (under %ld pad %ld flush %ld extra %ld) | "
               "pitch max %.3f%% sd %.3f%% wobble %.3f%% fps believed %.3f%% | wait %4.0f..%5.0f (%3.0f ms) target %.0f%s\n",
               c->name, good ? "ok  " : "FAIL", p.num, p.den, fps, st.judder, st.ev_learn, st.ev_steady, st.underruns, st.pads,
               st.flushes, st.extras, st.pitch_max * 100, pitch_sd * 100, st.wobble * 100, st.belief_max * 100,
               st.level_min > 1e8 ? 0 : st.level_min, st.level_max, lat, s.target, p.dropped ? " (frames lost)" : "");
    return good;
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
    /*  name                                          kind        hz   hz2 switch miss jitter card burst stall_at stall nominal
     *                                                irr_min irr_max cstall_at cstall miss_run cjitter pjitter hiccup_every hiccup
     *                                                boost_every boost target */
    const Case cases[] = {
        { "60 Hz, card 48 kHz",                       K_NORMAL,   60,    0, 0, 0, 0, N, 192, 0, 0, N },
        { "60 Hz, card +100 ppm, bursts 480",         K_NORMAL,   60,    0, 0, 0, 0, N * 1.0001, 480, 0, 0, N },
        { "60 Hz, card -300 ppm, bursts 1024",        K_NORMAL,   60,    0, 0, 0, 0, N * 0.9997, 1024, 0, 0, N },
        { "59.94 Hz",                                 K_NORMAL,   59.94, 0, 0, 0, 0, N, 240, 0, 0, N },
        { "120 Hz",                                   K_NORMAL,   120,   0, 0, 0, 0, N, 96, 0, 0, N },
        { "90 Hz",                                    K_NORMAL,   90,    0, 0, 0, 0, N, 192, 0, 0, N },
        { "144 Hz",                                   K_NORMAL,   144,   0, 0, 0, 0, N, 192, 0, 0, N },
        { "165 Hz",                                   K_NORMAL,   165,   0, 0, 0, 0, N, 192, 0, 0, N },
        { "75 Hz",                                    K_NORMAL,   75,    0, 0, 0, 0, N, 192, 0, 0, N },
        { "100 Hz",                                   K_NORMAL,   100,   0, 0, 0, 0, N, 192, 0, 0, N },
        { "120 Hz, then 60 Hz at 2 s (granted)",      K_NORMAL,   120,  60, 2.0, 0, 0, N, 192, 0, 0, N },
        { "90 Hz, then 60 Hz at 3 s",                 K_NORMAL,   90,   60, 3.0, 0, 0, N, 192, 0, 0, N },
        { "60 Hz, 1 % of refreshes missed",           K_NORMAL,   60,    0, 0, 0.01, 0, N, 192, 0, 0, N },
        { "120 Hz, 2 % missed",                       K_NORMAL,   120,   0, 0, 0.02, 0, N, 192, 0, 0, N },
        { "60 Hz, refresh times +-1 ms (Windows)",    K_NORMAL,   60,    0, 0, 0, 0.001, N, 441, 0, 0, N },
        { "144 Hz, refresh times +-1 ms",             K_NORMAL,   144,   0, 0, 0, 0.001, N, 441, 0, 0, N },
        { "Pixel-like: 120 Hz, MMAP 96, woken late",  K_NORMAL,   120,   0, 0, 0, 0, N, 96, 0, 0, N, 0, 0, 0, 0, 0, 0, 0.002 },
        { "Pixel-like: 60 Hz, MMAP 192, woken late",  K_NORMAL,   60,    0, 0, 0, 0, N, 192, 0, 0, N, 0, 0, 0, 0, 0, 0, 0.003 },
        { "60 Hz <-> 120 Hz when touched",            K_NORMAL,   60,  120, 0, 0, 0, N, 96, 0, 0, N, 0, 0, 0, 0, 0, 0, 0.001, 0, 0, 4, 1.5 },
        { "60 Hz, a picture of 20-60 ms every 5 s",   K_JITTER,   60,    0, 0, 0, 0, N, 192, 0, 0, N, 0, 0, 0, 0, 0, 0, 0, 5, 0.06, .late_ok = 1 },
        { "120 Hz, a picture of 20-60 ms every 3 s",  K_JITTER,   120,   0, 0, 0, 0, N, 96, 0, 0, N, 0, 0, 0, 0, 0, 0, 0, 3, 0.06, .late_ok = 1 },
        { "60 Hz, 3 % missed by 3 (slow phone)",      K_JITTER,    60,    0, 0, 0.01, 0, N, 192, 0, 0, N, 0, 0, 0, 0, 3, .lossy = 1 },
        { "120 Hz, 4 % missed by 5, bursts 960",      K_JITTER,    120,   0, 0, 0.008, 0, N, 960, 0, 0, N, 0, 0, 0, 0, 5, .lossy = 1, .late_ok = 1 },
        { "60 Hz, emulator card 41.7 kHz",            K_EMULATOR, 60,    0, 0, 0, 0, 41700, 1024, 0, 0, N, .learn = 18 },
        { "60 Hz, a 300 ms stall at 30 s",            K_STALL,    60,    0, 0, 0, 0, N, 192, 30, 0.3, N },
        { "no regular refreshes (15-32 ms)",          K_IRREGULAR, 60,   0, 0, 0, 0, N, 480, 0, 0, N, 0.015, 0.032 },
        { "60 Hz, the card held 3 s at 20 s",         K_STALL,    60,    0, 0, 0, 0, N, 192, 0, 0, N, 0, 0, 20, 3 },
        { "120 Hz, the card held 1 s at 8 s",         K_STALL,    120,   0, 0, 0, 0, N, 96, 0, 0, N, 0, 0, 8, 1 },
        { "60 Hz, the card 10 % slower 4 s at 15 s",  K_STALL,    60,    0, 0, 0, 0, N, 192, 0, 0, N, .cslow_at = 15, .cslow = 4, .cslow_by = 0.1 },
        { "60 Hz, the menu 2 s every 12 s",           K_STALL,    60,    0, 0, 0, 0, N, 192, 0, 0, N, .pause_every = 12, .pause = 2 },
        { "120 Hz, the menu 6 s every 20 s",          K_STALL,    120,   0, 0, 0, 0, N, 96, 0, 0, N, .pause_every = 20, .pause = 6 },
        { "60 Hz <-> 120 Hz touched, the menu 1 s every 7 s", K_STALL, 60, 120, 0, 0, 0, N, 96, 0, 0, N, 0, 0, 0, 0, 0, 0, 0.001, 0, 0, 4, 1.5,
          .pause_every = 7, .pause = 1, .judder_ok = 30 },
        { "Windows: 60 Hz +-1 ms, paused 3 s every 15 s", K_STALL, 60,   0, 0, 0, 0.001, N, 441, 0, 0, N, .pause_every = 15, .pause = 3 },
        { "120 Hz, the card 30 % slower 2 s at 20 s", K_STALL,    120,   0, 0, 0, 0, N, 96, 0, 0, N, .cslow_at = 20, .cslow = 2, .cslow_by = 0.3 },
        { "60 Hz, Bluetooth: 960, up to 120 ms late", K_JITTER,   60,    0, 0, 0, 0, N, 960, 0, 0, N, 0, 0, 0, 0, 0, 0.12 },
        { "120 Hz, Bluetooth: 1920, up to 200 ms late", K_JITTER, 120,   0, 0, 0, 0, N, 1920, 0, 0, N, 0, 0, 0, 0, 0, 0.2 },
        { "60 Hz, deep buffer: bursts 4800",          K_JITTER,   60,    0, 0, 0, 0, N, 4800, 0, 0, N },
        { "90 Hz, mixer: 480, up to 60 ms late",      K_JITTER,   90,    0, 0, 0, 0, N, 480, 0, 0, N, 0, 0, 0, 0, 0, 0.06 },
        { "120 Hz, Bluetooth: 1920, up to 150 ms late", K_JITTER, 120,   0, 0, 0, 0, N, 1920, 0, 0, N, 0, 0, 0, 0, 0, 0.15 },
        { "60 Hz, Bluetooth: 1024, up to 150 ms late", K_JITTER,  60,    0, 0, 0, 0, N, 1024, 0, 0, N, 0, 0, 0, 0, 0, 0.15 },
        { "120 Hz, Bluetooth: 4096, up to 250 ms late", K_JITTER, 120,   0, 0, 0, 0, N, 4096, 0, 0, N, 0, 0, 0, 0, 0, 0.25 },
        { "60 Hz <-> 120 Hz, Bluetooth 1920, 200 ms", K_JITTER,   60,  120, 0, 0, 0, N, 1920, 0, 0, N, 0, 0, 0, 0, 0, 0.2, 0, 0, 0, 4, 1.5 },
        { "2.0: 60 Hz, paced by the card",            K_OLD,      60,    0, 0, 0, 0, N, 192, 0, 0, N },
        { "2.0: 120 Hz, paced by the card",           K_OLD,      120,   0, 0, 0, 0, N, 96, 0, 0, N },
    };
    int bad = 0, seeds = argc > 2 && !strcmp(argv[1], "-seeds") ? atoi(argv[2]) : 1;
    quiet = seeds > 1;
    for (int k = first; k < first + seeds; k++) {
        seed = 12345u + (uint32_t)k * 7919u;
        draw = k;
        for (size_t i = 0; i < sizeof cases / sizeof cases[0]; i++) {
            case_no = (int)i;
            if (trace_case >= 0 && (int)i != trace_case) continue;
            bad += !run(&cases[i]);
        }
    }
    if (seeds > 1) printf("%d cases x %d draws of the random events\n", (int)(sizeof cases / sizeof cases[0]), seeds);
    printf(bad ? "%d FAILED\n" : "ALL OK\n", bad);
    return bad ? 1 : 0;
}
