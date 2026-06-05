--[[
    RequireHub — type any require expression and execute it
    e.g.  require(12345678).MorphMonster("Rapbatrat","locust")
    RightShift = show / hide
--]]

local ok, err = pcall(function()

local Players  = game:GetService("Players")
local TweenSvc = game:GetService("TweenService")
local UIS      = game:GetService("UserInputService")
local LP       = Players.LocalPlayer
local PGui     = LP:WaitForChild("PlayerGui", 10)
if not PGui then return end

pcall(function()
    local o = PGui:FindFirstChild("__REQHUB__")
    if o then o:Destroy() end
end)

-- ─── Theme ────────────────────────────────────────────────────────────────────
local C = {
    BG     = Color3.fromRGB(8,   8,  14),
    PANEL  = Color3.fromRGB(14,  14, 24),
    CARD   = Color3.fromRGB(20,  20, 34),
    HOVER  = Color3.fromRGB(28,  28, 46),
    BORDER = Color3.fromRGB(44,  44, 72),
    BLIGHT = Color3.fromRGB(80,  50,160),
    ACC    = Color3.fromRGB(110, 60,255),
    ACC2   = Color3.fromRGB(60, 130,255),
    TEXT   = Color3.fromRGB(215, 215,248),
    MUTED  = Color3.fromRGB(90,  90, 145),
    DIM    = Color3.fromRGB(50,  50,  88),
    GREEN  = Color3.fromRGB(50,  215,110),
    RED    = Color3.fromRGB(240,  65,  88),
    YELLOW = Color3.fromRGB(255, 200,  55),
    WHITE  = Color3.fromRGB(255, 255, 255),
    BLACK  = Color3.fromRGB(0,   0,   0),
}

local function ti(t,s,d)
    return TweenInfo.new(t,Enum.EasingStyle[s or "Quint"],Enum.EasingDirection[d or "Out"])
end
local function tw(o,p,i) TweenSvc:Create(o,i or ti(0.3),p):Play() end

local function Frm(p)
    local f=Instance.new("Frame")
    for k,v in pairs(p or {})do f[k]=v end; return f
end
local function Lbl(p)
    local l=Instance.new("TextLabel")
    l.BackgroundTransparency=1; l.Font=Enum.Font.GothamBold
    l.TextColor3=C.TEXT; l.TextXAlignment=Enum.TextXAlignment.Left
    for k,v in pairs(p or {})do l[k]=v end; return l
end
local function Btn(p)
    local b=Instance.new("TextButton")
    b.AutoButtonColor=false; b.Font=Enum.Font.GothamBold
    b.TextColor3=C.WHITE; b.TextXAlignment=Enum.TextXAlignment.Center
    for k,v in pairs(p or {})do b[k]=v end; return b
end
local function corner(f,r)
    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 8); c.Parent=f
end
local function stroke(f,col,thick)
    local s=Instance.new("UIStroke"); s.Color=col or C.BORDER; s.Thickness=thick or 1; s.Parent=f; return s
end
local function hov(b,n,h)
    b.MouseEnter:Connect(function() tw(b,{BackgroundColor3=h}) end)
    b.MouseLeave:Connect(function() tw(b,{BackgroundColor3=n}) end)
end

-- ─── History (last 8 entries) ─────────────────────────────────────────────────
local history = {}
local function pushHistory(txt)
    for i,v in ipairs(history) do
        if v == txt then table.remove(history,i); break end
    end
    table.insert(history, 1, txt)
    if #history > 8 then table.remove(history) end
end

-- ─── Screen GUI ───────────────────────────────────────────────────────────────
local SG = Instance.new("ScreenGui")
SG.Name="__REQHUB__"; SG.ResetOnSpawn=false
SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
SG.DisplayOrder=998; SG.IgnoreGuiInset=true; SG.Parent=PGui

-- ─── Intro ────────────────────────────────────────────────────────────────────
local INTRO = Frm{Size=UDim2.fromScale(1,1),BackgroundColor3=C.BLACK,
    BackgroundTransparency=0,ZIndex=100,Parent=SG}

local ORB = Frm{Size=UDim2.fromOffset(0,0),AnchorPoint=Vector2.new(0.5,0.5),
    Position=UDim2.fromScale(0.5,0.44),BackgroundTransparency=1,ZIndex=101,Parent=INTRO}
local function ring(sz,col,tr)
    local f=Frm{Size=UDim2.fromOffset(sz,sz),BackgroundColor3=col,
        BackgroundTransparency=tr,ZIndex=101,Parent=ORB}; corner(f,sz/2); return f
end
local R1=ring(100,C.ACC,1); local R2=ring(72,C.ACC2,1); local R3=ring(44,C.WHITE,1)
Lbl{Text="R",Font=Enum.Font.GothamBlack,TextSize=22,TextColor3=C.ACC,
    TextXAlignment=Enum.TextXAlignment.Center,Size=UDim2.fromOffset(44,44),
    AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),ZIndex=103,Parent=ORB}
local IT=Lbl{Text="RequireHub",Font=Enum.Font.GothamBlack,TextSize=28,
    TextColor3=C.WHITE,TextXAlignment=Enum.TextXAlignment.Center,
    Size=UDim2.new(1,0,0,36),AnchorPoint=Vector2.new(0.5,0),
    Position=UDim2.new(0.5,0,0.575,0),TextTransparency=1,ZIndex=101,Parent=INTRO}
local IS=Lbl{Text="type a require expression · press run",Font=Enum.Font.Gotham,TextSize=12,
    TextColor3=C.MUTED,TextXAlignment=Enum.TextXAlignment.Center,
    Size=UDim2.new(1,0,0,18),AnchorPoint=Vector2.new(0.5,0),
    Position=UDim2.new(0.5,0,0.66,0),TextTransparency=1,ZIndex=101,Parent=INTRO}

task.spawn(function()
    task.wait(0.2)
    tw(ORB,{Size=UDim2.fromOffset(112,112)},ti(0.45,"Back"))
    task.wait(0.1); tw(R1,{BackgroundTransparency=0.55},ti(0.4))
    task.wait(0.06); tw(R2,{BackgroundTransparency=0.35},ti(0.4))
    task.wait(0.06); tw(R3,{BackgroundTransparency=0},ti(0.35))
    task.wait(0.15); tw(ORB,{Size=UDim2.fromOffset(100,100)},ti(0.2))
    task.wait(0.2); tw(IT,{TextTransparency=0},ti(0.4))
    task.wait(0.14); tw(IS,{TextTransparency=0},ti(0.4))
    for _=1,2 do
        task.wait(0.5); tw(R1,{BackgroundTransparency=0.2},ti(0.5))
        task.wait(0.5); tw(R1,{BackgroundTransparency=0.6},ti(0.5))
    end
    task.wait(0.3)
    tw(INTRO,{BackgroundTransparency=1},ti(0.5))
    tw(IT,{TextTransparency=1},ti(0.3)); tw(IS,{TextTransparency=1},ti(0.3))
    tw(R1,{BackgroundTransparency=1},ti(0.4)); tw(R2,{BackgroundTransparency=1},ti(0.4))
    tw(R3,{BackgroundTransparency=1},ti(0.4))
    task.wait(0.55); INTRO:Destroy()
end)

-- ─── Window ───────────────────────────────────────────────────────────────────
local WIN = Frm{Name="Window",Size=UDim2.fromOffset(0,0),BackgroundTransparency=1,
    AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
    BorderSizePixel=0,ZIndex=1,Parent=SG}
corner(WIN,12); stroke(WIN,C.BORDER,1)

task.spawn(function()
    task.wait(1.6)
    WIN.BackgroundColor3=C.BG
    tw(WIN,{Size=UDim2.fromOffset(395,310),BackgroundTransparency=0},ti(0.45,"Back"))
    task.wait(0.1); tw(WIN,{Size=UDim2.fromOffset(375,294)},ti(0.22))
end)

-- ─── Header ───────────────────────────────────────────────────────────────────
local HDR = Frm{Size=UDim2.new(1,0,0,40),BackgroundColor3=C.PANEL,
    BorderSizePixel=0,ZIndex=2,Parent=WIN}
corner(HDR,12)
Frm{Size=UDim2.new(1,0,0,12),Position=UDim2.new(0,0,1,-12),
    BackgroundColor3=C.PANEL,BorderSizePixel=0,ZIndex=2,Parent=HDR}
Frm{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,0),
    BackgroundColor3=C.BLIGHT,BorderSizePixel=0,ZIndex=3,Parent=HDR}

local LORB=Frm{Size=UDim2.fromOffset(26,26),AnchorPoint=Vector2.new(0,0.5),
    Position=UDim2.new(0,9,0.5,0),BackgroundColor3=C.ACC,BorderSizePixel=0,ZIndex=3,Parent=HDR}
corner(LORB,13)
task.spawn(function()
    while LORB.Parent do
        tw(LORB,{BackgroundColor3=C.ACC2},ti(1.1)); task.wait(1.1)
        tw(LORB,{BackgroundColor3=C.ACC}, ti(1.1)); task.wait(1.1)
    end
end)
Lbl{Text="R",Font=Enum.Font.GothamBlack,TextSize=14,TextColor3=C.WHITE,
    TextXAlignment=Enum.TextXAlignment.Center,Size=UDim2.fromScale(1,1),ZIndex=4,Parent=LORB}
Lbl{Text="RequireHub",Font=Enum.Font.GothamBlack,TextSize=14,
    TextColor3=C.TEXT,Size=UDim2.new(0,160,1,0),Position=UDim2.new(0,42,0,0),ZIndex=3,Parent=HDR}

local HMIN=Btn{Text="—",Font=Enum.Font.GothamBlack,TextSize=14,TextColor3=C.MUTED,
    Size=UDim2.fromOffset(26,26),AnchorPoint=Vector2.new(1,0.5),
    Position=UDim2.new(1,-34,0.5,0),BackgroundColor3=C.CARD,BorderSizePixel=0,ZIndex=3,Parent=HDR}
corner(HMIN,6); hov(HMIN,C.CARD,C.HOVER)

local HCLOSE=Btn{Text="×",Font=Enum.Font.GothamBlack,TextSize=18,
    TextColor3=C.RED,Size=UDim2.fromOffset(26,26),AnchorPoint=Vector2.new(1,0.5),
    Position=UDim2.new(1,-4,0.5,0),BackgroundColor3=C.CARD,BorderSizePixel=0,ZIndex=3,Parent=HDR}
corner(HCLOSE,6); hov(HCLOSE,C.CARD,Color3.fromRGB(55,16,20))
HCLOSE.MouseButton1Click:Connect(function()
    tw(WIN,{Size=UDim2.fromOffset(0,0),BackgroundTransparency=1},ti(0.25,"Quint","In"))
    task.wait(0.3); SG:Destroy()
end)

-- ─── Body ────────────────────────────────────────────────────────────────────
local BODY=Frm{Size=UDim2.new(1,0,1,-40),Position=UDim2.new(0,0,0,40),
    BackgroundTransparency=1,ZIndex=1,Parent=WIN}

-- Input label
Lbl{Text="Expression",Font=Enum.Font.GothamBold,TextSize=10,TextColor3=C.MUTED,
    Size=UDim2.new(1,-24,0,12),Position=UDim2.new(0,12,0,10),ZIndex=2,Parent=BODY}

-- Input box
local IWRAP=Frm{Size=UDim2.new(1,-24,0,58),Position=UDim2.new(0,12,0,24),
    BackgroundColor3=C.CARD,BorderSizePixel=0,ZIndex=2,Parent=BODY}
corner(IWRAP,8)
local IBORDER = stroke(IWRAP,C.BORDER,1)

local INP=Instance.new("TextBox")
INP.PlaceholderText='require(12345678).Method("arg1","arg2")'
INP.Font=Enum.Font.Code
INP.TextSize=13
INP.TextColor3=C.TEXT
INP.PlaceholderColor3=C.DIM
INP.BackgroundTransparency=1
INP.BorderSizePixel=0
INP.ClearTextOnFocus=false
INP.TextXAlignment=Enum.TextXAlignment.Left
INP.TextWrapped=true
INP.MultiLine=true
INP.Size=UDim2.new(1,0,1,0)
INP.ZIndex=3
INP.Parent=IWRAP

local p=Instance.new("UIPadding"); p.PaddingLeft=UDim.new(0,10)
p.PaddingRight=UDim.new(0,10); p.PaddingTop=UDim.new(0,8)
p.PaddingBottom=UDim.new(0,8); p.Parent=IWRAP

INP.Focused:Connect(function()
    tw(IWRAP,{BackgroundColor3=C.HOVER})
    IBORDER.Color=C.BLIGHT
end)
INP.FocusLost:Connect(function()
    tw(IWRAP,{BackgroundColor3=C.CARD})
    IBORDER.Color=C.BORDER
end)

-- Run button
local RBTN=Btn{Text="▶  Run",Font=Enum.Font.GothamBlack,TextSize=14,TextColor3=C.WHITE,
    Size=UDim2.new(1,-24,0,38),Position=UDim2.new(0,12,0,92),
    BackgroundColor3=C.ACC,BorderSizePixel=0,ZIndex=2,Parent=BODY}
corner(RBTN,9); hov(RBTN,C.ACC,Color3.fromRGB(135,80,255))

-- Status line
local STAT=Lbl{Text="",Font=Enum.Font.Code,TextSize=11,TextColor3=C.MUTED,
    TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,
    Size=UDim2.new(1,-24,0,14),Position=UDim2.new(0,12,0,138),ZIndex=2,Parent=BODY}

-- History label
Lbl{Text="RECENT",Font=Enum.Font.GothamBold,TextSize=9,TextColor3=C.DIM,
    Size=UDim2.new(1,-24,0,12),Position=UDim2.new(0,12,0,158),ZIndex=2,Parent=BODY}

-- History scroll
local HSCROLL=Instance.new("ScrollingFrame")
HSCROLL.Size=UDim2.new(1,-24,0,100)
HSCROLL.Position=UDim2.new(0,12,0,172)
HSCROLL.BackgroundTransparency=1; HSCROLL.BorderSizePixel=0
HSCROLL.ScrollBarThickness=2; HSCROLL.ScrollBarImageColor3=C.ACC
HSCROLL.CanvasSize=UDim2.new(0,0,0,0)
HSCROLL.AutomaticCanvasSize=Enum.AutomaticSize.Y
HSCROLL.ZIndex=2; HSCROLL.Parent=BODY
local HL=Instance.new("UIListLayout")
HL.FillDirection=Enum.FillDirection.Vertical
HL.SortOrder=Enum.SortOrder.LayoutOrder
HL.Padding=UDim.new(0,4); HL.Parent=HSCROLL

-- ─── Build history row ───────────────────────────────────────────────────────
local function buildHistRow(txt, idx)
    local ROW=Btn{Text="",Size=UDim2.new(1,0,0,26),BackgroundColor3=C.CARD,
        BorderSizePixel=0,LayoutOrder=idx,ZIndex=3,Parent=HSCROLL}
    corner(ROW,6)

    Lbl{Text=txt,Font=Enum.Font.Code,TextSize=11,TextColor3=C.MUTED,
        TextTruncate=Enum.TextTruncate.AtEnd,
        Size=UDim2.new(1,-40,1,0),Position=UDim2.new(0,8,0,0),ZIndex=4,Parent=ROW}

    local RERUN=Btn{Text="▶",Font=Enum.Font.GothamBold,TextSize=11,TextColor3=C.ACC,
        Size=UDim2.fromOffset(28,20),AnchorPoint=Vector2.new(1,0.5),
        Position=UDim2.new(1,-4,0.5,0),BackgroundColor3=C.HOVER,
        BorderSizePixel=0,ZIndex=4,Parent=ROW}
    corner(RERUN,5); hov(RERUN,C.HOVER,C.ACTIVE)

    hov(ROW,C.CARD,C.HOVER)
    ROW.MouseButton1Click:Connect(function() INP.Text=txt end)
    RERUN.MouseButton1Click:Connect(function() INP.Text=txt end)
    return ROW
end

local histRows = {}
local function refreshHistory()
    for _,r in ipairs(histRows) do r:Destroy() end
    histRows={}
    for i,v in ipairs(history) do
        table.insert(histRows, buildHistRow(v,i))
    end
end

-- ─── Execute ─────────────────────────────────────────────────────────────────
local function doRun()
    local raw = INP.Text:match("^%s*(.-)%s*$")
    if raw=="" then
        STAT.TextColor3=C.RED; STAT.Text="nothing to run"
        return
    end

    RBTN.Text="Running..."
    RBTN.BackgroundColor3=C.YELLOW
    STAT.TextColor3=C.MUTED; STAT.Text=raw

    -- Wrap as statement: if it starts with "require" or has no assignment, add return
    local code = raw
    local fn, ce = loadstring(code)
    if not fn then
        -- try wrapping as expression
        fn, ce = loadstring("return "..code)
    end

    local ok2, e2
    if fn then
        ok2, e2 = pcall(fn)
    else
        ok2, e2 = false, ce
    end

    if ok2 then
        RBTN.Text="✓  Done"
        RBTN.BackgroundColor3=C.GREEN
        STAT.TextColor3=C.GREEN; STAT.Text="✓  "..raw
        pushHistory(raw); refreshHistory()
    else
        RBTN.Text="✗  Error"
        RBTN.BackgroundColor3=C.RED
        local msg=tostring(e2):gsub("^.*:%d+: ","")
        STAT.TextColor3=C.RED; STAT.Text="✗  "..msg
        warn("[RequireHub] "..tostring(e2))
    end

    task.wait(2.5)
    RBTN.Text="▶  Run"
    RBTN.BackgroundColor3=C.ACC
end

RBTN.MouseButton1Click:Connect(doRun)
INP.FocusLost:Connect(function(enter) if enter then doRun() end end)

-- ─── Status bar ───────────────────────────────────────────────────────────────
local SB=Frm{Size=UDim2.new(1,0,0,20),Position=UDim2.new(0,0,1,-20),
    BackgroundColor3=C.PANEL,BorderSizePixel=0,ZIndex=3,Parent=WIN}
corner(SB,12)
Frm{Size=UDim2.new(1,0,0,10),BackgroundColor3=C.PANEL,
    BorderSizePixel=0,ZIndex=3,Parent=SB}
Lbl{Text="RightShift to toggle",Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.DIM,
    TextXAlignment=Enum.TextXAlignment.Center,
    Size=UDim2.fromScale(1,1),ZIndex=4,Parent=SB}

-- ─── Drag ─────────────────────────────────────────────────────────────────────
local drag,ds,ws=false,nil,nil
HDR.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1
    or i.UserInputType==Enum.UserInputType.Touch then
        drag=true; ds=i.Position; ws=WIN.Position
    end
end)
HDR.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1
    or i.UserInputType==Enum.UserInputType.Touch then drag=false end
end)
UIS.InputChanged:Connect(function(i)
    if not drag then return end
    if i.UserInputType==Enum.UserInputType.MouseMovement
    or i.UserInputType==Enum.UserInputType.Touch then
        local d=i.Position-ds
        WIN.Position=UDim2.new(ws.X.Scale,ws.X.Offset+d.X,ws.Y.Scale,ws.Y.Offset+d.Y)
    end
end)

-- ─── Minimize ─────────────────────────────────────────────────────────────────
local mini=false
HMIN.MouseButton1Click:Connect(function()
    mini=not mini
    if mini then
        tw(WIN,{Size=UDim2.fromOffset(375,40)},ti(0.28)); HMIN.Text="+"
    else
        tw(WIN,{Size=UDim2.fromOffset(375,294)},ti(0.38,"Back")); HMIN.Text="—"
    end
end)

-- ─── RightShift toggle ────────────────────────────────────────────────────────
local vis=true
UIS.InputBegan:Connect(function(i,gp)
    if gp then return end
    if i.KeyCode==Enum.KeyCode.RightShift then
        vis=not vis
        if vis then
            WIN.Visible=true
            tw(WIN,{Size=UDim2.fromOffset(375,294),BackgroundTransparency=0},ti(0.32,"Back"))
        else
            tw(WIN,{Size=UDim2.fromOffset(0,0),BackgroundTransparency=1},ti(0.22,"Quint","In"))
            task.delay(0.28,function() WIN.Visible=false end)
        end
    end
end)

end)
if not ok then warn("[RequireHub] "..tostring(err)) end
