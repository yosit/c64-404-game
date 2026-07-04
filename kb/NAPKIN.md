# Napkin KB — C64 404 Dino Game

Quick, informal notes. Updated as we go. Newest decisions at the top of each
section; prune anything that stops being true.

## What this is

A replica of the Chrome "404 dinosaur" runner game for the Commodore 64,
written in 6502 assembly with KickAssembler. Runs in VICE (`x64sc`) or
Retro Debugger.

## Build / run

- `make build` → assembles `Startup.asm` into `bin/404.prg` (+ VICE symbols)
- `make run` → VICE; `make debug` → Retro Debugger with symbols
- KickAss.jar expected at `~/.local/kickass/KickAss.jar`

## Code map

- `Startup.asm` — entry point: inits Random, Setup, Dinosaur, draws land,
  installs IRQ, banks out BASIC+Kernal ($01 = %xxxxx101), then `jmp *`
  (everything after that runs in the raster IRQ).
- `libs/dinosaur.asm` — dino sprite logic; state machine flags:
  STANDING %0001, RUNNING %0010, JUMPING %0100, COLLISION %1000.
- `libs/irq.asm` — raster IRQ at line $20, vectors via $fffe/$ffff
  (Kernal banked out, so hardware vectors, not $0314/$0315).
- `libs/keyboard.asm` + `libs/keyboard_io.asm` — TWW/CTR non-Kernal keyboard
  scan (codebase64). 'x' increments `Screen.speed`, 'z' decrements (debug
  speed control).
- `libs/screen.asm` — land drawing / scrolling, `Screen.speed`.
- `libs/charset.asm` — binary imports: charset at $4000, map after it,
  sprites at $7000.
- `libs/zeropage.asm`, `macros.asm`, `vic.asm`, `setup.asm`, `utils.asm` —
  support code. `macros.asm` has `multiplyby9` (misnamed comment says "by 3"),
  StoreState/RestoreState.
- `data/` — charset/map/color binaries (VChar64 project), `dinosour.spm`
  sprites (SpritePad), `sprites.asm`.

## Memory layout (as of now)

- $4000 charset, map right after
- $7000 sprites
- Keyboard scan scratch: $50–$5f (zeropage, per keyboard_io.asm)

## Phase 0 — integration contract (LANDED 2026-07-04)

The sequential contract layer from IMPLEMENTATION-PLAN §3 is done. Interfaces
below are LOCKED; parallel WPs plug into them without editing each other.

- **State machine is a jump table now.** `Dinosaur.state` holds an ordinal:
  `ST_IDLE=0, ST_RUNNING=1, ST_JUMPING=2, ST_DUCKING=3, ST_DEAD=4` (all
  `.label` so they export across scopes — `.const` in a `{}` scope does NOT
  export, that was a build error). `Dinosaur.Update` dispatches via
  `StateHandlers` (.word table, RTS-trick, entries store handler-1).
  HandleIdle/HandleDucking/HandleDead are `rts` stubs for WPs to fill.
- **`libs/game.asm` is the hub.** MainIRQ calls ONLY `jsr Game.Update` (opens
  with `cld`). `Game.Update` fans out: Dinosaur → Input → Screen → Score →
  Ptero → Sound → Ambience. `Game.Reset` fans out every module's Reset.
  `Game.Crash` = crash entry point (producers call it): sets EV_CRASH +
  ST_DEAD. `Game.events` byte: EV_JUMP=%001, EV_MILESTONE=%010, EV_CRASH=%100,
  producers OR bits in, **Sound is the ONLY clearer** (runs last).
- **Stub modules** (Update/Reset = rts): score.asm (has `score`/`hiscore`,
  3 bytes BCD little-endian), ptero.asm, sound.asm, ambience.asm. Extra Init
  hooks called from Setup.init: `Ambience.InitColors`, `Sound.Init`,
  `Score.Init`. `Screen.Reset` redraws land + resets offset/speed/tileColumn.
- Import order in Startup.asm: score, ptero, sound, ambience, game (after
  dinosaur). Boot state still ST_RUNNING (WP-A flips to ST_IDLE for start
  screen). Verified: normal build pixel-identical to 6e1e54d; demo auto-jumps.

## Integration complete — all WPs merged (2026-07-04)

Phase 0 + WP-A..E merged (A→B→C→D→E) and verified headless. Full game loop
runs: idle → run → cacti/ptero → crash → GAME OVER → restart, with score,
high score, progressive speed, clouds, day/night, and SID sfx.

### New modules & flow
- `libs/game.asm` (hub): MainIRQ → `Game.Update` → Dinosaur, Input, Screen,
  Score, Ptero, Sound, Ambience. `Game.Reset` fans out; `Game.Crash` is the
  shared crash entry (dino-vs-cactus $d01f in dinosaur.asm, ptero $d01e in
  ptero.asm both call it). `Game.events` bus: EV_JUMP/MILESTONE/CRASH, Sound
  is the sole clearer (runs last).
- `score.asm` (WP-B), `ptero.asm` (WP-C), `sound.asm` (WP-D), `ambience.asm`
  (WP-E) — all filled.

### Char map (patched via tools/glyphs/*.txt at `make charset`)
- 0–44 land tiles 0–4 · 45–53 cactus tile 5 · 54–62 tile 6 · 63–71 tile 7
  (WP-A) · 174 existing · 176–185 digits 0–9 · 186–199 letters
  H I G A M E O V R (WP-B; blank glyph is **$ff**, NOT $20 — $20 is a land tile).

### Sprite map (data/sprites.asm, pointer = $c0 + block index)
- $c0–$c4 existing (dino stand/walk0/walk1 + 2 spare) · $c5/$c6 duck A/B ·
  $c7/$c8 ptero flap A/B (WP-C) · $c9 dead dino (WP-A, self-located $7240) ·
  $ca/$cb clouds A/B (WP-E). Append ORDER matters (positional pointers):
  c5,c6,c7,c8,c9,ca,cb.
- HW slots: 0 dino, 1 ptero (WP-C), 2/3 clouds (WP-E, Y<60 keeps $d01e clean),
  4–7 free.

### ZP allocation honored: $04–$07 WP-A (unused in the end), $08–$0b WP-B
(unused), $0c WP-C (ptero step), $10–$13 WP-D/E (unused; modules keep state in
non-ZP .byte). $02–$03 tile pos, $50–$5f keyboard.

### Regression found & fixed at integration
- **Black top band** (intermittent, heavy frames): WP-E's UpdateDayNight wrote
  $d020/$d021 EVERY frame from inside Game.Update (visible raster position),
  racing the inc/dec $d020 timing debug. Fixed: day/night writes background
  $d021 only on an actual transition, never touches the border. **The inc/dec
  $d020 raster-cycle debug is intentional (user's cycle meter) — do NOT remove
  it.** The grey side bars in screenshots are that meter, working as intended.
- GAME OVER blank char: WP-A used $20 (a land tile) for the space → fixed to $ff.

### Integration TODOs (not yet done)
- **Wire the duck key into Input** (keyboard.asm): call `Dinosaur.set_duck`
  while joystick-2 down (or a chosen key) is held, `Dinosaur.set_run` on
  release. Both guards are state-safe. Until then, duck is unreachable by a
  player (works in code/collision).
- Cosmetic: a cloud sprite can drift across the HI/score text (both up high) —
  harmless, sprite draws over the chars.
- Still-open housekeeping: DrawTile carry fragility, dead vars in screen.asm
  (delay/SCROLL_DELAY/scrolledTile), optional joystick jump support.
- SID audio needs a human listen via `make debug`.

## Decisions

- (2026-07-04) Keep a napkin KB in `kb/` — short notes, updated alongside
  changes, not formal docs.
- Speed implemented without delay loops (commit 67bbe1f), controlled at
  runtime via z/x keys for debugging.

## Review findings (2026-07-04)

Fixed:
- ~~Ragged right edge on land scroll~~ (user-reported): the shift loop never
  wrote column 39 and new tiles were stamped at cols 36–38, so a permanent
  blank at col 39 kept shifting into view. Now `FeedTileColumn` feeds the
  incoming tile one column at a time into col 39 (hidden behind the border —
  land rows run in 38-col mode), so chars slide in seamlessly. Replaced the
  whole-tile-every-3-shifts logic (`scrollTileComplete` + DrawTile at $24);
  DrawLand primes col 39 at init. The duplicate `jsr Screen.DrawLand` in Entry
  was removed — double-priming would misalign `tileColumn`.
- ~~IRQ race~~: Entry now banks out BASIC/Kernal *before* `jsr IRQ.Setup`, so
  the raster IRQ can never be dispatched through the Kernal handler.
- ~~Screen.speed unclamped~~: keyboard.asm now clamps speed to 1–7 (cpx guards
  around inc/dec, X used so the key code in A survives the checks).

Still open:
- No key debounce on z/x — speed changes every frame while held (fine for a
  debug knob).
- **irq.asm `and #%11111111`** in MainIRQ/ScrollIRQ is a no-op; intent was
  probably `%01111111` (clear raster MSB) like Setup/ResetIRQ.
- **DrawTile loop** relies on `cpx #$09` leaving carry clear for the `adc #$01`
  — works but fragile; add clc or a comment.
- DrawLand called twice (Setup.init + Entry). Dead `lda #$c0` in Dinosaur.Setup.
  Duplicate v*/non-v state consts. Dead: delay/SCROLL_DELAY/scrolledTile +
  commented blocks in screen.asm. Typo DISOSAUR_SPRITE.
- Not a bug: AnimateJump plays sine backward, final store hits the .fill byte
  (index 52) restoring initial Y — correct.

## Open questions / TODO

See [IMPLEMENTATION-PLAN.md](IMPLEMENTATION-PLAN.md) for the deep
parallel-agent plan (resource tables, Phase-0 skeleton, WP-A..E, merge
protocol) and [PLAN.md](PLAN.md) for the full roadmap to Chrome-dino parity
(milestones: obstacles+death+restart → score+difficulty → ptero+duck → polish).

- Obstacles (cacti) + collision handling (COLLISION_STATE exists, unused?)
- Score display
- Jump physics tuning
- `multiplyby9` macro comment says "multiply by 3" — comment is wrong.

## Headless run/verify recipe

```sh
x64sc -warp -autostartprgmode 1 -limitcycles 8000000 \
      -exitscreenshot /tmp/shot.png bin/404.prg
```

- `-autostartprgmode 1` injects the PRG into RAM — without it the emulated
  disk load is still going at 10M cycles.
- Take two shots at different `-limitcycles` to confirm the land scrolls.
- Needs `GSETTINGS_SCHEMA_DIR=$(brew --prefix)/share/glib-2.0/schemas`.
- Gray side-border bars in shots = the inc/dec $d020 IRQ timing debug, normal.
- **CRITICAL TIMING (measured 2026-07-04):** with `-autostartprgmode 1` the
  emulated BASIC "READY." + auto-RUN eats ~2.5M cycles BEFORE the game's
  first frame. So game-frame N ≈ 2.5M + N*19656 cycles (PAL: 19656 cyc/frame).
  The DEMO first auto-jump (frame 180) lands at **~6.2M cycles**, NOT 3.5M.
  Budget headless screenshots from a ~2.5M-cycle origin, not 0.
- `make demo` = build with `-define DEMO` → `Game.DemoDrive` synthesises input
  (auto-jump every 180 frames, auto-restart 120 frames after death). This is
  the ONLY way to exercise input headlessly (keys can't be pressed while
  Kernal is banked out).

## Ground / collision geometry (locked 2026-07-04)

- Land rows 12/13/14 = screen y 146–153 / 154–161 / 162–169.
- Dino sprite: Y=$8d → pixels y 141–161 (jump only goes UP from there).
- Plain-ground art rule: **pixels in row 14 only (y≥162)** → running dino
  never touches ground art → $d01f == "hit an obstacle", pixel-perfect.
- Enforced by blanking tile 4's plant top (chars 39–41) via
  `tools/glyphs/ground-no-collide.txt`; tiles 1/2 were already row-14-only.
- Charset patch pipeline: `make charset` (auto-run by build) applies
  `tools/glyphs/*.txt` via `tools/patch_charset.py`, idempotent,
  duplicate-char definitions across files are a build error.
- $d01f reads clear it → exactly ONE reader per frame (detect_collision).

## Gotchas

- BASIC + Kernal are banked out after init — no Kernal calls, IRQ vectors
  are the hardware ones at $fffe/$ffff.
- CIA IRQs are disabled in IRQ.Setup ($dc0d/$dd0d = $7f) to avoid crashes.
- VICE via Homebrew needs `GSETTINGS_SCHEMA_DIR` set (Makefile handles it).
