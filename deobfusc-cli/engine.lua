-- deobfusc engine — run by the bash CLI
-- Usage: lua engine.lua <mode> [file]
-- Modes: deob | detect | keyrm | trace

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

-- ── Roblox stubs (for VM mode) ───────────────────────────────────────────────
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
  game      = stub
  workspace = stub
  script    = stub
  shared    = stub
  _G        = _G or {}
  -- Lua 5.4 removed getfenv/setfenv
  if not getfenv then getfenv = function(n) return _ENV end end
  if not setfenv then setfenv = function(n, t) end end
  if not newproxy then newproxy = function() return {} end end
  -- bit library shim
  if not bit then
    bit = {
      bxor   = function(a,b) local r,p=0,1 while a>0 or b>0 do if a%2~=b%2 then r=r+p end a=math.floor(a/2) b=math.floor(b/2) p=p*2 end return r end,
      band   = function(a,b) local r,p=0,1 while a>0 and b>0 do if a%2+b%2>=2 then r=r+p end a=math.floor(a/2) b=math.floor(b/2) p=p*2 end return r end,
      bor    = function(a,b) local r,p=0,1 while a>0 or b>0 do if a%2+b%2>0 then r=r+p end a=math.floor(a/2) b=math.floor(b/2) p=p*2 end return r end,
      bnot   = function(a) return -(a+1) end,
      lshift = function(a,b) return math.floor(a*(2^b)) end,
      rshift = function(a,b) return math.floor(a/(2^b)) end,
    }
  end
end

-- ── Text deobfuscation passes ────────────────────────────────────────────────
local function deob(code)
  local passes = {}

  -- hex escape \xHH
  local b = code
  code = code:gsub("\\x(%x%x)", function(h) return string.char(tonumber(h,16)) end)
  if code ~= b then passes[#passes+1]="hex-escape" end

  -- decimal escape \DDD
  b = code
  code = code:gsub("\\(%d%d?%d?)", function(d)
    local n = tonumber(d)
    return (n and n<=255) and string.char(n) or "\\"..d
  end)
  if code ~= b then passes[#passes+1]="dec-escape" end

  -- string.char(...)
  b = code
  code = code:gsub("string%.char%(([%d,%s]+)%)", function(args)
    local out = {}
    for n in args:gmatch("%d+") do
      local num = tonumber(n); if num then out[#out+1]=string.char(num) end
    end
    return '"'..table.concat(out)..'"'
  end)
  if code ~= b then passes[#passes+1]="string.char" end

  -- concat collapse (8 passes)
  b = code
  for _ = 1, 8 do code = code:gsub('"([^"\\]*)"%s*%.%.%s*"([^"\\]*)"','"%1%2"') end
  if code ~= b then passes[#passes+1]="concat-collapse" end

  return code, passes
end

-- ── Detection ────────────────────────────────────────────────────────────────
local function detect(code)
  local types = {}
  if code:lower():find("luraph") or code:lower():find("lura%.ph") then
    -- find version
    local ver = code:match("Luraph[^v]*v?(%d+%.%d+)")
    types[#types+1] = "Luraph" .. (ver and " v"..ver or "")
  end
  if code:lower():find("moonsec") then
    local ver = code:match("[Mm]oonsec%s*v?(%d+%.?%d*)")
    types[#types+1] = "Moonsec" .. (ver and " v"..ver or "")
  end
  if code:find("getfenv") and code:find("0x%x%x%x%x") then
    types[#types+1] = code:lower():find("ironbrew") and "IronBrew 2" or "IronBrew"
  end
  if code:lower():find("prometheus") then types[#types+1]="Prometheus" end
  if code:find("jnkie%.com") or code:find("Junkie%.") then types[#types+1]="KeySystem:Junkie" end
  if code:lower():find("keysystem") then types[#types+1]="KeySystem:Generic" end
  if code:find("string%.char%(%d") then types[#types+1]="string.char" end
  if code:find("\\x%x%x") then types[#types+1]="hex-escape" end
  return #types>0 and table.concat(types,", ") or "plain/clean"
end

-- ── Key system removal ───────────────────────────────────────────────────────
local function keyrm(code)
  -- Junkie SDK header (top-of-file)
  code = code:gsub("^local%s+%w+%s*=%s*loadstring%b()%(%)%s*\n[^\n]*\n[^\n]*\n[^\n]*\n?", "")
  -- Junkie inline loadstring calls
  code = code:gsub('loadstring%s*%(%s*game:HttpGet%s*%(%s*"https?://[^"]*jnkie[^"]*"%s*%)%s*%)%s*%(%)','')
  -- Strip result=(function()...end)() blocks containing key check
  -- (simplified: remove from "local result = (function()" to matching "end)()")
  code = code:gsub("local%s+result%s*=%s*%(function%(%)(.-)end%)%(%)","", 1)
  return code:match("^%s*(.-)%s*$") or code
end

-- ── VM trace ─────────────────────────────────────────────────────────────────
local function vm_trace(code)
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

  local _orig = load
  load = function(s, ...)
    if type(s)=="string" and #s>10 then captured[#captured+1]=s end
    local ok, fn = pcall(_orig, s, ...)
    if ok and type(fn)=="function" then return fn end
    return function() end
  end
  -- Lua 5.1 compat
  if loadstring then
    local _ols = loadstring
    loadstring = function(s, ...)
      if type(s)=="string" and #s>10 then captured[#captured+1]=s end
      local ok, fn = pcall(_ols, s, ...)
      if ok and type(fn)=="function" then return fn end
      return function() end
    end
  end

  pcall(load or loadstring, code)
  debug.sethook()

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
        print("[Binary Lua 5.1 bytecode — use --disasm or paste into web tool]")
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

else -- deob (default)
  local result, passes = deob(src)
  if #passes > 0 then
    io.stderr:write("passes: " .. table.concat(passes, ", ") .. "\n")
  end
  io.write(result)
end
