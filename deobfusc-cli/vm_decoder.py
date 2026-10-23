#!/usr/bin/env python3
"""
vm_decoder.py — Dynamic Luraph v14.x VM-layer decoder (AI-only deobfuscator)
============================================================================

Where the *static* decoder (engine.lua --luraph) only base85/LZMA-unwraps the
outer blobs, this module actually *runs* the Luraph virtual machine in a stock
Lua 5.4 interpreter and captures the decompressed bytecode the VM produces — the
true "VM layer".

Pipeline
--------
  1. Strip/patch the outer Luraph script (anti-tamper, unpack, Lua5.1 compat).
  2. Inject a loadstring hook + a full Roblox/executor stub environment.
  3. Pass 1: run once to capture the ~90 KB Luau VM-interpreter source the outer
     script feeds to loadstring.
  4. Preprocess that source Luau→Lua5.4 (continue→goto, +=, invalid escapes).
  5. Pass 2: re-run; the hook loads the fixed VM. Wrappers on string.byte /
     string.unpack capture every large string the VM reads — the largest is the
     LZMA-decompressed Luraph bytecode.
  6. Parse the decoded proto: header + typed constant pool
     (0x7c string / 0x0e int64 / 0xab double) + instruction stream.

Outputs (in <workdir>):
  vm_interp.lua        captured Luau VM interpreter (raw)
  vm_interp.fixed.lua  VM interpreter preprocessed for Lua 5.4
  vm_blob_<N>.bin      every distinct large string the VM read (incl. decoded BC)
  decoded_bytecode.bin the largest blob = decompressed Luraph bytecode
  constants.txt        parsed top-level constant pool
  globals.txt          Roblox/executor globals the payload requested
  http.txt             any HttpService / HttpGet calls the payload made

Requires: lua5.4 (or lua5.3) on PATH.
Usage:    vm_decoder.py <obfuscated.lua> [workdir]
"""

import sys, os, re, struct, subprocess, glob, shutil

# ════════════════════════════════════════════════════════════════════════════
#  Luau → Lua 5.4 source preprocessor (tokenizer + 3 transforms)
# ════════════════════════════════════════════════════════════════════════════
_KEYWORDS = {'and','break','continue','do','else','elseif','end','false','for',
             'function','goto','if','in','local','nil','not','or','repeat',
             'return','then','true','until','while'}

def tokenize(src):
    i, n = 0, len(src)
    while i < n:
        c = src[i]
        if c == '[':                                   # long string
            j = i + 1; level = 0
            while j < n and src[j] == '=': level += 1; j += 1
            if j < n and src[j] == '[':
                close = ']' + '=' * level + ']'
                end = src.find(close, j + 1)
                if end != -1:
                    end += len(close); yield ('str', src[i:end]); i = end; continue
        if c == '-' and i + 1 < n and src[i + 1] == '-':   # comment
            j = i + 2
            if j < n and src[j] == '[':
                k = j + 1; level = 0
                while k < n and src[k] == '=': level += 1; k += 1
                if k < n and src[k] == '[':
                    close = ']' + '=' * level + ']'
                    end = src.find(close, k + 1)
                    if end != -1:
                        end += len(close); yield ('comment', src[i:end]); i = end; continue
            end = src.find('\n', i)
            if end == -1: end = n
            yield ('comment', src[i:end + 1]); i = end + 1; continue
        if c in ('"', "'"):                            # short string
            j = i + 1
            while j < n:
                if src[j] == '\\': j += 2
                elif src[j] == c: break
                else: j += 1
            yield ('str', src[i:j + 1]); i = j + 1; continue
        if c.isdigit() or (c == '.' and i + 1 < n and src[i + 1].isdigit()):
            j = i
            while j < n and (src[j].isalnum() or src[j] in '.xXeEpP+-_'): j += 1
            yield ('num', src[i:j]); i = j; continue
        if c.isalpha() or c == '_':
            j = i
            while j < n and (src[j].isalnum() or src[j] == '_'): j += 1
            w = src[i:j]; yield ('kw' if w in _KEYWORDS else 'name', w); i = j; continue
        if c in ' \t\r\n':
            j = i
            while j < n and src[j] in ' \t\r\n': j += 1
            yield ('ws', src[i:j]); i = j; continue
        two = src[i:i + 2]
        if two in ('//', '..', '~=', '<=', '>=', '==', '<<', '>>',
                   '+=', '-=', '*=', '/=', '%='):
            yield ('sym', two); i += 2; continue
        yield ('sym', c); i += 1

_VALID_ESC = set('abfnrtvxuU0123456789\\\'"z\n\r ')

def _fix_string_token(text):
    if not text or text[0] not in ('"', "'"): return text
    q = text[0]; out = [q]; i = 1
    while i < len(text) - 1:
        if text[i] == '\\' and i + 1 < len(text) - 1:
            ch = text[i + 1]
            if ch not in _VALID_ESC: out.append(ch); i += 2
            else: out.append(text[i:i + 2]); i += 2
        else: out.append(text[i]); i += 1
    out.append(q); return ''.join(out)

def fix_string_escapes(tokens):
    return [(k, _fix_string_token(t)) if k == 'str' and t[:1] in ('"', "'") else (k, t)
            for k, t in tokens]

def fix_compound_assignments(tokens):
    out, i = [], 0
    while i < len(tokens):
        kind, text = tokens[i]
        if kind == 'sym' and text in ('+=', '-=', '*=', '/=', '%='):
            op = text[0]; j = len(out) - 1
            while j >= 0 and out[j][0] == 'ws': j -= 1
            if j >= 0 and (out[j][0] in ('name', 'kw', 'num') or
                           (out[j][0] == 'sym' and out[j][1] in (']', ')'))):
                lhs = out[j][1]; out = out[:j]
                out.append(('name', lhs + ' = ' + lhs + ' ' + op + ' ('))
                i += 1
                while i < len(tokens) and tokens[i][0] == 'ws': out.append(tokens[i]); i += 1
                depth = 0
                while i < len(tokens):
                    tk = tokens[i]
                    if tk[1] in ('(', '[', '{'): depth += 1; out.append(tk)
                    elif tk[1] in (')', ']', '}'):
                        if depth == 0: break
                        depth -= 1; out.append(tk)
                    elif tk[1] == ';' and depth == 0: break
                    else: out.append(tk)
                    i += 1
                out.append(('sym', ')')); continue
        out.append((kind, text)); i += 1
    return out

def fix_continue(tokens):
    out, stack, cont_n, pending, used = [], [], [0], [], set()
    i = 0
    while i < len(tokens):
        kind, text = tokens[i]
        if kind == 'kw' and text == 'repeat':
            cont_n[0] += 1; stack.append({'type': 'repeat', 'cid': cont_n[0]}); out.append((kind, text))
        elif kind == 'kw' and text == 'function':
            stack.append({'type': 'func', 'cid': -1}); out.append((kind, text))
        elif kind == 'kw' and text == 'if':
            stack.append({'type': 'if', 'cid': -1}); out.append((kind, text))
        elif kind == 'kw' and text in ('for', 'while'):
            pending.append(text); out.append((kind, text))
        elif kind == 'kw' and text == 'do':
            if pending:
                lt = pending.pop(); cont_n[0] += 1; stack.append({'type': lt, 'cid': cont_n[0]})
            else:
                stack.append({'type': 'do', 'cid': -1})
            out.append((kind, text))
        elif kind == 'kw' and text in ('then', 'else', 'elseif'):
            out.append((kind, text))
        elif kind == 'kw' and text == 'end':
            top = stack.pop() if stack else {'type': '?', 'cid': -1}
            if top['type'] in ('for', 'while') and top['cid'] in used:
                last = next((t[1] for t in reversed(out) if t[0] not in ('ws', 'comment')), '')
                if last != 'return': out.append(('sym', ' ::_cont_' + str(top['cid']) + ':: '))
            out.append((kind, text))
        elif kind == 'kw' and text == 'until':
            top = stack.pop() if stack else {'type': '?', 'cid': -1}
            if top['type'] == 'repeat' and top['cid'] in used:
                last = next((t[1] for t in reversed(out) if t[0] not in ('ws', 'comment')), '')
                if last != 'return': out.append(('sym', ' ::_cont_' + str(top['cid']) + ':: '))
            out.append((kind, text))
        elif kind == 'kw' and text == 'continue':
            cid = -1
            for fr in reversed(stack):
                if fr['type'] in ('repeat', 'for', 'while') and fr['cid'] > 0: cid = fr['cid']; break
            if cid > 0: used.add(cid); out.append(('sym', 'goto _cont_' + str(cid)))
            else: out.append((kind, text))
        else:
            out.append((kind, text))
        i += 1
    return out

def normalize_luau_numbers(src):
    """Luau number literals → Lua 5.4: binary 0b… and underscore separators
    (e.g. 0X61__, 0b101__1, 1_000) which Luarmor 'superflow' uses heavily.
    Strings/comments are protected via the tokenizer before the regex pass."""
    holds, parts = [], []
    for kind, text in tokenize(src):
        if kind in ('str', 'comment'):
            parts.append('\x00%d\x00' % len(holds)); holds.append(text)
        else:
            parts.append(text)
    code = ''.join(parts)
    code = re.sub(r'0[bB][01][01_]*',
                  lambda m: str(int(m.group(0)[2:].replace('_', ''), 2) if m.group(0)[2:].replace('_', '') else 0), code)
    code = re.sub(r'0[xX][0-9a-fA-F][0-9a-fA-F_]*',
                  lambda m: '0x' + m.group(0)[2:].replace('_', ''), code)
    code = re.sub(r'\b\d[\d_]*\.?[\d_]*(?:[eEpP][+\-]?\d[\d_]*)?',
                  lambda m: m.group(0).replace('_', ''), code)
    return re.sub('\x00(\\d+)\x00', lambda m: holds[int(m.group(1))], code)


def luau_to_lua54(src):
    src = normalize_luau_numbers(src)        # binary/underscore numbers first
    toks = list(tokenize(src))
    toks = fix_string_escapes(toks)
    toks = fix_compound_assignments(toks)
    toks = fix_continue(toks)
    return ''.join(t[1] for t in toks)

# ════════════════════════════════════════════════════════════════════════════
#  Lua harness (stubs + hook + blob capture)  — templated with {WORK} {VMFIX}
# ════════════════════════════════════════════════════════════════════════════
HARNESS = r'''
-- ── decoded-blob capture: wrap byte readers ────────────────────────────────
do
  local DIR = "{WORK}/"
  local seen = {}
  local function rec(s)
    if type(s)=="string" and #s>256 and not seen[#s] then
      seen[#s]=true
      local f=io.open(DIR.."vm_blob_"..#s..".bin","wb"); if f then f:write(s); f:close() end
      io.stderr:write("[blob] "..#s.."\n")
    end
  end
  local ob=string.byte; string.byte=function(s,i,j) rec(s); return ob(s,i,j) end
  local ou=string.unpack
  if ou then string.unpack=function(fmt,s,p) rec(s); return ou(fmt,s,p) end end
end

if not unpack then unpack = table.unpack end
if not string.pack then
  string.pack = function(fmt,n)
    if fmt==">I4" then n=math.floor(n)%4294967296
      return string.char(math.floor(n/16777216)%256,math.floor(n/65536)%256,math.floor(n/256)%256,n%256) end
    error("string.pack: unsupported fmt "..tostring(fmt))
  end
end
if not bit32 then
  local function _i(v)
    if type(v)=='boolean' then return v and 1 or 0 end
    if type(v)=='number' then return math.tointeger(v) or (v>=0 and math.floor(v) or math.ceil(v)) end
    return 0 end
  bit32={
    band=function(...) local r=0xFFFFFFFF for _,v in ipairs({...}) do r=r&_i(v) end return r end,
    bor=function(...) local r=0 for _,v in ipairs({...}) do r=r|_i(v) end return r end,
    bxor=function(...) local r=0 for _,v in ipairs({...}) do r=r~_i(v) end return r end,
    bnot=function(a) return (~_i(a))&0xFFFFFFFF end,
    lshift=function(a,b) return (_i(a)<<_i(b))&0xFFFFFFFF end,
    rshift=function(a,b) return (_i(a)>>_i(b))&0xFFFFFFFF end,
    arshift=function(a,b) a=_i(a) b=_i(b) if a>=0x80000000 then a=a-0x100000000 end return a>>b end,
    lrotate=function(a,b) a=_i(a)&0xFFFFFFFF b=_i(b)%32 return ((a<<b)|(a>>(32-b)))&0xFFFFFFFF end,
    rrotate=function(a,b) a=_i(a)&0xFFFFFFFF b=_i(b)%32 return ((a>>b)|(a<<(32-b)))&0xFFFFFFFF end,
    countlz=function(a) a=_i(a)&0xFFFFFFFF if a==0 then return 32 end local c=0 while a<0x80000000 do c=c+1 a=a<<1 end return c end,
    countrz=function(a) a=_i(a)&0xFFFFFFFF if a==0 then return 32 end local c=0 while (a&1)==0 do c=c+1 a=a>>1 end return c end,
    extract=function(a,f,w) w=w or 1 a=_i(a) f=_i(f) return (a>>f)&((1<<w)-1) end,
    replace=function(a,v,f,w) w=w or 1 a=_i(a) v=_i(v) f=_i(f) local m=(1<<w)-1 return (a&~(m<<f))|((v&m)<<f) end,
    test=function(a,b) return (_i(a)&_i(b))~=0 end,
  }
end
if not table.create then table.create=function(n,v) local t={} if v~=nil then for i=1,n do t[i]=v end end return t end end
if not table.clear  then table.clear =function(t) for k in pairs(t) do t[k]=nil end end end
if not table.find   then table.find  =function(t,val,init) for i=(init or 1),#t do if t[i]==val then return i end end end end
if not table.freeze then table.freeze=function(t) return t end end
if not table.isfrozen then table.isfrozen=function() return false end end

-- getfenv/setfenv via _ENV upvalue (the VM stores setfenv to sandbox closures)
if not getfenv then function getfenv(f)
  if f==nil then f=1 end
  if type(f)=="number" then local i=debug.getinfo(f+1,"f") f=i and i.func end
  if type(f)~="function" then return _G end
  local i=1 while true do local n,v=debug.getupvalue(f,i) if n=="_ENV" then return v end if not n then return _G end i=i+1 end
end end
if not setfenv then function setfenv(f,env)
  if type(f)=="number" then if f==0 then return end local i=debug.getinfo(f+1,"f") f=i and i.func end
  if type(f)~="function" then return f end
  local i=1 while true do local n=debug.getupvalue(f,i)
    if n=="_ENV" then debug.upvaluejoin(f,i,function() return env end,1) return f end
    if not n then return f end i=i+1 end
end end

-- ── loadstring hook: captures every chunk; loads fixed VM for the big one ───
local VMFIX="{VMFIX}"
local cap=0
local orig=load
local function hook(src,name,...)
  if type(src)~="string" or #src<4 then return function() return nil end end
  cap=cap+1
  local f=io.open("{WORK}/layer_"..cap..".bin","wb"); if f then f:write(src) f:close() end
  if src:byte(1)==0x1b then return function() return nil end end  -- precompiled
  local code=src
  if #src>80000 then
    local vf=io.open(VMFIX,"rb")
    if vf then code=vf:read("*a") vf:close() io.stderr:write("[hook] using fixed VM\n") end
  end
  local fn=orig(code,name or ("=l"..cap),...)
  if fn then return fn end
  return function() return nil end
end
load=hook; loadstring=hook

-- ── Roblox / executor environment ──────────────────────────────────────────
local function stub(n) n=n or "stub"
  return setmetatable({},{__index=function(_,k) return stub(n.."."..k) end,
    __call=function() return stub(n.."()") end,__newindex=function(t,k,v) rawset(t,k,v) end,
    __tostring=function() return n end,__len=function() return 0 end}) end
local function logcall(tag,...)
  local p={}
  for i=1,select("#",...) do local v=select(i,...)
    if type(v)=="table" then local kv={} for k,vv in pairs(v) do kv[#kv+1]=tostring(k).."="..tostring(vv) end
      p[#p+1]="{"..table.concat(kv,", ").."}" else p[#p+1]=tostring(v) end end
  local line="[HTTP "..tag.."] "..table.concat(p," | ")
  io.stderr:write(line.."\n")
  local f=io.open("{WORK}/http.txt","a"); if f then f:write(line.."\n") f:close() end
end
local Http=setmetatable({
  RequestAsync=function(_,o) logcall("RequestAsync",o) return {Success=true,StatusCode=200,Body="{}",Headers={}} end,
  GetAsync=function(_,u,...) logcall("GetAsync",u,...) return "" end,
  PostAsync=function(_,u,b,...) logcall("PostAsync",u,b,...) return "" end,
  JSONEncode=function(_,t) return "{}" end, JSONDecode=function(_,s) return {} end,
  GenerateGUID=function() return "00000000-0000-0000-0000-000000000000" end,
  UrlEncode=function(_,s) return tostring(s) end,
},{__index=function(_,k) return stub("HttpService."..k) end})
game=stub("game")
game.HttpGet=function(_,u,...) logcall("HttpGet",u,...) return "" end
game.HttpGetAsync=game.HttpGet
game.GetService=function(_,n) if n=="HttpService" then return Http end return stub(n) end
game.HttpService=Http; HttpService=Http
workspace=stub("workspace"); script=stub("script")
typeof=function(x) local t=type(x) if t=="table" then return "Instance" end return t end
identifyexecutor=function() return "Synapse X","2.0" end; getexecutorname=identifyexecutor
iscclosure=function() return false end; islclosure=function() return true end
isexecutorclosure=function() return true end; checkcaller=function() return true end
hookfunction=function(_,b) return b end; newcclosure=function(f) return f end
local waits=0
local function tick(n) waits=waits+1 if waits>2000 then error("[loop-break]",0) end return n or 0 end
wait=tick; spawn=function(f,...) if type(f)=="function" then pcall(f,...) end return f end
task={wait=tick,spawn=spawn,delay=function(_,f,...) if type(f)=="function" then pcall(f,...) end end,
  defer=function(f,...) if type(f)=="function" then pcall(f,...) end return f end,cancel=function() end}
delay=function(_,f,...) if type(f)=="function" then pcall(f,...) end end
getgenv=function() return _G end; getrenv=function() return _G end; getsenv=function() return {} end
writefile=function() end; readfile=function() return "" end; makefolder=function() end
isfile=function() return false end; isfolder=function() return false end; appendfile=function() end
listfiles=function() return {} end; request=function() return {Body="",StatusCode=200} end
syn=stub("syn"); Drawing=stub("Drawing"); shared=stub("shared"); _G.shared=shared

-- universal fallback: any UNDEFINED global → indexable/callable proxy (keeps
-- the decoded payload alive so it reaches its HTTP / loadstring calls).
do
  local U
  local mt={__index=function() return U end,__call=function() return U end,__newindex=function() end,
    __tostring=function() return "stub" end,__concat=function() return "stub" end,__len=function() return 0 end,
    __add=function() return 0 end,__sub=function() return 0 end,__mul=function() return 0 end,
    __div=function() return 0 end,__mod=function() return 0 end,__pow=function() return 0 end,
    __unm=function() return 0 end,__idiv=function() return 0 end,__eq=function() return false end,
    __lt=function() return false end,__le=function() return false end}
  U=setmetatable({},mt)
  local seen={}
  setmetatable(_G,{__index=function(_,k)
    if type(k)=="string" and not seen[k] then seen[k]=true
      local f=io.open("{WORK}/globals.txt","a") if f then f:write(k.."\n") f:close() end end
    return U end})
end
'''

# ════════════════════════════════════════════════════════════════════════════
#  Proto / constant-pool parser
# ════════════════════════════════════════════════════════════════════════════
def parse_constants(path):
    with open(path, 'rb') as f: d = f.read()
    n, i = len(d), 4
    consts = []
    while i < n:
        m = d[i]
        if m == 0x7c:
            if i + 1 >= n: break
            ln = d[i + 1]; consts.append(('str', d[i + 2:i + 2 + ln])); i += 2 + ln
        elif m == 0x0e:
            if i + 9 > n: break
            consts.append(('int', struct.unpack('<q', d[i + 1:i + 9])[0])); i += 9
        elif m == 0xab:
            if i + 9 > n: break
            consts.append(('dbl', struct.unpack('<d', d[i + 1:i + 9])[0])); i += 9
        else:
            break
    return consts, i

# ════════════════════════════════════════════════════════════════════════════
#  Outer-script patching
# ════════════════════════════════════════════════════════════════════════════
def patch_outer(src):
    m = re.search(r'do Q=\{6824.*?end;end;end;', src, re.DOTALL) or \
        re.search(r'do Q=\{6824.*?end;end;', src, re.DOTALL)
    if m: src = src[:m.start()] + src[m.end():]
    src = src.replace(',unpack,', ',table.unpack or unpack,', 1)
    return src

def find_lua():
    for b in ('lua5.4', 'lua5.3', 'lua'):
        if shutil.which(b): return b
    return None

# ════════════════════════════════════════════════════════════════════════════
def main():
    if len(sys.argv) < 2:
        print("usage: vm_decoder.py <obfuscated.lua> [workdir]"); sys.exit(1)
    infile = sys.argv[1]
    work = sys.argv[2] if len(sys.argv) > 2 else infile + '.vmwork'
    os.makedirs(work, exist_ok=True)
    lua = find_lua()
    if not lua:
        print("[!] need lua5.4/lua5.3 on PATH"); sys.exit(1)

    with open(infile, 'rb') as f: src = f.read().decode('latin-1')
    src = patch_outer(src)
    print(f"[*] outer script patched ({len(src)} bytes), runtime={lua}")

    vmfix = os.path.join(work, 'vm_interp.fixed.lua')
    harness = HARNESS.replace('{WORK}', work).replace('{VMFIX}', vmfix)

    # clean prior artifacts
    for p in glob.glob(os.path.join(work, 'vm_blob_*.bin')) + \
             glob.glob(os.path.join(work, 'layer_*.bin')):
        os.remove(p)
    for fn in ('globals.txt', 'http.txt'):
        p = os.path.join(work, fn)
        if os.path.exists(p): os.remove(p)

    patched = os.path.join(work, 'patched.lua')
    with open(patched, 'wb') as f:
        f.write((harness + src).encode('latin-1', errors='replace'))

    def run(timeout):
        try:
            subprocess.run([lua, patched], capture_output=True, timeout=timeout)
        except subprocess.TimeoutExpired:
            pass

    # Pass 1 — capture the raw Luau VM interpreter
    if not os.path.exists(vmfix):
        print("[*] pass 1: capturing VM interpreter source ...")
        run(40)
        layers = sorted(glob.glob(os.path.join(work, 'layer_*.bin')), key=os.path.getsize)
        vm_raw = None
        for p in layers:
            if os.path.getsize(p) > 80000:
                with open(p, 'rb') as f:
                    if f.read(5) != b'\x1bLua': vm_raw = p; break
        if not vm_raw:
            print("[!] VM interpreter not captured — is this Luraph v14.x?"); sys.exit(2)
        shutil.copy(vm_raw, os.path.join(work, 'vm_interp.lua'))
        with open(vm_raw, 'rb') as f: raw = f.read().decode('latin-1')
        with open(vmfix, 'wb') as f: f.write(luau_to_lua54(raw).encode('latin-1', errors='replace'))
        print(f"[*] VM interpreter fixed for Lua 5.4 -> {vmfix}")

    # Pass 2 — run VM, capture decompressed bytecode
    print("[*] pass 2: executing VM, capturing decoded bytecode ...")
    run(90)

    blobs = sorted(glob.glob(os.path.join(work, 'vm_blob_*.bin')), key=os.path.getsize)
    if not blobs:
        print("[!] no decoded blob captured"); sys.exit(3)
    biggest = blobs[-1]
    decoded = os.path.join(work, 'decoded_bytecode.bin')
    shutil.copy(biggest, decoded)
    print(f"[*] decoded bytecode: {decoded} ({os.path.getsize(decoded)} bytes)")

    consts, stop = parse_constants(decoded)
    cpath = os.path.join(work, 'constants.txt')
    with open(cpath, 'w') as f:
        for idx, (t, v) in enumerate(consts):
            f.write(f'[{idx}] {t} {v!r}\n' if t == 'str' else f'[{idx}] {t} {v}\n')
    strs = [v for t, v in consts if t == 'str']
    print(f"[*] constant pool: {len(consts)} entries "
          f"({len(strs)} str / {sum(1 for t,_ in consts if t=='int')} int / "
          f"{sum(1 for t,_ in consts if t=='dbl')} dbl); instructions begin @ {stop}")
    print(f"[*] wrote {cpath}")

    gp = os.path.join(work, 'globals.txt')
    if os.path.exists(gp):
        with open(gp) as f: gl = [l.strip() for l in f if l.strip()]
        print(f"[*] payload requested {len(gl)} undefined globals: {', '.join(gl[:20])}")
    hp = os.path.join(work, 'http.txt')
    if os.path.exists(hp) and os.path.getsize(hp) > 0:
        print("[*] HTTP calls captured (http.txt):")
        with open(hp) as f: print(f.read())
    print("\n[done] artifacts in", work)

if __name__ == '__main__':
    main()
