.code16
.global tomer_start_boot
.global .readbootstage2
.global prot32
.global .read_ok

//This is running starting from 0x7C00 VMA in real mode.
tomer_start_boot:
    cli

    xor %ax, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %ss
    mov $0x7C00, %sp          /* simple stack at our load addr */

    movb %dl, boot_drive

    inb  $0x92, %al
    orb  $0x02, %al           /* set A20 bit */
    andb $0xFE, %al           /* clear RESET bit */
    outb %al, $0x92
    
    lgdt gdt_descriptor

    /* ====================== LOAD NEXT STAGE (3 sectors) ===================== */

    /* Read sectors 2, 3, 4 from boot drive */
.readbootstage2:
    /* Load sectors 2..4 (CHS: C=0,H=0,S=2, count=3) to 0x00010000 (ES=0x1000:BX=0) */
    mov  $0x1000, %ax         /* ES = 0x1000 => linear 0x10000 */
    mov  %ax, %es
    xor  %bx, %bx             /* ES:BX = 1000:0000 */
    mov  $3, %si              /* retry counter */
    movb boot_drive, %dl      /* DL = boot drive */
    mov  $0x02, %ah           /* opcode - AH=02h: BIOS read sectors (CHS) */
    mov  $51,    %al           /* (number of sectors to read) AL=3 sectors */
    xor  %ch,   %ch           /* CH=cylinder 0 */
    mov  $2,    %cl           /* start sector CL=sector 2 (sectors start at 1) */
    xor  %dh,   %dh           /* DH=head 0 */
    int  $0x13
    jnc  .read_ok

    /* on error: reset disk and retry */
    movb boot_drive, %dl
    xor  %ax, %ax             /* AH=00h: reset disk system */
    int  $0x13
    dec  %si
    jnz  .readbootstage2
    jmp  disk_fail

.read_ok:
    /* Next-stage (3*512 bytes) is now at linear 0x00010000 */
    /* ======================================================================= */

    /* --- Enter Protected Mode: set CR0.PE --- */
    mov %cr0, %eax
    or  $0x1, %eax            /* CR0.PE = 1 */
    mov %eax, %cr0

    /* --- Far jump to 32-bit code segment (flushes prefetch queue) --- */
    ljmp $0x08, $prot32       /* 0x08 = code selector in our GDT */


/* =============================================================== */
/*                    32-bit PROTECTED MODE                        */
/* =============================================================== */
.code32
prot32:
    /* Load data segments with our 32-bit data selector (0x10) */
    mov $0x10, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %ss

    /* Set up a 32-bit stack somewhere safe (below 1MB is fine) */
    mov $0x90000, %esp

    /* print a string to serial (COM1 @ 0x3F8) */
    movl $hello_msg, %esi
    call serial_print
    mov $0x00010000, %eax   
    jmp *%eax               

hang:
    jmp hang                  /* you're in protected mode now */

disk_fail:
    /* simple halt loop on disk error */
    cli
    hlt
    jmp disk_fail

    /* =========================  GDT  =============================== */
    /* Layout:
       0x00: null
       0x08: code: base=0, limit=4GiB, rx, DPL=0, gran=4K, 32-bit
       0x10: data: base=0, limit=4GiB, rw, DPL=0, gran=4K, 32-bit
    */
    .p2align 3                /* align to 8 bytes */
gdt:
    /* null */
    .long 0x00000000
    .long 0x00000000

    /* code: 0x00cf9a000000ffff */
    .long 0x0000ffff
    .long 0x00cf9a00

    /* data: 0x00cf92000000ffff */
    .long 0x0000ffff
    .long 0x00cf9200
gdt_end:

gdt_descriptor:
    .word  gdt_end - gdt - 1  /* limit (size-1) */
    .long  gdt                /* base (linear/physical for our flat binary) */

boot_drive:
    .byte 0


/* message to print (NUL-terminated) */
hello_msg:
    .ascii "OR SUCK MY DICK, Loading the next stage of the loader.. \r\n\0"
    