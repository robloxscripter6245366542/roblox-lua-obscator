-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║   AutoDraw Claude AI  —  Draw.me / Universal Drawing Game           ║
-- ║   No image URL needed. Just type what you want drawn.               ║
-- ║   Claude claude-opus-4-6 via Pollinations AI generates the strokes. ║
-- ║   Paste into Delta · Xeno · Solara · Codex · Wave · Fluxus · etc.  ║
-- ╚══════════════════════════════════════════════════════════════════════╝

local Players    = game:GetService("Players")
local UIS        = game:GetService("UserInputService")
local TS         = game:GetService("TweenService")
local VIM        = game:GetService("VirtualInputManager")

local LP         = Players.LocalPlayer
local PGui       = LP:WaitForChild("PlayerGui")

-- ═══════════════════════════════════════════════════════════════════
--  HTTP POST  (works on every major executor)
-- ═══════════════════════════════════════════════════════════════════
local function httpPost(url, body, headers)
    headers = headers or {}
    headers["Content-Type"] = "application/json"

    local function tryReq(fn)
        local ok, res = pcall(fn, {
            Url = url, Method = "POST",
            Headers = headers, Body = body,
        })
        if ok and res and type(res) == "table" and res.Body then
            return res.Body
        end
    end

    -- Synapse X / Wave
    if typeof(syn) == "table" and syn.request  then local r = tryReq(syn.request);   if r then return r end end
    -- Fluxus
    if typeof(fluxus) == "table" and fluxus.request then local r = tryReq(fluxus.request); if r then return r end end
    -- generic request() present on most executors
    if type(request)  == "function" then local r = tryReq(request);  if r then return r end end
    -- http.request  (some older builds)
    if typeof(http) == "table" and http.request then local r = tryReq(http.request); if r then return r end end

    return nil
end

-- ═══════════════════════════════════════════════════════════════════
--  MINIMAL JSON ENCODER  (for the Pollinations request body)
-- ═══════════════════════════════════════════════════════════════════
local function encodeJSON(v)
    local t = type(v)
    if t == "string"  then
        return '"' .. v:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n'):gsub('\r','\\r') .. '"'
    elseif t == "number"  then return tostring(v)
    elseif t == "boolean" then return tostring(v)
    elseif t == "table"   then
        if #v > 0 then
            local parts = {}
            for _, item in ipairs(v) do parts[#parts+1] = encodeJSON(item) end
            return "[" .. table.concat(parts, ",") .. "]"
        else
            local parts = {}
            for k, val in pairs(v) do parts[#parts+1] = '"'..tostring(k)..'":'..encodeJSON(val) end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    end
    return "null"
end

-- ═══════════════════════════════════════════════════════════════════
--  POLLINATIONS AI  —  Claude claude-opus-4-6 text endpoint
--  POST https://text.pollinations.ai/
--  Returns the AI's raw text reply.
-- ═══════════════════════════════════════════════════════════════════
local POLLINATIONS_URL = "https://text.pollinations.ai/"
local MODEL            = "claude-opus-4-6"       -- Claude claude-opus-4-6 via Pollinations

local SYSTEM_PROMPT = [[You are an expert drawing assistant for the Roblox drawing game "Draw Me".
Respond ONLY with valid JSON — no markdown fences, no explanation, nothing else.
Canvas is 1.0 × 1.0 units (0,0 = top-left corner, 1,1 = bottom-right corner).

Color names allowed (use EXACTLY one of these):
red, orange, yellow, green, blue, purple, pink, brown, black, white, gray, lightblue, darkgreen, darkblue

Output format (STRICT):
{
  "strokes": [
    { "color": "black", "size": 5, "points": [[0.1,0.1],[0.2,0.3]] }
  ]
}

Rules:
- Keep under 40 strokes total.
- Each stroke has 2–20 points.
- Size is 2–10 (pixel radius).
- Draw simply but recognizably — think of a quick sketch.
- Use fill-strokes (back-and-forth lines) for solid areas.
- Always include an outline stroke in black or dark color.]]

local function askClaude(prompt)
    local body = encodeJSON({
        model    = MODEL,
        jsonMode = true,
        seed     = 42,
        messages = {
            { role = "system", content = SYSTEM_PROMPT },
            { role = "user",   content = "Draw a simple recognizable sketch of: " .. prompt },
        },
    })
    return httpPost(POLLINATIONS_URL, body)
end

-- ═══════════════════════════════════════════════════════════════════
--  JSON PARSER  —  extracts the strokes array from Claude's reply
-- ═══════════════════════════════════════════════════════════════════
local function parseStrokes(raw)
    local strokes = {}
    if not raw then return strokes end

    -- strip markdown fences if the AI added them anyway
    raw = raw:gsub("```json",""):gsub("```","")

    -- pull the strokes array content
    local inner = raw:match('"strokes"%s*:%s*%[(.+)%]%s*}?$')
    if not inner then
        -- fallback: try to grab the whole array
        inner = raw:match('%[(.+)%]')
    end
    if not inner then return strokes end

    -- split on stroke objects  { ... }
    for obj in inner:gmatch("{([^{}]+)}") do
        local s = {}
        s.color  = obj:match('"color"%s*:%s*"([^"]+)"')   or "black"
        s.size   = tonumber(obj:match('"size"%s*:%s*(%d+)')) or 4
        s.points = {}

        local pts = obj:match('"points"%s*:%s*%[(.-)%]')
        if pts then
            for x, y in pts:gmatch('[%[%s]*([%d%.]+)%s*,%s*([%d%.]+)%s*%]') do
                s.points[#s.points+1] = { tonumber(x), tonumber(y) }
            end
        end

        if #s.points >= 2 then
            strokes[#strokes+1] = s
        end
    end
    return strokes
end

-- ═══════════════════════════════════════════════════════════════════
--  DRAW.ME CANVAS FINDER
--  Searches PlayerGui for the drawing surface.
--  Works on the original Draw Me game (place 2263973400) and forks.
-- ═══════════════════════════════════════════════════════════════════
local CANVAS_NAMES   = { "canvas","board","drawingboard","drawframe","sketchpad","paintboard" }
local CANVAS_MIN_PX  = 280   -- minimum dimension in pixels

local function nameMatch(n)
    local ln = n:lower()
    for _, k in ipairs(CANVAS_NAMES) do if ln:find(k, 1, true) then return true end end
    return false
end

local function findCanvas()
    for _, gui in ipairs(PGui:GetChildren()) do
        for _, d in ipairs(gui:GetDescendants()) do
            if d:IsA("Frame") then
                local sz = d.AbsoluteSize
                if sz.X >= CANVAS_MIN_PX and sz.Y >= CANVAS_MIN_PX and nameMatch(d.Name) then
                    return d
                end
            end
        end
    end
    -- second pass: any large Frame (fallback)
    for _, gui in ipairs(PGui:GetChildren()) do
        for _, d in ipairs(gui:GetDescendants()) do
            if d:IsA("Frame") then
                local sz = d.AbsoluteSize
                if sz.X >= CANVAS_MIN_PX and sz.Y >= CANVAS_MIN_PX then
                    return d
                end
            end
        end
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════════════
--  COLOR PALETTE — find the closest color button in-game
-- ═══════════════════════════════════════════════════════════════════
local PALETTE = {
    red       = Color3.fromRGB(255,   0,   0),
    orange    = Color3.fromRGB(255, 127,   0),
    yellow    = Color3.fromRGB(255, 255,   0),
    green     = Color3.fromRGB(  0, 200,   0),
    blue      = Color3.fromRGB(  0,   0, 255),
    purple    = Color3.fromRGB(128,   0, 128),
    pink      = Color3.fromRGB(255, 105, 180),
    brown     = Color3.fromRGB(139,  69,  19),
    black     = Color3.fromRGB(  0,   0,   0),
    white     = Color3.fromRGB(255, 255, 255),
    gray      = Color3.fromRGB(128, 128, 128),
    lightblue = Color3.fromRGB(135, 206, 235),
    darkgreen = Color3.fromRGB(  0, 100,   0),
    darkblue  = Color3.fromRGB(  0,   0, 139),
}

local colorCache = {}

local function colorDist(a, b)
    return (a.R-b.R)^2 + (a.G-b.G)^2 + (a.B-b.B)^2
end

local function findColorButton(colorName)
    if colorCache[colorName] and colorCache[colorName].Parent then
        return colorCache[colorName]
    end
    local target = PALETTE[colorName] or PALETTE.black
    local best, bestDist = nil, math.huge

    for _, gui in ipairs(PGui:GetChildren()) do
        for _, d in ipairs(gui:GetDescendants()) do
            if (d:IsA("TextButton") or d:IsA("ImageButton") or d:IsA("Frame")) then
                local sz = d.AbsoluteSize
                if sz.X >= 10 and sz.X <= 60 and sz.Y >= 10 and sz.Y <= 60 then
                    local dist = colorDist(d.BackgroundColor3, target)
                    if dist < bestDist then
                        bestDist = dist
                        best = d
                    end
                end
            end
        end
    end

    -- only accept if it's reasonably close (< 0.15 distance in 0–1 space)
    if bestDist < 0.15 * 3 then
        colorCache[colorName] = best
        return best
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════════════
--  VIRTUAL INPUT HELPERS
-- ═══════════════════════════════════════════════════════════════════
local function mouseDown(x, y)
    VIM:SendMouseButtonEvent(x, y, 0, true,  game, 1)
end
local function mouseUp(x, y)
    VIM:SendMouseButtonEvent(x, y, 0, false, game, 1)
end
local function mouseMove(x, y)
    VIM:SendMouseMoveEvent(x, y, game)
end
local function clickPos(x, y)
    mouseDown(x, y); task.wait(0.02); mouseUp(x, y)
end

-- ═══════════════════════════════════════════════════════════════════
--  DRAW ONE STROKE on the canvas
-- ═══════════════════════════════════════════════════════════════════
local function drawStroke(canvas, stroke, pointDelay)
    local ap  = canvas.AbsolutePosition
    local sz  = canvas.AbsoluteSize

    -- select color
    local btn = findColorButton(stroke.color)
    if btn then
        local bp = btn.AbsolutePosition + btn.AbsoluteSize * 0.5
        clickPos(bp.X, bp.Y)
        task.wait(0.04)
    end

    -- convert relative → absolute screen coords
    local function abs(pt)
        return ap.X + pt[1] * sz.X,
               ap.Y + pt[2] * sz.Y
    end

    local pts = stroke.points
    if #pts < 2 then return end

    local x0, y0 = abs(pts[1])
    mouseMove(x0, y0)
    mouseDown(x0, y0)
    task.wait(pointDelay)

    for i = 2, #pts do
        if _G.__AutoDrawStop then mouseUp(x0, y0); return end
        local xi, yi = abs(pts[i])
        mouseMove(xi, yi)
        task.wait(pointDelay)
        x0, y0 = xi, yi
    end

    mouseUp(x0, y0)
    task.wait(0.02)
end

-- ═══════════════════════════════════════════════════════════════════
--  GUI
-- ═══════════════════════════════════════════════════════════════════
local C = {
    BG     = Color3.fromRGB(11, 10, 16),
    PANEL  = Color3.fromRGB(20, 18, 28),
    CARD   = Color3.fromRGB(28, 26, 38),
    DARK   = Color3.fromRGB( 7,  6, 10),
    ACC    = Color3.fromRGB(120, 70, 220),
    ACC2   = Color3.fromRGB(155, 105, 255),
    GREEN  = Color3.fromRGB( 48, 200, 115),
    RED    = Color3.fromRGB(238,  58,  76),
    YELLOW = Color3.fromRGB(248, 188,  36),
    WHITE  = Color3.fromRGB(238, 235, 255),
    MUTED  = Color3.fromRGB(105, 100, 135),
    BORDER = Color3.fromRGB( 48,  43,  68),
}
local TF = TweenInfo.new(0.15, Enum.EasingStyle.Quad)
local function tw(i, p) TS:Create(i, TF, p):Play() end
local function corner(p, r) Instance.new("UICorner", p).CornerRadius = UDim.new(0, r or 8) end
local function mkStroke(p, col, t)
    local s = Instance.new("UIStroke", p); s.Color = col or C.BORDER; s.Thickness = t or 1
end

-- destroy any old instance
local _old = PGui:FindFirstChild("__AutoDrawClaude__")
if _old then _old:Destroy() end
_G.__AutoDrawStop = false

local SGI = Instance.new("ScreenGui")
SGI.Name          = "__AutoDrawClaude__"
SGI.ResetOnSpawn  = false
SGI.IgnoreGuiInset = true
SGI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SGI.DisplayOrder  = 999
pcall(function() SGI.Parent = gethui and gethui() or PGui end)
if not SGI.Parent then SGI.Parent = PGui end

-- main window
local WIN = Instance.new("Frame", SGI)
WIN.Size              = UDim2.new(0, 370, 0, 0)
WIN.AutomaticSize     = Enum.AutomaticSize.Y
WIN.Position          = UDim2.new(0.5, -185, 0.5, -220)
WIN.BackgroundColor3  = C.BG
WIN.BorderSizePixel   = 0
WIN.Active            = true
corner(WIN, 14)
mkStroke(WIN, C.BORDER, 1.5)

-- ── title bar ──────────────────────────────────────────────────────
local TBAR = Instance.new("Frame", WIN)
TBAR.Size             = UDim2.new(1, 0, 0, 50)
TBAR.BackgroundColor3 = C.PANEL
TBAR.BorderSizePixel  = 0
corner(TBAR, 14)
-- fill bottom half so it looks flat against body
local tfix = Instance.new("Frame", TBAR)
tfix.Size = UDim2.new(1, 0, 0, 14); tfix.Position = UDim2.new(0, 0, 1, -14)
tfix.BackgroundColor3 = C.PANEL; tfix.BorderSizePixel = 0

-- logo circle
local logoF = Instance.new("Frame", TBAR)
logoF.Size             = UDim2.new(0, 30, 0, 30)
logoF.Position         = UDim2.new(0, 12, 0.5, -15)
logoF.BackgroundColor3 = C.ACC
logoF.BorderSizePixel  = 0
corner(logoF, 9)
local logoL = Instance.new("TextLabel", logoF)
logoL.Size = UDim2.new(1, 0, 1, 0); logoL.BackgroundTransparency = 1
logoL.Text = "✏"; logoL.TextColor3 = C.WHITE
logoL.Font = Enum.Font.GothamBold; logoL.TextSize = 16
-- animate logo slowly
task.spawn(function()
    while logoL and logoL.Parent do
        logoL.Rotation = (logoL.Rotation + 1) % 360
        task.wait(0.05)
    end
end)

local function tbarLbl(txt, yoff, col, fs, font)
    local l = Instance.new("TextLabel", TBAR)
    l.Size               = UDim2.new(0, 240, 0, 18)
    l.Position           = UDim2.new(0, 52, 0, yoff)
    l.BackgroundTransparency = 1
    l.Text               = txt
    l.TextColor3         = col or C.WHITE
    l.Font               = font or Enum.Font.GothamBold
    l.TextSize           = fs or 14
    l.TextXAlignment     = Enum.TextXAlignment.Left
    return l
end
tbarLbl("AutoDraw  ·  Claude AI",         8,  C.WHITE,  14, Enum.Font.GothamBold)
tbarLbl("Pollinations AI  ·  " .. MODEL, 28,  C.MUTED,  10, Enum.Font.Gotham)

-- close button
local closeBtn = Instance.new("TextButton", TBAR)
closeBtn.Size             = UDim2.new(0, 28, 0, 28)
closeBtn.Position         = UDim2.new(1, -40, 0.5, -14)
closeBtn.BackgroundColor3 = C.RED
closeBtn.Text             = "✕"
closeBtn.TextColor3       = C.WHITE
closeBtn.Font             = Enum.Font.GothamBold
closeBtn.TextSize         = 12
closeBtn.BorderSizePixel  = 0
corner(closeBtn, 8)
closeBtn.MouseButton1Click:Connect(function() SGI:Destroy() end)

-- drag
do
    local drag, st, wp = false
    TBAR.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true; st = inp.Position; wp = WIN.Position
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if drag and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local d = inp.Position - st
            WIN.Position = UDim2.new(wp.X.Scale, wp.X.Offset + d.X, wp.Y.Scale, wp.Y.Offset + d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
    end)
end

-- ── body ───────────────────────────────────────────────────────────
local BODY = Instance.new("Frame", WIN)
BODY.Size             = UDim2.new(1, 0, 0, 0)
BODY.Position         = UDim2.new(0, 0, 0, 50)
BODY.AutomaticSize    = Enum.AutomaticSize.Y
BODY.BackgroundTransparency = 1
BODY.BorderSizePixel  = 0
local bll = Instance.new("UIListLayout", BODY)
bll.SortOrder = Enum.SortOrder.LayoutOrder; bll.Padding = UDim.new(0, 8)
local bp = Instance.new("UIPadding", BODY)
bp.PaddingLeft   = UDim.new(0, 12); bp.PaddingRight  = UDim.new(0, 12)
bp.PaddingTop    = UDim.new(0, 12); bp.PaddingBottom = UDim.new(0, 14)

local lo = 0
local function nextLO() lo = lo + 1; return lo end

local function sectionLbl(txt)
    local l = Instance.new("TextLabel", BODY)
    l.Size = UDim2.new(1, 0, 0, 14); l.LayoutOrder = nextLO()
    l.BackgroundTransparency = 1; l.Text = txt:upper()
    l.TextColor3 = C.MUTED; l.Font = Enum.Font.GothamBold
    l.TextSize = 9; l.TextXAlignment = Enum.TextXAlignment.Left
    return l
end

local function mkCard(h)
    local f = Instance.new("Frame", BODY)
    f.Size = UDim2.new(1, 0, 0, h); f.LayoutOrder = nextLO()
    f.BackgroundColor3 = C.CARD; f.BorderSizePixel = 0
    corner(f, 9); mkStroke(f, C.BORDER)
    return f
end

-- ── PROMPT INPUT ──
sectionLbl("Describe what to draw")
local promptCard = mkCard(40)
local pp = Instance.new("UIPadding", promptCard)
pp.PaddingLeft = UDim.new(0, 10); pp.PaddingRight = UDim.new(0, 10)
local promptBox = Instance.new("TextBox", promptCard)
promptBox.Size                = UDim2.new(1, 0, 1, 0)
promptBox.BackgroundTransparency = 1
promptBox.PlaceholderText     = "cat, house, tree, sun, rocket…"
promptBox.PlaceholderColor3   = C.MUTED
promptBox.Text                = ""
promptBox.TextColor3          = C.WHITE
promptBox.Font                = Enum.Font.Gotham
promptBox.TextSize            = 13
promptBox.ClearTextOnFocus    = false
promptBox.TextXAlignment      = Enum.TextXAlignment.Left

-- ── SPEED ──
sectionLbl("Draw speed")
local speedRow = Instance.new("Frame", BODY)
speedRow.Size               = UDim2.new(1, 0, 0, 32)
speedRow.BackgroundTransparency = 1
speedRow.BorderSizePixel    = 0
speedRow.LayoutOrder        = nextLO()
local srh = Instance.new("UIListLayout", speedRow)
srh.FillDirection = Enum.FillDirection.Horizontal; srh.Padding = UDim.new(0, 6)

local drawDelay = 0.022
local speedDefs = {{"Fast", 0.010}, {"Normal", 0.022}, {"Slow", 0.055}}
local speedBtns = {}
for i, def in ipairs(speedDefs) do
    local b = Instance.new("TextButton", speedRow)
    b.Size = UDim2.new(0, 100, 1, 0)
    b.BackgroundColor3 = i == 2 and C.ACC or C.DARK
    b.Text = def[1]; b.TextColor3 = C.WHITE
    b.Font = Enum.Font.GothamBold; b.TextSize = 11
    b.BorderSizePixel = 0; corner(b, 7)
    speedBtns[i] = b
    local spd = def[2]
    b.MouseButton1Click:Connect(function()
        drawDelay = spd
        for j, sb in ipairs(speedBtns) do
            tw(sb, {BackgroundColor3 = j == i and C.ACC or C.DARK})
        end
    end)
end

-- ── STATUS BOX ──
sectionLbl("Status")
local statCard = mkCard(56)
local sp2 = Instance.new("UIPadding", statCard)
sp2.PaddingLeft = UDim.new(0, 10); sp2.PaddingRight  = UDim.new(0, 10)
sp2.PaddingTop  = UDim.new(0,  6); sp2.PaddingBottom = UDim.new(0,  6)
local statusLbl = Instance.new("TextLabel", statCard)
statusLbl.Size = UDim2.new(1, 0, 1, 0); statusLbl.BackgroundTransparency = 1
statusLbl.Text = "Type a prompt, then press Generate & Draw."
statusLbl.TextColor3 = C.MUTED; statusLbl.Font = Enum.Font.Gotham
statusLbl.TextSize = 11; statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.TextWrapped = true; statusLbl.TextYAlignment = Enum.TextYAlignment.Top

local function setStatus(txt, col)
    statusLbl.Text = txt; statusLbl.TextColor3 = col or C.WHITE
end

-- ── PROGRESS BAR ──
local progBG = Instance.new("Frame", BODY)
progBG.Size = UDim2.new(1, 0, 0, 6); progBG.LayoutOrder = nextLO()
progBG.BackgroundColor3 = C.DARK; progBG.BorderSizePixel = 0; corner(progBG, 3)
local progFill = Instance.new("Frame", progBG)
progFill.Size = UDim2.new(0, 0, 1, 0); progFill.BackgroundColor3 = C.ACC
progFill.BorderSizePixel = 0; corner(progFill, 3)
local function setProgress(pct)
    tw(progFill, {Size = UDim2.new(math.clamp(pct, 0, 1), 0, 1, 0)})
end

-- ── CANVAS INFO ──
local canvasInfo = Instance.new("TextLabel", BODY)
canvasInfo.Size = UDim2.new(1, 0, 0, 14); canvasInfo.LayoutOrder = nextLO()
canvasInfo.BackgroundTransparency = 1
canvasInfo.Text = "Canvas: searching…"
canvasInfo.TextColor3 = C.YELLOW; canvasInfo.Font = Enum.Font.Gotham
canvasInfo.TextSize = 10; canvasInfo.TextXAlignment = Enum.TextXAlignment.Left

-- ── GENERATE & DRAW BUTTON ──
local drawBtn = Instance.new("TextButton", BODY)
drawBtn.Size = UDim2.new(1, 0, 0, 44); drawBtn.LayoutOrder = nextLO()
drawBtn.BackgroundColor3 = C.ACC; drawBtn.BorderSizePixel = 0
drawBtn.Text = "✨  Generate & Draw"; drawBtn.TextColor3 = C.WHITE
drawBtn.Font = Enum.Font.GothamBold; drawBtn.TextSize = 15
corner(drawBtn, 10); mkStroke(drawBtn, Color3.fromRGB(90, 50, 170), 1)
drawBtn.MouseEnter:Connect(function() tw(drawBtn, {BackgroundColor3 = C.ACC2}) end)
drawBtn.MouseLeave:Connect(function() tw(drawBtn, {BackgroundColor3 = C.ACC}) end)

-- ── STOP BUTTON ──
local stopBtn = Instance.new("TextButton", BODY)
stopBtn.Size = UDim2.new(1, 0, 0, 34); stopBtn.LayoutOrder = nextLO()
stopBtn.BackgroundColor3 = Color3.fromRGB(80, 18, 28); stopBtn.BorderSizePixel = 0
stopBtn.Text = "⏹  Stop Drawing"; stopBtn.TextColor3 = C.WHITE
stopBtn.Font = Enum.Font.GothamBold; stopBtn.TextSize = 12
corner(stopBtn, 8); stopBtn.Visible = false
stopBtn.MouseButton1Click:Connect(function()
    _G.__AutoDrawStop = true
    setStatus("Stopping…", C.YELLOW)
end)

-- ── FOOTER ──
local footerLbl = Instance.new("TextLabel", BODY)
footerLbl.Size = UDim2.new(1, 0, 0, 13); footerLbl.LayoutOrder = nextLO()
footerLbl.BackgroundTransparency = 1
footerLbl.Text = "Claude claude-opus-4-6  ·  Pollinations AI  ·  No image URL needed"
footerLbl.TextColor3 = C.MUTED; footerLbl.Font = Enum.Font.Gotham
footerLbl.TextSize = 9; footerLbl.TextXAlignment = Enum.TextXAlignment.Center

-- ═══════════════════════════════════════════════════════════════════
--  CANVAS WATCHER  (updates the info label every 2 s)
-- ═══════════════════════════════════════════════════════════════════
task.spawn(function()
    while SGI and SGI.Parent do
        task.wait(2)
        local c = findCanvas()
        if c then
            canvasInfo.Text      = "✓ Canvas ready: "..math.floor(c.AbsoluteSize.X).."×"..math.floor(c.AbsoluteSize.Y)
            canvasInfo.TextColor3 = C.GREEN
        else
            canvasInfo.Text      = "⚠ Canvas not found — wait for your drawing turn in Draw Me"
            canvasInfo.TextColor3 = C.YELLOW
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════
--  MAIN DRAW FLOW
-- ═══════════════════════════════════════════════════════════════════
local busy = false

drawBtn.MouseButton1Click:Connect(function()
    if busy then return end

    local prompt = promptBox.Text:match("^%s*(.-)%s*$")
    if prompt == "" then
        setStatus("Enter what you want to draw first!", C.RED); return
    end

    busy = true
    _G.__AutoDrawStop = false
    drawBtn.Text = "⏳  Asking Claude AI…"
    tw(drawBtn, {BackgroundColor3 = C.MUTED})
    stopBtn.Visible = true
    setProgress(0)

    task.spawn(function()
        -- 1. Ask Claude
        setStatus("Sending prompt to Claude claude-opus-4-6 via Pollinations AI…", C.YELLOW)
        setProgress(0.08)

        local response = askClaude(prompt)

        if _G.__AutoDrawStop then goto done end

        if not response or #response < 5 then
            setStatus(
                "No response from Pollinations AI.\n"..
                "Make sure your executor supports HTTP POST (syn.request / request()).",
                C.RED
            )
            goto done
        end

        setProgress(0.18)
        setStatus("Got AI response! Parsing strokes…", C.GREEN)

        -- 2. Parse
        local strokes = parseStrokes(response)

        if #strokes == 0 then
            setStatus(
                "Could not parse drawing plan.\nResponse preview:\n"..response:sub(1, 120),
                C.RED
            )
            goto done
        end

        -- 3. Find canvas
        local canvas = findCanvas()
        if not canvas then
            setStatus(
                "Drawing canvas not found!\n"..
                "Make sure it is YOUR TURN to draw in Draw Me.",
                C.RED
            )
            goto done
        end

        canvasInfo.Text       = "Drawing on: "..canvas.Name.."  ("..math.floor(canvas.AbsoluteSize.X).."×"..math.floor(canvas.AbsoluteSize.Y)..")"
        canvasInfo.TextColor3 = C.ACC2

        -- 4. Draw
        drawBtn.Text = "🎨  Drawing…"
        setStatus("Drawing '"..prompt.."'  —  "..#strokes.." strokes planned", C.GREEN)

        for i, stk in ipairs(strokes) do
            if _G.__AutoDrawStop then break end
            setProgress(0.18 + (i / #strokes) * 0.82)
            setStatus(
                "Stroke "..i.."/"..#strokes.."  color="..stk.color.."  pts="..#stk.points,
                C.WHITE
            )
            drawStroke(canvas, stk, drawDelay)
        end

        if _G.__AutoDrawStop then
            setStatus("Drawing stopped early.", C.YELLOW)
        else
            setProgress(1)
            setStatus("✓ Done! Drew '"..prompt.."' with "..#strokes.." strokes.", C.GREEN)
        end

        ::done::
        busy = false
        _G.__AutoDrawStop = false
        drawBtn.Text = "✨  Generate & Draw"
        tw(drawBtn, {BackgroundColor3 = C.ACC})
        stopBtn.Visible = false
    end)
end)
