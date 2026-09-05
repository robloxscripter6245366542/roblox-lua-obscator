#!/usr/bin/env python3
# ============================================================
#  v15_payload_lift.py  --  codegen for v15's payload VM (the missing piece
#  v15_payload_opcodes.py's own header names: "we know what category each
#  opcode is, not the exact Lua statement to emit for it")
#
#  v15_payload_opcodes.py resolves each opcode branch's exact AST but only
#  CLASSIFIES it (category/calls/arrays). v15_payload_dump_arrays.py gets
#  the VM's fully-decoded instruction data (the real, concrete o/r/k/E/...
#  array contents once the loader has populated them). This combines both:
#  for every pc in the target mode's instruction range, look up its real
#  opcode value from the dumped data, find that opcode's exact AST template
#  (from v15_payload_opcodes.py's dispatch walk), and re-print it as Lua
#  text with every `<array>[<pc-var>]` operand read substituted for the
#  actual dumped value at that pc -- e.g. the *template* "R[r[w]]=R[k[w]]<
#  E[w]" becomes the *concrete* instruction "R[7]=R[12]<58" once we know
#  r[41]=7, k[41]=12, E[41]=58 for instruction #41. That is genuine
#  per-instruction codegen, the same job v14.7's lift.py does from its
#  decoded bytecode -- just against a VM whose interpreter is already
#  plain Lua source instead of opaque numeric handler IDs, so the "handler
#  body" is read via luau-ast instead of a curated opcode map.
#
#  Every register READ is also annotated with which pc last WROTE it
#  (backward data-flow within the lifted range), which is what actually
#  answers "why doesn't this loop's RETURN ever fire": for the guard on any
#  spin/poll instruction, `--[[ last write: pc=N (opN, args) ]]` names the
#  exact instruction and opcode responsible, so tracing "which environment
#  stub feeds this loop's exit condition" is a lookup instead of a guess.
#
#  Usage:
#    python3 devirt/v15_payload_lift.py sample_v15.lua \
#        --luau-ast ../dynamic/luau-ast --arrays v15_payload_arrays.json \
#        --hist v15_payload_opcodes.json --mode 2 \
#        --out v15_payload_lifted.lua
# ============================================================

import argparse
import json
import re
import sys

from v15_payload_probe import find_vm_groups, pick_payload_vm
from v15_payload_opcodes import (
    offset_to_line_col, run_luau_ast, find_enclosing_while, cond_terms,
    resolve_opcode, unwrap, is_opcode_compare, _CMP_OPS,
)

ARRAY_NAMES = {"o", "r", "k", "E", "V", "n"}


def collect_leaves_raw(node, pc_var, m_var, path, out, prefix=()):
    """Same recursion as v15_payload_opcodes.walk_dispatch, but keeps the
    raw AST body (prefix statements + leaf) instead of classifying it."""
    extra, inner = unwrap(node, m_var)
    prefix = tuple(prefix) + tuple(extra)
    is_dispatch_if = inner.get("type") == "AstStatIf" and is_opcode_compare(inner.get("condition", {}), m_var)
    if not is_dispatch_if:
        opcode = resolve_opcode(path)
        out.append({"opcode": opcode, "body": list(prefix) + [inner]})
        return
    node = inner
    terms = list(cond_terms(node.get("condition", {})))
    collect_leaves_raw(node.get("thenbody"), pc_var, m_var, path + terms, out, prefix)
    if node.get("elsebody"):
        neg = {"<": ">=", ">=": "<", ">": "<=", "<=": ">", "==": "~=", "~=": "=="}
        else_terms = [(neg[op], val) for op, val in terms]
        collect_leaves_raw(node["elsebody"], pc_var, m_var, path + else_terms, out, prefix)


class Lifter:
    def __init__(self, arrays, pc_var):
        self.arrays = arrays  # name -> [values], 0-indexed list for 1-indexed Lua pc
        self.pc_var = pc_var
        self.writes = {}  # register number -> [(pc, opcode, text)]

    def const_at(self, arr_name, pc):
        vals = self.arrays.get(arr_name)
        if vals is None or pc < 1 or pc > len(vals):
            return None
        return vals[pc - 1]

    def lit(self, v):
        if v is None:
            return "nil"
        if isinstance(v, str) and v.startswith("S"):
            return f'"<str len={v[1:]}>"'
        if isinstance(v, (int, float)):
            return repr(v)
        return f'"{v}"'

    def _resolve_pc_offset(self, node, pc):
        """If `node` is exactly the pc variable, or `pc_var +/- constant`,
        return the concrete pc it denotes -- lets `arr[w]` AND `arr[w+1]`
        style operand reads both resolve to literal dumped values instead
        of only the exact `arr[w]` case."""
        if node.get("type") == "AstExprLocal" and node.get("local", {}).get("name") == self.pc_var:
            return pc
        if node.get("type") == "AstExprBinary" and node.get("op") in ("Add", "Sub"):
            left, right = node.get("left", {}), node.get("right", {})
            if (left.get("type") == "AstExprLocal" and left.get("local", {}).get("name") == self.pc_var
                    and right.get("type") == "AstExprConstantNumber"):
                delta = right["value"] if node["op"] == "Add" else -right["value"]
                return pc + delta
        return None

    def emit_expr(self, node, pc):
        if not isinstance(node, dict):
            return "?"
        t = node.get("type")
        if t == "AstExprIndexExpr":
            base = node.get("expr", {})
            index = node.get("index", {})
            if (base.get("type") == "AstExprLocal"
                    and base.get("local", {}).get("name") in ARRAY_NAMES):
                arr_name = base["local"]["name"]
                idx_pc = self._resolve_pc_offset(index, pc)
                if idx_pc is not None:
                    return self.lit(self.const_at(arr_name, idx_pc))
            return f"{self.emit_expr(base, pc)}[{self.emit_expr(index, pc)}]"
        if t == "AstExprLocal":
            return node.get("local", {}).get("name", "?")
        if t == "AstExprGlobal":
            return node.get("global", "?")
        if t == "AstExprIndexName":
            return f"{self.emit_expr(node.get('expr', {}), pc)}.{node.get('index', '?')}"
        if t == "AstExprConstantNumber":
            return repr(node.get("value"))
        if t == "AstExprConstantString":
            return json.dumps(node.get("value", ""))
        if t == "AstExprConstantBool":
            return "true" if node.get("value") else "false"
        if t == "AstExprConstantNil":
            return "nil"
        if t == "AstExprVarargs":
            return "..."
        if t == "AstExprGroup":
            return f"({self.emit_expr(node.get('expr', {}), pc)})"
        if t == "AstExprUnary":
            op = {"Not": "not ", "Minus": "-", "Len": "#"}.get(node.get("op"), "?")
            return f"{op}{self.emit_expr(node.get('expr', {}), pc)}"
        if t == "AstExprBinary":
            opmap = {"CompareLt": "<", "CompareLe": "<=", "CompareGt": ">", "CompareGe": ">=",
                     "CompareEq": "==", "CompareNe": "~=", "Add": "+", "Sub": "-", "Mul": "*",
                     "Div": "/", "Mod": "%", "Pow": "^", "Concat": "..", "And": "and", "Or": "or",
                     "FloorDiv": "//"}
            op = opmap.get(node.get("op"), "?")
            return f"({self.emit_expr(node.get('left', {}), pc)} {op} {self.emit_expr(node.get('right', {}), pc)})"
        if t == "AstExprCall":
            fn = self.emit_expr(node.get("func", {}), pc)
            args = ", ".join(self.emit_expr(a, pc) for a in node.get("args", []))
            return f"{fn}({args})"
        if t == "AstExprTable":
            return "{...}"
        if t == "AstExprIfElse":
            return (f"(if {self.emit_expr(node.get('condition', {}), pc)} then "
                    f"{self.emit_expr(node.get('trueExpr', {}), pc)} else "
                    f"{self.emit_expr(node.get('falseExpr', {}), pc)})")
        if t == "AstExprFunction":
            return "function(...) ... end"
        return f"--[[{t}]]"

    def emit_stat(self, node, pc, indent=""):
        if not isinstance(node, dict):
            return indent + "--[[?]]"
        t = node.get("type")
        if t == "AstStatBlock":
            return "\n".join(self.emit_stat(s, pc, indent) for s in node.get("body", []))
        if t in ("AstStatAssign", "AstStatCompoundAssign"):
            if t == "AstStatCompoundAssign":
                opmap = {"Add": "+=", "Sub": "-=", "Mul": "*=", "Div": "/=", "Mod": "%=", "Pow": "^="}
                var = node.get("var", {})
                op = opmap.get(node.get("op"), "+=")
                line = f"{self.emit_expr(var, pc)} {op} {self.emit_expr(node.get('value', {}), pc)}"
            else:
                vars_ = node.get("vars") or [node.get("var")]
                vals = node.get("values", [])
                line = (", ".join(self.emit_expr(v, pc) for v in vars_) + " = "
                        + ", ".join(self.emit_expr(v, pc) for v in vals))
            self._record_write(node, pc)
            return indent + line
        if t == "AstStatLocal":
            names = [v.get("name", "?") for v in node.get("vars", [])]
            vals = node.get("values", [])
            line = "local " + ", ".join(names)
            if vals:
                line += " = " + ", ".join(self.emit_expr(v, pc) for v in vals)
            return indent + line
        if t == "AstStatExpr":
            return indent + self.emit_expr(node.get("expr", {}), pc)
        if t == "AstStatReturn":
            vals = ", ".join(self.emit_expr(v, pc) for v in node.get("list", []))
            return indent + f"return {vals}"
        if t == "AstStatBreak":
            return indent + "break"
        if t == "AstStatIf":
            c = self.emit_expr(node.get("condition", {}), pc)
            out = [indent + f"if {c} then", self.emit_stat(node.get("thenbody"), pc, indent + "  ")]
            if node.get("elsebody"):
                out.append(indent + "else")
                out.append(self.emit_stat(node["elsebody"], pc, indent + "  "))
            out.append(indent + "end")
            return "\n".join(out)
        if t == "AstStatFor":
            var = node.get("var", {}).get("name", "i")
            frm = self.emit_expr(node.get("from", {}), pc)
            to = self.emit_expr(node.get("to", {}), pc)
            body = self.emit_stat(node.get("body"), pc, indent + "  ")
            return indent + f"for {var}={frm},{to} do\n{body}\n{indent}end"
        if t == "AstStatWhile":
            c = self.emit_expr(node.get("condition", {}), pc)
            body = self.emit_stat(node.get("body"), pc, indent + "  ")
            return indent + f"while {c} do\n{body}\n{indent}end"
        return indent + f"--[[unhandled: {t}]]"

    def _record_write(self, node, pc):
        vars_ = node.get("vars") or [node.get("var")]
        for v in vars_:
            if v and v.get("type") == "AstExprIndexExpr":
                base = v.get("expr", {})
                if base.get("type") == "AstExprLocal" and base.get("local", {}).get("name") == "R":
                    idx = v.get("index", {})
                    if (idx.get("type") == "AstExprIndexExpr"
                            and idx.get("expr", {}).get("type") == "AstExprLocal"
                            and idx["expr"]["local"]["name"] in ARRAY_NAMES):
                        idx_pc = self._resolve_pc_offset(idx.get("index", {}), pc)
                        if idx_pc is not None:
                            regnum = self.const_at(idx["expr"]["local"]["name"], idx_pc)
                            if isinstance(regnum, int):
                                self.writes.setdefault(regnum, []).append(pc)


def main():
    ap = argparse.ArgumentParser(description="v15 payload-VM codegen (concrete per-instruction Lua)")
    ap.add_argument("sample")
    ap.add_argument("--luau-ast", default="../dynamic/luau-ast")
    ap.add_argument("--arrays", required=True, help="v15_payload_dump_arrays.py --json output")
    ap.add_argument("--hist", help="v15_payload_probe.py --json output, for dynamic overlay")
    ap.add_argument("--mode", type=int, required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--limit", type=int, default=0,
                    help="lift only the first N pcs (static mode) or N steps (--trace mode); 0=all")
    ap.add_argument("--trace",
                    help="v15_payload_probe.py's raw output (or a grep'd subset): lift the ACTUAL "
                         "execution order (mode=X M=Y pc=Z lines) instead of blindly walking pc "
                         "1..N of the static array -- necessary because not every array slot is "
                         "meaningfully 'an opcode for this mode' (parallel arrays are a shared data "
                         "pool across modes/operand roles, so only visited pcs are safely lifted)")
    args = ap.parse_args()

    src = open(args.sample, encoding="utf-8", errors="replace").read()
    groups = find_vm_groups(src)
    pc_var = pick_payload_vm(groups)
    blocks = groups[pc_var]
    start, end, M, ARR, richness = blocks[args.mode]
    fetch_text = f"local {M}={ARR}[{pc_var}];"
    fetch_start = end - len(fetch_text)
    line, col = offset_to_line_col(src, fetch_start)
    fetch_loc = f"{line},{col} - {line},{col + len(fetch_text)}"

    root = run_luau_ast(args.luau_ast, args.sample)["root"]
    wnode = find_enclosing_while(root, fetch_loc)
    if wnode is None:
        sys.exit("!! could not locate dispatch loop")
    dispatch_root = wnode["body"]["body"][1]
    leaves = []
    collect_leaves_raw(dispatch_root, pc_var, M, [], leaves)
    print(f"[v15-payload-lift] mode {args.mode} ({M}={ARR}[{pc_var}]): "
          f"{len(leaves)} opcode branches available")

    def expand_opcode_key(key):
        """resolve_opcode() returns an exact value ("27"), a contiguous
        range ("29..30"), a disjoint list ("3,4"), or, on failure, a
        "?..."-prefixed dump of raw constraints -- expand the first three
        into individual ints; the fallback form isn't safely expandable."""
        if key.startswith("?"):
            return []
        if ".." in key:
            lo, hi = key.split("..")
            return list(range(int(lo), int(hi) + 1))
        return [int(x) for x in key.split(",")]

    by_opcode = {}
    unresolved_leaves = 0
    for leaf in leaves:
        vals = expand_opcode_key(leaf["opcode"])
        if not vals:
            unresolved_leaves += 1
            continue
        for v in vals:
            by_opcode.setdefault(v, leaf["body"])
    if unresolved_leaves:
        print(f"  !! {unresolved_leaves} leaf branch(es) had an unresolvable opcode "
              f"guard (won't be matched against any concrete instruction)")

    arrdata = json.load(open(args.arrays))
    if arrdata.get("mode") != args.mode:
        print(f"  !! warning: array dump was for mode {arrdata.get('mode')}, "
              f"lifting mode {args.mode} -- opcode source array may not match", file=sys.stderr)
    arrays = arrdata["arrays"]
    opcode_stream = arrays.get(ARR)
    if opcode_stream is None:
        sys.exit(f"!! array dump has no '{ARR}' array (the opcode source for this mode)")

    hist_counts = {}
    if args.hist:
        h = json.load(open(args.hist))
        info = h.get("modes", {}).get(str(args.mode), {})
        hist_counts = dict(info.get("top_opcodes", []))

    lifter = Lifter(arrays, pc_var)
    lines = []
    unresolved = 0

    if args.trace:
        # Execution-order lift: walk the ACTUAL (pc, opcode) sequence a real
        # run visited (from v15_payload_probe.py's raw output), not a blind
        # static scan -- the parallel arrays are a shared data pool across
        # modes/operand roles, so a slot is only meaningfully "an opcode for
        # this mode" once we've SEEN this mode read it as one.
        steps = []
        pat = re.compile(rf"mode={args.mode} M=(-?\d+) pc=(-?\d+)")
        with open(args.trace, encoding="utf-8", errors="replace") as f:
            for line in f:
                m = pat.search(line)
                if m:
                    steps.append((int(m.group(2)), int(m.group(1))))
                    if args.limit and len(steps) >= args.limit:
                        break
        print(f"  trace mode: {len(steps)} executed steps loaded from {args.trace}")
        for step, (pc, opval) in enumerate(steps):
            body = by_opcode.get(opval)
            cnt = hist_counts.get(str(opval), hist_counts.get(opval, 0))
            tag = f"-- step={step} pc={pc} op={opval} dyn_count={cnt}"
            if body is None:
                unresolved += 1
                lines.append(f"::S_{step}:: {tag}  --[[NO MATCHING BRANCH]]")
                continue
            combined = {"type": "AstStatBlock", "body": body}
            text = lifter.emit_stat(combined, pc, "  ")
            lines.append(f"::S_{step}:: {tag}\n{text}")
        total = len(steps)
    else:
        n = len(opcode_stream) if not args.limit else min(args.limit, len(opcode_stream))
        for pc in range(1, n + 1):
            opval = opcode_stream[pc - 1]
            body = by_opcode.get(opval)
            cnt = hist_counts.get(str(opval), hist_counts.get(opval, 0))
            tag = f"-- pc={pc} op={opval} dyn_count={cnt}"
            if body is None:
                unresolved += 1
                lines.append(f"::L_{pc}:: {tag}  --[[NO MATCHING BRANCH]]")
                continue
            combined = {"type": "AstStatBlock", "body": body}
            text = lifter.emit_stat(combined, pc, "  ")
            lines.append(f"::L_{pc}:: {tag}\n{text}")
        total = n

    with open(args.out, "w") as f:
        f.write(f"-- lifted from {args.sample}, mode {args.mode} ({M}={ARR}[{pc_var}]), "
                f"{'trace-order' if args.trace else 'static'}, "
                f"{total} instructions, {unresolved} unresolved\n")
        f.write("\n".join(lines))
        f.write("\n")
    print(f"  lifted {total} instructions, {unresolved} unresolved (no branch matched opcode value)")
    print(f"  -> {args.out}")

    reg_report_path = args.out + ".regwrites.json"
    json.dump({str(k): v for k, v in lifter.writes.items()}, open(reg_report_path, "w"), indent=1)
    print(f"  -> {reg_report_path} (register number -> [pcs that write it], for data-flow tracing)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
