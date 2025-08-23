# TKernel Makefile. Builds the bootloader, assembles the disk image to be loaded by QEMU or real hardware.
ASSEMBLER = x86_64-elf-as
LINKER = x86_64-elf-ld
GCC = x86_64-elf-gcc
GCCFLAGS = -ffreestanding -mno-red-zone -mcmodel=kernel -O0 -Wall -Wextra -Iinc #-g -O0 -c
LINKER_BINARY_FLAGS = --oformat binary
BOOT_DIR = boot64

.ONESHELL:

# Build all targets
all: cleanall disk.img clean

# Final disk img - to be loaded by qemu.
disk.img: boot.bin boot2.bin
	dd if=boot.bin   of=disk.img conv=notrunc bs=512 seek=0 count=1
	dd if=boot2.bin   of=disk.img conv=notrunc bs=512 seek=1
	dd if=/dev/zero of=disk.img conv=notrunc bs=512 seek=50 count=100

# Link boot.o to boot.bin
boot.bin: boot.o protmode_print.o
	$(LINKER) -T $(BOOT_DIR)/boot.ld -Map=boot1.map $(LINKER_BINARY_FLAGS) -o boot.bin boot.o protmode_print.o

# Build boot.o object file
boot.o: $(BOOT_DIR)/boot.s
	$(ASSEMBLER) -o boot.o $(BOOT_DIR)/boot.s

# Build protmode_print.o object file
protmode_print.o: $(BOOT_DIR)/protmode_print.inc
	$(ASSEMBLER) -o protmode_print.o $(BOOT_DIR)/protmode_print.inc

# Second bootloader stage: 2nd stage loaded by first stage
boot2.o: $(BOOT_DIR)/boot2.s
	$(ASSEMBLER) -o boot2.o $(BOOT_DIR)/boot2.s

# Build bootmain64.o object file
bootmain64.o: $(BOOT_DIR)/bootmain64.c
	$(GCC) $(GCCFLAGS) -c $(BOOT_DIR)/bootmain64.c -o bootmain64.o

# Link boot2.o and bootmain64.o to 2nd stage boot2.bin
boot2.bin: boot2.o bootmain64.o protmode_print.o
	$(LINKER) -T $(BOOT_DIR)/boot2.ld -Map=boot2.map $(LINKER_BINARY_FLAGS) -o boot2.bin boot2.o bootmain64.o protmode_print.o

.PHONY: clean cleanall
cleanall:
	rm -f *.o *.bin *.map disk.img
clean:
	rm -f *.o *.bin