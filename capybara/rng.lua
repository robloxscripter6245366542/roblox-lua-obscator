-- capybara/rng.lua
-- Deterministic PRNG so every build is reproducible from a single seed.
-- A small xorshift-style mixer built from pure arithmetic (no bit library),
-- so it behaves identically on Lua 5.1 / 5.2 / 5.3 / 5.4 and Luau.

local Rng = {}
Rng.__index = Rng

local MOD = 2147483648 -- 2^31

function Rng.new(seed)
    seed = (seed or 1) % MOD
    if seed == 0 then seed = 1 end
    return setmetatable({ s = seed }, Rng)
end

-- next integer in [0, 2^31)
function Rng:int()
    -- two-round LCG with a shift-mix so low bits are not obviously periodic
    local s = self.s
    s = (s * 1103515245 + 12345) % MOD
    s = (s + math.floor(s / 65536)) % MOD
    s = (s * 1103515245 + 12345) % MOD
    self.s = s
    return s
end

-- integer in [lo, hi] inclusive
function Rng:range(lo, hi)
    return lo + (self:int() % (hi - lo + 1))
end

-- an opaque but valid Lua identifier, unlikely to collide with user names
function Rng:name(len)
    len = len or 7
    local head = "abcdefghijklmnopqrstuvwxyz"
    local tail = "0123456789abcdefghijklmnopqrstuvwxyz_"
    local t = { "_c" }
    local i = self:range(1, #head)
    t[#t + 1] = head:sub(i, i)
    for _ = 1, len do
        local j = self:range(1, #tail)
        t[#t + 1] = tail:sub(j, j)
    end
    return table.concat(t)
end

return Rng
