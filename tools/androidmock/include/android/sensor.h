/* mock (tests on Linux): the part of android/sensor.h the app uses; no sensor in the mock */
#pragma once
#include <stdint.h>
#include <sys/types.h>
#include "looper.h"
typedef struct ASensorManager ASensorManager;
typedef struct ASensorEventQueue ASensorEventQueue;
typedef struct ASensor ASensor;
enum { ASENSOR_TYPE_ACCELEROMETER = 1 };
typedef struct { float x, y, z; int8_t status; uint8_t reserved[3]; } ASensorVector;
typedef struct ASensorEvent {
    int32_t version, sensor, type, reserved0;
    int64_t timestamp;
    union { float data[16]; ASensorVector vector; ASensorVector acceleration; };
    uint32_t flags;
    int32_t reserved1[3];
} ASensorEvent;
ASensorManager *ASensorManager_getInstanceForPackage(const char *packageName);
const ASensor *ASensorManager_getDefaultSensor(ASensorManager *manager, int type);
ASensorEventQueue *ASensorManager_createEventQueue(ASensorManager *manager, ALooper *looper, int ident, ALooper_callbackFunc callback, void *data);
int ASensorManager_destroyEventQueue(ASensorManager *manager, ASensorEventQueue *queue);
int ASensorEventQueue_enableSensor(ASensorEventQueue *queue, const ASensor *sensor);
int ASensorEventQueue_disableSensor(ASensorEventQueue *queue, const ASensor *sensor);
int ASensorEventQueue_setEventRate(ASensorEventQueue *queue, const ASensor *sensor, int32_t usec);
ssize_t ASensorEventQueue_getEvents(ASensorEventQueue *queue, ASensorEvent *events, size_t count);
int ASensor_getMinDelay(const ASensor *sensor);
