-- luau-vm/test/seal_test.lua
-- Tests for the runtime sealed/streamed code layer (seal.lua) and instruction
-- mutation (harden.opMutationMap): sealed execution must match unsealed/native,
-- the session key must be ephemeral (different in-memory bytes, same result),
-- and the mutation map must be a valid many-to-one alias mapping.

package.path = 'src/?.lua;' .. package.path
local API = require('api')
local VM = require('vm')
local Seal = require('seal')
local Harden = require('harden')
local Opcodes = require('opcodes')

local pass, fail = 0, 0
local function ok(c, m) if c then pass = pass + 1 else fail = fail + 1; print('FAIL ' .. m) end end

local function runNative(src)
  local f = (load or loadstring)(src); local p = table.pack(pcall(f))
  local o = {}; for i = 2, p.n do o[#o + 1] = tostring(p[i]) end
  return (p[1] and table.concat(o, '|') or 'ERR')
end
local function runSealed(src, sk)
  local proto = API.compile(src)
  Seal.seal(proto, sk)
  local p = table.pack(pcall(VM.load(proto, _G)))
  local o = {}; for i = 2, p.n do o[#o + 1] = tostring(p[i]) end
  return (p[1] and table.concat(o, '|') or 'ERR')
end

local progs = {
  'local function f(n) if n<2 then return n end return f(n-1)+f(n-2) end return f(12)',
  'local s=0 for i=1,50 do s=s+i*i end return s',
  'local t=setmetatable({},{__index=function(_,k) return k*3 end}) return t[7], #({1,2,3})',
  'local function mk() local c=0 return function() c=c+1 return c end end local g=mk() return g(),g(),g()',
  'local function v(...) return select("#",...), ... end return v("a","b","c")',
  'local ok,e=pcall(function() error("x") end) return ok, type(e)',
  'local a,b=1,2 a,b=b,a return a,b',
  'return ("Hello"):lower(), 10//3, 2^8',
}

-- 1. sealed execution == native, and independent of the (ephemeral) session key
for i, src in ipairs(progs) do
  local nat = runNative(src)
  ok(runSealed(src, 12345) == nat, 'sealed==native #' .. i .. ' (sk=12345)')
  ok(runSealed(src, 999999) == nat, 'sealed==native #' .. i .. ' (sk=999999)')
end

-- 2. different session keys => different encrypted bytes (ephemeral), same result
do
  local p1 = API.compile(progs[1]); Seal.seal(p1, 111)
  local p2 = API.compile(progs[1]); Seal.seal(p2, 222)
  ok(p1.code == nil and p2.code == nil, 'plaintext code dropped after seal')
  ok(p1.sealed.slices[1] ~= p2.sealed.slices[1], 'different session keys => different sealed bytes')
end

-- 3. seal/decode round-trips every instruction of a proto
do
  local proto = API.compile('local s=0 for i=1,3 do s=s+i end return s')
  local orig = {}
  for i, ins in ipairs(proto.code) do orig[i] = ins end
  local n = #proto.code
  Seal.seal(proto, 424242)
  local allmatch = true
  for i = 1, n do
    local d = Seal.decode(proto.sealed, i)
    local o = orig[i]
    if d.op ~= o.op or (d.a or 0) ~= (o.a or 0) or (d.b or 0) ~= (o.b or 0)
        or (d.bx or 0) ~= (o.bx or 0) or (d.sbx or 0) ~= (o.sbx or 0) then allmatch = false end
  end
  ok(allmatch, 'seal/decode round-trips all instructions')
end

-- 4. string constants are encrypted (not resident in plaintext) yet decode right
do
  local src = 'local url="https://secret.example/api" local name="RemoteFire" return url, name, #url'
  ok(runSealed(src, 55555) == runNative(src), 'sealed program with string constants == native')
  local proto = API.compile(src)
  -- capture the plaintext constants before sealing
  local plain = {}
  for i, v in ipairs(proto.consts) do plain[i] = v end
  Seal.seal(proto, 55555)
  -- the proxy must not expose any plaintext string in its backing storage
  local mt = getmetatable(proto.consts)
  ok(mt and type(mt.__index) == 'function', 'constants replaced by a decrypting proxy')
  -- accessing through the proxy returns the correct plaintext
  local allok = true
  for i, v in ipairs(plain) do
    if type(v) == 'string' and proto.consts[i] ~= v then allok = false end
  end
  ok(allok, 'encrypted constants decrypt to the original strings on access')
end

-- 5. mutation map: valid many-to-one aliasing within the byte budget
do
  local rng = Harden.prng(7)
  local fwd, inv = Harden.opMutationMap(Opcodes.count, rng, 3)
  local okmap, used = true, {}
  for op = 1, Opcodes.count do
    local list = fwd[op]
    if type(list) ~= 'table' or #list < 1 then okmap = false end
    for _, b in ipairs(list or {}) do
      if b < 1 or b > 255 or used[b] then okmap = false end
      used[b] = true
      if inv[b] ~= op then okmap = false end
    end
  end
  ok(okmap, 'opMutationMap: distinct alias bytes, each maps back to its op')
end

print(string.format('seal_test: %d passed, %d failed', pass, fail))
os.exit(fail == 0 and 0 or 1)
