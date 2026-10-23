/* unistd.h - the few POSIX functions the mobile code and its test tools use, for building
 * them on Windows with MSVC (tools/build_msvc.bat, force-included). Not used by the Android
 * build. */
#ifndef PB_MSVC_UNISTD_H
#define PB_MSVC_UNISTD_H
#include <stdio.h>
#include <io.h>
#include <direct.h>
#define fsync(fd) _commit(fd)
#define mkdir(path, mode) _mkdir(path)
/* POSIX rename replaces the destination (the saves rely on it); the Windows one fails */
static int pb_rename(const char *from, const char *to) { remove(to); return rename(from, to); }
#define rename(from, to) pb_rename(from, to)
/* nanosleep, to the millisecond (Sleep of kernel32, declared here: no windows.h in the mobile code) */
#include <time.h>
__declspec(dllimport) void __stdcall Sleep(unsigned long ms);
static int pb_nanosleep(const struct timespec *t, struct timespec *rem)
{
    (void)rem;
    Sleep((unsigned long)(t->tv_sec * 1000 + (t->tv_nsec + 999999) / 1000000));
    return 0;
}
#define nanosleep(t, rem) pb_nanosleep(t, rem)
#endif
