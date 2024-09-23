; zap.asm
;
; cruncher
; for Agon Console 8
;
; by B.Vignoli
; MIT 2024
;

.assume adl=1
.org $040000

	jp start

; MOS header
.align 64
.db "MOS",0,1

	include "mos_api.inc"

MAX_MODES			equ 24

MODES_TABLE:
	db 16,4,2,64,16,4,2,16,64,16,4,2,64,16,4,2,4,2,2,4,64,16,4,2

MODE:
	db 1

PALETTE:
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

;======================================================================
start:
	push af
	push bc
	push de
	push ix
	push iy

; get the '.img' filename (raw file with mode and palette)

	; set the readen mode
	vdu 22
	vdu 1
	
;=================
; exit the program
;=================
exit_program:
	; reset to mode 1
	vdu 22
	vdu 1
	
	; position the texte cursor at home
	vdu 30

	; show cursor
	vdu 23
	vdu 1
	vdu 1

	pop iy
	pop ix
	pop de
	pop bc
	pop af

	ld hl,0
	
	ret
;======================================================================
