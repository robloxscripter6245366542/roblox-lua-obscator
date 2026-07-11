-- luau-vm/src/vm.lua
-- Register-based interpreter for the ferret custom bytecode.
--
-- Design choices that buy correctness + Luau compatibility cheaply:
--   * A VM closure is a REAL Lua function (see makeClosure) that runs `execute`.
--     So VM and host functions are invoked identically, and metamethods, pcall,
--     coroutines, table.sort(cmp), etc. all work because a compiled function is
--     an ordinary callable Lua value.
--   * All operators use the host's native ops (R[b] + R[c], R[b][k], #x, ..),
--     so metatables (__index/__add/__concat/__len/…) are honored by the host.
--   * Captured locals & upvalues are "cells" ({v=...}); closures capture cell
--     references, so no open/closed-upvalue bookkeeping is needed.
--
-- table.pack/unpack carry multiple values across call boundaries, so multiple
-- returns and varargs are exact.

local Opcodes = require('opcodes')
local Bit = require('bitops')
local Op = Opcodes.Op

local pack = table.pack or function(...) return { n = select('#', ...), ... } end
local unpack = table.unpack or unpack

local VM = {}

-- Forward declaration: execute runs a proto with its upvalues/env/args.
local execute

-- Wrap a proto + captured upvalues + env into a callable Lua value.
local function makeClosure(proto, upvals, env)
  return function(...)
    local args = pack(...)
    local res = execute(proto, upvals, env, args, args.n)
    return unpack(res, 1, res.n)
  end
end

-- The interpreter. Returns a packed results table {..., n=}.
execute = function(proto, upvals, env, args, argN)
  local code = proto.code
  local K = proto.consts
  local protos = proto.protos
  local R = {}

  local np = proto.numparams
  for i = 0, np - 1 do R[i] = args[i + 1] end

  local varargs, varargN = nil, 0
  if proto.isVararg then
    varargs = {}
    for i = np + 1, argN do
      varargN = varargN + 1
      varargs[varargN] = args[i]
    end
  end

  local top = 0
  local pc = 1

  while true do
    local ins = code[pc]
    pc = pc + 1
    local op = ins.op
    local a = ins.a

    if op == Op.MOVE then R[a] = R[ins.b]
    elseif op == Op.LOADK then R[a] = K[ins.bx]
    elseif op == Op.LOADINT then R[a] = ins.sbx
    elseif op == Op.LOADBOOL then R[a] = (ins.b ~= 0)
    elseif op == Op.LOADNIL then for i = a, a + ins.b do R[i] = nil end

    elseif op == Op.GETGLOBAL then R[a] = env[K[ins.bx]]
    elseif op == Op.SETGLOBAL then env[K[ins.bx]] = R[a]

    elseif op == Op.NEWCELL then R[a] = { v = R[a] }
    elseif op == Op.GETCELL then R[a] = R[ins.b].v
    elseif op == Op.SETCELL then R[a].v = R[ins.b]
    elseif op == Op.GETUPVAL then R[a] = upvals[ins.b].v
    elseif op == Op.SETUPVAL then upvals[ins.b].v = R[a]

    elseif op == Op.NEWTABLE then R[a] = {}
    elseif op == Op.GETTABLE then R[a] = R[ins.b][R[ins.c]]
    elseif op == Op.SETTABLE then R[a][R[ins.b]] = R[ins.c]
    elseif op == Op.GETFIELD then R[a] = R[ins.b][K[ins.bx]]
    elseif op == Op.SETFIELD then R[a][K[ins.bx]] = R[ins.c]
    elseif op == Op.SELF then
      R[a + 1] = R[ins.b]
      R[a] = R[ins.b][K[ins.c]]
    elseif op == Op.SETLIST then
      local t = R[a]
      local count = ins.b
      if count == 0 then count = top - a - 1 end
      local base = ins.c
      for i = 1, count do t[base + i] = R[a + i] end

    elseif op == Op.ADD then R[a] = R[ins.b] + R[ins.c]
    elseif op == Op.SUB then R[a] = R[ins.b] - R[ins.c]
    elseif op == Op.MUL then R[a] = R[ins.b] * R[ins.c]
    elseif op == Op.DIV then R[a] = R[ins.b] / R[ins.c]
    elseif op == Op.MOD then R[a] = R[ins.b] % R[ins.c]
    elseif op == Op.POW then R[a] = R[ins.b] ^ R[ins.c]
    elseif op == Op.IDIV then R[a] = math.floor(R[ins.b] / R[ins.c])

    elseif op == Op.BAND then R[a] = Bit.band(R[ins.b], R[ins.c])
    elseif op == Op.BOR then R[a] = Bit.bor(R[ins.b], R[ins.c])
    elseif op == Op.BXOR then R[a] = Bit.bxor(R[ins.b], R[ins.c])
    elseif op == Op.SHL then R[a] = Bit.lshift(R[ins.b], R[ins.c])
    elseif op == Op.SHR then R[a] = Bit.rshift(R[ins.b], R[ins.c])

    elseif op == Op.CONCAT then
      local s = R[ins.b]
      for i = ins.b + 1, ins.c do s = s .. R[i] end
      R[a] = s

    elseif op == Op.UNM then R[a] = -R[ins.b]
    elseif op == Op.NOT then R[a] = not R[ins.b]
    elseif op == Op.LEN then R[a] = #R[ins.b]
    elseif op == Op.BNOT then R[a] = Bit.bnot(R[ins.b])

    elseif op == Op.EQ then R[a] = (R[ins.b] == R[ins.c])
    elseif op == Op.LT then R[a] = (R[ins.b] < R[ins.c])
    elseif op == Op.LE then R[a] = (R[ins.b] <= R[ins.c])

    elseif op == Op.JMP then pc = pc + ins.sbx
    elseif op == Op.JMPIF then if R[a] then pc = pc + ins.sbx end
    elseif op == Op.JMPIFNOT then if not R[a] then pc = pc + ins.sbx end

    elseif op == Op.CALL then
      local fn = R[a]
      local b = ins.b
      local nargs = (b == 0) and (top - a - 1) or (b - 1)
      local callArgs = {}
      for i = 1, nargs do callArgs[i] = R[a + i] end
      local res = pack(fn(unpack(callArgs, 1, nargs)))
      local c = ins.c
      if c == 0 then
        for i = 1, res.n do R[a + i - 1] = res[i] end
        top = a + res.n
      else
        for i = 1, c - 1 do R[a + i - 1] = res[i] end
      end

    elseif op == Op.TAILCALL then
      local fn = R[a]
      local b = ins.b
      local nargs = (b == 0) and (top - a - 1) or (b - 1)
      local callArgs = {}
      for i = 1, nargs do callArgs[i] = R[a + i] end
      return pack(fn(unpack(callArgs, 1, nargs)))

    elseif op == Op.RETURN then
      local b = ins.b
      local nret = (b == 0) and (top - a) or (b - 1)
      local out = {}
      for i = 1, nret do out[i] = R[a + i - 1] end
      out.n = nret
      return out

    elseif op == Op.CLOSURE then
      local child = protos[ins.bx]
      local newUp = {}
      for i, d in ipairs(child.upvals) do
        if d.kind == 'reg' then newUp[i] = R[d.index]
        else newUp[i] = upvals[d.index] end
      end
      R[a] = makeClosure(child, newUp, env)

    elseif op == Op.VARARG then
      local b = ins.b
      local count = (b == 0) and varargN or (b - 1)
      for i = 1, count do R[a + i - 1] = varargs[i] end
      if b == 0 then top = a + varargN end

    elseif op == Op.FORPREP then
      R[a] = R[a] - R[a + 2]
      pc = pc + ins.sbx
    elseif op == Op.FORLOOP then
      local step = R[a + 2]
      local idx = R[a] + step
      R[a] = idx
      local limit = R[a + 1]
      if (step >= 0 and idx <= limit) or (step < 0 and idx >= limit) then
        R[a + 3] = idx
        pc = pc + ins.sbx
      end
    elseif op == Op.TFORCALL then
      local fn = R[a]
      local res = pack(fn(R[a + 1], R[a + 2]))
      for i = 1, ins.c do R[a + 2 + i] = res[i] end
    elseif op == Op.TFORLOOP then
      if R[a + 3] ~= nil then
        R[a + 2] = R[a + 3]
        pc = pc + ins.sbx
      end

    elseif op == Op.NOP then -- nothing

    else
      error('ferret-vm: bad opcode ' .. Opcodes.mnemonic(op) .. ' at pc ' .. (pc - 1))
    end
  end
end

-- Public: build a callable from a top-level proto and an environment.
function VM.load(proto, env)
  env = env or _ENV or _G
  return makeClosure(proto, {}, env)
end

VM.execute = execute
VM.makeClosure = makeClosure
return VM
