/* mini SDK (see ../README.md): the threads used by platform/desktop (the writer of the cartridge
 * save) and platform/macos (the display link), with the sizes of Darwin's types (the same on arm64
 * and x86-64) */
#ifndef PNS_PTHREAD_H
#define PNS_PTHREAD_H

typedef struct _opaque_pthread_t *pthread_t;
typedef struct { long __sig; char __opaque[56]; } pthread_attr_t;
typedef struct { long __sig; char __opaque[56]; } pthread_mutex_t;
typedef struct { long __sig; char __opaque[8]; } pthread_mutexattr_t;
typedef struct { long __sig; char __opaque[40]; } pthread_cond_t;
typedef struct { long __sig; char __opaque[8]; } pthread_condattr_t;

int pthread_create(pthread_t *t, const pthread_attr_t *attr, void *(*fn)(void *), void *arg);
int pthread_detach(pthread_t t);
int pthread_mutex_init(pthread_mutex_t *m, const pthread_mutexattr_t *attr);
int pthread_mutex_lock(pthread_mutex_t *m);
int pthread_mutex_unlock(pthread_mutex_t *m);
int pthread_cond_init(pthread_cond_t *c, const pthread_condattr_t *attr);
int pthread_cond_wait(pthread_cond_t *c, pthread_mutex_t *m);
int pthread_cond_signal(pthread_cond_t *c);
struct timespec;
int pthread_cond_timedwait_relative_np(pthread_cond_t *c, pthread_mutex_t *m, const struct timespec *rel);

#endif
