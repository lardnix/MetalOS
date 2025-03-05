;; ========================================================
;; Command disk
;; ========================================================
command_disk:
    push es
    push bx
    push cx

    ;; ========================================================
    ;; Calculated free clusters of the disk
    ;; ========================================================
    ;; RootDirSize = (BPB_number_of_root_dir_entries * 32) / BPB_sector_size
    ;; FatTableSize = BPB_number_of_fats * BPB_sectors_per_fat
    ;; DataSectors = BPB_logical_sectors - (BPB_reserved_sectors + FatTableSize + RootDirSize)
    ;; TotalClusters = DataSectors/BPB_sectors_per_cluster

    mov bx, boot_segment
    mov es, bx
    mov bx, boot_offset

    ;; Calculate RootDirSize in ax
    mov ax, [es:bx + BPB_number_of_root_dir_entries_offset]
    shl ax, 5
    xor dx, dx
    mov cx, [es:bx + BPB_sector_size_offset]
    div cx

    mov [command_disk_root_size], ax

    ;; Calculate FatTableSize
    mov ah, 0
    mov al, [es:bx + BPB_number_of_fats_offset]
    mov cx, [es:bx + BPB_sectors_per_fat_offset]
    mul cx

    mov [command_disk_fat_table_size], ax

    ;; Calculate DataSectors
    mov ax, [es:bx + BPB_reserved_sectors_offset]
    mov cx, [command_disk_fat_table_size]
    add ax, cx
    mov cx, [command_disk_root_size]
    add ax, cx
    mov cx, [es:bx + BPB_logical_sectors_offset]
    xchg ax, cx
    sub ax, cx

    ;; Calculate TotalClusters
    xor dx, dx
    mov ch, 0
    mov cl, [es:bx + BPB_sectors_per_cluster_offset]
    mul cx

    mov [command_disk_total_clusters], ax

    ;; Calculate all used clusters
    mov cx, 2
.cluster_loop:
    push cx
    ;; NextClusterEntry = cluster * 3 / 2
    mov bx, fat_segment
    mov es, bx
    mov bx, fat_offset

    mov ax, cx

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
    jmp .check_cluster

.even:
    and ax, 0xfff                           ;; if even, only and with 0xfff

.check_cluster:
    cmp ax, 0xff7
    je .next_cluster

    cmp ax, 0xff8
    jae .free_cluster

    test ax, ax
    jnz .next_cluster

.free_cluster:
    mov ax, [command_disk_free_clusters]
    inc ax
    mov [command_disk_free_clusters], ax

.next_cluster:

    pop cx
    inc cx

    cmp cx, [command_disk_total_clusters]
    je .done

    jmp .cluster_loop
.done:
    mov bx, boot_segment
    mov es, bx
    mov bx, boot_offset

    ;; ========================================================
    ;; Calculate total size of the disk
    ;; ========================================================
    mov ax, [command_disk_total_clusters]
    mov cx, [es:bx + BPB_sector_size_offset]
    mul cx

    mov word [command_disk_total_size + 2], dx
    mov word [command_disk_total_size], ax

    ;; ========================================================
    ;; Calculated free size of the disk
    ;; ========================================================
    mov ax, [command_disk_free_clusters]
    mov cx, [es:bx + BPB_sector_size_offset]
    mul cx

    mov word [command_disk_free_size + 2], dx
    mov word [command_disk_free_size], ax

    ;; ========================================================
    ;; Calculated used size of the disk
    ;; ========================================================
    mov ax, [command_disk_total_clusters]
    mov cx, [command_disk_free_clusters]
    sub ax, cx
    mov cx, [es:bx + BPB_sector_size_offset]
    mul cx

    mov word [command_disk_used_size + 2], dx
    mov word [command_disk_used_size], ax

    ;; ========================================================
    ;; Print all information
    ;; ========================================================

    mov si, command_disk_label
    call print_string

    ;; Print total size
    mov si, command_disk_total_string
    call print_string

    mov dx, [command_disk_total_size + 2]
    mov ax, [command_disk_total_size]

    call print_32bit_decimal

    mov si, command_disk_bytes_string
    call print_string

    ;; Print used size
    mov si, command_disk_used_string
    call print_string

    mov dx, [command_disk_used_size + 2]
    mov ax, [command_disk_used_size]

    call print_32bit_decimal

    mov si, command_disk_bytes_string
    call print_string

    ;; Print free size
    mov si, command_disk_free_string
    call print_string

    mov dx, [command_disk_free_size + 2]
    mov ax, [command_disk_free_size]

    call print_32bit_decimal

    mov si, command_disk_bytes_string
    call print_string

    pop cx
    pop bx
    pop es

    jmp input

command_disk_root_size:      rw 1
command_disk_fat_table_size: rw 1
command_disk_total_clusters: rw 1
command_disk_free_clusters:  rw 1

command_disk_total_size:     rd 1
command_disk_used_size:      rd 1
command_disk_free_size:      rd 1

command_disk_total_string: db "Total: ", 0
command_disk_used_string:  db "Used:  ", 0
command_disk_free_string:  db "Free:  ", 0
command_disk_bytes_string: db " bytes", 0xd, 0xa, 0

command_disk_label:
    db "Disk info", 0xd, 0xa
    db "----------", 0xd, 0xa, 0xd, 0xa, 0
