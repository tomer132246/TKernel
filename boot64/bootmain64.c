#include <elf.h>
#include <stdint.h>
#include "hta_ata_pio_driver.h"

extern uint64_t pml4[512];
extern uint64_t pdpt[512];
extern uint64_t pd[512];
extern uint64_t pt_id[512]; // identity map the first 2MB of memory


static inline void outb(unsigned short p, unsigned char v)
{ __asm__ volatile("outb %0,%1"::"a"(v),"Nd"(p)); }
static inline unsigned char inb(unsigned short p)
{ unsigned char r; __asm__ volatile("inb %1,%0":"=a"(r):"Nd"(p)); return r; }
static inline void insl(int port, void *addr, int cnt){
    asm volatile (
        "cld\n\trepne insl"
        : "+D" (addr), "+c" (cnt) //tomer: remember these are outputs.
        : "d" (port)              //inputs
        : "memory");              //clobbers - dont re-organize.
}

static void serial_init(void){
    outb((unsigned short)0x3F8+1,0); 
    outb((unsigned short)0x3F8+3,0x80);
    outb((unsigned short)0x3F8+0,3); 
    outb((unsigned short)0x3F8+1,0);
    outb((unsigned short)0x3F8+3,0x03); 
    outb((unsigned short)0x3F8+2,0xC7); 
    outb((unsigned short)0x3F8+4,0x0B);
}


static void serial_putc(char c)
{ 
    while(!(inb(0x3F8+5)&0x20))
    { ; }
    outb(0x3F8,c); 
}

static void serial_puts(const char *s)
{
    while(*s) 
    {
        serial_putc(*s++);
    }
}

static void print_byte_as_hex(unsigned char byte)
{
    serial_putc("0123456789ABCDEF"[(byte >> 4) & 0xF]);
    serial_putc("0123456789ABCDEF"[(byte) & 0xF]);
}

static void serial_puts_hex(const unsigned char *data, int size)
{
    int i;
    
    for(i = 0; i < size; i++)
    {
        if(i % 8 == 0)
        {
            if(i > 0)
                serial_putc('\n');
        }
        
        unsigned char byte = data[i];
        print_byte_as_hex(byte);
        serial_putc(' ');
    }
    
    if(size > 0)
        serial_putc('\n');
}

void kernel_entry(void){
    char buff[520] = {0};
    readsect(buff, 0); //read sector 201 (sector 200 is the
    serial_init();
    const char *s="Running 64bit .c code now.. reading kernel.main from disk!\n";
    serial_puts(s);
    serial_puts("Ex: Reading the first 512 bytes of the bootloader:\n");
    serial_puts_hex(buff, 512);

    /*Migrate the page tables. */
    /*Map the first 4GB of the address space to be liniear*/
    // char pml4[4096] __attribute__((aligned(4096))) = {0};
    // char pdpt[4096] __attribute__((aligned(4096))) = {0};
    // char pd[4096] __attribute__((aligned(4096))) = {0};
    // char pt[4096] __attribute__((aligned(4096))) = {0};
    
    for(;;);
}