;; Basic boot loader

    bits 16                                 ;; set mode 16 bits
    org 0x7c00                              ;; origin of boot code

    jmp short boot
    nop

;; ========================================================
;;   FAT12 BPB(BIOS Parameter Block)
;; ========================================================
OEM_label:                  db "mkfs.fat"
sector_size:                dw 512
sectors_per_cluster:        db 1
reserved_sectors:           dw 1 ;; reserved for boot
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
    mov bx, 0x1000                          ;; local to put the fat table in memory
    mov [fat_buffer], bx                    ;; save it in fat_buffer

    mov ax, [fat_lba]                       ;; move fat_lba to ax
    call lba_to_chs                         ;; call lba_to_chs and pupulate ch, cl and dh

    mov ah, 0x2                             ;; disk read sectors
    mov al, [sectors_per_fat]               ;; number of sectors
    mov dl, byte [drive_number]             ;; drive number
    mov bx, [fat_buffer]                    ;; move into bx the fat_buffer pointer
    int 0x13                                ;; read disk and put pointer in es:bx

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
    mov bx, 0x2000                          ;; local to put the root directory in memory
    mov [root_buffer], bx                   ;; save it in root_buffer

    mov ax, [root_lba]                      ;; move root_lba to ax
    call lba_to_chs                         ;; call lba_to_chs and pupulate ch, cl and dh

    mov ah, 0x2                             ;; disk read sectors
    mov al, [root_size]                     ;; number of sectors
    mov dl, byte [drive_number]             ;; drive number
    mov bx, [root_buffer]                   ;; move into bx the root_buffer pointer
    int 0x13                                ;; read disk and put pointer in es:bx

    ;; ========================================================
    ;; Get the first cluster of the kernel
    ;; ========================================================
    ;; This code assumes that the kernel is the first entry of the root directory
    mov bx, [root_buffer]                   ;; move to bx the root_buffer
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

    mov ah, 0x2                             ;; disk read sectors
    mov al, 1                               ;; number of sectors (read 1 at time)
    mov dl, byte [drive_number]             ;; drive number
    int 0x13                                ;; read disk and put pointer in es:bx

    ;; ========================================================
    ;; Calculate next cluster of the kernel
    ;; ========================================================
    ;; NextClusterEntry = cluster * 3 / 2
    mov ax, [kernel_cluster]
    mov si, [fat_buffer]

    mov cx, 3
    mul cx                                  ;; multiply cluster by 3
    mov cx, 2
    xor dx, dx
    div cx                                  ;; divide cluster by 2

    add si, ax
    mov ax, [si]                            ;; get next cluster

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
    call puts

    mov ax, kernel_segment

    mov es, ax
    mov ds, ax

    jmp kernel_segment:kernel_offset        ;; jump to kernel

    cli
    hlt

;; Calculate LBA(Logical Blocking Adressing) of a given cluster at ax and save it in ax register
;; ax = cluster
cluster_to_lba:
    ;; LBA = (cluster - 2) + sectors_per_cluster + root_start_lba + root_size
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

%include "putc.asm"
%include "puts.asm"
%include "puth.asm"

fat_lba:     dw 0
fat_buffer:  dw 0

root_lba:    dw 0
root_size:   db 0
root_buffer: dw 0

kernel_cluster: dw 0
kernel_buffer:  dw 0

kernel_segment: equ 0x3000
kernel_offset: equ 0x0000

kernel_loaded_string: db "Kernel loaded successfully...", 0

    times 510-($-$$) db 0x0                 ;; pad file with 0s until reach 510 bytes
    dw 0xaa55                               ;; BIOS magic number
