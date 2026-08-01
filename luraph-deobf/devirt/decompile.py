#!/usr/bin/env python3
# ============================================================
#  decompile.py  --  fold the lifted register IR toward source-like Lua
#
#  lift.py emits one line per VM instruction (register-machine form). This
#  pass runs a conservative single-block decompiler over that IR to make it
#  read like normal Lua:
#
#    * forward copy-propagation / expression folding: a register defined by
#      a side-effect-free op and read exactly once, before being redefined,
#      is inlined at its use and its definition line dropped. This collapses
#      the pervasive  e[15]=e[0]["game"]; e[15](x)  chains into  e[0]["game"](x).
#    * real constants/keys inlined (from capture_values), so fields read as
#      ["GetService"], numbers as literals.
#    * control flow kept as the structured goto form from lift (correct;
#      folding into if/while is a separate, riskier pass).
#
#  HONEST CEILING. This produces readable, semantically-faithful Lua with
#  INVENTED register names (e[n]) — it does NOT recover the author's original
#  variable names or exact high-level syntax, because Luraph destroys those
#  at compile time. This is the maximum a VM-obfuscated file allows; it is an
#  analysis artifact (read it), not a runnable program.
#
#  Folding is intra-block and only over side-effect-free single-use temps, so
#  it is conservative. The output is checked to compile as Lua 5.4 in tests.
#
#  Usage:
#    python3 run_vm.py --vmdir peeled --luau ./luau --mode fulldump --out full.txt
#    python3 capture_values.py --vmdir peeled --luau ./luau --map opcodes.full.json --out values.txt
#    python3 decompile.py full.txt --map opcodes.full.json --values values.txt -o decompiled.lua
# ============================================================

import argparse
import json
import re
import sys

import lift  # reuse parse_fulldump, build_blocks, linearise, classify, opval, is_pc

FOLDABLE = {"loadk", "newtable", "move", "add", "gettable", "compare", "arith"}


def reg(x):
    return f"e[{x}]" if x is not None else "?"


def decompile_proto(pid, instrs, opmap, values):
    n = len(instrs)
    blocks, entry = lift.build_blocks(instrs, n)
    order = lift.linearise(blocks, entry)
    pos = {b: i for i, b in enumerate(order)}

    # which labels are targeted (emit only those)
    referenced = set()

    def op_meta(op):
        e = opmap.get(str(op)) or {}
        return e.get("name", "op?"), lift.CLASS.get(op, "unknown"), e.get("dst")

    # per-class register READ operands and WRITE operand (dst role letter)
    READS = {"gettable": ["a"], "settable": ["a", "c"], "call": ["a", "c"],
             "move": ["a"], "add": ["c"], "compare": ["a", "c"], "branch": ["a"]}
    # ops whose value is safe to inline at a single use site
    SAFE_FOLD = {"loadk", "move", "add", "compare", "gettable"}

    out_blocks = []
    for i, start in enumerate(order):
        blk = blocks[start]
        body = blk["instrs"]
        datbody = body[:-1]

        # ---- count reads/writes per register in this block (incl. terminator) ----
        rcount, wcount = {}, {}
        for (pc, op, ops) in body:
            _, cls, dst = op_meta(op)
            for role in READS.get(cls, []):
                rv = lift.opval(ops, role)
                if isinstance(rv, int):
                    rcount[rv] = rcount.get(rv, 0) + 1
            if cls in ("gettable", "loadk", "newtable", "compare") and dst:
                dv = lift.opval(ops, dst)
                if isinstance(dv, int):
                    wcount[dv] = wcount.get(dv, 0) + 1
            elif cls == "move":
                dv = lift.opval(ops, "b");  wcount[dv] = wcount.get(dv, 0) + 1 if isinstance(dv, int) else wcount.get(dv, 0)
            elif cls == "add":
                dv = lift.opval(ops, "a"); wcount[dv] = wcount.get(dv, 0) + 1 if isinstance(dv, int) else wcount.get(dv, 0)

        expr = {}

        def ref(rn):
            """Inline reg rn's expression only if it is provably single def +
            single use in this block and side-effect-free; else its slot."""
            info = expr.get(rn)
            if (info and info["foldable"] and not info["dead"]
                    and rcount.get(rn, 0) == 1 and wcount.get(rn, 0) == 1):
                info["dead"] = True
                return info["text"]
            return reg(rn)

        emitted = []
        for (pc, op, ops) in datbody:
            name, cls, dst = op_meta(op)
            a, b, c, d = (lift.opval(ops, k) for k in "abcd")
            val = values.get((pid, pc))
            konst = val if val is not None else f"K({b})"
            drow = lift.dst_reg(dst, a, b, c)

            if cls == "gettable":
                text = f"{ref(a)}[{konst}]"
                entry = {"text": text, "foldable": True, "uses": 1, "dead": False}
                expr[drow] = entry
                emitted.append((entry, f"{reg(drow)} = {text}"))
            elif cls == "loadk":
                entry = {"text": konst, "foldable": True, "uses": 1, "dead": False}
                expr[drow] = entry
                emitted.append((entry, f"{reg(drow)} = {konst}"))
            elif cls == "newtable":
                # never fold a table (it usually persists / aliases)
                entry = {"text": "{}", "foldable": False, "uses": 1, "dead": False}
                expr[drow] = entry
                emitted.append((entry, f"{reg(drow)} = {{}}"))
            elif cls == "move":
                text = ref(a)
                entry = {"text": text, "foldable": True, "uses": 1, "dead": False}
                expr[b] = entry
                emitted.append((entry, f"{reg(b)} = {text}"))
            elif cls == "add":
                text = f"{ref(c)} + {d}"
                entry = {"text": f"({text})", "foldable": True, "uses": 1, "dead": False}
                expr[a] = entry
                emitted.append((entry, f"{reg(a)} = {text}"))
            elif cls == "compare":
                text = f"({ref(a)} == {ref(c)})"
                entry = {"text": text, "foldable": True, "uses": 1, "dead": False}
                expr[drow] = entry
                emitted.append((entry, f"{reg(drow)} = {text}"))
            elif cls == "call":
                callee = ref(a)
                if dst:
                    entry = {"text": f"{callee}({ref(c)})", "foldable": False,
                             "uses": 1, "dead": False}
                    expr[drow] = entry
                    emitted.append((entry, f"{reg(drow)} = {callee}({ref(c)})"))
                else:
                    emitted.append((None, f"{callee}({ref(c)})"))
            elif cls == "settable":
                emitted.append((None, f"{ref(a)}[{konst}] = {ref(c)}"))
            else:  # dataop / unknown -> keep raw, non-foldable
                raw = " ".join(f"{k}={ops[k]}" for k in "abcd" if k in ops)
                emitted.append((None, f"-- {name} [{raw}]"))

        # terminator
        term = None
        lpc, lop, lops = body[-1]
        _, tcls, _ = op_meta(lop)
        nextblk = order[i + 1] if i + 1 < len(order) else None
        if tcls == "jump":
            t = lift.opval(lops, "b")
            if lift.is_pc(t, n) and t != nextblk:
                term = f"goto L_{t}"; referenced.add(t)
        elif tcls == "branch":
            t = lift.opval(lops, "b"); a = lift.opval(lops, "a")
            cond = ref(a)
            if lift.is_pc(t, n):
                if blk["fall"] == nextblk:
                    term = f"if {cond} then goto L_{t} end"; referenced.add(t)
                else:
                    term = f"if {cond} then goto L_{t} else goto L_{blk['fall']} end"
                    referenced.add(t); referenced.add(blk["fall"])
        elif tcls == "return":
            term = "do return end"
        else:
            # terminator is a data op; emit it too
            name, cls, dst = op_meta(lop)
            a, b, c, d = (lift.opval(lops, k) for k in "abcd")
            if cls == "settable":
                emitted.append((None, f"{reg(a)}[K({b})] = {reg(c)}"))
            if blk["fall"] is not None and blk["fall"] != nextblk:
                term = f"goto L_{blk['fall']}"; referenced.add(blk["fall"])

        out_blocks.append((start, emitted, term))

    # render (drop dead defs whose expression got inlined)
    lines = [f"local function proto{pid}(...)  -- {n} instrs, decompiled",
             "  local e = regs"]
    for start, emitted, term in out_blocks:
        if start in referenced:
            lines.append(f"  ::L_{start}::")
        for entry, text in emitted:
            if entry is not None and entry.get("dead"):
                continue   # its expression was folded into a use
            lines.append("  " + text)
        if term:
            lines.append("  " + term)
    lines.append("end")
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser(description="fold lifted IR toward source-like Lua")
    ap.add_argument("fulldump")
    ap.add_argument("--map", default="opcodes.full.json")
    ap.add_argument("--values", default=None)
    ap.add_argument("-o", "--out", default="decompiled.lua")
    args = ap.parse_args()

    opmap = json.load(open(args.map))
    for op, e in opmap.items():
        if not op.startswith("_") and isinstance(e, dict):
            lift.CLASS[int(op)] = lift.classify(e.get("name", "op?"))

    values = {}
    if args.values:
        for l in open(args.values, errors="replace"):
            m = re.match(r"\[\[V\]\] p=(\d+) pc=(\d+) op=\S+ v=(.*)", l.rstrip())
            if m:
                values[(int(m.group(1)), int(m.group(2)))] = m.group(3)

    protos = lift.parse_fulldump(args.fulldump)
    ids = sorted(protos)
    body = "\n\n".join(decompile_proto(p, protos[p], opmap, values) for p in ids)
    header = (
        "-- Decompiled from Luraph v14.7 bytecode by luraph-deobf/devirt/decompile.py\n"
        "-- Expression-folded, register-level Lua. Semantically faithful; variable\n"
        "-- names are INVENTED (e[n]) -- originals are destroyed by virtualisation.\n"
        "-- Analysis artifact (read it); not a runnable program.\n"
        f"-- {len(ids)} protos, {len(values)} constants inlined.\n"
        "local regs = {}\n")
    with open(args.out, "w") as f:
        f.write(header + "\n" + body + "\n")
    print(f"[decompile] {len(ids)} protos -> {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
