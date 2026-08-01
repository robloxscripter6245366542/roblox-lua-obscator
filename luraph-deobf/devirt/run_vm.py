#!/usr/bin/env python3
# ============================================================
#  run_vm.py  --  drive the recovered Luraph VM + instrument its dispatch
#
#  This is the engine of the devirtualiser. It takes a peel output dir
#  (stage_0.lua = VM interpreter source, stage_1.bin = decompressed
#  bytecode), generates a self-contained Luau harness that:
#
#    * stubs the Roblox/executor environment (network blocked),
#    * embeds the bytecode as base64 and rebuilds the buffer,
#    * compiles the VM source and runs it over the bytecode
#      (replicating the bootstrap's Vfn(buffer) then callable-table call),
#    * INJECTS a probe at the VM's dispatch point so every executed
#      instruction is reported: opcode + the four operand fields.
#
#  It auto-detects the (build-specific) dispatch variables. The v14.7
#  dispatch looks like:
#
#      repeat local V=W[C]; if V<148 then ... e[j[C]] ... C=c[C] ...
#
#  i.e. a register VM: W[C]=opcode, C=pc, e[]=registers, and the operand
#  fields live in parallel arrays indexed by C (j/q/U/c on this build).
#
#  Modes:
#    --mode disasm  dump the first N executed instructions w/ operands
#    --mode freq    opcode frequency histogram over the whole run
#    --mode trace   pc/op stream (for control-flow reconstruction)
#
#  Requires a luau binary (see ../dynamic/build_luau.sh).
#
#  Usage:
#    python3 run_vm.py --vmdir ../dynamic/peeled --luau ./luau --mode disasm
# ============================================================

import argparse
import base64
import os
import re
import subprocess
import sys

# ---- auto-detect the dispatch signature in the VM source ----------------

def find_dispatch(vm_src):
    """Locate the VM dispatch loop generically across Luraph v14.7 builds.

    Builds vary the loop keyword (`repeat` vs `while true do`), the variable
    names, and what follows the opcode fetch (an anti-tamper check may sit
    before the opcode comparisons). We therefore match any
        (repeat | while true do) local <V> = ( <W>[<C>] )
    whose fetched var <V> then drives a binary-search comparison tree, pick
    the one with the most comparisons (the real dispatch), and auto-detect:
      * operand arrays  = tables indexed by the pc var <C>
      * register file   = the first local initialised from a `x[n](...)` call
    Returns (anchor, (V, W, C, operand_arrays, regfile), None) or None.

    `anchor` is the exact matched text; inject a probe by inserting right
    after it.
    """
    # The dispatch is the OUTERMOST loop of the BIGGEST function (the VM core).
    # Scope the search there to avoid matching flattened handler loops.
    fns = [(mm.start(), mm.group(1))
           for mm in re.finditer(r'([A-Za-z_]\w*)=function\(', vm_src)]
    spans = sorted(((fns[i + 1][0] - p if i + 1 < len(fns) else len(vm_src) - p), p)
                   for i, (p, _) in enumerate(fns)) if fns else []
    search_regions = []
    if spans:
        _, big = spans[-1]
        end = min((p for p, _ in fns if p > big), default=len(vm_src))
        search_regions.append((big, vm_src[big:end]))
    search_regions.append((0, vm_src))   # fallback: whole file

    best = None
    for base, hay in search_regions:
        for m in re.finditer(
                r'(?:repeat|while true do)\s*local (\w+)\s*=\s*\(?(\w+)\[(\w+)\]\)?\s*;',
                hay):
            V, W, C = m.group(1), m.group(2), m.group(3)
            region = hay[m.end(): m.end() + 9000]
            cmps = (len(re.findall(r'\b' + re.escape(V) + r'\s*[<>=~]', region))
                    + len(re.findall(r'not\(\s*' + re.escape(V), region)))
            if cmps < 3:
                continue
            ops = []
            for om in re.finditer(r'(\w+)\[' + re.escape(C) + r'\]', region):
                nm = om.group(1)
                if nm != W and nm not in ops:
                    ops.append(nm)
            # first (outermost) qualifying loop in the biggest function wins
            best = (m.group(0), V, W, C, base + m.end(), ops[:4])
            break
        if best:
            break
    if not best:
        return None
    anchor, V, W, C, endpos, operand_arrays = best
    # register file: first local in this function assigned from a call like
    # `<name> = <tbl>[<n>](<arg>)`. Search backfrom the loop to the enclosing
    # `function(` and grab the first such initialiser.
    fn_start = vm_src.rfind("function(", 0, endpos)
    head = vm_src[fn_start: endpos]
    rf = re.search(r'local (\w+)[\w,]*=\s*\w+\[\d+\]\(', head)
    regfile = rf.group(1) if rf else "e"
    return anchor, (V, W, C, operand_arrays, regfile), None


PROBE_TMPL = ('repeat local {V}={W}[{C}];__op({C},{V},{args});'
              'if {V}')


def build_harness(vm_src, bytecode, mode, cap, dis_n):
    disp = find_dispatch(vm_src)
    if not disp:
        sys.exit("!! could not locate the dispatch loop in the VM source")
    anchor, (V, W, C, operand_arrays, regfile), _ = disp
    args = ",".join(f"{a}[{C}]" for a in operand_arrays) or "nil"
    nargs = len(operand_arrays)

    def inject(call):
        """Insert probe code immediately after the dispatch fetch (anchor)."""
        patched = vm_src.replace(anchor, anchor + call, 1)
        if patched == vm_src:
            sys.exit("!! probe injection failed (anchor not found)")
        return patched

    if mode == "fulldump":
        # dump the COMPLETE instruction array of every proto on first entry
        # (all instructions, not just executed ones) -> input for lift.py
        arr = ",".join(operand_arrays)
        patched = inject(
            f'if not __seen[{W}] then __seen[{W}]=true; __dump({W},{arr}) end;')
        fields = "".join(" ..' %s='..tostring(a%d[i])" % (chr(97+k), k) for k in range(nargs))
        params = "W," + ",".join("a%d" % k for k in range(nargs))
        op_body = (
            "env.__seen=setmetatable({},{__mode='k'}) local NP=0\n"
            f"env.__dump=function({params}) NP=NP+1 local n=#W\n"
            " print('[[P]] proto='..NP..' ninstr='..n)\n"
            " for i=1,n do print('[[I]] p='..NP..' pc='..i..' op='..tostring(W[i])"
            f"{fields}) end\n"
            f" if NP>={dis_n} then error('__enough__') end end\n"
            "env.__op=function() end\nenv.__fin=function() end")
        b64 = base64.b64encode(bytecode).decode()
        return (HARNESS.replace("__OP_BODY__", op_body).replace("__B64__", b64)
                .replace("__VMSRC__", patched))

    # all other modes: insert an __op(pc, op, operands...) call after the fetch
    patched = inject(f'__op({C},{V},{args});')

    if mode == "cf":
        # control-flow census: per opcode, sequential (next==pc+1) vs jump.
        # Emits [[CF]] lines that build_map.py consumes (write to cf.json).
        op_body = (
            "local seq={} local jmp={} local tot={} local lop,lpc local N=0\n"
            "env.__op=function(C,V) N=N+1\n"
            " if lop~=nil then tot[lop]=(tot[lop] or 0)+1\n"
            "  if C==lpc+1 then seq[lop]=(seq[lop] or 0)+1 else jmp[lop]=(jmp[lop] or 0)+1 end end\n"
            " lop=V lpc=C\n"
            f" if N>{cap} then error('__cap__') end end\n"
            "env.__fin=function() local a={} for k in pairs(tot) do a[#a+1]=k end table.sort(a)\n"
            " print('[[CF]] distinct='..#a)\n"
            " for _,op in ipairs(a) do print('[[CF]] op='..op..' seq='..(seq[op] or 0)..' jmp='..(jmp[op] or 0)) end end")
    elif mode == "freq":
        op_body = (
            "local F={} local N=0\n"
            "env.__op=function(C,V) N=N+1; F[V]=(F[V] or 0)+1;"
            f" if N>{cap} then error('__cap__') end end\n"
            "env.__fin=function() local a={} for k,v in pairs(F) do a[#a+1]={k,v} end\n"
            " table.sort(a,function(x,y) return x[2]>y[2] end)\n"
            " print('[[FREQ]] distinct='..#a..' total='..N)\n"
            " for i=1,#a do print('[[FREQ]] op='..a[i][1]..' count='..a[i][2]) end end")
    elif mode == "trace":
        op_body = (
            "local N=0\n"
            "env.__op=function(C,V) N=N+1;"
            f" if N<={dis_n} then print('[[TRACE]] '..C..' '..V) end;"
            f" if N>{cap} then error('__cap__') end end\n"
            "env.__fin=function() end")
    else:  # disasm
        params = "C,V," + ",".join(["o%d" % i for i in range(nargs)]) if nargs else "C,V"
        fields = "".join([" ..' %s='..tostring(o%d)" % (chr(97+i), i) for i in range(nargs)])
        op_body = (
            "local N=0\n"
            f"env.__op=function({params}) N=N+1;"
            f" if N<={dis_n} then print('[[DIS]] pc='..C..' op='..V{fields}) end;"
            f" if N>{cap} then error('__cap__') end end\n"
            "env.__fin=function() end")

    b64 = base64.b64encode(bytecode).decode()
    return HARNESS.replace("__OP_BODY__", op_body).replace("__B64__", b64) \
                  .replace("__VMSRC__", patched)


HARNESS = r'''
local realLoadstring = loadstring
local realG = getfenv(1)
local function b64dec(data)
  local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  local t={} for i=1,#b do t[b:sub(i,i)]=i-1 end
  data=data:gsub('[^%w+/]','')
  local out={}
  for i=1,#data,4 do
    local c1=t[data:sub(i,i)] or 0 local c2=t[data:sub(i+1,i+1)] or 0
    local c3=t[data:sub(i+2,i+2)] local c4=t[data:sub(i+3,i+3)]
    local n=c1*262144+c2*4096+(c3 or 0)*64+(c4 or 0)
    out[#out+1]=string.char(math.floor(n/65536)%256)
    if c3~=nil then out[#out+1]=string.char(math.floor(n/256)%256) end
    if c4~=nil then out[#out+1]=string.char(n%256) end
  end
  return table.concat(out)
end
local env={}
local instMT local function inst() return setmetatable({},instMT) end
instMT={__index=function() return inst() end,__newindex=function() end,__call=function() return inst() end,
 __concat=function() return "" end,__tostring=function() return "" end,__add=function() return inst() end,
 __sub=function() return inst() end,__mul=function() return inst() end,__div=function() return inst() end,
 __unm=function() return inst() end,__len=function() return 0 end,__eq=function() return false end,
 __lt=function() return false end,__le=function() return false end}
local rec rec=setmetatable({},{__index=function() return rec end,__newindex=function() end,__call=function() return rec end,__concat=function() return "" end,__tostring=function() return "" end})
env.__rec=rec
env.loadstring=function(s,cn) local f,e=realLoadstring(s,cn); if f then pcall(setfenv,f,env) end; return f,e end
env.load=env.loadstring
env.game=setmetatable({HttpGet=function() return "return __rec" end,HttpGetAsync=function() return "return __rec" end,GetService=function() return inst() end,GetObjects=function() return {} end},{__index=function() return function() return inst() end end,__newindex=function() end})
env.workspace=inst() env.getgenv=function() return env end
env.identifyexecutor=function() return "h","1" end env.getexecutorname=env.identifyexecutor
env.tick=function() return 0 end env.time=env.tick
env.task={wait=function() error("__stop__") end,spawn=function() end,defer=function() end,delay=function() end}
env.wait=function() error("__stop__") end
env.unpack=table.unpack env.shared={} env._G=env
for _,n in ipairs({"Instance","Vector3","Vector2","Color3","UDim","UDim2","CFrame","Rect","Region3","Ray","TweenInfo","NumberSequence","ColorSequence","NumberRange","BrickColor","Random","Font","Drawing","DateTime","Enum","OverlapParams","RaycastParams","Path2D","Path2DControlPoint"}) do env[n]=inst() end
setmetatable(env,{__index=function(_,k) return realG[k] end})
env.print=print
__OP_BODY__
local VMSRC=[=====[
__VMSRC__]=====]
local Vfn=assert(env.loadstring(VMSRC,"Luraph  "))
local buf=buffer.fromstring(b64dec("__B64__"))
print("[[H]] bytecode="..buffer.len(buf))
local ok,res=pcall(Vfn,buf)
if not ok then print("[[H]] Vfn-err "..tostring(res):sub(1,120)) end
if ok and res~=nil then pcall(function() return (res)() end) end
if env.__fin then env.__fin() end
print("[[H]] done")
'''


def main():
    ap = argparse.ArgumentParser(description="drive + instrument the recovered Luraph VM")
    ap.add_argument("--vmdir", default="../dynamic/peeled",
                    help="dir with stage_0.lua (VM src) + stage_1.bin (bytecode)")
    ap.add_argument("--luau", default="./luau")
    ap.add_argument("--mode", choices=["disasm", "freq", "trace", "cf", "fulldump"], default="disasm")
    ap.add_argument("--cap", type=int, default=3000000, help="max instructions to run")
    ap.add_argument("--n", type=int, default=200, help="how many to print (disasm/trace)")
    ap.add_argument("--timeout", type=int, default=90)
    ap.add_argument("--out", default="vm_out.txt")
    args = ap.parse_args()

    vm_path = os.path.join(args.vmdir, "stage_0.lua")
    bc_path = os.path.join(args.vmdir, "stage_1.bin")
    if not (os.path.exists(vm_path) and os.path.exists(bc_path)):
        sys.exit(f"!! need {vm_path} and {bc_path} (run peel.py first)")
    vm_src = open(vm_path, "r", encoding="utf-8", errors="replace").read()
    bytecode = open(bc_path, "rb").read()

    harness = build_harness(vm_src, bytecode, args.mode, args.cap, args.n)
    with open("vm_harness.luau", "w", encoding="utf-8") as f:
        f.write(harness)

    with open(args.out, "w", encoding="utf-8") as outf:
        try:
            subprocess.run(["timeout", str(args.timeout), "stdbuf", "-oL",
                            args.luau, "vm_harness.luau"], stdout=outf,
                           stderr=subprocess.STDOUT, check=False)
        except FileNotFoundError:
            sys.exit("!! luau not found; build it: bash ../dynamic/build_luau.sh")

    tags = {"disasm": ("[[DIS]]",), "freq": ("[[FREQ]]",), "trace": ("[[TRACE]]",),
            "cf": ("[[CF]]",), "fulldump": ("[[P]]", "[[I]]")}[args.mode]
    for line in open(args.out, errors="replace"):
        if line.startswith(tags) or line.startswith("[[H]]"):
            sys.stdout.write(line)
    return 0


if __name__ == "__main__":
    sys.exit(main())
