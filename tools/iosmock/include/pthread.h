/* pthread.h for tools/iosmock (Windows, MSVC): the threads the iPhone version uses (its writer of the
 * files), on Windows' own. (Without windows.h: its BOOL is not the one of Objective-C.) */
#ifndef PNS_MOCK_PTHREAD_H
#define PNS_MOCK_PTHREAD_H

#include <process.h>
#include <stdlib.h>

typedef struct { void *ptr; } pthread_mutex_t;          /* SRWLOCK */
typedef struct { void *ptr; } pthread_cond_t;           /* CONDITION_VARIABLE */
typedef void *pthread_t;
typedef int pthread_attr_t, pthread_mutexattr_t, pthread_condattr_t;

__declspec(dllimport) void __stdcall InitializeSRWLock(pthread_mutex_t *m);
__declspec(dllimport) void __stdcall AcquireSRWLockExclusive(pthread_mutex_t *m);
__declspec(dllimport) void __stdcall ReleaseSRWLockExclusive(pthread_mutex_t *m);
__declspec(dllimport) void __stdcall InitializeConditionVariable(pthread_cond_t *c);
__declspec(dllimport) int __stdcall SleepConditionVariableSRW(pthread_cond_t *c, pthread_mutex_t *m, unsigned long ms, unsigned long flags);
__declspec(dllimport) void __stdcall WakeConditionVariable(pthread_cond_t *c);
__declspec(dllimport) int __stdcall CloseHandle(void *h);

typedef struct { void *(*fn)(void *); void *arg; } PnsThreadStart;

static unsigned __stdcall pns_thread_main(void *p)
{
    PnsThreadStart s = *(PnsThreadStart *)p;
    free(p);
    s.fn(s.arg);
    return 0;
}

static inline int pthread_create(pthread_t *t, const pthread_attr_t *attr, void *(*fn)(void *), void *arg)
{
    (void)attr;
    PnsThreadStart *s = (PnsThreadStart *)malloc(sizeof *s);
    if (!s) return 1;
    s->fn = fn;
    s->arg = arg;
    *t = (void *)_beginthreadex(NULL, 0, pns_thread_main, s, 0, NULL);
    if (!*t) { free(s); return 1; }
    return 0;
}
static inline int pthread_detach(pthread_t t) { CloseHandle(t); return 0; }
static inline int pthread_mutex_init(pthread_mutex_t *m, const pthread_mutexattr_t *a) { (void)a; InitializeSRWLock(m); return 0; }
static inline int pthread_mutex_lock(pthread_mutex_t *m) { AcquireSRWLockExclusive(m); return 0; }
static inline int pthread_mutex_unlock(pthread_mutex_t *m) { ReleaseSRWLockExclusive(m); return 0; }
static inline int pthread_cond_init(pthread_cond_t *c, const pthread_condattr_t *a) { (void)a; InitializeConditionVariable(c); return 0; }
static inline int pthread_cond_wait(pthread_cond_t *c, pthread_mutex_t *m) { SleepConditionVariableSRW(c, m, 0xFFFFFFFFu, 0); return 0; }
static inline int pthread_cond_signal(pthread_cond_t *c) { WakeConditionVariable(c); return 0; }

#endif
