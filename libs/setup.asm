Setup: {
	ClearScreen: {
		//clear the screen - 24 lines over 40 chars
		lda #$00
		ldx #250
	!:	
		dex
		sta VIC.SCREEN_RAM, x
		sta VIC.SCREEN_RAM + 250, x
		sta VIC.SCREEN_RAM + 250*2, x
		sta VIC.SCREEN_RAM + 250*3, x
		bne !-
		rts
	}
}