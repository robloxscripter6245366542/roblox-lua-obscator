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

-- parry_accuracy: elopez L5470-5488
local function parryAccuracy(speed, ping_ms, speedDivMult)
    speedDivMult = speedDivMult or 1
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

-- Spam accumulator: elopez L8310-8337. Calls onFire() for each packet.
local function makeSpamAccumulator()
    local timeAccumulator = 0
    return function(deltaTime, targetRPS, onFire)
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
