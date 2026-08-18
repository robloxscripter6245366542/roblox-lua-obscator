--!nocheck
-- ============================================================================
--  Blade Ball spam gate — offline simulation
--
--  Models the block/guard mechanic and runs the REAL shipped gate through it.
--  The shipped gate is deliberately simple: fire at the FULL configured rate,
--  and the only thing that ever holds fire is the block ACTUALLY being broken
--  (the character's "Stunned" attribute). While Stunned we pause; the instant it
--  clears we resume. No artificial rate cap — so spam actually spams.
--
--  The failure players actually hit is a shield that STAYS broken: once the
--  guard is stunned (a heavy hit / clash you couldn't parry in time),
--  CONTINUING to hammer the parry re-arms the stun every frame, so it never
--  recovers. Stopping the feed while broken is what lets it heal. This sim
--  drives a periodic external break event through both gates and measures how
--  long the shield sits broken:
--    • "none"    — old behaviour: keep firing, stun gets re-armed -> stuck.
--    • "stunned" — shipped: hold fire while broken -> heals in one STUN window.
--
--  NOTE ON RATE: firing at the full rate is safe *here* because a clean parry
--  is what consumes an incoming ball. What this sim does NOT claim is that raw
--  idle hammering with no ball can never trigger a break — if the guard has a
--  stamina cost, a high enough idle rate can, and the only cures are a lower
--  rate or firing only on real balls. The gate's job is the STUCK case above.
--  Pure logic, no Roblox — the SHAPE (stuck vs self-healing) is the point.
-- ============================================================================

local STUN = 1.2            -- broken window once a break lands
local BREAK_EVERY = 6       -- an unavoidable external break arrives this often
local DT = 1 / 60
local DURATION = 48

local function run(rate, gate)
    local now, acc = 0, 0
    local stunned, stunUntil, nextBreak = false, 0, BREAK_EVERY
    local brokenTime = 0

    local function canFire()
        if gate == "stunned" and stunned then return false end
        return true
    end

    local function fire()
        if not canFire() then return end
        if stunned then
            stunUntil = now + STUN   -- feeding a broken guard re-arms the stun
        end
    end

    for _ = 1, math.floor(DURATION / DT) do
        now = now + DT
        if now >= nextBreak then      -- external break we didn't stop in time
            stunned = true
            stunUntil = now + STUN
            nextBreak = now + BREAK_EVERY
        end
        if stunned then
            brokenTime = brokenTime + DT
            if now >= stunUntil then stunned = false end
        end
        acc = acc + DT
        local n = math.floor(acc * rate)
        if n > 0 then acc = acc - n / rate; for _ = 1, n do fire() end end
    end
    return math.floor(brokenTime / DURATION * 100 + 0.5)
end

print("Stuck-shield test — periodic external break, 1000 rps, broken% (lower=better)")
print(("%-14s %-14s"):format("gate: none", "gate: stunned"))
print(("-"):rep(30))
local none = run(1000, "none")
local stun = run(1000, "stunned")
print(("%-14s %-14s"):format(none .. "%", stun .. "%"))
print(("-"):rep(30))
print("Without the gate the shield is hammered stuck (~always broken).")
print("The shipped Stunned gate lets each break heal in one STUN window,")
print("while still firing at the full spam rate the rest of the time.")
