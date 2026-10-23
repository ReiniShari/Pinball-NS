/*
 * gbc.c - SM83 CPU, memory map (MBC5 + rumble), I/O, timer, serial, hooks.
 */
#include "gbc.h"
#include <string.h>

#define FZ 0x80
#define FN 0x40
#define FH 0x20
#define FC 0x10

#define MAGIC_RET 0xFEB0          /* return address used by gbc_call (unusable memory) */

static const int TAC_BIT[4] = { 9, 3, 5, 7 };

/* ------------------------------------------------------------------ timing */

static void serial_finish(GBC *g)
{
    GBCState *s = &g->s;
    s->serial_active = false;
    s->io[0x01] = 0xFF;           /* nothing connected */
    s->io[0x02] &= 0x7F;
    s->ifl |= 0x08;
}

int gbc_default_engine = GBC_ENGINE_AUTO;

static inline void tick(GBC *g, int t)
{
    GBCState *s = &g->s;
    if (g->frozen) return;
    uint32_t old = s->div16;
    s->cycles += (uint64_t)t;
    s->div16 = (uint16_t)(old + (uint32_t)t);
    if (s->tac & 4) {
        int bit = TAC_BIT[s->tac & 3] + 1;
        uint32_t cnt = ((old + (uint32_t)t) >> bit) - (old >> bit);
        while (cnt--) {
            if (++s->tima == 0) { s->tima = s->tma; s->ifl |= 0x04; }
        }
    }
    if (s->cycles >= s->ppu.next) gbc_ppu_update(g);
    if (s->serial_active && s->cycles >= s->serial_done) serial_finish(g);
}

void gbc_tick(GBC *g, int t) { tick(g, t); }

/* ------------------------------------------------------------------ memory */

/* the bank of the ROM mapped at 4000-7FFF (bank numbers wrap around the size of the ROM) */
static inline uint32_t rom_bank_index(const GBC *g)
{
    return g->rom_mask ? (g->s.rom_bank & g->rom_mask) : g->s.rom_bank % g->rom_banks;
}

static inline uint8_t *sram_ptr(GBCState *s, uint16_t a)
{
    return &s->sram[(((uint32_t)s->ram_bank << 13) | (a & 0x1FFFu)) & (s->sram_size - 1)];
}

uint8_t gbc_read(GBC *g, uint16_t a)
{
    GBCState *s = &g->s;
    if (a < 0x4000) return g->rom[a];
    if (a < 0x8000) return g->rom[(rom_bank_index(g) << 14) | (a & 0x3FFFu)];
    if (a < 0xA000) return s->page[s->cpu_page].vram[s->vbk & 1][a & 0x1FFF];
    if (a < 0xC000) return (s->ram_enable && s->sram_size) ? *sram_ptr(s, a) : 0xFF;
    if (a < 0xD000) return s->wram[a & 0xFFF];
    if (a < 0xE000) return s->wram[((uint32_t)s->wram_bank << 12) | (a & 0xFFF)];
    if (a < 0xF000) return s->wram[a & 0xFFF];
    if (a < 0xFE00) return s->wram[((uint32_t)s->wram_bank << 12) | (a & 0xFFF)];
    if (a < 0xFEA0) return s->page[s->cpu_page].oam[a - 0xFE00];
    if (a < 0xFF00) return 0x00;
    if (a < 0xFF80) return gbc_io_read(g, a);
    if (a < 0xFFFF) return s->hram[a - 0xFF80];
    return s->ie;
}

static void wram_written(GBC *g, uint16_t a, uint8_t v)
{
    for (int i = 0; i < g->nwatch; i++)
        if (g->watch_addr[i] == a) g->watch_fn[i](g, a, v, g->watch_user[i]);
}

void gbc_write(GBC *g, uint16_t a, uint8_t v)
{
    GBCState *s = &g->s;
    if (a < 0x8000) {
        if (a < 0x2000) s->ram_enable = (v & 0x0F) == 0x0A;
        else if (g->rom[0x147] >= 0x01 && g->rom[0x147] <= 0x03) {   /* MBC1 (test ROMs only) */
            if (a < 0x4000) { uint8_t b = v & 0x1F; s->rom_bank = (uint16_t)(b ? b : 1); }
            else if (a < 0x6000) s->ram_bank = v & 3;
        }
        else if (a < 0x3000) s->rom_bank = (uint16_t)((s->rom_bank & 0x100) | v);
        else if (a < 0x4000) s->rom_bank = (uint16_t)((s->rom_bank & 0xFF) | ((v & 1) << 8));
        else if (a < 0x6000) {
            bool rumble_cart = g->rom[0x147] >= 0x1C && g->rom[0x147] <= 0x1E;
            s->ram_bank = (uint8_t)(v & (rumble_cart ? 0x07 : 0x0F));
            s->rumble = rumble_cart && (v & 0x08);
        }
        return;
    }
    if (a < 0xA000) {
        uint16_t off = (uint16_t)(a & 0x1FFF);
        int p = (a >= 0x9C00 && g->win_page >= 0) ? g->win_page : s->cpu_page;
        s->page[p].vram[s->vbk & 1][off] = v;
        if (g->vram_fn) g->vram_fn(g, p, s->vbk & 1, off, v, g->vram_user);
        if (g->tile_mirror_page >= 0 && g->tile_mirror_page != p && g->frozen <= g->stretch &&
            off >= g->tile_mirror_lo && off < g->tile_mirror_hi) {
            s->page[g->tile_mirror_page].vram[s->vbk & 1][off] = v;
            if (g->vram_fn) g->vram_fn(g, g->tile_mirror_page, s->vbk & 1, off, v, g->vram_user);
        }
        return;
    }
    if (a < 0xC000) { if (s->ram_enable && s->sram_size) *sram_ptr(s, a) = v; return; }
    if (a < 0xD000) {
        s->wram[a & 0xFFF] = v;
        if (g->nwatch) wram_written(g, a, v);
        if (g->wram_fn) g->wram_fn(g, a, v, g->wram_user);
        return;
    }
    if (a < 0xE000) {
        s->wram[((uint32_t)s->wram_bank << 12) | (a & 0xFFF)] = v;
        if (g->nwatch) wram_written(g, a, v);
        return;
    }
    if (a < 0xF000) { s->wram[a & 0xFFF] = v; return; }
    if (a < 0xFE00) { s->wram[((uint32_t)s->wram_bank << 12) | (a & 0xFFF)] = v; return; }
    if (a < 0xFEA0) { s->page[s->cpu_page].oam[a - 0xFE00] = v; return; }
    if (a < 0xFF00) return;
    if (a < 0xFF80) { gbc_io_write(g, a, v); return; }
    if (a < 0xFFFF) { s->hram[a - 0xFF80] = v; return; }
    s->ie = v;
}

/* ------------------------------------------------------------------ I/O */

uint8_t gbc_io_read(GBC *g, uint16_t a)
{
    GBCState *s = &g->s;
    uint8_t r = (uint8_t)(a & 0x7F);
    if (r >= 0x10 && r < 0x40) return gbc_apu_read(g, a);
    switch (r) {
    case 0x00: {
        uint8_t sel = s->io[0x00] & 0x30, v = (uint8_t)(0xCF | sel);
        if (!(sel & 0x10)) v &= (uint8_t)~((s->buttons >> 4) & 0x0F);
        if (!(sel & 0x20)) v &= (uint8_t)~(s->buttons & 0x0F);
        return v;
    }
    case 0x01: return s->io[0x01];
    case 0x02: return s->io[0x02] | 0x7C;
    case 0x04: return (uint8_t)(s->div16 >> 8);
    case 0x05: return s->tima;
    case 0x06: return s->tma;
    case 0x07: return s->tac | 0xF8;
    case 0x0F: return s->ifl | 0xE0;
    case 0x40: return g->fake_lcd_off ? (uint8_t)(s->io[0x40] & 0x7F) : s->io[0x40];
    case 0x41: {
        uint8_t v = (uint8_t)(0x80 | (s->io[0x41] & 0x78));
        if (g->frozen) {                 /* time is frozen: a virtual scan that always progresses */
            g->fake_phase = (uint8_t)((g->fake_phase + 1) % 3);
            /* modes 2, 3, 0, then the next line: a wait for an HBlank begun in the VBlank lines
             * (mode 1) ends too (it looped until the call's budget was spent: palettes loaded
             * during the evolution mode, 0x060F) */
            if (g->fake_phase == 0) g->fake_ly = (uint8_t)((g->fake_ly + 1) % 154);
            if (g->fake_ly == s->io[0x45]) v |= 0x04;
            v |= g->fake_ly >= 144 ? 1 : (uint8_t)("\x02\x03\x00"[g->fake_phase]);
            return v;
        }
        if ((s->io[0x40] & 0x80) && !g->fake_lcd_off) {
            if (s->ppu.ly == s->io[0x45]) v |= 0x04;
            v |= (uint8_t)(s->ppu.mode & 3);
        }
        return v;
    }
    case 0x44:
        if (g->frozen) { g->fake_ly = (uint8_t)((g->fake_ly + 1) % 154); return g->fake_ly; }
        return ((s->io[0x40] & 0x80) && !g->fake_lcd_off) ? s->ppu.ly : 0;
    case 0x4D: return 0x7E | (s->io[0x4D] & 1);
    case 0x4F: return 0xFE | s->vbk;
    case 0x51: case 0x52: case 0x53: case 0x54: case 0x55: return 0xFF;
    case 0x56: return (uint8_t)((s->io[0x56] & 0xC1) | 0x3E);   /* infrared: no light received */
    case 0x68: return s->bcps | 0x40;
    case 0x69: return s->page[s->cpu_page].bgpal[s->bcps & 0x3F];
    case 0x6A: return s->ocps | 0x40;
    case 0x6B: return s->page[s->cpu_page].obpal[s->ocps & 0x3F];
    case 0x70: return 0xF8 | (s->io[0x70] & 7);
    case 0x42: case 0x43: case 0x45: case 0x46: case 0x47:
    case 0x48: case 0x49: case 0x4A: case 0x4B:
        return s->io[r];
    default:
        return 0xFF;
    }
}

void gbc_io_write(GBC *g, uint16_t a, uint8_t v)
{
    GBCState *s = &g->s;
    uint8_t r = (uint8_t)(a & 0x7F);
    if (r >= 0x10 && r < 0x40) { gbc_apu_write(g, a, v); return; }
    switch (r) {
    case 0x00: s->io[0x00] = v & 0x30; break;
    case 0x01: s->io[0x01] = v; break;
    case 0x02:
        s->io[0x02] = v;
        if ((v & 0x81) == 0x81) {
            if (g->serial_out) g->serial_out(s->io[0x01], g->serial_user);
            s->serial_active = true;
            s->serial_done = s->cycles + ((v & 0x02) ? 8u * 16u : 8u * 512u);
        }
        break;
    case 0x04: {
        if ((s->tac & 4) && (s->div16 & (1u << TAC_BIT[s->tac & 3]))) {
            if (++s->tima == 0) { s->tima = s->tma; s->ifl |= 0x04; }
        }
        s->div16 = 0;
        break;
    }
    case 0x05: s->tima = v; break;
    case 0x06: s->tma = v; break;
    case 0x07: {
        bool old_sig = (s->tac & 4) && (s->div16 & (1u << TAC_BIT[s->tac & 3]));
        bool new_sig = (v & 4) && (s->div16 & (1u << TAC_BIT[v & 3]));
        if (old_sig && !new_sig) { if (++s->tima == 0) { s->tima = s->tma; s->ifl |= 0x04; } }
        s->tac = v & 7;
        break;
    }
    case 0x0F: s->ifl = v & 0x1F; break;
    case 0x40: gbc_ppu_lcdc_write(g, v); break;
    case 0x41: s->io[0x41] = v & 0x78; gbc_ppu_stat_check(g); break;
    case 0x44: break;
    case 0x45: s->io[0x45] = v; gbc_ppu_stat_check(g); break;
    case 0x46: {
        s->io[0x46] = v;
        if (g->dma_fn) { g->dma_fn(g, v, g->dma_user); break; }
        uint16_t src = (uint16_t)(v << 8);
        uint8_t *oam = s->page[s->cpu_page].oam;
        for (int i = 0; i < 0xA0; i++) oam[i] = gbc_read(g, (uint16_t)(src + i));
        break;
    }
    case 0x4D: s->io[0x4D] = v & 1; break;
    case 0x4F: s->vbk = v & 1; break;
    case 0x56: s->io[0x56] = v; break;
    case 0x68: s->bcps = v & 0xBF; break;
    case 0x69:
        s->page[s->cpu_page].bgpal[s->bcps & 0x3F] = v;
        if (s->bcps & 0x80) s->bcps = (uint8_t)(0x80 | ((s->bcps + 1) & 0x3F));
        break;
    case 0x6A: s->ocps = v & 0xBF; break;
    case 0x6B:
        s->page[s->cpu_page].obpal[s->ocps & 0x3F] = v;
        if (s->ocps & 0x80) s->ocps = (uint8_t)(0x80 | ((s->ocps + 1) & 0x3F));
        break;
    case 0x70: s->io[0x70] = v & 7; s->wram_bank = (v & 7) ? (v & 7) : 1; break;
    default: s->io[r] = v; break;
    }
}

/* ------------------------------------------------------------------ CPU helpers */

/* reads by the CPU: the ROM (instructions, most of the reads) without the call */
static inline uint8_t rd8(GBC *g, uint16_t a)
{
    tick(g, 4);
    if (a < 0x4000) return g->rom[a];
    if (a < 0x8000) return g->rom[(rom_bank_index(g) << 14) | (a & 0x3FFFu)];
    return gbc_read(g, a);
}
static inline void wr8(GBC *g, uint16_t a, uint8_t v) { tick(g, 4); gbc_write(g, a, v); }
static inline uint8_t fetch8(GBC *g) { return rd8(g, g->s.pc++); }
static inline uint16_t fetch16(GBC *g) { uint8_t lo = fetch8(g); uint8_t hi = fetch8(g); return (uint16_t)(lo | (hi << 8)); }

static inline void push16(GBC *g, uint16_t v)
{
    GBCState *s = &g->s;
    wr8(g, --s->sp, (uint8_t)(v >> 8));
    wr8(g, --s->sp, (uint8_t)v);
}

static inline uint16_t pop16(GBC *g)
{
    GBCState *s = &g->s;
    uint8_t lo = rd8(g, s->sp++);
    uint8_t hi = rd8(g, s->sp++);
    return (uint16_t)(lo | (hi << 8));
}

#define BC() ((uint16_t)((s->b << 8) | s->c))
#define DE() ((uint16_t)((s->d << 8) | s->e))
#define HL() ((uint16_t)((s->h << 8) | s->l))
#define SETBC(v) do { uint16_t v_ = (uint16_t)(v); s->b = (uint8_t)(v_ >> 8); s->c = (uint8_t)v_; } while (0)
#define SETDE(v) do { uint16_t v_ = (uint16_t)(v); s->d = (uint8_t)(v_ >> 8); s->e = (uint8_t)v_; } while (0)
#define SETHL(v) do { uint16_t v_ = (uint16_t)(v); s->h = (uint8_t)(v_ >> 8); s->l = (uint8_t)v_; } while (0)

static inline uint8_t getr(GBC *g, int i)
{
    GBCState *s = &g->s;
    switch (i) {
    case 0: return s->b; case 1: return s->c; case 2: return s->d; case 3: return s->e;
    case 4: return s->h; case 5: return s->l; case 6: return rd8(g, HL()); default: return s->a;
    }
}

static inline void setr(GBC *g, int i, uint8_t v)
{
    GBCState *s = &g->s;
    switch (i) {
    case 0: s->b = v; break; case 1: s->c = v; break; case 2: s->d = v; break; case 3: s->e = v; break;
    case 4: s->h = v; break; case 5: s->l = v; break; case 6: wr8(g, HL(), v); break; default: s->a = v; break;
    }
}

static inline void alu(GBCState *s, int op, uint8_t v)
{
    uint8_t a = s->a;
    int r, c;
    switch (op) {
    case 0: r = a + v; s->f = (uint8_t)(((r & 0xFF) ? 0 : FZ) | (((a & 0xF) + (v & 0xF)) > 0xF ? FH : 0) | (r > 0xFF ? FC : 0)); s->a = (uint8_t)r; break;
    case 1: c = (s->f & FC) ? 1 : 0; r = a + v + c;
        s->f = (uint8_t)(((r & 0xFF) ? 0 : FZ) | (((a & 0xF) + (v & 0xF) + c) > 0xF ? FH : 0) | (r > 0xFF ? FC : 0)); s->a = (uint8_t)r; break;
    case 2: r = a - v; s->f = (uint8_t)(((r & 0xFF) ? 0 : FZ) | FN | ((a & 0xF) < (v & 0xF) ? FH : 0) | (r < 0 ? FC : 0)); s->a = (uint8_t)r; break;
    case 3: c = (s->f & FC) ? 1 : 0; r = a - v - c;
        s->f = (uint8_t)(((r & 0xFF) ? 0 : FZ) | FN | (((a & 0xF) - (v & 0xF) - c) < 0 ? FH : 0) | (r < 0 ? FC : 0)); s->a = (uint8_t)r; break;
    case 4: s->a = a & v; s->f = (uint8_t)((s->a ? 0 : FZ) | FH); break;
    case 5: s->a = a ^ v; s->f = s->a ? 0 : FZ; break;
    case 6: s->a = a | v; s->f = s->a ? 0 : FZ; break;
    default: r = a - v; s->f = (uint8_t)(((r & 0xFF) ? 0 : FZ) | FN | ((a & 0xF) < (v & 0xF) ? FH : 0) | (r < 0 ? FC : 0)); break;
    }
}

static inline uint8_t rot(GBCState *s, int op, uint8_t v)
{
    uint8_t r; int c;
    switch (op) {
    case 0: c = v >> 7; r = (uint8_t)((v << 1) | c); break;
    case 1: c = v & 1; r = (uint8_t)((v >> 1) | (c << 7)); break;
    case 2: c = v >> 7; r = (uint8_t)((v << 1) | ((s->f & FC) ? 1 : 0)); break;
    case 3: c = v & 1; r = (uint8_t)((v >> 1) | ((s->f & FC) ? 0x80 : 0)); break;
    case 4: c = v >> 7; r = (uint8_t)(v << 1); break;
    case 5: c = v & 1; r = (uint8_t)((v >> 1) | (v & 0x80)); break;
    case 6: c = 0; r = (uint8_t)((v << 4) | (v >> 4)); break;
    default: c = v & 1; r = (uint8_t)(v >> 1); break;
    }
    s->f = (uint8_t)((r ? 0 : FZ) | (c ? FC : 0));
    return r;
}

static inline uint8_t inc8(GBCState *s, uint8_t v)
{
    uint8_t r = (uint8_t)(v + 1);
    s->f = (uint8_t)((s->f & FC) | (r ? 0 : FZ) | ((v & 0xF) == 0xF ? FH : 0));
    return r;
}

static inline uint8_t dec8(GBCState *s, uint8_t v)
{
    uint8_t r = (uint8_t)(v - 1);
    s->f = (uint8_t)((s->f & FC) | FN | (r ? 0 : FZ) | ((v & 0xF) == 0 ? FH : 0));
    return r;
}

static inline void add_hl(GBC *g, uint16_t v)
{
    GBCState *s = &g->s;
    uint32_t hl = HL(), r = hl + v;
    s->f = (uint8_t)((s->f & FZ) | (((hl & 0xFFF) + (v & 0xFFF)) > 0xFFF ? FH : 0) | (r > 0xFFFF ? FC : 0));
    SETHL(r);
    tick(g, 4);
}

static inline uint16_t sp_plus(GBCState *s, int8_t e)
{
    uint16_t sp = s->sp;
    uint8_t u = (uint8_t)e;
    s->f = (uint8_t)((((sp & 0xF) + (u & 0xF)) > 0xF ? FH : 0) | (((sp & 0xFF) + u) > 0xFF ? FC : 0));
    return (uint16_t)(sp + e);
}

static inline bool cond(GBCState *s, int cc)
{
    switch (cc) {
    case 0: return !(s->f & FZ);
    case 1: return (s->f & FZ) != 0;
    case 2: return !(s->f & FC);
    default: return (s->f & FC) != 0;
    }
}

/* ------------------------------------------------------------------ hooks */

int gbc_add_hook(GBC *g, int bank, uint16_t addr, GBCHookFn fn, void *user)
{
    if (g->nhooks >= GBC_MAX_HOOKS || addr >= 0x8000) return -1;
    GBCHook *h = &g->hooks[g->nhooks++];
    h->bank = (addr < 0x4000) ? -1 : bank;
    h->addr = addr; h->fn = fn; h->user = user;
    g->hookmap[addr >> 3] |= (uint8_t)(1u << (addr & 7));
    g->hookbyte[addr] = 1;
    return 0;
}

int gbc_add_watch(GBC *g, uint16_t addr, GBCWatchFn fn, void *user)
{
    if (g->nwatch >= 8) return -1;
    g->watch_addr[g->nwatch] = addr; g->watch_fn[g->nwatch] = fn; g->watch_user[g->nwatch] = user;
    g->nwatch++;
    if ((addr & 0xE000) == 0xC000) g->watchbyte[addr & 0x1FFF] = 1;   /* gbc_write looks at C000-DFFF */
    return 0;
}

bool gbc_run_hooks(GBC *g)
{
    GBCState *s = &g->s;
    uint16_t pc = s->pc;
    if (g->hook_skip == pc) { g->hook_skip = -1; return false; }
    int bank = pc < 0x4000 ? -1 : (int)rom_bank_index(g);
    for (int i = 0; i < g->nhooks; i++) {
        GBCHook *h = &g->hooks[i];
        if (h->addr == pc && (h->bank < 0 || h->bank == bank))
            if (h->fn(g, h->user)) return true;
    }
    return false;
}

void gbc_push(GBC *g, uint16_t v)
{
    GBCState *s = &g->s;
    gbc_write(g, --s->sp, (uint8_t)(v >> 8));
    gbc_write(g, --s->sp, (uint8_t)v);
}

uint16_t gbc_pop(GBC *g)
{
    GBCState *s = &g->s;
    uint8_t lo = gbc_read(g, s->sp++);
    uint8_t hi = gbc_read(g, s->sp++);
    return (uint16_t)(lo | (hi << 8));
}

void gbc_ret(GBC *g) { g->s.pc = gbc_pop(g); }

void gbc_set_rom_bank(GBC *g, uint16_t bank) { g->s.rom_bank = bank; }

/* the engines: the fast interpreter (assembly or C), or the reference one, which also takes over
 * when a trace function is installed (it is called before each instruction) */
int gbc_exec(GBC *g, int mode, uint16_t stop_pc, uint16_t stop_sp, int64_t *budget, uint64_t start)
{
    GBCState *s = &g->s;
    int r = GBC_EXEC_TRACE;
    if (!g->trace_fn && g->engine != GBC_ENGINE_REF)
        r = g->engine == GBC_ENGINE_AUTO && gbc_exec_has_asm() ? gbc_exec_asm(g, mode, stop_pc, stop_sp, budget, start)
                                                               : gbc_exec_c(g, mode, stop_pc, stop_sp, budget, start);
    if (r != GBC_EXEC_TRACE) return r;
    for (;;) {
        if (mode == GBC_EXEC_CALL) {
            if (s->pc == stop_pc && s->sp == stop_sp) return GBC_EXEC_DONE;
            if (--*budget < 0) return GBC_EXEC_BUDGET;
        } else if (g->frame_done) {
            return GBC_EXEC_DONE;
        }
        gbc_step(g);
        if (mode == GBC_EXEC_FRAME && !(s->io[0x40] & 0x80) && s->cycles - start >= GBC_FRAME_CYCLES) return GBC_EXEC_DONE;
    }
}

/* Steps that cannot reach the end of the frame (the line 144, the VBlank interrupt): a step takes
 * 24 cycles at most, 44 with the dispatch of an interrupt. -1: no end of frame to come (the LCD off,
 * already in the VBlank). */
static int64_t frame_room(const GBC *g)
{
    const GBCState *s = &g->s;
    if (!(s->io[0x40] & 0x80) || s->ppu.ly >= 144 || s->ppu.mode < 0) return -1;
    uint64_t end = s->ppu.line_start + (uint64_t)(144 - s->ppu.ly) * 456;
    return end > s->cycles ? (int64_t)((end - s->cycles - 1) / 44) : 0;
}

bool gbc_call(GBC *g, uint16_t addr)
{
    GBCState *s = &g->s;
    uint16_t sp0 = s->sp, pc0 = s->pc;
    gbc_push(g, MAGIC_RET);
    s->pc = addr;
    g->call_depth++;
    int64_t budget = GBC_CALL_BUDGET;
    int r = GBC_EXEC_BUDGET;
    int64_t room;
    if (g->call_in_frame && !g->frozen && (room = frame_room(g)) >= 0) {
        /* in time by slices that end before the end of the frame, then frozen (no time, no
         * interrupts) once it is near: the VBlank comes after the routine */
        while (budget > 0 && room >= 8) {
            int64_t slice = room < budget ? room : budget, left = slice;
            r = gbc_exec(g, GBC_EXEC_CALL, MAGIC_RET, sp0, &left, 0);
            budget -= slice - (left < 0 ? 0 : left);
            if (r != GBC_EXEC_BUDGET || (room = frame_room(g)) < 0) break;
        }
        if (r == GBC_EXEC_BUDGET && budget > 0 && room >= 0) {
            g->call_late++;
            g->frozen++;
            g->stretch++;
            r = gbc_exec(g, GBC_EXEC_CALL, MAGIC_RET, sp0, &budget, 0);
            g->stretch--;
            g->frozen--;
        } else if (r == GBC_EXEC_BUDGET && budget > 0) {
            r = gbc_exec(g, GBC_EXEC_CALL, MAGIC_RET, sp0, &budget, 0);
        }
    } else {
        r = gbc_exec(g, GBC_EXEC_CALL, MAGIC_RET, sp0, &budget, 0);
    }
    g->call_depth--;
    if (r != GBC_EXEC_DONE) return false;
    s->pc = pc0;                      /* like a CALL: execution goes on where it was */
    return true;
}

bool gbc_call_orig(GBC *g, uint16_t addr)
{
    g->hook_skip = addr;
    return gbc_call(g, addr);
}

/* Run a subroutine with time frozen (no PPU/timer/APU progress, no interrupts).
 * Returns false if it did not return within `budget` instructions; the caller is then
 * responsible for restoring the machine state (the CPU is left mid-routine). */
bool gbc_call_frozen(GBC *g, uint16_t addr, bool orig, long budget)
{
    GBCState *s = &g->s;
    uint16_t sp0 = s->sp, pc0 = s->pc;
    int64_t saved_budget = g->frozen_budget;
    g->frozen++;
    g->frozen_budget = budget;
    if (orig) g->hook_skip = addr;
    gbc_push(g, MAGIC_RET);
    s->pc = addr;
    bool ok = gbc_exec(g, GBC_EXEC_CALL, MAGIC_RET, sp0, &g->frozen_budget, 0) == GBC_EXEC_DONE;
    g->frozen--;
    g->frozen_budget = saved_budget;
    if (ok) s->pc = pc0;
    return ok;
}

/* Call a routine in another ROM bank through the game's own BankSwitch (callba). */
bool gbc_farcall(GBC *g, uint8_t bank, uint16_t addr)
{
    GBCState *s = &g->s;
    s->hram[0x8A - 0x80] = s->a;      /* hFarCallTempA */
    s->a = bank;
    s->h = (uint8_t)(addr >> 8); s->l = (uint8_t)addr;
    return gbc_call(g, 0x054F);       /* BankSwitch */
}

/* ------------------------------------------------------------------ CPU step */

void gbc_step(GBC *g)
{
    GBCState *s = &g->s;
    if (g->trace_fn) g->trace_fn(g, g->trace_user);
    uint8_t pend = s->ie & s->ifl & 0x1F;

    if (s->halted) {
        if (!pend) { tick(g, 4); return; }
        s->halted = false;
    }
    if (s->ime && pend && !g->frozen) {
        int n = 0;
        while (!(pend & (1 << n))) n++;
        s->ime = false;
        tick(g, 8);
        push16(g, s->pc);
        s->ifl &= (uint8_t)~(1 << n);
        s->pc = (uint16_t)(0x40 + 8 * n);
        tick(g, 4);
        if (g->irq_fn) g->irq_fn(g, n, g->irq_user);
        return;
    }
    if (s->ei_pending) { s->ime = true; s->ei_pending = false; }

    if (g->nhooks && s->pc < 0x8000 && (g->hookmap[s->pc >> 3] & (1u << (s->pc & 7))))
        if (gbc_run_hooks(g)) return;

    uint8_t op = rd8(g, s->pc);
    if (s->halt_bug) s->halt_bug = false; else s->pc++;

    if (op >= 0x40 && op < 0x80) {
        if (op == 0x76) {
            if (!s->ime && (s->ie & s->ifl & 0x1F)) s->halt_bug = true;
            else s->halted = true;
        } else {
            setr(g, (op >> 3) & 7, getr(g, op & 7));
        }
        return;
    }
    if (op >= 0x80 && op < 0xC0) { alu(s, (op >> 3) & 7, getr(g, op & 7)); return; }

    switch (op) {
    case 0x00: break;
    case 0x01: SETBC(fetch16(g)); break;
    case 0x11: SETDE(fetch16(g)); break;
    case 0x21: SETHL(fetch16(g)); break;
    case 0x31: s->sp = fetch16(g); break;
    case 0x02: wr8(g, BC(), s->a); break;
    case 0x12: wr8(g, DE(), s->a); break;
    case 0x22: { uint16_t hl = HL(); wr8(g, hl, s->a); SETHL(hl + 1); } break;
    case 0x32: { uint16_t hl = HL(); wr8(g, hl, s->a); SETHL(hl - 1); } break;
    case 0x0A: s->a = rd8(g, BC()); break;
    case 0x1A: s->a = rd8(g, DE()); break;
    case 0x2A: { uint16_t hl = HL(); s->a = rd8(g, hl); SETHL(hl + 1); } break;
    case 0x3A: { uint16_t hl = HL(); s->a = rd8(g, hl); SETHL(hl - 1); } break;
    case 0x03: SETBC(BC() + 1); tick(g, 4); break;
    case 0x13: SETDE(DE() + 1); tick(g, 4); break;
    case 0x23: SETHL(HL() + 1); tick(g, 4); break;
    case 0x33: s->sp++; tick(g, 4); break;
    case 0x0B: SETBC(BC() - 1); tick(g, 4); break;
    case 0x1B: SETDE(DE() - 1); tick(g, 4); break;
    case 0x2B: SETHL(HL() - 1); tick(g, 4); break;
    case 0x3B: s->sp--; tick(g, 4); break;
    case 0x04: case 0x0C: case 0x14: case 0x1C: case 0x24: case 0x2C: case 0x34: case 0x3C: {
        int r = (op >> 3) & 7; setr(g, r, inc8(s, getr(g, r))); } break;
    case 0x05: case 0x0D: case 0x15: case 0x1D: case 0x25: case 0x2D: case 0x35: case 0x3D: {
        int r = (op >> 3) & 7; setr(g, r, dec8(s, getr(g, r))); } break;
    case 0x06: case 0x0E: case 0x16: case 0x1E: case 0x26: case 0x2E: case 0x36: case 0x3E: {
        uint8_t v = fetch8(g); setr(g, (op >> 3) & 7, v); } break;
    case 0x07: s->a = rot(s, 0, s->a); s->f &= FC; break;
    case 0x0F: s->a = rot(s, 1, s->a); s->f &= FC; break;
    case 0x17: s->a = rot(s, 2, s->a); s->f &= FC; break;
    case 0x1F: s->a = rot(s, 3, s->a); s->f &= FC; break;
    case 0x08: { uint16_t a = fetch16(g); wr8(g, a, (uint8_t)s->sp); wr8(g, (uint16_t)(a + 1), (uint8_t)(s->sp >> 8)); } break;
    case 0x09: add_hl(g, BC()); break;
    case 0x19: add_hl(g, DE()); break;
    case 0x29: add_hl(g, HL()); break;
    case 0x39: add_hl(g, s->sp); break;
    case 0x10: fetch8(g); break;                                   /* STOP: no speed switch in this game */
    case 0x18: { int8_t e = (int8_t)fetch8(g); s->pc = (uint16_t)(s->pc + e); tick(g, 4); } break;
    case 0x20: case 0x28: case 0x30: case 0x38: {
        int8_t e = (int8_t)fetch8(g);
        if (cond(s, (op >> 3) & 3)) { s->pc = (uint16_t)(s->pc + e); tick(g, 4); }
    } break;
    case 0x27: {
        int a = s->a; bool c = (s->f & FC) != 0;
        if (s->f & FN) {
            if (s->f & FH) a -= 0x06;
            if (c) a -= 0x60;
        } else {
            if (c || a > 0x99) { a += 0x60; c = true; }
            if ((s->f & FH) || (a & 0x0F) > 0x09) a += 0x06;
        }
        s->a = (uint8_t)a;
        s->f = (uint8_t)((s->a ? 0 : FZ) | (s->f & FN) | (c ? FC : 0));
    } break;
    case 0x2F: s->a = (uint8_t)~s->a; s->f |= FN | FH; break;
    case 0x37: s->f = (uint8_t)((s->f & FZ) | FC); break;
    case 0x3F: s->f = (uint8_t)((s->f & FZ) | ((s->f & FC) ? 0 : FC)); break;

    case 0xC0: case 0xC8: case 0xD0: case 0xD8:
        tick(g, 4);
        if (cond(s, (op >> 3) & 3)) { s->pc = pop16(g); tick(g, 4); }
        break;
    case 0xC9: s->pc = pop16(g); tick(g, 4); break;
    case 0xD9: s->pc = pop16(g); tick(g, 4); s->ime = true; if (g->reti_fn) g->reti_fn(g, g->irq_user); break;
    case 0xC1: SETBC(pop16(g)); break;
    case 0xD1: SETDE(pop16(g)); break;
    case 0xE1: SETHL(pop16(g)); break;
    case 0xF1: { uint16_t v = pop16(g); s->a = (uint8_t)(v >> 8); s->f = (uint8_t)(v & 0xF0); } break;
    case 0xC5: tick(g, 4); push16(g, BC()); break;
    case 0xD5: tick(g, 4); push16(g, DE()); break;
    case 0xE5: tick(g, 4); push16(g, HL()); break;
    case 0xF5: tick(g, 4); push16(g, (uint16_t)((s->a << 8) | s->f)); break;
    case 0xC2: case 0xCA: case 0xD2: case 0xDA: {
        uint16_t a = fetch16(g);
        if (cond(s, (op >> 3) & 3)) { s->pc = a; tick(g, 4); }
    } break;
    case 0xC3: s->pc = fetch16(g); tick(g, 4); break;
    case 0xE9: s->pc = HL(); break;
    case 0xC4: case 0xCC: case 0xD4: case 0xDC: {
        uint16_t a = fetch16(g);
        if (cond(s, (op >> 3) & 3)) { tick(g, 4); push16(g, s->pc); s->pc = a; }
    } break;
    case 0xCD: { uint16_t a = fetch16(g); tick(g, 4); push16(g, s->pc); s->pc = a; } break;
    case 0xC7: case 0xCF: case 0xD7: case 0xDF: case 0xE7: case 0xEF: case 0xF7: case 0xFF:
        tick(g, 4); push16(g, s->pc); s->pc = (uint16_t)(op & 0x38); break;
    case 0xC6: case 0xCE: case 0xD6: case 0xDE: case 0xE6: case 0xEE: case 0xF6: case 0xFE:
        alu(s, (op >> 3) & 7, fetch8(g)); break;
    case 0xE0: { uint8_t n = fetch8(g); wr8(g, (uint16_t)(0xFF00 | n), s->a); } break;
    case 0xF0: { uint8_t n = fetch8(g); s->a = rd8(g, (uint16_t)(0xFF00 | n)); } break;
    case 0xE2: wr8(g, (uint16_t)(0xFF00 | s->c), s->a); break;
    case 0xF2: s->a = rd8(g, (uint16_t)(0xFF00 | s->c)); break;
    case 0xEA: { uint16_t a = fetch16(g); wr8(g, a, s->a); } break;
    case 0xFA: { uint16_t a = fetch16(g); s->a = rd8(g, a); } break;
    case 0xE8: { int8_t e = (int8_t)fetch8(g); s->sp = sp_plus(s, e); tick(g, 8); } break;
    case 0xF8: { int8_t e = (int8_t)fetch8(g); uint16_t v = sp_plus(s, e); SETHL(v); tick(g, 4); } break;
    case 0xF9: s->sp = HL(); tick(g, 4); break;
    case 0xF3: s->ime = false; s->ei_pending = false; break;
    case 0xFB: s->ei_pending = true; break;
    case 0xCB: {
        uint8_t cb = fetch8(g);
        int r = cb & 7, b = (cb >> 3) & 7;
        uint8_t v = getr(g, r);
        if (cb < 0x40) setr(g, r, rot(s, b, v));
        else if (cb < 0x80) s->f = (uint8_t)((s->f & FC) | FH | (((v >> b) & 1) ? 0 : FZ));
        else if (cb < 0xC0) setr(g, r, (uint8_t)(v & ~(1 << b)));
        else setr(g, r, (uint8_t)(v | (1 << b)));
    } break;
    default:
        /* illegal opcode: the real CPU locks up; treat as NOP */
        break;
    }
}

/* ------------------------------------------------------------------ lifecycle */

void gbc_set_bands(GBC *g, const GBCBand *bands, int n, int fw, int fh)
{
    GBCState *s = &g->s;
    if (n > GBC_MAX_BANDS) n = GBC_MAX_BANDS;
    memcpy(s->band, bands, sizeof(GBCBand) * (size_t)n);
    s->nbands = n;
    s->fw = fw > GBC_FB_W ? GBC_FB_W : fw;
    s->fh = fh > GBC_FB_H ? GBC_FB_H : fh;
}

int gbc_init(GBC *g, const uint8_t *rom, size_t size, uint32_t sample_rate)
{
    memset(g, 0, sizeof(*g));
    if (size < 0x8000 || (size & 0x3FFF)) return -1;
    g->rom = rom;
    g->rom_size = (uint32_t)size;
    g->rom_banks = (uint32_t)(size >> 14);
    g->rom_mask = (g->rom_banks & (g->rom_banks - 1)) == 0 ? g->rom_banks - 1 : 0;
    g->hook_skip = -1;
    g->engine = gbc_default_engine;
    gbc_exec_tables(g);
    g->win_page = -1;
    g->tile_mirror_page = -1;
    for (int p = 0; p < GBC_PAGES; p++) g->xobj_src[p] = -1;

    GBCState *s = &g->s;
    static const uint32_t ram_sizes[6] = { 0, 0x800, 0x2000, 0x8000, 0x8000, 0x8000 };
    uint8_t rs = rom[0x149];
    s->sram_size = rs < 6 ? ram_sizes[rs] : 0;
    if (s->sram_size > sizeof(s->sram)) s->sram_size = sizeof(s->sram);
    memset(s->sram, 0xFF, sizeof(s->sram));

    /* CGB post-boot state */
    s->a = 0x11; s->f = 0x80; s->b = 0x00; s->c = 0x00;
    s->d = 0xFF; s->e = 0x56; s->h = 0x00; s->l = 0x0D;
    s->sp = 0xFFFE; s->pc = 0x0100;
    s->rom_bank = 1; s->wram_bank = 1;
    s->io[0x00] = 0x30;
    s->io[0x02] = 0x7C;
    s->tac = 0; s->div16 = 0x2678;
    s->ifl = 0x01;
    s->io[0x40] = 0x91;
    s->io[0x47] = 0xFC;
    for (int p = 0; p < GBC_PAGES; p++)
        for (int i = 0; i < 64; i += 2) {
            s->page[p].bgpal[i] = 0xFF; s->page[p].bgpal[i + 1] = 0x7F;
            s->page[p].obpal[i] = 0xFF; s->page[p].obpal[i + 1] = 0x7F;
        }
    GBCBand b = { 0, 0, 144, 0, 0, 0 };
    gbc_set_bands(g, &b, 1, 160, 144);
    gbc_ppu_reset(g);
    gbc_apu_init(g, sample_rate);
    return 0;
}

void gbc_load_sram(GBC *g, const uint8_t *data, size_t size)
{
    if (size > g->s.sram_size) size = g->s.sram_size;
    memcpy(g->s.sram, data, size);
}

void gbc_set_buttons(GBC *g, uint8_t mask)
{
    uint8_t newly = (uint8_t)(mask & ~g->s.buttons);
    g->s.buttons = mask;
    if (newly) g->s.ifl |= 0x10;
}

void gbc_run_frame(GBC *g)
{
    GBCState *s = &g->s;
    g->frame_done = false;
    gbc_exec(g, GBC_EXEC_FRAME, 0, 0, NULL, s->cycles);
    if (s->rumble) s->rumble_frames++;
    gbc_apu_end_frame(g);
}

/* ------------------------------------------------------------------ snapshots */

size_t gbc_state_size(void) { return sizeof(GBCState); }

void gbc_state_save(const GBC *g, void *dst) { memcpy(dst, &g->s, sizeof(GBCState)); }

int gbc_state_load(GBC *g, const void *src, size_t size)
{
    if (size != sizeof(GBCState)) return -1;
    memcpy(&g->s, src, sizeof(GBCState));
    return 0;
}
