;; ========================================================
;; Command cd
;; ========================================================
command_cd:
    cmp word [argc], 2
    jb .not_enough_arguments

    call command_cd_clean_folder_name
    call command_cd_copy_folder_name

    push es
    push bx

    call get_entry_from_path

    mov si, command_cd_name_buffer
    call find_entry
    jc .folder_not_found

    mov ah, 0
    mov al, [es:bx + entry_file_attributes_offset]
    cmp al, 0x10
    jne .not_folder

    mov di, path
.point_to_end_loop:
    mov al, [di]
    test al, al
    jz .append_folder

    inc di
    jmp .point_to_end_loop

.append_folder:
    mov ax, 1
    mov cx, 2
    mul cx

    mov si, argv
    add si, ax
    mov si, [si]

.copy:
    mov al, [si]
    test al, al
    jz .done

    mov al, [si]
    inc si
    mov [di], al
    inc di

    jmp .copy

.done:
    mov byte [di], "/"
    inc di

    pop bx
    pop es

    jmp input

.not_enough_arguments:
    mov si, command_cd_help_string
    call print_string

    jmp input

.folder_not_found:
    mov si, command_cd_folder_not_found_error_begin
    call print_string

    mov si, command_cd_name_buffer
    call print_string

    mov si, command_cd_folder_not_found_error_end
    call print_string

    pop bx
    pop es

    jmp input

.not_folder:
    mov si, command_cd_not_folder_error_begin
    call print_string

    mov si, command_cd_name_buffer
    call print_string

    mov si, command_cd_not_folder_error_end
    call print_string

    pop bx
    pop es

    jmp input

command_cd_clean_folder_name:
    mov cx, 11
    mov di, command_cd_name_buffer
.loop:
    mov byte [di], " "
    inc di
    loop .loop

    ret

command_cd_copy_folder_name:
    mov ax, 1
    mov cx, 2
    mul cx

    mov si, argv
    add si, ax
    mov si, [si]

    mov di, command_cd_name_buffer
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

command_cd_name_buffer:
    db "           ", 0

command_cd_help_string:
    db "[USAGE]: cd <directory>", 0xd, 0xa, 0

command_cd_folder_not_found_error_begin:
    db "[ERROR]: File '", 0

command_cd_folder_not_found_error_end:
    db "' not found.", 0xd, 0xa, 0

command_cd_not_folder_error_begin:
    db "[ERROR]: '", 0

command_cd_not_folder_error_end:
    db "' is not a folder", 0xd, 0xa, 0
