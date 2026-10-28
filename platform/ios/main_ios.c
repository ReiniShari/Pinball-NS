/*
 * main_ios.c - iPhone front-end of Pinball NS, in C only.
 *
 * Like the Android version (a NativeActivity without Java), there is no Objective-C or Swift
 * here: the app delegate, the scene delegate, the view controller and the view are classes
 * made at run time from C functions (platform/apple/objc_c.h). Everything else is the Android
 * version's: the game, the screen, the menu and its settings (platform/mobile), the pace of the
 * game set by the refreshes of the screen and the sound made at the rate that keeps the card fed
 * (src/front/pacing.h, the same constants), MOTION TILT (platform/mobile/motion.h, the
 * accelerometer at up to 200 Hz through CoreMotion), the keys of gamepads and keyboards, the
 * files written by their own thread. The game runs on the main thread, from a CADisplayLink; the
 * screen is drawn with Metal (metal_render.c, the shaders of the Android version), the sound
 * plays through a RemoteIO audio unit, the vibrations are the Taptic Engine's
 * (UIImpactFeedbackGenerator).
 *
 * The ROMs come from the Files app: chosen in the document picker (tap the screen shown before a
 * ROM is installed), shared / opened in Pinball NS, or copied into the app's own folder (Files >
 * On My iPhone > Pinball NS: any ROM or IPS patch of a game not installed yet is imported when
 * the app becomes active). Problems are written to "Pinball NS log.txt" in that folder.
 */
#include "../apple/objc_c.h"
#include "metal_render.h"
#include "../mobile/app.h"
#include "../mobile/motion.h"
#include "../../src/front/pacing.h"
#include <AudioToolbox/AudioToolbox.h>
#include <pthread.h>
#include <stdarg.h>
#include <stdatomic.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <sys/stat.h>

#ifndef PNS_VERSION
#define PNS_VERSION "2.9"
#endif

#define AUDIO_RATE     48000
#define AUDIO_TARGET   2048            /* stereo frames kept ahead of the sound card (as on Android) */
#define ROM_MAX        (8u << 20)
#define LOG_MAX        32768
#define ACC_RING       256             /* accelerometer samples waiting for the game (a power of two) */

/* UIKit values */
enum {
    MASK_PORTRAIT = 2, EDGE_ALL = 15, PICKER_IMPORT = 0,
    IMPACT_LIGHT = 0, IMPACT_MEDIUM = 1, IMPACT_HEAVY = 2, PIXEL_BGRA8 = 80, GESTURE_DISABLED = 2
};

/* CoreMotion: its C symbol (linked through it); its accelerations (PnsAcceleration) are in g, as gravity
 * pulls: -1 on z when the phone lies on its back (Android's m/s² are the other way) */
extern id CMErrorDomain;
extern void *objc_autoreleasePoolPush(void);
extern void objc_autoreleasePoolPop(void *pool);

static MobileApp g_app;
static bool g_app_ready;
static MtlRenderer g_mr;
static UiList g_list;
static id g_window, g_vc, g_view, g_layer, g_link;
static id g_haptic[4];                     /* generator of each UI_HAPTIC_* */
static double g_scale = 1;                 /* screen pixels per point */
static int g_w, g_h;
static double g_last_vibration, g_last_touch;
static uint8_t g_pad_buttons, g_key_buttons, g_tilt_buttons;
static double g_tilt_until;
static bool g_keys[256];                   /* keyboard keys held (HID usages) */
static bool g_home_held;
static char g_dir[600], g_docs[600], g_log[700];
static id g_touch[UI_MAX_POINTERS];        /* the UITouch followed by each pointer id */
static Pacer g_pacer;

/* ------------------------------------------------------------------ log file (in Files) */

static void plog(const char *fmt, ...)
{
    if (!g_log[0]) return;
    FILE *f = fopen(g_log, "a");
    if (!f) return;
    va_list ap;
    va_start(ap, fmt);
    vfprintf(f, fmt, ap);
    va_end(ap);
    fputc('\n', f);
    fclose(f);
}

static void log_open(void)
{
    snprintf(g_log, sizeof g_log, "%s/Pinball NS log.txt", g_docs);
    FILE *f = fopen(g_log, "rb");
    long n = 0;
    if (f) { fseek(f, 0, SEEK_END); n = ftell(f); fclose(f); }
    if (n > LOG_MAX) remove(g_log);
    plog("Pinball NS %s (iOS) started", PNS_VERSION);
}

/* ------------------------------------------------------------------ files */

static void mkdirs(const char *path)
{
    char p[600];
    snprintf(p, sizeof p, "%s", path);
    for (char *s = p + 1; *s; s++)
        if (*s == '/') { *s = 0; mkdir(p, 0755); *s = '/'; }
    mkdir(p, 0755);
}

static uint8_t *read_file(const char *path, size_t *n)
{
    FILE *f = fopen(path, "rb");
    if (!f) return NULL;
    uint8_t *buf = (uint8_t *)malloc(ROM_MAX + 1);
    *n = buf ? fread(buf, 1, ROM_MAX + 1, f) : 0;
    fclose(f);
    if (!buf || *n == 0 || *n > ROM_MAX) { free(buf); return NULL; }
    return buf;
}

/* a ROM or a patch: quiet, a file of the app's folder (no message if it is refused); only_new: skipped
 * when its game is installed already */
static bool import_file(const char *path, bool quiet, bool only_new)
{
    size_t n = 0;
    uint8_t *buf = read_file(path, &n);
    if (!buf) {
        plog("cannot read %s", path);
        if (!quiet) ui_toast(&g_app.ui, "Could not read this file", 4);
        return false;
    }
    bool ok = false;
    if (!only_new || !app_has_rom(&g_app, buf, n)) {
        ok = app_import_rom(&g_app, buf, n);
        plog("import %s: %zu bytes, %s", path, n, ok ? "ok" : "refused");
    }
    free(buf);
    return ok;
}

/* a file given by iOS (document picker, "Open in", share): it may be outside the app */
static void import_url(id url)
{
    if (!url) return;
    bool scoped = msg_b(url, "startAccessingSecurityScopedResource");
    import_file(cstr(msg(url, "path")), false, false);
    if (scoped) msg_void(url, "stopAccessingSecurityScopedResource");
}

static void import_contexts(id set)            /* NSSet of UIOpenURLContext */
{
    id all = set ? msg(set, "allObjects") : nil;
    for (NSUInteger i = 0; i < ns_count(all); i++) import_url(msg(ns_at(all, i), "URL"));
}

static bool ends_with(const char *s, const char *ext)
{
    size_t n = strlen(s), k = strlen(ext);
    return n > k && !strcasecmp(s + n - k, ext);
}

/* the ROMs and patches copied into the app's folder of Files: those of a game not installed yet (as the
 * Android version does with its own folder) */
static void import_from_documents(void)
{
    id fm = msg(CLASS("NSFileManager"), "defaultManager");
    id names = MSG(id, (id, id *), fm, "contentsOfDirectoryAtPath:error:", nsstr(g_docs), NULL);
    for (NSUInteger i = 0; i < ns_count(names); i++) {
        const char *name = cstr(ns_at(names, i));
        if (!ends_with(name, ".gbc") && !ends_with(name, ".gb") && !ends_with(name, ".ips")) continue;
        char path[1200];
        snprintf(path, sizeof path, "%s/%s", g_docs, name);
        import_file(path, true, true);
    }
}

static void present_picker(void)
{
    if (!g_vc || msg(g_vc, "presentedViewController")) return;      /* already shown */
    id cls = CLASS("UIDocumentPickerViewController");
    id ut = CLASS("UTType");
    id picker = nil;
    if (ut && MSG1(BOOL, SEL, cls, "instancesRespondToSelector:", SEL_("initForOpeningContentTypes:asCopy:"))) {
        /* iOS 14: a copy of the file, readable without asking */
        id data = MSG1(id, id, ut, "typeWithIdentifier:", nsstr("public.data"));
        id types = MSG1(id, id, CLASS("NSArray"), "arrayWithObject:", data);
        picker = MSG(id, (id, BOOL), msg(cls, "alloc"), "initForOpeningContentTypes:asCopy:", types, (BOOL)YES);
    } else {
        id types = MSG1(id, id, CLASS("NSArray"), "arrayWithObject:", nsstr("public.data"));
        picker = MSG(id, (id, NSUInteger), msg(cls, "alloc"), "initWithDocumentTypes:inMode:", types, (NSUInteger)PICKER_IMPORT);
    }
    if (!picker) return;
    msg_set(picker, "setDelegate:", g_vc);
    msg_setb(picker, "setAllowsMultipleSelection:", false);
    MSG(void, (id, BOOL, id), g_vc, "presentViewController:animated:completion:", picker, (BOOL)YES, nil);
    release(picker);
}

static void picker_picked(id self, SEL cmd, id picker, id urls)
{
    (void)self; (void)cmd; (void)picker;
    for (NSUInteger i = 0; i < ns_count(urls); i++) import_url(ns_at(urls, i));
}

static void picker_cancelled(id self, SEL cmd, id picker) { (void)self; (void)cmd; (void)picker; }

/* the writer of the files (pinball.sav, settings.txt): the storage may take tens of milliseconds,
 * which the game must never wait for (app.h) */
static pthread_mutex_t g_io_lock;
static pthread_cond_t g_io_cond;
static bool g_io_flag;

static void io_wake(void)
{
    pthread_mutex_lock(&g_io_lock);
    g_io_flag = true;
    pthread_cond_signal(&g_io_cond);
    pthread_mutex_unlock(&g_io_lock);
}

static void *io_main(void *arg)
{
    (void)arg;
    for (;;) {
        pthread_mutex_lock(&g_io_lock);
        while (!g_io_flag) pthread_cond_wait(&g_io_cond, &g_io_lock);
        g_io_flag = false;
        pthread_mutex_unlock(&g_io_lock);
        app_io_run(&g_app);
    }
    return NULL;
}

static void io_start(void)
{
    pthread_mutex_init(&g_io_lock, NULL);
    pthread_cond_init(&g_io_cond, NULL);
    pthread_t th;
    if (pthread_create(&th, NULL, io_main, NULL) == 0) {
        pthread_detach(th);
        g_app.io_wake = io_wake;
        g_app.io_async = true;
    }
}

/* ------------------------------------------------------------------ sound */

static AudioUnit g_unit;
static _Atomic uint64_t g_pulled;          /* frames taken by the card since the unit was opened */
static _Atomic int g_unit_gen;
static SoundPacer g_sound;
static long g_gaps;

static OSStatus render_cb(void *ref, AudioUnitRenderActionFlags *flags, const AudioTimeStamp *ts,
                          UInt32 bus, UInt32 frames, AudioBufferList *io)
{
    (void)ref; (void)flags; (void)ts; (void)bus;
    if (!io || io->mNumberBuffers < 1 || !io->mBuffers[0].mData) return 0;
    UInt32 n = io->mBuffers[0].mDataByteSize / 4;
    if (n > frames) n = frames;
    app_audio_pull(&g_app, (int16_t *)io->mBuffers[0].mData, (int)n);
    atomic_fetch_add_explicit(&g_pulled, n, memory_order_relaxed);
    return 0;
}

static void audio_close(void)
{
    if (!g_unit) return;
    AudioOutputUnitStop(g_unit);
    AudioUnitUninitialize(g_unit);
    AudioComponentInstanceDispose(g_unit);
    g_unit = NULL;
}

static void audio_open(void)
{
    if (g_unit || !g_app.ui.sound) return;
    AudioComponentDescription d;
    memset(&d, 0, sizeof d);
    d.componentType = kAudioUnitType_Output;
    d.componentSubType = kAudioUnitSubType_RemoteIO;
    d.componentManufacturer = kAudioUnitManufacturer_Apple;
    AudioComponent c = AudioComponentFindNext(NULL, &d);
    if (!c || AudioComponentInstanceNew(c, &g_unit) != 0 || !g_unit) { g_unit = NULL; plog("audio: no output unit"); return; }
    /* 48 kHz, 16-bit stereo interleaved: the unit converts to the rate of the hardware */
    AudioStreamBasicDescription f;
    memset(&f, 0, sizeof f);
    f.mSampleRate = AUDIO_RATE;
    f.mFormatID = kAudioFormatLinearPCM;
    f.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    f.mBytesPerPacket = 4;
    f.mFramesPerPacket = 1;
    f.mBytesPerFrame = 4;
    f.mChannelsPerFrame = 2;
    f.mBitsPerChannel = 16;
    AURenderCallbackStruct cb = { render_cb, NULL };
    OSStatus e = AudioUnitSetProperty(g_unit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &f, sizeof f);
    if (!e) e = AudioUnitSetProperty(g_unit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &cb, sizeof cb);
    if (!e) e = AudioUnitInitialize(g_unit);
    if (!e) e = AudioOutputUnitStart(g_unit);
    if (e) {
        plog("audio: error %d", (int)e);
        AudioComponentInstanceDispose(g_unit);
        g_unit = NULL;
        return;
    }
    atomic_fetch_add(&g_unit_gen, 1);
}

/* before each frame of the game: the sound it makes keeps the card fed, AUDIO_TARGET frames ahead
 * (pacing.h); returns its action (SOUND_EXTRA: one frame more) */
static double g_rate_sum;
static long g_rate_n;

static int audio_pace(double t, int frames_left)
{
    static int gen;
    if (!g_unit) return SOUND_KEEP;
    int g = atomic_load(&g_unit_gen);
    if (g != gen) { gen = g; sound_restart(&g_sound, t); }
    double rate, pad;
    uint32_t queued = app_audio_queued(&g_app);
    bool resumed = g_sound.last_call <= 0 || t - g_sound.last_call > 0.25;    /* after a pause: its silence, not a gap */
    int act = sound_pace(&g_sound, &g_pacer, t, (double)atomic_load_explicit(&g_pulled, memory_order_relaxed),
                         (double)queued, frames_left, &rate, &pad);
    if (act == SOUND_PAD && t - g_sound.started > 1 && !resumed) g_gaps++;
    g_rate_sum += rate;
    g_rate_n++;
    if (act == SOUND_PAD) app_audio_pad(&g_app, queued + (uint32_t)pad);
    else if (act == SOUND_FLUSH) atomic_store_explicit(&g_app.ring_flush, true, memory_order_release);
    else if (act == SOUND_TRIM) app_audio_drop(&g_app, (uint32_t)pad);
    app_set_audio_rate(&g_app, rate);
    return act;
}

/* What the page ABOUT shows (ui.info), measured over 10 s of play, as on Android: the screen's rate and
 * the frames of the game it shows, the game's speed and its sound's against the Game Boy (100 %), the
 * gaps in the sound since the start, the card's rate as it took its samples. */
static struct {
    double t0, pulled0;
    long frames;
} g_meter;

static void meter(double t, bool running)
{
    if (!running || !g_unit || t - g_meter.t0 > 12) {            /* a pause: measured afresh */
        g_meter.t0 = t;
        g_meter.pulled0 = (double)atomic_load(&g_pulled);
        g_meter.frames = 0;
        g_rate_sum = 0;
        g_rate_n = 0;
        return;
    }
    if (t - g_meter.t0 < 10 || !g_rate_n) return;
    double secs = t - g_meter.t0, card = ((double)atomic_load(&g_pulled) - g_meter.pulled0) / secs;
    double speed = g_meter.frames / secs * PACER_GAME_PERIOD * 100, sound = g_sound.rate / (g_rate_sum / g_rate_n) * 100;
    char ratio[16];
    if (g_pacer.locked) snprintf(ratio, sizeof ratio, "%d/%d", g_pacer.num, g_pacer.den);
    else snprintf(ratio, sizeof ratio, "in time");
    NSUInteger pads = ns_count(msg(CLASS("GCController"), "controllers"));
    snprintf(g_app.ui.info, sizeof g_app.ui.info, "Screen %.1f Hz, %s\nGame speed %.2f %%\nSound %.2f %%, %ld gaps\n"
             "Card %.2f kHz\nTaptic Engine %s; gamepads %d",
             g_pacer.period > 0 ? 1.0 / g_pacer.period : 0.0, ratio, speed, sound, g_gaps, card / 1000,
             g_haptic[UI_HAPTIC_HEAVY] ? "yes" : "none", (int)pads);
    g_meter.t0 = t;
    g_meter.pulled0 = (double)atomic_load(&g_pulled);
    g_meter.frames = 0;
    g_rate_sum = 0;
    g_rate_n = 0;
}

/* ------------------------------------------------------------------ haptics */

static void haptic_init(void)
{
    static const NSInteger style[4] = { 0, IMPACT_LIGHT, IMPACT_MEDIUM, IMPACT_HEAVY };
    id cls = CLASS("UIImpactFeedbackGenerator");
    for (int k = UI_HAPTIC_TICK; cls && k <= UI_HAPTIC_HEAVY; k++) {
        g_haptic[k] = MSG1(id, NSInteger, msg(cls, "alloc"), "initWithStyle:", style[k]);
        if (g_haptic[k]) msg_void(g_haptic[k], "prepare");
    }
}

static void haptic(int kind)
{
    if (kind < UI_HAPTIC_TICK || kind > UI_HAPTIC_HEAVY || !g_haptic[kind]) return;
    msg_void(g_haptic[kind], "impactOccurred");
    msg_void(g_haptic[kind], "prepare");
}

/* ------------------------------------------------------------------ the buttons: gamepads, keyboards, tilts */

static void update_pad(void) { app_set_pad(&g_app, g_pad_buttons | g_key_buttons | g_tilt_buttons); }

static bool pressed(id input) { return input && msg_b(input, "isPressed"); }
static bool pressed_of(id gp, const char *name) { return responds(gp, name) && pressed(msg(gp, name)); }

static void dpad(id pad, uint8_t *m)
{
    if (!pad) return;
    if (pressed(msg(pad, "up"))) *m |= GBC_UP;
    if (pressed(msg(pad, "down"))) *m |= GBC_DOWN;
    if (pressed(msg(pad, "left"))) *m |= GBC_LEFT;
    if (pressed(msg(pad, "right"))) *m |= GBC_RIGHT;
}

/* the keys of the Android version: A, right shoulder / trigger = A (right flipper); left shoulder /
 * trigger = LEFT (left flipper); B, X = B; Y, options = SELECT; menu = START; home = the menu of the app
 * (taken from the system: iOS 14.5) */
static void poll_controllers(void)
{
    id all = msg(CLASS("GCController"), "controllers");
    uint8_t m = 0;
    bool home = false;
    for (NSUInteger i = 0; i < ns_count(all); i++) {
        id gp = msg(ns_at(all, i), "extendedGamepad");
        if (!gp) continue;
        dpad(msg(gp, "dpad"), &m);
        dpad(msg(gp, "leftThumbstick"), &m);
        if (pressed(msg(gp, "buttonA")) || pressed(msg(gp, "rightShoulder")) || pressed(msg(gp, "rightTrigger"))) m |= GBC_A;
        if (pressed(msg(gp, "leftShoulder")) || pressed(msg(gp, "leftTrigger"))) m |= GBC_LEFT;
        if (pressed(msg(gp, "buttonB")) || pressed(msg(gp, "buttonX"))) m |= GBC_B;
        if (pressed(msg(gp, "buttonY")) || pressed_of(gp, "buttonOptions")) m |= GBC_SELECT;
        if (pressed_of(gp, "buttonMenu")) m |= GBC_START;
        if (responds(gp, "buttonHome")) {
            id h = msg(gp, "buttonHome");
            if (h && responds(h, "setPreferredSystemGestureState:")) MSG1(void, NSInteger, h, "setPreferredSystemGestureState:", GESTURE_DISABLED);
            home |= pressed(h);
        }
    }
    if (home && !g_home_held) app_back(&g_app);
    g_home_held = home;
    if (m != g_pad_buttons) { g_pad_buttons = m; update_pad(); }
}

/* a keyboard's key (UIKeyboardHIDUsage), as the Android version reads them */
static uint8_t key_button(NSInteger usage)
{
    switch (usage) {
    case 0x52: return GBC_UP;
    case 0x51: return GBC_DOWN;
    case 0x50: return GBC_LEFT;
    case 0x4F: return GBC_RIGHT;
    case 0x2C: case 0x1B: case 0xE5: case 0x10: return GBC_A;          /* space, X, right shift, M */
    case 0x06: return GBC_B;                                             /* C */
    case 0x1D: case 0x1A: case 0xE1: return GBC_LEFT;                    /* Z, W, left shift */
    case 0x28: case 0x58: return GBC_START;                              /* return, keypad enter */
    case 0x19: case 0x2B: return GBC_SELECT;                             /* V, tab */
    default: return 0;
    }
}

static void presses(id set, bool down)
{
    id all = msg(set, "allObjects");
    for (NSUInteger i = 0; i < ns_count(all); i++) {
        id p = ns_at(all, i);
        id key = responds(p, "key") ? msg(p, "key") : nil;
        if (!key) continue;
        NSInteger u = MSG0(NSInteger, key, "keyCode");
        if (u == 0x29) { if (down) app_back(&g_app); continue; }        /* Esc: the menu */
        if (u >= 0 && u < 256) g_keys[u] = down;
    }
    uint8_t m = 0;
    for (int k = 0; k < 256; k++) if (g_keys[k]) m |= key_button(k);
    if (m != g_key_buttons) { g_key_buttons = m; update_pad(); }
}

static void presses_began(id self, SEL cmd, id set, id ev) { (void)self; (void)cmd; (void)ev; presses(set, true); }
static void presses_ended(id self, SEL cmd, id set, id ev) { (void)self; (void)cmd; (void)ev; presses(set, false); }

/* MOTION TILT: the accelerometer read while a table or a bonus stage is played (CoreMotion calls the
 * block below on its own queue; the samples wait in a ring for the game) */
static id g_motion_mgr, g_motion_queue;
static bool g_accel_on;
static Motion g_motion;
typedef struct { double t; float x, y, z; } AccSample;
static AccSample g_acc[ACC_RING];
static _Atomic uint32_t g_acc_w, g_acc_r;

static bool g_no_accel;                    /* no accelerometer (an iPod touch, an iPad...) */

static void accel_sample(id data, id error)
{
    (void)error;
    if (!data) return;
    PnsAcceleration a = MSG_STRUCT0(PnsAcceleration, data, "acceleration");
    double ts = msg_d(data, "timestamp");
    uint32_t w = atomic_load_explicit(&g_acc_w, memory_order_relaxed), r = atomic_load_explicit(&g_acc_r, memory_order_acquire);
    if (w - r >= ACC_RING) return;
    g_acc[w & (ACC_RING - 1)].t = ts;
    g_acc[w & (ACC_RING - 1)].x = (float)(-a.x * 9.80665);       /* in m/s², as Android reads them (motion.h) */
    g_acc[w & (ACC_RING - 1)].y = (float)(-a.y * 9.80665);
    g_acc[w & (ACC_RING - 1)].z = (float)(-a.z * 9.80665);
    atomic_store_explicit(&g_acc_w, w + 1, memory_order_release);
}

#ifdef __BLOCKS__
static void (^g_accel_block)(id, id) = ^(id data, id error) { accel_sample(data, error); };
#define ACCEL_HANDLER ((id)g_accel_block)
#else
/* (tools/iosmock, built by MSVC: no blocks there; its CoreMotion calls the function) */
#define ACCEL_HANDLER ((id)(void *)accel_sample)
#endif

static void motion_setup(void)
{
    if (CMErrorDomain && CLASS("CMMotionManager")) g_motion_mgr = new_of("CMMotionManager");
    if (!g_motion_mgr || !msg_b(g_motion_mgr, "isAccelerometerAvailable")) {
        g_no_accel = true;
        g_app.ui.menu_hide |= 1u << UI_ENTRY_MOTION;        /* no MOTION TILT in the menu */
        return;
    }
    g_motion_queue = new_of("NSOperationQueue");
    msg_setd(g_motion_mgr, "setAccelerometerUpdateInterval:", 1.0 / 200);
}

static void motion_enable(bool on)
{
    if (on == g_accel_on || g_no_accel) return;
    g_accel_on = on;
    if (on) {
        motion_reset(&g_motion);
        atomic_store(&g_acc_r, atomic_load(&g_acc_w));
        MSG(void, (id, id), g_motion_mgr, "startAccelerometerUpdatesToQueue:withHandler:", g_motion_queue, ACCEL_HANDLER);
    } else {
        msg_void(g_motion_mgr, "stopAccelerometerUpdates");
    }
}

static void motion_poll(double now)
{
    bool shaking = now - g_last_vibration < 0.12;          /* the Taptic Engine: its pulses, and their end */
    uint32_t w = atomic_load_explicit(&g_acc_w, memory_order_acquire), r = atomic_load_explicit(&g_acc_r, memory_order_relaxed);
    for (; r != w; r++) {
        const AccSample *s = &g_acc[r & (ACC_RING - 1)];
        if (!g_accel_on) continue;
        int tilt = motion_sample(&g_motion, s->t, s->x, s->y, s->z, shaking);
        if (!tilt || now - g_last_touch < 0.2) continue;   /* the jolt of a finger on the screen: the touch says it */
        g_tilt_buttons = tilt == MOTION_LEFT ? GBC_DOWN : tilt == MOTION_RIGHT ? GBC_B : GBC_SELECT;
        g_tilt_until = now + MOTION_HOLD;
        update_pad();
    }
    atomic_store_explicit(&g_acc_r, r, memory_order_release);
}

/* ------------------------------------------------------------------ screen */

static id screen_of_view(void)
{
    id win = g_view ? msg(g_view, "window") : nil;
    id scr = win ? msg(win, "screen") : nil;
    return scr ? scr : msg(CLASS("UIScreen"), "mainScreen");
}

/* the size of the screen in pixels, the parts covered by the system (camera housing, home
 * indicator) and the radius of the rounded corners of the screen */
static void update_layout(void)
{
    CGRect b = MSG_STRUCT0(CGRect, g_view, "bounds");
    int w = (int)(b.size.width * g_scale + 0.5), h = (int)(b.size.height * g_scale + 0.5);
    if (w <= 0 || h <= 0) return;
    if (w != g_w || h != g_h || g_app.ui.W != w || g_app.ui.H != h) {
        g_w = w;
        g_h = h;
        CGSize ds = { (CGFloat)w, (CGFloat)h };
        MSG1(void, CGSize, g_layer, "setDrawableSize:", ds);
        app_layout(&g_app, w, h);
        plog("screen %d x %d pixels (x%.3f)", w, h, g_scale);
    }
    PnsEdgeInsets in = MSG_STRUCT0(PnsEdgeInsets, g_view, "safeAreaInsets");
    id scr = screen_of_view();
    double corner = 0;
    if (responds(scr, "_displayCornerRadius")) corner = MSG0(double, scr, "_displayCornerRadius");
    else if (in.bottom > 0) corner = 40;              /* Face ID iPhones: about 40 to 62 points */
    if (corner < 0 || corner > 200) corner = 0;
    app_set_insets(&g_app, (int)(in.top * g_scale + 0.5), (int)(in.bottom * g_scale + 0.5),
                   (int)(in.left * g_scale + 0.5), (int)(in.right * g_scale + 0.5), (int)(corner * g_scale + 0.5));
}

/* ------------------------------------------------------------------ the frame */

/* QUIT in the menu: everything saved, then the Home screen (an app of iOS does not end itself) */
static void leave(void)
{
    app_suspend(&g_app);
    plog("quit");
    id app = msg(CLASS("UIApplication"), "sharedApplication");
    if (responds(app, "suspend")) msg_void(app, "suspend");
    else exit(0);
}

/* a refresh of the screen: the frames of the game it calls for (pacing.h), the menu, the picture */
static void tick(id self, SEL cmd, id link)
{
    (void)self; (void)cmd;
    void *pool = objc_autoreleasePoolPush();
    double t = CACurrentMediaTime(), vsync = msg_d(link, "timestamp");
    if (g_app.sound_changed) {
        g_app.sound_changed = false;
        if (g_app.ui.sound) audio_open(); else audio_close();
    }
    poll_controllers();
    motion_poll(t);
    bool running = app_running(&g_app);
    if (running) {
        int n = pacer_frames(&g_pacer, vsync, 6);
        bool extra = false;
        for (int k = 0; k < n; k++) {
            /* the sound may ask for one frame more (its target raised: pacing.h) */
            if (audio_pace(t, n - k) == SOUND_EXTRA && !extra) { extra = true; n++; }
            app_run_frame(&g_app);
            g_meter.frames++;
        }
    } else {
        pacer_restart(&g_pacer);
    }
    app_update(&g_app, t);
    meter(t, running);
    bool motion = g_app.ui.motion && g_app.ui.field && !g_app.ui.menu_open && running;
    motion_enable(motion);
    if (g_tilt_buttons && (t >= g_tilt_until || !motion)) { g_tilt_buttons = 0; update_pad(); }
    if (g_app.quit) {                                  /* "QUIT" in the menu */
        g_app.quit = false;
        leave();
    }
    int fb = app_take_haptic(&g_app);
    if (g_app.vibration_test) { g_app.vibration_test = false; haptic(UI_HAPTIC_HEAVY); g_last_vibration = t; }   /* VIBRATION on */
    else if (g_app.rumble && t - g_last_vibration > 0.045) { haptic(UI_HAPTIC_HEAVY); g_last_vibration = t; }
    else if (fb && t - g_last_vibration > 0.03) { haptic(fb); g_last_vibration = t; }

    int fw = 0, fh = 0, stride = 0;
    const uint32_t *px = app_frame(&g_app, &fw, &fh, &stride);
    update_layout();
    app_build(&g_app, &g_list);
    mr_frame(&g_mr, g_layer, &g_list, g_w, g_h, px, stride, fw, fh);
    objc_autoreleasePoolPop(pool);
}

static void become_active(void)
{
    import_from_documents();
    pacer_restart(&g_pacer);
    audio_open();
    if (g_link) msg_setb(g_link, "setPaused:", false);
}

static void resign_active(void)
{
    if (g_link) msg_setb(g_link, "setPaused:", true);
    memset(g_touch, 0, sizeof g_touch);
    app_touch(&g_app, UI_CANCEL, 0, 0, 0);
    memset(g_keys, 0, sizeof g_keys);
    g_pad_buttons = g_key_buttons = g_tilt_buttons = 0;
    update_pad();
    motion_enable(false);
    app_suspend(&g_app);                               /* iOS may end the app from now on */
    audio_close();
}

/* ------------------------------------------------------------------ the view: touches */

static Class layer_class(id self, SEL cmd) { (void)self; (void)cmd; return (Class)objc_getClass("CAMetalLayer"); }

static void touches(id view, id set, int action)
{
    id all = msg(set, "allObjects");
    for (NSUInteger i = 0; i < ns_count(all); i++) {
        id t = ns_at(all, i);
        int slot = -1;
        for (int k = 0; k < UI_MAX_POINTERS; k++) if (g_touch[k] == t) { slot = k; break; }
        if (slot < 0 && action == UI_DOWN)
            for (int k = 0; k < UI_MAX_POINTERS; k++) if (!g_touch[k]) { slot = k; g_touch[k] = t; break; }
        if (slot < 0) continue;
        CGPoint p = MSG_STRUCT(CGPoint, (id), t, "locationInView:", view);
        app_touch(&g_app, action, slot, (float)(p.x * g_scale), (float)(p.y * g_scale));
        if (action == UI_UP) g_touch[slot] = nil;
    }
}

static void touches_began(id self, SEL cmd, id set, id ev)
{
    (void)cmd; (void)ev;
    g_last_touch = CACurrentMediaTime();
    touches(self, set, UI_DOWN);
}
static void touches_moved(id self, SEL cmd, id set, id ev) { (void)cmd; (void)ev; touches(self, set, UI_MOVE); }

static void touches_ended(id self, SEL cmd, id set, id ev)
{
    (void)cmd; (void)ev;
    touches(self, set, UI_UP);
    if (!app_has_game(&g_app)) present_picker();      /* the screen that asks for the ROM */
}

static void touches_cancelled(id self, SEL cmd, id set, id ev)
{
    (void)self; (void)cmd; (void)set; (void)ev;
    memset(g_touch, 0, sizeof g_touch);
    app_touch(&g_app, UI_CANCEL, 0, 0, 0);
}

/* ------------------------------------------------------------------ the view controller */

static void vc_load_view(id self, SEL cmd)
{
    (void)cmd;
    CGRect zero = { { 0, 0 }, { 0, 0 } };
    g_view = MSG1(id, CGRect, msg(CLASS("PNSView"), "alloc"), "initWithFrame:", zero);
    msg_setb(g_view, "setMultipleTouchEnabled:", true);
    msg_set(g_view, "setBackgroundColor:", msg(CLASS("UIColor"), "blackColor"));
    msg_set(self, "setView:", g_view);                 /* the controller keeps it; g_view keeps its own reference */
}

static void vc_did_load(id self, SEL cmd)
{
    (void)cmd;
    g_scale = msg_d(screen_of_view(), "nativeScale");
    if (g_scale <= 0) g_scale = 1;
    g_layer = msg(g_view, "layer");
    id device = MTLCreateSystemDefaultDevice();
    msg_set(g_layer, "setDevice:", device);
    msg_setu(g_layer, "setPixelFormat:", PIXEL_BGRA8);
    msg_setb(g_layer, "setFramebufferOnly:", true);
    msg_setb(g_layer, "setOpaque:", true);
    msg_setd(g_layer, "setContentsScale:", g_scale);
    if (!mr_init(&g_mr, device)) plog("Metal: %s", g_mr.error);

    g_link = MSG(id, (id, SEL), CLASS("CADisplayLink"), "displayLinkWithTarget:selector:", self, SEL_("tick:"));
    retain(g_link);
    MSG1(void, NSInteger, g_link, "setPreferredFramesPerSecond:", 60);
    /* NSRunLoopCommonModes: the frames go on while a finger moves */
    MSG(void, (id, id), g_link, "addToRunLoop:forMode:", msg(CLASS("NSRunLoop"), "mainRunLoop"), nsstr("kCFRunLoopCommonModes"));
}

/* the keys of a keyboard come to the controller (the first responder) */
static void vc_did_appear(id self, SEL cmd, BOOL animated) { (void)cmd; (void)animated; msg_void(self, "becomeFirstResponder"); }

static BOOL vc_yes(id self, SEL cmd) { (void)self; (void)cmd; return YES; }
static BOOL vc_no(id self, SEL cmd) { (void)self; (void)cmd; return NO; }
static NSUInteger vc_edges(id self, SEL cmd) { (void)self; (void)cmd; return EDGE_ALL; }   /* system swipes: a second swipe */
static NSUInteger vc_orientations(id self, SEL cmd) { (void)self; (void)cmd; return MASK_PORTRAIT; }

/* ------------------------------------------------------------------ app and scene delegates */

static BOOL app_did_finish(id self, SEL cmd, id app, id options)
{
    (void)self; (void)cmd; (void)options;
    const char *home = cstr(NSHomeDirectory());
    snprintf(g_docs, sizeof g_docs, "%s/Documents", home);
    snprintf(g_dir, sizeof g_dir, "%s/Library/Application Support/Pinball NS", home);
    mkdirs(g_docs);
    mkdirs(g_dir);
    log_open();
    if (!g_app_ready) {
        app_init(&g_app, g_dir, AUDIO_RATE);
        g_app.ui.no_rom_how = "Tap here to choose it in Files, share it to Pinball NS, or copy it to Files > On My iPhone > "
                              "Pinball NS.\n\n";
        sound_reset(&g_sound, AUDIO_RATE, AUDIO_TARGET);
        g_sound.limit = APP_RING;
        pacer_reset(&g_pacer);
        io_start();
        motion_setup();
        g_app_ready = true;
    }
    haptic_init();
    msg_setb(app, "setIdleTimerDisabled:", true);     /* the screen stays on while playing */
    return YES;
}

static void app_will_terminate(id self, SEL cmd, id app) { (void)self; (void)cmd; (void)app; app_suspend(&g_app); }

static void scene_connect(id self, SEL cmd, id scene, id session, id options)
{
    (void)self; (void)cmd; (void)session;
    g_window = MSG1(id, id, msg(CLASS("UIWindow"), "alloc"), "initWithWindowScene:", scene);
    g_vc = new_of("PNSViewController");
    msg_set(g_window, "setRootViewController:", g_vc);
    msg_void(g_window, "makeKeyAndVisible");
    if (options) import_contexts(msg(options, "URLContexts"));
}

static void scene_open_urls(id self, SEL cmd, id scene, id contexts) { (void)self; (void)cmd; (void)scene; import_contexts(contexts); }
static void scene_active(id self, SEL cmd, id scene) { (void)self; (void)cmd; (void)scene; become_active(); }
static void scene_resign(id self, SEL cmd, id scene) { (void)self; (void)cmd; (void)scene; resign_active(); }
static id scene_window(id self, SEL cmd) { (void)self; (void)cmd; return g_window; }
static void scene_set_window(id self, SEL cmd, id w) { (void)self; (void)cmd; (void)w; }

static void register_classes(void)
{
    Class c = make_class("PNSAppDelegate", "UIResponder");
    add_protocol(c, "UIApplicationDelegate");
    add_method(c, "application:didFinishLaunchingWithOptions:", (void *)app_did_finish, "B@:@@");
    add_method(c, "applicationWillTerminate:", (void *)app_will_terminate, "v@:@");
    objc_registerClassPair(c);

    c = make_class("PNSSceneDelegate", "UIResponder");
    add_protocol(c, "UIWindowSceneDelegate");
    add_method(c, "scene:willConnectToSession:options:", (void *)scene_connect, "v@:@@@");
    add_method(c, "scene:openURLContexts:", (void *)scene_open_urls, "v@:@@");
    add_method(c, "sceneDidBecomeActive:", (void *)scene_active, "v@:@");
    add_method(c, "sceneWillResignActive:", (void *)scene_resign, "v@:@");
    add_method(c, "window", (void *)scene_window, "@@:");
    add_method(c, "setWindow:", (void *)scene_set_window, "v@:@");
    objc_registerClassPair(c);

    c = make_class("PNSViewController", "UIViewController");
    add_protocol(c, "UIDocumentPickerDelegate");
    add_method(c, "loadView", (void *)vc_load_view, "v@:");
    add_method(c, "viewDidLoad", (void *)vc_did_load, "v@:");
    add_method(c, "viewDidAppear:", (void *)vc_did_appear, "v@:B");
    add_method(c, "canBecomeFirstResponder", (void *)vc_yes, "B@:");
    add_method(c, "pressesBegan:withEvent:", (void *)presses_began, "v@:@@");
    add_method(c, "pressesEnded:withEvent:", (void *)presses_ended, "v@:@@");
    add_method(c, "pressesCancelled:withEvent:", (void *)presses_ended, "v@:@@");
    add_method(c, "prefersStatusBarHidden", (void *)vc_yes, "B@:");
    add_method(c, "prefersHomeIndicatorAutoHidden", (void *)vc_no, "B@:");
    add_method(c, "preferredScreenEdgesDeferringSystemGestures", (void *)vc_edges, "Q@:");
    add_method(c, "supportedInterfaceOrientations", (void *)vc_orientations, "Q@:");
    add_method(c, "tick:", (void *)tick, "v@:@");
    add_method(c, "documentPicker:didPickDocumentsAtURLs:", (void *)picker_picked, "v@:@@");
    add_method(c, "documentPickerWasCancelled:", (void *)picker_cancelled, "v@:@");
    objc_registerClassPair(c);

    c = make_class("PNSView", "UIView");
    add_class_method(c, "layerClass", (void *)layer_class, "#@:");
    add_method(c, "touchesBegan:withEvent:", (void *)touches_began, "v@:@@");
    add_method(c, "touchesMoved:withEvent:", (void *)touches_moved, "v@:@@");
    add_method(c, "touchesEnded:withEvent:", (void *)touches_ended, "v@:@@");
    add_method(c, "touchesCancelled:withEvent:", (void *)touches_cancelled, "v@:@@");
    objc_registerClassPair(c);
}

#ifdef PNS_MOCK
/* tools/iosmock: the same app, on a simulated iOS */
MobileApp *pns_mock_app(void) { return &g_app; }
int pns_mock_main(int argc, char *argv[])
#else
int main(int argc, char *argv[])
#endif
{
    void *pool = objc_autoreleasePoolPush();
    register_classes();
    int r = UIApplicationMain(argc, argv, nil, nsstr("PNSAppDelegate"));
    objc_autoreleasePoolPop(pool);
    return r;
}
