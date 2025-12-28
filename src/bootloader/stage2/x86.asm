global x86_outb
global x86_inb

global x86_Disk_CheckExtansionsPresent
global x86_Disk_ExtansionRead

%macro x86_EnterRealMode 0
    [bits 32]
    jmp word 18h:.pmode16         ; 1 - jump to 16-bit protected mode segment

.pmode16:
    [bits 16]
    ; 2 - disable protected mode bit in cr0
    mov eax, cr0
    and al, ~1
    mov cr0, eax

    ; 3 - jump to real mode
    jmp word 00h:.rmode

.rmode:
    ; 4 - setup segments
    mov ax, 0
    mov ds, ax
    mov ss, ax

    ; 5 - enable interrupts
    sti

%endmacro

%macro x86_EnterProtectedMode 0
    cli

    ; 4 - set protection enable flag in CR0
    mov eax, cr0
    or al, 1
    mov cr0, eax

    ; 5 - far jump into protected mode
    jmp dword 08h:.pmode

.pmode:
    ; we are now in protected mode!
    [bits 32]
    
    ; 6 - setup segment registers
    mov ax, 0x10
    mov ds, ax
    mov ss, ax

%endmacro

; Convert linear address to segment:offset address
; Args:
;    1 - linear address
;    2 - (out) target segment (e.g. es)
;    3 - target 32-bit register to use (e.g. eax)
;    4 - target lower 16-bit half of #3 (e.g. ax)
%macro LinearToSegOffset 4

    mov %3, %1      ; linear address to eax
    shr %3, 4
    mov %2, %4
    mov %3, %1      ; linear address to eax
    and %3, 0xF

%endmacro

x86_outb:
    [bits 32]
    mov dx, [esp + 4]
    mov al, [esp + 8]
    out dx, al
    ret

x86_inb:
    [bits 32]
    mov dx, [esp + 4]
    xor eax, eax
    in al, dx
    ret

x86_Disk_CheckExtansionsPresent:
    [bits 32]

    ; make new call frame
    push ebp             ; save old call frame
    mov ebp, esp          ; initialize new call frame

    x86_EnterRealMode

    mov ah, 41h
    mov dl, [bp + 8]    ; dl - drive
    stc
    int 13h

    mov eax, 1
    sbb eax, 0           ; 1 on success, 0 on fail

    push eax

    x86_EnterProtectedMode

    pop eax

    ; restore old call frame
    mov esp, ebp
    pop ebp
    ret

x86_Disk_ExtansionRead:
    [bits 32]

    ; make new call frame
    push ebp             ; save old call frame
    mov ebp, esp         ; initialize new call frame

    x86_EnterRealMode

    ; save modified regs
    push ebx
    push es

    ; setup args
    mov dl, [bp + 8]     ; dl - drive

    LinearToSegOffset [bp + 12], ds, esi, si    ; load DAP to ds:si

    ; call int13h
    mov ah, 42h
    stc
    int 13h

    ; set return value
    mov ax, 1
    sbb ax, 0           ; 1 on success, 0 on fail

    ; restore regs
    pop es
    pop ebx

    push eax

    x86_EnterProtectedMode

    pop eax

    ; restore old call frame
    mov esp, ebp
    pop ebp
    ret