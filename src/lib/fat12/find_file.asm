include "root_entry.asm"

;; ========================================================
;; Find file name at si and put entry at es:bx
;; ========================================================
;; si = file name
find_file:
    ;; Load root segment
    mov bx, root_segment
    mov es, bx
    mov bx, root_offset

    mov cx, 11                              ;; move to cx the length of file name + extension
.find_loop:
    mov al, [es:bx]                         ;; move to al the first byte of root entry
    test al, al
    jz .not_found                           ;; if zero, file not found

    push si                                 ;; save file name on the stack
    lea di, [es:bx]                         ;; move to di file name

    repe cmpsb                              ;; compare file name cx times
    pop si                                  ;; restore file name

    je .found                               ;; if equal, file found

    add bx, root_entry_size                 ;; add bx to point at next entry

    jmp .find_loop                          ;; loop

.not_found:
    stc                                     ;; set carry bit if file not found
    ret
    
.found:                                     ;; clear carry bit if file found
    clc
    ret
