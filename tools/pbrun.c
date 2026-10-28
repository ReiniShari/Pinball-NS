/*
 * pbrun.c - headless runner for the unified-field game (tests, screenshots, bots).
 *
 *   pbrun ROM [-load snap] [-save snap] [-shot prefix] cmd...
 *   cmds: w:N  p:BTN:N  h:BTN  r:BTN  s:NAME  R:N:SEED (random flipper play)
 *         B:N:SEED (bot: navigates menus and plays, whole game flow)
 *   -hash: a fingerprint of every frame (picture and sound), printed at the end: the same run
 *          gives the same value, so an optimisation must leave it unchanged
 *   -hashlog FILE: the fingerprints of the picture and of the sound of each frame, one line per
 *          frame (the first frame where two engines differ, and in what)
 *   -prof: (Windows, built with symbols) samples where the time goes: functions, source lines
 *   -fx F:C:K: the screenshots through the screen filter F (0 none, 1 dots, 2 LCD) and the colours C
 *          (0 original, 1 black and white, 2 Game Boy green) of the Windows version, cells of K x K
 *   -table T: the bot plays the table T (PB_TABLE_*: 0 Red, 1 Blue; Generations: 2 Gold, 3 Silver, 4 Ruby,
 *          5 Sapphire), chosen on the field select screen
 *   -ds: the double speed of Generations on the original ROM (pb_set_double_speed, as the front-ends)
 *   -pcm: Pikachu's voice (the sample player of bank $14): the wave channel when it starts, its length
 *   -linecheck: rows of a picture (1 or 2) that differ from the pictures before and after while
 *          these two are the same and the rows around stay put (a line drawn late, or early);
 *          the first ones saved as PREFIX_line_FRAME_{a,b,c}.png
 *   -antilag, -hold: as the front-ends run the game (pb_set_antilag, pb_set_hold: the fingerprint
 *          is then that of the pictures shown); -frametime: the time of each frame, by kind
 */
#include "../src/game/pinball.h"
#include "engine.h"
#include "png_write.h"
#include "../src/front/deflicker.h"
#include "../src/front/screenfx.h"
#include <stdio.h>
#include <stdlib.h>
#include "botrand.h"
#include <string.h>
#include <time.h>
#ifdef _WIN32
#include <windows.h>
#endif

static Pinball pb;
#define PBR (pb.rom)
static uint8_t rom[4 << 20];
static bool hashing;
static int fx_f = -1, fx_c, fx_k = 4;       /* -fx */
static ScreenFx fx;
static int table_wanted = -1;             /* -table */
static uint64_t run_hash = 1469598103934665603ull;

static FILE *hashlog, *audiodump;
static bool ratewobble;                   /* -ratewobble: the sound's rate changed at every frame, as the front-ends do */

static uint64_t fnv(uint64_t h, const void *d, size_t n)
{
    const uint8_t *p = (const uint8_t *)d;
    for (size_t i = 0; i < n; i++) { h ^= p[i]; h *= 1099511628211ull; }
    return h;
}
static void hash_bytes(const void *d, size_t n) { run_hash = fnv(run_hash, d, n); }
static uint8_t held;
static long frames;
static const char *prefix = "pb";

static int btn(const char *n)
{
    if (!strcmp(n, "a")) return GBC_A;
    if (!strcmp(n, "b")) return GBC_B;
    if (!strcmp(n, "sel")) return GBC_SELECT;
    if (!strcmp(n, "start")) return GBC_START;
    if (!strcmp(n, "right")) return GBC_RIGHT;
    if (!strcmp(n, "left")) return GBC_LEFT;
    if (!strcmp(n, "up")) return GBC_UP;
    if (!strcmp(n, "down")) return GBC_DOWN;
    fprintf(stderr, "bad button %s\n", n); exit(2);
}

static uint8_t rd(uint16_t a) { return gbc_read(&pb.g, a); }

/* -check: report wild jumps and resets, count time per stage */
static long wild, resets, stage_frames[32], screen_frames[16];
static void check_trace(GBC *g, void *u)
{
    (void)u;
    uint16_t pc = g->s.pc;
    if (pc >= 0x8000 && pc < 0xFF80) {
        if (wild++ < 5) fprintf(stderr, "frame %ld: wild PC %02X:%04X sp=%04X frozen=%d\n", frames, (int)g->s.rom_bank, pc, g->s.sp, g->frozen);
    }
    if (pc == 0x0100) { resets++; fprintf(stderr, "frame %ld: reset (screen %d)\n", frames, rd(W_CurrentScreen)); }
}

/* -lag: where the CPU was when each VBlank interrupt came (the return address it pushed). The
 * game waits for the next frame in a loop; a VBlank that comes anywhere else means its work of
 * the frame was not done: that frame of the game is late (a "lag frame"). */
static bool lagstat;
typedef struct { uint16_t pc; uint8_t bank; long n; } LagPc;
static LagPc lag_pc[512];
static int lag_npc;
static long lag_vblanks, lag_field, lag_field_late, lag_late_run, lag_late_max, lag_late_runs[8];
static bool hk_vblank(GBC *g, void *u)
{
    (void)u;
    if (g->frozen) return false;
    uint16_t sp = g->s.sp;
    uint16_t pc = (uint16_t)(gbc_read(g, sp) | gbc_read(g, (uint16_t)(sp + 1)) << 8);
    uint8_t bank = pc >= 0x4000 && pc < 0x8000 ? (uint8_t)g->s.rom_bank : 0;
    lag_vblanks++;
    /* on a table, playing: late unless in the wait for the next frame (0472-0474) */
    uint8_t st = rd(W_CurrentStage);
    if (rd(W_CurrentScreen) == SCREEN_PINBALL_GAME && pb_stage_table(&pb, st) >= 0) {
        lag_field++;
        bool late = !(bank == 0 && pc >= R_WaitFrameLoop && pc <= R_WaitFrameLoop + 2) && !g->s.halted;
        if (late) {
            lag_field_late++;
            lag_late_run++;
            int i = 0;                                   /* where: the late ones on the tables */
            while (i < lag_npc && (lag_pc[i].pc != pc || lag_pc[i].bank != bank)) i++;
            if (i == lag_npc && lag_npc < 512) { lag_pc[i].pc = pc; lag_pc[i].bank = bank; lag_pc[i].n = 0; lag_npc++; }
            if (i < 512) lag_pc[i].n++;
        }
        else if (lag_late_run) {
            if (lag_late_run > lag_late_max) lag_late_max = lag_late_run;
            lag_late_runs[lag_late_run < 7 ? lag_late_run : 7]++;
            lag_late_run = 0;
        }
    }
    return false;
}
static long wait_sp_n[0x100];          /* stack pointer at the entry of the wait (0468), high byte FF.. */
static uint16_t wait_sps[16];
static long wait_spc[16];
static int wait_nsp;
static bool hk_wait_entry(GBC *g, void *u)
{
    (void)u;
    if (g->frozen) return false;
    int i = 0;
    while (i < wait_nsp && wait_sps[i] != g->s.sp) i++;
    if (i == wait_nsp && wait_nsp < 16) { wait_sps[i] = g->s.sp; wait_spc[i] = 0; wait_nsp++; }
    if (i < 16) wait_spc[i]++;
    return false;
}
static int lag_cmp(const void *a, const void *b)
{
    long x = ((const LagPc *)a)->n, y = ((const LagPc *)b)->n;
    return x < y ? 1 : x > y ? -1 : 0;
}
static void lag_report(void)
{
    qsort(lag_pc, (size_t)lag_npc, sizeof lag_pc[0], lag_cmp);
    fprintf(stderr, "lag: on the tables %ld VBlanks, %ld late (%.2f %%); late VBlanks in a row: 1 x%ld, 2 x%ld, 3 x%ld, "
            "4+ x%ld (longest %ld)\n", lag_field, lag_field_late, 100.0 * lag_field_late / (lag_field ? lag_field : 1),
            lag_late_runs[1], lag_late_runs[2], lag_late_runs[3], lag_late_runs[4] + lag_late_runs[5] + lag_late_runs[6] + lag_late_runs[7],
            lag_late_max);
    if (pb.antilag) fprintf(stderr, "antilag: %ld frames late at their end, %ld finished out of time; routines of hooks frozen at the "
                            "end of the frame: %ld\n", pb.stats_late, pb.stats_late_done, pb.g.call_late);
    for (int i = 0; i < wait_nsp; i++) fprintf(stderr, "wait for the frame (0468) with SP %04X: %ld times\n", wait_sps[i], wait_spc[i]);
    fprintf(stderr, "lag: the late ones on the tables were at (the most frequent first; of %ld VBlanks in all):\n", lag_vblanks);
    for (int i = 0; i < lag_npc && i < 25; i++)
        fprintf(stderr, "  %02X:%04X %7ld (%.2f %%)\n", lag_pc[i].bank, lag_pc[i].pc, lag_pc[i].n, 100.0 * lag_pc[i].n / lag_vblanks);
}

/* -sfx: the sound effects (04AF, DE = the effect) and songs (0490, E) the game asks for, in its
 * normal run and in the out-of-time runs of the half without the ball (whose requests are lost:
 * the memory of the sound engine is not merged) */
/* -pcm: Pikachu's voice (the sample player of bank $14): the state of the wave channel when it
 * starts, and how long it took */
static uint64_t pcm_t0;
static bool hk_pcm_log(GBC *g, void *u)
{
    const GBCApu *a = &g->s.apu;
    if (u == (void *)1) pcm_t0 = gbc_sound_time(&g->s);
    fprintf(stderr, "frame %ld: sample player %s (%.3f s): NR50 %02X NR51 %02X power %d ch3 on %d dac %d level %d sample %d "
            "frozen %d double speed %d\n", frames, u == (void *)1 ? "starts" : "returns",
            u == (void *)1 ? 0.0 : (double)(gbc_sound_time(&g->s) - pcm_t0) / GBC_CLOCK,
            a->regs[0x14], a->regs[0x15], a->power, a->ch3.on, a->ch3.dac, a->ch3.level, a->ch3.sample, g->frozen, g->s.ds);
    return false;
}

static bool sfxstat;
static long sfx_n[2][2][256];            /* [song?][frozen?][id] */
static long sfx_frame[256][2];            /* last frame each effect was asked for: [running, out of time] */
static long sfx_unique[256];              /* out of time, not asked by the running program within 2 frames */
static bool hk_sfx(GBC *g, void *u)
{
    int song = u != NULL;
    uint8_t id = song ? g->s.e : g->s.d ? g->s.d : g->s.e;
    sfx_n[song][g->frozen ? 1 : 0][id]++;
    if (!song) sfx_frame[id][g->frozen ? 1 : 0] = frames + 1;
    return false;
}
static void sfx_end_frame(void)          /* 2 frames later: was it asked by the running program too? */
{
    for (int i = 0; i < 256; i++)
        if (sfx_frame[i][1] && frames + 1 - sfx_frame[i][1] >= 2) {
            if (!sfx_frame[i][0] || labs(sfx_frame[i][0] - sfx_frame[i][1]) > 2) {
                sfx_unique[i]++;
                if (i) fprintf(stderr, "frame %ld: effect %02X asked out of time only (stage %d, special %d mode %d)\n", frames, i,
                               rd(W_CurrentStage), rd(W_InSpecialMode), rd(W_SpecialMode));
            }
            sfx_frame[i][1] = 0;
        }
}
static void sfx_report(void)
{
    fprintf(stderr, "sound effects of the other half played at the end of the frame: %ld\n", pb.stats_sfx_replayed);
    for (int song = 0; song < 2; song++) {
        long t[2] = { 0, 0 };
        for (int f = 0; f < 2; f++) for (int i = 0; i < 256; i++) t[f] += sfx_n[song][f][i];
        fprintf(stderr, "%s: %ld asked by the running program, %ld by the out-of-time runs\n", song ? "songs (0490)" : "sound effects (04AF)", t[0], t[1]);
        for (int i = 0; i < 256; i++)
            if (sfx_n[song][1][i]) fprintf(stderr, "   out of time: %02X x%ld (running: x%ld), not asked by the running program then: x%ld\n",
                                           i, sfx_n[song][1][i], sfx_n[song][0][i], song ? 0 : sfx_unique[i]);
    }
}

/* -flicker: pixels alternating from a frame to the next (the colour of 2 frames before, not the
 * colour of the previous one): what a screen shows as flicker at 30 Hz. Counted per frame and per
 * 8 x 8 cell of the composed picture; the worst frame is saved with its two predecessors. */
static bool flicker;
static uint32_t *fl_prev[2];
static double fl_total;
static long fl_frames_with, fl_max, fl_max_frame;
static long fl_cell[64][64];
static uint32_t *fl_worst[3];
static int fl_ww, fl_wh;

static bool use_deflicker;                  /* -deflicker: measured on what the front-ends show */
static Deflicker defl;

static void flicker_frame(void)
{
    int w, h, stride;
    const uint32_t *px = pb_frame(&pb, &w, &h, &stride);
    if (use_deflicker) {
        const uint32_t *f = deflicker_frame(&defl, px, w, h, stride);
        if (f) { px = f; stride = w; }
    }
    size_t n = (size_t)w * (size_t)h;
    static int pw, ph, same;                /* the size of the picture changes (menus, table) */
    if (!fl_prev[0]) {
        for (int i = 0; i < 2; i++) fl_prev[i] = (uint32_t *)calloc((size_t)GBC_FB_W * GBC_FB_H, 4);
        for (int i = 0; i < 3; i++) fl_worst[i] = (uint32_t *)calloc((size_t)GBC_FB_W * GBC_FB_H, 4);
    }
    if (w != pw || h != ph) { pw = w; ph = h; same = 0; }
    same++;
    long count = 0;
    static long cell[64][64];
    if (same >= 3) {
        memset(cell, 0, sizeof cell);
        for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++) {
                uint32_t c = px[(size_t)y * stride + x], p1 = fl_prev[0][(size_t)y * w + x], p2 = fl_prev[1][(size_t)y * w + x];
                if (c == p2 && c != p1) { count++; if (y / 8 < 64 && x / 8 < 64) cell[y / 8][x / 8] = 1; }
            }
        /* the cells of the map: not the frames where the whole picture shakes (the tilt) */
        if (count < 4000)
            for (int y = 0; y < 64; y++) for (int x = 0; x < 64; x++) fl_cell[y][x] += cell[y][x];
    }
    fl_total += (double)count;
    if (count) fl_frames_with++;
    if (count > fl_max) {
        fl_max = count;
        fl_max_frame = frames;
        fl_ww = w;
        fl_wh = h;
        memcpy(fl_worst[0], fl_prev[1], n * 4);
        memcpy(fl_worst[1], fl_prev[0], n * 4);
        for (int y = 0; y < h; y++) memcpy(fl_worst[2] + (size_t)y * w, px + (size_t)y * stride, (size_t)w * 4);
    }
    uint32_t *t = fl_prev[1];
    fl_prev[1] = fl_prev[0];
    fl_prev[0] = t;
    for (int y = 0; y < h; y++) memcpy(fl_prev[0] + (size_t)y * w, px + (size_t)y * stride, (size_t)w * 4);
}

/* -linecheck: a band of 1 or 2 rows of picture B different from A (before) and C (after), A and C
 * the same there, and the rows just above and below the same in all three */
static bool linecheck;
static void save_png_rows(const char *name, const uint32_t *p, int w, int h) { png_write_rgb(name, p, w, h, w, 3); }
static uint32_t *lc_pic[2];
static long lc_found, lc_frames, lc_saved, lc_row_hist[GBC_FB_H];

static bool row_same(const uint32_t *a, const uint32_t *b, int w, int y)
{
    return !memcmp(a + (size_t)y * w, b + (size_t)y * w, (size_t)w * 4);
}

static void linecheck_frame(void)
{
    int w, h, stride;
    const uint32_t *px = pb_frame(&pb, &w, &h, &stride);
    static int pw, ph, same;
    if (!lc_pic[0]) for (int i = 0; i < 2; i++) lc_pic[i] = (uint32_t *)calloc((size_t)GBC_FB_W * GBC_FB_H, 4);
    static uint32_t *cur;
    if (!cur) cur = (uint32_t *)calloc((size_t)GBC_FB_W * GBC_FB_H, 4);
    for (int y = 0; y < h; y++) memcpy(cur + (size_t)y * w, px + (size_t)y * stride, (size_t)w * 4);
    if (w != pw || h != ph) { pw = w; ph = h; same = 0; }
    same++;
    const uint32_t *A = lc_pic[1], *B = lc_pic[0], *C = cur;
    if (same >= 3) {
        lc_frames++;
        int y = 1;
        while (y < h - 1) {
            bool t = !row_same(A, B, w, y) && !row_same(B, C, w, y) && row_same(A, C, w, y);
            if (!t) { y++; continue; }
            int y1 = y;
            while (y1 + 1 < h - 1 && !row_same(A, B, w, y1 + 1) && !row_same(B, C, w, y1 + 1) && row_same(A, C, w, y1 + 1)) y1++;
            bool around = row_same(A, B, w, y - 1) && row_same(B, C, w, y - 1) && row_same(A, B, w, y1 + 1) && row_same(B, C, w, y1 + 1);
            if (y1 - y < 2 && around) {
                lc_found++;
                lc_row_hist[y]++;
                if (lc_found <= 20) fprintf(stderr, "frame %ld: rows %d-%d of the picture (%dx%d) shown for one frame only (stage %d)\n",
                                            frames - 1, y, y1, w, h, rd(W_CurrentStage));
                if (lc_saved < 6) {
                    char n[600];
                    snprintf(n, sizeof n, "%s_line_%ld_a.png", prefix, frames - 1); save_png_rows(n, A, w, h);
                    snprintf(n, sizeof n, "%s_line_%ld_b.png", prefix, frames - 1); save_png_rows(n, B, w, h);
                    snprintf(n, sizeof n, "%s_line_%ld_c.png", prefix, frames - 1); save_png_rows(n, C, w, h);
                    lc_saved++;
                }
            }
            y = y1 + 1;
        }
    }
    uint32_t *t = lc_pic[1];
    lc_pic[1] = lc_pic[0];
    lc_pic[0] = t;
    memcpy(lc_pic[0], cur, (size_t)w * h * 4);
}

static void linecheck_report(void)
{
    fprintf(stderr, "linecheck: %ld bands of 1-2 rows shown for one frame only, in %ld frames compared\n", lc_found, lc_frames);
    for (int y = 0; y < GBC_FB_H; y++) if (lc_row_hist[y]) fprintf(stderr, "  row %3d: %ld\n", y, lc_row_hist[y]);
}

/* -frametime: the time of each frame of the emulation (pb_run_frame), the slowest ones */
static bool frametime;
static double ft_sum, ft_max[8];
static long ft_max_frame[8], ft_hist[64];

static bool sramwatch;
static uint8_t sram_last[0x8000];
static long sram_changes;

static double now_ms(void)
{
#ifdef _WIN32
    static LARGE_INTEGER f;
    LARGE_INTEGER c;
    if (!f.QuadPart) QueryPerformanceFrequency(&f);
    QueryPerformanceCounter(&c);
    return (double)c.QuadPart * 1000.0 / (double)f.QuadPart;
#else
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec * 1000.0 + t.tv_nsec / 1e6;
#endif
}

/* -frametime: by what the frame did (the other half redrawn, the ball changing halves, a stage
 * loaded, a late frame finished, nothing of these) */
static double ft_kind_sum[5], ft_kind_max[5];
static long ft_kind_n[5];

static void frame(void)
{
    double t0 = frametime ? now_ms() : 0;
    long refresh0 = pb.st.stats_refresh, swaps0 = pb.st.stats_swaps, late0 = pb.stats_late;
    bool unified0 = pb.st.unified;
    if (ratewobble) pb_set_audio_rate(&pb, 48000.0 * (1.0 + 0.005 * ((rand() % 2001) - 1000) / 1000.0));
    if (table_wanted >= 0 && rd(W_CurrentScreen) == SCREEN_FIELD_SELECT) {
        /* the region (Generations: Kanto, Johto) and the table in it */
        if (W_FieldSelectRegion) gbc_write(&pb.g, W_FieldSelectRegion, (uint8_t)(table_wanted / 2));
        gbc_write(&pb.g, W_SelectedFieldIndex, (uint8_t)(table_wanted & 1));
    }
    pb_run_frame(&pb, held);
    if (sfxstat) sfx_end_frame();
    if (frametime) {
        double dt = now_ms() - t0;
        int kind = pb.st.unified != unified0 ? 2 : pb.st.stats_swaps != swaps0 ? 1 : pb.st.stats_refresh != refresh0 ? 0 :
                   pb.stats_late != late0 ? 3 : 4;
        ft_kind_sum[kind] += dt;
        ft_kind_n[kind]++;
        if (dt > ft_kind_max[kind]) ft_kind_max[kind] = dt;
        ft_sum += dt;
        int b = (int)(dt * 4);                       /* 0.25 ms buckets */
        ft_hist[b < 63 ? b : 63]++;
        for (int i = 0; i < 8; i++)
            if (dt > ft_max[i]) {
                memmove(&ft_max[i + 1], &ft_max[i], sizeof(double) * (size_t)(7 - i));
                memmove(&ft_max_frame[i + 1], &ft_max_frame[i], sizeof(long) * (size_t)(7 - i));
                ft_max[i] = dt;
                ft_max_frame[i] = frames;
                break;
            }
    }
    if (flicker) flicker_frame();
    if (linecheck) linecheck_frame();
    if (sramwatch && frames % 60 == 0) {             /* -sramwrites: the cartridge save changed this second */
        size_t n;
        const uint8_t *d = pb_sram(&pb, &n);
        if (n > sizeof sram_last) n = sizeof sram_last;
        if (frames && memcmp(d, sram_last, n)) { sram_changes++; if (sram_changes <= 20) fprintf(stderr, "frame %ld: cartridge save changed\n", frames); }
        memcpy(sram_last, d, n);
    }
    stage_frames[rd(W_CurrentStage) & 31]++;
    screen_frames[rd(W_CurrentScreen) & 15]++;
    int16_t tmp[4096];
    int n;
    uint64_t fa = 1469598103934665603ull, fv = fa;
    while ((n = pb_audio(&pb, tmp, 2048)) > 0)
        if (hashing) { hash_bytes(tmp, (size_t)n * 4); if (hashlog) fa = fnv(fa, tmp, (size_t)n * 4); if (audiodump) fwrite(tmp, 4, (size_t)n, audiodump); }
    if (hashing) {
        int w, h, stride;
        const uint32_t *px = pb_frame(&pb, &w, &h, &stride);
        for (int y = 0; y < h; y++) {
            hash_bytes(px + (size_t)y * stride, (size_t)w * 4);
            if (hashlog) fv = fnv(fv, px + (size_t)y * stride, (size_t)w * 4);
        }
        if (hashlog) fprintf(hashlog, "%ld %016llx %016llx\n", frames, (unsigned long long)fv, (unsigned long long)fa);
    }
    frames++;
}

#ifdef _WIN32
/* ------------------------------------------------------------------ sampling profiler */
#include <windows.h>
#include <dbghelp.h>
#pragma comment(lib, "dbghelp.lib")
#pragma comment(lib, "winmm.lib")

#define PROF_MAX 200000
static DWORD64 prof_pc[PROF_MAX];
static volatile LONG prof_n, prof_stop;
static HANDLE prof_main;

static DWORD WINAPI prof_thread(LPVOID u)
{
    (void)u;
    timeBeginPeriod(1);
    while (!prof_stop) {
        Sleep(1);
        if (SuspendThread(prof_main) == (DWORD)-1) continue;
        CONTEXT c;
        c.ContextFlags = CONTEXT_CONTROL;
        if (GetThreadContext(prof_main, &c) && prof_n < PROF_MAX) prof_pc[prof_n++] = c.Rip;
        ResumeThread(prof_main);
    }
    return 0;
}

static void prof_start(void)
{
    DuplicateHandle(GetCurrentProcess(), GetCurrentThread(), GetCurrentProcess(), &prof_main, 0, FALSE, DUPLICATE_SAME_ACCESS);
    CreateThread(NULL, 0, prof_thread, NULL, 0, NULL);
}

typedef struct { char name[160]; long n; } ProfRow;
static int prof_cmp(const void *a, const void *b) { return (int)(((const ProfRow *)b)->n - ((const ProfRow *)a)->n); }

static void prof_report(void)
{
    prof_stop = 1;
    Sleep(20);
    HANDLE proc = GetCurrentProcess();
    SymSetOptions(SYMOPT_LOAD_LINES | SYMOPT_DEFERRED_LOADS | SYMOPT_UNDNAME);
    SymInitialize(proc, NULL, TRUE);
    static ProfRow fn[4096], ln[16384];
    int nf = 0, nl = 0;
    for (long i = 0; i < prof_n; i++) {
        char buf[sizeof(SYMBOL_INFO) + 256];
        SYMBOL_INFO *si = (SYMBOL_INFO *)buf;
        si->SizeOfStruct = sizeof(SYMBOL_INFO);
        si->MaxNameLen = 255;
        DWORD64 disp = 0;
        char name[160] = "?", line[160] = "?";
        if (SymFromAddr(proc, prof_pc[i], &disp, si)) snprintf(name, sizeof name, "%s", si->Name);
        IMAGEHLP_LINE64 li;
        DWORD ld = 0;
        li.SizeOfStruct = sizeof li;
        if (SymGetLineFromAddr64(proc, prof_pc[i], &ld, &li)) {
            const char *f = strrchr(li.FileName, '\\');
            snprintf(line, sizeof line, "%s:%lu", f ? f + 1 : li.FileName, li.LineNumber);
        }
        int k;
        for (k = 0; k < nf && strcmp(fn[k].name, name); k++) {}
        if (k == nf && nf < 4096) { snprintf(fn[nf].name, sizeof fn[nf].name, "%s", name); fn[nf++].n = 0; }
        if (k < 4096) fn[k].n++;
        for (k = 0; k < nl && strcmp(ln[k].name, line); k++) {}
        if (k == nl && nl < 16384) { snprintf(ln[nl].name, sizeof ln[nl].name, "%s", line); ln[nl++].n = 0; }
        if (k < 16384) ln[k].n++;
    }
    qsort(fn, (size_t)nf, sizeof fn[0], prof_cmp);
    qsort(ln, (size_t)nl, sizeof ln[0], prof_cmp);
    fprintf(stderr, "profile: %ld samples\n  functions:\n", (long)prof_n);
    for (int i = 0; i < nf && i < 30; i++) fprintf(stderr, "  %5.1f%%  %s\n", 100.0 * fn[i].n / prof_n, fn[i].name);
    fprintf(stderr, "  source lines:\n");
    for (int i = 0; i < nl && i < 40; i++) fprintf(stderr, "  %5.1f%%  %s\n", 100.0 * ln[i].n / prof_n, ln[i].name);
    /* PB_PROF_FUNC=name: the offsets in that function (assembly: see its listing, ml64 /Fl) */
    const char *pf = getenv("PB_PROF_FUNC");
    if (pf) {
        static ProfRow off[8192];
        int no = 0;
        for (long i = 0; i < prof_n; i++) {
            char buf[sizeof(SYMBOL_INFO) + 256];
            SYMBOL_INFO *si = (SYMBOL_INFO *)buf;
            si->SizeOfStruct = sizeof(SYMBOL_INFO);
            si->MaxNameLen = 255;
            DWORD64 disp = 0;
            if (!SymFromAddr(proc, prof_pc[i], &disp, si) || strcmp(si->Name, pf)) continue;
            char name[32];
            snprintf(name, sizeof name, "%llX", (unsigned long long)disp);
            int k;
            for (k = 0; k < no && strcmp(off[k].name, name); k++) {}
            if (k == no && no < 8192) { snprintf(off[no].name, sizeof off[no].name, "%s", name); off[no++].n = 0; }
            if (k < 8192) off[k].n++;
        }
        qsort(off, (size_t)no, sizeof off[0], prof_cmp);
        fprintf(stderr, "  offsets in %s:\n", pf);
        for (int i = 0; i < no && i < 200; i++) fprintf(stderr, "  %5.2f%%  %s\n", 100.0 * off[i].n / prof_n, off[i].name);
    }
}
#else
static void prof_start(void) {}
static void prof_report(void) {}
#endif

static void shot(const char *name)
{
    char path[512];
    int w, h, stride;
    const uint32_t *px = pb_frame(&pb, &w, &h, &stride);
    snprintf(path, sizeof path, "%s_%s.png", prefix, name);
    if (fx_f >= 0 && screenfx_begin(&fx, px, w, h, stride, fx_f, fx_c, fx_k)) {
        screenfx_rows(&fx, 0, fx.h);
        png_write_rgb(path, fx.out, w * fx.k, h * fx.k, w * fx.k, fx.k == 1 ? 2 : 1);
        return;
    }
    png_write_rgb(path, px, w, h, stride, 2);
}

#ifdef PB_STATS
extern unsigned long long gbc_stat_op[512], gbc_stat_tick, gbc_stat_rd_slow[16], gbc_stat_wr_slow[16], gbc_stat_rd_io[128],
    gbc_stat_wr_io[128], gbc_stat_hook, gbc_stat_irq, gbc_stat_halt, gbc_stat_halt_steps, gbc_stat_steps, gbc_stat_frozen_steps,
    gbc_stat_pc[2][0x10000], gbc_stat_apu_runs, gbc_stat_apu_iter, gbc_stat_apu_emit, gbc_stat_apu_ev[6];
/* -DPB_STATS: what the fast interpreter of C met, per frame */
static void print_stats(void)
{
    double n = frames > 0 ? (double)frames : 1;
    unsigned long long tot = 0;
    for (int i = 0; i < 256; i++) tot += gbc_stat_op[i];
    fprintf(stderr, "per frame: steps %.0f (frozen %.0f) instructions %.0f, deadline ticks %.0f, hooks %.1f, irq %.1f, halts %.0f (%.0f steps)\n",
            gbc_stat_steps / n, gbc_stat_frozen_steps / n, tot / n, gbc_stat_tick / n, gbc_stat_hook / n, gbc_stat_irq / n,
            gbc_stat_halt / n, gbc_stat_halt_steps / n);
    fprintf(stderr, "APU per frame: runs %.1f, intervals %.1f, samples %.1f, events: sequencer %.1f ch1 %.1f ch2 %.1f ch3 %.1f ch4 %.1f, CPU catch-up %.1f\n",
            gbc_stat_apu_runs / n, gbc_stat_apu_iter / n, gbc_stat_apu_emit / n, gbc_stat_apu_ev[0] / n, gbc_stat_apu_ev[1] / n,
            gbc_stat_apu_ev[2] / n, gbc_stat_apu_ev[3] / n, gbc_stat_apu_ev[4] / n, gbc_stat_apu_ev[5] / n);
    fprintf(stderr, "slow reads per region:");
    for (int i = 0; i < 16; i++) fprintf(stderr, " %X:%.1f", i, gbc_stat_rd_slow[i] / n);
    fprintf(stderr, "\nslow writes per region:");
    for (int i = 0; i < 16; i++) fprintf(stderr, " %X:%.1f", i, gbc_stat_wr_slow[i] / n);
    fprintf(stderr, "\nIO reads:");
    for (int i = 0; i < 128; i++) if (gbc_stat_rd_io[i] / n >= 0.5) fprintf(stderr, " FF%02X:%.1f", i, gbc_stat_rd_io[i] / n);
    fprintf(stderr, "\nIO writes:");
    for (int i = 0; i < 128; i++) if (gbc_stat_wr_io[i] / n >= 0.5) fprintf(stderr, " FF%02X:%.1f", i, gbc_stat_wr_io[i] / n);
    for (int fz = 0; fz < 2; fz++) {
        fprintf(stderr, "\nhot addresses (%s):", fz ? "frozen" : "game time");
        static bool usedp[2][0x10000];
        for (int k = 0; k < 32; k++) {
            int best = -1;
            for (int i = 0; i < 0x10000; i++) if (!usedp[fz][i] && (best < 0 || gbc_stat_pc[fz][i] > gbc_stat_pc[fz][best])) best = i;
            usedp[fz][best] = true;
            fprintf(stderr, " %04X:%.0f", best, gbc_stat_pc[fz][best] / n);
        }
    }
    fprintf(stderr, "\nopcodes (share of the instructions, cumulated; CB xx: share of the instructions too):\n");
    static bool used[512];
    double cum = 0;
    for (int k = 0; k < 160; k++) {
        int best = -1;
        for (int i = 0; i < 512; i++) if (!used[i] && (best < 0 || gbc_stat_op[i] > gbc_stat_op[best])) best = i;
        used[best] = true;
        double pct = 100.0 * (double)gbc_stat_op[best] / (double)(tot ? tot : 1);
        cum += best < 256 ? pct : 0;
        fprintf(stderr, "  %s%02X %5.2f%% %6.2f%%\n", best >= 256 ? "CB " : "", best & 255, pct, cum);
        if (pct < 0.03) break;
    }
}
#endif

int main(int argc, char **argv)
{
    engine_from_env();
    if (argc < 2) return 2;
    FILE *f = fopen(argv[1], "rb");
    if (!f) { perror(argv[1]); return 2; }
    size_t n = fread(rom, 1, sizeof rom, f);
    fclose(f);
    if (pb_init(&pb, rom, n, 48000)) { fprintf(stderr, "%s\n", pb.error); return 1; }
    clock_t t0 = clock();
    bool profiling = false;
    for (int i = 2; i < argc; i++) {
        char *a = argv[i];
        if (!strcmp(a, "-load")) {
            FILE *sf = fopen(argv[++i], "rb");
            static uint8_t buf[1 << 20];
            size_t r = fread(buf, 1, sizeof buf, sf); fclose(sf);
            if (pb_snapshot_load(&pb, buf, r)) fprintf(stderr, "bad snapshot\n");
        } else if (!strcmp(a, "-save")) {
            FILE *sf = fopen(argv[++i], "wb");
            static uint8_t buf[1 << 20];
            pb_snapshot_save(&pb, buf); fwrite(buf, 1, pb_snapshot_size(), sf); fclose(sf);
        } else if (!strcmp(a, "-sram")) {
            FILE *sf = fopen(argv[++i], "rb");
            static uint8_t buf[0x8000];
            size_t r = sf ? fread(buf, 1, sizeof buf, sf) : 0;
            if (sf) fclose(sf);
            pb_load_sram(&pb, buf, r);
        } else if (a[0] == 'S' && a[1] == ':') {
            size_t sz; const uint8_t *d = pb_sram(&pb, &sz);
            FILE *sf = fopen(a + 2, "wb"); fwrite(d, 1, sz, sf); fclose(sf);
        } else if (!strcmp(a, "-check")) {
            pb.g.trace_fn = check_trace;
        } else if (!strcmp(a, "-highpass") && i + 1 < argc) {   /* the output's high-pass filter at HZ (front-ends: GBC_HIGHPASS_FRONT) */
            pb_set_audio_highpass(&pb, atof(argv[++i]));
        } else if (!strcmp(a, "-audiodump") && i + 1 < argc) {   /* the sound, raw 16-bit stereo */
            hashing = true;
            audiodump = fopen(argv[++i], "wb");
        } else if (!strcmp(a, "-hashlog") && i + 1 < argc) {
            hashing = true;
            hashlog = fopen(argv[++i], "w");
        } else if (!strcmp(a, "-fx") && i + 1 < argc) {
            sscanf(argv[++i], "%d:%d:%d", &fx_f, &fx_c, &fx_k);
        } else if (!strcmp(a, "-table") && i + 1 < argc) {
            table_wanted = atoi(argv[++i]);
        } else if (!strcmp(a, "-hash")) {
            hashing = true;
        } else if (!strcmp(a, "-linecheck")) {
            linecheck = true;
        } else if (!strcmp(a, "-flicker")) {
            flicker = true;
        } else if (!strcmp(a, "-deflicker")) {
            flicker = use_deflicker = true;
        } else if (!strcmp(a, "-ratewobble")) {
            ratewobble = true;
        } else if (!strcmp(a, "-sfx")) {
            sfxstat = true;
            gbc_add_hook(&pb.g, 0, R_PlaySoundEffect, hk_sfx, NULL);
            gbc_add_hook(&pb.g, 0, R_PlaySong, hk_sfx, (void *)1);
        } else if (!strcmp(a, "-pcm")) {
            gbc_add_hook(&pb.g, B_PlayCry, PBR->R_CryPlayer, hk_pcm_log, (void *)1);
            gbc_add_hook(&pb.g, B_PlayCry, 0x4054, hk_pcm_log, (void *)2);   /* after its call (both ROMs) */
        } else if (!strcmp(a, "-ds")) {
            pb_set_double_speed(&pb, true);
        } else if (!strcmp(a, "-antilag")) {
            pb_set_antilag(&pb, true);
        } else if (!strcmp(a, "-hold")) {               /* pb_frame as the front-ends show it (pb_set_hold) */
            pb_set_hold(&pb, true);
        } else if (!strcmp(a, "-lag")) {
            lagstat = true;
            gbc_add_hook(&pb.g, 0, 0x0040, hk_vblank, NULL);
            gbc_add_hook(&pb.g, 0, R_WaitFrame, hk_wait_entry, NULL);
        } else if (!strcmp(a, "-frametime")) {
            frametime = true;
        } else if (!strcmp(a, "-sramwrites")) {
            sramwatch = true;
        } else if (!strcmp(a, "-prof")) {
            profiling = true;
            prof_start();
        } else if (!strcmp(a, "-shot")) {
            prefix = argv[++i];
        } else if (a[0] == 'w' && a[1] == ':') {
            int k = atoi(a + 2);
            for (int j = 0; j < k; j++) frame();
        } else if (a[0] == 'p' && a[1] == ':') {
            char name[16]; int k = 1;
            sscanf(a + 2, "%15[^:]:%d", name, &k);
            int b = btn(name);
            held |= (uint8_t)b;
            for (int j = 0; j < k; j++) frame();
            held &= (uint8_t)~b;
            frame();
        } else if (a[0] == 'h' && a[1] == ':') {
            held |= (uint8_t)btn(a + 2);
        } else if (a[0] == 'r' && a[1] == ':') {
            held &= (uint8_t)~btn(a + 2);
        } else if (a[0] == 's' && a[1] == ':') {
            shot(a + 2);
        } else if (a[0] == 'R' && a[1] == ':') {
            int k = 0, seed = 1, every = 0;
            sscanf(a + 2, "%d:%d:%d", &k, &seed, &every);
            srand((unsigned)seed);
            for (int j = 0; j < k; j++) {
                if (j % 6 == 0) {
                    held = 0;
                    if (rand() % 100 < 45) held |= GBC_LEFT;
                    if (rand() % 100 < 45) held |= GBC_A;
                }
                if (j % 400 == 10) held = GBC_A;
                frame();
                if (every && j % every == 0) { char nm[32]; snprintf(nm, sizeof nm, "R%06d", j); shot(nm); }
            }
            held = 0;
        } else if (a[0] == 'X' && a[1] == ':') {
            /* random flipper play, screenshots around the first N crossings of the ball */
            int k = 0, seed = 1, maxshots = 3;
            sscanf(a + 2, "%d:%d:%d", &k, &seed, &maxshots);
            srand((unsigned)seed);
            int shots = 0, after = -1;
            uint8_t last = rd(W_CurrentStage);
            for (int j = 0; j < k && shots < maxshots; j++) {
                if (j % 6 == 0) { held = 0; if (rand() % 100 < 45) held |= GBC_LEFT; if (rand() % 100 < 45) held |= GBC_A; }
                frame();
                uint8_t st = rd(W_CurrentStage);
                if (st != last && (st ^ last) == 1) { char nm[32]; snprintf(nm, sizeof nm, "X%d_a", shots); shot(nm); after = 2; }
                else if (after > 0 && --after == 0) { char nm[32]; snprintf(nm, sizeof nm, "X%d_b", shots); shot(nm); shots++; }
                last = st;
            }
            held = 0;
        } else if (a[0] == 'B' && a[1] == ':') {
            /* whole-game bot: menus (A / random), field play (flippers), occasional pause */
            int k = 0, seed = 1, every = 0;
            sscanf(a + 2, "%d:%d:%d", &k, &seed, &every);
            srand((unsigned)seed);
            for (int j = 0; j < k; j++) {
                if (j % 5 == 0) {
                    uint8_t scr = rd(W_CurrentScreen);
                    held = 0;
                    if (scr != SCREEN_PINBALL_GAME) {
                        int r = rand() % 100;
                        if (r < 45) held = GBC_A;
                        else if (r < 55) held = GBC_RIGHT;
                        else if (r < 62) held = GBC_LEFT;
                        else if (r < 67) held = GBC_DOWN;
                        else if (r < 70) held = GBC_B;
                    } else {
                        if (rand() % 100 < 42) held |= GBC_LEFT;
                        if (rand() % 100 < 42) held |= GBC_A;
                        if (rand() % 1000 < 8) held |= GBC_DOWN;
                        if (rand() % 1000 < 8) held |= GBC_B;
                        if (rand() % 2000 < 2) held = GBC_START;
                    }
                }
                frame();
                if (every && j % every == 0) { char nm[32]; snprintf(nm, sizeof nm, "B%07d", j); shot(nm); }
            }
            held = 0;
        }
    }
    double dt = (double)(clock() - t0) / CLOCKS_PER_SEC;
    fprintf(stderr, "%ld frames in %.2fs (%.0f fps) unified=%ld swaps=%ld refresh=%ld aborts=%ld stage=%d screen=%d\n",
            frames, dt, frames / (dt > 0 ? dt : 1), pb.st.stats_frames_unified, pb.st.stats_swaps,
            pb.st.stats_refresh, pb.st.stats_aborts, rd(W_CurrentStage), rd(W_CurrentScreen));
    if (pb.g.trace_fn) {
        fprintf(stderr, "wild=%ld resets=%ld  stages:", wild, resets);
        for (int i = 0; i < 32; i++) if (stage_frames[i]) fprintf(stderr, " %d:%ld", i, stage_frames[i]);
        fprintf(stderr, "  screens:");
        for (int i = 0; i < 16; i++) if (screen_frames[i]) fprintf(stderr, " %d:%ld", i, screen_frames[i]);
        fprintf(stderr, "\n");
    }
    if (hashing) fprintf(stderr, "hash %016llx\n", (unsigned long long)run_hash);
    if (flicker && frames) {
        fprintf(stderr, "flicker: %.1f alternating pixels per frame, %ld frames of %ld with some (%.1f %%), worst %ld pixels at frame %ld\n",
                fl_total / (double)frames, fl_frames_with, frames, 100.0 * fl_frames_with / frames, fl_max, fl_max_frame);
        {   /* a map of the cells (prefix_flickermap.png): brighter = more frames alternating */
            static uint32_t map[64 * 8 * 64 * 8];
            long top = 1;
            for (int y = 0; y < 64; y++) for (int x = 0; x < 64; x++) if (fl_cell[y][x] > top) top = fl_cell[y][x];
            int mw = GBC_FB_W, mh = GBC_FB_H;
            for (int y = 0; y < mh; y++)
                for (int x = 0; x < mw; x++) {
                    long v = fl_cell[y / 8][x / 8] * 255 / top;
                    uint32_t bg = fl_worst[2][0] ? 0 : 0;
                    map[(size_t)y * mw + x] = v ? (uint32_t)((v << 16) | ((v / 2) << 8)) : bg;
                }
            char name[300];
            snprintf(name, sizeof name, "%s_flickermap.png", prefix);
            png_write_rgb(name, map, mw, mh, mw, 2);
        }
        fprintf(stderr, "  cells (8 x 8, x y) alternating the most, per 1000 frames:");
        for (int k = 0; k < 12; k++) {
            int bx = 0, by = 0;
            for (int y = 0; y < 64; y++) for (int x = 0; x < 64; x++) if (fl_cell[y][x] > fl_cell[by][bx]) { bx = x; by = y; }
            if (!fl_cell[by][bx]) break;
            fprintf(stderr, " %d,%d:%.0f", bx, by, 1000.0 * fl_cell[by][bx] / frames);
            fl_cell[by][bx] = 0;
        }
        fprintf(stderr, "\n");
        if (fl_max) {
            char name[300];
            for (int i = 0; i < 3; i++) {
                snprintf(name, sizeof name, "%s_flicker%d.png", prefix, i);
                png_write_rgb(name, fl_worst[i], fl_ww, fl_wh, fl_ww, 3);
            }
        }
    }
    if (sramwatch) fprintf(stderr, "cartridge save: changed in %ld seconds of %ld\n", sram_changes, frames / 60);
    if (frametime && frames) {
        fprintf(stderr, "frame time: mean %.3f ms, slowest:", ft_sum / frames);
        for (int i = 0; i < 8 && ft_max[i] > 0; i++) fprintf(stderr, " %.2f ms (frame %ld)", ft_max[i], ft_max_frame[i]);
        fprintf(stderr, "\n  histogram (0.25 ms):");
        for (int b = 0; b < 64; b++) if (ft_hist[b]) fprintf(stderr, " %.2f:%ld", b / 4.0, ft_hist[b]);
        fprintf(stderr, "\n");
        static const char *const kinds[5] = { "other half redrawn", "ball changing halves", "unified field on/off (stage load)",
                                              "late frame finished", "none of these" };
        for (int k = 0; k < 5; k++)
            if (ft_kind_n[k])
                fprintf(stderr, "  %-34s %7ld frames, mean %.3f ms, max %.2f ms\n", kinds[k], ft_kind_n[k], ft_kind_sum[k] / ft_kind_n[k], ft_kind_max[k]);
    }
#ifdef PB_STATS
    print_stats();
#endif
    if (profiling) prof_report();
    if (lagstat) lag_report();
    if (sfxstat) sfx_report();
    if (linecheck) linecheck_report();
    pb_free(&pb);
    return 0;
}
