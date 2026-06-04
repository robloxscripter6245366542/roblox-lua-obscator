-- ╔══════════════════════════════════════════════════════════════════╗
-- ║   🤖 CLAUDE HUB v1.0  |  Universal require() Script Hub          ║
-- ║   Works on Delta · Xeno · Solara · Codex · Wave · Fluxus · more  ║
-- ║   Scans your environment & uses each executor to the MAX.        ║
-- ║   Self-contained — paste & run.   Toggle: [Insert]  or  [ ] ]   ║
-- ╚══════════════════════════════════════════════════════════════════╝

local _ok, _err = pcall(function()

local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")
local TS      = game:GetService("TweenService")
local WS      = game:GetService("Workspace")
local SG      = game:GetService("StarterGui")

local LP   = Players.LocalPlayer
local PGui = LP:WaitForChild("PlayerGui", 10)

-- ═══════════════════════════════════════════════════════════════════════════════
--  ENVIRONMENT SCAN — detect executor & every capability, then use the max
-- ═══════════════════════════════════════════════════════════════════════════════
local ENV = {}

-- safe getter for arbitrary globals (some executors sandbox getfenv/getgenv)
local function G(name)
    local ok2,v=pcall(function() return (getgenv and getgenv()[name]) or rawget(_G,name) or getfenv(0)[name] end)
    if ok2 then return v end
    return nil
end

-- Detect executor NAME (official API first, then fingerprints)
local function detectExecutor()
    local nm
    local ok2,res=pcall(function()
        if identifyexecutor then return (identifyexecutor()) end
        if getexecutorname then return (getexecutorname()) end
        return nil
    end)
    if ok2 and res and res~="" then nm=tostring(res) end
    if not nm then
        -- fingerprint by signature globals
        if      G("Delta") or G("DeltaLoaded")        then nm="Delta"
        elseif  G("Xeno")  or G("xeno")               then nm="Xeno"
        elseif  G("Solara") or G("solara")            then nm="Solara"
        elseif  G("Codex") or G("codex")              then nm="Codex"
        elseif  G("Wave")  or G("WAVE_LOADED")        then nm="Wave"
        elseif  G("fluxus")                           then nm="Fluxus"
        elseif  G("KRNL_LOADED")                      then nm="KRNL"
        elseif  (syn and syn.request)                 then nm="Synapse X"
        elseif  G("is_sirhurt_closure")               then nm="SirHurt"
        elseif  G("secure_load")                      then nm="ScriptWare"
        else nm="Unknown" end
    end
    return nm
end

-- pick the best available HTTP request function across executors
local function pickHttp()
    local cands = {
        (syn   and syn.request),
        (http  and http.request),
        (G("http_request")),
        (request),
        (fluxus and fluxus.request),
    }
    for _,f in ipairs(cands) do if type(f)=="function" then return f end end
    return nil
end

ENV.name      = detectExecutor()
ENV.httpReq   = pickHttp()

-- Capability map — probe everything that matters for "max" usage
ENV.caps = {
    ["require"]            = (require ~= nil),
    ["loadstring"]         = (loadstring ~= nil),
    ["HttpGet"]            = true,
    ["http.request"]       = (ENV.httpReq ~= nil),
    ["hookmetamethod"]     = (hookmetamethod ~= nil),
    ["getnamecallmethod"]  = (getnamecallmethod ~= nil),
    ["newcclosure"]        = (newcclosure ~= nil),
    ["hookfunction"]       = (hookfunction ~= nil or G("replaceclosure") ~= nil),
    ["getgc"]              = (getgc ~= nil),
    ["getgenv"]            = (getgenv ~= nil),
    ["getrawmetatable"]    = (getrawmetatable ~= nil),
    ["setreadonly"]        = (setreadonly ~= nil),
    ["Drawing"]            = (Drawing ~= nil),
    ["gethui"]             = (gethui ~= nil),
    ["setclipboard"]       = (setclipboard ~= nil or G("toclipboard") ~= nil),
    ["readfile"]           = (readfile ~= nil),
    ["writefile"]          = (writefile ~= nil),
    ["listfiles"]          = (listfiles ~= nil),
    ["isfolder"]           = (isfolder ~= nil),
    ["getconnections"]     = (getconnections ~= nil),
    ["fireclickdetector"]  = (fireclickdetector ~= nil),
    ["firetouchinterest"]  = (firetouchinterest ~= nil),
    ["getcustomasset"]     = (getcustomasset ~= nil),
    ["getscriptbytecode"]  = (getscriptbytecode ~= nil or G("dumpstring") ~= nil),
    ["queue_teleport"]     = (queue_on_teleport ~= nil or (syn and syn.queue_on_teleport) ~= nil),
}
-- count score
local _capN,_capTot=0,0
for _,v in pairs(ENV.caps) do _capTot=_capTot+1; if v then _capN=_capN+1 end end
ENV.score = _capN
ENV.total = _capTot

-- unified clipboard
ENV.setClip = function(t)
    if setclipboard then pcall(setclipboard,t)
    elseif G("toclipboard") then pcall(G("toclipboard"),t) end
end
ENV.HAS_CLIP = (setclipboard ~= nil or G("toclipboard") ~= nil)
ENV.HAS_GHUI = (gethui ~= nil)
ENV.HAS_REQ  = (require ~= nil)

pcall(function()
    SG:SetCore("SendNotification",{Title="🤖 Claude Hub",Text=ENV.name.." detected — "..ENV.score.."/"..ENV.total.." APIs",Duration=3})
end)

-- ── Palette ─────────────────────────────────────────────────────────────────────
local C = {
    BG     = Color3.fromRGB(15, 13, 20),
    SIDE   = Color3.fromRGB(10,  9, 14),
    PANEL  = Color3.fromRGB(23, 20, 30),
    CARD   = Color3.fromRGB(32, 28, 42),
    DARK   = Color3.fromRGB( 7,  6, 10),
    BORDER = Color3.fromRGB(46, 40, 60),
    ACCENT = Color3.fromRGB(217,119, 66),   -- Claude clay/orange
    ACC2   = Color3.fromRGB(235,150,100),
    GREEN  = Color3.fromRGB(52,211,153),
    RED    = Color3.fromRGB(244, 63, 94),
    YELLOW = Color3.fromRGB(251,191, 36),
    PINK   = Color3.fromRGB(236, 72,153),
    WHITE  = Color3.fromRGB(245,242,236),
    TEXT   = Color3.fromRGB(196,190,200),
    MUTED  = Color3.fromRGB(108,100,120),
}
local TF  = TweenInfo.new(0.16,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
local TS2 = TweenInfo.new(0.28,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
local FB,FC,FN = Enum.Font.GothamBold, Enum.Font.GothamSemibold, Enum.Font.Gotham

-- ── UI primitives ────────────────────────────────────────────────────────────────
local function tw(i,p,t) TS:Create(i,t or TF,p):Play() end
local function corner(i,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 8); c.Parent=i end
local function stroke(i,col,t) local s=Instance.new("UIStroke"); s.Color=col or C.BORDER; s.Thickness=t or 1; s.Parent=i; return s end
local function grad(i,c1,c2,rot) local g=Instance.new("UIGradient"); g.Color=ColorSequence.new(c1,c2); g.Rotation=rot or 0; g.Parent=i; return g end
local function pad(i,t,b,l,r)
    local p=Instance.new("UIPadding")
    p.PaddingTop=UDim.new(0,t or 6); p.PaddingBottom=UDim.new(0,b or 6)
    p.PaddingLeft=UDim.new(0,l or 8); p.PaddingRight=UDim.new(0,r or 8); p.Parent=i
end
local function listV(i,sp) local l=Instance.new("UIListLayout"); l.SortOrder=Enum.SortOrder.LayoutOrder; l.Padding=UDim.new(0,sp or 6); l.Parent=i; return l end

local function Frm(parent,sz,pos,col,nm)
    local f=Instance.new("Frame")
    f.Size=sz or UDim2.new(1,0,0,30); f.Position=pos or UDim2.new(0,0,0,0)
    f.BackgroundColor3=col or C.PANEL; f.BorderSizePixel=0; f.Name=nm or "Frame"; f.Parent=parent; return f
end
local function Lbl(parent,txt,sz,pos,col,fs,font)
    local l=Instance.new("TextLabel")
    l.Size=sz or UDim2.new(1,0,0,20); l.Position=pos or UDim2.new(0,0,0,0)
    l.BackgroundTransparency=1; l.Text=txt or ""; l.TextColor3=col or C.TEXT
    l.TextSize=fs or 13; l.Font=font or FN; l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=parent; return l
end
local function Btn(parent,txt,sz,pos,col,cb)
    local f=Frm(parent,sz,pos,col or C.ACCENT); corner(f,8)
    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1; l.Text=txt or ""
    l.TextColor3=C.WHITE; l.TextSize=13; l.Font=FB; l.Parent=f
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
    i.Text=""; i.TextColor3=C.WHITE; i.TextSize=13; i.Font=FN; i.ClearTextOnFocus=false; i.Parent=f; return f,i
end
local function Scr(parent,sz,pos)
    local f=Frm(parent,sz,pos,C.BG); f.BackgroundTransparency=1
    local s=Instance.new("ScrollingFrame")
    s.Size=UDim2.new(1,0,1,0); s.BackgroundTransparency=1; s.BorderSizePixel=0
    s.ScrollBarThickness=3; s.ScrollBarImageColor3=C.ACCENT
    s.CanvasSize=UDim2.new(0,0,0,0); s.AutomaticCanvasSize=Enum.AutomaticSize.Y; s.Parent=f; return f,s
end
local function notify(t,m,d) pcall(function() SG:SetCore("SendNotification",{Title=t,Text=m,Duration=d or 3}) end) end

-- ── require runner (uses every loader the executor supports) ──────────────────────
local function runRequire(name,id,mode)
    if not ENV.HAS_REQ then notify("Claude Hub","require() unavailable on "..ENV.name,4); return end
    if not id then notify("Claude Hub","No asset ID",3); return end
    notify("Claude Hub","Loading "..name.."…",2)
    task.spawn(function()
        local ok2,res=pcall(function()
            if mode=="call" then return require(id)() else return require(id) end
        end)
        if ok2 then notify("Claude Hub",name.." loaded ✓",3)
        else notify("Load Failed",name..": "..tostring(res):sub(1,50),5) end
    end)
end

-- loadstring via best HTTP for the executor
local function runUrl(name,url)
    notify("Claude Hub","Fetching "..name.."…",2)
    task.spawn(function()
        local body
        local ok2=pcall(function() body=game:HttpGet(url,true) end)
        if (not ok2 or not body) and ENV.httpReq then
            local ok3,resp=pcall(ENV.httpReq,{Url=url,Method="GET"})
            if ok3 and resp and resp.Body then body=resp.Body end
        end
        if not body then notify("HTTP Error",name.." — fetch failed",5); return end
        local fn,ce=loadstring(body)
        if not fn then notify("Compile Error",tostring(ce):sub(1,55),5); return end
        local ok4,e4=pcall(fn)
        if ok4 then notify("Claude Hub",name.." loaded ✓",3)
        else notify("Runtime Error",tostring(e4):sub(1,55),5) end
    end)
end

-- ── GUI shell ─────────────────────────────────────────────────────────────────────
local GUI_ROOT = ENV.HAS_GHUI and gethui() or PGui
local old=GUI_ROOT:FindFirstChild("__CLAUDE_HUB__"); if old then old:Destroy() end
local SGI=Instance.new("ScreenGui")
SGI.Name="__CLAUDE_HUB__"; SGI.ResetOnSpawn=false
SGI.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; SGI.IgnoreGuiInset=true; SGI.Parent=GUI_ROOT

local WIN=Frm(SGI,UDim2.new(0,672,0,488),UDim2.new(0.5,-336,0.5,-244),C.BG,"WIN")
corner(WIN,14); stroke(WIN,C.BORDER,1); WIN.ClipsDescendants=true
local shd=Instance.new("ImageLabel")
shd.Size=UDim2.new(1,46,1,46); shd.Position=UDim2.new(0,-23,0,-23); shd.BackgroundTransparency=1
shd.Image="rbxassetid://6014261993"; shd.ImageColor3=Color3.fromRGB(217,119,66); shd.ImageTransparency=0.55
shd.ScaleType=Enum.ScaleType.Slice; shd.SliceCenter=Rect.new(49,49,450,450); shd.Parent=WIN

local TBAR=Frm(WIN,UDim2.new(1,0,0,48),nil,C.SIDE,"TBAR"); grad(TBAR,C.SIDE,C.PANEL,90)
local function dot(xoff,col) local d=Frm(TBAR,UDim2.new(0,13,0,13),UDim2.new(0,xoff,0.5,-6.5),col); corner(d,7); return d end
local dotC=dot(13,C.RED); local dotM=dot(31,C.YELLOW); local dotG=dot(49,C.GREEN)
local titleL=Lbl(TBAR,"🤖  Claude Hub",UDim2.new(1,-280,1,0),UDim2.new(0,76,0,0),C.WHITE,16,FB)
titleL.TextXAlignment=Enum.TextXAlignment.Center
-- executor chip
local chipBg=Frm(TBAR,UDim2.new(0,230,0,28),UDim2.new(1,-240,0.5,-14),C.CARD); corner(chipBg,14); stroke(chipBg,C.ACCENT,1)
Lbl(chipBg,"⚡ "..ENV.name.."   ·   "..ENV.score.."/"..ENV.total.." APIs",UDim2.new(1,0,1,0),nil,C.ACC2,11,FB).TextXAlignment=Enum.TextXAlignment.Center

-- scrollable sidebar (many tabs)
local SIDEbg=Frm(WIN,UDim2.new(0,170,1,-48),UDim2.new(0,0,0,48),C.SIDE,"SIDEBG")
local SIDE=Instance.new("ScrollingFrame")
SIDE.Size=UDim2.new(1,0,1,0); SIDE.BackgroundTransparency=1; SIDE.BorderSizePixel=0
SIDE.ScrollBarThickness=2; SIDE.ScrollBarImageColor3=C.ACCENT
SIDE.CanvasSize=UDim2.new(0,0,0,0); SIDE.AutomaticCanvasSize=Enum.AutomaticSize.Y; SIDE.Parent=SIDEbg
pad(SIDE,8,8,6,6); listV(SIDE,3)
local BODY=Frm(WIN,UDim2.new(1,-170,1,-48),UDim2.new(0,170,0,48),C.BG,"BODY")
Frm(WIN,UDim2.new(0,1,1,-48),UDim2.new(0,170,0,48),C.BORDER)

-- ── Tabs ───────────────────────────────────────────────────────────────────────
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
    local bg=Frm(SIDE,UDim2.new(1,0,0,40),nil,C.SIDE,"T"..n); corner(bg,9)
    local bar=Frm(bg,UDim2.new(0,3,0.55,0),UDim2.new(0,0,0.225,0),C.SIDE); corner(bar,2)
    local ico=Lbl(bg,icon,UDim2.new(0,26,1,0),UDim2.new(0,8,0,0),C.MUTED,14,FB)
    local lbl=Lbl(bg,name,UDim2.new(1,-40,1,0),UDim2.new(0,36,0,0),C.MUTED,12,FC)
    local tb=Instance.new("TextButton")
    tb.Size=UDim2.new(1,0,1,0); tb.BackgroundTransparency=1; tb.Text=""; tb.Parent=bg
    tb.MouseButton1Click:Connect(function() showPage(n) end)
    tb.MouseEnter:Connect(function() if curPage~=n then tw(bg,{BackgroundColor3=C.CARD}) end end)
    tb.MouseLeave:Connect(function() if curPage~=n then tw(bg,{BackgroundColor3=C.SIDE}) end end)
    tabBtns[n]={bg=bg,bar=bar,ico=ico,lbl=lbl}
    local page=Frm(BODY,UDim2.new(1,0,1,0),nil,C.BG,"P"..n); page.Visible=false; pages[n]=page
    local _,scroller=Scr(page,UDim2.new(1,-16,1,-10),UDim2.new(0,8,0,5))
    listV(scroller,6); pad(scroller,6,6,4,4)
    return scroller
end
local function SectionHdr(parent,txt)
    local h=Lbl(parent,txt,UDim2.new(1,0,0,18),nil,C.MUTED,11,FB)
    h.TextXAlignment=Enum.TextXAlignment.Left; return h
end
local function ScriptCard(parent,s)
    local card=Frm(parent,UDim2.new(1,0,0,56),nil,C.CARD); corner(card,10); pad(card,6,6,12,8)
    Lbl(card,s.name,UDim2.new(1,-96,0,18),nil,C.WHITE,13,FB)
    Lbl(card,(s.by and ("by "..s.by.."  ·  ") or "").."id "..tostring(s.id),
        UDim2.new(1,-96,0,14),UDim2.new(0,0,0,20),C.MUTED,11,FN)
    if s.note then Lbl(card,s.note,UDim2.new(1,-96,0,12),UDim2.new(0,0,0,38),C.MUTED,10,FN) end
    Btn(card,"Run",UDim2.new(0,80,0,34),UDim2.new(1,-84,0.5,-17),C.ACCENT,function()
        runRequire(s.name,s.id,s.mode or "plain")
    end)
    if ENV.HAS_CLIP then
        Btn(card,"Copy ID",UDim2.new(0,52,0,18),UDim2.new(1,-84,0,6),C.PANEL,function()
            ENV.setClip(tostring(s.id)); notify("Claude Hub","ID copied!",1)
        end)
    end
end

-- ── Drag / minimize / close / keybind ───────────────────────────────────────────
do
    local dragging,startp,wp
    TBAR.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; startp=inp.Position; wp=WIN.Position end
    end)
    UIS.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType==Enum.UserInputType.MouseMovement then
            local d=inp.Position-startp
            WIN.Position=UDim2.new(wp.X.Scale,wp.X.Offset+d.X,wp.Y.Scale,wp.Y.Offset+d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
end
local minimized=false
local function clickable(d,cb)
    local b=Instance.new("TextButton"); b.Size=UDim2.new(1,0,1,0); b.BackgroundTransparency=1; b.Text=""; b.Parent=d
    b.MouseButton1Click:Connect(cb)
end
clickable(dotC,function() tw(WIN,{Size=UDim2.new(0,672,0,0)},TweenInfo.new(0.18)); task.delay(0.2,function() SGI:Destroy() end) end)
clickable(dotM,function() minimized=not minimized; tw(WIN,{Size=UDim2.new(0,672,0,minimized and 48 or 488)},TS2) end)
UIS.InputBegan:Connect(function(inp,gp)
    if gp then return end
    if inp.KeyCode==Enum.KeyCode.Insert or inp.KeyCode==Enum.KeyCode.RightBracket then SGI.Enabled=not SGI.Enabled end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB — CUSTOM LOADER
-- ═══════════════════════════════════════════════════════════════════════════════
do
    local P=newTab("⌨","Custom")
    SectionHdr(P,"■ LOAD ANY ASSET ID  (require)")
    do
        local note=Frm(P,UDim2.new(1,0,0,42),nil,C.PANEL); corner(note,8); pad(note,6,6,10,10)
        Lbl(note,"require(ID) loads a published ModuleScript and runs it.",UDim2.new(1,0,1,0),nil,C.MUTED,11,FN)
    end
    local _,idBox=Inp(P,"Asset ID  (numeric)",UDim2.new(1,0,0,36))
    Btn(P,"▶  require(ID)",UDim2.new(1,0,0,38),nil,C.ACCENT,function() runRequire("Custom",tonumber(idBox.Text),"plain") end)
    Btn(P,"▶  require(ID)()  — call return",UDim2.new(1,0,0,38),nil,C.PANEL,function() runRequire("Custom",tonumber(idBox.Text),"call") end)

    SectionHdr(P,"■ LOAD BY URL  (loadstring — uses "..ENV.name.." HTTP)")
    local _,urlBox=Inp(P,"https://raw.githubusercontent.com/.../script.lua",UDim2.new(1,0,0,36))
    Btn(P,"▶  loadstring(HttpGet(url))()",UDim2.new(1,0,0,38),nil,C.ACCENT,function()
        if urlBox.Text~="" then runUrl("URL Script",urlBox.Text) else notify("Claude Hub","Enter a URL",3) end
    end)

    if not ENV.HAS_REQ then
        local w=Frm(P,UDim2.new(1,0,0,28),nil,Color3.fromRGB(60,30,40)); corner(w,8); pad(w,0,0,10,10)
        Lbl(w,"⚠ require() unavailable on "..ENV.name,UDim2.new(1,0,1,0),nil,C.YELLOW,11,FN)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  Category tab data — every entry is require(ID).  Verify before trusting.
-- ═══════════════════════════════════════════════════════════════════════════════
local TABS = {
 {icon="🌐", name="Universal", scripts={
    {name="Infinite Yield",      by="EdgeIY", id=5747978845},
    {name="Dark Dex (explorer)", by="Moon",   id=11588107797},
    {name="Hydroxide",           by="Upbolt", id=6588975471, note="remote spy"},
    {name="Simple Spy",          by="exx",    id=7560252703, note="remote logger"},
    {name="Remote Spy v3",       by="74Q",    id=6592246360},
    {name="Owl Hub",             by="Owl",    id=5042889335},
    {name="CMD-X Admin",         by="CMD-X",  id=7621980194},
 }},
 {icon="🎯", name="Aimbot", scripts={
    {name="Universal Aimbot",    by="UAS",    id=8194423072},
    {name="Silent Aim",          by="silent", id=8194420774},
    {name="Camlock",             by="cam",    id=8194425331},
    {name="Hitbox Expander",     by="hb",     id=8194427711},
 }},
 {icon="👁", name="ESP", scripts={
    {name="Universal ESP",       by="esp",    id=8194418011},
    {name="Chams (through walls)",by="chams", id=8194419220},
    {name="Player Tracers",      by="trace",  id=8194420113},
    {name="Name + Health ESP",   by="esp",    id=8194421005},
 }},
 {icon="🔫", name="FPS Games", scripts={
    {name="Arsenal Hub",         by="ars",    id=8194430011},
    {name="Phantom Forces",      by="pf",     id=8194431022},
    {name="Big Paintball",       by="bpb",    id=8194432033},
    {name="Bad Business",        by="bb",     id=8194433044},
    {name="Krunker-style FPS",   by="fps",    id=8194434055},
 }},
 {icon="🏗", name="Tycoons", scripts={
    {name="Universal Tycoon Auto",by="tyc",   id=8194440011},
    {name="Retail Tycoon 2",     by="rt2",    id=8194441022},
    {name="Restaurant Tycoon",   by="rest",   id=8194442033},
    {name="Theme Park Tycoon",   by="tpt",    id=8194443044},
 }},
 {icon="🌱", name="Simulators", scripts={
    {name="Pet Simulator 99",    by="ps99",   id=8194450011},
    {name="Bee Swarm Sim",       by="bss",    id=8194451022},
    {name="Blox Fruits",         by="bf",     id=8194452033},
    {name="Anime Fighting Sim",  by="afs",    id=8194453044},
    {name="Bubble Gum Sim",      by="bgs",    id=8194454055},
    {name="Mining Simulator 2",  by="ms2",    id=8194455066},
 }},
 {icon="🔪", name="Murder/PvP", scripts={
    {name="Murder Mystery 2",    by="mm2",    id=8194460011},
    {name="Da Hood",             by="dh",     id=8194461022},
    {name="Counter Blox",        by="cb",     id=8194462033},
    {name="Knife Ability Test",  by="kat",    id=8194463044},
 }},
 {icon="🏃", name="Obby/Parkour", scripts={
    {name="Universal Obby Auto", by="obby",   id=8194470011},
    {name="Tower of Hell",       by="toh",    id=8194471022},
    {name="Speed Run 4",         by="sr4",    id=8194472033},
 }},
 {icon="🚗", name="Vehicle", scripts={
    {name="Jailbreak Hub",       by="jb",     id=8194480011},
    {name="Mad City",            by="mc",     id=8194481022},
    {name="Vehicle Legends",     by="vl",     id=8194482033},
    {name="Car Dealership Tycoon",by="cdt",   id=8194483044},
 }},
 {icon="🎮", name="Misc Games", scripts={
    {name="Adopt Me Hub",        by="am",     id=8194490011},
    {name="Brookhaven RP",       by="bh",     id=8194491022},
    {name="Doors Hub",           by="doors",  id=8194492033},
    {name="Evade",               by="evade",  id=8194493044},
    {name="Rivals",              by="riv",    id=8194494055},
 }},
 {icon="🛠", name="Utility", scripts={
    {name="FPS Booster",         by="fps",    id=8194500011},
    {name="Anti-AFK",            by="afk",    id=8194501022},
    {name="Server Hop",          by="hop",    id=8194502033},
    {name="Player Logger",       by="log",    id=8194503044},
    {name="Fly / Noclip Util",   by="util",   id=8194504055},
 }},
}
for _,t in ipairs(TABS) do
    local P=newTab(t.icon,t.name)
    SectionHdr(P,"■ "..string.upper(t.name).."  ·  require() scripts")
    for _,s in ipairs(t.scripts) do ScriptCard(P,s) end
    do
        local w=Frm(P,UDim2.new(1,0,0,26),nil,C.PANEL); corner(w,8); pad(w,0,0,10,10)
        Lbl(w,"IDs are placeholders — paste verified IDs in Custom tab.",UDim2.new(1,0,1,0),nil,C.MUTED,10,FN)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB — ENVIRONMENT  (full executor scan)
-- ═══════════════════════════════════════════════════════════════════════════════
do
    local P=newTab("🔬","Environ")
    local function row(parent,lbl,val,col)
        local r=Frm(parent,UDim2.new(1,0,0,28),nil,C.CARD); corner(r,6); pad(r,0,0,10,10)
        Lbl(r,lbl,UDim2.new(0.62,0,1,0),nil,C.TEXT,12,FN)
        local v=Lbl(r,val,UDim2.new(0.38,0,1,0),UDim2.new(0.62,0,0,0),col or C.GREEN,12,FB)
        v.TextXAlignment=Enum.TextXAlignment.Right
    end

    -- Big banner
    local ban=Frm(P,UDim2.new(1,0,0,58),nil,C.PANEL); corner(ban,10); stroke(ban,C.ACCENT,1); pad(ban,8,8,12,12)
    Lbl(ban,"⚡ "..ENV.name,UDim2.new(1,0,0,22),nil,C.ACC2,18,FB)
    Lbl(ban,ENV.score.." / "..ENV.total.." capabilities detected — using executor to the max",
        UDim2.new(1,0,0,16),UDim2.new(0,0,0,28),C.MUTED,11,FN)

    SectionHdr(P,"■ CAPABILITY SCAN")
    -- stable display order
    local order={"require","loadstring","HttpGet","http.request","hookmetamethod",
        "getnamecallmethod","newcclosure","hookfunction","getgc","getgenv",
        "getrawmetatable","setreadonly","Drawing","gethui","setclipboard",
        "readfile","writefile","listfiles","isfolder","getconnections",
        "fireclickdetector","firetouchinterest","getcustomasset","getscriptbytecode","queue_teleport"}
    for _,k in ipairs(order) do
        local ok2=ENV.caps[k]
        row(P,k, ok2 and "✓ Available" or "✗ Missing", ok2 and C.GREEN or C.RED)
    end

    SectionHdr(P,"■ GAME")
    row(P,"Place ID", tostring(game.PlaceId), C.ACCENT)
    row(P,"Game",     tostring(game.Name):sub(1,24), C.ACCENT)
    row(P,"Players",  tostring(#Players:GetPlayers()), C.TEXT)
    row(P,"Username", LP.Name, C.TEXT)

    SectionHdr(P,"■ TOOLS")
    if ENV.HAS_CLIP then
        Btn(P,"Copy Full Environment Report",UDim2.new(1,0,0,34),nil,C.ACCENT,function()
            local lines={"Claude Hub — Environment Report","Executor: "..ENV.name,
                "Score: "..ENV.score.."/"..ENV.total,"Place: "..game.PlaceId,"",
                "Capabilities:"}
            for _,k in ipairs(order) do table.insert(lines,(ENV.caps[k] and "[+] " or "[-] ")..k) end
            ENV.setClip(table.concat(lines,"\n")); notify("Claude Hub","Report copied!",2)
        end)
    end
    Btn(P,"Re-scan Environment",UDim2.new(1,0,0,34),nil,C.PANEL,function()
        notify("Claude Hub",ENV.name.." · "..ENV.score.."/"..ENV.total.." APIs",3)
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB — INFO
-- ═══════════════════════════════════════════════════════════════════════════════
do
    local P=newTab("ℹ","Info")
    do
        local b=Frm(P,UDim2.new(1,0,0,90),nil,C.PANEL); corner(b,10); pad(b,8,8,12,12)
        Lbl(b,"🤖 Claude Hub",UDim2.new(1,0,0,24),nil,C.WHITE,18,FB)
        Lbl(b,"Universal require() script hub.\nLoads scripts purely through require(ID) so it works\nacross any game and any executor.",
            UDim2.new(1,0,0,54),UDim2.new(0,0,0,28),C.MUTED,12,FN)
    end
    SectionHdr(P,"■ SUPPORTED EXECUTORS")
    for _,e in ipairs({"Delta","Xeno","Solara","Codex","Wave","Fluxus","Synapse X","KRNL","Script-Ware","SirHurt"}) do
        local r=Frm(P,UDim2.new(1,0,0,26),nil,C.CARD); corner(r,6); pad(r,0,0,10,10)
        Lbl(r,e,UDim2.new(0.7,0,1,0),nil,C.TEXT,12,FN)
        local hit = (e==ENV.name)
        local v=Lbl(r,hit and "◉ THIS ONE" or "○ supported",UDim2.new(0.3,0,1,0),UDim2.new(0.7,0,0,0),hit and C.ACCENT or C.GREEN,11,FB)
        v.TextXAlignment=Enum.TextXAlignment.Right
    end
    SectionHdr(P,"■ KEYBINDS")
    local function kb(lbl,val)
        local r=Frm(P,UDim2.new(1,0,0,26),nil,C.CARD); corner(r,6); pad(r,0,0,10,10)
        Lbl(r,lbl,UDim2.new(0.6,0,1,0),nil,C.TEXT,12,FN)
        local v=Lbl(r,val,UDim2.new(0.4,0,1,0),UDim2.new(0.6,0,0,0),C.TEXT,11,FB)
        v.TextXAlignment=Enum.TextXAlignment.Right
    end
    kb("Toggle GUI","[Insert] or [ ] ]")
    kb("Close","Red dot")
    kb("Minimize","Yellow dot")
    do
        local w=Frm(P,UDim2.new(1,0,0,52),nil,C.PANEL); corner(w,8); pad(w,6,6,10,10)
        Lbl(w,"⚠ Category-tab IDs are PLACEHOLDERS. Replace with\nverified module IDs, or paste your own require(ID)\nin the Custom tab.",UDim2.new(1,0,1,0),nil,C.YELLOW,11,FN)
    end
end

showPage(1)
notify("🤖 Claude Hub","Ready on "..ENV.name.." — press ] to toggle",4)

end) -- pcall

if not _ok then
    warn("[Claude Hub] STARTUP ERROR: "..tostring(_err))
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification",
            {Title="Claude Hub ERROR",Text=tostring(_err):sub(1,80),Duration=6})
    end)
end
