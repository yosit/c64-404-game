*=$0950 "Screen Code"
Screen: {
	TileTable: 	.byte 0,1,2,40,41,42,80,81,82
	NextTile: .byte $01
	TileY: .byte $00
	.label TileLookup = TileAbsolutePosition
	LandStart: .word VIC.SCREEN_RAM+40*12
	

	DrawTile: {
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

