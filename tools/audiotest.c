/*
 * audiotest.c - stress test of the audio ring of the mobile version (platform/mobile/app.c):
 * an "audio thread" pulls samples continuously, as AAudio does, while the game thread runs
 * frames and restarts the game again and again (each restart drops the waiting samples), adds
 * silence (app_audio_pad, as after a stall) and changes the rate of the sound (app_set_audio_rate,
 * as the pace of pacing.h does). The audio thread checks that it never sees more samples than the
 * ring holds. A "writer thread" writes the files as on Android (app_io_run): at the end, the
 * cartridge save on the disk is the last one handed to it.
 *
 *   audiotest ROM [restarts]
 */
#include "../platform/mobile/app.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <threads.h>

static MobileApp app;
static atomic_bool stop, io_stop;
static atomic_long pulled, pulls, bad;

static int io_thread(void *arg)
{
    (void)arg;
    while (!atomic_load(&io_stop)) {
        app_io_run(&app);
        thrd_sleep(&(struct timespec){ .tv_nsec = 1000000 }, NULL);
    }
    return 0;
}

static int audio_thread(void *arg)
{
    (void)arg;
    int16_t buf[256 * 2];
    while (!atomic_load(&stop)) {
        uint32_t q = app_audio_queued(&app);
        if (q > APP_RING) atomic_fetch_add(&bad, 1);       /* reader past the writer: corrupted indices */
        int n = app_audio_pull(&app, buf, 256);
        atomic_fetch_add(&pulled, n);
        atomic_fetch_add(&pulls, 1);
        thrd_yield();
    }
    return 0;
}

int main(int argc, char **argv)
{
    if (argc < 2) { fprintf(stderr, "usage: audiotest ROM [restarts]\n"); return 2; }
    int restarts = argc > 2 ? atoi(argv[2]) : 200;
    FILE *f = fopen(argv[1], "rb");
    if (!f) { perror(argv[1]); return 2; }
    static uint8_t rom[8 << 20];
    size_t n = fread(rom, 1, sizeof rom, f);
    fclose(f);
    app_init(&app, "build/audiotest_data", 48000);
    if (!app_import_rom(&app, rom, n)) { fprintf(stderr, "ROM refused\n"); return 1; }
    thrd_t t, io;
    app.io_async = true;                                 /* the files by the writer thread */
    thrd_create(&io, io_thread, NULL);
    thrd_create(&t, audio_thread, NULL);
    double now = 0;
    for (int k = 0; k < restarts; k++) {
        for (int i = 0; i < 30; i++) {
            now += 1.0 / 60;
            app_update(&app, now);
            if ((i + k) % 7 == 0) app_audio_pad(&app, 2048);
            app_set_audio_rate(&app, 48000.0 * (1.0 + 0.005 * ((i % 5) - 2) / 2.0));
            app_run_frame(&app);
        }
        app.ui.pending_action = UI_ACT_RESET;            /* menu > RESTART THE GAME */
        app_update(&app, now);
    }
    atomic_store(&stop, true);
    thrd_join(t, NULL);
    /* the save written by the writer thread: the last one handed to it */
    app_io_wait(&app);
    atomic_store(&io_stop, true);
    thrd_join(io, NULL);
    bool sav_ok = false;
    FILE *sf = fopen("build/audiotest_data/pinball.sav", "rb");
    if (sf) {
        static uint8_t d[0x8000];
        size_t m = fread(d, 1, sizeof d, sf);
        fclose(sf);
        sav_ok = app.sav_last_size > 0 && m == app.sav_last_size && memcmp(d, app.sav_last, m) == 0;
        if (!sav_ok) {
            size_t i = 0;
            while (i < m && i < app.sav_last_size && d[i] == app.sav_last[i]) i++;
            printf("save: %zu bytes on the disk, %zu handed over, first difference at %zu\n", m, app.sav_last_size, i);
        }
    }
    printf("%d restarts, %ld pulls, %ld samples, %ld bad reads, save written by the writer thread: %s: %s\n",
           restarts, (long)pulls, (long)pulled, (long)bad, sav_ok ? "yes" : "NO", bad || !sav_ok ? "FAILED" : "OK");
    app_free(&app);
    return bad || !sav_ok ? 1 : 0;
}
