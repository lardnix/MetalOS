include "../../memory_layout.asm"

include "bpb.asm"

;; Calculate LBA(Logical Blocking Adressing) of a given cluster at ax and save it in ax register
;; ax = cluster
cluster_to_lba:
    push es
    push bx

    ;; Move es:bx to point at boot segment
    mov bx, boot_segment
    mov es, bx
    mov bx, boot_offset

    ;; ========================================================
    ;; calculate lba(logical blocking adressing) for root directory
    ;; ========================================================
    ;; rootlba = reserved_sectors + number_of_fats * sectors_per_fat 
    xor ax, ax
    mov al, [es:bx + BPB_number_of_fats_offset]
    mov cx, [es:bx + BPB_sectors_per_fat_offset]
    mul cx
    add ax, word [es:bx + BPB_reserved_sectors_offset]

    mov [ctb_root_lba], al

    ;; ========================================================
    ;; Calculate size of root directory
    ;; ========================================================
    ;; RootSize = (number_of_root_dir_entries * 32) / sector_size
    mov ax, [es:bx + BPB_number_of_root_dir_entries_offset]
    shl ax, 5                               ;; multiply by 32
    xor dx, dx
    mov cx, [es:bx + BPB_sector_size_offset]
    div cx

    mov [ctb_root_size], ax

    ;; ========================================================
    ;; Calculate LBA
    ;; ========================================================
    ;; LBA = (cluster - 2) + sectors_per_cluster + root_start_lba + root_size
    sub ax, 2
    xor cx, cx
    mov cl, [es:bx + BPB_sectors_per_cluster_offset]
    mul cx
    add al, [ctb_root_lba]
    add ax, [ctb_root_size]

    pop bx
    pop es

    ret

ctb_root_lba: rw 1
ctb_root_size: rb 1
