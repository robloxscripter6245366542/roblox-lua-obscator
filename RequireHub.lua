--[[
    RequireHub
    Box 1: Module asset ID   e.g. 75834950186546
    Box 2: What to call      e.g. .MorphMonster("Rapbatrat","locust")
    Runs: require(ID) + call
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
local function Inp(p)
    local i=Instance.new("TextBox")
    i.Font=Enum.Font.Code; i.TextColor3=C.TEXT
    i.PlaceholderColor3=C.DIM; i.BackgroundTransparency=1
    i.ClearTextOnFocus=false; i.BorderSizePixel=0
    i.TextXAlignment=Enum.TextXAlignment.Left
    for k,v in pairs(p or {})do i[k]=v end; return i
end
local function corner(f,r)
    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 8); c.Parent=f
end
local function stroke(f,col,thick)
    local s=Instance.new("UIStroke"); s.Color=col or C.BORDER
    s.Thickness=thick or 1; s.Parent=f; return s
end
local function hov(b,n,h)
    b.MouseEnter:Connect(function() tw(b,{BackgroundColor3=h}) end)
    b.MouseLeave:Connect(function() tw(b,{BackgroundColor3=n}) end)
end
local function inputBox(parent, yPos, labelText, placeholder, isCode)
    local WRAP=Frm{Size=UDim2.new(1,-24,0,36),Position=UDim2.new(0,12,0,yPos),
        BackgroundColor3=C.CARD,BorderSizePixel=0,ZIndex=2,Parent=parent}
    corner(WRAP,8)
    local BD=stroke(WRAP,C.BORDER,1)
    -- label pill
    local PILL=Frm{Size=UDim2.fromOffset(0,18),AnchorPoint=Vector2.new(0,0.5),
        Position=UDim2.new(0,8,0.5,0),BackgroundColor3=C.PANEL,BorderSizePixel=0,ZIndex=3,Parent=WRAP}
    corner(PILL,9)
    local PLBL=Lbl{Text=labelText,Font=Enum.Font.GothamBold,TextSize=10,
        TextColor3=C.ACC,TextXAlignment=Enum.TextXAlignment.Center,
        Size=UDim2.fromScale(1,1),ZIndex=4,Parent=PILL}
    -- auto-size pill width
    local ts=Instance.new("TextService")
    local tw2=ts:GetTextSize(labelText,10,Enum.Font.GothamBold,Vector2.new(9999,9999))
    PILL.Size=UDim2.fromOffset(tw2.X+14,18)
    local pillW=tw2.X+14
    -- text input
    local BOX=Inp{PlaceholderText=placeholder,
        TextSize=isCode and 12 or 13,
        Size=UDim2.new(1,-(pillW+18),1,0),
        Position=UDim2.new(0,pillW+10,0,0),
        ZIndex=3,Parent=WRAP}
    BOX.Focused:Connect(function()  tw(WRAP,{BackgroundColor3=C.HOVER}); BD.Color=C.BLIGHT end)
    BOX.FocusLost:Connect(function() tw(WRAP,{BackgroundColor3=C.CARD});  BD.Color=C.BORDER end)
    return BOX
end

-- ─── Screen GUI ───────────────────────────────────────────────────────────────
local SG=Instance.new("ScreenGui")
SG.Name="__REQHUB__"; SG.ResetOnSpawn=false
SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
SG.DisplayOrder=998; SG.IgnoreGuiInset=true; SG.Parent=PGui

-- ─── Intro ────────────────────────────────────────────────────────────────────
local INTRO=Frm{Size=UDim2.fromScale(1,1),BackgroundColor3=C.BLACK,
    BackgroundTransparency=0,ZIndex=100,Parent=SG}
local ORB=Frm{Size=UDim2.fromOffset(0,0),AnchorPoint=Vector2.new(0.5,0.5),
    Position=UDim2.fromScale(0.5,0.43),BackgroundTransparency=1,ZIndex=101,Parent=INTRO}
local function ring(sz,col,tr)
    local f=Frm{Size=UDim2.fromOffset(sz,sz),BackgroundColor3=col,
        BackgroundTransparency=tr,ZIndex=101,Parent=ORB}; corner(f,sz/2); return f
end
local R1=ring(96,C.ACC,1); local R2=ring(68,C.ACC2,1); local R3=ring(42,C.WHITE,1)
Lbl{Text="R",Font=Enum.Font.GothamBlack,TextSize=21,TextColor3=C.ACC,
    TextXAlignment=Enum.TextXAlignment.Center,Size=UDim2.fromOffset(42,42),
    AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),ZIndex=103,Parent=ORB}
local IT=Lbl{Text="RequireHub",Font=Enum.Font.GothamBlack,TextSize=27,
    TextColor3=C.WHITE,TextXAlignment=Enum.TextXAlignment.Center,
    Size=UDim2.new(1,0,0,34),AnchorPoint=Vector2.new(0.5,0),
    Position=UDim2.new(0.5,0,0.57,0),TextTransparency=1,ZIndex=101,Parent=INTRO}
local IS=Lbl{Text="module id · name · run",Font=Enum.Font.Gotham,TextSize=12,
    TextColor3=C.MUTED,TextXAlignment=Enum.TextXAlignment.Center,
    Size=UDim2.new(1,0,0,18),AnchorPoint=Vector2.new(0.5,0),
    Position=UDim2.new(0.5,0,0.655,0),TextTransparency=1,ZIndex=101,Parent=INTRO}

task.spawn(function()
    task.wait(0.2)
    tw(ORB,{Size=UDim2.fromOffset(106,106)},ti(0.44,"Back"))
    task.wait(0.1);  tw(R1,{BackgroundTransparency=0.55},ti(0.4))
    task.wait(0.06); tw(R2,{BackgroundTransparency=0.35},ti(0.4))
    task.wait(0.06); tw(R3,{BackgroundTransparency=0},ti(0.35))
    task.wait(0.15); tw(ORB,{Size=UDim2.fromOffset(96,96)},ti(0.2))
    task.wait(0.2);  tw(IT,{TextTransparency=0},ti(0.4))
    task.wait(0.14); tw(IS,{TextTransparency=0},ti(0.35))
    for _=1,2 do
        task.wait(0.45); tw(R1,{BackgroundTransparency=0.2},ti(0.5))
        task.wait(0.5);  tw(R1,{BackgroundTransparency=0.6},ti(0.5))
    end
    task.wait(0.3)
    tw(INTRO,{BackgroundTransparency=1},ti(0.5))
    tw(IT,{TextTransparency=1},ti(0.3)); tw(IS,{TextTransparency=1},ti(0.3))
    tw(R1,{BackgroundTransparency=1},ti(0.4)); tw(R2,{BackgroundTransparency=1},ti(0.4))
    tw(R3,{BackgroundTransparency=1},ti(0.4))
    task.wait(0.55); INTRO:Destroy()
end)

-- ─── Window ───────────────────────────────────────────────────────────────────
local WIN=Frm{Name="Window",Size=UDim2.fromOffset(0,0),BackgroundTransparency=1,
    AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
    BorderSizePixel=0,ZIndex=1,Parent=SG}
corner(WIN,12); stroke(WIN,C.BORDER,1)

task.spawn(function()
    task.wait(1.6)
    WIN.BackgroundColor3=C.BG
    tw(WIN,{Size=UDim2.fromOffset(370,262),BackgroundTransparency=0},ti(0.45,"Back"))
    task.wait(0.1); tw(WIN,{Size=UDim2.fromOffset(352,248)},ti(0.22))
end)

-- ─── Header ───────────────────────────────────────────────────────────────────
local HDR=Frm{Size=UDim2.new(1,0,0,40),BackgroundColor3=C.PANEL,
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

local HCLOSE=Btn{Text="×",Font=Enum.Font.GothamBlack,TextSize=18,TextColor3=C.RED,
    Size=UDim2.fromOffset(26,26),AnchorPoint=Vector2.new(1,0.5),
    Position=UDim2.new(1,-4,0.5,0),BackgroundColor3=C.CARD,BorderSizePixel=0,ZIndex=3,Parent=HDR}
corner(HCLOSE,6); hov(HCLOSE,C.CARD,Color3.fromRGB(55,16,20))
HCLOSE.MouseButton1Click:Connect(function()
    tw(WIN,{Size=UDim2.fromOffset(0,0),BackgroundTransparency=1},ti(0.25,"Quint","In"))
    task.wait(0.3); SG:Destroy()
end)

-- ─── Body ────────────────────────────────────────────────────────────────────
local BODY=Frm{Size=UDim2.new(1,0,1,-40),Position=UDim2.new(0,0,0,40),
    BackgroundTransparency=1,ZIndex=1,Parent=WIN}

-- Box 1: Module ID
local MOD_INP = inputBox(BODY, 10, "require(", "75834950186546", false)
MOD_INP.TextSize = 14

-- Box 2: Name / method call
local NAME_INP = inputBox(BODY, 56, "call", '.MorphMonster("Rapbatrat","locust")', true)

-- Preview line showing combined expression
local PREVIEW=Lbl{Text='',Font=Enum.Font.Code,TextSize=10,TextColor3=C.DIM,
    TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,
    Size=UDim2.new(1,-24,0,13),Position=UDim2.new(0,12,0,100),ZIndex=2,Parent=BODY}

local function updatePreview()
    local id = MOD_INP.Text:match("^%s*(.-)%s*$")
    local call = NAME_INP.Text:match("^%s*(.-)%s*$")
    if id=="" then PREVIEW.Text=""; return end
    PREVIEW.Text = "require("..id..")"..call
end
MOD_INP:GetPropertyChangedSignal("Text"):Connect(updatePreview)
NAME_INP:GetPropertyChangedSignal("Text"):Connect(updatePreview)

-- Run button
local RBTN=Btn{Text="▶  Run",Font=Enum.Font.GothamBlack,TextSize=14,TextColor3=C.WHITE,
    Size=UDim2.new(1,-24,0,38),Position=UDim2.new(0,12,0,120),
    BackgroundColor3=C.ACC,BorderSizePixel=0,ZIndex=2,Parent=BODY}
corner(RBTN,9); hov(RBTN,C.ACC,Color3.fromRGB(135,80,255))

-- Status
local STAT=Lbl{Text="",Font=Enum.Font.Code,TextSize=11,TextColor3=C.MUTED,
    TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,
    Size=UDim2.new(1,-24,0,14),Position=UDim2.new(0,12,0,166),ZIndex=2,Parent=BODY}

-- ─── Run logic ────────────────────────────────────────────────────────────────
local function doRun()
    local rawId   = MOD_INP.Text:match("^%s*(.-)%s*$")
    local rawCall = NAME_INP.Text:match("^%s*(.-)%s*$")

    local assetId = tonumber(rawId)
    if not assetId or assetId <= 0 then
        STAT.TextColor3=C.RED; STAT.Text="✗  enter a valid module ID in the top box"
        tw(MOD_INP.Parent,{BackgroundColor3=Color3.fromRGB(40,12,16)},ti(0.1))
        task.wait(0.15); tw(MOD_INP.Parent,{BackgroundColor3=C.CARD})
        return
    end

    local expr = "require("..assetId..")"..rawCall
    RBTN.Text="Running..."; RBTN.BackgroundColor3=C.YELLOW
    STAT.TextColor3=C.MUTED; STAT.Text=expr

    local fn, ce = loadstring(expr)
    if not fn then fn, ce = loadstring("return "..expr) end

    local ok2, e2
    if fn then
        ok2, e2 = pcall(fn)
    else
        ok2, e2 = false, ce
    end

    if ok2 then
        RBTN.Text="✓  Done"; RBTN.BackgroundColor3=C.GREEN
        STAT.TextColor3=C.GREEN; STAT.Text="✓  "..expr
    else
        RBTN.Text="✗  Error"; RBTN.BackgroundColor3=C.RED
        local msg=tostring(e2):gsub("^.*:%d+: ","")
        STAT.TextColor3=C.RED; STAT.Text="✗  "..msg
        warn("[RequireHub] "..tostring(e2))
    end
    task.wait(2.5); RBTN.Text="▶  Run"; RBTN.BackgroundColor3=C.ACC
end

RBTN.MouseButton1Click:Connect(doRun)
-- Enter on either box runs it
MOD_INP.FocusLost:Connect(function(enter) if enter then NAME_INP:CaptureFocus() end end)
NAME_INP.FocusLost:Connect(function(enter) if enter then doRun() end end)

-- ─── Status bar ───────────────────────────────────────────────────────────────
local SB=Frm{Size=UDim2.new(1,0,0,20),Position=UDim2.new(0,0,1,-20),
    BackgroundColor3=C.PANEL,BorderSizePixel=0,ZIndex=3,Parent=WIN}
corner(SB,12)
Frm{Size=UDim2.new(1,0,0,10),BackgroundColor3=C.PANEL,BorderSizePixel=0,ZIndex=3,Parent=SB}
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

-- ─── Minimize / toggle ────────────────────────────────────────────────────────
local mini=false
HMIN.MouseButton1Click:Connect(function()
    mini=not mini
    if mini then tw(WIN,{Size=UDim2.fromOffset(352,40)},ti(0.28)); HMIN.Text="+"
    else tw(WIN,{Size=UDim2.fromOffset(352,248)},ti(0.38,"Back")); HMIN.Text="—" end
end)

local vis=true
UIS.InputBegan:Connect(function(i,gp)
    if gp then return end
    if i.KeyCode==Enum.KeyCode.RightShift then
        vis=not vis
        if vis then
            WIN.Visible=true
            tw(WIN,{Size=UDim2.fromOffset(352,248),BackgroundTransparency=0},ti(0.32,"Back"))
        else
            tw(WIN,{Size=UDim2.fromOffset(0,0),BackgroundTransparency=1},ti(0.22,"Quint","In"))
            task.delay(0.28,function() WIN.Visible=false end)
        end
    end
end)

end)
if not ok then warn("[RequireHub] "..tostring(err)) end
