/*
 * app.h - logic of the mobile version, independent of the platform: the ROM (import,
 * storage), save data, suspend/resume, quick saves, settings, the in-app menu, the
 * audio ring buffer. The Android glue (and the Linux test tool) drive it.
 */
#ifndef PB_APP_H
#define PB_APP_H

#include "ui.h"
#include "screen.h"
#include "../../src/game/pinball.h"
#include <stdatomic.h>

#define APP_RING 32768              /* audio ring, stereo frames (power of two; room for the peaks of a
                                     * card that takes its samples late, Bluetooth: see pacing.h) */

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
    bool gen;                       /* the game played: Pokemon Pinball Generations (else the original) */
    bool installed[2];              /* the ROMs installed: the original, Generations */
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
    _Atomic uint32_t ring_drop;     /* frames for the audio thread to skip (app_audio_drop) */
    bool rumble;                    /* rumble motor state, for the platform */
    bool vibration_test;            /* VIBRATION turned on: the platform makes a pulse */
    bool quit;                      /* the player chose "QUIT" */
    bool sound_changed;             /* the platform must open/close its audio stream */
    NdScreen scr;                   /* the whole screen, one picture (screen.h) */
    uint32_t frame_seq;
    /* files written by the writer thread of the platform: io_async set, io_wake wakes it */
    AppWrite io[2];
    bool io_async;
    void (*io_wake)(void);
    int test_bonus;                 /* test builds: bonus stage asked for (app_test_command) */
} MobileApp;

int  app_init(MobileApp *a, const char *dir, uint32_t sample_rate);
void app_free(MobileApp *a);
/* a ROM opened with the app: the US Pokemon Pinball, Pokemon Pinball Generations 1.6, or the IPS patch
 * of Generations (applied to the US ROM installed) */
bool app_import_rom(MobileApp *a, const uint8_t *data, size_t size);
/* the game of this ROM (or of this patch of Generations) is installed already */
bool app_has_rom(const MobileApp *a, const uint8_t *data, size_t size);
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
void app_audio_drop(MobileApp *a, uint32_t frames);           /* the oldest frames waiting skipped */
void app_set_audio_rate(MobileApp *a, double rate);           /* see pb_set_audio_rate */
void app_io_run(MobileApp *a);                                /* the writer thread: the files waiting */
void app_io_wait(MobileApp *a);                               /* until they are written (before a save) */
int  app_audio_pull(MobileApp *a, int16_t *out, int frames);   /* audio thread */
void app_build(MobileApp *a, UiList *list);
/* the picture to show: the whole screen, in the pixels of the game (design.h) */
const uint32_t *app_frame(MobileApp *a, int *w, int *h, int *stride);
/* the game's picture alone (screen_game): the dual-screen devices */
const uint32_t *app_game(MobileApp *a, int *w, int *h, int *stride);
#ifdef PNS_TEST
/* test builds only (the APK for the Android emulator of the PC, tools/emu.sh): "bonus N" sends
 * the ball to the bonus stage N the next time it is on a table, as the slot's reward */
void app_test_command(MobileApp *a, const char *cmd);
#endif

#endif
