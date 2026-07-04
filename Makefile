# C64 404 Game — build & run
#
# Requires:
#   - Java (for KickAssembler)        -> already on PATH via asdf
#   - KickAssembler (KickAss.jar)     -> KICKASS var below
#   - VICE (x64sc)                    -> `brew install vice`

KICKASS ?= $(HOME)/.local/kickass/KickAss.jar
JAVA    ?= java
X64     ?= x64sc

SRC     := Startup.asm
BINDIR  := bin
PRG     := $(BINDIR)/404.prg
SYMBOLS := $(BINDIR)/Startup.vs

.PHONY: all build demo run clean charset

all: build

# Patch glyphs from tools/glyphs/*.txt into the charset binary (idempotent)
charset:
	python3 tools/patch_charset.py

# Assemble Startup.asm -> bin/404.prg (with VICE symbol file for debugging)
build: charset $(PRG)

$(PRG): $(SRC) $(wildcard libs/*.asm) $(wildcard data/*.asm) $(wildcard tools/glyphs/*.txt)
	@mkdir -p $(BINDIR)
	$(JAVA) -jar $(KICKASS) $(SRC) -o $(PRG) -vicesymbols

# DEMO build: defines DEMO so Game.DemoDrive synthesises input (jump/duck/
# restart) for headless screenshot verification — keys can't be pressed while
# the Kernal is banked out. Rebuilds unconditionally (separate flag, no cache).
demo: charset
	@mkdir -p $(BINDIR)
	$(JAVA) -jar $(KICKASS) $(SRC) -o $(PRG) -vicesymbols -define DEMO

# Build then launch in the VICE C64 emulator.
# GSETTINGS_SCHEMA_DIR works around the Homebrew GTK build not finding its
# compiled GSettings schemas ("No GSettings schemas are installed").
run: build
	GSETTINGS_SCHEMA_DIR=$(GSCHEMA_DIR) $(X64) -moncommands $(SYMBOLS) $(PRG)

GSCHEMA_DIR ?= $(shell brew --prefix)/share/glib-2.0/schemas

# Build then launch in Retro Debugger (the successor to C64 Debugger).
# Auto-discovers the newest "Retro Debugger*" app in /Applications so it keeps
# working when you upgrade versions. Override with RETRODBG=/path/to/binary.
RETRODBG ?= $(shell ls -d "/Applications/Retro Debugger"*/"Retro Debugger.app/Contents/MacOS/Retro Debugger" 2>/dev/null | sort -V | tail -1)

debug: build
	@test -n '$(RETRODBG)' || { echo "Retro Debugger not found in /Applications. Set RETRODBG=/path/to/binary"; exit 1; }
	'$(RETRODBG)' -prg $(PRG) -symbols $(SYMBOLS) -autojmp -unpause

clean:
	rm -rf $(BINDIR)
