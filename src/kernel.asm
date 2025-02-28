;; Basic kernel

main:
    ;; Setup tty mode 80x25
    mov ah, 0x0              ;; ah = 0   | set video mode
    mov al, 0x3              ;; al = 03h | 80x25 color text 
    int 10h

    mov si, .welcome
    call puts

    cli
    hlt

.welcome:
    db "Welcome to OS", 0x0d, 0x0a, 0

%include "putc.asm"
%include "puts.asm"
%include "puth.asm"

    times 512-($-$$) db 0x0  ;; pad file with 0s until reach 512 bytes
