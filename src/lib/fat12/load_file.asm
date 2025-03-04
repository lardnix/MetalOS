include "../../memory_layout.asm"

include "root_entry.asm"

;; ========================================================
;; Load file name at es:bx root entry and put pointer at es:bx
;; ========================================================
;; load file expects 'find_file', 'cluster_to_lba', 'lba_to_chs', 'read_disk', 'get_next_cluster' included
;; es:bx = root file entry
load_file:
    push ax
    push cx

    mov ax, [es:bx + root_entry_first_cluster_offset]

    mov bx, loaded_file_segment
    mov es, bx
    mov bx, loaded_file_offset

.load_loop:
    push ax

    call cluster_to_lba
    call lba_to_chs

    call read_disk

    pop ax

    call get_next_cluster

    cmp ax, 0xff8
    jae .loaded

    jmp .load_loop

.loaded:
    pop cx
    pop ax

    ret
