/*
 * ui.h - touch interface of the mobile version (platform independent).
 *
 * The screen is one picture in the pixels of the game (platform/mobile/design.h), sent to the
 * platform as a display list (the game image item; rounded rectangles and text only for the
 * explanation shown before a ROM is installed). Touches are given to ui_touch(); the resulting
 * Game Boy buttons are read with ui_buttons(), menu choices with ui_take_action().
 */
#ifndef PB_UI_H
#define PB_UI_H

#include <stdbool.h>
#include <stdint.h>
#include "design.h"

enum { UI_SHAPE = 0, UI_TEXT = 1, UI_GAME = 2 };

typedef struct {
    int kind;
    float x, y, w, h;      /* pixels */
    float radius;          /* corner radius (shape) */
    uint32_t color;        /* 0xAARRGGBB: fill (shape) or text colour */
    uint32_t border;       /* border colour (shape) */
    float border_w;
    int text;              /* offset of the UTF-8 text in UiList.text (text) */
    float px;              /* size of one font pixel (text) */
    int filter;            /* the game image: UI_FILTER_* over the part fx0,fy0..fx1,fy1 (its pixels) */
    float fx0, fy0, fx1, fy1;
    int colors;            /* the game image: UI_COLORS_* (all of it) */
    float sy0, sy1;        /* the game image: only its lines sy0..sy1 (its pixels) in the rectangle; 0, 0: all
                            * (the dual-screen devices: one half of the table on each screen) */
} UiItem;

#define UI_MAX_ITEMS 320
#define UI_TEXT_ARENA 12288

typedef struct {
    UiItem item[UI_MAX_ITEMS];
    int n;
    char text[UI_TEXT_ARENA];
    int text_n;
} UiList;

enum {
    UI_ACT_NONE = 0, UI_ACT_RESUME, UI_ACT_QUICKSAVE, UI_ACT_QUICKLOAD, UI_ACT_TOGGLE_VIBRATION,
    UI_ACT_TOGGLE_SOUND, UI_ACT_RESET, UI_ACT_QUIT, UI_ACT_OPEN_MENU, UI_ACT_TOGGLE_MOTION, UI_ACT_NEXT_FILTER,
    UI_ACT_NEXT_TOUCH, UI_ACT_NEXT_COLORS, UI_ACT_ABOUT, UI_ACT_NEXT_GAME, UI_ACT_TOGGLE_CONTROLS
};

#define UI_MENU_ITEMS 14
#define UI_ABOUT_PAGES 3

/* what a finger on the game does during a game (2.8): the tilts (2.9, the user's design: its left
 * third the left tilt, its middle the upper tilt, its right third the right tilt, from top to bottom;
 * 2.8 after Gianchy3000's: its top the upper tilt, its bottom left and right the side ones), the
 * flippers (its left and right halves), nothing */
enum { UI_TOUCH_TILT = 0, UI_TOUCH_FLIPPERS, UI_TOUCH_OFF, UI_TOUCHES };

/* the screen filters of the game (the classic ones of the emulators): none (sharp pixels), dots
 * (each pixel a round dot, a little glow between them), LCD (the grid of a liquid crystal screen,
 * the red, green and blue of each cell side by side) */
enum { UI_FILTER_NONE = 0, UI_FILTER_DOT, UI_FILTER_LCD, UI_FILTERS };
/* the colours of the screen: the game's own (a Game Boy Color), black and white, the four greens of
 * the first Game Boy's screen (in shades between them) */
enum { UI_COLORS_ORIGINAL = 0, UI_COLORS_BW, UI_COLORS_GREEN, UI_COLORSETS };

/* haptic feedback requested by the interface (strongest of the frame) */
enum { UI_HAPTIC_NONE = 0, UI_HAPTIC_TICK = 1, UI_HAPTIC_CLICK = 2, UI_HAPTIC_HEAVY = 3 };

/* touch actions */
enum { UI_DOWN = 0, UI_UP = 1, UI_MOVE = 2, UI_CANCEL = 3 };

#define UI_MAX_POINTERS 10

typedef struct { float x, y, w, h; } UiRect;

typedef struct {
    /* screen and layout (design.h), made for the game image being shown */
    int W, H;
    NdLayout nd;
    int nd_fw, nd_fh, nd_sc;        /* game image and scene the layout was made for */
    int scene;                      /* what continues the game now (ND_SCENE_*, set by the app) */
    float press[ND_NBTN];           /* key animations */
    int inset_t, inset_b, inset_l, inset_r;   /* screen covered by the system (cut-out) */
    int corner;                     /* radius of the rounded corners of the screen */
    /* input */
    /* the fingers: `play` one that came down on the game (a flipper or a tilt, by where it came down,
     * wherever it slides: `zone`, the buttons it presses) */
    struct { int id; float x, y; bool active, play; uint8_t buttons, zone; int key, zone_key; } ptr[UI_MAX_POINTERS];
    uint8_t touch_buttons, ext_buttons;
    bool in_game;                   /* the pinball screen (the table, its menus, its bonus stages) */
    bool field;                     /* the table or a bonus stage is played: its keys, the TILT pad */
    bool tee;                       /* the layout of a game (design.h: NdLayout.tee), set by the app */
    int table;                      /* the table played, or the last one (PB_TABLE_*) */
    int haptic;                     /* feedback requested (UI_HAPTIC_*), strongest first */
    /* menu */
    bool menu_open;
    int about_page;                 /* its page shown: 0 the controls, 1 the author and the rights, 2 the
                                     * measures (2.8: two pages; in one, it went past the bottom of the screen) */
    bool about_open;                /* the menu shows its page ABOUT (the explanations, the author, the
                                     * rights, what the platform measured): a tap goes back */
    int menu_hot;                   /* item under the finger, -1 none */
    int menu_sel;                   /* item chosen with a gamepad / keyboard, -1 none */
    int pending_action;
    /* settings shown in the menu */
    bool vibration, sound;
    bool motion;                    /* tilt by moving the phone (the platform's accelerometer) */
    int touch_mode;                 /* UI_TOUCH_*: what a finger on the game does */
    bool hide_controls;             /* CONTROLS: HIDDEN (2.9): during a game, MENU and START only (design.h) */
    /* set by the platform: the entries of the menu it has not (bit i: entry i; the desktop versions:
     * no MOTION TILT), the first page ABOUT in its words (NULL: the phone's) */
    uint32_t menu_hide;
    const char *about_hint;
    const char *no_rom_how;         /* how to open a ROM there, for the screen without a ROM (NULL: the phone's) */
    bool game_gen;                  /* the game played is Pokemon Pinball Generations */
    bool other_game;                /* the other game is installed too (the menu switches) */
    int filter;                     /* UI_FILTER_* */
    int colors;                     /* UI_COLORS_* */
    char info[256];                 /* what the platform measured, shown on the page ABOUT */
    /* messages */
    char toast[160];
    double toast_until, now;
    /* no game yet: explanation screen */
    bool no_rom;
    char no_rom_detail[256];
} Ui;

void ui_init(Ui *ui);
void ui_layout(Ui *ui, int width, int height);
void ui_touch(Ui *ui, int action, int id, float x, float y);
void ui_set_external_buttons(Ui *ui, uint8_t buttons);   /* gamepad / keyboard */
uint8_t ui_buttons(const Ui *ui);
/* tools: what a finger coming down at (x, y) would press (*key: the control, -1 none) */
uint8_t ui_hit_test(Ui *ui, float x, float y, int *key);
int  ui_take_action(Ui *ui);
/* the entries of the menu, by their UI_ACT_* (the platform's menus) */
enum { UI_ENTRY_RESUME = 0, UI_ENTRY_QUICKSAVE, UI_ENTRY_QUICKLOAD, UI_ENTRY_VIBRATION, UI_ENTRY_SOUND, UI_ENTRY_MOTION,
       UI_ENTRY_TOUCH, UI_ENTRY_CONTROLS, UI_ENTRY_FILTER, UI_ENTRY_COLORS, UI_ENTRY_GAME, UI_ENTRY_RESTART, UI_ENTRY_ABOUT,
       UI_ENTRY_QUIT };
void ui_open_menu(Ui *ui, bool open);
void ui_toast(Ui *ui, const char *msg, double seconds);
/* build the display list; frame_w/h: size of the current game image (0: no game) */
void ui_build(Ui *ui, UiList *list, int frame_w, int frame_h);
/* what the screen shows (after ui_build) */
void ui_nd_state(const Ui *ui, NdState *st);
void ui_nd_prepare(Ui *ui, int frame_w, int frame_h, int scene, bool tee);   /* lays the screen out for this image */
void ui_set_insets(Ui *ui, int top, int bottom, int left, int right, int corner);
UiRect ui_menu_item(const Ui *ui, int i);                 /* menu entry i (0..UI_MENU_ITEMS-1) */

#endif
