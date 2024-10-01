; tilesets.inc
; (B.Vignoli)
;
; MIT Licence
; 2024

;===================================
; equ's
TIL_HEADER_BUFFER_SIZE:	equ 16

TIL_MAX_PAL_DATA: equ 836 ; max palette chars
TIL_MAX_PAL_DATA_HI: equ 03h
TIL_MAX_PAL_DATA_LO: equ 44h

;===================================
; data
til_header:
	db "JASC-PAL",13,10
	db "0100",13,10

til_color_buffer:
	db 0,0,0

til_real_palette_buffer:
	ds 192

til_palette_buffer:
	ds TIL_MAX_PAL_DATA + 1

til_temp_chars_buffer:
	db 0,0,0,0

til_tiles_count:
	db 0

til_bitmap_size:
	db 0

til_start_bitmap:
	db 0

til_current_bitmap:
	db 0

til_current_tile:
	db 0

; real number of colors
til_new_colors_count:
	db 0

til_colors_count:
	db 0
	
til_red_tint:
	db 0

til_green_tint:
	db 0

til_blue_tint:
	db 0
	
; file error message
til_file_error:
	db "File error !             ",0

; header error message
til_header_error:
	db "Header error !           ",0

; data error message
til_data_error:
	db "Data error !             ",0

til_rgb_palette:
	db $00,$00,$00
	db $AA,$00,$00
	db $00,$AA,$00
	db $AA,$AA,$00
	db $00,$00,$AA
	db $AA,$00,$AA
	db $00,$AA,$AA
	db $AA,$AA,$AA

	db $55,$55,$55
	db $FF,$00,$00
	db $00,$FF,$00
	db $FF,$FF,$00
	db $00,$00,$FF
	db $FF,$00,$FF
	db $00,$FF,$FF
	db $FF,$FF,$FF

	db $00,$00,$55
	db $00,$55,$00
	db $00,$55,$55
	db $00,$55,$AA
	db $00,$55,$FF
	db $00,$AA,$55
	db $00,$AA,$FF
	db $00,$FF,$55

	db $00,$FF,$AA
	db $55,$00,$00
	db $55,$00,$55
	db $55,$00,$AA
	db $55,$00,$FF
	db $55,$55,$00
	db $55,$55,$AA
	db $55,$55,$FF

	db $55,$AA,$00
	db $55,$AA,$55
	db $55,$AA,$AA
	db $55,$AA,$FF
	db $55,$FF,$00
	db $55,$FF,$55
	db $55,$FF,$AA
	db $55,$FF,$FF

	db $AA,$00,$55
	db $AA,$00,$FF
	db $AA,$55,$00
	db $AA,$55,$55
	db $AA,$55,$AA
	db $AA,$55,$FF
	db $AA,$AA,$55
	db $AA,$AA,$FF

	db $AA,$FF,$00
	db $AA,$FF,$55
	db $AA,$FF,$AA
	db $AA,$FF,$FF
	db $FF,$00,$55
	db $FF,$00,$AA
	db $FF,$55,$00
	db $FF,$55,$55

	db $FF,$55,$AA
	db $FF,$55,$FF
	db $FF,$AA,$00
	db $FF,$AA,$55
	db $FF,$AA,$AA
	db $FF,$AA,$FF
	db $FF,$FF,$55
	db $FF,$FF,$AA

;===================================
; set default palette as the one
; to use for tiles
; (don't forget me when needed !)
til_set_default_palette:
	LD HL,til_rgb_palette
	LD DE,til_real_palette_buffer
	LD BC,64*3
	LDIR
	RET
	
; load a palette
; the right mode must
; be set before
; hl -> pointer to palette
til_load_palette:
	; compare loaded header with needed header
	ld de,til_header
	ld b,TIL_HEADER_BUFFER_SIZE

til_lp_compare:
	ld a,(de)
	cp (hl)
	jp nz,til_lp_header_error
	
	inc de
	inc hl
	dec b
	
	ld a,b
	cp 0
	jp nz,til_lp_compare

	push hl
	pop ix
	
	; prepare to read the number of colors
	ld hl,til_color_buffer
	
til_lp_getcount:
	; read a string for colors count
	ld a,(ix+0)
	inc ix
	
	cp 48 ; < 0
	jr c,til_lpgc_next
	cp 58 ; > 9
	jp nc,til_lp_data_error

	ld (hl),a
	inc hl
	jr til_lp_getcount

til_lpgc_next:
	push af
	ld a,13
	ld (hl),a ; store CR
	pop af

	; test CR
	cp 13
	jp nz,til_lp_close_error

	; read LF
	ld a,(ix+0)
	inc ix

	; test LF
	cp 10
	jp nz,til_lp_close_error

	; prepare to read color strings
	ld de,#000000
	ld hl,til_palette_buffer
	
til_lp_load_pal_loop:
	; read colors data
	ld a,(ix+0)
	inc ix

	ld (hl),a ; store loaded char in palette buffer
	inc hl
	inc de ; count chars
	ld a,d
	cp TIL_MAX_PAL_DATA_HI
	jp c,til_lp_load_pal_loop
	ld a,e
	cp TIL_MAX_PAL_DATA_LO
	jp c,til_lp_load_pal_loop
	jp til_lp_read_palette_data

til_lp_close_error:
	push bc
	
	; read error
	call til_print_file_error
	
	pop bc
	jp til_lp_exit

til_lp_header_error:
	; write error
	call til_print_header_error
	jp til_lp_exit
	
til_lp_read_palette_data:
	; read the number of colors we have in the palette
	ld hl,til_color_buffer
	ld a,(hl)
	ld b,a
	inc hl
	ld a,(hl)
	ld c,a ; bc = 1st char, 2nd char or CR
	
	; first is a char number ?
	ld a,b
	cp 48
	jp c,til_lp_data_error
	cp 58
	jp nc,til_lp_data_error

	ld a,c
	cp 13
	jp nz,til_lp_two_numbers
	
; only one number
	ld a,b
	sub 48
	
	ld hl,til_new_colors_count
	ld (hl),a
	
	cp 0
	jp z,til_lp_data_error
	cp 3
	jp c,til_lp_two_colors
	cp 5
	jp c,til_lp_four_colors
	
	jp til_lp_sixteen_colors

; two numbers
til_lp_two_numbers:
	ld a,c
	cp 48
	jp c,til_lp_data_error
	cp 58
	jp nc,til_lp_data_error
	
	ld a,b
	sub 48
	ld bc,#000000
	ld b,a
	ld c,10
	mlt bc
	add a,c
	
	ld hl,til_new_colors_count
	ld (hl),a

	cp 10
	jp c,til_lp_data_error
	cp 17
	jp c,til_lp_sixteen_colors
	cp 65
	jp c,til_lp_sixty_four_colors
	
	jp til_lp_data_error

til_lp_two_colors:
	ld hl,til_colors_count
	ld a,2
	ld (hl),a

til_lptc_done:
	ld hl,til_new_colors_count
	ld a,(hl) ; real number of coulours
	ld b,0 ; start wit color 0
	ld hl,til_palette_buffer ; palette will be got here
	jp til_lp_read_colors

til_lp_four_colors:
	ld hl,til_colors_count
	ld a,4
	ld (hl),a
	
til_lpfc_done:
	ld hl,til_new_colors_count
	ld a,(hl) ; real number of coulours
	ld b,0 ; start wit color 0
	ld hl,til_palette_buffer ; palette will be got here
	jp til_lp_read_colors

til_lp_sixteen_colors:
	ld hl,til_colors_count
	ld a,16
	ld (hl),a

til_lpsc_done:
	ld hl,til_new_colors_count
	ld a,(hl) ; real number of coulours
	ld b,0 ; start wit color 0
	ld hl,til_palette_buffer ; palette will be got here	
	jp til_lp_read_colors

til_lp_sixty_four_colors:
	ld hl,til_colors_count
	ld a,64
	ld (hl),a

til_lpsfc_done:
	ld hl,til_new_colors_count
	ld a,(hl) ; real number of coulours
	ld b,0 ; start wit color 0
	ld hl,til_palette_buffer ; palette will be taken here
	jp til_lp_read_colors

til_lp_read_colors:
	push af
	
	call til_lp_read_tint ; read red tint

	push hl
	ld hl,til_red_tint
	ld (hl),a	
	pop hl

	call til_lp_read_tint ; read green tint

	push hl
	ld hl,til_green_tint
	ld (hl),a
	pop hl

	call til_lp_read_tint ; read blue tint

	push hl
	ld hl,til_blue_tint
	ld (hl),a
	pop hl
	
	call til_lp_set_tint
	
	pop af
	
	inc b ; increment number of colors
	dec a ; decrement real number of colors
	cp 0
	jp nz,til_lp_read_colors
	
til_lp_exit:
	ret

til_lp_data_error:
	jp til_print_data_error

til_lp_file_error:
	jp til_print_file_error

til_lp_read_tint:
	ld c,0 ; number of chars readen for a single string number
	ld de,til_temp_chars_buffer ; temp buffer for a string number

	; read next string number
	call til_lprt_read_chars

	ld a,c
	cp 0 ; no numbers
	jp z,til_lprt_wrong_exit
	cp 4 ; too many numbers
	jp nc,til_lprt_wrong_exit

	cp 3
	jr z,til_lprt_three_int

	cp 2
	jr z,til_lprt_two_int
	
	; one int only
	ld de,til_temp_chars_buffer
	ld a,(de)
	sub 48
	ret
	
til_lprt_wrong_exit:
	xor a
	ret

; two int
til_lprt_two_int:
	push bc
	ld de,til_temp_chars_buffer
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
til_lprt_three_int:
	push bc
	ld de,til_temp_chars_buffer
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

til_lprt_read_chars:
	ld a,13
	ld (de),a ; store eol as next default temp char
	
	ld a,(hl) ; get the new char in the palette buffer
	inc hl
	
	cp 32
	ret z ; ret if space
	cp 13
	jr z,til_lprt_read_chars ; loop if CR
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
	jp til_lprt_read_chars

; set tint
til_lp_set_tint:
	push af
	push bc
	push de
	push hl

	push bc
	
	; store palette in the real palette buffer
	; to use RGB values later with tiles
	push hl
	push de
	push bc	
	ld hl,til_real_palette_buffer
	ld de,$000000
	ld e,b
	ld d,3
	mlt de
	add hl,de
	ld de,til_red_tint
	ld a,(de)
	ld (hl),a ; red
	inc hl
	ld de,til_green_tint
	ld a,(de)
	ld (hl),a ; green
	inc hl
	ld de,til_blue_tint
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
	
	ld hl,til_red_tint
	ld a,(hl)
	vdu_a

	ld hl,til_green_tint
	ld a,(hl)
	vdu_a

	ld hl,til_blue_tint
	ld a,(hl)
	vdu_a

	pop hl
	pop de
	pop bc
	pop af
	ret

; init a tileset (8x8xsize*size)
; hl -> address of tiles data
; a -> first bitmap to use as tile
; c -> return number of tiles
til_init:
	PUSH HL
	POP IX

	LD HL,til_tiles_count
	LD C,(IX+1) ; get tiles count
	LD (HL),C
	
	LD HL,til_bitmap_size
	LD B,(IX+2) ; get bitmap size
	LD (HL),B
	
	INC IX
	INC IX
	INC IX

	LD HL,til_current_bitmap
	LD DE,til_start_bitmap
	LD (HL),A
	LD (DE),A
	
tili_big_loop:
	PUSH BC
	PUSH IX
	
	; select bitmap
	VDU 23
	VDU 27
	VDU 0
	LD HL,til_current_bitmap
	LD A,(HL)
	PUSH HL
	VDU_A
	POP HL
	INC A
	LD (HL),A
	
	; width & height -> de, hl
	LD HL,til_bitmap_size
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
	
tili_loop:
	LD A,(IX+0)
	PUSH IX
	PUSH DE
	PUSH BC
	CALL til_send_RGBA_to_VDP
	POP BC
	POP DE
	POP IX
	INC IX
	DEC DE
	LD A,D
	OR E
	CP 0
	JR NZ,tili_loop

	DEC C
	LD A,C
	CP 0
	RET Z
	JP tili_big_loop

; select bitmap tile
; a -> bitmap number
til_select:
	PUSH AF
	VDU 23
	VDU 27
	VDU 0
	POP AF
	VDU_A
	RET

; draw currently selected bitmap tile
til_draw:
	PUSH HL
	PUSH DE
	VDU 23
	VDU 27
	VDU 3
	POP DE
	VDU_DE
	POP HL
	VDU_HL
	RET
	
; print 'header error'
til_print_header_error:
	vdu 7	
	
	; locate x,y
	vdu 31
	vdu 0
	vdu 0

	; print text
	ld hl,til_header_error
	ld bc,0
	xor a
	rst.lis $18

	jp til_input_key

; print 'file error'
til_print_file_error:
	vdu 7
	
	; locate x,y
	vdu 31
	vdu 0
	vdu 0

	; print text
	ld hl,til_file_error
	ld bc,0
	xor a
	rst.lis $18

	jp til_input_key

; print 'data error'
til_print_data_error:
	vdu 7	
	
	; locate x,y
	vdu 31
	vdu 0
	vdu 0

	; print text
	ld hl,til_data_error
	ld bc,0
	xor a
	rst.lis $18

	jp til_input_key

; send RGB tint into the VDP
; a -> color
; hl -> real palette
til_send_RGBA_to_VDP:
	PUSH AF

	LD HL,til_real_palette_buffer
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
	JR NZ,til_srtv_not_transparent

	LD A,0 ; alpha = 0
	JR til_srtv_write

til_srtv_not_transparent:
	LD A,255 ; alpha = 255
	
til_srtv_write:
	VDU_A
	RET

; get an ascii key value
; (needed in case of file errors)
til_input_key:
	push bc
	moscall mos_getkey
	pop bc
	ret
