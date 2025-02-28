;; Basic kernel

main:
    mov ah, 0x0              ;; ah = 0   | set video mode
    mov al, 0x3              ;; al = 03h | 80x25 color text 
    int 10h

    mov bx, .success
    call puts

    cli
    hlt

.success:
    db "[Success]: Kernel load successfully", 0

;; prints character in al register
;; al = character | ascii character to write
putc:
    mov ah, 0xe              ;; ah = 0eh | write text in tty mode
    int 0x10                 ;; print character in al
    ret

;; prints null terminated string in bx register
;; bx = string pointer
puts:
    pusha                    ;; push all general registers
.print_char:
    mov al, [bx]             ;; al = current value in bx
    cmp al, 0x0
    je .end                  ;; jump to end if al = 0
    call putc                ;; print character in al
    add bx, 0x1              ;; increment bx to get next character
    jmp .print_char          ;; loop
.end:
    popa                     ;; restore all general registers
    ret

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
    add cx, 1                ;; increment cx to get next character
    jmp .loop
.end:
    mov bx, .string
    call puts
    popa                     ;; restore all general registers
    ret

.string:
    db "0x0000", 0

    times 512-($-$$) db 0x0  ;; pad file with 0s until reach 512 bytes
