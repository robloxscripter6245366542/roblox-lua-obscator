-- luau-vm/src/validate.lua
-- Structural validator for a deserialized proto tree. The checksum in the
-- container catches random corruption, but it does not catch a *well-formed*
-- stream that encodes nonsense (a register index past maxstack, a constant
-- index out of range, a jump that lands outside the code). This module walks a
-- proto tree and rejects those, so malformed/adversarial bytecode fails with a
-- precise message instead of an out-of-range table access at run time.
--
-- Usage:
--   local ok, err = Validate.proto(proto)          -- validate a proto tree
--   local ok, err = Validate.bytecode(bytes, inv)  -- deserialize + validate

local Opcodes = require('opcodes')
local Serializer = require('serializer')

local Op = Opcodes.Op

-- Operand *kind* per opcode field: what each operand indexes into, so we can
-- bounds-check it. 'reg' -> R (< maxstack); 'const' -> K; 'proto' -> protos;
-- 'upval' -> upvals; 'jump' -> a pc-relative offset; 'imm' -> a plain integer.
local R, RR, RRR = { a = 'reg' }, { a = 'reg', b = 'reg' }, { a = 'reg', b = 'reg', c = 'reg' }
local kinds = {
  [Op.MOVE] = RR,
  [Op.LOADK] = { a = 'reg', bx = 'const' },
  [Op.LOADINT] = { a = 'reg', sbx = 'imm' },
  [Op.LOADBOOL] = { a = 'reg', b = 'imm' },
  [Op.LOADNIL] = { a = 'reg', b = 'imm' },
  [Op.GETGLOBAL] = { a = 'reg', bx = 'const' },
  [Op.SETGLOBAL] = { a = 'reg', bx = 'const' },
  [Op.NEWCELL] = R, [Op.GETCELL] = RR, [Op.SETCELL] = RR,
  [Op.GETUPVAL] = { a = 'reg', b = 'upval' },
  [Op.SETUPVAL] = { a = 'reg', b = 'upval' },
  [Op.NEWTABLE] = R, [Op.GETTABLE] = RRR, [Op.SETTABLE] = RRR,
  [Op.GETFIELD] = { a = 'reg', b = 'reg', bx = 'const' },
  [Op.SETFIELD] = { a = 'reg', bx = 'const', c = 'reg' },
  [Op.SELF] = { a = 'reg', b = 'reg', c = 'const' },
  [Op.SETLIST] = { a = 'reg', b = 'imm', c = 'imm' },
  [Op.ADD] = RRR, [Op.SUB] = RRR, [Op.MUL] = RRR, [Op.DIV] = RRR, [Op.MOD] = RRR,
  [Op.POW] = RRR, [Op.IDIV] = RRR,
  [Op.BAND] = RRR, [Op.BOR] = RRR, [Op.BXOR] = RRR, [Op.SHL] = RRR, [Op.SHR] = RRR,
  [Op.CONCAT] = RRR,
  [Op.UNM] = RR, [Op.NOT] = RR, [Op.LEN] = RR, [Op.BNOT] = RR,
  [Op.EQ] = RRR, [Op.LT] = RRR, [Op.LE] = RRR,
  [Op.JMP] = { sbx = 'jump' },
  [Op.JMPIF] = { a = 'reg', sbx = 'jump' },
  [Op.JMPIFNOT] = { a = 'reg', sbx = 'jump' },
  [Op.CALL] = { a = 'reg', b = 'imm', c = 'imm' },
  [Op.TAILCALL] = { a = 'reg', b = 'imm' },
  [Op.RETURN] = { a = 'reg', b = 'imm' },
  [Op.CLOSURE] = { a = 'reg', bx = 'proto' },
  [Op.VARARG] = { a = 'reg', b = 'imm' },
  [Op.FORPREP] = { a = 'reg', sbx = 'jump' },
  [Op.FORLOOP] = { a = 'reg', sbx = 'jump' },
  [Op.TFORCALL] = { a = 'reg', c = 'imm' },
  [Op.TFORLOOP] = { a = 'reg', sbx = 'jump' },
  [Op.NOP] = {},
}

local Validate = {}

-- Validate a single proto (recurses into children). Returns ok, err.
local function checkProto(p, path)
  path = path or 'main'
  if type(p) ~= 'table' then return false, path .. ': not a proto table' end
  local maxstack = p.maxstack or 0
  if type(maxstack) ~= 'number' or maxstack < 0 or maxstack > 100000 then
    return false, path .. ': implausible maxstack ' .. tostring(maxstack)
  end
  local nconst, nproto, nupval, ncode = #p.consts, #p.protos, #p.upvals, #p.code
  -- SELF writes R[a+1] and CALL/CONCAT address ranges above `a`, so allow one
  -- extra slot of head-room before flagging a register as out of range.
  local regMax = maxstack

  for i = 1, ncode do
    local ins = p.code[i]
    local layout = kinds[ins.op]
    if not layout then return false, string.format('%s[%d]: unknown opcode %s', path, i, tostring(ins.op)) end
    for field, kind in pairs(layout) do
      local v = ins[field] or 0
      if kind == 'reg' then
        if v < 0 or v > regMax then
          return false, string.format('%s[%d] %s: register %d out of range [0,%d]',
            path, i, Opcodes.mnemonic(ins.op), v, regMax)
        end
      elseif kind == 'const' then
        -- constant/proto/upvalue operands index 1-based Lua tables (K[bx], etc.)
        if v < 1 or v > nconst then
          return false, string.format('%s[%d] %s: const index %d out of range [1,%d]',
            path, i, Opcodes.mnemonic(ins.op), v, nconst)
        end
      elseif kind == 'proto' then
        if v < 1 or v > nproto then
          return false, string.format('%s[%d] %s: proto index %d out of range [1,%d]',
            path, i, Opcodes.mnemonic(ins.op), v, nproto)
        end
      elseif kind == 'upval' then
        if v < 1 or v > nupval then
          return false, string.format('%s[%d] %s: upvalue index %d out of range [1,%d]',
            path, i, Opcodes.mnemonic(ins.op), v, nupval)
        end
      elseif kind == 'jump' then
        local target = i + 1 + v
        if target < 1 or target > ncode then
          return false, string.format('%s[%d] %s: jump target %d out of range [1,%d]',
            path, i, Opcodes.mnemonic(ins.op), target, ncode)
        end
      end
    end
  end

  -- upvalue descriptors must reference sane parent slots
  for j, d in ipairs(p.upvals) do
    if d.kind ~= 'reg' and d.kind ~= 'up' then
      return false, string.format('%s: upval[%d] bad kind %s', path, j, tostring(d.kind))
    end
    if type(d.index) ~= 'number' or d.index < 0 then
      return false, string.format('%s: upval[%d] bad index %s', path, j, tostring(d.index))
    end
  end

  for k, child in ipairs(p.protos) do
    local ok, err = checkProto(child, path .. '/' .. k)
    if not ok then return false, err end
  end
  return true
end

function Validate.proto(p) return checkProto(p) end

-- Deserialize (checksum-checked) then structurally validate. Never throws for
-- bad input: returns ok, err (or ok, proto on success).
function Validate.bytecode(bytes, invMap)
  local okD, proto = pcall(Serializer.deserialize, bytes, invMap)
  if not okD then return false, tostring(proto) end
  local okV, err = checkProto(proto)
  if not okV then return false, err end
  return true, proto
end

Validate.kinds = kinds
return Validate
