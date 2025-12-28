#pragma once

#include <stdint.h>
#include <stdbool.h>

typedef struct
{
    uint8_t drive;
} DISK;

bool DISK_Init(DISK* disk, uint8_t drive);
bool DISK_Read(DISK* disk, uint64_t lba, uint16_t sectors, void* lowerDataOut);