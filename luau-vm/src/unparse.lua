-- luau-vm/src/unparse.lua
-- Faithful AST -> Lua source printer. Used to emit a per-build-mutated copy of
-- the VM runtime modules (see mutate.lua): parse -> rename locals -> unparse.
--
-- Safety by construction:
--   * every binary/unary expression is fully parenthesized, so the output never
--     depends on operator precedence being re-derived correctly;
--   * statements are separated by ';', so no `a\n(b)` call-ambiguity can arise;
--   * numbers are emitted from their original lexeme (no float re-formatting);
--   * strings are re-escaped with 3-digit numeric escapes for every control /
--     quote / backslash byte, so any byte value round-trips exactly.
-- A declaration's name comes from decl.newname when set (the renamer fills it),
-- else the original identifier; globals/fields/keys are never a decl, so they
-- pass through untouched — which is what keeps `require`, stdlib, and table
-- field names intact.

local M = {}

local function q(s)
  local out = s:gsub('[%c"\\]', function(c)
    if c == '\\' then return '\\\\' end
    if c == '"' then return '\\"' end
    return string.format('\\%03d', c:byte())
  end)
  return '"' .. out .. '"'
end

local function declName(decl, orig) return (decl and decl.newname) or orig end

local emitExpr, emitBlock

-- comma-separated expression list
local function emitList(w, list)
  for i, e in ipairs(list) do
    if i > 1 then w[#w + 1] = ',' end
    emitExpr(w, e)
  end
end

emitExpr = function(w, e)
  local k = e.k
  if k == 'Number' then w[#w + 1] = e.value
  elseif k == 'String' then w[#w + 1] = q(e.value)
  elseif k == 'Nil' then w[#w + 1] = 'nil'
  elseif k == 'True' then w[#w + 1] = 'true'
  elseif k == 'False' then w[#w + 1] = 'false'
  elseif k == 'Vararg' then w[#w + 1] = '...'
  elseif k == 'Name' then w[#w + 1] = declName(e.decl, e.name)
  elseif k == 'Paren' then w[#w + 1] = '('; emitExpr(w, e.expr); w[#w + 1] = ')'
  elseif k == 'Field' then emitExpr(w, e.obj); w[#w + 1] = '.'; w[#w + 1] = e.name
  elseif k == 'Index' then emitExpr(w, e.obj); w[#w + 1] = '['; emitExpr(w, e.index); w[#w + 1] = ']'
  elseif k == 'CallE' then emitExpr(w, e.func); w[#w + 1] = '('; emitList(w, e.args); w[#w + 1] = ')'
  elseif k == 'Method' then
    emitExpr(w, e.obj); w[#w + 1] = ':'; w[#w + 1] = e.method
    w[#w + 1] = '('; emitList(w, e.args); w[#w + 1] = ')'
  elseif k == 'Unop' then
    w[#w + 1] = '('; w[#w + 1] = e.op; w[#w + 1] = (e.op == 'not') and ' ' or ''
    emitExpr(w, e.operand); w[#w + 1] = ')'
  elseif k == 'Binop' then
    w[#w + 1] = '('; emitExpr(w, e.left); w[#w + 1] = ' ' .. e.op .. ' '
    emitExpr(w, e.right); w[#w + 1] = ')'
  elseif k == 'Function' then
    w[#w + 1] = 'function'; M.emitFuncBody(w, e)
  elseif k == 'Table' then
    w[#w + 1] = '{'
    for i, f in ipairs(e.fields) do
      if i > 1 then w[#w + 1] = ',' end
      if f.kind == 'named' then w[#w + 1] = f.key .. '='; emitExpr(w, f.value)
      elseif f.kind == 'keyed' then w[#w + 1] = '['; emitExpr(w, f.key); w[#w + 1] = ']='; emitExpr(w, f.value)
      else emitExpr(w, f.value) end
    end
    w[#w + 1] = '}'
  elseif k == 'IfExpr' then
    w[#w + 1] = '('
    for _, c in ipairs(e.clauses) do
      w[#w + 1] = 'if '; emitExpr(w, c.cond); w[#w + 1] = ' then '; emitExpr(w, c.value); w[#w + 1] = ' else '
    end
    -- close: the elseValue sits inside the innermost else; nesting via repeated
    -- "else if ... then ... else": emit elseValue once at the end
    emitExpr(w, e.elseValue)
    w[#w + 1] = ')'
  else
    error('unparse: cannot emit expr ' .. tostring(k))
  end
end

-- Emit `(params[,...]) body end`. ALL params are explicit (including a method's
-- implicit `self`), so callers must use the dot form of a method declaration —
-- this lets `self` be renamed like any other local.
function M.emitFuncBody(w, fn)
  w[#w + 1] = '('
  for i, p in ipairs(fn.params) do
    if i > 1 then w[#w + 1] = ',' end
    w[#w + 1] = declName(fn.paramDecls and fn.paramDecls[i], p)
  end
  if fn.isVararg then w[#w + 1] = (#fn.params > 0 and ',' or '') .. '...' end
  w[#w + 1] = ')'
  emitBlock(w, fn.body)
  w[#w + 1] = 'end'
end
local emitFuncBody = M.emitFuncBody

local function emitStmt(w, s)
  local k = s.k
  if k == 'Local' then
    w[#w + 1] = 'local '
    for i in ipairs(s.names) do
      if i > 1 then w[#w + 1] = ',' end
      w[#w + 1] = declName(s.decls and s.decls[i], s.names[i])
    end
    if s.exprs and #s.exprs > 0 then w[#w + 1] = '='; emitList(w, s.exprs) end
  elseif k == 'LocalFunc' then
    -- must stay `local function NAME` so the name is in scope in its own body
    -- (recursion); `local NAME = function` would not be.
    w[#w + 1] = 'local function ' .. declName(s.decl, s.name)
    emitFuncBody(w, s.func)
  elseif k == 'Assign' then
    emitList(w, s.targets); w[#w + 1] = '='; emitList(w, s.exprs)
  elseif k == 'CallStat' then emitExpr(w, s.call)
  elseif k == 'Do' then w[#w + 1] = 'do'; emitBlock(w, s.body); w[#w + 1] = 'end'
  elseif k == 'While' then
    w[#w + 1] = 'while '; emitExpr(w, s.cond); w[#w + 1] = ' do'; emitBlock(w, s.body); w[#w + 1] = 'end'
  elseif k == 'Repeat' then
    w[#w + 1] = 'repeat'; emitBlock(w, s.body); w[#w + 1] = 'until '; emitExpr(w, s.cond)
  elseif k == 'If' then
    for i, c in ipairs(s.clauses) do
      w[#w + 1] = (i == 1) and 'if ' or 'elseif '
      emitExpr(w, c.cond); w[#w + 1] = ' then'; emitBlock(w, c.body)
    end
    if s.elseBody then w[#w + 1] = 'else'; emitBlock(w, s.elseBody) end
    w[#w + 1] = 'end'
  elseif k == 'NumFor' then
    w[#w + 1] = 'for ' .. declName(s.varDecl, s.var) .. '='
    emitExpr(w, s.start); w[#w + 1] = ','; emitExpr(w, s.stop)
    if s.step then w[#w + 1] = ','; emitExpr(w, s.step) end
    w[#w + 1] = ' do'; emitBlock(w, s.body); w[#w + 1] = 'end'
  elseif k == 'GenFor' then
    w[#w + 1] = 'for '
    for i in ipairs(s.names) do
      if i > 1 then w[#w + 1] = ',' end
      w[#w + 1] = declName(s.decls and s.decls[i], s.names[i])
    end
    w[#w + 1] = ' in '; emitList(w, s.exprs); w[#w + 1] = ' do'; emitBlock(w, s.body); w[#w + 1] = 'end'
  elseif k == 'FuncDecl' then
    -- always dot-form; a method's `self` is params[1] and is emitted explicitly
    -- by emitFuncBody, so `obj:m()` (self as first arg) still resolves correctly.
    w[#w + 1] = 'function ' .. declName(s.baseDecl, s.base)
    for _, p in ipairs(s.path) do w[#w + 1] = '.' .. p end
    if s.method then w[#w + 1] = '.' .. s.method end
    emitFuncBody(w, s.func)
  elseif k == 'Return' then
    w[#w + 1] = 'return '
    if s.exprs then emitList(w, s.exprs) end
  elseif k == 'Break' then w[#w + 1] = 'break'
  elseif k == 'Continue' then w[#w + 1] = 'continue'
  else
    error('unparse: cannot emit stmt ' .. tostring(k))
  end
end

emitBlock = function(w, stmts)
  w[#w + 1] = ' '
  for _, s in ipairs(stmts) do emitStmt(w, s); w[#w + 1] = ';\n' end
end

function M.unparse(chunk)
  local w = {}
  for _, s in ipairs(chunk.body) do emitStmt(w, s); w[#w + 1] = ';\n' end
  return table.concat(w)
end

return M
