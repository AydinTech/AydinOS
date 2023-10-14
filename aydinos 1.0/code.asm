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

	mov cx, 6
	mov si, buffer
	mov di, schoonnaam
	repe cmpsb
	je schoon
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
	mov al, 63
	mov ch, 0
	mov cl, 2
	mov dh, 0
	mov dl, [bootdrive]
	mov es, [leeg]
	mov bx, 0x7e00
	int 13h
	ret

schrijfnaarschijf:
	mov ah, 03h
	mov al, 1
	mov ch, 0
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
lijstinhoud: db "Je kan: lijst, cls, editor, schoon.", 0
niet: db "Deze bestaat niet. Typ lijst voor commando's.", 0
clsnaam: db "cls"
editornaam: db "editor"
editorinhoud: db "Tekstverwerker: Voer de cijfer na de naam in dat je wilt openen.Druk op F1 om op te slaan of esc om te sluiten.", 0
editorbestandadres: dw 0
tekstoffseteindtekst: dw 0
tekstoffsetbeginsector: dw 0
leeg: db 0

times 510 - ($ - $$) db 0
dw 0xaa55

editor:
	call leesschijf
	call cls
	mov si, editorinhoud
	call printstring
	call lijnomlaag
	mov si, 0x8400
	call printstring
	call lijnomlaag
	call tweenummeriginvoer
	push ax
	call leesschijf
	call cls
	pop bx
	mov ax, 0x200
	mul bx
	add ax, 0x7a00
	mov [editorbestandadres], ax
	mov [tekstoffsetbeginsector], ax
	mov si, [editorbestandadres]
	call printstring
	dec si
	mov [tekstoffseteindtekst], si
	mov di, si
editorlus:
	xor ax, ax
	int 16h
	cmp ax, 1C0Dh
	je editorenter
	cmp ax, 011Bh
	je editoresc
	cmp ax, 0E08h
	je editorbackspace
	cmp ax, 3B00h
	je editoropslaan
	mov ah, 0Eh
	int 10h
	stosb
	jmp editorlus
editorenter:
	call lijnomlaag
	jmp editorlus
editoresc:
	ret
editorbackspace:
	dec di
	mov ah, 0Eh
	mov al, 08h
	int 10h
	jmp editorlus
editoropslaan:
	mov si, 0x8400
	call printstring
	dec si
	mov [editorbestandadres], si
	call cls
	mov si, opslainstructie1
	call printstring
	call tweenummeriginvoer
	mov cl, al
	mov bx, [tekstoffsetbeginsector]
	call schrijfnaarschijf
	call leesschijf
	call lijnomlaag
	mov si, opslainstructie2
	call printstring
	mov di, [editorbestandadres]
opslalus:
	xor ax, ax
	int 16h
	cmp ax, 1C0Dh
	je naamopslaan
	cmp ax, 0E08h
	je opslabackspace
	mov ah, 0Eh
	int 10h
	stosb
	jmp opslalus
naamopslaan:
	mov cl, 5
	mov bx, 0x8400
	call schrijfnaarschijf
	ret
opslabackspace:
	dec di
	mov ah, 0Eh
	mov al, 08h
	int 10h
	jmp opslalus

schoon:
	call leesschijf
	call cls
	mov si, schooninstructie1
	call printstring
	call lijnomlaag
	call lijnomlaag
	mov si, 0x8400
	call printstring
	xor cx, cx
	call tweenummeriginvoer
	mov cl, al
	mov ax, 0301h
	xor dh, dh
	mov dl, [bootdrive]
	mov es, [leeg]
	mov bx, 0x8000
	int 13h
	ret

tweenummeriginvoer:
	xor ax, ax
	int 16h
	push ax
	mov ah, 0Eh
	int 10h
	xor ax, ax
	pop ax
	sub al, 30h
	mov bx, ax
	mov ax, 10
	mul bx
	push ax
	xor ax, ax
	int 16h
	push ax
	mov ah, 0Eh
	int 10h
	xor ax, ax
	pop ax
	sub al, 30h
	pop bx
	add ax, bx
	ret

opslainstructie1: db "Geef de sectornummer bijv. 06", 0
opslainstructie2: db "Geef de naam en sectornummer bijv. welkom06 en druk op enter", 0
schoonnaam: db "schoon"
schooninstructie1: db "Schoonmaker: Voer de cijfer na de naam van het bestand in dat je wilt verwijderen.", 0

times 1024 - ($ - $$) db 0

;3e sector leeg

times 1536 - ($ - $$) db 0

;4e sector buffer voor opslag

times 2048 - ($ - $$) db 0

;5e sector bestandstabel
db "welkom06"

times 2560 - ($ - $$) db 0

db "Welkom in AydinOS 1.0. Dit bestand heet welkom en is opgeslagen in de 6e sector van de harde schijf. Dit is ook hoe je een bestand moet noemen. De naam + eerstvolgende vrije sector", 0

times 3072 - ($ - $$) db 0

times 32768 - ($ - $$) db 0
