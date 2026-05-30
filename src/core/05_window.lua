-- ── Main Window & Tab System ─────────────────────────────────────────────────

local GUI = Instance.new("ScreenGui")
GUI.Name              = "__SS_EXEC__"
GUI.ResetOnSpawn      = false
GUI.IgnoreGuiInset    = true
GUI.DisplayOrder      = 999
GUI.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
GUI.Parent            = PGui

local WIN = F(GUI, UDim2.new(0,650,0,530), UDim2.new(0.5,-325,0.5,-265), C.BG, "Window")
corner(WIN, 12); stroke(WIN, C.BDR, 1.5)

-- Drop shadow
local Sh = Instance.new("ImageLabel")
Sh.Size               = UDim2.new(1, 60, 1, 60)
Sh.Position           = UDim2.new(0, -30, 0, -30)
Sh.BackgroundTransparency = 1
Sh.Image              = "rbxassetid://6014261993"
Sh.ImageColor3        = C.BLK
Sh.ImageTransparency  = 0.38
Sh.ScaleType          = Enum.ScaleType.Slice
Sh.SliceCenter        = Rect.new(49, 49, 450, 450)
Sh.ZIndex             = 0
Sh.Parent             = WIN

-- Title bar
local TBAR = F(WIN, UDim2.new(1,0,0,44), UDim2.new(0,0,0,0), C.SIDE, "TBar")
corner(TBAR, 12)
F(WIN, UDim2.new(1,0,0,12), UDim2.new(0,0,0,32), C.SIDE) -- square bottom corners

-- Logo icon
local LBG = F(TBAR, UDim2.new(0,30,0,30), UDim2.new(0,9,0,7), C.ACC); corner(LBG,8)
L(LBG, "⚡", UDim2.new(1,0,1,0), nil, C.WHT, FB, 16, Enum.TextXAlignment.Center)
L(TBAR, "NEXUS",        UDim2.new(0,60,0,22), UDim2.new(0,46,0,3),  C.WHT,  FB, 16)
L(TBAR, "EXECUTOR  v7", UDim2.new(0,110,0,13),UDim2.new(0,46,0,24), C.TXTS, FN, 10)

-- Bridge status indicator
local ODot      = dot(TBAR, UDim2.new(0,8,0,8), UDim2.new(0,163,0,18))
local BridgeTxt = L(TBAR, "checking…", UDim2.new(0,120,0,14), UDim2.new(0,178,0,15), C.TXTS, FN, 11)

-- Live FPS counter
local FpsTxt = L(TBAR, "", UDim2.new(0,72,0,14), UDim2.new(0,308,0,15), C.TXTD, FN, 10)
local _fpsConn
_fpsConn = RUN.RenderStepped:Connect(function(dt)
    FpsTxt.Text = ("%.0f fps"):format(1 / dt)
end)

-- Session uptime (ticks every second)
local uptimeLbl = L(TBAR, "00:00", UDim2.new(0,50,0,14), UDim2.new(0,384,0,15), C.TXTD, FC, 10)
task.spawn(function()
    local t0 = os.clock()
    while GUI.Parent do
        local elapsed = math.floor(os.clock() - t0)
        uptimeLbl.Text = ("%02d:%02d"):format(math.floor(elapsed/60), elapsed%60)
        task.wait(1)
    end
end)

-- Window control buttons
local BtnMin = B(TBAR, "—", UDim2.new(0,28,0,24), UDim2.new(1,-66,0,10), C.GREY)
local BtnX   = B(TBAR, "✕", UDim2.new(0,28,0,24), UDim2.new(1,-34,0,10), C.RED)
hov(BtnMin, C.GREY, C.GRYHV)
hov(BtnX,   C.RED,  C.REDHV)

BtnX.MouseButton1Click:Connect(function()
    if _fpsConn then _fpsConn:Disconnect() end
    tw(WIN, {BackgroundTransparency=1}, TF2)
    task.wait(0.22)
    GUI:Destroy()
end)

-- Bridge ping on startup
task.spawn(function()
    local alive = pingBridge()
    ODot.BackgroundColor3  = alive and C.GRN or C.RED
    BridgeTxt.Text         = alive and "bridge ✓" or "no bridge"
    BridgeTxt.TextColor3   = alive and C.GRN or C.RED
end)

-- Sidebar and body
local SIDE = F(WIN, UDim2.new(0,54,1,-44), UDim2.new(0,0,0,44), C.SIDE, "Side")
F(WIN, UDim2.new(0,1,1,-44), UDim2.new(0,54,0,44), Color3.fromRGB(32,44,82))  -- separator line
local BODY = F(WIN, UDim2.new(1,-60,1,-50), UDim2.new(0,57,0,48), C.BLK, "Body")
BODY.BackgroundTransparency = 1

-- ── Tab system ────────────────────────────────────────────────────────────────
local sbBtns  = {}
local pages   = {}
local curPage = 0
local tabN    = 0

local TCOL = {
    Color3.fromRGB( 59,130,246),  -- 1 Execute    blue
    Color3.fromRGB( 34,197, 94),  -- 2 Server     green
    Color3.fromRGB(249,115, 22),  -- 3 Sandbox    orange
    Color3.fromRGB(236, 72,153),  -- 4 Player     pink
    Color3.fromRGB(139, 92,246),  -- 5 RemoteSpy  purple
    Color3.fromRGB(220, 55, 55),  -- 6 Scanner    red
    Color3.fromRGB(250,204, 21),  -- 7 Deobfusc   yellow
    Color3.fromRGB( 20,184,166),  -- 8 Checker    teal
    Color3.fromRGB( 96,165,250),  -- 9 Scripts    sky
    Color3.fromRGB(167,139,250),  -- 10 Environ   lavender
}

local function showPage(idx)
    for i, p in pages  do p.Visible = (i == idx) end
    for i, b in sbBtns do
        local ac = TCOL[i] or C.ACC
        local active = (i == idx)
        tw(b, {
            BackgroundColor3 = active and ac or Color3.fromRGB(16,16,24),
            TextColor3       = active and C.WHT or C.TXTD,
        })
    end
    curPage = idx
end

local function newTab(icon, label)
    tabN += 1
    local idx = tabN
    local yp  = 8 + (idx-1) * 40
    local ac  = TCOL[idx] or C.ACC

    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(0,38,0,34)
    btn.Position         = UDim2.new(0,8,0,yp)
    btn.BackgroundColor3 = Color3.fromRGB(16,16,24)
    btn.Text             = icon
    btn.TextColor3       = C.TXTD
    btn.Font             = FB
    btn.TextSize         = 18
    btn.AutoButtonColor  = false
    btn.BorderSizePixel  = 0
    btn.Parent           = SIDE
    corner(btn, 8)

    -- Tooltip
    local tipW = math.max(80, #label * 8 + 16)
    local tip  = Instance.new("TextLabel")
    tip.Size             = UDim2.new(0, tipW, 0, 22)
    tip.Position         = UDim2.new(1, 6, 0, yp + 6)
    tip.BackgroundColor3 = C.PANEL
    tip.Text             = label
    tip.TextColor3       = C.TXT
    tip.Font             = FN
    tip.TextSize         = 11
    tip.TextXAlignment   = Enum.TextXAlignment.Center
    tip.BorderSizePixel  = 0
    tip.ZIndex           = 15
    tip.Visible          = false
    tip.Parent           = SIDE
    corner(tip, 5); stroke(tip, ac, 1)

    btn.MouseEnter:Connect(function()
        tip.Visible = true
        if curPage ~= idx then
            tw(btn, {BackgroundColor3=Color3.fromRGB(22,22,34), TextColor3=C.TXTS})
        end
    end)
    btn.MouseLeave:Connect(function()
        tip.Visible = false
        if curPage ~= idx then
            tw(btn, {BackgroundColor3=Color3.fromRGB(16,16,24), TextColor3=C.TXTD})
        end
    end)
    btn.MouseButton1Click:Connect(function() showPage(idx) end)
    sbBtns[idx] = btn

    local pg = F(BODY, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), C.BLK, "P"..idx)
    pg.BackgroundTransparency = 1
    pg.Visible = false
    pages[idx] = pg
    return pg
end
