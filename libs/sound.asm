// SID sound module. Phase-0 stub — WP-D fills the body. Sound is the ONLY
// consumer of Game.events: it reads the flags each frame and clears them.
// Owns $d400-$d406 (voice 1) and $d418 (volume); nobody else touches SID.
// Public interface (LOCKED): Sound.Update, Sound.Init.
* = * "Sound"
Sound: {
	Update: {
			lda #$00			//stub: consume + clear events so they don't linger
			sta Game.events
			rts
	}

	Init: {
			rts
	}
}
