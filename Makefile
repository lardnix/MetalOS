OS=os

SRC=src
LIB=$(SRC)/lib

BUILD=build
BIN=$(BUILD)/bin

BOOT=$(BIN)/boot.bin
KERNEL=$(BIN)/kernel.bin

HD=$(BUILD)/os.img

$(OS): $(BIN) $(HD) $(BOOT) $(KERNEL)
	dd if=$(BOOT) of=$(HD) bs=512 seek=0 conv=notrunc
	mcopy -o -i $(HD) $(KERNEL) ::/kernel.bin

	echo "Hello, World!" > test.txt
	mcopy -o -i $(HD) test.txt ::/test.txt
	rm test.txt

$(HD): $(BUILD)
	dd if=/dev/zero of=$(HD) bs=512 count=2880
	mkfs.fat -F12 $(HD)

$(BOOT): $(BIN) $(SRC)/boot.asm
	fasm $(SRC)/boot.asm $(BOOT)

$(KERNEL): $(BIN) $(SRC)/kernel.asm
	fasm $(SRC)/kernel.asm $(KERNEL)

$(BIN): $(BUILD)
	mkdir -p $(BIN)

$(BUILD):
	mkdir -p $(BUILD)

run: $(OS)
	qemu-system-i386 -drive format=raw,file=$(HD),index=0,if=floppy -boot order=a

clean:
	rm -rf build/
