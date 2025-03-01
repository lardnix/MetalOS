;; prints character in al register
;; al = character | ascii character to write
putc:
    mov ah, 0xe              ;; ah = 0eh | write text in tty mode
    mov bh, 0
    mov bl, 0x7
    int 0x10                 ;; print character in al
    ret
