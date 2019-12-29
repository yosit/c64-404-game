VIC: {
	.label SPRITE_0_POINTER = SCREEN_RAM + $03f8
	.label SPRITE_1_POINTER = SPRITE_0_POINTER + 1
	.label SPRITE_2_POINTER = SPRITE_0_POINTER + 2
	.label SPRITE_3_POINTER = SPRITE_0_POINTER + 3
	.label SPRITE_4_POINTER = SPRITE_0_POINTER + 4
	.label SPRITE_5_POINTER = SPRITE_0_POINTER + 5
	.label SPRITE_6_POINTER = SPRITE_0_POINTER + 6
	.label SPRITE_7_POINTER = SPRITE_0_POINTER + 7

	.label SPRITE_0_X = $d000
	.label SPRITE_0_Y = $d001

	.label SPRITE_1_X = $d002
	.label SPRITE_1_Y = $d003

	.label SPRITE_2_X = $d004
	.label SPRITE_2_Y = $d005

	.label SPRITE_3_X = $d006
	.label SPRITE_3_Y = $d007

	.label SPRITE_4_X = $d008
	.label SPRITE_4_Y = $d009

	.label SPRITE_5_X = $d00a
	.label SPRITE_5_Y = $d00b

	.label SPRITE_6_X = $d00c
	.label SPRITE_6_Y = $d00d

	.label SPRITE_7_X = $d00e
	.label SPRITE_7_Y = $d00f

	.label SPRITE_MSB = $d010

	.label RASTER_Y = $d012 

	.label SPRITE_ENABLE = $d015
	.label SCREEN_CONTROL_2 = $d016

	.label MEMORY_SETUP = $d018

	.label INTERRUPT_CONTROL = $d01a
	
	.label SPRITE_MULTICOLOR = $d01c

	.label BORDER_COLOR = $d020
	.label BACKGROUND_COLOR = $d021
	.label EXTENDED_BG_COLOR_1 = $d022
	.label EXTENDED_BG_COLOR_2 = $d023

	.label SPRITE_MULTICOLOR_1 = $d025
	.label SPRITE_MULTICOLOR_2 = $d026

	.label SPRITE_COLOR_0 = $d027
	.label SPRITE_COLOR_1 = $d028
	.label SPRITE_COLOR_2 = $d029
	.label SPRITE_COLOR_3 = $d02a
	.label SPRITE_COLOR_4 = $d02b
	.label SPRITE_COLOR_5 = $d02c
	.label SPRITE_COLOR_6 = $d02d
	.label SPRITE_COLOR_7 = $d02e

	//.label COLOR_RAM = $d800
	.label SCREEN_RAM = $5000

	.label JOYSTICK_1 = $dc01
	.label BANK = $dd00
}