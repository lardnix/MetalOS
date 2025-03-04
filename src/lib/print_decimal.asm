;; ========================================================
;; Prints 16 bits decimal value in dx register
;; ========================================================
;; it expect print_string included in assembly file

;; dx = value
print_decimal:
    pusha

    cmp dx, 0
    je .zero

    mov di, print_hex_string_end

    mov ax, dx
.convert:
    xor dx, dx
    mov cx, 10
    div cx

    add dl, '0'

    dec di
    mov [di], dl

    test ax, ax
    jz .done

    jmp .convert

.done:
    mov si, di
    mov cx, print_hex_string_end
    mov ax, di
    sub cx, ax

.print:
    mov ah, 0xe
    lodsb

    int 0x10

    loop .print

    popa
    ret

.zero:
    mov ah, 0xe
    mov al, "0"
    int 0x10
    ret

print_hex_string: rb 10
print_hex_string_end:
