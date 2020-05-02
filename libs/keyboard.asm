*=* "Keyboard Code"
.label		pra  =  $dc00            // CIA#1 (Port Register A)
.label	    prb  =  $dc01            // CIA#1 (Port Register B)

.label		ddra =  $dc02            // CIA#1 (Data Direction Register A)
.label		ddrb =  $dc03            // CIA#1 (Data Direction Register B)

Keyboard: {
	check_key_pressed: {  // each key needs its own pra line - so we should fall back to space after reading each key.
						  // add some delay so we can't 
		lda $00c5   //holds the current key
		cmp $00cb	//holds the previous key
		beq !+		// if they are the same de bounce the key

        lda #%11111111  // CIA#1 Port A needs to be set to output 
        sta ddra             

        lda #%00000000  // CIA#1 Port B needs to be set to input
        sta ddrb             
        
        lda #%11111011    // select third row
        sta pra           // by storing $0b into pra
        lda prb           // load current column information
        and #%10000000    // isolate 'x' key Bit which is Bit#7 
        bne !+          // if AND result is zero, then key was pressed
		inc Screen.speed
	!:	
		rts
	}
}