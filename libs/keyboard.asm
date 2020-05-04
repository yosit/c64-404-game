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
	    	inc Screen.speed
	    !:
	    	cmp #$1a //'z'
	    	bne !+
	    	dec Screen.speed
	    !:
	    	cmp #$20 // ' '  space/port 1 fire
	    	bne !+
	    	jsr Dinosaur.set_jump //TODO: consider changing that since space might not always be used for jump
	    !:
	    	rts
	}
}