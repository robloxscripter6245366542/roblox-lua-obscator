-- luau-vm/src/parser.lua
-- Recursive-descent parser with precedence climbing. Produces an AST of tables
-- tagged with `k`. Covers the executable Luau grammar the compiler lowers.

local Lexer = require('lexer')

local Parser = {}
Parser.__index = Parser

local BLOCK_END = { ['end'] = true, ['else'] = true, ['elseif'] = true, ['until'] = true }
-- binary op [left, right] priorities; right < left => right associative
local BINPRI = {
  ['or'] = { 1, 1 }, ['and'] = { 2, 2 },
  ['<'] = { 3, 3 }, ['>'] = { 3, 3 }, ['<='] = { 3, 3 }, ['>='] = { 3, 3 }, ['~='] = { 3, 3 }, ['=='] = { 3, 3 },
  ['|'] = { 4, 4 }, ['~'] = { 5, 5 }, ['&'] = { 6, 6 }, ['<<'] = { 7, 7 }, ['>>'] = { 7, 7 },
  ['..'] = { 9, 8 }, ['+'] = { 10, 10 }, ['-'] = { 10, 10 },
  ['*'] = { 11, 11 }, ['/'] = { 11, 11 }, ['//'] = { 11, 11 }, ['%'] = { 11, 11 },
  ['^'] = { 14, 13 },
}
local UNARY_PRI = 12

local function new(tokens, chunk)
  return setmetatable({ toks = tokens, i = 1, chunk = chunk or 'input' }, Parser)
end

function Parser:peek(o) return self.toks[self.i + (o or 0)] or self.toks[#self.toks] end
function Parser:next() local t = self:peek(); self.i = self.i + 1; return t end
function Parser:err(msg)
  local t = self:peek()
  error(self.chunk .. ':' .. t.line .. ': ' .. msg .. " near '" .. tostring(t.value) .. "'", 0)
end
function Parser:is(ty, v) local t = self:peek(); return t.type == ty and (v == nil or t.value == v) end
function Parser:isSym(v) return self:is('symbol', v) end
function Parser:isKw(v) return self:is('keyword', v) end
function Parser:accept(ty, v) if self:is(ty, v) then return self:next() end end
function Parser:expect(ty, v) if not self:is(ty, v) then self:err("'" .. tostring(v or ty) .. "' expected") end return self:next() end
function Parser:name() if not self:is('name') then self:err('name expected') end return self:next().value end

function Parser:parse()
  local body = self:block()
  if not self:is('eof') then self:err("'<eof>' expected") end
  return { k = 'Chunk', body = body }
end

function Parser:block()
  local stmts = {}
  while true do
    local t = self:peek()
    if t.type == 'eof' then break end
    if t.type == 'keyword' and BLOCK_END[t.value] then break end
    if t.type == 'keyword' and t.value == 'return' then stmts[#stmts + 1] = self:retStat(); break end
    local s = self:statement()
    if s then stmts[#stmts + 1] = s end
  end
  return stmts
end

function Parser:retStat()
  local line = self:next().line
  local exprs = {}
  local t = self:peek()
  local ends = t.type == 'eof' or (t.type == 'keyword' and BLOCK_END[t.value])
  if not ends and not self:isSym(';') then exprs = self:exprList() end
  self:accept('symbol', ';')
  return { k = 'Return', exprs = exprs, line = line }
end

function Parser:statement()
  local t = self:peek()
  if t.type == 'symbol' and t.value == ';' then self:next(); return nil end
  if t.type == 'symbol' and t.value == '::' then
    self:next(); local nm = self:name(); self:expect('symbol', '::')
    return { k = 'Label', name = nm, line = t.line }
  end
  if t.type == 'keyword' then
    local v = t.value
    if v == 'break' then self:next(); return { k = 'Break', line = t.line } end
    if v == 'goto' then self:next(); return { k = 'Goto', label = self:name(), line = t.line } end
    if v == 'do' then self:next(); local b = self:block(); self:expect('keyword', 'end'); return { k = 'Do', body = b, line = t.line } end
    if v == 'while' then return self:whileStat() end
    if v == 'repeat' then return self:repeatStat() end
    if v == 'if' then return self:ifStat() end
    if v == 'for' then return self:forStat() end
    if v == 'function' then return self:funcStat() end
    if v == 'local' then return self:localStat() end
  end
  return self:exprStat()
end

function Parser:whileStat()
  local line = self:next().line
  local cond = self:expr(); self:expect('keyword', 'do')
  local body = self:block(); self:expect('keyword', 'end')
  return { k = 'While', cond = cond, body = body, line = line }
end

function Parser:repeatStat()
  local line = self:next().line
  local body = self:block(); self:expect('keyword', 'until')
  local cond = self:expr()
  return { k = 'Repeat', body = body, cond = cond, line = line }
end

function Parser:ifStat()
  local line = self:next().line
  local clauses = {}
  local cond = self:expr(); self:expect('keyword', 'then')
  clauses[1] = { cond = cond, body = self:block() }
  while self:isKw('elseif') do
    self:next(); local c = self:expr(); self:expect('keyword', 'then')
    clauses[#clauses + 1] = { cond = c, body = self:block() }
  end
  local elseBody
  if self:accept('keyword', 'else') then elseBody = self:block() end
  self:expect('keyword', 'end')
  return { k = 'If', clauses = clauses, elseBody = elseBody, line = line }
end

function Parser:forStat()
  local line = self:next().line
  local first = self:name()
  if self:isSym('=') then
    self:next()
    local a = self:expr(); self:expect('symbol', ','); local b = self:expr()
    local c
    if self:accept('symbol', ',') then c = self:expr() end
    self:expect('keyword', 'do'); local body = self:block(); self:expect('keyword', 'end')
    return { k = 'NumFor', var = first, start = a, stop = b, step = c, body = body, line = line }
  end
  local names = { first }
  while self:accept('symbol', ',') do names[#names + 1] = self:name() end
  self:expect('keyword', 'in')
  local exprs = self:exprList()
  self:expect('keyword', 'do'); local body = self:block(); self:expect('keyword', 'end')
  return { k = 'GenFor', names = names, exprs = exprs, body = body, line = line }
end

function Parser:funcStat()
  local line = self:next().line
  local base = self:name()
  local path = {}
  local method
  while self:isSym('.') do self:next(); path[#path + 1] = self:name() end
  if self:accept('symbol', ':') then method = self:name() end
  local func = self:funcBody(line, method ~= nil)
  return { k = 'FuncDecl', base = base, path = path, method = method, func = func, line = line }
end

function Parser:localStat()
  local line = self:next().line
  if self:accept('keyword', 'function') then
    local nm = self:name()
    local func = self:funcBody(line, false)
    return { k = 'LocalFunc', name = nm, func = func, line = line }
  end
  local names = { self:localName() }
  while self:accept('symbol', ',') do names[#names + 1] = self:localName() end
  local exprs = {}
  if self:accept('symbol', '=') then exprs = self:exprList() end
  return { k = 'Local', names = names, exprs = exprs, line = line }
end

function Parser:localName()
  local nm = self:name()
  if self:accept('symbol', '<') then self:name(); self:expect('symbol', '>') end -- attribute, ignored
  return nm
end

function Parser:funcBody(line, isMethod)
  self:expect('symbol', '(')
  local params, isVararg = {}, false
  if isMethod then params[1] = 'self' end
  if not self:isSym(')') then
    repeat
      if self:isSym('...') then self:next(); isVararg = true; break end
      params[#params + 1] = self:name()
    until not self:accept('symbol', ',')
  end
  self:expect('symbol', ')')
  local body = self:block(); self:expect('keyword', 'end')
  return { k = 'Function', params = params, isVararg = isVararg, body = body, line = line }
end

-- Luau compound assignments desugar to a plain assignment: `t OP= e` becomes
-- `t = t OP (e)`. Single target only (Luau forbids `a, b += 1`).
local COMPOUND = {
  ['+='] = '+', ['-='] = '-', ['*='] = '*', ['/='] = '/',
  ['//='] = '//', ['%='] = '%', ['^='] = '^', ['..='] = '..',
}

-- Shallow-clone an lvalue node so the desugared RHS references a distinct node
-- from the assignment target (they share child subtrees, which is fine).
local function cloneLValue(n)
  local c = {}
  for k, v in pairs(n) do c[k] = v end
  return c
end

function Parser:exprStat()
  local line = self:peek().line
  local first = self:suffixed()
  local ct = self:peek()
  if ct.type == 'symbol' and COMPOUND[ct.value] then
    if first.k ~= 'Name' and first.k ~= 'Index' and first.k ~= 'Field' then self:err('cannot assign') end
    local op = COMPOUND[self:next().value]
    local rhs = self:expr()
    local sum = { k = 'Binop', op = op, left = cloneLValue(first), right = rhs, line = line }
    return { k = 'Assign', targets = { first }, exprs = { sum }, line = line }
  end
  if self:isSym('=') or self:isSym(',') then
    local targets = { first }
    while self:accept('symbol', ',') do targets[#targets + 1] = self:suffixed() end
    self:expect('symbol', '=')
    local exprs = self:exprList()
    for _, tg in ipairs(targets) do
      if tg.k ~= 'Name' and tg.k ~= 'Index' and tg.k ~= 'Field' then self:err('cannot assign') end
    end
    return { k = 'Assign', targets = targets, exprs = exprs, line = line }
  end
  if first.k ~= 'CallE' and first.k ~= 'Method' then self:err('syntax error') end
  return { k = 'CallStat', call = first, line = line }
end

function Parser:exprList()
  local list = { self:expr() }
  while self:accept('symbol', ',') do list[#list + 1] = self:expr() end
  return list
end

function Parser:expr() return self:subExpr(0) end

function Parser:getBinop()
  local t = self:peek()
  if t.type == 'symbol' and BINPRI[t.value] then return t.value end
  if t.type == 'keyword' and (t.value == 'and' or t.value == 'or') then return t.value end
end
function Parser:getUnop()
  local t = self:peek()
  if t.type == 'symbol' and (t.value == '-' or t.value == '#' or t.value == '~') then return t.value end
  if t.type == 'keyword' and t.value == 'not' then return t.value end
end

function Parser:subExpr(limit)
  local e
  local u = self:getUnop()
  if u then
    local line = self:next().line
    e = { k = 'Unop', op = u, operand = self:subExpr(UNARY_PRI), line = line }
  else
    e = self:simple()
  end
  while true do
    local op = self:getBinop()
    if not op or BINPRI[op][1] <= limit then break end
    local line = self:next().line
    local right = self:subExpr(BINPRI[op][2])
    e = { k = 'Binop', op = op, left = e, right = right, line = line }
  end
  return e
end

function Parser:simple()
  local t = self:peek()
  if t.type == 'number' then self:next(); return { k = 'Number', value = t.value, line = t.line } end
  if t.type == 'string' then self:next(); return { k = 'String', value = t.value, line = t.line } end
  if t.type == 'keyword' then
    if t.value == 'nil' then self:next(); return { k = 'Nil', line = t.line } end
    if t.value == 'true' then self:next(); return { k = 'True', line = t.line } end
    if t.value == 'false' then self:next(); return { k = 'False', line = t.line } end
    if t.value == 'function' then local l = self:next().line; return self:funcBody(l, false) end
  end
  if t.type == 'symbol' then
    if t.value == '...' then self:next(); return { k = 'Vararg', line = t.line } end
    if t.value == '{' then return self:table() end
  end
  return self:suffixed()
end

function Parser:primary()
  local t = self:peek()
  if t.type == 'symbol' and t.value == '(' then
    self:next(); local e = self:expr(); self:expect('symbol', ')')
    return { k = 'Paren', expr = e, line = t.line }
  end
  if t.type == 'name' then self:next(); return { k = 'Name', name = t.value, line = t.line } end
  self:err('unexpected symbol')
end

function Parser:suffixed()
  local e = self:primary()
  while true do
    local t = self:peek()
    if t.type == 'symbol' and t.value == '.' then
      self:next(); e = { k = 'Field', obj = e, name = self:name(), line = t.line }
    elseif t.type == 'symbol' and t.value == '[' then
      self:next(); local idx = self:expr(); self:expect('symbol', ']')
      e = { k = 'Index', obj = e, index = idx, line = t.line }
    elseif t.type == 'symbol' and t.value == ':' then
      self:next(); local m = self:name(); local args = self:callArgs()
      e = { k = 'Method', obj = e, method = m, args = args, line = t.line }
    elseif (t.type == 'symbol' and (t.value == '(' or t.value == '{')) or t.type == 'string' then
      e = { k = 'CallE', func = e, args = self:callArgs(), line = t.line }
    else break end
  end
  return e
end

function Parser:callArgs()
  local t = self:peek()
  if t.type == 'string' then self:next(); return { { k = 'String', value = t.value, line = t.line } } end
  if t.type == 'symbol' and t.value == '{' then return { self:table() } end
  self:expect('symbol', '(')
  local args = {}
  if not self:isSym(')') then args = self:exprList() end
  self:expect('symbol', ')')
  return args
end

function Parser:table()
  local line = self:expect('symbol', '{').line
  local fields = {}
  while not self:isSym('}') do
    if self:isSym('[') then
      self:next(); local key = self:expr(); self:expect('symbol', ']'); self:expect('symbol', '=')
      fields[#fields + 1] = { kind = 'keyed', key = key, value = self:expr() }
    elseif self:is('name') and self:peek(1).type == 'symbol' and self:peek(1).value == '=' then
      local key = self:next().value; self:next()
      fields[#fields + 1] = { kind = 'named', key = key, value = self:expr() }
    else
      fields[#fields + 1] = { kind = 'item', value = self:expr() }
    end
    if not self:accept('symbol', ',') and not self:accept('symbol', ';') then break end
  end
  self:expect('symbol', '}')
  return { k = 'Table', fields = fields, line = line }
end

function Parser.parseString(src, chunk)
  return new(Lexer.tokenize(src, chunk), chunk):parse()
end

return Parser
