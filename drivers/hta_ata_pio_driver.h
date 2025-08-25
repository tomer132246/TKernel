#ifndef ATA_PIO_DRIVER_H
#define ATA_PIO_DRIVER_H
#include <stdint.h>

void waitdisk(void);
void readsect(void *dst, unsigned int hdd_sector_offset);

#endif   