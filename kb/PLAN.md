# Plan — road to full Chrome-404-dino parity

Ordered by dependency. Tick items as they land; details/gotchas go in
[NAPKIN.md](NAPKIN.md).

## Milestone 1 — it becomes a game

- [ ] **Cacti obstacles** as chars (not sprites) so they ride the existing
      char scroll for free. Cactus tiles in charset, fed through
      `FeedTileColumn` (needs row(s) above the land strip). Random spacing
      with a minimum gap so every pattern is jumpable.
- [ ] **Collision → game over**: un-stub `Dinosaur.detect_collision` —
      hardware sprite-to-background register $d01f (already read there).
      On hit: COLLISION state, freeze scroll, dead-dino frame.
- [ ] **Restart**: space from COLLISION resets land/score/speed → RUNNING.

## Milestone 2 — replayability

- [ ] **Score**: distance counter, char digits top-right, blink every 100.
- [ ] **High score** in RAM, shown next to score (HI xxxxx).
- [ ] **Progressive speed**: auto-increment `Screen.speed` (cap 7) by score;
      z/x debug keys already exercise the mechanism.

## Milestone 3 — full mechanics

- [ ] **Pterodactyl**: sprite 1, 2 flap frames, spawns at 2–3 heights after
      a score threshold; sprite-sprite collision via $d01e.
- [ ] **Duck**: duck-run sprite frames, down key / joystick down, to dodge
      high pterodactyls.

## Milestone 4 — polish

- [ ] **Clouds**: slow parallax sprites.
- [ ] **Day/night**: flip bg/char colors at score thresholds.
- [ ] **SID sound**: jump blip, milestone blip, crash noise.
- [ ] **Idle/start state**: standing dino, "press space" to start
      (STANDING state exists, unused).
- [ ] **Housekeeping**: irq.asm `and #$ff` no-ops, DrawTile carry fragility,
      dead vars (delay/SCROLL_DELAY/scrolledTile), DISOSAUR typo, joystick
      support ($dc01 label already in vic.asm).

## Status

- (2026-07-04) Plan created. Base engine solid: run/jump states, seamless
  char scroll (FeedTileColumn), IRQ chain, clamped debug speed keys.
