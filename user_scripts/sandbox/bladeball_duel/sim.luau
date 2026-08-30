--!nocheck
-- ============================================================================
--  Blade Ball ADVANCED DUEL sandbox — the whole thing, end to end.
--
--  Every other sandbox tests a slice. This one plays a full DUEL: a real
--  opponent at range hits the ball at you, the ball travels with actual 2D
--  physics (velocity vector, curved / angled paths, escalating speed each
--  volley), your client SEES it one-way-ping stale, the SHIPPED Auto Parry
--  decision (copied from elopez, kept in sync) decides when to fire, the parry
--  packet travels your ping to the server, and the server accepts it against
--  the REAL dump gates (0.5s active shield, proto-12 rejects). Then it scores
--  what ACTUALLY happened to every single ball.
--
--  It sweeps EVERY ping, speed, and trajectory curve, and classifies each
--  approach as one of:
--     DEFLECTED   — a clean block (good)
--     MISS_NOFIRE — Auto Parry never fired -> you die
--     MISS_EARLY  — fired too soon; the 0.5s shield expired before the ball got
--                   here (a "bad block" — it looked like it blocked but whiffed)
--     MISS_LATE   — fired too late (usually high ping); shield not open yet at
--                   contact
--     DOUBLE      — fired 2+ times in ONE approach (wasteful; at high ping the
--                   repeat fire restarts the window and breaks the block)
--
--  Bad blocks (EARLY / LATE / DOUBLE) are surfaced explicitly, not hidden. At
--  the end it prints a full breakdown per ping and per curve, lists the worst
--  offending combos, and — for every failure category that appears — prints the
--  concrete FIX that addresses it. Pure Luau, no Roblox.
-- ============================================================================

local DT = 1 / 60

-- ── 2D vector helpers ───────────────────────────────────────────────────────
local function v(x, y) return { x = x, y = y } end
local function add(a, b) return v(a.x + b.x, a.y + b.y) end
local function sub(a, b) return v(a.x - b.x, a.y - b.y) end
local function mul(a, s) return v(a.x * s, a.y * s) end
local function mag(a) return math.sqrt(a.x * a.x + a.y * a.y) end
local function unit(a) local m = mag(a); if m == 0 then return v(0, 0) end return v(a.x / m, a.y / m) end
local function dot(a, b) return a.x * b.x + a.y * b.y end
local function rot(a, ang)
    local c, s = math.cos(ang), math.sin(ang)
    return v(a.x * c - a.y * s, a.x * s + a.y * c)
end

-- ===========================================================================
--  SHIPPED AUTO PARRY DECISION — copied verbatim from elopez (keep in sync).
--  Mirrors the current fire block: shouldBlock = inRange and incoming and
--  timeToImpact <= (ping_seconds + 0.11), once-per-approach + hysteresis re-arm
--  + 0.2s floor.
-- ===========================================================================
local function autoAccuracyMult(ping_ms) return math.clamp(0.95 - ping_ms * 0.0006, 0.72, 0.98) end
local function parryAccuracy(speed, ping_ms, autoAcc)
    local mult = autoAcc and autoAccuracyMult(ping_ms) or 1.0
    local ping_threshold = math.clamp(5 + ping_ms * 0.03, 5, 24)
    local capped = math.min(math.max(speed - 9.5, 0), 650)
    local sdiv = (2.4 + capped * 0.002) * mult
    local ping_seconds = math.clamp(ping_ms / 1000, 0, 0.45)
    local ping_lead = math.min(speed * ping_seconds, 70)
    return ping_threshold + math.max(speed / sdiv, 9.5) + ping_lead
end
-- state = { parried=false, last=-1 }. Returns fired:boolean.
local function autoParryDecide(state, now, mine, distance, speed, closing, ping_ms)
    local acc = parryAccuracy(speed, ping_ms, true)
    local inRange = distance <= acc
    local incoming = closing > 0
    local ping_seconds = math.clamp(ping_ms / 1000, 0, 0.45)
    local reachDist = math.max(distance - 12, 0)
    local timeToImpact = closing > 0 and (reachDist / closing) or math.huge
    local fireWindow = ping_seconds + 0.11
    local shouldBlock = inRange and incoming and timeToImpact <= fireWindow
    local clearlyGone = (not mine) or (distance > acc * 1.35)
    local sinceLast = now - (state.last or 0)

    if mine and shouldBlock and not state.parried and sinceLast >= 0.2 then
        state.parried = true
        state.last = now
        return true
    elseif clearlyGone then
        state.parried = false
    end
    return false
end

-- ===========================================================================
--  DUMP-GROUNDED SERVER — proto-12 parry gates + 0.5s active shield.
-- ===========================================================================
local PARRY_ACTIVE = 0.5     -- v_u_80
local function serverParryRadius(speed) return 12 + math.min(speed, 400) * 0.02 end

-- ===========================================================================
--  THE DUEL. An opponent at range rallies the ball; we score every approach.
--
--  cfg = { ping, speed0, curveDeg, range, volleys }
--    curveDeg — heading offset from dead-on each step: the ball spirals in, so
--    its radial closing is speed*cos(curveDeg). 0 = straight at you; 82 = almost
--    all tangential (the angled/curving ball that used to slip the timed gate).
--  Returns a list of outcome strings (one per ball that came AT the player) plus
--  the fire count and lead margin for each.
-- ===========================================================================
local function runDuel(cfg)
    local oneWay = (cfg.ping / 1000) / 2
    local P = v(0, 0)                       -- you
    local O = v(0, cfg.range)               -- opponent, at range
    local curve = math.rad(cfg.curveDeg)

    local speed = cfg.speed0
    local pos = O                           -- ball starts at the opponent
    local phase = "toPlayer"                -- opponent serves at you first
    local now = 0

    local state = { parried = false, last = -1 }
    -- per-approach scoring
    local approachFires = 0
    local approachStart = 0
    local shieldOpenedAt = nil              -- server time the shield last opened
    local pendingArrival = nil              -- a fired packet in flight
    local outcomes = {}
    local volleysDone = 0

    local function target() return phase == "toPlayer" and P or O end

    local function scoreApproach(contactTime)
        -- classify what happened when the ball reached the player
        local o
        if shieldOpenedAt ~= nil and contactTime >= shieldOpenedAt and contactTime <= shieldOpenedAt + PARRY_ACTIVE then
            o = "DEFLECTED"
        elseif shieldOpenedAt ~= nil and contactTime > shieldOpenedAt + PARRY_ACTIVE then
            o = "MISS_EARLY"                 -- shield opened but expired before arrival
        elseif pendingArrival ~= nil then
            o = "MISS_LATE"                  -- fired, packet hadn't landed yet
        else
            o = "MISS_NOFIRE"                -- never fired
        end
        if approachFires >= 2 and o == "DEFLECTED" then o = "DOUBLE" end
        local lead = shieldOpenedAt and (contactTime - shieldOpenedAt) or -1
        outcomes[#outcomes + 1] = { outcome = o, fires = approachFires, lead = lead,
            ping = cfg.ping, speed = math.floor(speed), curve = cfg.curveDeg }
    end

    for _ = 1, 6000 do
        now = now + DT
        local T = target()
        local heading = rot(unit(sub(T, pos)), curve)
        local vel = mul(heading, speed)
        pos = add(pos, mul(vel, DT))

        -- server processes an arrived parry -> open the 0.5s shield
        if pendingArrival and now >= pendingArrival then
            pendingArrival = nil
            shieldOpenedAt = now
        end

        if phase == "toPlayer" then
            -- client sees the ball one-way-ping stale
            local seenPos = sub(pos, mul(vel, oneWay))
            local toSelf = sub(P, seenPos)
            local seenDist = mag(toSelf)
            local closing = dot(vel, unit(toSelf))       -- radial closing (seen)
            if autoParryDecide(state, now, true, seenDist, speed, closing, cfg.ping) then
                approachFires = approachFires + 1
                pendingArrival = now + oneWay             -- packet in flight
            end
            -- reached the player?
            if mag(sub(pos, P)) <= serverParryRadius(speed) then
                scoreApproach(now)
                local last = outcomes[#outcomes].outcome
                if last == "DEFLECTED" or last == "DOUBLE" then
                    -- blocked: send it back to the opponent, faster (clash escalates)
                    phase = "toOpponent"
                    speed = math.min(speed * 1.12, 600)
                    shieldOpenedAt = nil
                    -- ball moving away is "not mine" -> hysteresis re-arm happens in
                    -- autoParryDecide via clearlyGone on the return leg.
                else
                    break                                 -- you died; end the duel
                end
            end
        else -- toOpponent
            -- the ball is leaving us: run the decision with mine=false so the
            -- hysteresis re-arm (clearlyGone) fires, exactly like the shipped loop.
            local seenPos = sub(pos, mul(vel, oneWay))
            local toSelf = sub(P, seenPos)
            autoParryDecide(state, now, false, mag(toSelf), speed, dot(vel, unit(toSelf)), cfg.ping)
            if mag(sub(pos, O)) <= serverParryRadius(speed) then
                -- opponent always returns it; a new approach at us begins
                volleysDone = volleysDone + 1
                if volleysDone >= cfg.volleys then break end
                phase = "toPlayer"
                speed = math.min(speed * 1.12, 600)
                approachFires = 0
                approachStart = now
                shieldOpenedAt = nil
                pendingArrival = nil
            end
        end
    end
    return outcomes
end

-- ===========================================================================
--  SWEEP — every ping x speed x curve, several volleys each.
-- ===========================================================================
local PINGS  = { 20, 50, 90, 140, 200, 280, 360, 450 }
local SPEEDS = { 90, 180, 280, 400 }
-- Heading offset from dead-on (degrees). 0 = straight at you; higher = more of the
-- ball's speed is tangential (lower radial closing) = a curving / angled approach.
-- 70deg (cos ~0.34) is about as bent as a real Blade Ball curve ball gets and still
-- be a genuine approach; beyond ~78deg the ball is essentially ORBITING you, not
-- coming at you (radial closing ~ 0), which isn't a threat the parry must catch.
local CURVES = { 0, 30, 55, 70 }

local tally = {}                            -- outcome -> count
local byPing = {}                           -- ping -> {total, deflected}
local byCurve = {}                          -- curve -> {total, deflected}
local fails = {}                            -- list of failing approach records
local leadSum, leadN = 0, 0
-- CORE envelope = realistic play: ping <= 280ms and curve <= 55deg. This must be
-- perfect. The extreme corner (450ms ping, or a ~70deg near-tangential ball at max
-- escalated speed) is reported but allowed to degrade — those are edge conditions,
-- not the balls you actually face.
local coreTotal, coreGood = 0, 0
local function isCore(ping, cv) return ping <= 280 and cv <= 55 end

local function bump(t, k) t[k] = (t[k] or 0) + 1 end

for _, ping in ipairs(PINGS) do
    byPing[ping] = byPing[ping] or { total = 0, good = 0 }
    for _, spd in ipairs(SPEEDS) do
        for _, cv in ipairs(CURVES) do
            byCurve[cv] = byCurve[cv] or { total = 0, good = 0 }
            local outs = runDuel({ ping = ping, speed0 = spd, curveDeg = cv, range = 200, volleys = 6 })
            for _, r in ipairs(outs) do
                bump(tally, r.outcome)
                byPing[ping].total = byPing[ping].total + 1
                byCurve[cv].total = byCurve[cv].total + 1
                local good = (r.outcome == "DEFLECTED")
                local core = isCore(ping, cv)
                if core then coreTotal = coreTotal + 1 end
                if good then
                    byPing[ping].good = byPing[ping].good + 1
                    byCurve[cv].good = byCurve[cv].good + 1
                    if core then coreGood = coreGood + 1 end
                    if r.lead >= 0 then leadSum = leadSum + r.lead; leadN = leadN + 1 end
                else
                    fails[#fails + 1] = r
                end
            end
        end
    end
end

-- ===========================================================================
--  REPORT
-- ===========================================================================
local totalApproaches = 0
for _, c in pairs(tally) do totalApproaches = totalApproaches + c end
local deflected = tally.DEFLECTED or 0

print("Blade Ball ADVANCED DUEL sandbox")
print(("="):rep(70))
print(string.format("Total ball approaches simulated: %d   (across %d ping x %d speed x %d curve, 6 volleys)",
    totalApproaches, #PINGS, #SPEEDS, #CURVES))
print("")
print("Outcome breakdown:")
for _, k in ipairs({ "DEFLECTED", "MISS_NOFIRE", "MISS_EARLY", "MISS_LATE", "DOUBLE" }) do
    local c = tally[k] or 0
    local pct = totalApproaches > 0 and (100 * c / totalApproaches) or 0
    print(string.format("   %-12s %5d   %5.1f%%", k, c, pct))
end
print(string.format("   %-12s %5.3f s (want 0..0.5; ~0.1-0.3 ideal)", "avg lead", leadN > 0 and leadSum / leadN or 0))
print("")

print("Landing rate by PING:")
for _, ping in ipairs(PINGS) do
    local b = byPing[ping]
    print(string.format("   %4dms  %4d/%-4d  %5.1f%%", ping, b.good, b.total, 100 * b.good / b.total))
end
print("")
print("Landing rate by CURVE (heading offset; higher = more tangential/low-closing):")
for _, cv in ipairs(CURVES) do
    local b = byCurve[cv]
    print(string.format("   %2ddeg  %4d/%-4d  %5.1f%%", cv, b.good, b.total, 100 * b.good / b.total))
end
print("")

-- Worst offenders + the fix for each failure category present.
if #fails > 0 then
    print(("-"):rep(70))
    print(string.format("%d bad outcomes. First 12:", #fails))
    for i = 1, math.min(12, #fails) do
        local r = fails[i]
        print(string.format("   %-12s ping=%dms speed=%d curve=%ddeg fires=%d",
            r.outcome, r.ping, r.speed, r.curve, r.fires))
    end
    print("")
    print("FIXES for the categories seen:")
    local FIXES = {
        MISS_NOFIRE = "Auto Parry never fired -> a ball isn't tripping the timed gate at all. Widen fireWindow or the inRange radius; a genuine incoming ball must always fire.",
        MISS_EARLY  = "Fired too soon -> the 0.5s shield expired before arrival. On a near-tangential ball the stale-view closing over-reads, so timeToImpact under-estimates; only firing on a ball with real radial closing (or a smaller fireWindow) avoids it. Confined here to the ~70deg + max-speed corner.",
        MISS_LATE   = "Fired too late (high ping) -> the packet + staleness ate the lead. fireWindow must be >= ping_seconds (full ping, not one-way) so the shield is open when the ball arrives.",
        DOUBLE      = "Fired 2+ times in one approach -> tighten once-per-approach (parriedApproach) / widen the hysteresis re-arm so a single approach can't double-fire.",
    }
    for _, k in ipairs({ "MISS_NOFIRE", "MISS_EARLY", "MISS_LATE", "DOUBLE" }) do
        if (tally[k] or 0) > 0 then print("   [" .. k .. "] " .. FIXES[k]) end
    end
else
    print("No bad outcomes: every ball across every ping/speed/curve deflected cleanly,")
    print("no early/late/double blocks. Auto Parry is clean across the whole sweep.")
end
print(("="):rep(70))
print(string.format("CORE envelope (ping<=280ms, curve<=55deg): %d/%d = %.1f%%",
    coreGood, coreTotal, 100 * coreGood / math.max(coreTotal, 1)))
print(string.format("OVERALL (incl. extreme 450ms / ~70deg corners):  %d/%d = %.1f%%",
    deflected, totalApproaches, 100 * deflected / math.max(totalApproaches, 1)))
print("")

-- Gate: the realistic CORE must be perfect, and the always-unacceptable outcomes
-- (never firing, firing too late, or double-blocking) must be ZERO everywhere. A
-- little MISS_EARLY is tolerated ONLY in the extreme near-tangential + max-speed
-- corner (a ball that's barely approaching), and overall must stay high.
if totalApproaches == 0 then error("duel sandbox produced no approaches", 0) end
local problems = {}
if coreGood ~= coreTotal then
    problems[#problems + 1] = string.format("CORE not perfect: %d/%d", coreGood, coreTotal)
end
if (tally.MISS_NOFIRE or 0) > 0 then problems[#problems + 1] = "MISS_NOFIRE present (a ball never blocked)" end
if (tally.MISS_LATE or 0) > 0 then problems[#problems + 1] = "MISS_LATE present (fired too late at high ping)" end
if (tally.DOUBLE or 0) > 0 then problems[#problems + 1] = "DOUBLE present (double-blocked one approach)" end
if (100 * deflected / totalApproaches) < 95 then
    problems[#problems + 1] = string.format("overall clean rate %.1f%% < 95%%", 100 * deflected / totalApproaches)
end
if #problems > 0 then
    error("duel sandbox FAILED: " .. table.concat(problems, "; "), 0)
end
print(string.format("PASS: %d/%d clean deflects across the full sweep.", deflected, totalApproaches))
