
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
{ 
	__asm__ volatile("outb %0,%1"::"a"(v),"Nd"(p)); 
}

static inline unsigned char inb(unsigned short p)
{ 
	unsigned char r;
	__asm__ volatile("inb %1,%0":"=a"(r):"Nd"(p));
	return r; 
}

static inline void insl(int port, void *addr, int cnt){
    asm volatile (
        "cld\n\trepne insl"
        : "+D" (addr), "+c" (cnt) //tomer: remember these are outputs.
        : "d" (port)              //inputs
        : "memory");              //clobbers - dont re-organize.
}

void waitdisk(void)
{
	while ((inb(0x1F7) & 0xC0) != 0x40);
}

void readsect(void *dst, unsigned int hdd_sector_offset)
{
	// wait for disk to be ready
	waitdisk();

	outb(0x1F0 + 0x2, 1);		// sector count
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