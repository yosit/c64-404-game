#import "./libs/vic.asm"
#import "./libs/setup.asm"
#import "./libs/dinosaur.asm"

BasicUpstart2(Entry)


Entry:
			jsr Setup.Init
			jsr Dinosaur.Setup
			jsr Screen.DrawTile

		raster:
			lda #$20
		!:
			cmp $d012
			bne !-
			inc $d020
			jsr Dinosaur.Update
		dd:
			jsr Screen.DrawTile

			dec $d020
			jmp raster 

			rts



* = $7000 "sprites"
	#import  "./data/sprites.asm"

