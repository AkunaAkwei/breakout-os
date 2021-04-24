[bits 16]
[org 0x7c00]

; set interrupt flag
sti

; get a20 line status
mov ax, 0x2402
int 0x1

; goto start if activated
cmp al, 1
jz _start

; enable a20 line
mov ax, 0x2401
int 0x15

_start:
	cli ; clear interrupt flag

	; setup segment registers
	mov ax, 0
	mov ss, ax ; stack segment
	mov ds, ax ; data segment
	mov es, ax ; extra segment

	lgdt [gdt] ; setup global descriptor table
	; prepare protected mode
	mov eax, cr0
	or eax, 1
	mov cr0, eax
	jmp far_jump



[bits 32]
far_jump:
	; segment registers need to be reloaded after setting gdt up
	mov ax, 0
	mov ss, ax ; stack segment
	mov ds, ax ; data segment
	mov es, ax ; extra segment


	jmp $

[bits 16]
; global descriptor table
gdt:
	dw gdt_end - gdt_start - 1
	dd gdt_start

gdt_start:
gdt_null:
	dq 0
gdt_end:

times 510-($-$$) db 0x00
dw 0xAA55
