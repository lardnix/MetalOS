;; ========================================================
;; Command view
;; ========================================================
command_view:
    cmp word [argc], 3
    jb .not_enugh_arguments

    call command_view_clean_filename

    call command_view_copy_filename
    call command_view_copy_file_extension

    push es
    push bx

    call get_entry_from_path

    mov si, command_view_file_buffer
    call find_entry
    jc .file_not_found

    ;; only print the first 65535 bytes of the file
    mov cx, [es:bx + entry_file_size_offset]

    call load_entry

.print_loop:
    mov ah, 0xe
    mov al, [es:bx]
    int 0x10

    inc bx
    loop .print_loop

    pop bx
    pop es

    jmp input

.not_enugh_arguments:
    mov si, command_view_help_string
    call print_string

    jmp input

.file_not_found:
    pop bx
    pop es

    mov si, command_view_file_not_found_error_begin
    call print_string

    mov si, command_view_file_buffer
    call print_string

    mov si, command_view_file_not_found_error_end
    call print_string

    jmp input

command_view_clean_filename:
    mov cx, 11
    mov di, command_view_file_buffer
.loop:
    mov byte [di], " "
    inc di
    loop .loop

    ret

command_view_copy_filename:
    mov ax, 1
    mov cx, 2
    mul cx

    mov si, argv
    add si, ax
    mov si, [si]

    mov di, command_view_file_buffer

.copy_loop:
    mov al, [si]
    test al, al
    jz .done

    lodsb
    stosb

    jmp .copy_loop

.done:
    ret

command_view_copy_file_extension:
    mov ax, 2
    mov cx, 2
    mul cx

    mov si, argv
    add si, ax
    mov si, [si]

    mov di, command_view_file_buffer
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

command_view_file_buffer: db "           ", 0


command_view_help_string:
    db "[USAGE]: view <file_name> <file_extension>", 0xd, 0xa, 0

command_view_file_not_found_error_begin:
    db "[ERROR]: File '", 0

command_view_file_not_found_error_end:
    db "' not found.", 0xd, 0xa, 0
