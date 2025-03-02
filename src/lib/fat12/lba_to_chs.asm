include "../../memory_layout.asm"

include "bpb.asm"

;; Calculate CHS(Cylinder/Head/Sector) of a geiven LBA(Logical Blocking Addressing) and save cylinder in ch, sector in cl, and head in dh
lba_to_chs:
    push es
    push bx

    ;; Move es:bx to point at boot segment
    mov bx, boot_segment
    mov es, bx
    mov bx, boot_offset

    xor dx, dx
    div word [es:bx + BPB_sectors_per_track_offset]
    inc dx

    mov cl, dl
    xor dx, dx
    div word [es:bx + BPB_number_of_heads_offset]
    mov dh, dl
    mov ch, al

    pop bx
    pop es

    ret
