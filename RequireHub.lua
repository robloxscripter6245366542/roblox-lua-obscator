--[[
    ╔══════════════════════════════════════════════════════╗
    ║           R E Q U I R E H U B  v1.0                 ║
    ║      Universal Script Loader — Delta iOS             ║
    ║   No http.request · No https.request · Pure          ║
    ╚══════════════════════════════════════════════════════╝
    RightShift  →  Show / Hide
    Drag header →  Move window
--]]

local ok, err = pcall(function()

local Players  = game:GetService("Players")
local TweenSvc = game:GetService("TweenService")
local UIS      = game:GetService("UserInputService")
local LP       = Players.LocalPlayer
local PGui     = LP:WaitForChild("PlayerGui", 10)
if not PGui then return end

pcall(function()
    local o = PGui:FindFirstChild("__REQHUB__")
    if o then o:Destroy() end
end)

pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification",
        {Title="RequireHub", Text="Loading...", Duration=2})
end)

-- ════════════════════════════════════════════════════════
--  THEME
-- ════════════════════════════════════════════════════════
local C = {
    BG      = Color3.fromRGB(7,   7,  13),
    PANEL   = Color3.fromRGB(13,  13, 22),
    CARD    = Color3.fromRGB(20,  20, 34),
    HOVER   = Color3.fromRGB(28,  28, 46),
    ACTIVE  = Color3.fromRGB(35,  25, 65),
    BORDER  = Color3.fromRGB(44,  44, 72),
    BLIGHT  = Color3.fromRGB(70,  50,130),
    ACC     = Color3.fromRGB(110, 60, 255),
    ACC2    = Color3.fromRGB(60,  130,255),
    PINK    = Color3.fromRGB(240, 65, 175),
    TEXT    = Color3.fromRGB(215, 215, 248),
    MUTED   = Color3.fromRGB(90,  90, 145),
    DIM     = Color3.fromRGB(55,  55, 95),
    GREEN   = Color3.fromRGB(50,  215,110),
    RED     = Color3.fromRGB(240, 65,  88),
    YELLOW  = Color3.fromRGB(255, 200, 55),
    WHITE   = Color3.fromRGB(255, 255,255),
    BLACK   = Color3.fromRGB(0,   0,   0),
}

-- ════════════════════════════════════════════════════════
--  HELPERS
-- ════════════════════════════════════════════════════════
local function ti(t, s, d)
    return TweenInfo.new(t,
        Enum.EasingStyle[s  or "Quint"],
        Enum.EasingDirection[d or "Out"])
end
local function tw(o, p, info) TweenSvc:Create(o, info or ti(0.3), p):Play() end

local function Frm(p)
    local f = Instance.new("Frame")
    for k,v in pairs(p or {}) do f[k]=v end
    return f
end
local function Lbl(p)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.GothamBold
    l.TextColor3 = C.TEXT
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextTruncate = Enum.TextTruncate.AtEnd
    for k,v in pairs(p or {}) do l[k]=v end
    return l
end
local function Btn(p)
    local b = Instance.new("TextButton")
    b.AutoButtonColor = false
    b.Font = Enum.Font.GothamBold
    b.TextColor3 = C.WHITE
    b.TextXAlignment = Enum.TextXAlignment.Center
    b.TextTruncate = Enum.TextTruncate.AtEnd
    for k,v in pairs(p or {}) do b[k]=v end
    return b
end
local function Inp(p)
    local i = Instance.new("TextBox")
    i.Font = Enum.Font.Gotham
    i.TextColor3 = C.TEXT
    i.PlaceholderColor3 = C.MUTED
    i.BackgroundTransparency = 1
    i.ClearTextOnFocus = false
    i.TextXAlignment = Enum.TextXAlignment.Left
    for k,v in pairs(p or {}) do i[k]=v end
    return i
end
local function corner(f, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = f; return c
end
local function stroke(f, col, thick)
    local s = Instance.new("UIStroke")
    s.Color = col or C.BORDER; s.Thickness = thick or 1
    s.Parent = f; return s
end
local function pad(f, t, b, l, r)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, t or 8)
    p.PaddingBottom = UDim.new(0, b or 8)
    p.PaddingLeft   = UDim.new(0, l or 8)
    p.PaddingRight  = UDim.new(0, r or 8)
    p.Parent = f
end
local function listV(f, sp)
    local l = Instance.new("UIListLayout")
    l.FillDirection = Enum.FillDirection.Vertical
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Padding = UDim.new(0, sp or 0)
    l.Parent = f; return l
end
local function hov(b, n, h)
    b.MouseEnter:Connect(function() tw(b, {BackgroundColor3=h}) end)
    b.MouseLeave:Connect(function() tw(b, {BackgroundColor3=n}) end)
end

-- ════════════════════════════════════════════════════════
--  SCRIPTS DATABASE
-- ════════════════════════════════════════════════════════
local REPO = "https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/claude/session-UDpk7/"

local CATS = {"All", "Anime", "FPS", "Simulator", "Roleplay", "Universal"}
local CAT_ICON  = {All="◈", Anime="⚔", FPS="🎯", Simulator="🌾", Roleplay="🏠", Universal="🌐"}
local CAT_COLOR = {
    All       = C.ACC,
    Anime     = Color3.fromRGB(255,135,50),
    FPS       = Color3.fromRGB(70, 190,255),
    Simulator = Color3.fromRGB(70, 215, 95),
    Roleplay  = Color3.fromRGB(255,180, 70),
    Universal = Color3.fromRGB(180, 90,255),
}

-- Each entry: cat, game, icon, col, name, desc, url, assetId (optional)
-- assetId: Roblox ModuleScript asset ID — loaded via require(assetId)
--          When set, Load button uses require(); otherwise uses game:HttpGet + loadstring
-- To add your own: upload a ModuleScript to Roblox, copy the asset ID here
local SCRIPTS = {
    -- ── Anime Games ─────────────────────────────────────────────────
    {
        cat="Anime", game="Anime Ball", icon="⚽",
        col=Color3.fromRGB(255,140,50),
        name="Auto Parry Lite",
        desc="Standalone silent auto-parry · no GUI · fastest load",
        url=REPO.."animeball.lua",
        -- assetId = 0000000000,  -- replace with your uploaded module ID
    },
    {
        cat="Anime", game="Anime Ball", icon="⚽",
        col=Color3.fromRGB(255,140,50),
        name="Anime Ball Hub",
        desc="Full hub — Parry/ESP/Visual/Movement/Settings",
        url=REPO.."AnimeBall_Hub.lua",
        -- assetId = 0000000000,
    },
    {
        cat="Anime", game="Blade Ball", icon="🔵",
        col=Color3.fromRGB(75,160,255),
        name="Auto Parry",
        desc="Auto-deflect all blades with predictive timing",
        url="https://raw.githubusercontent.com/7GrandDadPGN/RobloxScripts/main/BladeBallAutoParry.lua",
    },
    {
        cat="Anime", game="Blade Ball", icon="🔵",
        col=Color3.fromRGB(75,160,255),
        name="Spin Cheat",
        desc="Instant spin + infinite jump",
        url="https://raw.githubusercontent.com/7GrandDadPGN/RobloxScripts/main/BladeBallSpin.lua",
    },
    {
        cat="Anime", game="Anime Fighters",icon="⚡",
        col=Color3.fromRGB(240,210,50),
        name="Auto Farm",
        desc="Auto-battle and collect units",
        url="https://rawscripts.net/raw/Anime-Fighters-Simulator-AutoFarm-1111",
    },
    -- ── FPS Games ────────────────────────────────────────────────────
    {
        cat="FPS", game="Arsenal", icon="🔫",
        col=Color3.fromRGB(75,195,255),
        name="Aimbot + ESP",
        desc="Silent-aim · FOV circle · player boxes + health",
        url="https://rawscripts.net/raw/Arsenal-AimbotESP-7777",
    },
    {
        cat="FPS", game="Da Hood", icon="🏙",
        col=Color3.fromRGB(200,155,75),
        name="Anti Ragdoll",
        desc="Stay standing after hits · infinite block",
        url="https://rawscripts.net/raw/Da-Hood-AntiRagdoll-8888",
    },
    {
        cat="FPS", game="Da Hood", icon="🏙",
        col=Color3.fromRGB(200,155,75),
        name="Aimbot",
        desc="Lock-on with FOV slider · prediction",
        url="https://rawscripts.net/raw/Da-Hood-Aimbot-9999",
    },
    {
        cat="FPS", game="Counter Blox", icon="🪖",
        col=Color3.fromRGB(80,160,80),
        name="Aimbot + Wallhack",
        desc="Silent aim · see through walls",
        url="https://rawscripts.net/raw/Counter-Blox-AimbotWH-1234",
    },
    -- ── Simulators ───────────────────────────────────────────────────
    {
        cat="Simulator", game="Blox Fruits", icon="🍎",
        col=Color3.fromRGB(255,80,80),
        name="Auto Farm v2",
        desc="Level up · quest complete · chest farm",
        url="https://raw.githubusercontent.com/acsu1/Blox-Fruit/main/BloxFruit",
    },
    {
        cat="Simulator", game="Blox Fruits", icon="🍎",
        col=Color3.fromRGB(255,80,80),
        name="Fruit ESP",
        desc="Find devil fruits anywhere on the map",
        url="https://rawscripts.net/raw/Blox-Fruits-FruitESP-5678",
    },
    {
        cat="Simulator", game="Pet Sim 99",  icon="🐶",
        col=Color3.fromRGB(115,195,255),
        name="Auto Farm",
        desc="Hatch eggs · collect coins · auto-sell",
        url="https://rawscripts.net/raw/PetSim99-AutoFarm-2222",
    },
    {
        cat="Simulator", game="Anime Adventures",icon="🗡",
        col=Color3.fromRGB(230,120,50),
        name="Auto Farm",
        desc="Auto-stage + unit placement",
        url="https://rawscripts.net/raw/AnimeAdventures-AutoFarm-3333",
    },
    -- ── Roleplay ─────────────────────────────────────────────────────
    {
        cat="Roleplay", game="Brookhaven",    icon="🏡",
        col=Color3.fromRGB(95,215,95),
        name="Admin + Fly",
        desc="Free camera · speed · fly · noclip",
        url="https://rawscripts.net/raw/Brookhaven-Admin-4444",
    },
    {
        cat="Roleplay", game="Murder Mystery 2", icon="🔪",
        col=Color3.fromRGB(205,75,75),
        name="ESP + Knife Drop",
        desc="See knife/gun/sheriff · auto drop when spotted",
        url="https://rawscripts.net/raw/MM2-ESP-KnifeDrop-5555",
    },
    {
        cat="Roleplay", game="Royale High",   icon="👑",
        col=Color3.fromRGB(240,180,255),
        name="Chest Farm",
        desc="Auto-collect seasonal chests for diamonds",
        url="https://rawscripts.net/raw/RoyaleHigh-ChestFarm-6666",
    },
    -- ── Universal ────────────────────────────────────────────────────
    {
        cat="Universal", game="Any Game", icon="⚙",
        col=Color3.fromRGB(180,90,255),
        name="Infinite Yield",
        desc="Admin commands for every Roblox game",
        url="https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source",
    },
    {
        cat="Universal", game="Any Game", icon="🔍",
        col=Color3.fromRGB(90,180,255),
        name="Dex Explorer",
        desc="Browse all game instances + properties",
        url="https://github.com/LorekeeperZinnia/Dex/raw/master/Dex3.1.lua",
    },
    {
        cat="Universal", game="Any Game", icon="📡",
        col=Color3.fromRGB(80,230,150),
        name="Simple Spy",
        desc="Remote spy — capture all RemoteEvent/Function calls",
        url="https://raw.githubusercontent.com/exxtremestuffs/SimpleSpySource/master/SimpleSpy.lua",
    },
    {
        cat="Universal", game="Any Game", icon="🏃",
        col=Color3.fromRGB(255,200,60),
        name="Speed + Fly",
        desc="WalkSpeed · Jump · Fly toggle (client-side)",
        url=REPO.."animeball.lua",   -- placeholder — replace with your preferred script
    },
}

-- ════════════════════════════════════════════════════════
--  SCREEN GUI
-- ════════════════════════════════════════════════════════
local SG = Instance.new("ScreenGui")
SG.Name = "__REQHUB__"
SG.ResetOnSpawn = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.DisplayOrder = 998
SG.IgnoreGuiInset = true
SG.Parent = PGui

-- ════════════════════════════════════════════════════════
--  INTRO OVERLAY
-- ════════════════════════════════════════════════════════
local INTRO = Frm{
    Name="Intro",
    Size=UDim2.fromScale(1,1),
    BackgroundColor3=C.BLACK,
    BackgroundTransparency=0,
    ZIndex=100, Parent=SG,
}

-- Particle rings (3 concentric circles)
local function makeRing(sz, col, tr, parent)
    local r = Frm{
        Size=UDim2.fromOffset(sz,sz),
        AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.fromScale(0.5,0.5),
        BackgroundTransparency=1,
        ZIndex=101, Parent=parent,
    }
    local f = Frm{
        Size=UDim2.fromOffset(sz,sz),
        BackgroundColor3=col,
        BackgroundTransparency=tr,
        ZIndex=101, Parent=r,
    }
    corner(f, sz/2)
    return r, f
end

-- Center orb container (starts invisible/zero size)
local ORB = Frm{
    Size=UDim2.fromOffset(0,0),
    AnchorPoint=Vector2.new(0.5,0.5),
    Position=UDim2.fromScale(0.5, 0.44),
    BackgroundTransparency=1,
    ZIndex=101, Parent=INTRO,
}

local _r1, RING1 = makeRing(110, C.ACC,  0.6, ORB)
local _r2, RING2 = makeRing(80,  C.ACC2, 0.4, ORB)
local _r3, RING3 = makeRing(50,  C.WHITE, 0.0, ORB)
-- "R" glyph
local RGLYPH = Lbl{
    Text="R",
    Font=Enum.Font.GothamBlack,
    TextSize=24,
    TextColor3=C.ACC,
    TextXAlignment=Enum.TextXAlignment.Center,
    Size=UDim2.fromOffset(50,50),
    AnchorPoint=Vector2.new(0.5,0.5),
    Position=UDim2.fromScale(0.5,0.5),
    TextTransparency=1,
    ZIndex=103, Parent=ORB,
}

RING1.BackgroundTransparency = 1
RING2.BackgroundTransparency = 1
RING3.BackgroundTransparency = 1

-- Title / sub / loading text
local ITITLE = Lbl{
    Text="RequireHub",
    Font=Enum.Font.GothamBlack,
    TextSize=30,
    TextColor3=C.WHITE,
    TextXAlignment=Enum.TextXAlignment.Center,
    Size=UDim2.new(1,0,0,40),
    AnchorPoint=Vector2.new(0.5,0),
    Position=UDim2.new(0.5,0, 0.575, 0),
    TextTransparency=1,
    ZIndex=101, Parent=INTRO,
}
local ISUB = Lbl{
    Text="Universal Script Loader",
    Font=Enum.Font.Gotham,
    TextSize=13,
    TextColor3=C.MUTED,
    TextXAlignment=Enum.TextXAlignment.Center,
    Size=UDim2.new(1,0,0,18),
    AnchorPoint=Vector2.new(0.5,0),
    Position=UDim2.new(0.5,0, 0.655, 0),
    TextTransparency=1,
    ZIndex=101, Parent=INTRO,
}
local IDOTS = Lbl{
    Text="· · ·",
    Font=Enum.Font.GothamBold,
    TextSize=11,
    TextColor3=C.ACC,
    TextXAlignment=Enum.TextXAlignment.Center,
    Size=UDim2.new(1,0,0,16),
    AnchorPoint=Vector2.new(0.5,0),
    Position=UDim2.new(0.5,0, 0.725, 0),
    TextTransparency=1,
    ZIndex=101, Parent=INTRO,
}

-- ── Animate intro sequence ────────────────────────────────────────────────────
task.spawn(function()
    task.wait(0.2)

    -- Orb burst in
    tw(ORB, {Size=UDim2.fromOffset(118,118)}, ti(0.45, "Back"))
    task.wait(0.12)
    tw(RING1, {BackgroundTransparency=0.6}, ti(0.4))
    task.wait(0.06)
    tw(RING2, {BackgroundTransparency=0.4}, ti(0.4))
    task.wait(0.06)
    tw(RING3, {BackgroundTransparency=0.0}, ti(0.35))
    task.wait(0.08)
    tw(RGLYPH, {TextTransparency=0}, ti(0.3))
    -- Settle
    task.wait(0.15)
    tw(ORB, {Size=UDim2.fromOffset(110,110)}, ti(0.2))

    -- Text fade in
    task.wait(0.2)
    tw(ITITLE, {TextTransparency=0}, ti(0.4))
    task.wait(0.12)
    tw(ISUB,   {TextTransparency=0}, ti(0.4))
    task.wait(0.12)
    tw(IDOTS,  {TextTransparency=0}, ti(0.3))

    -- Pulse orb 2×
    for _=1,2 do
        task.wait(0.4)
        tw(RING1, {BackgroundTransparency=0.2}, ti(0.5))
        tw(RING2, {BackgroundTransparency=0.1}, ti(0.5))
        task.wait(0.5)
        tw(RING1, {BackgroundTransparency=0.65}, ti(0.5))
        tw(RING2, {BackgroundTransparency=0.45}, ti(0.5))
    end

    -- Exit
    task.wait(0.3)
    tw(INTRO,  {BackgroundTransparency=1}, ti(0.5))
    tw(ITITLE, {TextTransparency=1}, ti(0.35))
    tw(ISUB,   {TextTransparency=1}, ti(0.35))
    tw(IDOTS,  {TextTransparency=1}, ti(0.3))
    tw(RING1,  {BackgroundTransparency=1}, ti(0.4))
    tw(RING2,  {BackgroundTransparency=1}, ti(0.4))
    tw(RING3,  {BackgroundTransparency=1}, ti(0.4))
    tw(RGLYPH, {TextTransparency=1}, ti(0.3))
    task.wait(0.55)
    INTRO:Destroy()
end)

-- ════════════════════════════════════════════════════════
--  MAIN WINDOW
-- ════════════════════════════════════════════════════════
local WIN = Frm{
    Name="Window",
    Size=UDim2.fromOffset(0,0),
    BackgroundTransparency=1,
    AnchorPoint=Vector2.new(0.5,0.5),
    Position=UDim2.fromScale(0.5,0.5),
    BorderSizePixel=0,
    ZIndex=1, Parent=SG,
}
corner(WIN, 12)
stroke(WIN, C.BORDER, 1)

-- Animate WIN in after intro settles
task.spawn(function()
    task.wait(1.65)
    WIN.BackgroundColor3 = C.BG
    tw(WIN, {
        Size=UDim2.fromOffset(580,430),
        BackgroundTransparency=0,
    }, ti(0.5, "Back"))
    task.wait(0.12)
    tw(WIN, {Size=UDim2.fromOffset(560,416)}, ti(0.25))
end)

-- ── Header (44px) ─────────────────────────────────────────────────────────────
local HEADER = Frm{
    Name="Header",
    Size=UDim2.new(1,0,0,44),
    BackgroundColor3=C.PANEL,
    BorderSizePixel=0,
    ZIndex=2, Parent=WIN,
}
corner(HEADER, 12)
-- Fill bottom-corner gap so header flush-meets body
local HFILL = Frm{
    Size=UDim2.new(1,0,0,12),
    Position=UDim2.new(0,0,1,-12),
    BackgroundColor3=C.PANEL,
    BorderSizePixel=0,
    ZIndex=2, Parent=HEADER,
}

-- Accent line below header
local HACC = Frm{
    Size=UDim2.new(1,0,0,1),
    Position=UDim2.new(0,0,1,0),
    BackgroundColor3=C.BLIGHT,
    BorderSizePixel=0,
    ZIndex=3, Parent=HEADER,
}

-- Logo orb
local HLORB = Frm{
    Size=UDim2.fromOffset(28,28),
    AnchorPoint=Vector2.new(0,0.5),
    Position=UDim2.new(0,10,0.5,0),
    BackgroundColor3=C.ACC,
    BorderSizePixel=0,
    ZIndex=3, Parent=HEADER,
}
corner(HLORB, 14)
-- Pulse the logo orb continuously
task.spawn(function()
    while HLORB.Parent do
        tw(HLORB, {BackgroundColor3=C.ACC2}, ti(1.2))
        task.wait(1.2)
        tw(HLORB, {BackgroundColor3=C.ACC},  ti(1.2))
        task.wait(1.2)
    end
end)
Lbl{
    Text="R",
    Font=Enum.Font.GothamBlack,
    TextSize=16,
    TextColor3=C.WHITE,
    TextXAlignment=Enum.TextXAlignment.Center,
    Size=UDim2.fromScale(1,1),
    ZIndex=4, Parent=HLORB,
}

-- Title
Lbl{
    Text="RequireHub",
    Font=Enum.Font.GothamBlack,
    TextSize=16,
    TextColor3=C.TEXT,
    Size=UDim2.new(0,160,1,0),
    Position=UDim2.new(0,46,0,0),
    ZIndex=3, Parent=HEADER,
}
Lbl{
    Text="v1.0 · Script Loader",
    Font=Enum.Font.Gotham,
    TextSize=10,
    TextColor3=C.MUTED,
    Size=UDim2.new(0,160,0,16),
    Position=UDim2.new(0,46,0,24),
    ZIndex=3, Parent=HEADER,
}

-- Script count badge
local COUNT_BADGE = Frm{
    Size=UDim2.fromOffset(50,20),
    AnchorPoint=Vector2.new(1,0.5),
    Position=UDim2.new(1,-72,0.5,0),
    BackgroundColor3=C.ACTIVE,
    BorderSizePixel=0,
    ZIndex=3, Parent=HEADER,
}
corner(COUNT_BADGE, 10)
local COUNT_LBL = Lbl{
    Text=#SCRIPTS.." scripts",
    Font=Enum.Font.GothamBold,
    TextSize=10,
    TextColor3=C.ACC,
    TextXAlignment=Enum.TextXAlignment.Center,
    Size=UDim2.fromScale(1,1),
    ZIndex=4, Parent=COUNT_BADGE,
}

-- Minimize
local HMIN = Btn{
    Text="—",
    Font=Enum.Font.GothamBlack,
    TextSize=14,
    TextColor3=C.MUTED,
    Size=UDim2.fromOffset(28,28),
    AnchorPoint=Vector2.new(1,0.5),
    Position=UDim2.new(1,-36,0.5,0),
    BackgroundColor3=C.CARD,
    BorderSizePixel=0,
    ZIndex=3, Parent=HEADER,
}
corner(HMIN, 6)
hov(HMIN, C.CARD, C.HOVER)

-- Close
local HCLOSE = Btn{
    Text="×",
    Font=Enum.Font.GothamBlack,
    TextSize=18,
    TextColor3=C.RED,
    Size=UDim2.fromOffset(28,28),
    AnchorPoint=Vector2.new(1,0.5),
    Position=UDim2.new(1,-4,0.5,0),
    BackgroundColor3=C.CARD,
    BorderSizePixel=0,
    ZIndex=3, Parent=HEADER,
}
corner(HCLOSE, 6)
hov(HCLOSE, C.CARD, Color3.fromRGB(55,18,22))

HCLOSE.MouseButton1Click:Connect(function()
    tw(WIN, {Size=UDim2.fromOffset(0,0), BackgroundTransparency=1}, ti(0.28, "Back", "In"))
    task.wait(0.35)
    SG:Destroy()
end)

-- ── Body ──────────────────────────────────────────────────────────────────────
local BODY = Frm{
    Name="Body",
    Size=UDim2.new(1,0,1,-45),
    Position=UDim2.new(0,0,0,44),
    BackgroundTransparency=1,
    ZIndex=1, Parent=WIN,
}

-- ── Sidebar (130px) ───────────────────────────────────────────────────────────
local SIDE = Frm{
    Name="Sidebar",
    Size=UDim2.new(0,124,1,0),
    BackgroundColor3=C.PANEL,
    BorderSizePixel=0,
    ZIndex=2, Parent=BODY,
}
-- Round only bottom-left; cover top-right corner
corner(SIDE, 12)
Frm{
    Size=UDim2.new(0,12,0,12),
    Position=UDim2.new(1,-12,0,0),
    BackgroundColor3=C.PANEL,
    BorderSizePixel=0,
    ZIndex=2, Parent=SIDE,
}

-- "CATEGORIES" label
Lbl{
    Text="CATEGORIES",
    Font=Enum.Font.GothamBold,
    TextSize=9,
    TextColor3=C.DIM,
    TextXAlignment=Enum.TextXAlignment.Center,
    Size=UDim2.new(1,0,0,26),
    Position=UDim2.new(0,0,0,6),
    ZIndex=3, Parent=SIDE,
}

-- Category list
local CATLIST = Frm{
    Size=UDim2.new(1,-16,1,-40),
    Position=UDim2.new(0,8,0,38),
    BackgroundTransparency=1,
    ZIndex=3, Parent=SIDE,
}
listV(CATLIST, 5)

-- Vertical divider
Frm{
    Size=UDim2.new(0,1,1,0),
    Position=UDim2.new(0,124,0,0),
    BackgroundColor3=C.BORDER,
    BorderSizePixel=0,
    ZIndex=2, Parent=BODY,
}

-- ── Content panel ─────────────────────────────────────────────────────────────
local CONT = Frm{
    Name="Content",
    Size=UDim2.new(1,-125,1,0),
    Position=UDim2.new(0,125,0,0),
    BackgroundTransparency=1,
    ZIndex=2, Parent=BODY,
}

-- Search bar
local SWRAP = Frm{
    Size=UDim2.new(1,-16,0,34),
    Position=UDim2.new(0,8,0,8),
    BackgroundColor3=C.CARD,
    BorderSizePixel=0,
    ZIndex=3, Parent=CONT,
}
corner(SWRAP, 9)
stroke(SWRAP, C.BORDER, 1)

Lbl{
    Text="⌕",
    Font=Enum.Font.GothamBold,
    TextSize=17,
    TextColor3=C.MUTED,
    TextXAlignment=Enum.TextXAlignment.Center,
    Size=UDim2.fromOffset(30,34),
    ZIndex=4, Parent=SWRAP,
}
local SEARCH = Inp{
    PlaceholderText="Search scripts, games...",
    TextSize=13,
    Size=UDim2.new(1,-34,1,0),
    Position=UDim2.new(0,30,0,0),
    BorderSizePixel=0,
    ZIndex=4, Parent=SWRAP,
}

-- ── Quick Require bar ─────────────────────────────────────────────────────────
local QWRAP = Frm{
    Size=UDim2.new(1,-16,0,30),
    Position=UDim2.new(0,8,0,50),
    BackgroundColor3=C.CARD,
    BorderSizePixel=0,
    ZIndex=3, Parent=CONT,
}
corner(QWRAP, 8)
stroke(QWRAP, C.BLIGHT, 1)

Lbl{
    Text="require",
    Font=Enum.Font.GothamBold,
    TextSize=10,
    TextColor3=C.ACC,
    TextXAlignment=Enum.TextXAlignment.Center,
    Size=UDim2.fromOffset(52,30),
    ZIndex=4, Parent=QWRAP,
}
-- divider
Frm{
    Size=UDim2.fromOffset(1,18),
    AnchorPoint=Vector2.new(0,0.5),
    Position=UDim2.new(0,52,0.5,0),
    BackgroundColor3=C.BORDER,
    BorderSizePixel=0,
    ZIndex=4, Parent=QWRAP,
}
local QINP = Inp{
    PlaceholderText="Asset ID  e.g. 12345678",
    TextSize=12,
    Size=UDim2.new(1,-120,1,0),
    Position=UDim2.new(0,58,0,0),
    BorderSizePixel=0,
    ZIndex=4, Parent=QWRAP,
}
local QBTN = Btn{
    Text="Load",
    Font=Enum.Font.GothamBold,
    TextSize=11,
    TextColor3=C.WHITE,
    Size=UDim2.fromOffset(52,24),
    AnchorPoint=Vector2.new(1,0.5),
    Position=UDim2.new(1,-4,0.5,0),
    BackgroundColor3=C.ACC,
    BorderSizePixel=0,
    ZIndex=4, Parent=QWRAP,
}
corner(QBTN, 6)
hov(QBTN, C.ACC, Color3.fromRGB(140,85,255))

QBTN.MouseButton1Click:Connect(function()
    local idStr = QINP.Text:match("^%s*(%d+)%s*$")
    if not idStr then
        QBTN.Text = "Bad ID"
        QBTN.BackgroundColor3 = C.RED
        task.wait(1.5)
        QBTN.Text = "Load"
        QBTN.BackgroundColor3 = C.ACC
        return
    end
    local assetId = tonumber(idStr)
    QBTN.Text = "⏳"
    QBTN.BackgroundColor3 = C.YELLOW
    local ok2, e2 = pcall(function()
        local m = require(assetId)
        if type(m) == "function" then
            m()
        elseif type(m) == "table" then
            local fn = m.init or m.start or m.run or m.Execute or m.Load
            if type(fn) == "function" then fn() end
        end
    end)
    if ok2 then
        QBTN.Text = "✓"
        QBTN.BackgroundColor3 = C.GREEN
    else
        QBTN.Text = "✗"
        QBTN.BackgroundColor3 = C.RED
        warn("[RequireHub] require("..idStr.."): "..tostring(e2))
    end
    task.wait(2)
    QBTN.Text = "Load"
    QBTN.BackgroundColor3 = C.ACC
end)

-- Script scroll area
local SCROLL = Instance.new("ScrollingFrame")
SCROLL.Name = "ScriptScroll"
SCROLL.Size = UDim2.new(1,-16, 1,-92)
SCROLL.Position = UDim2.new(0,8, 0,86)
SCROLL.BackgroundTransparency = 1
SCROLL.BorderSizePixel = 0
SCROLL.ScrollBarThickness = 3
SCROLL.ScrollBarImageColor3 = C.ACC
SCROLL.CanvasSize = UDim2.new(0,0,0,0)
SCROLL.AutomaticCanvasSize = Enum.AutomaticSize.Y
SCROLL.ZIndex = 3
SCROLL.Parent = CONT
listV(SCROLL, 6)
pad(SCROLL, 0, 8, 0, 0)

-- ════════════════════════════════════════════════════════
--  CATEGORY BUTTONS
-- ════════════════════════════════════════════════════════
local activeCat = "All"
local catBtns   = {}
local allCards  = {}

local function refreshCards(cat, query)
    query = (query or ""):lower():gsub("^%s+",""):gsub("%s+$","")
    local visible = 0
    for _, card in ipairs(allCards) do
        local s = card._data
        local matchCat = (cat == "All") or (s.cat == cat)
        local matchQ   = query == ""
            or s.name:lower():find(query,1,true)
            or s.game:lower():find(query,1,true)
            or s.desc:lower():find(query,1,true)
        card.Visible = matchCat and matchQ
        if matchCat and matchQ then visible = visible + 1 end
    end
    COUNT_LBL.Text = visible.." scripts"
end

local function setCat(cat)
    activeCat = cat
    for c, btn in pairs(catBtns) do
        if c == cat then
            tw(btn.bg, {BackgroundColor3=C.ACTIVE}, ti(0.2))
            tw(btn.icon, {TextColor3=CAT_COLOR[c] or C.ACC}, ti(0.2))
            tw(btn.lbl,  {TextColor3=C.TEXT},                ti(0.2))
            -- Accent line
            tw(btn.bar, {BackgroundTransparency=0}, ti(0.2))
        else
            tw(btn.bg,   {BackgroundColor3=C.HOVER}, ti(0.2))
            tw(btn.icon, {TextColor3=C.MUTED},       ti(0.2))
            tw(btn.lbl,  {TextColor3=C.MUTED},       ti(0.2))
            tw(btn.bar,  {BackgroundTransparency=1},  ti(0.2))
        end
    end
    refreshCards(activeCat, SEARCH.Text)
end

for i, cat in ipairs(CATS) do
    local isActive = (cat == "All")
    local BG = Btn{
        Text="",
        Size=UDim2.new(1,0,0,38),
        BackgroundColor3=isActive and C.ACTIVE or C.HOVER,
        BorderSizePixel=0,
        LayoutOrder=i,
        ZIndex=4, Parent=CATLIST,
    }
    corner(BG, 8)

    -- Left accent bar
    local BAR = Frm{
        Size=UDim2.new(0,3,0.7,0),
        AnchorPoint=Vector2.new(0,0.5),
        Position=UDim2.new(0,0,0.5,0),
        BackgroundColor3=CAT_COLOR[cat] or C.ACC,
        BackgroundTransparency=isActive and 0 or 1,
        BorderSizePixel=0,
        ZIndex=5, Parent=BG,
    }
    corner(BAR, 2)

    local ICON_L = Lbl{
        Text=CAT_ICON[cat],
        Font=Enum.Font.GothamBold,
        TextSize=14,
        TextColor3=isActive and (CAT_COLOR[cat] or C.ACC) or C.MUTED,
        TextXAlignment=Enum.TextXAlignment.Center,
        Size=UDim2.fromOffset(24,38),
        Position=UDim2.new(0,8,0,0),
        ZIndex=5, Parent=BG,
    }
    local CAT_L = Lbl{
        Text=cat,
        Font=Enum.Font.GothamBold,
        TextSize=12,
        TextColor3=isActive and C.TEXT or C.MUTED,
        Size=UDim2.new(1,-36,1,0),
        Position=UDim2.new(0,34,0,0),
        ZIndex=5, Parent=BG,
    }

    if not isActive then
        BG.MouseEnter:Connect(function()
            if activeCat ~= cat then
                tw(BG, {BackgroundColor3=C.CARD})
            end
        end)
        BG.MouseLeave:Connect(function()
            if activeCat ~= cat then
                tw(BG, {BackgroundColor3=C.HOVER})
            end
        end)
    end

    BG.MouseButton1Click:Connect(function() setCat(cat) end)

    catBtns[cat] = {bg=BG, icon=ICON_L, lbl=CAT_L, bar=BAR}
end

-- ════════════════════════════════════════════════════════
--  SCRIPT CARDS
-- ════════════════════════════════════════════════════════
local function buildCard(s, idx)
    local CARD = Frm{
        Name="Card"..idx,
        Size=UDim2.new(1,0,0,72),
        BackgroundColor3=C.CARD,
        BorderSizePixel=0,
        LayoutOrder=idx,
        ZIndex=4, Parent=SCROLL,
    }
    corner(CARD, 8)
    stroke(CARD, C.BORDER, 1)

    -- Color accent strip
    local STRIP = Frm{
        Size=UDim2.new(0,3,0.65,0),
        AnchorPoint=Vector2.new(0,0.5),
        Position=UDim2.new(0,0,0.5,0),
        BackgroundColor3=s.col or C.ACC,
        BorderSizePixel=0,
        ZIndex=5, Parent=CARD,
    }
    corner(STRIP, 2)

    -- Game icon
    Lbl{
        Text=s.icon,
        Font=Enum.Font.GothamBold,
        TextSize=26,
        TextXAlignment=Enum.TextXAlignment.Center,
        Size=UDim2.fromOffset(38,72),
        Position=UDim2.new(0,10,0,0),
        ZIndex=5, Parent=CARD,
    }

    -- Game name (small chip)
    local GAME_L = Lbl{
        Text=s.game,
        Font=Enum.Font.Gotham,
        TextSize=10,
        TextColor3=s.col or C.ACC,
        Size=UDim2.new(1,-175,0,14),
        Position=UDim2.new(0,52,0,12),
        ZIndex=5, Parent=CARD,
    }

    -- Script name
    Lbl{
        Text=s.name,
        Font=Enum.Font.GothamBold,
        TextSize=14,
        TextColor3=C.TEXT,
        Size=UDim2.new(1,-175,0,18),
        Position=UDim2.new(0,52,0,25),
        ZIndex=5, Parent=CARD,
    }

    -- Description
    Lbl{
        Text=s.desc,
        Font=Enum.Font.Gotham,
        TextSize=11,
        TextColor3=C.MUTED,
        Size=UDim2.new(1,-175,0,14),
        Position=UDim2.new(0,52,0,45),
        ZIndex=5, Parent=CARD,
    }

    -- Category chip
    local CCHIP = Frm{
        Size=UDim2.fromOffset(54,18),
        AnchorPoint=Vector2.new(1,0),
        Position=UDim2.new(1,-10,0,10),
        BackgroundColor3=C.ACTIVE,
        BorderSizePixel=0,
        ZIndex=5, Parent=CARD,
    }
    corner(CCHIP, 9)
    Lbl{
        Text=s.cat,
        Font=Enum.Font.GothamBold,
        TextSize=9,
        TextColor3=CAT_COLOR[s.cat] or C.ACC,
        TextXAlignment=Enum.TextXAlignment.Center,
        Size=UDim2.fromScale(1,1),
        ZIndex=6, Parent=CCHIP,
    }

    -- Load-mode badge: "require" (purple) vs "http" (blue)
    local isRequire = (s.assetId ~= nil)
    local MBADGE = Frm{
        Size=UDim2.fromOffset(isRequire and 52 or 36, 16),
        AnchorPoint=Vector2.new(1,0),
        Position=UDim2.new(1,-10,0,32),
        BackgroundColor3=isRequire and C.ACTIVE or Color3.fromRGB(15,30,50),
        BorderSizePixel=0,
        ZIndex=5, Parent=CARD,
    }
    corner(MBADGE, 8)
    Lbl{
        Text=isRequire and "require()" or "http",
        Font=Enum.Font.GothamBold,
        TextSize=9,
        TextColor3=isRequire and C.ACC or C.ACC2,
        TextXAlignment=Enum.TextXAlignment.Center,
        Size=UDim2.fromScale(1,1),
        ZIndex=6, Parent=MBADGE,
    }

    -- Copy URL button
    local COPY = Btn{
        Text="⎘",
        Font=Enum.Font.GothamBold,
        TextSize=14,
        TextColor3=C.MUTED,
        Size=UDim2.fromOffset(30,30),
        AnchorPoint=Vector2.new(1,1),
        Position=UDim2.new(1,-10,1,-10),
        BackgroundColor3=C.HOVER,
        BorderSizePixel=0,
        ZIndex=5, Parent=CARD,
    }
    corner(COPY, 7)
    hov(COPY, C.HOVER, C.CARD)

    -- Load button
    local LOAD = Btn{
        Text="▶  Load",
        Font=Enum.Font.GothamBold,
        TextSize=12,
        TextColor3=C.WHITE,
        Size=UDim2.fromOffset(80,30),
        AnchorPoint=Vector2.new(1,1),
        Position=UDim2.new(1,-46,1,-10),
        BackgroundColor3=C.ACC,
        BorderSizePixel=0,
        ZIndex=5, Parent=CARD,
    }
    corner(LOAD, 7)
    hov(LOAD, C.ACC, Color3.fromRGB(140,85,255))

    -- ── Card hover glow ────────────────────────────────────────────────────
    CARD.MouseEnter:Connect(function()
        tw(CARD,  {BackgroundColor3=C.HOVER})
        tw(STRIP, {BackgroundTransparency=0.2})
    end)
    CARD.MouseLeave:Connect(function()
        tw(CARD,  {BackgroundColor3=C.CARD})
        tw(STRIP, {BackgroundTransparency=0})
    end)

    -- ── Load script (require if assetId set, else HttpGet + loadstring) ───────
    LOAD.MouseButton1Click:Connect(function()
        LOAD.Text = "⏳"
        LOAD.BackgroundColor3 = C.YELLOW
        local ok2, e2 = pcall(function()
            if s.assetId then
                -- Require mode: load Roblox ModuleScript asset by ID
                local m = require(s.assetId)
                if type(m) == "function" then
                    m()
                elseif type(m) == "table" then
                    local fn = m.init or m.start or m.run or m.Execute or m.Load
                    if type(fn) == "function" then fn() end
                end
            else
                -- HTTP mode: fetch raw source and loadstring it
                local src = game:HttpGet(s.url, true)
                local fn, ce = loadstring(src)
                if not fn then error("compile: "..tostring(ce)) end
                fn()
            end
        end)
        if ok2 then
            LOAD.Text = "✓ Done"
            LOAD.BackgroundColor3 = C.GREEN
        else
            LOAD.Text = "✗ Fail"
            LOAD.BackgroundColor3 = C.RED
            warn("[RequireHub] "..s.name..": "..tostring(e2))
        end
        task.wait(2.2)
        LOAD.Text = "▶  Load"
        LOAD.BackgroundColor3 = C.ACC
    end)

    -- ── Copy: copies require(ID) when assetId set, otherwise copies URL ───────
    COPY.MouseButton1Click:Connect(function()
        if setclipboard then
            local toCopy = s.assetId
                and ('require('..tostring(s.assetId)..')')
                or  s.url
            pcall(setclipboard, toCopy)
            COPY.Text = "✓"
            COPY.TextColor3 = C.GREEN
            task.wait(1.6)
            COPY.Text = "⎘"
            COPY.TextColor3 = C.MUTED
        end
    end)

    CARD._data = s
    return CARD
end

for i, s in ipairs(SCRIPTS) do
    local card = buildCard(s, i)
    table.insert(allCards, card)
end

-- ════════════════════════════════════════════════════════
--  LIVE SEARCH
-- ════════════════════════════════════════════════════════
SEARCH:GetPropertyChangedSignal("Text"):Connect(function()
    refreshCards(activeCat, SEARCH.Text)
end)
-- Highlight search bar on focus
SEARCH.Focused:Connect(function()
    tw(SWRAP, {BackgroundColor3=C.HOVER})
    stroke(SWRAP, C.BLIGHT, 1)
end)
SEARCH.FocusLost:Connect(function()
    tw(SWRAP, {BackgroundColor3=C.CARD})
end)

-- Initial filter
setCat("All")

-- ════════════════════════════════════════════════════════
--  STATUS BAR
-- ════════════════════════════════════════════════════════
local STATBAR = Frm{
    Name="StatusBar",
    Size=UDim2.new(1,0,0,22),
    Position=UDim2.new(0,0,1,-22),
    BackgroundColor3=C.PANEL,
    BorderSizePixel=0,
    ZIndex=3, Parent=WIN,
}
corner(STATBAR, 12)
-- Fill top-corner gap
Frm{
    Size=UDim2.new(1,0,0,12),
    BackgroundColor3=C.PANEL,
    BorderSizePixel=0,
    ZIndex=3, Parent=STATBAR,
}
Lbl{
    Text="● Ready  ·  RightShift to toggle  ·  Drag header to move",
    Font=Enum.Font.Gotham,
    TextSize=10,
    TextColor3=C.DIM,
    Size=UDim2.new(1,-12,1,0),
    Position=UDim2.new(0,10,0,0),
    ZIndex=4, Parent=STATBAR,
}

-- ════════════════════════════════════════════════════════
--  DRAG
-- ════════════════════════════════════════════════════════
local dragging, dragStart, winStart = false, nil, nil
HEADER.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        dragging  = true
        dragStart = inp.Position
        winStart  = WIN.Position
    end
end)
HEADER.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
UIS.InputChanged:Connect(function(inp)
    if not dragging then return end
    if inp.UserInputType == Enum.UserInputType.MouseMovement
    or inp.UserInputType == Enum.UserInputType.Touch then
        local d = inp.Position - dragStart
        WIN.Position = UDim2.new(
            winStart.X.Scale, winStart.X.Offset + d.X,
            winStart.Y.Scale, winStart.Y.Offset + d.Y)
    end
end)

-- ════════════════════════════════════════════════════════
--  MINIMIZE
-- ════════════════════════════════════════════════════════
local minimized = false
HMIN.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        tw(WIN, {Size=UDim2.fromOffset(560,44)}, ti(0.3))
        HMIN.Text = "+"
    else
        tw(WIN, {Size=UDim2.fromOffset(560,416)}, ti(0.4, "Back"))
        HMIN.Text = "—"
    end
end)

-- ════════════════════════════════════════════════════════
--  RIGHT-SHIFT TOGGLE
-- ════════════════════════════════════════════════════════
local visible = true
UIS.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.RightShift then
        visible = not visible
        if visible then
            WIN.Visible = true
            tw(WIN, {Size=UDim2.fromOffset(560,416), BackgroundTransparency=0}, ti(0.35, "Back"))
        else
            tw(WIN, {Size=UDim2.fromOffset(0,0), BackgroundTransparency=1}, ti(0.25, "Quint", "In"))
            task.delay(0.3, function() WIN.Visible = false end)
        end
    end
end)

-- Done
pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification",
        {Title="RequireHub", Text="Ready ✓ · "..#SCRIPTS.." scripts", Duration=3})
end)

end)
if not ok then warn("[RequireHub] Error: "..tostring(err)) end
