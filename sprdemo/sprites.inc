; sprites.inc
; (B.Vignoli)
;
; MIT Licence
; 2024

;===================================
; equ's
HEADER_BUFFER_SIZE:	equ 16

MAX_PAL_DATA: equ 836 ; max palette chars
MAX_PAL_DATA_HI: equ 03h
MAX_PAL_DATA_LO: equ 44h

;===================================
; data
header:
	db "JASC-PAL",13,10
	db "0100",13,10

color_buffer:
	db 0,0,0

real_palette_buffer:
	ds 192

palette_buffer:
	ds MAX_PAL_DATA + 1

temp_chars_buffer:
	db 0,0,0,0

frames_count:
	db 0

bitmap_size:
	db 0

start_bitmap:
	db 0

current_bitmap:
	db 0

current_sprite:
	db 0

; real number of colors
new_colors_count:
	db 0

colors_count:
	db 0
	
red_tint:
	db 0

green_tint:
	db 0

blue_tint:
	db 0
	
; file error message
file_error:
	db "File error !             ",0

; header error message
header_error:
	db "Header error !           ",0

; data error message
data_error:
	db "Data error !             ",0

;===================================
; load a palette
; the right mode must
; be set before
; hl -> pointer to palette
load_palette:
	; compare loaded header with needed header
	ld de,header
	ld b,HEADER_BUFFER_SIZE

lp_compare:
	ld a,(de)
	cp (hl)
	jp nz,lp_header_error
	
	inc de
	inc hl
	dec b
	
	ld a,b
	cp 0
	jp nz,lp_compare

	push hl
	pop ix
	
	; prepare to read the number of colors
	ld hl,color_buffer
	
lp_getcount:
	; read a string for colors count
	ld a,(ix+0)
	inc ix
	
	cp 48 ; < 0
	jr c,lpgc_next
	cp 58 ; > 9
	jp nc,lp_data_error

	ld (hl),a
	inc hl
	jr lp_getcount

lpgc_next:
	push af
	ld a,13
	ld (hl),a ; store CR
	pop af

	; test CR
	cp 13
	jp nz,lp_close_error

	; read LF
	ld a,(ix+0)
	inc ix

	; test LF
	cp 10
	jp nz,lp_close_error

	; prepare to read color strings
	ld de,#000000
	ld hl,palette_buffer
	
lp_load_pal_loop:
	; read colors data
	ld a,(ix+0)
	inc ix

	ld (hl),a ; store loaded char in palette buffer
	inc hl
	inc de ; count chars
	ld a,d
	cp MAX_PAL_DATA_HI
	jp c,lp_load_pal_loop
	ld a,e
	cp MAX_PAL_DATA_LO
	jp c,lp_load_pal_loop
	jp lp_read_palette_data

lp_close_error:
	push bc
	
	; read error
	call print_file_error
	
	pop bc
	jp lp_exit

lp_header_error:
	; write error
	call print_header_error
	jp lp_exit
	
lp_read_palette_data:
	; read the number of colors we have in the palette
	ld hl,color_buffer
	ld a,(hl)
	ld b,a
	inc hl
	ld a,(hl)
	ld c,a ; bc = 1st char, 2nd char or CR
	
	; first is a char number ?
	ld a,b
	cp 48
	jp c,lp_data_error
	cp 58
	jp nc,lp_data_error

	ld a,c
	cp 13
	jp nz,lp_two_numbers
	
; only one number
	ld a,b
	sub 48
	
	ld hl,new_colors_count
	ld (hl),a
	
	cp 0
	jp z,lp_data_error
	cp 3
	jp c,lp_two_colors
	cp 5
	jp c,lp_four_colors
	
	jp lp_sixteen_colors

; two numbers
lp_two_numbers:
	ld a,c
	cp 48
	jp c,lp_data_error
	cp 58
	jp nc,lp_data_error
	
	ld a,b
	sub 48
	ld bc,#000000
	ld b,a
	ld c,10
	mlt bc
	add a,c
	
	ld hl,new_colors_count
	ld (hl),a

	cp 10
	jp c,lp_data_error
	cp 17
	jp c,lp_sixteen_colors
	cp 65
	jp c,lp_sixty_four_colors
	
	jp lp_data_error

lp_two_colors:
	ld hl,colors_count
	ld a,2
	ld (hl),a

lptc_done:
	ld hl,new_colors_count
	ld a,(hl) ; real number of coulours
	ld b,0 ; start wit color 0
	ld hl,palette_buffer ; palette will be got here
	jp lp_read_colors

lp_four_colors:
	ld hl,colors_count
	ld a,4
	ld (hl),a
	
lpfc_done:
	ld hl,new_colors_count
	ld a,(hl) ; real number of coulours
	ld b,0 ; start wit color 0
	ld hl,palette_buffer ; palette will be got here
	jp lp_read_colors

lp_sixteen_colors:
	ld hl,colors_count
	ld a,16
	ld (hl),a

lpsc_done:
	ld hl,new_colors_count
	ld a,(hl) ; real number of coulours
	ld b,0 ; start wit color 0
	ld hl,palette_buffer ; palette will be got here	
	jp lp_read_colors

lp_sixty_four_colors:
	ld hl,colors_count
	ld a,64
	ld (hl),a

lpsfc_done:
	ld hl,new_colors_count
	ld a,(hl) ; real number of coulours
	ld b,0 ; start wit color 0
	ld hl,palette_buffer ; palette will be taken here
	jp lp_read_colors

lp_read_colors:
	push af
	
	call lp_read_tint ; read red tint

	push hl
	ld hl,red_tint
	ld (hl),a	
	pop hl

	call lp_read_tint ; read green tint

	push hl
	ld hl,green_tint
	ld (hl),a
	pop hl

	call lp_read_tint ; read blue tint

	push hl
	ld hl,blue_tint
	ld (hl),a
	pop hl
	
	call lp_set_tint
	
	pop af
	
	inc b ; increment number of colors
	dec a ; decrement real number of colors
	cp 0
	jp nz,lp_read_colors
	
lp_exit:
	ret

lp_data_error:
	jp print_data_error

lp_file_error:
	jp print_file_error

lp_read_tint:
	ld c,0 ; number of chars readen for a single string number
	ld de,temp_chars_buffer ; temp buffer for a string number

	; read next string number
	call lprt_read_chars

	ld a,c
	cp 0 ; no numbers
	jp z,lprt_wrong_exit
	cp 4 ; too many numbers
	jp nc,lprt_wrong_exit

	cp 3
	jr z,lprt_three_int

	cp 2
	jr z,lprt_two_int
	
	; one int only
	ld de,temp_chars_buffer
	ld a,(de)
	sub 48
	ret
	
lprt_wrong_exit:
	xor a
	ret

; two int
lprt_two_int:
	push bc
	ld de,temp_chars_buffer
	ld a,(de)
	sub 48
	push de
	ld de,#000000
	ld e,a
	ld d,10
	mlt de
	ld b,e
	pop de
	inc de
	ld a,(de)
	sub 48
	add a,b ; full int value is here	
	pop bc
	ret
	
; three int
lprt_three_int:
	push bc
	ld de,temp_chars_buffer
	ld a,(de)
	sub 48
	push de
	ld de,#000000
	ld e,a
	ld d,100
	mlt de
	ld b,e
	pop de
	inc de
	ld a,(de)
	sub 48
	push de
	ld de,#000000
	ld e,a
	ld d,10
	mlt de
	ld c,e
	pop de
	inc de
	ld a,(de)
	sub 48
	add a,c
	add a,b ; full int value is here
	pop bc
	ret

lprt_read_chars:
	ld a,13
	ld (de),a ; store eol as next default temp char
	
	ld a,(hl) ; get the new char in the palette buffer
	inc hl
	
	cp 32
	ret z ; ret if space
	cp 13
	jr z,lprt_read_chars ; loop if CR
	cp 10
	ret z ; ret if LF
	cp 48
	ret c ; ret if not number
	cp 58
	ret nc ; ret if not number

; found a number, store it
	ld (de),a
	inc de
	inc c
	jp lprt_read_chars

; set tint
lp_set_tint:
	push af
	push bc
	push de
	push hl

	push bc
	
	; store palette in the real palette buffer
	; to use RGB values later with sprites
	push hl
	push de
	push bc	
	ld hl,real_palette_buffer
	ld de,$000000
	ld e,b
	ld d,3
	mlt de
	add hl,de
	ld de,red_tint
	ld a,(de)
	ld (hl),a ; red
	inc hl
	ld de,green_tint
	ld a,(de)
	ld (hl),a ; green
	inc hl
	ld de,blue_tint
	ld a,(de)
	ld (hl),a ; blue
	pop bc
	pop de
	pop hl

	vdu 19
	pop bc
	ld a,b
	vdu_a
	vdu 255
	
	ld hl,red_tint
	ld a,(hl)
	vdu_a

	ld hl,green_tint
	ld a,(hl)
	vdu_a

	ld hl,blue_tint
	ld a,(hl)
	vdu_a

	pop hl
	pop de
	pop bc
	pop af
	ret

; init a sprite
; hl -> address of sprite data
; a -> current sprite number
; c -> return number of frames
init_sprite:
	PUSH HL
	POP IX

	LD HL,frames_count
	LD C,(IX+1) ; get frames count
	ld (HL),C
	
	LD HL,bitmap_size
	LD B,(IX+2) ; get bitmap size
	ld (HL),B
	
	INC IX
	INC IX
	INC IX

	LD HL,current_sprite
	LD (HL),A
	
	LD HL,current_bitmap
	LD DE,start_bitmap
	LD A,(HL)
	LD (DE),A
	
is_big_loop:
	PUSH BC
	PUSH IX
	
	; select bitmap
	VDU 23
	VDU 27
	VDU 0
	LD HL,current_bitmap
	LD A,(HL)
	PUSH HL
	VDU_A
	POP HL
	INC A
	LD (HL),A
	
	; width & height -> de, hl
	LD HL,bitmap_size
	LD DE,$000000
	LD E,(HL)
	PUSH DE
	POP HL

	; get bitmap data
	PUSH DE
	PUSH HL
	PUSH DE
	VDU 23
	VDU 27
	VDU 1
	POP DE
	VDU_DE
	POP HL
	VDU_HL
	POP DE
	LD D,E
	MLT DE ; de -> size of data

	POP IX
	POP BC
	
is_loop:
	LD A,(IX+0)
	PUSH IX
	PUSH DE
	PUSH BC
	CALL send_RGBA_to_VDP
	POP BC
	POP DE
	POP IX
	INC IX
	DEC DE
	LD A,D
	OR E
	CP 0
	JR NZ,is_loop

	DEC C
	LD A,C
	CP 0
	JR Z,is_add_frames_to_sprite
	JP is_big_loop

is_add_frames_to_sprite:
	; prepare current sprite
	LD HL,current_sprite
	LD A,(HL)
	
	; select sprite
	PUSH AF
	VDU 23
	VDU 27
	VDU 4
	POP AF
	VDU_A

	; clear frames in sprite
	VDU 23
	VDU 27
	VDU 5

	LD HL,frames_count
	LD C,(HL) ; c -> frames count
	LD HL,start_bitmap
	LD A,(HL) ; a -> start bitmap

isafts_loop:
	PUSH BC
	PUSH AF
	VDU 23
	VDU 27
	VDU 6
	POP AF
	PUSH AF
	VDU_A
	POP AF
	INC A
	POP BC
	DEC C
	LD B,A ; save a in B
	LD A,C
	CP 0
	LD A,B ;restore A
	JP NZ,isafts_loop
	
	VDU 23
	VDU 27
	VDU 7
	LD HL,start_bitmap
	LD A,(HL) ; a -> start bitmap
	VDU_A
	
	LD HL,frames_count
	LD C,(HL)
	RET

;  a sprite
; a -> sprite number
; de -> x
; hl -> y
set_sprite_position:
	PUSH HL
	PUSH DE
	PUSH AF
	VDU 23
	VDU 27
	VDU 4
	POP AF
	VDU_A
	
	VDU 23
	VDU 27
	VDU 13
	POP DE
	VDU_DE
	POP HL
	VDU_HL
	RET

; a -> sprite number
show_sprite:
	PUSH HL
	PUSH DE
	PUSH AF
	VDU 23
	VDU 27
	VDU 4
	POP AF
	VDU_A

	VDU 23
	VDU 27
	VDU 11
	RET

; a -> sprite number
hide_sprite:
	PUSH HL
	PUSH DE
	PUSH AF
	VDU 23
	VDU 27
	VDU 4
	POP AF
	VDU_A

	VDU 23
	VDU 27
	VDU 12
	RET

; flip buffer
flip:
	VDU 23
	VDU 27
	VDU 15
	
	VDU 23
	VDU 0
	VDU $C3
	ret
	
; print 'header error'
print_header_error:
	vdu 7	
	
	; locate x,y
	vdu 31
	vdu 0
	vdu 0

	; print text
	ld hl,header_error
	ld bc,0
	xor a
	rst.lis $18

	call input_key
	ret

; print 'file error'
print_file_error:
	vdu 7
	
	; locate x,y
	vdu 31
	vdu 0
	vdu 0

	; print text
	ld hl,file_error
	ld bc,0
	xor a
	rst.lis $18

	call input_key
	ret

; print 'data error'
print_data_error:
	vdu 7	
	
	; locate x,y
	vdu 31
	vdu 0
	vdu 0

	; print text
	ld hl,data_error
	ld bc,0
	xor a
	rst.lis $18

	call input_key
	ret

; get an ascii key value
input_key:
	push bc
	moscall mos_getkey
	pop bc
	ret

; send RGB tint into the VDP
; a -> color
; hl -> real palette
send_RGBA_to_VDP:
	PUSH AF

	LD HL,real_palette_buffer
	LD DE,$000000
	LD E,A
	LD D,3
	MLT DE
	ADD HL,DE	
	
	PUSH HL
	LD A,(HL)
	VDU_A
	POP HL
	
	INC HL
	PUSH HL
	LD A,(HL)
	VDU_A
	POP HL
	
	INC HL
	PUSH HL
	LD A,(HL)
	VDU_A
	POP HL
	
	POP AF
	
	CP 0 ; color = 0 ?
	JR NZ,srtv_not_transparent

	LD A,0 ; alpha = 0
	JR srtv_write

srtv_not_transparent:
	LD A,255 ; alpha = 255
	
srtv_write:
	VDU_A
	RET

; sleep microseconds
; input : BC
sleep:
	PUSH BC
	NOP ; 18 NOPS
	NOP ; for 18 MHtz
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	POP BC
	DEC BC
	LD A,B
	OR C
	CP 0
	JR NZ,sleep
	RET