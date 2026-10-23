/*
 * refresh_win.h - waiting for the refreshes of the display on Windows (main_win32.c; measured by
 * tools/refreshtest.c, without a window). Needs <windows.h> and src/front/pacing.h.
 *
 * The game is paced by the refreshes of the display (pacing.h). With the desktop's compositor
 * (always on since Windows 8), DwmFlush returns after each composition: the picture drawn then is
 * composed at the next one, a whole refresh away (drawn right after a vertical blank instead, it
 * would sometimes be composed at once, sometimes a refresh later: an uneven pace). Without it, the
 * vertical blank of the window's monitor (D3DKMT, in gdi32); else a timer at the game's rate.
 */
#ifndef PB_REFRESH_WIN_H
#define PB_REFRESH_WIN_H

static double qpc_now(void)
{
    static LARGE_INTEGER freq;
    LARGE_INTEGER t;
    if (!freq.QuadPart) QueryPerformanceFrequency(&freq);
    QueryPerformanceCounter(&t);
    return (double)t.QuadPart / (double)freq.QuadPart;
}

typedef HRESULT (WINAPI *DwmFlushFn)(void);
typedef HRESULT (WINAPI *DwmIsCompositionEnabledFn)(BOOL *);
typedef struct { HDC hDc; UINT hAdapter; LUID AdapterLuid; UINT VidPnSourceId; } KmtOpenFromHdc;
typedef struct { UINT hAdapter; UINT hDevice; UINT VidPnSourceId; } KmtWaitVblank;
typedef struct { UINT hAdapter; } KmtClose;
typedef LONG (APIENTRY *KmtOpenFn)(KmtOpenFromHdc *);
typedef LONG (APIENTRY *KmtWaitFn)(const KmtWaitVblank *);
typedef LONG (APIENTRY *KmtCloseFn)(const KmtClose *);
static DwmFlushFn dwm_flush;
static DwmIsCompositionEnabledFn dwm_enabled;
static KmtOpenFn kmt_open;
static KmtWaitFn kmt_wait;
static KmtCloseFn kmt_close;
static HMONITOR kmt_monitor;
static KmtWaitVblank kmt_vb;
static bool kmt_ok;

static void refresh_init(void)
{
    HMODULE d = LoadLibraryW(L"dwmapi.dll");
    if (d) {
        dwm_flush = (DwmFlushFn)(void *)GetProcAddress(d, "DwmFlush");
        dwm_enabled = (DwmIsCompositionEnabledFn)(void *)GetProcAddress(d, "DwmIsCompositionEnabled");
    }
    HMODULE g = GetModuleHandleW(L"gdi32.dll");
    if (g) {
        kmt_open = (KmtOpenFn)(void *)GetProcAddress(g, "D3DKMTOpenAdapterFromHdc");
        kmt_wait = (KmtWaitFn)(void *)GetProcAddress(g, "D3DKMTWaitForVerticalBlankEvent");
        kmt_close = (KmtCloseFn)(void *)GetProcAddress(g, "D3DKMTCloseAdapter");
    }
}

/* the graphics adapter of the monitor the window is on */
static bool kmt_select(HWND hwnd)
{
    if (!kmt_open || !kmt_wait || !kmt_close) return false;
    HMONITOR m = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);
    if (kmt_ok && m == kmt_monitor) return true;
    if (kmt_ok) { KmtClose c = { kmt_vb.hAdapter }; kmt_close(&c); kmt_ok = false; }
    MONITORINFOEXW mi;
    mi.cbSize = sizeof mi;
    if (!GetMonitorInfoW(m, (MONITORINFO *)&mi)) return false;
    HDC dc = CreateDCW(NULL, mi.szDevice, NULL, NULL);
    if (!dc) return false;
    KmtOpenFromHdc o;
    memset(&o, 0, sizeof o);
    o.hDc = dc;
    LONG r = kmt_open(&o);
    DeleteDC(dc);
    if (r != 0) return false;
    kmt_vb.hAdapter = o.hAdapter;
    kmt_vb.hDevice = 0;
    kmt_vb.VidPnSourceId = o.VidPnSourceId;
    kmt_monitor = m;
    kmt_ok = true;
    return true;
}

/* DwmFlush: the time it returned, 0 if it cannot be used (no compositor, an error, or it does not
 * wait: it returned less than 2 ms after the previous time, 8 times in a row; tried again 5 s later) */
static int dwm_quick;
static double dwm_last, dwm_retry;
static double refresh_dwm(void)
{
    BOOL on = FALSE;
    double t0 = qpc_now();
    if (!dwm_flush || (dwm_quick >= 8 && t0 < dwm_retry)) return 0;
    if (dwm_enabled && (dwm_enabled(&on) != S_OK || !on)) return 0;
    if (dwm_flush() != S_OK) return 0;
    double t = qpc_now();
    if (t - dwm_last < 0.002) {
        if (++dwm_quick >= 8) { dwm_retry = t + 5.0; return 0; }
    } else {
        dwm_quick = 0;
    }
    dwm_last = t;
    return t;
}

/* the vertical blank of the window's monitor: its time, 0 if it cannot be used */
static double refresh_kmt(HWND hwnd)
{
    double t0 = qpc_now();
    if (!kmt_select(hwnd) || kmt_wait(&kmt_vb) != 0) return 0;
    double t = qpc_now();
    return t - t0 > 0.0002 ? t : 0;
}

/* a timer at the game's rate */
static double refresh_timer(void)
{
    static double next;
    double t0 = qpc_now();
    if (t0 - next > 0.1 || next - t0 > 0.1) next = t0;
    next += PACER_GAME_PERIOD;
    double left = next - qpc_now();
    if (left > 0.002) Sleep((DWORD)((left - 0.0015) * 1000));
    while (qpc_now() < next) {}
    return next;
}

/* waits for the next refresh; returns its time (seconds, as qpc_now) */
static double wait_refresh(HWND hwnd)
{
    double t = refresh_dwm();
    if (t <= 0) t = refresh_kmt(hwnd);
    if (t <= 0) t = refresh_timer();
    return t;
}

#endif
