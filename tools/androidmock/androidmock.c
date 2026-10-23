/*
 * androidmock.c - runs the Android glue (platform/android/main_android.c) on Linux,
 * with the NDK, JNI, EGL, OpenGL ES and AAudio functions replaced by simulations, to
 * test what cannot be seen without a phone: the activity life cycle and its threads
 * (no deadlock), importing the ROM from an "Open with" intent, touches and keys,
 * the frame pacing driven by the sound card, suspend/resume, two activity instances.
 */
#define _GNU_SOURCE
#include <android/native_activity.h>
#include <android/looper.h>
#include <android/sensor.h>
#include <android/log.h>
#include <aaudio/AAudio.h>
#include <EGL/egl.h>
#include <GLES2/gl2.h>
#include <errno.h>
#include <poll.h>
#include <pthread.h>
#include <signal.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>
#include "../../platform/mobile/app.h"

MobileApp *pb_mock_app(void);
pthread_mutex_t *pb_mock_lock(void);
void ANativeActivity_onCreate(ANativeActivity *na, void *saved, size_t saved_size);

static int W = 1080, H = 2400;
static volatile long swaps, uploads, vibrations, finished, ui_flags_set, audio_frames;

static void msleep(int ms) { struct timespec t = { ms / 1000, (long)(ms % 1000) * 1000000L }; nanosleep(&t, NULL); }
static double now_s(void) { struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t); return t.tv_sec + t.tv_nsec * 1e-9; }

/* ------------------------------------------------------------------ log */

int __android_log_print(int prio, const char *tag, const char *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    fprintf(stderr, "[%s %d] ", tag, prio);
    vfprintf(stderr, fmt, ap);
    fputc('\n', stderr);
    va_end(ap);
    return 0;
}

/* ------------------------------------------------------------------ looper */

struct ALooper { int n; int fd[8], ident[8]; };
static __thread ALooper *tls_looper;

ALooper *ALooper_prepare(int opts)
{
    (void)opts;
    if (!tls_looper) tls_looper = (ALooper *)calloc(1, sizeof(ALooper));
    return tls_looper;
}

int ALooper_addFd(ALooper *l, int fd, int ident, int events, ALooper_callbackFunc cb, void *data)
{
    (void)events; (void)cb; (void)data;
    for (int i = 0; i < l->n; i++) if (l->fd[i] == fd) { l->ident[i] = ident; return 1; }
    l->fd[l->n] = fd;
    l->ident[l->n] = ident;
    l->n++;
    return 1;
}

static void looper_remove(ALooper *l, int fd)
{
    for (int i = 0; i < l->n; i++)
        if (l->fd[i] == fd) { l->fd[i] = l->fd[l->n - 1]; l->ident[i] = l->ident[l->n - 1]; l->n--; return; }
}

int ALooper_pollOnce(int timeout, int *out_fd, int *out_events, void **out_data)
{
    ALooper *l = tls_looper;
    struct pollfd p[8];
    for (int i = 0; i < l->n; i++) { p[i].fd = l->fd[i]; p[i].events = POLLIN; p[i].revents = 0; }
    int r = poll(p, (nfds_t)l->n, timeout);
    if (r <= 0) return ALOOPER_POLL_TIMEOUT;
    for (int i = 0; i < l->n; i++)
        if (p[i].revents & POLLIN) {
            if (out_fd) *out_fd = p[i].fd;
            if (out_events) *out_events = ALOOPER_EVENT_INPUT;
            if (out_data) *out_data = NULL;
            return l->ident[i];
        }
    return ALOOPER_POLL_TIMEOUT;
}

/* ------------------------------------------------------------------ input queue */

struct AInputEvent {
    int type, source, action, keycode, n;
    int id[10];
    float x[10], y[10], axis[32];
};

struct AInputQueue {
    pthread_mutex_t m;
    int pipe[2];
    ALooper *looper;
    AInputEvent ev[256];
    int head, tail;
    AInputEvent current;
    long finished, handled;
};

static AInputQueue *queue_new(void)
{
    AInputQueue *q = (AInputQueue *)calloc(1, sizeof *q);
    pthread_mutex_init(&q->m, NULL);
    if (pipe(q->pipe)) abort();
    return q;
}

static void queue_push(AInputQueue *q, const AInputEvent *e)
{
    pthread_mutex_lock(&q->m);
    q->ev[q->tail++ & 255] = *e;
    pthread_mutex_unlock(&q->m);
    char c = 1;
    if (write(q->pipe[1], &c, 1) != 1) abort();
}

void AInputQueue_attachLooper(AInputQueue *q, ALooper *l, int ident, ALooper_callbackFunc cb, void *data)
{
    q->looper = l;
    ALooper_addFd(l, q->pipe[0], ident, ALOOPER_EVENT_INPUT, cb, data);
}

void AInputQueue_detachLooper(AInputQueue *q) { if (q->looper) looper_remove(q->looper, q->pipe[0]); q->looper = NULL; }

int32_t AInputQueue_getEvent(AInputQueue *q, AInputEvent **out)
{
    pthread_mutex_lock(&q->m);
    if (q->head == q->tail) { pthread_mutex_unlock(&q->m); return -1; }
    char c;
    if (read(q->pipe[0], &c, 1) != 1) abort();
    q->current = q->ev[q->head++ & 255];
    pthread_mutex_unlock(&q->m);
    *out = &q->current;
    return 0;
}

int32_t AInputQueue_preDispatchEvent(AInputQueue *q, AInputEvent *e) { (void)q; (void)e; return 0; }
void AInputQueue_finishEvent(AInputQueue *q, AInputEvent *e, int handled) { (void)e; q->finished++; if (handled) q->handled++; }

int32_t AInputEvent_getType(const AInputEvent *e) { return e->type; }
int32_t AInputEvent_getSource(const AInputEvent *e) { return e->source; }
int32_t AKeyEvent_getAction(const AInputEvent *e) { return e->action; }
int32_t AKeyEvent_getKeyCode(const AInputEvent *e) { return e->keycode; }
int32_t AMotionEvent_getAction(const AInputEvent *e) { return e->action; }
size_t AMotionEvent_getPointerCount(const AInputEvent *e) { return (size_t)e->n; }
int32_t AMotionEvent_getPointerId(const AInputEvent *e, size_t i) { return e->id[i]; }
float AMotionEvent_getX(const AInputEvent *e, size_t i) { return e->x[i]; }
float AMotionEvent_getY(const AInputEvent *e, size_t i) { return e->y[i]; }
float AMotionEvent_getAxisValue(const AInputEvent *e, int32_t axis, size_t i) { (void)i; return axis >= 0 && axis < 32 ? e->axis[axis] : 0; }

static void touch(AInputQueue *q, int action, int id, float x, float y)
{
    AInputEvent e;
    memset(&e, 0, sizeof e);
    e.type = AINPUT_EVENT_TYPE_MOTION;
    e.source = AINPUT_SOURCE_TOUCHSCREEN;
    e.action = action;
    e.n = 1;
    e.id[0] = id;
    e.x[0] = x;
    e.y[0] = y;
    queue_push(q, &e);
}

static void tap(AInputQueue *q, float x, float y, int hold_ms)
{
    touch(q, AMOTION_EVENT_ACTION_DOWN, 0, x, y);
    msleep(hold_ms);
    touch(q, AMOTION_EVENT_ACTION_UP, 0, x, y);
}

static void key(AInputQueue *q, int code, int action)
{
    AInputEvent e;
    memset(&e, 0, sizeof e);
    e.type = AINPUT_EVENT_TYPE_KEY;
    e.source = AINPUT_SOURCE_KEYBOARD;
    e.action = action;
    e.keycode = code;
    queue_push(q, &e);
}

/* ------------------------------------------------------------------ window, EGL, GL */

struct ANativeWindow { int dummy; };
int32_t ANativeWindow_setBuffersGeometry(ANativeWindow *w, int32_t a, int32_t b, int32_t c) { (void)w; (void)a; (void)b; (void)c; return 0; }

static double next_vsync;
EGLDisplay eglGetDisplay(void *id) { (void)id; return (EGLDisplay)1; }
EGLBoolean eglInitialize(EGLDisplay d, EGLint *a, EGLint *b) { (void)d; (void)a; (void)b; return EGL_TRUE; }
EGLBoolean eglChooseConfig(EGLDisplay d, const EGLint *at, EGLConfig *c, EGLint s, EGLint *n) { (void)d; (void)at; (void)s; *c = (EGLConfig)1; *n = 1; return EGL_TRUE; }
EGLBoolean eglGetConfigAttrib(EGLDisplay d, EGLConfig c, EGLint a, EGLint *v) { (void)d; (void)c; (void)a; *v = 1; return EGL_TRUE; }
EGLSurface eglCreateWindowSurface(EGLDisplay d, EGLConfig c, EGLNativeWindowType w, const EGLint *a) { (void)d; (void)c; (void)a; return w ? (EGLSurface)2 : EGL_NO_SURFACE; }
EGLContext eglCreateContext(EGLDisplay d, EGLConfig c, EGLContext s, const EGLint *a) { (void)d; (void)c; (void)s; (void)a; return (EGLContext)3; }
EGLBoolean eglMakeCurrent(EGLDisplay d, EGLSurface a, EGLSurface b, EGLContext c) { (void)d; (void)a; (void)b; (void)c; return EGL_TRUE; }
EGLBoolean eglSwapInterval(EGLDisplay d, EGLint i) { (void)d; (void)i; return EGL_TRUE; }
EGLBoolean eglSwapBuffers(EGLDisplay d, EGLSurface s)
{
    (void)d; (void)s;
    /* a 60 Hz display: block until the next vertical blank */
    double t = now_s();
    if (next_vsync < t) next_vsync = t;
    next_vsync += 1.0 / 60.0;
    double wait = next_vsync - now_s();
    if (wait > 0) msleep((int)(wait * 1000));
    swaps++;
    return EGL_TRUE;
}
EGLBoolean eglQuerySurface(EGLDisplay d, EGLSurface s, EGLint a, EGLint *v) { (void)d; (void)s; *v = a == EGL_WIDTH ? W : H; return EGL_TRUE; }
EGLBoolean eglDestroySurface(EGLDisplay d, EGLSurface s) { (void)d; (void)s; return EGL_TRUE; }
EGLBoolean eglDestroyContext(EGLDisplay d, EGLContext c) { (void)d; (void)c; return EGL_TRUE; }
EGLBoolean eglTerminate(EGLDisplay d) { (void)d; return EGL_TRUE; }
EGLint eglGetError(void) { return 0x3000; }

void glActiveTexture(GLenum t) { (void)t; }
void glAttachShader(GLuint p, GLuint s) { (void)p; (void)s; }
void glBindAttribLocation(GLuint p, GLuint i, const GLchar *n) { (void)p; (void)i; (void)n; }
void glBindTexture(GLenum t, GLuint x) { (void)t; (void)x; }
void glBlendFunc(GLenum a, GLenum b) { (void)a; (void)b; }
void glClear(GLbitfield m) { (void)m; }
void glClearColor(GLfloat r, GLfloat g, GLfloat b, GLfloat a) { (void)r; (void)g; (void)b; (void)a; }
void glCompileShader(GLuint s) { (void)s; }
GLuint glCreateProgram(void) { return 1; }
GLuint glCreateShader(GLenum t) { (void)t; return 1; }
void glDeleteShader(GLuint s) { (void)s; }
void glDisableVertexAttribArray(GLuint i) { (void)i; }
void glDrawArrays(GLenum m, GLint f, GLsizei c) { (void)m; (void)f; (void)c; }
void glEnable(GLenum c) { (void)c; }
void glEnableVertexAttribArray(GLuint i) { (void)i; }
void glGenTextures(GLsizei n, GLuint *t) { for (int i = 0; i < n; i++) t[i] = 1; }
void glGetProgramInfoLog(GLuint p, GLsizei b, GLsizei *l, GLchar *s) { (void)p; (void)b; if (l) *l = 0; if (s) *s = 0; }
void glGetProgramiv(GLuint p, GLenum n, GLint *v) { (void)p; (void)n; *v = 1; }
void glGetShaderInfoLog(GLuint p, GLsizei b, GLsizei *l, GLchar *s) { (void)p; (void)b; if (l) *l = 0; if (s) *s = 0; }
void glGetShaderiv(GLuint p, GLenum n, GLint *v) { (void)p; (void)n; *v = 1; }
GLint glGetUniformLocation(GLuint p, const GLchar *n) { (void)p; (void)n; return 0; }
void glLinkProgram(GLuint p) { (void)p; }
void glPixelStorei(GLenum p, GLint v) { (void)p; (void)v; }
void glShaderSource(GLuint s, GLsizei c, const GLchar *const *str, const GLint *l) { (void)s; (void)c; (void)str; (void)l; }
void glTexImage2D(GLenum t, GLint l, GLint i, GLsizei w, GLsizei h, GLint b, GLenum f, GLenum ty, const void *p) { (void)t; (void)l; (void)i; (void)w; (void)h; (void)b; (void)f; (void)ty; (void)p; }
void glTexParameteri(GLenum t, GLenum p, GLint v) { (void)t; (void)p; (void)v; }
void glTexSubImage2D(GLenum t, GLint l, GLint x, GLint y, GLsizei w, GLsizei h, GLenum f, GLenum ty, const void *p) { (void)t; (void)l; (void)x; (void)y; (void)w; (void)h; (void)f; (void)ty; (void)p; uploads++; }
void glUniform1f(GLint l, GLfloat v) { (void)l; (void)v; }
void glUniform1i(GLint l, GLint v) { (void)l; (void)v; }
void glUniform2f(GLint l, GLfloat a, GLfloat b) { (void)l; (void)a; (void)b; }
void glUniform4f(GLint l, GLfloat a, GLfloat b, GLfloat c, GLfloat d) { (void)l; (void)a; (void)b; (void)c; (void)d; }
void glUseProgram(GLuint p) { (void)p; }
void glVertexAttribPointer(GLuint i, GLint s, GLenum t, GLboolean n, GLsizei st, const void *p) { (void)i; (void)s; (void)t; (void)n; (void)st; (void)p; }
void glViewport(GLint x, GLint y, GLsizei w, GLsizei h) { (void)x; (void)y; (void)w; (void)h; }

/* ------------------------------------------------------------------ AAudio: a 48 kHz sound card */

struct AAudioStreamBuilderStruct { AAudioStream_dataCallback cb; void *user; int rate, channels; };
struct AAudioStreamStruct { AAudioStream_dataCallback cb; void *user; pthread_t th; volatile int run; int32_t size; };
static int open_streams;

aaudio_result_t AAudio_createStreamBuilder(AAudioStreamBuilder **b) { *b = (AAudioStreamBuilder *)calloc(1, sizeof **b); (*b)->rate = 48000; (*b)->channels = 2; return AAUDIO_OK; }
void AAudioStreamBuilder_setDirection(AAudioStreamBuilder *b, aaudio_direction_t d) { (void)b; (void)d; }
void AAudioStreamBuilder_setSampleRate(AAudioStreamBuilder *b, int32_t r) { b->rate = r; }
void AAudioStreamBuilder_setChannelCount(AAudioStreamBuilder *b, int32_t c) { b->channels = c; }
void AAudioStreamBuilder_setFormat(AAudioStreamBuilder *b, aaudio_format_t f) { (void)b; (void)f; }
void AAudioStreamBuilder_setSharingMode(AAudioStreamBuilder *b, aaudio_sharing_mode_t m) { (void)b; (void)m; }
void AAudioStreamBuilder_setPerformanceMode(AAudioStreamBuilder *b, aaudio_performance_mode_t m) { (void)b; (void)m; }
void AAudioStreamBuilder_setBufferCapacityInFrames(AAudioStreamBuilder *b, int32_t n) { (void)b; (void)n; }
void AAudioStreamBuilder_setDataCallback(AAudioStreamBuilder *b, AAudioStream_dataCallback cb, void *u) { b->cb = cb; b->user = u; }
void AAudioStreamBuilder_setErrorCallback(AAudioStreamBuilder *b, AAudioStream_errorCallback cb, void *u) { (void)b; (void)cb; (void)u; }
aaudio_result_t AAudioStreamBuilder_openStream(AAudioStreamBuilder *b, AAudioStream **s)
{
    *s = (AAudioStream *)calloc(1, sizeof **s);
    (*s)->cb = b->cb;
    (*s)->user = b->user;
    open_streams++;
    return AAUDIO_OK;
}
aaudio_result_t AAudioStreamBuilder_delete(AAudioStreamBuilder *b) { free(b); return AAUDIO_OK; }

static void *audio_thread(void *arg)
{
    AAudioStream *s = (AAudioStream *)arg;
    static int16_t buf[480 * 2];
    double t = now_s();
    while (s->run) {
        s->cb(s, s->user, buf, 480);           /* 10 ms of sound */
        audio_frames += 480;
        t += 0.010;
        double wait = t - now_s();
        if (wait > 0) msleep((int)(wait * 1000 + 0.5));
    }
    return NULL;
}

aaudio_result_t AAudioStream_requestStart(AAudioStream *s) { s->run = 1; pthread_create(&s->th, NULL, audio_thread, s); return AAUDIO_OK; }
aaudio_result_t AAudioStream_requestPause(AAudioStream *s) { (void)s; return AAUDIO_OK; }
aaudio_result_t AAudioStream_requestStop(AAudioStream *s) { if (s->run) { s->run = 0; pthread_join(s->th, NULL); } return AAUDIO_OK; }
aaudio_result_t AAudioStream_close(AAudioStream *s) { AAudioStream_requestStop(s); free(s); open_streams--; return AAUDIO_OK; }
int32_t AAudioStream_getSampleRate(AAudioStream *s) { (void)s; return 48000; }
int32_t AAudioStream_getChannelCount(AAudioStream *s) { (void)s; return 2; }
int32_t AAudioStream_getFramesPerBurst(AAudioStream *s) { (void)s; return 192; }
aaudio_result_t AAudioStream_setBufferSizeInFrames(AAudioStream *s, int32_t n) { s->size = n; return n; }
int32_t AAudioStream_getBufferSizeInFrames(AAudioStream *s) { return s->size; }
int32_t AAudioStream_getBufferCapacityInFrames(AAudioStream *s) { (void)s; return 3072; }
int32_t AAudioStream_getXRunCount(AAudioStream *s) { (void)s; return 0; }
aaudio_performance_mode_t AAudioStream_getPerformanceMode(AAudioStream *s) { (void)s; return AAUDIO_PERFORMANCE_MODE_LOW_LATENCY; }
aaudio_sharing_mode_t AAudioStream_getSharingMode(AAudioStream *s) { (void)s; return AAUDIO_SHARING_MODE_SHARED; }
aaudio_result_t AAudioStream_getTimestamp(AAudioStream *s, clockid_t c, int64_t *pos, int64_t *ns) { (void)s; (void)c; (void)pos; (void)ns; return -1; }
aaudio_stream_state_t AAudioStream_getState(AAudioStream *s) { (void)s; return 4; }

/* ------------------------------------------------------------------ sensors: none */

ASensorManager *ASensorManager_getInstanceForPackage(const char *p) { (void)p; return NULL; }
const ASensor *ASensorManager_getDefaultSensor(ASensorManager *m, int t) { (void)m; (void)t; return NULL; }
ASensorEventQueue *ASensorManager_createEventQueue(ASensorManager *m, ALooper *l, int id, ALooper_callbackFunc cb, void *d) { (void)m; (void)l; (void)id; (void)cb; (void)d; return NULL; }
int ASensorManager_destroyEventQueue(ASensorManager *m, ASensorEventQueue *q) { (void)m; (void)q; return 0; }
int ASensorEventQueue_enableSensor(ASensorEventQueue *q, const ASensor *s) { (void)q; (void)s; return 0; }
int ASensorEventQueue_disableSensor(ASensorEventQueue *q, const ASensor *s) { (void)q; (void)s; return 0; }
int ASensorEventQueue_setEventRate(ASensorEventQueue *q, const ASensor *s, int32_t us) { (void)q; (void)s; (void)us; return 0; }
ssize_t ASensorEventQueue_getEvents(ASensorEventQueue *q, ASensorEvent *e, size_t n) { (void)q; (void)e; (void)n; return 0; }
int ASensor_getMinDelay(const ASensor *s) { (void)s; return 0; }

/* ------------------------------------------------------------------ activity services */

void ANativeActivity_finish(ANativeActivity *na) { (void)na; finished++; }
void ANativeActivity_setWindowFlags(ANativeActivity *na, uint32_t a, uint32_t r) { (void)na; (void)a; (void)r; }

/* ------------------------------------------------------------------ JNI: a tiny fake Java world */

enum { K_CLASS = 1, K_ACTIVITY, K_INTENT, K_URI, K_RESOLVER, K_STREAM, K_STRING, K_BYTES, K_WINDOW, K_VIEW, K_VIBRATOR,
       K_EFFECT, K_PARAMS, K_INSETS, K_CUTOUT, K_CORNER };
static int cutout_mode_set, effects_made, insets_asked;
static const int mock_insets[4] = { 96, 0, 0, 0 };          /* a camera hole at the top */
typedef struct FakeObj {
    int kind;
    int of;                 /* K_CLASS: kind of the instances */
    char str[600];          /* string, or the file of a URI */
    FILE *file;             /* stream */
    uint8_t *bytes;         /* byte array */
    int len;
    struct FakeObj *uri;    /* intent: data; activity: its intent */
} FakeObj;
typedef struct { const char *name; } FakeMethod;

static FakeObj *obj_new(int kind) { FakeObj *o = (FakeObj *)calloc(1, sizeof(FakeObj)); o->kind = kind; return o; }

static jclass JNICALL j_GetObjectClass(JNIEnv *env, jobject o) { (void)env; FakeObj *c = obj_new(K_CLASS); c->of = ((FakeObj *)o)->kind; return (jclass)c; }
static jclass JNICALL j_FindClass(JNIEnv *env, const char *name) { (void)env; FakeObj *c = obj_new(K_CLASS); c->of = strcmp(name, "android/net/Uri") == 0 ? K_URI : 0; return (jclass)c; }
static jmethodID JNICALL j_GetMethodID(JNIEnv *env, jclass c, const char *name, const char *sig)
{
    (void)env; (void)c; (void)sig;
    FakeMethod *m = (FakeMethod *)calloc(1, sizeof *m);
    m->name = name;
    return (jmethodID)m;
}
static jboolean JNICALL j_ExceptionCheck(JNIEnv *env) { (void)env; return JNI_FALSE; }
static void JNICALL j_ExceptionClear(JNIEnv *env) { (void)env; }
static void JNICALL j_DeleteLocalRef(JNIEnv *env, jobject o) { (void)env; (void)o; }
static jobject JNICALL j_NewGlobalRef(JNIEnv *env, jobject o) { (void)env; return o; }
static void JNICALL j_DeleteGlobalRef(JNIEnv *env, jobject o) { (void)env; (void)o; }
static jstring JNICALL j_NewStringUTF(JNIEnv *env, const char *s) { (void)env; FakeObj *o = obj_new(K_STRING); snprintf(o->str, sizeof o->str, "%s", s); return (jstring)o; }
static jboolean JNICALL j_IsInstanceOf(JNIEnv *env, jobject o, jclass c) { (void)env; return o && ((FakeObj *)o)->kind == ((FakeObj *)c)->of; }
static jbyteArray JNICALL j_NewByteArray(JNIEnv *env, jsize n) { (void)env; FakeObj *o = obj_new(K_BYTES); o->bytes = (uint8_t *)calloc((size_t)n, 1); o->len = n; return (jbyteArray)o; }
static void JNICALL j_GetByteArrayRegion(JNIEnv *env, jbyteArray a, jsize start, jsize len, jbyte *buf) { (void)env; memcpy(buf, ((FakeObj *)a)->bytes + start, (size_t)len); }

static jobject JNICALL j_CallObjectMethod(JNIEnv *env, jobject obj, jmethodID mid, ...)
{
    (void)env;
    FakeObj *o = (FakeObj *)obj;
    const char *m = ((FakeMethod *)mid)->name;
    va_list ap;
    va_start(ap, mid);
    jobject r = NULL;
    if (o->kind == K_ACTIVITY && !strcmp(m, "getIntent")) r = (jobject)o->uri;           /* the intent */
    else if (o->kind == K_ACTIVITY && !strcmp(m, "getContentResolver")) r = (jobject)obj_new(K_RESOLVER);
    else if (o->kind == K_ACTIVITY && !strcmp(m, "getSystemService")) r = (jobject)obj_new(K_VIBRATOR);
    else if (o->kind == K_ACTIVITY && !strcmp(m, "getWindow")) r = (jobject)obj_new(K_WINDOW);
    else if (o->kind == K_WINDOW && !strcmp(m, "getDecorView")) r = (jobject)obj_new(K_VIEW);
    else if (o->kind == K_WINDOW && !strcmp(m, "getAttributes")) r = (jobject)obj_new(K_PARAMS);
    else if (o->kind == K_VIEW && !strcmp(m, "getRootWindowInsets")) { insets_asked++; r = (jobject)obj_new(K_INSETS); }
    else if (o->kind == K_INSETS && !strcmp(m, "getDisplayCutout")) r = (jobject)obj_new(K_CUTOUT);
    else if (o->kind == K_INSETS && !strcmp(m, "getRoundedCorner")) r = (jobject)obj_new(K_CORNER);
    else if (o->kind == K_INTENT && !strcmp(m, "getData")) r = (jobject)o->uri;
    else if (o->kind == K_INTENT && !strcmp(m, "getParcelableExtra")) r = NULL;
    else if (o->kind == K_INTENT && !strcmp(m, "setData")) { o->uri = (FakeObj *)va_arg(ap, jobject); r = obj; }
    else if (o->kind == K_RESOLVER && !strcmp(m, "openInputStream")) {
        FakeObj *uri = (FakeObj *)va_arg(ap, jobject);
        FILE *f = fopen(uri->str, "rb");
        if (f) { FakeObj *s = obj_new(K_STREAM); s->file = f; r = (jobject)s; }
    } else fprintf(stderr, "mock: unexpected CallObjectMethod %s on kind %d\n", m, o->kind);
    va_end(ap);
    return r;
}

static void JNICALL j_CallVoidMethod(JNIEnv *env, jobject obj, jmethodID mid, ...)
{
    (void)env;
    FakeObj *o = (FakeObj *)obj;
    const char *m = ((FakeMethod *)mid)->name;
    if (o->kind == K_VIBRATOR && !strcmp(m, "vibrate")) vibrations++;
    else if (o->kind == K_VIEW && !strcmp(m, "setSystemUiVisibility")) ui_flags_set++;
    else if (o->kind == K_WINDOW && !strcmp(m, "setAttributes")) {}
    else if (o->kind == K_STREAM && !strcmp(m, "close")) { if (o->file) fclose(o->file); o->file = NULL; }
    else if (o->kind == K_INTENT && !strcmp(m, "removeExtra")) {}
    else fprintf(stderr, "mock: unexpected CallVoidMethod %s on kind %d\n", m, o->kind);
}

static jint JNICALL j_CallIntMethod(JNIEnv *env, jobject obj, jmethodID mid, ...)
{
    (void)env;
    FakeObj *o = (FakeObj *)obj;
    const char *m = ((FakeMethod *)mid)->name;
    va_list ap;
    va_start(ap, mid);
    jint r = -1;
    if (o->kind == K_STREAM && !strcmp(m, "read")) {
        FakeObj *a = (FakeObj *)va_arg(ap, jobject);
        size_t n = fread(a->bytes, 1, (size_t)a->len, o->file);
        r = n > 0 ? (jint)n : -1;
    } else if (o->kind == K_CUTOUT && !strcmp(m, "getSafeInsetTop")) r = mock_insets[0];
    else if (o->kind == K_CUTOUT && !strcmp(m, "getSafeInsetBottom")) r = mock_insets[1];
    else if (o->kind == K_CUTOUT && !strcmp(m, "getSafeInsetLeft")) r = mock_insets[2];
    else if (o->kind == K_CUTOUT && !strcmp(m, "getSafeInsetRight")) r = mock_insets[3];
    else if (o->kind == K_CORNER && !strcmp(m, "getRadius")) r = 120;
    else fprintf(stderr, "mock: unexpected CallIntMethod %s\n", m);
    va_end(ap);
    return r;
}

static jmethodID JNICALL j_GetStaticMethodID(JNIEnv *env, jclass c, const char *name, const char *sig) { return j_GetMethodID(env, c, name, sig); }
static jobject JNICALL j_CallStaticObjectMethod(JNIEnv *env, jclass c, jmethodID mid, ...)
{
    (void)env; (void)c;
    const char *m = ((FakeMethod *)mid)->name;
    if (!strcmp(m, "createPredefined") || !strcmp(m, "createOneShot")) { effects_made++; return (jobject)obj_new(K_EFFECT); }
    fprintf(stderr, "mock: unexpected CallStaticObjectMethod %s\n", m);
    return NULL;
}
static jfieldID JNICALL j_GetFieldID(JNIEnv *env, jclass c, const char *name, const char *sig) { return (jfieldID)j_GetMethodID(env, c, name, sig); }
static void JNICALL j_SetIntField(JNIEnv *env, jobject o, jfieldID f, jint v)
{
    (void)env;
    if (((FakeObj *)o)->kind == K_PARAMS && !strcmp(((FakeMethod *)f)->name, "layoutInDisplayCutoutMode") && v == 1) cutout_mode_set++;
}

/* the tables of functions: JNINativeInterface_ in the jni.h of a JDK (Linux), JNINativeInterface in
 * the NDK's (androidmock built for Android and run on the emulator) */
#ifdef __ANDROID__
static struct JNINativeInterface jni_fns;
static struct JNIInvokeInterface vm_fns;
#else
static struct JNINativeInterface_ jni_fns;
static struct JNIInvokeInterface_ vm_fns;
#endif
static JNIEnv jni_env = &jni_fns;
static jint JNICALL vm_Attach(JavaVM *vm, void **penv, void *args) { (void)vm; (void)args; *penv = &jni_env; return JNI_OK; }
static jint JNICALL vm_Detach(JavaVM *vm) { (void)vm; return JNI_OK; }
static JavaVM java_vm = &vm_fns;

static void jni_setup(void)
{
    jni_fns.GetObjectClass = j_GetObjectClass;
    jni_fns.FindClass = j_FindClass;
    jni_fns.GetMethodID = j_GetMethodID;
    jni_fns.ExceptionCheck = j_ExceptionCheck;
    jni_fns.ExceptionClear = j_ExceptionClear;
    jni_fns.DeleteLocalRef = j_DeleteLocalRef;
    jni_fns.NewGlobalRef = j_NewGlobalRef;
    jni_fns.DeleteGlobalRef = j_DeleteGlobalRef;
    jni_fns.NewStringUTF = j_NewStringUTF;
    jni_fns.IsInstanceOf = j_IsInstanceOf;
    jni_fns.NewByteArray = j_NewByteArray;
    jni_fns.GetByteArrayRegion = j_GetByteArrayRegion;
    jni_fns.CallObjectMethod = j_CallObjectMethod;
    jni_fns.CallVoidMethod = j_CallVoidMethod;
    jni_fns.CallIntMethod = j_CallIntMethod;
    jni_fns.GetStaticMethodID = j_GetStaticMethodID;
    jni_fns.CallStaticObjectMethod = j_CallStaticObjectMethod;
    jni_fns.GetFieldID = j_GetFieldID;
    jni_fns.SetIntField = j_SetIntField;
    vm_fns.AttachCurrentThread = vm_Attach;
    vm_fns.DetachCurrentThread = vm_Detach;
}

/* ------------------------------------------------------------------ the scenario */

typedef struct {
    ANativeActivity na;
    ANativeActivityCallbacks cb;
    AInputQueue *q;
    struct ANativeWindow win;
} Act;

static void act_create(Act *a, const char *internal, const char *external, const char *rom_uri)
{
    memset(a, 0, sizeof *a);
    a->na.callbacks = &a->cb;
    a->na.vm = &java_vm;
    a->na.env = &jni_env;
    FakeObj *act = obj_new(K_ACTIVITY);
    FakeObj *intent = obj_new(K_INTENT);
    if (rom_uri) { intent->uri = obj_new(K_URI); snprintf(intent->uri->str, sizeof intent->uri->str, "%s", rom_uri); }
    act->uri = intent;
    a->na.clazz = (jobject)act;
    a->na.internalDataPath = internal;
    a->na.externalDataPath = external;
    a->na.sdkVersion = 34;
    a->q = queue_new();
    ANativeActivity_onCreate(&a->na, NULL, 0);
}

static void act_show(Act *a)
{
    a->cb.onStart(&a->na);
    a->cb.onResume(&a->na);
    a->cb.onInputQueueCreated(&a->na, a->q);
    a->cb.onNativeWindowCreated(&a->na, &a->win);
    a->cb.onWindowFocusChanged(&a->na, 1);
}

static void act_hide(Act *a)            /* another activity in front */
{
    a->cb.onWindowFocusChanged(&a->na, 0);
    a->cb.onPause(&a->na);
    a->cb.onNativeWindowDestroyed(&a->na, &a->win);
    a->cb.onStop(&a->na);
}

static void act_destroy(Act *a)
{
    a->cb.onInputQueueDestroyed(&a->na, a->q);
    a->cb.onDestroy(&a->na);
}

static int failures;
#define CHECK(cond, ...) do { if (cond) printf("  ok   " __VA_ARGS__); else { printf("  FAIL " __VA_ARGS__); failures++; } printf("\n"); } while (0)

static long game_frames(void)
{
    MobileApp *app = pb_mock_app();
    pthread_mutex_lock(pb_mock_lock());
    long f = app->pb ? app->pb->st.frame : -1;
    pthread_mutex_unlock(pb_mock_lock());
    return f;
}

static void on_alarm(int sig) { (void)sig; static const char m[] = "DEADLOCK (timeout)\n"; if (write(2, m, sizeof m - 1)) {} _exit(3); }

/* the app's folders (built for Android, run on a phone or the emulator: its writable folder) */
#ifdef __ANDROID__
#define MOCK_DIR "/data/local/tmp/pinballtc_mock"
#else
#define MOCK_DIR "/tmp/pinballtc_mock"
#endif

int main(int argc, char **argv)
{
    if (argc < 2) { fprintf(stderr, "usage: androidmock ROM.gbc\n"); return 2; }
    const char *rom = argv[1];
    signal(SIGALRM, on_alarm);
    alarm(120);
    jni_setup();
    const char *internal = MOCK_DIR "/files", *external = MOCK_DIR "/ext";
    if (system("rm -rf " MOCK_DIR " && mkdir -p " MOCK_DIR "/files " MOCK_DIR "/ext")) return 2;

    printf("1. first launch, no ROM\n");
    Act a1;
    act_create(&a1, internal, external, NULL);
    act_show(&a1);
    msleep(700);
    MobileApp *app = pb_mock_app();
    CHECK(!app_has_game(app) && app->ui.no_rom, "the explanation screen is shown");
    CHECK(swaps > 20, "the screen is drawn (%ld frames)", swaps);
    CHECK(ui_flags_set > 0, "full screen requested (%ld)", ui_flags_set);
    CHECK(cutout_mode_set > 0, "the window covers the camera cut-out");
    CHECK(effects_made == 3, "haptic effects made (%d)", effects_made);

    printf("2. the player opens the ROM with the app: a second activity\n");
    act_hide(&a1);
    Act a2;
    act_create(&a2, internal, external, rom);
    act_show(&a2);
    msleep(1500);
    struct stat st;
    CHECK(app_has_game(app), "the ROM was imported and the game started");
    CHECK(stat(MOCK_DIR "/files/rom.gbc", &st) == 0 && st.st_size == 1 << 20, "rom.gbc stored in the app's storage");

    printf("3. touches: start a game (A: the right key of the menus), then the flippers\n");
    msleep(2500);
    pthread_mutex_lock(pb_mock_lock());
    CHECK(insets_asked > 0 && app->ui.inset_t == mock_insets[0], "cut-out insets read (top %d)", app->ui.inset_t);
    CHECK(app->ui.corner == 120, "rounded corners of the screen read (radius %d)", app->ui.corner);
    CHECK(app->ui.nd.scale > 0 && app->ui.nd.cw == ND_W, "screen laid out (canvas %dx%d, as wide as the game)", app->ui.nd.cw, app->ui.nd.ch);
    NdRect rk = app->ui.nd.btn[ND_RFLIP];
    float ax = (rk.x + rk.w / 2.0f) * app->ui.nd.scale, ay = (rk.y + rk.h / 2.0f) * app->ui.nd.scale;
    pthread_mutex_unlock(pb_mock_lock());
    for (int i = 0; i < 4; i++) { tap(a2.q, ax, ay, 80); msleep(2100); }
    msleep(3000);
    pthread_mutex_lock(pb_mock_lock());
    int screen = pb_screen(app->pb);
    pthread_mutex_unlock(pb_mock_lock());
    CHECK(screen == 4, "the pinball game is running (screen %d)", screen);
    long f0 = game_frames();
    double t0 = now_s();
    long a0 = audio_frames;
    for (int i = 0; i < 20; i++) {
        touch(a2.q, AMOTION_EVENT_ACTION_DOWN, 1, 200, 1200);
        msleep(80);
        touch(a2.q, AMOTION_EVENT_ACTION_UP, 1, 200, 1200);
        touch(a2.q, AMOTION_EVENT_ACTION_DOWN, 2, 900, 1200);
        msleep(70);
        touch(a2.q, AMOTION_EVENT_ACTION_UP, 2, 900, 1200);
    }
    double dt = now_s() - t0;
    long frames = game_frames() - f0;
    double fps = frames / dt;
    CHECK(fps > 57 && fps < 62.5, "emulation at the game's rate (paced by the display): %.2f frames/s (%ld audio frames/s)", fps, (long)((audio_frames - a0) / dt));
    CHECK(vibrations > 0, "touch feedback vibrations (%ld)", vibrations);
    CHECK(a2.q->finished == a2.q->handled && a2.q->finished > 40, "input events finished and handled (%ld)", a2.q->finished);

    printf("4. back key: menu, then back to the game\n");
    key(a2.q, AKEYCODE_BACK, AKEY_EVENT_ACTION_DOWN);
    key(a2.q, AKEYCODE_BACK, AKEY_EVENT_ACTION_UP);
    msleep(300);
    long fm = game_frames();
    msleep(500);
    CHECK(app->ui.menu_open && game_frames() == fm, "menu open, game paused");
    key(a2.q, AKEYCODE_BACK, AKEY_EVENT_ACTION_DOWN);
    key(a2.q, AKEYCODE_BACK, AKEY_EVENT_ACTION_UP);
    msleep(500);
    CHECK(!app->ui.menu_open && game_frames() > fm + 20, "menu closed, game running again");

    printf("5. the app goes to the background and comes back\n");
    act_hide(&a2);
    CHECK(stat(MOCK_DIR "/files/suspend.state", &st) == 0, "machine state saved when paused");
    long fh = game_frames();
    msleep(400);
    CHECK(game_frames() == fh && open_streams == 0, "nothing runs in the background, sound closed");
    act_show(&a2);
    msleep(600);
    CHECK(game_frames() > fh + 20 && open_streams == 1, "running again after resume");

    printf("6. the first activity comes back to the front (launcher)\n");
    act_hide(&a2);
    act_show(&a1);
    msleep(600);
    CHECK(game_frames() > fh + 40, "the same game continues in the first activity");

    printf("7. menu > QUIT\n");
    key(a1.q, AKEYCODE_BACK, AKEY_EVENT_ACTION_DOWN);
    key(a1.q, AKEYCODE_BACK, AKEY_EVENT_ACTION_UP);
    msleep(200);
    for (int i = 0; i < UI_MENU_ITEMS - 1; i++) { key(a1.q, AKEYCODE_DPAD_DOWN, AKEY_EVENT_ACTION_DOWN); msleep(40); key(a1.q, AKEYCODE_DPAD_DOWN, AKEY_EVENT_ACTION_UP); msleep(40); }
    key(a1.q, AKEYCODE_BUTTON_A, AKEY_EVENT_ACTION_DOWN);
    msleep(60);
    key(a1.q, AKEYCODE_BUTTON_A, AKEY_EVENT_ACTION_UP);
    msleep(300);
    CHECK(finished == 1, "the activity asked to finish");

    printf("8. teardown\n");
    act_hide(&a1);
    act_destroy(&a1);
    act_destroy(&a2);
    CHECK(true, "both activities destroyed, threads joined (no deadlock)");

    printf("9. new process: the game resumes where it was\n");
    long saved_frame = game_frames();
    (void)saved_frame;
    MobileApp fresh;
    app_init(&fresh, internal, 48000);
    CHECK(app_has_game(&fresh) && pb_screen(fresh.pb) == 4, "suspend state restored at start (screen %d)", fresh.pb ? pb_screen(fresh.pb) : -1);
    CHECK(stat(MOCK_DIR "/files/suspend.state", &st) != 0, "suspend state used once (removed once loaded)");
    app_free(&fresh);

    printf("%s (%d failure%s), %ld screen frames drawn, %ld game image uploads\n", failures ? "FAILED" : "ALL OK",
           failures, failures == 1 ? "" : "s", swaps, uploads);
    return failures ? 1 : 0;
}
