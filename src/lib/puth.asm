;; prints hexdecimal in dx register
;; dx = hexecimal value
puth:
    pusha                    ;; push all general registers
    mov cx, 0                ;; initialize cx loop counter
.loop:
    cmp cx, 4
    je .end                  ;; jmp if cx = 4

    ;; Convert dx hex to ascii
    mov ax, dx
    and ax, 0xf              ;; take only the last digit to convert
    add al, 0x30             ;; get ascii number or letter from digit
    cmp al, 0x39             ;; check if value is 0-9 (<= 39h) or A-F (> 39h)
    jle .save_digit
    add al, 0x7              ;; get ascii 'A' - 'F'

    ;; Save digit into buffer
.save_digit:
    mov bx, .string + 5      ;; move end of string to bx
    sub bx, cx               ;; move string to the current digit
    mov [bx], al             ;; move character into string
    ror dx, 4                ;; rotate left to get next digit
    inc cx                   ;; increment cx to get next character
    jmp .loop
.end:
    mov si, .string
    call puts
    popa                     ;; restore all general registers
    ret

.string:
    db "0x0000", 0
