#include <elf.h>

#define ATA_IO_DRIVE_BASE              0x1F0
#define ATA_IO_REG_DATA_OFFSET         0x00
#define ATA_IO_REG_ERROR_OFFSET        0x01
#define ATA_IO_REG_FEATURES_OFFSET     0x01
#define ATA_IO_REG_SECCOUNT0_OFFSET    0x02
#define ATA_IO_REG_LBA0_OFFSET         0x03
#define ATA_IO_REG_LBA1_OFFSET         0x04
#define ATA_IO_REG_LBA2_OFFSET         0x05
#define ATA_IO_REG_HDDEVSEL_OFFSET     0x06
#define ATA_IO_REG_COMMAND_OFFSET      0x07
#define ATA_IO_REG_STATUS_OFFSET       0x07

#define ATA_CONTROL_BASE               0x3F6
#define ATA_CONTROL_REG_ALTSTATUS_OFFSET 0x00
#define ATA_CONTROL_REG_DEVADDRESS_OFFSET 0x01

#define STATUS_REG_BSY_MASK          0b10000000 /* status offset 0x7, mask: 0x80 */

static inline void outb(unsigned short p, unsigned char v)
{ __asm__ volatile("outb %0,%1"::"a"(v),"Nd"(p)); }
static inline unsigned char inb(unsigned short p)
{ unsigned char r; __asm__ volatile("inb %1,%0":"=a"(r):"Nd"(p)); return r; }

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

void kernel_entry(void){
    serial_init();
    const char *s="Running 64bit .c code now.. reading kernel.main from disk!\n";
    serial_puts(s);
    for(;;);
}