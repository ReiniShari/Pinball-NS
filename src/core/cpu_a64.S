// cpu_a64.S - the fast interpreter of the SM83 for ARM64 (Android), written by
// tools/gencpu.c from its description of the instructions: do not edit, see that file.
// int gbc_cpu_run(GBC *g, int64_t *budget): see gbc_exec_asm (src/core/gbc_exec.c).

    .text
    .p2align 4
    .globl gbc_cpu_run
    .hidden gbc_cpu_run
    .type gbc_cpu_run, %function
gbc_cpu_run:
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
    add x20, x20, #2944
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
    bl gbc_read
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
    bl gbc_asm_write
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
    bl gbc_asm_tick
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
    bl gbc_asm_tick
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
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L70
L71:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L68:
    bl Lrd_slow
    b L69
L70:
    mov w9, w24
    bl Lrd_slow
    b L71
    .p2align 4
Lf_11:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L72
L73:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L74
L75:
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
    cbz x10, L76
L77:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L72:
    bl Lrd_slow
    b L73
L74:
    bl Lrd_slow
    b L75
L76:
    mov w9, w24
    bl Lrd_slow
    b L77
    .p2align 4
Lf_12:
    mov w9, w13
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L78
    strb w26, [x10, w9, uxtw]
L79:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L80
L81:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L78:
    mov w0, w26
    bl Lwr_slow
    b L79
L80:
    mov w9, w24
    bl Lrd_slow
    b L81
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
    cbz x10, L82
L83:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L82:
    mov w9, w24
    bl Lrd_slow
    b L83
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
    cbz x10, L84
L85:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L84:
    mov w9, w24
    bl Lrd_slow
    b L85
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
    cbz x10, L86
L87:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L86:
    mov w9, w24
    bl Lrd_slow
    b L87
    .p2align 4
Lf_16:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L88
L89:
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
    cbz x10, L90
L91:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L88:
    bl Lrd_slow
    b L89
L90:
    mov w9, w24
    bl Lrd_slow
    b L91
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
    cbz x10, L92
L93:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L92:
    mov w9, w24
    bl Lrd_slow
    b L93
    .p2align 4
Lf_18:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L94
L95:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    sxtb w0, w11
    add w24, w24, w0
    and w24, w24, #0xFFFF
    add x21, x21, #4
L96:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L97
L98:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L94:
    bl Lrd_slow
    b L95
L97:
    mov w9, w24
    bl Lrd_slow
    b L98
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
    cbz x10, L99
L100:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L99:
    mov w9, w24
    bl Lrd_slow
    b L100
    .p2align 4
Lf_1A:
    mov w9, w13
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L101
L102:
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
    cbz x10, L103
L104:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L101:
    bl Lrd_slow
    b L102
L103:
    mov w9, w24
    bl Lrd_slow
    b L104
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
    cbz x10, L105
L106:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L105:
    mov w9, w24
    bl Lrd_slow
    b L106
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
    cbz x10, L107
L108:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L107:
    mov w9, w24
    bl Lrd_slow
    b L108
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
    cbz x10, L109
L110:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L109:
    mov w9, w24
    bl Lrd_slow
    b L110
    .p2align 4
Lf_1E:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L111
L112:
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
    cbz x10, L113
L114:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L111:
    bl Lrd_slow
    b L112
L113:
    mov w9, w24
    bl Lrd_slow
    b L114
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
    cbz x10, L115
L116:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L115:
    mov w9, w24
    bl Lrd_slow
    b L116
    .p2align 4
Lf_20:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L117
L118:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    tbnz w27, #7, L119
    sxtb w0, w11
    add w24, w24, w0
    and w24, w24, #0xFFFF
    add x21, x21, #4
    cmn w0, #8
    b.eq L120
L121:
L119:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L122
L123:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L117:
    bl Lrd_slow
    b L118
L120:
    bl Lcopy
    b L121
L122:
    mov w9, w24
    bl Lrd_slow
    b L123
    .p2align 4
Lf_21:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L124
L125:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L126
L127:
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
    cbz x10, L128
L129:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L124:
    bl Lrd_slow
    b L125
L126:
    bl Lrd_slow
    b L127
L128:
    mov w9, w24
    bl Lrd_slow
    b L129
    .p2align 4
Lf_22:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L130
    strb w26, [x10, w9, uxtw]
L131:
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
    cbz x10, L132
L133:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L130:
    mov w0, w26
    bl Lwr_slow
    b L131
L132:
    mov w9, w24
    bl Lrd_slow
    b L133
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
    cbz x10, L134
L135:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L134:
    mov w9, w24
    bl Lrd_slow
    b L135
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
    cbz x10, L136
L137:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L136:
    mov w9, w24
    bl Lrd_slow
    b L137
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
    cbz x10, L138
L139:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L138:
    mov w9, w24
    bl Lrd_slow
    b L139
    .p2align 4
Lf_26:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L140
L141:
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
    cbz x10, L142
L143:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L140:
    bl Lrd_slow
    b L141
L142:
    mov w9, w24
    bl Lrd_slow
    b L143
    .p2align 4
Lf_27:
    mov w0, w26
    ubfx w1, w27, #4, #1
    tbz w27, #6, L144
    tbz w27, #5, L145
    sub w0, w0, #6
L145:
    cbz w1, L149
    sub w0, w0, #0x60
    b L149
L144:
    cbnz w1, L146
    cmp w0, #0x99
    b.ls L147
L146:
    add w0, w0, #0x60
    mov w1, #1
L147:
    tbnz w27, #5, L148
    and w2, w0, #0xF
    cmp w2, #9
    b.ls L149
L148:
    add w0, w0, #6
L149:
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
    cbz x10, L151
L152:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L151:
    mov w9, w24
    bl Lrd_slow
    b L152
    .p2align 4
Lf_28:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L153
L154:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    tbz w27, #7, L155
    sxtb w0, w11
    add w24, w24, w0
    and w24, w24, #0xFFFF
    add x21, x21, #4
    cmn w0, #4
    b.eq L156
L157:
L155:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L158
L159:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L153:
    bl Lrd_slow
    b L154
L156:
    bl Lidle
    b L157
L158:
    mov w9, w24
    bl Lrd_slow
    b L159
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
    cbz x10, L160
L161:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L160:
    mov w9, w24
    bl Lrd_slow
    b L161
    .p2align 4
Lf_2A:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L162
L163:
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
    cbz x10, L164
L165:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L162:
    bl Lrd_slow
    b L163
L164:
    mov w9, w24
    bl Lrd_slow
    b L165
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
    cbz x10, L166
L167:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L166:
    mov w9, w24
    bl Lrd_slow
    b L167
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
    cbz x10, L168
L169:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L168:
    mov w9, w24
    bl Lrd_slow
    b L169
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
    cbz x10, L170
L171:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L170:
    mov w9, w24
    bl Lrd_slow
    b L171
    .p2align 4
Lf_2E:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L172
L173:
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
    cbz x10, L174
L175:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L172:
    bl Lrd_slow
    b L173
L174:
    mov w9, w24
    bl Lrd_slow
    b L175
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
    cbz x10, L176
L177:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L176:
    mov w9, w24
    bl Lrd_slow
    b L177
    .p2align 4
Lf_30:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L178
L179:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    tbnz w27, #4, L180
    sxtb w0, w11
    add w24, w24, w0
    and w24, w24, #0xFFFF
    add x21, x21, #4
L180:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L181
L182:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L178:
    bl Lrd_slow
    b L179
L181:
    mov w9, w24
    bl Lrd_slow
    b L182
    .p2align 4
Lf_31:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L183
L184:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L185
L186:
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
    cbz x10, L187
L188:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L183:
    bl Lrd_slow
    b L184
L185:
    bl Lrd_slow
    b L186
L187:
    mov w9, w24
    bl Lrd_slow
    b L188
    .p2align 4
Lf_32:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L189
    strb w26, [x10, w9, uxtw]
L190:
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
    cbz x10, L191
L192:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L189:
    mov w0, w26
    bl Lwr_slow
    b L190
L191:
    mov w9, w24
    bl Lrd_slow
    b L192
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
    cbz x10, L193
L194:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L193:
    mov w9, w24
    bl Lrd_slow
    b L194
    .p2align 4
Lf_34:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L195
L196:
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
    cbz x10, L197
    strb w11, [x10, w9, uxtw]
L198:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L199
L200:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L195:
    bl Lrd_slow
    b L196
L197:
    mov w0, w11
    bl Lwr_slow
    b L198
L199:
    mov w9, w24
    bl Lrd_slow
    b L200
    .p2align 4
Lf_35:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L201
L202:
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
    cbz x10, L203
    strb w11, [x10, w9, uxtw]
L204:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L205
L206:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L201:
    bl Lrd_slow
    b L202
L203:
    mov w0, w11
    bl Lwr_slow
    b L204
L205:
    mov w9, w24
    bl Lrd_slow
    b L206
    .p2align 4
Lf_36:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L207
L208:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L209
    strb w11, [x10, w9, uxtw]
L210:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L211
L212:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L207:
    bl Lrd_slow
    b L208
L209:
    mov w0, w11
    bl Lwr_slow
    b L210
L211:
    mov w9, w24
    bl Lrd_slow
    b L212
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
    cbz x10, L213
L214:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L213:
    mov w9, w24
    bl Lrd_slow
    b L214
    .p2align 4
Lf_38:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L215
L216:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    tbz w27, #4, L217
    sxtb w0, w11
    add w24, w24, w0
    and w24, w24, #0xFFFF
    add x21, x21, #4
L217:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L218
L219:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L215:
    bl Lrd_slow
    b L216
L218:
    mov w9, w24
    bl Lrd_slow
    b L219
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
    cbz x10, L220
L221:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L220:
    mov w9, w24
    bl Lrd_slow
    b L221
    .p2align 4
Lf_3A:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L222
L223:
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
    cbz x10, L224
L225:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L222:
    bl Lrd_slow
    b L223
L224:
    mov w9, w24
    bl Lrd_slow
    b L225
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
    cbz x10, L226
L227:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L226:
    mov w9, w24
    bl Lrd_slow
    b L227
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
    cbz x10, L228
L229:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L228:
    mov w9, w24
    bl Lrd_slow
    b L229
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
    cbz x10, L230
L231:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L230:
    mov w9, w24
    bl Lrd_slow
    b L231
    .p2align 4
Lf_3E:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L232
L233:
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
    cbz x10, L234
L235:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L232:
    bl Lrd_slow
    b L233
L234:
    mov w9, w24
    bl Lrd_slow
    b L235
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
    cbz x10, L236
L237:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L236:
    mov w9, w24
    bl Lrd_slow
    b L237
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
    cbz x10, L238
L239:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L238:
    mov w9, w24
    bl Lrd_slow
    b L239
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
    cbz x10, L240
L241:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L240:
    mov w9, w24
    bl Lrd_slow
    b L241
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
    cbz x10, L242
L243:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L242:
    mov w9, w24
    bl Lrd_slow
    b L243
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
    cbz x10, L244
L245:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L244:
    mov w9, w24
    bl Lrd_slow
    b L245
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
    cbz x10, L246
L247:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L246:
    mov w9, w24
    bl Lrd_slow
    b L247
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
    cbz x10, L248
L249:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L248:
    mov w9, w24
    bl Lrd_slow
    b L249
    .p2align 4
Lf_46:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L250
L251:
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
    cbz x10, L252
L253:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L250:
    bl Lrd_slow
    b L251
L252:
    mov w9, w24
    bl Lrd_slow
    b L253
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
    cbz x10, L254
L255:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L254:
    mov w9, w24
    bl Lrd_slow
    b L255
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
    cbz x10, L256
L257:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L256:
    mov w9, w24
    bl Lrd_slow
    b L257
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
    cbz x10, L258
L259:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L258:
    mov w9, w24
    bl Lrd_slow
    b L259
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
    cbz x10, L260
L261:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L260:
    mov w9, w24
    bl Lrd_slow
    b L261
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
    cbz x10, L262
L263:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L262:
    mov w9, w24
    bl Lrd_slow
    b L263
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
    cbz x10, L264
L265:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L264:
    mov w9, w24
    bl Lrd_slow
    b L265
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
    cbz x10, L266
L267:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L266:
    mov w9, w24
    bl Lrd_slow
    b L267
    .p2align 4
Lf_4E:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L268
L269:
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
    cbz x10, L270
L271:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L268:
    bl Lrd_slow
    b L269
L270:
    mov w9, w24
    bl Lrd_slow
    b L271
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
    cbz x10, L272
L273:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L272:
    mov w9, w24
    bl Lrd_slow
    b L273
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
    cbz x10, L274
L275:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L274:
    mov w9, w24
    bl Lrd_slow
    b L275
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
    cbz x10, L276
L277:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L276:
    mov w9, w24
    bl Lrd_slow
    b L277
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
    cbz x10, L278
L279:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L278:
    mov w9, w24
    bl Lrd_slow
    b L279
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
    cbz x10, L280
L281:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L280:
    mov w9, w24
    bl Lrd_slow
    b L281
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
    cbz x10, L282
L283:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L282:
    mov w9, w24
    bl Lrd_slow
    b L283
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
    cbz x10, L284
L285:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L284:
    mov w9, w24
    bl Lrd_slow
    b L285
    .p2align 4
Lf_56:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L286
L287:
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
    cbz x10, L288
L289:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L286:
    bl Lrd_slow
    b L287
L288:
    mov w9, w24
    bl Lrd_slow
    b L289
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
    cbz x10, L290
L291:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L290:
    mov w9, w24
    bl Lrd_slow
    b L291
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
    cbz x10, L292
L293:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L292:
    mov w9, w24
    bl Lrd_slow
    b L293
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
    cbz x10, L294
L295:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L294:
    mov w9, w24
    bl Lrd_slow
    b L295
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
    cbz x10, L296
L297:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L296:
    mov w9, w24
    bl Lrd_slow
    b L297
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
    cbz x10, L298
L299:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L298:
    mov w9, w24
    bl Lrd_slow
    b L299
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
    cbz x10, L300
L301:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L300:
    mov w9, w24
    bl Lrd_slow
    b L301
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
    cbz x10, L302
L303:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L302:
    mov w9, w24
    bl Lrd_slow
    b L303
    .p2align 4
Lf_5E:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L304
L305:
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
    cbz x10, L306
L307:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L304:
    bl Lrd_slow
    b L305
L306:
    mov w9, w24
    bl Lrd_slow
    b L307
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
    cbz x10, L308
L309:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L308:
    mov w9, w24
    bl Lrd_slow
    b L309
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
    cbz x10, L310
L311:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L310:
    mov w9, w24
    bl Lrd_slow
    b L311
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
    cbz x10, L312
L313:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L312:
    mov w9, w24
    bl Lrd_slow
    b L313
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
    cbz x10, L314
L315:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L314:
    mov w9, w24
    bl Lrd_slow
    b L315
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
    cbz x10, L316
L317:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L316:
    mov w9, w24
    bl Lrd_slow
    b L317
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
    cbz x10, L318
L319:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L318:
    mov w9, w24
    bl Lrd_slow
    b L319
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
    cbz x10, L320
L321:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L320:
    mov w9, w24
    bl Lrd_slow
    b L321
    .p2align 4
Lf_66:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L322
L323:
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
    cbz x10, L324
L325:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L322:
    bl Lrd_slow
    b L323
L324:
    mov w9, w24
    bl Lrd_slow
    b L325
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
    cbz x10, L326
L327:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L326:
    mov w9, w24
    bl Lrd_slow
    b L327
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
    cbz x10, L328
L329:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L328:
    mov w9, w24
    bl Lrd_slow
    b L329
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
    cbz x10, L330
L331:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L330:
    mov w9, w24
    bl Lrd_slow
    b L331
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
    cbz x10, L332
L333:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L332:
    mov w9, w24
    bl Lrd_slow
    b L333
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
    cbz x10, L334
L335:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L334:
    mov w9, w24
    bl Lrd_slow
    b L335
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
    cbz x10, L336
L337:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L336:
    mov w9, w24
    bl Lrd_slow
    b L337
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
    cbz x10, L338
L339:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L338:
    mov w9, w24
    bl Lrd_slow
    b L339
    .p2align 4
Lf_6E:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L340
L341:
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
    cbz x10, L342
L343:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L340:
    bl Lrd_slow
    b L341
L342:
    mov w9, w24
    bl Lrd_slow
    b L343
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
    cbz x10, L344
L345:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L344:
    mov w9, w24
    bl Lrd_slow
    b L345
    .p2align 4
Lf_70:
    mov w9, w14
    add x21, x21, #4
    lsr w0, w28, #8
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L346
    strb w0, [x10, w9, uxtw]
L347:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L348
L349:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L346:
    bl Lwr_slow
    b L347
L348:
    mov w9, w24
    bl Lrd_slow
    b L349
    .p2align 4
Lf_71:
    mov w9, w14
    add x21, x21, #4
    and w0, w28, #0xFF
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L350
    strb w0, [x10, w9, uxtw]
L351:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L352
L353:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L350:
    bl Lwr_slow
    b L351
L352:
    mov w9, w24
    bl Lrd_slow
    b L353
    .p2align 4
Lf_72:
    mov w9, w14
    add x21, x21, #4
    lsr w0, w13, #8
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L354
    strb w0, [x10, w9, uxtw]
L355:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L356
L357:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L354:
    bl Lwr_slow
    b L355
L356:
    mov w9, w24
    bl Lrd_slow
    b L357
    .p2align 4
Lf_73:
    mov w9, w14
    add x21, x21, #4
    and w0, w13, #0xFF
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L358
    strb w0, [x10, w9, uxtw]
L359:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L360
L361:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L358:
    bl Lwr_slow
    b L359
L360:
    mov w9, w24
    bl Lrd_slow
    b L361
    .p2align 4
Lf_74:
    mov w9, w14
    add x21, x21, #4
    lsr w0, w14, #8
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L362
    strb w0, [x10, w9, uxtw]
L363:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L364
L365:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L362:
    bl Lwr_slow
    b L363
L364:
    mov w9, w24
    bl Lrd_slow
    b L365
    .p2align 4
Lf_75:
    mov w9, w14
    add x21, x21, #4
    and w0, w14, #0xFF
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L366
    strb w0, [x10, w9, uxtw]
L367:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L368
L369:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L366:
    bl Lwr_slow
    b L367
L368:
    mov w9, w24
    bl Lrd_slow
    b L369
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
    cbnz w17, L370
    str x21, [x19, #40]
    ldrh w17, [x20, #368]
    add w17, w17, w21
    add x16, x19, #16, lsl #12
    strh w17, [x16, #322]
L370:
    mov x0, x19
    mov w1, #118
    bl gbc_asm_op
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
    cbz x10, L371
L372:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L371:
    mov w9, w24
    bl Lrd_slow
    b L372
    .p2align 4
Lf_77:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L373
    strb w26, [x10, w9, uxtw]
L374:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L375
L376:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L373:
    mov w0, w26
    bl Lwr_slow
    b L374
L375:
    mov w9, w24
    bl Lrd_slow
    b L376
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
    cbz x10, L377
L378:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L377:
    mov w9, w24
    bl Lrd_slow
    b L378
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
    cbz x10, L379
L380:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L379:
    mov w9, w24
    bl Lrd_slow
    b L380
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
    cbz x10, L381
L382:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L381:
    mov w9, w24
    bl Lrd_slow
    b L382
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
    cbz x10, L383
L384:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L383:
    mov w9, w24
    bl Lrd_slow
    b L384
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
    cbz x10, L385
L386:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L385:
    mov w9, w24
    bl Lrd_slow
    b L386
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
    cbz x10, L387
L388:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L387:
    mov w9, w24
    bl Lrd_slow
    b L388
    .p2align 4
Lf_7E:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L389
L390:
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
    cbz x10, L391
L392:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L389:
    bl Lrd_slow
    b L390
L391:
    mov w9, w24
    bl Lrd_slow
    b L392
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
    cbz x10, L393
L394:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L393:
    mov w9, w24
    bl Lrd_slow
    b L394
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
    cbz x10, L395
L396:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L395:
    mov w9, w24
    bl Lrd_slow
    b L396
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
    cbz x10, L397
L398:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L397:
    mov w9, w24
    bl Lrd_slow
    b L398
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
    cbz x10, L399
L400:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L399:
    mov w9, w24
    bl Lrd_slow
    b L400
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
    cbz x10, L401
L402:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L401:
    mov w9, w24
    bl Lrd_slow
    b L402
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
    cbz x10, L403
L404:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L403:
    mov w9, w24
    bl Lrd_slow
    b L404
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
    cbz x10, L405
L406:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L405:
    mov w9, w24
    bl Lrd_slow
    b L406
    .p2align 4
Lf_86:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L407
L408:
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
    cbz x10, L409
L410:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L407:
    bl Lrd_slow
    b L408
L409:
    mov w9, w24
    bl Lrd_slow
    b L410
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
    cbz x10, L411
L412:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L411:
    mov w9, w24
    bl Lrd_slow
    b L412
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
    cbz x10, L413
L414:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L413:
    mov w9, w24
    bl Lrd_slow
    b L414
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
    cbz x10, L415
L416:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L415:
    mov w9, w24
    bl Lrd_slow
    b L416
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
    cbz x10, L417
L418:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L417:
    mov w9, w24
    bl Lrd_slow
    b L418
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
    cbz x10, L419
L420:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L419:
    mov w9, w24
    bl Lrd_slow
    b L420
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
    cbz x10, L421
L422:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L421:
    mov w9, w24
    bl Lrd_slow
    b L422
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
    cbz x10, L423
L424:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L423:
    mov w9, w24
    bl Lrd_slow
    b L424
    .p2align 4
Lf_8E:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L425
L426:
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
    cbz x10, L427
L428:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L425:
    bl Lrd_slow
    b L426
L427:
    mov w9, w24
    bl Lrd_slow
    b L428
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
    cbz x10, L429
L430:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L429:
    mov w9, w24
    bl Lrd_slow
    b L430
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
    cbz x10, L431
L432:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L431:
    mov w9, w24
    bl Lrd_slow
    b L432
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
    cbz x10, L433
L434:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L433:
    mov w9, w24
    bl Lrd_slow
    b L434
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
    cbz x10, L435
L436:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L435:
    mov w9, w24
    bl Lrd_slow
    b L436
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
    cbz x10, L437
L438:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L437:
    mov w9, w24
    bl Lrd_slow
    b L438
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
    cbz x10, L439
L440:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L439:
    mov w9, w24
    bl Lrd_slow
    b L440
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
    cbz x10, L441
L442:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L441:
    mov w9, w24
    bl Lrd_slow
    b L442
    .p2align 4
Lf_96:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L443
L444:
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
    cbz x10, L445
L446:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L443:
    bl Lrd_slow
    b L444
L445:
    mov w9, w24
    bl Lrd_slow
    b L446
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
    cbz x10, L447
L448:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L447:
    mov w9, w24
    bl Lrd_slow
    b L448
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
    cbz x10, L449
L450:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L449:
    mov w9, w24
    bl Lrd_slow
    b L450
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
    cbz x10, L451
L452:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L451:
    mov w9, w24
    bl Lrd_slow
    b L452
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
    cbz x10, L453
L454:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L453:
    mov w9, w24
    bl Lrd_slow
    b L454
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
    cbz x10, L455
L456:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L455:
    mov w9, w24
    bl Lrd_slow
    b L456
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
    cbz x10, L457
L458:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L457:
    mov w9, w24
    bl Lrd_slow
    b L458
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
    cbz x10, L459
L460:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L459:
    mov w9, w24
    bl Lrd_slow
    b L460
    .p2align 4
Lf_9E:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L461
L462:
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
    cbz x10, L463
L464:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L461:
    bl Lrd_slow
    b L462
L463:
    mov w9, w24
    bl Lrd_slow
    b L464
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
    cbz x10, L465
L466:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L465:
    mov w9, w24
    bl Lrd_slow
    b L466
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
    cbz x10, L467
L468:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L467:
    mov w9, w24
    bl Lrd_slow
    b L468
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
    cbz x10, L469
L470:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L469:
    mov w9, w24
    bl Lrd_slow
    b L470
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
    cbz x10, L471
L472:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L471:
    mov w9, w24
    bl Lrd_slow
    b L472
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
    cbz x10, L473
L474:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L473:
    mov w9, w24
    bl Lrd_slow
    b L474
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
    cbz x10, L475
L476:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L475:
    mov w9, w24
    bl Lrd_slow
    b L476
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
    cbz x10, L477
L478:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L477:
    mov w9, w24
    bl Lrd_slow
    b L478
    .p2align 4
Lf_A6:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L479
L480:
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
    cbz x10, L481
L482:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L479:
    bl Lrd_slow
    b L480
L481:
    mov w9, w24
    bl Lrd_slow
    b L482
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
    cbz x10, L483
L484:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L483:
    mov w9, w24
    bl Lrd_slow
    b L484
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
    cbz x10, L485
L486:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L485:
    mov w9, w24
    bl Lrd_slow
    b L486
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
    cbz x10, L487
L488:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L487:
    mov w9, w24
    bl Lrd_slow
    b L488
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
    cbz x10, L489
L490:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L489:
    mov w9, w24
    bl Lrd_slow
    b L490
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
    cbz x10, L491
L492:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L491:
    mov w9, w24
    bl Lrd_slow
    b L492
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
    cbz x10, L493
L494:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L493:
    mov w9, w24
    bl Lrd_slow
    b L494
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
    cbz x10, L495
L496:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L495:
    mov w9, w24
    bl Lrd_slow
    b L496
    .p2align 4
Lf_AE:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L497
L498:
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
    cbz x10, L499
L500:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L497:
    bl Lrd_slow
    b L498
L499:
    mov w9, w24
    bl Lrd_slow
    b L500
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
    cbz x10, L501
L502:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L501:
    mov w9, w24
    bl Lrd_slow
    b L502
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
    cbz x10, L503
L504:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L503:
    mov w9, w24
    bl Lrd_slow
    b L504
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
    cbz x10, L505
L506:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L505:
    mov w9, w24
    bl Lrd_slow
    b L506
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
    cbz x10, L507
L508:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L507:
    mov w9, w24
    bl Lrd_slow
    b L508
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
    cbz x10, L509
L510:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L509:
    mov w9, w24
    bl Lrd_slow
    b L510
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
    cbz x10, L511
L512:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L511:
    mov w9, w24
    bl Lrd_slow
    b L512
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
    cbz x10, L513
L514:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L513:
    mov w9, w24
    bl Lrd_slow
    b L514
    .p2align 4
Lf_B6:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L515
L516:
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
    cbz x10, L517
L518:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L515:
    bl Lrd_slow
    b L516
L517:
    mov w9, w24
    bl Lrd_slow
    b L518
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
    cbz x10, L519
L520:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L519:
    mov w9, w24
    bl Lrd_slow
    b L520
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
    cbz x10, L521
L522:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L521:
    mov w9, w24
    bl Lrd_slow
    b L522
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
    cbz x10, L523
L524:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L523:
    mov w9, w24
    bl Lrd_slow
    b L524
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
    cbz x10, L525
L526:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L525:
    mov w9, w24
    bl Lrd_slow
    b L526
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
    cbz x10, L527
L528:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L527:
    mov w9, w24
    bl Lrd_slow
    b L528
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
    cbz x10, L529
L530:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L529:
    mov w9, w24
    bl Lrd_slow
    b L530
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
    cbz x10, L531
L532:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L531:
    mov w9, w24
    bl Lrd_slow
    b L532
    .p2align 4
Lf_BE:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L533
L534:
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
    cbz x10, L535
L536:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L533:
    bl Lrd_slow
    b L534
L535:
    mov w9, w24
    bl Lrd_slow
    b L536
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
    cbz x10, L537
L538:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L537:
    mov w9, w24
    bl Lrd_slow
    b L538
    .p2align 4
Lf_C0:
    add x21, x21, #4
    tbnz w27, #7, L539
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L540
L541:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L542
L543:
    ldrb w12, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w24, w12
    add x21, x21, #4
L539:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L544
L545:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L540:
    bl Lrd_slow
    b L541
L542:
    bl Lrd_slow
    b L543
L544:
    mov w9, w24
    bl Lrd_slow
    b L545
    .p2align 4
Lf_C1:
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L546
L547:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L548
L549:
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
    cbz x10, L550
L551:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L546:
    bl Lrd_slow
    b L547
L548:
    bl Lrd_slow
    b L549
L550:
    mov w9, w24
    bl Lrd_slow
    b L551
    .p2align 4
Lf_C2:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L552
L553:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L554
L555:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    tbnz w27, #7, L556
    mov w24, w12
    add x21, x21, #4
L556:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L557
L558:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L552:
    bl Lrd_slow
    b L553
L554:
    bl Lrd_slow
    b L555
L557:
    mov w9, w24
    bl Lrd_slow
    b L558
    .p2align 4
Lf_C3:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L559
L560:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L561
L562:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w24, w12
    add x21, x21, #4
L563:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L564
L565:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L559:
    bl Lrd_slow
    b L560
L561:
    bl Lrd_slow
    b L562
L564:
    mov w9, w24
    bl Lrd_slow
    b L565
    .p2align 4
Lf_C4:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L566
L567:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L568
L569:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    tbnz w27, #7, L570
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
    cbz x10, L571
    strb w11, [x10, w9, uxtw]
L572:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L573
L574:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L575
    strb w12, [x10, w9, uxtw]
L576:
    ldr w24, [sp, #104]
L570:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L577
L578:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L566:
    bl Lrd_slow
    b L567
L568:
    bl Lrd_slow
    b L569
L571:
    mov w0, w11
    bl Lwr_slow
    b L572
L573:
    bl Ltick_slow4
    b L574
L575:
    mov w0, w12
    bl Lwr_slow
    b L576
L577:
    mov w9, w24
    bl Lrd_slow
    b L578
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
    cbz x10, L579
    strb w11, [x10, w9, uxtw]
L580:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L581
L582:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L583
    strb w12, [x10, w9, uxtw]
L584:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L585
L586:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L579:
    mov w0, w11
    bl Lwr_slow
    b L580
L581:
    bl Ltick_slow4
    b L582
L583:
    mov w0, w12
    bl Lwr_slow
    b L584
L585:
    mov w9, w24
    bl Lrd_slow
    b L586
    .p2align 4
Lf_C6:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L587
L588:
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
    cbz x10, L589
L590:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L587:
    bl Lrd_slow
    b L588
L589:
    mov w9, w24
    bl Lrd_slow
    b L590
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
    cbz x10, L591
    strb w11, [x10, w9, uxtw]
L592:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L593
L594:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L595
    strb w12, [x10, w9, uxtw]
L596:
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
    cbz x10, L597
L598:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L591:
    mov w0, w11
    bl Lwr_slow
    b L592
L593:
    bl Ltick_slow4
    b L594
L595:
    mov w0, w12
    bl Lwr_slow
    b L596
L597:
    mov w9, w24
    bl Lrd_slow
    b L598
    .p2align 4
Lf_C8:
    add x21, x21, #4
    tbz w27, #7, L599
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L600
L601:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L602
L603:
    ldrb w12, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w24, w12
    add x21, x21, #4
L599:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L604
L605:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L600:
    bl Lrd_slow
    b L601
L602:
    bl Lrd_slow
    b L603
L604:
    mov w9, w24
    bl Lrd_slow
    b L605
    .p2align 4
Lf_C9:
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L606
L607:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L608
L609:
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
    cbz x10, L610
L611:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L606:
    bl Lrd_slow
    b L607
L608:
    bl Lrd_slow
    b L609
L610:
    mov w9, w24
    bl Lrd_slow
    b L611
    .p2align 4
Lf_CA:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L612
L613:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L614
L615:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    tbz w27, #7, L616
    mov w24, w12
    add x21, x21, #4
L616:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L617
L618:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L612:
    bl Lrd_slow
    b L613
L614:
    bl Lrd_slow
    b L615
L617:
    mov w9, w24
    bl Lrd_slow
    b L618
    .p2align 4
Lf_CB:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L619
L620:
    ldrb w9, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    adr x17, Ljt_fcb
    ldrsw x0, [x17, x9, lsl #2]
    add x17, x17, x0
    br x17
L619:
    bl Lrd_slow
    b L620
    .p2align 4
Lf_CC:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L621
L622:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L623
L624:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    tbz w27, #7, L625
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
    cbz x10, L626
    strb w11, [x10, w9, uxtw]
L627:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L628
L629:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L630
    strb w12, [x10, w9, uxtw]
L631:
    ldr w24, [sp, #104]
L625:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L632
L633:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L621:
    bl Lrd_slow
    b L622
L623:
    bl Lrd_slow
    b L624
L626:
    mov w0, w11
    bl Lwr_slow
    b L627
L628:
    bl Ltick_slow4
    b L629
L630:
    mov w0, w12
    bl Lwr_slow
    b L631
L632:
    mov w9, w24
    bl Lrd_slow
    b L633
    .p2align 4
Lf_CD:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L634
L635:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L636
L637:
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
    cbz x10, L639
    strb w11, [x10, w9, uxtw]
L640:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L641
L642:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L643
    strb w12, [x10, w9, uxtw]
L644:
    ldr w24, [sp, #104]
L638:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L645
L646:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L634:
    bl Lrd_slow
    b L635
L636:
    bl Lrd_slow
    b L637
L639:
    mov w0, w11
    bl Lwr_slow
    b L640
L641:
    bl Ltick_slow4
    b L642
L643:
    mov w0, w12
    bl Lwr_slow
    b L644
L645:
    mov w9, w24
    bl Lrd_slow
    b L646
    .p2align 4
Lf_CE:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L647
L648:
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
    cbz x10, L649
L650:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L647:
    bl Lrd_slow
    b L648
L649:
    mov w9, w24
    bl Lrd_slow
    b L650
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
    cbz x10, L651
    strb w11, [x10, w9, uxtw]
L652:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L653
L654:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L655
    strb w12, [x10, w9, uxtw]
L656:
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
    cbz x10, L657
L658:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L651:
    mov w0, w11
    bl Lwr_slow
    b L652
L653:
    bl Ltick_slow4
    b L654
L655:
    mov w0, w12
    bl Lwr_slow
    b L656
L657:
    mov w9, w24
    bl Lrd_slow
    b L658
    .p2align 4
Lf_D0:
    add x21, x21, #4
    tbnz w27, #4, L659
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L660
L661:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L662
L663:
    ldrb w12, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w24, w12
    add x21, x21, #4
L659:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L664
L665:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L660:
    bl Lrd_slow
    b L661
L662:
    bl Lrd_slow
    b L663
L664:
    mov w9, w24
    bl Lrd_slow
    b L665
    .p2align 4
Lf_D1:
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L666
L667:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L668
L669:
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
    cbz x10, L670
L671:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L666:
    bl Lrd_slow
    b L667
L668:
    bl Lrd_slow
    b L669
L670:
    mov w9, w24
    bl Lrd_slow
    b L671
    .p2align 4
Lf_D2:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L672
L673:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L674
L675:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    tbnz w27, #4, L676
    mov w24, w12
    add x21, x21, #4
L676:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L677
L678:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L672:
    bl Lrd_slow
    b L673
L674:
    bl Lrd_slow
    b L675
L677:
    mov w9, w24
    bl Lrd_slow
    b L678
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
    cbz x10, L679
L680:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L679:
    mov w9, w24
    bl Lrd_slow
    b L680
    .p2align 4
Lf_D4:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L681
L682:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L683
L684:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    tbnz w27, #4, L685
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
    cbz x10, L686
    strb w11, [x10, w9, uxtw]
L687:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L688
L689:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L690
    strb w12, [x10, w9, uxtw]
L691:
    ldr w24, [sp, #104]
L685:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L692
L693:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L681:
    bl Lrd_slow
    b L682
L683:
    bl Lrd_slow
    b L684
L686:
    mov w0, w11
    bl Lwr_slow
    b L687
L688:
    bl Ltick_slow4
    b L689
L690:
    mov w0, w12
    bl Lwr_slow
    b L691
L692:
    mov w9, w24
    bl Lrd_slow
    b L693
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
    cbz x10, L694
    strb w11, [x10, w9, uxtw]
L695:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L696
L697:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L698
    strb w12, [x10, w9, uxtw]
L699:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L700
L701:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L694:
    mov w0, w11
    bl Lwr_slow
    b L695
L696:
    bl Ltick_slow4
    b L697
L698:
    mov w0, w12
    bl Lwr_slow
    b L699
L700:
    mov w9, w24
    bl Lrd_slow
    b L701
    .p2align 4
Lf_D6:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L702
L703:
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
    cbz x10, L704
L705:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L702:
    bl Lrd_slow
    b L703
L704:
    mov w9, w24
    bl Lrd_slow
    b L705
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
    cbz x10, L706
    strb w11, [x10, w9, uxtw]
L707:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L708
L709:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L710
    strb w12, [x10, w9, uxtw]
L711:
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
    cbz x10, L712
L713:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L706:
    mov w0, w11
    bl Lwr_slow
    b L707
L708:
    bl Ltick_slow4
    b L709
L710:
    mov w0, w12
    bl Lwr_slow
    b L711
L712:
    mov w9, w24
    bl Lrd_slow
    b L713
    .p2align 4
Lf_D8:
    add x21, x21, #4
    tbz w27, #4, L714
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L715
L716:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L717
L718:
    ldrb w12, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w24, w12
    add x21, x21, #4
L714:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L719
L720:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L715:
    bl Lrd_slow
    b L716
L717:
    bl Lrd_slow
    b L718
L719:
    mov w9, w24
    bl Lrd_slow
    b L720
    .p2align 4
Lf_D9:
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L721
L722:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L723
L724:
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
    cbnz w17, L725
    str x21, [x19, #40]
    ldrh w17, [x20, #368]
    add w17, w17, w21
    add x16, x19, #16, lsl #12
    strh w17, [x16, #322]
L725:
    mov x0, x19
    mov w1, #217
    bl gbc_asm_op
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
    cbz x10, L726
L727:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L721:
    bl Lrd_slow
    b L722
L723:
    bl Lrd_slow
    b L724
L726:
    mov w9, w24
    bl Lrd_slow
    b L727
    .p2align 4
Lf_DA:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L728
L729:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L730
L731:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    tbz w27, #4, L732
    mov w24, w12
    add x21, x21, #4
L732:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L733
L734:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L728:
    bl Lrd_slow
    b L729
L730:
    bl Lrd_slow
    b L731
L733:
    mov w9, w24
    bl Lrd_slow
    b L734
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
    cbz x10, L735
L736:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L735:
    mov w9, w24
    bl Lrd_slow
    b L736
    .p2align 4
Lf_DC:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L737
L738:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L739
L740:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    tbz w27, #4, L741
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
    cbz x10, L742
    strb w11, [x10, w9, uxtw]
L743:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L744
L745:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L746
    strb w12, [x10, w9, uxtw]
L747:
    ldr w24, [sp, #104]
L741:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L748
L749:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L737:
    bl Lrd_slow
    b L738
L739:
    bl Lrd_slow
    b L740
L742:
    mov w0, w11
    bl Lwr_slow
    b L743
L744:
    bl Ltick_slow4
    b L745
L746:
    mov w0, w12
    bl Lwr_slow
    b L747
L748:
    mov w9, w24
    bl Lrd_slow
    b L749
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
    cbz x10, L750
L751:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L750:
    mov w9, w24
    bl Lrd_slow
    b L751
    .p2align 4
Lf_DE:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L752
L753:
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
    cbz x10, L754
L755:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L752:
    bl Lrd_slow
    b L753
L754:
    mov w9, w24
    bl Lrd_slow
    b L755
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
    cbz x10, L756
    strb w11, [x10, w9, uxtw]
L757:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L758
L759:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L760
    strb w12, [x10, w9, uxtw]
L761:
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
    cbz x10, L762
L763:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L756:
    mov w0, w11
    bl Lwr_slow
    b L757
L758:
    bl Ltick_slow4
    b L759
L760:
    mov w0, w12
    bl Lwr_slow
    b L761
L762:
    mov w9, w24
    bl Lrd_slow
    b L763
    .p2align 4
Lf_E0:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L766
L767:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    cmp w11, #0x80
    b.lo L764
    cmp w11, #0xFF
    b.eq L764
    add x21, x21, #4
    ldr x10, [x20, #272]
    orr w0, w11, #0xFF00
    strb w26, [x10, w0, uxtw]
    b L765
L764:
    mov w9, w11
    orr w9, w9, #0xFF00
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L768
    strb w26, [x10, w9, uxtw]
L769:
L765:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L770
L771:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L766:
    bl Lrd_slow
    b L767
L768:
    mov w0, w26
    bl Lwr_slow
    b L769
L770:
    mov w9, w24
    bl Lrd_slow
    b L771
    .p2align 4
Lf_E1:
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L772
L773:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L774
L775:
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
    cbz x10, L776
L777:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L772:
    bl Lrd_slow
    b L773
L774:
    bl Lrd_slow
    b L775
L776:
    mov w9, w24
    bl Lrd_slow
    b L777
    .p2align 4
Lf_E2:
    and w9, w28, #0xFF
    orr w9, w9, #0xFF00
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L778
    strb w26, [x10, w9, uxtw]
L779:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L780
L781:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L778:
    mov w0, w26
    bl Lwr_slow
    b L779
L780:
    mov w9, w24
    bl Lrd_slow
    b L781
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
    cbz x10, L782
L783:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L782:
    mov w9, w24
    bl Lrd_slow
    b L783
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
    cbz x10, L784
L785:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L784:
    mov w9, w24
    bl Lrd_slow
    b L785
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
    cbz x10, L786
    strb w11, [x10, w9, uxtw]
L787:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L788
L789:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L790
    strb w12, [x10, w9, uxtw]
L791:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L792
L793:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L786:
    mov w0, w11
    bl Lwr_slow
    b L787
L788:
    bl Ltick_slow4
    b L789
L790:
    mov w0, w12
    bl Lwr_slow
    b L791
L792:
    mov w9, w24
    bl Lrd_slow
    b L793
    .p2align 4
Lf_E6:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L794
L795:
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
    cbz x10, L796
L797:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L794:
    bl Lrd_slow
    b L795
L796:
    mov w9, w24
    bl Lrd_slow
    b L797
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
    cbz x10, L798
    strb w11, [x10, w9, uxtw]
L799:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L800
L801:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L802
    strb w12, [x10, w9, uxtw]
L803:
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
    cbz x10, L804
L805:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L798:
    mov w0, w11
    bl Lwr_slow
    b L799
L800:
    bl Ltick_slow4
    b L801
L802:
    mov w0, w12
    bl Lwr_slow
    b L803
L804:
    mov w9, w24
    bl Lrd_slow
    b L805
    .p2align 4
Lf_E8:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L806
L807:
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
    cbz x10, L808
L809:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L806:
    bl Lrd_slow
    b L807
L808:
    mov w9, w24
    bl Lrd_slow
    b L809
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
    cbz x10, L810
L811:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L810:
    mov w9, w24
    bl Lrd_slow
    b L811
    .p2align 4
Lf_EA:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L812
L813:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L814
L815:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w9, w12
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L816
    strb w26, [x10, w9, uxtw]
L817:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L818
L819:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L812:
    bl Lrd_slow
    b L813
L814:
    bl Lrd_slow
    b L815
L816:
    mov w0, w26
    bl Lwr_slow
    b L817
L818:
    mov w9, w24
    bl Lrd_slow
    b L819
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
    cbz x10, L820
L821:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L820:
    mov w9, w24
    bl Lrd_slow
    b L821
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
    cbz x10, L822
L823:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L822:
    mov w9, w24
    bl Lrd_slow
    b L823
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
    cbz x10, L824
L825:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L824:
    mov w9, w24
    bl Lrd_slow
    b L825
    .p2align 4
Lf_EE:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L826
L827:
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
    cbz x10, L828
L829:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L826:
    bl Lrd_slow
    b L827
L828:
    mov w9, w24
    bl Lrd_slow
    b L829
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
    cbz x10, L830
    strb w11, [x10, w9, uxtw]
L831:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L832
L833:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L834
    strb w12, [x10, w9, uxtw]
L835:
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
    cbz x10, L836
L837:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L830:
    mov w0, w11
    bl Lwr_slow
    b L831
L832:
    bl Ltick_slow4
    b L833
L834:
    mov w0, w12
    bl Lwr_slow
    b L835
L836:
    mov w9, w24
    bl Lrd_slow
    b L837
    .p2align 4
Lf_F0:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L840
L841:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    cmp w11, #0x80
    b.lo L838
    cmp w11, #0xFF
    b.eq L838
    add x21, x21, #4
    ldr x10, [x20, #272]
    orr w0, w11, #0xFF00
    ldrb w26, [x10, w0, uxtw]
    b L839
L838:
    mov w9, w11
    orr w9, w9, #0xFF00
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L842
L843:
    ldrb w26, [x10, w9, uxtw]
L839:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L844
L845:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L840:
    bl Lrd_slow
    b L841
L842:
    bl Lrd_slow
    b L843
L844:
    mov w9, w24
    bl Lrd_slow
    b L845
    .p2align 4
Lf_F1:
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L846
L847:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L848
L849:
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
    cbz x10, L850
L851:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L846:
    bl Lrd_slow
    b L847
L848:
    bl Lrd_slow
    b L849
L850:
    mov w9, w24
    bl Lrd_slow
    b L851
    .p2align 4
Lf_F2:
    and w9, w28, #0xFF
    orr w9, w9, #0xFF00
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L852
L853:
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
    cbz x10, L854
L855:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L852:
    bl Lrd_slow
    b L853
L854:
    mov w9, w24
    bl Lrd_slow
    b L855
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
    cbnz w17, L856
    str x21, [x19, #40]
    ldrh w17, [x20, #368]
    add w17, w17, w21
    add x16, x19, #16, lsl #12
    strh w17, [x16, #322]
L856:
    mov x0, x19
    mov w1, #243
    bl gbc_asm_op
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
    cbz x10, L857
L858:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L857:
    mov w9, w24
    bl Lrd_slow
    b L858
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
    cbz x10, L859
L860:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L859:
    mov w9, w24
    bl Lrd_slow
    b L860
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
    cbz x10, L861
    strb w11, [x10, w9, uxtw]
L862:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L863
L864:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L865
    strb w12, [x10, w9, uxtw]
L866:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L867
L868:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L861:
    mov w0, w11
    bl Lwr_slow
    b L862
L863:
    bl Ltick_slow4
    b L864
L865:
    mov w0, w12
    bl Lwr_slow
    b L866
L867:
    mov w9, w24
    bl Lrd_slow
    b L868
    .p2align 4
Lf_F6:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L869
L870:
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
    cbz x10, L871
L872:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L869:
    bl Lrd_slow
    b L870
L871:
    mov w9, w24
    bl Lrd_slow
    b L872
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
    cbz x10, L873
    strb w11, [x10, w9, uxtw]
L874:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L875
L876:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L877
    strb w12, [x10, w9, uxtw]
L878:
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
    cbz x10, L879
L880:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L873:
    mov w0, w11
    bl Lwr_slow
    b L874
L875:
    bl Ltick_slow4
    b L876
L877:
    mov w0, w12
    bl Lwr_slow
    b L878
L879:
    mov w9, w24
    bl Lrd_slow
    b L880
    .p2align 4
Lf_F8:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L881
L882:
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
    cbz x10, L883
L884:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L881:
    bl Lrd_slow
    b L882
L883:
    mov w9, w24
    bl Lrd_slow
    b L884
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
    cbz x10, L885
L886:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L885:
    mov w9, w24
    bl Lrd_slow
    b L886
    .p2align 4
Lf_FA:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L887
L888:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L889
L890:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w9, w12
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L891
L892:
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
    cbz x10, L893
L894:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L887:
    bl Lrd_slow
    b L888
L889:
    bl Lrd_slow
    b L890
L891:
    bl Lrd_slow
    b L892
L893:
    mov w9, w24
    bl Lrd_slow
    b L894
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
    cbnz w17, L895
    str x21, [x19, #40]
    ldrh w17, [x20, #368]
    add w17, w17, w21
    add x16, x19, #16, lsl #12
    strh w17, [x16, #322]
L895:
    mov x0, x19
    mov w1, #251
    bl gbc_asm_op
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
    cbz x10, L896
L897:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L896:
    mov w9, w24
    bl Lrd_slow
    b L897
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
    cbz x10, L898
L899:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L898:
    mov w9, w24
    bl Lrd_slow
    b L899
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
    cbz x10, L900
L901:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L900:
    mov w9, w24
    bl Lrd_slow
    b L901
    .p2align 4
Lf_FE:
    mov w9, w24
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L902
L903:
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
    cbz x10, L904
L905:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L902:
    bl Lrd_slow
    b L903
L904:
    mov w9, w24
    bl Lrd_slow
    b L905
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
    cbz x10, L906
    strb w11, [x10, w9, uxtw]
L907:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L908
L909:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L910
    strb w12, [x10, w9, uxtw]
L911:
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
    cbz x10, L912
L913:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L906:
    mov w0, w11
    bl Lwr_slow
    b L907
L908:
    bl Ltick_slow4
    b L909
L910:
    mov w0, w12
    bl Lwr_slow
    b L911
L912:
    mov w9, w24
    bl Lrd_slow
    b L913
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
    cbz x10, L914
L915:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L914:
    mov w9, w24
    bl Lrd_slow
    b L915
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
    cbz x10, L916
L917:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L916:
    mov w9, w24
    bl Lrd_slow
    b L917
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
    cbz x10, L918
L919:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L918:
    mov w9, w24
    bl Lrd_slow
    b L919
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
    cbz x10, L920
L921:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L920:
    mov w9, w24
    bl Lrd_slow
    b L921
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
    cbz x10, L922
L923:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L922:
    mov w9, w24
    bl Lrd_slow
    b L923
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
    cbz x10, L924
L925:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L924:
    mov w9, w24
    bl Lrd_slow
    b L925
    .p2align 4
Lfcb_06:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L926
L927:
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
    cbz x10, L928
    strb w11, [x10, w9, uxtw]
L929:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L930
L931:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L926:
    bl Lrd_slow
    b L927
L928:
    mov w0, w11
    bl Lwr_slow
    b L929
L930:
    mov w9, w24
    bl Lrd_slow
    b L931
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
    cbz x10, L932
L933:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L932:
    mov w9, w24
    bl Lrd_slow
    b L933
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
    cbz x10, L934
L935:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L934:
    mov w9, w24
    bl Lrd_slow
    b L935
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
    cbz x10, L936
L937:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L936:
    mov w9, w24
    bl Lrd_slow
    b L937
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
    cbz x10, L938
L939:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L938:
    mov w9, w24
    bl Lrd_slow
    b L939
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
    cbz x10, L940
L941:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L940:
    mov w9, w24
    bl Lrd_slow
    b L941
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
    cbz x10, L942
L943:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L942:
    mov w9, w24
    bl Lrd_slow
    b L943
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
    cbz x10, L944
L945:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L944:
    mov w9, w24
    bl Lrd_slow
    b L945
    .p2align 4
Lfcb_0E:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L946
L947:
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
    cbz x10, L948
    strb w11, [x10, w9, uxtw]
L949:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L950
L951:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L946:
    bl Lrd_slow
    b L947
L948:
    mov w0, w11
    bl Lwr_slow
    b L949
L950:
    mov w9, w24
    bl Lrd_slow
    b L951
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
    cbz x10, L952
L953:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L952:
    mov w9, w24
    bl Lrd_slow
    b L953
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
    cbz x10, L954
L955:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L954:
    mov w9, w24
    bl Lrd_slow
    b L955
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
    cbz x10, L956
L957:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L956:
    mov w9, w24
    bl Lrd_slow
    b L957
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
    cbz x10, L958
L959:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L958:
    mov w9, w24
    bl Lrd_slow
    b L959
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
    cbz x10, L960
L961:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L960:
    mov w9, w24
    bl Lrd_slow
    b L961
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
    cbz x10, L962
L963:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L962:
    mov w9, w24
    bl Lrd_slow
    b L963
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
    cbz x10, L964
L965:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L964:
    mov w9, w24
    bl Lrd_slow
    b L965
    .p2align 4
Lfcb_16:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L966
L967:
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
    cbz x10, L968
    strb w11, [x10, w9, uxtw]
L969:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L970
L971:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L966:
    bl Lrd_slow
    b L967
L968:
    mov w0, w11
    bl Lwr_slow
    b L969
L970:
    mov w9, w24
    bl Lrd_slow
    b L971
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
    cbz x10, L972
L973:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L972:
    mov w9, w24
    bl Lrd_slow
    b L973
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
    cbz x10, L974
L975:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L974:
    mov w9, w24
    bl Lrd_slow
    b L975
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
    cbz x10, L976
L977:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L976:
    mov w9, w24
    bl Lrd_slow
    b L977
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
    cbz x10, L978
L979:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L978:
    mov w9, w24
    bl Lrd_slow
    b L979
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
    cbz x10, L980
L981:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L980:
    mov w9, w24
    bl Lrd_slow
    b L981
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
    cbz x10, L982
L983:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L982:
    mov w9, w24
    bl Lrd_slow
    b L983
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
    cbz x10, L984
L985:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L984:
    mov w9, w24
    bl Lrd_slow
    b L985
    .p2align 4
Lfcb_1E:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L986
L987:
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
    cbz x10, L988
    strb w11, [x10, w9, uxtw]
L989:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L990
L991:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L986:
    bl Lrd_slow
    b L987
L988:
    mov w0, w11
    bl Lwr_slow
    b L989
L990:
    mov w9, w24
    bl Lrd_slow
    b L991
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
    cbz x10, L992
L993:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L992:
    mov w9, w24
    bl Lrd_slow
    b L993
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
    cbz x10, L994
L995:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L994:
    mov w9, w24
    bl Lrd_slow
    b L995
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
    cbz x10, L996
L997:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L996:
    mov w9, w24
    bl Lrd_slow
    b L997
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
    cbz x10, L998
L999:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L998:
    mov w9, w24
    bl Lrd_slow
    b L999
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
    cbz x10, L1000
L1001:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1000:
    mov w9, w24
    bl Lrd_slow
    b L1001
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
    cbz x10, L1002
L1003:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1002:
    mov w9, w24
    bl Lrd_slow
    b L1003
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
    cbz x10, L1004
L1005:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1004:
    mov w9, w24
    bl Lrd_slow
    b L1005
    .p2align 4
Lfcb_26:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1006
L1007:
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
    cbz x10, L1008
    strb w11, [x10, w9, uxtw]
L1009:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1010
L1011:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1006:
    bl Lrd_slow
    b L1007
L1008:
    mov w0, w11
    bl Lwr_slow
    b L1009
L1010:
    mov w9, w24
    bl Lrd_slow
    b L1011
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
    cbz x10, L1012
L1013:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1012:
    mov w9, w24
    bl Lrd_slow
    b L1013
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
    cbz x10, L1014
L1015:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1014:
    mov w9, w24
    bl Lrd_slow
    b L1015
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
    cbz x10, L1016
L1017:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1016:
    mov w9, w24
    bl Lrd_slow
    b L1017
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
    cbz x10, L1018
L1019:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1018:
    mov w9, w24
    bl Lrd_slow
    b L1019
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
    cbz x10, L1020
L1021:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1020:
    mov w9, w24
    bl Lrd_slow
    b L1021
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
    cbz x10, L1022
L1023:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1022:
    mov w9, w24
    bl Lrd_slow
    b L1023
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
    cbz x10, L1024
L1025:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1024:
    mov w9, w24
    bl Lrd_slow
    b L1025
    .p2align 4
Lfcb_2E:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1026
L1027:
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
    cbz x10, L1028
    strb w11, [x10, w9, uxtw]
L1029:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1030
L1031:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1026:
    bl Lrd_slow
    b L1027
L1028:
    mov w0, w11
    bl Lwr_slow
    b L1029
L1030:
    mov w9, w24
    bl Lrd_slow
    b L1031
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
    cbz x10, L1032
L1033:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1032:
    mov w9, w24
    bl Lrd_slow
    b L1033
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
    cbz x10, L1034
L1035:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1034:
    mov w9, w24
    bl Lrd_slow
    b L1035
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
    cbz x10, L1036
L1037:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1036:
    mov w9, w24
    bl Lrd_slow
    b L1037
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
    cbz x10, L1038
L1039:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1038:
    mov w9, w24
    bl Lrd_slow
    b L1039
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
    cbz x10, L1040
L1041:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1040:
    mov w9, w24
    bl Lrd_slow
    b L1041
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
    cbz x10, L1042
L1043:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1042:
    mov w9, w24
    bl Lrd_slow
    b L1043
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
    cbz x10, L1044
L1045:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1044:
    mov w9, w24
    bl Lrd_slow
    b L1045
    .p2align 4
Lfcb_36:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1046
L1047:
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
    cbz x10, L1048
    strb w11, [x10, w9, uxtw]
L1049:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1050
L1051:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1046:
    bl Lrd_slow
    b L1047
L1048:
    mov w0, w11
    bl Lwr_slow
    b L1049
L1050:
    mov w9, w24
    bl Lrd_slow
    b L1051
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
    cbz x10, L1052
L1053:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1052:
    mov w9, w24
    bl Lrd_slow
    b L1053
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
    cbz x10, L1054
L1055:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1054:
    mov w9, w24
    bl Lrd_slow
    b L1055
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
    cbz x10, L1056
L1057:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1056:
    mov w9, w24
    bl Lrd_slow
    b L1057
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
    cbz x10, L1058
L1059:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1058:
    mov w9, w24
    bl Lrd_slow
    b L1059
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
    cbz x10, L1060
L1061:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1060:
    mov w9, w24
    bl Lrd_slow
    b L1061
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
    cbz x10, L1062
L1063:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1062:
    mov w9, w24
    bl Lrd_slow
    b L1063
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
    cbz x10, L1064
L1065:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1064:
    mov w9, w24
    bl Lrd_slow
    b L1065
    .p2align 4
Lfcb_3E:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1066
L1067:
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
    cbz x10, L1068
    strb w11, [x10, w9, uxtw]
L1069:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1070
L1071:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1066:
    bl Lrd_slow
    b L1067
L1068:
    mov w0, w11
    bl Lwr_slow
    b L1069
L1070:
    mov w9, w24
    bl Lrd_slow
    b L1071
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
    cbz x10, L1072
L1073:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1072:
    mov w9, w24
    bl Lrd_slow
    b L1073
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
    cbz x10, L1074
L1075:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1074:
    mov w9, w24
    bl Lrd_slow
    b L1075
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
    cbz x10, L1076
L1077:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1076:
    mov w9, w24
    bl Lrd_slow
    b L1077
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
    cbz x10, L1078
L1079:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1078:
    mov w9, w24
    bl Lrd_slow
    b L1079
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
    cbz x10, L1080
L1081:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1080:
    mov w9, w24
    bl Lrd_slow
    b L1081
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
    cbz x10, L1082
L1083:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1082:
    mov w9, w24
    bl Lrd_slow
    b L1083
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
    cbz x10, L1084
L1085:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1084:
    mov w9, w24
    bl Lrd_slow
    b L1085
    .p2align 4
Lfcb_46:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1086
L1087:
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
    cbz x10, L1088
L1089:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1086:
    bl Lrd_slow
    b L1087
L1088:
    mov w9, w24
    bl Lrd_slow
    b L1089
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
    cbz x10, L1090
L1091:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1090:
    mov w9, w24
    bl Lrd_slow
    b L1091
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
    cbz x10, L1092
L1093:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1092:
    mov w9, w24
    bl Lrd_slow
    b L1093
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
    cbz x10, L1094
L1095:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1094:
    mov w9, w24
    bl Lrd_slow
    b L1095
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
    cbz x10, L1096
L1097:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1096:
    mov w9, w24
    bl Lrd_slow
    b L1097
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
    cbz x10, L1098
L1099:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1098:
    mov w9, w24
    bl Lrd_slow
    b L1099
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
    cbz x10, L1100
L1101:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1100:
    mov w9, w24
    bl Lrd_slow
    b L1101
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
    cbz x10, L1102
L1103:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1102:
    mov w9, w24
    bl Lrd_slow
    b L1103
    .p2align 4
Lfcb_4E:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1104
L1105:
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
    cbz x10, L1106
L1107:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1104:
    bl Lrd_slow
    b L1105
L1106:
    mov w9, w24
    bl Lrd_slow
    b L1107
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
    cbz x10, L1108
L1109:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1108:
    mov w9, w24
    bl Lrd_slow
    b L1109
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
    cbz x10, L1110
L1111:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1110:
    mov w9, w24
    bl Lrd_slow
    b L1111
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
    cbz x10, L1112
L1113:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1112:
    mov w9, w24
    bl Lrd_slow
    b L1113
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
    cbz x10, L1114
L1115:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1114:
    mov w9, w24
    bl Lrd_slow
    b L1115
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
    cbz x10, L1116
L1117:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1116:
    mov w9, w24
    bl Lrd_slow
    b L1117
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
    cbz x10, L1118
L1119:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1118:
    mov w9, w24
    bl Lrd_slow
    b L1119
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
    cbz x10, L1120
L1121:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1120:
    mov w9, w24
    bl Lrd_slow
    b L1121
    .p2align 4
Lfcb_56:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1122
L1123:
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
    cbz x10, L1124
L1125:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1122:
    bl Lrd_slow
    b L1123
L1124:
    mov w9, w24
    bl Lrd_slow
    b L1125
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
    cbz x10, L1126
L1127:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1126:
    mov w9, w24
    bl Lrd_slow
    b L1127
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
    cbz x10, L1128
L1129:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1128:
    mov w9, w24
    bl Lrd_slow
    b L1129
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
    cbz x10, L1130
L1131:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1130:
    mov w9, w24
    bl Lrd_slow
    b L1131
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
    cbz x10, L1132
L1133:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1132:
    mov w9, w24
    bl Lrd_slow
    b L1133
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
    cbz x10, L1134
L1135:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1134:
    mov w9, w24
    bl Lrd_slow
    b L1135
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
    cbz x10, L1136
L1137:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1136:
    mov w9, w24
    bl Lrd_slow
    b L1137
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
    cbz x10, L1138
L1139:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1138:
    mov w9, w24
    bl Lrd_slow
    b L1139
    .p2align 4
Lfcb_5E:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1140
L1141:
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
    cbz x10, L1142
L1143:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1140:
    bl Lrd_slow
    b L1141
L1142:
    mov w9, w24
    bl Lrd_slow
    b L1143
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
    cbz x10, L1144
L1145:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1144:
    mov w9, w24
    bl Lrd_slow
    b L1145
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
    cbz x10, L1146
L1147:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1146:
    mov w9, w24
    bl Lrd_slow
    b L1147
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
    cbz x10, L1148
L1149:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1148:
    mov w9, w24
    bl Lrd_slow
    b L1149
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
    cbz x10, L1150
L1151:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1150:
    mov w9, w24
    bl Lrd_slow
    b L1151
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
    cbz x10, L1152
L1153:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1152:
    mov w9, w24
    bl Lrd_slow
    b L1153
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
    cbz x10, L1154
L1155:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1154:
    mov w9, w24
    bl Lrd_slow
    b L1155
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
    cbz x10, L1156
L1157:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1156:
    mov w9, w24
    bl Lrd_slow
    b L1157
    .p2align 4
Lfcb_66:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1158
L1159:
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
    cbz x10, L1160
L1161:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1158:
    bl Lrd_slow
    b L1159
L1160:
    mov w9, w24
    bl Lrd_slow
    b L1161
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
    cbz x10, L1162
L1163:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1162:
    mov w9, w24
    bl Lrd_slow
    b L1163
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
    cbz x10, L1164
L1165:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1164:
    mov w9, w24
    bl Lrd_slow
    b L1165
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
    cbz x10, L1166
L1167:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1166:
    mov w9, w24
    bl Lrd_slow
    b L1167
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
    cbz x10, L1168
L1169:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1168:
    mov w9, w24
    bl Lrd_slow
    b L1169
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
    cbz x10, L1170
L1171:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1170:
    mov w9, w24
    bl Lrd_slow
    b L1171
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
    cbz x10, L1172
L1173:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1172:
    mov w9, w24
    bl Lrd_slow
    b L1173
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
    cbz x10, L1174
L1175:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1174:
    mov w9, w24
    bl Lrd_slow
    b L1175
    .p2align 4
Lfcb_6E:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1176
L1177:
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
    cbz x10, L1178
L1179:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1176:
    bl Lrd_slow
    b L1177
L1178:
    mov w9, w24
    bl Lrd_slow
    b L1179
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
    cbz x10, L1180
L1181:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1180:
    mov w9, w24
    bl Lrd_slow
    b L1181
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
    cbz x10, L1182
L1183:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1182:
    mov w9, w24
    bl Lrd_slow
    b L1183
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
    cbz x10, L1184
L1185:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1184:
    mov w9, w24
    bl Lrd_slow
    b L1185
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
    cbz x10, L1186
L1187:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1186:
    mov w9, w24
    bl Lrd_slow
    b L1187
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
    cbz x10, L1188
L1189:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1188:
    mov w9, w24
    bl Lrd_slow
    b L1189
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
    cbz x10, L1190
L1191:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1190:
    mov w9, w24
    bl Lrd_slow
    b L1191
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
    cbz x10, L1192
L1193:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1192:
    mov w9, w24
    bl Lrd_slow
    b L1193
    .p2align 4
Lfcb_76:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1194
L1195:
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
    cbz x10, L1196
L1197:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1194:
    bl Lrd_slow
    b L1195
L1196:
    mov w9, w24
    bl Lrd_slow
    b L1197
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
    cbz x10, L1198
L1199:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1198:
    mov w9, w24
    bl Lrd_slow
    b L1199
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
    cbz x10, L1200
L1201:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1200:
    mov w9, w24
    bl Lrd_slow
    b L1201
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
    cbz x10, L1202
L1203:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1202:
    mov w9, w24
    bl Lrd_slow
    b L1203
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
    cbz x10, L1204
L1205:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1204:
    mov w9, w24
    bl Lrd_slow
    b L1205
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
    cbz x10, L1206
L1207:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1206:
    mov w9, w24
    bl Lrd_slow
    b L1207
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
    cbz x10, L1208
L1209:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1208:
    mov w9, w24
    bl Lrd_slow
    b L1209
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
    cbz x10, L1210
L1211:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1210:
    mov w9, w24
    bl Lrd_slow
    b L1211
    .p2align 4
Lfcb_7E:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1212
L1213:
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
    cbz x10, L1214
L1215:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1212:
    bl Lrd_slow
    b L1213
L1214:
    mov w9, w24
    bl Lrd_slow
    b L1215
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
    cbz x10, L1216
L1217:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1216:
    mov w9, w24
    bl Lrd_slow
    b L1217
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
    cbz x10, L1218
L1219:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1218:
    mov w9, w24
    bl Lrd_slow
    b L1219
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
    cbz x10, L1220
L1221:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1220:
    mov w9, w24
    bl Lrd_slow
    b L1221
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
    cbz x10, L1222
L1223:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1222:
    mov w9, w24
    bl Lrd_slow
    b L1223
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
    cbz x10, L1224
L1225:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1224:
    mov w9, w24
    bl Lrd_slow
    b L1225
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
    cbz x10, L1226
L1227:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1226:
    mov w9, w24
    bl Lrd_slow
    b L1227
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
    cbz x10, L1228
L1229:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1228:
    mov w9, w24
    bl Lrd_slow
    b L1229
    .p2align 4
Lfcb_86:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1230
L1231:
    ldrb w11, [x10, w9, uxtw]
    and w2, w11, #0xFFFFFFFE
    and w11, w2, #0xFF
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1232
    strb w11, [x10, w9, uxtw]
L1233:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1234
L1235:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1230:
    bl Lrd_slow
    b L1231
L1232:
    mov w0, w11
    bl Lwr_slow
    b L1233
L1234:
    mov w9, w24
    bl Lrd_slow
    b L1235
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
    cbz x10, L1236
L1237:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1236:
    mov w9, w24
    bl Lrd_slow
    b L1237
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
    cbz x10, L1238
L1239:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1238:
    mov w9, w24
    bl Lrd_slow
    b L1239
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
    cbz x10, L1240
L1241:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1240:
    mov w9, w24
    bl Lrd_slow
    b L1241
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
    cbz x10, L1242
L1243:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1242:
    mov w9, w24
    bl Lrd_slow
    b L1243
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
    cbz x10, L1244
L1245:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1244:
    mov w9, w24
    bl Lrd_slow
    b L1245
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
    cbz x10, L1246
L1247:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1246:
    mov w9, w24
    bl Lrd_slow
    b L1247
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
    cbz x10, L1248
L1249:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1248:
    mov w9, w24
    bl Lrd_slow
    b L1249
    .p2align 4
Lfcb_8E:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1250
L1251:
    ldrb w11, [x10, w9, uxtw]
    and w2, w11, #0xFFFFFFFD
    and w11, w2, #0xFF
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1252
    strb w11, [x10, w9, uxtw]
L1253:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1254
L1255:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1250:
    bl Lrd_slow
    b L1251
L1252:
    mov w0, w11
    bl Lwr_slow
    b L1253
L1254:
    mov w9, w24
    bl Lrd_slow
    b L1255
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
    cbz x10, L1256
L1257:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1256:
    mov w9, w24
    bl Lrd_slow
    b L1257
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
    cbz x10, L1258
L1259:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1258:
    mov w9, w24
    bl Lrd_slow
    b L1259
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
    cbz x10, L1260
L1261:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1260:
    mov w9, w24
    bl Lrd_slow
    b L1261
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
    cbz x10, L1262
L1263:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1262:
    mov w9, w24
    bl Lrd_slow
    b L1263
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
    cbz x10, L1264
L1265:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1264:
    mov w9, w24
    bl Lrd_slow
    b L1265
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
    cbz x10, L1266
L1267:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1266:
    mov w9, w24
    bl Lrd_slow
    b L1267
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
    cbz x10, L1268
L1269:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1268:
    mov w9, w24
    bl Lrd_slow
    b L1269
    .p2align 4
Lfcb_96:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1270
L1271:
    ldrb w11, [x10, w9, uxtw]
    and w2, w11, #0xFFFFFFFB
    and w11, w2, #0xFF
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1272
    strb w11, [x10, w9, uxtw]
L1273:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1274
L1275:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1270:
    bl Lrd_slow
    b L1271
L1272:
    mov w0, w11
    bl Lwr_slow
    b L1273
L1274:
    mov w9, w24
    bl Lrd_slow
    b L1275
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
    cbz x10, L1276
L1277:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1276:
    mov w9, w24
    bl Lrd_slow
    b L1277
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
    cbz x10, L1278
L1279:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1278:
    mov w9, w24
    bl Lrd_slow
    b L1279
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
    cbz x10, L1280
L1281:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1280:
    mov w9, w24
    bl Lrd_slow
    b L1281
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
    cbz x10, L1282
L1283:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1282:
    mov w9, w24
    bl Lrd_slow
    b L1283
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
    cbz x10, L1284
L1285:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1284:
    mov w9, w24
    bl Lrd_slow
    b L1285
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
    cbz x10, L1286
L1287:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1286:
    mov w9, w24
    bl Lrd_slow
    b L1287
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
    cbz x10, L1288
L1289:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1288:
    mov w9, w24
    bl Lrd_slow
    b L1289
    .p2align 4
Lfcb_9E:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1290
L1291:
    ldrb w11, [x10, w9, uxtw]
    and w2, w11, #0xFFFFFFF7
    and w11, w2, #0xFF
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1292
    strb w11, [x10, w9, uxtw]
L1293:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1294
L1295:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1290:
    bl Lrd_slow
    b L1291
L1292:
    mov w0, w11
    bl Lwr_slow
    b L1293
L1294:
    mov w9, w24
    bl Lrd_slow
    b L1295
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
    cbz x10, L1296
L1297:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1296:
    mov w9, w24
    bl Lrd_slow
    b L1297
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
    cbz x10, L1298
L1299:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1298:
    mov w9, w24
    bl Lrd_slow
    b L1299
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
    cbz x10, L1300
L1301:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1300:
    mov w9, w24
    bl Lrd_slow
    b L1301
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
    cbz x10, L1302
L1303:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1302:
    mov w9, w24
    bl Lrd_slow
    b L1303
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
    cbz x10, L1304
L1305:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1304:
    mov w9, w24
    bl Lrd_slow
    b L1305
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
    cbz x10, L1306
L1307:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1306:
    mov w9, w24
    bl Lrd_slow
    b L1307
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
    cbz x10, L1308
L1309:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1308:
    mov w9, w24
    bl Lrd_slow
    b L1309
    .p2align 4
Lfcb_A6:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1310
L1311:
    ldrb w11, [x10, w9, uxtw]
    and w2, w11, #0xFFFFFFEF
    and w11, w2, #0xFF
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1312
    strb w11, [x10, w9, uxtw]
L1313:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1314
L1315:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1310:
    bl Lrd_slow
    b L1311
L1312:
    mov w0, w11
    bl Lwr_slow
    b L1313
L1314:
    mov w9, w24
    bl Lrd_slow
    b L1315
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
    cbz x10, L1316
L1317:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1316:
    mov w9, w24
    bl Lrd_slow
    b L1317
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
    cbz x10, L1318
L1319:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1318:
    mov w9, w24
    bl Lrd_slow
    b L1319
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
    cbz x10, L1320
L1321:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1320:
    mov w9, w24
    bl Lrd_slow
    b L1321
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
    cbz x10, L1322
L1323:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1322:
    mov w9, w24
    bl Lrd_slow
    b L1323
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
    cbz x10, L1324
L1325:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1324:
    mov w9, w24
    bl Lrd_slow
    b L1325
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
    cbz x10, L1326
L1327:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1326:
    mov w9, w24
    bl Lrd_slow
    b L1327
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
    cbz x10, L1328
L1329:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1328:
    mov w9, w24
    bl Lrd_slow
    b L1329
    .p2align 4
Lfcb_AE:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1330
L1331:
    ldrb w11, [x10, w9, uxtw]
    and w2, w11, #0xFFFFFFDF
    and w11, w2, #0xFF
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1332
    strb w11, [x10, w9, uxtw]
L1333:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1334
L1335:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1330:
    bl Lrd_slow
    b L1331
L1332:
    mov w0, w11
    bl Lwr_slow
    b L1333
L1334:
    mov w9, w24
    bl Lrd_slow
    b L1335
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
    cbz x10, L1336
L1337:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1336:
    mov w9, w24
    bl Lrd_slow
    b L1337
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
    cbz x10, L1338
L1339:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1338:
    mov w9, w24
    bl Lrd_slow
    b L1339
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
    cbz x10, L1340
L1341:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1340:
    mov w9, w24
    bl Lrd_slow
    b L1341
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
    cbz x10, L1342
L1343:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1342:
    mov w9, w24
    bl Lrd_slow
    b L1343
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
    cbz x10, L1344
L1345:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1344:
    mov w9, w24
    bl Lrd_slow
    b L1345
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
    cbz x10, L1346
L1347:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1346:
    mov w9, w24
    bl Lrd_slow
    b L1347
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
    cbz x10, L1348
L1349:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1348:
    mov w9, w24
    bl Lrd_slow
    b L1349
    .p2align 4
Lfcb_B6:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1350
L1351:
    ldrb w11, [x10, w9, uxtw]
    and w2, w11, #0xFFFFFFBF
    and w11, w2, #0xFF
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1352
    strb w11, [x10, w9, uxtw]
L1353:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1354
L1355:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1350:
    bl Lrd_slow
    b L1351
L1352:
    mov w0, w11
    bl Lwr_slow
    b L1353
L1354:
    mov w9, w24
    bl Lrd_slow
    b L1355
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
    cbz x10, L1356
L1357:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1356:
    mov w9, w24
    bl Lrd_slow
    b L1357
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
    cbz x10, L1358
L1359:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1358:
    mov w9, w24
    bl Lrd_slow
    b L1359
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
    cbz x10, L1360
L1361:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1360:
    mov w9, w24
    bl Lrd_slow
    b L1361
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
    cbz x10, L1362
L1363:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1362:
    mov w9, w24
    bl Lrd_slow
    b L1363
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
    cbz x10, L1364
L1365:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1364:
    mov w9, w24
    bl Lrd_slow
    b L1365
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
    cbz x10, L1366
L1367:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1366:
    mov w9, w24
    bl Lrd_slow
    b L1367
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
    cbz x10, L1368
L1369:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1368:
    mov w9, w24
    bl Lrd_slow
    b L1369
    .p2align 4
Lfcb_BE:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1370
L1371:
    ldrb w11, [x10, w9, uxtw]
    and w2, w11, #0xFFFFFF7F
    and w11, w2, #0xFF
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1372
    strb w11, [x10, w9, uxtw]
L1373:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1374
L1375:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1370:
    bl Lrd_slow
    b L1371
L1372:
    mov w0, w11
    bl Lwr_slow
    b L1373
L1374:
    mov w9, w24
    bl Lrd_slow
    b L1375
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
    cbz x10, L1376
L1377:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1376:
    mov w9, w24
    bl Lrd_slow
    b L1377
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
    cbz x10, L1378
L1379:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1378:
    mov w9, w24
    bl Lrd_slow
    b L1379
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
    cbz x10, L1380
L1381:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1380:
    mov w9, w24
    bl Lrd_slow
    b L1381
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
    cbz x10, L1382
L1383:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1382:
    mov w9, w24
    bl Lrd_slow
    b L1383
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
    cbz x10, L1384
L1385:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1384:
    mov w9, w24
    bl Lrd_slow
    b L1385
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
    cbz x10, L1386
L1387:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1386:
    mov w9, w24
    bl Lrd_slow
    b L1387
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
    cbz x10, L1388
L1389:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1388:
    mov w9, w24
    bl Lrd_slow
    b L1389
    .p2align 4
Lfcb_C6:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1390
L1391:
    ldrb w11, [x10, w9, uxtw]
    orr w2, w11, #1
    and w11, w2, #0xFF
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1392
    strb w11, [x10, w9, uxtw]
L1393:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1394
L1395:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1390:
    bl Lrd_slow
    b L1391
L1392:
    mov w0, w11
    bl Lwr_slow
    b L1393
L1394:
    mov w9, w24
    bl Lrd_slow
    b L1395
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
    cbz x10, L1396
L1397:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1396:
    mov w9, w24
    bl Lrd_slow
    b L1397
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
    cbz x10, L1398
L1399:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1398:
    mov w9, w24
    bl Lrd_slow
    b L1399
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
    cbz x10, L1400
L1401:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1400:
    mov w9, w24
    bl Lrd_slow
    b L1401
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
    cbz x10, L1402
L1403:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1402:
    mov w9, w24
    bl Lrd_slow
    b L1403
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
    cbz x10, L1404
L1405:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1404:
    mov w9, w24
    bl Lrd_slow
    b L1405
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
    cbz x10, L1406
L1407:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1406:
    mov w9, w24
    bl Lrd_slow
    b L1407
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
    cbz x10, L1408
L1409:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1408:
    mov w9, w24
    bl Lrd_slow
    b L1409
    .p2align 4
Lfcb_CE:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1410
L1411:
    ldrb w11, [x10, w9, uxtw]
    orr w2, w11, #2
    and w11, w2, #0xFF
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1412
    strb w11, [x10, w9, uxtw]
L1413:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1414
L1415:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1410:
    bl Lrd_slow
    b L1411
L1412:
    mov w0, w11
    bl Lwr_slow
    b L1413
L1414:
    mov w9, w24
    bl Lrd_slow
    b L1415
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
    cbz x10, L1416
L1417:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1416:
    mov w9, w24
    bl Lrd_slow
    b L1417
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
    cbz x10, L1418
L1419:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1418:
    mov w9, w24
    bl Lrd_slow
    b L1419
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
    cbz x10, L1420
L1421:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1420:
    mov w9, w24
    bl Lrd_slow
    b L1421
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
    cbz x10, L1422
L1423:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1422:
    mov w9, w24
    bl Lrd_slow
    b L1423
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
    cbz x10, L1424
L1425:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1424:
    mov w9, w24
    bl Lrd_slow
    b L1425
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
    cbz x10, L1426
L1427:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1426:
    mov w9, w24
    bl Lrd_slow
    b L1427
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
    cbz x10, L1428
L1429:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1428:
    mov w9, w24
    bl Lrd_slow
    b L1429
    .p2align 4
Lfcb_D6:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1430
L1431:
    ldrb w11, [x10, w9, uxtw]
    orr w2, w11, #4
    and w11, w2, #0xFF
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1432
    strb w11, [x10, w9, uxtw]
L1433:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1434
L1435:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1430:
    bl Lrd_slow
    b L1431
L1432:
    mov w0, w11
    bl Lwr_slow
    b L1433
L1434:
    mov w9, w24
    bl Lrd_slow
    b L1435
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
    cbz x10, L1436
L1437:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1436:
    mov w9, w24
    bl Lrd_slow
    b L1437
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
    cbz x10, L1438
L1439:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1438:
    mov w9, w24
    bl Lrd_slow
    b L1439
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
    cbz x10, L1440
L1441:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1440:
    mov w9, w24
    bl Lrd_slow
    b L1441
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
    cbz x10, L1442
L1443:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1442:
    mov w9, w24
    bl Lrd_slow
    b L1443
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
    cbz x10, L1444
L1445:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1444:
    mov w9, w24
    bl Lrd_slow
    b L1445
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
    cbz x10, L1446
L1447:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1446:
    mov w9, w24
    bl Lrd_slow
    b L1447
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
    cbz x10, L1448
L1449:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1448:
    mov w9, w24
    bl Lrd_slow
    b L1449
    .p2align 4
Lfcb_DE:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1450
L1451:
    ldrb w11, [x10, w9, uxtw]
    orr w2, w11, #8
    and w11, w2, #0xFF
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1452
    strb w11, [x10, w9, uxtw]
L1453:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1454
L1455:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1450:
    bl Lrd_slow
    b L1451
L1452:
    mov w0, w11
    bl Lwr_slow
    b L1453
L1454:
    mov w9, w24
    bl Lrd_slow
    b L1455
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
    cbz x10, L1456
L1457:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1456:
    mov w9, w24
    bl Lrd_slow
    b L1457
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
    cbz x10, L1458
L1459:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1458:
    mov w9, w24
    bl Lrd_slow
    b L1459
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
    cbz x10, L1460
L1461:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1460:
    mov w9, w24
    bl Lrd_slow
    b L1461
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
    cbz x10, L1462
L1463:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1462:
    mov w9, w24
    bl Lrd_slow
    b L1463
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
    cbz x10, L1464
L1465:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1464:
    mov w9, w24
    bl Lrd_slow
    b L1465
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
    cbz x10, L1466
L1467:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1466:
    mov w9, w24
    bl Lrd_slow
    b L1467
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
    cbz x10, L1468
L1469:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1468:
    mov w9, w24
    bl Lrd_slow
    b L1469
    .p2align 4
Lfcb_E6:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1470
L1471:
    ldrb w11, [x10, w9, uxtw]
    orr w2, w11, #16
    and w11, w2, #0xFF
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1472
    strb w11, [x10, w9, uxtw]
L1473:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1474
L1475:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1470:
    bl Lrd_slow
    b L1471
L1472:
    mov w0, w11
    bl Lwr_slow
    b L1473
L1474:
    mov w9, w24
    bl Lrd_slow
    b L1475
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
    cbz x10, L1476
L1477:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1476:
    mov w9, w24
    bl Lrd_slow
    b L1477
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
    cbz x10, L1478
L1479:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1478:
    mov w9, w24
    bl Lrd_slow
    b L1479
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
    cbz x10, L1480
L1481:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1480:
    mov w9, w24
    bl Lrd_slow
    b L1481
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
    cbz x10, L1482
L1483:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1482:
    mov w9, w24
    bl Lrd_slow
    b L1483
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
    cbz x10, L1484
L1485:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1484:
    mov w9, w24
    bl Lrd_slow
    b L1485
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
    cbz x10, L1486
L1487:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1486:
    mov w9, w24
    bl Lrd_slow
    b L1487
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
    cbz x10, L1488
L1489:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1488:
    mov w9, w24
    bl Lrd_slow
    b L1489
    .p2align 4
Lfcb_EE:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1490
L1491:
    ldrb w11, [x10, w9, uxtw]
    orr w2, w11, #32
    and w11, w2, #0xFF
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1492
    strb w11, [x10, w9, uxtw]
L1493:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1494
L1495:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1490:
    bl Lrd_slow
    b L1491
L1492:
    mov w0, w11
    bl Lwr_slow
    b L1493
L1494:
    mov w9, w24
    bl Lrd_slow
    b L1495
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
    cbz x10, L1496
L1497:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1496:
    mov w9, w24
    bl Lrd_slow
    b L1497
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
    cbz x10, L1498
L1499:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1498:
    mov w9, w24
    bl Lrd_slow
    b L1499
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
    cbz x10, L1500
L1501:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1500:
    mov w9, w24
    bl Lrd_slow
    b L1501
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
    cbz x10, L1502
L1503:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1502:
    mov w9, w24
    bl Lrd_slow
    b L1503
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
    cbz x10, L1504
L1505:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1504:
    mov w9, w24
    bl Lrd_slow
    b L1505
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
    cbz x10, L1506
L1507:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1506:
    mov w9, w24
    bl Lrd_slow
    b L1507
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
    cbz x10, L1508
L1509:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1508:
    mov w9, w24
    bl Lrd_slow
    b L1509
    .p2align 4
Lfcb_F6:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1510
L1511:
    ldrb w11, [x10, w9, uxtw]
    orr w2, w11, #64
    and w11, w2, #0xFF
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1512
    strb w11, [x10, w9, uxtw]
L1513:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1514
L1515:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1510:
    bl Lrd_slow
    b L1511
L1512:
    mov w0, w11
    bl Lwr_slow
    b L1513
L1514:
    mov w9, w24
    bl Lrd_slow
    b L1515
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
    cbz x10, L1516
L1517:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1516:
    mov w9, w24
    bl Lrd_slow
    b L1517
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
    cbz x10, L1518
L1519:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1518:
    mov w9, w24
    bl Lrd_slow
    b L1519
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
    cbz x10, L1520
L1521:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1520:
    mov w9, w24
    bl Lrd_slow
    b L1521
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
    cbz x10, L1522
L1523:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1522:
    mov w9, w24
    bl Lrd_slow
    b L1523
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
    cbz x10, L1524
L1525:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1524:
    mov w9, w24
    bl Lrd_slow
    b L1525
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
    cbz x10, L1526
L1527:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1526:
    mov w9, w24
    bl Lrd_slow
    b L1527
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
    cbz x10, L1528
L1529:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1528:
    mov w9, w24
    bl Lrd_slow
    b L1529
    .p2align 4
Lfcb_FE:
    mov w9, w14
    add x21, x21, #4
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1530
L1531:
    ldrb w11, [x10, w9, uxtw]
    orr w2, w11, #128
    and w11, w2, #0xFF
    add x21, x21, #4
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1532
    strb w11, [x10, w9, uxtw]
L1533:
    cmp x21, x22
    b.hs Lslow_top
    ldrb w17, [x15, w24, uxtw]
    cbnz w17, Lslow_top
    subs x23, x23, #1
    b.mi Lexit_budget
    add x21, x21, #4
    lsr w10, w24, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1534
L1535:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1530:
    bl Lrd_slow
    b L1531
L1532:
    mov w0, w11
    bl Lwr_slow
    b L1533
L1534:
    mov w9, w24
    bl Lrd_slow
    b L1535
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
    cbz x10, L1536
L1537:
    ldrb w9, [x10, w24, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    ldrsw x17, [x16, x9, lsl #2]
    add x17, x16, x17
    br x17
L1536:
    mov w9, w24
    bl Lrd_slow
    b L1537
    .p2align 4
Lc_00:
    b Lnext
    .p2align 4
Lc_01:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1538
L1539:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1540
L1541:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1542
L1543:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1544
L1545:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w28, w12
    b Lnext
L1538:
    bl Ltick_slow4
    b L1539
L1540:
    bl Lrd_slow
    b L1541
L1542:
    bl Ltick_slow4
    b L1543
L1544:
    bl Lrd_slow
    b L1545
    .p2align 4
Lc_02:
    mov w9, w28
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1546
L1547:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1548
    strb w26, [x10, w9, uxtw]
L1549:
    b Lnext
L1546:
    bl Ltick_slow4
    b L1547
L1548:
    mov w0, w26
    bl Lwr_slow
    b L1549
    .p2align 4
Lc_03:
    add w28, w28, #1
    and w28, w28, #0xFFFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1550
L1551:
    b Lnext
L1550:
    bl Ltick_slow4
    b L1551
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
    b.hs L1552
L1553:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1554
L1555:
    ldrb w0, [x10, w9, uxtw]
    bfi w28, w0, #8, #8
    add w24, w24, #1
    and w24, w24, #0xFFFF
    b Lnext
L1552:
    bl Ltick_slow4
    b L1553
L1554:
    bl Lrd_slow
    b L1555
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
    b.hs L1556
L1557:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1558
L1559:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1560
L1561:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1562
L1563:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w9, w12
    and w11, w25, #0xFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1564
L1565:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1566
    strb w11, [x10, w9, uxtw]
L1567:
    add w9, w12, #1
    and w9, w9, #0xFFFF
    lsr w11, w25, #8
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1568
L1569:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1570
    strb w11, [x10, w9, uxtw]
L1571:
    b Lnext
L1556:
    bl Ltick_slow4
    b L1557
L1558:
    bl Lrd_slow
    b L1559
L1560:
    bl Ltick_slow4
    b L1561
L1562:
    bl Lrd_slow
    b L1563
L1564:
    bl Ltick_slow4
    b L1565
L1566:
    mov w0, w11
    bl Lwr_slow
    b L1567
L1568:
    bl Ltick_slow4
    b L1569
L1570:
    mov w0, w11
    bl Lwr_slow
    b L1571
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
    b.hs L1572
L1573:
    b Lnext
L1572:
    bl Ltick_slow4
    b L1573
    .p2align 4
Lc_0A:
    mov w9, w28
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1574
L1575:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1576
L1577:
    ldrb w26, [x10, w9, uxtw]
    b Lnext
L1574:
    bl Ltick_slow4
    b L1575
L1576:
    bl Lrd_slow
    b L1577
    .p2align 4
Lc_0B:
    sub w28, w28, #1
    and w28, w28, #0xFFFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1578
L1579:
    b Lnext
L1578:
    bl Ltick_slow4
    b L1579
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
    b.hs L1580
L1581:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1582
L1583:
    ldrb w0, [x10, w9, uxtw]
    bfi w28, w0, #0, #8
    add w24, w24, #1
    and w24, w24, #0xFFFF
    b Lnext
L1580:
    bl Ltick_slow4
    b L1581
L1582:
    bl Lrd_slow
    b L1583
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
    b.hs L1584
L1585:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1586
L1587:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    b Lnext
L1584:
    bl Ltick_slow4
    b L1585
L1586:
    bl Lrd_slow
    b L1587
    .p2align 4
Lc_11:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1588
L1589:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1590
L1591:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1592
L1593:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1594
L1595:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w13, w12
    b Lnext
L1588:
    bl Ltick_slow4
    b L1589
L1590:
    bl Lrd_slow
    b L1591
L1592:
    bl Ltick_slow4
    b L1593
L1594:
    bl Lrd_slow
    b L1595
    .p2align 4
Lc_12:
    mov w9, w13
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1596
L1597:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1598
    strb w26, [x10, w9, uxtw]
L1599:
    b Lnext
L1596:
    bl Ltick_slow4
    b L1597
L1598:
    mov w0, w26
    bl Lwr_slow
    b L1599
    .p2align 4
Lc_13:
    add w13, w13, #1
    and w13, w13, #0xFFFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1600
L1601:
    b Lnext
L1600:
    bl Ltick_slow4
    b L1601
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
    b.hs L1602
L1603:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1604
L1605:
    ldrb w0, [x10, w9, uxtw]
    bfi w13, w0, #8, #8
    add w24, w24, #1
    and w24, w24, #0xFFFF
    b Lnext
L1602:
    bl Ltick_slow4
    b L1603
L1604:
    bl Lrd_slow
    b L1605
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
    b.hs L1606
L1607:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1608
L1609:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    sxtb w0, w11
    add w24, w24, w0
    and w24, w24, #0xFFFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1611
L1612:
L1610:
    b Lnext
L1606:
    bl Ltick_slow4
    b L1607
L1608:
    bl Lrd_slow
    b L1609
L1611:
    bl Ltick_slow4
    b L1612
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
    b.hs L1613
L1614:
    b Lnext
L1613:
    bl Ltick_slow4
    b L1614
    .p2align 4
Lc_1A:
    mov w9, w13
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1615
L1616:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1617
L1618:
    ldrb w26, [x10, w9, uxtw]
    b Lnext
L1615:
    bl Ltick_slow4
    b L1616
L1617:
    bl Lrd_slow
    b L1618
    .p2align 4
Lc_1B:
    sub w13, w13, #1
    and w13, w13, #0xFFFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1619
L1620:
    b Lnext
L1619:
    bl Ltick_slow4
    b L1620
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
    b.hs L1621
L1622:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1623
L1624:
    ldrb w0, [x10, w9, uxtw]
    bfi w13, w0, #0, #8
    add w24, w24, #1
    and w24, w24, #0xFFFF
    b Lnext
L1621:
    bl Ltick_slow4
    b L1622
L1623:
    bl Lrd_slow
    b L1624
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
    b.hs L1625
L1626:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1627
L1628:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    tbnz w27, #7, L1629
    sxtb w0, w11
    add w24, w24, w0
    and w24, w24, #0xFFFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1630
L1631:
L1629:
    b Lnext
L1625:
    bl Ltick_slow4
    b L1626
L1627:
    bl Lrd_slow
    b L1628
L1630:
    bl Ltick_slow4
    b L1631
    .p2align 4
Lc_21:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1632
L1633:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1634
L1635:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1636
L1637:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1638
L1639:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w14, w12
    b Lnext
L1632:
    bl Ltick_slow4
    b L1633
L1634:
    bl Lrd_slow
    b L1635
L1636:
    bl Ltick_slow4
    b L1637
L1638:
    bl Lrd_slow
    b L1639
    .p2align 4
Lc_22:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1640
L1641:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1642
    strb w26, [x10, w9, uxtw]
L1643:
    add w14, w9, #1
    and w14, w14, #0xFFFF
    b Lnext
L1640:
    bl Ltick_slow4
    b L1641
L1642:
    mov w0, w26
    bl Lwr_slow
    b L1643
    .p2align 4
Lc_23:
    add w14, w14, #1
    and w14, w14, #0xFFFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1644
L1645:
    b Lnext
L1644:
    bl Ltick_slow4
    b L1645
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
    b.hs L1646
L1647:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1648
L1649:
    ldrb w0, [x10, w9, uxtw]
    bfi w14, w0, #8, #8
    add w24, w24, #1
    and w24, w24, #0xFFFF
    b Lnext
L1646:
    bl Ltick_slow4
    b L1647
L1648:
    bl Lrd_slow
    b L1649
    .p2align 4
Lc_27:
    mov w0, w26
    ubfx w1, w27, #4, #1
    tbz w27, #6, L1650
    tbz w27, #5, L1651
    sub w0, w0, #6
L1651:
    cbz w1, L1655
    sub w0, w0, #0x60
    b L1655
L1650:
    cbnz w1, L1652
    cmp w0, #0x99
    b.ls L1653
L1652:
    add w0, w0, #0x60
    mov w1, #1
L1653:
    tbnz w27, #5, L1654
    and w2, w0, #0xF
    cmp w2, #9
    b.ls L1655
L1654:
    add w0, w0, #6
L1655:
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
    b.hs L1657
L1658:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1659
L1660:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    tbz w27, #7, L1661
    sxtb w0, w11
    add w24, w24, w0
    and w24, w24, #0xFFFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1662
L1663:
L1661:
    b Lnext
L1657:
    bl Ltick_slow4
    b L1658
L1659:
    bl Lrd_slow
    b L1660
L1662:
    bl Ltick_slow4
    b L1663
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
    b.hs L1664
L1665:
    b Lnext
L1664:
    bl Ltick_slow4
    b L1665
    .p2align 4
Lc_2A:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1666
L1667:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1668
L1669:
    ldrb w26, [x10, w9, uxtw]
    add w14, w9, #1
    and w14, w14, #0xFFFF
    b Lnext
L1666:
    bl Ltick_slow4
    b L1667
L1668:
    bl Lrd_slow
    b L1669
    .p2align 4
Lc_2B:
    sub w14, w14, #1
    and w14, w14, #0xFFFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1670
L1671:
    b Lnext
L1670:
    bl Ltick_slow4
    b L1671
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
    b.hs L1672
L1673:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1674
L1675:
    ldrb w0, [x10, w9, uxtw]
    bfi w14, w0, #0, #8
    add w24, w24, #1
    and w24, w24, #0xFFFF
    b Lnext
L1672:
    bl Ltick_slow4
    b L1673
L1674:
    bl Lrd_slow
    b L1675
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
    b.hs L1676
L1677:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1678
L1679:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    tbnz w27, #4, L1680
    sxtb w0, w11
    add w24, w24, w0
    and w24, w24, #0xFFFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1681
L1682:
L1680:
    b Lnext
L1676:
    bl Ltick_slow4
    b L1677
L1678:
    bl Lrd_slow
    b L1679
L1681:
    bl Ltick_slow4
    b L1682
    .p2align 4
Lc_31:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1683
L1684:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1685
L1686:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1687
L1688:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1689
L1690:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w25, w12
    b Lnext
L1683:
    bl Ltick_slow4
    b L1684
L1685:
    bl Lrd_slow
    b L1686
L1687:
    bl Ltick_slow4
    b L1688
L1689:
    bl Lrd_slow
    b L1690
    .p2align 4
Lc_32:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1691
L1692:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1693
    strb w26, [x10, w9, uxtw]
L1694:
    sub w14, w9, #1
    and w14, w14, #0xFFFF
    b Lnext
L1691:
    bl Ltick_slow4
    b L1692
L1693:
    mov w0, w26
    bl Lwr_slow
    b L1694
    .p2align 4
Lc_33:
    add w25, w25, #1
    and w25, w25, #0xFFFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1695
L1696:
    b Lnext
L1695:
    bl Ltick_slow4
    b L1696
    .p2align 4
Lc_34:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1697
L1698:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1699
L1700:
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
    b.hs L1701
L1702:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1703
    strb w11, [x10, w9, uxtw]
L1704:
    b Lnext
L1697:
    bl Ltick_slow4
    b L1698
L1699:
    bl Lrd_slow
    b L1700
L1701:
    bl Ltick_slow4
    b L1702
L1703:
    mov w0, w11
    bl Lwr_slow
    b L1704
    .p2align 4
Lc_35:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1705
L1706:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1707
L1708:
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
    b.hs L1709
L1710:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1711
    strb w11, [x10, w9, uxtw]
L1712:
    b Lnext
L1705:
    bl Ltick_slow4
    b L1706
L1707:
    bl Lrd_slow
    b L1708
L1709:
    bl Ltick_slow4
    b L1710
L1711:
    mov w0, w11
    bl Lwr_slow
    b L1712
    .p2align 4
Lc_36:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1713
L1714:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1715
L1716:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1717
L1718:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1719
    strb w11, [x10, w9, uxtw]
L1720:
    b Lnext
L1713:
    bl Ltick_slow4
    b L1714
L1715:
    bl Lrd_slow
    b L1716
L1717:
    bl Ltick_slow4
    b L1718
L1719:
    mov w0, w11
    bl Lwr_slow
    b L1720
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
    b.hs L1721
L1722:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1723
L1724:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    tbz w27, #4, L1725
    sxtb w0, w11
    add w24, w24, w0
    and w24, w24, #0xFFFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1726
L1727:
L1725:
    b Lnext
L1721:
    bl Ltick_slow4
    b L1722
L1723:
    bl Lrd_slow
    b L1724
L1726:
    bl Ltick_slow4
    b L1727
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
    b.hs L1728
L1729:
    b Lnext
L1728:
    bl Ltick_slow4
    b L1729
    .p2align 4
Lc_3A:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1730
L1731:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1732
L1733:
    ldrb w26, [x10, w9, uxtw]
    sub w14, w9, #1
    and w14, w14, #0xFFFF
    b Lnext
L1730:
    bl Ltick_slow4
    b L1731
L1732:
    bl Lrd_slow
    b L1733
    .p2align 4
Lc_3B:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1734
L1735:
    b Lnext
L1734:
    bl Ltick_slow4
    b L1735
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
    b.hs L1736
L1737:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1738
L1739:
    ldrb w26, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    b Lnext
L1736:
    bl Ltick_slow4
    b L1737
L1738:
    bl Lrd_slow
    b L1739
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
    b.hs L1740
L1741:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1742
L1743:
    ldrb w0, [x10, w9, uxtw]
    bfi w28, w0, #8, #8
    b Lnext
L1740:
    bl Ltick_slow4
    b L1741
L1742:
    bl Lrd_slow
    b L1743
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
    b.hs L1744
L1745:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1746
L1747:
    ldrb w0, [x10, w9, uxtw]
    bfi w28, w0, #0, #8
    b Lnext
L1744:
    bl Ltick_slow4
    b L1745
L1746:
    bl Lrd_slow
    b L1747
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
    b.hs L1748
L1749:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1750
L1751:
    ldrb w0, [x10, w9, uxtw]
    bfi w13, w0, #8, #8
    b Lnext
L1748:
    bl Ltick_slow4
    b L1749
L1750:
    bl Lrd_slow
    b L1751
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
    b.hs L1752
L1753:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1754
L1755:
    ldrb w0, [x10, w9, uxtw]
    bfi w13, w0, #0, #8
    b Lnext
L1752:
    bl Ltick_slow4
    b L1753
L1754:
    bl Lrd_slow
    b L1755
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
    b.hs L1756
L1757:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1758
L1759:
    ldrb w0, [x10, w9, uxtw]
    bfi w14, w0, #8, #8
    b Lnext
L1756:
    bl Ltick_slow4
    b L1757
L1758:
    bl Lrd_slow
    b L1759
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
    b.hs L1760
L1761:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1762
L1763:
    ldrb w0, [x10, w9, uxtw]
    bfi w14, w0, #0, #8
    b Lnext
L1760:
    bl Ltick_slow4
    b L1761
L1762:
    bl Lrd_slow
    b L1763
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
    b.hs L1764
L1765:
    lsr w0, w28, #8
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1766
    strb w0, [x10, w9, uxtw]
L1767:
    b Lnext
L1764:
    bl Ltick_slow4
    b L1765
L1766:
    bl Lwr_slow
    b L1767
    .p2align 4
Lc_71:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1768
L1769:
    and w0, w28, #0xFF
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1770
    strb w0, [x10, w9, uxtw]
L1771:
    b Lnext
L1768:
    bl Ltick_slow4
    b L1769
L1770:
    bl Lwr_slow
    b L1771
    .p2align 4
Lc_72:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1772
L1773:
    lsr w0, w13, #8
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1774
    strb w0, [x10, w9, uxtw]
L1775:
    b Lnext
L1772:
    bl Ltick_slow4
    b L1773
L1774:
    bl Lwr_slow
    b L1775
    .p2align 4
Lc_73:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1776
L1777:
    and w0, w13, #0xFF
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1778
    strb w0, [x10, w9, uxtw]
L1779:
    b Lnext
L1776:
    bl Ltick_slow4
    b L1777
L1778:
    bl Lwr_slow
    b L1779
    .p2align 4
Lc_74:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1780
L1781:
    lsr w0, w14, #8
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1782
    strb w0, [x10, w9, uxtw]
L1783:
    b Lnext
L1780:
    bl Ltick_slow4
    b L1781
L1782:
    bl Lwr_slow
    b L1783
    .p2align 4
Lc_75:
    mov w9, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1784
L1785:
    and w0, w14, #0xFF
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1786
    strb w0, [x10, w9, uxtw]
L1787:
    b Lnext
L1784:
    bl Ltick_slow4
    b L1785
L1786:
    bl Lwr_slow
    b L1787
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
    cbnz w17, L1788
    str x21, [x19, #40]
    ldrh w17, [x20, #368]
    add w17, w17, w21
    add x16, x19, #16, lsl #12
    strh w17, [x16, #322]
L1788:
    mov x0, x19
    mov w1, #118
    bl gbc_asm_op
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
    b.hs L1789
L1790:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1791
    strb w26, [x10, w9, uxtw]
L1792:
    b Lnext
L1789:
    bl Ltick_slow4
    b L1790
L1791:
    mov w0, w26
    bl Lwr_slow
    b L1792
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
    b.hs L1793
L1794:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1795
L1796:
    ldrb w26, [x10, w9, uxtw]
    b Lnext
L1793:
    bl Ltick_slow4
    b L1794
L1795:
    bl Lrd_slow
    b L1796
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
    b.hs L1797
L1798:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1799
L1800:
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
L1797:
    bl Ltick_slow4
    b L1798
L1799:
    bl Lrd_slow
    b L1800
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
    b.hs L1801
L1802:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1803
L1804:
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
L1801:
    bl Ltick_slow4
    b L1802
L1803:
    bl Lrd_slow
    b L1804
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
    b.hs L1805
L1806:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1807
L1808:
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
L1805:
    bl Ltick_slow4
    b L1806
L1807:
    bl Lrd_slow
    b L1808
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
    b.hs L1809
L1810:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1811
L1812:
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
L1809:
    bl Ltick_slow4
    b L1810
L1811:
    bl Lrd_slow
    b L1812
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
    b.hs L1813
L1814:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1815
L1816:
    ldrb w11, [x10, w9, uxtw]
    and w26, w26, w11
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    orr w27, w27, #0x20
    b Lnext
L1813:
    bl Ltick_slow4
    b L1814
L1815:
    bl Lrd_slow
    b L1816
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
    b.hs L1817
L1818:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1819
L1820:
    ldrb w11, [x10, w9, uxtw]
    eor w26, w26, w11
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    b Lnext
L1817:
    bl Ltick_slow4
    b L1818
L1819:
    bl Lrd_slow
    b L1820
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
    b.hs L1821
L1822:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1823
L1824:
    ldrb w11, [x10, w9, uxtw]
    orr w26, w26, w11
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    b Lnext
L1821:
    bl Ltick_slow4
    b L1822
L1823:
    bl Lrd_slow
    b L1824
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
    b.hs L1825
L1826:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1827
L1828:
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
L1825:
    bl Ltick_slow4
    b L1826
L1827:
    bl Lrd_slow
    b L1828
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
    b.hs L1829
L1830:
    tbnz w27, #7, L1831
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1832
L1833:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1834
L1835:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1836
L1837:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1838
L1839:
    ldrb w12, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w24, w12
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1840
L1841:
L1831:
    b Lnext
L1829:
    bl Ltick_slow4
    b L1830
L1832:
    bl Ltick_slow4
    b L1833
L1834:
    bl Lrd_slow
    b L1835
L1836:
    bl Ltick_slow4
    b L1837
L1838:
    bl Lrd_slow
    b L1839
L1840:
    bl Ltick_slow4
    b L1841
    .p2align 4
Lc_C1:
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1842
L1843:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1844
L1845:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1846
L1847:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1848
L1849:
    ldrb w12, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w28, w12
    b Lnext
L1842:
    bl Ltick_slow4
    b L1843
L1844:
    bl Lrd_slow
    b L1845
L1846:
    bl Ltick_slow4
    b L1847
L1848:
    bl Lrd_slow
    b L1849
    .p2align 4
Lc_C2:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1850
L1851:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1852
L1853:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1854
L1855:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1856
L1857:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    tbnz w27, #7, L1858
    mov w24, w12
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1859
L1860:
L1858:
    b Lnext
L1850:
    bl Ltick_slow4
    b L1851
L1852:
    bl Lrd_slow
    b L1853
L1854:
    bl Ltick_slow4
    b L1855
L1856:
    bl Lrd_slow
    b L1857
L1859:
    bl Ltick_slow4
    b L1860
    .p2align 4
Lc_C3:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1861
L1862:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1863
L1864:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1865
L1866:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1867
L1868:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w24, w12
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1870
L1871:
L1869:
    b Lnext
L1861:
    bl Ltick_slow4
    b L1862
L1863:
    bl Lrd_slow
    b L1864
L1865:
    bl Ltick_slow4
    b L1866
L1867:
    bl Lrd_slow
    b L1868
L1870:
    bl Ltick_slow4
    b L1871
    .p2align 4
Lc_C4:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1872
L1873:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1874
L1875:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1876
L1877:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1878
L1879:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    tbnz w27, #7, L1880
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1881
L1882:
    str w12, [sp, #104]
    mov w12, w24
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1883
L1884:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1885
    strb w11, [x10, w9, uxtw]
L1886:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1887
L1888:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1889
    strb w12, [x10, w9, uxtw]
L1890:
    ldr w24, [sp, #104]
L1880:
    b Lnext
L1872:
    bl Ltick_slow4
    b L1873
L1874:
    bl Lrd_slow
    b L1875
L1876:
    bl Ltick_slow4
    b L1877
L1878:
    bl Lrd_slow
    b L1879
L1881:
    bl Ltick_slow4
    b L1882
L1883:
    bl Ltick_slow4
    b L1884
L1885:
    mov w0, w11
    bl Lwr_slow
    b L1886
L1887:
    bl Ltick_slow4
    b L1888
L1889:
    mov w0, w12
    bl Lwr_slow
    b L1890
    .p2align 4
Lc_C5:
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1891
L1892:
    mov w12, w28
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1893
L1894:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1895
    strb w11, [x10, w9, uxtw]
L1896:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1897
L1898:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1899
    strb w12, [x10, w9, uxtw]
L1900:
    b Lnext
L1891:
    bl Ltick_slow4
    b L1892
L1893:
    bl Ltick_slow4
    b L1894
L1895:
    mov w0, w11
    bl Lwr_slow
    b L1896
L1897:
    bl Ltick_slow4
    b L1898
L1899:
    mov w0, w12
    bl Lwr_slow
    b L1900
    .p2align 4
Lc_C6:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1901
L1902:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1903
L1904:
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
L1901:
    bl Ltick_slow4
    b L1902
L1903:
    bl Lrd_slow
    b L1904
    .p2align 4
Lc_C7:
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1905
L1906:
    mov w12, w24
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1907
L1908:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1909
    strb w11, [x10, w9, uxtw]
L1910:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1911
L1912:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1913
    strb w12, [x10, w9, uxtw]
L1914:
    mov w24, #0
    b Lnext
L1905:
    bl Ltick_slow4
    b L1906
L1907:
    bl Ltick_slow4
    b L1908
L1909:
    mov w0, w11
    bl Lwr_slow
    b L1910
L1911:
    bl Ltick_slow4
    b L1912
L1913:
    mov w0, w12
    bl Lwr_slow
    b L1914
    .p2align 4
Lc_C8:
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1915
L1916:
    tbz w27, #7, L1917
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1918
L1919:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1920
L1921:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1922
L1923:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1924
L1925:
    ldrb w12, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w24, w12
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1926
L1927:
L1917:
    b Lnext
L1915:
    bl Ltick_slow4
    b L1916
L1918:
    bl Ltick_slow4
    b L1919
L1920:
    bl Lrd_slow
    b L1921
L1922:
    bl Ltick_slow4
    b L1923
L1924:
    bl Lrd_slow
    b L1925
L1926:
    bl Ltick_slow4
    b L1927
    .p2align 4
Lc_C9:
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1928
L1929:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1930
L1931:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1932
L1933:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1934
L1935:
    ldrb w12, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w24, w12
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1936
L1937:
    b Lnext
L1928:
    bl Ltick_slow4
    b L1929
L1930:
    bl Lrd_slow
    b L1931
L1932:
    bl Ltick_slow4
    b L1933
L1934:
    bl Lrd_slow
    b L1935
L1936:
    bl Ltick_slow4
    b L1937
    .p2align 4
Lc_CA:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1938
L1939:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1940
L1941:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1942
L1943:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1944
L1945:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    tbz w27, #7, L1946
    mov w24, w12
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1947
L1948:
L1946:
    b Lnext
L1938:
    bl Ltick_slow4
    b L1939
L1940:
    bl Lrd_slow
    b L1941
L1942:
    bl Ltick_slow4
    b L1943
L1944:
    bl Lrd_slow
    b L1945
L1947:
    bl Ltick_slow4
    b L1948
    .p2align 4
Lc_CB:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1949
L1950:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1951
L1952:
    ldrb w9, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    adr x17, Ljt_ccb
    ldrsw x0, [x17, x9, lsl #2]
    add x17, x17, x0
    br x17
L1949:
    bl Ltick_slow4
    b L1950
L1951:
    bl Lrd_slow
    b L1952
    .p2align 4
Lc_CC:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1953
L1954:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1955
L1956:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1957
L1958:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1959
L1960:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    tbz w27, #7, L1961
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1962
L1963:
    str w12, [sp, #104]
    mov w12, w24
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1964
L1965:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1966
    strb w11, [x10, w9, uxtw]
L1967:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1968
L1969:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1970
    strb w12, [x10, w9, uxtw]
L1971:
    ldr w24, [sp, #104]
L1961:
    b Lnext
L1953:
    bl Ltick_slow4
    b L1954
L1955:
    bl Lrd_slow
    b L1956
L1957:
    bl Ltick_slow4
    b L1958
L1959:
    bl Lrd_slow
    b L1960
L1962:
    bl Ltick_slow4
    b L1963
L1964:
    bl Ltick_slow4
    b L1965
L1966:
    mov w0, w11
    bl Lwr_slow
    b L1967
L1968:
    bl Ltick_slow4
    b L1969
L1970:
    mov w0, w12
    bl Lwr_slow
    b L1971
    .p2align 4
Lc_CD:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1972
L1973:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1974
L1975:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1976
L1977:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1978
L1979:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1981
L1982:
    str w12, [sp, #104]
    mov w12, w24
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1983
L1984:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1985
    strb w11, [x10, w9, uxtw]
L1986:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1987
L1988:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1989
    strb w12, [x10, w9, uxtw]
L1990:
    ldr w24, [sp, #104]
L1980:
    b Lnext
L1972:
    bl Ltick_slow4
    b L1973
L1974:
    bl Lrd_slow
    b L1975
L1976:
    bl Ltick_slow4
    b L1977
L1978:
    bl Lrd_slow
    b L1979
L1981:
    bl Ltick_slow4
    b L1982
L1983:
    bl Ltick_slow4
    b L1984
L1985:
    mov w0, w11
    bl Lwr_slow
    b L1986
L1987:
    bl Ltick_slow4
    b L1988
L1989:
    mov w0, w12
    bl Lwr_slow
    b L1990
    .p2align 4
Lc_CE:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1991
L1992:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L1993
L1994:
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
L1991:
    bl Ltick_slow4
    b L1992
L1993:
    bl Lrd_slow
    b L1994
    .p2align 4
Lc_CF:
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1995
L1996:
    mov w12, w24
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L1997
L1998:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L1999
    strb w11, [x10, w9, uxtw]
L2000:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2001
L2002:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2003
    strb w12, [x10, w9, uxtw]
L2004:
    mov w24, #8
    b Lnext
L1995:
    bl Ltick_slow4
    b L1996
L1997:
    bl Ltick_slow4
    b L1998
L1999:
    mov w0, w11
    bl Lwr_slow
    b L2000
L2001:
    bl Ltick_slow4
    b L2002
L2003:
    mov w0, w12
    bl Lwr_slow
    b L2004
    .p2align 4
Lc_D0:
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2005
L2006:
    tbnz w27, #4, L2007
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2008
L2009:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2010
L2011:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2012
L2013:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2014
L2015:
    ldrb w12, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w24, w12
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2016
L2017:
L2007:
    b Lnext
L2005:
    bl Ltick_slow4
    b L2006
L2008:
    bl Ltick_slow4
    b L2009
L2010:
    bl Lrd_slow
    b L2011
L2012:
    bl Ltick_slow4
    b L2013
L2014:
    bl Lrd_slow
    b L2015
L2016:
    bl Ltick_slow4
    b L2017
    .p2align 4
Lc_D1:
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2018
L2019:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2020
L2021:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2022
L2023:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2024
L2025:
    ldrb w12, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w13, w12
    b Lnext
L2018:
    bl Ltick_slow4
    b L2019
L2020:
    bl Lrd_slow
    b L2021
L2022:
    bl Ltick_slow4
    b L2023
L2024:
    bl Lrd_slow
    b L2025
    .p2align 4
Lc_D2:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2026
L2027:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2028
L2029:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2030
L2031:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2032
L2033:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    tbnz w27, #4, L2034
    mov w24, w12
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2035
L2036:
L2034:
    b Lnext
L2026:
    bl Ltick_slow4
    b L2027
L2028:
    bl Lrd_slow
    b L2029
L2030:
    bl Ltick_slow4
    b L2031
L2032:
    bl Lrd_slow
    b L2033
L2035:
    bl Ltick_slow4
    b L2036
    .p2align 4
Lc_D3:
    b Lnext
    .p2align 4
Lc_D4:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2037
L2038:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2039
L2040:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2041
L2042:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2043
L2044:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    tbnz w27, #4, L2045
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2046
L2047:
    str w12, [sp, #104]
    mov w12, w24
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2048
L2049:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2050
    strb w11, [x10, w9, uxtw]
L2051:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2052
L2053:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2054
    strb w12, [x10, w9, uxtw]
L2055:
    ldr w24, [sp, #104]
L2045:
    b Lnext
L2037:
    bl Ltick_slow4
    b L2038
L2039:
    bl Lrd_slow
    b L2040
L2041:
    bl Ltick_slow4
    b L2042
L2043:
    bl Lrd_slow
    b L2044
L2046:
    bl Ltick_slow4
    b L2047
L2048:
    bl Ltick_slow4
    b L2049
L2050:
    mov w0, w11
    bl Lwr_slow
    b L2051
L2052:
    bl Ltick_slow4
    b L2053
L2054:
    mov w0, w12
    bl Lwr_slow
    b L2055
    .p2align 4
Lc_D5:
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2056
L2057:
    mov w12, w13
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2058
L2059:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2060
    strb w11, [x10, w9, uxtw]
L2061:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2062
L2063:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2064
    strb w12, [x10, w9, uxtw]
L2065:
    b Lnext
L2056:
    bl Ltick_slow4
    b L2057
L2058:
    bl Ltick_slow4
    b L2059
L2060:
    mov w0, w11
    bl Lwr_slow
    b L2061
L2062:
    bl Ltick_slow4
    b L2063
L2064:
    mov w0, w12
    bl Lwr_slow
    b L2065
    .p2align 4
Lc_D6:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2066
L2067:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2068
L2069:
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
L2066:
    bl Ltick_slow4
    b L2067
L2068:
    bl Lrd_slow
    b L2069
    .p2align 4
Lc_D7:
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2070
L2071:
    mov w12, w24
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2072
L2073:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2074
    strb w11, [x10, w9, uxtw]
L2075:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2076
L2077:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2078
    strb w12, [x10, w9, uxtw]
L2079:
    mov w24, #16
    b Lnext
L2070:
    bl Ltick_slow4
    b L2071
L2072:
    bl Ltick_slow4
    b L2073
L2074:
    mov w0, w11
    bl Lwr_slow
    b L2075
L2076:
    bl Ltick_slow4
    b L2077
L2078:
    mov w0, w12
    bl Lwr_slow
    b L2079
    .p2align 4
Lc_D8:
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2080
L2081:
    tbz w27, #4, L2082
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2083
L2084:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2085
L2086:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2087
L2088:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2089
L2090:
    ldrb w12, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w24, w12
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2091
L2092:
L2082:
    b Lnext
L2080:
    bl Ltick_slow4
    b L2081
L2083:
    bl Ltick_slow4
    b L2084
L2085:
    bl Lrd_slow
    b L2086
L2087:
    bl Ltick_slow4
    b L2088
L2089:
    bl Lrd_slow
    b L2090
L2091:
    bl Ltick_slow4
    b L2092
    .p2align 4
Lc_D9:
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2093
L2094:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2095
L2096:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2097
L2098:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2099
L2100:
    ldrb w12, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w24, w12
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2101
L2102:
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
    cbnz w17, L2103
    str x21, [x19, #40]
    ldrh w17, [x20, #368]
    add w17, w17, w21
    add x16, x19, #16, lsl #12
    strh w17, [x16, #322]
L2103:
    mov x0, x19
    mov w1, #217
    bl gbc_asm_op
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
L2093:
    bl Ltick_slow4
    b L2094
L2095:
    bl Lrd_slow
    b L2096
L2097:
    bl Ltick_slow4
    b L2098
L2099:
    bl Lrd_slow
    b L2100
L2101:
    bl Ltick_slow4
    b L2102
    .p2align 4
Lc_DA:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2104
L2105:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2106
L2107:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2108
L2109:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2110
L2111:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    tbz w27, #4, L2112
    mov w24, w12
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2113
L2114:
L2112:
    b Lnext
L2104:
    bl Ltick_slow4
    b L2105
L2106:
    bl Lrd_slow
    b L2107
L2108:
    bl Ltick_slow4
    b L2109
L2110:
    bl Lrd_slow
    b L2111
L2113:
    bl Ltick_slow4
    b L2114
    .p2align 4
Lc_DB:
    b Lnext
    .p2align 4
Lc_DC:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2115
L2116:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2117
L2118:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2119
L2120:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2121
L2122:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    tbz w27, #4, L2123
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2124
L2125:
    str w12, [sp, #104]
    mov w12, w24
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2126
L2127:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2128
    strb w11, [x10, w9, uxtw]
L2129:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2130
L2131:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2132
    strb w12, [x10, w9, uxtw]
L2133:
    ldr w24, [sp, #104]
L2123:
    b Lnext
L2115:
    bl Ltick_slow4
    b L2116
L2117:
    bl Lrd_slow
    b L2118
L2119:
    bl Ltick_slow4
    b L2120
L2121:
    bl Lrd_slow
    b L2122
L2124:
    bl Ltick_slow4
    b L2125
L2126:
    bl Ltick_slow4
    b L2127
L2128:
    mov w0, w11
    bl Lwr_slow
    b L2129
L2130:
    bl Ltick_slow4
    b L2131
L2132:
    mov w0, w12
    bl Lwr_slow
    b L2133
    .p2align 4
Lc_DD:
    b Lnext
    .p2align 4
Lc_DE:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2134
L2135:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2136
L2137:
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
L2134:
    bl Ltick_slow4
    b L2135
L2136:
    bl Lrd_slow
    b L2137
    .p2align 4
Lc_DF:
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2138
L2139:
    mov w12, w24
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2140
L2141:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2142
    strb w11, [x10, w9, uxtw]
L2143:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2144
L2145:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2146
    strb w12, [x10, w9, uxtw]
L2147:
    mov w24, #24
    b Lnext
L2138:
    bl Ltick_slow4
    b L2139
L2140:
    bl Ltick_slow4
    b L2141
L2142:
    mov w0, w11
    bl Lwr_slow
    b L2143
L2144:
    bl Ltick_slow4
    b L2145
L2146:
    mov w0, w12
    bl Lwr_slow
    b L2147
    .p2align 4
Lc_E0:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2150
L2151:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2152
L2153:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    cmp w11, #0x80
    b.lo L2148
    cmp w11, #0xFF
    b.eq L2148
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2154
L2155:
    ldr x10, [x20, #272]
    orr w0, w11, #0xFF00
    strb w26, [x10, w0, uxtw]
    b L2149
L2148:
    mov w9, w11
    orr w9, w9, #0xFF00
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2156
L2157:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2158
    strb w26, [x10, w9, uxtw]
L2159:
L2149:
    b Lnext
L2150:
    bl Ltick_slow4
    b L2151
L2152:
    bl Lrd_slow
    b L2153
L2154:
    bl Ltick_slow4
    b L2155
L2156:
    bl Ltick_slow4
    b L2157
L2158:
    mov w0, w26
    bl Lwr_slow
    b L2159
    .p2align 4
Lc_E1:
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2160
L2161:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2162
L2163:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2164
L2165:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2166
L2167:
    ldrb w12, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w14, w12
    b Lnext
L2160:
    bl Ltick_slow4
    b L2161
L2162:
    bl Lrd_slow
    b L2163
L2164:
    bl Ltick_slow4
    b L2165
L2166:
    bl Lrd_slow
    b L2167
    .p2align 4
Lc_E2:
    and w9, w28, #0xFF
    orr w9, w9, #0xFF00
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2168
L2169:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2170
    strb w26, [x10, w9, uxtw]
L2171:
    b Lnext
L2168:
    bl Ltick_slow4
    b L2169
L2170:
    mov w0, w26
    bl Lwr_slow
    b L2171
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
    b.hs L2172
L2173:
    mov w12, w14
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2174
L2175:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2176
    strb w11, [x10, w9, uxtw]
L2177:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2178
L2179:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2180
    strb w12, [x10, w9, uxtw]
L2181:
    b Lnext
L2172:
    bl Ltick_slow4
    b L2173
L2174:
    bl Ltick_slow4
    b L2175
L2176:
    mov w0, w11
    bl Lwr_slow
    b L2177
L2178:
    bl Ltick_slow4
    b L2179
L2180:
    mov w0, w12
    bl Lwr_slow
    b L2181
    .p2align 4
Lc_E6:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2182
L2183:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2184
L2185:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    and w26, w26, w11
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    orr w27, w27, #0x20
    b Lnext
L2182:
    bl Ltick_slow4
    b L2183
L2184:
    bl Lrd_slow
    b L2185
    .p2align 4
Lc_E7:
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2186
L2187:
    mov w12, w24
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2188
L2189:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2190
    strb w11, [x10, w9, uxtw]
L2191:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2192
L2193:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2194
    strb w12, [x10, w9, uxtw]
L2195:
    mov w24, #32
    b Lnext
L2186:
    bl Ltick_slow4
    b L2187
L2188:
    bl Ltick_slow4
    b L2189
L2190:
    mov w0, w11
    bl Lwr_slow
    b L2191
L2192:
    bl Ltick_slow4
    b L2193
L2194:
    mov w0, w12
    bl Lwr_slow
    b L2195
    .p2align 4
Lc_E8:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2196
L2197:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2198
L2199:
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
    b.hs L2200
L2201:
    b Lnext
L2196:
    bl Ltick_slow4
    b L2197
L2198:
    bl Lrd_slow
    b L2199
L2200:
    bl Ltick_slow8
    b L2201
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
    b.hs L2202
L2203:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2204
L2205:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2206
L2207:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2208
L2209:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w9, w12
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2210
L2211:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2212
    strb w26, [x10, w9, uxtw]
L2213:
    b Lnext
L2202:
    bl Ltick_slow4
    b L2203
L2204:
    bl Lrd_slow
    b L2205
L2206:
    bl Ltick_slow4
    b L2207
L2208:
    bl Lrd_slow
    b L2209
L2210:
    bl Ltick_slow4
    b L2211
L2212:
    mov w0, w26
    bl Lwr_slow
    b L2213
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
    b.hs L2214
L2215:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2216
L2217:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    eor w26, w26, w11
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    b Lnext
L2214:
    bl Ltick_slow4
    b L2215
L2216:
    bl Lrd_slow
    b L2217
    .p2align 4
Lc_EF:
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2218
L2219:
    mov w12, w24
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2220
L2221:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2222
    strb w11, [x10, w9, uxtw]
L2223:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2224
L2225:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2226
    strb w12, [x10, w9, uxtw]
L2227:
    mov w24, #40
    b Lnext
L2218:
    bl Ltick_slow4
    b L2219
L2220:
    bl Ltick_slow4
    b L2221
L2222:
    mov w0, w11
    bl Lwr_slow
    b L2223
L2224:
    bl Ltick_slow4
    b L2225
L2226:
    mov w0, w12
    bl Lwr_slow
    b L2227
    .p2align 4
Lc_F0:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2230
L2231:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2232
L2233:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    cmp w11, #0x80
    b.lo L2228
    cmp w11, #0xFF
    b.eq L2228
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2234
L2235:
    ldr x10, [x20, #272]
    orr w0, w11, #0xFF00
    ldrb w26, [x10, w0, uxtw]
    b L2229
L2228:
    mov w9, w11
    orr w9, w9, #0xFF00
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2236
L2237:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2238
L2239:
    ldrb w26, [x10, w9, uxtw]
L2229:
    b Lnext
L2230:
    bl Ltick_slow4
    b L2231
L2232:
    bl Lrd_slow
    b L2233
L2234:
    bl Ltick_slow4
    b L2235
L2236:
    bl Ltick_slow4
    b L2237
L2238:
    bl Lrd_slow
    b L2239
    .p2align 4
Lc_F1:
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2240
L2241:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2242
L2243:
    ldrb w11, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2244
L2245:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2246
L2247:
    ldrb w12, [x10, w9, uxtw]
    add w25, w25, #1
    and w25, w25, #0xFFFF
    orr w12, w11, w12, lsl #8
    lsr w26, w12, #8
    and w27, w12, #0xF0
    b Lnext
L2240:
    bl Ltick_slow4
    b L2241
L2242:
    bl Lrd_slow
    b L2243
L2244:
    bl Ltick_slow4
    b L2245
L2246:
    bl Lrd_slow
    b L2247
    .p2align 4
Lc_F2:
    and w9, w28, #0xFF
    orr w9, w9, #0xFF00
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2248
L2249:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2250
L2251:
    ldrb w26, [x10, w9, uxtw]
    b Lnext
L2248:
    bl Ltick_slow4
    b L2249
L2250:
    bl Lrd_slow
    b L2251
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
    cbnz w17, L2252
    str x21, [x19, #40]
    ldrh w17, [x20, #368]
    add w17, w17, w21
    add x16, x19, #16, lsl #12
    strh w17, [x16, #322]
L2252:
    mov x0, x19
    mov w1, #243
    bl gbc_asm_op
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
    b.hs L2253
L2254:
    orr w12, w27, w26, lsl #8
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2255
L2256:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2257
    strb w11, [x10, w9, uxtw]
L2258:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2259
L2260:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2261
    strb w12, [x10, w9, uxtw]
L2262:
    b Lnext
L2253:
    bl Ltick_slow4
    b L2254
L2255:
    bl Ltick_slow4
    b L2256
L2257:
    mov w0, w11
    bl Lwr_slow
    b L2258
L2259:
    bl Ltick_slow4
    b L2260
L2261:
    mov w0, w12
    bl Lwr_slow
    b L2262
    .p2align 4
Lc_F6:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2263
L2264:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2265
L2266:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w26, w26, w11
    cmp w26, #0
    cset w27, eq
    lsl w27, w27, #7
    b Lnext
L2263:
    bl Ltick_slow4
    b L2264
L2265:
    bl Lrd_slow
    b L2266
    .p2align 4
Lc_F7:
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2267
L2268:
    mov w12, w24
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2269
L2270:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2271
    strb w11, [x10, w9, uxtw]
L2272:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2273
L2274:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2275
    strb w12, [x10, w9, uxtw]
L2276:
    mov w24, #48
    b Lnext
L2267:
    bl Ltick_slow4
    b L2268
L2269:
    bl Ltick_slow4
    b L2270
L2271:
    mov w0, w11
    bl Lwr_slow
    b L2272
L2273:
    bl Ltick_slow4
    b L2274
L2275:
    mov w0, w12
    bl Lwr_slow
    b L2276
    .p2align 4
Lc_F8:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2277
L2278:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2279
L2280:
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
    b.hs L2281
L2282:
    b Lnext
L2277:
    bl Ltick_slow4
    b L2278
L2279:
    bl Lrd_slow
    b L2280
L2281:
    bl Ltick_slow4
    b L2282
    .p2align 4
Lc_F9:
    mov w25, w14
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2283
L2284:
    b Lnext
L2283:
    bl Ltick_slow4
    b L2284
    .p2align 4
Lc_FA:
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2285
L2286:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2287
L2288:
    ldrb w11, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    mov w9, w24
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2289
L2290:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2291
L2292:
    ldrb w12, [x10, w9, uxtw]
    add w24, w24, #1
    and w24, w24, #0xFFFF
    orr w12, w11, w12, lsl #8
    mov w9, w12
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2293
L2294:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2295
L2296:
    ldrb w26, [x10, w9, uxtw]
    b Lnext
L2285:
    bl Ltick_slow4
    b L2286
L2287:
    bl Lrd_slow
    b L2288
L2289:
    bl Ltick_slow4
    b L2290
L2291:
    bl Lrd_slow
    b L2292
L2293:
    bl Ltick_slow4
    b L2294
L2295:
    bl Lrd_slow
    b L2296
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
    cbnz w17, L2297
    str x21, [x19, #40]
    ldrh w17, [x20, #368]
    add w17, w17, w21
    add x16, x19, #16, lsl #12
    strh w17, [x16, #322]
L2297:
    mov x0, x19
    mov w1, #251
    bl gbc_asm_op
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
    b.hs L2298
L2299:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2300
L2301:
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
L2298:
    bl Ltick_slow4
    b L2299
L2300:
    bl Lrd_slow
    b L2301
    .p2align 4
Lc_FF:
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2302
L2303:
    mov w12, w24
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    lsr w11, w12, #8
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2304
L2305:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2306
    strb w11, [x10, w9, uxtw]
L2307:
    sub w25, w25, #1
    and w25, w25, #0xFFFF
    mov w9, w25
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2308
L2309:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2310
    strb w12, [x10, w9, uxtw]
L2311:
    mov w24, #56
    b Lnext
L2302:
    bl Ltick_slow4
    b L2303
L2304:
    bl Ltick_slow4
    b L2305
L2306:
    mov w0, w11
    bl Lwr_slow
    b L2307
L2308:
    bl Ltick_slow4
    b L2309
L2310:
    mov w0, w12
    bl Lwr_slow
    b L2311
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
    b.hs L2312
L2313:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2314
L2315:
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
    b.hs L2316
L2317:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2318
    strb w11, [x10, w9, uxtw]
L2319:
    b Lnext
L2312:
    bl Ltick_slow4
    b L2313
L2314:
    bl Lrd_slow
    b L2315
L2316:
    bl Ltick_slow4
    b L2317
L2318:
    mov w0, w11
    bl Lwr_slow
    b L2319
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
    b.hs L2320
L2321:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2322
L2323:
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
    b.hs L2324
L2325:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2326
    strb w11, [x10, w9, uxtw]
L2327:
    b Lnext
L2320:
    bl Ltick_slow4
    b L2321
L2322:
    bl Lrd_slow
    b L2323
L2324:
    bl Ltick_slow4
    b L2325
L2326:
    mov w0, w11
    bl Lwr_slow
    b L2327
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
    b.hs L2328
L2329:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2330
L2331:
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
    b.hs L2332
L2333:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2334
    strb w11, [x10, w9, uxtw]
L2335:
    b Lnext
L2328:
    bl Ltick_slow4
    b L2329
L2330:
    bl Lrd_slow
    b L2331
L2332:
    bl Ltick_slow4
    b L2333
L2334:
    mov w0, w11
    bl Lwr_slow
    b L2335
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
    b.hs L2336
L2337:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2338
L2339:
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
    b.hs L2340
L2341:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2342
    strb w11, [x10, w9, uxtw]
L2343:
    b Lnext
L2336:
    bl Ltick_slow4
    b L2337
L2338:
    bl Lrd_slow
    b L2339
L2340:
    bl Ltick_slow4
    b L2341
L2342:
    mov w0, w11
    bl Lwr_slow
    b L2343
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
    b.hs L2344
L2345:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2346
L2347:
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
    b.hs L2348
L2349:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2350
    strb w11, [x10, w9, uxtw]
L2351:
    b Lnext
L2344:
    bl Ltick_slow4
    b L2345
L2346:
    bl Lrd_slow
    b L2347
L2348:
    bl Ltick_slow4
    b L2349
L2350:
    mov w0, w11
    bl Lwr_slow
    b L2351
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
    b.hs L2352
L2353:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2354
L2355:
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
    b.hs L2356
L2357:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2358
    strb w11, [x10, w9, uxtw]
L2359:
    b Lnext
L2352:
    bl Ltick_slow4
    b L2353
L2354:
    bl Lrd_slow
    b L2355
L2356:
    bl Ltick_slow4
    b L2357
L2358:
    mov w0, w11
    bl Lwr_slow
    b L2359
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
    b.hs L2360
L2361:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2362
L2363:
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
    b.hs L2364
L2365:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2366
    strb w11, [x10, w9, uxtw]
L2367:
    b Lnext
L2360:
    bl Ltick_slow4
    b L2361
L2362:
    bl Lrd_slow
    b L2363
L2364:
    bl Ltick_slow4
    b L2365
L2366:
    mov w0, w11
    bl Lwr_slow
    b L2367
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
    b.hs L2368
L2369:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2370
L2371:
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
    b.hs L2372
L2373:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2374
    strb w11, [x10, w9, uxtw]
L2375:
    b Lnext
L2368:
    bl Ltick_slow4
    b L2369
L2370:
    bl Lrd_slow
    b L2371
L2372:
    bl Ltick_slow4
    b L2373
L2374:
    mov w0, w11
    bl Lwr_slow
    b L2375
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
    b.hs L2376
L2377:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2378
L2379:
    ldrb w11, [x10, w9, uxtw]
    tst w11, #1
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
L2376:
    bl Ltick_slow4
    b L2377
L2378:
    bl Lrd_slow
    b L2379
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
    b.hs L2380
L2381:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2382
L2383:
    ldrb w11, [x10, w9, uxtw]
    tst w11, #2
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
L2380:
    bl Ltick_slow4
    b L2381
L2382:
    bl Lrd_slow
    b L2383
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
    b.hs L2384
L2385:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2386
L2387:
    ldrb w11, [x10, w9, uxtw]
    tst w11, #4
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
L2384:
    bl Ltick_slow4
    b L2385
L2386:
    bl Lrd_slow
    b L2387
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
    b.hs L2388
L2389:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2390
L2391:
    ldrb w11, [x10, w9, uxtw]
    tst w11, #8
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
L2388:
    bl Ltick_slow4
    b L2389
L2390:
    bl Lrd_slow
    b L2391
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
    b.hs L2392
L2393:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2394
L2395:
    ldrb w11, [x10, w9, uxtw]
    tst w11, #16
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
L2392:
    bl Ltick_slow4
    b L2393
L2394:
    bl Lrd_slow
    b L2395
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
    b.hs L2396
L2397:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2398
L2399:
    ldrb w11, [x10, w9, uxtw]
    tst w11, #32
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
L2396:
    bl Ltick_slow4
    b L2397
L2398:
    bl Lrd_slow
    b L2399
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
    b.hs L2400
L2401:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2402
L2403:
    ldrb w11, [x10, w9, uxtw]
    tst w11, #64
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
L2400:
    bl Ltick_slow4
    b L2401
L2402:
    bl Lrd_slow
    b L2403
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
    b.hs L2404
L2405:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2406
L2407:
    ldrb w11, [x10, w9, uxtw]
    tst w11, #128
    cset w1, eq
    and w27, w27, #0x10
    orr w27, w27, #0x20
    orr w27, w27, w1, lsl #7
    b Lnext
L2404:
    bl Ltick_slow4
    b L2405
L2406:
    bl Lrd_slow
    b L2407
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
    b.hs L2408
L2409:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2410
L2411:
    ldrb w11, [x10, w9, uxtw]
    and w2, w11, #0xFFFFFFFE
    and w11, w2, #0xFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2412
L2413:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2414
    strb w11, [x10, w9, uxtw]
L2415:
    b Lnext
L2408:
    bl Ltick_slow4
    b L2409
L2410:
    bl Lrd_slow
    b L2411
L2412:
    bl Ltick_slow4
    b L2413
L2414:
    mov w0, w11
    bl Lwr_slow
    b L2415
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
    b.hs L2416
L2417:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2418
L2419:
    ldrb w11, [x10, w9, uxtw]
    and w2, w11, #0xFFFFFFFD
    and w11, w2, #0xFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2420
L2421:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2422
    strb w11, [x10, w9, uxtw]
L2423:
    b Lnext
L2416:
    bl Ltick_slow4
    b L2417
L2418:
    bl Lrd_slow
    b L2419
L2420:
    bl Ltick_slow4
    b L2421
L2422:
    mov w0, w11
    bl Lwr_slow
    b L2423
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
    b.hs L2424
L2425:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2426
L2427:
    ldrb w11, [x10, w9, uxtw]
    and w2, w11, #0xFFFFFFFB
    and w11, w2, #0xFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2428
L2429:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2430
    strb w11, [x10, w9, uxtw]
L2431:
    b Lnext
L2424:
    bl Ltick_slow4
    b L2425
L2426:
    bl Lrd_slow
    b L2427
L2428:
    bl Ltick_slow4
    b L2429
L2430:
    mov w0, w11
    bl Lwr_slow
    b L2431
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
    b.hs L2432
L2433:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2434
L2435:
    ldrb w11, [x10, w9, uxtw]
    and w2, w11, #0xFFFFFFF7
    and w11, w2, #0xFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2436
L2437:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2438
    strb w11, [x10, w9, uxtw]
L2439:
    b Lnext
L2432:
    bl Ltick_slow4
    b L2433
L2434:
    bl Lrd_slow
    b L2435
L2436:
    bl Ltick_slow4
    b L2437
L2438:
    mov w0, w11
    bl Lwr_slow
    b L2439
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
    b.hs L2440
L2441:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2442
L2443:
    ldrb w11, [x10, w9, uxtw]
    and w2, w11, #0xFFFFFFEF
    and w11, w2, #0xFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2444
L2445:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2446
    strb w11, [x10, w9, uxtw]
L2447:
    b Lnext
L2440:
    bl Ltick_slow4
    b L2441
L2442:
    bl Lrd_slow
    b L2443
L2444:
    bl Ltick_slow4
    b L2445
L2446:
    mov w0, w11
    bl Lwr_slow
    b L2447
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
    b.hs L2448
L2449:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2450
L2451:
    ldrb w11, [x10, w9, uxtw]
    and w2, w11, #0xFFFFFFDF
    and w11, w2, #0xFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2452
L2453:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2454
    strb w11, [x10, w9, uxtw]
L2455:
    b Lnext
L2448:
    bl Ltick_slow4
    b L2449
L2450:
    bl Lrd_slow
    b L2451
L2452:
    bl Ltick_slow4
    b L2453
L2454:
    mov w0, w11
    bl Lwr_slow
    b L2455
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
    b.hs L2456
L2457:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2458
L2459:
    ldrb w11, [x10, w9, uxtw]
    and w2, w11, #0xFFFFFFBF
    and w11, w2, #0xFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2460
L2461:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2462
    strb w11, [x10, w9, uxtw]
L2463:
    b Lnext
L2456:
    bl Ltick_slow4
    b L2457
L2458:
    bl Lrd_slow
    b L2459
L2460:
    bl Ltick_slow4
    b L2461
L2462:
    mov w0, w11
    bl Lwr_slow
    b L2463
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
    b.hs L2464
L2465:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2466
L2467:
    ldrb w11, [x10, w9, uxtw]
    and w2, w11, #0xFFFFFF7F
    and w11, w2, #0xFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2468
L2469:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2470
    strb w11, [x10, w9, uxtw]
L2471:
    b Lnext
L2464:
    bl Ltick_slow4
    b L2465
L2466:
    bl Lrd_slow
    b L2467
L2468:
    bl Ltick_slow4
    b L2469
L2470:
    mov w0, w11
    bl Lwr_slow
    b L2471
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
    b.hs L2472
L2473:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2474
L2475:
    ldrb w11, [x10, w9, uxtw]
    orr w2, w11, #1
    and w11, w2, #0xFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2476
L2477:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2478
    strb w11, [x10, w9, uxtw]
L2479:
    b Lnext
L2472:
    bl Ltick_slow4
    b L2473
L2474:
    bl Lrd_slow
    b L2475
L2476:
    bl Ltick_slow4
    b L2477
L2478:
    mov w0, w11
    bl Lwr_slow
    b L2479
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
    b.hs L2480
L2481:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2482
L2483:
    ldrb w11, [x10, w9, uxtw]
    orr w2, w11, #2
    and w11, w2, #0xFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2484
L2485:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2486
    strb w11, [x10, w9, uxtw]
L2487:
    b Lnext
L2480:
    bl Ltick_slow4
    b L2481
L2482:
    bl Lrd_slow
    b L2483
L2484:
    bl Ltick_slow4
    b L2485
L2486:
    mov w0, w11
    bl Lwr_slow
    b L2487
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
    b.hs L2488
L2489:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2490
L2491:
    ldrb w11, [x10, w9, uxtw]
    orr w2, w11, #4
    and w11, w2, #0xFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2492
L2493:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2494
    strb w11, [x10, w9, uxtw]
L2495:
    b Lnext
L2488:
    bl Ltick_slow4
    b L2489
L2490:
    bl Lrd_slow
    b L2491
L2492:
    bl Ltick_slow4
    b L2493
L2494:
    mov w0, w11
    bl Lwr_slow
    b L2495
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
    b.hs L2496
L2497:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2498
L2499:
    ldrb w11, [x10, w9, uxtw]
    orr w2, w11, #8
    and w11, w2, #0xFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2500
L2501:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2502
    strb w11, [x10, w9, uxtw]
L2503:
    b Lnext
L2496:
    bl Ltick_slow4
    b L2497
L2498:
    bl Lrd_slow
    b L2499
L2500:
    bl Ltick_slow4
    b L2501
L2502:
    mov w0, w11
    bl Lwr_slow
    b L2503
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
    b.hs L2504
L2505:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2506
L2507:
    ldrb w11, [x10, w9, uxtw]
    orr w2, w11, #16
    and w11, w2, #0xFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2508
L2509:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2510
    strb w11, [x10, w9, uxtw]
L2511:
    b Lnext
L2504:
    bl Ltick_slow4
    b L2505
L2506:
    bl Lrd_slow
    b L2507
L2508:
    bl Ltick_slow4
    b L2509
L2510:
    mov w0, w11
    bl Lwr_slow
    b L2511
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
    b.hs L2512
L2513:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2514
L2515:
    ldrb w11, [x10, w9, uxtw]
    orr w2, w11, #32
    and w11, w2, #0xFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2516
L2517:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2518
    strb w11, [x10, w9, uxtw]
L2519:
    b Lnext
L2512:
    bl Ltick_slow4
    b L2513
L2514:
    bl Lrd_slow
    b L2515
L2516:
    bl Ltick_slow4
    b L2517
L2518:
    mov w0, w11
    bl Lwr_slow
    b L2519
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
    b.hs L2520
L2521:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2522
L2523:
    ldrb w11, [x10, w9, uxtw]
    orr w2, w11, #64
    and w11, w2, #0xFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2524
L2525:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2526
    strb w11, [x10, w9, uxtw]
L2527:
    b Lnext
L2520:
    bl Ltick_slow4
    b L2521
L2522:
    bl Lrd_slow
    b L2523
L2524:
    bl Ltick_slow4
    b L2525
L2526:
    mov w0, w11
    bl Lwr_slow
    b L2527
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
    b.hs L2528
L2529:
    lsr w10, w9, #12
    ldr x10, [x20, x10, lsl #3]
    cbz x10, L2530
L2531:
    ldrb w11, [x10, w9, uxtw]
    orr w2, w11, #128
    and w11, w2, #0xFF
    add x21, x21, #4
    ldr x17, [x20, #296]
    cmp x21, x17
    b.hs L2532
L2533:
    lsr w10, w9, #8
    add x10, x20, x10, lsl #3
    ldr x10, [x10, #1944]
    cbz x10, L2534
    strb w11, [x10, w9, uxtw]
L2535:
    b Lnext
L2528:
    bl Ltick_slow4
    b L2529
L2530:
    bl Lrd_slow
    b L2531
L2532:
    bl Ltick_slow4
    b L2533
L2534:
    mov w0, w11
    bl Lwr_slow
    b L2535
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

    .section .note.GNU-stack,"",%progbits
