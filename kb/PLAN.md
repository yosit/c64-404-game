# Plan — road to full Chrome-404-dino parity

Ordered by dependency. Tick items as they land; details/gotchas go in
[NAPKIN.md](NAPKIN.md).

## Milestone 1 — it becomes a game

- [x] **Cacti obstacles** as chars fed through `FeedTileColumn` (WP-A). Tiles
      5/6/7 (chars 45–71), ~1/6 odds with an 8-tile min gap.
- [x] **Collision → game over**: `Dinosaur.detect_collision` reads $d01f once/
      frame; on hit → `Game.Crash` (ST_DEAD, dead sprite $c9, GAME OVER banner,
      scroll frozen).
- [x] **Restart**: space in ST_DEAD → `Game.Reset` → RUNNING (context-sensitive
      `set_jump`, keeps keyboard.asm untouched).

## Milestone 2 — replayability

- [x] **Score**: 3-byte BCD, digits at row 0 cols 34–38, blink every 100 (WP-B).
- [x] **High score** (survives restart), "HI xxxxx" at cols 24–32.
- [x] **Progressive speed**: `Screen.speed` +1 per 100 pts, cap 7. z/x keys kept.

## Milestone 3 — full mechanics

- [x] **Pterodactyl** (WP-C): hw sprite 1, 2 flap frames ($c7/$c8), spawns after
      score>300 at 2 heights; $d01e sprite-sprite collision → Game.Crash.
- [x] **Duck** (WP-C): duck frames $c5/$c6, `Dinosaur.set_duck`/`set_run`,
      recommended joystick-2 down. NOTE: key still needs wiring into Input
      (keyboard.asm) — see NAPKIN "Integration TODOs".

## Milestone 4 — polish

- [x] **Clouds** (WP-E): parallax hw sprites 2/3 ($ca/$cb), Y<60.
- [x] **Day/night** (WP-E): $d021 flips at 500-pt bands; grey color RAM keeps
      text legible on black. Writes only on transition (regression fix).
- [x] **SID sound** (WP-D): jump/milestone/crash on voice 1 (needs human audio
      check via `make debug`).
- [x] **Idle/start state** (WP-A): boots ST_IDLE, first space starts.
- [~] **Housekeeping**: irq.asm `and #$ff` no-ops FIXED; multiplyby9 comment
      FIXED; DINOSAUR typo fixed. STILL OPEN: DrawTile carry fragility, dead
      vars (delay/SCROLL_DELAY/scrolledTile), joystick support. inc/dec $d020
      raster-cycle debug KEPT (user uses it as a cycle meter — do not remove).

## Status

- (2026-07-04) Plan created. Base engine solid: run/jump states, seamless
  char scroll (FeedTileColumn), IRQ chain, clamped debug speed keys.
