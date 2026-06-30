-- ╔══════════════════════════════════════════════════════╗
-- ║         FNF HUB  —  Universal Funky Friday          ║
-- ║   AutoPlay · NoMiss · SpeedHack · BotScore          ║
-- ╚══════════════════════════════════════════════════════╝

local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService  = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService   = game:GetService("HttpService")
local StarterGui    = game:GetService("StarterGui")

local LP  = Players.LocalPlayer
local Cam = workspace.CurrentCamera

-- ── Config ────────────────────────────────────────────────────────────────────
local CFG = {
    AutoPlay       = false,
    NoMiss         = false,
    BotScore       = false,
    SpeedHack      = false,
    SpeedValue     = 1.5,
    ShowNoteBoxes  = false,
    AntiAfk        = true,
    Notifications  = true,
}

-- ── Theme (null-fire colour palette) ─────────────────────────────────────────
local T = {
    BG       = Color3.fromRGB(12, 12, 20),
    Panel    = Color3.fromRGB(18, 18, 30),
    Accent   = Color3.fromRGB(220, 80, 255),   -- purple
    AccentB  = Color3.fromRGB(100, 220, 255),  -- cyan
    Text     = Color3.fromRGB(240, 240, 255),
    SubText  = Color3.fromRGB(140, 140, 180),
    Green    = Color3.fromRGB(80, 255, 140),
    Red      = Color3.fromRGB(255, 80, 100),
    Border   = Color3.fromRGB(50, 50, 80),
    Btn      = Color3.fromRGB(28, 28, 46),
    BtnHov   = Color3.fromRGB(40, 40, 64),
}

-- ── Notify helper (mirrors null-fire SetCore pattern) ─────────────────────────
local function Notify(title, text, dur)
    if not CFG.Notifications then return end
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title    = title or "FNF Hub",
            Text     = text  or "",
            Duration = dur   or 4,
        })
    end)
end

-- ── GUI builder helpers ───────────────────────────────────────────────────────
local function New(cls, props, children)
    local o = Instance.new(cls)
    for k, v in pairs(props or {}) do o[k] = v end
    for _, c in ipairs(children or {}) do c.Parent = o end
    return o
end

local function Corner(r, parent)
    return New("UICorner", {CornerRadius = UDim.new(0, r), Parent = parent})
end

local function Stroke(t, c, parent)
    return New("UIStroke", {Thickness = t, Color = c, Parent = parent})
end

local function Tween(obj, info, props)
    TweenService:Create(obj, info, props):Play()
end

local FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad)
local MED  = TweenInfo.new(0.3,  Enum.EasingStyle.Quad)

-- ── Build ScreenGui ───────────────────────────────────────────────────────────
pcall(function() LP.PlayerGui:FindFirstChild("FNF_Hub"):Destroy() end)

local SG = New("ScreenGui", {
    Name            = "FNF_Hub",
    ResetOnSpawn    = false,
    ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset  = true,
    Parent          = (gethui and gethui()) or LP.PlayerGui,
})

-- Main window
local WIN = New("Frame", {
    Name            = "Window",
    Size            = UDim2.new(0, 360, 0, 480),
    Position        = UDim2.new(0.5, -180, 0.5, -240),
    BackgroundColor3= T.BG,
    BorderSizePixel = 0,
    Parent          = SG,
})
Corner(10, WIN)
Stroke(1.5, T.Border, WIN)

-- Gradient overlay on window
New("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(30, 10, 50)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(5,  5,  18)),
    }),
    Rotation = 135,
    Parent = WIN,
})

-- Title bar
local TITLEBAR = New("Frame", {
    Size            = UDim2.new(1, 0, 0, 46),
    BackgroundColor3= T.Panel,
    BorderSizePixel = 0,
    Parent          = WIN,
})
Corner(10, TITLEBAR)
New("Frame", {
    Size            = UDim2.new(1, 0, 0.5, 0),
    Position        = UDim2.new(0, 0, 0.5, 0),
    BackgroundColor3= T.Panel,
    BorderSizePixel = 0,
    Parent          = TITLEBAR,
})

-- Title gradient accent line
New("Frame", {
    Size            = UDim2.new(1, 0, 0, 2),
    Position        = UDim2.new(0, 0, 1, -2),
    BackgroundColor3= T.Accent,
    BorderSizePixel = 0,
    Parent          = TITLEBAR,
    ["UIGradient"] = nil,
})
do
    local ln = New("Frame", {
        Size            = UDim2.new(1, 0, 0, 2),
        Position        = UDim2.new(0, 0, 1, -2),
        BackgroundColor3= T.Accent,
        BorderSizePixel = 0,
        Parent          = TITLEBAR,
    })
    New("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,   T.Accent),
            ColorSequenceKeypoint.new(0.5, T.AccentB),
            ColorSequenceKeypoint.new(1,   T.Accent),
        }),
        Parent = ln,
    })
end

-- Title icon + text
New("TextLabel", {
    Size            = UDim2.new(1, -110, 1, 0),
    Position        = UDim2.new(0, 14, 0, 0),
    BackgroundTransparency = 1,
    Text            = "🎵  FNF HUB",
    TextColor3      = T.Text,
    Font            = Enum.Font.GothamBold,
    TextSize        = 16,
    TextXAlignment  = Enum.TextXAlignment.Left,
    Parent          = TITLEBAR,
})

-- Version label
New("TextLabel", {
    Size            = UDim2.new(0, 80, 1, 0),
    Position        = UDim2.new(1, -94, 0, 0),
    BackgroundTransparency = 1,
    Text            = "v2.0",
    TextColor3      = T.Accent,
    Font            = Enum.Font.GothamBold,
    TextSize        = 12,
    TextXAlignment  = Enum.TextXAlignment.Right,
    Parent          = TITLEBAR,
})

-- Close button
local CLOSE = New("TextButton", {
    Size            = UDim2.new(0, 28, 0, 28),
    Position        = UDim2.new(1, -36, 0.5, -14),
    BackgroundColor3= Color3.fromRGB(255, 60, 80),
    Text            = "×",
    TextColor3      = Color3.fromRGB(255, 255, 255),
    Font            = Enum.Font.GothamBold,
    TextSize        = 18,
    BorderSizePixel = 0,
    Parent          = TITLEBAR,
})
Corner(6, CLOSE)

CLOSE.MouseButton1Click:Connect(function()
    Tween(WIN, MED, {Size = UDim2.new(0, 360, 0, 0)})
    task.wait(0.3)
    SG:Destroy()
end)

-- Minimise button
local MINI = New("TextButton", {
    Size            = UDim2.new(0, 28, 0, 28),
    Position        = UDim2.new(1, -70, 0.5, -14),
    BackgroundColor3= Color3.fromRGB(255, 180, 30),
    Text            = "–",
    TextColor3      = Color3.fromRGB(255, 255, 255),
    Font            = Enum.Font.GothamBold,
    TextSize        = 18,
    BorderSizePixel = 0,
    Parent          = TITLEBAR,
})
Corner(6, MINI)
local minimised = false
MINI.MouseButton1Click:Connect(function()
    minimised = not minimised
    Tween(WIN, MED, {
        Size = minimised and UDim2.new(0, 360, 0, 46) or UDim2.new(0, 360, 0, 480)
    })
end)

-- Drag
do
    local dragging, dragStart, startPos
    TITLEBAR.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or
           i.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = i.Position
            startPos  = WIN.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement or
           i.UserInputType == Enum.UserInputType.Touch then
            local delta = i.Position - dragStart
            WIN.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or
           i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ── Content area ──────────────────────────────────────────────────────────────
local CONTENT = New("Frame", {
    Size            = UDim2.new(1, -16, 1, -62),
    Position        = UDim2.new(0, 8, 0, 54),
    BackgroundTransparency = 1,
    Parent          = WIN,
})

New("UIListLayout", {
    Padding         = UDim.new(0, 6),
    FillDirection   = Enum.FillDirection.Vertical,
    SortOrder       = Enum.SortOrder.LayoutOrder,
    Parent          = CONTENT,
})

-- ── Toggle builder ────────────────────────────────────────────────────────────
local function Toggle(label, desc, key, callback, order)
    local ROW = New("Frame", {
        Size            = UDim2.new(1, 0, 0, 54),
        BackgroundColor3= T.Btn,
        BorderSizePixel = 0,
        LayoutOrder     = order or 0,
        Parent          = CONTENT,
    })
    Corner(8, ROW)
    Stroke(1, T.Border, ROW)

    New("TextLabel", {
        Size            = UDim2.new(1, -70, 0, 24),
        Position        = UDim2.new(0, 14, 0, 6),
        BackgroundTransparency = 1,
        Text            = label,
        TextColor3      = T.Text,
        Font            = Enum.Font.GothamBold,
        TextSize        = 13,
        TextXAlignment  = Enum.TextXAlignment.Left,
        Parent          = ROW,
    })
    New("TextLabel", {
        Size            = UDim2.new(1, -70, 0, 20),
        Position        = UDim2.new(0, 14, 0, 28),
        BackgroundTransparency = 1,
        Text            = desc,
        TextColor3      = T.SubText,
        Font            = Enum.Font.Gotham,
        TextSize        = 11,
        TextXAlignment  = Enum.TextXAlignment.Left,
        Parent          = ROW,
    })

    local BTN = New("TextButton", {
        Size            = UDim2.new(0, 50, 0, 26),
        Position        = UDim2.new(1, -60, 0.5, -13),
        BackgroundColor3= T.Red,
        Text            = "OFF",
        TextColor3      = T.Text,
        Font            = Enum.Font.GothamBold,
        TextSize        = 11,
        BorderSizePixel = 0,
        Parent          = ROW,
    })
    Corner(6, BTN)

    local function refresh()
        local on = CFG[key]
        Tween(BTN, FAST, {BackgroundColor3 = on and T.Green or T.Red})
        BTN.Text = on and "ON" or "OFF"
    end

    BTN.MouseButton1Click:Connect(function()
        CFG[key] = not CFG[key]
        refresh()
        if callback then callback(CFG[key]) end
        Notify("FNF Hub", label .. " → " .. (CFG[key] and "ON" or "OFF"))
    end)

    ROW.MouseEnter:Connect(function() Tween(ROW, FAST, {BackgroundColor3 = T.BtnHov}) end)
    ROW.MouseLeave:Connect(function() Tween(ROW, FAST, {BackgroundColor3 = T.Btn}) end)

    refresh()
    return ROW
end

-- ── Status bar ────────────────────────────────────────────────────────────────
local STATUSBAR = New("Frame", {
    Size            = UDim2.new(1, 0, 0, 26),
    BackgroundColor3= T.Panel,
    BorderSizePixel = 0,
    LayoutOrder     = 99,
    Parent          = CONTENT,
})
Corner(6, STATUSBAR)

local STATUS_LBL = New("TextLabel", {
    Size            = UDim2.new(1, -10, 1, 0),
    Position        = UDim2.new(0, 10, 0, 0),
    BackgroundTransparency = 1,
    Text            = "● Idle — waiting for song to start",
    TextColor3      = T.SubText,
    Font            = Enum.Font.Gotham,
    TextSize        = 11,
    TextXAlignment  = Enum.TextXAlignment.Left,
    Parent          = STATUSBAR,
})

local function SetStatus(txt, col)
    STATUS_LBL.Text       = "● " .. txt
    STATUS_LBL.TextColor3 = col or T.SubText
end

-- ── Toggles ───────────────────────────────────────────────────────────────────
Toggle("AutoPlay / Bot",      "Hits every note perfectly with no misses",   "AutoPlay",      nil, 1)
Toggle("No Miss",             "Cancels miss penalties, keeps combo alive",  "NoMiss",        nil, 2)
Toggle("BotScore",            "Maximises score on every note hit",          "BotScore",      nil, 3)
Toggle("Speed Hack (1.5×)",   "Plays at 1.5× song speed — looks legit",     "SpeedHack",     nil, 4)
Toggle("Show Note Hitboxes",  "Draws boxes around incoming notes",          "ShowNoteBoxes", nil, 5)
Toggle("Anti-AFK",            "Moves camera so you don't get kicked",       "AntiAfk",       nil, 6)

-- ── Core logic ────────────────────────────────────────────────────────────────
-- Find the game's note remote (works across most FNF Roblox ports)
local function FindRemote(name)
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name:lower():find(name:lower()) then
            return v
        end
    end
    return nil
end

-- Find active note objects in workspace
local function GetNotes()
    local notes = {}
    for _, v in pairs(workspace:GetDescendants()) do
        if (v.Name == "Note" or v.Name:lower():find("note"))
            and v:IsA("BasePart") and v.Transparency < 0.9 then
            notes[#notes + 1] = v
        end
    end
    return notes
end

-- Detect which FNF game variant we're in
local gameType = "unknown"
pcall(function()
    if workspace:FindFirstChild("Song") or ReplicatedStorage:FindFirstChild("SongData") then
        gameType = "FunkyFriday"
    elseif workspace:FindFirstChild("FNF") then
        gameType = "FNFPort"
    end
end)

-- Note hit remote cache
local NoteHitRemote = nil
local MissRemote    = nil
task.spawn(function()
    task.wait(2)
    NoteHitRemote = FindRemote("NoteHit") or FindRemote("Hit") or FindRemote("Note")
    MissRemote    = FindRemote("Miss") or FindRemote("Penalty")
    if NoteHitRemote then
        SetStatus("Remote found: " .. NoteHitRemote.Name, T.Green)
    else
        SetStatus("Waiting for remote...", T.AccentB)
    end
end)

-- ── AutoPlay core (Funky Friday-compatible) ───────────────────────────────────
-- Hook note spawner via workspace.ChildAdded / DescendantAdded
local autoConnections = {}

local function StartAutoPlay()
    SetStatus("AutoPlay ACTIVE", T.Green)

    -- Method 1: hook every new note that appears
    local conn = workspace.DescendantAdded:Connect(function(obj)
        if not CFG.AutoPlay then return end
        if not (obj:IsA("BasePart") and obj.Name:lower():find("note")) then return end

        task.spawn(function()
            -- wait for note to be in hit zone (~Y position threshold)
            local tries = 0
            repeat
                task.wait(0.015)
                tries = tries + 1
            until tries > 200
                or (obj.Parent == nil)
                or (obj.Position.Y <= 3 and obj.Position.Y >= -3)  -- hit zone

            if obj.Parent == nil then return end

            -- fire the hit remote if found
            if NoteHitRemote then
                pcall(function()
                    NoteHitRemote:FireServer(obj, CFG.BotScore and 100 or nil)
                end)
            end

            -- also try direct note touch simulation
            pcall(function()
                local hitFn = obj:FindFirstChildOfClass("RemoteEvent")
                if hitFn then hitFn:FireServer() end
            end)

            -- highlight hit
            if CFG.ShowNoteBoxes then
                pcall(function()
                    local hl = Instance.new("SelectionBox")
                    hl.Adornee = obj
                    hl.Color3  = T.Green
                    hl.LineThickness = 0.05
                    hl.Parent  = workspace
                    game:GetService("Debris"):AddItem(hl, 0.3)
                end)
            end
        end)
    end)

    table.insert(autoConnections, conn)

    -- Method 2: scan existing notes every frame (catches notes already spawned)
    local scanConn = RunService.Heartbeat:Connect(function()
        if not CFG.AutoPlay then return end
        for _, note in ipairs(GetNotes()) do
            if note.Position.Y <= 3 and note.Position.Y >= -3 then
                if NoteHitRemote then
                    pcall(function()
                        NoteHitRemote:FireServer(note, CFG.BotScore and 100 or nil)
                    end)
                end
            end
        end
    end)
    table.insert(autoConnections, scanConn)
end

local function StopAutoPlay()
    for _, c in ipairs(autoConnections) do pcall(function() c:Disconnect() end) end
    autoConnections = {}
    SetStatus("AutoPlay stopped", T.SubText)
end

-- ── NoMiss: intercept miss remotes / hook character ──────────────────────────
local missHook = nil
task.spawn(function()
    while true do
        task.wait(1)
        if CFG.NoMiss and not missHook then
            local mr = FindRemote("Miss") or FindRemote("Penalty") or FindRemote("Fail")
            if mr then
                -- Block the miss remote from being fired by swapping it
                missHook = true
                MissRemote = mr
                -- Hook via metatable: replace FireServer
                local mt = getrawmetatable and getrawmetatable(mr)
                if mt and mt.__namecall then
                    local old = mt.__namecall
                    local rw = (setreadonly or function(t,b) end)
                    rw(mt, false)
                    mt.__namecall = function(self, ...)
                        local method = tostring(...):lower()
                        if self == mr and method == "fireserver" then
                            return  -- block miss fires
                        end
                        return old(self, ...)
                    end
                    rw(mt, true)
                end
            end
        end
    end
end)

-- ── Speed hack ────────────────────────────────────────────────────────────────
task.spawn(function()
    while true do
        task.wait(0.5)
        if CFG.SpeedHack then
            -- Try to set the game's song speed
            pcall(function()
                for _, v in pairs(workspace:GetDescendants()) do
                    if v.Name == "SongSpeed" and v:IsA("NumberValue") then
                        v.Value = CFG.SpeedValue
                    end
                end
            end)
            -- Try via SoundService pitch
            pcall(function()
                for _, s in pairs(workspace:GetDescendants()) do
                    if s:IsA("Sound") and s.Playing then
                        s.PlaybackSpeed = CFG.SpeedValue
                    end
                end
            end)
        else
            pcall(function()
                for _, s in pairs(workspace:GetDescendants()) do
                    if s:IsA("Sound") and s.Playing then
                        s.PlaybackSpeed = 1
                    end
                end
            end)
        end
    end
end)

-- ── Anti-AFK ─────────────────────────────────────────────────────────────────
task.spawn(function()
    while true do
        task.wait(60)
        if CFG.AntiAfk then
            pcall(function()
                local vrs = LP:FindFirstChildOfClass("PlayerScripts")
                            and LP:FindFirstChildOfClass("PlayerScripts"):FindFirstChild("PlayerModule")
                -- tiny camera wiggle
                Cam.CFrame = Cam.CFrame * CFrame.Angles(0, math.rad(0.001), 0)
            end)
        end
    end
end)

-- ── Note visualiser (hitbox overlay) ─────────────────────────────────────────
local boxes = {}
RunService.Heartbeat:Connect(function()
    -- clear old boxes
    for _, b in ipairs(boxes) do pcall(function() b:Destroy() end) end
    boxes = {}

    if not CFG.ShowNoteBoxes then return end
    for _, note in ipairs(GetNotes()) do
        pcall(function()
            local sb = Instance.new("SelectionBox")
            sb.Adornee       = note
            sb.Color3        = T.AccentB
            sb.SurfaceColor3 = T.Accent
            sb.SurfaceTransparency = 0.7
            sb.LineThickness = 0.04
            sb.Parent        = workspace
            table.insert(boxes, sb)
        end)
    end
end)

-- ── Watch CFG changes to start/stop systems ───────────────────────────────────
local prevAutoPlay = false
RunService.Heartbeat:Connect(function()
    if CFG.AutoPlay ~= prevAutoPlay then
        prevAutoPlay = CFG.AutoPlay
        if CFG.AutoPlay then
            StartAutoPlay()
        else
            StopAutoPlay()
        end
    end
end)

-- ── Animate accent line ───────────────────────────────────────────────────────
task.spawn(function()
    local hue = 0
    while SG.Parent do
        hue = (hue + 0.5) % 360
        task.wait(0.05)
    end
end)

-- ── Intro ─────────────────────────────────────────────────────────────────────
Tween(WIN, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    {Size = UDim2.new(0, 360, 0, 480)})

Notify("FNF Hub", "Loaded! Toggle features with the buttons.")
SetStatus("Ready — game: " .. gameType, T.AccentB)

print("[FNF Hub] Loaded — game type: " .. gameType)
