*=* "Screen Code"
Screen: {
	Update: {
		lda Dinosaur.state
		and #Dinosaur.PLAYING_STATE
		beq !+						// if this is zero we're not playing
		jsr UpdateScreen
	!:
		rts

	}
	UpdateScreen:{
					// the ugliest possible way to implement speed.
					// a better way would be to subtract the speed from the scroll state and calculate if we need to scroll the 
					// land and adjust $d016 accordingly
		ldx speed
	!:
		stx speed_counter	
		jsr ScrollScreen
		ldx speed_counter
		dex
		bne !-
		rts
	}

	UpdateScrollState: {
		lda realOffset
		sta VIC.SCREEN_CONTROL_2
		rts
	}

	ScrollScreen: {
		lda realOffset
		ldx delay
		dex
		bne !+
		sec
		lda offset
		sbc #$01
		and #$07
		sta offset

		clc
		lda VIC.SCREEN_CONTROL_2
		and #$f8
		adc offset
		sta realOffset
		pha
		jsr ScrollThirdTile
		pla
		ldx #SCROLL_DELAY
	!:
		stx delay
		rts
	}
	ScrollThirdTile: {
		inc $d020
		lda realOffset      //scroll the tiles only if we need to
		and #$07  			//if the screen is on the top most right position we need to scroll the tiles.
		cmp #$07
		bne skip
		ldx #$00
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
	realOffset: .byte $c8
	offset: .byte $07

	speed: 				  .byte $01			//used to control the speed of the land
	speed_counter: 		  .byte $01			//counter to keep tabs on the screen
	delay: .byte SCROLL_DELAY	  //Counter to remember the delay
	.label SCROLL_DELAY = $01      //control how slow we want to scroll the land
	
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



