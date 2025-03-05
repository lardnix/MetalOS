include "../memory_layout.asm"
;; ========================================================
;; Command run
;; ========================================================
command_run:
    cmp word [argc], 3
    jb .not_enugh_arguments

    call command_run_clean_filename

    call command_run_copy_filename
    call command_run_copy_file_extension

    call get_entry_from_path

    mov si, command_run_file_buffer

    call find_entry
    jc .file_not_found

    call load_entry

    mov ax, loaded_file_segment             ;; move to ax the kernel segment

    mov es, ax                              ;; setup es
    mov ds, ax                              ;; setup ds
    mov ss, ax                              ;; setup ss

    jmp loaded_file_segment:loaded_file_offset ;; jump to kernel

.not_enugh_arguments:
    mov si, command_run_help_string
    call print_string

    jmp input

.file_not_found:
    pop bx
    pop es

    mov si, command_run_file_not_found_error_begin
    call print_string

    mov si, command_run_file_buffer
    call print_string

    mov si, command_run_file_not_found_error_end
    call print_string

    jmp input

command_run_clean_filename:
    mov cx, 11
    mov di, command_run_file_buffer
.loop:
    mov byte [di], " "
    inc di
    loop .loop

    ret

command_run_copy_filename:
    mov ax, 1
    mov cx, 2
    mul cx

    mov si, argv
    add si, ax
    mov si, [si]

    mov di, command_run_file_buffer

.copy_loop:
    mov al, [si]
    test al, al
    jz .done

    lodsb
    stosb

    jmp .copy_loop

.done:
    ret

command_run_copy_file_extension:
    mov ax, 2
    mov cx, 2
    mul cx

    mov si, argv
    add si, ax
    mov si, [si]

    mov di, command_run_file_buffer
    add di, 8

.copy_loop:
    mov al, [si]
    test al, al
    jz .done

    mov al, [si]
    inc si
    mov [di], al
    inc di

    jmp .copy_loop

.done:
    ret

command_run_file_buffer: db "           ", 0

command_run_help_string:
    db "[USAGE]: run <file_name> <file_extension>", 0xd, 0xa, 0

command_run_file_not_found_error_begin:
    db "[ERROR]: File '", 0

command_run_file_not_found_error_end:
    db "' not found.", 0xd, 0xa, 0
