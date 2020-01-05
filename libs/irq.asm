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

		lda #$e2
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
			jsr Dinosaur.Update
			jsr Screen.DrawLand

			lda #<SecondIRQ    
			ldx #>SecondIRQ
			sta $fffe   // 0314
			stx $ffff	// 0315

			lda #$00
			sta $d012
			lda $d011
			and #%11111111
			sta $d011	

			asl $d019 //Acknowledging the interrupt
		:RestoreState();
		rti
	}


	SecondIRQ: {
		:StoreState()
			//Reset Values set by IRQ	
			lda #<MainIRQ    
			ldx #>MainIRQ
			sta $fffe   // 0314
			stx $ffff	// 0315

			lda #$50
			sta $d012
			lda $d011
			and #%01111111
			sta $d011	

			asl $d019 //Acknowledging the interrupt
		:RestoreState();
		rti
	}
}