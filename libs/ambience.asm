// Clouds (parallax) + day/night cycle — WP-E.
// Public interface (LOCKED): Ambience.Update, Ambience.Reset, Ambience.InitColors.
//
// Clouds: HARDWARE sprite slots 2 and 3 (X=$d004/5, $d006/7; enable bits 2,3
//   in $d015; pointers VIC.SPRITE_2/3_POINTER = $ca,$cb). They drift LEFT much
//   slower than the ground (cloud A 1px every 2nd frame, cloud B 1px every 3rd
//   frame) for a parallax effect, respawning off the right edge with a random
//   Y and gap. HARD CEILING: Y stays < 60 (and Y+21 < 91, the jump apex) so a
//   cloud can NEVER overlap the dino — this keeps sprite-sprite $d01e clean for
//   WP-C (clouds never contribute a false collision bit).
//
// Day/night: watches Score.score (3-byte BCD, little-endian). Night runs for a
//   250-point window starting at every 500-point boundary:
//     day  [0,500) [750,1000) [1250,1500) ...
//     night [500,750) [1000,1250) [1500,1750) ...
//   i.e. night  <=>  score >= 500  AND  (score mod 500) < 250.
//   Night flips background $d021 to black; day restores blue. Border $d020 is
//   also set (see note) but it is the IRQ timing-debug register (inc/dec'd each
//   raster band) so accept the flicker. Land/score chars stay legible in both
//   phases because InitColors paints color RAM light grey once at Setup.
* = * "Ambience"
Ambience: {
	.label CLOUD_A_PTR   = $ca
	.label CLOUD_B_PTR   = $cb
	.label COLOR_LAND    = $0f			//light grey — readable on both day (blue) and night (black)
	.label CLOUD_COLOR   = $0f			//light grey clouds
	.label DAY_BG        = $06			//blue background (matches the original look)
	.label NIGHT_BG      = $00			//black background
	// Border is written from inside MainIRQ AFTER its `inc $d020`; MainIRQ's
	// closing `dec $d020` then subtracts 1, so the border RESTS at (written-1).
	// Pre-increment the target by 1 so the resting color is what we want:
	.label DAY_BORDER    = $0f			//rests at $0e (light blue) — matches baseline
	.label NIGHT_BORDER  = $01			//rests at $00 (black)

	Update: {
			jsr UpdateClouds
			jsr UpdateDayNight
			rts
	}

	// Full reset (from Game.Reset on restart): back to day, reposition clouds.
	Reset: {
			lda #$00
			sta nightFlag
			lda #DAY_BG
			sta VIC.BACKGROUND_COLOR
			jsr InitClouds
			rts
	}

	// Called once from Setup. Paints color RAM light grey for rows 0-15 (land +
	// score legibility in both phases), sets the day background, and brings the
	// two cloud sprites online (pointers, colors, single-colour, enable, pos).
	InitColors: {
			// color RAM ($d800, fixed hardware) rows 0-15 = 640 cells -> grey.
			ldx #$00
		!:
			lda #COLOR_LAND
			sta $d800,x
			sta $d900,x
			sta $da00,x				//$d800..$daff = 768 cells (covers rows 0-19)
			inx
			bne !-

			// day background to start
			lda #DAY_BG
			sta VIC.BACKGROUND_COLOR
			lda #$00
			sta nightFlag

			// cloud sprite pointers
			lda #CLOUD_A_PTR
			sta VIC.SPRITE_2_POINTER
			lda #CLOUD_B_PTR
			sta VIC.SPRITE_3_POINTER

			// cloud colors (light grey)
			lda #CLOUD_COLOR
			sta VIC.SPRITE_COLOR_2
			sta VIC.SPRITE_COLOR_3

			// single-colour for sprites 2,3 (clear their multicolor bits)
			lda VIC.SPRITE_MULTICOLOR
			and #%11110011
			sta VIC.SPRITE_MULTICOLOR

			// enable sprites 2 and 3 (leave 0=dino, 1=ptero as-is)
			lda VIC.SPRITE_ENABLE
			ora #%00001100
			sta VIC.SPRITE_ENABLE

			jsr InitClouds
			rts
	}

	// Position both clouds and reset their parallax dividers. Cloud A starts on
	// the right, cloud B mid-screen, so they are visibly at different X.
	InitClouds: {
			lda #$18				//cloud A: X = 256+$18 = 280
			sta cxLo+0
			lda #$01
			sta cxHi+0
			lda #45					//cloud A Y (< 60, Y+21 < 91)
			sta cy+0

			lda #$78				//cloud B: X = 120
			sta cxLo+1
			lda #$00
			sta cxHi+1
			lda #55					//cloud B Y
			sta cy+1

			lda #$00
			sta cdiv+0
			sta cdiv+1
			jsr WriteCloudHW
			rts
	}

	UpdateClouds: {
			ldx #$00
			jsr StepCloud			//cloud A (index 0): moves every 2nd frame
			ldx #$01
			jsr StepCloud			//cloud B (index 1): moves every 3rd frame
			jsr WriteCloudHW
			rts
	}

	// Advance one cloud (X = cloud index). Increments the per-cloud divider; when
	// it reaches cdivmax[X] it decrements the 9-bit X by 1 and, if the cloud has
	// scrolled off the left, respawns it on the right with random Y and gap.
	StepCloud: {
			inc cdiv,x
			lda cdiv,x
			cmp cdivmax,x
			bcc done				//not time to move yet
			lda #$00
			sta cdiv,x
			// decrement 9-bit X (cxLo/cxHi)
			lda cxLo,x
			sec
			sbc #$01
			sta cxLo,x
			lda cxHi,x
			sbc #$00
			sta cxHi,x
			// off-left? (xHi==0 AND xLo < 8 -> mostly behind left border)
			lda cxHi,x
			bne done				//X >= 256, on-screen
			lda cxLo,x
			cmp #$08
			bcs done
			// respawn on the right: X = $154 + rnd(0..127) = 340..467
			lda #$01
			sta cxHi,x
			jsr Random
			and #%01111111
			clc
			adc #$54
			sta cxLo,x
			// random Y: 40..55 (stays < 60, Y+21 < 91)
			jsr Random				//Random preserves X
			and #%00001111
			clc
			adc #40
			sta cy,x
		done:
			rts
	}

	// Push cloud state to the VIC hardware registers (positions + 9-bit MSBs).
	WriteCloudHW: {
			lda cxLo+0
			sta VIC.SPRITE_2_X
			lda cy+0
			sta VIC.SPRITE_2_Y
			lda cxLo+1
			sta VIC.SPRITE_3_X
			lda cy+1
			sta VIC.SPRITE_3_Y
			// 9-bit MSB: bit2 = cloud A, bit3 = cloud B
			lda VIC.SPRITE_MSB
			and #%11110011			//clear bits 2,3 (do not disturb dino/ptero)
			ldx cxHi+0
			beq !+
			ora #%00000100
		!:
			ldx cxHi+1
			beq !+
			ora #%00001000
		!:
			sta VIC.SPRITE_MSB
			rts
	}

	// Day/night from Score.score (BCD LE). See header for the window scheme.
	UpdateDayNight: {
			// score >= 500 ?  (byte2 != 0)  OR  (byte1 >= $05, i.e. >= hundreds 5)
			lda Score.score+2
			bne inNightBand
			lda Score.score+1
			cmp #$05
			bcc setDay				//byte1 < $05 -> score < 500 -> day

		inNightBand:
			// night-in-band from the hundreds digit (low nibble of byte1):
			//   nightByHundreds[D2]: 0=day, 1=night, 2=night-if-tens<5
			lda Score.score+1
			and #%00001111
			tax
			lda nightByHundreds,x
			beq setDay
			cmp #$02
			bne setNight			//code 1 -> night
			// code 2 -> night only if tens digit (high nibble of byte0) < 5
			lda Score.score+0
			and #%11110000
			cmp #$50
			bcc setNight			//tens < 5 -> night
			// tens >= 5 -> day, fall through

		setDay:
			lda #DAY_BG
			sta VIC.BACKGROUND_COLOR
			lda #DAY_BORDER
			sta VIC.BORDER_COLOR
			lda #$00
			sta nightFlag
			rts

		setNight:
			lda #NIGHT_BG
			sta VIC.BACKGROUND_COLOR
			lda #NIGHT_BORDER
			sta VIC.BORDER_COLOR
			lda #$ff
			sta nightFlag
			rts
	}

// -------- module-local state --------
	nightFlag: .byte $00			//$00 = day, $ff = night

	// per-cloud arrays, index 0 = cloud A (sprite 2), 1 = cloud B (sprite 3)
	cxLo:    .byte $18, $78			//9-bit X low byte
	cxHi:    .byte $01, $00			//9-bit X high bit (0/1)
	cy:      .byte 45, 55			//Y (< 60)
	cdiv:    .byte $00, $00			//parallax frame counter
	cdivmax: .byte $02, $03			//move when cdiv reaches this (2nd / 3rd frame)

	// night-in-band lookup by hundreds digit (D2): see UpdateDayNight
	// D2:            0 1 2 3 4 5 6 7 8 9
	nightByHundreds: .byte 1,1,2,0,0,1,1,2,0,0
}
