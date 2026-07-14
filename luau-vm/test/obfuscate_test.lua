-- luau-vm/test/obfuscate_test.lua
-- Opaque-predicate injection (obfuscate.lua): injected bogus control flow must
-- (a) never change results across a range of build seeds, (b) actually inflate
-- the control-flow graph, and (c) leave the plaintext program unaffected when
-- disabled. Also exercises the end-to-end bundler path with opaque flow on.

package.path = 'src/?.lua;' .. package.path
local Compiler = require('compiler')
local VM = require('vm')
local Harden = require('harden')
local Opcodes = require('opcodes')
local Op = Opcodes.Op

local pass, fail = 0, 0
local function ok(c, m) if c then pass = pass + 1 else fail = fail + 1; print('FAIL ' .. m) end end

local function runNative(src)
  local f = (load or loadstring)(src); local p = table.pack(pcall(f))
  local o = {}; for i = 2, p.n do o[#o + 1] = tostring(p[i]) end
  return (p[1] and table.concat(o, '|') or 'ERR')
end
local function runObf(src, seed, density)
  local proto = Compiler.compile(src, 'x', { opaque = Harden.prng(seed), opaqueDensity = density or 400 })
  local p = table.pack(pcall(VM.load(proto, _G)))
  local o = {}; for i = 2, p.n do o[#o + 1] = tostring(p[i]) end
  return (p[1] and table.concat(o, '|') or 'ERR')
end

local progs = {
  'local function f(n) if n<2 then return n end return f(n-1)+f(n-2) end return f(15)',
  'local s=0 for i=1,100 do s=s+i*i end return s',
  'local t=setmetatable({},{__index=function(_,k) return k*3 end}) return t[7], #({1,2,3})',
  'local function mk() local c=0 return function() c=c+1 return c end end local g=mk() return g(),g(),g()',
  'local function v(...) return select("#",...), ... end return v("a","b","c")',
  'local ok,e=pcall(function() error("x") end) return ok, type(e)',
  'local a,b=1,2 a,b=b,a return a,b',
  'return ("Hello"):lower(), 10//3, 2^8',
  'local x=0 while x<10 do x=x+1 end return x',
  'local r={} for i=1,5 do r[i]=i*i end return table.concat(r,",")',
  'local n,c=5,1 repeat c=c*n n=n-1 until n==0 return c',
  'local function g(t) local s=0 for _,v in ipairs(t) do s=s+v end return s end return g({10,20,30})',
  'local m={x=1} function m:inc() self.x=self.x+1 return self.x end return m:inc(), m:inc()',
  'local s="" for i=1,3 do if i%2==0 then s=s.."e" else s=s.."o" end end return s',
}

-- 1. results are invariant under injection, across many seeds
for i, src in ipairs(progs) do
  local nat = runNative(src)
  local allok = true
  for _, sk in ipairs({ 1, 3, 7, 42, 1000, 65535, 999983 }) do
    if runObf(src, sk) ~= nat then allok = false end
  end
  ok(allok, 'opaque-injected result == native #' .. i)
end

-- 2. injection is deterministic for a fixed seed (reproducible builds)
do
  local a = Compiler.compile(progs[1], 'x', { opaque = Harden.prng(12345) })
  local b = Compiler.compile(progs[1], 'x', { opaque = Harden.prng(12345) })
  local function sig(p, acc)
    acc = acc or {}
    for _, ins in ipairs(p.code) do acc[#acc + 1] = ins.op .. ',' .. (ins.a or '') .. ',' .. (ins.sbx or '') end
    for _, c in ipairs(p.protos) do sig(c, acc) end
    return table.concat(acc, ';')
  end
  ok(sig(a) == sig(b), 'same seed => identical injected bytecode')
end

-- 3. injection actually inflates the control-flow graph (more jumps)
do
  local function jumps(p, n)
    n = n or 0
    for _, ins in ipairs(p.code) do
      if ins.op == Op.JMP or ins.op == Op.JMPIF or ins.op == Op.JMPIFNOT then n = n + 1 end
    end
    for _, c in ipairs(p.protos) do n = jumps(c, n) end
    return n
  end
  local src = progs[2]
  local plain = jumps(Compiler.compile(src))
  local obf = jumps(Compiler.compile(src, 'x', { opaque = Harden.prng(9), opaqueDensity = 600 }))
  ok(obf > plain, 'opaque injection adds control-flow edges (' .. plain .. ' -> ' .. obf .. ')')
end

-- 4. disabled by default (no opaque opt => byte-identical to a plain compile)
do
  local function sig(p, acc)
    acc = acc or {}
    for _, ins in ipairs(p.code) do acc[#acc + 1] = tostring(ins.op) end
    for _, c in ipairs(p.protos) do sig(c, acc) end
    return table.concat(acc, ';')
  end
  ok(sig(Compiler.compile(progs[1])) == sig(Compiler.compile(progs[1], 'x', {})),
    'no opaque opt => unchanged bytecode')
end

-- 4c. bytecode junk: unreachable dead opcodes preserve results + validate, both
-- directly and through serialize -> deserialize.
do
  local Obf = require('obfuscate')
  local Ser = require('serializer')
  local Val = require('validate')
  local allok = true
  for _, src in ipairs(progs) do
    local nat = runNative(src)
    for _, sk in ipairs({ 2, 13, 500, 123457 }) do
      local proto = Compiler.compile(src)
      Obf.junk(proto, Harden.prng(sk), { density = 900, maxRun = 4 })
      if not Val.proto(proto) then allok = false end
      local p1 = table.pack(pcall(VM.load(proto, _G)))
      local o1 = {}; for i = 2, p1.n do o1[i - 1] = tostring(p1[i]) end
      local r1 = p1[1] and table.concat(o1, '|') or 'ERR'
      local proto2 = Ser.deserialize(Ser.serialize(proto))
      if not Val.proto(proto2) then allok = false end
      local p2 = table.pack(pcall(VM.load(proto2, _G)))
      local o2 = {}; for i = 2, p2.n do o2[i - 1] = tostring(p2[i]) end
      local r2 = p2[1] and table.concat(o2, '|') or 'ERR'
      if r1 ~= nat or r2 ~= nat then allok = false end
    end
  end
  ok(allok, 'bytecode junk: results unchanged + valid (direct + serialized)')
end

-- 4d. junk inserts only UNREACHABLE code (adds instructions, never fewer)
do
  local Obf = require('obfuscate')
  local function total(p, n) n = n or 0; n = n + #p.code
    for _, c in ipairs(p.protos) do n = total(c, n) end; return n end
  local src = progs[1]
  local plain = total(Compiler.compile(src))
  local proto = Compiler.compile(src); Obf.junk(proto, Harden.prng(3), { density = 1000, maxRun = 3 })
  ok(total(proto) > plain, 'junk adds instructions (' .. plain .. ' -> ' .. total(proto) .. ')')
end

-- 4e. basic-block reordering: results unchanged + validator-clean, direct and
-- through serialize -> deserialize; layout actually changes.
do
  local Obf = require('obfuscate')
  local Ser = require('serializer')
  local Val = require('validate')
  local allok = true
  for _, src in ipairs(progs) do
    local nat = runNative(src)
    for _, sk in ipairs({ 5, 21, 777, 424243 }) do
      local proto = Compiler.compile(src)
      Obf.flatten(proto, Harden.prng(sk))
      if not Val.proto(proto) then allok = false end
      local p1 = table.pack(pcall(VM.load(proto, _G)))
      local o1 = {}; for i = 2, p1.n do o1[i - 1] = tostring(p1[i]) end
      local r1 = p1[1] and table.concat(o1, '|') or 'ERR'
      local proto2 = Ser.deserialize(Ser.serialize(proto))
      if not Val.proto(proto2) then allok = false end
      local p2 = table.pack(pcall(VM.load(proto2, _G)))
      local o2 = {}; for i = 2, p2.n do o2[i - 1] = tostring(p2[i]) end
      local r2 = p2[1] and table.concat(o2, '|') or 'ERR'
      if r1 ~= nat or r2 ~= nat then allok = false end
    end
  end
  ok(allok, 'block reordering: results unchanged + valid (direct + serialized)')
end

-- 4f. reordering changes the physical op layout (same multiset, new order)
do
  local Obf = require('obfuscate')
  local src = 'local s=0 for i=1,10 do if i%2==0 then s=s+i else s=s-i end end return s'
  local function seq(p) local t = {}; for i, ins in ipairs(p.code) do t[i] = ins.op end; return table.concat(t, ',') end
  local plain = seq(Compiler.compile(src))
  local proto = Compiler.compile(src); Obf.flatten(proto, Harden.prng(9))
  ok(seq(proto) ~= plain, 'block reordering changes the instruction layout')
end

-- 4g. full composition (opaque + flatten + junk) is still correct
do
  local Obf = require('obfuscate')
  local Ser = require('serializer')
  local Val = require('validate')
  local allok = true
  for _, src in ipairs(progs) do
    local nat = runNative(src)
    for _, sk in ipairs({ 8, 88, 8888 }) do
      local proto = Compiler.compile(src, 'x', { opaque = Harden.prng(sk), opaqueDensity = 400 })
      Obf.flatten(proto, Harden.prng(sk + 1))
      Obf.junk(proto, Harden.prng(sk + 2), { density = 600, maxRun = 3 })
      if not Val.proto(proto) then allok = false end
      local proto2 = Ser.deserialize(Ser.serialize(proto))
      if not Val.proto(proto2) then allok = false end
      local p = table.pack(pcall(VM.load(proto2, _G)))
      local o = {}; for i = 2, p.n do o[i - 1] = tostring(p[i]) end
      if (p[1] and table.concat(o, '|') or 'ERR') ~= nat then allok = false end
    end
  end
  ok(allok, 'opaque + flatten + junk composed == native (serialized)')
end

-- 5. end-to-end through the bundler (opaque flow ON) still runs identically
do
  local WebBundle = require('webbundle')
  local function readModule(name)
    local f = assert(io.open('src/' .. name .. '.lua', 'r')); local s = f:read('*a'); f:close(); return s
  end
  local RT = {}
  for _, n in ipairs({ 'opcodes', 'bitops', 'serializer', 'seal', 'vm' }) do RT[n] = readModule(n) end
  local src = progs[1]
  local bundle = WebBundle.bundle(src, RT, 'input', { seed = 4242 })
  local f = (load or loadstring)(bundle)
  local p = table.pack(pcall(f))
  local o = {}; for i = 2, p.n do o[#o + 1] = tostring(p[i]) end
  ok((p[1] and table.concat(o, '|') or 'ERR') == runNative(src), 'bundled (opaque on) == native')
end

print(string.format('obfuscate_test: %d passed, %d failed', pass, fail))
os.exit(fail == 0 and 0 or 1)
