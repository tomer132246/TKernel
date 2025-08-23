/* boot.ld */
OUTPUT_FORMAT("binary")
ENTRY(tomer_start_boot)

SECTIONS {
  . = 0x7C00;      /* ← this is the “org 0x7C00” - sets the VMA to start the relocations, etc at 0x7C00. */
  .text : { *(.text*) *(.rodata*) }

  . = 0x7DFE;      /* 0x7C00 + 510 */
  .sig : { BYTE(0x55); BYTE(0xAA); }

  . = 0x7E00;      /* total size = 512 bytes */
}
