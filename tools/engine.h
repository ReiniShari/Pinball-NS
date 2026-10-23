/* engine.h - the test tools choose the CPU interpreter from the environment:
 *   PB_ENGINE=ref   the reference (gbc_step, one instruction at a time)
 *   PB_ENGINE=c     the fast interpreter in C (gbc_exec.c)
 *   PB_ENGINE=auto  (or nothing) the fastest one: the assembly version where there is one
 * so that the same runs can be compared between them (tools/regress.sh). Call before gbc_init. */
#ifndef PB_ENGINE_H
#define PB_ENGINE_H

#include "../src/core/gbc.h"
#include <stdlib.h>
#include <string.h>

static inline void engine_from_env(void)
{
    const char *e = getenv("PB_ENGINE");
    if (!e || !*e || !strcmp(e, "auto")) gbc_default_engine = GBC_ENGINE_AUTO;
    else if (!strcmp(e, "c")) gbc_default_engine = GBC_ENGINE_C;
    else if (!strcmp(e, "ref")) gbc_default_engine = GBC_ENGINE_REF;
}

#endif
