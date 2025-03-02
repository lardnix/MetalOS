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

    call print_file_extension

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

    mov eax, [es:bx + root_entry_file_size_offset] ;; move file size into eax
    mov di, print_file_size_buffer_end
    
    mov ecx, 10
    ;; Add null termination
    dec di
    mov byte [di], 0

.convert:
    xor dx, dx
    div ecx
    add dl, '0'

    dec di
    mov byte [di], dl
    test eax, eax
    jnz .convert

    mov si, di
    call puts

    mov si, print_file_size_string
    call puts

    pop cx
    ret

print_file_size_buffer: rb 11
print_file_size_buffer_end:
print_file_size_string: db " bytes", 0

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
    db " - reboot                 -- reboot pc", 0xd, 0xa, 0xd, 0xa, 0

reboot_command:
    db "reboot", 0

clear_command:
    db "clear", 0

dir_command:
    db "dir", 0

dir_command_label:
    db "Name     Ext Size", 0xd, 0xa
    db "----     --- ----", 0xd, 0xa, 0xd, 0xa, 0

command_string:
    times 100 db 0
