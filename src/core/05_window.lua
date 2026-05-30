-- ── Main Window & Tab System ─────────────────────────────────────────────────
-- Mobile  → full-screen, bottom tab bar, touch-optimised (Delta iOS/Android/iPad)
-- Desktop → 650×530 floating window, left sidebar, hover tooltips

local GUI = Instance.new("ScreenGui")
GUI.Name              = "__SS_EXEC__"
GUI.ResetOnSpawn      = false
GUI.IgnoreGuiInset    = true
GUI.DisplayOrder      = 999
GUI.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
GUI.Parent            = PGui

local WIN = F(GUI,
    UDim2.new(0, WIN_W, 0, WIN_H),
    isMobile and UDim2.new(0, 0, 0, 0)
           or  UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2),
    C.BG, "Window")

if isMobile then
    -- No rounded corners on full-screen window
else
    corner(WIN, 12)
    stroke(WIN, C.BDR, 1.5)
    -- Drop shadow
    local Sh          = Instance.new("ImageLabel")
    Sh.Size           = UDim2.new(1,60,1,60)
    Sh.Position       = UDim2.new(0,-30,0,-30)
    Sh.BackgroundTransparency = 1
    Sh.Image          = "rbxassetid://6014261993"
    Sh.ImageColor3    = C.BLK
    Sh.ImageTransparency = 0.42
    Sh.ScaleType      = Enum.ScaleType.Slice
    Sh.SliceCenter    = Rect.new(49,49,450,450)
    Sh.ZIndex         = 0
    Sh.Parent         = WIN
end

-- ── Title bar ─────────────────────────────────────────────────────────────────
local _TBAR_H = isMobile and 50 or 44
local TBAR = F(WIN, UDim2.new(1,0,0,_TBAR_H), UDim2.new(0,0,0,0), C.SIDE, "TBar")
if not isMobile then
    corner(TBAR, 12)
    F(WIN, UDim2.new(1,0,0,12), UDim2.new(0,0,0,32), C.SIDE)  -- fill bottom corners
end

-- Logo
local LBG = F(TBAR, UDim2.new(0,30,0,30), UDim2.new(0,9,0,10), C.ACC); corner(LBG,8)
L(LBG, "⚡", UDim2.new(1,0,1,0), nil, C.WHT, FB, 16, Enum.TextXAlignment.Center)
L(TBAR, "NEXUS",        UDim2.new(0,60,0,22), UDim2.new(0,46,0,4),  C.WHT,  FB, isMobile and 15 or 16)
L(TBAR, "EXECUTOR  v8", UDim2.new(0,120,0,13),UDim2.new(0,46,0,25), C.TXTS, FN, 10)

-- Bridge status — X position scaled so it fits any window width
local _bX = math.min(170, WIN_W - 190)
local ODot      = dot(TBAR, UDim2.new(0,8,0,8),  UDim2.new(0,_bX,0,21))
local BridgeTxt = L(TBAR, "…",
    UDim2.new(0, math.max(60, WIN_W-_bX-80), 0,13),
    UDim2.new(0,_bX+14,0,19), C.TXTS, FN, 11)

-- FPS + uptime — desktop only (no room in mobile titlebar)
local _fpsConn
if not isMobile then
    local FpsTxt = L(TBAR,"",UDim2.new(0,72,0,14),UDim2.new(0,308,0,15),C.TXTD,FN,10)
    local uptL   = L(TBAR,"00:00",UDim2.new(0,50,0,14),UDim2.new(0,384,0,15),C.TXTD,FC,10)
    _fpsConn = RUN.RenderStepped:Connect(function(dt)
        FpsTxt.Text = ("%.0f fps"):format(1/dt)
    end)
    task.spawn(function()
        local t0 = os.clock()
        while GUI.Parent do
            local e = math.floor(os.clock()-t0)
            uptL.Text = ("%02d:%02d"):format(math.floor(e/60),e%60)
            task.wait(1)
        end
    end)
end

-- ── Control buttons ───────────────────────────────────────────────────────────
local _cH = isMobile and 32 or 24
local _cY = isMobile and  9 or 10
local BtnMin = B(TBAR,"—",UDim2.new(0,32,0,_cH),UDim2.new(1,-70,0,_cY),C.GREY)
local BtnX   = B(TBAR,"✕",UDim2.new(0,32,0,_cH),UDim2.new(1,-34,0,_cY),C.RED)
hov(BtnMin,C.GREY,C.GRYHV); hov(BtnX,C.RED,C.REDHV)

BtnX.MouseButton1Click:Connect(function()
    if _fpsConn then _fpsConn:Disconnect() end
    tw(WIN,{BackgroundTransparency=1},TF2)
    task.wait(0.22); GUI:Destroy()
end)

-- Bridge ping
task.spawn(function()
    local alive = pingBridge()
    ODot.BackgroundColor3 = alive and C.GRN or C.RED
    BridgeTxt.Text        = alive and "bridge ✓" or "no bridge"
    BridgeTxt.TextColor3  = alive and C.GRN or C.RED
end)

-- ── Layout: BODY + nav elements ───────────────────────────────────────────────
-- Mobile:  full-width body between titlebar and 52px bottom tab bar
-- Desktop: sidebar on left, body fills the rest
local SIDE, BODY, TABBAR

if isMobile then
    local _TABB_H = 52
    BODY = F(WIN,
        UDim2.new(1, 0, 1, -(_TBAR_H + _TABB_H)),
        UDim2.new(0, 0, 0, _TBAR_H),
        C.BLK, "Body")
    BODY.BackgroundTransparency = 1

    -- Bottom tab bar
    TABBAR = F(WIN, UDim2.new(1,0,0,_TABB_H), UDim2.new(0,0,1,-_TABB_H), C.SIDE, "TabBar")
    -- top separator line
    F(TABBAR, UDim2.new(1,0,0,1), UDim2.new(0,0,0,0), C.BDR2)
else
    SIDE = F(WIN, UDim2.new(0,SIDE_W,1,-44), UDim2.new(0,0,0,44), C.SIDE, "Side")
    F(WIN, UDim2.new(0,1,1,-44), UDim2.new(0,SIDE_W,0,44), Color3.fromRGB(32,44,82))
    BODY = F(WIN, UDim2.new(1,-(SIDE_W+6),1,-50), UDim2.new(0,SIDE_W+3,0,48), C.BLK, "Body")
    BODY.BackgroundTransparency = 1
end

-- ── Tab system ────────────────────────────────────────────────────────────────
local sbBtns  = {}
local pages   = {}
local curPage = 0
local tabN    = 0

local TCOL = {
    Color3.fromRGB( 59,130,246),  Color3.fromRGB( 34,197, 94),
    Color3.fromRGB(249,115, 22),  Color3.fromRGB(236, 72,153),
    Color3.fromRGB(139, 92,246),  Color3.fromRGB(220, 55, 55),
    Color3.fromRGB(250,204, 21),  Color3.fromRGB( 20,184,166),
    Color3.fromRGB( 96,165,250),  Color3.fromRGB(167,139,250),
}

local function showPage(idx)
    for i,p in pages  do p.Visible = (i==idx) end
    for i,b in sbBtns do
        local ac = TCOL[i] or C.ACC
        local on = (i==idx)
        tw(b, {
            BackgroundColor3 = on and ac or (isMobile and Color3.fromRGB(8,11,20) or Color3.fromRGB(16,16,24)),
            TextColor3       = on and C.WHT or C.TXTD,
        })
        -- mobile: show/hide indicator stripe at top of each tab button
        if isMobile then
            local ind = b:FindFirstChild("Ind")
            if ind then ind.BackgroundTransparency = on and 0 or 1 end
        end
    end
    curPage = idx
end

local function newTab(icon, label)
    tabN += 1
    local idx = tabN
    local ac  = TCOL[idx] or C.ACC
    local btn

    if isMobile then
        -- Bottom tab bar: 10 equal-width buttons (0.1 scale each)
        btn = Instance.new("TextButton")
        btn.Size             = UDim2.new(0.1, 0, 1, 0)
        btn.Position         = UDim2.new((idx-1)*0.1, 0, 0, 0)
        btn.BackgroundColor3 = Color3.fromRGB(8,11,20)
        btn.Text             = icon
        btn.TextColor3       = C.TXTD
        btn.Font             = FB
        btn.TextSize         = 20
        btn.AutoButtonColor  = false
        btn.BorderSizePixel  = 0
        btn.Parent           = TABBAR

        -- Coloured indicator stripe at top (visible when active)
        local ind = F(btn, UDim2.new(1,0,0,3), UDim2.new(0,0,0,1), ac, "Ind")
        ind.BackgroundTransparency = 1

        -- Left separator between buttons
        if idx > 1 then
            local sep = F(btn, UDim2.new(0,1,0.6,0), UDim2.new(0,0,0.2,0), C.BDR)
            sep.ZIndex = 2
        end

        -- Press ripple
        btn.MouseButton1Down:Connect(function()
            tw(btn,{BackgroundColor3=Color3.fromRGB(20,26,42)})
        end)
        btn.MouseButton1Up:Connect(function()
            tw(btn,{BackgroundColor3=curPage==idx and ac or Color3.fromRGB(8,11,20)})
        end)
        btn.MouseButton1Click:Connect(function() showPage(idx) end)
    else
        -- Desktop: left sidebar
        local yp   = 6 + (idx-1)*TAB_SP
        local btnW = SIDE_W - 12
        btn = Instance.new("TextButton")
        btn.Size             = UDim2.new(0,btnW,0,TAB_SZ)
        btn.Position         = UDim2.new(0,6,0,yp)
        btn.BackgroundColor3 = Color3.fromRGB(16,16,24)
        btn.Text             = icon
        btn.TextColor3       = C.TXTD
        btn.Font             = FB
        btn.TextSize         = 18
        btn.AutoButtonColor  = false
        btn.BorderSizePixel  = 0
        btn.Parent           = SIDE
        corner(btn,7)

        -- Tooltip
        local tipW = math.max(80,#label*8+16)
        local tip  = Instance.new("TextLabel")
        tip.Size             = UDim2.new(0,tipW,0,22)
        tip.Position         = UDim2.new(1,6,0,yp+4)
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
        corner(tip,5); stroke(tip,ac,1)

        btn.MouseEnter:Connect(function()
            tip.Visible = true
            if curPage~=idx then tw(btn,{BackgroundColor3=Color3.fromRGB(22,22,34),TextColor3=C.TXTS}) end
        end)
        btn.MouseLeave:Connect(function()
            tip.Visible = false
            if curPage~=idx then tw(btn,{BackgroundColor3=Color3.fromRGB(16,16,24),TextColor3=C.TXTD}) end
        end)
        btn.MouseButton1Click:Connect(function() showPage(idx) end)
    end

    sbBtns[idx] = btn

    local pg = F(BODY, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), C.BLK, "P"..idx)
    pg.BackgroundTransparency = 1
    pg.Visible = false
    pages[idx] = pg
    return pg
end
