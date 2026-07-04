// SID sound module (WP-D). Voice 1 only. Sound is the ONLY consumer of
// Game.events: each frame it reads the flags, dispatches, and CLEARS them.
// Owns $d400-$d406 (voice 1) and $d418 (volume); nobody else touches SID.
// Public interface (LOCKED): Sound.Update, Sound.Init.
//
// Priority state machine (crash > milestone > jump):
//   sfx_id holds the currently-playing effect (0=none, 1=jump, 2=milestone,
//   3=crash) — the id doubles as its priority. A newly-arrived event only
//   starts/preempts if its id >= sfx_id, so crash preempts everything and
//   jump only starts over silence or another jump. sfx_frame counts frames
//   elapsed in the current effect; when it reaches the effect's end the
//   voice is gated off and sfx_id returns to 0.
* = * "Sound"
Sound: {
	.const EFF_NONE      = 0
	.const EFF_JUMP      = 1
	.const EFF_MILESTONE = 2
	.const EFF_CRASH     = 3

	Update: {
			// --- 1. read Game.events, pick highest-priority request ---
			// Checked low→high so the last match left in X wins (= highest).
			ldx #EFF_NONE
			lda Game.events
			and #Game.EV_JUMP
			beq !+
			ldx #EFF_JUMP
	!:
			lda Game.events
			and #Game.EV_MILESTONE
			beq !+
			ldx #EFF_MILESTONE
	!:
			lda Game.events
			and #Game.EV_CRASH
			beq !+
			ldx #EFF_CRASH
	!:
			// --- 2. consume: single-consumer clear of the event bus ---
			lda #$00
			sta Game.events

			// --- 3. preempt if the request is >= current priority ---
			cpx #EFF_NONE
			beq runCurrent
			cpx sfx_id
			bcc runCurrent			//requested < current → keep current
			jsr StartEffect

	runCurrent:
			// --- 4. advance the currently-playing effect ---
			lda sfx_id
			bne !+
			rts						//nothing playing
	!:
			cmp #EFF_JUMP
			beq doJump
			cmp #EFF_MILESTONE
			beq doMilestone
			jmp doCrash

	// ---- JUMP: triangle, freq sweep up ~10 frames, short release ----
	doJump:
			lda sfx_frame
			cmp #10
			bcc jSweep
			beq jGateOff			//frame 10: start release
			cmp #14
			bcs endEffect			//frame 14: done
			jmp advance
	jGateOff:
			lda #$10				//triangle, gate off → release
			sta $d404
			jmp advance
	jSweep:
			ldx sfx_frame
			lda #$00
			sta $d400
			lda JumpFreqHi,x
			sta $d401
			jmp advance

	// ---- MILESTONE: two square blips F then F*1.25, ~16 frames ----
	doMilestone:
			lda sfx_frame
			cmp #7
			beq mGap
			cmp #8
			beq mBlip2
			cmp #15
			beq mEnd2
			cmp #16
			bcs endEffect
			jmp advance
	mGap:
			lda #$40				//pulse, gate off (silent gap)
			sta $d404
			jmp advance
	mBlip2:
			lda #$00
			sta $d400
			lda #$28				//freq*1.25 hi byte
			sta $d401
			lda #$41				//pulse + gate on
			sta $d404
			jmp advance
	mEnd2:
			lda #$40				//pulse, gate off → release
			sta $d404
			jmp advance

	// ---- CRASH: noise, low freq, gate off early for a long decay ----
	doCrash:
			lda sfx_frame
			cmp #8
			beq cGateOff
			cmp #30
			bcs endEffect
			jmp advance
	cGateOff:
			lda #$80				//noise, gate off → release rings out
			sta $d404
			jmp advance

	advance:
			inc sfx_frame
			rts

	endEffect:
			lda #EFF_NONE
			sta sfx_id
			sta sfx_frame
			lda #$00
			sta $d404				//silence the voice
			rts
	}

	// Configure SID for the effect id in X, reset its frame counter.
	StartEffect: {
			stx sfx_id
			lda #$00
			sta sfx_frame
			cpx #EFF_JUMP
			beq initJump
			cpx #EFF_MILESTONE
			beq initMilestone
			//fall through: crash
	initCrash:
			lda #$00
			sta $d400
			lda #$08
			sta $d401				//low frequency
			lda #$00
			sta $d405				//attack 0, decay 0
			lda #$f9
			sta $d406				//sustain F, release 9 (long tail)
			lda #$81
			sta $d404				//noise + gate on
			rts
	initJump:
			lda #$09
			sta $d405				//attack 0, decay 9 (short)
			lda #$00
			sta $d406				//sustain 0, release 0
			lda #$11				//triangle + gate on
			sta $d404
			rts
	initMilestone:
			lda #$00
			sta $d402
			lda #$08
			sta $d403				//pulse width ~50%
			lda #$04
			sta $d405				//attack 0, decay 4
			lda #$00
			sta $d406				//sustain 0, release 0
			lda #$00
			sta $d400
			lda #$20				//blip1 freq hi byte
			sta $d401
			lda #$41				//pulse + gate on
			sta $d404
			rts
	}

	Init: {
			lda #$0f
			sta $d418				//master volume max, filters off
			lda #EFF_NONE
			sta sfx_id
			sta sfx_frame
			lda #$00
			sta $d404				//voice 1 silent
			rts
	}

	// Rising triangle sweep for the jump (hi byte only, lo = 0).
	JumpFreqHi: .byte $10,$14,$18,$1c,$20,$26,$2c,$32,$38,$40

	sfx_id:    .byte EFF_NONE
	sfx_frame: .byte $00
}
