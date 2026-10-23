/*
 * main_win32.c - Windows front-end of Pinball NS (Pokemon Pinball, the whole table on one screen).
 *
 * Pure Win32 (GDI, waveOut, XInput loaded at run time): a single .exe, nothing to
 * install. The ROM is never included: the player gives the program the ROM dumped
 * from their own cartridge (command line, drag and drop, or a file dialog).
 *
 * Default controls (keyboard)               (Xbox-compatible gamepad)
 *   left flipper   Left Shift, Z, W, Left     LB, LT, D-pad left
 *   right flipper  Right Shift, X, Space      RB, RT, A
 *   tilt           Down (left), C (right),    D-pad down, B / X, Y / Back
 *                  V (up)
 *   menus          arrows, X / Enter / C      D-pad, A, B
 *   pause menu     Enter (Start)              Start
 * F2 (or the window menu) changes them: the input mapping tool.
 *   F11 or Alt+Enter: full screen   F10: sharp/smooth scaling   P: pause   F1: about
 *   F8: the table at its original width (the launch lane scrolls in) or whole
 *   F5: save state  F9: load state  Esc: leave full screen
 *
 * Test: PinballNS.exe -selftest SECONDS ROM REPORT.txt plays SECONDS seconds with the window hidden
 * and the sound at volume 0 (A pressed now and then), then writes the pace it kept in REPORT.txt.
 */
#ifndef UNICODE
#define UNICODE
#endif
#ifndef _UNICODE
#define _UNICODE
#endif
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <mmsystem.h>
#include <commdlg.h>
#include <shellapi.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>
#include "../../src/game/pinball.h"
#include "../../src/front/pacing.h"
#include "../../src/front/deflicker.h"
#include "refresh_win.h"

#define APP_TITLE   L"Pinball NS"
#define APP_VERSION L"2.7"
#define AUDIO_RATE  48000
#define NBUF        12
#define BUF_FRAMES  512
#define AUDIO_TARGET 2048             /* frames kept ahead of the sound card (~43 ms) */

/* ------------------------------------------------------------------ state */

static Pinball *pb;
static uint8_t *rom_data;
static size_t rom_size;
static wchar_t rom_path[MAX_PATH], sav_path[MAX_PATH], state_path[MAX_PATH], ini_path[MAX_PATH], cfg_path[MAX_PATH];
static uint8_t sav_last[0x8000];
static size_t sav_last_size;
static DWORD sav_check_tick;

static HWND hwnd;
static bool running = true, paused, fullscreen, smooth, narrow;
static WINDOWPLACEMENT prev_place;
static wchar_t osd[128];
static DWORD osd_until;

static uint8_t kb_buttons, pad_buttons;
static HWND ctl_wnd;                  /* the input mapping tool, when open */

/* audio */
static HWAVEOUT wout;
static HANDLE audio_event;
static WAVEHDR whdr[NBUF];
static int16_t wbuf[NBUF][BUF_FRAMES * 2];
static int16_t stage_buf[BUF_FRAMES * 2 * 8];
static int stage_n;                   /* stereo frames waiting in stage_buf */
static bool audio_ok;
static uint64_t audio_written;        /* frames given to waveOut */
static uint64_t audio_played_bytes;   /* bytes it has played (its position, made 64-bit) */
static uint32_t audio_pos_last;
static SoundPacer snd;                /* the sound follows the frames (pacing.h) */

/* pace: the refreshes of the display set it (wait_refresh, pacing.h) */
static Pacer pacer;

/* the picture shown: the game's 30 Hz flicker mixed (deflicker.h), made again for each new frame */
static Deflicker defl;
static uint32_t frame_seq, shown_seq;
static const uint32_t *shown_px;

/* -selftest: the pace kept, written at the end */
static struct {
    double secs, start, last, work_max, work_sum, dt_max, flush_max, level_min, level_max;
    long refreshes, frames, odd, starving, pads, flushes, sram_writes;
    wchar_t report[MAX_PATH];
} st;
static bool selftest;

/* the cartridge save, written by a thread of its own (the disk can take tens of milliseconds) */
static HANDLE io_event;
static volatile LONG io_state;        /* 0: free, 1: waiting for the writer, 2: being written */
static volatile LONG io_failed;
static uint8_t io_data[0x8000];
static size_t io_size;

/* ------------------------------------------------------------------ helpers */

static void show_osd(const wchar_t *msg)
{
    wcsncpy(osd, msg, 127);
    osd[127] = 0;
    osd_until = GetTickCount() + 2000;
}

static bool read_file(const wchar_t *path, uint8_t **data, size_t *size, size_t max)
{
    FILE *f = _wfopen(path, L"rb");
    if (!f) return false;
    fseek(f, 0, SEEK_END);
    long n = ftell(f);
    fseek(f, 0, SEEK_SET);
    if (n <= 0 || (size_t)n > max) { fclose(f); return false; }
    uint8_t *buf = (uint8_t *)malloc((size_t)n);
    if (!buf) { fclose(f); return false; }
    size_t r = fread(buf, 1, (size_t)n, f);
    fclose(f);
    if (r != (size_t)n) { free(buf); return false; }
    *data = buf;
    *size = (size_t)n;
    return true;
}

/* write through a temporary file, so that a crash never leaves half a save */
static bool write_file(const wchar_t *path, const void *data, size_t size)
{
    wchar_t tmp[MAX_PATH + 8];
    swprintf(tmp, MAX_PATH + 8, L"%ls.tmp", path);
    FILE *f = _wfopen(tmp, L"wb");
    if (!f) return false;
    bool ok = fwrite(data, 1, size, f) == size;
    ok = (fclose(f) == 0) && ok;
    if (!ok) { DeleteFileW(tmp); return false; }
    return MoveFileExW(tmp, path, MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH) != 0;
}

static void replace_ext(wchar_t *dst, const wchar_t *src, const wchar_t *ext)
{
    wcsncpy(dst, src, MAX_PATH - 1);
    dst[MAX_PATH - 1] = 0;
    wchar_t *dot = wcsrchr(dst, L'.'), *sl = wcsrchr(dst, L'\\');
    if (dot && (!sl || dot > sl)) *dot = 0;
    if (wcslen(dst) + wcslen(ext) < MAX_PATH) wcscat(dst, ext);
}

/* ------------------------------------------------------------------ save data */

static void sram_load(void)
{
    uint8_t *d; size_t n;
    if (read_file(sav_path, &d, &n, 0x8000)) {
        pb_load_sram(pb, d, n);
        free(d);
    }
    const uint8_t *s = pb_sram(pb, &sav_last_size);
    memcpy(sav_last, s, sav_last_size);
}

static DWORD WINAPI io_main(LPVOID arg)
{
    (void)arg;
    for (;;) {
        WaitForSingleObject(io_event, INFINITE);
        if (InterlockedCompareExchange(&io_state, 2, 1) == 1) {
            bool ok = write_file(sav_path, io_data, io_size);
            InterlockedExchange(&io_failed, ok ? 0 : 1);
            InterlockedExchange(&io_state, 0);
        }
    }
}

static void io_start(void)
{
    io_event = CreateEventW(NULL, FALSE, FALSE, NULL);
    HANDLE t = io_event ? CreateThread(NULL, 0, io_main, NULL, 0, NULL) : NULL;
    if (t) CloseHandle(t);
    else if (io_event) { CloseHandle(io_event); io_event = NULL; }
}

/* until the writer has nothing left (before another ROM, the end, a forced write) */
static void io_wait(void)
{
    for (int i = 0; i < 3000 && io_state; i++) Sleep(1);
}

/* the cartridge save if it changed (force: in any case); `later`: by the writer thread */
static void sram_flush_mode(bool force, bool later)
{
    size_t n;
    const uint8_t *s = pb_sram(pb, &n);
    if (n == 0 || n > sizeof sav_last) return;
    if (InterlockedExchange(&io_failed, 0)) sav_last_size = 0;        /* it failed: again */
    if (!force && n == sav_last_size && memcmp(s, sav_last, n) == 0) return;
    if (later && io_event) {
        if (io_state) return;                                       /* the previous one first */
        memcpy(io_data, s, n);
        io_size = n;
        InterlockedExchange(&io_state, 1);
        SetEvent(io_event);
    } else {
        io_wait();
        if (!write_file(sav_path, s, n)) return;
    }
    memcpy(sav_last, s, n);
    sav_last_size = n;
}

static void sram_flush(bool force) { sram_flush_mode(force, false); }

static void state_save(void)
{
    size_t n = pb_snapshot_size();
    void *buf = malloc(n);
    if (!buf) return;
    pb_snapshot_save(pb, buf);
    show_osd(write_file(state_path, buf, n) ? L"State saved (F9 to load it)"
                                           : L"The state could not be saved");
    free(buf);
}

static void state_load(void)
{
    uint8_t *d; size_t n;
    if (!read_file(state_path, &d, &n, 64u << 20)) { show_osd(L"No saved state (F5 to save one)"); return; }
    show_osd(pb_snapshot_load(pb, d, n) == 0 ? L"State loaded" : L"This saved state cannot be loaded");
    free(d);
}

/* ------------------------------------------------------------------ ROM */

static void ini_save_rom(void)
{
    write_file(ini_path, rom_path, (wcslen(rom_path) + 1) * sizeof(wchar_t));   /* UTF-16 path */
}

static wchar_t old_ini_path[MAX_PATH], old_cfg_path[MAX_PATH];   /* Pinball TC's, read once */

static bool ini_load_rom(wchar_t *out)
{
    uint8_t *d; size_t n;
    if (!read_file(ini_path, &d, &n, MAX_PATH * sizeof(wchar_t)) &&
        !read_file(old_ini_path, &d, &n, MAX_PATH * sizeof(wchar_t))) return false;
    memcpy(out, d, n);
    out[n / sizeof(wchar_t) < MAX_PATH ? n / sizeof(wchar_t) : MAX_PATH - 1] = 0;
    free(d);
    return out[0] != 0;
}

/* ------------------------------------------------------------------ input mapping */

/*
 * The Game Boy buttons, named by what they do in the game (its default key configuration, which
 * the program keeps: pb_fix_key_config), each with up to MAXB keys and MAXB gamepad inputs.
 * The mapping tool (F2) changes them; they are kept in pinball_ns.cfg.
 */
enum { ACT_LEFT, ACT_A, ACT_DOWN, ACT_B, ACT_SELECT, ACT_START, ACT_UP, ACT_RIGHT, ACT_N };
#define MAXB 4
static const uint8_t act_button[ACT_N] = { GBC_LEFT, GBC_A, GBC_DOWN, GBC_B, GBC_SELECT, GBC_START, GBC_UP, GBC_RIGHT };
static const char *const act_id[ACT_N] = { "left", "a", "down", "b", "select", "start", "up", "right" };
static const wchar_t *const act_name[ACT_N] = {
    L"Left flipper, menus left", L"Right flipper, launch, OK", L"Left tilt, menus down", L"Right tilt, back",
    L"Upper tilt", L"Pause menu", L"Menus up", L"Menus right" };
static const wchar_t *const act_gb[ACT_N] = { L"Left", L"A", L"Down", L"B", L"Select", L"Start", L"Up", L"Right" };

/* gamepad inputs: the 16 XInput buttons (bit numbers), the triggers, the left stick */
enum { PAD_LT = 16, PAD_RT, PAD_LS_LEFT, PAD_LS_RIGHT, PAD_LS_UP, PAD_LS_DOWN, PAD_N };
static const wchar_t *const pad_name[PAD_N] = {
    L"D-pad up", L"D-pad down", L"D-pad left", L"D-pad right", L"Start", L"Back", L"Left stick click",
    L"Right stick click", L"LB", L"RB", L"?", L"?", L"A", L"B", L"X", L"Y",
    L"LT", L"RT", L"Left stick left", L"Left stick right", L"Left stick up", L"Left stick down" };

static uint16_t keymap[ACT_N][MAXB];  /* virtual keys, 0: none */
static uint8_t padmap[ACT_N][MAXB];   /* gamepad input + 1, 0: none */

static const uint16_t def_keys[ACT_N][MAXB] = {
    { VK_LSHIFT, 'Z', 'W', VK_LEFT }, { VK_RSHIFT, 'X', VK_SPACE }, { VK_DOWN }, { 'C', VK_BACK },
    { 'V', VK_TAB }, { VK_RETURN }, { VK_UP }, { VK_RIGHT } };
static const uint8_t def_pad[ACT_N][MAXB] = {
    { 8 + 1, PAD_LT + 1, 2 + 1, PAD_LS_LEFT + 1 }, { 9 + 1, PAD_RT + 1, 12 + 1 }, { 1 + 1, PAD_LS_DOWN + 1 },
    { 13 + 1, 14 + 1 }, { 15 + 1, 5 + 1 }, { 4 + 1 }, { 0 + 1, PAD_LS_UP + 1 }, { 3 + 1, PAD_LS_RIGHT + 1 } };

/* keys kept by the program (its own functions) */
static bool key_reserved(unsigned vk)
{
    return vk == VK_F1 || vk == VK_F2 || vk == VK_F5 || vk == VK_F8 || vk == VK_F9 || vk == VK_F10 || vk == VK_F11 ||
           vk == 'P' || vk == VK_PAUSE || vk == VK_ESCAPE;
}

static void map_defaults(void)
{
    memcpy(keymap, def_keys, sizeof keymap);
    memcpy(padmap, def_pad, sizeof padmap);
}

/* settings next to the program (pinball_ns.cfg): "narrow=0/1", "smooth=0/1", and for each
 * button "keys.NAME=" virtual keys and "pad.NAME=" gamepad inputs (hexadecimal) */
static void cfg_load(void)
{
    map_defaults();
    uint8_t *d; size_t n;
    if (!read_file(cfg_path, &d, &n, 8192) && !read_file(old_cfg_path, &d, &n, 8192)) return;
    char buf[8193];
    memcpy(buf, d, n);
    buf[n] = 0;
    free(d);
    narrow = strstr(buf, "narrow=1") != NULL;
    smooth = strstr(buf, "smooth=1") != NULL;
    for (int a = 0; a < ACT_N; a++)
        for (int pad = 0; pad < 2; pad++) {
            char key[32];
            snprintf(key, sizeof key, "%s.%s=", pad ? "pad" : "keys", act_id[a]);
            const char *q = strstr(buf, key);
            if (!q) continue;                          /* not saved yet: the defaults */
            q += strlen(key);
            int k = 0;
            if (pad) memset(padmap[a], 0, sizeof padmap[a]); else memset(keymap[a], 0, sizeof keymap[a]);
            while (k < MAXB && *q && *q != '\r' && *q != '\n') {
                char *e;
                unsigned long v = strtoul(q, &e, 16);
                if (e == q) break;
                if (pad ? v < PAD_N : (v > 0 && v < 256 && !key_reserved((unsigned)v))) {
                    if (pad) padmap[a][k++] = (uint8_t)(v + 1); else keymap[a][k++] = (uint16_t)v;
                }
                q = e;
                while (*q == ' ' || *q == ',') q++;
            }
        }
}

static void cfg_save(void)
{
    char buf[2048];
    int n = snprintf(buf, sizeof buf, "narrow=%d\r\nsmooth=%d\r\n", narrow ? 1 : 0, smooth ? 1 : 0);
    for (int a = 0; a < ACT_N; a++)
        for (int pad = 0; pad < 2; pad++) {
            n += snprintf(buf + n, sizeof buf - (size_t)n, "%s.%s=", pad ? "pad" : "keys", act_id[a]);
            for (int k = 0; k < MAXB; k++) {
                unsigned v = pad ? padmap[a][k] : keymap[a][k];
                if (!v) continue;
                n += snprintf(buf + n, sizeof buf - (size_t)n, "%X ", pad ? v - 1 : v);
            }
            n += snprintf(buf + n, sizeof buf - (size_t)n, "\r\n");
        }
    write_file(cfg_path, buf, (size_t)n);
}

/* load and check a ROM; on success the game is (re)started with it */
static bool try_rom(const wchar_t *path, bool report)
{
    uint8_t *d; size_t n;
    if (!read_file(path, &d, &n, 8u << 20)) {
        if (report) {
            wchar_t msg[MAX_PATH + 128];
            swprintf(msg, MAX_PATH + 128, L"This file cannot be read:\n%ls", path);
            MessageBoxW(hwnd, msg, APP_TITLE, MB_ICONERROR);
        }
        return false;
    }
    Pinball *np = (Pinball *)calloc(1, sizeof(Pinball));
    if (!np) { free(d); return false; }
    if (pb_init(np, d, n, AUDIO_RATE) != 0) {
        if (report) {
            wchar_t err[300], msg[600];
            MultiByteToWideChar(CP_UTF8, 0, np->error, -1, err, 300);
            (void)err;
            swprintf(msg, 600, L"This is not the expected ROM.\n\n"
                     L"Pinball NS needs the ROM dumped from your own Pokémon Pinball cartridge "
                     L"(US version, Pokémon Pinball (USA, Australia) (Rumble Version)).");
            MessageBoxW(hwnd, msg, APP_TITLE, MB_ICONWARNING);
        }
        pb_free(np);
        free(np);
        free(d);
        return false;
    }
    if (pb) { sram_flush(false); pb_free(pb); free(pb); free(rom_data); }
    pb = np;
    pb_set_narrow(pb, narrow);
    pb_set_antilag(pb, true);                   /* no frame skipped by the game (see pinball.h) */
    pb_set_frame_palettes(pb, true);            /* no picture torn by a change of colours */
    pb_set_hold(pb, true);                      /* the screen off (loadings): the last picture stays */
    pb_set_audio_highpass(pb, GBC_HIGHPASS_FRONT);      /* the bass of the music (gbc.h) */
    shown_px = NULL;                          /* the old game's picture: not this one's size */
    rom_data = d;
    rom_size = n;
    wcsncpy(rom_path, path, MAX_PATH - 1);
    rom_path[MAX_PATH - 1] = 0;
    replace_ext(sav_path, rom_path, L".sav");
    replace_ext(state_path, rom_path, L".state");
    sram_load();
    ini_save_rom();
    return true;
}

static bool ask_rom(void)
{
    wchar_t file[MAX_PATH] = L"";
    OPENFILENAMEW ofn;
    memset(&ofn, 0, sizeof ofn);
    ofn.lStructSize = sizeof ofn;
    ofn.hwndOwner = hwnd;
    ofn.lpstrFilter = L"Game Boy Color ROM (*.gbc, *.gb)\0*.gbc;*.gb;*.cgb\0All files\0*.*\0";
    ofn.lpstrFile = file;
    ofn.nMaxFile = MAX_PATH;
    ofn.lpstrTitle = L"Choose the ROM of your Pokémon Pinball cartridge (US)";
    ofn.Flags = OFN_FILEMUSTEXIST | OFN_PATHMUSTEXIST | OFN_HIDEREADONLY;
    for (;;) {
        if (!GetOpenFileNameW(&ofn)) return false;
        if (try_rom(file, true)) return true;
    }
}

/* look next to the program for a ROM that matches */
static bool find_rom_near_exe(const wchar_t *dir)
{
    wchar_t pat[MAX_PATH];
    const wchar_t *exts[] = { L"*.gbc", L"*.gb", L"*.cgb" };
    for (int e = 0; e < 3; e++) {
        swprintf(pat, MAX_PATH, L"%ls\\%ls", dir, exts[e]);
        WIN32_FIND_DATAW fd;
        HANDLE h = FindFirstFileW(pat, &fd);
        if (h == INVALID_HANDLE_VALUE) continue;
        do {
            wchar_t p[MAX_PATH];
            swprintf(p, MAX_PATH, L"%ls\\%ls", dir, fd.cFileName);
            if (try_rom(p, false)) { FindClose(h); return true; }
        } while (FindNextFileW(h, &fd));
        FindClose(h);
    }
    return false;
}

/* ------------------------------------------------------------------ audio */

static void audio_open(void)
{
    WAVEFORMATEX wf;
    memset(&wf, 0, sizeof wf);
    wf.wFormatTag = WAVE_FORMAT_PCM;
    wf.nChannels = 2;
    wf.nSamplesPerSec = AUDIO_RATE;
    wf.wBitsPerSample = 16;
    wf.nBlockAlign = 4;
    wf.nAvgBytesPerSec = AUDIO_RATE * 4;
    audio_event = CreateEventW(NULL, FALSE, FALSE, NULL);
    if (waveOutOpen(&wout, WAVE_MAPPER, &wf, (DWORD_PTR)audio_event, 0, CALLBACK_EVENT) != MMSYSERR_NOERROR) {
        wout = NULL;
        return;
    }
    for (int i = 0; i < NBUF; i++) {
        memset(&whdr[i], 0, sizeof whdr[i]);
        whdr[i].lpData = (LPSTR)wbuf[i];
        whdr[i].dwBufferLength = BUF_FRAMES * 4;
        waveOutPrepareHeader(wout, &whdr[i], sizeof whdr[i]);
        whdr[i].dwFlags |= WHDR_DONE;
    }
    audio_ok = true;
    audio_written = 0;
    audio_played_bytes = 0;
    audio_pos_last = 0;
    stage_n = 0;
    sound_reset(&snd, AUDIO_RATE, AUDIO_TARGET);
    snd.limit = NBUF * BUF_FRAMES + sizeof stage_buf / sizeof stage_buf[0] / 2;   /* the buffers and the stage */
    sound_restart(&snd, qpc_now());
}

static void audio_close(void)
{
    if (!wout) return;
    waveOutReset(wout);
    for (int i = 0; i < NBUF; i++) waveOutUnprepareHeader(wout, &whdr[i], sizeof whdr[i]);
    waveOutClose(wout);
    wout = NULL;
    audio_ok = false;
}

/* move the emulator's new samples to the sound card */
static void audio_pump(void)
{
    int16_t tmp[4096];
    int n;
    while ((n = pb_audio(pb, tmp, 2048)) > 0) {
        if (!audio_ok) continue;
        int cap = (int)(sizeof stage_buf / sizeof stage_buf[0] / 2);
        if (stage_n + n > cap) {                   /* far ahead of the card: drop the oldest */
            int drop = stage_n + n - cap;
            if (drop > stage_n) drop = stage_n;
            memmove(stage_buf, stage_buf + drop * 2, (size_t)(stage_n - drop) * 4);
            stage_n -= drop;
        }
        if (n > cap) n = cap;
        memcpy(stage_buf + stage_n * 2, tmp, (size_t)n * 4);
        stage_n += n;
    }
    while (audio_ok && stage_n >= BUF_FRAMES) {
        int i;
        for (i = 0; i < NBUF; i++) if (whdr[i].dwFlags & WHDR_DONE) break;
        if (i == NBUF) break;
        memcpy(wbuf[i], stage_buf, BUF_FRAMES * 4);
        memmove(stage_buf, stage_buf + BUF_FRAMES * 2, (size_t)(stage_n - BUF_FRAMES) * 4);
        stage_n -= BUF_FRAMES;
        whdr[i].dwFlags &= ~(DWORD)WHDR_DONE;
        if (waveOutWrite(wout, &whdr[i], sizeof whdr[i]) != MMSYSERR_NOERROR) whdr[i].dwFlags |= WHDR_DONE;
        else audio_written += BUF_FRAMES;
    }
}

/* what the card has played (waveOutGetPosition: 32 bits, made 64) */
static void audio_position(void)
{
    MMTIME mt;
    mt.wType = TIME_BYTES;
    if (!wout || waveOutGetPosition(wout, &mt, sizeof mt) != MMSYSERR_NOERROR) return;
    uint32_t pos;
    if (mt.wType == TIME_BYTES) pos = mt.u.cb;
    else if (mt.wType == TIME_SAMPLES) pos = mt.u.sample * 4;
    else return;
    audio_played_bytes += (uint32_t)(pos - audio_pos_last);
    audio_pos_last = pos;
    if (audio_played_bytes > audio_written * 4) audio_played_bytes = audio_written * 4;
}

/* before each frame of the game: the sound it makes keeps the card fed, AUDIO_TARGET frames
 * ahead (pacing.h); returns its action (SOUND_EXTRA: one frame more) */
static int audio_pace(double t, int frames_left)
{
    if (!audio_ok) return SOUND_KEEP;
    audio_position();
    double played = (double)(audio_played_bytes / 4);
    double waiting = (double)audio_written - played + stage_n;
    double rate, pad;
    int act = sound_pace(&snd, &pacer, t, played, waiting, frames_left, &rate, &pad);
    if (selftest && t - st.start > 3) {
        if (waiting < st.level_min) st.level_min = waiting;
        if (waiting > st.level_max) st.level_max = waiting;
        int busy = 0;
        for (int i = 0; i < NBUF; i++) busy += !(whdr[i].dwFlags & WHDR_DONE);
        if (!busy) st.starving++;
        if (act == SOUND_PAD) st.pads++;
        if (act == SOUND_FLUSH) st.flushes++;
    }
    if (act == SOUND_PAD) {                     /* silence: nothing left, or the target raised */
        int cap = (int)(sizeof stage_buf / sizeof stage_buf[0] / 2);
        int add = (int)pad;
        if (add > cap - stage_n) add = cap - stage_n;
        if (add > 0) { memset(stage_buf + stage_n * 2, 0, (size_t)add * 4); stage_n += add; }
    } else if (act == SOUND_FLUSH) {
        stage_n = 0;
    } else if (act == SOUND_TRIM) {             /* the oldest of the stage (what the card has is out of reach) */
        int drop = (int)pad < stage_n ? (int)pad : stage_n;
        memmove(stage_buf, stage_buf + drop * 2, (size_t)(stage_n - drop) * 4);
        stage_n -= drop;
    }
    pb_set_audio_rate(pb, rate);
    return act;
}

/* ------------------------------------------------------------------ gamepad (XInput) */

typedef struct { WORD wButtons; BYTE bLeftTrigger, bRightTrigger; SHORT sThumbLX, sThumbLY, sThumbRX, sThumbRY; } XPad;
typedef struct { DWORD dwPacketNumber; XPad Gamepad; } XState;
typedef struct { WORD wLeftMotorSpeed, wRightMotorSpeed; } XVibration;
typedef DWORD (WINAPI *XGetStateFn)(DWORD, XState *);
typedef DWORD (WINAPI *XSetStateFn)(DWORD, XVibration *);
static XGetStateFn xget;
static XSetStateFn xset;
static int pad_index = -1;
static bool pad_rumbling;
static DWORD pad_scan_tick;

static void xinput_load(void)
{
    const wchar_t *dlls[] = { L"xinput1_4.dll", L"xinput1_3.dll", L"xinput9_1_0.dll" };
    for (int i = 0; i < 3 && !xget; i++) {
        HMODULE m = LoadLibraryW(dlls[i]);
        if (!m) continue;
        xget = (XGetStateFn)(void (*)(void))GetProcAddress(m, "XInputGetState");
        xset = (XSetStateFn)(void (*)(void))GetProcAddress(m, "XInputSetState");
    }
}

/* the gamepad inputs held (bit = PAD_* input), -1 when there is no gamepad */
static long pad_inputs(void)
{
    if (!xget) return -1;
    XState st;
    if (pad_index < 0) {
        DWORD now = GetTickCount();
        if (now - pad_scan_tick < 1000) return -1;   /* polling absent pads is slow */
        pad_scan_tick = now;
        for (int i = 0; i < 4; i++) if (xget((DWORD)i, &st) == ERROR_SUCCESS) { pad_index = i; break; }
        if (pad_index < 0) return -1;
    }
    if (xget((DWORD)pad_index, &st) != ERROR_SUCCESS) { pad_index = -1; return -1; }
    long in = st.Gamepad.wButtons;
    if (st.Gamepad.bLeftTrigger > 40) in |= 1L << PAD_LT;
    if (st.Gamepad.bRightTrigger > 40) in |= 1L << PAD_RT;
    if (st.Gamepad.sThumbLX < -16000) in |= 1L << PAD_LS_LEFT;
    if (st.Gamepad.sThumbLX > 16000) in |= 1L << PAD_LS_RIGHT;
    if (st.Gamepad.sThumbLY > 16000) in |= 1L << PAD_LS_UP;
    if (st.Gamepad.sThumbLY < -16000) in |= 1L << PAD_LS_DOWN;
    return in;
}

static void pad_poll(void)
{
    pad_buttons = 0;
    long in = pad_inputs();
    if (in <= 0) return;
    uint8_t m = 0;
    for (int a = 0; a < ACT_N; a++)
        for (int k = 0; k < MAXB; k++)
            if (padmap[a][k] && (in & (1L << (padmap[a][k] - 1)))) m |= act_button[a];
    pad_buttons = m;
}

static void pad_rumble(bool on)
{
    if (!xset || pad_index < 0 || on == pad_rumbling) return;
    XVibration v = { (WORD)(on ? 30000 : 0), (WORD)(on ? 42000 : 0) };
    xset((DWORD)pad_index, &v);
    pad_rumbling = on;
}

/* ------------------------------------------------------------------ keyboard */

static bool down(int vk) { return (GetKeyState(vk) & 0x8000) != 0; }

static void kb_update(void)
{
    uint8_t m = 0;
    if (!ctl_wnd)
        for (int a = 0; a < ACT_N; a++)
            for (int k = 0; k < MAXB; k++) {
                unsigned vk = keymap[a][k];
                if (!vk || !down((int)vk)) continue;
                if (vk == VK_RETURN && down(VK_MENU)) continue;       /* Alt+Enter: full screen */
                m |= act_button[a];
            }
    kb_buttons = m;
}

/* names of the keys, in English whatever the system language */
static void key_name(unsigned vk, wchar_t *out, int n)
{
    static const struct { unsigned vk; const wchar_t *name; } names[] = {
        { VK_LSHIFT, L"Left Shift" }, { VK_RSHIFT, L"Right Shift" }, { VK_SHIFT, L"Shift" },
        { VK_LCONTROL, L"Left Ctrl" }, { VK_RCONTROL, L"Right Ctrl" }, { VK_CONTROL, L"Ctrl" },
        { VK_LMENU, L"Left Alt" }, { VK_RMENU, L"Right Alt" }, { VK_MENU, L"Alt" },
        { VK_LEFT, L"Left" }, { VK_RIGHT, L"Right" }, { VK_UP, L"Up" }, { VK_DOWN, L"Down" },
        { VK_SPACE, L"Space" }, { VK_RETURN, L"Enter" }, { VK_TAB, L"Tab" }, { VK_BACK, L"Backspace" },
        { VK_INSERT, L"Insert" }, { VK_DELETE, L"Delete" }, { VK_HOME, L"Home" }, { VK_END, L"End" },
        { VK_PRIOR, L"Page Up" }, { VK_NEXT, L"Page Down" }, { VK_CAPITAL, L"Caps Lock" },
        { VK_LWIN, L"Left Windows" }, { VK_RWIN, L"Right Windows" }, { VK_APPS, L"Menu" },
        { VK_NUMPAD0, L"Num 0" }, { VK_MULTIPLY, L"Num *" }, { VK_ADD, L"Num +" }, { VK_SUBTRACT, L"Num -" },
        { VK_DECIMAL, L"Num ." }, { VK_DIVIDE, L"Num /" },
    };
    for (size_t i = 0; i < sizeof names / sizeof names[0]; i++)
        if (names[i].vk == vk) { wcsncpy(out, names[i].name, (size_t)n - 1); out[n - 1] = 0; return; }
    if (vk > VK_NUMPAD0 && vk <= VK_NUMPAD9) { swprintf(out, (size_t)n, L"Num %u", vk - VK_NUMPAD0); return; }
    if (vk >= VK_F1 && vk <= VK_F24) { swprintf(out, (size_t)n, L"F%u", vk - VK_F1 + 1); return; }
    UINT ch = MapVirtualKeyW(vk, 2 /* MAPVK_VK_TO_CHAR */) & 0x7FFFFFFF;
    if (ch > ' ') swprintf(out, (size_t)n, L"%lc", (wint_t)ch);
    else swprintf(out, (size_t)n, L"Key %02X", vk);
}

/* the key of a key message: Shift, Ctrl and Alt with their side */
static unsigned msg_key(WPARAM wp, LPARAM lp)
{
    unsigned sc = (unsigned)((lp >> 16) & 0xFF);
    bool ext = (lp & (1 << 24)) != 0;
    if (wp == VK_SHIFT) return MapVirtualKeyW(sc, 3 /* MAPVK_VSC_TO_VK_EX */) == VK_RSHIFT ? VK_RSHIFT : VK_LSHIFT;
    if (wp == VK_CONTROL) return ext ? VK_RCONTROL : VK_LCONTROL;
    if (wp == VK_MENU) return ext ? VK_RMENU : VK_LMENU;
    return (unsigned)wp;
}

/* ------------------------------------------------------------------ the input mapping tool */

static void set_fullscreen(bool on);

/*
 * A window listing the Game Boy buttons with what they do in the game, their keys and their
 * gamepad inputs. A click on a cell waits for a key or a gamepad input, which is added there
 * (and taken off any other button); right click or Delete clears the cell. The game is paused
 * while the tool is open.
 */
#define CTL_ID_DEFAULTS 101
#define CTL_ID_CLOSE    102
static int ctl_row = -1, ctl_col;     /* the cell waiting for an input (column 0 keys, 1 gamepad) */
static long ctl_pad_held;             /* gamepad inputs held when the wait began */
static wchar_t ctl_msg[200];
static int ctl_u;                     /* size unit (pixels for 1/96 inch) x 100 */

static int U(int v) { return v * ctl_u / 100; }
static int ctl_row_y(int r) { return U(92) + r * U(32); }
static int ctl_col_x(int c) { return c == 0 ? U(16) : c == 1 ? U(268) : U(508); }

static void cell_text(int a, int col, wchar_t *out, int n)
{
    out[0] = 0;
    for (int k = 0; k < MAXB; k++) {
        wchar_t name[48];
        if (col == 0) { if (!keymap[a][k]) continue; key_name(keymap[a][k], name, 48); }
        else { if (!padmap[a][k]) continue; wcsncpy(name, pad_name[padmap[a][k] - 1], 47); name[47] = 0; }
        if (out[0] && wcslen(out) + 2 < (size_t)n) wcscat(out, L", ");
        if (wcslen(out) + wcslen(name) < (size_t)n) wcscat(out, name);
    }
    if (!out[0]) wcsncpy(out, L"-", (size_t)n);
}

static void ctl_bind(int a, int col, unsigned v)
{
    /* one button per input: taken off the others */
    for (int b = 0; b < ACT_N; b++)
        for (int k = 0; k < MAXB; k++) {
            unsigned cur = col == 0 ? keymap[b][k] : padmap[b][k];
            if (cur != (col == 0 ? v : v + 1)) continue;
            for (int j = k; j < MAXB - 1; j++) {
                if (col == 0) keymap[b][j] = keymap[b][j + 1]; else padmap[b][j] = padmap[b][j + 1];
            }
            if (col == 0) keymap[b][MAXB - 1] = 0; else padmap[b][MAXB - 1] = 0;
            k--;
        }
    int k = 0;
    while (k < MAXB && (col == 0 ? keymap[a][k] : padmap[a][k])) k++;
    if (k == MAXB) {                           /* full: the oldest one goes */
        for (int j = 0; j < MAXB - 1; j++) {
            if (col == 0) keymap[a][j] = keymap[a][j + 1]; else padmap[a][j] = padmap[a][j + 1];
        }
        k = MAXB - 1;
    }
    if (col == 0) keymap[a][k] = (uint16_t)v; else padmap[a][k] = (uint8_t)(v + 1);
    cfg_save();
    ctl_msg[0] = 0;
}

static void ctl_clear(int a, int col)
{
    if (col == 0) memset(keymap[a], 0, sizeof keymap[a]); else memset(padmap[a], 0, sizeof padmap[a]);
    cfg_save();
}

static void ctl_wait(int row, int col)
{
    ctl_row = row;
    ctl_col = col;
    long in = pad_inputs();
    ctl_pad_held = in > 0 ? in : 0;
    swprintf(ctl_msg, 200, col == 0 ? L"%ls: press a key (Esc: cancel, Delete: clear)"
                                    : L"%ls: press a gamepad button (Esc: cancel, Delete: clear)", act_name[row]);
    if (col == 1 && pad_inputs() < 0) wcscat(ctl_msg, L". No gamepad found.");
    SetFocus(ctl_wnd);
    InvalidateRect(ctl_wnd, NULL, FALSE);
}

static void ctl_paint(HWND w)
{
    PAINTSTRUCT ps;
    HDC dc = BeginPaint(w, &ps);
    RECT rc;
    GetClientRect(w, &rc);
    HDC mem = CreateCompatibleDC(dc);
    HBITMAP bmp = CreateCompatibleBitmap(dc, rc.right, rc.bottom);
    HGDIOBJ obmp = SelectObject(mem, bmp);
    FillRect(mem, &rc, (HBRUSH)GetStockObject(WHITE_BRUSH));
    HFONT f = CreateFontW(-U(15), 0, 0, 0, FW_NORMAL, 0, 0, 0, DEFAULT_CHARSET, 0, 0, CLEARTYPE_QUALITY, 0, L"Segoe UI");
    HFONT fb = CreateFontW(-U(15), 0, 0, 0, FW_BOLD, 0, 0, 0, DEFAULT_CHARSET, 0, 0, CLEARTYPE_QUALITY, 0, L"Segoe UI");
    HFONT ft = CreateFontW(-U(22), 0, 0, 0, FW_BOLD, 0, 0, 0, DEFAULT_CHARSET, 0, 0, CLEARTYPE_QUALITY, 0, L"Segoe UI");
    SetBkMode(mem, TRANSPARENT);
    HGDIOBJ of = SelectObject(mem, ft);
    SetTextColor(mem, RGB(0x00, 0x5A, 0xFF));
    TextOutW(mem, U(16), U(12), L"Controls", 8);
    SelectObject(mem, f);
    SetTextColor(mem, RGB(0x55, 0x55, 0x55));
    const wchar_t *help = L"Click a cell, then press a key or a gamepad button to add it. Right click or Delete: clear.";
    TextOutW(mem, U(16), U(44), help, (int)wcslen(help));
    SelectObject(mem, fb);
    SetTextColor(mem, RGB(0, 0, 0));
    TextOutW(mem, ctl_col_x(0), U(68), L"Game Boy button", 15);
    TextOutW(mem, ctl_col_x(1), U(68), L"Keyboard", 8);
    TextOutW(mem, ctl_col_x(2), U(68), L"Gamepad", 7);
    HBRUSH band = CreateSolidBrush(RGB(0xF0, 0xF3, 0xFA)), hot = CreateSolidBrush(RGB(0xFF, 0xE6, 0x80));
    for (int a = 0; a < ACT_N; a++) {
        int y = ctl_row_y(a);
        RECT r = { U(8), y - U(4), rc.right - U(8), y + U(28) };
        if (a % 2 == 0) FillRect(mem, &r, band);
        for (int c = 0; c < 2; c++)
            if (ctl_row == a && ctl_col == c) {
                RECT hr = { ctl_col_x(c + 1) - U(6), y - U(4), ctl_col_x(c + 1) + U(232), y + U(28) };
                FillRect(mem, &hr, hot);
            }
        wchar_t t[160];
        SelectObject(mem, fb);
        swprintf(t, 160, L"%ls", act_gb[a]);
        TextOutW(mem, ctl_col_x(0), y, t, (int)wcslen(t));
        SelectObject(mem, f);
        swprintf(t, 160, L"%ls", act_name[a]);
        TextOutW(mem, ctl_col_x(0) + U(56), y, t, (int)wcslen(t));
        for (int c = 0; c < 2; c++) {
            if (ctl_row == a && ctl_col == c) wcscpy(t, c == 0 ? L"press a key..." : L"press a button...");
            else cell_text(a, c, t, 160);
            RECT tr = { ctl_col_x(c + 1), y, ctl_col_x(c + 1) + U(226), y + U(24) };
            DrawTextW(mem, t, -1, &tr, DT_LEFT | DT_SINGLELINE | DT_END_ELLIPSIS | DT_NOPREFIX);
        }
    }
    SetTextColor(mem, RGB(0x00, 0x5A, 0xFF));
    RECT mr = { U(16), ctl_row_y(ACT_N) + U(6), rc.right - U(240), ctl_row_y(ACT_N) + U(48) };
    DrawTextW(mem, ctl_msg, -1, &mr, DT_LEFT | DT_WORDBREAK | DT_NOPREFIX);
    BitBlt(dc, 0, 0, rc.right, rc.bottom, mem, 0, 0, SRCCOPY);
    SelectObject(mem, of);
    SelectObject(mem, obmp);
    DeleteObject(bmp);
    DeleteDC(mem);
    DeleteObject(f); DeleteObject(fb); DeleteObject(ft); DeleteObject(band); DeleteObject(hot);
    EndPaint(w, &ps);
}

static void ctl_close(void)
{
    if (!ctl_wnd) return;
    HWND w = ctl_wnd;
    KillTimer(w, 1);
    EnableWindow(hwnd, TRUE);
    ctl_wnd = NULL;
    DestroyWindow(w);
    SetForegroundWindow(hwnd);
    cfg_save();
    if (wout && !paused) waveOutRestart(wout);
    kb_update();
}

static LRESULT CALLBACK ctl_proc(HWND w, UINT msg, WPARAM wp, LPARAM lp)
{
    switch (msg) {
    case WM_PAINT: ctl_paint(w); return 0;
    case WM_ERASEBKGND: return 1;
    case WM_CLOSE: ctl_close(); return 0;
    case WM_COMMAND:
        if (LOWORD(wp) == CTL_ID_CLOSE) ctl_close();
        else if (LOWORD(wp) == CTL_ID_DEFAULTS) {
            map_defaults();
            cfg_save();
            ctl_row = -1;
            wcscpy(ctl_msg, L"Default controls restored.");
            SetFocus(w);
            InvalidateRect(w, NULL, FALSE);
        }
        return 0;
    case WM_LBUTTONDOWN:
    case WM_RBUTTONDOWN: {
        int x = (short)LOWORD(lp), y = (short)HIWORD(lp);
        int row = -1, col = -1;
        for (int a = 0; a < ACT_N; a++) if (y >= ctl_row_y(a) - U(4) && y < ctl_row_y(a) + U(28)) row = a;
        if (x >= ctl_col_x(1) - U(6) && x < ctl_col_x(2) - U(6)) col = 0;
        else if (x >= ctl_col_x(2) - U(6)) col = 1;
        if (row >= 0 && col >= 0) {
            if (msg == WM_RBUTTONDOWN) { ctl_clear(row, col); ctl_row = -1; ctl_msg[0] = 0; }
            else ctl_wait(row, col);
        } else { ctl_row = -1; ctl_msg[0] = 0; }
        SetFocus(w);
        InvalidateRect(w, NULL, FALSE);
        return 0;
    }
    case WM_KEYDOWN:
    case WM_SYSKEYDOWN: {
        unsigned vk = msg_key(wp, lp);
        if (ctl_row < 0) {
            if (vk == VK_ESCAPE) ctl_close();
            return 0;
        }
        if (vk == VK_ESCAPE) { ctl_row = -1; ctl_msg[0] = 0; }
        else if (vk == VK_DELETE) { ctl_clear(ctl_row, ctl_col); ctl_row = -1; ctl_msg[0] = 0; }
        else if (ctl_col == 0) {
            if (key_reserved(vk)) wcscpy(ctl_msg, L"F1, F2, F5, F8 to F11, P, Pause and Esc are kept by Pinball NS.");
            else { ctl_bind(ctl_row, 0, vk); ctl_row = -1; }
        }
        InvalidateRect(w, NULL, FALSE);
        return 0;
    }
    case WM_SYSCHAR:
        return 0;                             /* no beep for Alt + key */
    case WM_TIMER:
        if (ctl_row >= 0 && ctl_col == 1) {
            long in = pad_inputs();
            if (in < 0) in = 0;
            long fresh = in & ~ctl_pad_held;
            ctl_pad_held &= in;               /* released inputs can be pressed again */
            for (int i = 0; i < PAD_N; i++)
                if (fresh & (1L << i)) { ctl_bind(ctl_row, 1, (unsigned)i); ctl_row = -1; InvalidateRect(w, NULL, FALSE); break; }
        }
        return 0;
    default:
        break;
    }
    return DefWindowProcW(w, msg, wp, lp);
}

static void ctl_open(void)
{
    if (ctl_wnd) { SetForegroundWindow(ctl_wnd); return; }
    if (fullscreen) set_fullscreen(false);
    HINSTANCE inst = GetModuleHandleW(NULL);
    static bool registered;
    if (!registered) {
        WNDCLASSEXW wc;
        memset(&wc, 0, sizeof wc);
        wc.cbSize = sizeof wc;
        wc.lpfnWndProc = ctl_proc;
        wc.hInstance = inst;
        wc.hIcon = LoadIconW(inst, MAKEINTRESOURCEW(1));
        wc.hCursor = LoadCursorW(NULL, (LPCWSTR)IDC_ARROW);
        wc.lpszClassName = L"PinballNSControls";
        RegisterClassExW(&wc);
        registered = true;
    }
    HDC sdc = GetDC(NULL);
    ctl_u = GetDeviceCaps(sdc, LOGPIXELSY) * 100 / 96;
    ReleaseDC(NULL, sdc);
    if (ctl_u < 100) ctl_u = 100;
    RECT r = { 0, 0, U(760), ctl_row_y(ACT_N) + U(64) };
    DWORD style = WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU;
    AdjustWindowRect(&r, style, FALSE);
    RECT mr;
    GetWindowRect(hwnd, &mr);
    int ww = r.right - r.left, wh = r.bottom - r.top;
    int x = (mr.left + mr.right) / 2 - ww / 2, y = (mr.top + mr.bottom) / 2 - wh / 2;
    if (x < 0) x = 0;
    if (y < 0) y = 0;
    ctl_row = -1;
    ctl_msg[0] = 0;
    if (wout) waveOutPause(wout);
    ctl_wnd = CreateWindowExW(WS_EX_DLGMODALFRAME, L"PinballNSControls", L"Pinball NS - Controls", style, x, y, ww, wh, hwnd,
                              NULL, inst, NULL);
    if (!ctl_wnd) { if (wout && !paused) waveOutRestart(wout); return; }
    HFONT bf = CreateFontW(-U(15), 0, 0, 0, FW_NORMAL, 0, 0, 0, DEFAULT_CHARSET, 0, 0, CLEARTYPE_QUALITY, 0, L"Segoe UI");
    RECT cr;
    GetClientRect(ctl_wnd, &cr);
    int by = cr.bottom - U(46);
    HWND b1 = CreateWindowW(L"BUTTON", L"Defaults", WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON, cr.right - U(232), by, U(104), U(32),
                            ctl_wnd, (HMENU)(INT_PTR)CTL_ID_DEFAULTS, inst, NULL);
    HWND b2 = CreateWindowW(L"BUTTON", L"Close", WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON, cr.right - U(120), by, U(104), U(32),
                            ctl_wnd, (HMENU)(INT_PTR)CTL_ID_CLOSE, inst, NULL);
    SendMessageW(b1, WM_SETFONT, (WPARAM)bf, TRUE);
    SendMessageW(b2, WM_SETFONT, (WPARAM)bf, TRUE);
    EnableWindow(hwnd, FALSE);
    kb_buttons = 0;
    ShowWindow(ctl_wnd, SW_SHOW);
    SetTimer(ctl_wnd, 1, 30, NULL);
    SetFocus(ctl_wnd);
}

/* ------------------------------------------------------------------ about */

static void about(void)
{
    MSGBOXPARAMSW mb;
    memset(&mb, 0, sizeof mb);
    mb.cbSize = sizeof mb;
    mb.hwndOwner = hwnd;
    mb.hInstance = GetModuleHandleW(NULL);
    mb.lpszCaption = L"About Pinball NS";
    mb.lpszIcon = MAKEINTRESOURCEW(1);
    mb.dwStyle = MB_OK | MB_USERICON;
    mb.lpszText =
        L"Pinball NS " APP_VERSION L"\n"
        L"Pokémon Pinball, the whole table on one screen.\n"
        L"Made by Reinhard Sharapov 2026.\n\n"
        L"Pokémon Pinball © 1995-1999 Nintendo, Creatures Inc., GAME FREAK inc.\n"
        L"© 1999 HAL Laboratory, Inc., Jupiter Corp.\n"
        L"Pokémon, Pokémon character names, Game Boy and Game Boy Color are trademarks of Nintendo.\n\n"
        L"Pinball NS contains no part of the game: it plays the ROM dumped from your own cartridge.\n\n"
        L"F1: about   F2: controls   F5 / F9: save / load state   F8: table width\n"
        L"F10: sharp / smooth   F11 or Alt+Enter: full screen   P: pause";
    bool was = paused;
    paused = true;
    if (wout) waveOutPause(wout);
    MessageBoxIndirectW(&mb);
    paused = was;
    if (wout && !paused) waveOutRestart(wout);
    kb_update();
}

/* ------------------------------------------------------------------ video */

static void set_fullscreen(bool on)
{
    DWORD style = (DWORD)GetWindowLongW(hwnd, GWL_STYLE);
    if (on && !fullscreen) {
        MONITORINFO mi;
        memset(&mi, 0, sizeof mi);
        mi.cbSize = sizeof mi;
        prev_place.length = sizeof prev_place;
        if (GetWindowPlacement(hwnd, &prev_place) && GetMonitorInfoW(MonitorFromWindow(hwnd, MONITOR_DEFAULTTOPRIMARY), &mi)) {
            SetWindowLongW(hwnd, GWL_STYLE, (LONG)(style & ~(DWORD)WS_OVERLAPPEDWINDOW));
            SetWindowPos(hwnd, HWND_TOP, mi.rcMonitor.left, mi.rcMonitor.top,
                         mi.rcMonitor.right - mi.rcMonitor.left, mi.rcMonitor.bottom - mi.rcMonitor.top,
                         SWP_NOOWNERZORDER | SWP_FRAMECHANGED);
            fullscreen = true;
            ShowCursor(FALSE);
        }
    } else if (!on && fullscreen) {
        SetWindowLongW(hwnd, GWL_STYLE, (LONG)(style | WS_OVERLAPPEDWINDOW));
        SetWindowPlacement(hwnd, &prev_place);
        SetWindowPos(hwnd, NULL, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_FRAMECHANGED);
        fullscreen = false;
        ShowCursor(TRUE);
    }
}

static void paint(HDC dc)
{
    RECT rc;
    GetClientRect(hwnd, &rc);
    int cw = rc.right, ch = rc.bottom;
    HBRUSH black = (HBRUSH)GetStockObject(BLACK_BRUSH);
    if (!pb || cw <= 0 || ch <= 0) { FillRect(dc, &rc, black); return; }

    int w, h, stride;
    const uint32_t *px = pb_frame(pb, &w, &h, &stride);
    if (shown_seq != pb_picture_seq(pb) || !shown_px) {    /* a new picture of the game */
        shown_seq = pb_picture_seq(pb);
        shown_px = deflicker_frame(&defl, px, w, h, stride);
    }
    if (shown_px) { px = shown_px; stride = w; }
    /* sharp: largest integer zoom (unless it would waste too much room); smooth: fit */
    double fit = (double)cw / w < (double)ch / h ? (double)cw / w : (double)ch / h;
    int iz = (int)fit;
    int dw, dh;
    if (!smooth && iz >= 1 && iz >= fit * 0.82) { dw = w * iz; dh = h * iz; }
    else { dw = (int)(w * fit); dh = (int)(h * fit); }
    int x = (cw - dw) / 2, y = (ch - dh) / 2;

    RECT r;
    SetRect(&r, 0, 0, cw, y); FillRect(dc, &r, black);
    SetRect(&r, 0, y + dh, cw, ch); FillRect(dc, &r, black);
    SetRect(&r, 0, y, x, y + dh); FillRect(dc, &r, black);
    SetRect(&r, x + dw, y, cw, y + dh); FillRect(dc, &r, black);

    BITMAPINFO bmi;
    memset(&bmi, 0, sizeof bmi);
    bmi.bmiHeader.biSize = sizeof bmi.bmiHeader;
    bmi.bmiHeader.biWidth = stride;
    bmi.bmiHeader.biHeight = -h;
    bmi.bmiHeader.biPlanes = 1;
    bmi.bmiHeader.biBitCount = 32;
    bmi.bmiHeader.biCompression = BI_RGB;
    if (smooth && dw != w * iz) { SetStretchBltMode(dc, HALFTONE); SetBrushOrgEx(dc, 0, 0, NULL); }
    else SetStretchBltMode(dc, COLORONCOLOR);
    StretchDIBits(dc, x, y, dw, dh, 0, 0, w, h, px, &bmi, DIB_RGB_COLORS, SRCCOPY);

    const wchar_t *msg = NULL;
    if (paused) msg = L"PAUSE (P to resume)";
    else if (osd[0] && (int32_t)(GetTickCount() - osd_until) < 0) msg = osd;   /* (the tick count wraps after 49 days) */
    if (msg) {
        SetBkMode(dc, OPAQUE);
        SetBkColor(dc, RGB(0, 0, 0));
        SetTextColor(dc, RGB(255, 255, 255));
        int fh_px = dh / 26 < dw / 24 ? dh / 26 : dw / 24;
        if (fh_px < 12) fh_px = 12;
        HFONT f = CreateFontW(-fh_px, 0, 0, 0, FW_BOLD, 0, 0, 0, DEFAULT_CHARSET, 0, 0,
                              CLEARTYPE_QUALITY, 0, L"Segoe UI");
        HGDIOBJ old = SelectObject(dc, f);
        RECT tr = { x, y + dh / 2 - dh / 20, x + dw, y + dh / 2 + dh / 20 };
        DrawTextW(dc, msg, -1, &tr, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
        SelectObject(dc, old);
        DeleteObject(f);
    }
}

static void present(void)
{
    HDC dc = GetDC(hwnd);
    paint(dc);
    ReleaseDC(hwnd, dc);
}

/* ------------------------------------------------------------------ window */

static void apply_narrow(void);
#define SC_CONTROLS 0x1000             /* window menu entries */
#define SC_ABOUT    0x1010

static LRESULT CALLBACK wndproc(HWND h, UINT msg, WPARAM wp, LPARAM lp)
{
    switch (msg) {
    case WM_CLOSE:
        running = false;
        return 0;
    case WM_DESTROY:
        PostQuitMessage(0);
        return 0;
    case WM_PAINT: {
        PAINTSTRUCT ps;
        HDC dc = BeginPaint(h, &ps);
        paint(dc);
        EndPaint(h, &ps);
        return 0;
    }
    case WM_ERASEBKGND:
        return 1;
    case WM_SIZE:
        if (wp == SIZE_MINIMIZED) { if (wout) waveOutPause(wout); }
        else if (wout && !paused) waveOutRestart(wout);
        InvalidateRect(h, NULL, FALSE);
        return 0;
    case WM_KILLFOCUS:
        kb_buttons = 0;
        return 0;
    case WM_SYSCOMMAND:
        if ((wp & 0xFFF0) == SC_CONTROLS) { ctl_open(); return 0; }
        if ((wp & 0xFFF0) == SC_ABOUT) { about(); return 0; }
        break;
    case WM_SYSKEYDOWN:
        if (wp == VK_RETURN && (lp & (1 << 29))) { set_fullscreen(!fullscreen); return 0; }
        if (wp == VK_F10) { smooth = !smooth; cfg_save(); InvalidateRect(h, NULL, FALSE); return 0; }
        kb_update();
        break;
    case WM_KEYDOWN:
        if (!(lp & (1 << 30))) {               /* not an auto-repeat */
            switch (wp) {
            case VK_F11: set_fullscreen(!fullscreen); break;
            case VK_F8: narrow = !narrow; apply_narrow(); break;
            case VK_F1: about(); break;
            case VK_F2: ctl_open(); break;
            case VK_ESCAPE: if (fullscreen) set_fullscreen(false); break;
            case 'P': case VK_PAUSE:
                paused = !paused;
                if (wout) { if (paused) waveOutPause(wout); else waveOutRestart(wout); }
                InvalidateRect(h, NULL, FALSE);
                break;
            case VK_F5: if (pb) state_save(); break;
            case VK_F9: if (pb) state_load(); break;
            default: break;
            }
        }
        kb_update();
        return 0;
    case WM_KEYUP:
    case WM_SYSKEYUP:
        kb_update();
        return 0;
    case WM_DROPFILES: {
        wchar_t p[MAX_PATH];
        if (DragQueryFileW((HDROP)wp, 0, p, MAX_PATH)) try_rom(p, true);
        DragFinish((HDROP)wp);
        return 0;
    }
    default:
        break;
    }
    return DefWindowProcW(h, msg, wp, lp);
}

static int field_w(void) { return narrow ? PB_FIELD_W_NARROW : PB_FIELD_W; }

/* F8: the table at its original width or whole; the window takes the new shape */
static void apply_narrow(void)
{
    if (pb) pb_set_narrow(pb, narrow);
    cfg_save();
    show_osd(narrow ? L"Table: original width (F8)" : L"Table: whole (F8)");
    if (!fullscreen && !IsZoomed(hwnd) && !IsIconic(hwnd)) {
        RECT c;
        GetClientRect(hwnd, &c);
        int zoom = (c.bottom + PB_FIELD_H / 2) / PB_FIELD_H;
        if (zoom < 1) zoom = 1;
        RECT r = { 0, 0, field_w() * zoom, PB_FIELD_H * zoom };
        AdjustWindowRect(&r, WS_OVERLAPPEDWINDOW, FALSE);
        SetWindowPos(hwnd, NULL, 0, 0, r.right - r.left, r.bottom - r.top, SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE);
    }
    InvalidateRect(hwnd, NULL, FALSE);
}

static void create_window(HINSTANCE inst)
{
    WNDCLASSEXW wc;
    memset(&wc, 0, sizeof wc);
    wc.cbSize = sizeof wc;
    wc.style = CS_HREDRAW | CS_VREDRAW;
    wc.lpfnWndProc = wndproc;
    wc.hInstance = inst;
    wc.hIcon = LoadIconW(inst, MAKEINTRESOURCEW(1));
    wc.hIconSm = wc.hIcon;
    wc.hCursor = LoadCursorW(NULL, (LPCWSTR)IDC_ARROW);
    wc.lpszClassName = L"PinballNS";
    RegisterClassExW(&wc);

    /* biggest whole zoom of the tall field that fits the screen */
    RECT wa;
    SystemParametersInfoW(SPI_GETWORKAREA, 0, &wa, 0);
    int zoom = 1;
    while (field_w() * (zoom + 1) <= (wa.right - wa.left) * 9 / 10 &&
           PB_FIELD_H * (zoom + 1) <= (wa.bottom - wa.top) * 9 / 10) zoom++;
    RECT r = { 0, 0, field_w() * zoom, PB_FIELD_H * zoom };
    AdjustWindowRect(&r, WS_OVERLAPPEDWINDOW, FALSE);
    int ww = r.right - r.left, wh = r.bottom - r.top;
    hwnd = CreateWindowExW(WS_EX_ACCEPTFILES, wc.lpszClassName, APP_TITLE, WS_OVERLAPPEDWINDOW,
                           wa.left + ((wa.right - wa.left) - ww) / 2, wa.top + ((wa.bottom - wa.top) - wh) / 2,
                           ww, wh, NULL, NULL, inst, NULL);
    if (!hwnd) return;
    HMENU sm = GetSystemMenu(hwnd, FALSE);
    AppendMenuW(sm, MF_SEPARATOR, 0, NULL);
    AppendMenuW(sm, MF_STRING, SC_CONTROLS, L"Controls...\tF2");
    AppendMenuW(sm, MF_STRING, SC_ABOUT, L"About Pinball NS\tF1");
}

/* ------------------------------------------------------------------ main */

static void run_one_frame(void)
{
    pb_run_frame(pb, kb_buttons | pad_buttons);
    frame_seq++;
    audio_pump();
    pad_rumble(pb_rumble(pb));
}

int WINAPI wWinMain(HINSTANCE inst, HINSTANCE prev, PWSTR cmd, int show)
{
    (void)prev; (void)cmd;
    SetProcessDPIAware();
    timeBeginPeriod(1);

    wchar_t exe[MAX_PATH], dir[MAX_PATH];
    GetModuleFileNameW(NULL, exe, MAX_PATH);
    wcscpy(dir, exe);
    wchar_t *sl = wcsrchr(dir, L'\\');
    if (sl) *sl = 0;
    swprintf(ini_path, MAX_PATH, L"%ls\\pinball_ns.ini", dir);
    swprintf(cfg_path, MAX_PATH, L"%ls\\pinball_ns.cfg", dir);
    swprintf(old_ini_path, MAX_PATH, L"%ls\\pinball_tc.ini", dir);     /* Pinball TC's, if any */
    swprintf(old_cfg_path, MAX_PATH, L"%ls\\pinball_tc.cfg", dir);
    cfg_load();

    create_window(inst);
    if (!hwnd) return 1;

    /* the ROM: command line / drag and drop on the .exe, last one used, next to the
     * program, or ask */
    int argc = 0;
    wchar_t **argv = CommandLineToArgvW(GetCommandLineW(), &argc);
    bool have = false;
    if (argv && argc > 4 && !wcscmp(argv[1], L"-selftest")) {
        selftest = true;
        st.secs = _wtof(argv[2]);
        wcsncpy(st.report, argv[4], MAX_PATH - 1);
        have = try_rom(argv[3], true);
        if (!have) return 2;
    } else if (argv && argc > 1) have = try_rom(argv[1], true);
    if (!have) {
        wchar_t last[MAX_PATH];
        if (ini_load_rom(last)) have = try_rom(last, false);
    }
    if (!have) have = find_rom_near_exe(dir);
    if (!have) {
        MessageBoxW(hwnd,
            L"Welcome!\n\nPinball NS needs the ROM of your own Pokémon Pinball cartridge "
            L"(US version, .gbc file). It is not included.\n\n"
            L"Choose it in the next window. It will be remembered next time.",
            APP_TITLE, MB_ICONINFORMATION);
        have = ask_rom();
    }
    if (argv) LocalFree(argv);
    if (!have) return 0;

    if (!selftest) {
        ShowWindow(hwnd, show);
        UpdateWindow(hwnd);
    }
    xinput_load();
    io_start();
    refresh_init();
    pacer_reset(&pacer);
    audio_open();
    if (selftest) {
        if (wout) waveOutSetVolume(wout, 0);
        st.start = qpc_now();
        st.level_min = 1e9;
    }
    sav_check_tick = GetTickCount();
    bool was_active = false;

    while (running) {
        MSG m;
        while (PeekMessageW(&m, NULL, 0, 0, PM_REMOVE)) {
            if (m.message == WM_QUIT) running = false;
            TranslateMessage(&m);
            DispatchMessageW(&m);
        }
        if (!running) break;
        pad_poll();

        bool active = !paused && !ctl_wnd && !IsIconic(hwnd);
        if (active) {
            /* the display sets the pace; the sound follows (pacing.h) */
            double t = wait_refresh(hwnd);
            if (!was_active) {
                pacer_restart(&pacer);
                if (audio_ok) sound_restart(&snd, t);       /* the card was paused: measured afresh */
            }
            int n = pacer_frames(&pacer, t, 6);
            if (selftest) kb_buttons = (frame_seq % 90) < 6 ? 0x01 : 0;       /* A, now and then */
            bool extra = false;
            for (int k = 0; k < n; k++) {
                /* the sound may ask for one frame more (its target raised: pacing.h) */
                if (audio_pace(t, n - k) == SOUND_EXTRA && !extra) { extra = true; n++; }
                run_one_frame();
            }
            present();                                      /* every refresh: composed at the next */
            if (selftest) {
                double e = qpc_now();
                if (t - st.start > 3) {
                    st.refreshes++;
                    st.frames += n;
                    st.work_sum += e - t;
                    if (e - t > st.work_max) st.work_max = e - t;
                    if (st.last > 0 && t - st.last > st.dt_max) st.dt_max = t - st.last;
                    if (pacer.den) {
                        int most = (pacer.num + pacer.den - 1) / pacer.den, least = pacer.num / pacer.den;
                        if (n > most || n < least) st.odd++;
                    }
                }
                st.last = t;
                if (e - st.start > st.secs) running = false;
            }
        } else if (osd[0] && (int32_t)(GetTickCount() - osd_until) >= 0) {
            osd[0] = 0;
            InvalidateRect(hwnd, NULL, FALSE);
        }
        was_active = active;

        DWORD now = GetTickCount();
        if (now - sav_check_tick > 1000) {
            sav_check_tick = now;
            /* the game's own key configuration must stay the default one (the mapping is here) */
            int fix = pb_fix_key_config(pb);
            if (fix) {
                sram_flush(true);
                if (fix == 2) { wchar_t p[MAX_PATH]; wcscpy(p, rom_path); try_rom(p, false); }
                show_osd(L"Game key config reset to the defaults (F2: controls)");
            }
            double f0 = qpc_now();
            LONG before = io_state;
            sram_flush_mode(false, true);
            if (selftest) {
                double f = qpc_now() - f0;
                if (f > st.flush_max) st.flush_max = f;
                if (!before && io_state) st.sram_writes++;
            }
        }

        if (!active) MsgWaitForMultipleObjects(0, NULL, FALSE, 50, QS_ALLINPUT);
    }

    pad_rumble(false);
    sram_flush(false);
    if (selftest) {
        FILE *f = _wfopen(st.report, L"w");
        if (f) {
            double run = st.last - st.start - 3;
            fprintf(f, "refreshes %ld (%.2f Hz)  frames %ld (%.3f a second)  ratio %d/%d  out of pattern %ld\n",
                    st.refreshes, st.refreshes / run, st.frames, st.frames / run, pacer.num, pacer.den, st.odd);
            fprintf(f, "longest between refreshes %.2f ms  work per refresh %.2f ms (longest %.2f)\n",
                    st.dt_max * 1000, st.work_sum / (st.refreshes ? st.refreshes : 1) * 1000, st.work_max * 1000);
            fprintf(f, "sound: waiting %.0f..%.0f  starving %ld  silences added %ld  dropped %ld  frames added %ld  target %.0f  "
                    "card %.1f Hz (measured %.1f)\n", st.level_min, st.level_max, st.starving, st.pads, st.flushes, snd.extra,
                    snd.target, snd.rate, snd.measured);
            fprintf(f, "cartridge save: %ld writes handed over, longest call %.3f ms\n", st.sram_writes, st.flush_max * 1000);
            fclose(f);
        }
    }
    audio_close();
    timeEndPeriod(1);
    DestroyWindow(hwnd);
    return 0;
}
