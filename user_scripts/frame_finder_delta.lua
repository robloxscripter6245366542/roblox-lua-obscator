--[[
╔══════════════════════════════════════════════════════════╗
║         NEXUS FRAME FINDER — Delta Edition               ║
║  Drag • Scan • AI Describe • Copy Working Scripts        ║
║  Powered by Pollinations AI (Claude Opus 4)              ║
╚══════════════════════════════════════════════════════════╝
--]]

-- ── Services ──────────────────────────────────────────────────────────────────
local Players   = game:GetService("Players")
local UIS       = game:GetService("UserInputService")
local TS        = game:GetService("TweenService")
local SG        = game:GetService("StarterGui")
local LP        = Players.LocalPlayer
local PGUI      = LP:WaitForChild("PlayerGui")

-- ── Executor APIs (Delta / Synapse / KRNL / similar) ─────────────────────────
local httpReq  = (syn and syn.request) or (http and http.request) or request
local clipSet  = setclipboard or (syn and syn.set_clipboard) or (function() end)
local getScripts = getscripts or nil
local doDecomp   = decompile  or nil

-- ── Color Palette (matches Nexus dark-navy theme) ─────────────────────────────
local C = {
    BG     = Color3.fromRGB(13,  17,  30 ),
    SIDE   = Color3.fromRGB(8,   11,  20 ),
    PANEL  = Color3.fromRGB(22,  28,  46 ),
    EDIT   = Color3.fromRGB(12,  16,  28 ),
    DEEP   = Color3.fromRGB(8,   12,  22 ),
    HDRROW = Color3.fromRGB(16,  22,  42 ),
    ACC    = Color3.fromRGB(59,  130, 246),
    INDIGO = Color3.fromRGB(99,  102, 241),
    GRN    = Color3.fromRGB(34,  197, 94 ),
    RED    = Color3.fromRGB(220, 55,  55 ),
    AMBER  = Color3.fromRGB(245, 158, 11 ),
    TXT    = Color3.fromRGB(241, 245, 249),
    SUB    = Color3.fromRGB(148, 163, 184),
    MUTED  = Color3.fromRGB(71,  85,  105),
    BORDER = Color3.fromRGB(30,  42,  75 ),
    CODE   = Color3.fromRGB(160, 200, 240),
}

-- ── Fonts ─────────────────────────────────────────────────────────────────────
local FB = Enum.Font.GothamBold
local FN = Enum.Font.Gotham
local FM = Enum.Font.RobotoMono

-- ── Tween helpers ─────────────────────────────────────────────────────────────
local TF = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function tw(obj, props) TS:Create(obj, TF, props):Play() end
local function flash(btn, col)
    local orig = btn.BackgroundColor3
    tw(btn, {BackgroundColor3 = col})
    task.delay(0.22, function() tw(btn, {BackgroundColor3 = orig}) end)
end

-- ── UI factory helpers ────────────────────────────────────────────────────────
local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = p
    return c
end

local function stroke(p, col, th)
    local s = Instance.new("UIStroke")
    s.Color = col or C.BORDER
    s.Thickness = th or 1
    s.Parent = p
    return s
end

local function pad(p, v, h)
    local u = Instance.new("UIPadding")
    u.PaddingTop    = UDim.new(0, v)
    u.PaddingBottom = UDim.new(0, v)
    u.PaddingLeft   = UDim.new(0, h)
    u.PaddingRight  = UDim.new(0, h)
    u.Parent = p
    return u
end

local function listV(p, sp)
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, sp or 4)
    l.HorizontalAlignment = Enum.HorizontalAlignment.Left
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = p
    return l
end

local function F(par, sz, pos, col)
    local f = Instance.new("Frame")
    f.Size = sz
    if pos then f.Position = pos end
    f.BackgroundColor3 = col or C.BG
    f.BorderSizePixel = 0
    f.Parent = par
    return f
end

local function L(par, txt, sz, pos, col, fnt, ts, xa)
    local l = Instance.new("TextLabel")
    l.Size = sz
    if pos then l.Position = pos end
    l.BackgroundTransparency = 1
    l.Text = txt
    l.TextColor3 = col or C.TXT
    l.Font = fnt or FN
    l.TextSize = ts or 12
    l.TextWrapped = true
    l.TextXAlignment = xa or Enum.TextXAlignment.Left
    l.Parent = par
    return l
end

local function B(par, txt, sz, pos, bg, tc, ts, fnt)
    local b = Instance.new("TextButton")
    b.Size = sz
    if pos then b.Position = pos end
    b.BackgroundColor3 = bg or C.ACC
    b.Text = txt
    b.TextColor3 = tc or C.TXT
    b.Font = fnt or FB
    b.TextSize = ts or 12
    b.BorderSizePixel = 0
    b.Parent = par
    return b
end

local function dot(par, sz, pos, col)
    local d = F(par, sz, pos, col or C.MUTED)
    corner(d, 99)
    return d
end

-- ── Notify ────────────────────────────────────────────────────────────────────
local function notify(title, body, dur)
    pcall(function()
        SG:SetCore("SendNotification", {
            Title    = title,
            Text     = body,
            Duration = dur or 3,
        })
    end)
end

-- ── Pollinations AI ───────────────────────────────────────────────────────────
-- GET https://text.pollinations.ai/{prompt}?model=claude-opus-4-6&seed=42
-- Claude Opus 4.6 attempted first, falls back to openai
local function aiDescribe(fnName, fnCode)
    if not httpReq then return "HTTP not available in this executor." end

    local prompt = string.format(
        "Roblox Lua expert. In ONE short sentence (max 15 words), describe what "..
        "this frame-drawing function does. Function name: %s. Code: %s",
        fnName, fnCode:sub(1, 450)
    )

    -- URL-encode the prompt
    local encoded = prompt:gsub("[^%w%-%.%_%~%s]", function(c)
        return string.format("%%%02X", c:byte())
    end):gsub("%s", "%%20")

    -- Try claude-opus-4-6 first, fall back to openai
    local models = {"claude-opus-4-6", "openai"}
    for _, model in ipairs(models) do
        local ok, resp = pcall(httpReq, {
            Url    = "https://text.pollinations.ai/" .. encoded
                     .. "?model=" .. model .. "&seed=42",
            Method = "GET",
        })
        if ok and resp and (resp.StatusCode == 200 or resp.status == 200) then
            local body = resp.Body or resp.body or ""
            body = body:gsub("^%s+",""):gsub("%s+$",""):gsub('\\n', ' ')
            if #body > 4 and #body < 250 then
                return body
            end
        end
    end
    return "Draws a UI frame using Roblox Instance API."
end

-- ── Frame-drawing pattern set ─────────────────────────────────────────────────
local FRAME_PATS = {
    -- Roblox GUI instances
    'Instance%.new%s*%(%s*["\']Frame["\']',
    'Instance%.new%s*%(%s*["\']ScreenGui["\']',
    'Instance%.new%s*%(%s*["\']ScrollingFrame["\']',
    'Instance%.new%s*%(%s*["\']SurfaceGui["\']',
    'Instance%.new%s*%(%s*["\']BillboardGui["\']',
    'Instance%.new%s*%(%s*["\']ImageLabel["\']',
    'Instance%.new%s*%(%s*["\']ImageButton["\']',
    -- Drawing API (ESP / overlays)
    'Drawing%.new%s*%(%s*["\']Square["\']',
    'Drawing%.new%s*%(%s*["\']Circle["\']',
    'Drawing%.new%s*%(%s*["\']Triangle["\']',
    'Drawing%.new%s*%(%s*["\']Line["\']',
    'Drawing%.new%s*%(%s*["\']Image["\']',
    'Drawing%.new%s*%(%s*["\']Text["\']',
    -- Common ESP / UI naming patterns
    'DrawingAPI', 'drawFrame', 'drawRect', 'renderFrame',
    'CreateBox', 'BoxESP', 'drawESP', 'CreateFrame',
    'UICorner', 'UIStroke', 'UIListLayout', 'UIGridLayout',
}

local function matchesFramePat(code)
    for _, p in ipairs(FRAME_PATS) do
        if code:find(p) then return true end
    end
    return false
end

-- Extract named functions that contain frame-drawing patterns
local function extractFrameFunctions(src, scriptName)
    if not src or src == "" then return {} end
    local results = {}
    local seen = {}

    local function tryAdd(sig, name, body)
        if seen[name] then return end
        local full = sig .. "\n" .. body .. "\nend"
        if matchesFramePat(body) then
            seen[name] = true
            table.insert(results, {
                name   = name,
                code   = full,
                source = scriptName,
            })
        end
    end

    -- local function Name(...)
    for sig, name, body in src:gmatch("(local%s+function%s+(%w+)%b()\s*)\n(.-)\nend") do
        tryAdd(sig, name, body)
    end
    -- function Name(...)   /   function A.B(...)
    for sig, name, body in src:gmatch("(function%s+([%w_%.]+)%b()\s*)\n(.-)\nend") do
        tryAdd(sig, name, body)
    end

    return results
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- GUI BUILD
-- ═══════════════════════════════════════════════════════════════════════════════

-- Remove stale instance on re-run
if PGUI:FindFirstChild("NexusFrameFinder") then
    PGUI.NexusFrameFinder:Destroy()
end

local GUI = Instance.new("ScreenGui")
GUI.Name            = "NexusFrameFinder"
GUI.ResetOnSpawn    = false
GUI.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
GUI.DisplayOrder    = 999
GUI.Parent          = PGUI

-- Drop shadow
local SHADOW = F(GUI, UDim2.new(0,500,0,600), UDim2.new(0.5,-250,0.5,-300), Color3.new(0,0,0))
SHADOW.BackgroundTransparency = 0.62
corner(SHADOW, 16)

-- Main window
local WIN = F(GUI, UDim2.new(0,480,0,580), UDim2.new(0.5,-240,0.5,-290), C.BG)
corner(WIN, 12)
stroke(WIN, C.BORDER, 1.5)

-- ── Title bar ─────────────────────────────────────────────────────────────────
local TBAR = F(WIN, UDim2.new(1,0,0,46), UDim2.new(0,0,0,0), C.SIDE)
corner(TBAR, 12)
F(TBAR, UDim2.new(1,0,0,12), UDim2.new(0,0,1,-12), C.SIDE) -- square off bottom

-- Vertical accent stripe
local STRIPE = F(TBAR, UDim2.new(0,3,0,24), UDim2.new(0,14,0.5,-12), C.ACC)
corner(STRIPE, 2)

-- Title labels
L(TBAR, "Frame Finder",
    UDim2.new(0,220,0,20), UDim2.new(0,25,0,7),
    C.TXT, FB, 14)

local TSUB = L(TBAR, "Delta  ·  Pollinations AI  ·  Claude Opus 4.6",
    UDim2.new(0,320,0,14), UDim2.new(0,25,0,26),
    C.MUTED, FN, 9)

-- Close button
local CLOSEBTN = B(TBAR, "✕",
    UDim2.new(0,26,0,26), UDim2.new(1,-36,0.5,-13),
    C.RED, C.TXT, 11, FB)
corner(CLOSEBTN, 6)
CLOSEBTN.MouseEnter:Connect(function()  tw(CLOSEBTN, {BackgroundColor3 = Color3.fromRGB(255,70,70)}) end)
CLOSEBTN.MouseLeave:Connect(function()  tw(CLOSEBTN, {BackgroundColor3 = C.RED}) end)
CLOSEBTN.MouseButton1Click:Connect(function() GUI:Destroy() end)

-- ── Drag ──────────────────────────────────────────────────────────────────────
do
    local dragging, dragStart, winStart
    local function updateShadow()
        SHADOW.Position = UDim2.new(
            WIN.Position.X.Scale, WIN.Position.X.Offset - 10,
            WIN.Position.Y.Scale, WIN.Position.Y.Offset - 10)
    end
    TBAR.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = inp.Position
            winStart  = WIN.Position
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
            updateShadow()
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    updateShadow()
end

-- ── Status bar ────────────────────────────────────────────────────────────────
local SBAR = F(WIN, UDim2.new(1,-24,0,30), UDim2.new(0,12,0,54), C.PANEL)
corner(SBAR, 6)
local SDOT  = dot(SBAR,  UDim2.new(0,8,0,8),   UDim2.new(0,10,0.5,-4), C.MUTED)
local STXT  = L(SBAR, "Ready — press Scan to find frame-drawing functions",
    UDim2.new(1,-32,1,0), UDim2.new(0,26,0,0), C.SUB, FN, 10)
STXT.TextTruncate = Enum.TextTruncate.AtEnd

local function setStatus(msg, col)
    STXT.Text = msg
    tw(SDOT, {BackgroundColor3 = col or C.MUTED})
end

-- ── Scan button ───────────────────────────────────────────────────────────────
local SCANBTN = B(WIN, "⬡  Scan Game for Frame Functions",
    UDim2.new(1,-24,0,36), UDim2.new(0,12,0,92),
    C.ACC, C.TXT, 13, FB)
corner(SCANBTN, 8)
SCANBTN.MouseEnter:Connect(function()  tw(SCANBTN, {BackgroundColor3 = Color3.fromRGB(80,152,255)}) end)
SCANBTN.MouseLeave:Connect(function()  tw(SCANBTN, {BackgroundColor3 = C.ACC}) end)

-- ── Results header row ────────────────────────────────────────────────────────
local RLBL = L(WIN, "RESULTS",
    UDim2.new(0,80,0,14), UDim2.new(0,12,0,136),
    C.MUTED, FB, 9)
local RCNT = L(WIN, "",
    UDim2.new(1,-24,0,14), UDim2.new(0,12,0,136),
    C.SUB, FN, 9)
RCNT.TextXAlignment = Enum.TextXAlignment.Right

-- ── Scrollable results pane ───────────────────────────────────────────────────
local RSCR = Instance.new("ScrollingFrame")
RSCR.Size                = UDim2.new(1,-24,1,-158)
RSCR.Position            = UDim2.new(0,12,0,154)
RSCR.BackgroundColor3    = C.PANEL
RSCR.BorderSizePixel     = 0
RSCR.ScrollBarThickness  = 3
RSCR.ScrollBarImageColor3= C.ACC
RSCR.AutomaticCanvasSize = Enum.AutomaticSize.Y
RSCR.CanvasSize          = UDim2.new(0,0,0,0)
RSCR.Parent              = WIN
corner(RSCR, 8)

listV(RSCR, 6)
pad(RSCR, 8, 8)

-- Empty state placeholder
local EMPTY = L(RSCR,
    "No scripts scanned yet.\n\nPress  ⬡ Scan  to search all game\nscripts for frame-drawing functions.",
    UDim2.new(1,0,0,130), nil, C.MUTED, FN, 12)
EMPTY.TextXAlignment = Enum.TextXAlignment.Center
EMPTY.TextYAlignment = Enum.TextYAlignment.Center

-- ═══════════════════════════════════════════════════════════════════════════════
-- RESULT CARD
-- ═══════════════════════════════════════════════════════════════════════════════
local function makeCard(info, idx)
    -- Card shell
    local CARD = Instance.new("Frame")
    CARD.Name            = "Card_" .. idx
    CARD.Size            = UDim2.new(1, 0, 0, 0)
    CARD.AutomaticSize   = Enum.AutomaticSize.Y
    CARD.BackgroundColor3= C.EDIT
    CARD.BorderSizePixel = 0
    CARD.LayoutOrder     = idx
    CARD.Parent          = RSCR
    corner(CARD, 7)
    stroke(CARD, C.BORDER, 1)

    -- Stack children top-to-bottom with UIListLayout
    listV(CARD, 0)

    -- ── 1. Header row ─────────────────────────────────────────────────────────
    local HDR = F(CARD, UDim2.new(1,0,0,34), nil, C.HDRROW)
    HDR.LayoutOrder = 1
    corner(HDR, 7)
    F(HDR, UDim2.new(1,0,0,7), UDim2.new(0,0,1,-7), C.HDRROW) -- square bottom

    dot(HDR, UDim2.new(0,7,0,7), UDim2.new(0,10,0.5,-3), C.ACC)

    local FNLBL = L(HDR, info.name,
        UDim2.new(1,-110,1,0), UDim2.new(0,24,0,0),
        C.ACC, FM, 11)
    FNLBL.TextTruncate = Enum.TextTruncate.AtEnd

    -- Source badge pill
    local PILL = F(HDR, UDim2.new(0,92,0,18), UDim2.new(1,-100,0.5,-9), Color3.fromRGB(22,32,58))
    corner(PILL, 4)
    local PILLTXT = L(PILL, info.source or "?",
        UDim2.new(1,-8,1,0), UDim2.new(0,4,0,0),
        C.MUTED, FM, 9)
    PILLTXT.TextXAlignment = Enum.TextXAlignment.Center
    PILLTXT.TextTruncate = Enum.TextTruncate.AtEnd

    -- ── 2. AI description row ─────────────────────────────────────────────────
    local AIROW = Instance.new("Frame")
    AIROW.Size           = UDim2.new(1,0,0,0)
    AIROW.AutomaticSize  = Enum.AutomaticSize.Y
    AIROW.BackgroundColor3 = C.EDIT
    AIROW.BorderSizePixel  = 0
    AIROW.LayoutOrder    = 2
    AIROW.Parent         = CARD
    pad(AIROW, 6, 10)

    local AIDESC = Instance.new("TextLabel")
    AIDESC.Size          = UDim2.new(1,0,0,0)
    AIDESC.AutomaticSize = Enum.AutomaticSize.Y
    AIDESC.BackgroundTransparency = 1
    AIDESC.Text          = "✦  " .. (info.aiDesc or "Fetching AI description...")
    AIDESC.TextColor3    = C.SUB
    AIDESC.Font          = FN
    AIDESC.TextSize      = 10
    AIDESC.TextWrapped   = true
    AIDESC.TextXAlignment = Enum.TextXAlignment.Left
    AIDESC.Parent        = AIROW

    -- ── 3. Thin divider ───────────────────────────────────────────────────────
    local DIV = F(CARD, UDim2.new(1,0,0,1), nil, C.BORDER)
    DIV.LayoutOrder = 3

    -- ── 4. Code preview ───────────────────────────────────────────────────────
    local CODEROW = Instance.new("Frame")
    CODEROW.Size           = UDim2.new(1,0,0,0)
    CODEROW.AutomaticSize  = Enum.AutomaticSize.Y
    CODEROW.BackgroundColor3 = C.DEEP
    CODEROW.BorderSizePixel  = 0
    CODEROW.LayoutOrder    = 4
    CODEROW.Parent         = CARD
    pad(CODEROW, 8, 10)

    local lines = info.code:split("\n")
    local previewLines = {}
    for i = 1, math.min(10, #lines) do
        table.insert(previewLines, lines[i])
    end
    if #lines > 10 then
        table.insert(previewLines, "  ... (" .. (#lines - 10) .. " more lines)")
    end

    local CODETXT = Instance.new("TextLabel")
    CODETXT.Size          = UDim2.new(1,0,0,0)
    CODETXT.AutomaticSize = Enum.AutomaticSize.Y
    CODETXT.BackgroundTransparency = 1
    CODETXT.Text          = table.concat(previewLines, "\n")
    CODETXT.TextColor3    = C.CODE
    CODETXT.Font          = FM
    CODETXT.TextSize      = 9
    CODETXT.TextWrapped   = true
    CODETXT.TextXAlignment = Enum.TextXAlignment.Left
    CODETXT.Parent        = CODEROW

    -- ── 5. Copy button ────────────────────────────────────────────────────────
    local COPYBTN = B(CARD, "⧉  Copy Working Script",
        UDim2.new(1,0,0,32), nil,
        C.INDIGO, C.TXT, 11, FB)
    COPYBTN.LayoutOrder = 5
    corner(COPYBTN, 7)

    COPYBTN.MouseEnter:Connect(function()
        tw(COPYBTN, {BackgroundColor3 = Color3.fromRGB(118,122,255)})
    end)
    COPYBTN.MouseLeave:Connect(function()
        tw(COPYBTN, {BackgroundColor3 = C.INDIGO})
    end)
    COPYBTN.MouseButton1Click:Connect(function()
        clipSet(info.code)
        flash(COPYBTN, C.GRN)
        COPYBTN.Text = "✓  Copied to Clipboard!"
        task.delay(1.8, function()
            COPYBTN.Text = "⧉  Copy Working Script"
        end)
        notify("Frame Finder", "Copied: " .. info.name, 2)
    end)

    return CARD, AIDESC
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SCAN LOGIC
-- ═══════════════════════════════════════════════════════════════════════════════
local scanning = false

SCANBTN.MouseButton1Click:Connect(function()
    if scanning then return end
    scanning = true

    -- Clear previous results
    for _, ch in ipairs(RSCR:GetChildren()) do
        if ch:IsA("Frame") then ch:Destroy() end
    end
    EMPTY.Visible = false
    RCNT.Text     = ""

    setStatus("Collecting scripts...", C.AMBER)
    tw(SCANBTN, {BackgroundColor3 = Color3.fromRGB(38, 58, 102)})
    SCANBTN.Text = "Scanning..."

    task.spawn(function()
        -- ── Gather scripts ────────────────────────────────────────────────────
        local scripts = {}
        if getScripts then
            pcall(function() scripts = getScripts() end)
        end
        if #scripts == 0 then
            -- Fallback: walk instance tree
            for _, v in ipairs(game:GetDescendants()) do
                if v:IsA("LocalScript") or v:IsA("ModuleScript") or v:IsA("Script") then
                    table.insert(scripts, v)
                end
            end
        end

        setStatus(string.format("Found %d scripts — extracting functions...", #scripts), C.AMBER)

        -- ── Extract frame-drawing functions ───────────────────────────────────
        local allFound = {}
        for _, scr in ipairs(scripts) do
            local src = ""
            if doDecomp then pcall(function() src = doDecomp(scr) end) end
            if src == "" then pcall(function() src = scr.Source end) end
            if src and src ~= "" then
                local fns = extractFrameFunctions(src, scr.Name)
                for _, fn in ipairs(fns) do
                    table.insert(allFound, fn)
                end
            end
        end

        -- ── Handle no results ─────────────────────────────────────────────────
        if #allFound == 0 then
            EMPTY.Visible = true
            EMPTY.Text    = "No frame-drawing functions found in accessible scripts.\n\n"
                          .. "Try a game with active client UI scripts."
            setStatus("Scan complete — 0 results", C.RED)
            RCNT.Text = "0 found"
            tw(SCANBTN, {BackgroundColor3 = C.ACC})
            SCANBTN.Text = "⬡  Scan Again"
            scanning = false
            return
        end

        -- Cap display at 20 cards
        local display = {}
        for i = 1, math.min(20, #allFound) do
            table.insert(display, allFound[i])
        end

        RCNT.Text = (#allFound > 20)
            and (#allFound .. " found  (showing 20)")
            or  (#allFound .. " found")

        -- ── Build cards with AI descriptions ─────────────────────────────────
        for i, fn in ipairs(display) do
            setStatus(
                string.format("AI analyzing %d / %d — %s", i, #display, fn.name),
                C.AMBER
            )

            local desc = aiDescribe(fn.name, fn.code)
            fn.aiDesc  = desc

            local _, descLabel = makeCard(fn, i)
            if descLabel then
                descLabel.Text = "✦  " .. desc
            end

            task.wait(0.05)
        end

        setStatus(
            string.format("Done — %d frame function%s found",
                #allFound, #allFound == 1 and "" or "s"),
            C.GRN
        )
        tw(SCANBTN, {BackgroundColor3 = C.ACC})
        SCANBTN.Text = "⬡  Scan Again"
        scanning = false
    end)
end)

-- ── Boot ──────────────────────────────────────────────────────────────────────
tw(SDOT, {BackgroundColor3 = C.GRN})
setStatus("Ready — press Scan to begin", C.GRN)
notify("Frame Finder", "Loaded! Click Scan to find all frame-drawing functions.", 3)
