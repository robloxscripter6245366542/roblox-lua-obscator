-- ferret/rng.lua
-- Small deterministic PRNG (LCG) so builds are reproducible from a seed.

local Rng = {}
Rng.__index = Rng

function Rng.new(seed)
    return setmetatable({ s = (seed or 1) % 2147483648 }, Rng)
end

-- next integer in [0, 2^31)
function Rng:int()
    self.s = (self.s * 1103515245 + 12345) % 2147483648
    return self.s
end

-- integer in [lo, hi]
function Rng:range(lo, hi)
    return lo + (self:int() % (hi - lo + 1))
end

-- opaque identifier that is a valid Lua name and unlikely to collide
function Rng:name(len)
    len = len or 6
    local alpha = "abcdefghijklmnopqrstuvwxyz"
    local t = { "_" }
    local i = self:range(1, #alpha)
    t[#t + 1] = alpha:sub(i, i)
    for _ = 1, len do
        local j = self:range(1, 16)
        t[#t + 1] = ("0123456789abcdef"):sub(j, j)
    end
    return table.concat(t)
end

return Rng
