;; Basic kernel

include "memory_layout.asm"

include "lib/fat12/bpb.asm"
include "lib/fat12/root_entry.asm"

input_string_buffer_capacity = 100
arguments_buffer_capacity = 100

main:
    cmp byte [initialized], 0
    ja input

    mov byte [initialized], 1

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

    jmp handle_command

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

handle_command:
    mov si, [argv]

    ;; ========================================================
    ;; Check 'help' command
    ;; ========================================================
    mov di, command_help_name
    call string_equal
    cmp ax, 1
    je command_help

    ;; ========================================================
    ;; Check 'echo' command
    ;; ========================================================
    mov di, command_echo_name
    call string_equal
    cmp ax, 1
    je command_echo

    ;; ========================================================
    ;; Check 'view' command
    ;; ========================================================
    mov di, command_view_name
    call string_equal
    cmp ax, 1
    je command_view

    ;; ========================================================
    ;; Check 'run' command
    ;; ========================================================
    mov di, command_run_name
    call string_equal
    cmp ax, 1
    je command_run

    ;; ========================================================
    ;; Check 'reboot' command
    ;; ========================================================
    mov di, command_reboot_name
    call string_equal
    cmp ax, 1
    je command_reboot

    ;; ========================================================
    ;; Check 'clear' command
    ;; ========================================================
    mov di, command_clear_name
    call string_equal
    cmp ax, 1
    je command_clear

    ;; ========================================================
    ;; Check 'dir' command
    ;; ========================================================
    mov di, command_dir_name
    call string_equal
    cmp ax, 1
    je command_dir

    ;; ========================================================
    ;; Check 'disk' command
    ;; ========================================================
    mov di, command_disk_name
    call string_equal
    cmp ax, 1
    je command_disk

    jmp command_not_found                   ;; command not found

include "commands/help.asm"
include "commands/echo.asm"
include "commands/reboot.asm"
include "commands/clear.asm"
include "commands/run.asm"
include "commands/view.asm"
include "commands/dir.asm"
include "commands/disk.asm"


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

include "lib/read_disk.asm"

include "lib/fat12/lba_to_chs.asm"
include "lib/fat12/cluster_to_lba.asm"
include "lib/fat12/get_next_cluster.asm"
include "lib/fat12/find_file.asm"
include "lib/fat12/load_file.asm"

include "lib/print_char.asm"
include "lib/print_string.asm"
include "lib/print_hex.asm"
include "lib/print_decimal.asm"
include "lib/print_32bit_decimal.asm"
include "lib/string_equal.asm"

initialized:
    rb 1

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

command_help_name:
    db "help", 0
command_reboot_name:
    db "reboot", 0
command_clear_name:
    db "clear", 0
command_dir_name:
    db "dir", 0
command_disk_name:
    db "disk", 0
command_echo_name:
    db "echo", 0
command_view_name:
    db "view", 0
command_run_name:
    db "run", 0
