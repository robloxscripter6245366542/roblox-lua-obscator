#!/usr/bin/env python3
# ============================================================
#  chain_opcode_semantics.py  --  opcode SEMANTICS for the comparison-chain
#  dispatch shape (chain_dispatch_probe.py's detector), the missing half of
#  what v15_payload_opcodes.py already does for the array-fetch shape.
#
#  mm2.md's investigation proved walk_dispatch/classify_leaf (AST-based leaf
#  classification, originally written for v15_payload_probe.py's array-fetch
#  `while true do local M=o[w]; if M<N then...` shape) work COMPLETELY
#  UNCHANGED on a comparison-chain loop `while <var> do if <var><=N> then...`
#  -- that code only ever needed an `m_var` name and the dispatch chain's
#  AstStatIf node, never the array-fetch shape itself. This ties that
#  already-proven fact to a real CLI: find a comparison-chain loop with
#  chain_dispatch_probe.py's own detector, locate its AstStatIf via AST (not
#  text offsets -- the lesson this whole project keeps relearning), and feed
#  it straight into v15_payload_opcodes.py's classifier.
#
#  Usage:
#    python3 devirt/chain_opcode_semantics.py sample.lua \
#        --luau-ast dynamic/luau-ast --var K \
#        --json out.json --md out.md
# ============================================================

import argparse
import json
import sys

from chain_dispatch_probe import find_chain_groups, pick_richest
from v15_payload_opcodes import walk_dispatch, run_luau_ast, offset_to_line_col, find_node_at


def find_stat_if_at(root, line, col):
    node = find_node_at(root, line, col)
    if node is not None and node.get("type") == "AstStatIf":
        return node
    return None


def main():
    ap = argparse.ArgumentParser(
        description="opcode semantics for a comparison-chain dispatch loop (AST-based)")
    ap.add_argument("sample")
    ap.add_argument("--luau-ast", default="dynamic/luau-ast")
    ap.add_argument("--var", default=None,
                     help="target this specific compared variable instead of the richest")
    ap.add_argument("--instance", type=int, default=0,
                     help="if --var has multiple loop instances, which one (0-based, richest-first)")
    ap.add_argument("--json")
    ap.add_argument("--md")
    args = ap.parse_args()

    src = open(args.sample, encoding="utf-8", errors="replace").read()
    groups = find_chain_groups(src)
    if not groups:
        sys.exit("!! no candidate comparison-chain dispatch loop found")

    var = args.var or pick_richest(groups)
    if var not in groups:
        sys.exit(f"!! var '{var}' not among candidate groups: {sorted(groups)}")
    instances = sorted(groups[var], key=lambda t: -t[2])
    if args.instance >= len(instances):
        sys.exit(f"!! var '{var}' only has {len(instances)} instance(s)")
    loop_start, body_start, richness = instances[args.instance]
    line, col = offset_to_line_col(src, body_start)
    print(f"[chain-opcode-semantics] var '{var}' instance {args.instance} "
          f"(richness {richness}) at offset {body_start} ({line},{col})")

    ast = run_luau_ast(args.luau_ast, args.sample)
    root = ast["root"] if isinstance(ast, dict) and "root" in ast else ast
    node = find_stat_if_at(root, line, col)
    if node is None:
        sys.exit(f"!! could not locate the dispatch AstStatIf at ({line},{col}) -- "
                  f"the regex offset and the AST disagree, don't trust this candidate")

    leaves = []
    walk_dispatch(node, var, var, [], leaves)
    leaves.sort(key=lambda x: x["opcode"])
    print(f"  {len(leaves)} opcode branch(es) classified")
    for leaf in leaves:
        print(f"    {leaf['opcode']}: {leaf['category']}  "
              f"calls={leaf['calls'][:4]}  arrays={leaf['arrays']}")

    if args.json:
        json.dump({"sample": args.sample, "var": var, "instance": args.instance,
                   "richness": richness, "opcodes": leaves}, open(args.json, "w"), indent=1)
        print(f"  -> {args.json}")
    if args.md:
        with open(args.md, "w") as f:
            f.write(f"# chain-dispatch opcode semantics — `{args.sample}`, var `{var}`\n\n")
            f.write(f"Built by parsing the exact AST of the dispatch if/elseif chain "
                     "(same `walk_dispatch`/`classify_leaf` as "
                     "`v15_payload_opcodes.py`, unchanged), not guesswork.\n\n")
            f.write("| opcode | category | calls | arrays touched |\n|---|---|---|---|\n")
            for op in leaves:
                f.write(f"| {op['opcode']} | {op['category']} | "
                        f"{' '.join(op['calls'][:4])} | {' '.join(op['arrays'])} |\n")
        print(f"  -> {args.md}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
