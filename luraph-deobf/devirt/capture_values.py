#!/usr/bin/env python3
# ============================================================
#  capture_values.py  --  concrete constant/value capture for the lifter
#
#  Constant inlining without fully reversing the constant-table indexing:
#  instead of decoding how a LOADK operand maps to the constant pool, we
#  simply OBSERVE the value each instruction actually produces, keyed by
#  (proto, pc). lift.py --values then inlines those literals in place of the
#  K(i) placeholders.
#
#  Mechanism: run the VM; number protos by first entry (identically to
#  run_vm.py --mode fulldump, so keys align); at each dispatch step read the
#  destination register the PREVIOUS instruction wrote (its dst operand,
#  looked up from opcodes.full.json) and emit
#      [[V]] p=<proto> pc=<pc> v=<serialised value>
#  Only value-producing ops (known dst) are recorded.
#
#  Requires a luau binary + opcodes.full.json. Reuses run_vm's harness.
#
#  Usage:
#    python3 capture_values.py --vmdir peeled --luau ./luau \
#            --map opcodes.full.json --steps 60000 --out values.txt
# ============================================================

import argparse
import base64
import json
import os
import subprocess
import sys

import run_vm


def build(vm_src, bytecode, dstmap, steps):
    disp = run_vm.find_dispatch(vm_src)
    if not disp:
        sys.exit("!! dispatch not found")
    anchor, (V, W, C, operand_arrays, regfile), _ = disp
    arr = ",".join(f"{a}[{C}]" for a in operand_arrays)
    # probe: pass the proto's opcode-array identity W (for numbering), pc, op,
    # operands and the register file to __step (which owns all bookkeeping so
    # nothing is referenced from the VM chunk's env except __step itself).
    patched = vm_src.replace(
        anchor, anchor + f'__step({W},{C},{V},{arr},{regfile});', 1)
    if patched == vm_src:
        sys.exit("!! probe injection failed")

    nargs = len(operand_arrays)
    onames = ",".join("o%d" % k for k in range(nargs))
    params = "Wt,C,V," + onames + ",e"
    ops_tbl = "{" + onames + "}"
    # dst operand letter per opcode -> index in operand list (a=0,b=1,c=2,d=3)
    dst_lua = "{" + ",".join(
        f"[{op}]={ 'abcd'.index(d)+1 }" for op, d in dstmap.items() if d in "abcd"
    ) + "}"
    opnames = "{" + ",".join(f'[{op}]="%s"' % nm for op, nm in DSTNAMES.items()) + "}"

    op_body = f'''
local __pn=setmetatable({{}},{{__mode="k"}}) local __np=0
local __dst={dst_lua}      -- op -> which operand (1..4) is the destination reg
local __ops={opnames}
local __lp,__lpc,__ldstreg,__lop
local function vstr(x) local t=type(x)
  if t=="number" then return tostring(x)
  elseif t=="string" then
    -- Emit a string literal valid in Lua 5.1/5.4 and Luau alike.  `%q`
    -- escaping varies between runtimes and produces literals luac5.4
    -- rejects for binary constants, so quote every non-safe byte with a
    -- zero-padded \ddd decimal escape (unambiguous under 5.4's greedy
    -- 3-digit escape scan).
    local o={{'"'}}
    for i=1,#x do local by=string.byte(x,i)
      if by==34 then o[#o+1]='\\"'
      elseif by==92 then o[#o+1]='\\\\'
      elseif by>=32 and by<=126 then o[#o+1]=string.char(by)
      else o[#o+1]=string.format("\\%03d",by) end end
    o[#o+1]='"'
    return table.concat(o)
  elseif t=="boolean" then return tostring(x)
  else return nil end end
local __N=0
env.__step=function({params})
  __N=__N+1
  local ops={ops_tbl}
  -- resolve this proto's number by opcode-array identity
  local P=__pn[Wt]; if not P then __np=__np+1; __pn[Wt]=__np; P=__np end
  -- the previous instruction has now executed: read the register it wrote
  if __lp~=nil and __ldstreg~=nil then
    local val=vstr(e[__ldstreg])
    if val~=nil then print("[[V]] p="..__lp.." pc="..__lpc.." op="..__lop.." v="..val) end
  end
  local di=__dst[V]
  if di~=nil then __ldstreg=ops[di]; __lp=P; __lpc=C; __lop=V else __ldstreg=nil end
  if __N>{steps} then error("__cap__") end
end
env.__op=function() end
env.__fin=function() end'''

    b64 = base64.b64encode(bytecode).decode()
    return (run_vm.HARNESS.replace("__OP_BODY__", op_body)
            .replace("__B64__", b64).replace("__VMSRC__", patched))


DSTNAMES = {}


def main():
    ap = argparse.ArgumentParser(description="capture concrete per-(proto,pc) values")
    ap.add_argument("--vmdir", default="peeled")
    ap.add_argument("--luau", default="./luau")
    ap.add_argument("--map", default="opcodes.full.json")
    ap.add_argument("--steps", type=int, default=60000)
    ap.add_argument("--timeout", type=int, default=120)
    ap.add_argument("--out", default="values.txt")
    args = ap.parse_args()

    opmap = json.load(open(args.map))
    dstmap = {}
    for op, e in opmap.items():
        if op.startswith("_") or not isinstance(e, dict):
            continue
        if e.get("dst"):
            dstmap[op] = e["dst"]
        DSTNAMES[op] = e.get("name", "op?")

    vm_src = open(os.path.join(args.vmdir, "stage_0.lua"), errors="replace").read()
    bytecode = open(os.path.join(args.vmdir, "stage_1.bin"), "rb").read()
    harness = build(vm_src, bytecode, dstmap, args.steps)
    with open("val_harness.luau", "w") as f:
        f.write(harness)
    with open(args.out, "w") as outf:
        try:
            subprocess.run(["timeout", str(args.timeout), "stdbuf", "-oL",
                            args.luau, "val_harness.luau"], stdout=outf,
                           stderr=subprocess.STDOUT, check=False)
        except FileNotFoundError:
            sys.exit("!! luau not found; build via ../dynamic/build_luau.sh")
    n = sum(1 for l in open(args.out, errors="replace") if l.startswith("[[V]]"))
    print(f"[capture_values] {n} concrete values -> {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
