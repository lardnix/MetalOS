;; prints character in al register
;; al = character | ascii character to write
putc:
    mov ah, 0xe              ;; ah = 0eh | write text in tty mode
    int 0x10                 ;; print character in al
    ret
