/*
 * objc_c.h - Objective-C from C: the iPhone and Mac versions are written in C only, like the Android
 * one (no Java there, no Objective-C or Swift here). Classes are made at run time with the
 * Objective-C runtime, and messages are sent with objc_msgSend cast to the exact prototype of
 * each method (never called as a variadic function: the arm64 calling conventions differ).
 *
 * The few C functions of the Objective-C frameworks (UIKit, Foundation, QuartzCore, Metal) are
 * declared here: their own headers are Objective-C.
 */
#ifndef PB_OBJC_C_H
#define PB_OBJC_C_H

#include <objc/runtime.h>
#include <objc/message.h>
#include <CoreGraphics/CGGeometry.h>
#include <stdbool.h>
#include <stdint.h>

typedef long NSInteger;
typedef unsigned long NSUInteger;
typedef struct { CGFloat top, left, bottom, right; } PnsEdgeInsets;     /* UIEdgeInsets */
typedef struct { NSUInteger x, y, z; } PnsOrigin;                       /* MTLOrigin */
typedef struct { NSUInteger width, height, depth; } PnsSize;            /* MTLSize */
typedef struct { PnsOrigin origin; PnsSize size; } PnsRegion;           /* MTLRegion */
typedef struct { double red, green, blue, alpha; } PnsClearColor;       /* MTLClearColor */
typedef struct { double x, y, z; } PnsAcceleration;                     /* CMAcceleration (in g) */

/* UIKit, Foundation, QuartzCore, Metal */
extern int UIApplicationMain(int argc, char *argv[], id principal_class_name, id delegate_class_name);
extern id NSHomeDirectory(void);
extern void NSLog(id format, ...);
extern double CACurrentMediaTime(void);
extern id MTLCreateSystemDefaultDevice(void);

/* ------------------------------------------------------------------ sending messages */

#define SEL_(name) sel_registerName(name)
#define CLASS(name) ((id)objc_getClass(name))

/* MSG(return type, (argument types after id, SEL), receiver, "selector:", arguments...) */
#define MSG(R, ARGS, obj, sel, ...) ((R (*)(id, SEL, ARGS_ ARGS))objc_msgSend)((id)(obj), SEL_(sel), __VA_ARGS__)
#define ARGS_(...) __VA_ARGS__
/* the common shapes */
#define MSG0(R, obj, sel) ((R (*)(id, SEL))objc_msgSend)((id)(obj), SEL_(sel))
#define MSG1(R, T1, obj, sel, a) ((R (*)(id, SEL, T1))objc_msgSend)((id)(obj), SEL_(sel), a)

static inline id msg(id obj, const char *sel) { return MSG0(id, obj, sel); }
static inline id msg_id(id obj, const char *sel, id a) { return MSG1(id, id, obj, sel, a); }
static inline void msg_void(id obj, const char *sel) { MSG0(void, obj, sel); }
static inline void msg_set(id obj, const char *sel, id a) { MSG1(void, id, obj, sel, a); }
static inline void msg_setb(id obj, const char *sel, bool v) { MSG1(void, BOOL, obj, sel, (BOOL)v); }
static inline void msg_setu(id obj, const char *sel, NSUInteger v) { MSG1(void, NSUInteger, obj, sel, v); }
static inline void msg_setd(id obj, const char *sel, double v) { MSG1(void, double, obj, sel, v); }
static inline bool msg_b(id obj, const char *sel) { return MSG0(BOOL, obj, sel) ? true : false; }
static inline NSUInteger msg_u(id obj, const char *sel) { return MSG0(NSUInteger, obj, sel); }
static inline double msg_d(id obj, const char *sel) { return MSG0(double, obj, sel); }
static inline bool responds(id obj, const char *sel) { return obj && MSG1(BOOL, SEL, obj, "respondsToSelector:", SEL_(sel)); }
static inline id new_of(const char *cls) { return msg(msg(CLASS(cls), "alloc"), "init"); }   /* retained */
static inline void retain(id obj) { if (obj) msg(obj, "retain"); }
static inline void release(id obj) { if (obj) msg_void(obj, "release"); }

/* Structures returned by value: in registers on arm64 (objc_msgSend); in memory on x86-64
 * (the simulator on an Intel Mac) above 16 bytes, and on Windows (the test tool) above 8 bytes:
 * objc_msgSend_stret there. */
#if defined(_WIN32)
#define STRET_ABOVE 8
#elif defined(__x86_64__)
#define STRET_ABOVE 16
#else
#define STRET_ABOVE 0
#endif
#if STRET_ABOVE
#define MSG_STRUCT(R, ARGS, obj, sel, ...) \
    (sizeof(R) > STRET_ABOVE ? ((R (*)(id, SEL, ARGS_ ARGS))objc_msgSend_stret)((id)(obj), SEL_(sel), __VA_ARGS__) \
                             : ((R (*)(id, SEL, ARGS_ ARGS))objc_msgSend)((id)(obj), SEL_(sel), __VA_ARGS__))
#define MSG_STRUCT0(R, obj, sel) \
    (sizeof(R) > STRET_ABOVE ? ((R (*)(id, SEL))objc_msgSend_stret)((id)(obj), SEL_(sel)) \
                             : ((R (*)(id, SEL))objc_msgSend)((id)(obj), SEL_(sel)))
#else
#define MSG_STRUCT(R, ARGS, obj, sel, ...) ((R (*)(id, SEL, ARGS_ ARGS))objc_msgSend)((id)(obj), SEL_(sel), __VA_ARGS__)
#define MSG_STRUCT0(R, obj, sel) ((R (*)(id, SEL))objc_msgSend)((id)(obj), SEL_(sel))
#endif

/* ------------------------------------------------------------------ Foundation */

static inline id nsstr(const char *s) { return MSG1(id, const char *, CLASS("NSString"), "stringWithUTF8String:", s); }
static inline const char *cstr(id s) { return s ? MSG0(const char *, s, "UTF8String") : ""; }
static inline NSUInteger ns_count(id a) { return a ? msg_u(a, "count") : 0; }
static inline id ns_at(id a, NSUInteger i) { return MSG1(id, NSUInteger, a, "objectAtIndex:", i); }

/* a new class, made of C functions: methods are added with add_method before register_class */
static inline Class make_class(const char *name, const char *super)
{
    return objc_allocateClassPair((Class)objc_getClass(super), name, 0);
}
static inline void add_method(Class cls, const char *sel, void *fn, const char *types)
{
    class_addMethod(cls, SEL_(sel), (IMP)fn, types);
}
static inline void add_class_method(Class cls, const char *sel, void *fn, const char *types)
{
    class_addMethod(object_getClass((id)cls), SEL_(sel), (IMP)fn, types);
}
static inline void add_protocol(Class cls, const char *name)
{
    Protocol *p = objc_getProtocol(name);
    if (p) class_addProtocol(cls, p);
}

#endif
