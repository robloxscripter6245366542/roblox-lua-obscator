#!/usr/bin/env python3
# ============================================================
#  v15_payload_watch.py  --  long, low-overhead run watching for specific
#  events in v15's payload VM, instead of logging every instruction
#
#  v15_payload_probe.py's per-instruction print is what makes a truly long
#  run impractical (huge log files, heavy print overhead slowing the run
#  itself). This does the opposite: inject a probe that stays silent except
#  for sparse progress lines and the exact events under investigation --
#  letting a run push far more real instructions into the same wall-clock
#  budget, to answer "does this ever happen given enough time" rather than
#  "what happened in the first N instructions."
#
#  Default watch (tuned to the open question in v15.md's "Payload recovery
#  harness" section): does mode 2 (the hot, non-terminating loop) ever fire
#  its RETURN opcodes, or do any of a given set of registers ever stop
#  being nil. Both are configurable for reuse on a different sample/finding.
#
#  Usage:
#    python3 devirt/v15_payload_watch.py sample_v15.lua \
#        --luau dynamic/luau --deobf dynamic/deobf_v15.py \
#        --mode 2 --watch-opcodes 33,41 --watch-registers 36,105 \
#        --timeout 480
# ============================================================

import argparse
import os
import re
import subprocess
import sys
import tempfile

from v15_payload_probe import find_vm_groups, pick_payload_vm

WATCH_TAG = "[[VMWATCH]]"


def build_watch_probe(mode_idx, m_var, pc_var, opcodes, registers, progress_every):
    opcode_checks = "".join(
        f'if not __seen_op["{mode_idx}:{op}"] and {m_var}=={op} then __seen_op["{mode_idx}:{op}"]=true '
        f'print("{WATCH_TAG} mode={mode_idx} OPCODE {op} FIRED at pc="..tostring({pc_var}).." n="..__n) end '
        for op in opcodes
    )
    reg_checks = "".join(
        f'if not __seen_reg[{reg}] and R[{reg}]~=nil then __seen_reg[{reg}]=true '
        f'print("{WATCH_TAG} mode={mode_idx} REGISTER {reg} WRITTEN value="..tostring(R[{reg}]).." at pc="'
        f'..tostring({pc_var}).." n="..__n) end '
        for reg in registers
    )
    return (
        "__n=(__n or 0)+1 "
        "__seen_op=__seen_op or {} __seen_reg=__seen_reg or {} "
        f"{opcode_checks}{reg_checks}"
        f"if __n%{progress_every}==0 then "
        f'print("{WATCH_TAG} progress n="..__n.." mode={mode_idx} pc="..tostring({pc_var})) end;'
    )


def main():
    ap = argparse.ArgumentParser(description="v15 payload-VM long low-overhead event watch")
    ap.add_argument("sample")
    ap.add_argument("--luau", default="dynamic/luau")
    ap.add_argument("--deobf", default="dynamic/deobf_v15.py")
    ap.add_argument("--mode", type=int, default=None,
                    help="which dispatch block (0-based) to watch; omit to watch ALL blocks "
                         "at once (self-modifying arrays mean an opcode/register dead in one "
                         "mode's role could still surface via another)")
    ap.add_argument("--watch-opcodes", default="",
                    help="comma-separated opcode values to watch for (report first firing)")
    ap.add_argument("--watch-registers", default="",
                    help="comma-separated register numbers to watch (report first non-nil write)")
    ap.add_argument("--progress-every", type=int, default=20_000_000)
    ap.add_argument("--timeout", type=int, default=480)
    ap.add_argument("--workdir", default=None)
    args = ap.parse_args()

    opcodes = [int(x) for x in args.watch_opcodes.split(",") if x]
    registers = [int(x) for x in args.watch_registers.split(",") if x]
    if not opcodes and not registers:
        sys.exit("!! nothing to watch -- pass --watch-opcodes and/or --watch-registers")

    src = open(args.sample, encoding="utf-8", errors="replace").read()
    groups = find_vm_groups(src)
    pc_var = pick_payload_vm(groups)
    blocks = groups[pc_var]
    target_modes = [args.mode] if args.mode is not None else list(range(len(blocks)))
    for i in target_modes:
        start, end, M, ARR, richness = blocks[i]
        print(f"[v15-payload-watch] mode {i} ({M}={ARR}[{pc_var}]): "
              f"watching opcodes={opcodes} registers={registers}, timeout={args.timeout}s")

    patched = src
    for i in sorted(target_modes, reverse=True):
        start, end, M, ARR, richness = blocks[i]
        probe = build_watch_probe(i, M, pc_var, opcodes, registers, args.progress_every)
        patched = patched[:end] + probe + patched[end:]

    workdir = args.workdir or tempfile.mkdtemp(prefix="v15watch_")
    os.makedirs(workdir, exist_ok=True)
    instrumented = os.path.join(workdir, "watchprobe_" + os.path.basename(args.sample))
    out_prefix = os.path.join(workdir, "watch_run")
    open(instrumented, "w", encoding="utf-8").write(patched)

    cmd = [sys.executable, args.deobf, instrumented, "--luau", args.luau,
           "--timeout", str(args.timeout), "--out", out_prefix]
    print(f"[v15-payload-watch] running (this can take up to {args.timeout}s)...")
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

    print(f"\n[v15-payload-watch] {args.sample}")
    print(f"  last progress: {last_progress}")
    if events:
        print(f"  {len(events)} watched event(s) fired:")
        for e in events:
            print(f"    {e}")
    else:
        print("  no watched event fired within the time budget")
    return 0


if __name__ == "__main__":
    sys.exit(main())
