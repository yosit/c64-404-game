A replica of the chrome 404 dinosaur game for the c64

Current Status:

![](https://j.gifs.com/zvAr0O.gif) 


## Build & Run

Prerequisites:
- **Java** (for KickAssembler) — already available via asdf
- **KickAssembler** — `KickAss.jar`, expected at `~/.local/kickass/KickAss.jar` (override with `make KICKASS=/path/to/KickAss.jar`)
- **VICE** — `brew install vice` (provides `x64sc`)
- **Retro Debugger** (optional, for `make debug`) — download the macOS build from
  [the releases page](https://github.com/slajerek/RetroDebugger/releases) and drop the
  app into `/Applications` (currently v1.0.0)

```sh
make build   # assemble Startup.asm -> bin/404.prg
make run     # build, then launch in the VICE C64 emulator
make debug   # build, then launch in Retro Debugger (with symbols)
make clean   # remove bin/
```

`make debug` opens the game in [Retro Debugger](https://github.com/slajerek/RetroDebugger)
(the maintained successor to C64 Debugger) with the KickAssembler symbol file
loaded, so labels show up in the disassembly. It auto-discovers the newest
`Retro Debugger*` app in `/Applications`; override with
`make debug RETRODBG=/path/to/Retro\ Debugger`.

> Note: on macOS the Homebrew GTK build of VICE needs its GSettings schemas; the
> `run` target sets `GSETTINGS_SCHEMA_DIR` automatically to avoid the
> "No GSettings schemas are installed" crash.

Sprites under data are editable in https://www.spritemate.com/


Tools:
Sublime + kickass plugin
Retro Debugger [https://github.com/slajerek/RetroDebugger] (successor to c64debugger)
vice
vchar64 [https://github.com/ricardoquesada/vchar64/releases/tag/0.2.4]

Heavily inspired by Shallan and his excellent youtube channel [https://www.youtube.com/channel/UCFjZzzJO_rXmr4FeBSf2rcQ]