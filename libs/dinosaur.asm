Dinosaur: {
	//we have to use the .var in order to nicely configure PLAYING_STATE
	.const vSTANDING_STATE 	= %00000001
	.const vRUNNING_STATE 	= %00000010
	.const vJUMPING_STATE 	= %00000100
	.const vCOLLISION_STATE = %00001000

	.const STANDING_STATE 	= %00000001
	.const RUNNING_STATE  	= %00000010
	.const JUMPING_STATE  	= %00000100
	.const COLLISION_STATE  = %00001000


	Setup:
			//set the frame of the sprite relative to the charset (default starts at $0000 and $c0 means $3000)
			lda #$c0
			lda #SPRITE_0_X_INDEX
			sta VIC.SPRITE_0_POINTER

			//set the initial position
			lda #SPRITE_0_X_INITIAL_POSITION
			sta VIC.SPRITE_0_X
			lda #SPRITE_0_Y_INITIAL_POSITION
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
			cmp #COLLISION_STATE
			bne !+
			jmp AnimateCollision
	!:		jsr detect_collision		

			lda state
			cmp #JUMPING_STATE
			bne detect_jump
			jmp AnimateJump

	AnimateCollision:			//we might want to animate this.
			rts
	detect_collision:
			lda VIC.SPRITE_BACKGROUND_COLLISION
			and #DISOSAUR_SPRITE  			//checking 
			beq !+
			lda #COLLISION_STATE			//change the state for the dinosaur. 
											//It's the other parts of the program responsibility to handle this
			sta state
	!:
			rts
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
			lda jump_sine, x
			sta VIC.SPRITE_0_Y

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


* = * "Dinosaur data"
//data 
	.label RUNNING_DELAY = $10
	.label RUNNING_LAST_FRAME = LAST_FRAME - running_frames
	.label JUMP_COUNTER_INIT = JUMP_SINE_END - jump_sine - 1
	.label PLAYING_STATE 	= vRUNNING_STATE | vJUMPING_STATE

	.label SPRITE_0_X_INDEX 	= $c0
	.label SPRITE_0_X_INITIAL_POSITION 	= $40
	.label SPRITE_0_Y_INITIAL_POSITION	= $8d //TODO: make sure we're positioning the player just above the ground so we can do collision detection
	.label DISOSAUR_SPRITE		= $01
	state: .byte RUNNING_STATE

	jump_counter: .byte JUMP_COUNTER_INIT
	running_delay_counter: .byte RUNNING_DELAY

	running_frame_index: .byte $00
	running_frames: .byte $c1, $c2
	LAST_FRAME:

	*=* "jump_sine"
	//we're capping the sine wave by the max height and subtracting it from the initial x value, number of values control the speed (128)
	jump_sine: .for(var i=0;i<128;i+=2.5) .byte SPRITE_0_Y_INITIAL_POSITION - sin((i/128) * (PI*2) * 0.5) * 50
	.fill 1, SPRITE_0_Y_INITIAL_POSITION  //make sure the sine ends with the start position
	JUMP_SINE_END:
}