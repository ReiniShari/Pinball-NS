/*
 * iosmock.c - runs the iPhone version (platform/ios: main_ios.c, metal_render.c, and the
 * shared mobile code) on Windows, on a simulated iOS: an Objective-C runtime (classes made at
 * run time, objc_msgSend in msgsend_x64.asm), and the parts of UIKit, Foundation, QuartzCore,
 * Metal, AudioToolbox, GameController and CoreMotion the app uses. A message the simulation does
 * not know stops the test, as "unrecognized selector" would end the app on an iPhone.
 *
 * The Metal draws are carried out in software (the same formulas as the shaders), so the
 * screenshots show what the app sends to the screen. The sound card is pulled 800 frames per
 * display frame (48 kHz), as a RemoteIO unit would.
 *
 *   iosmock HOME ROM SCENARIO OUTDIR
 *     HOME      the app's sandbox (Documents, Library) - a scratch folder
 *     SCENARIO  first   no ROM; the document picker (a wrong file, then the ROM); the title, a
 *                       game started with a game controller, flippers, a keyboard's keys, the
 *                       controller's home button (the menu), MOTION TILT (taps on the sides, as the
 *                       accelerometer reads them), menu, sound off / on, background and back, QUIT
 *               resume  started again in the same HOME: the game resumes at once
 *               docs    the ROM is in Documents (Files > On My iPhone > Pinball NS)
 *               openin  the ROM is given at launch ("Open in" / share from Files)
 *               ips     the ROM, then the IPS patch of Generations (env PNS_GEN_IPS), copied to Files:
 *                       both games installed, the menu switches
 *
 * Built by tools\build_msvc.bat iosmock. Each scenario in a new HOME folder, but resume (in the
 * HOME of first); docs copies the ROM into HOME\Documents itself.
 */
#include "../../platform/apple/objc_c.h"
#include "../../platform/ios/metal_render.h"
#include "../../platform/mobile/app.h"
#include "../png_write.h"
#include <AudioToolbox/AudioToolbox.h>
#include <direct.h>
#include <io.h>
#include <math.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int pns_mock_main(int argc, char *argv[]);
MobileApp *pns_mock_app(void);
void mock_nil(void);
IMP mock_lookup(id self, SEL sel);

/* the simulated iPhone: an iPhone 15 (393 x 852 points, x3) */
#define SCR_W_PT 393.0
#define SCR_H_PT 852.0
#define SCR_SCALE 3.0

static int g_fail, g_checks;
#define CHECK(c, ...) do { g_checks++; if (c) printf("  ok    "); else { printf("  FAIL  "); g_fail++; } \
                           printf(__VA_ARGS__); printf("\n"); } while (0)

static void fatal(const char *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    printf("  FATAL ");
    vprintf(fmt, ap);
    printf("\n");
    va_end(ap);
    exit(2);
}

/* ------------------------------------------------------------------ the runtime */

typedef struct { SEL sel; IMP imp; } Meth;
struct objc_class { Class isa; Class super; char *name; Meth *m; int n, cap; bool meta; };

static Class g_classes[256];
static int g_nclasses;
static char *g_sels[4096];
static int g_nsels;
static long g_msgs;

SEL sel_registerName(const char *s)
{
    for (int i = 0; i < g_nsels; i++) if (!strcmp(g_sels[i], s)) return (SEL)g_sels[i];
    if (g_nsels >= 4096) fatal("too many selectors");
    g_sels[g_nsels] = _strdup(s);
    return (SEL)g_sels[g_nsels++];
}

const char *sel_getName(SEL s) { return (const char *)s; }

static Class new_class(Class super, const char *name)
{
    Class c = (Class)calloc(1, sizeof *c), meta = (Class)calloc(1, sizeof *meta);
    c->name = _strdup(name);
    meta->name = c->name;
    meta->meta = true;
    c->super = super;
    c->isa = meta;
    meta->super = super ? super->isa : c;              /* the root metaclass inherits the root class */
    meta->isa = super ? super->isa->isa : meta;
    return c;
}

Class objc_getClass(const char *name)
{
    for (int i = 0; i < g_nclasses; i++) if (!strcmp(g_classes[i]->name, name)) return g_classes[i];
    return NULL;
}

Class objc_allocateClassPair(Class super, const char *name, size_t extra)
{
    (void)extra;
    if (!super) fatal("objc_allocateClassPair(%s): no superclass", name);
    if (objc_getClass(name)) return NULL;
    return new_class(super, name);
}

void objc_registerClassPair(Class c)
{
    if (g_nclasses >= 256) fatal("too many classes");
    g_classes[g_nclasses++] = c;
}

BOOL class_addMethod(Class c, SEL s, IMP imp, const char *types)
{
    (void)types;
    for (int i = 0; i < c->n; i++) if (c->m[i].sel == s) return NO;     /* as the real one: no replacement */
    if (c->n == c->cap) { c->cap = c->cap ? c->cap * 2 : 16; c->m = (Meth *)realloc(c->m, (size_t)c->cap * sizeof(Meth)); }
    c->m[c->n].sel = s;
    c->m[c->n].imp = imp;
    c->n++;
    return YES;
}

static int g_protocols;
static struct objc_object g_protocol;
BOOL class_addProtocol(Class c, Protocol *p) { (void)c; if (p) g_protocols++; return p != NULL; }
Protocol *objc_getProtocol(const char *name) { return !strncmp(name, "UI", 2) ? (Protocol *)&g_protocol : NULL; }
Class object_getClass(id o) { return o ? o->isa : NULL; }
const char *class_getName(Class c) { return c ? c->name : "nil"; }

static IMP find_imp(Class c, SEL s)
{
    for (; c; c = c->super)
        for (int i = 0; i < c->n; i++) if (c->m[i].sel == s) return c->m[i].imp;
    return NULL;
}

IMP mock_lookup(id self, SEL sel)
{
    if (!self) return (IMP)mock_nil;
    IMP imp = find_imp(self->isa, sel);
    if (!imp) fatal("unrecognized selector sent to %s: %c[%s %s]", self->isa->meta ? "class" : "instance",
                    self->isa->meta ? '+' : '-', self->isa->name, (const char *)sel);
    g_msgs++;
    return imp;
}

void *objc_autoreleasePoolPush(void) { static int pools; return &pools; }
void objc_autoreleasePoolPop(void *pool) { (void)pool; }

/* ------------------------------------------------------------------ objects */

typedef struct MObj {
    Class isa;
    int rc;
    char *s;                     /* string, path, function name */
    id *items;                   /* array, set */
    int n;
    double v[8];
    uint8_t *mem;                /* texture, buffer */
    size_t len;
    int w, h, fmt;
    id a, b, c;
    SEL sel;
    SEL pk[24];                  /* values given to setters */
    uint64_t pv[24];
    int np;
} MObj;
#define M(o) ((MObj *)(o))

static id mk(Class c) { MObj *o = (MObj *)calloc(1, sizeof *o); o->isa = c; o->rc = 1; return (id)o; }
static id mkn(const char *cls)
{
    Class c = objc_getClass(cls);
    if (!c) fatal("no class %s", cls);
    return mk(c);
}
static id mstr(const char *s) { id o = mkn("NSString"); M(o)->s = _strdup(s); return o; }
static id marr(const id *items, int n)
{
    id o = mkn("NSArray");
    M(o)->items = (id *)calloc((size_t)(n ? n : 1), sizeof(id));
    if (n) memcpy(M(o)->items, items, (size_t)n * sizeof(id));
    M(o)->n = n;
    return o;
}

static void prop_set(id o, SEL k, uint64_t v)
{
    MObj *m = M(o);
    for (int i = 0; i < m->np; i++) if (m->pk[i] == k) { m->pv[i] = v; return; }
    if (m->np < 24) { m->pk[m->np] = k; m->pv[m->np++] = v; }
}
static bool prop_has(id o, const char *setter, uint64_t *v)
{
    SEL k = sel_registerName(setter);
    for (int i = 0; o && i < M(o)->np; i++) if (M(o)->pk[i] == k) { if (v) *v = M(o)->pv[i]; return true; }
    return false;
}
static uint64_t prop(id o, const char *setter) { uint64_t v = 0; prop_has(o, setter, &v); return v; }

/* generic setters: remember the value */
static void set_id(id self, SEL k, id v) { prop_set(self, k, (uint64_t)(uintptr_t)v); }
static void set_u(id self, SEL k, NSUInteger v) { prop_set(self, k, v); }
static void set_b(id self, SEL k, BOOL v) { prop_set(self, k, v ? 1 : 0); }
static void set_d(id self, SEL k, double v) { uint64_t u; memcpy(&u, &v, 8); prop_set(self, k, u); }
static double prop_d(id o, const char *setter) { uint64_t u = prop(o, setter); double d; memcpy(&d, &u, 8); return d; }

static Class defclass(const char *name, const char *super)
{
    Class c = new_class(super ? objc_getClass(super) : NULL, name);
    objc_registerClassPair(c);
    return c;
}
static void im(Class c, const char *sel, void *fn) { class_addMethod(c, sel_registerName(sel), (IMP)fn, ""); }
static void cm(Class c, const char *sel, void *fn) { class_addMethod(c->isa, sel_registerName(sel), (IMP)fn, ""); }

/* ------------------------------------------------------------------ simulated state */

static char g_home[600], g_out[600], g_rom[600];
static double g_now = 1000.0;
static id g_app_obj, g_screen, g_window, g_vc, g_view, g_layer, g_link, g_device, g_gamepad;
static id g_scene, g_scene_delegate;
static bool g_link_added;
static char g_link_mode[64];
static int g_impacts[8];
static int g_presented;
static int g_scoped_start, g_scoped_stop;
static bool g_pad_connected;
static int g_textures, g_buffers, g_pipelines, g_frames_presented, g_draws[3];
static bool g_pso_blend_ok = true, g_pso_format_ok = true, g_source_ok;
static char g_capture[700];
static uint32_t *g_screen_px;
static int g_sw, g_sh;
static bool g_screen_uniform_ok = true;
static int g_suspended, g_first_responder;
/* CoreMotion: the handler given to the manager, the samples it is sent (100 Hz, as an iPhone) */
id CMErrorDomain;
static void (*g_accel_fn)(id data, id error);
static bool g_accel_running;
static double g_accel_interval, g_acc_t;
static double g_jolt_t, g_jolt_x;                  /* a jolt across (m/s², as Android reads it) at g_jolt_t */

/* ------------------------------------------------------------------ Foundation */

static id o_alloc(id self, SEL c) { (void)c; return mk((Class)self); }
static id o_self(id self, SEL c) { (void)c; return self; }
static id o_retain(id self, SEL c) { (void)c; M(self)->rc++; return self; }
static void o_release(id self, SEL c) { (void)c; M(self)->rc--; }
static BOOL o_responds(id self, SEL c, SEL s) { (void)c; return find_imp(self->isa, s) != NULL; }
static BOOL o_inst_responds(id self, SEL c, SEL s) { (void)c; return find_imp((Class)self, s) != NULL; }
static void o_nop(id self, SEL c) { (void)self; (void)c; }

static id s_with_utf8(id self, SEL c, const char *s) { (void)self; (void)c; return mstr(s ? s : ""); }
static const char *s_utf8(id self, SEL c) { (void)c; return M(self)->s ? M(self)->s : ""; }
static NSUInteger s_length(id self, SEL c) { (void)c; return M(self)->s ? strlen(M(self)->s) : 0; }

static id a_with_object(id self, SEL c, id o) { (void)self; (void)c; return marr(&o, 1); }
static NSUInteger a_count(id self, SEL c) { (void)c; return (NSUInteger)M(self)->n; }
static id a_at(id self, SEL c, NSUInteger i)
{
    (void)c;
    if (i >= (NSUInteger)M(self)->n) fatal("objectAtIndex: %u beyond bounds (%d)", (unsigned)i, M(self)->n);
    return M(self)->items[i];
}
static id a_all(id self, SEL c) { (void)c; return marr(M(self)->items, M(self)->n); }

static id url_path(id self, SEL c) { (void)c; return mstr(M(self)->s); }
static BOOL url_start(id self, SEL c) { (void)self; (void)c; g_scoped_start++; return YES; }
static void url_stop(id self, SEL c) { (void)self; (void)c; g_scoped_stop++; }
static id mkurl(const char *path) { id u = mkn("NSURL"); M(u)->s = _strdup(path); return u; }

static id fm_default(id self, SEL c) { (void)self; (void)c; static id fm; if (!fm) fm = mkn("NSFileManager"); return fm; }
static id fm_list(id self, SEL c, id path, id *err)
{
    (void)self; (void)c;
    if (err) *err = nil;
    char pat[800];
    snprintf(pat, sizeof pat, "%s/*", M(path)->s);
    id items[256];
    int n = 0;
    struct _finddata_t fd;
    intptr_t h = _findfirst(pat, &fd);
    if (h == -1) return nil;
    do {
        if (strcmp(fd.name, ".") && strcmp(fd.name, "..") && n < 256) items[n++] = mstr(fd.name);
    } while (_findnext(h, &fd) == 0);
    _findclose(h);
    return marr(items, n);
}
static id rl_main(id self, SEL c) { (void)self; (void)c; static id rl; if (!rl) rl = mkn("NSRunLoop"); return rl; }
static id err_desc(id self, SEL c) { (void)self; (void)c; return mstr("mock error"); }

id NSHomeDirectory(void) { return mstr(g_home); }
void NSLog(id format, ...) { printf("  NSLog %s\n", format ? M(format)->s : ""); }
double CACurrentMediaTime(void) { return g_now; }

/* ------------------------------------------------------------------ UIKit */

static id scr_main(id self, SEL c) { (void)self; (void)c; if (!g_screen) g_screen = mkn("UIScreen"); return g_screen; }
static double scr_scale(id self, SEL c) { (void)self; (void)c; return SCR_SCALE; }
static double scr_corner(id self, SEL c) { (void)self; (void)c; return 55.0; }
static id color_black(id self, SEL c) { (void)self; (void)c; return mkn("UIColor"); }

static id view_init_frame(id self, SEL c, CGRect f) { (void)c; M(self)->v[0] = f.size.width; return self; }
static Class view_layer_class(id self, SEL c) { (void)self; (void)c; return objc_getClass("CALayer"); }
static id view_layer(id self, SEL c)
{
    (void)c;
    if (!M(self)->a) {
        Class lc = MSG0(Class, (id)self->isa, "layerClass");     /* [[self class] layerClass] */
        M(self)->a = msg(msg((id)lc, "alloc"), "init");
        if (!strcmp(class_getName(lc), "CAMetalLayer")) g_layer = M(self)->a;
    }
    return M(self)->a;
}
static CGRect view_bounds(id self, SEL c) { (void)self; (void)c; CGRect r = { { 0, 0 }, { SCR_W_PT, SCR_H_PT } }; return r; }
static PnsEdgeInsets view_safe(id self, SEL c) { (void)self; (void)c; PnsEdgeInsets e = { 59, 0, 34, 0 }; return e; }
static id view_window(id self, SEL c) { (void)c; return M(self)->b; }

static id win_init_scene(id self, SEL c, id scene) { (void)c; M(self)->a = scene; g_window = self; return self; }
static void win_set_root(id self, SEL c, id vc) { (void)c; M(self)->c = vc; g_vc = vc; }
static void win_key_visible(id self, SEL c)
{
    (void)c;
    id vc = M(self)->c;
    if (!vc) fatal("makeKeyAndVisible without a root view controller");
    if (!M(vc)->a) {                                   /* UIKit loads the view when it is needed */
        msg_void(vc, "loadView");
        if (!M(vc)->a) fatal("loadView did not set the view");
        M(M(vc)->a)->b = self;                         /* the view's window */
        msg_void(vc, "viewDidLoad");
        MSG1(void, BOOL, vc, "viewDidAppear:", YES);
    }
    g_view = M(vc)->a;
}
static id win_screen(id self, SEL c) { (void)self; return scr_main(nil, c); }

static void vc_set_view(id self, SEL c, id v) { (void)c; M(self)->a = v; }
static id vc_view(id self, SEL c) { (void)c; return M(self)->a; }
static void vc_present(id self, SEL c, id other, BOOL animated, id completion)
{
    (void)c; (void)animated; (void)completion;
    if (M(self)->b) fatal("presentViewController: one is already presented");
    M(self)->b = other;
    g_presented++;
}
static id vc_presented(id self, SEL c) { (void)c; return M(self)->b; }

static id dp_init_types(id self, SEL c, id types, BOOL copy)
{
    (void)c;
    M(self)->a = types;
    M(self)->v[0] = copy ? 1 : 0;
    return self;
}
static id dp_init_doc_types(id self, SEL c, id types, NSUInteger mode) { (void)c; (void)mode; M(self)->a = types; return self; }
static id ut_with_id(id self, SEL c, id ident) { (void)self; (void)c; id t = mkn("UTType"); M(t)->s = _strdup(M(ident)->s); return t; }

static id impact_init(id self, SEL c, NSInteger style) { (void)c; M(self)->v[0] = (double)style; return self; }
static void impact_fire(id self, SEL c) { (void)c; int s = (int)M(self)->v[0]; if (s >= 0 && s < 8) g_impacts[s]++; }

static CGPoint touch_location(id self, SEL c, id view)
{
    (void)c;
    if (view != g_view) fatal("locationInView: another view");
    CGPoint p = { M(self)->v[0], M(self)->v[1] };
    return p;
}
static id ctx_url(id self, SEL c) { (void)c; return M(self)->a; }
static id opts_contexts(id self, SEL c) { (void)c; return M(self)->a; }

/* ------------------------------------------------------------------ QuartzCore */

static id link_make(id self, SEL c, id target, SEL sel)
{
    (void)self; (void)c;
    id l = mkn("CADisplayLink");
    M(l)->a = target;
    M(l)->sel = sel;
    g_link = l;
    return l;
}
static void link_add(id self, SEL c, id runloop, id mode)
{
    (void)self; (void)c; (void)runloop;
    g_link_added = true;
    snprintf(g_link_mode, sizeof g_link_mode, "%s", mode ? M(mode)->s : "");
}
static void link_fps(id self, SEL c, NSInteger fps) { prop_set(self, c, (uint64_t)fps); }
static double link_timestamp(id self, SEL c) { (void)self; (void)c; return g_now; }

static void layer_drawable_size(id self, SEL c, CGSize s)
{
    (void)self; (void)c;
    int w = (int)s.width, h = (int)s.height;
    if (w != g_sw || h != g_sh) {
        free(g_screen_px);
        g_screen_px = (uint32_t *)calloc((size_t)w * h, 4);
        g_sw = w;
        g_sh = h;
    }
}
static id layer_next_drawable(id self, SEL c)
{
    (void)self; (void)c;
    if (!g_screen_px) return nil;                      /* no size yet: as iOS, no drawable */
    id d = mkn("MockDrawable");
    id t = mkn("MockTexture");
    M(t)->w = g_sw;
    M(t)->h = g_sh;
    M(t)->fmt = (int)prop(g_layer, "setPixelFormat:");
    M(d)->a = t;
    return d;
}
static id drawable_texture(id self, SEL c) { (void)c; return M(self)->a; }

/* ------------------------------------------------------------------ Metal */

id MTLCreateSystemDefaultDevice(void) { if (!g_device) g_device = mkn("MockDevice"); return g_device; }

static id dev_queue(id self, SEL c) { (void)self; (void)c; return mkn("MockQueue"); }
static id dev_library(id self, SEL c, id src, id opts, id *err)
{
    (void)self; (void)c; (void)opts;
    if (err) *err = nil;
    const char *s = M(src)->s;
    g_source_ok = s && strstr(s, "vertex VOut vs_main") && strstr(s, "fragment float4 fs_shape") &&
                  strstr(s, "fragment float4 fs_text") && strstr(s, "fragment float4 fs_game") && strstr(s, "#include <metal_stdlib>");
    id lib = mkn("MockLibrary");
    M(lib)->s = _strdup(s ? s : "");
    return lib;
}
static id lib_function(id self, SEL c, id name)
{
    (void)c;
    char want[80];
    snprintf(want, sizeof want, " %s(", M(name)->s);
    if (!strstr(M(self)->s, want)) return nil;
    id f = mkn("MockFunction");
    M(f)->s = _strdup(M(name)->s);
    return f;
}
static id rpd_pipe_init(id self, SEL c)
{
    (void)c;
    M(self)->a = mkn("MockAttachArray");
    return self;
}
static id rpd_attachments(id self, SEL c) { (void)c; return M(self)->a; }
static id attach_at(id self, SEL c, NSUInteger i)
{
    (void)c;
    if (i >= 8) fatal("colorAttachments[%u]", (unsigned)i);
    if (!M(self)->items) M(self)->items = (id *)calloc(8, sizeof(id));
    if (!M(self)->items[i]) M(self)->items[i] = mkn(M(self)->s ? M(self)->s : "MockAttach");
    return M(self)->items[i];
}
static void pipe_set_vertex(id self, SEL c, id f) { (void)c; M(self)->b = f; }
static void pipe_set_fragment(id self, SEL c, id f) { (void)c; M(self)->c = f; }
static id dev_pipeline(id self, SEL c, id desc, id *err)
{
    (void)self; (void)c;
    if (err) *err = nil;
    if (!M(desc)->b || !M(desc)->c) { if (err) *err = mkn("NSError"); return nil; }
    id ca = attach_at(M(desc)->a, c, 0);
    if (prop(ca, "setPixelFormat:") != 80) g_pso_format_ok = false;
    if (prop(ca, "setBlendingEnabled:") != 1 || prop(ca, "setSourceRGBBlendFactor:") != 1 ||
        prop(ca, "setDestinationRGBBlendFactor:") != 5) g_pso_blend_ok = false;
    id p = mkn("MockPipeline");
    const char *fs = M(M(desc)->c)->s;
    M(p)->fmt = !strcmp(fs, "fs_shape") ? 0 : !strcmp(fs, "fs_text") ? 1 : 2;
    g_pipelines++;
    return p;
}
static id texdesc_make(id self, SEL c, NSUInteger fmt, NSUInteger w, NSUInteger h, BOOL mip)
{
    (void)self; (void)c; (void)mip;
    id d = mkn("MTLTextureDescriptor");
    M(d)->fmt = (int)fmt;
    M(d)->w = (int)w;
    M(d)->h = (int)h;
    return d;
}
static int bpp_of(int fmt) { return fmt == 80 ? 4 : fmt == 10 ? 1 : 0; }
static id dev_texture(id self, SEL c, id d)
{
    (void)self; (void)c;
    int bpp = bpp_of(M(d)->fmt);
    if (!bpp) fatal("texture format %d", M(d)->fmt);
    id t = mkn("MockTexture");
    M(t)->w = M(d)->w;
    M(t)->h = M(d)->h;
    M(t)->fmt = M(d)->fmt;
    M(t)->len = (size_t)M(d)->w * M(d)->h * bpp;
    M(t)->mem = (uint8_t *)malloc(M(t)->len);
    memset(M(t)->mem, 0xCD, M(t)->len);                /* as undefined memory */
    g_textures++;
    return t;
}
static void tex_replace(id self, SEL c, PnsRegion r, NSUInteger level, const void *bytes, NSUInteger bpr)
{
    (void)c;
    MObj *t = M(self);
    int bpp = bpp_of(t->fmt);
    if (level != 0 || r.origin.z != 0 || r.size.depth != 1) fatal("replaceRegion: level/depth");
    if (r.origin.x + r.size.width > (NSUInteger)t->w || r.origin.y + r.size.height > (NSUInteger)t->h)
        fatal("replaceRegion: %ux%u outside the %dx%d texture", (unsigned)r.size.width, (unsigned)r.size.height, t->w, t->h);
    if (bpr < r.size.width * bpp) fatal("replaceRegion: bytesPerRow %u too small", (unsigned)bpr);
    for (NSUInteger y = 0; y < r.size.height; y++)
        memcpy(t->mem + ((r.origin.y + y) * t->w + r.origin.x) * bpp, (const uint8_t *)bytes + y * bpr, r.size.width * bpp);
}
static id dev_buffer(id self, SEL c, NSUInteger len, NSUInteger opts)
{
    (void)self; (void)c; (void)opts;
    id b = mkn("MockBuffer");
    M(b)->len = len;
    M(b)->mem = (uint8_t *)calloc(1, len);
    g_buffers++;
    return b;
}
static void *buf_contents(id self, SEL c) { (void)c; return M(self)->mem; }

static id rp_make(id self, SEL c)
{
    (void)self; (void)c;
    id r = mkn("MTLRenderPassDescriptor");
    M(r)->a = mkn("MockAttachArray");
    M(M(r)->a)->s = _strdup("MockPassAttach");
    return r;
}
static void pass_clear(id self, SEL c, PnsClearColor col)
{
    (void)c;
    M(self)->v[0] = col.red; M(self)->v[1] = col.green; M(self)->v[2] = col.blue; M(self)->v[3] = col.alpha;
}

/* the encoder: what is bound, and the draws done in software */
typedef struct { id pso, vbuf, ftex; NSUInteger voff; float screen[2]; uint8_t fbytes[64]; bool has_screen; } EncState;

static uint32_t argb_blend(uint32_t d, float r, float g, float b, float a)
{
    float dr = ((d >> 16) & 255) / 255.f, dg = ((d >> 8) & 255) / 255.f, db = (d & 255) / 255.f;
    dr = r + dr * (1 - a); dg = g + dg * (1 - a); db = b + db * (1 - a);
    int R = (int)(fminf(fmaxf(dr, 0), 1) * 255 + 0.5f), G = (int)(fminf(fmaxf(dg, 0), 1) * 255 + 0.5f), B = (int)(fminf(fmaxf(db, 0), 1) * 255 + 0.5f);
    return (uint32_t)(R << 16 | G << 8 | B);
}

static float clampf(float v, float lo, float hi) { return v < lo ? lo : v > hi ? hi : v; }

static void sample_bgra(const MObj *t, float u, float v, float out[3])
{
    /* linear filter, clamp to edge: texel centres at (i + 0.5) / size */
    float x = u * t->w - 0.5f, y = v * t->h - 0.5f;
    int x0 = (int)floorf(x), y0 = (int)floorf(y);
    float fx = x - x0, fy = y - y0;
    float acc[3] = { 0, 0, 0 };
    for (int k = 0; k < 4; k++) {
        int xx = x0 + (k & 1), yy = y0 + (k >> 1);
        xx = xx < 0 ? 0 : xx >= t->w ? t->w - 1 : xx;
        yy = yy < 0 ? 0 : yy >= t->h ? t->h - 1 : yy;
        float wgt = ((k & 1) ? fx : 1 - fx) * ((k >> 1) ? fy : 1 - fy);
        const uint8_t *p = t->mem + ((size_t)yy * t->w + xx) * 4;
        acc[0] += p[2] * wgt; acc[1] += p[1] * wgt; acc[2] += p[0] * wgt;      /* B, G, R in memory */
    }
    for (int i = 0; i < 3; i++) out[i] = acc[i] / 255.f;
}

static void raster(EncState *e, NSUInteger prim, NSUInteger count)
{
    const float *v = (const float *)(M(e->vbuf)->mem + e->voff);
    int kind = M(e->pso)->fmt;
    if (kind == 0 && prim == 4 && count == 4) {
        float rect[4], col[4], bor[4], rad, bw;
        memcpy(rect, e->fbytes, 16); memcpy(col, e->fbytes + 16, 16); memcpy(bor, e->fbytes + 32, 16);
        memcpy(&rad, e->fbytes + 48, 4); memcpy(&bw, e->fbytes + 52, 4);
        int x0 = (int)v[0], y0 = (int)v[1], x1 = (int)ceilf(v[12]), y1 = (int)ceilf(v[13]);
        for (int y = y0 < 0 ? 0 : y0; y < y1 && y < g_sh; y++)
            for (int x = x0 < 0 ? 0 : x0; x < x1 && x < g_sw; x++) {
                float qx = fabsf(x + 0.5f - rect[0]) - (rect[2] - rad), qy = fabsf(y + 0.5f - rect[1]) - (rect[3] - rad);
                float d = sqrtf(fmaxf(qx, 0) * fmaxf(qx, 0) + fmaxf(qy, 0) * fmaxf(qy, 0)) + fminf(fmaxf(qx, qy), 0) - rad;
                float cov = clampf(0.5f - d, 0, 1);
                float inb = bw > 0 ? clampf(0.5f + d + bw, 0, 1) : 0;
                float af = col[3] * cov * (1 - inb), ab = bor[3] * cov * inb;
                float a = ab + af * (1 - ab);
                if (a <= 0) continue;
                uint32_t *p = &g_screen_px[(size_t)y * g_sw + x];
                *p = argb_blend(*p, bor[0] * ab + col[0] * af * (1 - ab), bor[1] * ab + col[1] * af * (1 - ab),
                                bor[2] * ab + col[2] * af * (1 - ab), a);
            }
    } else if (kind == 1 && prim == 3 && count % 6 == 0) {
        float col[4];
        memcpy(col, e->fbytes, 16);
        const MObj *t = M(e->ftex);
        for (NSUInteger g = 0; g < count / 6; g++) {
            const float *q = v + g * 24;
            float gx0 = q[0], gy0 = q[1], u0 = q[2], v0 = q[3], gx1 = q[16], gy1 = q[17], u1 = q[18], v1 = q[19];
            for (int y = (int)gy0; y < (int)ceilf(gy1) && y < g_sh; y++)
                for (int x = (int)gx0; x < (int)ceilf(gx1) && x < g_sw; x++) {
                    if (x < 0 || y < 0) continue;
                    float fu = u0 + (x + 0.5f - gx0) / (gx1 - gx0) * (u1 - u0), fv = v0 + (y + 0.5f - gy0) / (gy1 - gy0) * (v1 - v0);
                    int tx = (int)(fu * t->w), ty = (int)(fv * t->h);
                    if (tx < 0 || ty < 0 || tx >= t->w || ty >= t->h) continue;
                    float a = t->mem[ty * t->w + tx] / 255.f * col[3];
                    if (a <= 0) continue;
                    uint32_t *p = &g_screen_px[(size_t)y * g_sw + x];
                    *p = argb_blend(*p, col[0] * a, col[1] * a, col[2] * a, a);
                }
        }
    } else if (kind == 2 && prim == 4 && count == 4) {
        /* (the filters DOT and LCD are not drawn here: the sharp pixels, in the colours chosen) */
        float texsize[2], scale[2], fsize[2], colors;
        memcpy(texsize, e->fbytes + 16, 8); memcpy(scale, e->fbytes + 24, 8); memcpy(fsize, e->fbytes + 32, 8);
        memcpy(&colors, e->fbytes + 44, 4);
        const MObj *t = M(e->ftex);
        float x0 = v[0], y0 = v[1], x1 = v[12], y1 = v[13], fw = v[14], fh = v[15];
        for (int y = (int)y0; y < (int)ceilf(y1) && y < g_sh; y++)
            for (int x = (int)x0; x < (int)ceilf(x1) && x < g_sw; x++) {
                if (x < 0 || y < 0) continue;
                float uv[2] = { (x + 0.5f - x0) / (x1 - x0) * fw, (y + 0.5f - y0) / (y1 - y0) * fh };
                float s[2];
                for (int k = 0; k < 2; k++) {
                    float tt = floorf(uv[k]), c = uv[k] - tt - 0.5f, range = 0.5f - 0.5f / scale[k];
                    float f = (c - clampf(c, -range, range)) * scale[k] + 0.5f;
                    s[k] = clampf(tt + f, 0.5f, fsize[k] - 0.5f) / texsize[k];
                }
                float rgb[3];
                sample_bgra(t, s[0], s[1], rgb);
                if (colors > 0.5f) {
                    float l = rgb[0] * 0.299f + rgb[1] * 0.587f + rgb[2] * 0.114f;
                    rgb[0] = rgb[1] = rgb[2] = l;
                    if (colors > 1.5f) {
                        static const float gb[4][3] = { { 0.0588f, 0.2196f, 0.0588f }, { 0.1882f, 0.3843f, 0.1882f },
                                                        { 0.5451f, 0.6745f, 0.0588f }, { 0.6078f, 0.7373f, 0.0588f } };
                        float tt = l * 3;
                        int i = tt < 1 ? 0 : tt < 2 ? 1 : 2;
                        for (int k = 0; k < 3; k++) rgb[k] = gb[i][k] + (gb[i + 1][k] - gb[i][k]) * (tt - i);
                    }
                }
                g_screen_px[(size_t)y * g_sw + x] = argb_blend(0, rgb[0], rgb[1], rgb[2], 1);
            }
    } else {
        fatal("draw: pipeline %d with primitive %u x %u", kind, (unsigned)prim, (unsigned)count);
    }
}

static id cb_make(id self, SEL c) { (void)self; (void)c; return mkn("MockCommandBuffer"); }
static id cb_encoder(id self, SEL c, id rpd)
{
    (void)self; (void)c;
    id ca = attach_at(M(rpd)->a, c, 0);
    id tex = (id)(uintptr_t)prop(ca, "setTexture:");
    if (!tex || M(tex)->w != g_sw || M(tex)->h != g_sh) fatal("render pass: not the drawable's texture");
    if (prop(ca, "setLoadAction:") != 2 || prop(ca, "setStoreAction:") != 1) fatal("render pass: load / store actions");
    id e = mkn("MockEncoder");
    M(e)->mem = (uint8_t *)calloc(1, sizeof(EncState));
    if (g_capture[0] && g_screen_px) {
        uint32_t clear = argb_blend(0, (float)M(ca)->v[0], (float)M(ca)->v[1], (float)M(ca)->v[2], 1);
        for (size_t i = 0; i < (size_t)g_sw * g_sh; i++) g_screen_px[i] = clear;
    }
    return e;
}
#define ENC(e) ((EncState *)M(e)->mem)
static void enc_pso(id self, SEL c, id p) { (void)c; ENC(self)->pso = p; }
static void enc_vbytes(id self, SEL c, const void *b, NSUInteger len, NSUInteger idx)
{
    (void)c;
    if (len > 4096) fatal("setVertexBytes: %u bytes (4 KB at most)", (unsigned)len);
    if (idx == 1 && len == 8) { memcpy(ENC(self)->screen, b, 8); ENC(self)->has_screen = true; }
    else fatal("setVertexBytes: index %u", (unsigned)idx);
}
static void enc_vbuf(id self, SEL c, id buf, NSUInteger off, NSUInteger idx)
{
    (void)c;
    if (idx != 0 || off % 16 || off >= M(buf)->len) fatal("setVertexBuffer: index %u offset %u", (unsigned)idx, (unsigned)off);
    ENC(self)->vbuf = buf;
    ENC(self)->voff = off;
}
static void enc_fbytes(id self, SEL c, const void *b, NSUInteger len, NSUInteger idx)
{
    (void)c;
    if (idx != 0 || len > 64) fatal("setFragmentBytes: index %u, %u bytes", (unsigned)idx, (unsigned)len);
    memset(ENC(self)->fbytes, 0, 64);
    memcpy(ENC(self)->fbytes, b, len);
}
static void enc_ftex(id self, SEL c, id t, NSUInteger idx) { (void)c; if (idx != 0) fatal("setFragmentTexture: index"); ENC(self)->ftex = t; }
static void enc_draw(id self, SEL c, NSUInteger prim, NSUInteger start, NSUInteger count)
{
    (void)c;
    EncState *e = ENC(self);
    if (!e->pso || !e->vbuf || start != 0) fatal("draw: no pipeline / vertices");
    if (!e->has_screen || e->screen[0] != (float)g_sw || e->screen[1] != (float)g_sh) g_screen_uniform_ok = false;
    if (e->voff + count * 16 > M(e->vbuf)->len) fatal("draw: vertices beyond the buffer");
    int kind = M(e->pso)->fmt;
    if (kind != 0 && !e->ftex) fatal("draw: no texture");
    g_draws[kind]++;
    if (g_capture[0] && g_screen_px) raster(e, prim, count);
}
static void cb_present(id self, SEL c, id d) { (void)c; M(self)->a = d; }
static void cb_commit(id self, SEL c)
{
    (void)c;
    if (!M(self)->a) fatal("commit without presentDrawable");
    g_frames_presented++;
    if (g_capture[0] && g_screen_px) {
        png_write_rgb(g_capture, g_screen_px, g_sw, g_sh, g_sw, 1);
        printf("  shot  %s\n", g_capture);
        g_capture[0] = 0;
    }
}

/* ------------------------------------------------------------------ GameController */

static id gc_controllers(id self, SEL c)
{
    (void)self; (void)c;
    if (!g_pad_connected) return marr(NULL, 0);
    static id ctl;
    if (!ctl) { ctl = mkn("GCController"); M(ctl)->a = g_gamepad = mkn("MockGamepad"); }
    return marr(&ctl, 1);
}
static id gc_extended(id self, SEL c) { (void)c; return M(self)->a; }
/* the elements of a gamepad (and of its direction pads), by the name of the getter */
static id gp_child(id self, SEL c)
{
    MObj *o = M(self);
    if (!o->items) o->items = (id *)calloc(16, sizeof(id));
    for (int i = 0; i < o->n; i++) if (M(o->items[i])->sel == c) return o->items[i];
    if (o->n >= 16) fatal("gamepad elements");
    bool pad = !strcmp((const char *)c, "dpad") || !strcmp((const char *)c, "leftThumbstick");
    id e = mkn(pad ? "MockGamepad" : "MockButton");
    M(e)->sel = c;
    o->items[o->n++] = e;
    return e;
}
static BOOL btn_pressed(id self, SEL c) { (void)c; return M(self)->v[0] != 0; }
static void pad_press(const char *name, const char *sub, bool on)
{
    id e = MSG0(id, g_gamepad, name);
    if (sub) e = MSG0(id, e, sub);
    M(e)->v[0] = on ? 1 : 0;
}

static void app_suspend_sel(id self, SEL c) { (void)self; (void)c; g_suspended++; }
static id app_shared(id self, SEL c) { (void)self; (void)c; return g_app_obj; }
static BOOL resp_become_first(id self, SEL c) { (void)self; (void)c; g_first_responder++; return YES; }
static id press_key(id self, SEL c) { (void)c; return M(self)->a; }
static NSInteger key_code(id self, SEL c) { (void)c; return (NSInteger)M(self)->v[0]; }

/* ------------------------------------------------------------------ CoreMotion */

static BOOL mm_available(id self, SEL c) { (void)self; (void)c; return YES; }
static void mm_interval(id self, SEL c, double v) { (void)self; (void)c; g_accel_interval = v; }
static void mm_start(id self, SEL c, id queue, id handler)
{
    (void)self; (void)c;
    if (!queue) fatal("startAccelerometerUpdatesToQueue: no queue");
    g_accel_fn = (void (*)(id, id))(void *)handler;
    g_accel_running = true;
    g_acc_t = g_now;
}
static void mm_stop(id self, SEL c) { (void)self; (void)c; g_accel_running = false; }
static PnsAcceleration acc_value(id self, SEL c)
{
    (void)c;
    PnsAcceleration a = { M(self)->v[0], M(self)->v[1], M(self)->v[2] };
    return a;
}
static double acc_time(id self, SEL c) { (void)c; return M(self)->v[3]; }

/* the accelerometer: the phone held upright, still, and the jolts asked for; in g, as iOS gives them
 * (gravity pulls: -1 on y held upright; a push to the right reads x < 0 there, x > 0 on Android) */
static void accel_feed(void)
{
    while (g_accel_running && g_acc_t + 0.01 <= g_now) {
        g_acc_t += 0.01;
        double x = 0;
        double since = g_acc_t - g_jolt_t;
        if (since >= 0 && since < 0.02) x = g_jolt_x;                 /* the tap: 20 ms */
        else if (since >= 0.02 && since < 0.03) x = -0.4 * g_jolt_x;  /* the hand stops it */
        id d = mkn("CMAccelerometerData");
        M(d)->v[0] = -x / 9.80665;
        M(d)->v[1] = -1.0;
        M(d)->v[2] = 0.0;
        M(d)->v[3] = g_acc_t;
        g_accel_fn(d, nil);
    }
}

/* ------------------------------------------------------------------ AudioToolbox */

typedef struct { AURenderCallbackStruct cb; AudioStreamBasicDescription f; bool has_cb, has_f, init, started; } MockUnit;
static MockUnit *g_unit;
static int g_units_made, g_units_disposed;
static long g_samples, g_samples_nonzero;
static bool g_audio_stall;
static int g_audio_format_ok = -1;
static int g_component_marker;

AudioComponent AudioComponentFindNext(AudioComponent in, const AudioComponentDescription *d)
{
    if (in || !d) return NULL;
    if (d->componentType != 0x61756F75 || d->componentSubType != 0x72696F63 || d->componentManufacturer != 0x6170706C) return NULL;
    return (AudioComponent)&g_component_marker;
}
OSStatus AudioComponentInstanceNew(AudioComponent c, AudioComponentInstance *out)
{
    if (c != (AudioComponent)&g_component_marker || !out) return -50;
    if (g_unit) fatal("a second audio unit while one is open");
    g_unit = (MockUnit *)calloc(1, sizeof *g_unit);
    g_units_made++;
    *out = (AudioComponentInstance)g_unit;
    return 0;
}
OSStatus AudioComponentInstanceDispose(AudioComponentInstance u)
{
    if ((MockUnit *)u != g_unit) fatal("dispose: not the open unit");
    free(g_unit);
    g_unit = NULL;
    g_units_disposed++;
    return 0;
}
OSStatus AudioUnitSetProperty(AudioUnit u, AudioUnitPropertyID id_, AudioUnitScope scope, AudioUnitElement el,
                              const void *data, UInt32 size)
{
    MockUnit *m = (MockUnit *)u;
    if (m != g_unit || el != 0) return -50;
    if (id_ == 8 && scope == 1 && size == sizeof(AudioStreamBasicDescription)) {
        memcpy(&m->f, data, size);
        m->has_f = true;
        g_audio_format_ok = m->f.mSampleRate == 48000 && m->f.mFormatID == 0x6C70636D && m->f.mChannelsPerFrame == 2 &&
                            m->f.mBitsPerChannel == 16 && m->f.mBytesPerFrame == 4 && (m->f.mFormatFlags & 4) && (m->f.mFormatFlags & 8) &&
                            !(m->f.mFormatFlags & 32);
        return 0;
    }
    if (id_ == 23 && scope == 1 && size == sizeof(AURenderCallbackStruct)) {
        memcpy(&m->cb, data, size);
        m->has_cb = true;
        return 0;
    }
    return -10879;                                     /* kAudioUnitErr_InvalidProperty */
}
OSStatus AudioUnitInitialize(AudioUnit u) { MockUnit *m = (MockUnit *)u; if (!m->has_f || !m->has_cb) return -10867; m->init = true; return 0; }
OSStatus AudioUnitUninitialize(AudioUnit u) { ((MockUnit *)u)->init = false; return 0; }
OSStatus AudioOutputUnitStart(AudioUnit u) { MockUnit *m = (MockUnit *)u; if (!m->init) return -10867; m->started = true; return 0; }
OSStatus AudioOutputUnitStop(AudioUnit u) { ((MockUnit *)u)->started = false; return 0; }

static void audio_pull(int frames)
{
    if (!g_unit || !g_unit->started || g_audio_stall) return;
    static int16_t buf[4096 * 2];
    AudioBufferList abl;
    abl.mNumberBuffers = 1;
    abl.mBuffers[0].mNumberChannels = 2;
    abl.mBuffers[0].mDataByteSize = (UInt32)frames * 4;
    abl.mBuffers[0].mData = buf;
    AudioUnitRenderActionFlags flags = 0;
    g_unit->cb.inputProc(g_unit->cb.inputProcRefCon, &flags, NULL, 0, (UInt32)frames, &abl);
    for (int i = 0; i < frames * 2; i++) { g_samples++; if (buf[i]) g_samples_nonzero++; }
}

/* ------------------------------------------------------------------ the scenario */

static void tick(int n)
{
    for (int k = 0; k < n; k++) {
        g_now += 1.0 / 60;
        audio_pull(800);
        accel_feed();
        if (g_link && g_link_added && !prop(g_link, "setPaused:"))
            MSG1(void, id, M(g_link)->a, (const char *)M(g_link)->sel, g_link);
    }
}

static id g_finger[UI_MAX_POINTERS];
enum { T_DOWN, T_MOVE, T_UP, T_CANCEL };
static void touch(int action, int finger, double x_px, double y_px)
{
    if (!g_finger[finger]) g_finger[finger] = mkn("UITouch");
    id t = g_finger[finger];
    M(t)->v[0] = x_px / SCR_SCALE;
    M(t)->v[1] = y_px / SCR_SCALE;
    id set = mkn("NSSet");
    M(set)->items = (id *)calloc(1, sizeof(id));
    M(set)->items[0] = t;
    M(set)->n = 1;
    static const char *const sel[4] = { "touchesBegan:withEvent:", "touchesMoved:withEvent:", "touchesEnded:withEvent:", "touchesCancelled:withEvent:" };
    MSG(void, (id, id), g_view, sel[action], set, mkn("UIEvent"));
    if (action == T_UP || action == T_CANCEL) g_finger[finger] = nil;    /* iOS: a new UITouch next time */
}
static void tap(double x, double y) { touch(T_DOWN, 0, x, y); tick(3); touch(T_UP, 0, x, y); tick(3); }

static void shot(const char *name)
{
    snprintf(g_capture, sizeof g_capture, "%s/ios_%s.png", g_out, name);
    tick(1);
    if (g_capture[0]) { printf("  (no frame drawn for %s)\n", name); g_capture[0] = 0; }
}

static void pick(const char *path)
{
    id picker = M(g_vc)->b;
    M(g_vc)->b = nil;                                  /* UIKit dismisses the picker, then tells the delegate */
    id url = mkurl(path);
    id del = (id)(uintptr_t)prop(picker, "setDelegate:");
    MSG(void, (id, id), del, "documentPicker:didPickDocumentsAtURLs:", picker, marr(&url, 1));
}

static bool file_exists(const char *p) { FILE *f = fopen(p, "rb"); if (f) fclose(f); return f != NULL; }

static void key_centre(int key, double *x, double *y)
{
    MobileApp *a = pns_mock_app();
    NdRect r = a->ui.nd.btn[key];
    *x = (r.x + r.w / 2.0) * a->ui.nd.scale;
    *y = (r.y + r.h / 2.0) * a->ui.nd.scale;
}

static void tap_menu_item(int i)
{
    UiRect r = ui_menu_item(&pns_mock_app()->ui, i);
    tap(r.x + r.w / 2, r.y + r.h / 2);
}

static bool reach_table(void)
{
    MobileApp *a = pns_mock_app();
    g_pad_connected = true;
    tick(2);
    for (int t = 0; t < 4000 && !pb_playing(a->pb); t += 60) {
        const char *b = t < 600 ? "buttonMenu" : "buttonA";       /* START on the title, then A */
        pad_press(b, NULL, true);
        tick(6);
        pad_press(b, NULL, false);
        tick(54);
    }
    g_pad_connected = false;
    tick(2);
    return pb_playing(a->pb);
}

static void scenario_first(void)
{
    MobileApp *a = pns_mock_app();
    tick(30);
    CHECK(!app_has_game(a) && a->ui.no_rom, "no ROM: the explanation screen");
    shot("norom");
    CHECK(g_draws[0] > 0 && g_draws[1] > 0, "explanation drawn with shapes (%d) and text (%d)", g_draws[0], g_draws[1]);
    tap(SCR_W_PT * SCR_SCALE / 2, SCR_H_PT * SCR_SCALE / 2);
    id picker = M(g_vc)->b;
    CHECK(picker && !strcmp(class_getName(picker->isa), "UIDocumentPickerViewController"), "a tap opens the document picker");
    if (!picker) return;
    CHECK(M(picker)->v[0] == 1 && M(M(picker)->a)->n == 1, "picker: a copy of one file of type public.data");
    tap(100, 100);
    CHECK(g_presented == 1, "no second picker while one is shown");
    char bad[700];
    snprintf(bad, sizeof bad, "%s/Library/not a rom.gbc", g_home);
    FILE *f = fopen(bad, "wb");
    if (f) { fputs("this is not a ROM", f); fclose(f); }
    pick(bad);
    tick(10);
    CHECK(!app_has_game(a) && a->ui.no_rom_detail[0], "a wrong file is refused: \"%.60s...\"", a->ui.no_rom_detail);
    shot("wrongfile");
    tap(500, 1200);
    CHECK(M(g_vc)->b != nil, "the picker opens again");
    pick(g_rom);
    CHECK(app_has_game(a), "the ROM chosen in the picker is installed");
    CHECK(g_scoped_start == g_scoped_stop && g_scoped_start == 2, "security-scoped access opened and closed (%d)", g_scoped_start);

    long f0 = a->pb->st.frame;
    long s0 = g_samples_nonzero;
    tick(600);
    long frames = a->pb->st.frame - f0;
    CHECK(frames > 580 && frames < 620, "600 display frames: %ld game frames (paced by the screen)", frames);
    CHECK(g_samples_nonzero - s0 > 100000, "sound played (%ld non-zero samples)", g_samples_nonzero - s0);
    CHECK(g_audio_format_ok == 1, "audio unit: 48 kHz, 16-bit stereo interleaved");
    shot("title");

    CHECK(reach_table(), "a game controller starts a game (START, A...)");
    tick(240);
    shot("table");
    CHECK(a->ui.field && a->ui.nd.scene != ND_SCENE_SCREEN, "on the table: its keys and panel (scene %d)", a->ui.nd.scene);

    /* the flipper keys under the game, two fingers at once */
    double lx, ly, rx, ry;
    key_centre(ND_LFLIP, &lx, &ly);
    key_centre(ND_RFLIP, &rx, &ry);
    int imp0 = g_impacts[0] + g_impacts[1] + g_impacts[2];
    touch(T_DOWN, 0, lx, ly);
    touch(T_DOWN, 1, rx, ry);
    tick(2);
    uint8_t b = ui_buttons(&a->ui);
    CHECK((b & GBC_LEFT) && (b & GBC_A), "two fingers on the flipper keys: both flippers (buttons %02X)", b);
    touch(T_UP, 0, lx, ly);
    tick(2);
    b = ui_buttons(&a->ui);
    CHECK(!(b & GBC_LEFT) && (b & GBC_A), "left finger lifted: right flipper only (%02X)", b);
    touch(T_UP, 1, rx, ry);
    tick(2);
    CHECK(ui_buttons(&a->ui) == 0, "all fingers lifted: no button");

    /* GAME TOUCH: TILT (the default): the thirds of the game give the left and right tilts */
    float gx, gy, gw, gh;
    nd_game_rect(&a->ui.nd, &gx, &gy, &gw, &gh);
    touch(T_DOWN, 0, gx + gw * 0.15, gy + gh * 0.8);
    tick(2);
    CHECK(ui_buttons(&a->ui) == GBC_DOWN, "a finger on the left third of the game: the left tilt (%02X)", ui_buttons(&a->ui));
    touch(T_UP, 0, gx + gw * 0.15, gy + gh * 0.8);
    touch(T_DOWN, 0, gx + gw * 0.85, gy + gh * 0.8);
    tick(2);
    CHECK(ui_buttons(&a->ui) == GBC_B, "a finger on the right third: the right tilt (%02X)", ui_buttons(&a->ui));
    touch(T_UP, 0, gx + gw * 0.85, gy + gh * 0.8);
    tick(2);
    CHECK(g_impacts[0] + g_impacts[1] + g_impacts[2] > imp0, "haptic feedback on the keys (%d)", g_impacts[0] + g_impacts[1] + g_impacts[2] - imp0);
    touch(T_DOWN, 0, gx + gw * 0.25, gy + gh * 0.6);
    tick(2);
    MSG(void, (id, id), g_view, "touchesCancelled:withEvent:", marr(NULL, 0), nil);
    tick(2);
    CHECK(ui_buttons(&a->ui) == 0, "touches cancelled by the system: no button left pressed");
    g_finger[0] = nil;

    /* a keyboard (UIPress): X is the right flipper, as on Android */
    CHECK(g_first_responder > 0, "the view controller takes the keys (first responder)");
    id key = mkn("UIKey");
    M(key)->v[0] = 0x1B;
    id pr = mkn("UIPress");
    M(pr)->a = key;
    id prs = mkn("NSSet");
    M(prs)->items = (id *)calloc(1, sizeof(id));
    M(prs)->items[0] = pr;
    M(prs)->n = 1;
    MSG(void, (id, id), g_vc, "pressesBegan:withEvent:", prs, mkn("UIEvent"));
    tick(1);
    CHECK(ui_buttons(&a->ui) & GBC_A, "keyboard X: the right flipper (%02X)", ui_buttons(&a->ui));
    MSG(void, (id, id), g_vc, "pressesEnded:withEvent:", prs, mkn("UIEvent"));
    tick(1);
    CHECK(!(ui_buttons(&a->ui) & GBC_A), "X released");

    /* the controller's home button: the menu (taken from the system) */
    g_pad_connected = true;
    tick(2);
    pad_press("buttonHome", NULL, true);
    tick(2);
    CHECK(a->ui.menu_open, "the controller's home button opens the menu");
    CHECK(prop(MSG0(id, g_gamepad, "buttonHome"), "setPreferredSystemGestureState:") == 2, "home button: system gesture disabled");
    pad_press("buttonHome", NULL, false);
    tick(2);
    pad_press("buttonHome", NULL, true);
    tick(2);
    pad_press("buttonHome", NULL, false);
    tick(2);
    CHECK(!a->ui.menu_open, "pressed again: the menu closes");
    g_pad_connected = false;
    tick(2);

    /* MOTION TILT: taps on the sides of the phone */
    a->ui.motion = true;
    tick(30);
    CHECK(g_accel_running && g_accel_interval > 0 && g_accel_interval <= 0.01, "MOTION TILT on: the accelerometer runs (%.0f Hz asked)",
          g_accel_interval > 0 ? 1 / g_accel_interval : 0.0);
    int tilts = 0;
    g_jolt_t = g_now + 0.05;
    g_jolt_x = 5.0;                                    /* the left side tapped: pushed to the right */
    for (int k = 0; k < 12; k++) { tick(1); if (ui_buttons(&a->ui) & GBC_DOWN) tilts |= 1; if (ui_buttons(&a->ui) & GBC_B) tilts |= 4; }
    CHECK(tilts == 1, "a tap on the left side: the left tilt (DOWN) (%d)", tilts);
    tick(60);
    CHECK(!(ui_buttons(&a->ui) & (GBC_DOWN | GBC_B | GBC_SELECT)), "the tilt released");
    tilts = 0;
    g_jolt_t = g_now + 0.05;
    g_jolt_x = -5.0;                                   /* the right side tapped */
    for (int k = 0; k < 12; k++) { tick(1); if (ui_buttons(&a->ui) & GBC_DOWN) tilts |= 1; if (ui_buttons(&a->ui) & GBC_B) tilts |= 4; }
    CHECK(tilts == 4, "a tap on the right side: the right tilt (B) (%d)", tilts);
    tick(60);
    a->ui.motion = false;
    tick(2);
    CHECK(!g_accel_running, "MOTION TILT off: the accelerometer stopped");

    /* the sound card stops taking samples (an interruption): the clock sets the pace */
    f0 = a->pb->st.frame;
    g_audio_stall = true;
    tick(120);
    g_audio_stall = false;
    frames = a->pb->st.frame - f0;
    CHECK(frames > 90, "sound card stalled for 2 s: the game goes on (%ld frames)", frames);
    tick(60);

    /* the menu */
    double mx, my;
    key_centre(ND_MENU, &mx, &my);
    tap(mx, my);
    CHECK(a->ui.menu_open, "the MENU key opens the menu");
    shot("menu");
    int made = g_units_made;
    tap_menu_item(4);
    tick(2);
    CHECK(!a->ui.sound && !g_unit, "SOUND : OFF closes the audio unit");
    f0 = a->pb->st.frame;
    tap_menu_item(4);
    tick(2);
    CHECK(a->ui.sound && g_unit && g_units_made == made + 1, "SOUND : ON opens it again");
    tap_menu_item(0);
    CHECK(!a->ui.menu_open, "RESUME closes the menu");
    f0 = a->pb->st.frame;
    tick(120);
    CHECK(a->pb->st.frame - f0 > 110, "the game runs again (%ld frames)", a->pb->st.frame - f0);

    /* to the background and back */
    char st[800];
    snprintf(st, sizeof st, "%s/Library/Application Support/Pinball NS/suspend.state", g_home);
    MSG1(void, id, g_scene_delegate, "sceneWillResignActive:", g_scene);
    CHECK(prop(g_link, "setPaused:") == 1 && !g_unit, "inactive: frames paused, audio unit closed");
    CHECK(file_exists(st), "inactive: the game is saved (suspend.state)");
    f0 = a->pb->st.frame;
    tick(60);
    CHECK(a->pb->st.frame == f0, "nothing runs in the background");
    MSG1(void, id, g_scene_delegate, "sceneDidBecomeActive:", g_scene);
    tick(60);
    CHECK(prop(g_link, "setPaused:") == 0 && g_unit && a->pb->st.frame > f0 + 50, "active again: the game goes on");

    /* QUIT in the menu: saved, then the Home screen (an app of iOS does not end itself) */
    remove(st);
    a->ui.pending_action = UI_ACT_QUIT;
    tick(1);
    CHECK(g_suspended == 1 && file_exists(st), "QUIT: the game saved, the Home screen");
    MSG1(void, id, g_scene_delegate, "sceneWillResignActive:", g_scene);
}

static void scenario_resume(void)
{
    MobileApp *a = pns_mock_app();
    char st[800];
    snprintf(st, sizeof st, "%s/Library/Application Support/Pinball NS/suspend.state", g_home);
    CHECK(app_has_game(a), "started again: the installed ROM is used");
    CHECK(!file_exists(st), "the suspended game was loaded (and its file removed)");
    tick(5);
    CHECK(a->pb && pb_playing(a->pb), "the game resumes on the table");
    tick(60);
    shot("resume");
    MSG1(void, id, g_scene_delegate, "sceneWillResignActive:", g_scene);
}

static void scenario_docs(void)
{
    MobileApp *a = pns_mock_app();
    CHECK(app_has_game(a), "a ROM copied to Files > On My iPhone > Pinball NS is installed when the app becomes active");
    tick(120);
    CHECK(a->pb->st.frame > 100, "the game runs");
    MSG1(void, id, g_scene_delegate, "sceneWillResignActive:", g_scene);
}

static void scenario_openin(void)
{
    MobileApp *a = pns_mock_app();
    CHECK(app_has_game(a), "a ROM opened in Pinball NS from Files is installed");
    CHECK(g_scoped_start == 1 && g_scoped_stop == 1, "security-scoped access opened and closed");
    tick(60);
    MSG1(void, id, g_scene_delegate, "sceneWillResignActive:", g_scene);
}

static bool copy_file(const char *from, const char *to)
{
    FILE *in = fopen(from, "rb"), *out = in ? fopen(to, "wb") : NULL;
    if (!out) { if (in) fclose(in); return false; }
    static char buf[1 << 16];
    size_t n;
    while ((n = fread(buf, 1, sizeof buf, in)) > 0) fwrite(buf, 1, n, out);
    fclose(in);
    fclose(out);
    return true;
}

static void scenario_ips(void)
{
    MobileApp *a = pns_mock_app();
    CHECK(app_has_game(a) && !a->gen, "the US ROM of Files > On My iPhone > Pinball NS is installed");
    const char *ips = getenv("PNS_GEN_IPS");
    char dst[1200];
    snprintf(dst, sizeof dst, "%s/Documents/Pokemon Pinball Generations.ips", g_home);
    if (!ips || !copy_file(ips, dst)) { CHECK(false, "the IPS patch of Generations (PNS_GEN_IPS) copied to Files"); return; }
    MSG1(void, id, g_scene_delegate, "sceneWillResignActive:", g_scene);
    MSG1(void, id, g_scene_delegate, "sceneDidBecomeActive:", g_scene);
    tick(30);
    CHECK(a->installed[0] && a->installed[1], "the patch, copied to Files, installs Generations too");
    CHECK(a->gen, "Generations is played (the game just installed)");
    tick(300);
    shot("generations");
    MSG1(void, id, g_scene_delegate, "sceneWillResignActive:", g_scene);
    MSG1(void, id, g_scene_delegate, "sceneDidBecomeActive:", g_scene);
    tick(30);
    CHECK(a->installed[1] && a->gen, "becoming active again: nothing imported twice");
    a->ui.pending_action = UI_ACT_NEXT_GAME;
    tick(30);
    CHECK(!a->gen && app_has_game(a), "GAME in the menu: back to the original");
    MSG1(void, id, g_scene_delegate, "sceneWillResignActive:", g_scene);
}

static const char *g_scenario;

/* the scene delegate class named in Info.plist, as UIKit reads it */
static void plist_string(const char *key, char *out, size_t n)
{
    out[0] = 0;
    FILE *f = fopen("platform/ios/Info.plist", "rb");
    if (!f) return;
    static char buf[16384];
    size_t len = fread(buf, 1, sizeof buf - 1, f);
    fclose(f);
    buf[len] = 0;
    char k[200];
    snprintf(k, sizeof k, "<key>%s</key>", key);
    char *p = strstr(buf, k);
    if (!p || !(p = strstr(p, "<string>"))) return;
    p += 8;
    char *e = strstr(p, "</string>");
    if (e && (size_t)(e - p) < n) { memcpy(out, p, (size_t)(e - p)); out[e - p] = 0; }
}

int UIApplicationMain(int argc, char *argv[], id principal, id delegate_name)
{
    (void)argc; (void)argv; (void)principal;
    g_app_obj = mkn("UIApplication");
    Class dc = objc_getClass(M(delegate_name)->s);
    if (!dc) fatal("no app delegate class %s", M(delegate_name)->s);
    id del = msg(msg((id)dc, "alloc"), "init");
    BOOL ok = MSG(BOOL, (id, id), del, "application:didFinishLaunchingWithOptions:", g_app_obj, nil);
    CHECK(ok, "application:didFinishLaunchingWithOptions: returns YES");
    CHECK(prop(g_app_obj, "setIdleTimerDisabled:") == 1, "the screen stays on");

    char name[100];
    plist_string("UISceneDelegateClassName", name, sizeof name);
    Class sc = objc_getClass(name);
    CHECK(sc != NULL, "Info.plist: the scene delegate class \"%s\" exists", name);
    if (!sc) return 1;
    g_scene_delegate = msg(msg((id)sc, "alloc"), "init");
    g_scene = mkn("UIWindowScene");
    id options = mkn("UISceneConnectionOptions");
    if (!strcmp(g_scenario, "openin")) {
        id ctx = mkn("UIOpenURLContext");
        M(ctx)->a = mkurl(g_rom);
        id set = mkn("NSSet");
        M(set)->items = (id *)calloc(1, sizeof(id));
        M(set)->items[0] = ctx;
        M(set)->n = 1;
        M(options)->a = set;
    }
    MSG(void, (id, id, id), g_scene_delegate, "scene:willConnectToSession:options:", g_scene, mkn("UISceneSession"), options);
    CHECK(g_vc && g_view && g_layer, "the window shows the view controller, its view has a CAMetalLayer");
    CHECK(MSG0(id, g_scene_delegate, "window") == g_window, "the scene delegate's window");
    CHECK(prop(g_view, "setMultipleTouchEnabled:") == 1, "multi-touch on");
    CHECK(MSG0(BOOL, g_vc, "prefersStatusBarHidden") && MSG0(NSUInteger, g_vc, "supportedInterfaceOrientations") == 2 &&
          MSG0(NSUInteger, g_vc, "preferredScreenEdgesDeferringSystemGestures") == 15, "status bar hidden, portrait, system swipes deferred");
    CHECK(prop(g_layer, "setPixelFormat:") == 80 && prop_d(g_layer, "setContentsScale:") == SCR_SCALE &&
          prop(g_layer, "setDevice:") == (uint64_t)(uintptr_t)g_device, "Metal layer: BGRA8, x3, the device");
    CHECK(g_source_ok && g_pipelines == 3 && g_pso_format_ok && g_pso_blend_ok, "shaders and 3 pipelines (BGRA8, premultiplied blending)");
    CHECK(g_textures == 1 + MR_FRAMES && g_buffers == MR_FRAMES, "font texture, %d canvases and vertex buffers", MR_FRAMES);
    CHECK(g_link && g_link_added && !strcmp(g_link_mode, "kCFRunLoopCommonModes") && prop(g_link, "setPreferredFramesPerSecond:") == 60,
          "display link at 60 Hz in the common modes");

    MSG1(void, id, g_scene_delegate, "sceneDidBecomeActive:", g_scene);
    tick(1);
    CHECK(g_sw == 1179 && g_sh == 2556, "drawable: %d x %d pixels", g_sw, g_sh);
    MobileApp *a = pns_mock_app();
    CHECK(a->ui.inset_t == 177 && a->ui.inset_b == 102 && a->ui.corner == 165, "safe area and corners in pixels (%d, %d, %d)",
          a->ui.inset_t, a->ui.inset_b, a->ui.corner);
    CHECK(g_frames_presented > 0, "a frame is presented");

    if (!strcmp(g_scenario, "first")) scenario_first();
    else if (!strcmp(g_scenario, "resume")) scenario_resume();
    else if (!strcmp(g_scenario, "docs")) scenario_docs();
    else if (!strcmp(g_scenario, "openin")) scenario_openin();
    else if (!strcmp(g_scenario, "ips")) scenario_ips();
    else fatal("unknown scenario %s", g_scenario);
    CHECK(g_screen_uniform_ok, "every draw had the drawable's size");
    return 0;
}

/* ------------------------------------------------------------------ the classes */

static void define_classes(void)
{
    Class c = defclass("NSObject", NULL);
    cm(c, "alloc", o_alloc);
    cm(c, "instancesRespondToSelector:", o_inst_responds);
    im(c, "init", o_self);
    im(c, "retain", o_retain);
    im(c, "release", o_release);
    im(c, "autorelease", o_self);
    im(c, "respondsToSelector:", o_responds);
    defclass("NSAutoreleasePool", "NSObject");
    c = defclass("NSString", "NSObject");
    cm(c, "stringWithUTF8String:", s_with_utf8);
    im(c, "UTF8String", s_utf8);
    im(c, "length", s_length);
    c = defclass("NSArray", "NSObject");
    cm(c, "arrayWithObject:", a_with_object);
    im(c, "count", a_count);
    im(c, "objectAtIndex:", a_at);
    c = defclass("NSSet", "NSObject");
    im(c, "allObjects", a_all);
    im(c, "count", a_count);
    c = defclass("NSURL", "NSObject");
    im(c, "path", url_path);
    im(c, "startAccessingSecurityScopedResource", url_start);
    im(c, "stopAccessingSecurityScopedResource", url_stop);
    c = defclass("NSError", "NSObject");
    im(c, "localizedDescription", err_desc);
    c = defclass("NSFileManager", "NSObject");
    cm(c, "defaultManager", fm_default);
    im(c, "contentsOfDirectoryAtPath:error:", fm_list);
    c = defclass("NSRunLoop", "NSObject");
    cm(c, "mainRunLoop", rl_main);

    c = defclass("UIResponder", "NSObject");
    im(c, "becomeFirstResponder", resp_become_first);
    c = defclass("UIApplication", "UIResponder");
    im(c, "setIdleTimerDisabled:", set_b);
    im(c, "suspend", app_suspend_sel);
    cm(c, "sharedApplication", app_shared);
    c = defclass("UIPress", "NSObject");
    im(c, "key", press_key);
    c = defclass("UIKey", "NSObject");
    im(c, "keyCode", key_code);
    defclass("NSOperationQueue", "NSObject");
    c = defclass("CMMotionManager", "NSObject");
    im(c, "isAccelerometerAvailable", mm_available);
    im(c, "setAccelerometerUpdateInterval:", mm_interval);
    im(c, "startAccelerometerUpdatesToQueue:withHandler:", mm_start);
    im(c, "stopAccelerometerUpdates", mm_stop);
    c = defclass("CMAccelerometerData", "NSObject");
    im(c, "acceleration", acc_value);
    im(c, "timestamp", acc_time);
    c = defclass("UIScreen", "NSObject");
    cm(c, "mainScreen", scr_main);
    im(c, "nativeScale", scr_scale);
    im(c, "_displayCornerRadius", scr_corner);
    c = defclass("UIColor", "NSObject");
    cm(c, "blackColor", color_black);
    c = defclass("UIView", "UIResponder");
    cm(c, "layerClass", view_layer_class);
    im(c, "initWithFrame:", view_init_frame);
    im(c, "layer", view_layer);
    im(c, "bounds", view_bounds);
    im(c, "safeAreaInsets", view_safe);
    im(c, "window", view_window);
    im(c, "setMultipleTouchEnabled:", set_b);
    im(c, "setBackgroundColor:", set_id);
    c = defclass("UIWindow", "UIView");
    im(c, "initWithWindowScene:", win_init_scene);
    im(c, "setRootViewController:", win_set_root);
    im(c, "makeKeyAndVisible", win_key_visible);
    im(c, "screen", win_screen);
    c = defclass("UIViewController", "UIResponder");
    im(c, "setView:", vc_set_view);
    im(c, "view", vc_view);
    im(c, "presentViewController:animated:completion:", vc_present);
    im(c, "presentedViewController", vc_presented);
    c = defclass("UIDocumentPickerViewController", "UIViewController");
    im(c, "initForOpeningContentTypes:asCopy:", dp_init_types);
    im(c, "initWithDocumentTypes:inMode:", dp_init_doc_types);
    im(c, "setDelegate:", set_id);
    im(c, "setAllowsMultipleSelection:", set_b);
    c = defclass("UTType", "NSObject");
    cm(c, "typeWithIdentifier:", ut_with_id);
    c = defclass("UIImpactFeedbackGenerator", "NSObject");
    im(c, "initWithStyle:", impact_init);
    im(c, "prepare", o_nop);
    im(c, "impactOccurred", impact_fire);
    c = defclass("UITouch", "NSObject");
    im(c, "locationInView:", touch_location);
    defclass("UIEvent", "NSObject");
    defclass("UIWindowScene", "NSObject");
    defclass("UISceneSession", "NSObject");
    c = defclass("UISceneConnectionOptions", "NSObject");
    im(c, "URLContexts", opts_contexts);
    c = defclass("UIOpenURLContext", "NSObject");
    im(c, "URL", ctx_url);

    c = defclass("CADisplayLink", "NSObject");
    cm(c, "displayLinkWithTarget:selector:", link_make);
    im(c, "setPreferredFramesPerSecond:", link_fps);
    im(c, "timestamp", link_timestamp);
    im(c, "addToRunLoop:forMode:", link_add);
    im(c, "setPaused:", set_b);
    c = defclass("CALayer", "NSObject");
    im(c, "setOpaque:", set_b);
    im(c, "setContentsScale:", set_d);
    c = defclass("CAMetalLayer", "CALayer");
    im(c, "setDevice:", set_id);
    im(c, "setPixelFormat:", set_u);
    im(c, "setFramebufferOnly:", set_b);
    im(c, "setDrawableSize:", layer_drawable_size);
    im(c, "nextDrawable", layer_next_drawable);
    c = defclass("MockDrawable", "NSObject");
    im(c, "texture", drawable_texture);

    c = defclass("MockDevice", "NSObject");
    im(c, "newCommandQueue", dev_queue);
    im(c, "newLibraryWithSource:options:error:", dev_library);
    im(c, "newRenderPipelineStateWithDescriptor:error:", dev_pipeline);
    im(c, "newTextureWithDescriptor:", dev_texture);
    im(c, "newBufferWithLength:options:", dev_buffer);
    c = defclass("MockLibrary", "NSObject");
    im(c, "newFunctionWithName:", lib_function);
    defclass("MockFunction", "NSObject");
    defclass("MockPipeline", "NSObject");
    c = defclass("MTLRenderPipelineDescriptor", "NSObject");
    im(c, "init", rpd_pipe_init);
    im(c, "colorAttachments", rpd_attachments);
    im(c, "setVertexFunction:", pipe_set_vertex);
    im(c, "setFragmentFunction:", pipe_set_fragment);
    c = defclass("MockAttachArray", "NSObject");
    im(c, "objectAtIndexedSubscript:", attach_at);
    c = defclass("MockAttach", "NSObject");
    im(c, "setPixelFormat:", set_u);
    im(c, "setBlendingEnabled:", set_b);
    im(c, "setSourceRGBBlendFactor:", set_u);
    im(c, "setDestinationRGBBlendFactor:", set_u);
    im(c, "setSourceAlphaBlendFactor:", set_u);
    im(c, "setDestinationAlphaBlendFactor:", set_u);
    c = defclass("MTLTextureDescriptor", "NSObject");
    cm(c, "texture2DDescriptorWithPixelFormat:width:height:mipmapped:", texdesc_make);
    im(c, "setUsage:", set_u);
    c = defclass("MockTexture", "NSObject");
    im(c, "replaceRegion:mipmapLevel:withBytes:bytesPerRow:", tex_replace);
    c = defclass("MockBuffer", "NSObject");
    im(c, "contents", buf_contents);
    c = defclass("MockQueue", "NSObject");
    im(c, "commandBuffer", cb_make);
    c = defclass("MockCommandBuffer", "NSObject");
    im(c, "renderCommandEncoderWithDescriptor:", cb_encoder);
    im(c, "presentDrawable:", cb_present);
    im(c, "commit", cb_commit);
    im(c, "waitUntilCompleted", o_nop);
    c = defclass("MTLRenderPassDescriptor", "NSObject");
    cm(c, "renderPassDescriptor", rp_make);
    im(c, "colorAttachments", rpd_attachments);
    c = defclass("MockPassAttach", "NSObject");
    im(c, "setTexture:", set_id);
    im(c, "setLoadAction:", set_u);
    im(c, "setStoreAction:", set_u);
    im(c, "setClearColor:", pass_clear);
    c = defclass("MockEncoder", "NSObject");
    im(c, "setRenderPipelineState:", enc_pso);
    im(c, "setVertexBytes:length:atIndex:", enc_vbytes);
    im(c, "setVertexBuffer:offset:atIndex:", enc_vbuf);
    im(c, "setFragmentBytes:length:atIndex:", enc_fbytes);
    im(c, "setFragmentTexture:atIndex:", enc_ftex);
    im(c, "drawPrimitives:vertexStart:vertexCount:", enc_draw);
    im(c, "endEncoding", o_nop);

    c = defclass("GCController", "NSObject");
    cm(c, "controllers", gc_controllers);
    im(c, "extendedGamepad", gc_extended);
    c = defclass("MockGamepad", "NSObject");
    static const char *const elems[] = { "dpad", "leftThumbstick", "buttonA", "buttonB", "buttonX", "buttonY", "leftShoulder",
                                         "rightShoulder", "leftTrigger", "rightTrigger", "buttonOptions", "buttonMenu",
                                         "buttonHome", "up", "down", "left", "right" };
    for (size_t i = 0; i < sizeof elems / sizeof elems[0]; i++) im(c, elems[i], gp_child);
    c = defclass("MockButton", "NSObject");
    im(c, "isPressed", btn_pressed);
    im(c, "setPreferredSystemGestureState:", set_u);
}

int main(int argc, char **argv)
{
    if (argc != 5) { fprintf(stderr, "usage: iosmock HOME ROM SCENARIO OUTDIR\n"); return 2; }
    snprintf(g_home, sizeof g_home, "%s", argv[1]);
    snprintf(g_rom, sizeof g_rom, "%s", argv[2]);
    g_scenario = argv[3];
    snprintf(g_out, sizeof g_out, "%s", argv[4]);
    setvbuf(stdout, NULL, _IONBF, 0);
    printf("iosmock: scenario %s\n", g_scenario);
    if (!strcmp(g_scenario, "docs") || !strcmp(g_scenario, "ips")) {
        /* the ROM copied into the app's folder of Files before the app starts */
        char path[1200];
        snprintf(path, sizeof path, "%s/Documents", g_home);
        _mkdir(g_home);
        _mkdir(path);
        snprintf(path, sizeof path, "%s/Documents/Pokemon Pinball.gbc", g_home);
        FILE *in = fopen(g_rom, "rb"), *out = in ? fopen(path, "wb") : NULL;
        if (!out) fatal("cannot copy the ROM into %s", path);
        static char buf[1 << 16];
        size_t n;
        while ((n = fread(buf, 1, sizeof buf, in)) > 0) fwrite(buf, 1, n, out);
        fclose(in);
        fclose(out);
    }
    define_classes();
    CMErrorDomain = mstr("CMErrorDomain");
    char *args[] = { "PinballNS", NULL };
    pns_mock_main(1, args);
    printf("%s: %d checks, %d failed, %ld messages\n", g_fail ? "FAILED" : "ALL OK", g_checks, g_fail, g_msgs);
    return g_fail ? 1 : 0;
}
