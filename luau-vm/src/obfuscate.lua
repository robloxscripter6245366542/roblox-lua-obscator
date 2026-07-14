-- luau-vm/src/obfuscate.lua
-- Source-level (AST) control-flow obfuscation: opaque-predicate injection.
--
-- This pass runs on the parsed + constant-folded AST, BEFORE scope analysis and
-- code generation, so the compiler performs all register allocation and jump
-- generation for the injected code exactly as it would for hand-written Lua.
-- That is what makes it safe: we never touch the bytecode's register/`top`
-- bookkeeping directly (where a stray write could clobber a live call frame) —
-- we only add ordinary, valid Lua statements and let the compiler lower them.
--
-- What it injects:
--   * One "seed" local per function/chunk:  local <s> = #"<random>"
--     `#literal` is a non-negative integer the optimizer does not fold, and once
--     the string constants are encrypted at runtime (see seal.lua) its value is
--     not visible to a static reader without running the decryptor.
--   * Bogus `if` statements guarded by OPAQUE PREDICATES over that seed:
--       - always-TRUE   `(s % A) <= (A-1)`   (A>=1, so s%A is in [0,A-1])
--       - always-FALSE  `(s % A) == A`       (never equal to A)
--     For any integer s and A>0 Lua/Luau guarantee  s % A  in [0, A-1], so the
--     predicate's truth value is fixed regardless of the seed's actual value —
--     yet a naive static analyzer cannot fold it away.
--
-- Every injected branch body contains ONLY self-contained junk (fresh
-- block-scoped locals, plus reads/dead-writes of the seed). It never wraps or
-- reorders real statements, so the scoping and semantics of the user's code are
-- untouched: the always-true bodies have no observable effect, and the
-- always-false bodies never execute. Result: extra, plausible control-flow
-- edges in the recovered bytecode without any behavioural change.

local M = {}

-- ── tiny AST builders ────────────────────────────────────────────────────────
local L = 0
local function name(n) return { k = 'Name', name = n, line = L } end
local function num(v) return { k = 'Number', value = tostring(v), line = L } end
local function str(s) return { k = 'String', value = s, line = L } end
local function bin(op, a, b) return { k = 'Binop', op = op, left = a, right = b, line = L } end
local function len(e) return { k = 'Unop', op = '#', operand = e, line = L } end
local function localStmt(nm, expr) return { k = 'Local', names = { nm }, exprs = { expr }, line = L } end
local function assign(nm, expr) return { k = 'Assign', targets = { name(nm) }, exprs = { expr }, line = L } end
local function ifStmt(cond, body) return { k = 'If', clauses = { { cond = cond, body = body } }, elseBody = nil, line = L } end

-- ── per-build identifier generator (leading `_` + lowercase/digits => never a
-- keyword or stdlib global; long enough that collision with a user local is
-- negligible) ────────────────────────────────────────────────────────────────
local function idGen(rng)
  local pool = 'abcdefghijklmnopqrstuvwxyz0123456789'
  local used = {}
  return function()
    while true do
      local s = '_'
      for _ = 1, 8 do local d = rng.int(#pool); s = s .. pool:sub(d + 1, d + 1) end
      if not used[s] then used[s] = true; return s end
    end
  end
end

local function randString(rng)
  local pool = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
  local n = rng.int(12) + 4
  local t = {}
  for i = 1, n do local d = rng.int(#pool); t[i] = pool:sub(d + 1, d + 1) end
  return table.concat(t)
end

-- A junk expression over the seed name and integer literals (no side effects).
local function junkExpr(seed, rng)
  local e = name(seed)
  for _ = 1, rng.int(2) + 1 do
    local op = ({ '+', '-', '%', '*' })[rng.int(4) + 1]
    local k = (op == '%') and (rng.int(97) + 3) or (rng.int(50) + 1)
    e = bin(op, e, num(k))
  end
  return e
end

-- Junk body statements. `live` = true when the branch actually executes
-- (always-true): only fresh block-scoped locals, so there is no observable
-- effect. `live` = false (always-false): may also "mutate" the seed for extra
-- confusion, since the body never runs.
local function junkBody(seed, g, rng, live)
  local body = {}
  local m = rng.int(2) + 1
  for _ = 1, m do body[#body + 1] = localStmt(g(), junkExpr(seed, rng)) end
  if not live and rng.int(2) == 0 then
    body[#body + 1] = assign(seed, junkExpr(seed, rng))
  end
  return body
end

-- Build one opaque `if`. Alternates between always-true and always-false forms.
local function opaqueIf(seed, g, rng)
  local A = rng.int(23) + 2                 -- divisor >= 2
  local modExpr = bin('%', name(seed), num(A))
  if rng.int(2) == 0 then
    -- always TRUE:  (seed % A) <= (A-1)   — body runs, but is inert
    return ifStmt(bin('<=', modExpr, num(A - 1)), junkBody(seed, g, rng, true))
  else
    -- always FALSE: (seed % A) == A       — body is dead
    return ifStmt(bin('==', modExpr, num(A)), junkBody(seed, g, rng, false))
  end
end

-- ── AST walk ─────────────────────────────────────────────────────────────────
local injectBlock, injectFunc, walkExprForFuncs

-- Recurse into any Function nodes reachable from an expression, treating each as
-- a fresh function (its own seed).
walkExprForFuncs = function(e, g, rng, density)
  if type(e) ~= 'table' then return end
  if e.k == 'Function' then injectFunc(e, g, rng, density); return end
  -- generic child traversal (covers Binop/Unop/Paren/Field/Index/Call/Method/Table)
  if e.left then walkExprForFuncs(e.left, g, rng, density) end
  if e.right then walkExprForFuncs(e.right, g, rng, density) end
  if e.operand then walkExprForFuncs(e.operand, g, rng, density) end
  if e.expr then walkExprForFuncs(e.expr, g, rng, density) end
  if e.obj then walkExprForFuncs(e.obj, g, rng, density) end
  if e.index then walkExprForFuncs(e.index, g, rng, density) end
  if e.func then walkExprForFuncs(e.func, g, rng, density) end
  if e.args then for _, a in ipairs(e.args) do walkExprForFuncs(a, g, rng, density) end end
  if e.fields then
    for _, f in ipairs(e.fields) do
      if f.key and type(f.key) == 'table' then walkExprForFuncs(f.key, g, rng, density) end
      walkExprForFuncs(f.value, g, rng, density)
    end
  end
end

-- Recurse into nested blocks/functions inside a single statement (same seed for
-- same-function blocks; a new seed for nested functions).
local function walkStmt(s, seed, g, rng, density)
  local k = s.k
  -- expressions that may contain function literals
  if s.exprs then for _, e in ipairs(s.exprs) do walkExprForFuncs(e, g, rng, density) end end
  if s.targets then for _, e in ipairs(s.targets) do walkExprForFuncs(e, g, rng, density) end end
  if s.call then walkExprForFuncs(s.call, g, rng, density) end
  if s.cond then walkExprForFuncs(s.cond, g, rng, density) end
  if s.start then walkExprForFuncs(s.start, g, rng, density) end
  if s.stop then walkExprForFuncs(s.stop, g, rng, density) end
  if s.step then walkExprForFuncs(s.step, g, rng, density) end
  -- nested blocks in the SAME function share the enclosing seed
  if k == 'Do' then injectBlock(s.body, seed, g, rng, density, false)
  elseif k == 'While' then injectBlock(s.body, seed, g, rng, density, false)
  elseif k == 'Repeat' then injectBlock(s.body, seed, g, rng, density, false); walkExprForFuncs(s.cond, g, rng, density)
  elseif k == 'NumFor' then injectBlock(s.body, seed, g, rng, density, false)
  elseif k == 'GenFor' then injectBlock(s.body, seed, g, rng, density, false)
  elseif k == 'If' then
    for _, c in ipairs(s.clauses) do
      walkExprForFuncs(c.cond, g, rng, density)
      injectBlock(c.body, seed, g, rng, density, false)
    end
    if s.elseBody then injectBlock(s.elseBody, seed, g, rng, density, false) end
  elseif k == 'LocalFunc' then injectFunc(s.func, g, rng, density)
  elseif k == 'FuncDecl' then injectFunc(s.func, g, rng, density)
  end
end

-- Transform a block (list of statements). `isFuncTop` => declare a fresh seed at
-- the top and use it for this block and its same-function descendants.
injectBlock = function(stmts, seed, g, rng, density, isFuncTop)
  if isFuncTop then
    seed = g()
  end
  -- recurse first (so nested functions/blocks get their own treatment)
  for _, s in ipairs(stmts) do walkStmt(s, seed, g, rng, density) end

  -- then splice opaque ifs BEFORE randomly chosen statements (never after a
  -- trailing return/break: inserting before a statement can't create
  -- unreachable code, and we simply don't append past the last statement).
  if seed then
    local out = {}
    for _, s in ipairs(stmts) do
      if rng.int(1000) < density then out[#out + 1] = opaqueIf(seed, g, rng) end
      out[#out + 1] = s
    end
    -- rewrite stmts in place
    for i = #stmts, 1, -1 do stmts[i] = nil end
    for i, s in ipairs(out) do stmts[i] = s end
    if isFuncTop then
      table.insert(stmts, 1, localStmt(seed, len(str(randString(rng)))))
    end
  end
end

injectFunc = function(fn, g, rng, density)
  injectBlock(fn.body, nil, g, rng, density, true)
end

-- ── bytecode junk: provably-unreachable dead opcodes ─────────────────────────
-- Inserts well-formed but UNREACHABLE instructions into a compiled proto's code,
-- so a linear-sweep disassembler decodes filler that never runs. Junk is only
-- placed immediately after an UNCONDITIONAL transfer (RETURN / TAILCALL / JMP),
-- which never falls through, so the inserted run can only be reached by a jump —
-- and every jump is relocated to land on its real (shifted) target, never on
-- junk. Because it never executes, its operands are irrelevant to behaviour; we
-- still keep them in range so the structural validator accepts the stream.
local Opcodes = require('opcodes')
local Op = Opcodes.Op

-- relative-jump opcodes whose sbx must be relocated after insertion
local JUMP = {
  [Op.JMP] = true, [Op.JMPIF] = true, [Op.JMPIFNOT] = true,
  [Op.FORPREP] = true, [Op.FORLOOP] = true, [Op.TFORLOOP] = true,
}
-- opcodes that never fall through => safe to append unreachable junk after
local TRANSFER = { [Op.RETURN] = true, [Op.TAILCALL] = true, [Op.JMP] = true }

-- Build one junk instruction using only register/immediate operands within the
-- proto's maxstack (the validator allows register indices in [0, maxstack]).
local function junkIns(maxstack, rng)
  local rmax = maxstack -- validator permits up to maxstack inclusive
  local function reg() return rng.int(rmax + 1) end
  local pick = rng.int(7)
  if pick == 0 then return { op = Op.MOVE, a = reg(), b = reg() }
  elseif pick == 1 then return { op = Op.LOADINT, a = reg(), sbx = rng.int(4096) }
  elseif pick == 2 then return { op = Op.ADD, a = reg(), b = reg(), c = reg() }
  elseif pick == 3 then return { op = Op.SUB, a = reg(), b = reg(), c = reg() }
  elseif pick == 4 then return { op = Op.MUL, a = reg(), b = reg(), c = reg() }
  elseif pick == 5 then return { op = Op.LOADBOOL, a = reg(), b = rng.int(2) }
  else return { op = Op.NEWTABLE, a = reg() }
  end
end

local function junkProto(proto, rng, density, maxRun)
  local code = proto.code
  local ncode = #code
  -- absolute jump targets in OLD indexing
  local absTarget = {}
  for i, ins in ipairs(code) do
    if JUMP[ins.op] then absTarget[i] = i + 1 + ins.sbx end
  end
  local newCode, newOf = {}, {}
  for i = 1, ncode do
    local ins = code[i]
    newCode[#newCode + 1] = ins
    newOf[i] = #newCode
    if TRANSFER[ins.op] and rng.int(1000) < density then
      local run = rng.int(maxRun) + 1
      for _ = 1, run do newCode[#newCode + 1] = junkIns(proto.maxstack, rng) end
    end
  end
  newOf[ncode + 1] = #newCode + 1
  -- relocate every real jump to its shifted target (never a junk slot). The
  -- jump instruction tables are the same refs in newCode, so patch via old idx.
  for oldI, ins in ipairs(code) do
    if JUMP[ins.op] then
      local tgt = absTarget[oldI]
      local newTarget = newOf[tgt] or (#newCode + 1)
      ins.sbx = newTarget - (newOf[oldI] + 1)
    end
  end
  proto.code = newCode
  for _, child in ipairs(proto.protos) do junkProto(child, rng, density, maxRun) end
end

function M.junk(proto, rng, opts)
  opts = opts or {}
  junkProto(proto, rng, opts.density or 700, opts.maxRun or 3)
  return proto
end

-- ── basic-block reordering (a safe, semantics-EXACT relative of control-flow
-- flattening) ────────────────────────────────────────────────────────────────
-- Splits a proto's code into basic blocks, shuffles their physical order
-- (pinning the entry block first so execution still starts correctly), and
-- threads the original fall-through edges with explicit jumps. Every instruction
-- still executes in the exact same runtime order — only the LAYOUT changes — so
-- there is no register/`top` liveness hazard at all. The payoff is the same as a
-- dispatcher: the linear byte order no longer matches control flow, so a reader
-- must reconstruct the CFG instead of reading top-to-bottom.
--
-- Opcodes that DO NOT fall through to the next instruction (so a reordered block
-- ending in one needs no threading jump).
local NOFALL = { [Op.JMP] = true, [Op.RETURN] = true, [Op.TAILCALL] = true, [Op.FORPREP] = true }

local function flattenProto(proto, rng)
  local code = proto.code
  local ncode = #code
  if ncode < 4 then
    for _, child in ipairs(proto.protos) do flattenProto(child, rng) end
    return
  end

  -- 1. leaders: instruction 1, every jump target, and the instruction after any
  --    control-transfer (so blocks break at all CFG edges).
  local absTarget = {}
  local leader = { [1] = true }
  for i, ins in ipairs(code) do
    if JUMP[ins.op] then
      local t = i + 1 + ins.sbx
      absTarget[i] = t
      leader[t] = true
      if i + 1 <= ncode then leader[i + 1] = true end
    elseif ins.op == Op.RETURN or ins.op == Op.TAILCALL then
      if i + 1 <= ncode then leader[i + 1] = true end
    end
  end

  -- 2. slice into blocks [start..end]; map each instruction index to its block.
  local starts = {}
  for i = 1, ncode do if leader[i] then starts[#starts + 1] = i end end
  local blocks, blockOf = {}, {}
  for bi, s in ipairs(starts) do
    local e = (starts[bi + 1] or (ncode + 1)) - 1
    blocks[bi] = { first = s, last = e }
    for j = s, e do blockOf[j] = bi end
  end

  -- fall-through successor block (nil when the block's last instr can't fall
  -- through, or there is no following instruction).
  for _, b in ipairs(blocks) do
    local lastOp = code[b.last].op
    if not NOFALL[lastOp] and b.last + 1 <= ncode then
      b.fall = blockOf[b.last + 1]
    end
  end

  -- 3. new order: entry block pinned first, the rest shuffled (Fisher-Yates).
  local order = {}
  for bi = 2, #blocks do order[#order + 1] = bi end
  for i = #order, 2, -1 do
    local j = rng.int(i) + 1
    order[i], order[j] = order[j], order[i]
  end
  table.insert(order, 1, 1)

  -- 4. emit instructions in the new block order; after any block with a
  --    fall-through successor, append a threading JMP (target = successor.first).
  --    Track each emitted slot so we can recompute offsets against new indices.
  local newCode, slotOldIdx, slotJmpTo = {}, {}, {}
  local newIndexOf = {} -- old instruction index -> new position
  for _, bi in ipairs(order) do
    local b = blocks[bi]
    for j = b.first, b.last do
      newCode[#newCode + 1] = code[j]
      newIndexOf[j] = #newCode
      slotOldIdx[#newCode] = j
    end
    if b.fall then
      newCode[#newCode + 1] = { op = Op.JMP, sbx = 0 }
      slotJmpTo[#newCode] = blocks[b.fall].first -- target as an OLD index
    end
  end
  newIndexOf[ncode + 1] = #newCode + 1

  -- 5. recompute sbx: original jumps against their mapped target, threading jumps
  --    against their successor's mapped first instruction.
  for pos, ins in ipairs(newCode) do
    local oldI = slotOldIdx[pos]
    if oldI and JUMP[ins.op] then
      ins.sbx = newIndexOf[absTarget[oldI]] - (pos + 1)
    elseif slotJmpTo[pos] then
      ins.sbx = newIndexOf[slotJmpTo[pos]] - (pos + 1)
    end
  end

  proto.code = newCode
  for _, child in ipairs(proto.protos) do flattenProto(child, rng) end
end

function M.flatten(proto, rng)
  flattenProto(proto, rng)
  return proto
end

-- Public: inject opaque predicates into a parsed chunk. `rng` is a Harden.prng
-- (has :int(n)); `opts.density` is the per-statement injection chance in
-- thousandths (default 350 = ~35%).
function M.inject(chunk, rng, opts)
  opts = opts or {}
  local density = opts.density or 350
  local g = idGen(rng)
  injectBlock(chunk.body, nil, g, rng, density, true)
  return chunk
end

return M
