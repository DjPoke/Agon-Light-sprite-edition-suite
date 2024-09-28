; load_raw.asm
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
	INCLUDE "load_screen.inc"
	INCLUDE "debug.inc"

; equ
KEY_ESCAPE: EQU -113

BITLOOKUP:
	DB 01h,02h,04h,08h
	DB 10h,20h,40h,80h

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
	
	; load raw screen
	LD IX,raw_screen
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
; included binary files
raw_screen:
.INCBIN "screens/not_crunched.scn"
