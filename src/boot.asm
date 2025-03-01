;; Basic boot loader

    bits 16                  ;; set mode 16 bits
    org 0x7c00               ;; origin of boot code

    ;; Setup es:bx memory address to read sectors
    mov ax, 0x1000
    mov es, ax               ;; load sectors as 0x1000
    mov bx, 0x0              ;; es:bx=0x1000:0

    ;; Setup disk read
    mov ch, 0x0              ;; ch = 00h | track/cylinder number (0-1023 dec.)
    mov cl, 0x2              ;; cl = 02h | sector number (1-17 dec.)
    mov dh, 0x0              ;; dh = 00h | header number (0-15 dec.)
    mov dl, 0x0              ;; dl = 00h | drive number (0=A:, 1=2nd floppy, 80h=drive 0, 81h=drive 1)

.read_disk:
    mov ah, 0x2              ;; ah = 02h | read disk sectors
    mov al, 0x2              ;; al = dh  | number of sectors to read
    int 0x13
    jc .read_disk

    mov ax, 0x1000
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    jmp 0x1000:0x0           ;; jump to kernel

    times 510-($-$$) db 0x0  ;; pad file with 0s until reach 510 bytes
    dw 0xaa55                ;; BIOS magic number
