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
    mov r13, qword ptr [r15+572624]
    jmp Lnext
Lrd_slow:
    cmp esi, 65408
    jb Lrs1
    cmp esi, 65535
    je Lrs2
    mov rdi, qword ptr [r15+572576]
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
    mov rdi, qword ptr [r15+572568]
    ret
Lrs_ly:
    cmp byte ptr [r15+572675], 0
    jne Lrs2
    lea rdi, [r15+572681]
    sub rdi, rsi
    ret
Lrs_st:
    cmp byte ptr [r15+572675], 0
    jne Lrs2
    lea rdi, [r15+572680]
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
    cmp byte ptr [r15+572675], 0
    jne L1
    mov qword ptr [r15+40], r14
    movzx edi, word ptr [r15+572672]
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
    mov byte ptr [r15+572676], al
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
    mov r13, qword ptr [r15+572624]
    lea rdi, [r15+572676]
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
    mov rcx, qword ptr [r15+572576]
    mov byte ptr [rcx+rsi], al
    jmp Lws8
Lws1:
    cmp esi, 65024
    jb Lws2
    cmp esi, 65184
    jae Lws9
    mov rcx, qword ptr [r15+572568]
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
    mov rcx, qword ptr [r15+rcx*8+572432]
    test rcx, rcx
    jz Lws9
    mov edx, esi
    and edx, 8191
    mov rdi, qword ptr [r15+572584]
    cmp byte ptr [rdi+rdx], 0
    jne Lws9
    mov byte ptr [rcx+rsi], al
Lws8:
    pop rdx
    pop rcx
    pop rax
    ret
Lws_v:
    cmp byte ptr [r15+572678], 0
    je Lws9
    mov rcx, qword ptr [r15+572632]
    mov rdx, qword ptr [r15+572648]
    cmp esi, 39936
    jb Lws_v1
    mov rcx, qword ptr [r15+572640]
    mov rdx, qword ptr [r15+572656]
Lws_v1:
    mov byte ptr [rcx+rsi], al
    test rdx, rdx
    jz Lws8
    cmp esi, dword ptr [r15+572664]
    jb Lws8
    cmp esi, dword ptr [r15+572668]
    jae Lws8
    mov byte ptr [rdx+rsi], al
    jmp Lws8
Lws_m:
    cmp byte ptr [r15+572679], 0
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
    mov qword ptr [r15+572336], rcx
    mov qword ptr [r15+572344], rcx
    mov qword ptr [r15+572352], rcx
    mov qword ptr [r15+572360], rcx
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
    cmp byte ptr [r15+572675], 0
    jne L2
    mov qword ptr [r15+40], r14
    movzx edi, word ptr [r15+572672]
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
    mov r13, qword ptr [r15+572624]
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
    cmp byte ptr [r15+572675], 0
    jne L3
    mov qword ptr [r15+40], r14
    movzx edi, word ptr [r15+572672]
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
    mov r13, qword ptr [r15+572624]
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
    cmp byte ptr [r15+572675], 0
    jne L4
    mov qword ptr [r15+40], r14
    movzx edi, word ptr [r15+572672]
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
    mov r13, qword ptr [r15+572624]
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
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz Lid_ret
    cmp dword ptr [rdi+rbp], 0FC28A77Eh
    jne Lid_ret
    mov esi, dword ptr [r15+rbp+498572]
    and esi, 197379
    jnz Lid_ret
    mov esi, ebx
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jnz Lid_m
    cmp ebx, 65408
    jb Lid_ret
    cmp ebx, 65535
    je Lid_ret
    mov rdi, qword ptr [r15+572576]
Lid_m:
    cmp byte ptr [rdi+rbx], 0
    jne Lid_ret
    mov rax, qword ptr [r15+572600]
    mov rsi, qword ptr [r15+572616]
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
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz Lcp_ret
    mov rsi, 0F820B0790B13122Ah
    cmp qword ptr [rdi+rbp], rsi
    jne Lcp_ret
    mov rsi, qword ptr [r15+rbp+498572]
    mov rdi, 0003030303030303h
    test rsi, rdi
    jnz Lcp_ret
    push rax
    push rdx
    mov rax, qword ptr [r15+572600]
    mov rsi, qword ptr [r15+572616]
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
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz Lcp_end
    movzx eax, byte ptr [rdi+rbx]
    mov esi, edx
    shr esi, 8
    mov rdi, qword ptr [r15+rsi*8+574248]
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
    cmp r14, qword ptr [r15+572616]
    jae Lexit_done
    cmp byte ptr [r15+572674], 0
    jne Lexit_more
    test byte ptr [r15+rbp+498572], 1
    jnz Lexit_more
    cmp ebp, dword ptr [r15+572688]
    jne Lst1
    cmp r9d, dword ptr [r15+572692]
    je Lexit_done
Lst1:
    dec r12
    js Lexit_budget
    cmp r14, qword ptr [r15+572608]
    jb Lfast_fetch
Lcareful_fetch:
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L5
L6:
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
Lfast_fetch:
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
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
    cmp byte ptr [r15+572675], 0
    jne L11
    mov qword ptr [r15+40], r14
    movzx edi, word ptr [r15+572672]
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
    cmp byte ptr [r15+572675], 0
    jne L12
    mov qword ptr [r15+40], r14
    movzx edi, word ptr [r15+572672]
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
    cmp byte ptr [r15+572675], 0
    jne L13
    mov qword ptr [r15+40], r14
    movzx edi, word ptr [r15+572672]
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
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
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L16
L17:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
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
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L22
    mov byte ptr [rdi+rsi], al
L23:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
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
    movzx edi, byte ptr [r15+rdi+573224]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
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
    movzx edi, byte ptr [r15+rdi+573480]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
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
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L32
L33:
    mov ch, byte ptr [rdi+rsi]
    inc bp
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
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
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L38
L39:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
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
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L42
    mov byte ptr [rdi+rsi], r10b
L43:
    lea esi, [r11+1]
    and esi, 65535
    mov r10d, r9d
    shr r10d, 8
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L44
L45:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L46
    mov byte ptr [rdi+rsi], r10b
L47:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
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
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L52
L53:
    mov al, byte ptr [rdi+rsi]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
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
    movzx edi, byte ptr [r15+rdi+573224]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
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
    movzx edi, byte ptr [r15+rdi+573480]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
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
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L62
L63:
    mov cl, byte ptr [rdi+rsi]
    inc bp
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
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
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L68
L69:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
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
    cmp byte ptr [r15+572675], 0
    jne L70
    mov qword ptr [r15+40], r14
    movzx edi, word ptr [r15+572672]
    add edi, r14d
    mov word ptr [r15+65858], di
L70:
    sub rsp, 32
    mov rcx, r15
    mov edx, 16
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
    mov r13, qword ptr [r15+572624]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L71
L72:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L68:
    call Lrd_slow
    jmp L69
L71:
    mov esi, ebp
    call Lrd_slow
    jmp L72
    ALIGN 16
Lf_11:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L73
L74:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L75
L76:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    mov edx, r11d
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L77
L78:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L73:
    call Lrd_slow
    jmp L74
L75:
    call Lrd_slow
    jmp L76
L77:
    mov esi, ebp
    call Lrd_slow
    jmp L78
    ALIGN 16
Lf_12:
    mov esi, edx
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L79
    mov byte ptr [rdi+rsi], al
L80:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L81
L82:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L79:
    mov byte ptr [rsp+40], al
    call Lwr_slow
    jmp L80
L81:
    mov esi, ebp
    call Lrd_slow
    jmp L82
    ALIGN 16
Lf_13:
    inc dx
    add r14, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L83
L84:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L83:
    mov esi, ebp
    call Lrd_slow
    jmp L84
    ALIGN 16
Lf_14:
    inc dh
    movzx edi, dh
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573224]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L85
L86:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L85:
    mov esi, ebp
    call Lrd_slow
    jmp L86
    ALIGN 16
Lf_15:
    dec dh
    movzx edi, dh
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573480]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L87
L88:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L87:
    mov esi, ebp
    call Lrd_slow
    jmp L88
    ALIGN 16
Lf_16:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L89
L90:
    mov dh, byte ptr [rdi+rsi]
    inc bp
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L91
L92:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L89:
    call Lrd_slow
    jmp L90
L91:
    mov esi, ebp
    call Lrd_slow
    jmp L92
    ALIGN 16
Lf_17:
    bt r8d, 4
    rcl al, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L93
L94:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L93:
    mov esi, ebp
    call Lrd_slow
    jmp L94
    ALIGN 16
Lf_18:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L95
L96:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    movsx r10d, r10b
    add ebp, r10d
    and ebp, 65535
    add r14, 4
L97:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L98
L99:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L95:
    call Lrd_slow
    jmp L96
L98:
    mov esi, ebp
    call Lrd_slow
    jmp L99
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L100
L101:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L100:
    mov esi, ebp
    call Lrd_slow
    jmp L101
    ALIGN 16
Lf_1A:
    mov esi, edx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L102
L103:
    mov al, byte ptr [rdi+rsi]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L104
L105:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L102:
    call Lrd_slow
    jmp L103
L104:
    mov esi, ebp
    call Lrd_slow
    jmp L105
    ALIGN 16
Lf_1B:
    dec dx
    add r14, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L106
L107:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L106:
    mov esi, ebp
    call Lrd_slow
    jmp L107
    ALIGN 16
Lf_1C:
    inc dl
    movzx edi, dl
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573224]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L108
L109:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L108:
    mov esi, ebp
    call Lrd_slow
    jmp L109
    ALIGN 16
Lf_1D:
    dec dl
    movzx edi, dl
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573480]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L110
L111:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L110:
    mov esi, ebp
    call Lrd_slow
    jmp L111
    ALIGN 16
Lf_1E:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L112
L113:
    mov dl, byte ptr [rdi+rsi]
    inc bp
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L114
L115:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L112:
    call Lrd_slow
    jmp L113
L114:
    mov esi, ebp
    call Lrd_slow
    jmp L115
    ALIGN 16
Lf_1F:
    bt r8d, 4
    rcr al, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L116
L117:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L116:
    mov esi, ebp
    call Lrd_slow
    jmp L117
    ALIGN 16
Lf_20:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L118
L119:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    test r8b, 128
    jnz L120
    movsx r10d, r10b
    add ebp, r10d
    and ebp, 65535
    add r14, 4
    cmp r10d, -8
    je L121
L122:
L120:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L123
L124:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L118:
    call Lrd_slow
    jmp L119
L121:
    call Lcopy
    jmp L122
L123:
    mov esi, ebp
    call Lrd_slow
    jmp L124
    ALIGN 16
Lf_21:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L125
L126:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L127
L128:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    mov ebx, r11d
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L129
L130:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L125:
    call Lrd_slow
    jmp L126
L127:
    call Lrd_slow
    jmp L128
L129:
    mov esi, ebp
    call Lrd_slow
    jmp L130
    ALIGN 16
Lf_22:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L131
    mov byte ptr [rdi+rsi], al
L132:
    lea ebx, [rsi+1]
    and ebx, 65535
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L133
L134:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L131:
    mov byte ptr [rsp+40], al
    call Lwr_slow
    jmp L132
L133:
    mov esi, ebp
    call Lrd_slow
    jmp L134
    ALIGN 16
Lf_23:
    inc bx
    add r14, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L135
L136:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L135:
    mov esi, ebp
    call Lrd_slow
    jmp L136
    ALIGN 16
Lf_24:
    inc bh
    movzx edi, bh
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573224]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L137
L138:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L137:
    mov esi, ebp
    call Lrd_slow
    jmp L138
    ALIGN 16
Lf_25:
    dec bh
    movzx edi, bh
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573480]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L139
L140:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L139:
    mov esi, ebp
    call Lrd_slow
    jmp L140
    ALIGN 16
Lf_26:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L141
L142:
    mov bh, byte ptr [rdi+rsi]
    inc bp
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L143
L144:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L141:
    call Lrd_slow
    jmp L142
L143:
    mov esi, ebp
    call Lrd_slow
    jmp L144
    ALIGN 16
Lf_27:
    movzx edi, al
    mov esi, r8d
    and esi, 16
    test r8b, 64
    jz L145
    test r8b, 32
    jz L146
    sub edi, 6
L146:
    test esi, esi
    jz L150
    sub edi, 96
    jmp L150
L145:
    test esi, esi
    jnz L147
    cmp edi, 153
    jbe L148
L147:
    add edi, 96
    mov esi, 16
L148:
    test r8b, 32
    jnz L149
    mov r10d, edi
    and r10d, 15
    cmp r10d, 9
    jbe L150
L149:
    add edi, 6
L150:
    mov eax, edi
    and r8d, 64
    or r8d, esi
    test al, al
    jnz L151
    or r8d, 128
L151:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L152
L153:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L152:
    mov esi, ebp
    call Lrd_slow
    jmp L153
    ALIGN 16
Lf_28:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L154
L155:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    test r8b, 128
    jz L156
    movsx r10d, r10b
    add ebp, r10d
    and ebp, 65535
    add r14, 4
    cmp r10d, -4
    je L157
L158:
L156:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L159
L160:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L154:
    call Lrd_slow
    jmp L155
L157:
    call Lidle
    jmp L158
L159:
    mov esi, ebp
    call Lrd_slow
    jmp L160
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L161
L162:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L161:
    mov esi, ebp
    call Lrd_slow
    jmp L162
    ALIGN 16
Lf_2A:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L163
L164:
    mov al, byte ptr [rdi+rsi]
    lea ebx, [rsi+1]
    and ebx, 65535
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L165
L166:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L163:
    call Lrd_slow
    jmp L164
L165:
    mov esi, ebp
    call Lrd_slow
    jmp L166
    ALIGN 16
Lf_2B:
    dec bx
    add r14, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L167
L168:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L167:
    mov esi, ebp
    call Lrd_slow
    jmp L168
    ALIGN 16
Lf_2C:
    inc bl
    movzx edi, bl
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573224]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L169
L170:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L169:
    mov esi, ebp
    call Lrd_slow
    jmp L170
    ALIGN 16
Lf_2D:
    dec bl
    movzx edi, bl
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573480]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L171
L172:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L171:
    mov esi, ebp
    call Lrd_slow
    jmp L172
    ALIGN 16
Lf_2E:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L173
L174:
    mov bl, byte ptr [rdi+rsi]
    inc bp
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L175
L176:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L173:
    call Lrd_slow
    jmp L174
L175:
    mov esi, ebp
    call Lrd_slow
    jmp L176
    ALIGN 16
Lf_2F:
    not al
    or r8d, 96
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L177
L178:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L177:
    mov esi, ebp
    call Lrd_slow
    jmp L178
    ALIGN 16
Lf_30:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L179
L180:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    test r8b, 16
    jnz L181
    movsx r10d, r10b
    add ebp, r10d
    and ebp, 65535
    add r14, 4
L181:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L182
L183:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L179:
    call Lrd_slow
    jmp L180
L182:
    mov esi, ebp
    call Lrd_slow
    jmp L183
    ALIGN 16
Lf_31:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L184
L185:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L186
L187:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    mov r9d, r11d
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L188
L189:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L184:
    call Lrd_slow
    jmp L185
L186:
    call Lrd_slow
    jmp L187
L188:
    mov esi, ebp
    call Lrd_slow
    jmp L189
    ALIGN 16
Lf_32:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L190
    mov byte ptr [rdi+rsi], al
L191:
    lea ebx, [rsi-1]
    and ebx, 65535
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L192
L193:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L190:
    mov byte ptr [rsp+40], al
    call Lwr_slow
    jmp L191
L192:
    mov esi, ebp
    call Lrd_slow
    jmp L193
    ALIGN 16
Lf_33:
    inc r9w
    add r14, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L194
L195:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L194:
    mov esi, ebp
    call Lrd_slow
    jmp L195
    ALIGN 16
Lf_34:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L196
L197:
    movzx r10d, byte ptr [rdi+rsi]
    inc r10b
    movzx edi, r10b
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573224]
    or r8d, edi
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L198
    mov byte ptr [rdi+rsi], r10b
L199:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L200
L201:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L196:
    call Lrd_slow
    jmp L197
L198:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L199
L200:
    mov esi, ebp
    call Lrd_slow
    jmp L201
    ALIGN 16
Lf_35:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L202
L203:
    movzx r10d, byte ptr [rdi+rsi]
    dec r10b
    movzx edi, r10b
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573480]
    or r8d, edi
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L204
    mov byte ptr [rdi+rsi], r10b
L205:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L206
L207:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L202:
    call Lrd_slow
    jmp L203
L204:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L205
L206:
    mov esi, ebp
    call Lrd_slow
    jmp L207
    ALIGN 16
Lf_36:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L208
L209:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L210
    mov byte ptr [rdi+rsi], r10b
L211:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L212
L213:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L208:
    call Lrd_slow
    jmp L209
L210:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L211
L212:
    mov esi, ebp
    call Lrd_slow
    jmp L213
    ALIGN 16
Lf_37:
    and r8d, 128
    or r8d, 16
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L214
L215:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L214:
    mov esi, ebp
    call Lrd_slow
    jmp L215
    ALIGN 16
Lf_38:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L216
L217:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    test r8b, 16
    jz L218
    movsx r10d, r10b
    add ebp, r10d
    and ebp, 65535
    add r14, 4
L218:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L219
L220:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L216:
    call Lrd_slow
    jmp L217
L219:
    mov esi, ebp
    call Lrd_slow
    jmp L220
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L221
L222:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L221:
    mov esi, ebp
    call Lrd_slow
    jmp L222
    ALIGN 16
Lf_3A:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L223
L224:
    mov al, byte ptr [rdi+rsi]
    lea ebx, [rsi-1]
    and ebx, 65535
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L225
L226:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L223:
    call Lrd_slow
    jmp L224
L225:
    mov esi, ebp
    call Lrd_slow
    jmp L226
    ALIGN 16
Lf_3B:
    dec r9w
    add r14, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L227
L228:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L227:
    mov esi, ebp
    call Lrd_slow
    jmp L228
    ALIGN 16
Lf_3C:
    inc al
    movzx edi, al
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573224]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L229
L230:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L229:
    mov esi, ebp
    call Lrd_slow
    jmp L230
    ALIGN 16
Lf_3D:
    dec al
    movzx edi, al
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573480]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L231
L232:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L231:
    mov esi, ebp
    call Lrd_slow
    jmp L232
    ALIGN 16
Lf_3E:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L233
L234:
    mov al, byte ptr [rdi+rsi]
    inc bp
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L235
L236:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L233:
    call Lrd_slow
    jmp L234
L235:
    mov esi, ebp
    call Lrd_slow
    jmp L236
    ALIGN 16
Lf_3F:
    and r8d, 144
    xor r8d, 16
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L237
L238:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L237:
    mov esi, ebp
    call Lrd_slow
    jmp L238
    ALIGN 16
Lf_40:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L239
L240:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L239:
    mov esi, ebp
    call Lrd_slow
    jmp L240
    ALIGN 16
Lf_41:
    mov ch, cl
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L241
L242:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L241:
    mov esi, ebp
    call Lrd_slow
    jmp L242
    ALIGN 16
Lf_42:
    mov ch, dh
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L243
L244:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L243:
    mov esi, ebp
    call Lrd_slow
    jmp L244
    ALIGN 16
Lf_43:
    mov ch, dl
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L245
L246:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L245:
    mov esi, ebp
    call Lrd_slow
    jmp L246
    ALIGN 16
Lf_44:
    mov ch, bh
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L247
L248:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L247:
    mov esi, ebp
    call Lrd_slow
    jmp L248
    ALIGN 16
Lf_45:
    mov ch, bl
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L249
L250:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L249:
    mov esi, ebp
    call Lrd_slow
    jmp L250
    ALIGN 16
Lf_46:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L251
L252:
    mov ch, byte ptr [rdi+rsi]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L253
L254:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L251:
    call Lrd_slow
    jmp L252
L253:
    mov esi, ebp
    call Lrd_slow
    jmp L254
    ALIGN 16
Lf_47:
    mov ch, al
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L255
L256:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L255:
    mov esi, ebp
    call Lrd_slow
    jmp L256
    ALIGN 16
Lf_48:
    mov cl, ch
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L257
L258:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L257:
    mov esi, ebp
    call Lrd_slow
    jmp L258
    ALIGN 16
Lf_49:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L259
L260:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L259:
    mov esi, ebp
    call Lrd_slow
    jmp L260
    ALIGN 16
Lf_4A:
    mov cl, dh
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L261
L262:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L261:
    mov esi, ebp
    call Lrd_slow
    jmp L262
    ALIGN 16
Lf_4B:
    mov cl, dl
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L263
L264:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L263:
    mov esi, ebp
    call Lrd_slow
    jmp L264
    ALIGN 16
Lf_4C:
    mov cl, bh
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L265
L266:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L265:
    mov esi, ebp
    call Lrd_slow
    jmp L266
    ALIGN 16
Lf_4D:
    mov cl, bl
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L267
L268:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L267:
    mov esi, ebp
    call Lrd_slow
    jmp L268
    ALIGN 16
Lf_4E:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L269
L270:
    mov cl, byte ptr [rdi+rsi]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L271
L272:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L269:
    call Lrd_slow
    jmp L270
L271:
    mov esi, ebp
    call Lrd_slow
    jmp L272
    ALIGN 16
Lf_4F:
    mov cl, al
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L273
L274:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L273:
    mov esi, ebp
    call Lrd_slow
    jmp L274
    ALIGN 16
Lf_50:
    mov dh, ch
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L275
L276:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L275:
    mov esi, ebp
    call Lrd_slow
    jmp L276
    ALIGN 16
Lf_51:
    mov dh, cl
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L277
L278:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L277:
    mov esi, ebp
    call Lrd_slow
    jmp L278
    ALIGN 16
Lf_52:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L279
L280:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L279:
    mov esi, ebp
    call Lrd_slow
    jmp L280
    ALIGN 16
Lf_53:
    mov dh, dl
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L281
L282:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L281:
    mov esi, ebp
    call Lrd_slow
    jmp L282
    ALIGN 16
Lf_54:
    mov dh, bh
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L283
L284:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L283:
    mov esi, ebp
    call Lrd_slow
    jmp L284
    ALIGN 16
Lf_55:
    mov dh, bl
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L285
L286:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L285:
    mov esi, ebp
    call Lrd_slow
    jmp L286
    ALIGN 16
Lf_56:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L287
L288:
    mov dh, byte ptr [rdi+rsi]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L289
L290:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L287:
    call Lrd_slow
    jmp L288
L289:
    mov esi, ebp
    call Lrd_slow
    jmp L290
    ALIGN 16
Lf_57:
    mov dh, al
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L291
L292:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L291:
    mov esi, ebp
    call Lrd_slow
    jmp L292
    ALIGN 16
Lf_58:
    mov dl, ch
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L293
L294:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L293:
    mov esi, ebp
    call Lrd_slow
    jmp L294
    ALIGN 16
Lf_59:
    mov dl, cl
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L295
L296:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L295:
    mov esi, ebp
    call Lrd_slow
    jmp L296
    ALIGN 16
Lf_5A:
    mov dl, dh
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L297
L298:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L297:
    mov esi, ebp
    call Lrd_slow
    jmp L298
    ALIGN 16
Lf_5B:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L299
L300:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L299:
    mov esi, ebp
    call Lrd_slow
    jmp L300
    ALIGN 16
Lf_5C:
    mov dl, bh
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L301
L302:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L301:
    mov esi, ebp
    call Lrd_slow
    jmp L302
    ALIGN 16
Lf_5D:
    mov dl, bl
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L303
L304:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L303:
    mov esi, ebp
    call Lrd_slow
    jmp L304
    ALIGN 16
Lf_5E:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L305
L306:
    mov dl, byte ptr [rdi+rsi]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L307
L308:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L305:
    call Lrd_slow
    jmp L306
L307:
    mov esi, ebp
    call Lrd_slow
    jmp L308
    ALIGN 16
Lf_5F:
    mov dl, al
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L309
L310:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L309:
    mov esi, ebp
    call Lrd_slow
    jmp L310
    ALIGN 16
Lf_60:
    mov bh, ch
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L311
L312:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L311:
    mov esi, ebp
    call Lrd_slow
    jmp L312
    ALIGN 16
Lf_61:
    mov bh, cl
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L313
L314:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L313:
    mov esi, ebp
    call Lrd_slow
    jmp L314
    ALIGN 16
Lf_62:
    mov bh, dh
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L315
L316:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L315:
    mov esi, ebp
    call Lrd_slow
    jmp L316
    ALIGN 16
Lf_63:
    mov bh, dl
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L317
L318:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L317:
    mov esi, ebp
    call Lrd_slow
    jmp L318
    ALIGN 16
Lf_64:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L319
L320:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L319:
    mov esi, ebp
    call Lrd_slow
    jmp L320
    ALIGN 16
Lf_65:
    mov bh, bl
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L321
L322:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L321:
    mov esi, ebp
    call Lrd_slow
    jmp L322
    ALIGN 16
Lf_66:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L323
L324:
    mov bh, byte ptr [rdi+rsi]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L325
L326:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L323:
    call Lrd_slow
    jmp L324
L325:
    mov esi, ebp
    call Lrd_slow
    jmp L326
    ALIGN 16
Lf_67:
    mov bh, al
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L327
L328:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L327:
    mov esi, ebp
    call Lrd_slow
    jmp L328
    ALIGN 16
Lf_68:
    mov bl, ch
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L329
L330:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L329:
    mov esi, ebp
    call Lrd_slow
    jmp L330
    ALIGN 16
Lf_69:
    mov bl, cl
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L331
L332:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L331:
    mov esi, ebp
    call Lrd_slow
    jmp L332
    ALIGN 16
Lf_6A:
    mov bl, dh
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L333
L334:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L333:
    mov esi, ebp
    call Lrd_slow
    jmp L334
    ALIGN 16
Lf_6B:
    mov bl, dl
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L335
L336:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L335:
    mov esi, ebp
    call Lrd_slow
    jmp L336
    ALIGN 16
Lf_6C:
    mov bl, bh
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L337
L338:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L337:
    mov esi, ebp
    call Lrd_slow
    jmp L338
    ALIGN 16
Lf_6D:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L339
L340:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L339:
    mov esi, ebp
    call Lrd_slow
    jmp L340
    ALIGN 16
Lf_6E:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L341
L342:
    mov bl, byte ptr [rdi+rsi]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L343
L344:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L341:
    call Lrd_slow
    jmp L342
L343:
    mov esi, ebp
    call Lrd_slow
    jmp L344
    ALIGN 16
Lf_6F:
    mov bl, al
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L345
L346:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L345:
    mov esi, ebp
    call Lrd_slow
    jmp L346
    ALIGN 16
Lf_70:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L347
    mov byte ptr [rdi+rsi], ch
L348:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L349
L350:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L347:
    mov byte ptr [rsp+40], ch
    call Lwr_slow
    jmp L348
L349:
    mov esi, ebp
    call Lrd_slow
    jmp L350
    ALIGN 16
Lf_71:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L351
    mov byte ptr [rdi+rsi], cl
L352:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L353
L354:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L351:
    mov byte ptr [rsp+40], cl
    call Lwr_slow
    jmp L352
L353:
    mov esi, ebp
    call Lrd_slow
    jmp L354
    ALIGN 16
Lf_72:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L355
    mov byte ptr [rdi+rsi], dh
L356:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L357
L358:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L355:
    mov byte ptr [rsp+40], dh
    call Lwr_slow
    jmp L356
L357:
    mov esi, ebp
    call Lrd_slow
    jmp L358
    ALIGN 16
Lf_73:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L359
    mov byte ptr [rdi+rsi], dl
L360:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L361
L362:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L359:
    mov byte ptr [rsp+40], dl
    call Lwr_slow
    jmp L360
L361:
    mov esi, ebp
    call Lrd_slow
    jmp L362
    ALIGN 16
Lf_74:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L363
    mov byte ptr [rdi+rsi], bh
L364:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L365
L366:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L363:
    mov byte ptr [rsp+40], bh
    call Lwr_slow
    jmp L364
L365:
    mov esi, ebp
    call Lrd_slow
    jmp L366
    ALIGN 16
Lf_75:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L367
    mov byte ptr [rdi+rsi], bl
L368:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L369
L370:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L367:
    mov byte ptr [rsp+40], bl
    call Lwr_slow
    jmp L368
L369:
    mov esi, ebp
    call Lrd_slow
    jmp L370
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
    cmp byte ptr [r15+572675], 0
    jne L371
    mov qword ptr [r15+40], r14
    movzx edi, word ptr [r15+572672]
    add edi, r14d
    mov word ptr [r15+65858], di
L371:
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
    mov r13, qword ptr [r15+572624]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L372
L373:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L372:
    mov esi, ebp
    call Lrd_slow
    jmp L373
    ALIGN 16
Lf_77:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L374
    mov byte ptr [rdi+rsi], al
L375:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L376
L377:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L374:
    mov byte ptr [rsp+40], al
    call Lwr_slow
    jmp L375
L376:
    mov esi, ebp
    call Lrd_slow
    jmp L377
    ALIGN 16
Lf_78:
    mov al, ch
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L378
L379:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L378:
    mov esi, ebp
    call Lrd_slow
    jmp L379
    ALIGN 16
Lf_79:
    mov al, cl
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L380
L381:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L380:
    mov esi, ebp
    call Lrd_slow
    jmp L381
    ALIGN 16
Lf_7A:
    mov al, dh
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L382
L383:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L382:
    mov esi, ebp
    call Lrd_slow
    jmp L383
    ALIGN 16
Lf_7B:
    mov al, dl
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L384
L385:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L384:
    mov esi, ebp
    call Lrd_slow
    jmp L385
    ALIGN 16
Lf_7C:
    mov al, bh
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L386
L387:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L386:
    mov esi, ebp
    call Lrd_slow
    jmp L387
    ALIGN 16
Lf_7D:
    mov al, bl
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L388
L389:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L388:
    mov esi, ebp
    call Lrd_slow
    jmp L389
    ALIGN 16
Lf_7E:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L390
L391:
    mov al, byte ptr [rdi+rsi]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L392
L393:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L390:
    call Lrd_slow
    jmp L391
L392:
    mov esi, ebp
    call Lrd_slow
    jmp L393
    ALIGN 16
Lf_7F:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L394
L395:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L394:
    mov esi, ebp
    call Lrd_slow
    jmp L395
    ALIGN 16
Lf_80:
    add al, ch
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572712]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L396
L397:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L396:
    mov esi, ebp
    call Lrd_slow
    jmp L397
    ALIGN 16
Lf_81:
    add al, cl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572712]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L398
L399:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L398:
    mov esi, ebp
    call Lrd_slow
    jmp L399
    ALIGN 16
Lf_82:
    add al, dh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572712]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L400
L401:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L400:
    mov esi, ebp
    call Lrd_slow
    jmp L401
    ALIGN 16
Lf_83:
    add al, dl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572712]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L402
L403:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L402:
    mov esi, ebp
    call Lrd_slow
    jmp L403
    ALIGN 16
Lf_84:
    add al, bh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572712]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L404
L405:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L404:
    mov esi, ebp
    call Lrd_slow
    jmp L405
    ALIGN 16
Lf_85:
    add al, bl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572712]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L406
L407:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L406:
    mov esi, ebp
    call Lrd_slow
    jmp L407
    ALIGN 16
Lf_86:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L408
L409:
    movzx r10d, byte ptr [rdi+rsi]
    add al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572712]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L410
L411:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L408:
    call Lrd_slow
    jmp L409
L410:
    mov esi, ebp
    call Lrd_slow
    jmp L411
    ALIGN 16
Lf_87:
    add al, al
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572712]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L412
L413:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L412:
    mov esi, ebp
    call Lrd_slow
    jmp L413
    ALIGN 16
Lf_88:
    bt r8d, 4
    adc al, ch
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572712]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L414
L415:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L414:
    mov esi, ebp
    call Lrd_slow
    jmp L415
    ALIGN 16
Lf_89:
    bt r8d, 4
    adc al, cl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572712]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L416
L417:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L416:
    mov esi, ebp
    call Lrd_slow
    jmp L417
    ALIGN 16
Lf_8A:
    bt r8d, 4
    adc al, dh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572712]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L418
L419:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L418:
    mov esi, ebp
    call Lrd_slow
    jmp L419
    ALIGN 16
Lf_8B:
    bt r8d, 4
    adc al, dl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572712]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L420
L421:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L420:
    mov esi, ebp
    call Lrd_slow
    jmp L421
    ALIGN 16
Lf_8C:
    bt r8d, 4
    adc al, bh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572712]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L422
L423:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L422:
    mov esi, ebp
    call Lrd_slow
    jmp L423
    ALIGN 16
Lf_8D:
    bt r8d, 4
    adc al, bl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572712]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L424
L425:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L424:
    mov esi, ebp
    call Lrd_slow
    jmp L425
    ALIGN 16
Lf_8E:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L426
L427:
    movzx r10d, byte ptr [rdi+rsi]
    bt r8d, 4
    adc al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572712]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L428
L429:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L426:
    call Lrd_slow
    jmp L427
L428:
    mov esi, ebp
    call Lrd_slow
    jmp L429
    ALIGN 16
Lf_8F:
    bt r8d, 4
    adc al, al
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572712]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L430
L431:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L430:
    mov esi, ebp
    call Lrd_slow
    jmp L431
    ALIGN 16
Lf_90:
    sub al, ch
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L432
L433:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L432:
    mov esi, ebp
    call Lrd_slow
    jmp L433
    ALIGN 16
Lf_91:
    sub al, cl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L434
L435:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L434:
    mov esi, ebp
    call Lrd_slow
    jmp L435
    ALIGN 16
Lf_92:
    sub al, dh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L436
L437:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L436:
    mov esi, ebp
    call Lrd_slow
    jmp L437
    ALIGN 16
Lf_93:
    sub al, dl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L438
L439:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L438:
    mov esi, ebp
    call Lrd_slow
    jmp L439
    ALIGN 16
Lf_94:
    sub al, bh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L440
L441:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L440:
    mov esi, ebp
    call Lrd_slow
    jmp L441
    ALIGN 16
Lf_95:
    sub al, bl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L442
L443:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L442:
    mov esi, ebp
    call Lrd_slow
    jmp L443
    ALIGN 16
Lf_96:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L444
L445:
    movzx r10d, byte ptr [rdi+rsi]
    sub al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L446
L447:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L444:
    call Lrd_slow
    jmp L445
L446:
    mov esi, ebp
    call Lrd_slow
    jmp L447
    ALIGN 16
Lf_97:
    sub al, al
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L448
L449:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L448:
    mov esi, ebp
    call Lrd_slow
    jmp L449
    ALIGN 16
Lf_98:
    bt r8d, 4
    sbb al, ch
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L450
L451:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L450:
    mov esi, ebp
    call Lrd_slow
    jmp L451
    ALIGN 16
Lf_99:
    bt r8d, 4
    sbb al, cl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L452
L453:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L452:
    mov esi, ebp
    call Lrd_slow
    jmp L453
    ALIGN 16
Lf_9A:
    bt r8d, 4
    sbb al, dh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L454
L455:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L454:
    mov esi, ebp
    call Lrd_slow
    jmp L455
    ALIGN 16
Lf_9B:
    bt r8d, 4
    sbb al, dl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L456
L457:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L456:
    mov esi, ebp
    call Lrd_slow
    jmp L457
    ALIGN 16
Lf_9C:
    bt r8d, 4
    sbb al, bh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L458
L459:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L458:
    mov esi, ebp
    call Lrd_slow
    jmp L459
    ALIGN 16
Lf_9D:
    bt r8d, 4
    sbb al, bl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L460
L461:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L460:
    mov esi, ebp
    call Lrd_slow
    jmp L461
    ALIGN 16
Lf_9E:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L462
L463:
    movzx r10d, byte ptr [rdi+rsi]
    bt r8d, 4
    sbb al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L464
L465:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L462:
    call Lrd_slow
    jmp L463
L464:
    mov esi, ebp
    call Lrd_slow
    jmp L465
    ALIGN 16
Lf_9F:
    bt r8d, 4
    sbb al, al
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L466
L467:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L466:
    mov esi, ebp
    call Lrd_slow
    jmp L467
    ALIGN 16
Lf_A0:
    and al, ch
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573992]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L468
L469:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L468:
    mov esi, ebp
    call Lrd_slow
    jmp L469
    ALIGN 16
Lf_A1:
    and al, cl
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573992]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L470
L471:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L470:
    mov esi, ebp
    call Lrd_slow
    jmp L471
    ALIGN 16
Lf_A2:
    and al, dh
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573992]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L472
L473:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L472:
    mov esi, ebp
    call Lrd_slow
    jmp L473
    ALIGN 16
Lf_A3:
    and al, dl
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573992]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L474
L475:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L474:
    mov esi, ebp
    call Lrd_slow
    jmp L475
    ALIGN 16
Lf_A4:
    and al, bh
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573992]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L476
L477:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L476:
    mov esi, ebp
    call Lrd_slow
    jmp L477
    ALIGN 16
Lf_A5:
    and al, bl
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573992]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L478
L479:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L478:
    mov esi, ebp
    call Lrd_slow
    jmp L479
    ALIGN 16
Lf_A6:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L480
L481:
    movzx r10d, byte ptr [rdi+rsi]
    and al, r10b
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573992]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L482
L483:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L480:
    call Lrd_slow
    jmp L481
L482:
    mov esi, ebp
    call Lrd_slow
    jmp L483
    ALIGN 16
Lf_A7:
    and al, al
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573992]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L484
L485:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L484:
    mov esi, ebp
    call Lrd_slow
    jmp L485
    ALIGN 16
Lf_A8:
    xor al, ch
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573736]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L486
L487:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L486:
    mov esi, ebp
    call Lrd_slow
    jmp L487
    ALIGN 16
Lf_A9:
    xor al, cl
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573736]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L488
L489:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L488:
    mov esi, ebp
    call Lrd_slow
    jmp L489
    ALIGN 16
Lf_AA:
    xor al, dh
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573736]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L490
L491:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L490:
    mov esi, ebp
    call Lrd_slow
    jmp L491
    ALIGN 16
Lf_AB:
    xor al, dl
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573736]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L492
L493:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L492:
    mov esi, ebp
    call Lrd_slow
    jmp L493
    ALIGN 16
Lf_AC:
    xor al, bh
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573736]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L494
L495:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L494:
    mov esi, ebp
    call Lrd_slow
    jmp L495
    ALIGN 16
Lf_AD:
    xor al, bl
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573736]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L496
L497:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L496:
    mov esi, ebp
    call Lrd_slow
    jmp L497
    ALIGN 16
Lf_AE:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L498
L499:
    movzx r10d, byte ptr [rdi+rsi]
    xor al, r10b
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573736]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L500
L501:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L498:
    call Lrd_slow
    jmp L499
L500:
    mov esi, ebp
    call Lrd_slow
    jmp L501
    ALIGN 16
Lf_AF:
    xor al, al
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573736]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L502
L503:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L502:
    mov esi, ebp
    call Lrd_slow
    jmp L503
    ALIGN 16
Lf_B0:
    or al, ch
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573736]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L504
L505:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L504:
    mov esi, ebp
    call Lrd_slow
    jmp L505
    ALIGN 16
Lf_B1:
    or al, cl
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573736]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L506
L507:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L506:
    mov esi, ebp
    call Lrd_slow
    jmp L507
    ALIGN 16
Lf_B2:
    or al, dh
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573736]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L508
L509:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L508:
    mov esi, ebp
    call Lrd_slow
    jmp L509
    ALIGN 16
Lf_B3:
    or al, dl
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573736]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L510
L511:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L510:
    mov esi, ebp
    call Lrd_slow
    jmp L511
    ALIGN 16
Lf_B4:
    or al, bh
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573736]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L512
L513:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L512:
    mov esi, ebp
    call Lrd_slow
    jmp L513
    ALIGN 16
Lf_B5:
    or al, bl
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573736]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L514
L515:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L514:
    mov esi, ebp
    call Lrd_slow
    jmp L515
    ALIGN 16
Lf_B6:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L516
L517:
    movzx r10d, byte ptr [rdi+rsi]
    or al, r10b
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573736]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L518
L519:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L516:
    call Lrd_slow
    jmp L517
L518:
    mov esi, ebp
    call Lrd_slow
    jmp L519
    ALIGN 16
Lf_B7:
    or al, al
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573736]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L520
L521:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L520:
    mov esi, ebp
    call Lrd_slow
    jmp L521
    ALIGN 16
Lf_B8:
    cmp al, ch
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L522
L523:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L522:
    mov esi, ebp
    call Lrd_slow
    jmp L523
    ALIGN 16
Lf_B9:
    cmp al, cl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L524
L525:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L524:
    mov esi, ebp
    call Lrd_slow
    jmp L525
    ALIGN 16
Lf_BA:
    cmp al, dh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L526
L527:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L526:
    mov esi, ebp
    call Lrd_slow
    jmp L527
    ALIGN 16
Lf_BB:
    cmp al, dl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L528
L529:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L528:
    mov esi, ebp
    call Lrd_slow
    jmp L529
    ALIGN 16
Lf_BC:
    cmp al, bh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L530
L531:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L530:
    mov esi, ebp
    call Lrd_slow
    jmp L531
    ALIGN 16
Lf_BD:
    cmp al, bl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L532
L533:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L532:
    mov esi, ebp
    call Lrd_slow
    jmp L533
    ALIGN 16
Lf_BE:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L534
L535:
    movzx r10d, byte ptr [rdi+rsi]
    cmp al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L536
L537:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L534:
    call Lrd_slow
    jmp L535
L536:
    mov esi, ebp
    call Lrd_slow
    jmp L537
    ALIGN 16
Lf_BF:
    cmp al, al
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L538
L539:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L538:
    mov esi, ebp
    call Lrd_slow
    jmp L539
    ALIGN 16
Lf_C0:
    add r14, 4
    test r8b, 128
    jnz L540
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L541
L542:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L543
L544:
    movzx r11d, byte ptr [rdi+rsi]
    inc r9w
    shl r11d, 8
    or r11d, r10d
    mov ebp, r11d
    add r14, 4
L540:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L545
L546:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L541:
    call Lrd_slow
    jmp L542
L543:
    call Lrd_slow
    jmp L544
L545:
    mov esi, ebp
    call Lrd_slow
    jmp L546
    ALIGN 16
Lf_C1:
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L547
L548:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L549
L550:
    movzx r11d, byte ptr [rdi+rsi]
    inc r9w
    shl r11d, 8
    or r11d, r10d
    mov ecx, r11d
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L551
L552:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L547:
    call Lrd_slow
    jmp L548
L549:
    call Lrd_slow
    jmp L550
L551:
    mov esi, ebp
    call Lrd_slow
    jmp L552
    ALIGN 16
Lf_C2:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L553
L554:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L555
L556:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    test r8b, 128
    jnz L557
    mov ebp, r11d
    add r14, 4
L557:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L558
L559:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L553:
    call Lrd_slow
    jmp L554
L555:
    call Lrd_slow
    jmp L556
L558:
    mov esi, ebp
    call Lrd_slow
    jmp L559
    ALIGN 16
Lf_C3:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L560
L561:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L562
L563:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    mov ebp, r11d
    add r14, 4
L564:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L565
L566:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L560:
    call Lrd_slow
    jmp L561
L562:
    call Lrd_slow
    jmp L563
L565:
    mov esi, ebp
    call Lrd_slow
    jmp L566
    ALIGN 16
Lf_C4:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L567
L568:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L569
L570:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    test r8b, 128
    jnz L571
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
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L572
    mov byte ptr [rdi+rsi], r10b
L573:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L574
L575:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L576
    mov byte ptr [rdi+rsi], r11b
L577:
    mov ebp, dword ptr [rsp+48]
L571:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L578
L579:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L567:
    call Lrd_slow
    jmp L568
L569:
    call Lrd_slow
    jmp L570
L572:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L573
L574:
    call Ltick_slow4
    jmp L575
L576:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L577
L578:
    mov esi, ebp
    call Lrd_slow
    jmp L579
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
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L580
    mov byte ptr [rdi+rsi], r10b
L581:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L582
L583:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L584
    mov byte ptr [rdi+rsi], r11b
L585:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L586
L587:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L580:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L581
L582:
    call Ltick_slow4
    jmp L583
L584:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L585
L586:
    mov esi, ebp
    call Lrd_slow
    jmp L587
    ALIGN 16
Lf_C6:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L588
L589:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    add al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572712]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L590
L591:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L588:
    call Lrd_slow
    jmp L589
L590:
    mov esi, ebp
    call Lrd_slow
    jmp L591
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
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L592
    mov byte ptr [rdi+rsi], r10b
L593:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L594
L595:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L596
    mov byte ptr [rdi+rsi], r11b
L597:
    mov ebp, 0
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L598
L599:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L592:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L593
L594:
    call Ltick_slow4
    jmp L595
L596:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L597
L598:
    mov esi, ebp
    call Lrd_slow
    jmp L599
    ALIGN 16
Lf_C8:
    add r14, 4
    test r8b, 128
    jz L600
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L601
L602:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L603
L604:
    movzx r11d, byte ptr [rdi+rsi]
    inc r9w
    shl r11d, 8
    or r11d, r10d
    mov ebp, r11d
    add r14, 4
L600:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L605
L606:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L601:
    call Lrd_slow
    jmp L602
L603:
    call Lrd_slow
    jmp L604
L605:
    mov esi, ebp
    call Lrd_slow
    jmp L606
    ALIGN 16
Lf_C9:
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L607
L608:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L609
L610:
    movzx r11d, byte ptr [rdi+rsi]
    inc r9w
    shl r11d, 8
    or r11d, r10d
    mov ebp, r11d
    add r14, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L611
L612:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L607:
    call Lrd_slow
    jmp L608
L609:
    call Lrd_slow
    jmp L610
L611:
    mov esi, ebp
    call Lrd_slow
    jmp L612
    ALIGN 16
Lf_CA:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L613
L614:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L615
L616:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    test r8b, 128
    jz L617
    mov ebp, r11d
    add r14, 4
L617:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L618
L619:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L613:
    call Lrd_slow
    jmp L614
L615:
    call Lrd_slow
    jmp L616
L618:
    mov esi, ebp
    call Lrd_slow
    jmp L619
    ALIGN 16
Lf_CB:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L620
L621:
    movzx esi, byte ptr [rdi+rsi]
    inc bp
    lea rdi, Ljt_fcb
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L620:
    call Lrd_slow
    jmp L621
    ALIGN 16
Lf_CC:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L622
L623:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L624
L625:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    test r8b, 128
    jz L626
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
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L627
    mov byte ptr [rdi+rsi], r10b
L628:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L629
L630:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L631
    mov byte ptr [rdi+rsi], r11b
L632:
    mov ebp, dword ptr [rsp+48]
L626:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L633
L634:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L622:
    call Lrd_slow
    jmp L623
L624:
    call Lrd_slow
    jmp L625
L627:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L628
L629:
    call Ltick_slow4
    jmp L630
L631:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L632
L633:
    mov esi, ebp
    call Lrd_slow
    jmp L634
    ALIGN 16
Lf_CD:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L635
L636:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L637
L638:
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
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L640
    mov byte ptr [rdi+rsi], r10b
L641:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L642
L643:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L644
    mov byte ptr [rdi+rsi], r11b
L645:
    mov ebp, dword ptr [rsp+48]
L639:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L646
L647:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L635:
    call Lrd_slow
    jmp L636
L637:
    call Lrd_slow
    jmp L638
L640:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L641
L642:
    call Ltick_slow4
    jmp L643
L644:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L645
L646:
    mov esi, ebp
    call Lrd_slow
    jmp L647
    ALIGN 16
Lf_CE:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L648
L649:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    bt r8d, 4
    adc al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572712]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L650
L651:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L648:
    call Lrd_slow
    jmp L649
L650:
    mov esi, ebp
    call Lrd_slow
    jmp L651
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
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L652
    mov byte ptr [rdi+rsi], r10b
L653:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L654
L655:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L656
    mov byte ptr [rdi+rsi], r11b
L657:
    mov ebp, 8
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L658
L659:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L652:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L653
L654:
    call Ltick_slow4
    jmp L655
L656:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L657
L658:
    mov esi, ebp
    call Lrd_slow
    jmp L659
    ALIGN 16
Lf_D0:
    add r14, 4
    test r8b, 16
    jnz L660
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L661
L662:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L663
L664:
    movzx r11d, byte ptr [rdi+rsi]
    inc r9w
    shl r11d, 8
    or r11d, r10d
    mov ebp, r11d
    add r14, 4
L660:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L665
L666:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L661:
    call Lrd_slow
    jmp L662
L663:
    call Lrd_slow
    jmp L664
L665:
    mov esi, ebp
    call Lrd_slow
    jmp L666
    ALIGN 16
Lf_D1:
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L667
L668:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L669
L670:
    movzx r11d, byte ptr [rdi+rsi]
    inc r9w
    shl r11d, 8
    or r11d, r10d
    mov edx, r11d
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L671
L672:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L667:
    call Lrd_slow
    jmp L668
L669:
    call Lrd_slow
    jmp L670
L671:
    mov esi, ebp
    call Lrd_slow
    jmp L672
    ALIGN 16
Lf_D2:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L673
L674:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L675
L676:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    test r8b, 16
    jnz L677
    mov ebp, r11d
    add r14, 4
L677:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L678
L679:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L673:
    call Lrd_slow
    jmp L674
L675:
    call Lrd_slow
    jmp L676
L678:
    mov esi, ebp
    call Lrd_slow
    jmp L679
    ALIGN 16
Lf_D3:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L680
L681:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L680:
    mov esi, ebp
    call Lrd_slow
    jmp L681
    ALIGN 16
Lf_D4:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L682
L683:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L684
L685:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    test r8b, 16
    jnz L686
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
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L687
    mov byte ptr [rdi+rsi], r10b
L688:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L689
L690:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L691
    mov byte ptr [rdi+rsi], r11b
L692:
    mov ebp, dword ptr [rsp+48]
L686:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L693
L694:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L682:
    call Lrd_slow
    jmp L683
L684:
    call Lrd_slow
    jmp L685
L687:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L688
L689:
    call Ltick_slow4
    jmp L690
L691:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L692
L693:
    mov esi, ebp
    call Lrd_slow
    jmp L694
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
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L695
    mov byte ptr [rdi+rsi], r10b
L696:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L697
L698:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L699
    mov byte ptr [rdi+rsi], r11b
L700:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L701
L702:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L695:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L696
L697:
    call Ltick_slow4
    jmp L698
L699:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L700
L701:
    mov esi, ebp
    call Lrd_slow
    jmp L702
    ALIGN 16
Lf_D6:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L703
L704:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    sub al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L705
L706:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L703:
    call Lrd_slow
    jmp L704
L705:
    mov esi, ebp
    call Lrd_slow
    jmp L706
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
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L707
    mov byte ptr [rdi+rsi], r10b
L708:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L709
L710:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L711
    mov byte ptr [rdi+rsi], r11b
L712:
    mov ebp, 16
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L713
L714:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L707:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L708
L709:
    call Ltick_slow4
    jmp L710
L711:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L712
L713:
    mov esi, ebp
    call Lrd_slow
    jmp L714
    ALIGN 16
Lf_D8:
    add r14, 4
    test r8b, 16
    jz L715
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L716
L717:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L718
L719:
    movzx r11d, byte ptr [rdi+rsi]
    inc r9w
    shl r11d, 8
    or r11d, r10d
    mov ebp, r11d
    add r14, 4
L715:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L720
L721:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L716:
    call Lrd_slow
    jmp L717
L718:
    call Lrd_slow
    jmp L719
L720:
    mov esi, ebp
    call Lrd_slow
    jmp L721
    ALIGN 16
Lf_D9:
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L722
L723:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L724
L725:
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
    cmp byte ptr [r15+572675], 0
    jne L726
    mov qword ptr [r15+40], r14
    movzx edi, word ptr [r15+572672]
    add edi, r14d
    mov word ptr [r15+65858], di
L726:
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
    mov r13, qword ptr [r15+572624]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L727
L728:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L722:
    call Lrd_slow
    jmp L723
L724:
    call Lrd_slow
    jmp L725
L727:
    mov esi, ebp
    call Lrd_slow
    jmp L728
    ALIGN 16
Lf_DA:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L729
L730:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L731
L732:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    test r8b, 16
    jz L733
    mov ebp, r11d
    add r14, 4
L733:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L734
L735:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L729:
    call Lrd_slow
    jmp L730
L731:
    call Lrd_slow
    jmp L732
L734:
    mov esi, ebp
    call Lrd_slow
    jmp L735
    ALIGN 16
Lf_DB:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L736
L737:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L736:
    mov esi, ebp
    call Lrd_slow
    jmp L737
    ALIGN 16
Lf_DC:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L738
L739:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L740
L741:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    test r8b, 16
    jz L742
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
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L743
    mov byte ptr [rdi+rsi], r10b
L744:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L745
L746:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L747
    mov byte ptr [rdi+rsi], r11b
L748:
    mov ebp, dword ptr [rsp+48]
L742:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L749
L750:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L738:
    call Lrd_slow
    jmp L739
L740:
    call Lrd_slow
    jmp L741
L743:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L744
L745:
    call Ltick_slow4
    jmp L746
L747:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L748
L749:
    mov esi, ebp
    call Lrd_slow
    jmp L750
    ALIGN 16
Lf_DD:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L751
L752:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L751:
    mov esi, ebp
    call Lrd_slow
    jmp L752
    ALIGN 16
Lf_DE:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L753
L754:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    bt r8d, 4
    sbb al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L755
L756:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L753:
    call Lrd_slow
    jmp L754
L755:
    mov esi, ebp
    call Lrd_slow
    jmp L756
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
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L757
    mov byte ptr [rdi+rsi], r10b
L758:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L759
L760:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L761
    mov byte ptr [rdi+rsi], r11b
L762:
    mov ebp, 24
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L763
L764:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L757:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L758
L759:
    call Ltick_slow4
    jmp L760
L761:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L762
L763:
    mov esi, ebp
    call Lrd_slow
    jmp L764
    ALIGN 16
Lf_E0:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L767
L768:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    cmp r10d, 128
    jb L765
    cmp r10d, 255
    je L765
    add r14, 4
    mov rdi, qword ptr [r15+572576]
    mov byte ptr [rdi+r10+65280], al
    jmp L766
L765:
    movzx esi, r10b
    or esi, 65280
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L769
    mov byte ptr [rdi+rsi], al
L770:
L766:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L771
L772:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L767:
    call Lrd_slow
    jmp L768
L769:
    mov byte ptr [rsp+40], al
    call Lwr_slow
    jmp L770
L771:
    mov esi, ebp
    call Lrd_slow
    jmp L772
    ALIGN 16
Lf_E1:
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L773
L774:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L775
L776:
    movzx r11d, byte ptr [rdi+rsi]
    inc r9w
    shl r11d, 8
    or r11d, r10d
    mov ebx, r11d
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L777
L778:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L773:
    call Lrd_slow
    jmp L774
L775:
    call Lrd_slow
    jmp L776
L777:
    mov esi, ebp
    call Lrd_slow
    jmp L778
    ALIGN 16
Lf_E2:
    movzx esi, cl
    or esi, 65280
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L779
    mov byte ptr [rdi+rsi], al
L780:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L781
L782:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L779:
    mov byte ptr [rsp+40], al
    call Lwr_slow
    jmp L780
L781:
    mov esi, ebp
    call Lrd_slow
    jmp L782
    ALIGN 16
Lf_E3:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L783
L784:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L783:
    mov esi, ebp
    call Lrd_slow
    jmp L784
    ALIGN 16
Lf_E4:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L785
L786:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L785:
    mov esi, ebp
    call Lrd_slow
    jmp L786
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
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L787
    mov byte ptr [rdi+rsi], r10b
L788:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L789
L790:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L791
    mov byte ptr [rdi+rsi], r11b
L792:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L793
L794:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L787:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L788
L789:
    call Ltick_slow4
    jmp L790
L791:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L792
L793:
    mov esi, ebp
    call Lrd_slow
    jmp L794
    ALIGN 16
Lf_E6:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L795
L796:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    and al, r10b
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573992]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L797
L798:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L795:
    call Lrd_slow
    jmp L796
L797:
    mov esi, ebp
    call Lrd_slow
    jmp L798
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
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L799
    mov byte ptr [rdi+rsi], r10b
L800:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L801
L802:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L803
    mov byte ptr [rdi+rsi], r11b
L804:
    mov ebp, 32
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L805
L806:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L799:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L800
L801:
    call Ltick_slow4
    jmp L802
L803:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L804
L805:
    mov esi, ebp
    call Lrd_slow
    jmp L806
    ALIGN 16
Lf_E8:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L807
L808:
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L809
L810:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L807:
    call Lrd_slow
    jmp L808
L809:
    mov esi, ebp
    call Lrd_slow
    jmp L810
    ALIGN 16
Lf_E9:
    mov ebp, ebx
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L811
L812:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L811:
    mov esi, ebp
    call Lrd_slow
    jmp L812
    ALIGN 16
Lf_EA:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L813
L814:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L815
L816:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    mov esi, r11d
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L817
    mov byte ptr [rdi+rsi], al
L818:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L819
L820:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L813:
    call Lrd_slow
    jmp L814
L815:
    call Lrd_slow
    jmp L816
L817:
    mov byte ptr [rsp+40], al
    call Lwr_slow
    jmp L818
L819:
    mov esi, ebp
    call Lrd_slow
    jmp L820
    ALIGN 16
Lf_EB:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L821
L822:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L821:
    mov esi, ebp
    call Lrd_slow
    jmp L822
    ALIGN 16
Lf_EC:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L823
L824:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L823:
    mov esi, ebp
    call Lrd_slow
    jmp L824
    ALIGN 16
Lf_ED:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L825
L826:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L825:
    mov esi, ebp
    call Lrd_slow
    jmp L826
    ALIGN 16
Lf_EE:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L827
L828:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    xor al, r10b
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573736]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L829
L830:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L827:
    call Lrd_slow
    jmp L828
L829:
    mov esi, ebp
    call Lrd_slow
    jmp L830
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
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L831
    mov byte ptr [rdi+rsi], r10b
L832:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L833
L834:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L835
    mov byte ptr [rdi+rsi], r11b
L836:
    mov ebp, 40
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L837
L838:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L831:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L832
L833:
    call Ltick_slow4
    jmp L834
L835:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L836
L837:
    mov esi, ebp
    call Lrd_slow
    jmp L838
    ALIGN 16
Lf_F0:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L841
L842:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    cmp r10d, 128
    jb L839
    cmp r10d, 255
    je L839
    add r14, 4
    mov rdi, qword ptr [r15+572576]
    mov al, byte ptr [rdi+r10+65280]
    jmp L840
L839:
    movzx esi, r10b
    or esi, 65280
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L843
L844:
    mov al, byte ptr [rdi+rsi]
L840:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L845
L846:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L841:
    call Lrd_slow
    jmp L842
L843:
    call Lrd_slow
    jmp L844
L845:
    mov esi, ebp
    call Lrd_slow
    jmp L846
    ALIGN 16
Lf_F1:
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L847
L848:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L849
L850:
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L851
L852:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L847:
    call Lrd_slow
    jmp L848
L849:
    call Lrd_slow
    jmp L850
L851:
    mov esi, ebp
    call Lrd_slow
    jmp L852
    ALIGN 16
Lf_F2:
    movzx esi, cl
    or esi, 65280
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L853
L854:
    mov al, byte ptr [rdi+rsi]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L855
L856:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L853:
    call Lrd_slow
    jmp L854
L855:
    mov esi, ebp
    call Lrd_slow
    jmp L856
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
    cmp byte ptr [r15+572675], 0
    jne L857
    mov qword ptr [r15+40], r14
    movzx edi, word ptr [r15+572672]
    add edi, r14d
    mov word ptr [r15+65858], di
L857:
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
    mov r13, qword ptr [r15+572624]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L858
L859:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L858:
    mov esi, ebp
    call Lrd_slow
    jmp L859
    ALIGN 16
Lf_F4:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L860
L861:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L860:
    mov esi, ebp
    call Lrd_slow
    jmp L861
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
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L862
    mov byte ptr [rdi+rsi], r10b
L863:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L864
L865:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L866
    mov byte ptr [rdi+rsi], r11b
L867:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L868
L869:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L862:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L863
L864:
    call Ltick_slow4
    jmp L865
L866:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L867
L868:
    mov esi, ebp
    call Lrd_slow
    jmp L869
    ALIGN 16
Lf_F6:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L870
L871:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    or al, r10b
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573736]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L872
L873:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L870:
    call Lrd_slow
    jmp L871
L872:
    mov esi, ebp
    call Lrd_slow
    jmp L873
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
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L874
    mov byte ptr [rdi+rsi], r10b
L875:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L876
L877:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L878
    mov byte ptr [rdi+rsi], r11b
L879:
    mov ebp, 48
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L880
L881:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L874:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L875
L876:
    call Ltick_slow4
    jmp L877
L878:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L879
L880:
    mov esi, ebp
    call Lrd_slow
    jmp L881
    ALIGN 16
Lf_F8:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L882
L883:
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L884
L885:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L882:
    call Lrd_slow
    jmp L883
L884:
    mov esi, ebp
    call Lrd_slow
    jmp L885
    ALIGN 16
Lf_F9:
    mov r9d, ebx
    add r14, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L886
L887:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L886:
    mov esi, ebp
    call Lrd_slow
    jmp L887
    ALIGN 16
Lf_FA:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L888
L889:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L890
L891:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    mov esi, r11d
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L892
L893:
    mov al, byte ptr [rdi+rsi]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L894
L895:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L888:
    call Lrd_slow
    jmp L889
L890:
    call Lrd_slow
    jmp L891
L892:
    call Lrd_slow
    jmp L893
L894:
    mov esi, ebp
    call Lrd_slow
    jmp L895
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
    cmp byte ptr [r15+572675], 0
    jne L896
    mov qword ptr [r15+40], r14
    movzx edi, word ptr [r15+572672]
    add edi, r14d
    mov word ptr [r15+65858], di
L896:
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
    mov r13, qword ptr [r15+572624]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L897
L898:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L897:
    mov esi, ebp
    call Lrd_slow
    jmp L898
    ALIGN 16
Lf_FC:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L899
L900:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L899:
    mov esi, ebp
    call Lrd_slow
    jmp L900
    ALIGN 16
Lf_FD:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L901
L902:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L901:
    mov esi, ebp
    call Lrd_slow
    jmp L902
    ALIGN 16
Lf_FE:
    mov esi, ebp
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L903
L904:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    cmp al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L905
L906:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L903:
    call Lrd_slow
    jmp L904
L905:
    mov esi, ebp
    call Lrd_slow
    jmp L906
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
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L907
    mov byte ptr [rdi+rsi], r10b
L908:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L909
L910:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L911
    mov byte ptr [rdi+rsi], r11b
L912:
    mov ebp, 56
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L913
L914:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L907:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L908
L909:
    call Ltick_slow4
    jmp L910
L911:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L912
L913:
    mov esi, ebp
    call Lrd_slow
    jmp L914
    ALIGN 16
Lfcb_00:
    rol ch, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, ch
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L915
L916:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L915:
    mov esi, ebp
    call Lrd_slow
    jmp L916
    ALIGN 16
Lfcb_01:
    rol cl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, cl
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L917
L918:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L917:
    mov esi, ebp
    call Lrd_slow
    jmp L918
    ALIGN 16
Lfcb_02:
    rol dh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dh
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L919
L920:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L919:
    mov esi, ebp
    call Lrd_slow
    jmp L920
    ALIGN 16
Lfcb_03:
    rol dl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dl
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L921
L922:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L921:
    mov esi, ebp
    call Lrd_slow
    jmp L922
    ALIGN 16
Lfcb_04:
    rol bh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bh
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L923
L924:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L923:
    mov esi, ebp
    call Lrd_slow
    jmp L924
    ALIGN 16
Lfcb_05:
    rol bl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bl
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L925
L926:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L925:
    mov esi, ebp
    call Lrd_slow
    jmp L926
    ALIGN 16
Lfcb_06:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L927
L928:
    movzx r10d, byte ptr [rdi+rsi]
    rol r10b, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, r10b
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L929
    mov byte ptr [rdi+rsi], r10b
L930:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L931
L932:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L927:
    call Lrd_slow
    jmp L928
L929:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L930
L931:
    mov esi, ebp
    call Lrd_slow
    jmp L932
    ALIGN 16
Lfcb_07:
    rol al, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, al
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L933
L934:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L933:
    mov esi, ebp
    call Lrd_slow
    jmp L934
    ALIGN 16
Lfcb_08:
    ror ch, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, ch
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L935
L936:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L935:
    mov esi, ebp
    call Lrd_slow
    jmp L936
    ALIGN 16
Lfcb_09:
    ror cl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, cl
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L937
L938:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L937:
    mov esi, ebp
    call Lrd_slow
    jmp L938
    ALIGN 16
Lfcb_0A:
    ror dh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dh
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L939
L940:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L939:
    mov esi, ebp
    call Lrd_slow
    jmp L940
    ALIGN 16
Lfcb_0B:
    ror dl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dl
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L941
L942:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L941:
    mov esi, ebp
    call Lrd_slow
    jmp L942
    ALIGN 16
Lfcb_0C:
    ror bh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bh
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L943
L944:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L943:
    mov esi, ebp
    call Lrd_slow
    jmp L944
    ALIGN 16
Lfcb_0D:
    ror bl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bl
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L945
L946:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L945:
    mov esi, ebp
    call Lrd_slow
    jmp L946
    ALIGN 16
Lfcb_0E:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L947
L948:
    movzx r10d, byte ptr [rdi+rsi]
    ror r10b, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, r10b
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L949
    mov byte ptr [rdi+rsi], r10b
L950:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L951
L952:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L947:
    call Lrd_slow
    jmp L948
L949:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L950
L951:
    mov esi, ebp
    call Lrd_slow
    jmp L952
    ALIGN 16
Lfcb_0F:
    ror al, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, al
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L953
L954:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L953:
    mov esi, ebp
    call Lrd_slow
    jmp L954
    ALIGN 16
Lfcb_10:
    bt r8d, 4
    rcl ch, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, ch
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L955
L956:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L955:
    mov esi, ebp
    call Lrd_slow
    jmp L956
    ALIGN 16
Lfcb_11:
    bt r8d, 4
    rcl cl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, cl
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L957
L958:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L957:
    mov esi, ebp
    call Lrd_slow
    jmp L958
    ALIGN 16
Lfcb_12:
    bt r8d, 4
    rcl dh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dh
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L959
L960:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L959:
    mov esi, ebp
    call Lrd_slow
    jmp L960
    ALIGN 16
Lfcb_13:
    bt r8d, 4
    rcl dl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dl
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L961
L962:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L961:
    mov esi, ebp
    call Lrd_slow
    jmp L962
    ALIGN 16
Lfcb_14:
    bt r8d, 4
    rcl bh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bh
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L963
L964:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L963:
    mov esi, ebp
    call Lrd_slow
    jmp L964
    ALIGN 16
Lfcb_15:
    bt r8d, 4
    rcl bl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bl
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L965
L966:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L965:
    mov esi, ebp
    call Lrd_slow
    jmp L966
    ALIGN 16
Lfcb_16:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L967
L968:
    movzx r10d, byte ptr [rdi+rsi]
    bt r8d, 4
    rcl r10b, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, r10b
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L969
    mov byte ptr [rdi+rsi], r10b
L970:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L971
L972:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L967:
    call Lrd_slow
    jmp L968
L969:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L970
L971:
    mov esi, ebp
    call Lrd_slow
    jmp L972
    ALIGN 16
Lfcb_17:
    bt r8d, 4
    rcl al, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, al
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L973
L974:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L973:
    mov esi, ebp
    call Lrd_slow
    jmp L974
    ALIGN 16
Lfcb_18:
    bt r8d, 4
    rcr ch, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, ch
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L975
L976:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L975:
    mov esi, ebp
    call Lrd_slow
    jmp L976
    ALIGN 16
Lfcb_19:
    bt r8d, 4
    rcr cl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, cl
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L977
L978:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L977:
    mov esi, ebp
    call Lrd_slow
    jmp L978
    ALIGN 16
Lfcb_1A:
    bt r8d, 4
    rcr dh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dh
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L979
L980:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L979:
    mov esi, ebp
    call Lrd_slow
    jmp L980
    ALIGN 16
Lfcb_1B:
    bt r8d, 4
    rcr dl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dl
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L981
L982:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L981:
    mov esi, ebp
    call Lrd_slow
    jmp L982
    ALIGN 16
Lfcb_1C:
    bt r8d, 4
    rcr bh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bh
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L983
L984:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L983:
    mov esi, ebp
    call Lrd_slow
    jmp L984
    ALIGN 16
Lfcb_1D:
    bt r8d, 4
    rcr bl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bl
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L985
L986:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L985:
    mov esi, ebp
    call Lrd_slow
    jmp L986
    ALIGN 16
Lfcb_1E:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L987
L988:
    movzx r10d, byte ptr [rdi+rsi]
    bt r8d, 4
    rcr r10b, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, r10b
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L989
    mov byte ptr [rdi+rsi], r10b
L990:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L991
L992:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L987:
    call Lrd_slow
    jmp L988
L989:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L990
L991:
    mov esi, ebp
    call Lrd_slow
    jmp L992
    ALIGN 16
Lfcb_1F:
    bt r8d, 4
    rcr al, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, al
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L993
L994:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L993:
    mov esi, ebp
    call Lrd_slow
    jmp L994
    ALIGN 16
Lfcb_20:
    shl ch, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, ch
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L995
L996:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L995:
    mov esi, ebp
    call Lrd_slow
    jmp L996
    ALIGN 16
Lfcb_21:
    shl cl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, cl
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L997
L998:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L997:
    mov esi, ebp
    call Lrd_slow
    jmp L998
    ALIGN 16
Lfcb_22:
    shl dh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dh
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L999
L1000:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L999:
    mov esi, ebp
    call Lrd_slow
    jmp L1000
    ALIGN 16
Lfcb_23:
    shl dl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dl
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1001
L1002:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1001:
    mov esi, ebp
    call Lrd_slow
    jmp L1002
    ALIGN 16
Lfcb_24:
    shl bh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bh
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1003
L1004:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1003:
    mov esi, ebp
    call Lrd_slow
    jmp L1004
    ALIGN 16
Lfcb_25:
    shl bl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bl
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1005
L1006:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1005:
    mov esi, ebp
    call Lrd_slow
    jmp L1006
    ALIGN 16
Lfcb_26:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1007
L1008:
    movzx r10d, byte ptr [rdi+rsi]
    shl r10b, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, r10b
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1009
    mov byte ptr [rdi+rsi], r10b
L1010:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1011
L1012:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1007:
    call Lrd_slow
    jmp L1008
L1009:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1010
L1011:
    mov esi, ebp
    call Lrd_slow
    jmp L1012
    ALIGN 16
Lfcb_27:
    shl al, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, al
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1013
L1014:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1013:
    mov esi, ebp
    call Lrd_slow
    jmp L1014
    ALIGN 16
Lfcb_28:
    sar ch, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, ch
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1015
L1016:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1015:
    mov esi, ebp
    call Lrd_slow
    jmp L1016
    ALIGN 16
Lfcb_29:
    sar cl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, cl
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1017
L1018:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1017:
    mov esi, ebp
    call Lrd_slow
    jmp L1018
    ALIGN 16
Lfcb_2A:
    sar dh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dh
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1019
L1020:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1019:
    mov esi, ebp
    call Lrd_slow
    jmp L1020
    ALIGN 16
Lfcb_2B:
    sar dl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dl
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1021
L1022:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1021:
    mov esi, ebp
    call Lrd_slow
    jmp L1022
    ALIGN 16
Lfcb_2C:
    sar bh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bh
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1023
L1024:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1023:
    mov esi, ebp
    call Lrd_slow
    jmp L1024
    ALIGN 16
Lfcb_2D:
    sar bl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bl
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1025
L1026:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1025:
    mov esi, ebp
    call Lrd_slow
    jmp L1026
    ALIGN 16
Lfcb_2E:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1027
L1028:
    movzx r10d, byte ptr [rdi+rsi]
    sar r10b, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, r10b
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1029
    mov byte ptr [rdi+rsi], r10b
L1030:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1031
L1032:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1027:
    call Lrd_slow
    jmp L1028
L1029:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1030
L1031:
    mov esi, ebp
    call Lrd_slow
    jmp L1032
    ALIGN 16
Lfcb_2F:
    sar al, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, al
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1033
L1034:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1033:
    mov esi, ebp
    call Lrd_slow
    jmp L1034
    ALIGN 16
Lfcb_30:
    rol ch, 4
    movzx edi, ch
    movzx r8d, byte ptr [r15+rdi+573736]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1035
L1036:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1035:
    mov esi, ebp
    call Lrd_slow
    jmp L1036
    ALIGN 16
Lfcb_31:
    rol cl, 4
    movzx edi, cl
    movzx r8d, byte ptr [r15+rdi+573736]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1037
L1038:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1037:
    mov esi, ebp
    call Lrd_slow
    jmp L1038
    ALIGN 16
Lfcb_32:
    rol dh, 4
    movzx edi, dh
    movzx r8d, byte ptr [r15+rdi+573736]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1039
L1040:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1039:
    mov esi, ebp
    call Lrd_slow
    jmp L1040
    ALIGN 16
Lfcb_33:
    rol dl, 4
    movzx edi, dl
    movzx r8d, byte ptr [r15+rdi+573736]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1041
L1042:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1041:
    mov esi, ebp
    call Lrd_slow
    jmp L1042
    ALIGN 16
Lfcb_34:
    rol bh, 4
    movzx edi, bh
    movzx r8d, byte ptr [r15+rdi+573736]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1043
L1044:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1043:
    mov esi, ebp
    call Lrd_slow
    jmp L1044
    ALIGN 16
Lfcb_35:
    rol bl, 4
    movzx edi, bl
    movzx r8d, byte ptr [r15+rdi+573736]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1045
L1046:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1045:
    mov esi, ebp
    call Lrd_slow
    jmp L1046
    ALIGN 16
Lfcb_36:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1047
L1048:
    movzx r10d, byte ptr [rdi+rsi]
    rol r10b, 4
    movzx edi, r10b
    movzx r8d, byte ptr [r15+rdi+573736]
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1049
    mov byte ptr [rdi+rsi], r10b
L1050:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1051
L1052:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1047:
    call Lrd_slow
    jmp L1048
L1049:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1050
L1051:
    mov esi, ebp
    call Lrd_slow
    jmp L1052
    ALIGN 16
Lfcb_37:
    rol al, 4
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573736]
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1053
L1054:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1053:
    mov esi, ebp
    call Lrd_slow
    jmp L1054
    ALIGN 16
Lfcb_38:
    shr ch, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, ch
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1055
L1056:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1055:
    mov esi, ebp
    call Lrd_slow
    jmp L1056
    ALIGN 16
Lfcb_39:
    shr cl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, cl
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1057
L1058:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1057:
    mov esi, ebp
    call Lrd_slow
    jmp L1058
    ALIGN 16
Lfcb_3A:
    shr dh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dh
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1059
L1060:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1059:
    mov esi, ebp
    call Lrd_slow
    jmp L1060
    ALIGN 16
Lfcb_3B:
    shr dl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dl
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1061
L1062:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1061:
    mov esi, ebp
    call Lrd_slow
    jmp L1062
    ALIGN 16
Lfcb_3C:
    shr bh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bh
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1063
L1064:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1063:
    mov esi, ebp
    call Lrd_slow
    jmp L1064
    ALIGN 16
Lfcb_3D:
    shr bl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bl
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1065
L1066:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1065:
    mov esi, ebp
    call Lrd_slow
    jmp L1066
    ALIGN 16
Lfcb_3E:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1067
L1068:
    movzx r10d, byte ptr [rdi+rsi]
    shr r10b, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, r10b
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1069
    mov byte ptr [rdi+rsi], r10b
L1070:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1071
L1072:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1067:
    call Lrd_slow
    jmp L1068
L1069:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1070
L1071:
    mov esi, ebp
    call Lrd_slow
    jmp L1072
    ALIGN 16
Lfcb_3F:
    shr al, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, al
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1073
L1074:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1073:
    mov esi, ebp
    call Lrd_slow
    jmp L1074
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1075
L1076:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1075:
    mov esi, ebp
    call Lrd_slow
    jmp L1076
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1077
L1078:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1077:
    mov esi, ebp
    call Lrd_slow
    jmp L1078
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1079
L1080:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1079:
    mov esi, ebp
    call Lrd_slow
    jmp L1080
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1081
L1082:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1081:
    mov esi, ebp
    call Lrd_slow
    jmp L1082
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1083
L1084:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1083:
    mov esi, ebp
    call Lrd_slow
    jmp L1084
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1085
L1086:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1085:
    mov esi, ebp
    call Lrd_slow
    jmp L1086
    ALIGN 16
Lfcb_46:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1087
L1088:
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1089
L1090:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1087:
    call Lrd_slow
    jmp L1088
L1089:
    mov esi, ebp
    call Lrd_slow
    jmp L1090
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1091
L1092:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1091:
    mov esi, ebp
    call Lrd_slow
    jmp L1092
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1093
L1094:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1093:
    mov esi, ebp
    call Lrd_slow
    jmp L1094
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1095
L1096:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1095:
    mov esi, ebp
    call Lrd_slow
    jmp L1096
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1097
L1098:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1097:
    mov esi, ebp
    call Lrd_slow
    jmp L1098
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1099
L1100:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1099:
    mov esi, ebp
    call Lrd_slow
    jmp L1100
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1101
L1102:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1101:
    mov esi, ebp
    call Lrd_slow
    jmp L1102
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1103
L1104:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1103:
    mov esi, ebp
    call Lrd_slow
    jmp L1104
    ALIGN 16
Lfcb_4E:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1105
L1106:
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1107
L1108:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1105:
    call Lrd_slow
    jmp L1106
L1107:
    mov esi, ebp
    call Lrd_slow
    jmp L1108
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1109
L1110:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1109:
    mov esi, ebp
    call Lrd_slow
    jmp L1110
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1111
L1112:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1111:
    mov esi, ebp
    call Lrd_slow
    jmp L1112
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1113
L1114:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1113:
    mov esi, ebp
    call Lrd_slow
    jmp L1114
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1115
L1116:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1115:
    mov esi, ebp
    call Lrd_slow
    jmp L1116
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1117
L1118:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1117:
    mov esi, ebp
    call Lrd_slow
    jmp L1118
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1119
L1120:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1119:
    mov esi, ebp
    call Lrd_slow
    jmp L1120
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1121
L1122:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1121:
    mov esi, ebp
    call Lrd_slow
    jmp L1122
    ALIGN 16
Lfcb_56:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1123
L1124:
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1125
L1126:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1123:
    call Lrd_slow
    jmp L1124
L1125:
    mov esi, ebp
    call Lrd_slow
    jmp L1126
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1127
L1128:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1127:
    mov esi, ebp
    call Lrd_slow
    jmp L1128
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1129
L1130:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1129:
    mov esi, ebp
    call Lrd_slow
    jmp L1130
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1131
L1132:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1131:
    mov esi, ebp
    call Lrd_slow
    jmp L1132
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1133
L1134:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1133:
    mov esi, ebp
    call Lrd_slow
    jmp L1134
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1135
L1136:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1135:
    mov esi, ebp
    call Lrd_slow
    jmp L1136
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1137
L1138:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1137:
    mov esi, ebp
    call Lrd_slow
    jmp L1138
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1139
L1140:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1139:
    mov esi, ebp
    call Lrd_slow
    jmp L1140
    ALIGN 16
Lfcb_5E:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1141
L1142:
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1143
L1144:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1141:
    call Lrd_slow
    jmp L1142
L1143:
    mov esi, ebp
    call Lrd_slow
    jmp L1144
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1145
L1146:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1145:
    mov esi, ebp
    call Lrd_slow
    jmp L1146
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1147
L1148:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1147:
    mov esi, ebp
    call Lrd_slow
    jmp L1148
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1149
L1150:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1149:
    mov esi, ebp
    call Lrd_slow
    jmp L1150
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1151
L1152:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1151:
    mov esi, ebp
    call Lrd_slow
    jmp L1152
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1153
L1154:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1153:
    mov esi, ebp
    call Lrd_slow
    jmp L1154
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1155
L1156:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1155:
    mov esi, ebp
    call Lrd_slow
    jmp L1156
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1157
L1158:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1157:
    mov esi, ebp
    call Lrd_slow
    jmp L1158
    ALIGN 16
Lfcb_66:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1159
L1160:
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1161
L1162:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1159:
    call Lrd_slow
    jmp L1160
L1161:
    mov esi, ebp
    call Lrd_slow
    jmp L1162
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1163
L1164:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1163:
    mov esi, ebp
    call Lrd_slow
    jmp L1164
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1165
L1166:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1165:
    mov esi, ebp
    call Lrd_slow
    jmp L1166
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1167
L1168:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1167:
    mov esi, ebp
    call Lrd_slow
    jmp L1168
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1169
L1170:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1169:
    mov esi, ebp
    call Lrd_slow
    jmp L1170
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1171
L1172:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1171:
    mov esi, ebp
    call Lrd_slow
    jmp L1172
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1173
L1174:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1173:
    mov esi, ebp
    call Lrd_slow
    jmp L1174
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1175
L1176:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1175:
    mov esi, ebp
    call Lrd_slow
    jmp L1176
    ALIGN 16
Lfcb_6E:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1177
L1178:
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1179
L1180:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1177:
    call Lrd_slow
    jmp L1178
L1179:
    mov esi, ebp
    call Lrd_slow
    jmp L1180
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1181
L1182:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1181:
    mov esi, ebp
    call Lrd_slow
    jmp L1182
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1183
L1184:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1183:
    mov esi, ebp
    call Lrd_slow
    jmp L1184
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1185
L1186:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1185:
    mov esi, ebp
    call Lrd_slow
    jmp L1186
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1187
L1188:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1187:
    mov esi, ebp
    call Lrd_slow
    jmp L1188
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1189
L1190:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1189:
    mov esi, ebp
    call Lrd_slow
    jmp L1190
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1191
L1192:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1191:
    mov esi, ebp
    call Lrd_slow
    jmp L1192
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1193
L1194:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1193:
    mov esi, ebp
    call Lrd_slow
    jmp L1194
    ALIGN 16
Lfcb_76:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1195
L1196:
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1197
L1198:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1195:
    call Lrd_slow
    jmp L1196
L1197:
    mov esi, ebp
    call Lrd_slow
    jmp L1198
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1199
L1200:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1199:
    mov esi, ebp
    call Lrd_slow
    jmp L1200
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1201
L1202:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1201:
    mov esi, ebp
    call Lrd_slow
    jmp L1202
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1203
L1204:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1203:
    mov esi, ebp
    call Lrd_slow
    jmp L1204
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1205
L1206:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1205:
    mov esi, ebp
    call Lrd_slow
    jmp L1206
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1207
L1208:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1207:
    mov esi, ebp
    call Lrd_slow
    jmp L1208
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1209
L1210:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1209:
    mov esi, ebp
    call Lrd_slow
    jmp L1210
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1211
L1212:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1211:
    mov esi, ebp
    call Lrd_slow
    jmp L1212
    ALIGN 16
Lfcb_7E:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1213
L1214:
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1215
L1216:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1213:
    call Lrd_slow
    jmp L1214
L1215:
    mov esi, ebp
    call Lrd_slow
    jmp L1216
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
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1217
L1218:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1217:
    mov esi, ebp
    call Lrd_slow
    jmp L1218
    ALIGN 16
Lfcb_80:
    and ch, 254
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1219
L1220:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1219:
    mov esi, ebp
    call Lrd_slow
    jmp L1220
    ALIGN 16
Lfcb_81:
    and cl, 254
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1221
L1222:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1221:
    mov esi, ebp
    call Lrd_slow
    jmp L1222
    ALIGN 16
Lfcb_82:
    and dh, 254
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1223
L1224:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1223:
    mov esi, ebp
    call Lrd_slow
    jmp L1224
    ALIGN 16
Lfcb_83:
    and dl, 254
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1225
L1226:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1225:
    mov esi, ebp
    call Lrd_slow
    jmp L1226
    ALIGN 16
Lfcb_84:
    and bh, 254
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1227
L1228:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1227:
    mov esi, ebp
    call Lrd_slow
    jmp L1228
    ALIGN 16
Lfcb_85:
    and bl, 254
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1229
L1230:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1229:
    mov esi, ebp
    call Lrd_slow
    jmp L1230
    ALIGN 16
Lfcb_86:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1231
L1232:
    movzx r10d, byte ptr [rdi+rsi]
    and r10b, 254
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1233
    mov byte ptr [rdi+rsi], r10b
L1234:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1235
L1236:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1231:
    call Lrd_slow
    jmp L1232
L1233:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1234
L1235:
    mov esi, ebp
    call Lrd_slow
    jmp L1236
    ALIGN 16
Lfcb_87:
    and al, 254
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1237
L1238:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1237:
    mov esi, ebp
    call Lrd_slow
    jmp L1238
    ALIGN 16
Lfcb_88:
    and ch, 253
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1239
L1240:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1239:
    mov esi, ebp
    call Lrd_slow
    jmp L1240
    ALIGN 16
Lfcb_89:
    and cl, 253
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1241
L1242:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1241:
    mov esi, ebp
    call Lrd_slow
    jmp L1242
    ALIGN 16
Lfcb_8A:
    and dh, 253
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1243
L1244:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1243:
    mov esi, ebp
    call Lrd_slow
    jmp L1244
    ALIGN 16
Lfcb_8B:
    and dl, 253
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1245
L1246:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1245:
    mov esi, ebp
    call Lrd_slow
    jmp L1246
    ALIGN 16
Lfcb_8C:
    and bh, 253
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1247
L1248:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1247:
    mov esi, ebp
    call Lrd_slow
    jmp L1248
    ALIGN 16
Lfcb_8D:
    and bl, 253
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1249
L1250:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1249:
    mov esi, ebp
    call Lrd_slow
    jmp L1250
    ALIGN 16
Lfcb_8E:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1251
L1252:
    movzx r10d, byte ptr [rdi+rsi]
    and r10b, 253
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1253
    mov byte ptr [rdi+rsi], r10b
L1254:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1255
L1256:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1251:
    call Lrd_slow
    jmp L1252
L1253:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1254
L1255:
    mov esi, ebp
    call Lrd_slow
    jmp L1256
    ALIGN 16
Lfcb_8F:
    and al, 253
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1257
L1258:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1257:
    mov esi, ebp
    call Lrd_slow
    jmp L1258
    ALIGN 16
Lfcb_90:
    and ch, 251
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1259
L1260:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1259:
    mov esi, ebp
    call Lrd_slow
    jmp L1260
    ALIGN 16
Lfcb_91:
    and cl, 251
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1261
L1262:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1261:
    mov esi, ebp
    call Lrd_slow
    jmp L1262
    ALIGN 16
Lfcb_92:
    and dh, 251
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1263
L1264:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1263:
    mov esi, ebp
    call Lrd_slow
    jmp L1264
    ALIGN 16
Lfcb_93:
    and dl, 251
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1265
L1266:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1265:
    mov esi, ebp
    call Lrd_slow
    jmp L1266
    ALIGN 16
Lfcb_94:
    and bh, 251
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1267
L1268:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1267:
    mov esi, ebp
    call Lrd_slow
    jmp L1268
    ALIGN 16
Lfcb_95:
    and bl, 251
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1269
L1270:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1269:
    mov esi, ebp
    call Lrd_slow
    jmp L1270
    ALIGN 16
Lfcb_96:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1271
L1272:
    movzx r10d, byte ptr [rdi+rsi]
    and r10b, 251
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1273
    mov byte ptr [rdi+rsi], r10b
L1274:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1275
L1276:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1271:
    call Lrd_slow
    jmp L1272
L1273:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1274
L1275:
    mov esi, ebp
    call Lrd_slow
    jmp L1276
    ALIGN 16
Lfcb_97:
    and al, 251
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1277
L1278:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1277:
    mov esi, ebp
    call Lrd_slow
    jmp L1278
    ALIGN 16
Lfcb_98:
    and ch, 247
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1279
L1280:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1279:
    mov esi, ebp
    call Lrd_slow
    jmp L1280
    ALIGN 16
Lfcb_99:
    and cl, 247
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1281
L1282:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1281:
    mov esi, ebp
    call Lrd_slow
    jmp L1282
    ALIGN 16
Lfcb_9A:
    and dh, 247
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1283
L1284:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1283:
    mov esi, ebp
    call Lrd_slow
    jmp L1284
    ALIGN 16
Lfcb_9B:
    and dl, 247
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1285
L1286:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1285:
    mov esi, ebp
    call Lrd_slow
    jmp L1286
    ALIGN 16
Lfcb_9C:
    and bh, 247
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1287
L1288:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1287:
    mov esi, ebp
    call Lrd_slow
    jmp L1288
    ALIGN 16
Lfcb_9D:
    and bl, 247
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1289
L1290:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1289:
    mov esi, ebp
    call Lrd_slow
    jmp L1290
    ALIGN 16
Lfcb_9E:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1291
L1292:
    movzx r10d, byte ptr [rdi+rsi]
    and r10b, 247
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1293
    mov byte ptr [rdi+rsi], r10b
L1294:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1295
L1296:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1291:
    call Lrd_slow
    jmp L1292
L1293:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1294
L1295:
    mov esi, ebp
    call Lrd_slow
    jmp L1296
    ALIGN 16
Lfcb_9F:
    and al, 247
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1297
L1298:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1297:
    mov esi, ebp
    call Lrd_slow
    jmp L1298
    ALIGN 16
Lfcb_A0:
    and ch, 239
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1299
L1300:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1299:
    mov esi, ebp
    call Lrd_slow
    jmp L1300
    ALIGN 16
Lfcb_A1:
    and cl, 239
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1301
L1302:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1301:
    mov esi, ebp
    call Lrd_slow
    jmp L1302
    ALIGN 16
Lfcb_A2:
    and dh, 239
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1303
L1304:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1303:
    mov esi, ebp
    call Lrd_slow
    jmp L1304
    ALIGN 16
Lfcb_A3:
    and dl, 239
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1305
L1306:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1305:
    mov esi, ebp
    call Lrd_slow
    jmp L1306
    ALIGN 16
Lfcb_A4:
    and bh, 239
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1307
L1308:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1307:
    mov esi, ebp
    call Lrd_slow
    jmp L1308
    ALIGN 16
Lfcb_A5:
    and bl, 239
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1309
L1310:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1309:
    mov esi, ebp
    call Lrd_slow
    jmp L1310
    ALIGN 16
Lfcb_A6:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1311
L1312:
    movzx r10d, byte ptr [rdi+rsi]
    and r10b, 239
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1313
    mov byte ptr [rdi+rsi], r10b
L1314:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1315
L1316:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1311:
    call Lrd_slow
    jmp L1312
L1313:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1314
L1315:
    mov esi, ebp
    call Lrd_slow
    jmp L1316
    ALIGN 16
Lfcb_A7:
    and al, 239
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1317
L1318:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1317:
    mov esi, ebp
    call Lrd_slow
    jmp L1318
    ALIGN 16
Lfcb_A8:
    and ch, 223
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1319
L1320:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1319:
    mov esi, ebp
    call Lrd_slow
    jmp L1320
    ALIGN 16
Lfcb_A9:
    and cl, 223
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1321
L1322:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1321:
    mov esi, ebp
    call Lrd_slow
    jmp L1322
    ALIGN 16
Lfcb_AA:
    and dh, 223
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1323
L1324:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1323:
    mov esi, ebp
    call Lrd_slow
    jmp L1324
    ALIGN 16
Lfcb_AB:
    and dl, 223
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1325
L1326:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1325:
    mov esi, ebp
    call Lrd_slow
    jmp L1326
    ALIGN 16
Lfcb_AC:
    and bh, 223
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1327
L1328:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1327:
    mov esi, ebp
    call Lrd_slow
    jmp L1328
    ALIGN 16
Lfcb_AD:
    and bl, 223
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1329
L1330:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1329:
    mov esi, ebp
    call Lrd_slow
    jmp L1330
    ALIGN 16
Lfcb_AE:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1331
L1332:
    movzx r10d, byte ptr [rdi+rsi]
    and r10b, 223
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1333
    mov byte ptr [rdi+rsi], r10b
L1334:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1335
L1336:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1331:
    call Lrd_slow
    jmp L1332
L1333:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1334
L1335:
    mov esi, ebp
    call Lrd_slow
    jmp L1336
    ALIGN 16
Lfcb_AF:
    and al, 223
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1337
L1338:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1337:
    mov esi, ebp
    call Lrd_slow
    jmp L1338
    ALIGN 16
Lfcb_B0:
    and ch, 191
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1339
L1340:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1339:
    mov esi, ebp
    call Lrd_slow
    jmp L1340
    ALIGN 16
Lfcb_B1:
    and cl, 191
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1341
L1342:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1341:
    mov esi, ebp
    call Lrd_slow
    jmp L1342
    ALIGN 16
Lfcb_B2:
    and dh, 191
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1343
L1344:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1343:
    mov esi, ebp
    call Lrd_slow
    jmp L1344
    ALIGN 16
Lfcb_B3:
    and dl, 191
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1345
L1346:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1345:
    mov esi, ebp
    call Lrd_slow
    jmp L1346
    ALIGN 16
Lfcb_B4:
    and bh, 191
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1347
L1348:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1347:
    mov esi, ebp
    call Lrd_slow
    jmp L1348
    ALIGN 16
Lfcb_B5:
    and bl, 191
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1349
L1350:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1349:
    mov esi, ebp
    call Lrd_slow
    jmp L1350
    ALIGN 16
Lfcb_B6:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1351
L1352:
    movzx r10d, byte ptr [rdi+rsi]
    and r10b, 191
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1353
    mov byte ptr [rdi+rsi], r10b
L1354:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1355
L1356:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1351:
    call Lrd_slow
    jmp L1352
L1353:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1354
L1355:
    mov esi, ebp
    call Lrd_slow
    jmp L1356
    ALIGN 16
Lfcb_B7:
    and al, 191
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1357
L1358:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1357:
    mov esi, ebp
    call Lrd_slow
    jmp L1358
    ALIGN 16
Lfcb_B8:
    and ch, 127
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1359
L1360:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1359:
    mov esi, ebp
    call Lrd_slow
    jmp L1360
    ALIGN 16
Lfcb_B9:
    and cl, 127
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1361
L1362:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1361:
    mov esi, ebp
    call Lrd_slow
    jmp L1362
    ALIGN 16
Lfcb_BA:
    and dh, 127
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1363
L1364:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1363:
    mov esi, ebp
    call Lrd_slow
    jmp L1364
    ALIGN 16
Lfcb_BB:
    and dl, 127
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1365
L1366:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1365:
    mov esi, ebp
    call Lrd_slow
    jmp L1366
    ALIGN 16
Lfcb_BC:
    and bh, 127
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1367
L1368:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1367:
    mov esi, ebp
    call Lrd_slow
    jmp L1368
    ALIGN 16
Lfcb_BD:
    and bl, 127
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1369
L1370:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1369:
    mov esi, ebp
    call Lrd_slow
    jmp L1370
    ALIGN 16
Lfcb_BE:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1371
L1372:
    movzx r10d, byte ptr [rdi+rsi]
    and r10b, 127
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1373
    mov byte ptr [rdi+rsi], r10b
L1374:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1375
L1376:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1371:
    call Lrd_slow
    jmp L1372
L1373:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1374
L1375:
    mov esi, ebp
    call Lrd_slow
    jmp L1376
    ALIGN 16
Lfcb_BF:
    and al, 127
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1377
L1378:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1377:
    mov esi, ebp
    call Lrd_slow
    jmp L1378
    ALIGN 16
Lfcb_C0:
    or ch, 1
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1379
L1380:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1379:
    mov esi, ebp
    call Lrd_slow
    jmp L1380
    ALIGN 16
Lfcb_C1:
    or cl, 1
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1381
L1382:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1381:
    mov esi, ebp
    call Lrd_slow
    jmp L1382
    ALIGN 16
Lfcb_C2:
    or dh, 1
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1383
L1384:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1383:
    mov esi, ebp
    call Lrd_slow
    jmp L1384
    ALIGN 16
Lfcb_C3:
    or dl, 1
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1385
L1386:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1385:
    mov esi, ebp
    call Lrd_slow
    jmp L1386
    ALIGN 16
Lfcb_C4:
    or bh, 1
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1387
L1388:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1387:
    mov esi, ebp
    call Lrd_slow
    jmp L1388
    ALIGN 16
Lfcb_C5:
    or bl, 1
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1389
L1390:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1389:
    mov esi, ebp
    call Lrd_slow
    jmp L1390
    ALIGN 16
Lfcb_C6:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1391
L1392:
    movzx r10d, byte ptr [rdi+rsi]
    or r10b, 1
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1393
    mov byte ptr [rdi+rsi], r10b
L1394:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1395
L1396:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1391:
    call Lrd_slow
    jmp L1392
L1393:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1394
L1395:
    mov esi, ebp
    call Lrd_slow
    jmp L1396
    ALIGN 16
Lfcb_C7:
    or al, 1
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1397
L1398:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1397:
    mov esi, ebp
    call Lrd_slow
    jmp L1398
    ALIGN 16
Lfcb_C8:
    or ch, 2
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1399
L1400:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1399:
    mov esi, ebp
    call Lrd_slow
    jmp L1400
    ALIGN 16
Lfcb_C9:
    or cl, 2
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1401
L1402:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1401:
    mov esi, ebp
    call Lrd_slow
    jmp L1402
    ALIGN 16
Lfcb_CA:
    or dh, 2
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1403
L1404:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1403:
    mov esi, ebp
    call Lrd_slow
    jmp L1404
    ALIGN 16
Lfcb_CB:
    or dl, 2
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1405
L1406:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1405:
    mov esi, ebp
    call Lrd_slow
    jmp L1406
    ALIGN 16
Lfcb_CC:
    or bh, 2
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1407
L1408:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1407:
    mov esi, ebp
    call Lrd_slow
    jmp L1408
    ALIGN 16
Lfcb_CD:
    or bl, 2
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1409
L1410:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1409:
    mov esi, ebp
    call Lrd_slow
    jmp L1410
    ALIGN 16
Lfcb_CE:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1411
L1412:
    movzx r10d, byte ptr [rdi+rsi]
    or r10b, 2
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1413
    mov byte ptr [rdi+rsi], r10b
L1414:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1415
L1416:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1411:
    call Lrd_slow
    jmp L1412
L1413:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1414
L1415:
    mov esi, ebp
    call Lrd_slow
    jmp L1416
    ALIGN 16
Lfcb_CF:
    or al, 2
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1417
L1418:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1417:
    mov esi, ebp
    call Lrd_slow
    jmp L1418
    ALIGN 16
Lfcb_D0:
    or ch, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1419
L1420:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1419:
    mov esi, ebp
    call Lrd_slow
    jmp L1420
    ALIGN 16
Lfcb_D1:
    or cl, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1421
L1422:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1421:
    mov esi, ebp
    call Lrd_slow
    jmp L1422
    ALIGN 16
Lfcb_D2:
    or dh, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1423
L1424:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1423:
    mov esi, ebp
    call Lrd_slow
    jmp L1424
    ALIGN 16
Lfcb_D3:
    or dl, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1425
L1426:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1425:
    mov esi, ebp
    call Lrd_slow
    jmp L1426
    ALIGN 16
Lfcb_D4:
    or bh, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1427
L1428:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1427:
    mov esi, ebp
    call Lrd_slow
    jmp L1428
    ALIGN 16
Lfcb_D5:
    or bl, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1429
L1430:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1429:
    mov esi, ebp
    call Lrd_slow
    jmp L1430
    ALIGN 16
Lfcb_D6:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1431
L1432:
    movzx r10d, byte ptr [rdi+rsi]
    or r10b, 4
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1433
    mov byte ptr [rdi+rsi], r10b
L1434:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1435
L1436:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1431:
    call Lrd_slow
    jmp L1432
L1433:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1434
L1435:
    mov esi, ebp
    call Lrd_slow
    jmp L1436
    ALIGN 16
Lfcb_D7:
    or al, 4
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1437
L1438:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1437:
    mov esi, ebp
    call Lrd_slow
    jmp L1438
    ALIGN 16
Lfcb_D8:
    or ch, 8
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1439
L1440:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1439:
    mov esi, ebp
    call Lrd_slow
    jmp L1440
    ALIGN 16
Lfcb_D9:
    or cl, 8
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1441
L1442:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1441:
    mov esi, ebp
    call Lrd_slow
    jmp L1442
    ALIGN 16
Lfcb_DA:
    or dh, 8
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1443
L1444:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1443:
    mov esi, ebp
    call Lrd_slow
    jmp L1444
    ALIGN 16
Lfcb_DB:
    or dl, 8
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1445
L1446:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1445:
    mov esi, ebp
    call Lrd_slow
    jmp L1446
    ALIGN 16
Lfcb_DC:
    or bh, 8
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1447
L1448:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1447:
    mov esi, ebp
    call Lrd_slow
    jmp L1448
    ALIGN 16
Lfcb_DD:
    or bl, 8
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1449
L1450:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1449:
    mov esi, ebp
    call Lrd_slow
    jmp L1450
    ALIGN 16
Lfcb_DE:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1451
L1452:
    movzx r10d, byte ptr [rdi+rsi]
    or r10b, 8
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1453
    mov byte ptr [rdi+rsi], r10b
L1454:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1455
L1456:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1451:
    call Lrd_slow
    jmp L1452
L1453:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1454
L1455:
    mov esi, ebp
    call Lrd_slow
    jmp L1456
    ALIGN 16
Lfcb_DF:
    or al, 8
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1457
L1458:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1457:
    mov esi, ebp
    call Lrd_slow
    jmp L1458
    ALIGN 16
Lfcb_E0:
    or ch, 16
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1459
L1460:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1459:
    mov esi, ebp
    call Lrd_slow
    jmp L1460
    ALIGN 16
Lfcb_E1:
    or cl, 16
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1461
L1462:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1461:
    mov esi, ebp
    call Lrd_slow
    jmp L1462
    ALIGN 16
Lfcb_E2:
    or dh, 16
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1463
L1464:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1463:
    mov esi, ebp
    call Lrd_slow
    jmp L1464
    ALIGN 16
Lfcb_E3:
    or dl, 16
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1465
L1466:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1465:
    mov esi, ebp
    call Lrd_slow
    jmp L1466
    ALIGN 16
Lfcb_E4:
    or bh, 16
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1467
L1468:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1467:
    mov esi, ebp
    call Lrd_slow
    jmp L1468
    ALIGN 16
Lfcb_E5:
    or bl, 16
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1469
L1470:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1469:
    mov esi, ebp
    call Lrd_slow
    jmp L1470
    ALIGN 16
Lfcb_E6:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1471
L1472:
    movzx r10d, byte ptr [rdi+rsi]
    or r10b, 16
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1473
    mov byte ptr [rdi+rsi], r10b
L1474:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1475
L1476:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1471:
    call Lrd_slow
    jmp L1472
L1473:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1474
L1475:
    mov esi, ebp
    call Lrd_slow
    jmp L1476
    ALIGN 16
Lfcb_E7:
    or al, 16
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1477
L1478:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1477:
    mov esi, ebp
    call Lrd_slow
    jmp L1478
    ALIGN 16
Lfcb_E8:
    or ch, 32
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1479
L1480:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1479:
    mov esi, ebp
    call Lrd_slow
    jmp L1480
    ALIGN 16
Lfcb_E9:
    or cl, 32
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1481
L1482:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1481:
    mov esi, ebp
    call Lrd_slow
    jmp L1482
    ALIGN 16
Lfcb_EA:
    or dh, 32
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1483
L1484:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1483:
    mov esi, ebp
    call Lrd_slow
    jmp L1484
    ALIGN 16
Lfcb_EB:
    or dl, 32
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1485
L1486:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1485:
    mov esi, ebp
    call Lrd_slow
    jmp L1486
    ALIGN 16
Lfcb_EC:
    or bh, 32
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1487
L1488:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1487:
    mov esi, ebp
    call Lrd_slow
    jmp L1488
    ALIGN 16
Lfcb_ED:
    or bl, 32
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1489
L1490:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1489:
    mov esi, ebp
    call Lrd_slow
    jmp L1490
    ALIGN 16
Lfcb_EE:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1491
L1492:
    movzx r10d, byte ptr [rdi+rsi]
    or r10b, 32
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1493
    mov byte ptr [rdi+rsi], r10b
L1494:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1495
L1496:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1491:
    call Lrd_slow
    jmp L1492
L1493:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1494
L1495:
    mov esi, ebp
    call Lrd_slow
    jmp L1496
    ALIGN 16
Lfcb_EF:
    or al, 32
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1497
L1498:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1497:
    mov esi, ebp
    call Lrd_slow
    jmp L1498
    ALIGN 16
Lfcb_F0:
    or ch, 64
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1499
L1500:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1499:
    mov esi, ebp
    call Lrd_slow
    jmp L1500
    ALIGN 16
Lfcb_F1:
    or cl, 64
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1501
L1502:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1501:
    mov esi, ebp
    call Lrd_slow
    jmp L1502
    ALIGN 16
Lfcb_F2:
    or dh, 64
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1503
L1504:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1503:
    mov esi, ebp
    call Lrd_slow
    jmp L1504
    ALIGN 16
Lfcb_F3:
    or dl, 64
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1505
L1506:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1505:
    mov esi, ebp
    call Lrd_slow
    jmp L1506
    ALIGN 16
Lfcb_F4:
    or bh, 64
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1507
L1508:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1507:
    mov esi, ebp
    call Lrd_slow
    jmp L1508
    ALIGN 16
Lfcb_F5:
    or bl, 64
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1509
L1510:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1509:
    mov esi, ebp
    call Lrd_slow
    jmp L1510
    ALIGN 16
Lfcb_F6:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1511
L1512:
    movzx r10d, byte ptr [rdi+rsi]
    or r10b, 64
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1513
    mov byte ptr [rdi+rsi], r10b
L1514:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1515
L1516:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1511:
    call Lrd_slow
    jmp L1512
L1513:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1514
L1515:
    mov esi, ebp
    call Lrd_slow
    jmp L1516
    ALIGN 16
Lfcb_F7:
    or al, 64
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1517
L1518:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1517:
    mov esi, ebp
    call Lrd_slow
    jmp L1518
    ALIGN 16
Lfcb_F8:
    or ch, 128
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1519
L1520:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1519:
    mov esi, ebp
    call Lrd_slow
    jmp L1520
    ALIGN 16
Lfcb_F9:
    or cl, 128
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1521
L1522:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1521:
    mov esi, ebp
    call Lrd_slow
    jmp L1522
    ALIGN 16
Lfcb_FA:
    or dh, 128
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1523
L1524:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1523:
    mov esi, ebp
    call Lrd_slow
    jmp L1524
    ALIGN 16
Lfcb_FB:
    or dl, 128
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1525
L1526:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1525:
    mov esi, ebp
    call Lrd_slow
    jmp L1526
    ALIGN 16
Lfcb_FC:
    or bh, 128
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1527
L1528:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1527:
    mov esi, ebp
    call Lrd_slow
    jmp L1528
    ALIGN 16
Lfcb_FD:
    or bl, 128
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1529
L1530:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1529:
    mov esi, ebp
    call Lrd_slow
    jmp L1530
    ALIGN 16
Lfcb_FE:
    mov esi, ebx
    add r14, 4
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1531
L1532:
    movzx r10d, byte ptr [rdi+rsi]
    or r10b, 128
    add r14, 4
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1533
    mov byte ptr [rdi+rsi], r10b
L1534:
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1535
L1536:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1531:
    call Lrd_slow
    jmp L1532
L1533:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1534
L1535:
    mov esi, ebp
    call Lrd_slow
    jmp L1536
    ALIGN 16
Lfcb_FF:
    or al, 128
    cmp r14, r13
    jae Lslow_top
    test byte ptr [r15+rbp+498572], 3
    jnz Lslow_top
    dec r12
    js Lexit_budget
    add r14, 4
    mov esi, ebp
    shr esi, 12
    mov rdi, qword ptr [r15+rsi*8+572304]
    test rdi, rdi
    jz L1537
L1538:
    movzx esi, byte ptr [rdi+rbp]
    inc bp
    lea rdi, Ljt_f
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1537:
    mov esi, ebp
    call Lrd_slow
    jmp L1538
    ALIGN 16
Lc_00:
    jmp Lnext
    ALIGN 16
Lc_01:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1539
L1540:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1541
L1542:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1543
L1544:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1545
L1546:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    mov ecx, r11d
    jmp Lnext
L1539:
    call Ltick_slow4
    jmp L1540
L1541:
    call Lrd_slow
    jmp L1542
L1543:
    call Ltick_slow4
    jmp L1544
L1545:
    call Lrd_slow
    jmp L1546
    ALIGN 16
Lc_02:
    mov esi, ecx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1547
L1548:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1549
    mov byte ptr [rdi+rsi], al
L1550:
    jmp Lnext
L1547:
    call Ltick_slow4
    jmp L1548
L1549:
    mov byte ptr [rsp+40], al
    call Lwr_slow
    jmp L1550
    ALIGN 16
Lc_03:
    inc cx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1551
L1552:
    jmp Lnext
L1551:
    call Ltick_slow4
    jmp L1552
    ALIGN 16
Lc_04:
    inc ch
    movzx edi, ch
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573224]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lc_05:
    dec ch
    movzx edi, ch
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573480]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lc_06:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1553
L1554:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1555
L1556:
    mov ch, byte ptr [rdi+rsi]
    inc bp
    jmp Lnext
L1553:
    call Ltick_slow4
    jmp L1554
L1555:
    call Lrd_slow
    jmp L1556
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
    cmp r14, qword ptr [r15+572600]
    jae L1557
L1558:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1559
L1560:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1561
L1562:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1563
L1564:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    mov esi, r11d
    mov r10d, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1565
L1566:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1567
    mov byte ptr [rdi+rsi], r10b
L1568:
    lea esi, [r11+1]
    and esi, 65535
    mov r10d, r9d
    shr r10d, 8
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1569
L1570:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1571
    mov byte ptr [rdi+rsi], r10b
L1572:
    jmp Lnext
L1557:
    call Ltick_slow4
    jmp L1558
L1559:
    call Lrd_slow
    jmp L1560
L1561:
    call Ltick_slow4
    jmp L1562
L1563:
    call Lrd_slow
    jmp L1564
L1565:
    call Ltick_slow4
    jmp L1566
L1567:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1568
L1569:
    call Ltick_slow4
    jmp L1570
L1571:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1572
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
    cmp r14, qword ptr [r15+572600]
    jae L1573
L1574:
    jmp Lnext
L1573:
    call Ltick_slow4
    jmp L1574
    ALIGN 16
Lc_0A:
    mov esi, ecx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1575
L1576:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1577
L1578:
    mov al, byte ptr [rdi+rsi]
    jmp Lnext
L1575:
    call Ltick_slow4
    jmp L1576
L1577:
    call Lrd_slow
    jmp L1578
    ALIGN 16
Lc_0B:
    dec cx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1579
L1580:
    jmp Lnext
L1579:
    call Ltick_slow4
    jmp L1580
    ALIGN 16
Lc_0C:
    inc cl
    movzx edi, cl
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573224]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lc_0D:
    dec cl
    movzx edi, cl
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573480]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lc_0E:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1581
L1582:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1583
L1584:
    mov cl, byte ptr [rdi+rsi]
    inc bp
    jmp Lnext
L1581:
    call Ltick_slow4
    jmp L1582
L1583:
    call Lrd_slow
    jmp L1584
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
    cmp r14, qword ptr [r15+572600]
    jae L1585
L1586:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1587
L1588:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
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
    cmp byte ptr [r15+572675], 0
    jne L1589
    mov qword ptr [r15+40], r14
    movzx edi, word ptr [r15+572672]
    add edi, r14d
    mov word ptr [r15+65858], di
L1589:
    sub rsp, 32
    mov rcx, r15
    mov edx, 16
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
    mov r13, qword ptr [r15+572624]
    jmp Lnext
L1585:
    call Ltick_slow4
    jmp L1586
L1587:
    call Lrd_slow
    jmp L1588
    ALIGN 16
Lc_11:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1590
L1591:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1592
L1593:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1594
L1595:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1596
L1597:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    mov edx, r11d
    jmp Lnext
L1590:
    call Ltick_slow4
    jmp L1591
L1592:
    call Lrd_slow
    jmp L1593
L1594:
    call Ltick_slow4
    jmp L1595
L1596:
    call Lrd_slow
    jmp L1597
    ALIGN 16
Lc_12:
    mov esi, edx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1598
L1599:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1600
    mov byte ptr [rdi+rsi], al
L1601:
    jmp Lnext
L1598:
    call Ltick_slow4
    jmp L1599
L1600:
    mov byte ptr [rsp+40], al
    call Lwr_slow
    jmp L1601
    ALIGN 16
Lc_13:
    inc dx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1602
L1603:
    jmp Lnext
L1602:
    call Ltick_slow4
    jmp L1603
    ALIGN 16
Lc_14:
    inc dh
    movzx edi, dh
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573224]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lc_15:
    dec dh
    movzx edi, dh
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573480]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lc_16:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1604
L1605:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1606
L1607:
    mov dh, byte ptr [rdi+rsi]
    inc bp
    jmp Lnext
L1604:
    call Ltick_slow4
    jmp L1605
L1606:
    call Lrd_slow
    jmp L1607
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
    cmp r14, qword ptr [r15+572600]
    jae L1608
L1609:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1610
L1611:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    movsx r10d, r10b
    add ebp, r10d
    and ebp, 65535
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1613
L1614:
L1612:
    jmp Lnext
L1608:
    call Ltick_slow4
    jmp L1609
L1610:
    call Lrd_slow
    jmp L1611
L1613:
    call Ltick_slow4
    jmp L1614
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
    cmp r14, qword ptr [r15+572600]
    jae L1615
L1616:
    jmp Lnext
L1615:
    call Ltick_slow4
    jmp L1616
    ALIGN 16
Lc_1A:
    mov esi, edx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1617
L1618:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1619
L1620:
    mov al, byte ptr [rdi+rsi]
    jmp Lnext
L1617:
    call Ltick_slow4
    jmp L1618
L1619:
    call Lrd_slow
    jmp L1620
    ALIGN 16
Lc_1B:
    dec dx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1621
L1622:
    jmp Lnext
L1621:
    call Ltick_slow4
    jmp L1622
    ALIGN 16
Lc_1C:
    inc dl
    movzx edi, dl
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573224]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lc_1D:
    dec dl
    movzx edi, dl
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573480]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lc_1E:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1623
L1624:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1625
L1626:
    mov dl, byte ptr [rdi+rsi]
    inc bp
    jmp Lnext
L1623:
    call Ltick_slow4
    jmp L1624
L1625:
    call Lrd_slow
    jmp L1626
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
    cmp r14, qword ptr [r15+572600]
    jae L1627
L1628:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1629
L1630:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    test r8b, 128
    jnz L1631
    movsx r10d, r10b
    add ebp, r10d
    and ebp, 65535
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1632
L1633:
L1631:
    jmp Lnext
L1627:
    call Ltick_slow4
    jmp L1628
L1629:
    call Lrd_slow
    jmp L1630
L1632:
    call Ltick_slow4
    jmp L1633
    ALIGN 16
Lc_21:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1634
L1635:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1636
L1637:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1638
L1639:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1640
L1641:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    mov ebx, r11d
    jmp Lnext
L1634:
    call Ltick_slow4
    jmp L1635
L1636:
    call Lrd_slow
    jmp L1637
L1638:
    call Ltick_slow4
    jmp L1639
L1640:
    call Lrd_slow
    jmp L1641
    ALIGN 16
Lc_22:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1642
L1643:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1644
    mov byte ptr [rdi+rsi], al
L1645:
    lea ebx, [rsi+1]
    and ebx, 65535
    jmp Lnext
L1642:
    call Ltick_slow4
    jmp L1643
L1644:
    mov byte ptr [rsp+40], al
    call Lwr_slow
    jmp L1645
    ALIGN 16
Lc_23:
    inc bx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1646
L1647:
    jmp Lnext
L1646:
    call Ltick_slow4
    jmp L1647
    ALIGN 16
Lc_24:
    inc bh
    movzx edi, bh
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573224]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lc_25:
    dec bh
    movzx edi, bh
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573480]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lc_26:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1648
L1649:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1650
L1651:
    mov bh, byte ptr [rdi+rsi]
    inc bp
    jmp Lnext
L1648:
    call Ltick_slow4
    jmp L1649
L1650:
    call Lrd_slow
    jmp L1651
    ALIGN 16
Lc_27:
    movzx edi, al
    mov esi, r8d
    and esi, 16
    test r8b, 64
    jz L1652
    test r8b, 32
    jz L1653
    sub edi, 6
L1653:
    test esi, esi
    jz L1657
    sub edi, 96
    jmp L1657
L1652:
    test esi, esi
    jnz L1654
    cmp edi, 153
    jbe L1655
L1654:
    add edi, 96
    mov esi, 16
L1655:
    test r8b, 32
    jnz L1656
    mov r10d, edi
    and r10d, 15
    cmp r10d, 9
    jbe L1657
L1656:
    add edi, 6
L1657:
    mov eax, edi
    and r8d, 64
    or r8d, esi
    test al, al
    jnz L1658
    or r8d, 128
L1658:
    jmp Lnext
    ALIGN 16
Lc_28:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1659
L1660:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1661
L1662:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    test r8b, 128
    jz L1663
    movsx r10d, r10b
    add ebp, r10d
    and ebp, 65535
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1664
L1665:
L1663:
    jmp Lnext
L1659:
    call Ltick_slow4
    jmp L1660
L1661:
    call Lrd_slow
    jmp L1662
L1664:
    call Ltick_slow4
    jmp L1665
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
    cmp r14, qword ptr [r15+572600]
    jae L1666
L1667:
    jmp Lnext
L1666:
    call Ltick_slow4
    jmp L1667
    ALIGN 16
Lc_2A:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1668
L1669:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1670
L1671:
    mov al, byte ptr [rdi+rsi]
    lea ebx, [rsi+1]
    and ebx, 65535
    jmp Lnext
L1668:
    call Ltick_slow4
    jmp L1669
L1670:
    call Lrd_slow
    jmp L1671
    ALIGN 16
Lc_2B:
    dec bx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1672
L1673:
    jmp Lnext
L1672:
    call Ltick_slow4
    jmp L1673
    ALIGN 16
Lc_2C:
    inc bl
    movzx edi, bl
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573224]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lc_2D:
    dec bl
    movzx edi, bl
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573480]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lc_2E:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1674
L1675:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1676
L1677:
    mov bl, byte ptr [rdi+rsi]
    inc bp
    jmp Lnext
L1674:
    call Ltick_slow4
    jmp L1675
L1676:
    call Lrd_slow
    jmp L1677
    ALIGN 16
Lc_2F:
    not al
    or r8d, 96
    jmp Lnext
    ALIGN 16
Lc_30:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1678
L1679:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1680
L1681:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    test r8b, 16
    jnz L1682
    movsx r10d, r10b
    add ebp, r10d
    and ebp, 65535
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1683
L1684:
L1682:
    jmp Lnext
L1678:
    call Ltick_slow4
    jmp L1679
L1680:
    call Lrd_slow
    jmp L1681
L1683:
    call Ltick_slow4
    jmp L1684
    ALIGN 16
Lc_31:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1685
L1686:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1687
L1688:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1689
L1690:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1691
L1692:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    mov r9d, r11d
    jmp Lnext
L1685:
    call Ltick_slow4
    jmp L1686
L1687:
    call Lrd_slow
    jmp L1688
L1689:
    call Ltick_slow4
    jmp L1690
L1691:
    call Lrd_slow
    jmp L1692
    ALIGN 16
Lc_32:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1693
L1694:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1695
    mov byte ptr [rdi+rsi], al
L1696:
    lea ebx, [rsi-1]
    and ebx, 65535
    jmp Lnext
L1693:
    call Ltick_slow4
    jmp L1694
L1695:
    mov byte ptr [rsp+40], al
    call Lwr_slow
    jmp L1696
    ALIGN 16
Lc_33:
    inc r9w
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1697
L1698:
    jmp Lnext
L1697:
    call Ltick_slow4
    jmp L1698
    ALIGN 16
Lc_34:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1699
L1700:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1701
L1702:
    movzx r10d, byte ptr [rdi+rsi]
    inc r10b
    movzx edi, r10b
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573224]
    or r8d, edi
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1703
L1704:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1705
    mov byte ptr [rdi+rsi], r10b
L1706:
    jmp Lnext
L1699:
    call Ltick_slow4
    jmp L1700
L1701:
    call Lrd_slow
    jmp L1702
L1703:
    call Ltick_slow4
    jmp L1704
L1705:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1706
    ALIGN 16
Lc_35:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1707
L1708:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1709
L1710:
    movzx r10d, byte ptr [rdi+rsi]
    dec r10b
    movzx edi, r10b
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573480]
    or r8d, edi
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1711
L1712:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1713
    mov byte ptr [rdi+rsi], r10b
L1714:
    jmp Lnext
L1707:
    call Ltick_slow4
    jmp L1708
L1709:
    call Lrd_slow
    jmp L1710
L1711:
    call Ltick_slow4
    jmp L1712
L1713:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1714
    ALIGN 16
Lc_36:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1715
L1716:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1717
L1718:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1719
L1720:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1721
    mov byte ptr [rdi+rsi], r10b
L1722:
    jmp Lnext
L1715:
    call Ltick_slow4
    jmp L1716
L1717:
    call Lrd_slow
    jmp L1718
L1719:
    call Ltick_slow4
    jmp L1720
L1721:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1722
    ALIGN 16
Lc_37:
    and r8d, 128
    or r8d, 16
    jmp Lnext
    ALIGN 16
Lc_38:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1723
L1724:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1725
L1726:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    test r8b, 16
    jz L1727
    movsx r10d, r10b
    add ebp, r10d
    and ebp, 65535
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1728
L1729:
L1727:
    jmp Lnext
L1723:
    call Ltick_slow4
    jmp L1724
L1725:
    call Lrd_slow
    jmp L1726
L1728:
    call Ltick_slow4
    jmp L1729
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
    cmp r14, qword ptr [r15+572600]
    jae L1730
L1731:
    jmp Lnext
L1730:
    call Ltick_slow4
    jmp L1731
    ALIGN 16
Lc_3A:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1732
L1733:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1734
L1735:
    mov al, byte ptr [rdi+rsi]
    lea ebx, [rsi-1]
    and ebx, 65535
    jmp Lnext
L1732:
    call Ltick_slow4
    jmp L1733
L1734:
    call Lrd_slow
    jmp L1735
    ALIGN 16
Lc_3B:
    dec r9w
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1736
L1737:
    jmp Lnext
L1736:
    call Ltick_slow4
    jmp L1737
    ALIGN 16
Lc_3C:
    inc al
    movzx edi, al
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573224]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lc_3D:
    dec al
    movzx edi, al
    and r8d, 16
    movzx edi, byte ptr [r15+rdi+573480]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lc_3E:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1738
L1739:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1740
L1741:
    mov al, byte ptr [rdi+rsi]
    inc bp
    jmp Lnext
L1738:
    call Ltick_slow4
    jmp L1739
L1740:
    call Lrd_slow
    jmp L1741
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
    cmp r14, qword ptr [r15+572600]
    jae L1742
L1743:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1744
L1745:
    mov ch, byte ptr [rdi+rsi]
    jmp Lnext
L1742:
    call Ltick_slow4
    jmp L1743
L1744:
    call Lrd_slow
    jmp L1745
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
    cmp r14, qword ptr [r15+572600]
    jae L1746
L1747:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1748
L1749:
    mov cl, byte ptr [rdi+rsi]
    jmp Lnext
L1746:
    call Ltick_slow4
    jmp L1747
L1748:
    call Lrd_slow
    jmp L1749
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
    cmp r14, qword ptr [r15+572600]
    jae L1750
L1751:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1752
L1753:
    mov dh, byte ptr [rdi+rsi]
    jmp Lnext
L1750:
    call Ltick_slow4
    jmp L1751
L1752:
    call Lrd_slow
    jmp L1753
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
    cmp r14, qword ptr [r15+572600]
    jae L1754
L1755:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1756
L1757:
    mov dl, byte ptr [rdi+rsi]
    jmp Lnext
L1754:
    call Ltick_slow4
    jmp L1755
L1756:
    call Lrd_slow
    jmp L1757
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
    cmp r14, qword ptr [r15+572600]
    jae L1758
L1759:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1760
L1761:
    mov bh, byte ptr [rdi+rsi]
    jmp Lnext
L1758:
    call Ltick_slow4
    jmp L1759
L1760:
    call Lrd_slow
    jmp L1761
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
    cmp r14, qword ptr [r15+572600]
    jae L1762
L1763:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1764
L1765:
    mov bl, byte ptr [rdi+rsi]
    jmp Lnext
L1762:
    call Ltick_slow4
    jmp L1763
L1764:
    call Lrd_slow
    jmp L1765
    ALIGN 16
Lc_6F:
    mov bl, al
    jmp Lnext
    ALIGN 16
Lc_70:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1766
L1767:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1768
    mov byte ptr [rdi+rsi], ch
L1769:
    jmp Lnext
L1766:
    call Ltick_slow4
    jmp L1767
L1768:
    mov byte ptr [rsp+40], ch
    call Lwr_slow
    jmp L1769
    ALIGN 16
Lc_71:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1770
L1771:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1772
    mov byte ptr [rdi+rsi], cl
L1773:
    jmp Lnext
L1770:
    call Ltick_slow4
    jmp L1771
L1772:
    mov byte ptr [rsp+40], cl
    call Lwr_slow
    jmp L1773
    ALIGN 16
Lc_72:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1774
L1775:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1776
    mov byte ptr [rdi+rsi], dh
L1777:
    jmp Lnext
L1774:
    call Ltick_slow4
    jmp L1775
L1776:
    mov byte ptr [rsp+40], dh
    call Lwr_slow
    jmp L1777
    ALIGN 16
Lc_73:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1778
L1779:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1780
    mov byte ptr [rdi+rsi], dl
L1781:
    jmp Lnext
L1778:
    call Ltick_slow4
    jmp L1779
L1780:
    mov byte ptr [rsp+40], dl
    call Lwr_slow
    jmp L1781
    ALIGN 16
Lc_74:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1782
L1783:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1784
    mov byte ptr [rdi+rsi], bh
L1785:
    jmp Lnext
L1782:
    call Ltick_slow4
    jmp L1783
L1784:
    mov byte ptr [rsp+40], bh
    call Lwr_slow
    jmp L1785
    ALIGN 16
Lc_75:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1786
L1787:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1788
    mov byte ptr [rdi+rsi], bl
L1789:
    jmp Lnext
L1786:
    call Ltick_slow4
    jmp L1787
L1788:
    mov byte ptr [rsp+40], bl
    call Lwr_slow
    jmp L1789
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
    cmp byte ptr [r15+572675], 0
    jne L1790
    mov qword ptr [r15+40], r14
    movzx edi, word ptr [r15+572672]
    add edi, r14d
    mov word ptr [r15+65858], di
L1790:
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
    mov r13, qword ptr [r15+572624]
    jmp Lnext
    ALIGN 16
Lc_77:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1791
L1792:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1793
    mov byte ptr [rdi+rsi], al
L1794:
    jmp Lnext
L1791:
    call Ltick_slow4
    jmp L1792
L1793:
    mov byte ptr [rsp+40], al
    call Lwr_slow
    jmp L1794
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
    cmp r14, qword ptr [r15+572600]
    jae L1795
L1796:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1797
L1798:
    mov al, byte ptr [rdi+rsi]
    jmp Lnext
L1795:
    call Ltick_slow4
    jmp L1796
L1797:
    call Lrd_slow
    jmp L1798
    ALIGN 16
Lc_7F:
    jmp Lnext
    ALIGN 16
Lc_80:
    add al, ch
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572712]
    jmp Lnext
    ALIGN 16
Lc_81:
    add al, cl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572712]
    jmp Lnext
    ALIGN 16
Lc_82:
    add al, dh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572712]
    jmp Lnext
    ALIGN 16
Lc_83:
    add al, dl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572712]
    jmp Lnext
    ALIGN 16
Lc_84:
    add al, bh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572712]
    jmp Lnext
    ALIGN 16
Lc_85:
    add al, bl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572712]
    jmp Lnext
    ALIGN 16
Lc_86:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1799
L1800:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1801
L1802:
    movzx r10d, byte ptr [rdi+rsi]
    add al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572712]
    jmp Lnext
L1799:
    call Ltick_slow4
    jmp L1800
L1801:
    call Lrd_slow
    jmp L1802
    ALIGN 16
Lc_87:
    add al, al
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572712]
    jmp Lnext
    ALIGN 16
Lc_88:
    bt r8d, 4
    adc al, ch
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572712]
    jmp Lnext
    ALIGN 16
Lc_89:
    bt r8d, 4
    adc al, cl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572712]
    jmp Lnext
    ALIGN 16
Lc_8A:
    bt r8d, 4
    adc al, dh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572712]
    jmp Lnext
    ALIGN 16
Lc_8B:
    bt r8d, 4
    adc al, dl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572712]
    jmp Lnext
    ALIGN 16
Lc_8C:
    bt r8d, 4
    adc al, bh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572712]
    jmp Lnext
    ALIGN 16
Lc_8D:
    bt r8d, 4
    adc al, bl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572712]
    jmp Lnext
    ALIGN 16
Lc_8E:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1803
L1804:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1805
L1806:
    movzx r10d, byte ptr [rdi+rsi]
    bt r8d, 4
    adc al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572712]
    jmp Lnext
L1803:
    call Ltick_slow4
    jmp L1804
L1805:
    call Lrd_slow
    jmp L1806
    ALIGN 16
Lc_8F:
    bt r8d, 4
    adc al, al
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572712]
    jmp Lnext
    ALIGN 16
Lc_90:
    sub al, ch
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    jmp Lnext
    ALIGN 16
Lc_91:
    sub al, cl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    jmp Lnext
    ALIGN 16
Lc_92:
    sub al, dh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    jmp Lnext
    ALIGN 16
Lc_93:
    sub al, dl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    jmp Lnext
    ALIGN 16
Lc_94:
    sub al, bh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    jmp Lnext
    ALIGN 16
Lc_95:
    sub al, bl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    jmp Lnext
    ALIGN 16
Lc_96:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1807
L1808:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1809
L1810:
    movzx r10d, byte ptr [rdi+rsi]
    sub al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    jmp Lnext
L1807:
    call Ltick_slow4
    jmp L1808
L1809:
    call Lrd_slow
    jmp L1810
    ALIGN 16
Lc_97:
    sub al, al
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    jmp Lnext
    ALIGN 16
Lc_98:
    bt r8d, 4
    sbb al, ch
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    jmp Lnext
    ALIGN 16
Lc_99:
    bt r8d, 4
    sbb al, cl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    jmp Lnext
    ALIGN 16
Lc_9A:
    bt r8d, 4
    sbb al, dh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    jmp Lnext
    ALIGN 16
Lc_9B:
    bt r8d, 4
    sbb al, dl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    jmp Lnext
    ALIGN 16
Lc_9C:
    bt r8d, 4
    sbb al, bh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    jmp Lnext
    ALIGN 16
Lc_9D:
    bt r8d, 4
    sbb al, bl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    jmp Lnext
    ALIGN 16
Lc_9E:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1811
L1812:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1813
L1814:
    movzx r10d, byte ptr [rdi+rsi]
    bt r8d, 4
    sbb al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    jmp Lnext
L1811:
    call Ltick_slow4
    jmp L1812
L1813:
    call Lrd_slow
    jmp L1814
    ALIGN 16
Lc_9F:
    bt r8d, 4
    sbb al, al
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    jmp Lnext
    ALIGN 16
Lc_A0:
    and al, ch
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573992]
    jmp Lnext
    ALIGN 16
Lc_A1:
    and al, cl
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573992]
    jmp Lnext
    ALIGN 16
Lc_A2:
    and al, dh
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573992]
    jmp Lnext
    ALIGN 16
Lc_A3:
    and al, dl
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573992]
    jmp Lnext
    ALIGN 16
Lc_A4:
    and al, bh
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573992]
    jmp Lnext
    ALIGN 16
Lc_A5:
    and al, bl
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573992]
    jmp Lnext
    ALIGN 16
Lc_A6:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1815
L1816:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1817
L1818:
    movzx r10d, byte ptr [rdi+rsi]
    and al, r10b
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573992]
    jmp Lnext
L1815:
    call Ltick_slow4
    jmp L1816
L1817:
    call Lrd_slow
    jmp L1818
    ALIGN 16
Lc_A7:
    and al, al
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573992]
    jmp Lnext
    ALIGN 16
Lc_A8:
    xor al, ch
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573736]
    jmp Lnext
    ALIGN 16
Lc_A9:
    xor al, cl
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573736]
    jmp Lnext
    ALIGN 16
Lc_AA:
    xor al, dh
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573736]
    jmp Lnext
    ALIGN 16
Lc_AB:
    xor al, dl
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573736]
    jmp Lnext
    ALIGN 16
Lc_AC:
    xor al, bh
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573736]
    jmp Lnext
    ALIGN 16
Lc_AD:
    xor al, bl
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573736]
    jmp Lnext
    ALIGN 16
Lc_AE:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1819
L1820:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1821
L1822:
    movzx r10d, byte ptr [rdi+rsi]
    xor al, r10b
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573736]
    jmp Lnext
L1819:
    call Ltick_slow4
    jmp L1820
L1821:
    call Lrd_slow
    jmp L1822
    ALIGN 16
Lc_AF:
    xor al, al
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573736]
    jmp Lnext
    ALIGN 16
Lc_B0:
    or al, ch
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573736]
    jmp Lnext
    ALIGN 16
Lc_B1:
    or al, cl
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573736]
    jmp Lnext
    ALIGN 16
Lc_B2:
    or al, dh
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573736]
    jmp Lnext
    ALIGN 16
Lc_B3:
    or al, dl
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573736]
    jmp Lnext
    ALIGN 16
Lc_B4:
    or al, bh
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573736]
    jmp Lnext
    ALIGN 16
Lc_B5:
    or al, bl
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573736]
    jmp Lnext
    ALIGN 16
Lc_B6:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1823
L1824:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1825
L1826:
    movzx r10d, byte ptr [rdi+rsi]
    or al, r10b
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573736]
    jmp Lnext
L1823:
    call Ltick_slow4
    jmp L1824
L1825:
    call Lrd_slow
    jmp L1826
    ALIGN 16
Lc_B7:
    or al, al
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573736]
    jmp Lnext
    ALIGN 16
Lc_B8:
    cmp al, ch
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    jmp Lnext
    ALIGN 16
Lc_B9:
    cmp al, cl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    jmp Lnext
    ALIGN 16
Lc_BA:
    cmp al, dh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    jmp Lnext
    ALIGN 16
Lc_BB:
    cmp al, dl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    jmp Lnext
    ALIGN 16
Lc_BC:
    cmp al, bh
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    jmp Lnext
    ALIGN 16
Lc_BD:
    cmp al, bl
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    jmp Lnext
    ALIGN 16
Lc_BE:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1827
L1828:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1829
L1830:
    movzx r10d, byte ptr [rdi+rsi]
    cmp al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    jmp Lnext
L1827:
    call Ltick_slow4
    jmp L1828
L1829:
    call Lrd_slow
    jmp L1830
    ALIGN 16
Lc_BF:
    cmp al, al
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    jmp Lnext
    ALIGN 16
Lc_C0:
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1831
L1832:
    test r8b, 128
    jnz L1833
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1834
L1835:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1836
L1837:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1838
L1839:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1840
L1841:
    movzx r11d, byte ptr [rdi+rsi]
    inc r9w
    shl r11d, 8
    or r11d, r10d
    mov ebp, r11d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1842
L1843:
L1833:
    jmp Lnext
L1831:
    call Ltick_slow4
    jmp L1832
L1834:
    call Ltick_slow4
    jmp L1835
L1836:
    call Lrd_slow
    jmp L1837
L1838:
    call Ltick_slow4
    jmp L1839
L1840:
    call Lrd_slow
    jmp L1841
L1842:
    call Ltick_slow4
    jmp L1843
    ALIGN 16
Lc_C1:
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1844
L1845:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1846
L1847:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1848
L1849:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1850
L1851:
    movzx r11d, byte ptr [rdi+rsi]
    inc r9w
    shl r11d, 8
    or r11d, r10d
    mov ecx, r11d
    jmp Lnext
L1844:
    call Ltick_slow4
    jmp L1845
L1846:
    call Lrd_slow
    jmp L1847
L1848:
    call Ltick_slow4
    jmp L1849
L1850:
    call Lrd_slow
    jmp L1851
    ALIGN 16
Lc_C2:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1852
L1853:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1854
L1855:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1856
L1857:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1858
L1859:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    test r8b, 128
    jnz L1860
    mov ebp, r11d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1861
L1862:
L1860:
    jmp Lnext
L1852:
    call Ltick_slow4
    jmp L1853
L1854:
    call Lrd_slow
    jmp L1855
L1856:
    call Ltick_slow4
    jmp L1857
L1858:
    call Lrd_slow
    jmp L1859
L1861:
    call Ltick_slow4
    jmp L1862
    ALIGN 16
Lc_C3:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1863
L1864:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1865
L1866:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1867
L1868:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1869
L1870:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    mov ebp, r11d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1872
L1873:
L1871:
    jmp Lnext
L1863:
    call Ltick_slow4
    jmp L1864
L1865:
    call Lrd_slow
    jmp L1866
L1867:
    call Ltick_slow4
    jmp L1868
L1869:
    call Lrd_slow
    jmp L1870
L1872:
    call Ltick_slow4
    jmp L1873
    ALIGN 16
Lc_C4:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1874
L1875:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1876
L1877:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1878
L1879:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1880
L1881:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    test r8b, 128
    jnz L1882
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1883
L1884:
    mov dword ptr [rsp+48], r11d
    mov r11d, ebp
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1885
L1886:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1887
    mov byte ptr [rdi+rsi], r10b
L1888:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1889
L1890:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1891
    mov byte ptr [rdi+rsi], r11b
L1892:
    mov ebp, dword ptr [rsp+48]
L1882:
    jmp Lnext
L1874:
    call Ltick_slow4
    jmp L1875
L1876:
    call Lrd_slow
    jmp L1877
L1878:
    call Ltick_slow4
    jmp L1879
L1880:
    call Lrd_slow
    jmp L1881
L1883:
    call Ltick_slow4
    jmp L1884
L1885:
    call Ltick_slow4
    jmp L1886
L1887:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1888
L1889:
    call Ltick_slow4
    jmp L1890
L1891:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L1892
    ALIGN 16
Lc_C5:
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1893
L1894:
    mov r11d, ecx
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1895
L1896:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1897
    mov byte ptr [rdi+rsi], r10b
L1898:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1899
L1900:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1901
    mov byte ptr [rdi+rsi], r11b
L1902:
    jmp Lnext
L1893:
    call Ltick_slow4
    jmp L1894
L1895:
    call Ltick_slow4
    jmp L1896
L1897:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1898
L1899:
    call Ltick_slow4
    jmp L1900
L1901:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L1902
    ALIGN 16
Lc_C6:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1903
L1904:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1905
L1906:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    add al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572712]
    jmp Lnext
L1903:
    call Ltick_slow4
    jmp L1904
L1905:
    call Lrd_slow
    jmp L1906
    ALIGN 16
Lc_C7:
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1907
L1908:
    mov r11d, ebp
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1909
L1910:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1911
    mov byte ptr [rdi+rsi], r10b
L1912:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1913
L1914:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1915
    mov byte ptr [rdi+rsi], r11b
L1916:
    mov ebp, 0
    jmp Lnext
L1907:
    call Ltick_slow4
    jmp L1908
L1909:
    call Ltick_slow4
    jmp L1910
L1911:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1912
L1913:
    call Ltick_slow4
    jmp L1914
L1915:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L1916
    ALIGN 16
Lc_C8:
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1917
L1918:
    test r8b, 128
    jz L1919
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1920
L1921:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1922
L1923:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1924
L1925:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1926
L1927:
    movzx r11d, byte ptr [rdi+rsi]
    inc r9w
    shl r11d, 8
    or r11d, r10d
    mov ebp, r11d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1928
L1929:
L1919:
    jmp Lnext
L1917:
    call Ltick_slow4
    jmp L1918
L1920:
    call Ltick_slow4
    jmp L1921
L1922:
    call Lrd_slow
    jmp L1923
L1924:
    call Ltick_slow4
    jmp L1925
L1926:
    call Lrd_slow
    jmp L1927
L1928:
    call Ltick_slow4
    jmp L1929
    ALIGN 16
Lc_C9:
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1930
L1931:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1932
L1933:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1934
L1935:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1936
L1937:
    movzx r11d, byte ptr [rdi+rsi]
    inc r9w
    shl r11d, 8
    or r11d, r10d
    mov ebp, r11d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1938
L1939:
    jmp Lnext
L1930:
    call Ltick_slow4
    jmp L1931
L1932:
    call Lrd_slow
    jmp L1933
L1934:
    call Ltick_slow4
    jmp L1935
L1936:
    call Lrd_slow
    jmp L1937
L1938:
    call Ltick_slow4
    jmp L1939
    ALIGN 16
Lc_CA:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1940
L1941:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1942
L1943:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1944
L1945:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1946
L1947:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    test r8b, 128
    jz L1948
    mov ebp, r11d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1949
L1950:
L1948:
    jmp Lnext
L1940:
    call Ltick_slow4
    jmp L1941
L1942:
    call Lrd_slow
    jmp L1943
L1944:
    call Ltick_slow4
    jmp L1945
L1946:
    call Lrd_slow
    jmp L1947
L1949:
    call Ltick_slow4
    jmp L1950
    ALIGN 16
Lc_CB:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1951
L1952:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1953
L1954:
    movzx esi, byte ptr [rdi+rsi]
    inc bp
    lea rdi, Ljt_ccb
    movsxd rsi, dword ptr [rdi+rsi*4]
    add rsi, rdi
    jmp rsi
L1951:
    call Ltick_slow4
    jmp L1952
L1953:
    call Lrd_slow
    jmp L1954
    ALIGN 16
Lc_CC:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1955
L1956:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1957
L1958:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1959
L1960:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1961
L1962:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    test r8b, 128
    jz L1963
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1964
L1965:
    mov dword ptr [rsp+48], r11d
    mov r11d, ebp
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1966
L1967:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1968
    mov byte ptr [rdi+rsi], r10b
L1969:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1970
L1971:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1972
    mov byte ptr [rdi+rsi], r11b
L1973:
    mov ebp, dword ptr [rsp+48]
L1963:
    jmp Lnext
L1955:
    call Ltick_slow4
    jmp L1956
L1957:
    call Lrd_slow
    jmp L1958
L1959:
    call Ltick_slow4
    jmp L1960
L1961:
    call Lrd_slow
    jmp L1962
L1964:
    call Ltick_slow4
    jmp L1965
L1966:
    call Ltick_slow4
    jmp L1967
L1968:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1969
L1970:
    call Ltick_slow4
    jmp L1971
L1972:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L1973
    ALIGN 16
Lc_CD:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1974
L1975:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1976
L1977:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1978
L1979:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1980
L1981:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1983
L1984:
    mov dword ptr [rsp+48], r11d
    mov r11d, ebp
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1985
L1986:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1987
    mov byte ptr [rdi+rsi], r10b
L1988:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1989
L1990:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L1991
    mov byte ptr [rdi+rsi], r11b
L1992:
    mov ebp, dword ptr [rsp+48]
L1982:
    jmp Lnext
L1974:
    call Ltick_slow4
    jmp L1975
L1976:
    call Lrd_slow
    jmp L1977
L1978:
    call Ltick_slow4
    jmp L1979
L1980:
    call Lrd_slow
    jmp L1981
L1983:
    call Ltick_slow4
    jmp L1984
L1985:
    call Ltick_slow4
    jmp L1986
L1987:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L1988
L1989:
    call Ltick_slow4
    jmp L1990
L1991:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L1992
    ALIGN 16
Lc_CE:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1993
L1994:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L1995
L1996:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    bt r8d, 4
    adc al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572712]
    jmp Lnext
L1993:
    call Ltick_slow4
    jmp L1994
L1995:
    call Lrd_slow
    jmp L1996
    ALIGN 16
Lc_CF:
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1997
L1998:
    mov r11d, ebp
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L1999
L2000:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2001
    mov byte ptr [rdi+rsi], r10b
L2002:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2003
L2004:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2005
    mov byte ptr [rdi+rsi], r11b
L2006:
    mov ebp, 8
    jmp Lnext
L1997:
    call Ltick_slow4
    jmp L1998
L1999:
    call Ltick_slow4
    jmp L2000
L2001:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2002
L2003:
    call Ltick_slow4
    jmp L2004
L2005:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L2006
    ALIGN 16
Lc_D0:
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2007
L2008:
    test r8b, 16
    jnz L2009
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2010
L2011:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2012
L2013:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2014
L2015:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2016
L2017:
    movzx r11d, byte ptr [rdi+rsi]
    inc r9w
    shl r11d, 8
    or r11d, r10d
    mov ebp, r11d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2018
L2019:
L2009:
    jmp Lnext
L2007:
    call Ltick_slow4
    jmp L2008
L2010:
    call Ltick_slow4
    jmp L2011
L2012:
    call Lrd_slow
    jmp L2013
L2014:
    call Ltick_slow4
    jmp L2015
L2016:
    call Lrd_slow
    jmp L2017
L2018:
    call Ltick_slow4
    jmp L2019
    ALIGN 16
Lc_D1:
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2020
L2021:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2022
L2023:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2024
L2025:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2026
L2027:
    movzx r11d, byte ptr [rdi+rsi]
    inc r9w
    shl r11d, 8
    or r11d, r10d
    mov edx, r11d
    jmp Lnext
L2020:
    call Ltick_slow4
    jmp L2021
L2022:
    call Lrd_slow
    jmp L2023
L2024:
    call Ltick_slow4
    jmp L2025
L2026:
    call Lrd_slow
    jmp L2027
    ALIGN 16
Lc_D2:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2028
L2029:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2030
L2031:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2032
L2033:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2034
L2035:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    test r8b, 16
    jnz L2036
    mov ebp, r11d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2037
L2038:
L2036:
    jmp Lnext
L2028:
    call Ltick_slow4
    jmp L2029
L2030:
    call Lrd_slow
    jmp L2031
L2032:
    call Ltick_slow4
    jmp L2033
L2034:
    call Lrd_slow
    jmp L2035
L2037:
    call Ltick_slow4
    jmp L2038
    ALIGN 16
Lc_D3:
    jmp Lnext
    ALIGN 16
Lc_D4:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2039
L2040:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2041
L2042:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2043
L2044:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2045
L2046:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    test r8b, 16
    jnz L2047
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2048
L2049:
    mov dword ptr [rsp+48], r11d
    mov r11d, ebp
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2050
L2051:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2052
    mov byte ptr [rdi+rsi], r10b
L2053:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2054
L2055:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2056
    mov byte ptr [rdi+rsi], r11b
L2057:
    mov ebp, dword ptr [rsp+48]
L2047:
    jmp Lnext
L2039:
    call Ltick_slow4
    jmp L2040
L2041:
    call Lrd_slow
    jmp L2042
L2043:
    call Ltick_slow4
    jmp L2044
L2045:
    call Lrd_slow
    jmp L2046
L2048:
    call Ltick_slow4
    jmp L2049
L2050:
    call Ltick_slow4
    jmp L2051
L2052:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2053
L2054:
    call Ltick_slow4
    jmp L2055
L2056:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L2057
    ALIGN 16
Lc_D5:
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2058
L2059:
    mov r11d, edx
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2060
L2061:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2062
    mov byte ptr [rdi+rsi], r10b
L2063:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2064
L2065:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2066
    mov byte ptr [rdi+rsi], r11b
L2067:
    jmp Lnext
L2058:
    call Ltick_slow4
    jmp L2059
L2060:
    call Ltick_slow4
    jmp L2061
L2062:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2063
L2064:
    call Ltick_slow4
    jmp L2065
L2066:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L2067
    ALIGN 16
Lc_D6:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2068
L2069:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2070
L2071:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    sub al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    jmp Lnext
L2068:
    call Ltick_slow4
    jmp L2069
L2070:
    call Lrd_slow
    jmp L2071
    ALIGN 16
Lc_D7:
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2072
L2073:
    mov r11d, ebp
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2074
L2075:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2076
    mov byte ptr [rdi+rsi], r10b
L2077:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2078
L2079:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2080
    mov byte ptr [rdi+rsi], r11b
L2081:
    mov ebp, 16
    jmp Lnext
L2072:
    call Ltick_slow4
    jmp L2073
L2074:
    call Ltick_slow4
    jmp L2075
L2076:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2077
L2078:
    call Ltick_slow4
    jmp L2079
L2080:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L2081
    ALIGN 16
Lc_D8:
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2082
L2083:
    test r8b, 16
    jz L2084
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2085
L2086:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2087
L2088:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2089
L2090:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2091
L2092:
    movzx r11d, byte ptr [rdi+rsi]
    inc r9w
    shl r11d, 8
    or r11d, r10d
    mov ebp, r11d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2093
L2094:
L2084:
    jmp Lnext
L2082:
    call Ltick_slow4
    jmp L2083
L2085:
    call Ltick_slow4
    jmp L2086
L2087:
    call Lrd_slow
    jmp L2088
L2089:
    call Ltick_slow4
    jmp L2090
L2091:
    call Lrd_slow
    jmp L2092
L2093:
    call Ltick_slow4
    jmp L2094
    ALIGN 16
Lc_D9:
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2095
L2096:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2097
L2098:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2099
L2100:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2101
L2102:
    movzx r11d, byte ptr [rdi+rsi]
    inc r9w
    shl r11d, 8
    or r11d, r10d
    mov ebp, r11d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2103
L2104:
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
    cmp byte ptr [r15+572675], 0
    jne L2105
    mov qword ptr [r15+40], r14
    movzx edi, word ptr [r15+572672]
    add edi, r14d
    mov word ptr [r15+65858], di
L2105:
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
    mov r13, qword ptr [r15+572624]
    jmp Lnext
L2095:
    call Ltick_slow4
    jmp L2096
L2097:
    call Lrd_slow
    jmp L2098
L2099:
    call Ltick_slow4
    jmp L2100
L2101:
    call Lrd_slow
    jmp L2102
L2103:
    call Ltick_slow4
    jmp L2104
    ALIGN 16
Lc_DA:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2106
L2107:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2108
L2109:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2110
L2111:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2112
L2113:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    test r8b, 16
    jz L2114
    mov ebp, r11d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2115
L2116:
L2114:
    jmp Lnext
L2106:
    call Ltick_slow4
    jmp L2107
L2108:
    call Lrd_slow
    jmp L2109
L2110:
    call Ltick_slow4
    jmp L2111
L2112:
    call Lrd_slow
    jmp L2113
L2115:
    call Ltick_slow4
    jmp L2116
    ALIGN 16
Lc_DB:
    jmp Lnext
    ALIGN 16
Lc_DC:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2117
L2118:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2119
L2120:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2121
L2122:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2123
L2124:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    test r8b, 16
    jz L2125
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2126
L2127:
    mov dword ptr [rsp+48], r11d
    mov r11d, ebp
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2128
L2129:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2130
    mov byte ptr [rdi+rsi], r10b
L2131:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2132
L2133:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2134
    mov byte ptr [rdi+rsi], r11b
L2135:
    mov ebp, dword ptr [rsp+48]
L2125:
    jmp Lnext
L2117:
    call Ltick_slow4
    jmp L2118
L2119:
    call Lrd_slow
    jmp L2120
L2121:
    call Ltick_slow4
    jmp L2122
L2123:
    call Lrd_slow
    jmp L2124
L2126:
    call Ltick_slow4
    jmp L2127
L2128:
    call Ltick_slow4
    jmp L2129
L2130:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2131
L2132:
    call Ltick_slow4
    jmp L2133
L2134:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L2135
    ALIGN 16
Lc_DD:
    jmp Lnext
    ALIGN 16
Lc_DE:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2136
L2137:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2138
L2139:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    bt r8d, 4
    sbb al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    jmp Lnext
L2136:
    call Ltick_slow4
    jmp L2137
L2138:
    call Lrd_slow
    jmp L2139
    ALIGN 16
Lc_DF:
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2140
L2141:
    mov r11d, ebp
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2142
L2143:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2144
    mov byte ptr [rdi+rsi], r10b
L2145:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2146
L2147:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2148
    mov byte ptr [rdi+rsi], r11b
L2149:
    mov ebp, 24
    jmp Lnext
L2140:
    call Ltick_slow4
    jmp L2141
L2142:
    call Ltick_slow4
    jmp L2143
L2144:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2145
L2146:
    call Ltick_slow4
    jmp L2147
L2148:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L2149
    ALIGN 16
Lc_E0:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2152
L2153:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2154
L2155:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    cmp r10d, 128
    jb L2150
    cmp r10d, 255
    je L2150
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2156
L2157:
    mov rdi, qword ptr [r15+572576]
    mov byte ptr [rdi+r10+65280], al
    jmp L2151
L2150:
    movzx esi, r10b
    or esi, 65280
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2158
L2159:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2160
    mov byte ptr [rdi+rsi], al
L2161:
L2151:
    jmp Lnext
L2152:
    call Ltick_slow4
    jmp L2153
L2154:
    call Lrd_slow
    jmp L2155
L2156:
    call Ltick_slow4
    jmp L2157
L2158:
    call Ltick_slow4
    jmp L2159
L2160:
    mov byte ptr [rsp+40], al
    call Lwr_slow
    jmp L2161
    ALIGN 16
Lc_E1:
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2162
L2163:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2164
L2165:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2166
L2167:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2168
L2169:
    movzx r11d, byte ptr [rdi+rsi]
    inc r9w
    shl r11d, 8
    or r11d, r10d
    mov ebx, r11d
    jmp Lnext
L2162:
    call Ltick_slow4
    jmp L2163
L2164:
    call Lrd_slow
    jmp L2165
L2166:
    call Ltick_slow4
    jmp L2167
L2168:
    call Lrd_slow
    jmp L2169
    ALIGN 16
Lc_E2:
    movzx esi, cl
    or esi, 65280
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2170
L2171:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2172
    mov byte ptr [rdi+rsi], al
L2173:
    jmp Lnext
L2170:
    call Ltick_slow4
    jmp L2171
L2172:
    mov byte ptr [rsp+40], al
    call Lwr_slow
    jmp L2173
    ALIGN 16
Lc_E3:
    jmp Lnext
    ALIGN 16
Lc_E4:
    jmp Lnext
    ALIGN 16
Lc_E5:
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2174
L2175:
    mov r11d, ebx
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2176
L2177:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2178
    mov byte ptr [rdi+rsi], r10b
L2179:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2180
L2181:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2182
    mov byte ptr [rdi+rsi], r11b
L2183:
    jmp Lnext
L2174:
    call Ltick_slow4
    jmp L2175
L2176:
    call Ltick_slow4
    jmp L2177
L2178:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2179
L2180:
    call Ltick_slow4
    jmp L2181
L2182:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L2183
    ALIGN 16
Lc_E6:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2184
L2185:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2186
L2187:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    and al, r10b
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573992]
    jmp Lnext
L2184:
    call Ltick_slow4
    jmp L2185
L2186:
    call Lrd_slow
    jmp L2187
    ALIGN 16
Lc_E7:
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2188
L2189:
    mov r11d, ebp
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2190
L2191:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2192
    mov byte ptr [rdi+rsi], r10b
L2193:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2194
L2195:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2196
    mov byte ptr [rdi+rsi], r11b
L2197:
    mov ebp, 32
    jmp Lnext
L2188:
    call Ltick_slow4
    jmp L2189
L2190:
    call Ltick_slow4
    jmp L2191
L2192:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2193
L2194:
    call Ltick_slow4
    jmp L2195
L2196:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L2197
    ALIGN 16
Lc_E8:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2198
L2199:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2200
L2201:
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
    cmp r14, qword ptr [r15+572600]
    jae L2202
L2203:
    jmp Lnext
L2198:
    call Ltick_slow4
    jmp L2199
L2200:
    call Lrd_slow
    jmp L2201
L2202:
    call Ltick_slow8
    jmp L2203
    ALIGN 16
Lc_E9:
    mov ebp, ebx
    jmp Lnext
    ALIGN 16
Lc_EA:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2204
L2205:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2206
L2207:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2208
L2209:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2210
L2211:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    mov esi, r11d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2212
L2213:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2214
    mov byte ptr [rdi+rsi], al
L2215:
    jmp Lnext
L2204:
    call Ltick_slow4
    jmp L2205
L2206:
    call Lrd_slow
    jmp L2207
L2208:
    call Ltick_slow4
    jmp L2209
L2210:
    call Lrd_slow
    jmp L2211
L2212:
    call Ltick_slow4
    jmp L2213
L2214:
    mov byte ptr [rsp+40], al
    call Lwr_slow
    jmp L2215
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
    cmp r14, qword ptr [r15+572600]
    jae L2216
L2217:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2218
L2219:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    xor al, r10b
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573736]
    jmp Lnext
L2216:
    call Ltick_slow4
    jmp L2217
L2218:
    call Lrd_slow
    jmp L2219
    ALIGN 16
Lc_EF:
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2220
L2221:
    mov r11d, ebp
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2222
L2223:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2224
    mov byte ptr [rdi+rsi], r10b
L2225:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2226
L2227:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2228
    mov byte ptr [rdi+rsi], r11b
L2229:
    mov ebp, 40
    jmp Lnext
L2220:
    call Ltick_slow4
    jmp L2221
L2222:
    call Ltick_slow4
    jmp L2223
L2224:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2225
L2226:
    call Ltick_slow4
    jmp L2227
L2228:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L2229
    ALIGN 16
Lc_F0:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2232
L2233:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2234
L2235:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    cmp r10d, 128
    jb L2230
    cmp r10d, 255
    je L2230
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2236
L2237:
    mov rdi, qword ptr [r15+572576]
    mov al, byte ptr [rdi+r10+65280]
    jmp L2231
L2230:
    movzx esi, r10b
    or esi, 65280
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2238
L2239:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2240
L2241:
    mov al, byte ptr [rdi+rsi]
L2231:
    jmp Lnext
L2232:
    call Ltick_slow4
    jmp L2233
L2234:
    call Lrd_slow
    jmp L2235
L2236:
    call Ltick_slow4
    jmp L2237
L2238:
    call Ltick_slow4
    jmp L2239
L2240:
    call Lrd_slow
    jmp L2241
    ALIGN 16
Lc_F1:
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2242
L2243:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2244
L2245:
    movzx r10d, byte ptr [rdi+rsi]
    inc r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2246
L2247:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2248
L2249:
    movzx r11d, byte ptr [rdi+rsi]
    inc r9w
    shl r11d, 8
    or r11d, r10d
    mov eax, r11d
    shr eax, 8
    mov r8d, r11d
    and r8d, 240
    jmp Lnext
L2242:
    call Ltick_slow4
    jmp L2243
L2244:
    call Lrd_slow
    jmp L2245
L2246:
    call Ltick_slow4
    jmp L2247
L2248:
    call Lrd_slow
    jmp L2249
    ALIGN 16
Lc_F2:
    movzx esi, cl
    or esi, 65280
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2250
L2251:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2252
L2253:
    mov al, byte ptr [rdi+rsi]
    jmp Lnext
L2250:
    call Ltick_slow4
    jmp L2251
L2252:
    call Lrd_slow
    jmp L2253
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
    cmp byte ptr [r15+572675], 0
    jne L2254
    mov qword ptr [r15+40], r14
    movzx edi, word ptr [r15+572672]
    add edi, r14d
    mov word ptr [r15+65858], di
L2254:
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
    mov r13, qword ptr [r15+572624]
    jmp Lnext
    ALIGN 16
Lc_F4:
    jmp Lnext
    ALIGN 16
Lc_F5:
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2255
L2256:
    movzx r11d, al
    shl r11d, 8
    or r11d, r8d
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2257
L2258:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2259
    mov byte ptr [rdi+rsi], r10b
L2260:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2261
L2262:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2263
    mov byte ptr [rdi+rsi], r11b
L2264:
    jmp Lnext
L2255:
    call Ltick_slow4
    jmp L2256
L2257:
    call Ltick_slow4
    jmp L2258
L2259:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2260
L2261:
    call Ltick_slow4
    jmp L2262
L2263:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L2264
    ALIGN 16
Lc_F6:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2265
L2266:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2267
L2268:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    or al, r10b
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573736]
    jmp Lnext
L2265:
    call Ltick_slow4
    jmp L2266
L2267:
    call Lrd_slow
    jmp L2268
    ALIGN 16
Lc_F7:
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2269
L2270:
    mov r11d, ebp
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2271
L2272:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2273
    mov byte ptr [rdi+rsi], r10b
L2274:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2275
L2276:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2277
    mov byte ptr [rdi+rsi], r11b
L2278:
    mov ebp, 48
    jmp Lnext
L2269:
    call Ltick_slow4
    jmp L2270
L2271:
    call Ltick_slow4
    jmp L2272
L2273:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2274
L2275:
    call Ltick_slow4
    jmp L2276
L2277:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L2278
    ALIGN 16
Lc_F8:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2279
L2280:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2281
L2282:
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
    cmp r14, qword ptr [r15+572600]
    jae L2283
L2284:
    jmp Lnext
L2279:
    call Ltick_slow4
    jmp L2280
L2281:
    call Lrd_slow
    jmp L2282
L2283:
    call Ltick_slow4
    jmp L2284
    ALIGN 16
Lc_F9:
    mov r9d, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2285
L2286:
    jmp Lnext
L2285:
    call Ltick_slow4
    jmp L2286
    ALIGN 16
Lc_FA:
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2287
L2288:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2289
L2290:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    mov esi, ebp
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2291
L2292:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2293
L2294:
    movzx r11d, byte ptr [rdi+rsi]
    inc bp
    shl r11d, 8
    or r11d, r10d
    mov esi, r11d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2295
L2296:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2297
L2298:
    mov al, byte ptr [rdi+rsi]
    jmp Lnext
L2287:
    call Ltick_slow4
    jmp L2288
L2289:
    call Lrd_slow
    jmp L2290
L2291:
    call Ltick_slow4
    jmp L2292
L2293:
    call Lrd_slow
    jmp L2294
L2295:
    call Ltick_slow4
    jmp L2296
L2297:
    call Lrd_slow
    jmp L2298
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
    cmp byte ptr [r15+572675], 0
    jne L2299
    mov qword ptr [r15+40], r14
    movzx edi, word ptr [r15+572672]
    add edi, r14d
    mov word ptr [r15+65858], di
L2299:
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
    mov r13, qword ptr [r15+572624]
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
    cmp r14, qword ptr [r15+572600]
    jae L2300
L2301:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2302
L2303:
    movzx r10d, byte ptr [rdi+rsi]
    inc bp
    cmp al, r10b
    lahf
    movzx edi, ah
    movzx r8d, byte ptr [r15+rdi+572968]
    jmp Lnext
L2300:
    call Ltick_slow4
    jmp L2301
L2302:
    call Lrd_slow
    jmp L2303
    ALIGN 16
Lc_FF:
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2304
L2305:
    mov r11d, ebp
    dec r9w
    mov esi, r9d
    mov r10d, r11d
    shr r10d, 8
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2306
L2307:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2308
    mov byte ptr [rdi+rsi], r10b
L2309:
    dec r9w
    mov esi, r9d
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2310
L2311:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2312
    mov byte ptr [rdi+rsi], r11b
L2313:
    mov ebp, 56
    jmp Lnext
L2304:
    call Ltick_slow4
    jmp L2305
L2306:
    call Ltick_slow4
    jmp L2307
L2308:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2309
L2310:
    call Ltick_slow4
    jmp L2311
L2312:
    mov byte ptr [rsp+40], r11b
    call Lwr_slow
    jmp L2313
    ALIGN 16
Lccb_00:
    rol ch, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, ch
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_01:
    rol cl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, cl
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_02:
    rol dh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dh
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_03:
    rol dl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dl
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_04:
    rol bh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bh
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_05:
    rol bl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bl
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_06:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2314
L2315:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2316
L2317:
    movzx r10d, byte ptr [rdi+rsi]
    rol r10b, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, r10b
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2318
L2319:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2320
    mov byte ptr [rdi+rsi], r10b
L2321:
    jmp Lnext
L2314:
    call Ltick_slow4
    jmp L2315
L2316:
    call Lrd_slow
    jmp L2317
L2318:
    call Ltick_slow4
    jmp L2319
L2320:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2321
    ALIGN 16
Lccb_07:
    rol al, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, al
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_08:
    ror ch, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, ch
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_09:
    ror cl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, cl
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_0A:
    ror dh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dh
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_0B:
    ror dl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dl
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_0C:
    ror bh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bh
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_0D:
    ror bl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bl
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_0E:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2322
L2323:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2324
L2325:
    movzx r10d, byte ptr [rdi+rsi]
    ror r10b, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, r10b
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2326
L2327:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2328
    mov byte ptr [rdi+rsi], r10b
L2329:
    jmp Lnext
L2322:
    call Ltick_slow4
    jmp L2323
L2324:
    call Lrd_slow
    jmp L2325
L2326:
    call Ltick_slow4
    jmp L2327
L2328:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2329
    ALIGN 16
Lccb_0F:
    ror al, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, al
    movzx edi, byte ptr [r15+rdi+573736]
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
    movzx edi, byte ptr [r15+rdi+573736]
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
    movzx edi, byte ptr [r15+rdi+573736]
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
    movzx edi, byte ptr [r15+rdi+573736]
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
    movzx edi, byte ptr [r15+rdi+573736]
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
    movzx edi, byte ptr [r15+rdi+573736]
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
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_16:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2330
L2331:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2332
L2333:
    movzx r10d, byte ptr [rdi+rsi]
    bt r8d, 4
    rcl r10b, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, r10b
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2334
L2335:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2336
    mov byte ptr [rdi+rsi], r10b
L2337:
    jmp Lnext
L2330:
    call Ltick_slow4
    jmp L2331
L2332:
    call Lrd_slow
    jmp L2333
L2334:
    call Ltick_slow4
    jmp L2335
L2336:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2337
    ALIGN 16
Lccb_17:
    bt r8d, 4
    rcl al, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, al
    movzx edi, byte ptr [r15+rdi+573736]
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
    movzx edi, byte ptr [r15+rdi+573736]
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
    movzx edi, byte ptr [r15+rdi+573736]
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
    movzx edi, byte ptr [r15+rdi+573736]
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
    movzx edi, byte ptr [r15+rdi+573736]
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
    movzx edi, byte ptr [r15+rdi+573736]
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
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_1E:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2338
L2339:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2340
L2341:
    movzx r10d, byte ptr [rdi+rsi]
    bt r8d, 4
    rcr r10b, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, r10b
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2342
L2343:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2344
    mov byte ptr [rdi+rsi], r10b
L2345:
    jmp Lnext
L2338:
    call Ltick_slow4
    jmp L2339
L2340:
    call Lrd_slow
    jmp L2341
L2342:
    call Ltick_slow4
    jmp L2343
L2344:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2345
    ALIGN 16
Lccb_1F:
    bt r8d, 4
    rcr al, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, al
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_20:
    shl ch, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, ch
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_21:
    shl cl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, cl
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_22:
    shl dh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dh
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_23:
    shl dl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dl
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_24:
    shl bh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bh
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_25:
    shl bl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bl
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_26:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2346
L2347:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2348
L2349:
    movzx r10d, byte ptr [rdi+rsi]
    shl r10b, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, r10b
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2350
L2351:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2352
    mov byte ptr [rdi+rsi], r10b
L2353:
    jmp Lnext
L2346:
    call Ltick_slow4
    jmp L2347
L2348:
    call Lrd_slow
    jmp L2349
L2350:
    call Ltick_slow4
    jmp L2351
L2352:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2353
    ALIGN 16
Lccb_27:
    shl al, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, al
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_28:
    sar ch, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, ch
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_29:
    sar cl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, cl
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_2A:
    sar dh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dh
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_2B:
    sar dl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dl
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_2C:
    sar bh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bh
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_2D:
    sar bl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bl
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_2E:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2354
L2355:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2356
L2357:
    movzx r10d, byte ptr [rdi+rsi]
    sar r10b, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, r10b
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2358
L2359:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2360
    mov byte ptr [rdi+rsi], r10b
L2361:
    jmp Lnext
L2354:
    call Ltick_slow4
    jmp L2355
L2356:
    call Lrd_slow
    jmp L2357
L2358:
    call Ltick_slow4
    jmp L2359
L2360:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2361
    ALIGN 16
Lccb_2F:
    sar al, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, al
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_30:
    rol ch, 4
    movzx edi, ch
    movzx r8d, byte ptr [r15+rdi+573736]
    jmp Lnext
    ALIGN 16
Lccb_31:
    rol cl, 4
    movzx edi, cl
    movzx r8d, byte ptr [r15+rdi+573736]
    jmp Lnext
    ALIGN 16
Lccb_32:
    rol dh, 4
    movzx edi, dh
    movzx r8d, byte ptr [r15+rdi+573736]
    jmp Lnext
    ALIGN 16
Lccb_33:
    rol dl, 4
    movzx edi, dl
    movzx r8d, byte ptr [r15+rdi+573736]
    jmp Lnext
    ALIGN 16
Lccb_34:
    rol bh, 4
    movzx edi, bh
    movzx r8d, byte ptr [r15+rdi+573736]
    jmp Lnext
    ALIGN 16
Lccb_35:
    rol bl, 4
    movzx edi, bl
    movzx r8d, byte ptr [r15+rdi+573736]
    jmp Lnext
    ALIGN 16
Lccb_36:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2362
L2363:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2364
L2365:
    movzx r10d, byte ptr [rdi+rsi]
    rol r10b, 4
    movzx edi, r10b
    movzx r8d, byte ptr [r15+rdi+573736]
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2366
L2367:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2368
    mov byte ptr [rdi+rsi], r10b
L2369:
    jmp Lnext
L2362:
    call Ltick_slow4
    jmp L2363
L2364:
    call Lrd_slow
    jmp L2365
L2366:
    call Ltick_slow4
    jmp L2367
L2368:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2369
    ALIGN 16
Lccb_37:
    rol al, 4
    movzx edi, al
    movzx r8d, byte ptr [r15+rdi+573736]
    jmp Lnext
    ALIGN 16
Lccb_38:
    shr ch, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, ch
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_39:
    shr cl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, cl
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_3A:
    shr dh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dh
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_3B:
    shr dl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, dl
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_3C:
    shr bh, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bh
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_3D:
    shr bl, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, bl
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    jmp Lnext
    ALIGN 16
Lccb_3E:
    mov esi, ebx
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2370
L2371:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2372
L2373:
    movzx r10d, byte ptr [rdi+rsi]
    shr r10b, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, r10b
    movzx edi, byte ptr [r15+rdi+573736]
    or r8d, edi
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2374
L2375:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2376
    mov byte ptr [rdi+rsi], r10b
L2377:
    jmp Lnext
L2370:
    call Ltick_slow4
    jmp L2371
L2372:
    call Lrd_slow
    jmp L2373
L2374:
    call Ltick_slow4
    jmp L2375
L2376:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2377
    ALIGN 16
Lccb_3F:
    shr al, 1
    mov r8d, 0
    setc r8b
    shl r8d, 4
    movzx edi, al
    movzx edi, byte ptr [r15+rdi+573736]
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
    cmp r14, qword ptr [r15+572600]
    jae L2378
L2379:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2380
L2381:
    movzx r10d, byte ptr [rdi+rsi]
    mov edi, 0
    test r10b, 1
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
L2378:
    call Ltick_slow4
    jmp L2379
L2380:
    call Lrd_slow
    jmp L2381
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
    cmp r14, qword ptr [r15+572600]
    jae L2382
L2383:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2384
L2385:
    movzx r10d, byte ptr [rdi+rsi]
    mov edi, 0
    test r10b, 2
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
L2382:
    call Ltick_slow4
    jmp L2383
L2384:
    call Lrd_slow
    jmp L2385
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
    cmp r14, qword ptr [r15+572600]
    jae L2386
L2387:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2388
L2389:
    movzx r10d, byte ptr [rdi+rsi]
    mov edi, 0
    test r10b, 4
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
L2386:
    call Ltick_slow4
    jmp L2387
L2388:
    call Lrd_slow
    jmp L2389
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
    cmp r14, qword ptr [r15+572600]
    jae L2390
L2391:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2392
L2393:
    movzx r10d, byte ptr [rdi+rsi]
    mov edi, 0
    test r10b, 8
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
L2390:
    call Ltick_slow4
    jmp L2391
L2392:
    call Lrd_slow
    jmp L2393
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
    cmp r14, qword ptr [r15+572600]
    jae L2394
L2395:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2396
L2397:
    movzx r10d, byte ptr [rdi+rsi]
    mov edi, 0
    test r10b, 16
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
L2394:
    call Ltick_slow4
    jmp L2395
L2396:
    call Lrd_slow
    jmp L2397
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
    cmp r14, qword ptr [r15+572600]
    jae L2398
L2399:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2400
L2401:
    movzx r10d, byte ptr [rdi+rsi]
    mov edi, 0
    test r10b, 32
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
L2398:
    call Ltick_slow4
    jmp L2399
L2400:
    call Lrd_slow
    jmp L2401
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
    cmp r14, qword ptr [r15+572600]
    jae L2402
L2403:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2404
L2405:
    movzx r10d, byte ptr [rdi+rsi]
    mov edi, 0
    test r10b, 64
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
L2402:
    call Ltick_slow4
    jmp L2403
L2404:
    call Lrd_slow
    jmp L2405
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
    cmp r14, qword ptr [r15+572600]
    jae L2406
L2407:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2408
L2409:
    movzx r10d, byte ptr [rdi+rsi]
    mov edi, 0
    test r10b, 128
    setz dil
    shl edi, 7
    and r8d, 16
    or r8d, 32
    or r8d, edi
    jmp Lnext
L2406:
    call Ltick_slow4
    jmp L2407
L2408:
    call Lrd_slow
    jmp L2409
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
    cmp r14, qword ptr [r15+572600]
    jae L2410
L2411:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2412
L2413:
    movzx r10d, byte ptr [rdi+rsi]
    and r10b, 254
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2414
L2415:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2416
    mov byte ptr [rdi+rsi], r10b
L2417:
    jmp Lnext
L2410:
    call Ltick_slow4
    jmp L2411
L2412:
    call Lrd_slow
    jmp L2413
L2414:
    call Ltick_slow4
    jmp L2415
L2416:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2417
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
    cmp r14, qword ptr [r15+572600]
    jae L2418
L2419:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2420
L2421:
    movzx r10d, byte ptr [rdi+rsi]
    and r10b, 253
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2422
L2423:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2424
    mov byte ptr [rdi+rsi], r10b
L2425:
    jmp Lnext
L2418:
    call Ltick_slow4
    jmp L2419
L2420:
    call Lrd_slow
    jmp L2421
L2422:
    call Ltick_slow4
    jmp L2423
L2424:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2425
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
    cmp r14, qword ptr [r15+572600]
    jae L2426
L2427:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2428
L2429:
    movzx r10d, byte ptr [rdi+rsi]
    and r10b, 251
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2430
L2431:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2432
    mov byte ptr [rdi+rsi], r10b
L2433:
    jmp Lnext
L2426:
    call Ltick_slow4
    jmp L2427
L2428:
    call Lrd_slow
    jmp L2429
L2430:
    call Ltick_slow4
    jmp L2431
L2432:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2433
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
    cmp r14, qword ptr [r15+572600]
    jae L2434
L2435:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2436
L2437:
    movzx r10d, byte ptr [rdi+rsi]
    and r10b, 247
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2438
L2439:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2440
    mov byte ptr [rdi+rsi], r10b
L2441:
    jmp Lnext
L2434:
    call Ltick_slow4
    jmp L2435
L2436:
    call Lrd_slow
    jmp L2437
L2438:
    call Ltick_slow4
    jmp L2439
L2440:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2441
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
    cmp r14, qword ptr [r15+572600]
    jae L2442
L2443:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2444
L2445:
    movzx r10d, byte ptr [rdi+rsi]
    and r10b, 239
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2446
L2447:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2448
    mov byte ptr [rdi+rsi], r10b
L2449:
    jmp Lnext
L2442:
    call Ltick_slow4
    jmp L2443
L2444:
    call Lrd_slow
    jmp L2445
L2446:
    call Ltick_slow4
    jmp L2447
L2448:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2449
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
    cmp r14, qword ptr [r15+572600]
    jae L2450
L2451:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2452
L2453:
    movzx r10d, byte ptr [rdi+rsi]
    and r10b, 223
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2454
L2455:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2456
    mov byte ptr [rdi+rsi], r10b
L2457:
    jmp Lnext
L2450:
    call Ltick_slow4
    jmp L2451
L2452:
    call Lrd_slow
    jmp L2453
L2454:
    call Ltick_slow4
    jmp L2455
L2456:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2457
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
    cmp r14, qword ptr [r15+572600]
    jae L2458
L2459:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2460
L2461:
    movzx r10d, byte ptr [rdi+rsi]
    and r10b, 191
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2462
L2463:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2464
    mov byte ptr [rdi+rsi], r10b
L2465:
    jmp Lnext
L2458:
    call Ltick_slow4
    jmp L2459
L2460:
    call Lrd_slow
    jmp L2461
L2462:
    call Ltick_slow4
    jmp L2463
L2464:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2465
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
    cmp r14, qword ptr [r15+572600]
    jae L2466
L2467:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2468
L2469:
    movzx r10d, byte ptr [rdi+rsi]
    and r10b, 127
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2470
L2471:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2472
    mov byte ptr [rdi+rsi], r10b
L2473:
    jmp Lnext
L2466:
    call Ltick_slow4
    jmp L2467
L2468:
    call Lrd_slow
    jmp L2469
L2470:
    call Ltick_slow4
    jmp L2471
L2472:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2473
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
    cmp r14, qword ptr [r15+572600]
    jae L2474
L2475:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2476
L2477:
    movzx r10d, byte ptr [rdi+rsi]
    or r10b, 1
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2478
L2479:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2480
    mov byte ptr [rdi+rsi], r10b
L2481:
    jmp Lnext
L2474:
    call Ltick_slow4
    jmp L2475
L2476:
    call Lrd_slow
    jmp L2477
L2478:
    call Ltick_slow4
    jmp L2479
L2480:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2481
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
    cmp r14, qword ptr [r15+572600]
    jae L2482
L2483:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2484
L2485:
    movzx r10d, byte ptr [rdi+rsi]
    or r10b, 2
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2486
L2487:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2488
    mov byte ptr [rdi+rsi], r10b
L2489:
    jmp Lnext
L2482:
    call Ltick_slow4
    jmp L2483
L2484:
    call Lrd_slow
    jmp L2485
L2486:
    call Ltick_slow4
    jmp L2487
L2488:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2489
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
    cmp r14, qword ptr [r15+572600]
    jae L2490
L2491:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2492
L2493:
    movzx r10d, byte ptr [rdi+rsi]
    or r10b, 4
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2494
L2495:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2496
    mov byte ptr [rdi+rsi], r10b
L2497:
    jmp Lnext
L2490:
    call Ltick_slow4
    jmp L2491
L2492:
    call Lrd_slow
    jmp L2493
L2494:
    call Ltick_slow4
    jmp L2495
L2496:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2497
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
    cmp r14, qword ptr [r15+572600]
    jae L2498
L2499:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2500
L2501:
    movzx r10d, byte ptr [rdi+rsi]
    or r10b, 8
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2502
L2503:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2504
    mov byte ptr [rdi+rsi], r10b
L2505:
    jmp Lnext
L2498:
    call Ltick_slow4
    jmp L2499
L2500:
    call Lrd_slow
    jmp L2501
L2502:
    call Ltick_slow4
    jmp L2503
L2504:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2505
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
    cmp r14, qword ptr [r15+572600]
    jae L2506
L2507:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2508
L2509:
    movzx r10d, byte ptr [rdi+rsi]
    or r10b, 16
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2510
L2511:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2512
    mov byte ptr [rdi+rsi], r10b
L2513:
    jmp Lnext
L2506:
    call Ltick_slow4
    jmp L2507
L2508:
    call Lrd_slow
    jmp L2509
L2510:
    call Ltick_slow4
    jmp L2511
L2512:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2513
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
    cmp r14, qword ptr [r15+572600]
    jae L2514
L2515:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2516
L2517:
    movzx r10d, byte ptr [rdi+rsi]
    or r10b, 32
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2518
L2519:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2520
    mov byte ptr [rdi+rsi], r10b
L2521:
    jmp Lnext
L2514:
    call Ltick_slow4
    jmp L2515
L2516:
    call Lrd_slow
    jmp L2517
L2518:
    call Ltick_slow4
    jmp L2519
L2520:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2521
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
    cmp r14, qword ptr [r15+572600]
    jae L2522
L2523:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2524
L2525:
    movzx r10d, byte ptr [rdi+rsi]
    or r10b, 64
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2526
L2527:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2528
    mov byte ptr [rdi+rsi], r10b
L2529:
    jmp Lnext
L2522:
    call Ltick_slow4
    jmp L2523
L2524:
    call Lrd_slow
    jmp L2525
L2526:
    call Ltick_slow4
    jmp L2527
L2528:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2529
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
    cmp r14, qword ptr [r15+572600]
    jae L2530
L2531:
    mov edi, esi
    shr edi, 12
    mov rdi, qword ptr [r15+rdi*8+572304]
    test rdi, rdi
    jz L2532
L2533:
    movzx r10d, byte ptr [rdi+rsi]
    or r10b, 128
    add r14, 4
    cmp r14, qword ptr [r15+572600]
    jae L2534
L2535:
    mov edi, esi
    shr edi, 8
    mov rdi, qword ptr [r15+rdi*8+574248]
    test rdi, rdi
    jz L2536
    mov byte ptr [rdi+rsi], r10b
L2537:
    jmp Lnext
L2530:
    call Ltick_slow4
    jmp L2531
L2532:
    call Lrd_slow
    jmp L2533
L2534:
    call Ltick_slow4
    jmp L2535
L2536:
    mov byte ptr [rsp+40], r10b
    call Lwr_slow
    jmp L2537
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
