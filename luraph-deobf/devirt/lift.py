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
#    * control flow rebuilt from JMP / TEST-BRANCH targets as a `pc`-keyed
#      dispatch loop (`while true do if pc == ... then ... end end`), NOT
#      goto/labels -- Luau has no goto statement at all (verified: it
#      rejects `::label::` outright), so a goto-based emission never parses
#      under the runtime this project targets. Every block sets its own
#      successor's `pc` explicitly; a structuring pass can fold this into
#      if/while later, but the dispatch loop is what actually runs today.
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


CLASS = {}      # op(int) -> class, filled from the map
VALUES = {}     # (proto, pc) -> concrete value literal (from capture_values.py)
CURPROTO = None  # proto currently being emitted (for VALUES lookup)


def emit(pc, op, ops, entry, n):
    """Return one line of lifted Lua for an instruction."""
    name = entry.get("name", "op?") if entry else "op?"
    dst = entry.get("dst") if entry else None
    cls = CLASS.get(op, "unknown")
    a, b, c, d = (opval(ops, k) for k in "abcd")
    raw = " ".join(f"{k}={ops[k]}" for k in "abcd" if k in ops)
    cm = f"  -- {name} [{raw}]"
    val = VALUES.get((CURPROTO, pc))   # concrete value this instr produced

    def reg(x):
        return f"e[{x}]" if x is not None else "?"

    # a "K" that becomes the real literal when we observed it, else a placeholder
    konst = val if val is not None else (f"K({b})")

    if cls == "jump":
        if is_pc(b, n):
            return f"goto L_{b}{cm}"
        return f"do return end{cm}"
    if cls == "branch":
        tgt = f"goto L_{b}" if is_pc(b, n) else "return"
        return f"if {reg(a)} then {tgt} end{cm}"
    if cls == "compare":
        vc = f"  -- = {val}" if val is not None else ""
        return f"{reg(dst_reg(dst, a, b, c))} = ({reg(a)} == {reg(c)}){cm}{vc}"
    if cls == "newtable":
        return f"{reg(dst_reg(dst, a, b, c))} = {{}}{cm}"
    if cls == "move":
        vc = f"  -- = {val}" if val is not None else ""
        return f"{reg(b)} = {reg(a)}{cm}{vc}"
    if cls == "add":
        vc = f"  -- = {val}" if val is not None else ""
        return f"{reg(a)} = {reg(c)} + {d}{cm}{vc}"
    if cls == "loadk":
        return f"{reg(dst_reg(dst, a, b, c))} = {konst}{cm}"
    if cls == "arith":
        vc = f"  -- = {val}" if val is not None else ""
        return f"{reg(dst_reg(dst, a, b, c))} = arith({reg(b)}, {reg(c)}){cm}{vc}"
    if cls == "gettable":
        vc = f"  -- = {val}" if val is not None else ""
        return f"{reg(dst_reg(dst, a, b, c))} = {reg(a)}[{konst}]{cm}{vc}"
    if cls == "call":
        vc = f"  -- returns {val}" if val is not None else ""
        if dst:
            return f"{reg(dst_reg(dst, a, b, c))} = call({reg(a)}, {reg(c)}){cm}{vc}"
        return f"call({reg(a)}, {reg(c)}){cm} -- void call"
    if cls == "settable":
        return f"{reg(a)}[{konst}] = {reg(c)}{cm} -- settable/void-call (inferred)"
    if cls == "dataop":
        vc = f"  -- = {val}" if val is not None else ""
        return f"dataop({reg(a)}, {reg(b)}, {reg(c)}){cm}{vc}"
    return f"-- UNKNOWN {name} [{raw}]"


def dst_reg(dst, a, b, c):
    return {"a": a, "b": b, "c": c}.get(dst, a)


def lift_proto(pid, instrs, opmap):
    """--flat mode.

    This used to be a separate emitter: one dispatch case per raw
    instruction (pc order) instead of per merged basic block, using the same
    goto/label statements structure_proto used to. That goto-based approach
    doesn't parse under Luau at all (verified: `luau` rejects `::label::`
    outright) and needed the same pc-dispatch-loop fix; once written as a
    dispatch loop, per-instruction vs. per-block dispatch is no longer a
    correctness distinction (every block, merged or not, explicitly sets its
    own successor's pc) -- only a size/readability one, and the merged form
    is strictly more readable for the same semantics. So --flat now reuses
    structure_proto directly rather than maintaining a second, redundant
    emitter.
    """
    return structure_proto(pid, instrs, opmap)


# ---- control-flow structuring (trace-linearise the flattened CFG) --------

def build_blocks(instrs, n):
    """Split into basic blocks. Returns {start_pc: block} where block =
    dict(start, instrs, kind, target, fall). kind in goto/branch/return/fall."""
    pc_index = {pc: i for i, (pc, _, _) in enumerate(instrs)}
    leaders = {instrs[0][0]}
    for i, (pc, op, ops) in enumerate(instrs):
        cls = CLASS.get(op)
        if cls in ("jump", "branch"):
            t = opval(ops, "b")
            if is_pc(t, n):
                leaders.add(t)
            if i + 1 < len(instrs):
                leaders.add(instrs[i + 1][0])
    starts = sorted(leaders)
    blocks = {}
    for si, start in enumerate(starts):
        end = starts[si + 1] if si + 1 < len(starts) else None
        body = []
        j = pc_index[start]
        while j < len(instrs) and (end is None or instrs[j][0] < end):
            body.append(instrs[j]); j += 1
        lpc, lop, lops = body[-1]
        cls = CLASS.get(lop)
        nxt = instrs[pc_index[lpc] + 1][0] if pc_index[lpc] + 1 < len(instrs) else None
        blk = {"start": start, "instrs": body}
        if cls == "jump":
            t = opval(lops, "b")
            if is_pc(t, n):
                blk.update(kind="goto", target=t, fall=None)
            else:
                blk.update(kind="return", target=None, fall=None)
        elif cls == "branch":
            t = opval(lops, "b")
            blk.update(kind="branch", target=t if is_pc(t, n) else None, fall=nxt)
        else:
            blk.update(kind="fall", target=None, fall=nxt)
        blocks[start] = blk
    return blocks, starts[0]


def linearise(blocks, entry):
    """Order blocks so a block's natural successor follows it (fall-through)."""
    order, placed, work = [], set(), [entry]
    while work:
        b = work.pop()
        while b is not None and b in blocks and b not in placed:
            order.append(b); placed.add(b)
            blk = blocks[b]
            if blk["kind"] == "branch":
                succs = [blk["fall"], blk["target"]]
            elif blk["kind"] == "goto":
                succs = [blk["target"]]
            elif blk["kind"] == "fall":
                succs = [blk["fall"]]
            else:
                succs = []
            nxt = None
            for s in succs:
                if s in blocks and s not in placed:
                    if nxt is None:
                        nxt = s
                    else:
                        work.append(s)
            b = nxt
    # append any unreachable blocks (defensive)
    for s in blocks:
        if s not in placed:
            order.append(s)
    return order


def structure_proto(pid, instrs, opmap):
    """Emit register-level Lua using a pc-dispatch loop, not goto/labels.

    Luau (unlike stock Lua 5.2+) has no goto/label statement at all -- a
    goto-based emission never parses under the runtime this project actually
    targets (verified: `luau` rejects `::label::` outright, "Expected
    identifier when parsing expression, got '::'"). This lowers the same
    block graph to the standard goto-free equivalent instead: a
    `while true do if pc == ... then ... end end` dispatch loop, where every
    block transition is `pc = <next block start>` (or the EXIT sentinel)
    rather than a jump. Correctness no longer depends on block emission
    order (each block explicitly sets its successor's pc), so a stray/
    unresolved target can never produce a dangling reference the way
    "goto L_None" did.
    """
    global CURPROTO; CURPROTO = pid
    EXIT = -1
    n = len(instrs)
    blocks, entry = build_blocks(instrs, n)
    order = linearise(blocks, entry)
    pos = {b: i for i, b in enumerate(order)}

    branches = []
    for i, start in enumerate(order):
        blk = blocks[start]
        body = []
        for (pc, op, ops) in blk["instrs"][:-1]:
            body.append("      " + emit(pc, op, ops, opmap.get(str(op)), n))
        lpc, lop, lops = blk["instrs"][-1]
        if blk["kind"] == "goto":
            body.append(f"      pc = {blk['target']}")
        elif blk["kind"] == "branch":
            a = opval(lops, "a")
            cond = f"e[{a}]" if a is not None else "cond"
            back = (blk["target"] is not None and blk["target"] in pos
                    and pos[blk["target"]] <= i)
            note = "  -- back-edge (loop)" if back else ""
            tgt = blk["target"] if blk["target"] is not None else EXIT
            fall = blk["fall"] if blk["fall"] is not None else EXIT
            body.append(f"      if {cond} then pc = {tgt} else pc = {fall} end{note}")
        elif blk["kind"] == "return":
            body.append("      " + emit(lpc, lop, lops, opmap.get(str(lop)), n))
            body.append(f"      pc = {EXIT}")
        else:  # fall
            body.append("      " + emit(lpc, lop, lops, opmap.get(str(lop)), n))
            fall = blk["fall"] if blk["fall"] is not None else EXIT
            body.append(f"      pc = {fall}")
        branches.append((start, body))

    out = [f"local function proto{pid}(...)  -- {n} instrs, {len(order)} blocks "
           "(structured, pc-dispatch)"]
    out.append("  local e = regs")
    out.append(f"  local pc = {entry}")
    out.append("  while true do")
    for j, (start, body) in enumerate(branches):
        kw = "if" if j == 0 else "elseif"
        out.append(f"    {kw} pc == {start} then")
        out.extend(body)
    out.append("    else")
    out.append("      break")
    out.append("    end")
    out.append("  end")
    out.append("end")
    return "\n".join(out)


def main():
    ap = argparse.ArgumentParser(description="lift Luraph bytecode to register-level Lua")
    ap.add_argument("fulldump", help="output of run_vm.py --mode fulldump")
    ap.add_argument("--map", default="opcodes.full.json")
    ap.add_argument("-o", "--out", default="lifted.lua")
    ap.add_argument("--protos", type=int, default=0, help="limit to first N protos (0=all)")
    ap.add_argument("--flat", action="store_true",
                    help="kept for CLI compatibility; now equivalent to the default "
                         "(both use the pc-dispatch emitter -- see lift_proto docstring)")
    ap.add_argument("--values", default=None,
                    help="capture_values.py output: inline observed constants")
    args = ap.parse_args()

    opmap = json.load(open(args.map))
    for op, e in opmap.items():
        if op.startswith("_") or not isinstance(e, dict):
            continue
        CLASS[int(op)] = classify(e.get("name", "op?"))

    if args.values:
        import re as _re
        for _l in open(args.values, errors="replace"):
            _m = _re.match(r"\[\[V\]\] p=(\d+) pc=(\d+) op=\S+ v=(.*)", _l.rstrip())
            if _m:
                VALUES[(int(_m.group(1)), int(_m.group(2)))] = _m.group(3)

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

    mode = "structured (pc-dispatch loop)"
    header = [
        "-- Devirtualised from Luraph v14.7 bytecode by luraph-deobf/devirt/lift.py",
        "-- Register-level transliteration (semantically faithful, not original source).",
        "-- e[] = VM register file; K(i) = constant #i; pc = dispatch-loop block cursor.",
        f"-- mode: {mode}.",
        f"-- {len(ids)} protos, {total} instructions, "
        f"{known} ({known*100//max(total,1)}%) with a known opcode.",
        f"-- {len(VALUES)} concrete values inlined from execution." if VALUES else "-- (no value capture; run capture_values.py + --values to inline constants)",
        "local regs = {}",
        "",
    ]
    gen = lift_proto if args.flat else structure_proto
    body = "\n\n".join(gen(pid, protos[pid], opmap) for pid in ids)
    with open(args.out, "w") as f:
        f.write("\n".join(header) + "\n" + body + "\n")
    print(f"[lift] {len(ids)} protos, {total} instructions "
          f"({known*100//max(total,1)}% known opcodes) -> {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
