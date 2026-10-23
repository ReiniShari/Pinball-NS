/*
 * gbc_apu.c - Audio processing unit (4 channels, frame sequencer, mixer).
 *
 * The APU is run lazily: it catches up to the CPU clock whenever one of its
 * registers is accessed and at the end of each video frame. Output samples are
 * box-filtered over their period (so fast register writes such as the game's
 * 1-bit PCM voice clips are reproduced) and go through the CGB high-pass filter.
 */
#include "gbc.h"
#include <string.h>
#include <math.h>

/* The samples are the same on every machine: no fused multiply-add (clang makes one of
 * "acc += l * dt" on ARM64 otherwise; x86-64 without AVX2 has none). */
#ifdef __clang__
#pragma STDC FP_CONTRACT OFF
#endif
#if defined(_M_X64) || defined(__x86_64__) || defined(__SSE2__)
#include <emmintrin.h>
#define APU_SSE2 1
#elif defined(__aarch64__) || defined(_M_ARM64)
#include <arm_neon.h>
#define APU_NEON 1
#endif


static const uint8_t DUTY[4][8] = {
    { 0, 0, 0, 0, 0, 0, 0, 1 },
    { 1, 0, 0, 0, 0, 0, 0, 1 },
    { 1, 0, 0, 0, 0, 1, 1, 1 },
    { 0, 1, 1, 1, 1, 1, 1, 0 },
};
static const int NOISE_DIV[8] = { 8, 16, 32, 48, 64, 80, 96, 112 };
static const uint8_t READ_MASK[0x20] = {
    0x80, 0x3F, 0x00, 0xFF, 0xBF,   /* NR10-NR14 */
    0xFF, 0x3F, 0x00, 0xFF, 0xBF,   /* --, NR21-NR24 */
    0x7F, 0xFF, 0x9F, 0xFF, 0xBF,   /* NR30-NR34 */
    0xFF, 0xFF, 0x00, 0x00, 0xBF,   /* --, NR41-NR44 */
    0x00, 0x00, 0x70,               /* NR50-NR52 */
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
};

#define BIG 0x7FFFFFFF

#ifdef PB_STATS
/* counters for the design of the optimisations (pbrun built with -DPB_STATS) */
unsigned long long gbc_stat_apu_runs, gbc_stat_apu_iter, gbc_stat_apu_emit, gbc_stat_apu_ev[6];
#define ASTAT(x) (x)
#else
#define ASTAT(x) ((void)0)
#endif

static inline double dac(bool on, int digital) { return on ? (digital / 7.5 - 1.0) : 0.0; }

/* the output of a DAC for its 16 digital levels, computed once (the same values as dac) */
static double DAC[16];
static bool dac_ready;
static inline double dac_t(bool on, int digital) { return on ? DAC[digital] : 0.0; }

static inline int sq_period(const GBCSquare *c) { return (2048 - c->period) * 4; }
static inline int wave_period(const GBCWave *c) { return (2048 - c->period) * 2; }
static inline int noise_period(const GBCNoise *c) { return c->shift >= 14 ? BIG : (NOISE_DIV[c->div] << c->shift); }

void gbc_apu_init(GBC *g, uint32_t sample_rate)
{
    GBCApu *a = &g->s.apu;
    memset(a, 0, sizeof(*a));
    if (!sample_rate) sample_rate = 48000;
    if (!dac_ready) { for (int i = 0; i < 16; i++) DAC[i] = dac(true, i); dac_ready = true; }
    a->sample_rate = sample_rate;
    a->cyc_per_sample = (double)GBC_CLOCK / sample_rate;
    a->hp_factor = pow(0.998943, (double)GBC_CLOCK / sample_rate);    /* GBC_HIGHPASS_CGB */
    a->power = true;
    a->fs_timer = 8192;
    a->regs[0x14] = 0x77;   /* NR50 */
    a->regs[0x15] = 0xF3;   /* NR51 */
    a->ch1.timer = a->ch2.timer = a->ch3.timer = a->ch4.timer = BIG;
    a->last = g->s.cycles;
}

/* A sample out of the box filter: the high-pass filter, 16 bits, into the ring. Both channels
 * at once in a vector register where there is one: the same operations on each, the same bits,
 * rounded to the nearest integer, ties to even (cvtpd2dq, fcvtns: lrint in the default mode,
 * without the call of the C library, which saved and restored the floating point environment).
 * (|l|, |r| <= 32 and the filter averages them: the scaled values stay far within 32 bits, so
 * their conversion never overflows and saturating to 16 bits is the clamp.) */
static void emit(GBCApu *a, double al, double ar)
{
#if APU_SSE2
    __m128d lr = _mm_div_pd(_mm_set_pd(ar, al), _mm_set1_pd(a->cyc_per_sample));   /* the box filter's mean */
    __m128d ol = _mm_sub_pd(lr, _mm_loadu_pd(&a->hp_l));
    _mm_storeu_pd(&a->hp_l, _mm_sub_pd(lr, _mm_mul_pd(ol, _mm_set1_pd(a->hp_factor))));
    __m128i v = _mm_cvtpd_epi32(_mm_mul_pd(_mm_mul_pd(ol, _mm_set1_pd(32767.0 / 32.0)), _mm_set1_pd(0.9)));
    int32_t lr16 = _mm_cvtsi128_si32(_mm_packs_epi32(v, v));      /* left, right: 16 bits each */
    if (a->ring_w - a->ring_r >= GBC_AUDIO_RING) a->ring_r++;
    memcpy(a->ring[a->ring_w % GBC_AUDIO_RING], &lr16, 4);
    a->ring_w++;
#elif APU_NEON
    float64x2_t acc = { al, ar }, lr = vdivq_f64(acc, vdupq_n_f64(a->cyc_per_sample));   /* the box filter's mean */
    float64x2_t ol = vsubq_f64(lr, vld1q_f64(&a->hp_l));
    vst1q_f64(&a->hp_l, vsubq_f64(lr, vmulq_f64(ol, vdupq_n_f64(a->hp_factor))));
    int32x2_t v = vmovn_s64(vcvtnq_s64_f64(vmulq_f64(vmulq_f64(ol, vdupq_n_f64(32767.0 / 32.0)), vdupq_n_f64(0.9))));
    int16x4_t v16 = vqmovn_s32(vcombine_s32(v, v));
    if (a->ring_w - a->ring_r >= GBC_AUDIO_RING) a->ring_r++;
    vst1_lane_s32((int32_t *)(void *)a->ring[a->ring_w % GBC_AUDIO_RING], vreinterpret_s32_s16(v16), 0);
    a->ring_w++;
#else
    double l = al / a->cyc_per_sample, r = ar / a->cyc_per_sample;
    double ol = l - a->hp_l, orr = r - a->hp_r;
    a->hp_l = l - ol * a->hp_factor;
    a->hp_r = r - orr * a->hp_factor;
    /* full scale: 4 channels x 8 volume steps = 32 */
    int sl = (int)lrint(ol * (32767.0 / 32.0) * 0.9);
    int sr = (int)lrint(orr * (32767.0 / 32.0) * 0.9);
    if (sl > 32767) sl = 32767;
    if (sl < -32768) sl = -32768;
    if (sr > 32767) sr = 32767;
    if (sr < -32768) sr = -32768;
    if (a->ring_w - a->ring_r >= GBC_AUDIO_RING) a->ring_r++;
    a->ring[a->ring_w % GBC_AUDIO_RING][0] = (int16_t)sl;
    a->ring[a->ring_w % GBC_AUDIO_RING][1] = (int16_t)sr;
    a->ring_w++;
#endif
}

static void accumulate(GBCApu *a, double l, double r, double dt)
{
    while (a->sample_pos + dt >= a->cyc_per_sample) {
        double part = a->cyc_per_sample - a->sample_pos;
        a->acc_l += l * part;
        a->acc_r += r * part;
        ASTAT(gbc_stat_apu_emit++);
        emit(a, a->acc_l, a->acc_r);
        a->acc_l = a->acc_r = 0;
        dt -= part;
        a->sample_pos = 0;
    }
    a->acc_l += l * dt;
    a->acc_r += r * dt;
    a->sample_pos += dt;
}


static void mix(const GBCApu *a, double *l, double *r)
{
    double out[4];
    out[0] = dac_t(a->ch1.dac, a->ch1.on ? (DUTY[a->ch1.duty][a->ch1.duty_pos] ? a->ch1.vol : 0) : 0);
    out[1] = dac_t(a->ch2.dac, a->ch2.on ? (DUTY[a->ch2.duty][a->ch2.duty_pos] ? a->ch2.vol : 0) : 0);
    out[2] = dac_t(a->ch3.dac, (a->ch3.on && a->ch3.level) ? (a->ch3.sample >> (a->ch3.level - 1)) : 0);
    out[3] = dac_t(a->ch4.dac, a->ch4.on ? ((a->ch4.lfsr & 1) ? 0 : a->ch4.vol) : 0);
    uint8_t nr51 = a->regs[0x15], nr50 = a->regs[0x14];
    double sl = 0, sr = 0;
    /* without branches: a channel not sent to a side adds +0.0 there, which changes nothing (the
     * sums are never -0.0: the outputs are not, and x + -x is +0.0) */
    for (int i = 0; i < 4; i++) {
        uint64_t o, ml = 0 - (uint64_t)((nr51 >> (4 + i)) & 1), mr = 0 - (uint64_t)((nr51 >> i) & 1);
        double vl, vr;
        memcpy(&o, &out[i], 8);
        o &= ml; memcpy(&vl, &o, 8);
        memcpy(&o, &out[i], 8);
        o &= mr; memcpy(&vr, &o, 8);
        sl += vl;
        sr += vr;
    }
    *l = sl * (((nr50 >> 4) & 7) + 1);
    *r = sr * ((nr50 & 7) + 1);
}

static int sweep_calc(GBCApu *a)
{
    GBCSquare *c = &a->ch1;
    int d = c->sw_shadow >> c->sw_step;
    int nf;
    if (c->sw_dir) { nf = c->sw_shadow - d; c->sw_neg_used = true; }
    else nf = c->sw_shadow + d;
    if (nf > 2047) c->on = false;
    return nf;
}

static void clock_length(GBCApu *a)
{
    if (a->ch1.len_en && a->ch1.len > 0 && --a->ch1.len == 0) a->ch1.on = false;
    if (a->ch2.len_en && a->ch2.len > 0 && --a->ch2.len == 0) a->ch2.on = false;
    if (a->ch3.len_en && a->ch3.len > 0 && --a->ch3.len == 0) a->ch3.on = false;
    if (a->ch4.len_en && a->ch4.len > 0 && --a->ch4.len == 0) a->ch4.on = false;
}

static void env_step(int *vol, int dir, int pace, int *timer)
{
    if (!pace) return;
    if (--*timer <= 0) {
        *timer = pace;
        if (dir && *vol < 15) (*vol)++;
        else if (!dir && *vol > 0) (*vol)--;
    }
}

static void clock_sweep(GBCApu *a)
{
    GBCSquare *c = &a->ch1;
    if (--c->sw_timer <= 0) {
        c->sw_timer = c->sw_pace ? c->sw_pace : 8;
        if (c->sw_en && c->sw_pace) {
            int nf = sweep_calc(a);
            if (nf <= 2047 && c->sw_step) {
                c->sw_shadow = nf;
                c->period = nf;
                a->regs[0x03] = (uint8_t)nf;
                a->regs[0x04] = (uint8_t)((a->regs[0x04] & 0xF8) | ((nf >> 8) & 7));
                sweep_calc(a);
            }
        }
    }
}

static void frame_seq(GBCApu *a)
{
    switch (a->fs_step) {
    case 0: case 4: clock_length(a); break;
    case 2: case 6: clock_length(a); clock_sweep(a); break;
    case 7:
        env_step(&a->ch1.vol, a->ch1.env_dir, a->ch1.env_pace, &a->ch1.env_timer);
        env_step(&a->ch2.vol, a->ch2.env_dir, a->ch2.env_pace, &a->ch2.env_timer);
        env_step(&a->ch4.vol, a->ch4.env_dir, a->ch4.env_pace, &a->ch4.env_timer);
        break;
    default: break;
    }
    a->fs_step = (a->fs_step + 1) & 7;
}

static inline void wave_fetch(GBCApu *a)
{
    uint8_t b = a->regs[0x20 + (a->ch3.pos >> 1)];
    a->ch3.sample = (a->ch3.pos & 1) ? (b & 0x0F) : (b >> 4);
}

/* The noise channel at a high frequency has thousands of events per frame (in this game most of
 * the intervals of gbc_apu_run), between which nothing else happens: they are run here in a
 * tight loop, with the same intervals and the same operations on the samples as gbc_apu_run,
 * in the same order (the same bits). The timers of the other channels and of the frame
 * sequencer, which stay above 0 meanwhile, are counted down once at the end. */
static void noise_run(GBCApu *a, uint64_t now)
{
    GBCNoise *c = &a->ch4;
    int64_t m = (int64_t)(now - a->last);        /* the next event of everything else */
    if (a->fs_timer < m) m = a->fs_timer;
    if (a->ch1.on && a->ch1.timer < m) m = a->ch1.timer;
    if (a->ch2.on && a->ch2.timer < m) m = a->ch2.timer;
    if (a->ch3.on && a->ch3.timer < m) m = a->ch3.timer;
    int t = c->timer, period = noise_period(c);
    if (t < 1 || t > (1 << 20) || t >= m || period > (1 << 20)) return;

    /* the output with the noise's two levels: all the other inputs of mix stay the same */
    double out[2][2];                            /* [lfsr & 1][left, right] (no branch: the noise is random) */
    uint16_t lfsr = c->lfsr;
    c->lfsr = (uint16_t)(lfsr & ~1); mix(a, &out[0][0], &out[0][1]);
    c->lfsr = (uint16_t)(lfsr | 1);  mix(a, &out[1][0], &out[1][1]);
    c->lfsr = lfsr;

    double sp = a->sample_pos, al = a->acc_l, ar = a->acc_r;
    const double cps = a->cyc_per_sample, dp = (double)period;
    /* after the first interval, every interval is one period: its products, computed once,
     * are the ones accumulate computes */
    const double prod[2][2] = { { out[0][0] * dp, out[0][1] * dp }, { out[1][0] * dp, out[1][1] * dp } };
    int64_t used = 0;
    const uint16_t w7 = c->width7 ? 0x40 : 0;   /* 7-bit mode: bit 6 too */
    /* The next outputs of the noise (bit 0) are the bits of the register as it is: they only
     * move down, a new bit reaches bit 0 after 15 steps (7 in the 7-bit mode). Taken from there,
     * the outputs do not wait for the register's own steps. */
    const int run = c->width7 ? 7 : 15;
    uint32_t bits = 0;
    int left = 0;
    do {
        if (!left) { bits = lfsr; left = run; }
        int sel = bits & 1;
        bits >>= 1;
        left--;
        double dt = (double)t, spn = sp + dt;
        ASTAT(gbc_stat_apu_iter++);
        ASTAT(gbc_stat_apu_ev[4]++);
        if (spn < cps && t == period) {          /* accumulate, no sample ends */
            al += prod[sel][0];
            ar += prod[sel][1];
            sp = spn;
        } else {
            double l = out[sel][0], r = out[sel][1];
            while (sp + dt >= cps) {             /* accumulate */
                double part = cps - sp;
                al += l * part;
                ar += r * part;
                ASTAT(gbc_stat_apu_emit++);
                emit(a, al, ar);
                al = ar = 0;
                dt -= part;
                sp = 0;
            }
            al += l * dt;
            ar += r * dt;
            sp += dt;
        }
        used += t;
        uint16_t fb = (uint16_t)((lfsr ^ (lfsr >> 1)) & 1);   /* the event */
        lfsr = (uint16_t)((lfsr >> 1) | (fb << 14));
        lfsr = (uint16_t)((lfsr & ~w7) | ((fb << 6) & w7));
        t = period;                              /* timer - dt = 0, + period */
    } while (t < m - used);
    a->sample_pos = sp;
    a->acc_l = al;
    a->acc_r = ar;
    c->lfsr = lfsr;
    c->timer = t;
    a->last += (uint64_t)used;
    a->fs_timer -= (int32_t)used;
    if (a->ch1.on) a->ch1.timer -= (int)used;
    if (a->ch2.on) a->ch2.timer -= (int)used;
    if (a->ch3.on) a->ch3.timer -= (int)used;
}

void gbc_apu_run(GBC *g)
{
    GBCApu *a = &g->s.apu;
    uint64_t now = g->s.cycles;
    ASTAT(gbc_stat_apu_runs++);
    while (a->last < now) {
        if (a->power && a->ch4.on) {
            noise_run(a, now);
            if (a->last >= now) break;
        }
        int64_t dt = (int64_t)(now - a->last);
        ASTAT(gbc_stat_apu_iter++);
        if (dt > 1 << 20) dt = 1 << 20;
        if (a->power) {
            if (a->fs_timer < dt) dt = a->fs_timer;
            if (a->ch1.on && a->ch1.timer < dt) dt = a->ch1.timer;
            if (a->ch2.on && a->ch2.timer < dt) dt = a->ch2.timer;
            if (a->ch3.on && a->ch3.timer < dt) dt = a->ch3.timer;
            if (a->ch4.on && a->ch4.timer < dt) dt = a->ch4.timer;
        }
        if (dt < 1) dt = 1;
        double l, r;
        if (a->power) mix(a, &l, &r); else l = r = 0;
        accumulate(a, l, r, (double)dt);
        a->last += (uint64_t)dt;
        if (!a->power) continue;
        a->fs_timer -= (int32_t)dt;
        ASTAT(a->last == now ? gbc_stat_apu_ev[5]++ : 0);
        if (a->fs_timer <= 0) { ASTAT(gbc_stat_apu_ev[0]++); a->fs_timer += 8192; frame_seq(a); }
        if (a->ch1.on && (a->ch1.timer -= (int)dt) <= 0) { ASTAT(gbc_stat_apu_ev[1]++); a->ch1.timer += sq_period(&a->ch1); a->ch1.duty_pos = (a->ch1.duty_pos + 1) & 7; }
        if (a->ch2.on && (a->ch2.timer -= (int)dt) <= 0) { ASTAT(gbc_stat_apu_ev[2]++); a->ch2.timer += sq_period(&a->ch2); a->ch2.duty_pos = (a->ch2.duty_pos + 1) & 7; }
        if (a->ch3.on && (a->ch3.timer -= (int)dt) <= 0) { ASTAT(gbc_stat_apu_ev[3]++);
            a->ch3.timer += wave_period(&a->ch3);
            a->ch3.pos = (a->ch3.pos + 1) & 31;
            wave_fetch(a);
        }
        if (a->ch4.on && (a->ch4.timer -= (int)dt) <= 0) { ASTAT(gbc_stat_apu_ev[4]++);
            a->ch4.timer += noise_period(&a->ch4);
            uint16_t fb = (uint16_t)((a->ch4.lfsr ^ (a->ch4.lfsr >> 1)) & 1);
            a->ch4.lfsr = (uint16_t)((a->ch4.lfsr >> 1) | (fb << 14));
            if (a->ch4.width7) a->ch4.lfsr = (uint16_t)((a->ch4.lfsr & ~0x40) | (fb << 6));
        }
    }
}

void gbc_apu_end_frame(GBC *g) { gbc_apu_run(g); }

uint8_t gbc_apu_read(GBC *g, uint16_t addr)
{
    GBCApu *a = &g->s.apu;
    int r = addr - 0xFF10;
    gbc_apu_run(g);
    if (r >= 0x20) {
        if (a->ch3.on) return a->regs[0x20 + (a->ch3.pos >> 1)];
        return a->regs[r];
    }
    if (r == 0x16) {
        return (uint8_t)((a->power ? 0x80 : 0) | 0x70 | (a->ch4.on ? 8 : 0) | (a->ch3.on ? 4 : 0) |
                         (a->ch2.on ? 2 : 0) | (a->ch1.on ? 1 : 0));
    }
    return a->regs[r] | READ_MASK[r];
}

static void length_enable(GBCApu *a, bool *len_en, int *len, bool *on, uint8_t v, int max)
{
    bool was = *len_en;
    *len_en = (v & 0x40) != 0;
    /* extra length clock when enabling length in the first half of a length period */
    if (!was && *len_en && (a->fs_step & 1) && *len > 0) {
        if (--*len == 0 && !(v & 0x80)) *on = false;
    }
    if ((v & 0x80) && *len == 0) {
        *len = max;
        if (*len_en && (a->fs_step & 1)) *len = max - 1;
    }
}

void gbc_apu_write(GBC *g, uint16_t addr, uint8_t v)
{
    GBCApu *a = &g->s.apu;
    int r = addr - 0xFF10;
    gbc_apu_run(g);
    if (r >= 0x20) {                      /* wave RAM */
        if (a->ch3.on) a->regs[0x20 + (a->ch3.pos >> 1)] = v;
        else a->regs[r] = v;
        return;
    }
    if (r == 0x16) {                      /* NR52 */
        bool on = (v & 0x80) != 0;
        if (a->power && !on) {
            uint8_t wave[16];
            memcpy(wave, &a->regs[0x20], 16);
            memset(a->regs, 0, 0x20);
            memcpy(&a->regs[0x20], wave, 16);
            memset(&a->ch1, 0, sizeof a->ch1);
            memset(&a->ch2, 0, sizeof a->ch2);
            memset(&a->ch3, 0, sizeof a->ch3);
            memset(&a->ch4, 0, sizeof a->ch4);
            a->ch1.timer = a->ch2.timer = a->ch3.timer = a->ch4.timer = BIG;
        } else if (!a->power && on) {
            a->fs_step = 0;
            a->fs_timer = 8192;
            a->ch1.duty_pos = a->ch2.duty_pos = 0;
            a->ch3.sample = 0;
        }
        a->power = on;
        return;
    }
    if (!a->power) return;
    a->regs[r] = v;
    switch (r) {
    case 0x00:                            /* NR10 */
        a->ch1.sw_pace = (v >> 4) & 7;
        a->ch1.sw_dir = (v >> 3) & 1;
        a->ch1.sw_step = v & 7;
        if (!a->ch1.sw_dir && a->ch1.sw_neg_used) a->ch1.on = false;
        break;
    case 0x01: a->ch1.duty = v >> 6; a->ch1.len = 64 - (v & 63); break;
    case 0x02:
        a->ch1.env_init = v >> 4; a->ch1.env_dir = (v >> 3) & 1; a->ch1.env_pace = v & 7;
        a->ch1.dac = (v & 0xF8) != 0; if (!a->ch1.dac) a->ch1.on = false;
        break;
    case 0x03: a->ch1.period = (a->ch1.period & 0x700) | v; break;
    case 0x04: {
        GBCSquare *c = &a->ch1;
        c->period = (c->period & 0xFF) | ((v & 7) << 8);
        length_enable(a, &c->len_en, &c->len, &c->on, v, 64);
        if (v & 0x80) {
            c->on = c->dac;
            c->timer = sq_period(c);
            c->vol = c->env_init; c->env_timer = c->env_pace;
            c->sw_shadow = c->period;
            c->sw_timer = c->sw_pace ? c->sw_pace : 8;
            c->sw_en = c->sw_pace || c->sw_step;
            c->sw_neg_used = false;
            if (c->sw_step) sweep_calc(a);
        }
        break;
    }
    case 0x06: a->ch2.duty = v >> 6; a->ch2.len = 64 - (v & 63); break;
    case 0x07:
        a->ch2.env_init = v >> 4; a->ch2.env_dir = (v >> 3) & 1; a->ch2.env_pace = v & 7;
        a->ch2.dac = (v & 0xF8) != 0; if (!a->ch2.dac) a->ch2.on = false;
        break;
    case 0x08: a->ch2.period = (a->ch2.period & 0x700) | v; break;
    case 0x09: {
        GBCSquare *c = &a->ch2;
        c->period = (c->period & 0xFF) | ((v & 7) << 8);
        length_enable(a, &c->len_en, &c->len, &c->on, v, 64);
        if (v & 0x80) {
            c->on = c->dac;
            c->timer = sq_period(c);
            c->vol = c->env_init; c->env_timer = c->env_pace;
        }
        break;
    }
    case 0x0A: a->ch3.dac = (v & 0x80) != 0; if (!a->ch3.dac) a->ch3.on = false; break;
    case 0x0B: a->ch3.len = 256 - v; break;
    case 0x0C: a->ch3.level = (v >> 5) & 3; break;
    case 0x0D: a->ch3.period = (a->ch3.period & 0x700) | v; break;
    case 0x0E: {
        GBCWave *c = &a->ch3;
        c->period = (c->period & 0xFF) | ((v & 7) << 8);
        length_enable(a, &c->len_en, &c->len, &c->on, v, 256);
        if (v & 0x80) {
            c->on = c->dac;
            c->timer = wave_period(c) + 6;
            c->pos = 0;
        }
        break;
    }
    case 0x10: a->ch4.len = 64 - (v & 63); break;
    case 0x11:
        a->ch4.env_init = v >> 4; a->ch4.env_dir = (v >> 3) & 1; a->ch4.env_pace = v & 7;
        a->ch4.dac = (v & 0xF8) != 0; if (!a->ch4.dac) a->ch4.on = false;
        break;
    case 0x12: a->ch4.shift = v >> 4; a->ch4.width7 = (v & 8) != 0; a->ch4.div = v & 7; break;
    case 0x13: {
        GBCNoise *c = &a->ch4;
        length_enable(a, &c->len_en, &c->len, &c->on, v, 64);
        if (v & 0x80) {
            c->on = c->dac;
            c->timer = noise_period(c);
            c->vol = c->env_init; c->env_timer = c->env_pace;
            c->lfsr = 0x7FFF;
        }
        break;
    }
    default: break;
    }
}

void gbc_set_audio_rate(GBC *g, double sample_rate)
{
    GBCApu *a = &g->s.apu;
    if (sample_rate < 8000 || sample_rate > 192000) return;
    a->cyc_per_sample = (double)GBC_CLOCK / sample_rate;
    if (a->sample_pos > a->cyc_per_sample) a->sample_pos = a->cyc_per_sample;   /* the sample ends now */
}

void gbc_set_audio_highpass(GBC *g, double hz)
{
    GBCApu *a = &g->s.apu;
    if (hz <= 0 || !a->sample_rate) return;
    a->hp_factor = exp(-2 * 3.14159265358979 * hz / a->sample_rate);   /* per sample */
}

int gbc_audio_available(GBC *g)
{
    return (int)(g->s.apu.ring_w - g->s.apu.ring_r);
}

int gbc_audio_read(GBC *g, int16_t *out, int max_frames)
{
    GBCApu *a = &g->s.apu;
    int n = 0;
    while (n < max_frames && a->ring_r != a->ring_w) {
        out[n * 2] = a->ring[a->ring_r % GBC_AUDIO_RING][0];
        out[n * 2 + 1] = a->ring[a->ring_r % GBC_AUDIO_RING][1];
        a->ring_r++;
        n++;
    }
    return n;
}
