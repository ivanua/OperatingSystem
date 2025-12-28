#pragma once

#include <stdint.h>
#include <stdbool.h>

//
// IO ports
//
void __attribute__((cdecl)) x86_outb(uint16_t port, uint8_t value);
uint8_t __attribute__((cdecl)) x86_inb(uint16_t port);

//
// Disk routines
//
bool __attribute__((cdecl)) x86_Disk_CheckExtansionsPresent(uint8_t drive);
bool __attribute__((cdecl)) x86_Disk_ExtansionRead(uint8_t drive, void* dap);