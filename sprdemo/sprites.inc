; sprites.inc
; (B.Vignoli)
;
; MIT Licence
; 2024

;===================================
; equ's
SPR_HEADER_BUFFER_SIZE:	equ 16

SPR_MAX_PAL_DATA: equ 836 ; max palette chars
SPR_MAX_PAL_DATA_HI: equ 03h
SPR_MAX_PAL_DATA_LO: equ 44h

;===================================
; data
spr_header:
	db "JASC-PAL",13,10
	db "0100",13,10

spr_color_buffer:
	db 0,0,0

spr_real_palette_buffer:
	ds 192

spr_palette_buffer:
	ds SPR_MAX_PAL_DATA + 1

spr_temp_chars_buffer:
	db 0,0,0,0

spr_frames_count:
	db 0

spr_bitmap_size:
	db 0

spr_start_bitmap:
	db 0

spr_current_bitmap:
	db 0

spr_current_sprite:
	db 0

; real number of colors
spr_new_colors_count:
	db 0

spr_colors_count:
	db 0
	
spr_red_tint:
	db 0

spr_green_tint:
	db 0

spr_blue_tint:
	db 0
	
; file error message
spr_file_error:
	db "File error !             ",0

; header error message
spr_header_error:
	db "Header error !           ",0

; data error message
spr_data_error:
	db "Data error !             ",0

spr_rgb_palette:
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
; to use for sprites
; (don't forget me when needed !)
spr_set_default_palette:
	LD HL,spr_rgb_palette
	LD DE,spr_real_palette_buffer
	LD BC,64*3
	LDIR
	RET
	
; load a palette
; the right mode must
; be set before
; hl -> pointer to palette
spr_load_palette:
	; compare loaded header with needed header
	ld de,spr_header
	ld b,SPR_HEADER_BUFFER_SIZE

spr_lp_compare:
	ld a,(de)
	cp (hl)
	jp nz,spr_lp_header_error
	
	inc de
	inc hl
	dec b
	
	ld a,b
	cp 0
	jp nz,spr_lp_compare

	push hl
	pop ix
	
	; prepare to read the number of colors
	ld hl,spr_color_buffer
	
spr_lp_getcount:
	; read a string for colors count
	ld a,(ix+0)
	inc ix
	
	cp 48 ; < 0
	jr c,spr_lpgc_next
	cp 58 ; > 9
	jp nc,spr_lp_data_error

	ld (hl),a
	inc hl
	jr spr_lp_getcount

spr_lpgc_next:
	push af
	ld a,13
	ld (hl),a ; store CR
	pop af

	; test CR
	cp 13
	jp nz,spr_lp_close_error

	; read LF
	ld a,(ix+0)
	inc ix

	; test LF
	cp 10
	jp nz,spr_lp_close_error

	; prepare to read color strings
	ld de,#000000
	ld hl,spr_palette_buffer
	
spr_lp_load_pal_loop:
	; read colors data
	ld a,(ix+0)
	inc ix

	ld (hl),a ; store loaded char in palette buffer
	inc hl
	inc de ; count chars
	ld a,d
	cp SPR_MAX_PAL_DATA_HI
	jp c,spr_lp_load_pal_loop
	ld a,e
	cp SPR_MAX_PAL_DATA_LO
	jp c,spr_lp_load_pal_loop
	jp spr_lp_read_palette_data

spr_lp_close_error:
	push bc
	
	; read error
	call spr_print_file_error
	
	pop bc
	jp spr_lp_exit

spr_lp_header_error:
	; write error
	call spr_print_header_error
	jp spr_lp_exit
	
spr_lp_read_palette_data:
	; read the number of colors we have in the palette
	ld hl,spr_color_buffer
	ld a,(hl)
	ld b,a
	inc hl
	ld a,(hl)
	ld c,a ; bc = 1st char, 2nd char or CR
	
	; first is a char number ?
	ld a,b
	cp 48
	jp c,spr_lp_data_error
	cp 58
	jp nc,spr_lp_data_error

	ld a,c
	cp 13
	jp nz,spr_lp_two_numbers
	
; only one number
	ld a,b
	sub 48
	
	ld hl,spr_new_colors_count
	ld (hl),a
	
	cp 0
	jp z,spr_lp_data_error
	cp 3
	jp c,spr_lp_two_colors
	cp 5
	jp c,spr_lp_four_colors
	
	jp spr_lp_sixteen_colors

; two numbers
spr_lp_two_numbers:
	ld a,c
	cp 48
	jp c,spr_lp_data_error
	cp 58
	jp nc,spr_lp_data_error
	
	ld a,b
	sub 48
	ld bc,#000000
	ld b,a
	ld c,10
	mlt bc
	add a,c
	
	ld hl,spr_new_colors_count
	ld (hl),a

	cp 10
	jp c,spr_lp_data_error
	cp 17
	jp c,spr_lp_sixteen_colors
	cp 65
	jp c,spr_lp_sixty_four_colors
	
	jp spr_lp_data_error

spr_lp_two_colors:
	ld hl,spr_colors_count
	ld a,2
	ld (hl),a

spr_lptc_done:
	ld hl,spr_new_colors_count
	ld a,(hl) ; real number of coulours
	ld b,0 ; start wit color 0
	ld hl,spr_palette_buffer ; palette will be got here
	jp spr_lp_read_colors

spr_lp_four_colors:
	ld hl,spr_colors_count
	ld a,4
	ld (hl),a
	
spr_lpfc_done:
	ld hl,spr_new_colors_count
	ld a,(hl) ; real number of coulours
	ld b,0 ; start wit color 0
	ld hl,spr_palette_buffer ; palette will be got here
	jp spr_lp_read_colors

spr_lp_sixteen_colors:
	ld hl,spr_colors_count
	ld a,16
	ld (hl),a

spr_lpsc_done:
	ld hl,spr_new_colors_count
	ld a,(hl) ; real number of coulours
	ld b,0 ; start wit color 0
	ld hl,spr_palette_buffer ; palette will be got here	
	jp spr_lp_read_colors

spr_lp_sixty_four_colors:
	ld hl,spr_colors_count
	ld a,64
	ld (hl),a

spr_lpsfc_done:
	ld hl,spr_new_colors_count
	ld a,(hl) ; real number of coulours
	ld b,0 ; start wit color 0
	ld hl,spr_palette_buffer ; palette will be taken here
	jp spr_lp_read_colors

spr_lp_read_colors:
	push af
	
	call spr_lp_read_tint ; read red tint

	push hl
	ld hl,spr_red_tint
	ld (hl),a	
	pop hl

	call spr_lp_read_tint ; read green tint

	push hl
	ld hl,spr_green_tint
	ld (hl),a
	pop hl

	call spr_lp_read_tint ; read blue tint

	push hl
	ld hl,spr_blue_tint
	ld (hl),a
	pop hl
	
	call spr_lp_set_tint
	
	pop af
	
	inc b ; increment number of colors
	dec a ; decrement real number of colors
	cp 0
	jp nz,spr_lp_read_colors
	
spr_lp_exit:
	ret

spr_lp_data_error:
	jp spr_print_data_error

spr_lp_file_error:
	jp spr_print_file_error

spr_lp_read_tint:
	ld c,0 ; number of chars readen for a single string number
	ld de,spr_temp_chars_buffer ; temp buffer for a string number

	; read next string number
	call spr_lprt_read_chars

	ld a,c
	cp 0 ; no numbers
	jp z,spr_lprt_wrong_exit
	cp 4 ; too many numbers
	jp nc,spr_lprt_wrong_exit

	cp 3
	jr z,spr_lprt_three_int

	cp 2
	jr z,spr_lprt_two_int
	
	; one int only
	ld de,spr_temp_chars_buffer
	ld a,(de)
	sub 48
	ret
	
spr_lprt_wrong_exit:
	xor a
	ret

; two int
spr_lprt_two_int:
	push bc
	ld de,spr_temp_chars_buffer
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
spr_lprt_three_int:
	push bc
	ld de,spr_temp_chars_buffer
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

spr_lprt_read_chars:
	ld a,13
	ld (de),a ; store eol as next default temp char
	
	ld a,(hl) ; get the new char in the palette buffer
	inc hl
	
	cp 32
	ret z ; ret if space
	cp 13
	jr z,spr_lprt_read_chars ; loop if CR
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
	jp spr_lprt_read_chars

; set tint
spr_lp_set_tint:
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
	ld hl,spr_real_palette_buffer
	ld de,$000000
	ld e,b
	ld d,3
	mlt de
	add hl,de
	ld de,spr_red_tint
	ld a,(de)
	ld (hl),a ; red
	inc hl
	ld de,spr_green_tint
	ld a,(de)
	ld (hl),a ; green
	inc hl
	ld de,spr_blue_tint
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
	
	ld hl,spr_red_tint
	ld a,(hl)
	vdu_a

	ld hl,spr_green_tint
	ld a,(hl)
	vdu_a

	ld hl,spr_blue_tint
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
spr_init:
	PUSH HL
	POP IX

	LD HL,spr_frames_count
	LD C,(IX+1) ; get frames count
	ld (HL),C
	
	LD HL,spr_bitmap_size
	LD B,(IX+2) ; get bitmap size
	ld (HL),B
	
	INC IX
	INC IX
	INC IX

	LD HL,spr_current_sprite
	LD (HL),A
	
	LD HL,spr_current_bitmap
	LD DE,spr_start_bitmap
	LD A,(HL)
	LD (DE),A
	
spri_big_loop:
	PUSH BC
	PUSH IX
	
	; select bitmap
	VDU 23
	VDU 27
	VDU 0
	LD HL,spr_current_bitmap
	LD A,(HL)
	PUSH HL
	VDU_A
	POP HL
	INC A
	LD (HL),A
	
	; width & height -> de, hl
	LD HL,spr_bitmap_size
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
	
spri_loop:
	LD A,(IX+0)
	PUSH IX
	PUSH DE
	PUSH BC
	CALL spr_send_RGBA_to_VDP
	POP BC
	POP DE
	POP IX
	INC IX
	DEC DE
	LD A,D
	OR E
	CP 0
	JR NZ,spri_loop

	DEC C
	LD A,C
	CP 0
	JR Z,spri_add_frames_to_sprite
	JP spri_big_loop

spri_add_frames_to_sprite:
	; prepare current sprite
	LD HL,spr_current_sprite
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

	LD HL,spr_frames_count
	LD C,(HL) ; c -> frames count
	LD HL,spr_start_bitmap
	LD A,(HL) ; a -> start bitmap

spriafts_loop:
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
	JP NZ,spriafts_loop

	LD HL,spr_frames_count
	LD C,(HL)
	RET

; activate sprites
; a -> sprites count
spr_activate:
	PUSH AF
	VDU 23
	VDU 27
	VDU 7
	POP AF
	VDU_A
	RET

; select sprite a
spr_select:
	PUSH AF
	VDU 23
	VDU 27
	VDU 4
	POP AF
	VDU_A
	RET

;  a sprite
; a -> sprite number
; de -> x
; hl -> y
spr_set_position:
	PUSH HL
	PUSH DE
	VDU 23
	VDU 27
	VDU 13
	POP DE
	VDU_DE
	POP HL
	VDU_HL
	RET

; a -> sprite number
spr_show:
	VDU 23
	VDU 27
	VDU 11
	RET

; a -> sprite number
spr_hide:
	VDU 23
	VDU 27
	VDU 12
	RET

; flip buffer
spr_update:
	VDU 23
	VDU 27
	VDU 15
	ret

; flip buffer
spr_flip:
	VDU 23
	VDU 0
	VDU $C3
	ret

spr_set_next_frame:
	VDU 23
	VDU 27
	VDU 8	
	RET

spr_set_previous_frame:
	VDU 23
	VDU 27
	VDU 9
	RET
	
; print 'header error'
spr_print_header_error:
	vdu 7	
	
	; locate x,y
	vdu 31
	vdu 0
	vdu 0

	; print text
	ld hl,spr_header_error
	ld bc,0
	xor a
	rst.lis $18

	jp spr_input_key

; print 'file error'
spr_print_file_error:
	vdu 7
	
	; locate x,y
	vdu 31
	vdu 0
	vdu 0

	; print text
	ld hl,spr_file_error
	ld bc,0
	xor a
	rst.lis $18

	jp spr_input_key

; print 'data error'
spr_print_data_error:
	vdu 7	
	
	; locate x,y
	vdu 31
	vdu 0
	vdu 0

	; print text
	ld hl,spr_data_error
	ld bc,0
	xor a
	rst.lis $18

	jp spr_input_key

; send RGB tint into the VDP
; a -> color
; hl -> real palette
spr_send_RGBA_to_VDP:
	PUSH AF

	LD HL,spr_real_palette_buffer
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
	JR NZ,spr_srtv_not_transparent

	LD A,0 ; alpha = 0
	JR spr_srtv_write

spr_srtv_not_transparent:
	LD A,255 ; alpha = 255
	
spr_srtv_write:
	VDU_A
	RET

; sleep 10 ms (approximatively)
spr_sleep10:
	LD BC,10000
	CALL spr_sleep
	RET

; sleep 50 ms (approximatively)
spr_sleep50:
	LD BC,50000
	CALL spr_sleep
	RET

; sleep microseconds
; input : BC*HL
spr_sleep:
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
	JR NZ,spr_sleep
	RET

; get an ascii key value
; (needed in case of file errors)
spr_input_key:
	push bc
	moscall mos_getkey
	pop bc
	ret
