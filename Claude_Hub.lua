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
local RS      = game:GetService("ReplicatedStorage")

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

-- ── require runner (handles every call shape these scripts use) ───────────────────
-- opt may be a string ("plain"/"call") OR a table {mode=, method=, colon=, args={...}}
--   require(id)                              → plain
--   require(id)()                            → mode "call"
--   require(id)(a,b)                         → args set, no method
--   require(id).Method(a,b)                  → method set
--   require(id):Method(a,b)                  → method set + colon=true
-- arg tokens: "@me"/"@user" → LocalPlayer.Name ; "@id" → UserId ; else literal
local function resolveArg(a)
    if a=="@me" or a=="@user" then return LP.Name end
    if a=="@id" then return LP.UserId end
    return a
end
local function buildArgs(opt)
    local out={}
    if opt.args then for i,a in ipairs(opt.args) do out[i]=resolveArg(a) end end
    return out, (opt.args and #opt.args or 0)
end
local function runRequire(name,id,opt)
    if not ENV.HAS_REQ then notify("Claude Hub","require() unavailable on "..ENV.name,4); return end
    if not id then notify("Claude Hub","No asset ID",3); return end
    if type(opt)=="string" then opt={mode=opt} end
    opt = opt or {}
    -- legacy single-arg support
    if opt.arg~=nil and not opt.args then opt.args={opt.arg} end
    notify("Claude Hub","Loading "..name.."…",2)
    task.spawn(function()
        local args,n = buildArgs(opt)
        local ok2,res=pcall(function()
            local m=require(id)
            if opt.method then
                local fn=m[opt.method]
                if type(fn)~="function" then error("method '"..opt.method.."' not found") end
                if opt.colon then return fn(m,table.unpack(args,1,n)) end
                return fn(table.unpack(args,1,n))
            elseif opt.mode=="call" or n>0 then
                return m(table.unpack(args,1,n))
            else
                return m
            end
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

-- ── Server-side bridge (pairs with SS_Executor.lua's SS_ExecBridge) ───────────────
-- The bridge is a RemoteFunction in ReplicatedStorage. We invoke it with
-- (action, payload) and get back { ok=bool, msg=string, data=table? }.
local BRIDGE_NAME = "SS_ExecBridge"
local function getBridge()
    local b=RS:FindFirstChild(BRIDGE_NAME)
    if b and b:IsA("RemoteFunction") then return b end
    return nil
end
-- Synchronous bridge call; returns the response table (never throws).
local function callBridge(action,payload)
    local b=getBridge()
    if not b then return {ok=false,msg="Bridge not found — is SS_Executor running? ("..BRIDGE_NAME..")"} end
    local ok2,res=pcall(function() return b:InvokeServer(action,payload or {}) end)
    if not ok2 then return {ok=false,msg="Invoke failed: "..tostring(res)} end
    if type(res)~="table" then return {ok=false,msg="Unexpected response from bridge"} end
    return res
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

local minimized=false
local TBAR=Frm(WIN,UDim2.new(1,0,0,48),nil,C.SIDE,"TBAR"); grad(TBAR,C.SIDE,C.PANEL,90)
Frm(TBAR,UDim2.new(1,0,0,1),UDim2.new(0,0,1,-1),C.BORDER)        -- bottom hairline
-- logo (animated: spinning gradient + gentle pulse + breathing glyph)
local logo=Frm(TBAR,UDim2.new(0,28,0,28),UDim2.new(0,14,0.5,-14),C.ACCENT,"Logo"); corner(logo,8)
local logoGrad=grad(logo,C.ACCENT,C.ACC2,45)
local logoStk=stroke(logo,C.ACC2,1); logoStk.Transparency=0.4
local logoL=Lbl(logo,"C",UDim2.new(1,0,1,0),nil,C.WHITE,16,FB); logoL.TextXAlignment=Enum.TextXAlignment.Center
Lbl(TBAR,"Claude Hub",UDim2.new(0,160,1,0),UDim2.new(0,52,0,0),C.WHITE,15,FB)
-- drive logo animation continuously
task.spawn(function()
    local t=0
    while logo and logo.Parent do
        t=(t+0.04)%1
        logoGrad.Rotation=(logoGrad.Rotation+4)%360            -- spin the gradient
        local pulse=0.5+0.5*math.sin(t*math.pi*2)              -- 0..1 breathing
        logoStk.Transparency=0.25+0.45*pulse                   -- glow in/out
        local s=27+math.floor(2*pulse)                          -- subtle size pulse
        logo.Size=UDim2.new(0,s,0,s); logo.Position=UDim2.new(0,14+((28-s)/2),0.5,-s/2)
        task.wait(0.03)
    end
end)
-- bounce the glyph on hover of the whole title bar logo
do
    local hb=Instance.new("TextButton"); hb.Size=UDim2.new(1,0,1,0); hb.BackgroundTransparency=1; hb.Text=""; hb.Parent=logo
    hb.MouseButton1Click:Connect(function()
        logoL.Rotation=0; tw(logoL,{Rotation=360},TweenInfo.new(0.5,Enum.EasingStyle.Back))
        task.delay(0.5,function() logoL.Rotation=0 end)
    end)
end
-- executor chip (live dot + name + score)
local chipBg=Frm(TBAR,UDim2.new(0,210,0,28),UDim2.new(1,-300,0.5,-14),C.CARD,"Chip"); corner(chipBg,9); stroke(chipBg,C.BORDER,1)
local cdot=Frm(chipBg,UDim2.new(0,7,0,7),UDim2.new(0,11,0.5,-3.5),C.GREEN); corner(cdot,4)
Lbl(chipBg,ENV.name.."   ·   "..ENV.score.."/"..ENV.total.." APIs",UDim2.new(1,-26,1,0),UDim2.new(0,24,0,0),C.ACC2,11,FB)
-- window control buttons (minimize / close)
local function topBtn(xoff,glyph,hoverCol,cb)
    local b=Frm(TBAR,UDim2.new(0,28,0,28),UDim2.new(1,xoff,0.5,-14),C.PANEL,"TB"); corner(b,8); stroke(b,C.BORDER,1)
    local l=Lbl(b,glyph,UDim2.new(1,0,1,0),nil,C.TEXT,15,FB); l.TextXAlignment=Enum.TextXAlignment.Center
    local btn=Instance.new("TextButton"); btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1; btn.Text=""; btn.Parent=b
    btn.MouseEnter:Connect(function() tw(b,{BackgroundColor3=hoverCol}); tw(l,{TextColor3=C.WHITE}) end)
    btn.MouseLeave:Connect(function() tw(b,{BackgroundColor3=C.PANEL}); tw(l,{TextColor3=C.TEXT}) end)
    btn.MouseButton1Click:Connect(cb)
end
topBtn(-38,"✕",C.RED,function() tw(WIN,{Size=UDim2.new(0,672,0,0)},TweenInfo.new(0.18)); task.delay(0.2,function() SGI:Destroy() end) end)
topBtn(-72,"—",C.ACCENT,function() minimized=not minimized; tw(WIN,{Size=UDim2.new(0,672,0,minimized and 48 or 488)},TS2) end)

-- ── sidebar (search box + scrollable tab list) ───────────────────────────────────
local SIDEbg=Frm(WIN,UDim2.new(0,176,1,-48),UDim2.new(0,0,0,48),C.SIDE,"SIDEBG")
local searchWrap=Frm(SIDEbg,UDim2.new(1,-16,0,32),UDim2.new(0,8,0,8),C.PANEL,"Search"); corner(searchWrap,8); stroke(searchWrap,C.BORDER,1); pad(searchWrap,3,3,10,8)
local searchBox=Instance.new("TextBox")
searchBox.Size=UDim2.new(1,0,1,0); searchBox.BackgroundTransparency=1
searchBox.PlaceholderText="Search tabs…"; searchBox.PlaceholderColor3=C.MUTED; searchBox.Text=""
searchBox.TextColor3=C.WHITE; searchBox.TextSize=12; searchBox.Font=FN
searchBox.TextXAlignment=Enum.TextXAlignment.Left; searchBox.ClearTextOnFocus=false; searchBox.Parent=searchWrap
local SIDE=Instance.new("ScrollingFrame")
SIDE.Size=UDim2.new(1,0,1,-48); SIDE.Position=UDim2.new(0,0,0,48); SIDE.BackgroundTransparency=1; SIDE.BorderSizePixel=0
SIDE.ScrollBarThickness=2; SIDE.ScrollBarImageColor3=C.BORDER; SIDE.ScrollBarImageTransparency=0.3
SIDE.CanvasSize=UDim2.new(0,0,0,0); SIDE.AutomaticCanvasSize=Enum.AutomaticSize.Y; SIDE.Parent=SIDEbg
pad(SIDE,6,8,8,6); listV(SIDE,3)
local BODY=Frm(WIN,UDim2.new(1,-176,1,-48),UDim2.new(0,176,0,48),C.BG,"BODY")
Frm(WIN,UDim2.new(0,1,1,-48),UDim2.new(0,176,0,48),C.BORDER)

-- ── Tabs ───────────────────────────────────────────────────────────────────────
local pages,pageScroll,tabBtns={},{},{}; local curPage=1
local function showPage(n)
    for i,f in pairs(pages) do f.Visible=(i==n) end
    for i,b in pairs(tabBtns) do
        if i==n then
            tw(b.bg,{BackgroundColor3=C.CARD}); tw(b.bar,{BackgroundColor3=C.ACCENT,Size=UDim2.new(0,3,0.55,0)})
            tw(b.ico,{TextColor3=C.ACCENT}); tw(b.lbl,{TextColor3=C.WHITE})
            tw(b.stk,{Transparency=0})
        else
            tw(b.bg,{BackgroundColor3=C.SIDE}); tw(b.bar,{BackgroundColor3=C.SIDE,Size=UDim2.new(0,3,0,0)})
            tw(b.ico,{TextColor3=C.MUTED}); tw(b.lbl,{TextColor3=C.MUTED})
            tw(b.stk,{Transparency=1})
        end
    end
    -- subtle slide-in of the active page content (Rayfield-style)
    local sc=pageScroll[n]
    if sc then sc.Position=UDim2.new(0,8,0,16); tw(sc,{Position=UDim2.new(0,8,0,5)},TS2) end
    curPage=n
end
local function newTab(icon,name)
    local n=#pages+1
    local bg=Frm(SIDE,UDim2.new(1,0,0,40),nil,C.SIDE,"T"..n); corner(bg,9)
    local stk=stroke(bg,C.BORDER,1); stk.Transparency=1
    local bar=Frm(bg,UDim2.new(0,3,0,0),UDim2.new(0,0,0.225,0),C.SIDE); corner(bar,2)
    local ico=Lbl(bg,icon,UDim2.new(0,26,1,0),UDim2.new(0,10,0,0),C.MUTED,14,FB)
    local lbl=Lbl(bg,name,UDim2.new(1,-44,1,0),UDim2.new(0,40,0,0),C.MUTED,12,FC)
    local tb=Instance.new("TextButton")
    tb.Size=UDim2.new(1,0,1,0); tb.BackgroundTransparency=1; tb.Text=""; tb.Parent=bg
    tb.MouseButton1Click:Connect(function() showPage(n) end)
    tb.MouseEnter:Connect(function() if curPage~=n then tw(bg,{BackgroundColor3=C.PANEL}) end end)
    tb.MouseLeave:Connect(function() if curPage~=n then tw(bg,{BackgroundColor3=C.SIDE}) end end)
    tabBtns[n]={bg=bg,bar=bar,ico=ico,lbl=lbl,stk=stk,name=name}
    local page=Frm(BODY,UDim2.new(1,0,1,0),nil,C.BG,"P"..n); page.Visible=false; pages[n]=page
    local _,scroller=Scr(page,UDim2.new(1,-16,1,-10),UDim2.new(0,8,0,5))
    listV(scroller,7); pad(scroller,8,8,4,4)
    pageScroll[n]=scroller
    return scroller
end
-- live tab search filter
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local q=searchBox.Text:lower()
    for _,b in pairs(tabBtns) do
        b.bg.Visible = (q=="") or (string.find(b.name:lower(),q,1,true)~=nil)
    end
end)
local function SectionHdr(parent,txt)
    local h=Lbl(parent,txt,UDim2.new(1,0,0,18),nil,C.MUTED,11,FB)
    h.TextXAlignment=Enum.TextXAlignment.Left; return h
end
-- build a readable call signature string for an entry
local function fmtArg(a)
    if a=="@me" or a=="@user" then return "game.Players.LocalPlayer.Name" end
    if a=="@id" then return "game.Players.LocalPlayer.UserId" end
    if type(a)=="string" then return '"'..a..'"' end
    return tostring(a)
end
local function callSig(s)
    local parts={}
    local arglist = s.args or (s.arg~=nil and {s.arg}) or nil
    if arglist then for _,a in ipairs(arglist) do parts[#parts+1]=fmtArg(a) end end
    local argstr=table.concat(parts,", ")
    if s.method then
        local sep = s.colon and ":" or "."
        return "require("..tostring(s.id)..")"..sep..s.method.."("..argstr..")"
    elseif #parts>0 or s.mode=="call" then
        return "require("..tostring(s.id)..")("..argstr..")"
    end
    return "require("..tostring(s.id)..")"
end
local function ScriptCard(parent,s)
    local card=Frm(parent,UDim2.new(1,0,0,60),nil,C.CARD); corner(card,10); stroke(card,C.BORDER,1); pad(card,6,6,12,8)
    Lbl(card,s.name,UDim2.new(1,-96,0,18),nil,C.WHITE,13,FB)
    Lbl(card,(s.by and ("by "..s.by.."  ·  ") or "").."id "..tostring(s.id),
        UDim2.new(1,-96,0,14),UDim2.new(0,0,0,19),C.MUTED,11,FN)
    -- call signature (monospace)
    local sig=Lbl(card,callSig(s),UDim2.new(1,-96,0,13),UDim2.new(0,0,0,36),C.ACC2,10,FN)
    sig.Font=Enum.Font.RobotoMono; sig.TextTruncate=Enum.TextTruncate.AtEnd
    Btn(card,"Run",UDim2.new(0,80,0,34),UDim2.new(1,-84,0.5,-17),C.ACCENT,function()
        runRequire(s.name,s.id,{mode=s.mode,method=s.method,colon=s.colon,args=s.args,arg=s.arg})
    end)
    if ENV.HAS_CLIP then
        Btn(card,"Copy",UDim2.new(0,52,0,18),UDim2.new(1,-84,0,6),C.PANEL,function()
            ENV.setClip(callSig(s)); notify("Claude Hub","Call copied!",1)
        end)
    end
    return card
end
-- a search box that live-filters a set of cards by their entry name/key
local function CardSearch(parent,placeholder)
    local items={}    -- { {card=,text=}, ... }
    local wrap=Frm(parent,UDim2.new(1,0,0,36),nil,C.PANEL,"CardSearch"); corner(wrap,8); stroke(wrap,C.BORDER,1); pad(wrap,3,3,10,8)
    local ico=Lbl(wrap,"🔍",UDim2.new(0,18,1,0),UDim2.new(0,0,0,0),C.MUTED,13,FN)
    local tbx=Instance.new("TextBox")
    tbx.Size=UDim2.new(1,-22,1,0); tbx.Position=UDim2.new(0,22,0,0); tbx.BackgroundTransparency=1
    tbx.PlaceholderText=placeholder or "Search…"; tbx.PlaceholderColor3=C.MUTED; tbx.Text=""
    tbx.TextColor3=C.WHITE; tbx.TextSize=13; tbx.Font=FN
    tbx.TextXAlignment=Enum.TextXAlignment.Left; tbx.ClearTextOnFocus=false; tbx.Parent=wrap
    local count=Lbl(parent,"",UDim2.new(1,0,0,14),nil,C.MUTED,11,FN)
    tbx:GetPropertyChangedSignal("Text"):Connect(function()
        local q=tbx.Text:lower(); local shown=0
        for _,it in ipairs(items) do
            local vis=(q=="") or (string.find(it.text,q,1,true)~=nil)
            it.card.Visible=vis
            if vis then shown=shown+1 end
        end
        count.Text = q=="" and (#items.." total") or (shown.." match"..(shown==1 and "" or "es"))
    end)
    return function(card,text) table.insert(items,{card=card,text=tostring(text):lower()}); count.Text=#items.." total" end
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
--  TAB — EXECUTE  (paste any Lua, run it with loadstring)
-- ═══════════════════════════════════════════════════════════════════════════════
do
    local P=newTab("▶","Execute")
    SectionHdr(P,"■ SCRIPT EDITOR  ·  loadstring")

    -- big multiline code editor
    local edWrap=Frm(P,UDim2.new(1,0,0,210),nil,C.DARK); corner(edWrap,10); stroke(edWrap,C.BORDER,1); pad(edWrap,8,8,10,10)
    local editor=Instance.new("TextBox")
    editor.Size=UDim2.new(1,0,1,0); editor.BackgroundTransparency=1
    editor.MultiLine=true; editor.ClearTextOnFocus=false; editor.TextWrapped=false
    editor.TextXAlignment=Enum.TextXAlignment.Left; editor.TextYAlignment=Enum.TextYAlignment.Top
    editor.PlaceholderText='-- paste Lua here\nprint("hello from "..game.Players.LocalPlayer.Name)'
    editor.PlaceholderColor3=C.MUTED; editor.Text=""; editor.TextColor3=C.WHITE
    editor.TextSize=13; editor.Font=Enum.Font.RobotoMono; editor.Parent=edWrap

    -- output console
    local conWrap=Frm(P,UDim2.new(1,0,0,96),nil,C.DARK); corner(conWrap,8); stroke(conWrap,C.BORDER,1)
    local _,conScr=Scr(conWrap,UDim2.new(1,-6,1,-6),UDim2.new(0,3,0,3)); listV(conScr,1); pad(conScr,4,4,6,6)
    local function eout(line,col)
        local l=Instance.new("TextLabel")
        l.Size=UDim2.new(1,0,0,14); l.BackgroundTransparency=1; l.Text=line
        l.TextColor3=col or C.TEXT; l.TextSize=11; l.Font=Enum.Font.RobotoMono
        l.TextXAlignment=Enum.TextXAlignment.Left; l.TextWrapped=true
        l.AutomaticSize=Enum.AutomaticSize.Y; l.Parent=conScr
    end

    local function execute()
        local code=editor.Text
        if code=="" then notify("Claude Hub","Editor is empty",2); return end
        eout("→ executing ("..#code.." chars)…",C.MUTED)
        local fn,ce=loadstring(code)
        if not fn then eout("✗ compile: "..tostring(ce),C.RED); return end
        task.spawn(function()
            local ok2,e2=pcall(fn)
            if ok2 then eout("✓ executed OK",C.GREEN)
            else eout("✗ runtime: "..tostring(e2),C.RED) end
        end)
    end

    -- action row
    local row=Frm(P,UDim2.new(1,0,0,38),nil,C.BG)
    local h=Instance.new("UIListLayout"); h.FillDirection=Enum.FillDirection.Horizontal; h.Padding=UDim.new(0,6); h.Parent=row
    Btn(row,"▶  Execute",UDim2.new(0,150,1,0),nil,C.ACCENT,execute)
    Btn(row,"Clear Editor",UDim2.new(0,110,1,0),nil,C.PANEL,function() editor.Text="" end)
    Btn(row,"Clear Output",UDim2.new(0,110,1,0),nil,C.PANEL,function()
        for _,c in ipairs(conScr:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end
    end)
    if ENV.HAS_CLIP then
        Btn(row,"Paste",UDim2.new(0,80,1,0),nil,C.PANEL,function()
            local gc=(getclipboard or (ENV and nil))
            if getclipboard then local ok2,t=pcall(getclipboard); if ok2 and t then editor.Text=tostring(t) end
            else notify("Claude Hub","getclipboard not available",3) end
        end)
    end

    SectionHdr(P,"■ QUICK SNIPPETS")
    local snips={
        {t="Print your name", c='print(game.Players.LocalPlayer.Name)'},
        {t="List players",    c='for _,p in ipairs(game:GetService("Players"):GetPlayers()) do print(p.Name) end'},
        {t="WalkSpeed 100",   c='game.Players.LocalPlayer.Character.Humanoid.WalkSpeed=100'},
        {t="Infinite Yield",  c='loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()'},
    }
    for _,sn in ipairs(snips) do
        local card=Frm(P,UDim2.new(1,0,0,32),nil,C.CARD); corner(card,8); stroke(card,C.BORDER,1); pad(card,0,0,10,6)
        Lbl(card,sn.t,UDim2.new(1,-150,1,0),nil,C.TEXT,12,FC)
        Btn(card,"Load",UDim2.new(0,60,0,22),UDim2.new(1,-138,0.5,-11),C.PANEL,function() editor.Text=sn.c end)
        Btn(card,"Run",UDim2.new(0,60,0,22),UDim2.new(1,-72,0.5,-11),C.ACCENT,function() editor.Text=sn.c; execute() end)
    end

    eout("Ready. Paste Lua above and hit Execute.",C.MUTED)
    if not loadstring then
        eout("⚠ loadstring not available on "..ENV.name,C.YELLOW)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB — SERVER  (server-side execution via SS_ExecBridge)
-- ═══════════════════════════════════════════════════════════════════════════════
do
    local P=newTab("🖥","Server")

    -- status banner
    local ban=Frm(P,UDim2.new(1,0,0,46),nil,C.PANEL); corner(ban,10); stroke(ban,C.BORDER,1); pad(ban,0,0,12,12)
    local sdot=Frm(ban,UDim2.new(0,9,0,9),UDim2.new(0,2,0.5,-4.5),C.RED); corner(sdot,5)
    local statusL=Lbl(ban,"Bridge: checking…",UDim2.new(1,-20,1,0),UDim2.new(0,18,0,0),C.TEXT,12,FC)

    -- output console
    local function makeOut()
        local box=Frm(P,UDim2.new(1,0,0,120),nil,C.DARK); corner(box,8); stroke(box,C.BORDER,1)
        local _,sc=Scr(box,UDim2.new(1,-6,1,-6),UDim2.new(0,3,0,3)); listV(sc,1); pad(sc,4,4,6,6)
        return sc
    end
    local outLog
    local function out(line,col)
        if not outLog then return end
        local l=Instance.new("TextLabel")
        l.Size=UDim2.new(1,0,0,14); l.BackgroundTransparency=1
        l.Text=line; l.TextColor3=col or C.TEXT; l.TextSize=11
        l.Font=Enum.Font.RobotoMono; l.TextXAlignment=Enum.TextXAlignment.Left
        l.TextWrapped=true; l.AutomaticSize=Enum.AutomaticSize.Y; l.Parent=outLog
    end
    -- client-side fallbacks so every action still works with NO backdoor/bridge
    local function clientFallback(action,payload)
        payload=payload or {}
        if action=="ls" then
            local fn,ce=loadstring(payload.code or "")
            if not fn then return {ok=false,msg="Compile: "..tostring(ce)} end
            local ok2,e=pcall(fn)
            return ok2 and {ok=true,msg="Client loadstring OK (no bridge — ran locally)"}
                        or {ok=false,msg="Runtime: "..tostring(e)}
        elseif action=="req" then
            local ok2,e=pcall(require,tonumber(payload.id))
            return ok2 and {ok=true,msg="Client require OK (no bridge — ran locally)"}
                        or {ok=false,msg=tostring(e)}
        elseif action=="ls_url" then
            local body; local ok2=pcall(function() body=game:HttpGet(payload.url,true) end)
            if not body and ENV.httpReq then local o,r=pcall(ENV.httpReq,{Url=payload.url,Method="GET"}); if o and r then body=r.Body end end
            if not body then return {ok=false,msg="HTTP fetch failed"} end
            local fn,ce=loadstring(body); if not fn then return {ok=false,msg="Compile: "..tostring(ce)} end
            local ok3,e=pcall(fn)
            return ok3 and {ok=true,msg="Client URL exec OK (no bridge — ran locally)"}
                        or {ok=false,msg="Runtime: "..tostring(e)}
        elseif action=="getplrs" then
            local names={}
            for _,p in ipairs(Players:GetPlayers()) do table.insert(names,p.Name.." ("..p.UserId..")") end
            return {ok=true,msg=#names.." players (client view)",data=names}
        elseif action=="get_scripts" then
            local list={}
            for _,o in ipairs(game:GetDescendants()) do
                if o:IsA("LuaSourceContainer") then table.insert(list,o.ClassName.."|"..o:GetFullName()) end
                if #list>=300 then break end
            end
            return {ok=true,msg=#list.." scripts (client view, capped 300)",data=list}
        elseif action=="scan" then
            local sus={"backdoor","exploit","inject","cmd","execute","admin_bypass","btools","spy","hack","bypass"}
            local hits={}
            for _,o in ipairs(game:GetDescendants()) do
                if o:IsA("RemoteEvent") or o:IsA("RemoteFunction") then
                    local nl=o.Name:lower()
                    for _,kw in ipairs(sus) do if nl:find(kw,1,true) then table.insert(hits,o.ClassName.."|"..o:GetFullName()); break end end
                end
            end
            return {ok=true,msg=#hits.." suspicious remote(s) (client scan — source not readable client-side)",data=hits}
        end
        return {ok=false,msg="'"..action.."' needs the server bridge (no client equivalent)"}
    end
    -- run an action: prefer the server bridge, fall back to client if no bridge
    local function doBridge(action,payload,label)
        out("→ "..(label or action).."…",C.MUTED)
        task.spawn(function()
            local r
            if getBridge() then
                r=callBridge(action,payload)
            else
                out("   no bridge — using client-side fallback",C.YELLOW)
                r=clientFallback(action,payload)
            end
            out((r.ok and "✓ " or "✗ ")..tostring(r.msg), r.ok and C.GREEN or C.RED)
            if r.data then for _,d in ipairs(r.data) do out("   "..tostring(d),C.TEXT) end end
        end)
    end

    local function refreshStatus()
        local b=getBridge()
        if b then
            sdot.BackgroundColor3=C.YELLOW; statusL.Text="Bridge found — ping to confirm (server mode)"
        else
            sdot.BackgroundColor3=C.ACCENT; statusL.Text="No bridge — client-side mode (still works)"
        end
    end
    refreshStatus()

    SectionHdr(P,"■ CONNECTION")
    Btn(P,"⟳  Ping Bridge",UDim2.new(1,0,0,36),nil,C.ACCENT,function()
        refreshStatus()
        task.spawn(function()
            local r=callBridge("ping")
            if r.ok then
                sdot.BackgroundColor3=C.GREEN; statusL.Text="Bridge ONLINE ✓ (pong)"
                out("✓ pong — server bridge online",C.GREEN)
            else
                sdot.BackgroundColor3=C.RED; statusL.Text="Bridge offline"
                out("✗ "..tostring(r.msg),C.RED)
            end
        end)
    end)

    SectionHdr(P,"■ SERVER LOADSTRING")
    local _,codeBox=Inp(P,'Lua code  e.g.  print("hi from server")',UDim2.new(1,0,0,36))
    Btn(P,"▶  Run on Server  (action: ls)",UDim2.new(1,0,0,36),nil,C.ACCENT,function()
        if codeBox.Text=="" then notify("Claude Hub","Enter code",3); return end
        doBridge("ls",{code=codeBox.Text},"server loadstring")
    end)

    SectionHdr(P,"■ SERVER REQUIRE / URL")
    local _,sidBox=Inp(P,"Asset ID (server require)",UDim2.new(1,0,0,36))
    Btn(P,"▶  require(ID) on Server  (action: req)",UDim2.new(1,0,0,36),nil,C.PANEL,function()
        local id=tonumber(sidBox.Text); if not id then notify("Claude Hub","Numeric ID",3); return end
        doBridge("req",{id=id},"server require")
    end)
    local _,surlBox=Inp(P,"URL (server loadstring)",UDim2.new(1,0,0,36))
    Btn(P,"▶  loadstring(URL) on Server  (action: ls_url)",UDim2.new(1,0,0,36),nil,C.PANEL,function()
        if surlBox.Text=="" then notify("Claude Hub","Enter a URL",3); return end
        doBridge("ls_url",{url=surlBox.Text},"server URL exec")
    end)

    SectionHdr(P,"■ SERVER TOOLS")
    local row1=Frm(P,UDim2.new(1,0,0,36),nil,C.BG)
    local h1=Instance.new("UIListLayout"); h1.FillDirection=Enum.FillDirection.Horizontal
    h1.Padding=UDim.new(0,6); h1.Parent=row1
    Btn(row1,"Malware Scan",UDim2.new(0.5,-3,1,0),nil,C.PANEL,function() doBridge("scan",{},"scan") end)
    Btn(row1,"List Players",UDim2.new(0.5,-3,1,0),nil,C.PANEL,function() doBridge("getplrs",{},"player list") end)
    local row2=Frm(P,UDim2.new(1,0,0,36),nil,C.BG)
    local h2=Instance.new("UIListLayout"); h2.FillDirection=Enum.FillDirection.Horizontal
    h2.Padding=UDim.new(0,6); h2.Parent=row2
    Btn(row2,"List Scripts",UDim2.new(0.5,-3,1,0),nil,C.PANEL,function() doBridge("get_scripts",{},"script list") end)
    Btn(row2,"Kill All Malware",UDim2.new(0.5,-3,1,0),nil,C.RED,function() doBridge("kill_all",{},"kill all") end)

    SectionHdr(P,"■ OUTPUT")
    outLog=makeOut()
    out("Server console ready. Ping the bridge to begin.",C.MUTED)

    do
        local w=Frm(P,UDim2.new(1,0,0,48),nil,C.PANEL); corner(w,8); pad(w,6,6,10,10)
        Lbl(w,"If SS_Executor.lua is running (ReplicatedStorage."..BRIDGE_NAME.."),\nactions run on the SERVER. With NO backdoor, they automatically\nfall back to running CLIENT-SIDE — so this tab always works.",
            UDim2.new(1,0,1,0),nil,C.GREEN,10,FN)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  MONSTER MORPHS — require(ID).MorphMonster(LocalPlayer.Name, "<morph>")
--  Each card finds your username and morphs your character into the monster.
-- ═══════════════════════════════════════════════════════════════════════════════
local function morph(id, label, key)
    return {name=label, id=id, method="MorphMonster", args={"@me", key}}
end
local MORPHS = {
    morph(75834950186546, "Locust",                "locust"),
    morph(75834950186546, "Siren Head",            "sirenhead"),
    morph(75834950186546, "Siren Head 2",          "sirenhead2"),
    morph(75834950186546, "Cartoon Cat",           "cartoon cat"),
    morph(75834950186546, "Phen",                  "phen"),
    morph(75834950186546, "Guilt",                 "guilt"),
    morph(75834950186546, "Country Road Creature", "country road creature"),
    morph(75834950186546, "Dark Siren Head",       "dark siren head"),
    morph(77055143496081, "Shin Sonic",            "shin sonic"),
    morph(77055143496081, "Small Shin",            "small shin"),
    morph(77055143496081, "Sonic.EYX",             "sonic.eyx"),
    morph(125056408682835,"Cartoon Cat (v2)",      "cartoon cat"),
    morph(125056408682835,"Cartoon Mouse",         "cartoon mouse"),
    morph(125056408682835,"Cartoon Dog",           "cartoon dog"),
    morph(83656983108761, "Anxious Dog",           "anxious dog"),
    morph(83656983108761, "Bridge Worm",           "bridgeworm"),
    morph(135567062529977,"Hush",                  "hush"),
    morph(135567062529977,"Long Horse",            "long horse"),
    morph(119819780800418,"Organator",             "organator"),
    morph(88521859208314, "Death Angel",           "death angel"),
    morph(88521859208314, "Horror",                "horror"),
    morph(88521859208314, "Aka Manto",             "aka manto"),
    morph(87513953915554, "Bon the Rabbit",        "bontherabbit"),
    morph(87513953915554, "Pumpkin Rabbit",        "pumpkinrabbit"),
    morph(73755486018996, "Prototype",             "Prototype"),
    morph(92610899059557, "CatNap",                "catnap"),
    morph(138108464845575,"Huggy Wuggy",           "huggy wuggy"),
    morph(81801397159119, "Spider Queen",          "spider queen"),
    morph(109044049581210,"SCP-096 Reskin",        "scp096reskin"),
    morph(122588279096344,"Phen (v2)",             "phen"),
    morph(95084162409898, "The Extra Slide",       "the extra slide"),
    morph(71349190736743, "Traffic Light Head",    "trafficlight head"),
    morph(87137179673747, "Siren Head (v2)",       "sirenhead"),
    morph(120865255781665,"Suitborn",              "suitborn"),
    morph(125375466492613,"Richard Boderman",      "richard boderman"),
    morph(130962958730541,"Adult Mimic",           "adultmimic"),
}

-- ═══════════════════════════════════════════════════════════════════════════════
--  LOADERS — misc require loaders that take your username
-- ═══════════════════════════════════════════════════════════════════════════════
local LOADERS = {
    {name="Loader A",          id=77842202241216,  method="load",            args={"@me"}},
    {name="Loader B",          id=90312411619068,  method="load",            args={"@me"}},
    {name="Loader C",          id=90079465185110,  method="load",            args={"@me"}},
    {name="Loader D",          id=71205239813237,  method="Load",            args={"@me"}},
    {name="Loader E (colon)",  id=134034440311399, method="load", colon=true,args={"@me"}},
    {name="Test Loader",       id=89532600142550,  method="Test",            args={"@me"}},
    {name="American Demo",     id=111697793579923, method="americandemo",    args={"@me"}},
    {name="c00lgui6",          id=116847923485060, method="c00lgui6",        args={"@me"}},
    {name="Loader F (colon)",  id=137870571533698, method="load", colon=true,args={"@me"}},
    {name="Loader G",          id=124675875890869, method="load",            args={"@me"}},
    {name="Loader H",          id=73888902428931,  method="load",            args={"@me"}},
    {name="Direct Loader",     id=94673163261524,                            args={"@me"}},
    {name="Blu Dude",          id=74432860446268,  method="bluudude",        args={"@me"}},
    {name="Jason",             id=93565035610376,  method="jason",           args={"@me"}},
    {name="Sukuna",            id=89529616632600,                            args={"@me","Sukuna"}},
    {name="Loader I",          id=14268224146,     method="load",            args={"@me"}},
    {name="Player Loader",     id=5375399205,      method="Player",          args={"@me"}},
    {name="John",              id=80147538511861,  method="john",            args={"@me"}},
    {name="Immortality Lord",  id=6088383746,      method="inmportalitylord",args={"@me"}},
    {name="MC",                id=15581949972,     method="mc",              args={"@me"}},
}

-- ═══════════════════════════════════════════════════════════════════════════════
--  Bulk dataset — hundreds of entries, generated from name lists.
--  Each entry loads via require(ID).method("@me")  matching the featured format.
--  IDs are PLACEHOLDERS (deterministic) — replace with verified IDs.
-- ═══════════════════════════════════════════════════════════════════════════════
local _idBase = 130000000000000
local function gen(list, method, arg)
    local out={}
    for _,nm in ipairs(list) do
        _idBase = _idBase + 1357913   -- deterministic step
        out[#out+1] = {name=nm, id=_idBase, method=method, arg=arg}
    end
    return out
end

local CAT = {
 {icon="👹", name="Morphs",  custom=MORPHS},
 {icon="⭐", name="Loaders", custom=LOADERS},

 {icon="🌐", name="Universal", method="Load", arg="@me", list={
    "Infinite Yield","Dark Dex Explorer","Hydroxide Remote Spy","Simple Spy","Remote Spy v3",
    "Owl Hub","CMD-X Admin","Nameless Admin","Vynixu Admin","Basic Admin","Adonis Loader",
    "Universal Fly","Universal Noclip","Universal ESP","Universal Aimbot","Universal Teleport",
    "Anti-Kick","Anti-AFK","God Mode (FE)","Btools Giver","Click Teleport","Walk on Walls",
 }},
 {icon="🎯", name="Aimbot", method="Aim", arg="@me", list={
    "Universal Aimbot","Silent Aim","Camlock","Hitbox Expander","Aim Assist","Triggerbot",
    "Prediction Aim","Closest-to-cursor","FOV Aimbot","Wallbang Aim","No-Recoil","No-Spread",
    "Auto-Fire","Lock Head","Lock Torso","Smooth Aim","Snap Aim","Visibility Check",
 }},
 {icon="👁", name="ESP", method="ESP", arg="@me", list={
    "Universal ESP","Box ESP","Chams","Skeleton ESP","Tracers","Name ESP","Health ESP",
    "Distance ESP","Team ESP","Item ESP","Chest ESP","Vehicle ESP","NPC ESP","Headdot ESP",
    "Snaplines","Glow Outline","X-Ray","Radar / Minimap",
 }},
 {icon="🔫", name="FPS Games", method="Run", arg="@me", list={
    "Arsenal","Phantom Forces","Big Paintball","Bad Business","Counter Blox","Frontlines",
    "BlackHawk Rescue","War Tycoon","Rogue Lineage Combat","Energy Assault","Krunker Clone",
    "Zombie Strike","Aimblox","Strucid","Island Royale","Polyguns","Typical Colors 2",
    "Hardline","Hexagon","Innovation Arctic",
 }},
 {icon="🏗", name="Tycoons", method="Auto", arg="@me", list={
    "Retail Tycoon 2","Restaurant Tycoon 2","Theme Park Tycoon 2","Lumber Tycoon 2",
    "Clone Tycoon 2","Miner's Haven","Cash Grab Simulator","Two Player Military",
    "Super Hero Tycoon","Pizza Factory Tycoon","Snow Shoveling","Airport Tycoon",
    "School Tycoon","Mansion Tycoon","Gym Tycoon","Car Factory Tycoon",
 }},
 {icon="🌱", name="Simulators", method="Auto", arg="@me", list={
    "Pet Simulator 99","Pet Simulator X","Bee Swarm Simulator","Blox Fruits","Anime Fighting Sim",
    "Bubble Gum Simulator","Mining Simulator 2","Saber Simulator","Strongman Simulator",
    "Ninja Legends","Unboxing Simulator","Weight Lifting Sim","Fishing Simulator",
    "Treasure Quest","Dragon Adventures","World // Zero","Anime Adventures","All Star Tower Defense",
    "Sorcerer Fighting Sim","Speed Simulator X","Clicker Simulator","Tapping Legends",
 }},
 {icon="🔪", name="Murder/PvP", method="Run", arg="@me", list={
    "Murder Mystery 2","Survive the Killer","Knife Ability Test","Da Hood","The Streets",
    "Criminality","Dahood Modded","Rumble Quest","Blade Ball","Combat Warriors",
    "Sword Fights on Heights","Bloxy Bingo PvP","Critical Strike","Boxing Beta","Untitled Boxing",
 }},
 {icon="🏃", name="Obby/Parkour", method="Auto", arg="@me", list={
    "Tower of Hell","Speed Run 4","Mega Fun Obby","Escape Running Obby","Parkour",
    "Flood Escape 2","Be a Parkour Ninja","Tower of Misery","Steep Steps","Obby But You're on a Bike",
    "Rainbow Obby","Difficulty Chart Obby","Long Hard Obby","Wipeout Obby",
 }},
 {icon="🚗", name="Vehicle", method="Run", arg="@me", list={
    "Jailbreak","Mad City","Vehicle Legends","Car Dealership Tycoon","Driving Empire",
    "Ultimate Driving","Greenville","Vehicle Simulator","Roblox Drift","Southwest Florida",
    "Emergency Response LC","Car Crushers 2","A Dusty Trip","Pacifico 2",
 }},
 {icon="🎮", name="RP / Social", method="Run", arg="@me", list={
    "Adopt Me","Brookhaven RP","Bloxburg","Royale High","MeepCity","Livetopia",
    "Berry Avenue","Roville","Bloxburg Auto-Build","Robloxian High School","World of Stands",
    "Your Bizarre Adventure","Project Slayers","Demonfall","Anime Last Stand",
 }},
 {icon="😱", name="Horror", method="Run", arg="@me", list={
    "DOORS","Mimic","Apeirophobia","The Mimic Chapter","Pressure","Specter",
    "Survive the Night","Alone in a Dark House","Zombie Attack","Eyes the Horror Game",
    "Identity Fraud","Dead Silence","The Maze","Forsaken",
 }},
 {icon="🏆", name="Tower Defense", method="Auto", arg="@me", list={
    "Tower Defense Simulator","All Star Tower Defense","Anime Vanguards","Toilet Tower Defense",
    "Critical Legends TD","Ultimate Tower Defense","Kaiju Universe TD","Tower Battles",
    "Anime World Tower Defense","Astd Hub","Plants vs Brainrots",
 }},
 {icon="⛏", name="Survival", method="Run", arg="@me", list={
    "Booga Booga Reborn","Islands","Lumber Tycoon 2","The Wild West","Apocalypse Rising 2",
    "Westbound","DeadRails","A Dusty Trip","Stranded","Hunt: Showdown clone","Frostbite",
 }},
 {icon="🛠", name="Utility", method="Use", arg="@me", list={
    "FPS Booster","Anti-AFK","Server Hop","Player Logger","Fly + Noclip","Infinite Jump",
    "Speed + Gravity","Walkspeed Changer","Hitbox Expander","No-Clip Toggle","Click TP",
    "Freecam","Spectate","Chat Logger","Join-Log Webhook","Auto-Rejoin","Low-Graphics",
 }},
}

for _,t in ipairs(CAT) do
    local P=newTab(t.icon,t.name)
    local scripts = t.custom or gen(t.list, t.method, t.arg)
    SectionHdr(P,"■ "..string.upper(t.name).."  ·  "..#scripts.." require() scripts")
    -- per-tab search box (e.g. search the morph you want to be)
    local ph = (t.name=="Morphs") and "Search the morph you want to be…" or ("Search "..t.name.."…")
    local register=CardSearch(P,ph)
    for _,s in ipairs(scripts) do
        local card=ScriptCard(P,s)
        -- searchable text = display name + any string arguments (e.g. morph key)
        local txt=s.name
        if s.args then for _,a in ipairs(s.args) do if type(a)=="string" and a:sub(1,1)~="@" then txt=txt.." "..a end end end
        if s.method then txt=txt.." "..s.method end
        register(card,txt)
    end
    if not t.custom then
        local w=Frm(P,UDim2.new(1,0,0,26),nil,C.PANEL); corner(w,8); pad(w,0,0,10,10)
        Lbl(w,"IDs here are PLACEHOLDERS — paste verified IDs in Custom tab.",UDim2.new(1,0,1,0),nil,C.MUTED,10,FN)
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
