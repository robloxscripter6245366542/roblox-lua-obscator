-- ================================================================
--  SS EXECUTOR  –  Main Loader
--  Loadstrings each tab module separately so code stays organised.
--  loadstring(game:HttpGet(URL,true))()
-- ================================================================

local _ok, _err = pcall(function()

-- ── Base URL for tab modules ──────────────────────────────────────────────────
local RAW = "https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/claude/session-UDpk7/tabs/"

-- ── Services ──────────────────────────────────────────────────────────────────
local Players  = game:GetService("Players")
local RS       = game:GetService("ReplicatedStorage")
local UIS      = game:GetService("UserInputService")
local TS       = game:GetService("TweenService")
local HTTP     = game:GetService("HttpService")

-- ── LocalPlayer ───────────────────────────────────────────────────────────────
local LP
for _ = 1, 100 do
    LP = Players.LocalPlayer
    if LP then break end
    task.wait(0.1)
end
if not LP then return end

local PGui = LP:WaitForChild("PlayerGui", 15)
if not PGui then return end

local prev = PGui:FindFirstChild("__SS_EXEC__")
if prev then prev:Destroy() end

-- ── Server bridge ─────────────────────────────────────────────────────────────
local Bridge = RS:FindFirstChild("SS_ExecBridge")
local function callBridge(action, payload)
    if not Bridge then
        return false, "No bridge — inject SS_Executor.lua server-side first."
    end
    local s, r = pcall(function() return Bridge:InvokeServer(action, payload or {}) end)
    if not s then return false, tostring(r) end
    return r.ok, r.msg, r.data
end

-- ── Loaded notification ───────────────────────────────────────────────────────
pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification",
        {Title="SS Executor", Text="Loading tabs...", Duration=3})
end)

-- ══════════════════════════════════════════════════════════════════════════════
--  THEME
-- ══════════════════════════════════════════════════════════════════════════════
local C = {
    BG      = Color3.fromRGB(11, 11, 17),
    SIDE    = Color3.fromRGB(7,   7, 12),
    PANEL   = Color3.fromRGB(16, 16, 24),
    EDITOR  = Color3.fromRGB(9,   9, 14),
    CONSOLE = Color3.fromRGB(7,   7, 11),
    BORDER  = Color3.fromRGB(50,  7, 130),
    ACC     = Color3.fromRGB(105, 18, 220),
    ACCHV   = Color3.fromRGB(130, 42, 248),
    BLUE    = Color3.fromRGB(28, 118, 238),
    BLUEHV  = Color3.fromRGB(52, 148, 255),
    GREEN   = Color3.fromRGB(44, 208, 64),
    RED     = Color3.fromRGB(228, 44, 44),
    REDHV   = Color3.fromRGB(255, 72, 72),
    YELLOW  = Color3.fromRGB(255, 196, 34),
    ORANGE  = Color3.fromRGB(232, 124, 22),
    GREY    = Color3.fromRGB(72,  72, 98),
    GREYHV  = Color3.fromRGB(100,100,132),
    TXT     = Color3.fromRGB(234, 234, 244),
    TXTS    = Color3.fromRGB(128, 128, 158),
    TXTD    = Color3.fromRGB(72,  72, 92),
    WHITE   = Color3.new(1,1,1),
    PURPLE  = Color3.fromRGB(180, 140, 255),
}
local TF  = TweenInfo.new(0.13)
local TS2 = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FB = Enum.Font.GothamBold
local FN = Enum.Font.Gotham
local FM = Enum.Font.GothamMedium
local FC = Enum.Font.Code

-- ══════════════════════════════════════════════════════════════════════════════
--  UI HELPERS  (shared with all tabs via _G._SS)
-- ══════════════════════════════════════════════════════════════════════════════
local function tw(o, p, ti) TS:Create(o, ti or TF, p):Play() end

local function corner(p, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 7); c.Parent = p
end
local function stroke(p, col, th)
    local s = Instance.new("UIStroke"); s.Color=col or C.BORDER; s.Thickness=th or 1.2; s.Parent=p
end
local function pad(p, v, h)
    local u = Instance.new("UIPadding")
    u.PaddingTop=UDim.new(0,v or 6); u.PaddingBottom=UDim.new(0,v or 6)
    u.PaddingLeft=UDim.new(0,h or v or 8); u.PaddingRight=UDim.new(0,h or v or 8)
    u.Parent=p
end
local function listH(p,sp)
    local l=Instance.new("UIListLayout"); l.FillDirection=Enum.FillDirection.Horizontal
    l.SortOrder=Enum.SortOrder.LayoutOrder; l.Padding=UDim.new(0,sp or 4); l.Parent=p
end
local function listV(p,sp)
    local l=Instance.new("UIListLayout"); l.FillDirection=Enum.FillDirection.Vertical
    l.SortOrder=Enum.SortOrder.LayoutOrder; l.Padding=UDim.new(0,sp or 4); l.Parent=p
end

local function F(parent, s, pos, col, name)
    local f=Instance.new("Frame"); f.Size=s; f.Position=pos or UDim2.new(0,0,0,0)
    f.BackgroundColor3=col or C.PANEL; f.BorderSizePixel=0; f.Name=name or "F"
    f.Parent=parent; return f
end
local function L(parent, text, s, pos, col, font, ts, xa)
    local l=Instance.new("TextLabel"); l.Size=s; l.Position=pos or UDim2.new(0,0,0,0)
    l.BackgroundTransparency=1; l.Text=text or ""; l.TextColor3=col or C.TXT
    l.Font=font or FN; l.TextSize=ts or 14
    l.TextXAlignment=xa or Enum.TextXAlignment.Left
    l.TextYAlignment=Enum.TextYAlignment.Center; l.Parent=parent; return l
end
local function B(parent, text, s, pos, bg, tc, fs)
    local b=Instance.new("TextButton"); b.Size=s; b.Position=pos or UDim2.new(0,0,0,0)
    b.BackgroundColor3=bg or C.ACC; b.BorderSizePixel=0; b.Text=text or ""
    b.TextColor3=tc or C.TXT; b.Font=FB; b.TextSize=fs or 13; b.AutoButtonColor=false
    b.Parent=parent; corner(b,6); return b
end
local function IN(parent, placeholder, s, pos, multi)
    local b=Instance.new("TextBox"); b.Size=s; b.Position=pos or UDim2.new(0,0,0,0)
    b.BackgroundColor3=C.EDITOR; b.BorderSizePixel=0; b.Text=""
    b.PlaceholderText=placeholder or ""; b.TextColor3=C.TXT; b.PlaceholderColor3=C.TXTS
    b.Font=FC; b.TextSize=13; b.TextXAlignment=Enum.TextXAlignment.Left
    b.TextYAlignment=Enum.TextYAlignment.Top; b.ClearTextOnFocus=false
    b.MultiLine=(multi~=false); b.TextWrapped=true; b.ClipsDescendants=true
    b.Parent=parent; corner(b,6); stroke(b,C.BORDER,1); pad(b,7,10); return b
end
local function OUT(parent, s, pos)
    local b=Instance.new("TextBox"); b.Size=s; b.Position=pos or UDim2.new(0,0,0,0)
    b.BackgroundColor3=C.CONSOLE; b.BorderSizePixel=0; b.Text=""
    b.PlaceholderText="> output..."; b.TextColor3=C.GREEN; b.PlaceholderColor3=C.TXTD
    b.Font=FC; b.TextSize=12; b.TextXAlignment=Enum.TextXAlignment.Left
    b.TextYAlignment=Enum.TextYAlignment.Top; b.ClearTextOnFocus=false
    b.MultiLine=true; b.TextWrapped=true; b.TextEditable=false; b.ClipsDescendants=true
    b.Parent=parent; corner(b,6); stroke(b,C.BORDER,1); pad(b,7,10); return b
end
local function SCR(parent, s, pos)
    local sc=Instance.new("ScrollingFrame"); sc.Size=s; sc.Position=pos or UDim2.new(0,0,0,0)
    sc.BackgroundTransparency=1; sc.BorderSizePixel=0; sc.ScrollBarThickness=3
    sc.ScrollBarImageColor3=C.ACC; sc.CanvasSize=UDim2.new(0,0,0,0)
    sc.AutomaticCanvasSize=Enum.AutomaticSize.Y; sc.Parent=parent; return sc
end
local function hov(btn, n, h)
    btn.MouseEnter:Connect(function()    tw(btn,{BackgroundColor3=h}) end)
    btn.MouseLeave:Connect(function()    tw(btn,{BackgroundColor3=n}) end)
    btn.MouseButton1Down:Connect(function() tw(btn,{BackgroundColor3=n}) end)
    btn.MouseButton1Up:Connect(function()   tw(btn,{BackgroundColor3=h}) end)
end

-- ══════════════════════════════════════════════════════════════════════════════
--  BUILD WINDOW
-- ══════════════════════════════════════════════════════════════════════════════
local GUI = Instance.new("ScreenGui")
GUI.Name="__SS_EXEC__"; GUI.ResetOnSpawn=false; GUI.IgnoreGuiInset=true
GUI.DisplayOrder=999; GUI.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
GUI.Parent=PGui

local WIN = F(GUI, UDim2.new(0,590,0,450), UDim2.new(0.5,-295,0.5,-225), C.BG, "Window")
corner(WIN,10); stroke(WIN,C.BORDER,1.5)

-- Shadow
local Sh=Instance.new("ImageLabel"); Sh.Size=UDim2.new(1,48,1,48); Sh.Position=UDim2.new(0,-24,0,-24)
Sh.BackgroundTransparency=1; Sh.Image="rbxassetid://6014261993"; Sh.ImageColor3=Color3.new(0,0,0)
Sh.ImageTransparency=0.44; Sh.ScaleType=Enum.ScaleType.Slice; Sh.SliceCenter=Rect.new(49,49,450,450)
Sh.ZIndex=0; Sh.Parent=WIN

-- Title bar
local TBAR = F(WIN, UDim2.new(1,0,0,38), UDim2.new(0,0,0,0), C.SIDE, "TBar")
corner(TBAR,10)
F(WIN, UDim2.new(1,0,0,10), UDim2.new(0,0,0,28), C.SIDE)   -- flatten corners

-- Accent strip
local Strip = F(TBAR, UDim2.new(0,3,0,22), UDim2.new(0,10,0,8), C.ACC)
corner(Strip,3)

L(TBAR,"  SS EXECUTOR", UDim2.new(1,-120,1,0), UDim2.new(0,20,0,0), C.TXT, FB, 15)
local OnDot = F(TBAR, UDim2.new(0,7,0,7), UDim2.new(0,183,0,15), C.GREEN); corner(OnDot,4)

-- Bridge status
local BridgeLbl = L(TBAR,"bridge: checking...", UDim2.new(0,140,0,16), UDim2.new(0,200,0,11),
    C.TXTS, FN, 11)

local BtnMin   = B(TBAR,"—", UDim2.new(0,26,0,22), UDim2.new(1,-64,0,8), C.GREY)
local BtnClose = B(TBAR,"✕", UDim2.new(0,26,0,22), UDim2.new(1,-34,0,8), C.RED)
hov(BtnMin,C.GREY,C.GREYHV); hov(BtnClose,C.RED,C.REDHV)
BtnClose.MouseButton1Click:Connect(function()
    tw(WIN,{BackgroundTransparency=1}); task.wait(0.15); GUI:Destroy()
end)

-- Update bridge label
task.spawn(function()
    local ok2 = callBridge("ping")
    BridgeLbl.Text = ok2 and "bridge: connected ✓" or "bridge: offline"
    BridgeLbl.TextColor3 = ok2 and C.GREEN or C.RED
end)

-- Sidebar (round-button style, like Roblox mobile sidebar)
local SIDE = F(WIN, UDim2.new(0,52,1,-38), UDim2.new(0,0,0,38), C.SIDE, "Sidebar")
corner(SIDE, 0)  -- no corner on sidebar itself
-- right-side blend strip
F(WIN, UDim2.new(0,10,1,-38), UDim2.new(0,42,0,38), C.SIDE)

-- thin separator line between sidebar and content
F(WIN, UDim2.new(0,1,1,-38), UDim2.new(0,52,0,38), Color3.fromRGB(40,10,90))

-- Content
local BODY = F(WIN, UDim2.new(1,-58,1,-44), UDim2.new(0,55,0,42), Color3.fromRGB(0,0,0), "Body")
BODY.BackgroundTransparency=1

-- Loading label inside body
local LOADING = L(BODY,"Loading modules...", UDim2.new(1,0,0,30), UDim2.new(0,0,0.5,-15),
    C.TXTS, FM, 14, Enum.TextXAlignment.Center)

-- ══════════════════════════════════════════════════════════════════════════════
--  TAB SYSTEM
-- ══════════════════════════════════════════════════════════════════════════════
local sbBtns = {}
local pages  = {}
local curPage = 0
local tabCount = 0

local function showPage(idx)
    for i, p in pages  do p.Visible=(i==idx) end
    for i, b in sbBtns do
        local ac = TAB_CLRS and TAB_CLRS[i] or C.ACC
        if i==idx then
            tw(b,{BackgroundColor3=ac, TextColor3=C.WHITE})
        else
            tw(b,{BackgroundColor3=Color3.fromRGB(18,18,26), TextColor3=C.TXTD})
        end
    end
    curPage=idx
end

-- Per-tab accent colours (like Roblox's round sidebar but coloured)
local TAB_CLRS = {
    Color3.fromRGB(110, 18, 230),   -- Execute   purple
    Color3.fromRGB(25, 112, 232),   -- Server    blue
    Color3.fromRGB(230, 98,  18),   -- Injector  orange
    Color3.fromRGB(225, 40, 120),   -- Sandbox   pink/magenta
    Color3.fromRGB(28, 180,  70),   -- Scripts   green
    Color3.fromRGB(218, 38,  38),   -- Malware   red
    Color3.fromRGB(175, 128, 255),  -- Deobfusc  lavender
    Color3.fromRGB(252, 188,  28),  -- Checker   gold
    Color3.fromRGB(20, 200, 200),   -- Environ   cyan
}

local function refreshSidebar()
    for i, b in sbBtns do
        local ac = TAB_CLRS[i] or C.ACC
        if i == curPage then
            b.BackgroundColor3 = ac
            b.TextColor3 = C.WHITE
        else
            b.BackgroundColor3 = Color3.fromRGB(18,18,26)
            b.TextColor3 = C.TXTD
        end
    end
end

local function registerTab(icon, _name)
    tabCount += 1
    local idx   = tabCount
    local yPos  = 6 + (idx-1)*42
    local ac    = TAB_CLRS[idx] or C.ACC

    -- Round button (full circle via CornerRadius 0.5)
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(0,36,0,36)
    btn.Position         = UDim2.new(0,8,0,yPos)
    btn.BackgroundColor3 = Color3.fromRGB(18,18,26)
    btn.Text             = icon
    btn.TextColor3       = C.TXTD
    btn.Font             = FB
    btn.TextSize         = 19
    btn.AutoButtonColor  = false
    btn.BorderSizePixel  = 0
    btn.Parent           = SIDE
    local uc = Instance.new("UICorner"); uc.CornerRadius=UDim.new(0.5,0); uc.Parent=btn

    -- Tooltip to the right
    local tipW = math.max(72, #_name*7+18)
    local tip  = Instance.new("TextLabel")
    tip.Size                 = UDim2.new(0,tipW,0,22)
    tip.Position             = UDim2.new(1,6,0,yPos+7)
    tip.BackgroundColor3     = C.PANEL
    tip.BackgroundTransparency = 0
    tip.Text                 = _name
    tip.TextColor3           = C.TXT
    tip.Font                 = FM
    tip.TextSize             = 12
    tip.TextXAlignment       = Enum.TextXAlignment.Center
    tip.BorderSizePixel      = 0
    tip.ZIndex               = 12
    tip.Visible              = false
    tip.Parent               = SIDE
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

    local pg = F(BODY,UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),Color3.fromRGB(0,0,0),"Page"..idx)
    pg.BackgroundTransparency=1; pg.Visible=false
    pages[idx]=pg
    return pg
end

-- ══════════════════════════════════════════════════════════════════════════════
--  SHARED CONTEXT  (_G._SS is readable from all tab modules)
-- ══════════════════════════════════════════════════════════════════════════════
_G._SS = {
    C=C, TF=TF, TS2=TS2, FB=FB, FN=FN, FM=FM, FC=FC,
    tw=tw, corner=corner, stroke=stroke, pad=pad,
    listH=listH, listV=listV,
    F=F, L=L, B=B, IN=IN, OUT=OUT, SCR=SCR, hov=hov,
    bridge=callBridge,
    LP=LP, HTTP=HTTP,
    registerTab=registerTab,
    showPage=showPage,
    RAW=RAW,
}

-- ══════════════════════════════════════════════════════════════════════════════
--  LOAD TAB MODULES
-- ══════════════════════════════════════════════════════════════════════════════
local TAB_FILES = {
    "execute.lua",
    "server.lua",
    "injector.lua",
    "sandbox.lua",
    "scripts.lua",
    "malware.lua",
    "deobfusc.lua",
    "checker.lua",
    "env.lua",
}

local loadErrors = {}
for _, file in TAB_FILES do
    local ok2, err2 = pcall(function()
        local src = game:HttpGet(RAW .. file, true)
        local fn, ce = loadstring(src)
        if not fn then error("Compile: "..tostring(ce)) end
        fn()
    end)
    if not ok2 then
        loadErrors[#loadErrors+1] = file .. ": " .. tostring(err2)
        warn("[SS Executor] Tab load failed – " .. file .. ": " .. tostring(err2))
    end
end

LOADING:Destroy()

if #loadErrors > 0 then
    local pg = registerTab("⚠", "Load Errors")
    L(pg, "Some modules failed to load:", UDim2.new(1,0,0,18), UDim2.new(0,4,0,4),
        C.RED, FB, 13)
    local sc = SCR(pg, UDim2.new(1,0,1,-26), UDim2.new(0,0,0,24))
    listV(sc, 3)
    for _, e2 in loadErrors do
        L(sc, e2, UDim2.new(1,-8,0,18), nil, C.YELLOW, FC, 11)
    end
end

showPage(1)

-- ══════════════════════════════════════════════════════════════════════════════
--  DRAG
-- ══════════════════════════════════════════════════════════════════════════════
local dragging, ds, dpos = false, nil, nil
TBAR.InputBegan:Connect(function(inp)
    local t=inp.UserInputType
    if t==Enum.UserInputType.MouseButton1 or t==Enum.UserInputType.Touch then
        dragging=true; ds=inp.Position; dpos=WIN.Position
    end
end)
UIS.InputChanged:Connect(function(inp)
    if not dragging then return end
    local t=inp.UserInputType
    if t==Enum.UserInputType.MouseMovement or t==Enum.UserInputType.Touch then
        local d=inp.Position-ds
        WIN.Position=UDim2.new(dpos.X.Scale,dpos.X.Offset+d.X,dpos.Y.Scale,dpos.Y.Offset+d.Y)
    end
end)
UIS.InputEnded:Connect(function(inp)
    local t=inp.UserInputType
    if t==Enum.UserInputType.MouseButton1 or t==Enum.UserInputType.Touch then dragging=false end
end)

-- Minimise
local mini=false
BtnMin.MouseButton1Click:Connect(function()
    mini=not mini
    tw(WIN,{Size=mini and UDim2.new(0,590,0,38) or UDim2.new(0,590,0,450)},TS2)
    BODY.Visible=not mini; SIDE.Visible=not mini
    BtnMin.Text=mini and "□" or "—"
end)

end)  -- pcall

if not _ok then warn("[SS Executor] ERROR: "..tostring(_err)) end
