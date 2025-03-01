;; Basic kernel

main:
    ;; Setup tty mode 80x25
    mov ah, 0x0                             ;; ah = 0   | set video mode
    mov al, 0x3                             ;; al = 03h | 80x25 color text 
    int 10h

    ;; Show header
    mov si, header
    call puts

input:
    ;; Show input indicator
    mov si, input_indicator
    call puts

    mov di, command_string                  ;; set di to command_string buffer
.key_loop:
    mov ax, 0
    int 0x16

    call putc

    cmp al, 0x0d                            ;; check for 'enter'
    je run_command

    cmp di, command_string + 100            ;; check for buffer oveflow
    je run_command

    mov [di], al                            ;; append character in command buffer
    inc di                                  ;; increment di for next character

    jmp .key_loop                           ;; loop

run_command:
    mov al, 0xa                             ;; print new line
    call putc

    mov BYTE [di], 0                        ;; make command null terminated

    ;; Check 'help' command
    mov si, command_string
    mov di, help_command
    call str_equal
    cmp ax, 1
    je .command_help

    ;; Check 'reboot' command
    mov si, command_string
    mov di, reboot_command
    call str_equal
    cmp ax, 1
    je .command_reboot

    jmp .command_not_found

;; Execute command help
.command_help:
    mov si, help_command_output
    call puts

    jmp input

;; Execute command reboot
.command_reboot:
    jmp 0xffff:0x0

;; Execute when command not found
.command_not_found:
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

%include "putc.asm"
%include "puts.asm"
%include "puth.asm"
%include "str_equal.asm"

header:
    db "Welcome to OS", 0xd, 0xa
    db "-------------", 0xd, 0xa, 0xd, 0xa

    db "type 'help' to list commands", 0xd, 0xa, 0xd, 0xa, 0

input_indicator:
    db "> ", 0

command_file_string:
    db "running file browser command...", 0xd, 0xa, 0

command_not_found_string_begin:
    db "Command '", 0
command_not_found_string_end:
    db "' not found :(", 0xd, 0xa, 0

help_command:
    db "help", 0

reboot_command:
    db "reboot", 0
help_command_output:
    db " - help                   -- show all available commands", 0xd, 0xa
    db " - reboot                 -- reboot pc", 0xd, 0xa, 0


command_string:

    times 512-($-$$) db 0x0  ;; pad file with 0s until reach 512 bytes
