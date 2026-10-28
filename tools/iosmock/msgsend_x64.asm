; msgsend_x64.asm - objc_msgSend of the simulated iOS (tools/iosmock), Windows x64 (ml64).
;
; As the real one: finds the method (mock_lookup, in C) and jumps to it with the arguments
; untouched, whatever their types (integer registers rcx, rdx, r8, r9, float registers
; xmm0-xmm3, the stack). objc_msgSend_stret: the method returns a structure in memory, the
; address of which comes first (rcx), the receiver and the selector after it.

EXTERN mock_lookup:PROC

.code

objc_msgSend PROC
    sub     rsp, 88h                ; shadow space + saved arguments, keeps rsp 16-aligned
    mov     [rsp+20h], rcx
    mov     [rsp+28h], rdx
    mov     [rsp+30h], r8
    mov     [rsp+38h], r9
    movdqu  [rsp+40h], xmm0
    movdqu  [rsp+50h], xmm1
    movdqu  [rsp+60h], xmm2
    movdqu  [rsp+70h], xmm3
    call    mock_lookup             ; (self = rcx, sel = rdx) -> rax
    mov     rcx, [rsp+20h]
    mov     rdx, [rsp+28h]
    mov     r8,  [rsp+30h]
    mov     r9,  [rsp+38h]
    movdqu  xmm0, [rsp+40h]
    movdqu  xmm1, [rsp+50h]
    movdqu  xmm2, [rsp+60h]
    movdqu  xmm3, [rsp+70h]
    add     rsp, 88h
    jmp     rax
objc_msgSend ENDP

objc_msgSend_stret PROC
    sub     rsp, 88h
    mov     [rsp+20h], rcx
    mov     [rsp+28h], rdx
    mov     [rsp+30h], r8
    mov     [rsp+38h], r9
    movdqu  [rsp+40h], xmm0
    movdqu  [rsp+50h], xmm1
    movdqu  [rsp+60h], xmm2
    movdqu  [rsp+70h], xmm3
    mov     rcx, rdx                ; self
    mov     rdx, r8                 ; sel
    call    mock_lookup
    mov     rcx, [rsp+20h]
    mov     rdx, [rsp+28h]
    mov     r8,  [rsp+30h]
    mov     r9,  [rsp+38h]
    movdqu  xmm0, [rsp+40h]
    movdqu  xmm1, [rsp+50h]
    movdqu  xmm2, [rsp+60h]
    movdqu  xmm3, [rsp+70h]
    add     rsp, 88h
    jmp     rax
objc_msgSend_stret ENDP

; a message to nil: returns 0 (integer and floating point)
mock_nil PROC
    xor     eax, eax
    xorps   xmm0, xmm0
    ret
mock_nil ENDP

PUBLIC objc_msgSend
PUBLIC objc_msgSend_stret
PUBLIC mock_nil

END
