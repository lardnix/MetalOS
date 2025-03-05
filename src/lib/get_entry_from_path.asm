include "../memory_layout.asm"

;; ========================================================
;; Get entry from current path and put at es:bx
;; ========================================================
get_entry_from_path:
    mov bx, root_segment
    mov es, bx
    mov bx, root_offset

    mov si, path
    inc si
.folder_loop:

    mov al, [si]
    test al, al

    jz .done

    call get_entry_from_path_clean_name_buffer
    mov di, get_entry_from_path_name_buffer
.copy_loop:
    mov al, [si]
    inc si
    cmp al, "/"
    je .get_entry

    mov [di], al
    inc di

    jmp .copy_loop

.get_entry:
    push si

    mov si, get_entry_from_path_name_buffer
    call find_entry

    mov dx, [es:bx + entry_first_cluster_offset]
    test dx, dx
    jz .root

    call load_entry

.retry:

    pop si

    jmp .folder_loop

.done:
    ret

.root:
    mov bx, root_segment
    mov es, bx
    mov bx, root_offset
    jmp .retry

get_entry_from_path_clean_name_buffer:
    mov cx, 11
    mov di, get_entry_from_path_name_buffer
.loop:
    mov byte [di], " "
    inc di
    loop .loop

    ret

get_entry_from_path_name_buffer:
    db "           ", 0
