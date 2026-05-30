-- ============================================================
--  Full SS Executor GUI  v3  (executor_gui.lua)
--  LocalScript | Mobile & PC | Draggable | 4 Tabs
--
--  Tab 1 – Execute   : Client/Server | loadstring/require/URL/Base64
--  Tab 2 – Deobfusc. : Pattern deobfuscator, obf-type detector
--  Tab 3 – Malware   : Scan, kill, block suspicious scripts/remotes
--  Tab 4 – UNC/SUNC  : Full UNC + SUNC function availability check
--
--  Requires SS_Executor.lua running server-side.
-- ============================================================

local Players     = game:GetService("Players")
local RepStore    = game:GetService("ReplicatedStorage")
local UIS         = game:GetService("UserInputService")
local TweenSvc    = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local LP   = Players.LocalPlayer
local PGui = LP:WaitForChild("PlayerGui")

if PGui:FindFirstChild("SS_ExecGUI") then PGui.SS_ExecGUI:Destroy() end

-- ── Bridge ────────────────────────────────────────────────
local Bridge = RepStore:FindFirstChild("SS_ExecBridge")

-- ── Theme ─────────────────────────────────────────────────
local C = {
    BG       = Color3.fromRGB(8,   8,  11),
    PANEL    = Color3.fromRGB(16,  16, 21),
    PANEL2   = Color3.fromRGB(20,  20, 27),
    INPUT    = Color3.fromRGB(11,  11, 15),
    ACCENT   = Color3.fromRGB(105, 15, 225),
    ACCHOV   = Color3.fromRGB(125, 38, 248),
    BLUE     = Color3.fromRGB(25,  120, 220),
    BLUEHOV  = Color3.fromRGB(40,  145, 245),
    DIM      = Color3.fromRGB(28,  28, 38),
    DIMTXT   = Color3.fromRGB(125, 125, 160),
    WHITE    = Color3.new(1,1,1),
    GREEN    = Color3.fromRGB(60,  210,  75),
    RED      = Color3.fromRGB(238,  60,  60),
    YELLOW   = Color3.fromRGB(255, 198,  42),
    PURPLE   = Color3.fromRGB(185, 140, 255),
    STROKE   = Color3.fromRGB(70,   8,  170),
    ORANGE   = Color3.fromRGB(240, 130,  30),
}
local TIF  = TweenInfo.new(0.14)
local TIS  = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local GBOL = Enum.Font.GothamBold
local GNRM = Enum.Font.Gotham
local GCOD = Enum.Font.Code

-- ── Helpers ───────────────────────────────────────────────
local function tw(o,p)  TweenSvc:Create(o,TIF,p):Play() end
local function tws(o,p) TweenSvc:Create(o,TIS,p):Play() end

local function rnd(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 7)
    c.Parent = p
end

local function str(p, col, th)
    local s = Instance.new("UIStroke")
    s.Color     = col or C.STROKE
    s.Thickness = th  or 1.2
    s.Parent    = p
end

local function lbl(parent, props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    for k,v in props do pcall(function() l[k]=v end) end
    l.Parent = parent
    return l
end

local function btn(parent, props)
    local b = Instance.new("TextButton")
    b.BorderSizePixel  = 0
    b.AutoButtonColor  = false
    for k,v in props do pcall(function() b[k]=v end) end
    b.Parent = parent
    return b
end

local function scrollBox(parent, pos, size)
    local sf = Instance.new("ScrollingFrame")
    sf.Position              = pos
    sf.Size                  = size
    sf.BackgroundColor3      = C.INPUT
    sf.BorderSizePixel       = 0
    sf.ScrollBarThickness    = 4
    sf.ScrollBarImageColor3  = C.ACCENT
    sf.CanvasSize            = UDim2.new(0,0,0,0)
    sf.AutomaticCanvasSize   = Enum.AutomaticSize.Y
    sf.Parent                = parent
    rnd(sf, 7)
    str(sf, Color3.fromRGB(48,4,115), 1)
    return sf
end

local function codeBox(parent, ph)
    local tb = Instance.new("TextBox")
    tb.Size               = UDim2.new(1,-10,1,0)
    tb.Position           = UDim2.new(0,5,0,5)
    tb.BackgroundTransparency = 1
    tb.Text               = ""
    tb.PlaceholderText    = ph or ""
    tb.PlaceholderColor3  = Color3.fromRGB(55,55,78)
    tb.TextColor3         = Color3.fromRGB(215,215,255)
    tb.TextSize           = 12
    tb.Font               = GCOD
    tb.MultiLine          = true
    tb.TextXAlignment     = Enum.TextXAlignment.Left
    tb.TextYAlignment     = Enum.TextYAlignment.Top
    tb.ClearTextOnFocus   = false
    tb.Parent             = parent
    return tb
end

local function hoverHook(b, norm, hov)
    b.MouseEnter:Connect(function() tw(b,{BackgroundColor3=hov})  end)
    b.MouseLeave:Connect(function() tw(b,{BackgroundColor3=norm}) end)
end

-- Call server bridge safely
local function callBridge(action, payload)
    if not Bridge then return {ok=false,msg="Bridge not found."} end
    local ok, res = pcall(Bridge.InvokeServer, Bridge, action, payload or {})
    if not ok then return {ok=false,msg=tostring(res)} end
    return res or {ok=false,msg="nil response"}
end

-- ── UNC / SUNC function list ──────────────────────────────
local UNC_LIST = {
    {"checkcaller","Closure"},  {"clonefunction","Closure"},
    {"getcallingscript","Closure"}, {"hookfunction","Closure"},
    {"iscclosure","Closure"}, {"islclosure","Closure"},
    {"newcclosure","Closure"}, {"replaceclosure","Closure"},
    {"crypt.base64decode","Crypt"}, {"crypt.base64encode","Crypt"},
    {"crypt.decrypt","Crypt"}, {"crypt.encrypt","Crypt"},
    {"crypt.generatebytes","Crypt"}, {"crypt.generatekey","Crypt"},
    {"crypt.hash","Crypt"},
    {"debug.getconstant","Debug"}, {"debug.getconstants","Debug"},
    {"debug.getinfo","Debug"}, {"debug.getproto","Debug"},
    {"debug.getprotos","Debug"}, {"debug.getstack","Debug"},
    {"debug.getupvalue","Debug"}, {"debug.getupvalues","Debug"},
    {"debug.setconstant","Debug"}, {"debug.setupvalue","Debug"},
    {"Drawing","Drawing"}, {"cleardrawcache","Drawing"},
    {"isrenderobj","Drawing"}, {"getrenderproperty","Drawing"},
    {"appendfile","FileSystem"}, {"delfile","FileSystem"},
    {"delfolder","FileSystem"}, {"isfile","FileSystem"},
    {"isfolder","FileSystem"}, {"listfiles","FileSystem"},
    {"loadfile","FileSystem"}, {"makefolder","FileSystem"},
    {"readfile","FileSystem"}, {"writefile","FileSystem"},
    {"isrbxactive","Input"}, {"isgameactive","Input"},
    {"keypress","Input"}, {"keyrelease","Input"},
    {"mouse1click","Input"}, {"mouse1press","Input"},
    {"mouse1release","Input"}, {"mouse2click","Input"},
    {"mouse2press","Input"}, {"mouse2release","Input"},
    {"mousemoveabs","Input"}, {"mousemoverel","Input"},
    {"mousescroll","Input"},
    {"fireclickdetector","Instance"}, {"fireproximityprompt","Instance"},
    {"firetouchinterest","Instance"}, {"getcustomasset","Instance"},
    {"gethiddenproperty","Instance"}, {"gethui","Instance"},
    {"getinstances","Instance"}, {"getnilinstances","Instance"},
    {"isscriptable","Instance"}, {"sethiddenproperty","Instance"},
    {"setscriptable","Instance"},
    {"getrawmetatable","Metatable"}, {"hookmetamethod","Metatable"},
    {"setrawmetatable","Metatable"}, {"setreadonly","Metatable"},
    {"isreadonly","Metatable"},
    {"getexecutorname","Misc"}, {"identifyexecutor","Misc"},
    {"gethwid","Misc"}, {"isluau","Misc"},
    {"lz4compress","Misc"}, {"lz4decompress","Misc"},
    {"messagebox","Misc"}, {"queue_on_teleport","Misc"},
    {"queueonteleport","Misc"}, {"setfpscap","Misc"},
    {"getfpscap","Misc"}, {"setclipboard","Misc"},
    {"toclipboard","Misc"}, {"getclipboard","Misc"},
    {"saveinstance","Misc"},
    {"getgc","Scripts"}, {"getgenv","Scripts"},
    {"getloadedmodules","Scripts"}, {"getrunningscripts","Scripts"},
    {"getscripts","Scripts"}, {"getrenv","Scripts"},
    {"getsenv","Scripts"},
    {"getconnections","Signal"}, {"firesignal","Signal"},
    {"getthreadidentity","Thread"}, {"setthreadidentity","Thread"},
    {"getidentity","Thread"}, {"setidentity","Thread"},
    {"request","HTTP"}, {"http_request","HTTP"},
    {"cache.invalidate","Cache"}, {"cache.iscached","Cache"},
    {"cache.replace","Cache"},
    {"WebSocket","WebSocket"},
}

local function hasUNC(name)
    if name:find("%.") then
        local tbl, key = name:match("^(.-)%.(.+)$")
        local t = rawget(_G, tbl)
        if t == nil then
            local ok2, v = pcall(function() return _G[tbl] end)
            t = ok2 and v or nil
        end
        if type(t) == "table" then
            return rawget(t, key) ~= nil
        end
        return false
    end
    if rawget(_G, name) ~= nil then return true end
    local ok, v = pcall(function()
        local env = (getfenv and getfenv()) or _G
        return rawget(env, name)
    end)
    return ok and v ~= nil
end

-- ── Deobfuscator ──────────────────────────────────────────
local function detectObfType(src)
    if src:find("This%s+file%s+was%s+protected%s+using%s+Luraph") or src:find("lura%.ph") then
        return "Luraph"
    elseif src:find("IronBrew") or src:find("Iron%s*Brew") then
        return "IronBrew 2"
    elseif src:find("Prometheus") then
        return "Prometheus"
    elseif src:find("Moonsec") then
        return "Moonsec"
    elseif src:find("PSU") and src:find("obfuscated") then
        return "PSU (Peasant)"
    elseif src:find("_0x%x+") and #src > 500 then
        return "Hex-var obfuscated"
    elseif src:find("string%.byte") and src:find("string%.char") and #src > 2000 then
        return "String-table VM"
    elseif src:find("local%s+[A-Z][A-Z0-9]*%s*=%s*{") and #src > 3000 then
        return "Custom VM / bytecode"
    end
    return "Unknown / Custom"
end

local function deobfuscate(src)
    local out = src
    local log = {}

    -- Hex escapes  \x41 → A
    local n
    out, n = out:gsub("\\x(%x%x)", function(h)
        return string.char(tonumber(h, 16))
    end)
    if n > 0 then log[#log+1] = "Decoded "..n.." hex escape(s)" end

    -- Decimal escapes  \65 → A
    out, n = out:gsub("\\(%d%d?%d?)", function(d)
        local v = tonumber(d)
        if v and v >= 32 and v <= 126 then return string.char(v) end
        return "\\"..d
    end)
    if n > 0 then log[#log+1] = "Decoded "..n.." decimal escape(s)" end

    -- string.char fold  string.char(72,101,108) → "Hel"
    out = out:gsub("string%.char%(([%d,%s]+)%)", function(args)
        local chars = {}
        for num in args:gmatch("%d+") do
            local v = tonumber(num)
            if not v or v < 32 or v > 126 then return "string.char("..args..")" end
            chars[#chars+1] = string.char(v)
        end
        log[#log+1] = "Folded string.char call"
        return '"'..table.concat(chars):gsub('"','\\"')..'"'
    end)

    -- String concat fold  "a" .. "b" → "ab"
    local changed = true
    local folds = 0
    while changed do
        changed = false
        out = out:gsub('"([^"\\]*)"%s*%.%.%s*"([^"\\]*)"', function(a, b)
            changed = true ; folds += 1 ; return '"'..a..b..'"'
        end)
    end
    if folds > 0 then log[#log+1] = "Folded "..folds.." concat(s)" end

    -- Collapse multiple blank lines
    out = out:gsub("\n\n\n+", "\n\n")

    local steps = #log > 0 and table.concat(log, "  |  ") or "No simplifications applied."
    return out, steps
end

-- ── Base64 decode (used for exec type) ───────────────────
local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function b64decode(data)
    data = data:gsub("[^"..B64.."=]","")
    return (data:gsub(".", function(x)
        if x == "=" then return "" end
        local r, f = "", (B64:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and "1" or "0") end
        return r
    end):gsub("%d%d%d%d%d%d%d%d", function(x)
        local n = 0
        for i=1,8 do n = n + (x:sub(i,i)=="1" and 2^(8-i) or 0) end
        return string.char(n)
    end))
end

-- ── Root GUI ──────────────────────────────────────────────
local SG = Instance.new("ScreenGui")
SG.Name           = "SS_ExecGUI"
SG.ResetOnSpawn   = false
SG.DisplayOrder   = 999
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.Parent         = PGui

local WIN_W, WIN_H = 520, 420

local Win = Instance.new("Frame")
Win.Name             = "Win"
Win.Size             = UDim2.new(0,WIN_W,0,WIN_H)
Win.Position         = UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2)
Win.BackgroundColor3 = C.BG
Win.BorderSizePixel  = 0
Win.ClipsDescendants = true
Win.Parent           = SG
rnd(Win, 10)
str(Win, C.STROKE, 1.5)

-- ── Title bar ─────────────────────────────────────────────
local TBar = Instance.new("Frame")
TBar.Name             = "TBar"
TBar.Size             = UDim2.new(1,0,0,40)
TBar.BackgroundColor3 = C.PANEL
TBar.BorderSizePixel  = 0
TBar.ZIndex           = 4
TBar.Parent           = Win
rnd(TBar,10)
-- Patch bottom corners
local TBP = Instance.new("Frame")
TBP.Size=UDim2.new(1,0,0.5,0) TBP.Position=UDim2.new(0,0,0.5,0)
TBP.BackgroundColor3=C.PANEL TBP.BorderSizePixel=0 TBP.ZIndex=4 TBP.Parent=TBar

lbl(TBar,{
    Size=UDim2.new(1,-110,1,0), Position=UDim2.new(0,12,0,0),
    Text="  Full SS Executor", TextColor3=C.PURPLE,
    TextSize=14, Font=GBOL, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=5
})

local DotLbl = lbl(Win,{
    Size=UDim2.new(0,180,0,14), Position=UDim2.new(0,12,0,26),
    Text="● Connecting...", TextColor3=C.YELLOW,
    TextSize=10, Font=GNRM, TextXAlignment=Enum.TextXAlignment.Left,
})

local function mkTitleBtn(text, bg, xOff)
    local b = btn(TBar,{
        Size=UDim2.new(0,30,0,24),
        Position=UDim2.new(1,xOff,0.5,-12),
        BackgroundColor3=bg, Text=text,
        TextColor3=C.WHITE, TextSize=12, Font=GBOL, ZIndex=5,
    })
    rnd(b,5)
    return b
end

local MinBtn   = mkTitleBtn("—", C.DIM,            -68)
local CloseBtn = mkTitleBtn("✕", Color3.fromRGB(195,36,52), -32)

-- ── Tab bar ───────────────────────────────────────────────
local TABS_Y = 40
local TabBar = Instance.new("Frame")
TabBar.Size             = UDim2.new(1,-20,0,34)
TabBar.Position         = UDim2.new(0,10,0,TABS_Y+4)
TabBar.BackgroundColor3 = C.PANEL
TabBar.BorderSizePixel  = 0
TabBar.Parent           = Win
rnd(TabBar,8)

local TAB_NAMES = {"Execute","Deobfusc.","Malware","UNC/SUNC"}
local tabBtns, tabFrames = {}, {}

do
    local layout = Instance.new("UIListLayout")
    layout.FillDirection=Enum.FillDirection.Horizontal
    layout.HorizontalAlignment=Enum.HorizontalAlignment.Center
    layout.VerticalAlignment=Enum.VerticalAlignment.Center
    layout.Padding=UDim.new(0,4)
    layout.Parent=TabBar

    for i, name in TAB_NAMES do
        local b = btn(TabBar,{
            Size=UDim2.new(0,112,1,-8),
            BackgroundColor3=C.DIM,
            Text=name, TextColor3=C.DIMTXT,
            TextSize=11, Font=GBOL,
        })
        rnd(b,5)
        tabBtns[i] = b
    end
end

-- Content area
local CONTENT_Y = TABS_Y + 4 + 34 + 4   -- 82

local Body = Instance.new("Frame")
Body.Name="Body" Body.Size=UDim2.new(1,0,1,-CONTENT_Y)
Body.Position=UDim2.new(0,0,0,CONTENT_Y)
Body.BackgroundTransparency=1 Body.Parent=Win

local BODY_H = WIN_H - CONTENT_Y  -- 338

-- Helper: make a tab content frame
local function makeTabFrame()
    local f = Instance.new("Frame")
    f.Size=UDim2.new(1,0,1,0)
    f.BackgroundTransparency=1
    f.Visible=false
    f.Parent=Body
    return f
end

-- ══════════════════════════════════════════════════════════
-- TAB 1 – EXECUTE
-- ══════════════════════════════════════════════════════════
local T1 = makeTabFrame()

-- Mode bar
local ModeBar = Instance.new("Frame")
ModeBar.Size=UDim2.new(1,-20,0,34) ModeBar.Position=UDim2.new(0,10,0,8)
ModeBar.BackgroundColor3=C.PANEL ModeBar.BorderSizePixel=0 ModeBar.Parent=T1
rnd(ModeBar,8)

local function modeBtn(text, x, off)
    local b=btn(ModeBar,{
        Size=UDim2.new(0.5,-5,1,-8), Position=UDim2.new(x,off,0,4),
        BackgroundColor3=C.DIM, Text=text,
        TextColor3=C.DIMTXT, TextSize=12, Font=GBOL,
    })
    rnd(b,5) return b
end
local ClientTab = modeBtn("  Client Side",  0, 4)
local ServerTab = modeBtn("  Server Side",  0.5, 1)

-- Sub-mode bar  (server only)
local SubBar = Instance.new("Frame")
SubBar.Size=UDim2.new(1,-20,0,28) SubBar.Position=UDim2.new(0,10,0,48)
SubBar.BackgroundColor3=C.PANEL SubBar.BorderSizePixel=0
SubBar.Visible=false SubBar.Parent=T1
rnd(SubBar,7)

local function subBtn(text, x, off)
    local b=btn(SubBar,{
        Size=UDim2.new(0.5,-5,1,-6), Position=UDim2.new(x,off,0,3),
        BackgroundColor3=C.DIM, Text=text,
        TextColor3=C.DIMTXT, TextSize=11, Font=GBOL,
    })
    rnd(b,5) return b
end
local SubLS  = subBtn("loadstring", 0,   4)
local SubReq = subBtn("require",    0.5, 1)

-- Code type bar  (normal / url / base64)
local TypeBar = Instance.new("Frame")
TypeBar.Size=UDim2.new(1,-20,0,24) TypeBar.Position=UDim2.new(0,10,0,82)
TypeBar.BackgroundColor3=C.PANEL TypeBar.BorderSizePixel=0 TypeBar.Parent=T1
rnd(TypeBar,6)

do
    local layout=Instance.new("UIListLayout")
    layout.FillDirection=Enum.FillDirection.Horizontal
    layout.HorizontalAlignment=Enum.HorizontalAlignment.Center
    layout.VerticalAlignment=Enum.VerticalAlignment.Center
    layout.Padding=UDim.new(0,4)
    layout.Parent=TypeBar
end

local codeTypeBtns = {}
for i,label in {"Normal","URL","Base64"} do
    local b=btn(TypeBar,{
        Size=UDim2.new(0,95,1,-6),
        BackgroundColor3 = i==1 and C.ACCENT or C.DIM,
        Text=label, TextColor3 = i==1 and C.WHITE or C.DIMTXT,
        TextSize=10, Font=GBOL,
    })
    rnd(b,4)
    codeTypeBtns[i]=b
end

-- Hint label
local ExecHint = lbl(T1,{
    Size=UDim2.new(1,-20,0,14), Position=UDim2.new(0,10,0,112),
    Text="Client Side  →  loadstring(code)()", TextColor3=Color3.fromRGB(90,55,170),
    TextSize=10, Font=GNRM, TextXAlignment=Enum.TextXAlignment.Left,
})

-- Code editor
local ExecScroll = scrollBox(T1, UDim2.new(0,10,0,130), UDim2.new(1,-20,0,140))
local CodeBox    = codeBox(ExecScroll,"-- Paste or type script here...")

-- Status
local ExecStatus = lbl(T1,{
    Size=UDim2.new(1,-20,0,15), Position=UDim2.new(0,10,0,278),
    Text="Ready.", TextColor3=C.DIMTXT,
    TextSize=10, Font=GNRM, TextXAlignment=Enum.TextXAlignment.Left,
})

-- Button row
local ExecRow = Instance.new("Frame")
ExecRow.Size=UDim2.new(1,-20,0,36) ExecRow.Position=UDim2.new(0,10,0,296)
ExecRow.BackgroundTransparency=1 ExecRow.Parent=T1
do
    local l=Instance.new("UIListLayout")
    l.FillDirection=Enum.FillDirection.Horizontal
    l.VerticalAlignment=Enum.VerticalAlignment.Center
    l.Padding=UDim.new(0,7)
    l.Parent=ExecRow
end

local function execBtn(text,bg,w)
    local b=btn(ExecRow,{Size=UDim2.new(0,w,0,32),BackgroundColor3=bg,
        Text=text,TextColor3=C.WHITE,TextSize=12,Font=GBOL})
    rnd(b,6) return b
end

local ExecBtn  = execBtn("  Execute", C.ACCENT, 120)
local ClearBtn = execBtn("Clear",     C.DIM,    72)
local CopyBtn  = execBtn("Copy",      C.DIM,    66)
local URLBtn   = execBtn("From URL",  C.DIM,    82)
ClearBtn.TextColor3=C.DIMTXT CopyBtn.TextColor3=C.DIMTXT URLBtn.TextColor3=C.DIMTXT

-- ── Execute state ─────────────────────────────────────────
local mode     = "client"   -- "client"|"server"
local subMode  = "ls"       -- "ls"|"req"
local codeType = "normal"   -- "normal"|"url"|"base64"

local function setExecStatus(msg, col)
    ExecStatus.Text=msg ExecStatus.TextColor3=col or C.DIMTXT
end

local function applyExecMode(m)
    mode = m
    local isServ = m=="server"
    SubBar.Visible = isServ
    if isServ then
        tw(ServerTab,{BackgroundColor3=C.BLUE,  TextColor3=C.WHITE  })
        tw(ClientTab,{BackgroundColor3=C.DIM,   TextColor3=C.DIMTXT })
        ExecBtn.BackgroundColor3=C.BLUE
        if subMode=="ls" then
            ExecHint.Text="Server Side  →  loadstring(code)()  [full server perms]"
        else
            ExecHint.Text="Server Side  →  require(assetId)  [numeric ID required]"
        end
    else
        tw(ClientTab,{BackgroundColor3=C.ACCENT, TextColor3=C.WHITE  })
        tw(ServerTab,{BackgroundColor3=C.DIM,    TextColor3=C.DIMTXT })
        ExecBtn.BackgroundColor3=C.ACCENT
        ExecHint.Text="Client Side  →  loadstring(code)()  [your client]"
    end
end

local function applySubMode(s)
    subMode=s
    if s=="ls" then
        tw(SubLS, {BackgroundColor3=C.BLUE, TextColor3=C.WHITE  })
        tw(SubReq,{BackgroundColor3=C.DIM,  TextColor3=C.DIMTXT })
        CodeBox.PlaceholderText="-- Server-side script (full permissions)..."
    else
        tw(SubReq,{BackgroundColor3=C.BLUE, TextColor3=C.WHITE  })
        tw(SubLS, {BackgroundColor3=C.DIM,  TextColor3=C.DIMTXT })
        CodeBox.PlaceholderText="-- Enter numeric Asset ID for require()..."
    end
    if mode=="server" then
        ExecHint.Text = subMode=="ls"
            and "Server Side  →  loadstring(code)()  [full server perms]"
            or  "Server Side  →  require(assetId)  [numeric ID required]"
    end
end

local function applyCodeType(t)
    codeType=t
    local names={"Normal","URL","Base64"}
    for i,b in codeTypeBtns do
        local active=(names[i]:lower()==t)
        tw(b,{BackgroundColor3=active and C.ACCENT or C.DIM,
              TextColor3=active and C.WHITE or C.DIMTXT})
    end
end

applyExecMode("client") applySubMode("ls") applyCodeType("normal")

ClientTab.MouseButton1Click:Connect(function() applyExecMode("client") end)
ServerTab.MouseButton1Click:Connect(function() applyExecMode("server") end)
SubLS.MouseButton1Click:Connect(function()     applySubMode("ls")      end)
SubReq.MouseButton1Click:Connect(function()    applySubMode("req")     end)
codeTypeBtns[1].MouseButton1Click:Connect(function() applyCodeType("normal")  end)
codeTypeBtns[2].MouseButton1Click:Connect(function() applyCodeType("url")     end)
codeTypeBtns[3].MouseButton1Click:Connect(function() applyCodeType("base64")  end)

-- Execute handler
ExecBtn.MouseButton1Click:Connect(function()
    local raw = CodeBox.Text
    if raw=="" or raw:match("^%s*$") then
        setExecStatus("Nothing to execute.", C.YELLOW) return
    end
    setExecStatus("Executing...", C.YELLOW)

    if mode=="client" then
        -- Resolve code
        local code = raw
        if codeType=="url" then
            local ok,src=pcall(function() return game:HttpGet(raw,true) end)
            if not ok then setExecStatus("HTTP error: "..tostring(src):sub(1,70),C.RED) return end
            code=src
        elseif codeType=="base64" then
            local ok,dec=pcall(b64decode,raw)
            if not ok then setExecStatus("Base64 decode failed.",C.RED) return end
            code=dec
        end
        local fn,err=loadstring(code)
        if not fn then setExecStatus("Compile: "..tostring(err):sub(1,70),C.RED) return end
        local ok,e=pcall(fn)
        if ok then setExecStatus("Executed on client.", C.GREEN)
        else       setExecStatus("Runtime: "..tostring(e):sub(1,70),C.RED) end
    else
        -- Server path
        local action
        local payload={}
        if subMode=="req" then
            action="req" payload.id=raw
        elseif codeType=="url" then
            action="ls_url" payload.url=raw
        else
            local code=raw
            if codeType=="base64" then
                local ok,dec=pcall(b64decode,raw)
                if not ok then setExecStatus("Base64 decode failed.",C.RED) return end
                code=dec
            end
            action="ls" payload.code=code
        end
        local res=callBridge(action,payload)
        if res.ok then setExecStatus(tostring(res.msg),C.GREEN)
        else           setExecStatus(tostring(res.msg):sub(1,80),C.RED) end
    end
end)

ClearBtn.MouseButton1Click:Connect(function()
    CodeBox.Text="" setExecStatus("Cleared.",C.DIMTXT)
end)
CopyBtn.MouseButton1Click:Connect(function()
    if setclipboard then setclipboard(CodeBox.Text) setExecStatus("Copied.",C.PURPLE)
    else setExecStatus("setclipboard not available.",C.YELLOW) end
end)
URLBtn.MouseButton1Click:Connect(function()
    applyCodeType("url")
    CodeBox.Text=""
    CodeBox.PlaceholderText="https://raw.githubusercontent.com/..."
    setExecStatus("Paste a raw script URL and press Execute.",C.YELLOW)
end)

hoverHook(ExecBtn, C.ACCENT, C.ACCHOV)
hoverHook(ClearBtn,C.DIM, Color3.fromRGB(40,40,54))
hoverHook(CopyBtn, C.DIM, Color3.fromRGB(40,40,54))
hoverHook(URLBtn,  C.DIM, Color3.fromRGB(40,40,54))

-- ══════════════════════════════════════════════════════════
-- TAB 2 – DEOBFUSCATE
-- ══════════════════════════════════════════════════════════
local T2 = makeTabFrame()

lbl(T2,{Size=UDim2.new(1,-20,0,14),Position=UDim2.new(0,10,0,6),
    Text="Obfuscated Input:",TextColor3=C.DIMTXT,TextSize=11,Font=GBOL,
    TextXAlignment=Enum.TextXAlignment.Left})

local DeobfIn    = scrollBox(T2, UDim2.new(0,10,0,24), UDim2.new(1,-20,0,108))
local DeobfInBox = codeBox(DeobfIn, "-- Paste obfuscated script here...")

-- Detect row
local DetectRow=Instance.new("Frame")
DetectRow.Size=UDim2.new(1,-20,0,30) DetectRow.Position=UDim2.new(0,10,0,138)
DetectRow.BackgroundTransparency=1 DetectRow.Parent=T2
do
    local l=Instance.new("UIListLayout")
    l.FillDirection=Enum.FillDirection.Horizontal
    l.VerticalAlignment=Enum.VerticalAlignment.Center
    l.Padding=UDim.new(0,8)
    l.Parent=DetectRow
end

local DetectBtn=btn(DetectRow,{Size=UDim2.new(0,110,0,28),
    BackgroundColor3=C.DIM,Text="Detect Type",
    TextColor3=C.WHITE,TextSize=11,Font=GBOL})
rnd(DetectBtn,6)

local DeobfBtn=btn(DetectRow,{Size=UDim2.new(0,120,0,28),
    BackgroundColor3=C.ACCENT,Text="Deobfuscate",
    TextColor3=C.WHITE,TextSize=11,Font=GBOL})
rnd(DeobfBtn,6)

local ObfTypeLbl=lbl(DetectRow,{
    Size=UDim2.new(0,210,0,28),
    Text="Type: —", TextColor3=C.YELLOW,
    TextSize=11, Font=GNRM, TextXAlignment=Enum.TextXAlignment.Left,
})

-- Steps hint
local StepsLbl=lbl(T2,{
    Size=UDim2.new(1,-20,0,14),Position=UDim2.new(0,10,0,174),
    Text="Steps: —",TextColor3=Color3.fromRGB(80,55,155),
    TextSize=10,Font=GNRM,TextXAlignment=Enum.TextXAlignment.Left,
})

lbl(T2,{Size=UDim2.new(1,-20,0,14),Position=UDim2.new(0,10,0,192),
    Text="Deobfuscated Output:",TextColor3=C.DIMTXT,TextSize=11,Font=GBOL,
    TextXAlignment=Enum.TextXAlignment.Left})

local DeobfOut    = scrollBox(T2, UDim2.new(0,10,0,210), UDim2.new(1,-20,0,96))
local DeobfOutBox = codeBox(DeobfOut,"-- Output appears here...")
DeobfOutBox.TextEditable=false

-- Bottom buttons
local DeobfBtmRow=Instance.new("Frame")
DeobfBtmRow.Size=UDim2.new(1,-20,0,26) DeobfBtmRow.Position=UDim2.new(0,10,0,311)
DeobfBtmRow.BackgroundTransparency=1 DeobfBtmRow.Parent=T2
do
    local l=Instance.new("UIListLayout")
    l.FillDirection=Enum.FillDirection.Horizontal
    l.VerticalAlignment=Enum.VerticalAlignment.Center
    l.Padding=UDim.new(0,8)
    l.Parent=DeobfBtmRow
end

local CopyOutBtn=btn(DeobfBtmRow,{Size=UDim2.new(0,110,0,24),
    BackgroundColor3=C.DIM,Text="Copy Output",
    TextColor3=C.DIMTXT,TextSize=11,Font=GBOL})
rnd(CopyOutBtn,5)

local ExecDeobfBtn=btn(DeobfBtmRow,{Size=UDim2.new(0,140,0,24),
    BackgroundColor3=C.ACCENT,Text="Execute Output",
    TextColor3=C.WHITE,TextSize=11,Font=GBOL})
rnd(ExecDeobfBtn,5)

-- Deobfuscate logic
DetectBtn.MouseButton1Click:Connect(function()
    local src=DeobfInBox.Text
    if src=="" then return end
    ObfTypeLbl.Text="Type: "..detectObfType(src)
end)

DeobfBtn.MouseButton1Click:Connect(function()
    local src=DeobfInBox.Text
    if src=="" or src:match("^%s*$") then return end
    ObfTypeLbl.Text="Type: "..detectObfType(src)
    local out,steps=deobfuscate(src)
    DeobfOutBox.Text=out
    StepsLbl.Text="Steps: "..steps
end)

CopyOutBtn.MouseButton1Click:Connect(function()
    if setclipboard and DeobfOutBox.Text~="" then
        setclipboard(DeobfOutBox.Text)
        ObfTypeLbl.Text="Copied!"
        task.delay(1.5,function() ObfTypeLbl.Text="Type: —" end)
    end
end)

ExecDeobfBtn.MouseButton1Click:Connect(function()
    local code=DeobfOutBox.Text
    if code=="" then return end
    local fn,err=loadstring(code)
    if not fn then ObfTypeLbl.Text="Compile: "..tostring(err):sub(1,40) return end
    local ok,e=pcall(fn)
    ObfTypeLbl.Text = ok and "Executed!" or "Error: "..tostring(e):sub(1,40)
end)

hoverHook(DeobfBtn,    C.ACCENT, C.ACCHOV)
hoverHook(DetectBtn,   C.DIM,    Color3.fromRGB(40,40,54))
hoverHook(CopyOutBtn,  C.DIM,    Color3.fromRGB(40,40,54))
hoverHook(ExecDeobfBtn,C.ACCENT, C.ACCHOV)

-- ══════════════════════════════════════════════════════════
-- TAB 3 – ANTI-MALWARE
-- ══════════════════════════════════════════════════════════
local T3 = makeTabFrame()

-- Top button row
local MalRow=Instance.new("Frame")
MalRow.Size=UDim2.new(1,-20,0,34) MalRow.Position=UDim2.new(0,10,0,8)
MalRow.BackgroundTransparency=1 MalRow.Parent=T3
do
    local l=Instance.new("UIListLayout")
    l.FillDirection=Enum.FillDirection.Horizontal
    l.VerticalAlignment=Enum.VerticalAlignment.Center
    l.Padding=UDim.new(0,8)
    l.Parent=MalRow
end

local function malBtn(text,bg,w)
    local b=btn(MalRow,{Size=UDim2.new(0,w,0,30),BackgroundColor3=bg,
        Text=text,TextColor3=C.WHITE,TextSize=11,Font=GBOL})
    rnd(b,6) return b
end

local ScanBtn     = malBtn("  Scan Game",    C.BLUE,   120)
local KillAllBtn  = malBtn("Kill All",       C.RED,    80)
local BlockRmtBtn = malBtn("Block Remotes",  C.ORANGE, 110)

-- Status
local MalStatus=lbl(T3,{
    Size=UDim2.new(1,-20,0,15),Position=UDim2.new(0,10,0,48),
    Text="Press Scan to detect threats.",
    TextColor3=C.DIMTXT,TextSize=10,Font=GNRM,
    TextXAlignment=Enum.TextXAlignment.Left,
})

-- Findings list
local FindScroll=Instance.new("ScrollingFrame")
FindScroll.Size=UDim2.new(1,-20,0,244) FindScroll.Position=UDim2.new(0,10,0,68)
FindScroll.BackgroundColor3=C.PANEL FindScroll.BorderSizePixel=0
FindScroll.ScrollBarThickness=4 FindScroll.ScrollBarImageColor3=C.ACCENT
FindScroll.CanvasSize=UDim2.new(0,0,0,0)
FindScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
FindScroll.Parent=T3
rnd(FindScroll,7) str(FindScroll,Color3.fromRGB(35,5,85),1)

local FindLayout=Instance.new("UIListLayout")
FindLayout.Padding=UDim.new(0,2)
FindLayout.SortOrder=Enum.SortOrder.LayoutOrder
FindLayout.Parent=FindScroll

local FindPad=Instance.new("UIPadding")
FindPad.PaddingTop=UDim.new(0,4) FindPad.PaddingLeft=UDim.new(0,4)
FindPad.PaddingRight=UDim.new(0,4) FindPad.Parent=FindScroll

-- Auto-monitor toggle row
local AutoRow=Instance.new("Frame")
AutoRow.Size=UDim2.new(1,-20,0,22) AutoRow.Position=UDim2.new(0,10,0,318)
AutoRow.BackgroundTransparency=1 AutoRow.Parent=T3
do
    local l=Instance.new("UIListLayout")
    l.FillDirection=Enum.FillDirection.Horizontal
    l.VerticalAlignment=Enum.VerticalAlignment.Center
    l.Padding=UDim.new(0,8)
    l.Parent=AutoRow
end
local autoMonOn=false
local AutoBtn=btn(AutoRow,{Size=UDim2.new(0,130,0,20),BackgroundColor3=C.DIM,
    Text="Auto-Monitor: OFF",TextColor3=C.DIMTXT,TextSize=10,Font=GBOL})
rnd(AutoBtn,4)
lbl(AutoRow,{Size=UDim2.new(0,250,0,20),
    Text="Auto scans every 30s and kills new threats",
    TextColor3=Color3.fromRGB(65,65,90),TextSize=9,Font=GNRM,
    TextXAlignment=Enum.TextXAlignment.Left})

-- Findings management
local currentFindings = {}

local function clearFindings()
    currentFindings={}
    for _,c in FindScroll:GetChildren() do
        if c:IsA("Frame") then c:Destroy() end
    end
end

local function addFindingRow(finding, i)
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,40)
    row.BackgroundColor3=C.PANEL2
    row.BorderSizePixel=0
    row.LayoutOrder=i
    row.Parent=FindScroll
    rnd(row,5)

    -- Kind badge
    local kindCol = finding.kind:find("Script") and C.ORANGE or C.RED
    local badge=btn(row,{Size=UDim2.new(0,68,0,20),Position=UDim2.new(0,6,0.5,-10),
        BackgroundColor3=kindCol,Text=finding.kind:sub(1,10),
        TextColor3=C.WHITE,TextSize=9,Font=GBOL})
    rnd(badge,4)

    -- Path label
    lbl(row,{Size=UDim2.new(1,-210,0,14),Position=UDim2.new(0,82,0,4),
        Text=finding.path:sub(-48),TextColor3=C.WHITE,TextSize=10,Font=GCOD,
        TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd})
    lbl(row,{Size=UDim2.new(1,-210,0,12),Position=UDim2.new(0,82,0,20),
        Text=finding.detail,TextColor3=C.DIMTXT,TextSize=9,Font=GNRM,
        TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd})

    -- Kill button
    local killBtn=btn(row,{Size=UDim2.new(0,50,0,24),Position=UDim2.new(1,-112,0.5,-12),
        BackgroundColor3=C.RED,Text="Kill",TextColor3=C.WHITE,TextSize=10,Font=GBOL})
    rnd(killBtn,5)

    -- Block button (for remotes)
    local blockBtn=btn(row,{Size=UDim2.new(0,54,0,24),Position=UDim2.new(1,-54,0.5,-12),
        BackgroundColor3=C.ORANGE,Text="Block",TextColor3=C.WHITE,TextSize=10,Font=GBOL})
    rnd(blockBtn,5)
    blockBtn.Visible = finding.kind:find("Remote")~=nil

    killBtn.MouseButton1Click:Connect(function()
        local res=callBridge("kill",{path=finding.path})
        if res.ok then
            row:Destroy()
            MalStatus.Text="Killed: "..finding.path:sub(-50)
            MalStatus.TextColor3=C.GREEN
        else
            MalStatus.Text="Failed: "..tostring(res.msg)
            MalStatus.TextColor3=C.RED
        end
    end)

    blockBtn.MouseButton1Click:Connect(function()
        local res=callBridge("block_remote",{path=finding.path})
        MalStatus.Text=tostring(res.msg)
        MalStatus.TextColor3=res.ok and C.GREEN or C.RED
    end)
end

local function runScan()
    MalStatus.Text="Scanning..." MalStatus.TextColor3=C.YELLOW
    clearFindings()
    local res=callBridge("scan")
    if not res.ok then
        MalStatus.Text="Scan failed: "..tostring(res.msg)
        MalStatus.TextColor3=C.RED return
    end
    local data=res.data or {}
    if #data==0 then
        MalStatus.Text="Clean! No threats found."
        MalStatus.TextColor3=C.GREEN return
    end
    for i,line in data do
        local kind,path,detail=line:match("^(.-)|(.-)|(.*)")
        local f={kind=kind or"?",path=path or"?",detail=detail or"?"}
        currentFindings[i]=f
        addFindingRow(f,i)
    end
    MalStatus.Text=tostring(res.msg).." – review and kill below."
    MalStatus.TextColor3=C.ORANGE
end

ScanBtn.MouseButton1Click:Connect(function() task.spawn(runScan) end)

KillAllBtn.MouseButton1Click:Connect(function()
    MalStatus.Text="Killing all..." MalStatus.TextColor3=C.YELLOW
    local res=callBridge("kill_all")
    MalStatus.Text=tostring(res.msg)
    MalStatus.TextColor3=res.ok and C.GREEN or C.RED
    if res.ok then clearFindings() end
end)

BlockRmtBtn.MouseButton1Click:Connect(function()
    local blocked=0
    for _,f in currentFindings do
        if f.kind:find("Remote") then
            local r=callBridge("block_remote",{path=f.path})
            if r.ok then blocked+=1 end
        end
    end
    MalStatus.Text="Blocked "..blocked.." remote(s)."
    MalStatus.TextColor3=C.GREEN
end)

-- Auto-monitor
local autoConn
AutoBtn.MouseButton1Click:Connect(function()
    autoMonOn = not autoMonOn
    if autoMonOn then
        tw(AutoBtn,{BackgroundColor3=C.GREEN}) AutoBtn.Text="Auto-Monitor: ON"
        AutoBtn.TextColor3=C.BG
        autoConn=task.spawn(function()
            while autoMonOn do
                task.wait(30)
                if autoMonOn then task.spawn(runScan) end
            end
        end)
    else
        tw(AutoBtn,{BackgroundColor3=C.DIM}) AutoBtn.Text="Auto-Monitor: OFF"
        AutoBtn.TextColor3=C.DIMTXT
        autoMonOn=false
    end
end)

hoverHook(ScanBtn,    C.BLUE,   C.BLUEHOV)
hoverHook(KillAllBtn, C.RED,    Color3.fromRGB(255,80,80))
hoverHook(BlockRmtBtn,C.ORANGE, Color3.fromRGB(255,150,50))

-- ══════════════════════════════════════════════════════════
-- TAB 4 – UNC / SUNC
-- ══════════════════════════════════════════════════════════
local T4 = makeTabFrame()

-- Executor info row
local ExecInfoRow=Instance.new("Frame")
ExecInfoRow.Size=UDim2.new(1,-20,0,28) ExecInfoRow.Position=UDim2.new(0,10,0,6)
ExecInfoRow.BackgroundTransparency=1 ExecInfoRow.Parent=T4
do
    local l=Instance.new("UIListLayout")
    l.FillDirection=Enum.FillDirection.Horizontal
    l.VerticalAlignment=Enum.VerticalAlignment.Center
    l.Padding=UDim.new(0,8)
    l.Parent=ExecInfoRow
end

local ExecNameLbl=lbl(ExecInfoRow,{
    Size=UDim2.new(0,240,1,0),
    Text="Executor: detecting...",TextColor3=C.PURPLE,
    TextSize=11,Font=GBOL,TextXAlignment=Enum.TextXAlignment.Left})

local SupportedLbl=lbl(ExecInfoRow,{
    Size=UDim2.new(0,150,1,0),
    Text="",TextColor3=C.DIMTXT,
    TextSize=10,Font=GNRM,TextXAlignment=Enum.TextXAlignment.Left})

local UNCRefreshBtn=btn(ExecInfoRow,{Size=UDim2.new(0,72,0,24),
    BackgroundColor3=C.ACCENT,Text="Refresh",
    TextColor3=C.WHITE,TextSize=10,Font=GBOL})
rnd(UNCRefreshBtn,5)

-- UNC scroll list
local UNCScroll=Instance.new("ScrollingFrame")
UNCScroll.Size=UDim2.new(1,-20,0,296) UNCScroll.Position=UDim2.new(0,10,0,40)
UNCScroll.BackgroundColor3=C.PANEL UNCScroll.BorderSizePixel=0
UNCScroll.ScrollBarThickness=4 UNCScroll.ScrollBarImageColor3=C.ACCENT
UNCScroll.CanvasSize=UDim2.new(0,0,0,0)
UNCScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
UNCScroll.Parent=T4
rnd(UNCScroll,7) str(UNCScroll,Color3.fromRGB(30,5,70),1)

local UNCLayout=Instance.new("UIListLayout")
UNCLayout.Padding=UDim.new(0,1)
UNCLayout.SortOrder=Enum.SortOrder.LayoutOrder
UNCLayout.Parent=UNCScroll

local UNCPad=Instance.new("UIPadding")
UNCPad.PaddingTop=UDim.new(0,3) UNCPad.PaddingLeft=UDim.new(0,4)
UNCPad.PaddingRight=UDim.new(0,4) UNCPad.Parent=UNCScroll

-- Category colours
local CAT_COLORS = {
    Closure="5,140,200",  Crypt="140,50,200",
    Debug="180,100,0",    Drawing="200,80,150",
    FileSystem="0,160,80",Input="160,160,0",
    Instance="0,120,160", Metatable="160,60,0",
    Misc="80,80,120",     Scripts="100,0,160",
    Signal="0,160,120",   Thread="160,100,0",
    HTTP="0,100,200",     Cache="100,140,0",
    WebSocket="0,160,200",
}
local function catColor(cat)
    local rgb=CAT_COLORS[cat]
    if not rgb then return C.DIM end
    local r,g,b=rgb:match("(%d+),(%d+),(%d+)")
    return Color3.fromRGB(tonumber(r),tonumber(g),tonumber(b))
end

local uncRows={}

local function buildUNCList()
    -- Clear existing rows
    for _,c in UNCScroll:GetChildren() do
        if c:IsA("Frame") then c:Destroy() end
    end
    uncRows={}

    -- Detect executor
    local execName="Unknown Executor"
    if identifyexecutor then
        local ok,n=pcall(identifyexecutor)
        if ok then execName=tostring(n) end
    elseif getexecutorname then
        local ok,n=pcall(getexecutorname)
        if ok then execName=tostring(n) end
    end
    ExecNameLbl.Text="Executor: "..execName

    local total,supported=0,0

    for i,entry in UNC_LIST do
        local name,cat=entry[1],entry[2]
        total+=1
        local avail=hasUNC(name)
        if avail then supported+=1 end

        local row=Instance.new("Frame")
        row.Size=UDim2.new(1,0,0,22)
        row.BackgroundColor3=avail and Color3.fromRGB(14,28,14) or Color3.fromRGB(22,12,12)
        row.BorderSizePixel=0
        row.LayoutOrder=i
        row.Parent=UNCScroll
        rnd(row,4)
        uncRows[i]=row

        -- Status dot
        lbl(row,{Size=UDim2.new(0,18,1,0),Position=UDim2.new(0,4,0,0),
            Text=avail and "●" or "○",
            TextColor3=avail and C.GREEN or Color3.fromRGB(100,30,30),
            TextSize=12,Font=GBOL,TextXAlignment=Enum.TextXAlignment.Center})

        -- Category badge
        local catLbl=btn(row,{
            Size=UDim2.new(0,72,0,14),Position=UDim2.new(0,24,0.5,-7),
            BackgroundColor3=catColor(cat),Text=cat,
            TextColor3=C.WHITE,TextSize=8,Font=GBOL})
        rnd(catLbl,3) catLbl.AutoButtonColor=false

        -- Function name
        lbl(row,{Size=UDim2.new(1,-170,1,0),Position=UDim2.new(0,102,0,0),
            Text=name,
            TextColor3=avail and Color3.fromRGB(190,245,190) or Color3.fromRGB(160,80,80),
            TextSize=10,Font=GCOD,TextXAlignment=Enum.TextXAlignment.Left})

        -- Status text
        lbl(row,{Size=UDim2.new(0,60,1,0),Position=UDim2.new(1,-62,0,0),
            Text=avail and "SUPPORTED" or "MISSING",
            TextColor3=avail and C.GREEN or Color3.fromRGB(120,40,40),
            TextSize=8,Font=GBOL,TextXAlignment=Enum.TextXAlignment.Right})
    end

    SupportedLbl.Text="Supported: "..supported.."/"..total
    SupportedLbl.TextColor3 = supported/total>0.7 and C.GREEN
                            or supported/total>0.4 and C.YELLOW
                            or C.RED
end

UNCRefreshBtn.MouseButton1Click:Connect(function()
    task.spawn(buildUNCList)
end)
hoverHook(UNCRefreshBtn,C.ACCENT,C.ACCHOV)

-- ══════════════════════════════════════════════════════════
-- TAB SWITCHING
-- ══════════════════════════════════════════════════════════
tabFrames={T1,T2,T3,T4}
local activeTab=0

local function switchTab(i)
    if activeTab==i then return end
    activeTab=i
    for j,f in tabFrames do
        f.Visible=(j==i)
    end
    for j,b in tabBtns do
        local active=(j==i)
        tw(b,{BackgroundColor3=active and C.ACCENT or C.DIM,
              TextColor3=active and C.WHITE or C.DIMTXT})
    end
    -- Lazy-build UNC list on first open
    if i==4 and #uncRows==0 then
        task.spawn(buildUNCList)
    end
end

for i,b in tabBtns do
    b.MouseButton1Click:Connect(function() switchTab(i) end)
end
switchTab(1)

-- ── Server ping ───────────────────────────────────────────
task.spawn(function()
    local res=callBridge("ping")
    if res.ok then
        DotLbl.Text="● Server connected" DotLbl.TextColor3=C.GREEN
    else
        DotLbl.Text="● Server offline"   DotLbl.TextColor3=C.RED
        setExecStatus("SS_Executor.lua not found. Server mode disabled.",C.RED)
    end
end)

-- ── Title bar controls ────────────────────────────────────
local minimised=false
MinBtn.MouseButton1Click:Connect(function()
    minimised=not minimised
    if minimised then
        tws(Win,{Size=UDim2.new(0,WIN_W,0,40)}) MinBtn.Text="□"
    else
        tws(Win,{Size=UDim2.new(0,WIN_W,0,WIN_H)}) MinBtn.Text="—"
    end
end)
CloseBtn.MouseButton1Click:Connect(function()
    tws(Win,{Size=UDim2.new(0,0,0,0)})
    task.delay(0.25,function() SG:Destroy() end)
end)

hoverHook(MinBtn,   C.DIM, Color3.fromRGB(42,42,56))
hoverHook(CloseBtn, Color3.fromRGB(195,36,52), Color3.fromRGB(230,55,72))

-- ── Dragging (mouse + touch) ──────────────────────────────
local dragging, dragStart, winStart = false, nil, nil

TBar.InputBegan:Connect(function(inp)
    local t=inp.UserInputType
    if t==Enum.UserInputType.MouseButton1 or t==Enum.UserInputType.Touch then
        dragging=true dragStart=inp.Position winStart=Win.Position
        inp.Changed:Connect(function()
            if inp.UserInputState==Enum.UserInputState.End then dragging=false end
        end)
    end
end)
UIS.InputChanged:Connect(function(inp)
    if not dragging then return end
    local t=inp.UserInputType
    if t==Enum.UserInputType.MouseMovement or t==Enum.UserInputType.Touch then
        local d=inp.Position-dragStart
        Win.Position=UDim2.new(winStart.X.Scale,winStart.X.Offset+d.X,
                               winStart.Y.Scale,winStart.Y.Offset+d.Y)
    end
end)
UIS.InputEnded:Connect(function(inp)
    local t=inp.UserInputType
    if t==Enum.UserInputType.MouseButton1 or t==Enum.UserInputType.Touch then
        dragging=false
    end
end)
