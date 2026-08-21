--!nocheck
-- ============================================================================
--  Blade Ball Auto Parry + Auto Spam — offline decision sandbox
--
--  This is a REAL test harness, not a demo. It reproduces the EXACT shipped
--  decision logic from `elopez` for both systems and drives it through every
--  scenario that has produced a bug report, asserting the observable behaviour:
--
--    Auto Parry (per-ball state machine, mirrors elopez ~L5460-5577):
--      • single incoming ball          -> fires exactly ONCE
--      • rally / clash (N volleys)      -> fires exactly N times (one per return)
--      • post-clash wobble (stays near) -> ZERO extra blocks
--      • ball never inbound / not mine  -> ZERO fires (no idle spam)
--      • high ping                      -> fires EARLIER (bigger radius) than low ping
--      • two balls, one mine            -> only the mine one fires
--      • one-frame target flicker       -> still ONE fire (cooldown floor holds)
--      • dead                           -> loop guarded off, ZERO fires
--
--    Auto Spam (accumulator + gate, mirrors elopez ~L8261-8337):
--      • steady rate                    -> ~TargetRPS packets/sec
--      • dead                           -> ZERO packets
--      • frame hitch                    -> burst bounded by the 0.05s dt clamp
--      • periodic block break           -> self-heals (broken% low) vs stuck
--
--  Pure Luau, no Roblox. The constants and branch structure are copied verbatim
--  from the shipped file so a divergence here means a real divergence there.
-- ============================================================================

local DT = 1 / 60

-- ---------------------------------------------------------------------------
--  SHIPPED LOGIC — copied verbatim from elopez (keep in sync).
-- ---------------------------------------------------------------------------

-- Auto Accuracy multiplier: elopez L5515-ish. Lower = bigger radius = earlier.
local function autoAccuracyMult(ping_ms)
    return math.clamp(0.95 - ping_ms * 0.0006, 0.72, 0.98)
end

-- parry_accuracy: elopez L5470-5488. autoAcc=true uses the adaptive multiplier.
local function parryAccuracy(speed, ping_ms, speedDivMult, autoAcc)
    speedDivMult = speedDivMult or 1
    if autoAcc then speedDivMult = autoAccuracyMult(ping_ms) end
    local ping_threshold = math.clamp(5 + ping_ms * 0.03, 5, 24)
    local capped_speed_diff = math.min(math.max(speed - 9.5, 0), 650)
    local speed_divisor = (2.4 + capped_speed_diff * 0.002) * speedDivMult
    local ping_seconds = math.clamp(ping_ms / 1000, 0, 0.45)
    local ping_lead = math.min(speed * ping_seconds, 70)
    return ping_threshold + math.max(speed / speed_divisor, 9.5) + ping_lead
end

-- Auto Parry per-ball decision: elopez L5522-5577.
-- state = { parried=false, last=0 }. Returns (fired, acc).
local function autoParryStep(state, now, mine, distance, speed, closing, ping_ms, speedDivMult)
    local acc = parryAccuracy(speed, ping_ms, speedDivMult)
    local inRange = distance <= acc
    local incoming = closing > 0
    local clearlyGone = (not mine) or (distance > acc * 1.35)
    local sinceLast = now - (state.last or 0)

    local fired = false
    if mine and inRange and incoming and not state.parried and sinceLast >= 0.2 then
        fired = true
        state.parried = true
        state.last = now
    elseif clearlyGone then
        state.parried = false
    else
        -- hold: parried this approach, or leaving/wobbling but not clearly gone
    end
    return fired, acc
end

-- Advanced Auto Spam detection decision: elopez ~L5865-5896 (the gates this
-- sandbox exercises). Returns whether ShouldSpam is set for one ball.
local function advancedShouldSpam(o)
    local proximityOK = o.advanced or (o.distToTarget <= o.targetCheck)
    local accelLead = math.clamp((o.accel or 0) * 0.002, 0, 0.05)
    local lead = (o.ping_ms / 1000) + (o.impactLead or 0.06) + accelLead
    local impact = o.closing > 0 and o.timeToImpact <= lead
    return o.distToBall <= o.ballReach and proximityOK and o.aimed and impact
end

-- Spam gate: elopez L8261-8275. env = { alive, stunned }.
local function makeSpamGate()
    local SpamStunHoldUntil = 0
    return function(now, env)
        if not env.alive then return false end          -- dead / no character
        if env.stunned then
            SpamStunHoldUntil = now + 0.12
            return false
        end
        if now < SpamStunHoldUntil then return false end
        return true
    end
end

-- Spam accumulator: elopez L8538-8561. Calls onFire() for each packet.
-- `active` false = nothing spamming: zero the accumulator and bail (no backlog,
-- instant stop on toggle-off).
local function makeSpamAccumulator()
    local timeAccumulator = 0
    return function(deltaTime, targetRPS, onFire, active)
        if active == false then timeAccumulator = 0; return end
        if deltaTime > 0.05 then deltaTime = 0.05 end    -- hitch clamp
        timeAccumulator += deltaTime
        if targetRPS <= 0 then return end
        local packetsToFire = math.floor(timeAccumulator * targetRPS)
        if packetsToFire > 0 then
            timeAccumulator -= (packetsToFire / targetRPS)
            for _ = 1, packetsToFire do onFire() end
        end
    end
end

-- ---------------------------------------------------------------------------
--  Tiny test runner
-- ---------------------------------------------------------------------------
local results = {}
local function check(name, ok, detail)
    results[#results + 1] = { name = name, ok = ok, detail = detail or "" }
end
local function approx(a, b, tol) return math.abs(a - b) <= tol end

-- ---------------------------------------------------------------------------
--  AUTO PARRY SCENARIOS
-- ---------------------------------------------------------------------------

-- Drive a ball at the player. Returns (fireCount, firstFireDistance).
-- traj(now, frame) -> mine, distance, speed, closing   (nil distance => skip)
local function driveBall(traj, ping_ms, frames)
    local state = { parried = false, last = 0 }
    local now, fires, firstDist = 0, 0, nil
    for f = 1, frames do
        now += DT
        local mine, distance, speed, closing = traj(now, f)
        if distance ~= nil then
            local fired = autoParryStep(state, now, mine, distance, speed, closing, ping_ms, 1)
            if fired then
                fires += 1
                if not firstDist then firstDist = distance end
            end
        end
    end
    return fires, firstDist
end

-- 1. Single approach: ball flies straight in, is parried, deflects away, then
--    retargets to the opponent. Exactly one block.
do
    local speed = 200
    local dist = 300
    local phase = "in"
    local fires = driveBall(function()
        if phase == "in" then
            dist = dist - speed * DT
            if dist <= 12 then phase = "out" end
            return true, dist, speed, speed          -- mine, closing in
        else
            dist = dist + speed * DT
            local mine = dist < 120                  -- after a bit it targets the opponent
            return mine, dist, speed, -speed         -- leaving
        end
    end, 60, 240)
    check("single approach -> 1 block", fires == 1, "got " .. fires)
end

-- 2. Rally: ball volleys between you and the opponent N times. Each return to
--    you is one block.
do
    local N = 6
    local speed = 260
    local dist, phase, done = 300, "in", 0
    local fires = driveBall(function()
        if phase == "in" then
            dist = dist - speed * DT
            if dist <= 12 then phase = "out" end
            return true, dist, speed, speed
        else
            dist = dist + speed * DT
            if dist >= 300 then                       -- reached opponent; send it back
                done = done + 1
                phase = "in"
                return false, dist, speed, -speed
            end
            return false, dist, speed, -speed         -- flying to opponent = not mine
        end
    end, 60, 60 * 12)
    check("rally of " .. N .. "+ volleys -> one block each", fires >= 5 and fires <= 8,
        "got " .. fires .. " (expect ~ per return volley)")
end

-- 3. Post-clash wobble: after a block the ball hangs near you for ~0.5s with its
--    closing sign flipping every frame, then leaves. ZERO extra blocks.
do
    local speed = 40
    local dist, phase, wob = 300, "in", 0
    local fires = driveBall(function(now, f)
        if phase == "in" then
            dist = dist - 200 * DT
            if dist <= 12 then phase = "wobble" end
            return true, dist, 200, 200
        elseif phase == "wobble" then
            wob = wob + 1
            if wob > 30 then phase = "leave" end
            -- stays close (well inside 1.35*acc), closing flips each frame
            local closing = (f % 2 == 0) and 20 or -20
            return true, 18, speed, closing
        else
            dist = dist + 200 * DT
            return (dist < 120), dist, 200, -200
        end
    end, 60, 60 * 4)
    -- exactly the one approach block; nothing during the wobble
    check("post-clash wobble -> no extra blocks", fires == 1, "got " .. fires)
end

-- 4a. Ball that never comes inbound (always leaving): zero blocks.
do
    local dist = 50
    local fires = driveBall(function()
        dist = dist + 100 * DT
        return true, dist, 150, -150                   -- mine but always moving away
    end, 60, 180)
    check("never-inbound ball -> no block", fires == 0, "got " .. fires)
end

-- 4b. Ball targeting someone else passing through your range: zero blocks.
do
    local dist = 300
    local fires = driveBall(function()
        dist = dist - 200 * DT
        if dist < 5 then dist = 300 end
        return false, dist, 200, 200                   -- not mine
    end, 60, 300)
    check("not-mine ball in range -> no block (no idle spam)", fires == 0, "got " .. fires)
end

-- 5. High ping fires earlier (larger radius) than low ping.
do
    local function approachFireDist(ping)
        local speed = 300
        local dist = 400
        local _, firstDist = driveBall(function()
            dist = dist - speed * DT
            return true, dist, speed, speed
        end, ping, 240)
        return firstDist
    end
    local lo = approachFireDist(30)
    local hi = approachFireDist(250)
    check("high ping fires earlier (bigger radius)", hi ~= nil and lo ~= nil and hi > lo + 10,
        string.format("30ms fired @%.0f, 250ms fired @%.0f", lo or -1, hi or -1))
end

-- 6. Two balls: one mine incoming, one not-mine incoming. Only mine fires.
do
    local sMine = { parried = false, last = 0 }
    local sOther = { parried = false, last = 0 }
    local dMine, dOther, now, fMine, fOther = 300, 300, 0, 0, 0
    for _ = 1, 240 do
        now += DT
        dMine = math.max(dMine - 200 * DT, 8)
        dOther = math.max(dOther - 200 * DT, 8)
        if (autoParryStep(sMine, now, true, dMine, 200, 200, 60, 1)) then fMine = fMine + 1 end
        if (autoParryStep(sOther, now, false, dOther, 200, 200, 60, 1)) then fOther = fOther + 1 end
    end
    check("multi-ball -> only mine fires", fMine == 1 and fOther == 0,
        "mine=" .. fMine .. " other=" .. fOther)
end

-- 7. One-frame target flicker mid-approach must NOT double-fire (cooldown floor).
do
    local state = { parried = false, last = 0 }
    local now, fires = 0, 0
    local dist = 300
    for f = 1, 120 do
        now += DT
        dist = math.max(dist - 200 * DT, 8)
        local mine = not (f == 40)                      -- one glitch frame: target flickers away
        if (autoParryStep(state, now, mine, dist, 200, 200, 60, 1)) then fires = fires + 1 end
    end
    check("1-frame target flicker -> still one block", fires == 1, "got " .. fires)
end

-- 7b. Auto Accuracy widens the radius (fires earlier) and still scales with ping,
--     without ever collapsing the radius to nothing.
do
    local speed = 300
    local accFixed = parryAccuracy(speed, 200, 1.1, false)
    local accAuto = parryAccuracy(speed, 200, 1.1, true)
    local accAutoLo = parryAccuracy(speed, 30, 1.1, true)
    check("auto-accuracy fires earlier than fixed + scales w/ ping",
        accAuto > accFixed and accAuto > accAutoLo,
        string.format("fixed@200=%.0f auto@200=%.0f auto@30=%.0f", accFixed, accAuto, accAutoLo))
end

-- ---------------------------------------------------------------------------
--  AUTO SPAM SCENARIOS
-- ---------------------------------------------------------------------------

-- 8. Steady rate: alive, not stunned -> ~TargetRPS packets/sec.
do
    local gate = makeSpamGate()
    local acc = makeSpamAccumulator()
    local now, fired = 0, 0
    for _ = 1, 60 do                                    -- 1 second at 60 fps
        now += DT
        acc(DT, 1000, function() if gate(now, { alive = true, stunned = false }) then fired = fired + 1 end end)
    end
    check("spam 1000 rps -> ~1000/s", approx(fired, 1000, 30), "got " .. fired)
end

-- 9. Dead -> zero packets even at full rate.
do
    local gate = makeSpamGate()
    local acc = makeSpamAccumulator()
    local now, fired = 0, 0
    for _ = 1, 60 do
        now += DT
        acc(DT, 2000, function() if gate(now, { alive = false, stunned = false }) then fired = fired + 1 end end)
    end
    check("spam while dead -> 0", fired == 0, "got " .. fired)
end

-- 10. Frame hitch: a 0.5s hang must not dump a 0.5s*rps burst; clamp bounds it.
do
    local acc = makeSpamAccumulator()
    local burst = 0
    acc(0.5, 2000, function() burst = burst + 1 end)    -- single hitched frame
    check("hitch burst bounded by 0.05s clamp", burst <= math.floor(0.05 * 2000) + 1,
        "burst=" .. burst .. " (cap " .. math.floor(0.05 * 2000) .. ")")
end

-- 11. Periodic block break: 'stunned' gate + recovery hold self-heals; a gate
--     that keeps firing while broken stays stuck.
do
    local STUN, BREAK_EVERY, DURATION = 1.2, 6, 30
    local function run(useGate)
        local gate = makeSpamGate()
        local now, stunUntil, nextBreak, broken = 0, 0, BREAK_EVERY, 0
        local stunnedNow = false
        for _ = 1, math.floor(DURATION / DT) do
            now += DT
            if now >= nextBreak then stunnedNow = true; stunUntil = now + STUN; nextBreak = now + BREAK_EVERY end
            if stunnedNow then
                broken += DT
                if now >= stunUntil then stunnedNow = false end
            end
            -- fire attempt
            local canFire = useGate and gate(now, { alive = true, stunned = stunnedNow }) or (not useGate)
            if canFire and stunnedNow then
                stunUntil = now + STUN                   -- feeding a broken guard re-arms the stun
            end
        end
        return broken / DURATION
    end
    local none = run(false)
    local gated = run(true)
    -- Floor is the external break itself (STUN/BREAK_EVERY ~= 20%); the gate must
    -- land near it, while an ungated feed re-arms the stun and stays mostly broken.
    check("block-break self-heals with gate", gated < 0.25 and none > 0.5,
        string.format("none=%.0f%% broken, gated=%.0f%% broken", none * 100, gated * 100))
end

-- 12. Advanced spam: a long-range ball aimed at you, inbound and within impact
--     lead, should spam even with NO player nearby (proximity gate off in
--     Advanced) — but the legacy Distance mode's proximity gate suppresses it.
do
    local base = {
        distToBall = 40, ballReach = 60, distToTarget = 500, targetCheck = 25,
        aimed = true, closing = 300, timeToImpact = 0.1, ping_ms = 80, impactLead = 0.06, accel = 0,
    }
    local adv = advancedShouldSpam(setmetatable({ advanced = true }, { __index = base }))
    local legacy = advancedShouldSpam(setmetatable({ advanced = false }, { __index = base }))
    check("advanced spam ignores duel-proximity on long-range aimed ball",
        adv == true and legacy == false, "adv=" .. tostring(adv) .. " legacy=" .. tostring(legacy))
end

-- 13. Advanced spam accel-lead: a ball just outside the lead window catches once
--     it's accelerating hard.
do
    local base = {
        distToBall = 40, ballReach = 60, distToTarget = 10, targetCheck = 25,
        aimed = true, closing = 300, ping_ms = 60, impactLead = 0.06, advanced = true,
    }
    local steady = advancedShouldSpam(setmetatable({ timeToImpact = 0.14, accel = 0 }, { __index = base }))
    local ramping = advancedShouldSpam(setmetatable({ timeToImpact = 0.14, accel = 40 }, { __index = base }))
    check("advanced spam accel-lead catches a ramping ball", steady == false and ramping == true,
        "steady=" .. tostring(steady) .. " ramping=" .. tostring(ramping))
end

-- "Manual spam when you turn it off keeps on going for so long": once toggled
-- off (active=false) the accumulator zeroes and NOTHING fires, even right after a
-- frame hitch that would otherwise have queued a burst.
do
    local acc = makeSpamAccumulator()
    local fired = 0
    -- spam ON with a big hitch (would queue a backlog), then immediately OFF
    acc(0.05, 2000, function() fired = fired + 1 end, true)  -- active frame (burst allowed, bounded)
    local firedWhileOn = fired
    fired = 0
    for _ = 1, 30 do                                          -- half a second after toggle-off
        acc(1 / 60, 2000, function() fired = fired + 1 end, false)
    end
    check("manual spam stops instantly on toggle-off (no backlog)",
        firedWhileOn > 0 and fired == 0, "afterOff=" .. fired)
end

-- ===========================================================================
--  REGRESSIONS FOR THE BUGS REPORTED IN-GAME (each named after the complaint,
--  mirroring the exact shipped helper, so they can never silently come back).
-- ===========================================================================

-- BallTargetsMe: elopez L4711. Target can be Name / DisplayName / UserId (number).
local function ballTargetsMe(t, lp)
    if t == nil then return false end
    local ts = tostring(t)
    return ts == lp.name or ts == lp.displayName or ts == tostring(lp.userId)
end

-- "It says not targeting me when it target me" -> match Name / DisplayName / UserId.
do
    local me = { name = "r3chel01", displayName = "Rachel", userId = 12345 }
    local okName = ballTargetsMe("r3chel01", me)
    local okDisplay = ballTargetsMe("Rachel", me)
    local okId = ballTargetsMe(12345, me)          -- numeric target
    local notOpp = ballTargetsMe("someoneElse", me) == false
    local notNil = ballTargetsMe(nil, me) == false
    check("target matches Name/DisplayName/UserId (not-targeting-me bug)",
        okName and okDisplay and okId and notOpp and notNil, "")
end

-- "Make it when it's in a clash the clash stops... not still block for nothing":
-- fire once on the approach, then the ball deflects (closing goes negative) and
-- it must STOP — no extra blocks while the ball is leaving.
do
    -- last = -1 mirrors a fresh ball (real game: LastParry 0 vs a large os.clock()
    -- => sinceLast huge => fires immediately; the sim's clock starts at 0).
    local state = { parried = false, last = -1 }
    local now, fires = 0, 0
    -- approach: mine, inbound, in range
    for _ = 1, 8 do
        now = now + DT
        if (autoParryStep(state, now, true, 12, 200, 200, 60, 1)) then fires = fires + 1 end
    end
    -- deflected: still mine and close, but now moving AWAY (closing < 0) for 30 frames
    for _ = 1, 30 do
        now = now + DT
        if (autoParryStep(state, now, true, 14, 200, -200, 60, 1)) then fires = fires + 1 end
    end
    check("stops the instant the clash ends (no block for nothing)", fires == 1, "fires=" .. fires)
end

-- Skin model apply guard: elopez setSword (build once per char+skin).
local function makeSkinApplier()
    local appliedChar, appliedName, builds = nil, nil, 0
    return {
        apply = function(char, name)
            if appliedChar ~= char or appliedName ~= name then
                builds = builds + 1
                appliedChar, appliedName = char, name
            end
        end,
        reset = function() appliedChar, appliedName = nil, nil end,   -- updateSword clears guard
        builds = function() return builds end,
    }
end

-- "My sword stuck into the sword": the apply burst runs setSword 5x and it also
-- re-runs on respawn — without the guard each call stacked another model. The
-- guard must build ONCE per character+skin (not once per call).
do
    local sk = makeSkinApplier()
    local char = {}
    for _ = 1, 5 do sk.apply(char, "Prismatic Odachi") end   -- 5x burst, same char+skin
    check("skin builds once per burst (stuck-sword bug)", sk.builds() == 1, "builds=" .. sk.builds())
    -- respawn (new char) rebuilds once; picking a new skin (reset) rebuilds once
    sk.apply({}, "Prismatic Odachi")
    sk.reset(); sk.apply(char, "Oni Ghost")
    check("skin rebuilds once on respawn / new pick", sk.builds() == 3, "builds=" .. sk.builds())
end

-- Skin persistence: elopez LeviathanSkinSnapshot / LeviathanRestoreSkin.
local function skinSnapshot(sc)
    return { Enabled = sc.enabled, ModelName = sc.model, FXName = sc.fx, AnimName = sc.anim }
end
local function skinRestore(sc, snap)
    if type(snap.Enabled) == "boolean" then sc.enabled = snap.Enabled end
    if type(snap.ModelName) == "string" then sc.model = snap.ModelName end
    if type(snap.FXName) == "string" then sc.fx = snap.FXName end
    if type(snap.AnimName) == "string" then sc.anim = snap.AnimName end
end

-- "Save your options and re-apply" on rejoin: snapshot survives a round-trip
-- into a fresh (default) SkinChanger.
do
    local saved = skinSnapshot({ enabled = true, model = "Riftflare Katana", fx = "SlashEffect", anim = "Riftflare Katana" })
    local fresh = { enabled = false, model = "", fx = "", anim = "" }   -- defaults after a rejoin
    skinRestore(fresh, saved)
    check("skin selections persist across rejoin",
        fresh.enabled == true and fresh.model == "Riftflare Katana" and fresh.anim == "Riftflare Katana", "")
end

-- ---------------------------------------------------------------------------
--  Report
-- ---------------------------------------------------------------------------
print("Blade Ball Auto Parry + Auto Spam sandbox")
print(("="):rep(58))
local passed = 0
for _, r in ipairs(results) do
    local tag = r.ok and "PASS" or "FAIL"
    if r.ok then passed = passed + 1 end
    print(string.format("[%s] %-42s %s", tag, r.name, r.detail))
end
print(("="):rep(58))
print(string.format("%d / %d passed", passed, #results))
if passed ~= #results then error("sandbox: " .. (#results - passed) .. " scenario(s) FAILED", 0) end
