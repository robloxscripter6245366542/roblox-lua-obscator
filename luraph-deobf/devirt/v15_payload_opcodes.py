#!/usr/bin/env python3
# ============================================================
#  v15_payload_opcodes.py  --  opcode SEMANTICS for v15's payload VM
#
#  v15_payload_probe.py gets real dynamic coverage (which opcodes fire, how
#  often, over what pc range) for the payload-side register VM described in
#  its own header comment. That's frequency, not meaning. This tool adds the
#  meaning: it parses the exact AST of each dispatch loop's `if/elseif`
#  chain (via `luau-ast`, not regex -- these bodies contain arbitrary Lua:
#  nested for-loops, multi-value assigns, recursive calls, so a text/balance
#  parser is the wrong tool here, unlike the outer loader's simple
#  `NAME=function()...end` shape that v15_opcodes.py handles with regex),
#  resolves each leaf's exact opcode value/range from its guard chain, and
#  classifies its body the same way v15_opcodes.py classifies loader
#  handlers (library calls, register read/write pattern, branch/jump/return
#  shape) -- then overlays the dynamic call counts from v15_payload_probe.py
#  so "hot but unclassified" and "classified but never hit" are both visible.
#
#  Requires a `luau-ast` binary (dynamic/build_luau.sh also builds this now).
#
#  Usage:
#    python3 devirt/v15_payload_opcodes.py sample_v15.lua \
#        --luau-ast ../dynamic/luau-ast \
#        --hist v15_payload_opcodes.json \
#        --json v15_payload_opcode_semantics.json \
#        --md v15_payload_opcode_semantics.md
# ============================================================

import argparse
import json
import re
import subprocess
import sys

from v15_payload_probe import find_vm_groups, pick_payload_vm

_CMP_OPS = {"CompareLt": "<", "CompareLe": "<=", "CompareGt": ">",
            "CompareGe": ">=", "CompareEq": "==", "CompareNe": "~="}


def offset_to_line_col(src, offset):
    """Convert a whole-file char offset to the (0-indexed line, col) pair
    luau-ast uses in its `location` strings."""
    line = src.count("\n", 0, offset)
    line_start = src.rfind("\n", 0, offset) + 1
    return line, offset - line_start


def run_luau_ast(luau_ast_bin, sample_path):
    out = subprocess.run([luau_ast_bin, sample_path], capture_output=True, text=True)
    if out.returncode != 0:
        sys.exit(f"!! luau-ast failed: {out.stderr[:500]}")
    return json.loads(out.stdout)


def find_node_at(node, line, col):
    """Find the (innermost first-seen) node whose location starts exactly
    at (line, col)."""
    if isinstance(node, dict):
        loc = node.get("location")
        if loc:
            start = loc.split(" - ")[0]
            l, c = start.split(",")
            if int(l) == line and int(c) == col:
                return node
        for k, v in node.items():
            if k in ("type", "location"):
                continue
            r = find_node_at(v, line, col)
            if r is not None:
                return r
    elif isinstance(node, list):
        for item in node:
            r = find_node_at(item, line, col)
            if r is not None:
                return r
    return None


def find_enclosing_while(root, fetch_loc):
    """The fetch AstStatLocal is body[0] of the AstStatWhile we want; find
    that AstStatWhile anywhere in the tree by matching its first body stmt's
    location."""
    result = [None]

    def walk(node):
        if result[0] is not None or not isinstance(node, (dict, list)):
            return
        if isinstance(node, dict):
            if node.get("type") == "AstStatWhile":
                b = node.get("body", {}).get("body", [])
                if b and b[0].get("location") == fetch_loc:
                    result[0] = node
                    return
            for k, v in node.items():
                if k == "type":
                    continue
                walk(v)
                if result[0] is not None:
                    return
        else:
            for item in node:
                walk(item)
                if result[0] is not None:
                    return
    walk(root)
    return result[0]


def is_opcode_compare(cond, m_var):
    """True if `cond` (through any `not(...)` wrapping) is a comparison of
    the opcode variable itself against a constant -- i.e. genuinely another
    step of the M-dispatch, not some unrelated `if` inside a handler body
    that just happens to sit last in its block."""
    if cond.get("type") == "AstExprUnary" and cond.get("op") == "Not":
        return is_opcode_compare(cond.get("expr", {}), m_var)
    if cond.get("type") != "AstExprBinary" or cond.get("op") not in _CMP_OPS:
        return False
    left = cond.get("left", {})
    return left.get("type") == "AstExprLocal" and left.get("local", {}).get("name") == m_var


def cond_terms(cond):
    """Yield (op, value) comparisons against the opcode var out of a
    (possibly `not(...)`-wrapped) condition, negating ops under `not`."""
    negate = {"<": ">=", ">=": "<", ">": "<=", "<=": ">", "==": "~=", "~=": "=="}
    if cond.get("type") == "AstExprUnary" and cond.get("op") == "Not":
        for op, val in cond_terms(cond.get("expr", {})):
            yield negate[op], val
        return
    if cond.get("type") == "AstExprBinary":
        op = _CMP_OPS.get(cond.get("op"))
        if op is None:
            return
        right = cond.get("right", {})
        if right.get("type") == "AstExprConstantNumber":
            yield op, right.get("value")


def resolve_opcode(path):
    """Turn a list of (op, value) constraints into an exact value, a range
    string, or a fallback join of the raw constraints."""
    lo, hi, ne, eq = float("-inf"), float("inf"), set(), None
    for op, val in path:
        if op == "==":
            eq = val
        elif op == "~=":
            ne.add(val)
        elif op == "<":
            hi = min(hi, val - 1)
        elif op == "<=":
            hi = min(hi, val)
        elif op == ">":
            lo = max(lo, val + 1)
        elif op == ">=":
            lo = max(lo, val)
    if eq is not None:
        return str(eq)
    if lo != float("-inf") and hi != float("inf"):
        remaining = [v for v in range(int(lo), int(hi) + 1) if v not in ne]
        if len(remaining) == 1:
            return str(remaining[0])
        if remaining:
            return f"{remaining[0]}..{remaining[-1]}" if remaining == list(
                range(remaining[0], remaining[-1] + 1)) else ",".join(map(str, remaining))
    return "?" + "&".join(f"{op}{val}" for op, val in path)


def collect_calls(node, out):
    if isinstance(node, dict):
        if node.get("type") == "AstExprCall":
            fn = node.get("func", {})
            name = None
            if fn.get("type") == "AstExprIndexName":
                base = fn.get("expr", {})
                if base.get("type") == "AstExprGlobal":
                    name = f"{base.get('global')}.{fn.get('index')}"
            elif fn.get("type") == "AstExprGlobal":
                name = fn.get("global")
            elif fn.get("type") == "AstExprLocal":
                name = fn.get("local", {}).get("name")
            if name:
                out.add(name)
        for k, v in node.items():
            if k == "type":
                continue
            collect_calls(v, out)
    elif isinstance(node, list):
        for item in node:
            collect_calls(item, out)


def collect_index_bases(node, out):
    """Which upvalue/local *names* get indexed (e.g. R, r, k, E, V, n, o) --
    a proxy for which parallel arrays this opcode touches."""
    if isinstance(node, dict):
        if node.get("type") == "AstExprIndexExpr":
            base = node.get("expr", {})
            if base.get("type") == "AstExprLocal":
                out.add(base.get("local", {}).get("name"))
        for k, v in node.items():
            if k == "type":
                continue
            collect_index_bases(v, out)
    elif isinstance(node, list):
        for item in node:
            collect_index_bases(item, out)


def has_type(node, want):
    if isinstance(node, dict):
        if node.get("type") == want:
            return True
        return any(has_type(v, want) for k, v in node.items() if k != "type")
    elif isinstance(node, list):
        return any(has_type(item, want) for item in node)
    return False


def sets_var(node, name):
    """Does this subtree assign (= or compound) to a local named `name`?"""
    if isinstance(node, dict):
        t = node.get("type")
        if t in ("AstStatAssign", "AstStatCompoundAssign"):
            vars_ = node.get("vars") or [node.get("var")]
            for v in vars_:
                if v and v.get("type") == "AstExprLocal" and v.get("local", {}).get("name") == name:
                    return True
        return any(sets_var(v, name) for k, v in node.items() if k != "type")
    elif isinstance(node, list):
        return any(sets_var(item, name) for item in node)
    return False


def classify_leaf(body, pc_var):
    calls = set()
    collect_calls(body, calls)
    arrays = set()
    collect_index_bases(body, arrays)
    cats = []
    if any(c.startswith("bit32.") for c in calls):
        cats.append("BITWISE")
    if any(c.startswith("buffer.") for c in calls):
        cats.append("BUFFER")
    if any(c.startswith("string.") for c in calls):
        cats.append("STRING")
    if any(c.startswith("table.") for c in calls):
        cats.append("TABLE")
    if has_type(body, "AstStatReturn"):
        cats.append("RETURN")
    if has_type(body, "AstStatBreak"):
        cats.append("LOOP-EXIT")
    if has_type(body, "AstStatFor") or has_type(body, "AstStatWhile") or has_type(body, "AstStatRepeat"):
        cats.append("LOOP")
    if sets_var(body, pc_var):
        cats.append("JUMP")
    if has_type(body, "AstExprCall") and not cats:
        cats.append("CALL")
    if not cats:
        cats.append("ARITH/MOVE")
    return "|".join(cats), sorted(calls), sorted(a for a in arrays if a)


def unwrap(node, m_var):
    """A `then`/`else` block that ends in a further dispatch if-chain looks
    like `{ local f=w; if M<14 then ... end }` -- statements before the
    trailing AstStatIf are setup shared by every opcode under it (e.g. an
    operand-index local), not a handler body. Split those off so recursion
    continues into the real chain instead of swallowing it as one leaf.
    Guarded by `is_opcode_compare` so an opcode handler whose OWN unrelated
    `if` happens to be its last statement isn't mistaken for more dispatch."""
    if node.get("type") == "AstStatBlock":
        b = node.get("body", [])
        if b and b[-1].get("type") == "AstStatIf" and is_opcode_compare(b[-1]["condition"], m_var):
            return b[:-1], b[-1]
    return [], node


def walk_dispatch(node, pc_var, m_var, path, out, prefix=()):
    """Recurse the dispatch AstStatIf chain; at each leaf resolve+classify
    (folding in any shared `prefix` statements collected along the way)."""
    extra, inner = unwrap(node, m_var)
    prefix = tuple(prefix) + tuple(extra)
    is_dispatch_if = inner.get("type") == "AstStatIf" and is_opcode_compare(inner.get("condition", {}), m_var)
    if not is_dispatch_if:
        opcode = resolve_opcode(path)
        combined = {"type": "AstStatBlock", "body": list(prefix) + [inner]}
        cat, calls, arrays = classify_leaf(combined, pc_var)
        out.append({"opcode": opcode, "category": cat, "calls": calls,
                    "arrays": arrays, "location": inner.get("location")})
        return
    node = inner
    terms = list(cond_terms(node.get("condition", {})))
    then_body = node.get("thenbody")
    walk_dispatch(then_body, pc_var, m_var, path + terms, out, prefix)
    if node.get("elsebody"):
        neg = {"<": ">=", ">=": "<", ">": "<=", "<=": ">", "==": "~=", "~=": "=="}
        else_terms = [(neg[op], val) for op, val in terms]
        eb = node["elsebody"]
        # `elseif` desugars to elsebody being a bare AstStatIf (no wrapping
        # AstStatBlock); a plain trailing `else` wraps its statements in one.
        walk_dispatch(eb, pc_var, m_var, path + else_terms, out, prefix)


def main():
    ap = argparse.ArgumentParser(description="v15 payload-VM opcode semantics (AST-based)")
    ap.add_argument("sample")
    ap.add_argument("--luau-ast", default="../dynamic/luau-ast")
    ap.add_argument("--hist", help="v15_payload_probe.py --json output, for dynamic overlay")
    ap.add_argument("--json")
    ap.add_argument("--md")
    args = ap.parse_args()

    src = open(args.sample, encoding="utf-8", errors="replace").read()
    groups = find_vm_groups(src)
    if not groups:
        sys.exit("!! no candidate dispatch loop found")
    pc = pick_payload_vm(groups)
    blocks = groups[pc]
    print(f"[v15-payload-opcodes] pc-var '{pc}', {len(blocks)} dispatch block(s)")

    hist = {}
    if args.hist:
        h = json.load(open(args.hist))
        for mode_i, info in h.get("modes", {}).items():
            hist[int(mode_i)] = dict(info.get("top_opcodes", []))

    root = run_luau_ast(args.luau_ast, args.sample)["root"]

    modes = {}
    for i, (start, end, M, ARR, richness) in enumerate(blocks):
        # `start` is the start of the whole "while true do local M=o[w];"
        # match; the fetch AstStatLocal node's own location only spans
        # "local M=o[w];" -- back it out from the known literal shape.
        fetch_text = f"local {M}={ARR}[{pc}];"
        fetch_start = end - len(fetch_text)
        line, col = offset_to_line_col(src, fetch_start)
        fetch_loc = f"{line},{col} - {line},{col + len(fetch_text)}"
        wnode = find_enclosing_while(root, fetch_loc)
        if wnode is None:
            print(f"  mode {i}: !! could not locate AstStatWhile via fetch location {fetch_loc}")
            modes[i] = {"opcode_var": M, "fetch_array": ARR, "error": "not found", "opcodes": []}
            continue
        dispatch_root = wnode["body"]["body"][1]
        leaves = []
        walk_dispatch(dispatch_root, pc, M, [], leaves)
        counts = hist.get(i, {})
        for leaf in leaves:
            leaf["dynamic_count"] = counts.get(leaf["opcode"], 0)
        leaves.sort(key=lambda x: -x["dynamic_count"])
        modes[i] = {"opcode_var": M, "fetch_array": ARR, "opcodes": leaves}
        print(f"  mode {i} ({M}={ARR}[{pc}]): {len(leaves)} opcode branches classified")

    if args.json:
        json.dump({"sample": args.sample, "pc_var": pc, "modes": modes},
                   open(args.json, "w"), indent=1)
        print(f"  -> {args.json}")
    if args.md:
        with open(args.md, "w") as f:
            f.write(f"# v15 payload-VM opcode semantics — `{args.sample}`\n\n")
            f.write(f"Pc variable: `{pc}`. Built by parsing the exact AST of each dispatch "
                    "loop's if/elseif chain (see `v15_payload_opcodes.py`), not guesswork.\n\n")
            for i, info in sorted(modes.items()):
                f.write(f"## mode {i} — `{info['opcode_var']}={info['fetch_array']}[{pc}]`\n\n")
                if "error" in info:
                    f.write(f"_{info['error']}_\n\n")
                    continue
                f.write("| opcode | dyn. count | category | calls | arrays touched |\n")
                f.write("|---|---|---|---|---|\n")
                for op in info["opcodes"]:
                    f.write(f"| {op['opcode']} | {op['dynamic_count']} | {op['category']} | "
                            f"{' '.join(op['calls'][:4])} | {' '.join(op['arrays'])} |\n")
                f.write("\n")
        print(f"  -> {args.md}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
