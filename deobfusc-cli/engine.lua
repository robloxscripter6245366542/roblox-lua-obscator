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
  if code:find("%bPSU%b") and code:find("loadstring") then add("PSU") end

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
  if code:find("%b%%checkKey") or code:find("%bverifyKey") or code:find("%bKeySystem") then add("KeySystem:Function") end

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
  -- Generic getgenv().Key check
  code = code:gsub("if%s+(?:getgenv|getrenv)%(%)%.%w*[Kk]ey%w*%s*~=%s*\"[^\"]*\"%s*then.-end%s*\n","")
  -- KeySystem require/call pattern
  code = code:gsub('require%s*%(%s*[%d]+%s*%)%s*:%s*(?:checkKey|verifyKey|KeySystem)%s*%([^%)]*%)', "-- key check removed")
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

else -- deob (default)
  local prepped = keyrm(src)
  local result, passes = deob(prepped)
  if #passes > 0 then
    io.stderr:write("passes: " .. table.concat(passes, ", ") .. "\n")
  end
  io.write(result)
end
