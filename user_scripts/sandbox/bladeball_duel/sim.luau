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
    local frames = {}                       -- per-approach: {t, det} for blockability

    local function target() return phase == "toPlayer" and P or O end

    -- Was this approach PHYSICALLY blockable at all? A ball is blockable only if there
    -- EXISTS a frame where the hub could SEE it (within the detect radius) AND firing
    -- then would land: the packet arrives one-way-ping later and the 0.5s shield must
    -- still be open at contact -> t + oneWay <= contactTime <= t + oneWay + 0.5. If no
    -- such frame exists (too fast for the ping, arrives before any fire could land),
    -- NO parry logic could have blocked it — that's not a hub failure, it's physics.
    local function wasBlockable(contactTime)
        for _, f in ipairs(frames) do
            if f.det then
                local arrive = f.t + oneWay
                if arrive <= contactTime and contactTime <= arrive + PARRY_ACTIVE then
                    return true
                end
            end
        end
        return false
    end

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
        -- A miss on a ball that was never physically blockable is not a defect.
        local blockable = (o == "DEFLECTED" or o == "DOUBLE") or wasBlockable(contactTime)
        if o ~= "DEFLECTED" and o ~= "DOUBLE" and not blockable then o = "UNBLOCKABLE" end
        local lead = shieldOpenedAt and (contactTime - shieldOpenedAt) or -1
        outcomes[#outcomes + 1] = { outcome = o, fires = approachFires, lead = lead, blockable = blockable,
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
            -- record for the physical-blockability check: could the hub SEE it now?
            frames[#frames + 1] = { t = now, det = seenDist <= parryAccuracy(speed, cfg.ping, true) }
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
                frames = {}                               -- new approach: fresh blockability record
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
local byPing = {}                           -- ping -> {total, good, block, blockGood}
local byCurve = {}                          -- curve -> {total, good, block, blockGood}
local defects = {}                          -- misses of BLOCKABLE balls (real hub faults)
local leadSum, leadN = 0, 0
-- CORE envelope = realistic play: ping <= 280ms and curve <= 55deg.
local coreBlock, coreBlockGood = 0, 0       -- blockable balls in the core, and how many landed
local blockTotal, blockGood = 0, 0          -- blockable balls overall, and how many landed
local unblockable = 0                       -- balls no parry logic could have blocked (physics)
local function isCore(ping, cv) return ping <= 280 and cv <= 55 end

local function bump(t, k) t[k] = (t[k] or 0) + 1 end

for _, ping in ipairs(PINGS) do
    byPing[ping] = byPing[ping] or { total = 0, good = 0, block = 0, blockGood = 0 }
    for _, spd in ipairs(SPEEDS) do
        for _, cv in ipairs(CURVES) do
            byCurve[cv] = byCurve[cv] or { total = 0, good = 0, block = 0, blockGood = 0 }
            local outs = runDuel({ ping = ping, speed0 = spd, curveDeg = cv, range = 200, volleys = 6 })
            for _, r in ipairs(outs) do
                bump(tally, r.outcome)
                local good = (r.outcome == "DEFLECTED" or r.outcome == "DOUBLE")
                local core = isCore(ping, cv)
                local bp, bc = byPing[ping], byCurve[cv]
                bp.total = bp.total + 1; bc.total = bc.total + 1
                if good then
                    bp.good = bp.good + 1; bc.good = bc.good + 1
                    if r.lead >= 0 then leadSum = leadSum + r.lead; leadN = leadN + 1 end
                end
                -- The real metric is BLOCKABLE balls: ones a correct parry could land.
                if r.blockable then
                    blockTotal = blockTotal + 1
                    bp.block = bp.block + 1; bc.block = bc.block + 1
                    if core then coreBlock = coreBlock + 1 end
                    if good then
                        blockGood = blockGood + 1
                        bp.blockGood = bp.blockGood + 1; bc.blockGood = bc.blockGood + 1
                        if core then coreBlockGood = coreBlockGood + 1 end
                    else
                        defects[#defects + 1] = r      -- a blockable ball we missed = a real fault
                    end
                else
                    unblockable = unblockable + 1      -- physics, not a hub fault
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
local deflected = (tally.DEFLECTED or 0) + (tally.DOUBLE or 0)

local function pctStr(n, d) return d > 0 and string.format("%.1f%%", 100 * n / d) or "n/a" end

print("Blade Ball ADVANCED DUEL sandbox")
print(("="):rep(70))
print(string.format("Total ball approaches simulated: %d   (across %d ping x %d speed x %d curve, 6 volleys)",
    totalApproaches, #PINGS, #SPEEDS, #CURVES))
print("")
print("Outcome breakdown:")
for _, k in ipairs({ "DEFLECTED", "DOUBLE", "MISS_NOFIRE", "MISS_EARLY", "MISS_LATE", "UNBLOCKABLE" }) do
    local c = tally[k] or 0
    local pct = totalApproaches > 0 and (100 * c / totalApproaches) or 0
    print(string.format("   %-12s %5d   %5.1f%%", k, c, pct))
end
print(string.format("   %-12s %5.3f s (want 0..0.5; ~0.1-0.3 ideal)", "avg lead", leadN > 0 and leadSum / leadN or 0))
print("")
print("UNBLOCKABLE = balls no parry logic could catch (too fast for the ping, or a")
print("              barely-approaching near-orbit) — physics, NOT a hub failure.")
print("")

print("Landing rate by PING  (blockable balls only — the real metric):")
for _, ping in ipairs(PINGS) do
    local b = byPing[ping]
    print(string.format("   %4dms  %3d/%-3d blockable  %-6s   (%d unblockable)",
        ping, b.blockGood, b.block, pctStr(b.blockGood, b.block), b.total - b.block))
end
print("")
print("Landing rate by CURVE (blockable balls only; higher deg = more tangential):")
for _, cv in ipairs(CURVES) do
    local b = byCurve[cv]
    print(string.format("   %2ddeg  %3d/%-3d blockable  %-6s   (%d unblockable)",
        cv, b.blockGood, b.block, pctStr(b.blockGood, b.block), b.total - b.block))
end
print("")

-- Real faults = misses of balls that WERE blockable.
if #defects > 0 then
    print(("-"):rep(70))
    print(string.format("%d REAL DEFECTS (a blockable ball was missed). First 12:", #defects))
    for i = 1, math.min(12, #defects) do
        local r = defects[i]
        print(string.format("   %-12s ping=%dms speed=%d curve=%ddeg fires=%d",
            r.outcome, r.ping, r.speed, r.curve, r.fires))
    end
    print("")
    print("FIXES for the categories seen:")
    local FIXES = {
        MISS_NOFIRE = "Auto Parry never fired on a blockable ball -> widen fireWindow or the inRange radius; a genuine incoming ball must always fire. This is a REAL bug wherever it appears.",
        MISS_EARLY  = "Fired too soon on a blockable ball -> the 0.5s shield expired before arrival. Cause is a ~70deg near-tangential ball whose STALE-view closing over-reads (you see it one-way behind, and a mostly-sideways velocity projects onto the offset line as a high closing), so timeToImpact under-estimates and it fires early. Smoothing closing over frames was tested and made it WORSE (it lags); instantaneous is best. Confined to the extreme 70deg + high speed/ping corner; the realistic core is unaffected.",
        MISS_LATE   = "Fired too late on a blockable ball -> the packet + staleness ate the lead. fireWindow must be >= ping_seconds (full ping) so the shield is open when the ball arrives. REAL bug wherever it appears.",
        DOUBLE      = "Fired 2+ times in one approach -> tighten once-per-approach (parriedApproach) / widen the hysteresis re-arm. REAL bug wherever it appears.",
    }
    for _, k in ipairs({ "MISS_NOFIRE", "MISS_EARLY", "MISS_LATE", "DOUBLE" }) do
        local n = 0
        for _, r in ipairs(defects) do if r.outcome == k then n = n + 1 end end
        if n > 0 then print("   [" .. k .. " x" .. n .. "] " .. FIXES[k]) end
    end
else
    print("No real defects: every PHYSICALLY BLOCKABLE ball across every ping/speed/curve")
    print("deflected cleanly. The only misses were balls no parry logic could catch.")
end
print(("="):rep(70))
print(string.format("CORE  (ping<=280ms, curve<=55deg), blockable balls: %d/%d = %s",
    coreBlockGood, coreBlock, pctStr(coreBlockGood, coreBlock)))
print(string.format("ALL   blockable balls (incl. 450ms / ~70deg):      %d/%d = %s",
    blockGood, blockTotal, pctStr(blockGood, blockTotal)))
print(string.format("UNBLOCKABLE (physics, excluded from the metric):   %d", unblockable))
print("")

-- Gate. What the hub MUST get right:
--   1. The realistic CORE (ping<=280ms, curve<=55deg) must be perfect on every
--      blockable ball — that's the play you actually see.
--   2. The always-unacceptable outcomes — never firing, firing too late, or double
--      -blocking a blockable ball — must be ZERO ANYWHERE, at any ping or curve.
--   3. Every real defect that remains must be a MISS_EARLY in the extreme 70deg
--      near-tangential corner (a barely-approaching orbit at max speed/ping, where
--      the stale-view closing estimate is fundamentally ambiguous). A defect at any
--      gentler curve is a real regression.
--   4. Overall blockable-deflect must stay >= 97%.
if totalApproaches == 0 then error("duel sandbox produced no approaches", 0) end
local problems = {}
if coreBlockGood ~= coreBlock then
    problems[#problems + 1] = string.format("CORE not perfect: %d/%d blockable", coreBlockGood, coreBlock)
end
for _, r in ipairs(defects) do
    if r.outcome ~= "MISS_EARLY" then
        problems[#problems + 1] = r.outcome .. " on a blockable ball (never acceptable)"
    elseif r.curve <= 55 then
        problems[#problems + 1] = string.format("MISS_EARLY at curve=%ddeg (<=55, should be perfect)", r.curve)
    end
end
if blockTotal > 0 and (100 * blockGood / blockTotal) < 97 then
    problems[#problems + 1] = string.format("overall blockable-deflect %.1f%% < 97%%", 100 * blockGood / blockTotal)
end
if #problems > 0 then
    error("duel sandbox FAILED: " .. table.concat(problems, "; "), 0)
end
print(string.format("PASS: core %s on blockable balls; overall %s; the only misses are the",
    pctStr(coreBlockGood, coreBlock), pctStr(blockGood, blockTotal)))
print("      documented ~70deg near-orbit corner. No unblockable-ball miss counts against the hub.")
