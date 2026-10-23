/*
 * ndicon.c - the icon of Pinball NS: the right flipper key of the Blue table, drawn by the screen
 * of the Android version itself (platform/mobile/design.c, 32 x 32 game pixels), at whole
 * enlargements (each pixel of the key: a square of SCALE x SCALE pixels).
 *
 *   ndicon -key SIZE SCALE out.png   the key alone, centred on a transparent SIZE x SIZE image
 *                                    (foreground of the adaptive icon of Android)
 *   ndicon -bg SIZE out.png          the blue of the table (background of the adaptive icon)
 *   ndicon -flat SIZE SCALE out.png  the key on the blue (icon of older launchers)
 *   ndicon -ico out.ico              the Windows icon: 32 x 32 and its enlargements x2, x4, x8;
 *                                    16, 24 and 48 drawn at their own size
 */
#include "../platform/mobile/design.h"
#include "png_write.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define BLUE 0xFF005AFFu

static int write_icon(const char *path, int size, int scale, bool key, uint32_t bg)
{
    uint32_t k[ND_ICON * ND_ICON];
    nd_icon(k, ND_ICON);
    uint32_t *img = (uint32_t *)malloc((size_t)size * size * 4);
    if (!img) return 1;
    for (int i = 0; i < size * size; i++) img[i] = bg;
    if (key) {
        int n = ND_ICON * scale, o = (size - n) / 2;
        for (int y = 0; y < n; y++)
            for (int x = 0; x < n; x++) {
                int X = o + x, Y = o + y;
                if (X < 0 || Y < 0 || X >= size || Y >= size) continue;
                uint32_t c = k[(y / scale) * ND_ICON + x / scale];
                if (c >> 24) img[Y * size + X] = c;
            }
    }
    int r = png_write_rgba(path, img, size, size, size, 1);
    free(img);
    return r ? 1 : 0;
}

static void put32(uint8_t *p, uint32_t v) { p[0] = (uint8_t)v; p[1] = (uint8_t)(v >> 8); p[2] = (uint8_t)(v >> 16); p[3] = (uint8_t)(v >> 24); }
static void put16(uint8_t *p, unsigned v) { p[0] = (uint8_t)v; p[1] = (uint8_t)(v >> 8); }

/* .ico with 32-bit images (BITMAPINFOHEADER, colours bottom-up, then the 1-bit mask) */
static int write_ico(const char *path)
{
    static const int sizes[] = { 16, 24, 32, 48, 64, 128, 256 };
    enum { N = sizeof sizes / sizeof sizes[0] };
    uint8_t *img[N];
    uint32_t len[N];
    for (int i = 0; i < N; i++) {
        int s = sizes[i], scale = s >= ND_ICON ? s / ND_ICON : 1, n = s >= ND_ICON ? ND_ICON : s;
        if (s == 48) { scale = 1; n = 48; }
        uint32_t k[64 * 64];
        nd_icon(k, n);
        int mrow = ((s + 31) / 32) * 4;
        len[i] = 40 + (uint32_t)s * s * 4 + (uint32_t)mrow * s;
        img[i] = (uint8_t *)calloc(1, len[i]);
        if (!img[i]) return 1;
        uint8_t *h = img[i];
        put32(h, 40); put32(h + 4, (uint32_t)s); put32(h + 8, (uint32_t)s * 2);
        put16(h + 12, 1); put16(h + 14, 32);
        uint8_t *px = h + 40, *mask = px + (size_t)s * s * 4;
        for (int y = 0; y < s; y++)
            for (int x = 0; x < s; x++) {
                uint32_t c = k[(y / scale) * n + x / scale];
                uint8_t *q = px + ((size_t)(s - 1 - y) * s + x) * 4;
                q[0] = (uint8_t)c; q[1] = (uint8_t)(c >> 8); q[2] = (uint8_t)(c >> 16); q[3] = (uint8_t)(c >> 24);
                if (!(c >> 24)) mask[(size_t)(s - 1 - y) * mrow + x / 8] |= (uint8_t)(0x80 >> (x % 8));
            }
    }
    FILE *f = fopen(path, "wb");
    if (!f) return 1;
    uint8_t hdr[6] = { 0, 0, 1, 0, N, 0 };
    fwrite(hdr, 1, 6, f);
    uint32_t off = 6 + 16 * N;
    for (int i = 0; i < N; i++) {
        uint8_t e[16] = { 0 };
        e[0] = (uint8_t)(sizes[i] >= 256 ? 0 : sizes[i]);
        e[1] = e[0];
        put16(e + 4, 1); put16(e + 6, 32);
        put32(e + 8, len[i]); put32(e + 12, off);
        fwrite(e, 1, 16, f);
        off += len[i];
    }
    for (int i = 0; i < N; i++) { fwrite(img[i], 1, len[i], f); free(img[i]); }
    return fclose(f) ? 1 : 0;
}

int main(int argc, char **argv)
{
    if (argc == 5 && !strcmp(argv[1], "-key")) return write_icon(argv[4], atoi(argv[2]), atoi(argv[3]), true, 0);
    if (argc == 4 && !strcmp(argv[1], "-bg")) return write_icon(argv[3], atoi(argv[2]), 1, false, BLUE);
    if (argc == 5 && !strcmp(argv[1], "-flat")) return write_icon(argv[4], atoi(argv[2]), atoi(argv[3]), true, BLUE);
    if (argc == 3 && !strcmp(argv[1], "-ico")) return write_ico(argv[2]);
    fprintf(stderr, "usage: ndicon -key SIZE SCALE out.png | -bg SIZE out.png | -flat SIZE SCALE out.png | -ico out.ico\n");
    return 2;
}
