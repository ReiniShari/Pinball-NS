/*
 * design.h - the screen of the Android version ("New Design"): one picture in the pixels of
 * the game, as wide as the game (the table at its original width, 160 pixels).
 *
 * The game is shown as wide as the screen; nothing is added on its left and right. The tables
 * are at the top; the screens of the Game Boy's size (title, menus, Pokedex, high scores, bonus
 * stages) are centred in the part of the screen above the controls. Around the game, what it
 * shows continues, made of its own graphics:
 *   - the Red and Blue tables: the frame of the table closes under the status bar (lines,
 *     rivets or screws, the funnel of the drain, the launch lane of the Blue table);
 *   - the bonus stages: their background pattern above and below, the drain lane below, drawn
 *     with the stage's own tiles and palettes (so they fade with it);
 *   - the other screens: their background colour, above and below.
 * Over it, at the bottom, the controls in the colours of the table played (the blue keys of the Red
 * table, the green ones of the Blue table, the gold and navy ones of the Gold and Silver tables of
 * Generations), on the table and in its bonus stages; the grey keys of the menus (B, A, directional
 * pad) everywhere else. 2.8 (after an idea of Gianchy3000, issue 3 of the project): two large flipper
 * keys, each one the whole quarter of the screen beside the pad, under the game; during a game the pad
 * is a "T" (the up arm, the bar of TILT with its left and right arrows), MENU and START under its bar,
 * away from the thumbs; in the menus of the game, a whole directional pad, MENU and START under it.
 * SELECT is the centre of the directional pad (on the table, the upper tilt is the up arm and TILT).
 * 2.9 (the user's designs): the keys a little smaller (40 pixels), level with the middle of the pad,
 * the game's own flipper in them (its tiles in the ROM), the screws of the Blue table beside the up arm;
 * a finger presses a key only on its picture; the controls can be hidden during a game (MENU and START
 * stay).
 */
#ifndef PB_DESIGN_H
#define PB_DESIGN_H

#include <stdbool.h>
#include <stdint.h>
#include "../../src/game/pinball.h"

#define ND_W      160                  /* width of the game: the canvas is as wide as it */
#define ND_MAX_W  1024                 /* canvas size limits (game pixels) */
#define ND_MAX_H  1024

enum { ND_LFLIP = 0, ND_RFLIP, ND_PAD, ND_MENU, ND_START, ND_NBTN };
enum { ND_SET_RED = 0, ND_SET_BLUE, ND_SET_GREY, ND_SET_GOLD, ND_SET_SILVER, ND_NSETS };
/* what continues the game below it */
enum { ND_SCENE_SCREEN = 0, ND_SCENE_RED, ND_SCENE_BLUE, ND_SCENE_STAGE };

/* directions of the pad (as the Game Boy buttons) */
#define ND_DIR_RIGHT 0x01
#define ND_DIR_LEFT  0x02
#define ND_DIR_UP    0x04
#define ND_DIR_DOWN  0x08

#define ND_MENU_MAX  14

/* Game Boy buttons, as the joypad bits of the emulator (GBC_*) */
#define ND_GB_A      0x01
#define ND_GB_B      0x02
#define ND_GB_SELECT 0x04
#define ND_GB_START  0x08
#define ND_GB_RIGHT  0x10
#define ND_GB_LEFT   0x20
#define ND_GB_UP     0x40
#define ND_GB_DOWN   0x80

typedef struct { int x, y, w, h; } NdRect;

typedef struct {
    int sw, sh;                        /* screen (pixels) */
    float scale;                       /* screen pixels per canvas pixel */
    int cw, ch;                        /* canvas (game pixels), covering the screen */
    int vh;                            /* its whole rows on screen (the last one can be cut) */
    int bottom;                        /* the controls end there (above a bottom cut-out) */
    int gx, gy, gw, gh;                /* the game image in the canvas */
    int corner;                        /* rounded corners of the screen (canvas pixels) */
    int scene;                         /* ND_SCENE_*: the panel of a table, a stage, a screen */
    int play_h;                        /* the game is touched from the top down to there; the controls below */
    bool tee;                          /* during a game: the pad is a "T" (no down arm), MENU and START under its bar */
    bool hidden;                       /* the controls hidden during a game (2.9): MENU and START only, at the bottom */
    NdRect btn[ND_NBTN];               /* controls (canvas pixels); the pad: the box of its cross */
} NdLayout;

typedef struct {
    int set;                           /* ND_SET_*: the colours of the controls */
    bool letters;                      /* the keys are B and A and the pad a directional pad (the
                                        * game's menus, its score count), not the flippers and TILT */
    float press[ND_NBTN];              /* 0 released .. 1 pressed (animated by the caller) */
    uint8_t pad_dirs;                  /* directions of the pad pressed (ND_DIR_*) */
    /* the menu of the app, drawn on the canvas */
    bool menu_open;
    int menu_n, menu_hot;              /* entries, highlighted entry (-1 none) */
    const char *menu_title;
    const char *menu_label[ND_MENU_MAX];
    const char *menu_hint;
    const char *menu_credits;          /* under the hint: the author */
    const char *menu_rights;           /* then the rights on the game */
    const char *menu_info;             /* then what the platform measured (the pace of the game, its sound) */
    const char *toast;                 /* a short message over the bottom of the game */
} NdState;

/* Layout for a screen of sw x sh pixels (inset_t / inset_b: covered by a camera cut-out;
 * corner: radius of its rounded corners), a game image of gw x gh and what is shown under it
 * (nd_scene: the TILT pad sits under the funnel of the tables); tee: during a game, hidden: its
 * controls hidden (see NdLayout; with them, a short screen gives the game more room). */
void nd_layout(NdLayout *L, int sw, int sh, int inset_t, int inset_b, int corner, int gw, int gh, int scene, bool tee, bool hidden);
/* the game's own flipper in the flipper keys: its tiles in the ROM played (18 tiles of 16 bytes,
 * pb_flipper_tiles), NULL: a flipper drawn by this program (the icon) */
void nd_set_flipper(const uint8_t *tiles);
/* what continues the game image (of height gh) of the screen pb shows */
int  nd_scene(const Pinball *pb, int gh);
/* the colours of the controls of a table (PB_TABLE_*; -1: the menus') */
int  nd_set_of_table(int table);

/* The canvas (L->cw x L->ch pixels, 0x00RRGGBB, stride L->cw), in two parts.
 * nd_render_game: what comes with a picture of the game, made once per picture, just after it
 * (bg): the game and what continues it around it. pb gives what the game showed (pb_view: screen,
 * stage) and its video memory for the extended stages. fade: how far the picture is faded to white
 * and to black (measured on it): the drawn parts follow it.
 * nd_render_controls: the canvas shown, bg with the controls, the message and the menu (out: a
 * buffer of its own, bg is kept for the next ones). */
void nd_render_game(const NdLayout *L, const Pinball *pb, const uint32_t *game, int game_stride, uint32_t *bg, int fade[2]);
void nd_render_controls(const NdLayout *L, const NdState *st, const uint32_t *bg, const int fade[2], uint32_t *out);

/* the control under a screen point (-1: none), below the game only, on what is drawn of it (2.9: the
 * octagon of a flipper key, the arm of the pad, the rounded box of a pill); the controls hidden, MENU and
 * START only. For the pad, the arm under the point (ND_DIR_*; 0: its centre). */
int  nd_hit(const NdLayout *L, float sx, float sy, uint8_t *dirs);
/* menu entry under a screen point (-1: none), and whether the point is inside the menu box */
int  nd_menu_hit(const NdLayout *L, const NdState *st, float sx, float sy, bool *inside);
/* the game image in screen pixels */
void nd_game_rect(const NdLayout *L, float *x, float *y, float *w, float *h);
/* where a finger plays on the game (GAME TOUCH), in screen pixels: as wide as the game, from the top
 * of the screen down to the controls (or to the bottom of the table); the controls hidden, the whole
 * screen */
void nd_play_rect(const NdLayout *L, float *x, float *y, float *w, float *h);

/* The Game Boy buttons a key presses. On the table (field), the pad tilts it as the game's
 * default keys (left: DOWN, the left tilt; right: B, the right tilt; up: SELECT, the upper
 * tilt) and the flipper keys are LEFT and A; elsewhere the pad is the directional pad (its
 * centre: SELECT) and the keys are B and A. The "T" of the game's own menus (tee, not field: the
 * pause menu, SAVE over CANCEL) has no down arm: its left arrow is also UP, its right one DOWN. */
uint8_t nd_key_buttons(int key, uint8_t dirs, bool field, bool tee);
/* the keys shown pressed for the Game Boy buttons pressed (touch, gamepad): 1 or 0 per key,
 * and the directions of the pad */
void nd_targets(uint8_t buttons, bool field, bool tee, bool menu_open, float target[ND_NBTN], uint8_t *dirs);
/* moves the key animations towards their targets: a press shows at once, a release in a few
 * frames (the flipper falls back) */
void nd_animate(float press[ND_NBTN], const float target[ND_NBTN]);

/* the icon of the app: the right flipper key of the Blue table, n x n (as on screen: n = ND_ICON;
 * 8..64), 0xAARRGGBB, the cut corners of the octagon transparent */
#define ND_ICON 32
void nd_icon(uint32_t *out, int n);

#endif
