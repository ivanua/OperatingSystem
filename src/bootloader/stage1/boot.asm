org 0x7C00
bits 16

%define ENDL 0x0A, 0x0D

;
; FAT header
;
jmp short start
nop

bpb_oem:					db 'MSWIN4.1'			; OEM ID
bpb_bytes_per_sector:		dw 512
bpb_sectors_per_cluster:	db 1
bpb_reserved_sectors:		dw 1
bpb_fat_count:				db 2
bpb_dir_entries_count:		dw 0E0h
bpb_total_sectors:			dw 2880					; 2880 * 512 = 1.44MB
bpb_media_descriptor_type:	db 0F0h					; F0 = 3.5" floppy disk
bpb_sectors_per_fat:		dw 9					; 9 sectors/fat
bpb_sectors_per_track:		dw 18
bpb_head:					dw 2
bpb_hidden_sectors:			dd 0
bpb_large_sector_count:		dd 0

; extended boot record
ebr_drive_number:			db 0					; 0x00 floppy, 0x80 hdd, useless
							db 0					; reserved
ebr_signature:				db 29h
ebr_volume_id:				db 11h, 22h, 33h, 44h 	; serial, number, value doesn't matter
ebr_volume_label:			db 'MYOS       '		; 11 bytes, padded with spaces
ebr_file_system:			db 'FAT12   '

times 90-($-$$) db 0

;
; Code goes here
;

start:
	; setup segments
	mov ax, 0
	mov ds, ax
	mov es, ax

	; setup stack
	mov ss, ax
	mov sp, 0x7C00

	; some BIOSes might start us at 07C0:0000 instead of 0000:7C00, make sure we are in the
    ; expected location
    push es
    push word .main
    retf

.main:
	; read something from floppy disk
    ; BIOS should set DL to drive number
    mov [ebr_drive_number], dl

    ; show loading message
    mov si, msg_loading
    call puts

    ; check extensions present
    mov ah, 0x41
    mov bx, 0x55AA
    stc
    int 13h

    jc .no_disk_extensions
    cmp bx, 0xAA55
    jne .no_disk_extensions

    ; extensions are present
    mov byte [have_extensions], 1
    jmp .after_disk_extensions_check

.no_disk_extensions:
    mov byte [have_extensions], 0

.after_disk_extensions_check:
    ; load stage2
    mov si, stage2_location

    mov ax, STAGE2_LOAD_SEGMENT         ; set segment registers
    mov es, ax
    mov bx, STAGE2_LOAD_OFFSET

.loop:
    mov eax, [si]
    add si, 4
    mov cl, [si]
    inc si

    cmp eax, 0
    je .read_finish

    call disk_read

    xor ch, ch
    shl cx, 5
    mov di, es
    add di, cx
    mov es, di

    jmp .loop

.read_finish:
    
    ; jump to our stage2
    mov dl, [ebr_drive_number]          ; boot device in dl

    mov ax, STAGE2_LOAD_SEGMENT         ; set segment registers
    mov ds, ax
    mov es, ax

    jmp STAGE2_LOAD_SEGMENT:STAGE2_LOAD_OFFSET

    jmp wait_key_and_reboot             ; should never happen

.halt:
	cli
	hlt

;
; Reads sectors from a disk
; Parameters:
;   - eax: LBA address
;   - cl: number of sectors to read (up to 128)
;   - dl: drive number
;   - es:bx: memory address where to store read data
;
disk_read:
    push eax                            ; save registers we will modify
    push bx
    push cx
    push dx
    push si
    push di

    cmp byte [have_extensions], 1
    jne disk_no_extensions

    ; with extensions
    mov [extensions_dap.lba], eax
    mov [extensions_dap.segment], es
    mov [extensions_dap.offset], bx
    mov [extensions_dap.count], cl

    mov ah, 0x42
    mov si, extensions_dap
    mov di, 3                           ; retry count

.retry:
    pusha                               ; save all registers, we don't know what bios modifies
    stc                                 ; set carry flag, some BIOS'es don't set it
    int 13h                             ; carry flag cleared = success
    jnc .done                           ; jump if carry not set

    ; read failed
    popa
    call disk_reset

    dec di
    test di, di
    jnz .retry

.fail:
    ; all attempts are exhausted
    jmp disk_read_error

.done:
    popa

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop eax                            ; restore registers modified
    ret

;
; Resets disk controller
; Parameters:
;   dl: drive number
;
disk_reset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc disk_read_error
    popa
    ret

;
; Error handlers
;

disk_read_error:
    mov si, msg_read_failed
    call puts
    jmp wait_key_and_reboot

disk_no_extensions:
	mov si, msg_no_extensions
    call puts
    jmp wait_key_and_reboot

wait_key_and_reboot:
    mov ah, 0
    int 16h                     ; wait for keypress
    jmp 0FFFFh:0                ; jump to beginning of BIOS, should reboot

;
; Write text to screen
; Params:
;	- ds:si - points to string
;
puts:
	push ax
	push si

.loop:
	lodsb				; load byte from ds:si to al
	or al, al			; check if al == 0

	jz .done

	mov ah, 0x0e
	mov bh, 0 			; set page number to 0
	int 0x10			; call interrupt 10h

	jmp .loop

.done:
	pop si
	pop ax
	ret

msg_loading: 			db 'Loading stage2...', ENDL, 0
msg_read_failed:        db 'Disk error: read failed!', ENDL, 0
msg_no_extensions:		db 'Disk error: no extensions!', ENDL, 0

have_extensions:        db 0
extensions_dap:
    .size:              db 10h
                        db 0
    .count:             dw 0
    .offset:            dw 0
    .segment:           dw 0
    .lba:               dq 0

STAGE2_LOAD_SEGMENT		equ 0x0
STAGE2_LOAD_OFFSET		equ 0x500

times 510-30-($-$$) db 0

stage2_location:		times 30 db 0

dw 0AA55h