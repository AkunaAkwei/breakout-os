[bits 16]
[org 0x7c00]

mov ax, 0
mov ss, ax
mov ds, ax
mov es, ax

mov si, welcome_msg
call print_string

jmp $

print_string:
    mov ah, 0eh
.next_char:
    lodsb
    cmp al, 0
    je .done
    int 10h
    jmp .next_char
.done:
    ret

welcome_msg db 'Hello World', 0

times 510-($-$$) db 0x00
dw 0xAA55
