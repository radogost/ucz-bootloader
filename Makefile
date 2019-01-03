all: build/os-image

clean:
	rm -rf build

build/os-image: build/boot.bin build/kernel.bin
	cat $^ > $@

build/boot.bin: bootloader/boot.asm
	@mkdir -p build
	nasm $< -f bin -o $@ -I './bootloader/'

build/kernel.o: kernel/kernel.c
	@mkdir -p build
	gcc -ffreestanding -m32 -fno-pie -c $< -o $@

build/kernel_entry.o: kernel/kernel_entry.asm
	@mkdir -p build
	nasm $< -f elf32 -o $@

build/kernel.bin: build/kernel_entry.o build/kernel.o
	ld -m elf_i386 -o $@ -Ttext 0x1000 $^ --oformat binary
