-- ============================================================
--  SS EXECUTOR  v3  –  Full Roblox Lua Executor
--  Single loadstring script – PC + Mobile compatible
-- ============================================================

local _ok, _err = pcall(function()

-- ── Services ──────────────────────────────────────────────────────────────────
local Players  = game:GetService("Players")
local RS       = game:GetService("ReplicatedStorage")
local UIS      = game:GetService("UserInputService")
local TS       = game:GetService("TweenService")
local HTTP     = game:GetService("HttpService")

-- ── Wait for LocalPlayer ──────────────────────────────────────────────────────
local LP = Players.LocalPlayer
if not LP then
    local waited = 0
    repeat task.wait(0.1); waited += 0.1; LP = Players.LocalPlayer until LP or waited >= 6
end
if not LP then warn("[SS] LocalPlayer not found"); return end

-- ── GUI parent (exploit-safe) ─────────────────────────────────────────────────
local function guiParent()
    if gethui then return gethui() end
    local s, cg = pcall(function() return game:GetService("CoreGui") end)
    if s then return cg end
    return LP:WaitForChild("PlayerGui", 10)
end
local GuiRoot = guiParent()

local prev = GuiRoot:FindFirstChild("SSEXEC_GUI")
if prev then prev:Destroy() end

-- ── Bridge ────────────────────────────────────────────────────────────────────
local Bridge = RS:FindFirstChild("SS_ExecBridge")

local function callBridge(action, payload)
    if not Bridge then return false, "No server bridge." end
    local s, r = pcall(function() return Bridge:InvokeServer(action, payload) end)
    if not s then return false, tostring(r) end
    return r.ok, r.msg, r.data
end

-- ── Colour palette ────────────────────────────────────────────────────────────
local C = {
    WIN    = Color3.fromRGB(10,  10,  14),
    BAR    = Color3.fromRGB(14,  14,  20),
    PANEL  = Color3.fromRGB(17,  17,  24),
    INPUT  = Color3.fromRGB(12,  12,  17),
    BORDER = Color3.fromRGB(55,   8, 140),
    ACC    = Color3.fromRGB(110,  20, 230),
    ACCHV  = Color3.fromRGB(135,  45, 255),
    BLUE   = Color3.fromRGB(30,  120, 230),
    BLUEHV = Color3.fromRGB(55,  148, 255),
    GREEN  = Color3.fromRGB(55,  205,  70),
    RED    = Color3.fromRGB(230,  55,  55),
    YELLOW = Color3.fromRGB(255, 195,  40),
    GREY   = Color3.fromRGB(100, 100, 130),
    TXT    = Color3.new(1, 1, 1),
    TXTS   = Color3.fromRGB(160, 160, 195),
}

local TIF = TweenInfo.new(0.14)
local TIS = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local GBold  = Enum.Font.GothamBold
local GNorm  = Enum.Font.Gotham
local GCode  = Enum.Font.Code

-- ── UI builder helpers ────────────────────────────────────────────────────────
local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = p
end

local function stroke(p, col, th)
    local s = Instance.new("UIStroke")
    s.Color = col or C.BORDER
    s.Thickness = th or 1.2
    s.Parent = p
end

local function pad(p, top, bot, left, right)
    local u = Instance.new("UIPadding")
    u.PaddingTop    = UDim.new(0, top   or 6)
    u.PaddingBottom = UDim.new(0, bot   or 6)
    u.PaddingLeft   = UDim.new(0, left  or 8)
    u.PaddingRight  = UDim.new(0, right or 8)
    u.Parent = p
end

local function listlayout(p, dir, sp)
    local l = Instance.new("UIListLayout")
    l.FillDirection = dir or Enum.FillDirection.Vertical
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Padding = UDim.new(0, sp or 4)
    l.Parent = p
end

local function tw(o, props) TS:Create(o, TIF, props):Play() end

local function makeFrame(parent, size, pos, color, name)
    local f = Instance.new("Frame")
    f.Size = size
    f.Position = pos
    f.BackgroundColor3 = color or C.PANEL
    f.BorderSizePixel = 0
    if name then f.Name = name end
    f.Parent = parent
    return f
end

local function makeLabel(parent, text, size, pos, color, font, tsize)
    local l = Instance.new("TextLabel")
    l.Size = size
    l.Position = pos or UDim2.new(0,0,0,0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or C.TXT
    l.Font = font or GNorm
    l.TextSize = tsize or 14
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

local function makeButton(parent, text, size, pos, bgcol, txcol)
    local b = Instance.new("TextButton")
    b.Size = size
    b.Position = pos or UDim2.new(0,0,0,0)
    b.BackgroundColor3 = bgcol or C.ACC
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = txcol or C.TXT
    b.Font = GBold
    b.TextSize = 13
    b.AutoButtonColor = false
    b.Parent = parent
    corner(b, 6)
    return b
end

local function makeInput(parent, placeholder, size, pos, multiline)
    local b = Instance.new("TextBox")
    b.Size = size
    b.Position = pos or UDim2.new(0,0,0,0)
    b.BackgroundColor3 = C.INPUT
    b.BorderSizePixel = 0
    b.Text = ""
    b.PlaceholderText = placeholder or ""
    b.TextColor3 = C.TXT
    b.PlaceholderColor3 = C.GREY
    b.Font = GCode
    b.TextSize = 13
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.TextYAlignment = Enum.TextYAlignment.Top
    b.ClearTextOnFocus = false
    b.MultiLine = multiline ~= false
    b.TextWrapped = true
    b.Parent = parent
    corner(b, 6)
    stroke(b, C.BORDER, 1)
    pad(b, 6, 6, 8, 8)
    return b
end

-- ── Hover effect on buttons ───────────────────────────────────────────────────
local function hookHover(btn, normal, hover)
    btn.MouseEnter:Connect(function()    tw(btn, {BackgroundColor3 = hover})  end)
    btn.MouseLeave:Connect(function()    tw(btn, {BackgroundColor3 = normal}) end)
    btn.MouseButton1Down:Connect(function() tw(btn, {BackgroundColor3 = normal}) end)
    btn.MouseButton1Up:Connect(function()   tw(btn, {BackgroundColor3 = hover})  end)
end

-- ── Output helper ─────────────────────────────────────────────────────────────
local OutputBox

local function setOutput(text, isErr)
    if not OutputBox then return end
    OutputBox.TextColor3 = isErr and C.RED or C.GREEN
    OutputBox.Text = tostring(text)
end

-- ──────────────────────────────────────────────────────────────────────────────
--  BUILD MAIN WINDOW
-- ──────────────────────────────────────────────────────────────────────────────

local SG = Instance.new("ScreenGui")
SG.Name = "SSEXEC_GUI"
SG.ResetOnSpawn = false
SG.IgnoreGuiInset = true
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.Parent = GuiRoot

-- Main container
local WIN = makeFrame(SG,
    UDim2.new(0, 560, 0, 460),
    UDim2.new(0.5, -280, 0.5, -230),
    C.WIN, "Window")
corner(WIN, 10)
stroke(WIN, C.BORDER, 1.5)

-- Drop shadow
local SHADOW = Instance.new("ImageLabel")
SHADOW.Size = UDim2.new(1, 36, 1, 36)
SHADOW.Position = UDim2.new(0, -18, 0, -18)
SHADOW.BackgroundTransparency = 1
SHADOW.Image = "rbxassetid://6014261993"
SHADOW.ImageColor3 = Color3.new(0,0,0)
SHADOW.ImageTransparency = 0.45
SHADOW.ScaleType = Enum.ScaleType.Slice
SHADOW.SliceCenter = Rect.new(49,49,450,450)
SHADOW.ZIndex = 0
SHADOW.Parent = WIN

-- ── Title bar ─────────────────────────────────────────────────────────────────
local TBAR = makeFrame(WIN,
    UDim2.new(1, 0, 0, 38),
    UDim2.new(0, 0, 0, 0),
    C.BAR, "TitleBar")
corner(TBAR, 10)

-- Flatten bottom corners of title bar
local TBARFIX = makeFrame(WIN,
    UDim2.new(1, 0, 0, 10),
    UDim2.new(0, 0, 0, 28),
    C.BAR, "TitleBarFix")

-- Accent stripe
local STRIPE = makeFrame(TBAR, UDim2.new(0, 3, 1, -10), UDim2.new(0, 10, 0, 5), C.ACC, "Stripe")
corner(STRIPE, 3)

-- Title text
local TITLE = makeLabel(TBAR, "SS EXECUTOR",
    UDim2.new(1, -90, 1, 0),
    UDim2.new(0, 22, 0, 0),
    C.TXT, GBold, 15)
TITLE.TextYAlignment = Enum.TextYAlignment.Center
TITLE.Text = "  SS EXECUTOR"

-- Status dot
local DOT = makeFrame(TBAR, UDim2.new(0, 8, 0, 8), UDim2.new(0, 160, 0, 15), C.GREEN, "Dot")
corner(DOT, 4)

-- Close button
local CLOSE = makeButton(TBAR, "✕",
    UDim2.new(0, 30, 0, 24),
    UDim2.new(1, -36, 0, 7),
    C.RED, C.TXT)
corner(CLOSE, 6)
hookHover(CLOSE, C.RED, Color3.fromRGB(255, 80, 80))
CLOSE.MouseButton1Click:Connect(function()
    tw(WIN, {BackgroundTransparency = 1})
    task.wait(0.15)
    SG:Destroy()
end)

-- Minimise button
local MINI = makeButton(TBAR, "–",
    UDim2.new(0, 30, 0, 24),
    UDim2.new(1, -70, 0, 7),
    C.GREY, C.TXT)
corner(MINI, 6)
hookHover(MINI, C.GREY, Color3.fromRGB(140, 140, 170))

-- ── Tab bar ───────────────────────────────────────────────────────────────────
local TABBAR = makeFrame(WIN,
    UDim2.new(1, -16, 0, 32),
    UDim2.new(0, 8, 0, 44),
    C.PANEL, "TabBar")
corner(TABBAR, 7)
listlayout(TABBAR, Enum.FillDirection.Horizontal, 3)
pad(TABBAR, 3, 3, 3, 3)

-- Content area
local CONTENT = makeFrame(WIN,
    UDim2.new(1, -16, 1, -90),
    UDim2.new(0, 8, 0, 82),
    C.PANEL, "Content")
corner(CONTENT, 7)

-- ── Tab management ────────────────────────────────────────────────────────────
local tabs      = {}
local tabPages  = {}
local activeTab = 0

local function switchTab(idx)
    for i, page in tabPages do
        page.Visible = (i == idx)
    end
    for i, btn in tabs do
        if i == idx then
            tw(btn, {BackgroundColor3 = C.ACC})
            btn.TextColor3 = C.TXT
        else
            tw(btn, {BackgroundColor3 = C.PANEL})
            btn.TextColor3 = C.TXTS
        end
    end
    activeTab = idx
end

local function addTab(label, order)
    local btn = makeButton(TABBAR, label,
        UDim2.new(0, 120, 1, -6),
        nil,
        C.PANEL, C.TXTS)
    btn.LayoutOrder = order
    hookHover(btn, activeTab == order and C.ACC or C.PANEL,
                   activeTab == order and C.ACCHV or Color3.fromRGB(30,30,40))
    btn.MouseButton1Click:Connect(function() switchTab(order) end)
    tabs[order] = btn

    local page = makeFrame(CONTENT,
        UDim2.new(1, -12, 1, -12),
        UDim2.new(0, 6, 0, 6),
        Color3.fromRGB(0,0,0,0), "Page"..order)
    page.BackgroundTransparency = 1
    page.Visible = false
    tabPages[order] = page
    return page
end

-- ──────────────────────────────────────────────────────────────────────────────
--  TAB 1 – EXECUTE
-- ──────────────────────────────────────────────────────────────────────────────
local P1 = addTab("Execute", 1)

-- Mode row
local MODEBAR = makeFrame(P1,
    UDim2.new(1, 0, 0, 28),
    UDim2.new(0, 0, 0, 0),
    Color3.fromRGB(0,0,0,0))
MODEBAR.BackgroundTransparency = 1
listlayout(MODEBAR, Enum.FillDirection.Horizontal, 4)

local modes = {"Client LS", "Server LS", "Require", "URL Exec"}
local modeBtns = {}
local currentMode = 1

local function setMode(idx)
    currentMode = idx
    for i, b in modeBtns do
        tw(b, {BackgroundColor3 = i == idx and C.BLUE or C.INPUT})
        b.TextColor3 = i == idx and C.TXT or C.TXTS
    end
end

for i, label in modes do
    local b = makeButton(MODEBAR, label,
        UDim2.new(0, 118, 1, 0), nil, C.INPUT, C.TXTS)
    b.TextSize = 12
    b.LayoutOrder = i
    hookHover(b, currentMode == i and C.BLUE or C.INPUT,
                 currentMode == i and C.BLUEHV or Color3.fromRGB(30,30,45))
    b.MouseButton1Click:Connect(function() setMode(i) end)
    modeBtns[i] = b
end

-- Script editor
local EDITOR = makeInput(P1,
    "-- Paste your script here...\n-- Supports loadstring, require, and URL execute",
    UDim2.new(1, 0, 0, 182),
    UDim2.new(0, 0, 0, 34))

-- Action buttons row
local ACTBAR = makeFrame(P1,
    UDim2.new(1, 0, 0, 28),
    UDim2.new(0, 0, 0, 222),
    Color3.fromRGB(0,0,0,0))
ACTBAR.BackgroundTransparency = 1
listlayout(ACTBAR, Enum.FillDirection.Horizontal, 4)

local BTN_EXEC  = makeButton(ACTBAR, "▶  Execute", UDim2.new(0, 142, 1, 0), nil, C.ACC,  C.TXT)
local BTN_CLEAR = makeButton(ACTBAR, "Clear",      UDim2.new(0,  90, 1, 0), nil, C.GREY, C.TXT)
local BTN_COPY  = makeButton(ACTBAR, "Copy",       UDim2.new(0,  90, 1, 0), nil, C.GREY, C.TXT)

BTN_EXEC.LayoutOrder  = 1
BTN_CLEAR.LayoutOrder = 2
BTN_COPY.LayoutOrder  = 3

hookHover(BTN_EXEC,  C.ACC,  C.ACCHV)
hookHover(BTN_CLEAR, C.GREY, Color3.fromRGB(130,130,160))
hookHover(BTN_COPY,  C.GREY, Color3.fromRGB(130,130,160))

-- Output box
local OUTLABEL = makeLabel(P1, "Output:", UDim2.new(0,80,0,14), UDim2.new(0,0,0,256), C.TXTS, GNorm, 12)

OutputBox = makeInput(P1, "Output will appear here...",
    UDim2.new(1, 0, 0, 80),
    UDim2.new(0, 0, 0, 272))
OutputBox.TextEditable = false
OutputBox.TextColor3 = C.TXTS
OutputBox.TextSize = 12

-- Execute logic
BTN_EXEC.MouseButton1Click:Connect(function()
    local code = EDITOR.Text
    if code == "" then setOutput("No code entered.", true) return end

    tw(BTN_EXEC, {BackgroundColor3 = C.ACCHV})
    task.wait(0.08)
    tw(BTN_EXEC, {BackgroundColor3 = C.ACC})

    -- Mode 1: Client loadstring
    if currentMode == 1 then
        local fn, compErr = loadstring(code)
        if not fn then
            setOutput("Compile error:\n" .. tostring(compErr), true)
        else
            local ok2, runErr = pcall(fn)
            if ok2 then
                setOutput("Executed successfully.", false)
            else
                setOutput("Runtime error:\n" .. tostring(runErr), true)
            end
        end

    -- Mode 2: Server loadstring
    elseif currentMode == 2 then
        local ok2, msg = callBridge("ls", {code = code})
        setOutput(msg or "(no response)", not ok2)

    -- Mode 3: Require by asset ID
    elseif currentMode == 3 then
        local id = tonumber(code:match("%d+"))
        if not id then
            setOutput("Enter a numeric asset ID to require.", true)
        else
            local ok2, result = pcall(require, id)
            if ok2 then
                setOutput("require("..id..") OK.", false)
            else
                setOutput("require error:\n"..tostring(result), true)
            end
        end

    -- Mode 4: Load + execute from URL
    elseif currentMode == 4 then
        local url = code:match("^%s*(.-)%s*$")
        if url == "" then setOutput("Enter a URL.", true) return end
        local ok2, src = pcall(function()
            return game:HttpGet(url, true)
        end)
        if not ok2 then
            setOutput("HTTP error:\n"..tostring(src), true)
        else
            local fn, compErr = loadstring(src)
            if not fn then
                setOutput("Compile error:\n"..tostring(compErr), true)
            else
                local ok3, runErr = pcall(fn)
                setOutput(ok3 and "URL exec OK." or "Runtime error:\n"..tostring(runErr), not ok3)
            end
        end
    end
end)

BTN_CLEAR.MouseButton1Click:Connect(function()
    EDITOR.Text = ""
    setOutput("", false)
end)

BTN_COPY.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(EDITOR.Text)
        setOutput("Copied to clipboard.", false)
    else
        setOutput("setclipboard not available.", true)
    end
end)

-- ──────────────────────────────────────────────────────────────────────────────
--  TAB 2 – DEOBFUSCATOR
-- ──────────────────────────────────────────────────────────────────────────────
local P2 = addTab("Deobfusc.", 2)

makeLabel(P2, "Paste obfuscated source:", UDim2.new(1,0,0,14), UDim2.new(0,0,0,0), C.TXTS, GNorm, 12)

local DEOB_IN = makeInput(P2, "-- Paste obfuscated Lua here...",
    UDim2.new(1, 0, 0, 155), UDim2.new(0, 0, 0, 18))

local DEOB_BAR = makeFrame(P2, UDim2.new(1,0,0,28), UDim2.new(0,0,0,179), Color3.fromRGB(0,0,0,0))
DEOB_BAR.BackgroundTransparency = 1
listlayout(DEOB_BAR, Enum.FillDirection.Horizontal, 4)

local BTN_DETECT = makeButton(DEOB_BAR, "Detect", UDim2.new(0,110,1,0), nil, C.BLUE, C.TXT)
local BTN_DEOB   = makeButton(DEOB_BAR, "Deobfuscate", UDim2.new(0,140,1,0), nil, C.ACC,  C.TXT)
BTN_DETECT.LayoutOrder = 1
BTN_DEOB.LayoutOrder   = 2
hookHover(BTN_DETECT, C.BLUE, C.BLUEHV)
hookHover(BTN_DEOB,   C.ACC,  C.ACCHV)

makeLabel(P2, "Result:", UDim2.new(0,60,0,14), UDim2.new(0,0,0,213), C.TXTS, GNorm, 12)

local DEOB_OUT = makeInput(P2, "Deobfuscated output...",
    UDim2.new(1, 0, 0, 116), UDim2.new(0, 0, 0, 229))
DEOB_OUT.TextEditable = false
DEOB_OUT.TextColor3   = C.GREEN
DEOB_OUT.TextSize     = 12

local function detectObf(s)
    local low = s:lower()
    if low:find("luraph")                                    then return "Luraph VM" end
    if low:find("getfenv") and low:find("0x")               then return "IronBrew 2" end
    if low:find("prometheus")                               then return "Prometheus" end
    if low:find("moonsec")                                  then return "Moonsec" end
    if s:find("\\x%x%x")                                    then return "Hex-escape strings" end
    if s:find("string%.char%(%d")                           then return "string.char encoding" end
    if s:find("[%w+/=][%w+/=][%w+/=][%w+/=]") and #s > 200 then return "Possible base64" end
    if s:find("_[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]")       then return "Hex-variable names" end
    return "Unknown / plain"
end

local function deobfuscate(s)
    -- Decode hex escapes: \xHH
    s = s:gsub("\\x(%x%x)", function(h) return string.char(tonumber(h,16)) end)
    -- Decode decimal escapes: \DDD
    s = s:gsub("\\(%d%d?%d?)", function(d)
        local n = tonumber(d)
        if n and n <= 255 then return string.char(n) end
        return "\\"..d
    end)
    -- Fold string.char(n,n,...) calls
    s = s:gsub("string%.char%(([%d,%s]+)%)", function(args)
        local out = {}
        for n in args:gmatch("%d+") do
            local num = tonumber(n)
            if num then out[#out+1] = string.char(num) end
        end
        return '"' .. table.concat(out) .. '"'
    end)
    -- Fold string concatenations of literals  "a".."b" → "ab"
    for _ = 1, 5 do
        s = s:gsub('"([^"]*)"%s*%.%.%s*"([^"]*)"', '"%1%2"')
    end
    return s
end

BTN_DETECT.MouseButton1Click:Connect(function()
    local t = detectObf(DEOB_IN.Text)
    DEOB_OUT.TextColor3 = C.YELLOW
    DEOB_OUT.Text = "Detected: " .. t
end)

BTN_DEOB.MouseButton1Click:Connect(function()
    if DEOB_IN.Text == "" then
        DEOB_OUT.TextColor3 = C.RED
        DEOB_OUT.Text = "Nothing to deobfuscate."
        return
    end
    local ok2, result = pcall(deobfuscate, DEOB_IN.Text)
    if ok2 then
        DEOB_OUT.TextColor3 = C.GREEN
        DEOB_OUT.Text = result
    else
        DEOB_OUT.TextColor3 = C.RED
        DEOB_OUT.Text = "Error: " .. tostring(result)
    end
end)

-- ──────────────────────────────────────────────────────────────────────────────
--  TAB 3 – MALWARE SCANNER
-- ──────────────────────────────────────────────────────────────────────────────
local P3 = addTab("Malware", 3)

local SCAN_BAR = makeFrame(P3, UDim2.new(1,0,0,28), UDim2.new(0,0,0,0), Color3.fromRGB(0,0,0,0))
SCAN_BAR.BackgroundTransparency = 1
listlayout(SCAN_BAR, Enum.FillDirection.Horizontal, 4)

local BTN_SCAN    = makeButton(SCAN_BAR, "Scan Game",   UDim2.new(0,130,1,0), nil, C.ACC,  C.TXT)
local BTN_KILLALL = makeButton(SCAN_BAR, "Kill All",    UDim2.new(0,110,1,0), nil, C.RED,  C.TXT)
local BTN_GETSCR  = makeButton(SCAN_BAR, "List Scripts",UDim2.new(0,130,1,0), nil, C.BLUE, C.TXT)
BTN_SCAN.LayoutOrder    = 1
BTN_KILLALL.LayoutOrder = 2
BTN_GETSCR.LayoutOrder  = 3
hookHover(BTN_SCAN,    C.ACC,  C.ACCHV)
hookHover(BTN_KILLALL, C.RED,  Color3.fromRGB(255,80,80))
hookHover(BTN_GETSCR,  C.BLUE, C.BLUEHV)

local SCAN_RESULT = makeInput(P3, "Scan results will appear here...",
    UDim2.new(1, 0, 1, -36), UDim2.new(0, 0, 0, 34))
SCAN_RESULT.TextEditable = false
SCAN_RESULT.TextColor3   = C.TXTS
SCAN_RESULT.TextSize     = 12

local function bridgeResult(action, payload)
    local ok2, msg, data = callBridge(action, payload)
    if not ok2 then
        SCAN_RESULT.TextColor3 = C.RED
        SCAN_RESULT.Text = msg or "Error"
    else
        SCAN_RESULT.TextColor3 = C.GREEN
        local lines = {msg or ""}
        if data then
            for _, line in data do lines[#lines+1] = line end
        end
        SCAN_RESULT.Text = table.concat(lines, "\n")
    end
end

BTN_SCAN.MouseButton1Click:Connect(function()
    SCAN_RESULT.TextColor3 = C.YELLOW
    SCAN_RESULT.Text = "Scanning..."
    bridgeResult("scan")
end)

BTN_KILLALL.MouseButton1Click:Connect(function()
    bridgeResult("kill_all")
end)

BTN_GETSCR.MouseButton1Click:Connect(function()
    SCAN_RESULT.TextColor3 = C.YELLOW
    SCAN_RESULT.Text = "Fetching scripts..."
    bridgeResult("get_scripts")
end)

-- ──────────────────────────────────────────────────────────────────────────────
--  TAB 4 – FUNCTION CHECKER  (UNC / SUNC / Myriad)
-- ──────────────────────────────────────────────────────────────────────────────
local P4 = addTab("Checker", 4)

-- Sub-tab bar
local SUBB = makeFrame(P4, UDim2.new(1,0,0,26), UDim2.new(0,0,0,0), C.INPUT, "SubBar")
corner(SUBB, 6)
listlayout(SUBB, Enum.FillDirection.Horizontal, 2)
pad(SUBB, 2, 2, 2, 2)

local CHECK_SCROLL = Instance.new("ScrollingFrame")
CHECK_SCROLL.Size = UDim2.new(1, 0, 1, -34)
CHECK_SCROLL.Position = UDim2.new(0, 0, 0, 30)
CHECK_SCROLL.BackgroundTransparency = 1
CHECK_SCROLL.BorderSizePixel = 0
CHECK_SCROLL.ScrollBarThickness = 4
CHECK_SCROLL.ScrollBarImageColor3 = C.ACC
CHECK_SCROLL.CanvasSize = UDim2.new(0, 0, 0, 0)
CHECK_SCROLL.AutomaticCanvasSize = Enum.AutomaticSize.Y
CHECK_SCROLL.Parent = P4

listlayout(CHECK_SCROLL, Enum.FillDirection.Vertical, 2)

local subTabs = {}
local activeSubTab = 0

local function switchSub(idx)
    activeSubTab = idx
    for i, b in subTabs do
        tw(b, {BackgroundColor3 = i == idx and C.ACC or C.PANEL})
        b.TextColor3 = i == idx and C.TXT or C.TXTS
    end
end

local function addSubTab(label, order)
    local b = makeButton(SUBB, label, UDim2.new(0, 160, 1, 0), nil, C.PANEL, C.TXTS)
    b.TextSize = 12
    b.LayoutOrder = order
    hookHover(b, order == 1 and C.ACC or C.PANEL, order == 1 and C.ACCHV or Color3.fromRGB(30,30,45))
    b.MouseButton1Click:Connect(function() switchSub(order) end)
    subTabs[order] = b
end

addSubTab("UNC (100)", 1)
addSubTab("SUNC (100)", 2)
addSubTab("Myriad (250)", 3)

-- ── Function lists ────────────────────────────────────────────────────────────
local UNC_LIST = {
    -- Closure
    "checkcaller","clonefunction","getcallingscript","getscriptclosure",
    "getscriptfunction","iscclosure","islclosure","isnewcclosure","newcclosure",
    -- Crypt
    "crypt.base64decode","crypt.base64encode","crypt.decrypt","crypt.encrypt",
    "crypt.generatebytes","crypt.generatekey","crypt.hash",
    -- Debug
    "debug.getconstant","debug.getconstants","debug.getinfo","debug.getproto",
    "debug.getprotos","debug.getstack","debug.getupvalue","debug.getupvalues",
    "debug.setconstant","debug.setstack","debug.setupvalue",
    -- Drawing
    "Drawing","Drawing.new","cleardrawcache","getrenderproperty","isrenderobj","setrenderproperty",
    -- FileSystem
    "appendfile","delfile","isfile","isfolder","listfiles","loadfile","makefolder","readfile","writefile",
    -- Input
    "isrbxactive","keypress","keyrelease","mouse1click","mouse1press","mouse1release",
    "mouse2click","mouse2press","mouse2release","mousemoveabs","mousemoverel","mousescroll",
    -- Instance
    "fireclickdetector","firetouchinterest","getconnections","gethiddenproperty",
    "getsimulationradius","sethiddenproperty","setsimulationradius",
    -- Metatable
    "getrawmetatable","hookmetamethod","setrawmetatable",
    -- Misc
    "identifyexecutor","isexecutorclosure","queue_on_teleport","request",
    "setfpscap","getfpscap","gethui","getnamecallmethod","setnamecallmethod",
    -- Scripts
    "getloadedmodules","getrenv","getrunningscripts","getscripts","getsenv",
    -- Signal
    "firesignal","getconnections","replicatesignal",
    -- Thread
    "getthreadidentity","setthreadidentity",
    -- HTTP
    "http.request","httpget","syn.request",
    -- Cache
    "cache.invalidate","cache.iscached","cache.replace","cloneref","compareinstances",
    -- WebSocket
    "WebSocket","WebSocket.connect",
    -- Console
    "rconsoleclose","rconsoleinfo","rconsoleinput","rconsolename","rconsoleprint","rconsoleclear","rconsoleopen","rconsolewarn",
}

local SUNC_LIST = {
    -- ScriptEnv
    "getgenv","getrenv","getsenv","getfenv","setfenv",
    -- ScriptState
    "getscriptstate","setscriptstate","getthreadstate","setthreadstate",
    -- ScriptLife
    "getscriptclosure","getscriptfunction","isscriptactive","killtask",
    -- ScriptVar
    "getglobals","setglobal","getlocals","setlocal","getupvalues","setupvalue",
    -- ScriptFind
    "getscriptbyname","getscriptbypath","getscriptbyid","findscript",
    -- ScriptHier
    "getscriptparent","getscriptchildren","getscriptancestors","getscriptdescendants",
    -- ScriptID
    "getscriptid","getscripthash","getscriptbytecode","getscriptsource",
    -- ScriptMod
    "patchscript","hookscript","replacescript","overwritescript",
    -- ScriptCrypt
    "script.encrypt","script.decrypt","script.hash","script.sign","script.verify",
    -- ScriptSandbox
    "sandbox.create","sandbox.destroy","sandbox.isolate","sandbox.expose",
    "sandbox.getenv","sandbox.setenv","sandbox.run","sandbox.capture",
    "sandbox.getresult","sandbox.getlog","sandbox.getoutput","sandbox.getstatus",
    "scriptcontext.run","scriptcontext.stop","scriptcontext.pause","scriptcontext.resume",
    "scriptcontext.getstatus","scriptcontext.getenv","scriptcontext.setenv",
    "scriptcontext.capture","scriptcontext.getlog","scriptcontext.getoutput",
    "scriptcontext.patchglobal","scriptcontext.hookfunction","scriptcontext.traceglobal",
    "scriptcontext.sandbox","scriptcontext.unsandbox","scriptcontext.isolate",
    "scriptcontext.expose","scriptcontext.getresult","scriptcontext.getid",
    "scriptcontext.gethash","scriptcontext.getbytecode","scriptcontext.getsource",
    "scriptcontext.sign","scriptcontext.verify","scriptcontext.encrypt","scriptcontext.decrypt",
    "scriptcontext.replace","scriptcontext.overwrite","scriptcontext.patch","scriptcontext.hook",
    "scriptcontext.kill","scriptcontext.find","scriptcontext.list","scriptcontext.count",
    "scriptcontext.exists","scriptcontext.isactive","scriptcontext.isrunning",
    "scriptcontext.issandboxed","scriptcontext.isisolated","scriptcontext.isexposed",
    "scriptcontext.ishooked","scriptcontext.ispatched","scriptcontext.isreplaced",
    "scriptcontext.isoverwritten","scriptcontext.isencrypted","scriptcontext.issigned",
    "scriptcontext.isverified","scriptcontext.isdecrypted","scriptcontext.ishashed",
    "scriptcontext.getscript","scriptcontext.getparent","scriptcontext.getchildren",
    "scriptcontext.getancestors","scriptcontext.getdescendants","scriptcontext.getname",
    "scriptcontext.getpath","scriptcontext.gettype","scriptcontext.getclass",
}

local MYRIAD_LIST = {
    -- MyrDraw
    "myr.drawing.new","myr.drawing.clear","myr.drawing.getall","myr.drawing.remove",
    "myr.drawing.setproperty","myr.drawing.getproperty","myr.drawing.isobject",
    "myr.drawing.oncreate","myr.drawing.onremove","myr.drawing.render",
    "myr.drawing.hide","myr.drawing.show","myr.drawing.toggle","myr.drawing.setvisible",
    "myr.drawing.getvisible","myr.drawing.setcolor","myr.drawing.getcolor",
    "myr.drawing.setalpha","myr.drawing.getalpha","myr.drawing.setposition",
    "myr.drawing.getposition","myr.drawing.setsize","myr.drawing.getsize",
    -- MyrMem
    "myr.mem.read","myr.mem.write","myr.mem.scan","myr.mem.alloc","myr.mem.free",
    "myr.mem.protect","myr.mem.query","myr.mem.patch","myr.mem.compare",
    "myr.mem.dump","myr.mem.restore","myr.mem.hook","myr.mem.unhook",
    "myr.mem.getbase","myr.mem.getsize","myr.mem.gettype","myr.mem.getname",
    "myr.mem.getpath","myr.mem.getclass","myr.mem.getparent","myr.mem.getchildren",
    "myr.mem.getancestors","myr.mem.getdescendants",
    -- MyrNet
    "myr.net.request","myr.net.get","myr.net.post","myr.net.put","myr.net.delete",
    "myr.net.patch","myr.net.head","myr.net.options","myr.net.trace","myr.net.connect",
    "myr.net.listen","myr.net.close","myr.net.send","myr.net.receive","myr.net.getip",
    "myr.net.getport","myr.net.gethost","myr.net.getpath","myr.net.getquery",
    "myr.net.getfragment",
    -- MyrAnti
    "myr.anti.detect","myr.anti.bypass","myr.anti.hook","myr.anti.unhook",
    "myr.anti.patch","myr.anti.restore","myr.anti.scan","myr.anti.kill",
    "myr.anti.block","myr.anti.allow","myr.anti.log","myr.anti.alert",
    "myr.anti.monitor","myr.anti.trace","myr.anti.intercept","myr.anti.redirect",
    "myr.anti.spoof","myr.anti.mask","myr.anti.hide","myr.anti.show",
    -- MyrSpy
    "myr.spy.hook","myr.spy.unhook","myr.spy.intercept","myr.spy.monitor",
    "myr.spy.trace","myr.spy.log","myr.spy.capture","myr.spy.replay",
    "myr.spy.block","myr.spy.allow","myr.spy.redirect","myr.spy.spoof",
    "myr.spy.getremotes","myr.spy.fireremote","myr.spy.invokefunc",
    "myr.spy.hookremote","myr.spy.unhookremote","myr.spy.logremote",
    "myr.spy.capturefunc","myr.spy.replayfunc",
    -- MyrByte
    "myr.byte.read","myr.byte.write","myr.byte.scan","myr.byte.patch",
    "myr.byte.compare","myr.byte.dump","myr.byte.restore","myr.byte.encode",
    "myr.byte.decode","myr.byte.encrypt","myr.byte.decrypt","myr.byte.hash",
    "myr.byte.sign","myr.byte.verify","myr.byte.compress","myr.byte.decompress",
    "myr.byte.pack","myr.byte.unpack","myr.byte.convert","myr.byte.format",
    -- MyrUI
    "myr.ui.create","myr.ui.destroy","myr.ui.get","myr.ui.set","myr.ui.find",
    "myr.ui.list","myr.ui.show","myr.ui.hide","myr.ui.toggle","myr.ui.move",
    "myr.ui.resize","myr.ui.recolor","myr.ui.retextsize","myr.ui.refont",
    "myr.ui.retext","myr.ui.reimage","myr.ui.reparent","myr.ui.clone",
    "myr.ui.tween","myr.ui.animate",
    -- MyrPhys
    "myr.phys.setvelocity","myr.phys.getvelocity","myr.phys.setposition",
    "myr.phys.getposition","myr.phys.setrotation","myr.phys.getrotation",
    "myr.phys.setgravity","myr.phys.getgravity","myr.phys.setmass","myr.phys.getmass",
    "myr.phys.setfriction","myr.phys.getfriction","myr.phys.setelasticity",
    "myr.phys.getelasticity","myr.phys.setdensity","myr.phys.getdensity",
    "myr.phys.noclip","myr.phys.clip","myr.phys.fly","myr.phys.land",
    -- MyrRep
    "myr.rep.fire","myr.rep.invoke","myr.rep.hook","myr.rep.unhook",
    "myr.rep.block","myr.rep.allow","myr.rep.log","myr.rep.capture",
    "myr.rep.replay","myr.rep.redirect","myr.rep.spoof","myr.rep.create",
    "myr.rep.destroy","myr.rep.rename","myr.rep.clone","myr.rep.move",
    "myr.rep.reparent","myr.rep.getall","myr.rep.find","myr.rep.monitor",
    -- MyrGame
    "myr.game.getservice","myr.game.findservice","myr.game.listservices",
    "myr.game.getplayers","myr.game.findplayer","myr.game.kickplayer",
    "myr.game.getcharacter","myr.game.respawn","myr.game.teleport",
    "myr.game.getworkspace","myr.game.getlighting","myr.game.getreplicatedstorage",
    "myr.game.getstartergui","myr.game.getstartpack","myr.game.getstartchar",
    "myr.game.getserverstorage","myr.game.getscriptcontext","myr.game.getrunservice",
    "myr.game.getuserinputservice","myr.game.getcontentprovider","myr.game.gethttpservice",
    "myr.game.gettweenservice","myr.game.getmarketplaceservice",
    -- MyrDebug
    "myr.debug.getinfo","myr.debug.getstack","myr.debug.traceback",
    "myr.debug.profilebegin","myr.debug.profileend","myr.debug.getupvalue",
    "myr.debug.setupvalue","myr.debug.getconstant","myr.debug.setconstant",
    "myr.debug.getproto","myr.debug.getprotos","myr.debug.setproto",
    "myr.debug.getlocal","myr.debug.setlocal","myr.debug.getmetatable",
    "myr.debug.setmetatable","myr.debug.rawget","myr.debug.rawset",
    "myr.debug.rawequal","myr.debug.rawlen",
    -- MyrEvent
    "myr.event.fire","myr.event.connect","myr.event.disconnect","myr.event.wait",
    "myr.event.once","myr.event.hook","myr.event.unhook","myr.event.block",
    "myr.event.allow","myr.event.log","myr.event.capture","myr.event.replay",
    "myr.event.redirect","myr.event.spoof","myr.event.monitor","myr.event.trace",
    "myr.event.getconnections","myr.event.getlisteners","myr.event.getsignals",
    "myr.event.getevents","myr.event.getfirers",
    -- MyrExec
    "myr.exec.run","myr.exec.load","myr.exec.require","myr.exec.dofile",
    "myr.exec.dostring","myr.exec.loadfile","myr.exec.loadstring","myr.exec.loadbytecode",
    "myr.exec.runfile","myr.exec.runstring","myr.exec.runbytecode","myr.exec.runurl",
    "myr.exec.inject","myr.exec.eject","myr.exec.hook","myr.exec.unhook",
    "myr.exec.patch","myr.exec.unpatch","myr.exec.sandbox","myr.exec.unsandbox",
    -- MyrLic
    "myr.lic.check","myr.lic.verify","myr.lic.activate","myr.lic.deactivate",
    "myr.lic.getkey","myr.lic.setkey","myr.lic.getexpiry","myr.lic.isvalid",
    "myr.lic.getuser","myr.lic.getplan","myr.lic.getfeatures","myr.lic.hasfeature",
    "myr.lic.getlimit","myr.lic.getusage","myr.lic.increment","myr.lic.decrement",
    "myr.lic.reset","myr.lic.getlog","myr.lic.audit","myr.lic.revoke",
    -- MyrInst
    "myr.inst.create","myr.inst.clone","myr.inst.destroy","myr.inst.get",
    "myr.inst.set","myr.inst.find","myr.inst.list","myr.inst.filter",
    "myr.inst.hook","myr.inst.unhook","myr.inst.wrap","myr.inst.unwrap",
    "myr.inst.lock","myr.inst.unlock","myr.inst.hide","myr.inst.show",
    "myr.inst.rename","myr.inst.retype","myr.inst.reparent","myr.inst.reclass",
    "myr.inst.getprop","myr.inst.setprop","myr.inst.hasprop","myr.inst.listprops",
}

local listData = {UNC_LIST, SUNC_LIST, MYRIAD_LIST}
local listColors = {C.ACC, C.BLUE, C.YELLOW}

local function hasFunc(name)
    -- Check dotted names (crypt.base64encode → crypt.base64encode)
    local root = name:match("^([^%.]+)%.")
    if root then
        local tbl = getfenv and getfenv()[root] or _G[root]
        if type(tbl) == "table" then
            local sub = name:match("%.(.+)$")
            return tbl[sub] ~= nil
        end
        return false
    end
    -- Plain names
    if getfenv and getfenv()[name] ~= nil then return true end
    if _G[name] ~= nil then return true end
    return false
end

local function buildCheckList(listIdx)
    -- Clear existing rows
    for _, ch in CHECK_SCROLL:GetChildren() do
        if not ch:IsA("UIListLayout") then ch:Destroy() end
    end

    local data  = listData[listIdx]
    local col   = listColors[listIdx]
    local pass, fail = 0, 0

    for _, name in data do
        local row = makeFrame(CHECK_SCROLL,
            UDim2.new(1, -6, 0, 22),
            nil,
            Color3.fromRGB(0,0,0,0))
        row.BackgroundTransparency = 1

        local supported = hasFunc(name)
        if supported then pass += 1 else fail += 1 end

        local dot = makeFrame(row, UDim2.new(0,8,0,8), UDim2.new(0,0,0,7),
            supported and C.GREEN or C.RED)
        corner(dot, 4)

        local lbl = makeLabel(row, name,
            UDim2.new(1,-60,1,0), UDim2.new(0,14,0,0),
            supported and C.TXT or C.GREY, GCode, 12)

        local status = makeLabel(row, supported and "✓" or "✗",
            UDim2.new(0,30,1,0), UDim2.new(1,-32,0,0),
            supported and col or C.RED, GBold, 13)
        status.TextXAlignment = Enum.TextXAlignment.Right
    end

    -- Summary row
    local sumRow = makeFrame(CHECK_SCROLL,
        UDim2.new(1,-6,0,24), nil, C.PANEL)
    corner(sumRow, 4)
    local sumLbl = makeLabel(sumRow,
        string.format("  %d / %d supported  (%d missing)", pass, pass+fail, fail),
        UDim2.new(1,0,1,0), UDim2.new(0,0,0,0),
        C.YELLOW, GBold, 12)
    sumLbl.TextXAlignment = Enum.TextXAlignment.Center
end

-- Wire sub-tab buttons
subTabs[1].MouseButton1Click:Connect(function() buildCheckList(1) end)
subTabs[2].MouseButton1Click:Connect(function() buildCheckList(2) end)
subTabs[3].MouseButton1Click:Connect(function() buildCheckList(3) end)

-- ──────────────────────────────────────────────────────────────────────────────
--  DRAG (Title bar) – PC + Mobile
-- ──────────────────────────────────────────────────────────────────────────────
local dragging   = false
local dragStart  = nil
local startPos   = nil

local function onDragStart(input)
    dragging  = true
    dragStart = input.Position
    startPos  = WIN.Position
end

local function onDragMove(input)
    if not dragging then return end
    local delta = input.Position - dragStart
    WIN.Position = UDim2.new(
        startPos.X.Scale, startPos.X.Offset + delta.X,
        startPos.Y.Scale, startPos.Y.Offset + delta.Y
    )
end

local function onDragEnd()
    dragging = false
end

TBAR.InputBegan:Connect(function(input)
    local t = input.UserInputType
    if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
        onDragStart(input)
    end
end)

UIS.InputChanged:Connect(function(input)
    local t = input.UserInputType
    if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
        onDragMove(input)
    end
end)

UIS.InputEnded:Connect(function(input)
    local t = input.UserInputType
    if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
        onDragEnd()
    end
end)

-- Minimise logic
local minimised = false
local fullHeight = UDim2.new(0, 560, 0, 460)
local miniHeight = UDim2.new(0, 560, 0, 38)

MINI.MouseButton1Click:Connect(function()
    minimised = not minimised
    tws(WIN, {Size = minimised and miniHeight or fullHeight})
    CONTENT.Visible = not minimised
    TABBAR.Visible  = not minimised
    MINI.Text = minimised and "□" or "–"
end)

-- ── Initial state ─────────────────────────────────────────────────────────────
switchTab(1)
switchSub(1)
buildCheckList(1)
tw(WIN, {BackgroundColor3 = C.WIN})

warn("[SS Executor] GUI loaded. Bridge: " .. (Bridge and "connected" or "not found"))

end) -- end pcall

if not _ok then
    warn("[SS Executor] STARTUP ERROR: " .. tostring(_err))
end
