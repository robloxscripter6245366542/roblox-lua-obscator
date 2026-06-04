-- ╔══════════════════════════════════════════════════════════════════╗
-- ║          ⚡ FE HUB v1.0  |  Universal  |  Delta Executor        ║
-- ║  Works in any FilteringEnabled Roblox game                      ║
-- ║  ESP · Fly · Speed · Noclip · Kill Aura · Hitbox · Remote Spy  ║
-- ╚══════════════════════════════════════════════════════════════════╝

local _ok, _err = pcall(function()

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local UIS     = game:GetService("UserInputService")
local TS      = game:GetService("TweenService")
local Run     = game:GetService("RunService")
local WS      = game:GetService("Workspace")
local SG      = game:GetService("StarterGui")
local Lighting= game:GetService("Lighting")

local LP   = Players.LocalPlayer
local PGui = LP:WaitForChild("PlayerGui", 10)
local Cam  = WS.CurrentCamera

-- ── Delta API detection ───────────────────────────────────────────────────────
local HAS_HOOK  = (hookmetamethod ~= nil)
local HAS_DRAW  = (Drawing ~= nil)
local HAS_GHUI  = (gethui ~= nil)
local HAS_CLIP  = (setclipboard ~= nil)
local HAS_NS    = (getnamecallmethod ~= nil)
local HAS_NCC   = (newcclosure ~= nil)

pcall(function()
    SG:SetCore("SendNotification",{Title="⚡ FE Hub",Text="Loading…",Duration=2})
end)

-- ── Colour palette ────────────────────────────────────────────────────────────
local C = {
    BG     = Color3.fromRGB(13, 13, 20),
    SIDE   = Color3.fromRGB( 9,  9, 15),
    PANEL  = Color3.fromRGB(20, 20, 30),
    CARD   = Color3.fromRGB(28, 28, 42),
    DARK   = Color3.fromRGB( 7,  7, 12),
    BORDER = Color3.fromRGB(38, 38, 58),
    ACCENT = Color3.fromRGB(99,102,241),
    ACC2   = Color3.fromRGB(139, 92,246),
    GREEN  = Color3.fromRGB(52,211,153),
    RED    = Color3.fromRGB(239, 68, 68),
    YELLOW = Color3.fromRGB(251,191, 36),
    CYAN   = Color3.fromRGB( 34,211,238),
    ORANGE = Color3.fromRGB(251,146, 60),
    PINK   = Color3.fromRGB(236, 72,153),
    WHITE  = Color3.fromRGB(240,240,255),
    TEXT   = Color3.fromRGB(190,190,215),
    MUTED  = Color3.fromRGB( 90, 90,120),
}

local TF  = TweenInfo.new(0.16,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
local TS2 = TweenInfo.new(0.28,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
local FB  = Enum.Font.GothamBold
local FC  = Enum.Font.GothamSemibold
local FN  = Enum.Font.Gotham

-- ── UI primitives ─────────────────────────────────────────────────────────────
local function tw(i,p,t) TS:Create(i,t or TF,p):Play() end

local function corner(i,r)
    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 8); c.Parent=i
end
local function stroke(i,col,t)
    local s=Instance.new("UIStroke"); s.Color=col or C.BORDER; s.Thickness=t or 1; s.Parent=i
end
local function pad(i,t,b,l,r)
    local p=Instance.new("UIPadding")
    p.PaddingTop    =UDim.new(0,t or 6)
    p.PaddingBottom =UDim.new(0,b or 6)
    p.PaddingLeft   =UDim.new(0,l or 8)
    p.PaddingRight  =UDim.new(0,r or 8)
    p.Parent=i
end
local function listV(i,sp)
    local l=Instance.new("UIListLayout")
    l.SortOrder=Enum.SortOrder.LayoutOrder; l.Padding=UDim.new(0,sp or 6); l.Parent=i; return l
end
local function listH(i,sp)
    local l=Instance.new("UIListLayout")
    l.FillDirection=Enum.FillDirection.Horizontal
    l.SortOrder=Enum.SortOrder.LayoutOrder; l.Padding=UDim.new(0,sp or 6); l.Parent=i; return l
end

local function Frm(parent,sz,pos,col,nm)
    local f=Instance.new("Frame")
    f.Size=sz or UDim2.new(1,0,0,30)
    f.Position=pos or UDim2.new(0,0,0,0)
    f.BackgroundColor3=col or C.PANEL
    f.BorderSizePixel=0; f.Name=nm or "Frame"; f.Parent=parent; return f
end

local function Lbl(parent,txt,sz,pos,col,fs,font)
    local l=Instance.new("TextLabel")
    l.Size=sz or UDim2.new(1,0,0,20)
    l.Position=pos or UDim2.new(0,0,0,0)
    l.BackgroundTransparency=1; l.Text=txt or ""
    l.TextColor3=col or C.TEXT; l.TextSize=fs or 13
    l.Font=font or FN; l.TextXAlignment=Enum.TextXAlignment.Left
    l.Parent=parent; return l
end

local function Btn(parent,txt,sz,pos,col,cb)
    local f=Frm(parent,sz,pos,col or C.ACCENT); corner(f,8)
    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1
    l.Text=txt or ""; l.TextColor3=C.WHITE
    l.TextSize=13; l.Font=FB; l.Parent=f
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(1,0,1,0); b.BackgroundTransparency=1; b.Text=""; b.Parent=f
    b.MouseButton1Click:Connect(function()
        tw(f,{BackgroundColor3=C.DARK},TweenInfo.new(0.07))
        task.delay(0.07,function() tw(f,{BackgroundColor3=col or C.ACCENT},TweenInfo.new(0.12)) end)
        if cb then pcall(cb) end
    end)
    b.MouseEnter:Connect(function() tw(f,{BackgroundColor3=C.ACC2}) end)
    b.MouseLeave:Connect(function() tw(f,{BackgroundColor3=col or C.ACCENT}) end)
    return f,b,l
end

local function Inp(parent,ph,sz,pos)
    local f=Frm(parent,sz,pos,C.CARD); corner(f,8); stroke(f,C.BORDER); pad(f,4,4,10,10)
    local i=Instance.new("TextBox")
    i.Size=UDim2.new(1,0,1,0); i.BackgroundTransparency=1
    i.PlaceholderText=ph or ""; i.PlaceholderColor3=C.MUTED
    i.Text=""; i.TextColor3=C.WHITE; i.TextSize=13; i.Font=FN
    i.ClearTextOnFocus=false; i.Parent=f; return f,i
end

local function Scr(parent,sz,pos)
    local f=Frm(parent,sz,pos,C.BG); f.BackgroundTransparency=1
    local s=Instance.new("ScrollingFrame")
    s.Size=UDim2.new(1,0,1,0); s.BackgroundTransparency=1
    s.BorderSizePixel=0; s.ScrollBarThickness=3
    s.ScrollBarImageColor3=C.ACCENT
    s.CanvasSize=UDim2.new(0,0,0,0)
    s.AutomaticCanvasSize=Enum.AutomaticSize.Y
    s.Parent=f; return f,s
end

-- Toggle with animated pill+knob
local function Toggle(parent,label,default,onChange)
    local row=Frm(parent,UDim2.new(1,0,0,38),nil,C.CARD); corner(row,8); pad(row,0,0,12,12)
    Lbl(row,label,UDim2.new(1,-54,1,0),UDim2.new(0,0,0,0),C.TEXT,13,FC)
    local pill=Frm(row,UDim2.new(0,44,0,24),UDim2.new(1,-44,0.5,-12),C.DARK)
    corner(pill,12); stroke(pill,C.BORDER)
    local knob=Frm(pill,UDim2.new(0,18,0,18),UDim2.new(0,3,0.5,-9),C.MUTED); corner(knob,9)
    local state=default or false
    local function upd()
        if state then
            tw(pill,{BackgroundColor3=C.ACCENT})
            tw(knob,{Position=UDim2.new(0,23,0.5,-9),BackgroundColor3=C.WHITE})
        else
            tw(pill,{BackgroundColor3=C.DARK})
            tw(knob,{Position=UDim2.new(0,3,0.5,-9),BackgroundColor3=C.MUTED})
        end
    end
    upd()
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(1,0,1,0); b.BackgroundTransparency=1; b.Text=""; b.Parent=row
    b.MouseButton1Click:Connect(function()
        state=not state; upd()
        if onChange then pcall(onChange,state) end
    end)
    return row,function() return state end,function(v) state=v; upd(); if onChange then pcall(onChange,v) end end
end

-- Slider
local function Slider(parent,label,mn,mx,def,onChange)
    local row=Frm(parent,UDim2.new(1,0,0,52),nil,C.CARD); corner(row,8); pad(row,8,8,12,12)
    Lbl(row,label,UDim2.new(0.65,0,0,16),nil,C.TEXT,13,FC)
    local valL=Lbl(row,tostring(def),UDim2.new(0.35,0,0,16),UDim2.new(0.65,0,0,0),C.ACCENT,13,FB)
    valL.TextXAlignment=Enum.TextXAlignment.Right
    local track=Frm(row,UDim2.new(1,0,0,6),UDim2.new(0,0,0,24),C.DARK); corner(track,3)
    local pct0=(def-mn)/(mx-mn)
    local fill=Frm(track,UDim2.new(pct0,0,1,0),nil,C.ACCENT); corner(fill,3)
    local thumb=Frm(track,UDim2.new(0,14,0,14),UDim2.new(pct0,-7,0.5,-7),C.WHITE); corner(thumb,7)
    local val=def; local drag=false
    local function setV(v)
        val=math.clamp(v,mn,mx)
        local p=(val-mn)/(mx-mn)
        fill.Size=UDim2.new(p,0,1,0)
        thumb.Position=UDim2.new(p,-7,0.5,-7)
        valL.Text=tostring(math.floor(val))
        if onChange then pcall(onChange,val) end
    end
    local ib=Instance.new("TextButton")
    ib.Size=UDim2.new(1,0,1,0); ib.BackgroundTransparency=1; ib.Text=""; ib.Parent=track
    ib.MouseButton1Down:Connect(function()
        drag=true
        local c2; c2=UIS.InputChanged:Connect(function(inp)
            if not drag then c2:Disconnect(); return end
            if inp.UserInputType==Enum.UserInputType.MouseMovement or
               inp.UserInputType==Enum.UserInputType.Touch then
                local ap=track.AbsolutePosition; local as=track.AbsoluteSize
                setV(mn+math.clamp((inp.Position.X-ap.X)/as.X,0,1)*(mx-mn))
            end
        end)
        UIS.InputEnded:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1 or
               inp.UserInputType==Enum.UserInputType.Touch then drag=false end
        end)
    end)
    return row,function() return val end
end

-- Status row (label + colored value)
local function StatusRow(parent,lbl,val,col)
    local row=Frm(parent,UDim2.new(1,0,0,30),nil,C.CARD); corner(row,6); pad(row,0,0,10,10)
    Lbl(row,lbl,UDim2.new(0.7,0,1,0),nil,C.TEXT,12,FN)
    local v=Lbl(row,val,UDim2.new(0.3,0,1,0),UDim2.new(0.7,0,0,0),col or C.GREEN,12,FB)
    v.TextXAlignment=Enum.TextXAlignment.Right; return row,v
end

local function SectionHdr(parent,txt)
    local h=Lbl(parent,txt,UDim2.new(1,0,0,18),nil,C.MUTED,11,FB)
    h.TextXAlignment=Enum.TextXAlignment.Left; return h
end

-- ── GUI shell ──────────────────────────────────────────────────────────────────
local GUI_ROOT = HAS_GHUI and gethui() or PGui

local old=GUI_ROOT:FindFirstChild("__FE_HUB__")
if old then old:Destroy() end

local SGI=Instance.new("ScreenGui")
SGI.Name="__FE_HUB__"; SGI.ResetOnSpawn=false
SGI.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
SGI.IgnoreGuiInset=true; SGI.Parent=GUI_ROOT

-- Window
local WIN=Frm(SGI,UDim2.new(0,630,0,480),UDim2.new(0.5,-315,0.5,-240),C.BG,"WIN")
corner(WIN,14); stroke(WIN,C.BORDER,1); WIN.ClipsDescendants=true

-- Shadow
local shd=Instance.new("ImageLabel")
shd.Size=UDim2.new(1,40,1,40); shd.Position=UDim2.new(0,-20,0,-20)
shd.BackgroundTransparency=1; shd.Image="rbxassetid://6014261993"
shd.ImageColor3=Color3.new(0,0,0); shd.ImageTransparency=0.55
shd.ScaleType=Enum.ScaleType.Slice; shd.SliceCenter=Rect.new(49,49,450,450); shd.Parent=WIN

-- Title bar
local TBAR=Frm(WIN,UDim2.new(1,0,0,46),nil,C.SIDE,"TBAR")

-- macOS traffic lights
local function dot(xoff,col)
    local d=Frm(TBAR,UDim2.new(0,13,0,13),UDim2.new(0,xoff,0.5,-6.5),col); corner(d,7)
    return d
end
local dotC=dot(12,C.RED); local dotM=dot(29,C.YELLOW); local dotG=dot(46,C.GREEN)

-- Title
local titleL=Lbl(TBAR,"⚡  FE Hub  ·  Universal",UDim2.new(1,-240,1,0),UDim2.new(0,72,0,0),C.WHITE,15,FB)
titleL.TextXAlignment=Enum.TextXAlignment.Center

-- Game info chip
local chipBg=Frm(TBAR,UDim2.new(0,190,0,26),UDim2.new(1,-198,0.5,-13),C.CARD); corner(chipBg,13)
Lbl(chipBg,tostring(game.Name):sub(1,22).." · "..game.PlaceId,UDim2.new(1,0,1,0),nil,C.MUTED,10,FN).TextXAlignment=Enum.TextXAlignment.Center

-- Sidebar
local SIDE=Frm(WIN,UDim2.new(0,152,1,-46),UDim2.new(0,0,0,46),C.SIDE,"SIDE")
pad(SIDE,8,8,6,6); listV(SIDE,3)

-- Body
local BODY=Frm(WIN,UDim2.new(1,-152,1,-46),UDim2.new(0,152,0,46),C.BG,"BODY")
Frm(WIN,UDim2.new(0,1,1,-46),UDim2.new(0,152,0,46),C.BORDER) -- separator

-- ── Tab system ────────────────────────────────────────────────────────────────
local pages,tabBtns={},{}; local curPage=1

local function showPage(n)
    for i,f in pairs(pages) do f.Visible=(i==n) end
    for i,b in pairs(tabBtns) do
        if i==n then
            tw(b.bg,{BackgroundColor3=C.CARD}); tw(b.bar,{BackgroundColor3=C.ACCENT})
            tw(b.ico,{TextColor3=C.ACCENT}); tw(b.lbl,{TextColor3=C.WHITE})
        else
            tw(b.bg,{BackgroundColor3=C.SIDE}); tw(b.bar,{BackgroundColor3=C.SIDE})
            tw(b.ico,{TextColor3=C.MUTED}); tw(b.lbl,{TextColor3=C.MUTED})
        end
    end
    curPage=n
end

local function newTab(icon,name)
    local n=#pages+1
    local bg=Frm(SIDE,UDim2.new(1,0,0,42),nil,C.SIDE,"T"..n); corner(bg,9)
    local bar=Frm(bg,UDim2.new(0,3,0.55,0),UDim2.new(0,0,0.225,0),C.SIDE); corner(bar,2)
    local ico=Lbl(bg,icon,UDim2.new(0,28,1,0),UDim2.new(0,8,0,0),C.MUTED,15,FB)
    local lbl=Lbl(bg,name,UDim2.new(1,-42,1,0),UDim2.new(0,38,0,0),C.MUTED,12,FC)
    local tb=Instance.new("TextButton")
    tb.Size=UDim2.new(1,0,1,0); tb.BackgroundTransparency=1; tb.Text=""; tb.Parent=bg
    tb.MouseButton1Click:Connect(function() showPage(n) end)
    tb.MouseEnter:Connect(function() if curPage~=n then tw(bg,{BackgroundColor3=C.CARD}) end end)
    tb.MouseLeave:Connect(function() if curPage~=n then tw(bg,{BackgroundColor3=C.SIDE}) end end)
    tabBtns[n]={bg=bg,bar=bar,ico=ico,lbl=lbl}
    local page=Frm(BODY,UDim2.new(1,0,1,0),nil,C.BG,"P"..n); page.Visible=false; pages[n]=page
    return page
end

-- ── Drag ──────────────────────────────────────────────────────────────────────
do
    local dragging,ds,ws
    TBAR.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true; ds=inp.Position; ws=WIN.Position
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType==Enum.UserInputType.MouseMovement then
            local d=inp.Position-ds
            WIN.Position=UDim2.new(ws.X.Scale,ws.X.Offset+d.X,ws.Y.Scale,ws.Y.Offset+d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
end

-- ── Close / minimize ──────────────────────────────────────────────────────────
local minimized=false
local function makeClickable(dotInst,cb)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(1,0,1,0); b.BackgroundTransparency=1; b.Text=""; b.Parent=dotInst
    b.MouseButton1Click:Connect(cb)
end
makeClickable(dotC,function()
    tw(WIN,{Size=UDim2.new(0,630,0,0)},TweenInfo.new(0.18))
    task.delay(0.2,function() SGI:Destroy() end)
end)
makeClickable(dotM,function()
    minimized=not minimized
    tw(WIN,{Size=UDim2.new(0,630,0,minimized and 46 or 480)},TS2)
end)

UIS.InputBegan:Connect(function(inp,gp)
    if gp then return end
    if inp.KeyCode==Enum.KeyCode.Insert or inp.KeyCode==Enum.KeyCode.RightBracket then
        SGI.Enabled=not SGI.Enabled
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- State
-- ═══════════════════════════════════════════════════════════════════════════════
local S = {
    -- ESP
    esp=false, espBoxes=true, espNames=true, espDist=true,
    espHealth=true, espTracers=false, espTeam=true, espChams=false,
    -- Movement
    speed=false, speedVal=24,
    fly=false, flySpeed=70,
    noclip=false, infJump=false, antiAFK=true,
    -- Combat
    killAura=false, kaRange=15,
    hitbox=false, hitboxSz=8,
    -- Visual
    fullbright=false,
    fov=false, fovSz=80,
    -- Remote spy
    spy=false,
}

-- ── Character helpers ─────────────────────────────────────────────────────────
local function char(p)  return (p or LP).Character end
local function root(p)  local c=char(p); return c and c:FindFirstChild("HumanoidRootPart") end
local function hum(p)   local c=char(p); return c and c:FindFirstChildOfClass("Humanoid") end
local function myRoot() return root(LP) end

-- ═══════════════════════════════════════════════════════════════════════════════
-- ESP (Drawing boxes + fallback Highlights)
-- ═══════════════════════════════════════════════════════════════════════════════
local espObj={}   -- [Player] = {drawings={}, highlight}

local function clearESP(plr)
    local o=espObj[plr]; if not o then return end
    for _,d in ipairs(o.drawings or {}) do pcall(function() d:Remove() end) end
    if o.highlight then pcall(function() o.highlight:Destroy() end) end
    espObj[plr]=nil
end

local function initESP(plr)
    if plr==LP then return end
    clearESP(plr)
    local o={drawings={}}
    if HAS_DRAW then
        o.box={}
        for i=1,4 do
            local ln=Drawing.new("Line")
            ln.Visible=false; ln.Thickness=1.6; ln.Color=Color3.fromRGB(255,80,80)
            table.insert(o.drawings,ln); o.box[i]=ln
        end
        -- Health bar (2 lines: bg and fill)
        local hbg=Drawing.new("Line"); hbg.Visible=false; hbg.Thickness=4
        hbg.Color=Color3.fromRGB(30,30,30); table.insert(o.drawings,hbg); o.hpBg=hbg
        local hfill=Drawing.new("Line"); hfill.Visible=false; hfill.Thickness=4
        hfill.Color=C.GREEN; table.insert(o.drawings,hfill); o.hpFill=hfill
        -- Name
        local nm=Drawing.new("Text"); nm.Visible=false; nm.Size=13; nm.Font=2
        nm.Color=C.WHITE; nm.Outline=true; nm.Center=true
        table.insert(o.drawings,nm); o.name=nm
        -- Distance
        local ds=Drawing.new("Text"); ds.Visible=false; ds.Size=11; ds.Font=2
        ds.Color=Color3.fromRGB(180,180,180); ds.Outline=true; ds.Center=true
        table.insert(o.drawings,ds); o.dist=ds
        -- Tracer
        local tr=Drawing.new("Line"); tr.Visible=false; tr.Thickness=1
        tr.Color=Color3.fromRGB(255,80,80); table.insert(o.drawings,tr); o.tracer=tr
    else
        local hl=Instance.new("Highlight")
        hl.FillColor=Color3.fromRGB(255,60,60); hl.OutlineColor=C.WHITE
        hl.FillTransparency=0.65; hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent=SGI; o.highlight=hl
    end
    espObj[plr]=o
end

local function updateESP()
    local myTeam=LP.Team; local mr=myRoot(); local vp=Cam.ViewportSize
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr==LP then
            -- skip self
        else
            local skip=S.espTeam and myTeam and (plr.Team==myTeam)
            local o=espObj[plr]
            if not o then
                if S.esp and not skip then initESP(plr); o=espObj[plr] end
            end
            if not o then
                -- nothing to do
            elseif not S.esp or skip then
                for _,d in ipairs(o.drawings or {}) do pcall(function() d.Visible=false end) end
                if o.highlight then o.highlight.Adornee=nil end
            else
                local ch=char(plr); local rt=ch and ch:FindFirstChild("HumanoidRootPart")
                local hm=ch and ch:FindFirstChildOfClass("Humanoid")
                local alive=rt and hm and hm.Health>0
                if not alive then
                    for _,d in ipairs(o.drawings or {}) do pcall(function() d.Visible=false end) end
                    if o.highlight then o.highlight.Adornee=nil end
                else
                    local col=Color3.fromRGB(255,80,80)
                    if myTeam and plr.Team==myTeam then col=C.GREEN end
                    if HAS_DRAW then
                        local sz=ch:GetExtentsSize()
                        local hw,hh,hd=sz.X/2,sz.Y/2,sz.Z/2
                        local cf=rt.CFrame
                        local corners3={
                            cf*CFrame.new(-hw,-hh,-hd), cf*CFrame.new( hw,-hh,-hd),
                            cf*CFrame.new(-hw, hh,-hd), cf*CFrame.new( hw, hh,-hd),
                            cf*CFrame.new(-hw,-hh, hd), cf*CFrame.new( hw,-hh, hd),
                            cf*CFrame.new(-hw, hh, hd), cf*CFrame.new( hw, hh, hd),
                        }
                        local mnX,mnY,mxX,mxY=math.huge,math.huge,-math.huge,-math.huge
                        local ok2=true
                        for _,cv in ipairs(corners3) do
                            local sp,vis=Cam:WorldToViewportPoint(cv.Position)
                            if not vis then ok2=false; break end
                            if sp.X<mnX then mnX=sp.X end; if sp.Y<mnY then mnY=sp.Y end
                            if sp.X>mxX then mxX=sp.X end; if sp.Y>mxY then mxY=sp.Y end
                        end
                        if ok2 then
                            local bx,by,bw,bh=mnX,mnY,mxX-mnX,mxY-mnY
                            -- Box
                            if S.espBoxes then
                                local segs={{Vector2.new(bx,by),Vector2.new(bx+bw,by)},
                                            {Vector2.new(bx,by+bh),Vector2.new(bx+bw,by+bh)},
                                            {Vector2.new(bx,by),Vector2.new(bx,by+bh)},
                                            {Vector2.new(bx+bw,by),Vector2.new(bx+bw,by+bh)}}
                                for i,ln in ipairs(o.box) do
                                    ln.Visible=true; ln.From=segs[i][1]; ln.To=segs[i][2]; ln.Color=col
                                end
                            else for _,ln in ipairs(o.box) do ln.Visible=false end end
                            -- Health bar (left edge)
                            if S.espHealth then
                                local hp=hm.Health/hm.MaxHealth
                                local hcol=Color3.fromRGB(math.floor(255*(1-hp)),math.floor(200*hp+55),50)
                                o.hpBg.Visible=true; o.hpBg.From=Vector2.new(bx-5,by); o.hpBg.To=Vector2.new(bx-5,by+bh)
                                o.hpFill.Visible=true; o.hpFill.Color=hcol
                                o.hpFill.From=Vector2.new(bx-5,by+bh); o.hpFill.To=Vector2.new(bx-5,by+bh*(1-hp))
                            else o.hpBg.Visible=false; o.hpFill.Visible=false end
                            -- Name
                            if S.espNames then
                                o.name.Visible=true; o.name.Position=Vector2.new(bx+bw/2,by-18)
                                o.name.Text=plr.DisplayName; o.name.Color=C.WHITE
                            else o.name.Visible=false end
                            -- Distance
                            if S.espDist and mr then
                                local d=(rt.Position-mr.Position).Magnitude
                                o.dist.Visible=true; o.dist.Position=Vector2.new(bx+bw/2,by+bh+4)
                                o.dist.Text=string.format("%.0f m",d)
                            else o.dist.Visible=false end
                            -- Tracer
                            if S.espTracers then
                                o.tracer.Visible=true; o.tracer.Color=col; o.tracer.Transparency=0.4
                                o.tracer.From=Vector2.new(vp.X/2,vp.Y)
                                o.tracer.To=Vector2.new(bx+bw/2,by+bh)
                            else o.tracer.Visible=false end
                        else
                            for _,d in ipairs(o.drawings) do pcall(function() d.Visible=false end) end
                        end
                    else
                        if o.highlight then o.highlight.Adornee=ch; o.highlight.FillColor=col end
                    end
                end
            end
        end
    end
end

Players.PlayerRemoving:Connect(clearESP)
Players.PlayerAdded:Connect(function(plr)
    if S.esp then initESP(plr) end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- Fly
-- ═══════════════════════════════════════════════════════════════════════════════
local flyConn
local function stopFly()
    if flyConn then flyConn:Disconnect(); flyConn=nil end
    pcall(function()
        local h=hum(LP); if h then h.PlatformStand=false end
        local r=myRoot(); if not r then return end
        local v=r:FindFirstChild("__FH_BV__"); local g=r:FindFirstChild("__FH_BG__")
        if v then v:Destroy() end; if g then g:Destroy() end
    end)
end
local function startFly()
    stopFly()
    local r=myRoot(); local h=hum(LP)
    if not r or not h then return end
    h.PlatformStand=true
    local bv=Instance.new("BodyVelocity")
    bv.Name="__FH_BV__"; bv.MaxForce=Vector3.new(1e5,1e5,1e5); bv.Velocity=Vector3.zero; bv.Parent=r
    local bg=Instance.new("BodyGyro")
    bg.Name="__FH_BG__"; bg.MaxTorque=Vector3.new(1e5,1e5,1e5); bg.P=1e4; bg.CFrame=r.CFrame; bg.Parent=r
    flyConn=Run.Heartbeat:Connect(function()
        if not S.fly then stopFly(); return end
        local r2=myRoot(); if not r2 then return end
        local h2=hum(LP); if h2 then h2.PlatformStand=true end
        local dir=Vector3.zero
        local cf=Cam.CFrame
        if UIS:IsKeyDown(Enum.KeyCode.W)         then dir=dir+cf.LookVector  end
        if UIS:IsKeyDown(Enum.KeyCode.S)         then dir=dir-cf.LookVector  end
        if UIS:IsKeyDown(Enum.KeyCode.A)         then dir=dir-cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D)         then dir=dir+cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space)     then dir=dir+Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir=dir-Vector3.new(0,1,0) end
        if dir.Magnitude>0 then dir=dir.Unit end
        local bv2=r2:FindFirstChild("__FH_BV__"); local bg2=r2:FindFirstChild("__FH_BG__")
        if bv2 then bv2.Velocity=dir*S.flySpeed end
        if bg2 then bg2.CFrame=CFrame.new(r2.Position,r2.Position+cf.LookVector) end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- Noclip
-- ═══════════════════════════════════════════════════════════════════════════════
local ncConn
local function stopNoclip()
    if ncConn then ncConn:Disconnect(); ncConn=nil end
    local c=char(LP); if c then
        for _,p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=true end
        end
    end
end
local function startNoclip()
    stopNoclip()
    ncConn=Run.Stepped:Connect(function()
        if not S.noclip then stopNoclip(); return end
        local c=char(LP); if c then
            for _,p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide=false end
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- Infinite jump
-- ═══════════════════════════════════════════════════════════════════════════════
UIS.JumpRequest:Connect(function()
    if not S.infJump then return end
    local h=hum(LP); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- Anti-AFK
-- ═══════════════════════════════════════════════════════════════════════════════
pcall(function()
    local VU=game:GetService("VirtualUser")
    LP.Idled:Connect(function()
        if S.antiAFK then
            VU:Button2Down(Vector2.new(0,0),CFrame.new())
            task.wait(0.1)
            VU:Button2Up(Vector2.new(0,0),CFrame.new())
        end
    end)
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- Kill Aura
-- ═══════════════════════════════════════════════════════════════════════════════
Run.Heartbeat:Connect(function()
    if not S.killAura then return end
    local mr=myRoot(); if not mr then return end
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=LP then
            local rt=root(plr)
            if rt and (rt.Position-mr.Position).Magnitude<=S.kaRange then
                local h=hum(plr)
                if h then
                    pcall(function() h.Health=0 end)
                    pcall(function()
                        local re=RS:FindFirstChild("DamagePlayer") or
                                  RS:FindFirstChild("Kill") or
                                  RS:FindFirstChild("Damage")
                        if re and re:IsA("RemoteEvent") then re:FireServer(plr) end
                    end)
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- Hitbox Expander
-- ═══════════════════════════════════════════════════════════════════════════════
local function applyHitboxes()
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=LP then
            local c=char(plr); local rt=c and c:FindFirstChild("HumanoidRootPart")
            if rt then
                rt.Size=S.hitbox and Vector3.new(S.hitboxSz,S.hitboxSz,S.hitboxSz) or Vector3.new(2,2,1)
                rt.Transparency=0.9; rt.CanCollide=false
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- Fullbright
-- ═══════════════════════════════════════════════════════════════════════════════
local origLight={}
local function applyFullbright(on)
    if on then
        origLight.Brightness=Lighting.Brightness; origLight.FogEnd=Lighting.FogEnd
        origLight.FogStart=Lighting.FogStart; origLight.Ambient=Lighting.Ambient
        Lighting.Brightness=2; Lighting.FogEnd=1e8; Lighting.FogStart=1e8
        Lighting.Ambient=Color3.fromRGB(180,180,180); Lighting.GlobalShadows=false
    else
        if origLight.Brightness then Lighting.Brightness=origLight.Brightness end
        if origLight.FogEnd     then Lighting.FogEnd=origLight.FogEnd         end
        if origLight.FogStart   then Lighting.FogStart=origLight.FogStart     end
        if origLight.Ambient    then Lighting.Ambient=origLight.Ambient       end
        Lighting.GlobalShadows=true
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- FOV Circle
-- ═══════════════════════════════════════════════════════════════════════════════
local fovCircle
if HAS_DRAW then
    fovCircle=Drawing.new("Circle"); fovCircle.Visible=false
    fovCircle.Thickness=1.5; fovCircle.Color=C.WHITE; fovCircle.Filled=false
    fovCircle.NumSides=64
end
local function updateFOV()
    if not fovCircle then return end
    fovCircle.Visible=S.fov
    if S.fov then
        fovCircle.Radius=S.fovSz
        fovCircle.Position=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y/2)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- Remote Spy
-- ═══════════════════════════════════════════════════════════════════════════════
local remLog={}
local MAX_LOG=80

local function addLog(dir,name,arg1)
    local line=string.format("[%s] %-28s %s",dir,name,tostring(arg1):sub(1,50))
    table.insert(remLog,1,line)
    if #remLog>MAX_LOG then table.remove(remLog) end
end

if HAS_HOOK and HAS_NS and HAS_NCC then
    local _old; _old=hookmetamethod(game,"__namecall",newcclosure(function(self,...)
        local m=getnamecallmethod()
        if S.spy then
            local args={...}   -- capture varargs before entering pcall closure
            local nm=(typeof(self)=="Instance" and self.Name or "?")
            if m=="FireServer" or m=="InvokeServer" then
                pcall(addLog,"C→S:"..m,nm,args[1])
            elseif m=="FireClient" or m=="InvokeClient" then
                pcall(addLog,"S→C:"..m,nm,args[1])
            end
        end
        return _old(self,...)
    end))
end

-- ── Respawn handler: re-apply persistent states ───────────────────────────────
LP.CharacterAdded:Connect(function()
    task.wait(0.6)
    if S.speed  then local h=hum(LP); if h then h.WalkSpeed=S.speedVal end end
    if S.fly    then startFly()    end
    if S.noclip then startNoclip() end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB 1 — ESP
-- ═══════════════════════════════════════════════════════════════════════════════
do
    local P=newTab("👁","ESP")
    local _,Ps=Scr(P,UDim2.new(1,-16,1,-10),UDim2.new(0,8,0,5))
    listV(Ps,6); pad(Ps,4,4,4,4)

    SectionHdr(Ps,"■ PLAYER ESP")
    Toggle(Ps,"Enable ESP",false,function(v)
        S.esp=v
        if v then
            for _,plr in ipairs(Players:GetPlayers()) do initESP(plr) end
        else
            for plr in pairs(espObj) do clearESP(plr) end
        end
    end)
    Toggle(Ps,"Boxes",true,function(v) S.espBoxes=v end)
    Toggle(Ps,"Names",true,function(v) S.espNames=v end)
    Toggle(Ps,"Distance",true,function(v) S.espDist=v end)
    Toggle(Ps,"Health Bars",true,function(v) S.espHealth=v end)
    Toggle(Ps,"Tracers",false,function(v) S.espTracers=v end)
    Toggle(Ps,"Team Check (hide team-mates)",true,function(v) S.espTeam=v end)

    if not HAS_DRAW then
        local w=Frm(Ps,UDim2.new(1,0,0,32),nil,Color3.fromRGB(60,35,10)); corner(w,8); pad(w,0,0,10,10)
        Lbl(w,"⚠  Drawing API unavailable — Highlight fallback active",UDim2.new(1,0,1,0),nil,C.YELLOW,11,FN)
    end

    SectionHdr(Ps,"■ CHAMS  (Highlight through walls)")
    Toggle(Ps,"Chams",false,function(v)
        S.espChams=v
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr~=LP then
                local c=char(plr); if not c then -- skip
                else
                    local existing=c:FindFirstChildOfClass("Highlight")
                    if v and not existing then
                        local hl=Instance.new("Highlight")
                        hl.FillColor=Color3.fromRGB(255,80,80); hl.OutlineColor=C.WHITE
                        hl.FillTransparency=0.5; hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent=c
                    elseif not v and existing then existing:Destroy() end
                end
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB 2 — PLAYER
-- ═══════════════════════════════════════════════════════════════════════════════
do
    local P=newTab("🏃","Player")
    local _,Ps=Scr(P,UDim2.new(1,-16,1,-10),UDim2.new(0,8,0,5))
    listV(Ps,6); pad(Ps,4,4,4,4)

    SectionHdr(Ps,"■ MOVEMENT")

    Slider(Ps,"Walk Speed",10,300,24,function(v)
        S.speedVal=v; if S.speed then local h=hum(LP); if h then h.WalkSpeed=v end end
    end)
    Toggle(Ps,"Speed Hack",false,function(v)
        S.speed=v; local h=hum(LP)
        if h then h.WalkSpeed=v and S.speedVal or 16 end
    end)

    Slider(Ps,"Fly Speed",10,400,70,function(v) S.flySpeed=v end)
    Toggle(Ps,"Fly  [W/A/S/D  Space/Shift]",false,function(v)
        S.fly=v; if v then startFly() else stopFly() end
    end)

    Toggle(Ps,"Noclip",false,function(v)
        S.noclip=v; if v then startNoclip() else stopNoclip() end
    end)
    Toggle(Ps,"Infinite Jump",false,function(v) S.infJump=v end)
    Toggle(Ps,"Anti-AFK",true,function(v) S.antiAFK=v end)

    SectionHdr(Ps,"■ CHARACTER")
    Btn(Ps,"Reset Character",UDim2.new(1,0,0,34),nil,C.RED,function()
        local h=hum(LP); if h then h.Health=0 end
    end)
    Btn(Ps,"Respawn",UDim2.new(1,0,0,34),nil,C.ACCENT,function()
        LP:LoadCharacter()
    end)
    Btn(Ps,"Teleport to Spawn",UDim2.new(1,0,0,34),nil,C.PANEL,function()
        local r=myRoot(); if not r then return end
        local sp=WS:FindFirstChildOfClass("SpawnLocation")
        r.CFrame=sp and (sp.CFrame+Vector3.new(0,4,0)) or CFrame.new(0,10,0)
    end)

    SectionHdr(Ps,"■ JUMP POWER")
    Slider(Ps,"Jump Power",1,300,50,function(v)
        local h=hum(LP); if h then h.JumpPower=v end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB 3 — TELEPORT
-- ═══════════════════════════════════════════════════════════════════════════════
do
    local P=newTab("📍","Teleport")
    local _,Ps=Scr(P,UDim2.new(1,-16,1,-10),UDim2.new(0,8,0,5))
    listV(Ps,6); pad(Ps,4,4,4,4)

    SectionHdr(Ps,"■ TELEPORT TO PLAYER")

    local listBg=Frm(Ps,UDim2.new(1,0,0,130),nil,C.DARK); corner(listBg,8)
    local _,listScr=Scr(listBg,UDim2.new(1,0,1,0))
    listV(listScr,3); pad(listScr,4,4,6,6)

    local function refreshList()
        for _,ch in ipairs(listScr:GetChildren()) do
            if ch:IsA("Frame") then ch:Destroy() end
        end
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr~=LP then
                local row=Frm(listScr,UDim2.new(1,0,0,28),nil,C.CARD); corner(row,6); pad(row,0,0,8,4)
                Lbl(row,plr.DisplayName.." ["..plr.Name.."]",UDim2.new(0.7,0,1,0),nil,C.TEXT,12,FN)
                Btn(row,"TP",UDim2.new(0,38,0,22),UDim2.new(1,-42,0.5,-11),C.ACCENT,function()
                    local mr=myRoot(); local tr=root(plr)
                    if mr and tr then mr.CFrame=tr.CFrame*CFrame.new(2,0,0) end
                end)
            end
        end
    end
    refreshList()
    Players.PlayerAdded:Connect(refreshList)
    Players.PlayerRemoving:Connect(function() task.delay(0.3,refreshList) end)
    Btn(Ps,"↻ Refresh Player List",UDim2.new(1,0,0,32),nil,C.PANEL,refreshList)

    SectionHdr(Ps,"■ COORDINATE TELEPORT")
    local _,xI=Inp(Ps,"X coordinate",UDim2.new(1,0,0,32))
    local _,yI=Inp(Ps,"Y coordinate",UDim2.new(1,0,0,32))
    local _,zI=Inp(Ps,"Z coordinate",UDim2.new(1,0,0,32))
    Btn(Ps,"Teleport to X, Y, Z",UDim2.new(1,0,0,34),nil,C.ACCENT,function()
        local x,y,z=tonumber(xI.Text),tonumber(yI.Text),tonumber(zI.Text)
        local mr=myRoot()
        if x and y and z and mr then mr.CFrame=CFrame.new(x,y,z) end
    end)

    SectionHdr(Ps,"■ WAYPOINTS")
    local waypoints={}
    local wpHost=Instance.new("Frame")
    wpHost.Size=UDim2.new(1,0,0,0); wpHost.BackgroundTransparency=1; wpHost.AutomaticSize=Enum.AutomaticSize.Y; wpHost.Parent=Ps
    listV(wpHost,4)

    local function refreshWP()
        for _,ch in ipairs(wpHost:GetChildren()) do
            if ch:IsA("Frame") then ch:Destroy() end
        end
        for i,wp in ipairs(waypoints) do
            local row=Frm(wpHost,UDim2.new(1,0,0,30),nil,C.CARD); corner(row,6); pad(row,0,0,8,4)
            Lbl(row,wp.n,UDim2.new(0.6,0,1,0),nil,C.TEXT,11,FN)
            Btn(row,"Go",UDim2.new(0,34,0,22),UDim2.new(0.6,4,0.5,-11),C.ACCENT,function()
                local mr=myRoot(); if mr then mr.CFrame=CFrame.new(wp.x,wp.y,wp.z) end
            end)
            local idx=i
            Btn(row,"✕",UDim2.new(0,22,0,22),UDim2.new(1,-26,0.5,-11),C.RED,function()
                table.remove(waypoints,idx); refreshWP()
            end)
        end
    end
    Btn(Ps,"+ Save Current Position as Waypoint",UDim2.new(1,0,0,34),nil,C.GREEN,function()
        local mr=myRoot(); if not mr then return end
        local p=mr.Position; local n=#waypoints+1
        table.insert(waypoints,{n=string.format("WP%d  %.0f,%.0f,%.0f",n,p.X,p.Y,p.Z),x=p.X,y=p.Y,z=p.Z})
        refreshWP()
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB 4 — COMBAT
-- ═══════════════════════════════════════════════════════════════════════════════
do
    local P=newTab("⚔","Combat")
    local _,Ps=Scr(P,UDim2.new(1,-16,1,-10),UDim2.new(0,8,0,5))
    listV(Ps,6); pad(Ps,4,4,4,4)

    SectionHdr(Ps,"■ KILL AURA")
    do
        local w=Frm(Ps,UDim2.new(1,0,0,28),nil,Color3.fromRGB(60,40,10)); corner(w,8); pad(w,0,0,10,10)
        Lbl(w,"⚠ Tries known damage remotes — may be game-specific",UDim2.new(1,0,1,0),nil,C.YELLOW,11,FN)
    end
    Slider(Ps,"Aura Range (studs)",3,60,15,function(v) S.kaRange=v end)
    Toggle(Ps,"Kill Aura",false,function(v) S.killAura=v end)

    SectionHdr(Ps,"■ HITBOX EXPANDER")
    Slider(Ps,"Hitbox Size",2,40,8,function(v) S.hitboxSz=v; if S.hitbox then applyHitboxes() end end)
    Toggle(Ps,"Hitbox Expander",false,function(v) S.hitbox=v; applyHitboxes() end)

    SectionHdr(Ps,"■ INSTANT ACTIONS")
    Btn(Ps,"TP to Nearest Enemy",UDim2.new(1,0,0,34),nil,C.ACCENT,function()
        local mr=myRoot(); if not mr then return end
        local near,nd=nil,math.huge
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr~=LP then
                local rt=root(plr)
                if rt then
                    local d=(rt.Position-mr.Position).Magnitude
                    if d<nd then nd=d; near=rt end
                end
            end
        end
        if near then mr.CFrame=near.CFrame*CFrame.new(2,0,0) end
    end)
    Btn(Ps,"Fling Nearest Player",UDim2.new(1,0,0,34),nil,C.RED,function()
        local mr=myRoot(); if not mr then return end
        local near,nd=nil,math.huge
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr~=LP then
                local rt=root(plr)
                if rt then
                    local d=(rt.Position-mr.Position).Magnitude
                    if d<nd then nd=d; near=rt end
                end
            end
        end
        if near then
            local bf=Instance.new("BodyForce"); bf.Force=Vector3.new(0,1.2e6,0); bf.Parent=near
            task.delay(0.12,function() pcall(function() bf:Destroy() end) end)
        end
    end)
    Btn(Ps,"Fake Lag (freeze for 2s)",UDim2.new(1,0,0,34),nil,C.PANEL,function()
        -- Disconnect character briefly to cause lag-like effect
        pcall(function()
            local h=hum(LP); if h then
                local old=h.WalkSpeed; h.WalkSpeed=0
                task.delay(2,function() h.WalkSpeed=S.speed and S.speedVal or old end)
            end
        end)
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB 5 — VISUAL
-- ═══════════════════════════════════════════════════════════════════════════════
do
    local P=newTab("✨","Visual")
    local _,Ps=Scr(P,UDim2.new(1,-16,1,-10),UDim2.new(0,8,0,5))
    listV(Ps,6); pad(Ps,4,4,4,4)

    SectionHdr(Ps,"■ ENVIRONMENT")
    Toggle(Ps,"Fullbright",false,function(v) S.fullbright=v; applyFullbright(v) end)
    Toggle(Ps,"No Fog",false,function(v)
        if v then Lighting.FogEnd=1e9; Lighting.FogStart=1e9
        else Lighting.FogEnd=origLight.FogEnd or 1000; Lighting.FogStart=origLight.FogStart or 0 end
    end)
    Toggle(Ps,"No Shadows",false,function(v) Lighting.GlobalShadows=not v end)
    Slider(Ps,"Brightness",0,10,2,function(v) Lighting.Brightness=v end)

    SectionHdr(Ps,"■ CAMERA")
    Slider(Ps,"Field of View",50,120,70,function(v) Cam.FieldOfView=v end)
    Toggle(Ps,"First-Person Lock",false,function(v)
        if v then LP.CameraMode=Enum.CameraMode.LockFirstPerson
        else LP.CameraMode=Enum.CameraMode.Classic end
    end)
    Btn(Ps,"Reset Camera",UDim2.new(1,0,0,34),nil,C.PANEL,function()
        Cam.FieldOfView=70; LP.CameraMode=Enum.CameraMode.Classic
        Cam.CameraType=Enum.CameraType.Custom
    end)

    SectionHdr(Ps,"■ FOV CIRCLE")
    if HAS_DRAW then
        Toggle(Ps,"FOV Circle",false,function(v) S.fov=v; updateFOV() end)
        Slider(Ps,"Radius (px)",20,500,80,function(v)
            S.fovSz=v; if fovCircle then fovCircle.Radius=v end
        end)
    else
        Lbl(Ps,"⚠ Drawing API not available",UDim2.new(1,0,0,18),nil,C.YELLOW,12,FN)
    end

    SectionHdr(Ps,"■ CROSSHAIR")
    if HAS_DRAW then
        local ch1,ch2,ch3,ch4
        Toggle(Ps,"Custom Crosshair",false,function(v)
            if v then
                local sz=8; local col=C.WHITE
                local function line() local l=Drawing.new("Line"); l.Thickness=1.5; l.Color=col; l.Visible=true; return l end
                ch1=line(); ch2=line(); ch3=line(); ch4=line()
                Run.RenderStepped:Connect(function()
                    if not S.fov then -- reuse fov flag? use separate
                    end
                    local cx,cy=Cam.ViewportSize.X/2,Cam.ViewportSize.Y/2
                    if ch1 then ch1.From=Vector2.new(cx-sz,cy); ch1.To=Vector2.new(cx+sz,cy) end
                    if ch2 then ch2.From=Vector2.new(cx,cy-sz); ch2.To=Vector2.new(cx,cy+sz) end
                end)
            else
                if ch1 then pcall(function() ch1:Remove(); ch2:Remove() end) end
            end
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB 6 — REMOTES
-- ═══════════════════════════════════════════════════════════════════════════════
do
    local P=newTab("📡","Remotes")
    pad(P,6,6,8,8)

    -- Header row
    local hdr=Frm(P,UDim2.new(1,0,0,38),nil,C.SIDE); corner(hdr,8); pad(hdr,0,0,10,10)
    listH(hdr,8)
    Toggle(hdr,"Remote Spy",false,function(v) S.spy=v end)
    if not HAS_HOOK then
        local w=Frm(P,UDim2.new(1,0,0,30),UDim2.new(0,0,0,44),Color3.fromRGB(60,30,10))
        corner(w,8); pad(w,0,0,10,10)
        Lbl(w,"⚠ hookmetamethod unavailable — spy cannot log remotes",UDim2.new(1,0,1,0),nil,C.YELLOW,11,FN)
    end

    -- Log area
    local logBg=Frm(P,UDim2.new(1,0,1,-88),UDim2.new(0,0,0,46),C.DARK); corner(logBg,8)
    local _,logScr=Scr(logBg,UDim2.new(1,-4,1,-4),UDim2.new(0,2,0,2))
    listV(logScr,1); pad(logScr,3,3,4,4)

    local function refreshLog()
        for _,ch in ipairs(logScr:GetChildren()) do
            if ch:IsA("TextLabel") then ch:Destroy() end
        end
        for _,entry in ipairs(remLog) do
            local lbl=Instance.new("TextLabel")
            lbl.Size=UDim2.new(1,0,0,13); lbl.BackgroundTransparency=1
            lbl.Text=entry; lbl.TextColor3=C.TEXT; lbl.TextSize=10
            lbl.Font=Enum.Font.RobotoMono; lbl.TextXAlignment=Enum.TextXAlignment.Left
            lbl.TextTruncate=Enum.TextTruncate.AtEnd; lbl.Parent=logScr
        end
    end

    -- Bottom buttons
    local btnRow=Frm(P,UDim2.new(1,0,0,36),UDim2.new(0,0,1,-42),C.BG)
    listH(btnRow,6)
    Btn(btnRow,"↻ Refresh",UDim2.new(0,90,0,30),nil,C.ACCENT,refreshLog)
    Btn(btnRow,"✕ Clear",UDim2.new(0,80,0,30),nil,C.RED,function() remLog={}; refreshLog() end)
    if HAS_CLIP then
        Btn(btnRow,"Copy All",UDim2.new(0,80,0,30),nil,C.PANEL,function()
            pcall(setclipboard,table.concat(remLog,"\n"))
            pcall(function() SG:SetCore("SendNotification",{Title="FE Hub",Text="Log copied!",Duration=2}) end)
        end)
    end
    Btn(btnRow,"List All Remotes",UDim2.new(0,110,0,30),nil,C.PANEL,function()
        local found={}
        for _,obj in ipairs(RS:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                table.insert(found,obj.ClassName.."  "..obj:GetFullName())
            end
        end
        for _,obj in ipairs(WS:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                table.insert(found,obj.ClassName.."  "..obj:GetFullName())
            end
        end
        if HAS_CLIP then
            pcall(setclipboard,table.concat(found,"\n"))
            pcall(function() SG:SetCore("SendNotification",{Title="FE Hub",Text="Copied "..#found.." remotes",Duration=3}) end)
        else print("[FE Hub] Remotes:\n"..table.concat(found,"\n")) end
    end)

    -- Auto-refresh every 1.5 s while spy active
    task.spawn(function()
        while SGI.Parent do
            task.wait(1.5)
            if S.spy then pcall(refreshLog) end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB 7 — SCRIPTS (Quick Script Hub)
-- ═══════════════════════════════════════════════════════════════════════════════
do
    local P=newTab("📜","Scripts")
    local _,Ps=Scr(P,UDim2.new(1,-16,1,-10),UDim2.new(0,8,0,5))
    listV(Ps,6); pad(Ps,4,4,4,4)

    SectionHdr(Ps,"■ UNIVERSAL SCRIPTS  (self-contained)")

    local scripts={
        {name="Print All Players",desc="Lists every player in console",code=[[
for _,p in ipairs(game:GetService("Players"):GetPlayers()) do
    print(p.Name, p.UserId, p.AccountAge.." days")
end]]},
        {name="Inf Yield — Walk Speed 100",desc="Requires inf yield in executor",code=[[
_G.WalkSpeed=100
game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function(c)
    task.wait(1)
    c:WaitForChild("Humanoid").WalkSpeed=_G.WalkSpeed
end)
local h=game:GetService("Players").LocalPlayer.Character
           and game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
if h then h.WalkSpeed=_G.WalkSpeed end]]},
        {name="Goto Spawn & Rejoin",desc="Teleports to 0,0,0 then resets char",code=[[
local LP=game:GetService("Players").LocalPlayer
local r=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
if r then r.CFrame=CFrame.new(0,10,0) end
task.wait(0.5); LP:LoadCharacter()]]},
        {name="Fling Self (test)",desc="Applies huge upward force on HRP",code=[[
local r=game:GetService("Players").LocalPlayer.Character
           and game:GetService("Players").LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
if r then
    local bf=Instance.new("BodyForce"); bf.Force=Vector3.new(0,2e6,0); bf.Parent=r
    task.delay(0.15,function() pcall(function() bf:Destroy() end) end)
end]]},
        {name="Print FPS",desc="Shows current FPS every second",code=[[
local RS=game:GetService("RunService")
local last=os.clock()
RS.Heartbeat:Connect(function()
    local now=os.clock()
    if now-last>=1 then
        print("[FPS] "..string.format("%.1f",1/(RS.Heartbeat:Wait())))
        last=now
    end
end)]]},
        {name="Toggle Billboard Names",desc="Puts a BillboardGui above every player",code=[[
local Players=game:GetService("Players")
local LP=Players.LocalPlayer
for _,p in ipairs(Players:GetPlayers()) do
    if p~=LP and p.Character then
        local head=p.Character:FindFirstChild("Head")
        if head then
            local bb=Instance.new("BillboardGui"); bb.Size=UDim2.new(0,80,0,30)
            bb.StudsOffset=Vector3.new(0,2,0); bb.AlwaysOnTop=true; bb.Parent=head
            local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,0,1,0)
            lbl.BackgroundTransparency=1; lbl.Text=p.Name
            lbl.TextColor3=Color3.new(1,1,1); lbl.TextSize=14
            lbl.Font=Enum.Font.GothamBold; lbl.Parent=bb
        end
    end
end]]},
        {name="Remove All Hats",desc="Removes accessories from local char",code=[[
local c=game:GetService("Players").LocalPlayer.Character
if c then for _,a in ipairs(c:GetChildren()) do
    if a:IsA("Accessory") then a:Destroy() end
end end]]},
        {name="Chat Spam (careful!)",desc="Sends 5 messages with delay",code=[[
local chat=game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
local fn=chat and chat:FindFirstChild("SayMessageRequest")
for i=1,5 do
    if fn then fn:FireServer("FE Hub "..i,"All") end
    task.wait(1.2)
end]]},
        {name="List All Tools",desc="Prints tools in workspace + backpack",code=[[
local LP=game:GetService("Players").LocalPlayer
local WS=game:GetService("Workspace")
print("=== TOOLS ===")
for _,t in ipairs(LP.Backpack:GetChildren()) do print("[BP] "..t.Name) end
local c=LP.Character
if c then for _,t in ipairs(c:GetChildren()) do if t:IsA("Tool") then print("[CHAR] "..t.Name) end end end]]},
        {name="Auto-Collect (touch all parts)",desc="Teleports HRP to every BasePart once",code=[[
local LP=game:GetService("Players").LocalPlayer
local r=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
if not r then return end
for _,p in ipairs(game:GetService("Workspace"):GetDescendants()) do
    if p:IsA("BasePart") and not p:IsDescendantOf(LP.Character) then
        pcall(function() r.CFrame=p.CFrame+Vector3.new(0,2,0) end)
        task.wait(0.05)
    end
end
print("[FE Hub] Auto-collect done")]]},
    }

    for _,sc in ipairs(scripts) do
        local card=Frm(Ps,UDim2.new(1,0,0,54),nil,C.CARD); corner(card,10); pad(card,6,6,12,8)
        Lbl(card,sc.name,UDim2.new(1,-90,0,18),nil,C.WHITE,13,FB)
        Lbl(card,sc.desc,UDim2.new(1,-90,0,14),UDim2.new(0,0,0,20),C.MUTED,11,FN)
        Btn(card,"Execute",UDim2.new(0,78,0,34),UDim2.new(1,-82,0.5,-17),C.ACCENT,function()
            local fn,ce=loadstring(sc.code)
            if fn then
                local ok2,e2=pcall(fn)
                if not ok2 then
                    pcall(function() SG:SetCore("SendNotification",{Title="Script Error",Text=tostring(e2):sub(1,60),Duration=4}) end)
                end
            else
                pcall(function() SG:SetCore("SendNotification",{Title="Compile Error",Text=tostring(ce):sub(1,60),Duration=4}) end)
            end
        end)
        if HAS_CLIP then
            Btn(card,"Copy",UDim2.new(0,44,0,20),UDim2.new(1,-82,0,6),C.PANEL,function()
                pcall(setclipboard,sc.code)
                pcall(function() SG:SetCore("SendNotification",{Title="FE Hub",Text="Copied!",Duration=1}) end)
            end)
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB 8 — MISC / INFO
-- ═══════════════════════════════════════════════════════════════════════════════
do
    local P=newTab("⚙","Misc")
    local _,Ps=Scr(P,UDim2.new(1,-16,1,-10),UDim2.new(0,8,0,5))
    listV(Ps,6); pad(Ps,4,4,4,4)

    SectionHdr(Ps,"■ DELTA API STATUS")
    local caps={
        {"hookmetamethod",   HAS_HOOK},
        {"Drawing API",      HAS_DRAW},
        {"gethui()",         HAS_GHUI},
        {"setclipboard",     HAS_CLIP},
        {"getnamecallmethod",HAS_NS},
        {"newcclosure",      HAS_NCC},
        {"loadstring",       (loadstring~=nil)},
        {"readfile",         (readfile~=nil)},
        {"writefile",        (writefile~=nil)},
        {"http.request",     (http~=nil or request~=nil)},
        {"syn.request",      (syn~=nil)},
        {"getgenv",          (getgenv~=nil)},
    }
    for _,cap in ipairs(caps) do
        StatusRow(Ps,cap[1],cap[2] and "✓  Available" or "✗  Missing",cap[2] and C.GREEN or C.RED)
    end

    SectionHdr(Ps,"■ GAME INFO")
    StatusRow(Ps,"Place ID",       tostring(game.PlaceId),   C.CYAN)
    StatusRow(Ps,"Game Name",      tostring(game.Name):sub(1,28), C.CYAN)
    StatusRow(Ps,"Players Online", tostring(#Players:GetPlayers()), C.TEXT)
    StatusRow(Ps,"Your Username",  LP.Name,                  C.TEXT)
    StatusRow(Ps,"Account Age",    LP.AccountAge.." days",   C.TEXT)
    StatusRow(Ps,"Executor",       "Delta",                  C.ACCENT)

    SectionHdr(Ps,"■ KEYBINDS")
    StatusRow(Ps,"Toggle GUI",      "[Insert]  or  [  ]  ]", C.TEXT)
    StatusRow(Ps,"Fly direction",   "W · A · S · D",         C.TEXT)
    StatusRow(Ps,"Fly up / down",   "Space / Left Shift",    C.TEXT)
    StatusRow(Ps,"Close window",    "Red dot (top-left)",    C.TEXT)
    StatusRow(Ps,"Minimize window", "Yellow dot",            C.TEXT)

    SectionHdr(Ps,"■ TOOLS")
    Btn(Ps,"Copy Place ID",UDim2.new(1,0,0,34),nil,C.PANEL,function()
        if HAS_CLIP then
            pcall(setclipboard,tostring(game.PlaceId))
            pcall(function() SG:SetCore("SendNotification",{Title="FE Hub",Text="Place ID copied!",Duration=2}) end)
        else print(game.PlaceId) end
    end)
    Btn(Ps,"Copy User ID",UDim2.new(1,0,0,34),nil,C.PANEL,function()
        if HAS_CLIP then
            pcall(setclipboard,tostring(LP.UserId))
            pcall(function() SG:SetCore("SendNotification",{Title="FE Hub",Text="User ID copied!",Duration=2}) end)
        end
    end)
    Btn(Ps,"Scan & Print All Scripts",UDim2.new(1,0,0,34),nil,C.PANEL,function()
        local found={}
        for _,o in ipairs(WS:GetDescendants()) do
            if o:IsA("LocalScript") or o:IsA("Script") or o:IsA("ModuleScript") then
                table.insert(found,o.ClassName..": "..o:GetFullName())
            end
        end
        print("[FE Hub] Scripts ("..#found.."):\n"..table.concat(found,"\n"))
        pcall(function() SG:SetCore("SendNotification",{Title="FE Hub",Text="Printed "..#found.." scripts",Duration=3}) end)
    end)
    Btn(Ps,"Rejoin Game",UDim2.new(1,0,0,34),nil,C.RED,function()
        game:GetService("TeleportService"):Teleport(game.PlaceId,LP)
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- Main render loop
-- ═══════════════════════════════════════════════════════════════════════════════
Run.RenderStepped:Connect(function()
    pcall(updateESP)
    pcall(updateFOV)
end)

-- First page
showPage(1)

pcall(function()
    SG:SetCore("SendNotification",{Title="⚡ FE Hub",Text="Ready — press ] to toggle",Duration=4})
end)

end) -- pcall

if not _ok then
    warn("[FE Hub] STARTUP ERROR: "..tostring(_err))
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification",
            {Title="FE Hub ERROR",Text=tostring(_err):sub(1,80),Duration=6})
    end)
end
