
.code32
.globl serial_print

serial_print:
    push %eax
    push %ecx

serial_print_loop:
    movb (%esi), %al
    testb %al, %al
    jz serial_print_done

serial_wait:
    mov $0x3FD, %dx           
    inb  %dx, %al             /* read LSR (port 0x3F8 + 5) */
    testb $0x20, %al          /* bit 5 = THR empty */
    jz serial_wait

    movb (%esi), %al
    mov $0x3F8, %dx           /* COM1 base in DX */
    outb %al, %dx
    incl %esi
    jmp serial_print_loop

serial_print_done:
    pop %ecx
    pop %eax
    ret
    