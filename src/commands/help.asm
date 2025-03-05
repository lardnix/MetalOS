;; ========================================================
;; Command help
;; ========================================================
command_help:
    mov si, command_help_output
    call print_string

    jmp input

command_help_output:
    db " - help                   -- show all available commands", 0xd, 0xa
    db " - echo                   -- print it's arguments on the screen", 0xd, 0xa
    db " - view                   -- show file content", 0xd, 0xa
    db " - run                    -- run program", 0xd, 0xa
    db " - clear                  -- clear entire screen", 0xd, 0xa
    db " - dir                    -- list root dir", 0xd, 0xa
    db " - disk                   -- show disk information", 0xd, 0xa
    db " - reboot                 -- reboot operating system", 0xd, 0xa, 0
