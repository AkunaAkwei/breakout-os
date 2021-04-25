[bits 16]
[org 0x7c00]

_start:
	cli ; clear interrupt flag
	mov [drive_number], dl ; safe the drive number (loaded by bios into dl) somewhere

	; setup segment registers
	mov ax, 0
	mov ss, ax ; stack segment
	mov ds, ax ; data segment
	mov es, ax ; extra segment

	; place stack pointer somewhere
	mov sp, [_end]

	; read kernel into memory
	; TODO

	mov dl, [drive_number]

	lidt [idt] ; setup interrupt descriptor table
	lgdt [gdt] ; setup global descriptor table

	; segment registers need to be reloaded after setting gdt up
	mov ax, 0
	mov ss, ax ; stack segment
	mov ds, ax ; data segment
	mov es, ax ; extra segment

	call a20_line ; activate a20 line
	jmp kernel_jump ; jump into kernel

; activate a20 line
a20_line:
	sti ; set interrupt flag

	; get a20 line status
	mov ax, 0x2402
	int 0x15

	; ret if activated
	cmp al, 1
	jz .done

.enable:
	; enable a20 line
	mov ax, 0x2401
	int 0x15
	; setting flag failed, recover by trying again
	jnc .enable
.done:
	cli ; clear interrupt flag
	ret

[bits 32]

; because of 32 bit mode we can access eax
kernel_jump:
	; prepare protected mode, cr0 flag is needed for that
	mov eax, cr0 ; move cr0 into a register
	or eax, 1    ; set it to one
	mov cr0, eax ; move it back

	; jump into kernel at 0x1000
	mov eax, 0x1000
	jmp [eax]

[bits 16]
; just imagine this is like a data section

; global descriptor table
gdt:
	dw gdt_end - gdt_start - 1
	dd gdt_start

gdt_start:
gdt_null:
	dq 0
gdt_end:

; interrupt descriptor table
idt:
	dw 0
	dw 0
	dw 0

; some space to safe the drive number
drive_number:
	dw 0

_end:
	times 510-($-$$) db 0x00
	dw 0xAA55
