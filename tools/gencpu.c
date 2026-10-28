/*
 * gencpu.c - writes the assembly versions of the fast interpreter of the SM83 from one
 * description of the instructions:
 *
 *   src/core/cpu_x64.asm   x86-64, Windows (MASM, ml64)
 *   src/core/cpu_a64.S     ARM64, Android (GNU syntax, through the C preprocessor)
 *   src/core/gbc_asm.h     the offsets of the fields of GBC they use; gbc_exec.c checks them
 *                          against the compiler of each target (a compilation error otherwise)
 *
 *   gencpu [OUTDIR]        (default src/core; run from the root of the project)
 *
 * Built and run on a 64-bit machine; the offsets come from its compiler. The generated files are
 * part of the sources: the builds do not need this program, only after a change of GBC.
 *
 * The model is gbc_exec_c (src/core/gbc_exec.c), statement by statement: the same reads and
 * writes in the same order, the same ticks, the same reloads of the registers after a call into
 * the rest of the core. What the assembly adds:
 *   - two versions of every instruction. A "fast" one, when the instruction starts at least 24
 *     cycles (the longest instruction) before the deadline (GBCFast.limit): its ticks only add
 *     cycles. A "careful" one otherwise, which compares the cycle counter with the deadline at
 *     every tick, like the C version. After a write that went to the rest of the core (which
 *     may move the deadline), the fast version compares too;
 *   - the steps that need more than an instruction (halted CPU, interrupt, pending EI, hook, trace,
 *     end of the frame) are handed to the C version (GBC_EXEC_MORE, see gbc_exec_asm); one look
 *     per step finds them all: the cycle counter against GBCFast.limit (0 when GBCFast.special is
 *     set) and a byte of the table of the hooks (bit 1: the stop address of the run);
 *   - the dispatch through a table of 32-bit offsets, repeated at the end of each fast handler.
 *
 * Registers. x64: A al (ah: LAHF), F r8d, BC ecx (B ch, C cl), DE edx, HL ebx, SP r9d, PC ebp, cycles
 * r14, limit r13, budget r12, g r15, address esi, pointer rdi, temporaries T r10, U r11 (the
 * instructions that name ch dh bh have no REX prefix: memory only through [rdi+rsi]).
 * ARM64: g x19, &g->fast x20, cycles x21, limit x22, budget x23, PC w24, SP w25, A w26, F w27,
 * BC w28, DE w13, HL w14, hooks x15, dispatch table x16, address w9, pointer x10, T w11, U w12.
 */
#include "../src/core/gbc.h"
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

enum { RB, RC, RD, RE, RH, RL, RM, RA, RT, RU, RX };   /* 8-bit operands; RM (HL); RX: the dispatch index */
enum { PBC, PDE, PHL, PSP, PPC, PW };                  /* 16-bit operands; PW: U after fetch16 / pop16 */

static FILE *out;
static int x64;          /* backend */
static int careful;      /* version of the handlers being written */
static int wrote;        /* a write happened in this instruction: its next ticks are compared */
static int nlab;
static char *stubs;      /* out-of-line code of the current handler */
static size_t nstubs, capstubs;

#define OG(f) ((long)offsetof(GBC, f))
#define OX(f) ((long)offsetof(GBCFast, f))
/* a field of GBC.fast: from r15 = g (x64), from x20 = &g->fast (ARM64) */
static long FX(long ox) { return x64 ? OG(fast) + ox : ox; }

static void E(const char *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    fputs("    ", out);
    vfprintf(out, fmt, ap);
    fputc('\n', out);
    va_end(ap);
}

static void LB(const char *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    vfprintf(out, fmt, ap);
    fputs(":\n", out);
    va_end(ap);
}

static void S(const char *fmt, ...)          /* a line of the stubs ("name:" lines are labels) */
{
    char line[256];
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(line, sizeof line, fmt, ap);
    va_end(ap);
    size_t n = strlen(line);
    if (nstubs + n + 8 > capstubs) {
        capstubs = capstubs ? capstubs * 2 : 65536;
        stubs = realloc(stubs, capstubs);
        if (!stubs) { perror("realloc"); exit(1); }
    }
    if (line[n - 1] != ':') { memcpy(stubs + nstubs, "    ", 4); nstubs += 4; }
    memcpy(stubs + nstubs, line, n);
    nstubs += n;
    stubs[nstubs++] = '\n';
}

static void flush_stubs(void)
{
    fwrite(stubs, 1, nstubs, out);
    nstubs = 0;
}

static int lab(void) { return ++nlab; }

/* ------------------------------------------------------------------ registers */

static const char *X8[] = { "ch", "cl", "dh", "dl", "bh", "bl", "?", "al", "r10b", "r11b" };
static const char *XP[] = { "ecx", "edx", "ebx", "r9d", "ebp", "r11d" };
static const char *AP[] = { "w28", "w13", "w14", "w25", "w24", "w12" };

/* ARM64: an 8-bit operand into a w register, a w register into an 8-bit operand */
static void a_get8(const char *dst, int r)
{
    switch (r) {
    case RB: E("lsr %s, w28, #8", dst); break;
    case RC: E("and %s, w28, #0xFF", dst); break;
    case RD: E("lsr %s, w13, #8", dst); break;
    case RE: E("and %s, w13, #0xFF", dst); break;
    case RH: E("lsr %s, w14, #8", dst); break;
    case RL: E("and %s, w14, #0xFF", dst); break;
    case RA: if (strcmp(dst, "w26")) E("mov %s, w26", dst); break;
    case RT: if (strcmp(dst, "w11")) E("mov %s, w11", dst); break;
    case RU: if (strcmp(dst, "w12")) E("mov %s, w12", dst); break;
    default: fprintf(stderr, "a_get8 %d\n", r); exit(1);
    }
}

static void a_set8(int r, const char *src)
{
    switch (r) {
    case RB: E("bfi w28, %s, #8, #8", src); break;
    case RC: E("bfi w28, %s, #0, #8", src); break;
    case RD: E("bfi w13, %s, #8, #8", src); break;
    case RE: E("bfi w13, %s, #0, #8", src); break;
    case RH: E("bfi w14, %s, #8, #8", src); break;
    case RL: E("bfi w14, %s, #0, #8", src); break;
    case RA: E("and w26, %s, #0xFF", src); break;
    case RT: E("and w11, %s, #0xFF", src); break;
    case RU: E("and w12, %s, #0xFF", src); break;
    default: fprintf(stderr, "a_set8 %d\n", r); exit(1);
    }
}

/* ARM64: the w register holding an 8-bit operand, or w0 after a_get8 */
static const char *a_src8(int r)
{
    if (r == RA) return "w26";
    if (r == RT) return "w11";
    if (r == RU) return "w12";
    a_get8("w0", r);
    return "w0";
}

/* ------------------------------------------------------------------ the machine state */

static void flush(void)              /* the registers (and the time unless frozen) into GBC.s */
{
    int n = lab();
    if (x64) {
        E("mov byte ptr [r15+%ld], al", OG(s.a));
        E("mov byte ptr [r15+%ld], r8b", OG(s.f));
        E("mov edi, ecx");
        E("rol di, 8");
        E("mov word ptr [r15+%ld], di", OG(s.b));
        E("mov edi, edx");
        E("rol di, 8");
        E("mov word ptr [r15+%ld], di", OG(s.d));
        E("mov edi, ebx");
        E("rol di, 8");
        E("mov word ptr [r15+%ld], di", OG(s.h));
        E("mov word ptr [r15+%ld], r9w", OG(s.sp));
        E("mov word ptr [r15+%ld], bp", OG(s.pc));
        E("cmp byte ptr [r15+%ld], 0", FX(OX(frozen)));
        E("jne L%d", n);
        E("mov qword ptr [r15+%ld], r14", OG(s.cycles));
        E("movzx edi, word ptr [r15+%ld]", FX(OX(div_base)));
        E("add edi, r14d");
        E("mov word ptr [r15+%ld], di", OG(s.div16));
    } else {
        E("strb w26, [x19, #%ld]", OG(s.a));
        E("strb w27, [x19, #%ld]", OG(s.f));
        E("rev16 w17, w28");
        E("strh w17, [x19, #%ld]", OG(s.b));
        E("rev16 w17, w13");
        E("strh w17, [x19, #%ld]", OG(s.d));
        E("rev16 w17, w14");
        E("strh w17, [x19, #%ld]", OG(s.h));
        E("strh w25, [x19, #%ld]", OG(s.sp));
        E("strh w24, [x19, #%ld]", OG(s.pc));
        E("ldrb w17, [x20, #%ld]", OX(frozen));
        E("cbnz w17, L%d", n);
        E("str x21, [x19, #%ld]", OG(s.cycles));
        E("ldrh w17, [x20, #%ld]", OX(div_base));
        E("add w17, w17, w21");
        E("add x16, x19, #%ld, lsl #12", OG(s.div16) >> 12);
        E("strh w17, [x16, #%ld]", OG(s.div16) & 0xFFF);
    }
    LB("L%d", n);
}

static void reload(void)             /* the registers, the time and the limit from GBC */
{
    if (x64) {
        E("movzx eax, byte ptr [r15+%ld]", OG(s.a));
        E("movzx r8d, byte ptr [r15+%ld]", OG(s.f));
        E("movzx ecx, word ptr [r15+%ld]", OG(s.b));
        E("rol cx, 8");
        E("movzx edx, word ptr [r15+%ld]", OG(s.d));
        E("rol dx, 8");
        E("movzx ebx, word ptr [r15+%ld]", OG(s.h));
        E("rol bx, 8");
        E("movzx r9d, word ptr [r15+%ld]", OG(s.sp));
        E("movzx ebp, word ptr [r15+%ld]", OG(s.pc));
        E("mov r14, qword ptr [r15+%ld]", OG(s.cycles));
        E("mov r13, qword ptr [r15+%ld]", FX(OX(limit)));
    } else {
        E("ldrb w26, [x19, #%ld]", OG(s.a));
        E("ldrb w27, [x19, #%ld]", OG(s.f));
        E("ldrh w17, [x19, #%ld]", OG(s.b));
        E("rev16 w28, w17");
        E("ldrh w17, [x19, #%ld]", OG(s.d));
        E("rev16 w13, w17");
        E("ldrh w17, [x19, #%ld]", OG(s.h));
        E("rev16 w14, w17");
        E("ldrh w25, [x19, #%ld]", OG(s.sp));
        E("ldrh w24, [x19, #%ld]", OG(s.pc));
        E("ldr x21, [x19, #%ld]", OG(s.cycles));
        E("ldr x22, [x20, #%ld]", OX(limit));
        E("ldr x15, [x20, #%ld]", OX(hooks));
        E("adr x16, Ljt_f");
    }
}

/* ------------------------------------------------------------------ time and memory */

static void tick(int t)
{
    if (!careful && !wrote) {
        E(x64 ? "add r14, %d" : "add x21, x21, #%d", t);
        return;
    }
    int st = lab(), back = lab();
    if (x64) {
        E("add r14, %d", t);
        E("cmp r14, qword ptr [r15+%ld]", FX(OX(deadline)));
        E("jae L%d", st);
        S("L%d:", st);
        S("call Ltick_slow%d", t);
        S("jmp L%d", back);
    } else {
        E("add x21, x21, #%d", t);
        E("ldr x17, [x20, #%ld]", OX(deadline));
        E("cmp x21, x17");
        E("b.hs L%d", st);
        S("L%d:", st);
        S("bl Ltick_slow%d", t);
        S("b L%d", back);
    }
    LB("L%d", back);
}

static void addr(int p)              /* the address register = a 16-bit operand */
{
    E(x64 ? "mov esi, %s" : "mov w9, %s", x64 ? XP[p] : AP[p]);
}

static void addr_ff(int r)           /* the address register = 0xFF00 | C or T */
{
    if (x64) {
        E("movzx esi, %s", r == RC ? "cl" : "r10b");
        E("or esi, 65280");
    } else {
        if (r == RC) E("and w9, w28, #0xFF");
        else E("mov w9, w11");
        E("orr w9, w9, #0xFF00");
    }
}

static void rd(int dst)              /* tick, then the byte at the address into dst */
{
    tick(4);
    int st = lab(), back = lab();
    if (x64) {
        E("mov edi, esi");
        E("shr edi, 12");
        E("mov rdi, qword ptr [r15+rdi*8+%ld]", FX(OX(rd)));
        E("test rdi, rdi");
        E("jz L%d", st);
        LB("L%d", back);
        if (dst == RT) E("movzx r10d, byte ptr [rdi+rsi]");
        else if (dst == RU) E("movzx r11d, byte ptr [rdi+rsi]");
        else if (dst == RX) E("movzx esi, byte ptr [rdi+rsi]");
        else E("mov %s, byte ptr [rdi+rsi]", X8[dst]);
        S("L%d:", st);
        S("call Lrd_slow");
        S("jmp L%d", back);
    } else {
        E("lsr w10, w9, #12");
        E("ldr x10, [x20, x10, lsl #3]");
        E("cbz x10, L%d", st);
        LB("L%d", back);
        if (dst == RA) E("ldrb w26, [x10, w9, uxtw]");
        else if (dst == RT) E("ldrb w11, [x10, w9, uxtw]");
        else if (dst == RU) E("ldrb w12, [x10, w9, uxtw]");
        else if (dst == RX) E("ldrb w9, [x10, w9, uxtw]");
        else { E("ldrb w0, [x10, w9, uxtw]"); a_set8(dst, "w0"); }
        S("L%d:", st);
        S("bl Lrd_slow");
        S("b L%d", back);
    }
}

static void wr(int src)              /* tick, then src to the byte at the address */
{
    tick(4);
    int st = lab(), back = lab();
    if (x64) {
        E("mov edi, esi");
        E("shr edi, 8");
        E("mov rdi, qword ptr [r15+rdi*8+%ld]", FX(OX(wrf)));
        E("test rdi, rdi");
        E("jz L%d", st);
        E("mov byte ptr [rdi+rsi], %s", X8[src]);
        S("L%d:", st);
        S("mov byte ptr [rsp+40], %s", X8[src]);
        S("call Lwr_slow");
        S("jmp L%d", back);
    } else {
        const char *v = a_src8(src);
        E("lsr w10, w9, #8");
        E("add x10, x20, x10, lsl #3");
        E("ldr x10, [x10, #%ld]", OX(wrf));
        E("cbz x10, L%d", st);
        E("strb %s, [x10, w9, uxtw]", v);
        S("L%d:", st);
        if (strcmp(v, "w0")) S("mov w0, %s", v);
        S("bl Lwr_slow");
        S("b L%d", back);
    }
    LB("L%d", back);
    wrote = 1;
}

static void pc_inc(void)
{
    if (x64) E("inc bp");
    else { E("add w24, w24, #1"); E("and w24, w24, #0xFFFF"); }
}

static void sp_add(int d)
{
    if (x64) E(d > 0 ? "inc r9w" : "dec r9w");
    else { E(d > 0 ? "add w25, w25, #1" : "sub w25, w25, #1"); E("and w25, w25, #0xFFFF"); }
}

static void fetch8(int dst) { addr(PPC); rd(dst); pc_inc(); }

static void fetch16(void)            /* W (= U) = the 16-bit immediate */
{
    fetch8(RT);
    fetch8(RU);
    if (x64) { E("shl r11d, 8"); E("or r11d, r10d"); }
    else E("orr w12, w11, w12, lsl #8");
}

static void pop16(void)              /* W = the word on the stack */
{
    addr(PSP); rd(RT); sp_add(1);
    addr(PSP); rd(RU); sp_add(1);
    if (x64) { E("shl r11d, 8"); E("or r11d, r10d"); }
    else E("orr w12, w11, w12, lsl #8");
}

static void push16(void)             /* push U (16 bits) */
{
    sp_add(-1);
    addr(PSP);
    if (x64) { E("mov r10d, r11d"); E("shr r10d, 8"); }
    else E("lsr w11, w12, #8");
    wr(RT);
    sp_add(-1);
    addr(PSP);
    wr(RU);
}

static void set_pair(int p, int from)    /* pair p = 16-bit operand from */
{
    if (x64) E("mov %s, %s", XP[p], XP[from]);
    else E("mov %s, %s", AP[p], AP[from]);
}

/* jumps to label n when the condition (0 NZ, 1 Z, 2 NC, 3 C) is false */
static void jfalse(int cc, int n)
{
    if (x64) {
        E("test r8b, %d", cc < 2 ? 128 : 16);
        E("%s L%d", (cc & 1) ? "jz" : "jnz", n);
    } else {
        E("%s w27, #%d, L%d", (cc & 1) ? "tbz" : "tbnz", cc < 2 ? 7 : 4, n);
    }
}

/* an instruction that changes the interrupt state: gbc_asm_op */
static void call_op(int op)
{
    flush();
    if (x64) {
        E("sub rsp, 32");
        E("mov rcx, r15");
        E("mov edx, %d", op);
        E("call gbc_asm_op");
        E("add rsp, 32");
    } else {
        E("mov x0, x19");
        E("mov w1, #%d", op);
        E("bl SYM(gbc_asm_op)");
    }
    reload();
}

/* ------------------------------------------------------------------ operations */

static void x_flags(long table)      /* x64: F from LAHF through a table */
{
    E("lahf");
    E("movzx edi, ah");
    E("movzx r8d, byte ptr [r15+rdi+%ld]", FX(table));
}

static void alu(int op, int src)
{
    if (x64) {
        const char *v = X8[src];
        switch (op) {
        case 0: E("add al, %s", v); x_flags(OX(t_add)); break;
        case 1: E("bt r8d, 4"); E("adc al, %s", v); x_flags(OX(t_add)); break;
        case 2: E("sub al, %s", v); x_flags(OX(t_sub)); break;
        case 3: E("bt r8d, 4"); E("sbb al, %s", v); x_flags(OX(t_sub)); break;
        case 4: E("and al, %s", v); E("movzx edi, al"); E("movzx r8d, byte ptr [r15+rdi+%ld]", FX(OX(t_zh))); break;
        case 5: E("xor al, %s", v); E("movzx edi, al"); E("movzx r8d, byte ptr [r15+rdi+%ld]", FX(OX(t_z))); break;
        case 6: E("or al, %s", v); E("movzx edi, al"); E("movzx r8d, byte ptr [r15+rdi+%ld]", FX(OX(t_z))); break;
        default: E("cmp al, %s", v); x_flags(OX(t_sub)); break;
        }
        return;
    }
    const char *v = a_src8(src);
    if (op >= 4 && op <= 6) {
        E("%s w26, w26, %s", op == 4 ? "and" : op == 5 ? "eor" : "orr", v);
        E("cmp w26, #0");
        E("cset w27, eq");
        E("lsl w27, w27, #7");
        if (op == 4) E("orr w27, w27, #0x20");
        return;
    }
    bool sub = op >= 2;
    if (op == 1 || op == 3) E("ubfx w2, w27, #4, #1");
    E("%s w1, w26, %s", sub ? "sub" : "add", v);
    if (op == 1 || op == 3) E("%s w1, w1, w2", sub ? "sub" : "add");
    E("eor w2, w26, %s", v);
    E("eor w2, w2, w1");                 /* bit 4: carry (borrow) into bit 4, bit 8: out of bit 7 */
    if (op != 7) E("and w26, w1, #0xFF");
    E("and w3, w2, #0x10");
    E("and w2, w2, #0x100");
    E("lsl w3, w3, #1");
    E("orr w27, w3, w2, lsr #4");
    E("tst w1, #0xFF");
    E("cset w3, eq");
    E("orr w27, w27, w3, lsl #7");
    if (sub) E("orr w27, w27, #0x40");
}

static void incdec(int r, int dec)   /* INC / DEC of a register or T */
{
    if (x64) {
        const char *v = X8[r];
        E("%s %s", dec ? "dec" : "inc", v);
        E("movzx edi, %s", v);
        E("and r8d, 16");
        E("movzx edi, byte ptr [r15+rdi+%ld]", FX(dec ? OX(t_dec) : OX(t_inc)));
        E("or r8d, edi");
        return;
    }
    const char *v = a_src8(r);
    E("%s w1, %s, #1", dec ? "sub" : "add", v);
    E("and w1, w1, #0xFF");
    a_set8(r, "w1");
    E("and w27, w27, #0x10");
    if (dec) E("orr w27, w27, #0x40");
    E("cmp w1, #0");
    E("cset w2, eq");
    E("orr w27, w27, w2, lsl #7");
    E("and w2, w1, #0xF");
    E("cmp w2, #%d", dec ? 15 : 0);
    E("cset w2, eq");
    E("orr w27, w27, w2, lsl #5");
}

static void cb_rot(int op, int r)    /* RLC RRC RL RR SLA SRA SWAP SRL of a register or T */
{
    if (x64) {
        const char *v = X8[r];
        static const char *ins[] = { "rol", "ror", "rcl", "rcr", "shl", "sar", "rol", "shr" };
        if (op == 2 || op == 3) E("bt r8d, 4");
        E("%s %s, %d", ins[op], v, op == 6 ? 4 : 1);
        if (op == 6) {
            E("movzx edi, %s", v);
            E("movzx r8d, byte ptr [r15+rdi+%ld]", FX(OX(t_z)));
        } else {
            E("mov r8d, 0");
            E("setc r8b");
            E("shl r8d, 4");
            E("movzx edi, %s", v);
            E("movzx edi, byte ptr [r15+rdi+%ld]", FX(OX(t_z)));
            E("or r8d, edi");
        }
        return;
    }
    const char *v = a_src8(r);         /* result w2, carry w1 */
    switch (op) {
    case 0: E("lsr w1, %s, #7", v); E("lsl w2, %s, #1", v); E("orr w2, w2, w1"); E("and w2, w2, #0xFF"); break;
    case 1: E("and w1, %s, #1", v); E("lsr w2, %s, #1", v); E("orr w2, w2, w1, lsl #7"); break;
    case 2: E("lsr w1, %s, #7", v); E("ubfx w3, w27, #4, #1"); E("lsl w2, %s, #1", v); E("orr w2, w2, w3"); E("and w2, w2, #0xFF"); break;
    case 3: E("and w1, %s, #1", v); E("ubfx w3, w27, #4, #1"); E("lsr w2, %s, #1", v); E("orr w2, w2, w3, lsl #7"); break;
    case 4: E("lsr w1, %s, #7", v); E("lsl w2, %s, #1", v); E("and w2, w2, #0xFF"); break;
    case 5: E("and w1, %s, #1", v); E("and w3, %s, #0x80", v); E("lsr w2, %s, #1", v); E("orr w2, w2, w3"); break;
    case 6: E("mov w1, #0"); E("lsl w2, %s, #4", v); E("orr w2, w2, %s, lsr #4", v); E("and w2, w2, #0xFF"); break;
    default: E("and w1, %s, #1", v); E("lsr w2, %s, #1", v); break;
    }
    a_set8(r, "w2");
    E("cmp w2, #0");
    E("cset w3, eq");
    E("lsl w27, w3, #7");
    E("orr w27, w27, w1, lsl #4");
}

/* ------------------------------------------------------------------ dispatch */

static void dispatch(const char *table, const char *idx)   /* x64: idx esi; ARM64: idx w9 */
{
    if (x64) {
        E("lea rdi, %s", table);
        E("movsxd rsi, dword ptr [rdi+rsi*4]");
        E("add rsi, rdi");
        E("jmp rsi");
    } else if (!strcmp(table, "Ljt_f")) {
        E("ldrsw x17, [x16, x9, lsl #2]");
        E("add x17, x16, x17");
        E("br x17");
    } else {
        E("adr x17, %s", table);
        E("ldrsw x0, [x17, x9, lsl #2]");
        E("add x17, x17, x0");
        E("br x17");
    }
    (void)idx;
}

/* the next opcode at PC (fetch tick already counted) and its handler */
static void fetch_dispatch(const char *table)
{
    int st = lab(), back = lab();
    if (x64) {
        E("mov esi, ebp");
        E("shr esi, 12");
        E("mov rdi, qword ptr [r15+rsi*8+%ld]", FX(OX(rd)));
        E("test rdi, rdi");
        E("jz L%d", st);
        LB("L%d", back);
        E("movzx esi, byte ptr [rdi+rbp]");
        E("inc bp");
        S("L%d:", st);
        S("mov esi, ebp");
        S("call Lrd_slow");
        S("jmp L%d", back);
    } else {
        E("lsr w10, w24, #12");
        E("ldr x10, [x20, x10, lsl #3]");
        E("cbz x10, L%d", st);
        LB("L%d", back);
        E("ldrb w9, [x10, w24, uxtw]");
        E("add w24, w24, #1");
        E("and w24, w24, #0xFFFF");
        S("L%d:", st);
        S("mov w9, w24");
        S("bl Lrd_slow");
        S("b L%d", back);
    }
    dispatch(table, NULL);
}

/* the end of a step and the start of the next one (fast handlers: a copy in each) */
static void next(void)
{
    if (careful) { E(x64 ? "jmp Lnext" : "b Lnext"); return; }
    if (x64) {
        E("cmp r14, r13");
        E("jae Lslow_top");
        E("test byte ptr [r15+rbp+%ld], 3", OG(hookbyte));
        E("jnz Lslow_top");
        E("dec r12");
        E("js Lexit_budget");
        E("add r14, 4");
    } else {
        E("cmp x21, x22");
        E("b.hs Lslow_top");
        E("ldrb w17, [x15, w24, uxtw]");
        E("cbnz w17, Lslow_top");
        E("subs x23, x23, #1");
        E("b.mi Lexit_budget");
        E("add x21, x21, #4");
    }
    fetch_dispatch("Ljt_f");
}

/* ------------------------------------------------------------------ the instructions */

static void gen_op(int op)
{
    if (op >= 0x40 && op < 0x80) {
        int dst = (op >> 3) & 7, src = op & 7;
        if (op == 0x76) call_op(0x76);                        /* HALT */
        else if (src == RM) { addr(PHL); rd(dst); }
        else if (dst == RM) { addr(PHL); wr(src); }
        else if (dst != src) {
            if (x64) E("mov %s, %s", X8[dst], X8[src]);
            else if (dst == RA) a_get8("w26", src);
            else a_set8(dst, a_src8(src));
        }
        return;
    }
    if (op >= 0x80 && op < 0xC0) {
        int src = op & 7;
        if (src == RM) { addr(PHL); rd(RT); src = RT; }
        alu((op >> 3) & 7, src);
        return;
    }
    int cc = (op >> 3) & 3, n;
    switch (op) {
    case 0x01: case 0x11: case 0x21: case 0x31:
        fetch16(); set_pair(op >> 4, PW); break;
    case 0x02: addr(PBC); wr(RA); break;
    case 0x12: addr(PDE); wr(RA); break;
    case 0x22: case 0x32:
        addr(PHL); wr(RA);
        if (x64) { E("lea ebx, [rsi%s]", op == 0x22 ? "+1" : "-1"); E("and ebx, 65535"); }
        else { E("%s w14, w9, #1", op == 0x22 ? "add" : "sub"); E("and w14, w14, #0xFFFF"); }
        break;
    case 0x0A: addr(PBC); rd(RA); break;
    case 0x1A: addr(PDE); rd(RA); break;
    case 0x2A: case 0x3A:
        addr(PHL); rd(RA);
        if (x64) { E("lea ebx, [rsi%s]", op == 0x2A ? "+1" : "-1"); E("and ebx, 65535"); }
        else { E("%s w14, w9, #1", op == 0x2A ? "add" : "sub"); E("and w14, w14, #0xFFFF"); }
        break;
    case 0x03: case 0x13: case 0x23: case 0x33:
    case 0x0B: case 0x1B: case 0x2B: case 0x3B: {
        int p = op >> 4, dec = (op & 8) != 0;
        if (x64) {
            static const char *P16[] = { "cx", "dx", "bx", "r9w" };
            E("%s %s", dec ? "dec" : "inc", P16[p]);
        } else {
            E("%s %s, %s, #1", dec ? "sub" : "add", AP[p], AP[p]);
            E("and %s, %s, #0xFFFF", AP[p], AP[p]);
        }
        tick(4);
        break;
    }
    case 0x04: case 0x0C: case 0x14: case 0x1C: case 0x24: case 0x2C: case 0x34: case 0x3C:
    case 0x05: case 0x0D: case 0x15: case 0x1D: case 0x25: case 0x2D: case 0x35: case 0x3D: {
        int r = (op >> 3) & 7, dec = op & 1;
        if (r == RM) { addr(PHL); rd(RT); incdec(RT, dec); wr(RT); }
        else incdec(r, dec);
        break;
    }
    case 0x06: case 0x0E: case 0x16: case 0x1E: case 0x26: case 0x2E: case 0x36: case 0x3E: {
        int r = (op >> 3) & 7;
        if (r == RM) { fetch8(RT); addr(PHL); wr(RT); }
        else fetch8(r);
        break;
    }
    case 0x07: case 0x0F: case 0x17: case 0x1F:          /* RLCA RRCA RLA RRA */
        if (x64) {
            if (op >= 0x17) E("bt r8d, 4");
            else E("xor r8d, r8d");
            E("%s al, 1", op == 0x07 ? "rol" : op == 0x0F ? "ror" : op == 0x17 ? "rcl" : "rcr");
            if (op >= 0x17) E("mov r8d, 0");
            E("setc r8b");
            E("shl r8d, 4");
        } else {
            if (op == 0x07 || op == 0x17) E("lsr w0, w26, #7");
            else E("and w0, w26, #1");
            if (op == 0x07) { E("lsl w26, w26, #1"); E("orr w26, w26, w0"); E("and w26, w26, #0xFF"); }
            if (op == 0x0F) { E("lsr w26, w26, #1"); E("orr w26, w26, w0, lsl #7"); }
            if (op == 0x17) { E("ubfx w1, w27, #4, #1"); E("lsl w26, w26, #1"); E("orr w26, w26, w1"); E("and w26, w26, #0xFF"); }
            if (op == 0x1F) { E("ubfx w1, w27, #4, #1"); E("lsr w26, w26, #1"); E("orr w26, w26, w1, lsl #7"); }
            E("lsl w27, w0, #4");
        }
        break;
    case 0x08:                                            /* LD (nn),SP */
        fetch16();
        addr(PW);
        if (x64) E("mov r10d, r9d"); else E("and w11, w25, #0xFF");
        wr(RT);
        if (x64) { E("lea esi, [r11+1]"); E("and esi, 65535"); E("mov r10d, r9d"); E("shr r10d, 8"); }
        else { E("add w9, w12, #1"); E("and w9, w9, #0xFFFF"); E("lsr w11, w25, #8"); }
        wr(RT);
        break;
    case 0x09: case 0x19: case 0x29: case 0x39: {         /* ADD HL,rr */
        int p = op >> 4;
        if (x64) {
            E("mov edi, ebx");
            E("xor edi, %s", XP[p]);
            E("add ebx, %s", XP[p]);
            E("xor edi, ebx");                  /* bit 12: carry into bit 12, bit 16: out of bit 15 */
            E("and r8d, 128");
            E("mov esi, edi");
            E("shr edi, 7");
            E("and edi, 32");
            E("shr esi, 12");
            E("and esi, 16");
            E("or r8d, edi");
            E("or r8d, esi");
            E("and ebx, 65535");
        } else {
            E("add w0, w14, %s", AP[p]);
            E("eor w1, w14, %s", AP[p]);
            E("eor w1, w1, w0");
            E("and w27, w27, #0x80");
            E("ubfx w2, w1, #12, #1");
            E("orr w27, w27, w2, lsl #5");
            E("ubfx w2, w1, #16, #1");
            E("orr w27, w27, w2, lsl #4");
            E("and w14, w0, #0xFFFF");
        }
        tick(4);
        break;
    }
    case 0x10: fetch8(RT); call_op(0x10); break;          /* STOP: the speed switch (gbc_asm_op) */
    case 0x18: case 0x20: case 0x28: case 0x30: case 0x38:
        fetch8(RT);
        n = lab();
        if (op != 0x18) jfalse(cc, n);
        if (x64) { E("movsx r10d, r10b"); E("add ebp, r10d"); E("and ebp, 65535"); }
        else { E("sxtb w0, w11"); E("add w24, w24, w0"); E("and w24, w24, #0xFFFF"); }
        tick(4);
        if ((op == 0x28 || op == 0x20) && !careful) {
            /* jr z,-4: the wait loop? jr nz,-8: the copy loop? (Lidle, Lcopy; fast steps only) */
            int st = lab(), back = lab(), d = op == 0x28 ? 4 : 8;
            const char *r = op == 0x28 ? "Lidle" : "Lcopy";
            if (x64) { E("cmp r10d, -%d", d); E("je L%d", st); S("L%d:", st); S("call %s", r); S("jmp L%d", back); }
            else { E("cmn w0, #%d", d); E("b.eq L%d", st); S("L%d:", st); S("bl %s", r); S("b L%d", back); }
            LB("L%d", back);
        }
        LB("L%d", n);
        break;
    case 0x27: {                                          /* DAA */
        int l_add = lab(), l1 = lab(), l2 = lab(), l3 = lab(), l4 = lab(), done = lab(), l5 = lab();
        if (x64) {
            E("movzx edi, al");                 /* av */
            E("mov esi, r8d");
            E("and esi, 16");                   /* carry (0x10) */
            E("test r8b, 64");
            E("jz L%d", l_add);
            E("test r8b, 32");
            E("jz L%d", l1);
            E("sub edi, 6");
            LB("L%d", l1);
            E("test esi, esi");
            E("jz L%d", done);
            E("sub edi, 96");
            E("jmp L%d", done);
            LB("L%d", l_add);
            E("test esi, esi");
            E("jnz L%d", l2);
            E("cmp edi, 153");
            E("jbe L%d", l3);
            LB("L%d", l2);
            E("add edi, 96");
            E("mov esi, 16");
            LB("L%d", l3);
            E("test r8b, 32");
            E("jnz L%d", l4);
            E("mov r10d, edi");
            E("and r10d, 15");
            E("cmp r10d, 9");
            E("jbe L%d", done);
            LB("L%d", l4);
            E("add edi, 6");
            LB("L%d", done);
            E("mov eax, edi");
            E("and r8d, 64");
            E("or r8d, esi");
            E("test al, al");
            E("jnz L%d", l5);
            E("or r8d, 128");
            LB("L%d", l5);
        } else {
            E("mov w0, w26");
            E("ubfx w1, w27, #4, #1");
            E("tbz w27, #6, L%d", l_add);
            E("tbz w27, #5, L%d", l1);
            E("sub w0, w0, #6");
            LB("L%d", l1);
            E("cbz w1, L%d", done);
            E("sub w0, w0, #0x60");
            E("b L%d", done);
            LB("L%d", l_add);
            E("cbnz w1, L%d", l2);
            E("cmp w0, #0x99");
            E("b.ls L%d", l3);
            LB("L%d", l2);
            E("add w0, w0, #0x60");
            E("mov w1, #1");
            LB("L%d", l3);
            E("tbnz w27, #5, L%d", l4);
            E("and w2, w0, #0xF");
            E("cmp w2, #9");
            E("b.ls L%d", done);
            LB("L%d", l4);
            E("add w0, w0, #6");
            LB("L%d", done);
            E("and w26, w0, #0xFF");
            E("and w27, w27, #0x40");
            E("orr w27, w27, w1, lsl #4");
            E("cmp w26, #0");
            E("cset w2, eq");
            E("orr w27, w27, w2, lsl #7");
            (void)l5;
        }
        break;
    }
    case 0x2F:
        if (x64) { E("not al"); E("or r8d, 96"); }
        else { E("eor w26, w26, #0xFF"); E("orr w27, w27, #0x60"); }
        break;
    case 0x37:
        if (x64) { E("and r8d, 128"); E("or r8d, 16"); }
        else { E("and w27, w27, #0x80"); E("orr w27, w27, #0x10"); }
        break;
    case 0x3F:
        if (x64) { E("and r8d, 144"); E("xor r8d, 16"); }
        else { E("mov w0, #0x90"); E("and w27, w27, w0"); E("eor w27, w27, #0x10"); }
        break;
    case 0xC0: case 0xC8: case 0xD0: case 0xD8:           /* RET cc */
        tick(4);
        n = lab();
        jfalse(cc, n);
        pop16();
        set_pair(PPC, PW);
        tick(4);
        LB("L%d", n);
        break;
    case 0xC9: pop16(); set_pair(PPC, PW); tick(4); break;
    case 0xD9: pop16(); set_pair(PPC, PW); tick(4); call_op(0xD9); break;
    case 0xC1: case 0xD1: case 0xE1:
        pop16(); set_pair((op >> 4) & 3, PW); break;
    case 0xF1:
        pop16();
        if (x64) { E("mov eax, r11d"); E("shr eax, 8"); E("mov r8d, r11d"); E("and r8d, 240"); }
        else { E("lsr w26, w12, #8"); E("and w27, w12, #0xF0"); }
        break;
    case 0xC5: case 0xD5: case 0xE5: case 0xF5:
        tick(4);
        if (op == 0xF5) {
            if (x64) { E("movzx r11d, al"); E("shl r11d, 8"); E("or r11d, r8d"); }
            else E("orr w12, w27, w26, lsl #8");
        } else set_pair(PW, (op >> 4) & 3);
        push16();
        break;
    case 0xC2: case 0xCA: case 0xD2: case 0xDA: case 0xC3:
        fetch16();
        n = lab();
        if (op != 0xC3) jfalse(cc, n);
        set_pair(PPC, PW);
        tick(4);
        LB("L%d", n);
        break;
    case 0xE9: set_pair(PPC, PHL); break;
    case 0xC4: case 0xCC: case 0xD4: case 0xDC: case 0xCD:
        fetch16();
        n = lab();
        if (op != 0xCD) jfalse(cc, n);
        tick(4);
        if (x64) { E("mov dword ptr [rsp+48], r11d"); E("mov r11d, ebp"); }
        else { E("str w12, [sp, #104]"); E("mov w12, w24"); }
        push16();
        if (x64) E("mov ebp, dword ptr [rsp+48]"); else E("ldr w24, [sp, #104]");
        LB("L%d", n);
        break;
    case 0xC7: case 0xCF: case 0xD7: case 0xDF: case 0xE7: case 0xEF: case 0xF7: case 0xFF:
        tick(4);
        set_pair(PW, PPC);
        push16();
        E(x64 ? "mov ebp, %d" : "mov w24, #%d", op & 0x38);
        break;
    case 0xC6: case 0xCE: case 0xD6: case 0xDE: case 0xE6: case 0xEE: case 0xF6: case 0xFE:
        fetch8(RT); alu((op >> 3) & 7, RT); break;
    case 0xE0: case 0xF0: {                               /* LDH: high RAM directly (FF80-FFFE) */
        int gen = lab(), done = lab();
        fetch8(RT);
        if (x64) { E("cmp r10d, 128"); E("jb L%d", gen); E("cmp r10d, 255"); E("je L%d", gen); }
        else { E("cmp w11, #0x80"); E("b.lo L%d", gen); E("cmp w11, #0xFF"); E("b.eq L%d", gen); }
        tick(4);
        if (x64) {
            E("mov rdi, qword ptr [r15+%ld]", FX(OX(hramb)));
            E(op == 0xE0 ? "mov byte ptr [rdi+r10+65280], al" : "mov al, byte ptr [rdi+r10+65280]");
            E("jmp L%d", done);
        } else {
            E("ldr x10, [x20, #%ld]", OX(hramb));
            E("orr w0, w11, #0xFF00");
            E(op == 0xE0 ? "strb w26, [x10, w0, uxtw]" : "ldrb w26, [x10, w0, uxtw]");
            E("b L%d", done);
        }
        LB("L%d", gen);
        addr_ff(RT);
        if (op == 0xE0) wr(RA); else rd(RA);
        LB("L%d", done);
        break;
    }
    case 0xE2: addr_ff(RC); wr(RA); break;
    case 0xF2: addr_ff(RC); rd(RA); break;
    case 0xEA: fetch16(); addr(PW); wr(RA); break;
    case 0xFA: fetch16(); addr(PW); rd(RA); break;
    case 0xE8: case 0xF8:                                 /* ADD SP,e  LD HL,SP+e */
        fetch8(RT);
        if (x64) {
            E("mov edi, r9d");
            E("and edi, 255");
            E("add edi, r10d");                 /* bit 8: carry out of bit 7 */
            E("mov esi, r9d");
            E("and esi, 15");
            E("mov r11d, r10d");
            E("and r11d, 15");
            E("add esi, r11d");                 /* bit 4: carry out of bit 3 */
            E("shr edi, 4");
            E("and edi, 16");
            E("shl esi, 1");
            E("and esi, 32");
            E("mov r8d, edi");
            E("or r8d, esi");
            E("movsx r10d, r10b");
            E("add r10d, r9d");
            E("and r10d, 65535");
            E(op == 0xE8 ? "mov r9d, r10d" : "mov ebx, r10d");
        } else {
            E("and w0, w25, #0xFF");
            E("add w0, w0, w11");
            E("and w1, w25, #0xF");
            E("and w2, w11, #0xF");
            E("add w1, w1, w2");
            E("ubfx w0, w0, #8, #1");
            E("ubfx w1, w1, #4, #1");
            E("lsl w27, w0, #4");
            E("orr w27, w27, w1, lsl #5");
            E("sxtb w2, w11");
            E("add w2, w25, w2");
            E("and %s, w2, #0xFFFF", op == 0xE8 ? "w25" : "w14");
        }
        tick(op == 0xE8 ? 8 : 4);
        break;
    case 0xF9: set_pair(PSP, PHL); tick(4); break;
    case 0xF3: case 0xFB: call_op(op); break;
    case 0xCB:
        fetch8(RX);
        dispatch(careful ? "Ljt_ccb" : "Ljt_fcb", NULL);
        return;                           /* the CB handler ends the step */
    default:
        break;                            /* NOP, illegal opcodes (NOP, as gbc_step) */
    }
}

static void gen_cb(int cb)
{
    int r = cb & 7, bit = (cb >> 3) & 7, v = r;
    if (r == RM) { addr(PHL); rd(RT); v = RT; }
    if (cb < 0x40) {
        cb_rot(bit, v);
    } else if (cb < 0x80) {
        if (x64) {
            E("mov edi, 0");
            E("test %s, %d", X8[v], 1 << bit);
            E("setz dil");
            E("shl edi, 7");
            E("and r8d, 16");
            E("or r8d, 32");
            E("or r8d, edi");
        } else {
            const char *s = a_src8(v);
            E("tst %s, #%d", s, 1 << bit);
            E("cset w1, eq");
            E("and w27, w27, #0x10");
            E("orr w27, w27, #0x20");
            E("orr w27, w27, w1, lsl #7");
        }
        return;                           /* BIT: no write */
    } else if (cb < 0xC0) {
        if (x64) E("and %s, %d", X8[v], 255 & ~(1 << bit));
        else { const char *s = a_src8(v); E("and w2, %s, #0x%X", s, 0xFFFFFFFFu & ~(1u << bit)); a_set8(v, "w2"); }
    } else {
        if (x64) E("or %s, %d", X8[v], 1 << bit);
        else { const char *s = a_src8(v); E("orr w2, %s, #%d", s, 1 << bit); a_set8(v, "w2"); }
    }
    if (r == RM) wr(RT);
}

static void handler(const char *prefix, int code, int is_cb)
{
    wrote = 0;
    if (x64) E("ALIGN 16"); else E(".p2align 4");
    LB("L%s_%02X", prefix, code);
    if (is_cb) gen_cb(code); else gen_op(code);
    if (is_cb || code != 0xCB) next();
    flush_stubs();
}

/* ------------------------------------------------------------------ the routine */

/* out-of-line: rd_slow (esi/w9 = address -> rdi/x10 such that [rdi+rsi] is the byte), wr_slow,
 * tick_slow4/8, the checks before a step, the exits */
static void routines(void)
{
    if (x64) {
        /* rd_slow: high RAM, LY and STAT (not frozen: GBCFast.ff44/ff41), OAM, else gbc_read (the
         * state written back: cycles for the I/O) */
        LB("Lrd_slow");
        E("cmp esi, 65408");
        E("jb Lrs1");
        E("cmp esi, 65535");
        E("je Lrs2");
        E("mov rdi, qword ptr [r15+%ld]", FX(OX(hramb)));
        E("ret");
        LB("Lrs1");
        E("cmp esi, 65348");
        E("je Lrs_ly");
        E("cmp esi, 65345");
        E("je Lrs_st");
        E("cmp esi, 65024");
        E("jb Lrs2");
        E("cmp esi, 65184");
        E("jae Lrs2");
        E("mov rdi, qword ptr [r15+%ld]", FX(OX(oamb)));
        E("ret");
        LB("Lrs_ly");
        E("cmp byte ptr [r15+%ld], 0", FX(OX(frozen)));
        E("jne Lrs2");
        E("lea rdi, [r15+%ld]", FX(OX(ff44)));
        E("sub rdi, rsi");
        E("ret");
        LB("Lrs_st");
        E("cmp byte ptr [r15+%ld], 0", FX(OX(frozen)));
        E("jne Lrs2");
        E("lea rdi, [r15+%ld]", FX(OX(ff41)));
        E("sub rdi, rsi");
        E("ret");
        LB("Lrs2");
        flush();
        E("push r10");
        E("push r11");
        E("sub rsp, 40");
        E("mov rcx, r15");
        E("mov edx, esi");
        E("call gbc_read");
        E("add rsp, 40");
        E("pop r11");
        E("pop r10");
        E("mov byte ptr [r15+%ld], al", FX(OX(tmp)));
        reload();
        E("lea rdi, [r15+%ld]", FX(OX(tmp)));
        E("sub rdi, rsi");
        E("ret");

        /* wr_slow: value at [rsp+8+40]; high RAM, OAM, an unwatched byte of a work RAM page with
         * watched bytes, else gbc_write (then the registers again: it may run game code) */
        LB("Lwr_slow");
        E("push rax");
        E("push rcx");
        E("push rdx");
        E("movzx eax, byte ptr [rsp+72]");
        E("cmp esi, 65408");
        E("jb Lws1");
        E("cmp esi, 65535");
        E("je Lws9");
        E("mov rcx, qword ptr [r15+%ld]", FX(OX(hramb)));
        E("mov byte ptr [rcx+rsi], al");
        E("jmp Lws8");
        LB("Lws1");
        E("cmp esi, 65024");
        E("jb Lws2");
        E("cmp esi, 65184");
        E("jae Lws9");
        E("mov rcx, qword ptr [r15+%ld]", FX(OX(oamb)));
        E("mov byte ptr [rcx+rsi], al");
        E("jmp Lws8");
        LB("Lws2");
        E("mov ecx, esi");
        E("and ecx, 57344");
        E("cmp ecx, 32768");
        E("je Lws_v");
        E("cmp ecx, 8192");
        E("je Lws_m");
        E("cmp ecx, 49152");
        E("jne Lws9");
        E("mov ecx, esi");
        E("shr ecx, 12");
        E("mov rcx, qword ptr [r15+rcx*8+%ld]", FX(OX(wr)));
        E("test rcx, rcx");
        E("jz Lws9");
        E("mov edx, esi");
        E("and edx, 8191");
        E("mov rdi, qword ptr [r15+%ld]", FX(OX(watch)));
        E("cmp byte ptr [rdi+rdx], 0");
        E("jne Lws9");
        E("mov byte ptr [rcx+rsi], al");
        LB("Lws8");
        E("pop rdx");
        E("pop rcx");
        E("pop rax");
        E("ret");
        /* video memory (vram_write of gbc_exec.c) */
        LB("Lws_v");
        E("cmp byte ptr [r15+%ld], 0", FX(OX(vfast)));
        E("je Lws9");
        E("mov rcx, qword ptr [r15+%ld]", FX(OX(vlo)));
        E("mov rdx, qword ptr [r15+%ld]", FX(OX(vmir_lo)));
        E("cmp esi, 39936");
        E("jb Lws_v1");
        E("mov rcx, qword ptr [r15+%ld]", FX(OX(vhi)));
        E("mov rdx, qword ptr [r15+%ld]", FX(OX(vmir_hi)));
        LB("Lws_v1");
        E("mov byte ptr [rcx+rsi], al");
        E("test rdx, rdx");
        E("jz Lws8");
        E("cmp esi, dword ptr [r15+%ld]", FX(OX(vmir_a0)));
        E("jb Lws8");
        E("cmp esi, dword ptr [r15+%ld]", FX(OX(vmir_a1)));
        E("jae Lws8");
        E("mov byte ptr [rdx+rsi], al");
        E("jmp Lws8");
        /* ROM bank of an MBC5 (mbc5_write) */
        LB("Lws_m");
        E("cmp byte ptr [r15+%ld], 0", FX(OX(mbc5)));
        E("je Lws9");
        E("movzx ecx, word ptr [r15+%ld]", OG(s.rom_bank));
        E("cmp esi, 12288");
        E("jae Lws_m1");
        E("and ecx, 256");
        E("or ecx, eax");
        E("jmp Lws_m2");
        LB("Lws_m1");
        E("and ecx, 255");
        E("mov edx, eax");
        E("and edx, 1");
        E("shl edx, 8");
        E("or ecx, edx");
        LB("Lws_m2");
        E("mov word ptr [r15+%ld], cx", OG(s.rom_bank));
        E("and ecx, dword ptr [r15+%ld]", OG(rom_mask));
        E("shl rcx, 14");
        E("add rcx, qword ptr [r15+%ld]", OG(rom));
        E("sub rcx, 16384");
        for (int i = 4; i < 8; i++) E("mov qword ptr [r15+%ld], rcx", FX(OX(rd)) + 8 * i);
        E("jmp Lws8");
        LB("Lws9");
        E("pop rdx");
        E("pop rcx");
        E("pop rax");
        flush();
        E("push r10");
        E("push r11");
        E("sub rsp, 40");
        E("mov rcx, r15");
        E("mov edx, esi");
        E("movzx r8d, byte ptr [rsp+104]");    /* 40 + 16 + 8 + 40 */
        E("call gbc_asm_write");
        E("add rsp, 40");
        E("pop r11");
        E("pop r10");
        reload();
        E("ret");

        for (int t = 4; t <= 8; t += 4) {
            LB("Ltick_slow%d", t);
            E("sub r14, %d", t);
            flush();
            E("push r10");
            E("push r11");
            E("sub rsp, 40");
            E("mov rcx, r15");
            E("mov edx, %d", t);
            E("call gbc_asm_tick");
            E("add rsp, 40");
            E("pop r11");
            E("pop r10");
            reload();
            E("ret");
        }

        /* idle: after a jr z,-4 back to pc in a fast step: the wait loop "ld a,[hl] / and a /
         * jr z,-4" with [hl] = 0 (idle_loop of gbc_exec.c). Its next whole iterations before the
         * deadline and the end of the frame, within the budget, are counted at once: 3 steps,
         * 24 cycles each (fast step: nothing special pending, see GBCFast.special) */
        LB("Lidle");
        E("test al, al");
        E("jnz Lid_ret");
        E("cmp r8d, 160");
        E("jne Lid_ret");
        E("mov esi, ebp");
        E("and esi, 4095");
        E("cmp esi, 4092");
        E("ja Lid_ret");
        E("mov esi, ebp");
        E("shr esi, 12");
        E("mov rdi, qword ptr [r15+rsi*8+%ld]", FX(OX(rd)));
        E("test rdi, rdi");
        E("jz Lid_ret");
        E("cmp dword ptr [rdi+rbp], 0FC28A77Eh");
        E("jne Lid_ret");
        E("mov esi, dword ptr [r15+rbp+%ld]", OG(hookbyte));
        E("and esi, 197379");              /* hooks or the stop address on the 3 instructions */
        E("jnz Lid_ret");
        E("mov esi, ebx");
        E("shr esi, 12");
        E("mov rdi, qword ptr [r15+rsi*8+%ld]", FX(OX(rd)));
        E("test rdi, rdi");
        E("jnz Lid_m");
        E("cmp ebx, 65408");
        E("jb Lid_ret");
        E("cmp ebx, 65535");
        E("je Lid_ret");
        E("mov rdi, qword ptr [r15+%ld]", FX(OX(hramb)));
        LB("Lid_m");
        E("cmp byte ptr [rdi+rbx], 0");
        E("jne Lid_ret");
        E("mov rax, qword ptr [r15+%ld]", FX(OX(deadline)));
        E("mov rsi, qword ptr [r15+%ld]", FX(OX(frame_end)));
        E("cmp rsi, rax");
        E("cmovb rax, rsi");
        E("dec rax");
        E("sub rax, r14");                 /* end - 1 - cycles */
        E("jbe Lid_a0");
        E("mov rdi, rdx");
        E("xor edx, edx");
        E("mov esi, 24");
        E("div rsi");                      /* whole iterations before the end */
        E("lea rsi, [rax+rax*2]");
        E("cmp rsi, r12");
        E("jbe Lid_k");
        E("mov rax, r12");                 /* the budget: budget / 3 */
        E("xor edx, edx");
        E("mov esi, 3");
        E("div rsi");
        LB("Lid_k");
        E("mov rdx, rdi");
        E("lea rsi, [rax+rax*2]");
        E("sub r12, rsi");
        E("shl rsi, 3");
        E("add r14, rsi");
        LB("Lid_a0");
        E("xor eax, eax");                 /* A = 0 again */
        LB("Lid_ret");
        E("ret");

        /* copy: after a jr nz,-8 back to pc in a fast step: the copy loop "ld a,[hl+] / ld [de],a /
         * inc de / dec bc / ld a,c / or b / jr nz,-8" (copy_loop of gbc_exec.c). Its next whole
         * iterations (7 steps, 52 cycles) before the deadline, the end of the frame, within the
         * budget, but the last one (jump not taken), byte by byte while both bytes are in the
         * tables (rd, wrf); then A = C | B, F = 0 */
        LB("Lcopy");
        E("cmp ebp, 32768");
        E("jae Lcp_ret");
        E("mov esi, ebp");
        E("and esi, 4095");
        E("cmp esi, 4088");
        E("ja Lcp_ret");
        E("mov esi, ebp");
        E("shr esi, 12");
        E("mov rdi, qword ptr [r15+rsi*8+%ld]", FX(OX(rd)));
        E("test rdi, rdi");
        E("jz Lcp_ret");
        E("mov rsi, 0F820B0790B13122Ah");
        E("cmp qword ptr [rdi+rbp], rsi");
        E("jne Lcp_ret");
        E("mov rsi, qword ptr [r15+rbp+%ld]", OG(hookbyte));
        E("mov rdi, 0003030303030303h");   /* hooks or the stop address on the 7 instructions */
        E("test rsi, rdi");
        E("jnz Lcp_ret");
        E("push rax");
        E("push rdx");
        E("mov rax, qword ptr [r15+%ld]", FX(OX(deadline)));
        E("mov rsi, qword ptr [r15+%ld]", FX(OX(frame_end)));
        E("cmp rsi, rax");
        E("cmovb rax, rsi");
        E("dec rax");
        E("sub rax, r14");
        E("jbe Lcp_none");
        E("xor edx, edx");
        E("mov esi, 52");
        E("div rsi");
        E("mov r10, rax");                 /* iterations before the end */
        E("mov rax, r12");
        E("xor edx, edx");
        E("mov esi, 7");
        E("div rsi");
        E("cmp rax, r10");
        E("cmovb r10, rax");               /* within the budget */
        E("lea eax, [rcx-1]");
        E("movzx eax, ax");
        E("cmp rax, r10");
        E("cmovb r10, rax");               /* but the last one */
        E("pop rdx");
        E("xor r11d, r11d");
        LB("Lcp_loop");
        E("cmp r11, r10");
        E("jae Lcp_end");
        E("mov esi, ebx");
        E("shr esi, 12");
        E("mov rdi, qword ptr [r15+rsi*8+%ld]", FX(OX(rd)));
        E("test rdi, rdi");
        E("jz Lcp_end");
        E("movzx eax, byte ptr [rdi+rbx]");
        E("mov esi, edx");
        E("shr esi, 8");
        E("mov rdi, qword ptr [r15+rsi*8+%ld]", FX(OX(wrf)));
        E("test rdi, rdi");
        E("jz Lcp_end");
        E("mov byte ptr [rdi+rdx], al");
        E("inc bx");
        E("inc dx");
        E("dec cx");
        E("inc r11");
        E("jmp Lcp_loop");
        LB("Lcp_end");
        E("pop rax");
        E("test r11, r11");
        E("jz Lcp_ret");
        E("mov eax, ecx");
        E("or al, ch");                    /* A = C | B, F = 0 */
        E("xor r8d, r8d");
        E("lea rsi, [r11*8]");
        E("sub rsi, r11");
        E("sub r12, rsi");
        E("imul rsi, r11, 52");
        E("add r14, rsi");
        LB("Lcp_ret");
        E("ret");
        LB("Lcp_none");
        E("pop rdx");
        E("pop rax");
        E("ret");

        /* before a step, when the cycle counter reached the limit or a byte of the hooks is set:
         * the checks of gbc_exec_c in its order */
        LB("Lslow_top");
        E("cmp r14, qword ptr [r15+%ld]", FX(OX(frame_end)));
        E("jae Lexit_done");
        E("cmp byte ptr [r15+%ld], 0", FX(OX(special)));
        E("jne Lexit_more");
        E("test byte ptr [r15+rbp+%ld], 1", OG(hookbyte));
        E("jnz Lexit_more");
        E("cmp ebp, dword ptr [r15+%ld]", FX(OX(stop_pc)));
        E("jne Lst1");
        E("cmp r9d, dword ptr [r15+%ld]", FX(OX(stop_sp)));
        E("je Lexit_done");
        LB("Lst1");
        E("dec r12");
        E("js Lexit_budget");
        E("cmp r14, qword ptr [r15+%ld]", FX(OX(dl24)));
        E("jb Lfast_fetch");
        LB("Lcareful_fetch");
        careful = 1; wrote = 0;
        tick(4);
        fetch_dispatch("Ljt_c");
        careful = 0;
        flush_stubs();

        LB("Lnext");
        E("cmp r14, r13");
        E("jae Lslow_top");
        E("test byte ptr [r15+rbp+%ld], 3", OG(hookbyte));
        E("jnz Lslow_top");
        E("dec r12");
        E("js Lexit_budget");
        LB("Lfast_fetch");
        E("add r14, 4");
        fetch_dispatch("Ljt_f");
        flush_stubs();

        static const char *ex[] = { "Lexit_budget", "Lexit_done", "Lexit_more" };
        static const int code[] = { 0, 1, 3 };
        for (int i = 0; i < 3; i++) {
            LB("%s", ex[i]);
            flush();
            E("mov eax, %d", code[i]);
            E("jmp Lepilogue");
        }
        LB("Lepilogue");
        E("mov rdi, qword ptr [rsp+32]");
        E("mov qword ptr [rdi], r12");
        E("add rsp, 56");
        E("pop r15");
        E("pop r14");
        E("pop r13");
        E("pop r12");
        E("pop rsi");
        E("pop rdi");
        E("pop rbp");
        E("pop rbx");
        E("ret");
        return;
    }

    /* ARM64 */
    LB("Lrd_slow");
    E("mov w17, #0xFF80");
    E("cmp w9, w17");
    E("b.lo Lrs1");
    E("mov w17, #0xFFFF");
    E("cmp w9, w17");
    E("b.eq Lrs2");
    E("ldr x10, [x20, #%ld]", OX(hramb));
    E("ret");
    LB("Lrs1");
    E("mov w17, #0xFF44");
    E("cmp w9, w17");
    E("b.eq Lrs_ly");
    E("mov w17, #0xFF41");
    E("cmp w9, w17");
    E("b.eq Lrs_st");
    E("mov w17, #0xFE00");
    E("cmp w9, w17");
    E("b.lo Lrs2");
    E("mov w17, #0xFEA0");
    E("cmp w9, w17");
    E("b.hs Lrs2");
    E("ldr x10, [x20, #%ld]", OX(oamb));
    E("ret");
    LB("Lrs_ly");
    E("ldrb w17, [x20, #%ld]", OX(frozen));
    E("cbnz w17, Lrs2");
    E("add x10, x20, #%ld", OX(ff44));
    E("sub x10, x10, w9, uxtw");
    E("ret");
    LB("Lrs_st");
    E("ldrb w17, [x20, #%ld]", OX(frozen));
    E("cbnz w17, Lrs2");
    E("add x10, x20, #%ld", OX(ff41));
    E("sub x10, x10, w9, uxtw");
    E("ret");
    LB("Lrs2");
    E("stp x30, x11, [sp, #-48]!");
    E("stp x12, x9, [sp, #16]");
    flush();
    E("mov x0, x19");
    E("mov w1, w9");
    E("bl SYM(gbc_read)");
    E("strb w0, [x20, #%ld]", OX(tmp));
    reload();
    E("ldp x12, x9, [sp, #16]");
    E("ldp x30, x11, [sp], #48");
    E("add x10, x20, #%ld", OX(tmp));
    E("sub x10, x10, w9, uxtw");
    E("ret");

    LB("Lwr_slow");                       /* value in w0 */
    E("mov w17, #0xFF80");
    E("cmp w9, w17");
    E("b.lo Lws1");
    E("mov w17, #0xFFFF");
    E("cmp w9, w17");
    E("b.eq Lws9");
    E("ldr x10, [x20, #%ld]", OX(hramb));
    E("strb w0, [x10, w9, uxtw]");
    E("ret");
    LB("Lws1");
    E("mov w17, #0xFE00");
    E("cmp w9, w17");
    E("b.lo Lws2");
    E("mov w17, #0xFEA0");
    E("cmp w9, w17");
    E("b.hs Lws9");
    E("ldr x10, [x20, #%ld]", OX(oamb));
    E("strb w0, [x10, w9, uxtw]");
    E("ret");
    LB("Lws2");
    E("and w17, w9, #0xE000");
    E("cmp w17, #0x8, lsl #12");
    E("b.eq Lws_v");
    E("cmp w17, #0x2, lsl #12");
    E("b.eq Lws_m");
    E("cmp w17, #0xC, lsl #12");
    E("b.ne Lws9");
    E("lsr w10, w9, #12");
    E("add x10, x20, x10, lsl #3");
    E("ldr x10, [x10, #%ld]", OX(wr));
    E("cbz x10, Lws9");
    E("and w17, w9, #0x1FFF");
    E("ldr x1, [x20, #%ld]", OX(watch));
    E("ldrb w17, [x1, w17, uxtw]");
    E("cbnz w17, Lws9");
    E("strb w0, [x10, w9, uxtw]");
    E("ret");
    LB("Lws_v");                          /* video memory (vram_write of gbc_exec.c) */
    E("ldrb w17, [x20, #%ld]", OX(vfast));
    E("cbz w17, Lws9");
    E("ldr x10, [x20, #%ld]", OX(vlo));
    E("ldr x1, [x20, #%ld]", OX(vmir_lo));
    E("mov w17, #0x9C00");
    E("cmp w9, w17");
    E("b.lo Lws_v1");
    E("ldr x10, [x20, #%ld]", OX(vhi));
    E("ldr x1, [x20, #%ld]", OX(vmir_hi));
    LB("Lws_v1");
    E("strb w0, [x10, w9, uxtw]");
    E("cbz x1, Lws_v2");
    E("ldr w17, [x20, #%ld]", OX(vmir_a0));
    E("cmp w9, w17");
    E("b.lo Lws_v2");
    E("ldr w17, [x20, #%ld]", OX(vmir_a1));
    E("cmp w9, w17");
    E("b.hs Lws_v2");
    E("strb w0, [x1, w9, uxtw]");
    LB("Lws_v2");
    E("ret");
    LB("Lws_m");                          /* ROM bank of an MBC5 (mbc5_write) */
    E("ldrb w17, [x20, #%ld]", OX(mbc5));
    E("cbz w17, Lws9");
    E("ldrh w1, [x19, #%ld]", OG(s.rom_bank));
    E("mov w17, #0x3000");
    E("cmp w9, w17");
    E("b.hs Lws_m1");
    E("and w1, w1, #0x100");
    E("and w2, w0, #0xFF");
    E("orr w1, w1, w2");
    E("b Lws_m2");
    LB("Lws_m1");
    E("and w1, w1, #0xFF");
    E("and w2, w0, #1");
    E("orr w1, w1, w2, lsl #8");
    LB("Lws_m2");
    E("strh w1, [x19, #%ld]", OG(s.rom_bank));
    E("ldr w2, [x19, #%ld]", OG(rom_mask));
    E("and w1, w1, w2");
    E("ldr x2, [x19, #%ld]", OG(rom));
    E("add x2, x2, x1, lsl #14");
    E("sub x2, x2, #0x4000");
    E("stp x2, x2, [x20, #%ld]", OX(rd) + 32);
    E("stp x2, x2, [x20, #%ld]", OX(rd) + 48);
    E("ret");
    LB("Lws9");
    E("stp x30, x11, [sp, #-48]!");
    E("stp x12, x9, [sp, #16]");
    E("str x0, [sp, #32]");
    flush();
    E("mov x0, x19");
    E("mov w1, w9");
    E("ldrb w2, [sp, #32]");
    E("bl SYM(gbc_asm_write)");
    reload();
    E("ldp x12, x9, [sp, #16]");
    E("ldp x30, x11, [sp], #48");
    E("ret");

    for (int t = 4; t <= 8; t += 4) {
        LB("Ltick_slow%d", t);
        E("sub x21, x21, #%d", t);
        E("stp x30, x11, [sp, #-48]!");
        E("stp x12, x9, [sp, #16]");
        flush();
        E("mov x0, x19");
        E("mov w1, #%d", t);
        E("bl SYM(gbc_asm_tick)");
        reload();
        E("ldp x12, x9, [sp, #16]");
        E("ldp x30, x11, [sp], #48");
        E("ret");
    }

    LB("Lidle");                          /* the wait loop (see the x64 version) */
    E("cbnz w26, Lid_ret");
    E("cmp w27, #0xA0");
    E("b.ne Lid_ret");
    E("and w0, w24, #0xFFF");
    E("cmp w0, #0xFFC");
    E("b.hi Lid_ret");
    E("lsr w0, w24, #12");
    E("ldr x0, [x20, x0, lsl #3]");
    E("cbz x0, Lid_ret");
    E("ldr w1, [x0, w24, uxtw]");
    E("mov w2, #0xA77E");
    E("movk w2, #0xFC28, lsl #16");
    E("cmp w1, w2");
    E("b.ne Lid_ret");
    E("ldr w1, [x15, w24, uxtw]");
    E("and w1, w1, #0xFFFFFF");
    E("tst w1, #0x03030303");             /* hooks or the stop address on the 3 instructions */
    E("b.ne Lid_ret");
    E("lsr w0, w14, #12");
    E("ldr x0, [x20, x0, lsl #3]");
    E("cbnz x0, Lid_m");
    E("mov w1, #0xFF80");
    E("cmp w14, w1");
    E("b.lo Lid_ret");
    E("mov w1, #0xFFFF");
    E("cmp w14, w1");
    E("b.eq Lid_ret");
    E("ldr x0, [x20, #%ld]", OX(hramb));
    LB("Lid_m");
    E("ldrb w1, [x0, w14, uxtw]");
    E("cbnz w1, Lid_ret");
    E("ldr x0, [x20, #%ld]", OX(deadline));
    E("ldr x1, [x20, #%ld]", OX(frame_end));
    E("cmp x1, x0");
    E("csel x0, x1, x0, lo");
    E("sub x0, x0, #1");
    E("subs x0, x0, x21");                /* end - 1 - cycles */
    E("b.ls Lid_ret");
    E("mov x1, #24");
    E("udiv x0, x0, x1");                 /* whole iterations before the end */
    E("mov x1, #3");
    E("udiv x2, x23, x1");                /* and within the budget */
    E("cmp x0, x2");
    E("csel x0, x2, x0, hi");
    E("add x1, x0, x0, lsl #1");
    E("sub x23, x23, x1");
    E("add x21, x21, x1, lsl #3");
    LB("Lid_ret");
    E("ret");

    LB("Lcopy");                          /* the copy loop (see the x64 version) */
    E("mov w0, #0x8000");
    E("cmp w24, w0");
    E("b.hs Lcp_ret");
    E("and w0, w24, #0xFFF");
    E("cmp w0, #0xFF8");
    E("b.hi Lcp_ret");
    E("lsr w0, w24, #12");
    E("ldr x0, [x20, x0, lsl #3]");
    E("cbz x0, Lcp_ret");
    E("ldr x1, [x0, w24, uxtw]");
    E("mov x2, #0x122A");
    E("movk x2, #0x0B13, lsl #16");
    E("movk x2, #0xB079, lsl #32");
    E("movk x2, #0xF820, lsl #48");
    E("cmp x1, x2");
    E("b.ne Lcp_ret");
    E("ldr x1, [x15, w24, uxtw]");
    E("mov x2, #0x0303");
    E("movk x2, #0x0303, lsl #16");
    E("movk x2, #0x0303, lsl #32");
    E("movk x2, #0x0003, lsl #48");
    E("tst x1, x2");                      /* hooks or the stop address on the 7 instructions */
    E("b.ne Lcp_ret");
    E("ldr x0, [x20, #%ld]", OX(deadline));
    E("ldr x1, [x20, #%ld]", OX(frame_end));
    E("cmp x1, x0");
    E("csel x0, x1, x0, lo");
    E("sub x0, x0, #1");
    E("subs x0, x0, x21");
    E("b.ls Lcp_ret");
    E("mov x1, #52");
    E("udiv x3, x0, x1");                 /* iterations before the end */
    E("mov x1, #7");
    E("udiv x2, x23, x1");
    E("cmp x2, x3");
    E("csel x3, x2, x3, lo");             /* within the budget */
    E("sub w2, w28, #1");
    E("and w2, w2, #0xFFFF");
    E("cmp x2, x3");
    E("csel x3, x2, x3, lo");             /* but the last one */
    E("mov x4, #0");
    LB("Lcp_loop");
    E("cmp x4, x3");
    E("b.hs Lcp_end");
    E("lsr w0, w14, #12");
    E("ldr x0, [x20, x0, lsl #3]");
    E("cbz x0, Lcp_end");
    E("ldrb w1, [x0, w14, uxtw]");
    E("lsr w0, w13, #8");
    E("add x0, x20, x0, lsl #3");
    E("ldr x0, [x0, #%ld]", OX(wrf));
    E("cbz x0, Lcp_end");
    E("strb w1, [x0, w13, uxtw]");
    E("add w14, w14, #1");
    E("and w14, w14, #0xFFFF");
    E("add w13, w13, #1");
    E("and w13, w13, #0xFFFF");
    E("sub w28, w28, #1");
    E("and w28, w28, #0xFFFF");
    E("add x4, x4, #1");
    E("b Lcp_loop");
    LB("Lcp_end");
    E("cbz x4, Lcp_ret");
    E("lsr w0, w28, #8");
    E("orr w26, w0, w28");
    E("and w26, w26, #0xFF");             /* A = C | B, F = 0 */
    E("mov w27, #0");
    E("lsl x0, x4, #3");
    E("sub x0, x0, x4");
    E("sub x23, x23, x0");
    E("mov x1, #52");
    E("madd x21, x4, x1, x21");
    LB("Lcp_ret");
    E("ret");

    LB("Lslow_top");
    E("ldr x17, [x20, #%ld]", OX(frame_end));
    E("cmp x21, x17");
    E("b.hs Lexit_done");
    E("ldrb w17, [x20, #%ld]", OX(special));
    E("cbnz w17, Lexit_more");
    E("ldrb w17, [x15, w24, uxtw]");
    E("tbnz w17, #0, Lexit_more");
    E("ldr w17, [x20, #%ld]", OX(stop_pc));
    E("cmp w24, w17");
    E("b.ne Lst1");
    E("ldr w17, [x20, #%ld]", OX(stop_sp));
    E("cmp w25, w17");
    E("b.eq Lexit_done");
    LB("Lst1");
    E("subs x23, x23, #1");
    E("b.mi Lexit_budget");
    E("ldr x17, [x20, #%ld]", OX(dl24));
    E("cmp x21, x17");
    E("b.lo Lfast_fetch");
    LB("Lcareful_fetch");
    careful = 1; wrote = 0;
    tick(4);
    fetch_dispatch("Ljt_c");
    careful = 0;
    flush_stubs();

    LB("Lnext");
    E("cmp x21, x22");
    E("b.hs Lslow_top");
    E("ldrb w17, [x15, w24, uxtw]");
    E("cbnz w17, Lslow_top");
    E("subs x23, x23, #1");
    E("b.mi Lexit_budget");
    LB("Lfast_fetch");
    E("add x21, x21, #4");
    fetch_dispatch("Ljt_f");
    flush_stubs();

    static const char *ex[] = { "Lexit_budget", "Lexit_done", "Lexit_more" };
    static const int code[] = { 0, 1, 3 };
    for (int i = 0; i < 3; i++) {
        LB("%s", ex[i]);
        flush();
        E("mov w0, #%d", code[i]);
        E("b Lepilogue");
    }
    LB("Lepilogue");
    E("ldr x1, [sp, #96]");
    E("str x23, [x1]");
    E("ldp x19, x20, [sp, #16]");
    E("ldp x21, x22, [sp, #32]");
    E("ldp x23, x24, [sp, #48]");
    E("ldp x25, x26, [sp, #64]");
    E("ldp x27, x28, [sp, #80]");
    E("ldp x29, x30, [sp], #112");
    E("ret");
}

static void tables(void)
{
    static const char *name[] = { "f", "c", "fcb", "ccb" };
    for (int t = 0; t < 4; t++) {
        if (x64) E("ALIGN 4"); else E(".p2align 2");
        LB("Ljt_%s", name[t]);
        for (int i = 0; i < 256; i++)
            E(x64 ? "DD L%s_%02X - Ljt_%s" : ".word L%s_%02X - Ljt_%s", name[t], i, name[t]);
    }
}

static void write_asm(const char *path)
{
    out = fopen(path, "wb");             /* LF line ends on every machine */
    if (!out) { perror(path); exit(1); }
    nlab = 0;
    if (x64) {
        fprintf(out, "; cpu_x64.asm - the fast interpreter of the SM83 for x86-64 (Windows), written by\n"
                     "; tools/gencpu.c from its description of the instructions: do not edit, see that file.\n"
                     "; int gbc_cpu_run(GBC *g, int64_t *budget): see gbc_exec_asm (src/core/gbc_exec.c).\n\n");
        fprintf(out, "OPTION CASEMAP:NONE\n\nEXTERN gbc_read:PROC\nEXTERN gbc_asm_tick:PROC\n"
                     "EXTERN gbc_asm_write:PROC\nEXTERN gbc_asm_op:PROC\n\n.CODE\n\n");
        fprintf(out, "gbc_cpu_run PROC FRAME\n");
        static const char *saved[] = { "rbx", "rbp", "rdi", "rsi", "r12", "r13", "r14", "r15" };
        for (int i = 0; i < 8; i++) { E("push %s", saved[i]); E(".pushreg %s", saved[i]); }
        E("sub rsp, 56");                 /* [rsp+32] budget pointer, [rsp+40] value, [rsp+48] call target */
        E(".allocstack 56");
        E(".endprolog");
        E("mov r15, rcx");
        E("mov qword ptr [rsp+32], rdx");
        E("mov r12, qword ptr [rdx]");
        reload();
        E("jmp Lnext");
    } else {
        fprintf(out, "// cpu_a64.S - the fast interpreter of the SM83 for ARM64 (Android, iPhone, Mac), written by\n"
                     "// tools/gencpu.c from its description of the instructions: do not edit, see that file.\n"
                     "// int gbc_cpu_run(GBC *g, int64_t *budget): see gbc_exec_asm (src/core/gbc_exec.c).\n"
                     "// ELF (Android, Linux) or Mach-O (Apple: the C names with an underscore; x18 is never used,\n"
                     "// the platform's register there).\n\n");
        fprintf(out, "#ifdef __APPLE__\n#define SYM(x) _##x\n#else\n#define SYM(x) x\n#endif\n"
                     "    .text\n    .p2align 4\n    .globl SYM(gbc_cpu_run)\n"
                     "#ifdef __APPLE__\n    .private_extern SYM(gbc_cpu_run)\n#else\n"
                     "    .hidden gbc_cpu_run\n    .type gbc_cpu_run, %%function\n#endif\n");
        LB("SYM(gbc_cpu_run)");
        E("stp x29, x30, [sp, #-112]!");  /* [sp+96] budget pointer, [sp+104] call target */
        E("mov x29, sp");
        E("stp x19, x20, [sp, #16]");
        E("stp x21, x22, [sp, #32]");
        E("stp x23, x24, [sp, #48]");
        E("stp x25, x26, [sp, #64]");
        E("stp x27, x28, [sp, #80]");
        E("str x1, [sp, #96]");
        E("mov x19, x0");
        E("add x20, x0, #%ld, lsl #12", OG(fast) >> 12);
        E("add x20, x20, #%ld", OG(fast) & 0xFFF);
        E("ldr x23, [x1]");
        reload();
        E("b Lnext");
    }
    routines();
    for (int c = 0; c < 2; c++) {
        careful = c;
        for (int op = 0; op < 256; op++) handler(c ? "c" : "f", op, 0);
        for (int cb = 0; cb < 256; cb++) handler(c ? "ccb" : "fcb", cb, 1);
    }
    careful = 0;
    tables();
    if (x64) fprintf(out, "\ngbc_cpu_run ENDP\n\nEND\n");
    /* ELF: the code needs no executable stack */
    else fprintf(out, "\n#ifndef __APPLE__\n    .section .note.GNU-stack,\"\",%%progbits\n#endif\n");
    fclose(out);
}

/* ------------------------------------------------------------------ the offsets */

static void write_offsets(const char *path)
{
    FILE *f = fopen(path, "wb");
    if (!f) { perror(path); exit(1); }
    fprintf(f, "/* gbc_asm.h - written by tools/gencpu.c: the offsets of the fields of GBC used by the\n"
               " * assembly versions of the interpreter (cpu_x64.asm, cpu_a64.S), as the compiler of the\n"
               " * machine that wrote them laid GBC out. Included by gbc_exec.c, where an offset that differs\n"
               " * on a target stops the compilation: run gencpu again (and look at the layout of GBC). */\n"
               "#ifndef GBC_ASM_H\n#define GBC_ASM_H\n\n#include <stddef.h>\n\n"
               "#define GBC_ASM_CHECK(name, expr, value) typedef char gbc_asm_check_##name[(expr) == (value) ? 1 : -1];\n\n");
#define CK(name, expr) fprintf(f, "GBC_ASM_CHECK(%s, %s, %ld)\n", name, #expr, (long)(expr))
    CK("a", offsetof(GBC, s.a)); CK("f", offsetof(GBC, s.f)); CK("b", offsetof(GBC, s.b)); CK("c", offsetof(GBC, s.c));
    CK("d", offsetof(GBC, s.d)); CK("e", offsetof(GBC, s.e)); CK("h", offsetof(GBC, s.h)); CK("l", offsetof(GBC, s.l));
    CK("sp", offsetof(GBC, s.sp)); CK("pc", offsetof(GBC, s.pc)); CK("cycles", offsetof(GBC, s.cycles));
    CK("div16", offsetof(GBC, s.div16)); CK("hookbyte", offsetof(GBC, hookbyte)); CK("fast", offsetof(GBC, fast));
    CK("rd", offsetof(GBCFast, rd)); CK("wr", offsetof(GBCFast, wr)); CK("wrf", offsetof(GBCFast, wrf));
    CK("oamb", offsetof(GBCFast, oamb)); CK("hramb", offsetof(GBCFast, hramb)); CK("watch", offsetof(GBCFast, watch));
    CK("hooks", offsetof(GBCFast, hooks)); CK("deadline", offsetof(GBCFast, deadline)); CK("dl24", offsetof(GBCFast, dl24));
    CK("frame_end", offsetof(GBCFast, frame_end)); CK("limit", offsetof(GBCFast, limit));
    CK("div_base", offsetof(GBCFast, div_base)); CK("special", offsetof(GBCFast, special));
    CK("frozen", offsetof(GBCFast, frozen)); CK("tmp", offsetof(GBCFast, tmp)); CK("stop_pc", offsetof(GBCFast, stop_pc));
    CK("stop_sp", offsetof(GBCFast, stop_sp)); CK("t_add", offsetof(GBCFast, t_add)); CK("t_sub", offsetof(GBCFast, t_sub));
    CK("t_inc", offsetof(GBCFast, t_inc)); CK("t_dec", offsetof(GBCFast, t_dec)); CK("t_z", offsetof(GBCFast, t_z));
    CK("t_zh", offsetof(GBCFast, t_zh)); CK("vlo", offsetof(GBCFast, vlo)); CK("vhi", offsetof(GBCFast, vhi));
    CK("vmir_lo", offsetof(GBCFast, vmir_lo)); CK("vmir_hi", offsetof(GBCFast, vmir_hi)); CK("vmir_a0", offsetof(GBCFast, vmir_a0));
    CK("vmir_a1", offsetof(GBCFast, vmir_a1)); CK("vfast", offsetof(GBCFast, vfast)); CK("mbc5", offsetof(GBCFast, mbc5));
    CK("ff41", offsetof(GBCFast, ff41)); CK("ff44", offsetof(GBCFast, ff44)); CK("rom_bank", offsetof(GBC, s.rom_bank));
    CK("rom", offsetof(GBC, rom)); CK("rom_mask", offsetof(GBC, rom_mask)); CK("sizes", sizeof(GBCState) + sizeof(GBCFast));
#undef CK
    fprintf(f, "\n#endif\n");
    fclose(f);
}

int main(int argc, char **argv)
{
    const char *dir = argc > 1 ? argv[1] : "src/core";
    char path[1024];
    /* what the code relies on */
    if (OX(rd) != 0 || OG(s.b) + 1 != OG(s.c) || OG(s.d) + 1 != OG(s.e) || OG(s.h) + 1 != OG(s.l) ||
        (OG(s.b) & 1) || (OG(s.d) & 1) || (OG(s.h) & 1) || (OG(s.div16) & 1) || (OG(s.cycles) & 7) ||
        OG(s.cycles) > 32760 || OG(s.pc) > 8190 || OX(t_zh) > 4095 || sizeof(void *) != 8) {
        fprintf(stderr, "gencpu: unexpected layout of GBC\n");
        return 1;
    }
    snprintf(path, sizeof path, "%s/gbc_asm.h", dir);
    write_offsets(path);
    x64 = 1;
    snprintf(path, sizeof path, "%s/cpu_x64.asm", dir);
    write_asm(path);
    x64 = 0;
    snprintf(path, sizeof path, "%s/cpu_a64.S", dir);
    write_asm(path);
    printf("gencpu: %s/gbc_asm.h, cpu_x64.asm, cpu_a64.S\n", dir);
    return 0;
}
