;; prints null terminated string in bx register
;; bx = string pointer
puts:
    pusha                    ;; push all general registers
.print_char:
    mov al, [si]             ;; al = current value in bx
    cmp al, 0x0
    je .end                  ;; jump to end if al = 0
    call putc                ;; print character in al
    inc si                   ;; increment bx to get next character
    jmp .print_char          ;; loop
.end:
    popa                     ;; restore all general registers
    ret
