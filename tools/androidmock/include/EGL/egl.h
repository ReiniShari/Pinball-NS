/* mock (tests on Linux): the subset of EGL used by the app */
#pragma once
#include <stdint.h>
struct ANativeWindow;
typedef void *EGLDisplay, *EGLSurface, *EGLContext, *EGLConfig;
typedef int32_t EGLint;
typedef unsigned int EGLBoolean;
typedef struct ANativeWindow *EGLNativeWindowType;
#define EGL_DEFAULT_DISPLAY ((void *)0)
#define EGL_NO_DISPLAY ((EGLDisplay)0)
#define EGL_NO_SURFACE ((EGLSurface)0)
#define EGL_NO_CONTEXT ((EGLContext)0)
#define EGL_FALSE 0
#define EGL_TRUE 1
#define EGL_RENDERABLE_TYPE 0x3040
#define EGL_OPENGL_ES2_BIT 0x0004
#define EGL_SURFACE_TYPE 0x3033
#define EGL_WINDOW_BIT 0x0004
#define EGL_RED_SIZE 0x3024
#define EGL_GREEN_SIZE 0x3023
#define EGL_BLUE_SIZE 0x3022
#define EGL_NONE 0x3038
#define EGL_NATIVE_VISUAL_ID 0x302E
#define EGL_CONTEXT_CLIENT_VERSION 0x3098
#define EGL_WIDTH 0x3057
#define EGL_HEIGHT 0x3056
#define EGL_BAD_SURFACE 0x300D
#define EGL_CONTEXT_LOST 0x300E
#define EGL_BAD_NATIVE_WINDOW 0x300B
EGLDisplay eglGetDisplay(void *id);
EGLBoolean eglInitialize(EGLDisplay d, EGLint *major, EGLint *minor);
EGLBoolean eglChooseConfig(EGLDisplay d, const EGLint *attr, EGLConfig *cfg, EGLint size, EGLint *num);
EGLBoolean eglGetConfigAttrib(EGLDisplay d, EGLConfig c, EGLint attr, EGLint *value);
EGLSurface eglCreateWindowSurface(EGLDisplay d, EGLConfig c, EGLNativeWindowType w, const EGLint *attr);
EGLContext eglCreateContext(EGLDisplay d, EGLConfig c, EGLContext share, const EGLint *attr);
EGLBoolean eglMakeCurrent(EGLDisplay d, EGLSurface draw, EGLSurface read, EGLContext ctx);
EGLBoolean eglSwapInterval(EGLDisplay d, EGLint interval);
EGLBoolean eglSwapBuffers(EGLDisplay d, EGLSurface s);
EGLBoolean eglQuerySurface(EGLDisplay d, EGLSurface s, EGLint attr, EGLint *value);
EGLBoolean eglDestroySurface(EGLDisplay d, EGLSurface s);
EGLBoolean eglDestroyContext(EGLDisplay d, EGLContext c);
EGLBoolean eglTerminate(EGLDisplay d);
EGLint eglGetError(void);
