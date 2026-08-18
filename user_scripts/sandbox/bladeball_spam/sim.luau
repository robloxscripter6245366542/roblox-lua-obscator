--!nocheck
-- ============================================================================
--  Blade Ball spam anti-break — offline simulation
--
--  Models the block-break mechanic and runs the REAL gate logic from elopez
--  (SpamCanFire: don't fire while Stunned, back off ~0.15s after a parry) against
--  it, comparing OLD (fire whenever spamming) vs NEW (gated), across spam rates
--  and block-cooldown assumptions. Pure logic — no Roblox — so it exercises the
--  fix, not the game's exact numbers (those are estimates, stated as such).
-- ============================================================================

local BACKOFF = 0.15          -- the value shipped in elopez
local STUN = 1.5              -- how long a broken block stays broken (estimate)
local OVER_DRAIN = 22         -- stamina lost per parry fired DURING cooldown (over-parry)
local PARRY_DRAIN = 4         -- stamina lost per legit parry
local REGEN = 60              -- stamina/sec regen when not over-parrying
local DT = 1 / 60
local DURATION = 12           -- seconds simulated

-- One run. gated=true uses the shipped SpamCanFire logic; false is the old behavior.
local function run(rate, blockCD, gated)
    local now = 0
    local acc = 0
    local stamina = 100
    local stunned = false
    local stunUntil = 0
    local blockReadyAt = 0     -- block off cooldown at/after this time
    local backoffUntil = 0     -- NEW: set on a successful parry
    local parries, overParries, brokenTime = 0, 0, 0

    -- The real gate, mirrored from elopez.
    local function SpamCanFire()
        if now < backoffUntil then return false end
        if stunned then return false end
        return true
    end

    local function attemptFire()
        if gated and not SpamCanFire() then return end
        if stunned then return end                       -- fire does nothing while broken
        if now < blockReadyAt then
            -- over-parry: hammering the block during its cooldown
            overParries = overParries + 1
            stamina = stamina - OVER_DRAIN
            if stamina <= 0 then
                stunned = true
                stunUntil = now + STUN
            end
        else
            -- legit parry lands
            parries = parries + 1
            stamina = math.min(100, stamina - PARRY_DRAIN)
            blockReadyAt = now + blockCD
            backoffUntil = now + BACKOFF
        end
    end

    local frames = math.floor(DURATION / DT)
    for _ = 1, frames do
        now = now + DT
        if stunned then
            brokenTime = brokenTime + DT
            if now >= stunUntil then stunned = false; stamina = 100 end
        else
            stamina = math.min(100, stamina + REGEN * DT)
        end
        acc = acc + DT
        local n = math.floor(acc * rate)
        if n > 0 then
            acc = acc - n / rate
            for _ = 1, n do attemptFire() end
        end
    end

    return {
        parries = parries,
        overParries = overParries,
        brokenPct = math.floor((brokenTime / DURATION) * 100 + 0.5),
    }
end

print("Blade Ball manual-spam anti-break simulation (" .. DURATION .. "s runs)")
print(("%-6s %-9s | %-22s | %-22s"):format("rate", "blockCD", "OLD (no gate)", "NEW (gated)"))
print(("-"):rep(72))
for _, rate in ipairs({ 550, 300, 200 }) do
    for _, cd in ipairs({ 0.15, 0.25, 0.35 }) do
        local o = run(rate, cd, false)
        local n = run(rate, cd, true)
        print(("%-6d %-9.2f | broken %3d%%  parries %-5d | broken %3d%%  parries %-5d"):format(
            rate, cd, o.brokenPct, o.parries, n.brokenPct, n.parries))
    end
end
print(("-"):rep(72))
print("broken% = share of time the block was broken/stunned (lower is better)")
