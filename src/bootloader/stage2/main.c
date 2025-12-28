#include <stdint.h>
#include "stdio.h"
#include "disk.h"

uint8_t* data = (uint8_t*)0x20000;

void __attribute__((cdecl)) start(uint8_t bootDrive)
{
    clrscr();

    DISK disk;

    if (!DISK_Init(&disk, bootDrive))
    {
        printf("Cannot init disk!\n");
        goto end;
    }

    if (!DISK_Read(&disk, 0, 1, data))
    {
        printf("Cannot read from disk!\n");
        goto end;
    }

    for (int i = 0; i < 512; i++)
    {
        printf("%x", data[i]);
    }

end:
    for(;;);
}