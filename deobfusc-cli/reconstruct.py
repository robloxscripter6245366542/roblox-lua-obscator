#!/usr/bin/env python3
"""
reconstruct.py — behavioral reconstruction tool.

Keeps the obfuscator intact, runs the script inside an instrumented Roblox
environment (trace_env.lua) that LOGS every observable action, then regenerates
clean, readable Lua that reproduces what the script actually did:
Instance.new, property assignments, parenting, event connections, HTTP calls.

Honest scope: reconstructs what *executes* during the trace. Paths gated behind
a key-check or a non-yielding busy-loop won't run, so coverage is bounded by how
far the script gets headlessly — but everything it builds comes out as clean Lua.

Usage: reconstruct.py <workdir-from-vm_decoder> [original.lua]
Outputs: <workdir>/trace.txt  and  <workdir>/reconstructed.lua
"""
import sys, os, re, subprocess, shutil

HERE = os.path.dirname(os.path.abspath(__file__))
SHIMS = r'''
if not unpack then unpack=table.unpack end
if not string.pack then string.pack=function(fmt,n) if fmt==">I4" then n=math.floor(n)%4294967296
  return string.char(math.floor(n/16777216)%256,math.floor(n/65536)%256,math.floor(n/256)%256,n%256) end error("pack") end end
if not bit32 then local function _i(v) if type(v)=='boolean' then return v and 1 or 0 end
  if type(v)=='number' then return math.tointeger(v) or (v>=0 and math.floor(v) or math.ceil(v)) end return 0 end
  bit32={band=function(...) local r=0xFFFFFFFF for _,v in ipairs({...}) do r=r&_i(v) end return r end,
  bor=function(...) local r=0 for _,v in ipairs({...}) do r=r|_i(v) end return r end,
  bxor=function(...) local r=0 for _,v in ipairs({...}) do r=r~_i(v) end return r end,
  bnot=function(a) return (~_i(a))&0xFFFFFFFF end,lshift=function(a,b) return (_i(a)<<_i(b))&0xFFFFFFFF end,
  rshift=function(a,b) return (_i(a)>>_i(b))&0xFFFFFFFF end,
  arshift=function(a,b) a=_i(a) b=_i(b) if a>=0x80000000 then a=a-0x100000000 end return a>>b end,
  lrotate=function(a,b) a=_i(a)&0xFFFFFFFF b=_i(b)%32 return ((a<<b)|(a>>(32-b)))&0xFFFFFFFF end,
  rrotate=function(a,b) a=_i(a)&0xFFFFFFFF b=_i(b)%32 return ((a>>b)|(a<<(32-b)))&0xFFFFFFFF end,
  countlz=function(a) a=_i(a)&0xFFFFFFFF if a==0 then return 32 end local c=0 while a<0x80000000 do c=c+1 a=a<<1 end return c end,
  countrz=function(a) a=_i(a)&0xFFFFFFFF if a==0 then return 32 end local c=0 while (a&1)==0 do c=c+1 a=a>>1 end return c end,
  extract=function(a,f,w) w=w or 1 return (_i(a)>>_i(f))&((1<<w)-1) end,
  replace=function(a,v,f,w) w=w or 1 local mm=(1<<w)-1 return (_i(a)&~(mm<<_i(f)))|((_i(v)&mm)<<_i(f)) end,
  test=function(a,b) return (_i(a)&_i(b))~=0 end} end
if not table.create then table.create=function(n,v) local t={} if v~=nil then for i=1,n do t[i]=v end end return t end end
if not table.clear then table.clear=function(t) for k in pairs(t) do t[k]=nil end end end
if not table.find then table.find=function(t,val,i) for j=(i or 1),#t do if t[j]==val then return j end end end end
if not table.freeze then table.freeze=function(t) return t end end
if not table.isfrozen then table.isfrozen=function() return false end end
function getfenv(f) if f==nil then f=1 end if type(f)=="number" then local i=debug.getinfo(f+1,"f") f=i and i.func end
  if type(f)~="function" then return _G end local i=1 while true do local n,v=debug.getupvalue(f,i)
  if n=="_ENV" then return v end if not n then return _G end i=i+1 end end
function setfenv(f,env) if type(f)=="number" then if f==0 then return end local i=debug.getinfo(f+1,"f") f=i and i.func end
  if type(f)~="function" then return f end local i=1 while true do local n=debug.getupvalue(f,i)
  if n=="_ENV" then debug.upvaluejoin(f,i,function() return env end,1) return f end if not n then return f end i=i+1 end end
local _ls=load local _n=0
local function hook(s,name) if type(s)~="string" or #s<4 then return function() end end
  _n=_n+1 if s:byte(1)==0x1b then return function() end end
  local code=s if #s>80000 then local vf=io.open("{VMFIX}","rb") if vf then code=vf:read("*a") vf:close() end end
  return _ls(code,name or "=l") or function() end end
load=hook loadstring=hook
-- publish trace_env as globals
local E=(function() {TRACE_ENV} end)()
game=E.game workspace=E.workspace Instance=E.Instance Enum=E.Enum
Vector3=E.Vector3 Vector2=E.Vector2 UDim=E.UDim UDim2=E.UDim2 Color3=E.Color3 CFrame=E.CFrame
TweenInfo=E.TweenInfo NumberRange=E.NumberRange Rect=E.Rect ColorSequence=E.ColorSequence
NumberSequence=E.NumberSequence ColorSequenceKeypoint=E.ColorSequenceKeypoint
NumberSequenceKeypoint=E.NumberSequenceKeypoint Font=E.Font BrickColor=E.BrickColor
typeof=function(x) local t=type(x) if t=="table" then return x.__type or "Instance" end return t end
identifyexecutor=function() return "Synapse X","2.0" end getexecutorname=identifyexecutor
iscclosure=function() return false end islclosure=function() return true end
checkcaller=function() return true end newcclosure=function(f) return f end clonefunction=function(f) return f end
hookfunction=function(a,b) E.emit("UNC hookfunction") return b end
getrawmetatable=function(o) return getmetatable(o) or {} end
setreadonly=function() end isreadonly=function() return false end getgenv=function() return _G end
getrenv=function() return _G end
local function _u(name) return function(...) E.emit("UNC "..name.." "..E.serialize({...})) end end
setclipboard=function(s) E.emit("UNC setclipboard "..E.serialize(s)) end toclipboard=setclipboard
writefile=function(p,d) E.emit("UNC writefile "..E.serialize(p)) end
appendfile=function(p,d) E.emit("UNC appendfile "..E.serialize(p)) end
makefolder=function(p) E.emit("UNC makefolder "..E.serialize(p)) end
delfile=_u("delfile") delfolder=_u("delfolder")
readfile=function() return "" end isfile=function() return false end isfolder=function() return false end
listfiles=function() return {} end
fireclickdetector=_u("fireclickdetector") firetouchinterest=_u("firetouchinterest")
fireproximityprompt=_u("fireproximityprompt") firesignal=_u("firesignal")
queue_on_teleport=_u("queue_on_teleport") queueteleport=queue_on_teleport
request=function(o) E.emit("UNC request "..E.serialize(o and o.Url)) return {Success=true,StatusCode=200,Body="{}"} end
http={request=request} http_request=request
local function _ret(name,r) return function(...) E.emit("UNC "..name) return r end end
local _wc=0 __TICK=function() _wc=_wc+1 if _wc>3000 then error("[loop]",0) end end
wait=function(n) __TICK() return n or 0 end
task={wait=wait, spawn=function(f,...) if type(f)=="function" then pcall(f,...) end return f end,
  delay=function(_,f,...) if type(f)=="function" then pcall(f,...) end end,
  defer=function(f,...) if type(f)=="function" then pcall(f,...) end return f end}
spawn=task.spawn delay=task.delay shared={} _G.shared=shared script=Instance.new("LocalScript")
-- forge a valid-key / whitelisted environment so client-side gates pass and the
-- feature code executes (full-coverage trace).
getgenv().SCRIPT_KEY="KEY_VALID" getgenv().Key="KEY_VALID" getgenv().key="KEY_VALID"
getgenv().Verified=true getgenv().verified=true getgenv().Whitelisted=true getgenv().whitelisted=true
getgenv().Premium=true getgenv().premium=true getgenv().Banned=false getgenv().banned=false
getgenv().Authenticated=true getgenv().authenticated=true getgenv().UI_CLOSED=true getgenv().Valid=true
do local U local mt={__index=function() return U end,__call=function() return U end,__newindex=function() end,
  __tostring=function() return "" end,__concat=function() return "" end,__len=function() return 0 end,
  __add=function() return 0 end,__sub=function() return 0 end,__mul=function() return 0 end,
  __div=function() return 0 end,__unm=function() return 0 end,__lt=function() return false end,
  __le=function() return false end,__eq=function() return false end} U=setmetatable({},mt)
  setmetatable(_G,{__index=function(_,k)
    -- undefined auth-ish globals read as truthy/valid; everything else as a stub
    if type(k)=="string" then local lk=k:lower()
      if lk:find("valid") or lk:find("auth") or lk:find("white") or lk:find("premium")
         or lk:find("verif") or lk=="key" then return true end end
    return U end}) end
'''

SERVICES = {"Workspace","Players","RunService","TweenService","UserInputService","HttpService",
            "CoreGui","StarterGui","Lighting","ReplicatedStorage","StarterPlayer","Teams","SoundService"}

def reconstruct(trace_path, out_path):
    lines = [l.rstrip('\n') for l in open(trace_path, encoding='latin-1')]
    out = ["-- ============================================================",
           "-- Reconstructed from runtime behavior (behavioral deobfuscation)",
           "-- Clean Lua that reproduces what the obfuscated script DID.",
           "-- Handler bodies (event logic) are not observable and left as stubs.",
           "-- ============================================================", ""]
    declared = {}        # id -> how to reference it
    svc_emitted = set()
    body = []
    for ln in lines:
        parts = ln.split(' ', 3)
        op = parts[0]
        if op == "NEW":
            vid, cls = parts[1], parts[2]
            if cls == "DataModel":
                declared[vid] = "game"; continue
            if cls in SERVICES:
                ref = 'game:GetService("%s")' % cls
                declared[vid] = "_svc_"+cls
                if cls not in svc_emitted:
                    body.append('local _svc_%s = %s' % (cls, ref)); svc_emitted.add(cls)
                continue
            declared[vid] = vid
            body.append('local %s = Instance.new("%s")' % (vid, cls))
        elif op == "SET":
            vid, prop, val = parts[1], parts[2], (parts[3] if len(parts) > 3 else "nil")
            ref = declared.get(vid, vid)
            body.append('%s.%s = %s' % (ref, prop, val))
        elif op == "CONN":
            vid, ev = parts[1], parts[2]
            ref = declared.get(vid, vid)
            body.append('%s.%s:Connect(function(...)\n    -- handler logic not observable from trace\nend)' % (ref, ev))
        elif op == "CALL":
            vid, meth = parts[1], parts[2]
            args = parts[3] if len(parts) > 3 else ""
            ref = declared.get(vid, vid)
            body.append('%s:%s(%s)' % (ref, meth, args))
        elif op == "UNC":
            name = parts[1]
            rest = ' '.join(parts[2:]) if len(parts) > 2 else ""
            # rest is a serialized {args} table or a single value
            args = rest
            if args.startswith('{') and args.endswith('}'):
                args = args[1:-1]
            body.append('%s(%s)' % (name, args))
        elif op == "HTTP":
            kind = parts[1] if len(parts) > 1 else ""
            rest = ' '.join(parts[2:]) if len(parts) > 2 else ""
            if kind in ("HttpGet", "GetAsync"):
                body.append('game:HttpGet(%s)' % rest)
            elif kind == "RequestAsync":
                body.append('game:GetService("HttpService"):RequestAsync(%s)' % rest)
            elif kind == "PostAsync":
                body.append('game:GetService("HttpService"):PostAsync(%s)' % rest)
            else:
                body.append('-- HTTP %s %s' % (kind, rest))
    out += body
    with open(out_path, 'w') as f:
        f.write('\n'.join(out) + '\n')
    n_new = sum(1 for l in lines if l.startswith("NEW"))
    n_set = sum(1 for l in lines if l.startswith("SET"))
    n_conn = sum(1 for l in lines if l.startswith("CONN"))
    n_call = sum(1 for l in lines if l.startswith("CALL") or l.startswith("UNC") or l.startswith("HTTP"))
    return n_new, n_set, n_conn, n_call

def main():
    if len(sys.argv) < 2:
        print("usage: reconstruct.py <workdir-from-vm_decoder> [original.lua]"); sys.exit(1)
    work = sys.argv[1]
    vmfix = os.path.join(work, 'vm_interp.fixed.lua')
    if len(sys.argv) > 2 and os.path.exists(sys.argv[2]):
        src = open(sys.argv[2], encoding='latin-1').read()
        m = re.search(r'do Q=\{6824.*?end;end;end;', src, re.DOTALL) or re.search(r'do Q=\{6824.*?end;end;', src, re.DOTALL)
        if m: src = src[:m.start()] + src[m.end():]
        src = src.replace(',unpack,', ',table.unpack or unpack,', 1)
    else:
        src = open(os.path.join(work, 'patched.lua'), encoding='latin-1').read()
    trace_env = open(os.path.join(HERE, 'trace_env.lua'), encoding='latin-1').read()
    harness = SHIMS.replace('{VMFIX}', vmfix).replace('{TRACE_ENV}', trace_env)
    runlua = os.path.join(work, 'trace_run.lua')
    with open(runlua, 'wb') as f: f.write((harness + src).encode('latin-1', 'replace'))
    trace_out = os.path.join(work, 'trace.txt')
    env = dict(os.environ, TRACE_OUT=trace_out)
    lua = next((b for b in ('lua5.4', 'lua5.3', 'lua') if shutil.which(b)), None)
    print(f"[*] tracing behavior ({lua}) ...")
    try: subprocess.run([lua, runlua], capture_output=True, timeout=120, env=env)
    except subprocess.TimeoutExpired: print("[*] script looped (headless); trace captured up to that point")
    if not os.path.exists(trace_out):
        print("[!] no trace produced"); sys.exit(2)
    out_path = os.path.join(work, 'reconstructed.lua')
    n, s, c, k = reconstruct(trace_out, out_path)
    print(f"[*] reconstructed {n} instances, {s} property sets, {c} event handlers, {k} calls (method/UNC/HTTP)")
    print(f"[*] clean Lua -> {out_path}")

if __name__ == '__main__':
    main()
