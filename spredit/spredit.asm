; spredit.asm
;
; by B.Vignoli
; MIT 2023
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

SPR44_width: 	equ 32
SPR88_width: 	equ 16
SPR1616_width: 	equ 8
SPR3232_width: 	equ 4

BUFFER_SIZE:			equ 8192 ; 8 frames
ONE_FRAME_BUFFER_SIZE:	equ 1024

SLOWDOWN_DELAY:	equ 20

KEY_SPACE: equ -99
KEY_UP: equ -58
KEY_DOWN: equ -42
KEY_LEFT: equ -26
KEY_RIGHT: equ -122
KEY_DELETE: equ -90
KEY_TAB: equ -97
KEY_N: equ -86
KEY_C: equ -83
KEY_BACKSPACE: equ -48
KEY_PGUP: equ -64
KEY_PGDOWN: equ -79
KEY_L: equ -87
KEY_S: equ -82
KEY_E: equ -35
KEY_R: equ -52
KEY_F: equ -68
KEY_M: equ -102
KEY_ESCAPE: equ -113
KEY_F1: equ -114
KEY_F2: equ -115
KEY_F3: equ -116
KEY_F4: equ -21
KEY_RETURN: equ -74

BITLOOKUP:
	DB 01h,02h,04h,08h
	DB 10h,20h,40h,80h

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
	
	; disable logical scale coordinates system
	vdu 23
	vdu 0
	vdu $c0
	vdu 0
	
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
	ld hl,319
	ld (ix+0),l
	ld (ix+1),h

	ld ix,y2
	ld hl,239
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

; menu loop
menu_loop:
	ld hl,KEY_ESCAPE
	call fn_inkey
	CP 1
	jp z,exit_program

	ld hl,KEY_F1
	call fn_inkey
	CP 1
	jp z,ml_menu1

	ld hl,KEY_F2
	call fn_inkey
	CP 1
	jp z,ml_menu2

	ld hl,KEY_F3
	call fn_inkey
	CP 1
	jp z,ml_menu3

	ld hl,KEY_F4
	call fn_inkey
	CP 1
	jp z,ml_menu4
	
	jp menu_loop

ml_menu1:	
	ld a,SPR44
	ld d,SPR44_width
	jr exit_menu_loop

ml_menu2:	
	ld a,SPR88
	ld d,SPR88_width
	jr exit_menu_loop

ml_menu3:
	ld a,SPR1616
	ld d,SPR1616_width
	jr exit_menu_loop

ml_menu4:
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
	ld h,5
	mlt hl
	push hl
	ld (ix+0),l
	ld (ix+1),h

	ld ix,y1
	ld hl,0
	ld (ix+0),l
	ld (ix+1),h

	ld ix,x2
	pop hl
	ld de,4
	add hl,de
	ld (ix+0),l
	ld (ix+1),h

	ld ix,y2
	ld hl,10
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
	ld hl,11
	ld (ix+0),l
	ld (ix+1),h

	ld ix,x2
	ld hl,319
	ld (ix+0),l
	ld (ix+1),h

	ld ix,y2
	ld hl,239
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

	; update sprite size descriptions
	call fn_show_spr_descr
	
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

; draw sprite loop	
draw_sprite_loop:
	ld hl,KEY_SPACE
	call fn_inkey
	cp 1
	call z,dsl_set_pen

	ld hl,KEY_UP
	call fn_inkey
	cp 1
	call z,dsl_up

	ld hl,KEY_DOWN
	call fn_inkey
	cp 1
	call z,dsl_down

	ld hl,KEY_LEFT
	call fn_inkey
	cp 1
	call z,dsl_left

	ld hl,KEY_RIGHT
	call fn_inkey
	cp 1
	call z,dsl_right
	
	ld hl,KEY_DELETE
	call fn_inkey
	cp 1
	call z,dsl_reset_pen

	ld hl,KEY_TAB
	call fn_inkey
	cp 1
	jp z,dsl_palette_tool

	ld hl,KEY_N
	call fn_inkey
	cp 1
	call z,dsl_add_frame

	ld hl,KEY_C
	call fn_inkey
	cp 1
	call z,dsl_add_and_copy_frame

	ld hl,KEY_BACKSPACE
	call fn_inkey
	cp 1
	call z,dsl_delete_frame
	
	ld hl,KEY_PGUP
	call fn_inkey
	cp 1
	call z,dsl_next_frame

	ld hl,KEY_PGDOWN
	call fn_inkey
	cp 1
	call z,dsl_previous_frame

	ld hl,KEY_L
	call fn_inkey
	cp 1
	call z,dsl_load_sprite

	ld hl,KEY_S
	call fn_inkey
	cp 1
	call z,dsl_save_sprite

	ld hl,KEY_E
	call fn_inkey
	cp 1
	call z,dsl_export_sprite

	ld hl,KEY_R
	call fn_inkey
	cp 1
	call z,dsl_rotate_frame

	ld hl,KEY_F
	call fn_inkey
	cp 1
	call z,dsl_flip_frame

	ld hl,KEY_M
	call fn_inkey
	cp 1
	call z,dsl_mirror_frame

	ld hl,KEY_RETURN
	call fn_inkey
	cp 1
	call z,dsl_flood_fill

	ld hl,KEY_ESCAPE
	call fn_inkey
	cp 1
	jp z,exit_program

	jp draw_sprite_loop

; set the pen of the current pixel
dsl_set_pen:
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
	ret z
	xor a
	call fn_set_pixel_color
	call fn_draw_pixel_with_border
	ret

; move pixel up
dsl_up:
	ld hl,ypix
	ld a,(hl)
	cp 0
	ret z

	ld hl,KEY_SPACE
	call fn_inkey
	cp 1
	call z,dsl_set_pen
	
	call fn_draw_pixel_without_border
	call fn_move_up
	call fn_draw_pixel_with_border
	call fn_slowdown
	ret

; move pixel down
dsl_down:
	ld hl,spr_size
	ld d,(hl)
	dec d

	ld hl,ypix
	ld a,(hl)
	cp d
	ret z

	ld hl,KEY_SPACE
	call fn_inkey
	cp 1
	call z,dsl_set_pen

	call fn_draw_pixel_without_border
	call fn_move_down
	call fn_draw_pixel_with_border
	call fn_slowdown
	ret

; move pixel left
dsl_left:
	ld hl,xpix
	ld a,(hl)
	cp 0
	ret z

	ld hl,KEY_SPACE
	call fn_inkey
	cp 1
	call z,dsl_set_pen

	call fn_draw_pixel_without_border
	call fn_move_left
	call fn_draw_pixel_with_border
	call fn_slowdown
	ret
		
; move pixel right
dsl_right:
	ld hl,spr_size
	ld d,(hl)
	dec d

	ld hl,xpix
	ld a,(hl)
	cp d
	ret z

	ld hl,KEY_SPACE
	call fn_inkey
	cp 1
	call z,dsl_set_pen
	
	call fn_draw_pixel_without_border
	call fn_move_right
	call fn_draw_pixel_with_border
	call fn_slowdown
	ret

; load a sprite
dsl_load_sprite:
	ld hl,KEY_L
	call fn_inkey
	cp 0
	jr nz,dsl_load_sprite

	call fn_draw_pixel_without_border
	call fn_load_sprite
	call fn_refresh_sprite
	call fn_draw_pixel_with_border
	call fn_change_frame
	ret

; save a sprite
dsl_save_sprite:
	ld hl,KEY_S
	call fn_inkey
	cp 0
	jr nz,dsl_save_sprite
	
	call fn_draw_pixel_without_border
	call fn_save_sprite
	call fn_refresh_sprite
	ret

dsl_export_sprite:
	ld hl,KEY_E
	call fn_inkey
	cp 0
	jr nz,dsl_export_sprite
	
	call fn_draw_pixel_without_border
	call fn_export_sprite
	call fn_refresh_sprite
	ret
	

; add a frame to the animation
dsl_add_frame:
	ld hl,KEY_N
	call fn_inkey
	cp 0
	jr nz,dsl_add_frame
	
	; frames limit reached ? exit
	ld hl,frames_count
	ld a,(hl)
	cp MAX_FRAMES
	ret z
	
	; get the number of frames to copy
	ld hl,frames_count
	ld a,(hl)
	ld hl,current_frame
	ld b,(hl)
	sub b
	dec a
	
	; get sprsize² (length of a sprite, in bytes)
	ld hl,spr_size
	ld de,$000000
	ld e,(hl)
	ld d,(hl)
	mlt de ; DE = sprsize²
	
	; prepare for the case we goto af_zap...
	ld hl,sprite_buffer

	push af
	push hl
	ld hl,current_frame
	ld a,(hl)
	inc a
	ld b,a
	pop hl
	pop af
	
af_loop0:	
	add hl,de ; for if current frame = 0 (prepare to zap!)
	djnz af_loop0
	
	push hl ; store HL = sprite buffer + sprsize²
	cp 0
	jp z,af_zap ; zap the copy, if the 'current frame' is at the last frame
	pop hl ; HL unused in this case

	ld hl,$000000 ; HL is 0 to store the result
	ld b,a ; B = frames to copy

; multiply number of frames to copy by sprsize²
af_loop1:
	add hl,de ; HL = length (in bytes) to copy (a few frames)
	djnz af_loop1
	
	push hl
	pop bc ; BC = HL = length (in bytes) to copy (a few frames)
	
	ld hl,current_frame
	ld a,(hl)
	inc a
	ld hl,sprite_buffer
	
	push bc
	ld b,a

af_loop2:
	add hl,de ; HL = sprite buffer + length to copy
	djnz af_loop2
	
	pop bc
	
	push hl ; HL = sprite_buffer + (current frame * sprsize²)
	
	add hl,bc
	dec hl ; HL = end address to copy to end target address
	
	push hl
	add hl,de
	ex de,hl ; DE = end target address
	pop hl

	lddr

af_zap:
	; multiply number of frames to copy by sprsize²
	ld hl,spr_size
	ld bc,$000000
	ld c,(hl)
	ld b,(hl)
	mlt bc ; BC = sprsize²

	pop hl ; HL = sprite_buffer + (current frame * sprsize²)
	
; fill frame with 0 color
af_loop3:
	xor a
	ld (hl),a
	inc hl
	dec bc
	ld a,b
	or c
	cp 0
	jr nz,af_loop3	

	; increment the frames count and the current frame values
	ld hl,frames_count
	inc (hl)
	ld hl,current_frame
	inc (hl)

	call fn_change_frame
	call fn_change_frames_count
	call fn_refresh_sprite
	ret

; add a copy of the current frame to the animation
dsl_add_and_copy_frame: ; TODO! debug me!
	ld hl,KEY_C
	call fn_inkey
	cp 0
	jr nz,dsl_add_and_copy_frame
	
	; frames limit reached ? exit
	ld hl,frames_count
	ld a,(hl)
	cp MAX_FRAMES
	ret z
	
	; get the number of frames to copy
	ld hl,frames_count
	ld a,(hl)
	ld hl,current_frame
	ld b,(hl)
	sub b
	
	; get sprsize² (length of a sprite, in bytes)
	ld hl,spr_size
	ld de,$000000
	ld e,(hl)
	ld d,(hl)
	mlt de ; DE = sprsize²

	ld hl,$000000 ; HL is 0 to store the result
	ld b,a ; B = frames to copy

; multiply number of frames to copy by sprsize²
aacf_loop1:
	add hl,de ; HL = length (in bytes) to copy (a few frames)
	djnz aacf_loop1
	
	push hl
	pop bc ; BC = HL = length (in bytes) to copy (a few frames)
	
	ld hl,current_frame
	ld a,(hl)
	ld hl,sprite_buffer
	cp 0
	jr z,aacf_loop_end2
	
	push bc
	ld b,a

aacf_loop2:
	add hl,de ; HL = sprite buffer + length to copy
	djnz aacf_loop2
	
	pop bc

aacf_loop_end2:
	add hl,bc
	dec hl ; HL = end address to copy to end target address
	
	push hl
	add hl,de
	ex de,hl ; DE = end target address
	pop hl

	lddr

	; increment the frames count and the current frame values
	ld hl,frames_count
	inc (hl)
	ld hl,current_frame
	inc (hl)

	call fn_change_frame
	call fn_change_frames_count
	call fn_refresh_sprite
	ret

; delete last frame from animation
dsl_delete_frame:
	ld hl,KEY_BACKSPACE
	call fn_inkey
	cp 0
	jr nz,dsl_delete_frame
	
	; delete current selected frame
	ld hl,spr_size
	ld bc,$000000
	ld c,(hl)
	ld b,(hl)
	mlt bc ; BC = sprsize²
	ld hl,current_frame
	ld a,(hl) ; A = current frame
	ld hl,sprite_buffer ; HL = sprite buffer
	push bc
	cp 0
	jr z,df_loop2

df_loop1:
	add hl,bc ; HL = sprite buffer + (current frame * sprsize²)
	dec a
	cp 0
	jr nz,df_loop1

; clear the current frame
df_loop2:
	xor a
	ld (hl),a
	inc hl
	dec bc
	ld a,b
	or c
	cp 0
	jr nz,df_loop2
	
	; current frame + 1 = frames count ?
	push hl
	ld hl,current_frame
	ld e,(hl)
	inc e
	ld hl,frames_count
	ld a,(hl)
	cp e
	pop hl
	pop bc
	jp z,df_exit

	ld de,frames_count
	ld a,(de) ; A = frames count
	push hl
	ld hl,current_frame
	ld e,(hl) ; E = current frame
	pop hl
	sub e
	dec a ; A = number of frames to copy back
	
	ex de,hl ; DE = sprite buffer + ((current frame + 1) * sprsize²)
	ld hl,$000000
	cp 0 ; 0 frames to copy ?
	jr z,df_exit_loop3

df_loop3:
	add hl,bc ; HL = length of a frame (sprsize²) * frames count
	dec a
	cp 0
	jr nz,df_loop3

df_exit_loop3:
	push hl
	pop bc ; BC = total length of area to copy
	push de
	pop hl ; HL = DE = start of area to copy
	
	push bc
	push de
	push hl
	ld hl,spr_size
	ld de,$000000
	ld e,(hl)
	ld d,(hl)
	mlt de ; DE = one sprite frame length
	pop hl
	or a
	sbc hl,de ; HL = target area to copy
	pop de
	ex de,hl ; DE = target, HL = start
	pop bc
	ldir

	ld hl,spr_size
	ld bc,$000000
	ld c,(hl)
	ld b,(hl)
	mlt bc ; DE = one sprite frame length
	
	; delete last frame data
	ld hl,frames_count
	ld a,(hl) ; A =frames count
	dec a ; A = last frame
	ld hl,sprite_buffer ; HL = sprite buffer
	cp 0
	jr z,df_loop5

df_loop4:
	add hl,bc ; HL = sprite buffer + (last frame * sprsize²)
	dec a
	cp 0
	jr nz,df_loop4

; clear the current frame
df_loop5:
	xor a
	ld (hl),a
	inc hl
	dec bc
	ld a,b
	or c
	cp 0
	jr nz,df_loop5

	; decrement frames count
	ld hl,frames_count
	dec (hl)
	
	call fn_change_frame
	call fn_change_frames_count
	call fn_refresh_sprite
	ret

df_exit:
	ld hl,frames_count
	ld a,(hl)
	cp 1
	jr z,df_exit_end
	dec (hl)
	ld hl,current_frame
	dec (hl)

df_exit_end:
	call fn_change_frame
	call fn_change_frames_count
	call fn_refresh_sprite
	ret

; goto previous frame
dsl_previous_frame:
	ld hl,KEY_PGDOWN
	call fn_inkey
	cp 0
	jr nz,dsl_previous_frame

	ld hl,current_frame
	ld a,(hl)
	cp 0
	ret z
	
	dec a
	ld (hl),a
	call fn_change_frame
	call fn_refresh_sprite
	ret

; goto next frame
dsl_next_frame:
	ld hl,KEY_PGUP
	call fn_inkey
	cp 0
	jr nz,dsl_next_frame

	ld hl,current_frame
	ld a,(hl)
	inc a
	ld hl,frames_count
	cp (hl)
	ret z

	ld hl,current_frame
	ld (hl),a
	call fn_change_frame
	call fn_refresh_sprite
	ret

; rotate a frame 90° clockwise
dsl_rotate_frame:
	ld hl,KEY_R
	call fn_inkey
	cp 0
	jr nz,dsl_rotate_frame

	; find HL as start of the first frame (buffer)
	ld hl,spr_size
	ld bc,$000000
	ld de,$000000
	ld e,(hl)
	ld d,(hl)
	ld c,e
	mlt de ; DE = sprite length in bytes
	ld hl,current_frame
	ld a,(hl) ; A = current frame
	ld hl,sprite_buffer
	cp 0
	jr z,rf_noloop1
	ld b,a
	
rf_loop1:
	add hl,de ; HL = sprite_buffer + (current frame * sprsize²)
	djnz rf_loop1
	
rf_noloop1:
	push bc
	push hl
	
	; copy current frame to swap sprite buffer
	ld de,swap_sprite_buffer
	ld b,c
	mlt bc
	ldir

	pop iy ; IY: destination
	pop bc
	
	ld a,c
	ld bc,$000000
	ld c,a ; BC = sprite size

	; turn and copy swap sprite buffer frame to sprite buffer
	ld ix,swap_sprite_buffer ; IX: source
	ld de,0 ; x
	ld hl,0 ; y

rf_loop2:
	push ix
	push iy
	
	push de
	push hl

	; add x
	add ix,de

	; add y * width
	ld a,h
	or l
	cp 0
	jr z,rf_done1
rf_loop3:
	add ix,bc
	dec hl
	ld a,h
	or l
	cp 0
	jr nz,rf_loop3

rf_done1:
	; found the pixel value
	ld a,(ix+0)
	
	pop hl
	pop de
	push de
	push hl
	
	; add y
	ex de,hl
	add iy,bc
	or a
	push hl
	push iy
	pop hl
	sbc hl,de
	push hl
	pop iy
	dec iy
	pop hl
	ex de,hl

	; add x * width
	push af
	ld a,d
	or e
	cp 0
	jr z,rf_done2
rf_loop5:
	add iy,bc
	dec de
	ld a,d
	or e
	cp 0
	jr nz,rf_loop5

rf_done2:
	pop af

	; store the pixel value
	ld (iy+0),a
	
	pop hl
	pop de
	
	pop iy
	pop ix
	
	inc de
	ex de,hl
	or a
	sbc hl,bc
	add hl,bc
	ex de,hl
	jp c,rf_loop2

	ld de,0
	inc hl
	or a
	sbc hl,bc
	add hl,bc
	jp c,rf_loop2
	
	call fn_refresh_sprite
	ret

; flip frame horizontally
dsl_flip_frame:
	ld hl,KEY_F
	call fn_inkey
	cp 0
	jr nz,dsl_flip_frame

	ld hl,spr_size
	ld de,$000000
	ld e,(hl)
	ld d,(hl)
	ld c,e
	mlt de ; DE = sprite length in bytes
	ld hl,current_frame
	ld a,(hl) ; A = current frame
	ld hl,sprite_buffer
	cp 0
	jr z,ff_noloop1
	ld b,a
	
ff_loop1:
	add hl,de ; HL = sprite_buffer + (current frame * sprsize²)
	djnz ff_loop1
	
ff_noloop1:
	ld b,c ; B = sprite height
	ld de,$000000
	ld e,c ; DE = sprite width
	ld a,c ; A = sprite width
	srl a ; A = sprite height / 2

	push hl
	pop ix ; IX = frame address
	add hl,de ; HL = frame address + sprite width - 1
	dec hl
	push hl
	pop iy ; IY = IX + sprite width - 1
	
ff_loop2:
	push af
	push de
	push ix
	push iy
ff_loop3:
	ld e,(ix+0)
	ld d,(iy+0)
	ld (ix+0),d
	ld (iy+0),e
	inc ix
	dec iy
	dec a
	cp 0
	jr nz,ff_loop3
	pop iy
	pop ix
	pop de
	pop af
	add ix,de
	add iy,de
	djnz ff_loop2

	call fn_refresh_sprite
	ret

; mirror frame vertically
dsl_mirror_frame:
	ld hl,KEY_M
	call fn_inkey
	cp 0
	jr nz,dsl_mirror_frame

	ld hl,spr_size
	ld bc,$000000
	ld de,$000000
	ld e,(hl)
	ld d,(hl)
	ld c,e
	mlt de ; DE = sprite length in bytes
	ld hl,current_frame
	ld a,(hl) ; A = current frame
	ld hl,sprite_buffer
	cp 0
	jr z,mf_noloop1
	ld b,a
	
mf_loop1:
	add hl,de ; HL = sprite_buffer + (current frame * sprsize²)
	djnz mf_loop1
	
mf_noloop1:
	ld de,$000000
	ld e,c ; E = sprite height
	ld a,c ; A = sprite width
	ld b,c ; B = sprite height
	srl b ; divide B by 2, so B = sprite height / 2
	
	push hl
	pop ix ; IX = frame address
	ld d,c
	dec d
	mlt de ; DE = sprite length - sprite width
	add hl,de ; HL = frame address + sprite length - sprite width
	push hl
	pop iy ; IY = IX + sprite length - sprite width
	ld hl,$000000
	ld l,c ; HL = sprite width
	
mf_loop2:
	push af
	push de
	push ix
	push iy
mf_loop3:
	ld e,(ix+0)
	ld d,(iy+0)
	ld (ix+0),d
	ld (iy+0),e
	inc ix
	inc iy
	dec a
	cp 0
	jr nz,mf_loop3
	pop iy
	pop ix
	pop de
	pop af
	ex de,hl
	add ix,de
	ex de,hl
	push hl
	push iy
	pop hl
	pop de
	or a
	sbc hl,de
	push hl
	push de
	pop hl
	pop iy
	djnz mf_loop2
	
	call fn_refresh_sprite
	ret

dsl_flood_fill:
	ld hl,KEY_RETURN
	call fn_inkey
	cp 0
	jr nz,dsl_flood_fill
	
	; hide the cursor
	call fn_draw_pixel_without_border

	; memorize pixel coordinates
	ld a,(xpix)
	ld (memxpix),a
	ld a,(ypix)
	ld (memypix),a

	; fill all recursively
	ld a,(xpix)
	ld e,a
	ld a,(ypix)
	ld d,a
	call dsl_flood_fill_loop

	; refresh all the sprite
	call fn_refresh_sprite

	; hide the cursor again
	call fn_draw_pixel_without_border
	
	; restore pixel coordinates
	; and cursor
	ld a,(memxpix)
	ld (xpix),a
	ld a,(memypix)
	ld (ypix),a
	call fn_draw_pixel_with_border
	ret

dsl_flood_fill_loop:
	push de
	
	ld ix,spr_size
	
	; out  of the sprite area ?
	ld a,e
	cp (ix+0)
	jp nc,ffl_exit

	; out  of the sprite area ?
	ld a,d
	cp (ix+0)
	jp nc,ffl_exit
	
	; replace current pixel, if it is
	; inside the sprite area,
	; and has not the select palette color
	ld a,e
	ld (xpix),a
	ld a,d
	ld (ypix),a
	call fn_get_pixel_color
	ld hl,current_pen
	cp (hl)
	jp z,ffl_exit
	ld a,(hl)
	call fn_set_pixel_color

	; restore coordinates
	ld a,(xpix)
	ld e,a
	ld a,(ypix)
	ld d,a
	
	; draw pixel at right
	inc e
	call dsl_flood_fill_loop
	dec e
	; draw pixel at left
	dec e
	call dsl_flood_fill_loop
	inc e
	; draw pixel up
	inc d
	call dsl_flood_fill_loop
	dec d
	; draw pixel down
	dec d
	call dsl_flood_fill_loop

ffl_exit:
	pop de
	ret

; change current tool to palette
dsl_palette_tool:
	ld hl,KEY_TAB
	call fn_inkey
	cp 0
	jr nz,dsl_palette_tool

	; hide sprite drawing cursor
	call fn_draw_pixel_without_border
	
	; draw selected palette color
	ld hl,current_pen
	ld c,(hl)
	call fn_draw_palette_with_border
	
; select palette color	
dsl_palette_tool_loop:
	ld hl,KEY_LEFT
	call fn_inkey
	cp 1
	call z,dsl_dec_pen
	
	ld hl,KEY_RIGHT
	call fn_inkey
	cp 1
	call z,dsl_inc_pen
	
	ld hl,KEY_TAB
	call fn_inkey
	cp 1
	jp z,dsl_draw_sprite_tool
	
	ld hl,KEY_L
	call fn_inkey
	cp 1
	call z,dslp_load_sprite
	
	ld hl,KEY_S
	call fn_inkey
	cp 1
	call z,dslp_save_sprite

	ld hl,KEY_ESCAPE
	call fn_inkey
	cp 1
	jp z,exit_program
	
	jp dsl_palette_tool_loop

dslp_load_sprite:
	ld hl,KEY_L
	call fn_inkey
	cp 0
	jr nz,dslp_load_sprite

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
	ld hl,KEY_S
	call fn_inkey
	cp 0
	jr nz,dslp_save_sprite

	ld hl,current_pen
	ld c,(hl)
	call fn_draw_palette_without_border
	call fn_save_sprite
	ld hl,current_pen
	ld c,(hl)
	call fn_draw_palette_with_border
	jp dsl_palette_tool_loop

dsl_draw_sprite_tool:
	ld hl,KEY_TAB
	call fn_inkey
	cp 0
	jr nz,dsl_draw_sprite_tool

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
	ld a,(ix + 1)
	vdu_a
	ld iy,y1
	ld a,(iy + 0)
	vdu_a
	ld a,(iy + 1)
	vdu_a

	vdu 25
	vdu 5
	ld ix,x2
	ld a,(ix + 0)
	vdu_a
	ld a,(ix + 1)
	vdu_a
	ld iy,y1
	ld a,(iy + 0)
	vdu_a
	ld a,(iy + 1)
	vdu_a

	vdu 25
	vdu 5
	ld ix,x2
	ld a,(ix + 0)
	vdu_a
	ld a,(ix + 1)
	vdu_a
	ld iy,y2
	ld a,(iy + 0)
	vdu_a
	ld a,(iy + 1)
	vdu_a

	vdu 25
	vdu 5
	ld ix,x1
	ld a,(ix + 0)
	vdu_a
	ld a,(ix + 1)
	vdu_a
	ld iy,y2
	ld a,(iy + 0)
	vdu_a
	ld a,(iy + 1)
	vdu_a

	vdu 25
	vdu 5
	ld ix,x1
	ld a,(ix + 0)
	vdu_a
	ld a,(ix + 1)
	vdu_a
	ld iy,y1
	ld a,(iy + 0)
	vdu_a
	ld a,(iy + 1)
	vdu_a
	
	ret

; draw a filled rectangle
fn_rectf:
	ld ix,x1
	ld iy,y1
	
	vdu 25
	vdu 4
	ld a,(ix+0)
	vdu_a
	ld a,(ix+1)
	vdu_a
	ld a,(iy+0)
	vdu_a
	ld a,(iy+1)
	vdu_a
	
	ld ix,x2
	ld iy,y2

	vdu 25
	vdu 101
	ld a,(ix+0)
	vdu_a
	ld a,(ix+1)
	vdu_a
	ld a,(iy+0)
	vdu_a
	ld a,(iy+1)
	vdu_a

	ret

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
	inc de ; DE = xs1 + 1
	add hl,de ; HL = (xpix * pixel_width) + xs1 + 1
	ld iy,x1
	ld (iy+0),l
	ld (iy+1),h ; x1 = (xpix * pixel_width) + xs1 + 1
	push hl
	ld hl,pixel_width
	ld d,0
	ld e,(hl)
	pop hl
	add hl,de
	dec hl
	ld iy,x2
	ld (iy+0),l
	ld (iy+1),h ; x2 = x1 + pixel_width - 1

	ld de,$000000 ; reset deu

	; calculate coordinates y of the resized pixel
	ld hl,ypix
	ld e,(hl) ; E = ypix
	ld hl,pixel_width
	ld d,(hl) ; D = pixel_width
	push de
	pop hl ; HL = DE
	mlt hl ; HL = ypix * pixel_width
	ld ix,ys1
	ld e,(ix+0)
	ld d,(ix+1) ; ys1 = ypix * pixel_width
	inc de ; DE = ys1 + 1
	add hl,de ; HL = (ypix * pixel_width) + ys1 + 1
	ld iy,y1
	ld (iy+0),l
	ld (iy+1),h ; y1 = (ypix * pixel_width) + ys1 + 1
	push hl
	ld hl,pixel_width
	ld d,0
	ld e,(hl)
	pop hl
	add hl,de
	dec hl
	ld iy,y2
	ld (iy+0),l
	ld (iy+1),h ; y2 = y1 + pixel_width - 1
	
	ret

; draw the resized pixel border, with its color
fn_draw_pixel_with_border:
	call fn_draw_pixel_without_border

	; set graphics pen
	vdu 18
	vdu 0
	vdu COLOR_GREY ; grey pen

	; draw the sprite's border rectangle
	jp fn_rect

; draw the resized pixel color
fn_draw_pixel_without_border:
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
	ld h,5
	mlt hl
	push hl
	ld (ix+0),l
	ld (ix+1),h

	ld ix,y1
	ld hl,0
	ld (ix+0),l
	ld (ix+1),h

	ld ix,x2
	pop hl
	ld de,4
	add hl,de
	ld (ix+0),l
	ld (ix+1),h

	ld ix,y2
	ld hl,10
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
	ld h,5
	mlt hl
	push hl
	ld (ix+0),l
	ld (ix+1),h

	ld ix,y1
	ld hl,0
	ld (ix+0),l
	ld (ix+1),h

	ld ix,x2
	pop hl
	ld de,4
	add hl,de
	ld (ix+0),l
	ld (ix+1),h

	ld ix,y2
	ld hl,10
	ld (ix+0),l
	ld (ix+1),h
	
	; draw the palette filled square
	call fn_rectf

	pop bc
	
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

; load a sprite, giving its name
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
	ld hl,sprite_path
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
	
	; set 4x4 pixel width
	cp SPR44
	jr nz,ls_next1

	ld hl,pixel_width
	ld b,SPR44_width
	ld (hl),b
	jr ls_next4

ls_next1:
	; set 8x8 pixel width
	cp SPR88
	jr nz,ls_next2

	ld hl,pixel_width
	ld b,SPR88_width
	ld (hl),b
	jr ls_next4

ls_next2:

	; set 16x16 pixel width
	cp SPR1616
	jr nz,ls_next3

	ld hl,pixel_width
	ld b,SPR1616_width
	ld (hl),b
	jr ls_next4
	
ls_next3:

	ld hl,pixel_width
	ld b,SPR3232_width
	ld (hl),b
	
ls_next4:

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
		
	; set path to home
	ld hl,back_path
	moscall mos_cd

	; exit on error
	cp 0
	jp nz,ls_folder_error

	
	; reset current frame and coordinates of the drawing pixel
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
	
	; set path to home
	ld hl,back_path
	moscall mos_cd

	; exit on error
	cp 0
	jp nz,ls_folder_error

	; reset current frame and coordinates of the drawing pixel
	ld hl,xpix
	xor a
	ld (hl),a
	ld hl,ypix
	ld (hl),a

ls_exit:
	call fn_show_spr_descr
	call fn_change_frames_count
	ret

ls_file_error:
	call fn_print_file_error

	; set path to home
	ld hl,back_path
	moscall mos_cd

	; exit on error
	cp 0
	jp nz,ls_folder_error

	ret

; save a sprite, giving its name
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

	; set path to sprite path
	ld hl,sprite_path
	moscall mos_cd

	; create it on error
	cp 0
	push af
	call nz,fn_create_sprite_folder
	pop af
	jr z,ss_next

	; set path to sprite path
	ld hl,sprite_path
	moscall mos_cd

ss_next:

	; exit on error
	cp 0
	jp nz,ss_folder_error
	
	; open the file for write
	ld hl,filename
	ld c,fa_create_always|fa_write
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
		
	; set path to home
	ld hl,back_path
	moscall mos_cd

	; exit on error
	cp 0
	jp nz,ss_folder_error
	
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
	
	; set path to home
	ld hl,back_path
	moscall mos_cd

	; exit on error
	cp 0
	jp nz,ss_folder_error

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
		
	; set path to home
	ld hl,back_path
	moscall mos_cd

	; exit on error
	cp 0
	jp nz,ss_folder_error
	ret

; export sprite data in assembly language, giving its name
fn_export_sprite:
	; clear filename
	ld hl,filename
	ld b,12
	xor a

es_clear_filename:
	ld (hl),a
	inc hl
	djnz es_clear_filename

	; get filename
	call fn_input_text8

	; set path to sprite path
	ld hl,sprite_path
	moscall mos_cd

	; create it on error
	cp 0
	push af
	call nz,fn_create_sprite_folder
	pop af
	jr z,es_next

	; set path to sprite path
	ld hl,sprite_path
	moscall mos_cd

	; exit on error
	cp 0
	jp nz,es_folder_error

es_next:
	; open the file for write
	ld hl,filename
	ld c,fa_create_always|fa_write
	moscall mos_fopen
		
	; exit on error
	cp 0
	jp z,es_file_error

	; filehandle -> C
	ld c,a


	; L = first frame
	ld a,0
	ld hl,sprite_buffer
	ld de,$000000
		
es_frames_repeat:
	push af
	push hl
	
	push af

	; start to write...
	ld e,0 ; rows

	ld b,';'
	moscall mos_fputc

	ld b,' '
	moscall mos_fputc

	ld b,'F'
	moscall mos_fputc

	ld b,'r'
	moscall mos_fputc

	ld b,'m'
	moscall mos_fputc

	ld b,' '
	moscall mos_fputc

	pop af
	add a,'0'
	ld b,a
	moscall mos_fputc

	ld b,13
	moscall mos_fputc

	ld b,10
	moscall mos_fputc

es_repeat:

	ld b,'D'
	moscall mos_fputc

	ld b,'B'
	moscall mos_fputc

	ld b,' '
	moscall mos_fputc

	ld d,0 ; columns

es_repeat_line:
	push de
	
	ld a,(hl)
	inc hl
	
	; convert A to BCD
	call fn_hex2bcd
	
	; write two numbers (chars)
	ld e,a
	and $f0
	rrca
	rrca
	rrca
	rrca
	add '0'
	
	ld b,a
	moscall mos_fputc
	
	ld a,e
	and $0f
	add '0'
	
	ld b,a
	moscall mos_fputc

	pop de
	inc d
	ld a,(spr_size)
	cp d
	push af
	call nz,fn_comma
	pop af
	jp nz,es_repeat_line
	
	ld b,13 ; CR
	moscall mos_fputc

	ld b,10 ; LF
	moscall mos_fputc

	inc e
	ld a,(spr_size)
	cp e
	jp nz,es_repeat

	ld b,13 ; CR
	moscall mos_fputc

	ld b,10 ; LF
	moscall mos_fputc

	pop hl
	push de
	mlt de
	add hl,de
	pop de
	pop af
	inc a
	ld ix,frames_count
	cp (ix+0)
	jp nz,es_frames_repeat

	; close the file
	moscall mos_fclose
		
	; set path to home
	ld hl,back_path
	moscall mos_cd

	; exit on error
	cp 0
	jp nz,es_folder_error
	
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
	jr es_exit

es_folder_error:
	; write error
	call fn_print_folder_error
	jp es_exit
	
es_exit:
	ret

es_file_error:
	call fn_print_file_error
		
	; set path to home
	ld hl,back_path
	moscall mos_cd

	; exit on error
	cp 0
	jp nz,es_folder_error
	ret

; print 'file error'
fn_print_file_error:
	vdu 7	
	
	; locate x,y
	vdu 31
	vdu FILENAME_X
	vdu FILENAME_Y

	; print text
	ld hl,file_error
	ld bc,0
	xor a
	rst.lis $18

	call fn_input_key

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
	vdu 7	
	
	; locate x,y
	vdu 31
	vdu FILENAME_X
	vdu FILENAME_Y

	; print text
	ld hl,folder_error
	ld bc,0
	xor a
	rst.lis $18

	call fn_input_key

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
	inc a	
	add a,48
	ld hl,current_frame_ascii
	ld (hl),a
	
	; locate 21,3
	vdu 31
	vdu 21
	vdu 3

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
	
	; locate 23,3
	vdu 31
	vdu 23
	vdu 3

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
	
fn_show_spr_descr:
	; locate 15,3
	vdu 31
	vdu 15
	vdu 3

	; print text
	ld hl,spr_descr
	ld bc,0
	xor a
	rst.lis $18

	; locate 15,5
	vdu 31
	vdu 15
	vdu 5

	; check for sprite size...
	ld hl,spr_size
	ld a,(hl)
	
	cp 4
	jr nz,ssd_8x8

	; print text 4x4
	ld hl,spr_descr1
	ld bc,0
	xor a
	rst.lis $18
	ret
	
ssd_8x8:
	cp 8
	jr nz,ssd_16x16

	; print text 8x8
	ld hl,spr_descr2
	ld bc,0
	xor a
	rst.lis $18
	ret
	
ssd_16x16:
	cp 16
	jr nz,ssd_32x32

	; print text 16x16
	ld hl,spr_descr3
	ld bc,0
	xor a
	rst.lis $18
	ret

ssd_32x32:
	; print text 32x32
	ld hl,spr_descr4
	ld bc,0
	xor a
	rst.lis $18

	ret

; input: HL = negative key to check
fn_inkey:
	moscall mos_getkbmap
	INC	HL
	LD	A, L
	NEG
	LD	C, A
	LD	A, 1
	JP	M,i_false ; < -128 ?

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
	JR Z,i_false
	LD A,1
	RET
i_false:
	XOR A
	RET

fn_create_sprite_folder:
	ld hl,sprite_path
	moscall mos_mkdir
	ret

fn_comma:
	ld b,','
	moscall mos_fputc
	ret
	
; Hex to BCD
; converts a hex number (eg. $10) to its BCD representation (eg. $16).
; Input: a = hex number
; Output: a = BCD number
; Clobbers: b,c
fn_hex2bcd:
		push bc
		ld c,a  ; Original (hex) number
		ld b,8  ; How many bits
		xor a   ; Output (BCD) number, starts at 0
htb:	sla c   ; shift c into carry
		adc a,a
		daa     ; Decimal adjust a, so shift = BCD x2 plus carry
		djnz htb  ; Repeat for 8 bits
		pop bc
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
	dw 95
ys1:
	dw 55
xs2:
	dw 224
ys2:
	dw 184

; coordinates of active pixels to draw
xpix:
	db 0
ypix:
	db 0

; memorized coordinates of active pixels to draw
memxpix:
	db 0
memypix:
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
	db "F1. 4x4 Sprite",0
menu2:
	db "F2. 8x8 Sprite",0
menu3:
	db "F3. 16x16 Sprite",0
menu4:
	db "F4. 32x32 Sprite",0

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

sprite_path:
	db "sprites",0

back_path:
	db "..",0

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

; buffer to perform some operations
swap_sprite_buffer:
	ds ONE_FRAME_BUFFER_SIZE,0

asm_line:
	DB "DB "
	
asm_line_length:
	DB 3

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
