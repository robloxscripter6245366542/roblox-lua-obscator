#!/usr/bin/env python3
# Adapter: inject run_vm's fulldump/disasm probe directly into an INVERTED
# Luraph v14.7 build (the sample IS the VM interpreter and self-boots),
# wrap it in dynamic/run.py's stubbed env, run under luau.
import sys, os, subprocess
HERE="/home/user/roblox-lua-obscator/luraph-deobf"
sys.path.insert(0, os.path.join(HERE,"devirt"))
sys.path.insert(0, os.path.join(HERE,"dynamic"))
import run_vm, run as dynrun

sample=sys.argv[1]; mode=sys.argv[2]; nprotos=int(sys.argv[3]); outp=sys.argv[4]
luau=os.path.join(HERE,"dynamic","luau")
src=open(sample,encoding="utf-8",errors="replace").read()

anchor,(V,W,C,ops,rf),_=run_vm.find_dispatch(src)
args=",".join(f"{a}[{C}]" for a in ops); nargs=len(ops)
sys.stderr.write(f"[probe] V={V} W={W} C={C} ops={ops} rf={rf}\n")

if mode=="fulldump":
    arr=",".join(ops)
    probe=f'if not __seen[{W}] then __seen[{W}]=true; __dump({W},{arr}) end;'
    fields="".join(" ..' %s='..tostring(a%d[i])"%(chr(97+k),k) for k in range(nargs))
    params="W,"+",".join("a%d"%k for k in range(nargs))
    opdef=(
      "__seen=setmetatable({},{__mode='k'}) local NP=0\n"
      f"function __dump({params}) NP=NP+1 local n=#W\n"
      " print('[[P]] proto='..NP..' ninstr='..n)\n"
      f" for i=1,n do print('[[I]] p='..NP..' pc='..i..' op='..tostring(W[i]){fields}) end\n"
      f" if NP>={nprotos} then error('__enough__') end end\n")
else:  # disasm
    probe=f'__op({C},{V},{args});'
    params="C,V,"+",".join("o%d"%i for i in range(nargs))
    fields="".join(" ..' %s='..tostring(o%d)"%(chr(97+i),i) for i in range(nargs))
    opdef=(
      "local N=0\n"
      f"function __op({params}) N=N+1;"
      f" if N<={nprotos} then print('[[DIS]] pc='..C..' op='..V{fields}) end;"
      f" if N>500000 then error('__cap__') end end\n")

patched=src.replace(anchor, anchor+probe, 1)
assert patched!=src, "injection failed"

# Assemble: STUBS set up `env`; inject probe defs into env; run patched sample.
stubs=dynrun.STUBS.replace("__STRINGS__","").replace("__WAITBUDGET__","20000")
# define probe globals ON env (sample runs under setfenv(chunk, env))
opdef_env=opdef.replace("__seen","env.__seen").replace("function __dump","env.__dump=function") \
                .replace("function __op","env.__op=function")
# STUBS already ends by opening `local SRC = [====[`. Inject probe defs BEFORE it.
marker="local SRC = [====["
assert marker in stubs
stubs=stubs.replace(marker, opdef_env+"log('probe-ready')\n"+marker, 1)
harness=stubs+patched+dynrun.RUNNER
open(outp,"w",encoding="utf-8").write(harness)
sys.stderr.write(f"[probe] harness {len(harness)} bytes -> {outp}\n")
# run
r=subprocess.run(["timeout","90","stdbuf","-oL",luau,outp])
sys.exit(0)
