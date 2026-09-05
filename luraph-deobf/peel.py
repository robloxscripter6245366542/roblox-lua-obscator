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
#  Variant handling (detect_encoding()):
#  Not every build uses base-85 + LZMA -- some Luraph-family variants swap
#  in plain base64 for the outer layer, and/or skip the LZMA layer
#  entirely (the inner bytes are already the final Lua source/bytecode).
#  detect_encoding() tries base-85 and base64 across the plausible header
#  lengths and only accepts a result on a strong, unambiguous signal (a
#  clean LZMA decode, or directly-readable Lua source/bytecode) -- it
#  never picks base64 over base85 on a weak heuristic, since base64
#  decoding rarely raises an error even on the wrong input. Absent a
#  strong signal from either, it falls back to base-85's own
#  entropy-based drop guess, unchanged from the original single-encoding
#  behaviour (the correct path for a build with no compression layer at
#  all, or a runtime-only codec -- see v15.md).
#
#  Usage:
#     python3 peel.py <script.lua> [-o outdir] [--no-lzma] [-D drop]
# ============================================================

import argparse
import base64
import binascii
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
    """Yield (label, header, body) for every [=[ .. ]=] of any level.

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
        out.append((f"[{level}[ bracket", header, body))
    return out


def find_quoted_lph_strings(src):
    """Yield (label, header, body) for every double-quoted "LPH..." literal.

    Executor decompilers (GameCodeDumper and similar) re-emit Luraph's
    packed stream as a plain quoted string argument -- e.g.
    `p_u_812[35] = v830("LPH}!!M...")` -- rather than the long-bracket form
    the original obfuscated source uses. Same payload, different quoting,
    so it needs its own lexer-level scan (long-bracket strings don't nest
    inside quotes and vice versa) and a Lua-escape unescape pass before the
    base-85 decode below can see the real characters.
    """
    out = []
    for m in re.finditer(r'"(LPH(?:\\.|[^"\\])*)"', src):
        body = m.group(1)
        body = re.sub(r"\\(.)", lambda mm: mm.group(1) if mm.group(1) in "\"'\\" else mm.group(0), body)
        header = body[:8]
        out.append(("quoted string", header, body))
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


def b64_decode(body, drop=1):
    """Standard/URL-safe base64, tolerant of missing padding and whitespace.

    Some Luraph-family variants swap the outer base-85 pass for plain
    base64 instead. `drop` works the same as a85_decode's: 1-indexed,
    keeps from the drop-th char, so a build with a short ASCII header
    before the base64 blob is still handled the same way.
    """
    s = re.sub(r"\s+", "", body[drop - 1:])
    pad = (-len(s)) % 4
    for variant, table in (("std", None), ("urlsafe", str.maketrans("-_", "+/"))):
        candidate = s.translate(table) if table else s
        try:
            return base64.b64decode(candidate + "=" * pad, validate=False), variant
        except (binascii.Error, ValueError):
            continue
    return None, None


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


def _score(data):
    """Higher = more likely to be the real decode: low entropy or a
    recognisable magic beats high-entropy noise from a wrong guess."""
    if not data:
        return -1.0
    return (8.0 - entropy(data[:4096])) + (4.0 if data.startswith(LUA_MAGIC) else 0.0)


def detect_encoding(body, forced_drop=None):
    """Auto-detect both the outer encoding (base-85 vs base64) and the
    header length D the loader strips before it.

    v14.x uses base-85 with D=5 ('LPH%V', 'LPH>&', ...). Not every
    Luraph-family build does -- some swap in plain base64 instead, and D
    varies by header length. Returns (encoding, drop, decoded_bytes).

    Priority matters here: base64 almost always "succeeds" on garbage (it's
    lenient about padding), just less cleanly, so it must never be allowed
    to outscore a85 on the weak entropy-based fallback -- only a strong,
    unambiguous signal (a clean LZMA decode, or directly-readable output)
    can make base64 win. Absent that from EITHER encoding, fall back to
    a85's own entropy-based drop guess exactly as before base64 support
    existed, since that's the verified-correct path for builds where the
    inner stream doesn't decompress or read cleanly (no compression layer
    at all, or a runtime-only codec -- see the v15 notes in main()).
    """
    drops = (forced_drop,) if forced_drop is not None else (5, 4, 6, 3, 7, 1)

    def strong_signal(data):
        if not data:
            return False
        dec, _ = lzma_raw_decompress(data)
        return dec is not None or looks_like_lua_source(data) or data.startswith(LUA_MAGIC)

    for encoding, decode_fn in (("a85", a85_decode), ("base64", b64_decode)):
        for d in drops:
            data, _ = decode_fn(body, d)
            if strong_signal(data):
                return encoding, d, data

    # No strong signal from either encoding -- a85's own entropy fallback,
    # unchanged from the original (base64-unaware) behaviour.
    best_drop, best_score = 5, -1.0
    for d in drops:
        data, _ = a85_decode(body, d)
        score = _score(data)
        if score > best_score:
            best_score, best_drop = score, d
    data, _ = a85_decode(body, best_drop)
    return "a85", best_drop, data


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

    strings = find_long_bracket_strings(src) + find_quoted_lph_strings(src)
    # Real Luraph packed streams carry the 'LPH' header. Requiring it avoids
    # false positives from stray [[ .. ]] / quoted-string runs elsewhere.
    packed = [(label, hdr, body) for (label, hdr, body) in strings
              if hdr.startswith("LPH")]

    if not packed:
        print("No LPH-headed packed streams found. This may not be a "
              "Luraph-packed file, or it uses a different container.")
        return 1

    os.makedirs(args.outdir, exist_ok=True)
    print(f"[peel] {args.input}: {len(packed)} packed stream(s) found\n")

    v15_submap = extract_v15_submap(src)

    for idx, (label, hdr, body) in enumerate(packed):
        encoding, drop, data = detect_encoding(body, forced_drop=args.drop)
        decode_fn = a85_decode if encoding == "a85" else b64_decode
        _, extra = decode_fn(body, drop)  # re-run once for the display-only leftover/variant
        outpath = os.path.join(args.outdir, f"stage_{idx}.bin")
        with open(outpath, "wb") as f:
            f.write(data)
        print(f"  stage[{idx}]  source={label}  header={hdr!r}")
        enc_label = "base-85" if encoding == "a85" else f"base64 ({extra})"
        print(f"             encoded {len(body):>8} chars -> {len(data):>8} bytes"
              f"  ({enc_label}, drop={drop})")

        if not args.no_lzma:
            dec, ds = lzma_raw_decompress(data)
            if dec is not None:
                if looks_like_lua_source(dec):
                    ext, stage_label = "lua", "LUA SOURCE (VM interpreter / loader)"
                elif dec.startswith(LUA_MAGIC):
                    ext, stage_label = "luac", "lua 5.1 bytecode"
                else:
                    ext, stage_label = "bin", "VM bytecode / binary program"
                decpath = os.path.join(args.outdir, f"stage_{idx}.{ext}")
                with open(decpath, "wb") as f:
                    f.write(dec)
                print(f"             LZMA -> {len(dec):>8} bytes  "
                      f"[dict {ds >> 10}KB]  {stage_label}")
                print(f"             -> {decpath}")
                if encoding == "a85" and extra:
                    print(f"             (leftover {len(extra)} chars: {extra!r})")
                print()
                continue

            # No LZMA layer: some builds skip compression entirely, so a
            # directly-readable result here is just as final as an LZMA hit.
            if looks_like_lua_source(data):
                decpath = os.path.join(args.outdir, f"stage_{idx}.lua")
                with open(decpath, "wb") as f:
                    f.write(data)
                print(f"             no LZMA layer -- {enc_label} decode is already "
                      f"readable Lua source ({len(data)} bytes)")
                print(f"             -> {decpath}")
                print()
                continue
            if data.startswith(LUA_MAGIC):
                decpath = os.path.join(args.outdir, f"stage_{idx}.luac")
                with open(decpath, "wb") as f:
                    f.write(data)
                print(f"             no LZMA layer -- {enc_label} decode is already "
                      f"Lua 5.1 bytecode ({len(data)} bytes)")
                print(f"             -> {decpath}")
                print()
                continue

        # v15 path: apply the per-build substitution map, re-base-85, and
        # report the recovered (still runtime-encrypted) VM buffer honestly.
        # (v15's substitution scheme is only verified for the base-85 outer
        # layer; skip this path if base64 was the better-scoring encoding.)
        if not args.no_lzma and encoding == "a85" and entropy(data) > 7.5 and v15_submap:
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
            if extra:
                print(f"             (leftover {len(extra)} chars: {extra!r})")
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
            print(f"             note: {enc_label} layer removed, but the inner "
                  "stream did not LZMA-decode and isn't directly readable either.")
            print("                   v15 can key-encrypt the bytecode "
                  "(LPH_PRECHECK) or use a new codec -> capture at runtime "
                  "instead (dynamic/). See v15.md.")
        if encoding == "a85" and extra:
            print(f"             (leftover {len(extra)} chars: {extra!r})")
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
