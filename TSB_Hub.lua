--[[
============================================================================
 TSB_Hub.lua  —  "TSB Hub" for "The Strongest Battlegrounds" (TSB)
============================================================================
 A self-contained hub: no external UI library is loaded, so it works even
 when a CDN is down or blocked. Draggable, tabbed, RightShift to toggle.

 Game constants are shared with cpsautoblock.lua so both scripts speak to
 the same game:
   Remote        : Character.Communicate   (TSB combat RemoteEvent)
   Input actions : "KeyPress" / "KeyRelease" sent through Communicate
   Char folder   : workspace.Live
   Attack anims  : rbxassetid://10479335397 / 13380255751 / 13477540643

 Features
   Combat   : Auto Parry, Auto Counter, Auto M1 (CPS-limited), M1 After Block
   Movement : WalkSpeed, JumpPower, Infinite Jump, Noclip, Fly
   Visuals  : ESP (box + name + distance), Camlock (aim-assist)
   Misc     : Anti-AFK, Rejoin, Reset

 Everything this script creates (connections, GUI, render binds) is tracked
 and torn down by Reset, so re-running the script never stacks duplicates.
============================================================================
]]

-- ── Single-instance guard: tear down a previous run before starting ──────
if _G.TSBHub and type(_G.TSBHub.cleanup) == "function" then
    pcall(_G.TSBHub.cleanup)
end

-- ── Services ─────────────────────────────────────────────────────────────
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local TeleportService    = game:GetService("TeleportService")
local CoreGui            = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera
local LiveFolder  = workspace:WaitForChild("Live")   -- TSB character container

-- ── State ────────────────────────────────────────────────────────────────
local flags = {
    -- combat
    AutoParry     = false,
    AutoCounter   = false,
    AutoM1        = false,
    M1AfterBlock  = false,
    ParryRange    = 14,
    CounterRange  = 12,
    M1Range       = 12,
    MaxCPS        = 8,
    -- movement
    InfJump       = false,
    Noclip        = false,
    Fly           = false,
    FlySpeed      = 60,
    WalkSpeed     = 16,
    JumpPower     = 50,
    -- visuals
    ESP           = false,
    Camlock       = false,
    CamlockKey    = Enum.KeyCode.C,
    -- misc
    AntiAFK       = true,
}

-- Enemy attack animation ids that trigger a parry/counter (shared with CPS Hub).
local ATTACK_ANIMS = {
    ["10479335397"] = true, ["13380255751"] = true, ["13477540643"] = true,
}

-- ── Bookkeeping so cleanup() can tear everything down ────────────────────
local connections = {}    -- RBXScriptConnections created here
local espObjects  = {}    -- character -> { box, billboard }
local camlockBound = false
local noclipConn   = nil
local flyBodyVel, flyBodyGyro = nil, nil
local gui                       -- the ScreenGui (forward decl)
local cleanup                   -- forward decl

local function track(conn)
    connections[#connections + 1] = conn
    return conn
end

-- ── Combat: replicate inputs through the Communicate remote ──────────────
-- Non-yielding + nil-safe: safe to call every frame.
local function sendKey(action, key)
    local char = LocalPlayer.Character
    local comm = char and char:FindFirstChild("Communicate")
    if not comm then return end
    pcall(function() comm:FireServer(action, key) end)
end
local function block()   sendKey("KeyPress", "F")  end
local function unblock() sendKey("KeyRelease", "F") end
local function m1()      sendKey("KeyPress", "M1"); sendKey("KeyRelease", "M1") end
local function counter() sendKey("KeyPress", "R")  end

-- Read an enemy Animator's playing tracks for a known attack animation id.
local function enemyIsAttacking(char)
    local hum    = char:FindFirstChildOfClass("Humanoid")
    local animtr = hum and hum:FindFirstChildOfClass("Animator")
    if not animtr then return false end
    for _, tr in ipairs(animtr:GetPlayingAnimationTracks()) do
        local anim = tr.Animation
        if anim then
            local id = tostring(anim.AnimationId):match("%d+")
            if id and ATTACK_ANIMS[id] then return true end
        end
    end
    return false
end

-- ── Camlock (single render-step driver, nearest enemy) ───────────────────
local function nearestEnemyHRP()
    local best, bestDist = nil, math.huge
    local myChar = LocalPlayer.Character
    local myHrp  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local origin = myHrp and myHrp.Position or Camera.CFrame.Position
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local d = (hrp.Position - origin).Magnitude
                if d < bestDist then best, bestDist = hrp, d end
            end
        end
    end
    return best
end

local function camlockStep()
    local target = nearestEnemyHRP()
    if target then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
    end
end

local function setCamlock(on)
    flags.Camlock = on
    if on and not camlockBound then
        RunService:BindToRenderStep("TSB_Camlock",
            Enum.RenderPriority.Camera.Value + 1, camlockStep)
        camlockBound = true
    elseif not on and camlockBound then
        pcall(function() RunService:UnbindFromRenderStep("TSB_Camlock") end)
        camlockBound = false
    end
end

-- ── ESP ──────────────────────────────────────────────────────────────────
local function clearESP()
    for char, obj in pairs(espObjects) do
        pcall(function() if obj.box then obj.box:Destroy() end end)
        pcall(function() if obj.billboard then obj.billboard:Destroy() end end)
        espObjects[char] = nil
    end
end

local function makeESP(plr)
    local char = plr.Character
    if not char or espObjects[char] then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local box = Instance.new("BoxHandleAdornment")
    box.Name             = "TSB_ESP"
    box.Adornee          = hrp
    box.AlwaysOnTop      = true
    box.ZIndex           = 0
    box.Size             = Vector3.new(4, 6, 2)
    box.Transparency     = 0.55
    box.Color3           = Color3.fromRGB(255, 60, 60)
    box.Parent           = hrp

    local bb = Instance.new("BillboardGui")
    bb.Name            = "TSB_ESP_Tag"
    bb.Adornee         = hrp
    bb.Size            = UDim2.fromOffset(200, 22)
    bb.StudsOffset     = Vector3.new(0, 3.2, 0)
    bb.AlwaysOnTop     = true
    bb.Parent          = hrp

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size                   = UDim2.fromScale(1, 1)
    label.Font                   = Enum.Font.GothamBold
    label.TextSize               = 14
    label.TextColor3             = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0.4
    label.Text                   = plr.Name
    label.Parent                 = bb

    espObjects[char] = { box = box, billboard = bb, label = label, plr = plr }
end

-- ── Movement mods ────────────────────────────────────────────────────────
local function applyMovement(hum)
    if not hum then return end
    hum.WalkSpeed    = flags.WalkSpeed
    hum.UseJumpPower = true
    hum.JumpPower    = flags.JumpPower
end

-- Fly: BodyVelocity/BodyGyro driven from camera look + WASD.
local function stopFly()
    if flyBodyVel  then pcall(function() flyBodyVel:Destroy()  end) flyBodyVel  = nil end
    if flyBodyGyro then pcall(function() flyBodyGyro:Destroy() end) flyBodyGyro = nil end
end

local function setFly(on)
    flags.Fly = on
    if not on then stopFly() return end
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then flags.Fly = false return end
    stopFly()
    flyBodyVel = Instance.new("BodyVelocity")
    flyBodyVel.MaxForce = Vector3.new(1, 1, 1) * 9e9
    flyBodyVel.Velocity = Vector3.zero
    flyBodyVel.Parent   = hrp
    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.MaxForce = Vector3.new(1, 1, 1) * 9e9
    flyBodyGyro.P        = 9e4
    flyBodyGyro.CFrame   = hrp.CFrame
    flyBodyGyro.Parent   = hrp
end

local function flyStep()
    if not flags.Fly or not flyBodyVel or not flyBodyGyro then return end
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local move = Vector3.zero
    local look = Camera.CFrame
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += look.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= look.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= look.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += look.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space)      then move += Vector3.yAxis end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.yAxis end
    flyBodyVel.Velocity = (move.Magnitude > 0 and move.Unit or Vector3.zero) * flags.FlySpeed
    flyBodyGyro.CFrame  = look
end

local function setNoclip(on)
    flags.Noclip = on
    if on and not noclipConn then
        noclipConn = track(RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
                end
            end
        end))
    elseif not on and noclipConn then
        pcall(function() noclipConn:Disconnect() end)
        noclipConn = nil
    end
end

-- ── cleanup() ────────────────────────────────────────────────────────────
function cleanup()
    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    connections = {}
    setCamlock(false)
    setNoclip(false)
    setFly(false)
    clearESP()
    pcall(function() RunService:UnbindFromRenderStep("TSB_Fly") end)
    if gui then pcall(function() gui:Destroy() end) end
    _G.TSBHub = nil
end
_G.TSBHub = { cleanup = cleanup, flags = flags }

-- ══════════════════════════════════════════════════════════════════════════
--  Loops
-- ══════════════════════════════════════════════════════════════════════════

-- Combat loop (Heartbeat).
local lastClick = 0
track(RunService.Heartbeat:Connect(function()
    local char  = LocalPlayer.Character
    local hum   = char and char:FindFirstChildOfClass("Humanoid")
    local myHrp = char and char:FindFirstChild("HumanoidRootPart")
    applyMovement(hum)

    if not myHrp then return end
    if not (flags.AutoParry or flags.AutoCounter or flags.AutoM1) then return end

    for _, enemy in ipairs(LiveFolder:GetChildren()) do
        if enemy ~= char then
            local hrp = enemy:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist      = (hrp.Position - myHrp.Position).Magnitude
                local attacking = nil   -- computed at most once per enemy per frame

                -- Counter takes priority over parry (elseif => never same frame).
                if flags.AutoCounter and dist <= flags.CounterRange then
                    if attacking == nil then attacking = enemyIsAttacking(enemy) end
                    if attacking then counter() end
                elseif flags.AutoParry and dist <= flags.ParryRange then
                    if attacking == nil then attacking = enemyIsAttacking(enemy) end
                    if attacking then
                        block()
                        if flags.M1AfterBlock then unblock(); m1() end
                    end
                end

                if flags.AutoM1 and dist <= flags.M1Range then
                    if tick() - lastClick >= 1 / flags.MaxCPS then
                        lastClick = tick(); m1()
                    end
                end
            end
        end
    end
end))

-- ESP loop (Heartbeat).
track(RunService.Heartbeat:Connect(function()
    if not flags.ESP then
        if next(espObjects) then clearESP() end
        return
    end
    -- Reap dead/removed characters.
    for char, obj in pairs(espObjects) do
        if not char:IsDescendantOf(workspace)
           or not char:FindFirstChild("HumanoidRootPart") then
            pcall(function() if obj.box then obj.box:Destroy() end end)
            pcall(function() if obj.billboard then obj.billboard:Destroy() end end)
            espObjects[char] = nil
        end
    end
    local myChar = LocalPlayer.Character
    local myHrp  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            makeESP(plr)
            local obj = espObjects[plr.Character]
            if obj and obj.label and myHrp then
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                local d = hrp and math.floor((hrp.Position - myHrp.Position).Magnitude) or 0
                obj.label.Text = string.format("%s  [%dm]", plr.Name, d)
            end
        end
    end
end))

-- Fly render loop (always bound; no-ops when Fly is off).
RunService:BindToRenderStep("TSB_Fly", Enum.RenderPriority.Camera.Value + 2, flyStep)

-- Infinite jump.
track(UserInputService.JumpRequest:Connect(function()
    if not flags.InfJump then return end
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end))

-- Camlock keybind (single source of truth).
track(UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.Keyboard
       and input.KeyCode == flags.CamlockKey then
        setCamlock(not flags.Camlock)
    end
end))

-- Anti-AFK: defeat the 20-minute idle kick.
track(LocalPlayer.Idled:Connect(function()
    if not flags.AntiAFK then return end
    local vu = game:GetService("VirtualUser")
    pcall(function()
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
    end)
end))

-- Re-apply movement mods & fly on respawn.
track(LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 10)
    applyMovement(hum)
    if flags.Fly then task.wait(0.5); setFly(true) end
end))

-- Reap ESP for leaving players.
track(Players.PlayerRemoving:Connect(function(plr)
    if plr.Character and espObjects[plr.Character] then
        local obj = espObjects[plr.Character]
        pcall(function() if obj.box then obj.box:Destroy() end end)
        pcall(function() if obj.billboard then obj.billboard:Destroy() end end)
        espObjects[plr.Character] = nil
    end
end))

-- ══════════════════════════════════════════════════════════════════════════
--  UI  (self-contained, draggable, tabbed)
-- ══════════════════════════════════════════════════════════════════════════

local C = {
    bg     = Color3.fromRGB(14, 13, 20),
    panel  = Color3.fromRGB(20, 18, 30),
    bar    = Color3.fromRGB(26, 22, 44),
    row    = Color3.fromRGB(28, 25, 42),
    accent = Color3.fromRGB(225, 70, 70),
    on     = Color3.fromRGB(210, 55, 55),
    off    = Color3.fromRGB(52, 48, 64),
    text   = Color3.fromRGB(222, 218, 235),
    dim    = Color3.fromRGB(150, 145, 170),
}

local function corner(inst, r)
    local u = Instance.new("UICorner"); u.CornerRadius = UDim.new(0, r or 8); u.Parent = inst; return u
end

gui = Instance.new("ScreenGui")
gui.Name             = "TSBHub"
gui.ResetOnSpawn     = false
gui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset   = true
-- Prefer CoreGui; fall back to PlayerGui if the executor blocks it.
local okParent = pcall(function() gui.Parent = CoreGui end)
if not okParent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local win = Instance.new("Frame")
win.Size             = UDim2.fromOffset(420, 330)
win.Position         = UDim2.fromOffset(60, 90)
win.BackgroundColor3 = C.bg
win.BorderSizePixel  = 0
win.Parent           = gui
corner(win, 12)
do
    local s = Instance.new("UIStroke", win)
    s.Color = C.accent; s.Transparency = 0.5; s.Thickness = 1.2
end

-- Title bar (drag handle).
local bar = Instance.new("Frame")
bar.Size             = UDim2.new(1, 0, 0, 40)
bar.BackgroundColor3 = C.bar
bar.BorderSizePixel  = 0
bar.Parent           = win
corner(bar, 12)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position               = UDim2.fromOffset(14, 0)
title.Size                   = UDim2.new(1, -90, 1, 0)
title.Font                   = Enum.Font.GothamBold
title.TextSize               = 16
title.TextColor3             = C.text
title.TextXAlignment         = Enum.TextXAlignment.Left
title.Text                   = "TSB Hub"
title.Parent                 = bar

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Position               = UDim2.fromOffset(14, 20)
subtitle.Size                   = UDim2.new(1, -90, 0, 14)
subtitle.Font                   = Enum.Font.Gotham
subtitle.TextSize               = 11
subtitle.TextColor3             = C.dim
subtitle.TextXAlignment         = Enum.TextXAlignment.Left
subtitle.Text                   = "The Strongest Battlegrounds  ·  RightShift to toggle"
subtitle.Parent                 = bar
title.Position = UDim2.fromOffset(14, 4)

-- Close/minimize button.
local closeBtn = Instance.new("TextButton")
closeBtn.Size             = UDim2.fromOffset(28, 28)
closeBtn.Position         = UDim2.new(1, -36, 0, 6)
closeBtn.BackgroundColor3 = C.accent
closeBtn.Text             = "✕"
closeBtn.Font             = Enum.Font.GothamBold
closeBtn.TextSize         = 14
closeBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
closeBtn.Parent           = bar
corner(closeBtn, 8)

-- Tab strip.
local tabStrip = Instance.new("Frame")
tabStrip.Position         = UDim2.fromOffset(10, 48)
tabStrip.Size             = UDim2.new(1, -20, 0, 30)
tabStrip.BackgroundTransparency = 1
tabStrip.Parent           = win
do
    local l = Instance.new("UIListLayout", tabStrip)
    l.FillDirection = Enum.FillDirection.Horizontal
    l.Padding       = UDim.new(0, 6)
end

-- Page container.
local pages = Instance.new("Frame")
pages.Position         = UDim2.fromOffset(10, 84)
pages.Size             = UDim2.new(1, -20, 1, -94)
pages.BackgroundTransparency = 1
pages.Parent           = win

local tabButtons = {}
local pageFrames = {}

local function selectTab(name)
    for n, pg in pairs(pageFrames) do pg.Visible = (n == name) end
    for n, btn in pairs(tabButtons) do
        btn.BackgroundColor3 = (n == name) and C.accent or C.off
    end
end

local function addTab(name)
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.fromOffset(96, 30)
    btn.BackgroundColor3 = C.off
    btn.Text             = name
    btn.Font             = Enum.Font.GothamSemibold
    btn.TextSize         = 13
    btn.TextColor3       = C.text
    btn.Parent           = tabStrip
    corner(btn, 7)
    tabButtons[name] = btn

    local pg = Instance.new("ScrollingFrame")
    pg.Size                  = UDim2.fromScale(1, 1)
    pg.BackgroundTransparency = 1
    pg.BorderSizePixel       = 0
    pg.ScrollBarThickness    = 3
    pg.CanvasSize            = UDim2.new()
    pg.AutomaticCanvasSize   = Enum.AutomaticSize.Y
    pg.Visible               = false
    pg.Parent                = pages
    local l = Instance.new("UIListLayout", pg)
    l.Padding = UDim.new(0, 6)
    pageFrames[name] = pg

    btn.MouseButton1Click:Connect(function() selectTab(name) end)
    return pg
end

-- Row factory: a rounded panel that holds one control.
local function row(parent, h)
    local f = Instance.new("Frame")
    f.Size             = UDim2.new(1, -6, 0, h or 34)
    f.BackgroundColor3 = C.row
    f.BorderSizePixel  = 0
    f.Parent           = parent
    corner(f, 7)
    return f
end

local function addToggle(parent, label, key, cb)
    local f = row(parent)
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Position               = UDim2.fromOffset(12, 0)
    t.Size                   = UDim2.new(1, -70, 1, 0)
    t.Font                   = Enum.Font.Gotham
    t.TextSize               = 13
    t.TextColor3             = C.text
    t.TextXAlignment         = Enum.TextXAlignment.Left
    t.Text                   = label
    t.Parent                 = f

    local sw = Instance.new("TextButton")
    sw.Size             = UDim2.fromOffset(44, 22)
    sw.Position         = UDim2.new(1, -54, 0.5, -11)
    sw.BackgroundColor3 = flags[key] and C.on or C.off
    sw.Text             = ""
    sw.AutoButtonColor  = false
    sw.Parent           = f
    corner(sw, 11)
    local knob = Instance.new("Frame")
    knob.Size             = UDim2.fromOffset(18, 18)
    knob.Position         = flags[key] and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
    knob.BackgroundColor3 = Color3.fromRGB(240, 240, 245)
    knob.BorderSizePixel  = 0
    knob.Parent           = sw
    corner(knob, 9)

    local function render()
        local on = flags[key]
        TweenService:Create(sw, TweenInfo.new(0.15), {
            BackgroundColor3 = on and C.on or C.off }):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = on and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9) }):Play()
    end
    sw.MouseButton1Click:Connect(function()
        flags[key] = not flags[key]
        render()
        if cb then cb(flags[key]) end
    end)
    return f
end

local function addSlider(parent, label, key, min, max, step)
    local f = row(parent, 44)
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Position               = UDim2.fromOffset(12, 4)
    t.Size                   = UDim2.new(1, -24, 0, 16)
    t.Font                   = Enum.Font.Gotham
    t.TextSize               = 13
    t.TextColor3             = C.text
    t.TextXAlignment         = Enum.TextXAlignment.Left
    t.Text                   = label .. ": " .. tostring(flags[key])
    t.Parent                 = f

    local track_ = Instance.new("Frame")
    track_.Position         = UDim2.fromOffset(12, 26)
    track_.Size             = UDim2.new(1, -24, 0, 8)
    track_.BackgroundColor3 = C.off
    track_.BorderSizePixel  = 0
    track_.Parent           = f
    corner(track_, 4)

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = C.accent
    fill.BorderSizePixel  = 0
    fill.Size             = UDim2.fromScale((flags[key] - min) / (max - min), 1)
    fill.Parent           = track_
    corner(fill, 4)

    local dragging = false
    local function setFromX(px)
        local rel = math.clamp((px - track_.AbsolutePosition.X) / track_.AbsoluteSize.X, 0, 1)
        local val = min + rel * (max - min)
        if step then val = math.floor(val / step + 0.5) * step end
        val = math.clamp(val, min, max)
        flags[key] = val
        fill.Size  = UDim2.fromScale((val - min) / (max - min), 1)
        t.Text     = label .. ": " .. tostring(val)
    end
    track_.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
           or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; setFromX(i.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
           or i.UserInputType == Enum.UserInputType.Touch) then
            setFromX(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
           or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    return f
end

local function addButton(parent, label, cb)
    local f = row(parent)
    local b = Instance.new("TextButton")
    b.BackgroundTransparency = 1
    b.Size                   = UDim2.fromScale(1, 1)
    b.Font                   = Enum.Font.GothamSemibold
    b.TextSize               = 13
    b.TextColor3             = C.accent
    b.Text                   = label
    b.Parent                 = f
    b.MouseButton1Click:Connect(function() if cb then cb() end end)
    return f
end

-- ── Build tabs ───────────────────────────────────────────────────────────
local combatPage = addTab("Combat")
addToggle(combatPage, "Auto Parry",      "AutoParry")
addToggle(combatPage, "Auto Counter",    "AutoCounter")
addToggle(combatPage, "Auto M1",         "AutoM1")
addToggle(combatPage, "M1 After Block",  "M1AfterBlock")
addSlider(combatPage, "Parry Range",     "ParryRange",   0, 50)
addSlider(combatPage, "Counter Range",   "CounterRange", 0, 50)
addSlider(combatPage, "M1 Range",        "M1Range",      0, 50)
addSlider(combatPage, "Max CPS",         "MaxCPS",       1, 30)

local movePage = addTab("Movement")
addToggle(movePage, "Infinite Jump", "InfJump")
addToggle(movePage, "Noclip",        "Noclip", setNoclip)
addToggle(movePage, "Fly",           "Fly",    setFly)
addSlider(movePage, "Fly Speed",     "FlySpeed",  16, 250)
addSlider(movePage, "Walk Speed",    "WalkSpeed", 16, 250)
addSlider(movePage, "Jump Power",    "JumpPower", 50, 400)

local visualPage = addTab("Visuals")
addToggle(visualPage, "ESP",     "ESP")
addToggle(visualPage, "Camlock", "Camlock", setCamlock)

local miscPage = addTab("Misc")
addToggle(miscPage, "Anti-AFK", "AntiAFK")
addButton(miscPage, "Rejoin Server", function()
    pcall(function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
end)
addButton(miscPage, "Refresh Character", function()
    local c = LocalPlayer.Character
    if c then pcall(function() c:BreakJoints() end) end
    task.wait()
    pcall(function() LocalPlayer:LoadCharacter() end)
end)
addButton(miscPage, "Reset / Unload Hub", function() cleanup() end)

selectTab("Combat")

-- ── Window controls: drag + toggle visibility ────────────────────────────
do
    local dragging, dragStart, startPos = false, nil, nil
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
           or i.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = i.Position
            startPos  = win.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
           or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            win.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
           or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

closeBtn.MouseButton1Click:Connect(function() win.Visible = false end)

track(UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        win.Visible = not win.Visible
    end
end))

-- ── Startup ──────────────────────────────────────────────────────────────
if flags.WalkSpeed ~= 16 or flags.JumpPower ~= 50 then
    applyMovement(LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"))
end
