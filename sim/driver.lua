
-- ============================================================================
-- DRIVER — runs after the hub script has loaded. Exercises every registered
-- control (toggles on/off, buttons, dropdowns, inputs, keybinds), fires
-- simulated animation / attribute / respawn events, steps the scheduler, and
-- prints any runtime errors that surfaced.
-- ============================================================================
local SIM = _G.__SIM
print(("[driver] hub loaded OK — %d controls registered"):format(#SIM.controls))

local RunService = SIM.RunService

local function mkTrack(id, tp)
    local a = Instance.new("Animation"); a.AnimationId = "rbxassetid://" .. id
    local tr = Instance.new("AnimationTrack")
    tr._props.Animation = a; tr._props.Name = "anim_" .. id
    tr._props.TimePosition = tp or 0.9; tr._props.Length = 1.0; tr._props.IsPlaying = true
    return tr
end

-- animations various detectors look for
local IDS = { "10503381238","12296113986","10479335397","13379003796","10503381238",
    "12273188754","10469643643","10469639222","10503381238","11365563255","10471336737",
    "12447705141","12309835105","10480793962" }

local function setTracks(hum)
    local t = {}
    for _, id in ipairs(IDS) do table.insert(t, mkTrack(id, 0.95)) end
    hum._props._tracks = t
    local an = hum:FindFirstChildOfClass("Animator")
    if an then an._props._tracks = t end
    return t
end

local function fireAnimEvents()
    local hum = SIM.LocalPlayer.Character and SIM.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local tracks = setTracks(hum)
    local an = hum:FindFirstChildOfClass("Animator")
    for _, tr in ipairs(tracks) do
        hum.AnimationPlayed:Fire(tr)
        if an then an.AnimationPlayed:Fire(tr) end
    end
    hum.Running:Fire(12)
    -- attribute-driven paths (Effects presets, reflex combo)
    local ch = SIM.LocalPlayer.Character
    if ch then
        ch:SetAttribute("Combo", 5); ch:SetAttribute("LastM1Hitted", "Enemy;1")
        ch:SetAttribute("Combo", 4)
    end
    local liveChar = SIM.live:FindFirstChild("You")
    if liveChar then liveChar:SetAttribute("Combo", 4) end
end

local function frames(n)
    for _ = 1, (n or 12) do
        SIM.step(1/60)
        RunService.Heartbeat:Fire(1/60)
        RunService.RenderStepped:Fire(1/60)
    end
end

local function exercise(c)
    SIM.label = ("%s '%s'"):format(c.kind, tostring(c.title))
    local cb = c.cfg.Callback
    if c.kind == "Toggle" then
        if cb then SIM.spawn(SIM.label, cb, true) end
        fireAnimEvents(); frames(10)
        if cb then SIM.spawn(SIM.label, cb, false) end
        frames(4)
    elseif c.kind == "Button" or c.kind == "Keybind" then
        if cb then SIM.spawn(SIM.label, cb) end
        fireAnimEvents(); frames(6)
    elseif c.kind == "Dropdown" then
        local vals = c.cfg.Values or { c.cfg.Value }
        for _, v in ipairs(vals) do            -- every value (Gojo/Killua/Itadori/Fire, presets, teleports)
            if cb then SIM.spawn(SIM.label, cb, v) end
            fireAnimEvents(); frames(5)
        end
    elseif c.kind == "Input" then
        if cb then SIM.spawn(SIM.label, cb, "15") end
        frames(2)
    end
end

-- 1) exercise everything once
for _, c in ipairs(SIM.controls) do exercise(c) end

-- 2) simulate a respawn, then re-exercise the toggles (respawn re-hook paths)
SIM.label = "RESPAWN"
local lp = SIM.LocalPlayer
if lp.CharacterRemoving then lp.CharacterRemoving:Fire(lp.Character) end
local newChar, newHum, newHRP = SIM.makeChar("You")
newChar.Parent = SIM.live
lp._props.Character = newChar
lp.CharacterAdded:Fire(newChar)
frames(20)               -- let task.wait(0.x) respawn handlers run
fireAnimEvents(); frames(20)

SIM.label = "POST-RESPAWN toggles"
for _, c in ipairs(SIM.controls) do
    if c.kind == "Toggle" and c.cfg.Callback then
        SIM.spawn(SIM.label .. " '" .. tostring(c.title) .. "'", c.cfg.Callback, true)
        fireAnimEvents(); frames(8)
    end
end
frames(30)

-- 2b) nil-safety: yank the character while loops are live, then recover
SIM.label = "NO-CHARACTER"
for _, c in ipairs(SIM.controls) do
    if c.kind == "Toggle" and c.cfg.Callback then SIM.spawn(SIM.label, c.cfg.Callback, true) end
end
frames(6)
lp._props.Character = nil
fireAnimEvents(); frames(25)          -- live RenderStepped/Heartbeat handlers run with no character
local rc = SIM.makeChar("You"); rc.Parent = SIM.live; lp._props.Character = rc
lp.CharacterAdded:Fire(rc); frames(15)

-- 3) report
print("\n==================== SIM RESULT ====================")
print(("controls exercised: %d   |   runtime errors: %d"):format(#SIM.controls, #SIM.errors))
local seen, uniq = {}, {}
for _, e in ipairs(SIM.errors) do
    local key = (e.label or "?") .. " :: " .. e.err
    if not seen[key] then seen[key] = true; table.insert(uniq, e) end
end
print(("unique errors: %d"):format(#uniq))
for i, e in ipairs(uniq) do
    print(("[%d] (%s) [%s]\n     %s"):format(i, e.label or "?", e.ctx or "?", e.err))
end
print("===================================================")
