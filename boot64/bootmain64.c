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

void
waitdisk(void)
{
    // wait for disk reaady
	while ((inb(0x1F7) & 0xC0) != 0x40)
		/* do nothing */;
}

void
readsect(void *dst, unsigned int hdd_sector_offset)
{
	// wait for disk to be ready
	waitdisk();

	outb(ATA_IO_DRIVE_BASE + ATA_IO_REG_SECCOUNT0_OFFSET, 1);		// sector count
	outb(0x1F3, hdd_sector_offset);
	outb(0x1F4, hdd_sector_offset >> 8);
	outb(0x1F5, hdd_sector_offset >> 16);
	outb(0x1F6, (hdd_sector_offset >> 24) | 0xE0);
	outb(0x1F7, 0x20);	// cmd 0x20 - read sectors

	// wait for disk to be ready
	waitdisk();

	// read a sector - how many dwords? 512(sector size) / dword size = 4.
	insl(0x1F0, dst, 512/4);
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