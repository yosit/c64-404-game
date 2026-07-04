
// 5 sprites generated with spritemate on 12/24/2019, 10:25:46 AM
// Byte 64 of each sprite contains multicolor (high nibble) & color (low nibble) information



// sprite 0 / singlecolor / color: $03
// Redrawn 2026-07-04 — source: tools/sprites/dino.txt (make_sprite.py)
din_stand:
.byte $00,$01,$fc,$00,$01,$fc,$00,$01
.byte $bc,$00,$01,$fc,$00,$01,$fc,$00
.byte $03,$f8,$80,$03,$f0,$c0,$07,$e0
.byte $e0,$0f,$e0,$70,$1f,$e0,$3c,$3f
.byte $e0,$1e,$7f,$e0,$0f,$ff,$d8,$07
.byte $ff,$e0,$03,$ff,$c0,$03,$ff,$80
.byte $03,$ff,$00,$01,$ce,$00,$01,$ce
.byte $00,$01,$ce,$00,$03,$cf,$00,$03

// sprite 1 / singlecolor / color: $03
din_walk_0:
.byte $00,$01,$fc,$00,$01,$fc,$00,$01
.byte $bc,$00,$01,$fc,$00,$01,$fc,$00
.byte $03,$f8,$80,$03,$f0,$c0,$07,$e0
.byte $e0,$0f,$e0,$70,$1f,$e0,$3c,$3f
.byte $e0,$1e,$7f,$e0,$0f,$ff,$d8,$07
.byte $ff,$e0,$03,$ff,$c0,$03,$ff,$80
.byte $03,$ff,$00,$01,$ce,$00,$01,$ce
.byte $00,$00,$ce,$00,$00,$4f,$00,$03

// sprite 2 / singlecolor / color: $03
din_walk_1:
.byte $00,$01,$fc,$00,$01,$fc,$00,$01
.byte $bc,$00,$01,$fc,$00,$01,$fc,$00
.byte $03,$f8,$80,$03,$f0,$c0,$07,$e0
.byte $e0,$0f,$e0,$70,$1f,$e0,$3c,$3f
.byte $e0,$1e,$7f,$e0,$0f,$ff,$d8,$07
.byte $ff,$e0,$03,$ff,$c0,$03,$ff,$80
.byte $03,$ff,$00,$01,$ce,$00,$01,$ce
.byte $00,$01,$cc,$00,$03,$c8,$00,$03

// sprite 3 / singlecolor / color: $03
sprite_0:
.byte $00,$00,$00,$00,$3f,$e0,$00,$2f
.byte $f0,$00,$3f,$f0,$00,$3f,$f0,$00
.byte $3e,$00,$00,$3f,$c0,$00,$3c,$00
.byte $40,$7c,$00,$40,$ff,$00,$61,$fd
.byte $00,$73,$fc,$00,$7f,$fc,$00,$7f
.byte $f8,$00,$3f,$f0,$00,$1f,$e0,$00
.byte $0f,$60,$00,$06,$20,$00,$04,$20
.byte $00,$06,$30,$00,$00,$00,$00,$03

// sprite 4 / singlecolor / color: $03
sprite_1:
.byte $ff,$ff,$ff,$ff,$c0,$1f,$ff,$d0
.byte $0f,$ff,$c0,$0f,$ff,$c0,$0f,$ff
.byte $c1,$ff,$ff,$c0,$3f,$ff,$c3,$ff
.byte $bf,$83,$ff,$bf,$00,$ff,$9e,$02
.byte $ff,$8c,$03,$ff,$80,$03,$ff,$80
.byte $07,$ff,$c0,$0f,$ff,$e0,$1f,$ff
.byte $f0,$9f,$ff,$f9,$df,$ff,$fb,$df
.byte $ff,$f9,$cf,$ff,$ff,$ff,$ff,$03

// ===================================================================
// WP-C appended sprites (pterodactyl + duck). APPEND-ONLY; order fixes
// the pointer values: $c5=$7140 duck A, $c6=$7180 duck B,
// $c7=$71c0 ptero flap A (wings up), $c8=$7200 ptero flap B (wings down).
// Single-color, 63 bytes + 1 meta byte (meta low nibble = color $03).
// ===================================================================

// sprite 5 / singlecolor / color: $03  (WP-C) duck frame A  ptr $c5
// Long low crouching dino, head forward (right). Art is bottom-aligned in
// the sprite cell (top pixel at sprite row 11) so at the unchanged dino
// ground Y=$8d its feet still sit on the ground line — duck Y offset = 0.
duck_a:
.byte $00,$00,$00,$00,$00,$00,$00,$00
.byte $00,$00,$00,$00,$00,$00,$00,$00
.byte $00,$00,$00,$00,$00,$00,$00,$00
.byte $00,$00,$00,$00,$00,$00,$00,$00
.byte $00,$00,$00,$3c,$00,$00,$7e,$0f
.byte $ff,$ee,$1f,$ff,$fa,$3f,$ff,$fc
.byte $3f,$ff,$ee,$1f,$ff,$de,$07,$03
.byte $40,$07,$03,$40,$0f,$07,$40,$03

// sprite 6 / singlecolor / color: $03  (WP-C) duck frame B  ptr $c6
// Same body as duck A, legs stepped (run-cadence animation swap).
duck_b:
.byte $00,$00,$00,$00,$00,$00,$00,$00
.byte $00,$00,$00,$00,$00,$00,$00,$00
.byte $00,$00,$00,$00,$00,$00,$00,$00
.byte $00,$00,$00,$00,$00,$00,$00,$00
.byte $00,$00,$00,$3c,$00,$00,$7e,$0f
.byte $ff,$ee,$1f,$ff,$fa,$3f,$ff,$fc
.byte $3f,$ff,$ee,$1f,$ff,$de,$03,$07
.byte $00,$03,$07,$00,$07,$0f,$00,$03

// sprite 7 / singlecolor / color: $03  (WP-C) ptero wings-up  ptr $c7
// Pterodactyl facing left (beak at left), wings raised above the body.
ptero_a:
.byte $00,$00,$00,$00,$00,$00,$00,$00
.byte $00,$00,$00,$00,$00,$00,$00,$00
.byte $f0,$f0,$00,$79,$c0,$00,$3f,$30
.byte $0f,$ff,$30,$ff,$7f,$a0,$3f,$7f
.byte $80,$03,$7f,$00,$00,$fc,$00,$00
.byte $70,$00,$00,$60,$00,$00,$00,$00
.byte $00,$00,$00,$00,$00,$00,$00,$00
.byte $00,$00,$00,$00,$00,$00,$00,$03

// sprite 8 / singlecolor / color: $03  (WP-C) ptero wings-down ptr $c8
// Same body core, wings lowered below the body (flap frame B).
ptero_b:
.byte $00,$00,$00,$00,$00,$00,$00,$00
.byte $00,$00,$00,$00,$00,$00,$00,$00
.byte $00,$00,$00,$00,$00,$00,$00,$00
.byte $0f,$ff,$30,$ff,$7f,$a0,$3f,$7f
.byte $80,$03,$7f,$00,$00,$ff,$60,$00
.byte $79,$c0,$00,$30,$70,$00,$00,$38
.byte $00,$00,$00,$00,$00,$00,$00,$03

// ===== WP-A: dead dino (sprite pointer $c9) =====
// Self-located at $7000 + 9*64 = $7240 so its pointer value is exactly $c9.
// Follows WP-C's $c5-$c8 (which end at $723f), so the PC is already at $7240
// here — the explicit address just documents/pins it. WP-E's clouds ($ca,$cb)
// append after this at $7280/$72c0. Derived from din_stand, eye X-ed out.
* = $7000 + 9*64 "din_dead"
din_dead:
.byte $00,$3f,$f0,$00,$40,$10,$00,$54
.byte $08,$00,$48,$08,$00,$54,$08,$00
.byte $41,$f8,$00,$40,$20,$60,$c3,$e0
.byte $a1,$83,$80,$a3,$00,$80,$9e,$02
.byte $80,$8c,$03,$80,$80,$02,$00,$80
.byte $04,$00,$40,$0c,$00,$20,$18,$00
.byte $10,$98,$00,$19,$50,$00,$0a,$50
.byte $00,$09,$48,$00,$0f,$78,$00,$03

// ---------------------------------------------------------------------------
// WP-E clouds — APPENDED AT THE END. Integration concatenates all WP appends
// in pointer order, so in the merged build these become the last two 64-byte
// sprite blocks and land at pointers $ca / $cb ($7000 + $ca*64 = $7280 etc.).
// Single-color, drawn light grey (VIC.SPRITE_COLOR_2/3). Puffy cloud shapes,
// pixels only in the top ~11 rows so the visible blob sits high on screen.
// ---------------------------------------------------------------------------

// $ca cloud A (wider puff)
cloud_a:
.byte $00,$00,$00,$00,$00,$00,$07,$c0
.byte $00,$0f,$f0,$00,$1f,$f8,$00,$3f
.byte $fe,$00,$7f,$ff,$80,$7f,$ff,$c0
.byte $3f,$ff,$e0,$0f,$ff,$c0,$01,$fe
.byte $00,$00,$00,$00,$00,$00,$00,$00
.byte $00,$00,$00,$00,$00,$00,$00,$00
.byte $00,$00,$00,$00,$00,$00,$00,$00
.byte $00,$00,$00,$00,$00,$00,$00,$0f

// $cb cloud B (smaller puff)
cloud_b:
.byte $00,$00,$00,$00,$00,$00,$00,$00
.byte $00,$03,$e0,$00,$07,$f8,$00,$0f
.byte $fc,$00,$1f,$fe,$00,$3f,$ff,$00
.byte $3f,$ff,$00,$1f,$fe,$00,$03,$f0
.byte $00,$00,$00,$00,$00,$00,$00,$00
.byte $00,$00,$00,$00,$00,$00,$00,$00
.byte $00,$00,$00,$00,$00,$00,$00,$00
.byte $00,$00,$00,$00,$00,$00,$00,$0f
