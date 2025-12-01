#include <stdint.h>
#include "stdio.h"

void __attribute__((cdecl)) start(uint8_t drive)
{
    clrscr();
    printf("Hello from stage2!\n");

    for(;;);
}