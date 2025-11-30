bits 16

section .entry

extern __bss_start
extern __end
extern start

global entry


entry:
	cli

    ; save boot drive
    mov [boot_drive], dl

    ; setup stack
    mov ax, ds
    mov ss, ax
    mov sp, 0xFFF0
    mov bp, sp

    ; switch to protected mode
    cli                     ; Disable interrupts
    call enable_a20          ; Enable A20 gate
    call load_gdt            ; Load GDT

    ; set protection enable flag in CR0
    mov eax, cr0
    or al, 1
    mov cr0, eax

    ; far jump into protected mode
    jmp dword 08h:.pmode

.pmode:
    ; we are now in protected mode
    [bits 32]
    
    ; setup segment registers
    mov ax, 0x10
    mov ds, ax
    mov ss, ax

    ; clear bss (uninitialized data)
    mov edi, __bss_start
    mov ecx, __end
    sub ecx, edi
    mov al, 0
    cld
    rep stosb

    ; expect boot drive in dl, send it as argument to start function
    xor edx, edx
    mov dl, [boot_drive]
    push edx
    call start

    cli
    hlt

enable_a20:
    [bits 16]
    ; disable keyboard
    call a20_wait_input
    mov al, KBD_DISABLE_PORT
    out KBD_CMD_PORT, al

    ; read control output port
    call a20_wait_input
    mov al, KBD_READ_CTRL_OUT_PORT
    out KBD_CMD_PORT, al

    call a20_wait_output
    in al, KBD_DATA_PORT
    push eax

    ; write control output port
    call a20_wait_input
    mov al, KBD_WRITE_CTRL_OUT_PORT
    out KBD_CMD_PORT, al
    
    call a20_wait_input
    pop eax
    or al, 2                                    ; bit 2 = A20 bit
    out KBD_DATA_PORT, al

    ; enable keyboard
    call a20_wait_input
    mov al, KBD_ENABLE_PORT
    out KBD_CMD_PORT, al

    call a20_wait_input
    ret

a20_wait_input:
    [bits 16]
    ; wait until status bit 2 (input buffer) is 0
    ; by reading from command port, we read status byte
    in al, KBD_CMD_PORT
    test al, 2
    jnz a20_wait_input
    ret

a20_wait_output:
    [bits 16]
    ; wait until status bit 1 (output buffer) is 1 so it can be read
    in al, KBD_CMD_PORT
    test al, 1
    jz a20_wait_output
    ret

load_gdt:
    [bits 16]
    lgdt [g_gdtdesc]
    ret

KBD_DATA_PORT               equ 0x60
KBD_CMD_PORT                equ 0x64
KBD_DISABLE_PORT            equ 0xAD
KBD_ENABLE_PORT             equ 0xAE
KBD_READ_CTRL_OUT_PORT      equ 0xD0
KBD_WRITE_CTRL_OUT_PORT     equ 0xD1

g_gdt:      ; NULL descriptor
            dq 0

            ; 32-bit code segment
            dw 0FFFFh                   ; limit (bits 0-15) = 0xFFFFF for full 32-bit range
            dw 0                        ; base (bits 0-15) = 0x0
            db 0                        ; base (bits 16-23)
            db 10011010b                ; access (present, ring 0, code segment, executable, direction 0, readable)
            db 11001111b                ; granularity (4k pages, 32-bit pmode) + limit (bits 16-19)
            db 0                        ; base high

            ; 32-bit data segment
            dw 0FFFFh                   ; limit (bits 0-15) = 0xFFFFF for full 32-bit range
            dw 0                        ; base (bits 0-15) = 0x0
            db 0                        ; base (bits 16-23)
            db 10010010b                ; access (present, ring 0, data segment, executable, direction 0, writable)
            db 11001111b                ; granularity (4k pages, 32-bit pmode) + limit (bits 16-19)
            db 0                        ; base high

            ; 16-bit code segment
            dw 0FFFFh                   ; limit (bits 0-15) = 0xFFFFF
            dw 0                        ; base (bits 0-15) = 0x0
            db 0                        ; base (bits 16-23)
            db 10011010b                ; access (present, ring 0, code segment, executable, direction 0, readable)
            db 00001111b                ; granularity (1b pages, 16-bit pmode) + limit (bits 16-19)
            db 0                        ; base high

            ; 16-bit data segment
            dw 0FFFFh                   ; limit (bits 0-15) = 0xFFFFF
            dw 0                        ; base (bits 0-15) = 0x0
            db 0                        ; base (bits 16-23)
            db 10010010b                ; access (present, ring 0, data segment, executable, direction 0, writable)
            db 00001111b                ; granularity (1b pages, 16-bit pmode) + limit (bits 16-19)
            db 0                        ; base high

g_gdtdesc:  dw g_gdtdesc - g_gdt - 1    ; limit = size of GDT
            dd g_gdt                    ; address of GDT

boot_drive: db 0