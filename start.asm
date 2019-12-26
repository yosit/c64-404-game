#import  "./libs/vic.asm"
#import "./libs/setup.asm"

BasicUpstart2(Entry)


Entry:
			jsr Setup.ClearScreen
			jmp SetupSprites
			rts

SetupSprites:
			lda #$c0
			lda #INITIAL_SETTINGS.SPRITE_0_X_INDEX
			sta VIC.SPRITE_0_POINTER

			lda #INITIAL_SETTINGS.SPRITE_0_X_INITIAL_POSITION
			sta VIC.SPRITE_0_X
			lda #INITIAL_SETTINGS.SPRITE_0_Y_INITIAL_POSITION
			sta VIC.SPRITE_0_Y

			lda VIC.SPRITE_ENABLE
			ora #$01
			sta VIC.SPRITE_ENABLE
			
			lda #$08 // sprite multicolor 1
			sta $D025
			lda #$06 // sprite multicolor 2
			sta $D026
			rts

* = $3000 "sprites"
	#import  "./data/sprites.asm"


