Setup: {

	init: {
		jsr Screen.ClearScreen
		lda VIC.BANK
		and #%11111110
		ora #%00000010   
		sta VIC.BANK

		lda #%01000000       //this would setup the character rom at $4000 and screen at %5000
		sta VIC.MEMORY_SETUP

		jsr Screen.DrawLand
		rts
	}
	
}