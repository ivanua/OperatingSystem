org 0x7C00
bits 16

%define ENDL 0x0A, 0x0D

jmp short start

start:
	; setup segments
	mov ax, 0
	mov ds, ax
	mov es, ax

	; setup stack
	mov ss, ax
	mov sp, 0x7C00

	mov si, msg_hello
	call puts

	cli
	hlt

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

msg_hello: db 'Hello world!', ENDL, 0

times 510-($-$$) db 0
dw 0AA55h