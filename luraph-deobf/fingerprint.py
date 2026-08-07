#!/usr/bin/env python3
# ============================================================
#  fingerprint.py  --  Luraph static fingerprint + strategy pass
#
#  A fast, no-execution triage that runs BEFORE peel/devirt and tells you
#  what you're looking at and how to attack it. It adopts the static
#  strengths of other public Luraph tooling (macro tracking, bootstrap
#  classification, protection detection) so the pipeline isn't hard-wired
#  to the single v14.7 base-85+LZMA path.
#
#  Reports:
#    * version              (from the "-- Luraph Obfuscator vN.N" tag / lura.ph)
#    * LPH_* macros present  (LPH_ENCSTR / LPH_NO_VIRTUALIZE / LPH_JIT / ...)
#    * packed streams        (count, bracket level, header, size, D offset)
#    * bootstrap layers      (base-85, LZMA, XOR loops, fragmentation, config)
#    * anti-tamper probe      (the loadstring("\x1bLuaP") integrity check)
#    * a recommended strategy (which tool/stage to run next, and caveats)
#
#  Usage:
#     python3 fingerprint.py <script.lua> [--json]
# ============================================================

import argparse
import json
import re
import sys

try:
    from peel import find_long_bracket_strings   # reuse the exact stream finder
except Exception:                                # standalone fallback
    def find_long_bracket_strings(src):
        out = []
        for m in re.finditer(r"\[(=*)\[", src):
            lvl = m.group(1)
            close = "]" + "=" * len(lvl) + "]"
            end = src.find(close, m.end())
            if end == -1:
                continue
            body = src[m.end():end]
            out.append((len(lvl), body[:8], body))
        return out

# Luraph build-time macros (https://lura.ph/dashboard/documents/macros). Presence
# in the *plaintext* wrapper tells you which transforms/behaviours are in play.
LPH_MACROS = {
    "LPH_NO_VIRTUALIZE": "code region is NOT virtualised — reads as ordinary Lua after peel",
    "LPH_ENCSTR":        "per-string encryption — strings decode at use-time, not in the pool",
    "LPH_ENCNUM":        "numeric-constant encryption",
    "LPH_JIT":           "JIT-style handler specialisation (bigger dispatch)",
    "LPH_NO_UPVALUES":   "upvalue lifting disabled (needs load/loadstring present)",
    "LPH_SKIP":          "region skipped by the obfuscator entirely",
    "LPH_CRASH":         "intentional crash trap if tampered",
    "LPH_ENCFUNC":       "function-level encryption",
    "LPH_LUAU":          "Luau target (buffer/bit32/continue in the VM)",
    "LPH_STR": "string macro", "LPH_NUM": "number macro", "LPH_BOOL": "bool macro",
    "LPH_ONLY_INJECT": "inject-only region", "LPH_DEBUG": "debug build",
}

ANTI_TAMPER = [
    (r'loadstring\(\s*["\']\\27LuaP', 'loadstring("\\27LuaP") 2nd-return probe (W5)'),
    (r'\\27LuaP', "\\27LuaP integrity magic (string form)"),
    # v14.x hides the \x1bLuaP magic as a byte array: {0x1B,0x4C,0x75,0x61,0x50}
    (r'0x1B\s*,\s*0x4C\s*,\s*0x75\s*,\s*0x61\s*,\s*0x50', "LuaP magic as hex byte-array (W5 probe)"),
    (r'\b27\s*,\s*76\s*,\s*117\s*,\s*97\s*,\s*80\b', "LuaP magic as decimal byte-array (W5 probe)"),
    (r'error"attempt to index', "decoy error string (fake index error)"),
]


def scan_bootstrap(src, stream_bodies):
    """Classify the outer transforms present in the plaintext wrapper."""
    layers = []
    # base-85 shorthand: the 'z' zero-run + 5-char groups are peel's signature
    if re.search(r'gsub\(\s*["\']z["\']', src) or re.search(r'string\.rep', src):
        layers.append(("base-85", "Ascii85 variant with 'z' zero-run shorthand"))
    # pure-Lua LZMA range decoder markers
    if re.search(r'string\.pack|<I4|rrotate|rep\(.*32', src) and len("".join(stream_bodies)) > 4000:
        layers.append(("LZMA1", "pure-Lua range decoder (lc3/lp0/pb0) — keyless compression"))
    # XOR-based outer layer (other Luraph builds)
    xors = len(re.findall(r'bxor|bit32\.bxor|\bBit\d*\.bxor|~=?', src))
    if re.search(r'bxor|bit32\.bxor', src):
        layers.append(("XOR", f"byte-wise XOR loop(s) detected (~{xors} bxor refs) — reverse with the key salt"))
    # fragmentation: payload split across multiple concatenated streams
    if len(stream_bodies) > 1:
        layers.append(("fragmentation", f"{len(stream_bodies)} packed streams (VM source + bytecode, or split payload)"))
    # config table
    if re.search(r'local\s+\w+\s*=\s*\{[^}]*\b(nextCommmit|Service|Identifier|whitelist|key)\b', src, re.I):
        layers.append(("config-table", "inline config table (service/identifier/whitelist keys)"))
    return layers


def guess_D(header):
    """Header offset D that peel strips. v14.x uses D=5 ('LPH%V' etc.)."""
    return 5 if header.startswith("LPH") else 1


def fingerprint(src):
    fp = {"bytes": len(src)}
    m = re.search(r'Luraph Obfuscator v([\d.]+)', src)
    fp["version"] = m.group(1) if m else ("unknown (lura.ph)" if "lura.ph" in src else "not-luraph?")
    fp["macros"] = [k for k in LPH_MACROS if re.search(r'\b' + k + r'\b', src)]

    streams = [(lvl, hdr, body) for (lvl, hdr, body) in find_long_bracket_strings(src)
               if hdr.startswith("LPH")]
    fp["streams"] = [{
        "level": lvl, "header": hdr, "encoded_chars": len(body), "D": guess_D(hdr),
    } for (lvl, hdr, body) in streams]

    fp["layers"] = scan_bootstrap(src, [b for (_, _, b) in streams])
    fp["anti_tamper"] = [desc for (pat, desc) in ANTI_TAMPER if re.search(pat, src)]

    # plaintext head: how much readable Lua precedes the first packed stream
    first = src.find("[==[") if "[==[" in src else src.find("[=[")
    fp["plaintext_head_lines"] = src[:first].count("\n") if first > 0 else 0

    # recommend a strategy
    rec = []
    if "LPH_NO_VIRTUALIZE" in fp["macros"]:
        rec.append("NO_VIRTUALIZE present → peel.py, then read the region as ordinary Lua "
                   "(skip devirt for it).")
    if any(l[0] == "base-85" for l in fp["layers"]) or fp["streams"]:
        rec.append("Packed LPH streams → `peel.py` (base-85→LZMA, keyless, fully static).")
    if any(l[0] == "XOR" for l in fp["layers"]):
        rec.append("XOR layer → reverse it with the salt from the bootstrap loop before LZMA.")
    if "LPH_ENCSTR" in fp["macros"]:
        rec.append("ENCSTR → program strings decode per-use; run `env_logger.lua` in an "
                   "executor (debug.getconstants) or the sandbox to recover them.")
    rec.append("For the whole constant pool incl. cold code → `env_logger.lua` (getgc + "
               "debug.getconstants). For readable logic → `devirt/` lift.")
    fp["strategy"] = rec
    return fp


def render(fp):
    L = []
    L.append(f"Luraph fingerprint  ({fp['bytes']:,} bytes)")
    L.append(f"  version        : {fp['version']}")
    L.append(f"  plaintext head : {fp['plaintext_head_lines']} lines before first packed stream")
    L.append(f"  macros         : {', '.join(fp['macros']) or '(none in plaintext)'}")
    for k in fp["macros"]:
        L.append(f"      - {k}: {LPH_MACROS.get(k,'')}")
    L.append(f"  packed streams : {len(fp['streams'])}")
    for i, s in enumerate(fp["streams"]):
        L.append(f"      [{i}] bracket=[{'='*s['level']}[  header={s['header']!r}  "
                 f"{s['encoded_chars']:,} chars  D={s['D']}")
    L.append(f"  outer layers   :")
    for name, desc in fp["layers"]:
        L.append(f"      - {name}: {desc}")
    if not fp["layers"]:
        L.append("      (none detected)")
    L.append(f"  anti-tamper    : {', '.join(fp['anti_tamper']) or '(none)'}")
    L.append("  strategy:")
    for r in fp["strategy"]:
        L.append(f"      • {r}")
    return "\n".join(L)


def main():
    ap = argparse.ArgumentParser(description="Luraph static fingerprint + strategy")
    ap.add_argument("sample")
    ap.add_argument("--json", action="store_true", help="emit machine-readable JSON")
    args = ap.parse_args()
    with open(args.sample, "r", encoding="utf-8", errors="replace") as f:
        src = f.read()
    fp = fingerprint(src)
    print(json.dumps(fp, indent=2) if args.json else render(fp))
    return 0


if __name__ == "__main__":
    sys.exit(main())
