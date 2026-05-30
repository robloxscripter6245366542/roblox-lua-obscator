local SS  = _G._SS
local C   = SS.C
local UIS = SS.UIS
local TS  = SS.TS

local Frm    = SS.Frm
local Lbl    = SS.Lbl
local Btn    = SS.Btn
local tw     = SS.tw
local corner = SS.corner
local stroke = SS.stroke
local hov    = SS.hov

local FB  = SS.FB
local FN  = SS.FN
local TS2 = SS.TS2

-- ── ScreenGui ──────────────────────────────────────────────────────────────────
local GUI = Instance.new("ScreenGui")
GUI.Name = "__SS_EXEC__"; GUI.ResetOnSpawn = false; GUI.IgnoreGuiInset = true
GUI.DisplayOrder = 999; GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GUI.Parent = SS.PGui

-- Main window
local WIN = Frm(GUI, UDim2.new(0,590,0,462), UDim2.new(0.5,-295,0.5,-231), C.BG, "Window")
corner(WIN, 12); stroke(WIN, C.BORDER, 1.5)

-- Drop shadow
local Sh = Instance.new("ImageLabel")
Sh.Size = UDim2.new(1,48,1,48); Sh.Position = UDim2.new(0,-24,0,-24)
Sh.BackgroundTransparency = 1; Sh.Image = "rbxassetid://6014261993"
Sh.ImageColor3 = Color3.new(0,0,0); Sh.ImageTransparency = 0.45
Sh.ScaleType = Enum.ScaleType.Slice; Sh.SliceCenter = Rect.new(49,49,450,450)
Sh.ZIndex = 0; Sh.Parent = WIN

-- Title bar
local TBAR = Frm(WIN, UDim2.new(1,0,0,42), UDim2.new(0,0,0,0), C.SIDE, "TBar")
corner(TBAR, 12)
Frm(WIN, UDim2.new(1,0,0,12), UDim2.new(0,0,0,30), C.SIDE)

-- Logo badge
local LogoBG = Frm(TBAR, UDim2.new(0,28,0,28), UDim2.new(0,8,0,7), C.ACC)
corner(LogoBG, 7)
Lbl(LogoBG, "⚡", UDim2.new(1,0,1,0), nil, C.WHITE, FB, 14, Enum.TextXAlignment.Center)

-- Title text
Lbl(TBAR, "NEXUS",    UDim2.new(0,54,0,20), UDim2.new(0,42,0,5),  C.WHITE, FB, 15)
Lbl(TBAR, "EXECUTOR", UDim2.new(0,72,0,14), UDim2.new(0,42,0,22), C.TXTS,  FN, 10)

-- Bridge status indicator
local ODot     = Frm(TBAR, UDim2.new(0,7,0,7),   UDim2.new(0,122,0,17), C.GREY)
corner(ODot, 4)
local BridgeTxt = Lbl(TBAR, "checking...", UDim2.new(0,130,0,14), UDim2.new(0,136,0,14), C.TXTS, FN, 11)

-- Control buttons
local BtnMin = Btn(TBAR, "—", UDim2.new(0,26,0,24), UDim2.new(1,-62,0,9), C.GREY)
local BtnX   = Btn(TBAR, "✕", UDim2.new(0,26,0,24), UDim2.new(1,-32,0,9), C.RED)
hov(BtnMin, C.GREY, C.GRYHV); hov(BtnX, C.RED, C.REDHV)

BtnX.MouseButton1Click:Connect(function()
    tw(WIN, {BackgroundTransparency=1}); task.wait(0.15); GUI:Destroy()
end)

-- Async bridge ping
task.spawn(function()
    local alive = SS.pingBridge()
    ODot.BackgroundColor3  = alive and C.GREEN or C.RED
    BridgeTxt.Text         = alive and "bridge ✓" or "no bridge"
    BridgeTxt.TextColor3   = alive and C.GREEN or C.RED
end)

-- Sidebar
local SIDE = Frm(WIN, UDim2.new(0,52,1,-42), UDim2.new(0,0,0,42), C.SIDE, "Side")
Frm(WIN, UDim2.new(0,10,1,-42), UDim2.new(0,42,0,42), C.SIDE)
Frm(WIN, UDim2.new(0,1,1,-42),  UDim2.new(0,52,0,42), Color3.fromRGB(35,48,88))

-- Body
local BODY = Frm(WIN, UDim2.new(1,-58,1,-48), UDim2.new(0,55,0,46), Color3.fromRGB(0,0,0), "Body")
BODY.BackgroundTransparency = 1

-- ── Tab system ─────────────────────────────────────────────────────────────────
local sbBtns = {}; local pages = {}; local curPage = 0; local tabN = 0

local TAB_COLORS = {
    Color3.fromRGB( 59,130,246), -- 1 Execute  blue
    Color3.fromRGB( 96,165,250), -- 2 Server   light-blue
    Color3.fromRGB(249,115, 22), -- 3 Sandbox  orange
    Color3.fromRGB(220, 55, 55), -- 4 Malware  red
    Color3.fromRGB(139, 92,246), -- 5 Deobfusc purple
    Color3.fromRGB(250,204, 21), -- 6 Checker  gold
    Color3.fromRGB( 20,184,166), -- 7 Scripts  teal
    Color3.fromRGB( 34,197, 94), -- 8 Environ  green
}

local function showPage(idx)
    for i,p in pages  do p.Visible = (i==idx) end
    for i,b in sbBtns do
        local ac = TAB_COLORS[i] or C.ACC
        tw(b, {
            BackgroundColor3 = i==idx and ac or Color3.fromRGB(18,18,26),
            TextColor3       = i==idx and C.WHITE or C.TXTD,
        })
    end
    curPage = idx
end

local function newTab(icon, label)
    tabN += 1; local idx = tabN
    local yp = 10 + (idx-1) * 44
    local ac = TAB_COLORS[idx] or C.ACC

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0,36,0,36); btn.Position = UDim2.new(0,8,0,yp)
    btn.BackgroundColor3 = Color3.fromRGB(18,18,26); btn.Text = icon
    btn.TextColor3 = C.TXTD; btn.Font = FB; btn.TextSize = 18
    btn.AutoButtonColor = false; btn.BorderSizePixel = 0; btn.Parent = SIDE
    local uc = Instance.new("UICorner"); uc.CornerRadius = UDim.new(0.5,0); uc.Parent = btn

    local tipW = math.max(70, #label*8+16)
    local tip = Instance.new("TextLabel")
    tip.Size = UDim2.new(0,tipW,0,22); tip.Position = UDim2.new(1,6,0,yp+7)
    tip.BackgroundColor3 = C.PANEL; tip.Text = label
    tip.TextColor3 = C.TXT; tip.Font = FN; tip.TextSize = 12
    tip.TextXAlignment = Enum.TextXAlignment.Center
    tip.BorderSizePixel = 0; tip.ZIndex = 12; tip.Visible = false; tip.Parent = SIDE
    corner(tip, 5); stroke(tip, ac, 1)

    btn.MouseEnter:Connect(function()
        tip.Visible = true
        if curPage ~= idx then tw(btn, {BackgroundColor3=Color3.fromRGB(28,28,40), TextColor3=C.TXTS}) end
    end)
    btn.MouseLeave:Connect(function()
        tip.Visible = false
        if curPage ~= idx then tw(btn, {BackgroundColor3=Color3.fromRGB(18,18,26), TextColor3=C.TXTD}) end
    end)
    btn.MouseButton1Click:Connect(function() showPage(idx) end)
    sbBtns[idx] = btn

    local pg = Frm(BODY, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), Color3.fromRGB(0,0,0), "P"..idx)
    pg.BackgroundTransparency = 1; pg.Visible = false; pages[idx] = pg
    return pg
end

-- ── Drag (PC + Mobile) ─────────────────────────────────────────────────────────
local drag, ds, dp = false, nil, nil
TBAR.InputBegan:Connect(function(inp)
    local t = inp.UserInputType
    if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
        drag = true; ds = inp.Position; dp = WIN.Position
    end
end)
UIS.InputChanged:Connect(function(inp)
    if not drag then return end
    local t = inp.UserInputType
    if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
        local d = inp.Position - ds
        WIN.Position = UDim2.new(dp.X.Scale, dp.X.Offset+d.X, dp.Y.Scale, dp.Y.Offset+d.Y)
    end
end)
UIS.InputEnded:Connect(function(inp)
    local t = inp.UserInputType
    if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then drag = false end
end)

-- ── Minimise ───────────────────────────────────────────────────────────────────
local mini = false
BtnMin.MouseButton1Click:Connect(function()
    mini = not mini
    tw(WIN, {Size=mini and UDim2.new(0,590,0,42) or UDim2.new(0,590,0,462)}, TS2)
    BODY.Visible = not mini; SIDE.Visible = not mini
    BtnMin.Text = mini and "□" or "—"
end)

-- ── Expose ─────────────────────────────────────────────────────────────────────
SS.GUI      = GUI
SS.WIN      = WIN
SS.TBAR     = TBAR
SS.SIDE     = SIDE
SS.BODY     = BODY
SS.showPage = showPage
SS.newTab   = newTab
