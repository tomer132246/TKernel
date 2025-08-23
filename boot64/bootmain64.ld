OUTPUT_FORMAT("elf64-x86-64")
ENTRY(kernel_entry)
SECTIONS {
  . = 0x200000 + SIZEOF_HEADERS;
  .text : { *(.text*) }
  .rodata : { *(.rodata*) }
  . = ALIGN(0x1000);
  .data : { *(.data*) }
  .bss  : { *(.bss*) }
}