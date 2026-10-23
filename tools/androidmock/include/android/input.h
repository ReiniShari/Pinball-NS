/* mock (tests on Linux): the subset of android/input.h + keycodes.h used by the app */
#pragma once
#include <stdint.h>
#include <stddef.h>
#include <android/looper.h>
typedef struct AInputEvent AInputEvent;
typedef struct AInputQueue AInputQueue;
enum { AINPUT_EVENT_TYPE_KEY = 1, AINPUT_EVENT_TYPE_MOTION = 2 };
enum { AINPUT_SOURCE_CLASS_JOYSTICK = 0x10, AINPUT_SOURCE_TOUCHSCREEN = 0x1002, AINPUT_SOURCE_JOYSTICK = 0x01000010, AINPUT_SOURCE_KEYBOARD = 0x101 };
enum { AKEY_EVENT_ACTION_DOWN = 0, AKEY_EVENT_ACTION_UP = 1 };
enum { AMOTION_EVENT_ACTION_MASK = 0xff, AMOTION_EVENT_ACTION_POINTER_INDEX_MASK = 0xff00, AMOTION_EVENT_ACTION_POINTER_INDEX_SHIFT = 8,
       AMOTION_EVENT_ACTION_DOWN = 0, AMOTION_EVENT_ACTION_UP = 1, AMOTION_EVENT_ACTION_MOVE = 2, AMOTION_EVENT_ACTION_CANCEL = 3,
       AMOTION_EVENT_ACTION_POINTER_DOWN = 5, AMOTION_EVENT_ACTION_POINTER_UP = 6 };
enum { AMOTION_EVENT_AXIS_X = 0, AMOTION_EVENT_AXIS_Y = 1, AMOTION_EVENT_AXIS_HAT_X = 15, AMOTION_EVENT_AXIS_HAT_Y = 16,
       AMOTION_EVENT_AXIS_LTRIGGER = 17, AMOTION_EVENT_AXIS_RTRIGGER = 18, AMOTION_EVENT_AXIS_GAS = 22, AMOTION_EVENT_AXIS_BRAKE = 23 };
enum { AKEYCODE_BACK = 4, AKEYCODE_DPAD_UP = 19, AKEYCODE_DPAD_DOWN = 20, AKEYCODE_DPAD_LEFT = 21, AKEYCODE_DPAD_RIGHT = 22,
       AKEYCODE_DPAD_CENTER = 23, AKEYCODE_C = 31, AKEYCODE_M = 41, AKEYCODE_V = 50, AKEYCODE_W = 51, AKEYCODE_X = 52,
       AKEYCODE_Z = 54, AKEYCODE_SHIFT_LEFT = 59, AKEYCODE_SHIFT_RIGHT = 60, AKEYCODE_TAB = 61, AKEYCODE_SPACE = 62,
       AKEYCODE_ENTER = 66, AKEYCODE_BUTTON_A = 96, AKEYCODE_BUTTON_B = 97, AKEYCODE_BUTTON_X = 99, AKEYCODE_BUTTON_Y = 100,
       AKEYCODE_BUTTON_L1 = 102, AKEYCODE_BUTTON_R1 = 103, AKEYCODE_BUTTON_L2 = 104, AKEYCODE_BUTTON_R2 = 105,
       AKEYCODE_BUTTON_START = 108, AKEYCODE_BUTTON_SELECT = 109, AKEYCODE_BUTTON_MODE = 110, AKEYCODE_ESCAPE = 111 };
int32_t AInputEvent_getType(const AInputEvent *event);
int32_t AInputEvent_getSource(const AInputEvent *event);
int32_t AKeyEvent_getAction(const AInputEvent *key_event);
int32_t AKeyEvent_getKeyCode(const AInputEvent *key_event);
int32_t AMotionEvent_getAction(const AInputEvent *motion_event);
size_t AMotionEvent_getPointerCount(const AInputEvent *motion_event);
int32_t AMotionEvent_getPointerId(const AInputEvent *motion_event, size_t pointer_index);
float AMotionEvent_getX(const AInputEvent *motion_event, size_t pointer_index);
float AMotionEvent_getY(const AInputEvent *motion_event, size_t pointer_index);
float AMotionEvent_getAxisValue(const AInputEvent *motion_event, int32_t axis, size_t pointer_index);
void AInputQueue_attachLooper(AInputQueue *queue, ALooper *looper, int ident, ALooper_callbackFunc callback, void *data);
void AInputQueue_detachLooper(AInputQueue *queue);
int32_t AInputQueue_getEvent(AInputQueue *queue, AInputEvent **outEvent);
int32_t AInputQueue_preDispatchEvent(AInputQueue *queue, AInputEvent *event);
void AInputQueue_finishEvent(AInputQueue *queue, AInputEvent *event, int handled);
