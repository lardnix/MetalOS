include "../memory_layout.asm"

    mov si, test_string
    mov ah, 0xe
.print_loop:
    lodsb
    test al, al
    jz .done

    int 0x10
    jmp .print_loop

.done:
    mov ax, 0
    int 0x16

    mov bx, kernel_segment
    mov es, bx
    mov bx, kernel_offset

    mov ax, kernel_segment                  ;; move to ax the kernel segment

    mov es, ax                              ;; setup es
    mov ds, ax                              ;; setup ds
    mov ss, ax                              ;; setup ss

    jmp kernel_segment:kernel_offset        ;; jump to kernel

test_string:
    db "Program Test", 0xd, 0xa, 0xd, 0xa
    db "Press any key to go back...", 0
