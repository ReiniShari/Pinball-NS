/* gbc_asm.h - written by tools/gencpu.c: the offsets of the fields of GBC used by the
 * assembly versions of the interpreter (cpu_x64.asm, cpu_a64.S), as the compiler of the
 * machine that wrote them laid GBC out. Included by gbc_exec.c, where an offset that differs
 * on a target stops the compilation: run gencpu again (and look at the layout of GBC). */
#ifndef GBC_ASM_H
#define GBC_ASM_H

#include <stddef.h>

#define GBC_ASM_CHECK(name, expr, value) typedef char gbc_asm_check_##name[(expr) == (value) ? 1 : -1];

GBC_ASM_CHECK(a, offsetof(GBC, s.a), 24)
GBC_ASM_CHECK(f, offsetof(GBC, s.f), 25)
GBC_ASM_CHECK(b, offsetof(GBC, s.b), 26)
GBC_ASM_CHECK(c, offsetof(GBC, s.c), 27)
GBC_ASM_CHECK(d, offsetof(GBC, s.d), 28)
GBC_ASM_CHECK(e, offsetof(GBC, s.e), 29)
GBC_ASM_CHECK(h, offsetof(GBC, s.h), 30)
GBC_ASM_CHECK(l, offsetof(GBC, s.l), 31)
GBC_ASM_CHECK(sp, offsetof(GBC, s.sp), 32)
GBC_ASM_CHECK(pc, offsetof(GBC, s.pc), 34)
GBC_ASM_CHECK(cycles, offsetof(GBC, s.cycles), 40)
GBC_ASM_CHECK(div16, offsetof(GBC, s.div16), 65858)
GBC_ASM_CHECK(hookbyte, offsetof(GBC, hookbyte), 498556)
GBC_ASM_CHECK(fast, offsetof(GBC, fast), 572288)
GBC_ASM_CHECK(rd, offsetof(GBCFast, rd), 0)
GBC_ASM_CHECK(wr, offsetof(GBCFast, wr), 128)
GBC_ASM_CHECK(wrf, offsetof(GBCFast, wrf), 1944)
GBC_ASM_CHECK(oamb, offsetof(GBCFast, oamb), 264)
GBC_ASM_CHECK(hramb, offsetof(GBCFast, hramb), 272)
GBC_ASM_CHECK(watch, offsetof(GBCFast, watch), 280)
GBC_ASM_CHECK(hooks, offsetof(GBCFast, hooks), 288)
GBC_ASM_CHECK(deadline, offsetof(GBCFast, deadline), 296)
GBC_ASM_CHECK(dl24, offsetof(GBCFast, dl24), 304)
GBC_ASM_CHECK(frame_end, offsetof(GBCFast, frame_end), 312)
GBC_ASM_CHECK(limit, offsetof(GBCFast, limit), 320)
GBC_ASM_CHECK(div_base, offsetof(GBCFast, div_base), 368)
GBC_ASM_CHECK(special, offsetof(GBCFast, special), 370)
GBC_ASM_CHECK(frozen, offsetof(GBCFast, frozen), 371)
GBC_ASM_CHECK(tmp, offsetof(GBCFast, tmp), 372)
GBC_ASM_CHECK(stop_pc, offsetof(GBCFast, stop_pc), 384)
GBC_ASM_CHECK(stop_sp, offsetof(GBCFast, stop_sp), 388)
GBC_ASM_CHECK(t_add, offsetof(GBCFast, t_add), 408)
GBC_ASM_CHECK(t_sub, offsetof(GBCFast, t_sub), 664)
GBC_ASM_CHECK(t_inc, offsetof(GBCFast, t_inc), 920)
GBC_ASM_CHECK(t_dec, offsetof(GBCFast, t_dec), 1176)
GBC_ASM_CHECK(t_z, offsetof(GBCFast, t_z), 1432)
GBC_ASM_CHECK(t_zh, offsetof(GBCFast, t_zh), 1688)
GBC_ASM_CHECK(vlo, offsetof(GBCFast, vlo), 328)
GBC_ASM_CHECK(vhi, offsetof(GBCFast, vhi), 336)
GBC_ASM_CHECK(vmir_lo, offsetof(GBCFast, vmir_lo), 344)
GBC_ASM_CHECK(vmir_hi, offsetof(GBCFast, vmir_hi), 352)
GBC_ASM_CHECK(vmir_a0, offsetof(GBCFast, vmir_a0), 360)
GBC_ASM_CHECK(vmir_a1, offsetof(GBCFast, vmir_a1), 364)
GBC_ASM_CHECK(vfast, offsetof(GBCFast, vfast), 374)
GBC_ASM_CHECK(mbc5, offsetof(GBCFast, mbc5), 375)
GBC_ASM_CHECK(ff41, offsetof(GBCFast, ff41), 376)
GBC_ASM_CHECK(ff44, offsetof(GBCFast, ff44), 377)
GBC_ASM_CHECK(rom_bank, offsetof(GBC, s.rom_bank), 48)
GBC_ASM_CHECK(rom, offsetof(GBC, rom), 0)
GBC_ASM_CHECK(rom_mask, offsetof(GBC, rom_mask), 16)
GBC_ASM_CHECK(sizes, sizeof(GBCState) + sizeof(GBCFast), 169216)

#endif
