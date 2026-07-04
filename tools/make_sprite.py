#!/usr/bin/env python3
"""Convert 24x21 ASCII sprite art into KickAssembler .byte blocks (printed to
stdout). Keeps the ASCII as the editable source of truth in tools/sprites/.

Sprite file format: a `sprite <name>` line, then 21 rows of exactly 24 chars
('#' = pixel on, '.' = off). Optional `meta <hex>` line sets the 64th byte
(spritemate color/multicolor nibble); defaults to $03 (single-colour, col 3).

Usage: python3 tools/make_sprite.py tools/sprites/dino.txt
Paste the printed block(s) over the corresponding label in data/sprites.asm.
"""
import sys
from pathlib import Path


def parse(path):
    out = []
    lines = [l.rstrip("\n") for l in Path(path).read_text().splitlines()]
    i = 0
    while i < len(lines):
        s = lines[i].strip()
        if not s or s.startswith("//"):
            i += 1
            continue
        if not s.startswith("sprite "):
            sys.exit(f"{path}:{i+1}: expected 'sprite <name>', got {s!r}")
        name = s.split()[1]
        meta = 0x03
        j = i + 1
        if lines[j].strip().startswith("meta "):
            meta = int(lines[j].strip().split()[1], 16)
            j += 1
        data = []
        for r in range(21):
            row = lines[j + r]
            if len(row) != 24 or any(c not in ".#" for c in row):
                sys.exit(f"{path}:{j+r+1}: need 24 of . or #, got {row!r}")
            for b in range(3):
                v = 0
                for k in range(8):
                    if row[b * 8 + k] == "#":
                        v |= 0x80 >> k
                data.append(v)
        data.append(meta)
        out.append((name, data))
        i = j + 21
    return out


def main():
    if len(sys.argv) < 2:
        sys.exit("usage: make_sprite.py <art.txt> ...")
    for path in sys.argv[1:]:
        for name, data in parse(path):
            print(f"{name}:")
            for start in range(0, 64, 8):
                chunk = data[start:start + 8]
                print(".byte " + ",".join(f"${v:02x}" for v in chunk))
            print()


if __name__ == "__main__":
    main()
