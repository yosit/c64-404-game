// Game module — the integration hub. MainIRQ calls Game.Update once per
// frame; nothing else edits irq.asm. Game.Reset fans out to every module's
// own Reset. Game.events is the frame-local event bus: producers OR bits in,
// Sound (WP-D) is the single consumer that clears them each frame.
* = * "Game"
Game: {
	.label EV_JUMP      = %00000001
	.label EV_MILESTONE = %00000010
	.label EV_CRASH     = %00000100

	events: .byte $00

	Update: {
			cld							//BCD-score users set/clear SED locally; backstop here (IRQ entry does not clear D on NMOS 6502)
		#if DEMO
			jsr DemoDrive
		#endif
			jsr Dinosaur.Update
			jsr Input.check_key_pressed
			jsr Screen.Update
			jsr Score.Update			//stub until WP-B
			jsr Ptero.Update			//stub until WP-C
			jsr Sound.Update			//stub until WP-D
			jsr Ambience.Update			//stub until WP-E
			rts
	}

	// Full game reset — each module owns its part.
	Reset: {
			jsr ClearGameOver		//WP-A: wipe the GAME OVER banner
			jsr Screen.Reset
			jsr Dinosaur.Reset		//restores the running sprite frame ($c1)
			jsr Score.Reset
			jsr Ptero.Reset
			jsr Ambience.Reset
			rts
	}

	// Crash entry point. Producers (WP-A dino-vs-cactus $d01f, WP-C
	// ptero $d01e) call this. Phase-0 baseline: flag the event and drop
	// the dino into ST_DEAD. WP-A fleshes out (dead sprite, GAME OVER text).
	Crash: {
			lda events
			ora #EV_CRASH
			sta events
			lda #Dinosaur.ST_DEAD
			sta Dinosaur.state
			lda #DEAD_DINO_SPRITE			//WP-A: swap in the dead (X-eyed) dino frame
			sta VIC.SPRITE_0_POINTER
			lda #Dinosaur.SPRITE_0_Y_INITIAL_POSITION	//drop to the ground if we crashed mid-jump
			sta VIC.SPRITE_0_Y
			jsr DrawGameOver				//WP-A: banner
			rts
	}

	.label DEAD_DINO_SPRITE = $c9			//sprite pointer of din_dead (data/sprites.asm)

	//"GAME OVER" banner on screen row 8. The letter glyphs (chars 186-199)
	//are owned by WP-B; here we only write the char CODES, so the text shows
	//as blanks until WP-B's letter glyphs merge, then renders correctly.
	//Char-code map (documented for WP-B/integration):
	//  G=$bc(188) A=$bd(189) M=$be(190) E=$bf(191) O=$c0(192) V=$c1(193) R=$c2(194)
	//  (space = $20). "GAME OVER" centred at cols 16-24 of row 8.
	.label GAMEOVER_ROW = VIC.SCREEN_RAM + 40*8
	.label GAMEOVER_COL = 16
	.label GAMEOVER_LEN = 9
	DrawGameOver: {
			ldx #GAMEOVER_LEN-1
	!:		lda GameOverText,x
			sta GAMEOVER_ROW + GAMEOVER_COL,x
			dex
			bpl !-
			rts
	}
	ClearGameOver: {
			lda #$ff					//blank (custom charset: $ff is the true blank, $20 is a land tile)
			ldx #GAMEOVER_LEN-1
	!:		sta GAMEOVER_ROW + GAMEOVER_COL,x
			dex
			bpl !-
			rts
	}
	GameOverText: .byte $bc,$bd,$be,$bf,$ff,$c0,$c1,$bf,$c2	//G A M E _ O V E R ($ff = blank space)

#if DEMO
	// Headless verification driver: keys can't be pressed while Kernal is
	// banked out, so DEMO builds synthesise input here. Jump ~every 180
	// frames, duck frames 400-500 of each 512-frame cycle, and auto-restart
	// 120 frames after a death. Each WP tunes/overrides as needed.
	DemoDrive: {
			inc demoFrame
			bne !+
			inc demoFrame+1
	!:
			//auto-restart if dead
			lda Dinosaur.state
			cmp #Dinosaur.ST_DEAD
			bne notDead
			inc deadCounter
			lda deadCounter
			cmp #120
			bcc done
			lda #$00
			sta deadCounter
			jsr Reset
			jmp done
	notDead:
			lda #$00
			sta deadCounter
			//jump every 180 frames (low byte hits 180)
			lda demoFrame
			cmp #180
			bne done
			lda #$00
			sta demoFrame
			jsr Dinosaur.set_jump
	done:
			rts
	}
	demoFrame:   .byte $00, $00
	deadCounter: .byte $00
#endif
}
