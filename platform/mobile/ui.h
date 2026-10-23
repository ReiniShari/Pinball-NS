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
    UI_ACT_TOGGLE_SOUND, UI_ACT_RESET, UI_ACT_QUIT, UI_ACT_OPEN_MENU
};

#define UI_MENU_ITEMS 7

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
    struct { int id; float x, y; bool active; uint8_t buttons; int key; } ptr[UI_MAX_POINTERS];
    uint8_t touch_buttons, ext_buttons;
    bool in_game;                   /* the pinball screen: the halves of the game image are flippers */
    bool field;                     /* the table or a bonus stage is played: its keys, the TILT pad */
    int table;                      /* the table played, or the last one: 0 Red, 1 Blue */
    int haptic;                     /* feedback requested (UI_HAPTIC_*), strongest first */
    /* menu */
    bool menu_open;
    int menu_hot;                   /* item under the finger, -1 none */
    int menu_sel;                   /* item chosen with a gamepad / keyboard, -1 none */
    int pending_action;
    /* settings shown in the menu */
    bool vibration, sound;
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
int  ui_take_action(Ui *ui);
void ui_open_menu(Ui *ui, bool open);
void ui_toast(Ui *ui, const char *msg, double seconds);
/* build the display list; frame_w/h: size of the current game image (0: no game) */
void ui_build(Ui *ui, UiList *list, int frame_w, int frame_h);
/* what the screen shows (after ui_build) */
void ui_nd_state(const Ui *ui, NdState *st);
void ui_nd_prepare(Ui *ui, int frame_w, int frame_h, int scene);   /* lays the screen out for this image */
void ui_set_insets(Ui *ui, int top, int bottom, int left, int right, int corner);
UiRect ui_menu_item(const Ui *ui, int i);                 /* menu entry i (0..UI_MENU_ITEMS-1) */

#endif
