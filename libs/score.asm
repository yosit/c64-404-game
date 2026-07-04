// Score / high-score module (WP-B). Public interface (LOCKED):
// Score.Update, Score.Reset, Score.Init, and the two BCD counters below.
//
// score/hiscore are 3 bytes BCD, little-endian (byte 0 = least significant
// pair of digits). 6 BCD digits internally; the low 5 are shown on screen.
//
// Layout on row 0 (SCREEN_RAM = $5000):
//   cols 24-32 : "HI" + 5-digit high score  (chars 186,187 + 176+digit)
//   cols 34-38 : 5-digit running score       (chars 176+digit)
//
// Digit char = 176 ($b0) + digit value. Blank = $ff (the custom charset's
// blank glyph — screen code $20 is a land tile here, not a space).
//
// cld discipline: the only BCD arithmetic is in AddOne, which brackets its
// adc chain with sed ... cld. MainIRQ/Game.Update also open with cld as a
// backstop.  No zeropage is used by this module.
* = * "Score"
Score: {
	.label DIGIT_BASE   = $b0			//char 176 = digit 0
	.label BLANK        = $ff			//custom charset: $ff is blank (ClearScreen fills it); $20 is a land tile
	.label CH_H         = 186
	.label CH_I         = 187
	.label SCORE_COL    = VIC.SCREEN_RAM + 34	//row 0, col 34 (5 digits: 34..38)
	.label HI_COL       = VIC.SCREEN_RAM + 24	//row 0, col 24 ("HI" + digits)
	.label FRAME_DIV    = 4				//+1 point every 4th frame
	.label MAX_SPEED    = 7
	.label BLINK_TOGGLES = 12			//~6 on/off blinks per milestone
	.label BLINK_PERIOD  = 8			//frames between blink toggles

	Update: {
			//--- high score check on crash (EV_CRASH still set: Sound clears
			//    events AFTER us in the same frame, so we read it first) ---
			lda Game.events
			and #Game.EV_CRASH
			beq noCrash
			jsr UpdateHiScore
			//freeze the score visible (not mid-blink) at the moment of death
			lda #$00
			sta blinkActive
			sta blinkPhase
			jsr RenderScore
	noCrash:
			//--- only score while in a playing state (RUNNING/JUMPING/DUCKING
			//    = ordinals 1..3). IDLE (0) and DEAD (4) freeze scoring. ---
			lda Dinosaur.state
			beq done					//ST_IDLE
			cmp #Dinosaur.ST_DEAD
			bcs done					//ST_DEAD (4) or higher

			//--- milestone blink handling ---
			lda blinkActive
			beq noBlink
			dec blinkTimer
			bne noBlink
			lda #BLINK_PERIOD
			sta blinkTimer
			lda blinkPhase
			eor #$01
			sta blinkPhase
			lda #$01
			sta dirty					//redraw in the new phase
			dec blinkCount
			bne noBlink
			//blink finished — leave digits visible
			lda #$00
			sta blinkActive
			sta blinkPhase
			lda #$01
			sta dirty
	noBlink:

			//--- frame divider: +1 point every FRAME_DIV frames ---
			inc frameDiv
			lda frameDiv
			cmp #FRAME_DIV
			bcc render
			lda #$00
			sta frameDiv
			jsr AddOne

	render:
			lda dirty
			beq done
			lda #$00
			sta dirty
			jsr RenderScore
	done:
			rts
	}

	// Reset the running score only — hiscore SURVIVES restarts. Also resets
	// scroll speed to 1 (WP-B owns progressive speed). Called from Game.Reset,
	// which runs Dinosaur.Reset (state -> RUNNING) BEFORE us, so the next
	// Score.Update renders "00000" while playing.
	Reset: {
			lda #$00
			sta score
			sta score+1
			sta score+2
			sta frameDiv
			sta blinkActive
			sta blinkPhase
			lda #$01
			sta Screen.speed
			sta dirty					//force re-render of the fresh score
			rts
	}

	// One-time init at Setup. Zero both counters and paint the initial
	// "00000" score and "HI 00000" high score onto the (already cleared) screen.
	Init: {
			lda #$00
			sta score
			sta score+1
			sta score+2
			sta hiscore
			sta hiscore+1
			sta hiscore+2
			sta frameDiv
			sta blinkActive
			sta blinkPhase
			sta dirty
			jsr RenderScore
			jsr RenderHi
			rts
	}

	// BCD +1 into the 3-byte little-endian score. On crossing a hundred
	// (byte0 wraps to $00) fire a milestone: EV_MILESTONE, speed-up, blink.
	AddOne: {
			sed
			clc
			lda score
			adc #$01
			sta score
			lda score+1
			adc #$00
			sta score+1
			lda score+2
			adc #$00
			sta score+2
			cld
			lda #$01
			sta dirty
			lda score					//byte0 == 0  => just crossed a hundred
			bne noMilestone
			jsr Milestone
	noMilestone:
			rts
	}

	Milestone: {
			lda Game.events
			ora #Game.EV_MILESTONE
			sta Game.events
			//progressive speed
			lda Screen.speed
			cmp #MAX_SPEED
			bcs noSpeed
			inc Screen.speed
	noSpeed:
			//start the score blink
			lda #BLINK_TOGGLES
			sta blinkCount
			lda #BLINK_PERIOD
			sta blinkTimer
			lda #$01
			sta blinkActive
			lda #$00
			sta blinkPhase
			rts
	}

	// On crash: copy score into hiscore if score > hiscore (BCD compare,
	// MSB first). Valid BCD compares correctly as plain byte compares.
	UpdateHiScore: {
			lda score+2
			cmp hiscore+2
			bcc noHi
			bne doCopy
			lda score+1
			cmp hiscore+1
			bcc noHi
			bne doCopy
			lda score
			cmp hiscore
			bcc noHi
			beq noHi					//equal — not greater
	doCopy:
			lda score
			sta hiscore
			lda score+1
			sta hiscore+1
			lda score+2
			sta hiscore+2
			jsr RenderHi
	noHi:
			rts
	}

	// Paint the 5 low digits of `score` at cols 34-38 (or blanks while the
	// milestone blink is in its blank phase).
	RenderScore: {
			lda blinkPhase
			beq showDigits
			ldx #$04
			lda #BLANK
	blankLoop:
			sta SCORE_COL,x
			dex
			bpl blankLoop
			rts
	showDigits:
			lda score+2					//col34 = ten-thousands (byte2 low nibble)
			and #$0f
			clc
			adc #DIGIT_BASE
			sta SCORE_COL+0
			lda score+1					//col35 = thousands (byte1 high nibble)
			lsr
			lsr
			lsr
			lsr
			clc
			adc #DIGIT_BASE
			sta SCORE_COL+1
			lda score+1					//col36 = hundreds (byte1 low nibble)
			and #$0f
			clc
			adc #DIGIT_BASE
			sta SCORE_COL+2
			lda score					//col37 = tens (byte0 high nibble)
			lsr
			lsr
			lsr
			lsr
			clc
			adc #DIGIT_BASE
			sta SCORE_COL+3
			lda score					//col38 = ones (byte0 low nibble)
			and #$0f
			clc
			adc #DIGIT_BASE
			sta SCORE_COL+4
			rts
	}

	// Paint "HI" + 5 high-score digits at cols 24-32.
	RenderHi: {
			lda #CH_H
			sta HI_COL+0				//col24 H
			lda #CH_I
			sta HI_COL+1				//col25 I
			lda #BLANK
			sta HI_COL+2				//col26
			sta HI_COL+3				//col27
			lda hiscore+2				//col28 ten-thousands
			and #$0f
			clc
			adc #DIGIT_BASE
			sta HI_COL+4
			lda hiscore+1				//col29 thousands
			lsr
			lsr
			lsr
			lsr
			clc
			adc #DIGIT_BASE
			sta HI_COL+5
			lda hiscore+1				//col30 hundreds
			and #$0f
			clc
			adc #DIGIT_BASE
			sta HI_COL+6
			lda hiscore					//col31 tens
			lsr
			lsr
			lsr
			lsr
			clc
			adc #DIGIT_BASE
			sta HI_COL+7
			lda hiscore					//col32 ones
			and #$0f
			clc
			adc #DIGIT_BASE
			sta HI_COL+8
			rts
	}

	score:   .byte $00, $00, $00		//running score, 3-byte BCD little-endian
	hiscore: .byte $00, $00, $00		//high score, 3-byte BCD little-endian

	frameDiv:    .byte $00				//frame counter for the +1 divider
	dirty:       .byte $00				//1 => score digits need repainting
	blinkActive: .byte $00				//1 => milestone blink in progress
	blinkPhase:  .byte $00				//1 => currently blanked
	blinkCount:  .byte $00				//remaining toggles
	blinkTimer:  .byte $00				//frames until next toggle
}
