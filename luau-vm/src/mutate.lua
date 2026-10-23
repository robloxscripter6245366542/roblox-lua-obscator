-- luau-vm/src/mutate.lua
-- Per-build source mutation of the VM runtime modules: parse -> scope-analyze ->
-- rename every local to a fresh per-build identifier -> unparse. Globals, stdlib
-- names, `require`, and table field/key names are never declarations, so they
-- pass through untouched and the module keeps working; only the *local* names
-- (R, K, pc, ins, handler temporaries, …) change, so a generic devirtualizer
-- keyed to one build's readable VM source does not transfer to the next build.
--
-- Correctness rests on the unparser being a faithful printer (proven by running
-- the whole test suite against round-tripped modules) plus scope analysis being
-- the same production pass the compiler uses. Renaming a declaration also
-- renames every reference, because scope links each Name to the same decl.

local Parser = require('parser')
local Scope = require('scope')
local Unparse = require('unparse')

local M = {}

-- fresh identifier generator: `_` + lowercase/digits => never a keyword, a
-- stdlib global, or `require`, so a renamed local can't collide with anything
-- the module references by global name.
local function idGen(rng)
  local pool = 'abcdefghijklmnopqrstuvwxyz0123456789'
  local used = {}
  return function()
    while true do
      local s = '_'
      for _ = 1, 6 do local d = rng.int(#pool); s = s .. pool:sub(d + 1, d + 1) end
      if not used[s] then used[s] = true; return s end
    end
  end
end

-- Assign a fresh name to a declaration (idempotent per decl object).
local function rename(decl, gen)
  if decl and not decl.newname then decl.newname = gen() end
end

local walkStmt, walkExpr, walkBlock

walkExpr = function(e, gen)
  if type(e) ~= 'table' then return end
  local k = e.k
  if k == 'Function' then
    if e.paramDecls then for _, d in ipairs(e.paramDecls) do rename(d, gen) end end
    walkBlock(e.body, gen)
    return
  end
  if e.left then walkExpr(e.left, gen) end
  if e.right then walkExpr(e.right, gen) end
  if e.operand then walkExpr(e.operand, gen) end
  if e.expr then walkExpr(e.expr, gen) end
  if e.obj then walkExpr(e.obj, gen) end
  if e.index then walkExpr(e.index, gen) end
  if e.func then walkExpr(e.func, gen) end
  if e.args then for _, a in ipairs(e.args) do walkExpr(a, gen) end end
  if e.clauses then for _, c in ipairs(e.clauses) do walkExpr(c.cond, gen); walkExpr(c.value, gen) end end
  if e.elseValue then walkExpr(e.elseValue, gen) end
  if e.fields then
    for _, f in ipairs(e.fields) do
      if f.key and type(f.key) == 'table' then walkExpr(f.key, gen) end
      walkExpr(f.value, gen)
    end
  end
end

walkStmt = function(s, gen)
  local k = s.k
  if k == 'Local' then
    if s.exprs then for _, e in ipairs(s.exprs) do walkExpr(e, gen) end end
    if s.decls then for _, d in ipairs(s.decls) do rename(d, gen) end end
  elseif k == 'LocalFunc' then
    rename(s.decl, gen) -- visible in its own body (recursion) before params
    walkExpr(s.func, gen)
  elseif k == 'Assign' then
    for _, t in ipairs(s.targets) do walkExpr(t, gen) end
    for _, e in ipairs(s.exprs) do walkExpr(e, gen) end
  elseif k == 'CallStat' then walkExpr(s.call, gen)
  elseif k == 'Do' then walkBlock(s.body, gen)
  elseif k == 'While' then walkExpr(s.cond, gen); walkBlock(s.body, gen)
  elseif k == 'Repeat' then walkBlock(s.body, gen); walkExpr(s.cond, gen)
  elseif k == 'If' then
    for _, c in ipairs(s.clauses) do walkExpr(c.cond, gen); walkBlock(c.body, gen) end
    if s.elseBody then walkBlock(s.elseBody, gen) end
  elseif k == 'NumFor' then
    walkExpr(s.start, gen); walkExpr(s.stop, gen); if s.step then walkExpr(s.step, gen) end
    rename(s.varDecl, gen); walkBlock(s.body, gen)
  elseif k == 'GenFor' then
    for _, e in ipairs(s.exprs) do walkExpr(e, gen) end
    if s.decls then for _, d in ipairs(s.decls) do rename(d, gen) end end
    walkBlock(s.body, gen)
  elseif k == 'FuncDecl' then walkExpr(s.func, gen)
  elseif k == 'Return' then
    if s.exprs then for _, e in ipairs(s.exprs) do walkExpr(e, gen) end end
  end
end

walkBlock = function(stmts, gen)
  for _, s in ipairs(stmts) do walkStmt(s, gen) end
end

-- Public: return a semantically-identical, locally-renamed copy of `src`.
function M.mutate(src, rng, chunkName)
  local chunk = Parser.parseString(src, chunkName or 'mod')
  Scope.analyze(chunk)
  local gen = idGen(rng)
  walkBlock(chunk.body, gen)
  return Unparse.unparse(chunk)
end

return M
