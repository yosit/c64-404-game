#import "./libs/zeropage.asm"
#import "./libs/macros.asm"
#import "./libs/vic.asm"
#import "./libs/setup.asm"
#import "./libs/utils.asm"
#import "./libs/dinosaur.asm"


BasicUpstart2(Entry)


Entry:
			jsr Random.init
			jsr Setup.init
			jsr Dinosaur.Setup
			jsr Screen.DrawTile

		raster:
			lda #$20
		!:
			cmp $d012
			bne !-
			inc $d020
			jsr Random
			jsr Dinosaur.Update
		dd:
			jsr Screen.DrawTile

			dec $d020
			jmp raster 

			rts



* = $7000 "sprites"
	#import  "./data/sprites.asm"

