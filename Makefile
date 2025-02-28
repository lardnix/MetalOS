os: bin boot.bin kernel.bin
	cat bin/boot.bin bin/kernel.bin > bin/os.bin

boot.bin: bin
	nasm -f bin -o bin/boot.bin src/boot.asm

kernel.bin: bin
	nasm -f bin -o bin/kernel.bin -i src/lib/ src/kernel.asm

bin:
	mkdir -p bin/

run:
	qemu-system-i386 -drive format=raw,file=bin/os.bin,index=0,if=floppy

clean:
	rm -rf bin/
