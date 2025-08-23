/* boot.ld */
OUTPUT_FORMAT("binary")
ENTRY(tomer_start_bootstage2)

SECTIONS {
  . = 0x10000;      /* sets the VMA to start the relocations, etc at 0x10000. */
  .text : { *(.text*) *(.rodata*) }

}
