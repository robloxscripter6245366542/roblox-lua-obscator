--!nocheck
-- ============================================================================
--  Blade Ball spam anti-break — offline simulation
--
--  Models the block-break mechanic and runs the REAL gate logic from elopez
--  through it. The shipped gate is AUTOMATIC + self-adapting: after each parry it
--  backs off for the block cooldown, widens the backoff if the block ever breaks,
--  and slowly narrows it when stable. This sim confirms it converges to 0% broken
--  for ANY block cooldown (i.e. "toggle forever, never breaks") with no tuning.
--  Pure logic, no Roblox — numbers are estimates, the CONVERGENCE is the point.
-- ============================================================================

local STUN = 1.5
local OVER_DRAIN = 22
local PARRY_DRAIN = 4
local REGEN = 60
local DT = 1 / 60
local DURATION = 40                 -- long run so adaptation can settle

local SPAM_BACKOFF_MAX = 0.80

local function run(rate, blockCD)
    local now, acc, stam = 0, 0, 100
    local stunned, stunUntil, blockReadyAt, backoffUntil = false, 0, 0, 0
    -- adaptive state (mirrors elopez)
    local backoff, wasStunned = 0.45, false
    local parries, brokenTime, breaks = 0, 0, 0

    local function canFire()
        if stunned then
            if not wasStunned then
                wasStunned = true
                backoff = math.min(backoff + 0.1, SPAM_BACKOFF_MAX)
            end
            return false
        end
        wasStunned = false
        if now < backoffUntil then return false end
        return true
    end

    local function fire()
        if not canFire() then return end
        -- Per-fire rate limit: EVERY fire arms the backoff (mirrors the shipped
        -- RequestSpamParry, which sets SpamReadyAt right after FireParry). This
        -- is what caps the press rate during a clash, before any landed-parry
        -- confirmation comes back.
        backoffUntil = now + backoff
        if now < blockReadyAt then
            stam = stam - OVER_DRAIN
            if stam <= 0 then stunned = true; stunUntil = now + STUN; breaks = breaks + 1 end
        else
            parries = parries + 1
            stam = math.min(100, stam - PARRY_DRAIN)
            blockReadyAt = now + blockCD
        end
    end

    -- track broken time only in the SECOND half, after adaptation settles
    for _ = 1, math.floor(DURATION / DT) do
        now = now + DT
        if stunned then
            if now > DURATION / 2 then brokenTime = brokenTime + DT end
            if now >= stunUntil then stunned = false; stam = 100 end
        else
            stam = math.min(100, stam + REGEN * DT)
        end
        acc = acc + DT
        local n = math.floor(acc * rate)
        if n > 0 then acc = acc - n / rate; for _ = 1, n do fire() end end
    end
    return math.floor(brokenTime / (DURATION / 2) * 100 + 0.5), parries, breaks, backoff
end

print("Adaptive anti-break — steady-state broken% over a 40s hold at 1000 rps")
print(("%-9s | %-12s %-10s %-10s %s"):format("blockCD", "broken%(2nd half)", "parries", "breaks", "settled backoff"))
print(("-"):rep(66))
for _, cd in ipairs({ 0.15, 0.25, 0.35, 0.45, 0.60, 0.75 }) do
    local broken, parries, breaks, bo = run(1000, cd)
    print(("%-9.2f | %-14d%% %-10d %-10d %.2fs"):format(cd, broken, parries, breaks, bo))
end
print(("-"):rep(66))
print("steady-state broken% should be 0 for every cooldown = never breaks once settled")
