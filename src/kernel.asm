;; Basic kernel

include "memory_layout.asm"

include "lib/fat12/bpb.asm"
include "lib/fat12/root_entry.asm"

input_string_buffer_capacity = 100
arguments_buffer_capacity = 100

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
    call print_string

    ;; ========================================================
    ;; Emulate a basic shell
    ;; ========================================================
input:
    mov si, input_indicator
    call print_string

    call get_input_string
    call parse_input_string

    jmp run_command

    jmp input

;; ========================================================
;; Stores input string in input_string_buffer
;; ========================================================
get_input_string:
    mov di, input_string                    ;; set di to input_string buffer
.key_loop:
    mov ax, 0
    int 0x16                                ;; wait for keystroke and read

    cmp al, 0x08                            ;; check of 'backspace'
    je .handle_backspace

    cmp di, input_string + input_string_buffer_capacity - 1 ;; check for buffer oveflow
    je .overflow

    cmp al, 0x0d                            ;; check for 'enter'
    je .done

    mov [di], al                            ;; append character in command buffer
    inc di                                  ;; increment di for next character

    call print_char                         ;; print input character

    jmp .key_loop                           ;; loop

.handle_backspace:
    cmp di, input_string                    ;; if input_string is empty, do nothing
    je .key_loop

    dec di                                  ;; decrement command string pointer
    mov BYTE [di], 0                        ;; make null terminated

    mov al, 0x8
    call print_char                         ;; move cursor left

    mov al, " "
    call print_char                         ;; print space

    mov al, 0x8
    call print_char                         ;; move cursor left again

    jmp .key_loop                           ;; loop

.overflow:
    mov BYTE [di], 0                        ;; make command null terminated

    mov al, 0xd                             ;; print carriage return
    call print_char
    mov al, 0xa                             ;; print new line
    call print_char

    mov si, input_overflow_string
    call print_string

    ;; keep state of input

    mov si, input_indicator
    call print_string

    mov si, input_string
    call print_string

    jmp .key_loop

.done:
    mov al, 0xd                             ;; print carriage return
    call print_char
    mov al, 0xa                             ;; print new line
    call print_char

    mov BYTE [di], 0                        ;; make command null terminated
    ret

;; ========================================================
;; Parse input_string to separate arguments
;; ========================================================
parse_input_string:
    mov word [argc], 0

    mov di, input_string
    mov si, input_string

    cmp byte [si], " "
    je .skip_extra_spaces

.argument_loop:
    mov al, [si]
    cmp al, " "
    je .append_argument

    cmp al, 0
    je .append_argument

    inc si
    jmp .argument_loop

.append_argument:
    cmp word [argc], arguments_buffer_capacity
    je .arguments_buffer_overflow

    push si

    mov ax, [argc]
    mov cx, 2
    mul cx

    mov si, argv
    add si, ax

    mov [si], di

    inc word [argc]

    pop si

    cmp byte [si], 0
    je .done

    mov byte [si], 0


    mov di, si


.skip_extra_spaces:
    inc si
    inc di

    cmp byte [si], " "
    je .skip_extra_spaces

    jmp .argument_loop

.arguments_buffer_overflow:
    mov si, arguments_overflow_string
    call print_string

    jmp input

.done:
    ret

run_command:
    mov si, [argv]

    ;; ========================================================
    ;; Check 'help' command
    ;; ========================================================
    mov di, help_command
    call string_equal
    cmp ax, 1
    je command_help

    ;; ========================================================
    ;; Check 'echo' command
    ;; ========================================================
    mov di, echo_command
    call string_equal
    cmp ax, 1
    je command_echo

    ;; ========================================================
    ;; Check 'reboot' command
    ;; ========================================================
    mov di, reboot_command
    call string_equal
    cmp ax, 1
    je command_reboot

    ;; ========================================================
    ;; Check 'clear' command
    ;; ========================================================
    mov di, clear_command
    call string_equal
    cmp ax, 1
    je command_clear

    ;; ========================================================
    ;; Check 'dir' command
    ;; ========================================================
    mov di, dir_command
    call string_equal
    cmp ax, 1
    je command_dir

    ;; ========================================================
    ;; Check 'disk' command
    ;; ========================================================
    mov di, disk_command
    call string_equal
    cmp ax, 1
    je command_disk

    jmp command_not_found                   ;; command not found

;; ========================================================
;; Execute command help
;; ========================================================
command_help:
    mov si, help_command_output
    call print_string

    jmp input

;; ========================================================
;; Execute command echo
;; ========================================================
command_echo:

    mov ax, 1
.print_loop:
    cmp ax, [argc]
    jae .done

    push ax

    mov cx, 2
    mul cx

    mov di, argv
    add di, ax

    mov si, [di]
    call print_string

    mov al, " "
    call print_char

    pop ax
    inc ax

    jmp .print_loop

.done:

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
    call print_string                               ;; print label of dir command

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

    add bx, root_entry_size                 ;; add root entry size in bx to point to the next entry
    loop .file_loop                         ;; loop

.done:
    pop bx
    pop es                                  ;; restore current es:bx

    jmp input                               ;; process next input


;; ========================================================
;; Print file entry for dir command
;; ========================================================
print_entry:
    call print_file_name

    mov al, " "
    call print_char
    mov al, " "
    call print_char

    call print_file_extension

    mov al, " "
    call print_char
    mov al, " "
    call print_char

    call print_file_size

    mov al, 0xd
    call print_char

    mov al, 0xa
    call print_char                               ;; put new line

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
    call print_char

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
    call print_char

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
    call print_string

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

;; ========================================================
;; Execute when command not found
;; ========================================================
command_not_found:
    mov si, command_not_found_string_begin
    call print_string

    mov si, input_string
    call print_string
    
    mov si, command_not_found_string_end
    call print_string

    jmp input

end_program:
    cli
    hlt

include "lib/print_char.asm"
include "lib/print_string.asm"
include "lib/print_16bit_hex.asm"
include "lib/print_32bit_decimal.asm"
include "lib/string_equal.asm"

header:
    db "Welcome to OS", 0xd, 0xa, 0xd, 0xa
    db "type 'help' to list commands", 0xd, 0xa, 0

input_indicator:
    db 0xd, 0xa, "> ", 0

input_string: rb input_string_buffer_capacity

input_overflow_string:
    db "Input string overflow.", 0xd, 0xa, 0

argc:
    rw 1
argv:
    rw arguments_buffer_capacity

arguments_overflow_string:
    db "Arguments overflow.", 0xd, 0xa, 0

command_not_found_string_begin:
    db "Command '", 0
command_not_found_string_end:
    db "' not found :(", 0xd, 0xa, 0xd, 0xa
    db "Type 'help' to see command list", 0xd, 0xa, 0

command_not_implemented_string_begin:
    db "Command '", 0
command_not_implemented_string_end:
    db "' is not implemented yet :(", 0xd, 0xa, 0

help_command:
    db "help", 0
help_command_output:
    db " - help                   -- show all available commands", 0xd, 0xa
    db " - echo                   -- print it's arguments on the screen", 0xd, 0xa
    db " - clear                  -- clear entire screen", 0xd, 0xa
    db " - dir                    -- list root dir", 0xd, 0xa
    db " - disk                   -- show disk information", 0xd, 0xa
    db " - reboot                 -- reboot operating system", 0xd, 0xa, 0

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

echo_command:
    db "echo", 0

