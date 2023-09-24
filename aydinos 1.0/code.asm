[bits 16]
[org 0x7c00]

	mov [bootdrive], dl

	xor ax, ax
	mov es, ax
	mov ds, ax
	mov bp, 0xFE00
	mov sp, bp
	cli
	call cls
	mov si, welkom
	call printstring
	call lijnomlaag
	mov al, 63
	mov bx, 0x7e00
	call leesschijf

main:
	mov ah, 0Eh
	mov al, ">"
	int 10h
	call krijginput
	call lijnomlaag
	call zoekcommando
	jmp main

;routines

printstring:
	mov ah, 0Eh
	lodsb
	int 10h
	cmp al, 0
	je return
	jmp printstring

lijnomlaag:
	mov ah, 03h
	mov bh, 00
	int 10h
	mov ah, 02h
	inc dh
	xor dl, dl
	int 10h
	ret

krijginput:
	mov di, buffer
	xor cx, cx
inputloop:
	xor ax, ax
	int 16h
	cmp ax, 1C0Dh
	je return
	cmp ax, 0E08h
	je inputverlaagd
	stosb
	inc cx
	cmp cx, 8
	mov ah, 0Eh
	int 10h
	je return
	jmp inputloop
inputverlaagd:
	mov ah, 0Eh
	mov al, 08h
	int 10h
	dec di
	dec cx
	jmp inputloop

zoekcommando:
	mov cx, 5
	mov si, buffer
	mov di, lijstnaam
	repe cmpsb
	je lijst

	mov cx, 3
	mov si, buffer
	mov di, clsnaam
	repe cmpsb
	je cls

	mov cx, 6
	mov si, buffer
	mov di, editornaam
	repe cmpsb
	je editor
	jmp nietgevonden

lijst:
	mov si, lijstinhoud
	call printstring
	call lijnomlaag
	ret

cls:
	mov ax, 0002h
	int 10h
	ret

nietgevonden:
	mov si, niet
	call printstring
	call lijnomlaag
	jmp main

leesschijf:
	mov ah, 02h
	mov ch, 0
	mov cl, 2
	mov dh, 0
	mov dl, [bootdrive]
	mov es, [leeg]
	int 13h
	ret

return:
	ret

;variabelen

bootdrive: db 0
welkom: db "Dit is AydinOS 1.0", 0
buffer: times 8 db 0
lijstnaam: db "lijst"
lijstinhoud: db "Je kan: lijst, cls, editor.", 0
niet: db "Deze bestaat niet. Typ lijst voor commando's.", 0
clsnaam: db "cls"
editornaam: db "editor"
editorinhoud: db "Dit is een tekstverwerker. Voer de cijfer na de naam van het bestand in dat je wilt openen. Druk op esc om te sluiten, F1 om op te slaan.", 0
leeg: db 0

times 510 - ($ - $$) db 0
dw 0xaa55

editor:
	call cls
	mov si, editorinhoud
	call printstring
	mov si, 0x8400
	call printstring
	call lijnomlaag
	xor ax, ax
	int 16h
	mov al, 6
	mov bx, 0x8200
	call leesschijf
	call cls
	mov si, 0x8200
	call printstring
editorloop:
	xor ax, ax
	int 16h
	cmp ax, 1C0Dh
	je editorenter
	cmp ax, 011Bh
	je editoresc
	mov ah, 0Eh
	int 10h
	jmp editorloop
editorenter:
	call lijnomlaag
	jmp editorloop
editoresc:
	ret	

times 1024 - ($ - $$) db 0

;3e sector leeg

times 1536 - ($ - $$) db 0

;4e sector buffer voor opslag

times 2048 - ($ - $$) db 0

;5e sector bestandstabel
db "welkom6"

times 2560 - ($ - $$) db 0

db "Welkom in AydinOS 1.0. Dit bestand heet welkom en is opgeslagen in de 6e sector van de harde schijf. Dit is ook hoe je een bestand moet noemen. De naam + eerstvolgende vrije sector", 0

times 3072 - ($ - $$) db 0

times 32768 - ($ - $$) db 0
