/*
 * gbc_ppu.c - LCD timing and scanline renderer (CGB mode), with video pages and bands.
 */
#include "gbc.h"
#include <string.h>

/* The colours of 8 pixels from their colour numbers: one vector table lookup (TBL on ARM64,
 * PSHUFB of SSSE3 on x86-64, which every x86-64 machine running Android or Windows 11 has; it is
 * still checked once on Windows). */
#if defined(__aarch64__) || defined(_M_ARM64)
#include <arm_neon.h>
#define PPU_NEON 1
#elif defined(_M_X64) || defined(__x86_64__)
#include <tmmintrin.h>
#define PPU_SSSE3 1
#ifdef _MSC_VER
#include <intrin.h>
#else
#include <cpuid.h>
#endif
static bool have_ssse3;
#endif

#define LINE_CYCLES 456
#define MODE2_END   80
#define MODE3_END   252
#define NEVER       UINT64_MAX

static uint8_t c5to8[32];
static bool lut_ready;
/* A row of a tile is two bit planes (lo, hi): the colour numbers of its 8 pixels, one per byte
 * (left pixel in the low byte), are SPREAD[lo] | SPREAD[hi] << 1; SPREAD_X for an X-flipped tile. */
static uint64_t SPREAD[256], SPREAD_X[256];

static void init_lut(void)
{
    for (int i = 0; i < 32; i++) c5to8[i] = (uint8_t)((i * 255 + 15) / 31);
    for (int b = 0; b < 256; b++) {
        uint64_t n = 0, x = 0;
        for (int px = 0; px < 8; px++) {
            n |= (uint64_t)((b >> (7 - px)) & 1) << (px * 8);
            x |= (uint64_t)((b >> px) & 1) << (px * 8);
        }
        SPREAD[b] = n;
        SPREAD_X[b] = x;
    }
#ifdef PPU_SSSE3
#ifdef _MSC_VER
    int r[4];
    __cpuid(r, 1);
    have_ssse3 = (r[2] >> 9) & 1;
#else
    /* CPUID itself (__builtin_cpu_supports needs the compiler's runtime library, which the
     * Android link has not) */
    unsigned int ea, eb, ec = 0, ed;
    have_ssse3 = __get_cpuid(1, &ea, &eb, &ec, &ed) && ((ec >> 9) & 1);
#endif
#endif
    lut_ready = true;
}

static inline uint32_t rgb555(const uint8_t *pal, int idx)
{
    uint16_t c = (uint16_t)(pal[idx * 2] | (pal[idx * 2 + 1] << 8));
    return ((uint32_t)c5to8[c & 31] << 16) | ((uint32_t)c5to8[(c >> 5) & 31] << 8) | c5to8[(c >> 10) & 31];
}

/* 64 bytes equal (a palette memory), without the call to memcmp */
static inline bool same64(const uint8_t *a, const uint8_t *b)
{
    uint64_t d = 0;
    for (int i = 0; i < 64; i += 8) {
        uint64_t x, y;
        memcpy(&x, a + i, 8);
        memcpy(&y, b + i, 8);
        d |= x ^ y;
    }
    return d == 0;
}

/* the 32 colours (8 palettes x 4) of a palette memory of a page (obj: the objects'), converted
 * again only when the palette memory changed */
static const uint32_t *pal_cached(GBC *g, int page, int obj)
{
    const uint8_t *src = g->pal_latch ? g->pal_frame[page][obj] : obj ? g->s.page[page].obpal : g->s.page[page].bgpal;
    uint32_t *rgb = g->palc_rgb[page][obj];
    if (!g->palc_ok[page][obj] || !same64(src, g->palc_src[page][obj])) {
        memcpy(g->palc_src[page][obj], src, 64);
        for (int i = 0; i < 32; i++) rgb[i] = rgb555(src, i);
        g->palc_ok[page][obj] = true;
    }
    return rgb;
}

static inline uint64_t tile_row(uint8_t lo, uint8_t hi, bool xflip)
{
    return xflip ? (SPREAD_X[lo] | SPREAD_X[hi] << 1) : (SPREAD[lo] | SPREAD[hi] << 1);
}

#ifdef PPU_SSSE3
#if defined(__clang__) || defined(__GNUC__)
__attribute__((target("ssse3")))
#endif
static void tile_rgb_ssse3(uint32_t *o, uint64_t ci8, const uint32_t *pc)
{
    __m128i pal = _mm_loadu_si128((const __m128i *)pc);          /* 4 colours, 16 bytes */
    __m128i c = _mm_slli_epi16(_mm_cvtsi64_si128((long long)ci8), 2);   /* byte offsets (ci * 4) */
    __m128i d = _mm_unpacklo_epi8(c, c);
    __m128i inc = _mm_set1_epi32(0x03020100);
    _mm_storeu_si128((__m128i *)o, _mm_shuffle_epi8(pal, _mm_add_epi8(_mm_unpacklo_epi16(d, d), inc)));
    _mm_storeu_si128((__m128i *)(o + 4), _mm_shuffle_epi8(pal, _mm_add_epi8(_mm_unpackhi_epi16(d, d), inc)));
}
#endif

/* o[0..7] = the colours pc[] of the 8 colour numbers of ci8 (a byte each, left pixel first) */
static inline void tile_rgb(uint32_t *o, uint64_t ci8, const uint32_t *pc)
{
#if PPU_NEON
    uint8x16_t pal = vld1q_u8((const uint8_t *)pc);
    uint8x8_t c = vshl_n_u8(vcreate_u8(ci8), 2);
    uint8x8x2_t z = vzip_u8(c, c);
    uint16x8_t w = vreinterpretq_u16_u8(vcombine_u8(z.val[0], z.val[1]));
    uint16x8x2_t ww = vzipq_u16(w, w);
    const uint8x16_t inc = vreinterpretq_u8_u32(vdupq_n_u32(0x03020100));
    vst1q_u8((uint8_t *)o, vqtbl1q_u8(pal, vaddq_u8(vreinterpretq_u8_u16(ww.val[0]), inc)));
    vst1q_u8((uint8_t *)(o + 4), vqtbl1q_u8(pal, vaddq_u8(vreinterpretq_u8_u16(ww.val[1]), inc)));
#else
#ifdef PPU_SSSE3
    if (have_ssse3) { tile_rgb_ssse3(o, ci8, pc); return; }
#endif
    o[0] = pc[ci8 & 3]; o[1] = pc[(ci8 >> 8) & 3]; o[2] = pc[(ci8 >> 16) & 3]; o[3] = pc[(ci8 >> 24) & 3];
    o[4] = pc[(ci8 >> 32) & 3]; o[5] = pc[(ci8 >> 40) & 3]; o[6] = pc[(ci8 >> 48) & 3]; o[7] = pc[(ci8 >> 56) & 3];
#endif
}

void gbc_ppu_stat_check(GBC *g)
{
    GBCState *s = &g->s;
    GBCPpu *p = &s->ppu;
    bool line = false;
    if (s->io[0x40] & 0x80) {
        uint8_t stat = s->io[0x41];
        line = ((stat & 0x40) && p->ly == s->io[0x45]) ||
               ((stat & 0x08) && p->mode == 0) ||
               ((stat & 0x10) && p->mode == 1) ||
               ((stat & 0x20) && p->mode == 2);
    }
    if (line && !p->stat_line) s->ifl |= 0x02;
    p->stat_line = line;
}

void gbc_ppu_reset(GBC *g)
{
    GBCState *s = &g->s;
    GBCPpu *p = &s->ppu;
    if (!lut_ready) init_lut();
    p->ly = 0;
    p->win_line = 0;
    p->win_trig = false;
    p->frame_lcdc = s->io[0x40];
    if (s->io[0x40] & 0x80) {
        p->mode = 2;
        p->line_start = s->cycles;
        p->next = s->cycles + MODE2_END;
        if (s->io[0x4A] == 0) p->win_trig = true;
    } else {
        p->mode = -1;
        p->next = NEVER;
    }
    gbc_ppu_stat_check(g);
}

void gbc_ppu_lcdc_write(GBC *g, uint8_t v)
{
    GBCState *s = &g->s;
    uint8_t old = s->io[0x40];
    s->io[0x40] = v;
    if ((old & 0x80) && !(v & 0x80)) {
        s->ppu.mode = -1;
        s->ppu.ly = 0;
        s->ppu.next = NEVER;
        s->ppu.stat_line = false;
    } else if (!(old & 0x80) && (v & 0x80)) {
        gbc_ppu_reset(g);
    }
}

/* Draw window line `wl` over x in [x0, x1), the window's first column being at `wxs`; rgb: the
 * page's background colours (pal_rgb). */
static void draw_window_line(const GBCPage *pg, const uint32_t *rgb, uint8_t lcdc, int wl, int wxs, int x0, int x1,
                             uint32_t *col, uint8_t *bgci, uint8_t *bgpr)
{
    uint16_t map = (lcdc & 0x40) ? 0x1C00 : 0x1800;
    bool udata = (lcdc & 0x10) != 0;
    const uint8_t *mrow0 = &pg->vram[0][map + ((wl >> 3) & 31) * 32];
    const uint8_t *mrow1 = &pg->vram[1][map + ((wl >> 3) & 31) * 32];
    for (int x = wxs > x0 ? wxs : x0; x < x1; ) {
        int wxx = x - wxs;
        uint8_t tile = mrow0[(wxx >> 3) & 31], attr = mrow1[(wxx >> 3) & 31];
        int row = wl & 7;
        if (attr & 0x40) row = 7 - row;
        int taddr = udata ? tile * 16 : 0x1000 + (int8_t)tile * 16;
        const uint8_t *td = &pg->vram[(attr >> 3) & 1][taddr + row * 2];
        uint64_t ci8 = tile_row(td[0], td[1], (attr & 0x20) != 0);
        const uint32_t *pc = &rgb[(attr & 7) * 4];
        uint8_t pr = attr & 0x80;
        for (int px = wxx & 7; px < 8 && x < x1; px++, x++) {
            int ci = (int)(ci8 >> (px * 8)) & 3;
            bgci[x] = (uint8_t)ci;
            bgpr[x] = pr;
            col[x] = pc[ci];
        }
    }
}

static inline int ctz64(uint64_t v)
{
#ifdef _MSC_VER
    unsigned long i;
    _BitScanForward64(&i, v);
    return (int)i;
#else
    return __builtin_ctzll(v);
#endif
}

/* The entries of `oam` (n of them, the 40 bytes of Y read at once) whose sprite covers line ly:
 * a bit each. Covered: 0 <= ly + 16 - Y < h, which is (uint8_t)(ly + 16 - Y) < h (ly + 16 - Y
 * is in [-239, 169]: its negative values are 17 or more as a byte). */
static uint64_t sprites_on_line(const uint8_t *oam, int n, int ly, int h)
{
    uint64_t m = 0;
#if defined(PPU_NEON)
    const uint8x16_t l = vdupq_n_u8((uint8_t)(ly + 16)), hh = vdupq_n_u8((uint8_t)h);
    for (int c = 0; c < 10; c++) {
        uint8x16_t hit = vcltq_u8(vsubq_u8(l, vld1q_u8(oam + 16 * c)), hh);
        /* a nibble per byte: the Y bytes (0, 4, 8, 12) at bits 0, 16, 32, 48 */
        uint64_t nib = vget_lane_u64(vreinterpret_u64_u8(vshrn_n_u16(vreinterpretq_u16_u8(hit), 4)), 0);
        m |= ((nib & 1) | ((nib >> 15) & 2) | ((nib >> 30) & 4) | ((nib >> 45) & 8)) << (4 * c);
    }
#elif defined(PPU_SSSE3)
    const __m128i l = _mm_set1_epi8((char)(ly + 16)), h1 = _mm_set1_epi8((char)(h - 1));
    for (int c = 0; c < 10; c++) {
        __m128i d = _mm_sub_epi8(l, _mm_loadu_si128((const __m128i *)(oam + 16 * c)));
        uint64_t b = (uint64_t)_mm_movemask_epi8(_mm_cmpeq_epi8(_mm_subs_epu8(d, h1), _mm_setzero_si128()));
        m |= ((b & 1) | ((b >> 3) & 2) | ((b >> 6) & 4) | ((b >> 9) & 8)) << (4 * c);
    }
#else
    for (int i = 0; i < 40; i++) m |= (uint64_t)((uint8_t)(ly + 16 - oam[i * 4]) < h) << i;
#endif
    return n < 40 ? m & ((1ull << n) - 1) : m;
}

#define ONES 0x0101010101010101ull

/* Sprites of one line: the first 10 of `oam` (n entries) on line `ly`, with the tiles and
 * object palettes of page `pg`; pixels already set by a sprite (done[]) keep it. The 8 pixels of
 * a sprite at once (a byte each in a 64-bit word): done[], bgci[], bgpr[] have 8 bytes before
 * and after the line, done[] set there (as the pixels out of the line). */
static void draw_sprites_line(const GBCPage *pg, const uint32_t *obrgb, const uint8_t *oam, int n, uint8_t lcdc, int ly,
                              int width, uint32_t *col, const uint8_t *bgci, const uint8_t *bgpr, uint8_t *done,
                              const uint8_t (*priv)[32])
{
    int h = (lcdc & 0x04) ? 16 : 8;
    uint64_t m = sprites_on_line(oam, n, ly, h);
    for (int k = 0; k < 10 && m; k++, m &= m - 1) {
        const uint8_t *o = &oam[ctz64(m) * 4];
        int sy = o[0] - 16, sx = o[1] - 8;
        if (sx <= -8 || sx >= width) continue;       /* no pixel on the line */
        uint8_t tile = o[2], attr = o[3];
        if (h == 16) tile &= 0xFE;
        int row = ly - sy;
        if (attr & 0x40) row = h - 1 - row;
        const uint8_t *td = priv ? &priv[o[2] % 40][row * 2] : &pg->vram[(attr >> 3) & 1][tile * 16 + row * 2];
        uint64_t ci8 = tile_row(td[0], td[1], (attr & 0x20) != 0);
        uint64_t d8;
        memcpy(&d8, &done[sx], 8);
        uint64_t draw = (ci8 | ci8 >> 1) & ~d8 & ONES;     /* a colour (ci != 0), not done */
        if (!draw) continue;
        d8 |= draw;
        memcpy(&done[sx], &d8, 8);
        if (lcdc & 0x01) {                           /* behind a background colour 1-3 with priority */
            uint64_t bc, bp;
            memcpy(&bc, &bgci[sx], 8);
            memcpy(&bp, &bgpr[sx], 8);
            draw &= ~((bc | bc >> 1) & ((attr & 0x80) ? ONES : bp >> 7) & ONES);
        }
        const uint32_t *pc = &obrgb[(attr & 7) * 4];
        for (; draw; draw &= draw - 1) {
            int b = ctz64(draw) >> 3;
            col[sx + b] = pc[(ci8 >> (8 * b)) & 3];
        }
    }
}

/* Status bar band: window lines 0..nlines-1, 160 pixels wide, centred in the frame. */
static void render_status_band(GBC *g, const GBCBand *b)
{
    GBCState *s = &g->s;
    const GBCPage *pg = &s->page[b->page];
    uint8_t lcdc = s->io[0x40], wy = s->io[0x4A], wx = s->io[0x4B];
    bool show = (lcdc & 0x80) && (lcdc & 0x20) && wy >= b->wy;
    int w = s->fw, x0 = w > 160 ? (w - 160) / 2 : 0, x1 = x0 + (w < 160 ? w : 160);
    uint8_t bgci[GBC_FB_W], bgpr[GBC_FB_W];
    const uint32_t *rgb = pal_cached(g, b->page, 0);
    for (int k = 0; k < b->nlines; k++) {
        int row = b->row0 + k;
        if (row < 0 || row >= s->fh) break;
        uint32_t *out = g->fb[row];
        memset(out, 0, sizeof(uint32_t) * (size_t)w);
        if (show) draw_window_line(pg, rgb, lcdc, k, x0 + wx - 7, x0, x1, out, bgci, bgpr);
    }
}

/* Render one line of `page` (LY = ly) into out[0..width). */
void gbc_render_page_line(GBC *g, int page, int ly, uint32_t *out, int width, int flags)
{
    gbc_render_band_line(g, page, ly, out, width, flags, 0);
}

void gbc_render_band_line(GBC *g, int page, int ly, uint32_t *out, int width, int flags, uint8_t wy_high)
{
    GBCState *s = &g->s;
    GBCPpu *p = &s->ppu;
    GBCPage *pg = &s->page[page];
    uint8_t lcdc = (flags & GBC_BAND_FRAME_LCDC) ? p->frame_lcdc : s->io[0x40];
    uint8_t scy = s->io[0x42], scx = s->io[0x43], wy = s->io[0x4A], wx = s->io[0x4B];
    /* colour numbers and priorities of the background (8 more bytes on both sides: draw_sprites_line) */
    uint8_t bgci_p[GBC_FB_W + 16], bgpr_p[GBC_FB_W + 16], *bgci = bgci_p + 8, *bgpr = bgpr_p + 8;
    uint32_t *col = out;                          /* drawn in place */
    const uint32_t *bgrgb = pal_cached(g, page, 0);

    if (width > GBC_FB_W) width = GBC_FB_W;
    memset(bgci_p, 0, 8);
    memset(bgpr_p, 0, 8);
    memset(bgci + width, 0, 8);
    memset(bgpr + width, 0, 8);
    if ((flags & GBC_BAND_WIN_HIGH) && wy >= wy_high) flags |= GBC_BAND_NO_WINDOW;

    /* background: a tile row at a time */
    {
        uint16_t map = (lcdc & 0x08) ? 0x1C00 : 0x1800;
        bool udata = (lcdc & 0x10) != 0;
        int y = (ly + scy) & 0xFF;
        const uint8_t *mrow0 = &pg->vram[0][map + (y >> 3) * 32];
        const uint8_t *mrow1 = &pg->vram[1][map + (y >> 3) * 32];
        int x = 0;
        while (x < width) {
            int xx = (x + scx) & 0xFF;
            uint8_t tile = mrow0[xx >> 3], attr = mrow1[xx >> 3];
            int row = y & 7;
            if (attr & 0x40) row = 7 - row;
            int taddr = udata ? tile * 16 : 0x1000 + (int8_t)tile * 16;
            const uint8_t *td = &pg->vram[(attr >> 3) & 1][taddr + row * 2];
            uint64_t ci8 = tile_row(td[0], td[1], (attr & 0x20) != 0);
            const uint32_t *pc = &bgrgb[(attr & 7) * 4];
            uint8_t pr = attr & 0x80;
            if (!(xx & 7) && x + 8 <= width) {
                /* a whole tile: its 8 colour numbers are the 8 bytes of ci8 */
                memcpy(&bgci[x], &ci8, 8);
                memset(&bgpr[x], pr, 8);
                tile_rgb(&col[x], ci8, pc);
                x += 8;
                continue;
            }
            for (int px = xx & 7; px < 8 && x < width; px++, x++) {
                int ci = (int)(ci8 >> (px * 8)) & 3;
                bgci[x] = (uint8_t)ci;
                bgpr[x] = pr;
                col[x] = pc[ci];
            }
        }
    }

    /* window */
    if ((lcdc & 0x20) && !(flags & GBC_BAND_NO_WINDOW) && p->win_trig && wx < width + 7) {
        int wend = (flags & GBC_BAND_WIN_CLIP) && width > 160 ? 160 : width;
        for (int x = wend; x < width; x++) { col[x] = 0; bgci[x] = 0; bgpr[x] = 0; }
        draw_window_line(pg, bgrgb, lcdc, p->win_line, wx - 7, 0, wend, col, bgci, bgpr);
        p->win_drawn_line = true;
    }

    /* sprites: the page's own, then its extra sprites (see GBC.xobj) */
    if (lcdc & 0x02) {
        uint8_t done_p[GBC_FB_W + 16], *done = done_p + 8;
        memset(done_p, 1, 8);                     /* out of the line: as done */
        memset(done, 0, (size_t)width);
        memset(done + width, 1, 8);
        draw_sprites_line(pg, pal_cached(g, page, 1), pg->oam, 40, lcdc, ly, width, col, bgci, bgpr, done, NULL);
        if (g->xobj_n[page] && g->xobj_src[page] >= 0)
            draw_sprites_line(&s->page[g->xobj_src[page]], pal_cached(g, g->xobj_src[page], 1), g->xobj[page], g->xobj_n[page],
                              lcdc, ly, width, col, bgci, bgpr, done,
                              g->xobj_private[page] ? (const uint8_t (*)[32])g->xobj_tiles[page] : NULL);
    }
}

static void latch_palettes(GBC *g)
{
    for (int p = 0; p < GBC_PAGES; p++) {
        memcpy(g->pal_frame[p][0], g->s.page[p].bgpal, 64);
        memcpy(g->pal_frame[p][1], g->s.page[p].obpal, 64);
    }
}

const uint8_t *gbc_frame_bgpal(const GBC *g, int page)
{
    return g->pal_latch ? g->pal_frame[page][0] : g->s.page[page].bgpal;
}

void gbc_set_frame_palettes(GBC *g, bool on)
{
    g->pal_latch = on;
    latch_palettes(g);
}

static void render_bands(GBC *g, int ly)
{
    GBCState *s = &g->s;
    if (ly == 0 && g->pal_latch) latch_palettes(g);
    s->ppu.win_drawn_line = false;
    for (int i = 0; i < s->nbands; i++) {
        const GBCBand *b = &s->band[i];
        if (b->flags & GBC_BAND_STATUS) {
            if (ly == b->line0) render_status_band(g, b);
            continue;
        }
        if (ly < b->line0 || ly >= b->line0 + b->nlines) continue;
        int row = b->row0 + (ly - b->line0);
        if (row < 0 || row >= s->fh) continue;
        gbc_render_band_line(g, b->page, ly, g->fb[row], s->fw, b->flags, b->wy);
    }
    if (s->ppu.win_drawn_line) s->ppu.win_line++;
}

void gbc_ppu_update(GBC *g)
{
    GBCState *s = &g->s;
    GBCPpu *p = &s->ppu;
    while (s->cycles >= p->next) {
        switch (p->mode) {
        case 2:
            p->mode = 3;
            p->next = p->line_start + MODE3_END;
            break;
        case 3:
            render_bands(g, p->ly);
            p->mode = 0;
            p->next = p->line_start + LINE_CYCLES;
            gbc_ppu_stat_check(g);
            break;
        case 0:
        case 1:
            p->line_start += LINE_CYCLES;
            p->ly++;
            if (p->ly == 144) {
                p->mode = 1;
                s->ifl |= 0x01;
                g->frame_done = true;
                s->frame_count++;
            } else if (p->ly == 154) {
                p->ly = 0;
                p->mode = 2;
                p->win_line = 0;
                p->win_trig = false;
                p->frame_lcdc = s->io[0x40];
            } else if (p->ly < 144) {
                p->mode = 2;
            }
            if (p->mode == 2) {
                if (s->io[0x4A] == p->ly) p->win_trig = true;
                p->next = p->line_start + MODE2_END;
            } else {
                p->next = p->line_start + LINE_CYCLES;
            }
            gbc_ppu_stat_check(g);
            break;
        default:
            p->next = NEVER;
            return;
        }
    }
}
