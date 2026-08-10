--!nocheck
--[[
============================================================================
 MM2_KnifeFarm.lua  —  Murder Mystery 2 murderer knife auto-farm
============================================================================
 Built against a full game dump of MM2 (PlaceId 129264514977232).

 How the knife kill works (from the dump's KnifeClient)
 ---------------------------------------------------------------------------
  * The knife is a Tool in your character. Its name varies (skins like
    "Beachy"), so we find it by its  KnifeServer.SlashStart  remote, not by
    the name "Knife".
      Character.<KnifeTool>.KnifeServer.SlashStart : RemoteEvent  (melee)
  * A slash is simply:
      SlashStart:FireServer()          -- NO arguments
    The SERVER does the range / hit check and kills whoever is within knife
    reach of you. So the recipe is: teleport behind a target, then slash.

 What this script does
 ---------------------------------------------------------------------------
  * Auto-farms every player as the murderer:
      teleport behind target  ->  SlashStart:FireServer()  ->  repeat
  * Switches to the next target the instant the current one dies.
  * Skips players with a blue ForceField (classic spawn protection — you
    can't kill them). They re-enter the target pool automatically once the
    shield expires.
  * Match-gated: only farms during a live round (MM2 "In Game" status), and
    resumes each new round.
  * Keeps the knife equipped and re-equips after you respawn.
  * Everything pcall-guarded; survives your own death.
  * Draggable dark "premium" GUI with on/off toggles (Enabled / Auto Farm /
    Skip Shielded). Drag it anywhere; the RightShift hotkey stays in sync.

 Requires being the murderer (you must have a knife) — a client script
 cannot assign itself the role, so if you have no knife it simply idles.

 Config is the CONFIG table below. TOGGLE_KEY enables/disables.
============================================================================
]]

-- ── Config ──────────────────────────────────────────────────────────────
local CONFIG = {
    Enabled          = true,
    TOGGLE_KEY       = Enum.KeyCode.RightShift,

    AutoFarm         = true,      -- teleport + slash on its own
    FARM_HOLD_KEY    = Enum.KeyCode.F,  -- when AutoFarm off: hold to farm

    BehindDistance   = 2.5,       -- studs behind the target to stand
    SlashInterval    = 0.55,      -- min seconds between slashes (server also gates)
    SwitchOnKill     = true,      -- retarget instantly when the target dies

    SkipForceField   = true,      -- skip players with spawn shield, return when gone
    MatchGated       = true,      -- only farm during a live round
    AutoEquipKnife   = true,      -- keep the knife out; re-equip after respawn

    ReturnAfterKill  = false,     -- teleport back to your start spot when done
}

-- ── Services ────────────────────────────────────────────────────────────
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local lp = Players.LocalPlayer

-- ── State ───────────────────────────────────────────────────────────────
local enabled     = CONFIG.Enabled
local farmHeld    = false
local lastSlash   = 0
local lastEquip   = 0
local lastStatus  = nil
local homeCFrame  = nil        -- where we were before diving in (for ReturnAfterKill)
local connections = {}
local function track(c) connections[#connections + 1] = c return c end

-- UI setters (assigned when the GUI is built) so the hotkey can sync the pills.
local setMaster, setFarm

-- ── Match state (UpdateStatus: In Game / Voting / ... ; CurrentMap fallback) ──
local function matchActive()
    if lastStatus == "In Game" then return true end
    local map = workspace:FindFirstChild("CurrentMap")
    return map ~= nil and map:FindFirstChildOfClass("Model") ~= nil
end

pcall(function()
    local ev = ReplicatedStorage:FindFirstChild("Events")
    ev = ev and ev:FindFirstChild("RemoteEvents")
    ev = ev and ev:FindFirstChild("UpdateStatus")
    if ev then
        track(ev.OnClientEvent:Connect(function(status)
            if type(status) == "string" then lastStatus = status end
        end))
    end
end)

-- ── Our knife ────────────────────────────────────────────────────────────
-- Returns: tool, SlashStart remote, isEquipped (tool is in the character).
local function findKnife()
    local char = lp.Character
    local bp   = lp:FindFirstChildOfClass("Backpack")
    for _, container in ipairs({ char, bp }) do
        if container then
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") then
                    local ks = tool:FindFirstChild("KnifeServer")
                    local slash = ks and ks:FindFirstChild("SlashStart")
                    if slash then
                        return tool, slash, tool.Parent == char
                    end
                end
            end
        end
    end
    return nil, nil, false
end

local function ensureKnifeEquipped()
    local char = lp.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not (hum and hum.Health > 0) then return end
    local tool, _, equipped = findKnife()
    if tool and not equipped then
        pcall(function() hum:EquipTool(tool) end)
    end
end

-- ── Target helpers ───────────────────────────────────────────────────────
local function rootOf(player)
    local c = player.Character
    return c and c:FindFirstChild("HumanoidRootPart"), c
end

local function isAlive(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function isShielded(char)
    return char:FindFirstChildOfClass("ForceField") ~= nil
end

-- Nearest valid target to us: alive, not self, not shielded (if configured).
local function pickTarget()
    local myRoot = select(1, rootOf(lp))
    local best, bestDist
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp then
            local root, char = rootOf(p)
            if root and isAlive(char) and not (CONFIG.SkipForceField and isShielded(char)) then
                local d = myRoot and (root.Position - myRoot.Position).Magnitude or 0
                if not bestDist or d < bestDist then
                    best, bestDist = p, d
                end
            end
        end
    end
    return best
end

-- Stand just behind the target, facing them (their back = +Z in their CFrame).
local function teleportBehind(targetRoot)
    local myRoot = select(1, rootOf(lp))
    if not (myRoot and targetRoot) then return false end
    local behind = targetRoot.CFrame * CFrame.new(0, 0, CONFIG.BehindDistance)
    myRoot.CFrame = CFrame.new(behind.Position, targetRoot.Position)
    return true
end

-- ── Main farm loop ───────────────────────────────────────────────────────
track(RunService.Heartbeat:Connect(function()
    if not enabled then return end

    -- keep the knife out (throttled)
    if CONFIG.AutoEquipKnife and os.clock() - lastEquip >= 0.25 then
        ensureKnifeEquipped()
        lastEquip = os.clock()
    end

    local wantFarm = CONFIG.AutoFarm or farmHeld
    if not wantFarm then homeCFrame = nil return end
    if CONFIG.MatchGated and not matchActive() then return end

    -- must actually have the knife equipped to deal damage
    local _, slash, equipped = findKnife()
    if not (slash and equipped) then return end

    local target = pickTarget()
    if not target then
        -- nobody killable right now (all shielded / dead) — hold position
        if CONFIG.ReturnAfterKill and homeCFrame then
            local myRoot = select(1, rootOf(lp))
            if myRoot then myRoot.CFrame = homeCFrame end
            homeCFrame = nil
        end
        return
    end

    local targetRoot = select(1, rootOf(target))
    if not targetRoot then return end

    -- remember where we came from the first time we dive in
    if CONFIG.ReturnAfterKill and not homeCFrame then
        local myRoot = select(1, rootOf(lp))
        if myRoot then homeCFrame = myRoot.CFrame end
    end

    teleportBehind(targetRoot)

    local now = os.clock()
    if now - lastSlash >= CONFIG.SlashInterval then
        pcall(function() slash:FireServer() end)
        lastSlash = now
    end
end))

-- ── GUI: draggable dark "premium" panel with on/off toggles ───────────────
-- Palette
local C = {
    bg     = Color3.fromRGB(16, 16, 22),
    bg2    = Color3.fromRGB(24, 24, 32),
    stroke = Color3.fromRGB(120, 90, 255),
    accent = Color3.fromRGB(130, 100, 255),
    off    = Color3.fromRGB(52, 52, 64),
    text   = Color3.fromRGB(236, 236, 246),
    dim    = Color3.fromRGB(168, 168, 186),
    knob   = Color3.fromRGB(244, 244, 252),
}
local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

pcall(function()
    local TweenService = game:GetService("TweenService")

    -- host the ScreenGui somewhere the game/anti-cheat won't wipe it
    local host = game:GetService("CoreGui")
    pcall(function() if gethui then host = gethui() end end)

    local gui = new("ScreenGui", {
        Name = "MM2KnifeFarmUI", ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true,
    })
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
    gui.Parent = host

    local main = new("Frame", {
        Name = "Main", Active = true,
        Size = UDim2.fromOffset(248, 168),
        Position = UDim2.fromScale(0.5, 0.42), AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = C.bg, BorderSizePixel = 0,
    }, gui)
    new("UICorner", { CornerRadius = UDim.new(0, 14) }, main)
    new("UIStroke", { Color = C.stroke, Thickness = 1.5, Transparency = 0.15 }, main)
    new("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, C.bg2),
            ColorSequenceKeypoint.new(1, C.bg),
        }),
    }, main)

    -- title bar
    local bar = new("Frame", {
        Name = "Bar", Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1,
    }, main)
    new("TextLabel", {
        Size = UDim2.new(1, -20, 1, 0), Position = UDim2.fromOffset(14, 0),
        BackgroundTransparency = 1, Text = "MM2 KNIFE FARM",
        Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = C.text,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, bar)
    new("Frame", {   -- accent underline
        Size = UDim2.new(1, -28, 0, 2), Position = UDim2.fromOffset(14, 38),
        BackgroundColor3 = C.accent, BorderSizePixel = 0,
    }, main)

    -- body with a vertical list of rows
    local body = new("Frame", {
        Size = UDim2.new(1, 0, 1, -50), Position = UDim2.fromOffset(0, 48),
        BackgroundTransparency = 1,
    }, main)
    new("UIPadding", {
        PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14),
        PaddingTop = UDim.new(0, 2),
    }, body)
    new("UIListLayout", {
        Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
    }, body)

    -- a labelled pill toggle; returns a setter set(state, fireCallback)
    local function addToggle(order, label, initial, callback)
        local row = new("Frame", {
            LayoutOrder = order, Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1,
        }, body)
        new("TextLabel", {
            Size = UDim2.new(1, -56, 1, 0), BackgroundTransparency = 1, Text = label,
            Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = C.dim,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, row)
        local pill = new("TextButton", {
            Size = UDim2.fromOffset(46, 24), Position = UDim2.new(1, -46, 0.5, -12),
            AutoButtonColor = false, Text = "",
            BackgroundColor3 = initial and C.accent or C.off,
        }, row)
        new("UICorner", { CornerRadius = UDim.new(1, 0) }, pill)
        local knob = new("Frame", {
            Size = UDim2.fromOffset(18, 18),
            Position = initial and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
            BackgroundColor3 = C.knob, BorderSizePixel = 0,
        }, pill)
        new("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)

        local state = initial
        local ti = TweenInfo.new(0.15, Enum.EasingStyle.Quad)
        local function set(s, fire)
            state = s
            TweenService:Create(pill, ti, { BackgroundColor3 = s and C.accent or C.off }):Play()
            TweenService:Create(knob, ti, {
                Position = s and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
            }):Play()
            if fire ~= false then callback(s) end
        end
        pill.MouseButton1Click:Connect(function() set(not state) end)
        return set
    end

    setMaster = addToggle(1, "Enabled",      enabled,               function(s) enabled = s end)
    setFarm   = addToggle(2, "Auto Farm",    CONFIG.AutoFarm,       function(s) CONFIG.AutoFarm = s end)
                addToggle(3, "Skip Shielded", CONFIG.SkipForceField, function(s) CONFIG.SkipForceField = s end)

    -- dragging (mouse + touch), grabbed anywhere on the panel
    local dragging, dragStart, startPos
    local function beginDrag(input)
        dragging = true; dragStart = input.Position; startPos = main.Position
    end
    main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            beginDrag(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end)

-- ── Input ───────────────────────────────────────────────────────────────
track(UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == CONFIG.TOGGLE_KEY then
        enabled = not enabled
        if setMaster then setMaster(enabled, false) end   -- keep the UI pill in sync
        warn("[MM2_KnifeFarm] " .. (enabled and "ENABLED" or "DISABLED"))
    elseif input.KeyCode == CONFIG.FARM_HOLD_KEY then
        farmHeld = true
    end
end))

track(UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == CONFIG.FARM_HOLD_KEY then farmHeld = false end
end))

-- ── Respawn: re-equip and keep farming ────────────────────────────────────
track(lp.CharacterAdded:Connect(function(char)
    homeCFrame = nil
    if CONFIG.AutoEquipKnife then
        task.spawn(function()
            char:WaitForChild("Humanoid", 10)
            for _ = 1, 40 do            -- ~4s: knife/backpack stream in late
                if not enabled then return end
                ensureKnifeEquipped()
                local _, _, equipped = findKnife()
                if equipped then return end
                task.wait(0.1)
            end
        end)
    end
end))

warn(("[MM2_KnifeFarm] loaded — toggle=%s  autoFarm=%s  skipShield=%s")
    :format(CONFIG.TOGGLE_KEY.Name, tostring(CONFIG.AutoFarm),
            tostring(CONFIG.SkipForceField)))
