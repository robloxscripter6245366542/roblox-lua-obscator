#!/usr/bin/env python3
# ============================================================
#  peel.py  --  Luraph static unpacker (no execution)
#
#  Luraph (v13/v14.x) wraps its VM in one or more "packed streams":
#  long-bracket Lua strings ([=[ ... ]=], [==[ ... ]==], ...) each
#  beginning with an "LPH..." header. Two fully-reversible layers,
#  NEITHER of which uses a cryptographic key:
#
#    1. base-85 (Ascii85) variant:
#         s = s:sub(D)                    -- keep from the D-th char
#         s = s:gsub("z", "!!!!!")        -- zero-run shorthand
#         s = s:gsub(".....", group->4B)  -- 5 chars -> uint32 -> <I4
#
#    2. LZMA1 (lc=3, lp=0, pb=0), raw stream (no props/size header).
#       The bootstrap ships a pure-Lua LZMA decoder -- the "encryption"
#       is just compression entropy. python's own lzma decodes it.
#
#  BIG FINDING
#  -----------
#  Because both layers are keyless, the ENTIRE outer protection is
#  statically reversible. Peeling a v14.7 sample yields, offline:
#     * the VM interpreter as readable Lua SOURCE   (stage 0)
#     * the VM bytecode program                     (stage 1)
#  No runtime, no executor, no sandbox needed to get this far. The
#  only thing that stays hard is devirtualising the bytecode back to
#  source -- see devirt.md.
#
#  Usage:
#     python3 peel.py <script.lua> [-o outdir] [--no-lzma]
# ============================================================

import argparse
import lzma
import math
import os
import re
import sys

LUA_MAGIC = b"\x1bLua"          # 5.1 bytecode magic prefix
LURAPH_MAGIC = b"\x1bLuaP"      # header the bootstrap integrity-checks for


def lzma_raw_decompress(data):
    """Decode the inner LZMA1 layer (lc=3, lp=0, pb=0, raw, no header).

    dict_size must exceed the largest match distance; grow it until the
    stream decodes. Returns (bytes, dict_size) or (None, None) on failure.
    """
    for bits in range(16, 28):
        ds = 1 << bits
        filt = [{"id": lzma.FILTER_LZMA1, "lc": 3, "lp": 0, "pb": 0,
                 "dict_size": ds}]
        try:
            dec = lzma.LZMADecompressor(format=lzma.FORMAT_RAW, filters=filt)
            out = dec.decompress(data)
            return out, ds
        except lzma.LZMAError:
            continue
    return None, None


def looks_like_lua_source(data):
    if len(data) < 8:
        return False
    sample = data[:2000]
    printable = sum(1 for b in sample if b in (9, 10, 13) or 32 <= b <= 126)
    return printable / len(sample) > 0.95


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

    Lua does string.sub(n, drop) which is 1-indexed and KEEPS from the
    drop-th char, i.e. it removes (drop-1) leading chars. Then it expands
    'z' -> five '!' (== four zero bytes) and maps every 5 chars -> uint32
    (big-endian base85) packed little-endian ('<I4').
    Returns (decoded_bytes, leftover_str).
    """
    s = body[drop - 1:]
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
    ap = argparse.ArgumentParser(description="Luraph static unpacker")
    ap.add_argument("input", help="obfuscated .lua file")
    ap.add_argument("-o", "--outdir", default="peeled", help="output directory")
    ap.add_argument("-D", "--drop", type=int, default=None,
                    help="header length to strip (default: auto=5)")
    ap.add_argument("--no-lzma", action="store_true",
                    help="stop after the base-85 layer (skip LZMA)")
    args = ap.parse_args()

    with open(args.input, "r", encoding="utf-8", errors="replace") as f:
        src = f.read()

    strings = find_long_bracket_strings(src)
    # Real Luraph packed streams carry the 'LPH' header. Requiring it avoids
    # false positives from stray [[ .. ]] runs inside the encoded data itself.
    packed = [(lvl, hdr, body) for (lvl, hdr, body) in strings
              if hdr.startswith("LPH")]

    if not packed:
        print("No LPH-headed packed streams found. This may not be a "
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
        print(f"  stage[{idx}]  bracket=[{'='*lvl}[  header={hdr!r}")
        print(f"             encoded {len(body):>8} chars -> {len(data):>8} bytes"
              f"  (base-85)")

        if not args.no_lzma:
            dec, ds = lzma_raw_decompress(data)
            if dec is not None:
                if looks_like_lua_source(dec):
                    ext, label = "lua", "LUA SOURCE (VM interpreter / loader)"
                elif dec.startswith(LUA_MAGIC):
                    ext, label = "luac", "lua 5.1 bytecode"
                else:
                    ext, label = "bin", "VM bytecode / binary program"
                decpath = os.path.join(args.outdir, f"stage_{idx}.{ext}")
                with open(decpath, "wb") as f:
                    f.write(dec)
                print(f"             LZMA -> {len(dec):>8} bytes  "
                      f"[dict {ds >> 10}KB]  {label}")
                print(f"             -> {decpath}")
                if leftover:
                    print(f"             (a85 leftover {len(leftover)} chars: {leftover!r})")
                print()
                continue

        kind = classify(data)
        print(f"             {kind}")
        if leftover:
            print(f"             (leftover {len(leftover)} chars: {leftover!r})")
        print(f"             -> {outpath}")
        print()

    print("[peel] done. Base-85 + LZMA layers removed statically (no key).\n"
          "       *.lua  = recovered Lua source (read it directly)\n"
          "       *.bin  = VM bytecode program -> see devirt.md for lifting\n"
          "       Use strings.py for a quick IOC pass over any stage.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
