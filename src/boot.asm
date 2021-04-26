[bits 16]
[org 0x7c00]

_start:
	cli ; clear interrupt flag
	mov [drive_number], dl ; safe the drive number (loaded by bios into dl) somewhere

	; setup segment registers
	; do i need to do this? after lgdt maybe?
	; mov ax, 0
	; mov ss, ax ; stack segment
	; mov ds, ax ; data segment
	; mov es, ax ; extra segment

	; place stack pointer somewhere
	; mov sp, [_end]

	; read kernel into memory
	; TODO

	mov dl, [drive_number]

	; activate a20 line
	sti ; set interrupt flag

	; get a20 line status
	mov ax, 0x2402
	int 0x15

	; ret if activated
	cmp al, 1
	jz .a20_done

.a20_enable:
	; enable a20 line
	mov ax, 0x2401
	int 0x15
	; setting flag failed, recover by trying again
	jnc .a20_enable
.a20_done:
	cli ; clear interrupt flag

	lidt [idt] ; setup interrupt descriptor table
	lgdt [gdt] ; setup global descriptor table

	; segment registers need to be reloaded after setting gdt up
	mov ax, [gdt_data - gdt_start]
	mov ss, ax ; stack segment
	mov ds, ax ; data segment
	mov es, ax ; extra segment
	mov esp, 0x3000

	jmp kernel_jump ; jump into kernel

[bits 32]
; because of 32 bit mode we can access eax
kernel_jump:
	; prepare protected mode, cr0 flag is needed for that
	mov eax, cr0 ; move cr0 into a register
	or eax, 1    ; set it to one
	mov cr0, eax ; move it back

	; jump into kernel at 0x1000
	mov eax, 0x1000
	; jmp [eax]
	jmp $

[bits 16]
; just imagine this is like a data section

; global descriptor table
gdt_start:
gdt_null:
	times 8 db 0x00
gdt_code:
	dw 0xffff    ; limit lower
	dw 0x0000    ; base lower
	db 0x00      ; base middle
    ; access byte:
    ;  a         ; present bit, must be 1
    ;   bb       ; privilege 2bit. 0 = kernel, 3 = user
    ;     c      ; descriptor bit?. set 1 for data or code segment, set 0 for system segment
    ;      d     ; executable bit?. set 1 for code selector, set 0 for data selector
    ;       e    ; if executable bit (d) = 0: then direction bit. set 0 segment grows up, set 1 segment grows down
                 ; if executable bit (d) = 1: set 1 if code can be executed from an equal or lower privilege level,
                 ;                        set 0 if code can only be executed from same level as privilege bit (b)
    ;        f   ; if executable bit (d) = 0, whether write access is allowed, read is always allowed
                 ; is executable bit (d) = 1, whether read access is allowed, write is never allowed
    ;         g  ; set to 0
	db 10010010b ; access byte
	;  a         ; granularity bit. set 0 for 1 byte blocks (byte granularity), set 1 for 4 KiB blocks (page granularity)
	;   b        ; size bit. set 0 for 16 bit protected mode, set 1 for 32 bit protected mode
	;    cc      ; reserved (for 64 bit mode)
	;      dddd  ; limit higher
	db 11001111b ; flags & limit higher
	db 0x00      ; base higher
gdt_data:
	dw 0xffff    ; limit lower
	dw 0x0000    ; base lower
	db 0x00      ; base middle
	db 10010010b ; access byte
	db 11001111b ; flags & limit higher
	db 0x00      ; base higher
gdt_end:

gdt:
	dw gdt_end - gdt_start - 1
	dd gdt_start

; interrupt descriptor table
idt:
	dw 0x0000
	dw 0x0000
	dw 0x0000

; some space to safe the drive number
drive_number:
	dw 0x0000

_end:
	times 510-($-$$) db 0x00
	dw 0xAA55
