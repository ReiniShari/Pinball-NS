/*
 * screen.h - the whole screen of the touch interface as one picture in the pixels of the game
 * (design.h): the game's picture as shown (its 30 Hz flicker mixed), what continues it around it,
 * made once per picture, and the controls over it. Shared by the mobile app (app.c) and the handheld
 * mode of the desktop versions (platform/desktop), which drive the same Ui (ui.h).
 */
#ifndef PB_SCREEN_H
#define PB_SCREEN_H

#include "ui.h"
#include "../../src/game/pinball.h"
#include "../../src/front/deflicker.h"

typedef struct {
    uint32_t *canvas;               /* the picture of the whole screen (ND_MAX_W x ND_MAX_H) */
    /* the game's picture as shown: its 30 Hz flicker mixed (deflicker.h), made again only when
     * the game has made a new frame */
    Deflicker defl;
    const uint32_t *shown;
    int shown_w, shown_h;
    /* what comes with each picture of the game (pb_set_hold): made just after it, while the game's
     * state is that of the picture (nd_render_game), kept while the game's screen is off */
    uint32_t pic_seq;               /* pb_picture_seq of the picture in bg */
    uint32_t *bg;                   /* the canvas without the controls (ND_MAX_W x ND_MAX_H) */
    int bg_fade[2];
    bool bg_ok;
    NdLayout bg_layout;             /* the layout it was made for */
    bool disp_in_game, disp_field;  /* the controls of that picture (ui_nd_state) */
    int disp_table;
    bool no_deflicker;              /* tools: the game's picture as it is (comparisons) */
} NdScreen;

bool screen_init(NdScreen *s);
void screen_free(NdScreen *s);
/* a new game: nothing of the old one's pictures (table: the last one played, for its colours) */
void screen_reset(NdScreen *s, int table);
/* what the game is showing, for the interface (ui->in_game, field, table) */
void screen_context(NdScreen *s, const Pinball *pb, Ui *ui);
/* after each frame of the game: a new picture comes with what continues it, made now */
void screen_new_picture(NdScreen *s, Pinball *pb, Ui *ui);
/* the display list of the interface for the picture shown */
void screen_build(NdScreen *s, Pinball *pb, Ui *ui, UiList *l);
/* the picture to show: the whole screen, in the pixels of the game (the game's own picture before
 * the interface knows its screen) */
const uint32_t *screen_frame(NdScreen *s, Pinball *pb, Ui *ui, int *w, int *h, int *stride);
/* the game's picture alone, as shown (its 30 Hz flicker mixed), without what continues it nor the
 * controls: the dual-screen devices, which show its parts on two screens (NULL: no game) */
const uint32_t *screen_game(NdScreen *s, Pinball *pb, Ui *ui, int *w, int *h, int *stride);

#endif
