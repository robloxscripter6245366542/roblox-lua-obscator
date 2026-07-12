-- luau-vm/test/opcode_coverage.lua
-- Explicit per-opcode coverage. The target set is derived from the compiler
-- itself (every Op.* it can emit), so if someone teaches the compiler a new
-- opcode this test demands a program that exercises it. Each corpus program is
-- also structurally validated and differential-checked (native vs VM), so this
-- doubles as a focused correctness test for every instruction.

package.path = 'src/?.lua;' .. package.path
local API = require('api')
local Opcodes = require('opcodes')
local Validate = require('validate')

-- ── target set: opcodes the compiler references (ground truth) ────────────────
local target = {}
do
  local f = assert(io.open('src/compiler.lua', 'r'))
  local text = f:read('*a'); f:close()
  for name in text:gmatch('Op%.([A-Z_]+)') do target[name] = true end
end

-- ── corpus (differential-checked: native == VM) ───────────────────────────────
-- Programs return only scalars, so results compare cleanly (no table identities).
local corpus = {
  'local a,b=7,3 return a+b,a-b,a*b,a/b,a%b,a^b,a//b,-a,#"hi",("x").."y"',
  'local a,b=7,3 return a<b, a<=b, a==b, not (a<b)',
  'local f,g=true,false local x,y,z return f,g,x,y,z',          -- LOADBOOL, LOADNIL
  'g=5 local t={10,20,30} t.k=g t[1]=99 return g,t.k,t[1],#t',   -- globals/table/field/list
  'local o={tag=9} function o:m(n) return self.tag, n end return o:m(5)', -- SELF/CLOSURE/SETFIELD/GETFIELD
  'local s=0 for i=1,4 do s=s+i end return s',                   -- FORPREP/FORLOOP
  'local s=0 for _,v in ipairs({4,5,6}) do s=s+v end return s',  -- TFORCALL/TFORLOOP
  'local n=0 while n<3 do n=n+1 if n==2 then n=n*1 end end return n', -- JMP/JMPIFNOT
  'local function pick(p,q) return (p or q), (p and q) end return pick(false,42)', -- JMPIF (or) / JMPIFNOT (and)
  'local function mk() local c=0 return function() c=c+1 return c end end local h=mk() return h()+h()', -- upvals
  'local function cell() local c=0 local function get() return c end c=c+2 return get()+c end return cell()', -- GETCELL/SETCELL
  'local function v(...) return select("#", ...) end return v(1,2,3,4)', -- VARARG
  'return math.floor(3.7)',                                      -- GETGLOBAL/GETFIELD/CALL
}

-- ── coverage-only (semantics differ from lua5.4 by design; not diffed) ────────
-- The VM's bitwise ops are 32-bit (bit32 / Luau semantics); lua5.4 native is
-- 64-bit, so `~x` and wide shifts legitimately differ. Kept for opcode coverage;
-- bitwise correctness against Luau is covered by the main verify suite.
local coverageOnly = {
  'local a,b=6,3 return a&b, a|b, ~a, a~b, a<<2, a>>1',          -- BAND/BOR/BNOT/BXOR/SHL/SHR
}

-- native runner (captures return values as a flat string)
local function runNative(src)
  local f = (loadstring or load)(src)
  if not f then return '<native-compile>' end
  local packed = table.pack(pcall(f))
  if not packed[1] then return '<native-error>' end
  local out = {}
  for i = 2, packed.n do out[#out + 1] = tostring(packed[i]) end
  return table.concat(out, '|')
end

local function runVM(proto)
  local packed = table.pack(pcall(API.VM.load(proto, _G)))
  if not packed[1] then return '<vm-error>' end
  local out = {}
  for i = 2, packed.n do out[#out + 1] = tostring(packed[i]) end
  return table.concat(out, '|')
end

local function collectOps(proto, seen)
  for _, ins in ipairs(proto.code) do seen[Opcodes.mnemonic(ins.op)] = true end
  for _, c in ipairs(proto.protos) do collectOps(c, seen) end
end

-- ── run corpus ────────────────────────────────────────────────────────────────
local seen, pass, fail = {}, 0, 0
for i, src in ipairs(corpus) do
  local proto = API.compile(src, 'cov' .. i)
  local okV, err = Validate.bytecode(API.serialize(src, 'cov' .. i))
  local nat, vm = runNative(src), runVM(proto)
  collectOps(proto, seen)
  if okV and nat == vm then
    pass = pass + 1
  else
    fail = fail + 1
    print(string.format('FAIL cov%d: valid=%s native=%q vm=%q  (%s)', i, tostring(okV), nat, vm, tostring(err)))
  end
end
-- coverage-only: compile + validate + collect ops, but do not diff semantics
for i, src in ipairs(coverageOnly) do
  local proto = API.compile(src, 'covo' .. i)
  local okV, err = Validate.bytecode(API.serialize(src, 'covo' .. i))
  collectOps(proto, seen)
  if not okV then fail = fail + 1; print('FAIL covo' .. i .. ': ' .. tostring(err)) end
end

-- ── coverage report ───────────────────────────────────────────────────────────
local missing = {}
for name in pairs(target) do if not seen[name] then missing[#missing + 1] = name end end
table.sort(missing)

local ntarget = 0; for _ in pairs(target) do ntarget = ntarget + 1 end
print(string.format('opcode_coverage: %d/%d corpus programs correct; %d/%d emittable opcodes covered',
  pass, #corpus, ntarget - #missing, ntarget))
if #missing > 0 then print('  UNCOVERED: ' .. table.concat(missing, ' ')) end

os.exit((fail == 0 and #missing == 0) and 0 or 1)
