* = * "IRQ"
IRQ: {
	Setup: {
		sei

		lda #$7f	//Disable CIA IRQ's to prevent crash because 
		sta $dc0d
		sta $dd0d

		lda $d01a
		ora #%00000001	
		sta $d01a

		lda #<MainIRQ    
		ldx #>MainIRQ
		sta $fffe   // 0314
		stx $ffff	// 0315

		lda #$20
		sta $d012
		lda $d011
		and #%01111111
		sta $d011	

		asl $d019
		cli
		rts
	}

	MainIRQ: {
		:StoreState()
			inc $d020
			jsr Game.Update		//all per-frame game logic lives behind this one call
			dec $d020
			lda #<ScrollIRQ    
			ldx #>ScrollIRQ
			sta $fffe   // 0314
			stx $ffff	// 0315

			lda #$90
			sta $d012
			lda $d011
			and #%01111111		//clear the raster-compare MSB (bit 8); target lines are <256
			sta $d011

			asl $d019 //Acknowledging the interrupt
		:RestoreState();
		rti
	}


	ScrollIRQ: {
		:StoreState()
			inc $d020
			jsr Screen.UpdateScrollState //we don't have enough cycles to take care of the actual scrolling so we just update the scroll state here
			//Reset Values set by IRQ
			lda #<ResetIRQ    
			ldx #>ResetIRQ
			sta $fffe   // 0314
			stx $ffff	// 0315

			lda #$b0
			sta $d012
			lda $d011
			and #%01111111		//clear the raster-compare MSB (bit 8); target lines are <256
			sta $d011

			asl $d019 //Acknowledging the interrupt
		:RestoreState();
		rti
	}

	ResetIRQ: {
		:StoreState()
			dec $d020

			lda #$c8
			sta VIC.SCREEN_CONTROL_2
			//Reset Values set by IRQ
			lda #<MainIRQ    
			ldx #>MainIRQ
			sta $fffe   // 0314
			stx $ffff	// 0315

			lda #$20
			sta $d012
			lda $d011
			and #%01111111
			sta $d011	

			asl $d019 //Acknowledging the interrupt
		:RestoreState();
		rti
	}
}