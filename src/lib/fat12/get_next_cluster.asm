include "../../memory_layout.asm"

;; ========================================================
;; Get next cluster from cluster at ax and put it in ax
;; ========================================================
;; ax = current cluster
get_next_cluster:
    push es
    push bx
    push cx

    ;; load fat table
    mov bx, fat_segment
    mov es, bx
    mov bx, fat_offset

    mov cx, 3
    mul cx                                  ;; multiply cluster by 3
    mov cx, 2
    xor dx, dx
    div cx                                  ;; divide cluster by 2

    add bx, ax
    mov ax, [es:bx]                         ;; get next cluster

    test dx, dx
    jz .even                                ;; test remaining of division

    shr ax, 4                               ;; if odd, the shift left by 4
    jmp .done

.even:
    and ax, 0xfff                           ;; if even, only and with 0xfff
.done:

    pop cx
    pop bx
    pop es

    ret
