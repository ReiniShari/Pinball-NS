/*
 * gbc.h - Game Boy Color emulation core (C99) for "Pokemon Pinball - table complete".
 *
 * A compact CGB core (SM83 CPU, MBC5 + rumble, PPU, APU, timer) with two
 * extensions that only exist in this runtime, since the mod targets Windows and
 * Android rather than real Game Boy Color hardware:
 *
 *   - several video "pages": each page is a complete CGB video memory (VRAM banks,
 *     OAM, BG/OBJ palette RAM). The CPU accesses the page selected by `cpu_page`;
 *   - a configurable output made of "bands": each band renders lines of one page
 *     into a region of a larger frame (up to GBC_FB_W x GBC_FB_H pixels).
 *
 * In normal use there is one page and one 160x144 band, i.e. a regular GBC.
 */
#ifndef GBC_H
#define GBC_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#define GBC_CLOCK        4194304           /* T-cycles per second (single speed) */
#define GBC_FRAME_CYCLES 70224             /* T-cycles per video frame            */
#define GBC_FB_W         256
#define GBC_FB_H         320
#define GBC_PAGES        2
#define GBC_MAX_BANDS    4
#define GBC_MAX_HOOKS    64
#define GBC_AUDIO_RING   16384             /* stereo frames                       */

/* joypad bits (1 = pressed) */
enum {
    GBC_A = 0x01, GBC_B = 0x02, GBC_SELECT = 0x04, GBC_START = 0x08,
    GBC_RIGHT = 0x10, GBC_LEFT = 0x20, GBC_UP = 0x40, GBC_DOWN = 0x80
};

/* band flags */
enum {
    GBC_BAND_NO_WINDOW   = 1,   /* do not draw the window layer in this band            */
    GBC_BAND_FRAME_LCDC  = 2,   /* use LCDC as it was at line 0 (ignore mid-frame LCDC) */
    GBC_BAND_WIN_CLIP    = 4,   /* window limited to x < 160, black beyond (status bar) */
    GBC_BAND_WIN_HIGH    = 8,   /* draw the window only while WY < band.wy (raised menus) */
    GBC_BAND_STATUS      = 16,  /* status bar: when line `line0` has been drawn, draw the
                                   window lines 0..nlines-1 (160 px, centred) at row0,
                                   or black while the window is off or WY < band.wy     */
};

typedef struct GBC GBC;
typedef bool (*GBCHookFn)(GBC *g, void *user);   /* return true if the hook replaced the routine */
typedef void (*GBCDmaFn)(GBC *g, uint8_t src_hi, void *user);
typedef void (*GBCWatchFn)(GBC *g, uint16_t addr, uint8_t value, void *user);

typedef struct {
    uint8_t vram[2][0x2000];
    uint8_t oam[0xA0];
    uint8_t bgpal[64];
    uint8_t obpal[64];
} GBCPage;

typedef struct {
    uint8_t page;
    uint8_t line0, nlines;      /* source lines [line0, line0+nlines) of the page */
    uint16_t row0;              /* destination row of line0 in the output frame   */
    uint8_t flags;
    uint8_t wy;                 /* WY threshold for GBC_BAND_WIN_HIGH / GBC_BAND_STATUS */
} GBCBand;

/* ----- APU ----- */
typedef struct {
    bool on, dac;
    int len; bool len_en;
    int period, timer;
    int duty, duty_pos;
    int vol, env_init, env_dir, env_pace, env_timer;
    /* sweep (channel 1 only) */
    int sw_pace, sw_dir, sw_step, sw_timer, sw_shadow;
    bool sw_en, sw_neg_used;
} GBCSquare;

typedef struct {
    bool on, dac;
    int len; bool len_en;
    int period, timer, pos, level;
    uint8_t sample;
} GBCWave;

typedef struct {
    bool on, dac;
    int len; bool len_en;
    int vol, env_init, env_dir, env_pace, env_timer;
    int timer, shift, div; bool width7;
    uint16_t lfsr;
} GBCNoise;

typedef struct {
    uint8_t regs[0x30];        /* FF10-FF3F as written (wave RAM at 0x20) */
    bool power;
    int fs_step;
    int32_t fs_timer;
    GBCSquare ch1, ch2;
    GBCWave ch3;
    GBCNoise ch4;
    uint64_t last;             /* cycle up to which the APU has been run   */
    uint32_t sample_rate;
    double cyc_per_sample, sample_pos;
    double acc_l, acc_r;
    double hp_l, hp_r, hp_factor;
    int16_t ring[GBC_AUDIO_RING][2];
    uint32_t ring_w, ring_r;
} GBCApu;

/* ----- PPU ----- */
typedef struct {
    int mode;                  /* 0..3, or -1 when the LCD is off           */
    uint8_t ly;
    uint64_t line_start;       /* cycle at which the current line started   */
    uint64_t next;             /* cycle of the next PPU event               */
    bool stat_line;
    uint8_t win_line;
    bool win_trig, win_drawn_line;
    uint8_t frame_lcdc;        /* LCDC latched at line 0                    */
} GBCPpu;

/* Everything that makes up the machine state (saved in snapshots). */
typedef struct {
    /* CPU */
    uint8_t a, f, b, c, d, e, h, l;
    uint16_t sp, pc;
    bool ime, ei_pending, halted, halt_bug;
    uint64_t cycles;
    /* memory */
    uint16_t rom_bank;
    uint8_t ram_bank;
    bool ram_enable, rumble;
    uint8_t sram[0x8000];
    uint32_t sram_size;
    uint8_t wram[0x8000];
    uint8_t wram_bank;
    uint8_t hram[0x80];
    uint8_t io[0x80];
    uint8_t ie, ifl;
    uint8_t vbk;
    uint8_t bcps, ocps;
    /* timer / serial / joypad */
    uint16_t div16;
    uint8_t tima, tma, tac;
    bool serial_active;
    uint64_t serial_done;
    uint8_t buttons;
    /* video */
    GBCPage page[GBC_PAGES];
    int cpu_page;              /* page accessed by the CPU                  */
    GBCBand band[GBC_MAX_BANDS];
    int nbands, fw, fh;
    GBCPpu ppu;
    /* audio */
    GBCApu apu;
    /* frame accounting */
    uint64_t frame_count;
    uint64_t lcd_off_since;
    uint32_t rumble_frames;    /* frames with the rumble motor on (consumed by the front-end) */
} GBCState;

typedef struct {
    int bank;                  /* -1: any bank (or address in bank 0) */
    uint16_t addr;
    GBCHookFn fn;
    void *user;
} GBCHook;

/* What the fast interpreters (gbc_exec.c, cpu_x64.asm, cpu_a64.S) derive from the machine state,
 * rebuilt by gbc_exec_prepare after every call into the rest of the core. The assembly versions
 * use its layout through the offsets written by tools/gencpu.c (gbc_asm.h checks them against
 * the compiler): run gencpu again after a change. */
typedef struct {
    const uint8_t *rd[16];     /* read: base pointer of each 4 KB of the address space (index:
                                  address >> 12; byte = rd[i][address]), NULL: gbc_read */
    uint8_t *wr[16];           /* write: the same, NULL: gbc_write */
    uint8_t *oam;              /* OAM of the CPU's page */
    uint8_t *oamb;             /* oam - 0xFE00 */
    uint8_t *hramb;            /* s.hram - 0xFF80 */
    const uint8_t *watch;      /* watched work RAM bytes (C000-DFFF: watch[address & 0x1FFF]) or NULL */
    const uint8_t *hooks;      /* GBC.hookbyte */
    uint64_t deadline;         /* cycle at which tick() does more than counting */
    uint64_t dl24;             /* deadline - 24 (or 0): an instruction that starts before it cannot reach it */
    uint64_t frame_end;        /* run of a frame with the LCD off: the cycle at which it ends, else never */
    uint64_t limit;            /* min(dl24, frame_end), 0 when the next step needs the C interpreter */
    /* writes without gbc_write: video memory (the pages of 8000-9BFF and 9C00-9FFF, minus 0x8000,
     * and the page that also receives the writes of [vmir_a0, vmir_a1), see tile_mirror_page,
     * or NULL), ROM banks (MBC5) */
    uint8_t *vlo, *vhi, *vmir_lo, *vmir_hi;
    uint32_t vmir_a0, vmir_a1;
    uint16_t div_base;         /* divider = div_base + (uint16_t)cycles */
    uint8_t special;           /* the next step needs the C interpreter: halted, interrupt, EI, trace, frame done */
    uint8_t frozen;            /* GBC.frozen != 0 */
    uint8_t tmp;               /* a byte read by gbc_read (assembly) */
    uint8_t tables_ok;         /* the flag tables are filled */
    uint8_t vfast, mbc5;       /* the writes above are allowed */
    uint8_t ff41, ff44;        /* what STAT and LY read until the next event (not frozen) */
    uint8_t pad[6];
    /* the run in progress of the assembly version (gbc_exec_asm; saved around nested runs) */
    uint32_t stop_pc;          /* 0x10000: none */
    uint32_t stop_sp;
    int32_t mode;
    uint32_t pad2;
    uint64_t start;
    /* flags of the x64 version, from LAHF (add, sub) or from the result (inc, dec, zero) */
    uint8_t t_add[256], t_sub[256], t_inc[256], t_dec[256], t_z[256], t_zh[256];
    /* writes of the assembly versions, per 256 bytes: wr, and the video memory without a mirrored
     * tile, but NULL where a byte is watched */
    uint8_t *wrf[256];
    /* what the memory map (rd, wr, wrf, ...) was built from: rebuilt when it changes */
    uint64_t map_key;
    const void *map_g;
} GBCFast;

/* engines of gbc_exec (GBC.engine): the fastest one available, the fast interpreter in C, or the
 * reference (gbc_step, one instruction per call) */
enum { GBC_ENGINE_AUTO = 0, GBC_ENGINE_C = 1, GBC_ENGINE_REF = 2 };
/* gbc_exec: modes, results */
enum { GBC_EXEC_FRAME = 0, GBC_EXEC_CALL = 1, GBC_EXEC_ONE = 0x100 /* internal: one step */ };
enum { GBC_EXEC_BUDGET = 0, GBC_EXEC_DONE = 1, GBC_EXEC_TRACE = 2, GBC_EXEC_MORE = 3 /* internal */ };

struct GBC {
    const uint8_t *rom;
    uint32_t rom_size, rom_banks;
    uint32_t rom_mask;         /* rom_banks - 1 when it is a power of two (a mask instead of a division), else 0 */
    GBCState s;
    /* frame buffer (0x00RRGGBB) */
    uint32_t fb[GBC_FB_H][GBC_FB_W];
    bool frame_done;
    /* runtime extensions (not saved) */
    GBCHook hooks[GBC_MAX_HOOKS];
    int nhooks;
    uint8_t hookmap[0x8000 / 8];
    uint8_t hookbyte[0x10000]; /* the same, one byte per address (the fast interpreters): bit 0 a
                                  hook, bit 1 the stop address of a run of the assembly version */
    uint8_t watchbyte[0x2000]; /* watched work RAM bytes: C000-DFFF, one byte per address */
    GBCFast fast;              /* the fast interpreters' view of the state */
    int engine;                /* GBC_ENGINE_* (gbc_init: gbc_default_engine) */
    int hook_skip;             /* address whose hook is skipped once (-1: none) */
    int call_depth;
    GBCDmaFn dma_fn; void *dma_user;
    uint16_t watch_addr[8]; GBCWatchFn watch_fn[8]; void *watch_user[8]; int nwatch;
    /* "virtual hardware" used by the runtime extensions */
    int frozen;                /* >0: time does not advance, no interrupts       */
    bool fake_lcd_off;         /* LCDC bit 7 / LY / STAT read as "LCD off"        */
    uint8_t fake_ly, fake_phase; /* virtual scan seen by out-of-time code (polling loops end) */
    int win_page;              /* -1, or page receiving CPU writes to 9C00-9FFF   */
    int tile_mirror_page;      /* -1, or page that also receives CPU writes to tile data in
                                  [tile_mirror_lo, tile_mirror_hi) (VRAM offsets), outside frozen mode */
    uint16_t tile_mirror_lo, tile_mirror_hi;
    /* extra sprites drawn on the lines of page p (after its own sprites, with lower priority),
     * using the tiles and object palettes of page xobj_src[p]; OAM format, positions in the
     * line coordinates of page p */
    uint8_t xobj[GBC_PAGES][0xA0];
    uint8_t xobj_n[GBC_PAGES];
    int8_t xobj_src[GBC_PAGES];
    /* with xobj_private[p], the extra sprites of page p use their own 8x16 tiles: the tile
     * number of an entry is an index in xobj_tiles[p] (2 bits per pixel, 16 rows) */
    bool xobj_private[GBC_PAGES];
    uint8_t xobj_tiles[GBC_PAGES][40][32];
    /* the palette memories converted to RGB (PPU), kept while their content does not change */
    uint8_t palc_src[GBC_PAGES][2][64];
    uint32_t palc_rgb[GBC_PAGES][2][32];
    bool palc_ok[GBC_PAGES][2];
    int64_t frozen_budget;     /* instructions left in frozen mode (safety)       */
    bool frozen_abort;
    void (*trace_fn)(GBC *g, void *user); void *trace_user;   /* debugging: called before each instruction */
    void (*irq_fn)(GBC *g, int n, void *user);
    void (*reti_fn)(GBC *g, void *user);
    void *irq_user;
    /* debugging */
    void (*serial_out)(uint8_t byte, void *user); void *serial_user;
    void (*vram_fn)(GBC *g, int page, int bank, uint16_t off, uint8_t v, void *user); void *vram_user;  /* CPU writes to VRAM */
    void (*wram_fn)(GBC *g, uint16_t addr, uint8_t v, void *user); void *wram_user;  /* CPU writes to C000-CFFF */
    /* levels of `frozen` that continue the program itself out of time (pinball.c: the end of a
     * late frame): for them, the writes still reach tile_mirror_page */
    int stretch;
    /* gbc_set_frame_palettes: each picture drawn with the palettes as they were at its line 0 */
    bool pal_latch;
    uint8_t pal_frame[GBC_PAGES][2][64];
    /* gbc_call / gbc_call_orig with call_in_frame: the end of the frame stops the time, the routine
     * goes on frozen from there (pinball.c: a late frame finished out of time); call_late counts them */
    bool call_in_frame;
    long call_late;
};

/* lifecycle */
int  gbc_init(GBC *g, const uint8_t *rom, size_t size, uint32_t sample_rate);
void gbc_load_sram(GBC *g, const uint8_t *data, size_t size);
void gbc_run_frame(GBC *g);
void gbc_set_buttons(GBC *g, uint8_t mask);
int  gbc_audio_read(GBC *g, int16_t *out, int max_frames);   /* interleaved stereo */
/* the rate of the sound output, changed while it runs (the front-ends keep the sound card fed
 * while the emulation follows the screen: a fraction of a percent) */
void gbc_set_audio_rate(GBC *g, double sample_rate);
int  gbc_audio_available(GBC *g);
/* The colours of a whole picture taken at its first line: a palette written while the picture is
 * drawn (a fade, a flash, the palettes of another video page loaded out of time) takes effect
 * at the next picture, on all of it, instead of tearing it at that line. What the CPU reads back
 * is not changed. Off by default (the original: the tools' fingerprints). */
void gbc_set_frame_palettes(GBC *g, bool on);
/* the background palettes (64 bytes) of page p the last picture was drawn with */
const uint8_t *gbc_frame_bgpal(const GBC *g, int page);

/* CPU-level helpers for runtime extensions */
void     gbc_step(GBC *g);                          /* one instruction (the reference interpreter) */
/* Runs instructions as repeated gbc_step would, until: (GBC_EXEC_FRAME) the frame is done, or
 * 70224 cycles after `start` with the LCD off; (GBC_EXEC_CALL) PC = stop_pc with SP = stop_sp
 * before an instruction (GBC_EXEC_DONE), or *budget, decremented before each instruction, goes
 * below zero (GBC_EXEC_BUDGET). The engine is g->engine. */
int      gbc_exec(GBC *g, int mode, uint16_t stop_pc, uint16_t stop_sp, int64_t *budget, uint64_t start);
extern int gbc_default_engine;                      /* engine of the machines made by gbc_init */
uint8_t  gbc_read(GBC *g, uint16_t addr);           /* no timing side effects */
void     gbc_write(GBC *g, uint16_t addr, uint8_t v);/* no timing side effects */
/* gbc_call*: run a subroutine until it returns. They return false if it did not return
 * within their instruction budget: the CPU is then left mid-routine and the caller must
 * restore the machine state (a hook must never hang the program). */
#define GBC_CALL_BUDGET 4000000L                    /* instructions (several seconds of emulated time) */
bool     gbc_call(GBC *g, uint16_t addr);
bool     gbc_call_orig(GBC *g, uint16_t addr);      /* same, skipping a hook at addr once */
bool     gbc_call_frozen(GBC *g, uint16_t addr, bool orig, long budget); /* run without time */
bool     gbc_farcall(GBC *g, uint8_t bank, uint16_t addr);  /* call through the game's BankSwitch */
void     gbc_ret(GBC *g);                           /* perform RET (used by hooks)       */
void     gbc_push(GBC *g, uint16_t v);
uint16_t gbc_pop(GBC *g);
int      gbc_add_hook(GBC *g, int bank, uint16_t addr, GBCHookFn fn, void *user);
int      gbc_add_watch(GBC *g, uint16_t addr, GBCWatchFn fn, void *user);
void     gbc_set_rom_bank(GBC *g, uint16_t bank);

/* video configuration */
void gbc_set_bands(GBC *g, const GBCBand *bands, int n, int fw, int fh);
void gbc_render_page_line(GBC *g, int page, int ly, uint32_t *out, int width, int flags);
void gbc_render_band_line(GBC *g, int page, int ly, uint32_t *out, int width, int flags, uint8_t wy_high);

/* internal (shared between core files) */
int     gbc_exec_c(GBC *g, int mode, uint16_t stop_pc, uint16_t stop_sp, int64_t *budget, uint64_t start);
int     gbc_exec_asm(GBC *g, int mode, uint16_t stop_pc, uint16_t stop_sp, int64_t *budget, uint64_t start);
bool    gbc_exec_has_asm(void);
void    gbc_exec_prepare(GBC *g);
void    gbc_exec_prepare_time(GBC *g);
void    gbc_exec_tables(GBC *g);
void    gbc_tick(GBC *g, int t);                    /* t cycles pass (the reference timing) */
/* called by the assembly versions, the machine state written back (they rebuild GBC.fast) */
void    gbc_asm_tick(GBC *g, int t);
void    gbc_asm_write(GBC *g, uint16_t addr, uint8_t v);
void    gbc_asm_op(GBC *g, int op);
bool    gbc_run_hooks(GBC *g);
uint8_t gbc_io_read(GBC *g, uint16_t addr);
void    gbc_io_write(GBC *g, uint16_t addr, uint8_t v);
void    gbc_ppu_reset(GBC *g);
void    gbc_ppu_update(GBC *g);
void    gbc_ppu_lcdc_write(GBC *g, uint8_t v);
void    gbc_ppu_stat_check(GBC *g);
void    gbc_apu_init(GBC *g, uint32_t sample_rate);
void    gbc_apu_run(GBC *g);
uint8_t gbc_apu_read(GBC *g, uint16_t addr);
void    gbc_apu_write(GBC *g, uint16_t addr, uint8_t v);
void    gbc_apu_end_frame(GBC *g);

/* snapshots */
size_t gbc_state_size(void);
void   gbc_state_save(const GBC *g, void *dst);
int    gbc_state_load(GBC *g, const void *src, size_t size);

#endif
