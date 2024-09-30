; load_screen.inc
; (B.Vignoli)
;
; MIT Licence
; 2024

; data
scn_mode_value:
	DB 0

scn_width_value:
	DW 0

scn_height_value:
	DW 0
	
scn_colors_count:
	DB 0

scn_red_tint:
	DB 0
	
scn_green_tint:
	DB 0	

scn_blue_tint:
	DB 0
	
scn_colors_by_mode:
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

scn_width_by_mode:
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
	
scn_height_by_mode:
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

scn_palette_rgb:
	DS 192

; load a raw screen
; ix -> pointer to the (crunched or raw) image
; iy -> pointer to the buffer (only for crunched files)
scn_load:
	push iy
	push ix
	
	; store the mode
	LD A,(IX+0)
	LD HL,scn_mode_value
	LD (HL),A
		
	PUSH AF
	
	; store the width and the height of the screen
	LD DE,$000000
	LD E,A
	LD D,2
	MLT DE
	PUSH DE
	LD HL,scn_width_by_mode
	ADD HL,DE
	LD DE,scn_width_value
	LD A,(HL)
	LD (DE),A
	INC DE
	INC HL
	LD A,(HL)
	LD (DE),A
	INC HL
	POP DE
	LD HL,scn_height_by_mode
	ADD HL,DE
	LD DE,scn_height_value
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
	LD HL,scn_mode_value
	LD A,(HL)
	VDU_A
	
	; hide cursor
	VDU 23
	VDU 1
	VDU 0
	
	POP IX
	POP AF
		
	; get colors count
	LD HL,scn_colors_by_mode
	LD DE,$000000
	LD E,A
	ADD HL,DE
	LD A,(HL) ; number of colors
	LD HL,scn_colors_count
	LD (HL),A
		
	; read the palette
	LD DE,scn_palette_rgb
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
	LD DE,scn_colors_count
	LD A,(DE)
	CP 0
	JP Z,scn_lrs_error

	PUSH IX
	
	LD B,0
	LD IX,scn_palette_rgb

scn_lrs_set_palette:
	LD C,(IX+0)
	LD E,(IX+1)
	LD L,(IX+2)
	INC IX
	INC IX
	INC IX
	CALL scn_set_color
	INC B
	CP B
	JR NZ,scn_lrs_set_palette
		
	; not crunched file flag
	POP HL ; HL -> crunched data, DE -> screen buffer
	POP DE ;
	
	INC HL
	LD BC,$000000
	LD C,A ; colors count * 3
	LD B,3
	MLT BC
	ADD HL,BC
	LD A,(HL)
	INC HL
	CP 0
	JR Z,scn_lrs_not_crunched

; uncrunch the file
scn_lrs_uncrunch:
	CALL scn_compare24 ; HL = IY ? exit
	JP NC,scn_lrs_not_crunched
	
	; a single byte > 0 ?
	LD A,(HL)
	CP 0
	JR Z,scn_lrs_uncrunch_next1
	
	LD (DE),A
	INC DE
	INC HL
	JP scn_lrs_uncrunch

scn_lrs_uncrunch_next1:
	INC HL
	LD A,(HL)
	CP 0
	JR NZ,scn_lrs_uncrunch_next2
	
	LD (DE),A
	INC DE
	INC HL
	JP scn_lrs_uncrunch	

scn_lrs_uncrunch_next2:
	LD B,A ; count of bytes of the same value
	INC HL
	LD A,(HL)

scn_lrs_uncrunch_loop:
	LD (DE),A
	INC DE
	DJNZ scn_lrs_uncrunch_loop

	INC HL
	JP scn_lrs_uncrunch	

scn_lrs_not_crunched:
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

scn_lrs_upload_block:
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
scn_lrs_loop:
	LD A,(HL) ; indexed color
	CP 64
	JP NC,scn_lrs_wrong_file
	PUSH HL
	LD HL,scn_palette_rgb ; start of palette
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
	JP NZ,scn_lrs_loop
	POP IX
	POP BC

	; next block of 256*4 bytes
	DEC IY
	PUSH IY
	POP DE
	LD A,D
	OR E
	CP 0
	JP NZ,scn_lrs_upload_block
	
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
	LD IX,scn_width_value
	LD IY,scn_height_value
	LD DE,$000000
	LD E,(IX+0)
	LD D,(IX+1)
	VDU_DE
	LD IY,scn_height_value
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

scn_redraw:
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

scn_lrs_wrong_file:
	POP IX
	POP BC
	VDU 7
	RET

scn_lrs_error:
	VDU 7
	RET

; set color RGB (b = c,e,l)
scn_set_color:
	PUSH IX
	PUSH AF
	PUSH BC
	PUSH DE
	PUSH HL

	PUSH BC
	PUSH HL
	LD HL,scn_red_tint
	LD (HL),C
	LD HL,scn_green_tint
	LD (HL),E
	POP DE
	LD HL,scn_blue_tint
	LD (HL),E
	
	VDU 19
	POP BC
	LD A,B
	VDU_A
	VDU 255
	
	LD HL,scn_red_tint
	LD A,(HL)
	VDU_A

	LD HL,scn_green_tint
	LD A,(HL)
	VDU_A

	LD HL,scn_blue_tint
	LD A,(HL)
	VDU_A	

	POP HL
	POP DE
	POP BC
	POP AF
	POP IX
	ret

scn_compare:
	LD A,H
	CP D
	RET NZ

	LD A,L
	CP E
	RET

scn_compare24:
	PUSH HL
	PUSH DE
	PUSH IY
	POP DE
	OR A
	SBC HL,DE
	ADD HL,DE
	POP DE
	POP HL
	RET
