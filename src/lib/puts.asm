;; ========================================================
;; Prints null terminated string in si register
;; ========================================================

;; si = string pointer
puts:
    push si
.print_char:
    lodsb                    ;; load ds:si in al and increment si
    cmp al, 0x0
    je .end                  ;; jump to end if al = 0
    mov ah, 0xe
    int 0x10                 ;; print character in al
    jmp .print_char          ;; loop
.end:
    pop si
    ret
