; uncrunch.asm
; (B.Vignoli)
;
; MIT Licence
;

.ASSUME ADL=1
.ORG $040000

	JP start

; MOS header
.ALIGN 64
.DB "MOS",0,1

.FILLBYTE 0

	INCLUDE "mos_api.inc"

; equ
KEY_ESCAPE: EQU -113

BITLOOKUP:
	DB 01h,02h,04h,08h
	DB 10h,20h,40h,80h

; data
screen_filename:
	DB "screens/not_crunched.scn",0
	
loading_text:
	DB "LOADING...",0

colors_count:
	DB 0

red_tint:
	DB 0
	
green_tint:
	DB 0	

blue_tint:
	DB 0
	
colors_by_mode:
	DB 16
	DB 4
	DB 2
	DB 64
	DB 16
	DB 4
	DB 2
	DB 16
	DB 64
	DB 16
	DB 4
	DB 2
	DB 64
	DB 16
	DB 4
	DB 2
	DB 4
	DB 2
	DB 2
	DB 4
	DB 64
	DB 16
	DB 4
	DB 2

; start main program ============================
start:
	PUSH AF
	PUSH BC
	PUSH DE
	PUSH IX
	PUSH IY

	; reset sprites and bitmaps data
	VDU 23
	VDU 27
	VDU 16

	; set to mode 8
	VDU 22
	VDU 8
	
	; set black paper color
	VDU 17
	VDU 128
	
	; clear screen
	VDU 12

	; hide cursor
	VDU 23
	VDU 1
	VDU 0

	; disable logical screen
	VDU 23
	VDU 0
	VDU $C0
	VDU 0

	; set pen 15
	VDU 17
	VDU 15

	; locate x,y
	VDU 31
	LD A,0
	VDU_A
	LD A,1
	VDU_A

	; print text
	LD HL,loading_text
	LD BC,0
	XOR A
	RST.LIS $18

	; load raw screen
	CALL load_raw_screen

exit_program:
	; wait for any key to be released
	LD HL,KEY_ESCAPE
	CALL inkey
	CP 1
	JR NZ,exit_program

	; reset to mode 1
	VDU 22
	VDU 1
	
	; enable logical screen
	VDU 23
	VDU 0
	VDU $C0
	VDU 1
	
	; position the texte cursor at home
	VDU 30

	; show cursor
	VDU 23
	VDU 1
	VDU 1

	POP IY
	POP IX
	POP DE
	POP BC
	POP AF
	LD HL,0

	RET
	
; ===============================================

; load a raw screen
load_raw_screen:
	; open the file for read
	LD HL,screen_filename
	LD C,fa_open_existing|fa_read
	MOSCALL mos_fopen
	
	; exit on error
	CP 0
	RET Z
	
	; filehandle -> C
	LD C,A

	; read the mode
	MOSCALL mos_fgetc
	JP C,lrs_error

	; set the readen mode
	PUSH AF
	VDU 22
	POP AF
	PUSH AF
	VDU_A
	POP AF
	
	; get colors count
	LD HL,colors_by_mode
	LD DE,#000000
	LD E,A
	ADD HL,DE
	LD A,(HL) ; number of colors
	LD HL,colors_count
	LD (HL),A
		
	; read the palette
	LD HL,$050000
	LD DE,#000000
	LD E,A
	LD D,3
	MLT DE
	PUSH BC
	PUSH DE
	MOSCALL mos_fread
	POP HL
	POP BC
	OR A
	SBC HL,DE
	ADD HL,DE
	JP NZ,lrs_error
	
	; set the palette
	LD HL,colors_count
	LD A,(HL)
	CP 0
	JP Z,lrs_error
	
lrs_set_palette:
	LD C,(HL)
	INC HL
	LD E,(HL)
	INC HL
	LD L,(HL)
	INC HL
	CALL set_color
	DEC A
	CP 0
	JR NZ,lrs_set_palette

	; read crunched flag
	MOSCALL mos_fgetc
	JP C,lrs_error
	
	CP 0
	JP NZ,lrs_error
	
	; read data on the sdcard
	LD HL,$050000
	LD DE,64000
	MOSCALL mos_fread
	LD HL,64000
	OR A
	SBC HL,DE
	ADD HL,DE ; DE = 60000 ?
	JP NZ,lrs_error
	
	; read data on the sdcard
	LD HL,$05FA00
	LD DE,1536
	MOSCALL mos_fread
	LD HL,1536
	OR A
	SBC HL,DE
	ADD HL,DE ; DE = 1536 ?
	JP NZ,lrs_error

	; read data on the sdcard
	LD HL,$060000
	LD DE,11264
	MOSCALL mos_fread
	LD HL,11264
	OR A
	SBC HL,DE
	ADD HL,DE ; DE = 11264 ?
	JP NZ,lrs_error

	; close the file
	MOSCALL mos_fclose

	; clear buffer 64255
	VDU 23
	VDU 0
	VDU $A0
	VDU $FF ; buffer number (16 bits)
	VDU $FA
	VDU 2 ; command

	; coordinates to draw a piece of screen
	LD HL,$050000 ; start address
	LD IY,256 ; 256 blocks of 256 bytes for the 1st RAM part

lrs_upload_block:
	; upload data to the buffer
	VDU 23
	VDU 0
	VDU $A0
	VDU $FF ; buffer number (16 bits)
	VDU $FA
	VDU 0 ; command
	LD DE,256 ; 256 bytes
	VDU_DE
		
	PUSH BC
	PUSH IX
	LD BC,256
lrs_loop:
	LD A,(HL) ; rgba2222 color
	VDU_A
	INC HL
	DEC BC
	LD A,B
	OR C
	JP NZ,lrs_loop
	POP IX
	POP BC

	; next block of 256 bytes
	DEC IY
	PUSH IY
	POP DE
	LD A,D
	OR E
	CP 0
	JP NZ,lrs_upload_block
	
	; second part
	; coordinates to draw a piece of screen
	LD HL,$060000 ; start address
	LD IY,44 ; 44 blocks of 256 bytes for the 2nd RAM part

lrs_upload_block2:
	; upload data to the buffer
	VDU 23
	VDU 0
	VDU $A0
	VDU $FF ; buffer number (16 bits)
	VDU $FA
	VDU 0 ; command
	LD DE,256 ; 256 bytes
	VDU_DE
		
	PUSH BC
	PUSH IX
	LD BC,256
lrs_loop2:
	LD A,(HL) ; rgba2222 color
	VDU_A
	INC HL
	DEC BC
	LD A,B
	OR C
	JP NZ,lrs_loop2
	POP IX
	POP BC

	; next block of 256 bytes
	DEC IY
	PUSH IY
	POP DE
	LD A,D
	OR E
	CP 0
	JP NZ,lrs_upload_block2

	; consolidate buffer 0
	VDU 23
	VDU 0
	VDU $A0
	VDU $FF ; buffer number (16 bits)
	VDU $FA
	VDU 14 ; command

	; set buffer 64255 as bitmap (bitmap 255)
	VDU 23
	VDU 27
	VDU $20
	VDU $FF ; bitmap number (16 bits)
	VDU $FA

	; set buffer 64255 attributes
	VDU 23
	VDU 27
	VDU $21
	LD DE,320 ; width
	LD HL,240 ; height
	VDU_DE
	VDU_HL
	VDU 1 ; rgba2222

	; select bitmap 255
	VDU 23
	VDU 27
	VDU 0
	VDU 255

	; draw bitmap 255 at coordinates 0,0
	VDU 23
	VDU 27
	VDU 3
	VDU 0
	VDU 0
	VDU 0
	VDU 0
	RET

lrs_error:
	VDU 7
	MOSCALL mos_fclose
	RET

lrs_exit:
	RET
	
; input: HL = negative key to check
inkey:
	MOSCALL	mos_getkbmap
	INC	HL
	LD	A, L
	NEG
	LD	C, A
	LD	A, 1
	JP	M,inkey_false ; < -128 ?

	LD	HL,BITLOOKUP
	LD	DE,0
	LD	A,C
	AND	00000111b
	LD	E,A
	ADD	HL,DE
	LD	B,(HL)

	LD	A,C
	AND	01111000b
	RRCA
	RRCA
	RRCA
	LD	E, A
	ADD	IX,DE
	LD	A,(IX+0)
	AND	B
	JR Z,inkey_false
	LD A,1
	RET
inkey_false:
	XOR A
	RET

; set color RGB (a = c,e,l)
set_color:
	PUSH AF
	PUSH BC
	PUSH DE
	PUSH HL

	PUSH HL
	LD HL,red_tint
	LD (HL),C
	LD HL,green_tint
	LD (HL),E
	POP DE
	LD HL,blue_tint
	LD (HL),E
	
	PUSH AF
	VDU 19
	POP AF
	VDU_A
	VDU 255
	
	LD HL,red_tint
	LD A,(HL)
	VDU_A

	LD HL,green_tint
	LD A,(HL)
	VDU_A

	LD HL,blue_tint
	LD A,(HL)
	VDU_A

	pop hl
	pop de
	pop bc
	pop af
	ret

;=================
; Debug functions
;=================
; A = byte to debug
debug_byte:
	PUSH AF
	PUSH BC
	PUSH DE
	PUSH HL
	LD HL,$000000
	LD L,A
	LD DE,debug_text
	PUSH DE
	CALL num2dec
	POP HL
	INC HL
	INC HL
	LD BC,3
	LD A,0
	RST.LIS $18
	POP HL
	POP DE
	POP BC
	POP AF
	RET

; HL = word to debug
debug_word:
	PUSH AF
	PUSH BC
	PUSH DE
	PUSH HL
	LD DE,$000000 ; remove HLU
	LD E,L
	LD D,H
	PUSH DE
	POP HL
	LD DE,debug_text
	PUSH DE
	CALL num2dec
	POP HL
	LD BC,5
	LD A,0
	RST.LIS $18
	POP HL
	POP DE
	POP BC
	POP AF
	RET

debug_text:
	DS 6

; 16 bits number to string
num2dec:
	LD BC,-10000
	CALL num1
	LD BC,-1000
	CALL num1
	LD BC,-100
	CALL num1
	LD BC,-10
	CALL num1
	LD C,B

num1: LD A,'0'-1
num2: INC A
	ADD HL,BC
	JR C,num2
	SBC HL,BC

	LD (DE),A
	INC DE
	RET