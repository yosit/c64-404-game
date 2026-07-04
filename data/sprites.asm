
// 5 sprites generated with spritemate on 12/24/2019, 10:25:46 AM
// Byte 64 of each sprite contains multicolor (high nibble) & color (low nibble) information



// sprite 0 / singlecolor / color: $03
din_stand:
.byte $00,$3f,$f0,$00,$40,$10,$00,$50
.byte $08,$00,$40,$08,$00,$40,$08,$00
.byte $41,$f8,$00,$40,$20,$60,$c3,$e0
.byte $a1,$83,$80,$a3,$00,$80,$9e,$02
.byte $80,$8c,$03,$80,$80,$02,$00,$80
.byte $04,$00,$40,$0c,$00,$20,$18,$00
.byte $10,$98,$00,$19,$50,$00,$0a,$50
.byte $00,$09,$48,$00,$0f,$78,$00,$03

// sprite 1 / singlecolor / color: $03
din_walk_0:
.byte $00,$3f,$f0,$00,$40,$10,$00,$50
.byte $08,$00,$40,$08,$00,$40,$08,$00
.byte $41,$f8,$00,$40,$20,$60,$c3,$e0
.byte $a1,$83,$80,$a3,$00,$80,$9e,$02
.byte $80,$8c,$03,$80,$80,$02,$00,$80
.byte $04,$00,$40,$0c,$00,$20,$18,$00
.byte $10,$cc,$00,$19,$78,$00,$0a,$00
.byte $00,$09,$00,$00,$0f,$00,$00,$03

// sprite 2 / singlecolor / color: $03
din_walk_1:
.byte $00,$3f,$f0,$00,$40,$10,$00,$50
.byte $08,$00,$40,$08,$00,$40,$08,$00
.byte $41,$f8,$00,$40,$20,$60,$c3,$e0
.byte $a1,$83,$80,$a3,$00,$80,$9e,$02
.byte $80,$8c,$03,$80,$80,$02,$00,$80
.byte $04,$00,$40,$0c,$00,$20,$18,$00
.byte $11,$98,$00,$18,$d0,$00,$0f,$50
.byte $00,$00,$48,$00,$00,$78,$00,$03

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