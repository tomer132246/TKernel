# TKernel Makefile. Builds the bootloader, assembles the disk image to be loaded by QEMU or real hardware.
ASSEMBLER = x86_64-elf-as
LINKER = x86_64-elf-ld
GCC = x86_64-elf-gcc
ARCHIVER = x86_64-elf-ar
GCCFLAGS = -ffreestanding -mno-red-zone -mcmodel=kernel -O0 -Wall -Wextra -Iinc -Idrivers #-g -O0 -c
LINKER_BINARY_FLAGS = --oformat binary
BOOT_DIR = boot64
KERNEL_DIR = kernel64

.ONESHELL:

# Build all targets
all: disk.img cleanobj
allclean: cleanall disk.img clean

# Final disk img - to be loaded by qemu.
disk.img: boot.bin bootstage2.bin kernel.elf
	dd if=boot.bin   of=disk.img conv=notrunc bs=512 seek=0 count=1
	dd if=bootstage2.bin   of=disk.img conv=notrunc bs=512 seek=1
	dd if=/dev/zero of=disk.img conv=notrunc bs=512 seek=200 count=100
	dd if=kernel.elf of=disk.img conv=notrunc bs=512 seek=300

# Link boot.o to boot.bin
boot.bin: boot.o protmode_print.o
	$(LINKER) -T $(BOOT_DIR)/bootstage1.ld -Map=bootstage1.map $(LINKER_BINARY_FLAGS) -o boot.bin boot.o protmode_print.o

# Build boot.o object file
boot.o: $(BOOT_DIR)/bootstage1.s
	$(ASSEMBLER) -o boot.o $(BOOT_DIR)/bootstage1.s

kernel.o: $(KERNEL_DIR)/kernel64.c
	$(GCC) $(GCCFLAGS) -g -c $(KERNEL_DIR)/kernel64.c -o kernel.o

kernel.elf: kernel.o
	$(LINKER) -T $(KERNEL_DIR)/kernel.ld -z max-page-size=0x1000 -Map=kernel.map -o kernel.elf kernel.o

# Build protmode_print.o object file
protmode_print.o: $(BOOT_DIR)/protmode_print.inc
	$(ASSEMBLER) -o protmode_print.o $(BOOT_DIR)/protmode_print.inc

# Second bootloader stage: 2nd stage loaded by first stage
bootstage2.o: $(BOOT_DIR)/bootstage2.s
	$(ASSEMBLER) -o bootstage2.o $(BOOT_DIR)/bootstage2.s

# Build bootmain64.o object file
bootmain64.o: $(BOOT_DIR)/bootmain64.c 
	$(GCC) $(GCCFLAGS) -c $(BOOT_DIR)/bootmain64.c -o bootmain64.o

# Link bootstage2.o and bootmain64.o to 2nd stage bootstage2.bin
bootstage2.bin: bootstage2.o bootmain64.o protmode_print.o hdd_ata_pio_driver.a
	$(LINKER) -T $(BOOT_DIR)/bootstage2.ld -Map=bootstage2.map $(LINKER_BINARY_FLAGS) -o bootstage2.bin bootstage2.o bootmain64.o protmode_print.o -L. -lhdd_ata_pio_driver

hdd_ata_pio_driver.o: drivers/hdd_ata_pio_driver.c drivers/hta_ata_pio_driver.h
	$(GCC) $(GCCFLAGS) -c drivers/hdd_ata_pio_driver.c -o hdd_ata_pio_driver.o

hdd_ata_pio_driver.a: hdd_ata_pio_driver.o
	$(ARCHIVER) rcs libhdd_ata_pio_driver.a hdd_ata_pio_driver.o

.PHONY: clean cleanall cleanobj
cleanall:
	rm -f *.o *.bin *.map disk.img *.elf *.a
clean:
	rm -f *.o *.bin *.elf
cleanobj:
	rm -f *.o