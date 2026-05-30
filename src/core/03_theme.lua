-- ── Theme: Nexus Navy Blue Dark ──────────────────────────────────────────────

local C = {
    -- Backgrounds
    BG      = Color3.fromRGB(13,  17,  30),   -- main window
    SIDE    = Color3.fromRGB( 8,  11,  20),   -- sidebar / titlebar
    PANEL   = Color3.fromRGB(22,  28,  46),   -- cards / panels
    EDIT    = Color3.fromRGB(12,  16,  28),   -- text input boxes
    CON     = Color3.fromRGB( 8,  11,  20),   -- console / output
    HOVER   = Color3.fromRGB(18,  24,  40),   -- generic hover
    SEL     = Color3.fromRGB(28,  36,  62),   -- selected item
    -- Borders
    BDR     = Color3.fromRGB(40,  52,  92),   -- default border
    BDR2    = Color3.fromRGB(55,  70, 120),   -- brighter border
    -- Accent — blue
    ACC     = Color3.fromRGB(59, 130, 246),
    ACCHV   = Color3.fromRGB(96, 165, 250),
    BLUE    = Color3.fromRGB(59, 130, 246),
    BLHV    = Color3.fromRGB(96, 165, 250),
    BLDK    = Color3.fromRGB(37,  99, 235),
    -- Green
    GRN     = Color3.fromRGB(34, 197,  94),
    GRNHV   = Color3.fromRGB(74, 222, 128),
    GRNDK   = Color3.fromRGB(21, 128,  61),
    -- Red
    RED     = Color3.fromRGB(220,  55,  55),
    REDHV   = Color3.fromRGB(248,  80,  80),
    REDDK   = Color3.fromRGB(153,  27,  27),
    -- Yellow
    YELL    = Color3.fromRGB(250, 204,  21),
    YELLHV  = Color3.fromRGB(253, 224,  71),
    -- Orange
    ORAN    = Color3.fromRGB(249, 115,  22),
    ORANHV  = Color3.fromRGB(253, 150,  60),
    -- Grey
    GREY    = Color3.fromRGB(50,  60,  86),
    GRYHV   = Color3.fromRGB(70,  84, 118),
    GRYDK   = Color3.fromRGB(30,  38,  58),
    -- Purple
    PURP    = Color3.fromRGB(139,  92, 246),
    PURPHV  = Color3.fromRGB(167, 139, 250),
    PURPDK  = Color3.fromRGB( 91,  33, 182),
    -- Teal
    TEAL    = Color3.fromRGB(20, 184, 166),
    TEALHV  = Color3.fromRGB(45, 212, 191),
    -- Pink
    PINK    = Color3.fromRGB(236,  72, 153),
    PINKHV  = Color3.fromRGB(244, 114, 182),
    -- Indigo
    INDI    = Color3.fromRGB(99, 102, 241),
    INDIHV  = Color3.fromRGB(129, 140, 248),
    -- Cyan
    CYAN    = Color3.fromRGB(34, 211, 238),
    CYANHV  = Color3.fromRGB(103, 232, 249),
    -- Text
    TXT     = Color3.fromRGB(241, 245, 249),   -- primary text
    TXTS    = Color3.fromRGB(148, 163, 184),   -- secondary / muted
    TXTD    = Color3.fromRGB( 55,  70, 100),   -- disabled text
    TXTE    = Color3.fromRGB(200, 210, 230),   -- emphasis
    -- Special
    WHT     = Color3.new(1, 1, 1),
    BLK     = Color3.new(0, 0, 0),
    TRANS   = Color3.new(0, 0, 0),  -- used with transparency=1
}

-- Status colors (used in status dots)
C.STATUS = {
    ok      = C.GRN,
    warn    = C.YELL,
    err     = C.RED,
    info    = C.BLUE,
    idle    = C.GREY,
}

-- Category colors (used in Script Hub)
C.CAT = {
    Utility = C.ACC,
    ESP     = C.RED,
    Game    = C.GRN,
    Lib     = C.PURP,
    Admin   = C.ORAN,
    Troll   = C.PINK,
    Debug   = C.TEAL,
    Farm    = C.YELL,
}

-- ── TweenInfos ────────────────────────────────────────────────────────────────
local TF    = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TF2   = TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TF3   = TweenInfo.new(0.30, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TF_SLOW = TweenInfo.new(0.50, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local TS2   = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TF_BOUNCE = TweenInfo.new(0.35, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)

-- ── Fonts ─────────────────────────────────────────────────────────────────────
local FB  = Enum.Font.GothamBold      -- bold
local FN  = Enum.Font.Gotham          -- normal
local FC  = Enum.Font.Code            -- monospace
local FM  = Enum.Font.GothamMedium    -- medium
local FSB = Enum.Font.GothamSemibold  -- semibold

-- ── Tween helper ──────────────────────────────────────────────────────────────
local function tw(obj, props, ti)
    TS:Create(obj, ti or TF, props):Play()
end

local function twWait(obj, props, ti)
    local t = TS:Create(obj, ti or TF, props)
    t:Play()
    t.Completed:Wait()
end

-- ── Flash helper (animate a button on press) ─────────────────────────────────
local function flash(btn, col)
    local orig = btn.BackgroundColor3
    tw(btn, {BackgroundColor3 = col or C.WHT}, TweenInfo.new(0.05))
    task.delay(0.07, function() tw(btn, {BackgroundColor3 = orig}) end)
end
