;; Basic kernel

include "memory_layout.asm"

include "lib/fat12/bpb.asm"
include "lib/fat12/root_entry.asm"

main:
    ;; ========================================================
    ;; Setup tty mode 80x25
    ;; ========================================================
    mov ah, 0x0                             ;; ah = 0   | set video mode
    mov al, 0x3                             ;; al = 03h | 80x25 color text 
    int 0x10

    ;; ========================================================
    ;; Show header
    ;; ========================================================
    mov si, header
    call puts

    ;; ========================================================
    ;; Emulate a basic shell
    ;; ========================================================
input:
    ;; ========================================================
    ;; Show input indicator
    ;; ========================================================
    mov si, input_indicator
    call puts

    mov di, command_string                  ;; set di to command_string buffer
.key_loop:
    mov ax, 0
    int 0x16                                ;; wait for keystroke and read

    cmp al, 0x0d                            ;; check for 'enter'
    je run_command

    cmp al, 0x08                            ;; check of 'backspace'
    je .handle_backspace

    cmp di, command_string + 100            ;; check for buffer oveflow
    je run_command

    mov [di], al                            ;; append character in command buffer
    inc di                                  ;; increment di for next character

    call putc

    jmp .key_loop

.handle_backspace:
    cmp di, command_string                  ;; if command_string is empty, do nothing
    je .key_loop

    dec di                                  ;; decrement command string pointer
    mov BYTE [di], 0                        ;; make null terminated

    mov al, 0x8
    call putc                               ;; move cursor left

    mov al, " "
    call putc                               ;; put space

    mov al, 0x8
    call putc                               ;; move cursor left again

    jmp .key_loop                           ;; loop

run_command:
    mov al, 0xd                             ;; print carriage return
    call putc
    mov al, 0xa                             ;; print new line
    call putc

    mov BYTE [di], 0                        ;; make command null terminated

    ;; ========================================================
    ;; Check 'help' command
    ;; ========================================================
    mov si, command_string
    mov di, help_command
    call str_equal
    cmp ax, 1
    je command_help

    ;; ========================================================
    ;; Check 'reboot' command
    ;; ========================================================
    mov si, command_string
    mov di, reboot_command
    call str_equal
    cmp ax, 1
    je command_reboot

    ;; ========================================================
    ;; Check 'clear' command
    ;; ========================================================
    mov si, command_string
    mov di, clear_command
    call str_equal
    cmp ax, 1
    je command_clear

    ;; ========================================================
    ;; Check 'dir' command
    ;; ========================================================
    mov si, command_string
    mov di, dir_command
    call str_equal
    cmp ax, 1
    je command_dir

    ;; ========================================================
    ;; Check 'disk' command
    ;; ========================================================
    mov si, command_string
    mov di, disk_command
    call str_equal
    cmp ax, 1
    je command_disk

    jmp command_not_found                   ;; command not found

;; ========================================================
;; Execute command help
;; ========================================================
command_help:
    mov si, help_command_output
    call puts

    jmp input

;; ========================================================
;; Execute command reboot
;; ========================================================
command_reboot:
    jmp 0xffff:0x0

;; ========================================================
;; Execute command clear
;; ========================================================
command_clear:
    ;; This clear entire
    ;; Setup tty mode 80x25
    mov ah, 0x0                             ;; ah = 0   | set video mode
    mov al, 0x3                             ;; al = 03h | 80x25 color text 
    int 10h

    jmp input

;; ========================================================
;; Execute command dir
;; ========================================================
command_dir:
    mov si, dir_command_label
    call puts                               ;; print label of dir command

    push es
    push bx                                 ;; save current es:bx

    mov bx, boot_segment
    mov es, bx
    mov bx, boot_offset                     ;; load boot segment in es:bx

    mov cx, [es:bx + BPB_number_of_root_dir_entries_offset] ;; save max root entries in cx

    mov bx, root_segment
    mov es, bx
    mov bx, root_offset                     ;; load boot segment in es:bx

.file_loop:
    mov ax, [es:bx]
    cmp ax, 0                               ;; if first byte is 0, terminate loop
    je .done

    call print_entry                        ;; print entry of file

    mov al, 0xd
    call putc

    mov al, 0xa
    call putc                               ;; put new line

    add bx, root_entry_size                 ;; add root entry size in bx to point to the next entry
    loop .file_loop                         ;; loop

.done:
    pop bx
    pop es                                  ;; restore current es:bx

    mov al, 0xd
    call putc

    mov al, 0xa
    call putc                               ;; put new line

    jmp input                               ;; process next input


;; ========================================================
;; Print file entry for dir command
;; ========================================================
print_entry:
    call print_file_name

    mov al, " "
    call putc
    mov al, " "
    call putc

    call print_file_extension

    mov al, " "
    call putc
    mov al, " "
    call putc

    call print_file_size

    ret

;; ========================================================
;; Print file name of root entry in es:bx
;; ========================================================
print_file_name:
    push cx
    push si

    mov cx, 8
    xor si, si
.print_loop:
    mov al, [es:bx + si]
    call putc

    add si, 1
    loop .print_loop

    pop si
    pop cx
    ret

;; ========================================================
;; Print file extension of root entry in es:bx
;; ========================================================
print_file_extension:
    push cx
    push si

    mov cx, 3
    mov si, 8
.print_loop:
    mov al, [es:bx + si]
    call putc

    add si, 1
    loop .print_loop

    pop si
    pop cx
    ret

;; ========================================================
;; Print file extension of root entry in es:bx
;; ========================================================
print_file_size:
    push cx

    mov dx, [es:bx + root_entry_file_size_offset + 2]     ;; move upper file size into dx
    mov ax, [es:bx + root_entry_file_size_offset]         ;; move lower file size into ax
    mov di, print_file_size_buffer_end

    call print_32bit_decimal
    
    mov si, print_file_size_string
    call puts

    pop cx
    ret

print_file_size_buffer: rb 11
print_file_size_buffer_end:
print_file_size_string: db " bytes", 0

;; ========================================================
;; Execute command disk
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

    mov si, disk_command_label
    call puts

    ;; Print total size
    mov si, command_disk_total_string
    call puts

    mov dx, [command_disk_total_size + 2]
    mov ax, [command_disk_total_size]

    call print_32bit_decimal

    mov si, command_disk_bytes_string
    call puts

    ;; Print used size
    mov si, command_disk_used_string
    call puts

    mov dx, [command_disk_used_size + 2]
    mov ax, [command_disk_used_size]

    call print_32bit_decimal

    mov si, command_disk_bytes_string
    call puts

    ;; Print free size
    mov si, command_disk_free_string
    call puts

    mov dx, [command_disk_free_size + 2]
    mov ax, [command_disk_free_size]

    call print_32bit_decimal

    mov si, command_disk_bytes_string
    call puts

    mov al, 0xd
    call putc

    mov al, 0xa
    call putc                               ;; put new line

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

;; ========================================================
;; Execute when command not found
;; ========================================================
command_not_found:
    mov si, command_not_found_string_begin
    call puts

    mov si, command_string
    call puts
    
    mov si, command_not_found_string_end
    call puts

    jmp input

end_program:
    cli
    hlt

include "lib/putc.asm"
include "lib/puts.asm"
include "lib/puth.asm"
include "lib/print_32bit_decimal.asm"
include "lib/str_equal.asm"

header:
    db "Welcome to OS", 0xd, 0xa, 0xd, 0xa
    db "type 'help' to list commands", 0xd, 0xa, 0xd, 0xa, 0

input_indicator:
    db "> ", 0

command_not_found_string_begin:
    db "Command '", 0
command_not_found_string_end:
    db "' not found :(", 0xd, 0xa, 0xd, 0xa
    db "Type 'help' to see command list", 0xd, 0xa, 0xd, 0xa, 0

command_not_implemented_string_begin:
    db "Command '", 0
command_not_implemented_string_end:
    db "' is not implemented yet :(", 0xd, 0xa, 0xd, 0xa, 0

help_command:
    db "help", 0
help_command_output:
    db " - help                   -- show all available commands", 0xd, 0xa
    db " - clear                  -- clear entire screen", 0xd, 0xa
    db " - dir                    -- list root dir", 0xd, 0xa
    db " - disk                   -- show information about the disk", 0xd, 0xa
    db " - reboot                 -- reboot pc", 0xd, 0xa, 0xd, 0xa, 0

reboot_command:
    db "reboot", 0

clear_command:
    db "clear", 0

dir_command:
    db "dir", 0

dir_command_label:
    db "Name      Ext  Size", 0xd, 0xa
    db "----      ---  ----", 0xd, 0xa, 0xd, 0xa, 0

disk_command:
    db "disk", 0
disk_command_label:
    db "Disk info", 0xd, 0xa
    db "----------", 0xd, 0xa, 0xd, 0xa, 0

command_string:
    times 100 db 0
