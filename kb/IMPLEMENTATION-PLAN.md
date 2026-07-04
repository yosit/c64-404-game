# Implementation Plan — Chrome-dino parity, parallel-agent edition

Deep technical plan for implementing everything in [PLAN.md](PLAN.md), designed
to be executed by multiple agents **in parallel** without stepping on each
other. Read this whole document before writing any code.

---

## 1. Current architecture (verified by inspection, 2026-07-04)

### Control flow
- `Startup.asm` `Entry`: Random.init → Setup.init (ClearScreen, VIC bank/
  memory setup, DrawLand) → Dinosaur.Setup → bank out BASIC+Kernal
  ($01=%xxxxx101, I/O stays) → IRQ.Setup → `jmp *`. **Everything after init
  runs in the raster IRQ chain.** No Kernal — IRQ vectors are the hardware
  ones at $fffe/$ffff.
- IRQ chain per frame: `MainIRQ` (line $20) → `ScrollIRQ` (line $90) →
  `ResetIRQ` (line $b0) → back to MainIRQ.
  - MainIRQ: Dinosaur.Update, Input.check_key_pressed, Screen.Update.
    Budget: ~7,000 cycles available (112 raster lines) — plenty of headroom.
  - ScrollIRQ (line $90): Screen.UpdateScrollState only (writes $d016 =
    $c0+offset → **38-column mode + smooth scroll for the land region**).
    Cycle-tight; do not add work here.
  - ResetIRQ (line $b0): restores $d016=$c8 (40-col, no scroll).
- Land region = screen rows 12–14 (pixel lines ~146–170), inside the
  $90–$b0 window. Rows 0–11 and 15–24 are normal 40-column screen.

### Memory / VIC layout
| What | Where | Notes |
|---|---|---|
| Code+data | $0801–~$0d53 | grows upward, lots of room to $4000 |
| Charset | $4000–$47ff | binary import of `data/everything-charset.bin` (2KB, 256 chars) |
| Map | $4800 | 6 bytes, currently unused at runtime |
| Screen RAM | $5000–$53e7 | VIC bank 1; sprite pointers at $53f8 |
| Sprites | $7000+ | pointer value $c0 = $7000; 5 sprites exist ($c0–$c4) |
| ZP used | $02–$03 (`TileAbsolutePosition`), $50–$5f (keyboard scan scratch) | |

### Charset facts (from `everything-charset.bin`)
- Non-blank chars: 0–44 region (land tiles 0–4; tile n = chars n*9 … n*9+8,
  row-major 3×3) plus char 174. Everything else is **blank and free**.
- Land tiles: `LandTiles: .byte 1,2,1,4,1,2,1,2` — random pick of tiles
  1,2,4 mostly. Tile chars are laid out row-major: col j of tile = chars
  base+j, base+3+j, base+6+j (this is what `FeedTileColumn` exploits).
- `data/everything-colors.bin` (256 bytes, per-char colors) is **not loaded
  at runtime** — color RAM is whatever the C64 booted with.

### Sprite facts (`data/sprites.asm`, single-color, 63 bytes + 1 meta byte)
| Ptr | Label | Content |
|---|---|---|
| $c0 | din_stand | standing dino |
| $c1 | din_walk_0 | run frame A |
| $c2 | din_walk_1 | run frame B |
| $c3 | sprite_0 | bird-like shape (usable as ptero seed / dead-eye dino?) |
| $c4 | sprite_1 | inverted dino (usable as crash flash) |

Dino = HW sprite 0 at X=$40 (px 64 → screen col ~5), Y=$8d (141).
Sprite is 21px tall → bottom at 162 → **overlaps land rows** (see §4 collision).

### State machine (dinosaur.asm)
`state`: STANDING %0001, RUNNING %0010, JUMPING %0100, COLLISION %1000
(v* duplicates exist — cleanup task). Dispatch is a cmp/bne chain.
Jump = 53-entry half-sine table played backward via `jump_counter`; last
entry (.fill) restores exact ground Y — do not break this invariant.

### Scroll system (screen.asm) — post-FeedTileColumn (commit 4e14b89)
- `offset` 7→0 minus `speed` (clamped 1–7) per frame; on wrap: 3-row shift
  left by one char (cols 1–39 → 0–38) + `FeedTileColumn` writes the next
  single tile column into hidden col 39. `tileColumn` 0–2 tracks position
  within `NextTile`; new random tile picked when it wraps. **Any new
  obstacle system must plug into this feed, not fight it.**

---

## 2. Resource allocation (FIXED — all agents must honor this table)

### Character set (patched into everything-charset.bin via tools/, see §3)
| Chars | Owner | Purpose |
|---|---|---|
| 0–44 | (existing) | land tiles 0–4 |
| 45–53 | WP-A | tile 5: small cactus (3×3, pixels in ALL rows so $d01f-free software collision works — see §4) |
| 54–62 | WP-A | tile 6: tall/double cactus |
| 63–71 | WP-A | tile 7: triple cactus cluster |
| 72–89 | WP-A | tiles 8–9: reserved for more obstacle variants |
| 176–185 ($b0–$b9) | WP-B | digits 0–9 (8×8, clean 5×7 font) |
| 186–199 ($ba–$c7) | WP-B | letters: H I G A M E O V R (+spares) for "HI" and "GAME OVER" |
| 200–208 ($c8–$d0) | WP-E | cloud chars (if char clouds chosen over sprites) |
| 174 | (existing) | in use — do not touch |

**CACTUS_FIRST = 45, CACTUS_LAST = 89** — collision checks use this range.

### Sprites (append to data/sprites.asm; 64 bytes each)
| Ptr | Owner | Purpose |
|---|---|---|
| $c5, $c6 | WP-C | duck-run frames A/B (wide, low profile) |
| $c7, $c8 | WP-C | pterodactyl flap frames A/B |
| $c9 | WP-A | dead dino (X-eyes; can derive from din_stand) |
| $ca, $cb | WP-E | cloud shapes (if sprite clouds chosen) |

### Hardware sprite slots
| Slot | Owner | Use | Constraint |
|---|---|---|---|
| 0 | (existing) | dino | |
| 1 | WP-C | pterodactyl | $d01e collision partner of dino |
| 2, 3 | WP-E | clouds | keep Y < 60 so they can NEVER overlap the dino (jump apex Y ≈ 91) — otherwise $d01e false-positives |
| 4–7 | free | | |

### Zeropage
| Range | Owner |
|---|---|
| $02–$03 | existing TileAbsolutePosition |
| $04–$07 | WP-A (game/obstacle temps) |
| $08–$0b | WP-B (score temps) |
| $0c–$0f | WP-C (ptero temps) |
| $10–$13 | WP-D/WP-E |
| $50–$5f | keyboard scan (existing, do not touch) |

### SID
WP-D owns $d400–$d406 (voice 1) and $d418 (volume). Nobody else touches SID.

### Keyboard matrix codes already decoded by Input (keyboard_io.asm returns
accumulator codes): 'x'=$18, 'z'=$1a, space=$20. WP-C must determine the
code for a duck key (recommend '.' or joystick-2 down via $dc00) and
document it in NAPKIN.

---

## 3. Phase 0 — integration skeleton (SEQUENTIAL, must land before the parallel wave)

One agent builds the contract layer everything else plugs into. ~half of
this is mechanical; it is the price of safe parallelism.

1. **State machine → jump table.** In dinosaur.asm replace the cmp/bne
   chain with an indexed jump table and renumber states as ordinals:
   `ST_IDLE=0, ST_RUNNING=1, ST_JUMPING=2, ST_DUCKING=3, ST_DEAD=4`
   (byte `state` holds the ordinal; a separate `StateHandlers:` .word table
   dispatches via RTS-trick or self-mod jmp). Provide empty handlers for
   IDLE/DUCKING/DEAD that just `rts`. Keep jump/run behavior identical
   (verify with screenshots before/after).
2. **Game module** `libs/game.asm` — the only file that grows jsr slots:
   ```
   Game: {
     Update:   // called from MainIRQ INSTEAD of the current three jsrs
       jsr Dinosaur.Update
       jsr Input.check_key_pressed
       jsr Screen.Update
       jsr Score.Update      // stub until WP-B fills it
       jsr Ptero.Update      // stub until WP-C
       jsr Sound.Update      // stub until WP-D
       jsr Ambience.Update   // stub until WP-E
       rts
     Reset:    // full game reset — each module owns its part
       jsr Screen.Reset      // land redraw + feed realign + offset/speed
       jsr Dinosaur.Reset
       jsr Score.Reset
       jsr Ptero.Reset
       jsr Ambience.Reset
       rts
     events: .byte 0         // bit flags, see below
   }
   ```
   MainIRQ calls `jsr Game.Update` — nothing else edits irq.asm afterward.
3. **Event flags** (`Game.events`, set by producers, consumed+cleared by
   Sound in the same frame): EV_JUMP=%001, EV_MILESTONE=%010, EV_CRASH=%100.
4. **Stub modules with full public interfaces** so every WP compiles alone:
   - `libs/score.asm`: `Score.Update/Reset` (rts), labels `score` (3 bytes
     BCD, little-endian), `hiscore` (3 bytes BCD).
   - `libs/ptero.asm`, `libs/sound.asm`, `libs/ambience.asm`: Update/Reset rts.
   - `Screen.Reset` in screen.asm: redraw land, reset offset/=7, speed=1,
     tileColumn=0, re-prime col 39.
5. **Charset patch pipeline** — ALREADY BUILT (2026-07-04):
   `tools/patch_charset.py` + `tools/glyphs/*.txt` (`char <index>` header,
   8 rows of 8 `.#`), wired as `make charset`, a `build` dependency,
   idempotent, and it errors on duplicate char definitions across files.
   Each WP adds its own .txt files → no merge conflicts. See
   `tools/glyphs/ground-no-collide.txt` for the format in action.
6. **DEMO mode for headless verification** (critical: keys can't be pressed
   headlessly — the game scans the CIA matrix and Kernal is banked out):
   `#if DEMO` blocks, enabled by `make demo` (KickAss `-define DEMO`):
   auto-press logic in Game.Update — jump every ~180 frames, duck frames
   400–500, auto-restart 120 frames after death. Every WP verifies its
   feature by building `make demo` + headless VICE screenshots at chosen
   `-limitcycles` values.
7. Commit. Tag the interfaces section of this file as LOCKED in the commit
   message.

### Phase 0 acceptance
- `make build` and `make demo` pass; normal build behaves pixel-identically
  to 4e14b89 (screenshot diff); demo build shows periodic auto-jumps.

---

## 4. Work packages (PARALLEL after Phase 0)

Each WP: own git branch off the Phase-0 commit (worktree), owns the files
listed, MUST NOT edit files owned by another WP. Shared files
(Startup.asm imports, Makefile) were pre-wired in Phase 0. Merge order and
conflict policy in §5.

---

### WP-A — Obstacles, collision, game over, restart  (owns: screen.asm obstacle feed, dinosaur.asm DEAD handler, game.asm restart logic, glyphs 45–89, sprite $c9)

**A1. Cactus tiles.** Design 3 cactus tiles (glyph .txt files, chars 45–71).
Constraint: cactus body pixels live in land rows 12–13 (y 146–161, the
dino-touchable zone — that is what $d01f keys on, §A3); the tile's row-14
base blends into the ground line. Draw them solid enough that a pixel
graze reads as a fair hit.

**A2. Obstacle spawning through the feed.** In screen.asm: with probability
~1/6 when `FeedTileColumn` picks a new tile AND a minimum-gap counter has
expired, pick a cactus tile (45/9=tile 5, 6, 7) instead of a land tile;
else land tile. Min gap: after feeding a cactus, force >= GAP_TILES(speed)
normal tiles before the next cactus — GAP must keep every pattern jumpable
at speed 7 (jump airtime = 53 frames / speed... compute: horizontal travel
during jump = 53 frames * speed px / 8 px-per-col ≈ 6.6 cols at speed 1,
46 cols at speed 7 — so min gap of ~8 tiles (24 cols) is safe for all
speeds; tune by playing). Track `columnsUntilCactusAllowed` byte.

**A3. Collision — HARDWARE $d01f (ground art fixed 2026-07-04 to allow it).**
The ground was made collision-silent: all plain-ground tiles (1, 2, and
the trimmed tile 4) have pixels only in land row 14 (screen y≥162), while
the running dino's lowest pixel is y=161 — so on plain ground $d01f NEVER
fires, and any set bit 0 means "dino pixel touched obstacle pixel".
Pixel-perfect for free, like Chrome.
- Un-stub Dinosaur.detect_collision: read $d01f ONCE per frame (reads
  clear it — single reader rule), `and #%00000001`, branch to crash.
- HARD RULE for cactus art: cactus pixels live in land rows 12–13
  (y 146–161) where the dino can touch them; their row-14 base may merge
  into the ground line. HARD RULE for any future plain-ground art: row 14
  only (enforced location: tools/glyphs/ — see ground-no-collide.txt).
- Works identically while JUMPING (sprite is higher, overlap = real graze).
  No Y-threshold logic needed.

**A4. Game over.** On crash: `Game.events |= EV_CRASH`, state=ST_DEAD,
dino sprite ptr = $c9 (dead frame), stop land scroll (Screen.Update
already gates on state — make it gate on ST_RUNNING/ST_JUMPING/ST_DUCKING),
write "GAME OVER" (chars from WP-B's letter range — coordinate: Phase 0
reserves the indices, WP-A may add the glyph .txt files if WP-B hasn't;
duplicate .txt files for the same char index = merge error, so ONLY WP-B
creates letter glyphs; WP-A just writes the char codes to screen row 8,
centered, cols 15–24).

**A5. Restart.** Space in ST_DEAD → `jsr Game.Reset` → state=ST_RUNNING.
Clear the GAME OVER text (restore blanks). High score survives (WP-B owns
the hiscore update itself — it hooks EV_CRASH).

**A6. Idle/start.** Boot into ST_IDLE (land drawn, not scrolling, dino
standing frame $c0). First space → ST_RUNNING. (This is WP-A's because it
owns game flow.)

**Verify (make demo + headless):** screenshots showing (a) cacti scrolling
in, spaced; (b) auto-jump clearing a cactus; (c) a crash frame with dead
dino + GAME OVER text; (d) post-auto-restart running screen again. State
what demo mode cannot prove (real key feel).

---

### WP-B — Score, high score, progressive speed  (owns: score.asm body, digit+letter glyphs 176–199)

**B1. Digit/letter glyphs.** tools/glyphs/digits.txt (chars 176–185),
letters.txt (186–199: H I G A M E O V R). Simple readable 5×7-in-8×8.

**B2. Score.** 3-byte BCD (6 digits, Chrome uses 5 — use 5 shown).
Increment: every 4th frame add 1 (frame divider byte), SED/CLD carefully
INSIDE IRQ — 6502 decimal flag is NOT cleared by IRQ entry on NMOS 6502;
set/clear explicitly around the arithmetic (cld at end, and note MainIRQ
should start with cld as safety — Phase 0 skeleton includes it).
Render: row 0, cols 34–38, char = $b0 + digit, only when a digit changed
(dirty flag) to save cycles. Only while state is a playing state.
Milestone: every 100 points set EV_MILESTONE + blink score (flash chars
to blank and back ~6 times using a blink counter — cheap: toggle between
digit chars and $20-blank every 8 frames).

**B3. High score.** On EV_CRASH: if score > hiscore (BCD compare, MSB
first) copy. Render "HI xxxxx" at row 0 cols 24–32. Persist across
restarts (just don't reset it in Score.Reset — reset score only).

**B4. Progressive speed.** In Score.Update: on every 100-point milestone,
if `Screen.speed` < 7: inc. Score.Reset sets speed=1. Keep z/x keys.

**Verify:** demo build screenshots at increasing -limitcycles show the
score advancing, HI field after first auto-crash+restart, and (long run)
speed visibly higher (land pattern displacement per frame — compare two
close screenshots).

---

### WP-C — Pterodactyl + duck  (owns: ptero.asm body, sprites $c5–$c8, dinosaur.asm DUCKING handler)

**C1. Sprites.** Author 4 sprites in data/sprites.asm: duck A/B (long low
dino, head forward, ~12px tall), ptero flap A/B (wings up/down).

**C2. Ptero logic (ptero.asm).** Active flag + X (9-bit: $d010 MSB!), Y,
frame, flap counter. Spawn: when score > 300 (read Score.score BCD) and
random interval + min distance from any cactus currently on screen is NOT
required (Chrome allows both; keep fairness: don't spawn if a cactus is in
the entry third of the screen — check screen RAM cols 30–39 for cactus
chars). Heights: Y=$85 (head height — must duck or jump), Y=$70 (jump-over
or duck-under... pick 2 heights: head-height forces duck, ground-height
forces jump). Move: X -= speed+1 each frame (slightly faster than ground);
flap every 16 frames; deactivate when X wraps past left edge (careful with
the $d010 MSB crossing).

**C3. Sprite-sprite collision.** Read $d01e once per frame in Ptero.Update
(read clears it); if bits 0 AND 1 set → EV_CRASH path (call the same crash
routine WP-A exposes: contract = `Game.Crash` label, Phase 0 provides it
as stub that WP-A fills; if WP-A's version isn't merged yet, the stub rts
keeps WP-C compilable).
False-positive guard: clouds (sprites 2/3) stay above Y 60 per §2 —
ignore $d01e bits 2+.

**C4. Duck.** New key (choose + document) held → if ST_RUNNING:
ST_DUCKING, sprite ptrs $c5/$c6 alternate at run cadence, sprite Y
adjusted so the duck sprite sits on the ground (its art is lower —
compensate Y by the art offset, document the value). Key released →
ST_RUNNING. While ducking, head-height pteros pass over (their Y vs duck
hitbox — since collision is $d01e pixel-perfect, correct duck art IS the
hitbox — verify visually).

**Verify:** demo mode ducks during frames 400–500; screenshots with ptero
approaching at both heights; a crash from ptero contact; flap animation
(two screenshots 16 frames apart differ in wing pose).

---

### WP-D — SID sound  (owns: sound.asm body; SID regs)

Voice 1 only. `Sound.Update` each frame: consume Game.events:
- EV_JUMP: triangle, freq sweep up over ~10 frames (table), short decay.
- EV_MILESTONE: two square blips (freq F, gap, F*1.25), ~16 frames total.
- EV_CRASH: noise waveform, low freq, longer decay (~30 frames).
Implement as a tiny priority state machine (crash > milestone > jump), a
frame counter + per-effect freq/ctrl tables. Init: volume $0f at Setup
(add `jsr Sound.Init` to Setup.init — Phase 0 put the stub call there).
Events byte cleared after consumption (single consumer = Sound).
NOTE: producers OR into Game.events; Sound is the ONLY clearer.

**Verify:** sound can't be heard headlessly — verify by asserting register
writes in the VICE monitor is overkill; instead build with a DEMO overlay
that also pokes the current effect id to border color... simplest: state
in final report that audio needs human verification with `make debug`;
verify no visual regressions + build passes.

---

### WP-E — Clouds + day/night  (owns: ambience.asm body, sprites $ca/$cb or chars 200–208)

**E1. Clouds:** 2 cloud sprites (slots 2,3), X decrement every 2nd/3rd
frame (half/third ground speed for parallax), Y fixed 45 and 55 (**hard
ceiling: Y+21 < 91 = jump apex — never overlap dino, keeps $d01e clean**),
respawn at right with random Y within limits + random gap.
**E2. Day/night:** watch Score.score: at each 500-point boundary flip to
night for 250 points: bg $d021 black, border $d020 black... note border
is currently used as IRQ timing debug (inc/dec $d020) — coordinate: night
sets a `nightFlag` and the debug border flashing stays (it's dev-only;
Phase 0 wraps the inc/dec $d020 pairs in `#if !DEMO` ... actually wrap in
`#if DEBUG_TIMING` default ON for now — WP-E just writes $d020/$d021 base
colors from its handler and accepts the flicker). Char visibility: land
chars are drawn in color RAM's boot default (light blue) — night needs
them visible: set color RAM for rows 0–15 once at Setup to white/grey
(WP-E adds `Ambience.InitColors` called from Setup stub slot), then
day/night only flips $d020/$d021/$d022/$d023.
Sprite colors: dino stays white-ish both phases.

**Verify:** screenshots before/after a 500-boundary (choose -limitcycles
to land in night; score visible in shot confirms phase), clouds at two
positions in two shots, clouds never below Y 60.

---

## 5. Integration & merge protocol (SEQUENTIAL, after parallel wave)

Merge order: **A → B → C → D → E** (A is the backbone; later merges are
additive modules + their stub fills).

Integration agent duties:
1. Merge each branch; expected conflict surface ≈ zero (file ownership) —
   any conflict in a shared file means an agent broke ownership: resolve
   favoring the owner listed in §4, note it in NAPKIN.
2. After EACH merge: `make build && make demo` + headless screenshot sweep
   (8M/12M/20M/40M cycles) — catch inter-module breakage at the merge that
   introduced it, not at the end.
3. Full-game demo soak: 60M cycles screenshot — expect: night or day phase,
   score 4+ digits, cacti + possibly ptero on screen, clouds, no visual
   corruption.
4. Housekeeping sweep (may be its own small agent): irq.asm `and #$ff`
   no-ops → `and #%01111111`; DrawTile clc/comment; delete dead vars
   (delay, SCROLL_DELAY, scrolledTile); DISOSAUR typo; multiplyby9 comment;
   remove v* dup constants (Phase 0 probably already did via jump table).
5. Update NAPKIN (memory map, char map, new modules) + tick PLAN.md.
6. Single push at the end (or per user instruction).

## 6. Global invariants (every agent re-reads before finishing)

1. `make build` passes AND normal (non-demo) build has no demo behavior.
2. Bank-out of BASIC/Kernal stays BEFORE IRQ.Setup in Entry.
3. ScrollIRQ gains no new work. New per-frame work goes in Game.Update.
4. Never touch another WP's files/chars/sprites/ZP (table in §2).
5. `cld` discipline: any SED user restores CLD before rts (and MainIRQ
   opens with cld as a backstop).
6. Screenshots are looked at, not just taken. A blank/garbage frame = stop
   and debug, not ship.
7. Every commit message ends with the standard co-author + session trailer.
8. Update kb/NAPKIN.md with every non-obvious discovery — it is the shared
   brain across agents.

## 7. Open design decisions already made (do not relitigate)

- Cacti are chars in the scroll feed, not sprites.
- Dino-vs-cactus collision is hardware $d01f — made possible by trimming
  tile 4's plant top (chars 39–41 blanked via tools/glyphs/) so plain
  ground has pixels only in row 14 (y≥162), below the dino's y=161 bottom.
  Plain-ground art must NEVER put pixels above row 14 (this is what keeps
  $d01f meaningful).
- Ptero/duck collision IS hardware ($d01e), clouds kept out of its way by
  the Y<60 rule.
- Score is BCD with explicit sed/cld inside the IRQ.
- DEMO compile flag is the headless verification mechanism.
