all: build/kernel.img

clean:
	rm -rf obj
	rm -rf build

obj/boot/boot: bootloader/boot.asm
	@mkdir -p obj/boot
	nasm $< -f elf -o obj/boot/boot.o -I './bootloader/'
	ld -N -Ttext 0x7c00 -m elf_i386 -o obj/boot/bootblock.o obj/boot/boot.o
	@mkdir -p disasm/boot
	objdump -S obj/boot/bootblock.o -M intel > disasm/boot/boot.asm
	objcopy -S -O binary -j .text obj/boot/bootblock.o $@

obj/kernel/kernel_entry.o: kernel/kernel_entry.asm
	@mkdir -p obj/kernel
	nasm $< -f elf -o $@

obj/kernel/kernel.o: kernel/kernel.c
	@mkdir -p obj/kernel
	gcc -c -m32 -static -MD $< -o $@

obj/kernel/kernel: obj/kernel/kernel_entry.o obj/kernel/kernel.o
	@mkdir -p disasm/kernel
	ld -o $@ -m elf_i386 -T kernel/kernel.ld $^
	objdump -S $@ -M intel > disasm/kernel/kernel.asm

build/kernel.img: obj/boot/boot obj/kernel/kernel
	@mkdir -p build
	dd if=/dev/zero of=$@ count=1000 2>/dev/null
	dd if=./obj/boot/boot of=$@ conv=notrunc 2>/dev/null
	dd if=./obj/kernel/kernel of=$@ seek=1 conv=notrunc 2>/dev/null

qemu: build/kernel.img
	qemu-system-i386 -drive file=$<,index=0,media=disk,format=raw

qemu-gdb: build/kernel.img
	qemu-system-i386 -drive file=$<,index=0,media=disk,format=raw -gdb tcp::26000 -S

gdb:
	gdb -n -x .gdbinit
