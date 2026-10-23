/* testrom.c - run a test ROM headless, print serial output / $A000 result, dump the screen. */
#include "../src/core/gbc.h"
#include "engine.h"
#include "png_write.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static char serial_buf[8192];
static int serial_len;

static void on_serial(uint8_t b, void *u)
{
    (void)u;
    if (serial_len < (int)sizeof(serial_buf) - 1) serial_buf[serial_len++] = (char)b;
}

int main(int argc, char **argv)
{
    engine_from_env();
    if (argc < 2) { fprintf(stderr, "usage: testrom rom.gb [frames] [out.png]\n"); return 2; }
    FILE *f = fopen(argv[1], "rb");
    if (!f) { perror(argv[1]); return 2; }
    static uint8_t rom[8 << 20];
    size_t n = fread(rom, 1, sizeof rom, f);
    fclose(f);
    if (n < 0x8000) { size_t pad = 0x8000; memset(rom + n, 0xFF, pad - n); n = pad; }
    int frames = argc > 2 ? atoi(argv[2]) : 3600;
    static GBC g;
    if (gbc_init(&g, rom, n, 48000)) { fprintf(stderr, "init failed\n"); return 2; }
    g.serial_out = on_serial;
    for (int i = 0; i < frames; i++) {
        gbc_run_frame(&g);
        int16_t tmp[4096];
        while (gbc_audio_read(&g, tmp, 2048) > 0) {}
        if (strstr(serial_buf, "Passed") || strstr(serial_buf, "Failed")) {
            if (i > 60) break;
        }
        /* $A000 protocol */
        if (g.s.sram[1] == 0xDE && g.s.sram[2] == 0xB0 && g.s.sram[3] == 0x61 && g.s.sram[0] != 0x80 && i > 30) break;
    }
    serial_buf[serial_len] = 0;
    printf("serial: %s\n", serial_buf);
    if (g.s.sram[1] == 0xDE && g.s.sram[2] == 0xB0 && g.s.sram[3] == 0x61)
        printf("a000: result=%d text=%s\n", g.s.sram[0], (char *)&g.s.sram[4]);
    if (argc > 3) png_write_rgb(argv[3], &g.fb[0][0], g.s.fw, g.s.fh, GBC_FB_W, 2);
    return 0;
}
