--!nocheck
-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║   🛰  ADVANCED REMOTE SPY  ·  v2.0  ·  RemoteSpy_UI.lua                    ║
-- ║   Live in-game GUI for capturing, inspecting & replaying remotes.         ║
-- ║   Self-contained — paste & run.   Toggle: [RightShift]  or  floating btn  ║
-- ╠══════════════════════════════════════════════════════════════════════════╣
-- ║   WHAT IT DOES                                                             ║
-- ║   • Captures OUTGOING calls the game makes  (:FireServer / :InvokeServer)  ║
-- ║   • Captures INCOMING events the server sends (OnClientEvent)              ║
-- ║   • Live, searchable, filterable call log with per-remote call counts      ║
-- ║   • Rich detail panel: full path, source script, timestamped args & return ║
-- ║   • Pretty-printed argument tree + auto-generated replay snippet            ║
-- ║   • One-click Replay, Block (drop outgoing), Ignore (stop logging)         ║
-- ║   • Copy path / args / snippet / whole log, save log to file               ║
-- ║   • Mobile + PC · draggable · minimizable · dark themed                    ║
-- ║                                                                            ║
-- ║   This CANNOT read server source code (it never leaves the server); it     ║
-- ║   shows you the exact interface & responses — the real way to learn a      ║
-- ║   game's protocol. Passive by default: it does not send extra packets.     ║
-- ║                                                                            ║
-- ║   Console API (getgenv):  RemoteSpy.Toggle() .Clear() .Dump() .Stop()      ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

local _bootOk, _bootErr = pcall(function()

-- ════════════════════════════════════════════════════════════════════════════
--  SERVICES & ENVIRONMENT
-- ════════════════════════════════════════════════════════════════════════════
local Players     = game:GetService("Players")
local UIS         = game:GetService("UserInputService")
local TweenSvc    = game:GetService("TweenService")
local RunService  = game:GetService("RunService")
local StarterGui  = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- safe global getter (executors sandbox differently)
local ENV = (typeof(getgenv) == "function" and getgenv()) or _G
local function G(name)
    local ok, v = pcall(function()
        return (getgenv and getgenv()[name]) or rawget(_G, name) or (getfenv and getfenv(0)[name])
    end)
    if ok then return v end
    return nil
end

local hookmetamethod    = G("hookmetamethod")
local getnamecallmethod = G("getnamecallmethod")
local checkcaller       = G("checkcaller")
local getcallingscript  = G("getcallingscript")
local setclipboard      = G("setclipboard") or G("toclipboard") or G("set_clipboard")
local writefile         = G("writefile")
local gethui            = G("gethui")
local newcclosure       = G("newcclosure") or function(f) return f end
local iscclosure        = G("iscclosure")

-- ════════════════════════════════════════════════════════════════════════════
--  CONFIG
-- ════════════════════════════════════════════════════════════════════════════
local CONFIG = {
    CaptureOutgoing = true,   -- :FireServer / :InvokeServer made by the game
    CaptureIncoming = true,   -- OnClientEvent fired by the server to you
    PrintEachCall   = false,  -- also print every call to the console
    MaxLog          = 500,    -- max entries kept in memory
    MaxRows         = 200,    -- max visual rows (older ones recycled)
    MaxArgPreview   = 160,    -- truncate serialized string args
    MaxDepth        = 4,      -- table serialization depth
    RowHeight       = 34,
}

-- ════════════════════════════════════════════════════════════════════════════
--  THEME
-- ════════════════════════════════════════════════════════════════════════════
local T = {
    BG        = Color3.fromRGB(13, 13, 18),
    PANEL     = Color3.fromRGB(19, 19, 26),
    PANEL2    = Color3.fromRGB(24, 24, 33),
    INPUT     = Color3.fromRGB(11, 11, 16),
    ROW       = Color3.fromRGB(22, 22, 30),
    ROWHOV    = Color3.fromRGB(32, 32, 44),
    ROWSEL    = Color3.fromRGB(46, 34, 78),
    STROKE    = Color3.fromRGB(44, 44, 60),
    ACCENT    = Color3.fromRGB(138, 92, 246),
    ACCHOV    = Color3.fromRGB(158, 118, 250),
    OUT       = Color3.fromRGB(90, 170, 255),   -- outgoing FireServer
    INVK      = Color3.fromRGB(245, 190, 70),   -- InvokeServer (has return)
    IN        = Color3.fromRGB(80, 220, 140),   -- incoming OnClientEvent
    RED       = Color3.fromRGB(240, 90, 100),
    TEXT      = Color3.fromRGB(238, 238, 245),
    DIM       = Color3.fromRGB(140, 140, 165),
    DIM2      = Color3.fromRGB(96, 96, 120),
}

local FONT     = Enum.Font.Gotham
local FONT_MED = Enum.Font.GothamMedium
local FONT_BLD = Enum.Font.GothamBold
local FONT_MONO= Enum.Font.Code

-- ════════════════════════════════════════════════════════════════════════════
--  UTIL
-- ════════════════════════════════════════════════════════════════════════════
local function notify(text)
    if CONFIG.PrintEachCall then print("[RemoteSpy] " .. text) end
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = "RemoteSpy", Text = text, Duration = 4 })
    end)
end

local function fullPath(inst)
    if typeof(inst) ~= "Instance" then return tostring(inst) end
    local ok, p = pcall(function() return inst:GetFullName() end)
    return (ok and p) or inst.Name
end

local function nowClock() return os.clock() end
local function timeStr()
    return os.date("%H:%M:%S")
end

-- safe value serialization (for display) ------------------------------------
local function serialize(v, depth)
    depth = depth or 0
    local t = typeof(v)
    if t == "string" then
        local s = string.format("%q", v)
        if #s > CONFIG.MaxArgPreview then s = s:sub(1, CONFIG.MaxArgPreview) .. '..."' end
        return s
    elseif t == "number" or t == "boolean" then
        return tostring(v)
    elseif t == "nil" then
        return "nil"
    elseif t == "Instance" then
        return string.format("<%s: %s>", v.ClassName, fullPath(v))
    elseif t == "Vector3" then
        return string.format("Vector3.new(%.3g, %.3g, %.3g)", v.X, v.Y, v.Z)
    elseif t == "Vector2" then
        return string.format("Vector2.new(%.3g, %.3g)", v.X, v.Y)
    elseif t == "CFrame" then
        local p = v.Position
        return string.format("CFrame(%.2g, %.2g, %.2g)", p.X, p.Y, p.Z)
    elseif t == "Color3" then
        return string.format("Color3.fromRGB(%d, %d, %d)",
            math.floor(v.R*255+0.5), math.floor(v.G*255+0.5), math.floor(v.B*255+0.5))
    elseif t == "table" then
        if depth >= CONFIG.MaxDepth then return "{...}" end
        local parts, n = {}, 0
        for k, val in pairs(v) do
            n = n + 1
            if n > 30 then parts[#parts + 1] = "..."; break end
            local keyStr = (type(k) == "string" and k:match("^[%a_][%w_]*$"))
                and k or ("[" .. serialize(k, depth + 1) .. "]")
            parts[#parts + 1] = keyStr .. " = " .. serialize(val, depth + 1)
        end
        return "{ " .. table.concat(parts, ", ") .. " }"
    else
        return string.format("<%s: %s>", t, tostring(v))
    end
end

local function serializeArgs(args, count, sep)
    local parts = {}
    for i = 1, count do parts[i] = serialize(args[i]) end
    return table.concat(parts, sep or ", ")
end

-- ════════════════════════════════════════════════════════════════════════════
--  DATA STORE
-- ════════════════════════════════════════════════════════════════════════════
local Log       = {}          -- array of entries
local byRemote  = {}          -- path -> count
local blocked   = {}          -- path -> true (drop outgoing)
local ignored   = {}          -- path -> true (do not log)
local paused    = false
local totalCalls= 0

ENV.RemoteSpy_Log = Log

-- ════════════════════════════════════════════════════════════════════════════
--  GUI CONSTRUCTION HELPERS
-- ════════════════════════════════════════════════════════════════════════════
local function mk(class, props, parent)
    local o = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            if k ~= "Parent" then o[k] = v end
        end
    end
    if parent then o.Parent = parent end
    return o
end

local function corner(inst, r)
    mk("UICorner", { CornerRadius = UDim.new(0, r or 8) }, inst)
    return inst
end

local function stroke(inst, col, thick, trans)
    mk("UIStroke", {
        Color = col or T.STROKE, Thickness = thick or 1,
        Transparency = trans or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, inst)
    return inst
end

local function pad(inst, all, l, t, r, b)
    mk("UIPadding", {
        PaddingLeft   = UDim.new(0, l or all or 0),
        PaddingTop    = UDim.new(0, t or all or 0),
        PaddingRight  = UDim.new(0, r or all or 0),
        PaddingBottom = UDim.new(0, b or all or 0),
    }, inst)
    return inst
end

local function tween(inst, time, props)
    local tw = TweenSvc:Create(inst, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

-- ════════════════════════════════════════════════════════════════════════════
--  BUILD THE UI
-- ════════════════════════════════════════════════════════════════════════════
local guiParent do
    local ok, hui = pcall(function() return gethui and gethui() end)
    if ok and hui then guiParent = hui else guiParent = LocalPlayer:WaitForChild("PlayerGui") end
end

-- clean up an old instance
pcall(function()
    local old = guiParent:FindFirstChild("AdvRemoteSpy")
    if old then old:Destroy() end
end)

local ScreenGui = mk("ScreenGui", {
    Name = "AdvRemoteSpy",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 9999,
    IgnoreGuiInset = true,
}, guiParent)

-- ── Floating toggle button (mobile-friendly) ────────────────────────────────
local ToggleBtn = mk("TextButton", {
    Name = "Toggle",
    Size = UDim2.new(0, 46, 0, 46),
    Position = UDim2.new(0, 14, 0.5, -23),
    BackgroundColor3 = T.ACCENT,
    Text = "🛰",
    TextSize = 22,
    Font = FONT_BLD,
    TextColor3 = Color3.new(1, 1, 1),
    AutoButtonColor = true,
    ZIndex = 50,
}, ScreenGui)
corner(ToggleBtn, 23)
stroke(ToggleBtn, T.ACCHOV, 1.5)

-- ── Main window ─────────────────────────────────────────────────────────────
local Win = mk("Frame", {
    Name = "Window",
    Size = UDim2.new(0, 720, 0, 460),
    Position = UDim2.new(0.5, -360, 0.5, -230),
    BackgroundColor3 = T.BG,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, ScreenGui)
corner(Win, 12)
stroke(Win, T.STROKE, 1.5)

-- responsive clamp for phones
do
    local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    if vp.X < 760 then
        local w = math.max(320, vp.X - 30)
        local h = math.max(320, vp.Y - 90)
        Win.Size = UDim2.new(0, w, 0, h)
        Win.Position = UDim2.new(0.5, -w/2, 0.5, -h/2)
    end
end

-- ── Title bar ───────────────────────────────────────────────────────────────
local Title = mk("Frame", {
    Name = "TitleBar",
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundColor3 = T.PANEL,
    BorderSizePixel = 0,
}, Win)
corner(Title, 12)
mk("Frame", { -- square off bottom corners
    Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 1, -12),
    BackgroundColor3 = T.PANEL, BorderSizePixel = 0,
}, Title)

local Dot = mk("Frame", {
    Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(0, 14, 0.5, -5),
    BackgroundColor3 = T.IN, BorderSizePixel = 0,
}, Title)
corner(Dot, 5)

local TitleLbl = mk("TextLabel", {
    Size = UDim2.new(1, -220, 1, 0), Position = UDim2.new(0, 34, 0, 0),
    BackgroundTransparency = 1, Text = "Advanced Remote Spy",
    TextColor3 = T.TEXT, Font = FONT_BLD, TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Title)

local StatsLbl = mk("TextLabel", {
    Size = UDim2.new(0, 150, 1, 0), Position = UDim2.new(1, -230, 0, 0),
    BackgroundTransparency = 1, Text = "0 calls",
    TextColor3 = T.DIM, Font = FONT_MED, TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Right,
}, Title)

local function titleBtn(txt, xoff, col)
    local b = mk("TextButton", {
        Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, xoff, 0.5, -15),
        BackgroundColor3 = T.PANEL2, Text = txt, TextColor3 = col or T.TEXT,
        Font = FONT_BLD, TextSize = 16, AutoButtonColor = true,
    }, Title)
    corner(b, 7)
    return b
end
local MinBtn   = titleBtn("–", -74)
local CloseBtn = titleBtn("✕", -40, T.RED)

-- ── Toolbar ─────────────────────────────────────────────────────────────────
local Toolbar = mk("Frame", {
    Name = "Toolbar",
    Size = UDim2.new(1, -20, 0, 34), Position = UDim2.new(0, 10, 0, 46),
    BackgroundTransparency = 1,
}, Win)

local function toolBtn(txt, w, x, col)
    local b = mk("TextButton", {
        Size = UDim2.new(0, w, 1, 0), Position = UDim2.new(0, x, 0, 0),
        BackgroundColor3 = T.PANEL2, Text = txt, TextColor3 = col or T.TEXT,
        Font = FONT_MED, TextSize = 13, AutoButtonColor = true,
    }, Toolbar)
    corner(b, 7)
    stroke(b, T.STROKE, 1)
    return b
end

local PauseBtn = toolBtn("⏸ Pause", 78, 0)
local ClearBtn = toolBtn("🗑 Clear", 74, 84)
local AutoBtn  = toolBtn("⤓ Auto", 66, 162, T.IN)
local CopyBtn  = toolBtn("⧉ Copy", 66, 232)
local SaveBtn  = toolBtn("💾 Save", 66, 302)

-- search box
local SearchBox = mk("TextBox", {
    Size = UDim2.new(1, -378, 1, 0), Position = UDim2.new(0, 374, 0, 0),
    BackgroundColor3 = T.INPUT, Text = "", PlaceholderText = "🔍 Filter by remote name / path…",
    PlaceholderColor3 = T.DIM2, TextColor3 = T.TEXT, Font = FONT, TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
}, Toolbar)
corner(SearchBox, 7)
stroke(SearchBox, T.STROKE, 1)
pad(SearchBox, nil, 10, 0, 10, 0)

-- ── Filter chips row ────────────────────────────────────────────────────────
local Chips = mk("Frame", {
    Size = UDim2.new(1, -20, 0, 26), Position = UDim2.new(0, 10, 0, 86),
    BackgroundTransparency = 1,
}, Win)
local chipLayout = mk("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6),
    VerticalAlignment = Enum.VerticalAlignment.Center,
}, Chips)

local filters = { out = true, invk = true, incoming = true }
local chipRefs = {}
local function makeChip(key, label, col)
    local c = mk("TextButton", {
        Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = T.PANEL2, Text = "", AutoButtonColor = false,
    }, Chips)
    corner(c, 13)
    stroke(c, col, 1)
    pad(c, nil, 10, 0, 10, 0)
    local lbl = mk("TextLabel", {
        Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1, Text = label, TextColor3 = col,
        Font = FONT_MED, TextSize = 12,
    }, c)
    chipRefs[key] = { btn = c, lbl = lbl, col = col }
    return c
end
makeChip("out",      "→ FireServer",   T.OUT)
makeChip("invk",     "→ InvokeServer", T.INVK)
makeChip("incoming", "← OnClientEvent",T.IN)

-- ── Body: list (left) + detail (right) ──────────────────────────────────────
local Body = mk("Frame", {
    Name = "Body",
    Size = UDim2.new(1, -20, 1, -128), Position = UDim2.new(0, 10, 0, 118),
    BackgroundTransparency = 1,
}, Win)

local listW = 0.46
local List = mk("ScrollingFrame", {
    Name = "List",
    Size = UDim2.new(listW, -5, 1, 0), Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = T.PANEL, BorderSizePixel = 0,
    ScrollBarThickness = 5, ScrollBarImageColor3 = T.ACCENT,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
}, Body)
corner(List, 9)
stroke(List, T.STROKE, 1)
local listLayout = mk("UIListLayout", {
    Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
}, List)
mk("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }, List)

-- empty-state hint
local EmptyHint = mk("TextLabel", {
    Size = UDim2.new(1, -20, 0, 60), Position = UDim2.new(0, 10, 0, 20),
    BackgroundTransparency = 1,
    Text = "Waiting for remote traffic…\nTrigger something in-game.",
    TextColor3 = T.DIM2, Font = FONT, TextSize = 13, TextWrapped = true,
}, List)

local Detail = mk("ScrollingFrame", {
    Name = "Detail",
    Size = UDim2.new(1 - listW, 0, 1, 0), Position = UDim2.new(listW, 5, 0, 0),
    BackgroundColor3 = T.PANEL, BorderSizePixel = 0,
    ScrollBarThickness = 5, ScrollBarImageColor3 = T.ACCENT,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
}, Body)
corner(Detail, 9)
stroke(Detail, T.STROKE, 1)
local detailLayout = mk("UIListLayout", {
    Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
}, Detail)
pad(Detail, 12)

local DetailPlaceholder = mk("TextLabel", {
    Size = UDim2.new(1, 0, 0, 80), BackgroundTransparency = 1,
    Text = "Select a call on the left\nto inspect its details.",
    TextColor3 = T.DIM2, Font = FONT, TextSize = 14, TextWrapped = true,
    LayoutOrder = 1,
}, Detail)

-- ════════════════════════════════════════════════════════════════════════════
--  DETAIL PANEL RENDERING
-- ════════════════════════════════════════════════════════════════════════════
local function clearDetail()
    for _, ch in ipairs(Detail:GetChildren()) do
        if ch:IsA("GuiObject") then ch:Destroy() end
    end
end

local function detailSection(title, order)
    local lbl = mk("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1,
        Text = title:upper(), TextColor3 = T.ACCENT, Font = FONT_BLD, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = order,
    }, Detail)
    return lbl
end

local function detailValue(text, order, mono, col)
    local box = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = T.INPUT, LayoutOrder = order,
    }, Detail)
    corner(box, 6)
    stroke(box, T.STROKE, 1)
    pad(box, 8)
    mk("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, Text = text, TextColor3 = col or T.TEXT,
        Font = mono and FONT_MONO or FONT, TextSize = mono and 12 or 13,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true, RichText = false,
    }, box)
    return box
end

local function detailButton(text, order, col, cb)
    local b = mk("TextButton", {
        Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = col or T.PANEL2,
        Text = text, TextColor3 = Color3.new(1, 1, 1), Font = FONT_MED, TextSize = 13,
        AutoButtonColor = true, LayoutOrder = order,
    }, Detail)
    corner(b, 7)
    b.MouseButton1Click:Connect(cb)
    return b
end

local function copyToClipboard(text, label)
    if setclipboard then
        pcall(setclipboard, text)
        notify((label or "Copied") .. " to clipboard.")
    else
        notify("Executor has no clipboard function.")
    end
end

local function buildReplaySnippet(entry)
    local pathVar = entry.path:gsub("^game%.", "game:GetService(\"")
    -- best-effort readable snippet using the captured full path
    local m = (entry.method == "InvokeServer" or entry.method == "invokeServer") and "InvokeServer"
        or (entry.dir == "in" and "-- incoming (server → client); shown for reference" or "FireServer")
    if entry.dir == "in" then
        return string.format("-- %s\n-- %s fired: %s\n%s.OnClientEvent:Connect(function(%s) end)",
            entry.path, entry.method, entry.argsStr,
            entry.path, "...")
    end
    return string.format("%s:%s(%s)", entry.path, m, entry.argsStr)
end

local selectedEntry = nil
local rowRefs = {}   -- entry.id -> row frame

local function renderDetail(entry)
    selectedEntry = entry
    clearDetail()

    local dirColor = entry.dir == "in" and T.IN or (entry.method:lower():find("invoke") and T.INVK or T.OUT)
    local dirArrow = entry.dir == "in" and "←" or "→"

    -- header
    local head = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, LayoutOrder = 0,
    }, Detail)
    mk("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1,
        Text = string.format("%s  %s", dirArrow, entry.method),
        TextColor3 = dirColor, Font = FONT_BLD, TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, head)
    mk("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 0, 0, 22),
        BackgroundTransparency = 1,
        Text = string.format("%s   ·   called %d×   ·   %s", entry.class, byRemote[entry.path] or 1, entry.tstr),
        TextColor3 = T.DIM, Font = FONT, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, head)
    head.Size = UDim2.new(1, 0, 0, 42)

    detailSection("Remote path", 1)
    detailValue(entry.path, 2, true)

    detailSection("Calling script", 3)
    detailValue(entry.src or "?", 4, true, T.DIM)

    detailSection(string.format("Arguments (%d)", entry.argc), 5)
    detailValue(entry.argc > 0 and entry.argsPretty or "(no arguments)", 6, true,
        entry.argc > 0 and T.TEXT or T.DIM2)

    if entry.ret ~= nil then
        detailSection("Return value", 7)
        detailValue(entry.ret, 8, true, T.INVK)
    end

    detailSection("Replay snippet", 9)
    detailValue(buildReplaySnippet(entry), 10, true, T.IN)

    -- action buttons
    detailButton("⧉  Copy path", 11, T.PANEL2, function()
        copyToClipboard(entry.path, "Path")
    end)
    detailButton("⧉  Copy arguments", 12, T.PANEL2, function()
        copyToClipboard(entry.argsPretty, "Arguments")
    end)
    detailButton("⧉  Copy replay snippet", 13, T.PANEL2, function()
        copyToClipboard(buildReplaySnippet(entry), "Snippet")
    end)

    if entry.dir ~= "in" then
        detailButton("▶  Replay this call", 14, T.ACCENT, function()
            local inst = entry.instance
            if not (inst and typeof(inst) == "Instance" and inst.Parent) then
                notify("Replay: remote no longer exists.")
                return
            end
            local raw = entry.raw
            local ok, res = pcall(function()
                if entry.method:lower():find("invoke") then
                    return inst:InvokeServer(table.unpack(raw, 1, entry.argc))
                else
                    inst:FireServer(table.unpack(raw, 1, entry.argc))
                end
            end)
            if ok then
                notify("Replayed " .. inst.Name .. (res ~= nil and (" → " .. serialize(res)) or " (sent)"))
            else
                notify("Replay error: " .. tostring(res))
            end
        end)
    end

    local isBlocked = blocked[entry.path]
    detailButton(isBlocked and "✔  Unblock outgoing" or "⛔  Block outgoing", 15,
        isBlocked and T.IN or T.RED, function()
            blocked[entry.path] = (not isBlocked) or nil
            notify((blocked[entry.path] and "Blocking " or "Unblocked ") .. entry.path)
            renderDetail(entry)
        end)

    local isIgnored = ignored[entry.path]
    detailButton(isIgnored and "👁  Un-ignore (log again)" or "🚫  Ignore (stop logging)", 16,
        T.PANEL2, function()
            ignored[entry.path] = (not isIgnored) or nil
            notify((ignored[entry.path] and "Ignoring " or "Logging ") .. entry.path)
            renderDetail(entry)
        end)
end

-- ════════════════════════════════════════════════════════════════════════════
--  LIST ROW RENDERING  (with recycling)
-- ════════════════════════════════════════════════════════════════════════════
local autoScroll = true
local rowQueue = {}  -- FIFO of row frames for recycling

local function matchesFilter(entry)
    -- direction/method chips
    if entry.dir == "in" and not filters.incoming then return false end
    if entry.dir == "out" then
        if entry.method:lower():find("invoke") then
            if not filters.invk then return false end
        else
            if not filters.out then return false end
        end
    end
    -- search text
    local q = SearchBox.Text
    if q ~= "" then
        if not entry.path:lower():find(q:lower(), 1, true) then return false end
    end
    return true
end

local function makeRow(entry)
    local dirColor = entry.dir == "in" and T.IN or (entry.method:lower():find("invoke") and T.INVK or T.OUT)
    local arrow = entry.dir == "in" and "←" or "→"

    local row = mk("TextButton", {
        Size = UDim2.new(1, -8, 0, CONFIG.RowHeight),
        BackgroundColor3 = T.ROW, Text = "", AutoButtonColor = false,
        LayoutOrder = entry.id,
    }, List)
    corner(row, 6)

    -- direction stripe
    local stripe = mk("Frame", {
        Size = UDim2.new(0, 3, 1, -8), Position = UDim2.new(0, 4, 0, 4),
        BackgroundColor3 = dirColor, BorderSizePixel = 0,
    }, row)
    corner(stripe, 2)

    mk("TextLabel", {
        Size = UDim2.new(0, 16, 1, 0), Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1, Text = arrow, TextColor3 = dirColor,
        Font = FONT_BLD, TextSize = 15,
    }, row)

    local name = mk("TextLabel", {
        Size = UDim2.new(1, -80, 0, 16), Position = UDim2.new(0, 32, 0, 3),
        BackgroundTransparency = 1, Text = entry.name, TextColor3 = T.TEXT,
        Font = FONT_MED, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)

    mk("TextLabel", {
        Size = UDim2.new(1, -80, 0, 12), Position = UDim2.new(0, 32, 0, 18),
        BackgroundTransparency = 1,
        Text = string.format("%s · %d arg%s", entry.method, entry.argc, entry.argc == 1 and "" or "s"),
        TextColor3 = T.DIM2, Font = FONT, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)

    -- count badge
    local badge = mk("TextLabel", {
        Size = UDim2.new(0, 36, 0, 16), Position = UDim2.new(1, -40, 0.5, -8),
        BackgroundColor3 = T.PANEL2, Text = "×" .. (byRemote[entry.path] or 1),
        TextColor3 = T.DIM, Font = FONT_MED, TextSize = 11,
    }, row)
    corner(badge, 8)
    entry._badge = badge

    row.MouseEnter:Connect(function()
        if selectedEntry ~= entry then tween(row, 0.12, { BackgroundColor3 = T.ROWHOV }) end
    end)
    row.MouseLeave:Connect(function()
        if selectedEntry ~= entry then tween(row, 0.12, { BackgroundColor3 = T.ROW }) end
    end)
    row.MouseButton1Click:Connect(function()
        for _, r in pairs(rowRefs) do
            if r and r.Parent then r.BackgroundColor3 = T.ROW end
        end
        row.BackgroundColor3 = T.ROWSEL
        renderDetail(entry)
    end)

    rowRefs[entry.id] = row
    entry._row = row

    -- recycle oldest
    rowQueue[#rowQueue + 1] = { id = entry.id, row = row }
    if #rowQueue > CONFIG.MaxRows then
        local old = table.remove(rowQueue, 1)
        if old.row and old.row.Parent then old.row:Destroy() end
        rowRefs[old.id] = nil
    end

    return row
end

local function refreshFilterVisibility()
    for _, item in ipairs(rowQueue) do
        local entry = Log[item.id]
        if entry and item.row and item.row.Parent then
            item.row.Visible = matchesFilter(entry)
        end
    end
end

-- ════════════════════════════════════════════════════════════════════════════
--  RECORD  — called by the hooks
-- ════════════════════════════════════════════════════════════════════════════
local function record(entry)
    if EmptyHint and EmptyHint.Parent then EmptyHint:Destroy() end

    entry.id   = #Log + 1
    entry.tstr = timeStr()
    Log[entry.id] = entry
    byRemote[entry.path] = (byRemote[entry.path] or 0) + 1
    totalCalls = totalCalls + 1

    -- trim memory
    if #Log > CONFIG.MaxLog then
        -- keep it simple: drop the raw payload of the very old ones to free refs
        local drop = Log[#Log - CONFIG.MaxLog]
        if drop then drop.raw = nil end
    end

    -- update existing badges for same remote
    for _, item in ipairs(rowQueue) do
        local e = Log[item.id]
        if e and e.path == entry.path and e._badge and e._badge.Parent then
            e._badge.Text = "×" .. byRemote[entry.path]
        end
    end

    local row = makeRow(entry)
    row.Visible = matchesFilter(entry)

    if CONFIG.PrintEachCall then
        print(string.format("[RemoteSpy] %s %s(%s)%s",
            entry.dir == "in" and "<-" or "->",
            entry.path, entry.argsStr, entry.ret and (" -> " .. entry.ret) or ""))
    end

    if autoScroll then
        task.defer(function()
            List.CanvasPosition = Vector2.new(0, List.AbsoluteCanvasSize.Y)
        end)
    end
end

-- build an entry from captured data
local function makeEntry(dir, method, inst, args, count, ret)
    local path = fullPath(inst)
    local argsStr    = serializeArgs(args, count, ", ")
    local argsPretty
    if count == 0 then
        argsPretty = ""
    else
        local parts = {}
        for i = 1, count do
            parts[i] = string.format("[%d]  %s", i, serialize(args[i]))
        end
        argsPretty = table.concat(parts, "\n")
    end
    return {
        dir = dir, method = method, instance = inst,
        path = path, name = (typeof(inst) == "Instance" and inst.Name) or tostring(inst),
        class = (typeof(inst) == "Instance" and inst.ClassName) or "?",
        argc = count, argsStr = argsStr, argsPretty = argsPretty,
        raw = { table.unpack(args, 1, count) },
        ret = ret,
        src = (getcallingscript and (function()
            local ok, s = pcall(getcallingscript)
            return ok and s and fullPath(s) or "?"
        end)()) or nil,
    }
end

-- ════════════════════════════════════════════════════════════════════════════
--  HOOKS
-- ════════════════════════════════════════════════════════════════════════════
local FIRE = { FireServer = true, fireServer = true }
local INVK = { InvokeServer = true, invokeServer = true }

local oldNamecall
local hookActive = false

local function installOutgoing()
    if not (hookmetamethod and getnamecallmethod) then
        return false, "no hookmetamethod/getnamecallmethod"
    end
    local ok, err = pcall(function()
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local skip = paused or not CONFIG.CaptureOutgoing
                or (checkcaller and checkcaller())
                or typeof(self) ~= "Instance"
            if skip then return oldNamecall(self, ...) end

            local method = getnamecallmethod()

            if FIRE[method] then
                local path = fullPath(self)
                if not ignored[path] then
                    local args = { ... }
                    local count = select("#", ...)
                    pcall(function() record(makeEntry("out", method, self, args, count, nil)) end)
                end
                if blocked[path] then return end   -- drop the call
                return oldNamecall(self, ...)

            elseif INVK[method] then
                local path = fullPath(self)
                if blocked[path] then
                    if not ignored[path] then
                        local args = { ... }
                        local count = select("#", ...)
                        pcall(function()
                            local e = makeEntry("out", method, self, args, count, nil)
                            e.ret = "(blocked)"
                            record(e)
                        end)
                    end
                    return
                end
                local args = { ... }
                local count = select("#", ...)
                local results = { oldNamecall(self, ...) }
                if not ignored[path] then
                    pcall(function()
                        local retStr
                        local rc = select("#", table.unpack(results))
                        if rc == 0 then retStr = "nil" else
                            local rp = {}
                            for i = 1, rc do rp[i] = serialize(results[i]) end
                            retStr = table.concat(rp, ", ")
                        end
                        record(makeEntry("out", method, self, args, count, retStr))
                    end)
                end
                return table.unpack(results)
            end

            return oldNamecall(self, ...)
        end))
    end)
    if ok then hookActive = true end
    return ok, err
end

-- incoming: passively listen to OnClientEvent on every RemoteEvent
local watched = setmetatable({}, { __mode = "k" })
local incomingConns = {}

local function watchRemote(inst)
    if not CONFIG.CaptureIncoming then return end
    if watched[inst] then return end
    if typeof(inst) ~= "Instance" then return end
    local isEvent = inst:IsA("RemoteEvent") or (inst.ClassName == "UnreliableRemoteEvent")
    if not isEvent then return end
    watched[inst] = true
    local ok, conn = pcall(function()
        return inst.OnClientEvent:Connect(function(...)
            if paused or not CONFIG.CaptureIncoming then return end
            local path = fullPath(inst)
            if ignored[path] then return end
            local args = { ... }
            local count = select("#", ...)
            pcall(function() record(makeEntry("in", "OnClientEvent", inst, args, count, nil)) end)
        end)
    end)
    if ok and conn then incomingConns[#incomingConns + 1] = conn end
end

local function installIncoming()
    if not CONFIG.CaptureIncoming then return end
    task.spawn(function()
        for _, d in ipairs(game:GetDescendants()) do
            watchRemote(d)
        end
    end)
    incomingConns[#incomingConns + 1] = game.DescendantAdded:Connect(watchRemote)
end

-- ════════════════════════════════════════════════════════════════════════════
--  TOOLBAR / CHIP / STATS BEHAVIOUR
-- ════════════════════════════════════════════════════════════════════════════
local function setPaused(v)
    paused = v
    PauseBtn.Text = paused and "▶ Resume" or "⏸ Pause"
    PauseBtn.TextColor3 = paused and T.IN or T.TEXT
    Dot.BackgroundColor3 = paused and T.DIM2 or T.IN
end
PauseBtn.MouseButton1Click:Connect(function() setPaused(not paused) end)

local function doClear()
    for i = #Log, 1, -1 do Log[i] = nil end
    for k in pairs(byRemote) do byRemote[k] = nil end
    for _, item in ipairs(rowQueue) do
        if item.row and item.row.Parent then item.row:Destroy() end
    end
    rowQueue = {}
    rowRefs = {}
    selectedEntry = nil
    totalCalls = 0
    clearDetail()
    DetailPlaceholder = mk("TextLabel", {
        Size = UDim2.new(1, 0, 0, 80), BackgroundTransparency = 1,
        Text = "Select a call on the left\nto inspect its details.",
        TextColor3 = T.DIM2, Font = FONT, TextSize = 14, TextWrapped = true, LayoutOrder = 1,
    }, Detail)
    EmptyHint = mk("TextLabel", {
        Size = UDim2.new(1, -20, 0, 60), Position = UDim2.new(0, 10, 0, 20),
        BackgroundTransparency = 1, Text = "Waiting for remote traffic…\nTrigger something in-game.",
        TextColor3 = T.DIM2, Font = FONT, TextSize = 13, TextWrapped = true,
    }, List)
    notify("Log cleared.")
end
ClearBtn.MouseButton1Click:Connect(doClear)

local function setAuto(v)
    autoScroll = v
    AutoBtn.TextColor3 = autoScroll and T.IN or T.DIM2
end
AutoBtn.MouseButton1Click:Connect(function() setAuto(not autoScroll) end)

local function dumpText()
    local out = { string.format("===== RemoteSpy log (%d calls) =====", #Log) }
    for i, e in ipairs(Log) do
        out[#out + 1] = string.format("[%d] %s %s %s(%s)%s   {from %s}  @%s",
            i, e.dir == "in" and "<-" or "->", e.class, e.path, e.argsStr,
            e.ret and ("  ->  " .. e.ret) or "", e.src or "?", e.tstr)
    end
    return table.concat(out, "\n")
end

CopyBtn.MouseButton1Click:Connect(function()
    copyToClipboard(dumpText(), string.format("%d calls", #Log))
end)

SaveBtn.MouseButton1Click:Connect(function()
    if writefile then
        local fname = string.format("RemoteSpy_%s.txt", tostring(game.PlaceId))
        local ok = pcall(writefile, fname, dumpText())
        notify(ok and ("Saved to " .. fname) or "Save failed.")
    else
        notify("Executor has no writefile.")
    end
end)

SearchBox:GetPropertyChangedSignal("Text"):Connect(refreshFilterVisibility)

for key, ref in pairs(chipRefs) do
    ref.btn.MouseButton1Click:Connect(function()
        filters[key] = not filters[key]
        local on = filters[key]
        ref.lbl.TextColor3 = on and ref.col or T.DIM2
        ref.btn.BackgroundColor3 = on and T.PANEL2 or T.INPUT
        local st = ref.btn:FindFirstChildOfClass("UIStroke")
        if st then st.Color = on and ref.col or T.STROKE end
        refreshFilterVisibility()
    end)
end

-- stats + calls/sec ticker
do
    local lastCount, lastT = 0, nowClock()
    task.spawn(function()
        while ScreenGui and ScreenGui.Parent do
            task.wait(0.7)
            local n = totalCalls
            local dt = nowClock() - lastT
            local cps = dt > 0 and ((n - lastCount) / dt) or 0
            lastCount, lastT = n, nowClock()
            local uniq = 0
            for _ in pairs(byRemote) do uniq = uniq + 1 end
            StatsLbl.Text = string.format("%d calls · %d remotes · %.1f/s", n, uniq, cps)
        end
    end)
end

-- ════════════════════════════════════════════════════════════════════════════
--  WINDOW: DRAG · MINIMIZE · CLOSE · TOGGLE
-- ════════════════════════════════════════════════════════════════════════════
do -- dragging the window by the title bar
    local dragging, dragStart, startPos
    local function begin(input)
        dragging = true; dragStart = input.Position; startPos = Win.Position
    end
    Title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            begin(input)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            Win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                     startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

do -- dragging the floating toggle button
    local dragging, moved, dragStart, startPos
    ToggleBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; moved = false; dragStart = input.Position; startPos = ToggleBtn.Position
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            if d.Magnitude > 6 then moved = true end
            ToggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                           startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            if not moved then Win.Visible = not Win.Visible end
        end
    end)
end

local minimized = false
local savedSize
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        savedSize = Win.Size
        tween(Win, 0.18, { Size = UDim2.new(savedSize.X.Scale, savedSize.X.Offset, 0, 40) })
        Body.Visible = false; Toolbar.Visible = false; Chips.Visible = false
        MinBtn.Text = "□"
    else
        Body.Visible = true; Toolbar.Visible = true; Chips.Visible = true
        tween(Win, 0.18, { Size = savedSize })
        MinBtn.Text = "–"
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    Win.Visible = false
end)

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        Win.Visible = not Win.Visible
    end
end)

-- ════════════════════════════════════════════════════════════════════════════
--  CONSOLE API
-- ════════════════════════════════════════════════════════════════════════════
ENV.RemoteSpy = {
    Toggle = function() Win.Visible = not Win.Visible end,
    Show   = function() Win.Visible = true end,
    Hide   = function() Win.Visible = false end,
    Clear  = function() doClear() end,
    Dump   = function() local t = dumpText(); print(t); copyToClipboard(t, #Log .. " calls"); return t end,
    Pause  = function() setPaused(true) end,
    Resume = function() setPaused(false) end,
    Block  = function(path) blocked[path] = true end,
    Ignore = function(path) ignored[path] = true end,
    Stop   = function()
        CONFIG.CaptureOutgoing = false
        CONFIG.CaptureIncoming = false
        for _, c in ipairs(incomingConns) do pcall(function() c:Disconnect() end) end
        notify("Stopped capturing.")
    end,
    Log = Log,
}

-- ════════════════════════════════════════════════════════════════════════════
--  GO
-- ════════════════════════════════════════════════════════════════════════════
local okOut, errOut = installOutgoing()
installIncoming()

setPaused(false)
setAuto(true)

if okOut then
    notify("Capturing remotes. [RightShift] toggles the window.")
else
    Dot.BackgroundColor3 = T.INVK
    TitleLbl.Text = "Advanced Remote Spy  (incoming-only)"
    notify("Outgoing capture unavailable (" .. tostring(errOut) .. "). Incoming still works.")
end

end) -- end pcall

if not _bootOk then
    warn("[RemoteSpy] failed to start: " .. tostring(_bootErr))
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "RemoteSpy", Text = "Failed to start (see console).", Duration = 6,
        })
    end)
end
