*=$0950 "Screen Code"
Screen: {
	tile_location: 	.byte 0,1,2,40,41,42,80,81,82

	DrawTile: {
		.label TILE = $00
		clc
		lda #TILE //we're multiplying by 9 because a tile is 3X3
		asl
		asl
		asl
		adc #TILE
		ldy #$00
	!:		
		ldx tile_location,y
		sta VIC.SCREEN_RAM,x
		adc #$01
		iny
		cpy #$09
		bne !-
		rts
	}
}


* = $4000 "Charset"
.import binary "./../data/everything-charset.bin"
* = * "Map"
Map:
.import binary "./../data/everything-map.bin"

