// cpu_a64.S - the fast interpreter of the SM83 for ARM64 (Android, iPhone, Mac), written by
// tools/gencpu.c from its description of the instructions: do not edit, see that file.
// int gbc_cpu_run(GBC *g, int64_t *budget): see gbc_exec_asm (src/core/gbc_exec.c).
// ELF (Android, Linux) or Mach-O (Apple: the C names with an underscore; x18 is never used,
// the platform's register there).

#ifdef __APPLE__
#define SYM(x) _##x
#else
#define SYM(x) x
#endif
    .text
    .p2align 4
    .globl SYM(gbc_cpu_run)
#ifdef __APPLE__
    .private_extern SYM(gbc_cpu_run)
#else
    .hidden gbc_cpu_run
    .type gbc_cpu_run, %function
#endif
SYM(gbc_cpu_run):
    stp x29, x30, [sp, #-112]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    stp x23, x24, [sp, #48]
    stp x25, x26, [sp, #64]
    stp x27, x28, [sp, #80]
    str x1, [sp, #96]
    mov x19, x0
    add x20, x0, #139, lsl #12
    add x20, x20, #2960
    ldr x23, [x1]
    ldrb w26, [x19, #24]
    ldrb w27, [x19, #25]
    ldrh w17, [x19, #26]
    rev16 w28, w17
    ldrh w17, [x19, #28]
    rev16 w13, w17
    ldrh w17, [x19, #30]
    rev16 w14, w17
    ldrh w25, [x19, #32]
    ldrh w24, [x19, #34]
    ldr x21, [x19, #40]
    ldr x22, [x20, #320]
    ldr x15, [x20, #288]
    adr x16, Ljt_f
    b Lnext
Lrd_slow:
    mov w17, #0xFF80
    cmp w9, w17
    b.lo Lrs1
    mov w17, #0xFFFF
    cmp w9, w17
    b.eq Lrs2
    ldr x10, [x20, #272]
    ret
Lrs1:
    mov w17, #0xFF44
    cmp w9, w17
    b.eq Lrs_ly
    mov w17, #0xFF41
    cmp w9, w17
    b.eq Lrs_st
    mov w17, #0xFE00
    cmp w9, w17
    b.lo Lrs2
    mov w17, #0xFEA0
    cmp w9, w17
    b.hs Lrs2
    ldr x10, [x20, #264]
    ret
Lrs_ly:
    ldrb w17, [x20, #371]
    cbnz w17, Lrs2
    add x10, x20, #377
    sub x10, x10, w9, uxtw
    ret
Lrs_st:
    ldrb w17, [x20, #371]
    cbnz w17, Lrs2
    add x10, x20, #376
    sub x10, x10, w9, uxtw
    ret
Lrs2:
    stp x30, x11, [sp, #-48]!
    stp x12, x9, [sp, #16]
    strb w26, [x19, #24]
    strb w27, [x19, #25]
    rev16 w17, w28
    strh w17, [x19, #26]
    rev16 w17, w13
    strh w17, [x19, #28]
    rev16 w17, w14
    strh w17, [x19, #30]
    strh w25, [x19, #32]
    strh w24, [x19, #34]
    ldrb w17, [x20, #371]
    cbnz w17, L1
    str x21, [x19, #40]
    ldrh w17, [x20, #368]
    add w17, w17, w21
    add x16, x19, #16, lsl #12
    strh w17, [x16, #322]
L1:
    mov x0, x19
    mov w1, w9
    bl SYM(gbc_read)
    strb w0, [x20, #372]
    ldrb w26, [x19, #24]
    ldrb w27, [x19, #25]
    ldrh w17, [x19, #26]
    rev16 w28, w17
    ldrh w17, [x19, #28]
    rev16 w13, w17
    ldrh w17, [x19, #30]
    rev16 w14, w17
    ldrh w25, [x19, #32]
    ldrh w24, [x19, #34]
    ldr x21, [x19, #40]
    ldr x22, [x20, #320]
    ldr x15, [x20, #288]
    adr x16, Ljt_f
    ldp x12, x9, [sp, #16]
    ldp x30, x11, [sp], #48
    add x10, x20, #372
    sub x10, x10, w9, uxtw
    ret
Lwr_slow:
    mov w17, #0xFF80
    cmp w9, w17
    b.lo Lws1
    mov w17, #0xFFFF
    cmp w9, w17
    b.eq Lws9
    ldr x10, [x20, #272]
    strb w0, [x10, w9, uxtw]
    ret
Lws1:
    mov w17, #0xFE00
    cmp w9, w17
    b.lo Lws2
    mov w17, #0xFEA0
    cmp w9, w17
    b.hs Lws9
    ldr x10, [x20, #264]
    strb w0, [x10, w9, uxtw]
    ret
Lws2:
    and w17, w9, #0xE000
    cmp w17, #0x8, lsl #12
    b.eq Lws_v
    cmp w17, #0x2, lsl #12
    b.eq Lws_m
    cmp w17, #0xC, lsl #12
    b.ne Lws9
    lsr w10, w9, #12
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #128]
    cbz x10, Lws9
    and w17, w9, #0x1FFF
    ldr x1, [x20, #280]
    ldrb w17, [x1, w17, uxtw]
    cbnz w17, Lws9
    strb w0, [x10, w9, uxtw]
    ret
Lws_v:
    ldrb w17, [x20, #374]
    cbz w17, Lws9
    ldr x10, [x20, #328]
    ldr x1, [x20, #344]
    mov w17, #0x9C00
    cmp w9, w17
    b.lo Lws_v1
    ldr x10, [x20, #336]
    ldr x1, [x20, #352]
Lws_v1:
    strb w0, [x10, w9, uxtw]
    cbz x1, Lws_v2
    ldr w17, [x20, #360]
    cmp w9, w17
    b.lo Lws_v2
    ldr w17, [x20, #364]
    cmp w9, w17
    b.hs Lws_v2
    strb w0, [x1, w9, uxtw]
Lws_v2:
    ret
Lws_m:
    ldrb w17, [x20, #375]
    cbz w17, Lws9
    ldrh w1, [x19, #48]
    mov w17, #0x3000
    cmp w9, w17
    b.hs Lws_m1
    and w1, w1, #0x100
    and w2, w0, #0xFF
    orr w1, w1, w2
    b Lws_m2
Lws_m1:
    and w1, w1, #0xFF
    and w2, w0, #1
    orr w1, w1, w2, lsl #8
Lws_m2:
    strh w1, [x19, #48]
    ldr w2, [x19, #16]
    and w1, w1, w2
    ldr x2, [x19, #0]
    add x2, x2, x1, lsl #14
    sub x2, x2, #0x4000
    stp x2, x2, [x20, #32]
    stp x2, x2, [x20, #48]
    ret
Lws9:
    stp x30, x11, [sp, #-48]!
    stp x12, x9, [sp, #16]
    str x0, [sp, #32]
    strb w26, [x19, #24]
    strb w27, [x19, #25]
    rev16 w17, w28
    strh w17, [x19, #26]
    rev16 w17, w13
    strh w17, [x19, #28]
    rev16 w17, w14
    strh w17, [x19, #30]
    strh w25, [x19, #32]
    strh w24, [x19, #34]
    ldrb w17, [x20, #371]
    cbnz w17, L2
    str x21, [x19, #40]
    ldrh w17, [x20, #368]
    add w17, w17, w21
    add x16, x19, #16, lsl #12
    strh w17, [x16, #322]
L2:
    mov x0, x19
    mov w1, w9
    ldrb w2, [sp, #32]
    bl SYM(gbc_asm_write)
    ldrb w26, [x19, #24]
    ldrb w27, [x19, #25]
    ldrh w17, [x19, #26]
    rev16 w28, w17
    ldrh w17, [x19, #28]
    rev16 w13, w17
    ldrh w17, [x19, #30]
    rev16 w14, w17
    ldrh w25, [x19, #32]
    ldrh w24, [x19, #34]
    ldr x21, [x19, #40]
    ldr x22, [x20, #320]
    ldr x15, [x20, #288]
    adr x16, Ljt_f
    ldp x12, x9, [sp, #16]
    ldp x30, x11, [sp], #48
    ret
Ltick_slow4:
    sub x21, x21, #4
    stp x30, x11, [sp, #-48]!
    stp x12, x9, [sp, #16]
    strb w26, [x19, #24]
    strb w27, [x19, #25]
    rev16 w17, w28
    strh w17, [x19, #26]
    rev16 w17, w13
    strh w17, [x19, #28]
    rev16 w17, w14
    strh w17, [x19, #30]
    strh w25, [x19, #32]
    strh w24, [x19, #34]
    ldrb w17, [x20, #371]
    cbnz w17, L3
    str x21, [x19, #40]
    ldrh w17, [x20, #368]
    add w17, w17, w21
    add x16, x19, #16, lsl #12
    strh w17, [x16, #322]
L3:
    mov x0, x19
    mov w1, #4
    bl SYM(gbc_asm_tick)
    ldrb w26, [x19, #24]
    ldrb w27, [x19, #25]
    ldrh w17, [x19, #26]
    rev16 w28, w17
    ldrh w17, [x19, #28]
    rev16 w13, w17
    ldrh w17, [x19, #30]
    rev16 w14, w17
    ldrh w25, [x19, #32]
    ldrh w24, [x19, #34]
    ldr x21, [x19, #40]
    ldr x22, [x20, #320]
    ldr x15, [x20, #288]
    adr x16, Ljt_f
    ldp x12, x9, [sp, #16]
    ldp x30, x11, [sp], #48
    ret
Ltick_slow8:
    sub x21, x21, #8
    stp x30, x11, [sp, #-48]!
    stp x12, x9, [sp, #16]
    strb w26, [x19, #24]
    strb w27, [x19, #25]
    rev16 w17, w28
    strh w17, [x19, #26]
    rev16 w17, w13
    strh w17, [x19, #28]
    rev16 w17, w14
    strh w17, [x19, #30]
    strh w25, [x19, #32]
    strh w24, [x19, #34]
    ldrb w17, [x20, #371]
    cbnz w17, L4
    str x21, [x19, #40]
    ldrh w17, [x20, #368]
    add w17, w17, w21
    add x16, x19, #16, lsl #12
    strh w17, [x16, #322]
L4:
    mov x0, x19
    mov w1, #8
    bl SYM(gbc_asm_tick)
    ldrb w26, [x19, #24]
    ldrb w27, [x19, #25]
    ldrh w17, [x19, #26]
    rev16 w28, w17
    ldrh w17, [x19, #28]
    rev16 w13, w17
    ldrh w17, [x19, #30]
    rev16 w14, w17
    ldrh w25, [x19, #32]
    ldrh w24, [x19, #34]
    ldr x21, [x19, #40]
    ldr x22, [x20, #320]
    ldr x15, [x20, #288]
    adr x16, Ljt_f
    ldp x12, x9, [sp, #16]
    ldp x30, x11, [sp], #48
    ret
Lidle:
    cbnz w26, Lid_ret
    cmp w27, #0xA0
    b.ne Lid_ret
    and w0, w24, #0xFFF
    cmp w0, #0xFFC
    b.hi Lid_ret
    lsr w0, w24, #12
    ldr x0, [x20, x0, lsl #3]
    cbz x0, Lid_ret
    ldr w1, [x0, w24, uxtw]
    mov w2, #0xA77E
    movk w2, #0xFC28, lsl #16
    cmp w1, w2
    b.ne Lid_ret
    ldr w1, [x15, w24, uxtw]
    and w1, w1, #0xFFFFFF
    tst w1, #0x03030303
    b.ne Lid_ret
    lsr w0, w14, #12
    ldr x0, [x20, x0, lsl #3]
    cbnz x0, Lid_m
    mov w1, #0xFF80
    cmp w14, w1
    b.lo Lid_ret
    mov w1, #0xFFFF
    cmp w14, w1
    b.eq Lid_ret
    ldr x0, [x20, #272]
Lid_m:
    ldrb w1, [x0, w14, uxtw]
    cbnz w1, Lid_ret
    ldr x0, [x20, #296]
    ldr x1, [x20, #312]
    cmp x1, x0
    csel x0, x1, x0, lo
    sub x0, x0, #1
    subs x0, x0, x21
    b.ls Lid_ret
    mov x1, #24
    udiv x0, x0, x1
    mov x1, #3
    udiv x2, x23, x1
    cmp x0, x2
    csel x0, x2, x0, hi
    add x1, x0, x0, lsl #1
    sub x23, x23, x1
    add x21, x21, x1, lsl #3
Lid_ret:
    ret
Lcopy:
    mov w0, #0x8000
    cmp w24, w0
    b.hs Lcp_ret
    and w0, w24, #0xFFF
    cmp w0, #0xFF8
    b.hi Lcp_ret
    lsr w0, w24, #12
    ldr x0, [x20, x0, lsl #3]
    cbz x0, Lcp_ret
    ldr x1, [x0, w24, uxtw]
    mov x2, #0x122A
    movk x2, #0x0B13, lsl #16
    movk x2, #0xB079, lsl #32
    movk x2, #0xF820, lsl #48
    cmp x1, x2
    b.ne Lcp_ret
    ldr x1, [x15, w24, uxtw]
    mov x2, #0x0303
    movk x2, #0x0303, lsl #16
    movk x2, #0x0303, lsl #32
    movk x2, #0x0003, lsl #48
    tst x1, x2
    b.ne Lcp_ret
    ldr x0, [x20, #296]
    ldr x1, [x20, #312]
    cmp x1, x0
    csel x0, x1, x0, lo
    sub x0, x0, #1
    subs x0, x0, x21
    b.ls Lcp_ret
    mov x1, #52
    udiv x3, x0, x1
    mov x1, #7
    udiv x2, x23, x1
    cmp x2, x3
    csel x3, x2, x3, lo
    sub w2, w28, #1
    and w2, w2, #0xFFFF
    cmp x2, x3
    csel x3, x2, x3, lo
    mov x4, #0
Lcp_loop:
    cmp x4, x3
    b.hs Lcp_end
    lsr w0, w14, #12
    ldr x0, [x20, x0, lsl #3]
    cbz x0, Lcp_end
    ldrb w1, [x0, w14, uxtw]
    lsr w0, w13, #8
    add x0, x20, x0, lsl #3
    ldr x0, [x0, #1944]
    cbz x0, Lcp_end
    strb w1, [x0, w13, uxtw]
    add w14, w14, #1
    and w14, w14, #0xFFFF
    add w13, w13, #1
    and w13, w13, #0xFFFF
    sub w28, w28, #1
    and w28, w28, #0xFFFF
    add x4, x4, #1
    b Lcp_loop
Lcp_end:
    cbz x4, Lcp_ret
    lsr w0, w28, #8
    orr w26, w0, w28
    and w26, w26, #0xFF
    mov w27, #0
    lsl x0, x4, #3
    sub x0, x0, x4
    sub x23, x23, x0
    mov x1, #52
    madd x21, x4, x1, x21
Lcp_ret:
    ret
Lslow_top:
    ldr x17, [x20, #312]
    cmp x21, x17
    b.hs Lexit_done
    ldrb w17, [x20, #370]
    cbnz w17, Lexit_more
    ldrb w17, [x15, w24, uxtw]
    tbnz w17, #0, Lexit_more
    ldr w17, [x20, #384]
    cmp w24, w17
    b.ne Lst1
    ldr w17, [x20, #388]
    cmp w25, w17
    b.eq Lexit_done
Lst1:
    subs x23, x23, #1
    b.mi Lexit_budget
    ldr x17, [x20, #304]
    cmp x21, x17
    b.lo Lfast_fetch
Lcareful_fetch:
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L5
L6:
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L7
L8:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    adr x17, Ljt_c
    ldrsw x0, [x17, x9, lsl #2]
    add x17, x17, x0
    br x17
L5:
    bl Ltick_slow4
    b L6
L7:
    mov w9, w24
    bl Lrd_slow
    b L8
Lnext:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
Lfast_fetch:
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L9
L10:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L9:
    mov w9, w24
    bl Lrd_slow
    b L10
Lexit_budget:
    strb w26, [x19, #24]
    strb w27, [x19, #25]
    rev16 w17, w28
    strh w17, [x19, #26]
    rev16 w17, w13
    strh w17, [x19, #28]
    rev16 w17, w14
    strh w17, [x19, #30]
    strh w25, [x19, #32]
    strh w24, [x19, #34]
    ldrb w17, [x20, #371]
    cbnz w17, L11
    str x21, [x19, #40]
    ldrh w17, [x20, #368]
    add w17, w17, w21
    add x16, x19, #16, lsl #12
    strh w17, [x16, #322]
L11:
    mov w0, #0
    b Lepilogue
Lexit_done:
    strb w26, [x19, #24]
    strb w27, [x19, #25]
    rev16 w17, w28
    strh w17, [x19, #26]
    rev16 w17, w13
    strh w17, [x19, #28]
    rev16 w17, w14
    strh w17, [x19, #30]
    strh w25, [x19, #32]
    strh w24, [x19, #34]
    ldrb w17, [x20, #371]
    cbnz w17, L12
    str x21, [x19, #40]
    ldrh w17, [x20, #368]
    add w17, w17, w21
    add x16, x19, #16, lsl #12
    strh w17, [x16, #322]
L12:
    mov w0, #1
    b Lepilogue
Lexit_more:
    strb w26, [x19, #24]
    strb w27, [x19, #25]
    rev16 w17, w28
    strh w17, [x19, #26]
    rev16 w17, w13
    strh w17, [x19, #28]
    rev16 w17, w14
    strh w17, [x19, #30]
    strh w25, [x19, #32]
    strh w24, [x19, #34]
    ldrb w17, [x20, #371]
    cbnz w17, L13
    str x21, [x19, #40]
    ldrh w17, [x20, #368]
    add w17, w17, w21
    add x16, x19, #16, lsl #12
    strh w17, [x16, #322]
L13:
    mov w0, #3
    b Lepilogue
Lepilogue:
    ldr x1, [sp, #96]
    str x23, [x1]
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x25, x26, [sp, #64]
    ldp x27, x28, [sp, #80]
    ldp x29, x30, [sp], #112
    ret
    .p2align 4
Lf_00:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L14
L15:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L14:
    mov w9, w24
    bl Lrd_slow
    b L15
    .p2align 4
Lf_01:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L16
L17:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L18
L19:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w28, w12
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L20
L21:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L16:
    bl Lrd_slow
    b L17
L18:
    bl Lrd_slow
    b L19
L20:
    mov w9, w24
    bl Lrd_slow
    b L21
    .p2align 4
Lf_02:
    mov w9, w28
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L22
    strb w26, [x10, w9, uxtw]
L23:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L24
L25:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L22:
    mov w0, w26
    bl Lwr_slow
    b L23
L24:
    mov w9, w24
    bl Lrd_slow
    b L25
    .p2align 4
Lf_03:
    add w28, w28, #1
    and w28, w28, #0xFFFF
    add x21, x21, #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L26
L27:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L26:
    mov w9, w24
    bl Lrd_slow
    b L27
    .p2align 4
Lf_04:
    lsr w0, w28, #8
    add w1, w0, #1
    and w1, w1, #0xFF
    bfi w28, w1, #8, #8
    and w27, w27, #0x10
    cmp w1, #0
    cset w2, eq
    orr w27, w27, w2, lsl #7
    and w2, w1, #0xF
    cmp w2, #0
    cset w2, eq
    orr w27, w27, w2, lsl #5
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L28
L29:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L28:
    mov w9, w24
    bl Lrd_slow
    b L29
    .p2align 4
Lf_05:
    lsr w0, w28, #8
    sub w1, w0, #1
    and w1, w1, #0xFF
    bfi w28, w1, #8, #8
    and w27, w27, #0x10
    orr w27, w27, #0x40
    cmp w1, #0
    cset w2, eq
    orr w27, w27, w2, lsl #7
    and w2, w1, #0xF
    cmp w2, #15
    cset w2, eq
    orr w27, w27, w2, lsl #5
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L30
L31:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L30:
    mov w9, w24
    bl Lrd_slow
    b L31
    .p2align 4
Lf_06:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L32
L33:
    ldrb w0, [x10, w9, uxtw]
    bfi w28, w0, #8, #8
    add w24, w24, #1
    and w24, w24, #0xFFFF
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L34
L35:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L32:
    bl Lrd_slow
    b L33
L34:
    mov w9, w24
    bl Lrd_slow
    b L35
    .p2align 4
Lf_07:
    lsr w0, w26, #7
    lsl w26, w26, #1
    orr w26, w26, w0
    and w26, w26, #0xFF
    lsl w27, w0, #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L36
L37:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L36:
    mov w9, w24
    bl Lrd_slow
    b L37
    .p2align 4
Lf_08:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L38
L39:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L40
L41:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w9, w12
    and w11, w25, #0xFF
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L42
    strb w11, [x10, w9, uxtw]
L43:
    add w9, w12, #1
    and w9, w9, #0xFFFF
    lsr w11, w25, #8
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L44
L45:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L46
    strb w11, [x10, w9, uxtw]
L47:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L48
L49:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L38:
    bl Lrd_slow
    b L39
L40:
    bl Lrd_slow
    b L41
L42:
    mov w0, w11
    bl Lwr_slow
    b L43
L44:
    bl Ltick_slow4
    b L45
L46:
    mov w0, w11
    bl Lwr_slow
    b L47
L48:
    mov w9, w24
    bl Lrd_slow
    b L49
    .p2align 4
Lf_09:
    add w0, w14, w28
    eor w1, w14, w28
    eor w1, w1, w0
    and w27, w27, #0x80
    ubfx w2, w1, #12, #1
    orr w27, w27, w2, lsl #5
    ubfx w2, w1, #16, #1
    orr w27, w27, w2, lsl #4
    and w14, w0, #0xFFFF
    add x21, x21, #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L50
L51:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L50:
    mov w9, w24
    bl Lrd_slow
    b L51
    .p2align 4
Lf_0A:
    mov w9, w28
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L52
L53:
    ldrb w26, [x10, w9, uxtw]
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L54
L55:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L52:
    bl Lrd_slow
    b L53
L54:
    mov w9, w24
    bl Lrd_slow
    b L55
    .p2align 4
Lf_0B:
    sub w28, w28, #1
    and w28, w28, #0xFFFF
    add x21, x21, #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L56
L57:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L56:
    mov w9, w24
    bl Lrd_slow
    b L57
    .p2align 4
Lf_0C:
    and w0, w28, #0xFF
    add w1, w0, #1
    and w1, w1, #0xFF
    bfi w28, w1, #0, #8
    and w27, w27, #0x10
    cmp w1, #0
    cset w2, eq
    orr w27, w27, w2, lsl #7
    and w2, w1, #0xF
    cmp w2, #0
    cset w2, eq
    orr w27, w27, w2, lsl #5
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L58
L59:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L58:
    mov w9, w24
    bl Lrd_slow
    b L59
    .p2align 4
Lf_0D:
    and w0, w28, #0xFF
    sub w1, w0, #1
    and w1, w1, #0xFF
    bfi w28, w1, #0, #8
    and w27, w27, #0x10
    orr w27, w27, #0x40
    cmp w1, #0
    cset w2, eq
    orr w27, w27, w2, lsl #7
    and w2, w1, #0xF
    cmp w2, #15
    cset w2, eq
    orr w27, w27, w2, lsl #5
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L60
L61:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L60:
    mov w9, w24
    bl Lrd_slow
    b L61
    .p2align 4
Lf_0E:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L62
L63:
    ldrb w0, [x10, w9, uxtw]
    bfi w28, w0, #0, #8
    add w24, w24, #1
    and w24, w24, #0xFFFF
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L64
L65:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L62:
    bl Lrd_slow
    b L63
L64:
    mov w9, w24
    bl Lrd_slow
    b L65
    .p2align 4
Lf_0F:
    and w0, w26, #1
    lsr w26, w26, #1
    orr w26, w26, w0, lsl #7
    lsl w27, w0, #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L66
L67:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L66:
    mov w9, w24
    bl Lrd_slow
    b L67
    .p2align 4
Lf_10:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L68
L69:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    strb w26, [x19, #24]
    strb w27, [x19, #25]
    rev16 w17, w28
    strh w17, [x19, #26]
    rev16 w17, w13
    strh w17, [x19, #28]
    rev16 w17, w14
    strh w17, [x19, #30]
    strh w25, [x19, #32]
    strh w24, [x19, #34]
    ldrb w17, [x20, #371]
    cbnz w17, L70
    str x21, [x19, #40]
    ldrh w17, [x20, #368]
    add w17, w17, w21
    add x16, x19, #16, lsl #12
    strh w17, [x16, #322]
L70:
    mov x0, x19
    mov w1, #16
    bl SYM(gbc_asm_op)
    ldrb w26, [x19, #24]
    ldrb w27, [x19, #25]
    ldrh w17, [x19, #26]
    rev16 w28, w17
    ldrh w17, [x19, #28]
    rev16 w13, w17
    ldrh w17, [x19, #30]
    rev16 w14, w17
    ldrh w25, [x19, #32]
    ldrh w24, [x19, #34]
    ldr x21, [x19, #40]
    ldr x22, [x20, #320]
    ldr x15, [x20, #288]
    adr x16, Ljt_f
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L71
L72:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L68:
    bl Lrd_slow
    b L69
L71:
    mov w9, w24
    bl Lrd_slow
    b L72
    .p2align 4
Lf_11:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L73
L74:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L75
L76:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w13, w12
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L77
L78:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L73:
    bl Lrd_slow
    b L74
L75:
    bl Lrd_slow
    b L76
L77:
    mov w9, w24
    bl Lrd_slow
    b L78
    .p2align 4
Lf_12:
    mov w9, w13
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L79
    strb w26, [x10, w9, uxtw]
L80:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L81
L82:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L79:
    mov w0, w26
    bl Lwr_slow
    b L80
L81:
    mov w9, w24
    bl Lrd_slow
    b L82
    .p2align 4
Lf_13:
    add w13, w13, #1
    and w13, w13, #0xFFFF
    add x21, x21, #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L83
L84:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L83:
    mov w9, w24
    bl Lrd_slow
    b L84
    .p2align 4
Lf_14:
    lsr w0, w13, #8
    add w1, w0, #1
    and w1, w1, #0xFF
    bfi w13, w1, #8, #8
    and w27, w27, #0x10
    cmp w1, #0
    cset w2, eq
    orr w27, w27, w2, lsl #7
    and w2, w1, #0xF
    cmp w2, #0
    cset w2, eq
    orr w27, w27, w2, lsl #5
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L85
L86:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L85:
    mov w9, w24
    bl Lrd_slow
    b L86
    .p2align 4
Lf_15:
    lsr w0, w13, #8
    sub w1, w0, #1
    and w1, w1, #0xFF
    bfi w13, w1, #8, #8
    and w27, w27, #0x10
    orr w27, w27, #0x40
    cmp w1, #0
    cset w2, eq
    orr w27, w27, w2, lsl #7
    and w2, w1, #0xF
    cmp w2, #15
    cset w2, eq
    orr w27, w27, w2, lsl #5
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L87
L88:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L87:
    mov w9, w24
    bl Lrd_slow
    b L88
    .p2align 4
Lf_16:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L89
L90:
    ldrb w0, [x10, w9, uxtw]
    bfi w13, w0, #8, #8
    add w24, w24, #1
    and w24, w24, #0xFFFF
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L91
L92:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L89:
    bl Lrd_slow
    b L90
L91:
    mov w9, w24
    bl Lrd_slow
    b L92
    .p2align 4
Lf_17:
    lsr w0, w26, #7
    ubfx w1, w27, #4, #1
    lsl w26, w26, #1
    orr w26, w26, w1
    and w26, w26, #0xFF
    lsl w27, w0, #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L93
L94:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L93:
    mov w9, w24
    bl Lrd_slow
    b L94
    .p2align 4
Lf_18:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L95
L96:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    sxtb w0, w11
    add w24, w24, w0
    and w24, w24, #0xFFFF
    add x21, x21, #4
L97:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L98
L99:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L95:
    bl Lrd_slow
    b L96
L98:
    mov w9, w24
    bl Lrd_slow
    b L99
    .p2align 4
Lf_19:
    add w0, w14, w13
    eor w1, w14, w13
    eor w1, w1, w0
    and w27, w27, #0x80
    ubfx w2, w1, #12, #1
    orr w27, w27, w2, lsl #5
    ubfx w2, w1, #16, #1
    orr w27, w27, w2, lsl #4
    and w14, w0, #0xFFFF
    add x21, x21, #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L100
L101:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L100:
    mov w9, w24
    bl Lrd_slow
    b L101
    .p2align 4
Lf_1A:
    mov w9, w13
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L102
L103:
    ldrb w26, [x10, w9, uxtw]
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L104
L105:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L102:
    bl Lrd_slow
    b L103
L104:
    mov w9, w24
    bl Lrd_slow
    b L105
    .p2align 4
Lf_1B:
    sub w13, w13, #1
    and w13, w13, #0xFFFF
    add x21, x21, #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L106
L107:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L106:
    mov w9, w24
    bl Lrd_slow
    b L107
    .p2align 4
Lf_1C:
    and w0, w13, #0xFF
    add w1, w0, #1
    and w1, w1, #0xFF
    bfi w13, w1, #0, #8
    and w27, w27, #0x10
    cmp w1, #0
    cset w2, eq
    orr w27, w27, w2, lsl #7
    and w2, w1, #0xF
    cmp w2, #0
    cset w2, eq
    orr w27, w27, w2, lsl #5
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L108
L109:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L108:
    mov w9, w24
    bl Lrd_slow
    b L109
    .p2align 4
Lf_1D:
    and w0, w13, #0xFF
    sub w1, w0, #1
    and w1, w1, #0xFF
    bfi w13, w1, #0, #8
    and w27, w27, #0x10
    orr w27, w27, #0x40
    cmp w1, #0
    cset w2, eq
    orr w27, w27, w2, lsl #7
    and w2, w1, #0xF
    cmp w2, #15
    cset w2, eq
    orr w27, w27, w2, lsl #5
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L110
L111:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L110:
    mov w9, w24
    bl Lrd_slow
    b L111
    .p2align 4
Lf_1E:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L112
L113:
    ldrb w0, [x10, w9, uxtw]
    bfi w13, w0, #0, #8
    add w24, w24, #1
    and w24, w24, #0xFFFF
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L114
L115:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L112:
    bl Lrd_slow
    b L113
L114:
    mov w9, w24
    bl Lrd_slow
    b L115
    .p2align 4
Lf_1F:
    and w0, w26, #1
    ubfx w1, w27, #4, #1
    lsr w26, w26, #1
    orr w26, w26, w1, lsl #7
    lsl w27, w0, #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L116
L117:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L116:
    mov w9, w24
    bl Lrd_slow
    b L117
    .p2align 4
Lf_20:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L118
L119:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    tbnz w27, #7, L120
    sxtb w0, w11
    add w24, w24, w0
    and w24, w24, #0xFFFF
    add x21, x21, #4
    cmn w0, #8
    b.eq L121
L122:
L120:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L123
L124:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L118:
    bl Lrd_slow
    b L119
L121:
    bl Lcopy
    b L122
L123:
    mov w9, w24
    bl Lrd_slow
    b L124
    .p2align 4
Lf_21:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L125
L126:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L127
L128:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w14, w12
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L129
L130:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L125:
    bl Lrd_slow
    b L126
L127:
    bl Lrd_slow
    b L128
L129:
    mov w9, w24
    bl Lrd_slow
    b L130
    .p2align 4
Lf_22:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L131
    strb w26, [x10, w9, uxtw]
L132:
    add w14, w9, #1
    and w14, w14, #0xFFFF
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L133
L134:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L131:
    mov w0, w26
    bl Lwr_slow
    b L132
L133:
    mov w9, w24
    bl Lrd_slow
    b L134
    .p2align 4
Lf_23:
    add w14, w14, #1
    and w14, w14, #0xFFFF
    add x21, x21, #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L135
L136:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L135:
    mov w9, w24
    bl Lrd_slow
    b L136
    .p2align 4
Lf_24:
    lsr w0, w14, #8
    add w1, w0, #1
    and w1, w1, #0xFF
    bfi w14, w1, #8, #8
    and w27, w27, #0x10
    cmp w1, #0
    cset w2, eq
    orr w27, w27, w2, lsl #7
    and w2, w1, #0xF
    cmp w2, #0
    cset w2, eq
    orr w27, w27, w2, lsl #5
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L137
L138:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L137:
    mov w9, w24
    bl Lrd_slow
    b L138
    .p2align 4
Lf_25:
    lsr w0, w14, #8
    sub w1, w0, #1
    and w1, w1, #0xFF
    bfi w14, w1, #8, #8
    and w27, w27, #0x10
    orr w27, w27, #0x40
    cmp w1, #0
    cset w2, eq
    orr w27, w27, w2, lsl #7
    and w2, w1, #0xF
    cmp w2, #15
    cset w2, eq
    orr w27, w27, w2, lsl #5
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L139
L140:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L139:
    mov w9, w24
    bl Lrd_slow
    b L140
    .p2align 4
Lf_26:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L141
L142:
    ldrb w0, [x10, w9, uxtw]
    bfi w14, w0, #8, #8
    add w24, w24, #1
    and w24, w24, #0xFFFF
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L143
L144:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L141:
    bl Lrd_slow
    b L142
L143:
    mov w9, w24
    bl Lrd_slow
    b L144
    .p2align 4
Lf_27:
    mov w0, w26
    ubfx w1, w27, #4, #1
    tbz w27, #6, L145
    tbz w27, #5, L146
    sub w0, w0, #6
L146:
    cbz w1, L150
    sub w0, w0, #0x60
    b L150
L145:
    cbnz w1, L147
    cmp w0, #0x99
    b.ls L148
L147:
    add w0, w0, #0x60
    mov w1, #1
L148:
    tbnz w27, #5, L149
    and w2, w0, #0xF
    cmp w2, #9
    b.ls L150
L149:
    add w0, w0, #6
L150:
    and w26, w0, #0xFF
    and w27, w27, #0x40
    orr w27, w27, w1, lsl #4
    cmp w26, #0
    cset w2, eq
    orr w27, w27, w2, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L152
L153:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L152:
    mov w9, w24
    bl Lrd_slow
    b L153
    .p2align 4
Lf_28:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L154
L155:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    tbz w27, #7, L156
    sxtb w0, w11
    add w24, w24, w0
    and w24, w24, #0xFFFF
    add x21, x21, #4
    cmn w0, #4
    b.eq L157
L158:
L156:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L159
L160:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L154:
    bl Lrd_slow
    b L155
L157:
    bl Lidle
    b L158
L159:
    mov w9, w24
    bl Lrd_slow
    b L160
    .p2align 4
Lf_29:
    add w0, w14, w14
    eor w1, w14, w14
    eor w1, w1, w0
    and w27, w27, #0x80
    ubfx w2, w1, #12, #1
    orr w27, w27, w2, lsl #5
    ubfx w2, w1, #16, #1
    orr w27, w27, w2, lsl #4
    and w14, w0, #0xFFFF
    add x21, x21, #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L161
L162:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L161:
    mov w9, w24
    bl Lrd_slow
    b L162
    .p2align 4
Lf_2A:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L163
L164:
    ldrb w26, [x10, w9, uxtw]
    add w14, w9, #1
    and w14, w14, #0xFFFF
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L165
L166:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L163:
    bl Lrd_slow
    b L164
L165:
    mov w9, w24
    bl Lrd_slow
    b L166
    .p2align 4
Lf_2B:
    sub w14, w14, #1
    and w14, w14, #0xFFFF
    add x21, x21, #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L167
L168:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L167:
    mov w9, w24
    bl Lrd_slow
    b L168
    .p2align 4
Lf_2C:
    and w0, w14, #0xFF
    add w1, w0, #1
    and w1, w1, #0xFF
    bfi w14, w1, #0, #8
    and w27, w27, #0x10
    cmp w1, #0
    cset w2, eq
    orr w27, w27, w2, lsl #7
    and w2, w1, #0xF
    cmp w2, #0
    cset w2, eq
    orr w27, w27, w2, lsl #5
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L169
L170:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L169:
    mov w9, w24
    bl Lrd_slow
    b L170
    .p2align 4
Lf_2D:
    and w0, w14, #0xFF
    sub w1, w0, #1
    and w1, w1, #0xFF
    bfi w14, w1, #0, #8
    and w27, w27, #0x10
    orr w27, w27, #0x40
    cmp w1, #0
    cset w2, eq
    orr w27, w27, w2, lsl #7
    and w2, w1, #0xF
    cmp w2, #15
    cset w2, eq
    orr w27, w27, w2, lsl #5
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L171
L172:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L171:
    mov w9, w24
    bl Lrd_slow
    b L172
    .p2align 4
Lf_2E:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L173
L174:
    ldrb w0, [x10, w9, uxtw]
    bfi w14, w0, #0, #8
    add w24, w24, #1
    and w24, w24, #0xFFFF
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L175
L176:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L173:
    bl Lrd_slow
    b L174
L175:
    mov w9, w24
    bl Lrd_slow
    b L176
    .p2align 4
Lf_2F:
    eor w26, w26, #0xFF
    orr w27, w27, #0x60
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L177
L178:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L177:
    mov w9, w24
    bl Lrd_slow
    b L178
    .p2align 4
Lf_30:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L179
L180:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    tbnz w27, #4, L181
    sxtb w0, w11
    add w24, w24, w0
    and w24, w24, #0xFFFF
    add x21, x21, #4
L181:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L182
L183:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L179:
    bl Lrd_slow
    b L180
L182:
    mov w9, w24
    bl Lrd_slow
    b L183
    .p2align 4
Lf_31:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L184
L185:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L186
L187:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w25, w12
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L188
L189:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L184:
    bl Lrd_slow
    b L185
L186:
    bl Lrd_slow
    b L187
L188:
    mov w9, w24
    bl Lrd_slow
    b L189
    .p2align 4
Lf_32:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L190
    strb w26, [x10, w9, uxtw]
L191:
    sub w14, w9, #1
    and w14, w14, #0xFFFF
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L192
L193:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L190:
    mov w0, w26
    bl Lwr_slow
    b L191
L192:
    mov w9, w24
    bl Lrd_slow
    b L193
    .p2align 4
Lf_33:
    add w25, w25, #1
    and w25, w25, #0xFFFF
    add x21, x21, #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L194
L195:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L194:
    mov w9, w24
    bl Lrd_slow
    b L195
    .p2align 4
Lf_34:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L196
L197:
    ldrb w11, [x10, w9, uxtw]
    add w1, w11, #1
    and w1, w1, #0xFF
    and w11, w1, #0xFF
    and w27, w27, #0x10
    cmp w1, #0
    cset w2, eq
    orr w27, w27, w2, lsl #7
    and w2, w1, #0xF
    cmp w2, #0
    cset w2, eq
    orr w27, w27, w2, lsl #5
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L198
    strb w11, [x10, w9, uxtw]
L199:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L200
L201:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L196:
    bl Lrd_slow
    b L197
L198:
    mov w0, w11
    bl Lwr_slow
    b L199
L200:
    mov w9, w24
    bl Lrd_slow
    b L201
    .p2align 4
Lf_35:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L202
L203:
    ldrb w11, [x10, w9, uxtw]
    sub w1, w11, #1
    and w1, w1, #0xFF
    and w11, w1, #0xFF
    and w27, w27, #0x10
    orr w27, w27, #0x40
    cmp w1, #0
    cset w2, eq
    orr w27, w27, w2, lsl #7
    and w2, w1, #0xF
    cmp w2, #15
    cset w2, eq
    orr w27, w27, w2, lsl #5
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L204
    strb w11, [x10, w9, uxtw]
L205:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L206
L207:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L202:
    bl Lrd_slow
    b L203
L204:
    mov w0, w11
    bl Lwr_slow
    b L205
L206:
    mov w9, w24
    bl Lrd_slow
    b L207
    .p2align 4
Lf_36:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L208
L209:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L210
    strb w11, [x10, w9, uxtw]
L211:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L212
L213:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L208:
    bl Lrd_slow
    b L209
L210:
    mov w0, w11
    bl Lwr_slow
    b L211
L212:
    mov w9, w24
    bl Lrd_slow
    b L213
    .p2align 4
Lf_37:
    and w27, w27, #0x80
    orr w27, w27, #0x10
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L214
L215:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L214:
    mov w9, w24
    bl Lrd_slow
    b L215
    .p2align 4
Lf_38:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L216
L217:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    tbz w27, #4, L218
    sxtb w0, w11
    add w24, w24, w0
    and w24, w24, #0xFFFF
    add x21, x21, #4
L218:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L219
L220:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L216:
    bl Lrd_slow
    b L217
L219:
    mov w9, w24
    bl Lrd_slow
    b L220
    .p2align 4
Lf_39:
    add w0, w14, w25
    eor w1, w14, w25
    eor w1, w1, w0
    and w27, w27, #0x80
    ubfx w2, w1, #12, #1
    orr w27, w27, w2, lsl #5
    ubfx w2, w1, #16, #1
    orr w27, w27, w2, lsl #4
    and w14, w0, #0xFFFF
    add x21, x21, #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L221
L222:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L221:
    mov w9, w24
    bl Lrd_slow
    b L222
    .p2align 4
Lf_3A:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L223
L224:
    ldrb w26, [x10, w9, uxtw]
    sub w14, w9, #1
    and w14, w14, #0xFFFF
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L225
L226:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L223:
    bl Lrd_slow
    b L224
L225:
    mov w9, w24
    bl Lrd_slow
    b L226
    .p2align 4
Lf_3B:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    add x21, x21, #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L227
L228:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L227:
    mov w9, w24
    bl Lrd_slow
    b L228
    .p2align 4
Lf_3C:
    add w1, w26, #1
    and w1, w1, #0xFF
    and w26, w1, #0xFF
    and w27, w27, #0x10
    cmp w1, #0
    cset w2, eq
    orr w27, w27, w2, lsl #7
    and w2, w1, #0xF
    cmp w2, #0
    cset w2, eq
    orr w27, w27, w2, lsl #5
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L229
L230:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L229:
    mov w9, w24
    bl Lrd_slow
    b L230
    .p2align 4
Lf_3D:
    sub w1, w26, #1
    and w1, w1, #0xFF
    and w26, w1, #0xFF
    and w27, w27, #0x10
    orr w27, w27, #0x40
    cmp w1, #0
    cset w2, eq
    orr w27, w27, w2, lsl #7
    and w2, w1, #0xF
    cmp w2, #15
    cset w2, eq
    orr w27, w27, w2, lsl #5
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L231
L232:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L231:
    mov w9, w24
    bl Lrd_slow
    b L232
    .p2align 4
Lf_3E:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L233
L234:
    ldrb w26, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L235
L236:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L233:
    bl Lrd_slow
    b L234
L235:
    mov w9, w24
    bl Lrd_slow
    b L236
    .p2align 4
Lf_3F:
    mov w0, #0x90
    and w27, w27, w0
    eor w27, w27, #0x10
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L237
L238:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L237:
    mov w9, w24
    bl Lrd_slow
    b L238
    .p2align 4
Lf_40:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L239
L240:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L239:
    mov w9, w24
    bl Lrd_slow
    b L240
    .p2align 4
Lf_41:
    and w0, w28, #0xFF
    bfi w28, w0, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L241
L242:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L241:
    mov w9, w24
    bl Lrd_slow
    b L242
    .p2align 4
Lf_42:
    lsr w0, w13, #8
    bfi w28, w0, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L243
L244:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L243:
    mov w9, w24
    bl Lrd_slow
    b L244
    .p2align 4
Lf_43:
    and w0, w13, #0xFF
    bfi w28, w0, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L245
L246:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L245:
    mov w9, w24
    bl Lrd_slow
    b L246
    .p2align 4
Lf_44:
    lsr w0, w14, #8
    bfi w28, w0, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L247
L248:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L247:
    mov w9, w24
    bl Lrd_slow
    b L248
    .p2align 4
Lf_45:
    and w0, w14, #0xFF
    bfi w28, w0, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L249
L250:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L249:
    mov w9, w24
    bl Lrd_slow
    b L250
    .p2align 4
Lf_46:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L251
L252:
    ldrb w0, [x10, w9, uxtw]
    bfi w28, w0, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L253
L254:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L251:
    bl Lrd_slow
    b L252
L253:
    mov w9, w24
    bl Lrd_slow
    b L254
    .p2align 4
Lf_47:
    bfi w28, w26, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L255
L256:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L255:
    mov w9, w24
    bl Lrd_slow
    b L256
    .p2align 4
Lf_48:
    lsr w0, w28, #8
    bfi w28, w0, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L257
L258:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L257:
    mov w9, w24
    bl Lrd_slow
    b L258
    .p2align 4
Lf_49:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L259
L260:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L259:
    mov w9, w24
    bl Lrd_slow
    b L260
    .p2align 4
Lf_4A:
    lsr w0, w13, #8
    bfi w28, w0, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L261
L262:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L261:
    mov w9, w24
    bl Lrd_slow
    b L262
    .p2align 4
Lf_4B:
    and w0, w13, #0xFF
    bfi w28, w0, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L263
L264:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L263:
    mov w9, w24
    bl Lrd_slow
    b L264
    .p2align 4
Lf_4C:
    lsr w0, w14, #8
    bfi w28, w0, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L265
L266:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L265:
    mov w9, w24
    bl Lrd_slow
    b L266
    .p2align 4
Lf_4D:
    and w0, w14, #0xFF
    bfi w28, w0, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L267
L268:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L267:
    mov w9, w24
    bl Lrd_slow
    b L268
    .p2align 4
Lf_4E:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L269
L270:
    ldrb w0, [x10, w9, uxtw]
    bfi w28, w0, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L271
L272:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L269:
    bl Lrd_slow
    b L270
L271:
    mov w9, w24
    bl Lrd_slow
    b L272
    .p2align 4
Lf_4F:
    bfi w28, w26, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L273
L274:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L273:
    mov w9, w24
    bl Lrd_slow
    b L274
    .p2align 4
Lf_50:
    lsr w0, w28, #8
    bfi w13, w0, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L275
L276:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L275:
    mov w9, w24
    bl Lrd_slow
    b L276
    .p2align 4
Lf_51:
    and w0, w28, #0xFF
    bfi w13, w0, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L277
L278:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L277:
    mov w9, w24
    bl Lrd_slow
    b L278
    .p2align 4
Lf_52:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L279
L280:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L279:
    mov w9, w24
    bl Lrd_slow
    b L280
    .p2align 4
Lf_53:
    and w0, w13, #0xFF
    bfi w13, w0, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L281
L282:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L281:
    mov w9, w24
    bl Lrd_slow
    b L282
    .p2align 4
Lf_54:
    lsr w0, w14, #8
    bfi w13, w0, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L283
L284:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L283:
    mov w9, w24
    bl Lrd_slow
    b L284
    .p2align 4
Lf_55:
    and w0, w14, #0xFF
    bfi w13, w0, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L285
L286:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L285:
    mov w9, w24
    bl Lrd_slow
    b L286
    .p2align 4
Lf_56:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L287
L288:
    ldrb w0, [x10, w9, uxtw]
    bfi w13, w0, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L289
L290:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L287:
    bl Lrd_slow
    b L288
L289:
    mov w9, w24
    bl Lrd_slow
    b L290
    .p2align 4
Lf_57:
    bfi w13, w26, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L291
L292:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L291:
    mov w9, w24
    bl Lrd_slow
    b L292
    .p2align 4
Lf_58:
    lsr w0, w28, #8
    bfi w13, w0, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L293
L294:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L293:
    mov w9, w24
    bl Lrd_slow
    b L294
    .p2align 4
Lf_59:
    and w0, w28, #0xFF
    bfi w13, w0, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L295
L296:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L295:
    mov w9, w24
    bl Lrd_slow
    b L296
    .p2align 4
Lf_5A:
    lsr w0, w13, #8
    bfi w13, w0, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L297
L298:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L297:
    mov w9, w24
    bl Lrd_slow
    b L298
    .p2align 4
Lf_5B:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L299
L300:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L299:
    mov w9, w24
    bl Lrd_slow
    b L300
    .p2align 4
Lf_5C:
    lsr w0, w14, #8
    bfi w13, w0, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L301
L302:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L301:
    mov w9, w24
    bl Lrd_slow
    b L302
    .p2align 4
Lf_5D:
    and w0, w14, #0xFF
    bfi w13, w0, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L303
L304:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L303:
    mov w9, w24
    bl Lrd_slow
    b L304
    .p2align 4
Lf_5E:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L305
L306:
    ldrb w0, [x10, w9, uxtw]
    bfi w13, w0, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L307
L308:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L305:
    bl Lrd_slow
    b L306
L307:
    mov w9, w24
    bl Lrd_slow
    b L308
    .p2align 4
Lf_5F:
    bfi w13, w26, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L309
L310:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L309:
    mov w9, w24
    bl Lrd_slow
    b L310
    .p2align 4
Lf_60:
    lsr w0, w28, #8
    bfi w14, w0, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L311
L312:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L311:
    mov w9, w24
    bl Lrd_slow
    b L312
    .p2align 4
Lf_61:
    and w0, w28, #0xFF
    bfi w14, w0, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L313
L314:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L313:
    mov w9, w24
    bl Lrd_slow
    b L314
    .p2align 4
Lf_62:
    lsr w0, w13, #8
    bfi w14, w0, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L315
L316:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L315:
    mov w9, w24
    bl Lrd_slow
    b L316
    .p2align 4
Lf_63:
    and w0, w13, #0xFF
    bfi w14, w0, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L317
L318:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L317:
    mov w9, w24
    bl Lrd_slow
    b L318
    .p2align 4
Lf_64:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L319
L320:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L319:
    mov w9, w24
    bl Lrd_slow
    b L320
    .p2align 4
Lf_65:
    and w0, w14, #0xFF
    bfi w14, w0, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L321
L322:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L321:
    mov w9, w24
    bl Lrd_slow
    b L322
    .p2align 4
Lf_66:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L323
L324:
    ldrb w0, [x10, w9, uxtw]
    bfi w14, w0, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L325
L326:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L323:
    bl Lrd_slow
    b L324
L325:
    mov w9, w24
    bl Lrd_slow
    b L326
    .p2align 4
Lf_67:
    bfi w14, w26, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L327
L328:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L327:
    mov w9, w24
    bl Lrd_slow
    b L328
    .p2align 4
Lf_68:
    lsr w0, w28, #8
    bfi w14, w0, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L329
L330:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L329:
    mov w9, w24
    bl Lrd_slow
    b L330
    .p2align 4
Lf_69:
    and w0, w28, #0xFF
    bfi w14, w0, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L331
L332:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L331:
    mov w9, w24
    bl Lrd_slow
    b L332
    .p2align 4
Lf_6A:
    lsr w0, w13, #8
    bfi w14, w0, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L333
L334:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L333:
    mov w9, w24
    bl Lrd_slow
    b L334
    .p2align 4
Lf_6B:
    and w0, w13, #0xFF
    bfi w14, w0, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L335
L336:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L335:
    mov w9, w24
    bl Lrd_slow
    b L336
    .p2align 4
Lf_6C:
    lsr w0, w14, #8
    bfi w14, w0, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L337
L338:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L337:
    mov w9, w24
    bl Lrd_slow
    b L338
    .p2align 4
Lf_6D:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L339
L340:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L339:
    mov w9, w24
    bl Lrd_slow
    b L340
    .p2align 4
Lf_6E:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L341
L342:
    ldrb w0, [x10, w9, uxtw]
    bfi w14, w0, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L343
L344:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L341:
    bl Lrd_slow
    b L342
L343:
    mov w9, w24
    bl Lrd_slow
    b L344
    .p2align 4
Lf_6F:
    bfi w14, w26, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L345
L346:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L345:
    mov w9, w24
    bl Lrd_slow
    b L346
    .p2align 4
Lf_70:
    mov w9, w14
    add x21, x21, #4
    lsr w0, w28, #8
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L347
    strb w0, [x10, w9, uxtw]
L348:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L349
L350:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L347:
    bl Lwr_slow
    b L348
L349:
    mov w9, w24
    bl Lrd_slow
    b L350
    .p2align 4
Lf_71:
    mov w9, w14
    add x21, x21, #4
    and w0, w28, #0xFF
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L351
    strb w0, [x10, w9, uxtw]
L352:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L353
L354:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L351:
    bl Lwr_slow
    b L352
L353:
    mov w9, w24
    bl Lrd_slow
    b L354
    .p2align 4
Lf_72:
    mov w9, w14
    add x21, x21, #4
    lsr w0, w13, #8
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L355
    strb w0, [x10, w9, uxtw]
L356:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L357
L358:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L355:
    bl Lwr_slow
    b L356
L357:
    mov w9, w24
    bl Lrd_slow
    b L358
    .p2align 4
Lf_73:
    mov w9, w14
    add x21, x21, #4
    and w0, w13, #0xFF
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L359
    strb w0, [x10, w9, uxtw]
L360:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L361
L362:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L359:
    bl Lwr_slow
    b L360
L361:
    mov w9, w24
    bl Lrd_slow
    b L362
    .p2align 4
Lf_74:
    mov w9, w14
    add x21, x21, #4
    lsr w0, w14, #8
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L363
    strb w0, [x10, w9, uxtw]
L364:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L365
L366:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L363:
    bl Lwr_slow
    b L364
L365:
    mov w9, w24
    bl Lrd_slow
    b L366
    .p2align 4
Lf_75:
    mov w9, w14
    add x21, x21, #4
    and w0, w14, #0xFF
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L367
    strb w0, [x10, w9, uxtw]
L368:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L369
L370:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L367:
    bl Lwr_slow
    b L368
L369:
    mov w9, w24
    bl Lrd_slow
    b L370
    .p2align 4
Lf_76:
    strb w26, [x19, #24]
    strb w27, [x19, #25]
    rev16 w17, w28
    strh w17, [x19, #26]
    rev16 w17, w13
    strh w17, [x19, #28]
    rev16 w17, w14
    strh w17, [x19, #30]
    strh w25, [x19, #32]
    strh w24, [x19, #34]
    ldrb w17, [x20, #371]
    cbnz w17, L371
    str x21, [x19, #40]
    ldrh w17, [x20, #368]
    add w17, w17, w21
    add x16, x19, #16, lsl #12
    strh w17, [x16, #322]
L371:
    mov x0, x19
    mov w1, #118
    bl SYM(gbc_asm_op)
    ldrb w26, [x19, #24]
    ldrb w27, [x19, #25]
    ldrh w17, [x19, #26]
    rev16 w28, w17
    ldrh w17, [x19, #28]
    rev16 w13, w17
    ldrh w17, [x19, #30]
    rev16 w14, w17
    ldrh w25, [x19, #32]
    ldrh w24, [x19, #34]
    ldr x21, [x19, #40]
    ldr x22, [x20, #320]
    ldr x15, [x20, #288]
    adr x16, Ljt_f
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L372
L373:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L372:
    mov w9, w24
    bl Lrd_slow
    b L373
    .p2align 4
Lf_77:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L374
    strb w26, [x10, w9, uxtw]
L375:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L376
L377:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L374:
    mov w0, w26
    bl Lwr_slow
    b L375
L376:
    mov w9, w24
    bl Lrd_slow
    b L377
    .p2align 4
Lf_78:
    lsr w26, w28, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L378
L379:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L378:
    mov w9, w24
    bl Lrd_slow
    b L379
    .p2align 4
Lf_79:
    and w26, w28, #0xFF
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L380
L381:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L380:
    mov w9, w24
    bl Lrd_slow
    b L381
    .p2align 4
Lf_7A:
    lsr w26, w13, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L382
L383:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L382:
    mov w9, w24
    bl Lrd_slow
    b L383
    .p2align 4
Lf_7B:
    and w26, w13, #0xFF
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L384
L385:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L384:
    mov w9, w24
    bl Lrd_slow
    b L385
    .p2align 4
Lf_7C:
    lsr w26, w14, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L386
L387:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L386:
    mov w9, w24
    bl Lrd_slow
    b L387
    .p2align 4
Lf_7D:
    and w26, w14, #0xFF
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L388
L389:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L388:
    mov w9, w24
    bl Lrd_slow
    b L389
    .p2align 4
Lf_7E:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L390
L391:
    ldrb w26, [x10, w9, uxtw]
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L392
L393:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L390:
    bl Lrd_slow
    b L391
L392:
    mov w9, w24
    bl Lrd_slow
    b L393
    .p2align 4
Lf_7F:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L394
L395:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L394:
    mov w9, w24
    bl Lrd_slow
    b L395
    .p2align 4
Lf_80:
    lsr w0, w28, #8
    add w1, w26, w0
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L396
L397:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L396:
    mov w9, w24
    bl Lrd_slow
    b L397
    .p2align 4
Lf_81:
    and w0, w28, #0xFF
    add w1, w26, w0
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L398
L399:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L398:
    mov w9, w24
    bl Lrd_slow
    b L399
    .p2align 4
Lf_82:
    lsr w0, w13, #8
    add w1, w26, w0
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L400
L401:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L400:
    mov w9, w24
    bl Lrd_slow
    b L401
    .p2align 4
Lf_83:
    and w0, w13, #0xFF
    add w1, w26, w0
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L402
L403:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L402:
    mov w9, w24
    bl Lrd_slow
    b L403
    .p2align 4
Lf_84:
    lsr w0, w14, #8
    add w1, w26, w0
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L404
L405:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L404:
    mov w9, w24
    bl Lrd_slow
    b L405
    .p2align 4
Lf_85:
    and w0, w14, #0xFF
    add w1, w26, w0
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L406
L407:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L406:
    mov w9, w24
    bl Lrd_slow
    b L407
    .p2align 4
Lf_86:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L408
L409:
    ldrb w11, [x10, w9, uxtw]
    add w1, w26, w11
    eor w2, w26, w11
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L410
L411:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L408:
    bl Lrd_slow
    b L409
L410:
    mov w9, w24
    bl Lrd_slow
    b L411
    .p2align 4
Lf_87:
    add w1, w26, w26
    eor w2, w26, w26
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L412
L413:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L412:
    mov w9, w24
    bl Lrd_slow
    b L413
    .p2align 4
Lf_88:
    lsr w0, w28, #8
    ubfx w2, w27, #4, #1
    add w1, w26, w0
    add w1, w1, w2
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L414
L415:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L414:
    mov w9, w24
    bl Lrd_slow
    b L415
    .p2align 4
Lf_89:
    and w0, w28, #0xFF
    ubfx w2, w27, #4, #1
    add w1, w26, w0
    add w1, w1, w2
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L416
L417:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L416:
    mov w9, w24
    bl Lrd_slow
    b L417
    .p2align 4
Lf_8A:
    lsr w0, w13, #8
    ubfx w2, w27, #4, #1
    add w1, w26, w0
    add w1, w1, w2
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L418
L419:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L418:
    mov w9, w24
    bl Lrd_slow
    b L419
    .p2align 4
Lf_8B:
    and w0, w13, #0xFF
    ubfx w2, w27, #4, #1
    add w1, w26, w0
    add w1, w1, w2
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L420
L421:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L420:
    mov w9, w24
    bl Lrd_slow
    b L421
    .p2align 4
Lf_8C:
    lsr w0, w14, #8
    ubfx w2, w27, #4, #1
    add w1, w26, w0
    add w1, w1, w2
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L422
L423:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L422:
    mov w9, w24
    bl Lrd_slow
    b L423
    .p2align 4
Lf_8D:
    and w0, w14, #0xFF
    ubfx w2, w27, #4, #1
    add w1, w26, w0
    add w1, w1, w2
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L424
L425:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L424:
    mov w9, w24
    bl Lrd_slow
    b L425
    .p2align 4
Lf_8E:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L426
L427:
    ldrb w11, [x10, w9, uxtw]
    ubfx w2, w27, #4, #1
    add w1, w26, w11
    add w1, w1, w2
    eor w2, w26, w11
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L428
L429:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L426:
    bl Lrd_slow
    b L427
L428:
    mov w9, w24
    bl Lrd_slow
    b L429
    .p2align 4
Lf_8F:
    ubfx w2, w27, #4, #1
    add w1, w26, w26
    add w1, w1, w2
    eor w2, w26, w26
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L430
L431:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L430:
    mov w9, w24
    bl Lrd_slow
    b L431
    .p2align 4
Lf_90:
    lsr w0, w28, #8
    sub w1, w26, w0
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L432
L433:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L432:
    mov w9, w24
    bl Lrd_slow
    b L433
    .p2align 4
Lf_91:
    and w0, w28, #0xFF
    sub w1, w26, w0
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L434
L435:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L434:
    mov w9, w24
    bl Lrd_slow
    b L435
    .p2align 4
Lf_92:
    lsr w0, w13, #8
    sub w1, w26, w0
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L436
L437:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L436:
    mov w9, w24
    bl Lrd_slow
    b L437
    .p2align 4
Lf_93:
    and w0, w13, #0xFF
    sub w1, w26, w0
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L438
L439:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L438:
    mov w9, w24
    bl Lrd_slow
    b L439
    .p2align 4
Lf_94:
    lsr w0, w14, #8
    sub w1, w26, w0
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L440
L441:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L440:
    mov w9, w24
    bl Lrd_slow
    b L441
    .p2align 4
Lf_95:
    and w0, w14, #0xFF
    sub w1, w26, w0
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L442
L443:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L442:
    mov w9, w24
    bl Lrd_slow
    b L443
    .p2align 4
Lf_96:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L444
L445:
    ldrb w11, [x10, w9, uxtw]
    sub w1, w26, w11
    eor w2, w26, w11
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L446
L447:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L444:
    bl Lrd_slow
    b L445
L446:
    mov w9, w24
    bl Lrd_slow
    b L447
    .p2align 4
Lf_97:
    sub w1, w26, w26
    eor w2, w26, w26
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L448
L449:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L448:
    mov w9, w24
    bl Lrd_slow
    b L449
    .p2align 4
Lf_98:
    lsr w0, w28, #8
    ubfx w2, w27, #4, #1
    sub w1, w26, w0
    sub w1, w1, w2
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L450
L451:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L450:
    mov w9, w24
    bl Lrd_slow
    b L451
    .p2align 4
Lf_99:
    and w0, w28, #0xFF
    ubfx w2, w27, #4, #1
    sub w1, w26, w0
    sub w1, w1, w2
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L452
L453:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L452:
    mov w9, w24
    bl Lrd_slow
    b L453
    .p2align 4
Lf_9A:
    lsr w0, w13, #8
    ubfx w2, w27, #4, #1
    sub w1, w26, w0
    sub w1, w1, w2
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L454
L455:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L454:
    mov w9, w24
    bl Lrd_slow
    b L455
    .p2align 4
Lf_9B:
    and w0, w13, #0xFF
    ubfx w2, w27, #4, #1
    sub w1, w26, w0
    sub w1, w1, w2
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L456
L457:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L456:
    mov w9, w24
    bl Lrd_slow
    b L457
    .p2align 4
Lf_9C:
    lsr w0, w14, #8
    ubfx w2, w27, #4, #1
    sub w1, w26, w0
    sub w1, w1, w2
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L458
L459:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L458:
    mov w9, w24
    bl Lrd_slow
    b L459
    .p2align 4
Lf_9D:
    and w0, w14, #0xFF
    ubfx w2, w27, #4, #1
    sub w1, w26, w0
    sub w1, w1, w2
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L460
L461:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L460:
    mov w9, w24
    bl Lrd_slow
    b L461
    .p2align 4
Lf_9E:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L462
L463:
    ldrb w11, [x10, w9, uxtw]
    ubfx w2, w27, #4, #1
    sub w1, w26, w11
    sub w1, w1, w2
    eor w2, w26, w11
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L464
L465:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L462:
    bl Lrd_slow
    b L463
L464:
    mov w9, w24
    bl Lrd_slow
    b L465
    .p2align 4
Lf_9F:
    ubfx w2, w27, #4, #1
    sub w1, w26, w26
    sub w1, w1, w2
    eor w2, w26, w26
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L466
L467:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L466:
    mov w9, w24
    bl Lrd_slow
    b L467
    .p2align 4
Lf_A0:
    lsr w0, w28, #8
    and w26, w26, w0
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    orr w27, w27, #0x20
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L468
L469:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L468:
    mov w9, w24
    bl Lrd_slow
    b L469
    .p2align 4
Lf_A1:
    and w0, w28, #0xFF
    and w26, w26, w0
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    orr w27, w27, #0x20
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L470
L471:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L470:
    mov w9, w24
    bl Lrd_slow
    b L471
    .p2align 4
Lf_A2:
    lsr w0, w13, #8
    and w26, w26, w0
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    orr w27, w27, #0x20
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L472
L473:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L472:
    mov w9, w24
    bl Lrd_slow
    b L473
    .p2align 4
Lf_A3:
    and w0, w13, #0xFF
    and w26, w26, w0
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    orr w27, w27, #0x20
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L474
L475:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L474:
    mov w9, w24
    bl Lrd_slow
    b L475
    .p2align 4
Lf_A4:
    lsr w0, w14, #8
    and w26, w26, w0
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    orr w27, w27, #0x20
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L476
L477:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L476:
    mov w9, w24
    bl Lrd_slow
    b L477
    .p2align 4
Lf_A5:
    and w0, w14, #0xFF
    and w26, w26, w0
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    orr w27, w27, #0x20
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L478
L479:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L478:
    mov w9, w24
    bl Lrd_slow
    b L479
    .p2align 4
Lf_A6:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L480
L481:
    ldrb w11, [x10, w9, uxtw]
    and w26, w26, w11
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    orr w27, w27, #0x20
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L482
L483:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L480:
    bl Lrd_slow
    b L481
L482:
    mov w9, w24
    bl Lrd_slow
    b L483
    .p2align 4
Lf_A7:
    and w26, w26, w26
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    orr w27, w27, #0x20
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L484
L485:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L484:
    mov w9, w24
    bl Lrd_slow
    b L485
    .p2align 4
Lf_A8:
    lsr w0, w28, #8
    eor w26, w26, w0
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L486
L487:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L486:
    mov w9, w24
    bl Lrd_slow
    b L487
    .p2align 4
Lf_A9:
    and w0, w28, #0xFF
    eor w26, w26, w0
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L488
L489:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L488:
    mov w9, w24
    bl Lrd_slow
    b L489
    .p2align 4
Lf_AA:
    lsr w0, w13, #8
    eor w26, w26, w0
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L490
L491:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L490:
    mov w9, w24
    bl Lrd_slow
    b L491
    .p2align 4
Lf_AB:
    and w0, w13, #0xFF
    eor w26, w26, w0
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L492
L493:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L492:
    mov w9, w24
    bl Lrd_slow
    b L493
    .p2align 4
Lf_AC:
    lsr w0, w14, #8
    eor w26, w26, w0
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L494
L495:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L494:
    mov w9, w24
    bl Lrd_slow
    b L495
    .p2align 4
Lf_AD:
    and w0, w14, #0xFF
    eor w26, w26, w0
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L496
L497:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L496:
    mov w9, w24
    bl Lrd_slow
    b L497
    .p2align 4
Lf_AE:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L498
L499:
    ldrb w11, [x10, w9, uxtw]
    eor w26, w26, w11
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L500
L501:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L498:
    bl Lrd_slow
    b L499
L500:
    mov w9, w24
    bl Lrd_slow
    b L501
    .p2align 4
Lf_AF:
    eor w26, w26, w26
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L502
L503:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L502:
    mov w9, w24
    bl Lrd_slow
    b L503
    .p2align 4
Lf_B0:
    lsr w0, w28, #8
    orr w26, w26, w0
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L504
L505:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L504:
    mov w9, w24
    bl Lrd_slow
    b L505
    .p2align 4
Lf_B1:
    and w0, w28, #0xFF
    orr w26, w26, w0
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L506
L507:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L506:
    mov w9, w24
    bl Lrd_slow
    b L507
    .p2align 4
Lf_B2:
    lsr w0, w13, #8
    orr w26, w26, w0
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L508
L509:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L508:
    mov w9, w24
    bl Lrd_slow
    b L509
    .p2align 4
Lf_B3:
    and w0, w13, #0xFF
    orr w26, w26, w0
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L510
L511:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L510:
    mov w9, w24
    bl Lrd_slow
    b L511
    .p2align 4
Lf_B4:
    lsr w0, w14, #8
    orr w26, w26, w0
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L512
L513:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L512:
    mov w9, w24
    bl Lrd_slow
    b L513
    .p2align 4
Lf_B5:
    and w0, w14, #0xFF
    orr w26, w26, w0
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L514
L515:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L514:
    mov w9, w24
    bl Lrd_slow
    b L515
    .p2align 4
Lf_B6:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L516
L517:
    ldrb w11, [x10, w9, uxtw]
    orr w26, w26, w11
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L518
L519:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L516:
    bl Lrd_slow
    b L517
L518:
    mov w9, w24
    bl Lrd_slow
    b L519
    .p2align 4
Lf_B7:
    orr w26, w26, w26
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L520
L521:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L520:
    mov w9, w24
    bl Lrd_slow
    b L521
    .p2align 4
Lf_B8:
    lsr w0, w28, #8
    sub w1, w26, w0
    eor w2, w26, w0
    eor w2, w2, w1
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L522
L523:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L522:
    mov w9, w24
    bl Lrd_slow
    b L523
    .p2align 4
Lf_B9:
    and w0, w28, #0xFF
    sub w1, w26, w0
    eor w2, w26, w0
    eor w2, w2, w1
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L524
L525:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L524:
    mov w9, w24
    bl Lrd_slow
    b L525
    .p2align 4
Lf_BA:
    lsr w0, w13, #8
    sub w1, w26, w0
    eor w2, w26, w0
    eor w2, w2, w1
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L526
L527:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L526:
    mov w9, w24
    bl Lrd_slow
    b L527
    .p2align 4
Lf_BB:
    and w0, w13, #0xFF
    sub w1, w26, w0
    eor w2, w26, w0
    eor w2, w2, w1
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L528
L529:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L528:
    mov w9, w24
    bl Lrd_slow
    b L529
    .p2align 4
Lf_BC:
    lsr w0, w14, #8
    sub w1, w26, w0
    eor w2, w26, w0
    eor w2, w2, w1
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L530
L531:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L530:
    mov w9, w24
    bl Lrd_slow
    b L531
    .p2align 4
Lf_BD:
    and w0, w14, #0xFF
    sub w1, w26, w0
    eor w2, w26, w0
    eor w2, w2, w1
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L532
L533:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L532:
    mov w9, w24
    bl Lrd_slow
    b L533
    .p2align 4
Lf_BE:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L534
L535:
    ldrb w11, [x10, w9, uxtw]
    sub w1, w26, w11
    eor w2, w26, w11
    eor w2, w2, w1
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L536
L537:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L534:
    bl Lrd_slow
    b L535
L536:
    mov w9, w24
    bl Lrd_slow
    b L537
    .p2align 4
Lf_BF:
    sub w1, w26, w26
    eor w2, w26, w26
    eor w2, w2, w1
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L538
L539:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L538:
    mov w9, w24
    bl Lrd_slow
    b L539
    .p2align 4
Lf_C0:
    add x21, x21, #4
    tbnz w27, #7, L540
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L541
L542:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L543
L544:
    ldrb w12, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w24, w12
    add x21, x21, #4
L540:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L545
L546:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L541:
    bl Lrd_slow
    b L542
L543:
    bl Lrd_slow
    b L544
L545:
    mov w9, w24
    bl Lrd_slow
    b L546
    .p2align 4
Lf_C1:
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L547
L548:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L549
L550:
    ldrb w12, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w28, w12
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L551
L552:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L547:
    bl Lrd_slow
    b L548
L549:
    bl Lrd_slow
    b L550
L551:
    mov w9, w24
    bl Lrd_slow
    b L552
    .p2align 4
Lf_C2:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L553
L554:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L555
L556:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    tbnz w27, #7, L557
    mov w24, w12
    add x21, x21, #4
L557:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L558
L559:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L553:
    bl Lrd_slow
    b L554
L555:
    bl Lrd_slow
    b L556
L558:
    mov w9, w24
    bl Lrd_slow
    b L559
    .p2align 4
Lf_C3:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L560
L561:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L562
L563:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w24, w12
    add x21, x21, #4
L564:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L565
L566:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L560:
    bl Lrd_slow
    b L561
L562:
    bl Lrd_slow
    b L563
L565:
    mov w9, w24
    bl Lrd_slow
    b L566
    .p2align 4
Lf_C4:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L567
L568:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L569
L570:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    tbnz w27, #7, L571
    add x21, x21, #4
    str w12, [sp, #104]
    mov w12, w24
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L572
    strb w11, [x10, w9, uxtw]
L573:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L574
L575:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L576
    strb w12, [x10, w9, uxtw]
L577:
    ldr w24, [sp, #104]
L571:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L578
L579:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L567:
    bl Lrd_slow
    b L568
L569:
    bl Lrd_slow
    b L570
L572:
    mov w0, w11
    bl Lwr_slow
    b L573
L574:
    bl Ltick_slow4
    b L575
L576:
    mov w0, w12
    bl Lwr_slow
    b L577
L578:
    mov w9, w24
    bl Lrd_slow
    b L579
    .p2align 4
Lf_C5:
    add x21, x21, #4
    mov w12, w28
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L580
    strb w11, [x10, w9, uxtw]
L581:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L582
L583:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L584
    strb w12, [x10, w9, uxtw]
L585:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L586
L587:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L580:
    mov w0, w11
    bl Lwr_slow
    b L581
L582:
    bl Ltick_slow4
    b L583
L584:
    mov w0, w12
    bl Lwr_slow
    b L585
L586:
    mov w9, w24
    bl Lrd_slow
    b L587
    .p2align 4
Lf_C6:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L588
L589:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    add w1, w26, w11
    eor w2, w26, w11
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L590
L591:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L588:
    bl Lrd_slow
    b L589
L590:
    mov w9, w24
    bl Lrd_slow
    b L591
    .p2align 4
Lf_C7:
    add x21, x21, #4
    mov w12, w24
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L592
    strb w11, [x10, w9, uxtw]
L593:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L594
L595:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L596
    strb w12, [x10, w9, uxtw]
L597:
    mov w24, #0
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L598
L599:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L592:
    mov w0, w11
    bl Lwr_slow
    b L593
L594:
    bl Ltick_slow4
    b L595
L596:
    mov w0, w12
    bl Lwr_slow
    b L597
L598:
    mov w9, w24
    bl Lrd_slow
    b L599
    .p2align 4
Lf_C8:
    add x21, x21, #4
    tbz w27, #7, L600
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L601
L602:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L603
L604:
    ldrb w12, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w24, w12
    add x21, x21, #4
L600:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L605
L606:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L601:
    bl Lrd_slow
    b L602
L603:
    bl Lrd_slow
    b L604
L605:
    mov w9, w24
    bl Lrd_slow
    b L606
    .p2align 4
Lf_C9:
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L607
L608:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L609
L610:
    ldrb w12, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w24, w12
    add x21, x21, #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L611
L612:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L607:
    bl Lrd_slow
    b L608
L609:
    bl Lrd_slow
    b L610
L611:
    mov w9, w24
    bl Lrd_slow
    b L612
    .p2align 4
Lf_CA:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L613
L614:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L615
L616:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    tbz w27, #7, L617
    mov w24, w12
    add x21, x21, #4
L617:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L618
L619:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L613:
    bl Lrd_slow
    b L614
L615:
    bl Lrd_slow
    b L616
L618:
    mov w9, w24
    bl Lrd_slow
    b L619
    .p2align 4
Lf_CB:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L620
L621:
    ldrb w9, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    adr x17, Ljt_fcb
    ldrsw x0, [x17, x9, lsl #2]
    add x17, x17, x0
    br x17
L620:
    bl Lrd_slow
    b L621
    .p2align 4
Lf_CC:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L622
L623:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L624
L625:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    tbz w27, #7, L626
    add x21, x21, #4
    str w12, [sp, #104]
    mov w12, w24
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L627
    strb w11, [x10, w9, uxtw]
L628:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L629
L630:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L631
    strb w12, [x10, w9, uxtw]
L632:
    ldr w24, [sp, #104]
L626:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L633
L634:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L622:
    bl Lrd_slow
    b L623
L624:
    bl Lrd_slow
    b L625
L627:
    mov w0, w11
    bl Lwr_slow
    b L628
L629:
    bl Ltick_slow4
    b L630
L631:
    mov w0, w12
    bl Lwr_slow
    b L632
L633:
    mov w9, w24
    bl Lrd_slow
    b L634
    .p2align 4
Lf_CD:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L635
L636:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L637
L638:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    add x21, x21, #4
    str w12, [sp, #104]
    mov w12, w24
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L640
    strb w11, [x10, w9, uxtw]
L641:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L642
L643:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L644
    strb w12, [x10, w9, uxtw]
L645:
    ldr w24, [sp, #104]
L639:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L646
L647:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L635:
    bl Lrd_slow
    b L636
L637:
    bl Lrd_slow
    b L638
L640:
    mov w0, w11
    bl Lwr_slow
    b L641
L642:
    bl Ltick_slow4
    b L643
L644:
    mov w0, w12
    bl Lwr_slow
    b L645
L646:
    mov w9, w24
    bl Lrd_slow
    b L647
    .p2align 4
Lf_CE:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L648
L649:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ubfx w2, w27, #4, #1
    add w1, w26, w11
    add w1, w1, w2
    eor w2, w26, w11
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L650
L651:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L648:
    bl Lrd_slow
    b L649
L650:
    mov w9, w24
    bl Lrd_slow
    b L651
    .p2align 4
Lf_CF:
    add x21, x21, #4
    mov w12, w24
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L652
    strb w11, [x10, w9, uxtw]
L653:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L654
L655:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L656
    strb w12, [x10, w9, uxtw]
L657:
    mov w24, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L658
L659:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L652:
    mov w0, w11
    bl Lwr_slow
    b L653
L654:
    bl Ltick_slow4
    b L655
L656:
    mov w0, w12
    bl Lwr_slow
    b L657
L658:
    mov w9, w24
    bl Lrd_slow
    b L659
    .p2align 4
Lf_D0:
    add x21, x21, #4
    tbnz w27, #4, L660
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L661
L662:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L663
L664:
    ldrb w12, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w24, w12
    add x21, x21, #4
L660:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L665
L666:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L661:
    bl Lrd_slow
    b L662
L663:
    bl Lrd_slow
    b L664
L665:
    mov w9, w24
    bl Lrd_slow
    b L666
    .p2align 4
Lf_D1:
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L667
L668:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L669
L670:
    ldrb w12, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w13, w12
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L671
L672:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L667:
    bl Lrd_slow
    b L668
L669:
    bl Lrd_slow
    b L670
L671:
    mov w9, w24
    bl Lrd_slow
    b L672
    .p2align 4
Lf_D2:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L673
L674:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L675
L676:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    tbnz w27, #4, L677
    mov w24, w12
    add x21, x21, #4
L677:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L678
L679:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L673:
    bl Lrd_slow
    b L674
L675:
    bl Lrd_slow
    b L676
L678:
    mov w9, w24
    bl Lrd_slow
    b L679
    .p2align 4
Lf_D3:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L680
L681:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L680:
    mov w9, w24
    bl Lrd_slow
    b L681
    .p2align 4
Lf_D4:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L682
L683:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L684
L685:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    tbnz w27, #4, L686
    add x21, x21, #4
    str w12, [sp, #104]
    mov w12, w24
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L687
    strb w11, [x10, w9, uxtw]
L688:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L689
L690:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L691
    strb w12, [x10, w9, uxtw]
L692:
    ldr w24, [sp, #104]
L686:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L693
L694:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L682:
    bl Lrd_slow
    b L683
L684:
    bl Lrd_slow
    b L685
L687:
    mov w0, w11
    bl Lwr_slow
    b L688
L689:
    bl Ltick_slow4
    b L690
L691:
    mov w0, w12
    bl Lwr_slow
    b L692
L693:
    mov w9, w24
    bl Lrd_slow
    b L694
    .p2align 4
Lf_D5:
    add x21, x21, #4
    mov w12, w13
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L695
    strb w11, [x10, w9, uxtw]
L696:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L697
L698:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L699
    strb w12, [x10, w9, uxtw]
L700:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L701
L702:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L695:
    mov w0, w11
    bl Lwr_slow
    b L696
L697:
    bl Ltick_slow4
    b L698
L699:
    mov w0, w12
    bl Lwr_slow
    b L700
L701:
    mov w9, w24
    bl Lrd_slow
    b L702
    .p2align 4
Lf_D6:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L703
L704:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    sub w1, w26, w11
    eor w2, w26, w11
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L705
L706:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L703:
    bl Lrd_slow
    b L704
L705:
    mov w9, w24
    bl Lrd_slow
    b L706
    .p2align 4
Lf_D7:
    add x21, x21, #4
    mov w12, w24
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L707
    strb w11, [x10, w9, uxtw]
L708:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L709
L710:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L711
    strb w12, [x10, w9, uxtw]
L712:
    mov w24, #16
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L713
L714:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L707:
    mov w0, w11
    bl Lwr_slow
    b L708
L709:
    bl Ltick_slow4
    b L710
L711:
    mov w0, w12
    bl Lwr_slow
    b L712
L713:
    mov w9, w24
    bl Lrd_slow
    b L714
    .p2align 4
Lf_D8:
    add x21, x21, #4
    tbz w27, #4, L715
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L716
L717:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L718
L719:
    ldrb w12, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w24, w12
    add x21, x21, #4
L715:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L720
L721:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L716:
    bl Lrd_slow
    b L717
L718:
    bl Lrd_slow
    b L719
L720:
    mov w9, w24
    bl Lrd_slow
    b L721
    .p2align 4
Lf_D9:
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L722
L723:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L724
L725:
    ldrb w12, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w24, w12
    add x21, x21, #4
    strb w26, [x19, #24]
    strb w27, [x19, #25]
    rev16 w17, w28
    strh w17, [x19, #26]
    rev16 w17, w13
    strh w17, [x19, #28]
    rev16 w17, w14
    strh w17, [x19, #30]
    strh w25, [x19, #32]
    strh w24, [x19, #34]
    ldrb w17, [x20, #371]
    cbnz w17, L726
    str x21, [x19, #40]
    ldrh w17, [x20, #368]
    add w17, w17, w21
    add x16, x19, #16, lsl #12
    strh w17, [x16, #322]
L726:
    mov x0, x19
    mov w1, #217
    bl SYM(gbc_asm_op)
    ldrb w26, [x19, #24]
    ldrb w27, [x19, #25]
    ldrh w17, [x19, #26]
    rev16 w28, w17
    ldrh w17, [x19, #28]
    rev16 w13, w17
    ldrh w17, [x19, #30]
    rev16 w14, w17
    ldrh w25, [x19, #32]
    ldrh w24, [x19, #34]
    ldr x21, [x19, #40]
    ldr x22, [x20, #320]
    ldr x15, [x20, #288]
    adr x16, Ljt_f
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L727
L728:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L722:
    bl Lrd_slow
    b L723
L724:
    bl Lrd_slow
    b L725
L727:
    mov w9, w24
    bl Lrd_slow
    b L728
    .p2align 4
Lf_DA:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L729
L730:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L731
L732:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    tbz w27, #4, L733
    mov w24, w12
    add x21, x21, #4
L733:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L734
L735:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L729:
    bl Lrd_slow
    b L730
L731:
    bl Lrd_slow
    b L732
L734:
    mov w9, w24
    bl Lrd_slow
    b L735
    .p2align 4
Lf_DB:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L736
L737:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L736:
    mov w9, w24
    bl Lrd_slow
    b L737
    .p2align 4
Lf_DC:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L738
L739:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L740
L741:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    tbz w27, #4, L742
    add x21, x21, #4
    str w12, [sp, #104]
    mov w12, w24
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L743
    strb w11, [x10, w9, uxtw]
L744:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L745
L746:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L747
    strb w12, [x10, w9, uxtw]
L748:
    ldr w24, [sp, #104]
L742:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L749
L750:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L738:
    bl Lrd_slow
    b L739
L740:
    bl Lrd_slow
    b L741
L743:
    mov w0, w11
    bl Lwr_slow
    b L744
L745:
    bl Ltick_slow4
    b L746
L747:
    mov w0, w12
    bl Lwr_slow
    b L748
L749:
    mov w9, w24
    bl Lrd_slow
    b L750
    .p2align 4
Lf_DD:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L751
L752:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L751:
    mov w9, w24
    bl Lrd_slow
    b L752
    .p2align 4
Lf_DE:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L753
L754:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ubfx w2, w27, #4, #1
    sub w1, w26, w11
    sub w1, w1, w2
    eor w2, w26, w11
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L755
L756:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L753:
    bl Lrd_slow
    b L754
L755:
    mov w9, w24
    bl Lrd_slow
    b L756
    .p2align 4
Lf_DF:
    add x21, x21, #4
    mov w12, w24
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L757
    strb w11, [x10, w9, uxtw]
L758:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L759
L760:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L761
    strb w12, [x10, w9, uxtw]
L762:
    mov w24, #24
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L763
L764:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L757:
    mov w0, w11
    bl Lwr_slow
    b L758
L759:
    bl Ltick_slow4
    b L760
L761:
    mov w0, w12
    bl Lwr_slow
    b L762
L763:
    mov w9, w24
    bl Lrd_slow
    b L764
    .p2align 4
Lf_E0:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L767
L768:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    cmp w11, #0x80
    b.lo L765
    cmp w11, #0xFF
    b.eq L765
    add x21, x21, #4
    ldr x10, [x20, #272]
    orr w0, w11, #0xFF00
    strb w26, [x10, w0, uxtw]
    b L766
L765:
    mov w9, w11
    orr w9, w9, #0xFF00
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L769
    strb w26, [x10, w9, uxtw]
L770:
L766:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L771
L772:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L767:
    bl Lrd_slow
    b L768
L769:
    mov w0, w26
    bl Lwr_slow
    b L770
L771:
    mov w9, w24
    bl Lrd_slow
    b L772
    .p2align 4
Lf_E1:
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L773
L774:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L775
L776:
    ldrb w12, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w14, w12
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L777
L778:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L773:
    bl Lrd_slow
    b L774
L775:
    bl Lrd_slow
    b L776
L777:
    mov w9, w24
    bl Lrd_slow
    b L778
    .p2align 4
Lf_E2:
    and w9, w28, #0xFF
    orr w9, w9, #0xFF00
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L779
    strb w26, [x10, w9, uxtw]
L780:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L781
L782:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L779:
    mov w0, w26
    bl Lwr_slow
    b L780
L781:
    mov w9, w24
    bl Lrd_slow
    b L782
    .p2align 4
Lf_E3:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L783
L784:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L783:
    mov w9, w24
    bl Lrd_slow
    b L784
    .p2align 4
Lf_E4:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L785
L786:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L785:
    mov w9, w24
    bl Lrd_slow
    b L786
    .p2align 4
Lf_E5:
    add x21, x21, #4
    mov w12, w14
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L787
    strb w11, [x10, w9, uxtw]
L788:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L789
L790:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L791
    strb w12, [x10, w9, uxtw]
L792:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L793
L794:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L787:
    mov w0, w11
    bl Lwr_slow
    b L788
L789:
    bl Ltick_slow4
    b L790
L791:
    mov w0, w12
    bl Lwr_slow
    b L792
L793:
    mov w9, w24
    bl Lrd_slow
    b L794
    .p2align 4
Lf_E6:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L795
L796:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    and w26, w26, w11
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    orr w27, w27, #0x20
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L797
L798:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L795:
    bl Lrd_slow
    b L796
L797:
    mov w9, w24
    bl Lrd_slow
    b L798
    .p2align 4
Lf_E7:
    add x21, x21, #4
    mov w12, w24
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L799
    strb w11, [x10, w9, uxtw]
L800:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L801
L802:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L803
    strb w12, [x10, w9, uxtw]
L804:
    mov w24, #32
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L805
L806:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L799:
    mov w0, w11
    bl Lwr_slow
    b L800
L801:
    bl Ltick_slow4
    b L802
L803:
    mov w0, w12
    bl Lwr_slow
    b L804
L805:
    mov w9, w24
    bl Lrd_slow
    b L806
    .p2align 4
Lf_E8:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L807
L808:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    and w0, w25, #0xFF
    add w0, w0, w11
    and w1, w25, #0xF
    and w2, w11, #0xF
    add w1, w1, w2
    ubfx w0, w0, #8, #1
    ubfx w1, w1, #4, #1
    lsl w27, w0, #4
    orr w27, w27, w1, lsl #5
    sxtb w2, w11
    add w2, w25, w2
    and w25, w2, #0xFFFF
    add x21, x21, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L809
L810:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L807:
    bl Lrd_slow
    b L808
L809:
    mov w9, w24
    bl Lrd_slow
    b L810
    .p2align 4
Lf_E9:
    mov w24, w14
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L811
L812:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L811:
    mov w9, w24
    bl Lrd_slow
    b L812
    .p2align 4
Lf_EA:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L813
L814:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L815
L816:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w9, w12
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L817
    strb w26, [x10, w9, uxtw]
L818:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L819
L820:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L813:
    bl Lrd_slow
    b L814
L815:
    bl Lrd_slow
    b L816
L817:
    mov w0, w26
    bl Lwr_slow
    b L818
L819:
    mov w9, w24
    bl Lrd_slow
    b L820
    .p2align 4
Lf_EB:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L821
L822:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L821:
    mov w9, w24
    bl Lrd_slow
    b L822
    .p2align 4
Lf_EC:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L823
L824:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L823:
    mov w9, w24
    bl Lrd_slow
    b L824
    .p2align 4
Lf_ED:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L825
L826:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L825:
    mov w9, w24
    bl Lrd_slow
    b L826
    .p2align 4
Lf_EE:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L827
L828:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    eor w26, w26, w11
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L829
L830:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L827:
    bl Lrd_slow
    b L828
L829:
    mov w9, w24
    bl Lrd_slow
    b L830
    .p2align 4
Lf_EF:
    add x21, x21, #4
    mov w12, w24
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L831
    strb w11, [x10, w9, uxtw]
L832:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L833
L834:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L835
    strb w12, [x10, w9, uxtw]
L836:
    mov w24, #40
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L837
L838:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L831:
    mov w0, w11
    bl Lwr_slow
    b L832
L833:
    bl Ltick_slow4
    b L834
L835:
    mov w0, w12
    bl Lwr_slow
    b L836
L837:
    mov w9, w24
    bl Lrd_slow
    b L838
    .p2align 4
Lf_F0:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L841
L842:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    cmp w11, #0x80
    b.lo L839
    cmp w11, #0xFF
    b.eq L839
    add x21, x21, #4
    ldr x10, [x20, #272]
    orr w0, w11, #0xFF00
    ldrb w26, [x10, w0, uxtw]
    b L840
L839:
    mov w9, w11
    orr w9, w9, #0xFF00
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L843
L844:
    ldrb w26, [x10, w9, uxtw]
L840:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L845
L846:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L841:
    bl Lrd_slow
    b L842
L843:
    bl Lrd_slow
    b L844
L845:
    mov w9, w24
    bl Lrd_slow
    b L846
    .p2align 4
Lf_F1:
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L847
L848:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L849
L850:
    ldrb w12, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    orr w12, w11, w12, lsl #8
    lsr w26, w12, #8
    and w27, w12, #0xF0
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L851
L852:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L847:
    bl Lrd_slow
    b L848
L849:
    bl Lrd_slow
    b L850
L851:
    mov w9, w24
    bl Lrd_slow
    b L852
    .p2align 4
Lf_F2:
    and w9, w28, #0xFF
    orr w9, w9, #0xFF00
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L853
L854:
    ldrb w26, [x10, w9, uxtw]
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L855
L856:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L853:
    bl Lrd_slow
    b L854
L855:
    mov w9, w24
    bl Lrd_slow
    b L856
    .p2align 4
Lf_F3:
    strb w26, [x19, #24]
    strb w27, [x19, #25]
    rev16 w17, w28
    strh w17, [x19, #26]
    rev16 w17, w13
    strh w17, [x19, #28]
    rev16 w17, w14
    strh w17, [x19, #30]
    strh w25, [x19, #32]
    strh w24, [x19, #34]
    ldrb w17, [x20, #371]
    cbnz w17, L857
    str x21, [x19, #40]
    ldrh w17, [x20, #368]
    add w17, w17, w21
    add x16, x19, #16, lsl #12
    strh w17, [x16, #322]
L857:
    mov x0, x19
    mov w1, #243
    bl SYM(gbc_asm_op)
    ldrb w26, [x19, #24]
    ldrb w27, [x19, #25]
    ldrh w17, [x19, #26]
    rev16 w28, w17
    ldrh w17, [x19, #28]
    rev16 w13, w17
    ldrh w17, [x19, #30]
    rev16 w14, w17
    ldrh w25, [x19, #32]
    ldrh w24, [x19, #34]
    ldr x21, [x19, #40]
    ldr x22, [x20, #320]
    ldr x15, [x20, #288]
    adr x16, Ljt_f
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L858
L859:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L858:
    mov w9, w24
    bl Lrd_slow
    b L859
    .p2align 4
Lf_F4:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L860
L861:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L860:
    mov w9, w24
    bl Lrd_slow
    b L861
    .p2align 4
Lf_F5:
    add x21, x21, #4
    orr w12, w27, w26, lsl #8
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L862
    strb w11, [x10, w9, uxtw]
L863:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L864
L865:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L866
    strb w12, [x10, w9, uxtw]
L867:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L868
L869:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L862:
    mov w0, w11
    bl Lwr_slow
    b L863
L864:
    bl Ltick_slow4
    b L865
L866:
    mov w0, w12
    bl Lwr_slow
    b L867
L868:
    mov w9, w24
    bl Lrd_slow
    b L869
    .p2align 4
Lf_F6:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L870
L871:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w26, w26, w11
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L872
L873:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L870:
    bl Lrd_slow
    b L871
L872:
    mov w9, w24
    bl Lrd_slow
    b L873
    .p2align 4
Lf_F7:
    add x21, x21, #4
    mov w12, w24
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L874
    strb w11, [x10, w9, uxtw]
L875:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L876
L877:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L878
    strb w12, [x10, w9, uxtw]
L879:
    mov w24, #48
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L880
L881:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L874:
    mov w0, w11
    bl Lwr_slow
    b L875
L876:
    bl Ltick_slow4
    b L877
L878:
    mov w0, w12
    bl Lwr_slow
    b L879
L880:
    mov w9, w24
    bl Lrd_slow
    b L881
    .p2align 4
Lf_F8:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L882
L883:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    and w0, w25, #0xFF
    add w0, w0, w11
    and w1, w25, #0xF
    and w2, w11, #0xF
    add w1, w1, w2
    ubfx w0, w0, #8, #1
    ubfx w1, w1, #4, #1
    lsl w27, w0, #4
    orr w27, w27, w1, lsl #5
    sxtb w2, w11
    add w2, w25, w2
    and w14, w2, #0xFFFF
    add x21, x21, #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L884
L885:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L882:
    bl Lrd_slow
    b L883
L884:
    mov w9, w24
    bl Lrd_slow
    b L885
    .p2align 4
Lf_F9:
    mov w25, w14
    add x21, x21, #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L886
L887:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L886:
    mov w9, w24
    bl Lrd_slow
    b L887
    .p2align 4
Lf_FA:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L888
L889:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L890
L891:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w9, w12
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L892
L893:
    ldrb w26, [x10, w9, uxtw]
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L894
L895:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L888:
    bl Lrd_slow
    b L889
L890:
    bl Lrd_slow
    b L891
L892:
    bl Lrd_slow
    b L893
L894:
    mov w9, w24
    bl Lrd_slow
    b L895
    .p2align 4
Lf_FB:
    strb w26, [x19, #24]
    strb w27, [x19, #25]
    rev16 w17, w28
    strh w17, [x19, #26]
    rev16 w17, w13
    strh w17, [x19, #28]
    rev16 w17, w14
    strh w17, [x19, #30]
    strh w25, [x19, #32]
    strh w24, [x19, #34]
    ldrb w17, [x20, #371]
    cbnz w17, L896
    str x21, [x19, #40]
    ldrh w17, [x20, #368]
    add w17, w17, w21
    add x16, x19, #16, lsl #12
    strh w17, [x16, #322]
L896:
    mov x0, x19
    mov w1, #251
    bl SYM(gbc_asm_op)
    ldrb w26, [x19, #24]
    ldrb w27, [x19, #25]
    ldrh w17, [x19, #26]
    rev16 w28, w17
    ldrh w17, [x19, #28]
    rev16 w13, w17
    ldrh w17, [x19, #30]
    rev16 w14, w17
    ldrh w25, [x19, #32]
    ldrh w24, [x19, #34]
    ldr x21, [x19, #40]
    ldr x22, [x20, #320]
    ldr x15, [x20, #288]
    adr x16, Ljt_f
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L897
L898:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L897:
    mov w9, w24
    bl Lrd_slow
    b L898
    .p2align 4
Lf_FC:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L899
L900:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L899:
    mov w9, w24
    bl Lrd_slow
    b L900
    .p2align 4
Lf_FD:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L901
L902:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L901:
    mov w9, w24
    bl Lrd_slow
    b L902
    .p2align 4
Lf_FE:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L903
L904:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    sub w1, w26, w11
    eor w2, w26, w11
    eor w2, w2, w1
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L905
L906:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L903:
    bl Lrd_slow
    b L904
L905:
    mov w9, w24
    bl Lrd_slow
    b L906
    .p2align 4
Lf_FF:
    add x21, x21, #4
    mov w12, w24
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L907
    strb w11, [x10, w9, uxtw]
L908:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L909
L910:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L911
    strb w12, [x10, w9, uxtw]
L912:
    mov w24, #56
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L913
L914:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L907:
    mov w0, w11
    bl Lwr_slow
    b L908
L909:
    bl Ltick_slow4
    b L910
L911:
    mov w0, w12
    bl Lwr_slow
    b L912
L913:
    mov w9, w24
    bl Lrd_slow
    b L914
    .p2align 4
Lfcb_00:
    lsr w0, w28, #8
    lsr w1, w0, #7
    lsl w2, w0, #1
    orr w2, w2, w1
    and w2, w2, #0xFF
    bfi w28, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L915
L916:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L915:
    mov w9, w24
    bl Lrd_slow
    b L916
    .p2align 4
Lfcb_01:
    and w0, w28, #0xFF
    lsr w1, w0, #7
    lsl w2, w0, #1
    orr w2, w2, w1
    and w2, w2, #0xFF
    bfi w28, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L917
L918:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L917:
    mov w9, w24
    bl Lrd_slow
    b L918
    .p2align 4
Lfcb_02:
    lsr w0, w13, #8
    lsr w1, w0, #7
    lsl w2, w0, #1
    orr w2, w2, w1
    and w2, w2, #0xFF
    bfi w13, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L919
L920:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L919:
    mov w9, w24
    bl Lrd_slow
    b L920
    .p2align 4
Lfcb_03:
    and w0, w13, #0xFF
    lsr w1, w0, #7
    lsl w2, w0, #1
    orr w2, w2, w1
    and w2, w2, #0xFF
    bfi w13, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L921
L922:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L921:
    mov w9, w24
    bl Lrd_slow
    b L922
    .p2align 4
Lfcb_04:
    lsr w0, w14, #8
    lsr w1, w0, #7
    lsl w2, w0, #1
    orr w2, w2, w1
    and w2, w2, #0xFF
    bfi w14, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L923
L924:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L923:
    mov w9, w24
    bl Lrd_slow
    b L924
    .p2align 4
Lfcb_05:
    and w0, w14, #0xFF
    lsr w1, w0, #7
    lsl w2, w0, #1
    orr w2, w2, w1
    and w2, w2, #0xFF
    bfi w14, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L925
L926:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L925:
    mov w9, w24
    bl Lrd_slow
    b L926
    .p2align 4
Lfcb_06:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L927
L928:
    ldrb w11, [x10, w9, uxtw]
    lsr w1, w11, #7
    lsl w2, w11, #1
    orr w2, w2, w1
    and w2, w2, #0xFF
    and w11, w2, #0xFF
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L929
    strb w11, [x10, w9, uxtw]
L930:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L931
L932:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L927:
    bl Lrd_slow
    b L928
L929:
    mov w0, w11
    bl Lwr_slow
    b L930
L931:
    mov w9, w24
    bl Lrd_slow
    b L932
    .p2align 4
Lfcb_07:
    lsr w1, w26, #7
    lsl w2, w26, #1
    orr w2, w2, w1
    and w2, w2, #0xFF
    and w26, w2, #0xFF
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L933
L934:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L933:
    mov w9, w24
    bl Lrd_slow
    b L934
    .p2align 4
Lfcb_08:
    lsr w0, w28, #8
    and w1, w0, #1
    lsr w2, w0, #1
    orr w2, w2, w1, lsl #7
    bfi w28, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L935
L936:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L935:
    mov w9, w24
    bl Lrd_slow
    b L936
    .p2align 4
Lfcb_09:
    and w0, w28, #0xFF
    and w1, w0, #1
    lsr w2, w0, #1
    orr w2, w2, w1, lsl #7
    bfi w28, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L937
L938:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L937:
    mov w9, w24
    bl Lrd_slow
    b L938
    .p2align 4
Lfcb_0A:
    lsr w0, w13, #8
    and w1, w0, #1
    lsr w2, w0, #1
    orr w2, w2, w1, lsl #7
    bfi w13, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L939
L940:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L939:
    mov w9, w24
    bl Lrd_slow
    b L940
    .p2align 4
Lfcb_0B:
    and w0, w13, #0xFF
    and w1, w0, #1
    lsr w2, w0, #1
    orr w2, w2, w1, lsl #7
    bfi w13, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L941
L942:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L941:
    mov w9, w24
    bl Lrd_slow
    b L942
    .p2align 4
Lfcb_0C:
    lsr w0, w14, #8
    and w1, w0, #1
    lsr w2, w0, #1
    orr w2, w2, w1, lsl #7
    bfi w14, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L943
L944:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L943:
    mov w9, w24
    bl Lrd_slow
    b L944
    .p2align 4
Lfcb_0D:
    and w0, w14, #0xFF
    and w1, w0, #1
    lsr w2, w0, #1
    orr w2, w2, w1, lsl #7
    bfi w14, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L945
L946:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L945:
    mov w9, w24
    bl Lrd_slow
    b L946
    .p2align 4
Lfcb_0E:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L947
L948:
    ldrb w11, [x10, w9, uxtw]
    and w1, w11, #1
    lsr w2, w11, #1
    orr w2, w2, w1, lsl #7
    and w11, w2, #0xFF
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L949
    strb w11, [x10, w9, uxtw]
L950:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L951
L952:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L947:
    bl Lrd_slow
    b L948
L949:
    mov w0, w11
    bl Lwr_slow
    b L950
L951:
    mov w9, w24
    bl Lrd_slow
    b L952
    .p2align 4
Lfcb_0F:
    and w1, w26, #1
    lsr w2, w26, #1
    orr w2, w2, w1, lsl #7
    and w26, w2, #0xFF
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L953
L954:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L953:
    mov w9, w24
    bl Lrd_slow
    b L954
    .p2align 4
Lfcb_10:
    lsr w0, w28, #8
    lsr w1, w0, #7
    ubfx w3, w27, #4, #1
    lsl w2, w0, #1
    orr w2, w2, w3
    and w2, w2, #0xFF
    bfi w28, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L955
L956:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L955:
    mov w9, w24
    bl Lrd_slow
    b L956
    .p2align 4
Lfcb_11:
    and w0, w28, #0xFF
    lsr w1, w0, #7
    ubfx w3, w27, #4, #1
    lsl w2, w0, #1
    orr w2, w2, w3
    and w2, w2, #0xFF
    bfi w28, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L957
L958:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L957:
    mov w9, w24
    bl Lrd_slow
    b L958
    .p2align 4
Lfcb_12:
    lsr w0, w13, #8
    lsr w1, w0, #7
    ubfx w3, w27, #4, #1
    lsl w2, w0, #1
    orr w2, w2, w3
    and w2, w2, #0xFF
    bfi w13, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L959
L960:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L959:
    mov w9, w24
    bl Lrd_slow
    b L960
    .p2align 4
Lfcb_13:
    and w0, w13, #0xFF
    lsr w1, w0, #7
    ubfx w3, w27, #4, #1
    lsl w2, w0, #1
    orr w2, w2, w3
    and w2, w2, #0xFF
    bfi w13, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L961
L962:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L961:
    mov w9, w24
    bl Lrd_slow
    b L962
    .p2align 4
Lfcb_14:
    lsr w0, w14, #8
    lsr w1, w0, #7
    ubfx w3, w27, #4, #1
    lsl w2, w0, #1
    orr w2, w2, w3
    and w2, w2, #0xFF
    bfi w14, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L963
L964:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L963:
    mov w9, w24
    bl Lrd_slow
    b L964
    .p2align 4
Lfcb_15:
    and w0, w14, #0xFF
    lsr w1, w0, #7
    ubfx w3, w27, #4, #1
    lsl w2, w0, #1
    orr w2, w2, w3
    and w2, w2, #0xFF
    bfi w14, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L965
L966:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L965:
    mov w9, w24
    bl Lrd_slow
    b L966
    .p2align 4
Lfcb_16:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L967
L968:
    ldrb w11, [x10, w9, uxtw]
    lsr w1, w11, #7
    ubfx w3, w27, #4, #1
    lsl w2, w11, #1
    orr w2, w2, w3
    and w2, w2, #0xFF
    and w11, w2, #0xFF
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L969
    strb w11, [x10, w9, uxtw]
L970:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L971
L972:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L967:
    bl Lrd_slow
    b L968
L969:
    mov w0, w11
    bl Lwr_slow
    b L970
L971:
    mov w9, w24
    bl Lrd_slow
    b L972
    .p2align 4
Lfcb_17:
    lsr w1, w26, #7
    ubfx w3, w27, #4, #1
    lsl w2, w26, #1
    orr w2, w2, w3
    and w2, w2, #0xFF
    and w26, w2, #0xFF
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L973
L974:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L973:
    mov w9, w24
    bl Lrd_slow
    b L974
    .p2align 4
Lfcb_18:
    lsr w0, w28, #8
    and w1, w0, #1
    ubfx w3, w27, #4, #1
    lsr w2, w0, #1
    orr w2, w2, w3, lsl #7
    bfi w28, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L975
L976:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L975:
    mov w9, w24
    bl Lrd_slow
    b L976
    .p2align 4
Lfcb_19:
    and w0, w28, #0xFF
    and w1, w0, #1
    ubfx w3, w27, #4, #1
    lsr w2, w0, #1
    orr w2, w2, w3, lsl #7
    bfi w28, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L977
L978:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L977:
    mov w9, w24
    bl Lrd_slow
    b L978
    .p2align 4
Lfcb_1A:
    lsr w0, w13, #8
    and w1, w0, #1
    ubfx w3, w27, #4, #1
    lsr w2, w0, #1
    orr w2, w2, w3, lsl #7
    bfi w13, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L979
L980:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L979:
    mov w9, w24
    bl Lrd_slow
    b L980
    .p2align 4
Lfcb_1B:
    and w0, w13, #0xFF
    and w1, w0, #1
    ubfx w3, w27, #4, #1
    lsr w2, w0, #1
    orr w2, w2, w3, lsl #7
    bfi w13, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L981
L982:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L981:
    mov w9, w24
    bl Lrd_slow
    b L982
    .p2align 4
Lfcb_1C:
    lsr w0, w14, #8
    and w1, w0, #1
    ubfx w3, w27, #4, #1
    lsr w2, w0, #1
    orr w2, w2, w3, lsl #7
    bfi w14, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L983
L984:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L983:
    mov w9, w24
    bl Lrd_slow
    b L984
    .p2align 4
Lfcb_1D:
    and w0, w14, #0xFF
    and w1, w0, #1
    ubfx w3, w27, #4, #1
    lsr w2, w0, #1
    orr w2, w2, w3, lsl #7
    bfi w14, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L985
L986:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L985:
    mov w9, w24
    bl Lrd_slow
    b L986
    .p2align 4
Lfcb_1E:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L987
L988:
    ldrb w11, [x10, w9, uxtw]
    and w1, w11, #1
    ubfx w3, w27, #4, #1
    lsr w2, w11, #1
    orr w2, w2, w3, lsl #7
    and w11, w2, #0xFF
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L989
    strb w11, [x10, w9, uxtw]
L990:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L991
L992:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L987:
    bl Lrd_slow
    b L988
L989:
    mov w0, w11
    bl Lwr_slow
    b L990
L991:
    mov w9, w24
    bl Lrd_slow
    b L992
    .p2align 4
Lfcb_1F:
    and w1, w26, #1
    ubfx w3, w27, #4, #1
    lsr w2, w26, #1
    orr w2, w2, w3, lsl #7
    and w26, w2, #0xFF
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L993
L994:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L993:
    mov w9, w24
    bl Lrd_slow
    b L994
    .p2align 4
Lfcb_20:
    lsr w0, w28, #8
    lsr w1, w0, #7
    lsl w2, w0, #1
    and w2, w2, #0xFF
    bfi w28, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L995
L996:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L995:
    mov w9, w24
    bl Lrd_slow
    b L996
    .p2align 4
Lfcb_21:
    and w0, w28, #0xFF
    lsr w1, w0, #7
    lsl w2, w0, #1
    and w2, w2, #0xFF
    bfi w28, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L997
L998:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L997:
    mov w9, w24
    bl Lrd_slow
    b L998
    .p2align 4
Lfcb_22:
    lsr w0, w13, #8
    lsr w1, w0, #7
    lsl w2, w0, #1
    and w2, w2, #0xFF
    bfi w13, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L999
L1000:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L999:
    mov w9, w24
    bl Lrd_slow
    b L1000
    .p2align 4
Lfcb_23:
    and w0, w13, #0xFF
    lsr w1, w0, #7
    lsl w2, w0, #1
    and w2, w2, #0xFF
    bfi w13, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1001
L1002:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1001:
    mov w9, w24
    bl Lrd_slow
    b L1002
    .p2align 4
Lfcb_24:
    lsr w0, w14, #8
    lsr w1, w0, #7
    lsl w2, w0, #1
    and w2, w2, #0xFF
    bfi w14, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1003
L1004:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1003:
    mov w9, w24
    bl Lrd_slow
    b L1004
    .p2align 4
Lfcb_25:
    and w0, w14, #0xFF
    lsr w1, w0, #7
    lsl w2, w0, #1
    and w2, w2, #0xFF
    bfi w14, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1005
L1006:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1005:
    mov w9, w24
    bl Lrd_slow
    b L1006
    .p2align 4
Lfcb_26:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1007
L1008:
    ldrb w11, [x10, w9, uxtw]
    lsr w1, w11, #7
    lsl w2, w11, #1
    and w2, w2, #0xFF
    and w11, w2, #0xFF
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1009
    strb w11, [x10, w9, uxtw]
L1010:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1011
L1012:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1007:
    bl Lrd_slow
    b L1008
L1009:
    mov w0, w11
    bl Lwr_slow
    b L1010
L1011:
    mov w9, w24
    bl Lrd_slow
    b L1012
    .p2align 4
Lfcb_27:
    lsr w1, w26, #7
    lsl w2, w26, #1
    and w2, w2, #0xFF
    and w26, w2, #0xFF
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1013
L1014:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1013:
    mov w9, w24
    bl Lrd_slow
    b L1014
    .p2align 4
Lfcb_28:
    lsr w0, w28, #8
    and w1, w0, #1
    and w3, w0, #0x80
    lsr w2, w0, #1
    orr w2, w2, w3
    bfi w28, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1015
L1016:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1015:
    mov w9, w24
    bl Lrd_slow
    b L1016
    .p2align 4
Lfcb_29:
    and w0, w28, #0xFF
    and w1, w0, #1
    and w3, w0, #0x80
    lsr w2, w0, #1
    orr w2, w2, w3
    bfi w28, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1017
L1018:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1017:
    mov w9, w24
    bl Lrd_slow
    b L1018
    .p2align 4
Lfcb_2A:
    lsr w0, w13, #8
    and w1, w0, #1
    and w3, w0, #0x80
    lsr w2, w0, #1
    orr w2, w2, w3
    bfi w13, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1019
L1020:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1019:
    mov w9, w24
    bl Lrd_slow
    b L1020
    .p2align 4
Lfcb_2B:
    and w0, w13, #0xFF
    and w1, w0, #1
    and w3, w0, #0x80
    lsr w2, w0, #1
    orr w2, w2, w3
    bfi w13, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1021
L1022:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1021:
    mov w9, w24
    bl Lrd_slow
    b L1022
    .p2align 4
Lfcb_2C:
    lsr w0, w14, #8
    and w1, w0, #1
    and w3, w0, #0x80
    lsr w2, w0, #1
    orr w2, w2, w3
    bfi w14, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1023
L1024:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1023:
    mov w9, w24
    bl Lrd_slow
    b L1024
    .p2align 4
Lfcb_2D:
    and w0, w14, #0xFF
    and w1, w0, #1
    and w3, w0, #0x80
    lsr w2, w0, #1
    orr w2, w2, w3
    bfi w14, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1025
L1026:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1025:
    mov w9, w24
    bl Lrd_slow
    b L1026
    .p2align 4
Lfcb_2E:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1027
L1028:
    ldrb w11, [x10, w9, uxtw]
    and w1, w11, #1
    and w3, w11, #0x80
    lsr w2, w11, #1
    orr w2, w2, w3
    and w11, w2, #0xFF
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1029
    strb w11, [x10, w9, uxtw]
L1030:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1031
L1032:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1027:
    bl Lrd_slow
    b L1028
L1029:
    mov w0, w11
    bl Lwr_slow
    b L1030
L1031:
    mov w9, w24
    bl Lrd_slow
    b L1032
    .p2align 4
Lfcb_2F:
    and w1, w26, #1
    and w3, w26, #0x80
    lsr w2, w26, #1
    orr w2, w2, w3
    and w26, w2, #0xFF
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1033
L1034:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1033:
    mov w9, w24
    bl Lrd_slow
    b L1034
    .p2align 4
Lfcb_30:
    lsr w0, w28, #8
    mov w1, #0
    lsl w2, w0, #4
    orr w2, w2, w0, lsr #4
    and w2, w2, #0xFF
    bfi w28, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1035
L1036:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1035:
    mov w9, w24
    bl Lrd_slow
    b L1036
    .p2align 4
Lfcb_31:
    and w0, w28, #0xFF
    mov w1, #0
    lsl w2, w0, #4
    orr w2, w2, w0, lsr #4
    and w2, w2, #0xFF
    bfi w28, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1037
L1038:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1037:
    mov w9, w24
    bl Lrd_slow
    b L1038
    .p2align 4
Lfcb_32:
    lsr w0, w13, #8
    mov w1, #0
    lsl w2, w0, #4
    orr w2, w2, w0, lsr #4
    and w2, w2, #0xFF
    bfi w13, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1039
L1040:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1039:
    mov w9, w24
    bl Lrd_slow
    b L1040
    .p2align 4
Lfcb_33:
    and w0, w13, #0xFF
    mov w1, #0
    lsl w2, w0, #4
    orr w2, w2, w0, lsr #4
    and w2, w2, #0xFF
    bfi w13, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1041
L1042:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1041:
    mov w9, w24
    bl Lrd_slow
    b L1042
    .p2align 4
Lfcb_34:
    lsr w0, w14, #8
    mov w1, #0
    lsl w2, w0, #4
    orr w2, w2, w0, lsr #4
    and w2, w2, #0xFF
    bfi w14, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1043
L1044:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1043:
    mov w9, w24
    bl Lrd_slow
    b L1044
    .p2align 4
Lfcb_35:
    and w0, w14, #0xFF
    mov w1, #0
    lsl w2, w0, #4
    orr w2, w2, w0, lsr #4
    and w2, w2, #0xFF
    bfi w14, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1045
L1046:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1045:
    mov w9, w24
    bl Lrd_slow
    b L1046
    .p2align 4
Lfcb_36:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1047
L1048:
    ldrb w11, [x10, w9, uxtw]
    mov w1, #0
    lsl w2, w11, #4
    orr w2, w2, w11, lsr #4
    and w2, w2, #0xFF
    and w11, w2, #0xFF
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1049
    strb w11, [x10, w9, uxtw]
L1050:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1051
L1052:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1047:
    bl Lrd_slow
    b L1048
L1049:
    mov w0, w11
    bl Lwr_slow
    b L1050
L1051:
    mov w9, w24
    bl Lrd_slow
    b L1052
    .p2align 4
Lfcb_37:
    mov w1, #0
    lsl w2, w26, #4
    orr w2, w2, w26, lsr #4
    and w2, w2, #0xFF
    and w26, w2, #0xFF
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1053
L1054:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1053:
    mov w9, w24
    bl Lrd_slow
    b L1054
    .p2align 4
Lfcb_38:
    lsr w0, w28, #8
    and w1, w0, #1
    lsr w2, w0, #1
    bfi w28, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1055
L1056:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1055:
    mov w9, w24
    bl Lrd_slow
    b L1056
    .p2align 4
Lfcb_39:
    and w0, w28, #0xFF
    and w1, w0, #1
    lsr w2, w0, #1
    bfi w28, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1057
L1058:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1057:
    mov w9, w24
    bl Lrd_slow
    b L1058
    .p2align 4
Lfcb_3A:
    lsr w0, w13, #8
    and w1, w0, #1
    lsr w2, w0, #1
    bfi w13, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1059
L1060:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1059:
    mov w9, w24
    bl Lrd_slow
    b L1060
    .p2align 4
Lfcb_3B:
    and w0, w13, #0xFF
    and w1, w0, #1
    lsr w2, w0, #1
    bfi w13, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1061
L1062:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1061:
    mov w9, w24
    bl Lrd_slow
    b L1062
    .p2align 4
Lfcb_3C:
    lsr w0, w14, #8
    and w1, w0, #1
    lsr w2, w0, #1
    bfi w14, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1063
L1064:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1063:
    mov w9, w24
    bl Lrd_slow
    b L1064
    .p2align 4
Lfcb_3D:
    and w0, w14, #0xFF
    and w1, w0, #1
    lsr w2, w0, #1
    bfi w14, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1065
L1066:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1065:
    mov w9, w24
    bl Lrd_slow
    b L1066
    .p2align 4
Lfcb_3E:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1067
L1068:
    ldrb w11, [x10, w9, uxtw]
    and w1, w11, #1
    lsr w2, w11, #1
    and w11, w2, #0xFF
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1069
    strb w11, [x10, w9, uxtw]
L1070:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1071
L1072:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1067:
    bl Lrd_slow
    b L1068
L1069:
    mov w0, w11
    bl Lwr_slow
    b L1070
L1071:
    mov w9, w24
    bl Lrd_slow
    b L1072
    .p2align 4
Lfcb_3F:
    and w1, w26, #1
    lsr w2, w26, #1
    and w26, w2, #0xFF
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1073
L1074:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1073:
    mov w9, w24
    bl Lrd_slow
    b L1074
    .p2align 4
Lfcb_40:
    lsr w0, w28, #8
    tst w0, #1
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1075
L1076:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1075:
    mov w9, w24
    bl Lrd_slow
    b L1076
    .p2align 4
Lfcb_41:
    and w0, w28, #0xFF
    tst w0, #1
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1077
L1078:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1077:
    mov w9, w24
    bl Lrd_slow
    b L1078
    .p2align 4
Lfcb_42:
    lsr w0, w13, #8
    tst w0, #1
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1079
L1080:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1079:
    mov w9, w24
    bl Lrd_slow
    b L1080
    .p2align 4
Lfcb_43:
    and w0, w13, #0xFF
    tst w0, #1
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1081
L1082:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1081:
    mov w9, w24
    bl Lrd_slow
    b L1082
    .p2align 4
Lfcb_44:
    lsr w0, w14, #8
    tst w0, #1
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1083
L1084:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1083:
    mov w9, w24
    bl Lrd_slow
    b L1084
    .p2align 4
Lfcb_45:
    and w0, w14, #0xFF
    tst w0, #1
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1085
L1086:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1085:
    mov w9, w24
    bl Lrd_slow
    b L1086
    .p2align 4
Lfcb_46:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1087
L1088:
    ldrb w11, [x10, w9, uxtw]
    tst w11, #1
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1089
L1090:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1087:
    bl Lrd_slow
    b L1088
L1089:
    mov w9, w24
    bl Lrd_slow
    b L1090
    .p2align 4
Lfcb_47:
    tst w26, #1
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1091
L1092:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1091:
    mov w9, w24
    bl Lrd_slow
    b L1092
    .p2align 4
Lfcb_48:
    lsr w0, w28, #8
    tst w0, #2
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1093
L1094:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1093:
    mov w9, w24
    bl Lrd_slow
    b L1094
    .p2align 4
Lfcb_49:
    and w0, w28, #0xFF
    tst w0, #2
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1095
L1096:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1095:
    mov w9, w24
    bl Lrd_slow
    b L1096
    .p2align 4
Lfcb_4A:
    lsr w0, w13, #8
    tst w0, #2
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1097
L1098:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1097:
    mov w9, w24
    bl Lrd_slow
    b L1098
    .p2align 4
Lfcb_4B:
    and w0, w13, #0xFF
    tst w0, #2
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1099
L1100:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1099:
    mov w9, w24
    bl Lrd_slow
    b L1100
    .p2align 4
Lfcb_4C:
    lsr w0, w14, #8
    tst w0, #2
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1101
L1102:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1101:
    mov w9, w24
    bl Lrd_slow
    b L1102
    .p2align 4
Lfcb_4D:
    and w0, w14, #0xFF
    tst w0, #2
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1103
L1104:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1103:
    mov w9, w24
    bl Lrd_slow
    b L1104
    .p2align 4
Lfcb_4E:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1105
L1106:
    ldrb w11, [x10, w9, uxtw]
    tst w11, #2
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1107
L1108:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1105:
    bl Lrd_slow
    b L1106
L1107:
    mov w9, w24
    bl Lrd_slow
    b L1108
    .p2align 4
Lfcb_4F:
    tst w26, #2
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1109
L1110:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1109:
    mov w9, w24
    bl Lrd_slow
    b L1110
    .p2align 4
Lfcb_50:
    lsr w0, w28, #8
    tst w0, #4
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1111
L1112:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1111:
    mov w9, w24
    bl Lrd_slow
    b L1112
    .p2align 4
Lfcb_51:
    and w0, w28, #0xFF
    tst w0, #4
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1113
L1114:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1113:
    mov w9, w24
    bl Lrd_slow
    b L1114
    .p2align 4
Lfcb_52:
    lsr w0, w13, #8
    tst w0, #4
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1115
L1116:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1115:
    mov w9, w24
    bl Lrd_slow
    b L1116
    .p2align 4
Lfcb_53:
    and w0, w13, #0xFF
    tst w0, #4
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1117
L1118:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1117:
    mov w9, w24
    bl Lrd_slow
    b L1118
    .p2align 4
Lfcb_54:
    lsr w0, w14, #8
    tst w0, #4
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1119
L1120:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1119:
    mov w9, w24
    bl Lrd_slow
    b L1120
    .p2align 4
Lfcb_55:
    and w0, w14, #0xFF
    tst w0, #4
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1121
L1122:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1121:
    mov w9, w24
    bl Lrd_slow
    b L1122
    .p2align 4
Lfcb_56:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1123
L1124:
    ldrb w11, [x10, w9, uxtw]
    tst w11, #4
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1125
L1126:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1123:
    bl Lrd_slow
    b L1124
L1125:
    mov w9, w24
    bl Lrd_slow
    b L1126
    .p2align 4
Lfcb_57:
    tst w26, #4
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1127
L1128:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1127:
    mov w9, w24
    bl Lrd_slow
    b L1128
    .p2align 4
Lfcb_58:
    lsr w0, w28, #8
    tst w0, #8
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1129
L1130:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1129:
    mov w9, w24
    bl Lrd_slow
    b L1130
    .p2align 4
Lfcb_59:
    and w0, w28, #0xFF
    tst w0, #8
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1131
L1132:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1131:
    mov w9, w24
    bl Lrd_slow
    b L1132
    .p2align 4
Lfcb_5A:
    lsr w0, w13, #8
    tst w0, #8
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1133
L1134:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1133:
    mov w9, w24
    bl Lrd_slow
    b L1134
    .p2align 4
Lfcb_5B:
    and w0, w13, #0xFF
    tst w0, #8
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1135
L1136:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1135:
    mov w9, w24
    bl Lrd_slow
    b L1136
    .p2align 4
Lfcb_5C:
    lsr w0, w14, #8
    tst w0, #8
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1137
L1138:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1137:
    mov w9, w24
    bl Lrd_slow
    b L1138
    .p2align 4
Lfcb_5D:
    and w0, w14, #0xFF
    tst w0, #8
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1139
L1140:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1139:
    mov w9, w24
    bl Lrd_slow
    b L1140
    .p2align 4
Lfcb_5E:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1141
L1142:
    ldrb w11, [x10, w9, uxtw]
    tst w11, #8
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1143
L1144:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1141:
    bl Lrd_slow
    b L1142
L1143:
    mov w9, w24
    bl Lrd_slow
    b L1144
    .p2align 4
Lfcb_5F:
    tst w26, #8
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1145
L1146:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1145:
    mov w9, w24
    bl Lrd_slow
    b L1146
    .p2align 4
Lfcb_60:
    lsr w0, w28, #8
    tst w0, #16
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1147
L1148:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1147:
    mov w9, w24
    bl Lrd_slow
    b L1148
    .p2align 4
Lfcb_61:
    and w0, w28, #0xFF
    tst w0, #16
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1149
L1150:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1149:
    mov w9, w24
    bl Lrd_slow
    b L1150
    .p2align 4
Lfcb_62:
    lsr w0, w13, #8
    tst w0, #16
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1151
L1152:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1151:
    mov w9, w24
    bl Lrd_slow
    b L1152
    .p2align 4
Lfcb_63:
    and w0, w13, #0xFF
    tst w0, #16
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1153
L1154:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1153:
    mov w9, w24
    bl Lrd_slow
    b L1154
    .p2align 4
Lfcb_64:
    lsr w0, w14, #8
    tst w0, #16
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1155
L1156:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1155:
    mov w9, w24
    bl Lrd_slow
    b L1156
    .p2align 4
Lfcb_65:
    and w0, w14, #0xFF
    tst w0, #16
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1157
L1158:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1157:
    mov w9, w24
    bl Lrd_slow
    b L1158
    .p2align 4
Lfcb_66:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1159
L1160:
    ldrb w11, [x10, w9, uxtw]
    tst w11, #16
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1161
L1162:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1159:
    bl Lrd_slow
    b L1160
L1161:
    mov w9, w24
    bl Lrd_slow
    b L1162
    .p2align 4
Lfcb_67:
    tst w26, #16
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1163
L1164:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1163:
    mov w9, w24
    bl Lrd_slow
    b L1164
    .p2align 4
Lfcb_68:
    lsr w0, w28, #8
    tst w0, #32
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1165
L1166:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1165:
    mov w9, w24
    bl Lrd_slow
    b L1166
    .p2align 4
Lfcb_69:
    and w0, w28, #0xFF
    tst w0, #32
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1167
L1168:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1167:
    mov w9, w24
    bl Lrd_slow
    b L1168
    .p2align 4
Lfcb_6A:
    lsr w0, w13, #8
    tst w0, #32
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1169
L1170:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1169:
    mov w9, w24
    bl Lrd_slow
    b L1170
    .p2align 4
Lfcb_6B:
    and w0, w13, #0xFF
    tst w0, #32
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1171
L1172:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1171:
    mov w9, w24
    bl Lrd_slow
    b L1172
    .p2align 4
Lfcb_6C:
    lsr w0, w14, #8
    tst w0, #32
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1173
L1174:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1173:
    mov w9, w24
    bl Lrd_slow
    b L1174
    .p2align 4
Lfcb_6D:
    and w0, w14, #0xFF
    tst w0, #32
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1175
L1176:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1175:
    mov w9, w24
    bl Lrd_slow
    b L1176
    .p2align 4
Lfcb_6E:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1177
L1178:
    ldrb w11, [x10, w9, uxtw]
    tst w11, #32
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1179
L1180:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1177:
    bl Lrd_slow
    b L1178
L1179:
    mov w9, w24
    bl Lrd_slow
    b L1180
    .p2align 4
Lfcb_6F:
    tst w26, #32
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1181
L1182:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1181:
    mov w9, w24
    bl Lrd_slow
    b L1182
    .p2align 4
Lfcb_70:
    lsr w0, w28, #8
    tst w0, #64
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1183
L1184:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1183:
    mov w9, w24
    bl Lrd_slow
    b L1184
    .p2align 4
Lfcb_71:
    and w0, w28, #0xFF
    tst w0, #64
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1185
L1186:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1185:
    mov w9, w24
    bl Lrd_slow
    b L1186
    .p2align 4
Lfcb_72:
    lsr w0, w13, #8
    tst w0, #64
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1187
L1188:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1187:
    mov w9, w24
    bl Lrd_slow
    b L1188
    .p2align 4
Lfcb_73:
    and w0, w13, #0xFF
    tst w0, #64
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1189
L1190:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1189:
    mov w9, w24
    bl Lrd_slow
    b L1190
    .p2align 4
Lfcb_74:
    lsr w0, w14, #8
    tst w0, #64
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1191
L1192:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1191:
    mov w9, w24
    bl Lrd_slow
    b L1192
    .p2align 4
Lfcb_75:
    and w0, w14, #0xFF
    tst w0, #64
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1193
L1194:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1193:
    mov w9, w24
    bl Lrd_slow
    b L1194
    .p2align 4
Lfcb_76:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1195
L1196:
    ldrb w11, [x10, w9, uxtw]
    tst w11, #64
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1197
L1198:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1195:
    bl Lrd_slow
    b L1196
L1197:
    mov w9, w24
    bl Lrd_slow
    b L1198
    .p2align 4
Lfcb_77:
    tst w26, #64
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1199
L1200:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1199:
    mov w9, w24
    bl Lrd_slow
    b L1200
    .p2align 4
Lfcb_78:
    lsr w0, w28, #8
    tst w0, #128
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1201
L1202:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1201:
    mov w9, w24
    bl Lrd_slow
    b L1202
    .p2align 4
Lfcb_79:
    and w0, w28, #0xFF
    tst w0, #128
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1203
L1204:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1203:
    mov w9, w24
    bl Lrd_slow
    b L1204
    .p2align 4
Lfcb_7A:
    lsr w0, w13, #8
    tst w0, #128
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1205
L1206:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1205:
    mov w9, w24
    bl Lrd_slow
    b L1206
    .p2align 4
Lfcb_7B:
    and w0, w13, #0xFF
    tst w0, #128
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1207
L1208:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1207:
    mov w9, w24
    bl Lrd_slow
    b L1208
    .p2align 4
Lfcb_7C:
    lsr w0, w14, #8
    tst w0, #128
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1209
L1210:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1209:
    mov w9, w24
    bl Lrd_slow
    b L1210
    .p2align 4
Lfcb_7D:
    and w0, w14, #0xFF
    tst w0, #128
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1211
L1212:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1211:
    mov w9, w24
    bl Lrd_slow
    b L1212
    .p2align 4
Lfcb_7E:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1213
L1214:
    ldrb w11, [x10, w9, uxtw]
    tst w11, #128
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1215
L1216:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1213:
    bl Lrd_slow
    b L1214
L1215:
    mov w9, w24
    bl Lrd_slow
    b L1216
    .p2align 4
Lfcb_7F:
    tst w26, #128
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1217
L1218:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1217:
    mov w9, w24
    bl Lrd_slow
    b L1218
    .p2align 4
Lfcb_80:
    lsr w0, w28, #8
    and w2, w0, #0xFFFFFFFE
    bfi w28, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1219
L1220:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1219:
    mov w9, w24
    bl Lrd_slow
    b L1220
    .p2align 4
Lfcb_81:
    and w0, w28, #0xFF
    and w2, w0, #0xFFFFFFFE
    bfi w28, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1221
L1222:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1221:
    mov w9, w24
    bl Lrd_slow
    b L1222
    .p2align 4
Lfcb_82:
    lsr w0, w13, #8
    and w2, w0, #0xFFFFFFFE
    bfi w13, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1223
L1224:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1223:
    mov w9, w24
    bl Lrd_slow
    b L1224
    .p2align 4
Lfcb_83:
    and w0, w13, #0xFF
    and w2, w0, #0xFFFFFFFE
    bfi w13, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1225
L1226:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1225:
    mov w9, w24
    bl Lrd_slow
    b L1226
    .p2align 4
Lfcb_84:
    lsr w0, w14, #8
    and w2, w0, #0xFFFFFFFE
    bfi w14, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1227
L1228:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1227:
    mov w9, w24
    bl Lrd_slow
    b L1228
    .p2align 4
Lfcb_85:
    and w0, w14, #0xFF
    and w2, w0, #0xFFFFFFFE
    bfi w14, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1229
L1230:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1229:
    mov w9, w24
    bl Lrd_slow
    b L1230
    .p2align 4
Lfcb_86:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1231
L1232:
    ldrb w11, [x10, w9, uxtw]
    and w2, w11, #0xFFFFFFFE
    and w11, w2, #0xFF
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1233
    strb w11, [x10, w9, uxtw]
L1234:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1235
L1236:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1231:
    bl Lrd_slow
    b L1232
L1233:
    mov w0, w11
    bl Lwr_slow
    b L1234
L1235:
    mov w9, w24
    bl Lrd_slow
    b L1236
    .p2align 4
Lfcb_87:
    and w2, w26, #0xFFFFFFFE
    and w26, w2, #0xFF
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1237
L1238:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1237:
    mov w9, w24
    bl Lrd_slow
    b L1238
    .p2align 4
Lfcb_88:
    lsr w0, w28, #8
    and w2, w0, #0xFFFFFFFD
    bfi w28, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1239
L1240:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1239:
    mov w9, w24
    bl Lrd_slow
    b L1240
    .p2align 4
Lfcb_89:
    and w0, w28, #0xFF
    and w2, w0, #0xFFFFFFFD
    bfi w28, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1241
L1242:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1241:
    mov w9, w24
    bl Lrd_slow
    b L1242
    .p2align 4
Lfcb_8A:
    lsr w0, w13, #8
    and w2, w0, #0xFFFFFFFD
    bfi w13, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1243
L1244:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1243:
    mov w9, w24
    bl Lrd_slow
    b L1244
    .p2align 4
Lfcb_8B:
    and w0, w13, #0xFF
    and w2, w0, #0xFFFFFFFD
    bfi w13, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1245
L1246:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1245:
    mov w9, w24
    bl Lrd_slow
    b L1246
    .p2align 4
Lfcb_8C:
    lsr w0, w14, #8
    and w2, w0, #0xFFFFFFFD
    bfi w14, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1247
L1248:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1247:
    mov w9, w24
    bl Lrd_slow
    b L1248
    .p2align 4
Lfcb_8D:
    and w0, w14, #0xFF
    and w2, w0, #0xFFFFFFFD
    bfi w14, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1249
L1250:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1249:
    mov w9, w24
    bl Lrd_slow
    b L1250
    .p2align 4
Lfcb_8E:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1251
L1252:
    ldrb w11, [x10, w9, uxtw]
    and w2, w11, #0xFFFFFFFD
    and w11, w2, #0xFF
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1253
    strb w11, [x10, w9, uxtw]
L1254:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1255
L1256:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1251:
    bl Lrd_slow
    b L1252
L1253:
    mov w0, w11
    bl Lwr_slow
    b L1254
L1255:
    mov w9, w24
    bl Lrd_slow
    b L1256
    .p2align 4
Lfcb_8F:
    and w2, w26, #0xFFFFFFFD
    and w26, w2, #0xFF
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1257
L1258:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1257:
    mov w9, w24
    bl Lrd_slow
    b L1258
    .p2align 4
Lfcb_90:
    lsr w0, w28, #8
    and w2, w0, #0xFFFFFFFB
    bfi w28, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1259
L1260:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1259:
    mov w9, w24
    bl Lrd_slow
    b L1260
    .p2align 4
Lfcb_91:
    and w0, w28, #0xFF
    and w2, w0, #0xFFFFFFFB
    bfi w28, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1261
L1262:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1261:
    mov w9, w24
    bl Lrd_slow
    b L1262
    .p2align 4
Lfcb_92:
    lsr w0, w13, #8
    and w2, w0, #0xFFFFFFFB
    bfi w13, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1263
L1264:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1263:
    mov w9, w24
    bl Lrd_slow
    b L1264
    .p2align 4
Lfcb_93:
    and w0, w13, #0xFF
    and w2, w0, #0xFFFFFFFB
    bfi w13, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1265
L1266:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1265:
    mov w9, w24
    bl Lrd_slow
    b L1266
    .p2align 4
Lfcb_94:
    lsr w0, w14, #8
    and w2, w0, #0xFFFFFFFB
    bfi w14, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1267
L1268:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1267:
    mov w9, w24
    bl Lrd_slow
    b L1268
    .p2align 4
Lfcb_95:
    and w0, w14, #0xFF
    and w2, w0, #0xFFFFFFFB
    bfi w14, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1269
L1270:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1269:
    mov w9, w24
    bl Lrd_slow
    b L1270
    .p2align 4
Lfcb_96:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1271
L1272:
    ldrb w11, [x10, w9, uxtw]
    and w2, w11, #0xFFFFFFFB
    and w11, w2, #0xFF
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1273
    strb w11, [x10, w9, uxtw]
L1274:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1275
L1276:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1271:
    bl Lrd_slow
    b L1272
L1273:
    mov w0, w11
    bl Lwr_slow
    b L1274
L1275:
    mov w9, w24
    bl Lrd_slow
    b L1276
    .p2align 4
Lfcb_97:
    and w2, w26, #0xFFFFFFFB
    and w26, w2, #0xFF
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1277
L1278:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1277:
    mov w9, w24
    bl Lrd_slow
    b L1278
    .p2align 4
Lfcb_98:
    lsr w0, w28, #8
    and w2, w0, #0xFFFFFFF7
    bfi w28, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1279
L1280:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1279:
    mov w9, w24
    bl Lrd_slow
    b L1280
    .p2align 4
Lfcb_99:
    and w0, w28, #0xFF
    and w2, w0, #0xFFFFFFF7
    bfi w28, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1281
L1282:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1281:
    mov w9, w24
    bl Lrd_slow
    b L1282
    .p2align 4
Lfcb_9A:
    lsr w0, w13, #8
    and w2, w0, #0xFFFFFFF7
    bfi w13, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1283
L1284:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1283:
    mov w9, w24
    bl Lrd_slow
    b L1284
    .p2align 4
Lfcb_9B:
    and w0, w13, #0xFF
    and w2, w0, #0xFFFFFFF7
    bfi w13, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1285
L1286:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1285:
    mov w9, w24
    bl Lrd_slow
    b L1286
    .p2align 4
Lfcb_9C:
    lsr w0, w14, #8
    and w2, w0, #0xFFFFFFF7
    bfi w14, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1287
L1288:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1287:
    mov w9, w24
    bl Lrd_slow
    b L1288
    .p2align 4
Lfcb_9D:
    and w0, w14, #0xFF
    and w2, w0, #0xFFFFFFF7
    bfi w14, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1289
L1290:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1289:
    mov w9, w24
    bl Lrd_slow
    b L1290
    .p2align 4
Lfcb_9E:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1291
L1292:
    ldrb w11, [x10, w9, uxtw]
    and w2, w11, #0xFFFFFFF7
    and w11, w2, #0xFF
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1293
    strb w11, [x10, w9, uxtw]
L1294:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1295
L1296:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1291:
    bl Lrd_slow
    b L1292
L1293:
    mov w0, w11
    bl Lwr_slow
    b L1294
L1295:
    mov w9, w24
    bl Lrd_slow
    b L1296
    .p2align 4
Lfcb_9F:
    and w2, w26, #0xFFFFFFF7
    and w26, w2, #0xFF
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1297
L1298:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1297:
    mov w9, w24
    bl Lrd_slow
    b L1298
    .p2align 4
Lfcb_A0:
    lsr w0, w28, #8
    and w2, w0, #0xFFFFFFEF
    bfi w28, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1299
L1300:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1299:
    mov w9, w24
    bl Lrd_slow
    b L1300
    .p2align 4
Lfcb_A1:
    and w0, w28, #0xFF
    and w2, w0, #0xFFFFFFEF
    bfi w28, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1301
L1302:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1301:
    mov w9, w24
    bl Lrd_slow
    b L1302
    .p2align 4
Lfcb_A2:
    lsr w0, w13, #8
    and w2, w0, #0xFFFFFFEF
    bfi w13, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1303
L1304:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1303:
    mov w9, w24
    bl Lrd_slow
    b L1304
    .p2align 4
Lfcb_A3:
    and w0, w13, #0xFF
    and w2, w0, #0xFFFFFFEF
    bfi w13, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1305
L1306:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1305:
    mov w9, w24
    bl Lrd_slow
    b L1306
    .p2align 4
Lfcb_A4:
    lsr w0, w14, #8
    and w2, w0, #0xFFFFFFEF
    bfi w14, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1307
L1308:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1307:
    mov w9, w24
    bl Lrd_slow
    b L1308
    .p2align 4
Lfcb_A5:
    and w0, w14, #0xFF
    and w2, w0, #0xFFFFFFEF
    bfi w14, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1309
L1310:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1309:
    mov w9, w24
    bl Lrd_slow
    b L1310
    .p2align 4
Lfcb_A6:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1311
L1312:
    ldrb w11, [x10, w9, uxtw]
    and w2, w11, #0xFFFFFFEF
    and w11, w2, #0xFF
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1313
    strb w11, [x10, w9, uxtw]
L1314:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1315
L1316:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1311:
    bl Lrd_slow
    b L1312
L1313:
    mov w0, w11
    bl Lwr_slow
    b L1314
L1315:
    mov w9, w24
    bl Lrd_slow
    b L1316
    .p2align 4
Lfcb_A7:
    and w2, w26, #0xFFFFFFEF
    and w26, w2, #0xFF
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1317
L1318:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1317:
    mov w9, w24
    bl Lrd_slow
    b L1318
    .p2align 4
Lfcb_A8:
    lsr w0, w28, #8
    and w2, w0, #0xFFFFFFDF
    bfi w28, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1319
L1320:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1319:
    mov w9, w24
    bl Lrd_slow
    b L1320
    .p2align 4
Lfcb_A9:
    and w0, w28, #0xFF
    and w2, w0, #0xFFFFFFDF
    bfi w28, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1321
L1322:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1321:
    mov w9, w24
    bl Lrd_slow
    b L1322
    .p2align 4
Lfcb_AA:
    lsr w0, w13, #8
    and w2, w0, #0xFFFFFFDF
    bfi w13, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1323
L1324:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1323:
    mov w9, w24
    bl Lrd_slow
    b L1324
    .p2align 4
Lfcb_AB:
    and w0, w13, #0xFF
    and w2, w0, #0xFFFFFFDF
    bfi w13, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1325
L1326:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1325:
    mov w9, w24
    bl Lrd_slow
    b L1326
    .p2align 4
Lfcb_AC:
    lsr w0, w14, #8
    and w2, w0, #0xFFFFFFDF
    bfi w14, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1327
L1328:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1327:
    mov w9, w24
    bl Lrd_slow
    b L1328
    .p2align 4
Lfcb_AD:
    and w0, w14, #0xFF
    and w2, w0, #0xFFFFFFDF
    bfi w14, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1329
L1330:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1329:
    mov w9, w24
    bl Lrd_slow
    b L1330
    .p2align 4
Lfcb_AE:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1331
L1332:
    ldrb w11, [x10, w9, uxtw]
    and w2, w11, #0xFFFFFFDF
    and w11, w2, #0xFF
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1333
    strb w11, [x10, w9, uxtw]
L1334:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1335
L1336:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1331:
    bl Lrd_slow
    b L1332
L1333:
    mov w0, w11
    bl Lwr_slow
    b L1334
L1335:
    mov w9, w24
    bl Lrd_slow
    b L1336
    .p2align 4
Lfcb_AF:
    and w2, w26, #0xFFFFFFDF
    and w26, w2, #0xFF
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1337
L1338:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1337:
    mov w9, w24
    bl Lrd_slow
    b L1338
    .p2align 4
Lfcb_B0:
    lsr w0, w28, #8
    and w2, w0, #0xFFFFFFBF
    bfi w28, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1339
L1340:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1339:
    mov w9, w24
    bl Lrd_slow
    b L1340
    .p2align 4
Lfcb_B1:
    and w0, w28, #0xFF
    and w2, w0, #0xFFFFFFBF
    bfi w28, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1341
L1342:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1341:
    mov w9, w24
    bl Lrd_slow
    b L1342
    .p2align 4
Lfcb_B2:
    lsr w0, w13, #8
    and w2, w0, #0xFFFFFFBF
    bfi w13, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1343
L1344:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1343:
    mov w9, w24
    bl Lrd_slow
    b L1344
    .p2align 4
Lfcb_B3:
    and w0, w13, #0xFF
    and w2, w0, #0xFFFFFFBF
    bfi w13, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1345
L1346:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1345:
    mov w9, w24
    bl Lrd_slow
    b L1346
    .p2align 4
Lfcb_B4:
    lsr w0, w14, #8
    and w2, w0, #0xFFFFFFBF
    bfi w14, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1347
L1348:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1347:
    mov w9, w24
    bl Lrd_slow
    b L1348
    .p2align 4
Lfcb_B5:
    and w0, w14, #0xFF
    and w2, w0, #0xFFFFFFBF
    bfi w14, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1349
L1350:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1349:
    mov w9, w24
    bl Lrd_slow
    b L1350
    .p2align 4
Lfcb_B6:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1351
L1352:
    ldrb w11, [x10, w9, uxtw]
    and w2, w11, #0xFFFFFFBF
    and w11, w2, #0xFF
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1353
    strb w11, [x10, w9, uxtw]
L1354:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1355
L1356:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1351:
    bl Lrd_slow
    b L1352
L1353:
    mov w0, w11
    bl Lwr_slow
    b L1354
L1355:
    mov w9, w24
    bl Lrd_slow
    b L1356
    .p2align 4
Lfcb_B7:
    and w2, w26, #0xFFFFFFBF
    and w26, w2, #0xFF
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1357
L1358:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1357:
    mov w9, w24
    bl Lrd_slow
    b L1358
    .p2align 4
Lfcb_B8:
    lsr w0, w28, #8
    and w2, w0, #0xFFFFFF7F
    bfi w28, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1359
L1360:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1359:
    mov w9, w24
    bl Lrd_slow
    b L1360
    .p2align 4
Lfcb_B9:
    and w0, w28, #0xFF
    and w2, w0, #0xFFFFFF7F
    bfi w28, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1361
L1362:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1361:
    mov w9, w24
    bl Lrd_slow
    b L1362
    .p2align 4
Lfcb_BA:
    lsr w0, w13, #8
    and w2, w0, #0xFFFFFF7F
    bfi w13, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1363
L1364:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1363:
    mov w9, w24
    bl Lrd_slow
    b L1364
    .p2align 4
Lfcb_BB:
    and w0, w13, #0xFF
    and w2, w0, #0xFFFFFF7F
    bfi w13, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1365
L1366:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1365:
    mov w9, w24
    bl Lrd_slow
    b L1366
    .p2align 4
Lfcb_BC:
    lsr w0, w14, #8
    and w2, w0, #0xFFFFFF7F
    bfi w14, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1367
L1368:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1367:
    mov w9, w24
    bl Lrd_slow
    b L1368
    .p2align 4
Lfcb_BD:
    and w0, w14, #0xFF
    and w2, w0, #0xFFFFFF7F
    bfi w14, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1369
L1370:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1369:
    mov w9, w24
    bl Lrd_slow
    b L1370
    .p2align 4
Lfcb_BE:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1371
L1372:
    ldrb w11, [x10, w9, uxtw]
    and w2, w11, #0xFFFFFF7F
    and w11, w2, #0xFF
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1373
    strb w11, [x10, w9, uxtw]
L1374:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1375
L1376:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1371:
    bl Lrd_slow
    b L1372
L1373:
    mov w0, w11
    bl Lwr_slow
    b L1374
L1375:
    mov w9, w24
    bl Lrd_slow
    b L1376
    .p2align 4
Lfcb_BF:
    and w2, w26, #0xFFFFFF7F
    and w26, w2, #0xFF
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1377
L1378:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1377:
    mov w9, w24
    bl Lrd_slow
    b L1378
    .p2align 4
Lfcb_C0:
    lsr w0, w28, #8
    orr w2, w0, #1
    bfi w28, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1379
L1380:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1379:
    mov w9, w24
    bl Lrd_slow
    b L1380
    .p2align 4
Lfcb_C1:
    and w0, w28, #0xFF
    orr w2, w0, #1
    bfi w28, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1381
L1382:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1381:
    mov w9, w24
    bl Lrd_slow
    b L1382
    .p2align 4
Lfcb_C2:
    lsr w0, w13, #8
    orr w2, w0, #1
    bfi w13, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1383
L1384:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1383:
    mov w9, w24
    bl Lrd_slow
    b L1384
    .p2align 4
Lfcb_C3:
    and w0, w13, #0xFF
    orr w2, w0, #1
    bfi w13, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1385
L1386:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1385:
    mov w9, w24
    bl Lrd_slow
    b L1386
    .p2align 4
Lfcb_C4:
    lsr w0, w14, #8
    orr w2, w0, #1
    bfi w14, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1387
L1388:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1387:
    mov w9, w24
    bl Lrd_slow
    b L1388
    .p2align 4
Lfcb_C5:
    and w0, w14, #0xFF
    orr w2, w0, #1
    bfi w14, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1389
L1390:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1389:
    mov w9, w24
    bl Lrd_slow
    b L1390
    .p2align 4
Lfcb_C6:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1391
L1392:
    ldrb w11, [x10, w9, uxtw]
    orr w2, w11, #1
    and w11, w2, #0xFF
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1393
    strb w11, [x10, w9, uxtw]
L1394:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1395
L1396:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1391:
    bl Lrd_slow
    b L1392
L1393:
    mov w0, w11
    bl Lwr_slow
    b L1394
L1395:
    mov w9, w24
    bl Lrd_slow
    b L1396
    .p2align 4
Lfcb_C7:
    orr w2, w26, #1
    and w26, w2, #0xFF
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1397
L1398:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1397:
    mov w9, w24
    bl Lrd_slow
    b L1398
    .p2align 4
Lfcb_C8:
    lsr w0, w28, #8
    orr w2, w0, #2
    bfi w28, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1399
L1400:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1399:
    mov w9, w24
    bl Lrd_slow
    b L1400
    .p2align 4
Lfcb_C9:
    and w0, w28, #0xFF
    orr w2, w0, #2
    bfi w28, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1401
L1402:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1401:
    mov w9, w24
    bl Lrd_slow
    b L1402
    .p2align 4
Lfcb_CA:
    lsr w0, w13, #8
    orr w2, w0, #2
    bfi w13, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1403
L1404:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1403:
    mov w9, w24
    bl Lrd_slow
    b L1404
    .p2align 4
Lfcb_CB:
    and w0, w13, #0xFF
    orr w2, w0, #2
    bfi w13, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1405
L1406:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1405:
    mov w9, w24
    bl Lrd_slow
    b L1406
    .p2align 4
Lfcb_CC:
    lsr w0, w14, #8
    orr w2, w0, #2
    bfi w14, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1407
L1408:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1407:
    mov w9, w24
    bl Lrd_slow
    b L1408
    .p2align 4
Lfcb_CD:
    and w0, w14, #0xFF
    orr w2, w0, #2
    bfi w14, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1409
L1410:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1409:
    mov w9, w24
    bl Lrd_slow
    b L1410
    .p2align 4
Lfcb_CE:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1411
L1412:
    ldrb w11, [x10, w9, uxtw]
    orr w2, w11, #2
    and w11, w2, #0xFF
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1413
    strb w11, [x10, w9, uxtw]
L1414:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1415
L1416:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1411:
    bl Lrd_slow
    b L1412
L1413:
    mov w0, w11
    bl Lwr_slow
    b L1414
L1415:
    mov w9, w24
    bl Lrd_slow
    b L1416
    .p2align 4
Lfcb_CF:
    orr w2, w26, #2
    and w26, w2, #0xFF
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1417
L1418:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1417:
    mov w9, w24
    bl Lrd_slow
    b L1418
    .p2align 4
Lfcb_D0:
    lsr w0, w28, #8
    orr w2, w0, #4
    bfi w28, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1419
L1420:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1419:
    mov w9, w24
    bl Lrd_slow
    b L1420
    .p2align 4
Lfcb_D1:
    and w0, w28, #0xFF
    orr w2, w0, #4
    bfi w28, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1421
L1422:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1421:
    mov w9, w24
    bl Lrd_slow
    b L1422
    .p2align 4
Lfcb_D2:
    lsr w0, w13, #8
    orr w2, w0, #4
    bfi w13, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1423
L1424:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1423:
    mov w9, w24
    bl Lrd_slow
    b L1424
    .p2align 4
Lfcb_D3:
    and w0, w13, #0xFF
    orr w2, w0, #4
    bfi w13, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1425
L1426:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1425:
    mov w9, w24
    bl Lrd_slow
    b L1426
    .p2align 4
Lfcb_D4:
    lsr w0, w14, #8
    orr w2, w0, #4
    bfi w14, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1427
L1428:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1427:
    mov w9, w24
    bl Lrd_slow
    b L1428
    .p2align 4
Lfcb_D5:
    and w0, w14, #0xFF
    orr w2, w0, #4
    bfi w14, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1429
L1430:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1429:
    mov w9, w24
    bl Lrd_slow
    b L1430
    .p2align 4
Lfcb_D6:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1431
L1432:
    ldrb w11, [x10, w9, uxtw]
    orr w2, w11, #4
    and w11, w2, #0xFF
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1433
    strb w11, [x10, w9, uxtw]
L1434:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1435
L1436:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1431:
    bl Lrd_slow
    b L1432
L1433:
    mov w0, w11
    bl Lwr_slow
    b L1434
L1435:
    mov w9, w24
    bl Lrd_slow
    b L1436
    .p2align 4
Lfcb_D7:
    orr w2, w26, #4
    and w26, w2, #0xFF
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1437
L1438:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1437:
    mov w9, w24
    bl Lrd_slow
    b L1438
    .p2align 4
Lfcb_D8:
    lsr w0, w28, #8
    orr w2, w0, #8
    bfi w28, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1439
L1440:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1439:
    mov w9, w24
    bl Lrd_slow
    b L1440
    .p2align 4
Lfcb_D9:
    and w0, w28, #0xFF
    orr w2, w0, #8
    bfi w28, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1441
L1442:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1441:
    mov w9, w24
    bl Lrd_slow
    b L1442
    .p2align 4
Lfcb_DA:
    lsr w0, w13, #8
    orr w2, w0, #8
    bfi w13, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1443
L1444:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1443:
    mov w9, w24
    bl Lrd_slow
    b L1444
    .p2align 4
Lfcb_DB:
    and w0, w13, #0xFF
    orr w2, w0, #8
    bfi w13, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1445
L1446:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1445:
    mov w9, w24
    bl Lrd_slow
    b L1446
    .p2align 4
Lfcb_DC:
    lsr w0, w14, #8
    orr w2, w0, #8
    bfi w14, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1447
L1448:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1447:
    mov w9, w24
    bl Lrd_slow
    b L1448
    .p2align 4
Lfcb_DD:
    and w0, w14, #0xFF
    orr w2, w0, #8
    bfi w14, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1449
L1450:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1449:
    mov w9, w24
    bl Lrd_slow
    b L1450
    .p2align 4
Lfcb_DE:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1451
L1452:
    ldrb w11, [x10, w9, uxtw]
    orr w2, w11, #8
    and w11, w2, #0xFF
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1453
    strb w11, [x10, w9, uxtw]
L1454:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1455
L1456:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1451:
    bl Lrd_slow
    b L1452
L1453:
    mov w0, w11
    bl Lwr_slow
    b L1454
L1455:
    mov w9, w24
    bl Lrd_slow
    b L1456
    .p2align 4
Lfcb_DF:
    orr w2, w26, #8
    and w26, w2, #0xFF
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1457
L1458:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1457:
    mov w9, w24
    bl Lrd_slow
    b L1458
    .p2align 4
Lfcb_E0:
    lsr w0, w28, #8
    orr w2, w0, #16
    bfi w28, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1459
L1460:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1459:
    mov w9, w24
    bl Lrd_slow
    b L1460
    .p2align 4
Lfcb_E1:
    and w0, w28, #0xFF
    orr w2, w0, #16
    bfi w28, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1461
L1462:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1461:
    mov w9, w24
    bl Lrd_slow
    b L1462
    .p2align 4
Lfcb_E2:
    lsr w0, w13, #8
    orr w2, w0, #16
    bfi w13, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1463
L1464:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1463:
    mov w9, w24
    bl Lrd_slow
    b L1464
    .p2align 4
Lfcb_E3:
    and w0, w13, #0xFF
    orr w2, w0, #16
    bfi w13, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1465
L1466:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1465:
    mov w9, w24
    bl Lrd_slow
    b L1466
    .p2align 4
Lfcb_E4:
    lsr w0, w14, #8
    orr w2, w0, #16
    bfi w14, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1467
L1468:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1467:
    mov w9, w24
    bl Lrd_slow
    b L1468
    .p2align 4
Lfcb_E5:
    and w0, w14, #0xFF
    orr w2, w0, #16
    bfi w14, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1469
L1470:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1469:
    mov w9, w24
    bl Lrd_slow
    b L1470
    .p2align 4
Lfcb_E6:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1471
L1472:
    ldrb w11, [x10, w9, uxtw]
    orr w2, w11, #16
    and w11, w2, #0xFF
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1473
    strb w11, [x10, w9, uxtw]
L1474:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1475
L1476:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1471:
    bl Lrd_slow
    b L1472
L1473:
    mov w0, w11
    bl Lwr_slow
    b L1474
L1475:
    mov w9, w24
    bl Lrd_slow
    b L1476
    .p2align 4
Lfcb_E7:
    orr w2, w26, #16
    and w26, w2, #0xFF
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1477
L1478:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1477:
    mov w9, w24
    bl Lrd_slow
    b L1478
    .p2align 4
Lfcb_E8:
    lsr w0, w28, #8
    orr w2, w0, #32
    bfi w28, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1479
L1480:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1479:
    mov w9, w24
    bl Lrd_slow
    b L1480
    .p2align 4
Lfcb_E9:
    and w0, w28, #0xFF
    orr w2, w0, #32
    bfi w28, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1481
L1482:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1481:
    mov w9, w24
    bl Lrd_slow
    b L1482
    .p2align 4
Lfcb_EA:
    lsr w0, w13, #8
    orr w2, w0, #32
    bfi w13, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1483
L1484:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1483:
    mov w9, w24
    bl Lrd_slow
    b L1484
    .p2align 4
Lfcb_EB:
    and w0, w13, #0xFF
    orr w2, w0, #32
    bfi w13, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1485
L1486:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1485:
    mov w9, w24
    bl Lrd_slow
    b L1486
    .p2align 4
Lfcb_EC:
    lsr w0, w14, #8
    orr w2, w0, #32
    bfi w14, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1487
L1488:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1487:
    mov w9, w24
    bl Lrd_slow
    b L1488
    .p2align 4
Lfcb_ED:
    and w0, w14, #0xFF
    orr w2, w0, #32
    bfi w14, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1489
L1490:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1489:
    mov w9, w24
    bl Lrd_slow
    b L1490
    .p2align 4
Lfcb_EE:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1491
L1492:
    ldrb w11, [x10, w9, uxtw]
    orr w2, w11, #32
    and w11, w2, #0xFF
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1493
    strb w11, [x10, w9, uxtw]
L1494:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1495
L1496:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1491:
    bl Lrd_slow
    b L1492
L1493:
    mov w0, w11
    bl Lwr_slow
    b L1494
L1495:
    mov w9, w24
    bl Lrd_slow
    b L1496
    .p2align 4
Lfcb_EF:
    orr w2, w26, #32
    and w26, w2, #0xFF
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1497
L1498:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1497:
    mov w9, w24
    bl Lrd_slow
    b L1498
    .p2align 4
Lfcb_F0:
    lsr w0, w28, #8
    orr w2, w0, #64
    bfi w28, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1499
L1500:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1499:
    mov w9, w24
    bl Lrd_slow
    b L1500
    .p2align 4
Lfcb_F1:
    and w0, w28, #0xFF
    orr w2, w0, #64
    bfi w28, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1501
L1502:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1501:
    mov w9, w24
    bl Lrd_slow
    b L1502
    .p2align 4
Lfcb_F2:
    lsr w0, w13, #8
    orr w2, w0, #64
    bfi w13, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1503
L1504:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1503:
    mov w9, w24
    bl Lrd_slow
    b L1504
    .p2align 4
Lfcb_F3:
    and w0, w13, #0xFF
    orr w2, w0, #64
    bfi w13, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1505
L1506:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1505:
    mov w9, w24
    bl Lrd_slow
    b L1506
    .p2align 4
Lfcb_F4:
    lsr w0, w14, #8
    orr w2, w0, #64
    bfi w14, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1507
L1508:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1507:
    mov w9, w24
    bl Lrd_slow
    b L1508
    .p2align 4
Lfcb_F5:
    and w0, w14, #0xFF
    orr w2, w0, #64
    bfi w14, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1509
L1510:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1509:
    mov w9, w24
    bl Lrd_slow
    b L1510
    .p2align 4
Lfcb_F6:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1511
L1512:
    ldrb w11, [x10, w9, uxtw]
    orr w2, w11, #64
    and w11, w2, #0xFF
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1513
    strb w11, [x10, w9, uxtw]
L1514:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1515
L1516:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1511:
    bl Lrd_slow
    b L1512
L1513:
    mov w0, w11
    bl Lwr_slow
    b L1514
L1515:
    mov w9, w24
    bl Lrd_slow
    b L1516
    .p2align 4
Lfcb_F7:
    orr w2, w26, #64
    and w26, w2, #0xFF
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1517
L1518:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1517:
    mov w9, w24
    bl Lrd_slow
    b L1518
    .p2align 4
Lfcb_F8:
    lsr w0, w28, #8
    orr w2, w0, #128
    bfi w28, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1519
L1520:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1519:
    mov w9, w24
    bl Lrd_slow
    b L1520
    .p2align 4
Lfcb_F9:
    and w0, w28, #0xFF
    orr w2, w0, #128
    bfi w28, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1521
L1522:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1521:
    mov w9, w24
    bl Lrd_slow
    b L1522
    .p2align 4
Lfcb_FA:
    lsr w0, w13, #8
    orr w2, w0, #128
    bfi w13, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1523
L1524:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1523:
    mov w9, w24
    bl Lrd_slow
    b L1524
    .p2align 4
Lfcb_FB:
    and w0, w13, #0xFF
    orr w2, w0, #128
    bfi w13, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1525
L1526:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1525:
    mov w9, w24
    bl Lrd_slow
    b L1526
    .p2align 4
Lfcb_FC:
    lsr w0, w14, #8
    orr w2, w0, #128
    bfi w14, w2, #8, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1527
L1528:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1527:
    mov w9, w24
    bl Lrd_slow
    b L1528
    .p2align 4
Lfcb_FD:
    and w0, w14, #0xFF
    orr w2, w0, #128
    bfi w14, w2, #0, #8
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1529
L1530:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1529:
    mov w9, w24
    bl Lrd_slow
    b L1530
    .p2align 4
Lfcb_FE:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1531
L1532:
    ldrb w11, [x10, w9, uxtw]
    orr w2, w11, #128
    and w11, w2, #0xFF
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1533
    strb w11, [x10, w9, uxtw]
L1534:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1535
L1536:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1531:
    bl Lrd_slow
    b L1532
L1533:
    mov w0, w11
    bl Lwr_slow
    b L1534
L1535:
    mov w9, w24
    bl Lrd_slow
    b L1536
    .p2align 4
Lfcb_FF:
    orr w2, w26, #128
    and w26, w2, #0xFF
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1537
L1538:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1537:
    mov w9, w24
    bl Lrd_slow
    b L1538
    .p2align 4
Lc_00:
    b Lnext
    .p2align 4
Lc_01:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1539
L1540:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1541
L1542:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1543
L1544:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1545
L1546:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w28, w12
    b Lnext
L1539:
    bl Ltick_slow4
    b L1540
L1541:
    bl Lrd_slow
    b L1542
L1543:
    bl Ltick_slow4
    b L1544
L1545:
    bl Lrd_slow
    b L1546
    .p2align 4
Lc_02:
    mov w9, w28
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1547
L1548:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1549
    strb w26, [x10, w9, uxtw]
L1550:
    b Lnext
L1547:
    bl Ltick_slow4
    b L1548
L1549:
    mov w0, w26
    bl Lwr_slow
    b L1550
    .p2align 4
Lc_03:
    add w28, w28, #1
    and w28, w28, #0xFFFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1551
L1552:
    b Lnext
L1551:
    bl Ltick_slow4
    b L1552
    .p2align 4
Lc_04:
    lsr w0, w28, #8
    add w1, w0, #1
    and w1, w1, #0xFF
    bfi w28, w1, #8, #8
    and w27, w27, #0x10
    cmp w1, #0
    cset w2, eq
    orr w27, w27, w2, lsl #7
    and w2, w1, #0xF
    cmp w2, #0
    cset w2, eq
    orr w27, w27, w2, lsl #5
    b Lnext
    .p2align 4
Lc_05:
    lsr w0, w28, #8
    sub w1, w0, #1
    and w1, w1, #0xFF
    bfi w28, w1, #8, #8
    and w27, w27, #0x10
    orr w27, w27, #0x40
    cmp w1, #0
    cset w2, eq
    orr w27, w27, w2, lsl #7
    and w2, w1, #0xF
    cmp w2, #15
    cset w2, eq
    orr w27, w27, w2, lsl #5
    b Lnext
    .p2align 4
Lc_06:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1553
L1554:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1555
L1556:
    ldrb w0, [x10, w9, uxtw]
    bfi w28, w0, #8, #8
    add w24, w24, #1
    and w24, w24, #0xFFFF
    b Lnext
L1553:
    bl Ltick_slow4
    b L1554
L1555:
    bl Lrd_slow
    b L1556
    .p2align 4
Lc_07:
    lsr w0, w26, #7
    lsl w26, w26, #1
    orr w26, w26, w0
    and w26, w26, #0xFF
    lsl w27, w0, #4
    b Lnext
    .p2align 4
Lc_08:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1557
L1558:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1559
L1560:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1561
L1562:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1563
L1564:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w9, w12
    and w11, w25, #0xFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1565
L1566:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1567
    strb w11, [x10, w9, uxtw]
L1568:
    add w9, w12, #1
    and w9, w9, #0xFFFF
    lsr w11, w25, #8
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1569
L1570:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1571
    strb w11, [x10, w9, uxtw]
L1572:
    b Lnext
L1557:
    bl Ltick_slow4
    b L1558
L1559:
    bl Lrd_slow
    b L1560
L1561:
    bl Ltick_slow4
    b L1562
L1563:
    bl Lrd_slow
    b L1564
L1565:
    bl Ltick_slow4
    b L1566
L1567:
    mov w0, w11
    bl Lwr_slow
    b L1568
L1569:
    bl Ltick_slow4
    b L1570
L1571:
    mov w0, w11
    bl Lwr_slow
    b L1572
    .p2align 4
Lc_09:
    add w0, w14, w28
    eor w1, w14, w28
    eor w1, w1, w0
    and w27, w27, #0x80
    ubfx w2, w1, #12, #1
    orr w27, w27, w2, lsl #5
    ubfx w2, w1, #16, #1
    orr w27, w27, w2, lsl #4
    and w14, w0, #0xFFFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1573
L1574:
    b Lnext
L1573:
    bl Ltick_slow4
    b L1574
    .p2align 4
Lc_0A:
    mov w9, w28
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1575
L1576:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1577
L1578:
    ldrb w26, [x10, w9, uxtw]
    b Lnext
L1575:
    bl Ltick_slow4
    b L1576
L1577:
    bl Lrd_slow
    b L1578
    .p2align 4
Lc_0B:
    sub w28, w28, #1
    and w28, w28, #0xFFFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1579
L1580:
    b Lnext
L1579:
    bl Ltick_slow4
    b L1580
    .p2align 4
Lc_0C:
    and w0, w28, #0xFF
    add w1, w0, #1
    and w1, w1, #0xFF
    bfi w28, w1, #0, #8
    and w27, w27, #0x10
    cmp w1, #0
    cset w2, eq
    orr w27, w27, w2, lsl #7
    and w2, w1, #0xF
    cmp w2, #0
    cset w2, eq
    orr w27, w27, w2, lsl #5
    b Lnext
    .p2align 4
Lc_0D:
    and w0, w28, #0xFF
    sub w1, w0, #1
    and w1, w1, #0xFF
    bfi w28, w1, #0, #8
    and w27, w27, #0x10
    orr w27, w27, #0x40
    cmp w1, #0
    cset w2, eq
    orr w27, w27, w2, lsl #7
    and w2, w1, #0xF
    cmp w2, #15
    cset w2, eq
    orr w27, w27, w2, lsl #5
    b Lnext
    .p2align 4
Lc_0E:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1581
L1582:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1583
L1584:
    ldrb w0, [x10, w9, uxtw]
    bfi w28, w0, #0, #8
    add w24, w24, #1
    and w24, w24, #0xFFFF
    b Lnext
L1581:
    bl Ltick_slow4
    b L1582
L1583:
    bl Lrd_slow
    b L1584
    .p2align 4
Lc_0F:
    and w0, w26, #1
    lsr w26, w26, #1
    orr w26, w26, w0, lsl #7
    lsl w27, w0, #4
    b Lnext
    .p2align 4
Lc_10:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1585
L1586:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1587
L1588:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    strb w26, [x19, #24]
    strb w27, [x19, #25]
    rev16 w17, w28
    strh w17, [x19, #26]
    rev16 w17, w13
    strh w17, [x19, #28]
    rev16 w17, w14
    strh w17, [x19, #30]
    strh w25, [x19, #32]
    strh w24, [x19, #34]
    ldrb w17, [x20, #371]
    cbnz w17, L1589
    str x21, [x19, #40]
    ldrh w17, [x20, #368]
    add w17, w17, w21
    add x16, x19, #16, lsl #12
    strh w17, [x16, #322]
L1589:
    mov x0, x19
    mov w1, #16
    bl SYM(gbc_asm_op)
    ldrb w26, [x19, #24]
    ldrb w27, [x19, #25]
    ldrh w17, [x19, #26]
    rev16 w28, w17
    ldrh w17, [x19, #28]
    rev16 w13, w17
    ldrh w17, [x19, #30]
    rev16 w14, w17
    ldrh w25, [x19, #32]
    ldrh w24, [x19, #34]
    ldr x21, [x19, #40]
    ldr x22, [x20, #320]
    ldr x15, [x20, #288]
    adr x16, Ljt_f
    b Lnext
L1585:
    bl Ltick_slow4
    b L1586
L1587:
    bl Lrd_slow
    b L1588
    .p2align 4
Lc_11:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1590
L1591:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1592
L1593:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1594
L1595:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1596
L1597:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w13, w12
    b Lnext
L1590:
    bl Ltick_slow4
    b L1591
L1592:
    bl Lrd_slow
    b L1593
L1594:
    bl Ltick_slow4
    b L1595
L1596:
    bl Lrd_slow
    b L1597
    .p2align 4
Lc_12:
    mov w9, w13
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1598
L1599:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1600
    strb w26, [x10, w9, uxtw]
L1601:
    b Lnext
L1598:
    bl Ltick_slow4
    b L1599
L1600:
    mov w0, w26
    bl Lwr_slow
    b L1601
    .p2align 4
Lc_13:
    add w13, w13, #1
    and w13, w13, #0xFFFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1602
L1603:
    b Lnext
L1602:
    bl Ltick_slow4
    b L1603
    .p2align 4
Lc_14:
    lsr w0, w13, #8
    add w1, w0, #1
    and w1, w1, #0xFF
    bfi w13, w1, #8, #8
    and w27, w27, #0x10
    cmp w1, #0
    cset w2, eq
    orr w27, w27, w2, lsl #7
    and w2, w1, #0xF
    cmp w2, #0
    cset w2, eq
    orr w27, w27, w2, lsl #5
    b Lnext
    .p2align 4
Lc_15:
    lsr w0, w13, #8
    sub w1, w0, #1
    and w1, w1, #0xFF
    bfi w13, w1, #8, #8
    and w27, w27, #0x10
    orr w27, w27, #0x40
    cmp w1, #0
    cset w2, eq
    orr w27, w27, w2, lsl #7
    and w2, w1, #0xF
    cmp w2, #15
    cset w2, eq
    orr w27, w27, w2, lsl #5
    b Lnext
    .p2align 4
Lc_16:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1604
L1605:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1606
L1607:
    ldrb w0, [x10, w9, uxtw]
    bfi w13, w0, #8, #8
    add w24, w24, #1
    and w24, w24, #0xFFFF
    b Lnext
L1604:
    bl Ltick_slow4
    b L1605
L1606:
    bl Lrd_slow
    b L1607
    .p2align 4
Lc_17:
    lsr w0, w26, #7
    ubfx w1, w27, #4, #1
    lsl w26, w26, #1
    orr w26, w26, w1
    and w26, w26, #0xFF
    lsl w27, w0, #4
    b Lnext
    .p2align 4
Lc_18:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1608
L1609:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1610
L1611:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    sxtb w0, w11
    add w24, w24, w0
    and w24, w24, #0xFFFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1613
L1614:
L1612:
    b Lnext
L1608:
    bl Ltick_slow4
    b L1609
L1610:
    bl Lrd_slow
    b L1611
L1613:
    bl Ltick_slow4
    b L1614
    .p2align 4
Lc_19:
    add w0, w14, w13
    eor w1, w14, w13
    eor w1, w1, w0
    and w27, w27, #0x80
    ubfx w2, w1, #12, #1
    orr w27, w27, w2, lsl #5
    ubfx w2, w1, #16, #1
    orr w27, w27, w2, lsl #4
    and w14, w0, #0xFFFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1615
L1616:
    b Lnext
L1615:
    bl Ltick_slow4
    b L1616
    .p2align 4
Lc_1A:
    mov w9, w13
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1617
L1618:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1619
L1620:
    ldrb w26, [x10, w9, uxtw]
    b Lnext
L1617:
    bl Ltick_slow4
    b L1618
L1619:
    bl Lrd_slow
    b L1620
    .p2align 4
Lc_1B:
    sub w13, w13, #1
    and w13, w13, #0xFFFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1621
L1622:
    b Lnext
L1621:
    bl Ltick_slow4
    b L1622
    .p2align 4
Lc_1C:
    and w0, w13, #0xFF
    add w1, w0, #1
    and w1, w1, #0xFF
    bfi w13, w1, #0, #8
    and w27, w27, #0x10
    cmp w1, #0
    cset w2, eq
    orr w27, w27, w2, lsl #7
    and w2, w1, #0xF
    cmp w2, #0
    cset w2, eq
    orr w27, w27, w2, lsl #5
    b Lnext
    .p2align 4
Lc_1D:
    and w0, w13, #0xFF
    sub w1, w0, #1
    and w1, w1, #0xFF
    bfi w13, w1, #0, #8
    and w27, w27, #0x10
    orr w27, w27, #0x40
    cmp w1, #0
    cset w2, eq
    orr w27, w27, w2, lsl #7
    and w2, w1, #0xF
    cmp w2, #15
    cset w2, eq
    orr w27, w27, w2, lsl #5
    b Lnext
    .p2align 4
Lc_1E:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1623
L1624:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1625
L1626:
    ldrb w0, [x10, w9, uxtw]
    bfi w13, w0, #0, #8
    add w24, w24, #1
    and w24, w24, #0xFFFF
    b Lnext
L1623:
    bl Ltick_slow4
    b L1624
L1625:
    bl Lrd_slow
    b L1626
    .p2align 4
Lc_1F:
    and w0, w26, #1
    ubfx w1, w27, #4, #1
    lsr w26, w26, #1
    orr w26, w26, w1, lsl #7
    lsl w27, w0, #4
    b Lnext
    .p2align 4
Lc_20:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1627
L1628:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1629
L1630:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    tbnz w27, #7, L1631
    sxtb w0, w11
    add w24, w24, w0
    and w24, w24, #0xFFFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1632
L1633:
L1631:
    b Lnext
L1627:
    bl Ltick_slow4
    b L1628
L1629:
    bl Lrd_slow
    b L1630
L1632:
    bl Ltick_slow4
    b L1633
    .p2align 4
Lc_21:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1634
L1635:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1636
L1637:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1638
L1639:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1640
L1641:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w14, w12
    b Lnext
L1634:
    bl Ltick_slow4
    b L1635
L1636:
    bl Lrd_slow
    b L1637
L1638:
    bl Ltick_slow4
    b L1639
L1640:
    bl Lrd_slow
    b L1641
    .p2align 4
Lc_22:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1642
L1643:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1644
    strb w26, [x10, w9, uxtw]
L1645:
    add w14, w9, #1
    and w14, w14, #0xFFFF
    b Lnext
L1642:
    bl Ltick_slow4
    b L1643
L1644:
    mov w0, w26
    bl Lwr_slow
    b L1645
    .p2align 4
Lc_23:
    add w14, w14, #1
    and w14, w14, #0xFFFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1646
L1647:
    b Lnext
L1646:
    bl Ltick_slow4
    b L1647
    .p2align 4
Lc_24:
    lsr w0, w14, #8
    add w1, w0, #1
    and w1, w1, #0xFF
    bfi w14, w1, #8, #8
    and w27, w27, #0x10
    cmp w1, #0
    cset w2, eq
    orr w27, w27, w2, lsl #7
    and w2, w1, #0xF
    cmp w2, #0
    cset w2, eq
    orr w27, w27, w2, lsl #5
    b Lnext
    .p2align 4
Lc_25:
    lsr w0, w14, #8
    sub w1, w0, #1
    and w1, w1, #0xFF
    bfi w14, w1, #8, #8
    and w27, w27, #0x10
    orr w27, w27, #0x40
    cmp w1, #0
    cset w2, eq
    orr w27, w27, w2, lsl #7
    and w2, w1, #0xF
    cmp w2, #15
    cset w2, eq
    orr w27, w27, w2, lsl #5
    b Lnext
    .p2align 4
Lc_26:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1648
L1649:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1650
L1651:
    ldrb w0, [x10, w9, uxtw]
    bfi w14, w0, #8, #8
    add w24, w24, #1
    and w24, w24, #0xFFFF
    b Lnext
L1648:
    bl Ltick_slow4
    b L1649
L1650:
    bl Lrd_slow
    b L1651
    .p2align 4
Lc_27:
    mov w0, w26
    ubfx w1, w27, #4, #1
    tbz w27, #6, L1652
    tbz w27, #5, L1653
    sub w0, w0, #6
L1653:
    cbz w1, L1657
    sub w0, w0, #0x60
    b L1657
L1652:
    cbnz w1, L1654
    cmp w0, #0x99
    b.ls L1655
L1654:
    add w0, w0, #0x60
    mov w1, #1
L1655:
    tbnz w27, #5, L1656
    and w2, w0, #0xF
    cmp w2, #9
    b.ls L1657
L1656:
    add w0, w0, #6
L1657:
    and w26, w0, #0xFF
    and w27, w27, #0x40
    orr w27, w27, w1, lsl #4
    cmp w26, #0
    cset w2, eq
    orr w27, w27, w2, lsl #7
    b Lnext
    .p2align 4
Lc_28:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1659
L1660:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1661
L1662:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    tbz w27, #7, L1663
    sxtb w0, w11
    add w24, w24, w0
    and w24, w24, #0xFFFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1664
L1665:
L1663:
    b Lnext
L1659:
    bl Ltick_slow4
    b L1660
L1661:
    bl Lrd_slow
    b L1662
L1664:
    bl Ltick_slow4
    b L1665
    .p2align 4
Lc_29:
    add w0, w14, w14
    eor w1, w14, w14
    eor w1, w1, w0
    and w27, w27, #0x80
    ubfx w2, w1, #12, #1
    orr w27, w27, w2, lsl #5
    ubfx w2, w1, #16, #1
    orr w27, w27, w2, lsl #4
    and w14, w0, #0xFFFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1666
L1667:
    b Lnext
L1666:
    bl Ltick_slow4
    b L1667
    .p2align 4
Lc_2A:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1668
L1669:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1670
L1671:
    ldrb w26, [x10, w9, uxtw]
    add w14, w9, #1
    and w14, w14, #0xFFFF
    b Lnext
L1668:
    bl Ltick_slow4
    b L1669
L1670:
    bl Lrd_slow
    b L1671
    .p2align 4
Lc_2B:
    sub w14, w14, #1
    and w14, w14, #0xFFFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1672
L1673:
    b Lnext
L1672:
    bl Ltick_slow4
    b L1673
    .p2align 4
Lc_2C:
    and w0, w14, #0xFF
    add w1, w0, #1
    and w1, w1, #0xFF
    bfi w14, w1, #0, #8
    and w27, w27, #0x10
    cmp w1, #0
    cset w2, eq
    orr w27, w27, w2, lsl #7
    and w2, w1, #0xF
    cmp w2, #0
    cset w2, eq
    orr w27, w27, w2, lsl #5
    b Lnext
    .p2align 4
Lc_2D:
    and w0, w14, #0xFF
    sub w1, w0, #1
    and w1, w1, #0xFF
    bfi w14, w1, #0, #8
    and w27, w27, #0x10
    orr w27, w27, #0x40
    cmp w1, #0
    cset w2, eq
    orr w27, w27, w2, lsl #7
    and w2, w1, #0xF
    cmp w2, #15
    cset w2, eq
    orr w27, w27, w2, lsl #5
    b Lnext
    .p2align 4
Lc_2E:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1674
L1675:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1676
L1677:
    ldrb w0, [x10, w9, uxtw]
    bfi w14, w0, #0, #8
    add w24, w24, #1
    and w24, w24, #0xFFFF
    b Lnext
L1674:
    bl Ltick_slow4
    b L1675
L1676:
    bl Lrd_slow
    b L1677
    .p2align 4
Lc_2F:
    eor w26, w26, #0xFF
    orr w27, w27, #0x60
    b Lnext
    .p2align 4
Lc_30:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1678
L1679:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1680
L1681:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    tbnz w27, #4, L1682
    sxtb w0, w11
    add w24, w24, w0
    and w24, w24, #0xFFFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1683
L1684:
L1682:
    b Lnext
L1678:
    bl Ltick_slow4
    b L1679
L1680:
    bl Lrd_slow
    b L1681
L1683:
    bl Ltick_slow4
    b L1684
    .p2align 4
Lc_31:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1685
L1686:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1687
L1688:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1689
L1690:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1691
L1692:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w25, w12
    b Lnext
L1685:
    bl Ltick_slow4
    b L1686
L1687:
    bl Lrd_slow
    b L1688
L1689:
    bl Ltick_slow4
    b L1690
L1691:
    bl Lrd_slow
    b L1692
    .p2align 4
Lc_32:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1693
L1694:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1695
    strb w26, [x10, w9, uxtw]
L1696:
    sub w14, w9, #1
    and w14, w14, #0xFFFF
    b Lnext
L1693:
    bl Ltick_slow4
    b L1694
L1695:
    mov w0, w26
    bl Lwr_slow
    b L1696
    .p2align 4
Lc_33:
    add w25, w25, #1
    and w25, w25, #0xFFFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1697
L1698:
    b Lnext
L1697:
    bl Ltick_slow4
    b L1698
    .p2align 4
Lc_34:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1699
L1700:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1701
L1702:
    ldrb w11, [x10, w9, uxtw]
    add w1, w11, #1
    and w1, w1, #0xFF
    and w11, w1, #0xFF
    and w27, w27, #0x10
    cmp w1, #0
    cset w2, eq
    orr w27, w27, w2, lsl #7
    and w2, w1, #0xF
    cmp w2, #0
    cset w2, eq
    orr w27, w27, w2, lsl #5
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1703
L1704:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1705
    strb w11, [x10, w9, uxtw]
L1706:
    b Lnext
L1699:
    bl Ltick_slow4
    b L1700
L1701:
    bl Lrd_slow
    b L1702
L1703:
    bl Ltick_slow4
    b L1704
L1705:
    mov w0, w11
    bl Lwr_slow
    b L1706
    .p2align 4
Lc_35:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1707
L1708:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1709
L1710:
    ldrb w11, [x10, w9, uxtw]
    sub w1, w11, #1
    and w1, w1, #0xFF
    and w11, w1, #0xFF
    and w27, w27, #0x10
    orr w27, w27, #0x40
    cmp w1, #0
    cset w2, eq
    orr w27, w27, w2, lsl #7
    and w2, w1, #0xF
    cmp w2, #15
    cset w2, eq
    orr w27, w27, w2, lsl #5
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1711
L1712:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1713
    strb w11, [x10, w9, uxtw]
L1714:
    b Lnext
L1707:
    bl Ltick_slow4
    b L1708
L1709:
    bl Lrd_slow
    b L1710
L1711:
    bl Ltick_slow4
    b L1712
L1713:
    mov w0, w11
    bl Lwr_slow
    b L1714
    .p2align 4
Lc_36:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1715
L1716:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1717
L1718:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1719
L1720:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1721
    strb w11, [x10, w9, uxtw]
L1722:
    b Lnext
L1715:
    bl Ltick_slow4
    b L1716
L1717:
    bl Lrd_slow
    b L1718
L1719:
    bl Ltick_slow4
    b L1720
L1721:
    mov w0, w11
    bl Lwr_slow
    b L1722
    .p2align 4
Lc_37:
    and w27, w27, #0x80
    orr w27, w27, #0x10
    b Lnext
    .p2align 4
Lc_38:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1723
L1724:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1725
L1726:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    tbz w27, #4, L1727
    sxtb w0, w11
    add w24, w24, w0
    and w24, w24, #0xFFFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1728
L1729:
L1727:
    b Lnext
L1723:
    bl Ltick_slow4
    b L1724
L1725:
    bl Lrd_slow
    b L1726
L1728:
    bl Ltick_slow4
    b L1729
    .p2align 4
Lc_39:
    add w0, w14, w25
    eor w1, w14, w25
    eor w1, w1, w0
    and w27, w27, #0x80
    ubfx w2, w1, #12, #1
    orr w27, w27, w2, lsl #5
    ubfx w2, w1, #16, #1
    orr w27, w27, w2, lsl #4
    and w14, w0, #0xFFFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1730
L1731:
    b Lnext
L1730:
    bl Ltick_slow4
    b L1731
    .p2align 4
Lc_3A:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1732
L1733:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1734
L1735:
    ldrb w26, [x10, w9, uxtw]
    sub w14, w9, #1
    and w14, w14, #0xFFFF
    b Lnext
L1732:
    bl Ltick_slow4
    b L1733
L1734:
    bl Lrd_slow
    b L1735
    .p2align 4
Lc_3B:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1736
L1737:
    b Lnext
L1736:
    bl Ltick_slow4
    b L1737
    .p2align 4
Lc_3C:
    add w1, w26, #1
    and w1, w1, #0xFF
    and w26, w1, #0xFF
    and w27, w27, #0x10
    cmp w1, #0
    cset w2, eq
    orr w27, w27, w2, lsl #7
    and w2, w1, #0xF
    cmp w2, #0
    cset w2, eq
    orr w27, w27, w2, lsl #5
    b Lnext
    .p2align 4
Lc_3D:
    sub w1, w26, #1
    and w1, w1, #0xFF
    and w26, w1, #0xFF
    and w27, w27, #0x10
    orr w27, w27, #0x40
    cmp w1, #0
    cset w2, eq
    orr w27, w27, w2, lsl #7
    and w2, w1, #0xF
    cmp w2, #15
    cset w2, eq
    orr w27, w27, w2, lsl #5
    b Lnext
    .p2align 4
Lc_3E:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1738
L1739:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1740
L1741:
    ldrb w26, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    b Lnext
L1738:
    bl Ltick_slow4
    b L1739
L1740:
    bl Lrd_slow
    b L1741
    .p2align 4
Lc_3F:
    mov w0, #0x90
    and w27, w27, w0
    eor w27, w27, #0x10
    b Lnext
    .p2align 4
Lc_40:
    b Lnext
    .p2align 4
Lc_41:
    and w0, w28, #0xFF
    bfi w28, w0, #8, #8
    b Lnext
    .p2align 4
Lc_42:
    lsr w0, w13, #8
    bfi w28, w0, #8, #8
    b Lnext
    .p2align 4
Lc_43:
    and w0, w13, #0xFF
    bfi w28, w0, #8, #8
    b Lnext
    .p2align 4
Lc_44:
    lsr w0, w14, #8
    bfi w28, w0, #8, #8
    b Lnext
    .p2align 4
Lc_45:
    and w0, w14, #0xFF
    bfi w28, w0, #8, #8
    b Lnext
    .p2align 4
Lc_46:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1742
L1743:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1744
L1745:
    ldrb w0, [x10, w9, uxtw]
    bfi w28, w0, #8, #8
    b Lnext
L1742:
    bl Ltick_slow4
    b L1743
L1744:
    bl Lrd_slow
    b L1745
    .p2align 4
Lc_47:
    bfi w28, w26, #8, #8
    b Lnext
    .p2align 4
Lc_48:
    lsr w0, w28, #8
    bfi w28, w0, #0, #8
    b Lnext
    .p2align 4
Lc_49:
    b Lnext
    .p2align 4
Lc_4A:
    lsr w0, w13, #8
    bfi w28, w0, #0, #8
    b Lnext
    .p2align 4
Lc_4B:
    and w0, w13, #0xFF
    bfi w28, w0, #0, #8
    b Lnext
    .p2align 4
Lc_4C:
    lsr w0, w14, #8
    bfi w28, w0, #0, #8
    b Lnext
    .p2align 4
Lc_4D:
    and w0, w14, #0xFF
    bfi w28, w0, #0, #8
    b Lnext
    .p2align 4
Lc_4E:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1746
L1747:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1748
L1749:
    ldrb w0, [x10, w9, uxtw]
    bfi w28, w0, #0, #8
    b Lnext
L1746:
    bl Ltick_slow4
    b L1747
L1748:
    bl Lrd_slow
    b L1749
    .p2align 4
Lc_4F:
    bfi w28, w26, #0, #8
    b Lnext
    .p2align 4
Lc_50:
    lsr w0, w28, #8
    bfi w13, w0, #8, #8
    b Lnext
    .p2align 4
Lc_51:
    and w0, w28, #0xFF
    bfi w13, w0, #8, #8
    b Lnext
    .p2align 4
Lc_52:
    b Lnext
    .p2align 4
Lc_53:
    and w0, w13, #0xFF
    bfi w13, w0, #8, #8
    b Lnext
    .p2align 4
Lc_54:
    lsr w0, w14, #8
    bfi w13, w0, #8, #8
    b Lnext
    .p2align 4
Lc_55:
    and w0, w14, #0xFF
    bfi w13, w0, #8, #8
    b Lnext
    .p2align 4
Lc_56:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1750
L1751:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1752
L1753:
    ldrb w0, [x10, w9, uxtw]
    bfi w13, w0, #8, #8
    b Lnext
L1750:
    bl Ltick_slow4
    b L1751
L1752:
    bl Lrd_slow
    b L1753
    .p2align 4
Lc_57:
    bfi w13, w26, #8, #8
    b Lnext
    .p2align 4
Lc_58:
    lsr w0, w28, #8
    bfi w13, w0, #0, #8
    b Lnext
    .p2align 4
Lc_59:
    and w0, w28, #0xFF
    bfi w13, w0, #0, #8
    b Lnext
    .p2align 4
Lc_5A:
    lsr w0, w13, #8
    bfi w13, w0, #0, #8
    b Lnext
    .p2align 4
Lc_5B:
    b Lnext
    .p2align 4
Lc_5C:
    lsr w0, w14, #8
    bfi w13, w0, #0, #8
    b Lnext
    .p2align 4
Lc_5D:
    and w0, w14, #0xFF
    bfi w13, w0, #0, #8
    b Lnext
    .p2align 4
Lc_5E:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1754
L1755:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1756
L1757:
    ldrb w0, [x10, w9, uxtw]
    bfi w13, w0, #0, #8
    b Lnext
L1754:
    bl Ltick_slow4
    b L1755
L1756:
    bl Lrd_slow
    b L1757
    .p2align 4
Lc_5F:
    bfi w13, w26, #0, #8
    b Lnext
    .p2align 4
Lc_60:
    lsr w0, w28, #8
    bfi w14, w0, #8, #8
    b Lnext
    .p2align 4
Lc_61:
    and w0, w28, #0xFF
    bfi w14, w0, #8, #8
    b Lnext
    .p2align 4
Lc_62:
    lsr w0, w13, #8
    bfi w14, w0, #8, #8
    b Lnext
    .p2align 4
Lc_63:
    and w0, w13, #0xFF
    bfi w14, w0, #8, #8
    b Lnext
    .p2align 4
Lc_64:
    b Lnext
    .p2align 4
Lc_65:
    and w0, w14, #0xFF
    bfi w14, w0, #8, #8
    b Lnext
    .p2align 4
Lc_66:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1758
L1759:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1760
L1761:
    ldrb w0, [x10, w9, uxtw]
    bfi w14, w0, #8, #8
    b Lnext
L1758:
    bl Ltick_slow4
    b L1759
L1760:
    bl Lrd_slow
    b L1761
    .p2align 4
Lc_67:
    bfi w14, w26, #8, #8
    b Lnext
    .p2align 4
Lc_68:
    lsr w0, w28, #8
    bfi w14, w0, #0, #8
    b Lnext
    .p2align 4
Lc_69:
    and w0, w28, #0xFF
    bfi w14, w0, #0, #8
    b Lnext
    .p2align 4
Lc_6A:
    lsr w0, w13, #8
    bfi w14, w0, #0, #8
    b Lnext
    .p2align 4
Lc_6B:
    and w0, w13, #0xFF
    bfi w14, w0, #0, #8
    b Lnext
    .p2align 4
Lc_6C:
    lsr w0, w14, #8
    bfi w14, w0, #0, #8
    b Lnext
    .p2align 4
Lc_6D:
    b Lnext
    .p2align 4
Lc_6E:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1762
L1763:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1764
L1765:
    ldrb w0, [x10, w9, uxtw]
    bfi w14, w0, #0, #8
    b Lnext
L1762:
    bl Ltick_slow4
    b L1763
L1764:
    bl Lrd_slow
    b L1765
    .p2align 4
Lc_6F:
    bfi w14, w26, #0, #8
    b Lnext
    .p2align 4
Lc_70:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1766
L1767:
    lsr w0, w28, #8
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1768
    strb w0, [x10, w9, uxtw]
L1769:
    b Lnext
L1766:
    bl Ltick_slow4
    b L1767
L1768:
    bl Lwr_slow
    b L1769
    .p2align 4
Lc_71:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1770
L1771:
    and w0, w28, #0xFF
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1772
    strb w0, [x10, w9, uxtw]
L1773:
    b Lnext
L1770:
    bl Ltick_slow4
    b L1771
L1772:
    bl Lwr_slow
    b L1773
    .p2align 4
Lc_72:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1774
L1775:
    lsr w0, w13, #8
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1776
    strb w0, [x10, w9, uxtw]
L1777:
    b Lnext
L1774:
    bl Ltick_slow4
    b L1775
L1776:
    bl Lwr_slow
    b L1777
    .p2align 4
Lc_73:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1778
L1779:
    and w0, w13, #0xFF
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1780
    strb w0, [x10, w9, uxtw]
L1781:
    b Lnext
L1778:
    bl Ltick_slow4
    b L1779
L1780:
    bl Lwr_slow
    b L1781
    .p2align 4
Lc_74:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1782
L1783:
    lsr w0, w14, #8
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1784
    strb w0, [x10, w9, uxtw]
L1785:
    b Lnext
L1782:
    bl Ltick_slow4
    b L1783
L1784:
    bl Lwr_slow
    b L1785
    .p2align 4
Lc_75:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1786
L1787:
    and w0, w14, #0xFF
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1788
    strb w0, [x10, w9, uxtw]
L1789:
    b Lnext
L1786:
    bl Ltick_slow4
    b L1787
L1788:
    bl Lwr_slow
    b L1789
    .p2align 4
Lc_76:
    strb w26, [x19, #24]
    strb w27, [x19, #25]
    rev16 w17, w28
    strh w17, [x19, #26]
    rev16 w17, w13
    strh w17, [x19, #28]
    rev16 w17, w14
    strh w17, [x19, #30]
    strh w25, [x19, #32]
    strh w24, [x19, #34]
    ldrb w17, [x20, #371]
    cbnz w17, L1790
    str x21, [x19, #40]
    ldrh w17, [x20, #368]
    add w17, w17, w21
    add x16, x19, #16, lsl #12
    strh w17, [x16, #322]
L1790:
    mov x0, x19
    mov w1, #118
    bl SYM(gbc_asm_op)
    ldrb w26, [x19, #24]
    ldrb w27, [x19, #25]
    ldrh w17, [x19, #26]
    rev16 w28, w17
    ldrh w17, [x19, #28]
    rev16 w13, w17
    ldrh w17, [x19, #30]
    rev16 w14, w17
    ldrh w25, [x19, #32]
    ldrh w24, [x19, #34]
    ldr x21, [x19, #40]
    ldr x22, [x20, #320]
    ldr x15, [x20, #288]
    adr x16, Ljt_f
    b Lnext
    .p2align 4
Lc_77:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1791
L1792:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1793
    strb w26, [x10, w9, uxtw]
L1794:
    b Lnext
L1791:
    bl Ltick_slow4
    b L1792
L1793:
    mov w0, w26
    bl Lwr_slow
    b L1794
    .p2align 4
Lc_78:
    lsr w26, w28, #8
    b Lnext
    .p2align 4
Lc_79:
    and w26, w28, #0xFF
    b Lnext
    .p2align 4
Lc_7A:
    lsr w26, w13, #8
    b Lnext
    .p2align 4
Lc_7B:
    and w26, w13, #0xFF
    b Lnext
    .p2align 4
Lc_7C:
    lsr w26, w14, #8
    b Lnext
    .p2align 4
Lc_7D:
    and w26, w14, #0xFF
    b Lnext
    .p2align 4
Lc_7E:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1795
L1796:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1797
L1798:
    ldrb w26, [x10, w9, uxtw]
    b Lnext
L1795:
    bl Ltick_slow4
    b L1796
L1797:
    bl Lrd_slow
    b L1798
    .p2align 4
Lc_7F:
    b Lnext
    .p2align 4
Lc_80:
    lsr w0, w28, #8
    add w1, w26, w0
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    b Lnext
    .p2align 4
Lc_81:
    and w0, w28, #0xFF
    add w1, w26, w0
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    b Lnext
    .p2align 4
Lc_82:
    lsr w0, w13, #8
    add w1, w26, w0
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    b Lnext
    .p2align 4
Lc_83:
    and w0, w13, #0xFF
    add w1, w26, w0
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    b Lnext
    .p2align 4
Lc_84:
    lsr w0, w14, #8
    add w1, w26, w0
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    b Lnext
    .p2align 4
Lc_85:
    and w0, w14, #0xFF
    add w1, w26, w0
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    b Lnext
    .p2align 4
Lc_86:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1799
L1800:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1801
L1802:
    ldrb w11, [x10, w9, uxtw]
    add w1, w26, w11
    eor w2, w26, w11
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    b Lnext
L1799:
    bl Ltick_slow4
    b L1800
L1801:
    bl Lrd_slow
    b L1802
    .p2align 4
Lc_87:
    add w1, w26, w26
    eor w2, w26, w26
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    b Lnext
    .p2align 4
Lc_88:
    lsr w0, w28, #8
    ubfx w2, w27, #4, #1
    add w1, w26, w0
    add w1, w1, w2
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    b Lnext
    .p2align 4
Lc_89:
    and w0, w28, #0xFF
    ubfx w2, w27, #4, #1
    add w1, w26, w0
    add w1, w1, w2
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    b Lnext
    .p2align 4
Lc_8A:
    lsr w0, w13, #8
    ubfx w2, w27, #4, #1
    add w1, w26, w0
    add w1, w1, w2
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    b Lnext
    .p2align 4
Lc_8B:
    and w0, w13, #0xFF
    ubfx w2, w27, #4, #1
    add w1, w26, w0
    add w1, w1, w2
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    b Lnext
    .p2align 4
Lc_8C:
    lsr w0, w14, #8
    ubfx w2, w27, #4, #1
    add w1, w26, w0
    add w1, w1, w2
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    b Lnext
    .p2align 4
Lc_8D:
    and w0, w14, #0xFF
    ubfx w2, w27, #4, #1
    add w1, w26, w0
    add w1, w1, w2
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    b Lnext
    .p2align 4
Lc_8E:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1803
L1804:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1805
L1806:
    ldrb w11, [x10, w9, uxtw]
    ubfx w2, w27, #4, #1
    add w1, w26, w11
    add w1, w1, w2
    eor w2, w26, w11
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    b Lnext
L1803:
    bl Ltick_slow4
    b L1804
L1805:
    bl Lrd_slow
    b L1806
    .p2align 4
Lc_8F:
    ubfx w2, w27, #4, #1
    add w1, w26, w26
    add w1, w1, w2
    eor w2, w26, w26
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    b Lnext
    .p2align 4
Lc_90:
    lsr w0, w28, #8
    sub w1, w26, w0
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    b Lnext
    .p2align 4
Lc_91:
    and w0, w28, #0xFF
    sub w1, w26, w0
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    b Lnext
    .p2align 4
Lc_92:
    lsr w0, w13, #8
    sub w1, w26, w0
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    b Lnext
    .p2align 4
Lc_93:
    and w0, w13, #0xFF
    sub w1, w26, w0
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    b Lnext
    .p2align 4
Lc_94:
    lsr w0, w14, #8
    sub w1, w26, w0
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    b Lnext
    .p2align 4
Lc_95:
    and w0, w14, #0xFF
    sub w1, w26, w0
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    b Lnext
    .p2align 4
Lc_96:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1807
L1808:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1809
L1810:
    ldrb w11, [x10, w9, uxtw]
    sub w1, w26, w11
    eor w2, w26, w11
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    b Lnext
L1807:
    bl Ltick_slow4
    b L1808
L1809:
    bl Lrd_slow
    b L1810
    .p2align 4
Lc_97:
    sub w1, w26, w26
    eor w2, w26, w26
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    b Lnext
    .p2align 4
Lc_98:
    lsr w0, w28, #8
    ubfx w2, w27, #4, #1
    sub w1, w26, w0
    sub w1, w1, w2
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    b Lnext
    .p2align 4
Lc_99:
    and w0, w28, #0xFF
    ubfx w2, w27, #4, #1
    sub w1, w26, w0
    sub w1, w1, w2
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    b Lnext
    .p2align 4
Lc_9A:
    lsr w0, w13, #8
    ubfx w2, w27, #4, #1
    sub w1, w26, w0
    sub w1, w1, w2
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    b Lnext
    .p2align 4
Lc_9B:
    and w0, w13, #0xFF
    ubfx w2, w27, #4, #1
    sub w1, w26, w0
    sub w1, w1, w2
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    b Lnext
    .p2align 4
Lc_9C:
    lsr w0, w14, #8
    ubfx w2, w27, #4, #1
    sub w1, w26, w0
    sub w1, w1, w2
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    b Lnext
    .p2align 4
Lc_9D:
    and w0, w14, #0xFF
    ubfx w2, w27, #4, #1
    sub w1, w26, w0
    sub w1, w1, w2
    eor w2, w26, w0
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    b Lnext
    .p2align 4
Lc_9E:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1811
L1812:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1813
L1814:
    ldrb w11, [x10, w9, uxtw]
    ubfx w2, w27, #4, #1
    sub w1, w26, w11
    sub w1, w1, w2
    eor w2, w26, w11
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    b Lnext
L1811:
    bl Ltick_slow4
    b L1812
L1813:
    bl Lrd_slow
    b L1814
    .p2align 4
Lc_9F:
    ubfx w2, w27, #4, #1
    sub w1, w26, w26
    sub w1, w1, w2
    eor w2, w26, w26
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    b Lnext
    .p2align 4
Lc_A0:
    lsr w0, w28, #8
    and w26, w26, w0
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    orr w27, w27, #0x20
    b Lnext
    .p2align 4
Lc_A1:
    and w0, w28, #0xFF
    and w26, w26, w0
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    orr w27, w27, #0x20
    b Lnext
    .p2align 4
Lc_A2:
    lsr w0, w13, #8
    and w26, w26, w0
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    orr w27, w27, #0x20
    b Lnext
    .p2align 4
Lc_A3:
    and w0, w13, #0xFF
    and w26, w26, w0
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    orr w27, w27, #0x20
    b Lnext
    .p2align 4
Lc_A4:
    lsr w0, w14, #8
    and w26, w26, w0
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    orr w27, w27, #0x20
    b Lnext
    .p2align 4
Lc_A5:
    and w0, w14, #0xFF
    and w26, w26, w0
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    orr w27, w27, #0x20
    b Lnext
    .p2align 4
Lc_A6:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1815
L1816:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1817
L1818:
    ldrb w11, [x10, w9, uxtw]
    and w26, w26, w11
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    orr w27, w27, #0x20
    b Lnext
L1815:
    bl Ltick_slow4
    b L1816
L1817:
    bl Lrd_slow
    b L1818
    .p2align 4
Lc_A7:
    and w26, w26, w26
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    orr w27, w27, #0x20
    b Lnext
    .p2align 4
Lc_A8:
    lsr w0, w28, #8
    eor w26, w26, w0
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    b Lnext
    .p2align 4
Lc_A9:
    and w0, w28, #0xFF
    eor w26, w26, w0
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    b Lnext
    .p2align 4
Lc_AA:
    lsr w0, w13, #8
    eor w26, w26, w0
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    b Lnext
    .p2align 4
Lc_AB:
    and w0, w13, #0xFF
    eor w26, w26, w0
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    b Lnext
    .p2align 4
Lc_AC:
    lsr w0, w14, #8
    eor w26, w26, w0
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    b Lnext
    .p2align 4
Lc_AD:
    and w0, w14, #0xFF
    eor w26, w26, w0
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    b Lnext
    .p2align 4
Lc_AE:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1819
L1820:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1821
L1822:
    ldrb w11, [x10, w9, uxtw]
    eor w26, w26, w11
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    b Lnext
L1819:
    bl Ltick_slow4
    b L1820
L1821:
    bl Lrd_slow
    b L1822
    .p2align 4
Lc_AF:
    eor w26, w26, w26
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    b Lnext
    .p2align 4
Lc_B0:
    lsr w0, w28, #8
    orr w26, w26, w0
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    b Lnext
    .p2align 4
Lc_B1:
    and w0, w28, #0xFF
    orr w26, w26, w0
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    b Lnext
    .p2align 4
Lc_B2:
    lsr w0, w13, #8
    orr w26, w26, w0
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    b Lnext
    .p2align 4
Lc_B3:
    and w0, w13, #0xFF
    orr w26, w26, w0
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    b Lnext
    .p2align 4
Lc_B4:
    lsr w0, w14, #8
    orr w26, w26, w0
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    b Lnext
    .p2align 4
Lc_B5:
    and w0, w14, #0xFF
    orr w26, w26, w0
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    b Lnext
    .p2align 4
Lc_B6:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1823
L1824:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1825
L1826:
    ldrb w11, [x10, w9, uxtw]
    orr w26, w26, w11
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    b Lnext
L1823:
    bl Ltick_slow4
    b L1824
L1825:
    bl Lrd_slow
    b L1826
    .p2align 4
Lc_B7:
    orr w26, w26, w26
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    b Lnext
    .p2align 4
Lc_B8:
    lsr w0, w28, #8
    sub w1, w26, w0
    eor w2, w26, w0
    eor w2, w2, w1
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    b Lnext
    .p2align 4
Lc_B9:
    and w0, w28, #0xFF
    sub w1, w26, w0
    eor w2, w26, w0
    eor w2, w2, w1
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    b Lnext
    .p2align 4
Lc_BA:
    lsr w0, w13, #8
    sub w1, w26, w0
    eor w2, w26, w0
    eor w2, w2, w1
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    b Lnext
    .p2align 4
Lc_BB:
    and w0, w13, #0xFF
    sub w1, w26, w0
    eor w2, w26, w0
    eor w2, w2, w1
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    b Lnext
    .p2align 4
Lc_BC:
    lsr w0, w14, #8
    sub w1, w26, w0
    eor w2, w26, w0
    eor w2, w2, w1
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    b Lnext
    .p2align 4
Lc_BD:
    and w0, w14, #0xFF
    sub w1, w26, w0
    eor w2, w26, w0
    eor w2, w2, w1
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    b Lnext
    .p2align 4
Lc_BE:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1827
L1828:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1829
L1830:
    ldrb w11, [x10, w9, uxtw]
    sub w1, w26, w11
    eor w2, w26, w11
    eor w2, w2, w1
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    b Lnext
L1827:
    bl Ltick_slow4
    b L1828
L1829:
    bl Lrd_slow
    b L1830
    .p2align 4
Lc_BF:
    sub w1, w26, w26
    eor w2, w26, w26
    eor w2, w2, w1
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    b Lnext
    .p2align 4
Lc_C0:
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1831
L1832:
    tbnz w27, #7, L1833
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1834
L1835:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1836
L1837:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1838
L1839:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1840
L1841:
    ldrb w12, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w24, w12
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1842
L1843:
L1833:
    b Lnext
L1831:
    bl Ltick_slow4
    b L1832
L1834:
    bl Ltick_slow4
    b L1835
L1836:
    bl Lrd_slow
    b L1837
L1838:
    bl Ltick_slow4
    b L1839
L1840:
    bl Lrd_slow
    b L1841
L1842:
    bl Ltick_slow4
    b L1843
    .p2align 4
Lc_C1:
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1844
L1845:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1846
L1847:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1848
L1849:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1850
L1851:
    ldrb w12, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w28, w12
    b Lnext
L1844:
    bl Ltick_slow4
    b L1845
L1846:
    bl Lrd_slow
    b L1847
L1848:
    bl Ltick_slow4
    b L1849
L1850:
    bl Lrd_slow
    b L1851
    .p2align 4
Lc_C2:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1852
L1853:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1854
L1855:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1856
L1857:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1858
L1859:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    tbnz w27, #7, L1860
    mov w24, w12
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1861
L1862:
L1860:
    b Lnext
L1852:
    bl Ltick_slow4
    b L1853
L1854:
    bl Lrd_slow
    b L1855
L1856:
    bl Ltick_slow4
    b L1857
L1858:
    bl Lrd_slow
    b L1859
L1861:
    bl Ltick_slow4
    b L1862
    .p2align 4
Lc_C3:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1863
L1864:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1865
L1866:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1867
L1868:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1869
L1870:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w24, w12
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1872
L1873:
L1871:
    b Lnext
L1863:
    bl Ltick_slow4
    b L1864
L1865:
    bl Lrd_slow
    b L1866
L1867:
    bl Ltick_slow4
    b L1868
L1869:
    bl Lrd_slow
    b L1870
L1872:
    bl Ltick_slow4
    b L1873
    .p2align 4
Lc_C4:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1874
L1875:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1876
L1877:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1878
L1879:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1880
L1881:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    tbnz w27, #7, L1882
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1883
L1884:
    str w12, [sp, #104]
    mov w12, w24
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1885
L1886:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1887
    strb w11, [x10, w9, uxtw]
L1888:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1889
L1890:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1891
    strb w12, [x10, w9, uxtw]
L1892:
    ldr w24, [sp, #104]
L1882:
    b Lnext
L1874:
    bl Ltick_slow4
    b L1875
L1876:
    bl Lrd_slow
    b L1877
L1878:
    bl Ltick_slow4
    b L1879
L1880:
    bl Lrd_slow
    b L1881
L1883:
    bl Ltick_slow4
    b L1884
L1885:
    bl Ltick_slow4
    b L1886
L1887:
    mov w0, w11
    bl Lwr_slow
    b L1888
L1889:
    bl Ltick_slow4
    b L1890
L1891:
    mov w0, w12
    bl Lwr_slow
    b L1892
    .p2align 4
Lc_C5:
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1893
L1894:
    mov w12, w28
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1895
L1896:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1897
    strb w11, [x10, w9, uxtw]
L1898:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1899
L1900:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1901
    strb w12, [x10, w9, uxtw]
L1902:
    b Lnext
L1893:
    bl Ltick_slow4
    b L1894
L1895:
    bl Ltick_slow4
    b L1896
L1897:
    mov w0, w11
    bl Lwr_slow
    b L1898
L1899:
    bl Ltick_slow4
    b L1900
L1901:
    mov w0, w12
    bl Lwr_slow
    b L1902
    .p2align 4
Lc_C6:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1903
L1904:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1905
L1906:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    add w1, w26, w11
    eor w2, w26, w11
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    b Lnext
L1903:
    bl Ltick_slow4
    b L1904
L1905:
    bl Lrd_slow
    b L1906
    .p2align 4
Lc_C7:
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1907
L1908:
    mov w12, w24
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1909
L1910:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1911
    strb w11, [x10, w9, uxtw]
L1912:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1913
L1914:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1915
    strb w12, [x10, w9, uxtw]
L1916:
    mov w24, #0
    b Lnext
L1907:
    bl Ltick_slow4
    b L1908
L1909:
    bl Ltick_slow4
    b L1910
L1911:
    mov w0, w11
    bl Lwr_slow
    b L1912
L1913:
    bl Ltick_slow4
    b L1914
L1915:
    mov w0, w12
    bl Lwr_slow
    b L1916
    .p2align 4
Lc_C8:
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1917
L1918:
    tbz w27, #7, L1919
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1920
L1921:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1922
L1923:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1924
L1925:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1926
L1927:
    ldrb w12, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w24, w12
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1928
L1929:
L1919:
    b Lnext
L1917:
    bl Ltick_slow4
    b L1918
L1920:
    bl Ltick_slow4
    b L1921
L1922:
    bl Lrd_slow
    b L1923
L1924:
    bl Ltick_slow4
    b L1925
L1926:
    bl Lrd_slow
    b L1927
L1928:
    bl Ltick_slow4
    b L1929
    .p2align 4
Lc_C9:
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1930
L1931:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1932
L1933:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1934
L1935:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1936
L1937:
    ldrb w12, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w24, w12
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1938
L1939:
    b Lnext
L1930:
    bl Ltick_slow4
    b L1931
L1932:
    bl Lrd_slow
    b L1933
L1934:
    bl Ltick_slow4
    b L1935
L1936:
    bl Lrd_slow
    b L1937
L1938:
    bl Ltick_slow4
    b L1939
    .p2align 4
Lc_CA:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1940
L1941:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1942
L1943:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1944
L1945:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1946
L1947:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    tbz w27, #7, L1948
    mov w24, w12
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1949
L1950:
L1948:
    b Lnext
L1940:
    bl Ltick_slow4
    b L1941
L1942:
    bl Lrd_slow
    b L1943
L1944:
    bl Ltick_slow4
    b L1945
L1946:
    bl Lrd_slow
    b L1947
L1949:
    bl Ltick_slow4
    b L1950
    .p2align 4
Lc_CB:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1951
L1952:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1953
L1954:
    ldrb w9, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    adr x17, Ljt_ccb
    ldrsw x0, [x17, x9, lsl #2]
    add x17, x17, x0
    br x17
L1951:
    bl Ltick_slow4
    b L1952
L1953:
    bl Lrd_slow
    b L1954
    .p2align 4
Lc_CC:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1955
L1956:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1957
L1958:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1959
L1960:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1961
L1962:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    tbz w27, #7, L1963
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1964
L1965:
    str w12, [sp, #104]
    mov w12, w24
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1966
L1967:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1968
    strb w11, [x10, w9, uxtw]
L1969:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1970
L1971:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1972
    strb w12, [x10, w9, uxtw]
L1973:
    ldr w24, [sp, #104]
L1963:
    b Lnext
L1955:
    bl Ltick_slow4
    b L1956
L1957:
    bl Lrd_slow
    b L1958
L1959:
    bl Ltick_slow4
    b L1960
L1961:
    bl Lrd_slow
    b L1962
L1964:
    bl Ltick_slow4
    b L1965
L1966:
    bl Ltick_slow4
    b L1967
L1968:
    mov w0, w11
    bl Lwr_slow
    b L1969
L1970:
    bl Ltick_slow4
    b L1971
L1972:
    mov w0, w12
    bl Lwr_slow
    b L1973
    .p2align 4
Lc_CD:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1974
L1975:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1976
L1977:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1978
L1979:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1980
L1981:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1983
L1984:
    str w12, [sp, #104]
    mov w12, w24
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1985
L1986:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1987
    strb w11, [x10, w9, uxtw]
L1988:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1989
L1990:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1991
    strb w12, [x10, w9, uxtw]
L1992:
    ldr w24, [sp, #104]
L1982:
    b Lnext
L1974:
    bl Ltick_slow4
    b L1975
L1976:
    bl Lrd_slow
    b L1977
L1978:
    bl Ltick_slow4
    b L1979
L1980:
    bl Lrd_slow
    b L1981
L1983:
    bl Ltick_slow4
    b L1984
L1985:
    bl Ltick_slow4
    b L1986
L1987:
    mov w0, w11
    bl Lwr_slow
    b L1988
L1989:
    bl Ltick_slow4
    b L1990
L1991:
    mov w0, w12
    bl Lwr_slow
    b L1992
    .p2align 4
Lc_CE:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1993
L1994:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1995
L1996:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ubfx w2, w27, #4, #1
    add w1, w26, w11
    add w1, w1, w2
    eor w2, w26, w11
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    b Lnext
L1993:
    bl Ltick_slow4
    b L1994
L1995:
    bl Lrd_slow
    b L1996
    .p2align 4
Lc_CF:
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1997
L1998:
    mov w12, w24
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1999
L2000:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2001
    strb w11, [x10, w9, uxtw]
L2002:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2003
L2004:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2005
    strb w12, [x10, w9, uxtw]
L2006:
    mov w24, #8
    b Lnext
L1997:
    bl Ltick_slow4
    b L1998
L1999:
    bl Ltick_slow4
    b L2000
L2001:
    mov w0, w11
    bl Lwr_slow
    b L2002
L2003:
    bl Ltick_slow4
    b L2004
L2005:
    mov w0, w12
    bl Lwr_slow
    b L2006
    .p2align 4
Lc_D0:
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2007
L2008:
    tbnz w27, #4, L2009
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2010
L2011:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2012
L2013:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2014
L2015:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2016
L2017:
    ldrb w12, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w24, w12
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2018
L2019:
L2009:
    b Lnext
L2007:
    bl Ltick_slow4
    b L2008
L2010:
    bl Ltick_slow4
    b L2011
L2012:
    bl Lrd_slow
    b L2013
L2014:
    bl Ltick_slow4
    b L2015
L2016:
    bl Lrd_slow
    b L2017
L2018:
    bl Ltick_slow4
    b L2019
    .p2align 4
Lc_D1:
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2020
L2021:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2022
L2023:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2024
L2025:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2026
L2027:
    ldrb w12, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w13, w12
    b Lnext
L2020:
    bl Ltick_slow4
    b L2021
L2022:
    bl Lrd_slow
    b L2023
L2024:
    bl Ltick_slow4
    b L2025
L2026:
    bl Lrd_slow
    b L2027
    .p2align 4
Lc_D2:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2028
L2029:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2030
L2031:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2032
L2033:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2034
L2035:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    tbnz w27, #4, L2036
    mov w24, w12
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2037
L2038:
L2036:
    b Lnext
L2028:
    bl Ltick_slow4
    b L2029
L2030:
    bl Lrd_slow
    b L2031
L2032:
    bl Ltick_slow4
    b L2033
L2034:
    bl Lrd_slow
    b L2035
L2037:
    bl Ltick_slow4
    b L2038
    .p2align 4
Lc_D3:
    b Lnext
    .p2align 4
Lc_D4:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2039
L2040:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2041
L2042:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2043
L2044:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2045
L2046:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    tbnz w27, #4, L2047
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2048
L2049:
    str w12, [sp, #104]
    mov w12, w24
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2050
L2051:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2052
    strb w11, [x10, w9, uxtw]
L2053:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2054
L2055:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2056
    strb w12, [x10, w9, uxtw]
L2057:
    ldr w24, [sp, #104]
L2047:
    b Lnext
L2039:
    bl Ltick_slow4
    b L2040
L2041:
    bl Lrd_slow
    b L2042
L2043:
    bl Ltick_slow4
    b L2044
L2045:
    bl Lrd_slow
    b L2046
L2048:
    bl Ltick_slow4
    b L2049
L2050:
    bl Ltick_slow4
    b L2051
L2052:
    mov w0, w11
    bl Lwr_slow
    b L2053
L2054:
    bl Ltick_slow4
    b L2055
L2056:
    mov w0, w12
    bl Lwr_slow
    b L2057
    .p2align 4
Lc_D5:
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2058
L2059:
    mov w12, w13
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2060
L2061:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2062
    strb w11, [x10, w9, uxtw]
L2063:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2064
L2065:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2066
    strb w12, [x10, w9, uxtw]
L2067:
    b Lnext
L2058:
    bl Ltick_slow4
    b L2059
L2060:
    bl Ltick_slow4
    b L2061
L2062:
    mov w0, w11
    bl Lwr_slow
    b L2063
L2064:
    bl Ltick_slow4
    b L2065
L2066:
    mov w0, w12
    bl Lwr_slow
    b L2067
    .p2align 4
Lc_D6:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2068
L2069:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2070
L2071:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    sub w1, w26, w11
    eor w2, w26, w11
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    b Lnext
L2068:
    bl Ltick_slow4
    b L2069
L2070:
    bl Lrd_slow
    b L2071
    .p2align 4
Lc_D7:
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2072
L2073:
    mov w12, w24
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2074
L2075:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2076
    strb w11, [x10, w9, uxtw]
L2077:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2078
L2079:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2080
    strb w12, [x10, w9, uxtw]
L2081:
    mov w24, #16
    b Lnext
L2072:
    bl Ltick_slow4
    b L2073
L2074:
    bl Ltick_slow4
    b L2075
L2076:
    mov w0, w11
    bl Lwr_slow
    b L2077
L2078:
    bl Ltick_slow4
    b L2079
L2080:
    mov w0, w12
    bl Lwr_slow
    b L2081
    .p2align 4
Lc_D8:
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2082
L2083:
    tbz w27, #4, L2084
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2085
L2086:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2087
L2088:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2089
L2090:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2091
L2092:
    ldrb w12, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w24, w12
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2093
L2094:
L2084:
    b Lnext
L2082:
    bl Ltick_slow4
    b L2083
L2085:
    bl Ltick_slow4
    b L2086
L2087:
    bl Lrd_slow
    b L2088
L2089:
    bl Ltick_slow4
    b L2090
L2091:
    bl Lrd_slow
    b L2092
L2093:
    bl Ltick_slow4
    b L2094
    .p2align 4
Lc_D9:
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2095
L2096:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2097
L2098:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2099
L2100:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2101
L2102:
    ldrb w12, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w24, w12
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2103
L2104:
    strb w26, [x19, #24]
    strb w27, [x19, #25]
    rev16 w17, w28
    strh w17, [x19, #26]
    rev16 w17, w13
    strh w17, [x19, #28]
    rev16 w17, w14
    strh w17, [x19, #30]
    strh w25, [x19, #32]
    strh w24, [x19, #34]
    ldrb w17, [x20, #371]
    cbnz w17, L2105
    str x21, [x19, #40]
    ldrh w17, [x20, #368]
    add w17, w17, w21
    add x16, x19, #16, lsl #12
    strh w17, [x16, #322]
L2105:
    mov x0, x19
    mov w1, #217
    bl SYM(gbc_asm_op)
    ldrb w26, [x19, #24]
    ldrb w27, [x19, #25]
    ldrh w17, [x19, #26]
    rev16 w28, w17
    ldrh w17, [x19, #28]
    rev16 w13, w17
    ldrh w17, [x19, #30]
    rev16 w14, w17
    ldrh w25, [x19, #32]
    ldrh w24, [x19, #34]
    ldr x21, [x19, #40]
    ldr x22, [x20, #320]
    ldr x15, [x20, #288]
    adr x16, Ljt_f
    b Lnext
L2095:
    bl Ltick_slow4
    b L2096
L2097:
    bl Lrd_slow
    b L2098
L2099:
    bl Ltick_slow4
    b L2100
L2101:
    bl Lrd_slow
    b L2102
L2103:
    bl Ltick_slow4
    b L2104
    .p2align 4
Lc_DA:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2106
L2107:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2108
L2109:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2110
L2111:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2112
L2113:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    tbz w27, #4, L2114
    mov w24, w12
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2115
L2116:
L2114:
    b Lnext
L2106:
    bl Ltick_slow4
    b L2107
L2108:
    bl Lrd_slow
    b L2109
L2110:
    bl Ltick_slow4
    b L2111
L2112:
    bl Lrd_slow
    b L2113
L2115:
    bl Ltick_slow4
    b L2116
    .p2align 4
Lc_DB:
    b Lnext
    .p2align 4
Lc_DC:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2117
L2118:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2119
L2120:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2121
L2122:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2123
L2124:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    tbz w27, #4, L2125
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2126
L2127:
    str w12, [sp, #104]
    mov w12, w24
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2128
L2129:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2130
    strb w11, [x10, w9, uxtw]
L2131:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2132
L2133:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2134
    strb w12, [x10, w9, uxtw]
L2135:
    ldr w24, [sp, #104]
L2125:
    b Lnext
L2117:
    bl Ltick_slow4
    b L2118
L2119:
    bl Lrd_slow
    b L2120
L2121:
    bl Ltick_slow4
    b L2122
L2123:
    bl Lrd_slow
    b L2124
L2126:
    bl Ltick_slow4
    b L2127
L2128:
    bl Ltick_slow4
    b L2129
L2130:
    mov w0, w11
    bl Lwr_slow
    b L2131
L2132:
    bl Ltick_slow4
    b L2133
L2134:
    mov w0, w12
    bl Lwr_slow
    b L2135
    .p2align 4
Lc_DD:
    b Lnext
    .p2align 4
Lc_DE:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2136
L2137:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2138
L2139:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ubfx w2, w27, #4, #1
    sub w1, w26, w11
    sub w1, w1, w2
    eor w2, w26, w11
    eor w2, w2, w1
    and w26, w1, #0xFF
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    b Lnext
L2136:
    bl Ltick_slow4
    b L2137
L2138:
    bl Lrd_slow
    b L2139
    .p2align 4
Lc_DF:
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2140
L2141:
    mov w12, w24
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2142
L2143:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2144
    strb w11, [x10, w9, uxtw]
L2145:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2146
L2147:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2148
    strb w12, [x10, w9, uxtw]
L2149:
    mov w24, #24
    b Lnext
L2140:
    bl Ltick_slow4
    b L2141
L2142:
    bl Ltick_slow4
    b L2143
L2144:
    mov w0, w11
    bl Lwr_slow
    b L2145
L2146:
    bl Ltick_slow4
    b L2147
L2148:
    mov w0, w12
    bl Lwr_slow
    b L2149
    .p2align 4
Lc_E0:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2152
L2153:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2154
L2155:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    cmp w11, #0x80
    b.lo L2150
    cmp w11, #0xFF
    b.eq L2150
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2156
L2157:
    ldr x10, [x20, #272]
    orr w0, w11, #0xFF00
    strb w26, [x10, w0, uxtw]
    b L2151
L2150:
    mov w9, w11
    orr w9, w9, #0xFF00
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2158
L2159:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2160
    strb w26, [x10, w9, uxtw]
L2161:
L2151:
    b Lnext
L2152:
    bl Ltick_slow4
    b L2153
L2154:
    bl Lrd_slow
    b L2155
L2156:
    bl Ltick_slow4
    b L2157
L2158:
    bl Ltick_slow4
    b L2159
L2160:
    mov w0, w26
    bl Lwr_slow
    b L2161
    .p2align 4
Lc_E1:
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2162
L2163:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2164
L2165:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2166
L2167:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2168
L2169:
    ldrb w12, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w14, w12
    b Lnext
L2162:
    bl Ltick_slow4
    b L2163
L2164:
    bl Lrd_slow
    b L2165
L2166:
    bl Ltick_slow4
    b L2167
L2168:
    bl Lrd_slow
    b L2169
    .p2align 4
Lc_E2:
    and w9, w28, #0xFF
    orr w9, w9, #0xFF00
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2170
L2171:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2172
    strb w26, [x10, w9, uxtw]
L2173:
    b Lnext
L2170:
    bl Ltick_slow4
    b L2171
L2172:
    mov w0, w26
    bl Lwr_slow
    b L2173
    .p2align 4
Lc_E3:
    b Lnext
    .p2align 4
Lc_E4:
    b Lnext
    .p2align 4
Lc_E5:
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2174
L2175:
    mov w12, w14
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2176
L2177:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2178
    strb w11, [x10, w9, uxtw]
L2179:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2180
L2181:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2182
    strb w12, [x10, w9, uxtw]
L2183:
    b Lnext
L2174:
    bl Ltick_slow4
    b L2175
L2176:
    bl Ltick_slow4
    b L2177
L2178:
    mov w0, w11
    bl Lwr_slow
    b L2179
L2180:
    bl Ltick_slow4
    b L2181
L2182:
    mov w0, w12
    bl Lwr_slow
    b L2183
    .p2align 4
Lc_E6:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2184
L2185:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2186
L2187:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    and w26, w26, w11
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    orr w27, w27, #0x20
    b Lnext
L2184:
    bl Ltick_slow4
    b L2185
L2186:
    bl Lrd_slow
    b L2187
    .p2align 4
Lc_E7:
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2188
L2189:
    mov w12, w24
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2190
L2191:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2192
    strb w11, [x10, w9, uxtw]
L2193:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2194
L2195:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2196
    strb w12, [x10, w9, uxtw]
L2197:
    mov w24, #32
    b Lnext
L2188:
    bl Ltick_slow4
    b L2189
L2190:
    bl Ltick_slow4
    b L2191
L2192:
    mov w0, w11
    bl Lwr_slow
    b L2193
L2194:
    bl Ltick_slow4
    b L2195
L2196:
    mov w0, w12
    bl Lwr_slow
    b L2197
    .p2align 4
Lc_E8:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2198
L2199:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2200
L2201:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    and w0, w25, #0xFF
    add w0, w0, w11
    and w1, w25, #0xF
    and w2, w11, #0xF
    add w1, w1, w2
    ubfx w0, w0, #8, #1
    ubfx w1, w1, #4, #1
    lsl w27, w0, #4
    orr w27, w27, w1, lsl #5
    sxtb w2, w11
    add w2, w25, w2
    and w25, w2, #0xFFFF
    add x21, x21, #8
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2202
L2203:
    b Lnext
L2198:
    bl Ltick_slow4
    b L2199
L2200:
    bl Lrd_slow
    b L2201
L2202:
    bl Ltick_slow8
    b L2203
    .p2align 4
Lc_E9:
    mov w24, w14
    b Lnext
    .p2align 4
Lc_EA:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2204
L2205:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2206
L2207:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2208
L2209:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2210
L2211:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w9, w12
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2212
L2213:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2214
    strb w26, [x10, w9, uxtw]
L2215:
    b Lnext
L2204:
    bl Ltick_slow4
    b L2205
L2206:
    bl Lrd_slow
    b L2207
L2208:
    bl Ltick_slow4
    b L2209
L2210:
    bl Lrd_slow
    b L2211
L2212:
    bl Ltick_slow4
    b L2213
L2214:
    mov w0, w26
    bl Lwr_slow
    b L2215
    .p2align 4
Lc_EB:
    b Lnext
    .p2align 4
Lc_EC:
    b Lnext
    .p2align 4
Lc_ED:
    b Lnext
    .p2align 4
Lc_EE:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2216
L2217:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2218
L2219:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    eor w26, w26, w11
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    b Lnext
L2216:
    bl Ltick_slow4
    b L2217
L2218:
    bl Lrd_slow
    b L2219
    .p2align 4
Lc_EF:
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2220
L2221:
    mov w12, w24
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2222
L2223:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2224
    strb w11, [x10, w9, uxtw]
L2225:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2226
L2227:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2228
    strb w12, [x10, w9, uxtw]
L2229:
    mov w24, #40
    b Lnext
L2220:
    bl Ltick_slow4
    b L2221
L2222:
    bl Ltick_slow4
    b L2223
L2224:
    mov w0, w11
    bl Lwr_slow
    b L2225
L2226:
    bl Ltick_slow4
    b L2227
L2228:
    mov w0, w12
    bl Lwr_slow
    b L2229
    .p2align 4
Lc_F0:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2232
L2233:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2234
L2235:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    cmp w11, #0x80
    b.lo L2230
    cmp w11, #0xFF
    b.eq L2230
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2236
L2237:
    ldr x10, [x20, #272]
    orr w0, w11, #0xFF00
    ldrb w26, [x10, w0, uxtw]
    b L2231
L2230:
    mov w9, w11
    orr w9, w9, #0xFF00
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2238
L2239:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2240
L2241:
    ldrb w26, [x10, w9, uxtw]
L2231:
    b Lnext
L2232:
    bl Ltick_slow4
    b L2233
L2234:
    bl Lrd_slow
    b L2235
L2236:
    bl Ltick_slow4
    b L2237
L2238:
    bl Ltick_slow4
    b L2239
L2240:
    bl Lrd_slow
    b L2241
    .p2align 4
Lc_F1:
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2242
L2243:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2244
L2245:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2246
L2247:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2248
L2249:
    ldrb w12, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    orr w12, w11, w12, lsl #8
    lsr w26, w12, #8
    and w27, w12, #0xF0
    b Lnext
L2242:
    bl Ltick_slow4
    b L2243
L2244:
    bl Lrd_slow
    b L2245
L2246:
    bl Ltick_slow4
    b L2247
L2248:
    bl Lrd_slow
    b L2249
    .p2align 4
Lc_F2:
    and w9, w28, #0xFF
    orr w9, w9, #0xFF00
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2250
L2251:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2252
L2253:
    ldrb w26, [x10, w9, uxtw]
    b Lnext
L2250:
    bl Ltick_slow4
    b L2251
L2252:
    bl Lrd_slow
    b L2253
    .p2align 4
Lc_F3:
    strb w26, [x19, #24]
    strb w27, [x19, #25]
    rev16 w17, w28
    strh w17, [x19, #26]
    rev16 w17, w13
    strh w17, [x19, #28]
    rev16 w17, w14
    strh w17, [x19, #30]
    strh w25, [x19, #32]
    strh w24, [x19, #34]
    ldrb w17, [x20, #371]
    cbnz w17, L2254
    str x21, [x19, #40]
    ldrh w17, [x20, #368]
    add w17, w17, w21
    add x16, x19, #16, lsl #12
    strh w17, [x16, #322]
L2254:
    mov x0, x19
    mov w1, #243
    bl SYM(gbc_asm_op)
    ldrb w26, [x19, #24]
    ldrb w27, [x19, #25]
    ldrh w17, [x19, #26]
    rev16 w28, w17
    ldrh w17, [x19, #28]
    rev16 w13, w17
    ldrh w17, [x19, #30]
    rev16 w14, w17
    ldrh w25, [x19, #32]
    ldrh w24, [x19, #34]
    ldr x21, [x19, #40]
    ldr x22, [x20, #320]
    ldr x15, [x20, #288]
    adr x16, Ljt_f
    b Lnext
    .p2align 4
Lc_F4:
    b Lnext
    .p2align 4
Lc_F5:
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2255
L2256:
    orr w12, w27, w26, lsl #8
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2257
L2258:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2259
    strb w11, [x10, w9, uxtw]
L2260:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2261
L2262:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2263
    strb w12, [x10, w9, uxtw]
L2264:
    b Lnext
L2255:
    bl Ltick_slow4
    b L2256
L2257:
    bl Ltick_slow4
    b L2258
L2259:
    mov w0, w11
    bl Lwr_slow
    b L2260
L2261:
    bl Ltick_slow4
    b L2262
L2263:
    mov w0, w12
    bl Lwr_slow
    b L2264
    .p2align 4
Lc_F6:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2265
L2266:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2267
L2268:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w26, w26, w11
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    b Lnext
L2265:
    bl Ltick_slow4
    b L2266
L2267:
    bl Lrd_slow
    b L2268
    .p2align 4
Lc_F7:
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2269
L2270:
    mov w12, w24
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2271
L2272:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2273
    strb w11, [x10, w9, uxtw]
L2274:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2275
L2276:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2277
    strb w12, [x10, w9, uxtw]
L2278:
    mov w24, #48
    b Lnext
L2269:
    bl Ltick_slow4
    b L2270
L2271:
    bl Ltick_slow4
    b L2272
L2273:
    mov w0, w11
    bl Lwr_slow
    b L2274
L2275:
    bl Ltick_slow4
    b L2276
L2277:
    mov w0, w12
    bl Lwr_slow
    b L2278
    .p2align 4
Lc_F8:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2279
L2280:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2281
L2282:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    and w0, w25, #0xFF
    add w0, w0, w11
    and w1, w25, #0xF
    and w2, w11, #0xF
    add w1, w1, w2
    ubfx w0, w0, #8, #1
    ubfx w1, w1, #4, #1
    lsl w27, w0, #4
    orr w27, w27, w1, lsl #5
    sxtb w2, w11
    add w2, w25, w2
    and w14, w2, #0xFFFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2283
L2284:
    b Lnext
L2279:
    bl Ltick_slow4
    b L2280
L2281:
    bl Lrd_slow
    b L2282
L2283:
    bl Ltick_slow4
    b L2284
    .p2align 4
Lc_F9:
    mov w25, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2285
L2286:
    b Lnext
L2285:
    bl Ltick_slow4
    b L2286
    .p2align 4
Lc_FA:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2287
L2288:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2289
L2290:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2291
L2292:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2293
L2294:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w9, w12
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2295
L2296:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2297
L2298:
    ldrb w26, [x10, w9, uxtw]
    b Lnext
L2287:
    bl Ltick_slow4
    b L2288
L2289:
    bl Lrd_slow
    b L2290
L2291:
    bl Ltick_slow4
    b L2292
L2293:
    bl Lrd_slow
    b L2294
L2295:
    bl Ltick_slow4
    b L2296
L2297:
    bl Lrd_slow
    b L2298
    .p2align 4
Lc_FB:
    strb w26, [x19, #24]
    strb w27, [x19, #25]
    rev16 w17, w28
    strh w17, [x19, #26]
    rev16 w17, w13
    strh w17, [x19, #28]
    rev16 w17, w14
    strh w17, [x19, #30]
    strh w25, [x19, #32]
    strh w24, [x19, #34]
    ldrb w17, [x20, #371]
    cbnz w17, L2299
    str x21, [x19, #40]
    ldrh w17, [x20, #368]
    add w17, w17, w21
    add x16, x19, #16, lsl #12
    strh w17, [x16, #322]
L2299:
    mov x0, x19
    mov w1, #251
    bl SYM(gbc_asm_op)
    ldrb w26, [x19, #24]
    ldrb w27, [x19, #25]
    ldrh w17, [x19, #26]
    rev16 w28, w17
    ldrh w17, [x19, #28]
    rev16 w13, w17
    ldrh w17, [x19, #30]
    rev16 w14, w17
    ldrh w25, [x19, #32]
    ldrh w24, [x19, #34]
    ldr x21, [x19, #40]
    ldr x22, [x20, #320]
    ldr x15, [x20, #288]
    adr x16, Ljt_f
    b Lnext
    .p2align 4
Lc_FC:
    b Lnext
    .p2align 4
Lc_FD:
    b Lnext
    .p2align 4
Lc_FE:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2300
L2301:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2302
L2303:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    sub w1, w26, w11
    eor w2, w26, w11
    eor w2, w2, w1
    and w3, w2, #0x10
    and w2, w2, #0x100
    lsl w3, w3, #1
    orr w27, w3, w2, lsr #4
    tst w1, #0xFF
    cset w3, eq
    orr w27, w27, w3, lsl #7
    orr w27, w27, #0x40
    b Lnext
L2300:
    bl Ltick_slow4
    b L2301
L2302:
    bl Lrd_slow
    b L2303
    .p2align 4
Lc_FF:
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2304
L2305:
    mov w12, w24
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2306
L2307:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2308
    strb w11, [x10, w9, uxtw]
L2309:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2310
L2311:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2312
    strb w12, [x10, w9, uxtw]
L2313:
    mov w24, #56
    b Lnext
L2304:
    bl Ltick_slow4
    b L2305
L2306:
    bl Ltick_slow4
    b L2307
L2308:
    mov w0, w11
    bl Lwr_slow
    b L2309
L2310:
    bl Ltick_slow4
    b L2311
L2312:
    mov w0, w12
    bl Lwr_slow
    b L2313
    .p2align 4
Lccb_00:
    lsr w0, w28, #8
    lsr w1, w0, #7
    lsl w2, w0, #1
    orr w2, w2, w1
    and w2, w2, #0xFF
    bfi w28, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_01:
    and w0, w28, #0xFF
    lsr w1, w0, #7
    lsl w2, w0, #1
    orr w2, w2, w1
    and w2, w2, #0xFF
    bfi w28, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_02:
    lsr w0, w13, #8
    lsr w1, w0, #7
    lsl w2, w0, #1
    orr w2, w2, w1
    and w2, w2, #0xFF
    bfi w13, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_03:
    and w0, w13, #0xFF
    lsr w1, w0, #7
    lsl w2, w0, #1
    orr w2, w2, w1
    and w2, w2, #0xFF
    bfi w13, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_04:
    lsr w0, w14, #8
    lsr w1, w0, #7
    lsl w2, w0, #1
    orr w2, w2, w1
    and w2, w2, #0xFF
    bfi w14, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_05:
    and w0, w14, #0xFF
    lsr w1, w0, #7
    lsl w2, w0, #1
    orr w2, w2, w1
    and w2, w2, #0xFF
    bfi w14, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_06:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2314
L2315:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2316
L2317:
    ldrb w11, [x10, w9, uxtw]
    lsr w1, w11, #7
    lsl w2, w11, #1
    orr w2, w2, w1
    and w2, w2, #0xFF
    and w11, w2, #0xFF
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2318
L2319:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2320
    strb w11, [x10, w9, uxtw]
L2321:
    b Lnext
L2314:
    bl Ltick_slow4
    b L2315
L2316:
    bl Lrd_slow
    b L2317
L2318:
    bl Ltick_slow4
    b L2319
L2320:
    mov w0, w11
    bl Lwr_slow
    b L2321
    .p2align 4
Lccb_07:
    lsr w1, w26, #7
    lsl w2, w26, #1
    orr w2, w2, w1
    and w2, w2, #0xFF
    and w26, w2, #0xFF
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_08:
    lsr w0, w28, #8
    and w1, w0, #1
    lsr w2, w0, #1
    orr w2, w2, w1, lsl #7
    bfi w28, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_09:
    and w0, w28, #0xFF
    and w1, w0, #1
    lsr w2, w0, #1
    orr w2, w2, w1, lsl #7
    bfi w28, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_0A:
    lsr w0, w13, #8
    and w1, w0, #1
    lsr w2, w0, #1
    orr w2, w2, w1, lsl #7
    bfi w13, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_0B:
    and w0, w13, #0xFF
    and w1, w0, #1
    lsr w2, w0, #1
    orr w2, w2, w1, lsl #7
    bfi w13, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_0C:
    lsr w0, w14, #8
    and w1, w0, #1
    lsr w2, w0, #1
    orr w2, w2, w1, lsl #7
    bfi w14, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_0D:
    and w0, w14, #0xFF
    and w1, w0, #1
    lsr w2, w0, #1
    orr w2, w2, w1, lsl #7
    bfi w14, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_0E:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2322
L2323:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2324
L2325:
    ldrb w11, [x10, w9, uxtw]
    and w1, w11, #1
    lsr w2, w11, #1
    orr w2, w2, w1, lsl #7
    and w11, w2, #0xFF
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2326
L2327:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2328
    strb w11, [x10, w9, uxtw]
L2329:
    b Lnext
L2322:
    bl Ltick_slow4
    b L2323
L2324:
    bl Lrd_slow
    b L2325
L2326:
    bl Ltick_slow4
    b L2327
L2328:
    mov w0, w11
    bl Lwr_slow
    b L2329
    .p2align 4
Lccb_0F:
    and w1, w26, #1
    lsr w2, w26, #1
    orr w2, w2, w1, lsl #7
    and w26, w2, #0xFF
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_10:
    lsr w0, w28, #8
    lsr w1, w0, #7
    ubfx w3, w27, #4, #1
    lsl w2, w0, #1
    orr w2, w2, w3
    and w2, w2, #0xFF
    bfi w28, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_11:
    and w0, w28, #0xFF
    lsr w1, w0, #7
    ubfx w3, w27, #4, #1
    lsl w2, w0, #1
    orr w2, w2, w3
    and w2, w2, #0xFF
    bfi w28, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_12:
    lsr w0, w13, #8
    lsr w1, w0, #7
    ubfx w3, w27, #4, #1
    lsl w2, w0, #1
    orr w2, w2, w3
    and w2, w2, #0xFF
    bfi w13, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_13:
    and w0, w13, #0xFF
    lsr w1, w0, #7
    ubfx w3, w27, #4, #1
    lsl w2, w0, #1
    orr w2, w2, w3
    and w2, w2, #0xFF
    bfi w13, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_14:
    lsr w0, w14, #8
    lsr w1, w0, #7
    ubfx w3, w27, #4, #1
    lsl w2, w0, #1
    orr w2, w2, w3
    and w2, w2, #0xFF
    bfi w14, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_15:
    and w0, w14, #0xFF
    lsr w1, w0, #7
    ubfx w3, w27, #4, #1
    lsl w2, w0, #1
    orr w2, w2, w3
    and w2, w2, #0xFF
    bfi w14, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_16:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2330
L2331:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2332
L2333:
    ldrb w11, [x10, w9, uxtw]
    lsr w1, w11, #7
    ubfx w3, w27, #4, #1
    lsl w2, w11, #1
    orr w2, w2, w3
    and w2, w2, #0xFF
    and w11, w2, #0xFF
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2334
L2335:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2336
    strb w11, [x10, w9, uxtw]
L2337:
    b Lnext
L2330:
    bl Ltick_slow4
    b L2331
L2332:
    bl Lrd_slow
    b L2333
L2334:
    bl Ltick_slow4
    b L2335
L2336:
    mov w0, w11
    bl Lwr_slow
    b L2337
    .p2align 4
Lccb_17:
    lsr w1, w26, #7
    ubfx w3, w27, #4, #1
    lsl w2, w26, #1
    orr w2, w2, w3
    and w2, w2, #0xFF
    and w26, w2, #0xFF
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_18:
    lsr w0, w28, #8
    and w1, w0, #1
    ubfx w3, w27, #4, #1
    lsr w2, w0, #1
    orr w2, w2, w3, lsl #7
    bfi w28, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_19:
    and w0, w28, #0xFF
    and w1, w0, #1
    ubfx w3, w27, #4, #1
    lsr w2, w0, #1
    orr w2, w2, w3, lsl #7
    bfi w28, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_1A:
    lsr w0, w13, #8
    and w1, w0, #1
    ubfx w3, w27, #4, #1
    lsr w2, w0, #1
    orr w2, w2, w3, lsl #7
    bfi w13, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_1B:
    and w0, w13, #0xFF
    and w1, w0, #1
    ubfx w3, w27, #4, #1
    lsr w2, w0, #1
    orr w2, w2, w3, lsl #7
    bfi w13, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_1C:
    lsr w0, w14, #8
    and w1, w0, #1
    ubfx w3, w27, #4, #1
    lsr w2, w0, #1
    orr w2, w2, w3, lsl #7
    bfi w14, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_1D:
    and w0, w14, #0xFF
    and w1, w0, #1
    ubfx w3, w27, #4, #1
    lsr w2, w0, #1
    orr w2, w2, w3, lsl #7
    bfi w14, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_1E:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2338
L2339:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2340
L2341:
    ldrb w11, [x10, w9, uxtw]
    and w1, w11, #1
    ubfx w3, w27, #4, #1
    lsr w2, w11, #1
    orr w2, w2, w3, lsl #7
    and w11, w2, #0xFF
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2342
L2343:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2344
    strb w11, [x10, w9, uxtw]
L2345:
    b Lnext
L2338:
    bl Ltick_slow4
    b L2339
L2340:
    bl Lrd_slow
    b L2341
L2342:
    bl Ltick_slow4
    b L2343
L2344:
    mov w0, w11
    bl Lwr_slow
    b L2345
    .p2align 4
Lccb_1F:
    and w1, w26, #1
    ubfx w3, w27, #4, #1
    lsr w2, w26, #1
    orr w2, w2, w3, lsl #7
    and w26, w2, #0xFF
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_20:
    lsr w0, w28, #8
    lsr w1, w0, #7
    lsl w2, w0, #1
    and w2, w2, #0xFF
    bfi w28, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_21:
    and w0, w28, #0xFF
    lsr w1, w0, #7
    lsl w2, w0, #1
    and w2, w2, #0xFF
    bfi w28, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_22:
    lsr w0, w13, #8
    lsr w1, w0, #7
    lsl w2, w0, #1
    and w2, w2, #0xFF
    bfi w13, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_23:
    and w0, w13, #0xFF
    lsr w1, w0, #7
    lsl w2, w0, #1
    and w2, w2, #0xFF
    bfi w13, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_24:
    lsr w0, w14, #8
    lsr w1, w0, #7
    lsl w2, w0, #1
    and w2, w2, #0xFF
    bfi w14, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_25:
    and w0, w14, #0xFF
    lsr w1, w0, #7
    lsl w2, w0, #1
    and w2, w2, #0xFF
    bfi w14, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_26:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2346
L2347:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2348
L2349:
    ldrb w11, [x10, w9, uxtw]
    lsr w1, w11, #7
    lsl w2, w11, #1
    and w2, w2, #0xFF
    and w11, w2, #0xFF
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2350
L2351:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2352
    strb w11, [x10, w9, uxtw]
L2353:
    b Lnext
L2346:
    bl Ltick_slow4
    b L2347
L2348:
    bl Lrd_slow
    b L2349
L2350:
    bl Ltick_slow4
    b L2351
L2352:
    mov w0, w11
    bl Lwr_slow
    b L2353
    .p2align 4
Lccb_27:
    lsr w1, w26, #7
    lsl w2, w26, #1
    and w2, w2, #0xFF
    and w26, w2, #0xFF
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_28:
    lsr w0, w28, #8
    and w1, w0, #1
    and w3, w0, #0x80
    lsr w2, w0, #1
    orr w2, w2, w3
    bfi w28, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_29:
    and w0, w28, #0xFF
    and w1, w0, #1
    and w3, w0, #0x80
    lsr w2, w0, #1
    orr w2, w2, w3
    bfi w28, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_2A:
    lsr w0, w13, #8
    and w1, w0, #1
    and w3, w0, #0x80
    lsr w2, w0, #1
    orr w2, w2, w3
    bfi w13, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_2B:
    and w0, w13, #0xFF
    and w1, w0, #1
    and w3, w0, #0x80
    lsr w2, w0, #1
    orr w2, w2, w3
    bfi w13, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_2C:
    lsr w0, w14, #8
    and w1, w0, #1
    and w3, w0, #0x80
    lsr w2, w0, #1
    orr w2, w2, w3
    bfi w14, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_2D:
    and w0, w14, #0xFF
    and w1, w0, #1
    and w3, w0, #0x80
    lsr w2, w0, #1
    orr w2, w2, w3
    bfi w14, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_2E:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2354
L2355:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2356
L2357:
    ldrb w11, [x10, w9, uxtw]
    and w1, w11, #1
    and w3, w11, #0x80
    lsr w2, w11, #1
    orr w2, w2, w3
    and w11, w2, #0xFF
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2358
L2359:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2360
    strb w11, [x10, w9, uxtw]
L2361:
    b Lnext
L2354:
    bl Ltick_slow4
    b L2355
L2356:
    bl Lrd_slow
    b L2357
L2358:
    bl Ltick_slow4
    b L2359
L2360:
    mov w0, w11
    bl Lwr_slow
    b L2361
    .p2align 4
Lccb_2F:
    and w1, w26, #1
    and w3, w26, #0x80
    lsr w2, w26, #1
    orr w2, w2, w3
    and w26, w2, #0xFF
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_30:
    lsr w0, w28, #8
    mov w1, #0
    lsl w2, w0, #4
    orr w2, w2, w0, lsr #4
    and w2, w2, #0xFF
    bfi w28, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_31:
    and w0, w28, #0xFF
    mov w1, #0
    lsl w2, w0, #4
    orr w2, w2, w0, lsr #4
    and w2, w2, #0xFF
    bfi w28, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_32:
    lsr w0, w13, #8
    mov w1, #0
    lsl w2, w0, #4
    orr w2, w2, w0, lsr #4
    and w2, w2, #0xFF
    bfi w13, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_33:
    and w0, w13, #0xFF
    mov w1, #0
    lsl w2, w0, #4
    orr w2, w2, w0, lsr #4
    and w2, w2, #0xFF
    bfi w13, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_34:
    lsr w0, w14, #8
    mov w1, #0
    lsl w2, w0, #4
    orr w2, w2, w0, lsr #4
    and w2, w2, #0xFF
    bfi w14, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_35:
    and w0, w14, #0xFF
    mov w1, #0
    lsl w2, w0, #4
    orr w2, w2, w0, lsr #4
    and w2, w2, #0xFF
    bfi w14, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_36:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2362
L2363:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2364
L2365:
    ldrb w11, [x10, w9, uxtw]
    mov w1, #0
    lsl w2, w11, #4
    orr w2, w2, w11, lsr #4
    and w2, w2, #0xFF
    and w11, w2, #0xFF
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2366
L2367:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2368
    strb w11, [x10, w9, uxtw]
L2369:
    b Lnext
L2362:
    bl Ltick_slow4
    b L2363
L2364:
    bl Lrd_slow
    b L2365
L2366:
    bl Ltick_slow4
    b L2367
L2368:
    mov w0, w11
    bl Lwr_slow
    b L2369
    .p2align 4
Lccb_37:
    mov w1, #0
    lsl w2, w26, #4
    orr w2, w2, w26, lsr #4
    and w2, w2, #0xFF
    and w26, w2, #0xFF
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_38:
    lsr w0, w28, #8
    and w1, w0, #1
    lsr w2, w0, #1
    bfi w28, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_39:
    and w0, w28, #0xFF
    and w1, w0, #1
    lsr w2, w0, #1
    bfi w28, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_3A:
    lsr w0, w13, #8
    and w1, w0, #1
    lsr w2, w0, #1
    bfi w13, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_3B:
    and w0, w13, #0xFF
    and w1, w0, #1
    lsr w2, w0, #1
    bfi w13, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_3C:
    lsr w0, w14, #8
    and w1, w0, #1
    lsr w2, w0, #1
    bfi w14, w2, #8, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_3D:
    and w0, w14, #0xFF
    and w1, w0, #1
    lsr w2, w0, #1
    bfi w14, w2, #0, #8
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_3E:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2370
L2371:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2372
L2373:
    ldrb w11, [x10, w9, uxtw]
    and w1, w11, #1
    lsr w2, w11, #1
    and w11, w2, #0xFF
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2374
L2375:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2376
    strb w11, [x10, w9, uxtw]
L2377:
    b Lnext
L2370:
    bl Ltick_slow4
    b L2371
L2372:
    bl Lrd_slow
    b L2373
L2374:
    bl Ltick_slow4
    b L2375
L2376:
    mov w0, w11
    bl Lwr_slow
    b L2377
    .p2align 4
Lccb_3F:
    and w1, w26, #1
    lsr w2, w26, #1
    and w26, w2, #0xFF
    cmp w2, #0
    cset w3, eq
    lsl w27, w3, #7
    orr w27, w27, w1, lsl #4
    b Lnext
    .p2align 4
Lccb_40:
    lsr w0, w28, #8
    tst w0, #1
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_41:
    and w0, w28, #0xFF
    tst w0, #1
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_42:
    lsr w0, w13, #8
    tst w0, #1
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_43:
    and w0, w13, #0xFF
    tst w0, #1
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_44:
    lsr w0, w14, #8
    tst w0, #1
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_45:
    and w0, w14, #0xFF
    tst w0, #1
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_46:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2378
L2379:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2380
L2381:
    ldrb w11, [x10, w9, uxtw]
    tst w11, #1
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
L2378:
    bl Ltick_slow4
    b L2379
L2380:
    bl Lrd_slow
    b L2381
    .p2align 4
Lccb_47:
    tst w26, #1
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_48:
    lsr w0, w28, #8
    tst w0, #2
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_49:
    and w0, w28, #0xFF
    tst w0, #2
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_4A:
    lsr w0, w13, #8
    tst w0, #2
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_4B:
    and w0, w13, #0xFF
    tst w0, #2
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_4C:
    lsr w0, w14, #8
    tst w0, #2
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_4D:
    and w0, w14, #0xFF
    tst w0, #2
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_4E:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2382
L2383:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2384
L2385:
    ldrb w11, [x10, w9, uxtw]
    tst w11, #2
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
L2382:
    bl Ltick_slow4
    b L2383
L2384:
    bl Lrd_slow
    b L2385
    .p2align 4
Lccb_4F:
    tst w26, #2
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_50:
    lsr w0, w28, #8
    tst w0, #4
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_51:
    and w0, w28, #0xFF
    tst w0, #4
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_52:
    lsr w0, w13, #8
    tst w0, #4
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_53:
    and w0, w13, #0xFF
    tst w0, #4
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_54:
    lsr w0, w14, #8
    tst w0, #4
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_55:
    and w0, w14, #0xFF
    tst w0, #4
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_56:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2386
L2387:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2388
L2389:
    ldrb w11, [x10, w9, uxtw]
    tst w11, #4
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
L2386:
    bl Ltick_slow4
    b L2387
L2388:
    bl Lrd_slow
    b L2389
    .p2align 4
Lccb_57:
    tst w26, #4
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_58:
    lsr w0, w28, #8
    tst w0, #8
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_59:
    and w0, w28, #0xFF
    tst w0, #8
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_5A:
    lsr w0, w13, #8
    tst w0, #8
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_5B:
    and w0, w13, #0xFF
    tst w0, #8
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_5C:
    lsr w0, w14, #8
    tst w0, #8
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_5D:
    and w0, w14, #0xFF
    tst w0, #8
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_5E:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2390
L2391:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2392
L2393:
    ldrb w11, [x10, w9, uxtw]
    tst w11, #8
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
L2390:
    bl Ltick_slow4
    b L2391
L2392:
    bl Lrd_slow
    b L2393
    .p2align 4
Lccb_5F:
    tst w26, #8
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_60:
    lsr w0, w28, #8
    tst w0, #16
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_61:
    and w0, w28, #0xFF
    tst w0, #16
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_62:
    lsr w0, w13, #8
    tst w0, #16
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_63:
    and w0, w13, #0xFF
    tst w0, #16
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_64:
    lsr w0, w14, #8
    tst w0, #16
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_65:
    and w0, w14, #0xFF
    tst w0, #16
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_66:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2394
L2395:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2396
L2397:
    ldrb w11, [x10, w9, uxtw]
    tst w11, #16
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
L2394:
    bl Ltick_slow4
    b L2395
L2396:
    bl Lrd_slow
    b L2397
    .p2align 4
Lccb_67:
    tst w26, #16
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_68:
    lsr w0, w28, #8
    tst w0, #32
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_69:
    and w0, w28, #0xFF
    tst w0, #32
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_6A:
    lsr w0, w13, #8
    tst w0, #32
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_6B:
    and w0, w13, #0xFF
    tst w0, #32
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_6C:
    lsr w0, w14, #8
    tst w0, #32
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_6D:
    and w0, w14, #0xFF
    tst w0, #32
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_6E:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2398
L2399:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2400
L2401:
    ldrb w11, [x10, w9, uxtw]
    tst w11, #32
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
L2398:
    bl Ltick_slow4
    b L2399
L2400:
    bl Lrd_slow
    b L2401
    .p2align 4
Lccb_6F:
    tst w26, #32
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_70:
    lsr w0, w28, #8
    tst w0, #64
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_71:
    and w0, w28, #0xFF
    tst w0, #64
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_72:
    lsr w0, w13, #8
    tst w0, #64
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_73:
    and w0, w13, #0xFF
    tst w0, #64
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_74:
    lsr w0, w14, #8
    tst w0, #64
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_75:
    and w0, w14, #0xFF
    tst w0, #64
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_76:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2402
L2403:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2404
L2405:
    ldrb w11, [x10, w9, uxtw]
    tst w11, #64
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
L2402:
    bl Ltick_slow4
    b L2403
L2404:
    bl Lrd_slow
    b L2405
    .p2align 4
Lccb_77:
    tst w26, #64
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_78:
    lsr w0, w28, #8
    tst w0, #128
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_79:
    and w0, w28, #0xFF
    tst w0, #128
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_7A:
    lsr w0, w13, #8
    tst w0, #128
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_7B:
    and w0, w13, #0xFF
    tst w0, #128
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_7C:
    lsr w0, w14, #8
    tst w0, #128
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_7D:
    and w0, w14, #0xFF
    tst w0, #128
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_7E:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2406
L2407:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2408
L2409:
    ldrb w11, [x10, w9, uxtw]
    tst w11, #128
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
L2406:
    bl Ltick_slow4
    b L2407
L2408:
    bl Lrd_slow
    b L2409
    .p2align 4
Lccb_7F:
    tst w26, #128
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
    .p2align 4
Lccb_80:
    lsr w0, w28, #8
    and w2, w0, #0xFFFFFFFE
    bfi w28, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_81:
    and w0, w28, #0xFF
    and w2, w0, #0xFFFFFFFE
    bfi w28, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_82:
    lsr w0, w13, #8
    and w2, w0, #0xFFFFFFFE
    bfi w13, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_83:
    and w0, w13, #0xFF
    and w2, w0, #0xFFFFFFFE
    bfi w13, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_84:
    lsr w0, w14, #8
    and w2, w0, #0xFFFFFFFE
    bfi w14, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_85:
    and w0, w14, #0xFF
    and w2, w0, #0xFFFFFFFE
    bfi w14, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_86:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2410
L2411:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2412
L2413:
    ldrb w11, [x10, w9, uxtw]
    and w2, w11, #0xFFFFFFFE
    and w11, w2, #0xFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2414
L2415:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2416
    strb w11, [x10, w9, uxtw]
L2417:
    b Lnext
L2410:
    bl Ltick_slow4
    b L2411
L2412:
    bl Lrd_slow
    b L2413
L2414:
    bl Ltick_slow4
    b L2415
L2416:
    mov w0, w11
    bl Lwr_slow
    b L2417
    .p2align 4
Lccb_87:
    and w2, w26, #0xFFFFFFFE
    and w26, w2, #0xFF
    b Lnext
    .p2align 4
Lccb_88:
    lsr w0, w28, #8
    and w2, w0, #0xFFFFFFFD
    bfi w28, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_89:
    and w0, w28, #0xFF
    and w2, w0, #0xFFFFFFFD
    bfi w28, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_8A:
    lsr w0, w13, #8
    and w2, w0, #0xFFFFFFFD
    bfi w13, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_8B:
    and w0, w13, #0xFF
    and w2, w0, #0xFFFFFFFD
    bfi w13, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_8C:
    lsr w0, w14, #8
    and w2, w0, #0xFFFFFFFD
    bfi w14, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_8D:
    and w0, w14, #0xFF
    and w2, w0, #0xFFFFFFFD
    bfi w14, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_8E:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2418
L2419:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2420
L2421:
    ldrb w11, [x10, w9, uxtw]
    and w2, w11, #0xFFFFFFFD
    and w11, w2, #0xFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2422
L2423:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2424
    strb w11, [x10, w9, uxtw]
L2425:
    b Lnext
L2418:
    bl Ltick_slow4
    b L2419
L2420:
    bl Lrd_slow
    b L2421
L2422:
    bl Ltick_slow4
    b L2423
L2424:
    mov w0, w11
    bl Lwr_slow
    b L2425
    .p2align 4
Lccb_8F:
    and w2, w26, #0xFFFFFFFD
    and w26, w2, #0xFF
    b Lnext
    .p2align 4
Lccb_90:
    lsr w0, w28, #8
    and w2, w0, #0xFFFFFFFB
    bfi w28, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_91:
    and w0, w28, #0xFF
    and w2, w0, #0xFFFFFFFB
    bfi w28, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_92:
    lsr w0, w13, #8
    and w2, w0, #0xFFFFFFFB
    bfi w13, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_93:
    and w0, w13, #0xFF
    and w2, w0, #0xFFFFFFFB
    bfi w13, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_94:
    lsr w0, w14, #8
    and w2, w0, #0xFFFFFFFB
    bfi w14, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_95:
    and w0, w14, #0xFF
    and w2, w0, #0xFFFFFFFB
    bfi w14, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_96:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2426
L2427:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2428
L2429:
    ldrb w11, [x10, w9, uxtw]
    and w2, w11, #0xFFFFFFFB
    and w11, w2, #0xFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2430
L2431:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2432
    strb w11, [x10, w9, uxtw]
L2433:
    b Lnext
L2426:
    bl Ltick_slow4
    b L2427
L2428:
    bl Lrd_slow
    b L2429
L2430:
    bl Ltick_slow4
    b L2431
L2432:
    mov w0, w11
    bl Lwr_slow
    b L2433
    .p2align 4
Lccb_97:
    and w2, w26, #0xFFFFFFFB
    and w26, w2, #0xFF
    b Lnext
    .p2align 4
Lccb_98:
    lsr w0, w28, #8
    and w2, w0, #0xFFFFFFF7
    bfi w28, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_99:
    and w0, w28, #0xFF
    and w2, w0, #0xFFFFFFF7
    bfi w28, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_9A:
    lsr w0, w13, #8
    and w2, w0, #0xFFFFFFF7
    bfi w13, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_9B:
    and w0, w13, #0xFF
    and w2, w0, #0xFFFFFFF7
    bfi w13, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_9C:
    lsr w0, w14, #8
    and w2, w0, #0xFFFFFFF7
    bfi w14, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_9D:
    and w0, w14, #0xFF
    and w2, w0, #0xFFFFFFF7
    bfi w14, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_9E:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2434
L2435:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2436
L2437:
    ldrb w11, [x10, w9, uxtw]
    and w2, w11, #0xFFFFFFF7
    and w11, w2, #0xFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2438
L2439:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2440
    strb w11, [x10, w9, uxtw]
L2441:
    b Lnext
L2434:
    bl Ltick_slow4
    b L2435
L2436:
    bl Lrd_slow
    b L2437
L2438:
    bl Ltick_slow4
    b L2439
L2440:
    mov w0, w11
    bl Lwr_slow
    b L2441
    .p2align 4
Lccb_9F:
    and w2, w26, #0xFFFFFFF7
    and w26, w2, #0xFF
    b Lnext
    .p2align 4
Lccb_A0:
    lsr w0, w28, #8
    and w2, w0, #0xFFFFFFEF
    bfi w28, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_A1:
    and w0, w28, #0xFF
    and w2, w0, #0xFFFFFFEF
    bfi w28, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_A2:
    lsr w0, w13, #8
    and w2, w0, #0xFFFFFFEF
    bfi w13, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_A3:
    and w0, w13, #0xFF
    and w2, w0, #0xFFFFFFEF
    bfi w13, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_A4:
    lsr w0, w14, #8
    and w2, w0, #0xFFFFFFEF
    bfi w14, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_A5:
    and w0, w14, #0xFF
    and w2, w0, #0xFFFFFFEF
    bfi w14, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_A6:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2442
L2443:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2444
L2445:
    ldrb w11, [x10, w9, uxtw]
    and w2, w11, #0xFFFFFFEF
    and w11, w2, #0xFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2446
L2447:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2448
    strb w11, [x10, w9, uxtw]
L2449:
    b Lnext
L2442:
    bl Ltick_slow4
    b L2443
L2444:
    bl Lrd_slow
    b L2445
L2446:
    bl Ltick_slow4
    b L2447
L2448:
    mov w0, w11
    bl Lwr_slow
    b L2449
    .p2align 4
Lccb_A7:
    and w2, w26, #0xFFFFFFEF
    and w26, w2, #0xFF
    b Lnext
    .p2align 4
Lccb_A8:
    lsr w0, w28, #8
    and w2, w0, #0xFFFFFFDF
    bfi w28, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_A9:
    and w0, w28, #0xFF
    and w2, w0, #0xFFFFFFDF
    bfi w28, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_AA:
    lsr w0, w13, #8
    and w2, w0, #0xFFFFFFDF
    bfi w13, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_AB:
    and w0, w13, #0xFF
    and w2, w0, #0xFFFFFFDF
    bfi w13, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_AC:
    lsr w0, w14, #8
    and w2, w0, #0xFFFFFFDF
    bfi w14, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_AD:
    and w0, w14, #0xFF
    and w2, w0, #0xFFFFFFDF
    bfi w14, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_AE:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2450
L2451:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2452
L2453:
    ldrb w11, [x10, w9, uxtw]
    and w2, w11, #0xFFFFFFDF
    and w11, w2, #0xFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2454
L2455:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2456
    strb w11, [x10, w9, uxtw]
L2457:
    b Lnext
L2450:
    bl Ltick_slow4
    b L2451
L2452:
    bl Lrd_slow
    b L2453
L2454:
    bl Ltick_slow4
    b L2455
L2456:
    mov w0, w11
    bl Lwr_slow
    b L2457
    .p2align 4
Lccb_AF:
    and w2, w26, #0xFFFFFFDF
    and w26, w2, #0xFF
    b Lnext
    .p2align 4
Lccb_B0:
    lsr w0, w28, #8
    and w2, w0, #0xFFFFFFBF
    bfi w28, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_B1:
    and w0, w28, #0xFF
    and w2, w0, #0xFFFFFFBF
    bfi w28, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_B2:
    lsr w0, w13, #8
    and w2, w0, #0xFFFFFFBF
    bfi w13, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_B3:
    and w0, w13, #0xFF
    and w2, w0, #0xFFFFFFBF
    bfi w13, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_B4:
    lsr w0, w14, #8
    and w2, w0, #0xFFFFFFBF
    bfi w14, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_B5:
    and w0, w14, #0xFF
    and w2, w0, #0xFFFFFFBF
    bfi w14, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_B6:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2458
L2459:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2460
L2461:
    ldrb w11, [x10, w9, uxtw]
    and w2, w11, #0xFFFFFFBF
    and w11, w2, #0xFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2462
L2463:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2464
    strb w11, [x10, w9, uxtw]
L2465:
    b Lnext
L2458:
    bl Ltick_slow4
    b L2459
L2460:
    bl Lrd_slow
    b L2461
L2462:
    bl Ltick_slow4
    b L2463
L2464:
    mov w0, w11
    bl Lwr_slow
    b L2465
    .p2align 4
Lccb_B7:
    and w2, w26, #0xFFFFFFBF
    and w26, w2, #0xFF
    b Lnext
    .p2align 4
Lccb_B8:
    lsr w0, w28, #8
    and w2, w0, #0xFFFFFF7F
    bfi w28, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_B9:
    and w0, w28, #0xFF
    and w2, w0, #0xFFFFFF7F
    bfi w28, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_BA:
    lsr w0, w13, #8
    and w2, w0, #0xFFFFFF7F
    bfi w13, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_BB:
    and w0, w13, #0xFF
    and w2, w0, #0xFFFFFF7F
    bfi w13, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_BC:
    lsr w0, w14, #8
    and w2, w0, #0xFFFFFF7F
    bfi w14, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_BD:
    and w0, w14, #0xFF
    and w2, w0, #0xFFFFFF7F
    bfi w14, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_BE:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2466
L2467:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2468
L2469:
    ldrb w11, [x10, w9, uxtw]
    and w2, w11, #0xFFFFFF7F
    and w11, w2, #0xFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2470
L2471:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2472
    strb w11, [x10, w9, uxtw]
L2473:
    b Lnext
L2466:
    bl Ltick_slow4
    b L2467
L2468:
    bl Lrd_slow
    b L2469
L2470:
    bl Ltick_slow4
    b L2471
L2472:
    mov w0, w11
    bl Lwr_slow
    b L2473
    .p2align 4
Lccb_BF:
    and w2, w26, #0xFFFFFF7F
    and w26, w2, #0xFF
    b Lnext
    .p2align 4
Lccb_C0:
    lsr w0, w28, #8
    orr w2, w0, #1
    bfi w28, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_C1:
    and w0, w28, #0xFF
    orr w2, w0, #1
    bfi w28, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_C2:
    lsr w0, w13, #8
    orr w2, w0, #1
    bfi w13, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_C3:
    and w0, w13, #0xFF
    orr w2, w0, #1
    bfi w13, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_C4:
    lsr w0, w14, #8
    orr w2, w0, #1
    bfi w14, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_C5:
    and w0, w14, #0xFF
    orr w2, w0, #1
    bfi w14, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_C6:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2474
L2475:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2476
L2477:
    ldrb w11, [x10, w9, uxtw]
    orr w2, w11, #1
    and w11, w2, #0xFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2478
L2479:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2480
    strb w11, [x10, w9, uxtw]
L2481:
    b Lnext
L2474:
    bl Ltick_slow4
    b L2475
L2476:
    bl Lrd_slow
    b L2477
L2478:
    bl Ltick_slow4
    b L2479
L2480:
    mov w0, w11
    bl Lwr_slow
    b L2481
    .p2align 4
Lccb_C7:
    orr w2, w26, #1
    and w26, w2, #0xFF
    b Lnext
    .p2align 4
Lccb_C8:
    lsr w0, w28, #8
    orr w2, w0, #2
    bfi w28, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_C9:
    and w0, w28, #0xFF
    orr w2, w0, #2
    bfi w28, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_CA:
    lsr w0, w13, #8
    orr w2, w0, #2
    bfi w13, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_CB:
    and w0, w13, #0xFF
    orr w2, w0, #2
    bfi w13, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_CC:
    lsr w0, w14, #8
    orr w2, w0, #2
    bfi w14, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_CD:
    and w0, w14, #0xFF
    orr w2, w0, #2
    bfi w14, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_CE:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2482
L2483:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2484
L2485:
    ldrb w11, [x10, w9, uxtw]
    orr w2, w11, #2
    and w11, w2, #0xFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2486
L2487:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2488
    strb w11, [x10, w9, uxtw]
L2489:
    b Lnext
L2482:
    bl Ltick_slow4
    b L2483
L2484:
    bl Lrd_slow
    b L2485
L2486:
    bl Ltick_slow4
    b L2487
L2488:
    mov w0, w11
    bl Lwr_slow
    b L2489
    .p2align 4
Lccb_CF:
    orr w2, w26, #2
    and w26, w2, #0xFF
    b Lnext
    .p2align 4
Lccb_D0:
    lsr w0, w28, #8
    orr w2, w0, #4
    bfi w28, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_D1:
    and w0, w28, #0xFF
    orr w2, w0, #4
    bfi w28, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_D2:
    lsr w0, w13, #8
    orr w2, w0, #4
    bfi w13, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_D3:
    and w0, w13, #0xFF
    orr w2, w0, #4
    bfi w13, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_D4:
    lsr w0, w14, #8
    orr w2, w0, #4
    bfi w14, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_D5:
    and w0, w14, #0xFF
    orr w2, w0, #4
    bfi w14, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_D6:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2490
L2491:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2492
L2493:
    ldrb w11, [x10, w9, uxtw]
    orr w2, w11, #4
    and w11, w2, #0xFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2494
L2495:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2496
    strb w11, [x10, w9, uxtw]
L2497:
    b Lnext
L2490:
    bl Ltick_slow4
    b L2491
L2492:
    bl Lrd_slow
    b L2493
L2494:
    bl Ltick_slow4
    b L2495
L2496:
    mov w0, w11
    bl Lwr_slow
    b L2497
    .p2align 4
Lccb_D7:
    orr w2, w26, #4
    and w26, w2, #0xFF
    b Lnext
    .p2align 4
Lccb_D8:
    lsr w0, w28, #8
    orr w2, w0, #8
    bfi w28, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_D9:
    and w0, w28, #0xFF
    orr w2, w0, #8
    bfi w28, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_DA:
    lsr w0, w13, #8
    orr w2, w0, #8
    bfi w13, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_DB:
    and w0, w13, #0xFF
    orr w2, w0, #8
    bfi w13, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_DC:
    lsr w0, w14, #8
    orr w2, w0, #8
    bfi w14, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_DD:
    and w0, w14, #0xFF
    orr w2, w0, #8
    bfi w14, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_DE:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2498
L2499:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2500
L2501:
    ldrb w11, [x10, w9, uxtw]
    orr w2, w11, #8
    and w11, w2, #0xFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2502
L2503:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2504
    strb w11, [x10, w9, uxtw]
L2505:
    b Lnext
L2498:
    bl Ltick_slow4
    b L2499
L2500:
    bl Lrd_slow
    b L2501
L2502:
    bl Ltick_slow4
    b L2503
L2504:
    mov w0, w11
    bl Lwr_slow
    b L2505
    .p2align 4
Lccb_DF:
    orr w2, w26, #8
    and w26, w2, #0xFF
    b Lnext
    .p2align 4
Lccb_E0:
    lsr w0, w28, #8
    orr w2, w0, #16
    bfi w28, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_E1:
    and w0, w28, #0xFF
    orr w2, w0, #16
    bfi w28, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_E2:
    lsr w0, w13, #8
    orr w2, w0, #16
    bfi w13, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_E3:
    and w0, w13, #0xFF
    orr w2, w0, #16
    bfi w13, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_E4:
    lsr w0, w14, #8
    orr w2, w0, #16
    bfi w14, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_E5:
    and w0, w14, #0xFF
    orr w2, w0, #16
    bfi w14, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_E6:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2506
L2507:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2508
L2509:
    ldrb w11, [x10, w9, uxtw]
    orr w2, w11, #16
    and w11, w2, #0xFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2510
L2511:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2512
    strb w11, [x10, w9, uxtw]
L2513:
    b Lnext
L2506:
    bl Ltick_slow4
    b L2507
L2508:
    bl Lrd_slow
    b L2509
L2510:
    bl Ltick_slow4
    b L2511
L2512:
    mov w0, w11
    bl Lwr_slow
    b L2513
    .p2align 4
Lccb_E7:
    orr w2, w26, #16
    and w26, w2, #0xFF
    b Lnext
    .p2align 4
Lccb_E8:
    lsr w0, w28, #8
    orr w2, w0, #32
    bfi w28, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_E9:
    and w0, w28, #0xFF
    orr w2, w0, #32
    bfi w28, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_EA:
    lsr w0, w13, #8
    orr w2, w0, #32
    bfi w13, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_EB:
    and w0, w13, #0xFF
    orr w2, w0, #32
    bfi w13, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_EC:
    lsr w0, w14, #8
    orr w2, w0, #32
    bfi w14, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_ED:
    and w0, w14, #0xFF
    orr w2, w0, #32
    bfi w14, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_EE:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2514
L2515:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2516
L2517:
    ldrb w11, [x10, w9, uxtw]
    orr w2, w11, #32
    and w11, w2, #0xFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2518
L2519:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2520
    strb w11, [x10, w9, uxtw]
L2521:
    b Lnext
L2514:
    bl Ltick_slow4
    b L2515
L2516:
    bl Lrd_slow
    b L2517
L2518:
    bl Ltick_slow4
    b L2519
L2520:
    mov w0, w11
    bl Lwr_slow
    b L2521
    .p2align 4
Lccb_EF:
    orr w2, w26, #32
    and w26, w2, #0xFF
    b Lnext
    .p2align 4
Lccb_F0:
    lsr w0, w28, #8
    orr w2, w0, #64
    bfi w28, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_F1:
    and w0, w28, #0xFF
    orr w2, w0, #64
    bfi w28, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_F2:
    lsr w0, w13, #8
    orr w2, w0, #64
    bfi w13, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_F3:
    and w0, w13, #0xFF
    orr w2, w0, #64
    bfi w13, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_F4:
    lsr w0, w14, #8
    orr w2, w0, #64
    bfi w14, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_F5:
    and w0, w14, #0xFF
    orr w2, w0, #64
    bfi w14, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_F6:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2522
L2523:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2524
L2525:
    ldrb w11, [x10, w9, uxtw]
    orr w2, w11, #64
    and w11, w2, #0xFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2526
L2527:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2528
    strb w11, [x10, w9, uxtw]
L2529:
    b Lnext
L2522:
    bl Ltick_slow4
    b L2523
L2524:
    bl Lrd_slow
    b L2525
L2526:
    bl Ltick_slow4
    b L2527
L2528:
    mov w0, w11
    bl Lwr_slow
    b L2529
    .p2align 4
Lccb_F7:
    orr w2, w26, #64
    and w26, w2, #0xFF
    b Lnext
    .p2align 4
Lccb_F8:
    lsr w0, w28, #8
    orr w2, w0, #128
    bfi w28, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_F9:
    and w0, w28, #0xFF
    orr w2, w0, #128
    bfi w28, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_FA:
    lsr w0, w13, #8
    orr w2, w0, #128
    bfi w13, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_FB:
    and w0, w13, #0xFF
    orr w2, w0, #128
    bfi w13, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_FC:
    lsr w0, w14, #8
    orr w2, w0, #128
    bfi w14, w2, #8, #8
    b Lnext
    .p2align 4
Lccb_FD:
    and w0, w14, #0xFF
    orr w2, w0, #128
    bfi w14, w2, #0, #8
    b Lnext
    .p2align 4
Lccb_FE:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2530
L2531:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2532
L2533:
    ldrb w11, [x10, w9, uxtw]
    orr w2, w11, #128
    and w11, w2, #0xFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2534
L2535:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2536
    strb w11, [x10, w9, uxtw]
L2537:
    b Lnext
L2530:
    bl Ltick_slow4
    b L2531
L2532:
    bl Lrd_slow
    b L2533
L2534:
    bl Ltick_slow4
    b L2535
L2536:
    mov w0, w11
    bl Lwr_slow
    b L2537
    .p2align 4
Lccb_FF:
    orr w2, w26, #128
    and w26, w2, #0xFF
    b Lnext
    .p2align 2
Ljt_f:
    .word Lf_00 - Ljt_f
    .word Lf_01 - Ljt_f
    .word Lf_02 - Ljt_f
    .word Lf_03 - Ljt_f
    .word Lf_04 - Ljt_f
    .word Lf_05 - Ljt_f
    .word Lf_06 - Ljt_f
    .word Lf_07 - Ljt_f
    .word Lf_08 - Ljt_f
    .word Lf_09 - Ljt_f
    .word Lf_0A - Ljt_f
    .word Lf_0B - Ljt_f
    .word Lf_0C - Ljt_f
    .word Lf_0D - Ljt_f
    .word Lf_0E - Ljt_f
    .word Lf_0F - Ljt_f
    .word Lf_10 - Ljt_f
    .word Lf_11 - Ljt_f
    .word Lf_12 - Ljt_f
    .word Lf_13 - Ljt_f
    .word Lf_14 - Ljt_f
    .word Lf_15 - Ljt_f
    .word Lf_16 - Ljt_f
    .word Lf_17 - Ljt_f
    .word Lf_18 - Ljt_f
    .word Lf_19 - Ljt_f
    .word Lf_1A - Ljt_f
    .word Lf_1B - Ljt_f
    .word Lf_1C - Ljt_f
    .word Lf_1D - Ljt_f
    .word Lf_1E - Ljt_f
    .word Lf_1F - Ljt_f
    .word Lf_20 - Ljt_f
    .word Lf_21 - Ljt_f
    .word Lf_22 - Ljt_f
    .word Lf_23 - Ljt_f
    .word Lf_24 - Ljt_f
    .word Lf_25 - Ljt_f
    .word Lf_26 - Ljt_f
    .word Lf_27 - Ljt_f
    .word Lf_28 - Ljt_f
    .word Lf_29 - Ljt_f
    .word Lf_2A - Ljt_f
    .word Lf_2B - Ljt_f
    .word Lf_2C - Ljt_f
    .word Lf_2D - Ljt_f
    .word Lf_2E - Ljt_f
    .word Lf_2F - Ljt_f
    .word Lf_30 - Ljt_f
    .word Lf_31 - Ljt_f
    .word Lf_32 - Ljt_f
    .word Lf_33 - Ljt_f
    .word Lf_34 - Ljt_f
    .word Lf_35 - Ljt_f
    .word Lf_36 - Ljt_f
    .word Lf_37 - Ljt_f
    .word Lf_38 - Ljt_f
    .word Lf_39 - Ljt_f
    .word Lf_3A - Ljt_f
    .word Lf_3B - Ljt_f
    .word Lf_3C - Ljt_f
    .word Lf_3D - Ljt_f
    .word Lf_3E - Ljt_f
    .word Lf_3F - Ljt_f
    .word Lf_40 - Ljt_f
    .word Lf_41 - Ljt_f
    .word Lf_42 - Ljt_f
    .word Lf_43 - Ljt_f
    .word Lf_44 - Ljt_f
    .word Lf_45 - Ljt_f
    .word Lf_46 - Ljt_f
    .word Lf_47 - Ljt_f
    .word Lf_48 - Ljt_f
    .word Lf_49 - Ljt_f
    .word Lf_4A - Ljt_f
    .word Lf_4B - Ljt_f
    .word Lf_4C - Ljt_f
    .word Lf_4D - Ljt_f
    .word Lf_4E - Ljt_f
    .word Lf_4F - Ljt_f
    .word Lf_50 - Ljt_f
    .word Lf_51 - Ljt_f
    .word Lf_52 - Ljt_f
    .word Lf_53 - Ljt_f
    .word Lf_54 - Ljt_f
    .word Lf_55 - Ljt_f
    .word Lf_56 - Ljt_f
    .word Lf_57 - Ljt_f
    .word Lf_58 - Ljt_f
    .word Lf_59 - Ljt_f
    .word Lf_5A - Ljt_f
    .word Lf_5B - Ljt_f
    .word Lf_5C - Ljt_f
    .word Lf_5D - Ljt_f
    .word Lf_5E - Ljt_f
    .word Lf_5F - Ljt_f
    .word Lf_60 - Ljt_f
    .word Lf_61 - Ljt_f
    .word Lf_62 - Ljt_f
    .word Lf_63 - Ljt_f
    .word Lf_64 - Ljt_f
    .word Lf_65 - Ljt_f
    .word Lf_66 - Ljt_f
    .word Lf_67 - Ljt_f
    .word Lf_68 - Ljt_f
    .word Lf_69 - Ljt_f
    .word Lf_6A - Ljt_f
    .word Lf_6B - Ljt_f
    .word Lf_6C - Ljt_f
    .word Lf_6D - Ljt_f
    .word Lf_6E - Ljt_f
    .word Lf_6F - Ljt_f
    .word Lf_70 - Ljt_f
    .word Lf_71 - Ljt_f
    .word Lf_72 - Ljt_f
    .word Lf_73 - Ljt_f
    .word Lf_74 - Ljt_f
    .word Lf_75 - Ljt_f
    .word Lf_76 - Ljt_f
    .word Lf_77 - Ljt_f
    .word Lf_78 - Ljt_f
    .word Lf_79 - Ljt_f
    .word Lf_7A - Ljt_f
    .word Lf_7B - Ljt_f
    .word Lf_7C - Ljt_f
    .word Lf_7D - Ljt_f
    .word Lf_7E - Ljt_f
    .word Lf_7F - Ljt_f
    .word Lf_80 - Ljt_f
    .word Lf_81 - Ljt_f
    .word Lf_82 - Ljt_f
    .word Lf_83 - Ljt_f
    .word Lf_84 - Ljt_f
    .word Lf_85 - Ljt_f
    .word Lf_86 - Ljt_f
    .word Lf_87 - Ljt_f
    .word Lf_88 - Ljt_f
    .word Lf_89 - Ljt_f
    .word Lf_8A - Ljt_f
    .word Lf_8B - Ljt_f
    .word Lf_8C - Ljt_f
    .word Lf_8D - Ljt_f
    .word Lf_8E - Ljt_f
    .word Lf_8F - Ljt_f
    .word Lf_90 - Ljt_f
    .word Lf_91 - Ljt_f
    .word Lf_92 - Ljt_f
    .word Lf_93 - Ljt_f
    .word Lf_94 - Ljt_f
    .word Lf_95 - Ljt_f
    .word Lf_96 - Ljt_f
    .word Lf_97 - Ljt_f
    .word Lf_98 - Ljt_f
    .word Lf_99 - Ljt_f
    .word Lf_9A - Ljt_f
    .word Lf_9B - Ljt_f
    .word Lf_9C - Ljt_f
    .word Lf_9D - Ljt_f
    .word Lf_9E - Ljt_f
    .word Lf_9F - Ljt_f
    .word Lf_A0 - Ljt_f
    .word Lf_A1 - Ljt_f
    .word Lf_A2 - Ljt_f
    .word Lf_A3 - Ljt_f
    .word Lf_A4 - Ljt_f
    .word Lf_A5 - Ljt_f
    .word Lf_A6 - Ljt_f
    .word Lf_A7 - Ljt_f
    .word Lf_A8 - Ljt_f
    .word Lf_A9 - Ljt_f
    .word Lf_AA - Ljt_f
    .word Lf_AB - Ljt_f
    .word Lf_AC - Ljt_f
    .word Lf_AD - Ljt_f
    .word Lf_AE - Ljt_f
    .word Lf_AF - Ljt_f
    .word Lf_B0 - Ljt_f
    .word Lf_B1 - Ljt_f
    .word Lf_B2 - Ljt_f
    .word Lf_B3 - Ljt_f
    .word Lf_B4 - Ljt_f
    .word Lf_B5 - Ljt_f
    .word Lf_B6 - Ljt_f
    .word Lf_B7 - Ljt_f
    .word Lf_B8 - Ljt_f
    .word Lf_B9 - Ljt_f
    .word Lf_BA - Ljt_f
    .word Lf_BB - Ljt_f
    .word Lf_BC - Ljt_f
    .word Lf_BD - Ljt_f
    .word Lf_BE - Ljt_f
    .word Lf_BF - Ljt_f
    .word Lf_C0 - Ljt_f
    .word Lf_C1 - Ljt_f
    .word Lf_C2 - Ljt_f
    .word Lf_C3 - Ljt_f
    .word Lf_C4 - Ljt_f
    .word Lf_C5 - Ljt_f
    .word Lf_C6 - Ljt_f
    .word Lf_C7 - Ljt_f
    .word Lf_C8 - Ljt_f
    .word Lf_C9 - Ljt_f
    .word Lf_CA - Ljt_f
    .word Lf_CB - Ljt_f
    .word Lf_CC - Ljt_f
    .word Lf_CD - Ljt_f
    .word Lf_CE - Ljt_f
    .word Lf_CF - Ljt_f
    .word Lf_D0 - Ljt_f
    .word Lf_D1 - Ljt_f
    .word Lf_D2 - Ljt_f
    .word Lf_D3 - Ljt_f
    .word Lf_D4 - Ljt_f
    .word Lf_D5 - Ljt_f
    .word Lf_D6 - Ljt_f
    .word Lf_D7 - Ljt_f
    .word Lf_D8 - Ljt_f
    .word Lf_D9 - Ljt_f
    .word Lf_DA - Ljt_f
    .word Lf_DB - Ljt_f
    .word Lf_DC - Ljt_f
    .word Lf_DD - Ljt_f
    .word Lf_DE - Ljt_f
    .word Lf_DF - Ljt_f
    .word Lf_E0 - Ljt_f
    .word Lf_E1 - Ljt_f
    .word Lf_E2 - Ljt_f
    .word Lf_E3 - Ljt_f
    .word Lf_E4 - Ljt_f
    .word Lf_E5 - Ljt_f
    .word Lf_E6 - Ljt_f
    .word Lf_E7 - Ljt_f
    .word Lf_E8 - Ljt_f
    .word Lf_E9 - Ljt_f
    .word Lf_EA - Ljt_f
    .word Lf_EB - Ljt_f
    .word Lf_EC - Ljt_f
    .word Lf_ED - Ljt_f
    .word Lf_EE - Ljt_f
    .word Lf_EF - Ljt_f
    .word Lf_F0 - Ljt_f
    .word Lf_F1 - Ljt_f
    .word Lf_F2 - Ljt_f
    .word Lf_F3 - Ljt_f
    .word Lf_F4 - Ljt_f
    .word Lf_F5 - Ljt_f
    .word Lf_F6 - Ljt_f
    .word Lf_F7 - Ljt_f
    .word Lf_F8 - Ljt_f
    .word Lf_F9 - Ljt_f
    .word Lf_FA - Ljt_f
    .word Lf_FB - Ljt_f
    .word Lf_FC - Ljt_f
    .word Lf_FD - Ljt_f
    .word Lf_FE - Ljt_f
    .word Lf_FF - Ljt_f
    .p2align 2
Ljt_c:
    .word Lc_00 - Ljt_c
    .word Lc_01 - Ljt_c
    .word Lc_02 - Ljt_c
    .word Lc_03 - Ljt_c
    .word Lc_04 - Ljt_c
    .word Lc_05 - Ljt_c
    .word Lc_06 - Ljt_c
    .word Lc_07 - Ljt_c
    .word Lc_08 - Ljt_c
    .word Lc_09 - Ljt_c
    .word Lc_0A - Ljt_c
    .word Lc_0B - Ljt_c
    .word Lc_0C - Ljt_c
    .word Lc_0D - Ljt_c
    .word Lc_0E - Ljt_c
    .word Lc_0F - Ljt_c
    .word Lc_10 - Ljt_c
    .word Lc_11 - Ljt_c
    .word Lc_12 - Ljt_c
    .word Lc_13 - Ljt_c
    .word Lc_14 - Ljt_c
    .word Lc_15 - Ljt_c
    .word Lc_16 - Ljt_c
    .word Lc_17 - Ljt_c
    .word Lc_18 - Ljt_c
    .word Lc_19 - Ljt_c
    .word Lc_1A - Ljt_c
    .word Lc_1B - Ljt_c
    .word Lc_1C - Ljt_c
    .word Lc_1D - Ljt_c
    .word Lc_1E - Ljt_c
    .word Lc_1F - Ljt_c
    .word Lc_20 - Ljt_c
    .word Lc_21 - Ljt_c
    .word Lc_22 - Ljt_c
    .word Lc_23 - Ljt_c
    .word Lc_24 - Ljt_c
    .word Lc_25 - Ljt_c
    .word Lc_26 - Ljt_c
    .word Lc_27 - Ljt_c
    .word Lc_28 - Ljt_c
    .word Lc_29 - Ljt_c
    .word Lc_2A - Ljt_c
    .word Lc_2B - Ljt_c
    .word Lc_2C - Ljt_c
    .word Lc_2D - Ljt_c
    .word Lc_2E - Ljt_c
    .word Lc_2F - Ljt_c
    .word Lc_30 - Ljt_c
    .word Lc_31 - Ljt_c
    .word Lc_32 - Ljt_c
    .word Lc_33 - Ljt_c
    .word Lc_34 - Ljt_c
    .word Lc_35 - Ljt_c
    .word Lc_36 - Ljt_c
    .word Lc_37 - Ljt_c
    .word Lc_38 - Ljt_c
    .word Lc_39 - Ljt_c
    .word Lc_3A - Ljt_c
    .word Lc_3B - Ljt_c
    .word Lc_3C - Ljt_c
    .word Lc_3D - Ljt_c
    .word Lc_3E - Ljt_c
    .word Lc_3F - Ljt_c
    .word Lc_40 - Ljt_c
    .word Lc_41 - Ljt_c
    .word Lc_42 - Ljt_c
    .word Lc_43 - Ljt_c
    .word Lc_44 - Ljt_c
    .word Lc_45 - Ljt_c
    .word Lc_46 - Ljt_c
    .word Lc_47 - Ljt_c
    .word Lc_48 - Ljt_c
    .word Lc_49 - Ljt_c
    .word Lc_4A - Ljt_c
    .word Lc_4B - Ljt_c
    .word Lc_4C - Ljt_c
    .word Lc_4D - Ljt_c
    .word Lc_4E - Ljt_c
    .word Lc_4F - Ljt_c
    .word Lc_50 - Ljt_c
    .word Lc_51 - Ljt_c
    .word Lc_52 - Ljt_c
    .word Lc_53 - Ljt_c
    .word Lc_54 - Ljt_c
    .word Lc_55 - Ljt_c
    .word Lc_56 - Ljt_c
    .word Lc_57 - Ljt_c
    .word Lc_58 - Ljt_c
    .word Lc_59 - Ljt_c
    .word Lc_5A - Ljt_c
    .word Lc_5B - Ljt_c
    .word Lc_5C - Ljt_c
    .word Lc_5D - Ljt_c
    .word Lc_5E - Ljt_c
    .word Lc_5F - Ljt_c
    .word Lc_60 - Ljt_c
    .word Lc_61 - Ljt_c
    .word Lc_62 - Ljt_c
    .word Lc_63 - Ljt_c
    .word Lc_64 - Ljt_c
    .word Lc_65 - Ljt_c
    .word Lc_66 - Ljt_c
    .word Lc_67 - Ljt_c
    .word Lc_68 - Ljt_c
    .word Lc_69 - Ljt_c
    .word Lc_6A - Ljt_c
    .word Lc_6B - Ljt_c
    .word Lc_6C - Ljt_c
    .word Lc_6D - Ljt_c
    .word Lc_6E - Ljt_c
    .word Lc_6F - Ljt_c
    .word Lc_70 - Ljt_c
    .word Lc_71 - Ljt_c
    .word Lc_72 - Ljt_c
    .word Lc_73 - Ljt_c
    .word Lc_74 - Ljt_c
    .word Lc_75 - Ljt_c
    .word Lc_76 - Ljt_c
    .word Lc_77 - Ljt_c
    .word Lc_78 - Ljt_c
    .word Lc_79 - Ljt_c
    .word Lc_7A - Ljt_c
    .word Lc_7B - Ljt_c
    .word Lc_7C - Ljt_c
    .word Lc_7D - Ljt_c
    .word Lc_7E - Ljt_c
    .word Lc_7F - Ljt_c
    .word Lc_80 - Ljt_c
    .word Lc_81 - Ljt_c
    .word Lc_82 - Ljt_c
    .word Lc_83 - Ljt_c
    .word Lc_84 - Ljt_c
    .word Lc_85 - Ljt_c
    .word Lc_86 - Ljt_c
    .word Lc_87 - Ljt_c
    .word Lc_88 - Ljt_c
    .word Lc_89 - Ljt_c
    .word Lc_8A - Ljt_c
    .word Lc_8B - Ljt_c
    .word Lc_8C - Ljt_c
    .word Lc_8D - Ljt_c
    .word Lc_8E - Ljt_c
    .word Lc_8F - Ljt_c
    .word Lc_90 - Ljt_c
    .word Lc_91 - Ljt_c
    .word Lc_92 - Ljt_c
    .word Lc_93 - Ljt_c
    .word Lc_94 - Ljt_c
    .word Lc_95 - Ljt_c
    .word Lc_96 - Ljt_c
    .word Lc_97 - Ljt_c
    .word Lc_98 - Ljt_c
    .word Lc_99 - Ljt_c
    .word Lc_9A - Ljt_c
    .word Lc_9B - Ljt_c
    .word Lc_9C - Ljt_c
    .word Lc_9D - Ljt_c
    .word Lc_9E - Ljt_c
    .word Lc_9F - Ljt_c
    .word Lc_A0 - Ljt_c
    .word Lc_A1 - Ljt_c
    .word Lc_A2 - Ljt_c
    .word Lc_A3 - Ljt_c
    .word Lc_A4 - Ljt_c
    .word Lc_A5 - Ljt_c
    .word Lc_A6 - Ljt_c
    .word Lc_A7 - Ljt_c
    .word Lc_A8 - Ljt_c
    .word Lc_A9 - Ljt_c
    .word Lc_AA - Ljt_c
    .word Lc_AB - Ljt_c
    .word Lc_AC - Ljt_c
    .word Lc_AD - Ljt_c
    .word Lc_AE - Ljt_c
    .word Lc_AF - Ljt_c
    .word Lc_B0 - Ljt_c
    .word Lc_B1 - Ljt_c
    .word Lc_B2 - Ljt_c
    .word Lc_B3 - Ljt_c
    .word Lc_B4 - Ljt_c
    .word Lc_B5 - Ljt_c
    .word Lc_B6 - Ljt_c
    .word Lc_B7 - Ljt_c
    .word Lc_B8 - Ljt_c
    .word Lc_B9 - Ljt_c
    .word Lc_BA - Ljt_c
    .word Lc_BB - Ljt_c
    .word Lc_BC - Ljt_c
    .word Lc_BD - Ljt_c
    .word Lc_BE - Ljt_c
    .word Lc_BF - Ljt_c
    .word Lc_C0 - Ljt_c
    .word Lc_C1 - Ljt_c
    .word Lc_C2 - Ljt_c
    .word Lc_C3 - Ljt_c
    .word Lc_C4 - Ljt_c
    .word Lc_C5 - Ljt_c
    .word Lc_C6 - Ljt_c
    .word Lc_C7 - Ljt_c
    .word Lc_C8 - Ljt_c
    .word Lc_C9 - Ljt_c
    .word Lc_CA - Ljt_c
    .word Lc_CB - Ljt_c
    .word Lc_CC - Ljt_c
    .word Lc_CD - Ljt_c
    .word Lc_CE - Ljt_c
    .word Lc_CF - Ljt_c
    .word Lc_D0 - Ljt_c
    .word Lc_D1 - Ljt_c
    .word Lc_D2 - Ljt_c
    .word Lc_D3 - Ljt_c
    .word Lc_D4 - Ljt_c
    .word Lc_D5 - Ljt_c
    .word Lc_D6 - Ljt_c
    .word Lc_D7 - Ljt_c
    .word Lc_D8 - Ljt_c
    .word Lc_D9 - Ljt_c
    .word Lc_DA - Ljt_c
    .word Lc_DB - Ljt_c
    .word Lc_DC - Ljt_c
    .word Lc_DD - Ljt_c
    .word Lc_DE - Ljt_c
    .word Lc_DF - Ljt_c
    .word Lc_E0 - Ljt_c
    .word Lc_E1 - Ljt_c
    .word Lc_E2 - Ljt_c
    .word Lc_E3 - Ljt_c
    .word Lc_E4 - Ljt_c
    .word Lc_E5 - Ljt_c
    .word Lc_E6 - Ljt_c
    .word Lc_E7 - Ljt_c
    .word Lc_E8 - Ljt_c
    .word Lc_E9 - Ljt_c
    .word Lc_EA - Ljt_c
    .word Lc_EB - Ljt_c
    .word Lc_EC - Ljt_c
    .word Lc_ED - Ljt_c
    .word Lc_EE - Ljt_c
    .word Lc_EF - Ljt_c
    .word Lc_F0 - Ljt_c
    .word Lc_F1 - Ljt_c
    .word Lc_F2 - Ljt_c
    .word Lc_F3 - Ljt_c
    .word Lc_F4 - Ljt_c
    .word Lc_F5 - Ljt_c
    .word Lc_F6 - Ljt_c
    .word Lc_F7 - Ljt_c
    .word Lc_F8 - Ljt_c
    .word Lc_F9 - Ljt_c
    .word Lc_FA - Ljt_c
    .word Lc_FB - Ljt_c
    .word Lc_FC - Ljt_c
    .word Lc_FD - Ljt_c
    .word Lc_FE - Ljt_c
    .word Lc_FF - Ljt_c
    .p2align 2
Ljt_fcb:
    .word Lfcb_00 - Ljt_fcb
    .word Lfcb_01 - Ljt_fcb
    .word Lfcb_02 - Ljt_fcb
    .word Lfcb_03 - Ljt_fcb
    .word Lfcb_04 - Ljt_fcb
    .word Lfcb_05 - Ljt_fcb
    .word Lfcb_06 - Ljt_fcb
    .word Lfcb_07 - Ljt_fcb
    .word Lfcb_08 - Ljt_fcb
    .word Lfcb_09 - Ljt_fcb
    .word Lfcb_0A - Ljt_fcb
    .word Lfcb_0B - Ljt_fcb
    .word Lfcb_0C - Ljt_fcb
    .word Lfcb_0D - Ljt_fcb
    .word Lfcb_0E - Ljt_fcb
    .word Lfcb_0F - Ljt_fcb
    .word Lfcb_10 - Ljt_fcb
    .word Lfcb_11 - Ljt_fcb
    .word Lfcb_12 - Ljt_fcb
    .word Lfcb_13 - Ljt_fcb
    .word Lfcb_14 - Ljt_fcb
    .word Lfcb_15 - Ljt_fcb
    .word Lfcb_16 - Ljt_fcb
    .word Lfcb_17 - Ljt_fcb
    .word Lfcb_18 - Ljt_fcb
    .word Lfcb_19 - Ljt_fcb
    .word Lfcb_1A - Ljt_fcb
    .word Lfcb_1B - Ljt_fcb
    .word Lfcb_1C - Ljt_fcb
    .word Lfcb_1D - Ljt_fcb
    .word Lfcb_1E - Ljt_fcb
    .word Lfcb_1F - Ljt_fcb
    .word Lfcb_20 - Ljt_fcb
    .word Lfcb_21 - Ljt_fcb
    .word Lfcb_22 - Ljt_fcb
    .word Lfcb_23 - Ljt_fcb
    .word Lfcb_24 - Ljt_fcb
    .word Lfcb_25 - Ljt_fcb
    .word Lfcb_26 - Ljt_fcb
    .word Lfcb_27 - Ljt_fcb
    .word Lfcb_28 - Ljt_fcb
    .word Lfcb_29 - Ljt_fcb
    .word Lfcb_2A - Ljt_fcb
    .word Lfcb_2B - Ljt_fcb
    .word Lfcb_2C - Ljt_fcb
    .word Lfcb_2D - Ljt_fcb
    .word Lfcb_2E - Ljt_fcb
    .word Lfcb_2F - Ljt_fcb
    .word Lfcb_30 - Ljt_fcb
    .word Lfcb_31 - Ljt_fcb
    .word Lfcb_32 - Ljt_fcb
    .word Lfcb_33 - Ljt_fcb
    .word Lfcb_34 - Ljt_fcb
    .word Lfcb_35 - Ljt_fcb
    .word Lfcb_36 - Ljt_fcb
    .word Lfcb_37 - Ljt_fcb
    .word Lfcb_38 - Ljt_fcb
    .word Lfcb_39 - Ljt_fcb
    .word Lfcb_3A - Ljt_fcb
    .word Lfcb_3B - Ljt_fcb
    .word Lfcb_3C - Ljt_fcb
    .word Lfcb_3D - Ljt_fcb
    .word Lfcb_3E - Ljt_fcb
    .word Lfcb_3F - Ljt_fcb
    .word Lfcb_40 - Ljt_fcb
    .word Lfcb_41 - Ljt_fcb
    .word Lfcb_42 - Ljt_fcb
    .word Lfcb_43 - Ljt_fcb
    .word Lfcb_44 - Ljt_fcb
    .word Lfcb_45 - Ljt_fcb
    .word Lfcb_46 - Ljt_fcb
    .word Lfcb_47 - Ljt_fcb
    .word Lfcb_48 - Ljt_fcb
    .word Lfcb_49 - Ljt_fcb
    .word Lfcb_4A - Ljt_fcb
    .word Lfcb_4B - Ljt_fcb
    .word Lfcb_4C - Ljt_fcb
    .word Lfcb_4D - Ljt_fcb
    .word Lfcb_4E - Ljt_fcb
    .word Lfcb_4F - Ljt_fcb
    .word Lfcb_50 - Ljt_fcb
    .word Lfcb_51 - Ljt_fcb
    .word Lfcb_52 - Ljt_fcb
    .word Lfcb_53 - Ljt_fcb
    .word Lfcb_54 - Ljt_fcb
    .word Lfcb_55 - Ljt_fcb
    .word Lfcb_56 - Ljt_fcb
    .word Lfcb_57 - Ljt_fcb
    .word Lfcb_58 - Ljt_fcb
    .word Lfcb_59 - Ljt_fcb
    .word Lfcb_5A - Ljt_fcb
    .word Lfcb_5B - Ljt_fcb
    .word Lfcb_5C - Ljt_fcb
    .word Lfcb_5D - Ljt_fcb
    .word Lfcb_5E - Ljt_fcb
    .word Lfcb_5F - Ljt_fcb
    .word Lfcb_60 - Ljt_fcb
    .word Lfcb_61 - Ljt_fcb
    .word Lfcb_62 - Ljt_fcb
    .word Lfcb_63 - Ljt_fcb
    .word Lfcb_64 - Ljt_fcb
    .word Lfcb_65 - Ljt_fcb
    .word Lfcb_66 - Ljt_fcb
    .word Lfcb_67 - Ljt_fcb
    .word Lfcb_68 - Ljt_fcb
    .word Lfcb_69 - Ljt_fcb
    .word Lfcb_6A - Ljt_fcb
    .word Lfcb_6B - Ljt_fcb
    .word Lfcb_6C - Ljt_fcb
    .word Lfcb_6D - Ljt_fcb
    .word Lfcb_6E - Ljt_fcb
    .word Lfcb_6F - Ljt_fcb
    .word Lfcb_70 - Ljt_fcb
    .word Lfcb_71 - Ljt_fcb
    .word Lfcb_72 - Ljt_fcb
    .word Lfcb_73 - Ljt_fcb
    .word Lfcb_74 - Ljt_fcb
    .word Lfcb_75 - Ljt_fcb
    .word Lfcb_76 - Ljt_fcb
    .word Lfcb_77 - Ljt_fcb
    .word Lfcb_78 - Ljt_fcb
    .word Lfcb_79 - Ljt_fcb
    .word Lfcb_7A - Ljt_fcb
    .word Lfcb_7B - Ljt_fcb
    .word Lfcb_7C - Ljt_fcb
    .word Lfcb_7D - Ljt_fcb
    .word Lfcb_7E - Ljt_fcb
    .word Lfcb_7F - Ljt_fcb
    .word Lfcb_80 - Ljt_fcb
    .word Lfcb_81 - Ljt_fcb
    .word Lfcb_82 - Ljt_fcb
    .word Lfcb_83 - Ljt_fcb
    .word Lfcb_84 - Ljt_fcb
    .word Lfcb_85 - Ljt_fcb
    .word Lfcb_86 - Ljt_fcb
    .word Lfcb_87 - Ljt_fcb
    .word Lfcb_88 - Ljt_fcb
    .word Lfcb_89 - Ljt_fcb
    .word Lfcb_8A - Ljt_fcb
    .word Lfcb_8B - Ljt_fcb
    .word Lfcb_8C - Ljt_fcb
    .word Lfcb_8D - Ljt_fcb
    .word Lfcb_8E - Ljt_fcb
    .word Lfcb_8F - Ljt_fcb
    .word Lfcb_90 - Ljt_fcb
    .word Lfcb_91 - Ljt_fcb
    .word Lfcb_92 - Ljt_fcb
    .word Lfcb_93 - Ljt_fcb
    .word Lfcb_94 - Ljt_fcb
    .word Lfcb_95 - Ljt_fcb
    .word Lfcb_96 - Ljt_fcb
    .word Lfcb_97 - Ljt_fcb
    .word Lfcb_98 - Ljt_fcb
    .word Lfcb_99 - Ljt_fcb
    .word Lfcb_9A - Ljt_fcb
    .word Lfcb_9B - Ljt_fcb
    .word Lfcb_9C - Ljt_fcb
    .word Lfcb_9D - Ljt_fcb
    .word Lfcb_9E - Ljt_fcb
    .word Lfcb_9F - Ljt_fcb
    .word Lfcb_A0 - Ljt_fcb
    .word Lfcb_A1 - Ljt_fcb
    .word Lfcb_A2 - Ljt_fcb
    .word Lfcb_A3 - Ljt_fcb
    .word Lfcb_A4 - Ljt_fcb
    .word Lfcb_A5 - Ljt_fcb
    .word Lfcb_A6 - Ljt_fcb
    .word Lfcb_A7 - Ljt_fcb
    .word Lfcb_A8 - Ljt_fcb
    .word Lfcb_A9 - Ljt_fcb
    .word Lfcb_AA - Ljt_fcb
    .word Lfcb_AB - Ljt_fcb
    .word Lfcb_AC - Ljt_fcb
    .word Lfcb_AD - Ljt_fcb
    .word Lfcb_AE - Ljt_fcb
    .word Lfcb_AF - Ljt_fcb
    .word Lfcb_B0 - Ljt_fcb
    .word Lfcb_B1 - Ljt_fcb
    .word Lfcb_B2 - Ljt_fcb
    .word Lfcb_B3 - Ljt_fcb
    .word Lfcb_B4 - Ljt_fcb
    .word Lfcb_B5 - Ljt_fcb
    .word Lfcb_B6 - Ljt_fcb
    .word Lfcb_B7 - Ljt_fcb
    .word Lfcb_B8 - Ljt_fcb
    .word Lfcb_B9 - Ljt_fcb
    .word Lfcb_BA - Ljt_fcb
    .word Lfcb_BB - Ljt_fcb
    .word Lfcb_BC - Ljt_fcb
    .word Lfcb_BD - Ljt_fcb
    .word Lfcb_BE - Ljt_fcb
    .word Lfcb_BF - Ljt_fcb
    .word Lfcb_C0 - Ljt_fcb
    .word Lfcb_C1 - Ljt_fcb
    .word Lfcb_C2 - Ljt_fcb
    .word Lfcb_C3 - Ljt_fcb
    .word Lfcb_C4 - Ljt_fcb
    .word Lfcb_C5 - Ljt_fcb
    .word Lfcb_C6 - Ljt_fcb
    .word Lfcb_C7 - Ljt_fcb
    .word Lfcb_C8 - Ljt_fcb
    .word Lfcb_C9 - Ljt_fcb
    .word Lfcb_CA - Ljt_fcb
    .word Lfcb_CB - Ljt_fcb
    .word Lfcb_CC - Ljt_fcb
    .word Lfcb_CD - Ljt_fcb
    .word Lfcb_CE - Ljt_fcb
    .word Lfcb_CF - Ljt_fcb
    .word Lfcb_D0 - Ljt_fcb
    .word Lfcb_D1 - Ljt_fcb
    .word Lfcb_D2 - Ljt_fcb
    .word Lfcb_D3 - Ljt_fcb
    .word Lfcb_D4 - Ljt_fcb
    .word Lfcb_D5 - Ljt_fcb
    .word Lfcb_D6 - Ljt_fcb
    .word Lfcb_D7 - Ljt_fcb
    .word Lfcb_D8 - Ljt_fcb
    .word Lfcb_D9 - Ljt_fcb
    .word Lfcb_DA - Ljt_fcb
    .word Lfcb_DB - Ljt_fcb
    .word Lfcb_DC - Ljt_fcb
    .word Lfcb_DD - Ljt_fcb
    .word Lfcb_DE - Ljt_fcb
    .word Lfcb_DF - Ljt_fcb
    .word Lfcb_E0 - Ljt_fcb
    .word Lfcb_E1 - Ljt_fcb
    .word Lfcb_E2 - Ljt_fcb
    .word Lfcb_E3 - Ljt_fcb
    .word Lfcb_E4 - Ljt_fcb
    .word Lfcb_E5 - Ljt_fcb
    .word Lfcb_E6 - Ljt_fcb
    .word Lfcb_E7 - Ljt_fcb
    .word Lfcb_E8 - Ljt_fcb
    .word Lfcb_E9 - Ljt_fcb
    .word Lfcb_EA - Ljt_fcb
    .word Lfcb_EB - Ljt_fcb
    .word Lfcb_EC - Ljt_fcb
    .word Lfcb_ED - Ljt_fcb
    .word Lfcb_EE - Ljt_fcb
    .word Lfcb_EF - Ljt_fcb
    .word Lfcb_F0 - Ljt_fcb
    .word Lfcb_F1 - Ljt_fcb
    .word Lfcb_F2 - Ljt_fcb
    .word Lfcb_F3 - Ljt_fcb
    .word Lfcb_F4 - Ljt_fcb
    .word Lfcb_F5 - Ljt_fcb
    .word Lfcb_F6 - Ljt_fcb
    .word Lfcb_F7 - Ljt_fcb
    .word Lfcb_F8 - Ljt_fcb
    .word Lfcb_F9 - Ljt_fcb
    .word Lfcb_FA - Ljt_fcb
    .word Lfcb_FB - Ljt_fcb
    .word Lfcb_FC - Ljt_fcb
    .word Lfcb_FD - Ljt_fcb
    .word Lfcb_FE - Ljt_fcb
    .word Lfcb_FF - Ljt_fcb
    .p2align 2
Ljt_ccb:
    .word Lccb_00 - Ljt_ccb
    .word Lccb_01 - Ljt_ccb
    .word Lccb_02 - Ljt_ccb
    .word Lccb_03 - Ljt_ccb
    .word Lccb_04 - Ljt_ccb
    .word Lccb_05 - Ljt_ccb
    .word Lccb_06 - Ljt_ccb
    .word Lccb_07 - Ljt_ccb
    .word Lccb_08 - Ljt_ccb
    .word Lccb_09 - Ljt_ccb
    .word Lccb_0A - Ljt_ccb
    .word Lccb_0B - Ljt_ccb
    .word Lccb_0C - Ljt_ccb
    .word Lccb_0D - Ljt_ccb
    .word Lccb_0E - Ljt_ccb
    .word Lccb_0F - Ljt_ccb
    .word Lccb_10 - Ljt_ccb
    .word Lccb_11 - Ljt_ccb
    .word Lccb_12 - Ljt_ccb
    .word Lccb_13 - Ljt_ccb
    .word Lccb_14 - Ljt_ccb
    .word Lccb_15 - Ljt_ccb
    .word Lccb_16 - Ljt_ccb
    .word Lccb_17 - Ljt_ccb
    .word Lccb_18 - Ljt_ccb
    .word Lccb_19 - Ljt_ccb
    .word Lccb_1A - Ljt_ccb
    .word Lccb_1B - Ljt_ccb
    .word Lccb_1C - Ljt_ccb
    .word Lccb_1D - Ljt_ccb
    .word Lccb_1E - Ljt_ccb
    .word Lccb_1F - Ljt_ccb
    .word Lccb_20 - Ljt_ccb
    .word Lccb_21 - Ljt_ccb
    .word Lccb_22 - Ljt_ccb
    .word Lccb_23 - Ljt_ccb
    .word Lccb_24 - Ljt_ccb
    .word Lccb_25 - Ljt_ccb
    .word Lccb_26 - Ljt_ccb
    .word Lccb_27 - Ljt_ccb
    .word Lccb_28 - Ljt_ccb
    .word Lccb_29 - Ljt_ccb
    .word Lccb_2A - Ljt_ccb
    .word Lccb_2B - Ljt_ccb
    .word Lccb_2C - Ljt_ccb
    .word Lccb_2D - Ljt_ccb
    .word Lccb_2E - Ljt_ccb
    .word Lccb_2F - Ljt_ccb
    .word Lccb_30 - Ljt_ccb
    .word Lccb_31 - Ljt_ccb
    .word Lccb_32 - Ljt_ccb
    .word Lccb_33 - Ljt_ccb
    .word Lccb_34 - Ljt_ccb
    .word Lccb_35 - Ljt_ccb
    .word Lccb_36 - Ljt_ccb
    .word Lccb_37 - Ljt_ccb
    .word Lccb_38 - Ljt_ccb
    .word Lccb_39 - Ljt_ccb
    .word Lccb_3A - Ljt_ccb
    .word Lccb_3B - Ljt_ccb
    .word Lccb_3C - Ljt_ccb
    .word Lccb_3D - Ljt_ccb
    .word Lccb_3E - Ljt_ccb
    .word Lccb_3F - Ljt_ccb
    .word Lccb_40 - Ljt_ccb
    .word Lccb_41 - Ljt_ccb
    .word Lccb_42 - Ljt_ccb
    .word Lccb_43 - Ljt_ccb
    .word Lccb_44 - Ljt_ccb
    .word Lccb_45 - Ljt_ccb
    .word Lccb_46 - Ljt_ccb
    .word Lccb_47 - Ljt_ccb
    .word Lccb_48 - Ljt_ccb
    .word Lccb_49 - Ljt_ccb
    .word Lccb_4A - Ljt_ccb
    .word Lccb_4B - Ljt_ccb
    .word Lccb_4C - Ljt_ccb
    .word Lccb_4D - Ljt_ccb
    .word Lccb_4E - Ljt_ccb
    .word Lccb_4F - Ljt_ccb
    .word Lccb_50 - Ljt_ccb
    .word Lccb_51 - Ljt_ccb
    .word Lccb_52 - Ljt_ccb
    .word Lccb_53 - Ljt_ccb
    .word Lccb_54 - Ljt_ccb
    .word Lccb_55 - Ljt_ccb
    .word Lccb_56 - Ljt_ccb
    .word Lccb_57 - Ljt_ccb
    .word Lccb_58 - Ljt_ccb
    .word Lccb_59 - Ljt_ccb
    .word Lccb_5A - Ljt_ccb
    .word Lccb_5B - Ljt_ccb
    .word Lccb_5C - Ljt_ccb
    .word Lccb_5D - Ljt_ccb
    .word Lccb_5E - Ljt_ccb
    .word Lccb_5F - Ljt_ccb
    .word Lccb_60 - Ljt_ccb
    .word Lccb_61 - Ljt_ccb
    .word Lccb_62 - Ljt_ccb
    .word Lccb_63 - Ljt_ccb
    .word Lccb_64 - Ljt_ccb
    .word Lccb_65 - Ljt_ccb
    .word Lccb_66 - Ljt_ccb
    .word Lccb_67 - Ljt_ccb
    .word Lccb_68 - Ljt_ccb
    .word Lccb_69 - Ljt_ccb
    .word Lccb_6A - Ljt_ccb
    .word Lccb_6B - Ljt_ccb
    .word Lccb_6C - Ljt_ccb
    .word Lccb_6D - Ljt_ccb
    .word Lccb_6E - Ljt_ccb
    .word Lccb_6F - Ljt_ccb
    .word Lccb_70 - Ljt_ccb
    .word Lccb_71 - Ljt_ccb
    .word Lccb_72 - Ljt_ccb
    .word Lccb_73 - Ljt_ccb
    .word Lccb_74 - Ljt_ccb
    .word Lccb_75 - Ljt_ccb
    .word Lccb_76 - Ljt_ccb
    .word Lccb_77 - Ljt_ccb
    .word Lccb_78 - Ljt_ccb
    .word Lccb_79 - Ljt_ccb
    .word Lccb_7A - Ljt_ccb
    .word Lccb_7B - Ljt_ccb
    .word Lccb_7C - Ljt_ccb
    .word Lccb_7D - Ljt_ccb
    .word Lccb_7E - Ljt_ccb
    .word Lccb_7F - Ljt_ccb
    .word Lccb_80 - Ljt_ccb
    .word Lccb_81 - Ljt_ccb
    .word Lccb_82 - Ljt_ccb
    .word Lccb_83 - Ljt_ccb
    .word Lccb_84 - Ljt_ccb
    .word Lccb_85 - Ljt_ccb
    .word Lccb_86 - Ljt_ccb
    .word Lccb_87 - Ljt_ccb
    .word Lccb_88 - Ljt_ccb
    .word Lccb_89 - Ljt_ccb
    .word Lccb_8A - Ljt_ccb
    .word Lccb_8B - Ljt_ccb
    .word Lccb_8C - Ljt_ccb
    .word Lccb_8D - Ljt_ccb
    .word Lccb_8E - Ljt_ccb
    .word Lccb_8F - Ljt_ccb
    .word Lccb_90 - Ljt_ccb
    .word Lccb_91 - Ljt_ccb
    .word Lccb_92 - Ljt_ccb
    .word Lccb_93 - Ljt_ccb
    .word Lccb_94 - Ljt_ccb
    .word Lccb_95 - Ljt_ccb
    .word Lccb_96 - Ljt_ccb
    .word Lccb_97 - Ljt_ccb
    .word Lccb_98 - Ljt_ccb
    .word Lccb_99 - Ljt_ccb
    .word Lccb_9A - Ljt_ccb
    .word Lccb_9B - Ljt_ccb
    .word Lccb_9C - Ljt_ccb
    .word Lccb_9D - Ljt_ccb
    .word Lccb_9E - Ljt_ccb
    .word Lccb_9F - Ljt_ccb
    .word Lccb_A0 - Ljt_ccb
    .word Lccb_A1 - Ljt_ccb
    .word Lccb_A2 - Ljt_ccb
    .word Lccb_A3 - Ljt_ccb
    .word Lccb_A4 - Ljt_ccb
    .word Lccb_A5 - Ljt_ccb
    .word Lccb_A6 - Ljt_ccb
    .word Lccb_A7 - Ljt_ccb
    .word Lccb_A8 - Ljt_ccb
    .word Lccb_A9 - Ljt_ccb
    .word Lccb_AA - Ljt_ccb
    .word Lccb_AB - Ljt_ccb
    .word Lccb_AC - Ljt_ccb
    .word Lccb_AD - Ljt_ccb
    .word Lccb_AE - Ljt_ccb
    .word Lccb_AF - Ljt_ccb
    .word Lccb_B0 - Ljt_ccb
    .word Lccb_B1 - Ljt_ccb
    .word Lccb_B2 - Ljt_ccb
    .word Lccb_B3 - Ljt_ccb
    .word Lccb_B4 - Ljt_ccb
    .word Lccb_B5 - Ljt_ccb
    .word Lccb_B6 - Ljt_ccb
    .word Lccb_B7 - Ljt_ccb
    .word Lccb_B8 - Ljt_ccb
    .word Lccb_B9 - Ljt_ccb
    .word Lccb_BA - Ljt_ccb
    .word Lccb_BB - Ljt_ccb
    .word Lccb_BC - Ljt_ccb
    .word Lccb_BD - Ljt_ccb
    .word Lccb_BE - Ljt_ccb
    .word Lccb_BF - Ljt_ccb
    .word Lccb_C0 - Ljt_ccb
    .word Lccb_C1 - Ljt_ccb
    .word Lccb_C2 - Ljt_ccb
    .word Lccb_C3 - Ljt_ccb
    .word Lccb_C4 - Ljt_ccb
    .word Lccb_C5 - Ljt_ccb
    .word Lccb_C6 - Ljt_ccb
    .word Lccb_C7 - Ljt_ccb
    .word Lccb_C8 - Ljt_ccb
    .word Lccb_C9 - Ljt_ccb
    .word Lccb_CA - Ljt_ccb
    .word Lccb_CB - Ljt_ccb
    .word Lccb_CC - Ljt_ccb
    .word Lccb_CD - Ljt_ccb
    .word Lccb_CE - Ljt_ccb
    .word Lccb_CF - Ljt_ccb
    .word Lccb_D0 - Ljt_ccb
    .word Lccb_D1 - Ljt_ccb
    .word Lccb_D2 - Ljt_ccb
    .word Lccb_D3 - Ljt_ccb
    .word Lccb_D4 - Ljt_ccb
    .word Lccb_D5 - Ljt_ccb
    .word Lccb_D6 - Ljt_ccb
    .word Lccb_D7 - Ljt_ccb
    .word Lccb_D8 - Ljt_ccb
    .word Lccb_D9 - Ljt_ccb
    .word Lccb_DA - Ljt_ccb
    .word Lccb_DB - Ljt_ccb
    .word Lccb_DC - Ljt_ccb
    .word Lccb_DD - Ljt_ccb
    .word Lccb_DE - Ljt_ccb
    .word Lccb_DF - Ljt_ccb
    .word Lccb_E0 - Ljt_ccb
    .word Lccb_E1 - Ljt_ccb
    .word Lccb_E2 - Ljt_ccb
    .word Lccb_E3 - Ljt_ccb
    .word Lccb_E4 - Ljt_ccb
    .word Lccb_E5 - Ljt_ccb
    .word Lccb_E6 - Ljt_ccb
    .word Lccb_E7 - Ljt_ccb
    .word Lccb_E8 - Ljt_ccb
    .word Lccb_E9 - Ljt_ccb
    .word Lccb_EA - Ljt_ccb
    .word Lccb_EB - Ljt_ccb
    .word Lccb_EC - Ljt_ccb
    .word Lccb_ED - Ljt_ccb
    .word Lccb_EE - Ljt_ccb
    .word Lccb_EF - Ljt_ccb
    .word Lccb_F0 - Ljt_ccb
    .word Lccb_F1 - Ljt_ccb
    .word Lccb_F2 - Ljt_ccb
    .word Lccb_F3 - Ljt_ccb
    .word Lccb_F4 - Ljt_ccb
    .word Lccb_F5 - Ljt_ccb
    .word Lccb_F6 - Ljt_ccb
    .word Lccb_F7 - Ljt_ccb
    .word Lccb_F8 - Ljt_ccb
    .word Lccb_F9 - Ljt_ccb
    .word Lccb_FA - Ljt_ccb
    .word Lccb_FB - Ljt_ccb
    .word Lccb_FC - Ljt_ccb
    .word Lccb_FD - Ljt_ccb
    .word Lccb_FE - Ljt_ccb
    .word Lccb_FF - Ljt_ccb

#ifndef __APPLE__
    .section .note.GNU-stack,"",%progbits
#endif
