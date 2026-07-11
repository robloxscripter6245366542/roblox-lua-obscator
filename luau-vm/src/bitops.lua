-- luau-vm/src/bitops.lua
-- Portable 32-bit bitwise ops. Uses bit32 when present (Luau, Lua 5.2); falls
-- back to arithmetic otherwise (Lua 5.4 removed both bit32 and — crucially for
-- source portability — we cannot write &|~<<>> operators in code that must also
-- parse under Luau). 32-bit (bit32) semantics; document accordingly.

local M = {}

if bit32 then
  M.band = bit32.band
  M.bor = bit32.bor
  M.bxor = bit32.bxor
  M.lshift = bit32.lshift
  M.rshift = bit32.rshift
  M.bnot = bit32.bnot
else
  local TWO32 = 4294967296
  local function norm(x) x = math.floor(x) % TWO32; return x end
  local function binop(a, b, f)
    a = norm(a); b = norm(b)
    local r, p = 0, 1
    for _ = 0, 31 do
      local x, y = a % 2, b % 2
      if f(x, y) == 1 then r = r + p end
      a = (a - x) / 2; b = (b - y) / 2; p = p * 2
    end
    return r
  end
  function M.band(a, b) return binop(a, b, function(x, y) return (x == 1 and y == 1) and 1 or 0 end) end
  function M.bor(a, b) return binop(a, b, function(x, y) return (x == 1 or y == 1) and 1 or 0 end) end
  function M.bxor(a, b) return binop(a, b, function(x, y) return (x ~= y) and 1 or 0 end) end
  function M.lshift(a, n) return norm(norm(a) * (2 ^ n)) end
  function M.rshift(a, n) return math.floor(norm(a) / (2 ^ n)) end
  function M.bnot(a) return (TWO32 - 1) - norm(a) end
end

return M
