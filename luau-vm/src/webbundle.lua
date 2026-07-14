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
  -- 4. encrypt the whole blob with a keystream seeded off the same build seed.
  local proto = Compiler.compile(src, chunkName or 'input')
  local fwd, inv = Harden.opPermutation(Opcodes.count, rng)
  local plain = Serializer.serialize(proto, fwd)
  local cipherSeed = rng.next() % 2147483647
  if cipherSeed <= 0 then cipherSeed = cipherSeed + 2147483646 end
  local cipher = Harden.encrypt(plain, cipherSeed)
  local payload = b64encode(cipher)

  local keyExpr = Harden.factorKey(cipherSeed, rng)
  local invLit = Harden.invMapLiteral(inv)

  local order = { 'opcodes', 'bitops', 'serializer', 'vm' }
  local parts = {}
  -- banner (ASCII only — the browser build ASCII-sanitizes this source)
  parts[#parts + 1] = '-- ================================================================'
  parts[#parts + 1] = '--  Obfuscated by Granite Lock  |  https://granitelock.com'
  parts[#parts + 1] = '--  Custom bytecode VM  |  encrypted  |  no loadstring'
  parts[#parts + 1] = '-- ================================================================'
  parts[#parts + 1] = 'local __m,__c={},{}'
  parts[#parts + 1] = 'local function require(n) if __c[n]==nil then __c[n]=__m[n]() end return __c[n] end'
  for _, name in ipairs(order) do
    local s = runtimeSrc[name]
    if not s then error('webbundle: missing runtime source for ' .. name) end
    parts[#parts + 1] = "__m['" .. name .. "']=function()\n" .. safeStrip(s) .. '\nend'
  end
  -- base64 decoder + keystream decryptor + bootstrap
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
    'local function __dec(s)',
    '  local st=' .. keyExpr,
    '  local o={}',
    '  for i=1,#s do st=(st*16807)%2147483647 o[i]=string.char(__Bit.bxor(s:byte(i),st%256)) end',
    '  return table.concat(o)',
    'end',
    'local __INV=' .. invLit,
    'local __Ser=require("serializer")',
    'local __VM=require("vm")',
    'local __proto=__Ser.deserialize(__dec(__b64(__PAYLOAD__)),__INV)',
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
