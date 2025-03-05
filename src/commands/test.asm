include "../memory_layout.asm"
;; ========================================================
;; Command test
;; ========================================================
command_test:
    call test_cluster_to_lba
    call test_lba_to_chs
    call test_find_entry
    call test_get_entry_from_path

    ret

;; ========================================================
;; Test cluster_to_lba function
;; ========================================================
test_cluster_to_lba:
    mov si, test_cluster_to_lba_testing
    call print_string

    mov ax, 2
    call cluster_to_lba
    cmp ax, 33
    jne .test_cluster_to_lba_cluster_2_fail

    mov ax, 3
    call cluster_to_lba
    cmp ax, 34
    jne .test_cluster_to_lba_cluster_3_fail

    mov ax, 10
    call cluster_to_lba
    cmp ax, 41
    jne .test_cluster_to_lba_cluster_10_fail

    mov si, test_cluster_to_lba_success
    call print_string

    ret

.test_cluster_to_lba_cluster_2_fail:
    mov si, test_cluster_to_lba_cluster_2_error
    call print_string
    ret

.test_cluster_to_lba_cluster_3_fail:
    mov si, test_cluster_to_lba_cluster_3_error
    call print_string
    ret

.test_cluster_to_lba_cluster_10_fail:
    mov si, test_cluster_to_lba_cluster_10_error
    call print_string
    ret

test_cluster_to_lba_testing:
    db "[INFO]: Testing 'cluter_to_lba' function...", 0xd, 0xa, 0

test_cluster_to_lba_cluster_2_error:
    db "[ERROR] Test for 'cluster_to_lba' with cluster '2' failed.", 0xd, 0xa, 0
test_cluster_to_lba_cluster_3_error:
    db "[ERROR] Test for 'cluster_to_lba' with cluster '3' failed.", 0xd, 0xa, 0
test_cluster_to_lba_cluster_10_error:
    db "[ERROR] Test for 'cluster_to_lba' with cluster '10' failed.", 0xd, 0xa, 0

test_cluster_to_lba_success:
    db "[SUCCESS]: Test for 'cluster_to_lba' function passed.", 0xd, 0xa, 0

;; ========================================================
;; Test lba_to_chs function
;; ========================================================
test_lba_to_chs:
    mov si, test_lba_to_chs_testing
    call print_string
    
    mov ax, 19
    call lba_to_chs
    cmp ch, 0
    jne .test_lba_to_chs_lba_19_fail
    cmp dh, 1
    jne .test_lba_to_chs_lba_19_fail
    cmp cl, 2
    jne .test_lba_to_chs_lba_19_fail

    mov ax, 33
    call lba_to_chs
    cmp ch, 0
    jne .test_lba_to_chs_lba_33_fail
    cmp dh, 1
    jne .test_lba_to_chs_lba_33_fail
    cmp cl, 16
    jne .test_lba_to_chs_lba_33_fail

    mov si, test_lba_to_chs_success
    call print_string

    ret

.test_lba_to_chs_lba_19_fail:
    mov si, test_lba_to_chs_lba_19_error
    call print_string

    ret

.test_lba_to_chs_lba_33_fail:
    mov si, test_lba_to_chs_lba_33_error
    call print_string

    ret

test_lba_to_chs_testing:
    db "[INFO]: Testing 'lba_to_chs' function...", 0xd, 0xa, 0

test_lba_to_chs_lba_19_error:
    db "[ERROR]: Test for 'lba_to_chs' with lba '19' failed.", 0xd, 0xa, 0

test_lba_to_chs_lba_33_error:
    db "[ERROR]: Test for 'lba_to_chs' with lba '33' failed.", 0xd, 0xa, 0

test_lba_to_chs_success:
    db "[SUCCESS] Test for 'lba_to_chs' function passed.", 0xd, 0xa, 0

;; ========================================================
;; Test find_entry function
;; ========================================================
test_find_entry:
    mov si, test_find_entry_testing
    call print_string

    push es
    push bx

    mov bx, root_segment
    mov es, bx
    mov bx, root_offset

    mov si, test_find_entry_hello_file
    call find_entry
    jc .test_find_entry_hello_file_failed

    mov bx, root_segment
    mov es, bx
    mov bx, root_offset

    mov si, test_find_entry_invalid_file
    call find_entry
    jnc .test_find_entry_invalid_file_failed

    pop bx
    pop es

    mov si, test_find_entry_success
    call print_string
    ret

.test_find_entry_hello_file_failed:
    mov si, test_find_entry_hello_file_error
    call print_string

    ret

.test_find_entry_invalid_file_failed:
    mov si, test_find_entry_invalid_file_error
    call print_string

    ret

test_find_entry_hello_file:
    db "HELLO   TXT", 0

test_find_entry_invalid_file:
    db "OLLEH   TXT", 0

test_find_entry_testing:
    db "[INFO]: Testing 'find_entry' function...", 0xd, 0xa, 0

test_find_entry_hello_file_error:
    db "[ERROR]: Test for 'find_entry' with name 'HELLO   TXT' failled", 0xd, 0xa, 0
test_find_entry_invalid_file_error:
    db "[ERROR]: Test for 'find_entry' with name 'OLLEH   TXT' failled", 0xd, 0xa, 0

test_find_entry_success:
    db "[SUCCESS] Test for 'find_entry' function passed.", 0xd, 0xa, 0

;; ========================================================
;; Test get_entry_from_path function
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
    db "[SUCCESS]: Test for 'get_entry_from_path' function passed.", 0xd, 0xa, 0

test_get_entry_from_path_fake_root_path: db "/", 0
test_get_entry_from_path_fake_bin_path: db "/BIN/", 0
