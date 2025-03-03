;; ========================================================
;; Prints 32 bits decimal inside of dx:ax registers
;; ========================================================

print_32bit_decimal:
    pusha

    mov cx, 10
    mov di, print_32bit_decimal_buffer_end

.convert:
    ;; Divide 32 bit number by 10
    xor bx, bx
    xchg ax, bx
    xchg ax, dx
    div cx
    xchg ax, bx
    div cx
    xchg dx, si
    xchg bx, dx

    mov bx, si
    add bl, '0'

    dec di
    mov [di], bl

    test ax, ax
    jnz .convert
    test dx, dx
    jnz .convert
    
    mov si, di

    mov cx, print_32bit_decimal_buffer_end
    sub cx, si
.print_loop:
    mov ah, 0xe
    lodsb
    int 0x10

    loop .print_loop

    popa
    ret

print_32bit_decimal_buffer: rb 10
print_32bit_decimal_buffer_end:
