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
    """Auto-detect the header length D that the loader strips before base-85.

    v14.x uses D=5 ('LPH%V', 'LPH>&', ...). Rather than hardcode that (v15 is
    a rewrite and may header differently), try the plausible candidates and
    keep the one whose base-85 decode actually LZMA-decompresses; fall back to
    the one that yields the most structured bytes. Defaults to 5.
    """
    best_struct, best_score = 5, -1.0
    for d in (5, 4, 6, 3, 7):
        data, _ = a85_decode(body, d)
        if not data:
            continue
        dec, _ = lzma_raw_decompress(data)
        if dec is not None:
            # A clean LZMA decode is a strong signal — take the first one.
            return d
        # No LZMA: score by low entropy / bytecode-magic as a fallback.
        score = (8.0 - entropy(data[:4096])) + (4.0 if data.startswith(LUA_MAGIC) else 0.0)
        if score > best_score:
            best_score, best_struct = score, d
    return best_struct


def classify(data):
    if data.startswith(LURAPH_MAGIC):
        return "luraph-bytecode (decrypted magic present!)"
    if data.startswith(LUA_MAGIC):
        return "lua 5.1 bytecode"
    ent = entropy(data)
    if ent > 7.5:
        return f"encrypted/compressed stream (entropy {ent:.2f})"
    return f"plain-ish data (entropy {ent:.2f})"


def extract_v15_submap(src):
    """v15 pre-base-85 substitution dictionary.

    v14.x used a single 'z' -> '!!!!!' zero-run shorthand. v15 generalises
    this to a per-build table literal mapping single characters to (usually
    5-char) expansions, e.g. `IA={[" "]="Wgv\\9",["("]=";5{w;", ...}`, applied
    with string.gsub before the base-85 pass. The variable name is randomised,
    so match on the shape: a run of ["<1 char>"]="<expansion>" pairs.

    Returns {char: expansion} (may be empty).
    """
    def unescape(s):
        try:
            return s.encode("utf-8", "surrogatepass").decode("unicode_escape")
        except Exception:
            return s
    best = {}
    for tbl in re.finditer(r"\{((?:\s*\[\"(?:\\.|[^\"\\])\"\]=\"(?:\\.|[^\"\\])+\","
                           r"?)+)\}", src):
        pairs = re.findall(r'\["((?:\\.|[^"\\]))"\]="((?:\\.|[^"\\])+?)"', tbl.group(1))
        m = {}
        for k, v in pairs:
            k, v = unescape(k), unescape(v)
            if len(k) == 1:
                m[k] = v
        # Keep the largest such table; the real substitution map dominates.
        if len(m) > len(best):
            best = m
    return best


def a85_decode_v15(body, submap, drop):
    """v15 decode: apply the char-substitution map, then the base-85 pass."""
    for k, v in submap.items():
        body = body.replace(k, v)
    return a85_decode(body, drop)


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

    v15_submap = extract_v15_submap(src)

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

        # v15 path: apply the per-build substitution map, re-base-85, and
        # report the recovered (still runtime-encrypted) VM buffer honestly.
        if not args.no_lzma and entropy(data) > 7.5 and v15_submap:
            v15data, _ = a85_decode_v15(body, v15_submap, drop)
            v15path = os.path.join(args.outdir, f"stage_{idx}.v15buf.bin")
            with open(v15path, "wb") as f:
                f.write(v15data)
            print(f"             v15: applied {len(v15_submap)}-entry substitution "
                  f"map + base-85 -> {len(v15data)} bytes")
            print(f"             -> {v15path}")
            print(f"             classify: {classify(v15data)}")
            print("             note: v15 has NO LZMA layer. This buffer is the "
                  "VM bytecode XOR-stream-encrypted at rest (bit32.bxor in the")
            print("                   readu8 path) and decrypted lazily during "
                  "execution, so it stays high-entropy statically. Recover it")
            print("                   at runtime (dynamic/) — see v15.md.")
            if leftover:
                print(f"             (a85 leftover {len(leftover)} chars: {leftover!r})")
            print(f"             (raw base-85 stage -> {outpath})")
            print()
            continue

        kind = classify(data)
        print(f"             {kind}")
        if not args.no_lzma and entropy(data) > 7.5:
            # High entropy that did NOT LZMA-decode: either a different codec
            # or genuine key-encryption. On v15, LPH_PRECHECK binds the
            # bytecode to a runtime-derived key, so a static peel is expected
            # to fail here — this is by design, not a bug in the unpacker.
            print("             note: base-85 layer removed, but the inner stream "
                  "did not LZMA-decode.")
            print("                   v15 can key-encrypt the bytecode "
                  "(LPH_PRECHECK) or use a new codec -> capture at runtime "
                  "instead (dynamic/). See v15.md.")
        if leftover:
            print(f"             (leftover {len(leftover)} chars: {leftover!r})")
        print(f"             -> {outpath}")
        print()

    print("[peel] done.\n"
          "       v13/v14.x: base-85 + LZMA removed statically (no key) ->\n"
          "         *.lua = recovered Lua source; *.bin = VM bytecode (see devirt.md).\n"
          "       v15: base-85 (+ per-build substitution map) removed ->\n"
          "         *.v15buf.bin = VM buffer, still XOR-encrypted at runtime\n"
          "         (no LZMA layer); recover it dynamically -> see v15.md.\n"
          "       Use strings.py for a quick IOC pass over any stage.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
