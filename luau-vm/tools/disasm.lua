-- luau-vm/tools/disasm.lua
-- Bytecode disassembler: print a human-readable listing of a compiled proto
-- tree — constants, upvalue descriptors, and one line per instruction with its
-- decoded operands and jump targets. Reads a source file (compiles it) or a
-- serialized .fvm bytecode file.
--
--   lua5.4 tools/disasm.lua input.lua        # compile then disassemble
--   lua5.4 tools/disasm.lua bytecode.fvm --bytecode
--
-- Useful for debugging the compiler, understanding what the VM runs, and
-- eyeballing the effect of optimization passes.
local here = (arg and arg[0] and arg[0]:match('^(.*)/tools/')) or '.'
package.path = here .. '/src/?.lua;' .. package.path

local Opcodes = require('opcodes')
local API = require('api')
local Serializer = require('serializer')
local Validate = require('validate')

local Op = Opcodes.Op
-- fields to print per opcode, in order (mirrors the operand layout)
local layout = Opcodes.operands

local function fmtConst(v)
  if type(v) == 'string' then return string.format('%q', v) end
  return tostring(v)
end

-- render one instruction's operands as "field=value", annotating jumps/consts.
local JUMP = { [Op.JMP] = true, [Op.JMPIF] = true, [Op.JMPIFNOT] = true,
  [Op.FORPREP] = true, [Op.FORLOOP] = true, [Op.TFORLOOP] = true }

local function insText(ins, idx, consts)
  local parts = {}
  for _, f in ipairs(layout[ins.op] or {}) do
    parts[#parts + 1] = f .. '=' .. tostring(ins[f] or 0)
  end
  local s = table.concat(parts, ' ')
  if JUMP[ins.op] and ins.sbx then
    s = s .. string.format('   -> %d', idx + 1 + ins.sbx)
  end
  -- annotate constant-bearing ops with the referenced literal
  local bx = ins.bx
  if bx and consts[bx] ~= nil and (ins.op == Op.LOADK or ins.op == Op.GETGLOBAL
      or ins.op == Op.SETGLOBAL or ins.op == Op.GETFIELD or ins.op == Op.SETFIELD) then
    s = s .. '   ; ' .. fmtConst(consts[bx])
  end
  return s
end

local out = {}
local function line(s) out[#out + 1] = s or '' end

local function dumpProto(p, name, depth)
  local pad = string.rep('  ', depth)
  line(string.format('%s%s  params=%d vararg=%s maxstack=%d  (%d instrs, %d consts, %d protos, %d upvals)',
    pad, name, p.numparams, tostring(p.isVararg), p.maxstack,
    #p.code, #p.consts, #p.protos, #p.upvals))
  if #p.consts > 0 then
    for i, c in ipairs(p.consts) do line(string.format('%s  K[%d] = %s', pad, i, fmtConst(c))) end
  end
  if #p.upvals > 0 then
    for i, u in ipairs(p.upvals) do line(string.format('%s  U[%d] = %s %d', pad, i, u.kind, u.index)) end
  end
  for i, ins in ipairs(p.code) do
    line(string.format('%s  %4d  %-10s %s', pad, i, Opcodes.mnemonic(ins.op), insText(ins, i, p.consts)))
  end
  for i, child in ipairs(p.protos) do
    line('')
    dumpProto(child, name .. '/' .. i, depth + 1)
  end
end

local input = arg[1]
if not input then io.stderr:write('usage: disasm.lua input.lua | bytecode.fvm --bytecode\n'); os.exit(2) end
local isBytecode = arg[2] == '--bytecode'

local f = assert(io.open(input, isBytecode and 'rb' or 'r'))
local data = f:read('*a'); f:close()

local proto
if isBytecode then
  local ok, res = Validate.bytecode(data)
  if not ok then io.stderr:write('invalid bytecode: ' .. tostring(res) .. '\n'); os.exit(1) end
  proto = res
else
  proto = API.compile(data, input)
  -- round-trip through the serializer + validator so the listing matches what ships
  local ok, res = Validate.bytecode(Serializer.serialize(proto))
  if not ok then io.stderr:write('internal: produced invalid bytecode: ' .. tostring(res) .. '\n'); os.exit(1) end
  proto = res
end

line('; ferret-vm disassembly of ' .. input)
dumpProto(proto, 'main', 0)
io.write(table.concat(out, '\n'), '\n')
