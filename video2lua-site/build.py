#!/usr/bin/env python3
"""Build the standalone video2lua web app.

Injects the current ../video2lua/player_template.lua into index.template.html
(replacing the /*__PLAYER_TEMPLATE__*/ marker) and writes a fully self-contained
index.html that works from a static host or straight off the filesystem.

Run this whenever the player template changes:  python3 build.py
"""
import json
from pathlib import Path

HERE = Path(__file__).parent
TEMPLATE = HERE.parent / "video2lua" / "player_template.lua"
SRC = HERE / "index.template.html"
OUT = HERE / "index.html"

MARKER = "/*__PLAYER_TEMPLATE__*/"


def main() -> None:
    lua = TEMPLATE.read_text(encoding="utf-8")
    page = SRC.read_text(encoding="utf-8")
    if MARKER not in page:
        raise SystemExit(f"marker {MARKER!r} not found in {SRC.name}")
    # json.dumps gives a safe, correctly-escaped JS string literal.
    injected = "const PLAYER_TEMPLATE = " + json.dumps(lua) + ";"
    page = page.replace(MARKER, injected)
    OUT.write_text(page, encoding="utf-8")
    print(f"wrote {OUT}  ({len(page)/1024:.0f} KB, template {len(lua)/1024:.0f} KB)")


if __name__ == "__main__":
    main()
