/*
 * ui.c - touch interface of the mobile version (platform independent).
 *
 * One display: the whole screen is one picture drawn in the pixels of the game, the game as
 * wide as the screen at the top, what it shows continued below it and the keys over that
 * (platform/mobile/design.c). During a game, a finger on the game tilts the table (its left third:
 * the left tilt, its middle: the upper tilt, its right third: the right tilt) or plays the flippers
 * (its left and right halves), as the option GAME TOUCH says. With the controls hidden (CONTROLS), the
 * screen under the game plays the flippers (B and A in the game's menus) and the game is touched as
 * GAME TOUCH says (in the game's menus, its thirds are the left arrow, up and the right arrow).
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
    ui->touch_mode = UI_TOUCH_TILT;
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
    bool hidden = ui->hide_controls && ui->tee;
    if (fw == ui->nd_fw && fh == ui->nd_fh && scene == ui->nd_sc && ui->nd.sw == ui->W && ui->nd.sh == ui->H && ui->nd.tee == ui->tee &&
        ui->nd.hidden == hidden) return;
    nd_layout(&ui->nd, ui->W, ui->H, ui->inset_t, ui->inset_b, ui->corner, fw, fh, scene, ui->tee, hidden);
    ui->nd_fw = fw;
    ui->nd_fh = fh;
    ui->nd_sc = scene;
}

void ui_nd_prepare(Ui *ui, int fw, int fh, int scene, bool tee) { ui->scene = scene; ui->tee = tee; nd_update(ui, fw, fh); }

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
    case 6: return ui->touch_mode == UI_TOUCH_FLIPPERS ? "GAME TOUCH : FLIPPERS" : ui->touch_mode == UI_TOUCH_OFF ? "GAME TOUCH : OFF" : "GAME TOUCH : TILT";
    case 7: return ui->hide_controls ? "CONTROLS : HIDDEN" : "CONTROLS : SHOWN";
    case 8: return ui->filter == UI_FILTER_DOT ? "SCREEN FILTER : DOT" : ui->filter == UI_FILTER_LCD ? "SCREEN FILTER : LCD" : "SCREEN FILTER : NONE";
    case 9: return ui->colors == UI_COLORS_BW ? "COLORS : BLACK & WHITE" : ui->colors == UI_COLORS_GREEN ? "COLORS : GAME BOY GREEN" : "COLORS : ORIGINAL";
    case 10: return ui->game_gen ? "GAME : GENERATIONS" : "GAME : POKéMON PINBALL";
    case 11: return "RESTART THE GAME";
    case 12: return "ABOUT";
    default: return "QUIT";
    }
}

/* the rows of the menu: its entries, but those the platform has not (ui->menu_hide) */
static int menu_rows(const Ui *ui, int *entry)
{
    int n = 0;
    for (int i = 0; i < NMENU; i++) if (!(ui->menu_hide & (1u << i))) entry[n++] = i;
    return n;
}

static int row_action(const Ui *ui, int row);

static const int menu_action[NMENU] = {
    UI_ACT_RESUME, UI_ACT_QUICKSAVE, UI_ACT_QUICKLOAD, UI_ACT_TOGGLE_VIBRATION, UI_ACT_TOGGLE_SOUND, UI_ACT_TOGGLE_MOTION,
    UI_ACT_NEXT_TOUCH, UI_ACT_TOGGLE_CONTROLS, UI_ACT_NEXT_FILTER, UI_ACT_NEXT_COLORS, UI_ACT_NEXT_GAME, UI_ACT_RESET,
    UI_ACT_ABOUT, UI_ACT_QUIT
};

/* the pages ABOUT (2.7: under the entries of the menu, which then went past the bottom of a phone's
 * screen; 2.9: three pages, an empty line between two subjects) */
static const char *MENU_HINT =
    "GAME TOUCH: TILT: the left, middle or right third of the game gives the left, upper or right tilt. "
    "FLIPPERS: its halves play the flippers.\n\n"
    "CONTROLS: HIDDEN: in a game, MENU and START only; under the game, the halves of the screen play the "
    "flippers.\n\n"
    "MOTION TILT: tap a side of the phone, even lightly, to tilt that way; shake it up and down for the "
    "upper tilt.\n\n"
    "GAME: Pokémon Pinball, or Pokémon Pinball Generations once its ROM or IPS patch is opened.\n\n"
    "Tap for more.";
static const char *MENU_CREDITS = "Made by Reinhard Sharapov 2026. Controls after a design by Gianchy3000. Pokémon Pinball "
    "Generations by RainbowDevs (formerly TPPDevs).";
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
    ui->about_page = 0;
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

/* under the game picture, with the controls hidden: where the flipper keys would be */
static bool under_game(const Ui *ui, float y)
{
    float gx, gy, gw, gh;
    nd_game_rect(&ui->nd, &gx, &gy, &gw, &gh);
    return ui->nd.hidden && y >= gy + gh;
}

/* the point is on the game, where a finger tilts the table or plays the flippers (GAME TOUCH): the
 * flippers during a game (its menus included: the right half is A), the tilts while it is played (the
 * controls hidden: in the game's menus too, as its arrows); the controls hidden, the screen under the
 * game too (the flipper keys), MENU and START apart */
static bool on_play(const Ui *ui, float x, float y)
{
    if (ui->no_rom || !ui->in_game) return false;
    uint8_t d;
    if (nd_hit(&ui->nd, x, y, &d) >= 0) return false;
    if (under_game(ui, y)) return true;
    float gx, gy, gw, gh;
    nd_play_rect(&ui->nd, &gx, &gy, &gw, &gh);
    bool on = ui->touch_mode == UI_TOUCH_FLIPPERS || (ui->touch_mode == UI_TOUCH_TILT && (ui->field || ui->nd.hidden));
    return on && x >= gx && x < gx + gw && y >= gy && y < gy + gh;
}

/* What a finger coming down on the game does (on_play): a flipper by the half it is on; a tilt by the
 * third of the game it is on (left, middle: the upper tilt, right; 2.9, the user's design), shown on the
 * TILT pad; in the game's menus (the controls hidden), the left arrow, up, the right arrow. Under the
 * game with the controls hidden, the flipper keys (B and A in the game's menus). */
static uint8_t play_zone(const Ui *ui, float x, float y, int *key, uint8_t *dirs)
{
    float gx, gy, gw, gh;
    nd_game_rect(&ui->nd, &gx, &gy, &gw, &gh);
    bool left = x < gx + gw * 0.5f;
    if (under_game(ui, y)) {
        *key = left ? ND_LFLIP : ND_RFLIP;
        *dirs = 0;
        return nd_key_buttons(*key, 0, ui->field, ui->tee);
    }
    if (ui->touch_mode == UI_TOUCH_FLIPPERS) {
        *key = left ? ND_LFLIP : ND_RFLIP;
        *dirs = 0;
        return left ? GBC_LEFT : GBC_A;
    }
    *key = ND_PAD;
    *dirs = x < gx + gw / 3.0f ? ND_DIR_LEFT : x < gx + gw * 2.0f / 3.0f ? ND_DIR_UP : ND_DIR_RIGHT;
    return nd_key_buttons(ND_PAD, *dirs, ui->field, true);
}

/* The key under the finger and the Game Boy buttons it presses. A finger that came down on the game
 * (play) keeps what it did there wherever it slides (down onto the controls too); elsewhere the
 * controls only (nd_hit). On the table, the pad tilts it (left: the left tilt, right: the right tilt,
 * up: the upper tilt), as the game's default keys (DOWN, B, SELECT); elsewhere it is the directional pad
 * (its centre: SELECT), and the flipper keys are B (left) and A (right). */
static uint8_t control_at(Ui *ui, float x, float y, bool play, int *key)
{
    *key = -1;
    if (ui->no_rom) return 0;
    if (play) {
        uint8_t dirs;
        return play_zone(ui, x, y, key, &dirs);
    }
    uint8_t dirs;
    int k = nd_hit(&ui->nd, x, y, &dirs);
    *key = k;
    return nd_key_buttons(k, dirs, ui->field, ui->tee);
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
        if (action == UI_UP) {                          /* its next page, then back to the menu */
            if (ui->about_page < UI_ABOUT_PAGES - 1) ui->about_page++;
            else { ui->about_open = false; ui->about_page = 0; }
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
                ui->pending_action = row_action(ui, ui->menu_hot);
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
        if (ui->ptr[slot].play) {                       /* what it does there, wherever it slides */
            uint8_t zd;
            ui->ptr[slot].zone = play_zone(ui, x, y, &ui->ptr[slot].zone_key, &zd);
        }
    }
    if (slot < 0) return;
    if (action == UI_UP) {
        ui->ptr[slot].active = false;
        ui->ptr[slot].id = -1;
        ui->ptr[slot].buttons = 0;
        ui->ptr[slot].key = -1;
    } else {
        int key = -1;
        uint8_t b;
        if (ui->ptr[slot].play) { b = ui->ptr[slot].zone; key = ui->ptr[slot].zone_key; }
        else b = control_at(ui, x, y, false, &key);
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
    if (ui->about_open) {                               /* A, START: its next page, then the menu; B: the menu */
        if ((pressed & (GBC_A | GBC_START)) && ui->about_page < UI_ABOUT_PAGES - 1) ui->about_page++;
        else if (pressed & (GBC_A | GBC_B | GBC_START)) { ui->about_open = false; ui->about_page = 0; }
        return;
    }
    /* the menu with a gamepad or a keyboard */
    int entry[NMENU], n = menu_rows(ui, entry);
    if (pressed & GBC_UP) ui->menu_sel = ui->menu_sel <= 0 ? n - 1 : ui->menu_sel - 1;
    if (pressed & GBC_DOWN) ui->menu_sel = ui->menu_sel < 0 || ui->menu_sel >= n - 1 ? 0 : ui->menu_sel + 1;
    if ((pressed & (GBC_A | GBC_START)) && ui->menu_sel >= 0) ui->pending_action = row_action(ui, ui->menu_sel);
    if (pressed & GBC_B) ui->pending_action = UI_ACT_RESUME;
}

static int row_action(const Ui *ui, int row)
{
    int entry[NMENU], n = menu_rows(ui, entry);
    return row >= 0 && row < n ? menu_action[entry[row]] : UI_ACT_NONE;
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
    st->set = !ui->in_game ? ND_SET_GREY : nd_set_of_table(ui->table);
    st->letters = !ui->field;
    float target[ND_NBTN];
    nd_targets((uint8_t)(ui->touch_buttons | ui->ext_buttons), ui->field, ui->tee, ui->menu_open, target, &st->pad_dirs);
    for (int i = 0; i < ND_NBTN; i++) st->press[i] = ui->press[i];
    st->menu_open = ui->menu_open;
    if (ui->about_open) {
        /* the page ABOUT: no entries, the texts */
        st->menu_n = 0;
        st->menu_hot = -1;
        static const char *const titles[UI_ABOUT_PAGES] = { "ABOUT 1/3", "ABOUT 2/3", "ABOUT 3/3" };
        st->menu_title = titles[ui->about_page < UI_ABOUT_PAGES ? ui->about_page : 0];
        if (ui->about_page == 0) st->menu_hint = ui->about_hint ? ui->about_hint : MENU_HINT;
        else if (ui->about_page == 1) {
            st->menu_hint = MENU_CREDITS;
            st->menu_credits = MENU_RIGHTS;
            st->menu_rights = "Tap for more.";
        } else {
            st->menu_hint = ui->info[0] ? ui->info : "Nothing measured yet.";
            st->menu_credits = "Tap to go back.";
        }
    } else {
        int entry[NMENU];
        st->menu_n = menu_rows(ui, entry);
        st->menu_hot = ui->menu_hot >= 0 ? ui->menu_hot : ui->menu_sel;
        st->menu_title = "PINBALL NS";
        for (int i = 0; i < st->menu_n && i < ND_MENU_MAX; i++) st->menu_label[i] = menu_label(ui, entry[i]);
    }
    if (ui->toast[0] && ui->now < ui->toast_until) st->toast = ui->toast;
}

/* ------------------------------------------------------------------ no ROM yet */

#define HOW_TO_IMPORT \
    "Copy it to the phone, then in your file manager, tap it and choose \"Open with\" " \
    "Pinball NS (or \"Share\" to Pinball NS).\n\n"

/* the explanation, with the platform's way to open a ROM (Ui.no_rom_how) */
static const char *no_rom_msg(const Ui *ui)
{
    static char buf[1024];
    snprintf(buf, sizeof buf, "%s%s%s",
             "Pinball NS needs the ROM of your own Pokémon Pinball cartridge (US version, .gbc file). "
             "It is not included. It also plays Pokémon Pinball Generations 1.6: open its ROM, or its IPS patch "
             "once the US ROM is installed.\n\n",
             ui->no_rom_how ? ui->no_rom_how : HOW_TO_IMPORT,
             "The app keeps its own copy: you only have to do it once.\n\n"
             "Made by Reinhard Sharapov 2026. " RIGHTS);
    return buf;
}

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
    y += push_para(l, cx, y, w, px, COL_TEXT, no_rom_msg(ui));
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
    nd_targets((uint8_t)(ui->touch_buttons | ui->ext_buttons), ui->field, ui->tee, ui->menu_open, target, &dirs);
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
