#!/usr/bin/env python3
# ============================================================
#  handler_category_scan.py  --  quantify opcode-handler categories across
#  a whole dispatch loop, not just a hand-read sample.
#
#  mm2.md's "K loop, fully characterized" section and its follow-ups found
#  several recurring handler shapes by reading a few by hand: plain
#  operand-decode (buffer.readu8 + multi-byte reassembly), a read->XOR->write
#  buffer-decrypt step, a conditional table lookup, a cons-cell-style
#  list-pop (X[1]=value, X[2]=next-pointer), and a store. This tool
#  automates recognizing those same shapes across every handler a dispatch
#  loop's opcode map (chain_opcode_semantics.py's output) references, so
#  "how common is category X in this loop" has a real count instead of
#  being asserted from the handful actually read.
#
#  Caught and fixed one real bug building this: a first version extracted
#  each handler's body with a fixed-size character window, which for SHORT
#  handlers bled into the next table entry entirely (confirmed on
#  sample_v15.lua's `Cu`: the window captured `,[38]=setfenv,qA=function
#  (...)...t[59](12)...` after Cu's own `end`, misattributing qA's decrypt
#  call to Cu). Fixed with a keyword-depth counter (function/if/while/for
#  open, end closes) that finds the handler's OWN closing `end` instead.
#  Luraph's handler bodies use `and/or` ternaries, not Luau's
#  `if...then...else` *expression* form (no `end`, and the exact thing that
#  broke a naive depth-counter once already in this project -- see
#  mm2.md's MM2 investigation) -- so a plain keyword counter is safe on
#  this specific shape of code, verified against the samples on file
#  before being trusted here.
#
#  The three special categories (decrypt/lookup/list-pop) are necessarily
#  sample-specific in ONE respect: which numeric constant-pool key resolves
#  to buffer.readu8/bit32.bxor/buffer.writeu8 differs per sample (they are
#  NOT hardcoded here -- pass them in, found the same way
#  loadstring_alias_dump.py resolves its own builtins: grep the sample for
#  `[N]=buffer.readu8` etc.).
#
#  Usage:
#    python3 devirt/handler_category_scan.py sample.lua opcode_map.json LOOP \
#        --read-key 56 --xor-key 46 --write-key 59
# ============================================================

import argparse
import json
import re
import sys
from collections import Counter, defaultdict


def extract_body(src, name, max_len=4000):
    bare = name.split(':')[-1]
    m = re.search(r'(?<![:\w])' + re.escape(bare) + r'=function\(', src)
    if not m:
        return None
    window = src[m.start():m.start() + max_len]
    depth = 0
    for tok in re.finditer(r'\b(function|if|while|for|end)\b', window):
        if tok.group(1) == 'end':
            depth -= 1
            if depth == 0:
                return window[:tok.end()]
        else:
            depth += 1
    return window  # unterminated within max_len -- caller sees a truncated body


def classify(body, read_key, xor_key, write_key):
    if body is None:
        return "NOT-FOUND"
    if re.search(r'\.\w+\s*=\s*\.\.\.', body):
        return "VARARG-ENTRY"
    if re.search(r'return\s+t\[\d+\]\(\w+,\s*1\s*,', body):
        return "RETURN-TRAMPOLINE"
    has_read = read_key and re.search(r't\[' + re.escape(read_key) + r'\]\(', body)
    has_xor = xor_key and re.search(r't\[' + re.escape(xor_key) + r'\]\(', body)
    has_write = write_key and re.search(r't\[' + re.escape(write_key) + r'\]\(', body)
    if has_read and has_xor and has_write:
        return "DECRYPT(read-xor-write)"
    if re.search(r'local (\w+)=t\[\w+\];if (not not )?\1', body):
        return "LOOKUP"
    first_branch = body.split('elseif', 1)[0].split('else', 1)[0]
    if re.search(r'\w+\[1\]', first_branch) and not has_read:
        return "LIST-POP"
    has_scale = any(c in body for c in ('16384', '2097152', '128*', '*128'))
    if has_read and has_scale:
        return "OPERAND-DECODE"
    if has_read:
        return "OPERAND-DECODE(short)"
    if re.search(r';\s*\w+\[\w+\]\s*=\s*\w+;', body):
        return "STORE"
    return "UNCLASSIFIED"


def main():
    ap = argparse.ArgumentParser(
        description="quantify opcode-handler categories across a whole dispatch loop")
    ap.add_argument("sample")
    ap.add_argument("opcode_map", help="chain_opcode_semantics.py --json output")
    ap.add_argument("loop", help="dispatch-loop key inside opcode_map (e.g. K, G, _, c, d, S)")
    ap.add_argument("--read-key", help="constant-pool numeric key resolving to buffer.readu8")
    ap.add_argument("--xor-key", help="constant-pool numeric key resolving to bit32.bxor")
    ap.add_argument("--write-key", help="constant-pool numeric key resolving to buffer.writeu8")
    ap.add_argument("--json")
    args = ap.parse_args()

    src = open(args.sample, encoding="utf-8", errors="replace").read()
    d = json.load(open(args.opcode_map))
    if args.loop not in d["dispatch_loops"]:
        sys.exit(f"!! loop '{args.loop}' not in {args.opcode_map}: {sorted(d['dispatch_loops'])}")
    names = sorted(set(c for op in d["dispatch_loops"][args.loop]["opcodes"] for c in op["calls"]))

    counts = Counter()
    by_cat = defaultdict(list)
    for n in names:
        body = extract_body(src, n)
        cat = classify(body, args.read_key, args.xor_key, args.write_key)
        counts[cat] += 1
        by_cat[cat].append(n)

    print(f"[handler-category-scan] {args.sample} loop '{args.loop}': {len(names)} handlers")
    for cat, n in counts.most_common():
        print(f"  {cat}: {n}  e.g. {by_cat[cat][:6]}")

    if args.json:
        json.dump({"sample": args.sample, "loop": args.loop, "total": len(names),
                   "counts": dict(counts), "by_category": dict(by_cat)},
                  open(args.json, "w"), indent=1)
        print(f"  -> {args.json}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
