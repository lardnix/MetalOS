all:
	nasm -f bin -o boot.bin boot.asm
	nasm -f bin -o kernel.bin kernel.asm
	cat boot.bin kernel.bin > os.bin

run:
	qemu-system-i386 -drive format=raw,file=os.bin,index=0,if=floppy
