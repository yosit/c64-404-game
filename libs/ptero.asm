// Pterodactyl module (WP-C). Hardware sprite slot 1 is ours.
// Public interface (LOCKED): Ptero.Update, Ptero.Reset.
//
// Behaviour:
//  - Spawns from the right once Score.score (BCD, 3 bytes LE) exceeds 300,
//    on a randomized cooldown, at one of two heights:
//      * PTERO_Y_HIGH ($85) — head height, overlaps the running dino's head
//        but passes ABOVE the crouched duck sprite -> forces a duck (or jump).
//      * PTERO_Y_LOW  ($90) — near the ground, overlaps both running and
//        ducking dino -> forces a jump.
//  - Fairness: does not spawn while a cactus char (CACTUS_FIRST..CACTUS_LAST)
//    sits in the entry third of the top land row (cols 30-39). Simplification:
//    only the top land row is scanned (cactus tops live there).
//  - Moves left by (Screen.speed+1) px/frame (slightly faster than ground),
//    9-bit X via the $d010 MSB (sprite 1 = bit 1). Flap frame swaps every
//    FLAP_PERIOD frames. Deactivates + hides sprite 1 past the left edge.
//  - C3 collision: reads $d01e ONCE per frame (reads clear it); dino=sprite0
//    (bit0), ptero=sprite1 (bit1); both set -> jsr Game.Crash. Higher bits
//    (clouds, sprites 2/3, kept above Y 60 by WP-E) are ignored.
* = * "Ptero"
Ptero: {
	.label PTR_A          = $c7			//wings-up flap frame  ($71c0)
	.label PTR_B          = $c8			//wings-down flap frame ($7200)
	.label PTERO_Y_HIGH   = $85			//head height  -> must duck (or jump)
	.label PTERO_Y_LOW    = $90			//ground height -> must jump
	.label FLAP_PERIOD    = 16			//frames between wing-flap swaps
	.label LEFT_EDGE      = $08			//deactivate once 9-bit X drops below this
	.label SPAWN_X_LO     = $54			//spawn 9-bit X = $0154 (=340), just off
	.label SPAWN_X_HI     = $01			//   the right border
	.label CACTUS_FIRST   = 45			//obstacle char range (WP-A resource table)
	.label CACTUS_LAST    = 89
	.label ENABLE_BIT     = %00000010	//sprite 1 enable / MSB mask
	.label ZP_STEP        = $0c			//WP-C scratch (ZP $0c-$0f)

	Update: {
			//C3: single reader of $d01e per frame (reads clear it).
			lda $d01e
			and #%00000011
			cmp #%00000011			//dino(bit0) AND ptero(bit1) both hit
			bne noHit
			jsr Game.Crash
	noHit:
			lda active
			bne moving
			jmp trySpawn

	moving:
			//step = Screen.speed + 1 (ptero drifts a touch faster than land)
			lda Screen.speed
			clc
			adc #$01
			sta ZP_STEP
			//x (16-bit LE) -= step
			lda x_lo
			sec
			sbc ZP_STEP
			sta x_lo
			lda x_hi
			sbc #$00
			sta x_hi
			bmi deactivate			//MSB underflowed past 0 -> off the left edge
			bne onScreen			//x_hi still 1 -> well onto the right half
			lda x_lo
			cmp #LEFT_EDGE
			bcc deactivate
	onScreen:
			//flap animation every FLAP_PERIOD frames
			dec flap_counter
			bne writeSprite
			lda #FLAP_PERIOD
			sta flap_counter
			lda frame
			eor #(PTR_A ^ PTR_B)	//toggle $c7<->$c8
			sta frame
	writeSprite:
			lda frame
			sta VIC.SPRITE_1_POINTER
			lda x_lo
			sta VIC.SPRITE_1_X
			//set/clear the sprite-1 X MSB (bit 1 of $d010)
			lda x_hi
			beq clrMsb
			lda VIC.SPRITE_MSB
			ora #ENABLE_BIT
			sta VIC.SPRITE_MSB
			rts
	clrMsb:
			lda VIC.SPRITE_MSB
			and #(ENABLE_BIT ^ $ff)
			sta VIC.SPRITE_MSB
			rts

	deactivate:
			jsr deactivateAndCooldown
			rts

	trySpawn:
			lda spawn_timer
			beq checkScore
			dec spawn_timer
			rts
	checkScore:
			//spawn once score > 300 (BCD, little-endian 3 bytes).
			lda Score.score+2
			bne scoreOk				//any ten-thousands digit -> well over 300
			lda Score.score+1
			cmp #$03				//hundreds/thousands pair >= $03 -> >= 300
			bcs scoreOk
			rts						//too low; recheck next frame (timer already 0)
	scoreOk:
			jsr cactusInEntry		//fairness guard
			bne blocked
			jsr spawn
			rts
	blocked:
			lda #$10				//brief wait, then re-check the entry lane
			sta spawn_timer
			rts
	}

	//Activate a fresh ptero at the right edge, random height, sprite enabled.
	spawn: {
			lda #$01
			sta active
			lda #SPAWN_X_LO
			sta x_lo
			lda #SPAWN_X_HI
			sta x_hi
			//pick height from one random bit
			jsr Random
			and #%00000001
			beq useHigh
			lda #PTERO_Y_LOW
			jmp setY
	useHigh:
			lda #PTERO_Y_HIGH
	setY:
			sta VIC.SPRITE_1_Y
			lda #PTR_A
			sta frame
			sta VIC.SPRITE_1_POINTER
			lda #FLAP_PERIOD
			sta flap_counter
			lda #$01				//white
			sta VIC.SPRITE_COLOR_1
			//enable sprite 1 + prime X / MSB
			lda VIC.SPRITE_ENABLE
			ora #ENABLE_BIT
			sta VIC.SPRITE_ENABLE
			lda x_lo
			sta VIC.SPRITE_1_X
			lda VIC.SPRITE_MSB
			ora #ENABLE_BIT
			sta VIC.SPRITE_MSB
			rts
	}

	//Deactivate during play: clear flag, hide hw sprite, set a random gap.
	deactivateAndCooldown: {
			lda #$00
			sta active
			jsr disableSprite1
			jsr Random
			and #%01111111
			clc
			adc #$40				//64..191 frame gap before the next ptero
			sta spawn_timer
			rts
	}

	//Hardware-only: disable sprite 1 and clear its X MSB.
	disableSprite1: {
			lda VIC.SPRITE_ENABLE
			and #(ENABLE_BIT ^ $ff)
			sta VIC.SPRITE_ENABLE
			lda VIC.SPRITE_MSB
			and #(ENABLE_BIT ^ $ff)
			sta VIC.SPRITE_MSB
			rts
	}

	//Return A!=0 if a cactus char occupies cols 30-39 of the top land row.
	cactusInEntry: {
			ldx #$00
	loop:
			lda Screen.LandStartAddress+30,x
			cmp #CACTUS_FIRST
			bcc next					//< first -> not a cactus
			cmp #CACTUS_LAST+1
			bcs next					//> last  -> not a cactus
			lda #$01
			rts
	next:
			inx
			cpx #10
			bne loop
			lda #$00
			rts
	}

	//Full reset — called from Game.Reset. Deactivate + hide sprite 1.
	Reset: {
			lda #$00
			sta active
			lda #$20
			sta spawn_timer				//short delay after a restart
			lda #PTR_A
			sta frame
			lda #FLAP_PERIOD
			sta flap_counter
			jsr disableSprite1
			rts
	}

* = * "Ptero data"
	active:      .byte $00			//0 = idle/off-screen, 1 = flying
	x_lo:        .byte $00			//9-bit X, low byte
	x_hi:        .byte $00			//9-bit X, high byte (0 or 1 = $d010 MSB)
	frame:       .byte PTR_A		//current sprite pointer ($c7/$c8)
	flap_counter: .byte FLAP_PERIOD	//frames until next wing swap
	spawn_timer: .byte $20			//cooldown before next spawn
}
