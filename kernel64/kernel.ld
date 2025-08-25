/* boot.ld */
OUTPUT_FORMAT("elf64-x86-64")
ENTRY(kernel_main)

SECTIONS {
  . = 0xFFFFFFFF80000000; /* higher half kernel: */
  .text : { *(.text*) *(.rodata*) }

  . = ALIGN(0x1000);
  .data : { *(.data*) }
  .bss  : { *(.bss*) }

}
