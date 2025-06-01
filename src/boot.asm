;; Basic boot loader
    org 0x7c00
    jmp short boot
    nop

;; ========================================================
;;   FAT12 BPB(BIOS Parameter Block)
;; ========================================================
OEM_label:                  db "Metal Os"
sector_size:                dw 512
sectors_per_cluster:        db 1
reserved_sectors:           dw 1            ;; reserved for boot
number_of_fats:             db 2
number_of_root_dir_entries: dw 224
logical_sectors:            dw 2880
media_descriptor_type:      db 0xf0
sectors_per_fat:            dw 9
sectors_per_track:          dw 18
number_of_heads:            dw 2
hidden_sectors:             dd 0
large_sectors:              dd 0
drive_number:               dw 0
siganture:                  db 0x29
volume_id:                  dd 0
volume_label:               db "OS VOLUME  "
file_system:                db "FAT     "

include "memory_layout.asm"

boot:
    ;; ========================================================
    ;; Calculate LBA(Logical Blocking Adressing) for fat table
    ;; ========================================================
    ;; FatTableLBA = reserved_sectors
    mov ax, [reserved_sectors]
    mov [fat_lba], ax

    ;; ========================================================
    ;; Load fat table in root_buffer
    ;; ========================================================
    mov bx, fat_segment                     ;; segment to put fat table
    mov es, bx
    mov bx, fat_offset                      ;; offset to put fat table

    mov ax, [fat_lba]                       ;; move fat_lba to ax
    call lba_to_chs                         ;; call lba_to_chs and pupulate ch, cl and dh

    mov al, [sectors_per_fat]               ;; number of sectors
    mov dl, byte [drive_number]             ;; drive number
    call read_disk

    ;; ========================================================
    ;; Calculate LBA(Logical Blocking Adressing) for root directory
    ;; ========================================================
    ;; RootLBA = reserved_sectors + number_of_fats * sectors_per_fat 
    xor ax, ax
    mov al, [number_of_fats]
    mov cx, [sectors_per_fat]
    mul cx
    add ax, word [reserved_sectors]

    mov [root_lba], al

    ;; ========================================================
    ;; Calculate size of root directory
    ;; ========================================================
    ;; RootSize = (number_of_root_dir_entries * 32) / sector_size
    mov ax, [number_of_root_dir_entries]
    shl ax, 5                               ;; multiply by 32
    xor dx, dx
    mov cx, [sector_size]
    div cx

    mov [root_size], ax

    ;; ========================================================
    ;; Load root directory in root_buffer
    ;; ========================================================
    mov bx, root_segment                    ;; segment to put root directory
    mov es, bx
    mov bx, root_offset                     ;; offset to put root directory

    mov ax, [root_lba]                      ;; move root_lba to ax
    call lba_to_chs                         ;; call lba_to_chs and pupulate ch, cl and dh

    mov al, [root_size]                     ;; number of sectors
    mov dl, byte [drive_number]             ;; drive number
    call read_disk

    ;; ========================================================
    ;; Get the first cluster of the kernel
    ;; ========================================================
    ;; This code assumes that the kernel is the first entry of the root directory
    mov bx, root_segment                    ;; segment of root directory
    mov es, bx
    mov bx, root_offset                     ;; offset of root directory

    mov ax, [es:bx + 0x1a]                  ;; get the first cluster by offset the root directory by 0x1a
    mov [kernel_cluster], ax                ;; save in kernel_cluster

    ;; ========================================================
    ;; Load the kernel
    ;; ========================================================
    mov bx, kernel_segment                  ;; segment to put the kernel
    mov es, bx
    mov bx, kernel_offset                   ;; offset to put the kernel

.load_kernel_loop:
    mov ax, [kernel_cluster]
    call cluster_to_lba
    call lba_to_chs

    mov al, 1                               ;; number of sectors (read 1 at time)
    mov dl, byte [drive_number]             ;; drive number
    call read_disk

    ;; ========================================================
    ;; Calculate next cluster of the kernel
    ;; ========================================================
    ;; NextClusterEntry = cluster * 3 / 2
    push es
    push bx

    mov bx, fat_segment
    mov es, bx
    mov bx, fat_offset

    mov ax, [kernel_cluster]

    mov cx, 3
    mul cx                                  ;; multiply cluster by 3
    mov cx, 2
    xor dx, dx
    div cx                                  ;; divide cluster by 2

    add bx, ax
    mov ax, [es:bx]                         ;; get next cluster

    pop bx
    pop es

    test dx, dx
    jz .even                                ;; test remaining of division

    shr ax, 4                               ;; if odd, the shift left by 4
    jmp .next_cluster

.even:
    and ax, 0xfff                           ;; if even, only and with 0xfff
.next_cluster:
    cmp ax, 0xff8                           ;; check if is last cluster
    jae .kernel_loaded

    mov [kernel_cluster], ax                ;; save next cluster
    add bx, [sector_size]                   ;; offset kernel pointer to read next sector

    jmp .load_kernel_loop                   ;; loop

.kernel_loaded:
    mov si, kernel_loaded_string
    call print_string

    mov bx, kernel_segment
    mov es, bx
    mov bx, kernel_offset

    mov ax, kernel_segment                  ;; move to ax the kernel segment

    mov es, ax                              ;; setup es
    mov ds, ax                              ;; setup ds
    mov ss, ax                              ;; setup ss

    jmp kernel_segment:kernel_offset        ;; jump to kernel

    cli
    hlt

;; Calculate LBA(Logical Blocking Adressing) of a given cluster at ax and save it in ax register
;; ax = cluster
cluster_to_lba:
    ;; LBA = (cluster - 2) * sectors_per_cluster + root_start_lba + root_size
    sub ax, 2
    xor cx, cx
    mov cl, [sectors_per_cluster]
    mul cx
    add al, [root_lba]
    add ax, [root_size]

    ret

;; Calculate CHS(Cylinder/Head/Sector) of a geiven LBA(Logical Blocking Addressing) and save cylinder in ch, sector in cl, and head in dh
lba_to_chs:
    xor dx, dx
    div word [sectors_per_track]
    inc dx

    mov cl, dl
    xor dx, dx
    div word [number_of_heads]
    mov dh, dl
    mov ch, al

    ret

;; Read disk
read_disk:
    mov ah, 0x2
    int 0x13
    jc .error
    ret
.error:
    mov si, disk_error_string
    call print_string

    mov dh, 0
    mov dl, ah
    call print_hex

    cli
    hlt

include "lib/print_char.asm"
include "lib/print_string.asm"
include "lib/print_hex.asm"

kernel_loaded_string: db "Kernel loaded successfully...", 0
disk_error_string: db "Can't read disk... status: ", 0

kernel_cluster: rw 1

fat_lba:     rw 1

root_lba:    rw 1
root_size:   rb 1

    times 510-($-$$) db 0x0                 ;; pad file with 0s until reach 510 bytes
    dw 0xaa55                               ;; BIOS magic number
