;; Basic kernel

main:
    ;; Setup tty mode 80x25
    mov ah, 0x0              ;; ah = 0   | set video mode
    mov al, 0x3              ;; al = 03h | 80x25 color text 
    int 10h

    mov si, header
    call puts

input:
    mov si, input_indicator
    call puts

    mov di, command_string
.key_loop:
    mov ax, 0
    int 0x16

    call putc

    cmp al, 0x0d
    je run_command

    mov [di], al
    inc di

    jmp .key_loop

run_command:
    mov al, 0xa
    call putc

    mov BYTE [di], 0

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

.command_help:
    mov si, help_command_output
    call puts

    jmp input

.command_reboot:
    jmp 0xffff:0x0

.command_not_found:
    mov si, command_not_found_string
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

command_not_found_string:
    db "Command not found :(", 0xd, 0xa, 0

help_command:
    db "help", 0

reboot_command:
    db "reboot", 0
help_command_output:
    db "    help                   -- show all available commands", 0xd, 0xa
    db "    reboot                 -- reboot pc", 0xd, 0xa, 0


command_string:

    times 512-($-$$) db 0x0  ;; pad file with 0s until reach 512 bytes
