//checkout https://www.lemon64.com/forum/viewtopic.php?t=9371&sid=0e227696efa1b47319e1ea6361224c79

*=* "Keyboard Code"
.label		pra  =  $dc00            // CIA#1 (Port Register A)
.label	    prb  =  $dc01            // CIA#1 (Port Register B)

.label		ddra =  $dc02            // CIA#1 (Data Direction Register A)
.label		ddrb =  $dc03            // CIA#1 (Data Direction Register B)

Input: {
	check_key_pressed: {
			jsr Keyboard
	        bcs !++
	        // Check A for Alphanumeric keys
	        cmp #$18 //'x'
	        bne !+
	    	ldx Screen.speed
	    	cpx #$07			//clamp at 7 — UpdateScreen wraps offset mod 8
	    	bcs !+
	    	inc Screen.speed
	    !:
	    	cmp #$1a //'z'
	    	bne !+
	    	ldx Screen.speed
	    	cpx #$02			//clamp at 1 — 0 freezes the land, underflow breaks sbc
	    	bcc !+
	    	dec Screen.speed
	    !:
	    	cmp #$20 // ' '  space/port 1 fire
	    	bne !+
	    	jsr Dinosaur.set_jump //TODO: consider changing that since space might not always be used for jump
	    !:
	    	jsr ScanDuck		//held-key duck ('D')
	    	rts
	}

	// The TWW keyboard routine is edge-triggered (reports only NEW keypresses),
	// which is perfect for jump but can't tell us a key is being HELD. Ducking
	// needs hold state, so scan the 'D' key straight off the CIA1 matrix:
	// D sits at column PA2 ($dc00 bit 2) / row PB2 ($dc01 bit 2). The DDRs were
	// already configured by the Keyboard call above. set_duck/set_run are
	// guarded (only RUNNING<->DUCKING act), so calling them every frame is safe.
	ScanDuck: {
	    	lda #%11111011		//drive PA2 low (select D's column)
	    	sta $dc00
	    	lda $dc01
	    	and #%00000100		//PB2 — D's row bit; 0 = pressed
	    	bne released
	    	jmp Dinosaur.set_duck	//held -> crouch
	    released:
	    	jmp Dinosaur.set_run	//released -> stand back up
	}
}