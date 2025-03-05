;; ========================================================
;; Command dir
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

    mov si, path
    call get_entry_from_path

.file_loop:
    mov ax, [es:bx]
    cmp ax, 0                               ;; if first byte is 0, terminate loop
    je .done

    call print_entry                        ;; print entry of file

    add bx, entry_size                      ;; add root entry size in bx to point to the next entry
    loop .file_loop                         ;; loop

.done:
    pop bx
    pop es                                  ;; restore current es:bx

    jmp input                               ;; process next input

print_entry:
    call print_file_created_at

    mov al, " "
    call print_char
    mov al, " "
    call print_char

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

    call print_file_attr

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

print_file_created_at:
    mov ax, [es:bx + 0xe]
    shr ax, 11
    and ax, 11111b
    cmp ax, 10
    jae .print_hour

    push ax
    mov al, "0"
    call print_char
    pop ax

.print_hour:
    mov dx, ax
    call print_decimal

    mov al, ":"
    call print_char

    mov ax, [es:bx + 0xe]
    shr ax, 5
    and ax, 111111b
    cmp ax, 10
    jae .print_min

    push ax
    mov al, "0"
    call print_char
    pop ax

.print_min:
    mov dx, ax
    call print_decimal

    mov al, ":"
    call print_char

    mov ax, [es:bx + 0xe]
    and ax, 11111b
    mov cx, 2
    mul cx

    cmp ax, 10
    jae .print_sec

    push ax
    mov al, "0"
    call print_char
    pop ax

.print_sec:
    mov dx, ax
    call print_decimal

    mov al, " "
    call print_char

    mov ax, [es:bx + 0x10]
    shr ax, 9
    and ax, 1111111b
    add ax, 1980
    mov dx, ax
    call print_decimal

    mov al, "/"
    call print_char

    mov ax, [es:bx + 0x10]
    shr ax, 5
    and ax, 1111b
    cmp ax, 10
    jae .print_month

    push ax
    mov al, "0"
    call print_char
    pop ax

.print_month:
    mov dx, ax
    call print_decimal

    mov al, "/"
    call print_char

    mov ax, [es:bx + 0x10]
    and ax, 11111b
    cmp ax, 10
    jae .print_day

    push ax
    mov al, "0"
    call print_char
    pop ax

.print_day:
    mov dx, ax
    call print_decimal

    ret

print_file_attr:
    mov dh, 0
    mov dl, [es:bx + 0x0b]
    call print_hex
    ret

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

print_file_size:
    push cx

    mov dx, [es:bx + entry_file_size_offset + 2] ;; move upper file size into dx
    mov ax, [es:bx + entry_file_size_offset]     ;; move lower file size into ax
    mov di, print_file_size_buffer_end

    call print_32bit_decimal
    
    mov si, print_file_size_string
    call print_string

    pop cx
    ret

print_file_size_buffer: rb 11
print_file_size_buffer_end:
print_file_size_string: db " bytes", 0

dir_command_label:
    db "Created At           Name      Ext  Attr    Size", 0xd, 0xa
    db "-------------------  --------- ---  ------- ----", 0xd, 0xa, 0xd, 0xa
    db "hh:mm:ss yyyy:mm:dd", 0xd, 0xa, 0xd, 0xa, 0xd, 0xa, 0
