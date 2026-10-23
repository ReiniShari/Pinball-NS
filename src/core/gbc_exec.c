/*
 * gbc_exec.c - the fast interpreter of the SM83: runs instructions until a stop condition, with
 * exactly the machine behaviour of repeated gbc_step (gbc.c, the reference). This is the model
 * of the assembly versions (cpu_x64.asm, cpu_a64.S, written by tools/gencpu.c) and their fallback.
 *
 * What makes it fast, everything else being the same instruction by instruction:
 *   - the CPU registers and the cycle counter live in local variables (machine registers); they
 *     are written back to the machine state before any call to the rest of the core (FLUSH) and
 *     read again after it (RELOAD), as that code may read or change anything;
 *   - time: tick() of gbc.c updates the divider, the timer, the PPU and the serial port at every
 *     memory access. Here an access only adds its cycles and compares them with a deadline: the
 *     first cycle at which tick() would do more than counting (the next PPU event, the next
 *     timer increment, the end of a serial transfer). The divider is kept as an offset from the
 *     cycle counter. At the deadline, the original tick() runs (gbc_tick, state written back);
 *   - memory: reads and writes go through two tables of 16 pointers, one per 4 KB of the address
 *     space (ROM, banked ROM, video memory, work RAM...), rebuilt after any call to the rest of
 *     the core (gbc_exec_prepare); NULL entries (cartridge RAM, I/O, MBC registers, video memory
 *     with the runtime extensions on) take the original gbc_read / gbc_write. High RAM and OAM
 *     are read and written directly; the work RAM bytes watched by the runtime take gbc_write;
 *   - HALT: while halted with no interrupt pending, nothing can happen before the deadline: the
 *     4-cycle steps that end before it are done at once (each still counted in the budget of a
 *     call, and the frame still ends at the same step with the LCD off).
 */
#include "gbc.h"
#include <string.h>

#define FZ 0x80
#define FN 0x40
#define FH 0x20
#define FC 0x10
#define NEVER UINT64_MAX

static const int TAC_BIT[4] = { 9, 3, 5, 7 };

#ifdef PB_STATS
/* counters for the design of the fast paths (pbrun built with -DPB_STATS) */
unsigned long long gbc_stat_op[512], gbc_stat_tick, gbc_stat_rd_slow[16], gbc_stat_wr_slow[16], gbc_stat_rd_io[128],
    gbc_stat_wr_io[128], gbc_stat_hook, gbc_stat_irq, gbc_stat_halt, gbc_stat_halt_steps, gbc_stat_steps, gbc_stat_frozen_steps,
    gbc_stat_pc[2][0x10000];
#define STAT(x) (x)
#else
#define STAT(x) ((void)0)
#endif

/* ------------------------------------------------------------------ the derived state */

/* The tables hold the base of each region minus its first address (table[i][address] is the
 * byte). That pointer is out of the array: C leaves such arithmetic undefined, so it is made
 * through an integer (UndefinedBehaviorSanitizer stays quiet, no compiler can assume anything). */
static inline uint8_t *bias(const uint8_t *p, uintptr_t first)
{
    return (uint8_t *)((uintptr_t)p - first);
}

/* what depends on the time (the next event of the hardware, the interrupts): after a tick, only
 * this changes (a tick never changes the memory map) */
void gbc_exec_prepare_time(GBC *g)
{
    GBCState *s = &g->s;
    GBCFast *x = &g->fast;
    uint64_t d = NEVER;
    if (!g->frozen) {
        d = s->ppu.next;
        if (s->serial_active && s->serial_done < d) d = s->serial_done;
        if (s->tac & 4) {
            uint32_t period = 1u << (TAC_BIT[s->tac & 3] + 1);
            uint64_t t = s->cycles + (period - (s->div16 & (period - 1)));
            if (t < d) d = t;
        }
    }
    x->deadline = d;
    x->dl24 = d > 24 ? d - 24 : 0;
    x->div_base = (uint16_t)(s->div16 - (uint16_t)s->cycles);
    x->frozen = g->frozen != 0;

    /* what LY and STAT read until the next event (gbc_io_read; frozen: a virtual scan, the C one) */
    bool lcd = (s->io[0x40] & 0x80) && !g->fake_lcd_off;
    x->ff44 = lcd ? s->ppu.ly : 0;
    x->ff41 = (uint8_t)(0x80 | (s->io[0x41] & 0x78) | (lcd ? ((s->ppu.ly == s->io[0x45] ? 0x04 : 0) | (s->ppu.mode & 3)) : 0));

    /* the assembly version: what makes it hand the next step to the C one, and when it must
     * look before each step (x->limit) */
    bool frame = x->mode == GBC_EXEC_FRAME;
    x->frame_end = frame && !(s->io[0x40] & 0x80) ? x->start + GBC_FRAME_CYCLES : NEVER;
    x->special = s->halted || s->ei_pending || s->halt_bug || (s->ime && (s->ie & s->ifl & 0x1F) && !g->frozen) ||
                 g->trace_fn || (frame && (g->frame_done || g->frozen));
    x->limit = x->special ? 0 : x->dl24 < x->frame_end ? x->dl24 : x->frame_end;
}

void gbc_exec_prepare(GBC *g)
{
    GBCState *s = &g->s;
    GBCFast *x = &g->fast;
    /* the memory map, when what it depends on changed (a machine copied elsewhere too: its
     * pointers); most calls come after a write to an I/O register, which changes none of it. The
     * bank of ROM at 4000-7FFF is set every time (4 pointers; it changes with nearly every call of
     * a routine of another bank, which made the whole map again: 5 % of the time, 2.5) */
    int vbk = s->vbk & 1, plo = s->cpu_page, phi = g->win_page >= 0 ? g->win_page : s->cpu_page;
    int tm = g->frozen > g->stretch ? -1 : g->tile_mirror_page;
    uint64_t key = (uint64_t)(s->cpu_page & 1) | (uint64_t)vbk << 1 | (uint64_t)(g->win_page + 1) << 2 | (uint64_t)(tm + 1) << 4 |
                   (uint64_t)(g->tile_mirror_lo & 0x3FFF) << 6 | (uint64_t)(g->tile_mirror_hi & 0x3FFF) << 20 |
                   (uint64_t)(g->vram_fn != NULL) << 35 | (uint64_t)(g->wram_fn != NULL) << 36 | (uint64_t)s->wram_bank << 37 |
                   (uint64_t)(g->nwatch & 15) << 45 | (uint64_t)(g->tile_mirror_page + 1) << 58;
    uint32_t bank = g->rom_mask ? (s->rom_bank & g->rom_mask) : s->rom_bank % g->rom_banks;
    const uint8_t *romx = bias(g->rom + ((size_t)bank << 14), 0x4000);
    x->rd[4] = x->rd[5] = x->rd[6] = x->rd[7] = romx;
    if (key == x->map_key && x->map_g == g) {
        gbc_exec_prepare_time(g);
        return;
    }
    x->map_key = key;
    x->map_g = g;

    for (int i = 0; i < 4; i++) { x->rd[i] = g->rom; x->wr[i] = x->wr[4 + i] = NULL; }
    uint8_t *vram = bias(s->page[s->cpu_page].vram[s->vbk & 1], 0x8000);
    x->rd[8] = x->rd[9] = vram;
    bool vfast = g->win_page < 0 && !g->vram_fn && g->tile_mirror_page < 0;
    x->wr[8] = x->wr[9] = vfast ? vram : NULL;
    x->rd[10] = x->rd[11] = NULL;
    x->wr[10] = x->wr[11] = NULL;
    x->rd[12] = bias(s->wram, 0xC000);
    x->rd[13] = bias(s->wram + ((size_t)s->wram_bank << 12), 0xD000);
    x->rd[14] = bias(s->wram, 0xE000);
    x->rd[15] = NULL;
    x->wr[12] = g->wram_fn ? NULL : (uint8_t *)x->rd[12];
    x->wr[13] = (uint8_t *)x->rd[13];
    x->wr[14] = (uint8_t *)x->rd[14];
    x->wr[15] = NULL;
    x->oam = s->page[s->cpu_page].oam;
    x->oamb = bias(x->oam, 0xFE00);
    x->hramb = bias(s->hram, 0xFF80);
    x->watch = g->nwatch ? g->watchbyte : NULL;
    x->hooks = g->hookbyte;

    /* video memory writes of gbc_write with the extensions of the unified field (win_page,
     * tile_mirror_page), done without it: the page of 8000-9BFF and of 9C00-9FFF, and the page
     * that also receives the writes of [mirror_a0, mirror_a1) */
    x->vfast = !g->vram_fn;
    x->vlo = bias(s->page[plo].vram[vbk], 0x8000);
    x->vhi = bias(s->page[phi].vram[vbk], 0x8000);
    x->vmir_lo = tm >= 0 && tm != plo ? bias(s->page[tm].vram[vbk], 0x8000) : NULL;
    x->vmir_hi = tm >= 0 && tm != phi ? bias(s->page[tm].vram[vbk], 0x8000) : NULL;
    x->vmir_a0 = 0x8000u + g->tile_mirror_lo;
    x->vmir_a1 = 0x8000u + g->tile_mirror_hi;
    /* MBC5 bank writes (2000-3FFF) without gbc_write: the ROM pointers of 4000-7FFF follow */
    x->mbc5 = g->rom_mask && !(g->rom[0x147] >= 0x01 && g->rom[0x147] <= 0x03);

    /* the write table of the assembly versions (per 256 bytes) */
    for (int i = 0; i < 256; i++) x->wrf[i] = x->wr[i >> 4];
    if (x->vfast)
        for (int i = 0x80; i < 0xA0; i++) {
            uint8_t *m = i >= 0x9C ? x->vmir_hi : x->vmir_lo;
            uint32_t a = (uint32_t)i << 8;
            x->wrf[i] = m && a < x->vmir_a1 && a + 0x100 > x->vmir_a0 ? NULL : i >= 0x9C ? x->vhi : x->vlo;
        }
    for (int i = 0; i < g->nwatch; i++)
        if ((g->watch_addr[i] & 0xE000) == 0xC000) x->wrf[g->watch_addr[i] >> 8] = NULL;

    gbc_exec_prepare_time(g);
}

/* the flags of the x64 version: from LAHF (bit 6 ZF, bit 4 AF, bit 0 CF) after an addition or a
 * subtraction, or from the result */
void gbc_exec_tables(GBC *g)
{
    GBCFast *x = &g->fast;
    for (int i = 0; i < 256; i++) {
        uint8_t f = (uint8_t)(((i & 0x40) ? FZ : 0) | ((i & 0x10) ? FH : 0) | ((i & 0x01) ? FC : 0));
        x->t_add[i] = f;
        x->t_sub[i] = (uint8_t)(f | FN);
        x->t_inc[i] = (uint8_t)((i ? 0 : FZ) | ((i & 0xF) == 0 ? FH : 0));
        x->t_dec[i] = (uint8_t)(FN | (i ? 0 : FZ) | ((i & 0xF) == 0xF ? FH : 0));
        x->t_z[i] = i ? 0 : FZ;
        x->t_zh[i] = (uint8_t)((i ? 0 : FZ) | FH);
    }
    x->tables_ok = 1;
}

/* ------------------------------------------------------------------ the interpreter */

#define BC() ((uint16_t)((b << 8) | c))
#define DE() ((uint16_t)((d << 8) | e))
#define HL() ((uint16_t)((h << 8) | l))
#define SETBC(v) do { uint16_t v_ = (uint16_t)(v); b = (uint8_t)(v_ >> 8); c = (uint8_t)v_; } while (0)
#define SETDE(v) do { uint16_t v_ = (uint16_t)(v); d = (uint8_t)(v_ >> 8); e = (uint8_t)v_; } while (0)
#define SETHL(v) do { uint16_t v_ = (uint16_t)(v); h = (uint8_t)(v_ >> 8); l = (uint8_t)v_; } while (0)

/* the CPU registers back into the machine state, and the time (in frozen mode the time does not
 * pass: the cycle counter and the divider of the state stay as they are) */
#define FLUSH_TIME() do { if (!g->frozen) { s->cycles = cyc; s->div16 = (uint16_t)(x->div_base + (uint16_t)cyc); } } while (0)
#define FLUSH() do { s->pc = (uint16_t)pc; s->sp = (uint16_t)sp; s->a = a; s->f = f; s->b = b; s->c = c; \
                     s->d = d; s->e = e; s->h = h; s->l = l; FLUSH_TIME(); } while (0)
/* after a call: everything may have changed; with a trace function installed, the original
 * interpreter takes over (it calls it before each instruction) */
#define RELOAD() do { gbc_exec_prepare(g); pc = s->pc; sp = s->sp; a = s->a; f = s->f; b = s->b; c = s->c; \
                      d = s->d; e = s->e; h = s->h; l = s->l; cyc = s->cycles; if (g->trace_fn) trace = true; } while (0)

/* t cycles pass (tick of gbc.c; it changes neither the registers nor the memory map) */
#define TICK(t) do { if (!g->frozen) { cyc += (t); if (cyc >= x->deadline) { STAT(gbc_stat_tick++); cyc -= (t); FLUSH(); gbc_tick(g, (t)); \
                                                                      gbc_exec_prepare_time(g); cyc = s->cycles; } } } while (0)

/* a read by the CPU (rd8 of gbc.c: the time passes first) */
#define RD(dst, addr) do { uint16_t a_ = (uint16_t)(addr); TICK(4); const uint8_t *p_ = x->rd[a_ >> 12]; \
                           if (p_) (dst) = p_[a_]; \
                           else if (a_ >= 0xFF80 && a_ < 0xFFFF) (dst) = s->hram[a_ - 0xFF80]; \
                           else if (a_ >= 0xFE00 && a_ < 0xFEA0) (dst) = x->oam[a_ - 0xFE00]; \
                           else if (a_ == 0xFF44 && !g->frozen) (dst) = x->ff44; \
                           else if (a_ == 0xFF41 && !g->frozen) (dst) = x->ff41; \
                           else { STAT(gbc_stat_rd_slow[a_ >> 12]++); STAT(a_ >= 0xFF00 && a_ < 0xFF80 ? gbc_stat_rd_io[a_ & 0x7F]++ : 0); FLUSH_TIME(); (dst) = gbc_read(g, a_); } } while (0)
/* a write by the CPU (wr8 of gbc.c) */
#define WR(addr, val) do { uint16_t a_ = (uint16_t)(addr); uint8_t v_ = (uint8_t)(val); TICK(4); uint8_t *p_ = x->wr[a_ >> 12]; \
                           if (p_ && !(x->watch && (a_ & 0xE000) == 0xC000 && x->watch[a_ & 0x1FFF])) p_[a_] = v_; \
                           else if (a_ >= 0xFF80 && a_ < 0xFFFF) s->hram[a_ - 0xFF80] = v_; \
                           else if (a_ >= 0xFE00 && a_ < 0xFEA0) x->oam[a_ - 0xFE00] = v_; \
                           else if ((a_ & 0xE000) == 0x8000 && x->vfast) vram_write(x, a_, v_); \
                           else if ((a_ & 0xE000) == 0x2000 && x->mbc5) mbc5_write(g, a_, v_); \
                           else { STAT(gbc_stat_wr_slow[a_ >> 12]++); STAT(a_ >= 0xFF00 && a_ < 0xFF80 ? gbc_stat_wr_io[a_ & 0x7F]++ : 0); FLUSH(); gbc_write(g, a_, v_); RELOAD(); } } while (0)
#define FETCH8(dst) do { RD(dst, pc); pc = (uint16_t)(pc + 1); } while (0)
#define FETCH16(dst) do { uint8_t lo_, hi_; FETCH8(lo_); FETCH8(hi_); (dst) = (uint16_t)(lo_ | (hi_ << 8)); } while (0)
#define PUSH16(val) do { uint16_t w_ = (uint16_t)(val); sp = (uint16_t)(sp - 1); WR(sp, w_ >> 8); sp = (uint16_t)(sp - 1); WR(sp, w_); } while (0)
#define POP16(dst) do { uint8_t lo_, hi_; RD(lo_, sp); sp = (uint16_t)(sp + 1); RD(hi_, sp); sp = (uint16_t)(sp + 1); (dst) = (uint16_t)(lo_ | (hi_ << 8)); } while (0)

/* register i of an instruction (B C D E H L (HL) A) */
#define GETR(dst, i) do { switch (i) { case 0: (dst) = b; break; case 1: (dst) = c; break; case 2: (dst) = d; break; \
                          case 3: (dst) = e; break; case 4: (dst) = h; break; case 5: (dst) = l; break; \
                          case 6: RD(dst, HL()); break; default: (dst) = a; break; } } while (0)
#define SETR(i, val) do { uint8_t sv_ = (uint8_t)(val); switch (i) { case 0: b = sv_; break; case 1: c = sv_; break; \
                          case 2: d = sv_; break; case 3: e = sv_; break; case 4: h = sv_; break; case 5: l = sv_; break; \
                          case 6: WR(HL(), sv_); break; default: a = sv_; break; } } while (0)

/* gbc_write for the video memory (no vram_fn) and the ROM bank of an MBC5, without the call */
static inline void vram_write(GBCFast *x, uint16_t a, uint8_t v)
{
    uint8_t *p = a >= 0x9C00 ? x->vhi : x->vlo, *m = a >= 0x9C00 ? x->vmir_hi : x->vmir_lo;
    p[a] = v;
    if (m && a >= x->vmir_a0 && a < x->vmir_a1) m[a] = v;
}

static inline void mbc5_write(GBC *g, uint16_t a, uint8_t v)
{
    GBCState *s = &g->s;
    s->rom_bank = a < 0x3000 ? (uint16_t)((s->rom_bank & 0x100) | v) : (uint16_t)((s->rom_bank & 0xFF) | ((v & 1) << 8));
    const uint8_t *romx = bias(g->rom + ((size_t)(s->rom_bank & g->rom_mask) << 14), 0x4000);
    for (int i = 4; i < 8; i++) g->fast.rd[i] = romx;
}

/* Loops of the game run whole iterations at once (idle_loop, copy_loop): the loop at pc (code
 * `pat`, n bytes, in ROM), its iterations of `steps` instructions and `cycles` cycles. How many
 * of them gbc_exec_c would run in a row with nothing else happening: no step of it needing
 * more (interrupt, EI, trace, hook, stop address), every tick before the deadline and the end
 * of the frame, within the budget. */
static uint64_t loop_room(GBC *g, uint32_t pc, const uint8_t *pat, int n, int steps, int cycles, uint64_t cyc, int mode,
                          uint16_t stop_pc, const int64_t *budget, uint64_t start)
{
    GBCFast *x = &g->fast;
    GBCState *s = &g->s;
    /* what the loop of gbc_exec_c looks at before each step (the tick of the jump may have changed it) */
    if (s->ei_pending || s->halt_bug || (s->ime && (s->ie & s->ifl & 0x1F) && !g->frozen) || g->trace_fn ||
        (mode == GBC_EXEC_FRAME && g->frame_done))
        return 0;
    const uint8_t *p = x->rd[pc >> 12];
    if (!p || pc >= 0x8000 || (pc & 0xFFF) > (uint32_t)(0x1000 - n) || memcmp(p + pc, pat, (size_t)n)) return 0;
    for (int i = 0; i < n - 1; i++)
        if (g->nhooks && (g->hookbyte[pc + i] & 1)) return 0;
    if (mode == GBC_EXEC_CALL && stop_pc >= pc && stop_pc < pc + n - 1) return 0;
    uint64_t k = UINT64_MAX / 128;
    if (!g->frozen) {
        uint64_t end = x->deadline;
        if (mode == GBC_EXEC_FRAME && !(g->s.io[0x40] & 0x80) && start + GBC_FRAME_CYCLES < end) end = start + GBC_FRAME_CYCLES;
        if (end <= cyc + (uint64_t)cycles) return 0;
        k = (end - cyc - 1) / (uint64_t)cycles;
    } else if (mode == GBC_EXEC_FRAME) {
        return 0;
    }
    if (mode == GBC_EXEC_CALL && (uint64_t)(*budget < 0 ? 0 : *budget) / (uint64_t)steps < k) k = (uint64_t)*budget / (uint64_t)steps;
    return k;
}

/* The wait loop "ld a,[hl] / and a / jr z,-4" with [hl] = 0 (the game waits there for the VBlank
 * interrupt: a fifth of its instructions). Its iterations all do the same thing until the next
 * event of the hardware: nothing it reads can change. Returns how many whole iterations (3 steps,
 * 24 cycles) to count at once from pc (A = 0, F = Z H: the state they leave). */
static uint64_t idle_loop(GBC *g, uint32_t pc, uint16_t hl, uint64_t cyc, int mode, uint16_t stop_pc, const int64_t *budget,
                          uint64_t start)
{
    static const uint8_t pat[4] = { 0x7E, 0xA7, 0x28, 0xFC };
    GBCFast *x = &g->fast;
    const uint8_t *q = x->rd[hl >> 12];
    if (q ? q[hl] : !(hl >= 0xFF80 && hl < 0xFFFF) || g->s.hram[hl - 0xFF80]) return 0;
    return loop_room(g, pc, pat, 4, 3, 24, cyc, mode, stop_pc, budget, start);
}

/* The copy loop "ld a,[hl+] / ld [de],a / inc de / dec bc / ld a,c / or b / jr nz,-8" (the
 * game's copies to the video memory, most of them out of time: a fifth of its instructions).
 * Its iterations (7 steps, 52 cycles) are run here byte by byte, as long as the bytes need no
 * call (read and written without gbc_read, gbc_write) and the next one is not the last (the
 * jump not taken). Returns the number run; A, F are then C | B and 0. */
static uint64_t copy_loop(GBC *g, uint32_t pc, uint16_t *hl, uint16_t *de, uint16_t *bc, uint64_t cyc, int mode,
                          uint16_t stop_pc, const int64_t *budget, uint64_t start)
{
    static const uint8_t pat[8] = { 0x2A, 0x12, 0x13, 0x0B, 0x79, 0xB0, 0x20, 0xF8 };
    GBCFast *x = &g->fast;
    GBCState *s = &g->s;
    uint64_t k = loop_room(g, pc, pat, 8, 7, 52, cyc, mode, stop_pc, budget, start);
    uint64_t n = (uint16_t)(*bc - 1);                /* iterations with the jump taken */
    if (k > n) k = n;
    uint64_t i;
    for (i = 0; i < k; i++) {
        uint16_t src = *hl, dst = *de;
        const uint8_t *p = x->rd[src >> 12];
        uint8_t v;
        if (p) v = p[src];
        else if (src >= 0xFF80 && src < 0xFFFF) v = s->hram[src - 0xFF80];
        else break;
        uint8_t *w = x->wr[dst >> 12];
        if (w && !(x->watch && (dst & 0xE000) == 0xC000 && x->watch[dst & 0x1FFF])) w[dst] = v;
        else if (dst >= 0xFF80 && dst < 0xFFFF) s->hram[dst - 0xFF80] = v;
        else if ((dst & 0xE000) == 0x8000 && x->vfast) vram_write(x, dst, v);
        else break;
        *hl = (uint16_t)(src + 1);
        *de = (uint16_t)(dst + 1);
        *bc = (uint16_t)(*bc - 1);
    }
    return i;
}

#define COND(cc) ((cc) == 0 ? !(f & FZ) : (cc) == 1 ? (f & FZ) != 0 : (cc) == 2 ? !(f & FC) : (f & FC) != 0)

/* the eight operations of A with a value (ADD ADC SUB SBC AND XOR OR CP) */
static inline void alu8(int op, uint8_t v, uint8_t *pa, uint8_t *pf)
{
    uint8_t a = *pa, f = *pf;
    int r, cy;
    switch (op) {
    case 0: r = a + v; f = (uint8_t)(((r & 0xFF) ? 0 : FZ) | (((a & 0xF) + (v & 0xF)) > 0xF ? FH : 0) | (r > 0xFF ? FC : 0)); a = (uint8_t)r; break;
    case 1: cy = (f & FC) ? 1 : 0; r = a + v + cy;
        f = (uint8_t)(((r & 0xFF) ? 0 : FZ) | (((a & 0xF) + (v & 0xF) + cy) > 0xF ? FH : 0) | (r > 0xFF ? FC : 0)); a = (uint8_t)r; break;
    case 2: r = a - v; f = (uint8_t)(((r & 0xFF) ? 0 : FZ) | FN | ((a & 0xF) < (v & 0xF) ? FH : 0) | (r < 0 ? FC : 0)); a = (uint8_t)r; break;
    case 3: cy = (f & FC) ? 1 : 0; r = a - v - cy;
        f = (uint8_t)(((r & 0xFF) ? 0 : FZ) | FN | (((a & 0xF) - (v & 0xF) - cy) < 0 ? FH : 0) | (r < 0 ? FC : 0)); a = (uint8_t)r; break;
    case 4: a = a & v; f = (uint8_t)((a ? 0 : FZ) | FH); break;
    case 5: a = a ^ v; f = a ? 0 : FZ; break;
    case 6: a = a | v; f = a ? 0 : FZ; break;
    default: r = a - v; f = (uint8_t)(((r & 0xFF) ? 0 : FZ) | FN | ((a & 0xF) < (v & 0xF) ? FH : 0) | (r < 0 ? FC : 0)); break;
    }
    *pa = a;
    *pf = f;
}

/* mode | GBC_EXEC_ONE: one step (stop conditions, step, end of frame) then GBC_EXEC_MORE, for the
 * steps the assembly version hands over */
int gbc_exec_c(GBC *g, int mode, uint16_t stop_pc, uint16_t stop_sp, int64_t *budget, uint64_t start)
{
    GBCState *s = &g->s;
    GBCFast *x = &g->fast;
    uint32_t pc, sp;
    uint8_t a, f, b, c, d, e, h, l;
    uint64_t cyc;
    bool trace = false;
    bool one = (mode & GBC_EXEC_ONE) != 0;
    int result = GBC_EXEC_DONE;
    mode &= ~GBC_EXEC_ONE;
    RELOAD();

    for (;;) {
        if (trace) { result = GBC_EXEC_TRACE; break; }
        /* the stop conditions, before each step (the loops of gbc_call / gbc_run_frame) */
        if (mode == GBC_EXEC_CALL) {
            if (pc == stop_pc && sp == stop_sp) break;
            if (--*budget < 0) { result = GBC_EXEC_BUDGET; break; }
        } else if (g->frame_done) {
            break;
        }

        /* ---- gbc_step */
        STAT(gbc_stat_steps++);
        STAT(g->frozen ? gbc_stat_frozen_steps++ : 0);
        uint8_t pend = s->ie & s->ifl & 0x1F;
        if (s->halted) {
            if (!pend) {
                if (g->frozen) {
                    /* nothing ever happens: every step left only counts */
                    if (mode == GBC_EXEC_CALL) *budget = 0;
                    goto step_end;
                }
                /* the 4-cycle steps that end before the deadline only count the time: done at once */
                uint64_t n = x->deadline > cyc + 4 ? (x->deadline - cyc - 1) / 4 : 0;   /* cyc + 4n < deadline */
                STAT(gbc_stat_halt++);
                if (n >= 1) {
                    uint64_t total = n;
                    if (mode == GBC_EXEC_CALL) {
                        uint64_t extra = n - 1;
                        if (extra > (uint64_t)*budget) extra = (uint64_t)*budget;
                        *budget -= (int64_t)extra;
                        total = 1 + extra;
                    } else if (!(s->io[0x40] & 0x80)) {
                        /* the frame ends with the first step at 70224 cycles or more */
                        uint64_t m = cyc - start >= GBC_FRAME_CYCLES ? 1 : (start + GBC_FRAME_CYCLES - cyc + 3) / 4;
                        if (m < total) total = m;
                    }
                    cyc += 4 * total;
                    STAT(gbc_stat_halt_steps += total);
                    goto step_end;
                }
                TICK(4);
                goto step_end;
            }
            s->halted = false;
        }
        if (s->ime && pend && !g->frozen) {
            STAT(gbc_stat_irq++);
            int n = 0;
            while (!(pend & (1 << n))) n++;
            s->ime = false;
            TICK(8);
            PUSH16(pc);
            s->ifl &= (uint8_t)~(1 << n);
            pc = (uint16_t)(0x40 + 8 * n);
            TICK(4);
            if (g->irq_fn) { FLUSH(); g->irq_fn(g, n, g->irq_user); RELOAD(); }
            goto step_end;
        }
        if (s->ei_pending) { s->ime = true; s->ei_pending = false; }

        if (g->nhooks && pc < 0x8000 && (g->hookbyte[pc] & 1)) {
            STAT(gbc_stat_hook++);
            FLUSH();
            bool replaced = gbc_run_hooks(g);
            RELOAD();
            if (replaced) goto step_end;
        }

        uint8_t op;
        RD(op, pc);
        if (s->halt_bug) s->halt_bug = false; else pc = (uint16_t)(pc + 1);
        STAT(gbc_stat_op[op]++);
        STAT(gbc_stat_pc[g->frozen ? 1 : 0][(uint16_t)(pc - 1)]++);

        if (op >= 0x40 && op < 0x80) {
            if (op == 0x76) {
                if (!s->ime && (s->ie & s->ifl & 0x1F)) s->halt_bug = true;
                else s->halted = true;
            } else {
                uint8_t v;
                GETR(v, op & 7);
                SETR((op >> 3) & 7, v);
            }
            goto step_end;
        }
        if (op >= 0x80 && op < 0xC0) {
            uint8_t v;
            GETR(v, op & 7);
            alu8((op >> 3) & 7, v, &a, &f);
            goto step_end;
        }

        switch (op) {
        case 0x00: break;
        case 0x01: { uint16_t v; FETCH16(v); SETBC(v); } break;
        case 0x11: { uint16_t v; FETCH16(v); SETDE(v); } break;
        case 0x21: { uint16_t v; FETCH16(v); SETHL(v); } break;
        case 0x31: { uint16_t v; FETCH16(v); sp = v; } break;
        case 0x02: WR(BC(), a); break;
        case 0x12: WR(DE(), a); break;
        case 0x22: { uint16_t hl = HL(); WR(hl, a); SETHL(hl + 1); } break;
        case 0x32: { uint16_t hl = HL(); WR(hl, a); SETHL(hl - 1); } break;
        case 0x0A: RD(a, BC()); break;
        case 0x1A: RD(a, DE()); break;
        case 0x2A: { uint16_t hl = HL(); RD(a, hl); SETHL(hl + 1); } break;
        case 0x3A: { uint16_t hl = HL(); RD(a, hl); SETHL(hl - 1); } break;
        case 0x03: SETBC(BC() + 1); TICK(4); break;
        case 0x13: SETDE(DE() + 1); TICK(4); break;
        case 0x23: SETHL(HL() + 1); TICK(4); break;
        case 0x33: sp = (uint16_t)(sp + 1); TICK(4); break;
        case 0x0B: SETBC(BC() - 1); TICK(4); break;
        case 0x1B: SETDE(DE() - 1); TICK(4); break;
        case 0x2B: SETHL(HL() - 1); TICK(4); break;
        case 0x3B: sp = (uint16_t)(sp - 1); TICK(4); break;
        case 0x04: case 0x0C: case 0x14: case 0x1C: case 0x24: case 0x2C: case 0x34: case 0x3C: {
            int r = (op >> 3) & 7; uint8_t v; GETR(v, r);
            uint8_t res = (uint8_t)(v + 1);
            f = (uint8_t)((f & FC) | (res ? 0 : FZ) | ((v & 0xF) == 0xF ? FH : 0));
            SETR(r, res);
        } break;
        case 0x05: case 0x0D: case 0x15: case 0x1D: case 0x25: case 0x2D: case 0x35: case 0x3D: {
            int r = (op >> 3) & 7; uint8_t v; GETR(v, r);
            uint8_t res = (uint8_t)(v - 1);
            f = (uint8_t)((f & FC) | FN | (res ? 0 : FZ) | ((v & 0xF) == 0 ? FH : 0));
            SETR(r, res);
        } break;
        case 0x06: case 0x0E: case 0x16: case 0x1E: case 0x26: case 0x2E: case 0x36: case 0x3E: {
            uint8_t v; FETCH8(v); SETR((op >> 3) & 7, v); } break;
        case 0x07: { int cy = a >> 7; a = (uint8_t)((a << 1) | cy); f = cy ? FC : 0; } break;
        case 0x0F: { int cy = a & 1; a = (uint8_t)((a >> 1) | (cy << 7)); f = cy ? FC : 0; } break;
        case 0x17: { int cy = a >> 7; a = (uint8_t)((a << 1) | ((f & FC) ? 1 : 0)); f = cy ? FC : 0; } break;
        case 0x1F: { int cy = a & 1; a = (uint8_t)((a >> 1) | ((f & FC) ? 0x80 : 0)); f = cy ? FC : 0; } break;
        case 0x08: { uint16_t ad; FETCH16(ad); WR(ad, sp); WR((uint16_t)(ad + 1), sp >> 8); } break;
        case 0x09: case 0x19: case 0x29: case 0x39: {
            uint32_t hl = HL(), v = op == 0x09 ? BC() : op == 0x19 ? DE() : op == 0x29 ? hl : sp, r = hl + v;
            f = (uint8_t)((f & FZ) | (((hl & 0xFFF) + (v & 0xFFF)) > 0xFFF ? FH : 0) | (r > 0xFFFF ? FC : 0));
            SETHL(r);
            TICK(4);
        } break;
        case 0x10: { uint8_t v; FETCH8(v); (void)v; } break;            /* STOP: no speed switch in this game */
        case 0x18: { uint8_t v; FETCH8(v); pc = (uint16_t)(pc + (int8_t)v); TICK(4); } break;
        case 0x20: case 0x28: case 0x30: case 0x38: {
            uint8_t v; FETCH8(v);
            if (COND((op >> 3) & 3)) {
                pc = (uint16_t)(pc + (int8_t)v); TICK(4);
                if (op == 0x28 && v == 0xFC && a == 0 && f == (FZ | FH)) {
                    uint64_t k = idle_loop(g, pc, HL(), cyc, mode, stop_pc, budget, start);
                    if (!g->frozen) cyc += 24 * k;
                    if (mode == GBC_EXEC_CALL) *budget -= (int64_t)(3 * k);
                } else if (op == 0x20 && v == 0xF8) {
                    uint16_t hl = HL(), de = DE(), bc = BC();
                    uint64_t k = copy_loop(g, pc, &hl, &de, &bc, cyc, mode, stop_pc, budget, start);
                    if (k) {
                        SETHL(hl); SETDE(de); SETBC(bc);
                        a = (uint8_t)(c | b); f = 0;           /* ld a,c / or b */
                        if (!g->frozen) cyc += 52 * k;
                        if (mode == GBC_EXEC_CALL) *budget -= (int64_t)(7 * k);
                    }
                }
            }
        } break;
        case 0x27: {
            int av = a; bool cy = (f & FC) != 0;
            if (f & FN) {
                if (f & FH) av -= 0x06;
                if (cy) av -= 0x60;
            } else {
                if (cy || av > 0x99) { av += 0x60; cy = true; }
                if ((f & FH) || (av & 0x0F) > 0x09) av += 0x06;
            }
            a = (uint8_t)av;
            f = (uint8_t)((a ? 0 : FZ) | (f & FN) | (cy ? FC : 0));
        } break;
        case 0x2F: a = (uint8_t)~a; f |= FN | FH; break;
        case 0x37: f = (uint8_t)((f & FZ) | FC); break;
        case 0x3F: f = (uint8_t)((f & FZ) | ((f & FC) ? 0 : FC)); break;

        case 0xC0: case 0xC8: case 0xD0: case 0xD8:
            TICK(4);
            if (COND((op >> 3) & 3)) { uint16_t v; POP16(v); pc = v; TICK(4); }
            break;
        case 0xC9: { uint16_t v; POP16(v); pc = v; TICK(4); } break;
        case 0xD9: {
            uint16_t v; POP16(v); pc = v; TICK(4); s->ime = true;
            if (g->reti_fn) { FLUSH(); g->reti_fn(g, g->irq_user); RELOAD(); }
        } break;
        case 0xC1: { uint16_t v; POP16(v); SETBC(v); } break;
        case 0xD1: { uint16_t v; POP16(v); SETDE(v); } break;
        case 0xE1: { uint16_t v; POP16(v); SETHL(v); } break;
        case 0xF1: { uint16_t v; POP16(v); a = (uint8_t)(v >> 8); f = (uint8_t)(v & 0xF0); } break;
        case 0xC5: TICK(4); PUSH16(BC()); break;
        case 0xD5: TICK(4); PUSH16(DE()); break;
        case 0xE5: TICK(4); PUSH16(HL()); break;
        case 0xF5: TICK(4); PUSH16((uint16_t)((a << 8) | f)); break;
        case 0xC2: case 0xCA: case 0xD2: case 0xDA: {
            uint16_t ad; FETCH16(ad);
            if (COND((op >> 3) & 3)) { pc = ad; TICK(4); }
        } break;
        case 0xC3: { uint16_t ad; FETCH16(ad); pc = ad; TICK(4); } break;
        case 0xE9: pc = HL(); break;
        case 0xC4: case 0xCC: case 0xD4: case 0xDC: {
            uint16_t ad; FETCH16(ad);
            if (COND((op >> 3) & 3)) { TICK(4); PUSH16(pc); pc = ad; }
        } break;
        case 0xCD: { uint16_t ad; FETCH16(ad); TICK(4); PUSH16(pc); pc = ad; } break;
        case 0xC7: case 0xCF: case 0xD7: case 0xDF: case 0xE7: case 0xEF: case 0xF7: case 0xFF:
            TICK(4); PUSH16(pc); pc = (uint16_t)(op & 0x38); break;
        case 0xC6: case 0xCE: case 0xD6: case 0xDE: case 0xE6: case 0xEE: case 0xF6: case 0xFE: {
            uint8_t v; FETCH8(v); alu8((op >> 3) & 7, v, &a, &f); } break;
        case 0xE0: { uint8_t n; FETCH8(n); WR((uint16_t)(0xFF00 | n), a); } break;
        case 0xF0: { uint8_t n; FETCH8(n); RD(a, (uint16_t)(0xFF00 | n)); } break;
        case 0xE2: WR((uint16_t)(0xFF00 | c), a); break;
        case 0xF2: RD(a, (uint16_t)(0xFF00 | c)); break;
        case 0xEA: { uint16_t ad; FETCH16(ad); WR(ad, a); } break;
        case 0xFA: { uint16_t ad; FETCH16(ad); RD(a, ad); } break;
        case 0xE8: case 0xF8: {
            uint8_t u; FETCH8(u);
            uint16_t v = (uint16_t)(sp + (int8_t)u);
            f = (uint8_t)((((sp & 0xF) + (u & 0xF)) > 0xF ? FH : 0) | (((sp & 0xFF) + u) > 0xFF ? FC : 0));
            if (op == 0xE8) { sp = v; TICK(8); } else { SETHL(v); TICK(4); }
        } break;
        case 0xF9: sp = HL(); TICK(4); break;
        case 0xF3: s->ime = false; s->ei_pending = false; break;
        case 0xFB: s->ei_pending = true; break;
        case 0xCB: {
            uint8_t cb; FETCH8(cb);
            STAT(gbc_stat_op[256 + cb]++);
            int r = cb & 7, bit = (cb >> 3) & 7;
            uint8_t v; GETR(v, r);
            if (cb < 0x40) {
                uint8_t res; int cy;
                switch (bit) {
                case 0: cy = v >> 7; res = (uint8_t)((v << 1) | cy); break;
                case 1: cy = v & 1; res = (uint8_t)((v >> 1) | (cy << 7)); break;
                case 2: cy = v >> 7; res = (uint8_t)((v << 1) | ((f & FC) ? 1 : 0)); break;
                case 3: cy = v & 1; res = (uint8_t)((v >> 1) | ((f & FC) ? 0x80 : 0)); break;
                case 4: cy = v >> 7; res = (uint8_t)(v << 1); break;
                case 5: cy = v & 1; res = (uint8_t)((v >> 1) | (v & 0x80)); break;
                case 6: cy = 0; res = (uint8_t)((v << 4) | (v >> 4)); break;
                default: cy = v & 1; res = (uint8_t)(v >> 1); break;
                }
                f = (uint8_t)((res ? 0 : FZ) | (cy ? FC : 0));
                SETR(r, res);
            } else if (cb < 0x80) {
                f = (uint8_t)((f & FC) | FH | (((v >> bit) & 1) ? 0 : FZ));
            } else if (cb < 0xC0) {
                SETR(r, (uint8_t)(v & ~(1 << bit)));
            } else {
                SETR(r, (uint8_t)(v | (1 << bit)));
            }
        } break;
        default:
            break;                              /* illegal opcode: NOP (as gbc_step) */
        }

    step_end:
        if (mode == GBC_EXEC_FRAME && !(s->io[0x40] & 0x80) && cyc - start >= GBC_FRAME_CYCLES) break;
        if (one) { result = GBC_EXEC_MORE; break; }
    }
    FLUSH();
    return result;
}

/* ------------------------------------------------------------------ the assembly versions */

/* what they ask of the rest of the core: the time, a write, the instructions that change the
 * interrupt state (the next step may need the C interpreter: GBCFast.special) */
void gbc_asm_tick(GBC *g, int t)
{
    gbc_tick(g, t);
    gbc_exec_prepare_time(g);
}

void gbc_asm_write(GBC *g, uint16_t addr, uint8_t v)
{
    gbc_write(g, addr, v);
    gbc_exec_prepare(g);
}

void gbc_asm_op(GBC *g, int op)
{
    GBCState *s = &g->s;
    switch (op) {
    case 0x76:                                  /* HALT */
        if (!s->ime && (s->ie & s->ifl & 0x1F)) s->halt_bug = true;
        else s->halted = true;
        break;
    case 0xF3: s->ime = false; s->ei_pending = false; break;     /* DI */
    case 0xFB: s->ei_pending = true; break;                       /* EI */
    case 0xD9:                                  /* RETI, after the return */
        s->ime = true;
        if (g->reti_fn) g->reti_fn(g, g->irq_user);
        break;
    }
    gbc_exec_prepare(g);
}

#ifdef PB_ASM
#include "gbc_asm.h"

/* cpu_x64.asm / cpu_a64.S: runs steps until one needs the C interpreter (GBC_EXEC_MORE, before
 * its stop conditions), or a stop condition (GBC_EXEC_DONE, GBC_EXEC_BUDGET) */
int gbc_cpu_run(GBC *g, int64_t *budget);

bool gbc_exec_has_asm(void) { return true; }

int gbc_exec_asm(GBC *g, int mode, uint16_t stop_pc, uint16_t stop_sp, int64_t *budget, uint64_t start)
{
    GBCFast *x = &g->fast;
    uint32_t sv_pc = x->stop_pc, sv_sp = x->stop_sp;
    int32_t sv_mode = x->mode;
    uint64_t sv_start = x->start;
    int64_t none = INT64_MAX;
    uint8_t *mark = NULL, sv_mark = 0;
    if (!x->tables_ok) gbc_exec_tables(g);
    x->mode = mode;
    x->start = start;
    if (mode == GBC_EXEC_CALL) {
        /* the stop address is marked in the table of the hooks: one look before each step */
        x->stop_pc = stop_pc;
        x->stop_sp = stop_sp;
        mark = &g->hookbyte[stop_pc];
        sv_mark = *mark;
        *mark |= 2;
    } else {
        x->stop_pc = x->stop_sp = 0x10000;
        budget = &none;
    }
    int r;
    for (;;) {
        gbc_exec_prepare(g);
        r = gbc_cpu_run(g, budget);
        if (r != GBC_EXEC_MORE) break;
        r = gbc_exec_c(g, mode | GBC_EXEC_ONE, stop_pc, stop_sp, budget, start);
        if (r != GBC_EXEC_MORE) break;
    }
    if (mark) *mark = sv_mark;
    x->stop_pc = sv_pc;
    x->stop_sp = sv_sp;
    x->mode = sv_mode;
    x->start = sv_start;
    return r;
}
#else
/* no assembly version on this platform (or not built with it): the C one */
bool gbc_exec_has_asm(void) { return false; }
int gbc_exec_asm(GBC *g, int mode, uint16_t stop_pc, uint16_t stop_sp, int64_t *budget, uint64_t start)
{
    return gbc_exec_c(g, mode, stop_pc, stop_sp, budget, start);
}
#endif
