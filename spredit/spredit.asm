; SprEdit.asm (Work In Progress)
;
; by B.Vignoli
; MIT 2023-2024
;
; Tested under firmware 1.0.4 RC1+
;

.assume adl=1
.org $040000

	jp start

; MOS header
.align 64
.db "MOS",0,1

	include "mos_api.inc"

MAX_COLORS:		 	equ 64
COLOR_MIN:	 		equ 0
COLOR_MAX:	 		equ 63

MAX_FRAMES:			equ 8

COLOR_WHITE:		equ 15
COLOR_GREY:			equ 7
COLOR_BLACK:		equ 0

TITLE_X: 	equ 17
TITLE_Y: 	equ 2
MENU_X: 	equ 13
MENU1_Y: 	equ 8
MENU2_Y: 	equ 12
MENU3_Y: 	equ 16
MENU4_Y: 	equ 20
MENU5_Y: 	equ 24
FILENAME_X: equ 7
FILENAME_Y: equ 24

SPR44: 		equ 4
SPR88: 		equ 8
SPR1616: 	equ 16
SPR3232: 	equ 32

SPR44_width: 	equ 128
SPR88_width: 	equ 64
SPR1616_width: 	equ 32
SPR3232_width: 	equ 16

BUFFER_SIZE:			equ 8192 ; 8 frames
ONE_FRAME_BUFFER_SIZE:	equ 1024

SLOWDOWN_DELAY:	equ 20

VK_ESCAPE: 		equ 125
VK_UP: 			equ 150
VK_DOWN: 		equ 152
VK_LEFT: 		equ 154
VK_RIGHT: 		equ 156
VK_SPACE: 		equ 1
VK_RETURN: 		equ 143
VK_TAB:			equ 142
VK_DELETE:		equ 130
VK_BACKSPACE:	equ 132
VK_PGUP:		equ 146
VK_PGDOWN:		equ 148
VK_1: 			equ 93
VK_2: 			equ 178
VK_3: 			equ 77
VK_4: 			equ 76
VK_5: 			equ 108
VK_6: 			equ 0
VK_7: 			equ 0
VK_8: 			equ 0
VK_9: 			equ 0
VK_0: 			equ 0
VK_NUMPAD_1: 	equ 0
VK_NUMPAD_2: 	equ 153
VK_NUMPAD_3: 	equ 0
VK_NUMPAD_4: 	equ 155
VK_NUMPAD_5: 	equ 0
VK_NUMPAD_6: 	equ 157
VK_NUMPAD_7: 	equ 0
VK_NUMPAD_8: 	equ 151
VK_NUMPAD_9: 	equ 0
VK_NUMPAD_0: 	equ 0
VK_a: 			equ 22
VK_b: 			equ 23
VK_c:			equ 24
VK_d: 			equ 25
VK_e: 			equ 26
VK_f: 			equ 27
VK_g: 			equ 28
VK_h: 			equ 29
VK_i: 			equ 30
VK_j: 			equ 31
VK_k: 			equ 32
VK_l: 			equ 33
VK_m: 			equ 34
VK_n: 			equ 35
VK_o: 			equ 36
VK_p: 			equ 37
VK_q: 			equ 38
VK_r: 			equ 39
VK_s: 			equ 40
VK_t: 			equ 41
VK_u: 			equ 42
VK_v: 			equ 43
VK_w: 			equ 44
VK_x: 			equ 45
VK_y: 			equ 46
VK_z: 			equ 47
VK_A: 			equ 48
VK_B: 			equ 49
VK_C:			equ 50
VK_D: 			equ 51
VK_E: 			equ 52
VK_F: 			equ 53
VK_G: 			equ 54
VK_H: 			equ 55
VK_I: 			equ 56
VK_J: 			equ 57
VK_K: 			equ 58
VK_L: 			equ 59
VK_M: 			equ 60
VK_N: 			equ 61
VK_O: 			equ 62
VK_P: 			equ 63
VK_Q: 			equ 64
VK_R: 			equ 65
VK_S: 			equ 66
VK_T: 			equ 67
VK_U: 			equ 68
VK_V: 			equ 69
VK_W: 			equ 70
VK_X: 			equ 71
VK_Y: 			equ 72
VK_Z: 			equ 73

;======================================================================
start:
	push af
	push bc
	push de
	push ix
	push iy

	; set mode 8 (320x240x64)
	vdu 22
	vdu 8
	
	; set text colors
	vdu 17
	vdu 128 ; black background

	vdu 17
	vdu COLOR_WHITE ; white pen
	
	; set graphics pen
	vdu 18
	vdu 0
	vdu COLOR_WHITE ; white pen
	
	; hide cursor
	vdu 23
	vdu 1
	vdu 0
	
	; store coordinates
	ld ix,x1
	ld hl,0
	ld (ix+0),l
	ld (ix+1),h

	ld ix,y1
	ld hl,0
	ld (ix+0),l
	ld (ix+1),h

	ld ix,x2
	ld hl,1279
	ld (ix+0),l
	ld (ix+1),h

	ld ix,y2
	ld hl,1023
	ld (ix+0),l
	ld (ix+1),h
	
	; draw the border rectangle
	call fn_rect

	; locate x,y
	vdu 31
	vdu TITLE_X
	vdu TITLE_Y

	; print text
	ld hl,title
	ld bc,0
	xor a
	rst.lis $18

	; locate x,y
	vdu 31
	vdu MENU_X
	vdu MENU1_Y

	; print text
	ld hl,menu1
	ld bc,0
	xor a
	rst.lis $18

	; locate x,y
	vdu 31
	vdu MENU_X
	vdu MENU2_Y

	; print text
	ld hl,menu2
	ld bc,0
	xor a
	rst.lis $18

	; locate x,y
	vdu 31
	vdu MENU_X
	vdu MENU3_Y

	; print text
	ld hl,menu3
	ld bc,0
	xor a
	rst.lis $18

	; locate x,y
	vdu 31
	vdu MENU_X
	vdu MENU4_Y

	; print text
	ld hl,menu4
	ld bc,0
	xor a
	rst.lis $18

	; reset keycode
	xor a

; menu loop
menu_loop:
	; get a keycode
	call fn_wait_key
	
	; wait key to be released
	push af
	push hl
	call fn_wait_key_released
	pop hl
	pop af

	cp VK_ESCAPE
	jp z,exit_program

	cp VK_1
	jr nz,not_menu1

	ld a,SPR44
	ld d,SPR44_width
	jr exit_menu_loop
	
not_menu1:
	cp VK_2
	jr nz,not_menu2
	
	ld a,SPR88
	ld d,SPR88_width
	jr exit_menu_loop

not_menu2:
	cp VK_3
	jr nz,not_menu3
	
	ld a,SPR1616
	ld d,SPR1616_width
	jr exit_menu_loop

not_menu3:
	cp VK_4
	jr nz,menu_loop

	ld a,SPR3232
	ld d,SPR3232_width

exit_menu_loop:
	; store edited sprite size
	ld hl,spr_size
	ld (hl),a
	ld hl,pixel_width
	ld (hl),d

	; clear the text screen
	vdu 12
	
	; draw the palette
	ld c,0

palette_loop:
	push bc

	; choose palette color
	vdu 18
	vdu 0
	pop bc
	push bc
	ld a,c
	vdu_a

	; store coordinates for a palette square
	ld ix,x1
	pop hl
	push hl
	ld h,20
	mlt hl
	push hl
	ld (ix+0),l
	ld (ix+1),h

	ld ix,y1
	ld hl,984
	ld (ix+0),l
	ld (ix+1),h

	ld ix,x2
	pop hl
	ld de,19
	add hl,de
	ld (ix+0),l
	ld (ix+1),h

	ld ix,y2
	ld hl,1019
	ld (ix+0),l
	ld (ix+1),h
	
	; draw the palette filled square
	call fn_rectf
	
	; next color ?
	pop bc
	inc c
	ld a,c
	cp MAX_COLORS
	jp nz,palette_loop
	
	; store coordinates
	ld ix,x1
	ld hl,0
	ld (ix+0),l
	ld (ix+1),h

	ld ix,y1
	ld hl,0
	ld (ix+0),l
	ld (ix+1),h

	ld ix,x2
	ld hl,1279
	ld (ix+0),l
	ld (ix+1),h

	ld ix,y2
	ld hl,1023
	ld (ix+0),l
	ld (ix+1),h
	
	; draw the border rectangle
	call fn_rect
	
	; store edited sprite coordinates
	ld ix,xs1
	ld iy,x1
	ld l,(ix+0)
	ld h,(ix+1)
	ld (iy+0),l
	ld (iy+1),h

	ld ix,ys1
	ld iy,y1
	ld l,(ix+0)
	ld h,(ix+1)
	ld (iy+0),l
	ld (iy+1),h

	ld ix,xs2
	ld iy,x2
	ld l,(ix+0)
	ld h,(ix+1)
	ld (iy+0),l
	ld (iy+1),h

	ld ix,ys2
	ld iy,y2
	ld l,(ix+0)
	ld h,(ix+1)
	ld (iy+0),l
	ld (iy+1),h
	
	; draw the sprite's border rectangle
	call fn_rect

	; locate 15,4
	vdu 31
	vdu 15
	vdu 4

	; print text
	ld hl,spr_descr
	ld bc,0
	xor a
	rst.lis $18

	; locate 15,6
	vdu 31
	vdu 15
	vdu 6

	; check for sprite size...
	ld hl,spr_size
	ld a,(hl)
	
	cp 4
	jr nz, not4x4

	; print text 4x4
	ld hl,spr_descr1
	ld bc,0
	xor a
	rst.lis $18
	jr init_sprite_vars
	
not4x4:
	cp 8
	jr nz, not8x8

	; print text 8x8
	ld hl,spr_descr2
	ld bc,0
	xor a
	rst.lis $18
	jr init_sprite_vars
	
not8x8:
	cp 16
	jr nz, not16x16

	; print text 16x16
	ld hl,spr_descr3
	ld bc,0
	xor a
	rst.lis $18
	jr init_sprite_vars

not16x16:
	; print text 32x32
	ld hl,spr_descr4
	ld bc,0
	xor a
	rst.lis $18

; initialize sprite vars
init_sprite_vars:
	; initialize coordinates before drawing the sprite
	ld ix,xpix
	xor a
	ld (ix+0),a ; xpix = 0
	ld (ix+1),a	; ypix = 0
	ld ix,current_pen
	ld a,COLOR_WHITE
	ld (ix+0),a ; current pen -> white
	
	; set vars
	ld hl,colors_count
	ld a,MAX_COLORS
	ld (hl),a
	ld hl,current_frame
	xor a
	ld (hl),a
	inc a
	ld hl,frames_count
	ld (hl),a

	; fill buffers with zeros
	ld bc,BUFFER_SIZE
	ld hl,sprite_buffer

isv_fill_loop:
	xor a
	ld (hl),a
	dec bc
	inc hl
	ld a,b
	or c
	cp 0
	jr nz,isv_fill_loop

; draw the pixel with a border
	call fn_draw_pixel_with_border

	call fn_wait_key_released

; draw sprite loop	
draw_sprite_loop:
	; get a keycode
	call fn_wait_key

	; if not keydown, loop
	ld d,a
	ld a,l
	and 1
	cp 0
	ld a,d
	jp z,draw_sprite_loop
	
	cp 0 ; keycode = 0 ? loop
	jp z,draw_sprite_loop
	
	cp VK_SPACE ; on space key....
	jp z,dsl_set_pen

	cp VK_DELETE ; on delete key....
	jp z,dsl_reset_pen
	
	cp VK_UP ; on up arrow...
	jp z,dsl_up
	
	cp VK_DOWN ; on down arrow...
	jp z,dsl_down
	
	cp VK_LEFT ; on left arrow...
	jp z,dsl_left
	
	cp VK_RIGHT ; on right arrow...
	jp z,dsl_right
	
	cp VK_TAB ; on tab key...
	jp z,dsl_palette_tool

	cp VK_n ; on n key...
	jp z,dsl_add_frame

	cp VK_N ; on N key...
	jp z,dsl_add_frame

	cp VK_c ; on c key...
	jp z,dsl_add_and_copy_frame

	cp VK_C ; on C key...
	jp z,dsl_add_and_copy_frame

	cp VK_BACKSPACE ; on backspace key...
	jp z,dsl_delete_frame
	
	cp VK_PGUP ; on pageup key...
	jp z,dsl_next_frame

	cp VK_PGDOWN ; on pagedown key...
	jp z,dsl_previous_frame

	cp VK_l ; on l key...
	jp z,dsl_load_sprite

	cp VK_L ; on L key...
	jp z,dsl_load_sprite

	cp VK_s ; on s key...
	jp z,dsl_save_sprite

	cp VK_S ; on S key...
	jp z,dsl_save_sprite

	cp VK_ESCAPE ; on escape key...
	jp z,exit_program

	jp draw_sprite_loop

; set the pen of the current pixel
dsl_set_pen:
	call fn_get_pixel_color
	ld hl,current_pen
	cp (hl)
	jp z,draw_sprite_loop
	ld a,(hl)
	call fn_set_pixel_color
	call fn_draw_pixel_with_border
	jp draw_sprite_loop

; set the pen of the current pixel
dsl_set_pen2:
	call fn_get_pixel_color
	ld hl,current_pen
	cp (hl)
	ret z
	ld a,(hl)
	call fn_set_pixel_color
	call fn_draw_pixel_with_border
	ret

; reset the pen of the current pixel
dsl_reset_pen:
	call fn_get_pixel_color
	cp 0
	jp z,draw_sprite_loop
	xor a
	call fn_set_pixel_color
	call fn_draw_pixel_with_border
	jp draw_sprite_loop

; move pixel up
dsl_up:
	ld hl,ypix
	ld a,(hl)
	cp 0
	jp z,draw_sprite_loop
	
	; controlkey down ? draw
	ld iy,keydata
	ld a,(iy+2)
	and 1
	cp 1
	call z,dsl_set_pen2

	call fn_draw_pixel_without_border
	call fn_move_up
	call fn_draw_pixel_with_border

	; controlkey down ? draw
	ld iy,keydata
	ld a,(iy+2)
	and 1
	cp 1
	call z,dsl_set_pen2

	call fn_slowdown
	jp draw_sprite_loop

; move pixel down
dsl_down:
	ld hl,spr_size
	ld d,(hl)
	dec d

	ld hl,ypix
	ld a,(hl)
	cp d
	jp z,draw_sprite_loop

	; controlkey down ? draw
	ld iy,keydata
	ld a,(iy+2)
	and 1
	cp 1
	call z,dsl_set_pen2

	call fn_draw_pixel_without_border
	call fn_move_down
	call fn_draw_pixel_with_border

	; controlkey down ? draw
	ld iy,keydata
	ld a,(iy+2)
	and 1
	cp 1
	call z,dsl_set_pen2

	call fn_slowdown
	jp draw_sprite_loop

; move pixel left
dsl_left:
	ld hl,xpix
	ld a,(hl)
	cp 0
	jp z,draw_sprite_loop

	; controlkey down ? draw
	ld iy,keydata
	ld a,(iy+2)
	and 1
	cp 1
	call z,dsl_set_pen2

	call fn_draw_pixel_without_border
	call fn_move_left
	call fn_draw_pixel_with_border

	; controlkey down ? draw
	ld iy,keydata
	ld a,(iy+2)
	and 1
	cp 1
	call z,dsl_set_pen2

	call fn_slowdown
	jp draw_sprite_loop
		
; move pixel right
dsl_right:
	ld hl,spr_size
	ld d,(hl)
	dec d

	ld hl,xpix
	ld a,(hl)
	cp d
	jp z,draw_sprite_loop

	; controlkey down ? draw
	ld iy,keydata
	ld a,(iy+2)
	and 1
	cp 1
	call z,dsl_set_pen2
	
	call fn_draw_pixel_without_border
	call fn_move_right
	call fn_draw_pixel_with_border

	; controlkey down ? draw
	ld iy,keydata
	ld a,(iy+2)
	and 1
	cp 1
	call z,dsl_set_pen2

	call fn_slowdown
	jp draw_sprite_loop

; load a sprite
dsl_load_sprite:
	call fn_wait_key_released
	call fn_draw_pixel_without_border
	call fn_load_sprite
	call fn_refresh_sprite
	call fn_draw_pixel_with_border
	call fn_change_frame
	jp draw_sprite_loop

; save a sprite
dsl_save_sprite:
	call fn_wait_key_released
	call fn_draw_pixel_without_border
	call fn_save_sprite
	call fn_refresh_sprite
	jp draw_sprite_loop

; add a frame to the animation
dsl_add_frame:
	call fn_wait_key_released
	ld hl,frames_count
	ld a,(hl)
	cp MAX_FRAMES
	jp z,draw_sprite_loop
	
	inc a
	ld (hl),a	
	call fn_change_frames_count
	call fn_refresh_sprite
	jp draw_sprite_loop

; add a copy of the current frame to the animation
dsl_add_and_copy_frame: ; TODO! debug me!
	call fn_wait_key_released
	ld hl,frames_count
	ld a,(hl)
	cp MAX_FRAMES
	jp z,draw_sprite_loop

	; inc frame
	inc a
	ld (hl),a
	
	ld hl,spr_size
	ld e,(hl)
	ld d,(hl)
	ex de,hl
	mlt hl ; HL = sprsize²

	dec a
	ld b,a
	cp 0
	jr z,dsl_aacf_end_loop
	
	ld de,sprite_buffer
	ex de,hl ; HL = sprite buffer, DE = sprsize²
dsl_aacf_loop:
	add hl,de
	djnz dsl_aacf_loop

dsl_aacf_end_loop:

	push hl
	pop bc ; BC = 1st sprite address in the buffer
	add hl,de ; HL = 2nd sprite address in the buffer
	
	push bc ; swap bc/de
	push de
	pop bc
	pop de

; copy the frame
dsl_aacf_loop2:
	ld a,(de)
	ld (hl),a
	inc de
	inc hl
	dec bc
	ld a,b
	or c
	cp 0
	jr nz,dsl_aacf_loop2

	call fn_change_frame ; change frame number in the text
	call fn_refresh_sprite
	jp draw_sprite_loop

; delete last frame from animation
dsl_delete_frame: ; TODO! delete the selected frame
	call fn_wait_key_released
	ld hl,current_frame
	ld a,(hl)
	cp 0
	jp z,draw_sprite_loop
	
	dec a
	ld (hl),a
	call fn_change_frame
	call fn_refresh_sprite
	jp draw_sprite_loop

; goto previous frame
dsl_previous_frame:
	call fn_wait_key_released
	ld hl,current_frame
	ld a,(hl)
	cp 0
	jp z,draw_sprite_loop
	
	dec a
	ld (hl),a
	call fn_change_frame
	call fn_refresh_sprite
	jp draw_sprite_loop

; goto next frame
dsl_next_frame:
	call fn_wait_key_released
	ld hl,current_frame
	ld a,(hl)
	inc a
	ld hl,frames_count
	ld c,(hl)
	cp c
	jp z,draw_sprite_loop
	
	ld (hl),a
	call fn_change_frame
	call fn_refresh_sprite
	jp draw_sprite_loop

; change current tool to palette
dsl_palette_tool:
	call fn_wait_key_released

	; hide sprite drawing cursor
	call fn_draw_pixel_without_border
	
	; draw selected palette color
	ld hl,current_pen
	ld c,(hl)
	call fn_draw_palette_with_border
	
; select palette color	
dsl_palette_tool_loop:
	; get a char
	call fn_wait_key

	; if not keydown, loop
	ld d,a
	ld a,l
	and 1
	cp 0
	ld a,d
	jp z,dsl_palette_tool_loop
	
	cp 0 ; keycode = 0 ? loop
	jp z,dsl_palette_tool_loop
	
	cp VK_LEFT ; on left key...
	jp z,dsl_dec_pen
	
	cp VK_RIGHT ; on right key...
	jp z,dsl_inc_pen

	cp VK_TAB ; on tab key...
	jp z,dsl_draw_sprite_tool
	
	cp VK_l ; on l key...
	jp z,dslp_load_sprite

	cp VK_L ; on L key...
	jp z,dslp_load_sprite

	cp VK_s ; on s key...
	jp z,dslp_save_sprite

	cp VK_S ; on S key...
	jp z,dslp_save_sprite

	cp VK_ESCAPE ; on escape key...
	jp z,exit_program
	
	jp dsl_palette_tool_loop

dslp_load_sprite:
	call fn_wait_key_released
	ld hl,current_pen
	ld c,(hl)
	call fn_draw_palette_without_border
	call fn_load_sprite
	ld hl,current_pen
	ld c,(hl)
	call fn_refresh_sprite
	call fn_draw_palette_with_border
	call fn_change_frame
	jp dsl_palette_tool_loop
	
dslp_save_sprite:
	call fn_wait_key_released
	ld hl,current_pen
	ld c,(hl)
	call fn_draw_palette_without_border
	call fn_save_sprite
	ld hl,current_pen
	ld c,(hl)
	call fn_draw_palette_with_border
	jp dsl_palette_tool_loop

dsl_draw_sprite_tool:
	call fn_wait_key_released

	; unselect palette color
	ld hl,current_pen
	ld c,(hl)
	call fn_draw_palette_without_border

	; draw the pixel with a border
	call fn_draw_pixel_with_border

	jp draw_sprite_loop

dsl_dec_pen:	
	ld hl,current_pen
	ld a,(hl)
	cp COLOR_MIN
	jp z,dsl_palette_tool_loop

	push af
	push hl
	
	; unselect palette color
	ld hl,current_pen
	ld c,(hl)
	call fn_draw_palette_without_border

	pop hl
	pop af
	
	; dec the pen
	dec a
	ld (hl),a
	
	; select palette color
	ld hl,current_pen
	ld c,(hl)
	call fn_draw_palette_with_border
	call fn_slowdown
	jp dsl_palette_tool_loop

dsl_inc_pen:
	ld hl,current_pen
	ld a,(hl)
	cp COLOR_MAX
	jp z,dsl_palette_tool_loop

	push af
	push hl
	
	; unselect palette color
	ld hl,current_pen
	ld c,(hl)
	call fn_draw_palette_without_border

	pop hl
	pop af

	; inc the pen
	inc a
	ld (hl),a
	
	; select palette color
	ld hl,current_pen
	ld c,(hl)
	call fn_draw_palette_with_border
	call fn_slowdown
	jp dsl_palette_tool_loop

; exit program
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

; draw a rectangle
fn_rect:
	vdu 25
	vdu 4
	ld ix,x1
	ld a,(ix + 0)
	vdu_a
	ld ix,x1
	ld a,(ix + 1)
	vdu_a
	ld iy,y1
	ld a,(iy + 0)
	vdu_a
	ld iy,y1
	ld a,(iy + 1)
	vdu_a

	vdu 25
	vdu 5
	ld ix,x2
	ld a,(ix + 0)
	vdu_a
	ld ix,x2
	ld a,(ix + 1)
	vdu_a
	ld iy,y1
	ld a,(iy + 0)
	vdu_a
	ld iy,y1
	ld a,(iy + 1)
	vdu_a

	vdu 25
	vdu 5
	ld ix,x2
	ld a,(ix + 0)
	vdu_a
	ld ix,x2
	ld a,(ix + 1)
	vdu_a
	ld iy,y2
	ld a,(iy + 0)
	vdu_a
	ld iy,y2
	ld a,(iy + 1)
	vdu_a

	vdu 25
	vdu 5
	ld ix,x1
	ld a,(ix + 0)
	vdu_a
	ld ix,x1
	ld a,(ix + 1)
	vdu_a
	ld iy,y2
	ld a,(iy + 0)
	vdu_a
	ld iy,y2
	ld a,(iy + 1)
	vdu_a

	vdu 25
	vdu 5
	ld ix,x1
	ld a,(ix + 0)
	vdu_a
	ld ix,x1
	ld a,(ix + 1)
	vdu_a
	ld iy,y1
	ld a,(iy + 0)
	vdu_a
	ld iy,y1
	ld a,(iy + 1)
	vdu_a
	
	ret

; draw a filled rectangle
fn_rectf:
	ld iy,y1
	ld c,(iy+0)
	ld b,(iy+1)	

fn_rectf_loop:
	push bc
	
	ld ix,x1
	vdu 25
	vdu 4
	ld a,(ix + 0)
	vdu_a
	ld a,(ix + 1)
	vdu_a
	pop bc
	ld a,c
	push bc
	vdu_a
	pop bc
	ld a,b
	push bc
	vdu_a

	ld ix,x2
	vdu 25
	vdu 5
	ld a,(ix + 0)
	vdu_a
	ld a,(ix + 1)
	vdu_a
	pop bc
	ld a,c
	push bc
	vdu_a
	pop bc
	ld a,b
	push bc
	vdu_a

	pop bc
	
	; y = y2 ?
	ld iy,y2
	ld a,(iy+1)
	cp b
	jr nz,fn_rectf_not_equal
	
	ld a,(iy+0)
	cp c
	jr nz,fn_rectf_not_equal

	ret
	
fn_rectf_not_equal:
	inc bc
	jp fn_rectf_loop

fn_calc_pixel_coords:
	ld de,$000000 ; reset deu

	; calculate coordinates x of the resized pixel
	ld hl,xpix
	ld e,(hl) ; E = xpix
	ld hl,pixel_width
	ld d,(hl) ; D = pixel_width
	push de
	pop hl ; HL = DE
	mlt hl ; HL = xpix * pixel_width
	ld ix,xs1
	ld e,(ix+0)
	ld d,(ix+1)
	inc de
	inc de
	inc de
	inc de ; DE = xs1 + 4
	add hl,de ; HL = (xpix * pixel_width) + xs1 + 4
	ld iy,x1
	ld (iy+0),l
	ld (iy+1),h ; x1 = (xpix * pixel_width) + xs1 + 4
	push hl
	ld hl,pixel_width
	ld d,0
	ld e,(hl)
	pop hl
	add hl,de
	dec hl
	dec hl
	dec hl
	dec hl
	ld iy,x2
	ld (iy+0),l
	ld (iy+1),h ; x2 = x1 + pixel_width - 4

	ld de,$000000 ; reset deu

	; calculate coordinates y of the resized pixel
	ld hl,spr_size
	ld a,(hl)
	dec a ; A = sprsize - 1
	ld hl,ypix
	ld e,(hl)
	sub e
	ld e,a ; E = (sprsize - 1) - ypix
	ld hl,pixel_width
	ld d,(hl) ; D = pixel_width
	push de
	pop hl
	mlt hl ; HL = ypix * pixel_width
	ld ix,ys1
	ld e,(ix+0)
	ld d,(ix+1) ; ys1 = ypix * pixel_width
	inc de
	inc de
	inc de
	inc de ; DE = ys1 + 4
	add hl,de ; HL = (ypix * pixel_width) + ys1 + 4
	ld iy,y1
	ld (iy+0),l
	ld (iy+1),h ; y1 = (ypix * pixel_width) + ys1 + 4
	push hl
	ld hl,pixel_width
	ld d,0
	ld e,(hl)
	pop hl
	add hl,de
	dec hl
	dec hl
	dec hl
	dec hl
	ld iy,y2
	ld (iy+0),l
	ld (iy+1),h ; y2 = y1 + pixel_width - 4
	
	ret

; draw the resized pixel border, with its color
fn_draw_pixel_with_border:
	call fn_calc_pixel_coords
		
	; set graphics pen
	vdu 18
	vdu 0
	call fn_get_pixel_color
	vdu_a

	; draw the sprite's color rectangle
	call fn_rectf

	; set graphics pen
	vdu 18
	vdu 0
	vdu COLOR_GREY ; grey pen

	; draw the sprite's border rectangle
	jp fn_rect

; draw the resized pixel color
fn_draw_pixel_without_border:
	; draw the resized pixel border
	call fn_calc_pixel_coords

	; set graphics pen
	vdu 18
	vdu 0
	call fn_get_pixel_color
	vdu_a

	; draw the sprite's color rectangle
	jp fn_rectf

; get pixel color value in the sprite buffer
; returns A: pixel color (0-63)
fn_get_pixel_color:
	ld de,$000000 ; reset deu

	; calculate the offset to add to the address
	ld hl,ypix
	ld e,(hl) ; E = ypix
	ld hl,spr_size
	ld d,(hl) ; D = sprsize
	push de
	pop hl
	mlt hl ; HL = ypix * sprsize
	push hl
	ld hl,xpix
	ld e,(hl)
	ld d,0
	pop hl
	add hl,de ; HL = (ypix * sprsize) + xpix
	
	ld de,current_frame
	ld a,(de)
	cp 0
	jr z,gpc_end_loop

	ld b,a
	push hl
	ld de,$000000
	ld hl,spr_size
	ld e,(hl)
	ld d,(hl)
	push de
	pop hl
	mlt hl
	push hl
	pop de ; DE = sprsize²
	pop hl
	
gpc_loop:
	add hl,de
	djnz gpc_loop

gpc_end_loop:
	; add the offset to the address
	ld de,sprite_buffer
	add hl,de ; HL = sprite_buffer + ((ypix * sprsize) + xpix)
	
	; get pixel color value
	ld a,(hl)

	ret

; get pixel color value in the sprite buffer
; A: pixel color (0-63)
fn_set_pixel_color:
	ld de,$000000 ; reset deu

	; calculate the offset to add to the address
	ld hl,ypix
	ld e,(hl) ; E = ypix
	ld hl,spr_size
	ld d,(hl) ; D = sprsize
	push de
	pop hl
	mlt hl ; HL = ypix * sprsize
	push hl
	ld hl,xpix
	ld e,(hl)
	ld d,0
	pop hl
	add hl,de ; HL = (ypix * sprsize) + xpix
	push af
	
	ld de,current_frame
	ld a,(de)
	cp 0
	jr z,spc_end_loop

	ld b,a
	push hl
	ld de,$000000
	ld hl,spr_size
	ld e,(hl)
	ld d,(hl)
	push de
	pop hl
	mlt hl
	push hl
	pop de ; DE = sprsize²
	pop hl
	
spc_loop:
	add hl,de
	djnz spc_loop

spc_end_loop:

	; add the offset to the address
	ld de,sprite_buffer
	add hl,de ; HL = sprite_buffer + ((ypix * sprsize) + xpix)
	
	; set pixel color value
	pop af
	ld (hl),a

	ret

fn_move_up:
	ld hl,ypix
	dec (hl)
	ret

fn_move_down:
	ld hl,ypix
	inc (hl)
	ret

fn_move_left:
	ld hl,xpix
	dec (hl)
	ret

fn_move_right:
	ld hl,xpix
	inc (hl)
	ret

; draw palette color whit border and selection
; C = color number (0-63)
fn_draw_palette_with_border:
	push bc
	
	; choose palette color
	vdu 18
	vdu 0
	pop bc
	push bc
	ld a,c
	vdu_a

	; store coordinates for a palette square
	ld ix,x1
	pop hl
	push hl
	ld h,20
	mlt hl
	push hl
	ld (ix+0),l
	ld (ix+1),h

	ld ix,y1
	ld hl,984
	ld (ix+0),l
	ld (ix+1),h

	ld ix,x2
	pop hl
	ld de,19
	add hl,de
	ld (ix+0),l
	ld (ix+1),h

	ld ix,y2
	ld hl,1019
	ld (ix+0),l
	ld (ix+1),h
	
	; draw the palette filled square
	call fn_rectf
	
	; choose grey color
	vdu 18
	vdu 0
	ld a,COLOR_GREY
	vdu_a

	; draw the palette square border
	call fn_rect

	; next color ?
	pop bc
	
	ret

; draw palette color whitout border and selection
; C = color number (0-63)
fn_draw_palette_without_border:
	push bc
	
	; choose palette color
	vdu 18
	vdu 0
	pop bc
	push bc
	ld a,c
	vdu_a

	; store coordinates for a palette square
	ld ix,x1
	pop hl
	push hl
	ld h,20
	mlt hl
	push hl
	ld (ix+0),l
	ld (ix+1),h

	ld ix,y1
	ld hl,984
	ld (ix+0),l
	ld (ix+1),h

	ld ix,x2
	pop hl
	ld de,19
	add hl,de
	ld (ix+0),l
	ld (ix+1),h

	ld ix,y2
	ld hl,1019
	ld (ix+0),l
	ld (ix+1),h
	
	; draw the palette filled square
	call fn_rectf

	pop bc
	
	ret

; return the keyascii of the key pressed
; returns:
; A: keycode
; L: keydown
; h: keymods
fn_wait_key:
	moscall mos_sysvars
	
	ld iy,keydata
	ld a,(ix+sysvar_vkeydown)
	ld (iy+1),a
	ld l,a
	ld a,(ix+sysvar_keymods)
	ld (iy+2),a
	ld h,a
	ld a,(ix+sysvar_vkeycode)
	ld (iy+0),a
	ret

; wait a key to be released
fn_wait_key_released:
	moscall mos_sysvars
	
	ld a,(ix+sysvar_vkeydown)
	cp 0
	jr nz,fn_wait_key_released
	ret

; get an ascii key value
fn_input_key:
	push bc
	moscall mos_getkey
	pop bc
	ret
	
; input a text of 8 chars
fn_input_text8:
	; locate x,y
	vdu 31
	vdu FILENAME_X
	vdu FILENAME_Y

	; print text
	ld hl,filename_label
	ld bc,0
	xor a
	rst.lis $18
	
	; show cursor
	vdu 23
	vdu 1
	vdu 1
	
	ld c,0

it8_loop:
	; get ascii key
	call fn_input_key
	or a
	jp z,it8_loop

	cp '.'
	jp z,it8l_add_char

	cp '-'
	jp z,it8l_add_char

	cp '_'
	jp z,it8l_add_char

	cp 127
	jp z,it8l_backspace
	
	cp 13
	jp z,it8l_return
	
	cp '0'
	jp c,it8_loop

	ld d,'9'
	inc d
	cp d
	jp c,it8l_add_char

	cp 'A'
	jp c,it8_loop

	ld d,'Z'
	inc d
	cp d
	jp c,it8l_add_char

	cp 'a'
	jp c,it8_loop

	ld d,'z'
	inc d
	cp d
	jp c,it8l_add_char
	
	jp it8_loop

it8l_add_char:
	push af
	ld a,c
	cp 12
	jr c,it8l_poke_char
	pop af
	jp it8_loop

it8l_poke_char:
	pop af
	ld hl,filename
	ld b,0
	add hl,bc
	ld (hl),a
	inc c
	push af
	push bc

	; locate x,y
	vdu 31
	vdu FILENAME_X+10
	vdu FILENAME_Y

	; print text
	ld hl,filename
	ld bc,0
	xor a
	rst.lis $18
	
	pop bc
	pop af
	
	jp it8_loop
	
it8l_backspace:
	ld a,c
	cp 0
	jp z,it8_loop
	
	; delete a character of the filename
	ld hl,filename
	ld b,0
	add hl,bc
	xor a
	ld (hl),a
	dec c
	push bc

	; locate x,y
	vdu 31
	ld a,FILENAME_X+10
	add a,c
	vdu_a
	vdu FILENAME_Y

	; print text
	ld hl,spacechar
	ld bc,0
	xor a
	rst.lis $18

	pop bc
	jp it8_loop

it8l_return:
	; locate x,y
	vdu 31
	vdu FILENAME_X
	vdu FILENAME_Y

	; print text
	ld hl,void_filename
	ld bc,0
	xor a
	rst.lis $18

	; hide cursor
	vdu 23
	vdu 1
	vdu 0

	ret

; load a sprite, giving its name (must be on spredit folder)
fn_load_sprite:
	; clear filename
	ld hl,filename
	ld b,12
	xor a

ls_clear_filename:
	ld (hl),a
	inc hl
	djnz ls_clear_filename
	
	; get filename
	call fn_input_text8
	
	; set path to home
	ld hl,home_path
	moscall mos_cd

	; exit on error
	cp 0
	jp nz,ls_folder_error
	
	; open the file for read
	ld hl,filename
	ld c,fa_open_existing|fa_read
	moscall mos_fopen
	
	; exit on error
	cp 0
	jp z,ls_file_error

	; filehandle -> C
	ld c,a
	
	; get colors count
	moscall mos_fgetc
	jp c,ls_close_error
	
	cp MAX_COLORS
	jp nz,ls_close_error

	; store colors count
	ld hl,colors_count
	ld (hl),a

	; get frames count
	moscall mos_fgetc
	jp c,ls_close_error

	; store frames count
	ld hl,frames_count
	ld (hl),a
	ld hl,current_frame
	dec a
	ld (hl),a

	; get sprite size
	moscall mos_fgetc
	jp c,ls_close_error

	; store sprite size
	ld hl,spr_size
	ld (hl),a
	
	; set 8x8 pixel width
	cp SPR88
	jr nz,ls_next1

	ld hl,pixel_width
	ld b,SPR88_width
	ld (hl),b
	jr ls_next3

ls_next1:

	; set 16x16 pixel width
	cp SPR1616
	jr nz,ls_next2

	ld hl,pixel_width
	ld b,SPR1616_width
	ld (hl),b
	jr ls_next3
	
ls_next2:

	ld hl,pixel_width
	ld b,SPR3232_width
	ld (hl),b
	
ls_next3:

	ld l,a
	ld h,a
	mlt hl ; HL = sprite length
	push hl
	
	; get frames count
	ld hl,current_frame
	ld b,(hl)

	pop hl
	
	ld a,b
	cp 0
	jr z,ls_read_data	

	; de = size²
	ld de,ONE_FRAME_BUFFER_SIZE
ls_add_length:
	add hl,de
	djnz ls_add_length

ls_read_data:
	push hl
	push hl
	pop de
	ld a,e
	ld hl,sprite_buffer
	moscall mos_fread
	pop hl
	ld a,h
	cp d
	jr nz,ls_close_error
	ld a,l
	cp e
	jr nz,ls_close_error
	jp ls_close

ls_close_error:
	push bc
	
	; read error
	call fn_print_file_error
	
	pop bc

	; close the file
	moscall mos_fclose
	
	; reset current frame and coordinates of the drawing pixel
	ld hl,frames_count
	ld a,(hl)
	dec a
	ld hl,current_frame
	ld (hl),a
	ld hl,xpix
	xor a
	ld (hl),a
	ld hl,ypix
	ld (hl),a
	jr ls_exit

ls_folder_error:
	; write error
	call fn_print_folder_error
	jp ls_exit
	
ls_close:
	; close the file
	moscall mos_fclose

	; reset current frame and coordinates of the drawing pixel
	ld hl,frames_count
	ld a,(hl)
	dec a
	ld hl,current_frame
	ld (hl),a
	ld hl,xpix
	xor a
	ld (hl),a
	ld hl,ypix
	ld (hl),a

ls_exit:
	call fn_change_frames_count
	ret

ls_file_error:
	call fn_print_file_error
	ret

; save a sprite, giving its name (must be on spredit folder)
fn_save_sprite:
	; clear filename
	ld hl,filename
	ld b,12
	xor a

ss_clear_filename:
	ld (hl),a
	inc hl
	djnz ss_clear_filename

	; get filename
	call fn_input_text8

	; set path to home
	ld hl,home_path
	moscall mos_cd

	; exit on error
	cp 0
	jp nz,ss_folder_error
	
	; open the file for write
	ld hl,filename
	ld c,fa_create_new|fa_write
	moscall mos_fopen
		
	; exit on error
	cp 0
	jp z,ss_file_error

	; filehandle -> C
	ld c,a
	
	; store colors count in the file
	ld b,MAX_COLORS
	moscall mos_fputc
	
	; store frames count in the file
	ld hl,frames_count
	ld b,(hl)
	moscall mos_fputc

	; store sprite size in the file
	ld hl,spr_size
	ld b,(hl)
	moscall mos_fputc

	; de = size²
	ld l,b
	ld h,b
	mlt hl ; HL = sprite length
	push hl

	; get frames count
	ld hl,current_frame
	ld b,(hl)
	
	pop hl
		
	ld a,b
	cp 0
	jr z,ss_write_data

	ld de,ONE_FRAME_BUFFER_SIZE
ss_add_length:
	add hl,de
	djnz ss_add_length

ss_write_data:
	push hl
	push hl
	pop de
	ld hl,sprite_buffer
	moscall mos_fwrite
	pop hl
	ld a,h
	cp d
	jr nz,ss_close_error
	ld a,l
	cp e
	jr nz,ss_close_error
	jp ss_close

ss_close_error:
	push bc
	
	; write error
	call fn_print_file_error
	
	pop bc

	; close the file
	moscall mos_fclose
	
	; reset current frame and coordinates of the drawing pixel
	ld hl,frames_count
	ld a,(hl)
	dec a
	ld hl,current_frame
	ld (hl),a
	ld hl,xpix
	xor a
	ld (hl),a
	ld hl,ypix
	ld (hl),a
	jr ss_exit

ss_folder_error:
	; write error
	call fn_print_folder_error
	jp ss_exit
	
ss_close:
	; close the file
	moscall mos_fclose

	; reset current frame and coordinates of the drawing pixel
	ld hl,frames_count
	ld a,(hl)
	dec a
	ld hl,current_frame
	ld (hl),a
	ld hl,xpix
	xor a
	ld (hl),a
	ld hl,ypix
	ld (hl),a

ss_exit:
	ret

ss_file_error:
	call fn_print_file_error
	ret

; print 'file error'
fn_print_file_error:
	; locate x,y
	vdu 31
	vdu FILENAME_X
	vdu FILENAME_Y

	; print text
	ld hl,file_error
	ld bc,0
	xor a
	rst.lis $18

pfe_loop:
	call fn_wait_key
	cp 0
	jr z, pfe_loop

	; locate x,y
	vdu 31
	vdu FILENAME_X
	vdu FILENAME_Y

	; print text
	ld hl,void_filename
	ld bc,0
	xor a
	rst.lis $18

	ret

; print 'folder error'
fn_print_folder_error:
	; locate x,y
	vdu 31
	vdu FILENAME_X
	vdu FILENAME_Y

	; print text
	ld hl,folder_error
	ld bc,0
	xor a
	rst.lis $18

pfre_loop:
	call fn_wait_key
	cp 0
	jr z, pfre_loop

	; locate x,y
	vdu 31
	vdu FILENAME_X
	vdu FILENAME_Y

	; print text
	ld hl,void_filename
	ld bc,0
	xor a
	rst.lis $18

	ret

; refresh all the current sprite frame
fn_refresh_sprite:
	ld b,0 ; B -> x cordinate
	ld c,0 ; C -> y cordinate
	
rs_loop:
	push bc

	ld hl,xpix
	ld (hl),b
	ld hl,ypix
	ld (hl),c
	call fn_draw_pixel_without_border

	pop bc

	inc b
	ld hl,spr_size
	ld a,(hl)
	cp b
	jr z,rs_next_line	
	jp rs_loop
	
rs_next_line:
	ld b,0
	inc c
	ld hl,spr_size
	ld a,(hl)
	cp c
	jr z,rs_end
	jp rs_loop

rs_end:
	xor a
	ld hl,xpix
	ld (hl),a
	ld hl,ypix
	ld (hl),a
	call fn_draw_pixel_with_border

	ret

fn_change_frame:
	ld hl,current_frame
	ld a,(hl)
	add a,49
	ld hl,current_frame_ascii
	ld (hl),a
	
	; locate 21,4
	vdu 31
	vdu 21
	vdu 4

	; print text
	ld hl,current_frame_ascii
	ld bc,0
	xor a
	rst.lis $18
	
	ret

fn_change_frames_count:
	ld hl,frames_count
	ld a,(hl)
	add a,48
	ld hl,frames_count_ascii
	ld (hl),a
	
	; locate 23,4
	vdu 31
	vdu 23
	vdu 4

	; print text
	ld hl,frames_count_ascii
	ld bc,0
	xor a
	rst.lis $18
	
	ret

; slowdown (wait delay)
fn_slowdown:
	ld ix,keydata
	ld a,(ix+2)
	and 2
	cp 2 ; shift key to disable delay
	ret z

	moscall mos_sysvars
	ld c,(ix+sysvar_time)

sd_loop:
	moscall mos_sysvars
	ld a,(ix+sysvar_time)
	sub c
	cp SLOWDOWN_DELAY
	jr nz,sd_loop
	ret
;======================================================================

; coordinates for rectangles
x1:
	dw $0000
y1:
	dw $0000
x2:
	dw $0000
y2:
	dw $0000

; coordinates of the edited sprite
xs1:
	dw 382
ys1:
	dw 254
xs2:
	dw 896
ys2:
	dw 768

; coordinates of active pixels to draw
xpix:
	db 0
ypix:
	db 0

; width of a pixel in the sprite
pixel_width:
	db 0

; sprite size, in resized pixels
spr_size:
	db 0

; pen color (0-63)
current_pen:
	db 0

; texts for 1st menu
title:
	db "SPR-EDIT",0

menu1:
	db "1) 4x4 Sprite",0
menu2:
	db "2) 8x8 Sprite",0
menu3:
	db "3) 16x16 Sprite",0
menu4:
	db "4) 32x32 Sprite",0

; descriptions of sprites
spr_descr:
	db "Frame:1/1",0
spr_descr1:
	db "4x4  ",0
spr_descr2:
	db "8x8  ",0
spr_descr3:
	db "16x16",0
spr_descr4:
	db "32x32",0

; label before filename
filename_label:
	db "Filename:",0

; filename without extension
filename:
	ds 13,0
	
home_path:
	db "/home",0

; single space char to print
spacechar:
	db " ",0

; spaces to remove filename label
void_filename:
	db "                      ",0

; file error message
file_error:
	db "File error !          ",0

; folder error message
folder_error:
	db "Folder error !        ",0

; number of colors
colors_count:
	db 0

; current frame
current_frame:
	db 0

; frames count
frames_count:
	db 0

current_frame_ascii:
	db '0',0
	
frames_count_ascii:
	db '0',0

; keycode, keydown & keymods are stored here
keydata:
	db 0,0,0

; buffer for the current sprite
sprite_buffer:
	ds BUFFER_SIZE,0

rgb_palette:
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

; sprite structure:
; =================
; colors_count  :   byte
; frames count	:	byte
; spr size		:	byte
; data			:   width x height bytes of colors


; TODO:
;---------
; add/remove frames must be done correctly
; read animations with 'p' key
; create a help text file with keyboard shorcuts list
; solve the 'copy frame' bug
; solve the bug of frames in fn_load/save sprite
