/*
 * cpucheck.c - an engine of the CPU (PB_ENGINE: the assembly version by default, or "c") and the
 * reference interpreter (gbc_step) side by side, one instruction at a time: after every
 * instruction the whole machine state (registers, memories, video, sound, timers, cycle
 * counter) and the picture must be the same.
 *
 *   cpucheck rom ROM N          N instructions of a ROM (from its start)
 *   cpucheck fuzz SEED M K      M random programs of K instructions: random code (every opcode),
 *                               random registers, memory, timer and interrupts, half of them with
 *                               the time frozen (the out-of-time calls of the unified field)
 *   cpucheck run ROM N          N instructions with gbc_exec in bigger slices (1..300 steps at
 *                               once, random), compared at the end of each slice
 *   cpucheck fuzzrun SEED M K   the random programs of fuzz through gbc_exec on both machines:
 *                               slices of 1..64 instructions, stop addresses, frames
 * Exit status 0 when everything matched.
 */
#include "../src/core/gbc.h"
#include "engine.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static GBC A, B;                      /* A: the engine tested, B: the reference */
static uint8_t rom[8 << 20];
static size_t rom_size;
static uint32_t rng = 1;

static uint32_t rnd(void)
{
    rng ^= rng << 13; rng ^= rng >> 17; rng ^= rng << 5;
    return rng;
}

/* the fields of the state, for the reports */
#define F(name) { #name, offsetof(GBCState, name), sizeof(((GBCState *)0)->name) }
static const struct { const char *name; size_t off, size; } FIELDS[] = {
    F(a), F(f), F(b), F(c), F(d), F(e), F(h), F(l), F(sp), F(pc), F(ime), F(ei_pending), F(halted), F(halt_bug),
    F(cycles), F(rom_bank), F(ram_bank), F(ram_enable), F(rumble), F(sram), F(sram_size), F(wram), F(wram_bank),
    F(hram), F(io), F(ie), F(ifl), F(vbk), F(bcps), F(ocps), F(div16), F(tima), F(tma), F(tac), F(serial_active),
    F(serial_done), F(buttons), F(page), F(cpu_page), F(band), F(nbands), F(fw), F(fh), F(ppu), F(apu),
    F(frame_count), F(lcd_off_since), F(rumble_frames),
};

static const char *field_of(size_t off)
{
    for (size_t i = 0; i < sizeof FIELDS / sizeof FIELDS[0]; i++)
        if (off >= FIELDS[i].off && off < FIELDS[i].off + FIELDS[i].size) return FIELDS[i].name;
    return "(padding)";
}

static long checks;

static void trace_print(GBC *g, void *u)
{
    const GBCState *s = &g->s;
    (void)u;
    printf("  ref pc=%04X a=%02X f=%02X bc=%02X%02X de=%02X%02X hl=%02X%02X sp=%04X cyc=%llu\n", s->pc, s->a, s->f, s->b, s->c,
           s->d, s->e, s->h, s->l, s->sp, (unsigned long long)s->cycles);
}

/* the watched work RAM bytes (gbc_add_watch): every call, its address and value, on both */
static uint64_t watch_sum[2];
static void on_watch(GBC *g, uint16_t addr, uint8_t v, void *u)
{
    int m = g == &A ? 0 : 1;
    (void)u;
    watch_sum[m] = watch_sum[m] * 1000003u + (uint64_t)(addr << 8 | v) + 1;
}

/* the two machines must be the same; else a report and false */
static bool same(const char *what, long n)
{
    checks++;
    const uint8_t *pa = (const uint8_t *)&A.s, *pb = (const uint8_t *)&B.s;
    bool ok = memcmp(pa, pb, sizeof(GBCState)) == 0 && A.frame_done == B.frame_done && watch_sum[0] == watch_sum[1] &&
              A.fake_ly == B.fake_ly && A.fake_phase == B.fake_phase && memcmp(A.fb, B.fb, sizeof A.fb) == 0;
    if (ok) return true;
    printf("MISMATCH %s after %ld: engine pc=%04X sp=%04X cycles=%llu, reference pc=%04X sp=%04X cycles=%llu\n", what, n,
           A.s.pc, A.s.sp, (unsigned long long)A.s.cycles, B.s.pc, B.s.sp, (unsigned long long)B.s.cycles);
    int shown = 0;
    for (size_t i = 0; i < sizeof(GBCState) && shown < 12; i++)
        if (pa[i] != pb[i]) {
            printf("  state+%zu (%s): engine %02X reference %02X\n", i, field_of(i), pa[i], pb[i]);
            shown++;
        }
    if (A.frame_done != B.frame_done) printf("  frame_done: engine %d reference %d\n", A.frame_done, B.frame_done);
    if (memcmp(A.fb, B.fb, sizeof A.fb)) printf("  the pictures differ\n");
    return false;
}

/* one instruction in each */
static void step_both(void)
{
    int64_t budget = 1;
    gbc_exec(&A, GBC_EXEC_CALL, 0xFFFF, 0x0001, &budget, 0);
    gbc_step(&B);
}

static bool load(const char *path)
{
    FILE *f = fopen(path, "rb");
    if (!f) { perror(path); return false; }
    rom_size = fread(rom, 1, sizeof rom, f);
    fclose(f);
    if (rom_size < 0x8000) { memset(rom + rom_size, 0xFF, 0x8000 - rom_size); rom_size = 0x8000; }
    return true;
}

static void init_both(void)
{
    int keep = gbc_default_engine;
    gbc_init(&A, rom, rom_size, 48000);
    gbc_default_engine = GBC_ENGINE_REF;
    gbc_init(&B, rom, rom_size, 48000);
    gbc_default_engine = keep;
}

static int check_rom(const char *path, long n)
{
    if (!load(path)) return 2;
    init_both();
    for (long i = 1; i <= n; i++) {
        step_both();
        if (!same("instruction", i)) return 1;
        if ((i & 0xFFFFF) == 0) { A.frame_done = B.frame_done = false; }
    }
    printf("rom: %ld instructions, all the same\n", n);
    return 0;
}

/* gbc_exec in slices: what the game does (frames, calls), compared at the end of each slice */
static int check_run(const char *path, long n)
{
    if (!load(path)) return 2;
    init_both();
    long done = 0;
    while (done < n) {
        int64_t k = 1 + rnd() % 300, ka = k;
        gbc_exec(&A, GBC_EXEC_CALL, 0xFFFF, 0x0001, &ka, 0);
        for (int64_t i = 0; i < k; i++) gbc_step(&B);
        done += k;
        if (!same("slice", done)) return 1;
        if (rnd() % 64 == 0) { A.frame_done = B.frame_done = false; }
    }
    printf("run: %ld instructions in slices, all the same\n", done);
    return 0;
}

/* gbc_exec on both (B: its reference loop): a slice of k instructions, a stop address, or a frame;
 * the results and the budgets left must be the same too */
static bool slice_both(long k)
{
    int64_t ka = k, kb = k;
    int ra, rb;
    uint32_t r = rnd() % 16;
    if (r == 0 && !A.frozen) {             /* (frozen, a frame would never end) */
        A.frame_done = B.frame_done = false;
        uint64_t st = A.s.cycles;
        ra = gbc_exec(&A, GBC_EXEC_FRAME, 0, 0, NULL, st);
        rb = gbc_exec(&B, GBC_EXEC_FRAME, 0, 0, NULL, st);
    } else {
        uint16_t stop_pc = 0xFFFF, stop_sp = 1;
        if (r < 4) { stop_pc = (uint16_t)(rnd() & 0x7FFF); stop_sp = A.s.sp; }
        ra = gbc_exec(&A, GBC_EXEC_CALL, stop_pc, stop_sp, &ka, 0);
        rb = gbc_exec(&B, GBC_EXEC_CALL, stop_pc, stop_sp, &kb, 0);
    }
    if (ra != rb || ka != kb) {
        printf("MISMATCH of gbc_exec: engine %d (budget %lld), reference %d (budget %lld)\n", ra, (long long)ka, rb, (long long)kb);
        return false;
    }
    return true;
}

static int check_fuzz(uint32_t seed, long programs, long len, bool slices)
{
    rng = seed ? seed : 1;
    rom_size = 0x8000;
    for (long p = 0; p < programs; p++) {
        for (size_t i = 0; i < rom_size; i++) rom[i] = (uint8_t)rnd();
        rom[0x147] = 0x00;                         /* no MBC */
        rom[0x149] = 0x02;                         /* 8 KB of cartridge RAM */
        init_both();
        GBCState *s = &A.s;
        s->a = (uint8_t)rnd(); s->f = (uint8_t)(rnd() & 0xF0); s->b = (uint8_t)rnd(); s->c = (uint8_t)rnd();
        s->d = (uint8_t)rnd(); s->e = (uint8_t)rnd(); s->h = (uint8_t)rnd(); s->l = (uint8_t)rnd();
        s->pc = (uint16_t)(rnd() & 0x7FFF);
        uint32_t r = rnd() % 4;
        s->sp = (uint16_t)(r == 0 ? 0xFFFE : r == 1 ? 0xC000 + (rnd() & 0x1FFF) : r == 2 ? 0xFF80 + (rnd() & 0x7F) : (uint16_t)rnd());
        for (size_t i = 0; i < sizeof s->wram; i++) s->wram[i] = (uint8_t)rnd();
        for (size_t i = 0; i < sizeof s->hram; i++) s->hram[i] = (uint8_t)rnd();
        s->ie = (uint8_t)rnd();
        s->ifl = (uint8_t)(rnd() & 0x1F);
        s->ime = rnd() & 1;
        s->tac = (uint8_t)(rnd() & 7);
        s->tma = (uint8_t)rnd();
        s->tima = (uint8_t)rnd();
        s->div16 = (uint16_t)rnd();
        s->wram_bank = (uint8_t)(1 + rnd() % 7);
        s->ram_enable = rnd() & 1;
        if (rnd() % 4 == 0) {
            /* the wait loop the engines count at once (ld a,[hl] / and a / jr z,-4), [hl] = 0 */
            uint16_t at = (uint16_t)(rnd() % 0x7FF0);
            rom[at] = 0x7E; rom[at + 1] = 0xA7; rom[at + 2] = 0x28; rom[at + 3] = 0xFC;
            s->pc = (uint16_t)(at + rnd() % 3);
            uint16_t hl = (uint16_t)(rnd() & 1 ? 0xFF80 + rnd() % 0x7F : 0xC000 + (rnd() & 0x1FFF));
            s->h = (uint8_t)(hl >> 8); s->l = (uint8_t)hl;
            if (hl >= 0xFF80) s->hram[hl - 0xFF80] = 0; else s->wram[hl - 0xC000] = 0;
            if (rnd() & 1) { s->a = 0; s->f = 0xA0; }
        } else if (rnd() % 3 == 0) {
            /* the copy loop (ld a,[hl+] / ld [de],a / inc de / dec bc / ld a,c / or b / jr nz,-8) */
            static const uint8_t pat[8] = { 0x2A, 0x12, 0x13, 0x0B, 0x79, 0xB0, 0x20, 0xF8 };
            uint16_t at = (uint16_t)(rnd() % 0x7FF0);
            memcpy(&rom[at], pat, 8);
            s->pc = (uint16_t)(at + rnd() % 7);
            static const uint16_t areas[5] = { 0x0000, 0x8000, 0xC000, 0xD000, 0xFF80 };
            uint16_t hl = (uint16_t)(areas[rnd() % 5] + rnd() % 0x1000), de = (uint16_t)(areas[1 + rnd() % 4] + rnd() % 0x1000);
            s->h = (uint8_t)(hl >> 8); s->l = (uint8_t)hl;
            s->d = (uint8_t)(de >> 8); s->e = (uint8_t)de;
            uint16_t bc = (uint16_t)(rnd() % 4 == 0 ? rnd() : rnd() % 0x300);
            s->b = (uint8_t)(bc >> 8); s->c = (uint8_t)bc;
        }
        if (rnd() & 1) gbc_ppu_lcdc_write(&A, 0x11);   /* LCD off */
        bool frozen = rnd() & 1;
        if (frozen) { A.frozen = 1; A.fake_lcd_off = rnd() & 1; }
        if (rnd() & 1) {
            /* the video pages of the unified field: window page, mirrored tile writes */
            s->cpu_page = (int)(rnd() & 1);
            A.win_page = (int)(rnd() % 3) - 1;
            A.tile_mirror_page = (int)(rnd() % 3) - 1;
            A.tile_mirror_lo = (uint16_t)(rnd() & 0x1FFF);
            A.tile_mirror_hi = (uint16_t)(A.tile_mirror_lo + rnd() % 0x400);
        }
        memcpy(&B.s, &A.s, sizeof(GBCState));
        B.frozen = A.frozen;
        B.fake_lcd_off = A.fake_lcd_off;
        B.win_page = A.win_page;
        B.tile_mirror_page = A.tile_mirror_page;
        B.tile_mirror_lo = A.tile_mirror_lo;
        B.tile_mirror_hi = A.tile_mirror_hi;
        /* CPUCHECK_TRACE=P: the instructions of program P on the reference */
        const char *tr = getenv("CPUCHECK_TRACE");
        B.trace_fn = tr && atol(tr) == p ? trace_print : NULL;
        if (rnd() & 1) {                           /* watched bytes (the unified field watches one) */
            int n = 1 + (int)(rnd() % 3);
            for (int i = 0; i < n; i++) {
                uint16_t w = (uint16_t)(0xC000 + (rnd() & 0x1FFF));
                gbc_add_watch(&A, w, on_watch, NULL);
                gbc_add_watch(&B, w, on_watch, NULL);
            }
        }
        for (long i = 1; i <= len; ) {
            bool ok = true;
            if (slices) {
                long k = 1 + (long)(rnd() % 64);
                ok = slice_both(k);
                i += k;
            } else {
                step_both();
                i++;
            }
            if (!ok || !same(frozen ? "fuzz (frozen)" : "fuzz", i)) {
                printf("  program %ld of seed %u\n", p, seed);
                return 1;
            }
            if (A.frame_done) A.frame_done = B.frame_done = false;
        }
    }
    printf("fuzz%s: %ld programs of %ld instructions, all the same (%ld checks)\n", slices ? " in slices" : "", programs,
           len, checks);
    return 0;
}

int main(int argc, char **argv)
{
    engine_from_env();
    printf("engine: %s\n", gbc_default_engine == GBC_ENGINE_REF ? "reference" : gbc_default_engine == GBC_ENGINE_C ? "C" :
           gbc_exec_has_asm() ? "assembly" : "C (no assembly version in this build)");
    if (argc >= 4 && !strcmp(argv[1], "rom")) return check_rom(argv[2], atol(argv[3]));
    if (argc >= 4 && !strcmp(argv[1], "run")) return check_run(argv[2], atol(argv[3]));
    if (argc >= 5 && !strcmp(argv[1], "fuzz"))
        return check_fuzz((uint32_t)strtoul(argv[2], NULL, 0), atol(argv[3]), atol(argv[4]), false);
    if (argc >= 5 && !strcmp(argv[1], "fuzzrun"))
        return check_fuzz((uint32_t)strtoul(argv[2], NULL, 0), atol(argv[3]), atol(argv[4]), true);
    fprintf(stderr, "usage: cpucheck rom ROM N | run ROM N | fuzz SEED M K | fuzzrun SEED M K\n");
    return 2;
}
