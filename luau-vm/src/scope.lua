-- luau-vm/src/scope.lua
-- Capture analysis. Resolves every Name to its declaration and marks a
-- declaration `captured` when it is referenced from a nested function. The
-- compiler uses `captured` to decide whether a local lives in a cell (box) so
-- closures can share it as an upvalue.
--
-- Declaration objects are attached to the AST and reused by the compiler, which
-- fills in `owner`/`reg` during code generation.

local Scope = {}

local function newScope(parent, fdepth) return { vars = {}, parent = parent, fdepth = fdepth } end
local function declare(scope, name)
  local d = { name = name, captured = false, fdepth = scope.fdepth }
  scope.vars[name] = d
  return d
end
local function lookup(scope, name)
  local s = scope
  while s do local d = s.vars[name]; if d then return d end; s = s.parent end
  return nil
end

local rExpr, rStmt, rBlock, rFunc

function Scope.analyze(chunk)
  local top = newScope(nil, 0)
  for _, s in ipairs(chunk.body) do rStmt(s, top) end
  return chunk
end

function rBlock(stmts, parent)
  local scope = newScope(parent, parent.fdepth)
  for _, s in ipairs(stmts) do rStmt(s, scope) end
end

function rFunc(fn, parent)
  local scope = newScope(parent, parent.fdepth + 1)
  fn.paramDecls = {}
  for i, p in ipairs(fn.params) do fn.paramDecls[i] = declare(scope, p) end
  for _, s in ipairs(fn.body) do rStmt(s, scope) end
end

local function ref(node, scope)
  local d = lookup(scope, node.name)
  if d then
    node.decl = d
    if d.fdepth ~= scope.fdepth then d.captured = true end
  else
    node.decl = nil -- global
  end
end

function rExpr(e, scope)
  local k = e.k
  if k == 'Name' then ref(e, scope)
  elseif k == 'Paren' then rExpr(e.expr, scope)
  elseif k == 'Field' then rExpr(e.obj, scope)
  elseif k == 'Index' then rExpr(e.obj, scope); rExpr(e.index, scope)
  elseif k == 'CallE' then rExpr(e.func, scope); for _, a in ipairs(e.args) do rExpr(a, scope) end
  elseif k == 'Method' then rExpr(e.obj, scope); for _, a in ipairs(e.args) do rExpr(a, scope) end
  elseif k == 'Binop' then rExpr(e.left, scope); rExpr(e.right, scope)
  elseif k == 'IfExpr' then
    for _, c in ipairs(e.clauses) do rExpr(c.cond, scope); rExpr(c.value, scope) end
    rExpr(e.elseValue, scope)
  elseif k == 'Unop' then rExpr(e.operand, scope)
  elseif k == 'Function' then rFunc(e, scope)
  elseif k == 'Table' then
    for _, f in ipairs(e.fields) do
      if f.kind == 'keyed' then rExpr(f.key, scope) end
      rExpr(f.value, scope)
    end
  end
end

function rStmt(s, scope)
  local k = s.k
  if k == 'Local' then
    for _, e in ipairs(s.exprs) do rExpr(e, scope) end
    s.decls = {}
    for i, nm in ipairs(s.names) do s.decls[i] = declare(scope, nm) end
  elseif k == 'Assign' then
    for _, t in ipairs(s.targets) do rExpr(t, scope) end
    for _, e in ipairs(s.exprs) do rExpr(e, scope) end
  elseif k == 'CallStat' then rExpr(s.call, scope)
  elseif k == 'Do' then rBlock(s.body, scope)
  elseif k == 'While' then rExpr(s.cond, scope); rBlock(s.body, scope)
  elseif k == 'Repeat' then
    local inner = newScope(scope, scope.fdepth)
    for _, st in ipairs(s.body) do rStmt(st, inner) end
    rExpr(s.cond, inner)
  elseif k == 'If' then
    for _, c in ipairs(s.clauses) do rExpr(c.cond, scope); rBlock(c.body, scope) end
    if s.elseBody then rBlock(s.elseBody, scope) end
  elseif k == 'NumFor' then
    rExpr(s.start, scope); rExpr(s.stop, scope); if s.step then rExpr(s.step, scope) end
    local inner = newScope(scope, scope.fdepth)
    s.varDecl = declare(inner, s.var)
    for _, st in ipairs(s.body) do rStmt(st, inner) end
  elseif k == 'GenFor' then
    for _, e in ipairs(s.exprs) do rExpr(e, scope) end
    local inner = newScope(scope, scope.fdepth)
    s.decls = {}
    for i, nm in ipairs(s.names) do s.decls[i] = declare(inner, nm) end
    for _, st in ipairs(s.body) do rStmt(st, inner) end
  elseif k == 'FuncDecl' then
    -- base is a reference (assignment target); resolve it
    local nameNode = { k = 'Name', name = s.base, line = s.line }
    ref(nameNode, scope)
    s.baseDecl = nameNode.decl
    rFunc(s.func, scope)
  elseif k == 'LocalFunc' then
    s.decl = declare(scope, s.name) -- visible in its own body (recursion)
    rFunc(s.func, scope)
  elseif k == 'Return' then
    for _, e in ipairs(s.exprs) do rExpr(e, scope) end
  end
  -- Break / Goto / Label: nothing
end

return Scope
