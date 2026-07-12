-- luau-vm/src/optimizer.lua
-- AST + bytecode optimization passes. Every pass is semantics-preserving AND
-- runtime-neutral: we only fold operations whose result has the same observable
-- value/representation on Lua 5.4 and Luau. Notably `/` and `^` are NOT folded
-- (they float on 5.4 but Luau prints them without `.0`), and bitwise/comparison
-- folds are skipped for the same reason.

local Opcodes = require('opcodes')
local Op = Opcodes.Op

local Optimizer = {}

-- ── AST: constant folding + dead-code elimination ────────────────────────────
local function isIntLit(e)
  if e.k ~= 'Number' then return nil end
  local v = tonumber(e.value)
  if v == nil then return nil end
  if v ~= math.floor(v) then return nil end
  if e.value:find('[%.eExXpP]') then return nil end -- keep hex/float text as-is
  return v
end

local FOLD = {
  ['+'] = function(a, b) return a + b end,
  ['-'] = function(a, b) return a - b end,
  ['*'] = function(a, b) return a * b end,
}

local foldExpr

local function foldChildren(e)
  if e.left then e.left = foldExpr(e.left) end
  if e.right then e.right = foldExpr(e.right) end
  if e.operand then e.operand = foldExpr(e.operand) end
  if e.obj then e.obj = foldExpr(e.obj) end
  if e.index then e.index = foldExpr(e.index) end
  if e.expr then e.expr = foldExpr(e.expr) end
  if e.func then e.func = foldExpr(e.func) end
  if e.args then for i, a in ipairs(e.args) do e.args[i] = foldExpr(a) end end
  if e.fields then
    for _, f in ipairs(e.fields) do
      if f.key and type(f.key) == 'table' then f.key = foldExpr(f.key) end
      f.value = foldExpr(f.value)
    end
  end
  if e.body then Optimizer.foldBlock(e.body) end
  return e
end

foldExpr = function(e)
  foldChildren(e)
  if e.k == 'Binop' then
    local la, lb = isIntLit(e.left), isIntLit(e.right)
    if la ~= nil and lb ~= nil and FOLD[e.op] then
      local v = FOLD[e.op](la, lb)
      return { k = 'Number', value = tostring(v), line = e.line }
    end
    -- literal concat of strings/ints is representation-stable
    if e.op == '..' then
      local function litStr(n)
        if n.k == 'String' then return n.value end
        if n.k == 'Number' then local iv = isIntLit(n); if iv ~= nil then return tostring(iv) end end
        return nil
      end
      local a, b = litStr(e.left), litStr(e.right)
      if a ~= nil and b ~= nil then return { k = 'String', value = a .. b, line = e.line } end
    end
  elseif e.k == 'Unop' and e.op == '-' then
    local v = isIntLit(e.operand)
    if v ~= nil then return { k = 'Number', value = tostring(-v), line = e.line } end
  end
  return e
end

function Optimizer.foldBlock(stmts)
  local cut = nil
  for i, s in ipairs(stmts) do
    -- fold expressions inside the statement
    if s.exprs then for j, e in ipairs(s.exprs) do s.exprs[j] = foldExpr(e) end end
    if s.targets then for j, e in ipairs(s.targets) do s.targets[j] = foldExpr(e) end end
    if s.cond then s.cond = foldExpr(s.cond) end
    if s.call then s.call = foldExpr(s.call) end
    if s.start then s.start = foldExpr(s.start) end
    if s.stop then s.stop = foldExpr(s.stop) end
    if s.step then s.step = foldExpr(s.step) end
    if s.value then s.value = foldExpr(s.value) end
    if s.func then foldExpr(s.func) end
    if s.body then Optimizer.foldBlock(s.body) end
    if s.elseBody then Optimizer.foldBlock(s.elseBody) end
    if s.clauses then
      for _, c in ipairs(s.clauses) do c.cond = foldExpr(c.cond); Optimizer.foldBlock(c.body) end
    end
    -- dead-code elimination: statements after an unconditional exit are removed
    if (s.k == 'Return' or s.k == 'Break') and cut == nil then cut = i end
  end
  if cut then for i = #stmts, cut + 1, -1 do stmts[i] = nil end end
end

function Optimizer.optimizeAST(chunk)
  Optimizer.foldBlock(chunk.body)
  return chunk
end

-- ── bytecode peephole ────────────────────────────────────────────────────────
-- Only these opcodes use sbx as a relative jump offset (LOADINT's sbx is an
-- immediate value and must never be retargeted).
local JUMP = {
  [Op.JMP] = true, [Op.JMPIF] = true, [Op.JMPIFNOT] = true,
  [Op.FORPREP] = true, [Op.FORLOOP] = true, [Op.TFORLOOP] = true,
}

local function isDroppable(ins)
  return (ins.op == Op.NOP) or (ins.op == Op.MOVE and ins.a == ins.b)
end

-- Remove NOPs and self-moves, remapping jump targets so control flow is kept.
function Optimizer.peephole(proto)
  for _, child in ipairs(proto.protos) do Optimizer.peephole(child) end
  local code = proto.code
  -- capture absolute jump targets before removal
  local absTarget = {}
  for i, ins in ipairs(code) do
    if JUMP[ins.op] then absTarget[i] = i + 1 + ins.sbx end
  end
  -- map every old index (1..#code+1) to the new index it lands on
  local newOf, kept, keepOldIndex = {}, {}, {}
  for i, ins in ipairs(code) do
    if isDroppable(ins) then
      newOf[i] = #kept + 1 -- redirect to the next kept instruction
    else
      kept[#kept + 1] = ins
      keepOldIndex[#kept] = i
      newOf[i] = #kept
    end
  end
  newOf[#code + 1] = #kept + 1
  -- recompute sbx for kept jumps
  for newPc, ins in ipairs(kept) do
    if JUMP[ins.op] then
      local oldIdx = keepOldIndex[newPc]
      local newTarget = newOf[absTarget[oldIdx]]
      ins.sbx = newTarget - (newPc + 1)
    end
  end
  proto.code = kept
  return proto
end

return Optimizer
