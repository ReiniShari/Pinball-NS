/*
 * app.c - logic of the mobile version (see app.h).
 *
 * Files kept in the private storage of the app:
 *   rom.gbc        the ROM the player imported (checked: US Pokemon Pinball)
 *   pinball.sav    the cartridge save (high scores, Pokedex, saved game)
 *   suspend.state  the whole machine when the app went to the background
 *   quick.state    the quick save of the menu
 *   gen_*          the same for Pokemon Pinball Generations (2.8), when its ROM was imported
 *   settings.txt   vibration / sound / motion tilt / game touch / screen filter / colours / the
 *                  game played / the last table played (keys of its bonus stages)
 */
#define _POSIX_C_SOURCE 200809L
#include "app.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <time.h>

/* ------------------------------------------------------------------ files */

static void path_of(const MobileApp *a, const char *name, char *out, size_t n)
{
    snprintf(out, n, "%s/%s", a->dir, name);
}

/* the files of a game: those of Generations begin with "gen_" */
static void game_path(const MobileApp *a, bool gen, const char *name, char *out, size_t n)
{
    snprintf(out, n, "%s/%s%s", a->dir, gen ? "gen_" : "", name);
}

static bool file_exists(const char *path)
{
    FILE *f = fopen(path, "rb");
    if (f) fclose(f);
    return f != NULL;
}

static uint8_t *read_all(const char *path, size_t *size, size_t max)
{
    FILE *f = fopen(path, "rb");
    if (!f) return NULL;
    if (fseek(f, 0, SEEK_END) != 0) { fclose(f); return NULL; }
    long n = ftell(f);
    fseek(f, 0, SEEK_SET);
    if (n <= 0 || (size_t)n > max) { fclose(f); return NULL; }
    uint8_t *d = (uint8_t *)malloc((size_t)n);
    if (d && fread(d, 1, (size_t)n, f) != (size_t)n) { free(d); d = NULL; }
    fclose(f);
    if (d) *size = (size_t)n;
    return d;
}

static bool write_all(const char *path, const void *data, size_t size)
{
    char tmp[600];
    snprintf(tmp, sizeof tmp, "%s.tmp", path);
    FILE *f = fopen(tmp, "wb");
    if (!f) return false;
    bool ok = fwrite(data, 1, size, f) == size;
    ok = (fflush(f) == 0) && ok;
    ok = (fsync(fileno(f)) == 0) && ok;
    ok = (fclose(f) == 0) && ok;
    if (!ok) { remove(tmp); return false; }
    return rename(tmp, path) == 0;
}

/* the file `path` with `data`, by the writer thread when the platform has one (a->io_async),
 * else now. False if it cannot be taken now (the previous one of this slot is still waiting):
 * the caller tries again later. */
static bool write_later(MobileApp *a, int slot, const char *path, const void *data, size_t size)
{
    AppWrite *w = &a->io[slot];
    if (!a->io_async) return write_all(path, data, size);
    if (size > sizeof w->data || atomic_load_explicit(&w->state, memory_order_acquire)) return false;
    snprintf(w->path, sizeof w->path, "%s", path);
    memcpy(w->data, data, size);
    w->size = size;
    atomic_store_explicit(&w->state, 1, memory_order_release);
    if (a->io_wake) a->io_wake();
    return true;
}

void app_io_run(MobileApp *a)
{
    for (int i = 0; i < 2; i++) {
        AppWrite *w = &a->io[i];
        if (!atomic_load_explicit(&w->state, memory_order_acquire)) continue;
        w->failed = !write_all(w->path, w->data, w->size);
        atomic_store_explicit(&w->state, 0, memory_order_release);
    }
}

void app_io_wait(MobileApp *a)
{
    for (int t = 0; t < 3000; t++) {                    /* 3 s at most */
        if (!atomic_load_explicit(&a->io[0].state, memory_order_acquire) &&
            !atomic_load_explicit(&a->io[1].state, memory_order_acquire)) return;
        if (a->io_wake) a->io_wake();
        struct timespec ms = { 0, 1000000 };
        nanosleep(&ms, NULL);
    }
}

/* ------------------------------------------------------------------ settings */

static void settings_load(MobileApp *a)
{
    char p[600];
    path_of(a, "settings.txt", p, sizeof p);
    size_t n;
    char *d = (char *)read_all(p, &n, 4096);
    if (!d) return;
    char buf[4097];
    memcpy(buf, d, n);
    buf[n] = 0;
    free(d);
    if (strstr(buf, "vibration=0")) a->ui.vibration = false;
    if (strstr(buf, "sound=0")) a->ui.sound = false;
    if (strstr(buf, "motion=1")) a->ui.motion = true;
    /* what a finger on the game does; up to 2.7 "touch=" (the flippers on or off): off stays off */
    const char *t = strstr(buf, "screen=");
    if (t && t[7] >= '0' && t[7] < '0' + UI_TOUCHES) a->ui.touch_mode = t[7] - '0';
    else if (strstr(buf, "touch=0")) a->ui.touch_mode = UI_TOUCH_OFF;
    if (strstr(buf, "game=1")) a->gen = true;
    if (strstr(buf, "controls=1")) a->ui.hide_controls = true;
    const char *f = strstr(buf, "filter=");
    if (f && f[7] >= '0' && f[7] < '0' + UI_FILTERS) a->ui.filter = f[7] - '0';
    f = strstr(buf, "colors=");
    if (f && f[7] >= '0' && f[7] < '0' + UI_COLORSETS) a->ui.colors = f[7] - '0';
    t = strstr(buf, "table=");
    if (t && t[6] >= '0' && t[6] < '0' + PB_TABLES) a->ui.table = t[6] - '0';
}

static void settings_save(MobileApp *a)
{
    char p[600], buf[192];
    path_of(a, "settings.txt", p, sizeof p);
    int n = snprintf(buf, sizeof buf, "vibration=%d\nsound=%d\nmotion=%d\nscreen=%d\nfilter=%d\ncolors=%d\ngame=%d\ntable=%d\ncontrols=%d\n",
                     a->ui.vibration ? 1 : 0, a->ui.sound ? 1 : 0, a->ui.motion ? 1 : 0, a->ui.touch_mode,
                     a->ui.filter, a->ui.colors, a->gen ? 1 : 0, a->ui.table, a->ui.hide_controls ? 1 : 0);
    if (!write_later(a, 1, p, buf, (size_t)n)) {         /* the previous one still waits: after it */
        app_io_wait(a);
        write_later(a, 1, p, buf, (size_t)n);
    }
}

/* ------------------------------------------------------------------ save data */

static void sram_load(MobileApp *a)
{
    app_io_wait(a);                                     /* a save being written: the new one */
    char p[600];
    game_path(a, a->gen, "pinball.sav", p, sizeof p);
    size_t n;
    uint8_t *d = read_all(p, &n, 0x8000);
    if (d) { pb_load_sram(a->pb, d, n); free(d); }
    const uint8_t *s = pb_sram(a->pb, &a->sav_last_size);
    if (a->sav_last_size > sizeof a->sav_last) a->sav_last_size = sizeof a->sav_last;
    memcpy(a->sav_last, s, a->sav_last_size);
}

static void sram_flush(MobileApp *a)
{
    if (!a->pb) return;
    size_t n;
    const uint8_t *s = pb_sram(a->pb, &n);
    if (n == 0 || n > sizeof a->sav_last) return;
    if (a->io[0].failed) { a->io[0].failed = false; a->sav_last_size = 0; }   /* written again */
    if (n == a->sav_last_size && memcmp(s, a->sav_last, n) == 0) return;
    char p[600];
    game_path(a, a->gen, "pinball.sav", p, sizeof p);
    if (write_later(a, 0, p, s, n)) { memcpy(a->sav_last, s, n); a->sav_last_size = n; }
}

/* the cartridge save on the disk now, after the writes waiting (the game is about to be replaced
 * or restarted: it reads the save again) */
static void sram_flush_now(MobileApp *a)
{
    app_io_wait(a);
    bool async = a->io_async;
    a->io_async = false;
    sram_flush(a);
    a->io_async = async;
}

static bool state_save(MobileApp *a, const char *name)
{
    if (!a->pb) return false;
    size_t n = pb_snapshot_size();
    void *buf = malloc(n);
    if (!buf) return false;
    pb_snapshot_save(a->pb, buf);
    char p[600];
    game_path(a, a->gen, name, p, sizeof p);
    bool ok = write_all(p, buf, n);
    free(buf);
    return ok;
}

static bool state_load(MobileApp *a, const char *name)
{
    if (!a->pb) return false;
    char p[600];
    game_path(a, a->gen, name, p, sizeof p);
    size_t n;
    uint8_t *d = read_all(p, &n, 64u << 20);
    if (!d) return false;
    bool ok = pb_snapshot_load(a->pb, d, n) == 0;
    free(d);
    return ok;
}

/* ------------------------------------------------------------------ the game */

/* start the game with the ROM in a->rom (already checked) */
static bool start_game(MobileApp *a, bool resume)
{
    if (a->pb) { pb_free(a->pb); free(a->pb); a->pb = NULL; }
    Pinball *pb = (Pinball *)calloc(1, sizeof(Pinball));
    if (!pb) return false;
    if (pb_init(pb, a->rom, a->rom_size, a->rate) != 0) {
        snprintf(a->ui.no_rom_detail, sizeof a->ui.no_rom_detail,
                 "The game could not be started (not enough memory, or a damaged ROM file).");
        pb_free(pb);
        free(pb);
        return false;
    }
    a->pb = pb;
    nd_set_flipper(pb_flipper_tiles(pb));       /* the game's flipper in the flipper keys */
    pb_set_narrow(pb, true);                    /* the table at its original width, always */
    pb_set_antilag(pb, true);                   /* no frame skipped by the game (see pinball.h) */
    pb_set_double_speed(pb, true);              /* the double speed of Generations, original ROM too */
    pb_set_frame_palettes(pb, true);            /* no picture torn by a change of colours */
    pb_set_hold(pb, true);                      /* the screen off (loadings): the last picture stays */
    pb_set_audio_highpass(pb, GBC_HIGHPASS_FRONT);      /* the bass of the music (gbc.h) */
    screen_reset(&a->scr, a->ui.table);
    sram_load(a);
    if (resume) {
        /* The suspended game is used once: if it made the app crash, the next start must not
         * load it again (the cartridge save is kept). It is written again at the next suspend. */
        state_load(a, "suspend.state");
        char p[600];
        game_path(a, a->gen, "suspend.state", p, sizeof p);
        remove(p);
    }
    a->ui.no_rom = false;
    a->ui.game_gen = a->gen;
    a->ui.other_game = a->installed[!a->gen];
    a->ui.no_rom_detail[0] = 0;
    atomic_store_explicit(&a->ring_flush, true, memory_order_release);   /* old samples: dropped by the audio thread */
    return true;
}

int app_init(MobileApp *a, const char *dir, uint32_t rate)
{
    memset(a, 0, sizeof *a);
    snprintf(a->dir, sizeof a->dir, "%s", dir);
    a->rate = rate ? rate : 48000;
    screen_init(&a->scr);
    ui_init(&a->ui);
    settings_load(a);
    a->ui.no_rom = true;
    char p[600];
    for (int g = 0; g < 2; g++) { game_path(a, g == 1, "rom.gbc", p, sizeof p); a->installed[g] = file_exists(p); }
    if (!a->installed[a->gen] && a->installed[!a->gen]) a->gen = !a->gen;   /* the one there is */
    game_path(a, a->gen, "rom.gbc", p, sizeof p);
    size_t n;
    uint8_t *d = read_all(p, &n, 8u << 20);
    if (d) {
        a->rom = d;
        a->rom_size = n;
        if (!start_game(a, true)) { free(a->rom); a->rom = NULL; a->rom_size = 0; }
    }
    return 0;
}

void app_free(MobileApp *a)
{
    if (a->pb) { pb_free(a->pb); free(a->pb); a->pb = NULL; }
    free(a->rom);
    a->rom = NULL;
    screen_free(&a->scr);
}

/* An IPS patch ("PATCH", records: 3 bytes of offset, 2 of size, the data, or a size 0 and 2 bytes of
 * count and the byte repeated, "EOF", maybe 3 bytes of the new size) applied to a ROM: the patched copy
 * (malloc), or NULL if the patch is damaged. */
static uint8_t *ips_apply(const uint8_t *rom, size_t rom_size, const uint8_t *ips, size_t n, size_t *out_size)
{
    const size_t max = 8u << 20;
    if (n < 8 || memcmp(ips, "PATCH", 5) != 0 || rom_size > max) return NULL;
    uint8_t *out = (uint8_t *)calloc(1, max);
    if (!out) return NULL;
    memcpy(out, rom, rom_size);
    size_t size = rom_size, i = 5;
    for (;;) {
        if (i + 3 > n) { free(out); return NULL; }
        if (!memcmp(ips + i, "EOF", 3)) {
            i += 3;
            if (i + 3 <= n) size = (size_t)ips[i] << 16 | (size_t)ips[i + 1] << 8 | ips[i + 2];
            break;
        }
        if (i + 5 > n) { free(out); return NULL; }
        size_t off = (size_t)ips[i] << 16 | (size_t)ips[i + 1] << 8 | ips[i + 2], len = (size_t)ips[i + 3] << 8 | ips[i + 4];
        i += 5;
        if (len) {
            if (i + len > n || off + len > max) { free(out); return NULL; }
            memcpy(out + off, ips + i, len);
            i += len;
        } else {
            if (i + 3 > n) { free(out); return NULL; }
            len = (size_t)ips[i] << 8 | ips[i + 1];
            if (off + len > max) { free(out); return NULL; }
            memset(out + off, ips[i + 2], len);
            i += 3;
        }
        if (off + len > size) size = off + len;
    }
    *out_size = size;
    return out;
}

bool app_import_rom(MobileApp *a, const uint8_t *data, size_t size)
{
    /* the patch of Generations: applied to the US ROM, if it is installed */
    uint8_t *patched = NULL;
    if (size >= 5 && !memcmp(data, "PATCH", 5)) {
        char p[600];
        game_path(a, false, "rom.gbc", p, sizeof p);
        size_t n;
        uint8_t *us = a->installed[0] ? read_all(p, &n, 8u << 20) : NULL;
        if (!us) {
            ui_toast(&a->ui, "Install the US ROM of Pokémon Pinball first, then open the patch again", 5);
            return false;
        }
        patched = ips_apply(us, n, data, size, &size);
        free(us);
        if (!patched) { ui_toast(&a->ui, "This patch could not be applied", 4); return false; }
        data = patched;
    }
    char sha[41];
    pb_sha1_hex(data, size, sha);
    const PbRom *rom = pb_rom_profile(sha);
    bool gen = rom && rom->id == PB_ROM_GENERATIONS;
    if (rom && a->rom && gen == a->gen && a->rom_size == size && memcmp(a->rom, data, size) == 0) {
        ui_toast(&a->ui, "This ROM is already installed", 3);
        free(patched);
        return true;
    }
    Pinball *probe = (Pinball *)calloc(1, sizeof(Pinball));
    if (!probe) { free(patched); return false; }
    int bad = pb_init(probe, data, size, a->rate);
    if (bad) {
        snprintf(a->ui.no_rom_detail, sizeof a->ui.no_rom_detail,
                 "This file is not a ROM Pinball NS knows (SHA-1 %.12s...). It needs Pokémon Pinball, US version (USA, "
                 "Australia), or Pokémon Pinball Generations 1.6.", sha);
        if (a->pb) ui_toast(&a->ui, patched ? "The patched ROM is not Pokémon Pinball Generations 1.6" : "This file is not the right ROM", 4);
    }
    pb_free(probe);
    free(probe);
    if (bad) { free(patched); return false; }

    uint8_t *copy = (uint8_t *)malloc(size);
    if (!copy) { free(patched); return false; }
    memcpy(copy, data, size);
    free(patched);
    char p[600];
    game_path(a, gen, "rom.gbc", p, sizeof p);
    write_all(p, copy, size);
    if (a->pb) app_suspend(a);                          /* the game played: kept to come back to */
    sram_flush_now(a);
    if (a->pb) { pb_free(a->pb); free(a->pb); a->pb = NULL; }
    free(a->rom);
    a->rom = copy;
    a->rom_size = size;
    a->installed[gen] = true;
    a->gen = gen;
    settings_save(a);
    if (!start_game(a, false)) return false;
    ui_toast(&a->ui, gen ? "Pokémon Pinball Generations installed. Have fun!" : "ROM installed. Have fun!", 4);
    return true;
}

bool app_has_rom(const MobileApp *a, const uint8_t *data, size_t size)
{
    if (size >= 5 && !memcmp(data, "PATCH", 5)) return a->installed[PB_ROM_GENERATIONS];
    char sha[41];
    pb_sha1_hex(data, size, sha);
    const PbRom *rom = pb_rom_profile(sha);
    return rom && a->installed[rom->id];
}

/* the other game installed: the one played is suspended (it is found again as it was), the other
 * one resumed */
static void switch_game(MobileApp *a)
{
    char p[600];
    game_path(a, !a->gen, "rom.gbc", p, sizeof p);
    size_t n;
    uint8_t *d = a->installed[!a->gen] ? read_all(p, &n, 8u << 20) : NULL;
    if (!d) {
        ui_toast(&a->ui, a->gen ? "Open the US ROM of Pokémon Pinball with Pinball NS to play it"
                                : "Open the ROM of Pokémon Pinball Generations 1.6 (or its IPS patch) with Pinball NS to play it", 5);
        return;
    }
    app_suspend(a);
    if (a->pb) { pb_free(a->pb); free(a->pb); a->pb = NULL; }
    free(a->rom);
    a->rom = d;
    a->rom_size = n;
    a->gen = !a->gen;
    settings_save(a);
    ui_open_menu(&a->ui, false);
    if (start_game(a, true)) ui_toast(&a->ui, a->gen ? "Pokémon Pinball Generations" : "Pokémon Pinball", 2);
}

bool app_has_game(const MobileApp *a) { return a->pb != NULL; }

bool app_running(const MobileApp *a) { return a->pb && !a->ui.menu_open; }

void app_layout(MobileApp *a, int w, int h) { ui_layout(&a->ui, w, h); }

void app_touch(MobileApp *a, int action, int id, float x, float y) { ui_touch(&a->ui, action, id, x, y); }

void app_set_pad(MobileApp *a, uint8_t b) { ui_set_external_buttons(&a->ui, b); }

void app_set_insets(MobileApp *a, int top, int bottom, int left, int right, int corner)
{
    ui_set_insets(&a->ui, top, bottom, left, right, corner);
}

void app_back(MobileApp *a)
{
    if (a->ui.menu_open && a->ui.about_open) { a->ui.about_open = false; a->ui.about_page = 0; return; }   /* ABOUT: the menu again */
    ui_open_menu(&a->ui, !a->ui.menu_open);
    if (a->ui.menu_open) a->ui.menu_sel = 0;          /* keys: the first entry is selected */
}

int app_take_haptic(MobileApp *a)
{
    int h = a->ui.haptic;
    a->ui.haptic = UI_HAPTIC_NONE;
    return a->ui.vibration ? h : UI_HAPTIC_NONE;
}

/* ------------------------------------------------------------------ frames and audio */

#ifdef PNS_TEST
void app_test_command(MobileApp *a, const char *cmd)
{
    int n;
    if (sscanf(cmd, "bonus %d", &n) == 1) a->test_bonus = n;
}

/* as tools/uisim's bonus:N, once the ball is in the bottom half of a table */
#define PBR (a->pb->rom)
static void test_step(MobileApp *a)
{
    GBC *g = &a->pb->g;
    uint8_t st = gbc_read(g, W_CurrentStage);
    if (gbc_read(g, W_CurrentScreen) == SCREEN_PINBALL_GAME && pb_stage_table(a->pb, st) >= 0 && (st & 1) &&
        !gbc_read(g, W_InSpecialMode) && gbc_read(g, W_PinballIsVisible) && !gbc_read(g, W_GoingToBonusStage)) {
        gbc_write(g, W_GoingToBonusStage, 1);
        gbc_write(g, W_MoveToNextScreenState, 1);
        gbc_write(g, W_NextStage, (uint8_t)a->test_bonus);
        a->test_bonus = 0;
    }
}
#undef PBR
#endif

#ifdef APP_PROF
/* tools (uisim perf): milliseconds spent in the game's frames, the picture (the filter of its
 * flicker, the composition of its background) */
double app_prof[3];
static double prof_now(void)
{
    struct timespec t;
    timespec_get(&t, TIME_UTC);
    return t.tv_sec * 1000.0 + t.tv_nsec / 1e6;
}
#define PROF(i, stmt) do { double t0_ = prof_now(); stmt; app_prof[i] += prof_now() - t0_; } while (0)
#else
#define PROF(i, stmt) stmt
#endif

void app_run_frame(MobileApp *a)
{
    if (!app_running(a)) return;
    screen_context(&a->scr, a->pb, &a->ui);
#ifdef PNS_TEST
    if (a->test_bonus) test_step(a);
#endif
    PROF(0, pb_run_frame(a->pb, ui_buttons(&a->ui)));
    a->frame_seq++;
    PROF(1, screen_new_picture(&a->scr, a->pb, &a->ui));
    int16_t tmp[4096];
    int n;
    while ((n = pb_audio(a->pb, tmp, 2048)) > 0) {
        if (!a->ui.sound) continue;
        uint32_t w = atomic_load_explicit(&a->ring_w, memory_order_relaxed);
        uint32_t r = atomic_load_explicit(&a->ring_r, memory_order_acquire);
        uint32_t room = APP_RING - (w - r);
        if ((uint32_t)n > room) n = (int)room;       /* far ahead of the sound card: drop */
        for (int i = 0; i < n; i++) {
            uint32_t k = (w + (uint32_t)i) & (APP_RING - 1);
            a->ring[k * 2] = tmp[i * 2];
            a->ring[k * 2 + 1] = tmp[i * 2 + 1];
        }
        atomic_store_explicit(&a->ring_w, w + (uint32_t)n, memory_order_release);
    }
    a->rumble = a->ui.vibration && pb_rumble(a->pb);
}

void app_audio_pad(MobileApp *a, uint32_t level)
{
    uint32_t w = atomic_load_explicit(&a->ring_w, memory_order_relaxed);
    uint32_t r = atomic_load_explicit(&a->ring_r, memory_order_acquire);
    if (level > APP_RING / 2) level = APP_RING / 2;
    if (w - r >= level) return;
    for (uint32_t i = w - r; i < level; i++) {
        uint32_t k = (r + i) & (APP_RING - 1);
        a->ring[k * 2] = a->ring[k * 2 + 1] = 0;
    }
    atomic_store_explicit(&a->ring_w, r + level, memory_order_release);
}

void app_audio_drop(MobileApp *a, uint32_t frames)
{
    atomic_store_explicit(&a->ring_drop, frames, memory_order_release);    /* done by the audio thread */
}

void app_set_audio_rate(MobileApp *a, double rate)
{
    if (a->pb) pb_set_audio_rate(a->pb, rate);
}

uint32_t app_audio_queued(MobileApp *a)
{
    return atomic_load_explicit(&a->ring_w, memory_order_acquire) - atomic_load_explicit(&a->ring_r, memory_order_acquire);
}

int app_audio_pull(MobileApp *a, int16_t *out, int frames)
{
    uint32_t r = atomic_load_explicit(&a->ring_r, memory_order_relaxed);
    uint32_t w = atomic_load_explicit(&a->ring_w, memory_order_acquire);
    if (atomic_exchange_explicit(&a->ring_flush, false, memory_order_acq_rel)) r = w;
    uint32_t drop = atomic_exchange_explicit(&a->ring_drop, 0, memory_order_acq_rel);
    if (drop) r += drop < w - r ? drop : w - r;
    uint32_t avail = w - r;
    int n = (uint32_t)frames < avail ? frames : (int)avail;
    for (int i = 0; i < n; i++) {
        uint32_t k = (r + (uint32_t)i) & (APP_RING - 1);
        out[i * 2] = a->ring[k * 2];
        out[i * 2 + 1] = a->ring[k * 2 + 1];
    }
    if (n < frames) memset(out + n * 2, 0, (size_t)(frames - n) * 4);     /* underrun: silence */
    atomic_store_explicit(&a->ring_r, r + (uint32_t)n, memory_order_release);
    return n;
}

/* ------------------------------------------------------------------ the game's key configuration */

/* The touch keys press the buttons of the game's default key configuration: another one, made in
 * the game or kept by a cartridge save, is put back (pb_fix_key_config), and out of a game the
 * game is restarted, so that it writes its own defaults in the cartridge save. */
static void keys_guard(MobileApp *a)
{
    if (!a->pb) return;
    int r = pb_fix_key_config(a->pb);
    if (!r) return;
    sram_flush_now(a);
    if (r == 2) start_game(a, false);
    ui_toast(&a->ui, "Game key config reset to the defaults", 4);
}

/* ------------------------------------------------------------------ menu, timers */

void app_update(MobileApp *a, double now)
{
    a->now = now;
    a->ui.now = now;
    int act = ui_take_action(&a->ui);
    switch (act) {
    case UI_ACT_OPEN_MENU: ui_open_menu(&a->ui, true); break;
    case UI_ACT_RESUME: ui_open_menu(&a->ui, false); break;
    case UI_ACT_QUICKSAVE:
        if (!a->pb) { ui_toast(&a->ui, "No game running", 3); break; }
        ui_open_menu(&a->ui, false);
        ui_toast(&a->ui, state_save(a, "quick.state") ? "Game saved" : "Saving failed", 3);
        break;
    case UI_ACT_QUICKLOAD:
        if (!a->pb) { ui_toast(&a->ui, "No game running", 3); break; }
        ui_open_menu(&a->ui, false);
        ui_toast(&a->ui, state_load(a, "quick.state") ? "Quick save loaded" : "No quick save yet", 3);
        break;
    case UI_ACT_TOGGLE_VIBRATION:
        a->ui.vibration = !a->ui.vibration;
        a->vibration_test = a->ui.vibration;            /* a pulse: the player feels whether it works */
        settings_save(a);
        break;
    case UI_ACT_TOGGLE_SOUND:
        a->ui.sound = !a->ui.sound;
        a->sound_changed = true;
        settings_save(a);
        break;
    case UI_ACT_TOGGLE_MOTION:
        a->ui.motion = !a->ui.motion;
        settings_save(a);
        break;
    case UI_ACT_NEXT_FILTER:
        a->ui.filter = (a->ui.filter + 1) % UI_FILTERS;
        settings_save(a);
        break;
    case UI_ACT_NEXT_TOUCH:
        a->ui.touch_mode = (a->ui.touch_mode + 1) % UI_TOUCHES;
        settings_save(a);
        break;
    case UI_ACT_TOGGLE_CONTROLS:
        a->ui.hide_controls = !a->ui.hide_controls;
        settings_save(a);
        break;
    case UI_ACT_NEXT_GAME:
        switch_game(a);
        break;
    case UI_ACT_NEXT_COLORS:
        a->ui.colors = (a->ui.colors + 1) % UI_COLORSETS;
        settings_save(a);
        break;
    case UI_ACT_ABOUT:
        a->ui.about_open = true;
        a->ui.about_page = 0;
        a->ui.menu_hot = -1;
        break;
    case UI_ACT_RESET:
        ui_open_menu(&a->ui, false);
        if (a->rom) {
            sram_flush_now(a);
            char p[600];
            game_path(a, a->gen, "suspend.state", p, sizeof p);
            remove(p);
            start_game(a, false);
            ui_toast(&a->ui, "Game restarted", 2);
        }
        break;
    case UI_ACT_QUIT:
        ui_open_menu(&a->ui, false);
        a->quit = true;
        break;
    default:
        break;
    }
    if (a->pb && now >= a->next_sav_check) {
        a->next_sav_check = now + 1.0;
        keys_guard(a);
        sram_flush(a);
    }
}

void app_suspend(MobileApp *a)
{
    if (!a->pb) return;
    sram_flush_now(a);                                  /* everything now: the app may stop */
    bool async = a->io_async;
    a->io_async = false;
    state_save(a, "suspend.state");
    settings_save(a);
    a->io_async = async;
}

void app_build(MobileApp *a, UiList *l) { screen_build(&a->scr, a->pb, &a->ui, l); }

const uint32_t *app_frame(MobileApp *a, int *w, int *h, int *stride) { return screen_frame(&a->scr, a->pb, &a->ui, w, h, stride); }

const uint32_t *app_game(MobileApp *a, int *w, int *h, int *stride) { return screen_game(&a->scr, a->pb, &a->ui, w, h, stride); }
