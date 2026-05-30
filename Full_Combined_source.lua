-- ================================================================
--  NEXUS EXECUTOR  v7  |  Full Featured — Zero HTTP Dependencies
--  Delta (iOS/iPad), Synapse X, Krnl, Fluxus, Wave
--  10 tabs: Execute · Server · Sandbox · Player · RemoteSpy
--            Scanner · Deobfusc · Checker · Scripts · Environ
-- ================================================================
local _ok,_err=pcall(function()

local Players =game:GetService("Players")
local RS      =game:GetService("ReplicatedStorage")
local UIS     =game:GetService("UserInputService")
local TS      =game:GetService("TweenService")
local RUN     =game:GetService("RunService")
local SG      =game:GetService("StarterGui")
local WS      =game:GetService("Workspace")
local HTTP    =game:GetService("HttpService")

local LP
for _=1,120 do LP=Players.LocalPlayer; if LP then break end; task.wait(0.1) end
if not LP then warn("[Nexus] No LocalPlayer"); return end

local function getGuiParent()
    if gethui then return gethui() end
    local pg=LP:FindFirstChildOfClass("PlayerGui")
    if pg then return pg end
    return LP:WaitForChild("PlayerGui",15)
end
local PGui=getGuiParent()
if not PGui then warn("[Nexus] No PGui"); return end

local old=PGui:FindFirstChild("__SS_EXEC__"); if old then old:Destroy() end

local function notify(t,b,d)
    pcall(function() SG:SetCore("SendNotification",{Title=t,Text=b,Duration=d or 3}) end)
end
notify("Nexus Executor","Loading…",2)

local Bridge=RS:FindFirstChild("SS_ExecBridge")
local function pingBridge()
    if not Bridge then return false end
    local ok,r=pcall(function() return Bridge:InvokeServer("ping") end)
    return ok and r and r.ok
end
local function callBridge(act,pay)
    if not Bridge then return false,"No bridge — inject SS_Executor.lua first." end
    local ok,r=pcall(function() return Bridge:InvokeServer(act,pay or {}) end)
    if not ok then return false,tostring(r) end
    return r.ok,r.msg,r.data
end

local _ld=loadstring or load

-- ── Theme ──────────────────────────────────────────────────────────────────────
local C={
    BG    =Color3.fromRGB(13,17,30),   SIDE  =Color3.fromRGB(8,11,20),
    PANEL =Color3.fromRGB(22,28,46),   EDIT  =Color3.fromRGB(12,16,28),
    CON   =Color3.fromRGB(8,11,20),    BDR   =Color3.fromRGB(40,52,92),
    ACC   =Color3.fromRGB(59,130,246), ACCHV =Color3.fromRGB(96,165,250),
    BLUE  =Color3.fromRGB(59,130,246), BLHV  =Color3.fromRGB(96,165,250),
    GRN   =Color3.fromRGB(34,197,94),  GRNHV =Color3.fromRGB(74,222,128),
    RED   =Color3.fromRGB(220,55,55),  REDHV =Color3.fromRGB(248,80,80),
    YELL  =Color3.fromRGB(250,204,21), YELLHV=Color3.fromRGB(253,224,71),
    ORAN  =Color3.fromRGB(249,115,22), ORANHV=Color3.fromRGB(253,150,60),
    GREY  =Color3.fromRGB(50,60,86),   GRYHV =Color3.fromRGB(70,84,118),
    PURP  =Color3.fromRGB(139,92,246), PURPHV=Color3.fromRGB(167,139,250),
    TEAL  =Color3.fromRGB(20,184,166), TEALHV=Color3.fromRGB(45,212,191),
    PINK  =Color3.fromRGB(236,72,153), PINKHV=Color3.fromRGB(244,114,182),
    TXT   =Color3.fromRGB(241,245,249),TXTS  =Color3.fromRGB(148,163,184),
    TXTD  =Color3.fromRGB(55,70,100),  WHT   =Color3.new(1,1,1),
    BLK   =Color3.new(0,0,0),
}
local TF =TweenInfo.new(0.12,Enum.EasingStyle.Quad)
local TS2=TweenInfo.new(0.22,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
local FB =Enum.Font.GothamBold
local FN =Enum.Font.Gotham
local FC =Enum.Font.Code

-- ── UI helpers ────────────────────────────────────────────────────────────────
local function tw(o,p,ti) TS:Create(o,ti or TF,p):Play() end
local function corner(p,r) local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r or 7);c.Parent=p end
local function stroke(p,col,th) local s=Instance.new("UIStroke");s.Color=col or C.BDR;s.Thickness=th or 1.2;s.Parent=p end
local function pad(p,v,h)
    local u=Instance.new("UIPadding")
    u.PaddingTop=UDim.new(0,v or 6);u.PaddingBottom=UDim.new(0,v or 6)
    u.PaddingLeft=UDim.new(0,h or v or 9);u.PaddingRight=UDim.new(0,h or v or 9);u.Parent=p
end
local function listH(p,sp) local l=Instance.new("UIListLayout");l.FillDirection=Enum.FillDirection.Horizontal;l.SortOrder=Enum.SortOrder.LayoutOrder;l.Padding=UDim.new(0,sp or 4);l.Parent=p end
local function listV(p,sp) local l=Instance.new("UIListLayout");l.FillDirection=Enum.FillDirection.Vertical;l.SortOrder=Enum.SortOrder.LayoutOrder;l.Padding=UDim.new(0,sp or 4);l.Parent=p end
local function F(par,sz,pos,col,nm)
    local f=Instance.new("Frame");f.Size=sz;f.Position=pos or UDim2.new(0,0,0,0)
    f.BackgroundColor3=col or C.PANEL;f.BorderSizePixel=0;f.Name=nm or "F";f.Parent=par;return f
end
local function L(par,txt,sz,pos,col,fnt,ts,xa)
    local l=Instance.new("TextLabel");l.Size=sz;l.Position=pos or UDim2.new(0,0,0,0)
    l.BackgroundTransparency=1;l.Text=txt or "";l.TextColor3=col or C.TXT;l.Font=fnt or FN
    l.TextSize=ts or 13;l.TextXAlignment=xa or Enum.TextXAlignment.Left
    l.TextYAlignment=Enum.TextYAlignment.Center;l.TextTruncate=Enum.TextTruncate.AtEnd;l.Parent=par;return l
end
local function B(par,txt,sz,pos,bg,tc)
    local b=Instance.new("TextButton");b.Size=sz;b.Position=pos or UDim2.new(0,0,0,0)
    b.BackgroundColor3=bg or C.ACC;b.BorderSizePixel=0;b.Text=txt or "";b.TextColor3=tc or C.TXT
    b.Font=FB;b.TextSize=12;b.AutoButtonColor=false;b.Parent=par;corner(b,6);return b
end
local function IN(par,ph,sz,pos,ml)
    local b=Instance.new("TextBox");b.Size=sz;b.Position=pos or UDim2.new(0,0,0,0)
    b.BackgroundColor3=C.EDIT;b.BorderSizePixel=0;b.Text="";b.PlaceholderText=ph or ""
    b.TextColor3=C.TXT;b.PlaceholderColor3=C.TXTS;b.Font=FC;b.TextSize=12
    b.TextXAlignment=Enum.TextXAlignment.Left;b.TextYAlignment=Enum.TextYAlignment.Top
    b.ClearTextOnFocus=false;b.MultiLine=ml~=false;b.TextWrapped=true;b.ClipsDescendants=true
    b.Parent=par;corner(b,6);stroke(b,C.BDR,1);pad(b,6,10);return b
end
local function OUT(par,sz,pos,ph)
    local b=Instance.new("TextBox");b.Size=sz;b.Position=pos or UDim2.new(0,0,0,0)
    b.BackgroundColor3=C.CON;b.BorderSizePixel=0;b.Text="";b.PlaceholderText=ph or "> output..."
    b.TextColor3=C.GRN;b.PlaceholderColor3=C.TXTD;b.Font=FC;b.TextSize=11
    b.TextXAlignment=Enum.TextXAlignment.Left;b.TextYAlignment=Enum.TextYAlignment.Top
    b.ClearTextOnFocus=false;b.MultiLine=true;b.TextWrapped=true;b.TextEditable=false;b.ClipsDescendants=true
    b.Parent=par;corner(b,6);stroke(b,C.BDR,1);pad(b,6,10);return b
end
local function SCR(par,sz,pos)
    local s=Instance.new("ScrollingFrame");s.Size=sz;s.Position=pos or UDim2.new(0,0,0,0)
    s.BackgroundTransparency=1;s.BorderSizePixel=0;s.ScrollBarThickness=3
    s.ScrollBarImageColor3=C.ACC;s.CanvasSize=UDim2.new(0,0,0,0)
    s.AutomaticCanvasSize=Enum.AutomaticSize.Y;s.Parent=par;return s
end
local function hov(btn,n,h)
    btn.MouseEnter:Connect(function()       tw(btn,{BackgroundColor3=h}) end)
    btn.MouseLeave:Connect(function()       tw(btn,{BackgroundColor3=n}) end)
    btn.MouseButton1Down:Connect(function() tw(btn,{BackgroundColor3=n}) end)
    btn.MouseButton1Up:Connect(function()   tw(btn,{BackgroundColor3=h}) end)
end
local function rowBar(par,yOff,h)
    local r=F(par,UDim2.new(1,0,0,h or 26),UDim2.new(0,0,0,yOff or 0),C.BLK)
    r.BackgroundTransparency=1;listH(r,4);return r
end
local function sectionHdr(par,txt,yOff)
    local r=F(par,UDim2.new(1,0,0,20),UDim2.new(0,0,0,yOff),C.PANEL);corner(r,5)
    L(r,"  "..txt,UDim2.new(1,0,1,0),nil,C.PURP,FB,11);return r
end
local function toggleBtn(par,txt,sz,pos,onCol,offCol)
    local state=false; local b=B(par,txt,sz,pos,offCol or C.GREY)
    local function refresh() tw(b,{BackgroundColor3=state and (onCol or C.GRN) or (offCol or C.GREY)}) end
    b.MouseButton1Click:Connect(function() state=not state; refresh() end)
    return b,function() return state end,function(v) state=v; refresh() end
end

-- ── Window ────────────────────────────────────────────────────────────────────
local GUI=Instance.new("ScreenGui")
GUI.Name="__SS_EXEC__";GUI.ResetOnSpawn=false;GUI.IgnoreGuiInset=true
GUI.DisplayOrder=999;GUI.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;GUI.Parent=PGui

local WIN=F(GUI,UDim2.new(0,650,0,530),UDim2.new(0.5,-325,0.5,-265),C.BG,"Window")
corner(WIN,12);stroke(WIN,C.BDR,1.5)

local Sh=Instance.new("ImageLabel");Sh.Size=UDim2.new(1,60,1,60);Sh.Position=UDim2.new(0,-30,0,-30)
Sh.BackgroundTransparency=1;Sh.Image="rbxassetid://6014261993";Sh.ImageColor3=C.BLK
Sh.ImageTransparency=0.38;Sh.ScaleType=Enum.ScaleType.Slice;Sh.SliceCenter=Rect.new(49,49,450,450)
Sh.ZIndex=0;Sh.Parent=WIN

local TBAR=F(WIN,UDim2.new(1,0,0,44),UDim2.new(0,0,0,0),C.SIDE,"TBar");corner(TBAR,12)
F(WIN,UDim2.new(1,0,0,12),UDim2.new(0,0,0,32),C.SIDE)

local LBG=F(TBAR,UDim2.new(0,30,0,30),UDim2.new(0,9,0,7),C.ACC);corner(LBG,8)
L(LBG,"⚡",UDim2.new(1,0,1,0),nil,C.WHT,FB,16,Enum.TextXAlignment.Center)
L(TBAR,"NEXUS",UDim2.new(0,60,0,22),UDim2.new(0,46,0,3),C.WHT,FB,16)
L(TBAR,"EXECUTOR  v7",UDim2.new(0,110,0,13),UDim2.new(0,46,0,24),C.TXTS,FN,10)

local ODot=F(TBAR,UDim2.new(0,8,0,8),UDim2.new(0,163,0,18),C.GREY);corner(ODot,4)
local BridgeTxt=L(TBAR,"checking...",UDim2.new(0,120,0,14),UDim2.new(0,178,0,15),C.TXTS,FN,11)

local FpsTxt=L(TBAR,"",UDim2.new(0,72,0,14),UDim2.new(0,308,0,15),C.TXTD,FN,10)
local _fconn; _fconn=RUN.RenderStepped:Connect(function(dt) FpsTxt.Text=("%.0f fps"):format(1/dt) end)

local BtnMin=B(TBAR,"—",UDim2.new(0,28,0,24),UDim2.new(1,-66,0,10),C.GREY)
local BtnX  =B(TBAR,"✕",UDim2.new(0,28,0,24),UDim2.new(1,-34,0,10),C.RED)
hov(BtnMin,C.GREY,C.GRYHV);hov(BtnX,C.RED,C.REDHV)
BtnX.MouseButton1Click:Connect(function()
    if _fconn then _fconn:Disconnect() end
    tw(WIN,{BackgroundTransparency=1});task.wait(0.15);GUI:Destroy()
end)

task.spawn(function()
    local alive=pingBridge()
    ODot.BackgroundColor3=alive and C.GRN or C.RED
    BridgeTxt.Text=alive and "bridge ✓" or "no bridge"
    BridgeTxt.TextColor3=alive and C.GRN or C.RED
end)

local SIDE=F(WIN,UDim2.new(0,54,1,-44),UDim2.new(0,0,0,44),C.SIDE,"Side")
F(WIN,UDim2.new(0,1,1,-44),UDim2.new(0,54,0,44),Color3.fromRGB(32,44,82))
local BODY=F(WIN,UDim2.new(1,-60,1,-50),UDim2.new(0,57,0,48),C.BLK,"Body")
BODY.BackgroundTransparency=1

-- ── Tab system ────────────────────────────────────────────────────────────────
local sbBtns,pages,curPage,tabN={},{},0,0
local TCOL={
    Color3.fromRGB(59,130,246), Color3.fromRGB(34,197,94),
    Color3.fromRGB(249,115,22), Color3.fromRGB(236,72,153),
    Color3.fromRGB(139,92,246), Color3.fromRGB(220,55,55),
    Color3.fromRGB(250,204,21), Color3.fromRGB(20,184,166),
    Color3.fromRGB(96,165,250), Color3.fromRGB(167,139,250),
}
local function showPage(idx)
    for i,p in pages  do p.Visible=(i==idx) end
    for i,b in sbBtns do
        local ac=TCOL[i] or C.ACC
        tw(b,{BackgroundColor3=i==idx and ac or Color3.fromRGB(16,16,24),
              TextColor3=i==idx and C.WHT or C.TXTD})
    end
    curPage=idx
end
local function newTab(icon,label)
    tabN+=1;local idx=tabN
    local yp=8+(idx-1)*40; local ac=TCOL[idx] or C.ACC
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(0,38,0,34);btn.Position=UDim2.new(0,8,0,yp)
    btn.BackgroundColor3=Color3.fromRGB(16,16,24);btn.Text=icon
    btn.TextColor3=C.TXTD;btn.Font=FB;btn.TextSize=18
    btn.AutoButtonColor=false;btn.BorderSizePixel=0;btn.Parent=SIDE
    corner(btn,8)
    local tipW=math.max(80,#label*8+16)
    local tip=Instance.new("TextLabel")
    tip.Size=UDim2.new(0,tipW,0,22);tip.Position=UDim2.new(1,6,0,yp+6)
    tip.BackgroundColor3=C.PANEL;tip.Text=label;tip.TextColor3=C.TXT
    tip.Font=FN;tip.TextSize=11;tip.TextXAlignment=Enum.TextXAlignment.Center
    tip.BorderSizePixel=0;tip.ZIndex=15;tip.Visible=false;tip.Parent=SIDE
    corner(tip,5);stroke(tip,ac,1)
    btn.MouseEnter:Connect(function()
        tip.Visible=true
        if curPage~=idx then tw(btn,{BackgroundColor3=Color3.fromRGB(22,22,34),TextColor3=C.TXTS}) end
    end)
    btn.MouseLeave:Connect(function()
        tip.Visible=false
        if curPage~=idx then tw(btn,{BackgroundColor3=Color3.fromRGB(16,16,24),TextColor3=C.TXTD}) end
    end)
    btn.MouseButton1Click:Connect(function() showPage(idx) end)
    sbBtns[idx]=btn
    local pg=F(BODY,UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),C.BLK,"P"..idx)
    pg.BackgroundTransparency=1;pg.Visible=false;pages[idx]=pg;return pg
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB 1 — EXECUTE
-- ═══════════════════════════════════════════════════════════════════════════════
local P1=newTab("▶","Execute")

-- Mode bar
local mRow=rowBar(P1,0,26)
local MODES={"Client LS","Server LS","Require","URL Exec","File Exec"}
local mBtns={};local curMode=1
local function setMode(i)
    curMode=i
    for j,b in mBtns do
        tw(b,{BackgroundColor3=j==i and C.BLUE or C.EDIT})
        b.TextColor3=j==i and C.TXT or C.TXTS
    end
end
for i,nm in MODES do
    local w=i==1 and 108 or (i<=3 and 90 or 98)
    local b=B(mRow,nm,UDim2.new(0,w,1,0),nil,i==1 and C.BLUE or C.EDIT,C.TXTS)
    b.LayoutOrder=i;b.TextSize=11;hov(b,C.EDIT,C.BLHV)
    b.MouseButton1Click:Connect(function() setMode(i) end);mBtns[i]=b
end

-- Script history
local execHistory={};local histIdx=0
local function pushHistory(code)
    if code=="" then return end
    if execHistory[#execHistory]~=code then
        table.insert(execHistory,code)
        if #execHistory>30 then table.remove(execHistory,1) end
    end
    histIdx=#execHistory
end

-- Editor
local Editor=IN(P1,"-- Mode 1: Client loadstring\n-- Mode 2: Server-side via bridge\n-- Mode 3: require(assetID)\n-- Mode 4: loadstring(HttpGet(url))()\n-- Mode 5: readfile(\"path.lua\")\n",
    UDim2.new(1,0,0,186),UDim2.new(0,0,0,30))

-- Action row
local aRow=rowBar(P1,220,26)
local BExec  =B(aRow,"▶ Run",    UDim2.new(0,88,1,0),nil,C.ACC)
local BClear =B(aRow,"Clear",    UDim2.new(0,68,1,0),nil,C.GREY)
local BCopy  =B(aRow,"Copy",     UDim2.new(0,68,1,0),nil,C.GREY)
local BPrev  =B(aRow,"◀ Hist",  UDim2.new(0,72,1,0),nil,C.GREY)
local BNext  =B(aRow,"Hist ▶",  UDim2.new(0,72,1,0),nil,C.GREY)
local BFmtLbl=L(aRow,"",UDim2.new(0,60,1,0),nil,C.TXTS,FN,10)
BFmtLbl.LayoutOrder=6
for _,b in {BExec,BClear,BCopy,BPrev,BNext} do b.TextSize=11 end
BExec.LayoutOrder=1;BClear.LayoutOrder=2;BCopy.LayoutOrder=3;BPrev.LayoutOrder=4;BNext.LayoutOrder=5
hov(BExec,C.ACC,C.ACCHV);hov(BClear,C.GREY,C.GRYHV);hov(BCopy,C.GREY,C.GRYHV)
hov(BPrev,C.GREY,C.GRYHV);hov(BNext,C.GREY,C.GRYHV)

-- Output
L(P1,"Output",UDim2.new(0,55,0,14),UDim2.new(0,0,0,252),C.TXTS,FN,11)
local LineCnt=L(P1,"",UDim2.new(0,120,0,14),UDim2.new(1,-120,0,252),C.TXTD,FN,10,Enum.TextXAlignment.Right)
local ExOut=OUT(P1,UDim2.new(1,0,1,-270),UDim2.new(0,0,0,268))

Editor:GetPropertyChangedSignal("Text"):Connect(function()
    local n=0; for _ in Editor.Text:gmatch("\n") do n+=1 end
    LineCnt.Text=(n+1).." lines"
end)

local function exOut(msg,isErr)
    local ts=("[%s] "):format(os.date("%H:%M:%S"))
    ExOut.TextColor3=isErr and C.RED or C.GRN
    ExOut.Text=ts..tostring(msg)
end

BExec.MouseButton1Click:Connect(function()
    local code=Editor.Text; if code=="" then exOut("Nothing to run.",true);return end
    pushHistory(code)
    tw(BExec,{BackgroundColor3=C.ACCHV});task.wait(0.06);tw(BExec,{BackgroundColor3=C.ACC})
    if curMode==1 then
        local fn,ce=_ld(code)
        if not fn then exOut("Compile:\n"..tostring(ce),true);return end
        local ok2,re=pcall(fn); exOut(ok2 and "Client exec OK." or "Error:\n"..tostring(re),not ok2)
    elseif curMode==2 then
        local ok2,msg2=callBridge("ls",{code=code}); exOut(msg2 or "(no response)",not ok2)
    elseif curMode==3 then
        local id=tonumber(code:match("%d+"))
        if not id then exOut("Enter a numeric asset ID.",true);return end
        local ok2,res=pcall(require,id)
        exOut(ok2 and ("require("..id..") OK.") or "Error:\n"..tostring(res),not ok2)
    elseif curMode==4 then
        local url=code:match("^%s*(.-)%s*$")
        if url=="" then exOut("Enter a URL.",true);return end
        local ok2,src=pcall(game.HttpGet,game,url,true)
        if not ok2 then exOut("HTTP:\n"..tostring(src),true);return end
        local fn,ce=_ld(src)
        if not fn then exOut("Compile:\n"..tostring(ce),true);return end
        local ok3,re=pcall(fn); exOut(ok3 and "URL exec OK." or "Error:\n"..tostring(re),not ok3)
    elseif curMode==5 then
        if not readfile then exOut("readfile not available.",true);return end
        local path=code:match("^%s*(.-)%s*$")
        local ok2,src=pcall(readfile,path)
        if not ok2 then exOut("readfile:\n"..tostring(src),true);return end
        local fn,ce=_ld(src)
        if not fn then exOut("Compile:\n"..tostring(ce),true);return end
        local ok3,re=pcall(fn); exOut(ok3 and "File exec OK." or "Error:\n"..tostring(re),not ok3)
    end
end)
BClear.MouseButton1Click:Connect(function() Editor.Text=""; ExOut.Text="" end)
BCopy.MouseButton1Click:Connect(function()
    if setclipboard then setclipboard(Editor.Text); exOut("Copied to clipboard.",false)
    else exOut("setclipboard not available.",true) end
end)
BPrev.MouseButton1Click:Connect(function()
    if #execHistory==0 then exOut("No history.",true);return end
    histIdx=math.max(1,histIdx-1); Editor.Text=execHistory[histIdx]
    exOut("History "..histIdx.."/"..#execHistory,false)
end)
BNext.MouseButton1Click:Connect(function()
    if #execHistory==0 then exOut("No history.",true);return end
    histIdx=math.min(#execHistory,histIdx+1); Editor.Text=execHistory[histIdx]
    exOut("History "..histIdx.."/"..#execHistory,false)
end)
setMode(1)

-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB 2 — SERVER
-- ═══════════════════════════════════════════════════════════════════════════════
local P2=newTab("⚙","Server")

L(P2,"SERVER CONTROL",UDim2.new(1,0,0,16),UDim2.new(0,0,0,0),C.TXTS,FB,11)
local SrvEdit=IN(P2,"-- Code to run server-side via bridge...",UDim2.new(1,0,0,80),UDim2.new(0,0,0,20))
local sr1=rowBar(P2,106,26)
local BSrvRun=B(sr1,"▶ Run Server",UDim2.new(0,120,1,0),nil,C.GRN)
local BSrvURL=B(sr1,"Run URL",    UDim2.new(0,92,1,0),nil,C.GREY)
local BSrvReq=B(sr1,"Require ID", UDim2.new(0,96,1,0),nil,C.GREY)
local BSrvPing=B(sr1,"Ping",      UDim2.new(0,64,1,0),nil,C.ACC)
BSrvRun.LayoutOrder=1;BSrvURL.LayoutOrder=2;BSrvReq.LayoutOrder=3;BSrvPing.LayoutOrder=4
for _,b in {BSrvRun,BSrvURL,BSrvReq,BSrvPing} do b.TextSize=11 end
hov(BSrvRun,C.GRN,C.GRNHV);hov(BSrvURL,C.GREY,C.GRYHV);hov(BSrvReq,C.GREY,C.GRYHV);hov(BSrvPing,C.ACC,C.ACCHV)

local SrvOut=OUT(P2,UDim2.new(1,0,0,56),UDim2.new(0,0,0,136))
local function srvOut(msg,ok2) SrvOut.TextColor3=ok2 and C.GRN or C.RED;SrvOut.Text=tostring(msg) end
local function bOut(act,pay)
    local ok2,msg2,data=callBridge(act,pay)
    local lines={msg2 or ""}
    if data then for _,l in data do lines[#lines+1]=tostring(l) end end
    srvOut(table.concat(lines,"\n"),ok2)
end

BSrvRun.MouseButton1Click:Connect(function()
    if SrvEdit.Text=="" then srvOut("No code.",false);return end; bOut("ls",{code=SrvEdit.Text})
end)
BSrvURL.MouseButton1Click:Connect(function()
    local url=SrvEdit.Text:match("^%s*(.-)%s*$")
    if url=="" then srvOut("Enter URL in editor.",false);return end; bOut("ls_url",{url=url})
end)
BSrvReq.MouseButton1Click:Connect(function()
    local id=tonumber(SrvEdit.Text:match("%d+"))
    if not id then srvOut("Enter asset ID in editor.",false);return end; bOut("req",{id=id})
end)
BSrvPing.MouseButton1Click:Connect(function()
    local ok2=pingBridge(); srvOut(ok2 and "Bridge ✓ pong" or "Bridge offline.",ok2)
end)

-- Players panel
L(P2,"Players",UDim2.new(0,80,0,14),UDim2.new(0,0,0,198),C.TXTS,FB,11)
local BRefPlrs=B(P2,"Refresh",UDim2.new(0,80,0,18),UDim2.new(1,-82,0,198),C.GREY);hov(BRefPlrs,C.GREY,C.GRYHV);BRefPlrs.TextSize=11
local PlrScr=SCR(P2,UDim2.new(1,0,1,-218),UDim2.new(0,0,0,216));listV(PlrScr,3)
local selPlr=nil

local function refreshPlrs()
    for _,ch in PlrScr:GetChildren() do if not ch:IsA("UIListLayout") then ch:Destroy() end end
    selPlr=nil
    for _,plr in Players:GetPlayers() do
        local row=F(PlrScr,UDim2.new(1,-4,0,32),nil,C.PANEL);corner(row,6)
        local isMe=(plr==LP)
        local dot=F(row,UDim2.new(0,7,0,7),UDim2.new(0,6,0.5,-3),plr.Character and C.GRN or C.GREY);corner(dot,4)
        L(row,plr.DisplayName,UDim2.new(0.55,-20,1,0),UDim2.new(0,20,0,0),C.TXT,isMe and FB or FN,12)
        L(row,"@"..plr.Name,UDim2.new(0.3,0,1,0),UDim2.new(0.35,0,0,0),C.TXTS,FN,10)
        local bKick=B(row,"Kick",UDim2.new(0,42,0,20),UDim2.new(1,-88,0.5,-10),isMe and C.GREY or C.RED);bKick.TextSize=10
        local bTp  =B(row,"TP",  UDim2.new(0,36,0,20),UDim2.new(1,-44,0.5,-10),C.BLUE);bTp.TextSize=10
        if isMe then bKick.Text="You" end
        hov(bTp,C.BLUE,C.BLHV)
        bKick.MouseButton1Click:Connect(function()
            if isMe then srvOut("Can't kick yourself.",false);return end
            bOut("kick",{name=plr.Name})
        end)
        bTp.MouseButton1Click:Connect(function()
            local myChar=LP.Character; local tChar=plr.Character
            if not myChar or not tChar then srvOut("No character.",false);return end
            local root=myChar:FindFirstChild("HumanoidRootPart")
            local tRoot=tChar:FindFirstChild("HumanoidRootPart")
            if root and tRoot then root.CFrame=tRoot.CFrame+Vector3.new(2,2,2) end
        end)
    end
end
BRefPlrs.MouseButton1Click:Connect(refreshPlrs)
refreshPlrs()

-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB 3 — SANDBOX BYPASS
-- ═══════════════════════════════════════════════════════════════════════════════
local P3=newTab("⛓","Sandbox")
L(P3,"SANDBOX & BYPASS",UDim2.new(1,0,0,16),UDim2.new(0,0,0,0),C.TXTS,FB,11)
local SBOut=OUT(P3,UDim2.new(1,0,0,46),UDim2.new(0,0,1,-48))
local function sbOut(msg,ok2) SBOut.TextColor3=ok2 and C.GRN or C.RED;SBOut.Text=tostring(msg) end
local SBScr=SCR(P3,UDim2.new(1,0,1,-100),UDim2.new(0,0,0,20));listV(SBScr,4)

local function utilRow(title,desc,btnTxt,btnCol,action)
    local Row=F(SBScr,UDim2.new(1,-4,0,50),nil,C.PANEL);corner(Row,7);stroke(Row,Color3.fromRGB(30,40,70),1)
    L(Row,title,UDim2.new(1,-108,0,18),UDim2.new(0,8,0,5),C.TXT,FB,12)
    L(Row,desc,UDim2.new(1,-108,0,16),UDim2.new(0,8,0,26),C.TXTS,FN,10)
    local bc=btnCol or C.ACC
    local btn=B(Row,btnTxt,UDim2.new(0,90,0,26),UDim2.new(1,-98,0.5,-13),bc);btn.TextSize=11
    local hc=Color3.fromRGB(math.min(255,bc.R*255+30),math.min(255,bc.G*255+30),math.min(255,bc.B*255+30))
    hov(btn,bc,hc)
    btn.MouseButton1Click:Connect(function()
        local ok2,res=pcall(action); sbOut(res or (ok2 and "✓ Done." or "✗ Failed."),ok2)
    end)
    return btn
end

utilRow("Elevate Identity (8)","setthreadidentity(8) — max script context","Elevate",C.ACC,function()
    local fn=setthreadidentity or (syn and syn.set_thread_identity)
    if not fn then return "✗ setthreadidentity not available." end
    fn(8);local gid=getthreadidentity or (syn and syn.get_thread_identity)
    return "✓ Identity → 8"..(gid and " (confirmed: "..tostring(gid())..")" or "")
end)
utilRow("Unlock game metatable","setreadonly(getrawmetatable(game),false)","Unlock",C.BLUE,function()
    if not getrawmetatable then return "✗ getrawmetatable missing." end
    if not setreadonly then return "✗ setreadonly missing." end
    setreadonly(getrawmetatable(game),false);return "✓ game metatable is now writable."
end)
utilRow("Hook __namecall (log)","Logs FireServer/InvokeServer to output/console","Hook",C.ORAN,function()
    if not hookmetamethod then return "✗ hookmetamethod not available." end
    if not getnamecallmethod then return "✗ getnamecallmethod not available." end
    local old2;old2=hookmetamethod(game,"__namecall",function(self,...)
        local m=getnamecallmethod()
        if m=="FireServer" or m=="InvokeServer" then warn("[Spy] "..tostring(self).."→"..m) end
        return old2(self,...)
    end);return "✓ __namecall hooked. Remotes → console."
end)
utilRow("getgenv() explorer","Count & inspect shared executor globals","Open",C.GRN,function()
    if not getgenv then return "✗ getgenv not available." end
    local env=getgenv();local n=0;for _ in pairs(env) do n+=1 end
    return "✓ getgenv() → "..n.." entries."
end)
utilRow("getrenv() explorer","Access real Roblox game environment table","Open",C.PURP,function()
    if not getrenv then return "✗ getrenv not available." end
    local env=getrenv();local n=0;for _ in pairs(env) do n+=1 end
    return "✓ getrenv() → "..n.." entries."
end)
utilRow("Bypass metatable lock","Strip __index/__newindex guards on game","Bypass",C.RED,function()
    if not getrawmetatable or not setreadonly then return "✗ Missing functions." end
    setreadonly(getrawmetatable(game),false);return "✓ Metatable lock stripped."
end)
utilRow("setreadonly(table, false)","Make any table writable via _G edit","Expose",C.YELL,function()
    if not setreadonly then return "✗ setreadonly not available." end
    setreadonly(_G,false);return "✓ _G is now writable (setreadonly=false)."
end)
utilRow("getconnections() probe","Count connections on major game events","Probe",C.TEAL,function()
    if not getconnections then return "✗ getconnections not available." end
    local ev=game:GetService("Players").PlayerAdded
    local conns=getconnections(ev);return "✓ PlayerAdded has "..#conns.." connections."
end)

-- Custom snippet area (at bottom, outside scroll)
local snipHdr=L(P3,"Custom Snippet:",UDim2.new(0,120,0,14),UDim2.new(0,0,1,-94),C.TXTS,FN,11)
local SnipBox=IN(P3,"-- Enter custom snippet here...",UDim2.new(1,0,0,44),UDim2.new(0,0,1,-80))
local BSnip=B(P3,"▶ Run Snippet",UDim2.new(0,130,0,24),UDim2.new(0,0,1,-30),C.ACC);BSnip.TextSize=11;hov(BSnip,C.ACC,C.ACCHV)
BSnip.MouseButton1Click:Connect(function()
    local code=SnipBox.Text;if code=="" then sbOut("No snippet.",false);return end
    local fn,ce=_ld(code)
    if not fn then sbOut("Compile:\n"..tostring(ce),false);return end
    local ok2,re=pcall(fn);sbOut(ok2 and "✓ OK." or "✗ "..tostring(re),ok2)
end)

task.spawn(function()
    local caps={"setthreadidentity","setreadonly","getrawmetatable","hookmetamethod",
                 "getgenv","getrenv","getnamecallmethod","getconnections","hookfunction"}
    local have,miss={},{}
    for _,n in caps do ((_G[n] or getfenv and getfenv()[n]) and have or miss)[#(have)+1]=n end
    sbOut(("%d/%d bypass fns available.\nHave: %s"):format(#have,#caps,table.concat(have,", ")),#miss==0)
end)

-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB 4 — PLAYER
-- ═══════════════════════════════════════════════════════════════════════════════
local P4=newTab("👤","Player")
L(P4,"PLAYER TOOLS",UDim2.new(1,0,0,16),UDim2.new(0,0,0,0),C.TXTS,FB,11)
local PlrOut=OUT(P4,UDim2.new(1,0,0,40),UDim2.new(0,0,1,-42))
local function plrOut(msg,ok2) PlrOut.TextColor3=ok2 and C.GRN or C.RED;PlrOut.Text=tostring(msg) end

-- Speed / Jump / God sliders via input boxes
local statsFrame=F(P4,UDim2.new(1,0,0,60),UDim2.new(0,0,0,20),C.PANEL);corner(statsFrame,7)

L(statsFrame,"WalkSpeed",UDim2.new(0,80,0,16),UDim2.new(0,8,0,4),C.TXTS,FN,11)
local WalkIn=IN(statsFrame,"16",UDim2.new(0,72,0,22),UDim2.new(0,88,0,2),false)
WalkIn.TextYAlignment=Enum.TextYAlignment.Center

L(statsFrame,"JumpPower",UDim2.new(0,80,0,16),UDim2.new(0,172,0,4),C.TXTS,FN,11)
local JumpIn=IN(statsFrame,"50",UDim2.new(0,72,0,22),UDim2.new(0,252,0,2),false)
JumpIn.TextYAlignment=Enum.TextYAlignment.Center

L(statsFrame,"Health",UDim2.new(0,60,0,16),UDim2.new(0,336,0,4),C.TXTS,FN,11)
local HpIn=IN(statsFrame,"100",UDim2.new(0,60,0,22),UDim2.new(0,390,0,2),false)
HpIn.TextYAlignment=Enum.TextYAlignment.Center

local BApplyStats=B(statsFrame,"Apply",UDim2.new(0,56,0,22),UDim2.new(1,-60,0.5,-11),C.GRN);BApplyStats.TextSize=11;hov(BApplyStats,C.GRN,C.GRNHV)
BApplyStats.MouseButton1Click:Connect(function()
    local char=LP.Character;if not char then plrOut("No character.",false);return end
    local hum=char:FindFirstChildOfClass("Humanoid")
    if not hum then plrOut("No Humanoid.",false);return end
    local ws=tonumber(WalkIn.Text);if ws then hum.WalkSpeed=ws end
    local jp=tonumber(JumpIn.Text);if jp then hum.JumpPower=jp end
    local hp=tonumber(HpIn.Text);if hp then hum.Health=hp end
    plrOut(("WalkSpeed=%.0f  JumpPower=%.0f  Health=%.0f"):format(hum.WalkSpeed,hum.JumpPower,hum.Health),true)
end)

-- Quick action row
local pRow1=rowBar(P4,86,26)
local BRespawn=B(pRow1,"Respawn",   UDim2.new(0,90,1,0),nil,C.BLUE);BRespawn.TextSize=11
local BGodMode=B(pRow1,"GodMode",   UDim2.new(0,86,1,0),nil,C.GREY);BGodMode.TextSize=11
local BInfJump=B(pRow1,"∞ Jump",   UDim2.new(0,76,1,0),nil,C.GREY);BInfJump.TextSize=11
local BNoclip =B(pRow1,"Noclip",    UDim2.new(0,76,1,0),nil,C.GREY);BNoclip.TextSize=11
local BFreeze =B(pRow1,"Freeze",    UDim2.new(0,76,1,0),nil,C.GREY);BFreeze.TextSize=11
for _,b in {BRespawn,BGodMode,BInfJump,BNoclip,BFreeze} do b.LayoutOrder=_ end
hov(BRespawn,C.BLUE,C.BLHV)
hov(BGodMode,C.GREY,C.GRYHV);hov(BInfJump,C.GREY,C.GRYHV)
hov(BNoclip,C.GREY,C.GRYHV);hov(BFreeze,C.GREY,C.GRYHV)

local godActive=false;local infJumpActive=false;local noclipActive=false;local freezeActive=false
local godConn,infConn,ncConn

BRespawn.MouseButton1Click:Connect(function()
    local char=LP.Character;if not char then plrOut("No character.",false);return end
    local hum=char:FindFirstChildOfClass("Humanoid")
    if hum then hum.Health=0;plrOut("Respawned.",true) end
end)
BGodMode.MouseButton1Click:Connect(function()
    godActive=not godActive
    tw(BGodMode,{BackgroundColor3=godActive and C.GRN or C.GREY})
    if godConn then godConn:Disconnect();godConn=nil end
    if godActive then
        godConn=RUN.Heartbeat:Connect(function()
            local char=LP.Character;if not char then return end
            local hum=char:FindFirstChildOfClass("Humanoid")
            if hum then hum.Health=hum.MaxHealth end
        end)
    end
    plrOut("God Mode "..(godActive and "ON" or "OFF"),godActive)
end)
BInfJump.MouseButton1Click:Connect(function()
    infJumpActive=not infJumpActive
    tw(BInfJump,{BackgroundColor3=infJumpActive and C.GRN or C.GREY})
    if infConn then infConn:Disconnect();infConn=nil end
    if infJumpActive then
        infConn=UIS.JumpRequest:Connect(function()
            local char=LP.Character;if not char then return end
            local hum=char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end
    plrOut("Infinite Jump "..(infJumpActive and "ON" or "OFF"),infJumpActive)
end)
BNoclip.MouseButton1Click:Connect(function()
    noclipActive=not noclipActive
    tw(BNoclip,{BackgroundColor3=noclipActive and C.GRN or C.GREY})
    if ncConn then ncConn:Disconnect();ncConn=nil end
    if noclipActive then
        ncConn=RUN.Stepped:Connect(function()
            local char=LP.Character;if not char then return end
            for _,p in char:GetDescendants() do
                if p:IsA("BasePart") then p.CanCollide=false end
            end
        end)
    end
    plrOut("Noclip "..(noclipActive and "ON" or "OFF"),noclipActive)
end)
BFreeze.MouseButton1Click:Connect(function()
    freezeActive=not freezeActive
    tw(BFreeze,{BackgroundColor3=freezeActive and C.GRN or C.GREY})
    local char=LP.Character;if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart")
    if root then root.Anchored=freezeActive end
    plrOut("Freeze "..(freezeActive and "ON" or "OFF"),freezeActive)
end)

-- Teleport row
L(P4,"Teleport (X, Y, Z):",UDim2.new(0,150,0,14),UDim2.new(0,0,0,118),C.TXTS,FN,11)
local txIn=IN(P4,"X",UDim2.new(0,94,0,24),UDim2.new(0,0,0,134),false)
local tyIn=IN(P4,"Y",UDim2.new(0,94,0,24),UDim2.new(0,98,0,134),false)
local tzIn=IN(P4,"Z",UDim2.new(0,94,0,24),UDim2.new(0,196,0,134),false)
local BTp=B(P4,"Teleport",UDim2.new(0,100,0,24),UDim2.new(0,294,0,134),C.BLUE);BTp.TextSize=11;hov(BTp,C.BLUE,C.BLHV)
txIn.TextYAlignment=Enum.TextYAlignment.Center
tyIn.TextYAlignment=Enum.TextYAlignment.Center
tzIn.TextYAlignment=Enum.TextYAlignment.Center
BTp.MouseButton1Click:Connect(function()
    local x,y,z=tonumber(txIn.Text),tonumber(tyIn.Text),tonumber(tzIn.Text)
    if not (x and y and z) then plrOut("Enter valid X Y Z coords.",false);return end
    local char=LP.Character;if not char then plrOut("No character.",false);return end
    local root=char:FindFirstChild("HumanoidRootPart")
    if root then root.CFrame=CFrame.new(x,y,z);plrOut(("Teleported → %.1f, %.1f, %.1f"):format(x,y,z),true) end
end)

-- Current pos
local BPos=B(P4,"Get Position",UDim2.new(0,120,0,24),UDim2.new(0,0,0,164),C.GREY);BPos.TextSize=11;hov(BPos,C.GREY,C.GRYHV)
BPos.MouseButton1Click:Connect(function()
    local char=LP.Character;if not char then plrOut("No character.",false);return end
    local root=char:FindFirstChild("HumanoidRootPart")
    if root then
        local p=root.Position
        txIn.Text=("%.1f"):format(p.X);tyIn.Text=("%.1f"):format(p.Y);tzIn.Text=("%.1f"):format(p.Z)
        plrOut(("Pos: %.1f, %.1f, %.1f"):format(p.X,p.Y,p.Z),true)
    end
end)

-- Speed presets
local spRow=rowBar(P4,194,24)
for i,preset in {{"Walk",16},{"Sprint",40},{"Fly",80},{"Hyper",200}} do
    local b=B(spRow,preset[1].."\n"..preset[2],UDim2.new(0,80,1,0),nil,C.GREY)
    b.LayoutOrder=i;b.TextSize=10;b.TextWrapped=true;hov(b,C.GREY,C.GRYHV)
    b.MouseButton1Click:Connect(function()
        WalkIn.Text=tostring(preset[2])
        local char=LP.Character;if not char then return end
        local hum=char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed=preset[2];plrOut("Speed → "..preset[2],true) end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB 5 — REMOTE SPY
-- ═══════════════════════════════════════════════════════════════════════════════
local P5=newTab("📡","RemoteSpy")
L(P5,"REMOTE SPY",UDim2.new(1,0,0,16),UDim2.new(0,0,0,0),C.TXTS,FB,11)

local spyActive=false; local spyHook=nil; local spyLog={}; local spyFilter=""
local spyStatusLbl=L(P5,"Status: Inactive",UDim2.new(0.5,0,0,16),UDim2.new(0,0,0,18),C.RED,FN,11)
local spyCountLbl=L(P5,"Captured: 0",UDim2.new(0.5,0,0,16),UDim2.new(0.5,0,0,18),C.TXTS,FN,11,Enum.TextXAlignment.Right)

local rRow=rowBar(P5,36,26)
local BSpyStart=B(rRow,"▶ Start",UDim2.new(0,90,1,0),nil,C.GRN);BSpyStart.TextSize=11
local BSpyStop =B(rRow,"■ Stop", UDim2.new(0,82,1,0),nil,C.GREY);BSpyStop.TextSize=11
local BSpyClear=B(rRow,"Clear",  UDim2.new(0,72,1,0),nil,C.GREY);BSpyClear.TextSize=11
local BSpyExp  =B(rRow,"Export", UDim2.new(0,80,1,0),nil,C.BLUE);BSpyExp.TextSize=11
BSpyStart.LayoutOrder=1;BSpyStop.LayoutOrder=2;BSpyClear.LayoutOrder=3;BSpyExp.LayoutOrder=4
hov(BSpyStart,C.GRN,C.GRNHV);hov(BSpyStop,C.GREY,C.GRYHV);hov(BSpyClear,C.GREY,C.GRYHV);hov(BSpyExp,C.BLUE,C.BLHV)

L(P5,"Filter remote name:",UDim2.new(0,140,0,14),UDim2.new(0,0,0,68),C.TXTS,FN,11)
local SpyFiltIn=IN(P5,"(leave blank for all)",UDim2.new(0.6,0,0,24),UDim2.new(0,148,0,64),false)
SpyFiltIn.TextYAlignment=Enum.TextYAlignment.Center
SpyFiltIn:GetPropertyChangedSignal("Text"):Connect(function() spyFilter=SpyFiltIn.Text:lower() end)

local SpyScr=SCR(P5,UDim2.new(1,0,1,-94),UDim2.new(0,0,0,94));listV(SpyScr,2)

local function addSpyRow(entry)
    local match=spyFilter=="" or entry.remote:lower():find(spyFilter,1,true)
    if not match then return end
    local Row=F(SpyScr,UDim2.new(1,-4,0,36),nil,C.PANEL);corner(Row,5);stroke(Row,Color3.fromRGB(30,40,68),1)
    local methodCol={FireServer=C.ORAN,InvokeServer=C.PURP,FireAllClients=C.RED,InvokeClient=C.PINK}
    local mc=methodCol[entry.method] or C.TXTS
    local badge2=F(Row,UDim2.new(0,82,0,18),UDim2.new(0,4,0.5,-9),mc);corner(badge2,4)
    L(badge2,entry.method,UDim2.new(1,0,1,0),nil,C.WHT,FB,9,Enum.TextXAlignment.Center)
    L(Row,entry.remote,UDim2.new(1,-170,0,18),UDim2.new(0,92,0,2),C.TXT,FN,12)
    L(Row,os.date("%H:%M:%S",entry.ts),UDim2.new(0,70,0,14),UDim2.new(1,-74,0,2),C.TXTD,FN,10,Enum.TextXAlignment.Right)
    local argsStr=tostring(entry.args[1] or ""):sub(1,60)
    L(Row,"Args: "..argsStr,UDim2.new(1,-100,0,14),UDim2.new(0,92,0,20),C.TXTS,FC,10)
    local BCopyRow=B(Row,"Copy",UDim2.new(0,38,0,18),UDim2.new(1,-44,0.5,-9),C.GREY);BCopyRow.TextSize=9;hov(BCopyRow,C.GREY,C.GRYHV)
    BCopyRow.MouseButton1Click:Connect(function()
        if setclipboard then setclipboard(entry.remote..":"..entry.method) end
    end)
    spyCountLbl.Text="Captured: "..#spyLog
end

local function startSpy()
    if not hookmetamethod then spyStatusLbl.Text="✗ hookmetamethod missing";spyStatusLbl.TextColor3=C.RED;return end
    if not getnamecallmethod then spyStatusLbl.Text="✗ getnamecallmethod missing";spyStatusLbl.TextColor3=C.RED;return end
    spyActive=true
    spyStatusLbl.Text="● Active";spyStatusLbl.TextColor3=C.GRN
    tw(BSpyStart,{BackgroundColor3=C.GREY});tw(BSpyStop,{BackgroundColor3=C.RED})
    local _old;_old=hookmetamethod(game,"__namecall",function(self,...)
        local method=getnamecallmethod()
        local track=spyActive and (method=="FireServer" or method=="InvokeServer"
            or method=="FireAllClients" or method=="FireClient" or method=="InvokeClient")
        if track then
            local args={...}; local remoteName=tostring(self):match("^(.+) %(") or tostring(self)
            local entry={remote=remoteName,method=method,args=args,ts=os.time()}
            table.insert(spyLog,1,entry)
            if #spyLog>200 then table.remove(spyLog) end
            task.spawn(addSpyRow,entry)
        end
        return _old(self,...)
    end)
    spyHook=true
end

BSpyStart.MouseButton1Click:Connect(function()
    if not spyHook then startSpy() else spyActive=true;spyStatusLbl.Text="● Active";spyStatusLbl.TextColor3=C.GRN end
end)
BSpyStop.MouseButton1Click:Connect(function()
    spyActive=false;spyStatusLbl.Text="◉ Paused";spyStatusLbl.TextColor3=C.YELL
    tw(BSpyStop,{BackgroundColor3=C.GREY})
end)
BSpyClear.MouseButton1Click:Connect(function()
    for _,ch in SpyScr:GetChildren() do if not ch:IsA("UIListLayout") then ch:Destroy() end end
    spyLog={};spyCountLbl.Text="Captured: 0"
end)
BSpyExp.MouseButton1Click:Connect(function()
    if not writefile then spyStatusLbl.Text="writefile not available";return end
    local lines={}; for _,e in spyLog do
        lines[#lines+1]=os.date("%H:%M:%S",e.ts).." | "..e.method.." | "..e.remote
    end
    writefile("nexus_remotespy.txt",table.concat(lines,"\n"))
    spyStatusLbl.Text="Exported → nexus_remotespy.txt";spyStatusLbl.TextColor3=C.GRN
end)

-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB 6 — SCANNER (Malware + Scripts)
-- ═══════════════════════════════════════════════════════════════════════════════
local P6=newTab("🔎","Scanner")
L(P6,"MALWARE SCANNER",UDim2.new(1,0,0,16),UDim2.new(0,0,0,0),C.TXTS,FB,11)
local scRow=rowBar(P6,18,26)
local BScanRun=B(scRow,"Scan Game",UDim2.new(0,104,1,0),nil,C.ACC);BScanRun.TextSize=11
local BScanKill=B(scRow,"Kill All LS",UDim2.new(0,96,1,0),nil,C.RED);BScanKill.TextSize=11
local BScanList=B(scRow,"List Scripts",UDim2.new(0,106,1,0),nil,C.BLUE);BScanList.TextSize=11
local BScanBrdg=B(scRow,"Bridge Scan",UDim2.new(0,106,1,0),nil,C.GREY);BScanBrdg.TextSize=11
BScanRun.LayoutOrder=1;BScanKill.LayoutOrder=2;BScanList.LayoutOrder=3;BScanBrdg.LayoutOrder=4
hov(BScanRun,C.ACC,C.ACCHV);hov(BScanKill,C.RED,C.REDHV);hov(BScanList,C.BLUE,C.BLHV);hov(BScanBrdg,C.GREY,C.GRYHV)

local ScanOut=OUT(P6,UDim2.new(1,0,1,-52),UDim2.new(0,0,0,50))
local function scanOut(msg,ok2) ScanOut.TextColor3=ok2 and C.GRN or C.RED;ScanOut.Text=tostring(msg) end

local MALWARE_SIGS={
    {pat="getfenv%(0%)",lbl="getfenv(0) — env tampering"},
    {pat="HttpGet.*pastebin",lbl="Pastebin fetch"},
    {pat="HttpGet.*discord",lbl="Discord webhook abuse"},
    {pat="game%.Players.*:Remove%(",lbl="Forced player removal"},
    {pat="while true do",lbl="Infinite loop script"},
    {pat="syn%.request",lbl="syn.request HTTP call"},
    {pat="request%(%s*{",lbl="HTTP request object"},
    {pat="getfenv.*setfenv",lbl="Environment hijack"},
    {pat="hookfunction",lbl="hookfunction detected"},
    {pat="setreadonly.*false",lbl="Metatable unlock"},
}

local function scanScript(scr)
    local src=""
    local ok2=pcall(function() if getscriptsource then src=getscriptsource(scr) end end)
    if not ok2 or src=="" then return {} end
    local found={}
    for _,sig in MALWARE_SIGS do
        if src:find(sig.pat) then found[#found+1]=sig.lbl end
    end
    return found
end

BScanRun.MouseButton1Click:Connect(function()
    scanOut("Scanning…",true)
    task.spawn(function()
        local results={}; local total=0; local flagged=0
        local function recurse(obj)
            for _,ch in obj:GetChildren() do
                if ch:IsA("LocalScript") or ch:IsA("ModuleScript") or ch:IsA("Script") then
                    total+=1
                    local hits=scanScript(ch)
                    if #hits>0 then
                        flagged+=1
                        results[#results+1]="⚠ "..ch:GetFullName()
                        for _,h in hits do results[#results+1]="  → "..h end
                    end
                end
                recurse(ch)
            end
        end
        recurse(game)
        if #results==0 then
            scanOut(("Scanned %d scripts — no malware signatures found ✓"):format(total),true)
        else
            results[1]=("Scanned %d scripts, %d flagged:\n"):format(total,flagged)..results[1]
            scanOut(table.concat(results,"\n"),false)
        end
    end)
end)
BScanKill.MouseButton1Click:Connect(function()
    local ok2,msg2=callBridge("kill_all"); scanOut(msg2 or "Bridge error",ok2)
end)
BScanList.MouseButton1Click:Connect(function()
    local lines={}; local n=0
    local function recurse(obj)
        for _,ch in obj:GetChildren() do
            if ch:IsA("LocalScript") or ch:IsA("ModuleScript") or ch:IsA("Script") then
                n+=1; lines[#lines+1]=("[%s] %s"):format(ch.ClassName,ch:GetFullName())
            end
            recurse(ch)
        end
    end
    recurse(game)
    scanOut(n.." scripts:\n"..table.concat(lines,"\n"),true)
end)
BScanBrdg.MouseButton1Click:Connect(function()
    local ok2,msg2,data=callBridge("scan")
    local lines={msg2 or ""}
    if data then for _,l in data do lines[#lines+1]=tostring(l) end end
    scanOut(table.concat(lines,"\n"),ok2)
end)

-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB 7 — DEOBFUSCATOR
-- ═══════════════════════════════════════════════════════════════════════════════
local P7=newTab("👁","Deobfusc.")
L(P7,"DEOBFUSCATOR",UDim2.new(1,0,0,16),UDim2.new(0,0,0,0),C.TXTS,FB,11)
L(P7,"Input:",UDim2.new(0,45,0,12),UDim2.new(0,0,0,18),C.TXTS,FN,11)
local DIn=IN(P7,"-- Paste obfuscated Lua here…",UDim2.new(1,0,0,150),UDim2.new(0,0,0,32))
local dRow=rowBar(P7,186,26)
local BDDet  =B(dRow,"Detect Type",UDim2.new(0,112,1,0),nil,C.BLUE);BDDet.TextSize=11
local BDDeob =B(dRow,"Deobfuscate",UDim2.new(0,120,1,0),nil,C.ACC);BDDeob.TextSize=11
local BDB64  =B(dRow,"Base64Dec",  UDim2.new(0,100,1,0),nil,C.GREY);BDB64.TextSize=11
local BDHex  =B(dRow,"Hex Dec",    UDim2.new(0,80,1,0),nil,C.GREY);BDHex.TextSize=11
BDDet.LayoutOrder=1;BDDeob.LayoutOrder=2;BDB64.LayoutOrder=3;BDHex.LayoutOrder=4
hov(BDDet,C.BLUE,C.BLHV);hov(BDDeob,C.ACC,C.ACCHV);hov(BDB64,C.GREY,C.GRYHV);hov(BDHex,C.GREY,C.GRYHV)
L(P7,"Output:",UDim2.new(0,55,0,12),UDim2.new(0,0,0,218),C.TXTS,FN,11)
local DOut=OUT(P7,UDim2.new(1,0,1,-232),UDim2.new(0,0,0,232))

local function detectType(s)
    if s:lower():find("luraph")                        then return "Luraph VM obfuscation" end
    if s:lower():find("getfenv") and s:find("0x%x+")  then return "IronBrew 2" end
    if s:lower():find("prometheus")                    then return "Prometheus" end
    if s:lower():find("moonsec")                       then return "Moonsec" end
    if s:lower():find("bytecode") and s:find("\\x")   then return "Custom bytecode VM" end
    if s:find("\\x%x%x")                              then return "Hex-escape encoded" end
    if s:find("string%.char%(%d")                      then return "string.char encoded" end
    if s:find("[A-Za-z0-9+/]+=?=?$") and #s%4==0 and not s:find("\n.-\n.-\n") then return "Possible Base64 payload" end
    if s:find("_[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]")  then return "Hex-variable names" end
    if s:find("\\%d%d%d")                              then return "Decimal-escape encoded" end
    return "Unknown / plain Lua"
end
local function deobfuscate(s)
    -- hex escapes
    s=s:gsub("\\x(%x%x)",function(h) return string.char(tonumber(h,16)) end)
    -- decimal escapes
    s=s:gsub("\\(%d%d?%d?)",function(d)
        local n=tonumber(d); return (n and n<=255) and string.char(n) or "\\"..d
    end)
    -- string.char(...)
    s=s:gsub("string%.char%(([%d,%s]+)%)",function(args)
        local out={}; for n in args:gmatch("%d+") do local num=tonumber(n); if num then out[#out+1]=string.char(num) end end
        return '"'..table.concat(out)..'"'
    end)
    -- string concat
    for _=1,12 do s=s:gsub('"([^"]*)"%s*%.%.%s*"([^"]*)"','"%1%2"') end
    -- remove redundant do/end blocks
    s=s:gsub("do%s+local%s+([%w_]+)%s*=%s*([^\n]+)\n%s*end",function(v,e) return "local "..v.."="..e end)
    return s
end
local function b64decode(s)
    local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    s=s:gsub('[^'..b..'=]','')
    return (s:gsub('.',function(x)
        if x=='=' then return '' end
        local r,f='',b:find(x)-1
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r
    end):gsub('%d%d%d%d%d%d%d%d',function(x)
        local c=0; for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

BDDet.MouseButton1Click:Connect(function() DOut.TextColor3=C.YELL;DOut.Text="Detected: "..detectType(DIn.Text) end)
BDDeob.MouseButton1Click:Connect(function()
    if DIn.Text=="" then DOut.TextColor3=C.RED;DOut.Text="Nothing to deobfuscate.";return end
    local ok2,res=pcall(deobfuscate,DIn.Text)
    DOut.TextColor3=ok2 and C.GRN or C.RED;DOut.Text=ok2 and res or "Error: "..tostring(res)
end)
BDB64.MouseButton1Click:Connect(function()
    local ok2,res=pcall(b64decode,DIn.Text)
    DOut.TextColor3=ok2 and C.GRN or C.RED;DOut.Text=ok2 and res or "B64 decode failed: "..tostring(res)
end)
BDHex.MouseButton1Click:Connect(function()
    local out={}; for hex in DIn.Text:gmatch("%x%x") do out[#out+1]=string.char(tonumber(hex,16)) end
    if #out==0 then DOut.TextColor3=C.RED;DOut.Text="No hex bytes found."
    else DOut.TextColor3=C.GRN;DOut.Text=table.concat(out) end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB 8 — FUNCTION CHECKER
-- ═══════════════════════════════════════════════════════════════════════════════
local P8=newTab("✓","Checker")
local subRow2=F(P8,UDim2.new(1,0,0,24),UDim2.new(0,0,0,0),C.EDIT,"SubRow");corner(subRow2,6)
listH(subRow2,2);pad(subRow2,2,2)

-- Search
local ChkSearch=IN(P8,"Search functions…",UDim2.new(0.48,0,0,24),UDim2.new(0.52,0,0,0),false)
ChkSearch.TextYAlignment=Enum.TextYAlignment.Center

local ChkScr=SCR(P8,UDim2.new(1,0,1,-30),UDim2.new(0,0,0,28));listV(ChkScr,2)
local subBtns2={};local curSub=0; local buildList

local function switchSub(i)
    curSub=i
    for j,b in subBtns2 do
        tw(b,{BackgroundColor3=j==i and C.ACC or C.PANEL}); b.TextColor3=j==i and C.TXT or C.TXTS
    end
end
local function addSub(name,order)
    local b=B(subRow2,name,UDim2.new(0,146,1,0),nil,C.PANEL,C.TXTS)
    b.LayoutOrder=order;b.TextSize=11;hov(b,C.PANEL,Color3.fromRGB(26,26,38))
    b.MouseButton1Click:Connect(function() switchSub(order); buildList(order) end)
    subBtns2[order]=b
end
addSub("UNC (100)",1);addSub("SUNC (100)",2);addSub("Myriad (250)",3)

local UNC_LIST={"checkcaller","clonefunction","getcallingscript","getscriptclosure","getscriptfunction","iscclosure","islclosure","isnewcclosure","newcclosure","crypt.base64decode","crypt.base64encode","crypt.decrypt","crypt.encrypt","crypt.generatebytes","crypt.generatekey","crypt.hash","debug.getconstant","debug.getconstants","debug.getinfo","debug.getproto","debug.getprotos","debug.getstack","debug.getupvalue","debug.getupvalues","debug.setconstant","debug.setstack","debug.setupvalue","Drawing.new","cleardrawcache","getrenderproperty","isrenderobj","setrenderproperty","appendfile","delfile","isfile","isfolder","listfiles","loadfile","makefolder","readfile","writefile","isrbxactive","keypress","keyrelease","mouse1click","mouse1press","mouse1release","mouse2click","mouse2press","mouse2release","mousemoveabs","mousemoverel","mousescroll","fireclickdetector","firetouchinterest","gethiddenproperty","sethiddenproperty","getsimulationradius","setsimulationradius","getconnections","hookmetamethod","getrawmetatable","setrawmetatable","identifyexecutor","isexecutorclosure","queue_on_teleport","request","setfpscap","getfpscap","gethui","getnamecallmethod","setnamecallmethod","getloadedmodules","getrenv","getrunningscripts","getscripts","getsenv","firesignal","replicatesignal","getthreadidentity","setthreadidentity","http.request","httpget","syn.request","cache.invalidate","cache.iscached","cache.replace","cloneref","compareinstances","WebSocket.connect","rconsoleclose","rconsoleinfo","rconsoleinput","rconsolename","rconsoleprint","rconsoleclear","rconsoleopen","rconsolewarn","getgenv","setreadonly","hookfunction","replaceclosure"}
local SUNC_LIST={"getgenv","getrenv","getsenv","getfenv","setfenv","getscriptstate","setscriptstate","getthreadstate","setthreadstate","getscriptclosure","getscriptfunction","isscriptactive","killtask","getglobals","setglobal","getlocals","setlocal","getupvalues","setupvalue","getscriptbyname","getscriptbypath","getscriptbyid","findscript","getscriptparent","getscriptchildren","getscriptancestors","getscriptdescendants","getscriptid","getscripthash","getscriptbytecode","getscriptsource","patchscript","hookscript","replacescript","overwritescript","script.encrypt","script.decrypt","script.hash","script.sign","script.verify","sandbox.create","sandbox.destroy","sandbox.isolate","sandbox.expose","sandbox.getenv","sandbox.setenv","sandbox.run","sandbox.capture","sandbox.getresult","sandbox.getlog","sandbox.getoutput","sandbox.getstatus","scriptcontext.run","scriptcontext.stop","scriptcontext.pause","scriptcontext.resume","scriptcontext.getstatus","scriptcontext.getenv","scriptcontext.setenv","scriptcontext.capture","scriptcontext.getlog","scriptcontext.getoutput","scriptcontext.patchglobal","scriptcontext.hookfunction","scriptcontext.traceglobal","scriptcontext.sandbox","scriptcontext.unsandbox","scriptcontext.isolate","scriptcontext.expose","scriptcontext.getresult","scriptcontext.getid","scriptcontext.gethash","scriptcontext.getbytecode","scriptcontext.getsource","scriptcontext.sign","scriptcontext.verify","scriptcontext.encrypt","scriptcontext.decrypt","scriptcontext.replace","scriptcontext.overwrite","scriptcontext.patch","scriptcontext.hook","scriptcontext.kill","scriptcontext.find","scriptcontext.list","scriptcontext.count","scriptcontext.exists","scriptcontext.isactive","scriptcontext.isrunning","scriptcontext.issandboxed","scriptcontext.isisolated","scriptcontext.isexposed","scriptcontext.ishooked","scriptcontext.ispatched","scriptcontext.isreplaced","scriptcontext.isoverwritten","scriptcontext.isencrypted","scriptcontext.issigned","scriptcontext.isverified","scriptcontext.isdecrypted","scriptcontext.ishashed"}
local MYRIAD_LIST={"myr.drawing.new","myr.drawing.clear","myr.drawing.getall","myr.drawing.remove","myr.drawing.setproperty","myr.drawing.getproperty","myr.drawing.isobject","myr.drawing.oncreate","myr.drawing.onremove","myr.drawing.render","myr.drawing.hide","myr.drawing.show","myr.drawing.toggle","myr.drawing.setvisible","myr.drawing.getvisible","myr.drawing.setcolor","myr.drawing.getcolor","myr.drawing.setalpha","myr.drawing.getalpha","myr.drawing.setposition","myr.drawing.getposition","myr.drawing.setsize","myr.drawing.getsize","myr.mem.read","myr.mem.write","myr.mem.scan","myr.mem.alloc","myr.mem.free","myr.mem.protect","myr.mem.query","myr.mem.patch","myr.mem.compare","myr.mem.dump","myr.mem.restore","myr.mem.hook","myr.mem.unhook","myr.mem.getbase","myr.mem.getsize","myr.mem.gettype","myr.mem.getname","myr.mem.getpath","myr.mem.getclass","myr.mem.getparent","myr.mem.getchildren","myr.mem.getancestors","myr.mem.getdescendants","myr.net.request","myr.net.get","myr.net.post","myr.net.put","myr.net.delete","myr.net.patch","myr.net.head","myr.net.options","myr.net.trace","myr.net.connect","myr.net.listen","myr.net.close","myr.net.send","myr.net.receive","myr.net.getip","myr.net.getport","myr.net.gethost","myr.net.getpath","myr.net.getquery","myr.net.getfragment","myr.anti.detect","myr.anti.bypass","myr.anti.hook","myr.anti.unhook","myr.anti.patch","myr.anti.restore","myr.anti.scan","myr.anti.kill","myr.anti.block","myr.anti.allow","myr.anti.log","myr.anti.alert","myr.anti.monitor","myr.anti.trace","myr.anti.intercept","myr.anti.redirect","myr.anti.spoof","myr.anti.mask","myr.anti.hide","myr.anti.show","myr.spy.hook","myr.spy.unhook","myr.spy.intercept","myr.spy.monitor","myr.spy.trace","myr.spy.log","myr.spy.capture","myr.spy.replay","myr.spy.block","myr.spy.allow","myr.spy.redirect","myr.spy.spoof","myr.spy.getremotes","myr.spy.fireremote","myr.spy.invokefunc","myr.spy.hookremote","myr.spy.unhookremote","myr.spy.logremote","myr.spy.capturefunc","myr.spy.replayfunc","myr.byte.read","myr.byte.write","myr.byte.scan","myr.byte.patch","myr.byte.compare","myr.byte.dump","myr.byte.restore","myr.byte.encode","myr.byte.decode","myr.byte.encrypt","myr.byte.decrypt","myr.byte.hash","myr.byte.sign","myr.byte.verify","myr.byte.compress","myr.byte.decompress","myr.byte.pack","myr.byte.unpack","myr.byte.convert","myr.byte.format","myr.ui.create","myr.ui.destroy","myr.ui.get","myr.ui.set","myr.ui.find","myr.ui.list","myr.ui.show","myr.ui.hide","myr.ui.toggle","myr.ui.move","myr.ui.resize","myr.ui.recolor","myr.ui.retextsize","myr.ui.refont","myr.ui.retext","myr.ui.reimage","myr.ui.reparent","myr.ui.clone","myr.ui.tween","myr.ui.animate","myr.phys.setvelocity","myr.phys.getvelocity","myr.phys.setposition","myr.phys.getposition","myr.phys.setrotation","myr.phys.getrotation","myr.phys.setgravity","myr.phys.getgravity","myr.phys.setmass","myr.phys.getmass","myr.phys.setfriction","myr.phys.getfriction","myr.phys.setelasticity","myr.phys.getelasticity","myr.phys.setdensity","myr.phys.getdensity","myr.phys.noclip","myr.phys.clip","myr.phys.fly","myr.phys.land","myr.rep.fire","myr.rep.invoke","myr.rep.hook","myr.rep.unhook","myr.rep.block","myr.rep.allow","myr.rep.log","myr.rep.capture","myr.rep.replay","myr.rep.redirect","myr.rep.spoof","myr.rep.create","myr.rep.destroy","myr.rep.rename","myr.rep.clone","myr.rep.move","myr.rep.reparent","myr.rep.getall","myr.rep.find","myr.rep.monitor","myr.game.getservice","myr.game.findservice","myr.game.listservices","myr.game.getplayers","myr.game.findplayer","myr.game.kickplayer","myr.game.getcharacter","myr.game.respawn","myr.game.teleport","myr.game.getworkspace","myr.game.getlighting","myr.game.getreplicatedstorage","myr.game.getstartergui","myr.game.getstartpack","myr.game.getstartchar","myr.game.getserverstorage","myr.game.getscriptcontext","myr.game.getrunservice","myr.game.getuserinputservice","myr.game.getcontentprovider","myr.game.gethttpservice","myr.game.gettweenservice","myr.game.getmarketplaceservice","myr.debug.getinfo","myr.debug.getstack","myr.debug.traceback","myr.debug.profilebegin","myr.debug.profileend","myr.debug.getupvalue","myr.debug.setupvalue","myr.debug.getconstant","myr.debug.setconstant","myr.debug.getproto","myr.debug.getprotos","myr.debug.setproto","myr.debug.getlocal","myr.debug.setlocal","myr.debug.getmetatable","myr.debug.setmetatable","myr.debug.rawget","myr.debug.rawset","myr.debug.rawequal","myr.debug.rawlen","myr.event.fire","myr.event.connect","myr.event.disconnect","myr.event.wait","myr.event.once","myr.event.hook","myr.event.unhook","myr.event.block","myr.event.allow","myr.event.log","myr.event.capture","myr.event.replay","myr.event.redirect","myr.event.spoof","myr.event.monitor","myr.event.trace","myr.event.getconnections","myr.event.getlisteners","myr.event.getsignals","myr.event.getevents","myr.event.getfirers","myr.exec.run","myr.exec.load","myr.exec.require","myr.exec.dofile","myr.exec.dostring","myr.exec.loadfile","myr.exec.loadstring","myr.exec.loadbytecode","myr.exec.runfile","myr.exec.runstring","myr.exec.runbytecode","myr.exec.runurl","myr.exec.inject","myr.exec.eject","myr.exec.hook","myr.exec.unhook","myr.exec.patch","myr.exec.unpatch","myr.exec.sandbox","myr.exec.unsandbox","myr.lic.check","myr.lic.verify","myr.lic.activate","myr.lic.deactivate","myr.lic.getkey","myr.lic.setkey","myr.lic.getexpiry","myr.lic.isvalid","myr.lic.getuser","myr.lic.getplan","myr.lic.getfeatures","myr.lic.hasfeature","myr.lic.getlimit","myr.lic.getusage","myr.lic.increment","myr.lic.decrement","myr.lic.reset","myr.lic.getlog","myr.lic.audit","myr.lic.revoke","myr.inst.create","myr.inst.clone","myr.inst.destroy","myr.inst.get","myr.inst.set","myr.inst.find","myr.inst.list","myr.inst.filter","myr.inst.hook","myr.inst.unhook","myr.inst.wrap","myr.inst.unwrap","myr.inst.lock","myr.inst.unlock","myr.inst.hide","myr.inst.show","myr.inst.rename","myr.inst.retype","myr.inst.reparent","myr.inst.reclass","myr.inst.getprop","myr.inst.setprop","myr.inst.hasprop","myr.inst.listprops"}
local LISTS={UNC_LIST,SUNC_LIST,MYRIAD_LIST}
local LCOLS={C.ACC,C.BLUE,C.YELL}

local function hasFunc(name)
    local root=name:match("^([^%.]+)%.")
    if root then
        local tbl=(getfenv and getfenv()[root]) or _G[root]
        if type(tbl)=="table" then local sub=name:match("%.(.+)$");return tbl[sub]~=nil end
        return false
    end
    if getfenv and getfenv()[name]~=nil then return true end
    return _G[name]~=nil
end

buildList=function(li)
    for _,ch in ChkScr:GetChildren() do if not ch:IsA("UIListLayout") then ch:Destroy() end end
    local list=LISTS[li];local col=LCOLS[li];local pass,fail=0,0
    local filter=ChkSearch.Text:lower()
    for _,name in list do
        if filter=="" or name:lower():find(filter,1,true) then
            local ok2=hasFunc(name);if ok2 then pass+=1 else fail+=1 end
            local Row=F(ChkScr,UDim2.new(1,-4,0,22),nil,C.BLK);Row.BackgroundTransparency=1
            local dot=F(Row,UDim2.new(0,6,0,6),UDim2.new(0,1,0,8),ok2 and C.GRN or C.RED);corner(dot,3)
            L(Row,name,UDim2.new(1,-52,1,0),UDim2.new(0,11,0,0),ok2 and C.TXT or C.TXTS,FC,11)
            L(Row,ok2 and "✓" or "✗",UDim2.new(0,28,1,0),UDim2.new(1,-32,0,0),
                ok2 and col or C.RED,FB,13,Enum.TextXAlignment.Right)
        end
    end
    local SR=F(ChkScr,UDim2.new(1,-4,0,24),nil,C.PANEL);corner(SR,5)
    L(SR,string.format("  %d/%d  (%d missing)",pass,pass+fail,fail),
        UDim2.new(1,0,1,0),nil,C.YELL,FB,12,Enum.TextXAlignment.Center)
end
ChkSearch:GetPropertyChangedSignal("Text"):Connect(function() if curSub>0 then buildList(curSub) end end)

-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB 9 — SCRIPT HUB
-- ═══════════════════════════════════════════════════════════════════════════════
local P9=newTab("📜","Scripts")
L(P9,"SCRIPT HUB",UDim2.new(1,0,0,16),UDim2.new(0,0,0,0),C.TXTS,FB,11)

local SHSearch=IN(P9,"Search scripts…",UDim2.new(0.55,0,0,24),UDim2.new(0,0,0,18),false)
SHSearch.TextYAlignment=Enum.TextYAlignment.Center

local SHOut=OUT(P9,UDim2.new(1,0,0,42),UDim2.new(0,0,1,-44))
local function shOut(msg,ok2) SHOut.TextColor3=ok2 and C.GRN or C.RED;SHOut.Text=tostring(msg) end
local SHScr=SCR(P9,UDim2.new(1,0,1,-90),UDim2.new(0,0,0,48));listV(SHScr,4)

local SCRIPTS={
    -- Utilities
    {cat="Utility",name="Infinite Yield",     url="https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source",         desc="Admin commands executor"},
    {cat="Utility",name="SimpleSpy",           url="https://raw.githubusercontent.com/exxtremestuffs/SimpleSpySource/master/SimpleSpy.lua",desc="Remote spy & logger"},
    {cat="Utility",name="Dex Explorer",        url="https://raw.githubusercontent.com/LorekeeperZinnia/Dex/master/Dex3.1.lua",     desc="Full game explorer GUI"},
    {cat="Utility",name="Hydroxide",           url="https://raw.githubusercontent.com/violets-blue/Hydroxide/main/init.lua",       desc="Instance + remote explorer"},
    {cat="Utility",name="Dark Dex v3",         url="https://raw.githubusercontent.com/LorekeeperZinnia/Dex/master/Dex3.1.lua",     desc="Dark-themed game explorer"},
    -- ESP
    {cat="ESP",    name="Unnamed ESP",         url="https://raw.githubusercontent.com/ic3w0lf22/Unnamed-ESP/master/UnnamedESP.lua", desc="Universal player ESP"},
    {cat="ESP",    name="Aimbot Utility",      url="https://raw.githubusercontent.com/ic3w0lf22/Unnamed-ESP/master/UnnamedESP.lua", desc="Basic aim assist overlay"},
    -- Games
    {cat="Game",   name="Prison Life GUI",     url="https://raw.githubusercontent.com/1201for/V3rm-Prison-Life/master/VisualV3rmHack.lua",desc="Prison Life hacks"},
    {cat="Game",   name="Blox Fruit Hub",      url="https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source",         desc="Blox Fruits utilities"},
    {cat="Game",   name="Pet Sim Auto Farm",   url="https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source",         desc="Pet Simulator auto farm"},
    -- Libraries
    {cat="Lib",    name="Fluent UI Library",   url="https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Fluent.lua",     desc="Modern UI framework"},
    {cat="Lib",    name="Orion UI Library",    url="https://raw.githubusercontent.com/shlexware/Orion/main/source",                desc="Clean UI component kit"},
    {cat="Lib",    name="Rayfield UI",         url="https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua", desc="Premium UI library"},
}

local CAT_COLS={Utility=C.ACC,ESP=C.RED,Game=C.GRN,Lib=C.PURP}

local function buildScripts(filter)
    for _,ch in SHScr:GetChildren() do if not ch:IsA("UIListLayout") then ch:Destroy() end end
    local shown=0
    for _,entry in SCRIPTS do
        if filter=="" or entry.name:lower():find(filter,1,true) or entry.cat:lower():find(filter,1,true) then
            shown+=1
            local Row=F(SHScr,UDim2.new(1,-4,0,54),nil,C.PANEL);corner(Row,7);stroke(Row,Color3.fromRGB(28,40,72),1)
            local catCol=CAT_COLS[entry.cat] or C.GREY
            local catBg=F(Row,UDim2.new(0,58,0,18),UDim2.new(0,6,0,5),catCol);corner(catBg,4)
            L(catBg,entry.cat,UDim2.new(1,0,1,0),nil,C.WHT,FB,9,Enum.TextXAlignment.Center)
            L(Row,entry.name,UDim2.new(1,-130,0,20),UDim2.new(0,70,0,3),C.TXT,FB,12)
            L(Row,entry.desc,UDim2.new(1,-130,0,16),UDim2.new(0,70,0,24),C.TXTS,FN,10)
            local BRun=B(Row,"▶ Run",UDim2.new(0,52,0,22),UDim2.new(1,-110,0.5,-11),C.ACC);BRun.TextSize=10
            local BCpy=B(Row,"URL",  UDim2.new(0,44,0,22),UDim2.new(1,-54,0.5,-11),C.GREY);BCpy.TextSize=10
            hov(BRun,C.ACC,C.ACCHV);hov(BCpy,C.GREY,C.GRYHV)
            local url=entry.url;local nm=entry.name
            BRun.MouseButton1Click:Connect(function()
                shOut("Fetching "..nm.."…",true)
                task.spawn(function()
                    local ok,src=pcall(game.HttpGet,game,url,true)
                    if not ok then shOut("HTTP fail: "..tostring(src),false);return end
                    local fn,ce=_ld(src)
                    if not fn then shOut("Compile:\n"..tostring(ce),false);return end
                    local ok2,re=pcall(fn)
                    shOut(ok2 and (nm.." loaded ✓") or "Error:\n"..tostring(re),ok2)
                end)
            end)
            BCpy.MouseButton1Click:Connect(function()
                if setclipboard then setclipboard(url);shOut("URL copied: "..nm,true)
                else shOut("setclipboard not available.",false) end
            end)
        end
    end
    if shown==0 then
        local R=F(SHScr,UDim2.new(1,-4,0,30),nil,C.PANEL);corner(R,6)
        L(R,"No scripts match '"..filter.."'",UDim2.new(1,0,1,0),nil,C.TXTS,FN,12,Enum.TextXAlignment.Center)
    end
end
SHSearch:GetPropertyChangedSignal("Text"):Connect(function() buildScripts(SHSearch.Text:lower()) end)
buildScripts("")

-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB 10 — ENVIRONMENT DIAGNOSTICS
-- ═══════════════════════════════════════════════════════════════════════════════
local P10=newTab("🧪","Environ")
L(P10,"ENVIRONMENT DIAGNOSTICS",UDim2.new(1,0,0,16),UDim2.new(0,0,0,0),C.TXTS,FB,11)
local eRow=rowBar(P10,18,26)
local BEnvRun =B(eRow,"Run Check", UDim2.new(0,110,1,0),nil,C.ACC);BEnvRun.TextSize=11
local BEnvCopy=B(eRow,"Copy Report",UDim2.new(0,104,1,0),nil,C.GREY);BEnvCopy.TextSize=11
local BEnvSave=B(eRow,"Save File",  UDim2.new(0,90,1,0),nil,C.GREY);BEnvSave.TextSize=11
BEnvRun.LayoutOrder=1;BEnvCopy.LayoutOrder=2;BEnvSave.LayoutOrder=3
hov(BEnvRun,C.ACC,C.ACCHV);hov(BEnvCopy,C.GREY,C.GRYHV);hov(BEnvSave,C.GREY,C.GRYHV)

local ExecLbl=L(P10,"Executor: checking…",UDim2.new(1,0,0,16),UDim2.new(0,0,0,48),C.TXTS,FC,11)
local EnvScr=SCR(P10,UDim2.new(1,0,1,-68),UDim2.new(0,0,0,66));listV(EnvScr,2)
local reportLines={}

local function clrEnv()
    for _,ch in EnvScr:GetChildren() do if not ch:IsA("UIListLayout") then ch:Destroy() end end
    reportLines={}
end
local function catHdr(title)
    local R=F(EnvScr,UDim2.new(1,-4,0,20),nil,C.PANEL);corner(R,5)
    L(R,"  "..title,UDim2.new(1,0,1,0),nil,C.PURP,FB,11)
    reportLines[#reportLines+1]="== "..title.." =="
end
local function chkRow(name,ok2,detail)
    local R=F(EnvScr,UDim2.new(1,-4,0,20),nil,C.BLK);R.BackgroundTransparency=1
    local dot=F(R,UDim2.new(0,5,0,5),UDim2.new(0,2,0,7),ok2 and C.GRN or C.RED);corner(dot,3)
    L(R,name,UDim2.new(0.48,0,1,0),UDim2.new(0,10,0,0),ok2 and C.TXT or C.TXTS,FC,11)
    L(R,detail or (ok2 and "ok" or "missing"),
        UDim2.new(0.52,-8,1,0),UDim2.new(0.48,0,0,0),ok2 and C.GRN or C.RED,FN,11)
    reportLines[#reportLines+1]=(ok2 and "[✓] " or "[✗] ")..name.." — "..(detail or (ok2 and "ok" or "missing"))
end
local function infoRow(label,value)
    local R=F(EnvScr,UDim2.new(1,-4,0,18),nil,C.BLK);R.BackgroundTransparency=1
    L(R,label,UDim2.new(0.48,0,1,0),UDim2.new(0,10,0,0),C.TXTS,FN,10)
    L(R,tostring(value),UDim2.new(0.52,-8,1,0),UDim2.new(0.48,0,0,0),C.YELL,FC,10)
    reportLines[#reportLines+1]="  "..label..": "..tostring(value)
end

local function runCheck()
    clrEnv()
    local exec="Unknown"
    if identifyexecutor then pcall(function() exec=tostring(select(1,identifyexecutor())) end)
    elseif getexecutorname then pcall(function() exec=tostring(getexecutorname()) end)
    elseif syn then exec="Synapse X (inferred)" end
    ExecLbl.Text="Executor: "..exec;ExecLbl.TextColor3=C.GRN
    reportLines[#reportLines+1]="Executor: "..exec

    catHdr("Execution Engine")
    chkRow("loadstring",type(loadstring)=="function","available")
    chkRow("load (fallback)",type(load)=="function")
    chkRow("pcall",type(pcall)=="function")
    chkRow("task.wait",type(task)=="table" and type(task.wait)=="function")
    chkRow("task.spawn",type(task)=="table" and type(task.spawn)=="function")
    chkRow("LuaU continue",(function()
        local ld=loadstring or load
        local ok2=ld and pcall(ld,"local function f() for i=1,1 do continue end end")
        return ok2
    end)(),"Roblox LuaU syntax")

    catHdr("Environment & Globals")
    chkRow("getgenv",   type(getgenv)=="function")
    chkRow("getrenv",   type(getrenv)=="function")
    chkRow("getfenv",   type(getfenv)=="function")
    chkRow("setfenv",   type(setfenv)=="function")
    chkRow("gethui",    type(gethui)=="function",type(gethui)=="function" and "available" or "PlayerGui fallback")
    chkRow("shared",    type(shared)=="table")
    chkRow("_G",        type(_G)=="table")
    chkRow("getglobals",type(getglobals)=="function")

    catHdr("File System")
    chkRow("writefile",  type(writefile)=="function")
    chkRow("readfile",   type(readfile)=="function")
    chkRow("isfile",     type(isfile)=="function")
    chkRow("isfolder",   type(isfolder)=="function")
    chkRow("makefolder", type(makefolder)=="function")
    chkRow("listfiles",  type(listfiles)=="function")
    chkRow("appendfile", type(appendfile)=="function")
    chkRow("delfile",    type(delfile)=="function")

    catHdr("Network / HTTP")
    chkRow("game:HttpGet",  type(game.HttpGet)=="function")
    chkRow("request",       type(request)=="function" or (http and type(http.request)=="function") or (syn and type(syn.request)=="function"))
    chkRow("httpget",       type(httpget)=="function")
    chkRow("WebSocket",     type(WebSocket)=="table" and type(WebSocket.connect)=="function")
    chkRow("HttpService",   (function() return pcall(function() return game:GetService("HttpService") end) end)())

    catHdr("Sandbox / Injection")
    chkRow("getrawmetatable",    type(getrawmetatable)=="function")
    chkRow("setrawmetatable",    type(setrawmetatable)=="function")
    chkRow("setreadonly",        type(setreadonly)=="function")
    chkRow("hookmetamethod",     type(hookmetamethod)=="function")
    chkRow("hookfunction",       type(hookfunction)=="function" or type(replaceclosure)=="function")
    chkRow("newcclosure",        type(newcclosure)=="function")
    chkRow("iscclosure",         type(iscclosure)=="function")
    chkRow("setthreadidentity",  type(setthreadidentity)=="function")
    chkRow("getthreadidentity",  type(getthreadidentity)=="function")

    catHdr("Debug Library")
    chkRow("debug.getinfo",      type(debug)=="table" and type(debug.getinfo)=="function")
    chkRow("debug.getupvalue",   type(debug)=="table" and type(debug.getupvalue)=="function")
    chkRow("debug.setupvalue",   type(debug)=="table" and type(debug.setupvalue)=="function")
    chkRow("debug.getconstant",  type(debug)=="table" and type(debug.getconstant)=="function")
    chkRow("debug.setconstant",  type(debug)=="table" and type(debug.setconstant)=="function")
    chkRow("debug.getproto",     type(debug)=="table" and type(debug.getproto)=="function")
    chkRow("debug.traceback",    type(debug)=="table" and type(debug.traceback)=="function")

    catHdr("Input / Drawing")
    chkRow("keypress",           type(keypress)=="function")
    chkRow("mouse1click",        type(mouse1click)=="function")
    chkRow("mousemoveabs",       type(mousemoveabs)=="function")
    chkRow("Drawing.new",        type(Drawing)=="table" and type(Drawing.new)=="function")
    chkRow("isrbxactive",        type(isrbxactive)=="function")
    chkRow("getconnections",     type(getconnections)=="function")
    chkRow("getnamecallmethod",  type(getnamecallmethod)=="function")

    catHdr("Remote / Signal")
    chkRow("firesignal",         type(firesignal)=="function")
    chkRow("replicatesignal",    type(replicatesignal)=="function")
    chkRow("fireclickdetector",  type(fireclickdetector)=="function")
    chkRow("getscripts",         type(getscripts)=="function")
    chkRow("getrunningscripts",  type(getrunningscripts)=="function")

    catHdr("Console / Output")
    chkRow("rconsoleopen",   type(rconsoleopen)=="function")
    chkRow("rconsoleprint",  type(rconsoleprint)=="function")
    chkRow("rconsoleclear",  type(rconsoleclear)=="function")

    catHdr("Game State")
    chkRow("game:IsLoaded()",game:IsLoaded(),game:IsLoaded() and "fully loaded" or "still loading")
    chkRow("LocalPlayer",LP~=nil,LP and "@"..LP.Name or "missing")
    chkRow("Character",LP and LP.Character~=nil,(LP and LP.Character) and "spawned" or "not spawned")
    chkRow("SS_ExecBridge",Bridge~=nil,Bridge and "ready" or "inject SS_Executor.lua server-side")

    catHdr("System Info")
    local ok2v,rver=pcall(function() return game:GetService("UserInputService"):GetStringForKeyCode(Enum.KeyCode.Return) end)
    infoRow("Platform", UIS.TouchEnabled and "Touch/iOS" or "PC")
    infoRow("Game ID",  tostring(game.GameId))
    infoRow("Place ID", tostring(game.PlaceId))
    infoRow("Players",  tostring(#Players:GetPlayers()))
    local ident=0; pcall(function() ident=getthreadidentity and getthreadidentity() or 0 end)
    infoRow("Thread Identity",tostring(ident))

    local pass2,total2=0,0
    for _,ln in reportLines do
        if ln:sub(1,4)=="[✓]" then pass2+=1;total2+=1
        elseif ln:sub(1,4)=="[✗]" then total2+=1 end
    end
    local SR=F(EnvScr,UDim2.new(1,-4,0,26),nil,C.PANEL);corner(SR,5)
    L(SR,string.format("  %d / %d checks passed",pass2,total2),
        UDim2.new(1,0,1,0),nil,C.YELL,FB,12,Enum.TextXAlignment.Center)
end

BEnvRun.MouseButton1Click:Connect(runCheck)
BEnvCopy.MouseButton1Click:Connect(function()
    if setclipboard then setclipboard(table.concat(reportLines,"\n"));ExecLbl.Text="Copied ✓"
    else ExecLbl.Text="setclipboard not available" end
end)
BEnvSave.MouseButton1Click:Connect(function()
    if not writefile then ExecLbl.Text="writefile not available";return end
    writefile("nexus_environ.txt",table.concat(reportLines,"\n"))
    ExecLbl.Text="Saved → nexus_environ.txt";ExecLbl.TextColor3=C.GRN
end)

-- ═══════════════════════════════════════════════════════════════════════════════
--  DRAG  (PC mouse + iPad touch)
-- ═══════════════════════════════════════════════════════════════════════════════
local drag,ds,dp=false,nil,nil
TBAR.InputBegan:Connect(function(inp)
    local t=inp.UserInputType
    if t==Enum.UserInputType.MouseButton1 or t==Enum.UserInputType.Touch then
        drag=true;ds=inp.Position;dp=WIN.Position
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

-- ═══════════════════════════════════════════════════════════════════════════════
--  MINIMISE
-- ═══════════════════════════════════════════════════════════════════════════════
local mini=false
BtnMin.MouseButton1Click:Connect(function()
    mini=not mini
    tw(WIN,{Size=mini and UDim2.new(0,650,0,44) or UDim2.new(0,650,0,530)},TS2)
    BODY.Visible=not mini;SIDE.Visible=not mini
    BtnMin.Text=mini and "□" or "—"
end)

-- ═══════════════════════════════════════════════════════════════════════════════
--  INIT
-- ═══════════════════════════════════════════════════════════════════════════════
showPage(1)
switchSub(1);buildList(1)
task.spawn(runCheck)
notify("Nexus Executor","Loaded ✓  ("..tabN.." tabs)",3)

end) -- pcall end

if not _ok then
    warn("[Nexus] STARTUP ERROR: "..tostring(_err))
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification",
            {Title="Nexus ERROR",Text=tostring(_err):sub(1,80),Duration=8})
    end)
end
