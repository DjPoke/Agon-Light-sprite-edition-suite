; sprdemo.asm
; (B.Vignoli)
;
; MIT Licence
; 2024

.ASSUME ADL=1
.ORG $040000

	JP start

; MOS header
.ALIGN 64
.DB "MOS",0,1

.FILLBYTE 0

	INCLUDE "mos_api.inc"
	INCLUDE "sprites.inc"
	INCLUDE "debug.inc"

; equ


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

	; set mode 136 (double buffered mode 8)
	VDU 22
	VDU 8;+128
	
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
	
	LD HL,palette1
	CALL load_palette

	LD HL,sprite1
	LD A,0 ; sprite number
	CALL init_sprite ; c -> frames count
	
	LD A,1 ; 1 sprite activated
	CALL activate_sprites
	
	LD A,0
	LD DE,0
	PUSH DE
	LD HL,112
	CALL set_sprite_position
	
	LD A,0
	CALL show_sprite

	POP DE

main_loop:
	PUSH DE
	LD A,0
	LD HL,112
	CALL set_sprite_position
	CALL flip
	CALL sleep50
	CALL set_sprite_next_frame
	POP DE
	INC DE
	INC DE
	LD HL,320
	OR A
	SBC HL,DE
	ADD HL,DE
	JP NZ,main_loop

exit_program:
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
palette1:
.incbin "data/BountyBoy.pal"

sprite1:
.incbin "data/BountyBoy.spr"
