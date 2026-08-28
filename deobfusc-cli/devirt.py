#!/usr/bin/env python3
"""
devirt.py — Luraph v14.x devirtualizer (stage 2, runs after vm_decoder.py).

vm_decoder.py recovers the decompressed bytecode + the runnable VM interpreter
(`<workdir>/vm_interp.fixed.lua`). This stage goes further: it instruments the
VM's closure-builder F[38] to dump every function prototype the VM constructs —
opcode array, operand arrays, jump table, register count and the constant
strings each function references — then writes a human-readable report.

Note: Luraph v14.x randomizes opcode numbers per build and salts the dispatch
with opaque predicates, so a clean 1:1 Lua-source decompile is NOT produced.
What you get is the complete recovered program structure: every function, its
size/control-flow, and the API/strings it uses (the real signal of behaviour).

Usage: devirt.py <workdir-from-vm_decoder> [path/to/original.lua]
Outputs in <workdir>: protos.txt, DEVIRT_REPORT.md
"""
import sys, os, re, ast, subprocess, shutil

# ── F[38] closure-builder signature in the fixed VM ─────────────────────────
F38_NEEDLE = '(F)[38]=(function(e,z)local t,d,q,A,l,s,p,C,g,_=e[6]'
F38_PATCH  = '(F)[38]=(function(e,z) if rawget(_G,"__DP") then __DP(e) end local t,d,q,A,l,s,p,C,g,_=e[6]'

DUMP_HARNESS = r'''
do
  local out = assert(io.open("{OUT}", "w"))
  local pid = 0
  local function arr(a)
    if type(a) ~= "table" then return "null" end
    local parts, i, gap = {}, 0, 0
    while gap < 4 and i < 200000 do
      local v = a[i]
      if v == nil then gap = gap + 1
      else
        gap = 0
        local t = type(v)
        if t == "number" then parts[#parts+1] = (math.type(v)=="integer" and tostring(v) or string.format("%.14g", v))
        elseif t == "string" then parts[#parts+1] = string.format("%q", v)
        elseif t == "boolean" then parts[#parts+1] = tostring(v)
        else parts[#parts+1] = '"<'..t..'>"' end
      end
      i = i + 1
    end
    return "["..table.concat(parts, ",").."]"
  end
  __DP = function(e)
    pid = pid + 1
    out:write("=== PROTO #"..pid.."  sel="..tostring(e[1]).."  regcount="..tostring(e[6]).."\n")
    out:write("A="..arr(e[3]).."\nL="..arr(e[4]).."\nS="..arr(e[7])..
              "\nG="..arr(e[8]).."\nP="..arr(e[9]).."\nC="..arr(e[10]).."\n")
    out:flush()
  end
end
'''

API = {
    'http': {'GetAsync','PostAsync','RequestAsync','HttpGet','HttpGetAsync','JSONEncode','JSONDecode','GenerateGUID'},
    'gui':  {'UDim2','UDim','Vector2','Vector3','ScreenGui','Frame','TextLabel','TextButton','TextBox',
             'UIPadding','UIScale','UISizeConstraint','UICorner','UIGradient','UIStroke','UIListLayout',
             'Size','MaxSize','MinSize','Position','Rotation','AnchorPoint','AbsoluteSize',
             'AbsolutePosition','PaddingLeft','PaddingRight','PaddingTop','PaddingBottom'},
    'inst': {'Instance','new','Clone','Destroy','GetChildren','WaitForChild','GetService','GetDescendants',
             'FindFirstChild','IsA','ClassName','Name','Parent','Changed','Connect','Disconnect'},
    'meta': {'setmetatable','getmetatable','rawget','rawset','rawequal','rawlen','__index','__newindex'},
    'env':  {'setfenv','getfenv','loadstring','load','pcall','xpcall','error','assert','select','type','typeof'},
    'str':  {'sub','rep','format','gsub','match','gmatch','find','byte','char','concat','insert','unpack'},
}
def classify(s):
    for c, names in API.items():
        if s in names: return c
    return None

def dump_protos(work):
    fixed = os.path.join(work, 'vm_interp.fixed.lua')
    patched = os.path.join(work, 'patched.lua')
    if not (os.path.exists(fixed) and os.path.exists(patched)):
        print("[!] run vm_decoder.py first (need vm_interp.fixed.lua + patched.lua)"); sys.exit(2)
    with open(fixed, 'rb') as f: vm = f.read().decode('latin-1')
    if F38_NEEDLE not in vm:
        print("[!] F[38] closure-builder signature not found — VM variant mismatch"); sys.exit(3)
    dumpvm = os.path.join(work, 'vm_dump.lua')
    with open(dumpvm, 'wb') as f:
        f.write(vm.replace(F38_NEEDLE, F38_PATCH, 1).encode('latin-1', 'replace'))
    out = os.path.join(work, 'protos.txt')
    harness = DUMP_HARNESS.replace('{OUT}', out)
    # rebuild patched.lua to (a) load vm_dump.lua and (b) prepend the dump harness
    with open(patched, 'rb') as f: pat = f.read().decode('latin-1')
    pat = pat.replace('vm_interp.fixed.lua', 'vm_dump.lua')
    dpat = os.path.join(work, 'dump_patched.lua')
    with open(dpat, 'wb') as f:
        f.write((harness + pat).encode('latin-1', 'replace'))
    lua = next((b for b in ('lua5.4','lua5.3','lua') if shutil.which(b)), None)
    print(f"[*] dumping protos with {lua} ...")
    try: subprocess.run([lua, dpat], capture_output=True, timeout=90)
    except subprocess.TimeoutExpired: print("[*] payload loops (expected); protos already dumped")
    return out

def load(path):
    protos, cur = [], None
    for line in open(path, encoding='latin-1'):
        line = line.rstrip('\n')
        m = re.match(r'=== PROTO #(\d+)\s+sel=(\S+)\s+regcount=(\S+)', line)
        if m:
            cur = {'id': int(m.group(1)), 'sel': m.group(2), 'reg': m.group(3)}
            protos.append(cur)
        elif cur and len(line) > 2 and line[1] == '=':
            k, v = line[0], line[2:]
            try: cur[k] = ast.literal_eval(v)
            except Exception: cur[k] = []
    return protos

def report(work):
    path = os.path.join(work, 'protos.txt')
    protos = load(path)
    o = ["# Luraph Hub — Devirtualization Report", "",
         f"Recovered **{len(protos)} function prototypes** from the VM bytecode. Each is a",
         "real function; the strings are the constants it references (what it does).",
         "Luraph randomizes opcodes per build, so this is structure+intel, not clean source.", ""]
    allstr = {}
    for p in protos:
        for a in ('S', 'P'):
            for v in p.get(a, []):
                if isinstance(v, str) and re.search(r'[A-Za-z]', v):
                    allstr[v] = allstr.get(v, 0) + 1
    for p in protos:
        strs = []
        for a in ('S', 'P'):
            for v in p.get(a, []):
                if isinstance(v, str) and re.search(r'[A-Za-z]', v) and v not in strs: strs.append(v)
        cats = {}
        for s in strs:
            c = classify(s)
            if c: cats.setdefault(c, []).append(s)
        nop = len(p.get('A', []))
        njmp = sum(1 for c in p.get('C', []) if isinstance(c,(int,float)) and c)
        o.append(f"## Function #{p['id']} — {nop} instr, {p['reg']} regs, {njmp} jumps")
        for k, v in sorted(cats.items()):
            o.append(f"- **{k}:** {', '.join(sorted(set(v)))}")
        notable = [s for s in strs if classify(s) is None and (len(s) >= 4 or s.isupper())]
        if notable:
            o.append(f"- literals: {', '.join(repr(s) for s in notable[:25])}")
        o.append("")
    o.append("## Most-referenced strings")
    for s, n in sorted(allstr.items(), key=lambda kv: -kv[1])[:60]:
        o.append(f"- {n:3}x  {s!r}")
    rep = "\n".join(o)
    rp = os.path.join(work, 'DEVIRT_REPORT.md')
    with open(rp, 'w') as f: f.write(rep)
    print(f"[*] wrote {rp} ({len(protos)} functions)")

def main():
    if len(sys.argv) < 2:
        print("usage: devirt.py <workdir-from-vm_decoder>"); sys.exit(1)
    work = sys.argv[1]
    dump_protos(work)
    report(work)
    print("[done]", work)

if __name__ == '__main__':
    main()
