#!/usr/bin/env python3
# ============================================================
#  chain_dispatch_probe.py  --  generic detector + dynamic probe for
#  "comparison-chain" register-VM dispatch loops (a SECOND Luraph codegen
#  shape, distinct from v15_payload_probe.py's array-fetch shape)
#
#  v15_payload_probe.py's find_vm_groups looks for one specific textual
#  shape: `while true do local <M>=<ARR>[<PC>];` -- an opcode FETCHED from
#  an array each iteration. That is sample_v15.lua's shape, but it is not
#  the only one real-world Luraph output uses: a second, independently-
#  authored real Luraph v15.0 sample (see ../mm2.md) has its actual VM
#  written as `while true do if <B><cmp><const> then ... end` instead -- a
#  PRE-SET state variable compared via a binary-search-style if/elseif
#  chain, reassigned inside each branch, with no array fetch at all. A
#  third file (a non-Luraph SDK library, also noted in mm2.md, checked to
#  rule this shape out as Luraph-specific) independently uses the same
#  comparison-chain shape for its own internal state machines -- so this
#  shape is common enough across obfuscated Lua generally to be worth its
#  own generic detector, the same way v15_payload_probe.py's is generic
#  rather than hardcoded to one sample's variable names.
#
#  This finds those loops GENERICALLY (regex anchor + a richness filter,
#  same method find_vm_groups uses), groups them by the compared variable,
#  and can inject a low-overhead one-shot-per-value probe at the top of a
#  chosen loop's body for real dynamic coverage. Leaf classification for a
#  found loop can reuse devirt/v15_payload_opcodes.py's AST-based
#  walk_dispatch/classify_leaf UNCHANGED -- that code only needs an m_var
#  name and an AstStatIf node, not the array-fetch shape (see mm2.md for a
#  worked example passing pc_var=m_var='B' straight into it).
#
#  Usage:
#    # just list candidates, no execution:
#    python3 devirt/chain_dispatch_probe.py sample.lua --list
#
#    # probe dynamic coverage of one (defaults to the richest):
#    python3 devirt/chain_dispatch_probe.py sample.lua \
#        --luau dynamic/luau --deobf dynamic/deobf_v15.py \
#        --timeout 300 --json out.json --md out.md
# ============================================================

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
from collections import defaultdict

CHAIN_RE = re.compile(
    r'while\s+true\s+do\s+'
    r'(?P<body>if\s+(?P<var>\w+)\s*(?P<op><=|>=|==|~=|<|>)\s*-?\d)'
)

WATCH_TAG = "[[CHAINOP]]"


def find_chain_groups(src):
    """Find candidate comparison-chain dispatch loops, grouped by the
    compared state variable. Returns {var: [(loop_start, body_start,
    richness), ...]}: loop_start is the offset of `while`, body_start the
    offset where the `if <var>...` chain begins (the injection point),
    richness the number of further `<var><cmp>` comparisons in the next
    4000 chars (same false-positive filter idea as find_vm_groups)."""
    groups = defaultdict(list)
    for m in CHAIN_RE.finditer(src):
        var = m.group('var')
        body_start = m.start('body')
        region = src[body_start: body_start + 4000]
        richness = len(re.findall(r'\b' + re.escape(var) + r'\s*(?:<=|>=|==|~=|<|>)', region))
        if richness < 3:
            continue
        groups[var].append((m.start(), body_start, richness))
    return groups


def pick_richest(groups):
    if not groups:
        return None
    return max(groups, key=lambda v: sum(r for *_, r in groups[v]))


def build_probe(var, progress_every):
    tag_var = re.sub(r'\W', '_', var)
    return (
        f' __n_{tag_var}=(__n_{tag_var} or 0)+1 '
        f'__seen_{tag_var}=__seen_{tag_var} or {{}} '
        f'if not __seen_{tag_var}[{var}] then __seen_{tag_var}[{var}]=true '
        f'print("{WATCH_TAG} var={var} val="..tostring({var}).." n="..__n_{tag_var}) end '
        f'if __n_{tag_var}%{progress_every}==0 then '
        f'print("{WATCH_TAG} progress n="..__n_{tag_var}.." var={var} val="..tostring({var})) end;'
    )


def main():
    ap = argparse.ArgumentParser(
        description="detect + dynamically probe comparison-chain dispatch loops")
    ap.add_argument("sample")
    ap.add_argument("--list", action="store_true",
                     help="only list candidate groups, don't run anything")
    ap.add_argument("--var", default=None,
                     help="probe this specific variable's dispatch loop instead of the richest")
    ap.add_argument("--instance", type=int, default=0,
                     help="if --var has multiple loop instances, which one (0-based, default richest-first)")
    ap.add_argument("--luau", default="dynamic/luau")
    ap.add_argument("--deobf", default="dynamic/deobf_v15.py")
    ap.add_argument("--progress-every", type=int, default=2_000_000)
    ap.add_argument("--timeout", type=int, default=120)
    ap.add_argument("--workdir", default=None)
    ap.add_argument("--json")
    ap.add_argument("--md")
    args = ap.parse_args()

    src = open(args.sample, encoding="utf-8", errors="replace").read()
    groups = find_chain_groups(src)
    if not groups:
        sys.exit("!! no candidate comparison-chain dispatch loop found")

    print(f"[chain-dispatch] candidate groups: "
          f"{ {k: len(v) for k, v in groups.items()} }")
    for var, instances in sorted(groups.items(), key=lambda kv: -sum(r for *_, r in kv[1])):
        total = sum(r for *_, r in instances)
        print(f"  var '{var}': {len(instances)} instance(s), total richness {total}")

    if args.list:
        return 0

    var = args.var or pick_richest(groups)
    if var not in groups:
        sys.exit(f"!! var '{var}' not among candidate groups: {sorted(groups)}")
    instances = sorted(groups[var], key=lambda t: -t[2])
    if args.instance >= len(instances):
        sys.exit(f"!! var '{var}' only has {len(instances)} instance(s)")
    loop_start, body_start, richness = instances[args.instance]
    print(f"[chain-dispatch] probing var '{var}' instance {args.instance} "
          f"(richness {richness}) at offset {body_start}")

    probe = build_probe(var, args.progress_every)
    patched = src[:body_start] + probe + src[body_start:]

    workdir = args.workdir or tempfile.mkdtemp(prefix="chaindispatch_")
    os.makedirs(workdir, exist_ok=True)
    instrumented = os.path.join(workdir, "chainprobe_" + os.path.basename(args.sample))
    out_prefix = os.path.join(workdir, "chain_run")
    open(instrumented, "w", encoding="utf-8").write(patched)

    cmd = [sys.executable, args.deobf, instrumented, "--luau", args.luau,
           "--timeout", str(args.timeout), "--out", out_prefix]
    print(f"[chain-dispatch] running (timeout={args.timeout}s)...")
    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    raw = out_prefix + ".raw.txt"
    if not os.path.exists(raw):
        sys.exit(f"!! expected {raw}, not found")

    last_progress = None
    events = []
    with open(raw, encoding="utf-8", errors="replace") as f:
        for line in f:
            m = re.search(re.escape(WATCH_TAG) + r" (.*)", line)
            if not m:
                continue
            body = m.group(1).rstrip('"')
            if body.startswith("progress"):
                last_progress = body
            else:
                events.append(body)

    print(f"\n[chain-dispatch] {args.sample}, var '{var}'")
    print(f"  last progress: {last_progress}")
    print(f"  {len(events)} distinct value(s) observed:")
    for e in events:
        print(f"    {e}")

    result = {"sample": args.sample, "var": var, "instance": args.instance,
              "last_progress": last_progress, "events": events}
    if args.json:
        json.dump(result, open(args.json, "w"), indent=1)
        print(f"\n  -> {args.json}")
    if args.md:
        with open(args.md, "w") as f:
            f.write(f"# chain-dispatch probe — `{args.sample}`, var `{var}`\n\n")
            f.write(f"- last progress: `{last_progress}`\n")
            f.write(f"- {len(events)} distinct value(s) observed\n\n")
            f.write("| event |\n|---|\n")
            for e in events:
                f.write(f"| {e} |\n")
        print(f"  -> {args.md}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
