/*
 * pbdebug.c - long automatic games with consistency checks of the unified field.
 *
 *   pbdebug ROM [-frames N] [-seed S] [-shots DIR] [-pause K] [-maxshots M] [-oracle K]
 *   pbdebug ROM -selftest
 *   investigation: -dump F (maps and sprites at frame F), -probe X Y (colour of a pixel),
 *   -tracetile T F0 F1 (writes to tile T), -every N F0 (screenshots), -endshot FILE,
 *   -savesram FILE (the cartridge save at the end: Pokedex, high scores)
 *
 * The whole-game bot of pbrun (menus, flippers, tilts) plays, and every frame:
 *   - wild jumps (PC in RAM), software resets, aborted out-of-time calls are counted;
 *   - "stale window tiles": the window (status bar, in-game menus) is drawn from the main
 *     video page; a tile it shows whose graphics were last written to the OTHER page (and
 *     differ) means the game updated it while the CPU was on the wrong page;
 *   - every K frames on the field, the pause menu is opened and closed (START, then A);
 *   - with -oracle K: every K frames, what the original game would show on entering each
 *     half is compared with the screen (stale graphics of the half without the ball);
 *   - visual churn and flicker of each half, position of the bonus slot halo.
 * Screenshots of the first problems go to DIR.
 */
#include "../src/game/pinball.h"
#include "engine.h"
#include "../src/game/pinball_us.h"
#include "png_write.h"
#include <stdio.h>
#include <stdlib.h>
#include "botrand.h"
#include <string.h>
#include <time.h>

static Pinball pb;
static uint8_t rom[4 << 20];
static long frames;
static int trace_tile = -1, trace_map = -1;     /* -tracetile / -tracemap */
static long trace_from, trace_to;
/* -writewatch ADDR F0 F1: every write to a work RAM byte, with the writer and its stack */
static int ww_addr = -1;
static long ww_from, ww_to;
static void on_ww(GBC *g, uint16_t addr, uint8_t v, void *u)
{
    (void)u;
    if (frames < ww_from || frames > ww_to) return;
    fprintf(stderr, "  f%ld write %04X=%02X pc %02X:%04X frozen %d other_run %d stretch %d stage %d, stack", frames, addr, v,
            (int)g->s.rom_bank, g->s.pc, g->frozen, pb.other_run, g->stretch, gbc_read(g, W_CurrentStage));
    for (int i = 0; i < 10; i++)
        fprintf(stderr, " %04X", gbc_read(g, (uint16_t)(g->s.sp + 2 * i)) | gbc_read(g, (uint16_t)(g->s.sp + 2 * i + 1)) << 8);
    fprintf(stderr, "\n");
}
static const char *shots;
static int maxshots = 12, nshots;

/* ---- instruction-level checks ---- */
static long wild, resets;
/* graphics queue entries whose data is in WRAM: [page][kind 0 normal, 1 frozen] -> address range */
static uint16_t qw_lo[2][2] = { { 0xFFFF, 0xFFFF }, { 0xFFFF, 0xFFFF } }, qw_hi[2][2];
static long qw_n[2][2];
/* main-program writes to the palettes (FF69 / FF6B), grouped by the instruction */
static struct { uint16_t pc; uint8_t bank, page, reg; long n; } palw[64];
static int npalw;
static void trace(GBC *g, void *u)
{
    (void)u;
    uint16_t pc = g->s.pc;
    if (trace_map >= 0 && frames >= trace_from && frames <= trace_to) {
        static long last_refresh = -1, last_swaps = -1;
        if (pb.st.stats_refresh != last_refresh)
            fprintf(stderr, "  f%ld redraw #%ld (stage %d, ly %d)\n", frames, pb.st.stats_refresh, gbc_read(g, W_CurrentStage), g->s.ppu.ly);
        if (pb.st.stats_swaps != last_swaps)
            fprintf(stderr, "  f%ld ball changes half #%ld (stage %d)\n", frames, pb.st.stats_swaps, gbc_read(g, W_CurrentStage));
        last_refresh = pb.st.stats_refresh;
        last_swaps = pb.st.stats_swaps;
    }
    if (pb.st.unified && !g->frozen && pb.st.nforced == 0) {
        uint8_t op = gbc_read(g, pc), a1 = gbc_read(g, (uint16_t)(pc + 1)), a2 = gbc_read(g, (uint16_t)(pc + 2));
        int reg = 0;
        if (op == 0xE0 && (a1 == 0x69 || a1 == 0x6B)) reg = a1;
        else if (op == 0xE2 && (g->s.c == 0x69 || g->s.c == 0x6B)) reg = g->s.c;
        else if (op == 0xEA && a2 == 0xFF && (a1 == 0x69 || a1 == 0x6B)) reg = a1;
        else if ((op == 0x77 || op == 0x22 || op == 0x32 || (op >= 0x70 && op <= 0x75)) && g->s.h == 0xFF &&
                 (g->s.l == 0x69 || g->s.l == 0x6B)) reg = g->s.l;
        if (reg) {
            int i;
            uint8_t bk = pc < 0x4000 ? 0 : (uint8_t)g->s.rom_bank;
            for (i = 0; i < npalw; i++) if (palw[i].pc == pc && palw[i].bank == bk && palw[i].page == g->s.cpu_page) break;
            if (i == npalw && npalw < 64) { palw[i].pc = pc; palw[i].bank = bk; palw[i].page = (uint8_t)g->s.cpu_page; palw[i].reg = (uint8_t)reg; npalw++; }
            if (i < 64) palw[i].n++;
        }
    }
    if (pc >= 0x8000 && pc < 0xFF80 && wild++ < 5)
        fprintf(stderr, "frame %ld: wild PC %02X:%04X sp=%04X frozen=%d\n", frames, (int)g->s.rom_bank, pc, g->s.sp, g->frozen);
    if (pc == 0x0100 && frames > 0) { resets++; fprintf(stderr, "frame %ld: reset\n", frames); }
    if (pc == R_Func_113a_Entry && pb.st.unified) {
        uint8_t l = g->s.l;
        uint16_t ptr = (uint16_t)(gbc_read(g, (uint16_t)(0xCB00 + l)) | (gbc_read(g, (uint16_t)(0xCC00 + l)) << 8));
        if (ptr >= 0xC000 && ptr < 0xE000) {
            int p = pb.st.slot_page[l] & 1, k = g->frozen ? 1 : 0;
            if (ptr < qw_lo[p][k]) qw_lo[p][k] = ptr;
            if (ptr > qw_hi[p][k]) qw_hi[p][k] = ptr;
            qw_n[p][k]++;
        }
    }
}

/* ---- VRAM writes: last frame and writer of each tile, per page and bank ---- */
static long last_w[GBC_PAGES][2][384];
static long long last_wb[GBC_PAGES][2][0x1800], write_seq;   /* order of the last write of each byte */
static uint16_t last_pc[GBC_PAGES][2][384];
static uint8_t last_bank[GBC_PAGES][2][384];
static uint16_t last_stack[GBC_PAGES][2][384][6];   /* return addresses (raw stack words) */
static long frozen_win_writes;
static bool other_tiles;                        /* -othertiles */
static struct { int page, stage, mode; uint16_t w[4], lo, hi; long n, first; } ot[64];
static int n_ot;
static struct { uint16_t pc, ret, lo, hi; uint8_t bank; long n; } writers[64];
static int nwriters;
static void on_vram(GBC *g, int page, int bank, uint16_t off, uint8_t v, void *u)
{
    (void)u;
    if (trace_map >= 0 && off == trace_map && frames >= trace_from && frames <= trace_to) {
        fprintf(stderr, "  f%ld map %04X=%d bank %d page %d frozen %d nforced %d other_run %d stretch %d pc %02X:%04X stage %d slot %d refresh %ld, stack",
                frames, 0x8000 + off, v, bank, page, g->frozen, pb.st.nforced, pb.other_run, g->stretch, (int)g->s.rom_bank, g->s.pc,
                gbc_read(g, W_CurrentStage), gbc_read(g, W_SlotIsOpen), pb.st.stats_refresh);
        for (int i = 0; i < 10; i++)
            fprintf(stderr, " %04X", gbc_read(g, (uint16_t)(g->s.sp + 2 * i)) | gbc_read(g, (uint16_t)(g->s.sp + 2 * i + 1)) << 8);
        fprintf(stderr, "\n");
    }
    if (trace_tile >= 0 && (off >> 4) == trace_tile && bank == 0 && frames >= trace_from && frames <= trace_to)
        fprintf(stderr, "  f%ld write %04X=%02X page %d frozen %d nforced %d mirror %d pc %02X:%04X stage %d\n", frames,
                0x8000 + off, v, page, g->frozen, pb.st.nforced, g->tile_mirror_page, (int)g->s.rom_bank, g->s.pc,
                gbc_read(g, W_CurrentStage));
    if (g->frozen && pb.st.unified && page == PB_PAGE_MAIN &&
        ((off >= PB_WIN_TILES_LO && off < PB_WIN_TILES_HI && bank == 0) || off >= 0x1C00))
        frozen_win_writes++;                             /* out-of-time code drawing into the window */
    if (other_tiles && pb.other_run == 1 && off < 0x1800 && pb.st.nforced == 0) {
        /* -othertiles: the other half's logic writing tiles of its page itself (not through the
         * graphics queue): by caller (the return addresses on the stack) */
        uint16_t sp = g->s.sp, w[4];
        for (int i = 0; i < 4; i++) w[i] = (uint16_t)(gbc_read(g, (uint16_t)(sp + 2 * i)) | gbc_read(g, (uint16_t)(sp + 2 * i + 1)) << 8);
        int i;
        for (i = 0; i < n_ot; i++)
            if (ot[i].page == page && ot[i].stage == gbc_read(g, W_CurrentStage) && !memcmp(ot[i].w, w, sizeof w)) break;
        if (i == n_ot && n_ot < 64) {
            ot[i].page = page; ot[i].stage = gbc_read(g, W_CurrentStage); memcpy(ot[i].w, w, sizeof w);
            ot[i].lo = ot[i].hi = off; ot[i].mode = gbc_read(g, W_InSpecialMode) ? gbc_read(g, W_SpecialMode) : -1;
            ot[i].first = frames; n_ot++;
        }
        if (i < 64) { ot[i].n++; if (off < ot[i].lo) ot[i].lo = off; if (off > ot[i].hi) ot[i].hi = off; }
    }
    if (off >= 0x1800 || g->frozen) return;              /* tile data only, game time only */
    int t = off >> 4;
    if (page == PB_PAGE_TOP && off >= PB_WIN_TILES_LO && off < PB_WIN_TILES_HI && g->tile_mirror_page != PB_PAGE_MAIN) {
        static int shown;
        if (shown++ < 8)
            fprintf(stderr, "frame %ld: window tile write %04X on the top page without copy (pc %04X, unified %d, nforced %d, "
                    "forced %d, stage %d, ime %d)\n", frames, 0x8000 + off, g->s.pc, pb.st.unified, pb.st.nforced,
                    pb.st.nforced ? pb.st.forced[pb.st.nforced - 1] : -1, gbc_read(g, W_CurrentStage), g->s.ime);
    }
    last_w[page][bank][t] = frames + 1;
    last_wb[page][bank][off] = ++write_seq;
    last_pc[page][bank][t] = g->s.pc;
    last_bank[page][bank][t] = (uint8_t)g->s.rom_bank;
    if (pb.st.unified && page == PB_PAGE_TOP && pb.st.nforced == 0) {
        /* main-program writes to the top page: group them by the routine that asked */
        uint16_t sp = g->s.sp, pc = g->s.pc;
        int k = (pc >= 0x0666 && pc < 0x0800) ? 2 : 0;       /* LoadVRAMData: AF and the old bank are pushed */
        uint16_t ret = (uint16_t)(gbc_read(g, (uint16_t)(sp + 2 * k)) | (gbc_read(g, (uint16_t)(sp + 2 * k + 1)) << 8));
        int i;
        for (i = 0; i < nwriters; i++) if (writers[i].pc == pc && writers[i].ret == ret) break;
        if (i == nwriters && nwriters < 64) { writers[i].pc = pc; writers[i].ret = ret; writers[i].lo = 0x7FFF; nwriters++; }
        if (i < 64) {
            writers[i].n++;
            if (off < writers[i].lo) writers[i].lo = off;
            if (off > writers[i].hi) writers[i].hi = off;
            writers[i].bank = (uint8_t)g->s.rom_bank;
        }
    }
    for (int k = 0; k < 6; k++) {
        uint16_t sp = (uint16_t)(g->s.sp + 2 * k);
        last_stack[page][bank][t][k] = (uint16_t)(gbc_read(g, sp) | (gbc_read(g, (uint16_t)(sp + 1)) << 8));
    }
}

static void shot(const char *what)
{
    if (!shots || nshots >= maxshots) return;
    char path[600];
    snprintf(path, sizeof path, "%s/%02d_%s_f%ld.png", shots, nshots++, what, frames);
    int w, h, stride;
    const uint32_t *px = pb_frame(&pb, &w, &h, &stride);
    png_write_rgb(path, px, w, h, stride, 2);
}

static uint8_t rd(uint16_t a) { return gbc_read(&pb.g, a); }

static long stale_events, window_field_tiles;
static uint8_t stale_seen[2][384];
static void check_window(void)
{
    GBCState *s = &pb.g.s;
    if (!pb.st.unified) return;
    uint8_t lcdc = s->io[0x40], wy = s->io[0x4A];
    if (!(lcdc & 0x80) || !(lcdc & 0x20)) return;
    const GBCPage *m = &s->page[PB_PAGE_MAIN], *o = &s->page[PB_PAGE_TOP];
    uint16_t map = (lcdc & 0x40) ? 0x1C00 : 0x1800;
    int rows = 2;                                        /* status bar: window lines 0-9 */
    if (wy < 0x86) rows = (144 - wy + 7) / 8;            /* raised window: in-game menus */
    for (int r = 0; r < rows && r < 32; r++)
        for (int c = 0; c < 20; c++) {
            uint8_t idx = m->vram[0][map + r * 32 + c], attr = m->vram[1][map + r * 32 + c];
            int t = (lcdc & 0x10) ? idx : 256 + (int8_t)idx, b = (attr >> 3) & 1;
            /* a byte of the tile written to the top page after the main page, and different */
            bool stale = false;
            for (int k = 0; k < 16 && !stale; k++) {
                int a = t * 16 + k;
                stale = last_wb[PB_PAGE_TOP][b][a] > last_wb[PB_PAGE_MAIN][b][a] && m->vram[b][a] != o->vram[b][a];
            }
            if (!stale) continue;
            if (t >= 256) {
                /* tiles of the field's background, never graphics of the window: a transient of
                 * the game (2.5: one frame when the pause menu closes, LCDC already back to the
                 * field's tiles while the window still shows the menu), not a missed copy */
                window_field_tiles++;
                continue;
            }
            stale_events++;
            if (!stale_seen[b][t]) {
                stale_seen[b][t] = 1;
                fprintf(stderr, "frame %ld: stale window tile %d (bank %d) at row %d col %d, written on the top page by %02X:%04X"
                        " (stage %d, screen %d, WY %d)\n", frames, t, b, r, c, last_bank[PB_PAGE_TOP][b][t],
                        last_pc[PB_PAGE_TOP][b][t], rd(W_CurrentStage), rd(W_CurrentScreen), wy);
                fprintf(stderr, "    main:");
                for (int k = 0; k < 16; k++) fprintf(stderr, " %02X", m->vram[b][t * 16 + k]);
                fprintf(stderr, "\n    top: ");
                for (int k = 0; k < 16; k++) fprintf(stderr, " %02X", o->vram[b][t * 16 + k]);
                fprintf(stderr, "\n");
                const uint16_t *sk = last_stack[PB_PAGE_TOP][b][t];
                fprintf(stderr, "    stack: %04X %04X %04X %04X %04X %04X\n", sk[0], sk[1], sk[2], sk[3], sk[4], sk[5]);
                shot("stale");
            }
        }
}

/* tiles used by the window, and by the background / sprites of each page (field only) */
static long used_win[2][384], used_bg[GBC_PAGES][2][384], used_obj[GBC_PAGES][2][384];
static long stage_frames[16], screen_frames[16];
static long dump_at = -1;
static int probe_x = -1, probe_y;
static long every, every_from;
static uint32_t probe_last = 0xFFFFFFFFu;

/* print the tile numbers of the background and window maps of both pages */
static void dump_maps(void)
{
    GBCState *s = &pb.g.s;
    uint8_t lcdc = s->io[0x40];
    bool sd = (lcdc & 0x10) != 0;
    fprintf(stderr, "dump at frame %ld: stage %d LCDC %02X SCY %d WY %d WX %d\n", frames, rd(W_CurrentStage), lcdc,
            s->io[0x42], s->io[0x4A], s->io[0x4B]);
    for (int p = 0; p < GBC_PAGES; p++)
        for (int w = 0; w < 2; w++) {
            uint16_t map = w ? ((lcdc & 0x40) ? 0x1C00 : 0x1800) : ((lcdc & 0x08) ? 0x1C00 : 0x1800);
            if (w == 0) {
                fprintf(stderr, "page %d sprites (y x tile attr):", p);
                for (int i = 0; i < 40; i++) {
                    const uint8_t *o = &s->page[p].oam[i * 4];
                    if (o[0] && o[0] < 168) fprintf(stderr, " [%d]%d,%d,%d,%02X", i, o[0], o[1], o[2], o[3]);
                }
                fprintf(stderr, "\n");
            }
            fprintf(stderr, "page %d %s:\n", p, w ? "window" : "background");
            for (int r = 0; r < (w ? 4 : 18); r++) {
                fprintf(stderr, " %2d:", r);
                for (int c = 0; c < 24; c++) {
                    uint8_t idx = s->page[p].vram[0][map + r * 32 + c], attr = s->page[p].vram[1][map + r * 32 + c];
                    fprintf(stderr, " %s%3d", (attr & 8) ? "*" : "", sd ? idx : 256 + (int8_t)idx);
                }
                fprintf(stderr, "\n     attr:");
                for (int c = 0; c < 24; c++) fprintf(stderr, "  %02X", s->page[p].vram[1][map + r * 32 + c]);
                fprintf(stderr, "\n");
            }
        }
}
static long glow_top[16][4];
static int glow_shots;                          /* -glowshots N: screenshots of the completed halo */
static bool tilt_glow;                          /* -tiltglow: tilts while the halo is on screen */
static int glow_now = 999;                      /* top line of the halo this frame (999: none) */
static long glow_missing;                       /* halo on screen, its upper part not drawn */
static bool glow_ascii;
static bool narrow;                             /* -narrow: the original width */                         /* -glowascii: print the halo sprites once */                   /* [stage][0: none, 1: top at line 0, 2: other, 3: mirrored] */
static void tile_stats(void)
{
    GBCState *s = &pb.g.s;
    stage_frames[rd(W_CurrentStage) & 15]++;
    if (pb.st.unified) {
        /* the bonus slot halo (SlotGlow sprites) of the bottom half: where it starts */
        int top = 999, nglow = 0;
        for (int i = 0; i < 40; i++) {
            const uint8_t *o = &s->page[PB_PAGE_MAIN].oam[i * 4];
            uint8_t t = o[2] & 0xFE;
            if (o[0] && (o[3] & 7) == 7 && ((t >= 0x1A && t <= 0x2E) || t == 0x38) && o[0] - 16 < top) top = o[0] - 16;
            if (o[0] && (o[3] == 0x17 || o[3] == 0x37) && ((t >= 0x1A && t <= 0x2E) || t == 0x38)) nglow++;
        }
        int st = rd(W_CurrentStage) & 15;
        glow_top[st][top == 999 ? 0 : top == 0 ? 1 : 2]++;
        glow_now = top;
        if (nglow >= 6 && top >= -8 && top <= 8 && !pb.g.xobj_n[PB_PAGE_TOP] && (s->io[0x40] & 0x04)) {
            /* (the whole halo: its first frames, as it appears, are a few of its sprites only) */
            /* the halo starts at the top of the half (shaken by a tilt or not): its upper part
             * must be drawn on the top page */
            glow_missing++;
            if (glow_missing <= 3) {
                fprintf(stderr, "frame %ld: slot halo at line %d of the bottom half without its upper part (tilt %d,%d)\n",
                        frames, top, (int8_t)rd(W_LeftRightTiltOffset), (int8_t)rd(W_UpperTiltOffset));
                shot("glow_missing");
            }
        }
        if (pb.g.xobj_n[PB_PAGE_TOP] && glow_ascii) {
            /* the halo sprites (lines 0-31 of the bottom half) as colour indices, once */
            glow_ascii = false;
            const GBCPage *pg = &s->page[PB_PAGE_MAIN];
            char canvas[32][49];
            memset(canvas, '.', sizeof canvas);
            for (int r = 0; r < 32; r++) canvas[r][48] = 0;
            int x0 = 999;
            for (int i = 0; i < 40; i++) { const uint8_t *o = &pg->oam[i * 4]; uint8_t t = o[2] & 0xFE;
                if (o[0] && (o[3] & 7) == 7 && ((t >= 0x1A && t <= 0x2E) || t == 0x38) && o[1] - 8 < x0) x0 = o[1] - 8; }
            for (int i = 0; i < 40; i++) {
                const uint8_t *o = &pg->oam[i * 4];
                uint8_t t = o[2] & 0xFE, at = o[3];
                if (!o[0] || (at & 7) != 7 || !((t >= 0x1A && t <= 0x2E) || t == 0x38)) continue;
                int sy = o[0] - 16, sx = o[1] - 8 - x0;
                for (int row = 0; row < 16; row++) {
                    int rr = (at & 0x40) ? 15 - row : row;
                    const uint8_t *td = &pg->vram[(at >> 3) & 1][t * 16 + rr * 2];
                    for (int px = 0; px < 8; px++) {
                        int bit = (at & 0x20) ? px : 7 - px, ci = ((td[0] >> bit) & 1) | (((td[1] >> bit) & 1) << 1);
                        int y = sy + row, x = sx + px;
                        if (y >= 0 && y < 32 && x >= 0 && x < 48 && ci) canvas[y][x] = (char)('0' + ci);
                    }
                }
            }
            fprintf(stderr, "frame %ld: slot halo sprites (colour index, '.' transparent), left at x=%d:\n", frames, x0);
            for (int r = 0; r < 32; r++) fprintf(stderr, "  %2d %s\n", r, canvas[r]);
        }
        if (pb.g.xobj_n[PB_PAGE_TOP]) {
            glow_top[st][3]++;
            static int shown_glow[16];
            if (glow_shots && shown_glow[st] < glow_shots && glow_top[st][3] % 7 == 1) { shown_glow[st]++; shot("glow"); }
        }
        if (top != 999 && top != 0 && glow_top[st][2] == 1)
            fprintf(stderr, "frame %ld: slot halo starting at line %d of the bottom half (stage %d)\n", frames, top, st);
    }
    screen_frames[rd(W_CurrentScreen) & 15]++;
    if (!pb.st.unified || rd(W_CurrentScreen) != SCREEN_PINBALL_GAME) return;
    uint8_t lcdc = s->io[0x40], wy = s->io[0x4A];
    bool sd = (lcdc & 0x10) != 0;
    for (int p = 0; p < GBC_PAGES; p++) {
        const GBCPage *pg = &s->page[p];
        uint16_t bmap = (lcdc & 0x08) ? 0x1C00 : 0x1800;
        for (int r = 0; r < 18; r++)
            for (int c = 0; c < 25; c++) {
                int k = bmap + r * 32 + (c & 31);
                uint8_t idx = pg->vram[0][k], attr = pg->vram[1][k];
                used_bg[p][(attr >> 3) & 1][sd ? idx : 256 + (int8_t)idx]++;
            }
        for (int i = 0; i < 40; i++) {
            const uint8_t *o = &pg->oam[i * 4];
            if (o[0] == 0 || o[0] >= 160) continue;
            int b = (o[3] >> 3) & 1, t = (lcdc & 0x04) ? (o[2] & 0xFE) : o[2];
            used_obj[p][b][t]++;
            if (lcdc & 0x04) used_obj[p][b][t + 1]++;
        }
    }
    if (!(lcdc & 0x20)) return;
    const GBCPage *m = &s->page[PB_PAGE_MAIN];
    uint16_t wmap = (lcdc & 0x40) ? 0x1C00 : 0x1800;
    int rows = wy < 0x86 ? (144 - wy + 7) / 8 : 2;
    for (int r = 0; r < rows && r < 32; r++)
        for (int c = 0; c < 20; c++) {
            uint8_t idx = m->vram[0][wmap + r * 32 + c], attr = m->vram[1][wmap + r * 32 + c];
            used_win[(attr >> 3) & 1][sd ? idx : 256 + (int8_t)idx]++;
        }
}

/* visual churn: background cells of each page that change from one frame to the next,
 * counted separately for the ball's half and the other half (flicker from redraws) */
static uint32_t churn_prev[GBC_PAGES][18][24], churn_old[GBC_PAGES][18][24];
static long churn_when[GBC_PAGES][18][24];
static long churn[2], churn_frames[2];          /* [0] ball's half, [1] other half */
static long flicker[2], redraw_cells, redraws, last_refresh_count;
static void churn_stats(void)
{
    GBCState *s = &pb.g.s;
    uint8_t R = rd(W_CurrentStage);
    if (!pb.st.unified || rd(W_CurrentScreen) != SCREEN_PINBALL_GAME) { memset(churn_prev, 0, sizeof churn_prev); return; }
    uint8_t lcdc = s->ppu.frame_lcdc;
    bool sd = (lcdc & 0x10) != 0;
    uint16_t map = (lcdc & 0x08) ? 0x1C00 : 0x1800;
    for (int p = 0; p < GBC_PAGES; p++) {
        const GBCPage *pg = &s->page[p];
        int other = (p == PB_PAGE_TOP) != (R == 0 || R == 4);
        long n = 0;
        for (int r = 0; r < (p == PB_PAGE_TOP ? 17 : 18); r++)
            for (int c = 0; c < 24; c++) {
                int k = map + r * 32 + c;
                uint8_t idx = pg->vram[0][k], attr = pg->vram[1][k];
                int t = sd ? idx : 256 + (int8_t)idx, b = (attr >> 3) & 1;
                uint32_t h = 2166136261u;
                h = (h ^ idx) * 16777619u; h = (h ^ attr) * 16777619u;
                for (int i = 0; i < 16; i++) h = (h ^ pg->vram[b][t * 16 + i]) * 16777619u;
                for (int i = 0; i < 8; i++) h = (h ^ pg->bgpal[(attr & 7) * 8 + i]) * 16777619u;
                if (churn_prev[p][r][c] && churn_prev[p][r][c] != h) {
                    n++;
                    /* back to what it was less than 10 frames ago: a flicker */
                    if (h == churn_old[p][r][c] && frames - churn_when[p][r][c] < 10) flicker[other]++;
                    churn_old[p][r][c] = churn_prev[p][r][c];
                    churn_when[p][r][c] = frames;
                }
                churn_prev[p][r][c] = h;
            }
        churn[other] += n;
        churn_frames[other]++;
        if (other && pb.st.stats_refresh != last_refresh_count) { redraw_cells += n; redraws++; }
    }
    last_refresh_count = pb.st.stats_refresh;
}

static void print_set(const char *name, long a[2][384], long b[2][384])
{
    fprintf(stderr, "%s:", name);
    int n = 0;
    for (int bk = 0; bk < 2; bk++)
        for (int t = 0; t < 384; t++) {
            if (!a[bk][t] || (b && !b[bk][t])) continue;
            int e = t;
            while (e + 1 < 384 && a[bk][e + 1] && (!b || b[bk][e + 1])) e++;
            fprintf(stderr, " %d:%d-%d", bk, t, e);
            n += e - t + 1;
            t = e;
        }
    fprintf(stderr, "  (%d tiles)\n", n);
}

/* ---- oracle: what the original game would show on entering each half ----
 * The original game reloads a half completely when the ball enters it (LoadStageData, then
 * the graphics queue), and some routines rely on it (they skip the other half's graphics).
 * Every K frames, on a copy of the machine, both halves are loaded that way; the visible
 * background of each video page is compared with the fresh load. A difference that lasts
 * (animations change and come back) means stale graphics on screen. */
static int oracle_every;
static int oracle_streak[GBC_PAGES][18][24], oracle_reported[GBC_PAGES][18][24];
static long oracle_checks, oracle_events, oracle_info, oracle_fail;
static int oracle_pic_done[GBC_PAGES];
static long oracle_next;
#define ORACLE_PERSIST 20                       /* checks in a row (x K frames) */

static uint32_t *pc_hist;                  /* (bank << 14 | pc & 0x3FFF) for pc >= 0x4000, pc for bank 0 */
static void hist_trace(GBC *g, void *u)
{
    (void)u;
    uint16_t pc = g->s.pc;
    uint32_t k = pc < 0x4000 ? pc : (((uint32_t)(g->s.rom_bank & 63) + 1) << 14) | (pc & 0x3FFF);
    if (pc < 0x8000) pc_hist[k]++;
    /* the path into CleanSpriteBuffer (main loop), once */
    static uint32_t ring[256];
    static int rn, dumped;
    uint32_t e = ((uint32_t)g->s.rom_bank << 24) | ((uint32_t)g->s.sp << 8 >> 8 << 16 >> 16 << 0) | pc;
    e = ((uint32_t)(g->s.rom_bank & 0xFF) << 24) | ((uint32_t)(g->s.sp & 0xFF) << 16) | pc;
    if (rn == 0 || ring[(rn - 1) & 255] != e) ring[rn++ & 255] = e;
    if (pc == 0x0926 && !dumped) {
        dumped = 1;
        fprintf(stderr, "  path into CleanSpriteBuffer (bank:pc spLow), oldest first:\n   ");
        for (int i = rn - 120; i < rn; i++) if (i >= 0) {
            uint32_t x = ring[i & 255];
            uint16_t p = (uint16_t)x;
            if (p >= 0x4000 || i == rn - 1 || (uint16_t)ring[(i - 1) & 255] + 4 < p || (uint16_t)ring[(i - 1) & 255] > p)
                fprintf(stderr, " %02X:%04X/%02X", x >> 24, p, (x >> 16) & 0xFF);
        }
        fprintf(stderr, "\n");
    }
}

static void hist_report(void)
{
    for (int n = 0; n < 12; n++) {
        uint32_t best = 0, bk = 0;
        for (uint32_t k = 0; k < (65u << 14); k++) if (pc_hist[k] > best) { best = pc_hist[k]; bk = k; }
        if (!best) break;
        fprintf(stderr, "    %02X:%04X x%u\n", bk < 0x4000 ? 0 : (bk >> 14) - 1, bk < 0x4000 ? bk : 0x4000 | (bk & 0x3FFF), best);
        pc_hist[bk] = 0;
    }
}

static bool fresh_half(uint8_t stage, int page, GBCPage *out)
{
    GBC *g = &pb.g;
    static int hist_runs;
    bool hist = hist_runs < 1;
    if (hist) {
        if (!pc_hist) pc_hist = (uint32_t *)calloc(65u << 14, sizeof *pc_hist);
        else memset(pc_hist, 0, (65u << 14) * sizeof *pc_hist);
        g->trace_fn = hist_trace;
    }
    uint8_t ball = g->s.wram[W_CurrentStage - 0xC000];
    g->s.wram[W_CurrentStage - 0xC000] = stage;
    /* as the field draws the Red top half without the ball: with the structures a mode asked for */
    uint8_t backup = g->s.wram[W_RedStageStructureBackup - 0xC000];
    if (stage == 0 && ball != stage && !(backup & 0x80))
        g->s.wram[W_StageCollisionState - 0xC000] = (uint8_t)((g->s.wram[W_StageCollisionState - 0xC000] & 1) | backup);
    g->s.halted = false;                                  /* between frames the CPU waits in HALT */
    pb.st.nforced = 0;
    g->s.cpu_page = page;
    g->tile_mirror_page = -1;
    g->fake_lcd_off = true;
    gbc_set_rom_bank(g, B_LoadStageData);                /* between frames, any bank is mapped */
    g->s.hram[0xF8 - 0x80] = B_LoadStageData;            /* hLoadedROMBank */
    bool ok = gbc_call_frozen(g, R_LoadStageData, true, 8000000L);
    int step = 0;
    if (ok) {
        step = 1;
        pb.st.nforced = 0;
        g->s.cpu_page = page;
        ok = gbc_call_frozen(g, 0x113A, false, 8000000L);    /* Func_113a: the graphics queue */
    }
    static int shown;
    if (!ok && shown++ < 4)
        fprintf(stderr, "oracle: %s stuck at %02X:%04X sp=%04X ime=%d halted=%d (stage %d)\n",
                step ? "graphics queue" : "LoadStageData", (int)g->s.rom_bank, g->s.pc, g->s.sp, g->s.ime, g->s.halted, stage);
    if (hist) {
        g->trace_fn = NULL;
        if (!ok) { hist_runs++; fprintf(stderr, "  most executed addresses:\n"); hist_report(); }
    }
    g->fake_lcd_off = false;
    if (ok) memcpy(out, &g->s.page[page], sizeof *out);
    return ok;
}

static void oracle(void)
{
    static GBCState save;
    static PinballState stsave;
    static GBCPage fresh[2];
    GBC *g = &pb.g;
    uint8_t R = rd(W_CurrentStage), scr = rd(W_CurrentScreen);
    if (!pb.st.unified || scr != SCREEN_PINBALL_GAME || !(R == 0 || R == 1 || R == 4 || R == 5)) {
        memset(oracle_streak, 0, sizeof oracle_streak);  /* off the field: the game reloads everything */
        return;
    }
    memcpy(&save, &g->s, sizeof save);
    stsave = pb.st;
    bool flo = g->fake_lcd_off;
    int hs = g->hook_skip, wp = g->win_page, tm = g->tile_mirror_page;
    void (*tr)(GBC *, void *) = g->trace_fn;
    void (*vf)(GBC *, int, int, uint16_t, uint8_t, void *) = g->vram_fn;
    g->trace_fn = NULL;
    g->vram_fn = NULL;
    bool ok[2];
    for (int h = 0; h < 2; h++) {                         /* h 0: top half, 1: bottom half */
        memcpy(&g->s, &save, sizeof save);
        pb.st = stsave;
        ok[h] = fresh_half((uint8_t)(h == 0 ? (R & ~1) : (R | 1)), h == 0 ? PB_PAGE_TOP : PB_PAGE_MAIN, &fresh[h]);
    }
    memcpy(&g->s, &save, sizeof save);
    pb.st = stsave;
    g->fake_lcd_off = flo; g->hook_skip = hs; g->win_page = wp; g->tile_mirror_page = tm;
    g->trace_fn = tr; g->vram_fn = vf;
    if (!ok[0] || !ok[1]) { oracle_fail++; return; }
    oracle_checks++;

    /* A page changes role when the ball changes half: what it showed as the ball's half (a
     * billboard picture...) is legitimate until the field redraws it as the other half. */
    static int last_top = -1;
    int ball_top = R == 0 || R == 4;
    if (ball_top != last_top) memset(oracle_streak, 0, sizeof oracle_streak);
    last_top = ball_top;

    uint8_t lcdc = g->s.ppu.frame_lcdc;                 /* the field is drawn with the LCDC of line 0 */
    bool sd = (lcdc & 0x10) != 0;
    uint16_t map = (lcdc & 0x08) ? 0x1C00 : 0x1800;
    for (int h = 0; h < 2; h++) {
        int p = h == 0 ? PB_PAGE_TOP : PB_PAGE_MAIN, rows = h == 0 ? 17 : 18;
        const GBCPage *a = &g->s.page[p], *f = &fresh[h];
        for (int r = 0; r < rows; r++)
            for (int c = 0; c < 24; c++) {
                int k = map + r * 32 + c;
                uint8_t ia = a->vram[0][k], aa = a->vram[1][k], fi = f->vram[0][k], fa = f->vram[1][k];
                bool diff = ia != fi || aa != fa;
                if (!diff) {
                    int t = sd ? ia : 256 + (int8_t)ia, b = (aa >> 3) & 1, pal = aa & 7;
                    diff = memcmp(&a->vram[b][t * 16], &f->vram[b][t * 16], 16) != 0 ||
                           memcmp(&a->bgpal[pal * 8], &f->bgpal[pal * 8], 8) != 0;
                }
                int *sk = &oracle_streak[p][r][c];
                /* stale graphics stay as they are: a cell that changed recently is animated by
                 * the game (a blinking light differs from its entry state half of the time) */
                if (diff && r < 18 && c < 24 && frames - churn_when[p][r][c] < 2L * oracle_every) diff = false;
                *sk = diff ? *sk + 1 : 0;
                if (*sk == ORACLE_PERSIST && oracle_reported[p][r][c] < 2) {
                    oracle_reported[p][r][c]++;
                    /* The half without the ball is drawn by the field: a lasting difference is stale
                     * graphics. The ball's half is drawn by the game as in the original, which can
                     * show something else than on entering for a long time (billboard messages...). */
                    bool other = (p == PB_PAGE_TOP) != (R == 0 || R == 4);
                    long *count = other ? &oracle_events : &oracle_info;
                    (*count)++;
                    if (*count <= 40)
                        fprintf(stderr, "frame %ld: %s on the %s page, row %d col %d (ball in the %s half,"
                                " stage %d): shown %d/%02X, entering the half would show %d/%02X\n", frames,
                                other ? "stale background" : "ball's half differs from its entry state",
                                p == PB_PAGE_TOP ? "top" : "main", r, c, (R & 1) ? "bottom" : "top", R, ia, aa, fi, fa);
                    char what[64];
                    snprintf(what, sizeof what, "oracle_%s_r%dc%d", p == PB_PAGE_TOP ? "top" : "main", r, c);
                    if (shots && nshots < maxshots && !oracle_pic_done[p]) {
                        /* the frame as shown, and with this page as entering the half would draw it */
                        oracle_pic_done[p] = 1;
                        shot(what);
                        static GBCPage keep;
                        static uint32_t img[GBC_FB_H][GBC_FB_W];
                        memcpy(img, g->fb, sizeof img);
                        memcpy(&keep, &g->s.page[p], sizeof keep);
                        memcpy(&g->s.page[p], f, sizeof keep);
                        int row0 = p == PB_PAGE_TOP ? 0 : PB_TOP_ROWS, n = p == PB_PAGE_TOP ? PB_TOP_ROWS : 144;
                        for (int ly = 0; ly < n; ly++)
                            gbc_render_page_line(g, p, ly, img[row0 + ly], g->s.fw, GBC_BAND_NO_WINDOW | GBC_BAND_FRAME_LCDC);
                        memcpy(&g->s.page[p], &keep, sizeof keep);
                        char path[600];
                        snprintf(path, sizeof path, "%s/%02d_%s_fresh_f%ld.png", shots, nshots++, what, frames);
                        png_write_rgb(path, &img[0][0], g->s.fw, g->s.fh, GBC_FB_W, 2);
                    }
                }
            }
    }
}

/* ---- -force MODE:HALF:FRAME: start a special mode with the game's own routine ----
 * MODE catch / evo, HALF top / bottom (where the ball must be), at the first object logic
 * of the ball's half from FRAME on. For "evo", a Rattata is put in the party if it is empty
 * (the evolution mode needs a Pokemon caught during the game). */
/* -merges: bytes of game state merged from the other half's runs during special modes */
static bool log_merges;
static long merges_n[0x2000][2];                /* [addr - C000][ball in bottom] */
static void on_merge(void *p, uint16_t addr, uint8_t before, uint8_t after, int kind)
{
    (void)p; (void)before; (void)after; (void)kind;
    if (!gbc_read(&pb.g, W_InSpecialMode)) return;
    merges_n[addr - 0xC000][gbc_read(&pb.g, W_CurrentStage) & 1]++;
}
static void merges_report(void)
{
    fprintf(stderr, "merged during special modes (address: merges with the ball at the top / at the bottom):\n");
    for (int i = 0; i < 0x2000; i++)
        if (merges_n[i][0] || merges_n[i][1]) fprintf(stderr, "  %04X: %ld / %ld\n", 0xC000 + i, merges_n[i][0], merges_n[i][1]);
}
static bool verbose_buffers;                   /* -vbuffers */
static int autohit;                            /* -autohit N: hit the catch mode Pokemon every N frames */
static int autohit_half = -1;                  /* -autohithalf top|bottom */
static bool bbcheck;                           /* -bbcheck: grey billboard after 3 hits */
static long bb_bad;
#ifdef PB_REFERENCE
#define FIELD_ON true                           /* the original game: no unified field */
#else
#define FIELD_ON pb.st.unified
#endif
static long mon_invisible;
static uint16_t watchb[16];
static int nwatchb;
static long watchb_from, watchb_to;
static bool antilag;                            /* -antilag: late frames finished out of time */
static int force_kind, force_half;              /* kind 1 catch, 2 evo; half 0 top, 1 bottom */
static long force_at, forced_frame = -1, forced_count;
static bool force_repeat;                       /* -forcerepeat: again each time the mode is over */
/* -bonus LIST:FRAME: the slot sends the ball to a bonus stage (as the game's "go to bonus"
 * reward: wGoingToBonusStage, wNextStage), the stages of LIST in turn (7 Gengar, 9 Mewtwo,
 * 11 Meowth, 13 Diglett, 15 Seel), again each time the ball is back on a table */
static int bonus_list[8], bonus_n, bonus_next;
static long bonus_at, bonus_last = -100000, bonus_count, bonus_frames[16];
static bool hk_bonus(GBC *g)
{
    if (!bonus_n || g->frozen || frames < bonus_at || frames < bonus_last + 1500) return false;
    uint8_t st = gbc_read(g, W_CurrentStage);
    if (!FIELD_ON || gbc_read(g, W_CurrentScreen) != SCREEN_PINBALL_GAME || !(st == 1 || st == 5)) return false;
    if (gbc_read(g, W_InSpecialMode) || !gbc_read(g, W_PinballIsVisible) || gbc_read(g, 0xD495)) return false;
    int stage = bonus_list[bonus_next++ % bonus_n];
    gbc_write(g, 0xD495, 1);                              /* wGoingToBonusStage */
    gbc_write(g, W_MoveToNextScreenState, 1);
    gbc_write(g, 0xD497, (uint8_t)stage);                 /* wNextStage */
    bonus_last = frames;
    if (bonus_count++ < 10) fprintf(stderr, "frame %ld: to the bonus stage %d (from stage %d)\n", frames, stage, st);
    return false;
}

static bool hk_force(GBC *g, void *u)
{
    (void)u;
    if (hk_bonus(g)) return true;
    if (!force_kind || g->frozen || frames < force_at) return false;
    if (forced_frame >= 0 && (!force_repeat || frames < forced_frame + 1500)) return false;
    uint8_t st = gbc_read(g, W_CurrentStage);
    if (!FIELD_ON || gbc_read(g, W_CurrentScreen) != SCREEN_PINBALL_GAME || ((st & 1) != 0) != (force_half == 1))
        return false;
    if (gbc_read(g, W_InSpecialMode) || !gbc_read(g, W_PinballIsVisible)) return false;
    if (force_kind == 2 && gbc_read(g, 0xD460) == 0) {   /* wNumPartyMons, wPartyMons */
        gbc_write(g, 0xD300, 0x12);
        gbc_write(g, 0xD460, 1);
    }
    /* as the game's "callba": the routine runs in real time (it can play a sequence lasting
     * several seconds) and returns to the object logic, which then runs as usual */
    GBCState *s = &g->s;
    gbc_push(g, s->pc);
    s->hram[0x8A - 0x80] = s->a;                          /* hFarCallTempA */
    s->a = 4;
    uint16_t addr = force_kind == 1 ? 0x403F : 0x4AB3;    /* StartCatchEmMode / StartEvolutionMode */
    s->h = (uint8_t)(addr >> 8);
    s->l = (uint8_t)addr;
    s->pc = 0x054F;                                       /* BankSwitch */
    forced_frame = frames;
    if (forced_count++ >= 3 && force_repeat) return true;   /* quietly after the first ones */
    fprintf(stderr, "frame %ld: starting the %s mode with the ball in the %s half (stage %d)\n", frames,
            force_kind == 1 ? "catch" : "evolution", force_half ? "bottom" : "top", st);
    return true;
}

static void force_report(void)
{
    static int reported;
    if (forced_frame < 0 || reported) return;
    if (gbc_read(&pb.g, W_InSpecialMode) || frames > forced_frame + 1200) {
        reported = 1;
        fprintf(stderr, "frame %ld: special mode %d (kind %d), catch mon %d, evolution mon %d, party %d\n", frames,
                gbc_read(&pb.g, W_InSpecialMode), gbc_read(&pb.g, W_SpecialMode), gbc_read(&pb.g, 0xD579),
                gbc_read(&pb.g, 0xD552), gbc_read(&pb.g, 0xD460));
    }
}

/* ---- -evocheck: the evolution mode stays consistent ----
 * The slot opens when the third trinket is collected (Func_20651): open with fewer trinkets
 * means a trinket was "collected" by the other half's run (Bug 1.3_2). Trinkets collected and
 * slot openings are counted. */
static bool evocheck;
static long evo_frames, evo_bad, evo_collects, evo_opens;
static void evo_check(void)
{
    static uint8_t last_n, last_open;
    if (!FIELD_ON || rd(W_CurrentScreen) != SCREEN_PINBALL_GAME) return;
    bool evo = rd(W_InSpecialMode) && rd(W_SpecialMode) == 1;
    uint8_t n = rd(W_NumEvolutionTrinkets), open = rd(W_SlotIsOpen);
    if (evo) {
        evo_frames++;
        if (n > last_n) evo_collects++;
        if (open && !last_open) {
            evo_opens++;
            if (n < 3 && evo_bad++ < 5) {
                fprintf(stderr, "frame %ld: evolution mode, slot open with %d trinket(s) (ball stage %d)\n", frames, n, rd(W_CurrentStage));
                shot("evo_slot");
            }
        }
    }
    last_n = n; last_open = open;
}

/* ---- -hudcheck: the status bar buffer (wBottomMessageBuffer rows +$40 and +$C0) ----
 * With no text shown, the bar holds the icons and the score (Func_8524: leading zeros are not
 * written, the buffer was filled with black when the last text ended). A cell the score does
 * not write must be black: anything else is a leftover (Bug 1.3_1). */
static bool hudcheck;
static long hud_bad;
static struct { uint16_t pc, ret; uint8_t bank, frozen, page, stage, v; long frame; } hud_w[0xC0];
static void on_wram(GBC *g, uint16_t a, uint8_t v, void *u)
{
    (void)u;
    if (a < 0xC640 || a >= 0xC700) return;
    int i = a - 0xC640;
    hud_w[i].pc = g->s.pc; hud_w[i].bank = (uint8_t)g->s.rom_bank; hud_w[i].frozen = (uint8_t)g->frozen;
    hud_w[i].page = (uint8_t)g->s.cpu_page; hud_w[i].stage = gbc_read(g, W_CurrentStage); hud_w[i].v = v;
    hud_w[i].ret = (uint16_t)(gbc_read(g, g->s.sp) | (gbc_read(g, (uint16_t)(g->s.sp + 1)) << 8));
    hud_w[i].frame = frames;
}
static void hud_check(void)
{
    uint8_t st = rd(W_CurrentStage);
    if (!FIELD_ON || rd(W_CurrentScreen) != SCREEN_PINBALL_GAME || !(st == 0 || st == 1 || st == 4 || st == 5)) return;
    if (rd(0xD5CA) || rd(0xD5CB) || !rd(0xD4AA)) return;   /* text shown, scoreboard off, or no bar */
    uint8_t want[2][20];
    bool known[2][20];
    memset(known, 0, sizeof known);
    known[0][3] = true; want[0][3] = 0x81;
    bool lead = true;
    for (int b = 12, k = 0; b >= 1; b--, k++) {
        uint8_t byte = rd((uint16_t)(0xD46A + 5 - k / 2)), d = (k & 1) ? (byte & 15) : (byte >> 4);
        int col = 7 + k;
        bool write = !(d == 0 && b != 1 && lead);
        known[0][col] = known[1][col] = true;
        if (write) { lead = false; want[0][col] = (uint8_t)(0x86 + d); want[1][col] = (b == 12 || b == 9 || b == 6 || b == 3) ? 0x82 : 0x81; }
        else { want[0][col] = 0x81; want[1][col] = 0x81; }
    }
    for (int c = 0; c < 7; c++) { known[1][c] = true; want[1][c] = 0x81; }
    known[1][19] = true; want[1][19] = 0x81;
    /* the tiles shown by the bar: the stage's ones (a special character of an old text left
     * in a digit tile shows stars in the score, Bug 1.3_1) */
    static int tstreak[16];
    const uint8_t *canon = pb.g.rom + 0x9C000;
    const GBCPage *mp = &pb.g.s.page[PB_PAGE_MAIN];
    for (int c = 0; c < 20; c++) {
        uint8_t t = rd((uint16_t)(0xC640 + c));
        if (t < 0x86 || t > 0x8F) continue;                    /* the digits */
        int k = t - 0x80;
        if (!memcmp(&mp->vram[0][0x800 + k * 16], canon + k * 16, 16)) { tstreak[k] = 0; continue; }
        if (++tstreak[k] != 30) continue;
        hud_bad++;
        fprintf(stderr, "frame %ld: status bar tile %02X (col %d) does not show the stage's graphics (ball stage %d,"
                " special mode %d/%d)\n", frames, t, c, st, rd(W_InSpecialMode), rd(W_SpecialMode));
        fprintf(stderr, "    shown:");
        for (int i = 0; i < 16; i++) fprintf(stderr, " %02X", mp->vram[0][0x800 + k * 16 + i]);
        fprintf(stderr, "\n    stage:");
        for (int i = 0; i < 16; i++) fprintf(stderr, " %02X", canon[k * 16 + i]);
        fprintf(stderr, "\n");
        shot("hudtile");
    }
    static int streak[2][20];
    for (int r = 0; r < 2; r++)
        for (int c = 0; c < 20; c++) {
            uint16_t a = (uint16_t)(0xC640 + r * 0x80 + c);
            /* a cell that should be black and stays something else (the score itself changes
             * within a frame: only lasting leftovers count) */
            if (!known[r][c] || want[r][c] != 0x81 || rd(a) == 0x81) { streak[r][c] = 0; continue; }
            if (++streak[r][c] < 30) continue;
            static bool seen[2][20];
            hud_bad++;
            if (seen[r][c]) continue;
            seen[r][c] = true;
            int i = a - 0xC640;
            fprintf(stderr, "frame %ld: status bar cell row %d col %d is %02X instead of %02X (ball stage %d, special mode %d/%d);"
                    " last written f%ld by %02X:%04X (ret %04X) frozen %d page %d stage %d\n", frames, r, c, rd(a), want[r][c],
                    st, rd(W_InSpecialMode), rd(W_SpecialMode), hud_w[i].frame, hud_w[i].bank, hud_w[i].pc, hud_w[i].ret,
                    hud_w[i].frozen, hud_w[i].page, hud_w[i].stage);
            shot("hud");
        }
}

/* ---- self tests: snapshots (format, determinism, refusals), call budget ---- */
static int st_fail;
#define ST_CHECK(c, ...) do { bool ok_ = (c); printf("%s ", ok_ ? "ok  " : "FAIL"); printf(__VA_ARGS__); printf("\n"); if (!ok_) st_fail++; } while (0)

static uint32_t machine_hash(void)
{
    uint32_t h = 2166136261u;
    const uint8_t *p[] = { pb.g.s.wram, (const uint8_t *)pb.g.s.page, (const uint8_t *)pb.g.fb };
    size_t n[] = { sizeof pb.g.s.wram, sizeof pb.g.s.page, sizeof pb.g.fb };
    for (int k = 0; k < 3; k++) for (size_t i = 0; i < n[k]; i++) { h ^= p[k][i]; h *= 16777619u; }
    return h;
}

static void run1(uint8_t held)
{
    pb_run_frame(&pb, held);
    int16_t tmp[4096];
    while (pb_audio(&pb, tmp, 2048) > 0) {}
    frames++;
}

static uint8_t fixed_input(int i) { return (uint8_t)(((i / 7) % 3 == 0 ? GBC_LEFT : 0) | ((i / 11) % 2 ? GBC_A : 0)); }

static int selftest(void)
{
    /* into a game: the start of the bot game (seed 11 reaches the Red field) */
    srand(11);
    uint8_t held = 0;
    while (frames < 3000) {
        if (frames % 5 == 0) {
            uint8_t scr = rd(W_CurrentScreen);
            held = 0;
            if (scr != SCREEN_PINBALL_GAME) { int r = rand() % 100; if (r < 45) held = GBC_A; else if (r < 55) held = GBC_RIGHT; else if (r < 62) held = GBC_LEFT; else if (r < 67) held = GBC_DOWN; else if (r < 70) held = GBC_B; }
            else { if (rand() % 100 < 42) held |= GBC_LEFT; if (rand() % 100 < 42) held |= GBC_A; }
        }
        run1(held);
    }
    ST_CHECK(pb.st.unified, "a game is running on the unified field (stage %d)", rd(W_CurrentStage));

    size_t n = pb_snapshot_size();
    uint8_t *a = (uint8_t *)malloc(n), *b = (uint8_t *)malloc(n + 1);
    pb_snapshot_save(&pb, a);
    for (int i = 0; i < 900; i++) run1(fixed_input(i));
    uint32_t h1 = machine_hash();
    ST_CHECK(pb_snapshot_load(&pb, a, n) == 0, "snapshot loads back (%zu bytes)", n);
    for (int i = 0; i < 900; i++) run1(fixed_input(i));
    ST_CHECK(machine_hash() == h1, "same game after the reload (900 frames, deterministic)");

    uint32_t h = machine_hash();
    memcpy(b, a, n); b[n / 2] ^= 0x01;
    ST_CHECK(pb_snapshot_load(&pb, b, n) != 0 && machine_hash() == h, "one corrupted byte: refused, game unchanged");
    memcpy(b, a, n); b[4]++;                                   /* header: version */
    ST_CHECK(pb_snapshot_load(&pb, b, n) != 0 && machine_hash() == h, "other snapshot version: refused");
    memcpy(b, a, n); b[8] ^= 0x40;                             /* header: layout fingerprint */
    ST_CHECK(pb_snapshot_load(&pb, b, n) != 0 && machine_hash() == h, "other structure layout: refused");
    ST_CHECK(pb_snapshot_load(&pb, a, n - 16) != 0 && pb_snapshot_load(&pb, b, n + 1) != 0, "wrong sizes (old format, truncated): refused");
    memcpy(b + 1, a, n);                                       /* unaligned buffer */
    ST_CHECK(pb_snapshot_load(&pb, b + 1, n) == 0, "snapshot read from an unaligned buffer");

    /* a routine that never returns, called from a hook: gbc_call must give up */
    pb_snapshot_save(&pb, a);
    void (*tr)(GBC *, void *) = pb.g.trace_fn;
    pb.g.trace_fn = NULL;
    gbc_write(&pb.g, 0xC000, 0x18);                            /* jr -2 */
    gbc_write(&pb.g, 0xC001, 0xFE);
    clock_t c0 = clock();
    bool ret = gbc_call(&pb.g, 0xC000);
    double secs = (double)(clock() - c0) / CLOCKS_PER_SEC;
    ST_CHECK(!ret && secs < 10, "endless routine: gbc_call gives up after %ld instructions (%.2f s)", GBC_CALL_BUDGET, secs);
    pb.g.trace_fn = tr;
    ST_CHECK(pb_snapshot_load(&pb, a, n) == 0, "machine restored after the endless call");
    long w0 = wild, r0 = resets;
    for (int i = 0; i < 600; i++) run1(fixed_input(i));
    ST_CHECK(wild == w0 && resets == r0 && pb.st.unified, "game goes on normally afterwards");
    free(a); free(b);
    printf("%s (%d failure%s)\n", st_fail ? "SELFTEST FAILED" : "SELFTEST OK", st_fail, st_fail == 1 ? "" : "s");
    return st_fail ? 1 : 0;
}

int main(int argc, char **argv)
{
    engine_from_env();
    if (argc < 2) { fprintf(stderr, "usage: pbdebug ROM [-frames N] [-seed S] [-shots DIR] [-pause K]\n"); return 2; }
    long nframes = 200000;
    int seed = 1, pause_every = 2500;
    bool do_selftest = false;
    const char *endshot = NULL;
    const char *sram_out = NULL;                /* -savesram PATH: the cartridge save at the end */
    for (int i = 2; i < argc; i++) {
        if (!strcmp(argv[i], "-frames") && i + 1 < argc) nframes = atol(argv[++i]);
        else if (!strcmp(argv[i], "-seed") && i + 1 < argc) seed = atoi(argv[++i]);
        else if (!strcmp(argv[i], "-shots") && i + 1 < argc) shots = argv[++i];
        else if (!strcmp(argv[i], "-pause") && i + 1 < argc) pause_every = atoi(argv[++i]);
        else if (!strcmp(argv[i], "-maxshots") && i + 1 < argc) maxshots = atoi(argv[++i]);
        else if (!strcmp(argv[i], "-dump") && i + 1 < argc) dump_at = atol(argv[++i]);
        else if (!strcmp(argv[i], "-selftest")) do_selftest = true;
        else if (!strcmp(argv[i], "-vbuffers")) verbose_buffers = true;
        else if (!strcmp(argv[i], "-merges")) log_merges = true;
        else if (!strcmp(argv[i], "-autohit") && i + 1 < argc) autohit = atoi(argv[++i]);
        else if (!strcmp(argv[i], "-bbcheck")) bbcheck = true;
        else if (!strcmp(argv[i], "-autohithalf") && i + 1 < argc) { i++; autohit_half = !strcmp(argv[i], "top") ? 0 : !strcmp(argv[i], "bottom") ? 1 : -1; }
        else if (!strcmp(argv[i], "-watchbytes") && i + 3 < argc) {   /* ADDR,ADDR,... F0 F1 (hex addresses) */
            char *p = argv[i + 1];
            while (*p && nwatchb < 16) { watchb[nwatchb++] = (uint16_t)strtol(p, &p, 16); if (*p == ',') p++; }
            watchb_from = atol(argv[i + 2]); watchb_to = atol(argv[i + 3]); i += 3;
        }
        else if (!strcmp(argv[i], "-force") && i + 1 < argc) {
            char mode[16] = "", half[16] = "";
            long at = 0;
            if (sscanf(argv[++i], "%15[a-z]:%15[a-z]:%ld", mode, half, &at) == 3) {
                force_kind = !strcmp(mode, "catch") ? 1 : !strcmp(mode, "evo") ? 2 : 0;
                force_half = !strcmp(half, "bottom");
                force_at = at;
            }
        }
        else if (!strcmp(argv[i], "-glowshots") && i + 1 < argc) glow_shots = atoi(argv[++i]);
        else if (!strcmp(argv[i], "-glowascii")) glow_ascii = true;
        else if (!strcmp(argv[i], "-tiltglow")) tilt_glow = true;
        else if (!strcmp(argv[i], "-othertiles")) other_tiles = true;
        else if (!strcmp(argv[i], "-narrow")) narrow = true;
        else if (!strcmp(argv[i], "-antilag")) antilag = true;
        else if (!strcmp(argv[i], "-hudcheck")) hudcheck = true;
        else if (!strcmp(argv[i], "-forcerepeat")) force_repeat = true;
        else if (!strcmp(argv[i], "-bonus") && i + 1 < argc) {     /* LIST:FRAME, e.g. 7,9,11,13,15:3000 */
            char *p = argv[++i];
            while (*p && *p != ':' && bonus_n < 8) { bonus_list[bonus_n++] = (int)strtol(p, &p, 10); if (*p == ',') p++; }
            if (*p == ':') bonus_at = atol(p + 1);
        }
        else if (!strcmp(argv[i], "-evocheck")) evocheck = true;
        else if (!strcmp(argv[i], "-savesram") && i + 1 < argc) sram_out = argv[++i];
        else if (!strcmp(argv[i], "-oracle") && i + 1 < argc) oracle_every = atoi(argv[++i]);
        else if (!strcmp(argv[i], "-every") && i + 2 < argc) { every = atol(argv[i + 1]); every_from = atol(argv[i + 2]); i += 2; }
        else if (!strcmp(argv[i], "-writewatch") && i + 3 < argc) {    /* hex WRAM address, frames */
            ww_addr = (int)strtol(argv[i + 1], NULL, 16); ww_from = atol(argv[i + 2]); ww_to = atol(argv[i + 3]); i += 3;
        }
        else if (!strcmp(argv[i], "-tracemap") && i + 3 < argc) {      /* VRAM offset of a map cell, main page */
            trace_map = (int)strtol(argv[i + 1], NULL, 16); trace_from = atol(argv[i + 2]); trace_to = atol(argv[i + 3]); i += 3;
        }
        else if (!strcmp(argv[i], "-tracetile") && i + 3 < argc) {
            trace_tile = atoi(argv[i + 1]); trace_from = atol(argv[i + 2]); trace_to = atol(argv[i + 3]); i += 3;
        }
        else if (!strcmp(argv[i], "-endshot") && i + 1 < argc) endshot = argv[++i];
        else if (!strcmp(argv[i], "-probe") && i + 2 < argc) { probe_x = atoi(argv[i + 1]); probe_y = atoi(argv[i + 2]); i += 2; }
    }
    FILE *f = fopen(argv[1], "rb");
    if (!f) { perror(argv[1]); return 2; }
    size_t n = fread(rom, 1, sizeof rom, f);
    fclose(f);
    if (pb_init(&pb, rom, n, 48000)) { fprintf(stderr, "%s\n", pb.error); return 1; }
    pb.g.trace_fn = trace;
    pb.g.vram_fn = on_vram;
    if (ww_addr >= 0) gbc_add_watch(&pb.g, (uint16_t)ww_addr, on_ww, NULL);
    if (force_kind || bonus_n) gbc_add_hook(&pb.g, 0, R_ResolveGameObjectCollisions, hk_force, NULL);
    if (log_merges) pb.merge_fn = on_merge;
    if (narrow) pb_set_narrow(&pb, true);
    if (antilag) pb_set_antilag(&pb, true);
    if (hudcheck) pb.g.wram_fn = on_wram;
    if (do_selftest) { int r = selftest(); pb_free(&pb); return r; }
    srand((unsigned)seed);

    clock_t t0 = clock();
    uint8_t held = 0;
    int pause_step = -1;                /* scripted pause: frames since START */
    long next_pause = pause_every, pauses = 0, pauses_top = 0;
    for (frames = 0; frames < nframes; frames++) {
        uint8_t scr = rd(W_CurrentScreen), st = rd(W_CurrentStage);
        if (pause_step >= 0) {
            /* START (3 frames), wait, A on "CANCEL" (the default choice), wait */
            held = pause_step < 3 ? GBC_START : (pause_step >= 60 && pause_step < 63) ? GBC_A : 0;
            if (pause_step == 50) shot(st == 0 || st == 4 ? "pause_top" : "pause_bottom");
            if (pause_step == 120) { shot(st == 0 || st == 4 ? "after_pause_top" : "after_pause_bottom"); pause_step = -1; }
            else pause_step++;
        } else if (frames % 5 == 0) {
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
                if (tilt_glow && glow_now != 999 && frames % 20 < 5) {   /* shake while the halo is on */
                    static const uint8_t tilts[3] = { GBC_DOWN, GBC_B, GBC_SELECT };
                    held |= tilts[(frames / 20) % 3];
                }
            }
        }
        if (pause_step < 0 && pause_every > 0 && frames >= next_pause && scr == SCREEN_PINBALL_GAME && pb.st.unified &&
            rd(W_PinballIsVisible)) {
            /* alternate: pause with the ball in the top half, then in the bottom half */
            bool top = st == 0 || st == 4;
            if (top == ((pauses & 1) == 0)) {
                pause_step = 0; held = 0; pauses++; if (top) pauses_top++;
                next_pause = frames + pause_every;
            }
        }
        pb_run_frame(&pb, held);
        int16_t tmp[4096];
        while (pb_audio(&pb, tmp, 2048) > 0) {}
        check_window();
        tile_stats();
        churn_stats();
        force_report();
        if (hudcheck) hud_check();
        if (evocheck) evo_check();
        if (bbcheck && pb.st.unified && rd(W_InSpecialMode) && rd(W_SpecialMode) == 0 && rd(0xD5C0) >= 3) {
            /* catch mode, 3 hits: the billboard must not be a grey picture (Bug 1.2_1) */
            int w, h, stride, colored = 0, white = 0, black = 0;
            const uint32_t *px = pb_frame(&pb, &w, &h, &stride);
            for (int y = PB_TOP_ROWS + 32; y < PB_TOP_ROWS + 64; y++)
                for (int x = 56; x < 104; x++) {
                    uint32_t c = px[y * stride + x];
                    int r = (c >> 16) & 255, gg = (c >> 8) & 255, b = c & 255;
                    if (abs(r - gg) > 24 || abs(gg - b) > 24 || abs(r - b) > 24) colored++;
                    else if (r > 200) white++;
                    else if (r < 60) black++;
                }
            if (!colored && white > 40 && black > 40) {
                bb_bad++;
                if (bb_bad <= 3) {
                    fprintf(stderr, "frame %ld: grey billboard after 3 hits (ball in the %s half, state %d, d5c6 %d, capturing %d)\n",
                            frames, (rd(W_CurrentStage) & 1) ? "bottom" : "top", rd(W_SpecialModeState), rd(0xD5C6), rd(0xD5F3));
                    shot("greybillboard");
                }
            }
        }
        if (rd(W_InSpecialMode) && rd(W_SpecialMode) == 0 && rd(0xD5C0) >= 3 && rd(W_SpecialModeState) == 4) {
            /* catch mode, 3 hits: is the Pokemon sprite (tiles $20-$2F, palette 3) drawn with empty tiles? */
            const GBCPage *pg = &pb.g.s.page[PB_PAGE_MAIN];
            int sprites = 0, pixels = 0;
            for (int i = 0; i < 40; i++) {
                const uint8_t *o = &pg->oam[i * 4];
                if (!o[0] || (o[3] & 7) != 3 || o[2] < 0x20 || o[2] > 0x2F) continue;
                sprites++;
                for (int k = 0; k < 32; k++) pixels += pg->vram[(o[3] >> 3) & 1][(o[2] & 0xFE) * 16 + k] != 0;
            }
            if (sprites && !pixels && mon_invisible++ < 3)
                fprintf(stderr, "frame %ld: catch mode Pokemon sprite with empty tiles (%d sprites)\n", frames, sprites);
        }
        if (autohit > 0 && frames % autohit == 0 && (autohit_half < 0 || (rd(W_CurrentStage) & 1) == autohit_half) && rd(W_InSpecialMode) && rd(W_SpecialMode) == 0 && rd(0xD5BB)) {
            /* catch mode, the Pokemon can be hit: what the collision code does when the ball hits it */
            gbc_write(&pb.g, 0xD5BF, 1);                 /* wBallHitWildMon */
            fprintf(stderr, "frame %ld: Pokemon hit (ball in the %s half), hits so far %d\n", frames,
                    (rd(W_CurrentStage) & 1) ? "bottom" : "top", rd(0xD5C0));
        }
        {
            static long last_buffers;
            if (pb.st.stats_buffers != last_buffers) {
                if (verbose_buffers) fprintf(stderr, "frame %ld: billboard buffers kept by a redraw\n", frames);
                last_buffers = pb.st.stats_buffers;
            }
        }
        if (nwatchb && frames >= watchb_from && frames <= watchb_to) {
            /* -watchbytes: values of some WRAM bytes, printed when they change */
            static uint8_t last[16];
            static bool first = true;
            bool ch = first;
            for (int i = 0; i < nwatchb; i++) if (rd(watchb[i]) != last[i]) ch = true;
            if (ch) {
                printf("f%ld stage %d refresh %ld:", frames, rd(W_CurrentStage), pb.st.stats_refresh);
                for (int i = 0; i < nwatchb; i++) { last[i] = rd(watchb[i]); printf(" %04X=%02X", watchb[i], last[i]); }
                printf("\n");
            }
            first = false;
        }
        if (frames == dump_at) dump_maps();
        if (oracle_every > 0 && frames >= oracle_next && pause_step < 0) {
            /* irregular intervals: a light blinking with the same period would always be
             * seen in the same phase (own generator: the bot's choices stay the same) */
            static uint32_t lcg = 12345;
            lcg = lcg * 1103515245u + 12345u;
            oracle_next = frames + oracle_every - 3 + (long)((lcg >> 16) % 7);
            oracle();
        }
        if (every > 0 && frames >= every_from && (frames - every_from) % every == 0) shot("t");
        if (probe_x >= 0 && pb.st.unified) {
            /* colour of one pixel of the composed frame, with the half of the ball */
            int w, h, stride;
            const uint32_t *px = pb_frame(&pb, &w, &h, &stride);
            uint32_t c = px[probe_y * stride + probe_x];
            if (c != probe_last) printf("%ld %d %06X\n", frames, rd(W_CurrentStage), c);
            probe_last = c;
        }
    }
    if (endshot) {
        int w, h, stride;
        const uint32_t *px = pb_frame(&pb, &w, &h, &stride);
        png_write_rgb(endshot, px, w, h, stride, 2);
    }
    double dt = (double)(clock() - t0) / CLOCKS_PER_SEC;
    fprintf(stderr, "%ld frames in %.1fs: unified=%ld swaps=%ld refresh=%ld aborts=%ld wild=%ld resets=%ld "
            "pauses=%ld (top %ld) stale_window=%ld\n", frames, dt, pb.st.stats_frames_unified, pb.st.stats_swaps,
            pb.st.stats_refresh, pb.st.stats_aborts, wild, resets, pauses, pauses_top, stale_events);
    if (antilag) fprintf(stderr, "antilag: %ld frames late at their end, %ld finished out of time; routines of hooks frozen at the end "
                         "of the frame: %ld\n", pb.stats_late, pb.stats_late_done, pb.g.call_late);
#ifndef PB_LEGACY                       /* the output of 2.0 (regress.sh: build/golden19) */
    fprintf(stderr, "sprite lists of the other half at an OAM DMA (ball passing halves in a late frame): %ld; OAM DMAs in a routine called by a hook: %ld\n",
            pb.stats_stale_oam, pb.stats_dma_in_call);
#endif
    if (window_field_tiles)
        fprintf(stderr, "window cells showing tiles of the field's background (a transient of the game): %ld\n", window_field_tiles);
    fprintf(stderr, "out-of-time writes into the window area of the main page (undone by the field): %ld\n", frozen_win_writes);
    for (int i = 0; i < n_ot; i++)
        fprintf(stderr, "other half's logic writing its tiles: page %d stage %d mode %d, %ld bytes %04X-%04X (first frame %ld), stack %04X %04X %04X %04X\n",
                ot[i].page, ot[i].stage, ot[i].mode, ot[i].n, 0x8000 + ot[i].lo, 0x8000 + ot[i].hi, ot[i].first,
                ot[i].w[0], ot[i].w[1], ot[i].w[2], ot[i].w[3]);
    fprintf(stderr, "redraws whose graphics queue buffers (billboard) were kept: %ld\n", pb.st.stats_buffers);
    if (log_merges) merges_report();
    if (evocheck) fprintf(stderr, "evolution mode: %ld frames, %ld trinkets collected, slot opened %ld times, %ld with fewer than 3 trinkets\n", evo_frames, evo_collects, evo_opens, evo_bad);
    if (hudcheck) fprintf(stderr, "status bar cells not matching the score and icons: %ld (cell-frames)\n", hud_bad);
    if (bbcheck) fprintf(stderr, "grey billboard frames after 3 hits: %ld; Pokemon sprite with empty tiles: %ld frames\n", bb_bad, mon_invisible);
    if (oracle_every > 0)
        fprintf(stderr, "oracle: %ld checks (%ld failed), stale_other_half=%ld (ball's half differing from its entry state: %ld)\n",
                oracle_checks, oracle_fail, oracle_events, oracle_info);
    fprintf(stderr, "background cells changing per 1000 frames: ball's half %.0f, other half %.0f\n",
            churn_frames[0] ? 1000.0 * churn[0] / churn_frames[0] : 0, churn_frames[1] ? 1000.0 * churn[1] / churn_frames[1] : 0);
    fprintf(stderr, "flickers (a cell back to its state of < 10 frames before) per 1000 frames: ball's half %.1f, other half %.1f;"
            " cells changed by a redraw of the other half: %.1f on average (%ld redraws)\n",
            churn_frames[0] ? 1000.0 * flicker[0] / churn_frames[0] : 0, churn_frames[1] ? 1000.0 * flicker[1] / churn_frames[1] : 0,
            redraws ? (double)redraw_cells / redraws : 0, redraws);
    if (tilt_glow || glow_missing) fprintf(stderr, "slot halo without its upper part: %ld frames\n", glow_missing);
    for (int i = 0; i < 16; i++)
        if (glow_top[i][1] || glow_top[i][2])
            fprintf(stderr, "slot halo, stage %d: %ld frames starting at the top of the half, %ld elsewhere, %ld mirrored\n",
                    i, glow_top[i][1], glow_top[i][2], glow_top[i][3]);
    fprintf(stderr, "stages:");
    for (int i = 0; i < 16; i++) if (stage_frames[i]) fprintf(stderr, " %d:%ld", i, stage_frames[i]);
    fprintf(stderr, "  screens:");
    for (int i = 0; i < 16; i++) if (screen_frames[i]) fprintf(stderr, " %d:%ld", i, screen_frames[i]);
    fprintf(stderr, "\n");
    for (int i = 0; i < nwriters; i++)
        fprintf(stderr, "top-page writer pc %02X:%04X caller %04X: %ld bytes, VRAM %04X-%04X\n", writers[i].bank,
                writers[i].pc, writers[i].ret, writers[i].n, 0x8000 + writers[i].lo, 0x8000 + writers[i].hi);
    for (int p = 0; p < 2; p++)
        for (int k = 0; k < 2; k++)
            if (qw_n[p][k])
                fprintf(stderr, "queue entries with data in WRAM, %s page%s: %ld, data %04X-%04X\n", p ? "top" : "main",
                        k ? " (out of time)" : "", qw_n[p][k], qw_lo[p][k], qw_hi[p][k]);
    for (int i = 0; i < npalw; i++)
        fprintf(stderr, "main-program palette write %02X:%04X -> FF%02X on page %d: %ld\n", palw[i].bank, palw[i].pc,
                palw[i].reg, palw[i].page, palw[i].n);
    print_set("window tiles", used_win, NULL);
    print_set("  also in top BG", used_win, used_bg[PB_PAGE_TOP]);
    print_set("  also in main BG", used_win, used_bg[PB_PAGE_MAIN]);
    print_set("  also in top OBJ", used_win, used_obj[PB_PAGE_TOP]);
    print_set("  also in main OBJ", used_win, used_obj[PB_PAGE_MAIN]);
    if (sram_out) {
        size_t n;
        const uint8_t *d = pb_sram(&pb, &n);
        FILE *f = fopen(sram_out, "wb");
        if (f) { fwrite(d, 1, n, f); fclose(f); }
    }
    pb_free(&pb);
    return (wild || resets || pb.st.stats_aborts || stale_events || oracle_events || oracle_fail) ? 1 : 0;
}
