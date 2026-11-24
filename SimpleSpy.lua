-- ============================================================
--  SimpleSpy.lua  —  v2 · sleek dark remote spy
--
--  Logs RemoteEvent / RemoteFunction traffic in both directions:
--    • Outgoing — :FireServer / :InvokeServer  (what YOUR client sends)
--    • Incoming — OnClientEvent                (what the SERVER fires to you)
--
--  One row per remote: if the same remote keeps firing, its counter
--  ticks up instead of spamming new rows. Select a row to see a runnable
--  snippet, the script that fired it, and Copy / Execute / Ignore it.
--
--  THEME, TABS and DEFAULT SETTINGS live in the CONFIG_JSON block below —
--  plain JSON, decoded with HttpService — so you can restyle the whole UI
--  (colours, tab order, tab names, tab icons) without touching any Lua.
--  If the JSON is broken, the built-in defaults are used instead.
--
--  For studying your OWN game's client<->server traffic. It shows the
--  interface the client uses; it can't read server source.
--
--  Executor: Delta, or anything with hookmetamethod + getnamecallmethod.
--  Show/hide: RightShift (configurable), or the floating button on mobile.
-- ============================================================

local CONFIG_JSON = [[
{
  "window": { "width": 640, "height": 400 },

  "settings": {
    "logOutgoing":  true,
    "logIncoming":  true,
    "acrylic":      true,
    "blur":         false,
    "blurSize":     12,
    "maxRows":      300,
    "maxStringLen": 5000,
    "maxDepth":     6,
    "toggleKey":    "RightShift"
  },

  "theme": {
    "background":      "#0D0E12",
    "surface":         "#14161C",
    "surfaceAlt":      "#1B1E26",
    "hover":           "#242834",
    "stroke":          "#2A2F3C",
    "accent":          "#6C8CFF",
    "text":            "#E9EBF2",
    "subtext":         "#8B91A3",
    "remoteEvent":     "#6C8CFF",
    "remoteFunction":  "#B484FF",
    "unreliableEvent": "#3CC6B4",
    "incoming":        "#4ED18F",
    "danger":          "#FF6B6B",
    "counter":         "#FFB35C"
  },

  "tabs": [
    { "id": "out",      "title": "Outgoing", "icon": "arrow_up"   },
    { "id": "in",       "title": "Incoming", "icon": "arrow_down" },
    { "id": "ignored",  "title": "Ignored",  "icon": "ban"        },
    { "id": "settings", "title": "Settings", "icon": "sliders"    }
  ]
}
]]
-- Tab ids: out, in, ignored, settings.
-- Icons:   arrow_up, arrow_down, ban, sliders, search, lens, close, minimize.

--// Services
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui       = game:GetService("StarterGui")
local HttpService      = game:GetService("HttpService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local LocalPlayer      = Players.LocalPlayer

-- ============================================================
--  CONFIG  (JSON -> Lua, merged over safe defaults)
-- ============================================================
local DEFAULTS = {
    window = { width = 640, height = 400 },
    settings = {
        logOutgoing = true, logIncoming = true, acrylic = true, blur = false,
        blurSize = 12, maxRows = 300, maxStringLen = 5000, maxDepth = 6,
        toggleKey = "RightShift",
    },
    theme = {
        background = "#0D0E12", surface = "#14161C", surfaceAlt = "#1B1E26",
        hover = "#242834", stroke = "#2A2F3C", accent = "#6C8CFF",
        text = "#E9EBF2", subtext = "#8B91A3", remoteEvent = "#6C8CFF",
        remoteFunction = "#B484FF", unreliableEvent = "#3CC6B4",
        incoming = "#4ED18F", danger = "#FF6B6B", counter = "#FFB35C",
    },
    tabs = {
        { id = "out",      title = "Outgoing", icon = "arrow_up" },
        { id = "in",       title = "Incoming", icon = "arrow_down" },
        { id = "ignored",  title = "Ignored",  icon = "ban" },
        { id = "settings", title = "Settings", icon = "sliders" },
    },
}
local KNOWN_TABS = { out = true, ["in"] = true, ignored = true, settings = true }

local function loadConfig()
    local ok, data = pcall(function() return HttpService:JSONDecode(CONFIG_JSON) end)
    if not ok or type(data) ~= "table" then data = {} end
    local cfg = {}
    for _, section in ipairs({ "window", "settings", "theme" }) do
        local given, out = data[section], {}
        for k, v in pairs(DEFAULTS[section]) do
            local g = nil
            if type(given) == "table" then g = given[k] end
            if g ~= nil and type(g) == type(v) then out[k] = g else out[k] = v end
        end
        cfg[section] = out
    end
    cfg.tabs = {}
    if type(data.tabs) == "table" then
        for _, t in ipairs(data.tabs) do
            if type(t) == "table" and KNOWN_TABS[t.id] then
                cfg.tabs[#cfg.tabs + 1] = {
                    id = t.id, title = tostring(t.title or t.id), icon = tostring(t.icon or "lens"),
                }
            end
        end
    end
    if #cfg.tabs == 0 then cfg.tabs = DEFAULTS.tabs end
    return cfg, ok
end

local CFG, configOk = loadConfig()
local S = CFG.settings

local function hexColor(h, fallbackHex)
    local ok, c = pcall(function() return Color3.fromHex(h) end)
    if ok and c then return c end
    return Color3.fromHex(fallbackHex)
end
local C = {}
for k, v in pairs(DEFAULTS.theme) do C[k] = hexColor(CFG.theme[k], v) end
local WHITE = Color3.new(1, 1, 1)

-- ============================================================
--  EXECUTOR FUNCTIONS (resolved safely)
-- ============================================================
local genv                 = (getgenv and getgenv()) or _G
local hookmetamethod_fn    = hookmetamethod
local getnamecallmethod_fn = getnamecallmethod
local checkcaller_fn       = checkcaller
local setclipboard_fn      = setclipboard or toclipboard or writeclipboard
local loadstring_fn        = loadstring
local gethui_fn            = gethui
local getcallingscript_fn  = getcallingscript

local function notify(t)
    print("[SimpleSpy] " .. t)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = "SimpleSpy", Text = t, Duration = 4 })
    end)
end

local function scriptName(inst)
    if typeof(inst) ~= "Instance" then return nil end
    local ok, p = pcall(function() return inst:GetFullName() end)
    return (ok and p) or inst.Name
end

local function callingScript()
    if not getcallingscript_fn then return nil end
    local ok, s = pcall(getcallingscript_fn)
    return ok and s or nil
end

-- ============================================================
--  VALUE -> RUNNABLE LUA
-- ============================================================
local function instancePath(inst)
    local ok, full = pcall(function() return inst:GetFullName() end)
    if not ok or not full then return nil end
    local segs = {}
    for seg in full:gmatch("[^%.]+") do segs[#segs + 1] = seg end
    if #segs == 0 then return nil end
    local services = {
        ReplicatedStorage = 1, ReplicatedFirst = 1, Workspace = 1, Players = 1, Lighting = 1,
        StarterGui = 1, StarterPack = 1, StarterPlayer = 1, SoundService = 1, Teams = 1, Chat = 1,
    }
    local out = services[segs[1]] and ('game:GetService("%s")'):format(segs[1])
                                   or ('game:FindFirstChild("%s")'):format(segs[1])
    for i = 2, #segs do out = out .. (':WaitForChild("%s")'):format(segs[i]) end
    return out
end

local toLua
local function keyToLua(k)
    if type(k) == "string" and k:match("^[%a_][%w_]*$") then return k end
    return "[" .. toLua(k, 0) .. "]"
end
toLua = function(v, depth)
    depth = depth or 0
    local t = typeof(v)
    if t == "string" then
        if #v > S.maxStringLen then
            return ("%q"):format(v:sub(1, S.maxStringLen)) .. " --[[ truncated ]]"
        end
        return ("%q"):format(v)
    elseif t == "number" then
        if v ~= v then return "0/0" end
        if v == math.huge then return "math.huge" end
        if v == -math.huge then return "-math.huge" end
        return tostring(v)
    elseif t == "boolean" or t == "nil" then return tostring(v)
    elseif t == "Vector3" then return ("Vector3.new(%s, %s, %s)"):format(v.X, v.Y, v.Z)
    elseif t == "Vector2" then return ("Vector2.new(%s, %s)"):format(v.X, v.Y)
    elseif t == "CFrame"  then return ("CFrame.new(%s)"):format(table.concat({ v:GetComponents() }, ", "))
    elseif t == "Color3"  then return ("Color3.new(%s, %s, %s)"):format(v.R, v.G, v.B)
    elseif t == "UDim2"   then return ("UDim2.new(%s, %s, %s, %s)"):format(v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset)
    elseif t == "UDim"    then return ("UDim.new(%s, %s)"):format(v.Scale, v.Offset)
    elseif t == "BrickColor" then return ('BrickColor.new("%s")'):format(v.Name)
    elseif t == "EnumItem" then return tostring(v)
    elseif t == "NumberRange" then return ("NumberRange.new(%s, %s)"):format(v.Min, v.Max)
    elseif t == "Instance" then
        return instancePath(v) or ('nil --[[ <%s> %s ]]'):format(v.ClassName, v.Name)
    elseif t == "table" then
        if depth >= S.maxDepth then return "{ --[[ max depth ]] }" end
        local pieces, isArray, n = {}, true, 0
        for k in pairs(v) do
            if type(k) ~= "number" then isArray = false end
            n = n + 1
            if n > 200 then break end
        end
        local pad, closePad = string.rep("    ", depth + 2), string.rep("    ", depth + 1)
        local c = 0
        for k, val in pairs(v) do
            c = c + 1
            if c > 200 then pieces[#pieces + 1] = pad .. "-- ...(truncated)" break end
            if isArray then
                pieces[#pieces + 1] = pad .. toLua(val, depth + 1) .. ","
            else
                pieces[#pieces + 1] = pad .. keyToLua(k) .. " = " .. toLua(val, depth + 1) .. ","
            end
        end
        if #pieces == 0 then return "{}" end
        return "{\n" .. table.concat(pieces, "\n") .. "\n" .. closePad .. "}"
    else
        return ('nil --[[ <%s> %s ]]'):format(t, tostring(v))
    end
end

local function buildScript(remote, method, args, count, retText, src)
    local path = instancePath(remote) or ('nil --[[ "%s" ]]'):format(remote.Name)

    -- Incoming: the server fired this to us; show what it sent + a listener.
    if method == "OnClientEvent" then
        local lines = { "-- " .. remote.ClassName .. "  |  OnClientEvent  (received FROM server)", "" }
        if count > 0 then
            lines[#lines + 1] = "-- the server sent these args:"
            lines[#lines + 1] = "local args = {"
            for i = 1, count do lines[#lines + 1] = "    " .. toLua(args[i], 0) .. "," end
            lines[#lines + 1] = "}"
            lines[#lines + 1] = ""
        end
        lines[#lines + 1] = "local remote = " .. path
        lines[#lines + 1] = "remote.OnClientEvent:Connect(function(...)"
        lines[#lines + 1] = '    print("[recv]", ...)'
        lines[#lines + 1] = "end)"
        return table.concat(lines, "\n")
    end

    local isInvoke = method:lower():find("invoke") ~= nil
    local lines = { "-- " .. remote.ClassName .. "  |  :" .. method .. "()" }
    if src then lines[#lines + 1] = "-- fired from: " .. src end
    lines[#lines + 1] = ""
    if count == 0 then
        lines[#lines + 1] = "local remote = " .. path
        lines[#lines + 1] = isInvoke and ("local result = remote:" .. method .. "()") or ("remote:" .. method .. "()")
        if isInvoke then lines[#lines + 1] = "print(result)" end
    else
        lines[#lines + 1] = "local args = {"
        for i = 1, count do lines[#lines + 1] = "    " .. toLua(args[i], 0) .. "," end
        lines[#lines + 1] = "}"
        lines[#lines + 1] = ""
        lines[#lines + 1] = "local remote = " .. path
        lines[#lines + 1] = isInvoke and ("local result = remote:" .. method .. "(table.unpack(args))")
                                       or ("remote:" .. method .. "(table.unpack(args))")
        if isInvoke then lines[#lines + 1] = "print(result)" end
    end
    if retText and retText ~= "" then
        lines[#lines + 1] = ""
        lines[#lines + 1] = "--[[ server returned: " .. retText .. " ]]"
    end
    return table.concat(lines, "\n")
end

-- ============================================================
--  UI TOOLKIT
-- ============================================================
local function mk(cls, props, kids)
    local o = Instance.new(cls)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then o[k] = v end
    end
    for _, c in ipairs(kids or {}) do c.Parent = o end
    if props and props.Parent then o.Parent = props.Parent end
    return o
end
local function corner(r) return mk("UICorner", { CornerRadius = UDim.new(0, r or 6) }) end
local function padAll(p)
    return mk("UIPadding", {
        PaddingTop = UDim.new(0, p), PaddingBottom = UDim.new(0, p),
        PaddingLeft = UDim.new(0, p), PaddingRight = UDim.new(0, p),
    })
end
local function tween(obj, t, props)
    local ok, tw = pcall(function()
        return TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    end)
    if ok and tw then tw:Play() else for k, v in pairs(props) do obj[k] = v end end
end

local connections = {}
local function connect(signal, fn)
    local c = signal:Connect(fn)
    connections[#connections + 1] = c
    return c
end

-- Acrylic: every "glass" surface remembers its see-through level so the
-- whole UI can flip between translucent and solid from Settings.
local glassParts = {}
local function glass(obj, base)
    glassParts[#glassParts + 1] = { obj = obj, base = base }
    obj.BackgroundTransparency = S.acrylic and base or 0
    return obj
end
local function applyAcrylic(on)
    for i = #glassParts, 1, -1 do
        local g = glassParts[i]
        if g.obj.Parent then
            g.obj.BackgroundTransparency = on and g.base or 0
        else
            table.remove(glassParts, i)
        end
    end
end

-- ── Icons: drawn from rounded frames, so they always render (no image IDs) ──
local function iconBar(holder, fills, x, y, w, h, rot)
    local f = mk("Frame", {
        Parent = holder, BorderSizePixel = 0, Size = UDim2.new(0, w, 0, h),
        Position = UDim2.new(0, x, 0, y), Rotation = rot or 0,
    }, { corner(math.floor(math.min(w, h) / 2)) })
    fills[#fills + 1] = f
end
local function iconRing(holder, strokes, x, y, d, thick)
    local f = mk("Frame", {
        Parent = holder, BackgroundTransparency = 1,
        Size = UDim2.new(0, d, 0, d), Position = UDim2.new(0, x, 0, y),
    }, { corner(math.floor(d / 2)) })
    strokes[#strokes + 1] = mk("UIStroke", { Parent = f, Thickness = thick or 2 })
end

local ICONS = {
    arrow_up = function(h, f)
        iconBar(h, f, 9, 5, 2, 12)
        iconBar(h, f, 3.5, 5.5, 8, 2, -45)
        iconBar(h, f, 8.5, 5.5, 8, 2, 45)
    end,
    arrow_down = function(h, f)
        iconBar(h, f, 9, 3, 2, 12)
        iconBar(h, f, 3.5, 12.5, 8, 2, 45)
        iconBar(h, f, 8.5, 12.5, 8, 2, -45)
    end,
    ban = function(h, f, s)
        iconRing(h, s, 3, 3, 14, 2)
        iconBar(h, f, 4, 9, 12, 2, 45)
    end,
    sliders = function(h, f)
        iconBar(h, f, 3, 4, 14, 2);  iconBar(h, f, 10, 2, 6, 6)
        iconBar(h, f, 3, 9, 14, 2);  iconBar(h, f, 4, 7, 6, 6)
        iconBar(h, f, 3, 14, 14, 2); iconBar(h, f, 8, 12, 6, 6)
    end,
    search = function(h, f, s)
        iconRing(h, s, 3, 3, 10, 2)
        iconBar(h, f, 10.5, 13, 6, 2, 45)
    end,
    lens = function(h, f, s)
        iconRing(h, s, 4, 4, 12, 2)
        iconBar(h, f, 8, 8, 4, 4)
    end,
    close = function(h, f)
        iconBar(h, f, 4, 9, 12, 2, 45)
        iconBar(h, f, 4, 9, 12, 2, -45)
    end,
    minimize = function(h, f)
        iconBar(h, f, 4, 9, 12, 2)
    end,
}

-- Draws a 20x20 icon centred in `parent`; returns setColor(color3).
local function drawIcon(name, parent, color)
    local holder = mk("Frame", {
        Parent = parent, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 20, 0, 20),
    })
    local fills, strokes = {}, {}
    ;(ICONS[name] or ICONS.lens)(holder, fills, strokes)
    local function setColor(c)
        for _, x in ipairs(fills) do x.BackgroundColor3 = c end
        for _, x in ipairs(strokes) do x.Color = c end
    end
    setColor(color)
    return setColor
end

-- ============================================================
--  WINDOW
-- ============================================================
-- Unload a previous copy (old or new version) before building a fresh one.
if type(genv.SimpleSpy_Stop) == "function" then pcall(genv.SimpleSpy_Stop) end
if genv.SimpleSpy_GUI then pcall(function() genv.SimpleSpy_GUI:Destroy() end) end
pcall(function()
    local old = Lighting:FindFirstChild("SimpleSpyBlur")
    if old then old:Destroy() end
end)

local screen = mk("ScreenGui", {
    Name = "SimpleSpy", ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 9999,
})
genv.SimpleSpy_GUI = screen
local parented = pcall(function()
    screen.Parent = (gethui_fn and gethui_fn()) or game:GetService("CoreGui")
end)
if not parented or not screen.Parent then screen.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local W, H = CFG.window.width, CFG.window.height

local main = mk("Frame", {
    Name = "Main", Parent = screen, AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0, W, 0, H), Position = UDim2.new(0.5, 0, 0.5, -math.floor(H / 2)),
    BackgroundColor3 = C.background, BorderSizePixel = 0, Active = true, ClipsDescendants = true,
}, { corner(14) })
glass(main, 0.3)
mk("UIStroke", { Parent = main, Color = C.stroke, Thickness = 1 })
local uiScale = mk("UIScale", { Parent = main })

-- ── top bar ──
local top = mk("Frame", { Parent = main, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44) })

local logo = mk("Frame", {
    Parent = top, Size = UDim2.new(0, 26, 0, 26), Position = UDim2.new(0, 14, 0.5, -13),
    BackgroundColor3 = C.accent, BorderSizePixel = 0,
}, { corner(8) })
drawIcon("lens", logo, WHITE)

local titleGroup = mk("Frame", {
    Parent = top, BackgroundTransparency = 1,
    Position = UDim2.new(0, 50, 0, 0), Size = UDim2.new(1, -260, 1, 0),
}, {
    mk("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
    }),
})
mk("TextLabel", {
    Parent = titleGroup, LayoutOrder = 1, BackgroundTransparency = 1,
    AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0),
    Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = C.text, Text = "SimpleSpy",
})
mk("TextLabel", {
    Parent = titleGroup, LayoutOrder = 2, BackgroundTransparency = 1,
    AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0),
    Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = C.stroke, Text = "/",
})
local tabLabel = mk("TextLabel", {
    Parent = titleGroup, LayoutOrder = 3, BackgroundTransparency = 1,
    AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0),
    Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.subtext, Text = "",
})

local stats = mk("TextLabel", {
    Parent = top, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -84, 0.5, 0), Size = UDim2.new(0, 160, 0, 20),
    Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.subtext,
    TextXAlignment = Enum.TextXAlignment.Right, Text = "",
})

local function winBtn(xOff, iconName)
    local b = mk("TextButton", {
        Parent = top, AutoButtonColor = false, Text = "", AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, xOff, 0.5, 0), Size = UDim2.new(0, 28, 0, 28),
        BackgroundColor3 = C.hover, BackgroundTransparency = 1, BorderSizePixel = 0,
    }, { corner(8) })
    local setColor = drawIcon(iconName, b, C.subtext)
    connect(b.MouseEnter, function() tween(b, 0.12, { BackgroundTransparency = 0 }); setColor(C.text) end)
    connect(b.MouseLeave, function() tween(b, 0.12, { BackgroundTransparency = 1 }); setColor(C.subtext) end)
    return b
end
local closeBtn = winBtn(-12, "close")
local minBtn   = winBtn(-44, "minimize")

mk("Frame", {
    Parent = main, Position = UDim2.new(0, 12, 0, 44), Size = UDim2.new(1, -24, 0, 1),
    BackgroundColor3 = C.stroke, BorderSizePixel = 0,
})

-- ── body: [sidebar] [list] [detail]  (or [sidebar] [settings]) ──
local body = mk("Frame", {
    Parent = main, BackgroundTransparency = 1,
    Position = UDim2.new(0, 0, 0, 52), Size = UDim2.new(1, 0, 1, -52),
})

local sidebar = mk("Frame", {
    Parent = body, Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(0, 52, 1, -8),
    BackgroundColor3 = C.surface, BorderSizePixel = 0,
}, {
    corner(12),
    mk("UIListLayout", {
        Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
    }),
    mk("UIPadding", { PaddingTop = UDim.new(0, 8) }),
})
glass(sidebar, 0.4)

-- list panel
local listPanel = mk("Frame", {
    Parent = body, Position = UDim2.new(0, 68, 0, 0), Size = UDim2.new(0, 230, 1, -8),
    BackgroundColor3 = C.surface, BorderSizePixel = 0,
}, { corner(12) })
glass(listPanel, 0.4)

local searchWrap = mk("Frame", {
    Parent = listPanel, Position = UDim2.new(0, 8, 0, 8), Size = UDim2.new(1, -16, 0, 32),
    BackgroundColor3 = C.surfaceAlt, BorderSizePixel = 0,
}, { corner(9) })
glass(searchWrap, 0.3)
local searchIcon = mk("Frame", { Parent = searchWrap, BackgroundTransparency = 1, Size = UDim2.new(0, 30, 1, 0) })
drawIcon("search", searchIcon, C.subtext)
local searchBox = mk("TextBox", {
    Parent = searchWrap, BackgroundTransparency = 1,
    Position = UDim2.new(0, 30, 0, 0), Size = UDim2.new(1, -38, 1, 0),
    Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = C.text, Text = "",
    PlaceholderText = "Search remotes", PlaceholderColor3 = C.subtext,
    ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
})

local list = mk("ScrollingFrame", {
    Parent = listPanel, Position = UDim2.new(0, 0, 0, 48), Size = UDim2.new(1, 0, 1, -48),
    BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
    ScrollBarImageColor3 = C.stroke, CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
}, {
    mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
    mk("UIPadding", {
        PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
        PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 8),
    }),
})
local emptyLabel = mk("TextLabel", {
    Parent = listPanel, BackgroundTransparency = 1,
    Position = UDim2.new(0, 14, 0, 48), Size = UDim2.new(1, -28, 1, -60),
    Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.subtext, TextWrapped = true, Text = "",
})

-- detail panel
local detail = mk("Frame", {
    Parent = body, Position = UDim2.new(0, 306, 0, 0), Size = UDim2.new(1, -314, 1, -8),
    BackgroundColor3 = C.surface, BorderSizePixel = 0,
}, { corner(12) })
glass(detail, 0.4)

local placeholder = mk("TextLabel", {
    Parent = detail, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
    Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = C.subtext,
    Text = "Select a remote to inspect it",
})

local header = mk("Frame", {
    Parent = detail, BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 10), Size = UDim2.new(1, -24, 0, 52), Visible = false,
})
local dBadge = mk("Frame", {
    Parent = header, Size = UDim2.new(0, 36, 0, 36), Position = UDim2.new(0, 0, 0, 4),
    BackgroundColor3 = C.remoteEvent, BackgroundTransparency = 0.82, BorderSizePixel = 0,
}, { corner(10) })
local dBadgeText = mk("TextLabel", {
    Parent = dBadge, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
    Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = C.remoteEvent, Text = "",
})
local dName = mk("TextLabel", {
    Parent = header, BackgroundTransparency = 1,
    Position = UDim2.new(0, 48, 0, 0), Size = UDim2.new(1, -118, 0, 20),
    Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = C.text,
    TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = "",
})
local dSub = mk("TextLabel", {
    Parent = header, BackgroundTransparency = 1,
    Position = UDim2.new(0, 48, 0, 20), Size = UDim2.new(1, -48, 0, 15),
    Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.subtext,
    TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = "",
})
local dFrom = mk("TextLabel", {
    Parent = header, BackgroundTransparency = 1,
    Position = UDim2.new(0, 48, 0, 36), Size = UDim2.new(1, -48, 0, 15),
    Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.subtext,
    TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = "",
})
local dCount = mk("TextLabel", {
    Parent = header, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 1),
    Size = UDim2.new(0, 62, 0, 20), BackgroundColor3 = C.counter, BackgroundTransparency = 0.82,
    BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = C.counter, Text = "",
}, { corner(10) })
local divider = mk("Frame", {
    Parent = detail, Position = UDim2.new(0, 12, 0, 70), Size = UDim2.new(1, -24, 0, 1),
    BackgroundColor3 = C.stroke, BorderSizePixel = 0, Visible = false,
})

local codeScroll = mk("ScrollingFrame", {
    Parent = detail, Position = UDim2.new(0, 8, 0, 78), Size = UDim2.new(1, -16, 1, -128),
    BackgroundColor3 = C.background, BorderSizePixel = 0, ClipsDescendants = true,
    ScrollBarThickness = 4, ScrollBarImageColor3 = C.stroke, CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
    Visible = false,
}, { corner(10), padAll(10) })
glass(codeScroll, 0.3)
local codeBox = mk("TextBox", {
    Parent = codeScroll, BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
    Font = Enum.Font.Code, TextSize = 13, TextColor3 = C.text,
    TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    MultiLine = true, ClearTextOnFocus = false, TextWrapped = true, TextEditable = true, Text = "",
})

local actions = mk("Frame", {
    Parent = detail, BackgroundTransparency = 1,
    Position = UDim2.new(0, 8, 1, -42), Size = UDim2.new(1, -16, 0, 34), Visible = false,
}, {
    mk("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }),
})
local function actBtn(order, text, bg, fg)
    return mk("TextButton", {
        Parent = actions, LayoutOrder = order, AutoButtonColor = true,
        Size = UDim2.new(1 / 3, -4, 1, 0), BackgroundColor3 = bg, BorderSizePixel = 0,
        Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = fg, Text = text,
    }, { corner(9) })
end
local copyBtn   = actBtn(1, "Copy", C.accent, WHITE)
local runBtn    = actBtn(2, "Execute", C.incoming, Color3.fromRGB(10, 30, 20))
local ignoreBtn = actBtn(3, "Ignore", C.surfaceAlt, C.danger)

-- settings panel (replaces list + detail on the Settings tab)
local settingsPanel = mk("ScrollingFrame", {
    Parent = body, Position = UDim2.new(0, 68, 0, 0), Size = UDim2.new(1, -76, 1, -8),
    BackgroundColor3 = C.surface, BorderSizePixel = 0, ScrollBarThickness = 3,
    ScrollBarImageColor3 = C.stroke, CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
    Visible = false,
}, {
    corner(12), padAll(14),
    mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
})
glass(settingsPanel, 0.4)

-- floating dock: brings the window back (the only way on mobile, no keyboard)
local dock = mk("TextButton", {
    Name = "Dock", Parent = screen, AutoButtonColor = false, Text = "",
    Size = UDim2.new(0, 48, 0, 48), Position = UDim2.new(0, 16, 0.5, -24),
    BackgroundColor3 = C.surface, BorderSizePixel = 0, Visible = false,
}, {
    corner(14),
    mk("UIStroke", { Color = C.accent, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
})
glass(dock, 0.2)
local dockLogo = mk("Frame", {
    Parent = dock, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 28, 0, 28), BackgroundColor3 = C.accent, BorderSizePixel = 0,
}, { corner(8) })
drawIcon("lens", dockLogo, WHITE)

-- ============================================================
--  STATE
-- ============================================================
local rows = {}          -- key -> row
local order, uniqueCount, outCount, inCount = 0, 0, 0, 0
local selected = nil
local currentTab = CFG.tabs[1].id
local searchText = ""
local active = true
local blur = nil
local setTab             -- forward declaration

local CLASS = {
    RemoteEvent           = { letter = "E", color = C.remoteEvent },
    RemoteFunction        = { letter = "F", color = C.remoteFunction },
    UnreliableRemoteEvent = { letter = "U", color = C.unreliableEvent },
}
local function classInfo(cn)
    local ci = CLASS[cn]
    if ci then return ci.letter, ci.color end
    return "?", C.subtext
end

local function fmtCount(n)
    if n >= 1e6 then return ("x%.1fm"):format(n / 1e6) end
    if n >= 1000 then return ("x%.1fk"):format(n / 1000) end
    return "x" .. n
end

local function rowSub(r)
    if r.incoming then return "OnClientEvent  ·  from server" end
    return ":" .. r.method .. "()" .. (r.srcShort and ("  ·  " .. r.srcShort) or "")
end

local function updateStats()
    stats.Text = ("%d out  ·  %d in"):format(outCount, inCount)
end

local function buildCode(r)
    r.code = buildScript(r.remote, r.method, r.args or {}, r.argCount or 0, r.retText, r.src)
    r.dirty = false
end

-- ============================================================
--  DETAIL + SELECTION
-- ============================================================
local function showDetail(r)
    local has = r ~= nil
    placeholder.Visible = not has
    header.Visible, divider.Visible, codeScroll.Visible, actions.Visible = has, has, has, has
    if not has then return end
    local letter, color = classInfo(r.className)
    dBadge.BackgroundColor3 = color
    dBadgeText.TextColor3 = color
    dBadgeText.Text = letter
    dName.Text = r.name
    dSub.Text = r.className .. "  ·  " ..
        (r.incoming and "OnClientEvent  (server -> you)" or (":" .. r.method .. "()  (you -> server)"))
    dFrom.Text = r.incoming and "Fired by the server" or ("Fired from " .. (r.src or "an unknown script"))
    dCount.Text = fmtCount(r.count)
    ignoreBtn.Text = r.ignored and "Unignore" or "Ignore"
    runBtn.Text = "Execute"
    runBtn.BackgroundTransparency = r.incoming and 0.6 or 0
end

local function selectRow(key)
    local old = selected and rows[selected]
    if old then
        old.selStroke.Transparency = 1
        old.button.BackgroundColor3 = C.surfaceAlt
    end
    selected = key
    local r = key and rows[key] or nil
    if r then
        r.selStroke.Transparency = 0
        r.button.BackgroundColor3 = C.hover
        if r.dirty then buildCode(r) end
        codeBox.Text = r.code
        codeScroll.CanvasPosition = Vector2.new(0, 0)
    end
    showDetail(r)
end

-- Live code refresh for the selected row, throttled so a spammy remote with
-- a huge payload doesn't re-serialize every single frame.
local refreshPending = false
local function refreshSelectedCode()
    refreshPending = false
    local r = selected and rows[selected]
    if not r or not r.dirty then return end
    if codeBox:IsFocused() then return end      -- don't clobber your edits
    buildCode(r)
    codeBox.Text = r.code
end
local function scheduleCodeRefresh()
    if refreshPending then return end
    refreshPending = true
    task.delay(0.25, refreshSelectedCode)
end

-- ============================================================
--  FILTERING (tab + search)
-- ============================================================
local EMPTY_TEXT = {
    out = "No outgoing remotes yet.\nDo something in-game and they'll show up here.",
    ["in"] = "No incoming remotes yet.\nThey appear when the server fires to you.",
    ignored = "Nothing ignored.\nSelect a remote and press Ignore to park it here.",
}

local function rowVisible(r)
    local inTab
    if currentTab == "ignored" then inTab = r.ignored
    elseif r.ignored then inTab = false
    elseif currentTab == "in" then inTab = r.incoming
    elseif currentTab == "out" then inTab = not r.incoming
    else inTab = false end
    if not inTab then return false end
    if searchText == "" then return true end
    local hay = string.lower(r.name .. " " .. r.method .. " " .. (r.srcShort or ""))
    return string.find(hay, searchText, 1, true) ~= nil
end

local function refilter()
    local n = 0
    for _, r in pairs(rows) do
        local vis = rowVisible(r)
        r.button.Visible = vis
        if vis then n = n + 1 end
    end
    if n == 0 then
        emptyLabel.Text = (searchText ~= "" and ('No remotes match "' .. searchBox.Text .. '".'))
            or EMPTY_TEXT[currentTab] or ""
    end
    emptyLabel.Visible = (n == 0)
    if selected and rows[selected] and not rows[selected].button.Visible then selectRow(nil) end
end

-- ============================================================
--  ROWS + RECORDING
-- ============================================================
local function makeRow(key, remote, method)
    order = order + 1
    local incoming = (method == "OnClientEvent")
    local cn = remote.ClassName
    local letter, color = classInfo(cn)

    local btn = mk("TextButton", {
        Parent = list, LayoutOrder = -order, AutoButtonColor = false, Text = "",
        Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = C.surfaceAlt, BorderSizePixel = 0,
    }, { corner(9) })
    glass(btn, 0.3)
    local selStroke = mk("UIStroke", {
        Parent = btn, Color = C.accent, Thickness = 1.5, Transparency = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
    local badge = mk("Frame", {
        Parent = btn, Position = UDim2.new(0, 8, 0.5, -15), Size = UDim2.new(0, 30, 0, 30),
        BackgroundColor3 = color, BackgroundTransparency = 0.82, BorderSizePixel = 0,
    }, { corner(8) })
    mk("TextLabel", {
        Parent = badge, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = color, Text = letter,
    })
    mk("TextLabel", {
        Parent = btn, BackgroundTransparency = 1,
        Position = UDim2.new(0, 46, 0, 7), Size = UDim2.new(1, -96, 0, 17),
        Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.text,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        Text = remote.Name,
    })
    local subL = mk("TextLabel", {
        Parent = btn, BackgroundTransparency = 1,
        Position = UDim2.new(0, 46, 0, 25), Size = UDim2.new(1, -54, 0, 15),
        Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.subtext,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = "",
    })
    local countL = mk("TextLabel", {
        Parent = btn, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 7),
        Size = UDim2.new(0, 42, 0, 18), BackgroundColor3 = C.counter, BackgroundTransparency = 0.82,
        BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = C.counter,
        Text = "x0",
    }, { corner(9) })

    local r = {
        key = key, remote = remote, method = method, incoming = incoming, className = cn,
        name = remote.Name, count = 0, code = "", dirty = true, ignored = false,
        button = btn, selStroke = selStroke, subLabel = subL, countLabel = countL,
    }
    rows[key] = r
    uniqueCount = uniqueCount + 1
    if incoming then inCount = inCount + 1 else outCount = outCount + 1 end
    updateStats()
    subL.Text = rowSub(r)
    btn.MouseButton1Click:Connect(function() selectRow(key) end)

    local vis = rowVisible(r)
    btn.Visible = vis
    if vis then emptyLabel.Visible = false end
    return r
end

local function record(remote, method, args, argCount, retText, src)
    local okKey, key = pcall(function() return remote:GetDebugId(0) .. "::" .. method end)
    if not okKey then key = tostring(remote) .. "::" .. method end

    local r = rows[key]
    if r and r.ignored then return end            -- ignored: stop logging it
    if not r then
        if uniqueCount >= S.maxRows then return end
        r = makeRow(key, remote, method)
    end

    r.count = r.count + 1
    r.countLabel.Text = fmtCount(r.count)
    r.remote, r.args, r.argCount, r.retText = remote, args, argCount, retText
    r.dirty = true

    local srcPath = src and scriptName(src) or nil
    if srcPath and srcPath ~= r.src then
        r.src = srcPath
        r.srcShort = srcPath:match("[^%.]+$") or srcPath
        r.subLabel.Text = rowSub(r)
    end

    if selected == key then
        dCount.Text = fmtCount(r.count)
        scheduleCodeRefresh()
    elseif selected == nil and r.button.Visible then
        selectRow(key)
    end
end

-- ============================================================
--  SIDEBAR TABS (built from the JSON "tabs" list)
-- ============================================================
local tabs, tabTitle = {}, {}
for i, t in ipairs(CFG.tabs) do
    tabTitle[t.id] = t.title
    local b = mk("TextButton", {
        Parent = sidebar, LayoutOrder = i, AutoButtonColor = false, Text = "",
        Size = UDim2.new(0, 38, 0, 38), BackgroundColor3 = C.hover, BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, { corner(10) })
    local indicator = mk("Frame", {
        Parent = b, Size = UDim2.new(0, 3, 0, 16), Position = UDim2.new(0, -7, 0.5, -8),
        BackgroundColor3 = C.accent, BorderSizePixel = 0, Visible = false,
    }, { corner(2) })
    local setColor = drawIcon(t.icon, b, C.subtext)
    tabs[t.id] = { button = b, indicator = indicator, setColor = setColor }
    connect(b.MouseButton1Click, function() setTab(t.id) end)
    connect(b.MouseEnter, function()
        if currentTab ~= t.id then tween(b, 0.12, { BackgroundTransparency = 0.5 }) end
    end)
    connect(b.MouseLeave, function()
        if currentTab ~= t.id then tween(b, 0.12, { BackgroundTransparency = 1 }) end
    end)
end

setTab = function(id)
    currentTab = id
    for tid, t in pairs(tabs) do
        local on = (tid == id)
        tween(t.button, 0.12, { BackgroundTransparency = on and 0 or 1 })
        t.indicator.Visible = on
        t.setColor(on and C.accent or C.subtext)
    end
    tabLabel.Text = tabTitle[id] or id
    local isSettings = (id == "settings")
    settingsPanel.Visible = isSettings
    listPanel.Visible = not isSettings
    detail.Visible = not isSettings
    if not isSettings then refilter() end
end

connect(searchBox:GetPropertyChangedSignal("Text"), function()
    searchText = string.lower(searchBox.Text)
    refilter()
end)

-- ============================================================
--  SHOW / HIDE, BLUR, DRAG, MINIMIZE
-- ============================================================
local function setBlur(on)
    if on then
        if not blur then
            pcall(function()
                blur = mk("BlurEffect", { Name = "SimpleSpyBlur", Size = S.blurSize, Parent = Lighting })
            end)
        end
        if blur then blur.Enabled = main.Visible end
    elseif blur then
        pcall(function() blur:Destroy() end)
        blur = nil
    end
end

local function setVisible(v)
    main.Visible = v
    dock.Visible = not v
    if blur then blur.Enabled = v end
end

local function makeDraggable(handle, target)
    local dragging, startInput, startPos, moved = false, nil, nil, false
    connect(handle.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging, startInput, startPos, moved = true, input.Position, target.Position, false
            local c
            c = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if c then c:Disconnect() end
                end
            end)
        end
    end)
    connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - startInput
            if math.abs(d.X) + math.abs(d.Y) > 4 then moved = true end
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                        startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    return function() return moved end
end

makeDraggable(top, main)
local dockWasDragged = makeDraggable(dock, dock)
connect(dock.MouseButton1Click, function()
    if dockWasDragged() then return end
    setVisible(true)
end)
connect(closeBtn.MouseButton1Click, function() setVisible(false) end)

local minimized = false
connect(minBtn.MouseButton1Click, function()
    minimized = not minimized
    if minimized then
        body.Visible = false
        tween(main, 0.18, { Size = UDim2.new(0, W, 0, 44) })
    else
        tween(main, 0.18, { Size = UDim2.new(0, W, 0, H) })
        task.delay(0.12, function() if not minimized then body.Visible = true end end)
    end
end)

-- Fit the window to small screens (phones) without changing its layout.
local function fit(first)
    local cam = workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    local s = math.min(1, (vp.X - 24) / W, (vp.Y - 80) / H)
    if s < 0.45 then s = 0.45 end
    uiScale.Scale = s
    if first then main.Position = UDim2.new(0.5, 0, 0.5, -math.floor(H * s / 2)) end
end

-- ============================================================
--  ACTION BUTTONS
-- ============================================================
connect(copyBtn.MouseButton1Click, function()
    if not (selected and rows[selected]) then return end
    if setclipboard_fn then
        pcall(setclipboard_fn, codeBox.Text)
        copyBtn.Text = "Copied"
        task.delay(1, function() copyBtn.Text = "Copy" end)
    else
        notify("Clipboard isn't available on this executor.")
    end
end)

connect(runBtn.MouseButton1Click, function()
    local r = selected and rows[selected]
    if not r then return end
    if r.incoming then
        notify("This is an INCOMING remote (server -> you). Nothing to fire - pick an Outgoing remote to replay.")
        runBtn.Text = "Incoming only"
        task.delay(1.4, function() runBtn.Text = "Execute" end)
        return
    end
    runBtn.Text = "..."
    local ran, result
    if loadstring_fn then
        local fn, compileErr = loadstring_fn(codeBox.Text)
        if not fn then
            notify("Compile error: " .. tostring(compileErr))
            runBtn.Text = "Execute"
            return
        end
        ran, result = pcall(fn)
    else
        ran, result = pcall(function()
            local n = r.argCount or 0
            return r.remote[r.method](r.remote, table.unpack(r.args or {}, 1, n))
        end)
    end
    if ran then
        runBtn.Text = "Sent"
        notify(("Executed :%s() on %s"):format(r.method, r.name))
    else
        runBtn.Text = "Error"
        notify("Execute error: " .. tostring(result))
    end
    task.delay(1.2, function() runBtn.Text = "Execute" end)
end)

connect(ignoreBtn.MouseButton1Click, function()
    local r = selected and rows[selected]
    if not r then return end
    r.ignored = not r.ignored
    notify((r.ignored and "Ignoring " or "Stopped ignoring ") .. r.name)
    refilter()
    if selected == r.key then showDetail(r) end
end)

-- ============================================================
--  CAPTURE: outgoing (__namecall hook) + incoming (OnClientEvent)
-- ============================================================
local FIRE = { FireServer = true, fireServer = true, SendToServer = true }
local INVK = { InvokeServer = true, invokeServer = true }
local oldNamecall

local function serializeReturn(res)
    local n = select("#", table.unpack(res))
    if n == 0 then return "" end
    local p = {}
    for i = 1, n do p[i] = toLua(res[i], 2) end
    return table.concat(p, ", ")
end

local function installHook()
    if not (hookmetamethod_fn and getnamecallmethod_fn) then
        notify("This executor has no hookmetamethod/getnamecallmethod - outgoing capture is off.")
        return false
    end
    local ok, err = pcall(function()
        oldNamecall = hookmetamethod_fn(game, "__namecall", function(self, ...)
            if active and S.logOutgoing and not (checkcaller_fn and checkcaller_fn()) then
                local m = getnamecallmethod_fn()
                if FIRE[m] and typeof(self) == "Instance" then
                    local a, c = { ... }, select("#", ...)
                    local src = callingScript()
                    pcall(record, self, m, a, c, nil, src)
                    return oldNamecall(self, ...)
                elseif INVK[m] and typeof(self) == "Instance" then
                    local a, c = { ... }, select("#", ...)
                    local src = callingScript()
                    local res = { oldNamecall(self, ...) }
                    local rt = ""
                    pcall(function() rt = serializeReturn(res) end)
                    pcall(record, self, m, a, c, rt, src)
                    return table.unpack(res)
                end
            end
            return oldNamecall(self, ...)
        end)
    end)
    if not ok then notify("Hook failed: " .. tostring(err)) return false end
    return true
end

-- FireClient / FireAllClients arrive on OnClientEvent, which __namecall never
-- sees, so we listen on every RemoteEvent. (RemoteFunction OnClientInvoke
-- allows only one callback and can't be watched without hijacking it.)
local watched = setmetatable({}, { __mode = "k" })
local function watchIncoming(remote)
    if watched[remote] then return end
    local cn = remote.ClassName
    if cn ~= "RemoteEvent" and cn ~= "UnreliableRemoteEvent" then return end
    watched[remote] = true
    pcall(function()
        connect(remote.OnClientEvent, function(...)
            if active and S.logIncoming then
                local a, c = { ... }, select("#", ...)
                pcall(record, remote, "OnClientEvent", a, c, nil, nil)
            end
        end)
    end)
end

local function startIncoming()
    pcall(function()
        for _, inst in ipairs(game:GetDescendants()) do watchIncoming(inst) end
    end)
    pcall(function()
        connect(game.DescendantAdded, function(inst)
            local ok = pcall(watchIncoming, inst)
            if not ok then return end
        end)
    end)
end

-- ============================================================
--  CLEAR / UNLOAD
-- ============================================================
local function clearAll()
    for _, r in pairs(rows) do pcall(function() r.button:Destroy() end) end
    rows = {}
    order, uniqueCount, outCount, inCount = 0, 0, 0, 0
    selected = nil
    showDetail(nil)
    updateStats()
    refilter()
end

local function unload()
    active = false
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    connections = {}
    if blur then pcall(function() blur:Destroy() end) blur = nil end
    pcall(function() screen:Destroy() end)
    if genv.SimpleSpy_GUI == screen then genv.SimpleSpy_GUI = nil end
    notify("Unloaded.")
end

-- ============================================================
--  SETTINGS PAGE
-- ============================================================
local settingsOrder = 0
local function nextOrder() settingsOrder = settingsOrder + 1; return settingsOrder end

local function sLabel(text, size, color, font, height)
    return mk("TextLabel", {
        Parent = settingsPanel, LayoutOrder = nextOrder(), BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, height or 18), Font = font or Enum.Font.Gotham,
        TextSize = size or 12, TextColor3 = color or C.subtext, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left, Text = text,
    })
end

local function sToggle(title, desc, initial, onChange)
    local rowF = mk("Frame", {
        Parent = settingsPanel, LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = C.surfaceAlt, BorderSizePixel = 0,
    }, { corner(10) })
    glass(rowF, 0.3)
    mk("TextLabel", {
        Parent = rowF, BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 6),
        Size = UDim2.new(1, -80, 0, 17), Font = Enum.Font.GothamBold, TextSize = 13,
        TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left, Text = title,
    })
    mk("TextLabel", {
        Parent = rowF, BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 23),
        Size = UDim2.new(1, -80, 0, 15), Font = Enum.Font.Gotham, TextSize = 11,
        TextColor3 = C.subtext, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, Text = desc,
    })
    local track = mk("TextButton", {
        Parent = rowF, AutoButtonColor = false, Text = "",
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.new(0, 40, 0, 22), BackgroundColor3 = initial and C.accent or C.stroke,
        BorderSizePixel = 0,
    }, { corner(11) })
    local function knobPos(on) return on and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9) end
    local knob = mk("Frame", {
        Parent = track, Size = UDim2.new(0, 18, 0, 18), Position = knobPos(initial),
        BackgroundColor3 = WHITE, BorderSizePixel = 0,
    }, { corner(9) })
    local state = initial
    connect(track.MouseButton1Click, function()
        state = not state
        tween(track, 0.15, { BackgroundColor3 = state and C.accent or C.stroke })
        tween(knob, 0.15, { Position = knobPos(state) })
        onChange(state)
    end)
end

local function sButtons(defs)
    local holder = mk("Frame", {
        Parent = settingsPanel, LayoutOrder = nextOrder(), BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 34),
    }, {
        mk("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })
    for i, d in ipairs(defs) do
        local b = mk("TextButton", {
            Parent = holder, LayoutOrder = i, AutoButtonColor = true,
            Size = UDim2.new(1 / #defs, -8 * (#defs - 1) / #defs, 1, 0),
            BackgroundColor3 = d.bg, BorderSizePixel = 0, Font = Enum.Font.GothamBold,
            TextSize = 13, TextColor3 = d.fg, Text = d.text,
        }, { corner(9) })
        connect(b.MouseButton1Click, d.fn)
    end
end

local toggleKey = Enum.KeyCode.RightShift
pcall(function() toggleKey = Enum.KeyCode[S.toggleKey] end)

sLabel("Settings", 16, C.text, Enum.Font.GothamBold, 22)
sToggle("Log outgoing", "FireServer / InvokeServer from your client", S.logOutgoing,
    function(v) S.logOutgoing = v end)
sToggle("Log incoming", "OnClientEvent fired to you by the server", S.logIncoming,
    function(v) S.logIncoming = v end)
sToggle("Acrylic glass", "See-through panels", S.acrylic,
    function(v) S.acrylic = v; applyAcrylic(v) end)
sToggle("Screen blur", "Frosted blur - note: Roblox blurs the WHOLE screen", S.blur,
    function(v) S.blur = v; setBlur(v) end)
sButtons({
    { text = "Clear all logs", bg = C.surfaceAlt, fg = C.text, fn = function() clearAll() end },
    { text = "Unload SimpleSpy", bg = C.danger, fg = WHITE, fn = function() unload() end },
})
sLabel("Show / hide: " .. tostring(S.toggleKey) .. " key, or the floating button on mobile.",
    11, C.subtext, Enum.Font.Gotham, 16)
sLabel("Theme, tabs and icons live in CONFIG_JSON at the top of the script.",
    11, C.subtext, Enum.Font.Gotham, 16)

-- ============================================================
--  API + HOTKEY + GO
-- ============================================================
connect(UserInputService.InputBegan, function(input, gpe)
    if not gpe and input.KeyCode == toggleKey then setVisible(not main.Visible) end
end)

genv.SimpleSpy_Toggle = function() setVisible(not main.Visible) end
genv.SimpleSpy_Clear  = clearAll
genv.SimpleSpy_Stop   = unload
genv.SimpleSpy_Unload = unload

fit(true)
pcall(function()
    connect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), function() fit(false) end)
end)
setTab(currentTab)
showDetail(nil)
updateStats()
setBlur(S.blur)

local hooked = installHook()
startIncoming()
if not configOk then notify("CONFIG_JSON couldn't be read - using the default theme.") end
notify(hooked and "Spying both ways. One row per remote; spam collapses into a counter."
              or  "Incoming capture is on, but this executor can't hook outgoing calls.")
