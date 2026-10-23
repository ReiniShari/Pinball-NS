/* botrand.h - the random choices of the bots (pbrun, pbdebug, uisim), the same on every platform.
 *
 * The C library's rand() is not the same everywhere (Microsoft's and Android's give other
 * sequences for the same seed): the same bot would play another game on another platform, and
 * the fingerprints of two engines could not be compared across platforms. The bots use the
 * algorithm of Microsoft's rand() (the reference games were played with it) everywhere.
 * Included after <stdlib.h>. */
#ifndef PB_BOTRAND_H
#define PB_BOTRAND_H

#include <stdint.h>

static uint32_t bot_rand_state = 1;
static inline void bot_srand(unsigned seed) { bot_rand_state = seed; }
static inline int bot_rand(void)
{
    bot_rand_state = bot_rand_state * 214013u + 2531011u;
    return (int)((bot_rand_state >> 16) & 0x7FFF);
}
#define srand bot_srand
#define rand bot_rand

#endif
