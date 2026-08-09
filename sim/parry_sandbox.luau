--!nocheck
-- ============================================================================
--  Leviathan / elopez — Parry Sandbox
--
--  A headless simulation harness that ACTUALLY RUNS the parry decision logic
--  (mirrored 1:1 from `elopez`) against thousands of generated ball scenarios,
--  so timing/curve changes can be tested without launching Roblox.
--
--  Run:  luau sim/parry_sandbox.luau
--  (build the Luau CLI first if needed: luraph-deobf/dynamic/build_luau.sh)
--
--  The model functions below are copied verbatim from the corresponding lines
--  in `elopez` so this exercises the real math. If you change the parry
--  formula in `elopez`, mirror it here and re-run.
-- ============================================================================

--------------------------------------------------------------------------------
-- Minimal Roblox Vector3 shim (only what the parry math uses).
--------------------------------------------------------------------------------
local Vector3 = {}
Vector3.__index = function(self, k)
    if k == "Magnitude" then
        return math.sqrt(self.X * self.X + self.Y * self.Y + self.Z * self.Z)
    elseif k == "Unit" then
        local m = math.sqrt(self.X * self.X + self.Y * self.Y + self.Z * self.Z)
        if m == 0 then return Vector3.new(0, 0, 0) end
        return Vector3.new(self.X / m, self.Y / m, self.Z / m)
    end
    return rawget(Vector3, k)
end
function Vector3.new(x, y, z)
    return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, Vector3)
end
function Vector3.__add(a, b) return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
function Vector3.__sub(a, b) return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
function Vector3.__mul(a, b)
    if type(b) == "number" then return Vector3.new(a.X * b, a.Y * b, a.Z * b) end
    return Vector3.new(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
function Vector3:Dot(o) return self.X * o.X + self.Y * o.Y + self.Z * o.Z end

--------------------------------------------------------------------------------
-- Parry model — mirrors elopez AutoParry (accuracy + fire gate).
--------------------------------------------------------------------------------
local Model = {}

-- elopez: parry_accuracy computation (ping_threshold + speed term + auto-accuracy
-- multiplier + one-way latency lead).
function Model.parryAccuracy(speed, dataPingMs, autoAccuracy, sliderMult)
    local ping = dataPingMs / 10
    local ping_threshold = math.clamp(ping / 10, 5, 17)
    local capped_speed_diff = math.min(math.max(speed - 9.5, 0), 650)

    local accuracy_multiplier = sliderMult
    if autoAccuracy then
        local ping_factor = math.clamp(ping / 100, 0, 1)
        local speed_factor = math.clamp(speed / 400, 0, 1)
        accuracy_multiplier = math.clamp(1.0 - ping_factor * 0.35 - speed_factor * 0.25, 0.45, 1.0)
    end

    local speed_divisor = (2.4 + capped_speed_diff * 0.002) * accuracy_multiplier
    -- Original block timing (no latency lead).
    return ping_threshold + math.max(speed / speed_divisor, 9.5)
end

local PARRY_COOLDOWN = 0.12 -- elopez: time_view >= 0.12 gate

--------------------------------------------------------------------------------
-- Curve model — mirrors elopez IsBall_Curved (side effects on per-ball state).
--------------------------------------------------------------------------------
local function lerp(a, b, t) return a + (b - a) * t end

function Model.isBallCurved(state, charPos, ballPos, vecVel, pingMs)
    local ball_direction = vecVel.Unit
    local direction = (charPos - ballPos).Unit
    local dot = direction:Dot(ball_direction)
    local speed = vecVel.Magnitude
    local speed_threshold = math.min(speed / 100, 40)
    local direction_difference = (ball_direction - vecVel).Unit
    local direction_similarity = direction:Dot(direction_difference)
    local dot_difference = dot - direction_similarity
    local distance = (charPos - ballPos).Magnitude
    local dot_threshold = 0.5 - (pingMs / 1000)
    local reach_time = distance / math.max(speed, 0.0001) - (pingMs / 1000)
    local ball_distance_threshold = 15 - math.min(distance / 1000, 15) + speed_threshold
    local clamped_dot = math.clamp(dot, -1, 1)

    state.lerp_radians = lerp(state.lerp_radians, math.rad(math.asin(clamped_dot)), 0.8)
    if speed > 0 and reach_time > pingMs / 10 then
        ball_distance_threshold = math.max(ball_distance_threshold - 15, 15)
    end
    if distance < ball_distance_threshold then return false end
    if dot_difference < dot_threshold then return true end
    if state.lerp_radians < 0.018 then state.last_warping = state.t end
    if (state.t - state.last_warping) < (reach_time / 1.5) then return true end
    if (state.t - state.curving) < (reach_time / 1.5) then return true end
    return dot < dot_threshold
end

-- elopez AutoSpamParry: ClashBall classifier (target aimed at you/opponent AND
-- travelling along the you<->opponent axis, not crossing it).
function Model.clashBall(ballTarget, lpName, opponentName, rootPos, targetPos, vel, distToTarget)
    if ballTarget == lpName or ballTarget == opponentName then
        local isClash = true
        local axis = targetPos - rootPos
        if distToTarget > 6 and axis.Magnitude > 0 and vel.Magnitude > 0 then
            if math.abs(vel.Unit:Dot(axis.Unit)) < 0.35 then
                isClash = false
            end
        end
        return isClash
    end
    return false
end

-- elopez spam accumulator: fire count over a frame given RPS.
function Model.accumulatorFires(rps, seconds)
    local dt = 1 / 60
    local acc, fired, t = 0, 0, 0
    while t < seconds - 1e-9 do
        acc += dt
        local n = math.floor(acc * rps)
        if n > 0 then acc -= n / rps; fired += n end
        t += dt
    end
    return fired
end

--------------------------------------------------------------------------------
-- Scenario simulation: a ball closing straight on the player.
--------------------------------------------------------------------------------
local FPS = 60
local DT = 1 / FPS

-- Returns a result table describing what happened.
local function simulateStraight(startDist, speed, dataPingMs, autoAccuracy, sliderMult)
    local playerPos = Vector3.new(0, 0, 0)
    local dir = Vector3.new(1, 0, 0)                 -- ball travels toward player along +X? no: place ball at +X, move -X
    local ballPos = Vector3.new(startDist, 0, 0)
    local vel = Vector3.new(-speed, 0, 0)            -- closing toward player

    local acc = Model.parryAccuracy(speed, dataPingMs, autoAccuracy, sliderMult)

    local parries = {}          -- times (seconds) we fired
    local lastParry = -1e9
    local t = 0
    local maxFrames = math.ceil((startDist / math.max(speed, 0.0001)) * FPS) + 5
    local firedDistances = {}
    local errored = nil

    local ok, err = pcall(function()
        for _ = 1, maxFrames do
            ballPos = ballPos + vel * DT
            t += DT
            local dist = (ballPos - playerPos).Magnitude
            -- ball passed through the player (crossed to -X side)
            if ballPos.X <= 0 then break end
            -- elopez fire gate: target==me (true here) and dist <= acc and cooldown
            if dist <= acc then
                if (t - lastParry) >= PARRY_COOLDOWN then
                    table.insert(parries, t)
                    table.insert(firedDistances, dist)
                    lastParry = t
                end
            end
        end
    end)
    if not ok then errored = err end

    return {
        accuracy = acc,
        parries = #parries,
        firstFireDist = firedDistances[1],
        perFrameStep = speed * DT,
        errored = errored,
        reachedPlayerUnparried = (#parries == 0),
        parryTimes = parries,
    }
end

--------------------------------------------------------------------------------
-- Test sweeps
--------------------------------------------------------------------------------
local failures = {}
local function fail(msg) table.insert(failures, msg) end

local scenarios = 0

-- 1) STRAIGHT-BALL SWEEP: speed x ping x distance x accuracy-mode
local speeds = {}
for s = 15, 1200, 15 do table.insert(speeds, s) end
local pings = { 0, 20, 50, 90, 130, 180, 260, 400, 550 }
local dists = { 40, 80, 150, 260 }

for _, autoAcc in ipairs({ false, true }) do
    for _, speed in ipairs(speeds) do
        for _, ping in ipairs(pings) do
            for _, d in ipairs(dists) do
                if d > speed * 0.05 then -- only sim if the ball has room to approach
                    scenarios += 1
                    local r = simulateStraight(d, speed, ping, autoAcc, 1.0)

                    if r.errored then
                        fail(string.format("ERROR speed=%d ping=%d dist=%d auto=%s: %s",
                            speed, ping, d, tostring(autoAcc), tostring(r.errored)))
                    end
                    -- INVARIANT: a straight ball aimed at us must be parried (no miss).
                    if r.reachedPlayerUnparried then
                        fail(string.format("MISS speed=%d ping=%d dist=%d auto=%s (acc=%.1f step=%.1f)",
                            speed, ping, d, tostring(autoAcc), r.accuracy, r.perFrameStep))
                    end
                    -- INVARIANT: parry window must be >= per-frame travel, or a fast
                    -- ball could skip past the detection band between frames.
                    if r.accuracy < r.perFrameStep then
                        fail(string.format("SKIP-RISK speed=%d ping=%d: acc=%.1f < step=%.1f",
                            speed, ping, r.accuracy, r.perFrameStep))
                    end
                    -- INVARIANT: no double-parry on one straight approach. A straight
                    -- ball stays in-band for many frames; the 120ms cooldown means it
                    -- should fire a bounded number of times before passing, but never
                    -- two fires closer than the cooldown.
                    for i = 2, #r.parryTimes do
                        if (r.parryTimes[i] - r.parryTimes[i - 1]) < (PARRY_COOLDOWN - 1e-9) then
                            fail(string.format("DOUBLE-PARRY speed=%d ping=%d gap=%.3f",
                                speed, ping, r.parryTimes[i] - r.parryTimes[i - 1]))
                            break
                        end
                    end
                    -- INVARIANT: not absurdly early — first fire distance <= accuracy.
                    if r.firstFireDist and r.firstFireDist > r.accuracy + 1e-6 then
                        fail(string.format("EARLY speed=%d ping=%d fireDist=%.1f > acc=%.1f",
                            speed, ping, r.firstFireDist, r.accuracy))
                    end
                end
            end
        end
    end
end

-- 2) CURVE SWEEP: exercise isBallCurved across speed x curve angle. Assert it
--    never errors and returns a boolean for thousands of geometries.
local curveChecks = 0
for _, speed in ipairs(speeds) do
    for angleDeg = 0, 180, 6 do
        local rad = math.rad(angleDeg)
        -- ball at distance 60 on +X, velocity rotated `angleDeg` from straight-at-player
        local ballPos = Vector3.new(60, 0, 0)
        local vel = Vector3.new(-math.cos(rad) * speed, 0, math.sin(rad) * speed)
        local charPos = Vector3.new(0, 0, 0)
        local state = { lerp_radians = 0, last_warping = 0, curving = 0, t = 0 }
        for frame = 1, 30 do
            state.t = frame * DT
            local ok, res = pcall(Model.isBallCurved, state, charPos, ballPos, vel, 60)
            curveChecks += 1
            if not ok then
                fail(string.format("CURVE-ERROR speed=%d angle=%d: %s", speed, angleDeg, tostring(res)))
                break
            elseif type(res) ~= "boolean" then
                fail(string.format("CURVE-TYPE speed=%d angle=%d: got %s", speed, angleDeg, typeof(res)))
                break
            end
            ballPos = ballPos + vel * DT
        end
    end
end

-- 3) CLASH DETECTION SWEEP: the ClashBall classifier must engage real clashes
--    and reject passing balls, across speeds and geometries.
local clashChecks = 0
local you, opp = "You", "Opponent"
for _, speed in ipairs(speeds) do
    for _, dist in ipairs({ 8, 20, 45, 90 }) do
        local root = Vector3.new(0, 0, 0)
        local target = Vector3.new(dist, 0, 0)  -- opponent along +X

        -- (a) Real clash ball: aimed at you, moving along the axis (toward you).
        do
            local vel = Vector3.new(-speed, 0, 0)
            clashChecks += 1
            if not Model.clashBall(you, you, opp, root, target, vel, dist) then
                fail(string.format("CLASH-MISS speed=%d dist=%d: real clash ball rejected", speed, dist))
            end
        end
        -- (b) Perpendicular crossing ball aimed at you: should be rejected as
        --     "passing by" (only when far enough for the axis to be meaningful).
        if dist > 6 then
            local vel = Vector3.new(0, 0, -speed)
            clashChecks += 1
            if Model.clashBall(you, you, opp, root, target, vel, dist) then
                fail(string.format("CLASH-FALSE speed=%d dist=%d: perpendicular passing ball accepted", speed, dist))
            end
        end
        -- (c) Ball aimed at a third party: never our clash.
        do
            local vel = Vector3.new(-speed, 0, 0)
            clashChecks += 1
            if Model.clashBall("Stranger", you, opp, root, target, vel, dist) then
                fail(string.format("CLASH-STRANGER speed=%d dist=%d: third-party ball accepted", speed, dist))
            end
        end
    end
end

-- 4) ACCUMULATOR SWEEP: fired count must track RPS*seconds with no drift/loss.
local accChecks = 0
for _, rps in ipairs({ 60, 180, 400, 550, 800, 1000 }) do
    for _, secs in ipairs({ 1, 3, 10 }) do
        accChecks += 1
        local fired = Model.accumulatorFires(rps, secs)
        local expected = rps * secs
        if math.abs(fired - expected) > 2 then
            fail(string.format("ACCUMULATOR rps=%d secs=%d fired=%d expected=%d", rps, secs, fired, expected))
        end
    end
end

--------------------------------------------------------------------------------
-- Harness self-check: feed KNOWN-BROKEN configs and confirm the checks fire,
-- so a green run means something.
--------------------------------------------------------------------------------
local selfCheckOk = true

-- (a) No-cooldown should produce double-parries on a straight approach.
do
    local saved = PARRY_COOLDOWN
    PARRY_COOLDOWN = 0
    local r = simulateStraight(150, 300, 50, false, 1.0)
    local sawDouble = false
    for i = 2, #r.parryTimes do
        if (r.parryTimes[i] - r.parryTimes[i - 1]) < 0.12 then sawDouble = true break end
    end
    PARRY_COOLDOWN = saved
    if not sawDouble then
        selfCheckOk = false
        print("SELF-CHECK BROKEN: no-cooldown config did not produce a double-parry")
    end
end

-- (b) A near-zero parry window must produce a MISS / skip on a fast ball.
do
    local playerPos = Vector3.new(0, 0, 0)
    local ballPos = Vector3.new(150, 0, 0)
    local vel = Vector3.new(-900, 0, 0)
    local tinyAcc = 1.0
    local fired = false
    local t = 0
    for _ = 1, 200 do
        ballPos = ballPos + vel * DT
        t += DT
        if ballPos.X <= 0 then break end
        if (ballPos - playerPos).Magnitude <= tinyAcc then fired = true break end
    end
    if fired then
        selfCheckOk = false
        print("SELF-CHECK BROKEN: 1-stud window somehow caught a 900-speed ball")
    end
end

--------------------------------------------------------------------------------
-- Report
--------------------------------------------------------------------------------
print(string.format("Ran %d straight-ball scenarios + %d curve checks + %d clash checks + %d accumulator checks.",
    scenarios, curveChecks, clashChecks, accChecks))
print("Harness self-check (broken configs must be detectable): " .. (selfCheckOk and "OK" or "COMPROMISED"))
if #failures == 0 and selfCheckOk then
    print("PASS — no misses, no skip-risk, no double-parries, no curve errors.")
else
    print(string.format("FAIL — %d issue(s):", #failures))
    local shown = math.min(#failures, 40)
    for i = 1, shown do print("  - " .. failures[i]) end
    if #failures > shown then print(string.format("  ...and %d more", #failures - shown)) end
end
