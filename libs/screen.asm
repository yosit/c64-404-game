*=$0950 "Screen Code"
Screen: {
	TileTable: 	.byte 0, 1, 2, 40, 41, 42, 80, 81, 82
	MultiplyBy3: .fill 15, i * $3 //0,3,6,9,12,15,18,21,24,27,30,33,36
	LandTiles: .byte 1,2,1,2,1,2,1,2
	NextTile: .byte $01
	TileY: .byte $00
	.label TileLookup = TileAbsolutePosition
	LandStart: .word VIC.SCREEN_RAM+40*12
	
	DrawLand: {
		ldy #$00
	!:
		lda MultiplyBy3,y   //calculate the y coordinate of the tile
		sta TileY			//store it for the drawing function
		tya 				//remember y so we can decrement it later
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

	DrawTile: {    // function DrawTile(TileY, NextTile)
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

}


* = $4000 "Charset"
.import binary "./../data/everything-charset.bin"
* = * "Map"
Map:
.import binary "./../data/everything-map.bin"

