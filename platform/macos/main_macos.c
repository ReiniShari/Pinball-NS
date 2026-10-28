/*
 * main_macos.c - macOS front-end of Pinball NS (Pokemon Pinball, the whole table on one screen), in C
 * only, as the Android version: AppKit through the Objective-C runtime (classes made at run time from
 * C functions, platform/apple/objc_c.h), the picture in a Core Animation layer (the nearest pixel, or
 * smooth), shown at the refreshes of the display (CVDisplayLink: the pace of the game, pacing.h), the
 * sound through the default output audio unit, the gamepads through the GameController framework (Xbox,
 * PlayStation, Switch Pro, MFi). What the desktop versions share (the game, its saves, the settings and
 * controls, the pictures, the function keys: as on Windows) is platform/desktop/desk.c; the pages of F1
 * (about) and F2 (the controls) are drawn in the window.
 *
 * The ROM: opened with the app (Finder, the Dock), dropped onto the window, the last one played, or
 * chosen in the dialog shown at the start (and with Open ROM in the menu). The settings are in
 * ~/Library/Application Support/Pinball NS; the cartridge save and the saved state next to the ROM, as
 * on Windows.
 */
#include "../apple/objc_c.h"
#include "../desktop/desk.h"
#include "../../src/front/pacing.h"
#include <AudioToolbox/AudioToolbox.h>
#include <CoreFoundation/CoreFoundation.h>
#include <CoreGraphics/CoreGraphics.h>
#include <CoreVideo/CoreVideo.h>
#include <mach/mach_time.h>
#include <pthread.h>
#include <stdatomic.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>

#define AUDIO_RATE   DESK_RATE
#define AUDIO_TARGET 2048
#define RING         32768                  /* the sound waiting for the audio unit (frames, a power of two) */

/* AppKit, Foundation, QuartzCore: their C symbols */
extern id NSDefaultRunLoopMode;
extern id NSPasteboardTypeFileURL;
extern id kCAFilterNearest, kCAFilterLinear;
extern id GCControllerDidConnectNotification;     /* (GameController: linked through it) */
extern void *objc_autoreleasePoolPush(void);
extern void objc_autoreleasePoolPop(void *pool);

/* BOOL: bool on arm64, signed char on x86-64 (the type encodings of the methods made here) */
#if defined(__aarch64__) || defined(__arm64__)
#define B_ "B"
#else
#define B_ "c"
#endif

enum { STYLE_WINDOW = 1 | 2 | 4 | 8, STYLE_FULLSCREEN = 1 << 14, BACKING_BUFFERED = 2, FULLSCREEN_PRIMARY = 1 << 7, MODAL_OK = 1,
       TERMINATE_NOW = 1, MOD_CTRL = 1 << 18, MOD_ALT = 1 << 19, MOD_CMD = 1 << 20 };
/* the modifiers of a key event, each side (NX_DEVICE*KEYMASK) */
enum { DEV_LCTL = 0x1, DEV_LSHIFT = 0x2, DEV_RSHIFT = 0x4, DEV_LCMD = 0x8, DEV_RCMD = 0x10, DEV_LALT = 0x20, DEV_RALT = 0x40,
       DEV_RCTL = 0x2000 };

static Desk D;
static bool running = true, launched, redraw;
static id app, win, view, pic, delegate;
static double scale = 1;                    /* pixels per point */
static CGColorSpaceRef rgb;
static double tick_s;                       /* seconds per unit of mach_absolute_time */

/* the clock of the display link's times */
static double now_s(void) { return (double)mach_absolute_time() * tick_s; }

static void sleep_s(double s)
{
    if (s <= 0) return;
    struct timespec ts = { (time_t)s, (long)((s - (double)(time_t)s) * 1e9) };
    nanosleep(&ts, NULL);
}

/* ------------------------------------------------------------------ sound */

static int16_t ring[RING * 2];
static _Atomic uint32_t ring_w, ring_r;
static _Atomic uint32_t pulled_lo;          /* frames taken by the audio unit (wraps; counted in 64 bits below) */
static _Atomic uint32_t ring_drop;          /* frames for the audio unit's thread to skip (only it moves ring_r) */
static uint64_t pulled;
static uint32_t pulled_last;
static AudioUnit unit;
static bool audio_ok, audio_running;
static SoundPacer snd;
static Pacer pacer;

static OSStatus render(void *ref, AudioUnitRenderActionFlags *flags, const AudioTimeStamp *ts, UInt32 bus, UInt32 n,
                       AudioBufferList *io)
{
    (void)ref; (void)flags; (void)ts; (void)bus;
    int16_t *out = (int16_t *)io->mBuffers[0].mData;
    uint32_t r = atomic_load_explicit(&ring_r, memory_order_relaxed), w = atomic_load_explicit(&ring_w, memory_order_acquire);
    uint32_t drop = atomic_exchange_explicit(&ring_drop, 0, memory_order_acq_rel);
    if (drop) r += drop < w - r ? drop : w - r;
    uint32_t avail = w - r, k = n < avail ? n : avail;
    for (uint32_t i = 0; i < k; i++) {
        uint32_t j = (r + i) & (RING - 1);
        out[i * 2] = ring[j * 2];
        out[i * 2 + 1] = ring[j * 2 + 1];
    }
    if (k < n) memset(out + k * 2, 0, (size_t)(n - k) * 4);
    atomic_store_explicit(&ring_r, r + k, memory_order_release);
    atomic_fetch_add_explicit(&pulled_lo, n, memory_order_relaxed);
    return 0;
}

static void audio_open(void)
{
    AudioComponentDescription d = { kAudioUnitType_Output, kAudioUnitSubType_DefaultOutput, kAudioUnitManufacturer_Apple, 0, 0 };
    AudioComponent c = AudioComponentFindNext(NULL, &d);
    if (!c || AudioComponentInstanceNew(c, &unit)) return;
    AudioStreamBasicDescription f = { AUDIO_RATE, kAudioFormatLinearPCM, kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked,
                                      4, 1, 4, 2, 16, 0 };
    AURenderCallbackStruct cb = { render, NULL };
    if (AudioUnitSetProperty(unit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &f, sizeof f) ||
        AudioUnitSetProperty(unit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &cb, sizeof cb) ||
        AudioUnitInitialize(unit)) {
        AudioComponentInstanceDispose(unit);
        return;
    }
    audio_ok = true;
    sound_reset(&snd, AUDIO_RATE, AUDIO_TARGET);
    snd.limit = RING;
    sound_restart(&snd, now_s());
}

static void audio_hold(bool hold)
{
    if (!audio_ok || hold == !audio_running) return;
    if (hold) AudioOutputUnitStop(unit); else AudioOutputUnitStart(unit);
    audio_running = !hold;
}

/* the emulator's new samples to the ring */
static void audio_pump(void)
{
    int16_t tmp[4096];
    int n;
    while ((n = pb_audio(D.pb, tmp, 2048)) > 0) {
        if (!audio_ok) continue;
        if (!D.sound) memset(tmp, 0, (size_t)n * 4);
        uint32_t w = atomic_load_explicit(&ring_w, memory_order_relaxed), r = atomic_load_explicit(&ring_r, memory_order_acquire);
        uint32_t room = RING - (w - r);
        if ((uint32_t)n > room) n = (int)room;      /* far ahead of the card: dropped */
        for (int i = 0; i < n; i++) {
            uint32_t j = (w + (uint32_t)i) & (RING - 1);
            ring[j * 2] = tmp[i * 2];
            ring[j * 2 + 1] = tmp[i * 2 + 1];
        }
        atomic_store_explicit(&ring_w, w + (uint32_t)n, memory_order_release);
    }
}

static int audio_pace(double t, int frames_left)
{
    if (!audio_ok) return SOUND_KEEP;
    uint32_t lo = atomic_load_explicit(&pulled_lo, memory_order_relaxed);
    pulled += (uint32_t)(lo - pulled_last);
    pulled_last = lo;
    uint32_t w = atomic_load_explicit(&ring_w, memory_order_relaxed), r = atomic_load_explicit(&ring_r, memory_order_acquire);
    double rate, pad;
    int act = sound_pace(&snd, &pacer, t, (double)pulled, (double)(w - r), frames_left, &rate, &pad);
    if (act == SOUND_PAD) {
        uint32_t add = pad > 0 ? (uint32_t)pad : 0;
        if (add > RING / 2) add = RING / 2;
        for (uint32_t i = 0; i < add; i++) { uint32_t j = (w + i) & (RING - 1); ring[j * 2] = ring[j * 2 + 1] = 0; }
        atomic_store_explicit(&ring_w, w + add, memory_order_release);
    } else if (act == SOUND_FLUSH) {
        atomic_store_explicit(&ring_drop, w - r, memory_order_release);
    } else if (act == SOUND_TRIM) {
        atomic_store_explicit(&ring_drop, pad > 0 ? (uint32_t)pad : 0, memory_order_release);
    }
    pb_set_audio_rate(D.pb, rate);
    return act;
}

/* ------------------------------------------------------------------ the display's refreshes */

/* CVDisplayLink calls vsync_cb at each refresh of the window's display (its own thread); the main loop
 * waits for it, as the Android version waits for Choreographer, and the pacer (pacing.h) makes 60 frames
 * a second from the refreshes (60, 120 Hz...). Without it (no display, asleep): a 60 Hz clock. */
static CVDisplayLinkRef link;
static pthread_mutex_t vs_lock;
static pthread_cond_t vs_cond;
static uint64_t vs_host, vs_count, vs_seen;

static CVReturn vsync_cb(CVDisplayLinkRef l, const CVTimeStamp *now, const CVTimeStamp *out, CVOptionFlags fi,
                         CVOptionFlags *fo, void *ctx)
{
    (void)l; (void)out; (void)fi; (void)fo; (void)ctx;
    pthread_mutex_lock(&vs_lock);
    vs_host = now->hostTime;
    vs_count++;
    pthread_cond_signal(&vs_cond);
    pthread_mutex_unlock(&vs_lock);
    return 0;
}

/* the display link follows the window's display */
static void link_display(void)
{
    if (!link || !win) return;
    id num = msg_id(msg(msg(win, "screen"), "deviceDescription"), "objectForKey:", nsstr("NSScreenNumber"));
    if (num) CVDisplayLinkSetCurrentCGDisplay(link, MSG0(unsigned int, num, "unsignedIntValue"));
}

static void link_open(void)
{
    pthread_mutex_init(&vs_lock, NULL);
    pthread_cond_init(&vs_cond, NULL);
    if (CVDisplayLinkCreateWithActiveCGDisplays(&link)) { link = NULL; return; }
    CVDisplayLinkSetOutputCallback(link, vsync_cb, NULL);
    link_display();
    if (CVDisplayLinkStart(link)) { CVDisplayLinkRelease(link); link = NULL; }
}

/* the time of the next refresh (seconds, the clock of now_s), 0 after 50 ms without one */
static double vsync_wait(void)
{
    if (!link) return 0;
    double t = 0, until = now_s() + 0.05;
    pthread_mutex_lock(&vs_lock);
    for (;;) {
        if (vs_count != vs_seen) { vs_seen = vs_count; t = (double)vs_host * tick_s; break; }
        double left = until - now_s();
        if (left <= 0) break;
        struct timespec rel = { 0, (long)(left * 1e9) };
        pthread_cond_timedwait_relative_np(&vs_cond, &vs_lock, &rel);
    }
    pthread_mutex_unlock(&vs_lock);
    return t;
}

/* the display kept on during a game (played with a gamepad, nothing else tells macOS someone is there),
 * without App Nap or timer coalescing */
static void keep_awake(bool on)
{
    static id activity;
    if (on == (activity != nil)) return;
    id info = msg(CLASS("NSProcessInfo"), "processInfo");
    if (on) {
        /* NSActivityUserInitiated | NSActivityIdleDisplaySleepDisabled | NSActivityLatencyCritical */
        activity = MSG(id, (uint64_t, id), info, "beginActivityWithOptions:reason:",
                       (uint64_t)0x00FFFFFFull | (1ull << 20) | (1ull << 40) | 0xFF00000000ull, nsstr("A game of Pinball NS"));
        retain(activity);
    } else {
        msg_set(info, "endActivity:", activity);
        release(activity);
        activity = nil;
    }
}

/* ------------------------------------------------------------------ keys */

/* the key codes of macOS (kVK_*, places on the keyboard) as the virtual keys of Windows (desk.h) */
static unsigned mac_key(unsigned short kc)
{
    static const uint8_t letters[0x33] = {
        'A', 'S', 'D', 'F', 'H', 'G', 'Z', 'X', 'C', 'V', 0, 'B', 'Q', 'W', 'E', 'R', 'Y', 'T', '1', '2', '3', '4', '6', '5',
        DK_EQUALS, '9', '7', DK_MINUS, '8', '0', DK_RBRACKET, 'O', 'U', DK_LBRACKET, 'I', 'P', DK_RETURN, 'L', 'J', DK_QUOTE,
        'K', DK_SEMICOLON, DK_BACKSLASH, DK_COMMA, DK_SLASH, 'N', 'M', DK_PERIOD, DK_TAB, DK_SPACE, DK_GRAVE };
    if (kc < 0x33) return letters[kc];
    switch (kc) {
    case 0x33: return DK_BACK;
    case 0x35: return DK_ESCAPE;
    case 0x41: return DK_DECIMAL;
    case 0x43: return DK_MULTIPLY;
    case 0x45: return DK_ADD;
    case 0x4B: return DK_DIVIDE;
    case 0x4C: return DK_RETURN;
    case 0x4E: return DK_SUBTRACT;
    case 0x52: case 0x53: case 0x54: case 0x55: case 0x56: case 0x57: case 0x58: case 0x59: return DK_NUM0 + (kc - 0x52);
    case 0x5B: return DK_NUM0 + 8;
    case 0x5C: return DK_NUM0 + 9;
    case 0x7A: return DK_F(1);
    case 0x78: return DK_F(2);
    case 0x63: return DK_F(3);
    case 0x76: return DK_F(4);
    case 0x60: return DK_F(5);
    case 0x61: return DK_F(6);
    case 0x62: return DK_F(7);
    case 0x64: return DK_F(8);
    case 0x65: return DK_F(9);
    case 0x6D: return DK_F(10);
    case 0x67: return DK_F(11);
    case 0x6F: return DK_F(12);
    case 0x72: return DK_INSERT;
    case 0x73: return DK_HOME;
    case 0x74: return DK_PGUP;
    case 0x75: return DK_DELETE;
    case 0x77: return DK_END;
    case 0x79: return DK_PGDN;
    case 0x7B: return DK_LEFT;
    case 0x7C: return DK_RIGHT;
    case 0x7D: return DK_DOWN;
    case 0x7E: return DK_UP;
    default: return 0;
    }
}

static void set_title(void)
{
    msg_set(win, "setTitle:", nsstr(D.pb && D.pb->rom->id == PB_ROM_GENERATIONS ? "Pinball NS - Generations" : "Pinball NS"));
}

static void reshape(void);

static void do_action(int a)
{
    switch (a) {
    case DESK_FULLSCREEN: case DESK_LEAVE_FULLSCREEN:
        if (a == DESK_FULLSCREEN || (msg_u(win, "styleMask") & STYLE_FULLSCREEN)) msg_set(win, "toggleFullScreen:", nil);
        break;
    case DESK_RESHAPE: reshape(); redraw = true; break;
    case DESK_PAUSE: audio_hold(D.paused); redraw = true; break;
    case DESK_QUIT: running = false; break;
    case DESK_REDRAW: redraw = true; break;
    default: break;
    }
}

/* ------------------------------------------------------------------ the ROM */

static bool try_rom(const char *path, bool report)
{
    char err[1024];
    if (!desk_open_rom(&D, path, err, sizeof err)) {
        if (report) desk_osd(&D, "Not the expected ROM (US Pokémon Pinball, or Generations 1.6)");
        return false;
    }
    if (win) set_title();
    redraw = true;
    return true;
}

static bool ask_rom(void)
{
    id panel = msg(CLASS("NSOpenPanel"), "openPanel");
    msg_set(panel, "setTitle:", nsstr("The ROM of your Pokémon Pinball cartridge (US), or of Pokémon Pinball Generations"));
    msg_set(panel, "setMessage:", nsstr("Pinball NS needs the ROM of your own cartridge (.gbc): it is not included."));
    for (;;) {
        if (MSG0(NSInteger, panel, "runModal") != MODAL_OK) return false;
        id url = msg(panel, "URL");
        if (url && try_rom(cstr(msg(url, "path")), true)) return true;
    }
}

/* ------------------------------------------------------------------ the view: keys, mouse, drops */

static uint8_t key_vk[128];                 /* the virtual key given at each key's press, for its release */

static BOOL v_yes(id self, SEL s) { (void)self; (void)s; return YES; }
static BOOL v_yes1(id self, SEL s, id a) { (void)self; (void)s; (void)a; return YES; }

/* the letters as the keyboard's layout names them (A of an AZERTY keyboard: its A, as on Windows), the
 * other keys by their place */
static void v_key(id self, SEL s, id ev, bool down)
{
    (void)self; (void)s;
    unsigned short kc = MSG0(unsigned short, ev, "keyCode");
    unsigned vk = mac_key(kc);
    if (down) {
        const char *c = cstr(msg(ev, "charactersIgnoringModifiers"));
        if (c[0] && !c[1] && ((c[0] >= 'a' && c[0] <= 'z') || (c[0] >= 'A' && c[0] <= 'Z'))) vk = (unsigned)(c[0] & ~0x20);
        if (kc < 128) key_vk[kc] = (uint8_t)vk;
    } else if (kc < 128 && key_vk[kc]) {
        vk = key_vk[kc];
        key_vk[kc] = 0;
    }
    if (vk) do_action(desk_key(&D, vk, down, down && MSG0(BOOL, ev, "isARepeat")));
}
static void v_keydown(id self, SEL s, id ev) { v_key(self, s, ev, true); }
static void v_keyup(id self, SEL s, id ev) { v_key(self, s, ev, false); }

/* Shift, Ctrl, Option (Alt), Command: their own event, each side by its bit */
static void v_flags(id self, SEL s, id ev)
{
    (void)self; (void)s;
    NSUInteger f = MSG0(NSUInteger, ev, "modifierFlags");
    static const struct { NSUInteger bit; unsigned vk; } mods[] = {
        { DEV_LSHIFT, DK_LSHIFT }, { DEV_RSHIFT, DK_RSHIFT }, { DEV_LCTL, DK_LCONTROL }, { DEV_RCTL, DK_RCONTROL },
        { DEV_LALT, DK_LALT }, { DEV_RALT, DK_RALT }, { DEV_LCMD, DK_LWIN }, { DEV_RCMD, DK_RWIN } };
    for (size_t i = 0; i < sizeof mods / sizeof mods[0]; i++) {
        bool down = (f & mods[i].bit) != 0;
        if (down != (D.key_down[mods[i].vk] != 0)) do_action(desk_key(&D, mods[i].vk, down, false));
    }
}

/* the mouse, in pixels from the top left of the view */
static void v_mouse(id ev, int action)
{
    CGPoint p = MSG_STRUCT0(CGPoint, ev, "locationInWindow");
    p = MSG_STRUCT(CGPoint, (CGPoint, id), view, "convertPoint:fromView:", p, nil);
    CGRect b = MSG_STRUCT0(CGRect, view, "bounds");
    desk_pointer(&D, action, 0, (float)(p.x * scale), (float)((b.size.height - p.y) * scale));
    redraw = true;
}
static void v_down(id self, SEL s, id ev) { (void)self; (void)s; v_mouse(ev, UI_DOWN); }
static void v_drag(id self, SEL s, id ev) { (void)self; (void)s; v_mouse(ev, UI_MOVE); }
static void v_up(id self, SEL s, id ev) { (void)self; (void)s; v_mouse(ev, UI_UP); }

static NSUInteger v_drag_enter(id self, SEL s, id info) { (void)self; (void)s; (void)info; return 1; }   /* copy */
static BOOL v_drop(id self, SEL s, id info)
{
    (void)self; (void)s;
    id pb = msg(info, "draggingPasteboard");
    id classes = msg_id(CLASS("NSArray"), "arrayWithObject:", CLASS("NSURL"));
    id urls = MSG(id, (id, id), pb, "readObjectsForClasses:options:", classes, nil);
    if (!ns_count(urls)) return NO;
    return try_rom(cstr(msg(ns_at(urls, 0), "path")), true) ? YES : NO;
}

/* ------------------------------------------------------------------ the application's delegate */

static void finish(void);

/* Quit (the menu, Command-Q, the end of the session): the saves written, then AppKit ends the process */
static NSUInteger d_should_terminate(id self, SEL s, id sender) { (void)self; (void)s; (void)sender; finish(); return TERMINATE_NOW; }
static BOOL d_open_file(id self, SEL s, id sender, id file) { (void)self; (void)s; (void)sender; return try_rom(cstr(file), true) ? YES : NO; }
static void d_did_launch(id self, SEL s, id note) { (void)self; (void)s; (void)note; launched = true; }
static void d_will_close(id self, SEL s, id note) { (void)self; (void)s; (void)note; running = false; }
static void d_resign_key(id self, SEL s, id note)
{
    (void)self; (void)s; (void)note;
    memset(key_vk, 0, sizeof key_vk);
    desk_keys_released(&D);
}
static void d_screen(id self, SEL s, id note) { (void)self; (void)s; (void)note; link_display(); redraw = true; }
/* the menu's items as their keys (a page shown first closed by Esc) */
static void press(unsigned vk) { do_action(desk_key(&D, vk, true, false)); desk_key(&D, vk, false, false); }
static void page(int want)
{
    for (int i = 0; i < 3 && D.page && D.page != want; i++) press(DK_ESCAPE);
    if (D.page != want) press(want == PAGE_ABOUT ? DK_F(1) : DK_F(2));
}
static void d_about(id self, SEL s, id sender) { (void)self; (void)s; (void)sender; page(PAGE_ABOUT); }
static void d_controls(id self, SEL s, id sender) { (void)self; (void)s; (void)sender; page(PAGE_CONTROLS); }
static void d_handheld(id self, SEL s, id sender) { (void)self; (void)s; (void)sender; press(DK_F(3)); }
static void d_open(id self, SEL s, id sender) { (void)self; (void)s; (void)sender; ask_rom(); }

/* an item of the menu: its action sent to the delegate (to the first responder: AppKit's own actions) */
static id menu_item(const char *title, const char *action, const char *key, NSUInteger mods, bool own)
{
    id it = MSG(id, (id, SEL, id), msg(CLASS("NSMenuItem"), "alloc"), "initWithTitle:action:keyEquivalent:", nsstr(title),
                SEL_(action), nsstr(key));
    if (mods) msg_setu(it, "setKeyEquivalentModifierMask:", mods);
    if (own) msg_set(it, "setTarget:", delegate);
    return it;
}

static void make_menu(void)
{
    id bar = new_of("NSMenu"), app_item = new_of("NSMenuItem"), m = new_of("NSMenu");
    msg_set(bar, "addItem:", app_item);
    msg_set(m, "addItem:", menu_item("About Pinball NS", "pnsAbout:", "", 0, true));
    msg_set(m, "addItem:", msg(CLASS("NSMenuItem"), "separatorItem"));
    msg_set(m, "addItem:", menu_item("Open ROM…", "pnsOpen:", "o", 0, true));
    msg_set(m, "addItem:", menu_item("Controls…", "pnsControls:", ",", 0, true));
    msg_set(m, "addItem:", menu_item("Handheld Mode", "pnsHandheld:", "", 0, true));
    msg_set(m, "addItem:", menu_item("Enter Full Screen", "toggleFullScreen:", "f", MOD_CTRL | MOD_CMD, false));
    msg_set(m, "addItem:", msg(CLASS("NSMenuItem"), "separatorItem"));
    msg_set(m, "addItem:", menu_item("Hide Pinball NS", "hide:", "h", 0, false));
    msg_set(m, "addItem:", menu_item("Hide Others", "hideOtherApplications:", "h", MOD_ALT | MOD_CMD, false));
    msg_set(m, "addItem:", menu_item("Show All", "unhideAllApplications:", "", 0, false));
    msg_set(m, "addItem:", msg(CLASS("NSMenuItem"), "separatorItem"));
    msg_set(m, "addItem:", menu_item("Quit Pinball NS", "terminate:", "q", 0, false));
    msg_set(app_item, "setSubmenu:", m);
    msg_set(app, "setMainMenu:", bar);
}

static void make_classes(void)
{
    Class v = make_class("PNSView", "NSView");
    add_method(v, "acceptsFirstResponder", (void *)v_yes, B_ "@:");
    add_method(v, "acceptsFirstMouse:", (void *)v_yes1, B_ "@:@");
    add_method(v, "keyDown:", (void *)v_keydown, "v@:@");
    add_method(v, "keyUp:", (void *)v_keyup, "v@:@");
    add_method(v, "flagsChanged:", (void *)v_flags, "v@:@");
    add_method(v, "mouseDown:", (void *)v_down, "v@:@");
    add_method(v, "mouseDragged:", (void *)v_drag, "v@:@");
    add_method(v, "mouseUp:", (void *)v_up, "v@:@");
    add_method(v, "draggingEntered:", (void *)v_drag_enter, "Q@:@");
    add_method(v, "performDragOperation:", (void *)v_drop, B_ "@:@");
    objc_registerClassPair(v);
    Class d = make_class("PNSDelegate", "NSObject");
    add_method(d, "applicationShouldTerminate:", (void *)d_should_terminate, "Q@:@");
    add_method(d, "application:openFile:", (void *)d_open_file, B_ "@:@@");
    add_method(d, "applicationDidFinishLaunching:", (void *)d_did_launch, "v@:@");
    add_method(d, "windowWillClose:", (void *)d_will_close, "v@:@");
    add_method(d, "windowDidResignKey:", (void *)d_resign_key, "v@:@");
    add_method(d, "windowDidChangeScreen:", (void *)d_screen, "v@:@");
    add_method(d, "pnsAbout:", (void *)d_about, "v@:@");
    add_method(d, "pnsOpen:", (void *)d_open, "v@:@");
    add_method(d, "pnsControls:", (void *)d_controls, "v@:@");
    add_method(d, "pnsHandheld:", (void *)d_handheld, "v@:@");
    objc_registerClassPair(d);
}

/* ------------------------------------------------------------------ the window and its picture */

static void make_window(void)
{
    id screen = msg(CLASS("NSScreen"), "mainScreen");
    CGRect vf = MSG_STRUCT0(CGRect, screen, "visibleFrame");
    int w, h;
    desk_window_size(&D, (int)vf.size.width, (int)vf.size.height, &w, &h);
    CGRect r = { { 0, 0 }, { w, h } };
    win = MSG(id, (CGRect, NSUInteger, NSUInteger, BOOL), msg(CLASS("NSWindow"), "alloc"),
              "initWithContentRect:styleMask:backing:defer:", r, (NSUInteger)STYLE_WINDOW, (NSUInteger)BACKING_BUFFERED, NO);
    view = MSG(id, (CGRect), msg(CLASS("PNSView"), "alloc"), "initWithFrame:", r);
    msg_setb(view, "setWantsLayer:", true);
    id layer = msg(view, "layer");
    CGColorRef black = CGColorCreateGenericRGB(0, 0, 0, 1);
    MSG1(void, CGColorRef, layer, "setBackgroundColor:", black);
    pic = msg(CLASS("CALayer"), "layer");
    msg_set(layer, "addSublayer:", pic);
    msg_set(view, "registerForDraggedTypes:", msg_id(CLASS("NSArray"), "arrayWithObject:", NSPasteboardTypeFileURL));
    msg_set(win, "setContentView:", view);
    msg_set(win, "setDelegate:", delegate);
    msg_setu(win, "setCollectionBehavior:", FULLSCREEN_PRIMARY);
    CGSize min = { PB_FIELD_W_NARROW, 144 };
    MSG1(void, CGSize, win, "setContentMinSize:", min);
    msg_void(win, "center");
    msg_set(win, "makeKeyAndOrderFront:", nil);
    msg_set(win, "makeFirstResponder:", view);
    scale = msg_d(win, "backingScaleFactor");
    rgb = CGColorSpaceCreateDeviceRGB();
    set_title();
}

/* the shape of the window for the display (the table: its zoom kept; the handheld mode: a phone's) */
static void reshape(void)
{
    if (msg_u(win, "styleMask") & STYLE_FULLSCREEN) return;
    CGRect b = MSG_STRUCT0(CGRect, view, "bounds");
    id screen = msg(CLASS("NSScreen"), "mainScreen");
    CGRect vf = MSG_STRUCT0(CGRect, screen, "visibleFrame");
    int w, h;
    if (D.handheld) desk_window_size(&D, (int)vf.size.width, (int)vf.size.height, &w, &h);
    else {
        int zoom = (int)((b.size.height + PB_FIELD_H / 2) / PB_FIELD_H);
        if (zoom < 1) zoom = 1;
        w = (D.narrow ? PB_FIELD_W_NARROW : PB_FIELD_W) * zoom;
        h = PB_FIELD_H * zoom;
    }
    CGSize sz = { w, h };
    MSG1(void, CGSize, win, "setContentSize:", sz);
}

/* the picture to the layer (Core Animation shows it at the next refresh); force: even if the window's size
 * has not changed */
static void present(bool force)
{
    static int last_w, last_h;
    if (!view) return;
    scale = msg_d(win, "backingScaleFactor");
    CGRect b = MSG_STRUCT0(CGRect, view, "bounds");
    int W = (int)(b.size.width * scale + 0.5), H = (int)(b.size.height * scale + 0.5);
    if (W <= 0 || H <= 0 || (!force && W == last_w && H == last_h)) return;
    last_w = W;
    last_h = H;
    DeskPicture p;
    desk_picture(&D, W, H, &p);
    if (!p.px) return;
    CFDataRef data = CFDataCreate(NULL, (const UInt8 *)p.px, (CFIndex)p.stride * p.h * 4);
    CGDataProviderRef prov = CGDataProviderCreateWithCFData(data);
    CGImageRef img = CGImageCreate((size_t)p.w, (size_t)p.h, 8, 32, (size_t)p.stride * 4, rgb,
                                   kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little, prov, NULL, false, kCGRenderingIntentDefault);
    id tx = CLASS("CATransaction");
    msg_void(tx, "begin");
    msg_setb(tx, "setDisableActions:", true);
    msg_set(pic, "setContents:", (id)(void *)img);
    msg_set(pic, "setMagnificationFilter:", p.smooth ? kCAFilterLinear : kCAFilterNearest);
    msg_set(pic, "setMinificationFilter:", kCAFilterLinear);
    /* (the layer's origin is its bottom left) */
    CGRect f = { { p.x / scale, (H - p.y - p.dh) / scale }, { p.dw / scale, p.dh / scale } };
    MSG1(void, CGRect, pic, "setFrame:", f);
    msg_void(tx, "commit");
    msg_void(tx, "flush");                  /* (sent now, even inside a transaction AppKit opened) */
    CGImageRelease(img);
    CGDataProviderRelease(prov);
    CFRelease(data);
}

/* ------------------------------------------------------------------ gamepads (GameController) */

static bool pressed(id gp, const char *name)
{
    if (!responds(gp, name)) return false;
    id b = msg(gp, name);
    return b && MSG0(BOOL, b, "isPressed");
}

/* every gamepad's inputs together, in the layout of an Xbox gamepad (desk.h), -1 when there is none */
static long pads_poll(void)
{
    if (!GCControllerDidConnectNotification) return -1;
    id list = msg(CLASS("GCController"), "controllers");
    NSUInteger n = ns_count(list);
    long in = n ? 0 : -1;
    for (NSUInteger i = 0; i < n; i++) {
        id gp = msg(ns_at(list, i), "extendedGamepad");
        if (!gp) continue;
        static const struct { const char *name; int pad; } buttons[] = {
            { "buttonA", PAD_A }, { "buttonB", PAD_B }, { "buttonX", PAD_X }, { "buttonY", PAD_Y },
            { "leftShoulder", PAD_LB }, { "rightShoulder", PAD_RB }, { "leftTrigger", PAD_LT }, { "rightTrigger", PAD_RT },
            { "buttonMenu", PAD_START }, { "buttonOptions", PAD_BACK }, { "buttonHome", PAD_GUIDE },
            { "leftThumbstickButton", PAD_LTHUMB }, { "rightThumbstickButton", PAD_RTHUMB } };
        for (size_t k = 0; k < sizeof buttons / sizeof buttons[0]; k++)
            if (pressed(gp, buttons[k].name)) in |= 1L << buttons[k].pad;
        id dpad = msg(gp, "dpad");
        if (dpad) {
            if (pressed(dpad, "up")) in |= 1L << PAD_DUP;
            if (pressed(dpad, "down")) in |= 1L << PAD_DDOWN;
            if (pressed(dpad, "left")) in |= 1L << PAD_DLEFT;
            if (pressed(dpad, "right")) in |= 1L << PAD_DRIGHT;
        }
        id stick = msg(gp, "leftThumbstick");
        if (stick) {
            float x = MSG0(float, msg(stick, "xAxis"), "value"), y = MSG0(float, msg(stick, "yAxis"), "value");
            if (x < -0.5f) in |= 1L << PAD_LS_LEFT;
            if (x > 0.5f) in |= 1L << PAD_LS_RIGHT;
            if (y > 0.5f) in |= 1L << PAD_LS_UP;
            if (y < -0.5f) in |= 1L << PAD_LS_DOWN;
        }
    }
    return in;
}

/* ------------------------------------------------------------------ main */

/* the events waiting (wait: seconds to wait for the first one) */
static void events(double wait)
{
    id until = wait > 0 ? MSG1(id, double, CLASS("NSDate"), "dateWithTimeIntervalSinceNow:", wait)
                        : msg(CLASS("NSDate"), "distantPast");
    for (;;) {
        id ev = MSG(id, (NSUInteger, id, id, BOOL), app, "nextEventMatchingMask:untilDate:inMode:dequeue:", (NSUInteger)-1,
                    until, NSDefaultRunLoopMode, YES);
        if (!ev) break;
        msg_set(app, "sendEvent:", ev);
        until = msg(CLASS("NSDate"), "distantPast");
    }
    msg_void(app, "updateWindows");
}

/* the end: the sound stopped, the saves written (once: Quit, or the window closed) */
static void finish(void)
{
    static bool done;
    if (done) return;
    done = true;
    if (link) CVDisplayLinkStop(link);
    keep_awake(false);
    audio_hold(true);
    desk_sram_flush(&D, false, false);
    desk_free(&D);
}

int main(int argc, char **argv)
{
    mach_timebase_info_data_t tb;
    mach_timebase_info(&tb);
    tick_s = (double)tb.numer / (double)tb.denom * 1e-9;
    void *pool = objc_autoreleasePoolPush();
    /* the settings: ~/Library/Application Support/Pinball NS */
    const char *home = getenv("HOME");
    char dir[DESK_PATH], cfg[DESK_PATH + 32];
    snprintf(dir, sizeof dir, "%s/Library/Application Support/Pinball NS", home ? home : ".");
    mkdir(dir, 0755);
    snprintf(cfg, sizeof cfg, "%s/pinball_ns.cfg", dir);
    desk_init(&D, cfg);

    app = msg(CLASS("NSApplication"), "sharedApplication");
    MSG1(BOOL, NSInteger, app, "setActivationPolicy:", 0);            /* a regular app: Dock, menu bar */
    make_classes();
    delegate = new_of("PNSDelegate");
    msg_set(app, "setDelegate:", delegate);
    make_menu();
    msg_void(app, "finishLaunching");
    /* a ROM opened with the app comes before the end of the launch (application:openFile:) */
    for (double end = now_s() + 2.0; !launched && now_s() < end;) events(0.05);
    make_window();
    MSG1(void, BOOL, app, "activateIgnoringOtherApps:", YES);
    events(0);

    bool have = D.pb != NULL;
    for (int i = 1; i < argc && !have; i++) if (argv[i][0] != '-') have = try_rom(argv[i], true);
    if (!have && D.rom_paths[0][0]) have = try_rom(D.rom_paths[0], false);
    if (!have && D.rom_paths[1][0]) have = try_rom(D.rom_paths[1], false);
    if (!have) have = ask_rom();

    audio_open();
    pacer_reset(&pacer);
    link_open();
    bool was_active = false;
    double next = now_s();
    const double tick = 1.0 / 60.0;
    objc_autoreleasePoolPop(pool);

    while (running && !D.quit) {
        void *frame_pool = objc_autoreleasePoolPush();
        /* the pace: the display's refreshes (the picture shown at the next one), else a 60 Hz clock */
        double vsync = vsync_wait(), t = now_s();
        if (!vsync) {
            if (next > t) { sleep_s(next - t); t = now_s(); }
            next += tick;
            if (next < t - 0.1) next = t + tick;            /* far behind (the Mac was busy): from now */
            vsync = t;
        } else next = t;
        events(0);
        desk_pad(&D, pads_poll());
        bool active = D.pb && !D.paused && !D.page && !msg_b(win, "isMiniaturized");
        keep_awake(active);
        int n = 0;
        if (active) {
            if (!was_active) {
                pacer_restart(&pacer);
                audio_hold(false);
                if (audio_ok) sound_restart(&snd, t);
            }
            n = pacer_frames(&pacer, vsync, 6);
            bool extra = false;
            for (int k = 0; k < n; k++) {
                if (audio_pace(t, n - k) == SOUND_EXTRA && !extra) { extra = true; n++; }
                desk_frame(&D);
                audio_pump();
            }
        } else if (was_active) audio_hold(true);
        bool changed = desk_tick(&D, t);
        present(n > 0 || changed || redraw || D.page);
        redraw = false;
        was_active = active;
        objc_autoreleasePoolPop(frame_pool);
    }
    finish();
    return 0;
}
