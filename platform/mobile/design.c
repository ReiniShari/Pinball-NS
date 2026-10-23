/*
 * design.c - "New Design": the screen of the Android version as one picture (see design.h).
 *
 * Everything is drawn in game pixels. The parts drawn here take the colours and the art of the
 * game: the frame of the Red table (red, yellow-green lines, its rivets), the walls of the Blue
 * table (its screws, the wall of the launch lane), the flippers of the game in the flipper keys,
 * the lane guides in the TILT pad (blue on the Red table, green on the Blue one), the lavender
 * and dark grey of the menus for their keys. The bonus stages and the menus go on below the
 * game with what the game itself shows (its tiles, its palettes, its background colour).
 */
#include "design.h"
#include "../../src/front/font5x7.h"
#include "../../src/game/pinball_us.h"
#include <math.h>
#include <stdlib.h>
#include <string.h>

#define C_BLACK   0x000000u
#define C_WHITE   0xFFFFFFu
#define C_RED     0xFF0000u
#define C_YELLOW  0xC5FF00u          /* lines of the Red table */
#define C_RIVET   0x190000u          /* its rivets */
#define C_BLUE    0x005AFFu          /* the Blue table, the guides of the Red one */
#define C_LBLUE   0x5ACEFFu
#define C_GREEN   0x21BD6Bu          /* the guides of the Blue table */
#define C_DGREEN  0x006B21u
#define C_SHADE   0xADADDEu          /* lavender shading of the flippers and keys */
#define C_INK     0x31294Au          /* letters of the keys */
#define C_LAV     0x7B7BADu          /* the keys of the menus */
#define C_DARK    0x292929u          /* the dark grey of the high scores */
#define C_HINT    0x635273u

/* the three sets of controls */
typedef struct {
    uint32_t ring, well;             /* flipper keys: the rim and the inside */
    uint32_t pad, pad_dark, pad_lit; /* the pad: its face, edges and arrows, a pressed arm */
    bool letters;                    /* B and A on white keys (menus), else the flippers */
} KeySet;

static const KeySet SETS[3] = {
    { C_LBLUE, C_BLUE, C_LBLUE, C_BLUE, C_BLUE, false },
    { C_GREEN, C_DGREEN, C_GREEN, C_DGREEN, C_DGREEN, false },
    { C_LAV, C_WHITE, C_LAV, C_DARK, 0x4A4A7Bu, true },
};

#define BLOCK_H   65                 /* rows from the status bar to the bottom in the design */
/* the funnels under the status bar: half width, depth, bands of lines under the outline */
#define RED_HV     13
#define RED_DEPTH  9
#define RED_BANDS  3
#define BLUE_HV    11
#define BLUE_DEPTH 8
#define BLUE_BANDS 7
#define BLOCK_MIN 44                 /* the least room the controls get (smaller keys) */
#define PILL_W    26
#define PILL_H    8

/* ------------------------------------------------------------------ drawing on the canvas */

typedef struct { uint32_t *p; int w, h; int to_white, to_black; } Canvas;

static uint32_t mix(uint32_t a, uint32_t b, int num, int den)  /* a + (b - a) * num / den */
{
    int r = (int)((a >> 16) & 255), g = (int)((a >> 8) & 255), bl = (int)(a & 255);
    r += (((int)((b >> 16) & 255) - r) * num) / den;
    g += (((int)((b >> 8) & 255) - g) * num) / den;
    bl += (((int)(b & 255) - bl) * num) / den;
    return ((uint32_t)r << 16) | ((uint32_t)g << 8) | (uint32_t)bl;
}

/* the drawn parts follow the fades of the game */
static uint32_t faded(const Canvas *c, uint32_t col)
{
    if (c->to_white) col = mix(col, C_WHITE, c->to_white, 256);
    if (c->to_black) col = mix(col, C_BLACK, c->to_black, 256);
    return col;
}

static inline void put_raw(Canvas *c, int x, int y, uint32_t col)
{
    if ((unsigned)x < (unsigned)c->w && (unsigned)y < (unsigned)c->h) c->p[y * c->w + x] = col;
}

static inline void put(Canvas *c, int x, int y, uint32_t col) { put_raw(c, x, y, faded(c, col)); }

static void fill(Canvas *c, int x, int y, int w, int h, uint32_t col)
{
    col = faded(c, col);
    for (int j = y < 0 ? 0 : y; j < y + h && j < c->h; j++)
        for (int i = x < 0 ? 0 : x; i < x + w && i < c->w; i++) c->p[j * c->w + i] = col;
}

/* small pictures: one character per pixel, '.' transparent; mirror: flipped left-right */
static void sprite(Canvas *c, int x, int y, const char *const *rows, int n, const uint32_t *pal, bool mirror)
{
    for (int j = 0; j < n; j++) {
        int w = (int)strlen(rows[j]);
        for (int i = 0; i < w; i++) {
            char ch = rows[j][i];
            if (ch >= '0' && ch <= '9') put(c, mirror ? x + w - 1 - i : x + i, y + j, pal[ch - '0']);
        }
    }
}

static int text_w(const char *s) { int n = utf8_len(s); return n > 0 ? n * FONT_CELL_W - 1 : 0; }

static void text(Canvas *c, int x, int y, const char *s, uint32_t col)
{
    while (*s) {
        const FontGlyph *g = font_glyph(utf8_next(&s));
        for (int r = 0; r < FONT_H; r++)
            for (int k = 0; k < FONT_W; k++)
                if (g->rows[r] & (0x10 >> k)) put(c, x + k, y + r, col);
        x += FONT_CELL_W;
    }
}

/* letters with an outline, as the menus of the title screen */
static void text_outlined(Canvas *c, int x, int y, const char *s, uint32_t col, uint32_t outline)
{
    static const int d[8][2] = { { -1, -1 }, { 0, -1 }, { 1, -1 }, { -1, 0 }, { 1, 0 }, { -1, 1 }, { 0, 1 }, { 1, 1 } };
    for (int k = 0; k < 8; k++) text(c, x + d[k][0], y + d[k][1], s, outline);
    text(c, x, y, s, col);
}

/* a bitmap ('X' set), with an outline when outline != col */
static void bitmap(Canvas *c, int x, int y, const char *const *rows, int n, uint32_t col, uint32_t outline, bool outlined)
{
    int w = (int)strlen(rows[0]);
    if (outlined)
        for (int j = -1; j <= n; j++)
            for (int i = -1; i <= w; i++) {
                bool on = false;
                for (int dy = -1; dy <= 1 && !on; dy++)
                    for (int dx = -1; dx <= 1 && !on; dx++) {
                        int jj = j + dy, ii = i + dx;
                        if (jj >= 0 && jj < n && ii >= 0 && ii < w && rows[jj][ii] == 'X') on = true;
                    }
                if (on) put(c, x + i, y + j, outline);
            }
    for (int j = 0; j < n; j++)
        for (int i = 0; rows[j][i]; i++)
            if (rows[j][i] == 'X') put(c, x + i, y + j, col);
}

/* rounded box (pill): rows shortened near the corners */
static int corner_cut(int r, int dy)       /* pixels cut at a row dy (0 = first) of a corner of radius r */
{
    if (dy >= r) return 0;
    float yy = r - dy - 0.5f;
    return (int)floorf(r - sqrtf((float)r * r - yy * yy) + 0.5f);
}

static void round_box(Canvas *c, int x, int y, int w, int h, int r, uint32_t col)
{
    for (int j = 0; j < h; j++) {
        int dy = j < h - 1 - j ? j : h - 1 - j;
        int cut = corner_cut(r, dy);
        fill(c, x + cut, y + j, w - 2 * cut, 1, col);
    }
}

static void pokeball(Canvas *c, int x, int y)
{
    static const char *const rows[] = {
        "..000..",
        ".02210.",
        "0222220",
        "0003000",
        "0333330",
        ".04440.",
        "..000..",
    };
    static const uint32_t pal[] = { C_BLACK, C_WHITE, C_RED, C_WHITE, C_SHADE };
    sprite(c, x, y, rows, 7, pal, false);
}

/* ------------------------------------------------------------------ the letters of the keys */

/* MENU / START: a small font, 5 rows */
static const struct { char ch; const char *rows[5]; } SMALL[] = {
    { 'M', { "X...X", "XX.XX", "X.X.X", "X...X", "X...X" } },
    { 'E', { "XXX", "X..", "XX.", "X..", "XXX" } },
    { 'N', { "X..X", "XX.X", "X.XX", "X..X", "X..X" } },
    { 'U', { "X.X", "X.X", "X.X", "X.X", "XXX" } },
    { 'S', { "XXX", "X..", "XXX", "..X", "XXX" } },
    { 'T', { "XXX", ".X.", ".X.", ".X.", ".X." } },
    { 'A', { ".X.", "X.X", "XXX", "X.X", "X.X" } },
    { 'R', { "XX.", "X.X", "XX.", "X.X", "X.X" } },
};

static const char *const *small_glyph(char ch)
{
    for (size_t i = 0; i < sizeof SMALL / sizeof SMALL[0]; i++) if (SMALL[i].ch == ch) return SMALL[i].rows;
    return NULL;
}

static int small_w(const char *s)
{
    int w = 0;
    for (; *s; s++) { const char *const *g = small_glyph(*s); if (g) w += (int)strlen(g[0]) + 1; }
    return w > 0 ? w - 1 : 0;
}

static void small_text(Canvas *c, int x, int y, const char *s, uint32_t col)
{
    for (; *s; s++) {
        const char *const *g = small_glyph(*s);
        if (!g) continue;
        bitmap(c, x, y, g, 5, col, col, false);
        x += (int)strlen(g[0]) + 1;
    }
}

/* TILT, in the strokes of the game's big letters (two pixels) */
static const char *const BIG_T[9] = { "XXXXXX", "XXXXXX", "..XX..", "..XX..", "..XX..", "..XX..", "..XX..", "..XX..", "..XX.." };
static const char *const BIG_I[9] = { "XXXXXX", "XXXXXX", "..XX..", "..XX..", "..XX..", "..XX..", "..XX..", "XXXXXX", "XXXXXX" };
static const char *const BIG_L[9] = { "XX....", "XX....", "XX....", "XX....", "XX....", "XX....", "XX....", "XXXXXX", "XXXXXX" };
/* B and A of the keys of the menus */
static const char *const BIG_B[10] = { "XXXXX..", "XXXXXX.", "XX..XX.", "XX..XX.", "XXXXX..", "XXXXXX.", "XX...XX", "XX...XX", "XXXXXXX", "XXXXXX." };
static const char *const BIG_A[10] = { "..XXX..", ".XXXXX.", "XXX.XXX", "XX...XX", "XX...XX", "XXXXXXX", "XXXXXXX", "XX...XX", "XX...XX", "XX...XX" };

/* ------------------------------------------------------------------ the art of the tables */

/* a screw of the Blue table (its top corners), and a rivet of the Red table's frame */
static const char *const SCREW[13] = {
    ".....0000....",
    "..2...00000..",
    ".22.21112000.",
    ".2.110001100.",
    "2.21021101200",
    "2.10220110100",
    "2.10200010100",
    "2.10..02201.0",
    "1.210.22012..",
    ".1.1100011...",
    ".11.21112.22.",
    "..11.....22..",
    "....12222....",
};
static const char *const RIVET[4] = { ".00.", "0120", "02.0", ".00." };

/* ------------------------------------------------------------------ layout */

static int fdiv(int a, int b) { return a >= 0 ? a / b : -((-a + b - 1) / b); }

/* the last row of a funnel's lines, under the status bar (its tip) */
static int funnel_bottom(int hv, int depth, int nb) { return -1 + fdiv((hv - 1) * depth, hv) + nb; }

void nd_layout(NdLayout *L, int sw, int sh, int inset_t, int inset_b, int corner, int gw, int gh, int scene)
{
    memset(L, 0, sizeof *L);
    L->scene = scene;
    if (sw < 1) sw = 1;
    if (sh < 1) sh = 1;
    if (gw < 1) gw = ND_W;
    if (gh < 1) gh = 144;
    L->sw = sw;
    L->sh = sh;
    /* as wide as the screen; a screen too short for the table and its controls gets a smaller
     * picture (then black on both sides: nothing is added beside the game) */
    float s = (float)sw / ND_W;
    float smax = (float)sh / (gh + BLOCK_MIN);
    if (s > smax) s = smax;
    if (s < 0.01f) s = 0.01f;
    int cw = (int)ceilf(sw / s - 0.01f), ch = (int)ceilf(sh / s - 0.01f);
    if (cw > ND_MAX_W) cw = ND_MAX_W;
    if (ch > ND_MAX_H) ch = ND_MAX_H;
    L->scale = s;
    L->cw = cw;
    L->ch = ch;
    L->vh = (int)floorf(sh / s + 0.01f);
    if (L->vh > ch) L->vh = ch;
    L->gw = gw;
    L->gh = gh;
    L->gx = (cw - gw) / 2;
    int it = (int)ceilf(inset_t / s - 0.01f), ib = (int)ceilf(inset_b / s - 0.01f);
    L->bottom = L->vh - ib;
    /* under the camera cut-out when the controls keep the room of the design, else higher (the
     * table then goes under it: its top is the frame) */
    int room = L->bottom - gh - BLOCK_H;
    L->gy = room <= 0 ? 0 : room < it ? room : it;
    L->corner = (int)lroundf(corner / s);

    /* the controls: anchored at the bottom, smaller when the room is short */
    int avail = L->bottom - (L->gy + gh);
    float f = avail >= BLOCK_H ? 1.0f : (avail - 5) / 60.0f;
    if (f < 0.5f) f = 0.5f;
    int pad = (int)lroundf(48 * f), key = (int)lroundf(32 * f);
    if (pad < 24) pad = 24;
    if (key < 16) key = 16;
    int b = L->bottom, x0 = L->gx;
    int pad_y = b - 6 - pad;
    if (avail < BLOCK_H) pad_y = b - (int)lroundf(6 * f) - pad;
    L->btn[ND_PAD] = (NdRect){ x0 + ND_W / 2 - pad / 2, pad_y, pad, pad };
    L->btn[ND_LFLIP] = (NdRect){ x0 + 5, pad_y + (pad - key) / 2, key, key };
    L->btn[ND_RFLIP] = (NdRect){ x0 + ND_W - 5 - key, pad_y + (pad - key) / 2, key, key };
    /* on a table, the pad is centred in the room left between the tip of the funnel and the
     * bottom (the line of the frame on the Red table) */
    if (avail >= BLOCK_H && (scene == ND_SCENE_RED || scene == ND_SCENE_BLUE)) {
        bool red = scene == ND_SCENE_RED;
        int top = L->gy + gh + 1 + (red ? funnel_bottom(RED_HV, RED_DEPTH, RED_BANDS) : funnel_bottom(BLUE_HV, BLUE_DEPTH, BLUE_BANDS));
        int lim = red ? L->vh - 3 : L->vh;
        int py = top + (lim - top - (pad + 1)) / 2;
        if (py + pad + 1 > lim) py = lim - pad - 1;
        if (py < top) py = top;
        L->btn[ND_PAD].y = py;
    }
    int pill_y = b - (int)lroundf(60 * f);
    if (pill_y < L->gy + gh + 4) pill_y = L->gy + gh + 4;
    L->btn[ND_MENU] = (NdRect){ x0 + 19, pill_y, PILL_W, PILL_H };
    L->btn[ND_START] = (NdRect){ x0 + ND_W - 19 - PILL_W, pill_y, PILL_W, PILL_H };

    /* the screens of the Game Boy's size: centred between the top and the controls (never under
     * the camera cut-out); what they show continues above and below them */
    int ctl_top = pill_y - 3;
    if (scene != ND_SCENE_RED && scene != ND_SCENE_BLUE && gh <= PB_STAGE_H) {
        int cy = (ctl_top - gh) / 2;
        if (cy > L->gy) L->gy = cy;
    }
    L->play_h = L->gy + gh > ctl_top ? L->gy + gh : ctl_top;
}

void nd_play_rect(const NdLayout *L, float *x, float *y, float *w, float *h)
{
    *x = L->gx * L->scale;
    *y = 0;
    *w = L->gw * L->scale;
    *h = L->play_h * L->scale;
}

void nd_game_rect(const NdLayout *L, float *x, float *y, float *w, float *h)
{
    *x = L->gx * L->scale;
    *y = L->gy * L->scale;
    *w = L->gw * L->scale;
    *h = L->gh * L->scale;
}

/* The shapes of the controls as they are drawn (draw_pill, draw_key, draw_pad), shadows included,
 * at a pixel of the canvas: a pill (rounded box), a flipper key (octagon), the pad (the cross: the arm,
 * ND_DIR_*; 0 its centre; -1 outside). */
static bool in_pill(const NdRect *r, int px, int py)
{
    for (int s = 0; s <= 1; s++) {                                  /* the pill, its shadow a row lower */
        int j = py - (r->y + s);
        if (j < 0 || j >= r->h) continue;
        int cut = corner_cut(3, j < r->h - 1 - j ? j : r->h - 1 - j);
        if (px >= r->x + cut && px < r->x + r->w - cut) return true;
    }
    return false;
}

static bool in_key(const NdRect *r, int px, int py)
{
    int n = r->w, x = px - r->x, y = py - r->y;
    if (x < 0 || y < 0 || x >= n || y >= n) return false;
    int dx = x < n - 1 - x ? x : n - 1 - x, dy = y < n - 1 - y ? y : n - 1 - y;
    return dx + dy >= n / 4;
}

static int in_pad(const NdRect *r, int px, int py)
{
    int n = r->w, a = n / 3 + ((n / 3) % 2 == 0 ? 1 : 0), half = n / 2, ha = a / 2;
    int x = px - (r->x + half), y = py - (r->y + half);
    if (y == half) y = half - 1;                                    /* its shadow */
    if (x < -half || x >= half || y < -half || y >= half) return -1;
    int X = x < 0 ? -x - 1 : x, Y = y < 0 ? -y - 1 : y;
    if (!((X <= ha && Y < half) || (Y <= ha && X < half))) return -1;
    if (Y <= ha && X > ha) return x < 0 ? ND_DIR_LEFT : ND_DIR_RIGHT;
    if (X <= ha && Y > ha) return y < 0 ? ND_DIR_UP : ND_DIR_DOWN;
    return 0;
}

/*
 * The control under a point of the screen: below the play area only (the halves of the game, which
 * play the flippers, end where the controls begin), on the pixels of its picture only: the octagon of
 * a flipper key, the cross of the pad (its arm: one direction, a tilt never comes with another one),
 * the rounded box of a pill. Up to 2.7 margins around them (2.6: the whole of each side of the
 * controls for the flipper keys): a thumb near the pad or a pill pressed another control.
 */
int nd_hit(const NdLayout *L, float sx, float sy, uint8_t *dirs)
{
    float x = sx / L->scale, y = sy / L->scale;
    *dirs = 0;
    if (y < L->play_h) return -1;
    int px = (int)floorf(x), py = (int)floorf(y);
    if (L->btn[ND_MENU].w > 0 && in_pill(&L->btn[ND_MENU], px, py)) return ND_MENU;
    if (L->btn[ND_START].w > 0 && in_pill(&L->btn[ND_START], px, py)) return ND_START;
    if (L->btn[ND_LFLIP].w > 0 && in_key(&L->btn[ND_LFLIP], px, py)) return ND_LFLIP;
    if (L->btn[ND_RFLIP].w > 0 && in_key(&L->btn[ND_RFLIP], px, py)) return ND_RFLIP;
    int d = L->btn[ND_PAD].w > 0 ? in_pad(&L->btn[ND_PAD], px, py) : -1;
    if (d < 0) return -1;
    *dirs = (uint8_t)d;
    return ND_PAD;
}

uint8_t nd_key_buttons(int key, uint8_t dirs, bool field)
{
    switch (key) {
    case ND_LFLIP: return field ? ND_GB_LEFT : ND_GB_B;
    case ND_RFLIP: return ND_GB_A;
    case ND_START: return ND_GB_START;
    case ND_PAD: {
        uint8_t m = 0;
        if (field) {
            if (dirs & ND_DIR_LEFT) m |= ND_GB_DOWN;
            if (dirs & ND_DIR_RIGHT) m |= ND_GB_B;
            if (!dirs || (dirs & ND_DIR_UP)) m |= ND_GB_SELECT;    /* the up arm and TILT itself */
        } else {
            if (!dirs) m |= ND_GB_SELECT;                 /* the centre of the directional pad */
            if (dirs & ND_DIR_LEFT) m |= ND_GB_LEFT;
            if (dirs & ND_DIR_RIGHT) m |= ND_GB_RIGHT;
            if (dirs & ND_DIR_UP) m |= ND_GB_UP;
            if (dirs & ND_DIR_DOWN) m |= ND_GB_DOWN;
        }
        return m;
    }
    default: return 0;
    }
}

void nd_targets(uint8_t on, bool field, bool menu_open, float target[ND_NBTN], uint8_t *dirs)
{
    if (menu_open) on = 0;
    uint8_t d = 0;
    if (field) {
        if (on & ND_GB_DOWN) d |= ND_DIR_LEFT;
        if (on & ND_GB_B) d |= ND_DIR_RIGHT;
        if (on & ND_GB_SELECT) d |= ND_DIR_UP;
    } else {
        if (on & ND_GB_LEFT) d |= ND_DIR_LEFT;
        if (on & ND_GB_RIGHT) d |= ND_DIR_RIGHT;
        if (on & ND_GB_UP) d |= ND_DIR_UP;
        if (on & ND_GB_DOWN) d |= ND_DIR_DOWN;
    }
    *dirs = d;
    target[ND_LFLIP] = (field ? (on & ND_GB_LEFT) : (on & ND_GB_B)) ? 1.0f : 0.0f;
    target[ND_RFLIP] = (on & ND_GB_A) ? 1.0f : 0.0f;
    target[ND_PAD] = (d || (!field && (on & ND_GB_SELECT))) ? 1.0f : 0.0f;
    target[ND_START] = (on & ND_GB_START) ? 1.0f : 0.0f;
    target[ND_MENU] = menu_open ? 1.0f : 0.0f;
}

void nd_animate(float press[ND_NBTN], const float target[ND_NBTN])
{
    for (int i = 0; i < ND_NBTN; i++) {
        if (target[i] > press[i]) press[i] = target[i];
        else press[i] = fmaxf(target[i], press[i] - 0.34f);
    }
}

/* ------------------------------------------------------------------ under the tables */

/* The funnel of the drain under the status bar, centred between columns cx-1 and cx: white
 * from the status bar down, outlined in black, the lines of the table under the outline (bands,
 * from the outline down). The lines go up along the funnel to the status bar. */
static void funnel(Canvas *c, int cx, int y0, int hv, int depth, const uint32_t *bands, int nb, int x0, int x1)
{
    for (int x = x0; x < x1; x++) {
        int dxv = x < cx ? cx - x : x - cx + 1;
        int e = y0 - 1 + fdiv((hv - dxv) * depth, hv);      /* the outline */
        for (int y = y0; y < e; y++) put(c, x, y, C_WHITE);
        if (e >= y0) put(c, x, e, dxv <= hv ? C_BLACK : bands[0]);
        for (int k = 0; k < nb; k++) if (e + 1 + k >= y0) put(c, x, e + 1 + k, bands[k]);
        /* steep steps of the outline: no hole between the columns */
        int dn = (x < cx ? dxv - 1 : dxv + 1), en = y0 - 1 + fdiv((hv - dn) * depth, hv);
        if (dxv <= hv && en < e - 1)
            for (int y = en + 1; y < e; y++) put(c, x, y, C_BLACK);
    }
}

/* distance of a pixel to the left, right and bottom edges of the panel, its bottom corners
 * rounded as the screen's */
static int frame_dist(int x, int y, int x0, int x1, int yb, int r)
{
    int dx = 0, dy = 0;
    if (x < x0 + r) dx = x0 + r - x; else if (x > x1 - 1 - r) dx = x - (x1 - 1 - r);
    if (y > yb - 1 - r) dy = y - (yb - 1 - r);
    if (dx && dy) return r - (int)lroundf(sqrtf((float)(dx * dx + dy * dy)));
    int d = x - x0;
    if (x1 - 1 - x < d) d = x1 - 1 - x;
    if (yb - 1 - y < d) d = yb - 1 - y;
    return d;
}

/* the frame of the Red table goes on and closes under it: red, the yellow-green line (two
 * pixels, one from the edge), its rivets, the funnel of the drain */
static void panel_red(Canvas *c, const NdLayout *L)
{
    int x0 = L->gx, x1 = L->gx + ND_W, y0 = L->gy + L->gh, yb = L->vh;
    int r = L->corner > 3 ? L->corner : 3;
    uint32_t red = faded(c, C_RED), yel = faded(c, C_YELLOW), blk = faded(c, C_BLACK);
    for (int y = y0; y < c->h; y++)
        for (int x = x0; x < x1; x++) {
            uint32_t col = red;
            if (y < yb) {
                int d = frame_dist(x, y, x0, x1, yb, r);
                col = d < 0 ? blk : (d == 1 || d == 2) ? yel : red;
            }
            put_raw(c, x, y, col);
        }
    fill(c, x0 + 1, y0 + 2, ND_W - 2, 2, C_YELLOW);       /* the top line, under the status bar */
    static const uint32_t bands[RED_BANDS] = { C_RED, C_YELLOW, C_YELLOW };
    funnel(c, x0 + ND_W / 2, y0, RED_HV, RED_DEPTH, bands, RED_BANDS, x0 + 3, x1 - 3);
    static const uint32_t rpal[] = { C_RIVET, C_WHITE, C_YELLOW };
    int ty = y0 + 5;
    sprite(c, x0 + 4, ty, RIVET, 4, rpal, false);
    sprite(c, x1 - 8, ty, RIVET, 4, rpal, false);
    sprite(c, x0 + 58, ty, RIVET, 4, rpal, false);
    sprite(c, x1 - 62, ty, RIVET, 4, rpal, false);
    /* the bottom ones stay inside the line when the corners are round */
    int o = (int)ceilf(r - (r - 4) / 1.4142f);
    if (o < 4) o = 4;
    if (yb - o - 4 > ty + 8) {
        sprite(c, x0 + o, yb - o - 4, RIVET, 4, rpal, false);
        sprite(c, x1 - o - 4, yb - o - 4, RIVET, 4, rpal, false);
    }
}

/* the Blue table: blue, the funnel in the lines of its walls, the wall of the launch lane on the
 * right (as the table shows it at its original width), its screws */
static void panel_blue(Canvas *c, const NdLayout *L)
{
    int x0 = L->gx, x1 = L->gx + ND_W, y0 = L->gy + L->gh, yb = L->vh;
    fill(c, x0, y0, ND_W, c->h - y0, C_BLUE);
    /* the lane wall: black, blue, four light blue, blue; the lane widens at the bottom (its wall
     * turns left), the blue edge of the table goes on down to the bottom */
    int bend = yb - 28;
    for (int y = y0; y < c->h; y++) {
        int k = y >= bend ? (y - bend) / 4 + 1 : 0;
        int xk = x1 - 8 - k;
        put(c, xk, y, C_BLACK);
        put(c, xk + 1, y, C_BLUE);
        for (int x = xk + 2; x < x1; x++) put(c, x, y, x >= x1 - 2 ? C_BLUE : C_LBLUE);
    }
    static const uint32_t bands[BLUE_BANDS] = { C_BLUE, C_WHITE, C_WHITE, C_WHITE, C_BLUE, C_LBLUE, C_LBLUE };
    funnel(c, x0 + ND_W / 2, y0, BLUE_HV, BLUE_DEPTH, bands, BLUE_BANDS, x0 + 50, x1 - 50);
    static const uint32_t spal[] = { C_BLACK, C_WHITE, C_LBLUE };
    int sy = yb - 15;
    if (sy > y0 + 10) {
        sprite(c, x0 + 39, sy, SCREW, 13, spal, false);
        sprite(c, x1 - 39 - 13, sy, SCREW, 13, spal, true);
    }
}

/* ------------------------------------------------------------------ around the bonus stages */

/*
 * A stage goes on above and below with its own tiles. Its background pattern repeats every
 * pat_n rows of its map (from row pat0: in phase with the stage, upwards as well), and every two
 * columns: it is taken from the columns 0-1 on the left half and 18-19 on the right one (the
 * right half of some stages is the mirror image of the left). Below the stage, its drain lane
 * goes on: the rows lane0 .. lane0 + lane_n - 1 of its map in turn, but only across the columns
 * where they differ from the pattern (the walls and the floor of the lane): the tiles of the walls
 * also show a part of the pattern, in the phase of their own row, which must not be repeated.
 * Gengar's grass keeps its grass tiles only (no walls, no lane).
 */
typedef struct {
    uint8_t stage;
    int8_t pat0, pat_n;              /* the rows of the pattern */
    int8_t lane0, lane_n;            /* the rows of the drain lane (lane_n 0: none) */
    bool grass;
} StageExt;

static const StageExt STAGES[] = {
    { 13, 16, 2, 16, 2, false },     /* Diglett */
    { 9, 14, 4, 16, 2, false },      /* Mewtwo */
    { 11, 12, 4, 16, 2, false },     /* Meowth */
    { 15, 12, 6, 15, 3, false },     /* Seel */
    { 7, 14, 4, 0, 0, true },        /* Gengar */
};

static const StageExt *stage_ext(int stage)
{
    for (size_t i = 0; i < sizeof STAGES / sizeof STAGES[0]; i++) if (STAGES[i].stage == stage) return &STAGES[i];
    return NULL;
}

int nd_scene(const Pinball *pb, int gh)
{
    const PbView *v = pb ? pb_view(pb) : NULL;          /* what the game showed with its picture */
    if (!v || v->screen != SCREEN_PINBALL_GAME) return ND_SCENE_SCREEN;
    int stage = v->stage;
    if (gh == PB_FIELD_H) return (stage == 0 || stage == 1) ? ND_SCENE_RED : (stage == 4 || stage == 5) ? ND_SCENE_BLUE : ND_SCENE_SCREEN;
    if ((gh == 144 || gh == PB_STAGE_H) && stage_ext(stage) && v->lcd_on) return ND_SCENE_STAGE;
    return ND_SCENE_SCREEN;
}

static uint32_t rgb555(const uint8_t *pal, int idx)
{
    uint16_t v = (uint16_t)(pal[idx * 2] | (pal[idx * 2 + 1] << 8));
    int r = v & 31, g = (v >> 5) & 31, b = (v >> 10) & 31;
    return ((uint32_t)((r * 255 + 15) / 31) << 16) | ((uint32_t)((g * 255 + 15) / 31) << 8) | (uint32_t)((b * 255 + 15) / 31);
}

/* pal: the background palettes the picture was drawn with (gbc_frame_bgpal) */
typedef struct { const GBCPage *pg; uint16_t map; bool udata; const StageExt *e; const uint8_t *pal; } StageMap;

static int fmod_pos(int a, int n) { int m = a % n; return m < 0 ? m + n : m; }

static uint32_t tile_px(const StageMap *m, uint8_t t, uint8_t a, int px, int py)
{
    int r = (a & 0x40) ? 7 - py : py;
    int taddr = m->udata ? t * 16 : 0x1000 + (int8_t)t * 16;
    const uint8_t *td = &m->pg->vram[(a >> 3) & 1][taddr + r * 2];
    int bit = (a & 0x20) ? px : 7 - px;
    int ci = ((td[0] >> bit) & 1) | (((td[1] >> bit) & 1) << 1);
    return rgb555(m->pal, (a & 7) * 4 + ci);
}

/* a pixel of the map: tile (row, col), pixel (px, py) of it */
static uint32_t map_px(const StageMap *m, int row, int col, int px, int py)
{
    row &= 31;
    col &= 31;
    return tile_px(m, m->pg->vram[0][m->map + row * 32 + col], m->pg->vram[1][m->map + row * 32 + col], px, py);
}

/* Gengar's grass: its plain tile (217), and here and there its tile with a tuft (218), as in the
 * stage (about one tile in six), never two side by side or one above the other; the same tiles
 * at the same places from one frame to the next */
static bool tuft_at(int row, int col)
{
    uint32_t h = (uint32_t)(row + 64) * 73856093u ^ (uint32_t)(col + 64) * 19349663u;
    h ^= h >> 13;
    h *= 0x5BD1E995u;
    h ^= h >> 15;
    return h % 100 < 24;
}

static uint32_t grass_px(const StageMap *m, int row, int col, int px, int py)
{
    bool tuft = tuft_at(row, col) && !tuft_at(row, col - 1) && !tuft_at(row - 1, col);
    return tile_px(m, tuft ? 218 : 217, m->pg->vram[1][m->map + 17 * 32], px, py);
}

/* the pattern at canvas column x (0..159) in map row row */
static uint32_t pattern_px(const StageMap *m, int x, int vx, int row, int py)
{
    int col = (vx >> 3) & 1;
    return map_px(m, row, x < ND_W / 2 ? col : 18 + col, vx & 7, py);
}

static bool ext_stage(Canvas *c, const NdLayout *L, const Pinball *pb, int stage)
{
    const StageExt *e = stage_ext(stage);
    if (!e) return false;
    const GBCState *s = &pb->g.s;
    uint8_t lcdc = s->io[0x40];
    if (!(lcdc & 0x80)) return false;                       /* screen off: its colour */
    StageMap m = { &s->page[PB_PAGE_MAIN], (uint16_t)((lcdc & 0x08) ? 0x1C00 : 0x1800), (lcdc & 0x10) != 0, e,
                   gbc_frame_bgpal(&pb->g, PB_PAGE_MAIN) };
    int scx = s->io[0x43], scy = s->io[0x42];

    /* the columns of the lane: where its rows differ from the pattern */
    int band_l = ND_W, band_r = -1;
    for (int k = 0; k < e->lane_n; k++)
        for (int py = 0; py < 8; py++)
            for (int x = 0; x < ND_W; x++) {
                int vx = (x + scx) & 255;
                if (map_px(&m, e->lane0 + k, vx >> 3, vx & 7, py) != pattern_px(&m, x, vx, e->lane0 + k, py)) {
                    if (x < band_l) band_l = x;
                    if (x > band_r) band_r = x;
                }
            }

    int yb = L->gy + L->gh;
    for (int y = 0; y < c->h; y++) {
        if (y == L->gy) { y = yb - 1; continue; }           /* the game itself */
        int vy = y - L->gy + scy, row = vy >> 3, py = vy & 7;
        if (vy < 0) { row = -((-vy + 7) >> 3); py = vy - row * 8; }
        int prow = e->pat0 + fmod_pos(row - e->pat0, e->pat_n);
        int lrow = e->lane_n ? e->lane0 + fmod_pos(row - e->lane0, e->lane_n) : 0;
        bool lane = e->lane_n && y >= yb;
        for (int x = 0; x < ND_W; x++) {
            int vx = (x + scx) & 255;
            uint32_t col = e->grass ? grass_px(&m, row, vx >> 3, vx & 7, py)
                         : lane && x >= band_l && x <= band_r ? map_px(&m, lrow, vx >> 3, vx & 7, py)
                                                               : pattern_px(&m, x, vx, prow, py);
            put_raw(c, L->gx + x, y, col);
        }
    }
    return true;
}

/*
 * Diglett: the striped band of the top of the stage goes up around the dome of its big Diglett,
 * cut by the top of the screen. Its outline is a circle (radius 16, centre on column 80 between
 * pixels, row 7.83 of the stage: it fits the outline the stage shows on its rows 0-6); above the
 * stage the arch closes on that circle: the stripes of the stage's row 0 inside, its black
 * outline, a white rim outside as the band's top edge. Drawn over the pattern, in the stage's own
 * colours (read on its picture: they fade with it).
 */
static bool in_arch(int x, int r) { float dx = x + 0.5f - 80.0f, dy = r - 7.83f; return dx * dx + dy * dy <= 256.0f; }

static void diglett_arch(Canvas *c, const NdLayout *L, const uint32_t *game, int stride)
{
    if (!game) return;
    uint32_t k = game[66] & 0xFFFFFFu, w = game[64] & 0xFFFFFFu;
    /* the arch as the stage shows it: its outline at columns 66 and 93 of row 0, white beside */
    if (k != (game[93] & 0xFFFFFFu) || k == w || (game[65] & 0xFFFFFFu) == k || (game[stride * 4 + 64] & 0xFFFFFFu) != k) return;
    for (int r = -1; r >= -10; r--) {
        int y = L->gy + r;
        if (y < 0) break;
        for (int x = 56; x < 104; x++) {
            uint32_t col;
            if (in_arch(x, r)) {
                bool edge = !in_arch(x - 1, r) || !in_arch(x + 1, r) || !in_arch(x, r - 1) || !in_arch(x, r + 1);
                col = edge ? k : game[x] & 0xFFFFFFu;               /* the stripes of row 0 */
            } else if (in_arch(x - 1, r) || in_arch(x + 1, r) || in_arch(x, r + 1) || in_arch(x, r - 1)) {
                col = w;                                            /* the rim */
            } else {
                continue;
            }
            put_raw(c, L->gx + x, y, col);
        }
    }
}

/*
 * The Pokedex: its list sits in a box with a bevel (dark top and left, light bottom and right)
 * inside a frame, which the bottom of the screen cuts (its last row is still the list). Below the
 * game, the box and the frame close as their top and sides show: the light bottom of the box (two rows, mitred with its dark
 * left side), a row of red, the light bottom line of the frame, then red down to the bottom; the
 * light and dark edges of the screen (columns 0 and 159) go on above and below. Only when the
 * picture is that list (its columns checked on row 140); colours read on the picture.
 */
static bool dex_list(const uint32_t *g, int stride)
{
    const uint32_t *row = g + 140 * stride;
    uint32_t p = row[0] & 0xFFFFFFu, rd = row[2] & 0xFFFFFFu, k = row[6] & 0xFFFFFFu;
    #define PX(x) (row[x] & 0xFFFFFFu)
    bool ok = p != rd && k != rd && k != p && PX(7) == rd && PX(8) == k && PX(9) == k && PX(134) == p && PX(135) == p &&
              PX(136) == rd && PX(137) == p && PX(159) == k && PX(12) != k && (g[143 * stride + 9] & 0xFFFFFFu) == k;
    #undef PX
    return ok;
}

static void dex_frame(Canvas *c, const NdLayout *L, const uint32_t *g, int stride)
{
    const uint32_t *t = g + 143 * stride;                      /* the last row of the list: the template */
    uint32_t p = t[0] & 0xFFFFFFu, rd = t[2] & 0xFFFFFFu, k = t[6] & 0xFFFFFFu;
    for (int y = 0; y < c->h; y++) {
        int r = y - L->gy;                                     /* row of the game */
        if (r >= 0 && r < 144) continue;
        for (int x = 0; x < ND_W; x++) {
            uint32_t col = x == 0 ? p : x == ND_W - 1 ? k : rd;
            int b = r - 144;
            if (b >= 0 && b <= 3) {
                col = t[x] & 0xFFFFFFu;
                if (b <= 1 && x >= 8 && x <= 135) col = x == 8 || (b == 0 && x == 9) ? k : p;   /* the box */
                else if (b == 2 && x >= 8 && x <= 135) col = rd;
                else if (b == 3 && x >= 7 && x <= 137) col = p;                                   /* the frame */
            }
            put_raw(c, L->gx + x, y, col);
        }
    }
}

/* ------------------------------------------------------------------ under the other screens */

/* their background colour, read on the game's picture (so it fades with it): near the top above
 * them (the third row: the top one of the Pokedex is a light line), the bottom row below; the white over the black band of the options (above as well: their
 * black title bar stays a bar), the red frame of the Pokedex. The high scores
 * move their bars out of the screen when they change table (the bottom row turns white, back
 * and forth): their dark grey is read in their palette instead (BG palette 0, colour 3), which
 * stays the same during the change and fades with the screen. */
static uint32_t screen_colour(const Pinball *pb, const uint32_t *game, int stride, int gw, int gh, bool top)
{
    if (!game || gw <= 0 || gh <= 0) return C_BLACK;
    int y = top ? 2 : gh - 1, xs[5] = { gw / 20, gw / 4, gw / 2, gw * 3 / 4, gw - 1 - gw / 20 }, n = 5;
    int scr = pb ? pb_view(pb)->screen : -1;
    if (scr == 7 && pb_view(pb)->lcd_on) return rgb555(gbc_frame_bgpal(&pb->g, PB_PAGE_MAIN), 3);
    if (scr == 6 && gh > 132) y = 130;                      /* options: the white, above and below */
    if (scr == 5) { xs[0] = 2; xs[1] = 3; xs[2] = 4; n = 3; }   /* Pokedex */
    uint32_t v[5];
    for (int i = 0; i < n; i++) v[i] = game[y * stride + xs[i]] & 0xFFFFFFu;
    /* the most frequent one (a cursor or a sprite over one of the points does not count) */
    int best = 0, bn = 0;
    for (int i = 0; i < n; i++) {
        int k = 0;
        for (int j = 0; j < n; j++) k += v[j] == v[i];
        if (k > bn) { bn = k; best = i; }
    }
    return v[best];
}

/* ------------------------------------------------------------------ the controls */

static void draw_pill(Canvas *c, const NdRect *r, float press, const char *label)
{
    int sink = press > 0.5f ? 1 : 0;
    int x = r->x, y = r->y, w = r->w, h = r->h;
    round_box(c, x, y + 1, w, h, 3, C_BLACK);                        /* the hole / shadow */
    round_box(c, x, y + sink, w, h, 3, C_BLACK);                     /* outline */
    round_box(c, x + 1, y + 1 + sink, w - 2, h - 2, 2, sink ? C_SHADE : C_WHITE);
    if (!sink) fill(c, x + 3, y + h - 2, w - 6, 1, C_SHADE);           /* lower edge */
    small_text(c, x + w / 2 - small_w(label) / 2, y + 1 + sink, label, C_INK);
}

/* the pad: the lane guides of the table (or the lavender of the menus), lit from the top left */
static void draw_pad(Canvas *c, const NdRect *r, const KeySet *k, uint8_t dirs, bool tilt, bool centre)
{
    int n = r->w, a = n / 3 + ((n / 3) % 2 == 0 ? 1 : 0);      /* arm width, odd: centred */
    int cx = r->x + n / 2, cy = r->y + n / 2, half = n / 2, ha = a / 2;
    /* the cross: shadow, outline, face, then the pressed arms */
    for (int pass = 0; pass < 3; pass++)
        for (int y = -half; y < half; y++)
            for (int x = -half; x < half; x++) {
                int X = x < 0 ? -x - 1 : x, Y = y < 0 ? -y - 1 : y;          /* symmetric about the centre */
                bool in = (X <= ha && Y < half) || (Y <= ha && X < half);
                if (!in) continue;
                bool edge = X == half - 1 || Y == half - 1 || (X == ha && Y > ha) || (Y == ha && X > ha);
                if (pass == 0) { put(c, cx + x, cy + y + 1, C_BLACK); continue; }
                if (pass == 1) { put(c, cx + x, cy + y, C_BLACK); continue; }
                if (edge) continue;
                int dir = 0;
                if (Y <= ha && X > ha) dir = x < 0 ? ND_DIR_LEFT : ND_DIR_RIGHT;
                if (X <= ha && Y > ha) dir = y < 0 ? ND_DIR_UP : ND_DIR_DOWN;
                bool lit = dir ? (dirs & dir) != 0 : (centre && dirs == 0xFF);
                uint32_t col = lit ? k->pad_lit : k->pad;
                bool top = (Y == half - 2 && y < 0 && X < ha) || (Y == ha - 1 && y < 0 && X > ha && X < half - 1);
                bool left = (X == half - 2 && x < 0 && Y < ha) || (X == ha - 1 && x < 0 && Y > ha && Y < half - 1);
                bool bot = (Y == half - 2 && y >= 0 && X < ha) || (Y == ha - 1 && y >= 0 && X > ha && X < half - 1);
                bool right = (X == half - 2 && x >= 0 && Y < ha) || (X == ha - 1 && x >= 0 && Y > ha && Y < half - 1);
                if (!lit && (top || left)) col = C_WHITE;
                else if (!lit && (bot || right)) col = k->pad_dark;
                put(c, cx + x, cy + y, col);
            }
    /* arrows near the ends of the arms */
    int al = ha - 1 > 1 ? ha - 1 : 1, off = half - 3 - al;
    for (int d = 0; d < 4; d++) {
        int bit = d == 0 ? ND_DIR_LEFT : d == 1 ? ND_DIR_RIGHT : d == 2 ? ND_DIR_UP : ND_DIR_DOWN;
        uint32_t col = (dirs & bit) ? C_WHITE : k->pad_dark;
        for (int q = 0; q <= al; q++)
            for (int j = -q; j < q; j++) {
                int px = 0, py = 0;
                switch (d) {
                case 0: px = -off - al + q - 1; py = j; break;
                case 1: px = off + al - q; py = j; break;
                case 2: px = j; py = -off - al + q - 1; break;
                default: px = j; py = off + al - q; break;
                }
                put(c, cx + px, cy + py, col);
            }
    }
    if (tilt) {
        /* TILT in the big letters, outlined in the dark of the guides */
        int tw = 6 * 4 + 2 * 3;
        if (a >= 13 && tw + 4 <= n) {
            int tx = cx - tw / 2, ty = cy - 5;
            bitmap(c, tx, ty, BIG_T, 9, C_WHITE, k->pad_dark, true);
            bitmap(c, tx + 8, ty, BIG_I, 9, C_WHITE, k->pad_dark, true);
            bitmap(c, tx + 16, ty, BIG_L, 9, C_WHITE, k->pad_dark, true);
            bitmap(c, tx + 24, ty, BIG_T, 9, C_WHITE, k->pad_dark, true);
        } else if (text_w("TILT") + 2 <= n) {
            text_outlined(c, cx - text_w("TILT") / 2, cy - FONT_H / 2 - 1, "TILT", C_WHITE, k->pad_dark);
        }
    }
}

/* a flipper key: an octagon (black, the rim, black, the inside); the game's flipper in it, or
 * the letter of the button on the white keys of the menus. mirror: the right one */
static void draw_key(Canvas *c, const NdRect *r, const KeySet *k, bool mirror, float up, const char *const *letter)
{
    int n = r->w, cut = n / 4;
    int sink = up > 0.5f ? 1 : 0;
    for (int y = 0; y < n; y++)
        for (int x = 0; x < n; x++) {
            int dx = x < n - 1 - x ? x : n - 1 - x, dy = y < n - 1 - y ? y : n - 1 - y;
            int d = dx + dy - cut;                       /* < 0: the cut corners */
            int e = dx < dy ? dx : dy;
            if (d < 0) continue;
            int rim = e < d ? e : d;
            uint32_t col;
            if (rim == 0) col = C_BLACK;
            else if (rim <= 2) col = k->ring;
            else if (rim == 3) col = (up > 0.5f && !k->letters) ? C_WHITE : C_BLACK;
            else col = (k->letters && sink) ? (k->well == C_WHITE ? C_SHADE : k->ring) : k->well;
            put(c, r->x + x, r->y + y, col);
        }
    if (k->letters) {
        /* black on the white keys of the menus, white outlined on the keys of a table */
        bool white = k->well == C_WHITE;
        if (letter) bitmap(c, r->x + (n - 7) / 2, r->y + (n - 10) / 2 + sink, letter, 10, white ? C_BLACK : C_WHITE, C_BLACK, !white);
        return;
    }
    /* the flipper: a tapered bar from the pivot, rotating about it */
    float len = n * 0.56f, r1 = n * 0.15f, r2 = n * 0.075f;
    float rest = 0.42f, raised = -0.42f, ang = rest + (raised - rest) * up;
    float px = n * 0.27f, py = n * 0.45f + sink;
    float dx = cosf(ang), dy = sinf(ang);
    uint8_t m[64][64];
    int nn = n < 64 ? n : 64;
    memset(m, 0, sizeof m);
    for (int y = 0; y < nn; y++)
        for (int x = 0; x < nn; x++) {
            float qx = x + 0.5f - px, qy = y + 0.5f - py;
            float tt = (qx * dx + qy * dy) / len;
            if (tt < 0) tt = 0;
            if (tt > 1) tt = 1;
            float ex = qx - dx * len * tt, ey = qy - dy * len * tt;
            float rr = r1 + (r2 - r1) * tt;
            if (sqrtf(ex * ex + ey * ey) <= rr) m[y][x] = (ex * -dy + ey * dx) > rr * 0.30f ? 2 : 1;   /* 2: the lower side */
        }
    for (int y = 0; y < nn; y++)
        for (int x = 0; x < nn; x++) {
            if (!m[y][x]) continue;
            bool edge = x == 0 || y == 0 || x == nn - 1 || y == nn - 1 || !m[y - 1][x] || !m[y + 1][x] || !m[y][x - 1] || !m[y][x + 1];
            uint32_t col = edge ? C_BLACK : m[y][x] == 2 ? C_SHADE : C_WHITE;
            put(c, mirror ? r->x + n - 1 - x : r->x + x, r->y + y, col);
        }
    /* the pivot: the "+" of the game's flippers */
    int ppx = (int)px, ppy = (int)py;
    int X = mirror ? r->x + n - 1 - ppx : r->x + ppx;
    put(c, X, r->y + ppy, C_BLACK);
    put(c, X - 1, r->y + ppy, C_BLACK); put(c, X + 1, r->y + ppy, C_BLACK);
    put(c, X, r->y + ppy - 1, C_BLACK); put(c, X, r->y + ppy + 1, C_BLACK);
}

/* ------------------------------------------------------------------ menu, messages */

#define MENU_ROW 11
#define MENU_HEAD 13

/* cuts the next line of at most maxc letters off *s, at a space when possible, at a new line always */
static int next_line(const char **s, char *line, int size, int maxc)
{
    while (**s == ' ' || **s == '\n') (*s)++;
    const char *p = *s;
    int n = 0, cut = -1;
    while (*p && *p != '\n' && n < maxc) { if (*p == ' ') cut = (int)(p - *s); utf8_next(&p); n++; }
    int len = (int)(p - *s);
    if (*p && *p != ' ' && *p != '\n' && cut > 0) len = cut;
    if (len > size - 1) len = size - 1;
    memcpy(line, *s, (size_t)len);
    line[len] = 0;
    *s += len;
    return len;
}

/* lines of a text cut to the width of the menu */
static int text_lines(const char *s, int maxc)
{
    char line[96];
    int n = 0;
    while (s && *s && n < 12 && next_line(&s, line, sizeof line, maxc)) n++;
    return n;
}

static int menu_width(const NdLayout *L, const NdState *st)
{
    int w = L->gw - 8;
    int maxl = 0;
    for (int i = 0; i < st->menu_n; i++) { int tw = text_w(st->menu_label[i]); if (tw > maxl) maxl = tw; }
    if (maxl + 24 > w) w = maxl + 24;
    if (w > L->cw - 4) w = L->cw - 4;
    return w;
}

static NdRect menu_box(const NdLayout *L, const NdState *st)
{
    int w = menu_width(L, st), maxc = (w - 6) / FONT_CELL_W;
    int h = MENU_HEAD + 4 + st->menu_n * MENU_ROW + 3;
    if (st->menu_hint) h += text_lines(st->menu_hint, maxc) * FONT_CELL_H + 3;
    if (st->menu_credits) h += text_lines(st->menu_credits, maxc) * FONT_CELL_H + 3;
    if (st->menu_rights) h += text_lines(st->menu_rights, maxc) * FONT_CELL_H + 3;
    if (st->menu_info) h += text_lines(st->menu_info, maxc) * FONT_CELL_H + 3;
    NdRect r = { L->gx + L->gw / 2 - w / 2, L->gy + L->gh / 2 - h / 2, w, h };
    if (r.y + h > L->vh - 3) r.y = L->vh - 3 - h;
    if (r.x < 2) r.x = 2;
    if (r.y < 2) r.y = 2;
    return r;
}

int nd_menu_hit(const NdLayout *L, const NdState *st, float sx, float sy, bool *inside)
{
    float x = sx / L->scale, y = sy / L->scale;
    NdRect b = menu_box(L, st);
    *inside = x >= b.x && x < b.x + b.w && y >= b.y && y < b.y + b.h;
    for (int i = 0; i < st->menu_n; i++) {
        int ry = b.y + MENU_HEAD + 3 + i * MENU_ROW;
        if (x >= b.x && x < b.x + b.w && y >= ry - 1 && y < ry + MENU_ROW - 1) return i;
    }
    return -1;
}

static void draw_menu(Canvas *c, const NdLayout *L, const NdState *st)
{
    /* the scene behind, darkened */
    for (int i = 0; i < c->w * c->h; i++) c->p[i] = mix(c->p[i], C_BLACK, 13, 20);
    NdRect b = menu_box(L, st);
    round_box(c, b.x - 1, b.y - 1, b.w + 2, b.h + 3, 4, C_BLACK);          /* outline and shadow */
    round_box(c, b.x, b.y, b.w, b.h, 3, C_WHITE);
    /* the title bar, as the header of the game's menus */
    round_box(c, b.x + 1, b.y + 1, b.w - 2, MENU_HEAD, 2, C_BLACK);
    const char *title = st->menu_title ? st->menu_title : "PINBALL TC";
    text(c, b.x + b.w / 2 - text_w(title) / 2, b.y + 4, title, C_WHITE);
    pokeball(c, b.x + 4, b.y + 4);
    pokeball(c, b.x + b.w - 11, b.y + 4);
    for (int i = 0; i < st->menu_n; i++) {
        int ry = b.y + MENU_HEAD + 3 + i * MENU_ROW;
        if (i == st->menu_hot) {
            fill(c, b.x + 2, ry - 1, b.w - 4, MENU_ROW - 1, 0xE6E6F5u);
            pokeball(c, b.x + 4, ry + 1);
        }
        text_outlined(c, b.x + 15, ry + 1, st->menu_label[i], C_WHITE, C_BLACK);
    }
    /* the hint, then the author (each under a line), the rights, what the platform measured (under a
     * line); cut at the spaces */
    int hy = b.y + MENU_HEAD + 4 + st->menu_n * MENU_ROW + 2;
    const char *parts[4] = { st->menu_hint, st->menu_credits, st->menu_rights, st->menu_info };
    for (int k = 0; k < 4; k++) {
        const char *s = parts[k];
        if (!s) continue;
        if (k != 2) fill(c, b.x + 3, hy - 2, b.w - 6, 1, C_SHADE);
        char line[96];
        while (*s && next_line(&s, line, sizeof line, (b.w - 6) / FONT_CELL_W)) {
            text(c, b.x + b.w / 2 - text_w(line) / 2, hy, line, C_HINT);
            hy += FONT_CELL_H;
        }
        hy += 3;
    }
}

static void draw_toast(Canvas *c, const NdLayout *L, const char *msg)
{
    char lines[2][64];
    int maxc = (L->gw - 6) / FONT_CELL_W, n = 0;
    const char *s = msg;
    while (n < 2 && *s && next_line(&s, lines[n], sizeof lines[n], maxc)) n++;
    if (!n) return;
    int h = n * FONT_CELL_H + 3, y = L->gy + L->gh - (L->gh > 200 ? 10 : 0) - h - 6;
    fill(c, L->gx, y - 1, L->gw, h + 2, C_WHITE);
    fill(c, L->gx, y, L->gw, h, C_BLACK);
    for (int i = 0; i < n; i++) text(c, L->gx + L->gw / 2 - text_w(lines[i]) / 2, y + 2 + i * FONT_CELL_H, lines[i], C_WHITE);
}

/* ------------------------------------------------------------------ the picture */

/*
 * The fades of the game: its palettes go to white (every channel raised by the same amount)
 * and, on the copyright screens, to black. Measured on its picture: an image always has black
 * outlines and white or saturated colours, so its darkest channel tells how far it went to
 * white, its brightest one how far to black. 0..256.
 */
static void game_fade(const uint32_t *game, int stride, int w, int h, int *to_white, int *to_black)
{
    if (h == PB_FIELD_H || h == PB_STAGE_H) h -= PB_HUD_ROWS;   /* the status bar keeps its black */
    /* the darkest and brightest channel of the picture: the extremes of each channel (simple
     * reductions, made vector instructions by the compiler), then of the three */
    uint32_t mn[3] = { 255, 255, 255 }, mx[3] = { 0, 0, 0 };
    for (int y = 0; y < h; y++) {
        const uint32_t *row = game + (size_t)y * stride;
        uint32_t r0 = 255, g0 = 255, b0 = 255, r1 = 0, g1 = 0, b1 = 0;
        for (int x = 0; x < w; x++) {
            uint32_t p = row[x], r = (p >> 16) & 255, g = (p >> 8) & 255, b = p & 255;
            r0 = r < r0 ? r : r0; g0 = g < g0 ? g : g0; b0 = b < b0 ? b : b0;
            r1 = r > r1 ? r : r1; g1 = g > g1 ? g : g1; b1 = b > b1 ? b : b1;
        }
        if (r0 < mn[0]) mn[0] = r0;
        if (g0 < mn[1]) mn[1] = g0;
        if (b0 < mn[2]) mn[2] = b0;
        if (r1 > mx[0]) mx[0] = r1;
        if (g1 > mx[1]) mx[1] = g1;
        if (b1 > mx[2]) mx[2] = b1;
    }
    int lo = (int)(mn[0] < mn[1] ? (mn[0] < mn[2] ? mn[0] : mn[2]) : (mn[1] < mn[2] ? mn[1] : mn[2]));
    int hi = (int)(mx[0] > mx[1] ? (mx[0] > mx[2] ? mx[0] : mx[2]) : (mx[1] > mx[2] ? mx[1] : mx[2]));
    /* below one step of the fade (1/31 of the range), nothing */
    *to_white = lo <= 8 ? 0 : (lo - 8) * 256 / (255 - 8);
    *to_black = hi >= 247 ? 0 : (247 - hi) * 256 / 247;
}

void nd_render_game(const NdLayout *L, const Pinball *pb, const uint32_t *game, int game_stride, uint32_t *bg, int fade[2])
{
    Canvas c = { bg, L->cw, L->ch, 0, 0 };
    font_init();
    for (int i = 0; i < c.w * c.h; i++) bg[i] = C_BLACK;
    if (game) game_fade(game, game_stride, L->gw, L->gh, &c.to_white, &c.to_black);
    fade[0] = c.to_white;
    fade[1] = c.to_black;

    /* what continues the game around it */
    const PbView *v = pb ? pb_view(pb) : NULL;
    int y0 = L->gy + L->gh;
    if (L->scene == ND_SCENE_RED) panel_red(&c, L);
    else if (L->scene == ND_SCENE_BLUE) panel_blue(&c, L);
    else if (L->scene == ND_SCENE_STAGE && v && ext_stage(&c, L, pb, v->stage)) {
        if (v->stage == 13) diglett_arch(&c, L, game, game_stride);
    } else if (game && v && v->screen == 5 && L->gh == 144 && dex_list(game, game_stride)) {
        dex_frame(&c, L, game, game_stride);
    } else {
        uint32_t below = screen_colour(pb, game, game_stride, L->gw, L->gh, false);
        uint32_t above = screen_colour(pb, game, game_stride, L->gw, L->gh, true);
        for (int y = 0; y < c.h; y++) {
            if (y == L->gy) { y = y0 - 1; continue; }
            for (int x = L->gx; x < L->gx + L->gw; x++) put_raw(&c, x, y, y < L->gy ? above : below);
        }
    }

    /* the game itself: its rows clipped to the canvas */
    int x0 = L->gx < 0 ? 0 : L->gx, x1 = L->gx + L->gw > c.w ? c.w : L->gx + L->gw;
    if (game)
        for (int y = 0; y < L->gh && x1 > x0; y++) {
            int Y = L->gy + y;
            if (Y < 0 || Y >= c.h) continue;
            const uint32_t *src = game + (size_t)y * game_stride + (x0 - L->gx);
            uint32_t *dst = bg + (size_t)Y * c.w + x0;
            for (int x = 0; x < x1 - x0; x++) dst[x] = src[x] & 0xFFFFFFu;
        }
}

void nd_render_controls(const NdLayout *L, const NdState *st, const uint32_t *bg, const int fade[2], uint32_t *out)
{
    Canvas c = { out, L->cw, L->ch, fade[0], fade[1] };
    font_init();
    memcpy(out, bg, (size_t)c.w * c.h * sizeof *out);

    /* the controls */
    int set = st->set >= 0 && st->set <= ND_SET_GREY ? st->set : ND_SET_GREY;
    KeySet keys = SETS[set];
    if (st->letters) keys.letters = true;              /* the colours stay those of the table */
    const KeySet *k = &keys;
    bool field = !k->letters;
    draw_pill(&c, &L->btn[ND_MENU], st->press[ND_MENU], "MENU");
    draw_pill(&c, &L->btn[ND_START], st->press[ND_START], "START");
    uint8_t dirs = st->pad_dirs;
    if (!field && !dirs && st->press[ND_PAD] > 0.5f) dirs = 0xFF;  /* SELECT: the centre */
    draw_pad(&c, &L->btn[ND_PAD], k, dirs == 0xFF ? 0 : dirs, field, dirs == 0xFF);
    draw_key(&c, &L->btn[ND_LFLIP], k, false, st->press[ND_LFLIP], BIG_B);
    draw_key(&c, &L->btn[ND_RFLIP], k, true, st->press[ND_RFLIP], BIG_A);

    /* the game itself, over the controls */
    int x0 = L->gx < 0 ? 0 : L->gx, x1 = L->gx + L->gw > c.w ? c.w : L->gx + L->gw;
    for (int y = L->gy < 0 ? 0 : L->gy; y < L->gy + L->gh && y < c.h && x1 > x0; y++)
        memcpy(&out[y * c.w + x0], &bg[y * c.w + x0], (size_t)(x1 - x0) * sizeof *out);

    c.to_white = c.to_black = 0;
    if (st->toast && st->toast[0] && !st->menu_open) draw_toast(&c, L, st->toast);
    if (st->menu_open && (st->menu_n > 0 || st->menu_hint)) draw_menu(&c, L, st);     /* the entries, or the page ABOUT */
}

void nd_icon(uint32_t *out, int n)
{
    if (n < 8) n = 8;
    if (n > 64) n = 64;
    /* drawn over a value no colour has, which becomes the transparent outside of the octagon */
    const uint32_t none = 0xFF000000u;
    for (int i = 0; i < n * n; i++) out[i] = none;
    Canvas c = { out, n, n, 0, 0 };
    NdRect r = { 0, 0, n, n };
    draw_key(&c, &r, &SETS[ND_SET_BLUE], true, 0, NULL);
    for (int i = 0; i < n * n; i++) out[i] = out[i] == none ? 0 : (out[i] | 0xFF000000u);
}
