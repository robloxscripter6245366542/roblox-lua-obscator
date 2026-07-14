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
