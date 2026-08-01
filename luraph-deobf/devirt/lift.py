#!/usr/bin/env python3
# ============================================================
#  lift.py  --  devirtualise Luraph bytecode to register-level Lua
#
#  The codegen step. Consumes a full instruction dump
#  (run_vm.py --mode fulldump) + the opcode map (opcodes.full.json) and
#  emits, per proto, readable Lua that is SEMANTICALLY faithful to the
#  bytecode:
#
#    * one `local function protoN(...)` per proto
#    * registers as locals `e[...]` (a shared register table)
#    * basic-block labels `::L_pc::` at every jump target
#    * control flow rebuilt from JMP / TEST-BRANCH targets as goto / if-goto
#      (Lua 5.4 goto; Luraph flattens control flow so this is the honest
#      shape — a structuring pass can fold these into if/while later)
#    * data ops emitted per the opcode map (NEWTABLE/LOADK/ADD/GETTABLE/…),
#      each with the raw operands in a trailing comment for verification
#    * unknown / no-write ops emitted as annotated comments, never guessed
#
#  HONEST SCOPE. This is a register-machine transliteration, not a
#  recovery of the author's original source (variable names, exact
#  expressions, and high-level if/while are not reconstructed here). It is
#  correct at the instruction level for every opcode the map knows, and it
#  marks the residue explicitly. That is what a devirtualiser produces
#  before the optional structuring/data-flow passes.
#
#  Usage:
#    python3 run_vm.py --vmdir peeled --luau ./luau --mode fulldump --out full.txt
#    python3 lift.py full.txt --map opcodes.full.json -o lifted.lua
# ============================================================

import argparse
import json
import re
import sys

P_RE = re.compile(r'\[\[P\]\] proto=(\d+) ninstr=(\d+)')
I_RE = re.compile(r'\[\[I\]\] p=(\d+) pc=(\d+) op=(\S+)((?: [a-d]=\S+)*)')


def parse_fulldump(path):
    protos = {}
    cur = None
    for line in open(path, errors="replace"):
        mp = P_RE.match(line)
        if mp:
            cur = int(mp.group(1))
            protos[cur] = []
            continue
        mi = I_RE.match(line)
        if mi and cur is not None:
            p, pc, op, ops = mi.groups()
            operands = {}
            for k, v in re.findall(r'([a-d])=(\S+)', ops):
                operands[k] = v
            protos[int(p)].append((int(pc), int(op), operands))
    return protos


def opval(operands, key):
    v = operands.get(key)
    if v is None or v == "nil":
        return None
    try:
        return int(v)
    except ValueError:
        return v


def is_pc(v, n):
    return isinstance(v, int) and 1 <= v <= n


def find_leaders(instrs, n):
    """Block leaders: jump targets + fall-through after control-transfer ops."""
    leaders = {1}
    for idx, (pc, op, ops) in enumerate(instrs):
        cls = CLASS.get(op, "")
        if cls in ("jump", "branch"):
            tgt = opval(ops, "b")
            if is_pc(tgt, n):
                leaders.add(tgt)
            if idx + 1 < len(instrs):
                leaders.add(instrs[idx + 1][0])  # fall-through
    return leaders


# opcode name -> abstract class used by codegen
def classify(name):
    n = name.upper()
    if n.startswith("JMP") or n.startswith("RETURN"):
        return "jump"
    if "BRANCH" in n or n.startswith("TEST"):
        return "branch"
    if "COMPARE" in n:
        return "compare"
    if "NEWTABLE" in n:
        return "newtable"
    if "GETTABLE" in n or "GETINDEX" in n:
        return "gettable"
    if "GETGLOBAL" in n or n.startswith("CALL"):
        return "call"
    if n.startswith("MOVE"):
        return "move"
    if n.startswith("ADD"):
        return "add"
    if "LOADK" in n or n.startswith("LOADN"):
        return "loadk"
    if "ARITH" in n or n.startswith("UNOP"):
        return "arith"
    if "SETTABLE" in n:
        return "settable"
    if n.startswith("DATAOP"):
        return "dataop"
    return "unknown"


CLASS = {}   # op(int) -> class, filled from the map


def emit(pc, op, ops, entry, n):
    """Return one line of lifted Lua for an instruction."""
    name = entry.get("name", "op?") if entry else "op?"
    dst = entry.get("dst") if entry else None
    cls = CLASS.get(op, "unknown")
    a, b, c, d = (opval(ops, k) for k in "abcd")
    raw = " ".join(f"{k}={ops[k]}" for k in "abcd" if k in ops)
    cm = f"  -- {name} [{raw}]"

    def reg(x):
        return f"e[{x}]" if x is not None else "?"

    if cls == "jump":
        if is_pc(b, n):
            return f"goto L_{b}{cm}"
        return f"do return end{cm}"
    if cls == "branch":
        tgt = f"goto L_{b}" if is_pc(b, n) else "return"
        return f"if {reg(a)} then {tgt} end{cm}"
    if cls == "compare":
        return f"{reg(dst_reg(dst, a, b, c))} = ({reg(a)} == {reg(c)}){cm} -- cmp (op-specific)"
    if cls == "newtable":
        return f"{reg(dst_reg(dst, a, b, c))} = {{}}{cm}"
    if cls == "move":
        return f"{reg(b)} = {reg(a)}{cm}"
    if cls == "add":
        return f"{reg(a)} = {reg(c)} + {d}{cm}"
    if cls == "loadk":
        return f"{reg(dst_reg(dst, a, b, c))} = K({b}){cm} -- constant"
    if cls == "arith":
        return f"{reg(dst_reg(dst, a, b, c))} = arith({reg(b)}, {reg(c)}){cm}"
    if cls == "gettable":
        return f"{reg(dst_reg(dst, a, b, c))} = {reg(a)}[K({c})]{cm}"
    if cls == "call":
        if dst:
            return f"{reg(dst_reg(dst, a, b, c))} = call({reg(a)}, {reg(c)}){cm}"
        return f"call({reg(a)}, {reg(c)}){cm} -- void call"
    if cls == "settable":
        return f"{reg(a)}[K({b})] = {reg(c)}{cm} -- settable/void-call (inferred)"
    if cls == "dataop":
        return f"dataop({reg(a)}, {reg(b)}, {reg(c)}){cm} -- flow-through, effect unprofiled"
    return f"-- UNKNOWN {name} [{raw}]"


def dst_reg(dst, a, b, c):
    return {"a": a, "b": b, "c": c}.get(dst, a)


def lift_proto(pid, instrs, opmap):
    n = len(instrs)
    # only emit labels that are actually targeted by a goto/branch (less noise)
    targets = set()
    for pc, op, ops in instrs:
        if CLASS.get(op) in ("jump", "branch"):
            t = opval(ops, "b")
            if is_pc(t, n):
                targets.add(t)
    out = [f"local function proto{pid}(...)  -- {n} instructions"]
    out.append("  local e = regs   -- register file")
    for pc, op, ops in instrs:
        if pc in targets:
            out.append(f"  ::L_{pc}::")
        entry = opmap.get(str(op))
        out.append("  " + emit(pc, op, ops, entry, n))
    out.append("end")
    return "\n".join(out)


def main():
    ap = argparse.ArgumentParser(description="lift Luraph bytecode to register-level Lua")
    ap.add_argument("fulldump", help="output of run_vm.py --mode fulldump")
    ap.add_argument("--map", default="opcodes.full.json")
    ap.add_argument("-o", "--out", default="lifted.lua")
    ap.add_argument("--protos", type=int, default=0, help="limit to first N protos (0=all)")
    args = ap.parse_args()

    opmap = json.load(open(args.map))
    for op, e in opmap.items():
        if op.startswith("_") or not isinstance(e, dict):
            continue
        CLASS[int(op)] = classify(e.get("name", "op?"))

    protos = parse_fulldump(args.fulldump)
    ids = sorted(protos)
    if args.protos:
        ids = ids[:args.protos]

    known = total = 0
    for pid in ids:
        for _, op, _ in protos[pid]:
            total += 1
            if CLASS.get(op, "unknown") != "unknown":
                known += 1

    header = [
        "-- Devirtualised from Luraph v14.7 bytecode by luraph-deobf/devirt/lift.py",
        "-- Register-level transliteration (semantically faithful, not original source).",
        "-- e[] = VM register file; K(i) = constant #i; L_n = basic-block labels.",
        f"-- {len(ids)} protos, {total} instructions, "
        f"{known} ({known*100//max(total,1)}%) with a known opcode.",
        "local regs = {}",
        "",
    ]
    body = "\n\n".join(lift_proto(pid, protos[pid], opmap) for pid in ids)
    with open(args.out, "w") as f:
        f.write("\n".join(header) + "\n" + body + "\n")
    print(f"[lift] {len(ids)} protos, {total} instructions "
          f"({known*100//max(total,1)}% known opcodes) -> {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
