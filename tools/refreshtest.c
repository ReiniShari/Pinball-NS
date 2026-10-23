/*
 * refreshtest.c - the refreshes of this PC's display as the Windows version waits for them
 * (platform/windows/refresh_win.h), measured without a window, and the pace it gives the game
 * (src/front/pacing.h).
 *
 *   refreshtest [dwm|kmt|timer|auto] [SECONDS]      (default: each one, 5 s)
 *
 * For each method: the spacing of the refreshes (mean, spread, the longest), and what pacer_frames
 * makes of them: the ratio found (1/1 at 60 Hz, 5/12 at 144 Hz...), the refreshes after which it
 * runs a number of frames out of its pattern (missed refreshes: the PC was busy).
 */
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <mmsystem.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "../src/front/pacing.h"
#include "../platform/windows/refresh_win.h"

static void measure(const char *name, double seconds)
{
    HWND desk = GetDesktopWindow();
    Pacer p;
    pacer_reset(&p);
    double first = 0, last = 0, sum = 0, sum2 = 0, longest = 0;
    long n = 0, frames = 0, odd = 0, failed = 0;
    int hist[5] = { 0 };
    double t_end = qpc_now() + seconds;
    while (qpc_now() < t_end) {
        double t;
        if (!strcmp(name, "dwm")) t = refresh_dwm();
        else if (!strcmp(name, "kmt")) t = refresh_kmt(desk);
        else if (!strcmp(name, "timer")) t = refresh_timer();
        else t = wait_refresh(desk);
        if (t <= 0) { if (++failed > 20) break; continue; }
        int k = pacer_frames(&p, t, 4);
        if (last > 0) {
            double d = t - last;
            sum += d;
            sum2 += d * d;
            if (d > longest) longest = d;
            n++;
            frames += k;
            if (k <= 4) hist[k]++;
            /* out of the pattern: more frames than num/den gives (rounded up), or none when den/num <= 1 */
            if (p.den && n > 120) {
                int most = (p.num + p.den - 1) / p.den, least = p.num / p.den;
                if (k > most || k < least) odd++;
            }
        } else {
            first = t;
        }
        last = t;
    }
    if (n < 2) { printf("%-6s cannot be used here (%ld failures)\n", name, failed); return; }
    double mean = sum / n, sd = sqrt(sum2 / n - mean * mean);
    printf("%-6s %6.2f Hz  spread %.3f ms  longest %.2f ms  | ratio %d/%d  %.3f frames/s  frames per refresh: 0:%d 1:%d 2:%d 3+:%d  out of pattern %ld\n",
           name, 1.0 / mean, sd * 1000, longest * 1000, p.num, p.den, frames / (last - first),
           hist[0], hist[1], hist[2], hist[3] + hist[4], odd);
}

int main(int argc, char **argv)
{
    timeBeginPeriod(1);
    refresh_init();
    double secs = argc > 2 ? atof(argv[2]) : 5.0;
    if (argc > 1) measure(argv[1], secs);
    else {
        const char *m[] = { "dwm", "kmt", "timer", "auto" };
        for (int i = 0; i < 4; i++) measure(m[i], secs);
    }
    timeEndPeriod(1);
    return 0;
}
