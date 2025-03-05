OS=os

SRC=src
LIB=$(SRC)/lib

BUILD=build
BIN=$(BUILD)/bin

BOOT=$(BIN)/boot.bin
KERNEL=$(BIN)/kernel.bin
PROGRAM=$(BIN)/test.bin

HD=$(BUILD)/os.img

$(OS): $(BIN) $(HD) $(BOOT) $(KERNEL) $(PROGRAM)
	dd if=$(BOOT) of=$(HD) bs=512 seek=0 conv=notrunc

	mcopy -o -i $(HD) $(KERNEL) ::/kernel.bin

	if ! mdir -i $(HD) ::/bin > /dev/null 2>&1; then mmd -i $(HD) ::/bin; fi

	mcopy -o -i $(HD) $(PROGRAM) ::/bin/test.bin

	echo "Hello, World!" > hello.txt
	mcopy -o -i $(HD) hello.txt ::/hello.txt
	rm hello.txt

$(HD): $(BUILD)
	dd if=/dev/zero of=$(HD) bs=512 count=2880
	mkfs.fat -F12 $(HD)

$(BOOT): $(BIN) $(SRC)/boot.asm
	fasm $(SRC)/boot.asm $(BOOT)

$(KERNEL): $(BIN) $(SRC)/kernel.asm
	fasm $(SRC)/kernel.asm $(KERNEL)

$(PROGRAM): $(BIN) $(SRC)/programs/test.asm
	fasm $(SRC)/programs/test.asm $(PROGRAM)

$(BIN): $(BUILD)
	mkdir -p $(BIN)

$(BUILD):
	mkdir -p $(BUILD)

run: $(OS)
	qemu-system-i386 -drive format=raw,file=$(HD),index=0,if=floppy -boot order=a

clean:
	rm -rf build/
