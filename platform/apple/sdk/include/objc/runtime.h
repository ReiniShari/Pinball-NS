/* mini SDK (see ../../README.md): the Objective-C runtime functions used by platform/ios */
#ifndef PNS_OBJC_RUNTIME_H
#define PNS_OBJC_RUNTIME_H

#include <stdbool.h>
#include <stddef.h>

typedef struct objc_class *Class;
struct objc_object { Class isa; };
typedef struct objc_object *id;
typedef struct objc_selector *SEL;
typedef void (*IMP)(void);
typedef bool BOOL;                          /* arm64: OBJC_BOOL_IS_BOOL */
typedef struct objc_object Protocol;
#define YES ((BOOL)1)
#define NO  ((BOOL)0)
#ifndef nil
#define nil ((id)0)
#endif

Class objc_getClass(const char *name);
Class objc_allocateClassPair(Class superclass, const char *name, size_t extra_bytes);
void objc_registerClassPair(Class cls);
BOOL class_addMethod(Class cls, SEL name, IMP imp, const char *types);
BOOL class_addProtocol(Class cls, Protocol *protocol);
Protocol *objc_getProtocol(const char *name);
Class object_getClass(id obj);
const char *class_getName(Class cls);
SEL sel_registerName(const char *str);
const char *sel_getName(SEL sel);

#endif
