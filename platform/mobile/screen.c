/*
 * screen.c - the whole screen of the touch interface as one picture (see screen.h).
 */
#include "screen.h"
#include <stdlib.h>
#include <string.h>

bool screen_init(NdScreen *s)
{
    memset(s, 0, sizeof *s);
    s->canvas = (uint32_t *)calloc((size_t)ND_MAX_W * ND_MAX_H, sizeof(uint32_t));
    s->bg = (uint32_t *)calloc((size_t)ND_MAX_W * ND_MAX_H, sizeof(uint32_t));
    return s->canvas && s->bg;
}

void screen_free(NdScreen *s)
{
    free(s->canvas);
    free(s->bg);
    s->bg = NULL;
    s->canvas = NULL;
    deflicker_free(&s->defl);
    s->shown = NULL;
}

void screen_reset(NdScreen *s, int table)
{
    s->pic_seq = 0;
    s->bg_ok = false;
    s->shown = NULL;                            /* the old game's picture: not this one's size */
    s->disp_table = table;
}

/* what the game shows: the field controls, the table played */
void screen_context(NdScreen *s, const Pinball *pb, Ui *ui)
{
    (void)s;
    if (!pb) return;
    ui->in_game = pb_in_game(pb);
    ui->field = pb_playing(pb);
    int t = pb_table(pb);
    if (t >= 0 && t != ui->table) ui->table = t;     /* kept for its bonus stages */
}

/* the game's picture as shown: the held one (pb_set_hold), its 30 Hz flicker mixed */
static const uint32_t *game_picture(NdScreen *s, Pinball *pb, int *w, int *h, int *stride)
{
    const uint32_t *px = pb_frame(pb, w, h, stride);
    if (s->shown && !s->no_deflicker && *w == s->shown_w && *h == s->shown_h) { px = s->shown; *stride = *w; }
    return px;
}

static bool same_layout(const NdLayout *x, const NdLayout *y)
{
    return x->sw == y->sw && x->sh == y->sh && x->cw == y->cw && x->ch == y->ch && x->gx == y->gx && x->gy == y->gy &&
           x->gw == y->gw && x->gh == y->gh && x->scene == y->scene && x->corner == y->corner && x->bottom == y->bottom &&
           x->tee == y->tee && x->hidden == y->hidden;
}

/* what comes with the picture: its layout, what continues it, the colours of its controls */
static void compose_game(NdScreen *s, Pinball *pb, Ui *ui)
{
    int w, h, stride;
    const uint32_t *px = game_picture(s, pb, &w, &h, &stride);
    const PbView *v = pb_view(pb);
    s->disp_in_game = v->in_game;
    s->disp_field = v->playing;
    if (v->table >= 0) s->disp_table = v->table;          /* kept for its bonus stages */
    if (!s->canvas || !s->bg || ui->no_rom) return;
    ui_nd_prepare(ui, w, h, nd_scene(pb, h), v->in_game);
    nd_render_game(&ui->nd, pb, px, stride, s->bg, s->bg_fade);
    s->bg_layout = ui->nd;
    s->bg_ok = true;
}

/* after each frame of the game: a new picture comes with what continues it, made now (the state
 * of the game is the one of the picture: its video memory for the stages); the screen off, the
 * last picture and its parts stay as they were */
void screen_new_picture(NdScreen *s, Pinball *pb, Ui *ui)
{
    uint32_t seq = pb_picture_seq(pb);
    if (seq == s->pic_seq && s->shown) return;
    s->pic_seq = seq;
    int w, h, stride;
    const uint32_t *px = pb_frame(pb, &w, &h, &stride);
    s->shown = deflicker_frame(&s->defl, px, w, h, stride);
    s->shown_w = w;
    s->shown_h = h;
    compose_game(s, pb, ui);
}

void screen_build(NdScreen *s, Pinball *pb, Ui *ui, UiList *l)
{
    int w = 0, h = 0, stride;
    if (pb) {
        pb_frame(pb, &w, &h, &stride);
        screen_context(s, pb, ui);
        ui->scene = nd_scene(pb, h);
        ui->tee = pb_view(pb)->in_game;
    }
    ui_build(ui, l, w, h);
}

const uint32_t *screen_frame(NdScreen *s, Pinball *pb, Ui *ui, int *w, int *h, int *stride)
{
    if (!pb) { *w = *h = 0; *stride = 0; return NULL; }
    if (!s->shown) screen_new_picture(s, pb, ui);
    const uint32_t *px = game_picture(s, pb, w, h, stride);
    if (!s->canvas || !s->bg || ui->no_rom) return px;
    /* the whole screen, one picture in the pixels of the game */
    ui_nd_prepare(ui, *w, *h, nd_scene(pb, *h), pb_view(pb)->in_game);
    if (!s->bg_ok || !same_layout(&s->bg_layout, &ui->nd)) compose_game(s, pb, ui);   /* new screen size */
    NdState st;
    ui_nd_state(ui, &st);
    /* the controls of the picture shown (a loading behind it: those of the next screen later) */
    st.set = !s->disp_in_game ? ND_SET_GREY : nd_set_of_table(s->disp_table);
    st.letters = !s->disp_field;
    nd_render_controls(&ui->nd, &st, s->bg, s->bg_fade, s->canvas);
    *w = ui->nd.cw;
    *h = ui->nd.ch;
    *stride = ui->nd.cw;
    return s->canvas;
}

const uint32_t *screen_game(NdScreen *s, Pinball *pb, Ui *ui, int *w, int *h, int *stride)
{
    if (!pb) { *w = *h = 0; *stride = 0; return NULL; }
    if (!s->shown) screen_new_picture(s, pb, ui);
    return game_picture(s, pb, w, h, stride);
}
