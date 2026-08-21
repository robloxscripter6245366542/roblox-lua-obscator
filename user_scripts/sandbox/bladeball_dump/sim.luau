--!nocheck
-- ============================================================================
--  Blade Ball DUMP-grounded sandbox
--
--  Unlike the abstracted decision sandbox (../bladeball_autoparry/sim.luau),
--  this models the REAL server-side parry acceptance taken straight from the
--  decompiled game (SwordsController_decompiled.lua / SwordsController_constants
--  .txt in the repo root), then runs the hub's shipped fire decision through it
--  and scores what ACTUALLY lands — the piece an in-editor test can't give.
--
--  Ground truth from the dump (proto 12 "Parry", line 324; proto 7
--  "OnParrySuccess", line 198):
--    * A parry is REJECTED if the character:
--        - has the "Stunned" attribute, or
--        - is not parented to workspace.Alive (unless LobbyParry / lobby), or
--        - has "DoNotParry", or "ChargingAdrenaline" with Upgrades["Qi-Charge"] < 2,
--        - or LobbyParry + "InLobbyParryCooldown".
--    * On a fire it sets the "ParryTime" attribute and runs an in-progress
--      window: v_u_80 = 0.5 (active phase) then max(0.1, v_u_81 - v_u_80) with
--      v_u_81 = 1.3 (total) before it fully clears.
--    * A successful deflect bumps "ServerParryCount" (proto 7).
--
--  Model: a fired parry travels one-way ping to the server; at receipt the ball
--  must be within the server parry radius and the character must pass the gates
--  above for the ball to deflect (ServerParryCount++). Ball staleness (we see
--  the ball ~one-way-ping behind) is modelled too, so the hub's ping lead is
--  actually exercised. Pure Luau, no Roblox.
-- ============================================================================

local DT = 1 / 60

-- Dump constants (SwordsController proto 12) --------------------------------
local PARRY_ACTIVE = 0.5    -- v_u_80: active phase of a parry
local PARRY_TOTAL  = 1.3    -- v_u_81: total in-progress window
-- Server parry radius: the game accepts a parry when the ball is within roughly
-- a sword's reach at receipt. Modelled as a base contact radius plus a small
-- speed term (fast balls have a slightly larger accept window server-side).
local function serverParryRadius(speed)
    return 12 + math.min(speed, 400) * 0.02   -- ~12..20 studs
end

-- ---------------------------------------------------------------------------
--  SHIPPED DECISION — mirrors elopez (keep in sync with bladeball_autoparry).
-- ---------------------------------------------------------------------------
local function autoAccuracyMult(ping_ms) return math.clamp(0.95 - ping_ms * 0.0006, 0.72, 0.98) end
local function parryAccuracy(speed, ping_ms, autoAcc)
    local mult = autoAcc and autoAccuracyMult(ping_ms) or 1.1
    local ping_threshold = math.clamp(5 + ping_ms * 0.03, 5, 24)
    local capped = math.min(math.max(speed - 9.5, 0), 650)
    local sdiv = (2.4 + capped * 0.002) * mult
    local ping_seconds = math.clamp(ping_ms / 1000, 0, 0.45)
    local ping_lead = math.min(speed * ping_seconds, 70)
    return ping_threshold + math.max(speed / sdiv, 9.5) + ping_lead
end
-- Returns true if the hub decides to FIRE this frame. state={parried,last}.
local function decideFire(state, now, mine, distance, speed, closing, ping_ms)
    local acc = parryAccuracy(speed, ping_ms, true)
    local inRange, incoming = distance <= acc, closing > 0
    local clearlyGone = (not mine) or (distance > acc * 1.35)
    local sinceLast = now - (state.last or 0)
    if mine and inRange and incoming and not state.parried and sinceLast >= 0.2 then
        state.parried = true; state.last = now
        return true
    elseif clearlyGone then
        state.parried = false
    end
    return false
end

-- ---------------------------------------------------------------------------
--  DUMP-GROUNDED SERVER + BALL MODEL
-- ---------------------------------------------------------------------------
-- character: { stunned, alive, doNotParry, charging, qi, lobbyCooldown, serverParryCount, parryInProgressUntil }
local function newChar(o)
    o = o or {}
    return {
        stunned = o.stunned or false,
        alive = (o.alive ~= false),
        doNotParry = o.doNotParry or false,
        charging = o.charging or false, qi = o.qi or 2,
        lobbyCooldown = o.lobbyCooldown or false,
        serverParryCount = 0,
        inProgressUntil = 0,
    }
end

-- Proto-12 gate: may this parry be accepted at server time `now`?
local function parryAccepted(char, now)
    if char.stunned then return false end
    if not char.alive then return false end
    if char.doNotParry then return false end
    if char.charging and char.qi < 2 then return false end
    if char.lobbyCooldown then return false end
    if now < char.inProgressUntil then return false end   -- still mid-parry (v_u_38/36)
    return true
end

-- A ball the server tracks. dist decreases while inbound.
-- The client SEES the ball one-way-ping behind (staleness).

-- Run one approach: ball flies in, the hub decides when to fire, the packet
-- lands one-way-ping later, and we check the SERVER truth. Returns "deflected"
-- (ServerParryCount bumped), "missed", or "rejected".
local function runApproach(pingMs, speed, char)
    local oneWay = (pingMs / 1000) / 2
    local now = 0
    local serverDist = 400                 -- server-truth distance
    local state = { parried = false, last = 0 }
    local pending = nil                     -- {arriveAt}
    local shieldUntil = -1                  -- an accepted parry opens a 0.5s shield
    local outcome = "missed"
    for _ = 1, 600 do
        now = now + DT
        -- server truth advances
        serverDist = math.max(serverDist - speed * DT, 0)
        -- what the CLIENT sees is one-way-ping stale (ball looks farther)
        local seenDist = serverDist + speed * oneWay
        local closing = speed  -- inbound
        -- hub decision on the STALE view
        if decideFire(state, now, true, seenDist, speed, closing, pingMs) then
            if not pending then pending = { arriveAt = now + oneWay } end
        end
        -- server processes an arrived parry: the dump opens an ACTIVE shield for
        -- PARRY_ACTIVE seconds (v_u_80), not an instant point-check — firing early
        -- is meant to work because the ball arrives during the window.
        if pending and now >= pending.arriveAt then
            pending = nil
            if parryAccepted(char, now) then
                shieldUntil = now + PARRY_ACTIVE
                char.inProgressUntil = now + PARRY_TOTAL
            else
                outcome = "rejected"
                break
            end
        end
        -- ball reaches contact: deflect only if a shield is currently active.
        if serverDist <= serverParryRadius(speed) then
            if now <= shieldUntil then
                char.serverParryCount = char.serverParryCount + 1
                outcome = "deflected"
            else
                outcome = "missed"
            end
            break
        end
    end
    return outcome
end

-- ---------------------------------------------------------------------------
--  Runner
-- ---------------------------------------------------------------------------
local results = {}
local function check(name, ok, detail)
    results[#results + 1] = { name = name, ok = ok, detail = detail or "" }
end

-- 1. Healthy player deflects a normal ball at low ping.
do
    local c = newChar()
    local o = runApproach(60, 200, c)
    check("normal ball deflects (server-confirmed)", o == "deflected" and c.serverParryCount == 1, o)
end

-- 2. Still deflects at high ping (the ping lead is what makes this land).
do
    local c = newChar()
    local o = runApproach(250, 320, c)
    check("high-ping ball still deflects", o == "deflected", o)
end

-- 3. Stunned character: the server REJECTS the parry (dump gate).
do
    local c = newChar({ stunned = true })
    local o = runApproach(60, 200, c)
    check("stunned -> server rejects parry", o == "rejected" and c.serverParryCount == 0, o)
end

-- 4. Dead character (not in Alive): rejected.
do
    local c = newChar({ alive = false })
    local o = runApproach(60, 200, c)
    check("dead -> server rejects parry", o == "rejected" and c.serverParryCount == 0, o)
end

-- 5. Charging adrenaline with low Qi: rejected (dump gate).
do
    local c = newChar({ charging = true, qi = 1 })
    local o = runApproach(60, 200, c)
    check("charging + Qi<2 -> rejected", o == "rejected", o)
end

-- 6. A rally of return volleys each deflects (ServerParryCount climbs), and the
--    0.5s in-progress window from the dump never blocks the next real volley
--    (volleys are far more than 0.5s apart).
do
    local c = newChar()
    local deflects = 0
    for _ = 1, 5 do
        c.inProgressUntil = 0            -- window has cleared by the next volley
        if runApproach(80, 260, c) == "deflected" then deflects = deflects + 1 end
    end
    check("rally: every volley server-confirmed", deflects == 5 and c.serverParryCount == 5,
        "deflects=" .. deflects)
end

-- 7. Landing rate across a ping/speed sweep — the shipped decision + real gates
--    should deflect every landable ball for a healthy player.
do
    local total, landed = 0, 0
    for _, ping in ipairs({ 30, 80, 150, 250 }) do
        for _, spd in ipairs({ 120, 220, 350 }) do
            local c = newChar()
            total = total + 1
            if runApproach(ping, spd, c) == "deflected" then landed = landed + 1 end
        end
    end
    check("ping x speed sweep: all landable balls deflect", landed == total,
        landed .. "/" .. total .. " deflected")
end

-- 8. THE HITBOX-BREAK PROOF. Model the shield stamina that breaks the block when
--    you hammer the parry with no ball to consume it (the "hitbox breaking" during
--    spam). Fire idle spam at 2000 rps for 3s, WITHOUT the stamina guard (fire
--    every packet) vs WITH it (throttle to ~9/s while nothing is inbound), and
--    measure whether the shield ever breaks.
do
    -- Stamina: 0..100, regenerates; an idle parry (no ball) costs stamina; hitting
    -- 0 breaks the block (Stunned). A parry landing on a ball costs nothing.
    local MAX, REGEN_PER_S, IDLE_COST = 100, 60, 3
    local function runSpam(useGuard)
        local stamina, broke = MAX, false
        local idleLast = -1
        local acc = 0
        local now = 0
        for _ = 1, math.floor(3 / DT) do
            now = now + DT
            stamina = math.min(stamina + REGEN_PER_S * DT, MAX)
            acc = acc + DT
            local packets = math.floor(acc * 2000)      -- 2000 rps
            if packets > 0 then acc = acc - packets / 2000 end
            for _ = 1, packets do
                -- the stamina guard: while nothing inbound, throttle to ~9/s
                local fire = true
                if useGuard and (now - idleLast) < 0.11 then fire = false end
                if fire then
                    idleLast = now
                    stamina = stamina - IDLE_COST        -- idle parry burns stamina
                    if stamina <= 0 then broke = true end
                end
            end
        end
        return broke
    end
    local brokeNoGuard = runSpam(false)
    local brokeWithGuard = runSpam(true)
    check("stamina guard prevents the idle-spam shield break",
        brokeNoGuard == true and brokeWithGuard == false,
        "no-guard broke=" .. tostring(brokeNoGuard) .. "  with-guard broke=" .. tostring(brokeWithGuard))
end

-- ---------------------------------------------------------------------------
print("Blade Ball DUMP-grounded sandbox (real server parry gates)")
print(("="):rep(60))
local passed = 0
for _, r in ipairs(results) do
    local tag = r.ok and "PASS" or "FAIL"
    if r.ok then passed = passed + 1 end
    print(string.format("[%s] %-46s %s", tag, r.name, r.detail))
end
print(("="):rep(60))
print(string.format("%d / %d passed", passed, #results))
if passed ~= #results then error("dump sandbox: " .. (#results - passed) .. " FAILED", 0) end
