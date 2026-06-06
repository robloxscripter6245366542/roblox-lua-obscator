-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║  STRONGEST BATTLEGROUNDS  FE HUB  v1.0                              ║
-- ║  Fluent-style UI  ·  Animations + Fling  ·  Delta / iOS compatible  ║
-- ╚══════════════════════════════════════════════════════════════════════╝

local ok, err = pcall(function()

-- ── Services ─────────────────────────────────────────────────────────────────
local Players   = game:GetService("Players")
local UIS       = game:GetService("UserInputService")
local RS        = game:GetService("RunService")
local TS        = game:GetService("TweenService")
local HS        = game:GetService("HttpService")
local Debris    = game:GetService("Debris")
local LP        = Players.LocalPlayer
local PGui      = LP:WaitForChild("PlayerGui", 15)
local cam       = workspace.CurrentCamera
if not PGui then warn("[SBHub] No PlayerGui"); return end

local old = PGui:FindFirstChild("__SBHub__")
if old then old:Destroy() end

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function getChar() return LP.Character end
local function getHRP()  local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum()  local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid") end

local function notify(t, m, d)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification",{Title=t,Text=m,Duration=d or 3})
    end)
end

local CONNS = {}
local function ac(c) CONNS[#CONNS+1]=c; return c end

-- ══════════════════════════════════════════════════════════════════════════════
--  FLUENT-STYLE THEME  (Windows 11 / Fluent Design)
-- ══════════════════════════════════════════════════════════════════════════════
local C = {
    BG        = Color3.fromRGB(28,  28,  34),   -- mica background
    CARD      = Color3.fromRGB(36,  36,  44),   -- card surface
    CARD2     = Color3.fromRGB(46,  46,  56),   -- secondary card
    STROKE    = Color3.fromRGB(62,  62,  74),   -- subtle border
    ACCENT    = Color3.fromRGB(96, 205, 255),   -- #60cdff  (Fluent blue)
    ACCENT2   = Color3.fromRGB(78, 160, 255),
    RED       = Color3.fromRGB(255, 85,  85),
    GRN       = Color3.fromRGB(90, 220, 130),
    YEL       = Color3.fromRGB(255, 200,  60),
    TX        = Color3.fromRGB(240, 240, 248),
    TX2       = Color3.fromRGB(170, 172, 185),
    TX3       = Color3.fromRGB(100, 103, 118),
    WHITE     = Color3.new(1,1,1),
    SIDE      = Color3.fromRGB(22,  22,  28),
}

local TF_FAST   = TweenInfo.new(0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TF_MED    = TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TF_SLOW   = TweenInfo.new(0.38, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TF_SPRING = TweenInfo.new(0.32, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)

local function tw(o,p,i) TS:Create(o,i or TF_MED,p):Play() end

-- ── UI helpers ────────────────────────────────────────────────────────────────
local function corner(o,r) local c=Instance.new("UICorner",o); c.CornerRadius=UDim.new(0,r or 8) end
local function stroke(o,col,th) local s=Instance.new("UIStroke",o); s.Color=col or C.STROKE; s.Thickness=th or 1 end
local function pad(o,t,b,l,r) local p=Instance.new("UIPadding",o); p.PaddingTop=UDim.new(0,t or 8); p.PaddingBottom=UDim.new(0,b or 8); p.PaddingLeft=UDim.new(0,l or 10); p.PaddingRight=UDim.new(0,r or 10) end
local function listV(o,sp) local l=Instance.new("UIListLayout",o); l.FillDirection=Enum.FillDirection.Vertical; l.HorizontalAlignment=Enum.HorizontalAlignment.Left; l.SortOrder=Enum.SortOrder.LayoutOrder; l.Padding=UDim.new(0,sp or 6); return l end
local function grad(o,c1,c2,rot) local g=Instance.new("UIGradient",o); g.Color=ColorSequence.new(c1,c2); g.Rotation=rot or 90 end

-- ══════════════════════════════════════════════════════════════════════════════
--  WINDOW
-- ══════════════════════════════════════════════════════════════════════════════
local SCR = Instance.new("ScreenGui", PGui)
SCR.Name="__SBHub__"; SCR.ResetOnSpawn=false; SCR.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; SCR.IgnoreGuiInset=true

-- Glow shadow
local GLOW = Instance.new("ImageLabel", SCR)
GLOW.Size=UDim2.new(0,440,0,600); GLOW.Position=UDim2.new(0.5,-222,0.5,-298)
GLOW.BackgroundTransparency=1; GLOW.Image="rbxassetid://5028857084"
GLOW.ImageColor3=Color3.fromRGB(30,80,160); GLOW.ImageTransparency=0.65; GLOW.ZIndex=0

local WIN = Instance.new("Frame", SCR)
WIN.Name="WIN"; WIN.Size=UDim2.new(0,400,0,560); WIN.Position=UDim2.new(0.5,-200,0.5,-280)
WIN.BackgroundColor3=C.BG; WIN.BorderSizePixel=0; corner(WIN,12)
stroke(WIN, C.STROKE, 1); WIN.ClipsDescendants=true; WIN.ZIndex=1

-- Acrylic tint strip at top
local TINT = Instance.new("Frame", WIN)
TINT.Size=UDim2.new(1,0,0,3); TINT.BackgroundColor3=C.ACCENT; TINT.BorderSizePixel=0
grad(TINT, C.ACCENT, C.ACCENT2, 0)

-- Title bar
local TBAR = Instance.new("Frame", WIN)
TBAR.Size=UDim2.new(1,0,0,44); TBAR.Position=UDim2.new(0,0,0,3)
TBAR.BackgroundColor3=C.SIDE; TBAR.BorderSizePixel=0

local TICON = Instance.new("TextLabel", TBAR)
TICON.Size=UDim2.new(0,28,0,28); TICON.Position=UDim2.new(0,10,0.5,-14)
TICON.BackgroundTransparency=1; TICON.Text="⚡"; TICON.Font=Enum.Font.GothamBold
TICON.TextSize=18; TICON.TextColor3=C.ACCENT; TICON.TextXAlignment=Enum.TextXAlignment.Center

local TTITLE = Instance.new("TextLabel", TBAR)
TTITLE.Size=UDim2.new(1,-120,1,0); TTITLE.Position=UDim2.new(0,42,0,0)
TTITLE.BackgroundTransparency=1; TTITLE.Text="Strongest Battlegrounds Hub"
TTITLE.TextColor3=C.TX; TTITLE.Font=Enum.Font.GothamSemibold; TTITLE.TextSize=13
TTITLE.TextXAlignment=Enum.TextXAlignment.Left

-- Window controls (macOS style)
local function winBtn(x, col, ico)
    local f=Instance.new("Frame",TBAR); f.Size=UDim2.new(0,13,0,13); f.Position=UDim2.new(1,x,0.5,-6.5)
    f.BackgroundColor3=col; f.BorderSizePixel=0; corner(f,7)
    local b=Instance.new("TextButton",f); b.Size=UDim2.new(1,0,1,0); b.BackgroundTransparency=1; b.Text=""
    return b
end
local CLOSEBTN = winBtn(-28, C.RED, "✕")
local MINBTN   = winBtn(-46, C.YEL, "−")

-- Sidebar
local SIDE = Instance.new("Frame", WIN)
SIDE.Size=UDim2.new(0,90,1,-47); SIDE.Position=UDim2.new(0,0,0,47)
SIDE.BackgroundColor3=C.SIDE; SIDE.BorderSizePixel=0
local SD = Instance.new("UIStroke",SIDE); SD.Color=C.STROKE; SD.Thickness=1; SD.ApplyStrokeMode=Enum.ApplyStrokeMode.Border

local SIDE_LL = listV(SIDE, 3)
SIDE_LL.HorizontalAlignment = Enum.HorizontalAlignment.Center
pad(SIDE, 8, 8, 5, 5)

-- Body
local BODY = Instance.new("Frame", WIN)
BODY.Size=UDim2.new(1,-92,1,-47); BODY.Position=UDim2.new(0,92,0,47)
BODY.BackgroundTransparency=1; BODY.ClipsDescendants=true

-- ══════════════════════════════════════════════════════════════════════════════
--  TAB SYSTEM
-- ══════════════════════════════════════════════════════════════════════════════
local tabBtns  = {}
local tabPages = {}
local activeTab = nil
local loCount  = 0
local function nextLo() loCount=loCount+1; return loCount end

local TABS = {
    {id="anims",    icon="🎭", label="Anims"},
    {id="fling",    icon="💥", label="Fling"},
    {id="move",     icon="🏃", label="Move"},
    {id="combat",   icon="⚔",  label="Combat"},
    {id="visual",   icon="👁",  label="Visual"},
    {id="misc",     icon="⚙",  label="Misc"},
}

local function newPage()
    local s=Instance.new("ScrollingFrame",BODY)
    s.Size=UDim2.new(1,0,1,0); s.BackgroundTransparency=1; s.BorderSizePixel=0
    s.ScrollBarThickness=3; s.ScrollBarImageColor3=C.ACCENT
    s.CanvasSize=UDim2.new(0,0,0,0); s.AutomaticCanvasSize=Enum.AutomaticSize.Y; s.Visible=false
    pad(s,10,10,10,8); listV(s,7)
    return s
end

for _, td in ipairs(TABS) do
    local page = newPage(); tabPages[td.id] = page
    local btn = Instance.new("TextButton", SIDE)
    btn.Size=UDim2.new(1,0,0,62); btn.BackgroundColor3=C.CARD
    btn.BorderSizePixel=0; btn.Text=""; corner(btn,8)
    local ic=Instance.new("TextLabel",btn); ic.Size=UDim2.new(1,0,0,26); ic.Position=UDim2.new(0,0,0,8)
    ic.BackgroundTransparency=1; ic.Text=td.icon; ic.Font=Enum.Font.GothamBold; ic.TextSize=18
    ic.TextXAlignment=Enum.TextXAlignment.Center; ic.TextColor3=C.TX3
    local lb=Instance.new("TextLabel",btn); lb.Size=UDim2.new(1,0,0,14); lb.Position=UDim2.new(0,0,0,36)
    lb.BackgroundTransparency=1; lb.Text=td.label; lb.Font=Enum.Font.Gotham; lb.TextSize=9.5
    lb.TextXAlignment=Enum.TextXAlignment.Center; lb.TextColor3=C.TX3
    tabBtns[td.id]={btn=btn,ic=ic,lb=lb}
    btn.MouseButton1Click:Connect(function()
        if activeTab==td.id then return end
        if activeTab then
            tabPages[activeTab].Visible=false
            local ob=tabBtns[activeTab]; tw(ob.btn,{BackgroundColor3=C.CARD}); tw(ob.ic,{TextColor3=C.TX3}); tw(ob.lb,{TextColor3=C.TX3})
        end
        activeTab=td.id; tabPages[td.id].Visible=true
        tw(btn,{BackgroundColor3=C.CARD2},TF_SPRING); tw(ic,{TextColor3=C.ACCENT}); tw(lb,{TextColor3=C.ACCENT})
    end)
end

local function showTab(id) if tabBtns[id] then tabBtns[id].btn.MouseButton1Click:Fire() end end

-- ── Component builders ────────────────────────────────────────────────────────
local function secHeader(p, t)
    local f=Instance.new("Frame",p); f.Size=UDim2.new(1,0,0,22); f.BackgroundTransparency=1; f.LayoutOrder=nextLo()
    local l=Instance.new("TextLabel",f); l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1
    l.Text=t:upper(); l.TextColor3=C.TX3; l.Font=Enum.Font.GothamBold; l.TextSize=9.5; l.TextXAlignment=Enum.TextXAlignment.Left
    local d=Instance.new("Frame",f); d.Size=UDim2.new(1,0,0,1); d.Position=UDim2.new(0,0,1,-1)
    d.BackgroundColor3=C.STROKE; d.BorderSizePixel=0
end

local function addToggle(p, title, desc, default, cb)
    local on=default or false
    local f=Instance.new("Frame",p); f.Size=UDim2.new(1,0,0,54); f.BackgroundColor3=C.CARD
    f.BorderSizePixel=0; corner(f,8); f.LayoutOrder=nextLo(); stroke(f,C.STROKE)
    local t=Instance.new("TextLabel",f); t.Size=UDim2.new(1,-64,0,18); t.Position=UDim2.new(0,12,0,9)
    t.BackgroundTransparency=1; t.Text=title; t.TextColor3=C.TX; t.Font=Enum.Font.GothamSemibold; t.TextSize=12; t.TextXAlignment=Enum.TextXAlignment.Left
    if desc and desc~="" then
        local d=Instance.new("TextLabel",f); d.Size=UDim2.new(1,-16,0,12); d.Position=UDim2.new(0,12,0,30)
        d.BackgroundTransparency=1; d.Text=desc; d.TextColor3=C.TX3; d.Font=Enum.Font.Gotham; d.TextSize=9.5; d.TextXAlignment=Enum.TextXAlignment.Left
    end
    local pill=Instance.new("Frame",f); pill.Size=UDim2.new(0,40,0,22); pill.Position=UDim2.new(1,-52,0.5,-11)
    pill.BackgroundColor3=on and C.ACCENT or C.CARD2; pill.BorderSizePixel=0; corner(pill,11); stroke(pill,C.STROKE)
    local knob=Instance.new("Frame",pill); knob.Size=UDim2.new(0,16,0,16); knob.Position=UDim2.new(0,on and 21 or 3,0.5,-8)
    knob.BackgroundColor3=C.WHITE; knob.BorderSizePixel=0; corner(knob,8)
    local hb=Instance.new("TextButton",f); hb.Size=UDim2.new(1,0,1,0); hb.BackgroundTransparency=1; hb.Text=""
    hb.MouseButton1Click:Connect(function()
        on=not on; tw(pill,{BackgroundColor3=on and C.ACCENT or C.CARD2})
        tw(knob,{Position=UDim2.new(0,on and 21 or 3,0.5,-8)}); task.spawn(cb,on)
    end)
    return function(v) if v~=on then hb.MouseButton1Click:Fire() end end
end

local function addButton(p, title, desc, col, cb)
    local f=Instance.new("Frame",p); f.Size=UDim2.new(1,0,0,54); f.BackgroundColor3=C.CARD
    f.BorderSizePixel=0; corner(f,8); f.LayoutOrder=nextLo(); stroke(f,C.STROKE)
    local t=Instance.new("TextLabel",f); t.Size=UDim2.new(1,-86,0,18); t.Position=UDim2.new(0,12,0,9)
    t.BackgroundTransparency=1; t.Text=title; t.TextColor3=C.TX; t.Font=Enum.Font.GothamSemibold; t.TextSize=12; t.TextXAlignment=Enum.TextXAlignment.Left
    if desc and desc~="" then
        local d=Instance.new("TextLabel",f); d.Size=UDim2.new(1,-16,0,12); d.Position=UDim2.new(0,12,0,30)
        d.BackgroundTransparency=1; d.Text=desc; d.TextColor3=C.TX3; d.Font=Enum.Font.Gotham; d.TextSize=9.5; d.TextXAlignment=Enum.TextXAlignment.Left
    end
    local btn=Instance.new("TextButton",f); btn.Size=UDim2.new(0,64,0,26); btn.Position=UDim2.new(1,-74,0.5,-13)
    btn.BackgroundColor3=col or C.ACCENT; btn.Text="Run"; btn.TextColor3=C.BG
    btn.Font=Enum.Font.GothamBold; btn.TextSize=11; btn.BorderSizePixel=0; corner(btn,6)
    btn.MouseButton1Click:Connect(function()
        tw(btn,{BackgroundColor3=C.WHITE},TF_FAST); task.delay(0.15,function() tw(btn,{BackgroundColor3=col or C.ACCENT}) end)
        task.spawn(cb)
    end)
end

local function addInfo(p, text, col)
    local f=Instance.new("Frame",p); f.Size=UDim2.new(1,0,0,32); f.BackgroundColor3=C.CARD2
    f.BorderSizePixel=0; corner(f,6); f.LayoutOrder=nextLo()
    local l=Instance.new("TextLabel",f); l.Size=UDim2.new(1,-12,1,0); l.Position=UDim2.new(0,10,0,0)
    l.BackgroundTransparency=1; l.Text=text; l.TextColor3=col or C.TX2
    l.Font=Enum.Font.Gotham; l.TextSize=10.5; l.TextXAlignment=Enum.TextXAlignment.Left; l.TextWrapped=true
end

-- ══════════════════════════════════════════════════════════════════════════════
--  GAME LOGIC
-- ══════════════════════════════════════════════════════════════════════════════

-- Fling settings
local flingEnabled = false
local flingForce   = 180
local flingUp      = 40
local flingRadius  = 14
local currentAnim  = nil
local animTrack    = nil

local function nearestPlayer(maxDist)
    local hrp = getHRP(); if not hrp then return nil end
    local best, bd = nil, maxDist or math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local r2 = p.Character:FindFirstChild("HumanoidRootPart")
            if r2 then
                local d = (r2.Position - hrp.Position).Magnitude
                if d < bd then best = p; bd = d end
            end
        end
    end
    return best
end

local function flingPlayer(target, dir)
    if not target or not target.Character then return end
    local hrp = target.Character:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local myHRP = getHRP(); if not myHRP then return end
    local d = dir or (hrp.Position - myHRP.Position).Unit
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = d * flingForce + Vector3.new(0, flingUp, 0)
    bv.MaxForce = Vector3.new(1e9, 1e9, 1e9); bv.Parent = hrp
    Debris:AddItem(bv, 0.18)
    -- Also apply torque for spin effect
    local bg = Instance.new("BodyAngularVelocity")
    bg.AngularVelocity = Vector3.new(math.random(-50,50), math.random(-50,50), math.random(-50,50))
    bg.MaxTorque = Vector3.new(1e9,1e9,1e9); bg.Parent = hrp
    Debris:AddItem(bg, 0.2)
end

local function playAnim(animId, flingOnPlay)
    local hum = getHum(); if not hum then notify("Anims","No humanoid!",2); return end
    if animTrack then pcall(function() animTrack:Stop() end); animTrack=nil end
    local a = Instance.new("Animation"); a.AnimationId = "rbxassetid://"..tostring(animId)
    local ok2, track = pcall(function() return hum:LoadAnimation(a) end)
    if not ok2 or not track then notify("Anims","Failed to load anim "..animId,3); return end
    animTrack = track; track:Play()
    notify("Anims","Playing animation",2)
    if flingOnPlay then
        local target = nearestPlayer(flingRadius)
        if target then flingPlayer(target); notify("Fling","Flung "..target.Name,2)
        else notify("Fling","No target in range ("..flingRadius.."st)",2) end
    end
    track.Stopped:Connect(function() animTrack=nil end)
end

-- ══════════════════════════════════════════════════════════════════════════════
--  TAB: ANIMATIONS
-- Strongest Battlegrounds public animation IDs (from the game's rig)
-- ══════════════════════════════════════════════════════════════════════════════
local ANIMS = {
    -- Movement
    {cat="MOVEMENT",   name="Run",           id=616010382},
    {cat="MOVEMENT",   name="Walk",          id=616010382},
    {cat="MOVEMENT",   name="Jump",          id=125750702},
    {cat="MOVEMENT",   name="Fall",          id=180436148},
    {cat="MOVEMENT",   name="Idle",          id=180435571},
    -- Attacks
    {cat="ATTACKS",    name="Punch 1",       id=742638842},
    {cat="ATTACKS",    name="Punch 2",       id=742640481},
    {cat="ATTACKS",    name="Kick",          id=742636889},
    {cat="ATTACKS",    name="Uppercut",      id=616008936},
    {cat="ATTACKS",    name="Slam",          id=616163682},
    {cat="ATTACKS",    name="Spin Kick",     id=742643870},
    {cat="ATTACKS",    name="Ground Slam",   id=616163682},
    -- Special
    {cat="SPECIAL",    name="Stand Up",      id=614905591},
    {cat="SPECIAL",    name="Sit",           id=2506281703},
    {cat="SPECIAL",    name="Wave",          id=507770239},
    {cat="SPECIAL",    name="Laugh",         id=3576735544},
    {cat="SPECIAL",    name="Cheer",         id=507770677},
    {cat="SPECIAL",    name="Dance",         id=507771019},
    {cat="SPECIAL",    name="Point",         id=507770453},
    {cat="SPECIAL",    name="Salute",        id=3337689006},
    -- Taunt
    {cat="TAUNT",      name="Flip",          id=754636970},
    {cat="TAUNT",      name="Spin",          id=507768792},
    {cat="TAUNT",      name="Float",         id=616001225},
    {cat="TAUNT",      name="Backflip",      id=3697001580},
}

do
    local P = tabPages["anims"]
    local autoFling = false
    loCount = 0

    addInfo(P, "▶ Play any animation on your character. Enable Auto-Fling to launch the nearest player on each play.")

    addToggle(P, "Auto-Fling on Play", "Fling nearest player when animation plays", false, function(v)
        autoFling = v
    end)

    secHeader(P, "MOVEMENT")
    secHeader(P, "ATTACKS")
    secHeader(P, "SPECIAL")
    secHeader(P, "TAUNT")

    -- Insert animation buttons under correct headers
    local cats = {"MOVEMENT","ATTACKS","SPECIAL","TAUNT"}
    local catIdx = 0
    loCount = 0

    -- Rebuild with proper ordering
    for _, cat in ipairs(cats) do
        secHeader(P, cat)
        for _, anim in ipairs(ANIMS) do
            if anim.cat == cat then
                local f = Instance.new("Frame", P)
                f.Size = UDim2.new(1,0,0,40); f.BackgroundColor3 = C.CARD
                f.BorderSizePixel=0; corner(f,8); f.LayoutOrder=nextLo(); stroke(f,C.STROKE)

                local nm = Instance.new("TextLabel",f); nm.Size=UDim2.new(1,-120,1,0); nm.Position=UDim2.new(0,12,0,0)
                nm.BackgroundTransparency=1; nm.Text=anim.name; nm.TextColor3=C.TX
                nm.Font=Enum.Font.GothamSemibold; nm.TextSize=12; nm.TextXAlignment=Enum.TextXAlignment.Left

                local idlbl = Instance.new("TextLabel",f); idlbl.Size=UDim2.new(0,80,1,0); idlbl.Position=UDim2.new(0.5,-40,0,0)
                idlbl.BackgroundTransparency=1; idlbl.Text=tostring(anim.id); idlbl.TextColor3=C.TX3
                idlbl.Font=Enum.Font.Code; idlbl.TextSize=9.5; idlbl.TextXAlignment=Enum.TextXAlignment.Center

                local pb=Instance.new("TextButton",f); pb.Size=UDim2.new(0,50,0,26); pb.Position=UDim2.new(1,-62,0.5,-13)
                pb.BackgroundColor3=C.ACCENT; pb.Text="Play"; pb.TextColor3=C.BG
                pb.Font=Enum.Font.GothamBold; pb.TextSize=11; pb.BorderSizePixel=0; corner(pb,6)

                local fBtn=Instance.new("TextButton",f); fBtn.Size=UDim2.new(0,50,0,26); fBtn.Position=UDim2.new(1,-116,0.5,-13)
                fBtn.BackgroundColor3=C.CARD2; fBtn.Text="+ Fling"; fBtn.TextColor3=C.TX2
                fBtn.Font=Enum.Font.Gotham; fBtn.TextSize=10; fBtn.BorderSizePixel=0; corner(fBtn,6); stroke(fBtn,C.STROKE)

                local animData = anim
                pb.MouseButton1Click:Connect(function()
                    tw(pb,{BackgroundColor3=C.WHITE},TF_FAST); task.delay(0.15,function() tw(pb,{BackgroundColor3=C.ACCENT}) end)
                    playAnim(animData.id, autoFling)
                end)
                fBtn.MouseButton1Click:Connect(function()
                    tw(fBtn,{BackgroundColor3=C.ACCENT},TF_FAST); task.delay(0.15,function() tw(fBtn,{BackgroundColor3=C.CARD2}) end)
                    playAnim(animData.id, true)
                end)
            end
        end
    end

    -- Stop all
    local stopRow = Instance.new("Frame",P); stopRow.Size=UDim2.new(1,0,0,40); stopRow.BackgroundColor3=C.CARD
    stopRow.BorderSizePixel=0; corner(stopRow,8); stopRow.LayoutOrder=nextLo(); stroke(stopRow,C.STROKE)
    local stopBtn=Instance.new("TextButton",stopRow); stopBtn.Size=UDim2.new(1,-20,0,26); stopBtn.Position=UDim2.new(0,10,0.5,-13)
    stopBtn.BackgroundColor3=C.RED; stopBtn.Text="⏹  Stop Current Animation"; stopBtn.TextColor3=C.WHITE
    stopBtn.Font=Enum.Font.GothamBold; stopBtn.TextSize=12; stopBtn.BorderSizePixel=0; corner(stopBtn,6)
    stopBtn.MouseButton1Click:Connect(function()
        if animTrack then pcall(function() animTrack:Stop() end); animTrack=nil; notify("Anims","Stopped",2) end
    end)
end

-- ══════════════════════════════════════════════════════════════════════════════
--  TAB: FLING
-- ══════════════════════════════════════════════════════════════════════════════
do
    local P = tabPages["fling"]
    loCount = 0

    addInfo(P, "Fling players using BodyVelocity. Adjust force and radius below.")

    secHeader(P, "QUICK FLING")

    addButton(P, "Fling Nearest Player", "Launch closest enemy", C.ACCENT, function()
        local t = nearestPlayer(50)
        if t then flingPlayer(t); notify("Fling","Flung "..t.Name,2)
        else notify("Fling","No players nearby",2) end
    end)

    addButton(P, "Fling All Players", "Launch everyone on the server", C.RED, function()
        local myHRP = getHRP()
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                task.spawn(flingPlayer, p)
            end
        end
        notify("Fling","Flung everyone!",2)
    end)

    addButton(P, "Orbital Fling", "Spin + launch nearest in orbit direction", C.YEL, function()
        local t = nearestPlayer(30); if not t then notify("Fling","No target",2); return end
        local hrp = t.Character and t.Character:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        local myHRP = getHRP(); if not myHRP then return end
        local orb = CFrame.Angles(0,math.rad(math.random(0,360)),0) * Vector3.new(1,0.5,0)
        flingPlayer(t, orb)
        notify("Fling","Orbital fling!",2)
    end)

    secHeader(P, "SETTINGS")

    -- Force slider card
    local forceCard = Instance.new("Frame",P); forceCard.Size=UDim2.new(1,0,0,80)
    forceCard.BackgroundColor3=C.CARD; forceCard.BorderSizePixel=0; corner(forceCard,8)
    forceCard.LayoutOrder=nextLo(); stroke(forceCard,C.STROKE)
    local fHdr=Instance.new("TextLabel",forceCard); fHdr.Size=UDim2.new(1,-16,0,16); fHdr.Position=UDim2.new(0,12,0,8)
    fHdr.BackgroundTransparency=1; fHdr.Text="Fling Force: 180"; fHdr.TextColor3=C.TX
    fHdr.Font=Enum.Font.GothamSemibold; fHdr.TextSize=12; fHdr.TextXAlignment=Enum.TextXAlignment.Left
    local FORCES={{60,"Gentle"},{120,"Normal"},{180,"Strong"},{300,"Insane"},{500,"Max"}}
    local fRow=Instance.new("Frame",forceCard); fRow.Size=UDim2.new(1,-24,0,28); fRow.Position=UDim2.new(0,12,0,36)
    fRow.BackgroundTransparency=1
    local fLL=Instance.new("UIListLayout",fRow); fLL.FillDirection=Enum.FillDirection.Horizontal; fLL.Padding=UDim.new(0,6)
    for _,fv in ipairs(FORCES) do
        local ff=Instance.new("Frame",fRow); ff.Size=UDim2.new(0,54,1,0); ff.BackgroundColor3=C.CARD2; ff.BorderSizePixel=0; corner(ff,6)
        local fl=Instance.new("TextLabel",ff); fl.Size=UDim2.new(1,0,1,0); fl.BackgroundTransparency=1
        fl.Text=fv[2]; fl.TextColor3=C.TX3; fl.Font=Enum.Font.Gotham; fl.TextSize=9.5; fl.TextXAlignment=Enum.TextXAlignment.Center
        local fb=Instance.new("TextButton",ff); fb.Size=UDim2.new(1,0,1,0); fb.BackgroundTransparency=1; fb.Text=""
        local fvv=fv
        fb.MouseButton1Click:Connect(function()
            flingForce=fvv[1]; fHdr.Text="Fling Force: "..fvv[1]
            tw(ff,{BackgroundColor3=C.ACCENT},TF_SPRING); tw(fl,{TextColor3=C.BG})
            task.delay(0.4,function() tw(ff,{BackgroundColor3=C.CARD2}); tw(fl,{TextColor3=C.TX3}) end)
        end)
    end

    -- Up force
    local upCard=Instance.new("Frame",P); upCard.Size=UDim2.new(1,0,0,60)
    upCard.BackgroundColor3=C.CARD; upCard.BorderSizePixel=0; corner(upCard,8); upCard.LayoutOrder=nextLo(); stroke(upCard,C.STROKE)
    local uHdr=Instance.new("TextLabel",upCard); uHdr.Size=UDim2.new(1,-16,0,18); uHdr.Position=UDim2.new(0,12,0,8)
    uHdr.BackgroundTransparency=1; uHdr.Text="Upward Force: 40"; uHdr.TextColor3=C.TX
    uHdr.Font=Enum.Font.GothamSemibold; uHdr.TextSize=12; uHdr.TextXAlignment=Enum.TextXAlignment.Left
    local UPS={{0,"None"},{20,"Low"},{40,"Mid"},{80,"High"},{150,"Sky"}}
    local uRow=Instance.new("Frame",upCard); uRow.Size=UDim2.new(1,-24,0,24); uRow.Position=UDim2.new(0,12,0,30)
    uRow.BackgroundTransparency=1
    local uLL=Instance.new("UIListLayout",uRow); uLL.FillDirection=Enum.FillDirection.Horizontal; uLL.Padding=UDim.new(0,6)
    for _,uv in ipairs(UPS) do
        local uf=Instance.new("Frame",uRow); uf.Size=UDim2.new(0,48,1,0); uf.BackgroundColor3=C.CARD2; uf.BorderSizePixel=0; corner(uf,6)
        local ul=Instance.new("TextLabel",uf); ul.Size=UDim2.new(1,0,1,0); ul.BackgroundTransparency=1
        ul.Text=uv[2]; ul.TextColor3=C.TX3; ul.Font=Enum.Font.Gotham; ul.TextSize=9.5; ul.TextXAlignment=Enum.TextXAlignment.Center
        local ub=Instance.new("TextButton",uf); ub.Size=UDim2.new(1,0,1,0); ub.BackgroundTransparency=1; ub.Text=""
        local uvv=uv
        ub.MouseButton1Click:Connect(function()
            flingUp=uvv[1]; uHdr.Text="Upward Force: "..uvv[1]
            tw(uf,{BackgroundColor3=C.ACCENT},TF_SPRING); tw(ul,{TextColor3=C.BG})
            task.delay(0.4,function() tw(uf,{BackgroundColor3=C.CARD2}); tw(ul,{TextColor3=C.TX3}) end)
        end)
    end

    addToggle(P, "Auto-Fling on Touch", "Fling anyone who touches your character", false, function(on)
        if on then
            ac(getChar() and getChar().Touched:Connect(function(hit)
                if not hit or not hit.Parent then return end
                local p = Players:GetPlayerFromCharacter(hit.Parent)
                if p and p ~= LP then flingPlayer(p) end
            end) or {})
        end
    end)
end

-- ══════════════════════════════════════════════════════════════════════════════
--  TAB: MOVEMENT
-- ══════════════════════════════════════════════════════════════════════════════
do
    local P = tabPages["move"]
    loCount = 0
    local flyActive = false; local flyConn = nil; local flyVel = nil

    secHeader(P, "SPEED")
    local SPEEDS = {{16,"Default"},{24,"Fast"},{32,"Faster"},{50,"Sprint"},{80,"Dash"},{120,"Blur"}}
    local spCard=Instance.new("Frame",P); spCard.Size=UDim2.new(1,0,0,80)
    spCard.BackgroundColor3=C.CARD; spCard.BorderSizePixel=0; corner(spCard,8); spCard.LayoutOrder=nextLo(); stroke(spCard,C.STROKE)
    local spHdr=Instance.new("TextLabel",spCard); spHdr.Size=UDim2.new(1,-16,0,18); spHdr.Position=UDim2.new(0,12,0,6)
    spHdr.BackgroundTransparency=1; spHdr.Text="WalkSpeed: 16"; spHdr.TextColor3=C.TX; spHdr.Font=Enum.Font.GothamSemibold; spHdr.TextSize=12; spHdr.TextXAlignment=Enum.TextXAlignment.Left
    local spRow=Instance.new("Frame",spCard); spRow.Size=UDim2.new(1,-24,0,28); spRow.Position=UDim2.new(0,12,0,42); spRow.BackgroundTransparency=1
    local spLL=Instance.new("UIListLayout",spRow); spLL.FillDirection=Enum.FillDirection.Horizontal; spLL.Padding=UDim.new(0,6)
    for _,sv in ipairs(SPEEDS) do
        local sf=Instance.new("Frame",spRow); sf.Size=UDim2.new(0,50,1,0); sf.BackgroundColor3=C.CARD2; sf.BorderSizePixel=0; corner(sf,7)
        local sl=Instance.new("TextLabel",sf); sl.Size=UDim2.new(1,0,0.55,0); sl.BackgroundTransparency=1; sl.Text=tostring(sv[1]); sl.TextColor3=C.TX3; sl.Font=Enum.Font.GothamBold; sl.TextSize=10; sl.TextXAlignment=Enum.TextXAlignment.Center
        local sl2=Instance.new("TextLabel",sf); sl2.Size=UDim2.new(1,0,0.45,0); sl2.Position=UDim2.new(0,0,0.55,0); sl2.BackgroundTransparency=1; sl2.Text=sv[2]; sl2.TextColor3=C.TX3; sl2.Font=Enum.Font.Gotham; sl2.TextSize=8; sl2.TextXAlignment=Enum.TextXAlignment.Center
        local sb=Instance.new("TextButton",sf); sb.Size=UDim2.new(1,0,1,0); sb.BackgroundTransparency=1; sb.Text=""
        local svv=sv
        sb.MouseButton1Click:Connect(function()
            local h=getHum(); if h then h.WalkSpeed=svv[1] end; spHdr.Text="WalkSpeed: "..svv[1]
            tw(sf,{BackgroundColor3=C.ACCENT},TF_SPRING); tw(sl,{TextColor3=C.BG}); tw(sl2,{TextColor3=C.BG})
            task.delay(0.4,function() tw(sf,{BackgroundColor3=C.CARD2}); tw(sl,{TextColor3=C.TX3}); tw(sl2,{TextColor3=C.TX3}) end)
        end)
    end

    secHeader(P, "MOVEMENT")
    addToggle(P,"Infinite Jump","Jump again mid-air",false,function(on)
        if on then ac(UIS.JumpRequest:Connect(function() pcall(function() local h=getHum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end) end)) end
    end)
    addToggle(P,"Noclip","Phase through all parts",false,function(on)
        if on then
            ac(RS.Stepped:Connect(function()
                local c=getChar(); if not c then return end
                for _,v in pairs(c:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide=false end end
            end))
        end
    end)
    addToggle(P,"Fly  (WASD + Space/Ctrl)",  "BodyVelocity free flight",false,function(on)
        if on then
            local bv=Instance.new("BodyVelocity"); bv.MaxForce=Vector3.new(1e9,1e9,1e9); bv.Velocity=Vector3.zero
            local hrp=getHRP(); if not hrp then return end; bv.Parent=hrp; flyVel=bv
            flyConn=ac(RS.Heartbeat:Connect(function()
                local hrp2=getHRP(); if not hrp2 or not flyVel then return end
                local spd=40; local vel=Vector3.zero
                local cf=cam.CFrame
                if UIS:IsKeyDown(Enum.KeyCode.W) then vel=vel+cf.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.S) then vel=vel-cf.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.A) then vel=vel-cf.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.D) then vel=vel+cf.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then vel=vel+Vector3.new(0,1,0) end
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then vel=vel-Vector3.new(0,1,0) end
                flyVel.Velocity=vel.Magnitude>0 and vel.Unit*spd or Vector3.zero
            end))
        else
            if flyVel then flyVel:Destroy(); flyVel=nil end
            if flyConn then flyConn:Disconnect(); flyConn=nil end
        end
    end)

    secHeader(P,"TELEPORT")
    addButton(P,"TP to Nearest Player","Jump beside closest enemy",C.ACCENT,function()
        local t=nearestPlayer(999); if not t then notify("TP","No players",2); return end
        local r2=t.Character and t.Character:FindFirstChild("HumanoidRootPart")
        local hrp=getHRP(); if hrp and r2 then hrp.CFrame=r2.CFrame*CFrame.new(4,0,0); notify("TP","Teleported to "..t.Name,2) end
    end)
    addButton(P,"TP to Spawn","Teleport to spawn point",C.TX3,function()
        local hrp=getHRP(); if not hrp then return end
        local sp=workspace:FindFirstChildOfClass("SpawnLocation")
        hrp.CFrame=sp and CFrame.new(sp.Position+Vector3.new(0,5,0)) or CFrame.new(0,20,0)
        notify("TP","At spawn",2)
    end)
end

-- ══════════════════════════════════════════════════════════════════════════════
--  TAB: COMBAT
-- ══════════════════════════════════════════════════════════════════════════════
do
    local P = tabPages["combat"]
    loCount = 0

    secHeader(P,"DEFENSE")
    addToggle(P,"God Mode","Lock HP to max every frame",false,function(on)
        if on then
            ac(RS.Heartbeat:Connect(function()
                local h=getHum(); if h then pcall(function() h.Health=h.MaxHealth end) end
            end))
        end
    end)
    addToggle(P,"Anti-Knockback","Zero your velocity when hit",false,function(on)
        if on then
            ac(RS.Heartbeat:Connect(function()
                local hrp=getHRP(); if hrp then
                    if hrp.AssemblyLinearVelocity.Magnitude > 50 then
                        hrp.AssemblyLinearVelocity = Vector3.zero
                    end
                end
            end))
        end
    end)

    secHeader(P,"OFFENSE")
    addButton(P,"Fling Nearest","Quick-fling the closest player",C.ACCENT,function()
        local t=nearestPlayer(50); if t then flingPlayer(t); notify("Combat","Flung "..t.Name,2)
        else notify("Combat","No target",2) end
    end)
    addToggle(P,"Kill Aura","Set nearby player HP to 0",false,function(on)
        if on then
            ac(RS.Heartbeat:Connect(function()
                for _, p in pairs(Players:GetPlayers()) do
                    if p~=LP and p.Character then
                        local h=p.Character:FindFirstChildOfClass("Humanoid")
                        local r2=p.Character:FindFirstChild("HumanoidRootPart")
                        local hrp=getHRP()
                        if h and r2 and hrp and (r2.Position-hrp.Position).Magnitude < 12 then
                            pcall(function() h.Health=0 end)
                        end
                    end
                end
            end))
        end
    end)
    addToggle(P,"Aimbot  (hold RMB)","Lock camera to nearest player head",false,function(on)
        if on then
            ac(RS.RenderStepped:Connect(function()
                if not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
                local t=nearestPlayer(100); if not t then return end
                local head=t.Character and t.Character:FindFirstChild("Head"); if not head then return end
                cam.CFrame=CFrame.new(cam.CFrame.Position, head.Position)
            end))
        end
    end)

    secHeader(P,"ANIMATION FLING")
    addInfo(P,"Play an attack anim + fling nearest at same time:")
    addButton(P,"Punch + Fling","Punch anim → fling nearest",C.ACCENT,function()
        playAnim(742638842, true)
    end)
    addButton(P,"Kick + Fling","Kick anim → fling nearest",C.YEL,function()
        playAnim(742636889, true)
    end)
    addButton(P,"Slam + Fling","Ground slam → fling all nearby",C.RED,function()
        playAnim(616163682, false)
        task.delay(0.3,function()
            local hrp=getHRP(); if not hrp then return end
            for _, p in pairs(Players:GetPlayers()) do
                if p~=LP and p.Character then
                    local r2=p.Character:FindFirstChild("HumanoidRootPart")
                    if r2 and (r2.Position-hrp.Position).Magnitude < 20 then
                        flingPlayer(p, (r2.Position-hrp.Position).Unit + Vector3.new(0,1,0))
                    end
                end
            end
            notify("Combat","Slam flung nearby players",2)
        end)
    end)
end

-- ══════════════════════════════════════════════════════════════════════════════
--  TAB: VISUAL
-- ══════════════════════════════════════════════════════════════════════════════
do
    local P = tabPages["visual"]
    loCount = 0

    secHeader(P,"PLAYER ESP")
    addToggle(P,"Name + HP ESP","Billboard name/health overlay",false,function(on)
        local function applyESP(p)
            if p==LP then return end
            ac(p.CharacterAdded:Connect(function(c) task.wait(1); applyESP(p) end))
            local c=p.Character; if not c then return end
            if c:FindFirstChild("__esp__") then return end
            local hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
            local bg=Instance.new("BillboardGui",hrp); bg.Name="__esp__"; bg.Size=UDim2.new(0,160,0,40)
            bg.StudsOffset=Vector3.new(0,3,0); bg.AlwaysOnTop=true
            local nl=Instance.new("TextLabel",bg); nl.Size=UDim2.new(1,0,0.6,0); nl.BackgroundTransparency=1
            nl.Text=p.Name; nl.TextColor3=C.ACCENT; nl.Font=Enum.Font.GothamBold; nl.TextSize=13; nl.TextStrokeTransparency=0
            local hl=Instance.new("TextLabel",bg); hl.Size=UDim2.new(1,0,0.4,0); hl.Position=UDim2.new(0,0,0.6,0); hl.BackgroundTransparency=1
            hl.TextColor3=C.GRN; hl.Font=Enum.Font.Gotham; hl.TextSize=10; hl.TextStrokeTransparency=0
            ac(RS.Heartbeat:Connect(function()
                local h=c:FindFirstChildOfClass("Humanoid")
                if h then
                    hl.Text=string.format("HP: %d / %d", math.floor(h.Health), math.floor(h.MaxHealth))
                    local r2=c:FindFirstChild("HumanoidRootPart"); local hrp2=getHRP()
                    if r2 and hrp2 then nl.Text=p.Name.." ("..math.floor((r2.Position-hrp2.Position).Magnitude).."st)" end
                end
            end))
        end
        if on then
            for _,p in pairs(Players:GetPlayers()) do applyESP(p) end
            ac(Players.PlayerAdded:Connect(applyESP))
        else
            for _,p in pairs(Players:GetPlayers()) do
                if p.Character then
                    local bg=p.Character:FindFirstChild("HumanoidRootPart") and p.Character.HumanoidRootPart:FindFirstChild("__esp__")
                    if bg then bg:Destroy() end
                end
            end
        end
    end)
    addToggle(P,"Chams / X-Ray","Highlight players through walls",false,function(on)
        for _,p in pairs(Players:GetPlayers()) do
            if p~=LP and p.Character then
                if on then
                    if not p.Character:FindFirstChild("__chams__") then
                        local h=Instance.new("Highlight",p.Character); h.Name="__chams__"
                        h.FillColor=C.ACCENT; h.OutlineColor=C.ACCENT2
                        h.FillTransparency=0.5; h.OutlineTransparency=0
                        h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                    end
                else
                    local ch=p.Character:FindFirstChild("__chams__"); if ch then ch:Destroy() end
                end
            end
        end
    end)

    secHeader(P,"SELF")
    addToggle(P,"Fullbright","Max brightness, no shadows",false,function(on)
        local L=game:GetService("Lighting")
        L.GlobalShadows=not on; L.Brightness=on and 10 or 1
        L.Ambient=on and Color3.new(1,1,1) or Color3.new(0,0,0)
        L.OutdoorAmbient=on and Color3.new(1,1,1) or Color3.fromRGB(70,70,70)
    end)
    addToggle(P,"Invisible (self)","Make your character transparent",false,function(on)
        local c=getChar(); if not c then return end
        for _,p in pairs(c:GetDescendants()) do
            if p:IsA("BasePart") or p:IsA("Decal") then p.Transparency=on and 1 or 0 end
        end
    end)
    addButton(P,"Toggle Day/Night","Flip clock time",C.TX3,function()
        local L=game:GetService("Lighting"); L.ClockTime=L.ClockTime>6 and 0 or 14
    end)
end

-- ══════════════════════════════════════════════════════════════════════════════
--  TAB: MISC
-- ══════════════════════════════════════════════════════════════════════════════
do
    local P = tabPages["misc"]
    loCount = 0

    secHeader(P,"TOOLS")
    addButton(P,"Dump Remotes","Print all RemoteEvents to F9",C.TX3,function()
        local found={}; for _,v in pairs(game:GetDescendants()) do if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then found[#found+1]=v:GetFullName() end end
        table.sort(found); print("[SBHub] === Remotes ("..#found..") ===")
        for _,n in ipairs(found) do print("  "..n) end; notify("Misc","Dumped "..#found.." → F9",3)
    end)
    addButton(P,"Copy Load URL","Print loadstring URL to F9",C.ACCENT,function()
        local url='loadstring(game:HttpGet("https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/claude/session-UDpk7/SB_Hub.lua",true))()'
        print("[SBHub] "..url); if setclipboard then pcall(function() setclipboard(url) end) end; notify("Misc","Copied!",2)
    end)

    secHeader(P,"API STATUS")
    local apis={{"getgc",type(getgc)=="function"},{"hookmetamethod",type(hookmetamethod)=="function"},{"firesignal",type(firesignal)=="function"},{"VirtualUser",(function() local ok2,_=pcall(function() game:GetService("VirtualUser") end); return ok2 end)()},{"readfile",type(readfile)=="function"}}
    for _,a in ipairs(apis) do
        addInfo(P,(a[2] and "✓  " or "✗  ")..a[1], a[2] and C.GRN or C.RED)
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
--  DRAG
-- ══════════════════════════════════════════════════════════════════════════════
local dragging=false; local dragStart; local winStart
TBAR.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        dragging=true; dragStart=i.Position; winStart=WIN.Position
    end
end)
TBAR.InputEnded:Connect(function() dragging=false end)
UIS.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
        local d=i.Position-dragStart
        WIN.Position=UDim2.new(winStart.X.Scale,winStart.X.Offset+d.X,winStart.Y.Scale,winStart.Y.Offset+d.Y)
        GLOW.Position=WIN.Position+UDim2.new(0,-22,0,-22)
    end
end)

-- ══════════════════════════════════════════════════════════════════════════════
--  MINIMIZE / CLOSE
-- ══════════════════════════════════════════════════════════════════════════════
local minimized=false

local ORB=Instance.new("Frame",SCR); ORB.Size=UDim2.new(0,48,0,48); ORB.Position=UDim2.new(0,20,0.5,-24)
ORB.BackgroundColor3=C.ACCENT; ORB.BorderSizePixel=0; ORB.Visible=false; corner(ORB,24)
grad(ORB,C.ACCENT,C.ACCENT2,135)
local ORBL=Instance.new("TextLabel",ORB); ORBL.Size=UDim2.new(1,0,1,0); ORBL.BackgroundTransparency=1
ORBL.Text="⚡"; ORBL.TextColor3=C.BG; ORBL.Font=Enum.Font.GothamBold; ORBL.TextSize=20; ORBL.TextXAlignment=Enum.TextXAlignment.Center
local ORB_BTN=Instance.new("TextButton",ORB); ORB_BTN.Size=UDim2.new(1,0,1,0); ORB_BTN.BackgroundTransparency=1; ORB_BTN.Text=""

local orbDrag=false; local orbDS; local orbPS
ORB.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then orbDrag=true; orbDS=i.Position; orbPS=ORB.Position end end)
ORB.InputEnded:Connect(function() orbDrag=false end)
UIS.InputChanged:Connect(function(i)
    if orbDrag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
        local d=i.Position-orbDS; ORB.Position=UDim2.new(orbPS.X.Scale,orbPS.X.Offset+d.X,orbPS.Y.Scale,orbPS.Y.Offset+d.Y)
    end
end)

local function setMinimized(v)
    minimized=v
    if v then
        tw(WIN,{Size=UDim2.new(0,400,0,0),BackgroundTransparency=1},TF_SLOW)
        tw(GLOW,{ImageTransparency=1},TF_MED)
        task.delay(0.35,function() WIN.Visible=false; GLOW.Visible=false end)
        ORB.Visible=true; tw(ORB,{Size=UDim2.new(0,48,0,48),BackgroundTransparency=0},TF_SPRING)
    else
        WIN.Visible=true; GLOW.Visible=true
        WIN.Size=UDim2.new(0,400,0,0); WIN.BackgroundTransparency=1
        tw(WIN,{Size=UDim2.new(0,400,0,560),BackgroundTransparency=0},TF_SLOW)
        tw(GLOW,{ImageTransparency=0.65},TF_MED)
        tw(ORB,{Size=UDim2.new(0,0,0,0)},TF_MED)
        task.delay(0.2,function() ORB.Visible=false end)
    end
end

MINBTN.MouseButton1Click:Connect(function() setMinimized(true) end)
ORB_BTN.MouseButton1Click:Connect(function() if not orbDrag then setMinimized(false) end end)
CLOSEBTN.MouseButton1Click:Connect(function()
    tw(WIN,{BackgroundTransparency=1,Size=UDim2.new(0,400,0,0)},TF_MED)
    tw(GLOW,{ImageTransparency=1},TF_MED)
    task.delay(0.3,function() SCR:Destroy() end)
end)

UIS.InputBegan:Connect(function(i,gpe)
    if not gpe and (i.KeyCode==Enum.KeyCode.Insert or i.KeyCode==Enum.KeyCode.RightShift) then
        setMinimized(not minimized)
    end
end)

-- ── Open animation ────────────────────────────────────────────────────────────
WIN.Size=UDim2.new(0,400,0,0); WIN.BackgroundTransparency=1
task.wait(0.05); WIN.Visible=true
tw(WIN,{Size=UDim2.new(0,400,0,560),BackgroundTransparency=0},TF_SLOW)
task.wait(0.1); showTab("anims")
notify("SB Hub","v1.0 loaded  ·  RShift to hide",3)

end)
if not ok then
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification",{Title="SB Hub Error",Text=tostring(err):sub(1,120),Duration=8})
    end)
    warn("[SBHub] STARTUP ERROR:", err)
end
