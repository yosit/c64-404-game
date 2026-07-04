Dinosaur: {
	//State ordinals — index into StateHandlers below. A byte `state`
	//holds the ordinal; Update dispatches through the .word table via the
	//RTS trick (each entry stores handler-1). Empty handlers (IDLE, DUCKING,
	//DEAD) are stubs that later work packages fill in.
	.label ST_IDLE    = 0
	.label ST_RUNNING = 1
	.label ST_JUMPING = 2
	.label ST_DUCKING = 3
	.label ST_DEAD    = 4

	Setup:
			//set the frame of the sprite relative to the charset (default starts at $0000 and $c0 means $3000)
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

	//Full reset of the dino to a fresh running state — called from Game.Reset.
	Reset:
			lda #ST_RUNNING
			sta state
			lda #SPRITE_0_Y_INITIAL_POSITION
			sta VIC.SPRITE_0_Y
			lda #JUMP_COUNTER_INIT
			sta jump_counter
			lda #RUNNING_DELAY
			sta running_delay_counter
			lda #$00
			sta running_frame_index
			lda #$c1
			sta VIC.SPRITE_0_POINTER
			rts

	Update:
			lda state
			asl						//*2 for the .word table
			tax
			lda StateHandlers+1,x
			pha
			lda StateHandlers,x
			pha
			rts						//RTS trick: jump to StateHandlers[state]

	HandleIdle:					//WP-A fills (start screen)
			rts

	HandleRunning:
			jsr detect_collision
			jmp AnimateRunning

	HandleJumping:
			jsr detect_collision
			jmp AnimateJump

	HandleDucking:				//WP-C fills (duck animation)
			rts

	HandleDead:					//WP-A fills (death animation)
			rts

	//WP-A un-stubs this: read $d01f ONCE per frame (reads clear it),
	//and #%00000001, on a set bit route to the crash path.
	detect_collision:
			rts  //skip for now
			lda VIC.SPRITE_BACKGROUND_COLLISION
			and #DINOSAUR_SPRITE
			beq !+
			jsr Game.Crash
	!:
			rts

	set_jump:
			lda #ST_JUMPING
			sta state
			lda Game.events				//producer: announce the jump for Sound (WP-D)
			ora #Game.EV_JUMP
			sta Game.events
			rts

	AnimateJump:
			ldx jump_counter
			dex
			bne !+
			ldx #JUMP_COUNTER_INIT
			lda #ST_RUNNING
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

	.label SPRITE_0_X_INDEX 	= $c0
	.label SPRITE_0_X_INITIAL_POSITION 	= $40
	.label SPRITE_0_Y_INITIAL_POSITION	= $8d //TODO: make sure we're positioning the player just above the ground so we can do collision detection
	.label DINOSAUR_SPRITE		= $01
	state: .byte ST_RUNNING

	jump_counter: .byte JUMP_COUNTER_INIT
	running_delay_counter: .byte RUNNING_DELAY

	running_frame_index: .byte $00
	running_frames: .byte $c1, $c2
	LAST_FRAME:

	//Dispatch table for Update — order MUST match the ST_* ordinals.
	//RTS-trick convention: store (handler address - 1).
	StateHandlers:
		.word HandleIdle-1
		.word HandleRunning-1
		.word HandleJumping-1
		.word HandleDucking-1
		.word HandleDead-1

	*=* "jump_sine"
	//we're capping the sine wave by the max height and subtracting it from the initial x value, number of values control the speed (128)
	jump_sine: .for(var i=0;i<128;i+=2.5) .byte SPRITE_0_Y_INITIAL_POSITION - sin((i/128) * (PI*2) * 0.5) * 50
	.fill 1, SPRITE_0_Y_INITIAL_POSITION  //make sure the sine ends with the start position
	JUMP_SINE_END:
}
