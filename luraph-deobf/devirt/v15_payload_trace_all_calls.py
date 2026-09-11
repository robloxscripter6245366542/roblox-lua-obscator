#!/usr/bin/env python3
# ============================================================
#  v15_payload_trace_all_calls.py  --  what does EVERY CALL-classified
#  opcode across all 4 dispatch modes actually invoke?
#
#  v15_payload_trace_zcalls.py answered "what does t[F[4]] compute" for the
#  3 specific save-call-restore sites that gate the payload's exit path (see
#  v15.md's "Payload recovery harness" section). That's 3 call sites out of
#  the ~75 opcode branches v15_payload_opcode_semantics.py already
#  classifies as CALL across all 4 modes -- any of the other ~72 could, in
#  principle, be the place real Roblox/executor state (game, HttpService,
#  Instance.new, etc.) would need to enter for the payload to do anything
#  observable. Two independent long-depth runs already ruled out "it just
#  needs more time" (see v15.md); this rules in/out "does any CALL site's
#  target ever look like live client state" instead -- the concrete
#  not-yet-tried step v15.md's ways-forward list named.
#
#  For each CALL leaf (per the same AST-based classification
#  v15_payload_opcode_semantics.py uses), this locates every AstExprCall
#  node inside that leaf's body via luau-ast, extracts the exact source
#  text of each call's callee expression (not just the small subset a
#  by-name search could resolve -- any index expression too, e.g.
#  `t[F[4]]` or `R[x]`), and injects a one-shot probe at the top of the
#  leaf's body that describes the callee's runtime value the first time
#  that opcode fires: type, and for tables/userdata, identity against
#  game/workspace/script plus a sample of its keys -- the "does this look
#  like a Roblox API surface" signal. Safe to evaluate that early: any
#  operand locals the callee expression depends on are bound by the shared
#  dispatch prefix BEFORE the branch is entered (see unwrap() in
#  v15_payload_opcodes.py), and every describe is itself pcall-wrapped.
#
#  Usage:
#    python3 devirt/v15_payload_trace_all_calls.py sample_v15.lua \
#        --luau dynamic/luau --deobf dynamic/deobf_v15.py \
#        --luau-ast dynamic/luau-ast --timeout 600 \
#        --json v15_payload_call_targets.json --md v15_payload_call_targets.md
# ============================================================

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile

import v15_payload_opcodes as vpo
from v15_payload_probe import find_vm_groups, pick_payload_vm

TAG = "[[CALLTARGET]]"


def line_col_to_offset(src, line, col):
    idx = -1
    for _ in range(line):
        idx = src.find("\n", idx + 1)
        if idx == -1:
            raise ValueError(f"line {line} out of range")
    return idx + 1 + col


def loc_span(src, location):
    start, end = location.split(" - ")
    l1, c1 = map(int, start.split(","))
    l2, c2 = map(int, end.split(","))
    return line_col_to_offset(src, l1, c1), line_col_to_offset(src, l2, c2)


def collect_call_func_nodes(node, out):
    """Every AstExprCall's callee (func) node found anywhere in `node`."""
    if isinstance(node, dict):
        if node.get("type") == "AstExprCall":
            fn = node.get("func")
            if fn and fn.get("location"):
                out.append(fn)
        for k, v in node.items():
            if k == "type":
                continue
            collect_call_func_nodes(v, out)
    elif isinstance(node, list):
        for item in node:
            collect_call_func_nodes(item, out)


def walk_dispatch_nodes(node, pc_var, m_var, path, out, prefix=()):
    """Same recursion as v15_payload_opcodes.walk_dispatch, but records the
    actual leaf AST node (not just its location string) so callers can
    re-walk it for AstExprCall nodes without a second, ambiguity-prone
    lookup by (line, col) into a freshly-reparsed tree."""
    extra, inner = vpo.unwrap(node, m_var)
    prefix = tuple(prefix) + tuple(extra)
    is_dispatch_if = (inner.get("type") == "AstStatIf" and
                       vpo.is_opcode_compare(inner.get("condition", {}), m_var))
    if not is_dispatch_if:
        opcode = vpo.resolve_opcode(path)
        combined = {"type": "AstStatBlock", "body": list(prefix) + [inner]}
        cat, calls, arrays = vpo.classify_leaf(combined, pc_var)
        out.append({"opcode": opcode, "category": cat, "node": inner})
        return
    node = inner
    terms = list(vpo.cond_terms(node.get("condition", {})))
    then_body = node.get("thenbody")
    walk_dispatch_nodes(then_body, pc_var, m_var, path + terms, out, prefix)
    if node.get("elsebody"):
        neg = {"<": ">=", ">=": "<", ">": "<=", "<=": ">", "==": "~=", "~=": "=="}
        else_terms = [(neg[op], val) for op, val in terms]
        walk_dispatch_nodes(node["elsebody"], pc_var, m_var, path + else_terms, out, prefix)


def describe_helper_snippet():
    return (
        "local function __describe_call(v)\n"
        "  local ok,ty=pcall(function() return type(v) end)\n"
        "  if not ok then return '<error>' end\n"
        "  if ty=='function' then return 'function '..tostring(v) end\n"
        "  if ty=='table' then\n"
        "    local ident=''\n"
        "    if v==game then ident=ident..' IS_GAME' end\n"
        "    if v==workspace then ident=ident..' IS_WORKSPACE' end\n"
        "    if v==script then ident=ident..' IS_SCRIPT' end\n"
        "    local n=0 local keys={}\n"
        "    pcall(function() for k in pairs(v) do n=n+1 if n<=6 then keys[#keys+1]=tostring(k) end end end)\n"
        "    return 'table n='..n..' keys='..table.concat(keys,',')..ident\n"
        "  end\n"
        "  if ty=='userdata' then\n"
        "    local ok3,cn=pcall(function() return v.ClassName end)\n"
        "    local ident=''\n"
        "    if v==game then ident=ident..' IS_GAME' end\n"
        "    if v==workspace then ident=ident..' IS_WORKSPACE' end\n"
        "    if v==script then ident=ident..' IS_SCRIPT' end\n"
        "    return 'userdata '..tostring(v)..(ok3 and (' ClassName='..tostring(cn)) or '')..ident\n"
        "  end\n"
        "  return ty..'='..tostring(v)\n"
        "end\n"
        "local __seen_call={}\n"
    )


def build_describe_expr(func_srcs):
    if not func_srcs:
        return '"<no call expr located>"'
    parts = [f'"T{j}="..__describe_call({txt})' for j, txt in enumerate(func_srcs)]
    return "..' '..".join(parts)


def build_site_probe(site_id, mode_idx, opcode, func_srcs):
    describe_expr = build_describe_expr(func_srcs)
    op_json = json.dumps(str(opcode))
    # Leading space: the leaf body's start offset can sit directly against a
    # preceding `then`/`else` keyword with no separator in this minified
    # source, and identifier-vs-identifier adjacency (e.g. `then`+`if` ->
    # `thenif`) is a real Luau lexer merge, not a stylistic nicety.
    return (
        f' if not __seen_call["{site_id}"] then __seen_call["{site_id}"]=true '
        f'local __ok,__msg=pcall(function() return {describe_expr} end) '
        f'print("{TAG} site={site_id} mode={mode_idx} op="..{op_json}..'
        f'" "..(__ok and __msg or "<describe-error>")) end;'
    )


def main():
    ap = argparse.ArgumentParser(
        description="trace what every CALL-classified payload-VM opcode actually calls")
    ap.add_argument("sample")
    ap.add_argument("--luau", default="dynamic/luau")
    ap.add_argument("--deobf", default="dynamic/deobf_v15.py")
    ap.add_argument("--luau-ast", default="dynamic/luau-ast")
    ap.add_argument("--timeout", type=int, default=600)
    ap.add_argument("--workdir", default=None)
    ap.add_argument("--json")
    ap.add_argument("--md")
    args = ap.parse_args()

    src = open(args.sample, encoding="utf-8", errors="replace").read()
    groups = find_vm_groups(src)
    if not groups:
        sys.exit("!! no candidate dispatch loop found")
    pc = pick_payload_vm(groups)
    blocks = groups[pc]
    print(f"[v15-all-calls] pc-var '{pc}', {len(blocks)} dispatch block(s)")

    root = vpo.run_luau_ast(args.luau_ast, args.sample)["root"]

    sites = []  # (offset, site_id, mode_idx, opcode, func_srcs)
    for i, (start, end, M, ARR, richness) in enumerate(blocks):
        fetch_text = f"local {M}={ARR}[{pc}];"
        fetch_start = end - len(fetch_text)
        line, col = vpo.offset_to_line_col(src, fetch_start)
        fetch_loc = f"{line},{col} - {line},{col + len(fetch_text)}"
        wnode = vpo.find_enclosing_while(root, fetch_loc)
        if wnode is None:
            print(f"  mode {i}: !! could not locate AstStatWhile")
            continue
        dispatch_root = wnode["body"]["body"][1]
        leaves = []
        walk_dispatch_nodes(dispatch_root, pc, M, [], leaves)

        n_call = 0
        for leaf in leaves:
            if "CALL" not in leaf["category"]:
                continue
            n_call += 1
            node = leaf["node"]
            loc = node.get("location")
            if not loc:
                continue
            lstart = loc.split(" - ")[0]
            lline, lcol = map(int, lstart.split(","))

            func_nodes = []
            collect_call_func_nodes(node, func_nodes)
            func_srcs = []
            for fn in func_nodes:
                try:
                    s, e = loc_span(src, fn["location"])
                    func_srcs.append(src[s:e])
                except Exception:
                    continue

            site_id = f"{i}:{leaf['opcode']}"
            offset = line_col_to_offset(src, lline, lcol)
            sites.append((offset, site_id, i, leaf["opcode"], func_srcs))
        print(f"  mode {i}: {n_call} CALL-classified leaf(es)")

    print(f"[v15-all-calls] {len(sites)} total CALL sites to instrument")

    patched = src
    for offset, site_id, mode_idx, opcode, func_srcs in sorted(sites, key=lambda t: -t[0]):
        probe = build_site_probe(site_id, mode_idx, opcode, func_srcs)
        patched = patched[:offset] + probe + patched[offset:]
    patched = describe_helper_snippet() + patched

    workdir = args.workdir or tempfile.mkdtemp(prefix="v15allcalls_")
    os.makedirs(workdir, exist_ok=True)
    instrumented = os.path.join(workdir, "allcalls_" + os.path.basename(args.sample))
    out_prefix = os.path.join(workdir, "allcalls_run")
    open(instrumented, "w", encoding="utf-8").write(patched)

    cmd = [sys.executable, args.deobf, instrumented, "--luau", args.luau,
           "--timeout", str(args.timeout), "--out", out_prefix]
    print(f"[v15-all-calls] running (timeout={args.timeout}s)...")
    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    raw = out_prefix + ".raw.txt"
    if not os.path.exists(raw):
        sys.exit(f"!! expected {raw}, not found")

    fired = {}
    with open(raw, encoding="utf-8", errors="replace") as f:
        for line in f:
            m = re.search(re.escape(TAG) + r" (.*)", line)
            if not m:
                continue
            body = m.group(1).rstrip('"')
            site_m = re.match(r"site=(\S+) mode=(\d+) op=(.*?) (.*)", body)
            if site_m:
                sid, mode_i, op, desc = site_m.groups()
                fired[sid] = {"mode": int(mode_i), "opcode": op, "desc": desc}

    total_sites = len(sites)
    print(f"\n[v15-all-calls] {args.sample}: {len(fired)}/{total_sites} CALL sites fired")
    interesting_kw = ("IS_GAME", "IS_WORKSPACE", "IS_SCRIPT", "ClassName",
                       "GetService", "HttpGet", "HttpPost", "Instance")
    interesting = [(sid, info) for sid, info in fired.items()
                   if any(kw in info["desc"] for kw in interesting_kw)]

    for sid, info in sorted(fired.items()):
        print(f"  {sid} mode={info['mode']} op={info['opcode']} -> {info['desc']}")
    if interesting:
        print(f"\n  !! {len(interesting)} site(s) touched something Roblox-API-shaped:")
        for sid, info in interesting:
            print(f"    {sid}: {info['desc']}")
    else:
        print("\n  no fired CALL site's target looked like a Roblox API surface "
              "(no game/workspace/script identity, no ClassName, no service-style call)")

    result = {
        "sample": args.sample, "total_sites": total_sites,
        "fired": fired, "interesting": [sid for sid, _ in interesting],
    }
    if args.json:
        json.dump(result, open(args.json, "w"), indent=1)
        print(f"\n  -> {args.json}")
    if args.md:
        with open(args.md, "w") as f:
            f.write(f"# v15 payload-VM CALL-target trace — `{args.sample}`\n\n")
            f.write(f"{len(fired)}/{total_sites} CALL-classified opcode sites fired.\n\n")
            f.write("| site | mode | opcode | callee description |\n|---|---|---|---|\n")
            for sid, info in sorted(fired.items()):
                f.write(f"| {sid} | {info['mode']} | {info['opcode']} | {info['desc']} |\n")
            f.write("\n")
            if interesting:
                f.write(f"**{len(interesting)} site(s) touched something Roblox-API-shaped** "
                        "(game/workspace/script identity, a ClassName, or a service-style call):\n\n")
                for sid, info in interesting:
                    f.write(f"- `{sid}`: {info['desc']}\n")
            else:
                f.write("No fired CALL site's target looked like a Roblox API surface.\n")
        print(f"  -> {args.md}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
