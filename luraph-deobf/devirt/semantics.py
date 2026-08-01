#!/usr/bin/env python3
# ============================================================
#  semantics.py  --  recover opcode semantics by register-delta analysis
#
#  Reading 120 obfuscated handler leaves in func `o` by eye is slow and
#  error-prone. Instead we recover semantics from GROUND TRUTH: run the VM,
#  snapshot the register file `e[]` at every step, and diff consecutive
#  snapshots. The change between step k-1 and step k is exactly the effect
#  of the instruction executed at step k-1, so we attribute each register
#  write (destination + value type) to its opcode and aggregate.
#
#  This sidesteps the obfuscation entirely: we never have to understand the
#  handler code, only observe what it does to registers. Tables are given
#  stable ids so table->table writes (GETTABLE/MOVE) are visible.
#
#  Output: per-opcode summary (how many operands change which register, the
#  value types produced, and a concrete example) + a proposed classification.
#
#  Requires a luau binary. Reuses run_vm.py's harness + dispatch detection.
#
#  Usage:
#     python3 semantics.py --vmdir peeled --luau ./luau --steps 1500
# ============================================================

import argparse
import base64
import os
import re
import subprocess
import sys
from collections import defaultdict

import run_vm   # reuse HARNESS + find_dispatch

SNAP_MAX_REG = 260


def build_harness(vm_src, bytecode, steps):
    disp = run_vm.find_dispatch(vm_src)
    if not disp:
        sys.exit("!! could not locate dispatch loop")
    anchor, (V, W, C, operand_arrays, regfile), _ = disp
    args = ",".join(f"{a}[{C}]" for a in operand_arrays) or "nil"
    patched = vm_src.replace(anchor, anchor + f'__op({C},{V},{args},{regfile});', 1)
    if patched == vm_src:
        sys.exit("!! probe injection failed")

    nargs = len(operand_arrays)
    params = "C,V," + ",".join("o%d" % i for i in range(nargs)) + ",e"
    op_fields = "".join(" ..' %s='..tostring(o%d)" % (chr(97+i), i) for i in range(nargs))
    op_body = f'''
local __tid=setmetatable({{}},{{__mode="k"}}) local __n=0
local function vstr(x) local t=type(x)
  if t=="number" then return "n:"..tostring(x)
  elseif t=="string" then return "s:"..string.format("%q",x:sub(1,24))
  elseif t=="boolean" then return "b:"..tostring(x)
  elseif t=="table" then local id=__tid[x]; if not id then __n=__n+1; __tid[x]=__n; id=__n end; return "t#"..id
  elseif t=="function" then return "f" else return t end end
local __N=0
env.__op=function({params}) __N=__N+1
  if __N<={steps} then
    local snap={{}}
    for i=0,{SNAP_MAX_REG} do local x=e[i]; if x~=nil then snap[#snap+1]=i..":"..vstr(x) end end
    print("[[S]] s="..__N.." pc="..C.." op="..V{op_fields}.." E="..table.concat(snap,","))
  end
  if __N>{steps}+40 then error("__cap__") end
end
env.__fin=function() end'''

    b64 = base64.b64encode(bytecode).decode()
    return (run_vm.HARNESS.replace("__OP_BODY__", op_body)
            .replace("__B64__", b64).replace("__VMSRC__", patched)), nargs


LINE_RE = re.compile(
    r'\[\[S\]\] s=(\d+) pc=(\S+) op=(\S+)((?: [a-d]=\S+)*) E=(.*)')


def parse_steps(path):
    steps = []
    for l in open(path, errors="replace"):
        if not l.startswith("[[S]]"):
            continue
        m = LINE_RE.match(l.rstrip())
        if not m:
            continue
        _, pc, op, ops, E = m.groups()
        operands = dict(re.findall(r'([a-d])=(\S+)', ops))
        regs = {}
        if E:
            for kv in E.split(","):
                if ":" in kv:
                    idx, val = kv.split(":", 1)
                    try:
                        regs[int(idx)] = val
                    except ValueError:
                        pass
        steps.append(dict(pc=pc, op=int(op), operands=operands, regs=regs))
    return steps


def role_of(operands, idx):
    for r in ("a", "b", "c", "d"):
        v = operands.get(r)
        if v and v.lstrip("-").isdigit() and int(v) == idx:
            return r
    return "?"


def classify(stat):
    """Heuristic label from the observed write pattern + value types."""
    n = stat["n"]
    writes0 = stat["writes"].get(0, 0)
    vt = stat["vtype"]
    dominant_vt = max(vt, key=vt.get) if vt else None
    # mostly no register write -> table store or control flow
    if writes0 >= n * 0.8:
        return "SETTABLE / control-flow (no register write)"
    if dominant_vt == "t":
        # new table vs read-from-table
        return "NEWTABLE / GETTABLE (writes a table into a register)"
    if dominant_vt == "f":
        return "GETTABLE / CLOSURE (writes a function into a register)"
    if dominant_vt == "n":
        return "LOADK-number / arithmetic (writes a number)"
    if dominant_vt == "s":
        return "LOADK-string (writes a string constant)"
    if dominant_vt == "b":
        return "comparison (writes a boolean)"
    return "mixed"


def main():
    ap = argparse.ArgumentParser(description="recover Luraph opcode semantics")
    ap.add_argument("--vmdir", default="peeled")
    ap.add_argument("--luau", default="./luau")
    ap.add_argument("--steps", type=int, default=1500)
    ap.add_argument("--timeout", type=int, default=90)
    ap.add_argument("--top", type=int, default=40)
    ap.add_argument("--out", default="sem_out.txt")
    args = ap.parse_args()

    vm_src = open(os.path.join(args.vmdir, "stage_0.lua"), errors="replace").read()
    bytecode = open(os.path.join(args.vmdir, "stage_1.bin"), "rb").read()
    harness, nargs = build_harness(vm_src, bytecode, args.steps)
    with open("sem_harness.luau", "w") as f:
        f.write(harness)
    with open(args.out, "w") as outf:
        try:
            subprocess.run(["timeout", str(args.timeout), "stdbuf", "-oL",
                            args.luau, "sem_harness.luau"], stdout=outf,
                           stderr=subprocess.STDOUT, check=False)
        except FileNotFoundError:
            sys.exit("!! luau not found; build via ../dynamic/build_luau.sh")

    steps = parse_steps(args.out)
    stat = defaultdict(lambda: dict(n=0, writes=defaultdict(int),
                                    dst=defaultdict(int), vtype=defaultdict(int),
                                    ex=[]))
    for k in range(1, len(steps)):
        prev, cur = steps[k-1], steps[k]
        changed = {i: (prev["regs"].get(i), v) for i, v in cur["regs"].items()
                   if prev["regs"].get(i) != v}
        s = stat[prev["op"]]
        s["n"] += 1
        s["writes"][len(changed)] += 1
        for idx, (old, new) in changed.items():
            s["dst"][role_of(prev["operands"], idx)] += 1
            if new:
                s["vtype"][new.split(":")[0].split("#")[0]] += 1
        if changed and len(s["ex"]) < 1:
            chs = ", ".join(f"e[{i}]:{o}->{nw}" for i, (o, nw) in list(changed.items())[:3])
            s["ex"].append(f"{dict(prev['operands'])} => {chs}")

    print(f"# opcode semantics (register-delta over {len(steps)} steps)\n")
    print(f"{'op':>4} {'n':>5}  {'class':<48} example")
    for op in sorted(stat, key=lambda o: -stat[o]["n"])[:args.top]:
        s = stat[op]
        print(f"{op:>4} {s['n']:>5}  {classify(s):<48} {s['ex'][0] if s['ex'] else ''}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
