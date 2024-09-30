; inputs.inc
; (B.Vignoli)
;
; MIT Licence
; 2024

; equ's


; data
BITLOOKUP:
	db 01h,02h,04h,08h
	db 10h,20h,40h,80h

; get an ascii key value
inp_input_key:
	push bc
	moscall mos_getkey
	pop bc
	ret

; input: HL = negative key to check
input_inkey:
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
