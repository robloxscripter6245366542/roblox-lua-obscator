-- luau-vm/test/fuse_test.lua
-- Superoperators (obfuscate.fuse): runs of pure instructions are fused into
-- single SUPEROP macro-ops so the bytecode no longer decomposes 1:1 into Lua
-- ops. Fusing must be exactly semantics-preserving through the direct VM, the
-- serialize->deserialize path, and the runtime seal layer -- and must actually
-- produce SUPEROPs while never fusing across a jump target.

package.path = 'src/?.lua;' .. package.path
local API = require('api')
local VM = require('vm')
local Compiler = require('compiler')
local Harden = require('harden')
local Obf = require('obfuscate')
local Ser = require('serializer')
local Val = require('validate')
local Seal = require('seal')
local Op = require('opcodes').Op

local pass, fail = 0, 0
local function ok(c, m) if c then pass = pass + 1 else fail = fail + 1; print('FAIL ' .. m) end end

local function runNative(s)
  local f = (load or loadstring)(s); local p = table.pack(pcall(f))
  local o = {}; for i = 2, p.n do o[#o + 1] = tostring(p[i]) end
  return p[1] and table.concat(o, '|') or 'ERR'
end
local function runProto(proto)
  local p = table.pack(pcall(VM.load(proto, _G)))
  local o = {}; for i = 2, p.n do o[#o + 1] = tostring(p[i]) end
  return p[1] and table.concat(o, '|') or 'ERR'
end

local progs = {
  'local function f(n) if n<2 then return n end return f(n-1)+f(n-2) end return f(16)',
  'local s=0 for i=1,80 do s=s+i*i-i//2 end return s',
  'local t={} for i=1,20 do t[i]=i*3+1 end local u=0 for _,v in ipairs(t) do u=u+v end return u',
  'local a,b,c=1,2,3 a=b+c b=a*c-1 c=a+b-a//b return a,b,c',
  'local m=setmetatable({},{__index=function(_,k) return #k end}) return m.hello,("ab"):rep(3)',
  'local x=5 local y=x>3 and "big" or "small" local z=("a".."b").."c" return y,z,#z',
  'local n,c=6,1 repeat c=c*n n=n-1 until n==0 return c',
  'local function mk() local k=0 return function() k=k+1 return k*10-3 end end local g=mk() return g(),g(),g()',
  'local p,q=10,3 return p+q,p-q,p*q,p/q,p%q,p//q,p^q',
  'return ("Hello, World"):lower():upper():sub(1,5)',
}

-- 1. correctness through direct / serialized / sealed paths, across run lengths
for i, src in ipairs(progs) do
  local nat = runNative(src)
  local allok = true
  for _, mr in ipairs({ 2, 3, 4, 5 }) do
    local sk = mr * 131 + i
    local p1 = Compiler.compile(src); Obf.fuse(p1, Harden.prng(sk), { maxRun = mr })
    if not Val.proto(p1) or runProto(p1) ~= nat then allok = false end
    local p2 = Compiler.compile(src); Obf.fuse(p2, Harden.prng(sk), { maxRun = mr })
    local p2b = Ser.deserialize(Ser.serialize(p2))
    if not Val.proto(p2b) or runProto(p2b) ~= nat then allok = false end
    local p3 = Compiler.compile(src); Obf.fuse(p3, Harden.prng(sk), { maxRun = mr }); Seal.seal(p3, 4242)
    if runProto(p3) ~= nat then allok = false end
  end
  ok(allok, 'fuse correct (direct+serialized+sealed) #' .. i)
end

-- 2. SUPEROPs are actually produced
do
  local proto = Compiler.compile(progs[2]); Obf.fuse(proto, Harden.prng(1), { maxRun = 5 })
  local n = 0
  for _, ins in ipairs(proto.code) do if ins.op == Op.SUPEROP then n = n + 1 end end
  ok(n > 0, 'fuse produces SUPEROP macro-ops (' .. n .. ')')
end

-- 3. never fuse across a jump target: every jump still lands on a real op, and
--    no SUPEROP sub is a control/impure opcode (validator enforces the latter).
do
  local proto = Compiler.compile(progs[1]); Obf.fuse(proto, Harden.prng(7), { maxRun = 5 })
  local okv, err = Val.proto(proto)
  ok(okv, 'fused proto validates (jumps land on whole ops, subs are pure)' .. (okv and '' or ': ' .. tostring(err)))
end

-- 4. determinism per seed
do
  local function sig(p, acc)
    acc = acc or {}
    for _, ins in ipairs(p.code) do
      acc[#acc + 1] = ins.op .. ':' .. (ins.subs and #ins.subs or 0)
    end
    for _, c in ipairs(p.protos) do sig(c, acc) end
    return table.concat(acc, ',')
  end
  local a = Compiler.compile(progs[3]); Obf.fuse(a, Harden.prng(555), { maxRun = 4 })
  local b = Compiler.compile(progs[3]); Obf.fuse(b, Harden.prng(555), { maxRun = 4 })
  ok(sig(a) == sig(b), 'fuse is deterministic for a fixed seed')
end

print(string.format('fuse_test: %d passed, %d failed', pass, fail))
os.exit(fail == 0 and 0 or 1)
