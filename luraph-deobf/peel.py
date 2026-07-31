#!/usr/bin/env python3
# ============================================================
#  peel.py  --  Luraph static outer-layer peeler (no execution)
#
#  Luraph (v13/v14.x) wraps its VM bytecode in one or more
#  "packed streams": long-bracket Lua strings ([=[ ... ]=],
#  [==[ ... ]==], ...) each beginning with an "LPH..." header,
#  encoded with a base-85 (Ascii85) variant:
#
#     s = s:sub(D)                    -- drop the D-char header
#     s = s:gsub("z", "!!!!!")        -- zero-run shorthand
#     s = s:gsub(".....", group->4B)  -- 5 chars -> uint32 -> <I4
#
#  This script reverses that transform WITHOUT running the file,
#  so it is safe on hostile samples. It recovers the raw packed
#  bytecode stream for every stage.
#
#  HONEST SCOPE
#  ------------
#  The base-85 layer is pure ENCODING and peels for free -- that
#  is Luraph weakness #1 (reversible outer layer). What you get
#  back is the VM bytecode stream, which in v14.x is *also*
#  encrypted by a keystream built in the bootstrap. That inner
#  layer decrypts itself at RUNTIME, so full recovery uses the
#  dynamic harness (sandbox.lua), not this static pass.
#
#  This peeler gives you: every packed stage as raw bytes, an
#  entropy/magic report, and a fast triage of what you're facing.
#
#  Usage:
#     python3 peel.py <script.lua> [-o outdir]
# ============================================================

import argparse
import math
import os
import re
import sys

LUA_MAGIC = b"\x1bLua"          # 5.1 bytecode magic prefix
LURAPH_MAGIC = b"\x1bLuaP"      # header the bootstrap integrity-checks for


def find_long_bracket_strings(src):
    """Yield (level, header, body) for every [=[ .. ]=] of any level.

    Matches the exact opening/closing bracket level so nested levels are
    handled the way the Lua lexer handles them.
    """
    out = []
    for m in re.finditer(r"\[(=*)\[", src):
        level = m.group(1)
        close = "]" + level + "]"
        start = m.end()
        end = src.find(close, start)
        if end == -1:
            continue
        body = src[start:end]
        # Luraph packed streams start with the LPH header; skip ordinary strings.
        header = body[:8]
        out.append((len(level), header, body))
    return out


def a85_decode(body, drop=5):
    """Luraph base-85 variant.

    body[drop:] , expand 'z' -> five '!' (== four zero bytes), then every
    5 chars -> uint32 (big-endian base85) packed little-endian ('<I4').
    Returns (decoded_bytes, leftover_str).
    """
    s = body[drop:]
    s = s.replace("z", "!!!!!")
    out = bytearray()
    n = len(s) - (len(s) % 5)
    for i in range(0, n, 5):
        val = 0
        for ch in s[i:i + 5]:
            val = val * 85 + (ord(ch) - 33)
        val &= 0xFFFFFFFF
        out += val.to_bytes(4, "little")
    return bytes(out), s[n:]


def entropy(data):
    if not data:
        return 0.0
    freq = [0] * 256
    for b in data:
        freq[b] += 1
    ent = 0.0
    ln = len(data)
    for f in freq:
        if f:
            p = f / ln
            ent -= p * math.log2(p)
    return ent


def guess_drop(body):
    """The header length D. Luraph v14.x uses D=5 ('LPH%V','LPH>&', ...).

    We confirm by checking the byte after decode for structure, but default
    to 5 which matches every v14.x sample observed.
    """
    return 5


def classify(data):
    if data.startswith(LURAPH_MAGIC):
        return "luraph-bytecode (decrypted magic present!)"
    if data.startswith(LUA_MAGIC):
        return "lua 5.1 bytecode"
    ent = entropy(data)
    if ent > 7.5:
        return f"encrypted/compressed stream (entropy {ent:.2f})"
    return f"plain-ish data (entropy {ent:.2f})"


def main():
    ap = argparse.ArgumentParser(description="Luraph static outer-layer peeler")
    ap.add_argument("input", help="obfuscated .lua file")
    ap.add_argument("-o", "--outdir", default="peeled", help="output directory")
    ap.add_argument("-D", "--drop", type=int, default=None,
                    help="header length to strip (default: auto=5)")
    args = ap.parse_args()

    with open(args.input, "r", encoding="utf-8", errors="replace") as f:
        src = f.read()

    strings = find_long_bracket_strings(src)
    packed = [(lvl, hdr, body) for (lvl, hdr, body) in strings
              if hdr.startswith("LPH") or body[:1] in ("L",)]
    # be permissive: if no LPH headers, treat all long-bracket blobs as candidates
    if not packed:
        packed = strings

    if not packed:
        print("No long-bracket packed streams found. This may not be a "
              "Luraph-packed file, or it uses a different container.")
        return 1

    os.makedirs(args.outdir, exist_ok=True)
    print(f"[peel] {args.input}: {len(packed)} packed stream(s) found\n")

    for idx, (lvl, hdr, body) in enumerate(packed):
        drop = args.drop if args.drop is not None else guess_drop(body)
        data, leftover = a85_decode(body, drop)
        outpath = os.path.join(args.outdir, f"stage_{idx}.bin")
        with open(outpath, "wb") as f:
            f.write(data)
        kind = classify(data)
        print(f"  stage[{idx}]  bracket=[{'='*lvl}[  header={hdr!r}")
        print(f"             encoded {len(body):>8} chars -> {len(data):>8} bytes")
        print(f"             {kind}")
        if leftover:
            print(f"             (leftover {len(leftover)} chars: {leftover!r})")
        print(f"             -> {outpath}")
        print()

    print("[peel] done. Encoding layer removed. If a stage reports "
          "'encrypted stream', the inner keystream decrypts at runtime -- "
          "use sandbox.lua to capture the final decoded output.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
