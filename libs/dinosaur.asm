


Dinosaur: {
* = $0830
//data 
	.label RUNNING_DELAY = $10
	.label JUMP_COUNTER_INIT = $40
	.label RUNNING_LAST_FRAME = $04

	.label STANDING_STATE = %00000000
	.label RUNNING_STATE  = %00000001
	.label JUMPING_STATE  = %00000010


	state: .byte RUNNING_STATE

	jump_counter: .byte JUMP_COUNTER_INIT
	running_delay_counter: .byte RUNNING_DELAY

	running_frame_index: .byte $00
	running_frames: .byte $c1, $c2, $c1, $c2, $c2, $c3, $c4, $c5

* = $0850	
	Setup:

			//set the frame of the sprite relative to the charset (default starts at $0000 and $c0 means $3000)
			lda #$c0
			lda #INITIAL_SETTINGS.SPRITE_0_X_INDEX
			sta VIC.SPRITE_0_POINTER

			//set the initial position
			lda #INITIAL_SETTINGS.SPRITE_0_X_INITIAL_POSITION
			sta VIC.SPRITE_0_X
			lda #INITIAL_SETTINGS.SPRITE_0_Y_INITIAL_POSITION
			sta VIC.SPRITE_0_Y

			//We're enabling only the dinosaur sprite
			lda VIC.SPRITE_ENABLE
			ora #$01
			sta VIC.SPRITE_ENABLE
			
			lda #$08 // sprite multicolor 1
			sta VIC.SPRITE_MULTICOLOR_1
			lda #$06 // sprite multicolor 2
			sta VIC.SPRITE_MULTICOLOR_2
			rts

	Update:
			lda state
			cmp #JUMPING_STATE
			bne detect_jump
			jmp AnimateJump

	detect_jump:
			lda VIC.JOYSTICK_1
			cmp #$ef  //space bar pressed
			bne !+
			lda #JUMPING_STATE
			sta state
			rts

		!:	jsr AnimateRunning
			rts

	AnimateJump:
			ldx jump_counter
			dex
			bne !+
			ldx #JUMP_COUNTER_INIT
			lda #RUNNING_STATE
			sta state
		!:
			stx jump_counter
			rts

	AnimateRunning: //running through the frames of running states
			ldx running_delay_counter
			dex
			beq reset_delay
			stx running_delay_counter
			rts
		reset_delay:
			ldx #RUNNING_DELAY
			stx running_delay_counter
			ldx running_frame_index
			inx
			cpx #RUNNING_LAST_FRAME
			bne !+
			ldx #$00
		!:
			stx running_frame_index
			lda running_frames, x
			sta VIC.SPRITE_0_POINTER
		skip:
			rts


}