-- AutoClicker v3.1
-- Scan-first: detects device + executor, tests every UNC function, THEN picks
-- the right click method from those results. 50k CPS burst engine. Never crashes.
-- Fires mouse1click + touchTap simultaneously — works whether a game uses
-- click-to-block OR tap-to-block (Blade Ball, Anime Ball, etc.) with no config.
-- Toggle: [E] or tap the pill. Drag the card to move. Drag the slider for speed.

-- ── State ─────────────────────────────────────────────────────────────────────
local AC = {
    Enabled    = false,
    CPS        = 50000,
    Budget     = 0.004,   -- max seconds per frame (anti-crash cap)
    SkipOverUI = true,    -- skip clicking when cursor is over a GUI element
    Method     = "scanning…",
    ClickCount = 0,
    _click     = nil,     -- set AFTER the scan determines the best method
}
if type(getgenv) == "function" then getgenv().AutoClicker = AC end

-- ── Services ──────────────────────────────────────────────────────────────────
local RunSvc    = game:GetService("RunService")
local UIS       = game:GetService("UserInputService")
local TweenSvc  = game:GetService("TweenService")
local Players   = game:GetService("Players")

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function resolve(name)
    if type(getgenv) == "function" then
        local v = getgenv()[name]
        if type(v) == "function" then return v end
    end
    if type(_G[name]) == "function" then return _G[name] end
    return nil
end

local function tw(obj, t, props, style, dir)
    return TweenSvc:Create(obj, TweenInfo.new(
        t or 0.25,
        style or Enum.EasingStyle.Quint,
        dir   or Enum.EasingDirection.Out
    ), props)
end
local function corner(p, r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r); c.Parent=p; return c end
local function grad(p, a, b, rot) local g=Instance.new("UIGradient"); g.Color=ColorSequence.new(a,b); g.Rotation=rot or 0; g.Parent=p; return g end
local function stroke(p, col, th, tr) local s=Instance.new("UIStroke"); s.Color=col; s.Thickness=th or 1; s.Transparency=tr or 0; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=p; return s end

local THEME = {
    A   = Color3.fromRGB(170, 80, 255),
    B   = Color3.fromRGB(90, 200, 255),
    On  = Color3.fromRGB(70, 230, 160),
    OnB = Color3.fromRGB(120, 255, 210),
    Off = Color3.fromRGB(255, 90, 110),
    OfB = Color3.fromRGB(255, 150, 90),
    Gl  = Color3.fromRGB(22, 22, 32),
    Txt = Color3.fromRGB(235, 235, 245),
    Dim = Color3.fromRGB(150, 150, 170),
}

-- screen-center touch position: safe from joystick (bottom-left) and jump button (bottom-right)
local function getSafePos()
    local cam = workspace.CurrentCamera
    local vp  = cam and cam.ViewportSize or Vector2.new(1280, 720)
    return Vector2.new(vp.X * 0.5, vp.Y * 0.5)
end

-- ── Container ─────────────────────────────────────────────────────────────────
local function getContainer()
    if type(getgenv)=="function" and type(getgenv().gethui)=="function" then return getgenv().gethui() end
    if type(gethui)=="function" then return gethui() end
    return Players.LocalPlayer:WaitForChild("PlayerGui")
end
local container = getContainer()
for _, n in ipairs({"AutoClickerUI","AutoClickerIntro"}) do
    local o = container:FindFirstChild(n); if o then o:Destroy() end
end

-- ── Burst engine (uses AC._click set after scan) ──────────────────────────────
local function cursorOverGui()
    local lp = Players.LocalPlayer
    local pg = lp and lp:FindFirstChildOfClass("PlayerGui")
    if not pg then return false end
    local mp = UIS:GetMouseLocation()
    local ok, objs = pcall(function() return pg:GetGuiObjectsAtPosition(mp.X, mp.Y - 36) end)
    return ok and objs and #objs > 0
end

local lastClock = os.clock()
local function burst()
    if not AC.Enabled or not AC._click then return end
    if AC.SkipOverUI and cursorOverGui() then return end

    local now = os.clock()
    local dt  = now - lastClock; lastClock = now
    if dt <= 0 then dt = 1/60 end

    local quota   = math.max(1, AC.CPS * dt)
    local startT  = os.clock()
    local fired   = 0
    while fired < quota do
        pcall(AC._click)
        fired = fired + 1
        if (os.clock() - startT) >= AC.Budget then break end
    end
    AC.ClickCount = AC.ClickCount + fired
end

local bound = false
pcall(function()
    RunSvc:BindToRenderStep("ACBurst", Enum.RenderPriority.First.Value - 1, burst)
    bound = true
end)
if not bound then RunSvc.Heartbeat:Connect(burst) end

function AC:Start()  self.Enabled = true  end
function AC:Stop()   self.Enabled = false end
function AC:Toggle() self.Enabled = not self.Enabled; return self.Enabled end

-- ── Keybind [E] ───────────────────────────────────────────────────────────────
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.E then
        local on = AC:Toggle()
        if AC.OnVisual then AC.OnVisual() end
        print(("[AutoClicker] %s | %d clicks | %s"):format(on and "ON" or "OFF", AC.ClickCount, AC.Method))
    end
end)

-- ══════════════════════════════════════════════════════════════════════════════
--  INTRO / SCAN — runs first, then hands off to the main UI
-- ══════════════════════════════════════════════════════════════════════════════
do
    local cam    = workspace.CurrentCamera
    local vp     = cam and cam.ViewportSize or Vector2.new(1280, 720)
    local minDim = math.min(vp.X, vp.Y)

    -- ── Platform ──────────────────────────────────────────────────────────────
    local isTouch = UIS.TouchEnabled
    local isKbd   = UIS.KeyboardEnabled
    local platform, isPad
    if isTouch and not isKbd then
        isPad    = minDim >= 700
        platform = isPad and "iPad / Tablet" or "Phone"
    elseif isTouch and isKbd then
        isPad    = minDim >= 700
        platform = "Tablet + Keyboard"
    else
        isPad    = false
        platform = "PC"
    end
    local fast = isPad   -- iPad path: shorter delays

    -- ── Executor ──────────────────────────────────────────────────────────────
    local execName = "Unknown"
    pcall(function()
        local n
        if identifyexecutor then n = identifyexecutor()
        elseif getexecutorname then n = getexecutorname()
        elseif syn   then n = "Synapse X"
        elseif KRNL_LOADED then n = "KRNL"
        elseif fluxus then n = "Fluxus"
        elseif is_sirhurt_closure then n = "SirHurt"
        elseif type(getgenv) == "function" then n = "Generic (UNC)"
        end
        if type(n) == "string" and #n > 0 then execName = n end
    end)

    -- ── UNC function list to scan ─────────────────────────────────────────────
    local UNC_LIST = {
        "mouse1click", "mouse1press", "mouse1release",
        "mouse2click", "mouse2press", "mouse2release",
        "touchTap",    "touchStart",  "touchEnd",
        "getgenv",     "gethui",      "hookfunction",
        "newcclosure", "hookmetamethod","getconnections","firesignal",
    }
    local found = {}   -- name → bool, filled during scan

    -- ── Scan cache ────────────────────────────────────────────────────────────
    local CACHE_FILE  = "ac_scan_cache.txt"
    local canWrite    = type(writefile) == "function"
    local canRead     = type(readfile)  == "function"

    local function saveCache(fc, method)
        if not canWrite then return end
        pcall(writefile, CACHE_FILE, platform.."|"..execName.."|"..tostring(fc).."|"..method)
    end
    local function loadCache()
        if not canRead then return nil end
        local ok, raw = pcall(readfile, CACHE_FILE)
        if not ok or type(raw) ~= "string" or raw == "" then return nil end
        local p,e,fc,m = raw:match("^([^|]+)|([^|]+)|(%d+)|(.+)$")
        if not p then return nil end
        return { platform=p, executor=e, foundCount=tonumber(fc), method=m }
    end

    -- quick pre-count to detect environment change vs cache
    local preCount = 0
    for _, n in ipairs(UNC_LIST) do if resolve(n) then preCount = preCount + 1 end end

    local cache     = loadCache()
    local cacheHit  = cache
        and cache.platform   == platform
        and cache.executor   == execName
        and cache.foundCount == preCount

    -- ── Build scan UI ─────────────────────────────────────────────────────────
    local Intro = Instance.new("ScreenGui")
    Intro.Name           = "AutoClickerIntro"
    Intro.ResetOnSpawn   = false
    Intro.IgnoreGuiInset = true
    Intro.DisplayOrder   = 99999
    Intro.Parent         = container

    local Backdrop = Instance.new("Frame")
    Backdrop.Size = UDim2.fromScale(1,1)
    Backdrop.BackgroundColor3      = Color3.new(0,0,0)
    Backdrop.BackgroundTransparency = 1
    Backdrop.BorderSizePixel       = 0
    Backdrop.Parent = Intro
    tw(Backdrop, 0.4, {BackgroundTransparency = 0.5}):Play()

    local W = isPad and 540 or 460
    local H = isPad and 380 or 340

    local Panel = Instance.new("Frame")
    Panel.AnchorPoint          = Vector2.new(0.5, 0.5)
    Panel.Position             = UDim2.fromScale(0.5, 0.5)
    Panel.Size                 = UDim2.fromOffset(W, 0)   -- opens via tween
    Panel.BackgroundColor3     = THEME.Gl
    Panel.BackgroundTransparency = 0.15
    Panel.BorderSizePixel      = 0
    Panel.Parent               = Intro
    corner(Panel, 22)
    grad(Panel, Color3.fromRGB(36,30,56), Color3.fromRGB(16,16,26), 90)
    local ps = stroke(Panel, THEME.A, 1.5, 0.05)
    grad(ps, THEME.A, THEME.B, 30)

    local PGlow = Instance.new("ImageLabel")
    PGlow.BackgroundTransparency = 1
    PGlow.Image            = "rbxassetid://6014261993"
    PGlow.ImageColor3      = THEME.A
    PGlow.ImageTransparency = 0.4
    PGlow.AnchorPoint      = Vector2.new(0.5,0.5)
    PGlow.Position         = UDim2.fromScale(0.5,0.5)
    PGlow.ScaleType        = Enum.ScaleType.Slice
    PGlow.SliceCenter      = Rect.new(49,49,450,450)
    PGlow.Size             = UDim2.new(1,80,1,80)
    PGlow.ZIndex           = 0
    PGlow.Parent           = Panel

    local Title = Instance.new("TextLabel")
    Title.BackgroundTransparency = 1
    Title.Position  = UDim2.new(0,0,0,28)
    Title.Size      = UDim2.new(1,0,0,36)
    Title.Font      = Enum.Font.GothamBlack
    Title.TextSize  = isPad and 36 or 30
    Title.Text      = "AUTOCLICKER"
    Title.TextColor3 = THEME.Txt
    Title.Parent    = Panel
    grad(Title, THEME.B, THEME.A, 0)

    local Sub = Instance.new("TextLabel")
    Sub.BackgroundTransparency = 1
    Sub.Position   = UDim2.new(0,0,0,67)
    Sub.Size       = UDim2.new(1,0,0,16)
    Sub.Font       = Enum.Font.Gotham
    Sub.TextSize   = 12
    Sub.TextColor3 = THEME.Dim
    Sub.Text       = "scanning environment…"
    Sub.Parent     = Panel

    -- info rows
    local function makeRow(yOff, labelTxt)
        local row = Instance.new("Frame")
        row.BackgroundTransparency = 1
        row.Position = UDim2.new(0,36,0,yOff)
        row.Size     = UDim2.new(1,-72,0,20)
        row.Parent   = Panel
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.fromOffset(120,20)
        lbl.Font = Enum.Font.Gotham; lbl.TextSize = 13
        lbl.TextColor3 = THEME.Dim; lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = labelTxt; lbl.Parent = row
        local val = Instance.new("TextLabel")
        val.BackgroundTransparency = 1
        val.AnchorPoint = Vector2.new(1,0)
        val.Position    = UDim2.new(1,0,0,0)
        val.Size        = UDim2.new(1,-125,1,0)
        val.Font = Enum.Font.GothamBold; val.TextSize = 13
        val.TextColor3 = THEME.B; val.TextXAlignment = Enum.TextXAlignment.Right
        val.Text = "…"; val.Parent = row
        return val
    end

    local vPlat  = makeRow(100, "Platform")
    local vExec  = makeRow(126, "Executor")
    local vUNC   = makeRow(152, "UNC Functions")
    local vTest  = makeRow(178, "Click Method")
    local vCache = makeRow(204, "Cache")

    local Status = Instance.new("TextLabel")
    Status.BackgroundTransparency = 1
    Status.AnchorPoint  = Vector2.new(0.5,1)
    Status.Position     = UDim2.new(0.5,0,1,-50)
    Status.Size         = UDim2.new(1,-72,0,18)
    Status.Font         = Enum.Font.GothamMedium; Status.TextSize = 12
    Status.TextColor3   = THEME.Txt; Status.Text = "Starting…"
    Status.Parent       = Panel

    local PTrack = Instance.new("Frame")
    PTrack.AnchorPoint          = Vector2.new(0.5,1)
    PTrack.Position             = UDim2.new(0.5,0,1,-24)
    PTrack.Size                 = UDim2.new(1,-72,0,8)
    PTrack.BackgroundColor3     = Color3.fromRGB(45,45,62)
    PTrack.BackgroundTransparency = 0.2
    PTrack.BorderSizePixel      = 0
    PTrack.Parent               = Panel
    corner(PTrack, 4)
    local PFill = Instance.new("Frame")
    PFill.Size = UDim2.fromScale(0,1)
    PFill.BackgroundColor3 = Color3.new(1,1,1)
    PFill.BorderSizePixel  = 0
    PFill.Parent = PTrack
    corner(PFill, 4)
    grad(PFill, THEME.A, THEME.B, 0)

    -- entrance animation
    tw(Panel, 0.5, {Size = UDim2.fromOffset(W, H)}, Enum.EasingStyle.Back):Play()

    local step = fast and 0.18 or 0.32
    local function prog(p, msg)
        tw(PFill, 0.3, {Size = UDim2.fromScale(math.clamp(p,0,1), 1)}):Play()
        if msg then Status.Text = msg end
    end

    task.wait(0.5)

    -- ── CACHE HIT — skip full scan ────────────────────────────────────────────
    if cacheHit then
        Sub.Text = "environment unchanged • loading from cache"
        tw(Sub, 0.3, {TextColor3 = THEME.B}):Play()

        vPlat.Text  = cache.platform;  vPlat.TextColor3  = THEME.On
        vExec.Text  = cache.executor;  vExec.TextColor3  = THEME.On
        vUNC.Text   = cache.foundCount.." / "..#UNC_LIST; vUNC.TextColor3 = THEME.On
        vTest.Text  = cache.method;    vTest.TextColor3  = THEME.On
        vCache.Text = "HIT (saved)";   vCache.TextColor3 = THEME.On

        tw(PFill, 0.5, {Size = UDim2.fromScale(1,1)}, Enum.EasingStyle.Quint):Play()
        prog(1, "Ready — all clear")
        task.wait(fast and 0.35 or 0.55)

        -- restore method from cache (skip re-detection below, handled after do-end)
        AC.Method  = cache.method
    else
        -- ── FULL SCAN ─────────────────────────────────────────────────────────
        if cache then
            Sub.Text = "environment changed • rescanning…"
            tw(Sub, 0.3, {TextColor3 = THEME.Off}):Play()
            task.wait(0.4)
        end

        -- 1) platform
        Status.Text = "Detecting device…"
        task.wait(step)
        vPlat.Text = platform; vPlat.TextColor3 = THEME.On
        prog(0.20)

        -- 2) executor
        Status.Text = "Identifying executor…"
        task.wait(step)
        vExec.Text = execName; vExec.TextColor3 = THEME.On
        prog(0.38)

        -- 3) scan every UNC function
        Status.Text = "Scanning UNC functions…"
        local fc = 0
        for i, name in ipairs(UNC_LIST) do
            local avail = resolve(name) ~= nil
            found[name] = avail
            if avail then fc = fc + 1 end
            vUNC.Text = fc.." / "..#UNC_LIST
            prog(0.38 + 0.42 * (i / #UNC_LIST))
            task.wait(fast and 0.012 or 0.038)
        end
        vUNC.TextColor3 = fc > 0 and THEME.On or THEME.Off

        -- 4) determine best click method FROM scan results
        Status.Text = "Selecting click method…"
        task.wait(step * 0.6)

        local pos   = getSafePos()
        local parts, names2 = {}, {}

        -- ALWAYS fire mouse1 input (covers click-to-block games: Blade Ball PC, etc.)
        if found.mouse1click then
            parts[#parts+1] = resolve("mouse1click")
            names2[#names2+1] = "mouse1click"
        elseif found.mouse1press and found.mouse1release then
            local mp, mr = resolve("mouse1press"), resolve("mouse1release")
            parts[#parts+1] = function() mp(); mr() end
            names2[#names2+1] = "mouse1press/release"
        elseif found.mouse2click then
            parts[#parts+1] = resolve("mouse2click")
            names2[#names2+1] = "mouse2click"
        elseif found.mouse2press and found.mouse2release then
            local mp2, mr2 = resolve("mouse2press"), resolve("mouse2release")
            parts[#parts+1] = function() mp2(); mr2() end
            names2[#names2+1] = "mouse2press/release"
        end

        -- ALWAYS fire touch input on top (covers tap-to-block games: Blade Ball Mobile,
        -- Anime Ball mobile mode, etc.) — firing both means the script works regardless
        -- of whether the game reads mouse or touch for its block/action mechanic.
        if found.touchTap then
            local tt = resolve("touchTap")
            parts[#parts+1] = function() tt({pos}) end
            names2[#names2+1] = "touchTap"
        elseif found.touchStart and found.touchEnd then
            local ts, te = resolve("touchStart"), resolve("touchEnd")
            parts[#parts+1] = function() ts({pos}); te({pos}) end
            names2[#names2+1] = "touchStart/End"
        end

        -- last resort: VIM (if executor provides no UNC input functions at all)
        if #parts == 0 then
            local vim = game:GetService("VirtualInputManager")
            parts[#parts+1] = function()
                vim:SendMouseButtonEvent(0,0,0,true,game,0)
                vim:SendMouseButtonEvent(0,0,0,false,game,0)
            end
            names2[#names2+1] = "VirtualInputManager"
        end

        -- wire up AC._click from scan results
        if #parts == 1 then
            AC._click = parts[1]
        else
            AC._click = function() for i=1,#parts do parts[i]() end end
        end
        AC.Method = table.concat(names2, " + ")

        -- UNC test
        local testOk = type(AC._click) == "function"
        vTest.Text = AC.Method; vTest.TextColor3 = testOk and THEME.On or THEME.Off

        -- cache status
        vCache.Text = canWrite and "Saved" or "No writefile"; vCache.TextColor3 = THEME.Dim

        prog(1, "Ready — launching AutoClicker")
        Sub.Text = "method: "..AC.Method

        saveCache(fc, AC.Method)
        task.wait(fast and 0.4 or 0.65)
    end

    -- ── Fade out ──────────────────────────────────────────────────────────────
    tw(Panel,    0.35, {BackgroundTransparency = 1}):Play()
    tw(Backdrop, 0.4,  {BackgroundTransparency = 1}):Play()
    for _, d in ipairs(Panel:GetDescendants()) do
        if d:IsA("TextLabel") then tw(d, 0.25, {TextTransparency = 1}):Play() end
        if d:IsA("Frame")     then tw(d, 0.25, {BackgroundTransparency = 1}):Play() end
        if d:IsA("ImageLabel")then tw(d, 0.25, {ImageTransparency = 1}):Play() end
    end
    task.wait(0.4)
    Intro:Destroy()
end

-- if cache was hit, _click still needs to be wired (no scan ran)
if not AC._click then
    local pos = getSafePos()
    local function r(n) return resolve(n) end
    local parts, names2 = {}, {}
    -- mouse input (click-to-block games)
    if r"mouse1click" then parts[#parts+1]=r"mouse1click"; names2[#names2+1]="mouse1click"
    elseif r"mouse1press" and r"mouse1release" then
        local mp,mr=r"mouse1press",r"mouse1release"
        parts[#parts+1]=function() mp();mr() end; names2[#names2+1]="mouse1press/release"
    elseif r"mouse2click" then parts[#parts+1]=r"mouse2click"; names2[#names2+1]="mouse2click"
    elseif r"mouse2press" and r"mouse2release" then
        local mp2,mr2=r"mouse2press",r"mouse2release"
        parts[#parts+1]=function() mp2();mr2() end; names2[#names2+1]="mouse2press/release"
    end
    -- touch input on top (tap-to-block games — fires simultaneously with mouse)
    if r"touchTap" then
        local tt=r"touchTap"; parts[#parts+1]=function() tt({pos}) end; names2[#names2+1]="touchTap"
    elseif r"touchStart" and r"touchEnd" then
        local ts,te=r"touchStart",r"touchEnd"
        parts[#parts+1]=function() ts({pos});te({pos}) end; names2[#names2+1]="touchStart/End"
    end
    -- last resort
    if #parts==0 then
        local vim=game:GetService("VirtualInputManager")
        parts[1]=function() vim:SendMouseButtonEvent(0,0,0,true,game,0); vim:SendMouseButtonEvent(0,0,0,false,game,0) end
        names2[1]="VirtualInputManager"
    end
    AC._click = #parts==1 and parts[1] or function() for i=1,#parts do parts[i]() end end
    AC.Method  = table.concat(names2," + ")
end

-- ══════════════════════════════════════════════════════════════════════════════
--  MAIN UI  (glass card, animated toggle pill, speed slider)
-- ══════════════════════════════════════════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "AutoClickerUI"
ScreenGui.ResetOnSpawn   = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder   = 9999
ScreenGui.Parent         = container

-- outer glow
local Glow = Instance.new("ImageLabel")
Glow.BackgroundTransparency = 1
Glow.Image           = "rbxassetid://6014261993"
Glow.ImageColor3     = THEME.A
Glow.ImageTransparency = 0.38
Glow.AnchorPoint     = Vector2.new(0.5,0.5)
Glow.Position        = UDim2.fromScale(0.5,0.5)
Glow.ScaleType       = Enum.ScaleType.Slice
Glow.SliceCenter     = Rect.new(49,49,450,450)
Glow.Size            = UDim2.new(1,60,1,60)
Glow.ZIndex          = 0

-- main card
local Card = Instance.new("Frame")
Card.Name              = "Card"
Card.Size              = UDim2.fromOffset(290, 0)
Card.Position          = UDim2.fromOffset(50, 140)
Card.BackgroundColor3  = THEME.Gl
Card.BackgroundTransparency = 0.25
Card.BorderSizePixel   = 0
Card.Parent            = ScreenGui
corner(Card, 18)
grad(Card, Color3.fromRGB(34,30,52), Color3.fromRGB(18,18,28), 90)
local cs = stroke(Card, THEME.A, 1.4, 0.08)
grad(cs, THEME.A, THEME.B, 25)
Glow.Parent = Card

-- ┌─────────────────── CARD LAYOUT (300 × 168) ───────────────────────────┐
-- │  y=10  accent bar                                                      │
-- │  y=17  "AUTOCLICKER" title                              [CPS big]  y=16│
-- │  y=40  method subtitle                                  [CPS unit] y=36│
-- │  y=55  divider line                                                     │
-- │  y=68  [toggle pill]  OFF / ON · clicks                                 │
-- │  y=96  divider line                                                     │
-- │  y=108 "Speed"                                                          │
-- │  y=126 slider track ──────────────────────────────●                    │
-- └────────────────────────────────────────────────────────────────────────┘

-- top accent bar
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1,-28,0,2); TopBar.Position = UDim2.new(0,14,0,10)
TopBar.BackgroundColor3 = Color3.new(1,1,1); TopBar.BorderSizePixel = 0
TopBar.Parent = Card; corner(TopBar,2); grad(TopBar, THEME.A, THEME.B, 0)

-- title (left-aligned, room for CPS on the right)
local TitleLbl = Instance.new("TextLabel")
TitleLbl.BackgroundTransparency = 1
TitleLbl.Position  = UDim2.fromOffset(18,17)
TitleLbl.Size      = UDim2.fromOffset(150,22)
TitleLbl.Font      = Enum.Font.GothamBlack
TitleLbl.TextSize  = 16
TitleLbl.TextColor3 = THEME.Txt
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TitleLbl.Text      = "AUTOCLICKER"
TitleLbl.Parent    = Card
grad(TitleLbl, THEME.B, THEME.A, 0)

-- CPS big number (top-right)
local CpsLbl = Instance.new("TextLabel")
CpsLbl.BackgroundTransparency = 1
CpsLbl.AnchorPoint = Vector2.new(1,0)
CpsLbl.Position    = UDim2.new(1,-18,0,14)
CpsLbl.Size        = UDim2.fromOffset(72,22)
CpsLbl.Font = Enum.Font.GothamBlack; CpsLbl.TextSize = 18
CpsLbl.TextColor3 = THEME.B; CpsLbl.TextXAlignment = Enum.TextXAlignment.Right
CpsLbl.Text = "50k"; CpsLbl.Parent = Card

-- "CPS" unit label (below big number)
local CpsUnit = Instance.new("TextLabel")
CpsUnit.BackgroundTransparency = 1
CpsUnit.AnchorPoint = Vector2.new(1,0)
CpsUnit.Position    = UDim2.new(1,-18,0,36)
CpsUnit.Size        = UDim2.fromOffset(72,12)
CpsUnit.Font = Enum.Font.Gotham; CpsUnit.TextSize = 9
CpsUnit.TextColor3 = THEME.Dim; CpsUnit.TextXAlignment = Enum.TextXAlignment.Right
CpsUnit.Text = "CPS"; CpsUnit.Parent = Card

-- method label (under title, never overlaps CPS because size stops before right zone)
local MethodLbl = Instance.new("TextLabel")
MethodLbl.BackgroundTransparency = 1
MethodLbl.Position  = UDim2.fromOffset(18,40)
MethodLbl.Size      = UDim2.fromOffset(170,14)    -- fixed width, safe from CPS column
MethodLbl.Font      = Enum.Font.Gotham; MethodLbl.TextSize = 10
MethodLbl.TextColor3 = THEME.Dim
MethodLbl.TextXAlignment = Enum.TextXAlignment.Left
MethodLbl.TextTruncate   = Enum.TextTruncate.AtEnd
MethodLbl.Text      = AC.Method
MethodLbl.Parent    = Card

-- thin divider under header
local Div1 = Instance.new("Frame")
Div1.Size = UDim2.new(1,-28,0,1); Div1.Position = UDim2.new(0,14,0,58)
Div1.BackgroundColor3 = Color3.fromRGB(55,55,75); Div1.BorderSizePixel = 0
Div1.Parent = Card

-- ── Toggle pill (y=68, h=30) ──────────────────────────────────────────────────
local Toggle = Instance.new("TextButton")
Toggle.AutoButtonColor = false; Toggle.Text = ""
Toggle.Size     = UDim2.fromOffset(52,28)
Toggle.Position = UDim2.fromOffset(18,66)
Toggle.BackgroundColor3      = Color3.fromRGB(40,40,56)
Toggle.BackgroundTransparency = 0.1; Toggle.BorderSizePixel = 0
Toggle.Parent = Card; corner(Toggle, 14)
local tStroke = stroke(Toggle, THEME.Off, 1.2, 0.2)

local Pill = Instance.new("Frame")
Pill.Size     = UDim2.fromOffset(22,22)
Pill.Position = UDim2.fromOffset(3,3)
Pill.BackgroundColor3 = Color3.new(1,1,1); Pill.BorderSizePixel = 0
Pill.Parent = Toggle; corner(Pill, 11)
local pillGrad = grad(Pill, THEME.Off, THEME.OfB, 90)

-- state label sits to the right of the pill, same row, ample width
local StateLbl = Instance.new("TextLabel")
StateLbl.BackgroundTransparency = 1
StateLbl.Position = UDim2.fromOffset(78,67)
StateLbl.Size     = UDim2.new(1,-96,0,28)   -- stretches to right edge minus padding
StateLbl.Font = Enum.Font.GothamBold; StateLbl.TextSize = 13
StateLbl.TextColor3 = THEME.Off; StateLbl.TextXAlignment = Enum.TextXAlignment.Left
StateLbl.TextTruncate = Enum.TextTruncate.AtEnd
StateLbl.Text = "OFF"; StateLbl.Parent = Card

-- thin divider under toggle row
local Div2 = Instance.new("Frame")
Div2.Size = UDim2.new(1,-28,0,1); Div2.Position = UDim2.new(0,14,0,103)
Div2.BackgroundColor3 = Color3.fromRGB(55,55,75); Div2.BorderSizePixel = 0
Div2.Parent = Card

-- ── Speed slider (y=108 label, y=126 track) ───────────────────────────────────
local SpdLbl = Instance.new("TextLabel")
SpdLbl.BackgroundTransparency = 1
SpdLbl.Position = UDim2.fromOffset(18,108)
SpdLbl.Size     = UDim2.new(1,-36,0,14)
SpdLbl.Font = Enum.Font.Gotham; SpdLbl.TextSize = 11
SpdLbl.TextColor3 = THEME.Dim; SpdLbl.TextXAlignment = Enum.TextXAlignment.Left
SpdLbl.Text = "Speed  (drag to adjust)"; SpdLbl.Parent = Card

local Track = Instance.new("Frame")
Track.Size     = UDim2.new(1,-36,0,7)
Track.Position = UDim2.fromOffset(18,126)
Track.BackgroundColor3      = Color3.fromRGB(50,50,68)
Track.BackgroundTransparency = 0.25; Track.BorderSizePixel = 0
Track.Parent = Card; corner(Track, 4)

local Fill = Instance.new("Frame")
Fill.Size = UDim2.fromScale(1,1); Fill.BackgroundColor3 = Color3.new(1,1,1)
Fill.BorderSizePixel = 0; Fill.Parent = Track; corner(Fill, 4)
grad(Fill, THEME.A, THEME.B, 0)

local Knob = Instance.new("Frame")
Knob.Size        = UDim2.fromOffset(18,18)
Knob.AnchorPoint = Vector2.new(0.5,0.5)
Knob.Position    = UDim2.fromScale(1,0.5)
Knob.BackgroundColor3 = Color3.new(1,1,1); Knob.BorderSizePixel = 0
Knob.ZIndex = 4; Knob.Parent = Track; corner(Knob, 9)
stroke(Knob, THEME.B, 1.5, 0)
local KnobGlow = Instance.new("ImageLabel")
KnobGlow.BackgroundTransparency = 1; KnobGlow.Image = "rbxassetid://6014261993"
KnobGlow.ImageColor3 = THEME.B; KnobGlow.ImageTransparency = 0.3
KnobGlow.AnchorPoint = Vector2.new(0.5,0.5); KnobGlow.Position = UDim2.fromScale(0.5,0.5)
KnobGlow.Size = UDim2.fromScale(2.5,2.5); KnobGlow.ZIndex = 3; KnobGlow.Parent = Knob

-- card entrance: open from height=0 to final height=162
-- Track bottom edge = 126+7 = 133; knob extends to 133+9 = 142; + 20px padding = 162
Card.Size = UDim2.fromOffset(300,0)
tw(Card, 0.45, {Size = UDim2.fromOffset(300, 162)}, Enum.EasingStyle.Back):Play()

-- ── Visual helpers ────────────────────────────────────────────────────────────
local MAX_CPS = 50000
local function fmtCPS(n)
    return n >= 1000 and string.format("%.0fk", n/1000) or tostring(math.floor(n))
end

local function applyVisual()
    MethodLbl.Text = AC.Method
    if AC.Enabled then
        tw(Pill,      0.28, {Position = UDim2.fromOffset(25,3)}, Enum.EasingStyle.Back):Play()
        tw(Toggle,    0.25, {BackgroundColor3 = Color3.fromRGB(28,52,42)}):Play()
        pillGrad.Color = ColorSequence.new(THEME.On, THEME.OnB)
        tStroke.Color  = THEME.On
        tw(StateLbl,  0.2,  {TextColor3 = THEME.On}):Play(); StateLbl.Text = "ON"
        tw(Glow,      0.3,  {ImageColor3 = THEME.On, ImageTransparency = 0.22}):Play()
    else
        tw(Pill,      0.28, {Position = UDim2.fromOffset(3,3)}, Enum.EasingStyle.Back):Play()
        tw(Toggle,    0.25, {BackgroundColor3 = Color3.fromRGB(40,40,56)}):Play()
        pillGrad.Color = ColorSequence.new(THEME.Off, THEME.OfB)
        tStroke.Color  = THEME.Off
        tw(StateLbl,  0.2,  {TextColor3 = THEME.Off}):Play(); StateLbl.Text = "OFF"
        tw(Glow,      0.3,  {ImageColor3 = THEME.A, ImageTransparency = 0.38}):Play()
    end
end
AC.OnVisual = applyVisual
applyVisual()

-- ── Slider logic ──────────────────────────────────────────────────────────────
local function setFromX(absX)
    local rel = math.clamp((absX - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
    tw(Fill, 0.07, {Size = UDim2.fromScale(rel,1)}):Play()
    tw(Knob, 0.07, {Position = UDim2.fromScale(rel,0.5)}):Play()
    AC.CPS = math.max(1, math.floor(rel * MAX_CPS))
    CpsLbl.Text = fmtCPS(AC.CPS)
end

local sliding = false
Track.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        sliding = true; tw(Knob,0.1,{Size=UDim2.fromOffset(22,22)}):Play(); setFromX(i.Position.X)
    end
end)
UIS.InputChanged:Connect(function(i)
    if sliding and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        setFromX(i.Position.X)
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        if sliding then tw(Knob,0.15,{Size=UDim2.fromOffset(18,18)}):Play() end
        sliding = false
    end
end)

-- ── Toggle button ─────────────────────────────────────────────────────────────
Toggle.MouseButton1Click:Connect(function() AC:Toggle(); applyVisual() end)
Toggle.MouseEnter:Connect(function() tw(Toggle,0.12,{BackgroundTransparency=0}):Play() end)
Toggle.MouseLeave:Connect(function() tw(Toggle,0.12,{BackgroundTransparency=0.1}):Play() end)

-- live CPS update ticker
RunSvc.Heartbeat:Connect(function()
    if AC.Enabled then
        StateLbl.Text = "ON · "..AC.ClickCount
    end
end)

-- ── Drag the card ─────────────────────────────────────────────────────────────
do
    local dragging, dStart, sPos
    Card.InputBegan:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end
        local mx,my = i.Position.X, i.Position.Y
        local function over(o,px,py)
            px,py=px or 0,py or 0
            local p,s=o.AbsolutePosition,o.AbsoluteSize
            return mx>=p.X-px and mx<=p.X+s.X+px and my>=p.Y-py and my<=p.Y+s.Y+py
        end
        if over(Track,8,12) or over(Toggle,4,6) then return end
        dragging=true; dStart=i.Position; sPos=Card.Position
        tw(Card,0.1,{BackgroundTransparency=0.12}):Play()
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local d=i.Position-dStart
            Card.Position=UDim2.fromOffset(sPos.X.Offset+d.X, sPos.Y.Offset+d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            if dragging then tw(Card,0.2,{BackgroundTransparency=0.25}):Play() end
            dragging=false
        end
    end)
end

-- ── Breathing glow while ON ───────────────────────────────────────────────────
task.spawn(function()
    while ScreenGui.Parent do
        if AC.Enabled then
            tw(Glow,1.1,{ImageTransparency=0.12}):Play(); task.wait(1.1)
            tw(Glow,1.1,{ImageTransparency=0.30}):Play(); task.wait(1.1)
        else
            task.wait(0.3)
        end
    end
end)

print(("[AutoClicker v3] Ready | %s | [E] to toggle"):format(AC.Method))
