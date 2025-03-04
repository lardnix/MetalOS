
# MetalOS

> [!WARNING]
> This project is not finished yet and is only for study purpose, do not use this operating system in produciton.

A tiny a kernel bare metal based operating system. It runs in 16 bits real mode in a floppy disk with 1.44mb.

## TODOs

Some TODOs that i have in my mind.

- [ ] Full FAT12 support (read, write, update, delete...).
- [ ] A tiny text editor for write something.

## How to Build

To be able to build this operating system you first need [FASM](https://flatassembler.net/), [QEMU](https://www.qemu.org/) and mcopy installed in your machine.

After all installed just type.

```
$ make
```

Make command builds the image of operating system and put it on the `build/` folder.

To run the operating system you just type

```
$ make run
```

or

```
$ qemu-system-i386 -drive format=raw,file=build/os.img,index=0,if=floppy -boot order=a
```

## Supported Commands

List of all supported commands.

| Name   | Description                        |
| ------ | ---------------------------------- |
| help   | show all available commands        |
| echo   | print it's arguments on the screen |
| view   | show file content                  |
| run    | run program                        |
| clear  | clear entire screen                |
| dir    | list root directory                |
| disk   | show disk information              |
| reboot | reoot operating system             |
