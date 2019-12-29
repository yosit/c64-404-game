#import "./screen.asm"
Setup: {

	Init: {
		jsr ClearScreen
		lda VIC.BANK
		and #%11111110
		ora #%00000010   
		sta VIC.BANK

		lda #%01000000       //this would setup the character rom at $4000 and screen at %5000
		sta VIC.MEMORY_SETUP

		rts
	}
	ClearScreen: {
		rts
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