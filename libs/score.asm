// Score / high-score module. Phase-0 stub — WP-B fills the body.
// Public interface (LOCKED): Score.Update, Score.Reset, and the two BCD
// counters below. score/hiscore are 3 bytes BCD, little-endian (byte 0 =
// least significant pair of digits).
* = * "Score"
Score: {
	Update: {
			rts
	}

	// Reset the running score only — hiscore SURVIVES restarts (WP-B).
	Reset: {
			rts
	}

	Init: {
			rts
	}

	score:   .byte $00, $00, $00
	hiscore: .byte $00, $00, $00
}
