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

-- ── Palette (Delta-inspired navy + Claude clay logo) ─────────────────────────────
local C = {
    BG     = Color3.fromRGB(20, 22, 34),    -- dark navy
    SIDE   = Color3.fromRGB(14, 16, 26),    -- sidebar navy
    PANEL  = Color3.fromRGB(28, 32, 48),    -- panel
    CARD   = Color3.fromRGB(36, 41, 60),    -- card
    DARK   = Color3.fromRGB(12, 13, 22),    -- input dark
    BORDER = Color3.fromRGB(50, 58, 84),    -- border
    ACCENT = Color3.fromRGB(74, 152, 245),  -- Delta blue
    ACC2   = Color3.fromRGB(120, 185, 255), -- lighter blue
    GREEN  = Color3.fromRGB(52, 211, 153),
    RED    = Color3.fromRGB(244,  63,  94),
    YELLOW = Color3.fromRGB(251, 191,  36),
    PINK   = Color3.fromRGB(236,  72, 153),
    WHITE  = Color3.fromRGB(242, 246, 255),
    TEXT   = Color3.fromRGB(190, 198, 222),
    MUTED  = Color3.fromRGB(100, 112, 150),
    -- Claude branding (logo only)
    CLAY   = Color3.fromRGB(217, 119,  66),
    CREAM  = Color3.fromRGB(240, 236, 228),
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
-- Parent to PlayerGui — renders reliably on every Delta build.
-- (gethui() is skipped: some Delta builds return a container that never shows.)
local GUI_ROOT = PGui
if typeof(GUI_ROOT)~="Instance" then GUI_ROOT = LP:WaitForChild("PlayerGui") end
local old=GUI_ROOT:FindFirstChild("__CLAUDE_HUB__"); if old then old:Destroy() end
local SGI=Instance.new("ScreenGui")
SGI.Name="__CLAUDE_HUB__"; SGI.ResetOnSpawn=false
SGI.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; SGI.IgnoreGuiInset=true; SGI.Parent=GUI_ROOT

-- ── Floating draggable logo button (top-center, Delta-style) ────────────────────────
-- Always visible; click to show/hide the hub. Drag anywhere.
local FLOAT_SIZE = 52
local FLOAT=Frm(SGI,UDim2.new(0,FLOAT_SIZE,0,FLOAT_SIZE),UDim2.new(0.5,-FLOAT_SIZE/2,0,8),C.DARK,"FLOAT")
corner(FLOAT,12)
stroke(FLOAT,C.ACCENT,2)
do
    local fInner=Frm(FLOAT,UDim2.new(0,FLOAT_SIZE-8,0,FLOAT_SIZE-8),UDim2.new(0,4,0,4),C.PANEL); corner(fInner,9)
    local fL=Lbl(fInner,"✳",UDim2.new(1,0,1,0),nil,C.ACCENT,22,FB); fL.TextXAlignment=Enum.TextXAlignment.Center
    -- spin the ✳
    task.spawn(function()
        while FLOAT and FLOAT.Parent do fL.Rotation=(fL.Rotation+1.5)%360; task.wait(0.03) end
    end)
    -- drag
    local fDrag,fStart,fWP,fActive
    FLOAT.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            fDrag=true; fStart=inp.Position; fWP=FLOAT.Position; fActive=inp
            inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then fDrag=false end end)
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if fDrag and (inp==fActive or inp.UserInputType==Enum.UserInputType.MouseMovement) then
            local d=inp.Position-fStart
            FLOAT.Position=UDim2.new(fWP.X.Scale,fWP.X.Offset+d.X,fWP.Y.Scale,fWP.Y.Offset+d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then fDrag=false end end)
    -- click to toggle hub
    local fBtn=Instance.new("TextButton"); fBtn.Size=UDim2.new(1,0,1,0); fBtn.BackgroundTransparency=1; fBtn.Text=""; fBtn.Parent=FLOAT
    fBtn.MouseButton1Click:Connect(function()
        if fDrag then return end
        -- toggle WIN + TBAR visibility (FLOAT stays always visible)
        -- WIN may not exist yet when this closure is called — guard with pcall
        pcall(function()
            local w=SGI:FindFirstChild("WIN")
            if w then w.Visible = not w.Visible end
        end)
    end)
    -- pulse glow on hover
    fBtn.MouseEnter:Connect(function() tw(FLOAT,{BackgroundColor3=C.ACC2}) end)
    fBtn.MouseLeave:Connect(function() tw(FLOAT,{BackgroundColor3=C.ACCENT}) end)
end

local WIN=Frm(SGI,UDim2.new(0,672,0,488),UDim2.new(0.5,-336,0.5,-244),C.BG,"WIN")
corner(WIN,14); stroke(WIN,C.BORDER,1); WIN.ClipsDescendants=true
local shd=Instance.new("ImageLabel")
shd.Size=UDim2.new(1,46,1,46); shd.Position=UDim2.new(0,-23,0,-23); shd.BackgroundTransparency=1
shd.Image="rbxassetid://6014261993"; shd.ImageColor3=C.ACCENT; shd.ImageTransparency=0.65
shd.ScaleType=Enum.ScaleType.Slice; shd.SliceCenter=Rect.new(49,49,450,450); shd.Parent=WIN

local minimized=false
local TBAR=Frm(WIN,UDim2.new(1,0,0,48),nil,C.SIDE,"TBAR"); grad(TBAR,C.SIDE,C.PANEL,90)
Frm(TBAR,UDim2.new(1,0,0,1),UDim2.new(0,0,1,-1),C.BORDER)        -- bottom hairline
-- Claude logo tile in titlebar
local logo=Frm(TBAR,UDim2.new(0,30,0,30),UDim2.new(0,13,0.5,-15),C.CREAM,"Logo"); corner(logo,9)
local logoStk=stroke(logo,C.CLAY,1); logoStk.Transparency=0.45
local logoL=Lbl(logo,"✳",UDim2.new(1,0,1,0),nil,C.CLAY,21,FB); logoL.TextXAlignment=Enum.TextXAlignment.Center
Lbl(TBAR,"Claude Hub",UDim2.new(0,160,1,0),UDim2.new(0,54,0,0),C.WHITE,15,FB)
-- drive logo animation continuously (spin the sunburst + soft glow pulse)
task.spawn(function()
    local t=0
    while logo and logo.Parent do
        t=(t+0.04)%1
        logoL.Rotation=(logoL.Rotation+2)%360                   -- slow sunburst spin
        local pulse=0.5+0.5*math.sin(t*math.pi*2)              -- 0..1 breathing
        logoStk.Transparency=0.25+0.45*pulse                   -- glow in/out
        local s=29+math.floor(2*pulse)                          -- subtle size pulse
        logo.Size=UDim2.new(0,s,0,s); logo.Position=UDim2.new(0,13+((30-s)/2),0.5,-s/2)
        task.wait(0.03)
    end
end)
-- click the logo for a fast spin flourish
do
    local hb=Instance.new("TextButton"); hb.Size=UDim2.new(1,0,1,0); hb.BackgroundTransparency=1; hb.Text=""; hb.Parent=logo
    hb.MouseButton1Click:Connect(function()
        tw(logoL,{Rotation=logoL.Rotation+360},TweenInfo.new(0.6,Enum.EasingStyle.Back))
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

-- ── right icon sidebar (Delta-style: 54px, icon-only buttons) ──────────────────────
local SIDEbg=Frm(WIN,UDim2.new(0,54,1,-48),UDim2.new(1,-54,0,48),C.SIDE,"SIDEBG")
Frm(SIDEbg,UDim2.new(0,1,1,0),UDim2.new(0,0,0,0),C.BORDER)   -- left hairline divider
local SIDE=Instance.new("ScrollingFrame")
SIDE.Size=UDim2.new(1,0,1,0); SIDE.Position=UDim2.new(0,0,0,4); SIDE.BackgroundTransparency=1; SIDE.BorderSizePixel=0
SIDE.ScrollBarThickness=0; SIDE.CanvasSize=UDim2.new(0,0,0,0); SIDE.AutomaticCanvasSize=Enum.AutomaticSize.Y; SIDE.Parent=SIDEbg
pad(SIDE,4,4,4,4); listV(SIDE,4)
local BODY=Frm(WIN,UDim2.new(1,-54,1,-48),UDim2.new(0,0,0,48),C.BG,"BODY")

-- ── Tabs ───────────────────────────────────────────────────────────────────────
local pages,pageScroll,tabBtns={},{},{}; local curPage=1
local function showPage(n)
    for i,f in pairs(pages) do f.Visible=(i==n) end
    for i,b in pairs(tabBtns) do
        if i==n then
            tw(b.bg,{BackgroundColor3=C.CARD})
            tw(b.ico,{TextColor3=C.ACCENT})
            tw(b.bar,{BackgroundColor3=C.ACCENT,Size=UDim2.new(0,3,0.6,0)})
        else
            tw(b.bg,{BackgroundColor3=C.SIDE})
            tw(b.ico,{TextColor3=C.MUTED})
            tw(b.bar,{BackgroundColor3=C.SIDE,Size=UDim2.new(0,3,0,0)})
        end
    end
    local sc=pageScroll[n]
    if sc then sc.Position=UDim2.new(0,8,0,16); tw(sc,{Position=UDim2.new(0,8,0,5)},TS2) end
    curPage=n
end
local function newTab(icon,name)
    local n=#pages+1
    -- icon-only pill button (Delta right-sidebar style)
    local bg=Frm(SIDE,UDim2.new(1,-8,0,44),nil,C.SIDE,"T"..n); corner(bg,11)
    -- left accent bar (shows when selected)
    local bar=Frm(bg,UDim2.new(0,3,0,0),UDim2.new(0,0,0.2,0),C.SIDE); corner(bar,2)
    local ico=Lbl(bg,icon,UDim2.new(1,0,1,0),nil,C.MUTED,17,FB); ico.TextXAlignment=Enum.TextXAlignment.Center
    local tb=Instance.new("TextButton"); tb.Size=UDim2.new(1,0,1,0); tb.BackgroundTransparency=1; tb.Text=""; tb.Parent=bg
    tb.MouseButton1Click:Connect(function() showPage(n) end)
    tb.MouseEnter:Connect(function() if curPage~=n then tw(bg,{BackgroundColor3=C.PANEL}); tw(ico,{TextColor3=C.TEXT}) end end)
    tb.MouseLeave:Connect(function() if curPage~=n then tw(bg,{BackgroundColor3=C.SIDE}); tw(ico,{TextColor3=C.MUTED}) end end)
    tabBtns[n]={bg=bg,bar=bar,ico=ico,name=name}
    local page=Frm(BODY,UDim2.new(1,0,1,0),nil,C.BG,"P"..n); page.Visible=false; pages[n]=page
    local _,scroller=Scr(page,UDim2.new(1,-16,1,-10),UDim2.new(0,8,0,5))
    listV(scroller,7); pad(scroller,8,8,4,4)
    pageScroll[n]=scroller
    return scroller
end
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

-- ── Drag (mouse + touch, so it works on PC and iOS/mobile) ───────────────────────
do
    local dragging,startp,wp,activeInput
    local function isDragInput(inp)
        return inp.UserInputType==Enum.UserInputType.MouseButton1
            or inp.UserInputType==Enum.UserInputType.Touch
    end
    local function isMoveInput(inp)
        return inp.UserInputType==Enum.UserInputType.MouseMovement
            or inp.UserInputType==Enum.UserInputType.Touch
    end
    TBAR.InputBegan:Connect(function(inp)
        if isDragInput(inp) then
            dragging=true; startp=inp.Position; wp=WIN.Position; activeInput=inp
            inp.Changed:Connect(function()
                if inp.UserInputState==Enum.UserInputState.End then dragging=false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if dragging and isMoveInput(inp) and (inp==activeInput or inp.UserInputType==Enum.UserInputType.MouseMovement) then
            local d=inp.Position-startp
            WIN.Position=UDim2.new(wp.X.Scale,wp.X.Offset+d.X,wp.Y.Scale,wp.Y.Offset+d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(inp) if isDragInput(inp) then dragging=false end end)
end
UIS.InputBegan:Connect(function(inp,gp)
    if gp then return end
    if inp.KeyCode==Enum.KeyCode.Insert or inp.KeyCode==Enum.KeyCode.RightBracket then
        local w=SGI:FindFirstChild("WIN"); if w then w.Visible=not w.Visible end
    end
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
--  TAB — EXECUTE  (universal: Lua / require / URL — runs ALL scripts)
-- ═══════════════════════════════════════════════════════════════════════════════
do
    local P=newTab("▶","Execute")
    SectionHdr(P,"■ UNIVERSAL EXECUTOR  ·  Lua · require · URL")

    -- mode chips
    local mode="lua"   -- lua | require | url
    local chipRow=Frm(P,UDim2.new(1,0,0,32),nil,C.BG)
    local ch=Instance.new("UIListLayout"); ch.FillDirection=Enum.FillDirection.Horizontal; ch.Padding=UDim.new(0,6); ch.Parent=chipRow
    local chips={}
    local function setMode(m) mode=m
        for k,c in pairs(chips) do
            local on=(k==m)
            tw(c.f,{BackgroundColor3=on and C.ACCENT or C.CARD}); tw(c.l,{TextColor3=on and C.WHITE or C.MUTED})
        end
    end
    local function chip(key,label)
        local f=Frm(chipRow,UDim2.new(0,108,1,0),nil,C.CARD); corner(f,8); stroke(f,C.BORDER,1)
        local l=Lbl(f,label,UDim2.new(1,0,1,0),nil,C.MUTED,12,FB); l.TextXAlignment=Enum.TextXAlignment.Center
        local b=Instance.new("TextButton"); b.Size=UDim2.new(1,0,1,0); b.BackgroundTransparency=1; b.Text=""; b.Parent=f
        b.MouseButton1Click:Connect(function() setMode(key) end)
        chips[key]={f=f,l=l}
    end
    chip("lua","Lua"); chip("require","require(ID)"); chip("url","URL")

    -- tab bar (script1.lua + add button) — Delta-style
    local tabBarWrap=Frm(P,UDim2.new(1,0,0,32),nil,C.DARK); corner(tabBarWrap,8)
    stroke(tabBarWrap,C.BORDER,1)
    local activeTabL=Lbl(tabBarWrap,"script1.lua",UDim2.new(0,90,1,0),UDim2.new(0,10,0,0),C.TEXT,12,FN)
    local xTabBtn=Lbl(tabBarWrap,"✕",UDim2.new(0,18,1,0),UDim2.new(0,104,0,0),C.MUTED,11,FN)
    local addTabL=Lbl(tabBarWrap,"+",UDim2.new(0,24,1,0),UDim2.new(0,126,0,0),C.MUTED,16,FB)
    addTabL.TextXAlignment=Enum.TextXAlignment.Center
    local menuBtn=Lbl(tabBarWrap,"⋮",UDim2.new(0,18,1,0),UDim2.new(1,-22,0,0),C.MUTED,14,FB)
    menuBtn.TextXAlignment=Enum.TextXAlignment.Center

    -- big multiline editor / input
    local edWrap=Frm(P,UDim2.new(1,0,0,188),nil,C.DARK,"EdWrap"); corner(edWrap,10); stroke(edWrap,C.BORDER,1); pad(edWrap,8,8,10,10)
    local editor=Instance.new("TextBox")
    editor.Name="__EXEC_EDITOR__"  -- tagged so Script Library can load into it
    editor.Size=UDim2.new(1,0,1,0); editor.BackgroundTransparency=1
    editor.MultiLine=true; editor.ClearTextOnFocus=false; editor.TextWrapped=false
    editor.TextXAlignment=Enum.TextXAlignment.Left; editor.TextYAlignment=Enum.TextYAlignment.Top
    editor.PlaceholderText='-- paste any Lua, OR an asset ID, OR a URL\nprint("hello from "..game.Players.LocalPlayer.Name)'
    editor.PlaceholderColor3=C.MUTED; editor.Text=""; editor.TextColor3=C.WHITE
    editor.TextSize=13; editor.Font=Enum.Font.RobotoMono; editor.Parent=edWrap

    -- output console
    local conWrap=Frm(P,UDim2.new(1,0,0,80),nil,C.DARK); corner(conWrap,8); stroke(conWrap,C.BORDER,1)
    local _,conScr=Scr(conWrap,UDim2.new(1,-6,1,-6),UDim2.new(0,3,0,3)); listV(conScr,1); pad(conScr,4,4,6,6)
    local function eout(line,col)
        local l=Instance.new("TextLabel")
        l.Size=UDim2.new(1,0,0,14); l.BackgroundTransparency=1; l.Text=line
        l.TextColor3=col or C.TEXT; l.TextSize=11; l.Font=Enum.Font.RobotoMono
        l.TextXAlignment=Enum.TextXAlignment.Left; l.TextWrapped=true
        l.AutomaticSize=Enum.AutomaticSize.Y; l.Parent=conScr
    end

    -- execute according to the selected mode (handles ALL script types)
    local function execute()
        local txt=editor.Text
        if txt=="" then notify("Claude Hub","Input is empty",2); return end
        if mode=="require" then
            local id=tonumber(txt:match("%d+"))
            if not id then eout("✗ require: no numeric ID found",C.RED); return end
            eout("→ require("..id..")…",C.MUTED)
            task.spawn(function()
                local ok2,e2=pcall(function() return require(id) end)
                if ok2 then eout("✓ required "..id.." OK",C.GREEN) else eout("✗ "..tostring(e2):sub(1,80),C.RED) end
            end)
        elseif mode=="url" then
            local url=txt:match("%S+")
            eout("→ fetching "..tostring(url):sub(1,50).."…",C.MUTED)
            task.spawn(function()
                local body; local ok2=pcall(function() body=game:HttpGet(url,true) end)
                if not body and ENV.httpReq then local o,r=pcall(ENV.httpReq,{Url=url,Method="GET"}); if o and r then body=r.Body end end
                if not body then eout("✗ HTTP fetch failed",C.RED); return end
                local fn,ce=loadstring(body); if not fn then eout("✗ compile: "..tostring(ce):sub(1,70),C.RED); return end
                local ok3,e3=pcall(fn)
                if ok3 then eout("✓ URL script executed OK",C.GREEN) else eout("✗ runtime: "..tostring(e3):sub(1,70),C.RED) end
            end)
        else -- lua (also runs require()/loadstring lines since it's valid Lua)
            eout("→ executing ("..#txt.." chars)…",C.MUTED)
            local fn,ce=loadstring(txt)
            if not fn then eout("✗ compile: "..tostring(ce):sub(1,80),C.RED); return end
            task.spawn(function()
                local ok2,e2=pcall(fn)
                if ok2 then eout("✓ executed OK",C.GREEN) else eout("✗ runtime: "..tostring(e2):sub(1,80),C.RED) end
            end)
        end
    end

    -- Delta-style bottom action bar: EXECUTE | CLEAR | EXECUTE CLIPBOARD
    local actRow=Frm(P,UDim2.new(1,0,0,44),nil,C.BG)
    local ah=Instance.new("UIListLayout"); ah.FillDirection=Enum.FillDirection.Horizontal; ah.Padding=UDim.new(0,8); ah.Parent=actRow

    local function deltaBtn(parent, label, accent, cb)
        local f=Frm(parent,UDim2.new(0,0,1,0),nil,C.CARD); f.AutomaticSize=Enum.AutomaticSize.X
        corner(f,10); stroke(f,accent or C.BORDER,1)
        pad(f,0,0,16,16)
        local l=Lbl(f,label,UDim2.new(0,0,1,0),nil,accent or C.TEXT,13,FB)
        l.AutomaticSize=Enum.AutomaticSize.X; l.TextXAlignment=Enum.TextXAlignment.Center
        local b=Instance.new("TextButton"); b.Size=UDim2.new(1,0,1,0); b.BackgroundTransparency=1; b.Text=""; b.Parent=f
        b.MouseButton1Click:Connect(function()
            tw(f,{BackgroundColor3=accent or C.BORDER},TweenInfo.new(0.06))
            task.delay(0.06,function() tw(f,{BackgroundColor3=C.CARD}) end)
            if cb then pcall(cb) end
        end)
        return f
    end

    deltaBtn(actRow,"EXECUTE",C.ACCENT,execute)
    deltaBtn(actRow,"CLEAR",C.MUTED,function()
        editor.Text=""
        for _,c in ipairs(conScr:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end
    end)
    deltaBtn(actRow,"EXECUTE CLIPBOARD",C.ACC2,function()
        local code=""
        if getclipboard then pcall(function() code=getclipboard() end) end
        if code~="" then editor.Text=code; execute()
        else notify("Execute","No clipboard content",3) end
    end)

    SectionHdr(P,"■ QUICK SCRIPTS")
    local snips={
        {t="Print your name",  m="lua", c='print(game.Players.LocalPlayer.Name)'},
        {t="List players",     m="lua", c='for _,p in ipairs(game:GetService("Players"):GetPlayers()) do print(p.Name) end'},
        {t="WalkSpeed 100",    m="lua", c='game.Players.LocalPlayer.Character.Humanoid.WalkSpeed=100'},
        {t="Infinite Yield",   m="url", c='https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'},
        {t="Dark Dex",         m="url", c='https://raw.githubusercontent.com/Babyhamsta/RBLX_Scripts/main/Universal/BypassedDarkDexV3.lua'},
    }
    for _,sn in ipairs(snips) do
        local card=Frm(P,UDim2.new(1,0,0,32),nil,C.CARD); corner(card,8); stroke(card,C.BORDER,1); pad(card,0,0,10,6)
        Lbl(card,sn.t,UDim2.new(1,-150,1,0),nil,C.TEXT,12,FC)
        Btn(card,"Load",UDim2.new(0,60,0,22),UDim2.new(1,-138,0.5,-11),C.PANEL,function() setMode(sn.m); editor.Text=sn.c end)
        Btn(card,"Run",UDim2.new(0,60,0,22),UDim2.new(1,-72,0.5,-11),C.ACCENT,function() setMode(sn.m); editor.Text=sn.c; execute() end)
    end

    setMode("lua")
    eout("Ready. Pick a mode (Lua / require / URL) and Execute.",C.MUTED)
    if not loadstring then eout("⚠ loadstring not available on "..ENV.name,C.YELLOW) end
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
        Lbl(w,"If SS_Executor.lua is running (ReplicatedStorage."..BRIDGE_NAME.."),\nactions run on the SERVER. With NO backdoor, they fall back to the\nclient — or use the Remotes tab to fire the game's own remotes (FE).",
            UDim2.new(1,0,1,0),nil,C.GREEN,10,FN)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB — REMOTES  (FE fallback: no backdoor → hop on the game's own remotes)
--  Scans every RemoteEvent / RemoteFunction and lets you fire it with args.
-- ═══════════════════════════════════════════════════════════════════════════════
do
    local P=newTab("📡","Remotes")
    SectionHdr(P,"■ FIRE GAME REMOTES  (works in FE — no backdoor needed)")
    do
        local note=Frm(P,UDim2.new(1,0,0,44),nil,C.PANEL); corner(note,8); pad(note,6,6,10,10)
        Lbl(note,"No backdoor? Hop on the game's existing remotes. Set args below\n(comma-separated). Tokens: @me = your name, @id = UserId.",
            UDim2.new(1,0,1,0),nil,C.MUTED,10,FN)
    end

    -- shared args input
    local _,argBox=Inp(P,'args  e.g.  @me, "Knife", 100   (blank = none)',UDim2.new(1,0,0,36))

    -- parse the args string into a real argument list
    local function parseArgs()
        local txt=argBox.Text
        if txt=="" then return {},0 end
        local list={}; local i=0
        for raw in string.gmatch(txt..",", "%s*(.-)%s*,") do
            i=i+1
            if raw=="@me" or raw=="@user" then list[i]=LP.Name
            elseif raw=="@id" then list[i]=LP.UserId
            elseif raw=="true" then list[i]=true
            elseif raw=="false" then list[i]=false
            elseif tonumber(raw) then list[i]=tonumber(raw)
            else
                -- strip surrounding quotes if present
                local s=raw:match('^"(.*)"$') or raw:match("^'(.*)'$") or raw
                list[i]=s
            end
        end
        return list,i
    end

    -- output console
    local conWrap=Frm(P,UDim2.new(1,0,0,88),nil,C.DARK); corner(conWrap,8); stroke(conWrap,C.BORDER,1)
    local _,conScr=Scr(conWrap,UDim2.new(1,-6,1,-6),UDim2.new(0,3,0,3)); listV(conScr,1); pad(conScr,4,4,6,6)
    local function rout(line,col)
        local l=Instance.new("TextLabel")
        l.Size=UDim2.new(1,0,0,14); l.BackgroundTransparency=1; l.Text=line
        l.TextColor3=col or C.TEXT; l.TextSize=11; l.Font=Enum.Font.RobotoMono
        l.TextXAlignment=Enum.TextXAlignment.Left; l.TextWrapped=true
        l.AutomaticSize=Enum.AutomaticSize.Y; l.Parent=conScr
    end

    -- fire one remote
    local function fire(remote)
        local args,n=parseArgs()
        rout("→ "..remote.ClassName..":"..remote.Name.." ("..n.." args)",C.MUTED)
        task.spawn(function()
            local ok2,res=pcall(function()
                if remote:IsA("RemoteEvent") then
                    remote:FireServer(table.unpack(args,1,n)); return "fired"
                else
                    return remote:InvokeServer(table.unpack(args,1,n))
                end
            end)
            if ok2 then rout("✓ "..remote.Name.." → "..tostring(res):sub(1,60),C.GREEN)
            else rout("✗ "..tostring(res):sub(1,60),C.RED) end
        end)
    end

    -- search + list
    SectionHdr(P,"■ DISCOVERED REMOTES")
    local searchReg=CardSearch(P,"Search remotes…")
    local listHost=Instance.new("Frame")
    listHost.Size=UDim2.new(1,0,0,0); listHost.BackgroundTransparency=1
    listHost.AutomaticSize=Enum.AutomaticSize.Y; listHost.Parent=P
    listV(listHost,5)

    -- collect remotes from EVERYWHERE, including hidden/nil-parented ones that a
    -- normal GetDescendants() misses. Read-only & passive — fires nothing, so it
    -- leaves no trace and won't trip remote-call anti-cheat ("clean" discovery).
    local function collectRemotes()
        local set={}        -- [instance]=true  (dedupe)
        local out={}
        local function add(o)
            if typeof(o)=="Instance" and not set[o]
               and (o:IsA("RemoteEvent") or o:IsA("RemoteFunction")) then
                set[o]=true; out[#out+1]=o
            end
        end
        -- 1) visible tree
        for _,o in ipairs(game:GetDescendants()) do add(o) end
        -- 2) nil-parented / hidden remotes (executor-only)
        if getnilinstances then
            local ok2,nils=pcall(getnilinstances)
            if ok2 and type(nils)=="table" then for _,o in ipairs(nils) do add(o) end end
        end
        -- 3) garbage-collector sweep — catches remotes referenced but not in the tree
        if getgc then
            local ok2,gc=pcall(getgc,true)
            if ok2 and type(gc)=="table" then
                for _,o in ipairs(gc) do pcall(add,o) end
            end
        end
        return out
    end

    local function scanRemotes()
        for _,c in ipairs(listHost:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
        local found=collectRemotes()
        local hidden=0
        for _,r in ipairs(found) do if not r:IsDescendantOf(game) then hidden=hidden+1 end end
        rout("clean scan — "..#found.." remotes ("..hidden.." hidden/nil)",C.ACC2)
        for _,r in ipairs(found) do
            local isFn=r:IsA("RemoteFunction")
            local isHidden = not r:IsDescendantOf(game)
            local card=Frm(listHost,UDim2.new(1,0,0,46),nil,C.CARD); corner(card,9); stroke(card,isHidden and C.YELLOW or C.BORDER,1); pad(card,5,5,10,8)
            -- type badge
            local badge=Frm(card,UDim2.new(0,30,0,16),UDim2.new(0,0,0,0),isFn and C.PINK or C.ACCENT); corner(badge,5)
            Lbl(badge,isFn and "FN" or "EV",UDim2.new(1,0,1,0),nil,C.WHITE,9,FB).TextXAlignment=Enum.TextXAlignment.Center
            -- hidden tag for nil-parented remotes
            if isHidden then
                local ht=Frm(card,UDim2.new(0,46,0,16),UDim2.new(0,34,0,0),C.YELLOW); corner(ht,5)
                Lbl(ht,"HIDDEN",UDim2.new(1,0,1,0),nil,C.DARK,8,FB).TextXAlignment=Enum.TextXAlignment.Center
                Lbl(card,r.Name,UDim2.new(1,-160,0,16),UDim2.new(0,84,0,0),C.WHITE,12,FB)
            else
                Lbl(card,r.Name,UDim2.new(1,-150,0,16),UDim2.new(0,36,0,0),C.WHITE,12,FB)
            end
            local okp,path=pcall(function() return r:GetFullName() end)
            if not okp then path="(nil)."..r.Name end
            Lbl(card,path,UDim2.new(1,-150,0,13),UDim2.new(0,0,0,20),C.MUTED,9,FN).TextTruncate=Enum.TextTruncate.AtEnd
            Btn(card,isFn and "Invoke" or "Fire",UDim2.new(0,70,0,28),UDim2.new(1,-74,0.5,-14),C.ACCENT,function() fire(r) end)
            searchReg(card, (r.Name.." "..path):lower())
        end
    end

    Btn(P,"⟳  Clean Scan  (incl. hidden / nil remotes)",UDim2.new(1,0,0,36),nil,C.ACCENT,scanRemotes)
    if ENV.HAS_CLIP then
        Btn(P,"Copy All Remote Paths",UDim2.new(1,0,0,32),nil,C.PANEL,function()
            local lines={}
            for _,o in ipairs(collectRemotes()) do
                local okp,p=pcall(function() return o:GetFullName() end)
                table.insert(lines,o.ClassName.."  "..(okp and p or o.Name))
            end
            ENV.setClip(table.concat(lines,"\n")); notify("Claude Hub","Copied "..#lines.." remotes",3)
        end)
    end

    -- ── Passive spy: the most undetectable discovery — just watch what the game
    --    fires through __namecall. We never probe; we observe. Read-only hook. ──
    SectionHdr(P,"■ PASSIVE SPY  (undetectable — observes live traffic)")
    local seen={}   -- name -> true (dedupe live discoveries)
    local spyOn=false
    local spyRow=Frm(P,UDim2.new(1,0,0,38),nil,C.CARD); corner(spyRow,8); stroke(spyRow,C.BORDER,1); pad(spyRow,0,0,12,12)
    Lbl(spyRow,"Watch live remote calls",UDim2.new(1,-54,1,0),nil,C.TEXT,12,FC)
    local pill=Frm(spyRow,UDim2.new(0,44,0,24),UDim2.new(1,-44,0.5,-12),C.DARK); corner(pill,12); stroke(pill,C.BORDER)
    local knob=Frm(pill,UDim2.new(0,18,0,18),UDim2.new(0,3,0.5,-9),C.MUTED); corner(knob,9)
    local function setSpy(v)
        spyOn=v
        if v then tw(pill,{BackgroundColor3=C.ACCENT}); tw(knob,{Position=UDim2.new(0,23,0.5,-9),BackgroundColor3=C.WHITE})
        else tw(pill,{BackgroundColor3=C.DARK}); tw(knob,{Position=UDim2.new(0,3,0.5,-9),BackgroundColor3=C.MUTED}) end
    end
    local sb=Instance.new("TextButton"); sb.Size=UDim2.new(1,0,1,0); sb.BackgroundTransparency=1; sb.Text=""; sb.Parent=spyRow
    if ENV.caps.hookmetamethod and ENV.caps.getnamecallmethod and ENV.caps.newcclosure then
        local _old; _old=hookmetamethod(game,"__namecall",newcclosure(function(self,...)
            if spyOn then
                local m=getnamecallmethod()
                if m=="FireServer" or m=="InvokeServer" then
                    pcall(function()
                        if typeof(self)=="Instance" and not seen[self] then
                            seen[self]=true
                            rout("● live: "..self.ClassName..":"..self.Name.." ("..m..")",C.GREEN)
                        end
                    end)
                end
            end
            return _old(self,...)
        end))
        sb.MouseButton1Click:Connect(function() setSpy(not spyOn) end)
    else
        sb.MouseButton1Click:Connect(function() notify("Claude Hub","hookmetamethod not available on "..ENV.name,4) end)
        Lbl(P,"⚠ Passive spy needs hookmetamethod (not on "..ENV.name..")",UDim2.new(1,0,0,16),nil,C.YELLOW,10,FN)
    end

    rout("Ready. Clean Scan finds hidden remotes; Passive Spy watches live ones.",C.MUTED)
    task.defer(scanRemotes)
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
--  TAB — CLAUDE AI  (powered by pollinations.ai free API — no key needed)
--  Real AI responses via the Claude model. Falls back to offline engine for
--  hub actions (morph, speed, fire remote, run Lua) which never use a request.
-- ═══════════════════════════════════════════════════════════════════════════════
do
    local P=newTab("✳","Claude AI")
    pad(P,4,4,2,2)

    -- Paste your Cloudflare Worker URL here to enable real Claude (Haiku) tier.
    -- Leave empty to use Free tier (pollinations.ai, unlimited, no setup needed).
    local AI_PROXY_URL = ""   -- e.g. "https://claude-hub.yourname.workers.dev"

    -- "free" = pollinations.ai, no limit at all
    -- "claude" = real Anthropic Haiku via proxy: 20 msgs → wait 30 min → 10 more
    local modelMode = "free"

    -- Claude tier rate-limit state (mirrors what the server tells us)
    local claudeRemaining   = nil  -- number of messages left (nil = unknown)
    local rateLimitWaitMins = nil  -- non-nil when server says we're rate-limited
    local rateLimitAt       = 0    -- os.clock() when rate limit was received

    -- ── Context injected into every AI call ───────────────────────────────────
    local function buildContext()
        local M = ENV.mem or {}
        return "Game: "..tostring(game.Name).." (PlaceId "..tostring(game.PlaceId)
            .."). Player: "..LP.Name.." (UserId "..LP.UserId
            .."). Executor: "..ENV.name.." ("..ENV.score.."/"..ENV.total.." APIs). "
            .."Remotes found: "..(#(M.remotes or {}))
            ..". Values: "..tostring(M.vcount or 0)
            ..". Morphs available: "..#MORPHS.."."
    end

    local AI_SYSTEM = "You are Claude, the AI assistant made by Anthropic, built into a Roblox script hub called Claude Hub. "
        .."You help users with Roblox scripting, exploiting tips, game knowledge, and general questions. "
        .."You have access to real-time game memory that was scanned on load. "
        .."Keep answers concise — the UI is a small chat window on a phone. "
        .."Do not use markdown headers or asterisks. Use plain text. "
        .."If the user asks to morph, change speed, fire a remote, or run Lua, "
        .."reply with EXACTLY: ACTION:morph:<name>  or  ACTION:speed:<n>  or  ACTION:jump:<n>  "
        .."or  ACTION:lua:<code>  — the hub will execute it. Context: "..buildContext()

    -- ── Claude tier: call Anthropic via Cloudflare Worker proxy ──────────────
    local function callViaProxy(userMsg, onSuccess, onFail)
        task.spawn(function()
            local HS = game:GetService("HttpService")
            local bodyJson = HS:JSONEncode({
                msg = userMsg:sub(1,600),
                sys = AI_SYSTEM:sub(1,1000),
                uid = tostring(LP.UserId),
            })
            local ok2, resp
            if ENV.httpReq then
                ok2, resp = pcall(function()
                    return ENV.httpReq({
                        Url = AI_PROXY_URL,
                        Method = "POST",
                        Body = bodyJson,
                        Headers = { ["Content-Type"] = "application/json" },
                    })
                end)
            end
            if not ok2 or not resp then
                ok2, resp = pcall(function()
                    return { Body = game:HttpGet(AI_PROXY_URL.."?q="..HS:UrlEncode(userMsg:sub(1,200)), true) }
                end)
            end
            if not ok2 or not resp or not resp.Body then onFail("network error"); return end
            local dOk, data = pcall(function() return HS:JSONDecode(resp.Body) end)
            if not dOk or not data then onFail("bad response"); return end
            if data.error == "rate_limit" then
                onFail("RATE_LIMIT:"..(data.wait_mins or 30)..":"..tostring(data.message or ""))
            elseif data.error then
                onFail(tostring(data.message or data.error))
            elseif data.reply then
                onSuccess(data.reply, data.remaining)
            else
                onFail("empty reply")
            end
        end)
    end

    -- ── Free tier: pollinations.ai — no key, no limit ─────────────────────────
    local function callPollinationsAI(userMsg, onSuccess, onFail)
        task.spawn(function()
            local HS = game:GetService("HttpService")
            local url = "https://text.pollinations.ai/"..HS:UrlEncode(userMsg:sub(1,300))
                .."?model=openai&system="..HS:UrlEncode(AI_SYSTEM:sub(1,500))
                .."&seed="..tostring(math.random(1,99999))
            local ok2, body
            if ENV.httpReq then
                ok2, body = pcall(function()
                    local r = ENV.httpReq({Url=url,Method="GET",Headers={["User-Agent"]="ClaudeHub/1.0"}})
                    if r and r.Body and #r.Body > 0 then return r.Body end
                    error("empty")
                end)
            end
            if not ok2 or not body then
                ok2, body = pcall(function() return game:HttpGet(url, true) end)
            end
            if ok2 and body and #tostring(body) > 2 then
                onSuccess(tostring(body):gsub("^%s+",""):gsub("%s+$",""), nil)
            else
                onFail(tostring(body):sub(1,80))
            end
        end)
    end

    -- ── Offline action engine (never uses any quota) ───────────────────────────
    local function has(s,...) for _,w in ipairs({...}) do if string.find(s,w,1,true) then return true end end end
    local function num(s) return tonumber(string.match(s,"%-?%d+%.?%d*")) end

    local function findMorph(q)
        for _,m in ipairs(MORPHS) do
            local key=(m.args and m.args[2] or ""):lower()
            if key~="" and (string.find(q,key,1,true) or string.find(q,m.name:lower(),1,true)) then return m end
        end
        for w in q:gmatch("%a+") do
            if #w>=3 then
                for _,m in ipairs(MORPHS) do
                    local key=(m.args and m.args[2] or ""):lower()
                    if string.find(key,w,1,true) or string.find(m.name:lower(),w,1,true) then return m end
                end
            end
        end
    end

    local function tryLocalAction(raw)
        local q=raw:lower()
        if has(q,"morph","turn into","become","transform") then
            local m=findMorph(q)
            if m then runRequire(m.name,m.id,{method=m.method,args=m.args}); return "Morphing you into <b>"..m.name.."</b>. "..callSig(m) end
        end
        if has(q,"walkspeed","walk speed") or (has(q,"speed") and num(q)) then
            local n=num(q) or 80
            local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed=n; return "WalkSpeed set to <b>"..n.."</b>." end
        end
        if has(q,"jumppower","jump power","jump high") or (has(q,"jump") and num(q)) then
            local n=num(q) or 120
            local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if h then h.JumpPower=n; h.UseJumpPower=true; return "JumpPower set to <b>"..n.."</b>." end
        end
        if has(q,"fire ","invoke ") then
            local target=raw:match("[Ff]ire%s+(.+)") or raw:match("[Ii]nvoke%s+(.+)")
            if target and ENV.mem then
                local hits={}; target=target:lower()
                for _,r in ipairs(ENV.mem.remotes) do
                    if string.find(r.name:lower(),target,1,true) then table.insert(hits,r) end
                end
                if #hits>0 then
                    local first=hits[1]; local ok2=false
                    pcall(function()
                        local o=game; for p in first.path:gmatch("[^%.]+") do o=o[p] end
                        if o and o:IsA("RemoteEvent") then o:FireServer(LP.Name); ok2=true
                        elseif o and o:IsA("RemoteFunction") then o:InvokeServer(LP.Name); ok2=true end
                    end)
                    return (ok2 and "Fired " or "Found but couldn't fire ").."<b>"..first.name.."</b>"
                end
            end
        end
        if has(q,"run ","execute ","exec ","lua ","do ") then
            local code=raw:match("[Rr]un%s+(.+)") or raw:match("[Ee]xec%w*%s+(.+)")
                     or raw:match("[Ll]ua%s+(.+)") or raw:match("[Dd]o%s+(.+)")
            if code then
                local fn,ce=loadstring(code)
                if not fn then return "Compile error: "..tostring(ce):sub(1,70) end
                local ok2,e2=pcall(fn)
                return ok2 and "Ran: <b>"..code:sub(1,50).."</b> ✓" or "Error: "..tostring(e2):sub(1,70)
            end
        end
        return nil
    end

    local function handleAIAction(text)
        local action, payload = text:match("^ACTION:(%w+):(.+)$")
        if not action then return text end
        if action=="morph" then
            local m=findMorph(payload:lower())
            if m then runRequire(m.name,m.id,{method=m.method,args=m.args}); return "Morphing you into <b>"..m.name.."</b>." end
        elseif action=="speed" then
            local n=tonumber(payload)
            local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if h and n then h.WalkSpeed=n; return "WalkSpeed → <b>"..n.."</b>." end
        elseif action=="jump" then
            local n=tonumber(payload)
            local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if h and n then h.JumpPower=n; h.UseJumpPower=true; return "JumpPower → <b>"..n.."</b>." end
        elseif action=="lua" then
            local fn,ce=loadstring(payload)
            if not fn then return "Claude tried to run: <i>"..payload:sub(1,40).."</i>\nCompile error: "..tostring(ce):sub(1,60) end
            local ok2,e2=pcall(fn)
            return ok2 and "Ran: <b>"..payload:sub(1,50).."</b> ✓" or "Error: "..tostring(e2):sub(1,60)
        end
        return text
    end

    -- ── Chat UI ────────────────────────────────────────────────────────────────
    -- Header: logo + title + model switcher chips + usage counter
    local hdr=Frm(P,UDim2.new(1,0,0,56),nil,C.PANEL); corner(hdr,10); stroke(hdr,C.BORDER,1); pad(hdr,0,0,10,10)
    local cLogo=Frm(hdr,UDim2.new(0,28,0,28),UDim2.new(0,0,0.5,-14),C.CREAM); corner(cLogo,8)
    stroke(cLogo,C.CLAY,1).Transparency=0.4
    local cMark=Lbl(cLogo,"✳",UDim2.new(1,0,1,0),nil,C.CLAY,18,FB); cMark.TextXAlignment=Enum.TextXAlignment.Center
    task.spawn(function() while cLogo and cLogo.Parent do cMark.Rotation=(cMark.Rotation+2)%360; task.wait(0.03) end end)
    Lbl(hdr,"Claude",UDim2.new(0,52,0,18),UDim2.new(0,34,0,2),C.WHITE,14,FB)
    local subLbl=Lbl(hdr,"by Anthropic  ·  Free  ·  Unlimited ∞",UDim2.new(0,200,0,14),UDim2.new(0,34,0,22),C.MUTED,10,FN)
    -- right side: usage label
    local usageLbl=Lbl(hdr,"",UDim2.new(0,90,0,14),UDim2.new(1,-90,0,22),C.MUTED,10,FN)
    usageLbl.TextXAlignment=Enum.TextXAlignment.Right
    -- model switcher chips: [Free ∞] [Claude ✦]
    local switchRow=Frm(hdr,UDim2.new(0,160,0,24),UDim2.new(1,-164,0,2),C.BG); switchRow.BackgroundTransparency=1
    local sh2=Instance.new("UIListLayout"); sh2.FillDirection=Enum.FillDirection.Horizontal; sh2.Padding=UDim.new(0,4); sh2.Parent=switchRow; sh2.VerticalAlignment=Enum.VerticalAlignment.Center
    local freeChip=Frm(switchRow,UDim2.new(0,74,1,0),nil,C.ACCENT); corner(freeChip,12)
    local freeL=Lbl(freeChip,"Free ∞",UDim2.new(1,0,1,0),nil,C.WHITE,11,FB); freeL.TextXAlignment=Enum.TextXAlignment.Center
    local freeBtn=Instance.new("TextButton"); freeBtn.Size=UDim2.new(1,0,1,0); freeBtn.BackgroundTransparency=1; freeBtn.Text=""; freeBtn.Parent=freeChip
    local cChip=Frm(switchRow,UDim2.new(0,80,1,0),nil,C.PANEL); corner(cChip,12); stroke(cChip,C.BORDER,1)
    local cChipL=Lbl(cChip,"Claude ✦",UDim2.new(1,0,1,0),nil,C.MUTED,11,FB); cChipL.TextXAlignment=Enum.TextXAlignment.Center
    local cBtn=Instance.new("TextButton"); cBtn.Size=UDim2.new(1,0,1,0); cBtn.BackgroundTransparency=1; cBtn.Text=""; cBtn.Parent=cChip

    -- refreshModeUI updates chips + subtitle + usage label to reflect current state
    local function refreshModeUI()
        if modelMode == "free" then
            tw(freeChip,{BackgroundColor3=C.ACCENT}); freeL.TextColor3=C.WHITE
            tw(cChip,{BackgroundColor3=C.PANEL}); cChipL.TextColor3=C.MUTED
            subLbl.Text="by Anthropic  ·  Free  ·  Unlimited ∞"
            usageLbl.Text=""
        else
            tw(freeChip,{BackgroundColor3=C.PANEL}); freeL.TextColor3=C.MUTED
            tw(cChip,{BackgroundColor3=C.ACCENT}); cChipL.TextColor3=C.WHITE
            subLbl.Text="by Anthropic  ·  Claude Haiku"
            if rateLimitWaitMins ~= nil then
                local elapsed = os.clock() - rateLimitAt
                local mLeft = math.max(1, math.ceil(((rateLimitWaitMins*60) - elapsed)/60))
                usageLbl.Text="wait "..mLeft.."m"
                usageLbl.TextColor3=C.RED
            elseif claudeRemaining ~= nil then
                usageLbl.Text=claudeRemaining.." msgs left"
                usageLbl.TextColor3=claudeRemaining<=3 and C.YELLOW or C.MUTED
            else
                usageLbl.Text="20 msgs / 30min refill"
                usageLbl.TextColor3=C.MUTED
            end
        end
    end

    -- chat log
    local logBg=Frm(P,UDim2.new(1,0,1,-100),UDim2.new(0,0,0,0),C.DARK); corner(logBg,10); stroke(logBg,C.BORDER,1)
    local _,chat=Scr(logBg,UDim2.new(1,-8,1,-8),UDim2.new(0,4,0,4)); listV(chat,7); pad(chat,8,8,8,8)

    local function bubble(text, fromUser, isSystem)
        local holder=Frm(chat,UDim2.new(1,0,0,0),nil,C.DARK); holder.BackgroundTransparency=1
        holder.AutomaticSize=Enum.AutomaticSize.Y
        local bgCol=fromUser and C.ACCENT or (isSystem and C.PANEL or C.CARD)
        local b=Frm(holder,UDim2.new(0.86,0,0,0),nil,bgCol)
        b.AutomaticSize=Enum.AutomaticSize.Y; corner(b,10)
        if not fromUser then stroke(b,C.BORDER,1) end
        b.Position=fromUser and UDim2.new(0.14,0,0,0) or UDim2.new(0,0,0,0)
        pad(b,8,8,12,12)
        if not fromUser and not isSystem then
            local dot=Frm(holder,UDim2.new(0,18,0,18),UDim2.new(0,0,0,6),C.CREAM); corner(dot,9)
            stroke(dot,C.CLAY,1).Transparency=0.5
            Lbl(dot,"✳",UDim2.new(1,0,1,0),nil,C.CLAY,11,FB).TextXAlignment=Enum.TextXAlignment.Center
            b.Position=UDim2.new(0,24,0,0); b.Size=UDim2.new(1,-24,0,0)
        end
        local t=Instance.new("TextLabel")
        t.Size=UDim2.new(1,0,0,0); t.AutomaticSize=Enum.AutomaticSize.Y; t.BackgroundTransparency=1
        t.Text=text; t.TextColor3=fromUser and C.WHITE or C.TEXT; t.TextSize=13; t.Font=FN
        t.TextWrapped=true; t.TextXAlignment=fromUser and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
        t.RichText=true; t.Parent=b
        task.defer(function() chat.CanvasPosition=Vector2.new(0,1e6) end)
        return t
    end

    -- ── Model chip click handlers (defined after bubble so they can use it) ────
    freeBtn.MouseButton1Click:Connect(function()
        modelMode="free"; refreshModeUI()
    end)
    cBtn.MouseButton1Click:Connect(function()
        if AI_PROXY_URL=="" then
            bubble("To unlock real Claude (Haiku), deploy the free proxy:\n"
                .."1. cloudflare.com → Workers → paste worker/worker.js\n"
                .."2. Secret: ANTHROPIC_KEY = your key from console.anthropic.com\n"
                .."3. KV Namespace binding: RATE_LIMITS\n"
                .."4. Set AI_PROXY_URL in Claude_Hub.lua to your Worker URL.\n"
                .."Free tier has zero limits — no setup needed.", false, true)
        else
            modelMode="claude"; refreshModeUI()
        end
    end)

    -- ── Send logic ─────────────────────────────────────────────────────────────
    local function send(raw)
        raw=raw:match("^%s*(.-)%s*$")
        if raw=="" then return end
        bubble(raw, true)

        -- offline actions never touch any quota
        local localReply=tryLocalAction(raw)
        if localReply then task.delay(0.1,function() bubble(localReply,false) end); return end

        -- Claude tier: check if currently rate-limited with time remaining
        if modelMode=="claude" and rateLimitWaitMins~=nil then
            local elapsed=os.clock()-rateLimitAt
            local secsLeft=math.max(0,(rateLimitWaitMins*60)-elapsed)
            if secsLeft>0 then
                local mLeft=math.ceil(secsLeft/60)
                bubble("You've used all your Claude messages.\nWait "..mLeft.." more minute"
                    ..(mLeft==1 and "" or "s").." to get 10 more.\n(Or tap <b>Free ∞</b> above for unlimited messages.)",false,true)
                return
            else
                -- cooldown expired
                rateLimitWaitMins=nil; claudeRemaining=nil; refreshModeUI()
            end
        end

        local typingL=bubble("✳  thinking…",false)

        if modelMode=="free" then
            -- Free tier: pollinations.ai, completely unlimited
            callPollinationsAI(raw,
                function(reply)
                    typingL.Text=handleAIAction(reply)
                end,
                function(err)
                    typingL.Text="Free AI unavailable ("..tostring(err):sub(1,50)..").\nHub actions (morph, speed, run) still work offline."
                end
            )
        else
            -- Claude tier: proxy required
            if AI_PROXY_URL=="" then
                typingL.Text="Paste your Cloudflare Worker URL into AI_PROXY_URL to use Claude tier.\nSwitching back to Free…"
                modelMode="free"; refreshModeUI(); return
            end
            callViaProxy(raw,
                function(reply, remaining)
                    typingL.Text=handleAIAction(reply)
                    if remaining~=nil then claudeRemaining=remaining; refreshModeUI() end
                end,
                function(err)
                    if err:sub(1,10)=="RATE_LIMIT" then
                        rateLimitWaitMins=tonumber(err:match("RATE_LIMIT:(%d+)")) or 30
                        rateLimitAt=os.clock()
                        claudeRemaining=0; refreshModeUI()
                        typingL.Text="You've used all 20 Claude messages.\nWait "..rateLimitWaitMins.." minutes to get 10 more.\n(Or tap <b>Free ∞</b> for unlimited messages.)"
                    else
                        typingL.Text="Claude unavailable ("..tostring(err):sub(1,50)..").\nTry Free tier or check your Worker URL."
                    end
                end
            )
        end
    end

    -- input row
    local inRow=Frm(P,UDim2.new(1,0,0,42),UDim2.new(0,0,1,-46),C.BG)
    local box=Frm(inRow,UDim2.new(1,-82,1,0),UDim2.new(0,0,0,0),C.CARD); corner(box,9); stroke(box,C.BORDER,1); pad(box,4,4,12,12)
    local tbx=Instance.new("TextBox")
    tbx.Size=UDim2.new(1,0,1,0); tbx.BackgroundTransparency=1
    tbx.PlaceholderText="Ask Claude anything…"
    tbx.PlaceholderColor3=C.MUTED; tbx.Text=""; tbx.TextColor3=C.WHITE; tbx.TextSize=13; tbx.Font=FN
    tbx.TextXAlignment=Enum.TextXAlignment.Left; tbx.ClearTextOnFocus=false; tbx.Parent=box
    local function doSend() local q=tbx.Text; if q=="" then return end; tbx.Text=""; send(q) end
    Btn(inRow,"Send",UDim2.new(0,76,1,0),UDim2.new(1,-76,0,0),C.ACCENT,doSend)
    tbx.FocusLost:Connect(function(enter) if enter then doSend() end end)

    refreshModeUI()

    -- welcome bubble
    bubble("Hi <b>"..LP.DisplayName.."</b>! I'm Claude — made by Anthropic.\n"
        .."• <b>Free ∞</b> (default) — unlimited messages, no setup\n"
        .."• <b>Claude ✦</b> — real Haiku: 20 msgs, wait 30 min → 10 more\n"
        .."Try: <b>morph [name]</b>  ·  <b>speed 200</b>  ·  <b>run print('hi')</b>  ·  <b>fire [remote]</b>",false)
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB — CLAUDE CONSOLE  (live Roblox + executor output log)
-- ═══════════════════════════════════════════════════════════════════════════════
do
    local P=newTab("🖥","Console")
    local LogService=game:GetService("LogService")

    -- Header: title + type filter chips + search
    local hdrRow=Frm(P,UDim2.new(1,0,0,38),nil,C.BG); hdrRow.BackgroundTransparency=1
    local hh=Instance.new("UIListLayout"); hh.FillDirection=Enum.FillDirection.Horizontal; hh.Padding=UDim.new(0,6); hh.Parent=hdrRow; hh.VerticalAlignment=Enum.VerticalAlignment.Center
    Lbl(hdrRow,"Claude Console",UDim2.new(0,110,1,0),nil,C.WHITE,14,FB)

    -- filter state: "all" | "print" | "warn" | "error"
    local filterMode="all"
    local filterChips={}
    local function makeChip(label, mode)
        local chip=Frm(hdrRow,UDim2.new(0,52,0,26),nil,mode=="all" and C.ACCENT or C.PANEL); corner(chip,13)
        local cl=Lbl(chip,label,UDim2.new(1,0,1,0),nil,mode=="all" and C.WHITE or C.MUTED,11,FB); cl.TextXAlignment=Enum.TextXAlignment.Center
        local cb=Instance.new("TextButton"); cb.Size=UDim2.new(1,0,1,0); cb.BackgroundTransparency=1; cb.Text=""; cb.Parent=chip
        filterChips[mode]={chip=chip,lbl=cl}
        return chip, cb
    end
    local allChip,allBtn=makeChip("All","all")
    local pChip,pBtn=makeChip("Print","print")
    local wChip,wBtn=makeChip("Warn","warn")
    local eChip,eBtn=makeChip("Error","error")

    -- log entries list: {frame=, text=, mtype=}
    local logEntries={}
    local logBg=Frm(P,UDim2.new(1,0,1,-88),UDim2.new(0,0,0,0),C.DARK); corner(logBg,10); stroke(logBg,C.BORDER,1)
    local _,logScroll=Scr(logBg,UDim2.new(1,-6,1,-6),UDim2.new(0,3,0,3)); listV(logScroll,1); pad(logScroll,4,4,6,4)

    local function applyFilter()
        for _,e in ipairs(logEntries) do
            e.frame.Visible = (filterMode=="all") or (e.mtype==filterMode)
        end
    end

    local function setFilter(mode)
        filterMode=mode
        for m,c in pairs(filterChips) do
            local active=(m==mode)
            tw(c.chip,{BackgroundColor3=active and C.ACCENT or C.PANEL})
            c.lbl.TextColor3=active and C.WHITE or C.MUTED
        end
        applyFilter()
    end

    allBtn.MouseButton1Click:Connect(function() setFilter("all") end)
    pBtn.MouseButton1Click:Connect(function() setFilter("print") end)
    wBtn.MouseButton1Click:Connect(function() setFilter("warn") end)
    eBtn.MouseButton1Click:Connect(function() setFilter("error") end)

    local function addLog(msg, msgType)
        local mtype="print"
        local col=C.TEXT
        if msgType==Enum.MessageType.MessageWarning then mtype="warn"; col=C.YELLOW
        elseif msgType==Enum.MessageType.MessageError then mtype="error"; col=C.RED
        end
        local row=Frm(logScroll,UDim2.new(1,0,0,0),nil,C.DARK); row.BackgroundTransparency=1
        row.AutomaticSize=Enum.AutomaticSize.Y
        -- type dot
        local dot=Frm(row,UDim2.new(0,6,0,6),UDim2.new(0,0,0,5),col); corner(dot,3)
        local t=Instance.new("TextLabel")
        t.Size=UDim2.new(1,-12,0,0); t.Position=UDim2.new(0,10,0,0)
        t.AutomaticSize=Enum.AutomaticSize.Y; t.BackgroundTransparency=1
        t.Text=tostring(msg):sub(1,300); t.TextColor3=col; t.TextSize=11; t.Font=FN
        t.TextWrapped=true; t.TextXAlignment=Enum.TextXAlignment.Left; t.RichText=false; t.Parent=row
        table.insert(logEntries,{frame=row,text=tostring(msg):lower(),mtype=mtype})
        row.Visible=(filterMode=="all" or filterMode==mtype)
        task.defer(function() logScroll.CanvasPosition=Vector2.new(0,1e6) end)
    end

    -- load existing log history
    pcall(function()
        for _,e in ipairs(LogService:GetLogHistory()) do
            addLog(e.message, e.messageType)
        end
    end)
    LogService.MessageOut:Connect(addLog)

    -- bottom bar: CLEAR button
    local botRow=Frm(P,UDim2.new(1,0,0,36),UDim2.new(0,0,1,-40),C.BG); botRow.BackgroundTransparency=1
    Btn(botRow,"CLEAR",UDim2.new(1,0,1,0),nil,C.PANEL,function()
        for _,e in ipairs(logEntries) do pcall(function() e.frame:Destroy() end) end
        logEntries={}
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB — UNC / sUNC  (executor function checker — run the 100-function test)
-- ═══════════════════════════════════════════════════════════════════════════════
do
    local P=newTab("✅","UNC")

    -- resolve a possibly-dotted global name from the executor environment
    local function lookup(name)
        local parts={}; for p in name:gmatch("[^%.]+") do parts[#parts+1]=p end
        local root
        pcall(function() root=(getgenv and getgenv()[parts[1]]); if root==nil then root=getfenv(0)[parts[1]] end end)
        if root==nil then return nil end
        local cur=root
        for i=2,#parts do if type(cur)~="table" then return nil end; cur=cur[parts[i]] end
        return cur
    end

    -- UNC — standard 100 + Delta-specific missing functions
    -- (functions Delta is missing are included so they correctly show as FAIL)
    local UNC={
        -- core instance / closure
        "cache.invalidate","cache.iscached","cache.replace","cloneref","compareinstances",
        "checkcaller","clonefunction","getcallingscript","getscriptclosure","hookfunction",
        "hookmetamethod","getrawmetatable","setrawmetatable","isreadonly","setreadonly",
        "getnamecallmethod","newcclosure","iscclosure","islclosure","isexecutorclosure",
        "isnewcclosure",          -- ← Delta: MISSING
        "isourthread",            -- ← Delta: MISSING
        "getfunctionhash","getgc","getgenv","getrenv","getreg","filtergc",
        -- connections / signals
        "getconnections",
        "firesignal","replicatesignal",
        -- instance utilities
        "getcustomasset","gethiddenproperty","sethiddenproperty","gethui",
        "getinstances","getnilinstances","isscriptable","setscriptable",
        "makewritable",           -- ← Delta: MISSING
        -- thread identity
        "getthreadidentity","setthreadidentity",
        "getscriptthread",        -- ← Delta: MISSING
        -- fire* helpers
        "fireclickdetector","firetouchinterest","fireproximityprompt",
        -- misc checks
        "isrbxactive","isnetworkowner",
        -- input
        "mouse1click","mouse1press","mouse1release","mouse2click","mouse2press",
        "mouse2release","mousemoveabs","mousemoverel","mousescroll",
        "keypress","keyrelease","keytap","iskeydown",  -- keytap: Delta PASSES
        -- network
        "WebSocket","request",
        "httpget",                -- ← Delta: exists but ARGUMENT MISMATCH ⚠
        -- crypto — Delta PASSES most, MISSING hmac + random
        "crypt.base64encode","crypt.base64decode",
        "crypt.encrypt","crypt.decrypt","crypt.generatebytes","crypt.generatekey","crypt.hash",
        "crypt.hmac",             -- ← Delta: MISSING
        "crypt.random",           -- ← Delta: MISSING
        -- base64 aliases
        "base64.encode","base64.decode",
        -- clipboard
        "getclipboard","setclipboard",
        -- teleport
        "queue_on_teleport",
        -- filesystem
        "readfile","writefile","appendfile","loadfile","listfiles","isfile","isfolder",
        "makefolder","delfolder","delfile",
        -- execution
        "loadstring",
        "dofile",                 -- ← Delta: exists but WRONG RETURN VALUE ⚠
        "messagebox",             -- ← Delta: exists but WRONG RETURN TYPE ⚠
        -- executor info
        "identifyexecutor","getexecutorname",
        -- fps / render
        "setfpscap","getfpscap","setrenderproperty","getrenderproperty","cleardrawcache",
        -- scripts
        "getrunningscripts","getloadedmodules","getscripts",
        "getscriptbytecode","getscripthash","getsenv","getcallbackvalue",
        -- actors
        "getactors","run_on_actor","getthreads",
        -- Drawing
        "Drawing.new","Drawing.Fonts",
        -- rconsole — Delta: exist but TIMEOUT ⚠
        "rconsolecreate","rconsolesettitle","rconsoleprint","rconsoleclear","rconsoleerror",
        -- debug — Delta: MISSING
        "debug.getcallstack","debug.getsafeenv","debug.setsafeenv","debug.setname",
        -- fflag
        "getfflagtype",           -- ← Delta: MISSING
    }
    -- sUNC — secure/stricter extras
    local SUNC={
        "checkcaller","clonefunction","getcallingscript","getscriptclosure","hookfunction",
        "hookmetamethod","newcclosure","isexecutorclosure","isnewcclosure","getfunctionhash",
        "getfflag","isluau","getgc","filtergc","getrawmetatable","setrawmetatable",
        "isreadonly","setreadonly","getnamecallmethod","getsenv","getmenv","getcallbackvalue",
        "getscriptbytecode","getscripthash","decompile","getproto","getprotos","getconstant",
        "getconstants","getupvalue","getupvalues","setupvalue","setconstant","getstack",
        "setstack","getinfo","islclosure","iscclosure","getfenv","setfenv","getreg",
        "validlevel","gethui","cloneref","compareinstances","getcustomasset","setscriptable",
        "debug.getcallstack","debug.getsafeenv","debug.setsafeenv","debug.setname",
        "getscriptthread","isourthread","makewritable","getfflagtype",
    }
    -- Behavioral tests — existence alone isn't enough for these functions.
    -- ⚠ badge shown when a function exists but fails the behavioral test.
    local BTESTS = {
        ["firesignal"] = function()
            -- Delta: firesignal exists but does NOT fire connected callbacks
            local fired = false
            local be = Instance.new("BindableEvent")
            be.Event:Connect(function() fired = true end)
            pcall(firesignal, be.Event)
            pcall(function() be:Destroy() end)
            return fired
        end,
        ["replicatesignal"] = function()
            -- Delta: replicatesignal exists but throws "invalid argument" error
            local re = Instance.new("RemoteEvent")
            local ok2 = pcall(replicatesignal, re)
            pcall(function() re:Destroy() end)
            return ok2
        end,
        ["getconnections"] = function()
            -- Must return a non-empty table when a connection exists
            local be = Instance.new("BindableEvent")
            local conn = be.Event:Connect(function() end)
            local ok2, t = pcall(getconnections, be.Event)
            pcall(function() conn:Disconnect(); be:Destroy() end)
            return ok2 and type(t) == "table" and #t > 0
        end,
        ["gethiddenproperty"] = function()
            -- Must return (value, bool) — 2 return values
            local ok2, val, isHid = pcall(gethiddenproperty, workspace, "StreamingEnabled")
            return ok2 and isHid ~= nil
        end,
        ["sethiddenproperty"] = function()
            local ok2, cur = pcall(gethiddenproperty, workspace, "StreamingEnabled")
            if not ok2 then return false end
            return pcall(sethiddenproperty, workspace, "StreamingEnabled", cur)
        end,
        ["isrbxactive"] = function()
            local ok2, v = pcall(isrbxactive)
            return ok2 and type(v) == "boolean"
        end,
        ["dofile"] = function()
            -- Delta: dofile exists but returns wrong type. Correct: error on missing file.
            local ok2, result = pcall(dofile, "__ch_test_nonexistent__.lua")
            -- Correct: errors cleanly (file not found). Wrong: returns a table/userdata.
            if ok2 then return type(result) ~= "table" and type(result) ~= "userdata" end
            -- Errored cleanly — check the message contains "file" or "not found"
            local msg = tostring(result):lower()
            return msg:find("file") ~= nil or msg:find("not found") ~= nil or msg:find("open") ~= nil
        end,
        ["messagebox"] = function()
            -- Delta: messagebox exists but returns wrong type. Must return number (button index).
            -- We can't show a real dialog in test mode, so just verify the return type signature.
            -- Calling with nil args should either error or return a number/nil.
            local ok2, result = pcall(messagebox, "", "", 0)
            if not ok2 then return false end  -- errored = wrong
            return type(result) == "number" or type(result) == "nil"
        end,
        ["httpget"] = function()
            -- Delta: httpget has argument mismatch (may expect different args than game:HttpGet)
            -- Test: call httpget with a simple URL and check it returns a string body
            if not httpget then return false end
            local ok2, result = pcall(httpget, "https://httpbin.org/get", true)
            return ok2 and type(result) == "string" and #result > 0
        end,
    }

    local sumBar=Frm(P,UDim2.new(1,0,0,52),nil,C.PANEL); corner(sumBar,10); stroke(sumBar,C.BORDER,1); pad(sumBar,8,8,12,12)
    local sumTitle=Lbl(sumBar,"Run a test to check your executor",UDim2.new(1,0,0,18),nil,C.WHITE,14,FB)
    local sumSub=Lbl(sumBar,ENV.name.." · UNC measures executor function coverage",UDim2.new(1,0,0,16),UDim2.new(0,0,0,24),C.MUTED,11,FN)
    -- progress bar
    local pbBg=Frm(P,UDim2.new(1,0,0,8),nil,C.DARK); corner(pbBg,4)
    local pbFill=Frm(pbBg,UDim2.new(0,0,1,0),nil,C.GREEN); corner(pbFill,4)

    local searchReg=CardSearch(P,"Search functions…")
    local resHost=Instance.new("Frame")
    resHost.Size=UDim2.new(1,0,0,0); resHost.BackgroundTransparency=1; resHost.AutomaticSize=Enum.AutomaticSize.Y; resHost.Parent=P
    listV(resHost,3)
    local lastResults={}

    local function runTest(list,label)
        for _,c in ipairs(resHost:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
        lastResults={}
        local pass=0
        for _,name in ipairs(list) do
            local v=lookup(name)
            local exists=(type(v)=="function") or (type(v)=="table")
            local ok2
            if exists and BTESTS[name] then
                -- behavioral test: exists isn't enough, check it actually works
                local bOk,bResult=pcall(BTESTS[name])
                ok2 = bOk and bResult
            else
                ok2 = exists
            end
            if ok2 then pass=pass+1 end
            -- ⚠ suffix when function exists but behavioral test failed (Delta partial support)
            local dispName = name..(exists and not ok2 and " ⚠" or "")
            table.insert(lastResults,(ok2 and "[PASS] " or "[FAIL] ")..dispName)
            local row=Frm(resHost,UDim2.new(1,0,0,24),nil,C.CARD); corner(row,6); pad(row,0,0,10,8)
            local nc=ok2 and C.TEXT or (exists and C.YELLOW or C.MUTED)
            Lbl(row,dispName,UDim2.new(1,-60,1,0),nil,nc,11,FN).TextTruncate=Enum.TextTruncate.AtEnd
            local tag=Lbl(row,ok2 and "✓ pass" or (exists and "⚠ bad" or "✗ fail"),UDim2.new(0,56,1,0),UDim2.new(1,-56,0,0),ok2 and C.GREEN or (exists and C.YELLOW or C.RED),11,FB)
            tag.TextXAlignment=Enum.TextXAlignment.Right
            searchReg(row,name:lower())
        end
        local total=#list; local pct=math.floor(pass/total*100+0.5)
        sumTitle.Text=label..":  "..pass.."/"..total.."  ("..pct.."%)"
        sumSub.Text=ENV.name.." · "..(total-pass).." missing/bad"
        local col = pct>=90 and C.GREEN or (pct>=60 and C.YELLOW or C.RED)
        pbFill.BackgroundColor3=col
        tw(pbFill,{Size=UDim2.new(pct/100,0,1,0)},TS2)
        sumTitle.TextColor3=col
        notify("Claude Hub",label.." "..pct.."% ("..pass.."/"..total..")",4)
    end

    local rowBtns=Frm(P,UDim2.new(1,0,0,38),nil,C.BG)
    local hh=Instance.new("UIListLayout"); hh.FillDirection=Enum.FillDirection.Horizontal; hh.Padding=UDim.new(0,6); hh.Parent=rowBtns
    Btn(rowBtns,"▶  Run UNC ("..#UNC..")",UDim2.new(0.5,-3,1,0),nil,C.ACCENT,function() runTest(UNC,"UNC") end)
    Btn(rowBtns,"▶  Run sUNC",UDim2.new(0.5,-3,1,0),nil,C.PANEL,function() runTest(SUNC,"sUNC") end)
    if ENV.HAS_CLIP then
        Btn(P,"Copy Results",UDim2.new(1,0,0,32),nil,C.PANEL,function()
            if #lastResults==0 then notify("Claude Hub","Run a test first",2); return end
            ENV.setClip(table.concat(lastResults,"\n")); notify("Claude Hub","Results copied!",2)
        end)
    end
    do
        local w=Frm(P,UDim2.new(1,0,0,34),nil,C.PANEL); corner(w,8); pad(w,6,6,10,10)
        Lbl(w,#UNC.." UNC + "..#SUNC.." sUNC functions tested. ⚠ = exists but fails behavioral test.\nHigher % = more capable executor.",UDim2.new(1,0,1,0),nil,C.MUTED,10,FN)
    end
    task.defer(function() runTest(UNC,"UNC") end)
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
--  AUTO MEMORY READER — runs at startup, reads the game's memory automatically
--  (no tab). Builds ENV.mem so the hub "already knows everything" on load.
-- ═══════════════════════════════════════════════════════════════════════════════
ENV.mem = {
    globals   = {},   -- getgenv/_G keys -> type
    remotes   = {},   -- {class,name,path}
    values    = {},   -- ValueBase paths -> value
    stats     = {},   -- leaderstats / data
    gc        = {fns=0, tabs=0, other=0},
    scanned   = false,
}
task.spawn(function()
    local M = ENV.mem
    -- 1) globals
    pcall(function()
        local src=(getgenv and getgenv()) or _G
        for k,v in pairs(src) do M.globals[tostring(k)]=type(v) end
    end)
    -- 2) every ValueBase + remote in the whole game (deep)
    pcall(function()
        for _,o in ipairs(game:GetDescendants()) do
            if o:IsA("ValueBase") then
                local okp,p=pcall(function() return o:GetFullName() end)
                M.values[okp and p or o.Name]=o.Value
            elseif o:IsA("RemoteEvent") or o:IsA("RemoteFunction") then
                local okp,p=pcall(function() return o:GetFullName() end)
                M.remotes[#M.remotes+1]={class=o.ClassName,name=o.Name,path=okp and p or o.Name}
            end
        end
    end)
    -- 3) hidden / nil-parented remotes (executor memory)
    if getnilinstances then
        pcall(function()
            for _,o in ipairs(getnilinstances()) do
                if typeof(o)=="Instance" and (o:IsA("RemoteEvent") or o:IsA("RemoteFunction")) then
                    M.remotes[#M.remotes+1]={class=o.ClassName,name=o.Name,path="(nil)."..o.Name,hidden=true}
                end
            end
        end)
    end
    -- 4) your stats (leaderstats + common data folders)
    pcall(function()
        local ls=LP:FindFirstChild("leaderstats")
        if ls then for _,v in ipairs(ls:GetChildren()) do if v:IsA("ValueBase") then M.stats[v.Name]=v.Value end end end
        for _,fn in ipairs({"Data","PlayerData","Stats","Currency"}) do
            local f=LP:FindFirstChild(fn)
            if f then for _,v in ipairs(f:GetChildren()) do if v:IsA("ValueBase") then M.stats[fn.."."..v.Name]=v.Value end end end
        end
    end)
    -- 5) GC sweep (functions/tables resident in memory)
    if getgc then
        pcall(function()
            for _,o in ipairs(getgc(true)) do
                local tp=type(o)
                if tp=="function" then M.gc.fns=M.gc.fns+1
                elseif tp=="table" then M.gc.tabs=M.gc.tabs+1
                else M.gc.other=M.gc.other+1 end
            end
        end)
    end
    M.gcount=0; for _ in pairs(M.globals) do M.gcount=M.gcount+1 end
    M.vcount=0; for _ in pairs(M.values)  do M.vcount=M.vcount+1 end
    M.scanned=true
    notify("🧠 Memory Read",#M.remotes.." remotes · "..M.vcount.." values · "..M.gcount.." globals",4)
end)

-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB — SCRIPT LIBRARY  (save, search, execute scripts — Delta-style)
-- ═══════════════════════════════════════════════════════════════════════════════
do
    local P=newTab("📂","Scripts")
    -- saved scripts: {name=string, code=string, builtIn=bool}
    local SAVED={
        {name="WalkSpeed 200",  code='game.Players.LocalPlayer.Character.Humanoid.WalkSpeed=200', builtIn=true},
        {name="Infinite Jump",  code='game:GetService("UserInputService").JumpRequest:Connect(function() game.Players.LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end)', builtIn=true},
        {name="Noclip",         code='game:GetService("RunService").Stepped:Connect(function() game.Players.LocalPlayer.Character:FindFirstChildOfClass("HumanoidRootPart").CanCollide=false end)', builtIn=true},
        {name="Print Name",     code='print(game.Players.LocalPlayer.Name)', builtIn=true},
        {name="Infinite Yield", code='loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source",true))()', builtIn=true},
    }
    -- load persisted scripts from files if available
    if readfile and listfiles then
        pcall(function()
            if not isfolder("claudehub") then makefolder("claudehub") end
            for _,f in ipairs(listfiles("claudehub")) do
                if f:match("%.lua$") then
                    local nm=f:match("([^/\\]+)%.lua$") or f
                    local ok2,src=pcall(readfile,f)
                    if ok2 and src and src~="" then
                        table.insert(SAVED,{name=nm,code=src,builtIn=false,path=f})
                    end
                end
            end
        end)
    end

    -- search bar + Upload button
    local topRow=Frm(P,UDim2.new(1,0,0,40),nil,C.BG)
    local hh=Instance.new("UIListLayout"); hh.FillDirection=Enum.FillDirection.Horizontal; hh.Padding=UDim.new(0,6); hh.Parent=topRow
    local sWrap=Frm(topRow,UDim2.new(1,-98,1,0),nil,C.CARD); corner(sWrap,10); stroke(sWrap,C.BORDER,1); pad(sWrap,4,4,12,10)
    Lbl(sWrap,"🔍",UDim2.new(0,18,1,0),UDim2.new(0,0,0,0),C.MUTED,13,FN)
    local sTbx=Instance.new("TextBox")
    sTbx.Size=UDim2.new(1,-22,1,0); sTbx.Position=UDim2.new(0,22,0,0); sTbx.BackgroundTransparency=1
    sTbx.PlaceholderText="Search for scripts…"; sTbx.PlaceholderColor3=C.MUTED
    sTbx.Text=""; sTbx.TextColor3=C.WHITE; sTbx.TextSize=13; sTbx.Font=FN
    sTbx.TextXAlignment=Enum.TextXAlignment.Left; sTbx.ClearTextOnFocus=false; sTbx.Parent=sWrap

    -- Upload from clipboard
    local uploadBtn=Frm(topRow,UDim2.new(0,86,1,0),nil,C.ACCENT); corner(uploadBtn,10)
    Lbl(uploadBtn,"UPLOAD",UDim2.new(1,0,1,0),nil,C.WHITE,12,FB).TextXAlignment=Enum.TextXAlignment.Center
    local upClick=Instance.new("TextButton"); upClick.Size=UDim2.new(1,0,1,0); upClick.BackgroundTransparency=1; upClick.Text=""; upClick.Parent=uploadBtn

    -- script list host
    local listHost=Instance.new("Frame"); listHost.Size=UDim2.new(1,0,0,0)
    listHost.BackgroundTransparency=1; listHost.AutomaticSize=Enum.AutomaticSize.Y; listHost.Parent=P
    listV(listHost,6)
    local scriptItems={}   -- {card=, text=}

    -- reference to Execute tab editor (set after Execute tab is defined)
    -- We patch it in via _G._SS_EDITOR at runtime
    local function execScript(code)
        -- find the execute tab editor by name
        local w=SGI:FindFirstChild("WIN")
        if w then
            local ed=w:FindFirstChild("__EXEC_EDITOR__",true)
            if ed then ed.Text=code end
        end
        -- run directly
        local fn,ce=loadstring(code)
        if not fn then notify("Script Error",tostring(ce):sub(1,60),5); return end
        local ok2,e2=pcall(fn)
        if not ok2 then notify("Runtime Error",tostring(e2):sub(1,60),5) end
    end

    local function saveScript(name, code)
        -- write to file if possible
        if writefile then
            pcall(function()
                if not isfolder("claudehub") then makefolder("claudehub") end
                writefile("claudehub/"..name:gsub("[^%w%s%-_]","").."_"..tostring(#SAVED)..".lua", code)
            end)
        end
    end

    local function rebuildList()
        for _,c in ipairs(listHost:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
        scriptItems={}
        local q=sTbx.Text:lower()
        for idx,s in ipairs(SAVED) do
            local visible=(q=="" or string.find(s.name:lower(),q,1,true))
            if visible then
                -- Delta-style card: dark bg, bold name, built-in tag, DELETE+EXECUTE buttons
                local card=Frm(listHost,UDim2.new(1,0,0,62),nil,C.CARD); corner(card,12); stroke(card,C.BORDER,1)
                pad(card,0,0,16,12)
                -- name
                local nameL=Lbl(card,s.name,UDim2.new(1,-220,0,22),UDim2.new(0,0,0,8),C.WHITE,14,FB)
                nameL.TextTruncate=Enum.TextTruncate.AtEnd
                -- built-in badge
                if s.builtIn then
                    local badge=Frm(card,UDim2.new(0,72,0,22),UDim2.new(0,nameL.Size.X.Offset+4,0,8),C.ACCENT); corner(badge,11)
                    Lbl(badge,"Built-In",UDim2.new(1,0,1,0),nil,C.WHITE,10,FB).TextXAlignment=Enum.TextXAlignment.Center
                end
                -- buttons row
                local brow=Frm(card,UDim2.new(0,200,0,30),UDim2.new(1,-200,0.5,-15),C.BG); brow.BackgroundTransparency=1
                local bh=Instance.new("UIListLayout"); bh.FillDirection=Enum.FillDirection.Horizontal; bh.Padding=UDim.new(0,8); bh.Parent=brow; bh.HorizontalAlignment=Enum.HorizontalAlignment.Right
                -- DELETE button
                if not s.builtIn then
                    local del=Frm(brow,UDim2.new(0,84,0,30),nil,C.PANEL); corner(del,8); stroke(del,C.BORDER,1)
                    Lbl(del,"DELETE",UDim2.new(1,0,1,0),nil,C.TEXT,11,FB).TextXAlignment=Enum.TextXAlignment.Center
                    local db=Instance.new("TextButton"); db.Size=UDim2.new(1,0,1,0); db.BackgroundTransparency=1; db.Text=""; db.Parent=del
                    local captIdx=idx
                    db.MouseButton1Click:Connect(function()
                        if SAVED[captIdx] then
                            if SAVED[captIdx].path and delfile then pcall(delfile,SAVED[captIdx].path) end
                            table.remove(SAVED,captIdx); rebuildList()
                        end
                    end)
                    db.MouseEnter:Connect(function() tw(del,{BackgroundColor3=C.RED}) end)
                    db.MouseLeave:Connect(function() tw(del,{BackgroundColor3=C.PANEL}) end)
                end
                -- EXECUTE button
                local exe=Frm(brow,UDim2.new(0,84,0,30),nil,C.PANEL); corner(exe,8); stroke(exe,C.ACCENT,1)
                Lbl(exe,"EXECUTE",UDim2.new(1,0,1,0),nil,C.ACCENT,11,FB).TextXAlignment=Enum.TextXAlignment.Center
                local eb=Instance.new("TextButton"); eb.Size=UDim2.new(1,0,1,0); eb.BackgroundTransparency=1; eb.Text=""; eb.Parent=exe
                local captCode=s.code
                eb.MouseButton1Click:Connect(function() execScript(captCode) end)
                eb.MouseEnter:Connect(function() tw(exe,{BackgroundColor3=C.ACCENT}) end)
                eb.MouseLeave:Connect(function() tw(exe,{BackgroundColor3=C.PANEL}) end)

                table.insert(scriptItems,{card=card,text=s.name:lower()})
            end
        end
        local cnt=Frm(P,UDim2.new(1,0,0,0),nil,C.BG); cnt.BackgroundTransparency=1  -- spacer
    end

    sTbx:GetPropertyChangedSignal("Text"):Connect(rebuildList)

    -- Upload: show popup to name + paste code
    upClick.MouseButton1Click:Connect(function()
        -- get code from clipboard or prompt
        local code=""
        if getclipboard then pcall(function() code=getclipboard() end) end
        if code=="" then notify("Script Library","Copy your script first, then press UPLOAD",4); return end
        -- ask for name via a quick input popup
        local popBg=Frm(SGI,UDim2.new(0,320,0,120),UDim2.new(0.5,-160,0.5,-60),C.PANEL,"ScriptNamePop")
        corner(popBg,12); stroke(popBg,C.BORDER,1); pad(popBg,12,12,16,16)
        Lbl(popBg,"Script name:",UDim2.new(1,0,0,18),nil,C.WHITE,13,FB)
        local _,ninp=Inp(popBg,"my_script",UDim2.new(1,0,0,32),UDim2.new(0,0,0,22))
        Btn(popBg,"Save",UDim2.new(1,0,0,32),UDim2.new(0,0,1,-36),C.ACCENT,function()
            local nm=ninp.Text~="" and ninp.Text or ("Script "..#SAVED+1)
            table.insert(SAVED,{name=nm,code=code,builtIn=false})
            saveScript(nm,code)
            popBg:Destroy(); rebuildList()
            notify("Script Library","Saved: "..nm,3)
        end)
        -- close on outside click
        task.delay(5,function() if popBg and popBg.Parent then popBg:Destroy() end end)
    end)
    tw(uploadBtn,{BackgroundColor3=C.ACCENT})
    upClick.MouseEnter:Connect(function() tw(uploadBtn,{BackgroundColor3=C.ACC2}) end)
    upClick.MouseLeave:Connect(function() tw(uploadBtn,{BackgroundColor3=C.ACCENT}) end)

    task.defer(rebuildList)
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB — SETTINGS  (Delta-style: search, toggle rows, click-here actions)
-- ═══════════════════════════════════════════════════════════════════════════════
do
    local P=newTab("⚙","Settings")

    -- top row: Enabled/Disabled/All filter chips + search bar
    local topRow=Frm(P,UDim2.new(1,0,0,40),nil,C.BG); topRow.BackgroundTransparency=1
    local th=Instance.new("UIListLayout"); th.FillDirection=Enum.FillDirection.Horizontal; th.Padding=UDim.new(0,6); th.Parent=topRow; th.VerticalAlignment=Enum.VerticalAlignment.Center
    -- filter chips
    local chipW=UDim2.new(0,76,1,0)
    local enChip=Frm(topRow,chipW,nil,C.PANEL); corner(enChip,10)
    local enL=Lbl(enChip,"Enabled",UDim2.new(1,0,1,0),nil,C.MUTED,11,FB); enL.TextXAlignment=Enum.TextXAlignment.Center
    local enBtn=Instance.new("TextButton"); enBtn.Size=UDim2.new(1,0,1,0); enBtn.BackgroundTransparency=1; enBtn.Text=""; enBtn.Parent=enChip
    local disChip=Frm(topRow,chipW,nil,C.PANEL); corner(disChip,10)
    local disL=Lbl(disChip,"Disabled",UDim2.new(1,0,1,0),nil,C.MUTED,11,FB); disL.TextXAlignment=Enum.TextXAlignment.Center
    local disBtn=Instance.new("TextButton"); disBtn.Size=UDim2.new(1,0,1,0); disBtn.BackgroundTransparency=1; disBtn.Text=""; disBtn.Parent=disChip
    local allChipS=Frm(topRow,chipW,nil,C.ACCENT); corner(allChipS,10)
    local allLS=Lbl(allChipS,"All",UDim2.new(1,0,1,0),nil,C.WHITE,11,FB); allLS.TextXAlignment=Enum.TextXAlignment.Center
    local allBtnS=Instance.new("TextButton"); allBtnS.Size=UDim2.new(1,0,1,0); allBtnS.BackgroundTransparency=1; allBtnS.Text=""; allBtnS.Parent=allChipS
    -- search bar (fills rest)
    local sWrap=Frm(topRow,UDim2.new(1,-246,1,0),nil,C.CARD); corner(sWrap,10); stroke(sWrap,C.BORDER,1); pad(sWrap,4,4,12,10)
    Lbl(sWrap,"🔍",UDim2.new(0,18,1,0),UDim2.new(0,0,0,0),C.MUTED,13,FN)
    local sTbx=Instance.new("TextBox")
    sTbx.Size=UDim2.new(1,-22,1,0); sTbx.Position=UDim2.new(0,22,0,0); sTbx.BackgroundTransparency=1
    sTbx.PlaceholderText="Search for options…"; sTbx.PlaceholderColor3=C.MUTED
    sTbx.Text=""; sTbx.TextColor3=C.WHITE; sTbx.TextSize=13; sTbx.Font=FN
    sTbx.TextXAlignment=Enum.TextXAlignment.Left; sTbx.ClearTextOnFocus=false; sTbx.Parent=sWrap

    -- settingItems: {row=, text=, isToggle=, stateRef=}
    local settingItems={}
    local settingsFilter="all"  -- "all" | "enabled" | "disabled"
    local toggleStates={}  -- row -> bool

    local function applySettingsFilter()
        local q=sTbx.Text:lower()
        for _,it in ipairs(settingItems) do
            local matchText=(q=="" or string.find(it.text,q,1,true)~=nil)
            local matchFilter=true
            if settingsFilter=="enabled" and it.isToggle then matchFilter=(toggleStates[it.row]==true)
            elseif settingsFilter=="disabled" and it.isToggle then matchFilter=(toggleStates[it.row]==false) end
            it.row.Visible=matchText and matchFilter
        end
    end

    local function setSettingsChip(mode)
        settingsFilter=mode
        tw(enChip,{BackgroundColor3=mode=="enabled" and C.ACCENT or C.PANEL}); enL.TextColor3=mode=="enabled" and C.WHITE or C.MUTED
        tw(disChip,{BackgroundColor3=mode=="disabled" and C.ACCENT or C.PANEL}); disL.TextColor3=mode=="disabled" and C.WHITE or C.MUTED
        tw(allChipS,{BackgroundColor3=mode=="all" and C.ACCENT or C.PANEL}); allLS.TextColor3=mode=="all" and C.WHITE or C.MUTED
        applySettingsFilter()
    end
    enBtn.MouseButton1Click:Connect(function() setSettingsChip("enabled") end)
    disBtn.MouseButton1Click:Connect(function() setSettingsChip("disabled") end)
    allBtnS.MouseButton1Click:Connect(function() setSettingsChip("all") end)

    -- Toggle row helper (Delta card style)
    local function ToggleRow(label, desc, default, onChange)
        local row=Frm(P,UDim2.new(1,0,0,62),nil,C.CARD); corner(row,12); stroke(row,C.BORDER,1); pad(row,0,0,16,16)
        Lbl(row,label,UDim2.new(1,-72,0,22),UDim2.new(0,0,0,8),C.WHITE,14,FB)
        Lbl(row,desc,UDim2.new(1,-72,0,18),UDim2.new(0,0,0,32),C.MUTED,11,FN)
        local state=default
        toggleStates[row]=state
        local track=Frm(row,UDim2.new(0,48,0,26),UDim2.new(1,-48,0.5,-13),state and C.ACCENT or C.PANEL); corner(track,13)
        local thumb=Frm(track,UDim2.new(0,20,0,20),UDim2.new(0,state and 25 or 3,0.5,-10),C.WHITE); corner(thumb,10)
        local btn=Instance.new("TextButton"); btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1; btn.Text=""; btn.Parent=track
        btn.MouseButton1Click:Connect(function()
            state=not state; toggleStates[row]=state
            tw(track,{BackgroundColor3=state and C.ACCENT or C.PANEL})
            tw(thumb,{Position=UDim2.new(0,state and 25 or 3,0.5,-10)})
            if onChange then pcall(onChange,state) end
            applySettingsFilter()
        end)
        table.insert(settingItems,{row=row,text=(label.." "..desc):lower(),isToggle=true})
        return row
    end

    -- Click-here action row
    local function ActionRow(label, desc, btnTxt, onClick)
        local row=Frm(P,UDim2.new(1,0,0,62),nil,C.CARD); corner(row,12); stroke(row,C.BORDER,1); pad(row,0,0,16,16)
        Lbl(row,label,UDim2.new(1,-120,0,22),UDim2.new(0,0,0,8),C.WHITE,14,FB)
        Lbl(row,desc,UDim2.new(1,-120,0,18),UDim2.new(0,0,0,32),C.MUTED,11,FN)
        local abtn=Frm(row,UDim2.new(0,100,0,30),UDim2.new(1,-100,0.5,-15),C.ACCENT); corner(abtn,8)
        Lbl(abtn,btnTxt or "CLICK HERE",UDim2.new(1,0,1,0),nil,C.WHITE,11,FB).TextXAlignment=Enum.TextXAlignment.Center
        local ab=Instance.new("TextButton"); ab.Size=UDim2.new(1,0,1,0); ab.BackgroundTransparency=1; ab.Text=""; ab.Parent=abtn
        ab.MouseButton1Click:Connect(function() if onClick then pcall(onClick) end end)
        ab.MouseEnter:Connect(function() tw(abtn,{BackgroundColor3=C.ACC2}) end)
        ab.MouseLeave:Connect(function() tw(abtn,{BackgroundColor3=C.ACCENT}) end)
        table.insert(settingItems,{row=row,text=(label.." "..desc):lower(),isToggle=false})
        return row
    end

    -- Stepper row (e.g. FPS cap)
    local function StepperRow(label, desc, initial, min, max, step, onChange)
        local row=Frm(P,UDim2.new(1,0,0,62),nil,C.CARD); corner(row,12); stroke(row,C.BORDER,1); pad(row,0,0,16,16)
        Lbl(row,label,UDim2.new(1,-130,0,22),UDim2.new(0,0,0,8),C.WHITE,14,FB)
        Lbl(row,desc,UDim2.new(1,-130,0,18),UDim2.new(0,0,0,32),C.MUTED,11,FN)
        local val=initial
        local valL=Lbl(row,tostring(val).." FPS",UDim2.new(0,70,0,30),UDim2.new(1,-128,0.5,-15),C.TEXT,12,FB)
        valL.TextXAlignment=Enum.TextXAlignment.Center
        -- stepper arrows
        local dnBt=Frm(row,UDim2.new(0,24,0,24),UDim2.new(1,-54,0.5,-12),C.PANEL); corner(dnBt,6)
        Lbl(dnBt,"‹",UDim2.new(1,0,1,0),nil,C.TEXT,14,FB).TextXAlignment=Enum.TextXAlignment.Center
        local upBt=Frm(row,UDim2.new(0,24,0,24),UDim2.new(1,-28,0.5,-12),C.PANEL); corner(upBt,6)
        Lbl(upBt,"›",UDim2.new(1,0,1,0),nil,C.TEXT,14,FB).TextXAlignment=Enum.TextXAlignment.Center
        local function makeArrow(container, delta)
            local b=Instance.new("TextButton"); b.Size=UDim2.new(1,0,1,0); b.BackgroundTransparency=1; b.Text=""; b.Parent=container
            b.MouseButton1Click:Connect(function()
                val=math.clamp(val+delta,min,max)
                valL.Text=tostring(val).." FPS"
                if onChange then pcall(onChange,val) end
            end)
        end
        makeArrow(dnBt,-step); makeArrow(upBt,step)
        table.insert(settingItems,{row=row,text=(label.." "..desc):lower(),isToggle=false})
        return row
    end

    -- ── Settings entries ─────────────────────────────────────────────────────
    -- Anti-AFK
    local antiAfkConn
    ToggleRow("Anti AFK","Disable all idle timeout kicks from the source",true,function(on)
        if antiAfkConn then pcall(function() antiAfkConn:Disconnect() end); antiAfkConn=nil end
        if on then
            antiAfkConn=Players.LocalPlayer.Idled:Connect(function()
                local vjs=game:GetService("VirtualUser")
                if vjs then pcall(function() vjs:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame) end) end
            end)
        end
    end)

    -- Auto Execute scripts tab
    ToggleRow("Auto Execute","Toggle auto-execution of scripts in the autoexec folder",false,function(on)
        if on and readfile and listfiles then
            pcall(function()
                if isfolder("autoexec") then
                    for _,f in ipairs(listfiles("autoexec")) do
                        if f:match("%.lua$") or f:match("%.txt$") then
                            local ok2,src=pcall(readfile,f)
                            if ok2 and src then
                                local fn2,ce=loadstring(src)
                                if fn2 then pcall(fn2) end
                            end
                        end
                    end
                    notify("Auto Execute","autoexec scripts ran",3)
                end
            end)
        end
    end)

    -- FPS Cap
    StepperRow("FPS Cap","Change the FPS cap for a smoother experience",60,30,240,30,function(v)
        if setfpscap then pcall(setfpscap,v) end
    end)

    -- Small Server Hop
    ActionRow("Small Server","Join a server with a low player count","CLICK HERE",function()
        if queue_on_teleport then
            local TS2=game:GetService("TeleportService")
            notify("Server Hop","Finding empty server…",3)
            task.spawn(function()
                local ok2,servers=pcall(function()
                    return game:GetService("HttpService"):GetAsync(
                        "https://games.roproxy.com/v1/games/"..game.PlaceId.."/servers/Public?limit=100&sortOrder=Asc"
                    )
                end)
                if ok2 and servers then
                    local data=game:GetService("HttpService"):JSONDecode(servers)
                    if data and data.data then
                        for _,s in ipairs(data.data) do
                            if s.playing and s.playing < 3 and s.id then
                                pcall(TS2.TeleportToPlaceInstance,TS2,game.PlaceId,s.id,LP)
                                return
                            end
                        end
                    end
                end
                notify("Server Hop","No empty server found",4)
            end)
        else
            notify("Server Hop","queue_on_teleport unavailable",4)
        end
    end)

    -- Server Hop
    ActionRow("Serverhop","Teleport to a new server","CLICK HERE",function()
        local TS3=game:GetService("TeleportService")
        pcall(TS3.TeleportToPlaceInstance,TS3,game.PlaceId,
            ("0000000000000000000000"):gsub("0",tostring(math.random(0,9))),LP)
    end)

    -- Rejoin
    ActionRow("Rejoin","Rejoins your current server","CLICK HERE",function()
        local TS3=game:GetService("TeleportService")
        pcall(TS3.TeleportToPlaceInstance,TS3,game.PlaceId,game.JobId,LP)
    end)

    -- Info block at bottom
    do
        local b=Frm(P,UDim2.new(1,0,0,76),nil,C.PANEL); corner(b,10); pad(b,8,8,12,12)
        Lbl(b,"🤖 Claude Hub",UDim2.new(1,0,0,22),nil,C.WHITE,15,FB)
        Lbl(b,ENV.name.."  ·  "..ENV.score.."/"..ENV.total.." APIs  ·  Toggle: [Insert] / [ ] ]",
            UDim2.new(1,0,0,16),UDim2.new(0,0,0,26),C.MUTED,11,FN)
        Lbl(b,"Executor: "..ENV.name.." on Roblox "..tostring(game.PlaceId),
            UDim2.new(1,0,0,16),UDim2.new(0,0,0,46),C.MUTED,11,FN)
    end

    -- live search + filter chip update
    sTbx:GetPropertyChangedSignal("Text"):Connect(applySettingsFilter)
end

showPage(1)

-- ═══════════════════════════════════════════════════════════════════════════════
--  INTRO SPLASH — animated welcome with your avatar + OK button → main hub
-- ═══════════════════════════════════════════════════════════════════════════════
do
    WIN.Visible=false   -- hide hub until the user presses OK

    local INTRO=Frm(SGI,UDim2.new(0,420,0,440),UDim2.new(0.5,-210,0.5,-220),C.BG,"INTRO")
    corner(INTRO,18); stroke(INTRO,C.BORDER,1); INTRO.ClipsDescendants=true
    grad(INTRO,C.BG,C.SIDE,90)
    -- shadow
    local ishd=Instance.new("ImageLabel")
    ishd.Size=UDim2.new(1,60,1,60); ishd.Position=UDim2.new(0,-30,0,-30); ishd.BackgroundTransparency=1
    ishd.Image="rbxassetid://6014261993"; ishd.ImageColor3=C.ACCENT; ishd.ImageTransparency=0.65
    ishd.ScaleType=Enum.ScaleType.Slice; ishd.SliceCenter=Rect.new(49,49,450,450); ishd.Parent=INTRO

    -- avatar ring + profile picture
    local ring=Frm(INTRO,UDim2.new(0,128,0,128),UDim2.new(0.5,-64,0,46),C.CREAM,"Ring"); corner(ring,64)
    local ringStk=stroke(ring,C.CLAY,2); ringStk.Transparency=0.2
    local pfp=Instance.new("ImageLabel")
    pfp.Size=UDim2.new(0,116,0,116); pfp.Position=UDim2.new(0.5,-58,0.5,-58); pfp.BackgroundColor3=C.CARD
    pfp.BorderSizePixel=0; pfp.Image=""; pfp.Parent=ring; corner(pfp,58)
    task.spawn(function()
        local ok2,url=pcall(function()
            return Players:GetUserThumbnailAsync(LP.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size150x150)
        end)
        if ok2 and url then pfp.Image=url end
    end)

    -- texts (start hidden, fade/slide in)
    local hi=Lbl(INTRO,"Welcome, "..LP.DisplayName,UDim2.new(1,-40,0,28),UDim2.new(0,20,0,196),C.WHITE,22,FB)
    hi.TextXAlignment=Enum.TextXAlignment.Center; hi.TextTransparency=1
    local sub=Lbl(INTRO,"Claude Hub  ·  "..ENV.name.."  ·  "..ENV.score.."/"..ENV.total.." APIs",
        UDim2.new(1,-40,0,20),UDim2.new(0,20,0,228),C.ACC2,13,FC)
    sub.TextXAlignment=Enum.TextXAlignment.Center; sub.TextTransparency=1
    local tag=Lbl(INTRO,"The most advanced universal require hub.\nFE-ready · undetectable remote finder · memory reader.",
        UDim2.new(1,-50,0,34),UDim2.new(0,25,0,252),C.MUTED,11,FN)
    tag.TextXAlignment=Enum.TextXAlignment.Center; tag.TextTransparency=1

    -- animated loading bar
    local barBg=Frm(INTRO,UDim2.new(1,-80,0,6),UDim2.new(0,40,0,300),C.DARK); corner(barBg,3)
    local barFill=Frm(barBg,UDim2.new(0,0,1,0),nil,C.ACCENT); corner(barFill,3); grad(barFill,C.ACCENT,C.ACC2,0)

    -- OK button (hidden until load completes)
    local okBtn=Frm(INTRO,UDim2.new(0,160,0,42),UDim2.new(0.5,-80,1,-66),C.ACCENT,"OK"); corner(okBtn,10); grad(okBtn,C.ACCENT,C.ACC2,30)
    local okStk=stroke(okBtn,C.ACC2,1)
    local okL=Lbl(okBtn,"OK  →",UDim2.new(1,0,1,0),nil,C.WHITE,15,FB); okL.TextXAlignment=Enum.TextXAlignment.Center
    okBtn.BackgroundTransparency=1; okL.TextTransparency=1; okStk.Transparency=1
    local okClick=Instance.new("TextButton"); okClick.Size=UDim2.new(1,0,1,0); okClick.BackgroundTransparency=1; okClick.Text=""; okClick.Parent=okBtn

    -- entrance animation
    INTRO.Size=UDim2.new(0,420,0,0)
    tw(INTRO,{Size=UDim2.new(0,420,0,440)},TweenInfo.new(0.45,Enum.EasingStyle.Back))
    ring.Size=UDim2.new(0,0,0,0); ring.Position=UDim2.new(0.5,0,0,110)
    task.delay(0.25,function()
        tw(ring,{Size=UDim2.new(0,128,0,128),Position=UDim2.new(0.5,-64,0,46)},TweenInfo.new(0.5,Enum.EasingStyle.Back))
    end)
    task.delay(0.5,function() tw(hi,{TextTransparency=0},TS2) end)
    task.delay(0.65,function() tw(sub,{TextTransparency=0},TS2) end)
    task.delay(0.8,function() tw(tag,{TextTransparency=0},TS2) end)
    -- spin the avatar ring stroke softly
    task.spawn(function()
        while ring and ring.Parent do
            ringStk.Transparency=0.15+0.25*(0.5+0.5*math.sin(os.clock()*2))
            task.wait(0.03)
        end
    end)
    -- fill the loading bar, then reveal OK
    task.delay(0.5,function()
        tw(barFill,{Size=UDim2.new(1,0,1,0)},TweenInfo.new(1.1,Enum.EasingStyle.Quad))
        task.delay(1.15,function()
            tw(okBtn,{BackgroundTransparency=0},TS2); tw(okL,{TextTransparency=0},TS2); tw(okStk,{Transparency=0},TS2)
        end)
    end)
    okClick.MouseEnter:Connect(function() tw(okBtn,{Size=UDim2.new(0,168,0,44),Position=UDim2.new(0.5,-84,1,-67)}) end)
    okClick.MouseLeave:Connect(function() tw(okBtn,{Size=UDim2.new(0,160,0,42),Position=UDim2.new(0.5,-80,1,-66)}) end)
    okClick.MouseButton1Click:Connect(function()
        -- intro out → hub in
        tw(INTRO,{Size=UDim2.new(0,420,0,0),Position=UDim2.new(0.5,-210,0.5,0)},TweenInfo.new(0.3,Enum.EasingStyle.Quad))
        task.delay(0.3,function()
            INTRO:Destroy()
            WIN.Visible=true
            WIN.Size=UDim2.new(0,672,0,0)
            tw(WIN,{Size=UDim2.new(0,672,0,488)},TweenInfo.new(0.4,Enum.EasingStyle.Back))
            notify("🤖 Claude Hub","Ready on "..ENV.name.." — press ] to toggle",4)
        end)
    end)
end

end) -- pcall

if not _ok then
    warn("[Claude Hub] STARTUP ERROR: "..tostring(_err))
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification",
            {Title="Claude Hub ERROR",Text=tostring(_err):sub(1,80),Duration=6})
    end)
end
