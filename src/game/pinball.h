/*
 * pinball.h - "Pokemon Pinball : table complete" runtime.
 *
 * Runs the US Pokemon Pinball ROM on the C core and replaces the game's stage
 * management with a single, unified field: the top and bottom halves of the Red and
 * Blue tables are loaded together, updated together every frame and displayed
 * together on one tall screen (192 x 280 pixels). See pinball.c for details.
 */
#ifndef PINBALL_H
#define PINBALL_H

#include "../core/gbc.h"

#define PB_PAGE_MAIN 0       /* bottom half, bonus stages, menus */
#define PB_PAGE_TOP  1       /* top half of the field            */

#define PB_FIELD_W   192                     /* the whole table, launch lane included */
#define PB_FIELD_W_NARROW 160                /* option: the original width, scrolling to the lane */
#define PB_TOP_ROWS  136                     /* top half: lines 0-135 of its page   */
#define PB_HUD_ROWS  10                      /* status bar, under the table          */
#define PB_FIELD_H   (PB_TOP_ROWS + 144 + PB_HUD_ROWS)
#define PB_STAGE_H   (144 + PB_HUD_ROWS)    /* a bonus stage, its status bar under it      */

/* what the game showed with a picture (pb_view): as pb_screen, pb_stage, pb_table, pb_in_game,
 * pb_playing at that time, and whether the screen was on */
typedef struct {
    int screen, stage, table;
    bool in_game, playing, lcd_on;
} PbView;

typedef struct {
    uint32_t magic;
    bool unified;            /* both halves loaded, unified field active        */
    uint8_t slot_page[256];  /* graphics queue entry -> video page              */
    int8_t forced[16];       /* page override stack (interrupts, queue entries) */
    int nforced;
    uint8_t other_oam[0xA0]; /* sprites of the half without the ball           */
    bool other_oam_valid;
    uint8_t palbuf[2][0x100];/* per-page copy of wPaletteData + fade buffers    */
    uint8_t watch_last[2][64];
    long frame;
    long last_refresh[2];
    bool redraw_pending[2];  /* page to redraw once the cooldown allows it (the ball left that half) */
    bool resolve_pending;     /* the ball half's object logic is running (see hk_resolve) */
    uint8_t resolve_stage;
    uint64_t resolve_frame;
    long stats_swaps, stats_refresh, stats_aborts, stats_frames_unified;
    long stats_buffers;      /* redraws whose queue buffers (billboard) had to be kept */
} PinballState;

typedef struct {
    GBC g;
    PinballState st;
    GBCState *snap_a, *snap_b, *snap_c;   /* scratch machine states (heap) */
    GBCState *snap_r;                    /* state before the ball half's object logic */
    char error[256];
    bool narrow;                         /* original width (see pb_set_narrow); not in snapshots */
    /* see pb_set_antilag; not in snapshots */
    bool antilag;
    uint16_t wait_sp;                    /* SP of the last wait for the next frame (0468) */
    int64_t *late_budget;                /* while a late frame is finished: its slice (hk_cry) */
    /* sound effects asked for by the other half's logic (played at the end of the frame) and
     * the last frame each effect was asked for by the ball's half; not in snapshots */
    int other_run;                       /* 1 + RUN_* while the other half runs, else 0 */
    uint16_t sfx_other[8];
    int sfx_other_n;
    long sfx_ball_frame[256];
    long stats_sfx_replayed;
    long stats_late, stats_late_done;    /* frames late at their end, finished out of time */
    /* the picture shown (see pb_set_hold); not in snapshots */
    bool hold;
    uint32_t *held;                      /* GBC_FB_H x GBC_FB_W */
    int held_w, held_h;
    bool held_uniform, held_pending;
    int held_lo;                         /* its darkest channel (how far it is faded to white) */
    int flash;                           /* frames into a flash of the game (0: none) */
    uint32_t held_seq;
    PbView view;
    /* the stage each list of sprites was made for (on_dma): the game's buffer (the ball's half,
     * hk_draw) and st.other_oam (run_other_half); 0xFF: not known. Not in snapshots */
    uint8_t oam_buf_stage, oam_other_stage;
    bool oam_drawing;                    /* the game is writing a new list into its buffer */
    long stats_stale_oam;                /* OAM DMAs that came with the lists of the other halves */
    long stats_dma_in_call;              /* OAM DMAs during a routine called by a hook (late frames) */
    /* the other half's watched variables at the previous frame (watch_moved); not in snapshots */
    uint8_t watch_prev[64];
    int watch_prev_page;                 /* the page they were read for, -1: none */
    /* tools only: called for each byte of game state merged from the other half's run */
    void (*merge_fn)(void *pb, uint16_t addr, uint8_t before, uint8_t after, int kind);
} Pinball;

/* returns 0 on success; otherwise pb->error explains (ROM not recognised...) */
int  pb_init(Pinball *pb, const uint8_t *rom, size_t size, uint32_t sample_rate);
void pb_free(Pinball *pb);
void pb_load_sram(Pinball *pb, const uint8_t *data, size_t size);
const uint8_t *pb_sram(Pinball *pb, size_t *size);
void pb_run_frame(Pinball *pb, uint8_t buttons);
const uint32_t *pb_frame(Pinball *pb, int *w, int *h, int *stride);   /* 0x00RRGGBB */
int  pb_audio(Pinball *pb, int16_t *out, int max_frames);            /* stereo s16 */
void pb_set_audio_rate(Pinball *pb, double sample_rate);             /* see gbc_set_audio_rate */
void pb_set_audio_highpass(Pinball *pb, double hz);                  /* see gbc_set_audio_highpass */
bool pb_rumble(Pinball *pb);
bool pb_unified(const Pinball *pb);
/* Width of the table: the whole table (192 pixels, default), or the original width (160
 * pixels): the launch lane on the right only comes on screen when the ball is launched, with
 * the original horizontal scrolling. Both halves stay on screen together either way. */
void pb_set_narrow(Pinball *pb, bool on);
bool pb_narrow(const Pinball *pb);
/* The Game Boy Color does not always have the time to do the game's work of a frame: after a
 * hit of the ball at speed (collisions, sounds, score, lights), 1 frame in 10 on the tables, the
 * game is still busy when the next frame comes, and skips it: the ball slows down for a moment.
 * With this option, such a late frame is finished out of time (the game's program goes on with
 * the time stopped until it waits for the next frame): the game never skips a frame. A frame
 * finished in time is not changed. The routines of the game called by the hooks (its sprites,
 * the flippers, a step of a fade, the capture animation) stop the time at the end of the frame
 * the same way (2.5: their VBlank came in the middle of the list of sprites); a copy to the video
 * memory waiting for the lines 64-127 (the letters of a message, the picture of a Pokemon caught)
 * is done at once there. Off by default (the original timing: the tools' fingerprints). */
void pb_set_antilag(Pinball *pb, bool on);
/* The game changes its palettes while a picture is drawn now and then (the start and the end of
 * the white flash after a ball is lost, some fades), and the other half's palettes are loaded
 * out of time at any line: the picture tore at that line, on both halves (a striped flash of the
 * whole screen for one frame). With this option, each picture keeps the colours of its first
 * line (gbc_set_frame_palettes). Off by default. */
void pb_set_frame_palettes(Pinball *pb, bool on);
/* The game turns the screen off to load a table, a new ball, a bonus stage: the frame buffer then
 * keeps an old picture, partly drawn over and at the size of the new screen, while the state of
 * the game (screen, stage) is already the next one. Its pictures are often cut to a single colour
 * just before (the white of a new ball). With this option (front-ends), pb_frame gives the last
 * picture the game drew whole, the screen on; a picture of a single colour that cuts a picture
 * of the game is only shown if the next one is one as well (the screen turned off after it: a
 * flash of the whole screen is not shown), and the game's flashes to white (whiter by more than
 * a quarter in one frame, its fades take 16 frames) are not shown either, for 45 frames at most:
 * the picture before stays until the game's picture is back. pb_view tells what the game showed
 * with that picture.
 * Off by default (pb_frame: the frame buffer, as the tools compare it). */
void pb_set_hold(Pinball *pb, bool on);
uint32_t pb_picture_seq(const Pinball *pb);                          /* changes with each picture */
const PbView *pb_view(const Pinball *pb);
int  pb_screen(const Pinball *pb);                                   /* current game screen */
bool pb_in_game(const Pinball *pb);                                  /* on the pinball screen (flippers) */
/* the table (or a bonus stage) is being played: not one of the in-game menus (pause menu,
 * choice of the Pokemon to evolve, end-of-ball bonus), which use the directional pad */
bool pb_playing(const Pinball *pb);
/* the table being played: 0 Red, 1 Blue, -1 none (title, menus, bonus stages) */
int  pb_table(const Pinball *pb);
/* the stage of the pinball screen (wCurrentStage: 0/1 Red, 4/5 Blue, 7 Gengar, 9 Mewtwo,
 * 11 Meowth, 13 Diglett, 15 Seel), -1 on the other screens */
int  pb_stage(const Pinball *pb);

/* The front-ends press the buttons of the game's default key configuration (OPTION > KEY
 * CONFIG). Once the game has loaded it (from the title screen on) and out of its options, a
 * different one (changed in the game, or kept by a cartridge save) is put back: in memory at
 * once, and the copy of the cartridge save is made invalid, so that the game writes its own
 * defaults when it starts again. Returns 0: nothing to do; 1: fixed during a game (it goes on);
 * 2: fixed out of a game (the front-end should save the cartridge and restart the game). */
int  pb_fix_key_config(Pinball *pb);

/* whole-machine snapshots (to resume after the app is suspended) */
size_t pb_snapshot_size(void);
void   pb_snapshot_save(const Pinball *pb, void *dst);
int    pb_snapshot_load(Pinball *pb, const void *src, size_t size);

/* utility */
void pb_sha1_hex(const uint8_t *data, size_t len, char out[41]);

#endif
