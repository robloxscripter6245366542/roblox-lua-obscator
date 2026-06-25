--[[
╔══════════════════════════════════════════════════════════════╗
║              NEXUS AI — Delta Edition                        ║
║  Describe a script → AI generates it → Copy / Execute       ║
║  Powered by Pollinations AI  ·  Claude Opus 4.6             ║
╚══════════════════════════════════════════════════════════════╝

  AI TAB  — Type any prompt (e.g. "blade ball autoparry with emotes,
             draggable ui, on/off switches, scan and decompile the
             game for all parry code"). AI writes the full script.
             Copy it or Execute it directly via loadstring().

  SCANNER TAB — Scans all game scripts for frame-drawing functions.
                Each result has Copy + Execute buttons.
--]]

-- ── Services ──────────────────────────────────────────────────────────────────
local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")
local TS      = game:GetService("TweenService")
local SG      = game:GetService("StarterGui")
local HS      = game:GetService("HttpService")
local LP      = Players.LocalPlayer
local PGUI    = LP:WaitForChild("PlayerGui")

-- ── Executor APIs ─────────────────────────────────────────────────────────────
local httpReq    = (syn and syn.request) or (http and http.request) or request
local clipSet    = setclipboard or (syn and syn.set_clipboard) or (function() end)
local getScripts = getscripts  or nil
local doDecomp   = decompile   or nil

-- ── Colors ────────────────────────────────────────────────────────────────────
local C = {
    BG     = Color3.fromRGB(13,  17,  30 ),
    SIDE   = Color3.fromRGB(8,   11,  20 ),
    PANEL  = Color3.fromRGB(22,  28,  46 ),
    EDIT   = Color3.fromRGB(12,  16,  28 ),
    DEEP   = Color3.fromRGB(7,   10,  20 ),
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

local FB = Enum.Font.GothamBold
local FN = Enum.Font.Gotham
local FM = Enum.Font.RobotoMono

-- ── Tween helpers ─────────────────────────────────────────────────────────────
local TF = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function tw(o, p)    TS:Create(o, TF, p):Play() end
local function flash(b, c)
    local orig = b.BackgroundColor3
    tw(b, {BackgroundColor3 = c})
    task.delay(0.22, function() tw(b, {BackgroundColor3 = orig}) end)
end

-- ── UI primitives ─────────────────────────────────────────────────────────────
local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8); c.Parent = p; return c
end
local function stroke(p, col, th)
    local s = Instance.new("UIStroke")
    s.Color = col or C.BORDER; s.Thickness = th or 1; s.Parent = p; return s
end
local function pad(p, v, h)
    local u = Instance.new("UIPadding")
    u.PaddingTop    = UDim.new(0, v); u.PaddingBottom = UDim.new(0, v)
    u.PaddingLeft   = UDim.new(0, h); u.PaddingRight  = UDim.new(0, h)
    u.Parent = p; return u
end
local function listV(p, sp)
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, sp or 4)
    l.HorizontalAlignment = Enum.HorizontalAlignment.Left
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = p; return l
end
local function F(par, sz, pos, col)
    local f = Instance.new("Frame"); f.Size = sz
    if pos then f.Position = pos end
    f.BackgroundColor3 = col or C.BG; f.BorderSizePixel = 0
    f.Parent = par; return f
end
local function L(par, txt, sz, pos, col, fnt, ts, xa)
    local l = Instance.new("TextLabel"); l.Size = sz
    if pos then l.Position = pos end
    l.BackgroundTransparency = 1; l.Text = txt
    l.TextColor3 = col or C.TXT; l.Font = fnt or FN
    l.TextSize = ts or 12; l.TextWrapped = true
    l.TextXAlignment = xa or Enum.TextXAlignment.Left
    l.Parent = par; return l
end
local function B(par, txt, sz, pos, bg, tc, ts, fnt)
    local b = Instance.new("TextButton"); b.Size = sz
    if pos then b.Position = pos end
    b.BackgroundColor3 = bg or C.ACC; b.Text = txt
    b.TextColor3 = tc or C.TXT; b.Font = fnt or FB
    b.TextSize = ts or 12; b.BorderSizePixel = 0
    b.Parent = par; return b
end
local function dot(par, sz, pos, col)
    local d = F(par, sz, pos, col or C.MUTED); corner(d, 99); return d
end

local function notify(title, body, dur)
    pcall(function()
        SG:SetCore("SendNotification", {Title = title, Text = body, Duration = dur or 3})
    end)
end

-- ── loadstring executor ───────────────────────────────────────────────────────
local function execScript(code)
    if not code or code:gsub("%s","") == "" then
        notify("Execute", "No script loaded.", 2); return
    end
    local fn, err = loadstring(code)
    if not fn then
        notify("Syntax Error", tostring(err):sub(1, 90), 5); return
    end
    local ok, runErr = pcall(fn)
    if not ok then
        notify("Runtime Error", tostring(runErr):sub(1, 90), 5)
    else
        notify("Nexus AI", "Script is running!", 2)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- POLLINATIONS AI  —  full script generation
-- ═══════════════════════════════════════════════════════════════════════════════
local SYS = [[You are an expert Roblox Lua script writer for executor environments (Delta, Synapse, KRNL).
Rules:
- Write a complete, self-contained, immediately runnable Lua script.
- Use task.spawn / task.wait (not coroutine or wait).
- Wrap risky calls in pcall.
- Find RemoteEvents/RemoteFunctions dynamically at runtime — never hardcode instance paths.
- If a draggable UI is requested, build it with ScreenGui + Frame, implement mouse+touch drag on the title bar.
- If toggles/switches are requested, implement proper on/off state with color feedback.
- Output ONLY raw Lua code. No markdown, no triple backticks, no prose.]]

local function aiGenerate(prompt)
    if not httpReq then return nil, "No HTTP function in this executor." end

    local payload = HS:JSONEncode({
        messages = {
            { role = "system", content = SYS   },
            { role = "user",   content = prompt },
        },
        model = "claude-opus-4-6",
        seed  = math.random(1, 99999),
    })

    for _, model in ipairs({"claude-opus-4-6", "openai"}) do
        local body = (model == "claude-opus-4-6") and payload or HS:JSONEncode({
            messages = {
                { role = "system", content = SYS   },
                { role = "user",   content = prompt },
            },
            model = model, seed = 42,
        })
        local ok, res = pcall(httpReq, {
            Url     = "https://text.pollinations.ai/",
            Method  = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body    = body,
        })
        if ok and res then
            local status = res.StatusCode or res.status or 0
            if status == 200 then
                local text = (res.Body or res.body or "")
                    :gsub("^```lua%s*",""):gsub("^```%s*",""):gsub("```%s*$","")
                    :gsub("^%s+",""):gsub("%s+$","")
                if #text > 20 then return text, nil end
            end
        end
    end
    return nil, "AI request failed — check your internet connection."
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SCANNER  —  frame-drawing pattern extraction
-- ═══════════════════════════════════════════════════════════════════════════════
local FPATS = {
    'Instance%.new%s*%(%s*["\']Frame["\']',
    'Instance%.new%s*%(%s*["\']ScreenGui["\']',
    'Instance%.new%s*%(%s*["\']ScrollingFrame["\']',
    'Instance%.new%s*%(%s*["\']SurfaceGui["\']',
    'Instance%.new%s*%(%s*["\']BillboardGui["\']',
    'Instance%.new%s*%(%s*["\']ImageLabel["\']',
    'Drawing%.new%s*%(%s*["\']Square["\']',
    'Drawing%.new%s*%(%s*["\']Circle["\']',
    'Drawing%.new%s*%(%s*["\']Triangle["\']',
    'Drawing%.new%s*%(%s*["\']Line["\']',
    'DrawingAPI','drawFrame','drawRect','renderFrame',
    'CreateBox','BoxESP','drawESP','UICorner','UIStroke',
}
local function matchesFP(code)
    for _, p in ipairs(FPATS) do if code:find(p) then return true end end
    return false
end
local function extractFunctions(src, name)
    if not src or src == "" then return {} end
    local res, seen = {}, {}
    local function tryAdd(sig, n, body)
        if seen[n] then return end
        if matchesFP(body) then
            seen[n] = true
            table.insert(res, {name=n, code=sig.."\n"..body.."\nend", source=name})
        end
    end
    for s,n,b in src:gmatch("(local%s+function%s+(%w+)%b()%s*)\n(.-)\nend") do tryAdd(s,n,b) end
    for s,n,b in src:gmatch("(function%s+([%w_%.]+)%b()%s*)\n(.-)\nend")       do tryAdd(s,n,b) end
    return res
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- BUILD GUI
-- ═══════════════════════════════════════════════════════════════════════════════
if PGUI:FindFirstChild("NexusAI") then PGUI.NexusAI:Destroy() end

local GUI = Instance.new("ScreenGui")
GUI.Name = "NexusAI"; GUI.ResetOnSpawn = false
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GUI.DisplayOrder = 999; GUI.Parent = PGUI

-- Shadow
local SHADOW = F(GUI, UDim2.new(0,510,0,632), UDim2.new(0.5,-255,0.5,-316), Color3.new(0,0,0))
SHADOW.BackgroundTransparency = 0.62; corner(SHADOW, 16)

-- Window
local WIN = F(GUI, UDim2.new(0,490,0,612), UDim2.new(0.5,-245,0.5,-306), C.BG)
corner(WIN, 12); stroke(WIN, C.BORDER, 1.5)

-- ── Title bar ─────────────────────────────────────────────────────────────────
local TBAR = F(WIN, UDim2.new(1,0,0,46), UDim2.new(0,0,0,0), C.SIDE)
corner(TBAR, 12); F(TBAR, UDim2.new(1,0,0,12), UDim2.new(0,0,1,-12), C.SIDE)

local STRIPE = F(TBAR, UDim2.new(0,3,0,24), UDim2.new(0,14,0.5,-12), C.ACC); corner(STRIPE,2)
L(TBAR, "Nexus AI",  UDim2.new(0,220,0,20), UDim2.new(0,25,0,7),  C.TXT,   FB, 14)
L(TBAR, "Delta  ·  Pollinations AI  ·  Claude Opus 4.6",
         UDim2.new(0,340,0,14), UDim2.new(0,25,0,27), C.MUTED, FN, 9)

local CLOSE = B(TBAR,"✕",UDim2.new(0,26,0,26),UDim2.new(1,-36,0.5,-13),C.RED,C.TXT,11,FB)
corner(CLOSE,6)
CLOSE.MouseEnter:Connect(function()  tw(CLOSE,{BackgroundColor3=Color3.fromRGB(255,70,70)}) end)
CLOSE.MouseLeave:Connect(function()  tw(CLOSE,{BackgroundColor3=C.RED}) end)
CLOSE.MouseButton1Click:Connect(function() GUI:Destroy() end)

-- ── Drag ──────────────────────────────────────────────────────────────────────
do
    local drag, dSt, wSt
    local function syncShadow()
        SHADOW.Position = UDim2.new(
            WIN.Position.X.Scale, WIN.Position.X.Offset - 10,
            WIN.Position.Y.Scale, WIN.Position.Y.Offset - 10)
    end
    TBAR.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then
            drag=true; dSt=i.Position; wSt=WIN.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if not drag then return end
        if i.UserInputType==Enum.UserInputType.MouseMovement
        or i.UserInputType==Enum.UserInputType.Touch then
            local d=i.Position-dSt
            WIN.Position=UDim2.new(wSt.X.Scale,wSt.X.Offset+d.X,wSt.Y.Scale,wSt.Y.Offset+d.Y)
            syncShadow()
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then drag=false end
    end)
    syncShadow()
end

-- ── Tab bar ───────────────────────────────────────────────────────────────────
local TABBAR = F(WIN, UDim2.new(1,-24,0,32), UDim2.new(0,12,0,54), C.PANEL)
corner(TABBAR, 8)
local TAB_AI  = B(TABBAR,"⬡  AI Generate",UDim2.new(0.5,-3,1,-8),UDim2.new(0,4,0,4),   C.ACC,  C.TXT,11,FB); corner(TAB_AI,6)
local TAB_SCN = B(TABBAR,"⬡  Scanner",    UDim2.new(0.5,-3,1,-8),UDim2.new(0.5,3,0,4), C.PANEL,C.SUB,11,FB); corner(TAB_SCN,6)

-- ── Status bar ────────────────────────────────────────────────────────────────
local SBAR = F(WIN, UDim2.new(1,-24,0,26), UDim2.new(0,12,0,94), C.PANEL)
corner(SBAR, 6)
local SDOT = dot(SBAR, UDim2.new(0,8,0,8), UDim2.new(0,8,0.5,-4), C.GRN)
local STXT = L(SBAR,"Ready",UDim2.new(1,-28,1,0),UDim2.new(0,22,0,0),C.SUB,FN,10)
STXT.TextTruncate = Enum.TextTruncate.AtEnd

local function setStatus(msg, col)
    STXT.Text = msg; tw(SDOT, {BackgroundColor3 = col or C.MUTED})
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- AI GENERATE PAGE
-- ═══════════════════════════════════════════════════════════════════════════════
local AI_PAGE = F(WIN, UDim2.new(1,-24,1,-130), UDim2.new(0,12,0,128), C.BG)

-- Prompt box
local PFRAME = F(AI_PAGE, UDim2.new(1,0,0,96), UDim2.new(0,0,0,0), C.PANEL)
corner(PFRAME,8); stroke(PFRAME,C.BORDER)
L(PFRAME,"Describe the script you want  (the AI will write it):",
  UDim2.new(1,-12,0,14), UDim2.new(0,10,0,6), C.SUB, FB, 9)

local PIN = Instance.new("TextBox")
PIN.Size              = UDim2.new(1,-16,0,64)
PIN.Position          = UDim2.new(0,8,0,22)
PIN.BackgroundColor3  = C.EDIT
PIN.Text              = ""
PIN.PlaceholderText   = 'e.g. "blade ball autoparry with all emotes, draggable ui, on/off switches, decompile and scan the game for all parry code, copy to clipboard"'
PIN.PlaceholderColor3 = C.MUTED
PIN.TextColor3        = C.TXT
PIN.Font              = FM
PIN.TextSize          = 10
PIN.MultiLine         = true
PIN.ClearTextOnFocus  = false
PIN.TextXAlignment    = Enum.TextXAlignment.Left
PIN.TextYAlignment    = Enum.TextYAlignment.Top
PIN.BorderSizePixel   = 0
PIN.Parent            = PFRAME
corner(PIN, 6); pad(PIN, 5, 8)

-- Generate button
local GENBTN = B(AI_PAGE,"⬡  Generate Script with AI",UDim2.new(1,0,0,36),UDim2.new(0,0,0,102),C.ACC,C.TXT,13,FB)
corner(GENBTN,8)
GENBTN.MouseEnter:Connect(function() tw(GENBTN,{BackgroundColor3=Color3.fromRGB(80,152,255)}) end)
GENBTN.MouseLeave:Connect(function() tw(GENBTN,{BackgroundColor3=C.ACC}) end)

-- Code output section
local OUTLBL  = L(AI_PAGE,"GENERATED SCRIPT", UDim2.new(0,160,0,12), UDim2.new(0,0,0,146), C.MUTED, FB, 9)
local OUTCNT  = L(AI_PAGE,"", UDim2.new(1,0,0,12), UDim2.new(0,0,0,146), C.MUTED, FN, 9)
OUTCNT.TextXAlignment = Enum.TextXAlignment.Right

-- Scrollable code preview
local CSCR = Instance.new("ScrollingFrame")
CSCR.Size                = UDim2.new(1,0,1,-206)
CSCR.Position            = UDim2.new(0,0,0,162)
CSCR.BackgroundColor3    = C.DEEP
CSCR.BorderSizePixel     = 0
CSCR.ScrollBarThickness  = 3
CSCR.ScrollBarImageColor3= C.ACC
CSCR.AutomaticCanvasSize = Enum.AutomaticSize.Y
CSCR.CanvasSize          = UDim2.new(0,0,0,0)
CSCR.Parent              = AI_PAGE
corner(CSCR,8); pad(CSCR,8,10)

local CLBL = Instance.new("TextLabel")
CLBL.Size                = UDim2.new(1,0,0,0)
CLBL.AutomaticSize       = Enum.AutomaticSize.Y
CLBL.BackgroundTransparency = 1
CLBL.Text                = "← Type a prompt above, then press Generate"
CLBL.TextColor3          = C.MUTED
CLBL.Font                = FM
CLBL.TextSize            = 10
CLBL.TextWrapped         = true
CLBL.TextXAlignment      = Enum.TextXAlignment.Left
CLBL.Parent              = CSCR

-- Copy + Execute buttons
local COPYBTN = B(AI_PAGE,"⧉  Copy Script",         UDim2.new(0.5,-3,0,32),UDim2.new(0,0,1,-34),  C.INDIGO,C.TXT,11,FB); corner(COPYBTN,8)
local EXECBTN = B(AI_PAGE,"▶  Execute via loadstring",UDim2.new(0.5,-3,0,32),UDim2.new(0.5,3,1,-34),C.GRN,   C.TXT,11,FB); corner(EXECBTN,8)

COPYBTN.MouseEnter:Connect(function() tw(COPYBTN,{BackgroundColor3=Color3.fromRGB(118,122,255)}) end)
COPYBTN.MouseLeave:Connect(function() tw(COPYBTN,{BackgroundColor3=C.INDIGO}) end)
EXECBTN.MouseEnter:Connect(function() tw(EXECBTN,{BackgroundColor3=Color3.fromRGB(50,220,110)}) end)
EXECBTN.MouseLeave:Connect(function() tw(EXECBTN,{BackgroundColor3=C.GRN}) end)

local generatedCode = ""

COPYBTN.MouseButton1Click:Connect(function()
    if generatedCode == "" then notify("Nexus AI","Nothing generated yet.",2); return end
    clipSet(generatedCode)
    flash(COPYBTN, C.GRN)
    COPYBTN.Text = "✓  Copied!"
    task.delay(1.8, function() COPYBTN.Text = "⧉  Copy Script" end)
    notify("Nexus AI","Script copied to clipboard!",2)
end)

EXECBTN.MouseButton1Click:Connect(function()
    if generatedCode == "" then notify("Nexus AI","Nothing generated yet.",2); return end
    flash(EXECBTN, C.AMBER)
    task.spawn(function() execScript(generatedCode) end)
end)

local generating = false
GENBTN.MouseButton1Click:Connect(function()
    if generating then return end
    local prompt = PIN.Text
    if not prompt or prompt:gsub("%s","") == "" then
        notify("Nexus AI","Enter a prompt first!",2); return
    end
    generating    = true
    generatedCode = ""
    CLBL.Text     = "Asking Claude Opus 4.6 ..."
    CLBL.TextColor3 = C.AMBER
    OUTCNT.Text   = ""
    setStatus("Generating with Claude Opus 4.6...", C.AMBER)
    tw(GENBTN,{BackgroundColor3=Color3.fromRGB(38,58,102)})
    GENBTN.Text = "Generating..."

    task.spawn(function()
        local code, err = aiGenerate(prompt)
        if code and #code > 20 then
            generatedCode   = code
            CLBL.Text       = code
            CLBL.TextColor3 = C.CODE
            OUTCNT.Text     = #code .. " chars"
            setStatus("Done — " .. #code .. " chars  ·  ready to copy / execute", C.GRN)
            notify("Nexus AI","Script ready! Press Copy or Execute.",3)
        else
            CLBL.Text       = "Generation failed:\n" .. (err or "unknown error")
            CLBL.TextColor3 = C.RED
            setStatus("Generation failed", C.RED)
            notify("Nexus AI", err or "AI request failed.", 4)
        end
        tw(GENBTN,{BackgroundColor3=C.ACC})
        GENBTN.Text = "⬡  Generate Script with AI"
        generating = false
    end)
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- SCANNER PAGE
-- ═══════════════════════════════════════════════════════════════════════════════
local SCN_PAGE = F(WIN, UDim2.new(1,-24,1,-130), UDim2.new(0,12,0,128), C.BG)
SCN_PAGE.Visible = false

local SCANBTN = B(SCN_PAGE,"⬡  Scan Game for Frame Functions",UDim2.new(1,0,0,36),UDim2.new(0,0,0,0),C.ACC,C.TXT,13,FB)
corner(SCANBTN,8)
SCANBTN.MouseEnter:Connect(function() tw(SCANBTN,{BackgroundColor3=Color3.fromRGB(80,152,255)}) end)
SCANBTN.MouseLeave:Connect(function() tw(SCANBTN,{BackgroundColor3=C.ACC}) end)

local RLBL = L(SCN_PAGE,"RESULTS",UDim2.new(0,80,0,12),UDim2.new(0,0,0,44),C.MUTED,FB,9)
local RCNT = L(SCN_PAGE,"",       UDim2.new(1,0,0,12), UDim2.new(0,0,0,44),C.SUB,  FN,9)
RCNT.TextXAlignment = Enum.TextXAlignment.Right

local RSCR = Instance.new("ScrollingFrame")
RSCR.Size                = UDim2.new(1,0,1,-60)
RSCR.Position            = UDim2.new(0,0,0,58)
RSCR.BackgroundColor3    = C.PANEL
RSCR.BorderSizePixel     = 0
RSCR.ScrollBarThickness  = 3
RSCR.ScrollBarImageColor3= C.ACC
RSCR.AutomaticCanvasSize = Enum.AutomaticSize.Y
RSCR.CanvasSize          = UDim2.new(0,0,0,0)
RSCR.Parent              = SCN_PAGE
corner(RSCR,8); listV(RSCR,6); pad(RSCR,8,8)

local EMPTY = L(RSCR,"No scripts scanned yet.\nPress Scan to search for frame-drawing functions.",
    UDim2.new(1,0,0,110), nil, C.MUTED, FN,12)
EMPTY.TextXAlignment = Enum.TextXAlignment.Center
EMPTY.TextYAlignment = Enum.TextYAlignment.Center

local function makeCard(info, idx)
    local CARD = Instance.new("Frame")
    CARD.Size=UDim2.new(1,0,0,0); CARD.AutomaticSize=Enum.AutomaticSize.Y
    CARD.BackgroundColor3=C.EDIT; CARD.BorderSizePixel=0
    CARD.LayoutOrder=idx; CARD.Parent=RSCR
    corner(CARD,7); stroke(CARD,C.BORDER,1); listV(CARD,0)

    -- Header
    local HDR = F(CARD,UDim2.new(1,0,0,32),nil,C.HDRROW)
    HDR.LayoutOrder=1; corner(HDR,7)
    F(HDR,UDim2.new(1,0,0,7),UDim2.new(0,0,1,-7),C.HDRROW)
    dot(HDR,UDim2.new(0,7,0,7),UDim2.new(0,9,0.5,-3),C.ACC)
    local NL=L(HDR,info.name,UDim2.new(1,-104,1,0),UDim2.new(0,22,0,0),C.ACC,FM,11)
    NL.TextTruncate=Enum.TextTruncate.AtEnd
    local PIL=F(HDR,UDim2.new(0,88,0,17),UDim2.new(1,-94,0.5,-8),Color3.fromRGB(22,32,58)); corner(PIL,4)
    local PT=L(PIL,info.source or "?",UDim2.new(1,-6,1,0),UDim2.new(0,3,0,0),C.MUTED,FM,9)
    PT.TextXAlignment=Enum.TextXAlignment.Center; PT.TextTruncate=Enum.TextTruncate.AtEnd

    -- Code preview
    local CR=Instance.new("Frame"); CR.Size=UDim2.new(1,0,0,0); CR.AutomaticSize=Enum.AutomaticSize.Y
    CR.BackgroundColor3=C.DEEP; CR.BorderSizePixel=0; CR.LayoutOrder=2; CR.Parent=CARD; pad(CR,6,10)
    local lines=info.code:split("\n"); local pl={}
    for i=1,math.min(8,#lines) do table.insert(pl,lines[i]) end
    if #lines>8 then table.insert(pl,"  ...("..(#lines-8).." more lines)") end
    local CT=Instance.new("TextLabel"); CT.Size=UDim2.new(1,0,0,0); CT.AutomaticSize=Enum.AutomaticSize.Y
    CT.BackgroundTransparency=1; CT.Text=table.concat(pl,"\n"); CT.TextColor3=C.CODE
    CT.Font=FM; CT.TextSize=9; CT.TextWrapped=true; CT.TextXAlignment=Enum.TextXAlignment.Left; CT.Parent=CR

    -- Copy + Execute row
    local BR=F(CARD,UDim2.new(1,0,0,34),nil,C.EDIT); BR.LayoutOrder=3
    local CP=B(BR,"⧉ Copy",    UDim2.new(0.5,-5,0,26),UDim2.new(0,4,0,4),  C.INDIGO,C.TXT,10,FB); corner(CP,6)
    local EX=B(BR,"▶ Execute",  UDim2.new(0.5,-5,0,26),UDim2.new(0.5,3,0,4),C.GRN,   C.TXT,10,FB); corner(EX,6)
    CP.MouseButton1Click:Connect(function()
        clipSet(info.code); flash(CP,C.GRN)
        CP.Text="✓ Copied!"; task.delay(1.5,function() CP.Text="⧉ Copy" end)
        notify("Scanner","Copied: "..info.name,2)
    end)
    EX.MouseButton1Click:Connect(function()
        flash(EX,C.AMBER); task.spawn(function() execScript(info.code) end)
    end)
end

local scanning = false
SCANBTN.MouseButton1Click:Connect(function()
    if scanning then return end; scanning=true
    for _,c in ipairs(RSCR:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    EMPTY.Visible=false; RCNT.Text=""
    setStatus("Collecting scripts...", C.AMBER)
    tw(SCANBTN,{BackgroundColor3=Color3.fromRGB(38,58,102)}); SCANBTN.Text="Scanning..."

    task.spawn(function()
        local scripts={}
        if getScripts then pcall(function() scripts=getScripts() end) end
        if #scripts==0 then
            for _,v in ipairs(game:GetDescendants()) do
                if v:IsA("LocalScript") or v:IsA("ModuleScript") or v:IsA("Script") then
                    table.insert(scripts,v)
                end
            end
        end
        setStatus("Found "..#scripts.." scripts — extracting...", C.AMBER)
        local found={}
        for _,scr in ipairs(scripts) do
            local src=""
            if doDecomp then pcall(function() src=doDecomp(scr) end) end
            if src=="" then pcall(function() src=scr.Source end) end
            if src and src~="" then
                for _,fn in ipairs(extractFunctions(src,scr.Name)) do
                    table.insert(found,fn)
                end
            end
        end
        if #found==0 then
            EMPTY.Visible=true; EMPTY.Text="No frame-drawing functions found."
            setStatus("0 results",C.RED); RCNT.Text="0 found"
        else
            RCNT.Text=#found.." found"
            for i,fn in ipairs(found) do
                if i>20 then break end; makeCard(fn,i); task.wait(0.03)
            end
            setStatus("Done — "..(#found).." frame functions found",C.GRN)
        end
        tw(SCANBTN,{BackgroundColor3=C.ACC}); SCANBTN.Text="⬡  Scan Again"; scanning=false
    end)
end)

-- ── Tab switching ─────────────────────────────────────────────────────────────
local function showTab(t)
    if t=="ai" then
        AI_PAGE.Visible=true;  SCN_PAGE.Visible=false
        tw(TAB_AI, {BackgroundColor3=C.ACC,   TextColor3=C.TXT})
        tw(TAB_SCN,{BackgroundColor3=C.PANEL, TextColor3=C.SUB})
    else
        AI_PAGE.Visible=false; SCN_PAGE.Visible=true
        tw(TAB_SCN,{BackgroundColor3=C.ACC,   TextColor3=C.TXT})
        tw(TAB_AI, {BackgroundColor3=C.PANEL, TextColor3=C.SUB})
    end
end
TAB_AI.MouseButton1Click:Connect(function()  showTab("ai")      end)
TAB_SCN.MouseButton1Click:Connect(function() showTab("scanner") end)

-- ── Boot ──────────────────────────────────────────────────────────────────────
setStatus("Ready — describe a script and press Generate", C.GRN)
notify("Nexus AI","Type any script request and press Generate, or use the Scanner tab.",4)
