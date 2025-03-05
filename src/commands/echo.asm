;; ========================================================
;; Command echo
;; ========================================================
command_echo:
    mov ax, 1

.print_loop:
    cmp ax, [argc]
    jae .done

    push ax

    mov cx, 2
    mul cx

    mov di, argv
    add di, ax

    mov si, [di]
    call print_string

    mov al, " "
    call print_char

    pop ax
    inc ax

    jmp .print_loop

.done:
    jmp input
