;; Compare 2 strings in si and di and return if this strings are equal in ax
;; si = pointer to first string
;; di = pointer to second string
str_equal:
    push si
    push di

.cmp_loop:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .not_equal
    cmp al, 0
    je .equal

    inc si
    inc di

    jmp .cmp_loop
.equal:
    mov ax, 1
    jmp .done
.not_equal:
    mov ax, 0
.done:
    pop di
    pop si
    ret
