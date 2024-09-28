; load_screen.inc
; (B.Vignoli)
;
; MIT Licence
; 2024

; data
crunched_screen_filename:
	db "temp",0

mode_value:
	DB 0

width_value:
	DW 0

height_value:
	DW 0
	
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

width_by_mode:
	DW 640
	DW 640
	DW 640
	DW 640
	DW 640
	DW 640
	DW 640
	DW 0
	DW 320
	DW 320
	DW 320
	DW 320
	DW 320
	DW 320
	DW 320
	DW 320
	DW 800
	DW 800
	DW 1024
	DW 1024
	DW 512
	DW 512
	DW 512
	DW 512
	
height_by_mode:
	DW 480
	DW 480
	DW 480
	DW 240
	DW 240
	DW 240
	DW 240
	DW 0
	DW 240
	DW 240
	DW 240
	DW 240
	DW 200
	DW 200
	DW 200
	DW 200
	DW 600
	DW 600
	DW 768
	DW 768
	DW 384
	DW 384
	DW 384
	DW 384

palette_rgb:
	DS 192

; load a raw screen
; ix -> pointer to the image
load_raw_screen:
	push ix
	
	; store the mode
	LD A,(IX+0)
	LD HL,mode_value
	LD (HL),A
		
	PUSH AF
	
	; store the width and the height of the screen
	LD DE,$000000
	LD E,A
	LD D,2
	MLT DE
	PUSH DE
	LD HL,width_by_mode
	ADD HL,DE
	LD DE,width_value
	LD A,(HL)
	LD (DE),A
	INC DE
	INC HL
	LD A,(HL)
	LD (DE),A
	INC HL
	POP DE
	LD HL,height_by_mode
	ADD HL,DE
	LD DE,height_value
	LD A,(HL)
	LD (DE),A
	INC DE
	INC HL
	LD A,(HL)
	LD (DE),A
	INC HL
	
	PUSH IX
	
	; set the readen mode
	VDU 22
	LD HL,mode_value
	LD A,(HL)
	VDU_A
	
	; hide cursor
	VDU 23
	VDU 1
	VDU 0
	
	POP IX
	POP AF
		
	; get colors count
	LD HL,colors_by_mode
	LD DE,$000000
	LD E,A
	ADD HL,DE
	LD A,(HL) ; number of colors
	LD HL,colors_count
	LD (HL),A
		
	; read the palette
	LD DE,palette_rgb
	LD BC,$000000
	LD C,A ; colors count * 3
	LD B,3
	MLT BC
	INC IX
	PUSH IX
	POP HL
	LDIR
	
	POP IX
	
	; set the palette
	LD DE,colors_count
	LD A,(DE)
	CP 0
	JP Z,lrs_error

	PUSH IX
	
	LD B,0
	LD IX,palette_rgb

lrs_set_palette:
	LD C,(IX+0)
	LD E,(IX+1)
	LD L,(IX+2)
	INC IX
	INC IX
	INC IX
	CALL set_color
	INC B
	CP B
	JR NZ,lrs_set_palette
		
	; not crunched file flag
	POP HL
	INC HL
	LD BC,$000000
	LD C,A ; colors count * 3
	LD B,3
	MLT BC
	ADD HL,BC
	LD A,(HL)
	CP 0
	JP NZ,lrs_error
		
	INC HL
	PUSH HL
	
	; clear buffer 64255
	VDU 23
	VDU 0
	VDU $A0
	VDU $FF ; buffer number (16 bits)
	VDU $FA
	VDU 2 ; command

	; coordinates to draw a piece of screen
	POP HL ; start address
	LD IY,300 ; 300 blocks of 256 bytes * 4 for the 1st RAM part

lrs_upload_block:
	PUSH HL
	
	; upload data to the buffer
	VDU 23
	VDU 0
	VDU $A0
	VDU $FF ; buffer number (16 bits)
	VDU $FA
	VDU 0 ; command
	LD DE,256*4 ; 256 bytes * 4
	VDU_DE
	
	POP HL
		
	PUSH BC
	PUSH IX
	LD BC,256 ; 256 loops
lrs_loop:
	LD A,(HL) ; indexed color
	CP 64
	JP NC,lrs_wrong_file
	PUSH HL
	LD HL,palette_rgb ; start of palette
	LD DE,$000000
	LD E,A
	LD D,3
	MLT DE ; color * 3 tints
	ADD HL,DE ; hl -> RGB values for this color
	LD A,(HL) ; get red
	INC HL
	PUSH HL
	VDU_A
	POP HL
	LD A,(HL) ; get green
	INC HL
	PUSH HL
	VDU_A
	POP HL
	LD A,(HL) ; get blue
	INC HL
	PUSH HL
	VDU_A
	POP HL
	LD A,255 ; get alpha
	VDU_A
	POP HL
	INC HL
	DEC BC
	LD A,B
	OR C
	JP NZ,lrs_loop
	POP IX
	POP BC

	; next block of 256*4 bytes
	DEC IY
	PUSH IY
	POP DE
	LD A,D
	OR E
	CP 0
	JP NZ,lrs_upload_block
	
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
	LD IX,width_value
	LD IY,height_value
	LD DE,$000000
	LD E,(IX+0)
	LD D,(IX+1)
	VDU_DE
	LD IY,height_value
	LD HL,$000000
	LD L,(IY+0)
	LD H,(IY+1)
	VDU_HL
	VDU 0 ; rgba8888

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

lrs_wrong_file:
	POP IX
	POP BC
	VDU 7
	RET

lrs_error:
	VDU 7
	RET

; load a crunched screen
; ix -> pointer to the image
load_crunched_screen:
	PUSH IY
	PUSH IX
	
	; store the mode
	LD A,(IX+0)
	LD HL,mode_value
	LD (HL),A
		
	PUSH AF
	
	; store the width and the height of the screen
	LD DE,$000000
	LD E,A
	LD D,2
	MLT DE
	PUSH DE
	LD HL,width_by_mode
	ADD HL,DE
	LD DE,width_value
	LD A,(HL)
	LD (DE),A
	INC DE
	INC HL
	LD A,(HL)
	LD (DE),A
	INC HL
	POP DE
	LD HL,height_by_mode
	ADD HL,DE
	LD DE,height_value
	LD A,(HL)
	LD (DE),A
	INC DE
	INC HL
	LD A,(HL)
	LD (DE),A
	INC HL
	
	PUSH IX
	
	; set the readen mode
	VDU 22
	LD HL,mode_value
	LD A,(HL)
	VDU_A
	
	; hide cursor
	VDU 23
	VDU 1
	VDU 0
	
	POP IX
	POP AF
		
	; get colors count
	LD HL,colors_by_mode
	LD DE,$000000
	LD E,A
	ADD HL,DE
	LD A,(HL) ; number of colors
	LD HL,colors_count
	LD (HL),A
		
	; read the palette
	LD DE,palette_rgb
	LD BC,$000000
	LD C,A ; colors count * 3
	LD B,3
	MLT BC
	INC IX
	PUSH IX
	POP HL
	LDIR
	
	POP IX
	
	; set the palette
	LD DE,colors_count
	LD A,(DE)
	CP 0
	JP Z,lcs_error

	PUSH IX
	
	LD B,0
	LD IX,palette_rgb

lcs_set_palette:
	LD C,(IX+0)
	LD E,(IX+1)
	LD L,(IX+2)
	INC IX
	INC IX
	INC IX
	CALL set_color
	INC B
	CP B
	JR NZ,lcs_set_palette
		
	; crunched file flag
	POP HL
	INC HL
	LD BC,$000000
	LD C,A ; colors count * 3
	LD B,3
	MLT BC
	ADD HL,BC
	LD A,(HL)
	CP 1
	JP NZ,lcs_error
	
	INC HL
	PUSH HL
	
	; clear buffer 64255
	VDU 23
	VDU 0
	VDU $A0
	VDU $FF ; buffer number (16 bits)
	VDU $FA
	VDU 2 ; command

	; coordinates to draw a piece of screen
	POP HL ; start address
	POP IY
	DEC IY ; end address-1

lcs_upload_little_blocks:
	PUSH HL
	
	LD A,(HL)
	CP 64
	JP NC,lcs_wrong_file ; exit if more than 64 colors
	CP 1 ; > 0 ?
	JP NC,lcs_upload_little_blocks2
	
	; upload data to the buffer
	VDU 23
	VDU 0
	VDU $A0
	VDU $FF ; buffer number (16 bits)
	VDU $FA
	VDU 0 ; command
	LD DE,4 ; 1 byte * 4
	VDU_DE
	
	POP HL

	PUSH HL
	LD HL,palette_rgb ; start of palette
	LD DE,$000000
	LD E,A
	LD D,3
	MLT DE ; color * 3 tints
	ADD HL,DE ; hl -> RGB values for this color
	LD A,(HL) ; get red
	INC HL
	PUSH HL
	VDU_A
	POP HL
	LD A,(HL) ; get green
	INC HL
	PUSH HL
	VDU_A
	POP HL
	LD A,(HL) ; get blue
	INC HL
	PUSH HL
	VDU_A
	POP HL
	LD A,255 ; get alpha
	VDU_A
	POP HL
	INC HL
	PUSH IY
	POP DE
	CALL compare24
	JP C,lcs_upload_little_blocks
	JP lcs_consolidate

lcs_upload_little_blocks2:
	PUSH HL
	
	INC HL
	LD A,(HL)
	CP 0 ; = 0 ?
	JP NZ,lcs_upload_little_blocks3
	
	; upload data to the buffer
	VDU 23
	VDU 0
	VDU $A0
	VDU $FF ; buffer number (16 bits)
	VDU $FA
	VDU 0 ; command
	LD DE,4 ; 1 byte * 4
	VDU_DE
	
	POP HL

	PUSH HL
	LD HL,palette_rgb ; start of palette
	LD DE,$000000
	LD E,A
	LD D,3
	MLT DE ; color * 3 tints
	ADD HL,DE ; hl -> RGB values for this color
	LD A,(HL) ; get red
	INC HL
	PUSH HL
	VDU_A
	POP HL
	LD A,(HL) ; get green
	INC HL
	PUSH HL
	VDU_A
	POP HL
	LD A,(HL) ; get blue
	INC HL
	PUSH HL
	VDU_A
	POP HL
	LD A,255 ; get alpha
	VDU_A
	POP HL
	INC HL
	PUSH IY
	POP DE
	CALL compare24
	JP C,lcs_upload_little_blocks
	JP lcs_consolidate

lcs_upload_little_blocks3:
	PUSH HL

	LD B,(HL)
	INC HL
	
	PUSH BC
	
	; upload data to the buffer
	VDU 23
	VDU 0
	VDU $A0
	VDU $FF ; buffer number (16 bits)
	VDU $FA
	VDU 0 ; command
	LD DE,$000000
	LD E,4 ; B bytes * 4
	LD D,B
	MLT DE
	VDU_DE
	
	POP BC

	POP HL

lcs_loop:
	PUSH HL
	LD A,(HL)
	LD HL,palette_rgb ; start of palette
	LD DE,$000000
	LD E,A
	LD D,3
	MLT DE ; color * 3 tints
	ADD HL,DE ; hl -> RGB values for this color
	LD A,(HL) ; get red
	INC HL
	PUSH HL
	VDU_A
	POP HL
	LD A,(HL) ; get green
	INC HL
	PUSH HL
	VDU_A
	POP HL
	LD A,(HL) ; get blue
	INC HL
	PUSH HL
	VDU_A
	POP HL
	LD A,255 ; get alpha
	VDU_A	
	POP HL
	DJNZ lcs_loop
	INC HL
	PUSH IY
	POP DE
	CALL compare24
	JP C,lcs_upload_little_blocks

lcs_consolidate:
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
	LD IX,width_value
	LD IY,height_value
	LD DE,$000000
	LD E,(IX+0)
	LD D,(IX+1)
	VDU_DE
	LD IY,height_value
	LD HL,$000000
	LD L,(IY+0)
	LD H,(IY+1)
	VDU_HL
	VDU 0 ; rgba8888

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

lcs_wrong_file:
	POP IX
	POP BC
	VDU 7
	RET

lcs_error:
	VDU 7
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

; set color RGB (b = c,e,l)
set_color:
	PUSH IX
	PUSH AF
	PUSH BC
	PUSH DE
	PUSH HL

	PUSH BC
	PUSH HL
	LD HL,red_tint
	LD (HL),C
	LD HL,green_tint
	LD (HL),E
	POP DE
	LD HL,blue_tint
	LD (HL),E
	
	VDU 19
	POP BC
	LD A,B
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

	POP HL
	POP DE
	POP BC
	POP AF
	POP IX
	ret

; DE -> x
; HL -> y
; A -> color
plot_pixel:
	PUSH AF
	PUSH BC
	PUSH DE
	PUSH HL

	PUSH AF
	VDU 18
	VDU 0
	POP AF
	VDU_A

	VDU 25
	VDU 4

	POP HL
	POP DE
	PUSH DE
	PUSH HL
	
	VDU_DE

	POP HL
	POP DE
	PUSH DE
	PUSH HL
	
	VDU_HL

	VDU 25
	VDU 5

	POP HL
	POP DE
	PUSH DE
	PUSH HL
	
	VDU_DE

	POP HL
	POP DE
	PUSH DE
	PUSH HL
	
	VDU_HL

	POP HL
	POP DE
	POP BC
	POP AF

	INC DE

	PUSH HL
	LD IX,width_value
	LD L,(IX+0)
	LD H,(IX+1)
	CALL compare
	POP HL
	RET NZ

	LD DE,$000000
	INC HL
	RET

; DE -> x
; HL -> y
; B -> count of pixels to draw
; A -> color
draw_line:
	PUSH AF
	PUSH BC
	PUSH DE
	PUSH HL

	POP HL
	POP DE
	POP BC
	POP AF
	RET

compare:
	LD A,H
	CP D
	RET NZ

	LD A,L
	CP E
	RET

compare24:
	PUSH HL
	OR A
	SBC HL,DE
	ADD HL,DE
	POP HL
	RET
