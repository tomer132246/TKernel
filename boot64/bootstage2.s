/* Tomer 2nd part bootloader (loaded at 0x00010000 by stage-1)
 * Switches to long mode, then runs bootmain64.c
 */

.code32
.global tomer_start_bootstage2
.global long_mode_entry

tomer_start_bootstage2:
    cli
    movl $hello_msg, %esi
    call serial_print

    lgdt gdt64_desc

    /* pml4[0] = &pdpt | P|RW */
    lea   pdpt, %eax
    or    $0x03, %eax
    movl  %eax, pml4
    movl  $0,   pml4+4

    /* pdpt[0] = &pd | P|RW */
    lea   pd, %eax
    or    $0x03, %eax
    movl  %eax, pdpt
    movl  $0,   pdpt+4

    /* pd[0] = &pt_id | P|RW (covers VA 0x00000000..0x001FFFFF) */
    lea   pt_id, %eax
    or    $0x03, %eax
    movl  %eax, pd+(0*8)
    movl  $0,   pd+(0*8)+4

    /* -------- Build pt_id: identity map first 2MiB -------- */
    /* PTE[i] = (i*0x1000) | P|RW ; i = 0..511 */
    lea   pt_id, %edi             /* dest table */
    mov   $0x00000003, %eax       /* phys|flags, start at 0 | (P|RW) */
    mov   $512, %ecx              /* 2MiB / 4KiB = 512 PTEs */
1:  mov   %eax, (%edi)            /* low dword of PTE */
    movl  $0, 4(%edi)             /* high dword = 0 */
    add   $0x1000, %eax           /* next 4KiB page, flags stay set */
    add   $8, %edi                /* next PTE (8 bytes) */
    dec   %ecx
    jnz   1b

    /* ------------------------------ */
    /*       Enable long mode         */
    /* ------------------------------ */

    /* Enable PAE (CR4.PAE = 1) */
    mov   %cr4, %eax
    or    $0x20, %eax                /* PAE */
    mov   %eax, %cr4

    /* Load CR3 with PML4 base */
    lea   pml4, %eax
    mov   %eax, %cr3

    /* Set EFER.LME (MSR 0xC000_0080, bit 8) */
    mov   $0xC0000080, %ecx          /* IA32_EFER */
    rdmsr                             /* EDX:EAX = EFER */
    or    $0x00000100, %eax           /* LME=1 */
    wrmsr

    /* Enable paging (CR0.PG = 1). With LME=1+PAE, CPU enters compat. mode. */
    mov   %cr0, %eax
    or    $0x80000000, %eax           /* PG */
    mov   %eax, %cr0

    movl $jumping_msg, %esi
    call serial_print

    /* Far jump to 64-bit code segment to activate 64-bit submode */
    ljmp  *longmode_ptr

/* =============================================================== */
/*                         64-bit mode                             */
/* =============================================================== */
.align 8
longmode_ptr:
    .long long_mode_entry     # 32-bit offset
    .word CODE64_SEL          # 16-bit selector

.code64
long_mode_entry:
    /* Load a data selector (segmentation mostly ignored in 64-bit) */
    mov   $DATA64_SEL, %ax
    mov   %ax, %ds
    mov   %ax, %es
    mov   %ax, %ss

    /*
    movl $jumping_msg, %esi
    call serial_print
    */

    /* Set a 64-bit stack (identity-mapped in first 2MiB) */
    mov   $0x0000000000090000, %rsp

    /* Jump to kernel entry at 0x00200000 (2 MiB) */
    call kernel_entry
    
    

hang64:
    hlt
    jmp hang64

/* =================== Tables & Descriptors ====================== */

.set CODE32_SEL, 0x08
.set DATA32_SEL, 0x10
.set CODE64_SEL, 0x18
.set DATA64_SEL, 0x20
.set KERN_VIRT_BASE, 0x00200000       /* where the kernel expects to run   */
.set KERN_PHYS_BASE, 0x000F0000       /* where you loaded it physically    */
.set KERN_PAGES,     1              /* map 128 * 4KiB = 512 KiB of code  */

/* Minimal GDT: null, 32-bit code, 32-bit data, 64-bit code, data */
.align 8
gdt64:
    .quad 0x0000000000000000          /* null */
    .quad 0x00CF9A000000FFFF          /* 32-bit code: base=0, limit=4G, D=1 */
    .quad 0x00CF92000000FFFF          /* 32-bit data: base=0, limit=4G */
    .quad 0x00AF9A000000FFFF          /* 64-bit code: L=1, D=0, G=1 */
    .quad 0x00AF92000000FFFF          /* data (for DS/SS); L ignored */
gdt64_end:

gdt64_desc:
    .word gdt64_end - gdt64 - 1
    .long gdt64

/* 4K-aligned paging structures */
.align 4096
pml4:     .space 4096, 0
.align 4096
pdpt:     .space 4096, 0
.align 4096
pd:       .space 4096, 0
.align 4096
pt_id:    .space 4096, 0   /* identity 0..2MiB */
.align 4096
/* ---------------------- Misc strings --------------------------- */
hello_msg:
    .ascii "Boot Loader part 2 starting up.. \r\n\0"

jumping_msg:
    .ascii "Jumping to bootmain64.c code...\r\n\0"
    