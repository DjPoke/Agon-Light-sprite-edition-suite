; load_crunched.asm
; (B.Vignoli)
;
; MIT Licence
; 2024
;

.ASSUME ADL=1
.ORG $040000

	JP start

; MOS header
.ALIGN 64
.DB "MOS",0,1

.FILLBYTE 0

	INCLUDE "mos_api.inc"
	INCLUDE "inputs.inc"
	INCLUDE "load_screen.inc"

; equ
KEY_ESCAPE: EQU -113

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

	; set mode 8
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

	; load crunched screen
	ld ix,crunched_screen
	ld iy,uncrunched_screen
	CALL scn_load

exit_program:
	; wait for any key to be released
	LD HL,KEY_ESCAPE
	CALL inp_inkey
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
; included binary files
crunched_screen:
.INCBIN "screens/crunched.scn"

; buffer for uncrunched screen
uncrunched_screen:
	ds 320*240
