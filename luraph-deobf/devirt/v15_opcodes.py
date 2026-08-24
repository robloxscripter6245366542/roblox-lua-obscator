#!/usr/bin/env python3
# ============================================================
#  v15_opcodes.py  --  Luraph v15 handler/opcode map builder
#
#  v15's VM is ~145 threaded "continuation" handlers stored as fields of one
#  `setmetatable({...})` table (see ../v15.md). This tool builds an opcode map
#  by STATICALLY classifying every handler and (optionally) overlaying the
#  DYNAMIC coverage from dynamic/run_v15.py's histogram, so the "remaining /
#  missing" opcodes are made explicit:
#
#    * defined but never exercised   -> needs more samples to hit
#    * exercised but unclassified    -> needs manual semantics
#    * classified                    -> best-effort operation label
#
#  For each handler it records: arity, the numeric library slots it calls
#  (resolved to buffer.*/bit32.*/string.* via the sample's own [N]=lib table),
#  the set of next-handler ids it returns (successor opcodes), and a heuristic
#  category. This is the v15 analogue of devirt/build_map.py.
#
#  Usage:
#    python3 devirt/v15_opcodes.py sample_v15.lua \
#        [--hist dyn.hist.txt] [--json out.json] [--md out.md]
# ============================================================

import argparse
import json
import re
import sys


def strip_noncode(src):
    """Remove long-bracket blobs and quoted strings so keyword matching on the
    handler bodies is not fooled by string contents."""
    out = []
    i = 0
    n = len(src)
    while i < n:
        m = re.match(r"\[(=*)\[", src[i:])
        if m:
            close = "]" + m.group(1) + "]"
            e = src.find(close, i + m.end())
            if e == -1:
                e = n
            out.append(" ")
            i = e + len(close)
            continue
        c = src[i]
        if c in "\"'":
            j = i + 1
            while j < n and src[j] != c:
                if src[j] == "\\":
                    j += 1
                j += 1
            out.append('""')
            i = j + 1
            continue
        out.append(c)
        i += 1
    return "".join(out)


def lib_slots(src):
    """Numeric slot -> library function name, from the sample's [N]=lib.fn."""
    return dict(re.findall(r"\[(\d+)\]=([A-Za-z_][\w.]*)", src))


# opener keywords that each consume one `end`; for/while are NOT counted
# because their `do` is (Lua: `for .. do .. end`, `while .. do .. end`).
_TOK = re.compile(r"\b(function|if|do|end|for|while|repeat|until)\b")


def handler_bodies(code):
    """Yield (name, params, body) for every `NAME=function(params) ... end`.

    NAME is a string key (word) or a numeric key [N]. Body is matched by
    balancing block openers/closers.
    """
    for m in re.finditer(r"(?:\[(\d+)\]|([A-Za-z_]\w*))=function\(([^)]*)\)", code):
        name = m.group(1) if m.group(1) is not None else m.group(2)
        params = [p.strip() for p in m.group(3).split(",") if p.strip()]
        depth = 1  # we're inside the function's own block
        i = m.end()
        while i < len(code) and depth > 0:
            t = _TOK.search(code, i)
            if not t:
                break
            w = t.group(1)
            if w in ("function", "if", "do"):
                depth += 1
            elif w == "end":
                depth -= 1
            # for/while/repeat/until don't change end-depth (see note above)
            i = t.end()
        body = code[m.end():t.start()] if t else code[m.end():]
        yield name, params, body


def classify(body, slots):
    """Heuristic operation category + the library primitives it touches."""
    used = sorted({slots[n] for n in re.findall(r"t\[(\d+)\]", body) if n in slots})
    has = lambda *p: any(any(u.startswith(x) for x in p) for u in used)
    # successor opcode ids: the numeric next-id in `return <id>, ...` and in the
    # `return true/false/nil, <id>, ...` resume form (id is the 2nd value there).
    succ = {int(x) for x in re.findall(r"return\s+(\d+)\b", body)}
    succ |= {int(x) for x in re.findall(r"return\s+(?:true|false|nil)\s*,\s*(\d+)", body)}
    succ = sorted(succ)
    # multi-way branch: compares a var and returns different ids
    branch = bool(re.search(r"(<=|<|==|~=|\bnot\b)", body)) and len(
        set(re.findall(r"return\s+(\w+)", body))) > 1

    cats = []
    if re.search(r"\breadu8\b|\breadu16\b|\breadu32\b|\breadf64\b|\breadstring\b",
                 " ".join(used)) or has("buffer.read"):
        cats.append("FETCH")               # reads bytecode operand bytes
    if has("buffer.write"):
        cats.append("STORE/DECRYPT")       # writes decrypted/computed byte
    if has("bit32"):
        cats.append("BITWISE")
    if has("string."):
        cats.append("STRING")
    if has("table.") or re.search(r"\{[^}]*\}", body):
        cats.append("TABLE/CONST")
    if re.search(r"\b[A-Z]\w*\([^)]*\)|[a-z]\(", body) and not cats:
        cats.append("CALL/OTHER")
    if branch:
        cats.append("BRANCH")
    if re.search(r"\berror\b", body):
        cats.append("HALT")
    if not cats:
        # fallbacks for the small, distinctive handlers with no lib call:
        if re.search(r"return\s+(?:true|false)\b", body):
            cats.append("RESUME")             # returns a control flag + next id
        elif re.search(r"%\s*4294967296|[*/%+\-]", body):
            cats.append("ARITH")              # u32 wrap / numeric helper
        elif re.search(r"\[[^\]]*\]\s*=\s*nil", body):
            cats.append("STORE-NIL")          # clears a register/table slot
        elif re.search(r"\[[^\]]*\]\s*=", body):
            cats.append("STORE")
        else:
            cats.append("MOVE/UNKNOWN")
    return "|".join(cats), used, succ


def load_hist(path):
    counts = {}
    if not path:
        return counts
    for line in open(path, encoding="utf-8", errors="replace"):
        m = re.match(r"\[\[VMH\]\] name=(\S+) calls=(\d+)", line)
        if m:
            counts[m.group(1)] = int(m.group(2))
    return counts


def main():
    ap = argparse.ArgumentParser(description="Luraph v15 opcode/handler map")
    ap.add_argument("sample")
    ap.add_argument("--hist", help="dynamic/run_v15.py <out>.hist.txt (coverage)")
    ap.add_argument("--json")
    ap.add_argument("--md")
    args = ap.parse_args()

    src = open(args.sample, encoding="utf-8", errors="replace").read()
    slots = lib_slots(src)
    code = strip_noncode(src)
    counts = load_hist(args.hist)

    handlers = {}
    for name, params, body in handler_bodies(code):
        cat, used, succ = classify(body, slots)
        handlers[name] = {
            "arity": len(params),
            "category": cat,
            "libs": used,
            "successors": succ,
            "calls": counts.get(name),   # None if no hist / never hit
        }

    total = len(handlers)
    exercised = [n for n, h in handlers.items() if h["calls"]]
    never = [n for n, h in handlers.items() if args.hist and not h["calls"]]
    unclassified = [n for n, h in handlers.items()
                    if h["category"] in ("MOVE/UNKNOWN",)]

    print(f"[v15-opcodes] {args.sample}")
    print(f"  handlers defined : {total}")
    print(f"  library slots    : {len(slots)}")
    if args.hist:
        print(f"  exercised (dyn)  : {len(exercised)}")
        print(f"  NEVER exercised  : {len(never)}  (need more samples)")
    print(f"  MOVE/UNKNOWN cat : {len(unclassified)}  (need manual semantics)")

    # category tally
    tally = {}
    for h in handlers.values():
        tally[h["category"]] = tally.get(h["category"], 0) + 1
    print("\n  category tally:")
    for c, k in sorted(tally.items(), key=lambda x: -x[1]):
        print(f"    {k:3}  {c}")

    if never:
        print("\n  missing (defined, never hit by this sample):")
        print("   ", " ".join(sorted(never)))

    result = {"sample": args.sample, "total": total,
              "exercised": sorted(exercised), "never_exercised": sorted(never),
              "unclassified": sorted(unclassified), "handlers": handlers}
    if args.json:
        json.dump(result, open(args.json, "w"), indent=1)
        print(f"\n  -> {args.json}")
    if args.md:
        with open(args.md, "w") as f:
            f.write(f"# v15 opcode/handler map — `{args.sample}`\n\n")
            f.write(f"- handlers defined: **{total}**, library slots: {len(slots)}\n")
            if args.hist:
                f.write(f"- exercised (dynamic): **{len(exercised)}**, "
                        f"never exercised: **{len(never)}**\n")
            f.write(f"- MOVE/UNKNOWN (need manual semantics): **{len(unclassified)}**\n\n")
            f.write("| handler | arity | category | calls | successors | libs |\n")
            f.write("|---|---|---|---|---|---|\n")
            for n in sorted(handlers, key=lambda k: -(handlers[k]["calls"] or 0)):
                h = handlers[n]
                f.write(f"| `{n}` | {h['arity']} | {h['category']} | "
                        f"{h['calls'] if h['calls'] is not None else '-'} | "
                        f"{','.join(map(str,h['successors'][:8]))} | "
                        f"{' '.join(h['libs'][:6])} |\n")
        print(f"  -> {args.md}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
