-- luau-vm/src/compiler.lua
-- Lowers the AST into register-based bytecode protos.
--
-- Register model: a function's locals occupy the low registers; expression
-- temporaries are allocated above `freereg` and freed by restoring it. Captured
-- locals (scope.captured) are boxed with NEWCELL and accessed via GETCELL/SETCELL
-- so closures can share them as upvalues.
--
-- Multi-value positions (last of a call-arg / return / local-init / assignment
-- list) use the count convention from opcodes.lua (0 = "to top").

local Parser = require('parser')
local Scope = require('scope')
local Opcodes = require('opcodes')
local Op = Opcodes.Op

local Compiler = {}

local function isMultiExpr(e) return e.k == 'CallE' or e.k == 'Method' or e.k == 'Vararg' end

-- '...' is only valid inside a vararg function (Lua/Luau reject it otherwise).
local function assertVararg(fs, line)
  if not fs.proto.isVararg then
    error("ferret-vm: cannot use '...' outside a vararg function (line " .. tostring(line) .. ')')
  end
end

-- ── function state ───────────────────────────────────────────────────────────
local FS = {}
FS.__index = FS

local function newFS(parent, isVararg)
  return setmetatable({
    parent = parent,
    proto = { code = {}, consts = {}, protos = {}, upvals = {}, lines = {}, numparams = 0, isVararg = isVararg, maxstack = 2 },
    freereg = 0,
    constMap = {},
    upvalMap = {},   -- decl -> upvalue index
    loops = {},      -- stack of { breaks = {} }
    lines = {},
  }, FS)
end

function FS:emit(ins, line)
  local code = self.proto.code
  code[#code + 1] = ins
  self.proto.lines[#code] = line
  return #code
end
function FS:here() return #self.proto.code + 1 end -- index the NEXT emitted instruction will get
function FS:patch(j, target)
  self.proto.code[j].sbx = target - (j + 1)
end
function FS:reserve(n)
  self.freereg = self.freereg + n
  if self.freereg > self.proto.maxstack then self.proto.maxstack = self.freereg end
end

function FS:const(v)
  local key = type(v) .. '\0' .. tostring(v)
  local idx = self.constMap[key]
  if idx then return idx end
  local consts = self.proto.consts
  consts[#consts + 1] = v
  idx = #consts
  self.constMap[key] = idx
  return idx
end

-- resolve a decl declared in an enclosing function to an upvalue index here.
function FS:upval(decl)
  local cached = self.upvalMap[decl]
  if cached then return cached end
  local parent = self.parent
  local desc
  if decl.owner == parent then
    desc = { kind = 'reg', index = decl.reg }
  else
    desc = { kind = 'up', index = parent:upval(decl) }
  end
  local ups = self.proto.upvals
  ups[#ups + 1] = desc
  local idx = #ups
  self.upvalMap[decl] = idx
  return idx
end

-- ── expression compilation ───────────────────────────────────────────────────
local compileExpr, compileExprInto, compileStmt, compileBlock, compileFunc

-- Return a register holding a non-cell local's value directly, else nil.
local function localReg(fs, node)
  if node.k == 'Name' and node.decl and node.decl.owner == fs and not node.decl.captured then
    return node.decl.reg
  end
  return nil
end

-- Compile into a freshly reserved register at the top; return it.
local function exprNext(fs, node)
  local r = fs.freereg
  fs:reserve(1)
  compileExprInto(fs, node, r)
  return r
end

-- Register holding node's value: a local reg (no copy) or a fresh temp.
local function exprAny(fs, node)
  local lr = localReg(fs, node)
  if lr then return lr end
  return exprNext(fs, node)
end

-- Compile a call (CallE/Method). Places results at `base`; nresults=-1 => multi.
local function compileCall(fs, node, base, nresults, line)
  if node.k == 'Method' then
    -- SELF: R[base+1]=obj, R[base]=obj[method]
    local robj = exprAny(fs, node.obj)
    fs.freereg = base
    fs:reserve(2)
    fs:emit({ op = Op.SELF, a = base, b = robj, c = fs:const(node.method) }, line)
    local argBase = base + 2
    fs.freereg = argBase
    local b = fs:explistOpen(node.args, argBase) -- args after self
    -- total args = self + nargs; adjust B (b is count field for args-after-self)
    local B
    if b == 0 then B = 0 else B = (b - 1) + 1 + 1 end -- (nargs) + self + 1
    fs:emit({ op = Op.CALL, a = base, b = B, c = (nresults == -1) and 0 or (nresults + 1) }, line)
  else
    fs.freereg = base
    local rfn = base
    fs:reserve(1)
    compileExprInto(fs, node.func, rfn)
    local b = fs:explistOpen(node.args, base + 1)
    fs:emit({ op = Op.CALL, a = base, b = b, c = (nresults == -1) and 0 or (nresults + 1) }, line)
  end
  fs.freereg = base + math.max(nresults, 0)
end

-- Compile a list of exprs into consecutive regs from `base`.
-- Returns the CALL/RETURN "count" field: exact = n+1, or 0 (multi, to top).
function FS:explistOpen(exprs, base)
  local n = #exprs
  self.freereg = base
  if n == 0 then return 1 end
  for i = 1, n - 1 do
    local r = base + i - 1
    self.freereg = r
    self:reserve(1)
    compileExprInto(self, exprs[i], r)
  end
  local last = exprs[n]
  local lastReg = base + n - 1
  if isMultiExpr(last) then
    self.freereg = lastReg
    if last.k == 'Vararg' then
      assertVararg(self, last.line)
      self:reserve(1)
      self:emit({ op = Op.VARARG, a = lastReg, b = 0 }, last.line)
    else
      compileCall(self, last, lastReg, -1, last.line)
    end
    return 0
  else
    self.freereg = lastReg
    self:reserve(1)
    compileExprInto(self, last, lastReg)
    return n + 1
  end
end

-- Compile `exprs` so EXACTLY `want` values land in base..base+want-1. A trailing
-- call/vararg is closed to the exact number still needed (so a call returning
-- fewer values nil-fills the rest, instead of leaving stale registers), and any
-- shortfall is padded with nil. Used by local-decl and multi-assign, which — unlike
-- return/call-args — need a fixed value count regardless of what the RHS produces.
function FS:explistExact(exprs, base, want)
  local n = #exprs
  self.freereg = base
  if n == 0 then
    for i = 0, want - 1 do self:emit({ op = Op.LOADNIL, a = base + i, b = 0 }) end
  else
    for i = 1, n - 1 do -- all but the last: one value each (evaluated for effect even if beyond want)
      local r = base + i - 1
      self.freereg = r; self:reserve(1)
      compileExprInto(self, exprs[i], r)
    end
    local last = exprs[n]
    local lastReg = base + n - 1
    local remaining = want - (n - 1) -- values the last expr must supply
    if isMultiExpr(last) then
      local req = remaining >= 1 and remaining or 1 -- evaluate even when discarded (side effects)
      self.freereg = lastReg; self:reserve(req)
      if last.k == 'Vararg' then
        assertVararg(self, last.line)
        self:emit({ op = Op.VARARG, a = lastReg, b = req + 1 }, last.line)
      else
        compileCall(self, last, lastReg, req, last.line)
      end
    else
      self.freereg = lastReg; self:reserve(1)
      compileExprInto(self, last, lastReg)
      for i = 1, remaining - 1 do -- want > #exprs: pad the extra targets with nil
        self:emit({ op = Op.LOADNIL, a = lastReg + i, b = 0 }, last.line)
      end
    end
  end
  self.freereg = base + want
  if self.freereg > self.proto.maxstack then self.proto.maxstack = self.freereg end
end

local BINOP = {
  ['+'] = Op.ADD, ['-'] = Op.SUB, ['*'] = Op.MUL, ['/'] = Op.DIV, ['%'] = Op.MOD,
  ['^'] = Op.POW, ['//'] = Op.IDIV, ['&'] = Op.BAND, ['|'] = Op.BOR, ['~'] = Op.BXOR,
  ['<<'] = Op.SHL, ['>>'] = Op.SHR,
}

compileExprInto = function(fs, node, target)
  local k = node.k
  local line = node.line
  if k == 'Nil' then fs:emit({ op = Op.LOADNIL, a = target, b = 0 }, line)
  elseif k == 'True' then fs:emit({ op = Op.LOADBOOL, a = target, b = 1 }, line)
  elseif k == 'False' then fs:emit({ op = Op.LOADBOOL, a = target, b = 0 }, line)
  elseif k == 'Number' then
    local v = tonumber(node.value)
    -- small integer immediates avoid a constant slot
    if math.type and math.type(v) == 'integer' and v >= -32768 and v <= 32767 then
      fs:emit({ op = Op.LOADINT, a = target, sbx = v }, line)
    elseif not math.type and v == math.floor(v) and v >= -32768 and v <= 32767 then
      fs:emit({ op = Op.LOADINT, a = target, sbx = v }, line)
    else
      fs:emit({ op = Op.LOADK, a = target, bx = fs:const(v) }, line)
    end
  elseif k == 'String' then fs:emit({ op = Op.LOADK, a = target, bx = fs:const(node.value) }, line)
  elseif k == 'Vararg' then assertVararg(fs, line); fs:emit({ op = Op.VARARG, a = target, b = 2 }, line)
  elseif k == 'Paren' then
    compileExprInto(fs, node.expr, target) -- single value already
  elseif k == 'Name' then
    local d = node.decl
    if not d then
      fs:emit({ op = Op.GETGLOBAL, a = target, bx = fs:const(node.name) }, line)
    elseif d.owner == fs then
      if d.captured then fs:emit({ op = Op.GETCELL, a = target, b = d.reg }, line)
      elseif d.reg ~= target then fs:emit({ op = Op.MOVE, a = target, b = d.reg }, line) end
    else
      fs:emit({ op = Op.GETUPVAL, a = target, b = fs:upval(d) }, line)
    end
  elseif k == 'Field' then
    local save = fs.freereg
    local robj = exprAny(fs, node.obj)
    fs:emit({ op = Op.GETFIELD, a = target, b = robj, bx = fs:const(node.name) }, line)
    fs.freereg = save
  elseif k == 'Index' then
    local save = fs.freereg
    local robj = exprAny(fs, node.obj)
    local ridx = exprAny(fs, node.index)
    fs:emit({ op = Op.GETTABLE, a = target, b = robj, c = ridx }, line)
    fs.freereg = save
  elseif k == 'CallE' or k == 'Method' then
    compileCall(fs, node, target, 1, line)
  elseif k == 'Function' then
    compileFunc(fs, node, target)
  elseif k == 'Table' then
    compileTable(fs, node, target)
  elseif k == 'Unop' then
    local save = fs.freereg
    local rb = exprAny(fs, node.operand)
    local opmap = { ['-'] = Op.UNM, ['not'] = Op.NOT, ['#'] = Op.LEN, ['~'] = Op.BNOT }
    fs:emit({ op = opmap[node.op], a = target, b = rb }, line)
    fs.freereg = save
  elseif k == 'Binop' then
    compileBinop(fs, node, target)
  elseif k == 'IfExpr' then
    -- Luau if-then-else expression: each branch stores its value into `target`.
    local endJumps = {}
    for _, clause in ipairs(node.clauses) do
      local save = fs.freereg
      local rc = exprNext(fs, clause.cond)
      fs.freereg = save
      local jnext = fs:emit({ op = Op.JMPIFNOT, a = rc, sbx = 0 }, clause.cond.line)
      compileExprInto(fs, clause.value, target)
      endJumps[#endJumps + 1] = fs:emit({ op = Op.JMP, sbx = 0 }, line)
      fs:patch(jnext, fs:here())
    end
    compileExprInto(fs, node.elseValue, target)
    for _, j in ipairs(endJumps) do fs:patch(j, fs:here()) end
  else
    error('compiler: cannot compile expr ' .. tostring(k))
  end
end

function compileBinop(fs, node, target)
  local op, line = node.op, node.line
  if op == 'and' then
    compileExprInto(fs, node.left, target)
    local j = fs:emit({ op = Op.JMPIFNOT, a = target, sbx = 0 }, line)
    compileExprInto(fs, node.right, target)
    fs:patch(j, fs:here())
    return
  elseif op == 'or' then
    compileExprInto(fs, node.left, target)
    local j = fs:emit({ op = Op.JMPIF, a = target, sbx = 0 }, line)
    compileExprInto(fs, node.right, target)
    fs:patch(j, fs:here())
    return
  end
  local save = fs.freereg
  if op == '..' then
    local r1 = exprNext(fs, node.left)
    local r2 = exprNext(fs, node.right)
    fs:emit({ op = Op.CONCAT, a = target, b = r1, c = r2 }, line)
  elseif BINOP[op] then
    local rb = exprAny(fs, node.left)
    local rc = exprAny(fs, node.right)
    fs:emit({ op = BINOP[op], a = target, b = rb, c = rc }, line)
  elseif op == '==' or op == '~=' then
    local rb = exprAny(fs, node.left)
    local rc = exprAny(fs, node.right)
    fs:emit({ op = Op.EQ, a = target, b = rb, c = rc }, line)
    if op == '~=' then fs:emit({ op = Op.NOT, a = target, b = target }, line) end
  elseif op == '<' or op == '>' then
    local l, r = node.left, node.right
    if op == '>' then l, r = r, l end
    local rb = exprAny(fs, l)
    local rc = exprAny(fs, r)
    fs:emit({ op = Op.LT, a = target, b = rb, c = rc }, line)
  elseif op == '<=' or op == '>=' then
    local l, r = node.left, node.right
    if op == '>=' then l, r = r, l end
    local rb = exprAny(fs, l)
    local rc = exprAny(fs, r)
    fs:emit({ op = Op.LE, a = target, b = rb, c = rc }, line)
  else
    error('compiler: bad binop ' .. tostring(op))
  end
  fs.freereg = save
end

function compileTable(fs, node, target)
  -- Positional (array) values are held in a contiguous block above the table
  -- register and flushed with one SETLIST at the END, so they win over any
  -- same-index keyed field (matching Lua's evaluation order). Keyed/named
  -- fields are stored as encountered, using temporaries above the block.
  local save = fs.freereg
  fs:emit({ op = Op.NEWTABLE, a = target }, node.line)
  local arrayBase = target + 1
  fs.freereg = arrayBase
  local arrayCount = 0
  local multiLast = false
  local nfields = #node.fields
  for i, f in ipairs(node.fields) do
    if f.kind == 'item' then
      local r = arrayBase + arrayCount
      fs.freereg = r
      if i == nfields and isMultiExpr(f.value) then
        if f.value.k == 'Vararg' then
          assertVararg(fs, node.line)
          fs:reserve(1)
          fs:emit({ op = Op.VARARG, a = r, b = 0 }, node.line)
        else
          compileCall(fs, f.value, r, -1, node.line)
        end
        multiLast = true
      else
        fs:reserve(1)
        compileExprInto(fs, f.value, r)
        arrayCount = arrayCount + 1
      end
    else
      local blockTop = arrayBase + arrayCount
      fs.freereg = blockTop
      if f.kind == 'named' then
        local rv = exprNext(fs, f.value)
        fs:emit({ op = Op.SETFIELD, a = target, bx = fs:const(f.key), c = rv }, node.line)
      else
        local rk = exprNext(fs, f.key)
        local rv = exprNext(fs, f.value)
        fs:emit({ op = Op.SETTABLE, a = target, b = rk, c = rv }, node.line)
      end
      fs.freereg = blockTop -- keep the positional block intact
    end
  end
  if multiLast then
    fs:emit({ op = Op.SETLIST, a = target, b = 0, c = 0 }, node.line)
  elseif arrayCount > 0 then
    fs:emit({ op = Op.SETLIST, a = target, b = arrayCount, c = 0 }, node.line)
  end
  fs.freereg = save
end

-- ── function bodies ──────────────────────────────────────────────────────────
compileFunc = function(fs, node, target)
  local child = newFS(fs, node.isVararg)
  child.proto.numparams = #node.params
  -- declare params as locals
  for i, decl in ipairs(node.paramDecls) do
    decl.owner = child
    decl.reg = i - 1
    child.freereg = math.max(child.freereg, i)
  end
  child:reserve(0)
  if child.proto.numparams > child.proto.maxstack then child.proto.maxstack = child.proto.numparams + 2 end
  -- box captured params
  for _, decl in ipairs(node.paramDecls) do
    if decl.captured then child:emit({ op = Op.NEWCELL, a = decl.reg }, node.line) end
  end
  compileBlock(child, node.body)
  child:emit({ op = Op.RETURN, a = 0, b = 1 }, node.line) -- implicit return
  local protos = fs.proto.protos
  protos[#protos + 1] = child.proto
  fs:emit({ op = Op.CLOSURE, a = target, bx = #protos }, node.line)
end

-- ── statements ───────────────────────────────────────────────────────────────
function compileBlock(fs, stmts)
  local save = fs.freereg
  local savedLocals = fs._activeCount or 0
  for _, s in ipairs(stmts) do compileStmt(fs, s) end
  fs.freereg = save
end

local function declareLocal(fs, decl, line)
  local r = fs.freereg
  fs:reserve(1)
  decl.owner = fs
  decl.reg = r
  return r
end

compileStmt = function(fs, s)
  local k = s.k
  local line = s.line
  if k == 'Local' then
    local base = fs.freereg
    -- produce exactly #names values (nil-filling short calls / vararg) — see explistExact
    fs:explistExact(s.exprs, base, #s.names)
    for i, decl in ipairs(s.decls) do
      decl.owner = fs
      decl.reg = base + i - 1
      if decl.captured then fs:emit({ op = Op.NEWCELL, a = decl.reg }, line) end
    end
  elseif k == 'LocalFunc' then
    local r = declareLocal(fs, s.decl, line)
    if s.decl.captured then
      -- reserve cell first so recursion sees it
      fs:emit({ op = Op.LOADNIL, a = r, b = 0 }, line)
      fs:emit({ op = Op.NEWCELL, a = r }, line)
      local tmp = fs.freereg
      fs:reserve(1)
      compileFunc(fs, s.func, tmp)
      fs:emit({ op = Op.SETCELL, a = r, b = tmp }, line)
      fs.freereg = r + 1
    else
      compileFunc(fs, s.func, r)
    end
  elseif k == 'Assign' then
    compileAssign(fs, s)
  elseif k == 'FuncDecl' then
    compileFuncDecl(fs, s)
  elseif k == 'CallStat' then
    local save = fs.freereg
    compileCall(fs, s.call, fs.freereg, 0, line)
    fs.freereg = save
  elseif k == 'Do' then
    compileBlock(fs, s.body)
  elseif k == 'Return' then
    local base = fs.freereg
    local count = fs:explistOpen(s.exprs, base)
    fs:emit({ op = Op.RETURN, a = base, b = count }, line)
    fs.freereg = base
  elseif k == 'If' then
    compileIf(fs, s)
  elseif k == 'While' then
    compileWhile(fs, s)
  elseif k == 'Repeat' then
    compileRepeat(fs, s)
  elseif k == 'NumFor' then
    compileNumFor(fs, s)
  elseif k == 'GenFor' then
    compileGenFor(fs, s)
  elseif k == 'Break' then
    local loop = fs.loops[#fs.loops]
    if not loop then error('compiler: break outside loop') end
    local j = fs:emit({ op = Op.JMP, sbx = 0 }, line)
    loop.breaks[#loop.breaks + 1] = j
  elseif k == 'Continue' then
    local loop = fs.loops[#fs.loops]
    if not loop then error('compiler: continue outside loop') end
    local j = fs:emit({ op = Op.JMP, sbx = 0 }, line)
    loop.continues[#loop.continues + 1] = j
  elseif k == 'Goto' or k == 'Label' then
    error('ferret-vm: goto/label is not supported (Luau has no goto)')
  else
    error('compiler: cannot compile stmt ' .. tostring(k))
  end
end

function compileAssign(fs, s)
  local save = fs.freereg
  local n = #s.targets
  if n == 1 and #s.exprs == 1 then
    compileStore(fs, s.targets[1], s.exprs[1], s.line)
    fs.freereg = save
    return
  end
  -- evaluate exactly n RHS values into consecutive temps (nil-filling short
  -- calls / vararg — see explistExact), then store into the targets
  local base = fs.freereg
  fs:explistExact(s.exprs, base, n)
  fs.freereg = base + n
  for i = 1, n do
    compileStoreReg(fs, s.targets[i], base + i - 1, s.line)
  end
  fs.freereg = save
end

-- store the value of `valueNode` into target lvalue
function compileStore(fs, target, valueNode, line)
  if target.k == 'Name' then
    local d = target.decl
    if not d then
      local r = exprNext(fs, valueNode)
      fs:emit({ op = Op.SETGLOBAL, a = r, bx = fs:const(target.name) }, line)
    elseif d.owner == fs then
      if d.captured then
        local r = exprNext(fs, valueNode)
        fs:emit({ op = Op.SETCELL, a = d.reg, b = r }, line)
      else
        -- Calls/methods/tables use [target+1..] as scratch, which would clobber
        -- other live locals (and args read from them). Evaluate into a fresh
        -- temp above the locals, then move into place.
        local vk = valueNode.k
        if vk == 'CallE' or vk == 'Method' or vk == 'Table' then
          local save = fs.freereg
          local tmp = exprNext(fs, valueNode)
          if tmp ~= d.reg then fs:emit({ op = Op.MOVE, a = d.reg, b = tmp }, line) end
          fs.freereg = save
        else
          compileExprInto(fs, valueNode, d.reg)
        end
      end
    else
      local r = exprNext(fs, valueNode)
      fs:emit({ op = Op.SETUPVAL, a = r, b = fs:upval(d) }, line)
    end
  elseif target.k == 'Field' then
    local robj = exprAny(fs, target.obj)
    local rv = exprNext(fs, valueNode)
    fs:emit({ op = Op.SETFIELD, a = robj, bx = fs:const(target.name), c = rv }, line)
  elseif target.k == 'Index' then
    local robj = exprAny(fs, target.obj)
    local rk = exprAny(fs, target.index)
    local rv = exprNext(fs, valueNode)
    fs:emit({ op = Op.SETTABLE, a = robj, b = rk, c = rv }, line)
  end
end

-- store an already-computed value (in register `vreg`) into target lvalue
function compileStoreReg(fs, target, vreg, line)
  if target.k == 'Name' then
    local d = target.decl
    if not d then fs:emit({ op = Op.SETGLOBAL, a = vreg, bx = fs:const(target.name) }, line)
    elseif d.owner == fs then
      if d.captured then fs:emit({ op = Op.SETCELL, a = d.reg, b = vreg }, line)
      elseif d.reg ~= vreg then fs:emit({ op = Op.MOVE, a = d.reg, b = vreg }, line) end
    else fs:emit({ op = Op.SETUPVAL, a = vreg, b = fs:upval(d) }, line) end
  elseif target.k == 'Field' then
    local robj = exprAny(fs, target.obj)
    fs:emit({ op = Op.SETFIELD, a = robj, bx = fs:const(target.name), c = vreg }, line)
  elseif target.k == 'Index' then
    local robj = exprAny(fs, target.obj)
    local rk = exprAny(fs, target.index)
    fs:emit({ op = Op.SETTABLE, a = robj, b = rk, c = vreg }, line)
  end
end

function compileFuncDecl(fs, s)
  -- build the target lvalue: base [.path]* [:method]
  local line = s.line
  if #s.path == 0 and not s.method then
    -- assign to base (local/upval/global)
    local nameNode = { k = 'Name', name = s.base, decl = s.baseDecl, line = line }
    compileStore(fs, nameNode, s.func, line)
  else
    -- resolve base object, then descend fields, set last
    local save = fs.freereg
    local baseNode = { k = 'Name', name = s.base, decl = s.baseDecl, line = line }
    local robj = exprNext(fs, baseNode)
    for i = 1, #s.path - (s.method and 0 or 1) do
      local nxt = fs.freereg
      fs:reserve(1)
      fs:emit({ op = Op.GETFIELD, a = nxt, b = robj, bx = fs:const(s.path[i]) }, line)
      robj = nxt
    end
    local lastKey = s.method or s.path[#s.path]
    local rv = exprNext(fs, s.func)
    fs:emit({ op = Op.SETFIELD, a = robj, bx = fs:const(lastKey), c = rv }, line)
    fs.freereg = save
  end
end

-- if / elseif / else
function compileIf(fs, s)
  local endJumps = {}
  for ci, clause in ipairs(s.clauses) do
    local save = fs.freereg
    local rc = exprNext(fs, clause.cond)
    fs.freereg = save
    local jnext = fs:emit({ op = Op.JMPIFNOT, a = rc, sbx = 0 }, clause.cond.line)
    compileBlock(fs, clause.body)
    if s.elseBody or ci < #s.clauses then
      endJumps[#endJumps + 1] = fs:emit({ op = Op.JMP, sbx = 0 }, s.line)
    end
    fs:patch(jnext, fs:here())
  end
  if s.elseBody then compileBlock(fs, s.elseBody) end
  for _, j in ipairs(endJumps) do fs:patch(j, fs:here()) end
end

function compileWhile(fs, s)
  local top = fs:here()
  local save = fs.freereg
  local rc = exprNext(fs, s.cond)
  fs.freereg = save
  local jexit = fs:emit({ op = Op.JMPIFNOT, a = rc, sbx = 0 }, s.line)
  fs.loops[#fs.loops + 1] = { breaks = {}, continues = {} }
  compileBlock(fs, s.body)
  local loop = fs.loops[#fs.loops]
  for _, j in ipairs(loop.continues) do fs:patch(j, top) end -- continue -> re-test
  local jback = fs:emit({ op = Op.JMP, sbx = 0 }, s.line)
  fs:patch(jback, top)
  fs:patch(jexit, fs:here())
  table.remove(fs.loops)
  for _, j in ipairs(loop.breaks) do fs:patch(j, fs:here()) end
end

function compileRepeat(fs, s)
  local top = fs:here()
  fs.loops[#fs.loops + 1] = { breaks = {}, continues = {} }
  -- body and until share scope; compile inline (no freereg reset before cond)
  local save = fs.freereg
  for _, st in ipairs(s.body) do compileStmt(fs, st) end
  local loop = fs.loops[#fs.loops]
  for _, j in ipairs(loop.continues) do fs:patch(j, fs:here()) end -- continue -> until test
  local rc = exprNext(fs, s.cond)
  local jback = fs:emit({ op = Op.JMPIFNOT, a = rc, sbx = 0 }, s.line)
  fs:patch(jback, top)
  fs.freereg = save
  table.remove(fs.loops)
  for _, j in ipairs(loop.breaks) do fs:patch(j, fs:here()) end
end

function compileNumFor(fs, s)
  local base = fs.freereg
  exprNext(fs, s.start)  -- base
  exprNext(fs, s.stop)   -- base+1
  if s.step then exprNext(fs, s.step) else
    fs:emit({ op = Op.LOADINT, a = fs.freereg, sbx = 1 }, s.line); fs:reserve(1)
  end
  fs:reserve(1) -- loop var at base+3
  if fs.freereg > fs.proto.maxstack then fs.proto.maxstack = fs.freereg end
  s.varDecl.owner = fs
  s.varDecl.reg = base + 3
  local jprep = fs:emit({ op = Op.FORPREP, a = base, sbx = 0 }, s.line)
  fs.loops[#fs.loops + 1] = { breaks = {}, continues = {} }
  local bodyStart = fs:here()
  if s.varDecl.captured then fs:emit({ op = Op.NEWCELL, a = base + 3 }, s.line) end
  compileBlock(fs, s.body)
  local loop = fs.loops[#fs.loops]
  for _, j in ipairs(loop.continues) do fs:patch(j, fs:here()) end -- continue -> step/test
  local loopIns = fs:emit({ op = Op.FORLOOP, a = base, sbx = 0 }, s.line)
  fs:patch(jprep, loopIns)     -- FORPREP jumps forward to the FORLOOP instruction
  fs:patch(loopIns, bodyStart) -- FORLOOP jumps back to the body start
  fs.freereg = base
  table.remove(fs.loops)
  for _, j in ipairs(loop.breaks) do fs:patch(j, fs:here()) end
end

function compileGenFor(fs, s)
  local base = fs.freereg
  -- iterator function, state, control (3 values) from exprs
  local count = fs:explistOpen(s.exprs, base)
  local have = (count == 0) and 3 or (count - 1)
  for i = have, 2 do fs:emit({ op = Op.LOADNIL, a = base + i, b = 0 }, s.line) end
  fs.freereg = base + 3
  -- loop vars at base+3 ...
  local nvars = #s.decls
  fs:reserve(nvars)
  if fs.freereg > fs.proto.maxstack then fs.proto.maxstack = fs.freereg end
  for i, decl in ipairs(s.decls) do decl.owner = fs; decl.reg = base + 3 + (i - 1) end
  -- normalize the iterator triple once for Luau generalized iteration (a bare
  -- table / __iter object becomes a proper (iterfn, state, control) triple)
  fs:emit({ op = Op.TFORPREP, a = base }, s.line)
  local jto = fs:emit({ op = Op.JMP, sbx = 0 }, s.line) -- jump to TFORCALL
  fs.loops[#fs.loops + 1] = { breaks = {}, continues = {} }
  local bodyStart = fs:here()
  for _, decl in ipairs(s.decls) do
    if decl.captured then fs:emit({ op = Op.NEWCELL, a = decl.reg }, s.line) end
  end
  compileBlock(fs, s.body)
  local loop = fs.loops[#fs.loops]
  local contTarget = fs:here()
  for _, j in ipairs(loop.continues) do fs:patch(j, contTarget) end -- continue -> next iter
  fs:patch(jto, contTarget)
  fs:emit({ op = Op.TFORCALL, a = base, c = nvars }, s.line)
  local jloop = fs:emit({ op = Op.TFORLOOP, a = base, sbx = 0 }, s.line)
  fs:patch(jloop, bodyStart)
  fs.freereg = base
  table.remove(fs.loops)
  for _, j in ipairs(loop.breaks) do fs:patch(j, fs:here()) end
end

-- ── entry ────────────────────────────────────────────────────────────────────
function Compiler.compileAST(chunk)
  Scope.analyze(chunk)
  local main = newFS(nil, true)
  main.proto.isVararg = true
  compileBlock(main, chunk.body)
  main:emit({ op = Op.RETURN, a = 0, b = 1 }, 0)
  return main.proto
end

function Compiler.compile(src, chunkName, opts)
  opts = opts or {}
  local chunk = Parser.parseString(src, chunkName)
  if opts.optimize ~= false then
    local Optimizer = require('optimizer')
    Optimizer.optimizeAST(chunk)
    -- Opaque-predicate injection runs AFTER folding (so predicates aren't
    -- folded) and BEFORE scope analysis / codegen (so the compiler allocates
    -- registers and jumps for the injected code). opts.opaque is a Harden.prng.
    if opts.opaque then
      require('obfuscate').inject(chunk, opts.opaque, { density = opts.opaqueDensity })
    end
    local proto = Compiler.compileAST(chunk)
    Optimizer.peephole(proto)
    return proto
  end
  if opts.opaque then
    require('obfuscate').inject(chunk, opts.opaque, { density = opts.opaqueDensity })
  end
  return Compiler.compileAST(chunk)
end

return Compiler
