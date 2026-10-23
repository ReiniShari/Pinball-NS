/*
 * app.h - logic of the mobile version, independent of the platform: the ROM (import,
 * storage), save data, suspend/resume, quick saves, settings, the in-app menu, the
 * audio ring buffer. The Android glue (and the Linux test tool) drive it.
 */
#ifndef PB_APP_H
#define PB_APP_H

#include "ui.h"
#include "../../src/game/pinball.h"
#include "../../src/front/deflicker.h"
#include <stdatomic.h>

#define APP_RING 16384              /* audio ring, stereo frames (power of two) */

/* A file to write, handed to the writer thread of the platform (app_io_run): the storage can
 * take tens of milliseconds (fsync), which the game thread must never wait for. */
typedef struct {
    _Atomic int state;              /* 0: free, 1: waiting for the writer */
    bool failed;                    /* the last write failed (it is done again) */
    char path[600];
    size_t size;
    uint8_t data[0x8000];
} AppWrite;

typedef struct {
    Pinball *pb;                    /* NULL until a valid ROM is known */
    uint8_t *rom;
    size_t rom_size;
    Ui ui;
    char dir[512];                  /* private storage of the app */
    uint32_t rate;
    double now;
    uint8_t sav_last[0x8000];
    size_t sav_last_size;
    double next_sav_check;
    /* audio: produced by app_run_frame, consumed by the audio thread. ring_w is only written
     * by the game thread, ring_r only by the audio thread; the game thread asks for the
     * waiting samples to be dropped (new game) with ring_flush. */
    int16_t ring[APP_RING * 2];
    _Atomic uint32_t ring_w, ring_r;
    atomic_bool ring_flush;
    bool rumble;                    /* rumble motor state, for the platform */
    bool quit;                      /* the player chose "QUIT" */
    bool sound_changed;             /* the platform must open/close its audio stream */
    uint32_t *canvas;               /* the picture of the whole screen (ND_MAX_W x ND_MAX_H) */
    /* the game's picture as shown: its 30 Hz flicker mixed (deflicker.h), made again only when
     * the game has made a new frame */
    Deflicker defl;
    uint32_t frame_seq;
    const uint32_t *shown;
    int shown_w, shown_h;
    /* what comes with each picture of the game (pb_set_hold): made just after it, while the game's
     * state is that of the picture (nd_render_game), kept while the game's screen is off */
    uint32_t pic_seq;                   /* pb_picture_seq of the picture in bg */
    uint32_t *bg;                       /* the canvas without the controls (ND_MAX_W x ND_MAX_H) */
    int bg_fade[2];
    bool bg_ok;
    NdLayout bg_layout;                 /* the layout it was made for */
    bool disp_in_game, disp_field;      /* the controls of that picture (ui_nd_state) */
    int disp_table;
    /* files written by the writer thread of the platform: io_async set, io_wake wakes it */
    AppWrite io[2];
    bool io_async;
    bool no_deflicker;              /* tools: the game's picture as it is (comparisons) */
    void (*io_wake)(void);
    int test_bonus;                 /* test builds: bonus stage asked for (app_test_command) */
} MobileApp;

int  app_init(MobileApp *a, const char *dir, uint32_t sample_rate);
void app_free(MobileApp *a);
bool app_import_rom(MobileApp *a, const uint8_t *data, size_t size);
bool app_has_game(const MobileApp *a);
bool app_running(const MobileApp *a);           /* game loaded and not in the menu */
void app_layout(MobileApp *a, int width, int height);
void app_touch(MobileApp *a, int action, int id, float x, float y);
void app_set_pad(MobileApp *a, uint8_t buttons);
void app_back(MobileApp *a);                    /* back key: opens / closes the menu */
void app_run_frame(MobileApp *a);
void app_update(MobileApp *a, double now);      /* menu actions, periodic saves */
void app_suspend(MobileApp *a);                 /* going to background: save everything */
int  app_take_haptic(MobileApp *a);             /* feedback requested by the UI (UI_HAPTIC_*) */
/* screen under the system (camera cut-out), radius of the rounded corners of the screen */
void app_set_insets(MobileApp *a, int top, int bottom, int left, int right, int corner);
uint32_t app_audio_queued(MobileApp *a);
void app_audio_pad(MobileApp *a, uint32_t level);             /* silence up to `level` waiting frames */
void app_set_audio_rate(MobileApp *a, double rate);           /* see pb_set_audio_rate */
void app_io_run(MobileApp *a);                                /* the writer thread: the files waiting */
void app_io_wait(MobileApp *a);                               /* until they are written (before a save) */
int  app_audio_pull(MobileApp *a, int16_t *out, int frames);   /* audio thread */
void app_build(MobileApp *a, UiList *list);
/* the picture to show: the whole screen, in the pixels of the game (design.h) */
const uint32_t *app_frame(MobileApp *a, int *w, int *h, int *stride);
#ifdef PNS_TEST
/* test builds only (the APK for the Android emulator of the PC, tools/emu.sh): "bonus N" sends
 * the ball to the bonus stage N the next time it is on a table, as the slot's reward */
void app_test_command(MobileApp *a, const char *cmd);
#endif

#endif
