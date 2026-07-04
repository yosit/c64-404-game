#!/usr/bin/env python3
"""Patch glyphs from tools/glyphs/*.txt into data/everything-charset.bin.

Glyph file format (any number of glyphs per file):

    char 39
    ........
    ........
    ........
    ........
    ........
    ........
    ........
    ........

'#' = pixel on, '.' = pixel off. Idempotent: running twice is a no-op.
Refuses duplicate definitions of the same char across all files.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CHARSET = ROOT / "data" / "everything-charset.bin"
GLYPHS = ROOT / "tools" / "glyphs"


def parse(path):
    glyphs = {}
    lines = [l.rstrip() for l in path.read_text().splitlines()]
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        if not line or line.startswith("//") or line.startswith("#!"):
            i += 1
            continue
        if not line.startswith("char "):
            sys.exit(f"{path}:{i+1}: expected 'char <index>', got: {line!r}")
        idx = int(line.split()[1], 0)
        if not 0 <= idx <= 255:
            sys.exit(f"{path}:{i+1}: char index {idx} out of range")
        rows = []
        for j in range(8):
            row = lines[i + 1 + j].strip()
            if len(row) != 8 or any(c not in ".#" for c in row):
                sys.exit(f"{path}:{i+2+j}: bad row {row!r} (need 8 of . or #)")
            rows.append(sum(0x80 >> k for k, c in enumerate(row) if c == "#"))
        glyphs[idx] = (bytes(rows), path.name)
        i += 9
    return glyphs


def main():
    data = bytearray(CHARSET.read_bytes())
    assert len(data) == 2048, f"unexpected charset size {len(data)}"
    seen = {}
    for f in sorted(GLYPHS.glob("*.txt")):
        for idx, (rows, src) in parse(f).items():
            if idx in seen:
                sys.exit(f"char {idx} defined in both {seen[idx]} and {src}")
            seen[idx] = src
            data[idx * 8:(idx + 1) * 8] = rows
    CHARSET.write_bytes(bytes(data))
    print(f"patched {len(seen)} glyph(s) into {CHARSET.name}")


if __name__ == "__main__":
    main()
