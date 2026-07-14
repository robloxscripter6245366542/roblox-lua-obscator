-- luau-vm/src/bitops.lua
-- Custom 32-bit bitwise ops. Deliberately does NOT use the standard `bit32`
-- library: the ops are our own, built from per-nibble lookup tables so a build
-- ships no recognizable bit32.* calls. Semantics match 32-bit unsigned bit32
-- (the model Luau uses), so VM programs behave identically on Luau and Lua 5.4.
-- Processing 4 bits at a time via a 16x16 table keeps this ~8 lookups per op
-- (far cheaper than a 32-iteration per-bit loop) so hot bitwise code stays fast.

local M = {}
local TWO32 = 4294967296

-- Per-nibble truth tables for our three primitive binary ops, built once.
local AND, OR, XOR = {}, {}, {}
for x = 0, 15 do
  AND[x], OR[x], XOR[x] = {}, {}, {}
  for y = 0, 15 do
    local a, b, ra, ro, rx, p = x, y, 0, 0, 0, 1
    for _ = 1, 4 do
      local xb, yb = a % 2, b % 2
      if xb == 1 and yb == 1 then ra = ra + p end
      if xb == 1 or yb == 1 then ro = ro + p end
      if xb ~= yb then rx = rx + p end
      a = (a - xb) / 2; b = (b - yb) / 2; p = p * 2
    end
    AND[x][y] = ra; OR[x][y] = ro; XOR[x][y] = rx
  end
end

local function norm(x) return math.floor(x) % TWO32 end

-- Combine two 32-bit values a nibble at a time through table T.
local function apply(a, b, T)
  a = norm(a); b = norm(b)
  local r, p = 0, 1
  for _ = 1, 8 do
    local an, bn = a % 16, b % 16
    r = r + T[an][bn] * p
    a = (a - an) / 16; b = (b - bn) / 16; p = p * 16
  end
  return r
end

function M.band(a, b) return apply(a, b, AND) end
function M.bor(a, b) return apply(a, b, OR) end
function M.bxor(a, b) return apply(a, b, XOR) end
function M.lshift(a, n) return norm(norm(a) * (2 ^ n)) end
function M.rshift(a, n) return math.floor(norm(a) / (2 ^ n)) end
function M.bnot(a) return (TWO32 - 1) - norm(a) end

return M
