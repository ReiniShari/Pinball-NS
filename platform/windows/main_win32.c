/*
 * main_win32.c - Windows front-end of Pinball NS (Pokemon Pinball, the whole table on one screen).
 *
 * Pure Win32 (GDI, waveOut, XInput and hid.dll loaded at run time): a single .exe, nothing to
 * install. The ROM is never included: the player gives the program the ROM dumped from their
 * own cartridge (command line, drag and drop, or a file dialog). What the desktop versions share
 * (the game, its saves, the settings and controls, the pictures, the function keys) is in
 * platform/desktop/desk.c; this file is the window, the sound, the keys, the mouse and touches,
 * the gamepads, and the windows of the controls and of "about".
 *
 * Default controls (keyboard)               (gamepad: Xbox, PlayStation, Switch Pro, others)
 *   left flipper   Left Shift, Z, W, Left     LB, LT, D-pad left
 *   right flipper  Right Shift, X, Space      RB, RT, A
 *   tilt           Down (left), C (right),    D-pad down, B / X, Y / Back
 *                  V (up)
 *   menus          arrows, X / Enter / C      D-pad, A, B
 *   pause menu     Enter (Start)              Start
 * F2 (or the window menu) changes them: the input mapping tool.
 *   F3: handheld mode (the screen of the Android version: its touch keys with the mouse or the
 *   fingers, a touch screen)   F4: its keys hidden in a game   F11 or Alt+Enter: full screen
 *   F10: sharp/smooth scaling   P: pause   F1: about   F8: the table at its original width or whole
 *   F6: screen filter (none, dots, LCD)   F7: colours (original, black and white, Game Boy green)
 *   F5: save state  F9: load state  Esc: leave full screen (handheld: the menu)
 * The ROM: Pokemon Pinball (US), or Pokemon Pinball Generations 1.6 (its four tables, unified too).
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
#include "../desktop/desk.h"
#include "../../src/front/pacing.h"
#include "refresh_win.h"

#define APP_TITLE   L"Pinball NS"
#define APP_VERSION L"2.9"
#define AUDIO_RATE  DESK_RATE
#define NBUF        12
#define BUF_FRAMES  512
#define AUDIO_TARGET 2048             /* frames kept ahead of the sound card (~43 ms) */

/* ------------------------------------------------------------------ state */

static Desk D;                        /* the game, its settings and controls, the pictures (desk.h) */
static wchar_t exe_dir[MAX_PATH], ini_path[MAX_PATH], old_ini_path[MAX_PATH];

static HWND hwnd;
static bool running = true, fullscreen;
static WINDOWPLACEMENT prev_place;
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
static uint32_t frame_seq;

/* -selftest: the pace kept, written at the end */
static struct {
    double secs, start, last, work_max, work_sum, dt_max, flush_max, level_min, level_max;
    long refreshes, frames, odd, starving, pads, flushes;
    wchar_t report[MAX_PATH];
} st;
static bool selftest;

/* ------------------------------------------------------------------ helpers */

static void to_utf8(const wchar_t *w, char *out, int n) { WideCharToMultiByte(CP_UTF8, 0, w, -1, out, n, NULL, NULL); }
static void to_wide(const char *s, wchar_t *out, int n) { MultiByteToWideChar(CP_UTF8, 0, s, -1, out, n); }

static void set_title(void)
{
    if (hwnd) SetWindowTextW(hwnd, D.pb && D.pb->rom->id == PB_ROM_GENERATIONS ? APP_TITLE L" - Generations" : APP_TITLE);
}

/* load and check a ROM; on success the game is (re)started with it */
static bool try_rom(const wchar_t *path, bool report)
{
    char p[DESK_PATH], err[1024];
    wchar_t full[MAX_PATH];
    if (!GetFullPathNameW(path, MAX_PATH, full, NULL)) wcsncpy(full, path, MAX_PATH - 1), full[MAX_PATH - 1] = 0;
    to_utf8(full, p, DESK_PATH);
    if (!desk_open_rom(&D, p, err, sizeof err)) {
        if (report) {
            wchar_t msg[1100];
            to_wide(err, msg, 1100);
            MessageBoxW(hwnd, msg, APP_TITLE, MB_ICONWARNING);
        }
        return false;
    }
    set_title();
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
    ofn.lpstrTitle = L"Choose the ROM of your Pokémon Pinball cartridge (US), or of Pokémon Pinball Generations";
    ofn.Flags = OFN_FILEMUSTEXIST | OFN_PATHMUSTEXIST | OFN_HIDEREADONLY;
    for (;;) {
        if (!GetOpenFileNameW(&ofn)) return false;
        if (try_rom(file, true)) return true;
    }
}

/* the ROM of 2.8 and before: its path in pinball_ns.ini (UTF-16), or in Pinball TC's */
static bool ini_load_rom(wchar_t *out)
{
    for (int k = 0; k < 2; k++) {
        FILE *f = _wfopen(k ? old_ini_path : ini_path, L"rb");
        if (!f) continue;
        size_t n = fread(out, sizeof(wchar_t), MAX_PATH - 1, f);
        fclose(f);
        out[n] = 0;
        if (out[0]) return true;
    }
    return false;
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

static void audio_hold(bool hold)
{
    if (!wout) return;
    if (hold) waveOutPause(wout); else waveOutRestart(wout);
}

/* move the emulator's new samples to the sound card (SOUND: OFF in the handheld menu: silence) */
static void audio_pump(void)
{
    int16_t tmp[4096];
    int n;
    while ((n = pb_audio(D.pb, tmp, 2048)) > 0) {
        if (!audio_ok) continue;
        if (!D.sound) memset(tmp, 0, (size_t)n * 4);
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
    pb_set_audio_rate(D.pb, rate);
    return act;
}

/* ------------------------------------------------------------------ gamepads */

/*
 * Every gamepad is read into the layout of an Xbox gamepad (desk.h: PAD_*): XInput (Xbox gamepads and
 * the many that act as one); the others through raw input and hid.dll (2.9): DualShock 4, DualSense,
 * Switch Pro, and any HID gamepad (8BitDo in its D-input mode, Logitech, arcade sticks...), their
 * buttons by number as most of them number them (1 west, 2 south, 3 east, 4 north, 5-8 shoulders and
 * triggers, 9 back, 10 start, 11-12 sticks, 13 home; the Switch Pro: 1 south, 2 east, 3 west, 4 north),
 * the hat as the D-pad, X / Y the left stick, the triggers as axes when they have them. The inputs of
 * all the gamepads count together.
 */
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

/* the inputs of the XInput gamepad (bit = PAD_*), -1 when there is none */
static long xinput_inputs(void)
{
    if (!xget) return -1;
    XState s;
    if (pad_index < 0) {
        DWORD now = GetTickCount();
        if (now - pad_scan_tick < 1000) return -1;   /* polling absent pads is slow */
        pad_scan_tick = now;
        for (int i = 0; i < 4; i++) if (xget((DWORD)i, &s) == ERROR_SUCCESS) { pad_index = i; break; }
        if (pad_index < 0) return -1;
    }
    if (xget((DWORD)pad_index, &s) != ERROR_SUCCESS) { pad_index = -1; return -1; }
    long in = s.Gamepad.wButtons;
    if (s.Gamepad.bLeftTrigger > 40) in |= 1L << PAD_LT;
    if (s.Gamepad.bRightTrigger > 40) in |= 1L << PAD_RT;
    if (s.Gamepad.sThumbLX < -16000) in |= 1L << PAD_LS_LEFT;
    if (s.Gamepad.sThumbLX > 16000) in |= 1L << PAD_LS_RIGHT;
    if (s.Gamepad.sThumbLY > 16000) in |= 1L << PAD_LS_UP;
    if (s.Gamepad.sThumbLY < -16000) in |= 1L << PAD_LS_DOWN;
    return in;
}

/* hid.dll (HidP_*), its structures as the SDK has them */
typedef struct { USHORT Usage, UsagePage; USHORT InputReportByteLength, OutputReportByteLength, FeatureReportByteLength;
                 USHORT Reserved[17]; USHORT NumberLinkCollectionNodes, NumberInputButtonCaps, NumberInputValueCaps,
                 NumberInputDataIndices, NumberOutputButtonCaps, NumberOutputValueCaps, NumberOutputDataIndices,
                 NumberFeatureButtonCaps, NumberFeatureValueCaps, NumberFeatureDataIndices; } HidCaps;
typedef struct { USHORT UsagePage; UCHAR ReportID; BOOLEAN IsAlias; USHORT BitField, LinkCollection, LinkUsage, LinkUsagePage;
                 BOOLEAN IsRange, IsStringRange, IsDesignatorRange, IsAbsolute; ULONG Reserved[10];
                 union { struct { USHORT UsageMin, UsageMax, StringMin, StringMax, DesignatorMin, DesignatorMax, DataIndexMin, DataIndexMax; } Range;
                         struct { USHORT Usage, Reserved1, StringIndex, Reserved2, DesignatorIndex, Reserved3, DataIndex, Reserved4; } NotRange; }; } HidButtonCaps;
typedef struct { USHORT UsagePage; UCHAR ReportID; BOOLEAN IsAlias; USHORT BitField, LinkCollection, LinkUsage, LinkUsagePage;
                 BOOLEAN IsRange, IsStringRange, IsDesignatorRange, IsAbsolute, HasNull; UCHAR Reserved; USHORT BitSize, ReportCount;
                 USHORT Reserved2[5]; ULONG UnitsExp, Units; LONG LogicalMin, LogicalMax, PhysicalMin, PhysicalMax;
                 union { struct { USHORT UsageMin, UsageMax, StringMin, StringMax, DesignatorMin, DesignatorMax, DataIndexMin, DataIndexMax; } Range;
                         struct { USHORT Usage, Reserved1, StringIndex, Reserved2, DesignatorIndex, Reserved3, DataIndex, Reserved4; } NotRange; }; } HidValueCaps;
typedef LONG (WINAPI *HidGetCapsFn)(void *, HidCaps *);
typedef LONG (WINAPI *HidGetButtonCapsFn)(int, HidButtonCaps *, USHORT *, void *);
typedef LONG (WINAPI *HidGetValueCapsFn)(int, HidValueCaps *, USHORT *, void *);
typedef LONG (WINAPI *HidGetUsagesFn)(int, USHORT, USHORT, USHORT *, ULONG *, void *, CHAR *, ULONG);
typedef LONG (WINAPI *HidGetUsageValueFn)(int, USHORT, USHORT, USHORT, ULONG *, void *, CHAR *, ULONG);
static HidGetCapsFn hid_caps;
static HidGetButtonCapsFn hid_button_caps;
static HidGetValueCapsFn hid_value_caps;
static HidGetUsagesFn hid_usages;
static HidGetUsageValueFn hid_value;
#define HID_OK 0x00110000L

#define MAX_HID 4
static struct {
    HANDLE dev;
    uint8_t *prep;                   /* its preparsed data */
    int kind;                        /* 0 generic, 1 Nintendo (Switch Pro), 2 Sony (its triggers on Rx, Ry) */
    HidValueCaps val[24];
    int nval;
    long in;                         /* its inputs */
} hid[MAX_HID];
static int nhid;

static void hid_load(void)
{
    HMODULE m = LoadLibraryW(L"hid.dll");
    if (!m) return;
    hid_caps = (HidGetCapsFn)(void (*)(void))GetProcAddress(m, "HidP_GetCaps");
    hid_button_caps = (HidGetButtonCapsFn)(void (*)(void))GetProcAddress(m, "HidP_GetButtonCaps");
    hid_value_caps = (HidGetValueCapsFn)(void (*)(void))GetProcAddress(m, "HidP_GetValueCaps");
    hid_usages = (HidGetUsagesFn)(void (*)(void))GetProcAddress(m, "HidP_GetUsages");
    hid_value = (HidGetUsageValueFn)(void (*)(void))GetProcAddress(m, "HidP_GetUsageValue");
    if (!hid_caps || !hid_value_caps || !hid_usages || !hid_value) { hid_caps = NULL; return; }
    RAWINPUTDEVICE rid[2] = { { 0x01, 0x04, RIDEV_INPUTSINK | RIDEV_DEVNOTIFY, hwnd },     /* joysticks */
                              { 0x01, 0x05, RIDEV_INPUTSINK | RIDEV_DEVNOTIFY, hwnd } };   /* gamepads */
    RegisterRawInputDevices(rid, 2, sizeof rid[0]);
}

/* a gamepad seen for the first time (XInput ones are read through XInput: their name has "IG_") */
static int hid_slot(HANDLE dev)
{
    for (int i = 0; i < nhid; i++) if (hid[i].dev == dev) return i;
    if (nhid == MAX_HID) return -1;
    wchar_t name[512];
    UINT n = 512;
    if (GetRawInputDeviceInfoW(dev, RIDI_DEVICENAME, name, &n) == (UINT)-1) return -1;
    if (wcsstr(name, L"IG_") || wcsstr(name, L"ig_")) return -1;
    UINT sz = 0;
    GetRawInputDeviceInfoW(dev, RIDI_PREPARSEDDATA, NULL, &sz);
    if (!sz) return -1;
    uint8_t *prep = (uint8_t *)malloc(sz);
    if (!prep || GetRawInputDeviceInfoW(dev, RIDI_PREPARSEDDATA, prep, &sz) == (UINT)-1) { free(prep); return -1; }
    RID_DEVICE_INFO info;
    info.cbSize = sizeof info;
    UINT isz = sizeof info;
    int kind = 0;
    if (GetRawInputDeviceInfoW(dev, RIDI_DEVICEINFO, &info, &isz) != (UINT)-1 && info.dwType == RIM_TYPEHID &&
        info.hid.dwVendorId == 0x057E) kind = 1;                       /* Nintendo */
    else if (info.dwType == RIM_TYPEHID && info.hid.dwVendorId == 0x054C) kind = 2;   /* Sony */
    int i = nhid++;
    memset(&hid[i], 0, sizeof hid[i]);
    hid[i].dev = dev;
    hid[i].prep = prep;
    hid[i].kind = kind;
    HidCaps caps;
    if (hid_caps(prep, &caps) == HID_OK) {
        USHORT nv = (USHORT)(caps.NumberInputValueCaps < 24 ? caps.NumberInputValueCaps : 24);
        if (nv && hid_value_caps(0, hid[i].val, &nv, prep) == HID_OK) hid[i].nval = nv;
    }
    return i;
}

/* an axis read as -1..1 */
static double hid_axis(int i, const HidValueCaps *c, uint8_t *rep, ULONG len)
{
    ULONG v;
    USHORT usage = c->IsRange ? c->Range.UsageMin : c->NotRange.Usage;
    if (hid_value(0, c->UsagePage, 0, usage, &v, hid[i].prep, (CHAR *)rep, len) != HID_OK) return 0;
    LONG lo = c->LogicalMin, hi = c->LogicalMax;
    if (hi <= lo) { lo = 0; hi = (LONG)((1u << c->BitSize) - 1); }
    return (2.0 * ((LONG)v - lo) / (double)(hi - lo)) - 1.0;
}

static void hid_report(HANDLE dev, uint8_t *rep, ULONG len)
{
    if (!hid_caps) return;
    int i = hid_slot(dev);
    if (i < 0) return;
    long in = 0;
    USHORT us[64];
    ULONG n = 64;
    if (hid_usages(0, 0x09, 0, us, &n, hid[i].prep, (CHAR *)rep, len) == HID_OK)
        for (ULONG k = 0; k < n; k++) {
            static const int8_t generic[16] = { PAD_X, PAD_A, PAD_B, PAD_Y, PAD_LB, PAD_RB, PAD_LT, PAD_RT, PAD_BACK, PAD_START,
                                                PAD_LTHUMB, PAD_RTHUMB, PAD_GUIDE, PAD_MISC, -1, -1 };
            static const int8_t nintendo[16] = { PAD_A, PAD_B, PAD_X, PAD_Y, PAD_LB, PAD_RB, PAD_LT, PAD_RT, PAD_BACK, PAD_START,
                                                 PAD_LTHUMB, PAD_RTHUMB, PAD_GUIDE, PAD_MISC, -1, -1 };
            int b = us[k] - 1;
            if (b < 0 || b >= 16) continue;
            int p = hid[i].kind == 1 ? nintendo[b] : generic[b];
            if (p >= 0) in |= 1L << p;
        }
    for (int v = 0; v < hid[i].nval; v++) {
        const HidValueCaps *c = &hid[i].val[v];
        if (c->UsagePage != 0x01) continue;
        USHORT usage = c->IsRange ? c->Range.UsageMin : c->NotRange.Usage;
        if (usage == 0x39) {                                         /* the hat: 8 directions, else centred */
            ULONG h;
            if (hid_value(0, 0x01, 0, 0x39, &h, hid[i].prep, (CHAR *)rep, len) != HID_OK) continue;
            long d = (long)h - c->LogicalMin;
            if (d < 0 || d > 7) continue;
            static const uint8_t dirs[8] = { 1, 9, 8, 10, 2, 6, 4, 5 };   /* bits: up 1, down 2, left 4, right 8 */
            if (dirs[d] & 1) in |= 1L << PAD_DUP;
            if (dirs[d] & 2) in |= 1L << PAD_DDOWN;
            if (dirs[d] & 4) in |= 1L << PAD_DLEFT;
            if (dirs[d] & 8) in |= 1L << PAD_DRIGHT;
            continue;
        }
        double a = hid_axis(i, c, rep, len);
        if (usage == 0x30) { if (a < -0.5) in |= 1L << PAD_LS_LEFT; if (a > 0.5) in |= 1L << PAD_LS_RIGHT; }
        else if (usage == 0x31) { if (a < -0.5) in |= 1L << PAD_LS_UP; if (a > 0.5) in |= 1L << PAD_LS_DOWN; }
        else if (hid[i].kind == 2 && usage == 0x33 && a > -0.4) in |= 1L << PAD_LT;   /* Rx, Ry: the triggers of the */
        else if (hid[i].kind == 2 && usage == 0x34 && a > -0.4) in |= 1L << PAD_RT;   /* PlayStation pads (else a stick) */
    }
    hid[i].in = in;
}

static void hid_removed(HANDLE dev)
{
    for (int i = 0; i < nhid; i++)
        if (hid[i].dev == dev) {
            free(hid[i].prep);
            hid[i] = hid[--nhid];
            return;
        }
}

/* the inputs of every gamepad together, -1 when there is none */
static long pad_inputs(void)
{
    long in = xinput_inputs();
    for (int i = 0; i < nhid; i++) in = (in < 0 ? 0 : in) | hid[i].in;
    return in;
}

static void pad_rumble(bool on)
{
    if (!xset || pad_index < 0 || on == pad_rumbling) return;
    XVibration v = { (WORD)(on ? 30000 : 0), (WORD)(on ? 42000 : 0) };
    xset((DWORD)pad_index, &v);
    pad_rumbling = on;
}

/* ------------------------------------------------------------------ keyboard */

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
    for (int k = 0; k < DESK_MAXB; k++) {
        wchar_t name[48];
        if (col == 0) { if (!D.keymap[a][k]) continue; key_name(D.keymap[a][k], name, 48); }
        else { if (!D.padmap[a][k]) continue; to_wide(desk_pad_name[D.padmap[a][k] - 1], name, 48); }
        if (out[0] && wcslen(out) + 2 < (size_t)n) wcscat(out, L", ");
        if (wcslen(out) + wcslen(name) < (size_t)n) wcscat(out, name);
    }
    if (!out[0]) wcsncpy(out, L"-", (size_t)n);
}

static void ctl_bind(int a, int col, unsigned v)
{
    /* one button per input: taken off the others */
    for (int b = 0; b < ACT_N; b++)
        for (int k = 0; k < DESK_MAXB; k++) {
            unsigned cur = col == 0 ? D.keymap[b][k] : D.padmap[b][k];
            if (cur != (col == 0 ? v : v + 1)) continue;
            for (int j = k; j < DESK_MAXB - 1; j++) {
                if (col == 0) D.keymap[b][j] = D.keymap[b][j + 1]; else D.padmap[b][j] = D.padmap[b][j + 1];
            }
            if (col == 0) D.keymap[b][DESK_MAXB - 1] = 0; else D.padmap[b][DESK_MAXB - 1] = 0;
            k--;
        }
    int k = 0;
    while (k < DESK_MAXB && (col == 0 ? D.keymap[a][k] : D.padmap[a][k])) k++;
    if (k == DESK_MAXB) {                      /* full: the oldest one goes */
        for (int j = 0; j < DESK_MAXB - 1; j++) {
            if (col == 0) D.keymap[a][j] = D.keymap[a][j + 1]; else D.padmap[a][j] = D.padmap[a][j + 1];
        }
        k = DESK_MAXB - 1;
    }
    if (col == 0) D.keymap[a][k] = (uint16_t)v; else D.padmap[a][k] = (uint8_t)(v + 1);
    desk_cfg_save(&D);
    ctl_msg[0] = 0;
}

static void ctl_clear(int a, int col)
{
    if (col == 0) memset(D.keymap[a], 0, sizeof D.keymap[a]); else memset(D.padmap[a], 0, sizeof D.padmap[a]);
    desk_cfg_save(&D);
}

static void ctl_wait(int row, int col)
{
    ctl_row = row;
    ctl_col = col;
    long in = pad_inputs();
    ctl_pad_held = in > 0 ? in : 0;
    wchar_t name[64];
    to_wide(desk_act_name[row], name, 64);
    swprintf(ctl_msg, 200, col == 0 ? L"%ls: press a key (Esc: cancel, Delete: clear)"
                                    : L"%ls: press a gamepad button (Esc: cancel, Delete: clear)", name);
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
        to_wide(desk_act_gb[a], t, 160);
        TextOutW(mem, ctl_col_x(0), y, t, (int)wcslen(t));
        SelectObject(mem, f);
        to_wide(desk_act_name[a], t, 160);
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
    desk_cfg_save(&D);
    if (!D.paused) audio_hold(false);
    desk_keys_released(&D);
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
            desk_map_defaults(&D);
            desk_cfg_save(&D);
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
            if (desk_key_reserved(vk)) wcscpy(ctl_msg, L"F1 to F11, P, Pause and Esc are kept by Pinball NS.");
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
    case WM_INPUT: {                          /* the HID gamepads, while the tool has the focus */
        UINT sz = 0;
        GetRawInputData((HRAWINPUT)lp, RID_INPUT, NULL, &sz, sizeof(RAWINPUTHEADER));
        static uint8_t buf[2048];
        if (sz && sz <= sizeof buf && GetRawInputData((HRAWINPUT)lp, RID_INPUT, buf, &sz, sizeof(RAWINPUTHEADER)) == sz) {
            RAWINPUT *ri = (RAWINPUT *)buf;
            if (ri->header.dwType == RIM_TYPEHID && ri->data.hid.dwCount)
                hid_report(ri->header.hDevice, ri->data.hid.bRawData, ri->data.hid.dwSizeHid);
        }
        break;
    }
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
    audio_hold(true);
    ctl_wnd = CreateWindowExW(WS_EX_DLGMODALFRAME, L"PinballNSControls", L"Pinball NS - Controls", style, x, y, ww, wh, hwnd,
                              NULL, inst, NULL);
    if (!ctl_wnd) { if (!D.paused) audio_hold(false); return; }
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
    desk_keys_released(&D);
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
        L"Made by Reinhard Sharapov 2026. Controls of the handheld mode after a design by Gianchy3000.\n"
        L"Pokémon Pinball Generations by RainbowDevs (formerly TPPDevs).\n\n"
        L"Pokémon Pinball © 1995-1999 Nintendo, Creatures Inc., GAME FREAK inc.\n"
        L"© 1999 HAL Laboratory, Inc., Jupiter Corp.\n"
        L"Pokémon, Pokémon character names, Game Boy and Game Boy Color are trademarks of Nintendo.\n\n"
        L"Pinball NS contains no part of the game: it plays the ROM dumped from your own cartridge.\n\n"
        L"F1: about   F2: controls   F3: handheld mode   F4: its keys hidden in a game\n"
        L"F5 / F9: save / load state   F8: table width   F10: sharp / smooth   F11 or Alt+Enter: full screen\n"
        L"F6: screen filter (none, dots, LCD)   F7: colours (original, black and white, Game Boy green)   P: pause";
    bool was = D.paused;
    D.paused = true;
    audio_hold(true);
    MessageBoxIndirectW(&mb);
    D.paused = was;
    if (!D.paused) audio_hold(false);
    desk_keys_released(&D);
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
            if (!D.handheld) ShowCursor(FALSE);
        }
    } else if (!on && fullscreen) {
        SetWindowLongW(hwnd, GWL_STYLE, (LONG)(style | WS_OVERLAPPEDWINDOW));
        SetWindowPlacement(hwnd, &prev_place);
        SetWindowPos(hwnd, NULL, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_FRAMECHANGED);
        fullscreen = false;
        if (!D.handheld) ShowCursor(TRUE);
    }
}

/* The screen filter and the colours (screenfx.h): the cells that changed, by bands of rows shared out
 * between a few threads when there are many (a fade, a new screen: every cell). */
static int fx_nthreads = -1;
static HANDLE fx_go[3], fx_done[3];
static volatile int fx_band[3][2];
static ScreenFx *fx_cur;

static DWORD WINAPI fx_worker(LPVOID arg)
{
    int i = (int)(INT_PTR)arg;
    for (;;) {
        WaitForSingleObject(fx_go[i], INFINITE);
        screenfx_rows(fx_cur, fx_band[i][0], fx_band[i][1]);
        SetEvent(fx_done[i]);
    }
}

static void fx_make(ScreenFx *sfx)
{
    if (fx_nthreads < 0) {
        SYSTEM_INFO si;
        GetSystemInfo(&si);
        int n = (int)si.dwNumberOfProcessors - 1;
        fx_nthreads = n < 0 ? 0 : n > 3 ? 3 : n;
        for (int i = 0; i < fx_nthreads; i++) {
            fx_go[i] = CreateEventW(NULL, FALSE, FALSE, NULL);
            fx_done[i] = CreateEventW(NULL, FALSE, FALSE, NULL);
            HANDLE t = fx_go[i] && fx_done[i] ? CreateThread(NULL, 0, fx_worker, (LPVOID)(INT_PTR)i, 0, NULL) : NULL;
            if (!t) { fx_nthreads = i; break; }
            CloseHandle(t);
        }
    }
    long dirty = 0;
    for (int i = 0; i < sfx->w * sfx->h; i++) dirty += sfx->dirty[i];
    if (dirty * sfx->k * sfx->k < 200000 || fx_nthreads == 0) { screenfx_rows(sfx, 0, sfx->h); return; }
    int n = fx_nthreads + 1;
    fx_cur = sfx;
    for (int i = 0; i < fx_nthreads; i++) {
        fx_band[i][0] = sfx->h * i / n;
        fx_band[i][1] = sfx->h * (i + 1) / n;
        SetEvent(fx_go[i]);
    }
    screenfx_rows(sfx, sfx->h * fx_nthreads / n, sfx->h);
    WaitForMultipleObjects((DWORD)fx_nthreads, fx_done, TRUE, INFINITE);
}

static void paint(HDC dc)
{
    RECT rc;
    GetClientRect(hwnd, &rc);
    int cw = rc.right, ch = rc.bottom;
    HBRUSH black = (HBRUSH)GetStockObject(BLACK_BRUSH);
    if (!D.pb || cw <= 0 || ch <= 0) { FillRect(dc, &rc, black); return; }
    DeskPicture p;
    desk_picture(&D, cw, ch, &p);
    if (!p.px) { FillRect(dc, &rc, black); return; }

    RECT r;
    if (p.y > 0) { SetRect(&r, 0, 0, cw, p.y); FillRect(dc, &r, black); }
    if (p.y + p.dh < ch) { SetRect(&r, 0, p.y + p.dh, cw, ch); FillRect(dc, &r, black); }
    if (p.x > 0) { SetRect(&r, 0, p.y, p.x, p.y + p.dh); FillRect(dc, &r, black); }
    if (p.x + p.dw < cw) { SetRect(&r, p.x + p.dw, p.y, cw, p.y + p.dh); FillRect(dc, &r, black); }

    BITMAPINFO bmi;
    memset(&bmi, 0, sizeof bmi);
    bmi.bmiHeader.biSize = sizeof bmi.bmiHeader;
    bmi.bmiHeader.biWidth = p.stride;
    bmi.bmiHeader.biHeight = -p.h;
    bmi.bmiHeader.biPlanes = 1;
    bmi.bmiHeader.biBitCount = 32;
    bmi.bmiHeader.biCompression = BI_RGB;
    if (p.smooth) { SetStretchBltMode(dc, HALFTONE); SetBrushOrgEx(dc, 0, 0, NULL); }
    else SetStretchBltMode(dc, COLORONCOLOR);
    StretchDIBits(dc, p.x, p.y, p.dw, p.dh, 0, 0, p.w, p.h, p.px, &bmi, DIB_RGB_COLORS, SRCCOPY);

    const char *msg = NULL;
    if (D.paused) msg = "PAUSE (P to resume)";
    else if (D.osd[0] && D.now < D.osd_until) msg = D.osd;
    if (msg && !D.handheld) {
        wchar_t wmsg[200];
        to_wide(msg, wmsg, 200);
        int dw = p.dw < cw ? p.dw : cw, dh = p.dh < ch ? p.dh : ch, y = p.y > 0 ? p.y : 0;
        SetBkMode(dc, OPAQUE);
        SetBkColor(dc, RGB(0, 0, 0));
        SetTextColor(dc, RGB(255, 255, 255));
        int fh_px = dh / 26 < dw / 24 ? dh / 26 : dw / 24;
        if (fh_px < 12) fh_px = 12;
        HFONT f = CreateFontW(-fh_px, 0, 0, 0, FW_BOLD, 0, 0, 0, DEFAULT_CHARSET, 0, 0, CLEARTYPE_QUALITY, 0, L"Segoe UI");
        HGDIOBJ old = SelectObject(dc, f);
        RECT tr = { p.x > 0 ? p.x : 0, y + dh / 2 - dh / 20, (p.x > 0 ? p.x : 0) + dw, y + dh / 2 + dh / 20 };
        DrawTextW(dc, wmsg, -1, &tr, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
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

#define SC_CONTROLS 0x1000             /* window menu entries */
#define SC_ABOUT    0x1010

/* the shape of the window for the display (the table: its zoom kept; the handheld mode: a phone's shape) */
static void reshape(void)
{
    if (fullscreen || IsZoomed(hwnd) || IsIconic(hwnd)) { InvalidateRect(hwnd, NULL, FALSE); return; }
    RECT c, wa;
    GetClientRect(hwnd, &c);
    SystemParametersInfoW(SPI_GETWORKAREA, 0, &wa, 0);
    int w, h;
    if (D.handheld) desk_window_size(&D, wa.right - wa.left, wa.bottom - wa.top, &w, &h);
    else {
        int zoom = (c.bottom + PB_FIELD_H / 2) / PB_FIELD_H;
        if (zoom < 1) zoom = 1;
        w = (D.narrow ? PB_FIELD_W_NARROW : PB_FIELD_W) * zoom;
        h = PB_FIELD_H * zoom;
    }
    RECT r = { 0, 0, w, h };
    AdjustWindowRect(&r, WS_OVERLAPPEDWINDOW, FALSE);
    SetWindowPos(hwnd, NULL, 0, 0, r.right - r.left, r.bottom - r.top, SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE);
    InvalidateRect(hwnd, NULL, FALSE);
}

static void do_action(int a)
{
    switch (a) {
    case DESK_FULLSCREEN: set_fullscreen(!fullscreen); break;
    case DESK_LEAVE_FULLSCREEN: if (fullscreen) set_fullscreen(false); break;
    case DESK_ABOUT: about(); break;
    case DESK_CONTROLS: ctl_open(); break;
    case DESK_RESHAPE: reshape(); break;
    case DESK_PAUSE: audio_hold(D.paused); InvalidateRect(hwnd, NULL, FALSE); break;
    case DESK_REDRAW: InvalidateRect(hwnd, NULL, FALSE); break;
    default: break;
    }
}

/* touches of a touch screen (handheld mode): the pointer messages of Windows 8 and later; the mouse
 * stays the mouse (its messages below) */
#ifndef WM_POINTERUPDATE
#define WM_POINTERUPDATE 0x0245
#define WM_POINTERDOWN   0x0246
#define WM_POINTERUP     0x0247
#endif
typedef BOOL (WINAPI *GetPointerTypeFn)(UINT32, DWORD *);
static GetPointerTypeFn get_pointer_type;

static bool touch_message(UINT msg, WPARAM wp, LPARAM lp)
{
    if (!get_pointer_type) return false;
    UINT32 id = LOWORD(wp);
    DWORD type = 0;
    if (!get_pointer_type(id, &type) || type == 4 /* PT_MOUSE */) return false;
    POINT pt = { (short)LOWORD(lp), (short)HIWORD(lp) };
    ScreenToClient(hwnd, &pt);
    int action = msg == WM_POINTERDOWN ? UI_DOWN : msg == WM_POINTERUP ? UI_UP : UI_MOVE;
    desk_pointer(&D, action, (int)(id & 0x7FFF) + 1, (float)pt.x, (float)pt.y);
    return true;
}

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
        if (wp == SIZE_MINIMIZED) audio_hold(true);
        else if (!D.paused) audio_hold(false);
        InvalidateRect(h, NULL, FALSE);
        return 0;
    case WM_KILLFOCUS:
        desk_keys_released(&D);
        if (D.handheld) desk_pointer(&D, UI_CANCEL, 0, 0, 0);
        return 0;
    case WM_SYSCOMMAND:
        if ((wp & 0xFFF0) == SC_CONTROLS) { ctl_open(); return 0; }
        if ((wp & 0xFFF0) == SC_ABOUT) { about(); return 0; }
        break;
    case WM_SYSKEYDOWN:
    case WM_KEYDOWN:
        do_action(desk_key(&D, msg_key(wp, lp), true, (lp & (1 << 30)) != 0));
        /* F10 and Alt+Enter: not the window's menu; the other Alt keys as usual (Alt+F4 closes) */
        if (msg == WM_SYSKEYDOWN && wp != VK_F10 && !(wp == VK_RETURN && (lp & (1 << 29)))) break;
        return 0;
    case WM_KEYUP:
    case WM_SYSKEYUP:
        desk_key(&D, msg_key(wp, lp), false, false);
        if (msg == WM_SYSKEYUP) break;
        return 0;
    case WM_SYSCHAR:
        return 0;                             /* no beep for Alt + key */
    case WM_LBUTTONDOWN:
        SetCapture(h);
        desk_pointer(&D, UI_DOWN, 0, (float)(short)LOWORD(lp), (float)(short)HIWORD(lp));
        return 0;
    case WM_MOUSEMOVE:
        if (wp & MK_LBUTTON) desk_pointer(&D, UI_MOVE, 0, (float)(short)LOWORD(lp), (float)(short)HIWORD(lp));
        return 0;
    case WM_LBUTTONUP:
        ReleaseCapture();
        desk_pointer(&D, UI_UP, 0, (float)(short)LOWORD(lp), (float)(short)HIWORD(lp));
        return 0;
    case WM_POINTERDOWN:
    case WM_POINTERUPDATE:
    case WM_POINTERUP:
        if (D.handheld && touch_message(msg, wp, lp)) return 0;
        break;
    case WM_INPUT: {
        UINT sz = 0;
        GetRawInputData((HRAWINPUT)lp, RID_INPUT, NULL, &sz, sizeof(RAWINPUTHEADER));
        static uint8_t buf[2048];
        if (sz && sz <= sizeof buf && GetRawInputData((HRAWINPUT)lp, RID_INPUT, buf, &sz, sizeof(RAWINPUTHEADER)) == sz) {
            RAWINPUT *ri = (RAWINPUT *)buf;
            if (ri->header.dwType == RIM_TYPEHID && ri->data.hid.dwCount)
                hid_report(ri->header.hDevice, ri->data.hid.bRawData, ri->data.hid.dwSizeHid);
        }
        break;
    }
    case WM_INPUT_DEVICE_CHANGE:
        if (wp == 2 /* GIDC_REMOVAL */) hid_removed((HANDLE)lp);
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

    /* biggest whole zoom of the tall field that fits the screen (the handheld mode: a phone's shape) */
    RECT wa;
    SystemParametersInfoW(SPI_GETWORKAREA, 0, &wa, 0);
    int w, h;
    desk_window_size(&D, wa.right - wa.left, wa.bottom - wa.top, &w, &h);
    RECT r = { 0, 0, w, h };
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
    get_pointer_type = (GetPointerTypeFn)(void (*)(void))GetProcAddress(GetModuleHandleW(L"user32.dll"), "GetPointerType");
}

/* ------------------------------------------------------------------ main */

static void run_one_frame(void)
{
    desk_frame(&D);
    frame_seq++;
    audio_pump();
    pad_rumble(desk_rumble(&D));
}

int WINAPI wWinMain(HINSTANCE inst, HINSTANCE prev, PWSTR cmd, int show)
{
    (void)prev; (void)cmd;
    SetProcessDPIAware();
    timeBeginPeriod(1);

    wchar_t exe[MAX_PATH];
    GetModuleFileNameW(NULL, exe, MAX_PATH);
    wcscpy(exe_dir, exe);
    wchar_t *sl = wcsrchr(exe_dir, L'\\');
    if (sl) *sl = 0;
    wchar_t cfg[MAX_PATH], old_cfg[MAX_PATH];
    swprintf(ini_path, MAX_PATH, L"%ls\\pinball_ns.ini", exe_dir);
    swprintf(old_ini_path, MAX_PATH, L"%ls\\pinball_tc.ini", exe_dir);     /* Pinball TC's, if any */
    swprintf(cfg, MAX_PATH, L"%ls\\pinball_ns.cfg", exe_dir);
    swprintf(old_cfg, MAX_PATH, L"%ls\\pinball_tc.cfg", exe_dir);
    if (GetFileAttributesW(cfg) == INVALID_FILE_ATTRIBUTES) CopyFileW(old_cfg, cfg, TRUE);   /* Pinball TC's settings, once */
    char cfg8[DESK_PATH];
    to_utf8(cfg, cfg8, DESK_PATH);
    desk_init(&D, cfg8);
    D.own_pages = true;
    D.fx_run = fx_make;

    create_window(inst);
    if (!hwnd) return 1;

    /* the ROM: command line / drag and drop on the .exe, last one used, next to the program, or ask */
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
    if (!have && D.rom_paths[0][0]) { wchar_t w[MAX_PATH]; to_wide(D.rom_paths[0], w, MAX_PATH); have = try_rom(w, false); }
    if (!have && D.rom_paths[1][0]) { wchar_t w[MAX_PATH]; to_wide(D.rom_paths[1], w, MAX_PATH); have = try_rom(w, false); }
    if (!have) {
        wchar_t last[MAX_PATH];
        if (ini_load_rom(last)) have = try_rom(last, false);
    }
    if (!have) have = find_rom_near_exe(exe_dir);
    if (!have) {
        MessageBoxW(hwnd,
            L"Welcome!\n\nPinball NS needs the ROM of your own Pokémon Pinball cartridge "
            L"(US version, .gbc file). It is not included. It also plays Pokémon Pinball Generations 1.6 "
            L"(its patch applied to that ROM).\n\n"
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
    hid_load();
    refresh_init();
    pacer_reset(&pacer);
    audio_open();
    if (selftest) {
        if (wout) waveOutSetVolume(wout, 0);
        st.start = qpc_now();
        st.level_min = 1e9;
    }
    bool was_active = false;

    while (running && !D.quit) {
        MSG m;
        while (PeekMessageW(&m, NULL, 0, 0, PM_REMOVE)) {
            if (m.message == WM_QUIT) running = false;
            TranslateMessage(&m);
            DispatchMessageW(&m);
        }
        if (!running) break;
        desk_pad(&D, ctl_wnd ? -1 : pad_inputs());

        bool active = !D.paused && !ctl_wnd && !IsIconic(hwnd);
        /* the display kept on during a game (played with a gamepad, nothing else tells Windows someone is there) */
        if (active != was_active)
            SetThreadExecutionState(active ? ES_CONTINUOUS | ES_DISPLAY_REQUIRED | ES_SYSTEM_REQUIRED : ES_CONTINUOUS);
        if (active) {
            /* the display sets the pace; the sound follows (pacing.h) */
            double t = wait_refresh(hwnd);
            if (!was_active) {
                pacer_restart(&pacer);
                if (audio_ok) sound_restart(&snd, t);       /* the card was paused: measured afresh */
            }
            int n = pacer_frames(&pacer, t, 6);
            if (selftest) desk_key(&D, 'X', (frame_seq % 90) < 6, false);   /* A, now and then */
            bool extra = false;
            for (int k = 0; k < n; k++) {
                /* the sound may ask for one frame more (its target raised: pacing.h) */
                if (audio_pace(t, n - k) == SOUND_EXTRA && !extra) { extra = true; n++; }
                run_one_frame();
            }
            desk_tick(&D, t);
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
        } else {
            if (desk_tick(&D, qpc_now())) InvalidateRect(hwnd, NULL, FALSE);
            MsgWaitForMultipleObjects(0, NULL, FALSE, 50, QS_ALLINPUT);
        }
        was_active = active;
        set_title();
    }

    pad_rumble(false);
    desk_sram_flush(&D, false, false);
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
            fclose(f);
        }
    }
    audio_close();
    desk_free(&D);
    timeEndPeriod(1);
    DestroyWindow(hwnd);
    return 0;
}
