/*
 * pinball.c - the unified field for "Pokemon Pinball : table complete".
 *
 * In the original game, each table (Red, Blue) is made of two separate stages,
 * STAGE_x_FIELD_TOP and STAGE_x_FIELD_BOTTOM. Only one is loaded at a time; when the
 * ball crosses the middle of the table the game turns the screen off, reloads the
 * graphics and collision data of the other stage, and carries on. The half without
 * the ball does not exist while the ball is away.
 *
 * This file rewrites that stage management so that a table is one field:
 *
 *   - both halves are loaded together, each in its own video page (the runtime gives
 *     the virtual Game Boy one video memory per half), and displayed together on a
 *     192 x 280 screen: no scrolling, no screen switch;
 *   - every frame, the objects of BOTH halves are updated (animations, lights, timers)
 *     and drawn, the half without the ball included;
 *   - the ball moves between the halves without blanking the screen: the field switches the
 *     collision data the physics uses (the original physics and collision maps are kept
 *     exactly, so the table plays like the original) and reloads the half into its own
 *     page as the original did (see load_half);
 *   - the ball is drawn on both halves where they overlap, the flippers move even when
 *     the ball is at the top, fades apply to the whole table, the catch/evolution timer
 *     is shown once at the top of the table and the status bar under it.
 *
 * How the half without the ball is updated: the game's own per-half routines are run
 * for it, in its own context (stage, video page, ball position in its coordinates),
 * "out of time" (the virtual hardware does not advance while they run), starting from
 * the same game state as the ball's half. Their effects are merged back into the game
 * state, except where the ball's half already changed the same data this frame (state
 * shared by both halves, like timers and counters, must only advance once) and except
 * for the ball itself, which belongs to the physics of its half.
 *
 * Everything here is driven through hooks on the original routines (addresses of the
 * US ROM, see pinball_us.h); the ROM itself is never modified.
 */
#include "pinball.h"
#include "pinball_us.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stddef.h>

#define PB_MAGIC 0x50424C31u   /* "PBL1" */
#define BUDGET   4000000L      /* safety limit for out-of-time calls (instructions) */
#define REFRESH_COOLDOWN 20

#define W(a) (pb->g.s.wram[(a) - 0xC000])   /* WRAM C000-DFFF (bank 1 at D000) */
#define H(a) (pb->g.s.hram[(a) - 0xFF80])

/* WRAM classes for merging the other half's work back into the game state */
enum { M_SHARED = 0, M_LOCAL = 1, M_BALL = 2 };
static uint8_t wclass[0x2000];
static bool wclass_ready;

/* 16 bytes equal: one comparison of 16 bytes (SSE2 on x86-64, NEON on ARM64) */
#if defined(_M_X64) || defined(__x86_64__) || defined(__SSE2__)
#include <emmintrin.h>
static inline bool same16(const uint8_t *a, const uint8_t *b)
{
    __m128i x = _mm_loadu_si128((const __m128i *)a), y = _mm_loadu_si128((const __m128i *)b);
    return _mm_movemask_epi8(_mm_cmpeq_epi8(x, y)) == 0xFFFF;
}
#elif defined(__aarch64__)
#include <arm_neon.h>
static inline bool same16(const uint8_t *a, const uint8_t *b)
{
    return vmaxvq_u8(veorq_u8(vld1q_u8(a), vld1q_u8(b))) == 0;
}
#else
static inline bool same16(const uint8_t *a, const uint8_t *b) { return memcmp(a, b, 16) == 0; }
#endif

/* A row of n pixels (0x00RRGGBB): *mins keeps the smallest value of each channel (as bytes of
 * a pixel), *diff the bits that differ from c0 somewhere. 4 pixels at a time (SSE2, NEON): the
 * picture of each frame is looked at whole (hold_picture: 15 % of the frame's time before 2.5). */
static inline void row_stats(const uint32_t *p, int n, uint32_t c0, uint32_t *mins, uint32_t *diff)
{
    int x = 0;
    uint32_t m = *mins, d = *diff;
#if defined(_M_X64) || defined(__x86_64__) || defined(__SSE2__)
    __m128i vm = _mm_set1_epi32((int)m), vd = _mm_setzero_si128(), vc = _mm_set1_epi32((int)c0);
    for (; x + 4 <= n; x += 4) {
        __m128i v = _mm_loadu_si128((const __m128i *)(p + x));
        vm = _mm_min_epu8(vm, v);
        vd = _mm_or_si128(vd, _mm_xor_si128(v, vc));
    }
    uint32_t t[4];
    _mm_storeu_si128((__m128i *)t, vm);
    for (int i = 0; i < 4; i++)
        for (int k = 0; k < 24; k += 8) if (((t[i] >> k) & 255) < ((m >> k) & 255)) m = (m & ~(255u << k)) | (t[i] & (255u << k));
    _mm_storeu_si128((__m128i *)t, vd);
    d |= t[0] | t[1] | t[2] | t[3];
#elif defined(__aarch64__)
    uint8x16_t vm = vreinterpretq_u8_u32(vdupq_n_u32(m));
    uint32x4_t vd = vdupq_n_u32(0), vc = vdupq_n_u32(c0);
    for (; x + 4 <= n; x += 4) {
        uint32x4_t v = vld1q_u32(p + x);
        vm = vminq_u8(vm, vreinterpretq_u8_u32(v));
        vd = vorrq_u32(vd, veorq_u32(v, vc));
    }
    uint32_t t[4];
    vst1q_u32(t, vreinterpretq_u32_u8(vm));
    for (int i = 0; i < 4; i++)
        for (int k = 0; k < 24; k += 8) if (((t[i] >> k) & 255) < ((m >> k) & 255)) m = (m & ~(255u << k)) | (t[i] & (255u << k));
    vst1q_u32(t, vd);
    d |= t[0] | t[1] | t[2] | t[3];
#endif
    for (; x < n; x++) {
        uint32_t v = p[x];
        for (int k = 0; k < 24; k += 8) if (((v >> k) & 255) < ((m >> k) & 255)) m = (m & ~(255u << k)) | (v & (255u << k));
        d |= v ^ c0;
    }
    *mins = m;
    *diff = d;
}

/* A copy of the machine state, but for the samples waiting in the sound ring (64 KB, 40 % of
 * the state): the copies kept here (out-of-time calls, the merge of the halves, a failed call)
 * are put back before any sound is pulled, and no sound is made while they are kept, so the
 * ring is the same in both (its read and write positions are copied). */
static void copy_range(GBCState *dst, const GBCState *src, size_t a, size_t b)
{
    if (b > a) memcpy((uint8_t *)dst + a, (const uint8_t *)src + a, b - a);
}

/* (pages false: but the video pages.) The cartridge RAM beyond its size (sram_size of 32 KB,
 * 8 KB for this game) is not copied either: nothing writes it (gbc_write masks the address,
 * gbc_load_sram stops at the size), it stays as gbc_init left it in the machine. */
static void state_copy_ex(GBCState *dst, const GBCState *src, bool pages)
{
    size_t ring = offsetof(GBCState, apu) + offsetof(GBCApu, ring), ring_end = ring + sizeof src->apu.ring;
    size_t sram = offsetof(GBCState, sram), used = src->sram_size <= sizeof src->sram ? src->sram_size : sizeof src->sram;
    size_t page = offsetof(GBCState, page), page_end = page + sizeof src->page;
    copy_range(dst, src, 0, sram + used);
    if (pages) {
        copy_range(dst, src, sram + sizeof src->sram, ring);
    } else {
        copy_range(dst, src, sram + sizeof src->sram, page);
        copy_range(dst, src, page_end, ring);
    }
    copy_range(dst, src, ring_end, sizeof(GBCState));
}

static void state_copy(GBCState *dst, const GBCState *src) { state_copy_ex(dst, src, true); }


static const uint8_t STAGE_UP[16]   = { 0xFF, 0, 0xFF, 2, 0xFF, 4, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF };
static const uint8_t STAGE_DOWN[16] = { 1, 0xFF, 3, 0xFF, 5, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF };

/* Game state the graphics of a half depend on and that events in the other half can
 * change (from the _LoadStageData* loaders). When the ball's half changes one of these,
 * the other half redraws its state-dependent graphics, as the game does on entering it. */
static const uint16_t WATCH_TOP[] = {
    W_BallType, W_StageCollisionState, W_StaryuState, W_InSpecialMode, W_SpecialModeState,
    W_SpecialMode, W_EvolutionObjectsDisabled, W_NumEvolutionTrinkets, W_SlotIsOpen,
    W_OpenedSlotBy4CAVELights, W_OpenedSlotBy3Pokeballs, W_PikachuSaverCharge,
    W_BallUpgradeTriggerStates, W_BallUpgradeTriggerStates + 1, W_BallUpgradeTriggerStates + 2,
    W_NumBellsproutEntries, W_BlueForceFieldDirection, W_RedStageStructureBackup,
};
static const uint16_t WATCH_BOTTOM[] = {
    W_BallType, W_StageCollisionState, W_StaryuState, W_InSpecialMode, W_SpecialModeState,
    W_SpecialMode, W_EvolutionObjectsDisabled, W_NumEvolutionTrinkets, W_SlotIsOpen,
    W_OpenedSlotBy4CAVELights, W_OpenedSlotBy3Pokeballs, W_NextBonusStage, W_ExtraBalls,
    W_LeftMapMoveCounter, W_RightMapMoveCounter,
    W_IndicatorStates + 0, W_IndicatorStates + 1, W_IndicatorStates + 2, W_IndicatorStates + 3,
    W_IndicatorStates + 4, W_IndicatorStates + 5, W_IndicatorStates + 6, W_IndicatorStates + 7,
    W_IndicatorStates + 8, W_IndicatorStates + 9, W_IndicatorStates + 10, W_IndicatorStates + 11,
    W_IndicatorStates + 12, W_IndicatorStates + 13, W_IndicatorStates + 14, W_IndicatorStates + 15,
    W_IndicatorStates + 16, W_IndicatorStates + 17, W_IndicatorStates + 18,
    W_CurrentMap, W_MapMoveDirection, W_RareMonsFlag, W_NumMonHits, W_CapturingMon,
    W_BonusMultiplierTens, W_BonusMultiplierOnes, W_BlueForceFieldDirection,
};
#define NWATCH_TOP    (int)(sizeof WATCH_TOP / sizeof WATCH_TOP[0])
#define NWATCH_BOTTOM (int)(sizeof WATCH_BOTTOM / sizeof WATCH_BOTTOM[0])

/* What the ball touched this frame, found by the collision checks of the ball's half (in its
 * coordinates, with its own lists of objects) and read by the object logic: two bytes each
 * (index of the object hit, its id), as HandleGameObjectCollision writes them. Some are read
 * by the object logic of both halves with a meaning that depends on the half: the point index
 * of the evolution trinkets is a trinket of the top half for one, of the bottom half for the
 * other. The other half's run must see "nothing touched", as in the original where the half
 * without the ball did not run at all: otherwise it collected a trinket the ball never touched
 * and opened the slot with 2 trinkets, the slot halo drawn with the trinkets' tiles (Bug 1.3_2). */
static const uint16_t BALL_HITS[] = {
    0xD4CB,   /* wWhichVoltorb / wWhichShellder            */
    0xD4D8,   /* wWhichBumper                              */
    0xD4DC,   /* wPinballLaunchCollision                   */
    0xD4ED,   /* wWhichDiglett / wWhichPsyduckPoliwag      */
    0xD4FB,   /* wBellsproutCollision                      */
    0xD500,   /* wStaryuCollision                          */
    0xD507,   /* wSpinnerCollision                         */
    0xD50D,   /* wWhichCAVELight                           */
    0xD515,   /* wWhichPikachu                             */
    0xD51F,   /* wWhichBoardTrigger                        */
    0xD5C7,   /* wWildMonCollision                         */
    0xD5F7,   /* wWhichPinballUpgradeTrigger               */
    0xD5FE,   /* wDittoSlotCollision                       */
    0xD601,   /* wSlotCollision                            */
    0xD60A,   /* wWhichBonusMultiplierRailing              */
    0xD630,   /* wSlowpokeCollision                        */
    0xD635,   /* wCloysterCollision                        */
};
#define NBALL_HITS (int)(sizeof BALL_HITS / sizeof BALL_HITS[0])

static void mark(uint16_t a, uint16_t b, uint8_t cls)
{
    for (uint32_t i = a; i < b; i++) wclass[i - 0xC000] = cls;
}

static void init_wclass(void)
{
    if (wclass_ready) return;
    memset(wclass, M_SHARED, sizeof wclass);
    mark(0xC700, 0xCA00, M_LOCAL);    /* wStageCollisionMap (per half)            */
    mark(0xCA00, 0xD000, M_LOCAL);    /* graphics queue (handled separately)      */
    mark(0xD000, 0xD0A0, M_LOCAL);    /* wSpriteBuffer                            */
    mark(0xD200, 0xD300, M_LOCAL);    /* palette data + fade buffers (per page)   */
    mark(0xD4AC, 0xD4AD, M_LOCAL);    /* wCurrentStage                            */
    mark(0xD7EC, 0xD7F3, M_LOCAL);    /* collision map pointers, wd7f2            */
    mark(0xD7FA, 0xD7FD, M_LOCAL);    /* graphics queue indices                   */
    mark(0xD802, 0xD803, M_LOCAL);    /* wSpriteBufferSize                        */
    mark(0xDF00, 0xE000, M_LOCAL);    /* stack                                    */
    mark(0xDD00, 0xDEB0, M_LOCAL);    /* audio engine                             */
    mark(0xD800, 0xD860, M_LOCAL);    /* audio control, rumble, joypad, RNG        */
    mark(0xD400, 0xD47E, M_LOCAL);    /* score queue, score                        */
    mark(0xC500, 0xC700, M_LOCAL);    /* bottom message text and buffer           */
    mark(W_QueueBuffers, W_QueueBuffers + W_QueueBuffersSize, M_LOCAL);   /* billboard buffers (see run_other_half) */
    mark(0xD5CA, 0xD5F3, M_LOCAL);    /* scrolling / stationary texts              */
    mark(0xD4B3, 0xD4BF, M_BALL);     /* ball position and velocity               */
    /* Special modes (catch 'em, evolution, map move): their state machine is in the object
     * logic of both halves, so it runs here in the other half too. In the original only the
     * ball's half ran it, and some steps take a "the other half will be reloaded" path when
     * they run in the half without the billboard: merged, such a step skipped the drawing of
     * the billboard in the ball's half (grey picture over the Pokemon, Bug 1.2_1). The ball's
     * half owns this state, as in the original; the other half still draws from it. */
    mark(0xD54B, 0xD5CA, M_BALL);     /* mode, state, evolution, timer, billboard, wild mon */
    mark(0xD5F3, 0xD5F9, M_BALL);     /* capture                                  */
    mark(0xD548, 0xD549, M_BALL);     /* wPinballIsVisible                        */
    mark(0xD79F, 0xD7AD, M_BALL);     /* tilt offsets, wSCX                       */
    mark(0xD7B8, 0xD7BE, M_BALL);     /* flipper collision and forces             */
    mark(0xD7C3, 0xD7EC, M_BALL);     /* collision scratch                        */
    mark(0xD7F3, 0xD7F9, M_BALL);
    for (int i = 0; i < NBALL_HITS; i++) mark(BALL_HITS[i], (uint16_t)(BALL_HITS[i] + 2), M_BALL);
    mark(W_CollidedPointIndex, W_CollidedPointIndex + 1, M_BALL);   /* evolution trinkets (see BALL_HITS) */
    wclass_ready = true;
}

static inline bool is_field(uint8_t s) { return s == 0 || s == 1 || s == 4 || s == 5; }
static inline bool is_top(uint8_t s) { return s == 0 || s == 4; }

/* ------------------------------------------------------------------ video pages */

static int page_of_stage(Pinball *pb, uint8_t stage)
{
    return (pb->st.unified && is_top(stage)) ? PB_PAGE_TOP : PB_PAGE_MAIN;
}

static void update_page(Pinball *pb)
{
    GBC *g = &pb->g;
    if (pb->st.nforced > 0) g->s.cpu_page = pb->st.forced[pb->st.nforced - 1];
    else g->s.cpu_page = page_of_stage(pb, W(W_CurrentStage));
    g->win_page = pb->st.unified ? PB_PAGE_MAIN : -1;   /* the window (status bar) lives on the main page */
    /* The window's own graphics (letters of the status bar messages, pause menu cursor,
     * status bar icons) are copied into VRAM by the main program, on the page of the ball's
     * half. The window is drawn from the main page: with the ball at the top, these copies
     * also go there (otherwise the status bar keeps old letters instead of its icons, and
     * the pause menu shows a stray tile instead of its cursor). Outside the interrupts and
     * the graphics queue (which have their own page), nothing else writes the top page. */
    g->tile_mirror_page = (pb->st.unified && pb->st.nforced == 0 && g->s.cpu_page == PB_PAGE_TOP) ? PB_PAGE_MAIN : -1;
    g->tile_mirror_lo = PB_WIN_TILES_LO;
    g->tile_mirror_hi = PB_WIN_TILES_HI;
}

static void push_page(Pinball *pb, int page)
{
    if (pb->st.nforced >= 16) pb->st.nforced = 0;     /* never expected: resynchronise */
    pb->st.forced[pb->st.nforced++] = (int8_t)page;
    update_page(pb);
}

static void pop_page(Pinball *pb)
{
    if (pb->st.nforced > 0) pb->st.nforced--;
    update_page(pb);
}

/* a bonus stage being played (Gengar, Mewtwo, Meowth, Diglett, Seel) */
static bool bonus_stage(Pinball *pb)
{
#ifdef PB_LEGACY
    return false;
#endif
    uint8_t st = W(W_CurrentStage);
    return W(W_CurrentScreen) == SCREEN_PINBALL_GAME && st >= 6 && st <= 15;
}

static void set_bands(Pinball *pb)
{
    if (pb->st.unified) {
        /* top half, bottom half (the window only when raised: in-game menus), and the
         * status bar under the table instead of over its bottom lines */
        GBCBand b[3] = {
            { PB_PAGE_TOP,  0,   PB_TOP_ROWS, 0,                 GBC_BAND_NO_WINDOW | GBC_BAND_FRAME_LCDC, 0 },
            { PB_PAGE_MAIN, 0,   144,         PB_TOP_ROWS,       GBC_BAND_WIN_CLIP | GBC_BAND_WIN_HIGH, 0x86 },
            { PB_PAGE_MAIN, 143, PB_HUD_ROWS, PB_TOP_ROWS + 144, GBC_BAND_STATUS, 0x86 },
        };
        gbc_set_bands(&pb->g, b, 3, pb->narrow ? PB_FIELD_W_NARROW : PB_FIELD_W, PB_FIELD_H);
    } else if (bonus_stage(pb)) {
        /* a bonus stage: the whole stage, and its status bar under it. The game slides the bar
         * down out of the screen while the ball is low (its line 132 and below), and up again:
         * a ball bounced on a flipper around that line made the bar jump up and down, over the
         * bottom of the stage. Here the bottom of the stage is always seen, the bar stays put. */
        GBCBand b[2] = {
            { PB_PAGE_MAIN, 0,   144,         0,   GBC_BAND_WIN_HIGH, 0x86 },
            { PB_PAGE_MAIN, 143, PB_HUD_ROWS, 144, GBC_BAND_STATUS,   0x86 },
        };
        gbc_set_bands(&pb->g, b, 2, 160, PB_STAGE_H);
    } else {
        GBCBand b = { PB_PAGE_MAIN, 0, 144, 0, 0, 0 };
        gbc_set_bands(&pb->g, &b, 1, 160, 144);
    }
}

static void set_unified(Pinball *pb, bool on)
{
    if (pb->st.unified == on) return;
    pb->st.unified = on;
    pb->st.nforced = 0;
    pb->st.other_oam_valid = false;
    pb->oam_buf_stage = pb->oam_other_stage = 0xFF;
    set_bands(pb);
    update_page(pb);
}

/* ------------------------------------------------------------------ helpers */

/* A routine of the game called from a hook did not return within its budget (never
 * expected): put the machine back as it was before the call instead of hanging. */
static void call_failed(Pinball *pb, const GBCState *before, const char *what)
{
#ifdef PB_DEBUG
    fprintf(stderr, "call failed: %s, stuck at %02X:%04X frame=%ld\n", what, (int)pb->g.s.rom_bank, pb->g.s.pc, pb->st.frame);
#else
    (void)what;
#endif
    state_copy(&pb->g.s, before);
    pb->g.fake_lcd_off = false;
    pb->st.stats_aborts++;
    update_page(pb);
}

static bool farcall_frozen(Pinball *pb, uint8_t bank, uint16_t addr)
{
    GBC *g = &pb->g;
    H(H_FarCallTempA) = g->s.a;
    g->s.a = bank;
    g->s.h = (uint8_t)(addr >> 8);
    g->s.l = (uint8_t)addr;
    return gbc_call_frozen(g, R_BankSwitch, false, BUDGET);
}

/*
 * Load the half W(W_CurrentStage) into its video page, out of time, as the original game does
 * when the ball enters a half: LoadStageData, i.e. the base graphics of the half, then its
 * state-dependent graphics (_LoadStageData, with wd7f2 = 0). Some routines rely on that
 * complete reload and leave the graphics of the half without the ball as they are: the
 * structures of the Red field (Ditto, the roof over the Voltorbs and its 3 lights, the
 * guard rail) are loaded as a difference from the base graphics, the end of the catch mode
 * only redraws the billboard when the ball is in the bottom half... Loading only the
 * state-dependent graphics over what a page shows leaves such parts in an old state.
 * The window's own graphics (status bar icons, message letters) belong to the ball's half
 * and are kept as they are.
 */
/*
 * LoadStageData copies the base graphics of a half at once, but some of its graphics go
 * through the graphics queue: the structures of the Red field (Ditto, the roof, the guard rail)
 * loaded as a difference from the base. The queue runs a few entries at each VBlank (its
 * budget, wd7fa, and the mark of each entry, wca00): for a few frames the half showed its base
 * structures (Ditto without its lower part, at the start of the catch mode or when the ball
 * crossed to the other half). The original loads with the screen off and never shows that. The
 * entries queued from slot s0 on are run now, out of time, in their page (hk_queue_entry), then
 * made harmless in the queue; the entries queued before them, for the other page, stay as they
 * are. */
static bool queue_run_new(Pinball *pb, uint8_t s0)
{
    GBC *g = &pb->g;
    uint8_t s1 = W(W_d7fb);
#ifdef PB_LEGACY
    s1 = s0;                                    /* the 2.0 behaviour (tools: comparisons) */
#endif
    if (s0 == s1) return true;
    uint8_t rd = W(W_d7fc), budget = W(W_d7fa), stop = W(W_VramQueueStart + s1);
    for (uint8_t s = s0; s != s1; s++) W(W_VramQueueStart + s) = 0xFF;   /* all in one run */
    W(W_VramQueueStart + s1) = 0;                                     /* and no further */
    W(W_d7fc) = s0;
    int np = pb->st.nforced;
    bool ok = gbc_call_frozen(g, R_Func_113a, false, BUDGET);
    pb->st.nforced = np;
    W(W_d7fc) = rd;
    W(W_d7fa) = budget;
    W(W_VramQueueStart + s1) = stop;
    for (uint8_t s = s0; s != s1; s++) {
        W(W_VramQueueFunc + s) = (uint8_t)R_Ret;
        W(W_VramQueueFunc + 0x100 + s) = (uint8_t)(R_Ret >> 8);
    }
    update_page(pb);
    return ok;
}

static bool load_half(Pinball *pb)
{
    GBC *g = &pb->g;
    /* The graphics queue may still hold updates queued for this page by the half's routines
     * (a frame of a blinking light...): run after the load, they would leave an old state on
     * screen. The original game empties the queue when the ball enters a half (Func_1129);
     * here only the entries of this page are made harmless (their routine becomes a "ret"),
     * the other page's ones must still run. */
    int page = g->s.cpu_page;
    for (uint8_t s = W(W_d7fc); s != W(W_d7fb); s++)
        if (pb->st.slot_page[s] == page) {
            W(W_VramQueueFunc + s) = (uint8_t)R_Ret;
            W(W_VramQueueFunc + 0x100 + s) = (uint8_t)(R_Ret >> 8);
        }
    GBCPage *m = &g->s.page[PB_PAGE_MAIN];
    uint8_t keep[PB_WIN_TILES_HI - PB_WIN_TILES_LO];
    memcpy(keep, &m->vram[0][PB_WIN_TILES_LO], sizeof keep);
    g->hook_skip = R_LoadStageData;                  /* the original routine, not hk_load_stage */
    uint8_t s0 = W(W_d7fb);
    bool ok = farcall_frozen(pb, B_LoadStageData, R_LoadStageData);
    g->hook_skip = -1;
#ifdef PB_LAGDEBUG
    if (getenv("PB_RLOG")) fprintf(stderr, "frame %ld: load_half page %d stage %d, %d entries queued, buffers %02X %02X %02X %02X\n",
                                   pb->st.frame, page, W(W_CurrentStage), (uint8_t)(W(W_d7fb) - s0), W(0xC000), W(0xC001), W(0xC150), W(0xC1B8));
#endif
    if (ok) ok = queue_run_new(pb, s0);              /* its structures now, not over the next frames */
    memcpy(&m->vram[0][PB_WIN_TILES_LO], keep, sizeof keep);
    return ok;
}

/* Express the ball position in the coordinates of half `to` (it is stored in those of `from`). */
static void ball_to_half(Pinball *pb, uint8_t from, uint8_t to)
{
    int y = W(W_BallYPos + 1);
    int yfull = y + (is_top(from) ? 0 : 0x88);
    int yt = yfull - (is_top(to) ? 0 : 0x88);
    if (yt < 0 || yt > 0xFF) {
        W(W_PinballIsVisible) = 0;
        yt = 0;
    }
    W(W_BallYPos + 1) = (uint8_t)yt;
}

static void watch_snapshot(Pinball *pb, int page)
{
    const uint16_t *list = page == PB_PAGE_TOP ? WATCH_TOP : WATCH_BOTTOM;
    int n = page == PB_PAGE_TOP ? NWATCH_TOP : NWATCH_BOTTOM;
    for (int i = 0; i < n; i++) pb->st.watch_last[page][i] = W(list[i]);
}

static bool watch_changed(Pinball *pb, int page)
{
    const uint16_t *list = page == PB_PAGE_TOP ? WATCH_TOP : WATCH_BOTTOM;
    int n = page == PB_PAGE_TOP ? NWATCH_TOP : NWATCH_BOTTOM;
    for (int i = 0; i < n; i++)
        if (pb->st.watch_last[page][i] != W(list[i])) return true;
    return false;
}

/* A watched variable that changed since the previous frame asks for a redraw even if it is back
 * to its value of the last redraw when the cooldown ends (A, B, A): the other half's run may
 * have drawn B. The Blue field's top lane lights (wBallUpgradeTriggerStates) rotate with the
 * flippers in the logic of both halves, drawn by the top half's only. When a late frame's
 * VBlank comes in the middle of the ball's half's logic, that half sees a key press that the
 * other half's run (started from the state before it) does not: the lights drawn as B came
 * back to A in the game state only, and stayed B on screen until the ball went up. */
static void watch_moved(Pinball *pb, int page)
{
#ifndef PB_LEGACY
    const uint16_t *list = page == PB_PAGE_TOP ? WATCH_TOP : WATCH_BOTTOM;
    int n = page == PB_PAGE_TOP ? NWATCH_TOP : NWATCH_BOTTOM;
    bool known = pb->watch_prev_page == page;
    for (int i = 0; i < n; i++) {
        uint8_t v = W(list[i]);
        if (known && v != pb->watch_prev[i]) pb->st.redraw_pending[page] = true;
        pb->watch_prev[i] = v;
    }
    pb->watch_prev_page = page;
#else
    (void)pb; (void)page;
#endif
}

/* Changes that load other graphics into tiles in use, redrawn at once (no cooldown): the slot
 * opening in the evolution mode (its halo uses the tiles where the trinkets were loaded), a
 * trinket collected, a mode starting or ending. They are rare. */
static bool watch_urgent(Pinball *pb, int page)
{
    const uint16_t *list = page == PB_PAGE_TOP ? WATCH_TOP : WATCH_BOTTOM;
    int n = page == PB_PAGE_TOP ? NWATCH_TOP : NWATCH_BOTTOM;
    for (int i = 0; i < n; i++)
        if ((list[i] == W_SlotIsOpen || list[i] == W_NumEvolutionTrinkets || list[i] == W_InSpecialMode) &&
            pb->st.watch_last[page][i] != W(list[i])) return true;
    return false;
}

/* ------------------------------------------------------------------ the other half */

enum { RUN_RESOLVE, RUN_DRAW, RUN_REDRAW };

/*
 * Run the game's own routine for the half `O` (the one without the ball), out of time.
 *   RUN_RESOLVE: its object logic (animations, lights...), starting from `base`, the game
 *                state before the ball's half ran the same logic this frame, then merged;
 *   RUN_DRAW:    its sprites, starting from `base`, captured for its video page, merged;
 *   RUN_REDRAW:  its graphics, loaded as when the ball enters the half (load_half), a pure
 *                redraw: only the video page keeps the result.
 * The window (status bar, messages, in-game menus) belongs to the ball's half: whatever
 * the other half's routines draw there is dropped, like their message state.
 */
static void run_other_half(Pinball *pb, const GBCState *base, uint8_t R, uint8_t O, int kind)
{
    GBC *g = &pb->g;
    GBCState *after_r = pb->snap_b;
    state_copy(after_r, &g->s);

    if (kind != RUN_REDRAW) {
        memcpy(g->s.wram, base->wram, sizeof g->s.wram);
        memcpy(g->s.hram, base->hram, sizeof g->s.hram);
        /* keep the graphics queue as the ball's half left it (append after its entries) */
        memcpy(&W(0xCA00), &after_r->wram[0xCA00 - 0xC000], 0x600);
        memcpy(&W(W_d7fa), &after_r->wram[W_d7fa - 0xC000], 3);
    }
    W(W_CurrentStage) = O;
    update_page(pb);
    ball_to_half(pb, R, O);
    if (kind == RUN_RESOLVE) {                  /* the ball touched nothing in this half (see BALL_HITS) */
        for (int i = 0; i < NBALL_HITS; i++) W(BALL_HITS[i]) = W(BALL_HITS[i] + 1) = 0;
        W(W_CollidedPointIndex) = 0;
    }

    /* The structures of the Red field's top half (Ditto, the roof, the guard rail) change when
     * a mode asks for it (wRedStageStructureBackup), but only once the ball passes an alley of
     * the top half: the original game never showed the top half in between. Here it is on
     * screen, and the graphics of the mode (the evolution trinkets...) are loaded over tiles of
     * the old structures (the large Ditto): the top half is drawn with the structures the
     * mode asked for, as the original shows them once the ball is there. Drawing only: the
     * game state is not changed. */
    if (kind != RUN_RESOLVE && O == STAGE_RED_FIELD_TOP && !(W(W_RedStageStructureBackup) & 0x80))
        W(W_StageCollisionState) = (uint8_t)((W(W_StageCollisionState) & 1) | W(W_RedStageStructureBackup));

    bool ok;
    g->fake_lcd_off = true;
    pb->other_run = 1 + kind;
    if (kind == RUN_RESOLVE) {
        ok = gbc_call_frozen(g, R_ResolveGameObjectCollisions, true, BUDGET);
    } else if (kind == RUN_DRAW) {
        W(W_SpriteBufferSize) = 0;
        ok = gbc_call_frozen(g, R_DrawSpritesForStage, true, BUDGET);
        if (ok) {
            uint8_t n = W(W_SpriteBufferSize);
            if (n > 0xA0) n = 0xA0;
            memcpy(pb->st.other_oam, &W(W_SpriteBuffer), n);
            memset(pb->st.other_oam + n, 0, (size_t)(0xA0 - n));
            pb->st.other_oam_valid = true;
            pb->oam_other_stage = O;
        }
    } else {
        ok = load_half(pb);
    }
    pb->other_run = 0;
    g->fake_lcd_off = false;

    if (!ok) {                      /* never expected: drop everything this run did */
#ifdef PB_DEBUG
        fprintf(stderr, "abort: kind=%d R=%d O=%d stuck at %02X:%04X sp=%04X frame=%ld, stack", kind, R, O,
                (int)g->s.rom_bank, g->s.pc, g->s.sp, pb->st.frame);
        for (int i = 0; i < 12; i++) fprintf(stderr, " %04X", gbc_read(g, (uint16_t)(g->s.sp + 2 * i)) | gbc_read(g, (uint16_t)(g->s.sp + 2 * i + 1)) << 8);
        fprintf(stderr, ", LY %d STAT %02X LCDC %02X lcdoff %d\n", gbc_read(g, 0xFF44), gbc_read(g, 0xFF41), gbc_read(g, 0xFF40), g->fake_lcd_off);
#endif
        state_copy(&g->s, after_r);
        pb->st.stats_aborts++;
        update_page(pb);
        return;
    }

    /* results: the other half's video page, the graphics queue, and (resolve/draw) its
     * game state changes where the ball's half did not change the same bytes. Of the other
     * half's state, only its work RAM is kept aside; its video pages stay in place while the
     * rest of the ball's half state comes back. */
    GBCState *after_o = pb->snap_c;
    memcpy(after_o->wram, g->s.wram, sizeof g->s.wram);
    if (kind == RUN_DRAW)                   /* drawing only (see above): not a change of the game state */
        after_o->wram[W_StageCollisionState - 0xC000] = base->wram[W_StageCollisionState - 0xC000];
    state_copy_ex(&g->s, after_r, false);
    GBCPage *m = &g->s.page[PB_PAGE_MAIN];
    const GBCPage *mr = &after_r->page[PB_PAGE_MAIN];
    for (int b = 0; b < 2; b++) memcpy(&m->vram[b][0x1C00], &mr->vram[b][0x1C00], 0x400);   /* window map */
    memcpy(&m->vram[0][PB_WIN_TILES_LO], &mr->vram[0][PB_WIN_TILES_LO], PB_WIN_TILES_HI - PB_WIN_TILES_LO);
    memcpy(&W(0xCA00), &after_o->wram[0xCA00 - 0xC000], 0x600);
    memcpy(&W(W_d7fa), &after_o->wram[W_d7fa - 0xC000], 3);
    /* Some entries of the graphics queue copy their data from WRAM buffers (the billboard
     * picture, its animation frames, its palettes): what is there when the queue runs is
     * drawn. These buffers belong to the bottom half, where the billboard is, whichever half
     * the ball is in: the top half's routines write them too during the catch mode, which
     * mixed other data into the billboard of the bottom half (grey picture, Bug 1.2_1).
     * They are excluded from the merge (class LOCAL) and taken from the bottom half's run. */
    if ((O & 1) && memcmp(&W(W_QueueBuffers), &after_o->wram[W_QueueBuffers - 0xC000], W_QueueBuffersSize)) {
        memcpy(&W(W_QueueBuffers), &after_o->wram[W_QueueBuffers - 0xC000], W_QueueBuffersSize);
        pb->st.stats_buffers++;
    }
    if (kind != RUN_REDRAW) {
        const uint8_t *b0 = base->wram, *br = after_r->wram, *bo = after_o->wram;
        uint8_t *dst = g->s.wram;
        /* most of the memory is not changed by the other half: 16 bytes compared at a time,
         * byte by byte only where it changed something */
        for (int i0 = 0; i0 < 0x2000; i0 += 16) {
            if (same16(bo + i0, b0 + i0)) continue;
            for (int i = i0; i < i0 + 16; i++)
                if (wclass[i] == M_SHARED && bo[i] != b0[i] && br[i] == b0[i]) {
                    if (pb->merge_fn) pb->merge_fn(pb, (uint16_t)(0xC000 + i), dst[i], bo[i], kind);
                    dst[i] = bo[i];
                }
        }
    }
    update_page(pb);
}

/* The ball entered half `target`: switch the physics to it and load it, as the original
 * FieldVerticalTransition did, but without blanking the screen (the half is loaded into
 * its own page) and keeping the graphics queue of the other half. */
static void enter_half(Pinball *pb, uint8_t target, int dy)
{
    GBC *g = &pb->g;
    uint8_t old = W(W_CurrentStage);
    state_copy(pb->snap_c, &g->s);
    W(W_CurrentStage) = target;
    update_page(pb);
    g->fake_lcd_off = true;
    bool ok = farcall_frozen(pb, B_LoadStageCollisionAttributes, R_LoadStageCollisionAttributes);
    if (ok) ok = load_half(pb);
    g->fake_lcd_off = false;
    if (!ok) { call_failed(pb, pb->snap_c, "enter_half"); return; }   /* the ball stays in its half */
    W(W_BallYPos + 1) = (uint8_t)(W(W_BallYPos + 1) + dy);
    /* The half the ball left becomes the "other" half. It still shows what the ball's half
     * displayed, including frames of animations that only run there (the slot cave cover
     * blinking while the ball is near...), which the original game never showed again: it
     * reloaded the half when the ball came back. It is reloaded the same way once the
     * redraw cooldown allows it. */
    int pl = page_of_stage(pb, old);
    watch_snapshot(pb, pl);
    pb->st.last_refresh[pl] = pb->st.frame;
    pb->st.redraw_pending[pl] = true;
    pb->st.stats_swaps++;
}

static void camera(Pinball *pb)
{
    if (pb->narrow) {
        /* the original width (160 pixels, the launch lane on the right is off screen): the
         * horizontal scrolling of the original ScrollScreenToShowPinball, both halves together.
         * While the ball is in the launch lane the screen moves right 2 pixels a frame up to
         * 32 pixels, and back when it leaves. No vertical scrolling: both halves are shown. */
        uint8_t scx = W(W_SCX);
        if (!W(W_DisableHorizontalScrollForBallStart)) {
            uint8_t n = (uint8_t)(scx + (W(W_BallXPos + 1) >= 0x9A ? 2 : -2));
            if (n != 0x22 && !(n & 0x80)) scx = n;
            W(W_SCX) = scx;
        }
        H(H_SCX) = (uint8_t)(scx - W(W_LeftRightTiltOffset));
    } else {
        /* the whole table is on screen: no scrolling, only the tilt shake */
        W(W_SCX) = 0;
        H(H_SCX) = (uint8_t)(0 - W(W_LeftRightTiltOffset));
    }
    H(H_SCY) = (uint8_t)(0 - W(W_UpperTiltOffset));
}

/* ------------------------------------------------------------------ hooks */

/*
 * Object logic. The ball's half runs it as the game does (it can last several frames,
 * e.g. the map roulette at the start of a game waits for the player), so it is not
 * wrapped: the state is saved when it starts, and when it returns to its only caller
 * (GameScreenFunction_HandleBallPhysics) the other half runs the same logic.
 */
static bool hk_resolve(GBC *g, void *u)
{
    Pinball *pb = (Pinball *)u;
    uint8_t R = W(W_CurrentStage);
    pb->st.resolve_pending = false;
    if (!pb->st.unified || !is_field(R)) return false;
    /* the base of run_other_half: only its work and high RAM are read */
    memcpy(pb->snap_r->wram, g->s.wram, sizeof g->s.wram);
    memcpy(pb->snap_r->hram, g->s.hram, sizeof g->s.hram);
    pb->st.resolve_pending = true;
    pb->st.resolve_stage = R;
    pb->st.resolve_frame = g->s.frame_count;
    return false;
}

static bool hk_resolve_done(GBC *g, void *u)
{
    Pinball *pb = (Pinball *)u;
    if (!pb->st.resolve_pending) return false;
    pb->st.resolve_pending = false;
    uint8_t R = W(W_CurrentStage);
    if (!pb->st.unified || R != pb->st.resolve_stage) return false;
    if (g->s.frame_count - pb->st.resolve_frame <= 1)          /* not after a long sequence */
        run_other_half(pb, pb->snap_r, R, R ^ 1, RUN_RESOLVE);
    if (is_top(R)) {                                          /* flippers move whatever the ball does */
        state_copy(pb->snap_c, &g->s);
        g->call_in_frame = pb->antilag;
        bool ok = gbc_farcall(g, B_UpdateFlipperStates, R_UpdateFlipperStates);
        g->call_in_frame = false;
        if (!ok) call_failed(pb, pb->snap_c, "flippers");
    }
    return false;
}

static bool hk_draw(GBC *g, void *u)
{
    Pinball *pb = (Pinball *)u;
    uint8_t R = W(W_CurrentStage);
    if (!pb->st.unified || !is_field(R)) return false;
    state_copy(pb->snap_a, &g->s);
    pb->oam_drawing = true;
    g->call_in_frame = pb->antilag;                          /* a late frame: see pb_set_antilag */
    bool drawn = gbc_call_orig(g, R_DrawSpritesForStage);    /* ball's half -> wSpriteBuffer */
    g->call_in_frame = false;
    pb->oam_drawing = false;
    if (!drawn) {
        call_failed(pb, pb->snap_a, "draw");                  /* back at the routine's entry: skip it */
        gbc_ret(g);
        return true;
    }
    pb->oam_buf_stage = R;
    if (pb->st.unified && W(W_CurrentStage) == R) {
        uint8_t O = R ^ 1;
        int po = page_of_stage(pb, O);
        run_other_half(pb, pb->snap_a, R, O, RUN_DRAW);      /* other half -> its own sprites */
        watch_moved(pb, po);
        if (((watch_changed(pb, po) || pb->st.redraw_pending[po]) && pb->st.frame - pb->st.last_refresh[po] >= REFRESH_COOLDOWN) ||
            watch_urgent(pb, po)) {
            run_other_half(pb, NULL, R, O, RUN_REDRAW);
            watch_snapshot(pb, po);
            pb->st.redraw_pending[po] = false;
            pb->st.last_refresh[po] = pb->st.frame;
            pb->st.stats_refresh++;
        }
    }
    gbc_ret(g);
    return true;
}

static bool hk_transition(GBC *g, void *u)
{
    Pinball *pb = (Pinball *)u;
    uint8_t st = W(W_CurrentStage);
    if (!pb->st.unified || !is_field(st)) return false;
    camera(pb);
    uint8_t t = (uint8_t)(W(W_BallYPos + 1) + 0x10);
    uint8_t target = 0;
    int dy = 0;
    bool move = false;
    if (t < 0x18) { target = STAGE_UP[st & 15]; dy = 0x88; move = true; }
    else if (t >= 0xB8) { target = STAGE_DOWN[st & 15]; dy = -0x88; move = true; }
    if (move && target == 0xFF) {
        /* ball lost: "callba HandleBallLoss" as a tail call (it may run for several frames) */
        W(W_MoveToNextScreenState) = 1;
        H(H_FarCallTempA) = g->s.a;
        g->s.a = B_HandleBallLoss;
        g->s.h = (uint8_t)(R_HandleBallLoss >> 8);
        g->s.l = (uint8_t)R_HandleBallLoss;
        g->s.pc = R_BankSwitch;
        return true;
    }
    if (move) enter_half(pb, target, dy);
    gbc_ret(g);
    return true;
}

static bool hk_scroll(GBC *g, void *u)
{
    Pinball *pb = (Pinball *)u;
    if (!pb->st.unified || !is_field(W(W_CurrentStage))) return false;
    camera(pb);
    gbc_ret(g);
    return true;
}

static bool hk_load_stage(GBC *g, void *u)
{
    Pinball *pb = (Pinball *)u;
    uint8_t R = W(W_CurrentStage);
#ifdef PB_REFERENCE
    /* tools only: the original game, without the unified field (comparisons) */
    if (true) {
#else
    if (!is_field(R) || W(W_CurrentScreen) != SCREEN_PINBALL_GAME) {
#endif
        set_unified(pb, false);
        return false;
    }
    set_unified(pb, true);
    uint8_t O = R ^ 1;
    /* the other half first, as a pure graphics load into its own page... */
    GBCState *before = pb->snap_a;
    state_copy(before, &g->s);
    W(W_CurrentStage) = O;
    update_page(pb);
#ifndef PB_LEGACY
    /* drawn as run_other_half draws it: the Red top half with the structures a mode asked for
     * (2.5: loaded with the old ones on the return from a bonus stage, and nothing redrew it: the
     * bottom of Ditto stayed in another state until the ball went up). Drawing only: the state of
     * the game comes back below. */
    if (O == STAGE_RED_FIELD_TOP && !(W(W_RedStageStructureBackup) & 0x80))
        W(W_StageCollisionState) = (uint8_t)((W(W_StageCollisionState) & 1) | W(W_RedStageStructureBackup));
#endif
    uint8_t s0 = W(W_d7fb);
    bool ok = gbc_call_frozen(g, R_LoadStageData, true, BUDGET * 4);
    if (ok) ok = queue_run_new(pb, s0);              /* its structures too (see queue_run_new) */
    GBCState *after = pb->snap_b;
    state_copy(after, &g->s);
    state_copy(&g->s, before);
    if (ok) memcpy(g->s.page, after->page, sizeof g->s.page);
    update_page(pb);
    watch_snapshot(pb, page_of_stage(pb, O));
    pb->st.last_refresh[page_of_stage(pb, O)] = pb->st.frame;
    pb->st.redraw_pending[0] = pb->st.redraw_pending[1] = false;
    pb->st.other_oam_valid = false;
    pb->oam_buf_stage = pb->oam_other_stage = 0xFF;
    /* ...then the ball's half, exactly as the game does (the original routine runs) */
    return false;
}

static bool hk_timer(GBC *g, void *u)
{
    Pinball *pb = (Pinball *)u;
    if (!pb->st.unified || is_top(W(W_CurrentStage))) return false;
    gbc_ret(g);                      /* the timer is shown once, at the top of the table */
    return true;
}

/* The capture animation of the catch mode (4:4496: the Pokemon caught and the frames of its Poke
 * Ball, loaded into tiles 126-127, 144-167 and 56-59, shown on the billboard) is drawn by the
 * logic of the half the ball is in, both tables; the billboard is in the bottom half. The top
 * half's run out of time did it too, on its own page: over the tiles of the big Ditto (Red
 * table), whose picture was broken until the next redraw of the top half (18 frames after the
 * third hit). Its run skips it now (the ball's half draws it); the ball's half at the top (the ball
 * thrown up during the animation) draws it on the page of the billboard. */
static bool hk_capture_anim(GBC *g, void *u)
{
    Pinball *pb = (Pinball *)u;
    if (!pb->st.unified || !is_top(W(W_CurrentStage))) return false;
    if (pb->other_run) { gbc_ret(g); return true; }
    state_copy(pb->snap_c, &g->s);
    push_page(pb, PB_PAGE_MAIN);
    g->call_in_frame = pb->antilag;                     /* its copies take frames: see pb_set_antilag */
    bool ok = gbc_call_orig(g, R_CaptureAnimation);
    g->call_in_frame = false;
    pop_page(pb);
    if (!ok) call_failed(pb, pb->snap_c, "capture animation");   /* back at its entry: skipped */
    gbc_ret(g);
    return true;
}

/* the game waits for the next frame (0468: clears hFFB2, then loops at 0472 until the VBlank
 * interrupt sets it): where its program is when it has done the work of a frame */
#define R_WaitFrame      0x0468
#define R_WaitFrameLoop  0x0472
#define LATE_BUDGET      40000                  /* instructions: two frames' worth at most */

static bool hk_wait(GBC *g, void *u)
{
    Pinball *pb = (Pinball *)u;
    if (!g->frozen) pb->wait_sp = g->s.sp;
    return false;
}

/* Sound effects (PlaySoundEffect, 04AF: E the effect, D its priority). The memory of the sound
 * engine is the ball's half's (class LOCAL): an effect asked for only by the logic of the other
 * half, run out of time (its objects, its sprites), would be lost. They are noted, and played at
 * the end of the frame (sfx_other_play) unless the ball's half asked for the same one meanwhile.
 * Measured (pbrun -sfx): the special modes run in both halves and ask for theirs twice; the
 * redraw of the other half (LoadStageData) asks for the effect 07, which the original only plays
 * when the ball enters the half (enter_half: kept), and which is not played here. */
#define R_PlaySoundEffect 0x04AF
static bool hk_sfx(GBC *g, void *u)
{
    Pinball *pb = (Pinball *)u;
#ifdef PB_LAGDEBUG
    if (g->frozen) fprintf(stderr, "frame %ld: effect %02X%02X asked out of time, other_run %d, frozen %d, stage %d\n",
                           pb->st.frame, g->s.d, g->s.e, pb->other_run, g->frozen, W(W_CurrentStage));
#endif
    if (pb->other_run == 1 + RUN_RESOLVE || pb->other_run == 1 + RUN_DRAW) {
        uint16_t de = (uint16_t)(g->s.d << 8 | g->s.e);
        if (de && pb->sfx_other_n < 8) pb->sfx_other[pb->sfx_other_n++] = de;
    } else if (!pb->other_run) {
        pb->sfx_ball_frame[g->s.e] = pb->st.frame;
    }
    return false;
}

static void sfx_other_play(Pinball *pb)
{
    GBC *g = &pb->g;
    GBCState *s = &g->s;
    int n = pb->sfx_other_n;
    pb->sfx_other_n = 0;
    if (!pb->st.unified) return;
    for (int i = 0; i < n; i++) {
        uint16_t de = pb->sfx_other[i];
        uint8_t e = (uint8_t)de;
        long last = pb->sfx_ball_frame[e];
        if (last && pb->st.frame - last <= 2) continue;          /* the ball's half played it */
        /* between two frames: the registers and the HALT state of the program are kept (a call
         * from a halted CPU would not run) */
        state_copy(pb->snap_c, s);
        uint8_t a = s->a, f = s->f, b = s->b, c = s->c, d = s->d, ee = s->e, h = s->h, l = s->l;
        bool halted = s->halted;
        s->halted = false;
        s->d = (uint8_t)(de >> 8);
        s->e = e;
        if (!gbc_call_frozen(g, R_PlaySoundEffect, true, BUDGET)) { call_failed(pb, pb->snap_c, "sound effect"); continue; }
        s->a = a; s->f = f; s->b = b; s->c = c; s->d = d; s->e = ee; s->h = h; s->l = l;
        s->halted = halted;
        pb->sfx_ball_frame[e] = pb->st.frame;
        pb->stats_sfx_replayed++;
        update_page(pb);
    }
}

/* the Pokemon cries (14:4000, with the interrupts off: it waits for line 0 four times, then plays
 * the cry by writing the volume of the wave channel at a rate timed by the CPU, 14:5F56): never
 * out of time, where it would play nothing. A late frame being finished stops at its entry. */
#define B_PlayCry 0x14
#define R_PlayCry 0x4000
static bool hk_cry(GBC *g, void *u)
{
    Pinball *pb = (Pinball *)u;
    if (g->stretch && pb->late_budget) *pb->late_budget = 0;  /* gbc_exec stops before the next step */
#ifdef PB_LAGDEBUG
    if (g->call_depth > 0 && getenv("PB_LATELOG"))
        fprintf(stderr, "frame %ld: cry in a routine called by a hook (frozen %d stretch %d)\n", pb->st.frame, g->frozen, g->stretch);
#endif
    return false;
}

/* The copy to the video memory with the screen on (0735: the letters of the messages of the status
 * bar...) waits for a horizontal blank of the lines 64-127 for every 4 bytes: a few hundred bytes
 * take several frames, which the game skipped (the ball slowed down when a message came), and more
 * instructions than a late frame finished out of time is given (LATE_BUDGET). Out of time (a late
 * frame finished, a routine of a hook frozen at the end of the frame: the capture animation, ball up),
 * its loop goes on as the copy with the screen off (0666, the same registers and stack): at once. */
#define R_CopyScreenOnLoop  0x075A
#define R_CopyScreenOffLoop 0x067E
static bool hk_copy_screen_on(GBC *g, void *u)
{
    Pinball *pb = (Pinball *)u;
    (void)pb;
    if (!g->stretch) return false;
#ifdef PB_LAGDEBUG
    if (getenv("PB_LATELOG")) fprintf(stderr, "frame %ld: screen-on copy finished at once, %d bytes to %02X%02X\n", pb->st.frame,
                                      g->s.b << 8 | g->s.c, g->s.d, g->s.e);
#endif
    g->s.pc = R_CopyScreenOffLoop;
    return true;
}

/* graphics queue: remember which page each entry belongs to */
static bool hk_queue(GBC *g, void *u)
{
    Pinball *pb = (Pinball *)u;
    pb->st.slot_page[W(W_d7fb)] = (uint8_t)g->s.cpu_page;
#ifdef PB_LAGDEBUG
    if (getenv("PB_QLOG"))
        fprintf(stderr, "frame %ld: queue slot %02X page %d frozen %d other_run %d stage %d: routine %02X:%02X%02X data %02X%02X\n",
                pb->st.frame, W(W_d7fb), g->s.cpu_page, g->frozen, pb->other_run, W(W_CurrentStage), g->s.a, g->s.d, g->s.e, g->s.b, g->s.c);
#endif
    return false;
}

static bool hk_queue_entry(GBC *g, void *u)
{
    Pinball *pb = (Pinball *)u;
    push_page(pb, pb->st.unified ? pb->st.slot_page[g->s.l] : PB_PAGE_MAIN);
    return false;
}

static bool hk_queue_after(GBC *g, void *u)
{
    (void)g;
    pop_page((Pinball *)u);
    return false;
}

/* palettes: the game fades the palettes of the page it is on; do the same for the other page */
static void other_page_pal_to_buf(Pinball *pb, int p, int off)
{
    memcpy(&pb->st.palbuf[p][off], pb->g.s.page[p].bgpal, 64);
    memcpy(&pb->st.palbuf[p][off + 64], pb->g.s.page[p].obpal, 64);
}

static int other_page(Pinball *pb)
{
    return page_of_stage(pb, W(W_CurrentStage)) == PB_PAGE_TOP ? PB_PAGE_MAIN : PB_PAGE_TOP;
}

static bool hk_all_white(GBC *g, void *u)
{
    Pinball *pb = (Pinball *)u;
    (void)g;
    if (!pb->st.unified) return false;
    int p = other_page(pb);
    other_page_pal_to_buf(pb, p, 0x00);                 /* wPaletteData = current colours */
    for (int i = 0x80; i < 0x100; i += 2) { pb->st.palbuf[p][i] = 0xFF; pb->st.palbuf[p][i + 1] = 0x7F; }
    memcpy(pb->g.s.page[p].bgpal, &pb->st.palbuf[p][0x80], 64);
    memcpy(pb->g.s.page[p].obpal, &pb->st.palbuf[p][0xC0], 64);
    return false;
}

static bool hk_fade_out(GBC *g, void *u)
{
    Pinball *pb = (Pinball *)u;
    (void)g;
    if (!pb->st.unified) return false;
    other_page_pal_to_buf(pb, other_page(pb), 0x80);    /* fade buffers = current colours */
    return false;
}

static void fade_step(Pinball *pb, uint16_t routine)
{
    GBC *g = &pb->g;
    GBCState *s = &g->s;
    uint8_t ra = s->a, rb = s->b, rc = s->c, rd = s->d, re = s->e, rh = s->h, rl = s->l;
    state_copy(pb->snap_c, s);
    g->call_in_frame = pb->antilag && W(W_CurrentScreen) == SCREEN_PINBALL_GAME;
    bool done = gbc_call_orig(g, routine);
    g->call_in_frame = false;
    if (!done) { call_failed(pb, pb->snap_c, "fade"); return; }   /* the hook then skips it */
    if (!pb->st.unified) return;
    int p = other_page(pb);
    state_copy(pb->snap_b, s);
    memcpy(&W(W_PaletteData), pb->st.palbuf[p], 0x100);
    s->a = ra; s->b = rb; s->c = rc; s->d = rd; s->e = re; s->h = rh; s->l = rl;
    bool ok = gbc_call_frozen(g, routine, true, BUDGET);
    uint8_t other[0x100];
    memcpy(other, &W(W_PaletteData), 0x100);
    state_copy(s, pb->snap_b);             /* the ball's half state, registers included */
    if (ok) memcpy(pb->st.palbuf[p], other, 0x100);
    else { pb->st.stats_aborts++; update_page(pb); }
}

static bool hk_fade_in_step(GBC *g, void *u)
{
    Pinball *pb = (Pinball *)u;
    if (!pb->st.unified) return false;
    fade_step(pb, R_FadeInStep);
    gbc_ret(g);
    return true;
}

static bool hk_fade_out_step(GBC *g, void *u)
{
    Pinball *pb = (Pinball *)u;
    if (!pb->st.unified) return false;
    fade_step(pb, R_FadeOutStep);
    gbc_ret(g);
    return true;
}

static bool hk_faded_set(GBC *g, void *u)       /* at the end of SetFadedPalettes */
{
    Pinball *pb = (Pinball *)u;
    (void)g;
    if (!pb->st.unified) return false;
    int p = other_page(pb);
    memcpy(pb->g.s.page[p].bgpal, &pb->st.palbuf[p][0x80], 64);
    memcpy(pb->g.s.page[p].obpal, &pb->st.palbuf[p][0xC0], 64);
    return false;
}

/* interrupts: the VBlank handler draws the status bar and processes the graphics queue */
static void on_irq(GBC *g, int n, void *u)
{
    Pinball *pb = (Pinball *)u;
    push_page(pb, n == 0 ? PB_PAGE_MAIN : g->s.cpu_page);
}

static void on_reti(GBC *g, void *u)
{
    (void)g;
    pop_page((Pinball *)u);
}

static void on_stage_written(GBC *g, uint16_t a, uint8_t v, void *u)
{
    (void)g; (void)a; (void)v;
    update_page((Pinball *)u);
}

/*
 * The halo of the bonus slot of the bottom half ("SlotGlow" sprites, 8x16, palette 7) starts
 * at the very top of the bottom half: its upper part was never on screen in the original game
 * (the screen ended there), so the game has no graphics for it and the halo looked cut. Here
 * the top half is on screen above it: the upper part is drawn on the top page as the mirror
 * image of the lower part around the centre of the slot (PB_GLOW_AXIS lines below the top of
 * the halo), with the palette of the bottom half. The lower part opens at its tip to show the
 * arrow under the slot; in the mirror image that opening would be a notch in the upper part,
 * so it is filled there, continuing the dithering of the halo (Bug 1.2_3).
 * A tilt shakes the table: the game moves its sprites with the background, the halo then starts
 * a few lines above (or below) the top of the half. Everything follows (2.2: the upper part was
 * dropped during a tilt): the mirror image, and the first lines of the halo itself, which are
 * then above the top of the bottom half, on the top page.
 */
#define PB_GLOW_AXIS 7
#define PB_GLOW_W    48              /* width of the halo canvas (pixels) */

static bool is_slot_glow(const uint8_t *o)
{
    uint8_t t = o[2] & 0xFE;
    return o[0] && (o[3] == 0x17 || o[3] == 0x37) && ((t >= 0x1A && t <= 0x2E) || t == 0x38);
}

static void slot_glow_mirror(Pinball *pb)
{
    GBC *g = &pb->g;
    const GBCPage *pg = &g->s.page[PB_PAGE_MAIN];
    const uint8_t *oam = pg->oam;
    g->xobj_n[PB_PAGE_TOP] = 0;
    if (!(g->s.io[0x40] & 0x04)) return;                /* 8x16 sprites */
    int top = 0x7FFF, left = 0x7FFF, count = 0;
    for (int i = 0; i < 40; i++)
        if (is_slot_glow(&oam[i * 4])) {
            count++;
            if (oam[i * 4] - 16 < top) top = oam[i * 4] - 16;
            if (oam[i * 4 + 1] - 8 < left) left = oam[i * 4 + 1] - 8;
        }
    /* the halo is 8 sprites (an evolution trinket using the same tiles is one); it is cut by
     * the top of the half only when it starts at its first line (give or take a tilt) */
#ifdef PB_LEGACY
    if (count < 6 || top != 0) return;          /* the 2.0 behaviour (tools: comparisons) */
#endif
    if (count < 6 || top < -8 || top > 8) return;

    /* the lower part, lines 0-31 of the bottom half: colour indices, 0 = transparent */
    uint8_t cv[32][PB_GLOW_W];
    memset(cv, 0, sizeof cv);
    for (int i = 0; i < 40; i++) {
        const uint8_t *o = &oam[i * 4];
        if (!is_slot_glow(o)) continue;
        int sy = o[0] - 16 - top, sx = o[1] - 8 - left;     /* in the lines of the halo */
        for (int row = 0; row < 16; row++) {
            const uint8_t *td = &pg->vram[(o[3] >> 3) & 1][(o[2] & 0xFE) * 16 + ((o[3] & 0x40) ? 15 - row : row) * 2];
            for (int px = 0; px < 8; px++) {
                int bit = (o[3] & 0x20) ? px : 7 - px, y = sy + row, x = sx + px;
                int ci = ((td[0] >> bit) & 1) | (((td[1] >> bit) & 1) << 1);
                if (ci && y >= 0 && y < 32 && x >= 0 && x < PB_GLOW_W) cv[y][x] = (uint8_t)ci;
            }
        }
    }
    /* below the centre of the slot, the opening for the arrow: runs of 3 transparent pixels or
     * more between two pixels of the halo are filled with its dithering (every other pixel),
     * each side with the colour of its edge */
    for (int y = 2 * PB_GLOW_AXIS + 1; y < 32; y++) {
        int last = -1;
        for (int x = 0; x < PB_GLOW_W; x++) {
            if (!cv[y][x]) continue;
            if (last >= 0 && x - last > 3) {
                for (int f = last + 2; f < x; f += 2) cv[y][f] = (f - last <= x - f) ? cv[y][last] : cv[y][x];
            }
            last = x;
        }
    }
    /* the top page, from the line of the bottom half `top - 32` to its line -1: line m of the
     * halo (m = line - top) shows its line 2 * axis - m when m < 0 (the mirror image), its line m
     * otherwise (shaken up by a tilt, its first lines are above the top of the half); cut into
     * 8x16 sprites with their own tiles */
    int n = 0, y0 = top - 32;
    for (int band = 0; band * 16 < -y0; band++)
        for (int col = 0; col < PB_GLOW_W / 8; col++) {
            uint8_t tile[32];
            bool any = false;
            for (int row = 0; row < 16; row++) {
                int line = y0 + band * 16 + row, m = line - top, y = m < 0 ? 2 * PB_GLOW_AXIS - m : m;
                uint8_t lo = 0, hi = 0;
                if (line < 0 && y >= 0 && y < 32)
                    for (int px = 0; px < 8; px++) {
                        uint8_t ci = cv[y][col * 8 + px];
                        lo |= (uint8_t)((ci & 1) << (7 - px));
                        hi |= (uint8_t)(((ci >> 1) & 1) << (7 - px));
                    }
                tile[row * 2] = lo;
                tile[row * 2 + 1] = hi;
                any |= lo || hi;
            }
            if (!any || n >= 40) continue;
            memcpy(g->xobj_tiles[PB_PAGE_TOP][n], tile, 32);
            uint8_t *x = &g->xobj[PB_PAGE_TOP][n * 4];
            x[0] = (uint8_t)(PB_TOP_ROWS + y0 + band * 16 + 16);  /* in the lines of the top page */
            x[1] = (uint8_t)(left + col * 8 + 8);
            x[2] = (uint8_t)n;                                     /* own tile */
            x[3] = 0x07;                                           /* palette 7, no flip */
            n++;
        }
    g->xobj_n[PB_PAGE_TOP] = (uint8_t)n;
    g->xobj_src[PB_PAGE_TOP] = PB_PAGE_MAIN;
    g->xobj_private[PB_PAGE_TOP] = true;
}

/*
 * OAM DMA: each page receives the sprites of its half. The VBlank of a frame the game finishes
 * late can come between the passage of the ball to the other half (hk_transition) and the drawing
 * of the sprites (hk_draw): the game's buffer is then still the list of the half the ball left,
 * and other_oam that of the half it entered. Each list went to the page of the other half for a
 * frame or two: the timer, Staryu, the ball... of the top half drawn in the bottom half with its
 * tiles (black blocks over the Diglett), the flippers missing. Each page gets the last list made
 * for its half (the sprites of the frame before, at the passage), or keeps its own.
 */
static void on_dma(GBC *g, uint8_t src_hi, void *u)
{
    Pinball *pb = (Pinball *)u;
    uint8_t buf[0xA0];
    for (int i = 0; i < 0xA0; i++) buf[i] = gbc_read(g, (uint16_t)((src_hi << 8) + i));
    if (!pb->st.unified) {
        memcpy(g->s.page[PB_PAGE_MAIN].oam, buf, 0xA0);
        g->xobj_n[PB_PAGE_TOP] = 0;
        return;
    }
    uint8_t sr = W(W_CurrentStage), so = sr ^ 1;
    int pr = page_of_stage(pb, sr);
    int po = pr == PB_PAGE_TOP ? PB_PAGE_MAIN : PB_PAGE_TOP;
    const uint8_t *other = pb->st.other_oam_valid ? pb->st.other_oam : NULL;
    bool stale = pb->oam_buf_stage == so || (other && pb->oam_other_stage == sr);
    if (stale) pb->stats_stale_oam++;
    if (g->call_depth > 0) pb->stats_dma_in_call++;
#ifdef PB_DEBUG
    if (g->call_depth > 0 && getenv("PB_DMALOG")) {
        fprintf(stderr, "OAM DMA in a call: frame %ld stage %d drawing %d at %02X:%04X stack", pb->st.frame, sr, pb->oam_drawing,
                (int)g->s.rom_bank, g->s.pc);
        for (int i = 0; i < 12; i++) fprintf(stderr, " %04X", gbc_read(g, (uint16_t)(g->s.sp + 2 * i)) | gbc_read(g, (uint16_t)(g->s.sp + 2 * i + 1)) << 8);
        fprintf(stderr, "\n");
    }
    if (stale) {
        fprintf(stderr, "stale OAM lists: frame %ld stage %d, buffer for %d, other for %d (%d), at %02X:%04X LY %d stretch %d, stack",
                pb->st.frame, sr, pb->oam_buf_stage, pb->oam_other_stage, other != NULL, (int)g->s.rom_bank, g->s.pc,
                g->s.io[0x44], g->stretch);
        for (int i = 0; i < 10; i++) fprintf(stderr, " %04X", gbc_read(g, (uint16_t)(g->s.sp + 2 * i)) | gbc_read(g, (uint16_t)(g->s.sp + 2 * i + 1)) << 8);
        fprintf(stderr, "\n");
    }
#endif
#ifndef PB_LEGACY                       /* PB_LEGACY (tools): the output of 2.0, to compare the engines */
    if (stale) {
        /* a list being written (hk_draw) is that of the ball's half at its start, and of the half
         * it left after it: it is not given to the latter */
        const uint8_t *for_r = pb->oam_buf_stage != so ? buf : other && pb->oam_other_stage == sr ? other : NULL;
        const uint8_t *for_o = other && pb->oam_other_stage != sr ? other : pb->oam_buf_stage == so && !pb->oam_drawing ? buf : NULL;
        if (for_r) memcpy(g->s.page[pr].oam, for_r, 0xA0);
        if (for_o) memcpy(g->s.page[po].oam, for_o, 0xA0);
        slot_glow_mirror(pb);
        return;
    }
#endif
    memcpy(g->s.page[pr].oam, buf, 0xA0);
    if (other) memcpy(g->s.page[po].oam, other, 0xA0);
    else memset(g->s.page[po].oam, 0, 0xA0);
    slot_glow_mirror(pb);
}

/*
 * The status bar draws its icons and the score digits with tiles $81-$8F of the main page. The
 * bottom texts load special characters over some of them (é ' ! * . ...): when a text ends the
 * game restores tiles $83-$86 only. The asterisk of the evolved Pokemon names goes into tile
 * $87, the digit 1, and stayed there until the next LoadStageData: in the original, the next
 * time the ball changed halves. Here the window's tiles are kept across the halves (see
 * load_half), so the 1s of the score showed stars for the rest of the ball (Bug 1.3_1, a score
 * of 101,475,450 shown as *0*,475,450). With no text and no menu in the bar, an asterisk left
 * in that tile becomes the digit again.
 */
static void status_bar_tiles(Pinball *pb)
{
    if (!pb->st.unified || !is_field(W(W_CurrentStage)) || W(W_BottomTextEnabled) || !W(W_DrawBottomMessageBox)) return;
    if (pb->g.rom_size < ROM_AsteriskGlyph + 16) return;
    uint8_t *t = &pb->g.s.page[PB_PAGE_MAIN].vram[0][0x0870];          /* tile $87 */
    if (!memcmp(t, pb->g.rom + ROM_AsteriskGlyph, 16)) memcpy(t, pb->g.rom + ROM_StatusBarSymbols + 0x70, 16);
}

/* ------------------------------------------------------------------ public API */

int pb_init(Pinball *pb, const uint8_t *rom, size_t size, uint32_t sample_rate)
{
    memset(pb, 0, sizeof(*pb));
    pb->watch_prev_page = -1;
    pb->oam_buf_stage = pb->oam_other_stage = 0xFF;
    init_wclass();
    char sha[41];
    pb_sha1_hex(rom, size, sha);
    if (strcmp(sha, PB_ROM_SHA1) != 0) {
        snprintf(pb->error, sizeof pb->error,
                 "ROM non reconnue (SHA-1 %s). Il faut Pokemon Pinball version US/Australie, SHA-1 %s.",
                 sha, PB_ROM_SHA1);
        return -1;
    }
    pb->snap_a = (GBCState *)malloc(sizeof(GBCState));
    pb->snap_b = (GBCState *)malloc(sizeof(GBCState));
    pb->snap_c = (GBCState *)malloc(sizeof(GBCState));
    pb->snap_r = (GBCState *)malloc(sizeof(GBCState));
    pb->held = (uint32_t *)malloc((size_t)GBC_FB_H * GBC_FB_W * sizeof(uint32_t));
    if (!pb->snap_a || !pb->snap_b || !pb->snap_c || !pb->snap_r || !pb->held) {
        snprintf(pb->error, sizeof pb->error, "memoire insuffisante");
        return -1;
    }
    GBC *g = &pb->g;
    if (gbc_init(g, rom, size, sample_rate)) {
        snprintf(pb->error, sizeof pb->error, "ROM invalide");
        return -1;
    }
    pb->st.magic = PB_MAGIC;
    gbc_add_hook(g, 0, R_ResolveGameObjectCollisions, hk_resolve, pb);
    gbc_add_hook(g, 3, 0x5943, hk_resolve_done, pb);          /* return site in HandleBallPhysics */
    gbc_add_hook(g, B_DrawSpritesForStage, R_DrawSpritesForStage, hk_draw, pb);
    gbc_add_hook(g, B_CheckStageTransition, R_CheckStageTransition, hk_transition, pb);
    gbc_add_hook(g, 0, R_WaitFrame, hk_wait, pb);
    gbc_add_hook(g, B_PlayCry, R_PlayCry, hk_cry, pb);
    gbc_add_hook(g, 0, R_CopyScreenOnLoop, hk_copy_screen_on, pb);
    gbc_add_hook(g, 0, R_PlaySoundEffect, hk_sfx, pb);
    gbc_add_hook(g, B_ScrollScreenToShowPinball, R_ScrollScreenToShowPinball, hk_scroll, pb);
    gbc_add_hook(g, B_LoadStageData, R_LoadStageData, hk_load_stage, pb);
    gbc_add_hook(g, B_DrawTimer, R_DrawTimer, hk_timer, pb);
    gbc_add_hook(g, 0, R_QueueGraphicsToLoadWithFunc, hk_queue, pb);
    gbc_add_hook(g, 0, R_Func_113a_Entry, hk_queue_entry, pb);
    gbc_add_hook(g, 0, R_Func_113a_AfterCall, hk_queue_after, pb);
    gbc_add_hook(g, 0, R_SetAllPalettesWhite, hk_all_white, pb);
    gbc_add_hook(g, 0, R_FadeOut_GameboyColor, hk_fade_out, pb);
    gbc_add_hook(g, 0, R_FadeInStep, hk_fade_in_step, pb);
    gbc_add_hook(g, 0, R_FadeOutStep, hk_fade_out_step, pb);
    gbc_add_hook(g, 0, 0x0D9C, hk_faded_set, pb);             /* "ret" of SetFadedPalettes */
#ifndef PB_LEGACY
    gbc_add_hook(g, B_CaptureAnimation, R_CaptureAnimation, hk_capture_anim, pb);
#endif
    gbc_add_watch(g, W_CurrentStage, on_stage_written, pb);
    g->irq_fn = on_irq;
    g->reti_fn = on_reti;
    g->irq_user = pb;
    g->dma_fn = on_dma;
    g->dma_user = pb;
    set_bands(pb);
    update_page(pb);
    return 0;
}

void pb_free(Pinball *pb)
{
    free(pb->snap_a); free(pb->snap_b); free(pb->snap_c); free(pb->snap_r);
    pb->snap_a = pb->snap_b = pb->snap_c = pb->snap_r = NULL;
    free(pb->held);
    pb->held = NULL;
    pb->hold = false;
}

void pb_load_sram(Pinball *pb, const uint8_t *data, size_t size) { gbc_load_sram(&pb->g, data, size); }

const uint8_t *pb_sram(Pinball *pb, size_t *size)
{
    *size = pb->g.s.sram_size;
    return pb->g.s.sram;
}

void pb_set_antilag(Pinball *pb, bool on) { pb->antilag = on; }

void pb_set_frame_palettes(Pinball *pb, bool on) { gbc_set_frame_palettes(&pb->g, on); }

/* The game waits there (for an interrupt, or for time to pass): the work of the frame is done up
 * to this point. The frame wait (0468-0476) at any depth (the main loop, or a sequence that waits
 * frames itself); a flag cleared by an interrupt (0E62); the screen turned off (057E); a delay
 * counted down in BC or DE (the timing of some sequences: a roulette of the slot plays a sound
 * between such delays), which out of time would go faster; the Pokemon cries (14:4000-4075 and
 * their player 14:5F56-5FA5: see hk_cry), which out of time would play no sound. */
static bool game_waits(GBC *g)
{
    uint16_t pc = g->s.pc;
    if ((pc >= R_WaitFrame && pc <= R_WaitFrameLoop + 4) || (pc >= 0x0E62 && pc <= 0x0E67) || (pc >= 0x057E && pc <= 0x0585))
        return true;
    if (g->s.rom_bank == B_PlayCry && ((pc >= R_PlayCry && pc <= 0x4075) || (pc >= 0x5F56 && pc <= 0x5FA5))) return true;
    static const uint8_t delays[3][9] = {
        { 5, 0x0B, 0x78, 0xB1, 0x20, 0xFB },                         /* dec bc / ld a,b / or c / jr nz */
        { 5, 0x1B, 0x7A, 0xB3, 0x20, 0xFB },                         /* dec de / ld a,d / or e / jr nz */
        { 8, 0x00, 0x00, 0x00, 0x1B, 0x7A, 0xB3, 0x20, 0xF8 },       /* the same with 3 nops (0943, 12E7) */
    };
    for (int d = 0; d < 3; d++) {
        int n = delays[d][0];
        for (int k = 0; k < n - 1; k++) {                /* PC on one of the instructions of the loop */
            uint16_t base = (uint16_t)(pc - k);
            int i = 0;
            while (i < n && gbc_read(g, (uint16_t)(base + i)) == delays[d][1 + i]) i++;
            if (i == n) return true;
        }
    }
    return false;
}

/* The frame is over (the VBlank interrupt is due) and the game's program is still doing its work
 * of the frame: it goes on out of time (no time, no interrupts, as the calls of the other half),
 * by slices of LATE_SLICE instructions, until it waits for the next frame (the VBlank then
 * comes as after a frame done in time), or for anything else (game_waits: what it waits for comes
 * in real time, as in the original), or LATE_BUDGET instructions. Only on the pinball screen,
 * the LCD on (loadings with the LCD off do not wait for frames). */
#define LATE_SLICE 512
static void finish_late_frame(Pinball *pb)
{
    GBC *g = &pb->g;
    GBCState *s = &g->s;
    if (!pb->wait_sp || s->halted || !(s->io[0x40] & 0x80) || W(W_CurrentScreen) != SCREEN_PINBALL_GAME) return;
    if (game_waits(g)) return;
    pb->stats_late++;
#ifdef PB_LAGDEBUG
    uint16_t start_pc = s->pc;
    int start_bank = (int)s->rom_bank;
#endif
    int r = GBC_EXEC_BUDGET;
    g->frozen++;
    g->stretch++;
    for (long done = 0; done < LATE_BUDGET; done += LATE_SLICE) {
        int64_t budget = LATE_SLICE;
        pb->late_budget = &budget;
        r = gbc_exec(g, GBC_EXEC_CALL, R_WaitFrameLoop, pb->wait_sp, &budget, 0);
        pb->late_budget = NULL;
        if (r == GBC_EXEC_DONE || game_waits(g)) { r = GBC_EXEC_DONE; break; }
    }
    g->stretch--;
    g->frozen--;
    if (r == GBC_EXEC_DONE) pb->stats_late_done++;
#ifdef PB_LAGDEBUG
    if (r == GBC_EXEC_DONE && getenv("PB_LATELOG"))
        fprintf(stderr, "frame %ld: late frame finished out of time, from %02X:%04X\n", pb->st.frame, start_bank, start_pc);
    else if (r != GBC_EXEC_DONE) {
        fprintf(stderr, "late frame %ld not finished: started at %02X:%04X, now %02X:%04X SP %04X (wait SP %04X) stage %d, stack",
                pb->st.frame, start_bank, start_pc, (int)s->rom_bank, s->pc, s->sp, pb->wait_sp, W(W_CurrentStage));
        for (uint16_t a = s->sp; a < pb->wait_sp && a - s->sp < 32; a += 2) fprintf(stderr, " %04X", gbc_read(g, a) | gbc_read(g, (uint16_t)(a + 1)) << 8);
        fprintf(stderr, "\n");
    }
#endif
    update_page(pb);
}

static void view_now(Pinball *pb)
{
    PbView *v = &pb->view;
    v->screen = pb_screen(pb);
    v->stage = pb_stage(pb);
    v->table = pb_table(pb);
    v->in_game = pb_in_game(pb);
    v->playing = pb_playing(pb);
    v->lcd_on = (pb->g.s.io[0x40] & 0x80) != 0;
}

#define FLASH_STEP 64            /* whiter by more than this in one frame: a flash, not a fade */
#define FLASH_MAX  45            /* frames: a white screen that lasts more is shown */

/* see pb_set_hold: the picture of this frame, if the game drew a whole one */
static void hold_picture(Pinball *pb)
{
    GBC *g = &pb->g;
    if (pb->flash) pb->flash++;
    if (!g->frame_done) {                         /* the screen was off: the last picture stays, */
        pb->held_pending = false;                 /* and a single colour after it is a new cut */
        return;
    }
    int w = g->s.fw, h = g->s.fh;
    /* the status bar under a table or a stage does not count (it keeps its black while the
     * game's colours are white, just before a table is shown) */
    int hu = (h == PB_FIELD_H || h == PB_STAGE_H) ? h - PB_HUD_ROWS : h;
    uint32_t c0 = g->fb[0][0] & 0xFFFFFFu, mins = 0xFFFFFFFFu, diff = 0;
    for (int y = 0; y < hu; y++) row_stats(g->fb[y], w, c0, &mins, &diff);
    bool uniform = (diff & 0xFFFFFFu) == 0;
    int lo = (int)(mins & 255);                   /* how far to white: its darkest channel */
    if ((int)((mins >> 8) & 255) < lo) lo = (int)((mins >> 8) & 255);
    if ((int)((mins >> 16) & 255) < lo) lo = (int)((mins >> 16) & 255);
    /* The game's own flashes: a new ball on a bonus stage (to white in two frames, then the
     * screen off), leaving one, the end of a game: the picture before stays until the game's
     * picture is back (its fades take 16 frames: they are shown) */
    if (pb->flash) {
        if (lo > pb->held_lo + 16 && pb->flash <= FLASH_MAX) return;
        pb->flash = 0;
    } else if (pb->held_seq && lo - pb->held_lo > FLASH_STEP) {
        pb->flash = 1;
        return;
    }
    if (uniform && pb->held_seq && !pb->held_uniform && !pb->held_pending) {
        pb->held_pending = true;                  /* a cut to one colour: shown if it lasts */
        return;
    }
    pb->held_pending = false;
    pb->held_lo = lo;
    for (int y = 0; y < h; y++) memcpy(&pb->held[y * GBC_FB_W], g->fb[y], (size_t)w * sizeof(uint32_t));
    pb->held_w = w;
    pb->held_h = h;
    pb->held_uniform = uniform;
    view_now(pb);
    pb->held_seq++;
}

void pb_set_hold(Pinball *pb, bool on)
{
    pb->hold = on && pb->held;
    pb->held_seq = 0;
    pb->held_pending = false;
    pb->flash = 0;
}

uint32_t pb_picture_seq(const Pinball *pb) { return pb->hold ? pb->held_seq : (uint32_t)pb->st.frame; }

const PbView *pb_view(const Pinball *pb) { return &pb->view; }

void pb_run_frame(Pinball *pb, uint8_t buttons)
{
    gbc_set_buttons(&pb->g, buttons);
    gbc_run_frame(&pb->g);
    if (pb->antilag && pb->g.frame_done) finish_late_frame(pb);
#ifndef PB_LEGACY                       /* PB_LEGACY (tools): the output of 2.0, to compare the engines */
    if (pb->sfx_other_n) sfx_other_play(pb);
#endif
    if (pb->st.unified && W(W_CurrentScreen) != SCREEN_PINBALL_GAME) set_unified(pb, false);
    if (!pb->st.unified && bonus_stage(pb) != (pb->g.s.fh == PB_STAGE_H)) set_bands(pb);   /* in or out of a bonus stage */
    status_bar_tiles(pb);
    if (pb->st.unified) pb->st.stats_frames_unified++;
    pb->st.frame++;
    if (pb->hold) hold_picture(pb);
    else view_now(pb);
}

const uint32_t *pb_frame(Pinball *pb, int *w, int *h, int *stride)
{
    if (pb->hold && pb->held_seq) {
        *w = pb->held_w;
        *h = pb->held_h;
        *stride = GBC_FB_W;
        return pb->held;
    }
    *w = pb->g.s.fw;
    *h = pb->g.s.fh;
    *stride = GBC_FB_W;
    return &pb->g.fb[0][0];
}

int pb_audio(Pinball *pb, int16_t *out, int max_frames) { return gbc_audio_read(&pb->g, out, max_frames); }

void pb_set_audio_rate(Pinball *pb, double sample_rate) { gbc_set_audio_rate(&pb->g, sample_rate); }
void pb_set_audio_highpass(Pinball *pb, double hz) { gbc_set_audio_highpass(&pb->g, hz); }

bool pb_rumble(Pinball *pb) { return pb->g.s.rumble; }

bool pb_unified(const Pinball *pb) { return pb->st.unified; }

void pb_set_narrow(Pinball *pb, bool on)
{
    if (pb->narrow == on) return;
    pb->narrow = on;
    set_bands(pb);                       /* the camera follows from the next frame */
}

bool pb_narrow(const Pinball *pb) { return pb->narrow; }

int pb_screen(const Pinball *pb) { return pb->g.s.wram[W_CurrentScreen - 0xC000]; }

bool pb_in_game(const Pinball *pb) { return pb_screen(pb) == SCREEN_PINBALL_GAME; }

bool pb_playing(const Pinball *pb)
{
    /* the in-game menus stop the bottom message box and raise the window */
    return pb_in_game(pb) && pb->g.s.wram[W_DrawBottomMessageBox - 0xC000] && pb->g.s.hram[H_WY - 0xFF80] >= 0x80;
}

int pb_table(const Pinball *pb)
{
    if (!pb_in_game(pb)) return -1;
    uint8_t st = pb->g.s.wram[W_CurrentStage - 0xC000];
    return (st == 0 || st == 1) ? 0 : (st == 4 || st == 5) ? 1 : -1;
}

int pb_stage(const Pinball *pb)
{
    return pb_in_game(pb) ? pb->g.s.wram[W_CurrentStage - 0xC000] : -1;
}

int pb_fix_key_config(Pinball *pb)
{
    /* DefaultKeyConfigs: ball start A, flippers LEFT and A, tilts DOWN, B and SELECT, menu START */
    static const uint8_t def[14] = { 0x01, 0, 0x20, 0, 0x01, 0, 0x80, 0, 0x02, 0, 0x04, 0, 0x08, 0 };
    int scr = pb_screen(pb);
    if (scr < SCREEN_TITLESCREEN || scr == SCREEN_OPTIONS) return 0;   /* not loaded yet, or being changed */
    uint8_t *w = &pb->g.s.wram[W_KeyConfigs - 0xC000];
    if (!memcmp(w, def, sizeof def)) return 0;
    memcpy(w, def, sizeof def);
    uint8_t *s = pb->g.s.sram;
    s[S_KeyConfigs + 14] = s[S_KeyConfigs + 15] = 0;                   /* the signature */
    s[S_KeyConfigs + 18 + 14] = s[S_KeyConfigs + 18 + 15] = 0;         /* the backup's */
    return pb_in_game(pb) ? 1 : 2;
}

/*
 * Snapshots: a header, then the machine (GBCState) and the field (PinballState) as they are
 * in memory. A snapshot is only ever loaded by the build that wrote it: the header carries
 * a version (to increase when the meaning of the state changes) and a fingerprint of the
 * structure layout (which changes by itself with the structures, and differs between
 * platforms), plus a checksum. Anything else is refused: an app update must never load an
 * old suspend.state as garbage (and crash at every start because of it).
 */
#define PB_SNAP_MAGIC   0x43544250u    /* "PBTC" */
#define PB_SNAP_VERSION 5u

typedef struct {
    uint32_t magic, version, layout, check;
} SnapHeader;

static uint32_t fnv1a(uint32_t h, const void *data, size_t n)
{
    const uint8_t *p = (const uint8_t *)data;
    for (size_t i = 0; i < n; i++) { h ^= p[i]; h *= 16777619u; }
    return h;
}

static uint32_t snap_layout(void)
{
    const size_t v[] = {
        sizeof(GBCState), sizeof(PinballState), sizeof(long), sizeof(bool), GBC_PAGES, GBC_MAX_BANDS,
        offsetof(GBCState, sram), offsetof(GBCState, page), offsetof(GBCState, band), offsetof(GBCState, ppu),
        offsetof(GBCState, apu), offsetof(GBCState, frame_count), offsetof(GBCApu, ring),
        offsetof(PinballState, forced), offsetof(PinballState, palbuf), offsetof(PinballState, frame),
        offsetof(PinballState, resolve_frame), offsetof(PinballState, stats_swaps),
    };
    uint32_t h = 2166136261u;
    for (size_t i = 0; i < sizeof v / sizeof v[0]; i++) { uint32_t x = (uint32_t)v[i]; h = fnv1a(h, &x, sizeof x); }
    return h;
}

size_t pb_snapshot_size(void) { return sizeof(SnapHeader) + sizeof(GBCState) + sizeof(PinballState); }

void pb_snapshot_save(const Pinball *pb, void *dst)
{
    uint8_t *d = (uint8_t *)dst;
    SnapHeader h = { PB_SNAP_MAGIC, PB_SNAP_VERSION, snap_layout(), 0 };
    gbc_state_save(&pb->g, d + sizeof h);
    memcpy(d + sizeof h + sizeof(GBCState), &pb->st, sizeof(PinballState));
    h.check = fnv1a(2166136261u, d + sizeof h, sizeof(GBCState) + sizeof(PinballState));
    memcpy(d, &h, sizeof h);
}

/* values a valid snapshot of this game can hold (a corrupted one must not crash the core) */
static bool snap_sane(const Pinball *pb, const GBCState *s, const PinballState *st)
{
    if (st->magic != PB_MAGIC) return false;
    if (s->cpu_page < 0 || s->cpu_page >= GBC_PAGES) return false;
    if (s->nbands < 1 || s->nbands > GBC_MAX_BANDS || s->fw < 1 || s->fw > GBC_FB_W || s->fh < 1 || s->fh > GBC_FB_H) return false;
    for (int i = 0; i < s->nbands; i++) if (s->band[i].page >= GBC_PAGES) return false;
    if (s->wram_bank < 1 || s->wram_bank > 7 || s->sram_size != pb->g.s.sram_size) return false;
    if (st->nforced < 0 || st->nforced > 16) return false;
    for (int i = 0; i < st->nforced; i++) if (st->forced[i] < 0 || st->forced[i] >= GBC_PAGES) return false;
    return true;
}

int pb_snapshot_load(Pinball *pb, const void *src, size_t size)
{
    if (size != pb_snapshot_size()) return -1;
    const uint8_t *d = (const uint8_t *)src;
    SnapHeader h;
    memcpy(&h, d, sizeof h);
    if (h.magic != PB_SNAP_MAGIC || h.version != PB_SNAP_VERSION || h.layout != snap_layout()) return -1;
    if (h.check != fnv1a(2166136261u, d + sizeof h, sizeof(GBCState) + sizeof(PinballState))) return -1;
    /* the source may be unaligned (file buffer): check copies */
    GBCState *s = pb->snap_c;
    PinballState st;
    memcpy(s, d + sizeof h, sizeof(GBCState));
    memcpy(&st, d + sizeof h + sizeof(GBCState), sizeof st);
    if (!snap_sane(pb, s, &st)) return -1;

    /* the sound output keeps the settings of this run (sample rate of the device) and does
     * not replay the samples that were waiting when the snapshot was taken */
    GBCApu *a = &pb->g.s.apu;
    uint32_t rate = a->sample_rate;
    double cps = a->cyc_per_sample, hpf = a->hp_factor;
    gbc_state_load(&pb->g, s, sizeof(GBCState));
    memcpy(&pb->st, &st, sizeof st);
    a->sample_rate = rate;
    a->cyc_per_sample = cps;
    a->hp_factor = hpf;
    a->sample_pos = 0;
    a->acc_l = a->acc_r = 0;
    a->ring_r = a->ring_w;
    pb->g.fake_lcd_off = false;
    pb->g.hook_skip = -1;
    pb->watch_prev_page = -1;
    pb->oam_buf_stage = pb->oam_other_stage = 0xFF;
    pb->held_pending = false;
    pb->flash = 0;
    set_bands(pb);
    update_page(pb);
    return 0;
}

/* ------------------------------------------------------------------ SHA-1 */

static uint32_t rol(uint32_t v, int n) { return (v << n) | (v >> (32 - n)); }

void pb_sha1_hex(const uint8_t *data, size_t len, char out[41])
{
    uint32_t h0 = 0x67452301, h1 = 0xEFCDAB89, h2 = 0x98BADCFE, h3 = 0x10325476, h4 = 0xC3D2E1F0;
    uint64_t bits = (uint64_t)len * 8;
    size_t total = ((len + 8) / 64 + 1) * 64;
    for (size_t off = 0; off < total; off += 64) {
        uint8_t blk[64];
        for (int i = 0; i < 64; i++) {
            size_t p = off + (size_t)i;
            if (p < len) blk[i] = data[p];
            else if (p == len) blk[i] = 0x80;
            else if (p >= total - 8) blk[i] = (uint8_t)(bits >> (8 * (total - 1 - p)));
            else blk[i] = 0;
        }
        uint32_t w[80];
        for (int i = 0; i < 16; i++)
            w[i] = ((uint32_t)blk[i * 4] << 24) | ((uint32_t)blk[i * 4 + 1] << 16) | ((uint32_t)blk[i * 4 + 2] << 8) | blk[i * 4 + 3];
        for (int i = 16; i < 80; i++) w[i] = rol(w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16], 1);
        uint32_t a = h0, b = h1, c = h2, d = h3, e = h4;
        for (int i = 0; i < 80; i++) {
            uint32_t f, k;
            if (i < 20) { f = (b & c) | (~b & d); k = 0x5A827999; }
            else if (i < 40) { f = b ^ c ^ d; k = 0x6ED9EBA1; }
            else if (i < 60) { f = (b & c) | (b & d) | (c & d); k = 0x8F1BBCDC; }
            else { f = b ^ c ^ d; k = 0xCA62C1D6; }
            uint32_t t = rol(a, 5) + f + e + k + w[i];
            e = d; d = c; c = rol(b, 30); b = a; a = t;
        }
        h0 += a; h1 += b; h2 += c; h3 += d; h4 += e;
    }
    snprintf(out, 41, "%08x%08x%08x%08x%08x", h0, h1, h2, h3, h4);
}
