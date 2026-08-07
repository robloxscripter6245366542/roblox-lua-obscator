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
#  Constant resolution (readability): a K(i) placeholder is replaced by a real
#  literal in priority order — runtime value observed by capture_values
#  (--values) > a decoded constant learned per (opcode, operand) from executed
#  traces (--decoded) > the instruction's own decoded `d` operand > K(i).
#  String keys become dot-access (e[a].Name) when they are non-keyword
#  identifiers, else bracket-index (e[a]["end"]).
#
#  Well-formedness: the output is guaranteed to PARSE as Lua 5.4. Every goto
#  targets an emitted ::label:: (branch/goto terminators to a None/unknown
#  target degrade to a plain return), and a final sanitiser rewrites any
#  stray unresolved goto to a return. Verify with:  luac5.4 -p lifted.lua
#  (define call/K/arith/dataop stubs first, or just parse-check).
#
#  HONEST SCOPE. This is a register-machine transliteration, not a
#  recovery of the author's original source (variable names, exact
#  expressions, and high-level if/while are not reconstructed here). It is
#  correct at the instruction level for every opcode the map knows, and it
#  marks the residue explicitly (K(i) = a constant in cold/unexecuted code).
#  That is what a devirtualiser produces before the optional
#  structuring/data-flow passes.
#
#  Usage:
#    python3 run_vm.py --vmdir peeled --luau ./luau --mode fulldump --out full.txt
#    python3 lift.py full.txt --map opcodes.full.json \
#            --values values.txt --decoded sem_big.txt,disasm.txt -o lifted.lua
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
DECODED = {}    # (op, b-operand) -> decoded constant literal (from executed traces)
CURPROTO = None  # proto currently being emitted (for VALUES lookup)

_IDENT_RE = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*$')
_LUA_KEYWORDS = frozenset((
    "and", "break", "do", "else", "elseif", "end", "false", "for", "function",
    "goto", "if", "in", "local", "nil", "not", "or", "repeat", "return",
    "then", "true", "until", "while",
))


def _quote(v):
    """Render a captured value as a Lua literal. Ints/floats/bools pass through;
    everything else is treated as a string constant and quoted."""
    if isinstance(v, str):
        s = v.strip()
        # already a Lua literal produced upstream (quoted string, number, bool)?
        if (s.startswith('"') or s.startswith("'")
                or s in ("true", "false", "nil")):
            return s
        try:
            int(s); return s
        except ValueError:
            pass
        try:
            float(s); return s
        except ValueError:
            pass
        return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'
    return str(v)


def _key_access(base, konst):
    """t[k] with dot-sugar when k is a plain string identifier literal."""
    if isinstance(konst, str) and len(konst) >= 2 and konst[0] == '"' and konst[-1] == '"':
        inner = konst[1:-1]
        if _IDENT_RE.match(inner) and inner not in _LUA_KEYWORDS:
            return f"{base}.{inner}"
    return f"{base}[{konst}]"


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

    # Resolve a constant: runtime-observed value > decoded-from-trace (by op+b) >
    # the instruction's own decoded d operand > opaque K(b) placeholder.
    if val is not None:
        konst = _quote(val)
    elif (op, b) in DECODED:
        konst = DECODED[(op, b)]
    elif isinstance(d, str):          # d already holds a decoded constant
        konst = _quote(d)
    else:
        konst = f"K({b})"

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
        return f"{reg(dst_reg(dst, a, b, c))} = {_key_access(reg(a), konst)}{cm}{vc}"
    if cls == "call":
        vc = f"  -- returns {val}" if val is not None else ""
        if dst:
            return f"{reg(dst_reg(dst, a, b, c))} = call({reg(a)}, {reg(c)}){cm}{vc}"
        return f"call({reg(a)}, {reg(c)}){cm} -- void call"
    if cls == "settable":
        return f"{_key_access(reg(a), konst)} = {reg(c)}{cm} -- settable/void-call (inferred)"
    if cls == "dataop":
        vc = f"  -- = {val}" if val is not None else ""
        return f"dataop({reg(a)}, {reg(b)}, {reg(c)}){cm}{vc}"
    return f"-- UNKNOWN {name} [{raw}]"


def dst_reg(dst, a, b, c):
    return {"a": a, "b": b, "c": c}.get(dst, a)


def lift_proto(pid, instrs, opmap):
    global CURPROTO; CURPROTO = pid
    """Flat mode: emit in pc order with labels + gotos (faithful, un-structured)."""
    n = len(instrs)
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
    global CURPROTO; CURPROTO = pid
    n = len(instrs)
    blocks, entry = build_blocks(instrs, n)
    order = linearise(blocks, entry)
    pos = {b: i for i, b in enumerate(order)}
    ctrl = {"jump", "branch"}
    referenced = set()
    lines = []
    for i, start in enumerate(order):
        blk = blocks[start]
        nextblk = order[i + 1] if i + 1 < len(order) else None
        blines = []
        # non-terminator instructions
        for (pc, op, ops) in blk["instrs"][:-1]:
            blines.append("  " + emit(pc, op, ops, opmap.get(str(op)), n))
        # terminator
        lpc, lop, lops = blk["instrs"][-1]
        # a jump/branch target is only usable if it is a real emitted block start
        tgt = blk.get("target") if blk.get("target") in pos else None
        fall = blk.get("fall") if blk.get("fall") in pos else None
        if blk["kind"] == "goto":
            if tgt is None:
                blines.append("  do return end  -- goto target unresolved -> return")
            elif tgt != nextblk:
                blines.append(f"  goto L_{tgt}"); referenced.add(tgt)
            # else fall-through: drop the jump
        elif blk["kind"] == "branch":
            a = opval(lops, "a")
            cond = f"e[{a}]" if a is not None else "cond"
            back = tgt in pos and pos[tgt] <= i if tgt is not None else False
            note = "  -- back-edge (loop)" if back else ""
            if tgt is None:
                # conditional whose taken-target is unknown: fall through only
                blines.append(f"  -- branch (taken target unresolved) [{ ' '.join(f'{k}={lops[k]}' for k in 'abcd' if k in lops) }]")
                if fall is not None and fall != nextblk:
                    blines.append(f"  goto L_{fall}"); referenced.add(fall)
            elif fall is None:
                # no fall path (last block): take-or-end
                blines.append(f"  if {cond} then goto L_{tgt} end{note}")
                referenced.add(tgt)
            elif fall == nextblk:
                blines.append(f"  if {cond} then goto L_{tgt} end{note}")
                referenced.add(tgt)
            else:
                blines.append(f"  if {cond} then goto L_{tgt} else goto L_{fall} end{note}")
                referenced.add(tgt); referenced.add(fall)
        elif blk["kind"] == "return":
            blines.append("  " + emit(lpc, lop, lops, opmap.get(str(lop)), n))
        else:  # fall
            blines.append("  " + emit(lpc, lop, lops, opmap.get(str(lop)), n))
            if fall is not None and fall != nextblk:
                blines.append(f"  goto L_{fall}"); referenced.add(fall)
        lines.append((start, blines))

    out = [f"local function proto{pid}(...)  -- {n} instrs, {len(order)} blocks (structured)"]
    out.append("  local e = regs")
    for start, blines in lines:
        if start in referenced:
            out.append(f"  ::L_{start}::")
        out.extend(blines)
    out.append("end")
    return "\n".join(out)


def load_decoded(paths):
    """Build (op, b-operand) -> decoded-constant map from executed traces
    (semantics.py [[S]] / run_vm disasm [[DIS]]). A pair is kept only if every
    observation of it agrees (unambiguous); conflicting pairs are dropped so we
    never inline a wrong constant."""
    line_re = re.compile(r'\bop=(\d+)\b.*?\bb=(\S+).*?\bd=(\S+)')
    conflict = set()
    for path in paths:
        for line in open(path, errors="replace"):
            if "op=" not in line or "d=" not in line:
                continue
            m = line_re.search(line)
            if not m:
                continue
            op, b, d = m.group(1), m.group(2), m.group(3)
            if d == "nil":
                continue
            try:
                int(d)      # numeric d is a raw operand, not a decoded constant
                continue
            except ValueError:
                pass
            try:
                key = (int(op), int(b))
            except ValueError:
                continue
            lit = _quote(d)
            if key in conflict:
                continue
            if key in DECODED and DECODED[key] != lit:
                del DECODED[key]; conflict.add(key); continue
            DECODED[key] = lit
    return len(DECODED)


def sanitize(text):
    """Safety net: rewrite any `goto L_x` whose `::L_x::` was not emitted into a
    return, so the output is always well-formed Lua that parses. Reports count."""
    labels = set(re.findall(r'::L_(\w+)::', text))
    fixed = [0]

    def _repl(m):
        tgt = m.group(1)
        if tgt in labels:
            return m.group(0)
        fixed[0] += 1
        return f"do return end  --[[ unresolved goto L_{tgt} ]]"

    text = re.sub(r'goto L_(\w+)', _repl, text)
    return text, fixed[0]


def main():
    ap = argparse.ArgumentParser(description="lift Luraph bytecode to register-level Lua")
    ap.add_argument("fulldump", help="output of run_vm.py --mode fulldump")
    ap.add_argument("--map", default="opcodes.full.json")
    ap.add_argument("-o", "--out", default="lifted.lua")
    ap.add_argument("--protos", type=int, default=0, help="limit to first N protos (0=all)")
    ap.add_argument("--flat", action="store_true",
                    help="emit in raw pc order (skip control-flow structuring)")
    ap.add_argument("--values", default=None,
                    help="capture_values.py output: inline observed constants")
    ap.add_argument("--decoded", default=None,
                    help="comma-separated executed traces (semantics.py / disasm) to "
                         "resolve K(i) placeholders to real constants by (op,operand)")
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

    if args.decoded:
        load_decoded([p for p in args.decoded.split(",") if p])

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

    gen = lift_proto if args.flat else structure_proto
    body = "\n\n".join(gen(pid, protos[pid], opmap) for pid in ids)
    body, fixed = sanitize(body)

    kremain = len(re.findall(r'K\(\d+\)', body))
    mode = "flat (pc order)" if args.flat else "structured (trace-linearised CFG)"
    header = [
        "-- Devirtualised from Luraph v14.7 bytecode by luraph-deobf/devirt/lift.py",
        "-- Register-level transliteration (semantically faithful, not original source).",
        "-- e[] = VM register file; K(i) = an unresolved constant #i; L_n = block labels.",
        f"-- mode: {mode}.",
        f"-- {len(ids)} protos, {total} instructions, "
        f"{known} ({known*100//max(total,1)}%) with a known opcode.",
        (f"-- {len(VALUES)} runtime values + {len(DECODED)} decoded constants inlined; "
         f"{kremain} K(i) placeholders remain (cold/unexecuted code)."),
        f"-- {fixed} unresolved goto(s) rewritten to return for well-formedness."
        if fixed else "-- control flow: all gotos resolve to emitted labels.",
        "local regs = {}",
        "",
    ]
    with open(args.out, "w") as f:
        f.write("\n".join(header) + "\n" + body + "\n")
    print(f"[lift] {len(ids)} protos, {total} instructions "
          f"({known*100//max(total,1)}% known opcodes); "
          f"{len(DECODED)} decoded consts, {kremain} K(i) left, {fixed} gotos fixed -> {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
