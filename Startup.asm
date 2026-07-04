#import "./libs/zeropage.asm"
#import "./libs/macros.asm"
#import "./libs/vic.asm"
BasicUpstart2(Entry)
#import "./libs/screen.asm"
#import "./libs/keyboard_io.asm"
#import "./libs/keyboard.asm"
#import "./libs/irq.asm"
#import "./libs/setup.asm"
#import "./libs/utils.asm"

#import "./libs/dinosaur.asm"

Entry:
			jsr Random.init
			jsr Setup.init
			jsr Dinosaur.Setup
			//note: Setup.init already draws the land (and primes the
			//incoming-tile column); drawing it twice would misalign it

			//Bank out BASIC and Kernal ROM before enabling the raster IRQ —
			//with the ROM banked in, an IRQ would be dispatched through the
			//Kernal handler, which never acks $d019
			lda $01
			and #%11111000
			ora #%00000101
			sta $01

			jsr IRQ.Setup
			jmp *


#import "./libs/charset.asm"