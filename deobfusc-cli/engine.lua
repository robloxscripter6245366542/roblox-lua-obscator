-- deobfusc engine — run by the bash CLI
-- Usage: lua engine.lua <mode> [file]
-- Modes: deob | detect | keyrm | trace | deep

local mode = arg[1] or "deob"
local file = arg[2]

-- ── Read source ──────────────────────────────────────────────────────────────
local src
if file then
  local f, err = io.open(file, "r")
  if not f then io.stderr:write("Cannot open file: " .. tostring(err) .. "\n"); os.exit(1) end
  src = f:read("*a"); f:close()
else
  src = io.read("*a")
end

-- ── Roblox stubs ─────────────────────────────────────────────────────────────
local function setup_roblox_stubs()
  local stub
  stub = setmetatable({}, {
    __index    = function(t, k)
      return setmetatable({}, {
        __index    = function(tt, kk) return function(...) return tt end end,
        __call     = function(tt, ...) return tt end,
        __newindex = function() end,
      })
    end,
    __call     = function() end,
    __newindex = function() end,
  })
  game = stub; workspace = stub; script = stub; shared = stub
  _G = _G or {}
  if not getfenv then getfenv = function(n) return _ENV end end
  if not setfenv then setfenv = function(n, t) end end
  if not newproxy then newproxy = function() return {} end end
  if not bit then
    bit = {
      bxor    = function(a,b) local r,p=0,1 while a>0 or b>0 do if a%2~=b%2 then r=r+p end a=math.floor(a/2) b=math.floor(b/2) p=p*2 end return r end,
      band    = function(a,b) local r,p=0,1 while a>0 and b>0 do if a%2+b%2>=2 then r=r+p end a=math.floor(a/2) b=math.floor(b/2) p=p*2 end return r end,
      bor     = function(a,b) local r,p=0,1 while a>0 or b>0 do if a%2+b%2>0 then r=r+p end a=math.floor(a/2) b=math.floor(b/2) p=p*2 end return r end,
      bnot    = function(a) return -(a+1) end,
      lshift  = function(a,b) return math.floor(a*(2^b)) end,
      rshift  = function(a,b) return math.floor(a/(2^b)) end,
      arshift = function(a,b) return math.floor(a/(2^b)) end,
      tobit   = function(a) return a end,
      tohex   = function(a,w) return string.format(w and ("%0"..w.."x") or "%x", a) end,
    }
  end
  -- Roblox task scheduler stub
  task = task or {
    wait  = function(t) end,
    spawn = function(f,...) pcall(f,...) end,
    defer = function(f,...) end,
    delay = function(n,f,...) end,
  }
  wait = wait or function(t) end
  getgenv = getgenv or function() return _G end
  getrenv = getrenv or function() return _G end
  syn = syn or stub
  rconsoleprint = rconsoleprint or function() end
  printidentity = printidentity or function() end
  Drawing = Drawing or stub
  writefile = writefile or function() end
  readfile  = readfile  or function() return "" end
  isfile    = isfile    or function() return false end
  request   = request   or function() return {StatusCode=200,Body=""} end
  HttpService = HttpService or stub
end

-- ── Base64 decoder ────────────────────────────────────────────────────────────
local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local b64_lut = {}
for i = 1, 64 do b64_lut[B64:sub(i,i)] = i-1 end

local function b64decode(s)
  s = s:gsub("[^A-Za-z0-9+/=]","")
  if #s < 4 then return nil end
  local out = {}
  for i = 1, #s, 4 do
    local a = b64_lut[s:sub(i,i)]
    local b = b64_lut[s:sub(i+1,i+1)]
    local c = b64_lut[s:sub(i+2,i+2)]
    local d = b64_lut[s:sub(i+3,i+3)]
    if a == nil or b == nil then break end
    out[#out+1] = string.char(((a*4) + math.floor(b/16)) % 256)
    if c ~= nil then out[#out+1] = string.char(((b%16*16) + math.floor(c/4)) % 256) end
    if d ~= nil then out[#out+1] = string.char(((c%4*64) + d) % 256) end
  end
  local result = table.concat(out)
  -- reject if mostly non-printable
  local nprint = result:gsub("[%g%s]","")
  if #nprint / (#result+1) > 0.1 then return nil end
  return result
end

-- ── XOR single-byte decode ────────────────────────────────────────────────────
local function xor_str(s, key)
  local out = {}
  for i = 1, #s do
    local b = s:byte(i)
    local x = b ~ key  -- Lua 5.3+
    if x < 0 then x = x + 256 end
    out[#out+1] = string.char(x)
  end
  return table.concat(out)
end

-- Try Lua 5.1-compat XOR (no ~ operator)
local function xor_byte(a, b)
  if bit then return bit.bxor(a, b) end
  local r, p = 0, 1
  while a > 0 or b > 0 do
    if a%2 ~= b%2 then r = r + p end
    a = math.floor(a/2); b = math.floor(b/2); p = p*2
  end
  return r
end

-- ── Text deobfuscation passes ────────────────────────────────────────────────
local function deob(code)
  local passes = {}
  local b

  -- pass: hex escape \xHH
  b = code
  code = code:gsub("\\x(%x%x)", function(h) return string.char(tonumber(h,16)) end)
  if code ~= b then passes[#passes+1]="hex-escape" end

  -- pass: decimal escape \DDD
  b = code
  code = code:gsub("\\(%d%d?%d?)", function(d)
    local n = tonumber(d)
    return (n and n<=255) and string.char(n) or "\\"..d
  end)
  if code ~= b then passes[#passes+1]="dec-escape" end

  -- pass: string.char(...)
  b = code
  code = code:gsub("string%.char%(([%d,%s]+)%)", function(args)
    local out = {}
    for n in args:gmatch("%d+") do
      local num = tonumber(n); if num then out[#out+1]=string.char(num) end
    end
    return '"'..table.concat(out)..'"'
  end)
  if code ~= b then passes[#passes+1]="string.char" end

  -- pass: concat collapse (12 passes)
  b = code
  for _ = 1, 12 do code = code:gsub('"([^"\\]*)"%s*%.%.%s*"([^"\\]*)"','"%1%2"') end
  if code ~= b then passes[#passes+1]="concat-collapse" end

  -- pass: number array {n,n,n,...} → string (printable ASCII only)
  b = code
  code = code:gsub("{(%d[%d,%s]*)}", function(content)
    local nums = {}
    local ok = true
    for n in content:gmatch("%d+") do
      local v = tonumber(n)
      if not v or v < 32 or v > 126 then ok = false; break end
      nums[#nums+1] = string.char(v)
    end
    if ok and #nums >= 3 then return '"'..table.concat(nums)..'"' end
  end)
  if code ~= b then passes[#passes+1]="num-array" end

  -- pass: string.reverse("literal") inline
  b = code
  code = code:gsub('string%.reverse%("([^"\\]-)"%)', function(s) return '"'..s:reverse()..'"' end)
  if code ~= b then passes[#passes+1]="string.reverse" end

  -- pass: string.rep("x", n) inline
  b = code
  code = code:gsub('string%.rep%("([^"\\]-)",%s*(%d+)%)', function(s, n)
    local cnt = tonumber(n) or 0
    if cnt > 0 and cnt < 2000 then return '"'..s:rep(cnt)..'"' end
  end)
  if code ~= b then passes[#passes+1]="string.rep" end

  -- pass: string.sub("literal", s, e) inline
  b = code
  code = code:gsub('string%.sub%("([^"\\]-)",%s*(-?%d+),%s*(-?%d+)%)', function(s, i, j)
    return '"'..s:sub(tonumber(i), tonumber(j))..'"'
  end)
  if code ~= b then passes[#passes+1]="string.sub" end

  -- pass: string.upper / string.lower inline
  b = code
  code = code:gsub('string%.upper%("([^"\\]-)"%)', function(s) return '"'..s:upper()..'"' end)
  code = code:gsub('string%.lower%("([^"\\]-)"%)', function(s) return '"'..s:lower()..'"' end)
  if code ~= b then passes[#passes+1]="string.case" end

  -- pass: XOR with literal single-byte key on literal string
  -- pattern: (function(s,k)...bxor(byte(s,i),k)...end)("LITERAL", KEY)
  b = code
  code = code:gsub(
    '%(?function%s*%([^%)]+%)%s*local%s+%a+%s*=%s*""%s+for%s+[^\n]+bxor[^\n]+end%s*%)%s*%("([^"]+)",%s*(%d+)%)',
    function(str, key)
      local k = tonumber(key)
      if not k then return end
      local out = {}
      for i = 1, #str do out[#out+1] = string.char(xor_byte(str:byte(i), k)) end
      return '"'..table.concat(out)..'"'
    end
  )
  if code ~= b then passes[#passes+1]="xor-literal" end

  -- pass: base64 decode — Base64.decode("...") / b64d("...") / decodeBase64("...")
  b = code
  code = code:gsub('[Bb]ase64%.?[Dd]ecode%s*%("([A-Za-z0-9+/=]+)"%)', function(s)
    local d = b64decode(s)
    if d then return '"'..d:gsub('"','\\"')..'"' end
  end)
  code = code:gsub('[Dd]ecodeBase64%s*%("([A-Za-z0-9+/=]+)"%)', function(s)
    local d = b64decode(s)
    if d then return '"'..d:gsub('"','\\"')..'"' end
  end)
  if code ~= b then passes[#passes+1]="base64-decode" end

  -- second pass of string.char after previous collapses
  b = code
  code = code:gsub("string%.char%(([%d,%s]+)%)", function(args)
    local out = {}
    for n in args:gmatch("%d+") do
      local num = tonumber(n); if num then out[#out+1]=string.char(num) end
    end
    return '"'..table.concat(out)..'"'
  end)
  if code ~= b then passes[#passes+1]="string.char-2" end

  -- second concat collapse
  b = code
  for _ = 1, 8 do code = code:gsub('"([^"\\]*)"%s*%.%.%s*"([^"\\]*)"','"%1%2"') end
  if code ~= b then passes[#passes+1]="concat-2" end

  -- note VM blobs
  local blobs = 0
  for _ in code:gmatch("%[=%[") do blobs = blobs + 1 end
  if blobs > 0 then
    io.stderr:write("info: "..blobs.." long-string blob(s) — likely VM bytecode. Use 'deep' or 'trace' mode.\n")
  end

  return code, passes
end

-- ── Detection ────────────────────────────────────────────────────────────────
local function detect(code)
  local types = {}
  local function add(t) types[#types+1]=t end
  local lo = code:lower()

  -- Luraph
  if lo:find("luraph") or lo:find("lura%.ph") then
    local ver = code:match("Luraph[^v\n]*v?(%d+%.%d+)")
    add("Luraph"..(ver and " v"..ver or ""))
  elseif code:match("^return%(function%(%)[^\n]*string%.byte") and code:find("%[=%[") then
    add("Luraph v14.x (structural)")
  end

  -- Moonsec
  if lo:find("moonsec") then
    local ver = code:match("[Mm]oonsec%s*v?(%d+%.?%d*)")
    add("Moonsec"..(ver and " v"..ver or ""))
  elseif code:find("local function [A-Z][A-Z][A-Z]%(") and code:find("bit%.bxor") and code:find("repeat") then
    add("Moonsec v3 (structural)")
  end

  -- IronBrew
  if code:find("getfenv") and code:find("0x%x%x%x%x") then
    add(lo:find("ironbrew") and "IronBrew 2" or "IronBrew")
  elseif code:find("string%.dump") and code:find("bit%.bxor") and code:find("loadstring") then
    add("IronBrew 2 (structural)")
  end

  -- Prometheus
  if lo:find("prometheus") then add("Prometheus")
  elseif code:find("local VM = function%(Instructions, Env%)") or code:find("PROMETHEUS_") then
    add("Prometheus (structural)")
  end

  -- PSU
  if code:find("[^%a]PSU[^%a]") and code:find("loadstring") then add("PSU") end

  -- Raw Lua bytecode
  if code:sub(1,4) == "\x1bLua" then
    local v = code:byte(5)
    add("Lua-bytecode-"..(v==0x51 and "5.1" or v==0x52 and "5.2" or v==0x53 and "5.3" or "?"))
  end

  -- Generic custom VM heuristic
  local vm_score = 0
  if code:find("repeat") then vm_score=vm_score+1 end
  if code:find("while%s+true") then vm_score=vm_score+1 end
  if code:find("%[=%[") then vm_score=vm_score+2 end
  if lo:find("opcode") or lo:find("instruction") then vm_score=vm_score+2 end
  if code:find("local%s+[A-Z][A-Z0-9]+%s*=%s*{") then vm_score=vm_score+1 end
  if vm_score >= 4 and #types == 0 then add("CustomVM (heuristic score="..vm_score..")") end

  -- Key systems
  if code:find("jnkie%.com") or code:find("Junkie%.") then add("KeySystem:Junkie") end
  if code:find("Linkvertise") or lo:find("linkvertise") then add("KeySystem:Linkvertise") end
  if lo:find("keysystem") then add("KeySystem:Generic") end
  if code:find("checkKey") or code:find("verifyKey") or code:find("[^%a]KeySystem[^%a]") then add("KeySystem:Function") end

  -- Text obfuscation
  if code:find("string%.char%(%d") then add("obf:string.char") end
  if code:find("\\x%x%x") then add("obf:hex-escape") end
  if code:find("{%d+,%d+,%d+") then add("obf:num-array") end
  if code:find("string%.reverse%(") then add("obf:string.reverse") end

  return #types>0 and table.concat(types,", ") or "plain/clean"
end

-- ── Key system removal ───────────────────────────────────────────────────────
local function keyrm(code)
  -- Junkie SDK header (top-of-file, up to 6 lines)
  code = code:gsub("^local%s+%w+%s*=%s*loadstring%b()%(%)%s*\n[^\n]*\n[^\n]*\n[^\n]*\n?", "")
  -- Junkie inline loadstring calls
  code = code:gsub('loadstring%s*%(%s*game:HttpGet%s*%(%s*"https?://[^"]*jnkie[^"]*"%s*%)%s*%)%s*%(%)','')
  -- Junkie key UI block: (function()...Junkie.check_key|JunkieKeySystemUI...end)()
  code = code:gsub("local%s+result%s*=%s*%(function%(%)(.-)end%)%(%)","", 1)
  -- Linkvertise redirect block
  code = code:gsub('if%s+not%s+pcall%s*%(function%(%)[^\n]*Linkvertise[^\n]*\n.-end%)%s*then\n.-end%s*\n',"")
  -- Generic getgenv()/getrenv() key check
  for _, fn in ipairs({"getgenv", "getrenv"}) do
    code = code:gsub("if%s+"..fn.."%s*%(%)%.%w*[Kk]ey%w*%s*~=%s*\"[^\"]*\"%s*then.-end%s*\n","")
  end
  -- KeySystem require/call pattern
  for _, m in ipairs({"checkKey","verifyKey","KeySystem","check_key"}) do
    code = code:gsub('require%s*%(%s*[%d]+%s*%)%s*:%s*'..m..'%s*%([^%)]*%)', "-- key check removed")
  end
  -- getgenv().WHITELIST check block
  code = code:gsub("local%s+%w+%s*=%s*false%s*\nfor%s+.-%sdo.-%sif.-%swhitelist.-%sthen.-%send.-%send","")
  return code:match("^%s*(.-)%s*$") or code
end

-- ── Deep deobfuscation (execute + capture layers) ────────────────────────────
local function deep_deob(code)
  setup_roblox_stubs()

  local layers = {}
  local seen = {}

  local function record(s)
    if type(s)~="string" or #s<20 then return end
    if seen[s] then return end
    seen[s] = true
    layers[#layers+1] = s
  end

  local _load_orig = load
  local _ls_orig   = loadstring

  local function hook(s, ...)
    record(s)
    local fn
    local ok, res = pcall(_load_orig or _ls_orig, s, ...)
    if ok and type(res)=="function" then fn = res end
    return fn or function() end
  end

  if load     then load      = hook end
  if loadstring then loadstring = hook end

  -- sandbox
  local env = setmetatable({
    print=function()end, warn=function()end, error=error,
    pairs=pairs, ipairs=ipairs, next=next, select=select,
    type=type, tostring=tostring, tonumber=tonumber,
    rawget=rawget, rawset=rawset, rawequal=rawequal,
    setmetatable=setmetatable, getmetatable=getmetatable,
    unpack=unpack or table.unpack,
    string=string, table=table, math=math,
    pcall=pcall, xpcall=xpcall, assert=assert,
    load=hook, loadstring=hook,
    game=game, workspace=workspace, script=script, shared=shared,
    getfenv=getfenv, setfenv=setfenv, newproxy=newproxy,
    bit=bit, task=task, wait=wait,
    getgenv=function() return _G end,
    getrenv=function() return _G end,
    _G=_G, coroutine=coroutine,
    syn=syn, Drawing=Drawing,
    writefile=writefile, readfile=readfile, isfile=isfile,
    request=request,
  }, {__index=_G})

  -- apply text deob first
  local prepped = (deob(code))

  -- try to load and run
  local fn, err
  if load then
    fn, err = load(prepped, "deep_deob", "t", env)
  elseif loadstring then
    fn, err = loadstring(prepped)
    if fn and setfenv then setfenv(fn, env) end
  end
  if fn then pcall(fn) end

  -- restore
  if _load_orig then load = _load_orig end
  if _ls_orig   then loadstring = _ls_orig end

  return layers
end

-- ── VM trace ─────────────────────────────────────────────────────────────────
local function vm_trace(src)
  setup_roblox_stubs()

  local trace = {}
  local count = 0
  local MAX = 1000
  local captured = {}

  debug.sethook(function(ev, line)
    count = count + 1
    if count > MAX then debug.sethook() return end
    local info = debug.getinfo(2, "nSl")
    trace[#trace+1] = {
      n    = count,
      ev   = ev,
      name = info and info.name or "?",
      what = info and info.what or "?",
      src  = info and (info.short_src or info.source) or "?",
      line = info and info.currentline or 0,
    }
  end, "clr")

  local function hook_load(s, ...)
    if type(s)=="string" and #s>10 then captured[#captured+1]=s end
    local orig = _G.load or _G.loadstring
    local ok, fn = pcall(orig, s, ...)
    if ok and type(fn)=="function" then return fn end
    return function() end
  end

  local _orig_load = load
  local _orig_ls   = loadstring
  if load       then load       = hook_load end
  if loadstring then loadstring = hook_load end

  pcall(load or loadstring, src)
  debug.sethook()

  if _orig_load then load       = _orig_load end
  if _orig_ls   then loadstring = _orig_ls   end

  -- Print trace
  print(string.format("=== VM TRACE (%d events%s) ===", #trace, count>MAX and " — capped" or ""))
  print(string.format("%-5s %-8s %-22s %-8s %-40s %s", "#","EVENT","FUNCTION","TYPE","SOURCE","LINE"))
  print(string.rep("-", 95))
  for _, t in ipairs(trace) do
    local s = t.src:sub(1,40)
    print(string.format("%-5d %-8s %-22s %-8s %-40s %s",
      t.n, t.ev, (t.name or "?"):sub(1,22), (t.what or "?"):sub(1,8), s, t.line))
  end

  if #captured > 0 then
    print(string.format("\n=== CAPTURED SOURCES (%d) ===", #captured))
    for i, s in ipairs(captured) do
      local hdr = s:sub(1,4)
      local is_bc = hdr=="\x1bLua"
      print(string.format("--- Layer %d: %s (%d bytes) ---", i, is_bc and "BYTECODE" or "source", #s))
      if is_bc then
        print("[Binary Lua 5.1 bytecode]")
      else
        print(s:sub(1,3000))
        if #s>3000 then print("[... truncated]") end
      end
    end
  end
end

-- ── Luraph v14 base85 blob decoder ───────────────────────────────────────────
-- Luraph v14.x stores its payload as custom base85 inside [=[ ... ]=].
-- Encoding: each group of 5 chars (offset by 33) decodes to a big-endian uint32.
-- "z" is a run-length alias for "!!!!!" (base85 zero-word).
-- The blob starts with a 4-byte header we skip (q=5 means start at char 5).

local function luraph_b85_decode(blob, offset)
  local data = blob:sub(offset)        -- skip header bytes
  data = data:gsub("z", "!!!!!")       -- expand zero-word alias
  local out = {}
  local i = 1
  while i + 4 <= #data do
    local M,N,S,C,A = data:byte(i, i+4)
    M=M-33; N=N-33; S=S-33; C=C-33; A=A-33
    if M<0 or N<0 or S<0 or C<0 or A<0 then break end
    local b = M*52200625 + N*614125 + S*7225 + C*85 + A
    out[#out+1] = string.char(
      math.floor(b/16777216)%256,
      math.floor(b/65536)%256,
      math.floor(b/256)%256,
      b%256
    )
    i = i + 5
  end
  return table.concat(out)
end

local function luraph_find_bytecode(src)
  -- Collect all long-string blobs
  local blobs = {}
  for blob in src:gmatch("%[=%[(.-)%]=%]") do
    blobs[#blobs+1] = blob
  end
  if #blobs == 0 then return nil, "no [=[ blobs found" end

  io.stderr:write(string.format("[luraph] found %d blob(s), scanning for Lua 5.1 magic...\n", #blobs))

  for bi, blob in ipairs(blobs) do
    -- Try all reasonable offsets (Luraph sets q=5 normally, q=20 when tampered)
    for offset = 1, 25 do
      if offset > #blob - 9 then break end
      local bc = luraph_b85_decode(blob, offset)
      if #bc >= 12
        and bc:byte(1)==0x1b and bc:byte(2)==0x4c
        and bc:byte(3)==0x75 and bc:byte(4)==0x61
        and bc:byte(5)==0x51 then
        io.stderr:write(string.format("[luraph] blob #%d offset=%d → valid Lua 5.1 bytecode (%d bytes)\n",
          bi, offset, #bc))
        return bc, bi, offset
      end
    end
  end
  return nil, "no valid Lua 5.1 bytecode found in any blob (wrong version or tampered)"
end

-- ── Lua 5.1 bytecode disassembler ────────────────────────────────────────────
local LUA51_OPS = {
  [0]="MOVE","LOADK","LOADBOOL","LOADNIL","GETUPVAL","GETGLOBAL","GETTABLE",
  "SETGLOBAL","SETUPVAL","SETTABLE","NEWTABLE","SELF",
  "ADD","SUB","MUL","DIV","MOD","POW","UNM","NOT","LEN","CONCAT",
  "JMP","EQ","LT","LE","TEST","TESTSET",
  "CALL","TAILCALL","RETURN",
  "FORLOOP","FORPREP","TFORLOOP","SETLIST",
  "CLOSE","CLOSURE","VARARG",
}

local function lua51_disasm(bc)
  local p = 1
  local le = true

  local function u8()
    local v = bc:byte(p); p=p+1; return v or 0
  end
  local function u32()
    local a,b_,c,d = bc:byte(p,p+3); p=p+4
    a=a or 0; b_=b_ or 0; c=c or 0; d=d or 0
    if le then return a + b_*256 + c*65536 + d*16777216
    else       return d + c*256 + b_*65536 + a*16777216 end
  end
  local function f64() p=p+8; return 0 end
  local function lstr()
    local len = u32(); if len==0 then return nil end
    local s = bc:sub(p, p+len-2); p=p+len; return s
  end

  -- header
  if bc:sub(1,4)~="\x1bLua" then return nil,"bad magic" end
  p=5; u8(); u8(); le=(u8()==1); u8(); u8(); u8(); u8(); u8()

  local funcs = {}
  local strings_seen = {}
  local all_strings = {}

  local function parse(depth, fn_idx)
    local fn = {depth=depth, idx=fn_idx}
    fn.src        = lstr() or "?"
    fn.line_s     = u32(); fn.line_e = u32()
    fn.nups       = u8();  fn.nparams = u8()
    fn.isvararg   = u8();  fn.maxstack = u8()

    -- code
    fn.code = {}
    local nc = u32()
    for i=1,nc do fn.code[i]=u32() end

    -- constants
    fn.k = {}
    local nk = u32()
    for i=1,nk do
      local t = u8()
      if     t==0 then fn.k[i]={t="nil",v="nil"}
      elseif t==1 then fn.k[i]={t="bool",v=u8()==1 and "true" or "false"}
      elseif t==3 then f64(); fn.k[i]={t="num",v="<num>"}
      elseif t==4 then
        local s=lstr() or ""
        fn.k[i]={t="str",v=s}
        if #s>0 and not strings_seen[s] then
          strings_seen[s]=true; all_strings[#all_strings+1]=s
        end
      else fn.k[i]={t="?",v="?"} end
    end

    -- nested protos
    fn.protos={}
    local np=u32()
    for i=1,np do fn.protos[i]=parse(depth+1, i-1) end

    -- debug: line info
    fn.lines={}; local nl=u32()
    for i=1,nl do fn.lines[i]=u32() end

    -- debug: locals
    fn.locals={}; local nlo=u32()
    for i=1,nlo do fn.locals[i]={name=lstr() or "?", s=u32(), e=u32()} end

    -- debug: upvalues
    fn.ups={}; local nu=u32()
    for i=1,nu do fn.ups[i]=lstr() or "?" end

    funcs[#funcs+1]=fn
    return fn
  end

  local ok,err = pcall(function() parse(0,0) end)
  if not ok then return nil, err end

  -- Format output
  local lines = {}
  local function emit(s) lines[#lines+1]=s end

  emit(string.format("=== Lua 5.1 Bytecode Disassembly (%d bytes, %d functions) ===",
    #bc, #funcs))
  emit("")

  -- Strings section (most useful for understanding what the script does)
  emit(string.format("── String constants (%d) ──", #all_strings))
  -- Sort by length desc, then alpha
  table.sort(all_strings, function(a,b)
    if #a ~= #b then return #a > #b end
    return a < b
  end)
  for i,s in ipairs(all_strings) do
    local display = s:gsub("[%c]", function(c) return string.format("\\%d", c:byte()) end)
    emit(string.format("  [%d] %q", i, display))
    if i >= 500 then emit("  ... ("..#all_strings-500 .." more strings)"); break end
  end
  emit("")

  -- Per-function summary
  emit(string.format("── Functions (%d) ──", #funcs))
  for _, fn in ipairs(funcs) do
    local pad = string.rep("  ", fn.depth)
    local src = fn.src:match("^@?(.*)") or fn.src
    emit(string.format("%sfunction [%d] %s  params=%d ups=%d stack=%d instrs=%d consts=%d protos=%d",
      pad, fn.idx, src, fn.nparams, fn.nups, fn.maxstack,
      #fn.code, #fn.k, #fn.protos))

    -- Instructions
    for i, raw in ipairs(fn.code) do
      local op    = raw & 0x3F
      local A     = (raw >> 6) & 0xFF
      local C     = (raw >> 14) & 0x1FF
      local B     = (raw >> 23) & 0x1FF
      local Bx    = (raw >> 14) & 0x3FFFF
      local sBx   = Bx - 131071
      local opname = LUA51_OPS[op] or ("OP_"..op)
      local ln    = fn.lines[i] or 0

      -- Human-readable arg
      local rk = function(x)
        if x >= 256 then
          local k=fn.k[x-255]; return k and (k.t=="str" and string.format("%q",k.v) or k.v) or "K?"
        end
        local loc=fn.locals[x+1]; return loc and loc.name or ("R"..x)
      end
      local lname = function(x) local l=fn.locals[x+1]; return l and l.name or ("R"..x) end
      local kname = function(x) local k=fn.k[x+1]; return k and (k.t=="str" and string.format("%q",k.v) or k.v) or "K"..x end

      local args
      if     opname=="MOVE"      then args=lname(A).." = "..lname(B)
      elseif opname=="LOADK"     then args=lname(A).." = "..kname(Bx)
      elseif opname=="LOADBOOL"  then args=lname(A).." = "..(B~=0 and "true" or "false")..(C~=0 and "; skip" or "")
      elseif opname=="LOADNIL"   then args=lname(A)..".."..lname(B).." = nil"
      elseif opname=="GETUPVAL"  then args=lname(A).." = UP["..B.."]"..(fn.ups[B+1] and "("..fn.ups[B+1]..")" or "")
      elseif opname=="GETGLOBAL" then args=lname(A).." = _G["..kname(Bx).."]"
      elseif opname=="GETTABLE"  then args=lname(A).." = "..lname(B).."["..rk(C).."]"
      elseif opname=="SETGLOBAL" then args="_G["..kname(Bx).."] = "..lname(A)
      elseif opname=="SETUPVAL"  then args="UP["..B.."] = "..lname(A)
      elseif opname=="SETTABLE"  then args=lname(A).."["..rk(B).."] = "..rk(C)
      elseif opname=="NEWTABLE"  then args=lname(A).." = {}"
      elseif opname=="SELF"      then args=lname(A+1).." = "..lname(B).."; "..lname(A).." = "..lname(B).."["..rk(C).."]"
      elseif opname=="ADD"       then args=lname(A).." = "..rk(B).." + "..rk(C)
      elseif opname=="SUB"       then args=lname(A).." = "..rk(B).." - "..rk(C)
      elseif opname=="MUL"       then args=lname(A).." = "..rk(B).." * "..rk(C)
      elseif opname=="DIV"       then args=lname(A).." = "..rk(B).." / "..rk(C)
      elseif opname=="MOD"       then args=lname(A).." = "..rk(B).." % "..rk(C)
      elseif opname=="POW"       then args=lname(A).." = "..rk(B).." ^ "..rk(C)
      elseif opname=="UNM"       then args=lname(A).." = -"..lname(B)
      elseif opname=="NOT"       then args=lname(A).." = not "..lname(B)
      elseif opname=="LEN"       then args=lname(A).." = #"..lname(B)
      elseif opname=="CONCAT"    then args=lname(A).." = "..lname(B)..".."..lname(C)
      elseif opname=="JMP"       then args="→ "..(i+sBx)
      elseif opname=="EQ"        then args="if "..rk(B).."==".."rk(C).."..(A~=0 and " skip" or "")
      elseif opname=="LT"        then args="if "..rk(B).."<"..rk(C)..(A~=0 and " skip" or "")
      elseif opname=="LE"        then args="if "..rk(B).."<="..rk(C)..(A~=0 and " skip" or "")
      elseif opname=="TEST"      then args="if bool("..lname(A)..") != "..C.." skip"
      elseif opname=="TESTSET"   then args="if "..lname(B).." then "..lname(A).."="..lname(B)
      elseif opname=="CALL"      then args=lname(A).."("..lname(A+1).."…) → "..(C>1 and (C-1).." ret" or "…ret")
      elseif opname=="TAILCALL"  then args="return "..lname(A).."(…)"
      elseif opname=="RETURN"    then args="return "..(B>1 and lname(A) or "()")
      elseif opname=="FORLOOP"   then args=lname(A).."+= "..lname(A+2).." → "..(i+sBx)
      elseif opname=="FORPREP"   then args=lname(A).."-= "..lname(A+2).." → "..(i+sBx)
      elseif opname=="TFORLOOP"  then args="tfor "..lname(A)
      elseif opname=="SETLIST"   then args=lname(A).."["..(C>0 and (C-1)*50+1 or "?").."+] = R…"
      elseif opname=="CLOSE"     then args="close upvals ≥"..lname(A)
      elseif opname=="CLOSURE"   then args=lname(A).." = closure[Proto"..Bx.."]"
      elseif opname=="VARARG"    then args=lname(A)..".."..lname(A+B-2).." = ..."
      else                            args=string.format("A=%d B=%d C=%d", A, B, C)
      end

      emit(string.format("%s  %5d [%4d]  %-12s  %s", pad, i-1, ln, opname, args))
    end
  end

  return table.concat(lines, "\n")
end

-- ── Dispatch ─────────────────────────────────────────────────────────────────
if mode == "detect" then
  print(detect(src))

elseif mode == "keyrm" then
  io.write(keyrm(src))

elseif mode == "trace" then
  vm_trace(src)

elseif mode == "deep" then
  -- Strip key first, text deob, then execute and capture layers
  local stripped = keyrm(src)
  local prepped, passes = deob(stripped)
  if #passes > 0 then
    io.stderr:write("text passes: " .. table.concat(passes, ", ") .. "\n")
  end
  local layers = deep_deob(prepped)
  if #layers == 0 then
    io.stderr:write("no inner layers captured — outputting text-deobfuscated source\n")
    io.write(prepped)
  else
    io.stderr:write(string.format("captured %d layer(s)\n", #layers))
    for i, layer in ipairs(layers) do
      io.stderr:write(string.format("=== Layer %d (%d bytes) ===\n", i, #layer))
      -- deob each captured layer
      local ld, lp = deob(layer)
      if #lp > 0 then io.stderr:write("  passes: "..table.concat(lp,", ").."\n") end
      -- output the deepest (last) layer as the result; print all to stderr
      if i < #layers then
        io.stderr:write(ld:sub(1,500)..(#ld>500 and "\n[...]\n" or "\n"))
      else
        io.write(ld)
      end
    end
  end

elseif mode == "luraph" then
  local bc, blob_idx, offset = luraph_find_bytecode(src)
  if not bc then
    io.stderr:write("[luraph] ERROR: " .. tostring(blob_idx) .. "\n")
    os.exit(1)
  end
  io.stderr:write(string.format("[luraph] blob #%d offset=%d → %d bytes Lua 5.1 bytecode\n", blob_idx, offset, #bc))
  local dis, err2 = lua51_disasm(bc)
  if dis then
    io.write(dis)
  else
    io.stderr:write("[luraph] disasm error: " .. tostring(err2) .. "\n")
    io.write(bc)
  end

else -- deob (default)
  local prepped = keyrm(src)
  local result, passes = deob(prepped)
  if #passes > 0 then
    io.stderr:write("passes: " .. table.concat(passes, ", ") .. "\n")
  end
  io.write(result)
end
