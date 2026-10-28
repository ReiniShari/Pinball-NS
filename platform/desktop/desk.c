/*
 * desk.c - what the desktop versions share (see desk.h).
 */
#include "desk.h"
#include "../../src/front/font5x7.h"
#include <math.h>
#include <stdlib.h>
#include <string.h>
#ifdef _WIN32
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
#else
#include <pthread.h>
#include <unistd.h>
#endif

/* ------------------------------------------------------------------ names */

const uint8_t desk_act_button[ACT_N] = { GBC_LEFT, GBC_A, GBC_DOWN, GBC_B, GBC_SELECT, GBC_START, GBC_UP, GBC_RIGHT };
static const char *const act_id[ACT_N] = { "left", "a", "down", "b", "select", "start", "up", "right" };
const char *const desk_act_name[ACT_N] = {
    "Left flipper, menus left", "Right flipper, launch, OK", "Left tilt, menus down", "Right tilt, back",
    "Upper tilt", "Pause menu", "Menus up", "Menus right" };
const char *const desk_act_gb[ACT_N] = { "Left", "A", "Down", "B", "Select", "Start", "Up", "Right" };
const char *const desk_pad_name[PAD_N] = {
    "D-pad up", "D-pad down", "D-pad left", "D-pad right", "Start", "Back", "Left stick click",
    "Right stick click", "LB", "RB", "Guide", "?", "A", "B", "X", "Y",
    "LT", "RT", "Left stick left", "Left stick right", "Left stick up", "Left stick down" };

static const uint16_t def_keys[ACT_N][DESK_MAXB] = {
    { DK_LSHIFT, 'Z', 'W', DK_LEFT }, { DK_RSHIFT, 'X', DK_SPACE }, { DK_DOWN }, { 'C', DK_BACK },
    { 'V', DK_TAB }, { DK_RETURN }, { DK_UP }, { DK_RIGHT } };
static const uint8_t def_pad[ACT_N][DESK_MAXB] = {
    { PAD_LB + 1, PAD_LT + 1, PAD_DLEFT + 1, PAD_LS_LEFT + 1 }, { PAD_RB + 1, PAD_RT + 1, PAD_A + 1 },
    { PAD_DDOWN + 1, PAD_LS_DOWN + 1 }, { PAD_B + 1, PAD_X + 1 }, { PAD_Y + 1, PAD_BACK + 1 }, { PAD_START + 1 },
    { PAD_DUP + 1, PAD_LS_UP + 1 }, { PAD_DRIGHT + 1, PAD_LS_RIGHT + 1 } };

/* the names of the keys, in English whatever the system's language */
static void key_name(unsigned vk, char *out, size_t n)
{
    static const struct { unsigned vk; const char *name; } names[] = {
        { DK_LSHIFT, "Left Shift" }, { DK_RSHIFT, "Right Shift" }, { DK_SHIFT, "Shift" }, { DK_LCONTROL, "Left Ctrl" },
        { DK_RCONTROL, "Right Ctrl" }, { DK_CONTROL, "Ctrl" }, { DK_LALT, "Left Alt" }, { DK_RALT, "Right Alt" },
        { DK_ALT, "Alt" }, { DK_LEFT, "Left" }, { DK_RIGHT, "Right" }, { DK_UP, "Up" }, { DK_DOWN, "Down" },
        { DK_SPACE, "Space" }, { DK_RETURN, "Enter" }, { DK_TAB, "Tab" }, { DK_BACK, "Backspace" }, { DK_INSERT, "Insert" },
        { DK_DELETE, "Delete" }, { DK_HOME, "Home" }, { DK_END, "End" }, { DK_PGUP, "Page Up" }, { DK_PGDN, "Page Down" },
        { DK_CAPS, "Caps Lock" }, { DK_LWIN, "Left Super" }, { DK_RWIN, "Right Super" }, { DK_APPS, "Menu" },
        { DK_MULTIPLY, "Num *" }, { DK_ADD, "Num +" }, { DK_SUBTRACT, "Num -" }, { DK_DECIMAL, "Num ." }, { DK_DIVIDE, "Num /" },
        { DK_SEMICOLON, ";" }, { DK_EQUALS, "=" }, { DK_COMMA, "," }, { DK_MINUS, "-" }, { DK_PERIOD, "." }, { DK_SLASH, "/" },
        { DK_GRAVE, "`" }, { DK_LBRACKET, "[" }, { DK_BACKSLASH, "\\" }, { DK_RBRACKET, "]" }, { DK_QUOTE, "'" },
    };
    for (size_t i = 0; i < sizeof names / sizeof names[0]; i++)
        if (names[i].vk == vk) { snprintf(out, n, "%s", names[i].name); return; }
    if (vk >= DK_NUM0 && vk <= DK_NUM9) { snprintf(out, n, "Num %u", vk - DK_NUM0); return; }
    if (vk >= DK_F1 && vk <= DK_F24) { snprintf(out, n, "F%u", vk - DK_F1 + 1); return; }
    if ((vk >= '0' && vk <= '9') || (vk >= 'A' && vk <= 'Z')) { snprintf(out, n, "%c", (char)vk); return; }
    snprintf(out, n, "Key %02X", vk);
}

/* ------------------------------------------------------------------ files */

FILE *desk_fopen(const char *path, const char *mode)
{
#ifdef _WIN32
    wchar_t wp[DESK_PATH], wm[8];
    if (!MultiByteToWideChar(CP_UTF8, 0, path, -1, wp, DESK_PATH)) return NULL;
    MultiByteToWideChar(CP_UTF8, 0, mode, -1, wm, 8);
    return _wfopen(wp, wm);
#else
    return fopen(path, mode);
#endif
}

bool desk_read(const char *path, uint8_t **data, size_t *size, size_t max)
{
    FILE *f = desk_fopen(path, "rb");
    if (!f) return false;
    fseek(f, 0, SEEK_END);
    long n = ftell(f);
    fseek(f, 0, SEEK_SET);
    if (n <= 0 || (size_t)n > max) { fclose(f); return false; }
    uint8_t *buf = (uint8_t *)malloc((size_t)n + 1);
    if (!buf) { fclose(f); return false; }
    size_t r = fread(buf, 1, (size_t)n, f);
    fclose(f);
    if (r != (size_t)n) { free(buf); return false; }
    buf[n] = 0;
    *data = buf;
    *size = (size_t)n;
    return true;
}

/* through a temporary file, so that a crash never leaves half a file */
bool desk_write(const char *path, const void *data, size_t size)
{
    char tmp[DESK_PATH + 8];
    snprintf(tmp, sizeof tmp, "%s.tmp", path);
    FILE *f = desk_fopen(tmp, "wb");
    if (!f) return false;
    bool ok = fwrite(data, 1, size, f) == size;
    ok = (fclose(f) == 0) && ok;
#ifdef _WIN32
    wchar_t wt[DESK_PATH + 8], wp[DESK_PATH];
    MultiByteToWideChar(CP_UTF8, 0, tmp, -1, wt, DESK_PATH + 8);
    MultiByteToWideChar(CP_UTF8, 0, path, -1, wp, DESK_PATH);
    if (!ok) { DeleteFileW(wt); return false; }
    return MoveFileExW(wt, wp, MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH) != 0;
#else
    if (!ok) { remove(tmp); return false; }
    return rename(tmp, path) == 0;
#endif
}

static void replace_ext(char *dst, size_t n, const char *src, const char *ext)
{
    snprintf(dst, n, "%s", src);
    char *dot = strrchr(dst, '.'), *sl = strrchr(dst, '/'), *bs = strrchr(dst, '\\');
    if (bs > sl) sl = bs;
    if (dot && (!sl || dot > sl)) *dot = 0;
    if (strlen(dst) + strlen(ext) < n) strcat(dst, ext);
}

/* ------------------------------------------------------------------ the writer of the cartridge save */

/* The disk can take tens of milliseconds (a flush): the cartridge save is written by a thread of its
 * own, one at a time (a new one waits for the next check if the previous one is still being written). */
static struct {
    bool started, failed;
    int state;                  /* 0: free, 1: waiting for the writer, 2: being written */
    char path[DESK_PATH];
    uint8_t data[0x8000];
    size_t size;
#ifdef _WIN32
    CRITICAL_SECTION lock;
    HANDLE wake;
#else
    pthread_mutex_t lock;
    pthread_cond_t wake;
#endif
} io;

#ifdef _WIN32
#define IO_LOCK() EnterCriticalSection(&io.lock)
#define IO_UNLOCK() LeaveCriticalSection(&io.lock)
#else
#define IO_LOCK() pthread_mutex_lock(&io.lock)
#define IO_UNLOCK() pthread_mutex_unlock(&io.lock)
#endif

static void io_work(void)
{
    for (;;) {
        IO_LOCK();
#ifdef _WIN32
        while (io.state != 1) { IO_UNLOCK(); WaitForSingleObject(io.wake, INFINITE); IO_LOCK(); }
#else
        while (io.state != 1) pthread_cond_wait(&io.wake, &io.lock);
#endif
        io.state = 2;
        IO_UNLOCK();
        bool ok = desk_write(io.path, io.data, io.size);       /* (the data are not touched while it is 2) */
        IO_LOCK();
        io.failed = !ok;
        io.state = 0;
        IO_UNLOCK();
    }
}

#ifdef _WIN32
static DWORD WINAPI io_main(LPVOID arg) { (void)arg; io_work(); return 0; }
#else
static void *io_main(void *arg) { (void)arg; io_work(); return NULL; }
#endif

static void io_start(void)
{
    if (io.started) return;
#ifdef _WIN32
    InitializeCriticalSection(&io.lock);
    io.wake = CreateEventW(NULL, FALSE, FALSE, NULL);
    HANDLE t = io.wake ? CreateThread(NULL, 0, io_main, NULL, 0, NULL) : NULL;
    if (!t) return;
    CloseHandle(t);
#else
    pthread_mutex_init(&io.lock, NULL);
    pthread_cond_init(&io.wake, NULL);
    pthread_t t;
    if (pthread_create(&t, NULL, io_main, NULL) != 0) return;
    pthread_detach(t);
#endif
    io.started = true;
}

static int io_busy(void)
{
    if (!io.started) return 0;
    IO_LOCK();
    int s = io.state;
    IO_UNLOCK();
    return s;
}

/* until the writer has nothing left (before another ROM, the end, a forced write) */
static void io_wait(void)
{
    for (int i = 0; i < 3000 && io_busy(); i++) {
#ifdef _WIN32
        Sleep(1);
#else
        usleep(1000);
#endif
    }
}

/* ------------------------------------------------------------------ settings */

void desk_map_defaults(Desk *d)
{
    memcpy(d->keymap, def_keys, sizeof d->keymap);
    memcpy(d->padmap, def_pad, sizeof d->padmap);
}

bool desk_key_reserved(unsigned vk)
{
    return (vk >= DK_F(1) && vk <= DK_F(11)) || vk == 'P' || vk == DK_PAUSE || vk == DK_ESCAPE;
}

static int cfg_int(const char *buf, const char *key, int lo, int hi, int def)
{
    const char *q = strstr(buf, key);
    if (!q) return def;
    int v = atoi(q + strlen(key));
    return v < lo || v > hi ? def : v;
}

static void cfg_str(const char *buf, const char *key, char *out, size_t n)
{
    const char *q = strstr(buf, key);
    if (!q) return;
    q += strlen(key);
    size_t k = 0;
    while (*q && *q != '\r' && *q != '\n' && k + 1 < n) out[k++] = *q++;
    out[k] = 0;
}

/* "narrow=0/1", "smooth=0/1", "filter=0-2", "colors=0-2", the handheld mode's settings, the last ROM of
 * each game, and for each button "keys.NAME=" virtual keys and "pad.NAME=" gamepad inputs (hexadecimal) */
static void cfg_load(Desk *d)
{
    desk_map_defaults(d);
    uint8_t *data;
    size_t n;
    if (!desk_read(d->cfg_path, &data, &n, 16384)) return;
    const char *buf = (const char *)data;
    d->narrow = cfg_int(buf, "narrow=", 0, 1, 0);
    d->smooth = cfg_int(buf, "smooth=", 0, 1, 0);
    d->filter = cfg_int(buf, "filter=", 0, FX_FILTERS - 1, 0);
    d->colors = cfg_int(buf, "colors=", 0, FX_COLORSETS - 1, 0);
    d->handheld = cfg_int(buf, "handheld=", 0, 1, 0);
    d->sound = cfg_int(buf, "sound=", 0, 1, 1);
    d->vibration = cfg_int(buf, "vibration=", 0, 1, 1);
    d->ui.hide_controls = cfg_int(buf, "controls=", 0, 1, 0);
    d->ui.touch_mode = cfg_int(buf, "touch=", 0, UI_TOUCHES - 1, UI_TOUCH_TILT);
    cfg_str(buf, "rom=", d->rom_paths[0], DESK_PATH);
    cfg_str(buf, "rom_gen=", d->rom_paths[1], DESK_PATH);
    for (int a = 0; a < ACT_N; a++)
        for (int pad = 0; pad < 2; pad++) {
            char key[32];
            snprintf(key, sizeof key, "%s.%s=", pad ? "pad" : "keys", act_id[a]);
            const char *q = strstr(buf, key);
            if (!q) continue;                          /* not saved yet: the defaults */
            q += strlen(key);
            int k = 0;
            if (pad) memset(d->padmap[a], 0, sizeof d->padmap[a]); else memset(d->keymap[a], 0, sizeof d->keymap[a]);
            while (k < DESK_MAXB && *q && *q != '\r' && *q != '\n') {
                char *e;
                unsigned long v = strtoul(q, &e, 16);
                if (e == q) break;
                if (pad ? v < PAD_N : (v > 0 && v < 256 && !desk_key_reserved((unsigned)v))) {
                    if (pad) d->padmap[a][k++] = (uint8_t)(v + 1); else d->keymap[a][k++] = (uint16_t)v;
                }
                q = e;
                while (*q == ' ' || *q == ',') q++;
            }
        }
    free(data);
}

void desk_cfg_save(Desk *d)
{
    char buf[8192];
    int n = snprintf(buf, sizeof buf, "narrow=%d\r\nsmooth=%d\r\nfilter=%d\r\ncolors=%d\r\nhandheld=%d\r\ncontrols=%d\r\ntouch=%d\r\n"
                     "sound=%d\r\nvibration=%d\r\nrom=%s\r\nrom_gen=%s\r\n",
                     d->narrow, d->smooth, d->filter, d->colors, d->handheld, d->ui.hide_controls, d->ui.touch_mode, d->sound,
                     d->vibration, d->rom_paths[0], d->rom_paths[1]);
    for (int a = 0; a < ACT_N; a++)
        for (int pad = 0; pad < 2; pad++) {
            n += snprintf(buf + n, sizeof buf - (size_t)n, "%s.%s=", pad ? "pad" : "keys", act_id[a]);
            for (int k = 0; k < DESK_MAXB; k++) {
                unsigned v = pad ? d->padmap[a][k] : d->keymap[a][k];
                if (v) n += snprintf(buf + n, sizeof buf - (size_t)n, "%X ", pad ? v - 1 : v);
            }
            n += snprintf(buf + n, sizeof buf - (size_t)n, "\r\n");
        }
    desk_write(d->cfg_path, buf, (size_t)n);
}

/* ------------------------------------------------------------------ the game */

/* the first page ABOUT of the handheld mode, in the words of a computer */
static const char *const HANDHELD_HINT =
    "GAME TOUCH: TILT: the left, middle or right third of the game gives the left, upper or right tilt. "
    "FLIPPERS: its halves play the flippers.\n\n"
    "CONTROLS: HIDDEN (F4): in a game, MENU and START only; under the game, the halves of the window play the "
    "flippers.\n\n"
    "KEYS AND GAMEPADS: F2 changes them. F3: the table alone.\n\n"
    "GAME: switches to the other game once its ROM has been opened here (drag it onto the window).\n\n"
    "Tap for more.";

void desk_init(Desk *d, const char *cfg_path)
{
    memset(d, 0, sizeof *d);
    snprintf(d->cfg_path, sizeof d->cfg_path, "%s", cfg_path);
    d->pad_in = -1;
    d->sound = d->vibration = true;
    ui_init(&d->ui);
    screen_init(&d->scr);
    d->ui.menu_hide = 1u << UI_ENTRY_MOTION;                 /* no accelerometer */
    d->ui.about_hint = HANDHELD_HINT;
    d->ui.no_rom_how = "Drop it onto this window, or choose it in the window shown at the start.\n\n";
    cfg_load(d);
    d->ui.sound = d->sound;
    d->ui.vibration = d->vibration;
    d->ui.no_rom = true;
    io_start();
    font_init();
}

void desk_free(Desk *d)
{
    if (d->pb) { desk_sram_flush(d, false, false); pb_free(d->pb); free(d->pb); d->pb = NULL; }
    free(d->rom);
    d->rom = NULL;
    deflicker_free(&d->defl);
    screenfx_free(&d->fx);
    screen_free(&d->scr);
    free(d->text_buf);
    d->text_buf = NULL;
}

void desk_osd(Desk *d, const char *msg)
{
    if (d->handheld) { ui_toast(&d->ui, msg, 2.5); return; }
    snprintf(d->osd, sizeof d->osd, "%s", msg);
    d->osd_until = d->now + 2.0;
}

static void sram_load(Desk *d)
{
    uint8_t *data;
    size_t n;
    if (desk_read(d->sav_path, &data, &n, 0x8000)) {
        pb_load_sram(d->pb, data, n);
        free(data);
    }
    const uint8_t *s = pb_sram(d->pb, &d->sav_last_size);
    memcpy(d->sav_last, s, d->sav_last_size);
}

void desk_sram_flush(Desk *d, bool force, bool later)
{
    if (!d->pb) return;
    size_t n;
    const uint8_t *s = pb_sram(d->pb, &n);
    if (n == 0 || n > sizeof d->sav_last) return;
    if (io.started) {
        IO_LOCK();
        if (io.failed) { io.failed = false; d->sav_last_size = 0; }          /* it failed: again */
        IO_UNLOCK();
    }
    if (!force && n == d->sav_last_size && memcmp(s, d->sav_last, n) == 0) return;
    if (later && io.started) {
        IO_LOCK();
        bool free_ = io.state == 0;
        if (free_) {
            memcpy(io.data, s, n);
            io.size = n;
            snprintf(io.path, sizeof io.path, "%s", d->sav_path);
            io.state = 1;
        }
        IO_UNLOCK();
        if (!free_) return;                                    /* the previous one first */
#ifdef _WIN32
        SetEvent(io.wake);
#else
        pthread_cond_signal(&io.wake);
#endif
    } else {
        io_wait();
        if (!desk_write(d->sav_path, s, n)) return;
    }
    memcpy(d->sav_last, s, n);
    d->sav_last_size = n;
}

void desk_state_save(Desk *d)
{
    if (!d->pb) return;
    size_t n = pb_snapshot_size();
    void *buf = malloc(n);
    if (!buf) return;
    pb_snapshot_save(d->pb, buf);
    desk_osd(d, desk_write(d->state_path, buf, n) ? "State saved (F9 to load it)" : "The state could not be saved");
    free(buf);
}

void desk_state_load(Desk *d)
{
    if (!d->pb) return;
    uint8_t *data;
    size_t n;
    if (!desk_read(d->state_path, &data, &n, 64u << 20)) { desk_osd(d, "No saved state (F5 to save one)"); return; }
    desk_osd(d, pb_snapshot_load(d->pb, data, n) == 0 ? "State loaded" : "This saved state cannot be loaded");
    free(data);
}

bool desk_open_rom(Desk *d, const char *path, char *err, size_t errn)
{
    uint8_t *data;
    size_t n;
    if (!desk_read(path, &data, &n, 8u << 20)) { snprintf(err, errn, "This file cannot be read:\n%s", path); return false; }
    Pinball *np = (Pinball *)calloc(1, sizeof(Pinball));
    if (!np) { free(data); snprintf(err, errn, "Not enough memory."); return false; }
    if (pb_init(np, data, n, DESK_RATE) != 0) {
        snprintf(err, errn, "This is not the expected ROM.\n\nPinball NS needs the ROM dumped from your own Pokémon Pinball "
                 "cartridge (US version, Pokémon Pinball (USA, Australia) (Rumble Version)), or Pokémon Pinball Generations 1.6 "
                 "(its patch applied to that ROM).");
        pb_free(np);
        free(np);
        free(data);
        return false;
    }
    if (d->pb) { desk_sram_flush(d, false, false); pb_free(d->pb); free(d->pb); }
    free(d->rom);
    d->pb = np;
    d->rom = data;
    d->rom_size = n;
    pb_set_narrow(np, d->narrow || d->handheld);       /* (the handheld mode: the original width, as Android) */
    pb_set_antilag(np, true);                   /* no frame skipped by the game (see pinball.h) */
    pb_set_double_speed(np, true);              /* the double speed of Generations, original ROM too */
    pb_set_frame_palettes(np, true);            /* no picture torn by a change of colours */
    pb_set_hold(np, true);                      /* the screen off (loadings): the last picture stays */
    pb_set_audio_highpass(np, GBC_HIGHPASS_FRONT);      /* the bass of the music (gbc.h) */
    nd_set_flipper(pb_flipper_tiles(np));       /* the game's flipper in the keys of the handheld mode */
    d->shown = NULL;                          /* the old game's picture: not this one's size */
    snprintf(d->rom_path, sizeof d->rom_path, "%s", path);
    replace_ext(d->sav_path, sizeof d->sav_path, path, ".sav");
    replace_ext(d->state_path, sizeof d->state_path, path, ".state");
    bool gen = np->rom->id == PB_ROM_GENERATIONS;
    snprintf(d->rom_paths[gen], DESK_PATH, "%s", path);
    sram_load(d);
    screen_reset(&d->scr, d->ui.table);
    d->ui.no_rom = false;
    d->ui.game_gen = gen;
    d->ui.other_game = d->rom_paths[!gen][0] != 0;
    desk_cfg_save(d);
    return true;
}

/* ------------------------------------------------------------------ input */

uint8_t desk_buttons(Desk *d)
{
    uint8_t m = 0;
    for (int a = 0; a < ACT_N; a++)
        for (int k = 0; k < DESK_MAXB; k++) {
            unsigned vk = d->keymap[a][k];
            if (vk && vk < 256 && d->key_down[vk]) m |= desk_act_button[a];
        }
    d->kb_buttons = d->page ? 0 : m;
    uint8_t p = 0;
    if (d->pad_in > 0 && !d->page)
        for (int a = 0; a < ACT_N; a++)
            for (int k = 0; k < DESK_MAXB; k++)
                if (d->padmap[a][k] && (d->pad_in & (1L << (d->padmap[a][k] - 1)))) p |= desk_act_button[a];
    d->pad_buttons = p;
    if (d->handheld) {
        ui_set_external_buttons(&d->ui, (uint8_t)(d->kb_buttons | d->pad_buttons));
        return ui_buttons(&d->ui);
    }
    return (uint8_t)(d->kb_buttons | d->pad_buttons);
}

void desk_keys_released(Desk *d)
{
    memset(d->key_down, 0, sizeof d->key_down);
    d->kb_buttons = 0;
}

/* the controls page: one button per input (taken off the others), at most DESK_MAXB per button (the
 * oldest goes) */
static void ctl_bind(Desk *d, int a, int col, unsigned v)
{
    for (int b = 0; b < ACT_N; b++)
        for (int k = 0; k < DESK_MAXB; k++) {
            unsigned cur = col == 0 ? d->keymap[b][k] : d->padmap[b][k];
            if (cur != (col == 0 ? v : v + 1)) continue;
            for (int j = k; j < DESK_MAXB - 1; j++) {
                if (col == 0) d->keymap[b][j] = d->keymap[b][j + 1]; else d->padmap[b][j] = d->padmap[b][j + 1];
            }
            if (col == 0) d->keymap[b][DESK_MAXB - 1] = 0; else d->padmap[b][DESK_MAXB - 1] = 0;
            k--;
        }
    int k = 0;
    while (k < DESK_MAXB && (col == 0 ? d->keymap[a][k] : d->padmap[a][k])) k++;
    if (k == DESK_MAXB) {
        for (int j = 0; j < DESK_MAXB - 1; j++) {
            if (col == 0) d->keymap[a][j] = d->keymap[a][j + 1]; else d->padmap[a][j] = d->padmap[a][j + 1];
        }
        k = DESK_MAXB - 1;
    }
    if (col == 0) d->keymap[a][k] = (uint16_t)v; else d->padmap[a][k] = (uint8_t)(v + 1);
    desk_cfg_save(d);
    d->ctl_msg[0] = 0;
}

static int controls_key(Desk *d, unsigned vk)
{
    if (d->ctl_wait) {
        if (vk == DK_ESCAPE) { d->ctl_wait = false; d->ctl_msg[0] = 0; }
        else if (vk == DK_DELETE) {
            if (d->ctl_col == 0) memset(d->keymap[d->ctl_row], 0, sizeof d->keymap[0]);
            else memset(d->padmap[d->ctl_row], 0, sizeof d->padmap[0]);
            desk_cfg_save(d);
            d->ctl_wait = false;
            d->ctl_msg[0] = 0;
        } else if (d->ctl_col == 0) {
            if (desk_key_reserved(vk)) snprintf(d->ctl_msg, sizeof d->ctl_msg, "F1 to F11, P, Pause and Esc are kept by Pinball NS.");
            else { ctl_bind(d, d->ctl_row, 0, vk); d->ctl_wait = false; }
        }
        return DESK_REDRAW;
    }
    switch (vk) {
    case DK_ESCAPE: case DK_F(2): d->page = PAGE_NONE; desk_cfg_save(d); break;
    case DK_UP: d->ctl_row = (d->ctl_row + ACT_N - 1) % ACT_N; break;
    case DK_DOWN: d->ctl_row = (d->ctl_row + 1) % ACT_N; break;
    case DK_LEFT: case DK_RIGHT: d->ctl_col = !d->ctl_col; break;
    case DK_DELETE: case DK_BACK:
        if (d->ctl_col == 0) memset(d->keymap[d->ctl_row], 0, sizeof d->keymap[0]);
        else memset(d->padmap[d->ctl_row], 0, sizeof d->padmap[0]);
        desk_cfg_save(d);
        break;
    case 'D':
        desk_map_defaults(d);
        desk_cfg_save(d);
        snprintf(d->ctl_msg, sizeof d->ctl_msg, "Default controls restored.");
        break;
    case DK_RETURN: case DK_SPACE:
        d->ctl_wait = true;
        d->ctl_pad_held = d->pad_in > 0 ? d->pad_in : 0;
        snprintf(d->ctl_msg, sizeof d->ctl_msg, d->ctl_col == 0 ? "%s: press a key (Esc: cancel, Delete: clear)"
                 : "%s: press a gamepad button (Esc: cancel, Delete: clear)%s", desk_act_name[d->ctl_row],
                 d->ctl_col == 1 && d->pad_in < 0 ? ". No gamepad found." : "");
        break;
    default: break;
    }
    return DESK_REDRAW;
}

int desk_key(Desk *d, unsigned vk, bool down, bool repeat)
{
    if (vk < 256) d->key_down[vk] = down;
    /* the sides of Shift, Ctrl and Alt count for both names */
    if (vk == DK_LSHIFT || vk == DK_RSHIFT) d->key_down[DK_SHIFT] = d->key_down[DK_LSHIFT] || d->key_down[DK_RSHIFT];
    if (vk == DK_LCONTROL || vk == DK_RCONTROL) d->key_down[DK_CONTROL] = d->key_down[DK_LCONTROL] || d->key_down[DK_RCONTROL];
    if (vk == DK_LALT || vk == DK_RALT) d->key_down[DK_ALT] = d->key_down[DK_LALT] || d->key_down[DK_RALT];
    if (!down || repeat) return DESK_NONE;
    if (d->page == PAGE_CONTROLS) return controls_key(d, vk);
    if (d->page == PAGE_ABOUT) { d->page = PAGE_NONE; return DESK_REDRAW; }
    if (vk == DK_RETURN && d->key_down[DK_ALT]) return DESK_FULLSCREEN;
    switch (vk) {
    case DK_F(11): return DESK_FULLSCREEN;
    case DK_F(1):
        if (d->own_pages) return DESK_ABOUT;
        d->page = PAGE_ABOUT;
        return DESK_REDRAW;
    case DK_F(2):
        if (d->own_pages) return DESK_CONTROLS;
        d->page = PAGE_CONTROLS;
        d->ctl_wait = false;
        d->ctl_msg[0] = 0;
        return DESK_REDRAW;
    case DK_F(3):
        d->handheld = !d->handheld;
        if (d->pb) pb_set_narrow(d->pb, d->narrow || d->handheld);
        d->osd[0] = 0;
        ui_open_menu(&d->ui, false);
        desk_cfg_save(d);
        desk_osd(d, d->handheld ? "Handheld mode (F3: the table alone)" : "The table alone (F3: handheld mode)");
        return DESK_RESHAPE;
    case DK_F(4):
        d->ui.hide_controls = !d->ui.hide_controls;
        desk_cfg_save(d);
        desk_osd(d, d->ui.hide_controls ? "Touch keys hidden in a game (F4)" : "Touch keys shown (F4)");
        return DESK_REDRAW;
    case DK_F(5): desk_state_save(d); return DESK_REDRAW;
    case DK_F(9): desk_state_load(d); return DESK_REDRAW;
    case DK_F(6):
        d->filter = (d->filter + 1) % FX_FILTERS;
        d->ui.filter = d->filter;
        desk_cfg_save(d);
        desk_osd(d, d->filter == FX_FILTER_DOT ? "Screen filter: dots (F6)" : d->filter == FX_FILTER_LCD ? "Screen filter: LCD (F6)" : "Screen filter: none (F6)");
        return DESK_REDRAW;
    case DK_F(7):
        d->colors = (d->colors + 1) % FX_COLORSETS;
        d->ui.colors = d->colors;
        desk_cfg_save(d);
        desk_osd(d, d->colors == FX_COLORS_BW ? "Colours: black and white (F7)" : d->colors == FX_COLORS_GREEN ? "Colours: Game Boy green (F7)" : "Colours: original (F7)");
        return DESK_REDRAW;
    case DK_F(8):
        d->narrow = !d->narrow;
        if (d->pb) pb_set_narrow(d->pb, d->narrow || d->handheld);
        desk_cfg_save(d);
        desk_osd(d, d->narrow ? "Table: original width (F8)" : "Table: whole (F8)");
        return d->handheld ? DESK_REDRAW : DESK_RESHAPE;
    case DK_F(10):
        d->smooth = !d->smooth;
        desk_cfg_save(d);
        return DESK_REDRAW;
    case 'P': case DK_PAUSE:
        d->paused = !d->paused;
        return DESK_PAUSE;
    case DK_ESCAPE:
        if (d->handheld && !d->ui.no_rom) { ui_open_menu(&d->ui, !d->ui.menu_open); return DESK_REDRAW; }
        return DESK_LEAVE_FULLSCREEN;
    default: return DESK_NONE;
    }
}

void desk_pad(Desk *d, long inputs)
{
    d->pad_in = inputs;
    if (d->page == PAGE_CONTROLS && d->ctl_wait && d->ctl_col == 1) {
        long in = inputs > 0 ? inputs : 0, fresh = in & ~d->ctl_pad_held;
        d->ctl_pad_held &= in;                      /* released inputs can be pressed again */
        for (int i = 0; i < PAD_N; i++)
            if (fresh & (1L << i)) { ctl_bind(d, d->ctl_row, 1, (unsigned)i); d->ctl_wait = false; break; }
    }
}

void desk_pointer(Desk *d, int action, int id, float x, float y)
{
    if (d->page) {
        if (action == UI_DOWN && d->page == PAGE_ABOUT) d->page = PAGE_NONE;
        return;
    }
    if (d->handheld) ui_touch(&d->ui, action, id, x, y);
}

/* ------------------------------------------------------------------ frames */

void desk_frame(Desk *d)
{
    if (!d->pb) return;
    uint8_t b = desk_buttons(d);
    /* the game waits: paused, a page open, the menu of the handheld mode (as the phones) */
    if (d->paused || d->page || (d->handheld && d->ui.menu_open)) return;
    if (d->handheld) {
        screen_context(&d->scr, d->pb, &d->ui);
        pb_run_frame(d->pb, b);
        screen_new_picture(&d->scr, d->pb, &d->ui);
    } else {
        pb_run_frame(d->pb, b);
    }
}

bool desk_rumble(const Desk *d) { return d->pb && d->vibration && pb_rumble(d->pb); }

static void switch_game(Desk *d)
{
    bool gen = d->pb && d->pb->rom->id == PB_ROM_GENERATIONS;
    const char *other = d->rom_paths[!gen];
    if (!other[0]) {
        desk_osd(d, gen ? "Open the ROM of Pokémon Pinball (drag it onto the window)"
                        : "Open the ROM of Pokémon Pinball Generations (drag it onto the window)");
        return;
    }
    char path[DESK_PATH], err[512];
    snprintf(path, sizeof path, "%s", other);
    if (!desk_open_rom(d, path, err, sizeof err)) desk_osd(d, "The other game's ROM cannot be opened");
}

bool desk_tick(Desk *d, double now)
{
    bool redraw = false;
    d->now = now;
    d->ui.now = now;
    d->ui.filter = d->filter;
    d->ui.colors = d->colors;
    int act = ui_take_action(&d->ui);
    if (act) redraw = true;
    switch (act) {
    case UI_ACT_OPEN_MENU: ui_open_menu(&d->ui, true); break;
    case UI_ACT_RESUME: ui_open_menu(&d->ui, false); break;
    case UI_ACT_QUICKSAVE: ui_open_menu(&d->ui, false); desk_state_save(d); break;
    case UI_ACT_QUICKLOAD: ui_open_menu(&d->ui, false); desk_state_load(d); break;
    case UI_ACT_TOGGLE_VIBRATION: d->vibration = d->ui.vibration = !d->vibration; desk_cfg_save(d); break;
    case UI_ACT_TOGGLE_SOUND: d->sound = d->ui.sound = !d->sound; desk_cfg_save(d); break;
    case UI_ACT_NEXT_TOUCH: d->ui.touch_mode = (d->ui.touch_mode + 1) % UI_TOUCHES; desk_cfg_save(d); break;
    case UI_ACT_TOGGLE_CONTROLS: d->ui.hide_controls = !d->ui.hide_controls; desk_cfg_save(d); break;
    case UI_ACT_NEXT_FILTER: d->filter = d->ui.filter = (d->filter + 1) % FX_FILTERS; desk_cfg_save(d); break;
    case UI_ACT_NEXT_COLORS: d->colors = d->ui.colors = (d->colors + 1) % FX_COLORSETS; desk_cfg_save(d); break;
    case UI_ACT_NEXT_GAME: ui_open_menu(&d->ui, false); switch_game(d); break;
    case UI_ACT_ABOUT: d->ui.about_open = true; d->ui.about_page = 0; d->ui.menu_hot = -1; break;
    case UI_ACT_RESET:
        ui_open_menu(&d->ui, false);
        if (d->rom_path[0]) {
            char path[DESK_PATH], err[512];
            snprintf(path, sizeof path, "%s", d->rom_path);
            desk_open_rom(d, path, err, sizeof err);
            desk_osd(d, "Game restarted");
        }
        break;
    case UI_ACT_QUIT: ui_open_menu(&d->ui, false); d->quit = true; break;
    default: break;
    }
    if (d->osd[0] && now >= d->osd_until) { d->osd[0] = 0; redraw = true; }
    if (d->pb && now >= d->next_sav_check) {
        d->next_sav_check = now + 1.0;
        /* the game's own key configuration must stay the default one (the mapping is here) */
        int fix = pb_fix_key_config(d->pb);
        if (fix) {
            desk_sram_flush(d, true, false);
            if (fix == 2) { char p[DESK_PATH], err[512]; snprintf(p, sizeof p, "%s", d->rom_path); desk_open_rom(d, p, err, sizeof err); }
            desk_osd(d, "Game key config reset to the defaults (F2: controls)");
        }
        desk_sram_flush(d, false, true);
    }
    return redraw;
}

/* ------------------------------------------------------------------ text in the picture */

static void dim(uint32_t *p, int w, int h, int stride)
{
    for (int y = 0; y < h; y++)
        for (int x = 0; x < w; x++) {
            uint32_t c = p[(size_t)y * stride + x];
            p[(size_t)y * stride + x] = (c >> 2) & 0x3F3F3F;
        }
}

static void box(uint32_t *p, int w, int h, int stride, int x0, int y0, int bw, int bh, uint32_t col)
{
    for (int y = y0 < 0 ? 0 : y0; y < y0 + bh && y < h; y++)
        for (int x = x0 < 0 ? 0 : x0; x < x0 + bw && x < w; x++) p[(size_t)y * stride + x] = col;
}

static void text(uint32_t *p, int w, int h, int stride, int x, int y, int s, const char *str, uint32_t col)
{
    while (*str) {
        const FontGlyph *g = font_glyph(utf8_next(&str));
        for (int r = 0; r < FONT_H; r++)
            for (int k = 0; k < FONT_W; k++)
                if (g->rows[r] & (0x10 >> k)) box(p, w, h, stride, x + k * s, y + r * s, s, s, col);
        x += FONT_CELL_W * s;
    }
}

static int text_w(const char *s, int sz) { int n = utf8_len(s); return n ? (n * FONT_CELL_W - 1) * sz : 0; }

/* a paragraph cut at the spaces to `cols` letters; returns the rows used (draw: false, counted only) */
static int para(uint32_t *p, int w, int h, int stride, int x, int y, int s, int cols, const char *str, uint32_t col, bool draw)
{
    int rows = 0;
    char line[256];
    while (*str) {
        if (*str == '\n') { str++; rows++; continue; }
        const char *q = str, *cut = NULL;
        int n = 0;
        while (*q && *q != '\n' && n < cols) { if (*q == ' ') cut = q; utf8_next(&q); n++; }
        const char *end = (*q && *q != '\n' && *q != ' ' && cut) ? cut : q;
        size_t len = (size_t)(end - str) < sizeof line - 1 ? (size_t)(end - str) : sizeof line - 1;
        memcpy(line, str, len);
        line[len] = 0;
        if (draw) text(p, w, h, stride, x, y + rows * FONT_CELL_H * s, s, line, col);
        rows++;
        str = end;
        while (*str == ' ') str++;
        if (*str == '\n') str++;
    }
    return rows;
}

static const char *const ABOUT_TEXT =
    "Pinball NS " DESK_VERSION "\n"
    "Pokémon Pinball, the whole table on one screen.\n"
    "Made by Reinhard Sharapov 2026. Controls of the handheld mode after a design by Gianchy3000. "
    "Pokémon Pinball Generations by RainbowDevs (formerly TPPDevs).\n\n"
    "Pokémon Pinball: Copyright 1995-1999 Nintendo, Creatures Inc., GAME FREAK inc. Copyright 1999 HAL Laboratory, Inc., "
    "Jupiter Corp. Pokémon, Pokémon character names, Game Boy and Game Boy Color are trademarks of Nintendo.\n\n"
    "Pinball NS contains no part of the game: it plays the ROM dumped from your own cartridge.\n\n"
    "F1 about  F2 controls  F3 handheld mode  F4 hide its keys  F5 / F9 save / load state  F6 screen filter  "
    "F7 colours  F8 table width  F10 sharp / smooth  F11 full screen  P pause  Esc menu (handheld)\n\n"
    "Any key: back to the game.";

static void page_about(uint32_t *p, int w, int h, int stride, int s)
{
    int cols = (w - 8 * s) / (FONT_CELL_W * s);
    int rows = para(NULL, 0, 0, 0, 0, 0, s, cols, ABOUT_TEXT, 0, false);
    int y = (h - rows * FONT_CELL_H * s) / 2;
    para(p, w, h, stride, 4 * s, y < 2 ? 2 : y, s, cols, ABOUT_TEXT, 0xFFFFFF, true);
}

static void cell_text(const Desk *d, int a, int col, char *out, size_t n)
{
    out[0] = 0;
    for (int k = 0; k < DESK_MAXB; k++) {
        char name[48];
        if (col == 0) { if (!d->keymap[a][k]) continue; key_name(d->keymap[a][k], name, sizeof name); }
        else { if (!d->padmap[a][k]) continue; snprintf(name, sizeof name, "%s", desk_pad_name[d->padmap[a][k] - 1]); }
        if (out[0] && strlen(out) + 2 < n) strcat(out, ", ");
        if (strlen(out) + strlen(name) < n) strcat(out, name);
    }
    if (!out[0]) snprintf(out, n, "-");
}

static void page_controls(const Desk *d, uint32_t *p, int w, int h, int stride, int s)
{
    int lh = FONT_CELL_H * s, x = 4 * s, y = 4 * s, cols = (w - 8 * s) / (FONT_CELL_W * s);
    text(p, w, h, stride, x, y, s, "CONTROLS", 0x5ACEFF);
    y += lh + lh / 2;
    y += para(p, w, h, stride, x, y, s, cols, "Up / Down: a button. Left / Right: keys or gamepad. Enter: add an input. "
              "Delete: clear. D: defaults. Esc: close.", 0xBBBBBB, true) * lh + lh / 2;
    for (int a = 0; a < ACT_N; a++) {
        char line[200], cell[160];
        snprintf(line, sizeof line, "%s: %s", desk_act_gb[a], desk_act_name[a]);
        text(p, w, h, stride, x, y, s, line, 0xFFFFFF);
        y += lh;
        for (int c = 0; c < 2; c++) {
            bool hot = a == d->ctl_row && c == d->ctl_col;
            if (hot && d->ctl_wait) snprintf(cell, sizeof cell, c == 0 ? "press a key..." : "press a gamepad button...");
            else cell_text(d, a, c, cell, sizeof cell);
            snprintf(line, sizeof line, "%s %s", c == 0 ? " Keys:" : " Pad: ", cell);
            if (hot) box(p, w, h, stride, x - s, y - s, w - 2 * x + 2 * s, lh, 0x6B5A00);
            int rows = para(p, w, h, stride, x, y, s, cols, line, hot ? 0xFFE680 : 0xBBBBBB, true);
            y += rows * lh;
        }
        y += lh / 3;
    }
    if (d->ctl_msg[0]) para(p, w, h, stride, x, y + lh / 2, s, cols, d->ctl_msg, 0x5ACEFF, true);
}

/* the message, the pause, the pages: over the picture at the size it is shown (its pixels made larger
 * first, the nearest one: the letters as sharp as the window's), at most 2048 x 2048 */
static void with_text(Desk *d, DeskPicture *p)
{
    const char *msg = d->paused && !d->page ? "PAUSE (P to resume)" : d->osd[0] ? d->osd : NULL;
    if ((!msg && !d->page) || p->dw <= 0 || p->dh <= 0) return;
    int W = p->dw < 2048 ? p->dw : 2048, H = p->dh < 2048 ? p->dh : 2048;
    if ((size_t)W * H > d->text_cap) {
        free(d->text_buf);
        d->text_cap = (size_t)W * H;
        d->text_buf = (uint32_t *)malloc(d->text_cap * 4);
        if (!d->text_buf) { d->text_cap = 0; return; }
    }
    uint32_t *o = d->text_buf;
    for (int y = 0; y < H; y++) {
        const uint32_t *src = p->px + (size_t)((int64_t)y * p->h / H) * p->stride;
        for (int x = 0; x < W; x++) o[(size_t)y * W + x] = src[(int64_t)x * p->w / W];
    }
    /* letters about 46 to a line, and 34 lines in the height (the controls page fits in 30) */
    int s = W / (46 * FONT_CELL_W), sh = H / (34 * FONT_CELL_H);
    if (sh < s) s = sh;
    if (s < 1) s = 1;
    if (d->page) {
        dim(o, W, H, W);
        if (d->page == PAGE_ABOUT) page_about(o, W, H, W, s);
        else page_controls(d, o, W, H, W, s);
    } else {
        int cols = (W - 8 * s) / (FONT_CELL_W * s), rows = para(NULL, 0, 0, 0, 0, 0, s, cols, msg, 0, false);
        int bh = rows * FONT_CELL_H * s + 6 * s, by = H / 2 - bh / 2;
        box(o, W, H, W, 0, by, W, bh, 0x000000);
        int tw = text_w(msg, s);
        para(o, W, H, W, rows == 1 ? (W - tw) / 2 : 4 * s, by + 3 * s, s, cols, msg, 0xFFFFFF, true);
    }
    p->px = o;
    p->w = W;
    p->h = H;
    p->stride = W;
    p->smooth = W != p->dw || H != p->dh;
}

/* ------------------------------------------------------------------ the picture */

void desk_window_size(const Desk *d, int screen_w, int screen_h, int *w, int *h)
{
    if (d->handheld) {                                         /* a phone's shape, 9 x 20 */
        *h = screen_h * 9 / 10;
        *w = *h * 9 / 20;
        return;
    }
    int fw = d->narrow ? PB_FIELD_W_NARROW : PB_FIELD_W, zoom = 1;
    while (fw * (zoom + 1) <= screen_w * 9 / 10 && PB_FIELD_H * (zoom + 1) <= screen_h * 9 / 10) zoom++;
    *w = fw * zoom;
    *h = PB_FIELD_H * zoom;
}

void desk_picture(Desk *d, int win_w, int win_h, DeskPicture *p)
{
    memset(p, 0, sizeof *p);
    if (!d->pb || win_w <= 0 || win_h <= 0) return;
    int w, h, stride;
    const uint32_t *px;
    if (d->handheld) {
        if (d->win_w != win_w || d->win_h != win_h) {
            d->win_w = win_w;
            d->win_h = win_h;
            ui_layout(&d->ui, win_w, win_h);
        }
        screen_build(&d->scr, d->pb, &d->ui, &d->list);
        px = screen_frame(&d->scr, d->pb, &d->ui, &w, &h, &stride);
        if (!px) return;
        p->x = p->y = 0;
        p->dw = (int)lroundf(w * d->ui.nd.scale);
        p->dh = (int)lroundf(h * d->ui.nd.scale);
        p->smooth = false;
        if (d->filter || d->colors) {
            int k = d->filter ? (int)ceilf(d->ui.nd.scale - 0.01f) : 1;
            if (k > FX_MAXK) k = FX_MAXK;
            if (screenfx_begin(&d->fx, px, w, h, stride, d->filter, d->colors, k)) {
                if (d->fx_run) d->fx_run(&d->fx); else screenfx_rows(&d->fx, 0, d->fx.h);
                px = d->fx.out;
                w *= d->fx.k;
                h *= d->fx.k;
                stride = w;
                p->smooth = d->filter != 0;
            }
        }
    } else {
        px = pb_frame(d->pb, &w, &h, &stride);
        if (d->shown_seq != pb_picture_seq(d->pb) || !d->shown) {     /* a new picture of the game */
            d->shown_seq = pb_picture_seq(d->pb);
            d->shown = deflicker_frame(&d->defl, px, w, h, stride);
        }
        if (d->shown) { px = d->shown; stride = w; }
        /* sharp: the largest whole zoom (unless it would waste too much room); smooth: fit */
        double fit = (double)win_w / w < (double)win_h / h ? (double)win_w / w : (double)win_h / h;
        int iz = (int)fit;
        if (!d->smooth && iz >= 1 && iz >= fit * 0.82) { p->dw = w * iz; p->dh = h * iz; }
        else { p->dw = (int)(w * fit); p->dh = (int)(h * fit); }
        p->x = (win_w - p->dw) / 2;
        p->y = (win_h - p->dh) / 2;
        p->smooth = d->smooth && p->dw != w * iz;
        if (d->filter || d->colors) {
            int k = d->filter ? (p->dh + h - 1) / h : 1;
            if (k > FX_MAXK) k = FX_MAXK;
            if (screenfx_begin(&d->fx, px, w, h, stride, d->filter, d->colors, k)) {
                if (d->fx_run) d->fx_run(&d->fx); else screenfx_rows(&d->fx, 0, d->fx.h);
                px = d->fx.out;
                w *= d->fx.k;
                h *= d->fx.k;
                stride = w;
                if (d->filter) p->smooth = p->dw != w || p->dh != h;
            }
        }
    }
    p->px = px;
    p->w = w;
    p->h = h;
    p->stride = stride;
    if (!d->own_pages) with_text(d, p);
}

void desk_blit(const DeskPicture *p, uint32_t *dst, int win_w, int win_h, int dst_stride)
{
    for (int y = 0; y < win_h; y++) {
        uint32_t *row = dst + (size_t)y * dst_stride;
        int sy = p->dh > 0 ? (int)((int64_t)(y - p->y) * p->h / p->dh) : -1;
        if (!p->px || y < p->y || y >= p->y + p->dh || sy < 0 || sy >= p->h) { memset(row, 0, (size_t)win_w * 4); continue; }
        const uint32_t *src = p->px + (size_t)sy * p->stride;
        for (int x = 0; x < win_w; x++) {
            int sx = (int)((int64_t)(x - p->x) * p->w / (p->dw > 0 ? p->dw : 1));
            row[x] = x < p->x || x >= p->x + p->dw || sx < 0 || sx >= p->w ? 0 : src[sx] & 0xFFFFFF;
        }
    }
}
