/*
 * desk.h - what the desktop versions of Pinball NS share (Windows, Linux, macOS): the game and its
 * ROM, its saves, the settings and the controls (pinball_ns.cfg: keys and gamepad inputs for each
 * Game Boy button, as the Windows version has kept them since 1.7), the picture shown and the
 * function keys. The platform files open the window, the sound card and the gamepads, give the keys,
 * the mouse or the touches, and show the picture.
 *
 * Two displays:
 *   - the table alone (the Windows version since 1.3), as large as the window allows, whole zooms
 *     when that wastes little room (or smooth, F10); F8 the table at its original width;
 *   - the handheld mode (2.9, F3): the screen of the Android version (platform/mobile: the table at the
 *     top, its touch keys below, the menu), for the computers held in the hands with a touch screen
 *     (or played with the mouse); its keys can be hidden (F4).
 * Both: F6 screen filter, F7 colours (src/front/screenfx.h), F5 / F9 save / load the state, F11 full
 * screen, P pause, F1 about, F2 the controls. Linux and macOS draw the pages of F1 and F2 and the
 * messages in the picture (the Windows version has its own windows for them).
 */
#ifndef PB_DESK_H
#define PB_DESK_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include "../../src/game/pinball.h"
#include "../../src/front/screenfx.h"
#include "../../src/front/deflicker.h"
#include "../mobile/screen.h"

#define DESK_VERSION "2.9"
#define DESK_RATE    48000                   /* the sound's rate */
#define DESK_PATH    1024

/* the Game Boy buttons, by what they do in the game (its default key configuration, kept by
 * pb_fix_key_config), each with up to DESK_MAXB keys and DESK_MAXB gamepad inputs */
enum { ACT_LEFT, ACT_A, ACT_DOWN, ACT_B, ACT_SELECT, ACT_START, ACT_UP, ACT_RIGHT, ACT_N };
#define DESK_MAXB 4
extern const uint8_t desk_act_button[ACT_N];
extern const char *const desk_act_name[ACT_N];   /* what it does */
extern const char *const desk_act_gb[ACT_N];     /* the Game Boy button */

/* keys: the virtual-key codes of Windows, on every platform (the others translate theirs; the
 * settings files stay the same) */
enum {
    DK_BACK = 0x08, DK_TAB = 0x09, DK_RETURN = 0x0D, DK_SHIFT = 0x10, DK_CONTROL = 0x11, DK_ALT = 0x12, DK_PAUSE = 0x13,
    DK_CAPS = 0x14, DK_ESCAPE = 0x1B, DK_SPACE = 0x20, DK_PGUP = 0x21, DK_PGDN = 0x22, DK_END = 0x23, DK_HOME = 0x24,
    DK_LEFT = 0x25, DK_UP = 0x26, DK_RIGHT = 0x27, DK_DOWN = 0x28, DK_INSERT = 0x2D, DK_DELETE = 0x2E,
    DK_LWIN = 0x5B, DK_RWIN = 0x5C, DK_APPS = 0x5D, DK_NUM0 = 0x60, DK_NUM9 = 0x69, DK_MULTIPLY = 0x6A, DK_ADD = 0x6B,
    DK_SUBTRACT = 0x6D, DK_DECIMAL = 0x6E, DK_DIVIDE = 0x6F, DK_F1 = 0x70, DK_F24 = 0x87, DK_LSHIFT = 0xA0,
    DK_RSHIFT = 0xA1, DK_LCONTROL = 0xA2, DK_RCONTROL = 0xA3, DK_LALT = 0xA4, DK_RALT = 0xA5, DK_SEMICOLON = 0xBA,
    DK_EQUALS = 0xBB, DK_COMMA = 0xBC, DK_MINUS = 0xBD, DK_PERIOD = 0xBE, DK_SLASH = 0xBF, DK_GRAVE = 0xC0,
    DK_LBRACKET = 0xDB, DK_BACKSLASH = 0xDC, DK_RBRACKET = 0xDD, DK_QUOTE = 0xDE
};
#define DK_F(n) (DK_F1 + (n) - 1)

/* gamepad inputs: those of an Xbox gamepad (the buttons of XInput by their bit, its triggers, its left
 * stick): every gamepad is read into this layout by the platform (its south button is A, its west one
 * X, its shoulders LB / RB...) */
enum {
    PAD_DUP, PAD_DDOWN, PAD_DLEFT, PAD_DRIGHT, PAD_START, PAD_BACK, PAD_LTHUMB, PAD_RTHUMB, PAD_LB, PAD_RB, PAD_GUIDE,
    PAD_MISC, PAD_A, PAD_B, PAD_X, PAD_Y, PAD_LT, PAD_RT, PAD_LS_LEFT, PAD_LS_RIGHT, PAD_LS_UP, PAD_LS_DOWN, PAD_N
};
extern const char *const desk_pad_name[PAD_N];

/* what a key asks of the platform (desk_key) */
enum {
    DESK_NONE = 0, DESK_REDRAW, DESK_FULLSCREEN, DESK_LEAVE_FULLSCREEN, DESK_ABOUT, DESK_CONTROLS, DESK_RESHAPE,
    DESK_QUIT, DESK_PAUSE
};

/* the pages drawn in the picture (Linux, macOS) */
enum { PAGE_NONE = 0, PAGE_ABOUT, PAGE_CONTROLS };

typedef struct {
    const uint32_t *px;         /* the picture (0x00RRGGBB) */
    int w, h, stride;
    int x, y, dw, dh;           /* where it goes in the window, at that size */
    bool smooth;                /* scaled smoothly (else the nearest pixel) */
} DeskPicture;

typedef struct {
    /* the game */
    Pinball *pb;
    uint8_t *rom;
    size_t rom_size;
    char rom_path[DESK_PATH], sav_path[DESK_PATH], state_path[DESK_PATH];
    char rom_paths[2][DESK_PATH];           /* the last ROM of each game (original, Generations) */
    char cfg_path[DESK_PATH];
    uint8_t sav_last[0x8000];
    size_t sav_last_size;
    double next_sav_check;
    /* settings (pinball_ns.cfg) */
    bool narrow, smooth, handheld, paused, sound, vibration;
    bool quit;                              /* QUIT chosen in the menu of the handheld mode */
    int filter, colors;                     /* FX_FILTER_*, FX_COLORS_* */
    uint16_t keymap[ACT_N][DESK_MAXB];      /* keys (DK_*), 0: none */
    uint8_t padmap[ACT_N][DESK_MAXB];       /* gamepad inputs + 1, 0: none */
    /* input */
    uint8_t key_down[256];
    long pad_in;                            /* gamepad inputs held (bit: PAD_*), -1: no gamepad */
    uint8_t kb_buttons, pad_buttons;
    /* the platform draws its own windows for the pages and the messages (Windows) */
    bool own_pages;
    int page;                               /* PAGE_* shown in the picture */
    int ctl_row, ctl_col;                   /* the controls page: the cell chosen; waiting for an input */
    bool ctl_wait;
    long ctl_pad_held;
    char ctl_msg[160];
    /* messages */
    char osd[160];
    double osd_until, now;
    /* the picture */
    Deflicker defl;
    uint32_t shown_seq;
    const uint32_t *shown;
    ScreenFx fx;
    void (*fx_run)(ScreenFx *fx);           /* the platform's way to make it (threads), NULL: at once */
    uint32_t *text_buf;                     /* the picture with its text (twice as large) */
    size_t text_cap;
    /* handheld mode: the interface of the Android version */
    Ui ui;
    NdScreen scr;
    UiList list;
    int win_w, win_h;
} Desk;

/* The settings in `cfg_path` (UTF-8 paths everywhere). */
void desk_init(Desk *d, const char *cfg_path);
void desk_free(Desk *d);
void desk_cfg_save(Desk *d);
void desk_map_defaults(Desk *d);
bool desk_key_reserved(unsigned vk);         /* kept by the program: F1 to F11, P, Pause, Esc */
/* a ROM: the game restarts with it (its cartridge save and state next to it); false, with err */
bool desk_open_rom(Desk *d, const char *path, char *err, size_t errn);
void desk_state_save(Desk *d);
void desk_state_load(Desk *d);
/* the cartridge save if it changed (force: in any case); later: by the writer thread */
void desk_sram_flush(Desk *d, bool force, bool later);
void desk_osd(Desk *d, const char *msg);

/* input: a key pressed or released (DK_*; repeat: an auto-repeat), the gamepad's inputs (-1: none),
 * the mouse or a finger (handheld mode; UI_DOWN, UI_MOVE, UI_UP, UI_CANCEL; window pixels) */
int  desk_key(Desk *d, unsigned vk, bool down, bool repeat);
void desk_pad(Desk *d, long inputs);
void desk_pointer(Desk *d, int action, int id, float x, float y);
uint8_t desk_buttons(Desk *d);               /* the Game Boy buttons held */
void desk_keys_released(Desk *d);            /* the window lost the keyboard */

/* one frame of the game (its sound: pb_audio), then rumble (desk_rumble); nothing while the game
 * waits (paused, a page, the menu of the handheld mode) */
void desk_frame(Desk *d);
bool desk_rumble(const Desk *d);
/* every refresh: the menu of the handheld mode, the periodic saves, the messages; true when the
 * picture changed without a frame (redraw) */
bool desk_tick(Desk *d, double now);
/* the picture for a window of win_w x win_h pixels */
void desk_picture(Desk *d, int win_w, int win_h, DeskPicture *p);
/* the picture scaled to the window (platforms without a scaler: X11), nearest pixel, black around */
void desk_blit(const DeskPicture *p, uint32_t *dst, int win_w, int win_h, int dst_stride);
/* a window shape for the display (zoom: as large as fits 90 % of the screen) */
void desk_window_size(const Desk *d, int screen_w, int screen_h, int *w, int *h);

/* UTF-8 files */
FILE *desk_fopen(const char *path, const char *mode);
bool desk_read(const char *path, uint8_t **data, size_t *size, size_t max);
bool desk_write(const char *path, const void *data, size_t size);   /* through a temporary file */

#endif
