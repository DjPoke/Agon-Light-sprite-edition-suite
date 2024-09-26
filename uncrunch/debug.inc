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
