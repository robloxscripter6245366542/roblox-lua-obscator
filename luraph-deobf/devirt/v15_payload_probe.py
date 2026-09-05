#!/usr/bin/env python3
# ============================================================
#  v15_payload_probe.py  --  dynamic opcode coverage for v15's payload VM
#
#  devirt/v15_opcodes.py maps v15's ~145 top-level `NAME=function(...)`
#  handlers (the loader/deserialiser stage -- see v15.md). Those are not the
#  only VM in a v15 sample: the sample's own bytecode is then interpreted by
#  a SEPARATE register machine written directly in the sample's source as a
#  handful of `while true do local <M>=<ARR>[<PC>]; if <M>==... end` dispatch
#  loops sharing one pc variable -- multiple "modes" (T-values in the sample
#  this was built against) selected by a mode-switch opcode, all living
#  inside one enclosing closure. This is the loop `dynamic/deobf_v15.py` gets
#  stuck in after it boots past the loader (see v15.md's "Payload recovery
#  harness" section for how that was found, and its correction below).
#
#  This tool finds those dispatch loops GENERICALLY (regex, like
#  run_vm.py's find_dispatch -- no fixed variable names), groups them by
#  shared pc-variable (each group is one candidate VM), picks the group with
#  the richest comparison chains as "the payload VM", and INJECTS a probe
#  print right after each of its opcode fetches. Running the probed copy
#  through the existing dynamic/deobf_v15.py environment (same rich
#  Roblox/executor stub, same loader) gives a REAL per-opcode dynamic
#  frequency histogram and pc-range coverage per mode -- ground truth,
#  not guesswork from a handful of manually-sampled snapshots.
#
#  Usage:
#    python3 devirt/v15_payload_probe.py sample_v15.lua \
#        --luau dynamic/luau --deobf dynamic/deobf_v15.py \
#        --timeout 60 --json out.json --md out.md
# ============================================================

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
from collections import Counter, defaultdict

DISPATCH_RE = re.compile(r'while true do local (\w+)=(\w+)\[(\w+)\];')


def find_vm_groups(src):
    """Find candidate register-VM dispatch loops, grouped by shared pc var.

    Returns {pc_var: [(start, end_of_fetch, M, ARR, richness), ...]}, richness
    being the number of `M<op>`-style comparisons in the 6000 chars after the
    fetch (same signal run_vm.py uses to reject non-dispatch matches).
    """
    groups = defaultdict(list)
    for m in DISPATCH_RE.finditer(src):
        M, ARR, PC = m.groups()
        region = src[m.end(): m.end() + 6000]
        richness = len(re.findall(r'\b' + re.escape(M) + r'\s*[<>=~]', region))
        if richness < 3:
            continue
        groups[PC].append((m.start(), m.end(), M, ARR, richness))
    return groups


def pick_payload_vm(groups):
    """The payload VM is the pc-var group with the most total comparisons
    across its blocks (the loader's own dispatch, if any, is typically
    smaller/flatter than the program interpreter it feeds)."""
    if not groups:
        return None
    return max(groups, key=lambda pc: sum(r for *_, r in groups[pc]))


def inject_probes(src, blocks, pc_var):
    """Insert a `print("[[VMOP]] mode=<i> M=.. pc=..")` right after each
    block's opcode fetch. Processes highest offset first so earlier offsets
    stay valid."""
    out = src
    for i, (start, end, M, ARR, richness) in sorted(enumerate(blocks), key=lambda x: -x[1][0]):
        probe = f'print("[[VMOP]] mode={i} M="..tostring({M}).." pc="..tostring({pc_var}));'
        out = out[:end] + probe + out[end:]
    return out


def run_probe(sample_path, luau, deobf_script, timeout, workdir):
    instrumented = os.path.join(workdir, "probed_" + os.path.basename(sample_path))
    out_prefix = os.path.join(workdir, "probe_run")
    src = open(sample_path, encoding="utf-8", errors="replace").read()
    groups = find_vm_groups(src)
    if not groups:
        sys.exit("!! no candidate dispatch loop found (regex didn't match -- "
                 "this sample's payload VM may use a different source shape)")
    pc = pick_payload_vm(groups)
    blocks = groups[pc]
    print(f"[v15-payload-probe] pc-var groups found: "
          f"{ {k: len(v) for k, v in groups.items()} }")
    print(f"[v15-payload-probe] picked pc-var '{pc}' with {len(blocks)} "
          f"dispatch block(s) (richest comparison chains)")
    patched = inject_probes(src, blocks, pc)
    open(instrumented, "w", encoding="utf-8").write(patched)

    cmd = [sys.executable, deobf_script, instrumented, "--luau", luau,
           "--timeout", str(timeout), "--out", out_prefix]
    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    raw = out_prefix + ".raw.txt"
    if not os.path.exists(raw):
        sys.exit(f"!! expected {raw} from {deobf_script}, not found")
    return raw, blocks


VMOP_RE = re.compile(r'\[\[VMOP\]\] mode=(\d+) M=(-?\d+) pc=(-?\d+)')


def summarize(raw_path, blocks):
    per_mode = defaultdict(Counter)
    pc_range = {}
    total = 0
    with open(raw_path, encoding="utf-8", errors="replace") as f:
        for line in f:
            m = VMOP_RE.search(line)
            if not m:
                continue
            mode, mval, pcval = int(m.group(1)), m.group(2), int(m.group(3))
            per_mode[mode][mval] += 1
            lo, hi = pc_range.get(mode, (pcval, pcval))
            pc_range[mode] = (min(lo, pcval), max(hi, pcval))
            total += 1
    result = {"total_instructions": total, "modes": {}}
    for i, (start, end, M, ARR, richness) in enumerate(blocks):
        c = per_mode.get(i, Counter())
        result["modes"][i] = {
            "opcode_var": M, "fetch_array": ARR, "static_richness": richness,
            "instructions_executed": sum(c.values()),
            "distinct_opcodes_hit": len(c),
            "pc_range": pc_range.get(i, None),
            "top_opcodes": c.most_common(15),
        }
    return result


def main():
    ap = argparse.ArgumentParser(description="v15 payload-VM dynamic opcode probe")
    ap.add_argument("sample")
    ap.add_argument("--luau", default="dynamic/luau")
    ap.add_argument("--deobf", default="dynamic/deobf_v15.py")
    ap.add_argument("--timeout", type=int, default=60)
    ap.add_argument("--workdir", default=None)
    ap.add_argument("--json")
    ap.add_argument("--md")
    args = ap.parse_args()

    workdir = args.workdir or tempfile.mkdtemp(prefix="v15probe_")
    raw_path, blocks = run_probe(args.sample, args.luau, args.deobf,
                                  args.timeout, workdir)
    result = summarize(raw_path, blocks)

    print(f"\n[v15-payload-probe] {args.sample}")
    print(f"  total instructions observed: {result['total_instructions']}")
    for i, info in sorted(result["modes"].items()):
        print(f"  mode {i} ({info['opcode_var']}={info['fetch_array']}[pc]): "
              f"{info['instructions_executed']} executed, "
              f"{info['distinct_opcodes_hit']} distinct opcodes, "
              f"pc_range={info['pc_range']}")
        for op, cnt in info["top_opcodes"][:8]:
            print(f"      op={op:<6} count={cnt}")

    if args.json:
        json.dump(result, open(args.json, "w"), indent=1)
        print(f"\n  -> {args.json}")
    if args.md:
        with open(args.md, "w") as f:
            f.write(f"# v15 payload-VM dynamic opcode probe — `{args.sample}`\n\n")
            f.write(f"- total instructions observed: **{result['total_instructions']}**\n")
            f.write(f"- dispatch modes found: **{len(result['modes'])}**\n\n")
            for i, info in sorted(result["modes"].items()):
                f.write(f"## mode {i} — `{info['opcode_var']}={info['fetch_array']}[pc]`\n\n")
                f.write(f"- instructions executed: **{info['instructions_executed']}**\n")
                f.write(f"- distinct opcodes hit: **{info['distinct_opcodes_hit']}**\n")
                f.write(f"- pc range visited: **{info['pc_range']}**\n\n")
                f.write("| opcode | count |\n|---|---|\n")
                for op, cnt in info["top_opcodes"]:
                    f.write(f"| {op} | {cnt} |\n")
                f.write("\n")
        print(f"  -> {args.md}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
