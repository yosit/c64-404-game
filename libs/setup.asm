Setup: {
	ClearScreen: {
		//clear the screen - 25 lines over 40 chars => divided by 4 it's 250
		lda #$20
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