#import "./libs/zeropage.asm"
#import "./libs/macros.asm"
#import "./libs/vic.asm"
BasicUpstart2(Entry)
#import "./libs/screen.asm"
#import "./libs/irq.asm"
#import "./libs/setup.asm"
#import "./libs/utils.asm"

#import "./libs/dinosaur.asm"
#import "./libs/charset.asm"


Entry:
			jsr Random.init
			jsr Setup.init
			jsr Dinosaur.Setup
			jsr Screen.DrawLand
			jsr IRQ.Setup

			//Bank out BASIC and Kernal ROM
			lda $01
			and #%11111000 
			ora #%00000101
			sta $01
			jmp *

		raster:
			lda #$20
		!:
			cmp $d012
			bne !-
			inc $d020
			jsr Dinosaur.Update
			jsr Screen.DrawLand

		dd:
			dec $d020
			jmp raster 

			rts





