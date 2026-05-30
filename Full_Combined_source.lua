-- ================================================================
--  SS EXECUTOR  v5  –  Full Serverside + Client Executor
--  Single-file, self-contained. No external HTTP tab loading.
--  loadstring(game:HttpGet(URL, true))()
-- ================================================================

local _ok, _err = pcall(function()

-- ── Services ──────────────────────────────────────────────────────────────────
local Players  = game:GetService("Players")
local RS       = game:GetService("ReplicatedStorage")
local UIS      = game:GetService("UserInputService")
local TS       = game:GetService("TweenService")

-- ── Wait for LocalPlayer ──────────────────────────────────────────────────────
local LP
for _ = 1, 120 do LP = Players.LocalPlayer; if LP then break end; task.wait(0.1) end
if not LP then warn("[SS] No LocalPlayer."); return end

local PGui = LP:WaitForChild("PlayerGui", 15)
if not PGui then warn("[SS] No PlayerGui."); return end

local old = PGui:FindFirstChild("__SS_EXEC__")
if old then old:Destroy() end

-- ── Server bridge (SS_Executor.lua must be running server-side) ───────────────
local Bridge = RS:FindFirstChild("SS_ExecBridge")

local function pingBridge() -- returns true/false
    if not Bridge then return false end
    local ok, r = pcall(function() return Bridge:InvokeServer("ping") end)
    return ok and r and r.ok
end

local function callBridge(action, payload)
    if not Bridge then
        return false, "No bridge.\nInject SS_Executor.lua server-side first."
    end
    local ok, r = pcall(function() return Bridge:InvokeServer(action, payload or {}) end)
    if not ok then return false, tostring(r) end
    return r.ok, r.msg, r.data
end

-- Notify
pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification",
        {Title="SS Executor", Text="Loaded", Duration=2})
end)

-- ── Theme  (Delta-style navy blue) ────────────────────────────────────────────
local C = {
    BG     = Color3.fromRGB(15,  19,  33),   -- deep navy
    SIDE   = Color3.fromRGB( 9,  12,  22),   -- darker sidebar
    PANEL  = Color3.fromRGB(24,  30,  50),   -- panel navy
    CARD   = Color3.fromRGB(32,  40,  64),   -- card
    EDIT   = Color3.fromRGB(14,  18,  32),   -- editor
    CON    = Color3.fromRGB( 9,  12,  22),   -- console bg
    BORDER = Color3.fromRGB(45,  58, 100),   -- subtle navy border
    ACC    = Color3.fromRGB(59, 130, 246),   -- Delta blue
    ACCHV  = Color3.fromRGB(96, 165, 250),   -- hover blue
    BLUE   = Color3.fromRGB(59, 130, 246),   -- same blue
    BLHV   = Color3.fromRGB(96, 165, 250),
    GREEN  = Color3.fromRGB(34, 197, 94),
    RED    = Color3.fromRGB(220, 55,  55),
    REDHV  = Color3.fromRGB(248, 80,  80),
    YELL   = Color3.fromRGB(250, 204,  21),
    ORAN   = Color3.fromRGB(249, 115,  22),
    GREY   = Color3.fromRGB(55,  65,  90),
    GRYHV  = Color3.fromRGB(75,  88, 120),
    PURP   = Color3.fromRGB(139, 92, 246),
    TXT    = Color3.fromRGB(241, 245, 249),
    TXTS   = Color3.fromRGB(148, 163, 184),
    TXTD   = Color3.fromRGB(71,  85, 105),
    WHITE  = Color3.new(1,1,1),
}
local TF  = TweenInfo.new(0.13)
local TS2 = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FB = Enum.Font.GothamBold
local FN = Enum.Font.Gotham
local FC = Enum.Font.Code

-- ── UI helpers ─────────────────────────────────────────────────────────────
local function tw(o, p, ti) TS:Create(o, ti or TF, p):Play() end

local function corner(p, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 7); c.Parent = p
end
local function stroke(p, col, th)
    local s = Instance.new("UIStroke"); s.Color=col or C.BORDER; s.Thickness=th or 1.2; s.Parent=p
end
local function pad(p, v, h)
    local u=Instance.new("UIPadding")
    u.PaddingTop=UDim.new(0,v or 6); u.PaddingBottom=UDim.new(0,v or 6)
    u.PaddingLeft=UDim.new(0,h or v or 9); u.PaddingRight=UDim.new(0,h or v or 9); u.Parent=p
end
local function listH(p, sp)
    local l=Instance.new("UIListLayout"); l.FillDirection=Enum.FillDirection.Horizontal
    l.SortOrder=Enum.SortOrder.LayoutOrder; l.Padding=UDim.new(0,sp or 4); l.Parent=p
end
local function listV(p, sp)
    local l=Instance.new("UIListLayout"); l.FillDirection=Enum.FillDirection.Vertical
    l.SortOrder=Enum.SortOrder.LayoutOrder; l.Padding=UDim.new(0,sp or 4); l.Parent=p
end

local function Frm(parent, sz, pos, col, name)
    local f=Instance.new("Frame"); f.Size=sz; f.Position=pos or UDim2.new(0,0,0,0)
    f.BackgroundColor3=col or C.PANEL; f.BorderSizePixel=0; f.Name=name or "F"
    f.Parent=parent; return f
end
local function Lbl(parent, text, sz, pos, col, fnt, ts, xa)
    local l=Instance.new("TextLabel"); l.Size=sz; l.Position=pos or UDim2.new(0,0,0,0)
    l.BackgroundTransparency=1; l.Text=text or ""; l.TextColor3=col or C.TXT
    l.Font=fnt or FN; l.TextSize=ts or 13
    l.TextXAlignment=xa or Enum.TextXAlignment.Left
    l.TextYAlignment=Enum.TextYAlignment.Center; l.TextTruncate=Enum.TextTruncate.AtEnd
    l.Parent=parent; return l
end
local function Btn(parent, text, sz, pos, bg, tc)
    local b=Instance.new("TextButton"); b.Size=sz; b.Position=pos or UDim2.new(0,0,0,0)
    b.BackgroundColor3=bg or C.ACC; b.BorderSizePixel=0; b.Text=text or ""
    b.TextColor3=tc or C.TXT; b.Font=FB; b.TextSize=13; b.AutoButtonColor=false
    b.Parent=parent; corner(b,6); return b
end
local function Inp(parent, ph, sz, pos)
    local b=Instance.new("TextBox"); b.Size=sz; b.Position=pos or UDim2.new(0,0,0,0)
    b.BackgroundColor3=C.EDIT; b.BorderSizePixel=0; b.Text=""
    b.PlaceholderText=ph or ""; b.TextColor3=C.TXT; b.PlaceholderColor3=C.TXTS
    b.Font=FC; b.TextSize=13; b.TextXAlignment=Enum.TextXAlignment.Left
    b.TextYAlignment=Enum.TextYAlignment.Top; b.ClearTextOnFocus=false
    b.MultiLine=true; b.TextWrapped=true; b.ClipsDescendants=true
    b.Parent=parent; corner(b,6); stroke(b,C.BORDER,1); pad(b,7,10); return b
end
local function Con(parent, sz, pos)
    local b=Instance.new("TextBox"); b.Size=sz; b.Position=pos or UDim2.new(0,0,0,0)
    b.BackgroundColor3=C.CON; b.BorderSizePixel=0; b.Text=""
    b.PlaceholderText="> output..."; b.TextColor3=C.GREEN; b.PlaceholderColor3=C.TXTD
    b.Font=FC; b.TextSize=12; b.TextXAlignment=Enum.TextXAlignment.Left
    b.TextYAlignment=Enum.TextYAlignment.Top; b.ClearTextOnFocus=false
    b.MultiLine=true; b.TextWrapped=true; b.TextEditable=false; b.ClipsDescendants=true
    b.Parent=parent; corner(b,6); stroke(b,C.BORDER,1); pad(b,7,10); return b
end
local function Scr(parent, sz, pos)
    local s=Instance.new("ScrollingFrame"); s.Size=sz; s.Position=pos or UDim2.new(0,0,0,0)
    s.BackgroundTransparency=1; s.BorderSizePixel=0; s.ScrollBarThickness=3
    s.ScrollBarImageColor3=C.ACC; s.CanvasSize=UDim2.new(0,0,0,0)
    s.AutomaticCanvasSize=Enum.AutomaticSize.Y; s.Parent=parent; return s
end
local function hov(btn, n, h)
    btn.MouseEnter:Connect(function()    tw(btn,{BackgroundColor3=h}) end)
    btn.MouseLeave:Connect(function()    tw(btn,{BackgroundColor3=n}) end)
    btn.MouseButton1Down:Connect(function() tw(btn,{BackgroundColor3=n}) end)
    btn.MouseButton1Up:Connect(function()   tw(btn,{BackgroundColor3=h}) end)
end
local function rowBar(parent, yOff)
    local r=Frm(parent,UDim2.new(1,0,0,26),UDim2.new(0,0,0,yOff),Color3.fromRGB(0,0,0))
    r.BackgroundTransparency=1; listH(r,4); return r
end

-- ── Window ────────────────────────────────────────────────────────────────────
local GUI=Instance.new("ScreenGui")
GUI.Name="__SS_EXEC__"; GUI.ResetOnSpawn=false; GUI.IgnoreGuiInset=true
GUI.DisplayOrder=999; GUI.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; GUI.Parent=PGui

local WIN=Frm(GUI,UDim2.new(0,590,0,462),UDim2.new(0.5,-295,0.5,-231),C.BG,"Window")
corner(WIN,12); stroke(WIN,C.BORDER,1.5)

-- shadow
local Sh=Instance.new("ImageLabel"); Sh.Size=UDim2.new(1,48,1,48); Sh.Position=UDim2.new(0,-24,0,-24)
Sh.BackgroundTransparency=1; Sh.Image="rbxassetid://6014261993"; Sh.ImageColor3=Color3.new(0,0,0)
Sh.ImageTransparency=0.45; Sh.ScaleType=Enum.ScaleType.Slice; Sh.SliceCenter=Rect.new(49,49,450,450)
Sh.ZIndex=0; Sh.Parent=WIN

-- title bar
local TBAR=Frm(WIN,UDim2.new(1,0,0,42),UDim2.new(0,0,0,0),C.SIDE,"TBar"); corner(TBAR,12)
Frm(WIN,UDim2.new(1,0,0,12),UDim2.new(0,0,0,30),C.SIDE)

-- Logo box (like Delta's icon badge)
local LogoBG=Frm(TBAR,UDim2.new(0,28,0,28),UDim2.new(0,8,0,7),C.ACC); corner(LogoBG,7)
local LogoTxt=Lbl(LogoBG,"⚡",UDim2.new(1,0,1,0),nil,C.WHITE,FB,14,Enum.TextXAlignment.Center)

-- Title text
Lbl(TBAR,"NEXUS",UDim2.new(0,54,0,20),UDim2.new(0,42,0,5),C.WHITE,FB,15)
Lbl(TBAR,"EXECUTOR",UDim2.new(0,72,0,14),UDim2.new(0,42,0,22),C.TXTS,FN,10)

local ODot=Frm(TBAR,UDim2.new(0,7,0,7),UDim2.new(0,122,0,17),C.GREY); corner(ODot,4)
local BridgeTxt=Lbl(TBAR,"checking...",UDim2.new(0,130,0,14),UDim2.new(0,136,0,14),C.TXTS,FN,11)
local BtnMin=Btn(TBAR,"—",UDim2.new(0,26,0,24),UDim2.new(1,-62,0,9),C.GREY)
local BtnX  =Btn(TBAR,"✕",UDim2.new(0,26,0,24),UDim2.new(1,-32,0,9),C.RED)
hov(BtnMin,C.GREY,C.GRYHV); hov(BtnX,C.RED,C.REDHV)
BtnX.MouseButton1Click:Connect(function() tw(WIN,{BackgroundTransparency=1}); task.wait(0.15); GUI:Destroy() end)

task.spawn(function()
    local alive = pingBridge()
    ODot.BackgroundColor3 = alive and C.GREEN or C.RED
    BridgeTxt.Text = alive and "bridge ✓" or "no bridge"
    BridgeTxt.TextColor3 = alive and C.GREEN or C.RED
end)

-- sidebar
local SIDE=Frm(WIN,UDim2.new(0,52,1,-42),UDim2.new(0,0,0,42),C.SIDE,"Side")
Frm(WIN,UDim2.new(0,10,1,-42),UDim2.new(0,42,0,42),C.SIDE)
Frm(WIN,UDim2.new(0,1,1,-42),UDim2.new(0,52,0,42),Color3.fromRGB(35,48,88)) -- navy divider

-- body
local BODY=Frm(WIN,UDim2.new(1,-58,1,-48),UDim2.new(0,55,0,46),Color3.fromRGB(0,0,0),"Body")
BODY.BackgroundTransparency=1

-- ── Tab system ────────────────────────────────────────────────────────────────
local sbBtns={} local pages={} local curPage=0 local tabN=0
local TAB_COLORS={
    Color3.fromRGB( 59,130,246), -- 1 Execute  blue
    Color3.fromRGB( 96,165,250), -- 2 Server   light blue
    Color3.fromRGB(249,115, 22), -- 3 Sandbox  orange
    Color3.fromRGB(220, 55, 55), -- 4 Malware  red
    Color3.fromRGB(139, 92,246), -- 5 Deobfusc purple
    Color3.fromRGB(250,204, 21), -- 6 Checker  gold
    Color3.fromRGB( 34,197, 94), -- 7 Environ  green
}

local function showPage(idx)
    for i,p in pages  do p.Visible=(i==idx) end
    for i,b in sbBtns do
        local ac=TAB_COLORS[i] or C.ACC
        tw(b,{BackgroundColor3=i==idx and ac or Color3.fromRGB(18,18,26),
              TextColor3=i==idx and C.WHITE or C.TXTD})
    end
    curPage=idx
end

local function newTab(icon, label)
    tabN+=1; local idx=tabN
    local yp = 10+(idx-1)*44
    local ac = TAB_COLORS[idx] or C.ACC

    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(0,36,0,36); btn.Position=UDim2.new(0,8,0,yp)
    btn.BackgroundColor3=Color3.fromRGB(18,18,26); btn.Text=icon
    btn.TextColor3=C.TXTD; btn.Font=FB; btn.TextSize=18
    btn.AutoButtonColor=false; btn.BorderSizePixel=0; btn.Parent=SIDE
    local uc=Instance.new("UICorner"); uc.CornerRadius=UDim.new(0.5,0); uc.Parent=btn

    local tipW=math.max(70,#label*8+16)
    local tip=Instance.new("TextLabel")
    tip.Size=UDim2.new(0,tipW,0,22); tip.Position=UDim2.new(1,6,0,yp+7)
    tip.BackgroundColor3=C.PANEL; tip.Text=label; tip.TextColor3=C.TXT
    tip.Font=FN; tip.TextSize=12; tip.TextXAlignment=Enum.TextXAlignment.Center
    tip.BorderSizePixel=0; tip.ZIndex=12; tip.Visible=false; tip.Parent=SIDE
    corner(tip,5); stroke(tip,ac,1)

    btn.MouseEnter:Connect(function()
        tip.Visible=true
        if curPage~=idx then tw(btn,{BackgroundColor3=Color3.fromRGB(28,28,40),TextColor3=C.TXTS}) end
    end)
    btn.MouseLeave:Connect(function()
        tip.Visible=false
        if curPage~=idx then tw(btn,{BackgroundColor3=Color3.fromRGB(18,18,26),TextColor3=C.TXTD}) end
    end)
    btn.MouseButton1Click:Connect(function() showPage(idx) end)
    sbBtns[idx]=btn

    local pg=Frm(BODY,UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),Color3.fromRGB(0,0,0),"P"..idx)
    pg.BackgroundTransparency=1; pg.Visible=false; pages[idx]=pg
    return pg
end

-- ════════════════════════════════════════════════════════════════════════════════
--  TAB 1 — EXECUTE
-- ════════════════════════════════════════════════════════════════════════════════
local P1 = newTab("▶","Execute")

-- Mode strip
local mRow=rowBar(P1,0)
local modes={"Client LS","Server LS","Require","URL Exec"}
local mBtns={}; local curMode=1
local function setMode(i)
    curMode=i
    for j,b in mBtns do
        tw(b,{BackgroundColor3=j==i and C.BLUE or C.EDIT})
        b.TextColor3=j==i and C.TXT or C.TXTS
    end
end
for i,nm in modes do
    local b=Btn(mRow,nm,UDim2.new(0,120,1,0),nil,C.EDIT,C.TXTS)
    b.LayoutOrder=i; b.TextSize=12
    hov(b,i==1 and C.BLUE or C.EDIT,C.BLHV)
    b.MouseButton1Click:Connect(function() setMode(i) end)
    mBtns[i]=b
end

-- Editor
local Editor=Inp(P1,"-- Paste or type Lua here\n-- Client LS: runs locally\n-- Server LS: runs server-side via bridge\n-- Require: enter asset ID number\n-- URL Exec: enter a raw script URL",
    UDim2.new(1,0,0,188),UDim2.new(0,0,0,32))

-- Action row
local aRow=rowBar(P1,226)
local BExec =Btn(aRow,"▶ Execute",UDim2.new(0,130,1,0),nil,C.ACC)
local BClear=Btn(aRow,"Clear",    UDim2.new(0,76,1,0), nil,C.GREY)
local BCopy =Btn(aRow,"Copy",     UDim2.new(0,76,1,0), nil,C.GREY)
BExec.LayoutOrder=1; BClear.LayoutOrder=2; BCopy.LayoutOrder=3
hov(BExec,C.ACC,C.ACCHV); hov(BClear,C.GREY,C.GRYHV); hov(BCopy,C.GREY,C.GRYHV)

Lbl(P1,"Output",UDim2.new(0,55,0,14),UDim2.new(0,0,0,258),C.TXTS,FN,11)
local ExOut=Con(P1,UDim2.new(1,0,0,82),UDim2.new(0,0,0,274))

local function exOut(msg,isErr)
    ExOut.TextColor3=isErr and C.RED or C.GREEN; ExOut.Text=tostring(msg)
end

BExec.MouseButton1Click:Connect(function()
    local code=Editor.Text
    if code=="" then exOut("No code entered.",true); return end
    tw(BExec,{BackgroundColor3=C.ACCHV}); task.wait(0.07); tw(BExec,{BackgroundColor3=C.ACC})

    if curMode==1 then
        local fn,ce=loadstring(code)
        if not fn then exOut("Compile error:\n"..tostring(ce),true); return end
        local ok2,re=pcall(fn)
        exOut(ok2 and "Client exec OK." or "Runtime error:\n"..tostring(re), not ok2)

    elseif curMode==2 then
        local ok2,msg2=callBridge("ls",{code=code})
        exOut(msg2 or "(no response)", not ok2)

    elseif curMode==3 then
        local id=tonumber(code:match("%d+"))
        if not id then exOut("Enter a numeric Roblox asset ID.",true); return end
        local ok2,res=pcall(require,id)
        exOut(ok2 and ("require("..id..") OK.") or ("Error:\n"..tostring(res)), not ok2)

    elseif curMode==4 then
        local url=code:match("^%s*(.-)%s*$")
        if url=="" then exOut("Enter a raw script URL.",true); return end
        local ok2,src=pcall(game.HttpGet,game,url,true)
        if not ok2 then exOut("HTTP error:\n"..tostring(src),true); return end
        local fn,ce=loadstring(src)
        if not fn then exOut("Compile error:\n"..tostring(ce),true); return end
        local ok3,re=pcall(fn)
        exOut(ok3 and "URL exec OK." or ("Runtime error:\n"..tostring(re)), not ok3)
    end
end)
BClear.MouseButton1Click:Connect(function() Editor.Text=""; exOut("",false) end)
BCopy.MouseButton1Click:Connect(function()
    if setclipboard then setclipboard(Editor.Text); exOut("Copied.",false)
    else exOut("setclipboard not available.",true) end
end)

setMode(1)

-- ════════════════════════════════════════════════════════════════════════════════
--  TAB 2 — SERVER  (server-side commands + player actions)
-- ════════════════════════════════════════════════════════════════════════════════
local P2 = newTab("⚙","Server")

Lbl(P2,"SERVER COMMANDS",UDim2.new(1,0,0,16),UDim2.new(0,0,0,0),C.TXTS,FB,11)

local SrvOut=Con(P2,UDim2.new(1,0,0,80),UDim2.new(0,0,1,-82))
local function srvOut(msg,isErr)
    SrvOut.TextColor3=isErr and C.RED or C.GREEN; SrvOut.Text=tostring(msg)
end
local function bridgeOut(action,payload)
    local ok2,msg2,data=callBridge(action,payload)
    local lines={msg2 or ""}
    if data then for _,l in data do lines[#lines+1]=l end end
    srvOut(table.concat(lines,"\n"), not ok2)
end

-- Server script editor + run
Lbl(P2,"Server Loadstring:",UDim2.new(1,0,0,14),UDim2.new(0,0,0,20),C.TXTS,FN,11)
local SrvEdit=Inp(P2,"-- Code to run server-side...",UDim2.new(1,0,0,85),UDim2.new(0,0,0,36))
local sRow1=rowBar(P2,127)
local BSrvRun=Btn(sRow1,"▶ Run Server-Side",UDim2.new(0,150,1,0),nil,C.BLUE)
local BSrvURL=Btn(sRow1,"Run URL Server",    UDim2.new(0,130,1,0),nil,C.GREY)
BSrvRun.LayoutOrder=1; BSrvURL.LayoutOrder=2
hov(BSrvRun,C.BLUE,C.BLHV); hov(BSrvURL,C.GREY,C.GRYHV)

BSrvRun.MouseButton1Click:Connect(function()
    local code=SrvEdit.Text
    if code=="" then srvOut("No code.",true); return end
    bridgeOut("ls",{code=code})
end)
BSrvURL.MouseButton1Click:Connect(function()
    local url=SrvEdit.Text:match("^%s*(.-)%s*$")
    if url=="" then srvOut("Enter a URL.",true); return end
    bridgeOut("ls_url",{url=url})
end)

-- Utility buttons
local sRow2=rowBar(P2,161)
local BGetPlrs=Btn(sRow2,"Players",      UDim2.new(0,90,1,0),nil,C.GREY)
local BGetScr =Btn(sRow2,"Scripts",      UDim2.new(0,90,1,0),nil,C.GREY)
local BPing   =Btn(sRow2,"Ping Bridge",  UDim2.new(0,110,1,0),nil,C.ACC)
local BReq    =Btn(sRow2,"Require ID",   UDim2.new(0,100,1,0),nil,C.GREY)
BGetPlrs.LayoutOrder=1; BGetScr.LayoutOrder=2; BPing.LayoutOrder=3; BReq.LayoutOrder=4
for _,b in {BGetPlrs,BGetScr,BPing,BReq} do hov(b,b.BackgroundColor3,C.GRYHV) end

BGetPlrs.MouseButton1Click:Connect(function() bridgeOut("getplrs") end)
BGetScr.MouseButton1Click:Connect(function()  bridgeOut("get_scripts") end)
BPing.MouseButton1Click:Connect(function()
    local alive=pingBridge()
    srvOut(alive and "Bridge responded: pong ✓" or "Bridge offline.", not alive)
end)
BReq.MouseButton1Click:Connect(function()
    local id=tonumber(SrvEdit.Text:match("%d+"))
    if not id then srvOut("Paste a numeric asset ID into the editor.",true); return end
    bridgeOut("req",{id=id})
end)

-- ════════════════════════════════════════════════════════════════════════════════
--  TAB 3 — SANDBOX BYPASS
-- ════════════════════════════════════════════════════════════════════════════════
local P3 = newTab("⛓","Sandbox")

Lbl(P3,"SANDBOX BYPASS",UDim2.new(1,0,0,16),UDim2.new(0,0,0,0),C.TXTS,FB,11)

local SBOut=Con(P3,UDim2.new(1,0,0,56),UDim2.new(0,0,1,-58))
local function sbOut(msg,ok2) SBOut.TextColor3=ok2 and C.GREEN or C.RED; SBOut.Text=tostring(msg) end

local SBScr=Scr(P3,UDim2.new(1,0,1,-116),UDim2.new(0,0,0,20))
listV(SBScr,5)

local function utilRow(title, desc, btnTxt, btnCol, action)
    local Row=Frm(SBScr,UDim2.new(1,-4,0,50),nil,C.PANEL); corner(Row,7); stroke(Row,Color3.fromRGB(35,35,52),1)
    Lbl(Row,title, UDim2.new(1,-108,0,18),UDim2.new(0,8,0,5), C.TXT,FB,13)
    Lbl(Row,desc,  UDim2.new(1,-108,0,16),UDim2.new(0,8,0,25),C.TXTS,FN,11)
    local hv=Color3.fromRGB(math.min(255,(btnCol or C.ACC).R*255+28),math.min(255,(btnCol or C.ACC).G*255+28),math.min(255,(btnCol or C.ACC).B*255+28))
    local btn=Btn(Row,btnTxt,UDim2.new(0,88,0,26),UDim2.new(1,-96,0.5,-13),btnCol or C.ACC)
    hov(btn,btnCol or C.ACC,hv)
    btn.MouseButton1Click:Connect(function()
        local ok2,res=pcall(action); sbOut(res or (ok2 and "✓ Done." or "✗ Failed."), ok2)
    end)
end

utilRow("Elevate Thread Identity","setthreadidentity(8) — max script context","Elevate",C.ACC,function()
    local fn=setthreadidentity or (syn and syn.set_thread_identity)
    if not fn then return "✗ setthreadidentity not available." end
    fn(8)
    local gid=getthreadidentity or (syn and syn.get_thread_identity)
    return "✓ Identity=8"..(gid and " (confirmed "..tostring(gid())..")" or "")
end)

utilRow("Unlock game metatable","setreadonly(getrawmetatable(game),false)","Unlock",C.BLUE,function()
    if not getrawmetatable then return "✗ getrawmetatable missing." end
    if not setreadonly then return "✗ setreadonly missing." end
    setreadonly(getrawmetatable(game),false)
    return "✓ game metatable is writable."
end)

utilRow("Hook __namecall (remote spy)","Logs FireServer/InvokeServer to console","Hook",C.ORAN,function()
    if not hookmetamethod then return "✗ hookmetamethod missing." end
    if not getnamecallmethod then return "✗ getnamecallmethod missing." end
    local logged=0; local old2
    old2=hookmetamethod(game,"__namecall",function(self,...)
        local m=getnamecallmethod()
        if m=="FireServer" or m=="InvokeServer" then
            logged+=1; warn("[SS spy] "..tostring(self)..":"..m)
        end
        return old2(self,...)
    end)
    return "✓ __namecall hooked — remote calls logged to console."
end)

utilRow("Open getgenv()","Access the shared executor global env","Open",C.GREEN,function()
    if not getgenv then return "✗ getgenv not available." end
    local env=getgenv(); local n=0; for _ in pairs(env) do n+=1 end
    return "✓ getgenv() ok — "..n.." entries."
end)

utilRow("Open getrenv()","Access the real Roblox game environment","Open",C.PURP,function()
    if not getrenv then return "✗ getrenv not available." end
    getrenv(); return "✓ getrenv() ok."
end)

utilRow("Bypass metatable lock","Strips __index/__newindex guards from game","Bypass",C.RED,function()
    if not getrawmetatable or not setreadonly then return "✗ Missing functions." end
    local mt=getrawmetatable(game); setreadonly(mt,false)
    return "✓ Metatable lock removed."
end)

-- Custom snippet
local SnipBox=Inp(SBScr,"-- Custom bypass snippet...",UDim2.new(1,-4,0,60))
local sRow3=rowBar(P3,1,-60) -- positioned relative to bottom
sRow3.Size=UDim2.new(1,0,0,26); sRow3.Position=UDim2.new(0,0,1,-60)
local BSnip=Btn(sRow3,"▶ Run Snippet",UDim2.new(0,130,1,0),nil,C.ACC)
hov(BSnip,C.ACC,C.ACCHV)
BSnip.MouseButton1Click:Connect(function()
    local code=SnipBox.Text
    if code=="" then sbOut("Enter a snippet.",false); return end
    local fn,ce=loadstring(code)
    if not fn then sbOut("Compile error:\n"..tostring(ce),false); return end
    local ok2,re=pcall(fn)
    sbOut(ok2 and "✓ Snippet OK." or "✗ "..tostring(re), ok2)
end)

-- Capability summary
task.spawn(function()
    local caps={
        {"setthreadidentity",setthreadidentity},{"setreadonly",setreadonly},
        {"getrawmetatable",getrawmetatable},{"hookmetamethod",hookmetamethod},
        {"getgenv",getgenv},{"getrenv",getrenv},{"getnamecallmethod",getnamecallmethod},
    }
    local have,miss={},{}
    for _,c in caps do (c[2] and have or miss)[#(c[2] and have or miss)+1]=c[1] end
    sbOut(("Executor has %d/%d bypass functions.\nPresent: %s%s"):format(
        #have,#caps,table.concat(have,", "),
        #miss>0 and ("\nMissing: "..table.concat(miss,", ")) or ""), #miss==0)
end)

-- ════════════════════════════════════════════════════════════════════════════════
--  TAB 4 — MALWARE SCANNER
-- ════════════════════════════════════════════════════════════════════════════════
local P4 = newTab("🔎","Malware")

Lbl(P4,"MALWARE SCANNER",UDim2.new(1,0,0,16),UDim2.new(0,0,0,0),C.TXTS,FB,11)

local mwRow=rowBar(P4,20)
local BMwScan   =Btn(mwRow,"Scan Game",   UDim2.new(0,106,1,0),nil,C.ACC)
local BMwKillAll=Btn(mwRow,"Kill All",    UDim2.new(0,90,1,0), nil,C.RED)
local BMwScripts=Btn(mwRow,"List Scripts",UDim2.new(0,110,1,0),nil,C.BLUE)
BMwScan.LayoutOrder=1; BMwKillAll.LayoutOrder=2; BMwScripts.LayoutOrder=3
hov(BMwScan,C.ACC,C.ACCHV); hov(BMwKillAll,C.RED,C.REDHV); hov(BMwScripts,C.BLUE,C.BLHV)

local MwOut=Con(P4,UDim2.new(1,0,1,-54),UDim2.new(0,0,0,52))
local function mwOut(msg,ok2) MwOut.TextColor3=ok2 and C.GREEN or C.RED; MwOut.Text=tostring(msg) end
local function mwBridge(action,payload)
    local ok2,msg2,data=callBridge(action,payload)
    local lines={msg2 or ""}
    if data then for _,l in data do lines[#lines+1]=l end end
    mwOut(table.concat(lines,"\n"),ok2)
end

BMwScan.MouseButton1Click:Connect(function() mwOut("Scanning...",true); task.wait(0.05); mwBridge("scan") end)
BMwKillAll.MouseButton1Click:Connect(function() mwBridge("kill_all") end)
BMwScripts.MouseButton1Click:Connect(function() mwOut("Fetching...",true); task.wait(0.05); mwBridge("get_scripts") end)

-- ════════════════════════════════════════════════════════════════════════════════
--  TAB 5 — DEOBFUSCATOR
-- ════════════════════════════════════════════════════════════════════════════════
local P5 = newTab("👁","Deobfusc.")

Lbl(P5,"DEOBFUSCATOR",UDim2.new(1,0,0,16),UDim2.new(0,0,0,0),C.TXTS,FB,11)
Lbl(P5,"Input:",UDim2.new(0,45,0,12),UDim2.new(0,0,0,18),C.TXTS,FN,11)
local DIn=Inp(P5,"-- Paste obfuscated Lua here...",UDim2.new(1,0,0,152),UDim2.new(0,0,0,32))
local dRow=rowBar(P5,190)
local BDDet=Btn(dRow,"Detect Type",  UDim2.new(0,116,1,0),nil,C.BLUE)
local BDDeob=Btn(dRow,"Deobfuscate", UDim2.new(0,128,1,0),nil,C.ACC)
BDDet.LayoutOrder=1; BDDeob.LayoutOrder=2
hov(BDDet,C.BLUE,C.BLHV); hov(BDDeob,C.ACC,C.ACCHV)
Lbl(P5,"Output:",UDim2.new(0,55,0,12),UDim2.new(0,0,0,222),C.TXTS,FN,11)
local DOut=Con(P5,UDim2.new(1,0,1,-236),UDim2.new(0,0,0,236))

local function detectType(s)
    if s:lower():find("luraph")                        then return "Luraph VM" end
    if s:lower():find("getfenv") and s:find("0x%x+")  then return "IronBrew 2" end
    if s:lower():find("prometheus")                    then return "Prometheus" end
    if s:lower():find("moonsec")                       then return "Moonsec" end
    if s:find("\\x%x%x")                               then return "Hex-escape encoded" end
    if s:find("string%.char%(%d")                      then return "string.char encoded" end
    if s:find("_[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]")  then return "Hex-variable names" end
    return "Unknown / plain Lua"
end
local function deobfuscate(s)
    s=s:gsub("\\x(%x%x)",function(h) return string.char(tonumber(h,16)) end)
    s=s:gsub("\\(%d%d?%d?)",function(d) local n=tonumber(d); return (n and n<=255) and string.char(n) or "\\"..d end)
    s=s:gsub("string%.char%(([%d,%s]+)%)",function(args)
        local out={}; for n in args:gmatch("%d+") do local num=tonumber(n); if num then out[#out+1]=string.char(num) end end
        return '"'..table.concat(out)..'"'
    end)
    for _=1,6 do s=s:gsub('"([^"]*)"%s*%.%.%s*"([^"]*)"','"%1%2"') end
    return s
end

BDDet.MouseButton1Click:Connect(function()
    DOut.TextColor3=C.YELL; DOut.Text="Type: "..detectType(DIn.Text)
end)
BDDeob.MouseButton1Click:Connect(function()
    if DIn.Text=="" then DOut.TextColor3=C.RED; DOut.Text="Nothing to deobfuscate."; return end
    local ok2,res=pcall(deobfuscate,DIn.Text)
    DOut.TextColor3=ok2 and C.GREEN or C.RED; DOut.Text=ok2 and res or ("Error: "..tostring(res))
end)

-- ════════════════════════════════════════════════════════════════════════════════
--  TAB 6 — FUNCTION CHECKER  (UNC / SUNC / Myriad)
-- ════════════════════════════════════════════════════════════════════════════════
local P6 = newTab("✓","Checker")

-- Sub-tab row
local subRow=Frm(P6,UDim2.new(1,0,0,24),UDim2.new(0,0,0,0),C.EDIT,"SubRow"); corner(subRow,6)
listH(subRow,2); pad(subRow,2,2)
local ChkScr=Scr(P6,UDim2.new(1,0,1,-30),UDim2.new(0,0,0,28)); listV(ChkScr,2)
local subBtns2={}; local curSub=0

local function switchSub(i)
    curSub=i
    for j,b in subBtns2 do
        tw(b,{BackgroundColor3=j==i and C.ACC or C.PANEL}); b.TextColor3=j==i and C.TXT or C.TXTS
    end
end
local function addSub(name,order)
    local b=Btn(subRow,name,UDim2.new(0,156,1,0),nil,C.PANEL,C.TXTS)
    b.LayoutOrder=order; b.TextSize=12; hov(b,C.PANEL,Color3.fromRGB(28,28,40))
    b.MouseButton1Click:Connect(function() switchSub(order) end); subBtns2[order]=b
end
addSub("UNC (100)",1); addSub("SUNC (100)",2); addSub("Myriad (250)",3)

local UNC_LIST={"checkcaller","clonefunction","getcallingscript","getscriptclosure","getscriptfunction","iscclosure","islclosure","isnewcclosure","newcclosure","crypt.base64decode","crypt.base64encode","crypt.decrypt","crypt.encrypt","crypt.generatebytes","crypt.generatekey","crypt.hash","debug.getconstant","debug.getconstants","debug.getinfo","debug.getproto","debug.getprotos","debug.getstack","debug.getupvalue","debug.getupvalues","debug.setconstant","debug.setstack","debug.setupvalue","Drawing.new","cleardrawcache","getrenderproperty","isrenderobj","setrenderproperty","appendfile","delfile","isfile","isfolder","listfiles","loadfile","makefolder","readfile","writefile","isrbxactive","keypress","keyrelease","mouse1click","mouse1press","mouse1release","mouse2click","mouse2press","mouse2release","mousemoveabs","mousemoverel","mousescroll","fireclickdetector","firetouchinterest","gethiddenproperty","sethiddenproperty","getsimulationradius","setsimulationradius","getconnections","hookmetamethod","getrawmetatable","setrawmetatable","identifyexecutor","isexecutorclosure","queue_on_teleport","request","setfpscap","getfpscap","gethui","getnamecallmethod","setnamecallmethod","getloadedmodules","getrenv","getrunningscripts","getscripts","getsenv","firesignal","replicatesignal","getthreadidentity","setthreadidentity","http.request","httpget","syn.request","cache.invalidate","cache.iscached","cache.replace","cloneref","compareinstances","WebSocket.connect","rconsoleclose","rconsoleinfo","rconsoleinput","rconsolename","rconsoleprint","rconsoleclear","rconsoleopen","rconsolewarn"}
local SUNC_LIST={"getgenv","getrenv","getsenv","getfenv","setfenv","getscriptstate","setscriptstate","getthreadstate","setthreadstate","getscriptclosure","getscriptfunction","isscriptactive","killtask","getglobals","setglobal","getlocals","setlocal","getupvalues","setupvalue","getscriptbyname","getscriptbypath","getscriptbyid","findscript","getscriptparent","getscriptchildren","getscriptancestors","getscriptdescendants","getscriptid","getscripthash","getscriptbytecode","getscriptsource","patchscript","hookscript","replacescript","overwritescript","script.encrypt","script.decrypt","script.hash","script.sign","script.verify","sandbox.create","sandbox.destroy","sandbox.isolate","sandbox.expose","sandbox.getenv","sandbox.setenv","sandbox.run","sandbox.capture","sandbox.getresult","sandbox.getlog","sandbox.getoutput","sandbox.getstatus","scriptcontext.run","scriptcontext.stop","scriptcontext.pause","scriptcontext.resume","scriptcontext.getstatus","scriptcontext.getenv","scriptcontext.setenv","scriptcontext.capture","scriptcontext.getlog","scriptcontext.getoutput","scriptcontext.patchglobal","scriptcontext.hookfunction","scriptcontext.traceglobal","scriptcontext.sandbox","scriptcontext.unsandbox","scriptcontext.isolate","scriptcontext.expose","scriptcontext.getresult","scriptcontext.getid","scriptcontext.gethash","scriptcontext.getbytecode","scriptcontext.getsource","scriptcontext.sign","scriptcontext.verify","scriptcontext.encrypt","scriptcontext.decrypt","scriptcontext.replace","scriptcontext.overwrite","scriptcontext.patch","scriptcontext.hook","scriptcontext.kill","scriptcontext.find","scriptcontext.list","scriptcontext.count","scriptcontext.exists","scriptcontext.isactive","scriptcontext.isrunning","scriptcontext.issandboxed","scriptcontext.isisolated","scriptcontext.isexposed","scriptcontext.ishooked","scriptcontext.ispatched","scriptcontext.isreplaced","scriptcontext.isoverwritten","scriptcontext.isencrypted","scriptcontext.issigned","scriptcontext.isverified","scriptcontext.isdecrypted","scriptcontext.ishashed"}
local MYRIAD_LIST={"myr.drawing.new","myr.drawing.clear","myr.drawing.getall","myr.drawing.remove","myr.drawing.setproperty","myr.drawing.getproperty","myr.drawing.isobject","myr.drawing.oncreate","myr.drawing.onremove","myr.drawing.render","myr.drawing.hide","myr.drawing.show","myr.drawing.toggle","myr.drawing.setvisible","myr.drawing.getvisible","myr.drawing.setcolor","myr.drawing.getcolor","myr.drawing.setalpha","myr.drawing.getalpha","myr.drawing.setposition","myr.drawing.getposition","myr.drawing.setsize","myr.drawing.getsize","myr.mem.read","myr.mem.write","myr.mem.scan","myr.mem.alloc","myr.mem.free","myr.mem.protect","myr.mem.query","myr.mem.patch","myr.mem.compare","myr.mem.dump","myr.mem.restore","myr.mem.hook","myr.mem.unhook","myr.mem.getbase","myr.mem.getsize","myr.mem.gettype","myr.mem.getname","myr.mem.getpath","myr.mem.getclass","myr.mem.getparent","myr.mem.getchildren","myr.mem.getancestors","myr.mem.getdescendants","myr.net.request","myr.net.get","myr.net.post","myr.net.put","myr.net.delete","myr.net.patch","myr.net.head","myr.net.options","myr.net.trace","myr.net.connect","myr.net.listen","myr.net.close","myr.net.send","myr.net.receive","myr.net.getip","myr.net.getport","myr.net.gethost","myr.net.getpath","myr.net.getquery","myr.net.getfragment","myr.anti.detect","myr.anti.bypass","myr.anti.hook","myr.anti.unhook","myr.anti.patch","myr.anti.restore","myr.anti.scan","myr.anti.kill","myr.anti.block","myr.anti.allow","myr.anti.log","myr.anti.alert","myr.anti.monitor","myr.anti.trace","myr.anti.intercept","myr.anti.redirect","myr.anti.spoof","myr.anti.mask","myr.anti.hide","myr.anti.show","myr.spy.hook","myr.spy.unhook","myr.spy.intercept","myr.spy.monitor","myr.spy.trace","myr.spy.log","myr.spy.capture","myr.spy.replay","myr.spy.block","myr.spy.allow","myr.spy.redirect","myr.spy.spoof","myr.spy.getremotes","myr.spy.fireremote","myr.spy.invokefunc","myr.spy.hookremote","myr.spy.unhookremote","myr.spy.logremote","myr.spy.capturefunc","myr.spy.replayfunc","myr.byte.read","myr.byte.write","myr.byte.scan","myr.byte.patch","myr.byte.compare","myr.byte.dump","myr.byte.restore","myr.byte.encode","myr.byte.decode","myr.byte.encrypt","myr.byte.decrypt","myr.byte.hash","myr.byte.sign","myr.byte.verify","myr.byte.compress","myr.byte.decompress","myr.byte.pack","myr.byte.unpack","myr.byte.convert","myr.byte.format","myr.ui.create","myr.ui.destroy","myr.ui.get","myr.ui.set","myr.ui.find","myr.ui.list","myr.ui.show","myr.ui.hide","myr.ui.toggle","myr.ui.move","myr.ui.resize","myr.ui.recolor","myr.ui.retextsize","myr.ui.refont","myr.ui.retext","myr.ui.reimage","myr.ui.reparent","myr.ui.clone","myr.ui.tween","myr.ui.animate","myr.phys.setvelocity","myr.phys.getvelocity","myr.phys.setposition","myr.phys.getposition","myr.phys.setrotation","myr.phys.getrotation","myr.phys.setgravity","myr.phys.getgravity","myr.phys.setmass","myr.phys.getmass","myr.phys.setfriction","myr.phys.getfriction","myr.phys.setelasticity","myr.phys.getelasticity","myr.phys.setdensity","myr.phys.getdensity","myr.phys.noclip","myr.phys.clip","myr.phys.fly","myr.phys.land","myr.rep.fire","myr.rep.invoke","myr.rep.hook","myr.rep.unhook","myr.rep.block","myr.rep.allow","myr.rep.log","myr.rep.capture","myr.rep.replay","myr.rep.redirect","myr.rep.spoof","myr.rep.create","myr.rep.destroy","myr.rep.rename","myr.rep.clone","myr.rep.move","myr.rep.reparent","myr.rep.getall","myr.rep.find","myr.rep.monitor","myr.game.getservice","myr.game.findservice","myr.game.listservices","myr.game.getplayers","myr.game.findplayer","myr.game.kickplayer","myr.game.getcharacter","myr.game.respawn","myr.game.teleport","myr.game.getworkspace","myr.game.getlighting","myr.game.getreplicatedstorage","myr.game.getstartergui","myr.game.getstartpack","myr.game.getstartchar","myr.game.getserverstorage","myr.game.getscriptcontext","myr.game.getrunservice","myr.game.getuserinputservice","myr.game.getcontentprovider","myr.game.gethttpservice","myr.game.gettweenservice","myr.game.getmarketplaceservice","myr.debug.getinfo","myr.debug.getstack","myr.debug.traceback","myr.debug.profilebegin","myr.debug.profileend","myr.debug.getupvalue","myr.debug.setupvalue","myr.debug.getconstant","myr.debug.setconstant","myr.debug.getproto","myr.debug.getprotos","myr.debug.setproto","myr.debug.getlocal","myr.debug.setlocal","myr.debug.getmetatable","myr.debug.setmetatable","myr.debug.rawget","myr.debug.rawset","myr.debug.rawequal","myr.debug.rawlen","myr.event.fire","myr.event.connect","myr.event.disconnect","myr.event.wait","myr.event.once","myr.event.hook","myr.event.unhook","myr.event.block","myr.event.allow","myr.event.log","myr.event.capture","myr.event.replay","myr.event.redirect","myr.event.spoof","myr.event.monitor","myr.event.trace","myr.event.getconnections","myr.event.getlisteners","myr.event.getsignals","myr.event.getevents","myr.event.getfirers","myr.exec.run","myr.exec.load","myr.exec.require","myr.exec.dofile","myr.exec.dostring","myr.exec.loadfile","myr.exec.loadstring","myr.exec.loadbytecode","myr.exec.runfile","myr.exec.runstring","myr.exec.runbytecode","myr.exec.runurl","myr.exec.inject","myr.exec.eject","myr.exec.hook","myr.exec.unhook","myr.exec.patch","myr.exec.unpatch","myr.exec.sandbox","myr.exec.unsandbox","myr.lic.check","myr.lic.verify","myr.lic.activate","myr.lic.deactivate","myr.lic.getkey","myr.lic.setkey","myr.lic.getexpiry","myr.lic.isvalid","myr.lic.getuser","myr.lic.getplan","myr.lic.getfeatures","myr.lic.hasfeature","myr.lic.getlimit","myr.lic.getusage","myr.lic.increment","myr.lic.decrement","myr.lic.reset","myr.lic.getlog","myr.lic.audit","myr.lic.revoke","myr.inst.create","myr.inst.clone","myr.inst.destroy","myr.inst.get","myr.inst.set","myr.inst.find","myr.inst.list","myr.inst.filter","myr.inst.hook","myr.inst.unhook","myr.inst.wrap","myr.inst.unwrap","myr.inst.lock","myr.inst.unlock","myr.inst.hide","myr.inst.show","myr.inst.rename","myr.inst.retype","myr.inst.reparent","myr.inst.reclass","myr.inst.getprop","myr.inst.setprop","myr.inst.hasprop","myr.inst.listprops"}

local LISTS={UNC_LIST,SUNC_LIST,MYRIAD_LIST}
local LCOLS={C.ACC,C.BLUE,C.YELL}

local function hasFunc(name)
    local root=name:match("^([^%.]+)%.")
    if root then
        local tbl=(getfenv and getfenv()[root]) or _G[root]
        if type(tbl)=="table" then local sub=name:match("%.(.+)$"); return tbl[sub]~=nil end
        return false
    end
    if getfenv and getfenv()[name]~=nil then return true end
    return _G[name]~=nil
end

local function buildList(li)
    for _,ch in ChkScr:GetChildren() do if not ch:IsA("UIListLayout") then ch:Destroy() end end
    local list=LISTS[li]; local col=LCOLS[li]; local pass,fail=0,0
    for _,name in list do
        local ok2=hasFunc(name); if ok2 then pass+=1 else fail+=1 end
        local Row=Frm(ChkScr,UDim2.new(1,-4,0,22),nil,Color3.fromRGB(0,0,0))
        Row.BackgroundTransparency=1
        local dot=Frm(Row,UDim2.new(0,6,0,6),UDim2.new(0,1,0,8),ok2 and C.GREEN or C.RED); corner(dot,3)
        Lbl(Row,name,UDim2.new(1,-50,1,0),UDim2.new(0,11,0,0),ok2 and C.TXT or C.TXTS,FC,12)
        Lbl(Row,ok2 and "✓" or "✗",UDim2.new(0,28,1,0),UDim2.new(1,-30,0,0),
            ok2 and col or C.RED,FB,13,Enum.TextXAlignment.Right)
    end
    local SR=Frm(ChkScr,UDim2.new(1,-4,0,24),nil,C.PANEL); corner(SR,5)
    Lbl(SR,string.format("  %d/%d supported  (%d missing)",pass,pass+fail,fail),
        UDim2.new(1,0,1,0),nil,C.YELL,FB,12,Enum.TextXAlignment.Center)
end

subBtns2[1].MouseButton1Click:Connect(function() buildList(1) end)
subBtns2[2].MouseButton1Click:Connect(function() buildList(2) end)
subBtns2[3].MouseButton1Click:Connect(function() buildList(3) end)

-- ════════════════════════════════════════════════════════════════════════════════
--  TAB 7 — ENVIRONMENT DIAGNOSTICS
-- ════════════════════════════════════════════════════════════════════════════════
local P7 = newTab("🧪","Environ")

Lbl(P7,"ENVIRONMENT DIAGNOSTICS",UDim2.new(1,0,0,16),UDim2.new(0,0,0,0),C.TXTS,FB,11)

local envRow=rowBar(P7,18)
local BEnvRun =Btn(envRow,"Run Check", UDim2.new(0,116,1,0),nil,C.ACC)
local BEnvCopy=Btn(envRow,"Copy Report",UDim2.new(0,110,1,0),nil,C.GREY)
BEnvRun.LayoutOrder=1; BEnvCopy.LayoutOrder=2
hov(BEnvRun,C.ACC,C.ACCHV); hov(BEnvCopy,C.GREY,C.GRYHV)

local ExecLbl=Lbl(P7,"Executor: checking...",UDim2.new(1,0,0,18),UDim2.new(0,0,0,50),C.TXTS,FC,12)
local EnvScr=Scr(P7,UDim2.new(1,0,1,-72),UDim2.new(0,0,0,72)); listV(EnvScr,2)

local reportLines={}

local function clrEnv()
    for _,ch in EnvScr:GetChildren() do if not ch:IsA("UIListLayout") then ch:Destroy() end end
    reportLines={}
end
local function catHdr(title)
    local R=Frm(EnvScr,UDim2.new(1,-4,0,20),nil,C.PANEL); corner(R,5)
    Lbl(R,"  "..title,UDim2.new(1,0,1,0),nil,C.PURP,FB,11)
    reportLines[#reportLines+1]="== "..title.." =="
end
local function chkRow(name, ok2, detail)
    local R=Frm(EnvScr,UDim2.new(1,-4,0,20),nil,Color3.fromRGB(0,0,0)); R.BackgroundTransparency=1
    local dot=Frm(R,UDim2.new(0,5,0,5),UDim2.new(0,2,0,7),ok2 and C.GREEN or C.RED); corner(dot,3)
    Lbl(R,name,UDim2.new(0.48,0,1,0),UDim2.new(0,10,0,0),ok2 and C.TXT or C.TXTS,FC,11)
    Lbl(R,detail or (ok2 and "ok" or "missing"),
        UDim2.new(0.52,-8,1,0),UDim2.new(0.48,0,0,0),ok2 and C.GREEN or C.RED,FN,11)
    reportLines[#reportLines+1]=(ok2 and "[✓] " or "[✗] ")..name.." — "..(detail or "")
end

local function runCheck()
    clrEnv()
    local exec="Unknown"
    if identifyexecutor then pcall(function() exec=tostring(select(1,identifyexecutor())) end)
    elseif getexecutorname then pcall(function() exec=tostring(getexecutorname()) end) end
    ExecLbl.Text="Executor: "..exec; ExecLbl.TextColor3=C.GREEN

    catHdr("Execution Engine")
    chkRow("loadstring",     type(loadstring)=="function", type(loadstring)=="function" and "available" or "DISABLED — scripts will fail")
    chkRow("pcall",          type(pcall)=="function")
    chkRow("LuaU (continue)",(function() return loadstring and pcall(loadstring,"local function f() for i=1,1 do continue end end") end)(), "Roblox LuaU syntax")
    chkRow("task scheduler", type(task)=="table" and type(task.wait)=="function")

    catHdr("Environment Functions")
    chkRow("getgenv",  type(getgenv)=="function")
    chkRow("getrenv",  type(getrenv)=="function")
    chkRow("getfenv",  type(getfenv)=="function")
    chkRow("shared",   type(shared)=="table",  type(shared)=="table" and "global shared table" or "missing")
    chkRow("_G",       type(_G)=="table")
    chkRow("game:GetService", (function() return pcall(function() return game:GetService("Players") end) end)())

    catHdr("File System")
    chkRow("writefile", type(writefile)=="function")
    chkRow("readfile",  type(readfile)=="function")
    chkRow("isfile",    type(isfile)=="function")
    chkRow("makefolder",type(makefolder)=="function")
    chkRow("listfiles", type(listfiles)=="function")

    catHdr("HTTP")
    chkRow("game:HttpGet",  type(game.HttpGet)=="function")
    chkRow("request",       type(request)=="function" or (http and type(http.request)=="function") or (syn and type(syn.request)=="function"))
    chkRow("HttpService",   (function() return pcall(function() return game:GetService("HttpService") end) end)())

    catHdr("Sandbox / Injection")
    chkRow("getrawmetatable",   type(getrawmetatable)=="function")
    chkRow("setreadonly",       type(setreadonly)=="function")
    chkRow("hookmetamethod",    type(hookmetamethod)=="function")
    chkRow("hookfunction",      type(hookfunction)=="function" or type(replaceclosure)=="function")
    chkRow("setthreadidentity", type(setthreadidentity)=="function")
    chkRow("gethui",            type(gethui)=="function", type(gethui)=="function" and "available" or "using PlayerGui fallback")

    catHdr("RemoteEvent / RemoteFunction")
    chkRow("getnamecallmethod", type(getnamecallmethod)=="function")
    chkRow("firesignal",        type(firesignal)=="function")
    chkRow("getconnections",    type(getconnections)=="function")
    chkRow("SS_ExecBridge",     Bridge~=nil, Bridge and "server bridge ready" or "inject SS_Executor.lua server-side")

    catHdr("Game State")
    chkRow("game:IsLoaded()", game:IsLoaded(), game:IsLoaded() and "fully loaded" or "still loading — wait before running scripts")
    chkRow("LocalPlayer",     LP~=nil)
    chkRow("Character",       LP and LP.Character~=nil, (LP and LP.Character) and "spawned" or "not spawned yet")

    -- score
    local pass2,total2=0,0
    for _,ln in reportLines do
        if ln:sub(1,4)=="[✓]" then pass2+=1; total2+=1 elseif ln:sub(1,4)=="[✗]" then total2+=1 end
    end
    local SR=Frm(EnvScr,UDim2.new(1,-4,0,24),nil,C.PANEL); corner(SR,5)
    Lbl(SR,string.format("  %d / %d checks passed",pass2,total2),
        UDim2.new(1,0,1,0),nil,C.YELL,FB,12,Enum.TextXAlignment.Center)
end

BEnvRun.MouseButton1Click:Connect(runCheck)
BEnvCopy.MouseButton1Click:Connect(function()
    if setclipboard then setclipboard(table.concat(reportLines,"\n")); ExecLbl.Text="Report copied ✓"; ExecLbl.TextColor3=C.GREEN end
end)

-- ════════════════════════════════════════════════════════════════════════════════
--  DRAG  (PC + Mobile)
-- ════════════════════════════════════════════════════════════════════════════════
local drag,ds,dp=false,nil,nil
TBAR.InputBegan:Connect(function(inp)
    local t=inp.UserInputType
    if t==Enum.UserInputType.MouseButton1 or t==Enum.UserInputType.Touch then
        drag=true; ds=inp.Position; dp=WIN.Position
    end
end)
UIS.InputChanged:Connect(function(inp)
    if not drag then return end
    local t=inp.UserInputType
    if t==Enum.UserInputType.MouseMovement or t==Enum.UserInputType.Touch then
        local d=inp.Position-ds
        WIN.Position=UDim2.new(dp.X.Scale,dp.X.Offset+d.X,dp.Y.Scale,dp.Y.Offset+d.Y)
    end
end)
UIS.InputEnded:Connect(function(inp)
    local t=inp.UserInputType
    if t==Enum.UserInputType.MouseButton1 or t==Enum.UserInputType.Touch then drag=false end
end)

-- ════════════════════════════════════════════════════════════════════════════════
--  MINIMISE
-- ════════════════════════════════════════════════════════════════════════════════
local mini=false
BtnMin.MouseButton1Click:Connect(function()
    mini=not mini
    tw(WIN,{Size=mini and UDim2.new(0,590,0,42) or UDim2.new(0,590,0,462)},TS2)
    BODY.Visible=not mini; SIDE.Visible=not mini
    BtnMin.Text=mini and "□" or "—"
end)

-- ════════════════════════════════════════════════════════════════════════════════
--  INIT
-- ════════════════════════════════════════════════════════════════════════════════
showPage(1)
switchSub(1); buildList(1)
runCheck()

end)  -- end pcall

if not _ok then warn("[SS Executor] STARTUP ERROR: "..tostring(_err)) end
