-- luau-vm/src/opcodes.lua
-- Custom instruction set for the ferret VM.
--
-- Register-based. Operands are register indices unless noted. Multi-value
-- calls/returns/varargs follow a Lua-style convention: a count field of 0 means
-- "up to the current frame top" (set by a preceding multi-value producer), and
-- a result count of 0 means "produce all results and set top". Everything else
-- uses exact counts, which keeps the common case simple and fast.
--
-- Instructions are stored at compile time as tables {op=, a=, b=, c=, bx=, sbx=}
-- for readability; the serializer packs them into a compact binary form.
--
-- Captured locals and upvalues are unified as "cells" (a 1-field box {v=...}),
-- so closures never touch the parent's live registers — no open/closed upvalue
-- machinery is required.

local Op = {}
local names = {}
local n = 0
local function def(name)
  n = n + 1
  Op[name] = n
  names[n] = name
  return n
end

-- ── data movement / constants ────────────────────────────────────────────────
def('MOVE')      -- A B      R[A] = R[B]
def('LOADK')     -- A Bx     R[A] = K[Bx]
def('LOADINT')   -- A sBx    R[A] = sBx                (immediate small integer)
def('LOADBOOL')  -- A B      R[A] = (B ~= 0)
def('LOADNIL')   -- A B      R[A..A+B] = nil

-- ── globals / environment ────────────────────────────────────────────────────
def('GETGLOBAL') -- A Bx     R[A] = ENV[K[Bx]]
def('SETGLOBAL') -- A Bx     ENV[K[Bx]] = R[A]

-- ── cells (captured locals) & upvalues ───────────────────────────────────────
def('NEWCELL')   -- A        R[A] = { v = R[A] }       (box a captured local)
def('GETCELL')   -- A B      R[A] = R[B].v
def('SETCELL')   -- A B      R[A].v = R[B]
def('GETUPVAL')  -- A B      R[A] = U[B].v
def('SETUPVAL')  -- A B      U[B].v = R[A]

-- ── tables ───────────────────────────────────────────────────────────────────
def('NEWTABLE')  -- A        R[A] = {}
def('GETTABLE')  -- A B C    R[A] = R[B][R[C]]
def('SETTABLE')  -- A B C    R[A][R[B]] = R[C]
def('GETFIELD')  -- A B Bx   R[A] = R[B][K[Bx]]        (const-string key fast path)
def('SETFIELD')  -- A Bx C   R[A][K[Bx]] = R[C]
def('SELF')      -- A B C    R[A+1] = R[B]; R[A] = R[B][K[C]]  (method prep)
def('SETLIST')   -- A B C    R[A][C + i] = R[A+i], i=1..B (B=0 -> up to top)

-- ── arithmetic (R[A] = R[B] op R[C]) ─────────────────────────────────────────
def('ADD'); def('SUB'); def('MUL'); def('DIV'); def('MOD'); def('POW'); def('IDIV')
-- ── bitwise ──────────────────────────────────────────────────────────────────
def('BAND'); def('BOR'); def('BXOR'); def('SHL'); def('SHR')
-- ── concat ───────────────────────────────────────────────────────────────────
def('CONCAT')    -- A B C    R[A] = R[B] .. R[B+1] .. ... .. R[C]
-- ── unary ────────────────────────────────────────────────────────────────────
def('UNM'); def('NOT'); def('LEN'); def('BNOT')  -- A B   R[A] = op R[B]
-- ── comparison (R[A] = R[B] op R[C]) ─────────────────────────────────────────
def('EQ'); def('LT'); def('LE')

-- ── control flow ─────────────────────────────────────────────────────────────
def('JMP')       -- sBx      pc += sBx
def('JMPIF')     -- A sBx    if truthy(R[A]) then pc += sBx
def('JMPIFNOT')  -- A sBx    if not truthy(R[A]) then pc += sBx

-- ── calls / returns ──────────────────────────────────────────────────────────
def('CALL')      -- A B C    call R[A] with (B-1) args; keep (C-1) results (0 = to top)
def('TAILCALL')  -- A B      return R[A]((B-1) args)   (no host TCO; result-preserving)
def('RETURN')    -- A B      return R[A..A+B-2]        (B=0 -> to top)

-- ── closures / varargs ───────────────────────────────────────────────────────
def('CLOSURE')   -- A Bx     R[A] = closure(protos[Bx], captured upvals)
def('VARARG')    -- A B      R[A..A+B-2] = varargs     (B=0 -> to top)

-- ── loops ────────────────────────────────────────────────────────────────────
def('FORPREP')   -- A sBx    numeric-for init; jump to loop test
def('FORLOOP')   -- A sBx    numeric-for step + test; jump back if continuing
def('TFORPREP')  -- A        generic-for setup: normalize R[A..A+2] for Luau
                 --          generalized iteration (table/__iter -> next-triple)
def('TFORCALL')  -- A C      generic-for: call iterator, C results into R[A+3..]
def('TFORLOOP')  -- A sBx    generic-for: if R[A+1] ~= nil then R[A]=R[A+1]; pc += sBx

def('NOP')       -- (used by peephole/DCE)

-- Operand layout per opcode: which instruction fields carry data. Used by the
-- serializer for a compact, self-validating encoding, and as documentation.
local A, AB, ABC = { 'a' }, { 'a', 'b' }, { 'a', 'b', 'c' }
local operands = {
  [Op.MOVE] = AB, [Op.LOADK] = { 'a', 'bx' }, [Op.LOADINT] = { 'a', 'sbx' },
  [Op.LOADBOOL] = AB, [Op.LOADNIL] = AB,
  [Op.GETGLOBAL] = { 'a', 'bx' }, [Op.SETGLOBAL] = { 'a', 'bx' },
  [Op.NEWCELL] = A, [Op.GETCELL] = AB, [Op.SETCELL] = AB, [Op.GETUPVAL] = AB, [Op.SETUPVAL] = AB,
  [Op.NEWTABLE] = A, [Op.GETTABLE] = ABC, [Op.SETTABLE] = ABC,
  [Op.GETFIELD] = { 'a', 'b', 'bx' }, [Op.SETFIELD] = { 'a', 'bx', 'c' },
  [Op.SELF] = ABC, [Op.SETLIST] = ABC,
  [Op.ADD] = ABC, [Op.SUB] = ABC, [Op.MUL] = ABC, [Op.DIV] = ABC, [Op.MOD] = ABC,
  [Op.POW] = ABC, [Op.IDIV] = ABC,
  [Op.BAND] = ABC, [Op.BOR] = ABC, [Op.BXOR] = ABC, [Op.SHL] = ABC, [Op.SHR] = ABC,
  [Op.CONCAT] = ABC,
  [Op.UNM] = AB, [Op.NOT] = AB, [Op.LEN] = AB, [Op.BNOT] = AB,
  [Op.EQ] = ABC, [Op.LT] = ABC, [Op.LE] = ABC,
  [Op.JMP] = { 'sbx' }, [Op.JMPIF] = { 'a', 'sbx' }, [Op.JMPIFNOT] = { 'a', 'sbx' },
  [Op.CALL] = ABC, [Op.TAILCALL] = AB, [Op.RETURN] = AB,
  [Op.CLOSURE] = { 'a', 'bx' }, [Op.VARARG] = AB,
  [Op.FORPREP] = { 'a', 'sbx' }, [Op.FORLOOP] = { 'a', 'sbx' },
  [Op.TFORPREP] = A, [Op.TFORCALL] = { 'a', 'c' }, [Op.TFORLOOP] = { 'a', 'sbx' },
  [Op.NOP] = {},
}

local Opcodes = { Op = Op, name = names, count = n, operands = operands }

function Opcodes.mnemonic(op)
  return names[op] or ('?' .. tostring(op))
end

return Opcodes
