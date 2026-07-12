-- Hand-assembled bytecode tests for the VM core (no compiler involved).
local here = (arg and arg[0] and arg[0]:match('^(.*)/test/')) or '.'
package.path = here .. '/src/?.lua;' .. package.path

local Opcodes = require('opcodes')
local VM = require('vm')
local Op = Opcodes.Op

local function I(op, a, b, c) return { op = Op[op], a = a, b = b, c = c } end
local function Ik(op, a, bx) return { op = Op[op], a = a, bx = bx } end
local function Ii(op, a, sbx) return { op = Op[op], a = a, sbx = sbx } end
local function Ij(op, sbx) return { op = Op[op], sbx = sbx } end

local out = {}
local function capture(...)
  local parts = {}
  for i = 1, select('#', ...) do parts[i] = tostring((select(i, ...))) end
  out[#out + 1] = table.concat(parts, '\t')
end

local env = setmetatable({ print = capture }, { __index = _G })

local passed, failed = 0, 0
local function check(name, proto, expected)
  out = {}
  local fn = VM.load(proto, env)
  local ok, err = pcall(fn)
  local got = table.concat(out, '\n')
  if ok and got == expected then
    passed = passed + 1
    print('PASS ' .. name)
  else
    failed = failed + 1
    print('FAIL ' .. name .. '  got=[' .. got .. '] expected=[' .. expected .. ']' .. (ok and '' or ('  err=' .. tostring(err))))
  end
end

-- 1) print(1 + 2)  -> 3
check('arith+call', {
  numparams = 0, isVararg = true, maxstack = 3, protos = {},
  consts = { 'print' },
  upvals = {},
  code = {
    Ik('GETGLOBAL', 0, 1),
    Ii('LOADINT', 1, 1),
    Ii('LOADINT', 2, 2),
    I('ADD', 1, 1, 2),
    I('CALL', 0, 2, 1),
    I('RETURN', 0, 1),
  },
}, '3')

-- 2) local s=0 for i=1,5 do s=s+i end print(s)  -> 15
check('numeric-for', {
  numparams = 0, isVararg = false, maxstack = 5, protos = {}, consts = { 'print' }, upvals = {},
  code = {
    Ii('LOADINT', 0, 0),   -- s = 0
    Ii('LOADINT', 1, 1),   -- init
    Ii('LOADINT', 2, 5),   -- limit
    Ii('LOADINT', 3, 1),   -- step
    Ii('FORPREP', 1, 1),   -- a=1 -> jump to FORLOOP
    I('ADD', 0, 0, 4),     -- body: s = s + i
    Ii('FORLOOP', 1, -2),  -- a=1 -> back to body
    Ik('GETGLOBAL', 1, 1), -- print
    I('MOVE', 2, 0),       -- s
    I('CALL', 1, 2, 1),
    I('RETURN', 0, 1),
  },
}, '15')

-- 3) closure counter: print(c(), c(), c()) -> 1  2  3
local innerProto = {
  numparams = 0, isVararg = false, maxstack = 2, protos = {}, consts = {},
  upvals = { { kind = 'reg', index = 0 } },
  code = {
    I('GETUPVAL', 0, 1),   -- n
    Ii('LOADINT', 1, 1),
    I('ADD', 0, 0, 1),     -- n+1
    I('SETUPVAL', 0, 1),   -- store back
    I('RETURN', 0, 2),     -- return n
  },
}
local counterProto = {
  numparams = 0, isVararg = false, maxstack = 2, protos = { innerProto }, consts = {}, upvals = {},
  code = {
    Ii('LOADINT', 0, 0),   -- n = 0
    I('NEWCELL', 0),       -- box n
    Ik('CLOSURE', 1, 1),   -- inner captures reg0
    I('RETURN', 1, 2),
  },
}
check('closure-upvalue', {
  numparams = 0, isVararg = false, maxstack = 5, protos = { counterProto }, consts = { 'print' }, upvals = {},
  code = {
    Ik('CLOSURE', 0, 1),   -- counter
    I('CALL', 0, 1, 2),    -- c = counter()
    Ik('GETGLOBAL', 1, 1), -- print
    I('MOVE', 2, 0), I('CALL', 2, 1, 2),  -- c() -> R2
    I('MOVE', 3, 0), I('CALL', 3, 1, 2),  -- c() -> R3
    I('MOVE', 4, 0), I('CALL', 4, 1, 2),  -- c() -> R4
    I('CALL', 1, 4, 1),    -- print(R2,R3,R4)
    I('RETURN', 0, 1),
  },
}, '1\t2\t3')

print(string.format('\ncore: %d passed, %d failed', passed, failed))
os.exit(failed == 0 and 0 or 1)
