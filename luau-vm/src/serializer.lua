-- luau-vm/src/serializer.lua
-- Compact binary encoding of a compiled proto tree, and its inverse loader.
-- No loadstring: bytes -> runtime proto tables directly.
--
-- Format
--   magic  'FVM' , version(1 byte)
--   uint32 checksum (FNV-1a over the body)
--   uint32 bodyLength
--   body:  proto (recursive)
-- Integers use zig-zag LEB128 varints; numbers round-trip via %.17g text so no
-- string.pack dependency (works on Lua 5.1+/Luau uniformly).

local Opcodes = require('opcodes')
local Bit = require('bitops')

local Serializer = {}

local MAGIC = 'FVM'
local VERSION = 1

-- ── writer ───────────────────────────────────────────────────────────────────
local function Writer()
  return { buf = {}, put = function(self, s) self.buf[#self.buf + 1] = s end }
end
local function writeByte(w, b) w:put(string.char(b % 256)) end
local function writeUVarint(w, x)
  x = math.floor(x)
  while true do
    local b = x % 128
    x = math.floor(x / 128)
    if x > 0 then writeByte(w, b + 128) else writeByte(w, b); break end
  end
end
local function writeSVarint(w, x)
  x = math.floor(x)
  local zz = x >= 0 and (x * 2) or (-x * 2 - 1) -- zig-zag
  writeUVarint(w, zz)
end
local function writeString(w, s)
  writeUVarint(w, #s)
  w:put(s)
end
local function writeU32(w, x)
  x = math.floor(x) % 4294967296
  for _ = 1, 4 do writeByte(w, x % 256); x = math.floor(x / 256) end
end

-- ── reader ───────────────────────────────────────────────────────────────────
local function Reader(s) return { s = s, pos = 1 } end
local function readByte(r) local b = string.byte(r.s, r.pos); r.pos = r.pos + 1; return b end
local function readUVarint(r)
  local x, shift = 0, 1
  while true do
    local b = readByte(r)
    x = x + (b % 128) * shift
    if b < 128 then break end
    shift = shift * 128
  end
  return x
end
local function readSVarint(r)
  local zz = readUVarint(r)
  -- math.floor keeps an integer subtype on Lua 5.4 (unlike `/`, which floats)
  if zz % 2 == 0 then return math.floor(zz / 2) else return -math.floor((zz + 1) / 2) end
end
local function readString(r)
  local n = readUVarint(r)
  local s = r.s:sub(r.pos, r.pos + n - 1)
  r.pos = r.pos + n
  return s
end
local function readU32(r)
  local x, m = 0, 1
  for _ = 1, 4 do x = x + readByte(r) * m; m = m * 256 end
  return x
end

-- ── value (constant) encoding ────────────────────────────────────────────────
local T_NIL, T_TRUE, T_FALSE, T_INT, T_NUM, T_STR = 0, 1, 2, 3, 4, 5
local function writeValue(w, v)
  local t = type(v)
  if v == nil then writeByte(w, T_NIL)
  elseif v == true then writeByte(w, T_TRUE)
  elseif v == false then writeByte(w, T_FALSE)
  elseif t == 'number' then
    if math.floor(v) == v and v >= -2147483648 and v <= 2147483647 then
      writeByte(w, T_INT); writeSVarint(w, v)
    else
      writeByte(w, T_NUM); writeString(w, string.format('%.17g', v))
    end
  elseif t == 'string' then writeByte(w, T_STR); writeString(w, v)
  else error('serializer: cannot encode constant of type ' .. t) end
end
local function readValue(r)
  local t = readByte(r)
  if t == T_NIL then return nil
  elseif t == T_TRUE then return true
  elseif t == T_FALSE then return false
  elseif t == T_INT then return readSVarint(r)
  elseif t == T_NUM then return tonumber(readString(r))
  elseif t == T_STR then return readString(r)
  else error('serializer: bad constant tag ' .. tostring(t)) end
end

-- ── proto encoding ───────────────────────────────────────────────────────────
-- opMap (optional): canonical opcode -> the byte written for it. Lets a build
-- ship a per-build opcode numbering so the bytecode can't be read by a
-- devirtualizer keyed to the canonical set. ins.op stays canonical internally,
-- so operand-layout lookup and the VM's dispatch are unaffected.
local function writeProto(w, p, opMap)
  writeUVarint(w, p.numparams)
  writeByte(w, p.isVararg and 1 or 0)
  writeUVarint(w, p.maxstack)
  -- upvalues
  writeUVarint(w, #p.upvals)
  for _, d in ipairs(p.upvals) do
    writeByte(w, d.kind == 'reg' and 0 or 1)
    writeUVarint(w, d.index)
  end
  -- constants
  writeUVarint(w, #p.consts)
  for _, c in ipairs(p.consts) do writeValue(w, c) end
  -- code
  writeUVarint(w, #p.code)
  for _, ins in ipairs(p.code) do
    writeByte(w, opMap and opMap[ins.op] or ins.op)
    for _, field in ipairs(Opcodes.operands[ins.op]) do
      writeSVarint(w, ins[field] or 0)
    end
  end
  -- nested protos
  writeUVarint(w, #p.protos)
  for _, child in ipairs(p.protos) do writeProto(w, child, opMap) end
end

-- invMap (optional): the inverse of opMap (written byte -> canonical opcode).
local function readProto(r, invMap)
  local p = { upvals = {}, consts = {}, code = {}, protos = {}, lines = {} }
  p.numparams = readUVarint(r)
  p.isVararg = readByte(r) == 1
  p.maxstack = readUVarint(r)
  for i = 1, readUVarint(r) do
    local kind = readByte(r) == 0 and 'reg' or 'up'
    p.upvals[i] = { kind = kind, index = readUVarint(r) }
  end
  for i = 1, readUVarint(r) do p.consts[i] = readValue(r) end
  local ncode = readUVarint(r)
  for i = 1, ncode do
    local op = readByte(r)
    if invMap then op = invMap[op] end
    local ins = { op = op }
    for _, field in ipairs(Opcodes.operands[op]) do ins[field] = readSVarint(r) end
    p.code[i] = ins
  end
  for i = 1, readUVarint(r) do p.protos[i] = readProto(r, invMap) end
  return p
end

-- ── FNV-1a checksum (32-bit, portable) ───────────────────────────────────────
local function fnv1a(s)
  local h = 2166136261
  for i = 1, #s do
    h = Bit.bxor(h, s:byte(i))
    -- h * 16777619 mod 2^32, split to stay exact in doubles
    local lo = (h % 65536) * 16777619
    local hi = (math.floor(h / 65536) * 16777619) % 65536
    h = (lo + hi * 65536) % 4294967296
  end
  return math.floor(h)
end

-- ── public API ───────────────────────────────────────────────────────────────
function Serializer.serialize(proto, opMap)
  local w = Writer()
  writeProto(w, proto, opMap)
  local body = table.concat(w.buf)
  local head = Writer()
  head:put(MAGIC)
  writeByte(head, VERSION)
  writeU32(head, fnv1a(body))
  writeU32(head, #body)
  return table.concat(head.buf) .. body
end

function Serializer.deserialize(bytes, invMap)
  local r = Reader(bytes)
  if bytes:sub(1, 3) ~= MAGIC then error('serializer: bad magic (not ferret bytecode)') end
  r.pos = 4
  local version = readByte(r)
  if version ~= VERSION then error('serializer: unsupported version ' .. version) end
  local checksum = readU32(r)
  local bodyLen = readU32(r)
  local body = bytes:sub(r.pos, r.pos + bodyLen - 1)
  if fnv1a(body) ~= checksum then error('serializer: checksum mismatch (corrupt bytecode)') end
  local br = Reader(body)
  return readProto(br, invMap)
end

Serializer.MAGIC = MAGIC
Serializer.VERSION = VERSION
return Serializer
