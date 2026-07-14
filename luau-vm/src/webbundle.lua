-- luau-vm/src/webbundle.lua
-- Browser-friendly bundler: compile a Luau source string to a self-contained,
-- HARDENED VM-protected script. Unlike tools/bundle.lua it never touches the
-- filesystem; the runtime module sources are passed in (the website embeds
-- them), so this runs unchanged inside Fengari (Lua-in-JS) in the browser.
--
-- Hardening applied per build (see harden.lua): opcode permutation, bytecode
-- encryption (Park-Miller XOR keystream), a factored (non-literal) key, and
-- comment-stripped runtime sources. Still no loadstring, and the original
-- source is never reconstructed — the logic exists only as encrypted bytecode.

local Compiler = require('compiler')
local Serializer = require('serializer')
local Opcodes = require('opcodes')
local Harden = require('harden')

local M = {}

local B64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local function b64encode(data)
  local out, len = {}, #data
  for i = 1, len, 3 do
    local b1 = data:byte(i)
    local b2 = i + 1 <= len and data:byte(i + 1) or 0
    local b3 = i + 2 <= len and data:byte(i + 2) or 0
    local n = b1 * 65536 + b2 * 256 + b3
    out[#out + 1] = B64:sub(math.floor(n / 262144) % 64 + 1, math.floor(n / 262144) % 64 + 1)
    out[#out + 1] = B64:sub(math.floor(n / 4096) % 64 + 1, math.floor(n / 4096) % 64 + 1)
    out[#out + 1] = i + 1 <= len and B64:sub(math.floor(n / 64) % 64 + 1, math.floor(n / 64) % 64 + 1) or '='
    out[#out + 1] = i + 2 <= len and B64:sub(n % 64 + 1, n % 64 + 1) or '='
  end
  return table.concat(out)
end

-- Pick a per-build seed. Deterministic when opts.seed is given (tests); else
-- derived from wall clock + math.random so each build differs.
local function pickSeed(opts)
  if opts and opts.seed then return opts.seed end
  local t = (os and os.time and os.time()) or 0
  local r = math.random(1, 2147483646)
  local s = (t * 2654435761 + r) % 2147483647
  if s <= 0 then s = s + 2147483646 end
  return s
end

-- Strip comments from a runtime source, but only if the result still parses.
local function safeStrip(src)
  local stripped = Harden.stripComments(src)
  local chunk = (loadstring or load)(stripped)
  if chunk then return stripped end
  return src
end

-- runtimeSrc: table of Lua source strings for { opcodes, bitops, serializer, vm }.
function M.bundle(src, runtimeSrc, chunkName, opts)
  local seed = pickSeed(opts)
  local rng = Harden.prng(seed)

  -- 1. compile, 2. permute opcodes, 3. serialize with the permutation,
  -- 4. seal the whole blob with the custom multi-stage GraniteCipher (byte
  --    permutation -> S-box substitution -> chained stream mask -> checksum),
  --    all keyed off the same build seed.
  local proto = Compiler.compile(src, chunkName or 'input')
  local fwd, inv = Harden.opPermutation(Opcodes.count, rng)
  local plain = Serializer.serialize(proto, fwd)
  local sealed, cp = Harden.seal(plain, rng)
  local payload = b64encode(sealed)

  -- sub-seeds emitted as arithmetic expressions, not grep-able literals
  local permExpr = Harden.factorKey(cp.permSeed, rng)
  local sboxExpr = Harden.factorKey(cp.sboxSeed, rng)
  local maskExpr = Harden.factorKey(cp.maskSeed, rng)
  local invLit = Harden.invMapLiteral(inv)

  local order = { 'opcodes', 'bitops', 'serializer', 'vm' }
  local parts = {}
  -- banner (ASCII only — the browser build ASCII-sanitizes this source)
  parts[#parts + 1] = '-- ================================================================'
  parts[#parts + 1] = '--  Obfuscated by Granite Lock  |  https://granitelock.vercel.app'
  parts[#parts + 1] = '--  Custom bytecode VM  |  encrypted  |  no loadstring'
  parts[#parts + 1] = '-- ================================================================'
  parts[#parts + 1] = 'local __m,__c={},{}'
  parts[#parts + 1] = 'local function require(n) if __c[n]==nil then __c[n]=__m[n]() end return __c[n] end'
  for _, name in ipairs(order) do
    local s = runtimeSrc[name]
    if not s then error('webbundle: missing runtime source for ' .. name) end
    parts[#parts + 1] = "__m['" .. name .. "']=function()\n" .. safeStrip(s) .. '\nend'
  end
  -- base64 decoder + GraniteCipher unseal + bootstrap. The unseal inverts the
  -- build-time chain in reverse (checksum -> stream unmask -> inverse S-box ->
  -- inverse permutation), regenerating the S-box / permutation / keystream from
  -- the emitted sub-seeds alone. No loadstring; bytes -> proto tables directly.
  parts[#parts + 1] = table.concat({
    "local __A='" .. B64 .. "'",
    'local function __b64(s)',
    '  local r,v,b={},0,0',
    "  s=s:gsub('[^'..__A..'=]','')",
    '  for i=1,#s do',
    '    local c=s:sub(i,i)',
    "    if c=='=' then break end",
    '    local p=__A:find(c,1,true)',
    '    if not p then break end',
    '    v=v*64+(p-1) b=b+6',
    '    if b>=8 then b=b-8 r[#r+1]=string.char(math.floor(v/2^b)%256) v=v%(2^b) end',
    '  end',
    '  return table.concat(r)',
    'end',
    'local __Bit=require("bitops")',
    -- Park-Miller PRNG closure, identical stream to build-time Harden.prng.
    'local function __pr(sd)',
    '  local st=sd%2147483647 if st<=0 then st=st+2147483646 end',
    '  return function(n) st=(st*16807)%2147483647 if n then return st%n else return st end end',
    'end',
    'local __sealed=__b64(__PAYLOAD__)',
    -- (6) verify the custom integrity checksum over the ciphertext
    'local __c=__sealed:sub(5)',
    'local __h=5381',
    '  for i=1,#__c do __h=(__h*33+__c:byte(i))%4294967296 end',
    'local __want=__sealed:byte(1)*16777216+__sealed:byte(2)*65536+__sealed:byte(3)*256+__sealed:byte(4)',
    'if __h~=__want then error("granite: integrity check failed") end',
    'local __n=#__c',
    'local __t={}',
    '  for i=1,__n do __t[i]=__c:byte(i) end',
    -- (5) inverse stream masking (cipher-feedback chaining)
    'local __mr=__pr(' .. maskExpr .. ')',
    'local __prev=' .. cp.iv,
    '  for i=1,__n do local __k=__mr(256) local __cur=__t[i] __t[i]=__Bit.bxor(__Bit.bxor(__cur,__k),__prev) __prev=__cur end',
    -- (4) inverse byte substitution: rebuild the S-box, invert it, apply
    'local __sr=__pr(' .. sboxExpr .. ')',
    'local __sb={} for i=0,255 do __sb[i]=i end',
    '  for i=255,1,-1 do local j=__sr(i+1) __sb[i],__sb[j]=__sb[j],__sb[i] end',
    'local __is={} for i=0,255 do __is[__sb[i]]=i end',
    '  for i=1,__n do __t[i]=__is[__t[i]] end',
    -- (3) inverse byte permutation: regenerate swap partners, undo in order
    'local __ps={} do local __r=__pr(' .. permExpr .. ') for i=__n,2,-1 do __ps[i]=__r(i)+1 end end',
    '  for i=2,__n do __t[i],__t[__ps[i]]=__t[__ps[i]],__t[i] end',
    'local __bb={}',
    '  for i=1,__n do __bb[i]=string.char(__t[i]) end',
    'local __plain=table.concat(__bb)',
    'local __INV=' .. invLit,
    'local __Ser=require("serializer")',
    'local __VM=require("vm")',
    'local __proto=__Ser.deserialize(__plain,__INV)',
    -- Resolve the global environment for the VM. Roblox Luau has no _ENV, so we
    -- prefer an explicit _ENV where a runtime provides one (Lua 5.2+), else the
    -- Roblox/5.1 getfenv (pcall-guarded so a sandbox that errors on it can't
    -- break loading), else _G. getfenv appears only here in the tiny bootstrap,
    -- never in the interpreter loop, so Luau's getfenv deopt doesn't touch hot code.
    'local __env',
    'if type(_ENV)=="table" then __env=_ENV',
    'elseif getfenv then local __ok,__e=pcall(getfenv,1) __env=(__ok and type(__e)=="table") and __e or _G',
    'else __env=_G end',
    'return __VM.load(__proto,__env)()',
  }, '\n')
  local body = table.concat(parts, '\n')
  local out = body:gsub('__PAYLOAD__', function() return "'" .. payload .. "'" end)
  return out
end

return M
