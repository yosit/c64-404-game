*=* "Screen Code"
Screen: {
	speed: 	.byte $01			//used to control the speed of the land

	Update: {
		lda Dinosaur.state
		and #Dinosaur.PLAYING_STATE // TODO: Change states to jump table.
		beq !+						// if this is zero we're not playing
		jsr UpdateScreen
	!:
		rts

	}
*=* "offset"
	offset: .byte $07

	UpdateScreen:{
		// ldx delay
		// dex
		// bne skipDelay
		lda offset
		sec 
		sbc speed
		bpl !+		// we should skip and just set the scroll
		and #$07
		sta offset
		lda #$01
		sta shouldScrollLand
		jsr ScrollThirdTile
		jmp continueDelay
	!:	sta offset

	continueDelay:
	// 	ldx #SCROLL_DELAY
	// skipDelay:
	// 	stx delay
		rts
	}

	UpdateScrollState: {
		clc  
		lda #$c0
		adc offset
		sta VIC.SCREEN_CONTROL_2
		rts
	}

	ScrollThirdTile: {
		inc $d020
		// lda realOffset      //scroll the tiles only if we need to
		// and #$07  			//if the screen is on the top most right position we need to scroll the tiles.
		// cmp #$07
		lda shouldScrollLand   //if the flag is on we should scroll the screen
		cmp #$01
		bne skip

		ldx #$00
		stx shouldScrollLand   //zero the scroll flag
	!:
		lda LandStartAddress+1,x
		sta LandStartAddress,x
		lda LandStartAddress+$29,x
		sta LandStartAddress+$28,x
		lda LandStartAddress+$51,x
		sta LandStartAddress+$50,x
		inx
		cpx #$27
		bne !-
	!:	
		ldx scrollTileComplete //check if we need to add another tile on the far right side when we scrolled 3 chars.
		dex
		bne !+

		lda #$24     		//calculate the y coordinate of the tile
		sta TileY			//store it for the drawing function
		jsr Random
		and #%00000111
		tay
		lda LandTiles,y
		sta NextTile
		jsr DrawTile		

		ldx #$03
	!:
		stx scrollTileComplete
	skip:
		dec $d020
		rts
	}

	DrawLand: {
		ldy #$00
	!:
		lda MultiplyBy3,y   //calculate the y coordinate of the tile
		sta TileY			//store it for the drawing function
		tya 				//remember y so we can increment it later
		pha
		jsr Random
		and #%00000111
		tay
		lda LandTiles,y
		sta NextTile
		jsr DrawTile		//draw the tile
		pla
		tay
		iny
		cpy #$0d			//we want 13 tiles on screen (40/3 ~ 13)
		bne !-
		rts
	}

	DrawTile: {   		// function DrawTile(TileY, NextTile)
					    // TileY: the exact Y Position on screen to put the tile.
					    // NextTile: The tile index
						//initialize start address
		lda LandStart
		sta TileAbsolutePosition
		lda LandStart+1
		sta TileAbsolutePosition+1
						//calculate the first position for the tile in the font
		clc
		lda TileY
		adc TileAbsolutePosition
		bcc !+
		inc TileAbsolutePosition+1
	!:	sta TileAbsolutePosition

		multiplyby9(NextTile)
		ldx #$00
	!:		
		ldy TileTable,x
		sta (TileLookup),y
		adc #$01
		inx
		cpx #$09
		bne !-
		rts
	}
	ClearScreen: {
		//clear the screen - 25 lines over 40 chars => divided by 4 it's 250
		lda #$ff
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

	scrollTileComplete: .byte $03
	shouldScrollLand: .byte $00


	delay: .byte SCROLL_DELAY	  //Counter to remember the delay
	.label SCROLL_DELAY = $04      //control how slow we want to scroll the land
	
	scrolledTile: .byte $03

	TileTable: 	.byte 0, 1, 2, 40, 41, 42, 80, 81, 82
	MultiplyBy3: .fill 15, i * $3 //0,3,6,9,12,15,18,21,24,27,30,33,36
	LandTiles: .byte 1,2,1,4,1,2,1,2
	NextTile: .byte $01
	TileY: .byte $00
	.label TileLookup = TileAbsolutePosition
	LandStart: .word VIC.SCREEN_RAM+40*12
	.label LandStartAddress = VIC.SCREEN_RAM+40*12
}



