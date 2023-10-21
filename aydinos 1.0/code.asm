[org 0x7c00]
[bits 16]

    jmp bootloader
    nop

OEM_identifier:         db "MSWIN4.1"
Bytespersector:         dw 512
Sectorspercluster:      db 4
reservedsectors:        dw 2
FATs:                   db 2
rootentries:            dw 512
totalsectors:           dw 63
mediadescriptortype:    db 0xf0
sectorsperFAT:          dw 20
sectorspertrack:        dw 63
heads:                  dw 16
hiddensectors:          dd 0
largesectors:           dd 0
boot_disk:              db 0
reservedflags:          db 0
signature:              db 0x29
serial_number:          dd 0x2d7e5a1a
volume_label:           db "BAKSTEEN1  "
systemidentifier:       db "FAT12", 0, 0, 0

bootloader:
    xor ax, ax
    mov bp, 0xffff
    mov sp, bp
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov [boot_disk], dl

    mov ax, 0003h
    int 10h
    mov ax, 0E41h
    int 10h
    mov ah, 2h
    mov al, 62
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov bx, 0x7e00
    int 13h
    mov ah, 1h
    int 13h
    cmp ah, 0
    jne error

    mov ax, 0E42h
    int 10h

    cli
    in al, 0x92
    or al, 2
    out 0x92, al
    lgdt [GDT_descriptor]
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp 08h:start_protected_mode

error:
    mov ax, 0E45h
    int 10h
    jmp $

GDT_start:
    GDT_null:
        dd 0x0
        dd 0x0
    GDT_code:
        dw 0xffff
        dw 0x0
        db 0x0
        db 0b10011010
        db 0b11001111
        db 0x0
    GDT_data:
        dw 0xffff
        dw 0x0
        db 0x0
        db 0b10010010
        db 0b11001111
        db 0x0
GDT_end:

GDT_descriptor:
    dw GDT_end - GDT_start - 1
    dd GDT_start

%define PIC1 0x20
%define PIC2 0xA0
%define ps2data 0x60
%define ps2status 0x64
%define ps2command 0x64

[bits 32]
start_protected_mode:

    mov ax, 16
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov ebp, 0xFFFF
    mov esp, ebp
    mov word [0xb8004], 0x0f43
    jmp removecursor

times 510 - ($ - $$) db 0
dw 0xaa55
removecursor:
    mov al, 0x0A
    mov dx, 0x03D4
    out dx, al
    inc dx
    mov al, 0x20
    out dx, al

    mov al, 0x11
    out PIC1, al
    call verspiltijd
    out PIC2, al
    call verspiltijd

    mov al, 0x20
    out PIC1 + 1, al
    call verspiltijd
    mov al, 0x28
    out PIC2 + 1, al
    call verspiltijd

    mov al, 4
    out PIC1 + 1, al
    call verspiltijd
    mov al, 2
    out PIC2 + 1, al
    call verspiltijd

    mov al, 0x01
    out PIC1 + 1, al
    call verspiltijd
    out PIC2 + 1, al
    call verspiltijd

    mov al, 0xFD
    out PIC1 + 1, al
    call verspiltijd

    lidt [IDTR]
    sti

    call wachtps2
    mov al, 0xA7
    out ps2command, al

    call wachtps2
    mov al, 0xAE
    out ps2command, al

    call wachtps2
    mov al, 0xF6
    out ps2command, al
    call reactieps2

    call wachtps2
    mov al, 0xF4
    out ps2command, al
    call reactieps2

    mov word [0xb8006], 0x0f44

    mov dword [videopointer], 0xb8000
    mov esi, string
    int 0x20
    jmp $

;routines

wachtps2:
    in al, ps2status
    shl al, 6
    shr al, 7
    cmp al, 1
    je wachtps2
    ret

reactieps2:
    mov ah, al
    in al, ps2data
    cmp al, 0xFA
    jne herstuur
    ret
herstuur:
    mov al, ah
    out ps2command, al
    ret

verspiltijd:
    xor cx, cx
verspiltijdloop:
    inc cx
    cmp cx, 0xffff
    jne verspiltijdloop
    ret

;variabelen

string: db "Hallo het werkt!", 0
videopointer: dd 0x0
scancodes: db 0, 0, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', 0, 0, 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', 0, 0, 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', 39, '`', 0, '\', 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', 0, '*', 0, ' '

;interrupts

printstring:           ;print string - esi: string
    pusha
    mov edi, [videopointer]
printloop:
    lodsb
    mov ah, 0x0f
    cmp al, 0
    je return
    stosw
    jmp printloop
return:
    mov [videopointer], edi
    popa
    iret

toetsenboord:
    pusha
    xor ax, ax
    in al, 60h
    cmp al, 0x59
    jnb toetsenboordlos
    mov esi, scancodes
    add esi, eax
    lodsb
    mov ah, 0x0f
    mov edi, [videopointer]
    stosw
    mov [videopointer], edi
toetsenboordlos:
    mov al, 20h
    out PIC1, al
    call verspiltijd
    popa
    iret

noop:
    nop
    iret

IDT_start:
%rep 0x20
    dw noop         ;uitzonderingen fouten int 0 - 1f
    dw 0x08
    dw 0x8E00
    dw 0x00
%endrep

    dw printstring  ;int 0x20 - irq 0
    dw 0x08
    dw 0x8E00
    dw 0x00

    dw toetsenboord ;int 0x21 - irq 1
    dw 0x08
    dw 0x8E00
    dw 0x00
IDT_end:

IDTR:
    dw IDT_end - IDT_start - 1
    dd IDT_start

times 512*63 - ($ - $$) db 0
