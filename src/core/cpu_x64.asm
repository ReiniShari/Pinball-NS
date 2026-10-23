; cpu_x64.asm - the fast interpreter of the SM83 for x86-64 (Windows), written by
; tools/gencpu.c from its description of the instructions: do not edit, see that file.
; int gbc_cpu_run(GBC *g, int64_t *budget): see gbc_exec_asm (src/core/gbc_exec.c).

OPTION CASEMAP:NONE

EXTERN gbc_read:PROC
EXTERN gbc_asm_tick:PROC
EXTERN gbc_asm_write:PROC
EXTERN gbc_asm_op:PROC

.CODE

gbc_cpu_run PROC FRAME
    push rbx
    .pushreg rbx
    push rbp
    .pushreg rbp
    push rdi
    .pushreg rdi
    push rsi
    .pushreg rsi
    push r12
    .pushreg r12
    push r13
    .pushreg r13
    push r14
    .pushreg r14
    push r15
    .pushreg r15
    sub rsp, 56
    .allocstack 56
    .endprolog
    mov r15, rcx
    mov qword ptr [rsp+32], rdx
    mov r12, qword ptr [rdx]
    movzx eax, byte ptr [r15+24]
    movzx r8d, byte ptr [r15+25]
    movzx ecx, word ptr [r15+26]
    rol cx, 8
    movzx edx, word ptr [r15+28]
    rol dx, 8
    movzx ebx, word ptr [r15+30]
    rol bx, 8
    movzx r9d, word ptr [r15+32]
    movzx ebp, word ptr [r15+34]
    mov r14, qword ptr [r15+40]
    mov r13, qword ptr [r15+572608]
    jmp Lnext
Lrd_slow:
    cmp esi, 65408
    jb Lrs1
    cmp esi, 65535
    je Lrs2
    mov rdi, qword ptr [r15+572560]
    ret
Lrs1:
    cmp esi, 65348
    je Lrs_ly
    cmp esi, 65345
    je Lrs_st
    cmp esi, 65024
    jb Lrs2
    cmp esi, 65184
    jae Lrs2
    mov rdi, qword ptr [r15+572552]
    ret
Lrs_ly:
    cmp byte ptr [r15+572659], 0
    jne Lrs2
    lea rdi, [r15+572665]
    sub rdi, rsi
    ret
Lrs_st:
    cmp byte ptr [r15+572659], 0
    jne Lrs2
    lea rdi, [r15+572664]
    sub rdi, rsi
    ret
Lrs2:
    mov byte ptr [r15+24], al
    mov byte ptr [r15+25], r8b
    mov edi, ecx
    rol di, 8
    mov word ptr [r15+26], di
    mov edi, edx
    rol di, 8
    mov word ptr [r15+28], di
    mov edi, ebx
    rol di, 8
    mov word ptr [r15+30], di
    mov word ptr [r15+32], r9w
    mov word ptr [r15+34], bp
    cmp byte ptr [r15+572659], 0
    jne L1
    mov qword ptr [r15+40], r14
    movzx edi, word ptr [r15+572656]
    add edi, r14d
    mov word ptr [r15+65858], di
L1:
    push r10
    push r11
    sub rsp, 40
    mov rcx, r15
    mov edx, esi
    call gbc_read
    add rsp, 40
    pop r11
    pop r10
    mov byte ptr [r15+572660], al
    movzx eax, byte ptr [r15+24]
    movzx r8d, byte ptr [r15+25]
    movzx ecx, word ptr [r15+26]
    rol cx, 8
    movzx edx, word ptr [r15+28]
    rol dx, 8
    movzx ebx, word ptr [r15+30]
    rol bx, 8
    movzx r9d, word ptr [r15+32]
    movzx ebp, word ptr [r15+34]
    mov r14, qword ptr [r15+40]
    mov r13, qword ptr [r15+572608]
    lea rdi, [r15+572660]
    sub rdi, rsi
    ret
Lwr_slow:
    push rax
    push rcx
    push rdx
    movzx eax, byte ptr [rsp+72]
    cmp esi, 65408
    jb Lws1
    cmp esi, 65535
    je Lws9
    mov rcx, qword ptr [r15+572560]
    mov byte ptr [rcx+rsi], al
    jmp Lws8
Lws1:
    cmp esi, 65024
    jb Lws2
    cmp esi, 65184
    jae Lws9
    mov rcx, qword ptr [r15+572552]
    mov byte ptr [rcx+rsi], al
    jmp Lws8
Lws2:
    mov ecx, esi
    and ecx, 57344
    cmp ecx, 32768
    je Lws_v
    cmp ecx, 8192
    je Lws_m
    cmp ecx, 49152
    jne Lws9
    mov ecx, esi
    shr ecx, 12
    mov rcx, qword ptr [r15+rcx*8+572416]
    test rcx, rcx
    jz Lws9
    mov edx, esi
    and edx, 8191
    mov rdi, qword ptr [r15+572568]
    cmp byte ptr [rdi+rdx], 0
    jne Lws9
    mov byte ptr [rcx+rsi], al
Lws8:
    pop rdx
    pop rcx
    pop rax
    ret
Lws_v:
    cmp byte ptr [r15+572662], 0
    je Lws9
    mov rcx, qword ptr [r15+572616]
    mov rdx, qword ptr [r15+572632]
    cmp esi, 39936
    jb Lws_v1
    mov rcx, qword ptr [r15+572624]
    mov rdx, qword ptr [r15+572640]
Lws_v1:
    mov byte ptr [rcx+rsi], al
    test rdx, rdx
    jz Lws8
    cmp esi, dword ptr [r15+572648]
    jb Lws8
    cmp esi, dword ptr [r15+572652]
    jae Lws8
    mov byte ptr [rdx+rsi], al
    jmp Lws8
Lws_m:
    cmp byte ptr [r15+572663], 0
    je Lws9
    movzx ecx, word ptr [r15+48]
    cmp esi, 12288
    jae Lws_m1
    and ecx, 256
    or ecx, eax
    jmp Lws_m2
Lws_m1:
    and ecx, 255
    mov edx, eax
    and edx, 1
    shl edx, 8
    or ecx, edx
Lws_m2:
    mov word ptr [r15+48], cx
    and ecx, dword ptr [r15+16]
    shl rcx, 14
    add rcx, qword ptr [r15+0]
    sub rcx, 16384
    mov qword ptr [r15+572320], rcx
    mov qword ptr [r15+572328], rcx
    mov qword ptr [r15+572336], rcx
    mov qword ptr [r15+572344], rcx
    jmp Lws8
Lws9:
    pop rdx
    pop rcx
    pop rax
    mov byte ptr [r15+24], al
    mov byte ptr [r15+25], r8b
    mov edi, ecx
    rol di, 8
    mov word ptr [r15+26], di
    mov edi, edx
    rol di, 8
    mov word ptr [r15+28], di
    mov edi, ebx
    rol di, 8
    mov word ptr [r15+30], di
    mov word ptr [r15+32], r9w
    mov word ptr [r15+34], bp
    cmp byte ptr [r15+572659], 0
    jne L2
    mov qword ptr [r15+40], r14
    movzx edi, word ptr [r15+572656]
    add edi, r14d
    mov word ptr [r15+65858], di
L2:
    push r10
    push r11
    sub rsp, 40
    mov rcx, r15
    mov edx, esi
    movzx r8d, byte ptr [rsp+104]
    call gbc_asm_write
    add rsp, 40
    pop r11
    pop r10
    movzx eax, byte ptr [r15+24]
    movzx r8d, byte ptr [r15+25]
    movzx ecx, word ptr [r15+26]
    rol cx, 8
    movzx edx, word ptr [r15+28]
    rol dx, 8
    movzx ebx, word ptr [r15+30]
    rol bx, 8
    movzx r9d, word ptr [r15+32]
    movzx ebp, word ptr [r15+34]
    mov r14, qword ptr [r15+40]
    mov r13, qword ptr [r15+572608]
    ret
Ltick_slow4:
    sub r14, 4
    mov byte ptr [r15+24], al
    mov byte ptr [r15+25], r8b
    mov edi, ecx
    rol di, 8
    mov word ptr [r15+26], di
    mov edi, edx
    rol di, 8
    mov word ptr [r15+28], di
    mov edi, ebx
    rol di, 8
    mov word ptr [r15+30], di
    mov word ptr [r15+32], r9w
    mov word ptr [r15+34], bp
    cmp byte ptr [r15+572659], 0
    jne L3
    mov qword ptr [r15+40], r14
    movzx edi, word ptr [r15+572656]
    add edi, r14d
    mov word ptr [r15+65858], di
L3:
    push r10
    push r11
    sub rsp, 40
    mov rcx, r15
    mov edx, 4
    call gbc_asm_tick
    add rsp, 40
    pop r11
    pop r10
    movzx eax, byte ptr [r15+24]
    movzx r8d, byte ptr [r15+25]
    movzx ecx, word ptr [r15+26]
    rol cx, 8
    movzx edx, word ptr [r15+28]
    rol dx, 8
    movzx ebx, word ptr [r15+30]
    rol bx, 8
    movzx r9d, word ptr [r15+32]
    movzx ebp, word ptr [r15+34]
    mov r14, qword ptr [r15+40]
    mov r13, qword ptr [r15+572608]
    ret
Ltick_slow8:
    sub r14, 8
    mov byte ptr [r15+24], al
    mov byte ptr [r15+25], r8b
    mov edi, ecx
    rol di, 8
    mov word ptr [r15+26], di
    mov edi, edx
    rol di, 8
    mov word ptr [r15+28], di
    mov edi, ebx
    rol di, 8
    mov word ptr [r15+30], di
    mov word ptr [r15+32], r9w
    mov word ptr [r15+34], bp
    cmp byte ptr [r15+572659], 0
    jne L4
    mov qword ptr [r15+40], r14
    movzx edi, word ptr [r15+572656]
    add edi, r14d
    mov word ptr [r15+65858], di
L4:
    push r10
    push r11
    sub rsp, 40
    mov rcx, r15
    mov edx, 8
    call gbc_asm_tick
    add rsp, 40
    pop r11
    pop r10
    movzx eax, byte ptr [r15+24]
    movzx r8d, byte ptr [r15+25]
    movzx ecx, word ptr [r15+26]
    rol cx, 8
    movzx edx, word ptr [r15+28]
    rol dx, 8
    movzx ebx, word ptr [r15+30]
    rol bx, 8
    movzx r9d, word ptr [r15+32]
    movzx ebp, word ptr [r15+34]
    mov r14, qword ptr [r15+40]
    mov r13, qword ptr [r15+572608]
    ret
Lidle:
    test al, al
    jnz Lid_ret
    cmp r8d, 160
    jne Lid_ret
    mov esi, ebp
    and esi, 4095
    cmp esi, 4092
    ja Lid_ret
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz Lid_ret
    cmp dword ptr [rdi+rbp], 0FC28A77Eh
    jne Lid_ret
    mov esi, dword ptr [r15+rbp+498556]
    and esi, 197379
    jnz Lid_ret
    mov esi, ebx
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jnz Lid_m
    cmp ebx, 65408
    jb Lid_ret
    cmp ebx, 65535
    je Lid_ret
    mov rdi, qword ptr [r15+572560]
Lid_m:
    cmp byte ptr [rdi+rbx], 0
    jne Lid_ret
    mov rax, qword ptr [r15+572584]
    mov rsi, qword ptr [r15+572600]
    cmp rsi, rax
    cmovb rax, rsi
    dec rax
    sub rax, r14
    jbe Lid_a0
    mov rdi, rdx
    xor edx, edx
    mov esi, 24
    div rsi
    lea rsi, [rax+rax*2]
    cmp rsi, r12
    jbe Lid_k
    mov rax, r12
    xor edx, edx
    mov esi, 3
    div rsi
Lid_k:
    mov rdx, rdi
    lea rsi, [rax+rax*2]
    sub r12, rsi
    shl rsi, 3
    add r14, rsi
Lid_a0:
    xor eax, eax
Lid_ret:
    ret
Lcopy:
    cmp ebp, 32768
    jae Lcp_ret
    mov esi, ebp
    and esi, 4095
    cmp esi, 4088
    ja Lcp_ret
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz Lcp_ret
    mov rsi, 0F820B0790B13122Ah
    cmp qword ptr [rdi+rbp], rsi
    jne Lcp_ret
    mov rsi, qword ptr [r15+rbp+498556]
    mov rdi, 0003030303030303h
    test rsi, rdi
    jnz Lcp_ret
    push rax
    push rdx
    mov rax, qword ptr [r15+572584]
    mov rsi, qword ptr [r15+572600]
    cmp rsi, rax
    cmovb rax, rsi
    dec rax
    sub rax, r14
    jbe Lcp_none
    xor edx, edx
    mov esi, 52
    div rsi
    mov r10, rax
    mov rax, r12
    xor edx, edx
    mov esi, 7
    div rsi
    cmp rax, r10
    cmovb r10, rax
    lea eax, [rcx-1]
    movzx eax, ax
    cmp rax, r10
    cmovb r10, rax
    pop rdx
    xor r11d, r11d
Lcp_loop:
    cmp r11, r10
    jae Lcp_end
    mov esi, ebx
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz Lcp_end
    movzx eax, byte ptr [rdi+rbx]
    mov esi, edx
    shr esi, 8
    mov rdi, qword ptr [r15+rsi*8+574232]
    test rdi, rdi
    jz Lcp_end
    mov byte ptr [rdi+rdx], al
    inc bx
    inc dx
    dec cx
    inc r11
    jmp Lcp_loop
Lcp_end:
    pop rax
    test r11, r11
    jz Lcp_ret
    mov eax, ecx
    or al, ch
    xor r8d, r8d
    lea rsi, [r11*8]
    sub rsi, r11
    sub r12, rsi
    imul rsi, r11, 52
    add r14, rsi
Lcp_ret:
    ret
Lcp_none:
    pop rdx
    pop rax
    ret
Lslow_top:
    cmp r14, qword ptr [r15+572600]
    jae Lexit_done
    cmp byte ptr [r15+572658], 0
    jne Lexit_more
    test byte ptr [r15+rbp+498556], 1
    jnz Lexit_more
    cmp ebp, dword ptr [r15+572672]
    jne Lst1
    cmp r9d, dword ptr [r15+572676]
    je Lexit_done
Lst1:
    dec r12
    js Lexit_budget
    cmp r14, qword ptr [r15+572592]
    jb Lfast_fetch
Lcareful_fetch:
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L5
L6:
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L7
L8:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_c
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L5:
    call Ltick_slow4
    jmp L6
L7:
    mov esi, ebp
    call Lrd_slow
    jmp L8
Lnext:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
Lfast_fetch:
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L9
L10:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L9:
    mov esi, ebp
    call Lrd_slow
    jmp L10
Lexit_budget:
    mov byte ptr [r15+24], al
    mov byte ptr [r15+25], r8b
    mov edi, ecx
    rol di, 8
    mov word ptr [r15+26], di
    mov edi, edx
    rol di, 8
    mov word ptr [r15+28], di
    mov edi, ebx
    rol di, 8
    mov word ptr [r15+30], di
    mov word ptr [r15+32], r9w
    mov word ptr [r15+34], bp
    cmp byte ptr [r15+572659], 0
    jne L11
    mov qword ptr [r15+40], r14
    movzx edi, word ptr [r15+572656]
    add edi, r14d
    mov word ptr [r15+65858], di
L11:
    mov eax, 0
    jmp Lepilogue
Lexit_done:
    mov byte ptr [r15+24], al
    mov byte ptr [r15+25], r8b
    mov edi, ecx
    rol di, 8
    mov word ptr [r15+26], di
    mov edi, edx
    rol di, 8
    mov word ptr [r15+28], di
    mov edi, ebx
    rol di, 8
    mov word ptr [r15+30], di
    mov word ptr [r15+32], r9w
    mov word ptr [r15+34], bp
    cmp byte ptr [r15+572659], 0
    jne L12
    mov qword ptr [r15+40], r14
    movzx edi, word ptr [r15+572656]
    add edi, r14d
    mov word ptr [r15+65858], di
L12:
    mov eax, 1
    jmp Lepilogue
Lexit_more:
    mov byte ptr [r15+24], al
    mov byte ptr [r15+25], r8b
    mov edi, ecx
    rol di, 8
    mov word ptr [r15+26], di
    mov edi, edx
    rol di, 8
    mov word ptr [r15+28], di
    mov edi, ebx
    rol di, 8
    mov word ptr [r15+30], di
    mov word ptr [r15+32], r9w
    mov word ptr [r15+34], bp
    cmp byte ptr [r15+572659], 0
    jne L13
    mov qword ptr [r15+40], r14
    movzx edi, word ptr [r15+572656]
    add edi, r14d
    mov word ptr [r15+65858], di
L13:
    mov eax, 3
    jmp Lepilogue
Lepilogue:
    mov rdi, qword ptr [rsp+32]
    mov qword ptr [rdi], r12
    add rsp, 56
    pop r15
    pop r14
    pop r13
    pop r12
    pop rsi
    pop rdi
    pop rbp
    pop rbx
    ret
    ALIGN 16
Lf_00:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L14
L15:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L14:
    mov esi, ebp
    call Lrd_slow
    jmp L15
    ALIGN 16
Lf_01:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L16
L17:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L18
L19:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    mov ecx, r11d
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L20
L21:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L16:
    call Lrd_slow
    jmp L17
L18:
    call Lrd_slow
    jmp L19
L20:
    mov esi, ebp
    call Lrd_slow
    jmp L21
    ALIGN 16
Lf_02:
    mov esi, ecx
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L22
    mov byte ptr [rdi+rsi], al
L23:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L24
L25:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L22:
    mov byte ptr [rsp+40], al
    call Lwr_slow
    jmp L23
L24:
    mov esi, ebp
    call Lrd_slow
    jmp L25
    ALIGN 16
Lf_03:
    inc cx
    add r14, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L26
L27:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L26:
    mov esi, ebp
    call Lrd_slow
    jmp L27
    ALIGN 16
Lf_04:
    inc ch
    movzx edi, ch
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573208]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L28
L29:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L28:
    mov esi, ebp
    call Lrd_slow
    jmp L29
    ALIGN 16
Lf_05:
    dec ch
    movzx edi, ch
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573464]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L30
L31:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L30:
    mov esi, ebp
    call Lrd_slow
    jmp L31
    ALIGN 16
Lf_06:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L32
L33:
    mov ch, byte ptr [rdi+rsi]
    inc bp
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L34
L35:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L32:
    call Lrd_slow
    jmp L33
L34:
    mov esi, ebp
    call Lrd_slow
    jmp L35
    ALIGN 16
Lf_07:
    xor r8d, r8d
    rol al, 1
    setc r8b
    shl r8d, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L36
L37:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L36:
    mov esi, ebp
    call Lrd_slow
    jmp L37
    ALIGN 16
Lf_08:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L38
L39:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L40
L41:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    mov esi, r11d
    mov r10d, r9d
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L42
    mov byte ptr [rdi+rsi], r10b
L43:
    lea esi, [r11+1]
    and esi, 65535
    mov r10d, r9d
    shr r10d, 8
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L44
L45:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L46
    mov byte ptr [rdi+rsi], r10b
L47:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L48
L49:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L38:
    call Lrd_slow
    jmp L39
L40:
    call Lrd_slow
    jmp L41
L42:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L43
L44:
    call Ltick_slow4
    jmp L45
L46:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L47
L48:
    mov esi, ebp
    call Lrd_slow
    jmp L49
    ALIGN 16
Lf_09:
    mov edi, ebx
    xor edi, ecx
    add ebx, ecx
    xor edi, ebx
    and r8d, 128
    mov esi, edi
    shr edi, 7
    and edi, 32
    shr esi, 12
    and esi, 16
    or r8d, edi
    or r8d, esi
    and ebx, 65535
    add r14, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L50
L51:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L50:
    mov esi, ebp
    call Lrd_slow
    jmp L51
    ALIGN 16
Lf_0A:
    mov esi, ecx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L52
L53:
    mov al, byte ptr [rdi+rsi]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L54
L55:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L52:
    call Lrd_slow
    jmp L53
L54:
    mov esi, ebp
    call Lrd_slow
    jmp L55
    ALIGN 16
Lf_0B:
    dec cx
    add r14, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L56
L57:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L56:
    mov esi, ebp
    call Lrd_slow
    jmp L57
    ALIGN 16
Lf_0C:
    inc cl
    movzx edi, cl
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573208]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L58
L59:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L58:
    mov esi, ebp
    call Lrd_slow
    jmp L59
    ALIGN 16
Lf_0D:
    dec cl
    movzx edi, cl
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573464]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L60
L61:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L60:
    mov esi, ebp
    call Lrd_slow
    jmp L61
    ALIGN 16
Lf_0E:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L62
L63:
    mov cl, byte ptr [rdi+rsi]
    inc bp
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L64
L65:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L62:
    call Lrd_slow
    jmp L63
L64:
    mov esi, ebp
    call Lrd_slow
    jmp L65
    ALIGN 16
Lf_0F:
    xor r8d, r8d
    ror al, 1
    setc r8b
    shl r8d, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L66
L67:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L66:
    mov esi, ebp
    call Lrd_slow
    jmp L67
    ALIGN 16
Lf_10:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L68
L69:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L70
L71:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L68:
    call Lrd_slow
    jmp L69
L70:
    mov esi, ebp
    call Lrd_slow
    jmp L71
    ALIGN 16
Lf_11:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L72
L73:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L74
L75:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    mov edx, r11d
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L76
L77:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L72:
    call Lrd_slow
    jmp L73
L74:
    call Lrd_slow
    jmp L75
L76:
    mov esi, ebp
    call Lrd_slow
    jmp L77
    ALIGN 16
Lf_12:
    mov esi, edx
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L78
    mov byte ptr [rdi+rsi], al
L79:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L80
L81:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L78:
    mov byte ptr [rsp+40], al
    call Lwr_slow
    jmp L79
L80:
    mov esi, ebp
    call Lrd_slow
    jmp L81
    ALIGN 16
Lf_13:
    inc dx
    add r14, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L82
L83:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L82:
    mov esi, ebp
    call Lrd_slow
    jmp L83
    ALIGN 16
Lf_14:
    inc dh
    movzx edi, dh
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573208]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L84
L85:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L84:
    mov esi, ebp
    call Lrd_slow
    jmp L85
    ALIGN 16
Lf_15:
    dec dh
    movzx edi, dh
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573464]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L86
L87:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L86:
    mov esi, ebp
    call Lrd_slow
    jmp L87
    ALIGN 16
Lf_16:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L88
L89:
    mov dh, byte ptr [rdi+rsi]
    inc bp
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L90
L91:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L88:
    call Lrd_slow
    jmp L89
L90:
    mov esi, ebp
    call Lrd_slow
    jmp L91
    ALIGN 16
Lf_17:
    bt r8d, 4
    rcl al, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L92
L93:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L92:
    mov esi, ebp
    call Lrd_slow
    jmp L93
    ALIGN 16
Lf_18:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L94
L95:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    movsx r10d, r10b
    add ebp, r10d
    and ebp, 65535
    add r14, 4
L96:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L97
L98:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L94:
    call Lrd_slow
    jmp L95
L97:
    mov esi, ebp
    call Lrd_slow
    jmp L98
    ALIGN 16
Lf_19:
    mov edi, ebx
    xor edi, edx
    add ebx, edx
    xor edi, ebx
    and r8d, 128
    mov esi, edi
    shr edi, 7
    and edi, 32
    shr esi, 12
    and esi, 16
    or r8d, edi
    or r8d, esi
    and ebx, 65535
    add r14, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L99
L100:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L99:
    mov esi, ebp
    call Lrd_slow
    jmp L100
    ALIGN 16
Lf_1A:
    mov esi, edx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L101
L102:
    mov al, byte ptr [rdi+rsi]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L103
L104:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L101:
    call Lrd_slow
    jmp L102
L103:
    mov esi, ebp
    call Lrd_slow
    jmp L104
    ALIGN 16
Lf_1B:
    dec dx
    add r14, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L105
L106:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L105:
    mov esi, ebp
    call Lrd_slow
    jmp L106
    ALIGN 16
Lf_1C:
    inc dl
    movzx edi, dl
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573208]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L107
L108:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L107:
    mov esi, ebp
    call Lrd_slow
    jmp L108
    ALIGN 16
Lf_1D:
    dec dl
    movzx edi, dl
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573464]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L109
L110:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L109:
    mov esi, ebp
    call Lrd_slow
    jmp L110
    ALIGN 16
Lf_1E:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L111
L112:
    mov dl, byte ptr [rdi+rsi]
    inc bp
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L113
L114:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L111:
    call Lrd_slow
    jmp L112
L113:
    mov esi, ebp
    call Lrd_slow
    jmp L114
    ALIGN 16
Lf_1F:
    bt r8d, 4
    rcr al, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L115
L116:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L115:
    mov esi, ebp
    call Lrd_slow
    jmp L116
    ALIGN 16
Lf_20:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L117
L118:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    test r8b, 128
    jnz L119
    movsx r10d, r10b
    add ebp, r10d
    and ebp, 65535
    add r14, 4
    cmp r10d, -8
    je L120
L121:
L119:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L122
L123:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L117:
    call Lrd_slow
    jmp L118
L120:
    call Lcopy
    jmp L121
L122:
    mov esi, ebp
    call Lrd_slow
    jmp L123
    ALIGN 16
Lf_21:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L124
L125:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L126
L127:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    mov ebx, r11d
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L128
L129:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L124:
    call Lrd_slow
    jmp L125
L126:
    call Lrd_slow
    jmp L127
L128:
    mov esi, ebp
    call Lrd_slow
    jmp L129
    ALIGN 16
Lf_22:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L130
    mov byte ptr [rdi+rsi], al
L131:
    lea ebx, [rsi+1]
    and ebx, 65535
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L132
L133:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L130:
    mov byte ptr [rsp+40], al
    call Lwr_slow
    jmp L131
L132:
    mov esi, ebp
    call Lrd_slow
    jmp L133
    ALIGN 16
Lf_23:
    inc bx
    add r14, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L134
L135:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L134:
    mov esi, ebp
    call Lrd_slow
    jmp L135
    ALIGN 16
Lf_24:
    inc bh
    movzx edi, bh
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573208]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L136
L137:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L136:
    mov esi, ebp
    call Lrd_slow
    jmp L137
    ALIGN 16
Lf_25:
    dec bh
    movzx edi, bh
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573464]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L138
L139:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L138:
    mov esi, ebp
    call Lrd_slow
    jmp L139
    ALIGN 16
Lf_26:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L140
L141:
    mov bh, byte ptr [rdi+rsi]
    inc bp
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L142
L143:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L140:
    call Lrd_slow
    jmp L141
L142:
    mov esi, ebp
    call Lrd_slow
    jmp L143
    ALIGN 16
Lf_27:
    movzx edi, al
    mov esi, r8d
    and esi, 16
    test r8b, 64
    jz L144
    test r8b, 32
    jz L145
    sub edi, 6
L145:
    test esi, esi
    jz L149
    sub edi, 96
    jmp L149
L144:
    test esi, esi
    jnz L146
    cmp edi, 153
    jbe L147
L146:
    add edi, 96
    mov esi, 16
L147:
    test r8b, 32
    jnz L148
    mov r10d, edi
    and r10d, 15
    cmp r10d, 9
    jbe L149
L148:
    add edi, 6
L149:
    mov eax, edi
    and r8d, 64
    or r8d, esi
    test al, al
    jnz L150
    or r8d, 128
L150:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L151
L152:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L151:
    mov esi, ebp
    call Lrd_slow
    jmp L152
    ALIGN 16
Lf_28:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L153
L154:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    test r8b, 128
    jz L155
    movsx r10d, r10b
    add ebp, r10d
    and ebp, 65535
    add r14, 4
    cmp r10d, -4
    je L156
L157:
L155:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L158
L159:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L153:
    call Lrd_slow
    jmp L154
L156:
    call Lidle
    jmp L157
L158:
    mov esi, ebp
    call Lrd_slow
    jmp L159
    ALIGN 16
Lf_29:
    mov edi, ebx
    xor edi, ebx
    add ebx, ebx
    xor edi, ebx
    and r8d, 128
    mov esi, edi
    shr edi, 7
    and edi, 32
    shr esi, 12
    and esi, 16
    or r8d, edi
    or r8d, esi
    and ebx, 65535
    add r14, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L160
L161:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L160:
    mov esi, ebp
    call Lrd_slow
    jmp L161
    ALIGN 16
Lf_2A:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L162
L163:
    mov al, byte ptr [rdi+rsi]
    lea ebx, [rsi+1]
    and ebx, 65535
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L164
L165:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L162:
    call Lrd_slow
    jmp L163
L164:
    mov esi, ebp
    call Lrd_slow
    jmp L165
    ALIGN 16
Lf_2B:
    dec bx
    add r14, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L166
L167:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L166:
    mov esi, ebp
    call Lrd_slow
    jmp L167
    ALIGN 16
Lf_2C:
    inc bl
    movzx edi, bl
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573208]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L168
L169:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L168:
    mov esi, ebp
    call Lrd_slow
    jmp L169
    ALIGN 16
Lf_2D:
    dec bl
    movzx edi, bl
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573464]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L170
L171:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L170:
    mov esi, ebp
    call Lrd_slow
    jmp L171
    ALIGN 16
Lf_2E:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L172
L173:
    mov bl, byte ptr [rdi+rsi]
    inc bp
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L174
L175:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L172:
    call Lrd_slow
    jmp L173
L174:
    mov esi, ebp
    call Lrd_slow
    jmp L175
    ALIGN 16
Lf_2F:
    not al
    or r8d, 96
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L176
L177:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L176:
    mov esi, ebp
    call Lrd_slow
    jmp L177
    ALIGN 16
Lf_30:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L178
L179:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    test r8b, 16
    jnz L180
    movsx r10d, r10b
    add ebp, r10d
    and ebp, 65535
    add r14, 4
L180:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L181
L182:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L178:
    call Lrd_slow
    jmp L179
L181:
    mov esi, ebp
    call Lrd_slow
    jmp L182
    ALIGN 16
Lf_31:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L183
L184:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L185
L186:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    mov r9d, r11d
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L187
L188:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L183:
    call Lrd_slow
    jmp L184
L185:
    call Lrd_slow
    jmp L186
L187:
    mov esi, ebp
    call Lrd_slow
    jmp L188
    ALIGN 16
Lf_32:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L189
    mov byte ptr [rdi+rsi], al
L190:
    lea ebx, [rsi-1]
    and ebx, 65535
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L191
L192:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L189:
    mov byte ptr [rsp+40], al
    call Lwr_slow
    jmp L190
L191:
    mov esi, ebp
    call Lrd_slow
    jmp L192
    ALIGN 16
Lf_33:
    inc r9w
    add r14, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L193
L194:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L193:
    mov esi, ebp
    call Lrd_slow
    jmp L194
    ALIGN 16
Lf_34:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L195
L196:
    movzx r10d, byte ptr [rdi+rsi]
    inc r10b
    movzx edi, r10b
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573208]
    or r8d, edi
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L197
    mov byte ptr [rdi+rsi], r10b
L198:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L199
L200:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L195:
    call Lrd_slow
    jmp L196
L197:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L198
L199:
    mov esi, ebp
    call Lrd_slow
    jmp L200
    ALIGN 16
Lf_35:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L201
L202:
    movzx r10d, byte ptr [rdi+rsi]
    dec r10b
    movzx edi, r10b
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573464]
    or r8d, edi
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L203
    mov byte ptr [rdi+rsi], r10b
L204:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L205
L206:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L201:
    call Lrd_slow
    jmp L202
L203:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L204
L205:
    mov esi, ebp
    call Lrd_slow
    jmp L206
    ALIGN 16
Lf_36:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L207
L208:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L209
    mov byte ptr [rdi+rsi], r10b
L210:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L211
L212:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L207:
    call Lrd_slow
    jmp L208
L209:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L210
L211:
    mov esi, ebp
    call Lrd_slow
    jmp L212
    ALIGN 16
Lf_37:
    and r8d, 128
    or r8d, 16
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L213
L214:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L213:
    mov esi, ebp
    call Lrd_slow
    jmp L214
    ALIGN 16
Lf_38:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L215
L216:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    test r8b, 16
    jz L217
    movsx r10d, r10b
    add ebp, r10d
    and ebp, 65535
    add r14, 4
L217:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L218
L219:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L215:
    call Lrd_slow
    jmp L216
L218:
    mov esi, ebp
    call Lrd_slow
    jmp L219
    ALIGN 16
Lf_39:
    mov edi, ebx
    xor edi, r9d
    add ebx, r9d
    xor edi, ebx
    and r8d, 128
    mov esi, edi
    shr edi, 7
    and edi, 32
    shr esi, 12
    and esi, 16
    or r8d, edi
    or r8d, esi
    and ebx, 65535
    add r14, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L220
L221:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L220:
    mov esi, ebp
    call Lrd_slow
    jmp L221
    ALIGN 16
Lf_3A:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L222
L223:
    mov al, byte ptr [rdi+rsi]
    lea ebx, [rsi-1]
    and ebx, 65535
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L224
L225:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L222:
    call Lrd_slow
    jmp L223
L224:
    mov esi, ebp
    call Lrd_slow
    jmp L225
    ALIGN 16
Lf_3B:
    dec r9w
    add r14, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L226
L227:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L226:
    mov esi, ebp
    call Lrd_slow
    jmp L227
    ALIGN 16
Lf_3C:
    inc al
    movzx edi, al
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573208]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L228
L229:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L228:
    mov esi, ebp
    call Lrd_slow
    jmp L229
    ALIGN 16
Lf_3D:
    dec al
    movzx edi, al
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573464]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L230
L231:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L230:
    mov esi, ebp
    call Lrd_slow
    jmp L231
    ALIGN 16
Lf_3E:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L232
L233:
    mov al, byte ptr [rdi+rsi]
    inc bp
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L234
L235:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L232:
    call Lrd_slow
    jmp L233
L234:
    mov esi, ebp
    call Lrd_slow
    jmp L235
    ALIGN 16
Lf_3F:
    and r8d, 144
    xor r8d, 16
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L236
L237:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L236:
    mov esi, ebp
    call Lrd_slow
    jmp L237
    ALIGN 16
Lf_40:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L238
L239:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L238:
    mov esi, ebp
    call Lrd_slow
    jmp L239
    ALIGN 16
Lf_41:
    mov ch, cl
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L240
L241:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L240:
    mov esi, ebp
    call Lrd_slow
    jmp L241
    ALIGN 16
Lf_42:
    mov ch, dh
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L242
L243:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L242:
    mov esi, ebp
    call Lrd_slow
    jmp L243
    ALIGN 16
Lf_43:
    mov ch, dl
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L244
L245:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L244:
    mov esi, ebp
    call Lrd_slow
    jmp L245
    ALIGN 16
Lf_44:
    mov ch, bh
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L246
L247:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L246:
    mov esi, ebp
    call Lrd_slow
    jmp L247
    ALIGN 16
Lf_45:
    mov ch, bl
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L248
L249:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L248:
    mov esi, ebp
    call Lrd_slow
    jmp L249
    ALIGN 16
Lf_46:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L250
L251:
    mov ch, byte ptr [rdi+rsi]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L252
L253:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L250:
    call Lrd_slow
    jmp L251
L252:
    mov esi, ebp
    call Lrd_slow
    jmp L253
    ALIGN 16
Lf_47:
    mov ch, al
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L254
L255:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L254:
    mov esi, ebp
    call Lrd_slow
    jmp L255
    ALIGN 16
Lf_48:
    mov cl, ch
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L256
L257:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L256:
    mov esi, ebp
    call Lrd_slow
    jmp L257
    ALIGN 16
Lf_49:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L258
L259:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L258:
    mov esi, ebp
    call Lrd_slow
    jmp L259
    ALIGN 16
Lf_4A:
    mov cl, dh
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L260
L261:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L260:
    mov esi, ebp
    call Lrd_slow
    jmp L261
    ALIGN 16
Lf_4B:
    mov cl, dl
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L262
L263:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L262:
    mov esi, ebp
    call Lrd_slow
    jmp L263
    ALIGN 16
Lf_4C:
    mov cl, bh
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L264
L265:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L264:
    mov esi, ebp
    call Lrd_slow
    jmp L265
    ALIGN 16
Lf_4D:
    mov cl, bl
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L266
L267:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L266:
    mov esi, ebp
    call Lrd_slow
    jmp L267
    ALIGN 16
Lf_4E:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L268
L269:
    mov cl, byte ptr [rdi+rsi]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L270
L271:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L268:
    call Lrd_slow
    jmp L269
L270:
    mov esi, ebp
    call Lrd_slow
    jmp L271
    ALIGN 16
Lf_4F:
    mov cl, al
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L272
L273:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L272:
    mov esi, ebp
    call Lrd_slow
    jmp L273
    ALIGN 16
Lf_50:
    mov dh, ch
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L274
L275:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L274:
    mov esi, ebp
    call Lrd_slow
    jmp L275
    ALIGN 16
Lf_51:
    mov dh, cl
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L276
L277:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L276:
    mov esi, ebp
    call Lrd_slow
    jmp L277
    ALIGN 16
Lf_52:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L278
L279:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L278:
    mov esi, ebp
    call Lrd_slow
    jmp L279
    ALIGN 16
Lf_53:
    mov dh, dl
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L280
L281:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L280:
    mov esi, ebp
    call Lrd_slow
    jmp L281
    ALIGN 16
Lf_54:
    mov dh, bh
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L282
L283:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L282:
    mov esi, ebp
    call Lrd_slow
    jmp L283
    ALIGN 16
Lf_55:
    mov dh, bl
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L284
L285:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L284:
    mov esi, ebp
    call Lrd_slow
    jmp L285
    ALIGN 16
Lf_56:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L286
L287:
    mov dh, byte ptr [rdi+rsi]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L288
L289:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L286:
    call Lrd_slow
    jmp L287
L288:
    mov esi, ebp
    call Lrd_slow
    jmp L289
    ALIGN 16
Lf_57:
    mov dh, al
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L290
L291:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L290:
    mov esi, ebp
    call Lrd_slow
    jmp L291
    ALIGN 16
Lf_58:
    mov dl, ch
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L292
L293:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L292:
    mov esi, ebp
    call Lrd_slow
    jmp L293
    ALIGN 16
Lf_59:
    mov dl, cl
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L294
L295:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L294:
    mov esi, ebp
    call Lrd_slow
    jmp L295
    ALIGN 16
Lf_5A:
    mov dl, dh
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L296
L297:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L296:
    mov esi, ebp
    call Lrd_slow
    jmp L297
    ALIGN 16
Lf_5B:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L298
L299:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L298:
    mov esi, ebp
    call Lrd_slow
    jmp L299
    ALIGN 16
Lf_5C:
    mov dl, bh
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L300
L301:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L300:
    mov esi, ebp
    call Lrd_slow
    jmp L301
    ALIGN 16
Lf_5D:
    mov dl, bl
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L302
L303:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L302:
    mov esi, ebp
    call Lrd_slow
    jmp L303
    ALIGN 16
Lf_5E:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L304
L305:
    mov dl, byte ptr [rdi+rsi]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L306
L307:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L304:
    call Lrd_slow
    jmp L305
L306:
    mov esi, ebp
    call Lrd_slow
    jmp L307
    ALIGN 16
Lf_5F:
    mov dl, al
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L308
L309:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L308:
    mov esi, ebp
    call Lrd_slow
    jmp L309
    ALIGN 16
Lf_60:
    mov bh, ch
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L310
L311:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L310:
    mov esi, ebp
    call Lrd_slow
    jmp L311
    ALIGN 16
Lf_61:
    mov bh, cl
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L312
L313:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L312:
    mov esi, ebp
    call Lrd_slow
    jmp L313
    ALIGN 16
Lf_62:
    mov bh, dh
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L314
L315:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L314:
    mov esi, ebp
    call Lrd_slow
    jmp L315
    ALIGN 16
Lf_63:
    mov bh, dl
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L316
L317:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L316:
    mov esi, ebp
    call Lrd_slow
    jmp L317
    ALIGN 16
Lf_64:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L318
L319:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L318:
    mov esi, ebp
    call Lrd_slow
    jmp L319
    ALIGN 16
Lf_65:
    mov bh, bl
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L320
L321:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L320:
    mov esi, ebp
    call Lrd_slow
    jmp L321
    ALIGN 16
Lf_66:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L322
L323:
    mov bh, byte ptr [rdi+rsi]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L324
L325:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L322:
    call Lrd_slow
    jmp L323
L324:
    mov esi, ebp
    call Lrd_slow
    jmp L325
    ALIGN 16
Lf_67:
    mov bh, al
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L326
L327:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L326:
    mov esi, ebp
    call Lrd_slow
    jmp L327
    ALIGN 16
Lf_68:
    mov bl, ch
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L328
L329:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L328:
    mov esi, ebp
    call Lrd_slow
    jmp L329
    ALIGN 16
Lf_69:
    mov bl, cl
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L330
L331:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L330:
    mov esi, ebp
    call Lrd_slow
    jmp L331
    ALIGN 16
Lf_6A:
    mov bl, dh
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L332
L333:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L332:
    mov esi, ebp
    call Lrd_slow
    jmp L333
    ALIGN 16
Lf_6B:
    mov bl, dl
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L334
L335:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L334:
    mov esi, ebp
    call Lrd_slow
    jmp L335
    ALIGN 16
Lf_6C:
    mov bl, bh
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L336
L337:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L336:
    mov esi, ebp
    call Lrd_slow
    jmp L337
    ALIGN 16
Lf_6D:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L338
L339:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L338:
    mov esi, ebp
    call Lrd_slow
    jmp L339
    ALIGN 16
Lf_6E:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L340
L341:
    mov bl, byte ptr [rdi+rsi]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L342
L343:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L340:
    call Lrd_slow
    jmp L341
L342:
    mov esi, ebp
    call Lrd_slow
    jmp L343
    ALIGN 16
Lf_6F:
    mov bl, al
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L344
L345:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L344:
    mov esi, ebp
    call Lrd_slow
    jmp L345
    ALIGN 16
Lf_70:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L346
    mov byte ptr [rdi+rsi], ch
L347:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L348
L349:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L346:
    mov byte ptr [rsp+40], ch
    call Lwr_slow
    jmp L347
L348:
    mov esi, ebp
    call Lrd_slow
    jmp L349
    ALIGN 16
Lf_71:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L350
    mov byte ptr [rdi+rsi], cl
L351:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L352
L353:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L350:
    mov byte ptr [rsp+40], cl
    call Lwr_slow
    jmp L351
L352:
    mov esi, ebp
    call Lrd_slow
    jmp L353
    ALIGN 16
Lf_72:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L354
    mov byte ptr [rdi+rsi], dh
L355:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L356
L357:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L354:
    mov byte ptr [rsp+40], dh
    call Lwr_slow
    jmp L355
L356:
    mov esi, ebp
    call Lrd_slow
    jmp L357
    ALIGN 16
Lf_73:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L358
    mov byte ptr [rdi+rsi], dl
L359:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L360
L361:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L358:
    mov byte ptr [rsp+40], dl
    call Lwr_slow
    jmp L359
L360:
    mov esi, ebp
    call Lrd_slow
    jmp L361
    ALIGN 16
Lf_74:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L362
    mov byte ptr [rdi+rsi], bh
L363:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L364
L365:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L362:
    mov byte ptr [rsp+40], bh
    call Lwr_slow
    jmp L363
L364:
    mov esi, ebp
    call Lrd_slow
    jmp L365
    ALIGN 16
Lf_75:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L366
    mov byte ptr [rdi+rsi], bl
L367:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L368
L369:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L366:
    mov byte ptr [rsp+40], bl
    call Lwr_slow
    jmp L367
L368:
    mov esi, ebp
    call Lrd_slow
    jmp L369
    ALIGN 16
Lf_76:
    mov byte ptr [r15+24], al
    mov byte ptr [r15+25], r8b
    mov edi, ecx
    rol di, 8
    mov word ptr [r15+26], di
    mov edi, edx
    rol di, 8
    mov word ptr [r15+28], di
    mov edi, ebx
    rol di, 8
    mov word ptr [r15+30], di
    mov word ptr [r15+32], r9w
    mov word ptr [r15+34], bp
    cmp byte ptr [r15+572659], 0
    jne L370
    mov qword ptr [r15+40], r14
    movzx edi, word ptr [r15+572656]
    add edi, r14d
    mov word ptr [r15+65858], di
L370:
    sub rsp, 32
    mov rcx, r15
    mov edx, 118
    call gbc_asm_op
    add rsp, 32
    movzx eax, byte ptr [r15+24]
    movzx r8d, byte ptr [r15+25]
    movzx ecx, word ptr [r15+26]
    rol cx, 8
    movzx edx, word ptr [r15+28]
    rol dx, 8
    movzx ebx, word ptr [r15+30]
    rol bx, 8
    movzx r9d, word ptr [r15+32]
    movzx ebp, word ptr [r15+34]
    mov r14, qword ptr [r15+40]
    mov r13, qword ptr [r15+572608]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L371
L372:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L371:
    mov esi, ebp
    call Lrd_slow
    jmp L372
    ALIGN 16
Lf_77:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L373
    mov byte ptr [rdi+rsi], al
L374:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L375
L376:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L373:
    mov byte ptr [rsp+40], al
    call Lwr_slow
    jmp L374
L375:
    mov esi, ebp
    call Lrd_slow
    jmp L376
    ALIGN 16
Lf_78:
    mov al, ch
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L377
L378:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L377:
    mov esi, ebp
    call Lrd_slow
    jmp L378
    ALIGN 16
Lf_79:
    mov al, cl
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L379
L380:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L379:
    mov esi, ebp
    call Lrd_slow
    jmp L380
    ALIGN 16
Lf_7A:
    mov al, dh
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L381
L382:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L381:
    mov esi, ebp
    call Lrd_slow
    jmp L382
    ALIGN 16
Lf_7B:
    mov al, dl
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L383
L384:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L383:
    mov esi, ebp
    call Lrd_slow
    jmp L384
    ALIGN 16
Lf_7C:
    mov al, bh
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L385
L386:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L385:
    mov esi, ebp
    call Lrd_slow
    jmp L386
    ALIGN 16
Lf_7D:
    mov al, bl
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L387
L388:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L387:
    mov esi, ebp
    call Lrd_slow
    jmp L388
    ALIGN 16
Lf_7E:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L389
L390:
    mov al, byte ptr [rdi+rsi]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L391
L392:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L389:
    call Lrd_slow
    jmp L390
L391:
    mov esi, ebp
    call Lrd_slow
    jmp L392
    ALIGN 16
Lf_7F:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L393
L394:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L393:
    mov esi, ebp
    call Lrd_slow
    jmp L394
    ALIGN 16
Lf_80:
    add al, ch
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572696]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L395
L396:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L395:
    mov esi, ebp
    call Lrd_slow
    jmp L396
    ALIGN 16
Lf_81:
    add al, cl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572696]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L397
L398:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L397:
    mov esi, ebp
    call Lrd_slow
    jmp L398
    ALIGN 16
Lf_82:
    add al, dh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572696]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L399
L400:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L399:
    mov esi, ebp
    call Lrd_slow
    jmp L400
    ALIGN 16
Lf_83:
    add al, dl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572696]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L401
L402:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L401:
    mov esi, ebp
    call Lrd_slow
    jmp L402
    ALIGN 16
Lf_84:
    add al, bh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572696]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L403
L404:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L403:
    mov esi, ebp
    call Lrd_slow
    jmp L404
    ALIGN 16
Lf_85:
    add al, bl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572696]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L405
L406:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L405:
    mov esi, ebp
    call Lrd_slow
    jmp L406
    ALIGN 16
Lf_86:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L407
L408:
    movzx r10d, byte ptr [rdi+rsi]
    add al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572696]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L409
L410:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L407:
    call Lrd_slow
    jmp L408
L409:
    mov esi, ebp
    call Lrd_slow
    jmp L410
    ALIGN 16
Lf_87:
    add al, al
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572696]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L411
L412:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L411:
    mov esi, ebp
    call Lrd_slow
    jmp L412
    ALIGN 16
Lf_88:
    bt r8d, 4
    adc al, ch
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572696]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L413
L414:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L413:
    mov esi, ebp
    call Lrd_slow
    jmp L414
    ALIGN 16
Lf_89:
    bt r8d, 4
    adc al, cl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572696]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L415
L416:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L415:
    mov esi, ebp
    call Lrd_slow
    jmp L416
    ALIGN 16
Lf_8A:
    bt r8d, 4
    adc al, dh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572696]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L417
L418:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L417:
    mov esi, ebp
    call Lrd_slow
    jmp L418
    ALIGN 16
Lf_8B:
    bt r8d, 4
    adc al, dl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572696]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L419
L420:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L419:
    mov esi, ebp
    call Lrd_slow
    jmp L420
    ALIGN 16
Lf_8C:
    bt r8d, 4
    adc al, bh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572696]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L421
L422:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L421:
    mov esi, ebp
    call Lrd_slow
    jmp L422
    ALIGN 16
Lf_8D:
    bt r8d, 4
    adc al, bl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572696]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L423
L424:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L423:
    mov esi, ebp
    call Lrd_slow
    jmp L424
    ALIGN 16
Lf_8E:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L425
L426:
    movzx r10d, byte ptr [rdi+rsi]
    bt r8d, 4
    adc al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572696]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L427
L428:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L425:
    call Lrd_slow
    jmp L426
L427:
    mov esi, ebp
    call Lrd_slow
    jmp L428
    ALIGN 16
Lf_8F:
    bt r8d, 4
    adc al, al
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572696]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L429
L430:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L429:
    mov esi, ebp
    call Lrd_slow
    jmp L430
    ALIGN 16
Lf_90:
    sub al, ch
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L431
L432:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L431:
    mov esi, ebp
    call Lrd_slow
    jmp L432
    ALIGN 16
Lf_91:
    sub al, cl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L433
L434:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L433:
    mov esi, ebp
    call Lrd_slow
    jmp L434
    ALIGN 16
Lf_92:
    sub al, dh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L435
L436:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L435:
    mov esi, ebp
    call Lrd_slow
    jmp L436
    ALIGN 16
Lf_93:
    sub al, dl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L437
L438:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L437:
    mov esi, ebp
    call Lrd_slow
    jmp L438
    ALIGN 16
Lf_94:
    sub al, bh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L439
L440:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L439:
    mov esi, ebp
    call Lrd_slow
    jmp L440
    ALIGN 16
Lf_95:
    sub al, bl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L441
L442:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L441:
    mov esi, ebp
    call Lrd_slow
    jmp L442
    ALIGN 16
Lf_96:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L443
L444:
    movzx r10d, byte ptr [rdi+rsi]
    sub al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L445
L446:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L443:
    call Lrd_slow
    jmp L444
L445:
    mov esi, ebp
    call Lrd_slow
    jmp L446
    ALIGN 16
Lf_97:
    sub al, al
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L447
L448:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L447:
    mov esi, ebp
    call Lrd_slow
    jmp L448
    ALIGN 16
Lf_98:
    bt r8d, 4
    sbb al, ch
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L449
L450:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L449:
    mov esi, ebp
    call Lrd_slow
    jmp L450
    ALIGN 16
Lf_99:
    bt r8d, 4
    sbb al, cl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L451
L452:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L451:
    mov esi, ebp
    call Lrd_slow
    jmp L452
    ALIGN 16
Lf_9A:
    bt r8d, 4
    sbb al, dh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L453
L454:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L453:
    mov esi, ebp
    call Lrd_slow
    jmp L454
    ALIGN 16
Lf_9B:
    bt r8d, 4
    sbb al, dl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L455
L456:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L455:
    mov esi, ebp
    call Lrd_slow
    jmp L456
    ALIGN 16
Lf_9C:
    bt r8d, 4
    sbb al, bh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L457
L458:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L457:
    mov esi, ebp
    call Lrd_slow
    jmp L458
    ALIGN 16
Lf_9D:
    bt r8d, 4
    sbb al, bl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L459
L460:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L459:
    mov esi, ebp
    call Lrd_slow
    jmp L460
    ALIGN 16
Lf_9E:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L461
L462:
    movzx r10d, byte ptr [rdi+rsi]
    bt r8d, 4
    sbb al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L463
L464:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L461:
    call Lrd_slow
    jmp L462
L463:
    mov esi, ebp
    call Lrd_slow
    jmp L464
    ALIGN 16
Lf_9F:
    bt r8d, 4
    sbb al, al
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L465
L466:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L465:
    mov esi, ebp
    call Lrd_slow
    jmp L466
    ALIGN 16
Lf_A0:
    and al, ch
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573976]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L467
L468:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L467:
    mov esi, ebp
    call Lrd_slow
    jmp L468
    ALIGN 16
Lf_A1:
    and al, cl
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573976]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L469
L470:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L469:
    mov esi, ebp
    call Lrd_slow
    jmp L470
    ALIGN 16
Lf_A2:
    and al, dh
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573976]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L471
L472:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L471:
    mov esi, ebp
    call Lrd_slow
    jmp L472
    ALIGN 16
Lf_A3:
    and al, dl
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573976]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L473
L474:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L473:
    mov esi, ebp
    call Lrd_slow
    jmp L474
    ALIGN 16
Lf_A4:
    and al, bh
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573976]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L475
L476:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L475:
    mov esi, ebp
    call Lrd_slow
    jmp L476
    ALIGN 16
Lf_A5:
    and al, bl
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573976]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L477
L478:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L477:
    mov esi, ebp
    call Lrd_slow
    jmp L478
    ALIGN 16
Lf_A6:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L479
L480:
    movzx r10d, byte ptr [rdi+rsi]
    and al, r10b
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573976]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L481
L482:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L479:
    call Lrd_slow
    jmp L480
L481:
    mov esi, ebp
    call Lrd_slow
    jmp L482
    ALIGN 16
Lf_A7:
    and al, al
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573976]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L483
L484:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L483:
    mov esi, ebp
    call Lrd_slow
    jmp L484
    ALIGN 16
Lf_A8:
    xor al, ch
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573720]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L485
L486:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L485:
    mov esi, ebp
    call Lrd_slow
    jmp L486
    ALIGN 16
Lf_A9:
    xor al, cl
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573720]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L487
L488:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L487:
    mov esi, ebp
    call Lrd_slow
    jmp L488
    ALIGN 16
Lf_AA:
    xor al, dh
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573720]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L489
L490:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L489:
    mov esi, ebp
    call Lrd_slow
    jmp L490
    ALIGN 16
Lf_AB:
    xor al, dl
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573720]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L491
L492:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L491:
    mov esi, ebp
    call Lrd_slow
    jmp L492
    ALIGN 16
Lf_AC:
    xor al, bh
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573720]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L493
L494:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L493:
    mov esi, ebp
    call Lrd_slow
    jmp L494
    ALIGN 16
Lf_AD:
    xor al, bl
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573720]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L495
L496:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L495:
    mov esi, ebp
    call Lrd_slow
    jmp L496
    ALIGN 16
Lf_AE:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L497
L498:
    movzx r10d, byte ptr [rdi+rsi]
    xor al, r10b
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573720]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L499
L500:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L497:
    call Lrd_slow
    jmp L498
L499:
    mov esi, ebp
    call Lrd_slow
    jmp L500
    ALIGN 16
Lf_AF:
    xor al, al
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573720]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L501
L502:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L501:
    mov esi, ebp
    call Lrd_slow
    jmp L502
    ALIGN 16
Lf_B0:
    or al, ch
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573720]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L503
L504:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L503:
    mov esi, ebp
    call Lrd_slow
    jmp L504
    ALIGN 16
Lf_B1:
    or al, cl
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573720]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L505
L506:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L505:
    mov esi, ebp
    call Lrd_slow
    jmp L506
    ALIGN 16
Lf_B2:
    or al, dh
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573720]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L507
L508:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L507:
    mov esi, ebp
    call Lrd_slow
    jmp L508
    ALIGN 16
Lf_B3:
    or al, dl
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573720]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L509
L510:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L509:
    mov esi, ebp
    call Lrd_slow
    jmp L510
    ALIGN 16
Lf_B4:
    or al, bh
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573720]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L511
L512:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L511:
    mov esi, ebp
    call Lrd_slow
    jmp L512
    ALIGN 16
Lf_B5:
    or al, bl
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573720]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L513
L514:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L513:
    mov esi, ebp
    call Lrd_slow
    jmp L514
    ALIGN 16
Lf_B6:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L515
L516:
    movzx r10d, byte ptr [rdi+rsi]
    or al, r10b
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573720]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L517
L518:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L515:
    call Lrd_slow
    jmp L516
L517:
    mov esi, ebp
    call Lrd_slow
    jmp L518
    ALIGN 16
Lf_B7:
    or al, al
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573720]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L519
L520:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L519:
    mov esi, ebp
    call Lrd_slow
    jmp L520
    ALIGN 16
Lf_B8:
    cmp al, ch
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L521
L522:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L521:
    mov esi, ebp
    call Lrd_slow
    jmp L522
    ALIGN 16
Lf_B9:
    cmp al, cl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L523
L524:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L523:
    mov esi, ebp
    call Lrd_slow
    jmp L524
    ALIGN 16
Lf_BA:
    cmp al, dh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L525
L526:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L525:
    mov esi, ebp
    call Lrd_slow
    jmp L526
    ALIGN 16
Lf_BB:
    cmp al, dl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L527
L528:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L527:
    mov esi, ebp
    call Lrd_slow
    jmp L528
    ALIGN 16
Lf_BC:
    cmp al, bh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L529
L530:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L529:
    mov esi, ebp
    call Lrd_slow
    jmp L530
    ALIGN 16
Lf_BD:
    cmp al, bl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L531
L532:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L531:
    mov esi, ebp
    call Lrd_slow
    jmp L532
    ALIGN 16
Lf_BE:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L533
L534:
    movzx r10d, byte ptr [rdi+rsi]
    cmp al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L535
L536:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L533:
    call Lrd_slow
    jmp L534
L535:
    mov esi, ebp
    call Lrd_slow
    jmp L536
    ALIGN 16
Lf_BF:
    cmp al, al
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L537
L538:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L537:
    mov esi, ebp
    call Lrd_slow
    jmp L538
    ALIGN 16
Lf_C0:
    add r14, 4
    test r8b, 128
    jnz L539
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L540
L541:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L542
L543:
    movzx r11d, byte ptr [rdi+rsi]
    inc r9w
    shl r11d, 8
    or r11d, r10d
    mov ebp, r11d
    add r14, 4
L539:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L544
L545:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L540:
    call Lrd_slow
    jmp L541
L542:
    call Lrd_slow
    jmp L543
L544:
    mov esi, ebp
    call Lrd_slow
    jmp L545
    ALIGN 16
Lf_C1:
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L546
L547:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L548
L549:
    movzx r11d, byte ptr [rdi+rsi]
    inc r9w
    shl r11d, 8
    or r11d, r10d
    mov ecx, r11d
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L550
L551:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L546:
    call Lrd_slow
    jmp L547
L548:
    call Lrd_slow
    jmp L549
L550:
    mov esi, ebp
    call Lrd_slow
    jmp L551
    ALIGN 16
Lf_C2:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L552
L553:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L554
L555:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    test r8b, 128
    jnz L556
    mov ebp, r11d
    add r14, 4
L556:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L557
L558:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L552:
    call Lrd_slow
    jmp L553
L554:
    call Lrd_slow
    jmp L555
L557:
    mov esi, ebp
    call Lrd_slow
    jmp L558
    ALIGN 16
Lf_C3:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L559
L560:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L561
L562:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    mov ebp, r11d
    add r14, 4
L563:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L564
L565:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L559:
    call Lrd_slow
    jmp L560
L561:
    call Lrd_slow
    jmp L562
L564:
    mov esi, ebp
    call Lrd_slow
    jmp L565
    ALIGN 16
Lf_C4:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L566
L567:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L568
L569:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    test r8b, 128
    jnz L570
    add r14, 4
    mov dword ptr [rsp+48], r11d
    mov r11d, ebp
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L571
    mov byte ptr [rdi+rsi], r10b
L572:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L573
L574:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L575
    mov byte ptr [rdi+rsi], r11b
L576:
    mov ebp, dword ptr [rsp+48]
L570:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L577
L578:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L566:
    call Lrd_slow
    jmp L567
L568:
    call Lrd_slow
    jmp L569
L571:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L572
L573:
    call Ltick_slow4
    jmp L574
L575:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L576
L577:
    mov esi, ebp
    call Lrd_slow
    jmp L578
    ALIGN 16
Lf_C5:
    add r14, 4
    mov r11d, ecx
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L579
    mov byte ptr [rdi+rsi], r10b
L580:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L581
L582:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L583
    mov byte ptr [rdi+rsi], r11b
L584:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L585
L586:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L579:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L580
L581:
    call Ltick_slow4
    jmp L582
L583:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L584
L585:
    mov esi, ebp
    call Lrd_slow
    jmp L586
    ALIGN 16
Lf_C6:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L587
L588:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    add al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572696]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L589
L590:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L587:
    call Lrd_slow
    jmp L588
L589:
    mov esi, ebp
    call Lrd_slow
    jmp L590
    ALIGN 16
Lf_C7:
    add r14, 4
    mov r11d, ebp
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L591
    mov byte ptr [rdi+rsi], r10b
L592:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L593
L594:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L595
    mov byte ptr [rdi+rsi], r11b
L596:
    mov ebp, 0
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L597
L598:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L591:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L592
L593:
    call Ltick_slow4
    jmp L594
L595:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L596
L597:
    mov esi, ebp
    call Lrd_slow
    jmp L598
    ALIGN 16
Lf_C8:
    add r14, 4
    test r8b, 128
    jz L599
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L600
L601:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L602
L603:
    movzx r11d, byte ptr [rdi+rsi]
    inc r9w
    shl r11d, 8
    or r11d, r10d
    mov ebp, r11d
    add r14, 4
L599:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L604
L605:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L600:
    call Lrd_slow
    jmp L601
L602:
    call Lrd_slow
    jmp L603
L604:
    mov esi, ebp
    call Lrd_slow
    jmp L605
    ALIGN 16
Lf_C9:
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L606
L607:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L608
L609:
    movzx r11d, byte ptr [rdi+rsi]
    inc r9w
    shl r11d, 8
    or r11d, r10d
    mov ebp, r11d
    add r14, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L610
L611:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L606:
    call Lrd_slow
    jmp L607
L608:
    call Lrd_slow
    jmp L609
L610:
    mov esi, ebp
    call Lrd_slow
    jmp L611
    ALIGN 16
Lf_CA:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L612
L613:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L614
L615:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    test r8b, 128
    jz L616
    mov ebp, r11d
    add r14, 4
L616:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L617
L618:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L612:
    call Lrd_slow
    jmp L613
L614:
    call Lrd_slow
    jmp L615
L617:
    mov esi, ebp
    call Lrd_slow
    jmp L618
    ALIGN 16
Lf_CB:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L619
L620:
    movzx esi, byte ptr [rdi+rsi]
    inc bp
    lea rdi, Ljt_fcb
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L619:
    call Lrd_slow
    jmp L620
    ALIGN 16
Lf_CC:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L621
L622:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L623
L624:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    test r8b, 128
    jz L625
    add r14, 4
    mov dword ptr [rsp+48], r11d
    mov r11d, ebp
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L626
    mov byte ptr [rdi+rsi], r10b
L627:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L628
L629:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L630
    mov byte ptr [rdi+rsi], r11b
L631:
    mov ebp, dword ptr [rsp+48]
L625:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L632
L633:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L621:
    call Lrd_slow
    jmp L622
L623:
    call Lrd_slow
    jmp L624
L626:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L627
L628:
    call Ltick_slow4
    jmp L629
L630:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L631
L632:
    mov esi, ebp
    call Lrd_slow
    jmp L633
    ALIGN 16
Lf_CD:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L634
L635:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L636
L637:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    add r14, 4
    mov dword ptr [rsp+48], r11d
    mov r11d, ebp
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L639
    mov byte ptr [rdi+rsi], r10b
L640:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L641
L642:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L643
    mov byte ptr [rdi+rsi], r11b
L644:
    mov ebp, dword ptr [rsp+48]
L638:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L645
L646:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L634:
    call Lrd_slow
    jmp L635
L636:
    call Lrd_slow
    jmp L637
L639:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L640
L641:
    call Ltick_slow4
    jmp L642
L643:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L644
L645:
    mov esi, ebp
    call Lrd_slow
    jmp L646
    ALIGN 16
Lf_CE:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L647
L648:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    bt r8d, 4
    adc al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572696]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L649
L650:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L647:
    call Lrd_slow
    jmp L648
L649:
    mov esi, ebp
    call Lrd_slow
    jmp L650
    ALIGN 16
Lf_CF:
    add r14, 4
    mov r11d, ebp
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L651
    mov byte ptr [rdi+rsi], r10b
L652:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L653
L654:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L655
    mov byte ptr [rdi+rsi], r11b
L656:
    mov ebp, 8
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L657
L658:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L651:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L652
L653:
    call Ltick_slow4
    jmp L654
L655:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L656
L657:
    mov esi, ebp
    call Lrd_slow
    jmp L658
    ALIGN 16
Lf_D0:
    add r14, 4
    test r8b, 16
    jnz L659
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L660
L661:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L662
L663:
    movzx r11d, byte ptr [rdi+rsi]
    inc r9w
    shl r11d, 8
    or r11d, r10d
    mov ebp, r11d
    add r14, 4
L659:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L664
L665:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L660:
    call Lrd_slow
    jmp L661
L662:
    call Lrd_slow
    jmp L663
L664:
    mov esi, ebp
    call Lrd_slow
    jmp L665
    ALIGN 16
Lf_D1:
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L666
L667:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L668
L669:
    movzx r11d, byte ptr [rdi+rsi]
    inc r9w
    shl r11d, 8
    or r11d, r10d
    mov edx, r11d
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L670
L671:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L666:
    call Lrd_slow
    jmp L667
L668:
    call Lrd_slow
    jmp L669
L670:
    mov esi, ebp
    call Lrd_slow
    jmp L671
    ALIGN 16
Lf_D2:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L672
L673:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L674
L675:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    test r8b, 16
    jnz L676
    mov ebp, r11d
    add r14, 4
L676:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L677
L678:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L672:
    call Lrd_slow
    jmp L673
L674:
    call Lrd_slow
    jmp L675
L677:
    mov esi, ebp
    call Lrd_slow
    jmp L678
    ALIGN 16
Lf_D3:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L679
L680:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L679:
    mov esi, ebp
    call Lrd_slow
    jmp L680
    ALIGN 16
Lf_D4:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L681
L682:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L683
L684:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    test r8b, 16
    jnz L685
    add r14, 4
    mov dword ptr [rsp+48], r11d
    mov r11d, ebp
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L686
    mov byte ptr [rdi+rsi], r10b
L687:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L688
L689:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L690
    mov byte ptr [rdi+rsi], r11b
L691:
    mov ebp, dword ptr [rsp+48]
L685:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L692
L693:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L681:
    call Lrd_slow
    jmp L682
L683:
    call Lrd_slow
    jmp L684
L686:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L687
L688:
    call Ltick_slow4
    jmp L689
L690:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L691
L692:
    mov esi, ebp
    call Lrd_slow
    jmp L693
    ALIGN 16
Lf_D5:
    add r14, 4
    mov r11d, edx
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L694
    mov byte ptr [rdi+rsi], r10b
L695:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L696
L697:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L698
    mov byte ptr [rdi+rsi], r11b
L699:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L700
L701:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L694:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L695
L696:
    call Ltick_slow4
    jmp L697
L698:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L699
L700:
    mov esi, ebp
    call Lrd_slow
    jmp L701
    ALIGN 16
Lf_D6:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L702
L703:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    sub al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L704
L705:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L702:
    call Lrd_slow
    jmp L703
L704:
    mov esi, ebp
    call Lrd_slow
    jmp L705
    ALIGN 16
Lf_D7:
    add r14, 4
    mov r11d, ebp
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L706
    mov byte ptr [rdi+rsi], r10b
L707:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L708
L709:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L710
    mov byte ptr [rdi+rsi], r11b
L711:
    mov ebp, 16
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L712
L713:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L706:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L707
L708:
    call Ltick_slow4
    jmp L709
L710:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L711
L712:
    mov esi, ebp
    call Lrd_slow
    jmp L713
    ALIGN 16
Lf_D8:
    add r14, 4
    test r8b, 16
    jz L714
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L715
L716:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L717
L718:
    movzx r11d, byte ptr [rdi+rsi]
    inc r9w
    shl r11d, 8
    or r11d, r10d
    mov ebp, r11d
    add r14, 4
L714:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L719
L720:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L715:
    call Lrd_slow
    jmp L716
L717:
    call Lrd_slow
    jmp L718
L719:
    mov esi, ebp
    call Lrd_slow
    jmp L720
    ALIGN 16
Lf_D9:
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L721
L722:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L723
L724:
    movzx r11d, byte ptr [rdi+rsi]
    inc r9w
    shl r11d, 8
    or r11d, r10d
    mov ebp, r11d
    add r14, 4
    mov byte ptr [r15+24], al
    mov byte ptr [r15+25], r8b
    mov edi, ecx
    rol di, 8
    mov word ptr [r15+26], di
    mov edi, edx
    rol di, 8
    mov word ptr [r15+28], di
    mov edi, ebx
    rol di, 8
    mov word ptr [r15+30], di
    mov word ptr [r15+32], r9w
    mov word ptr [r15+34], bp
    cmp byte ptr [r15+572659], 0
    jne L725
    mov qword ptr [r15+40], r14
    movzx edi, word ptr [r15+572656]
    add edi, r14d
    mov word ptr [r15+65858], di
L725:
    sub rsp, 32
    mov rcx, r15
    mov edx, 217
    call gbc_asm_op
    add rsp, 32
    movzx eax, byte ptr [r15+24]
    movzx r8d, byte ptr [r15+25]
    movzx ecx, word ptr [r15+26]
    rol cx, 8
    movzx edx, word ptr [r15+28]
    rol dx, 8
    movzx ebx, word ptr [r15+30]
    rol bx, 8
    movzx r9d, word ptr [r15+32]
    movzx ebp, word ptr [r15+34]
    mov r14, qword ptr [r15+40]
    mov r13, qword ptr [r15+572608]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L726
L727:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L721:
    call Lrd_slow
    jmp L722
L723:
    call Lrd_slow
    jmp L724
L726:
    mov esi, ebp
    call Lrd_slow
    jmp L727
    ALIGN 16
Lf_DA:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L728
L729:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L730
L731:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    test r8b, 16
    jz L732
    mov ebp, r11d
    add r14, 4
L732:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L733
L734:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L728:
    call Lrd_slow
    jmp L729
L730:
    call Lrd_slow
    jmp L731
L733:
    mov esi, ebp
    call Lrd_slow
    jmp L734
    ALIGN 16
Lf_DB:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L735
L736:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L735:
    mov esi, ebp
    call Lrd_slow
    jmp L736
    ALIGN 16
Lf_DC:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L737
L738:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L739
L740:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    test r8b, 16
    jz L741
    add r14, 4
    mov dword ptr [rsp+48], r11d
    mov r11d, ebp
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L742
    mov byte ptr [rdi+rsi], r10b
L743:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L744
L745:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L746
    mov byte ptr [rdi+rsi], r11b
L747:
    mov ebp, dword ptr [rsp+48]
L741:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L748
L749:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L737:
    call Lrd_slow
    jmp L738
L739:
    call Lrd_slow
    jmp L740
L742:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L743
L744:
    call Ltick_slow4
    jmp L745
L746:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L747
L748:
    mov esi, ebp
    call Lrd_slow
    jmp L749
    ALIGN 16
Lf_DD:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L750
L751:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L750:
    mov esi, ebp
    call Lrd_slow
    jmp L751
    ALIGN 16
Lf_DE:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L752
L753:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    bt r8d, 4
    sbb al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L754
L755:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L752:
    call Lrd_slow
    jmp L753
L754:
    mov esi, ebp
    call Lrd_slow
    jmp L755
    ALIGN 16
Lf_DF:
    add r14, 4
    mov r11d, ebp
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L756
    mov byte ptr [rdi+rsi], r10b
L757:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L758
L759:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L760
    mov byte ptr [rdi+rsi], r11b
L761:
    mov ebp, 24
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L762
L763:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L756:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L757
L758:
    call Ltick_slow4
    jmp L759
L760:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L761
L762:
    mov esi, ebp
    call Lrd_slow
    jmp L763
    ALIGN 16
Lf_E0:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L766
L767:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    cmp r10d, 128
    jb L764
    cmp r10d, 255
    je L764
    add r14, 4
    mov rdi, qword ptr [r15+572560]
    mov byte ptr [rdi+r10+65280], al
    jmp L765
L764:
    movzx esi, r10b
    or esi, 65280
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L768
    mov byte ptr [rdi+rsi], al
L769:
L765:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L770
L771:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L766:
    call Lrd_slow
    jmp L767
L768:
    mov byte ptr [rsp+40], al
    call Lwr_slow
    jmp L769
L770:
    mov esi, ebp
    call Lrd_slow
    jmp L771
    ALIGN 16
Lf_E1:
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L772
L773:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L774
L775:
    movzx r11d, byte ptr [rdi+rsi]
    inc r9w
    shl r11d, 8
    or r11d, r10d
    mov ebx, r11d
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L776
L777:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L772:
    call Lrd_slow
    jmp L773
L774:
    call Lrd_slow
    jmp L775
L776:
    mov esi, ebp
    call Lrd_slow
    jmp L777
    ALIGN 16
Lf_E2:
    movzx esi, cl
    or esi, 65280
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L778
    mov byte ptr [rdi+rsi], al
L779:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L780
L781:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L778:
    mov byte ptr [rsp+40], al
    call Lwr_slow
    jmp L779
L780:
    mov esi, ebp
    call Lrd_slow
    jmp L781
    ALIGN 16
Lf_E3:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L782
L783:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L782:
    mov esi, ebp
    call Lrd_slow
    jmp L783
    ALIGN 16
Lf_E4:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L784
L785:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L784:
    mov esi, ebp
    call Lrd_slow
    jmp L785
    ALIGN 16
Lf_E5:
    add r14, 4
    mov r11d, ebx
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L786
    mov byte ptr [rdi+rsi], r10b
L787:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L788
L789:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L790
    mov byte ptr [rdi+rsi], r11b
L791:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L792
L793:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L786:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L787
L788:
    call Ltick_slow4
    jmp L789
L790:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L791
L792:
    mov esi, ebp
    call Lrd_slow
    jmp L793
    ALIGN 16
Lf_E6:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L794
L795:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    and al, r10b
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573976]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L796
L797:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L794:
    call Lrd_slow
    jmp L795
L796:
    mov esi, ebp
    call Lrd_slow
    jmp L797
    ALIGN 16
Lf_E7:
    add r14, 4
    mov r11d, ebp
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L798
    mov byte ptr [rdi+rsi], r10b
L799:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L800
L801:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L802
    mov byte ptr [rdi+rsi], r11b
L803:
    mov ebp, 32
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L804
L805:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L798:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L799
L800:
    call Ltick_slow4
    jmp L801
L802:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L803
L804:
    mov esi, ebp
    call Lrd_slow
    jmp L805
    ALIGN 16
Lf_E8:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L806
L807:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov edi, r9d
    and edi, 255
    add edi, r10d
    mov esi, r9d
    and esi, 15
    mov r11d, r10d
    and r11d, 15
    add esi, r11d
    shr edi, 4
    and edi, 16
    shl esi, 1
    and esi, 32
    mov r8d, edi
    or r8d, esi
    movsx r10d, r10b
    add r10d, r9d
    and r10d, 65535
    mov r9d, r10d
    add r14, 8
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L808
L809:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L806:
    call Lrd_slow
    jmp L807
L808:
    mov esi, ebp
    call Lrd_slow
    jmp L809
    ALIGN 16
Lf_E9:
    mov ebp, ebx
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L810
L811:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L810:
    mov esi, ebp
    call Lrd_slow
    jmp L811
    ALIGN 16
Lf_EA:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L812
L813:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L814
L815:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    mov esi, r11d
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L816
    mov byte ptr [rdi+rsi], al
L817:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L818
L819:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L812:
    call Lrd_slow
    jmp L813
L814:
    call Lrd_slow
    jmp L815
L816:
    mov byte ptr [rsp+40], al
    call Lwr_slow
    jmp L817
L818:
    mov esi, ebp
    call Lrd_slow
    jmp L819
    ALIGN 16
Lf_EB:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L820
L821:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L820:
    mov esi, ebp
    call Lrd_slow
    jmp L821
    ALIGN 16
Lf_EC:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L822
L823:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L822:
    mov esi, ebp
    call Lrd_slow
    jmp L823
    ALIGN 16
Lf_ED:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L824
L825:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L824:
    mov esi, ebp
    call Lrd_slow
    jmp L825
    ALIGN 16
Lf_EE:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L826
L827:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    xor al, r10b
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573720]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L828
L829:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L826:
    call Lrd_slow
    jmp L827
L828:
    mov esi, ebp
    call Lrd_slow
    jmp L829
    ALIGN 16
Lf_EF:
    add r14, 4
    mov r11d, ebp
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L830
    mov byte ptr [rdi+rsi], r10b
L831:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L832
L833:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L834
    mov byte ptr [rdi+rsi], r11b
L835:
    mov ebp, 40
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L836
L837:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L830:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L831
L832:
    call Ltick_slow4
    jmp L833
L834:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L835
L836:
    mov esi, ebp
    call Lrd_slow
    jmp L837
    ALIGN 16
Lf_F0:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L840
L841:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    cmp r10d, 128
    jb L838
    cmp r10d, 255
    je L838
    add r14, 4
    mov rdi, qword ptr [r15+572560]
    mov al, byte ptr [rdi+r10+65280]
    jmp L839
L838:
    movzx esi, r10b
    or esi, 65280
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L842
L843:
    mov al, byte ptr [rdi+rsi]
L839:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L844
L845:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L840:
    call Lrd_slow
    jmp L841
L842:
    call Lrd_slow
    jmp L843
L844:
    mov esi, ebp
    call Lrd_slow
    jmp L845
    ALIGN 16
Lf_F1:
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L846
L847:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L848
L849:
    movzx r11d, byte ptr [rdi+rsi]
    inc r9w
    shl r11d, 8
    or r11d, r10d
    mov eax, r11d
    shr eax, 8
    mov r8d, r11d
    and r8d, 240
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L850
L851:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L846:
    call Lrd_slow
    jmp L847
L848:
    call Lrd_slow
    jmp L849
L850:
    mov esi, ebp
    call Lrd_slow
    jmp L851
    ALIGN 16
Lf_F2:
    movzx esi, cl
    or esi, 65280
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L852
L853:
    mov al, byte ptr [rdi+rsi]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L854
L855:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L852:
    call Lrd_slow
    jmp L853
L854:
    mov esi, ebp
    call Lrd_slow
    jmp L855
    ALIGN 16
Lf_F3:
    mov byte ptr [r15+24], al
    mov byte ptr [r15+25], r8b
    mov edi, ecx
    rol di, 8
    mov word ptr [r15+26], di
    mov edi, edx
    rol di, 8
    mov word ptr [r15+28], di
    mov edi, ebx
    rol di, 8
    mov word ptr [r15+30], di
    mov word ptr [r15+32], r9w
    mov word ptr [r15+34], bp
    cmp byte ptr [r15+572659], 0
    jne L856
    mov qword ptr [r15+40], r14
    movzx edi, word ptr [r15+572656]
    add edi, r14d
    mov word ptr [r15+65858], di
L856:
    sub rsp, 32
    mov rcx, r15
    mov edx, 243
    call gbc_asm_op
    add rsp, 32
    movzx eax, byte ptr [r15+24]
    movzx r8d, byte ptr [r15+25]
    movzx ecx, word ptr [r15+26]
    rol cx, 8
    movzx edx, word ptr [r15+28]
    rol dx, 8
    movzx ebx, word ptr [r15+30]
    rol bx, 8
    movzx r9d, word ptr [r15+32]
    movzx ebp, word ptr [r15+34]
    mov r14, qword ptr [r15+40]
    mov r13, qword ptr [r15+572608]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L857
L858:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L857:
    mov esi, ebp
    call Lrd_slow
    jmp L858
    ALIGN 16
Lf_F4:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L859
L860:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L859:
    mov esi, ebp
    call Lrd_slow
    jmp L860
    ALIGN 16
Lf_F5:
    add r14, 4
    movzx r11d, al
    shl r11d, 8
    or r11d, r8d
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L861
    mov byte ptr [rdi+rsi], r10b
L862:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L863
L864:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L865
    mov byte ptr [rdi+rsi], r11b
L866:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L867
L868:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L861:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L862
L863:
    call Ltick_slow4
    jmp L864
L865:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L866
L867:
    mov esi, ebp
    call Lrd_slow
    jmp L868
    ALIGN 16
Lf_F6:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L869
L870:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    or al, r10b
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573720]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L871
L872:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L869:
    call Lrd_slow
    jmp L870
L871:
    mov esi, ebp
    call Lrd_slow
    jmp L872
    ALIGN 16
Lf_F7:
    add r14, 4
    mov r11d, ebp
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L873
    mov byte ptr [rdi+rsi], r10b
L874:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L875
L876:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L877
    mov byte ptr [rdi+rsi], r11b
L878:
    mov ebp, 48
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L879
L880:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L873:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L874
L875:
    call Ltick_slow4
    jmp L876
L877:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L878
L879:
    mov esi, ebp
    call Lrd_slow
    jmp L880
    ALIGN 16
Lf_F8:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L881
L882:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov edi, r9d
    and edi, 255
    add edi, r10d
    mov esi, r9d
    and esi, 15
    mov r11d, r10d
    and r11d, 15
    add esi, r11d
    shr edi, 4
    and edi, 16
    shl esi, 1
    and esi, 32
    mov r8d, edi
    or r8d, esi
    movsx r10d, r10b
    add r10d, r9d
    and r10d, 65535
    mov ebx, r10d
    add r14, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L883
L884:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L881:
    call Lrd_slow
    jmp L882
L883:
    mov esi, ebp
    call Lrd_slow
    jmp L884
    ALIGN 16
Lf_F9:
    mov r9d, ebx
    add r14, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L885
L886:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L885:
    mov esi, ebp
    call Lrd_slow
    jmp L886
    ALIGN 16
Lf_FA:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L887
L888:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L889
L890:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    mov esi, r11d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L891
L892:
    mov al, byte ptr [rdi+rsi]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L893
L894:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L887:
    call Lrd_slow
    jmp L888
L889:
    call Lrd_slow
    jmp L890
L891:
    call Lrd_slow
    jmp L892
L893:
    mov esi, ebp
    call Lrd_slow
    jmp L894
    ALIGN 16
Lf_FB:
    mov byte ptr [r15+24], al
    mov byte ptr [r15+25], r8b
    mov edi, ecx
    rol di, 8
    mov word ptr [r15+26], di
    mov edi, edx
    rol di, 8
    mov word ptr [r15+28], di
    mov edi, ebx
    rol di, 8
    mov word ptr [r15+30], di
    mov word ptr [r15+32], r9w
    mov word ptr [r15+34], bp
    cmp byte ptr [r15+572659], 0
    jne L895
    mov qword ptr [r15+40], r14
    movzx edi, word ptr [r15+572656]
    add edi, r14d
    mov word ptr [r15+65858], di
L895:
    sub rsp, 32
    mov rcx, r15
    mov edx, 251
    call gbc_asm_op
    add rsp, 32
    movzx eax, byte ptr [r15+24]
    movzx r8d, byte ptr [r15+25]
    movzx ecx, word ptr [r15+26]
    rol cx, 8
    movzx edx, word ptr [r15+28]
    rol dx, 8
    movzx ebx, word ptr [r15+30]
    rol bx, 8
    movzx r9d, word ptr [r15+32]
    movzx ebp, word ptr [r15+34]
    mov r14, qword ptr [r15+40]
    mov r13, qword ptr [r15+572608]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L896
L897:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L896:
    mov esi, ebp
    call Lrd_slow
    jmp L897
    ALIGN 16
Lf_FC:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L898
L899:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L898:
    mov esi, ebp
    call Lrd_slow
    jmp L899
    ALIGN 16
Lf_FD:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L900
L901:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L900:
    mov esi, ebp
    call Lrd_slow
    jmp L901
    ALIGN 16
Lf_FE:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L902
L903:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    cmp al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L904
L905:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L902:
    call Lrd_slow
    jmp L903
L904:
    mov esi, ebp
    call Lrd_slow
    jmp L905
    ALIGN 16
Lf_FF:
    add r14, 4
    mov r11d, ebp
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L906
    mov byte ptr [rdi+rsi], r10b
L907:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L908
L909:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L910
    mov byte ptr [rdi+rsi], r11b
L911:
    mov ebp, 56
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L912
L913:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L906:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L907
L908:
    call Ltick_slow4
    jmp L909
L910:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L911
L912:
    mov esi, ebp
    call Lrd_slow
    jmp L913
    ALIGN 16
Lfcb_00:
    rol ch, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, ch
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L914
L915:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L914:
    mov esi, ebp
    call Lrd_slow
    jmp L915
    ALIGN 16
Lfcb_01:
    rol cl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, cl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L916
L917:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L916:
    mov esi, ebp
    call Lrd_slow
    jmp L917
    ALIGN 16
Lfcb_02:
    rol dh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dh
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L918
L919:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L918:
    mov esi, ebp
    call Lrd_slow
    jmp L919
    ALIGN 16
Lfcb_03:
    rol dl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L920
L921:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L920:
    mov esi, ebp
    call Lrd_slow
    jmp L921
    ALIGN 16
Lfcb_04:
    rol bh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bh
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L922
L923:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L922:
    mov esi, ebp
    call Lrd_slow
    jmp L923
    ALIGN 16
Lfcb_05:
    rol bl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L924
L925:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L924:
    mov esi, ebp
    call Lrd_slow
    jmp L925
    ALIGN 16
Lfcb_06:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L926
L927:
    movzx r10d, byte ptr [rdi+rsi]
    rol r10b, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, r10b
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L928
    mov byte ptr [rdi+rsi], r10b
L929:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L930
L931:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L926:
    call Lrd_slow
    jmp L927
L928:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L929
L930:
    mov esi, ebp
    call Lrd_slow
    jmp L931
    ALIGN 16
Lfcb_07:
    rol al, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, al
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L932
L933:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L932:
    mov esi, ebp
    call Lrd_slow
    jmp L933
    ALIGN 16
Lfcb_08:
    ror ch, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, ch
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L934
L935:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L934:
    mov esi, ebp
    call Lrd_slow
    jmp L935
    ALIGN 16
Lfcb_09:
    ror cl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, cl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L936
L937:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L936:
    mov esi, ebp
    call Lrd_slow
    jmp L937
    ALIGN 16
Lfcb_0A:
    ror dh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dh
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L938
L939:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L938:
    mov esi, ebp
    call Lrd_slow
    jmp L939
    ALIGN 16
Lfcb_0B:
    ror dl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L940
L941:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L940:
    mov esi, ebp
    call Lrd_slow
    jmp L941
    ALIGN 16
Lfcb_0C:
    ror bh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bh
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L942
L943:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L942:
    mov esi, ebp
    call Lrd_slow
    jmp L943
    ALIGN 16
Lfcb_0D:
    ror bl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L944
L945:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L944:
    mov esi, ebp
    call Lrd_slow
    jmp L945
    ALIGN 16
Lfcb_0E:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L946
L947:
    movzx r10d, byte ptr [rdi+rsi]
    ror r10b, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, r10b
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L948
    mov byte ptr [rdi+rsi], r10b
L949:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L950
L951:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L946:
    call Lrd_slow
    jmp L947
L948:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L949
L950:
    mov esi, ebp
    call Lrd_slow
    jmp L951
    ALIGN 16
Lfcb_0F:
    ror al, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, al
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L952
L953:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L952:
    mov esi, ebp
    call Lrd_slow
    jmp L953
    ALIGN 16
Lfcb_10:
    bt r8d, 4
    rcl ch, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, ch
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L954
L955:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L954:
    mov esi, ebp
    call Lrd_slow
    jmp L955
    ALIGN 16
Lfcb_11:
    bt r8d, 4
    rcl cl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, cl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L956
L957:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L956:
    mov esi, ebp
    call Lrd_slow
    jmp L957
    ALIGN 16
Lfcb_12:
    bt r8d, 4
    rcl dh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dh
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L958
L959:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L958:
    mov esi, ebp
    call Lrd_slow
    jmp L959
    ALIGN 16
Lfcb_13:
    bt r8d, 4
    rcl dl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L960
L961:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L960:
    mov esi, ebp
    call Lrd_slow
    jmp L961
    ALIGN 16
Lfcb_14:
    bt r8d, 4
    rcl bh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bh
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L962
L963:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L962:
    mov esi, ebp
    call Lrd_slow
    jmp L963
    ALIGN 16
Lfcb_15:
    bt r8d, 4
    rcl bl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L964
L965:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L964:
    mov esi, ebp
    call Lrd_slow
    jmp L965
    ALIGN 16
Lfcb_16:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L966
L967:
    movzx r10d, byte ptr [rdi+rsi]
    bt r8d, 4
    rcl r10b, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, r10b
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L968
    mov byte ptr [rdi+rsi], r10b
L969:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L970
L971:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L966:
    call Lrd_slow
    jmp L967
L968:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L969
L970:
    mov esi, ebp
    call Lrd_slow
    jmp L971
    ALIGN 16
Lfcb_17:
    bt r8d, 4
    rcl al, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, al
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L972
L973:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L972:
    mov esi, ebp
    call Lrd_slow
    jmp L973
    ALIGN 16
Lfcb_18:
    bt r8d, 4
    rcr ch, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, ch
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L974
L975:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L974:
    mov esi, ebp
    call Lrd_slow
    jmp L975
    ALIGN 16
Lfcb_19:
    bt r8d, 4
    rcr cl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, cl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L976
L977:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L976:
    mov esi, ebp
    call Lrd_slow
    jmp L977
    ALIGN 16
Lfcb_1A:
    bt r8d, 4
    rcr dh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dh
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L978
L979:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L978:
    mov esi, ebp
    call Lrd_slow
    jmp L979
    ALIGN 16
Lfcb_1B:
    bt r8d, 4
    rcr dl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L980
L981:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L980:
    mov esi, ebp
    call Lrd_slow
    jmp L981
    ALIGN 16
Lfcb_1C:
    bt r8d, 4
    rcr bh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bh
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L982
L983:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L982:
    mov esi, ebp
    call Lrd_slow
    jmp L983
    ALIGN 16
Lfcb_1D:
    bt r8d, 4
    rcr bl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L984
L985:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L984:
    mov esi, ebp
    call Lrd_slow
    jmp L985
    ALIGN 16
Lfcb_1E:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L986
L987:
    movzx r10d, byte ptr [rdi+rsi]
    bt r8d, 4
    rcr r10b, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, r10b
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L988
    mov byte ptr [rdi+rsi], r10b
L989:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L990
L991:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L986:
    call Lrd_slow
    jmp L987
L988:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L989
L990:
    mov esi, ebp
    call Lrd_slow
    jmp L991
    ALIGN 16
Lfcb_1F:
    bt r8d, 4
    rcr al, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, al
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L992
L993:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L992:
    mov esi, ebp
    call Lrd_slow
    jmp L993
    ALIGN 16
Lfcb_20:
    shl ch, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, ch
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L994
L995:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L994:
    mov esi, ebp
    call Lrd_slow
    jmp L995
    ALIGN 16
Lfcb_21:
    shl cl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, cl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L996
L997:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L996:
    mov esi, ebp
    call Lrd_slow
    jmp L997
    ALIGN 16
Lfcb_22:
    shl dh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dh
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L998
L999:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L998:
    mov esi, ebp
    call Lrd_slow
    jmp L999
    ALIGN 16
Lfcb_23:
    shl dl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1000
L1001:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1000:
    mov esi, ebp
    call Lrd_slow
    jmp L1001
    ALIGN 16
Lfcb_24:
    shl bh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bh
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1002
L1003:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1002:
    mov esi, ebp
    call Lrd_slow
    jmp L1003
    ALIGN 16
Lfcb_25:
    shl bl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1004
L1005:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1004:
    mov esi, ebp
    call Lrd_slow
    jmp L1005
    ALIGN 16
Lfcb_26:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1006
L1007:
    movzx r10d, byte ptr [rdi+rsi]
    shl r10b, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, r10b
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1008
    mov byte ptr [rdi+rsi], r10b
L1009:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1010
L1011:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1006:
    call Lrd_slow
    jmp L1007
L1008:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1009
L1010:
    mov esi, ebp
    call Lrd_slow
    jmp L1011
    ALIGN 16
Lfcb_27:
    shl al, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, al
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1012
L1013:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1012:
    mov esi, ebp
    call Lrd_slow
    jmp L1013
    ALIGN 16
Lfcb_28:
    sar ch, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, ch
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1014
L1015:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1014:
    mov esi, ebp
    call Lrd_slow
    jmp L1015
    ALIGN 16
Lfcb_29:
    sar cl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, cl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1016
L1017:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1016:
    mov esi, ebp
    call Lrd_slow
    jmp L1017
    ALIGN 16
Lfcb_2A:
    sar dh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dh
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1018
L1019:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1018:
    mov esi, ebp
    call Lrd_slow
    jmp L1019
    ALIGN 16
Lfcb_2B:
    sar dl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1020
L1021:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1020:
    mov esi, ebp
    call Lrd_slow
    jmp L1021
    ALIGN 16
Lfcb_2C:
    sar bh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bh
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1022
L1023:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1022:
    mov esi, ebp
    call Lrd_slow
    jmp L1023
    ALIGN 16
Lfcb_2D:
    sar bl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1024
L1025:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1024:
    mov esi, ebp
    call Lrd_slow
    jmp L1025
    ALIGN 16
Lfcb_2E:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1026
L1027:
    movzx r10d, byte ptr [rdi+rsi]
    sar r10b, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, r10b
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1028
    mov byte ptr [rdi+rsi], r10b
L1029:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1030
L1031:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1026:
    call Lrd_slow
    jmp L1027
L1028:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1029
L1030:
    mov esi, ebp
    call Lrd_slow
    jmp L1031
    ALIGN 16
Lfcb_2F:
    sar al, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, al
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1032
L1033:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1032:
    mov esi, ebp
    call Lrd_slow
    jmp L1033
    ALIGN 16
Lfcb_30:
    rol ch, 4
    movzx edi, ch
    movzx r8d, byte ptr [r15+rdi+573720]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1034
L1035:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1034:
    mov esi, ebp
    call Lrd_slow
    jmp L1035
    ALIGN 16
Lfcb_31:
    rol cl, 4
    movzx edi, cl
    movzx r8d, byte ptr [r15+rdi+573720]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1036
L1037:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1036:
    mov esi, ebp
    call Lrd_slow
    jmp L1037
    ALIGN 16
Lfcb_32:
    rol dh, 4
    movzx edi, dh
    movzx r8d, byte ptr [r15+rdi+573720]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1038
L1039:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1038:
    mov esi, ebp
    call Lrd_slow
    jmp L1039
    ALIGN 16
Lfcb_33:
    rol dl, 4
    movzx edi, dl
    movzx r8d, byte ptr [r15+rdi+573720]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1040
L1041:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1040:
    mov esi, ebp
    call Lrd_slow
    jmp L1041
    ALIGN 16
Lfcb_34:
    rol bh, 4
    movzx edi, bh
    movzx r8d, byte ptr [r15+rdi+573720]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1042
L1043:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1042:
    mov esi, ebp
    call Lrd_slow
    jmp L1043
    ALIGN 16
Lfcb_35:
    rol bl, 4
    movzx edi, bl
    movzx r8d, byte ptr [r15+rdi+573720]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1044
L1045:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1044:
    mov esi, ebp
    call Lrd_slow
    jmp L1045
    ALIGN 16
Lfcb_36:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1046
L1047:
    movzx r10d, byte ptr [rdi+rsi]
    rol r10b, 4
    movzx edi, r10b
    movzx r8d, byte ptr [r15+rdi+573720]
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1048
    mov byte ptr [rdi+rsi], r10b
L1049:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1050
L1051:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1046:
    call Lrd_slow
    jmp L1047
L1048:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1049
L1050:
    mov esi, ebp
    call Lrd_slow
    jmp L1051
    ALIGN 16
Lfcb_37:
    rol al, 4
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573720]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1052
L1053:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1052:
    mov esi, ebp
    call Lrd_slow
    jmp L1053
    ALIGN 16
Lfcb_38:
    shr ch, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, ch
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1054
L1055:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1054:
    mov esi, ebp
    call Lrd_slow
    jmp L1055
    ALIGN 16
Lfcb_39:
    shr cl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, cl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1056
L1057:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1056:
    mov esi, ebp
    call Lrd_slow
    jmp L1057
    ALIGN 16
Lfcb_3A:
    shr dh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dh
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1058
L1059:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1058:
    mov esi, ebp
    call Lrd_slow
    jmp L1059
    ALIGN 16
Lfcb_3B:
    shr dl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1060
L1061:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1060:
    mov esi, ebp
    call Lrd_slow
    jmp L1061
    ALIGN 16
Lfcb_3C:
    shr bh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bh
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1062
L1063:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1062:
    mov esi, ebp
    call Lrd_slow
    jmp L1063
    ALIGN 16
Lfcb_3D:
    shr bl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1064
L1065:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1064:
    mov esi, ebp
    call Lrd_slow
    jmp L1065
    ALIGN 16
Lfcb_3E:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1066
L1067:
    movzx r10d, byte ptr [rdi+rsi]
    shr r10b, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, r10b
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1068
    mov byte ptr [rdi+rsi], r10b
L1069:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1070
L1071:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1066:
    call Lrd_slow
    jmp L1067
L1068:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1069
L1070:
    mov esi, ebp
    call Lrd_slow
    jmp L1071
    ALIGN 16
Lfcb_3F:
    shr al, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, al
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1072
L1073:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1072:
    mov esi, ebp
    call Lrd_slow
    jmp L1073
    ALIGN 16
Lfcb_40:
    mov edi, 0
    test ch, 1
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1074
L1075:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1074:
    mov esi, ebp
    call Lrd_slow
    jmp L1075
    ALIGN 16
Lfcb_41:
    mov edi, 0
    test cl, 1
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1076
L1077:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1076:
    mov esi, ebp
    call Lrd_slow
    jmp L1077
    ALIGN 16
Lfcb_42:
    mov edi, 0
    test dh, 1
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1078
L1079:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1078:
    mov esi, ebp
    call Lrd_slow
    jmp L1079
    ALIGN 16
Lfcb_43:
    mov edi, 0
    test dl, 1
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1080
L1081:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1080:
    mov esi, ebp
    call Lrd_slow
    jmp L1081
    ALIGN 16
Lfcb_44:
    mov edi, 0
    test bh, 1
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1082
L1083:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1082:
    mov esi, ebp
    call Lrd_slow
    jmp L1083
    ALIGN 16
Lfcb_45:
    mov edi, 0
    test bl, 1
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1084
L1085:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1084:
    mov esi, ebp
    call Lrd_slow
    jmp L1085
    ALIGN 16
Lfcb_46:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1086
L1087:
    movzx r10d, byte ptr [rdi+rsi]
    mov edi, 0
    test r10b, 1
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1088
L1089:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1086:
    call Lrd_slow
    jmp L1087
L1088:
    mov esi, ebp
    call Lrd_slow
    jmp L1089
    ALIGN 16
Lfcb_47:
    mov edi, 0
    test al, 1
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1090
L1091:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1090:
    mov esi, ebp
    call Lrd_slow
    jmp L1091
    ALIGN 16
Lfcb_48:
    mov edi, 0
    test ch, 2
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1092
L1093:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1092:
    mov esi, ebp
    call Lrd_slow
    jmp L1093
    ALIGN 16
Lfcb_49:
    mov edi, 0
    test cl, 2
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1094
L1095:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1094:
    mov esi, ebp
    call Lrd_slow
    jmp L1095
    ALIGN 16
Lfcb_4A:
    mov edi, 0
    test dh, 2
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1096
L1097:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1096:
    mov esi, ebp
    call Lrd_slow
    jmp L1097
    ALIGN 16
Lfcb_4B:
    mov edi, 0
    test dl, 2
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1098
L1099:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1098:
    mov esi, ebp
    call Lrd_slow
    jmp L1099
    ALIGN 16
Lfcb_4C:
    mov edi, 0
    test bh, 2
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1100
L1101:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1100:
    mov esi, ebp
    call Lrd_slow
    jmp L1101
    ALIGN 16
Lfcb_4D:
    mov edi, 0
    test bl, 2
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1102
L1103:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1102:
    mov esi, ebp
    call Lrd_slow
    jmp L1103
    ALIGN 16
Lfcb_4E:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1104
L1105:
    movzx r10d, byte ptr [rdi+rsi]
    mov edi, 0
    test r10b, 2
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1106
L1107:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1104:
    call Lrd_slow
    jmp L1105
L1106:
    mov esi, ebp
    call Lrd_slow
    jmp L1107
    ALIGN 16
Lfcb_4F:
    mov edi, 0
    test al, 2
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1108
L1109:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1108:
    mov esi, ebp
    call Lrd_slow
    jmp L1109
    ALIGN 16
Lfcb_50:
    mov edi, 0
    test ch, 4
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1110
L1111:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1110:
    mov esi, ebp
    call Lrd_slow
    jmp L1111
    ALIGN 16
Lfcb_51:
    mov edi, 0
    test cl, 4
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1112
L1113:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1112:
    mov esi, ebp
    call Lrd_slow
    jmp L1113
    ALIGN 16
Lfcb_52:
    mov edi, 0
    test dh, 4
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1114
L1115:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1114:
    mov esi, ebp
    call Lrd_slow
    jmp L1115
    ALIGN 16
Lfcb_53:
    mov edi, 0
    test dl, 4
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1116
L1117:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1116:
    mov esi, ebp
    call Lrd_slow
    jmp L1117
    ALIGN 16
Lfcb_54:
    mov edi, 0
    test bh, 4
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1118
L1119:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1118:
    mov esi, ebp
    call Lrd_slow
    jmp L1119
    ALIGN 16
Lfcb_55:
    mov edi, 0
    test bl, 4
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1120
L1121:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1120:
    mov esi, ebp
    call Lrd_slow
    jmp L1121
    ALIGN 16
Lfcb_56:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1122
L1123:
    movzx r10d, byte ptr [rdi+rsi]
    mov edi, 0
    test r10b, 4
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1124
L1125:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1122:
    call Lrd_slow
    jmp L1123
L1124:
    mov esi, ebp
    call Lrd_slow
    jmp L1125
    ALIGN 16
Lfcb_57:
    mov edi, 0
    test al, 4
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1126
L1127:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1126:
    mov esi, ebp
    call Lrd_slow
    jmp L1127
    ALIGN 16
Lfcb_58:
    mov edi, 0
    test ch, 8
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1128
L1129:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1128:
    mov esi, ebp
    call Lrd_slow
    jmp L1129
    ALIGN 16
Lfcb_59:
    mov edi, 0
    test cl, 8
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1130
L1131:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1130:
    mov esi, ebp
    call Lrd_slow
    jmp L1131
    ALIGN 16
Lfcb_5A:
    mov edi, 0
    test dh, 8
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1132
L1133:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1132:
    mov esi, ebp
    call Lrd_slow
    jmp L1133
    ALIGN 16
Lfcb_5B:
    mov edi, 0
    test dl, 8
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1134
L1135:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1134:
    mov esi, ebp
    call Lrd_slow
    jmp L1135
    ALIGN 16
Lfcb_5C:
    mov edi, 0
    test bh, 8
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1136
L1137:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1136:
    mov esi, ebp
    call Lrd_slow
    jmp L1137
    ALIGN 16
Lfcb_5D:
    mov edi, 0
    test bl, 8
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1138
L1139:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1138:
    mov esi, ebp
    call Lrd_slow
    jmp L1139
    ALIGN 16
Lfcb_5E:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1140
L1141:
    movzx r10d, byte ptr [rdi+rsi]
    mov edi, 0
    test r10b, 8
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1142
L1143:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1140:
    call Lrd_slow
    jmp L1141
L1142:
    mov esi, ebp
    call Lrd_slow
    jmp L1143
    ALIGN 16
Lfcb_5F:
    mov edi, 0
    test al, 8
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1144
L1145:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1144:
    mov esi, ebp
    call Lrd_slow
    jmp L1145
    ALIGN 16
Lfcb_60:
    mov edi, 0
    test ch, 16
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1146
L1147:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1146:
    mov esi, ebp
    call Lrd_slow
    jmp L1147
    ALIGN 16
Lfcb_61:
    mov edi, 0
    test cl, 16
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1148
L1149:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1148:
    mov esi, ebp
    call Lrd_slow
    jmp L1149
    ALIGN 16
Lfcb_62:
    mov edi, 0
    test dh, 16
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1150
L1151:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1150:
    mov esi, ebp
    call Lrd_slow
    jmp L1151
    ALIGN 16
Lfcb_63:
    mov edi, 0
    test dl, 16
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1152
L1153:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1152:
    mov esi, ebp
    call Lrd_slow
    jmp L1153
    ALIGN 16
Lfcb_64:
    mov edi, 0
    test bh, 16
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1154
L1155:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1154:
    mov esi, ebp
    call Lrd_slow
    jmp L1155
    ALIGN 16
Lfcb_65:
    mov edi, 0
    test bl, 16
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1156
L1157:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1156:
    mov esi, ebp
    call Lrd_slow
    jmp L1157
    ALIGN 16
Lfcb_66:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1158
L1159:
    movzx r10d, byte ptr [rdi+rsi]
    mov edi, 0
    test r10b, 16
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1160
L1161:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1158:
    call Lrd_slow
    jmp L1159
L1160:
    mov esi, ebp
    call Lrd_slow
    jmp L1161
    ALIGN 16
Lfcb_67:
    mov edi, 0
    test al, 16
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1162
L1163:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1162:
    mov esi, ebp
    call Lrd_slow
    jmp L1163
    ALIGN 16
Lfcb_68:
    mov edi, 0
    test ch, 32
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1164
L1165:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1164:
    mov esi, ebp
    call Lrd_slow
    jmp L1165
    ALIGN 16
Lfcb_69:
    mov edi, 0
    test cl, 32
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1166
L1167:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1166:
    mov esi, ebp
    call Lrd_slow
    jmp L1167
    ALIGN 16
Lfcb_6A:
    mov edi, 0
    test dh, 32
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1168
L1169:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1168:
    mov esi, ebp
    call Lrd_slow
    jmp L1169
    ALIGN 16
Lfcb_6B:
    mov edi, 0
    test dl, 32
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1170
L1171:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1170:
    mov esi, ebp
    call Lrd_slow
    jmp L1171
    ALIGN 16
Lfcb_6C:
    mov edi, 0
    test bh, 32
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1172
L1173:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1172:
    mov esi, ebp
    call Lrd_slow
    jmp L1173
    ALIGN 16
Lfcb_6D:
    mov edi, 0
    test bl, 32
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1174
L1175:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1174:
    mov esi, ebp
    call Lrd_slow
    jmp L1175
    ALIGN 16
Lfcb_6E:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1176
L1177:
    movzx r10d, byte ptr [rdi+rsi]
    mov edi, 0
    test r10b, 32
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1178
L1179:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1176:
    call Lrd_slow
    jmp L1177
L1178:
    mov esi, ebp
    call Lrd_slow
    jmp L1179
    ALIGN 16
Lfcb_6F:
    mov edi, 0
    test al, 32
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1180
L1181:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1180:
    mov esi, ebp
    call Lrd_slow
    jmp L1181
    ALIGN 16
Lfcb_70:
    mov edi, 0
    test ch, 64
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1182
L1183:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1182:
    mov esi, ebp
    call Lrd_slow
    jmp L1183
    ALIGN 16
Lfcb_71:
    mov edi, 0
    test cl, 64
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1184
L1185:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1184:
    mov esi, ebp
    call Lrd_slow
    jmp L1185
    ALIGN 16
Lfcb_72:
    mov edi, 0
    test dh, 64
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1186
L1187:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1186:
    mov esi, ebp
    call Lrd_slow
    jmp L1187
    ALIGN 16
Lfcb_73:
    mov edi, 0
    test dl, 64
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1188
L1189:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1188:
    mov esi, ebp
    call Lrd_slow
    jmp L1189
    ALIGN 16
Lfcb_74:
    mov edi, 0
    test bh, 64
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1190
L1191:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1190:
    mov esi, ebp
    call Lrd_slow
    jmp L1191
    ALIGN 16
Lfcb_75:
    mov edi, 0
    test bl, 64
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1192
L1193:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1192:
    mov esi, ebp
    call Lrd_slow
    jmp L1193
    ALIGN 16
Lfcb_76:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1194
L1195:
    movzx r10d, byte ptr [rdi+rsi]
    mov edi, 0
    test r10b, 64
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1196
L1197:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1194:
    call Lrd_slow
    jmp L1195
L1196:
    mov esi, ebp
    call Lrd_slow
    jmp L1197
    ALIGN 16
Lfcb_77:
    mov edi, 0
    test al, 64
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1198
L1199:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1198:
    mov esi, ebp
    call Lrd_slow
    jmp L1199
    ALIGN 16
Lfcb_78:
    mov edi, 0
    test ch, 128
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1200
L1201:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1200:
    mov esi, ebp
    call Lrd_slow
    jmp L1201
    ALIGN 16
Lfcb_79:
    mov edi, 0
    test cl, 128
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1202
L1203:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1202:
    mov esi, ebp
    call Lrd_slow
    jmp L1203
    ALIGN 16
Lfcb_7A:
    mov edi, 0
    test dh, 128
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1204
L1205:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1204:
    mov esi, ebp
    call Lrd_slow
    jmp L1205
    ALIGN 16
Lfcb_7B:
    mov edi, 0
    test dl, 128
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1206
L1207:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1206:
    mov esi, ebp
    call Lrd_slow
    jmp L1207
    ALIGN 16
Lfcb_7C:
    mov edi, 0
    test bh, 128
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1208
L1209:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1208:
    mov esi, ebp
    call Lrd_slow
    jmp L1209
    ALIGN 16
Lfcb_7D:
    mov edi, 0
    test bl, 128
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1210
L1211:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1210:
    mov esi, ebp
    call Lrd_slow
    jmp L1211
    ALIGN 16
Lfcb_7E:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1212
L1213:
    movzx r10d, byte ptr [rdi+rsi]
    mov edi, 0
    test r10b, 128
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1214
L1215:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1212:
    call Lrd_slow
    jmp L1213
L1214:
    mov esi, ebp
    call Lrd_slow
    jmp L1215
    ALIGN 16
Lfcb_7F:
    mov edi, 0
    test al, 128
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1216
L1217:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1216:
    mov esi, ebp
    call Lrd_slow
    jmp L1217
    ALIGN 16
Lfcb_80:
    and ch, 254
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1218
L1219:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1218:
    mov esi, ebp
    call Lrd_slow
    jmp L1219
    ALIGN 16
Lfcb_81:
    and cl, 254
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1220
L1221:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1220:
    mov esi, ebp
    call Lrd_slow
    jmp L1221
    ALIGN 16
Lfcb_82:
    and dh, 254
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1222
L1223:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1222:
    mov esi, ebp
    call Lrd_slow
    jmp L1223
    ALIGN 16
Lfcb_83:
    and dl, 254
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1224
L1225:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1224:
    mov esi, ebp
    call Lrd_slow
    jmp L1225
    ALIGN 16
Lfcb_84:
    and bh, 254
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1226
L1227:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1226:
    mov esi, ebp
    call Lrd_slow
    jmp L1227
    ALIGN 16
Lfcb_85:
    and bl, 254
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1228
L1229:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1228:
    mov esi, ebp
    call Lrd_slow
    jmp L1229
    ALIGN 16
Lfcb_86:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1230
L1231:
    movzx r10d, byte ptr [rdi+rsi]
    and r10b, 254
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1232
    mov byte ptr [rdi+rsi], r10b
L1233:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1234
L1235:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1230:
    call Lrd_slow
    jmp L1231
L1232:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1233
L1234:
    mov esi, ebp
    call Lrd_slow
    jmp L1235
    ALIGN 16
Lfcb_87:
    and al, 254
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1236
L1237:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1236:
    mov esi, ebp
    call Lrd_slow
    jmp L1237
    ALIGN 16
Lfcb_88:
    and ch, 253
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1238
L1239:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1238:
    mov esi, ebp
    call Lrd_slow
    jmp L1239
    ALIGN 16
Lfcb_89:
    and cl, 253
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1240
L1241:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1240:
    mov esi, ebp
    call Lrd_slow
    jmp L1241
    ALIGN 16
Lfcb_8A:
    and dh, 253
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1242
L1243:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1242:
    mov esi, ebp
    call Lrd_slow
    jmp L1243
    ALIGN 16
Lfcb_8B:
    and dl, 253
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1244
L1245:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1244:
    mov esi, ebp
    call Lrd_slow
    jmp L1245
    ALIGN 16
Lfcb_8C:
    and bh, 253
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1246
L1247:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1246:
    mov esi, ebp
    call Lrd_slow
    jmp L1247
    ALIGN 16
Lfcb_8D:
    and bl, 253
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1248
L1249:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1248:
    mov esi, ebp
    call Lrd_slow
    jmp L1249
    ALIGN 16
Lfcb_8E:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1250
L1251:
    movzx r10d, byte ptr [rdi+rsi]
    and r10b, 253
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1252
    mov byte ptr [rdi+rsi], r10b
L1253:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1254
L1255:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1250:
    call Lrd_slow
    jmp L1251
L1252:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1253
L1254:
    mov esi, ebp
    call Lrd_slow
    jmp L1255
    ALIGN 16
Lfcb_8F:
    and al, 253
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1256
L1257:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1256:
    mov esi, ebp
    call Lrd_slow
    jmp L1257
    ALIGN 16
Lfcb_90:
    and ch, 251
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1258
L1259:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1258:
    mov esi, ebp
    call Lrd_slow
    jmp L1259
    ALIGN 16
Lfcb_91:
    and cl, 251
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1260
L1261:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1260:
    mov esi, ebp
    call Lrd_slow
    jmp L1261
    ALIGN 16
Lfcb_92:
    and dh, 251
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1262
L1263:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1262:
    mov esi, ebp
    call Lrd_slow
    jmp L1263
    ALIGN 16
Lfcb_93:
    and dl, 251
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1264
L1265:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1264:
    mov esi, ebp
    call Lrd_slow
    jmp L1265
    ALIGN 16
Lfcb_94:
    and bh, 251
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1266
L1267:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1266:
    mov esi, ebp
    call Lrd_slow
    jmp L1267
    ALIGN 16
Lfcb_95:
    and bl, 251
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1268
L1269:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1268:
    mov esi, ebp
    call Lrd_slow
    jmp L1269
    ALIGN 16
Lfcb_96:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1270
L1271:
    movzx r10d, byte ptr [rdi+rsi]
    and r10b, 251
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1272
    mov byte ptr [rdi+rsi], r10b
L1273:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1274
L1275:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1270:
    call Lrd_slow
    jmp L1271
L1272:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1273
L1274:
    mov esi, ebp
    call Lrd_slow
    jmp L1275
    ALIGN 16
Lfcb_97:
    and al, 251
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1276
L1277:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1276:
    mov esi, ebp
    call Lrd_slow
    jmp L1277
    ALIGN 16
Lfcb_98:
    and ch, 247
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1278
L1279:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1278:
    mov esi, ebp
    call Lrd_slow
    jmp L1279
    ALIGN 16
Lfcb_99:
    and cl, 247
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1280
L1281:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1280:
    mov esi, ebp
    call Lrd_slow
    jmp L1281
    ALIGN 16
Lfcb_9A:
    and dh, 247
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1282
L1283:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1282:
    mov esi, ebp
    call Lrd_slow
    jmp L1283
    ALIGN 16
Lfcb_9B:
    and dl, 247
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1284
L1285:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1284:
    mov esi, ebp
    call Lrd_slow
    jmp L1285
    ALIGN 16
Lfcb_9C:
    and bh, 247
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1286
L1287:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1286:
    mov esi, ebp
    call Lrd_slow
    jmp L1287
    ALIGN 16
Lfcb_9D:
    and bl, 247
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1288
L1289:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1288:
    mov esi, ebp
    call Lrd_slow
    jmp L1289
    ALIGN 16
Lfcb_9E:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1290
L1291:
    movzx r10d, byte ptr [rdi+rsi]
    and r10b, 247
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1292
    mov byte ptr [rdi+rsi], r10b
L1293:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1294
L1295:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1290:
    call Lrd_slow
    jmp L1291
L1292:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1293
L1294:
    mov esi, ebp
    call Lrd_slow
    jmp L1295
    ALIGN 16
Lfcb_9F:
    and al, 247
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1296
L1297:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1296:
    mov esi, ebp
    call Lrd_slow
    jmp L1297
    ALIGN 16
Lfcb_A0:
    and ch, 239
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1298
L1299:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1298:
    mov esi, ebp
    call Lrd_slow
    jmp L1299
    ALIGN 16
Lfcb_A1:
    and cl, 239
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1300
L1301:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1300:
    mov esi, ebp
    call Lrd_slow
    jmp L1301
    ALIGN 16
Lfcb_A2:
    and dh, 239
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1302
L1303:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1302:
    mov esi, ebp
    call Lrd_slow
    jmp L1303
    ALIGN 16
Lfcb_A3:
    and dl, 239
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1304
L1305:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1304:
    mov esi, ebp
    call Lrd_slow
    jmp L1305
    ALIGN 16
Lfcb_A4:
    and bh, 239
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1306
L1307:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1306:
    mov esi, ebp
    call Lrd_slow
    jmp L1307
    ALIGN 16
Lfcb_A5:
    and bl, 239
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1308
L1309:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1308:
    mov esi, ebp
    call Lrd_slow
    jmp L1309
    ALIGN 16
Lfcb_A6:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1310
L1311:
    movzx r10d, byte ptr [rdi+rsi]
    and r10b, 239
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1312
    mov byte ptr [rdi+rsi], r10b
L1313:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1314
L1315:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1310:
    call Lrd_slow
    jmp L1311
L1312:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1313
L1314:
    mov esi, ebp
    call Lrd_slow
    jmp L1315
    ALIGN 16
Lfcb_A7:
    and al, 239
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1316
L1317:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1316:
    mov esi, ebp
    call Lrd_slow
    jmp L1317
    ALIGN 16
Lfcb_A8:
    and ch, 223
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1318
L1319:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1318:
    mov esi, ebp
    call Lrd_slow
    jmp L1319
    ALIGN 16
Lfcb_A9:
    and cl, 223
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1320
L1321:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1320:
    mov esi, ebp
    call Lrd_slow
    jmp L1321
    ALIGN 16
Lfcb_AA:
    and dh, 223
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1322
L1323:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1322:
    mov esi, ebp
    call Lrd_slow
    jmp L1323
    ALIGN 16
Lfcb_AB:
    and dl, 223
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1324
L1325:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1324:
    mov esi, ebp
    call Lrd_slow
    jmp L1325
    ALIGN 16
Lfcb_AC:
    and bh, 223
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1326
L1327:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1326:
    mov esi, ebp
    call Lrd_slow
    jmp L1327
    ALIGN 16
Lfcb_AD:
    and bl, 223
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1328
L1329:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1328:
    mov esi, ebp
    call Lrd_slow
    jmp L1329
    ALIGN 16
Lfcb_AE:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1330
L1331:
    movzx r10d, byte ptr [rdi+rsi]
    and r10b, 223
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1332
    mov byte ptr [rdi+rsi], r10b
L1333:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1334
L1335:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1330:
    call Lrd_slow
    jmp L1331
L1332:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1333
L1334:
    mov esi, ebp
    call Lrd_slow
    jmp L1335
    ALIGN 16
Lfcb_AF:
    and al, 223
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1336
L1337:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1336:
    mov esi, ebp
    call Lrd_slow
    jmp L1337
    ALIGN 16
Lfcb_B0:
    and ch, 191
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1338
L1339:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1338:
    mov esi, ebp
    call Lrd_slow
    jmp L1339
    ALIGN 16
Lfcb_B1:
    and cl, 191
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1340
L1341:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1340:
    mov esi, ebp
    call Lrd_slow
    jmp L1341
    ALIGN 16
Lfcb_B2:
    and dh, 191
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1342
L1343:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1342:
    mov esi, ebp
    call Lrd_slow
    jmp L1343
    ALIGN 16
Lfcb_B3:
    and dl, 191
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1344
L1345:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1344:
    mov esi, ebp
    call Lrd_slow
    jmp L1345
    ALIGN 16
Lfcb_B4:
    and bh, 191
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1346
L1347:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1346:
    mov esi, ebp
    call Lrd_slow
    jmp L1347
    ALIGN 16
Lfcb_B5:
    and bl, 191
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1348
L1349:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1348:
    mov esi, ebp
    call Lrd_slow
    jmp L1349
    ALIGN 16
Lfcb_B6:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1350
L1351:
    movzx r10d, byte ptr [rdi+rsi]
    and r10b, 191
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1352
    mov byte ptr [rdi+rsi], r10b
L1353:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1354
L1355:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1350:
    call Lrd_slow
    jmp L1351
L1352:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1353
L1354:
    mov esi, ebp
    call Lrd_slow
    jmp L1355
    ALIGN 16
Lfcb_B7:
    and al, 191
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1356
L1357:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1356:
    mov esi, ebp
    call Lrd_slow
    jmp L1357
    ALIGN 16
Lfcb_B8:
    and ch, 127
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1358
L1359:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1358:
    mov esi, ebp
    call Lrd_slow
    jmp L1359
    ALIGN 16
Lfcb_B9:
    and cl, 127
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1360
L1361:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1360:
    mov esi, ebp
    call Lrd_slow
    jmp L1361
    ALIGN 16
Lfcb_BA:
    and dh, 127
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1362
L1363:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1362:
    mov esi, ebp
    call Lrd_slow
    jmp L1363
    ALIGN 16
Lfcb_BB:
    and dl, 127
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1364
L1365:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1364:
    mov esi, ebp
    call Lrd_slow
    jmp L1365
    ALIGN 16
Lfcb_BC:
    and bh, 127
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1366
L1367:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1366:
    mov esi, ebp
    call Lrd_slow
    jmp L1367
    ALIGN 16
Lfcb_BD:
    and bl, 127
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1368
L1369:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1368:
    mov esi, ebp
    call Lrd_slow
    jmp L1369
    ALIGN 16
Lfcb_BE:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1370
L1371:
    movzx r10d, byte ptr [rdi+rsi]
    and r10b, 127
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1372
    mov byte ptr [rdi+rsi], r10b
L1373:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1374
L1375:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1370:
    call Lrd_slow
    jmp L1371
L1372:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1373
L1374:
    mov esi, ebp
    call Lrd_slow
    jmp L1375
    ALIGN 16
Lfcb_BF:
    and al, 127
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1376
L1377:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1376:
    mov esi, ebp
    call Lrd_slow
    jmp L1377
    ALIGN 16
Lfcb_C0:
    or ch, 1
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1378
L1379:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1378:
    mov esi, ebp
    call Lrd_slow
    jmp L1379
    ALIGN 16
Lfcb_C1:
    or cl, 1
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1380
L1381:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1380:
    mov esi, ebp
    call Lrd_slow
    jmp L1381
    ALIGN 16
Lfcb_C2:
    or dh, 1
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1382
L1383:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1382:
    mov esi, ebp
    call Lrd_slow
    jmp L1383
    ALIGN 16
Lfcb_C3:
    or dl, 1
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1384
L1385:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1384:
    mov esi, ebp
    call Lrd_slow
    jmp L1385
    ALIGN 16
Lfcb_C4:
    or bh, 1
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1386
L1387:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1386:
    mov esi, ebp
    call Lrd_slow
    jmp L1387
    ALIGN 16
Lfcb_C5:
    or bl, 1
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1388
L1389:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1388:
    mov esi, ebp
    call Lrd_slow
    jmp L1389
    ALIGN 16
Lfcb_C6:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1390
L1391:
    movzx r10d, byte ptr [rdi+rsi]
    or r10b, 1
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1392
    mov byte ptr [rdi+rsi], r10b
L1393:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1394
L1395:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1390:
    call Lrd_slow
    jmp L1391
L1392:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1393
L1394:
    mov esi, ebp
    call Lrd_slow
    jmp L1395
    ALIGN 16
Lfcb_C7:
    or al, 1
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1396
L1397:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1396:
    mov esi, ebp
    call Lrd_slow
    jmp L1397
    ALIGN 16
Lfcb_C8:
    or ch, 2
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1398
L1399:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1398:
    mov esi, ebp
    call Lrd_slow
    jmp L1399
    ALIGN 16
Lfcb_C9:
    or cl, 2
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1400
L1401:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1400:
    mov esi, ebp
    call Lrd_slow
    jmp L1401
    ALIGN 16
Lfcb_CA:
    or dh, 2
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1402
L1403:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1402:
    mov esi, ebp
    call Lrd_slow
    jmp L1403
    ALIGN 16
Lfcb_CB:
    or dl, 2
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1404
L1405:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1404:
    mov esi, ebp
    call Lrd_slow
    jmp L1405
    ALIGN 16
Lfcb_CC:
    or bh, 2
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1406
L1407:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1406:
    mov esi, ebp
    call Lrd_slow
    jmp L1407
    ALIGN 16
Lfcb_CD:
    or bl, 2
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1408
L1409:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1408:
    mov esi, ebp
    call Lrd_slow
    jmp L1409
    ALIGN 16
Lfcb_CE:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1410
L1411:
    movzx r10d, byte ptr [rdi+rsi]
    or r10b, 2
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1412
    mov byte ptr [rdi+rsi], r10b
L1413:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1414
L1415:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1410:
    call Lrd_slow
    jmp L1411
L1412:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1413
L1414:
    mov esi, ebp
    call Lrd_slow
    jmp L1415
    ALIGN 16
Lfcb_CF:
    or al, 2
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1416
L1417:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1416:
    mov esi, ebp
    call Lrd_slow
    jmp L1417
    ALIGN 16
Lfcb_D0:
    or ch, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1418
L1419:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1418:
    mov esi, ebp
    call Lrd_slow
    jmp L1419
    ALIGN 16
Lfcb_D1:
    or cl, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1420
L1421:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1420:
    mov esi, ebp
    call Lrd_slow
    jmp L1421
    ALIGN 16
Lfcb_D2:
    or dh, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1422
L1423:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1422:
    mov esi, ebp
    call Lrd_slow
    jmp L1423
    ALIGN 16
Lfcb_D3:
    or dl, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1424
L1425:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1424:
    mov esi, ebp
    call Lrd_slow
    jmp L1425
    ALIGN 16
Lfcb_D4:
    or bh, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1426
L1427:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1426:
    mov esi, ebp
    call Lrd_slow
    jmp L1427
    ALIGN 16
Lfcb_D5:
    or bl, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1428
L1429:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1428:
    mov esi, ebp
    call Lrd_slow
    jmp L1429
    ALIGN 16
Lfcb_D6:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1430
L1431:
    movzx r10d, byte ptr [rdi+rsi]
    or r10b, 4
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1432
    mov byte ptr [rdi+rsi], r10b
L1433:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1434
L1435:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1430:
    call Lrd_slow
    jmp L1431
L1432:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1433
L1434:
    mov esi, ebp
    call Lrd_slow
    jmp L1435
    ALIGN 16
Lfcb_D7:
    or al, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1436
L1437:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1436:
    mov esi, ebp
    call Lrd_slow
    jmp L1437
    ALIGN 16
Lfcb_D8:
    or ch, 8
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1438
L1439:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1438:
    mov esi, ebp
    call Lrd_slow
    jmp L1439
    ALIGN 16
Lfcb_D9:
    or cl, 8
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1440
L1441:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1440:
    mov esi, ebp
    call Lrd_slow
    jmp L1441
    ALIGN 16
Lfcb_DA:
    or dh, 8
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1442
L1443:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1442:
    mov esi, ebp
    call Lrd_slow
    jmp L1443
    ALIGN 16
Lfcb_DB:
    or dl, 8
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1444
L1445:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1444:
    mov esi, ebp
    call Lrd_slow
    jmp L1445
    ALIGN 16
Lfcb_DC:
    or bh, 8
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1446
L1447:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1446:
    mov esi, ebp
    call Lrd_slow
    jmp L1447
    ALIGN 16
Lfcb_DD:
    or bl, 8
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1448
L1449:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1448:
    mov esi, ebp
    call Lrd_slow
    jmp L1449
    ALIGN 16
Lfcb_DE:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1450
L1451:
    movzx r10d, byte ptr [rdi+rsi]
    or r10b, 8
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1452
    mov byte ptr [rdi+rsi], r10b
L1453:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1454
L1455:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1450:
    call Lrd_slow
    jmp L1451
L1452:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1453
L1454:
    mov esi, ebp
    call Lrd_slow
    jmp L1455
    ALIGN 16
Lfcb_DF:
    or al, 8
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1456
L1457:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1456:
    mov esi, ebp
    call Lrd_slow
    jmp L1457
    ALIGN 16
Lfcb_E0:
    or ch, 16
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1458
L1459:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1458:
    mov esi, ebp
    call Lrd_slow
    jmp L1459
    ALIGN 16
Lfcb_E1:
    or cl, 16
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1460
L1461:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1460:
    mov esi, ebp
    call Lrd_slow
    jmp L1461
    ALIGN 16
Lfcb_E2:
    or dh, 16
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1462
L1463:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1462:
    mov esi, ebp
    call Lrd_slow
    jmp L1463
    ALIGN 16
Lfcb_E3:
    or dl, 16
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1464
L1465:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1464:
    mov esi, ebp
    call Lrd_slow
    jmp L1465
    ALIGN 16
Lfcb_E4:
    or bh, 16
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1466
L1467:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1466:
    mov esi, ebp
    call Lrd_slow
    jmp L1467
    ALIGN 16
Lfcb_E5:
    or bl, 16
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1468
L1469:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1468:
    mov esi, ebp
    call Lrd_slow
    jmp L1469
    ALIGN 16
Lfcb_E6:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1470
L1471:
    movzx r10d, byte ptr [rdi+rsi]
    or r10b, 16
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1472
    mov byte ptr [rdi+rsi], r10b
L1473:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1474
L1475:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1470:
    call Lrd_slow
    jmp L1471
L1472:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1473
L1474:
    mov esi, ebp
    call Lrd_slow
    jmp L1475
    ALIGN 16
Lfcb_E7:
    or al, 16
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1476
L1477:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1476:
    mov esi, ebp
    call Lrd_slow
    jmp L1477
    ALIGN 16
Lfcb_E8:
    or ch, 32
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1478
L1479:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1478:
    mov esi, ebp
    call Lrd_slow
    jmp L1479
    ALIGN 16
Lfcb_E9:
    or cl, 32
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1480
L1481:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1480:
    mov esi, ebp
    call Lrd_slow
    jmp L1481
    ALIGN 16
Lfcb_EA:
    or dh, 32
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1482
L1483:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1482:
    mov esi, ebp
    call Lrd_slow
    jmp L1483
    ALIGN 16
Lfcb_EB:
    or dl, 32
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1484
L1485:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1484:
    mov esi, ebp
    call Lrd_slow
    jmp L1485
    ALIGN 16
Lfcb_EC:
    or bh, 32
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1486
L1487:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1486:
    mov esi, ebp
    call Lrd_slow
    jmp L1487
    ALIGN 16
Lfcb_ED:
    or bl, 32
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1488
L1489:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1488:
    mov esi, ebp
    call Lrd_slow
    jmp L1489
    ALIGN 16
Lfcb_EE:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1490
L1491:
    movzx r10d, byte ptr [rdi+rsi]
    or r10b, 32
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1492
    mov byte ptr [rdi+rsi], r10b
L1493:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1494
L1495:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1490:
    call Lrd_slow
    jmp L1491
L1492:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1493
L1494:
    mov esi, ebp
    call Lrd_slow
    jmp L1495
    ALIGN 16
Lfcb_EF:
    or al, 32
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1496
L1497:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1496:
    mov esi, ebp
    call Lrd_slow
    jmp L1497
    ALIGN 16
Lfcb_F0:
    or ch, 64
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1498
L1499:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1498:
    mov esi, ebp
    call Lrd_slow
    jmp L1499
    ALIGN 16
Lfcb_F1:
    or cl, 64
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1500
L1501:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1500:
    mov esi, ebp
    call Lrd_slow
    jmp L1501
    ALIGN 16
Lfcb_F2:
    or dh, 64
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1502
L1503:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1502:
    mov esi, ebp
    call Lrd_slow
    jmp L1503
    ALIGN 16
Lfcb_F3:
    or dl, 64
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1504
L1505:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1504:
    mov esi, ebp
    call Lrd_slow
    jmp L1505
    ALIGN 16
Lfcb_F4:
    or bh, 64
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1506
L1507:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1506:
    mov esi, ebp
    call Lrd_slow
    jmp L1507
    ALIGN 16
Lfcb_F5:
    or bl, 64
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1508
L1509:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1508:
    mov esi, ebp
    call Lrd_slow
    jmp L1509
    ALIGN 16
Lfcb_F6:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1510
L1511:
    movzx r10d, byte ptr [rdi+rsi]
    or r10b, 64
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1512
    mov byte ptr [rdi+rsi], r10b
L1513:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1514
L1515:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1510:
    call Lrd_slow
    jmp L1511
L1512:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1513
L1514:
    mov esi, ebp
    call Lrd_slow
    jmp L1515
    ALIGN 16
Lfcb_F7:
    or al, 64
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1516
L1517:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1516:
    mov esi, ebp
    call Lrd_slow
    jmp L1517
    ALIGN 16
Lfcb_F8:
    or ch, 128
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1518
L1519:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1518:
    mov esi, ebp
    call Lrd_slow
    jmp L1519
    ALIGN 16
Lfcb_F9:
    or cl, 128
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1520
L1521:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1520:
    mov esi, ebp
    call Lrd_slow
    jmp L1521
    ALIGN 16
Lfcb_FA:
    or dh, 128
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1522
L1523:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1522:
    mov esi, ebp
    call Lrd_slow
    jmp L1523
    ALIGN 16
Lfcb_FB:
    or dl, 128
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1524
L1525:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1524:
    mov esi, ebp
    call Lrd_slow
    jmp L1525
    ALIGN 16
Lfcb_FC:
    or bh, 128
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1526
L1527:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1526:
    mov esi, ebp
    call Lrd_slow
    jmp L1527
    ALIGN 16
Lfcb_FD:
    or bl, 128
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1528
L1529:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1528:
    mov esi, ebp
    call Lrd_slow
    jmp L1529
    ALIGN 16
Lfcb_FE:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1530
L1531:
    movzx r10d, byte ptr [rdi+rsi]
    or r10b, 128
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1532
    mov byte ptr [rdi+rsi], r10b
L1533:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1534
L1535:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1530:
    call Lrd_slow
    jmp L1531
L1532:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1533
L1534:
    mov esi, ebp
    call Lrd_slow
    jmp L1535
    ALIGN 16
Lfcb_FF:
    or al, 128
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498556], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572288]
    test rdi, rdi
    jz L1536
L1537:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1536:
    mov esi, ebp
    call Lrd_slow
    jmp L1537
    ALIGN 16
Lc_00:
    jmp Lnext
    ALIGN 16
Lc_01:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1538
L1539:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1540
L1541:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1542
L1543:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1544
L1545:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    mov ecx, r11d
    jmp Lnext
L1538:
    call Ltick_slow4
    jmp L1539
L1540:
    call Lrd_slow
    jmp L1541
L1542:
    call Ltick_slow4
    jmp L1543
L1544:
    call Lrd_slow
    jmp L1545
    ALIGN 16
Lc_02:
    mov esi, ecx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1546
L1547:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1548
    mov byte ptr [rdi+rsi], al
L1549:
    jmp Lnext
L1546:
    call Ltick_slow4
    jmp L1547
L1548:
    mov byte ptr [rsp+40], al
    call Lwr_slow
    jmp L1549
    ALIGN 16
Lc_03:
    inc cx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1550
L1551:
    jmp Lnext
L1550:
    call Ltick_slow4
    jmp L1551
    ALIGN 16
Lc_04:
    inc ch
    movzx edi, ch
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573208]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lc_05:
    dec ch
    movzx edi, ch
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573464]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lc_06:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1552
L1553:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1554
L1555:
    mov ch, byte ptr [rdi+rsi]
    inc bp
    jmp Lnext
L1552:
    call Ltick_slow4
    jmp L1553
L1554:
    call Lrd_slow
    jmp L1555
    ALIGN 16
Lc_07:
    xor r8d, r8d
    rol al, 1
    setc r8b
    shl r8d, 4
    jmp Lnext
    ALIGN 16
Lc_08:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1556
L1557:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1558
L1559:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1560
L1561:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1562
L1563:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    mov esi, r11d
    mov r10d, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1564
L1565:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1566
    mov byte ptr [rdi+rsi], r10b
L1567:
    lea esi, [r11+1]
    and esi, 65535
    mov r10d, r9d
    shr r10d, 8
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1568
L1569:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1570
    mov byte ptr [rdi+rsi], r10b
L1571:
    jmp Lnext
L1556:
    call Ltick_slow4
    jmp L1557
L1558:
    call Lrd_slow
    jmp L1559
L1560:
    call Ltick_slow4
    jmp L1561
L1562:
    call Lrd_slow
    jmp L1563
L1564:
    call Ltick_slow4
    jmp L1565
L1566:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1567
L1568:
    call Ltick_slow4
    jmp L1569
L1570:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1571
    ALIGN 16
Lc_09:
    mov edi, ebx
    xor edi, ecx
    add ebx, ecx
    xor edi, ebx
    and r8d, 128
    mov esi, edi
    shr edi, 7
    and edi, 32
    shr esi, 12
    and esi, 16
    or r8d, edi
    or r8d, esi
    and ebx, 65535
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1572
L1573:
    jmp Lnext
L1572:
    call Ltick_slow4
    jmp L1573
    ALIGN 16
Lc_0A:
    mov esi, ecx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1574
L1575:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1576
L1577:
    mov al, byte ptr [rdi+rsi]
    jmp Lnext
L1574:
    call Ltick_slow4
    jmp L1575
L1576:
    call Lrd_slow
    jmp L1577
    ALIGN 16
Lc_0B:
    dec cx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1578
L1579:
    jmp Lnext
L1578:
    call Ltick_slow4
    jmp L1579
    ALIGN 16
Lc_0C:
    inc cl
    movzx edi, cl
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573208]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lc_0D:
    dec cl
    movzx edi, cl
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573464]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lc_0E:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1580
L1581:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1582
L1583:
    mov cl, byte ptr [rdi+rsi]
    inc bp
    jmp Lnext
L1580:
    call Ltick_slow4
    jmp L1581
L1582:
    call Lrd_slow
    jmp L1583
    ALIGN 16
Lc_0F:
    xor r8d, r8d
    ror al, 1
    setc r8b
    shl r8d, 4
    jmp Lnext
    ALIGN 16
Lc_10:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1584
L1585:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1586
L1587:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    jmp Lnext
L1584:
    call Ltick_slow4
    jmp L1585
L1586:
    call Lrd_slow
    jmp L1587
    ALIGN 16
Lc_11:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1588
L1589:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1590
L1591:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1592
L1593:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1594
L1595:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    mov edx, r11d
    jmp Lnext
L1588:
    call Ltick_slow4
    jmp L1589
L1590:
    call Lrd_slow
    jmp L1591
L1592:
    call Ltick_slow4
    jmp L1593
L1594:
    call Lrd_slow
    jmp L1595
    ALIGN 16
Lc_12:
    mov esi, edx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1596
L1597:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1598
    mov byte ptr [rdi+rsi], al
L1599:
    jmp Lnext
L1596:
    call Ltick_slow4
    jmp L1597
L1598:
    mov byte ptr [rsp+40], al
    call Lwr_slow
    jmp L1599
    ALIGN 16
Lc_13:
    inc dx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1600
L1601:
    jmp Lnext
L1600:
    call Ltick_slow4
    jmp L1601
    ALIGN 16
Lc_14:
    inc dh
    movzx edi, dh
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573208]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lc_15:
    dec dh
    movzx edi, dh
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573464]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lc_16:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1602
L1603:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1604
L1605:
    mov dh, byte ptr [rdi+rsi]
    inc bp
    jmp Lnext
L1602:
    call Ltick_slow4
    jmp L1603
L1604:
    call Lrd_slow
    jmp L1605
    ALIGN 16
Lc_17:
    bt r8d, 4
    rcl al, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    jmp Lnext
    ALIGN 16
Lc_18:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1606
L1607:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1608
L1609:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    movsx r10d, r10b
    add ebp, r10d
    and ebp, 65535
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1611
L1612:
L1610:
    jmp Lnext
L1606:
    call Ltick_slow4
    jmp L1607
L1608:
    call Lrd_slow
    jmp L1609
L1611:
    call Ltick_slow4
    jmp L1612
    ALIGN 16
Lc_19:
    mov edi, ebx
    xor edi, edx
    add ebx, edx
    xor edi, ebx
    and r8d, 128
    mov esi, edi
    shr edi, 7
    and edi, 32
    shr esi, 12
    and esi, 16
    or r8d, edi
    or r8d, esi
    and ebx, 65535
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1613
L1614:
    jmp Lnext
L1613:
    call Ltick_slow4
    jmp L1614
    ALIGN 16
Lc_1A:
    mov esi, edx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1615
L1616:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1617
L1618:
    mov al, byte ptr [rdi+rsi]
    jmp Lnext
L1615:
    call Ltick_slow4
    jmp L1616
L1617:
    call Lrd_slow
    jmp L1618
    ALIGN 16
Lc_1B:
    dec dx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1619
L1620:
    jmp Lnext
L1619:
    call Ltick_slow4
    jmp L1620
    ALIGN 16
Lc_1C:
    inc dl
    movzx edi, dl
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573208]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lc_1D:
    dec dl
    movzx edi, dl
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573464]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lc_1E:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1621
L1622:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1623
L1624:
    mov dl, byte ptr [rdi+rsi]
    inc bp
    jmp Lnext
L1621:
    call Ltick_slow4
    jmp L1622
L1623:
    call Lrd_slow
    jmp L1624
    ALIGN 16
Lc_1F:
    bt r8d, 4
    rcr al, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    jmp Lnext
    ALIGN 16
Lc_20:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1625
L1626:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1627
L1628:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    test r8b, 128
    jnz L1629
    movsx r10d, r10b
    add ebp, r10d
    and ebp, 65535
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1630
L1631:
L1629:
    jmp Lnext
L1625:
    call Ltick_slow4
    jmp L1626
L1627:
    call Lrd_slow
    jmp L1628
L1630:
    call Ltick_slow4
    jmp L1631
    ALIGN 16
Lc_21:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1632
L1633:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1634
L1635:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1636
L1637:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1638
L1639:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    mov ebx, r11d
    jmp Lnext
L1632:
    call Ltick_slow4
    jmp L1633
L1634:
    call Lrd_slow
    jmp L1635
L1636:
    call Ltick_slow4
    jmp L1637
L1638:
    call Lrd_slow
    jmp L1639
    ALIGN 16
Lc_22:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1640
L1641:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1642
    mov byte ptr [rdi+rsi], al
L1643:
    lea ebx, [rsi+1]
    and ebx, 65535
    jmp Lnext
L1640:
    call Ltick_slow4
    jmp L1641
L1642:
    mov byte ptr [rsp+40], al
    call Lwr_slow
    jmp L1643
    ALIGN 16
Lc_23:
    inc bx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1644
L1645:
    jmp Lnext
L1644:
    call Ltick_slow4
    jmp L1645
    ALIGN 16
Lc_24:
    inc bh
    movzx edi, bh
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573208]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lc_25:
    dec bh
    movzx edi, bh
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573464]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lc_26:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1646
L1647:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1648
L1649:
    mov bh, byte ptr [rdi+rsi]
    inc bp
    jmp Lnext
L1646:
    call Ltick_slow4
    jmp L1647
L1648:
    call Lrd_slow
    jmp L1649
    ALIGN 16
Lc_27:
    movzx edi, al
    mov esi, r8d
    and esi, 16
    test r8b, 64
    jz L1650
    test r8b, 32
    jz L1651
    sub edi, 6
L1651:
    test esi, esi
    jz L1655
    sub edi, 96
    jmp L1655
L1650:
    test esi, esi
    jnz L1652
    cmp edi, 153
    jbe L1653
L1652:
    add edi, 96
    mov esi, 16
L1653:
    test r8b, 32
    jnz L1654
    mov r10d, edi
    and r10d, 15
    cmp r10d, 9
    jbe L1655
L1654:
    add edi, 6
L1655:
    mov eax, edi
    and r8d, 64
    or r8d, esi
    test al, al
    jnz L1656
    or r8d, 128
L1656:
    jmp Lnext
    ALIGN 16
Lc_28:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1657
L1658:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1659
L1660:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    test r8b, 128
    jz L1661
    movsx r10d, r10b
    add ebp, r10d
    and ebp, 65535
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1662
L1663:
L1661:
    jmp Lnext
L1657:
    call Ltick_slow4
    jmp L1658
L1659:
    call Lrd_slow
    jmp L1660
L1662:
    call Ltick_slow4
    jmp L1663
    ALIGN 16
Lc_29:
    mov edi, ebx
    xor edi, ebx
    add ebx, ebx
    xor edi, ebx
    and r8d, 128
    mov esi, edi
    shr edi, 7
    and edi, 32
    shr esi, 12
    and esi, 16
    or r8d, edi
    or r8d, esi
    and ebx, 65535
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1664
L1665:
    jmp Lnext
L1664:
    call Ltick_slow4
    jmp L1665
    ALIGN 16
Lc_2A:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1666
L1667:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1668
L1669:
    mov al, byte ptr [rdi+rsi]
    lea ebx, [rsi+1]
    and ebx, 65535
    jmp Lnext
L1666:
    call Ltick_slow4
    jmp L1667
L1668:
    call Lrd_slow
    jmp L1669
    ALIGN 16
Lc_2B:
    dec bx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1670
L1671:
    jmp Lnext
L1670:
    call Ltick_slow4
    jmp L1671
    ALIGN 16
Lc_2C:
    inc bl
    movzx edi, bl
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573208]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lc_2D:
    dec bl
    movzx edi, bl
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573464]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lc_2E:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1672
L1673:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1674
L1675:
    mov bl, byte ptr [rdi+rsi]
    inc bp
    jmp Lnext
L1672:
    call Ltick_slow4
    jmp L1673
L1674:
    call Lrd_slow
    jmp L1675
    ALIGN 16
Lc_2F:
    not al
    or r8d, 96
    jmp Lnext
    ALIGN 16
Lc_30:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1676
L1677:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1678
L1679:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    test r8b, 16
    jnz L1680
    movsx r10d, r10b
    add ebp, r10d
    and ebp, 65535
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1681
L1682:
L1680:
    jmp Lnext
L1676:
    call Ltick_slow4
    jmp L1677
L1678:
    call Lrd_slow
    jmp L1679
L1681:
    call Ltick_slow4
    jmp L1682
    ALIGN 16
Lc_31:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1683
L1684:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1685
L1686:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1687
L1688:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1689
L1690:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    mov r9d, r11d
    jmp Lnext
L1683:
    call Ltick_slow4
    jmp L1684
L1685:
    call Lrd_slow
    jmp L1686
L1687:
    call Ltick_slow4
    jmp L1688
L1689:
    call Lrd_slow
    jmp L1690
    ALIGN 16
Lc_32:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1691
L1692:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1693
    mov byte ptr [rdi+rsi], al
L1694:
    lea ebx, [rsi-1]
    and ebx, 65535
    jmp Lnext
L1691:
    call Ltick_slow4
    jmp L1692
L1693:
    mov byte ptr [rsp+40], al
    call Lwr_slow
    jmp L1694
    ALIGN 16
Lc_33:
    inc r9w
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1695
L1696:
    jmp Lnext
L1695:
    call Ltick_slow4
    jmp L1696
    ALIGN 16
Lc_34:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1697
L1698:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1699
L1700:
    movzx r10d, byte ptr [rdi+rsi]
    inc r10b
    movzx edi, r10b
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573208]
    or r8d, edi
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1701
L1702:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1703
    mov byte ptr [rdi+rsi], r10b
L1704:
    jmp Lnext
L1697:
    call Ltick_slow4
    jmp L1698
L1699:
    call Lrd_slow
    jmp L1700
L1701:
    call Ltick_slow4
    jmp L1702
L1703:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1704
    ALIGN 16
Lc_35:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1705
L1706:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1707
L1708:
    movzx r10d, byte ptr [rdi+rsi]
    dec r10b
    movzx edi, r10b
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573464]
    or r8d, edi
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1709
L1710:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1711
    mov byte ptr [rdi+rsi], r10b
L1712:
    jmp Lnext
L1705:
    call Ltick_slow4
    jmp L1706
L1707:
    call Lrd_slow
    jmp L1708
L1709:
    call Ltick_slow4
    jmp L1710
L1711:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1712
    ALIGN 16
Lc_36:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1713
L1714:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1715
L1716:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1717
L1718:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1719
    mov byte ptr [rdi+rsi], r10b
L1720:
    jmp Lnext
L1713:
    call Ltick_slow4
    jmp L1714
L1715:
    call Lrd_slow
    jmp L1716
L1717:
    call Ltick_slow4
    jmp L1718
L1719:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1720
    ALIGN 16
Lc_37:
    and r8d, 128
    or r8d, 16
    jmp Lnext
    ALIGN 16
Lc_38:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1721
L1722:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1723
L1724:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    test r8b, 16
    jz L1725
    movsx r10d, r10b
    add ebp, r10d
    and ebp, 65535
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1726
L1727:
L1725:
    jmp Lnext
L1721:
    call Ltick_slow4
    jmp L1722
L1723:
    call Lrd_slow
    jmp L1724
L1726:
    call Ltick_slow4
    jmp L1727
    ALIGN 16
Lc_39:
    mov edi, ebx
    xor edi, r9d
    add ebx, r9d
    xor edi, ebx
    and r8d, 128
    mov esi, edi
    shr edi, 7
    and edi, 32
    shr esi, 12
    and esi, 16
    or r8d, edi
    or r8d, esi
    and ebx, 65535
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1728
L1729:
    jmp Lnext
L1728:
    call Ltick_slow4
    jmp L1729
    ALIGN 16
Lc_3A:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1730
L1731:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1732
L1733:
    mov al, byte ptr [rdi+rsi]
    lea ebx, [rsi-1]
    and ebx, 65535
    jmp Lnext
L1730:
    call Ltick_slow4
    jmp L1731
L1732:
    call Lrd_slow
    jmp L1733
    ALIGN 16
Lc_3B:
    dec r9w
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1734
L1735:
    jmp Lnext
L1734:
    call Ltick_slow4
    jmp L1735
    ALIGN 16
Lc_3C:
    inc al
    movzx edi, al
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573208]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lc_3D:
    dec al
    movzx edi, al
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573464]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lc_3E:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1736
L1737:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1738
L1739:
    mov al, byte ptr [rdi+rsi]
    inc bp
    jmp Lnext
L1736:
    call Ltick_slow4
    jmp L1737
L1738:
    call Lrd_slow
    jmp L1739
    ALIGN 16
Lc_3F:
    and r8d, 144
    xor r8d, 16
    jmp Lnext
    ALIGN 16
Lc_40:
    jmp Lnext
    ALIGN 16
Lc_41:
    mov ch, cl
    jmp Lnext
    ALIGN 16
Lc_42:
    mov ch, dh
    jmp Lnext
    ALIGN 16
Lc_43:
    mov ch, dl
    jmp Lnext
    ALIGN 16
Lc_44:
    mov ch, bh
    jmp Lnext
    ALIGN 16
Lc_45:
    mov ch, bl
    jmp Lnext
    ALIGN 16
Lc_46:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1740
L1741:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1742
L1743:
    mov ch, byte ptr [rdi+rsi]
    jmp Lnext
L1740:
    call Ltick_slow4
    jmp L1741
L1742:
    call Lrd_slow
    jmp L1743
    ALIGN 16
Lc_47:
    mov ch, al
    jmp Lnext
    ALIGN 16
Lc_48:
    mov cl, ch
    jmp Lnext
    ALIGN 16
Lc_49:
    jmp Lnext
    ALIGN 16
Lc_4A:
    mov cl, dh
    jmp Lnext
    ALIGN 16
Lc_4B:
    mov cl, dl
    jmp Lnext
    ALIGN 16
Lc_4C:
    mov cl, bh
    jmp Lnext
    ALIGN 16
Lc_4D:
    mov cl, bl
    jmp Lnext
    ALIGN 16
Lc_4E:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1744
L1745:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1746
L1747:
    mov cl, byte ptr [rdi+rsi]
    jmp Lnext
L1744:
    call Ltick_slow4
    jmp L1745
L1746:
    call Lrd_slow
    jmp L1747
    ALIGN 16
Lc_4F:
    mov cl, al
    jmp Lnext
    ALIGN 16
Lc_50:
    mov dh, ch
    jmp Lnext
    ALIGN 16
Lc_51:
    mov dh, cl
    jmp Lnext
    ALIGN 16
Lc_52:
    jmp Lnext
    ALIGN 16
Lc_53:
    mov dh, dl
    jmp Lnext
    ALIGN 16
Lc_54:
    mov dh, bh
    jmp Lnext
    ALIGN 16
Lc_55:
    mov dh, bl
    jmp Lnext
    ALIGN 16
Lc_56:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1748
L1749:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1750
L1751:
    mov dh, byte ptr [rdi+rsi]
    jmp Lnext
L1748:
    call Ltick_slow4
    jmp L1749
L1750:
    call Lrd_slow
    jmp L1751
    ALIGN 16
Lc_57:
    mov dh, al
    jmp Lnext
    ALIGN 16
Lc_58:
    mov dl, ch
    jmp Lnext
    ALIGN 16
Lc_59:
    mov dl, cl
    jmp Lnext
    ALIGN 16
Lc_5A:
    mov dl, dh
    jmp Lnext
    ALIGN 16
Lc_5B:
    jmp Lnext
    ALIGN 16
Lc_5C:
    mov dl, bh
    jmp Lnext
    ALIGN 16
Lc_5D:
    mov dl, bl
    jmp Lnext
    ALIGN 16
Lc_5E:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1752
L1753:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1754
L1755:
    mov dl, byte ptr [rdi+rsi]
    jmp Lnext
L1752:
    call Ltick_slow4
    jmp L1753
L1754:
    call Lrd_slow
    jmp L1755
    ALIGN 16
Lc_5F:
    mov dl, al
    jmp Lnext
    ALIGN 16
Lc_60:
    mov bh, ch
    jmp Lnext
    ALIGN 16
Lc_61:
    mov bh, cl
    jmp Lnext
    ALIGN 16
Lc_62:
    mov bh, dh
    jmp Lnext
    ALIGN 16
Lc_63:
    mov bh, dl
    jmp Lnext
    ALIGN 16
Lc_64:
    jmp Lnext
    ALIGN 16
Lc_65:
    mov bh, bl
    jmp Lnext
    ALIGN 16
Lc_66:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1756
L1757:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1758
L1759:
    mov bh, byte ptr [rdi+rsi]
    jmp Lnext
L1756:
    call Ltick_slow4
    jmp L1757
L1758:
    call Lrd_slow
    jmp L1759
    ALIGN 16
Lc_67:
    mov bh, al
    jmp Lnext
    ALIGN 16
Lc_68:
    mov bl, ch
    jmp Lnext
    ALIGN 16
Lc_69:
    mov bl, cl
    jmp Lnext
    ALIGN 16
Lc_6A:
    mov bl, dh
    jmp Lnext
    ALIGN 16
Lc_6B:
    mov bl, dl
    jmp Lnext
    ALIGN 16
Lc_6C:
    mov bl, bh
    jmp Lnext
    ALIGN 16
Lc_6D:
    jmp Lnext
    ALIGN 16
Lc_6E:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1760
L1761:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1762
L1763:
    mov bl, byte ptr [rdi+rsi]
    jmp Lnext
L1760:
    call Ltick_slow4
    jmp L1761
L1762:
    call Lrd_slow
    jmp L1763
    ALIGN 16
Lc_6F:
    mov bl, al
    jmp Lnext
    ALIGN 16
Lc_70:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1764
L1765:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1766
    mov byte ptr [rdi+rsi], ch
L1767:
    jmp Lnext
L1764:
    call Ltick_slow4
    jmp L1765
L1766:
    mov byte ptr [rsp+40], ch
    call Lwr_slow
    jmp L1767
    ALIGN 16
Lc_71:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1768
L1769:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1770
    mov byte ptr [rdi+rsi], cl
L1771:
    jmp Lnext
L1768:
    call Ltick_slow4
    jmp L1769
L1770:
    mov byte ptr [rsp+40], cl
    call Lwr_slow
    jmp L1771
    ALIGN 16
Lc_72:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1772
L1773:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1774
    mov byte ptr [rdi+rsi], dh
L1775:
    jmp Lnext
L1772:
    call Ltick_slow4
    jmp L1773
L1774:
    mov byte ptr [rsp+40], dh
    call Lwr_slow
    jmp L1775
    ALIGN 16
Lc_73:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1776
L1777:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1778
    mov byte ptr [rdi+rsi], dl
L1779:
    jmp Lnext
L1776:
    call Ltick_slow4
    jmp L1777
L1778:
    mov byte ptr [rsp+40], dl
    call Lwr_slow
    jmp L1779
    ALIGN 16
Lc_74:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1780
L1781:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1782
    mov byte ptr [rdi+rsi], bh
L1783:
    jmp Lnext
L1780:
    call Ltick_slow4
    jmp L1781
L1782:
    mov byte ptr [rsp+40], bh
    call Lwr_slow
    jmp L1783
    ALIGN 16
Lc_75:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1784
L1785:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1786
    mov byte ptr [rdi+rsi], bl
L1787:
    jmp Lnext
L1784:
    call Ltick_slow4
    jmp L1785
L1786:
    mov byte ptr [rsp+40], bl
    call Lwr_slow
    jmp L1787
    ALIGN 16
Lc_76:
    mov byte ptr [r15+24], al
    mov byte ptr [r15+25], r8b
    mov edi, ecx
    rol di, 8
    mov word ptr [r15+26], di
    mov edi, edx
    rol di, 8
    mov word ptr [r15+28], di
    mov edi, ebx
    rol di, 8
    mov word ptr [r15+30], di
    mov word ptr [r15+32], r9w
    mov word ptr [r15+34], bp
    cmp byte ptr [r15+572659], 0
    jne L1788
    mov qword ptr [r15+40], r14
    movzx edi, word ptr [r15+572656]
    add edi, r14d
    mov word ptr [r15+65858], di
L1788:
    sub rsp, 32
    mov rcx, r15
    mov edx, 118
    call gbc_asm_op
    add rsp, 32
    movzx eax, byte ptr [r15+24]
    movzx r8d, byte ptr [r15+25]
    movzx ecx, word ptr [r15+26]
    rol cx, 8
    movzx edx, word ptr [r15+28]
    rol dx, 8
    movzx ebx, word ptr [r15+30]
    rol bx, 8
    movzx r9d, word ptr [r15+32]
    movzx ebp, word ptr [r15+34]
    mov r14, qword ptr [r15+40]
    mov r13, qword ptr [r15+572608]
    jmp Lnext
    ALIGN 16
Lc_77:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1789
L1790:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1791
    mov byte ptr [rdi+rsi], al
L1792:
    jmp Lnext
L1789:
    call Ltick_slow4
    jmp L1790
L1791:
    mov byte ptr [rsp+40], al
    call Lwr_slow
    jmp L1792
    ALIGN 16
Lc_78:
    mov al, ch
    jmp Lnext
    ALIGN 16
Lc_79:
    mov al, cl
    jmp Lnext
    ALIGN 16
Lc_7A:
    mov al, dh
    jmp Lnext
    ALIGN 16
Lc_7B:
    mov al, dl
    jmp Lnext
    ALIGN 16
Lc_7C:
    mov al, bh
    jmp Lnext
    ALIGN 16
Lc_7D:
    mov al, bl
    jmp Lnext
    ALIGN 16
Lc_7E:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1793
L1794:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1795
L1796:
    mov al, byte ptr [rdi+rsi]
    jmp Lnext
L1793:
    call Ltick_slow4
    jmp L1794
L1795:
    call Lrd_slow
    jmp L1796
    ALIGN 16
Lc_7F:
    jmp Lnext
    ALIGN 16
Lc_80:
    add al, ch
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572696]
    jmp Lnext
    ALIGN 16
Lc_81:
    add al, cl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572696]
    jmp Lnext
    ALIGN 16
Lc_82:
    add al, dh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572696]
    jmp Lnext
    ALIGN 16
Lc_83:
    add al, dl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572696]
    jmp Lnext
    ALIGN 16
Lc_84:
    add al, bh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572696]
    jmp Lnext
    ALIGN 16
Lc_85:
    add al, bl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572696]
    jmp Lnext
    ALIGN 16
Lc_86:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1797
L1798:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1799
L1800:
    movzx r10d, byte ptr [rdi+rsi]
    add al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572696]
    jmp Lnext
L1797:
    call Ltick_slow4
    jmp L1798
L1799:
    call Lrd_slow
    jmp L1800
    ALIGN 16
Lc_87:
    add al, al
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572696]
    jmp Lnext
    ALIGN 16
Lc_88:
    bt r8d, 4
    adc al, ch
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572696]
    jmp Lnext
    ALIGN 16
Lc_89:
    bt r8d, 4
    adc al, cl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572696]
    jmp Lnext
    ALIGN 16
Lc_8A:
    bt r8d, 4
    adc al, dh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572696]
    jmp Lnext
    ALIGN 16
Lc_8B:
    bt r8d, 4
    adc al, dl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572696]
    jmp Lnext
    ALIGN 16
Lc_8C:
    bt r8d, 4
    adc al, bh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572696]
    jmp Lnext
    ALIGN 16
Lc_8D:
    bt r8d, 4
    adc al, bl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572696]
    jmp Lnext
    ALIGN 16
Lc_8E:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1801
L1802:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1803
L1804:
    movzx r10d, byte ptr [rdi+rsi]
    bt r8d, 4
    adc al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572696]
    jmp Lnext
L1801:
    call Ltick_slow4
    jmp L1802
L1803:
    call Lrd_slow
    jmp L1804
    ALIGN 16
Lc_8F:
    bt r8d, 4
    adc al, al
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572696]
    jmp Lnext
    ALIGN 16
Lc_90:
    sub al, ch
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    jmp Lnext
    ALIGN 16
Lc_91:
    sub al, cl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    jmp Lnext
    ALIGN 16
Lc_92:
    sub al, dh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    jmp Lnext
    ALIGN 16
Lc_93:
    sub al, dl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    jmp Lnext
    ALIGN 16
Lc_94:
    sub al, bh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    jmp Lnext
    ALIGN 16
Lc_95:
    sub al, bl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    jmp Lnext
    ALIGN 16
Lc_96:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1805
L1806:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1807
L1808:
    movzx r10d, byte ptr [rdi+rsi]
    sub al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    jmp Lnext
L1805:
    call Ltick_slow4
    jmp L1806
L1807:
    call Lrd_slow
    jmp L1808
    ALIGN 16
Lc_97:
    sub al, al
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    jmp Lnext
    ALIGN 16
Lc_98:
    bt r8d, 4
    sbb al, ch
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    jmp Lnext
    ALIGN 16
Lc_99:
    bt r8d, 4
    sbb al, cl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    jmp Lnext
    ALIGN 16
Lc_9A:
    bt r8d, 4
    sbb al, dh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    jmp Lnext
    ALIGN 16
Lc_9B:
    bt r8d, 4
    sbb al, dl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    jmp Lnext
    ALIGN 16
Lc_9C:
    bt r8d, 4
    sbb al, bh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    jmp Lnext
    ALIGN 16
Lc_9D:
    bt r8d, 4
    sbb al, bl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    jmp Lnext
    ALIGN 16
Lc_9E:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1809
L1810:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1811
L1812:
    movzx r10d, byte ptr [rdi+rsi]
    bt r8d, 4
    sbb al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    jmp Lnext
L1809:
    call Ltick_slow4
    jmp L1810
L1811:
    call Lrd_slow
    jmp L1812
    ALIGN 16
Lc_9F:
    bt r8d, 4
    sbb al, al
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    jmp Lnext
    ALIGN 16
Lc_A0:
    and al, ch
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573976]
    jmp Lnext
    ALIGN 16
Lc_A1:
    and al, cl
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573976]
    jmp Lnext
    ALIGN 16
Lc_A2:
    and al, dh
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573976]
    jmp Lnext
    ALIGN 16
Lc_A3:
    and al, dl
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573976]
    jmp Lnext
    ALIGN 16
Lc_A4:
    and al, bh
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573976]
    jmp Lnext
    ALIGN 16
Lc_A5:
    and al, bl
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573976]
    jmp Lnext
    ALIGN 16
Lc_A6:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1813
L1814:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1815
L1816:
    movzx r10d, byte ptr [rdi+rsi]
    and al, r10b
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573976]
    jmp Lnext
L1813:
    call Ltick_slow4
    jmp L1814
L1815:
    call Lrd_slow
    jmp L1816
    ALIGN 16
Lc_A7:
    and al, al
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573976]
    jmp Lnext
    ALIGN 16
Lc_A8:
    xor al, ch
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573720]
    jmp Lnext
    ALIGN 16
Lc_A9:
    xor al, cl
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573720]
    jmp Lnext
    ALIGN 16
Lc_AA:
    xor al, dh
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573720]
    jmp Lnext
    ALIGN 16
Lc_AB:
    xor al, dl
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573720]
    jmp Lnext
    ALIGN 16
Lc_AC:
    xor al, bh
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573720]
    jmp Lnext
    ALIGN 16
Lc_AD:
    xor al, bl
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573720]
    jmp Lnext
    ALIGN 16
Lc_AE:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1817
L1818:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1819
L1820:
    movzx r10d, byte ptr [rdi+rsi]
    xor al, r10b
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573720]
    jmp Lnext
L1817:
    call Ltick_slow4
    jmp L1818
L1819:
    call Lrd_slow
    jmp L1820
    ALIGN 16
Lc_AF:
    xor al, al
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573720]
    jmp Lnext
    ALIGN 16
Lc_B0:
    or al, ch
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573720]
    jmp Lnext
    ALIGN 16
Lc_B1:
    or al, cl
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573720]
    jmp Lnext
    ALIGN 16
Lc_B2:
    or al, dh
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573720]
    jmp Lnext
    ALIGN 16
Lc_B3:
    or al, dl
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573720]
    jmp Lnext
    ALIGN 16
Lc_B4:
    or al, bh
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573720]
    jmp Lnext
    ALIGN 16
Lc_B5:
    or al, bl
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573720]
    jmp Lnext
    ALIGN 16
Lc_B6:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1821
L1822:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1823
L1824:
    movzx r10d, byte ptr [rdi+rsi]
    or al, r10b
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573720]
    jmp Lnext
L1821:
    call Ltick_slow4
    jmp L1822
L1823:
    call Lrd_slow
    jmp L1824
    ALIGN 16
Lc_B7:
    or al, al
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573720]
    jmp Lnext
    ALIGN 16
Lc_B8:
    cmp al, ch
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    jmp Lnext
    ALIGN 16
Lc_B9:
    cmp al, cl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    jmp Lnext
    ALIGN 16
Lc_BA:
    cmp al, dh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    jmp Lnext
    ALIGN 16
Lc_BB:
    cmp al, dl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    jmp Lnext
    ALIGN 16
Lc_BC:
    cmp al, bh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    jmp Lnext
    ALIGN 16
Lc_BD:
    cmp al, bl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    jmp Lnext
    ALIGN 16
Lc_BE:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1825
L1826:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1827
L1828:
    movzx r10d, byte ptr [rdi+rsi]
    cmp al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    jmp Lnext
L1825:
    call Ltick_slow4
    jmp L1826
L1827:
    call Lrd_slow
    jmp L1828
    ALIGN 16
Lc_BF:
    cmp al, al
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    jmp Lnext
    ALIGN 16
Lc_C0:
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1829
L1830:
    test r8b, 128
    jnz L1831
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1832
L1833:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1834
L1835:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1836
L1837:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1838
L1839:
    movzx r11d, byte ptr [rdi+rsi]
    inc r9w
    shl r11d, 8
    or r11d, r10d
    mov ebp, r11d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1840
L1841:
L1831:
    jmp Lnext
L1829:
    call Ltick_slow4
    jmp L1830
L1832:
    call Ltick_slow4
    jmp L1833
L1834:
    call Lrd_slow
    jmp L1835
L1836:
    call Ltick_slow4
    jmp L1837
L1838:
    call Lrd_slow
    jmp L1839
L1840:
    call Ltick_slow4
    jmp L1841
    ALIGN 16
Lc_C1:
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1842
L1843:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1844
L1845:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1846
L1847:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1848
L1849:
    movzx r11d, byte ptr [rdi+rsi]
    inc r9w
    shl r11d, 8
    or r11d, r10d
    mov ecx, r11d
    jmp Lnext
L1842:
    call Ltick_slow4
    jmp L1843
L1844:
    call Lrd_slow
    jmp L1845
L1846:
    call Ltick_slow4
    jmp L1847
L1848:
    call Lrd_slow
    jmp L1849
    ALIGN 16
Lc_C2:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1850
L1851:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1852
L1853:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1854
L1855:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1856
L1857:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    test r8b, 128
    jnz L1858
    mov ebp, r11d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1859
L1860:
L1858:
    jmp Lnext
L1850:
    call Ltick_slow4
    jmp L1851
L1852:
    call Lrd_slow
    jmp L1853
L1854:
    call Ltick_slow4
    jmp L1855
L1856:
    call Lrd_slow
    jmp L1857
L1859:
    call Ltick_slow4
    jmp L1860
    ALIGN 16
Lc_C3:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1861
L1862:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1863
L1864:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1865
L1866:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1867
L1868:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    mov ebp, r11d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1870
L1871:
L1869:
    jmp Lnext
L1861:
    call Ltick_slow4
    jmp L1862
L1863:
    call Lrd_slow
    jmp L1864
L1865:
    call Ltick_slow4
    jmp L1866
L1867:
    call Lrd_slow
    jmp L1868
L1870:
    call Ltick_slow4
    jmp L1871
    ALIGN 16
Lc_C4:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1872
L1873:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1874
L1875:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1876
L1877:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1878
L1879:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    test r8b, 128
    jnz L1880
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1881
L1882:
    mov dword ptr [rsp+48], r11d
    mov r11d, ebp
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1883
L1884:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1885
    mov byte ptr [rdi+rsi], r10b
L1886:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1887
L1888:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1889
    mov byte ptr [rdi+rsi], r11b
L1890:
    mov ebp, dword ptr [rsp+48]
L1880:
    jmp Lnext
L1872:
    call Ltick_slow4
    jmp L1873
L1874:
    call Lrd_slow
    jmp L1875
L1876:
    call Ltick_slow4
    jmp L1877
L1878:
    call Lrd_slow
    jmp L1879
L1881:
    call Ltick_slow4
    jmp L1882
L1883:
    call Ltick_slow4
    jmp L1884
L1885:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1886
L1887:
    call Ltick_slow4
    jmp L1888
L1889:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L1890
    ALIGN 16
Lc_C5:
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1891
L1892:
    mov r11d, ecx
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1893
L1894:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1895
    mov byte ptr [rdi+rsi], r10b
L1896:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1897
L1898:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1899
    mov byte ptr [rdi+rsi], r11b
L1900:
    jmp Lnext
L1891:
    call Ltick_slow4
    jmp L1892
L1893:
    call Ltick_slow4
    jmp L1894
L1895:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1896
L1897:
    call Ltick_slow4
    jmp L1898
L1899:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L1900
    ALIGN 16
Lc_C6:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1901
L1902:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1903
L1904:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    add al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572696]
    jmp Lnext
L1901:
    call Ltick_slow4
    jmp L1902
L1903:
    call Lrd_slow
    jmp L1904
    ALIGN 16
Lc_C7:
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1905
L1906:
    mov r11d, ebp
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1907
L1908:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1909
    mov byte ptr [rdi+rsi], r10b
L1910:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1911
L1912:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1913
    mov byte ptr [rdi+rsi], r11b
L1914:
    mov ebp, 0
    jmp Lnext
L1905:
    call Ltick_slow4
    jmp L1906
L1907:
    call Ltick_slow4
    jmp L1908
L1909:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1910
L1911:
    call Ltick_slow4
    jmp L1912
L1913:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L1914
    ALIGN 16
Lc_C8:
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1915
L1916:
    test r8b, 128
    jz L1917
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1918
L1919:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1920
L1921:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1922
L1923:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1924
L1925:
    movzx r11d, byte ptr [rdi+rsi]
    inc r9w
    shl r11d, 8
    or r11d, r10d
    mov ebp, r11d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1926
L1927:
L1917:
    jmp Lnext
L1915:
    call Ltick_slow4
    jmp L1916
L1918:
    call Ltick_slow4
    jmp L1919
L1920:
    call Lrd_slow
    jmp L1921
L1922:
    call Ltick_slow4
    jmp L1923
L1924:
    call Lrd_slow
    jmp L1925
L1926:
    call Ltick_slow4
    jmp L1927
    ALIGN 16
Lc_C9:
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1928
L1929:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1930
L1931:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1932
L1933:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1934
L1935:
    movzx r11d, byte ptr [rdi+rsi]
    inc r9w
    shl r11d, 8
    or r11d, r10d
    mov ebp, r11d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1936
L1937:
    jmp Lnext
L1928:
    call Ltick_slow4
    jmp L1929
L1930:
    call Lrd_slow
    jmp L1931
L1932:
    call Ltick_slow4
    jmp L1933
L1934:
    call Lrd_slow
    jmp L1935
L1936:
    call Ltick_slow4
    jmp L1937
    ALIGN 16
Lc_CA:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1938
L1939:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1940
L1941:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1942
L1943:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1944
L1945:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    test r8b, 128
    jz L1946
    mov ebp, r11d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1947
L1948:
L1946:
    jmp Lnext
L1938:
    call Ltick_slow4
    jmp L1939
L1940:
    call Lrd_slow
    jmp L1941
L1942:
    call Ltick_slow4
    jmp L1943
L1944:
    call Lrd_slow
    jmp L1945
L1947:
    call Ltick_slow4
    jmp L1948
    ALIGN 16
Lc_CB:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1949
L1950:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1951
L1952:
    movzx esi, byte ptr [rdi+rsi]
    inc bp
    lea rdi, Ljt_ccb
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1949:
    call Ltick_slow4
    jmp L1950
L1951:
    call Lrd_slow
    jmp L1952
    ALIGN 16
Lc_CC:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1953
L1954:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1955
L1956:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1957
L1958:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1959
L1960:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    test r8b, 128
    jz L1961
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1962
L1963:
    mov dword ptr [rsp+48], r11d
    mov r11d, ebp
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1964
L1965:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1966
    mov byte ptr [rdi+rsi], r10b
L1967:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1968
L1969:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1970
    mov byte ptr [rdi+rsi], r11b
L1971:
    mov ebp, dword ptr [rsp+48]
L1961:
    jmp Lnext
L1953:
    call Ltick_slow4
    jmp L1954
L1955:
    call Lrd_slow
    jmp L1956
L1957:
    call Ltick_slow4
    jmp L1958
L1959:
    call Lrd_slow
    jmp L1960
L1962:
    call Ltick_slow4
    jmp L1963
L1964:
    call Ltick_slow4
    jmp L1965
L1966:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1967
L1968:
    call Ltick_slow4
    jmp L1969
L1970:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L1971
    ALIGN 16
Lc_CD:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1972
L1973:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1974
L1975:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1976
L1977:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1978
L1979:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1981
L1982:
    mov dword ptr [rsp+48], r11d
    mov r11d, ebp
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1983
L1984:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1985
    mov byte ptr [rdi+rsi], r10b
L1986:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1987
L1988:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1989
    mov byte ptr [rdi+rsi], r11b
L1990:
    mov ebp, dword ptr [rsp+48]
L1980:
    jmp Lnext
L1972:
    call Ltick_slow4
    jmp L1973
L1974:
    call Lrd_slow
    jmp L1975
L1976:
    call Ltick_slow4
    jmp L1977
L1978:
    call Lrd_slow
    jmp L1979
L1981:
    call Ltick_slow4
    jmp L1982
L1983:
    call Ltick_slow4
    jmp L1984
L1985:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1986
L1987:
    call Ltick_slow4
    jmp L1988
L1989:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L1990
    ALIGN 16
Lc_CE:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1991
L1992:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L1993
L1994:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    bt r8d, 4
    adc al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572696]
    jmp Lnext
L1991:
    call Ltick_slow4
    jmp L1992
L1993:
    call Lrd_slow
    jmp L1994
    ALIGN 16
Lc_CF:
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1995
L1996:
    mov r11d, ebp
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L1997
L1998:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L1999
    mov byte ptr [rdi+rsi], r10b
L2000:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2001
L2002:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2003
    mov byte ptr [rdi+rsi], r11b
L2004:
    mov ebp, 8
    jmp Lnext
L1995:
    call Ltick_slow4
    jmp L1996
L1997:
    call Ltick_slow4
    jmp L1998
L1999:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2000
L2001:
    call Ltick_slow4
    jmp L2002
L2003:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L2004
    ALIGN 16
Lc_D0:
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2005
L2006:
    test r8b, 16
    jnz L2007
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2008
L2009:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2010
L2011:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2012
L2013:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2014
L2015:
    movzx r11d, byte ptr [rdi+rsi]
    inc r9w
    shl r11d, 8
    or r11d, r10d
    mov ebp, r11d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2016
L2017:
L2007:
    jmp Lnext
L2005:
    call Ltick_slow4
    jmp L2006
L2008:
    call Ltick_slow4
    jmp L2009
L2010:
    call Lrd_slow
    jmp L2011
L2012:
    call Ltick_slow4
    jmp L2013
L2014:
    call Lrd_slow
    jmp L2015
L2016:
    call Ltick_slow4
    jmp L2017
    ALIGN 16
Lc_D1:
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2018
L2019:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2020
L2021:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2022
L2023:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2024
L2025:
    movzx r11d, byte ptr [rdi+rsi]
    inc r9w
    shl r11d, 8
    or r11d, r10d
    mov edx, r11d
    jmp Lnext
L2018:
    call Ltick_slow4
    jmp L2019
L2020:
    call Lrd_slow
    jmp L2021
L2022:
    call Ltick_slow4
    jmp L2023
L2024:
    call Lrd_slow
    jmp L2025
    ALIGN 16
Lc_D2:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2026
L2027:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2028
L2029:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2030
L2031:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2032
L2033:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    test r8b, 16
    jnz L2034
    mov ebp, r11d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2035
L2036:
L2034:
    jmp Lnext
L2026:
    call Ltick_slow4
    jmp L2027
L2028:
    call Lrd_slow
    jmp L2029
L2030:
    call Ltick_slow4
    jmp L2031
L2032:
    call Lrd_slow
    jmp L2033
L2035:
    call Ltick_slow4
    jmp L2036
    ALIGN 16
Lc_D3:
    jmp Lnext
    ALIGN 16
Lc_D4:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2037
L2038:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2039
L2040:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2041
L2042:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2043
L2044:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    test r8b, 16
    jnz L2045
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2046
L2047:
    mov dword ptr [rsp+48], r11d
    mov r11d, ebp
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2048
L2049:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2050
    mov byte ptr [rdi+rsi], r10b
L2051:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2052
L2053:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2054
    mov byte ptr [rdi+rsi], r11b
L2055:
    mov ebp, dword ptr [rsp+48]
L2045:
    jmp Lnext
L2037:
    call Ltick_slow4
    jmp L2038
L2039:
    call Lrd_slow
    jmp L2040
L2041:
    call Ltick_slow4
    jmp L2042
L2043:
    call Lrd_slow
    jmp L2044
L2046:
    call Ltick_slow4
    jmp L2047
L2048:
    call Ltick_slow4
    jmp L2049
L2050:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2051
L2052:
    call Ltick_slow4
    jmp L2053
L2054:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L2055
    ALIGN 16
Lc_D5:
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2056
L2057:
    mov r11d, edx
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2058
L2059:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2060
    mov byte ptr [rdi+rsi], r10b
L2061:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2062
L2063:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2064
    mov byte ptr [rdi+rsi], r11b
L2065:
    jmp Lnext
L2056:
    call Ltick_slow4
    jmp L2057
L2058:
    call Ltick_slow4
    jmp L2059
L2060:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2061
L2062:
    call Ltick_slow4
    jmp L2063
L2064:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L2065
    ALIGN 16
Lc_D6:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2066
L2067:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2068
L2069:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    sub al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    jmp Lnext
L2066:
    call Ltick_slow4
    jmp L2067
L2068:
    call Lrd_slow
    jmp L2069
    ALIGN 16
Lc_D7:
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2070
L2071:
    mov r11d, ebp
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2072
L2073:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2074
    mov byte ptr [rdi+rsi], r10b
L2075:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2076
L2077:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2078
    mov byte ptr [rdi+rsi], r11b
L2079:
    mov ebp, 16
    jmp Lnext
L2070:
    call Ltick_slow4
    jmp L2071
L2072:
    call Ltick_slow4
    jmp L2073
L2074:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2075
L2076:
    call Ltick_slow4
    jmp L2077
L2078:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L2079
    ALIGN 16
Lc_D8:
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2080
L2081:
    test r8b, 16
    jz L2082
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2083
L2084:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2085
L2086:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2087
L2088:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2089
L2090:
    movzx r11d, byte ptr [rdi+rsi]
    inc r9w
    shl r11d, 8
    or r11d, r10d
    mov ebp, r11d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2091
L2092:
L2082:
    jmp Lnext
L2080:
    call Ltick_slow4
    jmp L2081
L2083:
    call Ltick_slow4
    jmp L2084
L2085:
    call Lrd_slow
    jmp L2086
L2087:
    call Ltick_slow4
    jmp L2088
L2089:
    call Lrd_slow
    jmp L2090
L2091:
    call Ltick_slow4
    jmp L2092
    ALIGN 16
Lc_D9:
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2093
L2094:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2095
L2096:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2097
L2098:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2099
L2100:
    movzx r11d, byte ptr [rdi+rsi]
    inc r9w
    shl r11d, 8
    or r11d, r10d
    mov ebp, r11d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2101
L2102:
    mov byte ptr [r15+24], al
    mov byte ptr [r15+25], r8b
    mov edi, ecx
    rol di, 8
    mov word ptr [r15+26], di
    mov edi, edx
    rol di, 8
    mov word ptr [r15+28], di
    mov edi, ebx
    rol di, 8
    mov word ptr [r15+30], di
    mov word ptr [r15+32], r9w
    mov word ptr [r15+34], bp
    cmp byte ptr [r15+572659], 0
    jne L2103
    mov qword ptr [r15+40], r14
    movzx edi, word ptr [r15+572656]
    add edi, r14d
    mov word ptr [r15+65858], di
L2103:
    sub rsp, 32
    mov rcx, r15
    mov edx, 217
    call gbc_asm_op
    add rsp, 32
    movzx eax, byte ptr [r15+24]
    movzx r8d, byte ptr [r15+25]
    movzx ecx, word ptr [r15+26]
    rol cx, 8
    movzx edx, word ptr [r15+28]
    rol dx, 8
    movzx ebx, word ptr [r15+30]
    rol bx, 8
    movzx r9d, word ptr [r15+32]
    movzx ebp, word ptr [r15+34]
    mov r14, qword ptr [r15+40]
    mov r13, qword ptr [r15+572608]
    jmp Lnext
L2093:
    call Ltick_slow4
    jmp L2094
L2095:
    call Lrd_slow
    jmp L2096
L2097:
    call Ltick_slow4
    jmp L2098
L2099:
    call Lrd_slow
    jmp L2100
L2101:
    call Ltick_slow4
    jmp L2102
    ALIGN 16
Lc_DA:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2104
L2105:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2106
L2107:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2108
L2109:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2110
L2111:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    test r8b, 16
    jz L2112
    mov ebp, r11d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2113
L2114:
L2112:
    jmp Lnext
L2104:
    call Ltick_slow4
    jmp L2105
L2106:
    call Lrd_slow
    jmp L2107
L2108:
    call Ltick_slow4
    jmp L2109
L2110:
    call Lrd_slow
    jmp L2111
L2113:
    call Ltick_slow4
    jmp L2114
    ALIGN 16
Lc_DB:
    jmp Lnext
    ALIGN 16
Lc_DC:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2115
L2116:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2117
L2118:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2119
L2120:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2121
L2122:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    test r8b, 16
    jz L2123
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2124
L2125:
    mov dword ptr [rsp+48], r11d
    mov r11d, ebp
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2126
L2127:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2128
    mov byte ptr [rdi+rsi], r10b
L2129:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2130
L2131:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2132
    mov byte ptr [rdi+rsi], r11b
L2133:
    mov ebp, dword ptr [rsp+48]
L2123:
    jmp Lnext
L2115:
    call Ltick_slow4
    jmp L2116
L2117:
    call Lrd_slow
    jmp L2118
L2119:
    call Ltick_slow4
    jmp L2120
L2121:
    call Lrd_slow
    jmp L2122
L2124:
    call Ltick_slow4
    jmp L2125
L2126:
    call Ltick_slow4
    jmp L2127
L2128:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2129
L2130:
    call Ltick_slow4
    jmp L2131
L2132:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L2133
    ALIGN 16
Lc_DD:
    jmp Lnext
    ALIGN 16
Lc_DE:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2134
L2135:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2136
L2137:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    bt r8d, 4
    sbb al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    jmp Lnext
L2134:
    call Ltick_slow4
    jmp L2135
L2136:
    call Lrd_slow
    jmp L2137
    ALIGN 16
Lc_DF:
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2138
L2139:
    mov r11d, ebp
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2140
L2141:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2142
    mov byte ptr [rdi+rsi], r10b
L2143:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2144
L2145:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2146
    mov byte ptr [rdi+rsi], r11b
L2147:
    mov ebp, 24
    jmp Lnext
L2138:
    call Ltick_slow4
    jmp L2139
L2140:
    call Ltick_slow4
    jmp L2141
L2142:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2143
L2144:
    call Ltick_slow4
    jmp L2145
L2146:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L2147
    ALIGN 16
Lc_E0:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2150
L2151:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2152
L2153:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    cmp r10d, 128
    jb L2148
    cmp r10d, 255
    je L2148
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2154
L2155:
    mov rdi, qword ptr [r15+572560]
    mov byte ptr [rdi+r10+65280], al
    jmp L2149
L2148:
    movzx esi, r10b
    or esi, 65280
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2156
L2157:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2158
    mov byte ptr [rdi+rsi], al
L2159:
L2149:
    jmp Lnext
L2150:
    call Ltick_slow4
    jmp L2151
L2152:
    call Lrd_slow
    jmp L2153
L2154:
    call Ltick_slow4
    jmp L2155
L2156:
    call Ltick_slow4
    jmp L2157
L2158:
    mov byte ptr [rsp+40], al
    call Lwr_slow
    jmp L2159
    ALIGN 16
Lc_E1:
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2160
L2161:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2162
L2163:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2164
L2165:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2166
L2167:
    movzx r11d, byte ptr [rdi+rsi]
    inc r9w
    shl r11d, 8
    or r11d, r10d
    mov ebx, r11d
    jmp Lnext
L2160:
    call Ltick_slow4
    jmp L2161
L2162:
    call Lrd_slow
    jmp L2163
L2164:
    call Ltick_slow4
    jmp L2165
L2166:
    call Lrd_slow
    jmp L2167
    ALIGN 16
Lc_E2:
    movzx esi, cl
    or esi, 65280
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2168
L2169:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2170
    mov byte ptr [rdi+rsi], al
L2171:
    jmp Lnext
L2168:
    call Ltick_slow4
    jmp L2169
L2170:
    mov byte ptr [rsp+40], al
    call Lwr_slow
    jmp L2171
    ALIGN 16
Lc_E3:
    jmp Lnext
    ALIGN 16
Lc_E4:
    jmp Lnext
    ALIGN 16
Lc_E5:
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2172
L2173:
    mov r11d, ebx
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2174
L2175:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2176
    mov byte ptr [rdi+rsi], r10b
L2177:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2178
L2179:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2180
    mov byte ptr [rdi+rsi], r11b
L2181:
    jmp Lnext
L2172:
    call Ltick_slow4
    jmp L2173
L2174:
    call Ltick_slow4
    jmp L2175
L2176:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2177
L2178:
    call Ltick_slow4
    jmp L2179
L2180:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L2181
    ALIGN 16
Lc_E6:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2182
L2183:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2184
L2185:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    and al, r10b
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573976]
    jmp Lnext
L2182:
    call Ltick_slow4
    jmp L2183
L2184:
    call Lrd_slow
    jmp L2185
    ALIGN 16
Lc_E7:
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2186
L2187:
    mov r11d, ebp
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2188
L2189:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2190
    mov byte ptr [rdi+rsi], r10b
L2191:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2192
L2193:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2194
    mov byte ptr [rdi+rsi], r11b
L2195:
    mov ebp, 32
    jmp Lnext
L2186:
    call Ltick_slow4
    jmp L2187
L2188:
    call Ltick_slow4
    jmp L2189
L2190:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2191
L2192:
    call Ltick_slow4
    jmp L2193
L2194:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L2195
    ALIGN 16
Lc_E8:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2196
L2197:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2198
L2199:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov edi, r9d
    and edi, 255
    add edi, r10d
    mov esi, r9d
    and esi, 15
    mov r11d, r10d
    and r11d, 15
    add esi, r11d
    shr edi, 4
    and edi, 16
    shl esi, 1
    and esi, 32
    mov r8d, edi
    or r8d, esi
    movsx r10d, r10b
    add r10d, r9d
    and r10d, 65535
    mov r9d, r10d
    add r14, 8
    cmp r14, qword ptr [r15+572584]
    jae L2200
L2201:
    jmp Lnext
L2196:
    call Ltick_slow4
    jmp L2197
L2198:
    call Lrd_slow
    jmp L2199
L2200:
    call Ltick_slow8
    jmp L2201
    ALIGN 16
Lc_E9:
    mov ebp, ebx
    jmp Lnext
    ALIGN 16
Lc_EA:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2202
L2203:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2204
L2205:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2206
L2207:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2208
L2209:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    mov esi, r11d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2210
L2211:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2212
    mov byte ptr [rdi+rsi], al
L2213:
    jmp Lnext
L2202:
    call Ltick_slow4
    jmp L2203
L2204:
    call Lrd_slow
    jmp L2205
L2206:
    call Ltick_slow4
    jmp L2207
L2208:
    call Lrd_slow
    jmp L2209
L2210:
    call Ltick_slow4
    jmp L2211
L2212:
    mov byte ptr [rsp+40], al
    call Lwr_slow
    jmp L2213
    ALIGN 16
Lc_EB:
    jmp Lnext
    ALIGN 16
Lc_EC:
    jmp Lnext
    ALIGN 16
Lc_ED:
    jmp Lnext
    ALIGN 16
Lc_EE:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2214
L2215:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2216
L2217:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    xor al, r10b
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573720]
    jmp Lnext
L2214:
    call Ltick_slow4
    jmp L2215
L2216:
    call Lrd_slow
    jmp L2217
    ALIGN 16
Lc_EF:
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2218
L2219:
    mov r11d, ebp
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2220
L2221:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2222
    mov byte ptr [rdi+rsi], r10b
L2223:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2224
L2225:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2226
    mov byte ptr [rdi+rsi], r11b
L2227:
    mov ebp, 40
    jmp Lnext
L2218:
    call Ltick_slow4
    jmp L2219
L2220:
    call Ltick_slow4
    jmp L2221
L2222:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2223
L2224:
    call Ltick_slow4
    jmp L2225
L2226:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L2227
    ALIGN 16
Lc_F0:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2230
L2231:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2232
L2233:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    cmp r10d, 128
    jb L2228
    cmp r10d, 255
    je L2228
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2234
L2235:
    mov rdi, qword ptr [r15+572560]
    mov al, byte ptr [rdi+r10+65280]
    jmp L2229
L2228:
    movzx esi, r10b
    or esi, 65280
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2236
L2237:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2238
L2239:
    mov al, byte ptr [rdi+rsi]
L2229:
    jmp Lnext
L2230:
    call Ltick_slow4
    jmp L2231
L2232:
    call Lrd_slow
    jmp L2233
L2234:
    call Ltick_slow4
    jmp L2235
L2236:
    call Ltick_slow4
    jmp L2237
L2238:
    call Lrd_slow
    jmp L2239
    ALIGN 16
Lc_F1:
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2240
L2241:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2242
L2243:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2244
L2245:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2246
L2247:
    movzx r11d, byte ptr [rdi+rsi]
    inc r9w
    shl r11d, 8
    or r11d, r10d
    mov eax, r11d
    shr eax, 8
    mov r8d, r11d
    and r8d, 240
    jmp Lnext
L2240:
    call Ltick_slow4
    jmp L2241
L2242:
    call Lrd_slow
    jmp L2243
L2244:
    call Ltick_slow4
    jmp L2245
L2246:
    call Lrd_slow
    jmp L2247
    ALIGN 16
Lc_F2:
    movzx esi, cl
    or esi, 65280
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2248
L2249:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2250
L2251:
    mov al, byte ptr [rdi+rsi]
    jmp Lnext
L2248:
    call Ltick_slow4
    jmp L2249
L2250:
    call Lrd_slow
    jmp L2251
    ALIGN 16
Lc_F3:
    mov byte ptr [r15+24], al
    mov byte ptr [r15+25], r8b
    mov edi, ecx
    rol di, 8
    mov word ptr [r15+26], di
    mov edi, edx
    rol di, 8
    mov word ptr [r15+28], di
    mov edi, ebx
    rol di, 8
    mov word ptr [r15+30], di
    mov word ptr [r15+32], r9w
    mov word ptr [r15+34], bp
    cmp byte ptr [r15+572659], 0
    jne L2252
    mov qword ptr [r15+40], r14
    movzx edi, word ptr [r15+572656]
    add edi, r14d
    mov word ptr [r15+65858], di
L2252:
    sub rsp, 32
    mov rcx, r15
    mov edx, 243
    call gbc_asm_op
    add rsp, 32
    movzx eax, byte ptr [r15+24]
    movzx r8d, byte ptr [r15+25]
    movzx ecx, word ptr [r15+26]
    rol cx, 8
    movzx edx, word ptr [r15+28]
    rol dx, 8
    movzx ebx, word ptr [r15+30]
    rol bx, 8
    movzx r9d, word ptr [r15+32]
    movzx ebp, word ptr [r15+34]
    mov r14, qword ptr [r15+40]
    mov r13, qword ptr [r15+572608]
    jmp Lnext
    ALIGN 16
Lc_F4:
    jmp Lnext
    ALIGN 16
Lc_F5:
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2253
L2254:
    movzx r11d, al
    shl r11d, 8
    or r11d, r8d
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2255
L2256:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2257
    mov byte ptr [rdi+rsi], r10b
L2258:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2259
L2260:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2261
    mov byte ptr [rdi+rsi], r11b
L2262:
    jmp Lnext
L2253:
    call Ltick_slow4
    jmp L2254
L2255:
    call Ltick_slow4
    jmp L2256
L2257:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2258
L2259:
    call Ltick_slow4
    jmp L2260
L2261:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L2262
    ALIGN 16
Lc_F6:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2263
L2264:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2265
L2266:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    or al, r10b
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573720]
    jmp Lnext
L2263:
    call Ltick_slow4
    jmp L2264
L2265:
    call Lrd_slow
    jmp L2266
    ALIGN 16
Lc_F7:
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2267
L2268:
    mov r11d, ebp
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2269
L2270:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2271
    mov byte ptr [rdi+rsi], r10b
L2272:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2273
L2274:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2275
    mov byte ptr [rdi+rsi], r11b
L2276:
    mov ebp, 48
    jmp Lnext
L2267:
    call Ltick_slow4
    jmp L2268
L2269:
    call Ltick_slow4
    jmp L2270
L2271:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2272
L2273:
    call Ltick_slow4
    jmp L2274
L2275:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L2276
    ALIGN 16
Lc_F8:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2277
L2278:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2279
L2280:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov edi, r9d
    and edi, 255
    add edi, r10d
    mov esi, r9d
    and esi, 15
    mov r11d, r10d
    and r11d, 15
    add esi, r11d
    shr edi, 4
    and edi, 16
    shl esi, 1
    and esi, 32
    mov r8d, edi
    or r8d, esi
    movsx r10d, r10b
    add r10d, r9d
    and r10d, 65535
    mov ebx, r10d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2281
L2282:
    jmp Lnext
L2277:
    call Ltick_slow4
    jmp L2278
L2279:
    call Lrd_slow
    jmp L2280
L2281:
    call Ltick_slow4
    jmp L2282
    ALIGN 16
Lc_F9:
    mov r9d, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2283
L2284:
    jmp Lnext
L2283:
    call Ltick_slow4
    jmp L2284
    ALIGN 16
Lc_FA:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2285
L2286:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2287
L2288:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2289
L2290:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2291
L2292:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    mov esi, r11d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2293
L2294:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2295
L2296:
    mov al, byte ptr [rdi+rsi]
    jmp Lnext
L2285:
    call Ltick_slow4
    jmp L2286
L2287:
    call Lrd_slow
    jmp L2288
L2289:
    call Ltick_slow4
    jmp L2290
L2291:
    call Lrd_slow
    jmp L2292
L2293:
    call Ltick_slow4
    jmp L2294
L2295:
    call Lrd_slow
    jmp L2296
    ALIGN 16
Lc_FB:
    mov byte ptr [r15+24], al
    mov byte ptr [r15+25], r8b
    mov edi, ecx
    rol di, 8
    mov word ptr [r15+26], di
    mov edi, edx
    rol di, 8
    mov word ptr [r15+28], di
    mov edi, ebx
    rol di, 8
    mov word ptr [r15+30], di
    mov word ptr [r15+32], r9w
    mov word ptr [r15+34], bp
    cmp byte ptr [r15+572659], 0
    jne L2297
    mov qword ptr [r15+40], r14
    movzx edi, word ptr [r15+572656]
    add edi, r14d
    mov word ptr [r15+65858], di
L2297:
    sub rsp, 32
    mov rcx, r15
    mov edx, 251
    call gbc_asm_op
    add rsp, 32
    movzx eax, byte ptr [r15+24]
    movzx r8d, byte ptr [r15+25]
    movzx ecx, word ptr [r15+26]
    rol cx, 8
    movzx edx, word ptr [r15+28]
    rol dx, 8
    movzx ebx, word ptr [r15+30]
    rol bx, 8
    movzx r9d, word ptr [r15+32]
    movzx ebp, word ptr [r15+34]
    mov r14, qword ptr [r15+40]
    mov r13, qword ptr [r15+572608]
    jmp Lnext
    ALIGN 16
Lc_FC:
    jmp Lnext
    ALIGN 16
Lc_FD:
    jmp Lnext
    ALIGN 16
Lc_FE:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2298
L2299:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2300
L2301:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    cmp al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572952]
    jmp Lnext
L2298:
    call Ltick_slow4
    jmp L2299
L2300:
    call Lrd_slow
    jmp L2301
    ALIGN 16
Lc_FF:
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2302
L2303:
    mov r11d, ebp
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2304
L2305:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2306
    mov byte ptr [rdi+rsi], r10b
L2307:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2308
L2309:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2310
    mov byte ptr [rdi+rsi], r11b
L2311:
    mov ebp, 56
    jmp Lnext
L2302:
    call Ltick_slow4
    jmp L2303
L2304:
    call Ltick_slow4
    jmp L2305
L2306:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2307
L2308:
    call Ltick_slow4
    jmp L2309
L2310:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L2311
    ALIGN 16
Lccb_00:
    rol ch, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, ch
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_01:
    rol cl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, cl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_02:
    rol dh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dh
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_03:
    rol dl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_04:
    rol bh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bh
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_05:
    rol bl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_06:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2312
L2313:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2314
L2315:
    movzx r10d, byte ptr [rdi+rsi]
    rol r10b, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, r10b
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2316
L2317:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2318
    mov byte ptr [rdi+rsi], r10b
L2319:
    jmp Lnext
L2312:
    call Ltick_slow4
    jmp L2313
L2314:
    call Lrd_slow
    jmp L2315
L2316:
    call Ltick_slow4
    jmp L2317
L2318:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2319
    ALIGN 16
Lccb_07:
    rol al, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, al
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_08:
    ror ch, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, ch
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_09:
    ror cl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, cl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_0A:
    ror dh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dh
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_0B:
    ror dl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_0C:
    ror bh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bh
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_0D:
    ror bl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_0E:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2320
L2321:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2322
L2323:
    movzx r10d, byte ptr [rdi+rsi]
    ror r10b, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, r10b
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2324
L2325:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2326
    mov byte ptr [rdi+rsi], r10b
L2327:
    jmp Lnext
L2320:
    call Ltick_slow4
    jmp L2321
L2322:
    call Lrd_slow
    jmp L2323
L2324:
    call Ltick_slow4
    jmp L2325
L2326:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2327
    ALIGN 16
Lccb_0F:
    ror al, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, al
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_10:
    bt r8d, 4
    rcl ch, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, ch
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_11:
    bt r8d, 4
    rcl cl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, cl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_12:
    bt r8d, 4
    rcl dh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dh
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_13:
    bt r8d, 4
    rcl dl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_14:
    bt r8d, 4
    rcl bh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bh
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_15:
    bt r8d, 4
    rcl bl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_16:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2328
L2329:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2330
L2331:
    movzx r10d, byte ptr [rdi+rsi]
    bt r8d, 4
    rcl r10b, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, r10b
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2332
L2333:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2334
    mov byte ptr [rdi+rsi], r10b
L2335:
    jmp Lnext
L2328:
    call Ltick_slow4
    jmp L2329
L2330:
    call Lrd_slow
    jmp L2331
L2332:
    call Ltick_slow4
    jmp L2333
L2334:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2335
    ALIGN 16
Lccb_17:
    bt r8d, 4
    rcl al, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, al
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_18:
    bt r8d, 4
    rcr ch, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, ch
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_19:
    bt r8d, 4
    rcr cl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, cl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_1A:
    bt r8d, 4
    rcr dh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dh
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_1B:
    bt r8d, 4
    rcr dl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_1C:
    bt r8d, 4
    rcr bh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bh
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_1D:
    bt r8d, 4
    rcr bl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_1E:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2336
L2337:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2338
L2339:
    movzx r10d, byte ptr [rdi+rsi]
    bt r8d, 4
    rcr r10b, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, r10b
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2340
L2341:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2342
    mov byte ptr [rdi+rsi], r10b
L2343:
    jmp Lnext
L2336:
    call Ltick_slow4
    jmp L2337
L2338:
    call Lrd_slow
    jmp L2339
L2340:
    call Ltick_slow4
    jmp L2341
L2342:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2343
    ALIGN 16
Lccb_1F:
    bt r8d, 4
    rcr al, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, al
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_20:
    shl ch, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, ch
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_21:
    shl cl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, cl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_22:
    shl dh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dh
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_23:
    shl dl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_24:
    shl bh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bh
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_25:
    shl bl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_26:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2344
L2345:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2346
L2347:
    movzx r10d, byte ptr [rdi+rsi]
    shl r10b, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, r10b
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2348
L2349:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2350
    mov byte ptr [rdi+rsi], r10b
L2351:
    jmp Lnext
L2344:
    call Ltick_slow4
    jmp L2345
L2346:
    call Lrd_slow
    jmp L2347
L2348:
    call Ltick_slow4
    jmp L2349
L2350:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2351
    ALIGN 16
Lccb_27:
    shl al, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, al
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_28:
    sar ch, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, ch
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_29:
    sar cl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, cl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_2A:
    sar dh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dh
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_2B:
    sar dl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_2C:
    sar bh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bh
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_2D:
    sar bl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_2E:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2352
L2353:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2354
L2355:
    movzx r10d, byte ptr [rdi+rsi]
    sar r10b, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, r10b
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2356
L2357:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2358
    mov byte ptr [rdi+rsi], r10b
L2359:
    jmp Lnext
L2352:
    call Ltick_slow4
    jmp L2353
L2354:
    call Lrd_slow
    jmp L2355
L2356:
    call Ltick_slow4
    jmp L2357
L2358:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2359
    ALIGN 16
Lccb_2F:
    sar al, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, al
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_30:
    rol ch, 4
    movzx edi, ch
    movzx r8d, byte ptr [r15+rdi+573720]
    jmp Lnext
    ALIGN 16
Lccb_31:
    rol cl, 4
    movzx edi, cl
    movzx r8d, byte ptr [r15+rdi+573720]
    jmp Lnext
    ALIGN 16
Lccb_32:
    rol dh, 4
    movzx edi, dh
    movzx r8d, byte ptr [r15+rdi+573720]
    jmp Lnext
    ALIGN 16
Lccb_33:
    rol dl, 4
    movzx edi, dl
    movzx r8d, byte ptr [r15+rdi+573720]
    jmp Lnext
    ALIGN 16
Lccb_34:
    rol bh, 4
    movzx edi, bh
    movzx r8d, byte ptr [r15+rdi+573720]
    jmp Lnext
    ALIGN 16
Lccb_35:
    rol bl, 4
    movzx edi, bl
    movzx r8d, byte ptr [r15+rdi+573720]
    jmp Lnext
    ALIGN 16
Lccb_36:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2360
L2361:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2362
L2363:
    movzx r10d, byte ptr [rdi+rsi]
    rol r10b, 4
    movzx edi, r10b
    movzx r8d, byte ptr [r15+rdi+573720]
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2364
L2365:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2366
    mov byte ptr [rdi+rsi], r10b
L2367:
    jmp Lnext
L2360:
    call Ltick_slow4
    jmp L2361
L2362:
    call Lrd_slow
    jmp L2363
L2364:
    call Ltick_slow4
    jmp L2365
L2366:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2367
    ALIGN 16
Lccb_37:
    rol al, 4
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573720]
    jmp Lnext
    ALIGN 16
Lccb_38:
    shr ch, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, ch
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_39:
    shr cl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, cl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_3A:
    shr dh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dh
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_3B:
    shr dl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_3C:
    shr bh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bh
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_3D:
    shr bl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bl
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_3E:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2368
L2369:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2370
L2371:
    movzx r10d, byte ptr [rdi+rsi]
    shr r10b, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, r10b
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2372
L2373:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2374
    mov byte ptr [rdi+rsi], r10b
L2375:
    jmp Lnext
L2368:
    call Ltick_slow4
    jmp L2369
L2370:
    call Lrd_slow
    jmp L2371
L2372:
    call Ltick_slow4
    jmp L2373
L2374:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2375
    ALIGN 16
Lccb_3F:
    shr al, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, al
    movzx edi, byte ptr [r15+rdi+573720]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_40:
    mov edi, 0
    test ch, 1
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_41:
    mov edi, 0
    test cl, 1
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_42:
    mov edi, 0
    test dh, 1
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_43:
    mov edi, 0
    test dl, 1
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_44:
    mov edi, 0
    test bh, 1
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_45:
    mov edi, 0
    test bl, 1
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_46:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2376
L2377:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2378
L2379:
    movzx r10d, byte ptr [rdi+rsi]
    mov edi, 0
    test r10b, 1
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
L2376:
    call Ltick_slow4
    jmp L2377
L2378:
    call Lrd_slow
    jmp L2379
    ALIGN 16
Lccb_47:
    mov edi, 0
    test al, 1
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_48:
    mov edi, 0
    test ch, 2
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_49:
    mov edi, 0
    test cl, 2
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_4A:
    mov edi, 0
    test dh, 2
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_4B:
    mov edi, 0
    test dl, 2
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_4C:
    mov edi, 0
    test bh, 2
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_4D:
    mov edi, 0
    test bl, 2
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_4E:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2380
L2381:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2382
L2383:
    movzx r10d, byte ptr [rdi+rsi]
    mov edi, 0
    test r10b, 2
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
L2380:
    call Ltick_slow4
    jmp L2381
L2382:
    call Lrd_slow
    jmp L2383
    ALIGN 16
Lccb_4F:
    mov edi, 0
    test al, 2
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_50:
    mov edi, 0
    test ch, 4
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_51:
    mov edi, 0
    test cl, 4
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_52:
    mov edi, 0
    test dh, 4
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_53:
    mov edi, 0
    test dl, 4
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_54:
    mov edi, 0
    test bh, 4
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_55:
    mov edi, 0
    test bl, 4
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_56:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2384
L2385:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2386
L2387:
    movzx r10d, byte ptr [rdi+rsi]
    mov edi, 0
    test r10b, 4
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
L2384:
    call Ltick_slow4
    jmp L2385
L2386:
    call Lrd_slow
    jmp L2387
    ALIGN 16
Lccb_57:
    mov edi, 0
    test al, 4
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_58:
    mov edi, 0
    test ch, 8
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_59:
    mov edi, 0
    test cl, 8
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_5A:
    mov edi, 0
    test dh, 8
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_5B:
    mov edi, 0
    test dl, 8
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_5C:
    mov edi, 0
    test bh, 8
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_5D:
    mov edi, 0
    test bl, 8
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_5E:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2388
L2389:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2390
L2391:
    movzx r10d, byte ptr [rdi+rsi]
    mov edi, 0
    test r10b, 8
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
L2388:
    call Ltick_slow4
    jmp L2389
L2390:
    call Lrd_slow
    jmp L2391
    ALIGN 16
Lccb_5F:
    mov edi, 0
    test al, 8
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_60:
    mov edi, 0
    test ch, 16
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_61:
    mov edi, 0
    test cl, 16
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_62:
    mov edi, 0
    test dh, 16
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_63:
    mov edi, 0
    test dl, 16
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_64:
    mov edi, 0
    test bh, 16
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_65:
    mov edi, 0
    test bl, 16
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_66:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2392
L2393:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2394
L2395:
    movzx r10d, byte ptr [rdi+rsi]
    mov edi, 0
    test r10b, 16
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
L2392:
    call Ltick_slow4
    jmp L2393
L2394:
    call Lrd_slow
    jmp L2395
    ALIGN 16
Lccb_67:
    mov edi, 0
    test al, 16
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_68:
    mov edi, 0
    test ch, 32
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_69:
    mov edi, 0
    test cl, 32
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_6A:
    mov edi, 0
    test dh, 32
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_6B:
    mov edi, 0
    test dl, 32
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_6C:
    mov edi, 0
    test bh, 32
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_6D:
    mov edi, 0
    test bl, 32
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_6E:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2396
L2397:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2398
L2399:
    movzx r10d, byte ptr [rdi+rsi]
    mov edi, 0
    test r10b, 32
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
L2396:
    call Ltick_slow4
    jmp L2397
L2398:
    call Lrd_slow
    jmp L2399
    ALIGN 16
Lccb_6F:
    mov edi, 0
    test al, 32
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_70:
    mov edi, 0
    test ch, 64
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_71:
    mov edi, 0
    test cl, 64
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_72:
    mov edi, 0
    test dh, 64
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_73:
    mov edi, 0
    test dl, 64
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_74:
    mov edi, 0
    test bh, 64
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_75:
    mov edi, 0
    test bl, 64
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_76:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2400
L2401:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2402
L2403:
    movzx r10d, byte ptr [rdi+rsi]
    mov edi, 0
    test r10b, 64
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
L2400:
    call Ltick_slow4
    jmp L2401
L2402:
    call Lrd_slow
    jmp L2403
    ALIGN 16
Lccb_77:
    mov edi, 0
    test al, 64
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_78:
    mov edi, 0
    test ch, 128
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_79:
    mov edi, 0
    test cl, 128
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_7A:
    mov edi, 0
    test dh, 128
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_7B:
    mov edi, 0
    test dl, 128
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_7C:
    mov edi, 0
    test bh, 128
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_7D:
    mov edi, 0
    test bl, 128
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_7E:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2404
L2405:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2406
L2407:
    movzx r10d, byte ptr [rdi+rsi]
    mov edi, 0
    test r10b, 128
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
L2404:
    call Ltick_slow4
    jmp L2405
L2406:
    call Lrd_slow
    jmp L2407
    ALIGN 16
Lccb_7F:
    mov edi, 0
    test al, 128
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_80:
    and ch, 254
    jmp Lnext
    ALIGN 16
Lccb_81:
    and cl, 254
    jmp Lnext
    ALIGN 16
Lccb_82:
    and dh, 254
    jmp Lnext
    ALIGN 16
Lccb_83:
    and dl, 254
    jmp Lnext
    ALIGN 16
Lccb_84:
    and bh, 254
    jmp Lnext
    ALIGN 16
Lccb_85:
    and bl, 254
    jmp Lnext
    ALIGN 16
Lccb_86:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2408
L2409:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2410
L2411:
    movzx r10d, byte ptr [rdi+rsi]
    and r10b, 254
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2412
L2413:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2414
    mov byte ptr [rdi+rsi], r10b
L2415:
    jmp Lnext
L2408:
    call Ltick_slow4
    jmp L2409
L2410:
    call Lrd_slow
    jmp L2411
L2412:
    call Ltick_slow4
    jmp L2413
L2414:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2415
    ALIGN 16
Lccb_87:
    and al, 254
    jmp Lnext
    ALIGN 16
Lccb_88:
    and ch, 253
    jmp Lnext
    ALIGN 16
Lccb_89:
    and cl, 253
    jmp Lnext
    ALIGN 16
Lccb_8A:
    and dh, 253
    jmp Lnext
    ALIGN 16
Lccb_8B:
    and dl, 253
    jmp Lnext
    ALIGN 16
Lccb_8C:
    and bh, 253
    jmp Lnext
    ALIGN 16
Lccb_8D:
    and bl, 253
    jmp Lnext
    ALIGN 16
Lccb_8E:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2416
L2417:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2418
L2419:
    movzx r10d, byte ptr [rdi+rsi]
    and r10b, 253
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2420
L2421:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2422
    mov byte ptr [rdi+rsi], r10b
L2423:
    jmp Lnext
L2416:
    call Ltick_slow4
    jmp L2417
L2418:
    call Lrd_slow
    jmp L2419
L2420:
    call Ltick_slow4
    jmp L2421
L2422:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2423
    ALIGN 16
Lccb_8F:
    and al, 253
    jmp Lnext
    ALIGN 16
Lccb_90:
    and ch, 251
    jmp Lnext
    ALIGN 16
Lccb_91:
    and cl, 251
    jmp Lnext
    ALIGN 16
Lccb_92:
    and dh, 251
    jmp Lnext
    ALIGN 16
Lccb_93:
    and dl, 251
    jmp Lnext
    ALIGN 16
Lccb_94:
    and bh, 251
    jmp Lnext
    ALIGN 16
Lccb_95:
    and bl, 251
    jmp Lnext
    ALIGN 16
Lccb_96:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2424
L2425:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2426
L2427:
    movzx r10d, byte ptr [rdi+rsi]
    and r10b, 251
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2428
L2429:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2430
    mov byte ptr [rdi+rsi], r10b
L2431:
    jmp Lnext
L2424:
    call Ltick_slow4
    jmp L2425
L2426:
    call Lrd_slow
    jmp L2427
L2428:
    call Ltick_slow4
    jmp L2429
L2430:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2431
    ALIGN 16
Lccb_97:
    and al, 251
    jmp Lnext
    ALIGN 16
Lccb_98:
    and ch, 247
    jmp Lnext
    ALIGN 16
Lccb_99:
    and cl, 247
    jmp Lnext
    ALIGN 16
Lccb_9A:
    and dh, 247
    jmp Lnext
    ALIGN 16
Lccb_9B:
    and dl, 247
    jmp Lnext
    ALIGN 16
Lccb_9C:
    and bh, 247
    jmp Lnext
    ALIGN 16
Lccb_9D:
    and bl, 247
    jmp Lnext
    ALIGN 16
Lccb_9E:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2432
L2433:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2434
L2435:
    movzx r10d, byte ptr [rdi+rsi]
    and r10b, 247
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2436
L2437:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2438
    mov byte ptr [rdi+rsi], r10b
L2439:
    jmp Lnext
L2432:
    call Ltick_slow4
    jmp L2433
L2434:
    call Lrd_slow
    jmp L2435
L2436:
    call Ltick_slow4
    jmp L2437
L2438:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2439
    ALIGN 16
Lccb_9F:
    and al, 247
    jmp Lnext
    ALIGN 16
Lccb_A0:
    and ch, 239
    jmp Lnext
    ALIGN 16
Lccb_A1:
    and cl, 239
    jmp Lnext
    ALIGN 16
Lccb_A2:
    and dh, 239
    jmp Lnext
    ALIGN 16
Lccb_A3:
    and dl, 239
    jmp Lnext
    ALIGN 16
Lccb_A4:
    and bh, 239
    jmp Lnext
    ALIGN 16
Lccb_A5:
    and bl, 239
    jmp Lnext
    ALIGN 16
Lccb_A6:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2440
L2441:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2442
L2443:
    movzx r10d, byte ptr [rdi+rsi]
    and r10b, 239
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2444
L2445:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2446
    mov byte ptr [rdi+rsi], r10b
L2447:
    jmp Lnext
L2440:
    call Ltick_slow4
    jmp L2441
L2442:
    call Lrd_slow
    jmp L2443
L2444:
    call Ltick_slow4
    jmp L2445
L2446:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2447
    ALIGN 16
Lccb_A7:
    and al, 239
    jmp Lnext
    ALIGN 16
Lccb_A8:
    and ch, 223
    jmp Lnext
    ALIGN 16
Lccb_A9:
    and cl, 223
    jmp Lnext
    ALIGN 16
Lccb_AA:
    and dh, 223
    jmp Lnext
    ALIGN 16
Lccb_AB:
    and dl, 223
    jmp Lnext
    ALIGN 16
Lccb_AC:
    and bh, 223
    jmp Lnext
    ALIGN 16
Lccb_AD:
    and bl, 223
    jmp Lnext
    ALIGN 16
Lccb_AE:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2448
L2449:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2450
L2451:
    movzx r10d, byte ptr [rdi+rsi]
    and r10b, 223
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2452
L2453:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2454
    mov byte ptr [rdi+rsi], r10b
L2455:
    jmp Lnext
L2448:
    call Ltick_slow4
    jmp L2449
L2450:
    call Lrd_slow
    jmp L2451
L2452:
    call Ltick_slow4
    jmp L2453
L2454:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2455
    ALIGN 16
Lccb_AF:
    and al, 223
    jmp Lnext
    ALIGN 16
Lccb_B0:
    and ch, 191
    jmp Lnext
    ALIGN 16
Lccb_B1:
    and cl, 191
    jmp Lnext
    ALIGN 16
Lccb_B2:
    and dh, 191
    jmp Lnext
    ALIGN 16
Lccb_B3:
    and dl, 191
    jmp Lnext
    ALIGN 16
Lccb_B4:
    and bh, 191
    jmp Lnext
    ALIGN 16
Lccb_B5:
    and bl, 191
    jmp Lnext
    ALIGN 16
Lccb_B6:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2456
L2457:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2458
L2459:
    movzx r10d, byte ptr [rdi+rsi]
    and r10b, 191
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2460
L2461:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2462
    mov byte ptr [rdi+rsi], r10b
L2463:
    jmp Lnext
L2456:
    call Ltick_slow4
    jmp L2457
L2458:
    call Lrd_slow
    jmp L2459
L2460:
    call Ltick_slow4
    jmp L2461
L2462:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2463
    ALIGN 16
Lccb_B7:
    and al, 191
    jmp Lnext
    ALIGN 16
Lccb_B8:
    and ch, 127
    jmp Lnext
    ALIGN 16
Lccb_B9:
    and cl, 127
    jmp Lnext
    ALIGN 16
Lccb_BA:
    and dh, 127
    jmp Lnext
    ALIGN 16
Lccb_BB:
    and dl, 127
    jmp Lnext
    ALIGN 16
Lccb_BC:
    and bh, 127
    jmp Lnext
    ALIGN 16
Lccb_BD:
    and bl, 127
    jmp Lnext
    ALIGN 16
Lccb_BE:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2464
L2465:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2466
L2467:
    movzx r10d, byte ptr [rdi+rsi]
    and r10b, 127
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2468
L2469:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2470
    mov byte ptr [rdi+rsi], r10b
L2471:
    jmp Lnext
L2464:
    call Ltick_slow4
    jmp L2465
L2466:
    call Lrd_slow
    jmp L2467
L2468:
    call Ltick_slow4
    jmp L2469
L2470:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2471
    ALIGN 16
Lccb_BF:
    and al, 127
    jmp Lnext
    ALIGN 16
Lccb_C0:
    or ch, 1
    jmp Lnext
    ALIGN 16
Lccb_C1:
    or cl, 1
    jmp Lnext
    ALIGN 16
Lccb_C2:
    or dh, 1
    jmp Lnext
    ALIGN 16
Lccb_C3:
    or dl, 1
    jmp Lnext
    ALIGN 16
Lccb_C4:
    or bh, 1
    jmp Lnext
    ALIGN 16
Lccb_C5:
    or bl, 1
    jmp Lnext
    ALIGN 16
Lccb_C6:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2472
L2473:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2474
L2475:
    movzx r10d, byte ptr [rdi+rsi]
    or r10b, 1
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2476
L2477:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2478
    mov byte ptr [rdi+rsi], r10b
L2479:
    jmp Lnext
L2472:
    call Ltick_slow4
    jmp L2473
L2474:
    call Lrd_slow
    jmp L2475
L2476:
    call Ltick_slow4
    jmp L2477
L2478:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2479
    ALIGN 16
Lccb_C7:
    or al, 1
    jmp Lnext
    ALIGN 16
Lccb_C8:
    or ch, 2
    jmp Lnext
    ALIGN 16
Lccb_C9:
    or cl, 2
    jmp Lnext
    ALIGN 16
Lccb_CA:
    or dh, 2
    jmp Lnext
    ALIGN 16
Lccb_CB:
    or dl, 2
    jmp Lnext
    ALIGN 16
Lccb_CC:
    or bh, 2
    jmp Lnext
    ALIGN 16
Lccb_CD:
    or bl, 2
    jmp Lnext
    ALIGN 16
Lccb_CE:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2480
L2481:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2482
L2483:
    movzx r10d, byte ptr [rdi+rsi]
    or r10b, 2
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2484
L2485:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2486
    mov byte ptr [rdi+rsi], r10b
L2487:
    jmp Lnext
L2480:
    call Ltick_slow4
    jmp L2481
L2482:
    call Lrd_slow
    jmp L2483
L2484:
    call Ltick_slow4
    jmp L2485
L2486:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2487
    ALIGN 16
Lccb_CF:
    or al, 2
    jmp Lnext
    ALIGN 16
Lccb_D0:
    or ch, 4
    jmp Lnext
    ALIGN 16
Lccb_D1:
    or cl, 4
    jmp Lnext
    ALIGN 16
Lccb_D2:
    or dh, 4
    jmp Lnext
    ALIGN 16
Lccb_D3:
    or dl, 4
    jmp Lnext
    ALIGN 16
Lccb_D4:
    or bh, 4
    jmp Lnext
    ALIGN 16
Lccb_D5:
    or bl, 4
    jmp Lnext
    ALIGN 16
Lccb_D6:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2488
L2489:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2490
L2491:
    movzx r10d, byte ptr [rdi+rsi]
    or r10b, 4
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2492
L2493:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2494
    mov byte ptr [rdi+rsi], r10b
L2495:
    jmp Lnext
L2488:
    call Ltick_slow4
    jmp L2489
L2490:
    call Lrd_slow
    jmp L2491
L2492:
    call Ltick_slow4
    jmp L2493
L2494:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2495
    ALIGN 16
Lccb_D7:
    or al, 4
    jmp Lnext
    ALIGN 16
Lccb_D8:
    or ch, 8
    jmp Lnext
    ALIGN 16
Lccb_D9:
    or cl, 8
    jmp Lnext
    ALIGN 16
Lccb_DA:
    or dh, 8
    jmp Lnext
    ALIGN 16
Lccb_DB:
    or dl, 8
    jmp Lnext
    ALIGN 16
Lccb_DC:
    or bh, 8
    jmp Lnext
    ALIGN 16
Lccb_DD:
    or bl, 8
    jmp Lnext
    ALIGN 16
Lccb_DE:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2496
L2497:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2498
L2499:
    movzx r10d, byte ptr [rdi+rsi]
    or r10b, 8
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2500
L2501:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2502
    mov byte ptr [rdi+rsi], r10b
L2503:
    jmp Lnext
L2496:
    call Ltick_slow4
    jmp L2497
L2498:
    call Lrd_slow
    jmp L2499
L2500:
    call Ltick_slow4
    jmp L2501
L2502:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2503
    ALIGN 16
Lccb_DF:
    or al, 8
    jmp Lnext
    ALIGN 16
Lccb_E0:
    or ch, 16
    jmp Lnext
    ALIGN 16
Lccb_E1:
    or cl, 16
    jmp Lnext
    ALIGN 16
Lccb_E2:
    or dh, 16
    jmp Lnext
    ALIGN 16
Lccb_E3:
    or dl, 16
    jmp Lnext
    ALIGN 16
Lccb_E4:
    or bh, 16
    jmp Lnext
    ALIGN 16
Lccb_E5:
    or bl, 16
    jmp Lnext
    ALIGN 16
Lccb_E6:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2504
L2505:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2506
L2507:
    movzx r10d, byte ptr [rdi+rsi]
    or r10b, 16
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2508
L2509:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2510
    mov byte ptr [rdi+rsi], r10b
L2511:
    jmp Lnext
L2504:
    call Ltick_slow4
    jmp L2505
L2506:
    call Lrd_slow
    jmp L2507
L2508:
    call Ltick_slow4
    jmp L2509
L2510:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2511
    ALIGN 16
Lccb_E7:
    or al, 16
    jmp Lnext
    ALIGN 16
Lccb_E8:
    or ch, 32
    jmp Lnext
    ALIGN 16
Lccb_E9:
    or cl, 32
    jmp Lnext
    ALIGN 16
Lccb_EA:
    or dh, 32
    jmp Lnext
    ALIGN 16
Lccb_EB:
    or dl, 32
    jmp Lnext
    ALIGN 16
Lccb_EC:
    or bh, 32
    jmp Lnext
    ALIGN 16
Lccb_ED:
    or bl, 32
    jmp Lnext
    ALIGN 16
Lccb_EE:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2512
L2513:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2514
L2515:
    movzx r10d, byte ptr [rdi+rsi]
    or r10b, 32
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2516
L2517:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2518
    mov byte ptr [rdi+rsi], r10b
L2519:
    jmp Lnext
L2512:
    call Ltick_slow4
    jmp L2513
L2514:
    call Lrd_slow
    jmp L2515
L2516:
    call Ltick_slow4
    jmp L2517
L2518:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2519
    ALIGN 16
Lccb_EF:
    or al, 32
    jmp Lnext
    ALIGN 16
Lccb_F0:
    or ch, 64
    jmp Lnext
    ALIGN 16
Lccb_F1:
    or cl, 64
    jmp Lnext
    ALIGN 16
Lccb_F2:
    or dh, 64
    jmp Lnext
    ALIGN 16
Lccb_F3:
    or dl, 64
    jmp Lnext
    ALIGN 16
Lccb_F4:
    or bh, 64
    jmp Lnext
    ALIGN 16
Lccb_F5:
    or bl, 64
    jmp Lnext
    ALIGN 16
Lccb_F6:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2520
L2521:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2522
L2523:
    movzx r10d, byte ptr [rdi+rsi]
    or r10b, 64
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2524
L2525:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2526
    mov byte ptr [rdi+rsi], r10b
L2527:
    jmp Lnext
L2520:
    call Ltick_slow4
    jmp L2521
L2522:
    call Lrd_slow
    jmp L2523
L2524:
    call Ltick_slow4
    jmp L2525
L2526:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2527
    ALIGN 16
Lccb_F7:
    or al, 64
    jmp Lnext
    ALIGN 16
Lccb_F8:
    or ch, 128
    jmp Lnext
    ALIGN 16
Lccb_F9:
    or cl, 128
    jmp Lnext
    ALIGN 16
Lccb_FA:
    or dh, 128
    jmp Lnext
    ALIGN 16
Lccb_FB:
    or dl, 128
    jmp Lnext
    ALIGN 16
Lccb_FC:
    or bh, 128
    jmp Lnext
    ALIGN 16
Lccb_FD:
    or bl, 128
    jmp Lnext
    ALIGN 16
Lccb_FE:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2528
L2529:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572288]
    test rdi, rdi
    jz L2530
L2531:
    movzx r10d, byte ptr [rdi+rsi]
    or r10b, 128
    add r14, 4
    cmp r14, qword ptr [r15+572584]
    jae L2532
L2533:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574232]
    test rdi, rdi
    jz L2534
    mov byte ptr [rdi+rsi], r10b
L2535:
    jmp Lnext
L2528:
    call Ltick_slow4
    jmp L2529
L2530:
    call Lrd_slow
    jmp L2531
L2532:
    call Ltick_slow4
    jmp L2533
L2534:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2535
    ALIGN 16
Lccb_FF:
    or al, 128
    jmp Lnext
    ALIGN 4
Ljt_f:
    DD Lf_00 - Ljt_f
    DD Lf_01 - Ljt_f
    DD Lf_02 - Ljt_f
    DD Lf_03 - Ljt_f
    DD Lf_04 - Ljt_f
    DD Lf_05 - Ljt_f
    DD Lf_06 - Ljt_f
    DD Lf_07 - Ljt_f
    DD Lf_08 - Ljt_f
    DD Lf_09 - Ljt_f
    DD Lf_0A - Ljt_f
    DD Lf_0B - Ljt_f
    DD Lf_0C - Ljt_f
    DD Lf_0D - Ljt_f
    DD Lf_0E - Ljt_f
    DD Lf_0F - Ljt_f
    DD Lf_10 - Ljt_f
    DD Lf_11 - Ljt_f
    DD Lf_12 - Ljt_f
    DD Lf_13 - Ljt_f
    DD Lf_14 - Ljt_f
    DD Lf_15 - Ljt_f
    DD Lf_16 - Ljt_f
    DD Lf_17 - Ljt_f
    DD Lf_18 - Ljt_f
    DD Lf_19 - Ljt_f
    DD Lf_1A - Ljt_f
    DD Lf_1B - Ljt_f
    DD Lf_1C - Ljt_f
    DD Lf_1D - Ljt_f
    DD Lf_1E - Ljt_f
    DD Lf_1F - Ljt_f
    DD Lf_20 - Ljt_f
    DD Lf_21 - Ljt_f
    DD Lf_22 - Ljt_f
    DD Lf_23 - Ljt_f
    DD Lf_24 - Ljt_f
    DD Lf_25 - Ljt_f
    DD Lf_26 - Ljt_f
    DD Lf_27 - Ljt_f
    DD Lf_28 - Ljt_f
    DD Lf_29 - Ljt_f
    DD Lf_2A - Ljt_f
    DD Lf_2B - Ljt_f
    DD Lf_2C - Ljt_f
    DD Lf_2D - Ljt_f
    DD Lf_2E - Ljt_f
    DD Lf_2F - Ljt_f
    DD Lf_30 - Ljt_f
    DD Lf_31 - Ljt_f
    DD Lf_32 - Ljt_f
    DD Lf_33 - Ljt_f
    DD Lf_34 - Ljt_f
    DD Lf_35 - Ljt_f
    DD Lf_36 - Ljt_f
    DD Lf_37 - Ljt_f
    DD Lf_38 - Ljt_f
    DD Lf_39 - Ljt_f
    DD Lf_3A - Ljt_f
    DD Lf_3B - Ljt_f
    DD Lf_3C - Ljt_f
    DD Lf_3D - Ljt_f
    DD Lf_3E - Ljt_f
    DD Lf_3F - Ljt_f
    DD Lf_40 - Ljt_f
    DD Lf_41 - Ljt_f
    DD Lf_42 - Ljt_f
    DD Lf_43 - Ljt_f
    DD Lf_44 - Ljt_f
    DD Lf_45 - Ljt_f
    DD Lf_46 - Ljt_f
    DD Lf_47 - Ljt_f
    DD Lf_48 - Ljt_f
    DD Lf_49 - Ljt_f
    DD Lf_4A - Ljt_f
    DD Lf_4B - Ljt_f
    DD Lf_4C - Ljt_f
    DD Lf_4D - Ljt_f
    DD Lf_4E - Ljt_f
    DD Lf_4F - Ljt_f
    DD Lf_50 - Ljt_f
    DD Lf_51 - Ljt_f
    DD Lf_52 - Ljt_f
    DD Lf_53 - Ljt_f
    DD Lf_54 - Ljt_f
    DD Lf_55 - Ljt_f
    DD Lf_56 - Ljt_f
    DD Lf_57 - Ljt_f
    DD Lf_58 - Ljt_f
    DD Lf_59 - Ljt_f
    DD Lf_5A - Ljt_f
    DD Lf_5B - Ljt_f
    DD Lf_5C - Ljt_f
    DD Lf_5D - Ljt_f
    DD Lf_5E - Ljt_f
    DD Lf_5F - Ljt_f
    DD Lf_60 - Ljt_f
    DD Lf_61 - Ljt_f
    DD Lf_62 - Ljt_f
    DD Lf_63 - Ljt_f
    DD Lf_64 - Ljt_f
    DD Lf_65 - Ljt_f
    DD Lf_66 - Ljt_f
    DD Lf_67 - Ljt_f
    DD Lf_68 - Ljt_f
    DD Lf_69 - Ljt_f
    DD Lf_6A - Ljt_f
    DD Lf_6B - Ljt_f
    DD Lf_6C - Ljt_f
    DD Lf_6D - Ljt_f
    DD Lf_6E - Ljt_f
    DD Lf_6F - Ljt_f
    DD Lf_70 - Ljt_f
    DD Lf_71 - Ljt_f
    DD Lf_72 - Ljt_f
    DD Lf_73 - Ljt_f
    DD Lf_74 - Ljt_f
    DD Lf_75 - Ljt_f
    DD Lf_76 - Ljt_f
    DD Lf_77 - Ljt_f
    DD Lf_78 - Ljt_f
    DD Lf_79 - Ljt_f
    DD Lf_7A - Ljt_f
    DD Lf_7B - Ljt_f
    DD Lf_7C - Ljt_f
    DD Lf_7D - Ljt_f
    DD Lf_7E - Ljt_f
    DD Lf_7F - Ljt_f
    DD Lf_80 - Ljt_f
    DD Lf_81 - Ljt_f
    DD Lf_82 - Ljt_f
    DD Lf_83 - Ljt_f
    DD Lf_84 - Ljt_f
    DD Lf_85 - Ljt_f
    DD Lf_86 - Ljt_f
    DD Lf_87 - Ljt_f
    DD Lf_88 - Ljt_f
    DD Lf_89 - Ljt_f
    DD Lf_8A - Ljt_f
    DD Lf_8B - Ljt_f
    DD Lf_8C - Ljt_f
    DD Lf_8D - Ljt_f
    DD Lf_8E - Ljt_f
    DD Lf_8F - Ljt_f
    DD Lf_90 - Ljt_f
    DD Lf_91 - Ljt_f
    DD Lf_92 - Ljt_f
    DD Lf_93 - Ljt_f
    DD Lf_94 - Ljt_f
    DD Lf_95 - Ljt_f
    DD Lf_96 - Ljt_f
    DD Lf_97 - Ljt_f
    DD Lf_98 - Ljt_f
    DD Lf_99 - Ljt_f
    DD Lf_9A - Ljt_f
    DD Lf_9B - Ljt_f
    DD Lf_9C - Ljt_f
    DD Lf_9D - Ljt_f
    DD Lf_9E - Ljt_f
    DD Lf_9F - Ljt_f
    DD Lf_A0 - Ljt_f
    DD Lf_A1 - Ljt_f
    DD Lf_A2 - Ljt_f
    DD Lf_A3 - Ljt_f
    DD Lf_A4 - Ljt_f
    DD Lf_A5 - Ljt_f
    DD Lf_A6 - Ljt_f
    DD Lf_A7 - Ljt_f
    DD Lf_A8 - Ljt_f
    DD Lf_A9 - Ljt_f
    DD Lf_AA - Ljt_f
    DD Lf_AB - Ljt_f
    DD Lf_AC - Ljt_f
    DD Lf_AD - Ljt_f
    DD Lf_AE - Ljt_f
    DD Lf_AF - Ljt_f
    DD Lf_B0 - Ljt_f
    DD Lf_B1 - Ljt_f
    DD Lf_B2 - Ljt_f
    DD Lf_B3 - Ljt_f
    DD Lf_B4 - Ljt_f
    DD Lf_B5 - Ljt_f
    DD Lf_B6 - Ljt_f
    DD Lf_B7 - Ljt_f
    DD Lf_B8 - Ljt_f
    DD Lf_B9 - Ljt_f
    DD Lf_BA - Ljt_f
    DD Lf_BB - Ljt_f
    DD Lf_BC - Ljt_f
    DD Lf_BD - Ljt_f
    DD Lf_BE - Ljt_f
    DD Lf_BF - Ljt_f
    DD Lf_C0 - Ljt_f
    DD Lf_C1 - Ljt_f
    DD Lf_C2 - Ljt_f
    DD Lf_C3 - Ljt_f
    DD Lf_C4 - Ljt_f
    DD Lf_C5 - Ljt_f
    DD Lf_C6 - Ljt_f
    DD Lf_C7 - Ljt_f
    DD Lf_C8 - Ljt_f
    DD Lf_C9 - Ljt_f
    DD Lf_CA - Ljt_f
    DD Lf_CB - Ljt_f
    DD Lf_CC - Ljt_f
    DD Lf_CD - Ljt_f
    DD Lf_CE - Ljt_f
    DD Lf_CF - Ljt_f
    DD Lf_D0 - Ljt_f
    DD Lf_D1 - Ljt_f
    DD Lf_D2 - Ljt_f
    DD Lf_D3 - Ljt_f
    DD Lf_D4 - Ljt_f
    DD Lf_D5 - Ljt_f
    DD Lf_D6 - Ljt_f
    DD Lf_D7 - Ljt_f
    DD Lf_D8 - Ljt_f
    DD Lf_D9 - Ljt_f
    DD Lf_DA - Ljt_f
    DD Lf_DB - Ljt_f
    DD Lf_DC - Ljt_f
    DD Lf_DD - Ljt_f
    DD Lf_DE - Ljt_f
    DD Lf_DF - Ljt_f
    DD Lf_E0 - Ljt_f
    DD Lf_E1 - Ljt_f
    DD Lf_E2 - Ljt_f
    DD Lf_E3 - Ljt_f
    DD Lf_E4 - Ljt_f
    DD Lf_E5 - Ljt_f
    DD Lf_E6 - Ljt_f
    DD Lf_E7 - Ljt_f
    DD Lf_E8 - Ljt_f
    DD Lf_E9 - Ljt_f
    DD Lf_EA - Ljt_f
    DD Lf_EB - Ljt_f
    DD Lf_EC - Ljt_f
    DD Lf_ED - Ljt_f
    DD Lf_EE - Ljt_f
    DD Lf_EF - Ljt_f
    DD Lf_F0 - Ljt_f
    DD Lf_F1 - Ljt_f
    DD Lf_F2 - Ljt_f
    DD Lf_F3 - Ljt_f
    DD Lf_F4 - Ljt_f
    DD Lf_F5 - Ljt_f
    DD Lf_F6 - Ljt_f
    DD Lf_F7 - Ljt_f
    DD Lf_F8 - Ljt_f
    DD Lf_F9 - Ljt_f
    DD Lf_FA - Ljt_f
    DD Lf_FB - Ljt_f
    DD Lf_FC - Ljt_f
    DD Lf_FD - Ljt_f
    DD Lf_FE - Ljt_f
    DD Lf_FF - Ljt_f
    ALIGN 4
Ljt_c:
    DD Lc_00 - Ljt_c
    DD Lc_01 - Ljt_c
    DD Lc_02 - Ljt_c
    DD Lc_03 - Ljt_c
    DD Lc_04 - Ljt_c
    DD Lc_05 - Ljt_c
    DD Lc_06 - Ljt_c
    DD Lc_07 - Ljt_c
    DD Lc_08 - Ljt_c
    DD Lc_09 - Ljt_c
    DD Lc_0A - Ljt_c
    DD Lc_0B - Ljt_c
    DD Lc_0C - Ljt_c
    DD Lc_0D - Ljt_c
    DD Lc_0E - Ljt_c
    DD Lc_0F - Ljt_c
    DD Lc_10 - Ljt_c
    DD Lc_11 - Ljt_c
    DD Lc_12 - Ljt_c
    DD Lc_13 - Ljt_c
    DD Lc_14 - Ljt_c
    DD Lc_15 - Ljt_c
    DD Lc_16 - Ljt_c
    DD Lc_17 - Ljt_c
    DD Lc_18 - Ljt_c
    DD Lc_19 - Ljt_c
    DD Lc_1A - Ljt_c
    DD Lc_1B - Ljt_c
    DD Lc_1C - Ljt_c
    DD Lc_1D - Ljt_c
    DD Lc_1E - Ljt_c
    DD Lc_1F - Ljt_c
    DD Lc_20 - Ljt_c
    DD Lc_21 - Ljt_c
    DD Lc_22 - Ljt_c
    DD Lc_23 - Ljt_c
    DD Lc_24 - Ljt_c
    DD Lc_25 - Ljt_c
    DD Lc_26 - Ljt_c
    DD Lc_27 - Ljt_c
    DD Lc_28 - Ljt_c
    DD Lc_29 - Ljt_c
    DD Lc_2A - Ljt_c
    DD Lc_2B - Ljt_c
    DD Lc_2C - Ljt_c
    DD Lc_2D - Ljt_c
    DD Lc_2E - Ljt_c
    DD Lc_2F - Ljt_c
    DD Lc_30 - Ljt_c
    DD Lc_31 - Ljt_c
    DD Lc_32 - Ljt_c
    DD Lc_33 - Ljt_c
    DD Lc_34 - Ljt_c
    DD Lc_35 - Ljt_c
    DD Lc_36 - Ljt_c
    DD Lc_37 - Ljt_c
    DD Lc_38 - Ljt_c
    DD Lc_39 - Ljt_c
    DD Lc_3A - Ljt_c
    DD Lc_3B - Ljt_c
    DD Lc_3C - Ljt_c
    DD Lc_3D - Ljt_c
    DD Lc_3E - Ljt_c
    DD Lc_3F - Ljt_c
    DD Lc_40 - Ljt_c
    DD Lc_41 - Ljt_c
    DD Lc_42 - Ljt_c
    DD Lc_43 - Ljt_c
    DD Lc_44 - Ljt_c
    DD Lc_45 - Ljt_c
    DD Lc_46 - Ljt_c
    DD Lc_47 - Ljt_c
    DD Lc_48 - Ljt_c
    DD Lc_49 - Ljt_c
    DD Lc_4A - Ljt_c
    DD Lc_4B - Ljt_c
    DD Lc_4C - Ljt_c
    DD Lc_4D - Ljt_c
    DD Lc_4E - Ljt_c
    DD Lc_4F - Ljt_c
    DD Lc_50 - Ljt_c
    DD Lc_51 - Ljt_c
    DD Lc_52 - Ljt_c
    DD Lc_53 - Ljt_c
    DD Lc_54 - Ljt_c
    DD Lc_55 - Ljt_c
    DD Lc_56 - Ljt_c
    DD Lc_57 - Ljt_c
    DD Lc_58 - Ljt_c
    DD Lc_59 - Ljt_c
    DD Lc_5A - Ljt_c
    DD Lc_5B - Ljt_c
    DD Lc_5C - Ljt_c
    DD Lc_5D - Ljt_c
    DD Lc_5E - Ljt_c
    DD Lc_5F - Ljt_c
    DD Lc_60 - Ljt_c
    DD Lc_61 - Ljt_c
    DD Lc_62 - Ljt_c
    DD Lc_63 - Ljt_c
    DD Lc_64 - Ljt_c
    DD Lc_65 - Ljt_c
    DD Lc_66 - Ljt_c
    DD Lc_67 - Ljt_c
    DD Lc_68 - Ljt_c
    DD Lc_69 - Ljt_c
    DD Lc_6A - Ljt_c
    DD Lc_6B - Ljt_c
    DD Lc_6C - Ljt_c
    DD Lc_6D - Ljt_c
    DD Lc_6E - Ljt_c
    DD Lc_6F - Ljt_c
    DD Lc_70 - Ljt_c
    DD Lc_71 - Ljt_c
    DD Lc_72 - Ljt_c
    DD Lc_73 - Ljt_c
    DD Lc_74 - Ljt_c
    DD Lc_75 - Ljt_c
    DD Lc_76 - Ljt_c
    DD Lc_77 - Ljt_c
    DD Lc_78 - Ljt_c
    DD Lc_79 - Ljt_c
    DD Lc_7A - Ljt_c
    DD Lc_7B - Ljt_c
    DD Lc_7C - Ljt_c
    DD Lc_7D - Ljt_c
    DD Lc_7E - Ljt_c
    DD Lc_7F - Ljt_c
    DD Lc_80 - Ljt_c
    DD Lc_81 - Ljt_c
    DD Lc_82 - Ljt_c
    DD Lc_83 - Ljt_c
    DD Lc_84 - Ljt_c
    DD Lc_85 - Ljt_c
    DD Lc_86 - Ljt_c
    DD Lc_87 - Ljt_c
    DD Lc_88 - Ljt_c
    DD Lc_89 - Ljt_c
    DD Lc_8A - Ljt_c
    DD Lc_8B - Ljt_c
    DD Lc_8C - Ljt_c
    DD Lc_8D - Ljt_c
    DD Lc_8E - Ljt_c
    DD Lc_8F - Ljt_c
    DD Lc_90 - Ljt_c
    DD Lc_91 - Ljt_c
    DD Lc_92 - Ljt_c
    DD Lc_93 - Ljt_c
    DD Lc_94 - Ljt_c
    DD Lc_95 - Ljt_c
    DD Lc_96 - Ljt_c
    DD Lc_97 - Ljt_c
    DD Lc_98 - Ljt_c
    DD Lc_99 - Ljt_c
    DD Lc_9A - Ljt_c
    DD Lc_9B - Ljt_c
    DD Lc_9C - Ljt_c
    DD Lc_9D - Ljt_c
    DD Lc_9E - Ljt_c
    DD Lc_9F - Ljt_c
    DD Lc_A0 - Ljt_c
    DD Lc_A1 - Ljt_c
    DD Lc_A2 - Ljt_c
    DD Lc_A3 - Ljt_c
    DD Lc_A4 - Ljt_c
    DD Lc_A5 - Ljt_c
    DD Lc_A6 - Ljt_c
    DD Lc_A7 - Ljt_c
    DD Lc_A8 - Ljt_c
    DD Lc_A9 - Ljt_c
    DD Lc_AA - Ljt_c
    DD Lc_AB - Ljt_c
    DD Lc_AC - Ljt_c
    DD Lc_AD - Ljt_c
    DD Lc_AE - Ljt_c
    DD Lc_AF - Ljt_c
    DD Lc_B0 - Ljt_c
    DD Lc_B1 - Ljt_c
    DD Lc_B2 - Ljt_c
    DD Lc_B3 - Ljt_c
    DD Lc_B4 - Ljt_c
    DD Lc_B5 - Ljt_c
    DD Lc_B6 - Ljt_c
    DD Lc_B7 - Ljt_c
    DD Lc_B8 - Ljt_c
    DD Lc_B9 - Ljt_c
    DD Lc_BA - Ljt_c
    DD Lc_BB - Ljt_c
    DD Lc_BC - Ljt_c
    DD Lc_BD - Ljt_c
    DD Lc_BE - Ljt_c
    DD Lc_BF - Ljt_c
    DD Lc_C0 - Ljt_c
    DD Lc_C1 - Ljt_c
    DD Lc_C2 - Ljt_c
    DD Lc_C3 - Ljt_c
    DD Lc_C4 - Ljt_c
    DD Lc_C5 - Ljt_c
    DD Lc_C6 - Ljt_c
    DD Lc_C7 - Ljt_c
    DD Lc_C8 - Ljt_c
    DD Lc_C9 - Ljt_c
    DD Lc_CA - Ljt_c
    DD Lc_CB - Ljt_c
    DD Lc_CC - Ljt_c
    DD Lc_CD - Ljt_c
    DD Lc_CE - Ljt_c
    DD Lc_CF - Ljt_c
    DD Lc_D0 - Ljt_c
    DD Lc_D1 - Ljt_c
    DD Lc_D2 - Ljt_c
    DD Lc_D3 - Ljt_c
    DD Lc_D4 - Ljt_c
    DD Lc_D5 - Ljt_c
    DD Lc_D6 - Ljt_c
    DD Lc_D7 - Ljt_c
    DD Lc_D8 - Ljt_c
    DD Lc_D9 - Ljt_c
    DD Lc_DA - Ljt_c
    DD Lc_DB - Ljt_c
    DD Lc_DC - Ljt_c
    DD Lc_DD - Ljt_c
    DD Lc_DE - Ljt_c
    DD Lc_DF - Ljt_c
    DD Lc_E0 - Ljt_c
    DD Lc_E1 - Ljt_c
    DD Lc_E2 - Ljt_c
    DD Lc_E3 - Ljt_c
    DD Lc_E4 - Ljt_c
    DD Lc_E5 - Ljt_c
    DD Lc_E6 - Ljt_c
    DD Lc_E7 - Ljt_c
    DD Lc_E8 - Ljt_c
    DD Lc_E9 - Ljt_c
    DD Lc_EA - Ljt_c
    DD Lc_EB - Ljt_c
    DD Lc_EC - Ljt_c
    DD Lc_ED - Ljt_c
    DD Lc_EE - Ljt_c
    DD Lc_EF - Ljt_c
    DD Lc_F0 - Ljt_c
    DD Lc_F1 - Ljt_c
    DD Lc_F2 - Ljt_c
    DD Lc_F3 - Ljt_c
    DD Lc_F4 - Ljt_c
    DD Lc_F5 - Ljt_c
    DD Lc_F6 - Ljt_c
    DD Lc_F7 - Ljt_c
    DD Lc_F8 - Ljt_c
    DD Lc_F9 - Ljt_c
    DD Lc_FA - Ljt_c
    DD Lc_FB - Ljt_c
    DD Lc_FC - Ljt_c
    DD Lc_FD - Ljt_c
    DD Lc_FE - Ljt_c
    DD Lc_FF - Ljt_c
    ALIGN 4
Ljt_fcb:
    DD Lfcb_00 - Ljt_fcb
    DD Lfcb_01 - Ljt_fcb
    DD Lfcb_02 - Ljt_fcb
    DD Lfcb_03 - Ljt_fcb
    DD Lfcb_04 - Ljt_fcb
    DD Lfcb_05 - Ljt_fcb
    DD Lfcb_06 - Ljt_fcb
    DD Lfcb_07 - Ljt_fcb
    DD Lfcb_08 - Ljt_fcb
    DD Lfcb_09 - Ljt_fcb
    DD Lfcb_0A - Ljt_fcb
    DD Lfcb_0B - Ljt_fcb
    DD Lfcb_0C - Ljt_fcb
    DD Lfcb_0D - Ljt_fcb
    DD Lfcb_0E - Ljt_fcb
    DD Lfcb_0F - Ljt_fcb
    DD Lfcb_10 - Ljt_fcb
    DD Lfcb_11 - Ljt_fcb
    DD Lfcb_12 - Ljt_fcb
    DD Lfcb_13 - Ljt_fcb
    DD Lfcb_14 - Ljt_fcb
    DD Lfcb_15 - Ljt_fcb
    DD Lfcb_16 - Ljt_fcb
    DD Lfcb_17 - Ljt_fcb
    DD Lfcb_18 - Ljt_fcb
    DD Lfcb_19 - Ljt_fcb
    DD Lfcb_1A - Ljt_fcb
    DD Lfcb_1B - Ljt_fcb
    DD Lfcb_1C - Ljt_fcb
    DD Lfcb_1D - Ljt_fcb
    DD Lfcb_1E - Ljt_fcb
    DD Lfcb_1F - Ljt_fcb
    DD Lfcb_20 - Ljt_fcb
    DD Lfcb_21 - Ljt_fcb
    DD Lfcb_22 - Ljt_fcb
    DD Lfcb_23 - Ljt_fcb
    DD Lfcb_24 - Ljt_fcb
    DD Lfcb_25 - Ljt_fcb
    DD Lfcb_26 - Ljt_fcb
    DD Lfcb_27 - Ljt_fcb
    DD Lfcb_28 - Ljt_fcb
    DD Lfcb_29 - Ljt_fcb
    DD Lfcb_2A - Ljt_fcb
    DD Lfcb_2B - Ljt_fcb
    DD Lfcb_2C - Ljt_fcb
    DD Lfcb_2D - Ljt_fcb
    DD Lfcb_2E - Ljt_fcb
    DD Lfcb_2F - Ljt_fcb
    DD Lfcb_30 - Ljt_fcb
    DD Lfcb_31 - Ljt_fcb
    DD Lfcb_32 - Ljt_fcb
    DD Lfcb_33 - Ljt_fcb
    DD Lfcb_34 - Ljt_fcb
    DD Lfcb_35 - Ljt_fcb
    DD Lfcb_36 - Ljt_fcb
    DD Lfcb_37 - Ljt_fcb
    DD Lfcb_38 - Ljt_fcb
    DD Lfcb_39 - Ljt_fcb
    DD Lfcb_3A - Ljt_fcb
    DD Lfcb_3B - Ljt_fcb
    DD Lfcb_3C - Ljt_fcb
    DD Lfcb_3D - Ljt_fcb
    DD Lfcb_3E - Ljt_fcb
    DD Lfcb_3F - Ljt_fcb
    DD Lfcb_40 - Ljt_fcb
    DD Lfcb_41 - Ljt_fcb
    DD Lfcb_42 - Ljt_fcb
    DD Lfcb_43 - Ljt_fcb
    DD Lfcb_44 - Ljt_fcb
    DD Lfcb_45 - Ljt_fcb
    DD Lfcb_46 - Ljt_fcb
    DD Lfcb_47 - Ljt_fcb
    DD Lfcb_48 - Ljt_fcb
    DD Lfcb_49 - Ljt_fcb
    DD Lfcb_4A - Ljt_fcb
    DD Lfcb_4B - Ljt_fcb
    DD Lfcb_4C - Ljt_fcb
    DD Lfcb_4D - Ljt_fcb
    DD Lfcb_4E - Ljt_fcb
    DD Lfcb_4F - Ljt_fcb
    DD Lfcb_50 - Ljt_fcb
    DD Lfcb_51 - Ljt_fcb
    DD Lfcb_52 - Ljt_fcb
    DD Lfcb_53 - Ljt_fcb
    DD Lfcb_54 - Ljt_fcb
    DD Lfcb_55 - Ljt_fcb
    DD Lfcb_56 - Ljt_fcb
    DD Lfcb_57 - Ljt_fcb
    DD Lfcb_58 - Ljt_fcb
    DD Lfcb_59 - Ljt_fcb
    DD Lfcb_5A - Ljt_fcb
    DD Lfcb_5B - Ljt_fcb
    DD Lfcb_5C - Ljt_fcb
    DD Lfcb_5D - Ljt_fcb
    DD Lfcb_5E - Ljt_fcb
    DD Lfcb_5F - Ljt_fcb
    DD Lfcb_60 - Ljt_fcb
    DD Lfcb_61 - Ljt_fcb
    DD Lfcb_62 - Ljt_fcb
    DD Lfcb_63 - Ljt_fcb
    DD Lfcb_64 - Ljt_fcb
    DD Lfcb_65 - Ljt_fcb
    DD Lfcb_66 - Ljt_fcb
    DD Lfcb_67 - Ljt_fcb
    DD Lfcb_68 - Ljt_fcb
    DD Lfcb_69 - Ljt_fcb
    DD Lfcb_6A - Ljt_fcb
    DD Lfcb_6B - Ljt_fcb
    DD Lfcb_6C - Ljt_fcb
    DD Lfcb_6D - Ljt_fcb
    DD Lfcb_6E - Ljt_fcb
    DD Lfcb_6F - Ljt_fcb
    DD Lfcb_70 - Ljt_fcb
    DD Lfcb_71 - Ljt_fcb
    DD Lfcb_72 - Ljt_fcb
    DD Lfcb_73 - Ljt_fcb
    DD Lfcb_74 - Ljt_fcb
    DD Lfcb_75 - Ljt_fcb
    DD Lfcb_76 - Ljt_fcb
    DD Lfcb_77 - Ljt_fcb
    DD Lfcb_78 - Ljt_fcb
    DD Lfcb_79 - Ljt_fcb
    DD Lfcb_7A - Ljt_fcb
    DD Lfcb_7B - Ljt_fcb
    DD Lfcb_7C - Ljt_fcb
    DD Lfcb_7D - Ljt_fcb
    DD Lfcb_7E - Ljt_fcb
    DD Lfcb_7F - Ljt_fcb
    DD Lfcb_80 - Ljt_fcb
    DD Lfcb_81 - Ljt_fcb
    DD Lfcb_82 - Ljt_fcb
    DD Lfcb_83 - Ljt_fcb
    DD Lfcb_84 - Ljt_fcb
    DD Lfcb_85 - Ljt_fcb
    DD Lfcb_86 - Ljt_fcb
    DD Lfcb_87 - Ljt_fcb
    DD Lfcb_88 - Ljt_fcb
    DD Lfcb_89 - Ljt_fcb
    DD Lfcb_8A - Ljt_fcb
    DD Lfcb_8B - Ljt_fcb
    DD Lfcb_8C - Ljt_fcb
    DD Lfcb_8D - Ljt_fcb
    DD Lfcb_8E - Ljt_fcb
    DD Lfcb_8F - Ljt_fcb
    DD Lfcb_90 - Ljt_fcb
    DD Lfcb_91 - Ljt_fcb
    DD Lfcb_92 - Ljt_fcb
    DD Lfcb_93 - Ljt_fcb
    DD Lfcb_94 - Ljt_fcb
    DD Lfcb_95 - Ljt_fcb
    DD Lfcb_96 - Ljt_fcb
    DD Lfcb_97 - Ljt_fcb
    DD Lfcb_98 - Ljt_fcb
    DD Lfcb_99 - Ljt_fcb
    DD Lfcb_9A - Ljt_fcb
    DD Lfcb_9B - Ljt_fcb
    DD Lfcb_9C - Ljt_fcb
    DD Lfcb_9D - Ljt_fcb
    DD Lfcb_9E - Ljt_fcb
    DD Lfcb_9F - Ljt_fcb
    DD Lfcb_A0 - Ljt_fcb
    DD Lfcb_A1 - Ljt_fcb
    DD Lfcb_A2 - Ljt_fcb
    DD Lfcb_A3 - Ljt_fcb
    DD Lfcb_A4 - Ljt_fcb
    DD Lfcb_A5 - Ljt_fcb
    DD Lfcb_A6 - Ljt_fcb
    DD Lfcb_A7 - Ljt_fcb
    DD Lfcb_A8 - Ljt_fcb
    DD Lfcb_A9 - Ljt_fcb
    DD Lfcb_AA - Ljt_fcb
    DD Lfcb_AB - Ljt_fcb
    DD Lfcb_AC - Ljt_fcb
    DD Lfcb_AD - Ljt_fcb
    DD Lfcb_AE - Ljt_fcb
    DD Lfcb_AF - Ljt_fcb
    DD Lfcb_B0 - Ljt_fcb
    DD Lfcb_B1 - Ljt_fcb
    DD Lfcb_B2 - Ljt_fcb
    DD Lfcb_B3 - Ljt_fcb
    DD Lfcb_B4 - Ljt_fcb
    DD Lfcb_B5 - Ljt_fcb
    DD Lfcb_B6 - Ljt_fcb
    DD Lfcb_B7 - Ljt_fcb
    DD Lfcb_B8 - Ljt_fcb
    DD Lfcb_B9 - Ljt_fcb
    DD Lfcb_BA - Ljt_fcb
    DD Lfcb_BB - Ljt_fcb
    DD Lfcb_BC - Ljt_fcb
    DD Lfcb_BD - Ljt_fcb
    DD Lfcb_BE - Ljt_fcb
    DD Lfcb_BF - Ljt_fcb
    DD Lfcb_C0 - Ljt_fcb
    DD Lfcb_C1 - Ljt_fcb
    DD Lfcb_C2 - Ljt_fcb
    DD Lfcb_C3 - Ljt_fcb
    DD Lfcb_C4 - Ljt_fcb
    DD Lfcb_C5 - Ljt_fcb
    DD Lfcb_C6 - Ljt_fcb
    DD Lfcb_C7 - Ljt_fcb
    DD Lfcb_C8 - Ljt_fcb
    DD Lfcb_C9 - Ljt_fcb
    DD Lfcb_CA - Ljt_fcb
    DD Lfcb_CB - Ljt_fcb
    DD Lfcb_CC - Ljt_fcb
    DD Lfcb_CD - Ljt_fcb
    DD Lfcb_CE - Ljt_fcb
    DD Lfcb_CF - Ljt_fcb
    DD Lfcb_D0 - Ljt_fcb
    DD Lfcb_D1 - Ljt_fcb
    DD Lfcb_D2 - Ljt_fcb
    DD Lfcb_D3 - Ljt_fcb
    DD Lfcb_D4 - Ljt_fcb
    DD Lfcb_D5 - Ljt_fcb
    DD Lfcb_D6 - Ljt_fcb
    DD Lfcb_D7 - Ljt_fcb
    DD Lfcb_D8 - Ljt_fcb
    DD Lfcb_D9 - Ljt_fcb
    DD Lfcb_DA - Ljt_fcb
    DD Lfcb_DB - Ljt_fcb
    DD Lfcb_DC - Ljt_fcb
    DD Lfcb_DD - Ljt_fcb
    DD Lfcb_DE - Ljt_fcb
    DD Lfcb_DF - Ljt_fcb
    DD Lfcb_E0 - Ljt_fcb
    DD Lfcb_E1 - Ljt_fcb
    DD Lfcb_E2 - Ljt_fcb
    DD Lfcb_E3 - Ljt_fcb
    DD Lfcb_E4 - Ljt_fcb
    DD Lfcb_E5 - Ljt_fcb
    DD Lfcb_E6 - Ljt_fcb
    DD Lfcb_E7 - Ljt_fcb
    DD Lfcb_E8 - Ljt_fcb
    DD Lfcb_E9 - Ljt_fcb
    DD Lfcb_EA - Ljt_fcb
    DD Lfcb_EB - Ljt_fcb
    DD Lfcb_EC - Ljt_fcb
    DD Lfcb_ED - Ljt_fcb
    DD Lfcb_EE - Ljt_fcb
    DD Lfcb_EF - Ljt_fcb
    DD Lfcb_F0 - Ljt_fcb
    DD Lfcb_F1 - Ljt_fcb
    DD Lfcb_F2 - Ljt_fcb
    DD Lfcb_F3 - Ljt_fcb
    DD Lfcb_F4 - Ljt_fcb
    DD Lfcb_F5 - Ljt_fcb
    DD Lfcb_F6 - Ljt_fcb
    DD Lfcb_F7 - Ljt_fcb
    DD Lfcb_F8 - Ljt_fcb
    DD Lfcb_F9 - Ljt_fcb
    DD Lfcb_FA - Ljt_fcb
    DD Lfcb_FB - Ljt_fcb
    DD Lfcb_FC - Ljt_fcb
    DD Lfcb_FD - Ljt_fcb
    DD Lfcb_FE - Ljt_fcb
    DD Lfcb_FF - Ljt_fcb
    ALIGN 4
Ljt_ccb:
    DD Lccb_00 - Ljt_ccb
    DD Lccb_01 - Ljt_ccb
    DD Lccb_02 - Ljt_ccb
    DD Lccb_03 - Ljt_ccb
    DD Lccb_04 - Ljt_ccb
    DD Lccb_05 - Ljt_ccb
    DD Lccb_06 - Ljt_ccb
    DD Lccb_07 - Ljt_ccb
    DD Lccb_08 - Ljt_ccb
    DD Lccb_09 - Ljt_ccb
    DD Lccb_0A - Ljt_ccb
    DD Lccb_0B - Ljt_ccb
    DD Lccb_0C - Ljt_ccb
    DD Lccb_0D - Ljt_ccb
    DD Lccb_0E - Ljt_ccb
    DD Lccb_0F - Ljt_ccb
    DD Lccb_10 - Ljt_ccb
    DD Lccb_11 - Ljt_ccb
    DD Lccb_12 - Ljt_ccb
    DD Lccb_13 - Ljt_ccb
    DD Lccb_14 - Ljt_ccb
    DD Lccb_15 - Ljt_ccb
    DD Lccb_16 - Ljt_ccb
    DD Lccb_17 - Ljt_ccb
    DD Lccb_18 - Ljt_ccb
    DD Lccb_19 - Ljt_ccb
    DD Lccb_1A - Ljt_ccb
    DD Lccb_1B - Ljt_ccb
    DD Lccb_1C - Ljt_ccb
    DD Lccb_1D - Ljt_ccb
    DD Lccb_1E - Ljt_ccb
    DD Lccb_1F - Ljt_ccb
    DD Lccb_20 - Ljt_ccb
    DD Lccb_21 - Ljt_ccb
    DD Lccb_22 - Ljt_ccb
    DD Lccb_23 - Ljt_ccb
    DD Lccb_24 - Ljt_ccb
    DD Lccb_25 - Ljt_ccb
    DD Lccb_26 - Ljt_ccb
    DD Lccb_27 - Ljt_ccb
    DD Lccb_28 - Ljt_ccb
    DD Lccb_29 - Ljt_ccb
    DD Lccb_2A - Ljt_ccb
    DD Lccb_2B - Ljt_ccb
    DD Lccb_2C - Ljt_ccb
    DD Lccb_2D - Ljt_ccb
    DD Lccb_2E - Ljt_ccb
    DD Lccb_2F - Ljt_ccb
    DD Lccb_30 - Ljt_ccb
    DD Lccb_31 - Ljt_ccb
    DD Lccb_32 - Ljt_ccb
    DD Lccb_33 - Ljt_ccb
    DD Lccb_34 - Ljt_ccb
    DD Lccb_35 - Ljt_ccb
    DD Lccb_36 - Ljt_ccb
    DD Lccb_37 - Ljt_ccb
    DD Lccb_38 - Ljt_ccb
    DD Lccb_39 - Ljt_ccb
    DD Lccb_3A - Ljt_ccb
    DD Lccb_3B - Ljt_ccb
    DD Lccb_3C - Ljt_ccb
    DD Lccb_3D - Ljt_ccb
    DD Lccb_3E - Ljt_ccb
    DD Lccb_3F - Ljt_ccb
    DD Lccb_40 - Ljt_ccb
    DD Lccb_41 - Ljt_ccb
    DD Lccb_42 - Ljt_ccb
    DD Lccb_43 - Ljt_ccb
    DD Lccb_44 - Ljt_ccb
    DD Lccb_45 - Ljt_ccb
    DD Lccb_46 - Ljt_ccb
    DD Lccb_47 - Ljt_ccb
    DD Lccb_48 - Ljt_ccb
    DD Lccb_49 - Ljt_ccb
    DD Lccb_4A - Ljt_ccb
    DD Lccb_4B - Ljt_ccb
    DD Lccb_4C - Ljt_ccb
    DD Lccb_4D - Ljt_ccb
    DD Lccb_4E - Ljt_ccb
    DD Lccb_4F - Ljt_ccb
    DD Lccb_50 - Ljt_ccb
    DD Lccb_51 - Ljt_ccb
    DD Lccb_52 - Ljt_ccb
    DD Lccb_53 - Ljt_ccb
    DD Lccb_54 - Ljt_ccb
    DD Lccb_55 - Ljt_ccb
    DD Lccb_56 - Ljt_ccb
    DD Lccb_57 - Ljt_ccb
    DD Lccb_58 - Ljt_ccb
    DD Lccb_59 - Ljt_ccb
    DD Lccb_5A - Ljt_ccb
    DD Lccb_5B - Ljt_ccb
    DD Lccb_5C - Ljt_ccb
    DD Lccb_5D - Ljt_ccb
    DD Lccb_5E - Ljt_ccb
    DD Lccb_5F - Ljt_ccb
    DD Lccb_60 - Ljt_ccb
    DD Lccb_61 - Ljt_ccb
    DD Lccb_62 - Ljt_ccb
    DD Lccb_63 - Ljt_ccb
    DD Lccb_64 - Ljt_ccb
    DD Lccb_65 - Ljt_ccb
    DD Lccb_66 - Ljt_ccb
    DD Lccb_67 - Ljt_ccb
    DD Lccb_68 - Ljt_ccb
    DD Lccb_69 - Ljt_ccb
    DD Lccb_6A - Ljt_ccb
    DD Lccb_6B - Ljt_ccb
    DD Lccb_6C - Ljt_ccb
    DD Lccb_6D - Ljt_ccb
    DD Lccb_6E - Ljt_ccb
    DD Lccb_6F - Ljt_ccb
    DD Lccb_70 - Ljt_ccb
    DD Lccb_71 - Ljt_ccb
    DD Lccb_72 - Ljt_ccb
    DD Lccb_73 - Ljt_ccb
    DD Lccb_74 - Ljt_ccb
    DD Lccb_75 - Ljt_ccb
    DD Lccb_76 - Ljt_ccb
    DD Lccb_77 - Ljt_ccb
    DD Lccb_78 - Ljt_ccb
    DD Lccb_79 - Ljt_ccb
    DD Lccb_7A - Ljt_ccb
    DD Lccb_7B - Ljt_ccb
    DD Lccb_7C - Ljt_ccb
    DD Lccb_7D - Ljt_ccb
    DD Lccb_7E - Ljt_ccb
    DD Lccb_7F - Ljt_ccb
    DD Lccb_80 - Ljt_ccb
    DD Lccb_81 - Ljt_ccb
    DD Lccb_82 - Ljt_ccb
    DD Lccb_83 - Ljt_ccb
    DD Lccb_84 - Ljt_ccb
    DD Lccb_85 - Ljt_ccb
    DD Lccb_86 - Ljt_ccb
    DD Lccb_87 - Ljt_ccb
    DD Lccb_88 - Ljt_ccb
    DD Lccb_89 - Ljt_ccb
    DD Lccb_8A - Ljt_ccb
    DD Lccb_8B - Ljt_ccb
    DD Lccb_8C - Ljt_ccb
    DD Lccb_8D - Ljt_ccb
    DD Lccb_8E - Ljt_ccb
    DD Lccb_8F - Ljt_ccb
    DD Lccb_90 - Ljt_ccb
    DD Lccb_91 - Ljt_ccb
    DD Lccb_92 - Ljt_ccb
    DD Lccb_93 - Ljt_ccb
    DD Lccb_94 - Ljt_ccb
    DD Lccb_95 - Ljt_ccb
    DD Lccb_96 - Ljt_ccb
    DD Lccb_97 - Ljt_ccb
    DD Lccb_98 - Ljt_ccb
    DD Lccb_99 - Ljt_ccb
    DD Lccb_9A - Ljt_ccb
    DD Lccb_9B - Ljt_ccb
    DD Lccb_9C - Ljt_ccb
    DD Lccb_9D - Ljt_ccb
    DD Lccb_9E - Ljt_ccb
    DD Lccb_9F - Ljt_ccb
    DD Lccb_A0 - Ljt_ccb
    DD Lccb_A1 - Ljt_ccb
    DD Lccb_A2 - Ljt_ccb
    DD Lccb_A3 - Ljt_ccb
    DD Lccb_A4 - Ljt_ccb
    DD Lccb_A5 - Ljt_ccb
    DD Lccb_A6 - Ljt_ccb
    DD Lccb_A7 - Ljt_ccb
    DD Lccb_A8 - Ljt_ccb
    DD Lccb_A9 - Ljt_ccb
    DD Lccb_AA - Ljt_ccb
    DD Lccb_AB - Ljt_ccb
    DD Lccb_AC - Ljt_ccb
    DD Lccb_AD - Ljt_ccb
    DD Lccb_AE - Ljt_ccb
    DD Lccb_AF - Ljt_ccb
    DD Lccb_B0 - Ljt_ccb
    DD Lccb_B1 - Ljt_ccb
    DD Lccb_B2 - Ljt_ccb
    DD Lccb_B3 - Ljt_ccb
    DD Lccb_B4 - Ljt_ccb
    DD Lccb_B5 - Ljt_ccb
    DD Lccb_B6 - Ljt_ccb
    DD Lccb_B7 - Ljt_ccb
    DD Lccb_B8 - Ljt_ccb
    DD Lccb_B9 - Ljt_ccb
    DD Lccb_BA - Ljt_ccb
    DD Lccb_BB - Ljt_ccb
    DD Lccb_BC - Ljt_ccb
    DD Lccb_BD - Ljt_ccb
    DD Lccb_BE - Ljt_ccb
    DD Lccb_BF - Ljt_ccb
    DD Lccb_C0 - Ljt_ccb
    DD Lccb_C1 - Ljt_ccb
    DD Lccb_C2 - Ljt_ccb
    DD Lccb_C3 - Ljt_ccb
    DD Lccb_C4 - Ljt_ccb
    DD Lccb_C5 - Ljt_ccb
    DD Lccb_C6 - Ljt_ccb
    DD Lccb_C7 - Ljt_ccb
    DD Lccb_C8 - Ljt_ccb
    DD Lccb_C9 - Ljt_ccb
    DD Lccb_CA - Ljt_ccb
    DD Lccb_CB - Ljt_ccb
    DD Lccb_CC - Ljt_ccb
    DD Lccb_CD - Ljt_ccb
    DD Lccb_CE - Ljt_ccb
    DD Lccb_CF - Ljt_ccb
    DD Lccb_D0 - Ljt_ccb
    DD Lccb_D1 - Ljt_ccb
    DD Lccb_D2 - Ljt_ccb
    DD Lccb_D3 - Ljt_ccb
    DD Lccb_D4 - Ljt_ccb
    DD Lccb_D5 - Ljt_ccb
    DD Lccb_D6 - Ljt_ccb
    DD Lccb_D7 - Ljt_ccb
    DD Lccb_D8 - Ljt_ccb
    DD Lccb_D9 - Ljt_ccb
    DD Lccb_DA - Ljt_ccb
    DD Lccb_DB - Ljt_ccb
    DD Lccb_DC - Ljt_ccb
    DD Lccb_DD - Ljt_ccb
    DD Lccb_DE - Ljt_ccb
    DD Lccb_DF - Ljt_ccb
    DD Lccb_E0 - Ljt_ccb
    DD Lccb_E1 - Ljt_ccb
    DD Lccb_E2 - Ljt_ccb
    DD Lccb_E3 - Ljt_ccb
    DD Lccb_E4 - Ljt_ccb
    DD Lccb_E5 - Ljt_ccb
    DD Lccb_E6 - Ljt_ccb
    DD Lccb_E7 - Ljt_ccb
    DD Lccb_E8 - Ljt_ccb
    DD Lccb_E9 - Ljt_ccb
    DD Lccb_EA - Ljt_ccb
    DD Lccb_EB - Ljt_ccb
    DD Lccb_EC - Ljt_ccb
    DD Lccb_ED - Ljt_ccb
    DD Lccb_EE - Ljt_ccb
    DD Lccb_EF - Ljt_ccb
    DD Lccb_F0 - Ljt_ccb
    DD Lccb_F1 - Ljt_ccb
    DD Lccb_F2 - Ljt_ccb
    DD Lccb_F3 - Ljt_ccb
    DD Lccb_F4 - Ljt_ccb
    DD Lccb_F5 - Ljt_ccb
    DD Lccb_F6 - Ljt_ccb
    DD Lccb_F7 - Ljt_ccb
    DD Lccb_F8 - Ljt_ccb
    DD Lccb_F9 - Ljt_ccb
    DD Lccb_FA - Ljt_ccb
    DD Lccb_FB - Ljt_ccb
    DD Lccb_FC - Ljt_ccb
    DD Lccb_FD - Ljt_ccb
    DD Lccb_FE - Ljt_ccb
    DD Lccb_FF - Ljt_ccb

gbc_cpu_run ENDP

END
