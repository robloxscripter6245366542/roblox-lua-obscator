-- Dodge or Die — Movement Utility Hub
-- Client-side survival helpers: Fly · Infinite Jump · Speed · Jump · Noclip · Anti-AFK
-- These modify only YOUR character (network-owned), no game remotes required.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local VirtualUser       = game:GetService("VirtualUser")
local LocalPlayer       = Players.LocalPlayer

-- ── GAME REMOTE: keepalive heartbeat (captured via spy) ──────────
-- ReplicatedStorage.RemoteEvents.GameplayEvents.HitDetectionHeartbeat
-- Fired with no args on an interval; the server kicks you (Error 267,
-- "Connection lost please rejoin") if it stops receiving them.
local heartbeatRemote
pcall(function()
    heartbeatRemote = ReplicatedStorage:WaitForChild("RemoteEvents",5)
        :WaitForChild("GameplayEvents",5):WaitForChild("HitDetectionHeartbeat",5)
end)

-- ── GAME REMOTE: round phase broadcast (server → client) ─────────
-- ReplicatedStorage.RemoteEvents.RoundTimerUpdate  ("DODGE!", boolean)
local roundRemote
pcall(function()
    roundRemote = ReplicatedStorage:WaitForChild("RemoteEvents",5):WaitForChild("RoundTimerUpdate",5)
end)
local currentPhase = "—"
local onPhaseChange  -- set after GUI exists

-- ── CHARACTER REFS ───────────────────────────────────────────────
local char, hrp, humanoid
local function bindCharacter(c)
    char      = c
    hrp       = c:WaitForChild("HumanoidRootPart", 5)
    humanoid  = c:WaitForChild("Humanoid", 5)
end
if LocalPlayer.Character then bindCharacter(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(function(c)
    task.wait(0.2); bindCharacter(c)
end)

-- ── STATE ────────────────────────────────────────────────────────
local state = {
    flying      = false,
    flySpeed    = 70,
    infJump     = false,
    noclip      = false,
    walkSpeed   = 16,
    jumpPower   = 50,
    speedOn     = false,
    jumpOn      = false,
    keepAlive   = false,
    keepRate    = 1.0,   -- seconds between heartbeat fires
    autoDodge   = false,
    dodgeDist   = 28,    -- start dodging when ball is within this many studs
    superSlide  = false,
    slidePower  = 120,   -- game default is ~50; this dashes much faster
}

-- ── SUPER SLIDE (no cooldown) ────────────────────────────────────
-- The game's "Slide Ability" is purely client-side: a BodyVelocity of
-- LookVector*(Dashes+50) gated by a 1s cooldown. This reimplements it
-- with adjustable power and NO cooldown, on the same C key.
local sliding = false
local function doSlide()
    if sliding or not hrp then return end
    sliding = true
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(30000, 0, 30000)
    bv.Velocity = hrp.CFrame.LookVector * state.slidePower
    bv.Parent = hrp
    task.spawn(function()
        for _=1,4 do
            task.wait(0.08)
            if bv.Parent then bv.Velocity = bv.Velocity * 0.72 end
        end
        if bv then bv:Destroy() end
        sliding = false
    end)
end
UserInputService.InputBegan:Connect(function(input, processed)
    if processed or not state.superSlide then return end
    if input.KeyCode == Enum.KeyCode.C then doSlide() end
end)

-- ── AUTO-DODGE ───────────────────────────────────────────────────
-- Finds the death ball heuristically (name match, or a big moving part)
-- and runs the character directly away from it whenever it gets close.
local cachedBall, lastBallScan = nil, 0
local function findBall()
    local best, bestScore
    for _,p in ipairs(workspace:GetDescendants()) do
        if p:IsA("BasePart") then
            local n = p.Name:lower()
            local named  = n:find("ball") or n:find("death") or n:find("hazard") or n:find("bomb")
            local moving = p.AssemblyLinearVelocity.Magnitude > 6
            local big    = p.Size.Magnitude > 6
            if named or (big and moving) then
                local score = (named and 1000 or 0) + p.Size.Magnitude + p.AssemblyLinearVelocity.Magnitude
                if not bestScore or score > bestScore then bestScore = score; best = p end
            end
        end
    end
    return best
end
RunService.Heartbeat:Connect(function()
    if not state.autoDodge or not hrp or not humanoid then return end
    if tick() - lastBallScan > 0.4 or not (cachedBall and cachedBall.Parent) then
        cachedBall = findBall(); lastBallScan = tick()
    end
    local ball = cachedBall
    if not (ball and ball.Parent) then return end
    -- predict where the ball is heading and measure flat distance
    local future = ball.Position + ball.AssemblyLinearVelocity * 0.15
    local toBall = Vector3.new(future.X - hrp.Position.X, 0, future.Z - hrp.Position.Z)
    if toBall.Magnitude < state.dodgeDist and toBall.Magnitude > 0.1 then
        humanoid:Move(-toBall.Unit, false)   -- sprint directly away from the threat
    end
end)

-- ── KEEPALIVE LOOP (prevents Error 267 disconnect) ───────────────
task.spawn(function()
    while true do
        if state.keepAlive and heartbeatRemote then
            pcall(function() heartbeatRemote:FireServer() end)
        end
        task.wait(state.keepRate)
    end
end)

-- ── FLY ──────────────────────────────────────────────────────────
local flyVel, flyGyro
local function startFly()
    if not hrp then return end
    state.flying = true
    flyVel = Instance.new("BodyVelocity")
    flyVel.MaxForce = Vector3.new(1,1,1)*math.huge
    flyVel.Velocity = Vector3.zero
    flyVel.Parent = hrp
    flyGyro = Instance.new("BodyGyro")
    flyGyro.MaxTorque = Vector3.new(1,1,1)*math.huge
    flyGyro.P = 9000
    flyGyro.CFrame = hrp.CFrame
    flyGyro.Parent = hrp
    if humanoid then humanoid.PlatformStand = true end
end
local function stopFly()
    state.flying = false
    if flyVel then flyVel:Destroy(); flyVel=nil end
    if flyGyro then flyGyro:Destroy(); flyGyro=nil end
    if humanoid then humanoid.PlatformStand = false end
end
RunService.RenderStepped:Connect(function()
    if not state.flying or not hrp or not flyVel then return end
    local cam = workspace.CurrentCamera
    local dir = Vector3.zero
    local look, right = cam.CFrame.LookVector, cam.CFrame.RightVector
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + look end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - look end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + right end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - right end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
    flyVel.Velocity = (dir.Magnitude>0 and dir.Unit or Vector3.zero) * state.flySpeed
    flyGyro.CFrame = cam.CFrame
end)

-- ── INFINITE JUMP ────────────────────────────────────────────────
UserInputService.JumpRequest:Connect(function()
    if state.infJump and humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ── NOCLIP ───────────────────────────────────────────────────────
RunService.Stepped:Connect(function()
    if state.noclip and char then
        for _,p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
        end
    end
end)

-- ── SPEED / JUMP APPLY ───────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    if not humanoid then return end
    if state.speedOn then humanoid.WalkSpeed = state.walkSpeed end
    if state.jumpOn then
        humanoid.UseJumpPower = true
        humanoid.JumpPower = state.jumpPower
    end
end)

-- ── ANTI-AFK ─────────────────────────────────────────────────────
pcall(function()
    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  GUI  (purple, stealth-mounted)                               ║
-- ╚═══════════════════════════════════════════════════════════════╝
local function guiParent()
    local ok,hui = pcall(function() return gethui and gethui() end)
    if ok and hui then return hui end
    local okc,cg = pcall(function() return game:GetService("CoreGui") end)
    if okc and cg then return cg end
    return LocalPlayer:WaitForChild("PlayerGui")
end
local function randName()
    local s="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"; local t={}
    for _=1,math.random(8,13) do local i=math.random(1,#s); t[#t+1]=s:sub(i,i) end
    return table.concat(t)
end
local function corner(o,r) local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r);c.Parent=o end

local PURP   = Color3.fromRGB(140,70,240)
local PURP2  = Color3.fromRGB(184,116,255)
local BG     = Color3.fromRGB(16,10,26)
local PANEL  = Color3.fromRGB(24,15,40)
local TEXT   = Color3.fromRGB(232,224,255)
local DIM    = Color3.fromRGB(120,104,150)
local GOOD   = Color3.fromRGB(96,222,142)

local sg=Instance.new("ScreenGui")
sg.Name=randName(); sg.ResetOnSpawn=false; sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
pcall(function() if syn and syn.protect_gui then syn.protect_gui(sg) end end)
sg.Parent=guiParent()

local W,H=260,604
local main=Instance.new("Frame")
main.AnchorPoint=Vector2.new(0.5,0.5); main.Position=UDim2.new(0.5,0,0.5,0)
main.Size=UDim2.new(0,W,0,H); main.BackgroundColor3=BG; main.BorderSizePixel=0
main.Active=true; main.Draggable=true; main.Parent=sg
corner(main,10)
do local s=Instance.new("UIStroke");s.Color=PURP;s.Thickness=1.4;s.Transparency=0.2;s.Parent=main end
do
    local g=Instance.new("UIGradient")
    g.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(27,16,46)),ColorSequenceKeypoint.new(1,Color3.fromRGB(13,7,23))}
    g.Rotation=120; g.Parent=main
end

-- title
local title=Instance.new("Frame")
title.Size=UDim2.new(1,0,0,32); title.BackgroundColor3=PANEL; title.BorderSizePixel=0; title.Parent=main
corner(title,10)
local tl=Instance.new("TextLabel")
tl.Size=UDim2.new(1,-40,1,0); tl.Position=UDim2.new(0,12,0,0); tl.BackgroundTransparency=1
tl.Text="⚡ DODGE OR DIE"; tl.TextColor3=PURP2; tl.Font=Enum.Font.GothamBold; tl.TextSize=13
tl.TextXAlignment=Enum.TextXAlignment.Left; tl.Parent=title
local closeB=Instance.new("TextButton")
closeB.Size=UDim2.new(0,24,0,24); closeB.Position=UDim2.new(1,-28,0.5,-12)
closeB.BackgroundTransparency=1; closeB.Text="✕"; closeB.TextColor3=Color3.fromRGB(236,92,112)
closeB.Font=Enum.Font.GothamBold; closeB.TextSize=13; closeB.Parent=title
closeB.MouseButton1Click:Connect(function() main.Visible=false end)

local body=Instance.new("Frame")
body.Size=UDim2.new(1,-16,1,-42); body.Position=UDim2.new(0,8,0,38)
body.BackgroundTransparency=1; body.Parent=main
local layout=Instance.new("UIListLayout"); layout.Padding=UDim.new(0,6); layout.Parent=body

-- round phase banner (driven by RoundTimerUpdate)
local phaseBanner=Instance.new("Frame")
phaseBanner.Size=UDim2.new(1,0,0,30); phaseBanner.BackgroundColor3=Color3.fromRGB(30,18,50)
phaseBanner.BorderSizePixel=0; phaseBanner.LayoutOrder=-1; phaseBanner.Parent=body
corner(phaseBanner,6)
local phaseLbl=Instance.new("TextLabel")
phaseLbl.Size=UDim2.new(1,0,1,0); phaseLbl.BackgroundTransparency=1
phaseLbl.Text="PHASE: —"; phaseLbl.TextColor3=PURP2; phaseLbl.Font=Enum.Font.GothamBold
phaseLbl.TextSize=13; phaseLbl.Parent=phaseBanner

onPhaseChange=function(phase, flag)
    currentPhase=tostring(phase)
    phaseLbl.Text="PHASE: "..currentPhase
    -- flash red on a dodge instruction
    local danger=currentPhase:upper():find("DODGE")~=nil
    phaseLbl.TextColor3=danger and Color3.fromRGB(255,90,90) or PURP2
    TweenService:Create(phaseBanner,TweenInfo.new(0.15),{BackgroundColor3=danger and Color3.fromRGB(70,20,28) or Color3.fromRGB(30,18,50)}):Play()
    if danger then
        TweenService:Create(phaseBanner,TweenInfo.new(0.6),{BackgroundColor3=Color3.fromRGB(30,18,50)}):Play()
    end
end
if roundRemote then
    roundRemote.OnClientEvent:Connect(function(phase, flag) pcall(onPhaseChange, phase, flag) end)
end

-- toggle row
local function mkToggle(name, default, onChange, order)
    local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,30); row.BackgroundColor3=PANEL
    row.BorderSizePixel=0; row.LayoutOrder=order; row.Parent=body
    corner(row,6)
    local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,-58,1,0); lbl.Position=UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=name; lbl.TextColor3=TEXT; lbl.Font=Enum.Font.GothamMedium
    lbl.TextSize=12; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=row
    local track=Instance.new("TextButton"); track.Size=UDim2.new(0,38,0,18); track.Position=UDim2.new(1,-46,0.5,-9)
    track.BorderSizePixel=0; track.Text=""; track.AutoButtonColor=false; track.Parent=row
    corner(track,9)
    local knob=Instance.new("Frame"); knob.Size=UDim2.new(0,14,0,14); knob.BorderSizePixel=0; knob.Parent=track
    corner(knob,7)
    local on=default
    local function paint()
        TweenService:Create(track,TweenInfo.new(0.16),{BackgroundColor3=on and PURP or Color3.fromRGB(40,26,62)}):Play()
        TweenService:Create(knob,TweenInfo.new(0.16),{Position=on and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7),
            BackgroundColor3=on and Color3.fromRGB(255,255,255) or Color3.fromRGB(140,124,168)}):Play()
    end
    paint()
    track.MouseButton1Click:Connect(function() on=not on; paint(); onChange(on) end)
end

-- slider row
local function mkSlider(name, min, max, default, onChange, order)
    local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,42); row.BackgroundColor3=PANEL
    row.BorderSizePixel=0; row.LayoutOrder=order; row.Parent=body
    corner(row,6)
    local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,-20,0,16); lbl.Position=UDim2.new(0,10,0,4)
    lbl.BackgroundTransparency=1; lbl.Text=name..": "..default; lbl.TextColor3=TEXT
    lbl.Font=Enum.Font.GothamMedium; lbl.TextSize=12; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=row
    local bar=Instance.new("Frame"); bar.Size=UDim2.new(1,-20,0,6); bar.Position=UDim2.new(0,10,0,28)
    bar.BackgroundColor3=Color3.fromRGB(40,26,62); bar.BorderSizePixel=0; bar.Parent=row
    corner(bar,3)
    local fill=Instance.new("Frame"); fill.BackgroundColor3=PURP; fill.BorderSizePixel=0; fill.Parent=bar
    fill.Size=UDim2.new((default-min)/(max-min),0,1,0); corner(fill,3)
    local dragging=false
    local function set(x)
        local rel=math.clamp((x-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
        local val=math.floor(min+(max-min)*rel)
        fill.Size=UDim2.new(rel,0,1,0); lbl.Text=name..": "..val; onChange(val)
    end
    bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true; set(i.Position.X) end end)
    UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then set(i.Position.X) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
end

mkToggle("⚡ AUTO-DODGE", false, function(v) state.autoDodge=v end, 0)
mkSlider("Dodge Range", 12, 60, 28, function(v) state.dodgeDist=v end, 1)
mkToggle("Super Slide  (C, no cooldown)", false, function(v) state.superSlide=v end, 2)
mkSlider("Slide Power", 50, 350, 120, function(v) state.slidePower=v end, 3)
mkToggle("Anti-Kick (Heartbeat)", false, function(v) state.keepAlive=v end, 4)
mkToggle("Fly  (WASD/Space/Ctrl)", false, function(v) if v then startFly() else stopFly() end end, 5)
mkToggle("Infinite Jump", false, function(v) state.infJump=v end, 6)
mkToggle("Noclip", false, function(v) state.noclip=v; if not v and char then for _,p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=true end end end end, 7)
mkToggle("Speed Boost", false, function(v) state.speedOn=v; if not v and humanoid then humanoid.WalkSpeed=16 end end, 8)
mkToggle("Jump Boost", false, function(v) state.jumpOn=v; if not v and humanoid then humanoid.JumpPower=50 end end, 9)
mkSlider("Fly Speed", 20, 200, 70, function(v) state.flySpeed=v end, 10)
mkSlider("Walk Speed", 16, 250, 16, function(v) state.walkSpeed=v end, 11)
mkSlider("Jump Power", 50, 350, 50, function(v) state.jumpPower=v end, 12)

-- floating reopen button
local pill=Instance.new("TextButton")
pill.Size=UDim2.new(0,70,0,24); pill.Position=UDim2.new(0,8,0,8)
pill.BackgroundColor3=PURP; pill.BorderSizePixel=0; pill.Text="DODGE"; pill.TextColor3=TEXT
pill.Font=Enum.Font.GothamBold; pill.TextSize=11; pill.Parent=sg
corner(pill,12)
pill.MouseButton1Click:Connect(function() main.Visible=not main.Visible end)
