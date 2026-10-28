/*
 * main_android.c - Android front-end of "Pokemon Pinball : table complete", in C only.
 *
 * The app is a NativeActivity (no Java code at all): this file receives the activity
 * callbacks, runs the game on its own thread, draws with OpenGL ES 2 (the table with a
 * "sharp bilinear" filter, and the touch controls), plays the sound with AAudio, reads
 * the accelerometer (the option MOTION TILT) and uses JNI for the few Java services it
 * needs (reading the ROM the player opens with the app, vibration, full screen).
 *
 * Dual-screen devices (AYN Thor...): the small Java class DualScreen (platform/android/java) opens
 * the second display and hands its surface here; on a table, the top half is drawn on the
 * activity's screen and the bottom half with the status bar on the second one (see dual_mode).
 *
 * The game logic of the mobile version (ROM, saves, menu, touch interface) is in
 * platform/mobile/; this file is only the Android glue.
 */
#include <android/native_activity.h>
#include <android/log.h>
#include <android/looper.h>
#include <android/sensor.h>
#include <android/window.h>
#ifndef PB_MOCK
#include <android/native_window_jni.h>
#endif
#include <aaudio/AAudio.h>
#include <EGL/egl.h>
#include <GLES2/gl2.h>
#include <dirent.h>
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <math.h>
#include <pthread.h>
#include <semaphore.h>
#include <stdatomic.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <sys/resource.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>

#include "../mobile/app.h"
#include "../mobile/motion.h"
#include "../../src/front/font5x7.h"
#include "../../src/front/pacing.h"
#include "gles_render.h"

#define TAG "PinballTC"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)

#define AUDIO_RATE     48000
#define AUDIO_TARGET   2048            /* stereo frames kept ahead of the sound card */
#define ROM_MAX        (8u << 20)

enum { LOOPER_ID_MAIN = 1, LOOPER_ID_INPUT = 2, LOOPER_ID_SENSOR = 3 };
enum {
    CMD_INPUT_CHANGED, CMD_INIT_WINDOW, CMD_TERM_WINDOW, CMD_GAINED_FOCUS, CMD_LOST_FOCUS,
    CMD_START, CMD_RESUME, CMD_PAUSE, CMD_STOP, CMD_DESTROY, CMD_CONFIG, CMD_DUAL
};

/* ------------------------------------------------------------------ process-wide state */

/* One game per process. Android may run two instances of the activity for a moment
 * (e.g. the player opens the ROM with the app while it is already running): they
 * share the game, and only the one in front runs it. */
static MobileApp g_app;
static bool g_app_ready;
static pthread_mutex_t g_game = PTHREAD_MUTEX_INITIALIZER;
static struct Activity *g_front;          /* the activity that runs the game */

static AAudioStream *g_stream;
static _Atomic long g_pulled;           /* frames the sound card has asked for */
static _Atomic int g_stream_gen;        /* streams opened */
static volatile int g_audio_error;
static int32_t g_burst, g_xruns;        /* the stream's burst; its own underruns seen so far */
static double g_xrun_check;

/* The vibrators (global refs, created once). 2.8 (issue 4 of the project: no vibration at all on a
 * POCO F4, HyperOS, nor on its Bluetooth gamepad): the phone's is the default vibrator of the vibrator
 * manager from Android 12 on (getSystemService("vibrator") before), and every vibration says what it
 * is for: the rumble, part of a game, "media" (Android 13+: VibrationAttributes; 8-12: AudioAttributes
 * USAGE_GAME), the keys "touch" (USAGE_ASSISTANCE_SONIFICATION) - without it the system classes them as
 * "unknown". The method ids are those of android.os.Vibrator: valid for any vibrator, the gamepad's too. */
static int g_sdk;
static jobject g_vibrator;
static jmethodID g_vib_vibrate;            /* vibrate(long) */
static jmethodID g_vib_vibrate_fx;         /* vibrate(VibrationEffect), Android 8+ */
static jmethodID g_vib_vibrate_attr;       /* vibrate(VibrationEffect, VibrationAttributes or AudioAttributes) */
static jmethodID g_vib_has;                /* hasVibrator() */
static jobject g_attr_media, g_attr_touch; /* the attributes of the rumble and of the keys */
static jobject g_fx[4];                    /* the effect of each UI_HAPTIC_* (NULL: a plain vibration) */
static jobject g_fx_rumble;                /* a pulse of the rumble motor (60 ms) */
static char g_vib_info[48];                /* what was found (the page ABOUT) */
/* the gamepad played with (the last one a button or a stick came from) and its vibrator, if it has one */
static _Atomic int g_pad_id = -1;
static int g_pad_vib_id = -1;
static jobject g_pad_vibrator;
static _Atomic bool g_pad_rumbles;

static double now_s(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + ts.tv_nsec * 1e-9;
}

/* ------------------------------------------------------------------ helper threads */

/* The vibrator and the storage are slow at times (a call to a system service, an fsync of the
 * flash: milliseconds, tens of milliseconds): the game thread, which has 16 ms per picture, hands
 * them to threads of their own and never waits for them. */
static JavaVM *g_vm;
static sem_t g_haptic_sem, g_io_sem;
static _Atomic int g_haptic_kind;           /* the strongest UI_HAPTIC_* waiting, 0: none */
static _Atomic int g_haptic_pulse;          /* a pulse of the rumble motor waiting */
static void vibrate(JNIEnv *env, long ms);
static void haptic(JNIEnv *env, int kind);
static void rumble_pulse(JNIEnv *env);

static void *haptic_thread(void *arg)
{
    (void)arg;
    setpriority(PRIO_PROCESS, (id_t)gettid(), 0);       /* not the game thread's priority */
    JNIEnv *env = NULL;
    if ((*g_vm)->AttachCurrentThread(g_vm, &env, NULL) != JNI_OK) return NULL;
    pthread_setname_np(pthread_self(), "pns-haptics");  /* (after: attaching names it) */
    for (;;) {
        while (sem_wait(&g_haptic_sem) != 0) {}
        int pulse = atomic_exchange(&g_haptic_pulse, 0), kind = atomic_exchange(&g_haptic_kind, 0);
        if (pulse) rumble_pulse(env);
        else if (kind) haptic(env, kind);
    }
    return NULL;
}

static void haptic_post(int kind, bool pulse)
{
    if (pulse) atomic_store(&g_haptic_pulse, 1);
    else {
        int k = atomic_load(&g_haptic_kind);
        while (kind > k && !atomic_compare_exchange_weak(&g_haptic_kind, &k, kind)) {}
    }
    sem_post(&g_haptic_sem);
}

static void io_wake(void) { sem_post(&g_io_sem); }

static void *io_thread(void *arg)
{
    (void)arg;
    pthread_setname_np(pthread_self(), "pns-files");
    setpriority(PRIO_PROCESS, (id_t)gettid(), 0);
    for (;;) {
        while (sem_wait(&g_io_sem) != 0) {}
        app_io_run(&g_app);
    }
    return NULL;
}

static void start_helpers(JavaVM *vm)
{
    static bool started;
    if (started) return;
    started = true;
    g_vm = vm;
    sem_init(&g_haptic_sem, 0, 0);
    sem_init(&g_io_sem, 0, 0);
    pthread_attr_t attr;
    pthread_attr_init(&attr);
    pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
    pthread_t t;
    pthread_create(&t, &attr, haptic_thread, NULL);
    if (pthread_create(&t, &attr, io_thread, NULL) == 0) {
        g_app.io_wake = io_wake;
        g_app.io_async = true;
    }
    pthread_attr_destroy(&attr);
}

/* ------------------------------------------------------------------ per activity */

typedef struct Activity {
    ANativeActivity *na;
    pthread_t thread;
    pthread_mutex_t mutex;
    pthread_cond_t cond;
    int msgread, msgwrite;
    ALooper *looper;
    AInputQueue *queue, *pending_queue;
    ANativeWindow *window, *pending_window;
    int state;                          /* last of CMD_START/RESUME/PAUSE/STOP */
    bool focused, running, destroyed, destroy_requested;
    JNIEnv *env;                        /* of the game thread */
    /* rendering */
    EGLDisplay dpy;
    EGLSurface surf;
    EGLContext ctx;
    EGLConfig cfg;
    int w, h;
    GlRenderer gr;
    /* the second screen (DualScreen.java): its window (dual_pending: set by the UI thread, taken by
     * the game thread), its surface in the same context, what it shows (DUAL_*) and its list */
    ANativeWindow *dual_window, *dual_pending;
    EGLSurface dual_surf;
    int dual_mode;
    bool dual_eat;                      /* the finger that opened the menu: its moves and its lift ignored */
    UiList dual_list;
    /* timing (the screen sets the pace: src/front/pacing.h), input */
    Pacer pacer;
    /* the vertical blanks of the display (vsync_request): time of the last one (CLOCK_MONOTONIC) */
    struct AChoreographer *choreo;
    bool vsync_posted, vsync_due;
    double vsync_time, last_step;
#ifdef PNS_TEST
    /* the pace, for the tests: refreshes, frames run, refreshes with none or more than one,
     * longest time between two refreshes */
    long st_refresh, st_frames, st_none, st_more;
    double st_last, st_maxdt;
    /* where the time goes (ms, sum and longest): late = the call after the vertical blank,
     * emu = the game's frames, prep = picture and display list, draw = GL, swap */
    double st_sum[5], st_max[5];
    long st_steps;
#endif
    double last_vibration, insets_tried;
    double last_touch;                  /* a finger came down on the screen (the accelerometer: not a tilt) */
    bool insets_known;
    bool keys[256];
    uint8_t axis_buttons;
    /* MOTION TILT: the accelerometer, on the looper of the game thread; the tilt a nudge pressed */
    ASensorManager *sensor_mgr;
    const ASensor *accel;
    ASensorEventQueue *sensors;
    bool accel_on;
    Motion motion;
    uint8_t tilt_buttons;
    double tilt_until;
    UiList list;
} Activity;

/* ------------------------------------------------------------------ vertical blanks */

/* The time eglSwapBuffers returns at says little: the system lets the app queue a buffer or two ahead,
 * and the swap then returns at once, or waits for two refreshes (measured on the emulator: 1 frame
 * in 5 drawn after 0 or 2 frames of the game). The Choreographer gives the time of each vertical
 * blank of the display, exactly: the game thread waits for it (on its looper) and the pace of the
 * game is counted in refreshes from these times (pacing.h). Android 7 and later, found at run time
 * (the frame callback with a 64-bit time on Android 10 and later). */
typedef struct AChoreographer AChoreographer;
typedef void (*VsyncCb)(long ns, void *data);
typedef void (*VsyncCb64)(int64_t ns, void *data);
static struct {
    AChoreographer *(*get)(void);
    void (*post)(AChoreographer *, VsyncCb, void *);
    void (*post64)(AChoreographer *, VsyncCb64, void *);
} g_vsync;

static AChoreographer *vsync_init(void)
{
#ifdef PB_MOCK
    return NULL;                        /* the mock's looper is not the system's: swaps only */
#else
    void *lib = dlopen("libandroid.so", RTLD_NOW);
    if (!lib) return NULL;
    g_vsync.get = (AChoreographer *(*)(void))dlsym(lib, "AChoreographer_getInstance");
    g_vsync.post = (void (*)(AChoreographer *, VsyncCb, void *))dlsym(lib, "AChoreographer_postFrameCallback");
    g_vsync.post64 = (void (*)(AChoreographer *, VsyncCb64, void *))dlsym(lib, "AChoreographer_postFrameCallback64");
    if (!g_vsync.get || (!g_vsync.post && !g_vsync.post64)) return NULL;
    return g_vsync.get();               /* the game thread's (it has a looper) */
#endif
}

static void on_vsync(Activity *a, int64_t ns)
{
    a->vsync_posted = false;
    a->vsync_due = true;
    a->vsync_time = (double)ns * 1e-9;
}
static void vsync_cb(long ns, void *data) { on_vsync((Activity *)data, (int64_t)ns); }
static void vsync_cb64(int64_t ns, void *data) { on_vsync((Activity *)data, ns); }

/* the next vertical blank, called back by the looper of the game thread */
static void vsync_request(Activity *a)
{
    if (!a->choreo || a->vsync_posted) return;
    if (g_vsync.post64) g_vsync.post64(a->choreo, vsync_cb64, a);
    else g_vsync.post(a->choreo, vsync_cb, a);
    a->vsync_posted = true;
}

/* ------------------------------------------------------------------ performance hints */

/* Android 13 and later (APerformanceHint, found at run time): the system is told how long the work
 * of each refresh took against a budget, and sets the processor's speed for it. Without it the game
 * thread, about a millisecond of work every refresh, can be left on a slow core at a low clock: the
 * rarer frames with more work (the other half redrawn, a late frame finished, several frames to catch
 * up) then last longer than a refresh, a picture shown twice and the sound short. Budget: half the
 * refresh period. */
typedef struct APerformanceHintManager APerformanceHintManager;
typedef struct APerformanceHintSession APerformanceHintSession;
static struct {
    APerformanceHintSession *s;
    int (*update)(APerformanceHintSession *, int64_t);
    int (*report)(APerformanceHintSession *, int64_t);
    int64_t target;
} g_hint;

static void hint_init(void)
{
#ifndef PB_MOCK
    void *lib = dlopen("libandroid.so", RTLD_NOW);
    if (!lib) return;
    APerformanceHintManager *(*manager)(void) = (APerformanceHintManager *(*)(void))dlsym(lib, "APerformanceHint_getManager");
    APerformanceHintSession *(*create)(APerformanceHintManager *, const int32_t *, size_t, int64_t) =
        (APerformanceHintSession *(*)(APerformanceHintManager *, const int32_t *, size_t, int64_t))dlsym(lib, "APerformanceHint_createSession");
    g_hint.update = (int (*)(APerformanceHintSession *, int64_t))dlsym(lib, "APerformanceHint_updateTargetWorkDuration");
    g_hint.report = (int (*)(APerformanceHintSession *, int64_t))dlsym(lib, "APerformanceHint_reportActualWorkDuration");
    if (!manager || !create || !g_hint.update || !g_hint.report) return;
    APerformanceHintManager *m = manager();
    if (!m) return;
    int32_t tid = (int32_t)gettid();
    g_hint.target = 8333333;
    g_hint.s = create(m, &tid, 1, g_hint.target);
    LOGI("performance hints: %s", g_hint.s ? "on" : "refused");
#endif
}

/* the work of a refresh took `work` seconds; the refresh period is `period` (0: not known yet) */
static void hint_report(double work, double period)
{
    if (!g_hint.s) return;
    if (period > 0.004 && period < 0.05) {
        int64_t t = (int64_t)(period * 0.5e9);
        if (t > g_hint.target + g_hint.target / 20 || t < g_hint.target - g_hint.target / 20) {
            g_hint.target = t;
            g_hint.update(g_hint.s, t);
        }
    }
    if (work > 0) g_hint.report(g_hint.s, (int64_t)(work * 1e9));
}

static void write_cmd(Activity *a, int8_t cmd)
{
    if (write(a->msgwrite, &cmd, sizeof cmd) != sizeof cmd) LOGE("write_cmd failed: %s", strerror(errno));
}

static bool active(const Activity *a) { return a->window && a->state == CMD_RESUME && a->focused; }

/* ------------------------------------------------------------------ JNI helpers */

static bool jni_check(JNIEnv *env)
{
    if ((*env)->ExceptionCheck(env)) {
        (*env)->ExceptionClear(env);
        return true;
    }
    return false;
}

static void vibrate(JNIEnv *env, long ms)
{
    if (!g_vibrator || !env) return;
    (*env)->CallVoidMethod(env, g_vibrator, g_vib_vibrate, (jlong)ms);
    jni_check(env);
}

/* an effect on a vibrator, with its attributes where the system takes them */
static bool vibrate_fx(JNIEnv *env, jobject vib, jobject fx, jobject attr)
{
    if (!vib || !fx) return false;
    if (g_vib_vibrate_attr && attr) (*env)->CallVoidMethod(env, vib, g_vib_vibrate_attr, fx, attr);
    else if (g_vib_vibrate_fx) (*env)->CallVoidMethod(env, vib, g_vib_vibrate_fx, fx);
    else return false;
    return !jni_check(env);
}

/* the feedback of the touch controls: the system's own key clicks where available (Android
 * 10+: tick, click, heavy click), else short vibrations of chosen strength (Android 8+) */
static void haptic(JNIEnv *env, int kind)
{
    if (!g_vibrator || !env || kind <= UI_HAPTIC_NONE || kind > UI_HAPTIC_HEAVY) return;
    if (!vibrate_fx(env, g_vibrator, g_fx[kind], g_attr_touch))
        vibrate(env, kind == UI_HAPTIC_HEAVY ? 20 : kind == UI_HAPTIC_CLICK ? 12 : 6);
}

/* The vibrator of the gamepad played with (InputDevice: its vibrator manager's default one from Android
 * 12 on, getVibrator() before), looked up again when the gamepad changes; NULL if it has none. */
static jobject pad_vibrator(JNIEnv *env)
{
    int id = atomic_load(&g_pad_id);
    if (id == g_pad_vib_id) return g_pad_vibrator;
    if (g_pad_vibrator) { (*env)->DeleteGlobalRef(env, g_pad_vibrator); g_pad_vibrator = NULL; }
    g_pad_vib_id = id;
    atomic_store(&g_pad_rumbles, false);
    if (id < 0) return NULL;
    jclass ic = (*env)->FindClass(env, "android/view/InputDevice");
    if (jni_check(env) || !ic) return NULL;
    jmethodID gd = (*env)->GetStaticMethodID(env, ic, "getDevice", "(I)Landroid/view/InputDevice;");
    jobject dev = !jni_check(env) && gd ? (*env)->CallStaticObjectMethod(env, ic, gd, (jint)id) : NULL;
    if (jni_check(env)) dev = NULL;
    jobject v = NULL;
    if (dev && g_sdk >= 31) {
        jmethodID gm = (*env)->GetMethodID(env, ic, "getVibratorManager", "()Landroid/os/VibratorManager;");
        jobject mgr = !jni_check(env) && gm ? (*env)->CallObjectMethod(env, dev, gm) : NULL;
        if (jni_check(env)) mgr = NULL;
        if (mgr) {
            jclass mc = (*env)->FindClass(env, "android/os/VibratorManager");
            jmethodID gdv = !jni_check(env) && mc ? (*env)->GetMethodID(env, mc, "getDefaultVibrator", "()Landroid/os/Vibrator;") : NULL;
            if (!jni_check(env) && gdv) v = (*env)->CallObjectMethod(env, mgr, gdv);
            if (jni_check(env)) v = NULL;
            if (mc) (*env)->DeleteLocalRef(env, mc);
            (*env)->DeleteLocalRef(env, mgr);
        }
    }
    if (dev && !v) {
        jmethodID gv = (*env)->GetMethodID(env, ic, "getVibrator", "()Landroid/os/Vibrator;");
        v = !jni_check(env) && gv ? (*env)->CallObjectMethod(env, dev, gv) : NULL;
        if (jni_check(env)) v = NULL;
    }
    if (v && g_vib_has && (*env)->CallBooleanMethod(env, v, g_vib_has) && !jni_check(env)) {
        g_pad_vibrator = (*env)->NewGlobalRef(env, v);
        atomic_store(&g_pad_rumbles, true);
    }
    jni_check(env);
    if (v) (*env)->DeleteLocalRef(env, v);
    if (dev) (*env)->DeleteLocalRef(env, dev);
    (*env)->DeleteLocalRef(env, ic);
    return g_pad_vibrator;
}

/* a pulse of the game's rumble motor: the phone, and the gamepad played with */
static void rumble_pulse(JNIEnv *env)
{
    if (!env) return;
    if (g_vibrator && !vibrate_fx(env, g_vibrator, g_fx_rumble, g_attr_media)) vibrate(env, 60);
    jobject pad = pad_vibrator(env);
    if (pad) vibrate_fx(env, pad, g_fx_rumble, NULL);
}

/* the attributes of a vibration for (usage): VibrationAttributes on Android 13+, AudioAttributes
 * before (usage: the AudioAttributes one) */
static jobject vib_attributes(JNIEnv *env, int vib_usage, int audio_usage)
{
    jobject at = NULL;
    if (g_sdk >= 33) {
        jclass c = (*env)->FindClass(env, "android/os/VibrationAttributes");
        jmethodID cf = !jni_check(env) && c ? (*env)->GetStaticMethodID(env, c, "createForUsage", "(I)Landroid/os/VibrationAttributes;") : NULL;
        if (!jni_check(env) && cf) at = (*env)->CallStaticObjectMethod(env, c, cf, (jint)vib_usage);
        if (jni_check(env)) at = NULL;
        if (c) (*env)->DeleteLocalRef(env, c);
    } else {
        jclass c = (*env)->FindClass(env, "android/media/AudioAttributes$Builder");
        jmethodID init = !jni_check(env) && c ? (*env)->GetMethodID(env, c, "<init>", "()V") : NULL;
        jmethodID su = init ? (*env)->GetMethodID(env, c, "setUsage", "(I)Landroid/media/AudioAttributes$Builder;") : NULL;
        jmethodID bd = su ? (*env)->GetMethodID(env, c, "build", "()Landroid/media/AudioAttributes;") : NULL;
        jobject b = !jni_check(env) && bd ? (*env)->NewObject(env, c, init) : NULL;
        if (jni_check(env)) b = NULL;
        if (b) {
            jobject b2 = (*env)->CallObjectMethod(env, b, su, (jint)audio_usage);
            if (!jni_check(env) && b2) { at = (*env)->CallObjectMethod(env, b2, bd); if (jni_check(env)) at = NULL; }
            if (b2) (*env)->DeleteLocalRef(env, b2);
            (*env)->DeleteLocalRef(env, b);
        }
        if (c) (*env)->DeleteLocalRef(env, c);
    }
    if (!at) return NULL;
    jobject g = (*env)->NewGlobalRef(env, at);
    (*env)->DeleteLocalRef(env, at);
    return g;
}

static void init_effects(ANativeActivity *na, jclass vcls)
{
    JNIEnv *env = na->env;
    if (na->sdkVersion < 26) return;
    jclass ve = (*env)->FindClass(env, "android/os/VibrationEffect");
    if (jni_check(env) || !ve) return;
    jmethodID pre = na->sdkVersion >= 29 ? (*env)->GetStaticMethodID(env, ve, "createPredefined", "(I)Landroid/os/VibrationEffect;") : NULL;
    if (jni_check(env)) pre = NULL;
    jmethodID one = (*env)->GetStaticMethodID(env, ve, "createOneShot", "(JI)Landroid/os/VibrationEffect;");
    if (jni_check(env)) one = NULL;
    static const jint predefined[4] = { -1, 2, 0, 5 };          /* EFFECT_TICK, EFFECT_CLICK, EFFECT_HEAVY_CLICK */
    static const jlong ms[4] = { 0, 6, 12, 20 };
    static const jint amp[4] = { 0, 70, 150, 255 };
    for (int k = UI_HAPTIC_TICK; k <= UI_HAPTIC_HEAVY; k++) {
        jobject fx = pre ? (*env)->CallStaticObjectMethod(env, ve, pre, predefined[k]) : NULL;
        if (jni_check(env)) fx = NULL;
        if (!fx && one) { fx = (*env)->CallStaticObjectMethod(env, ve, one, ms[k], amp[k]); if (jni_check(env)) fx = NULL; }
        if (fx) { g_fx[k] = (*env)->NewGlobalRef(env, fx); (*env)->DeleteLocalRef(env, fx); }
    }
    jobject fx = one ? (*env)->CallStaticObjectMethod(env, ve, one, (jlong)60, (jint)-1) : NULL;   /* DEFAULT_AMPLITUDE */
    if (jni_check(env)) fx = NULL;
    if (fx) { g_fx_rumble = (*env)->NewGlobalRef(env, fx); (*env)->DeleteLocalRef(env, fx); }
    g_vib_vibrate_fx = (*env)->GetMethodID(env, vcls, "vibrate", "(Landroid/os/VibrationEffect;)V");
    if (jni_check(env)) g_vib_vibrate_fx = NULL;
    g_vib_vibrate_attr = na->sdkVersion >= 33
        ? (*env)->GetMethodID(env, vcls, "vibrate", "(Landroid/os/VibrationEffect;Landroid/os/VibrationAttributes;)V")
        : (*env)->GetMethodID(env, vcls, "vibrate", "(Landroid/os/VibrationEffect;Landroid/media/AudioAttributes;)V");
    if (jni_check(env)) g_vib_vibrate_attr = NULL;
    /* VibrationAttributes USAGE_MEDIA 19, USAGE_TOUCH 18; AudioAttributes USAGE_GAME 14,
     * USAGE_ASSISTANCE_SONIFICATION 13 */
    if (g_vib_vibrate_attr) {
        g_attr_media = vib_attributes(env, 19, 14);
        g_attr_touch = vib_attributes(env, 18, 13);
    }
    (*env)->DeleteLocalRef(env, ve);
}

/* the phone's vibrator: the vibrator manager's default one (Android 12+), else the "vibrator" service */
static jobject phone_vibrator(ANativeActivity *na)
{
    JNIEnv *env = na->env;
    jclass acls = (*env)->GetObjectClass(env, na->clazz);
    jmethodID gss = (*env)->GetMethodID(env, acls, "getSystemService", "(Ljava/lang/String;)Ljava/lang/Object;");
    jobject vib = NULL;
    if (gss && na->sdkVersion >= 31) {
        jstring name = (*env)->NewStringUTF(env, "vibrator_manager");
        jobject mgr = (*env)->CallObjectMethod(env, na->clazz, gss, name);
        if (jni_check(env)) mgr = NULL;
        if (mgr) {
            jclass mc = (*env)->GetObjectClass(env, mgr);
            jmethodID gdv = (*env)->GetMethodID(env, mc, "getDefaultVibrator", "()Landroid/os/Vibrator;");
            if (!jni_check(env) && gdv) vib = (*env)->CallObjectMethod(env, mgr, gdv);
            if (jni_check(env)) vib = NULL;
            (*env)->DeleteLocalRef(env, mc);
            (*env)->DeleteLocalRef(env, mgr);
        }
        (*env)->DeleteLocalRef(env, name);
    }
    if (gss && !vib) {
        jstring name = (*env)->NewStringUTF(env, "vibrator");
        vib = (*env)->CallObjectMethod(env, na->clazz, gss, name);
        if (jni_check(env)) vib = NULL;
        (*env)->DeleteLocalRef(env, name);
    }
    jni_check(env);
    (*env)->DeleteLocalRef(env, acls);
    return vib;
}

/* UI thread: create the vibrator reference (once) */
static void init_vibrator(ANativeActivity *na)
{
    if (g_vibrator) return;
    JNIEnv *env = na->env;
    g_sdk = na->sdkVersion;
    snprintf(g_vib_info, sizeof g_vib_info, "none");
    jobject vib = phone_vibrator(na);
    jclass vcls = (*env)->FindClass(env, "android/os/Vibrator");
    if (jni_check(env)) vcls = NULL;
    if (vib && vcls) {
        g_vib_vibrate = (*env)->GetMethodID(env, vcls, "vibrate", "(J)V");
        if (jni_check(env)) g_vib_vibrate = NULL;
        g_vib_has = (*env)->GetMethodID(env, vcls, "hasVibrator", "()Z");
        if (jni_check(env)) g_vib_has = NULL;
        jmethodID amp = (*env)->GetMethodID(env, vcls, "hasAmplitudeControl", "()Z");
        if (jni_check(env)) amp = NULL;
        bool has = g_vib_has ? (*env)->CallBooleanMethod(env, vib, g_vib_has) : true;
        if (jni_check(env)) has = true;
        bool ac = amp && (*env)->CallBooleanMethod(env, vib, amp);
        if (jni_check(env)) ac = false;
        if (g_vib_vibrate) {
            g_vibrator = (*env)->NewGlobalRef(env, vib);
            init_effects(na, vcls);
            snprintf(g_vib_info, sizeof g_vib_info, "%s%s%s", has ? "yes" : "none", ac ? ", amplitude" : "",
                     g_vib_vibrate_attr && g_attr_media ? ", media" : "");
        }
    }
    if (vcls) (*env)->DeleteLocalRef(env, vcls);
    if (vib) (*env)->DeleteLocalRef(env, vib);
}

/* UI thread (before the window is laid out): the window also covers the camera cut-out
 * (Android 9+); the table goes under it when the controls need the room (see query_insets) */
static void set_cutout_mode(ANativeActivity *na)
{
    if (na->sdkVersion < 28) return;
    JNIEnv *env = na->env;
    jclass acls = (*env)->GetObjectClass(env, na->clazz);
    jmethodID get_window = (*env)->GetMethodID(env, acls, "getWindow", "()Landroid/view/Window;");
    jobject win = get_window ? (*env)->CallObjectMethod(env, na->clazz, get_window) : NULL;
    if (jni_check(env)) win = NULL;
    if (win) {
        jclass wcls = (*env)->GetObjectClass(env, win);
        jmethodID get_attr = (*env)->GetMethodID(env, wcls, "getAttributes", "()Landroid/view/WindowManager$LayoutParams;");
        jmethodID set_attr = (*env)->GetMethodID(env, wcls, "setAttributes", "(Landroid/view/WindowManager$LayoutParams;)V");
        jobject lp = (get_attr && !jni_check(env)) ? (*env)->CallObjectMethod(env, win, get_attr) : NULL;
        if (jni_check(env)) lp = NULL;
        if (lp && set_attr) {
            jclass lcls = (*env)->GetObjectClass(env, lp);
            jfieldID mode = (*env)->GetFieldID(env, lcls, "layoutInDisplayCutoutMode", "I");
            if (!jni_check(env) && mode) {
                (*env)->SetIntField(env, lp, mode, 1);          /* LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES */
                (*env)->CallVoidMethod(env, win, set_attr, lp);
                jni_check(env);
            }
            (*env)->DeleteLocalRef(env, lcls);
        }
        if (lp) (*env)->DeleteLocalRef(env, lp);
        (*env)->DeleteLocalRef(env, wcls);
        (*env)->DeleteLocalRef(env, win);
    }
    jni_check(env);
    (*env)->DeleteLocalRef(env, acls);
}

/* Game thread: the screen covered by the camera cut-out (safe insets, Android 9+), and the
 * radius of the rounded corners of the screen (Android 12+). False when not known yet (the
 * window is not laid out). */
static bool query_insets(JNIEnv *env, jobject act, int sdk, int *t, int *b, int *l, int *r, int *corner)
{
    *t = *b = *l = *r = *corner = 0;
    if (sdk < 28 || !env) return true;
    bool known = false;
    jclass acls = (*env)->GetObjectClass(env, act);
    jmethodID get_window = (*env)->GetMethodID(env, acls, "getWindow", "()Landroid/view/Window;");
    jobject win = get_window ? (*env)->CallObjectMethod(env, act, get_window) : NULL;
    if (jni_check(env)) win = NULL;
    if (win) {
        jclass wcls = (*env)->GetObjectClass(env, win);
        jmethodID get_decor = (*env)->GetMethodID(env, wcls, "getDecorView", "()Landroid/view/View;");
        jobject decor = get_decor ? (*env)->CallObjectMethod(env, win, get_decor) : NULL;
        if (jni_check(env)) decor = NULL;
        if (decor) {
            jclass vcls = (*env)->GetObjectClass(env, decor);
            jmethodID get_insets = (*env)->GetMethodID(env, vcls, "getRootWindowInsets", "()Landroid/view/WindowInsets;");
            jobject ins = get_insets ? (*env)->CallObjectMethod(env, decor, get_insets) : NULL;
            if (jni_check(env)) ins = NULL;
            if (ins) {
                known = true;
                jclass icls = (*env)->GetObjectClass(env, ins);
                jmethodID get_cut = (*env)->GetMethodID(env, icls, "getDisplayCutout", "()Landroid/view/DisplayCutout;");
                jobject cut = get_cut ? (*env)->CallObjectMethod(env, ins, get_cut) : NULL;
                if (jni_check(env)) cut = NULL;
                if (cut) {
                    jclass ccls = (*env)->GetObjectClass(env, cut);
                    static const char *const names[4] = { "getSafeInsetTop", "getSafeInsetBottom", "getSafeInsetLeft", "getSafeInsetRight" };
                    int *out[4] = { t, b, l, r };
                    for (int k = 0; k < 4; k++) {
                        jmethodID m = (*env)->GetMethodID(env, ccls, names[k], "()I");
                        if (jni_check(env) || !m) continue;
                        jint v = (*env)->CallIntMethod(env, cut, m);
                        if (!jni_check(env) && v > 0 && v < 4096) *out[k] = (int)v;
                    }
                    (*env)->DeleteLocalRef(env, ccls);
                    (*env)->DeleteLocalRef(env, cut);
                }
                if (sdk >= 31) {
                    /* RoundedCorner of each corner (POSITION_TOP_LEFT .. POSITION_BOTTOM_LEFT) */
                    jmethodID get_rc = (*env)->GetMethodID(env, icls, "getRoundedCorner", "(I)Landroid/view/RoundedCorner;");
                    if (jni_check(env)) get_rc = NULL;
                    for (int pos = 0; get_rc && pos < 4; pos++) {
                        jobject rc = (*env)->CallObjectMethod(env, ins, get_rc, (jint)pos);
                        if (jni_check(env) || !rc) continue;
                        jclass rcls = (*env)->GetObjectClass(env, rc);
                        jmethodID get_r = (*env)->GetMethodID(env, rcls, "getRadius", "()I");
                        jint v = (!jni_check(env) && get_r) ? (*env)->CallIntMethod(env, rc, get_r) : 0;
                        if (!jni_check(env) && v > *corner && v < 2048) *corner = (int)v;
                        (*env)->DeleteLocalRef(env, rcls);
                        (*env)->DeleteLocalRef(env, rc);
                    }
                }
                (*env)->DeleteLocalRef(env, icls);
                (*env)->DeleteLocalRef(env, ins);
            }
            (*env)->DeleteLocalRef(env, vcls);
            (*env)->DeleteLocalRef(env, decor);
        }
        (*env)->DeleteLocalRef(env, wcls);
        (*env)->DeleteLocalRef(env, win);
    }
    jni_check(env);
    (*env)->DeleteLocalRef(env, acls);
    return known;
}

/* UI thread: full screen, navigation bar hidden until the player swipes */
static void set_immersive(ANativeActivity *na)
{
    JNIEnv *env = na->env;
    jclass acls = (*env)->GetObjectClass(env, na->clazz);
    jmethodID get_window = (*env)->GetMethodID(env, acls, "getWindow", "()Landroid/view/Window;");
    jobject win = get_window ? (*env)->CallObjectMethod(env, na->clazz, get_window) : NULL;
    if (jni_check(env)) win = NULL;
    if (win) {
        jclass wcls = (*env)->GetObjectClass(env, win);
        jmethodID get_decor = (*env)->GetMethodID(env, wcls, "getDecorView", "()Landroid/view/View;");
        jobject decor = get_decor ? (*env)->CallObjectMethod(env, win, get_decor) : NULL;
        if (jni_check(env)) decor = NULL;
        if (decor) {
            jclass vcls = (*env)->GetObjectClass(env, decor);
            jmethodID set_vis = (*env)->GetMethodID(env, vcls, "setSystemUiVisibility", "(I)V");
            /* IMMERSIVE_STICKY | LAYOUT_FULLSCREEN | LAYOUT_HIDE_NAVIGATION | LAYOUT_STABLE
             * | FULLSCREEN | HIDE_NAVIGATION */
            if (set_vis) (*env)->CallVoidMethod(env, decor, set_vis, (jint)(0x1000 | 0x400 | 0x200 | 0x100 | 0x4 | 0x2));
            jni_check(env);
            (*env)->DeleteLocalRef(env, vcls);
            (*env)->DeleteLocalRef(env, decor);
        }
        (*env)->DeleteLocalRef(env, wcls);
        (*env)->DeleteLocalRef(env, win);
    }
    jni_check(env);
    (*env)->DeleteLocalRef(env, acls);
}

/* Game thread: if the activity was opened with a file ("Open with" / "Share"),
 * read it (content:// URI) and give it to the app as the ROM. */
static void import_from_intent(JNIEnv *env, jobject act)
{
    jclass acls = (*env)->GetObjectClass(env, act);
    jmethodID get_intent = (*env)->GetMethodID(env, acls, "getIntent", "()Landroid/content/Intent;");
    jobject intent = get_intent ? (*env)->CallObjectMethod(env, act, get_intent) : NULL;
    if (jni_check(env) || !intent) { (*env)->DeleteLocalRef(env, acls); return; }

    jclass icls = (*env)->GetObjectClass(env, intent);
    jmethodID get_data = (*env)->GetMethodID(env, icls, "getData", "()Landroid/net/Uri;");
    jobject uri = get_data ? (*env)->CallObjectMethod(env, intent, get_data) : NULL;
    if (jni_check(env)) uri = NULL;
    jstring extra = (*env)->NewStringUTF(env, "android.intent.extra.STREAM");
    if (!uri) {
        jmethodID get_extra = (*env)->GetMethodID(env, icls, "getParcelableExtra", "(Ljava/lang/String;)Landroid/os/Parcelable;");
        if (get_extra) uri = (*env)->CallObjectMethod(env, intent, get_extra, extra);
        if (jni_check(env)) uri = NULL;
        if (uri) {
            jclass ucls = (*env)->FindClass(env, "android/net/Uri");
            if (jni_check(env) || !ucls || !(*env)->IsInstanceOf(env, uri, ucls)) { (*env)->DeleteLocalRef(env, uri); uri = NULL; }
            if (ucls) (*env)->DeleteLocalRef(env, ucls);
        }
    }
    if (uri) {
        uint8_t *buf = (uint8_t *)malloc(ROM_MAX);
        size_t total = 0;
        bool ok = buf != NULL;
        jmethodID get_cr = (*env)->GetMethodID(env, acls, "getContentResolver", "()Landroid/content/ContentResolver;");
        jobject cr = ok && get_cr ? (*env)->CallObjectMethod(env, act, get_cr) : NULL;
        if (jni_check(env) || !cr) ok = false;
        jobject in = NULL;
        if (ok) {
            jclass ccls = (*env)->GetObjectClass(env, cr);
            jmethodID open = (*env)->GetMethodID(env, ccls, "openInputStream", "(Landroid/net/Uri;)Ljava/io/InputStream;");
            in = open ? (*env)->CallObjectMethod(env, cr, open, uri) : NULL;
            if (jni_check(env) || !in) { ok = false; in = NULL; }
            (*env)->DeleteLocalRef(env, ccls);
        }
        if (ok) {
            jclass scls = (*env)->GetObjectClass(env, in);
            jmethodID rd = (*env)->GetMethodID(env, scls, "read", "([B)I");
            jmethodID cl = (*env)->GetMethodID(env, scls, "close", "()V");
            jbyteArray jb = (*env)->NewByteArray(env, 65536);
            while (ok && rd && jb) {
                jint n = (*env)->CallIntMethod(env, in, rd, jb);
                if (jni_check(env)) { ok = false; break; }
                if (n < 0) break;
                if (total + (size_t)n > ROM_MAX) { ok = false; break; }
                (*env)->GetByteArrayRegion(env, jb, 0, n, (jbyte *)(buf + total));
                total += (size_t)n;
            }
            if (cl) (*env)->CallVoidMethod(env, in, cl);
            jni_check(env);
            if (jb) (*env)->DeleteLocalRef(env, jb);
            (*env)->DeleteLocalRef(env, scls);
            (*env)->DeleteLocalRef(env, in);
        }
        if (cr) (*env)->DeleteLocalRef(env, cr);
        pthread_mutex_lock(&g_game);
        if (ok && total > 0) app_import_rom(&g_app, buf, total);
        else ui_toast(&g_app.ui, "Could not read this file", 4);
        pthread_mutex_unlock(&g_game);
        free(buf);

        /* done with it: a later re-creation of the activity must not import it again */
        jmethodID set_data = (*env)->GetMethodID(env, icls, "setData", "(Landroid/net/Uri;)Landroid/content/Intent;");
        jmethodID remove_extra = (*env)->GetMethodID(env, icls, "removeExtra", "(Ljava/lang/String;)V");
        if (set_data) { jobject r = (*env)->CallObjectMethod(env, intent, set_data, (jobject)NULL); if (r) (*env)->DeleteLocalRef(env, r); }
        jni_check(env);
        if (remove_extra) (*env)->CallVoidMethod(env, intent, remove_extra, extra);
        jni_check(env);
        (*env)->DeleteLocalRef(env, uri);
    }
    (*env)->DeleteLocalRef(env, extra);
    (*env)->DeleteLocalRef(env, icls);
    (*env)->DeleteLocalRef(env, intent);
    (*env)->DeleteLocalRef(env, acls);
}

/* ROM copied by USB into the app's folder (Android/data/<package>/files) */
static void import_from_external_dir(const char *dir)
{
    if (!dir) return;
    DIR *d = opendir(dir);
    if (!d) return;
    struct dirent *e;
    /* every ROM (or patch of Generations) put there whose game is not installed yet (2.8: only when no game
     * was; the other game could not be added that way) */
    while ((e = readdir(d)) != NULL) {
        size_t n = strlen(e->d_name);
        if (n < 4) continue;
        const char *ext = e->d_name + n - 4;
        if (strcasecmp(ext, ".gbc") != 0 && strcasecmp(ext + 1, ".gb") != 0 && strcasecmp(ext, ".ips") != 0) continue;
        char path[1024];
        snprintf(path, sizeof path, "%s/%s", dir, e->d_name);
        FILE *f = fopen(path, "rb");
        if (!f) continue;
        uint8_t *buf = (uint8_t *)malloc(ROM_MAX);
        size_t r = buf ? fread(buf, 1, ROM_MAX, f) : 0;
        fclose(f);
        if (r > 0 && !app_has_rom(&g_app, buf, r)) app_import_rom(&g_app, buf, r);
        free(buf);
    }
    closedir(d);
}

/* The import runs on its own thread: reading the file can be slow (a cloud provider),
 * and the activity callbacks must never wait for it. */
typedef struct { JavaVM *vm; jobject act; char ext_dir[600]; } Importer;

static void *importer_thread(void *arg)
{
    Importer *im = (Importer *)arg;
    JNIEnv *env = NULL;
    if ((*im->vm)->AttachCurrentThread(im->vm, &env, NULL) == JNI_OK) {
        import_from_intent(env, im->act);
        (*env)->DeleteGlobalRef(env, im->act);
        (*im->vm)->DetachCurrentThread(im->vm);
    }
    pthread_mutex_lock(&g_game);
    import_from_external_dir(im->ext_dir[0] ? im->ext_dir : NULL);
    pthread_mutex_unlock(&g_game);
    free(im);
    return NULL;
}

static void start_importer(Activity *a)
{
    Importer *im = (Importer *)calloc(1, sizeof *im);
    if (!im) return;
    im->vm = a->na->vm;
    im->act = (*a->env)->NewGlobalRef(a->env, a->na->clazz);
    if (a->na->externalDataPath) snprintf(im->ext_dir, sizeof im->ext_dir, "%s", a->na->externalDataPath);
    pthread_t t;
    pthread_attr_t attr;
    pthread_attr_init(&attr);
    pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
    if (pthread_create(&t, &attr, importer_thread, im) != 0) { (*a->env)->DeleteGlobalRef(a->env, im->act); free(im); }
    pthread_attr_destroy(&attr);
}

/* ------------------------------------------------------------------ audio */

static long g_pads, g_flushes;          /* silences added, flushes */
static _Atomic long g_underruns;        /* the card found the ring short: a gap (the game running: not the
                                         * silence of a pause, the menu) */
static atomic_bool g_playing;
#ifdef PNS_TEST
static double g_pull_since;
static long g_pull_base;
#endif

static aaudio_data_callback_result_t audio_cb(AAudioStream *s, void *user, void *data, int32_t frames)
{
    (void)s; (void)user;
    int n = app_audio_pull(&g_app, (int16_t *)data, frames);
    atomic_fetch_add_explicit(&g_pulled, frames, memory_order_relaxed);
    static bool short_before;
    if (n < frames && n > 0 && !short_before && atomic_load_explicit(&g_playing, memory_order_relaxed))
        atomic_fetch_add_explicit(&g_underruns, 1, memory_order_relaxed);
    short_before = n < frames;
    return AAUDIO_CALLBACK_RESULT_CONTINUE;
}

static void audio_err_cb(AAudioStream *s, void *user, aaudio_result_t err)
{
    (void)s; (void)user;
    LOGE("audio stream error %d", (int)err);
    g_audio_error = 1;
}

static pthread_mutex_t g_audio_mutex = PTHREAD_MUTEX_INITIALIZER;

static void audio_close(void)
{
    pthread_mutex_lock(&g_audio_mutex);
    if (g_stream) {
        AAudioStream_requestStop(g_stream);
        AAudioStream_close(g_stream);
        g_stream = NULL;
    }
    pthread_mutex_unlock(&g_audio_mutex);
}

static void audio_open_locked(void);

static void audio_open(void)
{
    pthread_mutex_lock(&g_audio_mutex);
    audio_open_locked();
    pthread_mutex_unlock(&g_audio_mutex);
}

static void audio_open_locked(void)
{
    if (g_stream || !g_app.ui.sound) return;
    AAudioStreamBuilder *b = NULL;
    if (AAudio_createStreamBuilder(&b) != AAUDIO_OK) return;
    AAudioStreamBuilder_setDirection(b, AAUDIO_DIRECTION_OUTPUT);
    AAudioStreamBuilder_setSampleRate(b, AUDIO_RATE);
    AAudioStreamBuilder_setChannelCount(b, 2);
    AAudioStreamBuilder_setFormat(b, AAUDIO_FORMAT_PCM_I16);
    AAudioStreamBuilder_setSharingMode(b, AAUDIO_SHARING_MODE_SHARED);
    AAudioStreamBuilder_setPerformanceMode(b, AAUDIO_PERFORMANCE_MODE_LOW_LATENCY);
    AAudioStreamBuilder_setDataCallback(b, audio_cb, NULL);
    AAudioStreamBuilder_setErrorCallback(b, audio_err_cb, NULL);
    AAudioStream *s = NULL;
    aaudio_result_t r = AAudioStreamBuilder_openStream(b, &s);
    AAudioStreamBuilder_delete(b);
    if (r != AAUDIO_OK || !s) { LOGE("AAudio open failed: %d", (int)r); return; }
    if (AAudioStream_getSampleRate(s) != AUDIO_RATE || AAudioStream_getChannelCount(s) != 2) {
        LOGE("unexpected audio format: %d Hz, %d channels", (int)AAudioStream_getSampleRate(s), (int)AAudioStream_getChannelCount(s));
        AAudioStream_close(s);
        return;
    }
    /* The stream's own buffer, between the callback and the device: 3 bursts, 10 ms at least (up to
     * 2.6: 3 bursts, 6 ms on a phone whose bursts are 2 ms: the callback thread woken a little late
     * left the device short, a click the ring never saw), one burst more after each underrun of the
     * stream (audio_tune), up to 50 ms. */
    int32_t burst = AAudioStream_getFramesPerBurst(s);
    g_burst = burst > 0 ? burst : 192;
    int32_t want = g_burst * 3;
    while (want < AUDIO_RATE / 100) want += g_burst;
    AAudioStream_setBufferSizeInFrames(s, want);
    g_xruns = AAudioStream_getXRunCount(s);
    LOGI("audio: burst %d, buffer %d of %d, performance mode %d, sharing mode %d", (int)burst,
         (int)AAudioStream_getBufferSizeInFrames(s), (int)AAudioStream_getBufferCapacityInFrames(s),
         (int)AAudioStream_getPerformanceMode(s), (int)AAudioStream_getSharingMode(s));
    g_audio_error = 0;
    if (AAudioStream_requestStart(s) != AAUDIO_OK) { AAudioStream_close(s); return; }
    g_stream = s;
    atomic_fetch_add(&g_stream_gen, 1);
}

/* the stream's underruns (its buffer short: the callback came late), checked twice a second: its
 * buffer grows by a burst after each (as Oboe's LatencyTuner); game thread */
static void audio_tune(double t)
{
    if (t < g_xrun_check) return;
    g_xrun_check = t + 0.5;
    pthread_mutex_lock(&g_audio_mutex);
    if (g_stream) {
        int32_t x = AAudioStream_getXRunCount(g_stream);
        if (x > g_xruns) {
            g_xruns = x;
            int32_t size = AAudioStream_getBufferSizeInFrames(g_stream), cap = AAudioStream_getBufferCapacityInFrames(g_stream);
            int32_t most = AUDIO_RATE / 20 > g_burst * 4 ? AUDIO_RATE / 20 : g_burst * 4;
            if (cap > 0 && most > cap) most = cap;
            if (size > 0 && size + g_burst <= most) {
                AAudioStream_setBufferSizeInFrames(g_stream, size + g_burst);
                LOGI("audio: %d underruns of the stream, its buffer %d", (int)x, (int)AAudioStream_getBufferSizeInFrames(g_stream));
            }
        }
    }
    pthread_mutex_unlock(&g_audio_mutex);
}

/* ------------------------------------------------------------------ the second screen */

/* What the two screens show: DUAL_NONE, a single screen (the usual picture with its controls); DUAL_UI,
 * the usual picture on the main screen, the second one black (the menu, no ROM yet); DUAL_GAME, the
 * game's picture alone on the main screen (title, menus of the game, bonus stages); DUAL_TABLE, the top
 * half of the table on the main screen, its bottom half and the status bar on the second one. */
enum { DUAL_NONE = 0, DUAL_UI, DUAL_GAME, DUAL_TABLE };

#ifndef PB_MOCK
static jclass g_dual_cls;                  /* fr.pinballtc.app.DualScreen (global ref), NULL: none */
static jmethodID g_dual_start, g_dual_stop, g_dual_enable;
static jfieldID g_dual_present;            /* DualScreen.present: a second display is there */
static int g_dual_on = -1;                 /* the DUAL SCREEN setting DualScreen was last given, -1: none */
static struct Activity *g_dual_act;        /* the activity the second screen is opened for */
#endif

static void dual_release(ANativeWindow *w)
{
#ifndef PB_MOCK
    if (w) ANativeWindow_release(w);
#else
    (void)w;
#endif
}

/* the EGL surface of the second screen gone (its window kept) */
static void dual_surface_term(Activity *a)
{
    if (a->dual_surf == EGL_NO_SURFACE) return;
    if (a->dpy != EGL_NO_DISPLAY) {
        eglMakeCurrent(a->dpy, a->surf, a->surf, a->ctx);
        eglDestroySurface(a->dpy, a->dual_surf);
    }
    a->dual_surf = EGL_NO_SURFACE;
}

#ifndef PB_MOCK
/* DualScreen.nativeSurface (UI thread): the surface of the second screen created, or destroyed (NULL);
 * returns once the game thread has taken it (destroyed: no longer drawn) */
static void JNICALL dual_native_surface(JNIEnv *env, jclass c, jobject surface)
{
    (void)c;
    Activity *a = g_dual_act;
    if (!a) return;
    ANativeWindow *w = surface ? ANativeWindow_fromSurface(env, surface) : NULL;
    pthread_mutex_lock(&a->mutex);
    if (w && w == a->dual_pending) { pthread_mutex_unlock(&a->mutex); ANativeWindow_release(w); return; }
    if (!w && !a->dual_pending && !a->dual_window) { pthread_mutex_unlock(&a->mutex); return; }
    a->dual_pending = w;
    write_cmd(a, CMD_DUAL);
    while (a->dual_window != a->dual_pending && !a->destroyed) pthread_cond_wait(&a->cond, &a->mutex);
    pthread_mutex_unlock(&a->mutex);
}
#endif

/* the class DualScreen, from the app's own class loader (FindClass only sees the system's here) */
static void dual_init(ANativeActivity *na)
{
#ifndef PB_MOCK
    JNIEnv *env = na->env;
    jclass acls = (*env)->GetObjectClass(env, na->clazz);
    jmethodID gcl = (*env)->GetMethodID(env, acls, "getClassLoader", "()Ljava/lang/ClassLoader;");
    jobject cl = !jni_check(env) && gcl ? (*env)->CallObjectMethod(env, na->clazz, gcl) : NULL;
    jclass clcls = !jni_check(env) && cl ? (*env)->GetObjectClass(env, cl) : NULL;
    jmethodID load = clcls ? (*env)->GetMethodID(env, clcls, "loadClass", "(Ljava/lang/String;)Ljava/lang/Class;") : NULL;
    jstring name = load && !jni_check(env) ? (*env)->NewStringUTF(env, "fr.pinballtc.app.DualScreen") : NULL;
    jclass c = name ? (jclass)(*env)->CallObjectMethod(env, cl, load, name) : NULL;
    if (jni_check(env) || !c) { LOGI("second screen: no DualScreen class"); return; }
    static const JNINativeMethod nm[] = { { "nativeSurface", "(Ljava/lang/Object;)V", (void *)dual_native_surface } };
    if ((*env)->RegisterNatives(env, c, nm, 1) != 0 || jni_check(env)) { LOGE("second screen: RegisterNatives failed"); return; }
    g_dual_start = (*env)->GetStaticMethodID(env, c, "start", "(Landroid/app/Activity;Z)Z");
    g_dual_stop = !jni_check(env) ? (*env)->GetStaticMethodID(env, c, "stop", "()V") : NULL;
    g_dual_enable = !jni_check(env) ? (*env)->GetStaticMethodID(env, c, "setEnabled", "(Z)V") : NULL;
    g_dual_present = !jni_check(env) ? (*env)->GetStaticFieldID(env, c, "present", "Z") : NULL;
    if (jni_check(env) || !g_dual_start || !g_dual_stop || !g_dual_enable || !g_dual_present) return;
    g_dual_cls = (jclass)(*env)->NewGlobalRef(env, c);
#else
    (void)na;
#endif
}

/* the activity comes to the front / leaves it (UI thread) */
static void dual_start(ANativeActivity *na)
{
#ifndef PB_MOCK
    if (!g_dual_cls) return;
    JNIEnv *env = na->env;
    g_dual_act = (Activity *)na->instance;
    pthread_mutex_lock(&g_game);
    g_dual_on = !g_app.ui.single_screen;
    pthread_mutex_unlock(&g_game);
    jboolean there = (*env)->CallStaticBooleanMethod(env, g_dual_cls, g_dual_start, na->clazz, (jboolean)g_dual_on);
    if (jni_check(env)) there = JNI_FALSE;
    LOGI("second screen: %s", !there ? "none" : g_dual_on ? "opened" : "there, DUAL SCREEN off");
#else
    (void)na;
#endif
}

static void dual_stop(ANativeActivity *na)
{
#ifndef PB_MOCK
    if (!g_dual_cls || g_dual_act != (Activity *)na->instance) return;
    JNIEnv *env = na->env;
    (*env)->CallStaticVoidMethod(env, g_dual_cls, g_dual_stop);
    jni_check(env);
    g_dual_act = NULL;
#else
    (void)na;
#endif
}

/* the EGL surface of the second screen, once both its window and the context are there; it does not
 * wait for its vertical blanks (the main screen sets the pace) */
static void dual_surface_init(Activity *a)
{
    if (a->dual_surf != EGL_NO_SURFACE || !a->dual_window || a->dpy == EGL_NO_DISPLAY || a->ctx == EGL_NO_CONTEXT) return;
    EGLint fmt = 0;
    eglGetConfigAttrib(a->dpy, a->cfg, EGL_NATIVE_VISUAL_ID, &fmt);
    ANativeWindow_setBuffersGeometry(a->dual_window, 0, 0, fmt);
    a->dual_surf = eglCreateWindowSurface(a->dpy, a->cfg, a->dual_window, NULL);
    if (a->dual_surf == EGL_NO_SURFACE) { LOGE("second screen: no surface (0x%x)", eglGetError()); return; }
    if (eglMakeCurrent(a->dpy, a->dual_surf, a->dual_surf, a->ctx)) eglSwapInterval(a->dpy, 0);
    eglMakeCurrent(a->dpy, a->surf, a->surf, a->ctx);
}

/* the menu's DUAL SCREEN: shown while there is a second display; the setting given to DualScreen when
 * it changes (it opens or closes the second screen on the UI thread). Game thread, game lock held. */
static void dual_setting(Activity *a)
{
#ifndef PB_MOCK
    if (!g_dual_cls || g_dual_act != a) { g_app.ui.menu_hide |= 1u << UI_ENTRY_DUAL; return; }
    JNIEnv *env = a->env;
    bool there = (*env)->GetStaticBooleanField(env, g_dual_cls, g_dual_present);
    if (jni_check(env)) there = false;
    if (there) g_app.ui.menu_hide &= ~(1u << UI_ENTRY_DUAL);
    else g_app.ui.menu_hide |= 1u << UI_ENTRY_DUAL;
    int on = !g_app.ui.single_screen;
    if (on != g_dual_on) {
        g_dual_on = on;
        (*env)->CallStaticVoidMethod(env, g_dual_cls, g_dual_enable, (jboolean)on);
        jni_check(env);
    }
#else
    (void)a;
#endif
}

/* what the screens show now (DUAL_*); game lock held */
static int dual_mode_now(const Activity *a, int fh)
{
    if (a->dual_surf == EGL_NO_SURFACE || g_app.ui.single_screen) return DUAL_NONE;
    if (!g_app.pb || g_app.ui.no_rom || g_app.ui.menu_open || fh <= 0) return DUAL_UI;
    return fh == PB_FIELD_H ? DUAL_TABLE : DUAL_GAME;
}

/* the lines y0..y1 of the game's picture (fw x fh), as large as they fit in a screen of sw x sh (at most
 * smax screen pixels a game pixel, 0: no limit), centred; returns that size (0: nothing drawn) */
static float dual_game_item(UiList *l, int sw, int sh, int fw, int fh, int y0, int y1, float smax)
{
    l->n = 0;
    l->text_n = 0;
    if (sw <= 0 || sh <= 0 || fw <= 0 || y1 <= y0) return 0;
    float s = fminf((float)sw / fw, (float)sh / (y1 - y0));
    if (smax > 0 && s > smax) s = smax;
    UiItem *it = &l->item[l->n++];
    memset(it, 0, sizeof *it);
    it->kind = UI_GAME;
    it->w = fw * s;
    it->h = (y1 - y0) * s;
    it->x = (sw - it->w) / 2;
    it->y = (sh - it->h) / 2;
    it->filter = g_app.ui.filter;
    it->colors = g_app.ui.colors;
    it->fx0 = 0;
    it->fy0 = (float)y0;                 /* the filter takes no neighbour from the other half */
    it->fx1 = (float)fw;
    it->fy1 = (float)y1;
    it->sy0 = (float)y0;
    it->sy1 = (float)y1;
    (void)fh;
    return s;
}

/* ------------------------------------------------------------------ EGL */

static void egl_term(Activity *a)
{
    dual_surface_term(a);
    if (a->dpy != EGL_NO_DISPLAY) {
        eglMakeCurrent(a->dpy, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
        if (a->ctx != EGL_NO_CONTEXT) eglDestroyContext(a->dpy, a->ctx);
        if (a->surf != EGL_NO_SURFACE) eglDestroySurface(a->dpy, a->surf);
        eglTerminate(a->dpy);
    }
    a->dpy = EGL_NO_DISPLAY;
    a->ctx = EGL_NO_CONTEXT;
    a->surf = EGL_NO_SURFACE;
    a->w = a->h = 0;
}

/* Ask the system to refresh the screen at the game's rate (59.73 frames a second): a 90 or 120 Hz
 * screen then runs at 60 Hz (or 120 Hz, twice per frame), where every frame of the game stays on
 * the screen for the same time. Android 11 and later (ANativeWindow_setFrameRate, found at run
 * time: the app starts on Android 8); Android 12 and later: even if the switch is not seamless. */
static void request_game_rate(ANativeWindow *w)
{
    typedef int32_t (*SetRate)(ANativeWindow *, float, int8_t);
    typedef int32_t (*SetRateStrategy)(ANativeWindow *, float, int8_t, int8_t);
    static void *lib;
#ifdef PB_MOCK
    return;                             /* the mock's window is not the system's */
#endif
    if (!w) return;
    if (!lib) lib = dlopen("libandroid.so", RTLD_NOW);
    if (!lib) return;
    SetRateStrategy f2 = (SetRateStrategy)dlsym(lib, "ANativeWindow_setFrameRateWithChangeStrategy");
    SetRate f = (SetRate)dlsym(lib, "ANativeWindow_setFrameRate");
    const float rate = (float)(1.0 / PACER_GAME_PERIOD);
    int32_t r = -1;
    if (f2) r = f2(w, rate, 1 /* FIXED_SOURCE */, 1 /* CHANGE_FRAME_RATE_ALWAYS */);
    else if (f) r = f(w, rate, 1);
    LOGI("frame rate %.2f requested: %d", (double)rate, (int)r);
}

static bool egl_init(Activity *a)
{
    a->dpy = eglGetDisplay(EGL_DEFAULT_DISPLAY);
    if (a->dpy == EGL_NO_DISPLAY || !eglInitialize(a->dpy, NULL, NULL)) { LOGE("eglInitialize failed"); return false; }
    const EGLint want888[] = { EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT, EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
                               EGL_RED_SIZE, 8, EGL_GREEN_SIZE, 8, EGL_BLUE_SIZE, 8, EGL_NONE };
    const EGLint want565[] = { EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT, EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
                               EGL_RED_SIZE, 5, EGL_GREEN_SIZE, 6, EGL_BLUE_SIZE, 5, EGL_NONE };
    EGLConfig cfg;
    EGLint n = 0;
    if (!eglChooseConfig(a->dpy, want888, &cfg, 1, &n) || n < 1)
        if (!eglChooseConfig(a->dpy, want565, &cfg, 1, &n) || n < 1) { LOGE("no EGL config"); egl_term(a); return false; }
    a->cfg = cfg;
    EGLint fmt = 0;
    eglGetConfigAttrib(a->dpy, cfg, EGL_NATIVE_VISUAL_ID, &fmt);
    ANativeWindow_setBuffersGeometry(a->window, 0, 0, fmt);
    a->surf = eglCreateWindowSurface(a->dpy, cfg, a->window, NULL);
    const EGLint ctx_attr[] = { EGL_CONTEXT_CLIENT_VERSION, 2, EGL_NONE };
    a->ctx = eglCreateContext(a->dpy, cfg, EGL_NO_CONTEXT, ctx_attr);
    if (a->surf == EGL_NO_SURFACE || a->ctx == EGL_NO_CONTEXT || !eglMakeCurrent(a->dpy, a->surf, a->surf, a->ctx)) {
        LOGE("EGL surface/context failed: 0x%x", eglGetError());
        egl_term(a);
        return false;
    }
    eglSwapInterval(a->dpy, 1);
    if (!gr_init(&a->gr)) LOGE("renderer setup failed");
    request_game_rate(a->window);
    pacer_restart(&a->pacer);
    return true;
}

/* ------------------------------------------------------------------ input */

static uint8_t key_button(int32_t code)
{
    switch (code) {
    case AKEYCODE_DPAD_UP: return GBC_UP;
    case AKEYCODE_DPAD_DOWN: return GBC_DOWN;
    case AKEYCODE_DPAD_LEFT: return GBC_LEFT;
    case AKEYCODE_DPAD_RIGHT: return GBC_RIGHT;
    case AKEYCODE_DPAD_CENTER: case AKEYCODE_BUTTON_A: case AKEYCODE_BUTTON_R1: case AKEYCODE_BUTTON_R2:
    case AKEYCODE_SPACE: case AKEYCODE_X: case AKEYCODE_SHIFT_RIGHT: case AKEYCODE_M:
        return GBC_A;
    case AKEYCODE_BUTTON_B: case AKEYCODE_BUTTON_X: case AKEYCODE_C: return GBC_B;
    case AKEYCODE_BUTTON_L1: case AKEYCODE_BUTTON_L2: case AKEYCODE_Z: case AKEYCODE_W: case AKEYCODE_SHIFT_LEFT:
        return GBC_LEFT;
    case AKEYCODE_BUTTON_START: case AKEYCODE_ENTER: case AKEYCODE_NUMPAD_ENTER: return GBC_START;
    case AKEYCODE_BUTTON_SELECT: case AKEYCODE_BUTTON_Y: case AKEYCODE_V: case AKEYCODE_TAB: return GBC_SELECT;
    /* (2.9) gamepads Android does not know: their buttons by number, in the order of the usual layout (that of
     * the Windows version's generic gamepads): 1 X, 2 A, 3 B, 4 Y, 5 LB, 6 RB, 7 LT, 8 RT, 9 back, 10 start */
    case AKEYCODE_BUTTON_2: case AKEYCODE_BUTTON_6: case AKEYCODE_BUTTON_8: return GBC_A;
    case AKEYCODE_BUTTON_1: case AKEYCODE_BUTTON_3: return GBC_B;
    case AKEYCODE_BUTTON_5: case AKEYCODE_BUTTON_7: return GBC_LEFT;
    case AKEYCODE_BUTTON_4: case AKEYCODE_BUTTON_9: return GBC_SELECT;
    case AKEYCODE_BUTTON_10: return GBC_START;
    default: return 0;
    }
}

static void update_pad(Activity *a)
{
    uint8_t m = a->axis_buttons | a->tilt_buttons;
    for (int k = 0; k < 256; k++) if (a->keys[k]) m |= key_button(k);
    app_set_pad(&g_app, m);
}

static int handle_input(Activity *a, AInputEvent *ev)
{
    int32_t type = AInputEvent_getType(ev);
    int32_t source = AInputEvent_getSource(ev);
    if ((source & AINPUT_SOURCE_GAMEPAD) == AINPUT_SOURCE_GAMEPAD || (source & AINPUT_SOURCE_JOYSTICK) == AINPUT_SOURCE_JOYSTICK)
        atomic_store(&g_pad_id, AInputEvent_getDeviceId(ev));          /* the gamepad played with: its rumble */
    if (type == AINPUT_EVENT_TYPE_KEY) {
        int32_t code = AKeyEvent_getKeyCode(ev), action = AKeyEvent_getAction(ev);
        if (code == AKEYCODE_BACK || code == AKEYCODE_ESCAPE || code == AKEYCODE_BUTTON_MODE || code == AKEYCODE_MENU) {
            if (action == AKEY_EVENT_ACTION_UP) {
                pthread_mutex_lock(&g_game);
                app_back(&g_app);
                pthread_mutex_unlock(&g_game);
            }
            return 1;
        }
        if (!key_button(code) || code < 0 || code > 255) return 0;      /* volume etc.: the system */
        if (action == AKEY_EVENT_ACTION_DOWN) a->keys[code] = true;
        else if (action == AKEY_EVENT_ACTION_UP) a->keys[code] = false;
        pthread_mutex_lock(&g_game);
        update_pad(a);
        pthread_mutex_unlock(&g_game);
        return 1;
    }
    if (type != AINPUT_EVENT_TYPE_MOTION) return 0;

    if ((source & AINPUT_SOURCE_CLASS_JOYSTICK) != 0) {
        float x = AMotionEvent_getAxisValue(ev, AMOTION_EVENT_AXIS_X, 0);
        float y = AMotionEvent_getAxisValue(ev, AMOTION_EVENT_AXIS_Y, 0);
        float hx = AMotionEvent_getAxisValue(ev, AMOTION_EVENT_AXIS_HAT_X, 0);
        float hy = AMotionEvent_getAxisValue(ev, AMOTION_EVENT_AXIS_HAT_Y, 0);
        float lt = fmaxf(AMotionEvent_getAxisValue(ev, AMOTION_EVENT_AXIS_LTRIGGER, 0), AMotionEvent_getAxisValue(ev, AMOTION_EVENT_AXIS_BRAKE, 0));
        float rt = fmaxf(AMotionEvent_getAxisValue(ev, AMOTION_EVENT_AXIS_RTRIGGER, 0), AMotionEvent_getAxisValue(ev, AMOTION_EVENT_AXIS_GAS, 0));
        uint8_t m = 0;
        if (x < -0.5f || hx < -0.5f) m |= GBC_LEFT;
        if (x > 0.5f || hx > 0.5f) m |= GBC_RIGHT;
        if (y < -0.5f || hy < -0.5f) m |= GBC_UP;
        if (y > 0.5f || hy > 0.5f) m |= GBC_DOWN;
        if (lt > 0.3f) m |= GBC_LEFT;
        if (rt > 0.3f) m |= GBC_A;
        a->axis_buttons = m;
        pthread_mutex_lock(&g_game);
        update_pad(a);
        pthread_mutex_unlock(&g_game);
        return 1;
    }

    int32_t action = AMotionEvent_getAction(ev);
    int32_t masked = action & AMOTION_EVENT_ACTION_MASK;
    size_t index = (size_t)((action & AMOTION_EVENT_ACTION_POINTER_INDEX_MASK) >> AMOTION_EVENT_ACTION_POINTER_INDEX_SHIFT);
    if (a->dual_eat) {
        if (masked == AMOTION_EVENT_ACTION_UP || masked == AMOTION_EVENT_ACTION_CANCEL) a->dual_eat = false;
        return 1;
    }
    pthread_mutex_lock(&g_game);
    switch (masked) {
    case AMOTION_EVENT_ACTION_DOWN:
    case AMOTION_EVENT_ACTION_POINTER_DOWN:
        a->last_touch = now_s();
        if (a->dual_mode == DUAL_TABLE || a->dual_mode == DUAL_GAME) {
            /* two screens: no touch controls on the game; a finger on it opens the menu */
            if (masked == AMOTION_EVENT_ACTION_DOWN) { app_back(&g_app); a->dual_eat = true; }
            break;
        }
        app_touch(&g_app, UI_DOWN, AMotionEvent_getPointerId(ev, index), AMotionEvent_getX(ev, index), AMotionEvent_getY(ev, index));
        break;
    case AMOTION_EVENT_ACTION_UP:
    case AMOTION_EVENT_ACTION_POINTER_UP:
        app_touch(&g_app, UI_UP, AMotionEvent_getPointerId(ev, index), AMotionEvent_getX(ev, index), AMotionEvent_getY(ev, index));
        break;
    case AMOTION_EVENT_ACTION_MOVE: {
        size_t n = AMotionEvent_getPointerCount(ev);
        for (size_t i = 0; i < n; i++)
            app_touch(&g_app, UI_MOVE, AMotionEvent_getPointerId(ev, i), AMotionEvent_getX(ev, i), AMotionEvent_getY(ev, i));
        break;
    }
    case AMOTION_EVENT_ACTION_CANCEL:
        app_touch(&g_app, UI_CANCEL, 0, 0, 0);
        break;
    default:
        break;
    }
    pthread_mutex_unlock(&g_game);
    return 1;
}

/* ------------------------------------------------------------------ motion tilt */

/* The option MOTION TILT (platform/mobile/motion.h): the accelerometer read 200 times a second while
 * a table or a bonus stage is played, never in the background; a nudge of the phone presses its tilt
 * as the pad does (left: DOWN, right: B, up: SELECT) for MOTION_HOLD seconds. Game thread. */
static void sensors_init(Activity *a)
{
    ASensorManager *m = ASensorManager_getInstanceForPackage("fr.pinballtc.app");
    if (!m) return;
    a->accel = ASensorManager_getDefaultSensor(m, ASENSOR_TYPE_ACCELEROMETER);
    if (a->accel) a->sensors = ASensorManager_createEventQueue(m, a->looper, LOOPER_ID_SENSOR, NULL, NULL);
    a->sensor_mgr = m;
    LOGI("accelerometer: %s", a->sensors ? "yes" : "none");
}

static void sensors_enable(Activity *a, bool on)
{
    if (!a->sensors || on == a->accel_on) return;
    a->accel_on = on;
    if (on) {
        motion_reset(&a->motion);
        ASensorEventQueue_enableSensor(a->sensors, a->accel);
        int us = ASensor_getMinDelay(a->accel);
        ASensorEventQueue_setEventRate(a->sensors, a->accel, us > 5000 ? us : 5000);
    } else {
        ASensorEventQueue_disableSensor(a->sensors, a->accel);
    }
}

static void process_sensors(Activity *a)
{
    ASensorEvent ev[32];
    ssize_t n;
    bool shaking = now_s() - a->last_vibration < 0.12;      /* the motor: pulses of 60 ms, and their end */
    while (a->sensors && (n = ASensorEventQueue_getEvents(a->sensors, ev, 32)) > 0)
        for (ssize_t i = 0; i < n; i++) {
            if (ev[i].type != ASENSOR_TYPE_ACCELEROMETER || !a->accel_on) continue;
            int tilt = motion_sample(&a->motion, (double)ev[i].timestamp * 1e-9, ev[i].acceleration.x,
                                     ev[i].acceleration.y, ev[i].acceleration.z, shaking);
            if (!tilt) continue;
            if (now_s() - a->last_touch < 0.2) continue;   /* (2.9) the jolt of a finger on the screen: the touch says it */
            a->tilt_buttons = tilt == MOTION_LEFT ? GBC_DOWN : tilt == MOTION_RIGHT ? GBC_B : GBC_SELECT;
            a->tilt_until = now_s() + MOTION_HOLD;
            pthread_mutex_lock(&g_game);
            update_pad(a);
            pthread_mutex_unlock(&g_game);
        }
}

static void process_input(Activity *a)
{
    AInputEvent *ev = NULL;
    while (a->queue && AInputQueue_getEvent(a->queue, &ev) >= 0) {
        if (AInputQueue_preDispatchEvent(a->queue, ev)) continue;
        int handled = handle_input(a, ev);
        AInputQueue_finishEvent(a->queue, ev, handled);
    }
}

/* ------------------------------------------------------------------ commands */

static void become_front(Activity *a)
{
    pthread_mutex_lock(&g_game);
    g_front = a;
    pacer_restart(&a->pacer);
    pthread_mutex_unlock(&g_game);
    audio_open();
}

static void leave_front(Activity *a)
{
    pthread_mutex_lock(&g_game);
    bool was_front = g_front == a;
    if (was_front) {
        g_front = NULL;
        app_touch(&g_app, UI_CANCEL, 0, 0, 0);
        app_suspend(&g_app);                       /* the process may be killed from now on */
    }
    pthread_mutex_unlock(&g_game);
    if (was_front) audio_close();
}

static void process_cmd(Activity *a)
{
    int8_t cmd;
    if (read(a->msgread, &cmd, sizeof cmd) != sizeof cmd) return;
    switch (cmd) {
    case CMD_INPUT_CHANGED:
        pthread_mutex_lock(&a->mutex);
        if (a->queue) AInputQueue_detachLooper(a->queue);
        a->queue = a->pending_queue;
        if (a->queue) AInputQueue_attachLooper(a->queue, a->looper, LOOPER_ID_INPUT, NULL, NULL);
        pthread_cond_broadcast(&a->cond);
        pthread_mutex_unlock(&a->mutex);
        break;
    case CMD_INIT_WINDOW:
        pthread_mutex_lock(&a->mutex);
        a->window = a->pending_window;
        pthread_cond_broadcast(&a->cond);
        pthread_mutex_unlock(&a->mutex);
        if (a->window) egl_init(a);
        break;
    case CMD_TERM_WINDOW:
        egl_term(a);
        pthread_mutex_lock(&a->mutex);
        a->window = NULL;
        pthread_cond_broadcast(&a->cond);
        pthread_mutex_unlock(&a->mutex);
        break;
    case CMD_GAINED_FOCUS: a->focused = true; break;
    case CMD_LOST_FOCUS:
        a->focused = false;
        memset(a->keys, 0, sizeof a->keys);
        a->axis_buttons = 0;
        a->tilt_buttons = 0;
        sensors_enable(a, false);
        pthread_mutex_lock(&g_game);
        app_set_pad(&g_app, 0);
        app_touch(&g_app, UI_CANCEL, 0, 0, 0);
        pthread_mutex_unlock(&g_game);
        break;
    case CMD_PAUSE:
        leave_front(a);                              /* saves before onPause returns */
        /* fall through */
    case CMD_START:
    case CMD_RESUME:
    case CMD_STOP:
        pthread_mutex_lock(&a->mutex);
        a->state = cmd;
        pthread_cond_broadcast(&a->cond);
        pthread_mutex_unlock(&a->mutex);
        if (cmd == CMD_RESUME) become_front(a);
        break;
    case CMD_DUAL:
        /* the second screen's window changed: the old one's surface and window let go */
        dual_surface_term(a);
        pthread_mutex_lock(&a->mutex);
        if (a->dual_window != a->dual_pending) dual_release(a->dual_window);
        a->dual_window = a->dual_pending;
        pthread_cond_broadcast(&a->cond);
        pthread_mutex_unlock(&a->mutex);
        break;
    case CMD_DESTROY:
        a->destroy_requested = true;
        break;
    default:
        break;
    }
}

/* ------------------------------------------------------------------ the game thread */

/* before each frame of the game: the sound it makes keeps the card fed, AUDIO_TARGET frames ahead
 * (pacing.h; game thread); returns its action (SOUND_EXTRA: one frame more) */
static SoundPacer g_sound;

/* What the menu shows at its bottom (ui.info), measured over 10 s of play: the screen's rate and the
 * frames of the game it shows; the game's speed and its sound's (the pitch and the tempo the card
 * plays it at, its rate as it is meant to be), against the Game Boy (100 %); the gaps in the sound
 * since the start; the card's rate as it took its samples (its bursts make this a little uneven); the
 * stream (its burst and buffer, low latency or not, its own underruns). Game thread. */
static struct {
    double t0, pulled0, rate_sum;
    long frames, rate_n;
    bool ok;
} g_meter;

static void meter(Activity *a, double t, bool running)
{
    if (!running || !g_stream || t - g_meter.t0 > 12) {            /* a pause: measured afresh */
        g_meter.t0 = t;
        g_meter.pulled0 = (double)atomic_load(&g_pulled);
        g_meter.frames = 0;
        g_meter.rate_sum = 0;
        g_meter.rate_n = 0;
        return;
    }
    if (t - g_meter.t0 < 10 || !g_meter.rate_n) return;
    double secs = t - g_meter.t0, card = ((double)atomic_load(&g_pulled) - g_meter.pulled0) / secs;
    double speed = g_meter.frames / secs * PACER_GAME_PERIOD * 100, sound = g_sound.rate / (g_meter.rate_sum / g_meter.rate_n) * 100;
    char ratio[16];
    if (a->pacer.locked) snprintf(ratio, sizeof ratio, "%d/%d", a->pacer.num, a->pacer.den);
    else snprintf(ratio, sizeof ratio, "in time");
    pthread_mutex_lock(&g_audio_mutex);
    int32_t xr = g_stream ? AAudioStream_getXRunCount(g_stream) : 0, bsz = g_stream ? AAudioStream_getBufferSizeInFrames(g_stream) : 0;
    bool ll = g_stream && AAudioStream_getPerformanceMode(g_stream) == AAUDIO_PERFORMANCE_MODE_LOW_LATENCY;
    pthread_mutex_unlock(&g_audio_mutex);
    snprintf(g_app.ui.info, sizeof g_app.ui.info, "Screen %.1f Hz, %s\nGame speed %.2f %%\nSound %.2f %%, %ld gaps\nCard %.2f kHz, %d/%d%s, %d xruns\n"
             "Vibrator %s; gamepad %s",
             a->pacer.period > 0 ? 1.0 / a->pacer.period : 0.0, ratio, speed, sound, atomic_load(&g_underruns) + g_pads,
             card / 1000, (int)g_burst, (int)bsz, ll ? " LL" : "", (int)xr, g_vib_info,
             atomic_load(&g_pad_id) < 0 ? "none" : atomic_load(&g_pad_rumbles) ? "rumbles" : "no rumble");
    g_meter.t0 = t;
    g_meter.pulled0 = (double)atomic_load(&g_pulled);
    g_meter.frames = 0;
    g_meter.rate_sum = 0;
    g_meter.rate_n = 0;
}

static int audio_pace(Activity *a, double t, int frames_left)
{
    static int gen;
    if (!g_stream) return SOUND_KEEP;
    int g = atomic_load(&g_stream_gen);
    if (g != gen) { gen = g; sound_restart(&g_sound, t); }
    double rate, pad;
    uint32_t queued = app_audio_queued(&g_app);
    bool resumed = g_sound.last_call <= 0 || t - g_sound.last_call > 0.25;    /* after a pause: its silence, not a gap */
    int act = sound_pace(&g_sound, &a->pacer, t, (double)atomic_load_explicit(&g_pulled, memory_order_relaxed),
                         (double)queued, frames_left, &rate, &pad);
    if (act == SOUND_PAD && t - g_sound.started > 1 && !resumed) g_pads++;
    if (act == SOUND_FLUSH) g_flushes++;
    g_meter.rate_sum += rate;
    g_meter.rate_n++;
    if (act == SOUND_PAD) app_audio_pad(&g_app, queued + (uint32_t)pad);
    else if (act == SOUND_FLUSH) atomic_store_explicit(&g_app.ring_flush, true, memory_order_release);
    else if (act == SOUND_TRIM) app_audio_drop(&g_app, (uint32_t)pad);
    app_set_audio_rate(&g_app, rate);
    return act;
}

/* a refresh of the display at `vsync` (seconds, CLOCK_MONOTONIC) */
static void frame_step(Activity *a, double vsync)
{
    double t = now_s();
    a->last_step = t;
#ifdef PNS_TEST
    double tm[5];
    tm[0] = t;
#endif
    pthread_mutex_lock(&g_game);
    bool front = g_front == a;
    if (front && g_audio_error) { pthread_mutex_unlock(&g_game); audio_close(); audio_open(); pthread_mutex_lock(&g_game); }
    if (front && g_app.sound_changed) {
        g_app.sound_changed = false;
        pthread_mutex_unlock(&g_game);
        if (g_app.ui.sound) audio_open(); else audio_close();
        pthread_mutex_lock(&g_game);
    }
    bool ran = false;
    if (front && app_running(&g_app)) {
        /* the screen sets the pace (a refresh has just passed: the swap waited for it); the sound
         * is made at the rate that keeps the card fed (src/front/pacing.h) */
        int n = pacer_frames(&a->pacer, vsync, 6);
        bool extra = false;
        for (int k = 0; k < n; k++) {
            /* the sound may ask for one frame more (its target raised: pacing.h) */
            if (audio_pace(a, t, n - k) == SOUND_EXTRA && !extra) { extra = true; n++; }
            app_run_frame(&g_app);
            ran = true;
            g_meter.frames++;
        }
#ifdef PNS_TEST
        if (a->st_last > 0 && vsync - a->st_last > a->st_maxdt) a->st_maxdt = vsync - a->st_last;
        a->st_last = vsync;
        a->st_refresh++;
        a->st_frames += n;
        tm[1] = now_s();
        if (n == 0) a->st_none++;
        if (n > 1) a->st_more++;
#endif
    } else {
        pacer_restart(&a->pacer);
#ifdef PNS_TEST
        a->st_last = 0;
#endif
    }
    if (front) app_update(&g_app, t);
    if (front && g_stream) audio_tune(t);
    if (front) meter(a, t, app_running(&g_app));
    atomic_store_explicit(&g_playing, front && app_running(&g_app), memory_order_relaxed);
    /* MOTION TILT: the accelerometer read while a table or a bonus stage is played */
    bool motion = front && g_app.ui.motion && g_app.ui.field && !g_app.ui.menu_open && app_running(&g_app);
    if (motion != a->accel_on) sensors_enable(a, motion);
    if (a->tilt_buttons && (t >= a->tilt_until || !motion)) { a->tilt_buttons = 0; update_pad(a); }
#ifdef PNS_TEST
    /* test builds: commands written by tools/emu.sh into test.txt of the app's folder */
    static double next_test;
    if (front && t >= next_test && a->na->externalDataPath) {
        next_test = t + 0.25;
        char p[700], line[128];
        snprintf(p, sizeof p, "%s/test.txt", a->na->externalDataPath);
        FILE *f = fopen(p, "r");
        if (f) {
            while (fgets(line, sizeof line, f)) {
                if (strncmp(line, "pace reset", 10) == 0) {      /* the statistics from now on */
                    a->st_refresh = a->st_frames = a->st_none = a->st_more = a->st_steps = 0;
                    a->st_maxdt = 0;
                    memset(a->st_sum, 0, sizeof a->st_sum);
                    memset(a->st_max, 0, sizeof a->st_max);
                    atomic_store(&g_underruns, 0);
                    g_pads = g_flushes = 0;
                    g_pull_base = atomic_load(&g_pulled);
                    g_pull_since = t;
                } else {
                    app_test_command(&g_app, line);
                }
            }
            fclose(f);
            remove(p);
        }
        /* and what the game shows, for them to wait for a screen */
        snprintf(p, sizeof p, "%s/test_status.txt", a->na->externalDataPath);
        f = g_app.pb ? fopen(p, "w") : NULL;
        if (f) {
            fprintf(f, "screen %d stage %d playing %d frame %ld\n", pb_screen(g_app.pb), pb_stage(g_app.pb),
                    pb_playing(g_app.pb) ? 1 : 0, g_app.pb->st.frame);
            fprintf(f, "pace refresh %ld frames %ld none %ld more %ld maxdt %.1f period %.3f ratio %d/%d level %.0f underruns %ld\n",
                    a->st_refresh, a->st_frames, a->st_none, a->st_more, a->st_maxdt * 1000, a->pacer.period * 1000,
                    a->pacer.num, a->pacer.den, g_sound.level, atomic_load(&g_underruns));
            fprintf(f, "card %.0f Hz (measured %.1f, used %.1f)  sound rate %.1f  fps %.3f\n",
                    (atomic_load(&g_pulled) - g_pull_base) / (t - g_pull_since + 1e-9), g_sound.measured, g_sound.rate,
                    pacer_sound_rate(&a->pacer, g_sound.rate, g_sound.level, AUDIO_TARGET), a->pacer.fps);
            fprintf(f, "antilag late %ld finished %ld calls %ld  stale sprites %ld  hints %d target %.2f ms  sound target %.0f\n",
                    g_app.pb->stats_late, g_app.pb->stats_late_done, g_app.pb->g.call_late, g_app.pb->stats_stale_oam,
                    g_hint.s != NULL, g_hint.target / 1e6, g_sound.target);
            /* the stream: its underruns and buffer; the frames between the callback and the speaker
             * (from its timestamp); the sound's corrections */
            int64_t pos = 0, ns = 0;
            double devq = -1;
            pthread_mutex_lock(&g_audio_mutex);
            int32_t xr = g_stream ? AAudioStream_getXRunCount(g_stream) : -1, bsz = g_stream ? AAudioStream_getBufferSizeInFrames(g_stream) : 0;
            if (g_stream && AAudioStream_getTimestamp(g_stream, CLOCK_MONOTONIC, &pos, &ns) == AAUDIO_OK)
                devq = atomic_load(&g_pulled) - (pos + (t - ns * 1e-9) * AUDIO_RATE);
            pthread_mutex_unlock(&g_audio_mutex);
            fprintf(f, "stream xruns %d buffer %d burst %d device %.0f  sound level %.0f corr %+.3f%% extra %ld pads %ld flushes %ld\n",
                    (int)xr, (int)bsz, (int)g_burst, devq, g_sound.level, g_sound.corr * 100, g_sound.extra, g_pads, g_flushes);
            fprintf(f, "buttons %02X  motion %d left %ld right %ld up %ld\n", ui_buttons(&g_app.ui), a->accel_on ? 1 : 0,
                    a->motion.count[MOTION_LEFT], a->motion.count[MOTION_RIGHT], a->motion.count[MOTION_UP]);
            fprintf(f, "info %s\n", g_app.ui.info);
            static const char *const phase[5] = { "late", "emu", "prep", "draw", "swap" };
            for (int i = 0; i < 5; i++)
                fprintf(f, "%s avg %.2f max %.2f%s", phase[i], a->st_steps ? a->st_sum[i] / a->st_steps : 0.0,
                        a->st_max[i], i < 4 ? "  " : "\n");
            fclose(f);
        }
    }
#endif
    bool quit = front && g_app.quit;
    if (quit) g_app.quit = false;
    int fb = front ? app_take_haptic(&g_app) : UI_HAPTIC_NONE;
    bool rumble = front && g_app.rumble;

    /* draw: upload the game image (under the lock: the emulator writes it). With a second screen,
     * the table at its whole width (both screens are wide enough), the game's picture alone */
    dual_setting(a);
    dual_surface_init(a);
    bool dual = a->dual_surf != EGL_NO_SURFACE && !g_app.ui.single_screen;
    if (g_app.pb && pb_narrow(g_app.pb) == dual) pb_set_narrow(g_app.pb, !dual);
    int fw = 0, fh = 0, stride = 0;
    const uint32_t *px = NULL;
    if (dual) px = app_game(&g_app, &fw, &fh, &stride);
    a->dual_mode = dual_mode_now(a, px ? fh : 0);
    if (a->dual_mode == DUAL_NONE || a->dual_mode == DUAL_UI) px = app_frame(&g_app, &fw, &fh, &stride);
    if (px && a->dpy != EGL_NO_DISPLAY) gr_upload(&a->gr, px, stride, fh);
    EGLint w = 0, h = 0;
    eglQuerySurface(a->dpy, a->surf, EGL_WIDTH, &w);
    eglQuerySurface(a->dpy, a->surf, EGL_HEIGHT, &h);
    if (w > 0 && h > 0 && (w != a->w || h != a->h || g_app.ui.W != w || g_app.ui.H != h)) {
        a->w = w;
        a->h = h;
        a->insets_known = false;
        app_layout(&g_app, w, h);
    }
    if (!a->insets_known && t - a->insets_tried > 0.5 && a->w > 0) {
        /* the cut-out: asked again until the window is laid out */
        int it, ib, il, ir, rc;
        a->insets_tried = t;
        a->insets_known = query_insets(a->env, a->na->clazz, a->na->sdkVersion, &it, &ib, &il, &ir, &rc);
        if (a->insets_known) app_set_insets(&g_app, it, ib, il, ir, rc);
    }
    app_build(&g_app, &a->list);
    EGLint dw = 0, dh = 0;
    if (dual) {
        eglQuerySurface(a->dpy, a->dual_surf, EGL_WIDTH, &dw);
        eglQuerySurface(a->dpy, a->dual_surf, EGL_HEIGHT, &dh);
    }
    a->dual_list.n = 0;
    if (a->dual_mode == DUAL_TABLE) {
        /* the top half at the size of the bottom one: one table across the two screens */
        float sb = dual_game_item(&a->dual_list, dw, dh, fw, fh, PB_TOP_ROWS, fh, 0);
        dual_game_item(&a->list, a->w, a->h, fw, fh, 0, PB_TOP_ROWS, sb);
    } else if (a->dual_mode == DUAL_GAME) {
        dual_game_item(&a->list, a->w, a->h, fw, fh, 0, fh, 0);
    }
    pthread_mutex_unlock(&g_game);
    (void)ran;
#ifdef PNS_TEST
    tm[2] = now_s();
#endif

    if (quit) ANativeActivity_finish(a->na);
    if (g_app.vibration_test) { g_app.vibration_test = false; haptic_post(0, true); a->last_vibration = t; }   /* VIBRATION on */
    else if (rumble && t - a->last_vibration > 0.045) { haptic_post(0, true); a->last_vibration = t; }
    else if (fb && t - a->last_vibration > 0.03) { haptic_post(fb, false); a->last_vibration = t; }

    if (dual) {
        /* the second screen first: the main screen's swap waits for its vertical blank */
        if (eglMakeCurrent(a->dpy, a->dual_surf, a->dual_surf, a->ctx)) {
            gr_draw(&a->gr, &a->dual_list, dw, dh, fw, fh);
            if (!eglSwapBuffers(a->dpy, a->dual_surf)) LOGE("second screen: swap failed (0x%x)", eglGetError());
        }
        eglMakeCurrent(a->dpy, a->surf, a->surf, a->ctx);
    }
    gr_draw(&a->gr, &a->list, a->w, a->h, fw, fh);
    double work = now_s() - t;                  /* the swap may wait for a buffer: not work */
#ifdef PNS_TEST
    tm[3] = now_s();
#endif
    if (!eglSwapBuffers(a->dpy, a->surf)) {
        EGLint err = eglGetError();
        if (err == EGL_BAD_SURFACE || err == EGL_CONTEXT_LOST || err == EGL_BAD_NATIVE_WINDOW) {
            egl_term(a);
            if (a->window) egl_init(a);
        }
    }
    hint_report(work, a->pacer.period);
#ifdef PNS_TEST
    if (ran) {
        tm[4] = now_s();
        double d[5] = { t - vsync, tm[1] - tm[0], tm[2] - tm[1], tm[3] - tm[2], tm[4] - tm[3] };
        for (int i = 0; i < 5; i++) {
            a->st_sum[i] += d[i] * 1000;
            if (d[i] * 1000 > a->st_max[i]) a->st_max[i] = d[i] * 1000;
        }
        a->st_steps++;
    }
#endif
}

static void *game_thread(void *arg)
{
    Activity *a = (Activity *)arg;
    JavaVM *vm = a->na->vm;
    (*vm)->AttachCurrentThread(vm, &a->env, NULL);
    /* the priority of Android's own display threads (URGENT_DISPLAY, else DISPLAY): work in the
     * background of the phone does not delay a picture */
    if (setpriority(PRIO_PROCESS, (id_t)gettid(), -8) != 0) setpriority(PRIO_PROCESS, (id_t)gettid(), -4);
    pthread_setname_np(pthread_self(), "pns-game");
    hint_init();
    a->looper = ALooper_prepare(ALOOPER_PREPARE_ALLOW_NON_CALLBACKS);
    ALooper_addFd(a->looper, a->msgread, LOOPER_ID_MAIN, ALOOPER_EVENT_INPUT, NULL, NULL);
    sensors_init(a);

    pthread_mutex_lock(&g_game);
    if (!g_app_ready) {
        mkdir(a->na->internalDataPath, 0700);
        app_init(&g_app, a->na->internalDataPath, AUDIO_RATE);
        g_app_ready = true;
        start_helpers(vm);
    }
    pthread_mutex_unlock(&g_game);
    start_importer(a);
    a->choreo = vsync_init();
    LOGI("vertical blanks: %s", a->choreo ? "Choreographer" : "swaps");

    pthread_mutex_lock(&a->mutex);
    a->running = true;
    pthread_cond_broadcast(&a->cond);
    pthread_mutex_unlock(&a->mutex);

    while (!a->destroy_requested) {
        /* drawing: at each vertical blank (the Choreographer calls back through the looper), or
         * as fast as the swaps allow without it; else asleep until an event */
        bool draw = active(a) && a->dpy != EGL_NO_DISPLAY;
        if (draw) vsync_request(a);
        int timeout = !draw ? -1 : (!a->choreo || a->vsync_due) ? 0 : 50;
        int events, ident;
        void *data;
        while ((ident = ALooper_pollOnce(timeout, NULL, &events, &data)) >= 0) {
            if (ident == LOOPER_ID_MAIN) process_cmd(a);
            else if (ident == LOOPER_ID_INPUT) process_input(a);
            else if (ident == LOOPER_ID_SENSOR) process_sensors(a);
            if (a->destroy_requested) break;
            draw = active(a) && a->dpy != EGL_NO_DISPLAY;
            timeout = !draw ? -1 : (!a->choreo || a->vsync_due) ? 0 : 50;
        }
        if (a->destroy_requested) break;
        if (!(active(a) && a->dpy != EGL_NO_DISPLAY)) {
            a->vsync_due = false;
            sensors_enable(a, false);
            if (a->tilt_buttons) { a->tilt_buttons = 0; pthread_mutex_lock(&g_game); update_pad(a); pthread_mutex_unlock(&g_game); }
            continue;
        }
        if (!a->choreo) frame_step(a, now_s());
        else if (a->vsync_due) { a->vsync_due = false; frame_step(a, a->vsync_time); }
        else if (now_s() - a->last_step > 0.1) frame_step(a, now_s());   /* no vertical blank: draw anyway */
    }

    leave_front(a);
    egl_term(a);
    pthread_mutex_lock(&a->mutex);
    dual_release(a->dual_window);
    a->dual_window = a->dual_pending = NULL;
    pthread_cond_broadcast(&a->cond);
    pthread_mutex_unlock(&a->mutex);
    sensors_enable(a, false);
    if (a->sensors) ASensorManager_destroyEventQueue(a->sensor_mgr, a->sensors);
    a->sensors = NULL;
    pthread_mutex_lock(&a->mutex);
    if (a->queue) AInputQueue_detachLooper(a->queue);
    a->queue = NULL;
    a->destroyed = true;
    pthread_cond_broadcast(&a->cond);
    pthread_mutex_unlock(&a->mutex);
    (*vm)->DetachCurrentThread(vm);
    return NULL;
}

/* ------------------------------------------------------------------ activity callbacks (UI thread) */

static void wait_state(Activity *a, int8_t cmd)
{
    pthread_mutex_lock(&a->mutex);
    write_cmd(a, cmd);
    while (a->state != cmd && !a->destroyed) pthread_cond_wait(&a->cond, &a->mutex);
    pthread_mutex_unlock(&a->mutex);
}

static void on_start(ANativeActivity *na) { wait_state((Activity *)na->instance, CMD_START); }
static void on_resume(ANativeActivity *na) { set_immersive(na); wait_state((Activity *)na->instance, CMD_RESUME); dual_start(na); }
static void on_pause(ANativeActivity *na) { dual_stop(na); wait_state((Activity *)na->instance, CMD_PAUSE); }
static void on_stop(ANativeActivity *na) { wait_state((Activity *)na->instance, CMD_STOP); }

static void *on_save_state(ANativeActivity *na, size_t *len) { (void)na; *len = 0; return NULL; }

static void on_destroy(ANativeActivity *na)
{
    Activity *a = (Activity *)na->instance;
    pthread_mutex_lock(&a->mutex);
    write_cmd(a, CMD_DESTROY);
    while (!a->destroyed) pthread_cond_wait(&a->cond, &a->mutex);
    pthread_mutex_unlock(&a->mutex);
    pthread_join(a->thread, NULL);
    close(a->msgread);
    close(a->msgwrite);
    pthread_cond_destroy(&a->cond);
    pthread_mutex_destroy(&a->mutex);
    free(a);
    na->instance = NULL;
}

static void on_focus(ANativeActivity *na, int focused)
{
    if (focused) set_immersive(na);
    write_cmd((Activity *)na->instance, focused ? CMD_GAINED_FOCUS : CMD_LOST_FOCUS);
}

static void set_window(Activity *a, ANativeWindow *w)
{
    pthread_mutex_lock(&a->mutex);
    if (a->pending_window) write_cmd(a, CMD_TERM_WINDOW);
    a->pending_window = w;
    if (w) write_cmd(a, CMD_INIT_WINDOW);
    while (a->window != a->pending_window) pthread_cond_wait(&a->cond, &a->mutex);
    pthread_mutex_unlock(&a->mutex);
}

static void on_window_created(ANativeActivity *na, ANativeWindow *w) { set_window((Activity *)na->instance, w); }
static void on_window_destroyed(ANativeActivity *na, ANativeWindow *w) { (void)w; set_window((Activity *)na->instance, NULL); }

static void set_input(Activity *a, AInputQueue *q)
{
    pthread_mutex_lock(&a->mutex);
    a->pending_queue = q;
    write_cmd(a, CMD_INPUT_CHANGED);
    while (a->queue != a->pending_queue) pthread_cond_wait(&a->cond, &a->mutex);
    pthread_mutex_unlock(&a->mutex);
}

static void on_input_created(ANativeActivity *na, AInputQueue *q) { set_input((Activity *)na->instance, q); }
static void on_input_destroyed(ANativeActivity *na, AInputQueue *q) { (void)q; set_input((Activity *)na->instance, NULL); }
static void on_config(ANativeActivity *na) { write_cmd((Activity *)na->instance, CMD_CONFIG); }
static void on_low_memory(ANativeActivity *na) { (void)na; }

__attribute__((visibility("default")))
void ANativeActivity_onCreate(ANativeActivity *na, void *saved, size_t saved_size)
{
    (void)saved; (void)saved_size;
    na->callbacks->onStart = on_start;
    na->callbacks->onResume = on_resume;
    na->callbacks->onPause = on_pause;
    na->callbacks->onStop = on_stop;
    na->callbacks->onDestroy = on_destroy;
    na->callbacks->onSaveInstanceState = on_save_state;
    na->callbacks->onWindowFocusChanged = on_focus;
    na->callbacks->onNativeWindowCreated = on_window_created;
    na->callbacks->onNativeWindowDestroyed = on_window_destroyed;
    na->callbacks->onInputQueueCreated = on_input_created;
    na->callbacks->onInputQueueDestroyed = on_input_destroyed;
    na->callbacks->onConfigurationChanged = on_config;
    na->callbacks->onLowMemory = on_low_memory;

    Activity *a = (Activity *)calloc(1, sizeof(Activity));
    if (a) pacer_reset(&a->pacer);
    if (!g_sound.target) sound_reset(&g_sound, AUDIO_RATE, AUDIO_TARGET);
    a->na = na;
    a->dpy = EGL_NO_DISPLAY;
    a->surf = EGL_NO_SURFACE;
    a->ctx = EGL_NO_CONTEXT;
    a->dual_surf = EGL_NO_SURFACE;
    a->state = CMD_STOP;
    na->instance = a;
    pthread_mutex_init(&a->mutex, NULL);
    pthread_cond_init(&a->cond, NULL);
    int fds[2];
    if (pipe(fds)) { LOGE("pipe failed: %s", strerror(errno)); ANativeActivity_finish(na); return; }
    a->msgread = fds[0];
    a->msgwrite = fds[1];

    ANativeActivity_setWindowFlags(na, AWINDOW_FLAG_KEEP_SCREEN_ON | AWINDOW_FLAG_FULLSCREEN, 0);
    init_vibrator(na);
    dual_init(na);
    set_cutout_mode(na);
    set_immersive(na);

    pthread_attr_t attr;
    pthread_attr_init(&attr);
    pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_JOINABLE);
    pthread_create(&a->thread, &attr, game_thread, a);
    pthread_attr_destroy(&attr);
    pthread_mutex_lock(&a->mutex);
    while (!a->running) pthread_cond_wait(&a->cond, &a->mutex);
    pthread_mutex_unlock(&a->mutex);
}

#ifdef PB_MOCK
/* tests on Linux (tools/androidmock): access to the shared game */
MobileApp *pb_mock_app(void) { return &g_app; }
pthread_mutex_t *pb_mock_lock(void) { return &g_game; }
#endif
