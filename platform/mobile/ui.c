/*
 * ui.c - touch interface of the mobile version (platform independent).
 *
 * One display: the whole screen is one picture drawn in the pixels of the game, the game as
 * wide as the screen at the top, what it shows continued below it and the keys over that
 * (platform/mobile/design.c). During a game, the left and right halves of the game image are
 * also the left and right flippers, which is the natural way to play pinball on a touch screen.
 */
#include "ui.h"
#include "../../src/front/font5x7.h"
#include "../../src/game/pinball.h"
#include <math.h>
#include <stdio.h>
#include <string.h>

#define COL_BG        0xFF0E1115u
#define COL_TEXT      0xFFEDEDEDu
#define COL_DIM       0xFF98A1ACu
#define COL_ACCENT    0xFFF2C14Eu

#define NMENU UI_MENU_ITEMS

/* ------------------------------------------------------------------ display list */

static float text_w(const char *s, float px) { int n = utf8_len(s); return n > 0 ? (n * FONT_CELL_W - 1) * px : 0; }

/* one line of text, top-left at (x, y) */
static void push_text(UiList *l, float x, float y, float px, uint32_t c, const char *s)
{
    size_t len = strlen(s);
    if (l->n >= UI_MAX_ITEMS || l->text_n + (int)len + 1 > UI_TEXT_ARENA) return;
    UiItem *it = &l->item[l->n++];
    memset(it, 0, sizeof *it);
    it->kind = UI_TEXT;
    it->x = x; it->y = y;
    it->w = text_w(s, px);
    it->h = FONT_H * px;
    it->color = c;
    it->px = px;
    it->text = l->text_n;
    memcpy(l->text + l->text_n, s, len + 1);
    l->text_n += (int)len + 1;
}

static void push_text_c(UiList *l, float cx, float cy, float px, uint32_t c, const char *s)
{
    push_text(l, floorf(cx - text_w(s, px) / 2 + 0.5f), floorf(cy - FONT_H * px / 2 + 0.5f), px, c, s);
}

/* word-wrapped paragraph, centred; returns the height used (l == NULL: measure only) */
static float push_para(UiList *l, float cx, float y, float maxw, float px, uint32_t c, const char *s)
{
    int maxc = (int)(maxw / (FONT_CELL_W * px));
    if (maxc < 8) maxc = 8;
    char line[256];
    float y0 = y;
    const char *p = s;
    while (*p) {
        /* take words while they fit */
        const char *best = NULL, *q = p;
        int cols = 0;
        while (*q && *q != '\n') {
            const char *w = q;
            int wc = 0;
            while (*w && *w != ' ' && *w != '\n') { utf8_next(&w); wc++; }
            if (cols + (cols ? 1 : 0) + wc > maxc && cols) break;
            cols += (cols ? 1 : 0) + wc;
            best = w;
            q = w;
            if (*q == ' ') q++;
            if (cols >= maxc) break;
        }
        if (!best) best = q;                    /* empty line */
        size_t n = (size_t)(best - p);
        if (n >= sizeof line) n = sizeof line - 1;
        memcpy(line, p, n);
        line[n] = 0;
        if (n && l) push_text_c(l, cx, y + FONT_H * px / 2, px, c, line);
        y += FONT_CELL_H * px * 1.15f;
        p = best;
        while (*p == ' ') p++;
        if (*p == '\n') p++;
    }
    return y - y0;
}

static float pxsize(float v) { return v < 1 ? 1 : floorf(v); }

/* ------------------------------------------------------------------ layout */

void ui_init(Ui *ui)
{
    memset(ui, 0, sizeof *ui);
    font_init();
    ui->vibration = true;
    ui->sound = true;
    ui->touch_flippers = true;
    ui->menu_hot = -1;
    for (int i = 0; i < UI_MAX_POINTERS; i++) { ui->ptr[i].id = -1; ui->ptr[i].key = -1; }
}

void ui_set_insets(Ui *ui, int top, int bottom, int left, int right, int corner)
{
    if (top == ui->inset_t && bottom == ui->inset_b && left == ui->inset_l && right == ui->inset_r && corner == ui->corner) return;
    ui->inset_t = top; ui->inset_b = bottom; ui->inset_l = left; ui->inset_r = right; ui->corner = corner;
    if (ui->W > 0 && ui->H > 0) ui_layout(ui, ui->W, ui->H);
}

void ui_layout(Ui *ui, int W, int H)
{
    ui->W = W;
    ui->H = H;
    ui->nd_fw = ui->nd_fh = 0;                          /* the layout follows the image */
}

/* the screen is laid out for the image being shown (table or Game Boy screen) and what
 * continues it (the TILT pad sits under the funnel of the tables) */
static void nd_update(Ui *ui, int fw, int fh)
{
    int scene = ui->scene;
    if (fw <= 0 || fh <= 0) { fw = PB_FIELD_W_NARROW; fh = PB_FIELD_H; }
    if (fw == ui->nd_fw && fh == ui->nd_fh && scene == ui->nd_sc && ui->nd.sw == ui->W && ui->nd.sh == ui->H) return;
    nd_layout(&ui->nd, ui->W, ui->H, ui->inset_t, ui->inset_b, ui->corner, fw, fh, scene);
    ui->nd_fw = fw;
    ui->nd_fh = fh;
    ui->nd_sc = scene;
}

void ui_nd_prepare(Ui *ui, int fw, int fh, int scene) { ui->scene = scene; nd_update(ui, fw, fh); }

/* ------------------------------------------------------------------ menu */

/* in the letters of the game's menus */
static const char *menu_label(const Ui *ui, int i)
{
    switch (i) {
    case 0: return "RESUME";
    case 1: return "QUICK SAVE";
    case 2: return "LOAD QUICK SAVE";
    case 3: return ui->vibration ? "VIBRATION : ON" : "VIBRATION : OFF";
    case 4: return ui->sound ? "SOUND : ON" : "SOUND : OFF";
    case 5: return ui->motion ? "MOTION TILT : ON" : "MOTION TILT : OFF";
    case 6: return ui->touch_flippers ? "TOUCH FLIPPERS : ON" : "TOUCH FLIPPERS : OFF";
    case 7: return ui->filter == UI_FILTER_DOT ? "SCREEN FILTER : DOT" : ui->filter == UI_FILTER_LCD ? "SCREEN FILTER : LCD" : "SCREEN FILTER : NONE";
    case 8: return ui->colors == UI_COLORS_BW ? "COLORS : BLACK & WHITE" : ui->colors == UI_COLORS_GREEN ? "COLORS : GAME BOY GREEN" : "COLORS : ORIGINAL";
    case 9: return "RESTART THE GAME";
    case 10: return "ABOUT";
    default: return "QUIT";
    }
}

static const int menu_action[NMENU] = {
    UI_ACT_RESUME, UI_ACT_QUICKSAVE, UI_ACT_QUICKLOAD, UI_ACT_TOGGLE_VIBRATION, UI_ACT_TOGGLE_SOUND, UI_ACT_TOGGLE_MOTION,
    UI_ACT_TOGGLE_TOUCH, UI_ACT_NEXT_FILTER, UI_ACT_NEXT_COLORS, UI_ACT_RESET, UI_ACT_ABOUT, UI_ACT_QUIT
};

/* the page ABOUT (2.7: under the entries of the menu, which then went past the bottom of a phone's
 * screen) */
static const char *MENU_HINT =
    "TOUCH FLIPPERS: the left or right half of the game plays a flipper. MOTION TILT: shake the phone left, "
    "right, or up and down, to tilt the table. Tap to go back.";
static const char *MENU_CREDITS = "Made by Reinhard Sharapov 2026";
/* the copyright lines of the game's own copyright screen and the trademarks
 * ("Copyright" in words: the font of the menus has no room for a readable sign) */
#define RIGHTS \
    "Pokémon Pinball: Copyright 1995-1999 Nintendo, Creatures Inc., GAME FREAK inc. Copyright 1999 " \
    "HAL Laboratory, Inc., Jupiter Corp. Pokémon, Pokémon character names and Game Boy Color are " \
    "trademarks of Nintendo."
static const char *MENU_RIGHTS = RIGHTS;

UiRect ui_menu_item(const Ui *ui, int i)
{
    /* the entry in screen pixels (centre of the row) */
    UiRect none = { 0, 0, 0, 0 };
    if (ui->nd.scale <= 0) return none;
    NdState st;
    ui_nd_state(ui, &st);
    st.menu_open = true;
    for (float y = 0; y < ui->H; y += ui->nd.scale * 0.5f) {
        bool in;
        if (nd_menu_hit(&ui->nd, &st, ui->W / 2.0f, y, &in) == i) {
            float y1 = y;
            while (y1 < ui->H && nd_menu_hit(&ui->nd, &st, ui->W / 2.0f, y1, &in) == i) y1 += 1;
            UiRect r = { ui->W * 0.1f, y, ui->W * 0.8f, y1 - y };
            return r;
        }
    }
    return none;
}

void ui_open_menu(Ui *ui, bool open)
{
    ui->menu_open = open;
    ui->about_open = false;
    ui->menu_hot = -1;
    ui->menu_sel = -1;
    for (int i = 0; i < UI_MAX_POINTERS; i++) { ui->ptr[i].id = -1; ui->ptr[i].active = false; ui->ptr[i].buttons = 0; ui->ptr[i].key = -1; }
    ui->touch_buttons = 0;
}

void ui_toast(Ui *ui, const char *msg, double seconds)
{
    snprintf(ui->toast, sizeof ui->toast, "%s", msg);
    ui->toast_until = ui->now + seconds;
}

/* ------------------------------------------------------------------ touches */

static void haptic(Ui *ui, int kind) { if (kind > ui->haptic) ui->haptic = kind; }

/* the point is on the game, where a finger plays the flippers (during a game, TOUCH FLIPPERS on) */
static bool on_play(const Ui *ui, float x, float y)
{
    float gx, gy, gw, gh;
    nd_play_rect(&ui->nd, &gx, &gy, &gw, &gh);
    return ui->in_game && ui->touch_flippers && !ui->no_rom && x >= gx && x < gx + gw && y >= gy && y < gy + gh;
}

/* The key under the finger and the Game Boy buttons it presses. A finger that came down on the game
 * (play) is a flipper, by the half it is over, wherever it slides (down onto the controls too);
 * elsewhere the controls only (nd_hit). On the table, the pad tilts it (left: the left tilt, right:
 * the right tilt, up: the upper tilt), as the game's default keys (DOWN, B, SELECT); elsewhere it is
 * the directional pad (its centre: SELECT), and the flipper keys are B (left) and A (right). */
static uint8_t control_at(Ui *ui, float x, float y, bool play, int *key)
{
    *key = -1;
    if (ui->no_rom) return 0;
    if (play) {
        float gx, gy, gw, gh;
        nd_play_rect(&ui->nd, &gx, &gy, &gw, &gh);
        bool left = x < gx + gw * 0.5f;
        *key = left ? ND_LFLIP : ND_RFLIP;
        return left ? GBC_LEFT : GBC_A;
    }
    uint8_t dirs;
    int k = nd_hit(&ui->nd, x, y, &dirs);
    *key = k;
    return nd_key_buttons(k, dirs, ui->field);
}

uint8_t ui_hit_test(Ui *ui, float x, float y, int *key)
{
    nd_update(ui, ui->nd_fw, ui->nd_fh);
    return control_at(ui, x, y, on_play(ui, x, y), key);
}

static void recompute(Ui *ui)
{
    uint8_t m = 0;
    for (int i = 0; i < UI_MAX_POINTERS; i++) if (ui->ptr[i].active) m |= ui->ptr[i].buttons;
    ui->touch_buttons = m;
}

static int menu_hit(Ui *ui, float x, float y, bool *in)
{
    NdState st;
    ui_nd_state(ui, &st);
    st.menu_open = true;
    return nd_menu_hit(&ui->nd, &st, x, y, in);
}

void ui_touch(Ui *ui, int action, int id, float x, float y)
{
    if (action == UI_CANCEL) {
        for (int i = 0; i < UI_MAX_POINTERS; i++) { ui->ptr[i].active = false; ui->ptr[i].id = -1; ui->ptr[i].buttons = 0; ui->ptr[i].key = -1; }
        ui->menu_hot = -1;
        recompute(ui);
        return;
    }
    nd_update(ui, ui->nd_fw, ui->nd_fh);
    if (ui->menu_open && ui->about_open) {
        if (action == UI_UP) {                          /* back to the menu */
            ui->about_open = false;
            haptic(ui, UI_HAPTIC_TICK);
        }
        return;
    }
    if (ui->menu_open) {
        bool in;
        if (action == UI_DOWN) {
            ui->menu_hot = menu_hit(ui, x, y, &in);
            if (ui->menu_hot < 0 && !in) ui->pending_action = UI_ACT_RESUME;
            else if (ui->menu_hot >= 0) haptic(ui, UI_HAPTIC_TICK);
        } else if (action == UI_MOVE) {
            if (ui->menu_hot >= 0 && menu_hit(ui, x, y, &in) != ui->menu_hot) ui->menu_hot = -1;
        } else if (action == UI_UP) {
            if (ui->menu_hot >= 0 && menu_hit(ui, x, y, &in) == ui->menu_hot) {
                ui->pending_action = menu_action[ui->menu_hot];
                haptic(ui, UI_HAPTIC_CLICK);
            }
            ui->menu_hot = -1;
        }
        return;
    }

    int slot = -1;
    for (int i = 0; i < UI_MAX_POINTERS; i++) if (ui->ptr[i].active && ui->ptr[i].id == id) { slot = i; break; }
    if (action == UI_DOWN) {
        uint8_t dirs;
        if (!ui->no_rom && nd_hit(&ui->nd, x, y, &dirs) == ND_MENU) {
            ui->pending_action = UI_ACT_OPEN_MENU;
            ui->press[ND_MENU] = 1;
            haptic(ui, UI_HAPTIC_CLICK);
            return;
        }
        if (slot < 0) for (int i = 0; i < UI_MAX_POINTERS; i++) if (!ui->ptr[i].active) { slot = i; break; }
        if (slot < 0) return;
        ui->ptr[slot].active = true;
        ui->ptr[slot].id = id;
        ui->ptr[slot].buttons = 0;
        ui->ptr[slot].key = -1;
        ui->ptr[slot].play = on_play(ui, x, y);
    }
    if (slot < 0) return;
    if (action == UI_UP) {
        ui->ptr[slot].active = false;
        ui->ptr[slot].id = -1;
        ui->ptr[slot].buttons = 0;
        ui->ptr[slot].key = -1;
    } else {
        int key = -1;
        uint8_t b = control_at(ui, x, y, ui->ptr[slot].play, &key);
        int old = ui->ptr[slot].key;
        if (action == UI_MOVE && !ui->ptr[slot].play) {
            /* a finger on a flipper key keeps it while it slides (a thumb rolls, leaves the key a
             * little), unless it reaches the other key (up to 2.5 the flipper fell back at once);
             * MENU opens only where a finger comes down */
            if ((old == ND_LFLIP || old == ND_RFLIP) && key != ND_LFLIP && key != ND_RFLIP) {
                key = old;
                b = ui->ptr[slot].buttons;
            } else if (key == ND_MENU) {
                key = -1;
                b = 0;
            }
        }
        if (b & ~ui->ptr[slot].buttons) {
            /* a new press: a click, lighter for the tilts */
            bool tilt = ui->field && key == ND_PAD;
            haptic(ui, tilt ? UI_HAPTIC_TICK : UI_HAPTIC_CLICK);
        }
        ui->ptr[slot].buttons = b;
        ui->ptr[slot].key = key;
        ui->ptr[slot].x = x;
        ui->ptr[slot].y = y;
    }
    recompute(ui);
}

void ui_set_external_buttons(Ui *ui, uint8_t b)
{
    uint8_t pressed = (uint8_t)(b & ~ui->ext_buttons);
    ui->ext_buttons = b;
    if (!ui->menu_open || !pressed) return;
    if (ui->about_open) {                               /* any of A, B, START: back to the menu */
        if (pressed & (GBC_A | GBC_B | GBC_START)) ui->about_open = false;
        return;
    }
    /* the menu with a gamepad or a keyboard */
    if (pressed & GBC_UP) ui->menu_sel = ui->menu_sel <= 0 ? NMENU - 1 : ui->menu_sel - 1;
    if (pressed & GBC_DOWN) ui->menu_sel = ui->menu_sel < 0 || ui->menu_sel >= NMENU - 1 ? 0 : ui->menu_sel + 1;
    if ((pressed & (GBC_A | GBC_START)) && ui->menu_sel >= 0) ui->pending_action = menu_action[ui->menu_sel];
    if (pressed & GBC_B) ui->pending_action = UI_ACT_RESUME;
}

uint8_t ui_buttons(const Ui *ui) { return ui->menu_open ? 0 : (uint8_t)(ui->touch_buttons | ui->ext_buttons); }

int ui_take_action(Ui *ui)
{
    int a = ui->pending_action;
    ui->pending_action = UI_ACT_NONE;
    return a;
}

/* ------------------------------------------------------------------ what the screen shows */

void ui_nd_state(const Ui *ui, NdState *st)
{
    memset(st, 0, sizeof *st);
    /* the colours of the table while the game is on it (or on one of its bonus stages), else the
     * menus'; on the table, its flipper keys and TILT pad only while the flippers are played (the
     * score count at the end of a ball, the pause menu: B, A and the directional pad) */
    st->set = !ui->in_game ? ND_SET_GREY : ui->table == 1 ? ND_SET_BLUE : ND_SET_RED;
    st->letters = !ui->field;
    float target[ND_NBTN];
    nd_targets((uint8_t)(ui->touch_buttons | ui->ext_buttons), ui->field, ui->menu_open, target, &st->pad_dirs);
    for (int i = 0; i < ND_NBTN; i++) st->press[i] = ui->press[i];
    st->menu_open = ui->menu_open;
    if (ui->about_open) {
        /* the page ABOUT: no entries, the texts */
        st->menu_n = 0;
        st->menu_hot = -1;
        st->menu_title = "ABOUT";
        st->menu_hint = MENU_HINT;
        st->menu_credits = MENU_CREDITS;
        st->menu_rights = MENU_RIGHTS;
        st->menu_info = ui->info[0] ? ui->info : NULL;
    } else {
        st->menu_n = NMENU;
        st->menu_hot = ui->menu_hot >= 0 ? ui->menu_hot : ui->menu_sel;
        st->menu_title = "PINBALL NS";
        for (int i = 0; i < NMENU && i < ND_MENU_MAX; i++) st->menu_label[i] = menu_label(ui, i);
    }
    if (ui->toast[0] && ui->now < ui->toast_until) st->toast = ui->toast;
}

/* ------------------------------------------------------------------ no ROM yet */

#define HOW_TO_IMPORT \
    "Copy it to the phone, then in your file manager, tap it and choose \"Open with\" " \
    "Pinball NS (or \"Share\" to Pinball NS).\n\n"

static const char *NO_ROM_MSG =
    "Pinball NS needs the ROM of your own Pokémon Pinball cartridge (US version, .gbc file). "
    "It is not included.\n\n"
    HOW_TO_IMPORT
    "The app keeps its own copy: you only have to do it once.\n\n"
    "Made by Reinhard Sharapov 2026. " RIGHTS;

#define NO_ROM_SUB "Pokémon Pinball, the whole table"

/* the width the text may take: the screen less its side margins (the cut-out, the rounded
 * corners, and a little room) */
static float no_rom_width(const Ui *ui)
{
    float m = ui->W * 0.05f;
    if (ui->inset_l > m) m = (float)ui->inset_l;
    if (ui->inset_r > m) m = (float)ui->inset_r;
    if (ui->corner * 0.3f > m) m = ui->corner * 0.3f;
    return ui->W - 2 * m;
}

/* title, explanation, and the reason of a refused file, every line wrapped to the width; returns
 * the height used */
static float no_rom_layout(const Ui *ui, UiList *l, float px)
{
    float top = (float)ui->inset_t + ui->H * 0.04f;
    float cx = ui->W / 2.0f, w = no_rom_width(ui);
    float y = top;
    y += push_para(l, cx, y, w, px * 2, COL_ACCENT, "Pinball NS");
    y += FONT_CELL_H * px * 0.4f;
    y += push_para(l, cx, y, w, px, COL_DIM, NO_ROM_SUB);
    y += FONT_CELL_H * px;
    y += push_para(l, cx, y, w, px, COL_TEXT, NO_ROM_MSG);
    if (ui->no_rom_detail[0]) {
        y += FONT_CELL_H * px;
        y += push_para(l, cx, y, w, px, COL_ACCENT, ui->no_rom_detail);
    }
    return y - top;
}

/* the font as large as possible with everything on the screen: lines no wider than the screen
 * (the longest word included) and the whole under the top cut-out, above the bottom one */
static bool no_rom_fits(const Ui *ui, float px)
{
    float w = no_rom_width(ui);
    if (text_w("Pinball NS", px * 2) > w || text_w(NO_ROM_SUB, px) > w) return false;   /* each on one line */
    return no_rom_layout(ui, NULL, px) <= ui->H - ui->inset_t - ui->inset_b - ui->H * 0.06f;
}

static void draw_no_rom(const Ui *ui, UiList *l)
{
    float px = pxsize(ui->W / (30.0f * FONT_CELL_W));
    while (px > 1 && !no_rom_fits(ui, px)) px -= 1;
    no_rom_layout(ui, l, px);
}

void ui_build(Ui *ui, UiList *l, int fw, int fh)
{
    l->n = 0;
    l->text_n = 0;

    if (ui->no_rom) {
        UiItem *it = &l->item[l->n++];
        memset(it, 0, sizeof *it);
        it->kind = UI_SHAPE;
        it->w = (float)ui->W;
        it->h = (float)ui->H;
        it->color = COL_BG;
        draw_no_rom(ui, l);
        return;
    }
    /* one picture: the canvas made by the app (app_frame) */
    nd_update(ui, fw, fh);
    float target[ND_NBTN];
    uint8_t dirs;
    nd_targets((uint8_t)(ui->touch_buttons | ui->ext_buttons), ui->field, ui->menu_open, target, &dirs);
    nd_animate(ui->press, target);
    UiItem *it = &l->item[l->n++];
    memset(it, 0, sizeof *it);
    it->kind = UI_GAME;
    it->w = ui->nd.cw * ui->nd.scale;
    it->h = ui->nd.ch * ui->nd.scale;
    /* the filter and the colours: the whole picture alike, the controls and the menu as the game */
    it->filter = ui->filter;
    it->colors = ui->colors;
    it->fx0 = 0;
    it->fy0 = 0;
    it->fx1 = (float)ui->nd.cw;
    it->fy1 = (float)ui->nd.ch;
}
