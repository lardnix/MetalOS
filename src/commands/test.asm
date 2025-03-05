include "../memory_layout.asm"
;; ========================================================
;; Command test
;; ========================================================
command_test:
    call test_get_entry_from_path
    ret


    ;; ========================================================
    ;; Test get_entry_from_path
    ;; ========================================================
test_get_entry_from_path:
    mov si, test_get_entry_from_path_testing
    call print_string

    push es
    push bx

    mov si, test_get_entry_from_path_fake_root_path 
    call get_entry_from_path

    mov ax, es
    cmp ax, root_segment
    jne .test_get_entry_from_path_root_fail
    cmp bx, root_offset
    jne .test_get_entry_from_path_root_fail

    mov si, test_get_entry_from_path_fake_bin_path 
    call get_entry_from_path

    mov ax, es
    cmp ax, loaded_file_segment
    jne .test_get_entry_from_path_bin_fail
    cmp bx, loaded_file_offset
    jne .test_get_entry_from_path_bin_fail

    pop bx
    pop es

    mov si, test_get_entry_from_path_success
    call print_string

    ret

.test_get_entry_from_path_root_fail:
    mov si, test_get_entry_from_path_root_error
    call print_string

    ret
.test_get_entry_from_path_bin_fail:
    mov si, test_get_entry_from_path_bin_error
    call print_string

    ret

test_get_entry_from_path_testing:
    db "[INFO]: Testing 'get_entry_from_path' function ...", 0xd, 0xa, 0

test_get_entry_from_path_root_error:
    db "[ERROR]: Test for 'get_entry_from_path' with path '/' failed.", 0xd, 0xa, 0

test_get_entry_from_path_bin_error:
    db "[ERROR]: Test for 'get_entry_from_path' with path '/BIN/' failed.", 0xd, 0xa, 0

test_get_entry_from_path_success:
    db "[SUCCESS]: Test for 'get_entry_from_path' passed.", 0xd, 0xa, 0

test_get_entry_from_path_fake_root_path: db "/", 0
test_get_entry_from_path_fake_bin_path: db "/BIN/", 0
