/*
 * main_linux.c - Linux front-end of Pinball NS (Pokemon Pinball, the whole table on one screen).
 *
 * Xlib (MIT-SHM when the X server has it; Wayland desktops run it through XWayland), ALSA, the
 * gamepads through evdev (/dev/input/event*, their vibration through force feedback). What the
 * desktop versions share (the game, its saves, the settings and controls, the pictures, the function
 * keys: as on Windows) is platform/desktop/desk.c; this file is the window, the sound, the keys, the
 * mouse and the gamepads. The pages of F1 (about) and F2 (the controls) are drawn in the window.
 *
 * The ROM: on the command line, the last one played, one next to the program, chosen in a file
 * dialog (zenity or kdialog, when there is one), or dropped onto the window. The settings are in
 * $XDG_CONFIG_HOME/pinball-ns/pinball_ns.cfg (~/.config); the cartridge save and the saved state next
 * to the ROM, as on Windows.
 *
 * Test: pinball-ns -selftest SECONDS ROM REPORT [PICTURE.png] plays SECONDS seconds (the sound
 * silent, A pressed now and then), then writes the pace it kept in REPORT and what the window showed
 * in PICTURE (read back from the X server).
 */
/* POSIX and BSD, not _GNU_SOURCE: with it, glibc 2.38 makes strtol its C23 version (__isoc23_strtol), and the
 * program would need it (glibc 2.34 is enough without) */
#ifndef _DEFAULT_SOURCE
#define _DEFAULT_SOURCE
#endif
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/Xatom.h>
#include <X11/XKBlib.h>
#include <X11/keysym.h>
#include <X11/extensions/XShm.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#include <alsa/asoundlib.h>
#include <linux/input.h>
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>
#include "../desktop/desk.h"
#include "../../src/front/pacing.h"
#include "../../tools/png_write.h"

#define APP_TITLE    "Pinball NS"
#define AUDIO_RATE   DESK_RATE
#define AUDIO_TARGET 2048             /* frames kept ahead of the sound card (~43 ms) */
#define ALSA_BUFFER  8192             /* the card's buffer (frames) */
#define STAGE_FRAMES 8192

static Desk D;
static bool running = true;

static double now_s(void)
{
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec + t.tv_nsec * 1e-9;
}

/* ------------------------------------------------------------------ window */

static Display *dpy;
static Window win;
static Atom a_delete, a_state, a_fullscreen, a_net_name, a_utf8, a_icon;
static Atom a_dnd_aware, a_dnd_enter, a_dnd_position, a_dnd_status, a_dnd_drop, a_dnd_finished, a_dnd_selection,
            a_dnd_action_copy, a_uri_list, a_dnd_target;
static Window dnd_source;
static int win_w, win_h;
static bool fullscreen, visible = true;
static XImage *img;
static XShmSegmentInfo shm;
static bool use_shm;
static GC gc;

static void image_free(void)
{
    if (!img) return;
    if (use_shm) {
        XShmDetach(dpy, &shm);
        XDestroyImage(img);
        shmdt(shm.shmaddr);
        shmctl(shm.shmid, IPC_RMID, NULL);
    } else {
        XDestroyImage(img);              /* (frees its data) */
    }
    img = NULL;
}

static int shm_error;
static int shm_handler(Display *d, XErrorEvent *e) { (void)d; (void)e; shm_error = 1; return 0; }

/* the picture of the window: in shared memory when the server is on this machine */
static bool image_make(int w, int h)
{
    image_free();
    if (w < 1) w = 1;
    if (h < 1) h = 1;
    Visual *vis = DefaultVisual(dpy, DefaultScreen(dpy));
    int depth = DefaultDepth(dpy, DefaultScreen(dpy));
    if (use_shm) {
        img = XShmCreateImage(dpy, vis, (unsigned)depth, ZPixmap, NULL, &shm, (unsigned)w, (unsigned)h);
        if (img) {
            shm.shmid = shmget(IPC_PRIVATE, (size_t)img->bytes_per_line * img->height, IPC_CREAT | 0600);
            shm.shmaddr = img->data = shm.shmid >= 0 ? (char *)shmat(shm.shmid, NULL, 0) : (char *)-1;
            shm.readOnly = False;
            shm_error = 0;
            XErrorHandler old = XSetErrorHandler(shm_handler);
            bool ok = shm.shmaddr != (char *)-1 && XShmAttach(dpy, &shm);
            XSync(dpy, False);
            XSetErrorHandler(old);
            if (ok && !shm_error) return true;
            if (shm.shmaddr != (char *)-1) shmdt(shm.shmaddr);
            if (shm.shmid >= 0) shmctl(shm.shmid, IPC_RMID, NULL);
            img->data = NULL;
            XDestroyImage(img);
            img = NULL;
        }
        use_shm = false;
    }
    char *data = (char *)malloc((size_t)w * h * 4);
    if (!data) return false;
    img = XCreateImage(dpy, vis, (unsigned)depth, ZPixmap, 0, data, (unsigned)w, (unsigned)h, 32, w * 4);
    return img != NULL;
}

static void present(void)
{
    if (!win || win_w <= 0 || win_h <= 0) return;
    if (!img || img->width != win_w || img->height != win_h) if (!image_make(win_w, win_h)) return;
    DeskPicture p;
    desk_picture(&D, win_w, win_h, &p);
    desk_blit(&p, (uint32_t *)(void *)img->data, win_w, win_h, img->bytes_per_line / 4);
    if (use_shm) XShmPutImage(dpy, win, gc, img, 0, 0, 0, 0, (unsigned)win_w, (unsigned)win_h, False);
    else XPutImage(dpy, win, gc, img, 0, 0, 0, 0, (unsigned)win_w, (unsigned)win_h);
    XFlush(dpy);
}

static void set_title(void)
{
    const char *t = D.pb && D.pb->rom->id == PB_ROM_GENERATIONS ? APP_TITLE " - Generations" : APP_TITLE;
    XStoreName(dpy, win, t);
    XChangeProperty(dpy, win, a_net_name, a_utf8, 8, PropModeReplace, (const unsigned char *)t, (int)strlen(t));
}

/* the icon: the right flipper key of the Blue table (as on Android and Windows), 32 and 64 pixels */
static void set_icon(void)
{
    static unsigned long data[2 + 32 * 32 + 2 + 64 * 64];
    uint32_t px[64 * 64];
    size_t k = 0;
    for (int s = 32; s <= 64; s *= 2) {
        nd_set_flipper(NULL);                   /* the program's own flipper (the game's: not in the icon) */
        nd_icon(px, s);
        data[k++] = (unsigned long)s;
        data[k++] = (unsigned long)s;
        for (int i = 0; i < s * s; i++) data[k++] = px[i];
    }
    if (D.pb) nd_set_flipper(pb_flipper_tiles(D.pb));
    XChangeProperty(dpy, win, a_icon, XA_CARDINAL, 32, PropModeReplace, (const unsigned char *)data, (int)k);
}

static void set_fullscreen(bool on)
{
    if (on == fullscreen) return;
    fullscreen = on;
    XEvent e;
    memset(&e, 0, sizeof e);
    e.xclient.type = ClientMessage;
    e.xclient.window = win;
    e.xclient.message_type = a_state;
    e.xclient.format = 32;
    e.xclient.data.l[0] = on ? 1 : 0;           /* _NET_WM_STATE_ADD / REMOVE */
    e.xclient.data.l[1] = (long)a_fullscreen;
    e.xclient.data.l[3] = 1;
    XSendEvent(dpy, DefaultRootWindow(dpy), False, SubstructureRedirectMask | SubstructureNotifyMask, &e);
    XFlush(dpy);
}

/* the shape of the window for the display (the table: its zoom kept; the handheld mode: a phone's) */
static void reshape(void)
{
    if (fullscreen) return;
    int sw = DisplayWidth(dpy, DefaultScreen(dpy)), sh = DisplayHeight(dpy, DefaultScreen(dpy)), w, h;
    if (D.handheld) desk_window_size(&D, sw, sh, &w, &h);
    else {
        int zoom = (win_h + PB_FIELD_H / 2) / PB_FIELD_H;
        if (zoom < 1) zoom = 1;
        w = (D.narrow ? PB_FIELD_W_NARROW : PB_FIELD_W) * zoom;
        h = PB_FIELD_H * zoom;
    }
    XResizeWindow(dpy, win, (unsigned)w, (unsigned)h);
}

static bool create_window(void)
{
    dpy = XOpenDisplay(NULL);
    if (!dpy) { fprintf(stderr, "Pinball NS: no X display (DISPLAY is not set?)\n"); return false; }
    int scr = DefaultScreen(dpy), w, h;
    desk_window_size(&D, DisplayWidth(dpy, scr), DisplayHeight(dpy, scr), &w, &h);
    win = XCreateSimpleWindow(dpy, RootWindow(dpy, scr), 0, 0, (unsigned)w, (unsigned)h, 0, BlackPixel(dpy, scr), BlackPixel(dpy, scr));
    win_w = w;
    win_h = h;
    XSelectInput(dpy, win, ExposureMask | KeyPressMask | KeyReleaseMask | ButtonPressMask | ButtonReleaseMask |
                 PointerMotionMask | StructureNotifyMask | FocusChangeMask | VisibilityChangeMask);
    a_delete = XInternAtom(dpy, "WM_DELETE_WINDOW", False);
    a_state = XInternAtom(dpy, "_NET_WM_STATE", False);
    a_fullscreen = XInternAtom(dpy, "_NET_WM_STATE_FULLSCREEN", False);
    a_net_name = XInternAtom(dpy, "_NET_WM_NAME", False);
    a_utf8 = XInternAtom(dpy, "UTF8_STRING", False);
    a_icon = XInternAtom(dpy, "_NET_WM_ICON", False);
    a_dnd_aware = XInternAtom(dpy, "XdndAware", False);
    a_dnd_enter = XInternAtom(dpy, "XdndEnter", False);
    a_dnd_position = XInternAtom(dpy, "XdndPosition", False);
    a_dnd_status = XInternAtom(dpy, "XdndStatus", False);
    a_dnd_drop = XInternAtom(dpy, "XdndDrop", False);
    a_dnd_finished = XInternAtom(dpy, "XdndFinished", False);
    a_dnd_selection = XInternAtom(dpy, "XdndSelection", False);
    a_dnd_action_copy = XInternAtom(dpy, "XdndActionCopy", False);
    a_uri_list = XInternAtom(dpy, "text/uri-list", False);
    a_dnd_target = XInternAtom(dpy, "PINBALL_NS_DROP", False);
    XSetWMProtocols(dpy, win, &a_delete, 1);
    Atom version = 5;
    XChangeProperty(dpy, win, a_dnd_aware, XA_ATOM, 32, PropModeReplace, (const unsigned char *)&version, 1);
    XClassHint ch = { (char *)"pinball-ns", (char *)"PinballNS" };
    XSetClassHint(dpy, win, &ch);
    XkbSetDetectableAutoRepeat(dpy, True, NULL);  /* auto-repeats without the releases between them */
    gc = XCreateGC(dpy, win, 0, NULL);
    use_shm = XShmQueryExtension(dpy);
    set_title();
    set_icon();
    return true;
}

/* ------------------------------------------------------------------ keys */

static unsigned key_of(KeySym k)
{
    if (k >= XK_a && k <= XK_z) return (unsigned)('A' + (k - XK_a));
    if (k >= XK_A && k <= XK_Z) return (unsigned)('A' + (k - XK_A));
    if (k >= XK_0 && k <= XK_9) return (unsigned)('0' + (k - XK_0));
    if (k >= XK_F1 && k <= XK_F24) return DK_F1 + (unsigned)(k - XK_F1);
    if (k >= XK_KP_0 && k <= XK_KP_9) return DK_NUM0 + (unsigned)(k - XK_KP_0);
    switch (k) {
    case XK_Shift_L: return DK_LSHIFT;
    case XK_Shift_R: return DK_RSHIFT;
    case XK_Control_L: return DK_LCONTROL;
    case XK_Control_R: return DK_RCONTROL;
    case XK_Alt_L: case XK_Meta_L: return DK_LALT;
    case XK_Alt_R: case XK_Meta_R: case XK_ISO_Level3_Shift: return DK_RALT;
    case XK_Super_L: return DK_LWIN;
    case XK_Super_R: return DK_RWIN;
    case XK_Menu: return DK_APPS;
    case XK_Left: case XK_KP_Left: return DK_LEFT;
    case XK_Right: case XK_KP_Right: return DK_RIGHT;
    case XK_Up: case XK_KP_Up: return DK_UP;
    case XK_Down: case XK_KP_Down: return DK_DOWN;
    case XK_Return: case XK_KP_Enter: return DK_RETURN;
    case XK_space: return DK_SPACE;
    case XK_Tab: case XK_ISO_Left_Tab: return DK_TAB;
    case XK_BackSpace: return DK_BACK;
    case XK_Escape: return DK_ESCAPE;
    case XK_Delete: case XK_KP_Delete: return DK_DELETE;
    case XK_Insert: case XK_KP_Insert: return DK_INSERT;
    case XK_Home: case XK_KP_Home: return DK_HOME;
    case XK_End: case XK_KP_End: return DK_END;
    case XK_Prior: case XK_KP_Prior: return DK_PGUP;
    case XK_Next: case XK_KP_Next: return DK_PGDN;
    case XK_Pause: return DK_PAUSE;
    case XK_Caps_Lock: return DK_CAPS;
    case XK_KP_Multiply: return DK_MULTIPLY;
    case XK_KP_Add: return DK_ADD;
    case XK_KP_Subtract: return DK_SUBTRACT;
    case XK_KP_Decimal: return DK_DECIMAL;
    case XK_KP_Divide: return DK_DIVIDE;
    case XK_semicolon: return DK_SEMICOLON;
    case XK_equal: return DK_EQUALS;
    case XK_comma: return DK_COMMA;
    case XK_minus: return DK_MINUS;
    case XK_period: return DK_PERIOD;
    case XK_slash: return DK_SLASH;
    case XK_grave: return DK_GRAVE;
    case XK_bracketleft: return DK_LBRACKET;
    case XK_backslash: return DK_BACKSLASH;
    case XK_bracketright: return DK_RBRACKET;
    case XK_apostrophe: return DK_QUOTE;
    default: return 0;
    }
}

/* ------------------------------------------------------------------ sound (ALSA) */

static snd_pcm_t *pcm;
static bool audio_ok;
static int16_t stage_buf[STAGE_FRAMES * 2];
static int stage_n;
static uint64_t audio_written;        /* frames given to ALSA */
static SoundPacer snd;
static Pacer pacer;
static bool silent;                   /* -selftest: silence (the card still paces the sound) */

static void audio_open(void)
{
    if (snd_pcm_open(&pcm, "default", SND_PCM_STREAM_PLAYBACK, SND_PCM_NONBLOCK) < 0) { pcm = NULL; return; }
    if (snd_pcm_set_params(pcm, SND_PCM_FORMAT_S16_LE, SND_PCM_ACCESS_RW_INTERLEAVED, 2, AUDIO_RATE, 1,
                           (unsigned)((uint64_t)ALSA_BUFFER * 1000000 / AUDIO_RATE)) < 0) {
        snd_pcm_close(pcm);
        pcm = NULL;
        return;
    }
    audio_ok = true;
    stage_n = 0;
    audio_written = 0;
    sound_reset(&snd, AUDIO_RATE, AUDIO_TARGET);
    snd.limit = ALSA_BUFFER + STAGE_FRAMES;
    sound_restart(&snd, now_s());
}

static void audio_close(void)
{
    if (!pcm) return;
    snd_pcm_drop(pcm);
    snd_pcm_close(pcm);
    pcm = NULL;
    audio_ok = false;
}

static void audio_hold(bool hold)
{
    if (pcm) snd_pcm_pause(pcm, hold ? 1 : 0);
}

/* the frames waiting in ALSA's buffer */
static long audio_delay(void)
{
    snd_pcm_sframes_t d = 0;
    if (!pcm || snd_pcm_delay(pcm, &d) < 0) return 0;
    return d < 0 ? 0 : (long)d;
}

/* the emulator's new samples to the stage, the stage to the card as far as it takes them */
static void audio_pump(void)
{
    int16_t tmp[4096];
    int n;
    while ((n = pb_audio(D.pb, tmp, 2048)) > 0) {
        if (!audio_ok) continue;
        if (!D.sound || silent) memset(tmp, 0, (size_t)n * 4);
        if (stage_n + n > STAGE_FRAMES) {          /* far ahead of the card: drop the oldest */
            int drop = stage_n + n - STAGE_FRAMES;
            if (drop > stage_n) drop = stage_n;
            memmove(stage_buf, stage_buf + drop * 2, (size_t)(stage_n - drop) * 4);
            stage_n -= drop;
        }
        if (n > STAGE_FRAMES) n = STAGE_FRAMES;
        memcpy(stage_buf + stage_n * 2, tmp, (size_t)n * 4);
        stage_n += n;
    }
    while (audio_ok && stage_n > 0) {
        snd_pcm_sframes_t w = snd_pcm_writei(pcm, stage_buf, (snd_pcm_uframes_t)stage_n);
        if (w == -EAGAIN) break;
        if (w < 0) { if (snd_pcm_recover(pcm, (int)w, 1) < 0) { audio_close(); break; } continue; }
        memmove(stage_buf, stage_buf + w * 2, (size_t)(stage_n - w) * 4);
        stage_n -= (int)w;
        audio_written += (uint64_t)w;
    }
}

static struct {
    double secs, start, last, work_max, work_sum, dt_max, level_min, level_max;
    long refreshes, frames, odd, starving, pads, flushes;
    char report[PATH_MAX], shot[PATH_MAX];
} st;
static bool selftest;

static int audio_pace(double t, int frames_left)
{
    if (!audio_ok) return SOUND_KEEP;
    long delay = audio_delay();
    double played = (double)audio_written - delay;
    double waiting = (double)delay + stage_n;
    double rate, pad;
    int act = sound_pace(&snd, &pacer, t, played, waiting, frames_left, &rate, &pad);
    if (selftest && t - st.start > 3) {
        if (waiting < st.level_min) st.level_min = waiting;
        if (waiting > st.level_max) st.level_max = waiting;
        if (delay == 0) st.starving++;
        if (act == SOUND_PAD) st.pads++;
        if (act == SOUND_FLUSH) st.flushes++;
    }
    if (act == SOUND_PAD) {
        int add = (int)pad;
        if (add > STAGE_FRAMES - stage_n) add = STAGE_FRAMES - stage_n;
        if (add > 0) { memset(stage_buf + stage_n * 2, 0, (size_t)add * 4); stage_n += add; }
    } else if (act == SOUND_FLUSH) {
        /* what waited in ALSA's buffer is dropped, never played: the frames played go on from where they were
         * (the pacer measures the card on their total; set back to 0, it read a card going backwards) */
        stage_n = 0;
        if (pcm) {
            snd_pcm_drop(pcm);
            snd_pcm_prepare(pcm);
            audio_written = (uint64_t)delay < audio_written ? audio_written - (uint64_t)delay : 0;
        }
    } else if (act == SOUND_TRIM) {
        int drop = (int)pad < stage_n ? (int)pad : stage_n;
        memmove(stage_buf, stage_buf + drop * 2, (size_t)(stage_n - drop) * 4);
        stage_n -= drop;
    }
    pb_set_audio_rate(D.pb, rate);
    return act;
}

/* ------------------------------------------------------------------ gamepads (evdev) */

/*
 * Every gamepad is read into the layout of an Xbox gamepad (desk.h: PAD_*), from the codes of the
 * kernel's drivers (xpad, hid-sony, hid-nintendo, hid-generic...): BTN_SOUTH A, BTN_EAST B, BTN_X X,
 * BTN_Y Y, the shoulders and the triggers, SELECT Back, START, the D-pad (buttons or the hat), the
 * left stick; Z and RZ as triggers when they rest at their lowest (else they are a stick); the old
 * joysticks' buttons (BTN_TRIGGER...) by number as most gamepads number them. Their vibration: a
 * force feedback rumble when they have one. New gamepads are looked for every two seconds.
 */
#define MAX_PADS 4
#define TEST_BIT(b, a) (((a)[(b) / (8 * sizeof(long))] >> ((b) % (8 * sizeof(long)))) & 1)
static struct {
    int fd;
    char path[300];
    long in;
    int lo[ABS_CNT], hi[ABS_CNT];
    bool trig_z, trig_rz;            /* Z and RZ are triggers */
    int ff_id;                       /* its rumble effect, -1: none */
    bool rumbling;
} pads[MAX_PADS];
static int npads;
static double pad_scan_t;

static void pad_add(const char *path)
{
    for (int i = 0; i < npads; i++) if (!strcmp(pads[i].path, path)) return;
    if (npads == MAX_PADS) return;
    int fd = open(path, O_RDWR | O_NONBLOCK | O_CLOEXEC);
    if (fd < 0) fd = open(path, O_RDONLY | O_NONBLOCK | O_CLOEXEC);
    if (fd < 0) return;
    unsigned long keys[KEY_CNT / (8 * sizeof(long)) + 1], abs[ABS_CNT / (8 * sizeof(long)) + 1], ff[FF_CNT / (8 * sizeof(long)) + 1];
    memset(keys, 0, sizeof keys);
    memset(abs, 0, sizeof abs);
    memset(ff, 0, sizeof ff);
    ioctl(fd, EVIOCGBIT(EV_KEY, sizeof keys), keys);
    ioctl(fd, EVIOCGBIT(EV_ABS, sizeof abs), abs);
    if (!TEST_BIT(BTN_GAMEPAD, keys) && !TEST_BIT(BTN_JOYSTICK, keys)) { close(fd); return; }
    int i = npads++;
    memset(&pads[i], 0, sizeof pads[i]);
    pads[i].fd = fd;
    snprintf(pads[i].path, sizeof pads[i].path, "%s", path);
    for (int a = 0; a < ABS_CNT; a++) {
        struct input_absinfo ai;
        if (TEST_BIT(a, abs) && ioctl(fd, EVIOCGABS(a), &ai) == 0) {
            pads[i].lo[a] = ai.minimum;
            pads[i].hi[a] = ai.maximum;
            if (a == ABS_Z) pads[i].trig_z = ai.value <= ai.minimum + (ai.maximum - ai.minimum) / 8;
            if (a == ABS_RZ) pads[i].trig_rz = ai.value <= ai.minimum + (ai.maximum - ai.minimum) / 8;
        }
    }
    pads[i].ff_id = -1;
    if (ioctl(fd, EVIOCGBIT(EV_FF, sizeof ff), ff) >= 0 && TEST_BIT(FF_RUMBLE, ff)) {
        struct ff_effect e;
        memset(&e, 0, sizeof e);
        e.type = FF_RUMBLE;
        e.id = -1;
        e.u.rumble.strong_magnitude = 0x7000;
        e.u.rumble.weak_magnitude = 0xA000;
        e.replay.length = 5000;
        if (ioctl(fd, EVIOCSFF, &e) == 0) pads[i].ff_id = e.id;
    }
}

static void pads_scan(void)
{
    DIR *dir = opendir("/dev/input");
    if (!dir) return;
    struct dirent *e;
    while ((e = readdir(dir))) {
        if (strncmp(e->d_name, "event", 5)) continue;
        char p[300];
        snprintf(p, sizeof p, "/dev/input/%s", e->d_name);
        pad_add(p);
    }
    closedir(dir);
}

static double axis(int i, int a, int v)
{
    int lo = pads[i].lo[a], hi = pads[i].hi[a];
    return hi > lo ? 2.0 * (v - lo) / (hi - lo) - 1.0 : 0;
}

static void pad_event(int i, const struct input_event *ev)
{
    long *in = &pads[i].in;
#define SET(bit, on) do { if (on) *in |= 1L << (bit); else *in &= ~(1L << (bit)); } while (0)
    if (ev->type == EV_KEY) {
        int p = -1;
        switch (ev->code) {
        case BTN_SOUTH: p = PAD_A; break;
        case BTN_EAST: p = PAD_B; break;
        case BTN_X: p = PAD_X; break;
        case BTN_Y: p = PAD_Y; break;
        case BTN_TL: p = PAD_LB; break;
        case BTN_TR: p = PAD_RB; break;
        case BTN_TL2: p = PAD_LT; break;
        case BTN_TR2: p = PAD_RT; break;
        case BTN_SELECT: p = PAD_BACK; break;
        case BTN_START: p = PAD_START; break;
        case BTN_MODE: p = PAD_GUIDE; break;
        case BTN_THUMBL: p = PAD_LTHUMB; break;
        case BTN_THUMBR: p = PAD_RTHUMB; break;
        case BTN_DPAD_UP: p = PAD_DUP; break;
        case BTN_DPAD_DOWN: p = PAD_DDOWN; break;
        case BTN_DPAD_LEFT: p = PAD_DLEFT; break;
        case BTN_DPAD_RIGHT: p = PAD_DRIGHT; break;
        default:
            if (ev->code >= BTN_TRIGGER && ev->code <= BTN_BASE6) {      /* an old joystick's buttons 1-12 */
                static const int8_t num[12] = { PAD_X, PAD_A, PAD_B, PAD_Y, PAD_LB, PAD_RB, PAD_LT, PAD_RT, PAD_BACK,
                                                PAD_START, PAD_LTHUMB, PAD_RTHUMB };
                if (ev->code - BTN_TRIGGER < 12) p = num[ev->code - BTN_TRIGGER];
            }
            break;
        }
        if (p >= 0) SET(p, ev->value != 0);
    } else if (ev->type == EV_ABS) {
        double a = axis(i, ev->code, ev->value);
        switch (ev->code) {
        case ABS_X: SET(PAD_LS_LEFT, a < -0.5); SET(PAD_LS_RIGHT, a > 0.5); break;
        case ABS_Y: SET(PAD_LS_UP, a < -0.5); SET(PAD_LS_DOWN, a > 0.5); break;
        case ABS_HAT0X: SET(PAD_DLEFT, ev->value < 0); SET(PAD_DRIGHT, ev->value > 0); break;
        case ABS_HAT0Y: SET(PAD_DUP, ev->value < 0); SET(PAD_DDOWN, ev->value > 0); break;
        case ABS_Z: if (pads[i].trig_z) SET(PAD_LT, a > -0.5); break;
        case ABS_RZ: if (pads[i].trig_rz) SET(PAD_RT, a > -0.5); break;
        case ABS_BRAKE: SET(PAD_LT, a > -0.5); break;
        case ABS_GAS: SET(PAD_RT, a > -0.5); break;
        default: break;
        }
    }
#undef SET
}

/* the inputs of every gamepad together, -1 when there is none */
static long pads_poll(void)
{
    double t = now_s();
    if (t - pad_scan_t > 2.0) { pad_scan_t = t; pads_scan(); }
    long in = npads ? 0 : -1;
    for (int i = 0; i < npads; i++) {
        struct input_event ev[64];
        ssize_t n;
        while ((n = read(pads[i].fd, ev, sizeof ev)) > 0)
            for (size_t k = 0; k < (size_t)n / sizeof ev[0]; k++) pad_event(i, &ev[k]);
        if (n < 0 && errno != EAGAIN && errno != EINTR) {        /* unplugged */
            close(pads[i].fd);
            pads[i] = pads[--npads];
            i--;
            continue;
        }
        in |= pads[i].in;
    }
    return npads ? in : -1;
}

static void pads_rumble(bool on)
{
    for (int i = 0; i < npads; i++) {
        if (pads[i].ff_id < 0 || pads[i].rumbling == on) continue;
        struct input_event ev;
        memset(&ev, 0, sizeof ev);
        ev.type = EV_FF;
        ev.code = (unsigned short)pads[i].ff_id;
        ev.value = on ? 1 : 0;
        if (write(pads[i].fd, &ev, sizeof ev) == (ssize_t)sizeof ev) pads[i].rumbling = on;
    }
}

/* ------------------------------------------------------------------ the ROM */

static bool try_rom(const char *path, bool report)
{
    char full[PATH_MAX], err[1024];
    if (!realpath(path, full)) snprintf(full, sizeof full, "%s", path);
    if (!desk_open_rom(&D, full, err, sizeof err)) {
        if (report) {
            fprintf(stderr, "Pinball NS: %s\n", err);
            if (win) desk_osd(&D, "Not the expected ROM (US Pokémon Pinball, or Generations 1.6)");
        }
        return false;
    }
    if (win) { set_title(); set_icon(); }
    return true;
}

/* a ROM next to the program */
static bool find_rom_near(const char *dir)
{
    DIR *dd = opendir(dir);
    if (!dd) return false;
    struct dirent *e;
    bool ok = false;
    while (!ok && (e = readdir(dd))) {
        const char *x = strrchr(e->d_name, '.');
        if (!x || (strcasecmp(x, ".gbc") && strcasecmp(x, ".gb") && strcasecmp(x, ".cgb"))) continue;
        char p[PATH_MAX + 256];
        snprintf(p, sizeof p, "%s/%s", dir, e->d_name);
        ok = try_rom(p, false);
    }
    closedir(dd);
    return ok;
}

/* the file dialog of the desktop, when it has one */
static bool ask_rom(void)
{
    const char *cmds[] = {
        "zenity --file-selection --title='Pinball NS: the ROM of your Pokémon Pinball cartridge (US), or of Generations' "
        "--file-filter='Game Boy Color ROM | *.gbc *.gb *.cgb' 2>/dev/null",
        "kdialog --getopenfilename . 'Game Boy Color ROM (*.gbc *.gb *.cgb)' 2>/dev/null" };
    for (int k = 0; k < 2; k++) {
        for (;;) {
            FILE *f = popen(cmds[k], "r");
            if (!f) break;
            char p[PATH_MAX];
            bool got = fgets(p, sizeof p, f) != NULL;
            int rc = pclose(f);
            if (!got || rc != 0) break;
            p[strcspn(p, "\r\n")] = 0;
            if (!p[0]) break;
            if (try_rom(p, true)) return true;
        }
    }
    return false;
}

/* a file dropped onto the window (XDND): file:///path%20with%20escapes */
static void dropped(const char *uris)
{
    const char *u = strstr(uris, "file://");
    if (!u) return;
    u += 7;
    char p[PATH_MAX];
    size_t k = 0;
    while (*u && *u != '\r' && *u != '\n' && k + 1 < sizeof p) {
        if (*u == '%' && u[1] && u[2]) { char h[3] = { u[1], u[2], 0 }; p[k++] = (char)strtol(h, NULL, 16); u += 3; }
        else p[k++] = *u++;
    }
    p[k] = 0;
    try_rom(p, true);
}

/* ------------------------------------------------------------------ events */

static void do_action(int a)
{
    switch (a) {
    case DESK_FULLSCREEN: set_fullscreen(!fullscreen); break;
    case DESK_LEAVE_FULLSCREEN: set_fullscreen(false); break;
    case DESK_RESHAPE: reshape(); break;
    case DESK_PAUSE: audio_hold(D.paused); break;
    default: break;
    }
}

static void dnd_reply(Atom type, long accept)
{
    XEvent r;
    memset(&r, 0, sizeof r);
    r.xclient.type = ClientMessage;
    r.xclient.window = dnd_source;
    r.xclient.message_type = type;
    r.xclient.format = 32;
    r.xclient.data.l[0] = (long)win;
    r.xclient.data.l[1] = accept;
    r.xclient.data.l[2] = accept ? (long)a_dnd_action_copy : None;
    if (type == a_dnd_status) { r.xclient.data.l[2] = 0; r.xclient.data.l[3] = 0; r.xclient.data.l[4] = (long)a_dnd_action_copy; }
    XSendEvent(dpy, dnd_source, False, NoEventMask, &r);
}

static void events(void)
{
    while (XPending(dpy)) {
        XEvent e;
        XNextEvent(dpy, &e);
        switch (e.type) {
        case ClientMessage:
            if ((Atom)e.xclient.data.l[0] == a_delete) running = false;
            else if (e.xclient.message_type == a_dnd_enter || e.xclient.message_type == a_dnd_position) {
                dnd_source = (Window)e.xclient.data.l[0];
                if (e.xclient.message_type == a_dnd_position) dnd_reply(a_dnd_status, 1);
            } else if (e.xclient.message_type == a_dnd_drop) {
                dnd_source = (Window)e.xclient.data.l[0];
                XConvertSelection(dpy, a_dnd_selection, a_uri_list, a_dnd_target, win, (Time)e.xclient.data.l[2]);
            }
            break;
        case SelectionNotify:
            if (e.xselection.property == a_dnd_target) {
                Atom type;
                int fmt;
                unsigned long n, left;
                unsigned char *data = NULL;
                if (XGetWindowProperty(dpy, win, a_dnd_target, 0, 65536, True, AnyPropertyType, &type, &fmt, &n, &left, &data) == Success && data) {
                    dropped((const char *)data);
                    XFree(data);
                }
                dnd_reply(a_dnd_finished, 1);
            }
            break;
        case ConfigureNotify:
            win_w = e.xconfigure.width;
            win_h = e.xconfigure.height;
            break;
        case Expose:
            present();
            break;
        case VisibilityNotify:
            visible = e.xvisibility.state != VisibilityFullyObscured;
            break;
        case UnmapNotify: visible = false; break;
        case MapNotify: visible = true; break;
        case FocusOut:
            desk_keys_released(&D);
            if (D.handheld) desk_pointer(&D, UI_CANCEL, 0, 0, 0);
            break;
        case KeyPress:
        case KeyRelease: {
            unsigned vk = key_of(XLookupKeysym(&e.xkey, 0));
            if (!vk) break;
            bool down = e.type == KeyPress, repeat = down && D.key_down[vk];
            do_action(desk_key(&D, vk, down, repeat));
            break;
        }
        case ButtonPress:
            if (e.xbutton.button == Button1) desk_pointer(&D, UI_DOWN, 0, (float)e.xbutton.x, (float)e.xbutton.y);
            break;
        case ButtonRelease:
            if (e.xbutton.button == Button1) desk_pointer(&D, UI_UP, 0, (float)e.xbutton.x, (float)e.xbutton.y);
            break;
        case MotionNotify:
            if (e.xmotion.state & Button1Mask) desk_pointer(&D, UI_MOVE, 0, (float)e.xmotion.x, (float)e.xmotion.y);
            break;
        default:
            break;
        }
    }
}

/* -selftest: what the X server shows in the window, read back */
static void selftest_shot(void)
{
    if (!st.shot[0]) return;
    XImage *g = XGetImage(dpy, win, 0, 0, (unsigned)win_w, (unsigned)win_h, AllPlanes, ZPixmap);
    if (!g) { fprintf(stderr, "selftest: the window could not be read back\n"); return; }
    uint32_t *px = (uint32_t *)malloc((size_t)win_w * win_h * 4);
    if (px) {
        for (int y = 0; y < win_h; y++)
            for (int x = 0; x < win_w; x++) px[(size_t)y * win_w + x] = (uint32_t)XGetPixel(g, x, y) & 0xFFFFFF;
        png_write_rgb(st.shot, px, win_w, win_h, win_w, 1);
        free(px);
    }
    XDestroyImage(g);
}

/* ------------------------------------------------------------------ main */

int main(int argc, char **argv)
{
    /* the settings: $XDG_CONFIG_HOME/pinball-ns, else ~/.config/pinball-ns */
    char cfgdir[PATH_MAX], cfg[PATH_MAX + 32];
    const char *xdg = getenv("XDG_CONFIG_HOME"), *home = getenv("HOME");
    if (xdg && xdg[0]) snprintf(cfgdir, sizeof cfgdir, "%s/pinball-ns", xdg);
    else snprintf(cfgdir, sizeof cfgdir, "%s/.config/pinball-ns", home ? home : ".");
    char parent[PATH_MAX];
    snprintf(parent, sizeof parent, "%s", cfgdir);
    char *sl = strrchr(parent, '/');
    if (sl) { *sl = 0; mkdir(parent, 0755); }
    mkdir(cfgdir, 0755);
    snprintf(cfg, sizeof cfg, "%s/pinball_ns.cfg", cfgdir);
    desk_init(&D, cfg);

    const char *rom_arg = NULL;
    if (argc > 4 && !strcmp(argv[1], "-selftest")) {
        selftest = silent = true;
        st.secs = atof(argv[2]);
        rom_arg = argv[3];
        snprintf(st.report, sizeof st.report, "%s", argv[4]);
        if (argc > 5) snprintf(st.shot, sizeof st.shot, "%s", argv[5]);
    } else if (argc > 1) rom_arg = argv[1];

    if (!create_window()) return 1;
    bool have = rom_arg && try_rom(rom_arg, true);
    if (selftest && !have) return 2;
    if (!have && D.rom_paths[0][0]) have = try_rom(D.rom_paths[0], false);
    if (!have && D.rom_paths[1][0]) have = try_rom(D.rom_paths[1], false);
    if (!have) {
        char exe[PATH_MAX];
        ssize_t n = readlink("/proc/self/exe", exe, sizeof exe - 1);
        if (n > 0) { exe[n] = 0; char *s2 = strrchr(exe, '/'); if (s2) *s2 = 0; have = find_rom_near(exe); }
    }
    if (!have) {
        fprintf(stderr, "Pinball NS needs the ROM of your own Pokémon Pinball cartridge (US version, .gbc file); it is not "
                        "included. It also plays Pokémon Pinball Generations 1.6. Give it on the command line, choose it "
                        "in the next window, or drop it onto the window.\n");
        have = ask_rom();
    }
    XMapWindow(dpy, win);
    XFlush(dpy);

    audio_open();
    pacer_reset(&pacer);
    if (selftest) { st.start = now_s(); st.level_min = 1e9; }
    bool was_active = false;
    uint32_t frame_seq = 0;
    double next = now_s(), saver_reset = 0;
    const double tick = 1.0 / 60.0;          /* no refresh of the display to wait for in X11: a 60 Hz clock */

    double audio_retry = now_s() + 3;
    while (running && !D.quit) {
        events();
        desk_pad(&D, pads_poll());
        bool active = D.pb && !D.paused && !D.page && visible;
        double t = now_s();
        /* no sound yet (the sound server of the desktop not ready, a device busy): tried again now and then */
        if (!audio_ok && t >= audio_retry) {
            audio_open();
            audio_retry = t + 3;
            if (audio_ok) was_active = false;              /* (measured afresh: pacer_restart, sound_restart) */
        }
        if (active) {
            /* the clock sets the pace; the sound follows (pacing.h) */
            if (next > t) {
                struct timespec ts = { (time_t)(next - t), (long)((next - t - (double)(time_t)(next - t)) * 1e9) };
                nanosleep(&ts, NULL);
                t = now_s();
            }
            next += tick;
            if (next < t - 0.1) next = t + tick;            /* far behind (the machine was busy): from now */
            if (!was_active) {
                pacer_restart(&pacer);
                if (audio_ok) sound_restart(&snd, t);
            }
            /* the display kept on during a game (played with a gamepad, nothing else tells X someone is there) */
            if (t - saver_reset > 30) { XResetScreenSaver(dpy); saver_reset = t; }
            int n = pacer_frames(&pacer, t, 6);
            if (selftest) desk_key(&D, 'X', (frame_seq % 90) < 6, false);   /* A, now and then */
            bool extra = false;
            for (int k = 0; k < n; k++) {
                if (audio_pace(t, n - k) == SOUND_EXTRA && !extra) { extra = true; n++; }
                desk_frame(&D);
                frame_seq++;
                audio_pump();
                pads_rumble(desk_rumble(&D));
            }
            desk_tick(&D, t);
            present();
            if (selftest) {
                double e = now_s();
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
            if (desk_tick(&D, t)) present();
            else if (D.page) present();
            struct timespec ts = { 0, 16000000 };
            nanosleep(&ts, NULL);
            next = now_s();
        }
        was_active = active;
    }

    pads_rumble(false);
    desk_sram_flush(&D, false, false);
    if (selftest) {
        selftest_shot();
        FILE *f = fopen(st.report, "w");
        if (f) {
            double run = st.last - st.start - 3;
            fprintf(f, "refreshes %ld (%.2f Hz)  frames %ld (%.3f a second)  ratio %d/%d  out of pattern %ld\n",
                    st.refreshes, st.refreshes / run, st.frames, st.frames / run, pacer.num, pacer.den, st.odd);
            fprintf(f, "longest between refreshes %.2f ms  work per refresh %.2f ms (longest %.2f)  shared memory %d\n",
                    st.dt_max * 1000, st.work_sum / (st.refreshes ? st.refreshes : 1) * 1000, st.work_max * 1000, use_shm);
            fprintf(f, "sound: %s  waiting %.0f..%.0f  starving %ld  silences added %ld  dropped %ld  frames added %ld  "
                    "target %.0f  card %.1f Hz (measured %.1f)\n", audio_ok ? "ALSA" : "none", st.level_min, st.level_max,
                    st.starving, st.pads, st.flushes, snd.extra, snd.target, snd.rate, snd.measured);
            fclose(f);
        }
    }
    audio_close();
    image_free();
    desk_free(&D);
    XCloseDisplay(dpy);
    return 0;
}
