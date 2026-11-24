-- ============================================================
--  SimpleSpy v4  —  premium remote spy  (SimpleSpy.lua)
--
--  Logs RemoteEvent / RemoteFunction traffic in both directions:
--    • Outgoing — :FireServer / :InvokeServer  (what YOUR client sends)
--    • Incoming — OnClientEvent                (what the SERVER fires to you)
--
--  One row per remote: if the same remote keeps firing, its counter ticks
--  up instead of spamming new rows. Select a row to see:
--    • Script     – a runnable, syntax-highlighted snippet (tap to edit)
--    • Arguments  – every argument with its type
--    • History    – the last calls; tap one to load that exact call
--  plus Copy / Execute, Copy path, Ignore and Block.
--
--  THEME, SYNTAX COLOURS, TABS and DEFAULT SETTINGS live in CONFIG_JSON
--  below (plain JSON, decoded with HttpService). Accent colour, toggles
--  and window size you change in-app are saved between sessions.
--
--  For studying your OWN game's client<->server traffic. It shows the
--  interface the client uses; it can't read server source.
--
--  Executor: Delta, or anything with hookmetamethod + getnamecallmethod.
--  Show/hide: RightShift (configurable), or the floating button on mobile.
--  "/" focuses search.
-- ============================================================

local CONFIG_JSON = [[
{
  "window": { "width": 820, "height": 470 },

  "settings": {
    "logOutgoing":    true,
    "logIncoming":    true,
    "logExecutor":    false,
    "acrylic":        true,
    "animatedBorder": true,
    "blur":           false,
    "blurSize":       12,
    "maxRows":        300,
    "maxStringLen":   5000,
    "maxDepth":       6,
    "historySize":    30,
    "toggleKey":      "RightShift",
    "saveSettings":   true
  },

  "theme": {
    "background":      "#0B0C10",
    "backgroundTop":   "#13151C",
    "surface":         "#12141A",
    "surfaceAlt":      "#191C24",
    "hover":           "#222632",
    "stroke":          "#2A2F3C",
    "strokeSoft":      "#1F232D",
    "accent":          "#6C8CFF",
    "accent2":         "#A07CFF",
    "text":            "#ECEEF4",
    "subtext":         "#8A90A2",
    "muted":           "#5C6273",
    "remoteEvent":     "#6C8CFF",
    "remoteFunction":  "#B484FF",
    "unreliableEvent": "#3CC6B4",
    "incoming":        "#4ED18F",
    "danger":          "#FF6B6B",
    "warning":         "#FFB35C",
    "counter":         "#FFB35C"
  },

  "syntax": {
    "text":    "#DDE1EA",
    "keyword": "#C792EA",
    "string":  "#A5E07D",
    "number":  "#F9A15A",
    "comment": "#5C6273",
    "builtin": "#7FD4FF",
    "method":  "#FFD580"
  },

  "tabs": [
    { "id": "out",      "title": "Outgoing", "icon": "send",    "color": "accent"   },
    { "id": "in",       "title": "Incoming", "icon": "receive", "color": "incoming" },
    { "id": "ignored",  "title": "Ignored",  "icon": "ban",     "color": "danger"   },
    { "id": "settings", "title": "Settings", "icon": "gear",    "color": "accent2"  }
  ]
}
]]
-- Tab ids: out, in, ignored, settings.
-- Icons:   send, receive, ban, gear, lock, copy, search, chevron, lens.
-- Colors:  any key from "theme".

local VERSION   = "v4"
local SAVE_FILE = "SimpleSpy_settings.json"

-- Accent presets offered in Settings (accent + gradient partner).
local ACCENTS = {
    { name = "Azure",   a = "#6C8CFF", b = "#A07CFF" },
    { name = "Violet",  a = "#9B7BFF", b = "#FF6FB5" },
    { name = "Rose",    a = "#FF6FB5", b = "#FFB35C" },
    { name = "Mint",    a = "#3CC6B4", b = "#6C8CFF" },
    { name = "Amber",   a = "#FFB35C", b = "#FF6B6B" },
    { name = "Crimson", a = "#FF6B6B", b = "#B484FF" },
}

--// Services
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui       = game:GetService("StarterGui")
local HttpService      = game:GetService("HttpService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local Lighting         = game:GetService("Lighting")
local LocalPlayer      = Players.LocalPlayer

local function clamp(x, a, b)
    if x < a then return a end
    if x > b then return b end
    return x
end

-- ============================================================
--  CONFIG  (JSON -> Lua, merged over safe defaults)
-- ============================================================
local DEFAULTS = {
    window = { width = 820, height = 470 },
    settings = {
        logOutgoing = true, logIncoming = true, logExecutor = false, acrylic = true, animatedBorder = true,
        blur = false, blurSize = 12, maxRows = 300, maxStringLen = 5000, maxDepth = 6,
        historySize = 30, toggleKey = "RightShift", saveSettings = true,
    },
    theme = {
        background = "#0B0C10", backgroundTop = "#13151C", surface = "#12141A",
        surfaceAlt = "#191C24", hover = "#222632", stroke = "#2A2F3C", strokeSoft = "#1F232D",
        accent = "#6C8CFF", accent2 = "#A07CFF", text = "#ECEEF4", subtext = "#8A90A2",
        muted = "#5C6273", remoteEvent = "#6C8CFF", remoteFunction = "#B484FF",
        unreliableEvent = "#3CC6B4", incoming = "#4ED18F", danger = "#FF6B6B",
        warning = "#FFB35C", counter = "#FFB35C",
    },
    syntax = {
        text = "#DDE1EA", keyword = "#C792EA", string = "#A5E07D", number = "#F9A15A",
        comment = "#5C6273", builtin = "#7FD4FF", method = "#FFD580",
    },
    tabs = {
        { id = "out",      title = "Outgoing", icon = "send",    color = "accent" },
        { id = "in",       title = "Incoming", icon = "receive", color = "incoming" },
        { id = "ignored",  title = "Ignored",  icon = "ban",     color = "danger" },
        { id = "settings", title = "Settings", icon = "gear",    color = "accent2" },
    },
}
local KNOWN_TABS = { out = true, ["in"] = true, ignored = true, settings = true }
local DEFAULT_TAB_COLOR = { out = "accent", ["in"] = "incoming", ignored = "danger", settings = "accent2" }

local function loadConfig()
    local ok, data = pcall(function() return HttpService:JSONDecode(CONFIG_JSON) end)
    if not ok or type(data) ~= "table" then data = {} end
    local cfg = {}
    for _, section in ipairs({ "window", "settings", "theme", "syntax" }) do
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
                    color = tostring(t.color or DEFAULT_TAB_COLOR[t.id]),
                }
            end
        end
    end
    if #cfg.tabs == 0 then cfg.tabs = DEFAULTS.tabs end
    return cfg, ok
end

local CFG, configOk = loadConfig()
local S = CFG.settings
S.accentIndex = 0                 -- 0 = the accent from CONFIG_JSON

-- ── executor file API (for saved settings) ──
local writefile_fn, readfile_fn, isfile_fn = writefile, readfile, isfile

local SAVED_KEYS = { "logOutgoing", "logIncoming", "logExecutor", "acrylic", "animatedBorder", "blur" }
if S.saveSettings and readfile_fn and isfile_fn then
    pcall(function()
        if not isfile_fn(SAVE_FILE) then return end
        local saved = HttpService:JSONDecode(readfile_fn(SAVE_FILE))
        if type(saved) ~= "table" then return end
        for _, k in ipairs(SAVED_KEYS) do
            if type(saved[k]) == "boolean" then S[k] = saved[k] end
        end
        if type(saved.accent) == "number" and ACCENTS[saved.accent] then S.accentIndex = saved.accent end
        if type(saved.width) == "number" and type(saved.height) == "number" then
            CFG.window.width, CFG.window.height = saved.width, saved.height
        end
    end)
end

-- ── colours ──
local function isHex(h) return type(h) == "string" and h:match("^#?%x%x%x%x%x%x$") ~= nil end
local function hexColor(h, fallbackHex)
    local ok, c = pcall(function() return Color3.fromHex(h) end)
    if ok and c then return c end
    return Color3.fromHex(fallbackHex)
end
local C = {}
for k, v in pairs(DEFAULTS.theme) do C[k] = hexColor(CFG.theme[k], v) end
if S.accentIndex > 0 then
    C.accent  = Color3.fromHex(ACCENTS[S.accentIndex].a)
    C.accent2 = Color3.fromHex(ACCENTS[S.accentIndex].b)
end
local SYN = {}
for k, v in pairs(DEFAULTS.syntax) do
    local h = isHex(CFG.syntax[k]) and CFG.syntax[k] or v
    SYN[k] = (h:sub(1, 1) == "#") and h or ("#" .. h)
end
local WHITE, BLACK = Color3.new(1, 1, 1), Color3.new(0, 0, 0)

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
local newcclosure_fn       = newcclosure
local hookfunction_fn      = hookfunction or replaceclosure
local getrawmetatable_fn   = getrawmetatable
local setreadonly_fn       = setreadonly
local identify_fn          = identifyexecutor or getexecutorname

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

-- Stable per-remote id WITHOUT any :Method() call: the namecall hook must not make
-- method calls before running the original (that would overwrite the pending
-- method name and turn the game's :FireServer() into something else).
local remoteIds, nextRemoteId = setmetatable({}, { __mode = "k" }), 0
local function keyFor(remote, method)
    local id = remoteIds[remote]
    if not id then
        nextRemoteId = nextRemoteId + 1
        id = "r" .. nextRemoteId
        remoteIds[remote] = id
    end
    return id .. "::" .. method
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

-- Short one-line preview of a value (Arguments + History pages).
local function preview(v, depth)
    depth = depth or 0
    local t = typeof(v)
    if t == "string" then
        local s = v:gsub("\n", "\\n")
        if #s > 48 then s = s:sub(1, 48) .. "…" end
        return '"' .. s .. '"'
    elseif t == "table" then
        if depth >= 1 then return "{…}" end
        local parts, c = {}, 0
        for k, val in pairs(v) do
            c = c + 1
            if c > 3 then parts[#parts + 1] = "…" break end
            parts[#parts + 1] = (type(k) == "string" and (k .. " = ") or "") .. preview(val, depth + 1)
        end
        if #parts == 0 then return "{}" end
        return "{ " .. table.concat(parts, ", ") .. " }"
    elseif t == "Instance" then
        return v.Name
    end
    local s = toLua(v, 0)
    if #s > 60 then s = s:sub(1, 60) .. "…" end
    return s
end

-- ============================================================
--  SYNTAX HIGHLIGHTING  (RichText)
-- ============================================================
local highlight
do
    local KEYWORDS, BUILTINS = {}, {}
    for w in ("and break do else elseif end false for function if in local nil not or repeat return then true until while continue"):gmatch("%S+") do KEYWORDS[w] = true end
    for w in ("game workspace script Vector3 Vector2 CFrame Color3 UDim UDim2 BrickColor Enum Instance NumberRange math table string print task typeof pairs ipairs tostring tonumber unpack"):gmatch("%S+") do BUILTINS[w] = true end

    local function rtEscape(s)
        return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"):gsub("'", "&apos;"))
    end
    local function paint(s, hex, italic)
        s = rtEscape(s)
        if italic then s = "<i>" .. s .. "</i>" end
        return '<font color="' .. hex .. '">' .. s .. "</font>"
    end

    highlight = function(src)
        local out, i, n, prev = {}, 1, #src, ""
        while i <= n do
            local c = src:sub(i, i)
            if c == "-" and src:sub(i + 1, i + 1) == "-" then
                local j
                if src:sub(i + 2, i + 3) == "[[" then
                    local e = src:find("]]", i + 4, true)
                    j = e and (e + 1) or n
                else
                    j = (src:find("\n", i, true) or (n + 1)) - 1
                end
                out[#out + 1] = paint(src:sub(i, j), SYN.comment, true)
                i = j + 1
            elseif c == '"' or c == "'" then
                local j = i + 1
                while j <= n do
                    local d = src:sub(j, j)
                    if d == "\\" then j = j + 2
                    elseif d == c or d == "\n" then break
                    else j = j + 1 end
                end
                if j > n then j = n end
                out[#out + 1] = paint(src:sub(i, j), SYN.string)
                i, prev = j + 1, c
            elseif c:match("%d") then
                local num = src:match("^0[xX]%x+", i) or src:match("^%d+%.?%d*[eE][%-+]?%d+", i)
                         or src:match("^%d+%.?%d*", i)
                out[#out + 1] = paint(num, SYN.number)
                i, prev = i + #num, "0"
            elseif c:match("[%a_]") then
                local word = src:match("^[%a_][%w_]*", i)
                local hex
                if KEYWORDS[word] then hex = SYN.keyword
                elseif prev == ":" then hex = SYN.method
                elseif BUILTINS[word] then hex = SYN.builtin end
                out[#out + 1] = hex and paint(word, hex) or word
                i, prev = i + #word, "a"
            else
                out[#out + 1] = rtEscape(c)
                if not c:match("%s") then prev = c end
                i = i + 1
            end
        end
        return table.concat(out)
    end
end

-- ============================================================
--  UI TOOLKIT
-- ============================================================
local connections = {}
local function connect(signal, fn)
    local c = signal:Connect(fn)
    connections[#connections + 1] = c
    return c
end

-- Theme bindings: anything tied to the accent recolours live from Settings.
local themeBindings = {}
local function bindTheme(obj, prop, key)
    themeBindings[#themeBindings + 1] = { obj = obj, prop = prop, key = key }
    obj[prop] = C[key]
end
local function onTheme(fn)
    themeBindings[#themeBindings + 1] = { fn = fn }
    fn()
end
local function applyTheme()
    for i = #themeBindings, 1, -1 do
        local b = themeBindings[i]
        if b.fn then
            b.fn()
        elseif b.obj.Parent then
            b.obj[b.prop] = C[b.key]
        else
            table.remove(themeBindings, i)
        end
    end
end

-- mk(class, props, children). props.Theme = { Prop = "themeKey" } binds to the theme.
local function mk(cls, props, kids)
    local o = Instance.new(cls)
    local theme
    if props then
        for k, v in pairs(props) do
            if k == "Theme" then theme = v
            elseif k ~= "Parent" then o[k] = v end
        end
    end
    if kids then for _, c in ipairs(kids) do c.Parent = o end end
    if props and props.Parent then o.Parent = props.Parent end
    if theme then for prop, key in pairs(theme) do bindTheme(o, prop, key) end end
    return o
end
local function corner(r) return mk("UICorner", { CornerRadius = UDim.new(0, r or 8) }) end
local function pad(t, r, b, l)
    return mk("UIPadding", {
        PaddingTop = UDim.new(0, t), PaddingRight = UDim.new(0, r or t),
        PaddingBottom = UDim.new(0, b or t), PaddingLeft = UDim.new(0, l or r or t),
    })
end
local function outline(color, thick, transp)
    return mk("UIStroke", {
        Color = color, Thickness = thick or 1, Transparency = transp or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end
local function seq(...)
    local kps = {}
    for i, p in ipairs({ ... }) do kps[i] = ColorSequenceKeypoint.new(p[1], p[2]) end
    return ColorSequence.new(kps)
end
local function nseq(...)
    local kps = {}
    for i, p in ipairs({ ... }) do kps[i] = NumberSequenceKeypoint.new(p[1], p[2]) end
    return NumberSequence.new(kps)
end
local function tween(obj, t, props, style, dir)
    local ok, tw = pcall(function()
        return TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quint,
            dir or Enum.EasingDirection.Out), props)
    end)
    if ok and tw then tw:Play() return tw end
    for k, v in pairs(props) do obj[k] = v end
end

-- Acrylic: every "glass" surface remembers its see-through level.
local glassParts = {}
local function glass(obj, base)
    glassParts[#glassParts + 1] = { obj = obj, base = base }
    obj.BackgroundTransparency = S.acrylic and base or 0
    return obj
end
local function glassLevel(base) return S.acrylic and base or 0 end
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

-- Subtle press feedback for buttons.
local function pressable(btn, dynamic)
    local sc = mk("UIScale", { Parent = btn })
    local link = dynamic and function(sig, fn) sig:Connect(fn) end or connect
    link(btn.MouseButton1Down, function() tween(sc, 0.08, { Scale = 0.96 }) end)
    link(btn.MouseButton1Up, function() tween(sc, 0.14, { Scale = 1 }) end)
    link(btn.MouseLeave, function() tween(sc, 0.14, { Scale = 1 }) end)
    return btn
end

-- ── Icons: drawn from rounded frames, so they always render (no image IDs) ──
local drawIcon
do
    local function iconBar(holder, fills, x, y, w, h, rot, radius)
        local f = mk("Frame", {
            Parent = holder, BorderSizePixel = 0, Size = UDim2.new(0, w, 0, h),
            Position = UDim2.new(0, x, 0, y), Rotation = rot or 0,
        }, { corner(radius or math.floor(math.min(w, h) / 2)) })
        fills[#fills + 1] = f
    end
    local function iconRing(holder, strokes, x, y, d, thick)
        local f = mk("Frame", {
            Parent = holder, BackgroundTransparency = 1,
            Size = UDim2.new(0, d, 0, d), Position = UDim2.new(0, x, 0, y),
        }, { corner(math.floor(d / 2)) })
        strokes[#strokes + 1] = mk("UIStroke", { Parent = f, Thickness = thick or 2 })
    end
    local function iconBox(holder, strokes, x, y, w, h, radius, thick)
        local f = mk("Frame", {
            Parent = holder, BackgroundTransparency = 1,
            Size = UDim2.new(0, w, 0, h), Position = UDim2.new(0, x, 0, y),
        }, { corner(radius or 3) })
        strokes[#strokes + 1] = mk("UIStroke", { Parent = f, Thickness = thick or 1.8 })
    end

    local ICONS = {
        send = function(h, f)                      -- arrow out, up-right
            iconBar(h, f, 3.5, 9, 13, 2, -45)
            iconBar(h, f, 8, 4, 8, 2)
            iconBar(h, f, 14, 4, 2, 8)
        end,
        receive = function(h, f)                   -- arrow in, down-left
            iconBar(h, f, 3.5, 9, 13, 2, -45)
            iconBar(h, f, 4, 14, 8, 2)
            iconBar(h, f, 4, 8, 2, 8)
        end,
        ban = function(h, f, s)
            iconRing(h, s, 3, 3, 14, 2)
            iconBar(h, f, 4, 9, 12, 2, 45)
        end,
        gear = function(h, f, s)                   -- ring + 8 teeth
            iconRing(h, s, 6, 6, 8, 3)
            for i = 0, 7 do
                local a = math.rad(i * 45)
                iconBar(h, f, 10 + 7.5 * math.cos(a) - 2, 10 + 7.5 * math.sin(a) - 2, 4, 4, i * 45, 1)
            end
        end,
        lock = function(h, f, s)                   -- shackle + body
            iconRing(h, s, 6, 2, 8, 2)
            iconBar(h, f, 4, 9, 12, 9, 0, 2)
        end,
        copy = function(h, f, s)                   -- two stacked sheets
            iconBar(h, f, 3, 3, 9, 2)
            iconBar(h, f, 3, 3, 2, 9)
            iconBox(h, s, 8, 8, 9, 9, 2, 1.8)
        end,
        search = function(h, f, s)
            iconRing(h, s, 3, 3, 10, 2)
            iconBar(h, f, 10.5, 13, 6, 2, 45)
        end,
        chevron = function(h, f)                   -- ›
            iconBar(h, f, 6, 6.5, 8, 2.5, 45)
            iconBar(h, f, 6, 11, 8, 2.5, -45)
        end,
        close = function(h, f)
            iconBar(h, f, 4, 9, 12, 2, 45)
            iconBar(h, f, 4, 9, 12, 2, -45)
        end,
        x = function(h, f)
            iconBar(h, f, 5.5, 9, 9, 2, 45)
            iconBar(h, f, 5.5, 9, 9, 2, -45)
        end,
        minimize = function(h, f)
            iconBar(h, f, 4, 9, 12, 2)
        end,
        grip = function(h, f)                      -- resize corner
            iconBar(h, f, 11, 13, 7, 2, -45)
            iconBar(h, f, 6, 11, 14, 2, -45)
        end,
        lens = function(h, f, s)
            iconRing(h, s, 4, 4, 12, 2)
            iconBar(h, f, 8, 8, 4, 4)
        end,
    }

    -- Draws a 20x20 icon centred in `parent`; returns setColor(color3), holder.
    drawIcon = function(name, parent, color, scale)
        local holder = mk("Frame", {
            Name = "Icon", Parent = parent, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 20, 0, 20),
        })
        if scale and scale ~= 1 then mk("UIScale", { Parent = holder, Scale = scale }) end
        local fills, strokes = {}, {}
        ;(ICONS[name] or ICONS.lens)(holder, fills, strokes)
        local function setColor(c)
            for _, x in ipairs(fills) do x.BackgroundColor3 = c end
            for _, x in ipairs(strokes) do x.Color = c end
        end
        setColor(color)
        return setColor, holder
    end
end

-- Logo: gradient tile with a "broadcast" mark (a dot sending two signal arcs).
local function makeLogo(parent, size)
    local s = size / 30
    local tile = mk("Frame", {
        Name = "Logo", Parent = parent, Size = UDim2.new(0, size, 0, size),
        BackgroundColor3 = WHITE, BorderSizePixel = 0,
    }, { corner(math.floor(size * 0.3)) })
    local grad = mk("UIGradient", { Parent = tile, Rotation = 45 })
    onTheme(function() grad.Color = seq({ 0, C.accent }, { 1, C.accent2 }) end)
    -- soft sheen on the top half
    mk("Frame", {
        Parent = tile, BackgroundColor3 = WHITE, BackgroundTransparency = 0.88, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0.5, 0),
    }, {
        corner(math.floor(size * 0.3)),
        mk("UIGradient", { Rotation = 90, Transparency = nseq({ 0, 0 }, { 1, 1 }) }),
    })
    local cx, cy = 10.5 * s, 19.5 * s
    mk("Frame", {
        Parent = tile, BorderSizePixel = 0, BackgroundColor3 = WHITE,
        Size = UDim2.new(0, 5 * s, 0, 5 * s), Position = UDim2.new(0, cx - 2.5 * s, 0, cy - 2.5 * s),
    }, { corner(math.ceil(2.5 * s)) })
    for _, d in ipairs({ 10, 18 }) do
        local ring = mk("Frame", {
            Parent = tile, BackgroundTransparency = 1, Size = UDim2.new(0, d * s, 0, d * s),
            Position = UDim2.new(0, cx - d * s / 2, 0, cy - d * s / 2),
        }, { corner(math.ceil(d * s / 2)) })
        mk("UIStroke", { Parent = ring, Color = WHITE, Thickness = 2.2 * s }, {
            mk("UIGradient", {
                Rotation = -45,
                Transparency = nseq({ 0, 1 }, { 0.64, 1 }, { 0.7, 0 }, { 1, 0 }),
            }),
        })
    end
    return tile
end

-- Soft drop shadow: stacked translucent layers (no image assets needed).
local function shadow(parent, radius, depth)
    for i = depth or 4, 1, -1 do
        mk("Frame", {
            Name = "Shadow", Parent = parent, BackgroundColor3 = BLACK,
            BackgroundTransparency = 0.86 + i * 0.025, BorderSizePixel = 0,
            Position = UDim2.new(0, -i * 3, 0, -i * 3 + 6), Size = UDim2.new(1, i * 6, 1, i * 6),
        }, { corner(radius + i * 3) })
    end
end

local function label(props)
    props.BackgroundTransparency = props.BackgroundTransparency or 1
    props.Font = props.Font or Enum.Font.Gotham
    props.TextColor3 = props.TextColor3 or C.text
    props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    return mk("TextLabel", props)
end

-- ============================================================
--  STATE
-- ============================================================
local rows = {}                -- key -> row
local order, uniqueCount = 0, 0
local selected = nil
local currentTab = CFG.tabs[1].id
local currentPage = "script"
local searchText = ""
local active, paused = true, false
local blur = nil
local blockedKeys = {}
local pinned = nil             -- { kind = "edit" | "history", row, entry }
local generatedText = ""
local unseen = 0
local fitScale = 1
local tabs = {}                -- id -> sidebar tab
local executingOwn = false     -- true while our own Execute button runs a snippet
-- Capture health, shown in Settings > Diagnostics.
local HOOK = {
    namecall = "not installed", fnHooks = 0, seenCalls = 0, seenRemote = 0, captured = 0, actors = 0,
    noMethod = 0, skipped = 0, compat = false, rehooked = false,
}
local setTab, setPage, notify, refreshDiagnostics, repaintSwitches, autoTune  -- forward declarations

local UI = {}   -- every widget lives here (keeps us under Luau's 200-locals limit)

-- ============================================================
--  WINDOW
-- ============================================================
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
local MIN_W, MIN_H = math.min(700, W), math.min(400, H)
local TOP_H, SIDEBAR_W, LIST_W = 54, 176, 252

UI.root = mk("Frame", {
    Name = "Window", Parent = screen, AnchorPoint = Vector2.new(0.5, 0), BackgroundTransparency = 1,
    Size = UDim2.new(0, W, 0, H), Position = UDim2.new(0.5, 0, 0.5, -math.floor(H / 2)),
})
UI.uiScale = mk("UIScale", { Parent = UI.root })
shadow(UI.root, 16, 4)

UI.main = mk("Frame", {
    Name = "Main", Parent = UI.root, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = WHITE,
    BorderSizePixel = 0, Active = true, ClipsDescendants = true,
}, { corner(16) })
glass(UI.main, 0.18)
UI.mainGrad = mk("UIGradient", { Parent = UI.main, Rotation = 90 })
onTheme(function() UI.mainGrad.Color = seq({ 0, C.backgroundTop }, { 1, C.background }) end)
UI.border = mk("UIStroke", {
    Parent = UI.main, Color = WHITE, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
})
UI.borderGrad = mk("UIGradient", {
    Parent = UI.border, Rotation = 35,
    Transparency = nseq({ 0, 0.05 }, { 0.5, 0.8 }, { 1, 0.05 }),
})
onTheme(function() UI.borderGrad.Color = seq({ 0, C.accent }, { 0.5, C.stroke }, { 1, C.accent2 }) end)

-- ── top bar ──
UI.top = mk("Frame", { Name = "TopBar", Parent = UI.main, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, TOP_H) })
UI.logo = makeLogo(UI.top, 34)
UI.logo.Position = UDim2.new(0, 14, 0.5, -17)

UI.titleRow = mk("Frame", {
    Parent = UI.top, BackgroundTransparency = 1, Position = UDim2.new(0, 58, 0, 9), Size = UDim2.new(0, 300, 0, 20),
}, {
    mk("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
    }),
})
label({
    Name = "Title", Parent = UI.titleRow, LayoutOrder = 1, AutomaticSize = Enum.AutomaticSize.X,
    Size = UDim2.new(0, 0, 1, 0), Font = Enum.Font.GothamBlack, TextSize = 17, Text = "SimpleSpy",
})
mk("TextLabel", {
    Name = "Version", Parent = UI.titleRow, LayoutOrder = 2, AutomaticSize = Enum.AutomaticSize.X,
    Size = UDim2.new(0, 0, 0, 18), BackgroundTransparency = 0.82, BorderSizePixel = 0,
    Font = Enum.Font.GothamBold, TextSize = 11, Text = VERSION,
    Theme = { BackgroundColor3 = "accent", TextColor3 = "accent" },
}, { corner(9), pad(0, 7) })
label({
    Name = "Subtitle", Parent = UI.top, Position = UDim2.new(0, 58, 0, 30), Size = UDim2.new(0, 260, 0, 14),
    TextSize = 11, TextColor3 = C.subtext, Text = "Remote inspector",
})

-- Live / Paused pill: one tap pauses all capture.
UI.statusBtn = mk("TextButton", {
    Name = "Status", Parent = UI.top, AutoButtonColor = false, Text = "", AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -86, 0.5, 0), Size = UDim2.new(0, 84, 0, 28),
    BackgroundColor3 = C.incoming, BackgroundTransparency = 0.86, BorderSizePixel = 0,
}, { corner(14), outline(C.incoming, 1, 0.6) })
pressable(UI.statusBtn)
UI.statusDot = mk("Frame", {
    Parent = UI.statusBtn, Size = UDim2.new(0, 8, 0, 8), Position = UDim2.new(0, 13, 0.5, -4),
    BackgroundColor3 = C.incoming, BorderSizePixel = 0,
}, { corner(4) })
UI.statusText = label({
    Parent = UI.statusBtn, Position = UDim2.new(0, 28, 0, 0), Size = UDim2.new(1, -32, 1, 0),
    Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.incoming, Text = "Live",
})

function UI.winBtn(xOff, iconName, danger)
    local b = mk("TextButton", {
        Name = "Win_" .. iconName, Parent = UI.top, AutoButtonColor = false, Text = "", AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, xOff, 0.5, 0), Size = UDim2.new(0, 30, 0, 30),
        BackgroundColor3 = danger and C.danger or C.hover, BackgroundTransparency = 1, BorderSizePixel = 0,
    }, { corner(9) })
    pressable(b)
    local setColor = drawIcon(iconName, b, C.subtext)
    connect(b.MouseEnter, function()
        tween(b, 0.12, { BackgroundTransparency = danger and 0.75 or 0 })
        setColor(danger and C.danger or C.text)
    end)
    connect(b.MouseLeave, function() tween(b, 0.12, { BackgroundTransparency = 1 }); setColor(C.subtext) end)
    return b
end
UI.closeBtn = UI.winBtn(-14, "close", true)
UI.minBtn   = UI.winBtn(-48, "minimize")

-- hairline under the top bar, fading out at both ends
mk("Frame", {
    Parent = UI.main, Position = UDim2.new(0, 0, 0, TOP_H), Size = UDim2.new(1, 0, 0, 1),
    BackgroundColor3 = C.stroke, BorderSizePixel = 0,
}, { mk("UIGradient", { Transparency = nseq({ 0, 1 }, { 0.15, 0 }, { 0.85, 0 }, { 1, 1 }) }) })

-- ── body ──
UI.body = mk("Frame", {
    Name = "Body", Parent = UI.main, BackgroundTransparency = 1,
    Position = UDim2.new(0, 0, 0, TOP_H + 10), Size = UDim2.new(1, 0, 1, -(TOP_H + 10)),
})

function UI.panel(name, x, width, scrolling)
    local f = mk(scrolling and "ScrollingFrame" or "Frame", {
        Name = name, Parent = UI.body, Position = UDim2.new(0, x, 0, 0),
        Size = width, BackgroundColor3 = C.surface, BorderSizePixel = 0,
    }, { corner(14), outline(C.strokeSoft, 1) })
    glass(f, 0.3)
    if not scrolling then
        mk("Frame", {
            Name = "Sheen", Parent = f, BackgroundColor3 = WHITE, BackgroundTransparency = 0.93, BorderSizePixel = 0,
            Position = UDim2.new(0, 16, 0, 0), Size = UDim2.new(1, -32, 0, 1),
        })
    end
    return f
end

-- ── sidebar ──
UI.sidebar = UI.panel("Sidebar", 10, UDim2.new(0, SIDEBAR_W, 1, -10))
UI.tabPill = mk("Frame", {
    Name = "TabPill", Parent = UI.sidebar, Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -16, 0, 40),
    BackgroundColor3 = C.accent, BackgroundTransparency = 0.86, BorderSizePixel = 0,
}, { corner(11) })
UI.tabPillBar = mk("Frame", {
    Parent = UI.tabPill, Position = UDim2.new(0, -8, 0.5, -9), Size = UDim2.new(0, 3, 0, 18),
    BackgroundColor3 = C.accent, BorderSizePixel = 0,
}, { corner(2) })

UI.sidebarFooter = mk("Frame", {
    Parent = UI.sidebar, BackgroundTransparency = 1, Position = UDim2.new(0, 14, 1, -40), Size = UDim2.new(1, -28, 0, 26),
})
label({ Parent = UI.sidebarFooter, Size = UDim2.new(0.45, 0, 1, 0), TextSize = 11, TextColor3 = C.subtext, Text = "Toggle UI" })
mk("TextLabel", {
    Name = "KeyChip", Parent = UI.sidebarFooter, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
    AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 22), BackgroundColor3 = C.background,
    BorderSizePixel = 0, Font = Enum.Font.Code, TextSize = 12, TextColor3 = C.text, Text = tostring(S.toggleKey),
}, { corner(6), outline(C.stroke, 1), pad(0, 8) })

-- ── list panel ──
UI.listPanel = UI.panel("ListPanel", SIDEBAR_W + 18, UDim2.new(0, LIST_W, 1, -10))
UI.listTitle = label({
    Parent = UI.listPanel, Position = UDim2.new(0, 16, 0, 14), Size = UDim2.new(1, -110, 0, 18),
    Font = Enum.Font.GothamBold, TextSize = 15, Text = "",
})
UI.listCount = label({
    Name = "ListCount", Parent = UI.listPanel, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 15),
    Size = UDim2.new(0, 100, 0, 16), TextSize = 11, TextColor3 = C.subtext,
    TextXAlignment = Enum.TextXAlignment.Right, Text = "",
})
UI.searchWrap = mk("Frame", {
    Parent = UI.listPanel, Position = UDim2.new(0, 10, 0, 42), Size = UDim2.new(1, -20, 0, 36),
    BackgroundColor3 = C.background, BorderSizePixel = 0,
}, { corner(10) })
glass(UI.searchWrap, 0.25)
UI.searchStroke = outline(C.strokeSoft, 1)
UI.searchStroke.Parent = UI.searchWrap
UI.searchIcon = mk("Frame", { Parent = UI.searchWrap, BackgroundTransparency = 1, Size = UDim2.new(0, 34, 1, 0) })
UI.setSearchIconColor = drawIcon("search", UI.searchIcon, C.subtext)
UI.searchBox = mk("TextBox", {
    Parent = UI.searchWrap, BackgroundTransparency = 1, Position = UDim2.new(0, 34, 0, 0),
    Size = UDim2.new(1, -66, 1, 0), Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.text,
    Text = "", PlaceholderText = "Search remotes", PlaceholderColor3 = C.muted,
    ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
})
UI.searchClear = mk("TextButton", {
    Name = "SearchClear", Parent = UI.searchWrap, AutoButtonColor = false, Text = "", AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.new(0, 24, 0, 24), BackgroundColor3 = C.hover,
    BackgroundTransparency = 0.3, BorderSizePixel = 0, Visible = false,
}, { corner(12) })
drawIcon("x", UI.searchClear, C.subtext)

UI.list = mk("ScrollingFrame", {
    Name = "List", Parent = UI.listPanel, Position = UDim2.new(0, 0, 0, 86), Size = UDim2.new(1, 0, 1, -86),
    BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.stroke,
    CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
}, {
    mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
    pad(2, 10, 10, 10),
})

UI.empty = mk("Frame", {
    Name = "Empty", Parent = UI.listPanel, BackgroundTransparency = 1,
    Position = UDim2.new(0, 16, 0, 86), Size = UDim2.new(1, -32, 1, -100),
})
UI.emptyCircle = mk("Frame", {
    Parent = UI.empty, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.18, 0),
    Size = UDim2.new(0, 56, 0, 56), BackgroundColor3 = C.accent, BackgroundTransparency = 0.88, BorderSizePixel = 0,
}, { corner(28) })
UI.emptyTitle = mk("TextLabel", {
    Parent = UI.empty, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0.18, 68), Size = UDim2.new(1, 0, 0, 18),
    Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = C.text, Text = "",
})
UI.emptyText = mk("TextLabel", {
    Parent = UI.empty, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0.18, 90), Size = UDim2.new(1, 0, 0, 34),
    Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.subtext, TextWrapped = true, Text = "",
})

-- ── detail panel ──
UI.detail = UI.panel("Detail", SIDEBAR_W + LIST_W + 26, UDim2.new(1, -(SIDEBAR_W + LIST_W + 36), 1, -10))

UI.placeholder = mk("Frame", { Name = "Placeholder", Parent = UI.detail, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0) })
UI.phLogo = makeLogo(UI.placeholder, 46)
UI.phLogo.AnchorPoint = Vector2.new(0.5, 0)
UI.phLogo.Position = UDim2.new(0.5, 0, 0.3, 0)
mk("TextLabel", {
    Parent = UI.placeholder, BackgroundTransparency = 1, Position = UDim2.new(0, 20, 0.3, 60), Size = UDim2.new(1, -40, 0, 20),
    Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = C.text, Text = "Select a remote",
})
mk("TextLabel", {
    Parent = UI.placeholder, BackgroundTransparency = 1, Position = UDim2.new(0, 30, 0.3, 84), Size = UDim2.new(1, -60, 0, 34),
    Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.subtext, TextWrapped = true,
    Text = "Pick any call on the left to see its script, arguments and history.",
})

UI.inspector = mk("Frame", { Name = "Inspector", Parent = UI.detail, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Visible = false })
UI.dBadge = mk("Frame", {
    Parent = UI.inspector, Position = UDim2.new(0, 16, 0, 16), Size = UDim2.new(0, 44, 0, 44),
    BackgroundColor3 = C.remoteEvent, BackgroundTransparency = 0.84, BorderSizePixel = 0,
}, { corner(13) })
UI.dBadgeText = mk("TextLabel", {
    Parent = UI.dBadge, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
    Font = Enum.Font.GothamBlack, TextSize = 17, TextColor3 = C.remoteEvent, Text = "",
})
UI.dName = label({
    Name = "DetailName", Parent = UI.inspector, Position = UDim2.new(0, 72, 0, 14), Size = UDim2.new(1, -196, 0, 22),
    Font = Enum.Font.GothamBold, TextSize = 17, TextTruncate = Enum.TextTruncate.AtEnd, Text = "",
})
UI.dMeta = label({
    Name = "DetailMeta", Parent = UI.inspector, Position = UDim2.new(0, 72, 0, 39), Size = UDim2.new(1, -190, 0, 16),
    TextSize = 11, TextColor3 = C.subtext, TextTruncate = Enum.TextTruncate.AtEnd, Text = "",
})
UI.dFrom = label({
    Name = "DetailFrom", Parent = UI.inspector, Position = UDim2.new(0, 72, 0, 60), Size = UDim2.new(1, -88, 0, 14),
    TextSize = 11, TextColor3 = C.muted, TextTruncate = Enum.TextTruncate.AtEnd, Text = "",
})
UI.chips = mk("Frame", {
    Parent = UI.inspector, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 37),
    Size = UDim2.new(0, 160, 0, 22), BackgroundTransparency = 1,
}, {
    mk("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
    }),
})
UI.dRate = mk("TextLabel", {
    Name = "Rate", Parent = UI.chips, LayoutOrder = 1, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0),
    BackgroundColor3 = C.hover, BackgroundTransparency = 0.2, BorderSizePixel = 0,
    Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = C.subtext, Text = "idle",
}, { corner(11), pad(0, 8) })
UI.dCount = mk("TextLabel", {
    Name = "Count", Parent = UI.chips, LayoutOrder = 2, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0),
    BackgroundColor3 = C.counter, BackgroundTransparency = 0.84, BorderSizePixel = 0,
    Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = C.counter, Text = "x0",
}, { corner(11), pad(0, 8) })

-- icon tools: copy path, ignore, block
UI.tools = mk("Frame", {
    Parent = UI.inspector, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 10),
    Size = UDim2.new(0, 104, 0, 30), BackgroundTransparency = 1,
}, {
    mk("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
    }),
})
function UI.toolBtn(order, name, icon)
    local b = mk("TextButton", {
        Name = name, Parent = UI.tools, LayoutOrder = order, AutoButtonColor = false, Text = "",
        Size = UDim2.new(0, 30, 0, 30), BackgroundColor3 = C.hover, BackgroundTransparency = 0.4, BorderSizePixel = 0,
    }, { corner(9) })
    pressable(b)
    local setColor = drawIcon(icon, b, C.subtext)
    return b, setColor
end
UI.pathBtn          = UI.toolBtn(1, "CopyPath", "copy")
UI.ignoreBtn, UI.setIgnoreColor = UI.toolBtn(2, "Ignore", "ban")
UI.blockBtn, UI.setBlockColor   = UI.toolBtn(3, "Block", "lock")

-- segmented control: Script | Arguments | History
local SEGS = { { id = "script", title = "Script" }, { id = "args", title = "Arguments" }, { id = "history", title = "History" } }
local SEG_W = 86
UI.seg = mk("Frame", {
    Name = "Segments", Parent = UI.inspector, Position = UDim2.new(0, 16, 0, 86),
    Size = UDim2.new(0, SEG_W * #SEGS + 4, 0, 32), BackgroundColor3 = C.background, BorderSizePixel = 0,
}, { corner(10), outline(C.strokeSoft, 1) })
glass(UI.seg, 0.25)
UI.segPill = mk("Frame", {
    Parent = UI.seg, Position = UDim2.new(0, 2, 0, 2), Size = UDim2.new(0, SEG_W, 1, -4),
    BackgroundColor3 = C.hover, BorderSizePixel = 0,
}, { corner(8), outline(C.stroke, 1, 0.4) })
UI.segButtons = {}
for i, sDef in ipairs(SEGS) do
    UI.segButtons[i] = mk("TextButton", {
        Name = "Seg_" .. sDef.id, Parent = UI.seg, AutoButtonColor = false, BackgroundTransparency = 1,
        Position = UDim2.new(0, 2 + (i - 1) * SEG_W, 0, 2), Size = UDim2.new(0, SEG_W, 1, -4),
        Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = C.subtext, Text = sDef.title,
    })
end
UI.pages = mk("Frame", {
    Name = "Pages", Parent = UI.inspector, BackgroundTransparency = 1,
    Position = UDim2.new(0, 16, 0, 128), Size = UDim2.new(1, -32, 1, -(128 + 62)),
})

-- Script page
UI.scriptPage = mk("Frame", { Name = "ScriptPage", Parent = UI.pages, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0) })
UI.codeWrap = mk("Frame", {
    Parent = UI.scriptPage, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = C.background, BorderSizePixel = 0,
}, { corner(12), outline(C.strokeSoft, 1) })
glass(UI.codeWrap, 0.2)
UI.codeScroll = mk("ScrollingFrame", {
    Parent = UI.codeWrap, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0),
    ScrollBarThickness = 4, ScrollBarImageColor3 = C.stroke, CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
    ClipsDescendants = true,
}, { pad(12) })
UI.codeView = mk("TextButton", {
    Name = "CodeView", Parent = UI.codeScroll, AutoButtonColor = false, BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, RichText = true,
    Font = Enum.Font.Code, TextSize = 13, TextColor3 = hexColor(SYN.text, DEFAULTS.syntax.text),
    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    Text = "",
})
UI.codeBox = mk("TextBox", {
    Name = "CodeBox", Parent = UI.codeScroll, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y, Font = Enum.Font.Code, TextSize = 13, TextColor3 = C.text,
    MultiLine = true, ClearTextOnFocus = false, TextWrapped = true, TextEditable = true,
    TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    Text = "", Visible = false,
})
UI.pinChip = mk("TextButton", {
    Name = "PinChip", Parent = UI.codeWrap, AutoButtonColor = false, AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -10, 1, -10), AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 24),
    BackgroundTransparency = 0.8, BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 11,
    Text = "", Visible = false, Theme = { BackgroundColor3 = "accent", TextColor3 = "accent" },
}, { corner(12), pad(0, 10) })
UI.editHint = mk("TextLabel", {
    Name = "EditHint", Parent = UI.codeWrap, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -10, 1, -10),
    AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 22), BackgroundColor3 = C.surfaceAlt,
    BackgroundTransparency = 0.08, BorderSizePixel = 0, Font = Enum.Font.GothamMedium, TextSize = 10,
    TextColor3 = C.subtext, Text = "Tap code to edit",
}, { corner(11), outline(C.stroke, 1), pad(0, 9) })

-- Arguments page
function UI.listPage(name)
    return mk("ScrollingFrame", {
        Name = name, Parent = UI.pages, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0),
        ScrollBarThickness = 3, ScrollBarImageColor3 = C.stroke, CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, Visible = false,
    }, { mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })
end
UI.argsPage = UI.listPage("ArgsPage")
UI.argsEmpty = mk("TextLabel", {
    Parent = UI.argsPage, LayoutOrder = 999, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40),
    Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.subtext, Text = "This call has no arguments.", Visible = false,
})
UI.argsMore = mk("TextLabel", {
    Parent = UI.argsPage, LayoutOrder = 998, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24),
    Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.subtext, Text = "", Visible = false,
})
local ARG_POOL = 24
UI.argSlots = {}
for i = 1, ARG_POOL do
    local f = mk("Frame", {
        Name = "Arg", Parent = UI.argsPage, LayoutOrder = i, Size = UDim2.new(1, -4, 0, 36),
        BackgroundColor3 = C.surfaceAlt, BorderSizePixel = 0, Visible = false,
    }, { corner(9) })
    glass(f, 0.25)
    local idx = mk("TextLabel", {
        Parent = f, Position = UDim2.new(0, 8, 0.5, -11), Size = UDim2.new(0, 22, 0, 22),
        BackgroundColor3 = C.background, BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 11,
        TextColor3 = C.subtext, Text = tostring(i),
    }, { corner(6) })
    local tpill = mk("TextLabel", {
        Name = "TypePill", Parent = f, Position = UDim2.new(0, 38, 0.5, -10), AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 0, 20), BackgroundTransparency = 0.84, BorderSizePixel = 0,
        Font = Enum.Font.GothamBold, TextSize = 10, Text = "",
    }, { corner(10), pad(0, 7) })
    local val = label({
        Name = "Value", Parent = f, Position = UDim2.new(0, 120, 0, 0), Size = UDim2.new(1, -128, 1, 0),
        Font = Enum.Font.Code, TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd, Text = "",
    })
    UI.argSlots[i] = { frame = f, index = idx, typePill = tpill, value = val }
end

-- History page
UI.historyPage = UI.listPage("HistoryPage")
local HIST_POOL = 30
UI.histSlots = {}

-- action bar
UI.actions = mk("Frame", {
    Parent = UI.inspector, BackgroundTransparency = 1, Position = UDim2.new(0, 16, 1, -54),
    Size = UDim2.new(1, -32, 0, 40),
})
function UI.actionBtn(name, x, w, primary, iconName, text)
    local b = mk("TextButton", {
        Name = name, Parent = UI.actions, AutoButtonColor = false, Text = "", Position = x, Size = w,
        BackgroundColor3 = primary and WHITE or C.surfaceAlt, BorderSizePixel = 0,
    }, { corner(11) })
    if primary then
        local g = mk("UIGradient", { Parent = b, Rotation = 0 })
        onTheme(function() g.Color = seq({ 0, C.accent }, { 1, C.accent2 }) end)
    else
        outline(C.stroke, 1).Parent = b
        glass(b, 0.2)
    end
    pressable(b)
    local content = mk("Frame", { Parent = b, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0) }, {
        mk("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })
    local iconHolder = mk("Frame", { Parent = content, LayoutOrder = 1, BackgroundTransparency = 1, Size = UDim2.new(0, 20, 0, 20) })
    drawIcon(iconName, iconHolder, primary and WHITE or C.text)
    local t = mk("TextLabel", {
        Name = "Label", Parent = content, LayoutOrder = 2, BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 1, 0), Font = Enum.Font.GothamBold, TextSize = 13,
        TextColor3 = primary and WHITE or C.text, Text = text,
    })
    return b, t
end
UI.copyBtn, UI.copyLabel = UI.actionBtn("Copy", UDim2.new(0, 0, 0, 0), UDim2.new(0.4, -5, 1, 0), false, "copy", "Copy")
UI.runBtn, UI.runLabel   = UI.actionBtn("Execute", UDim2.new(0.4, 5, 0, 0), UDim2.new(0.6, -5, 1, 0), true, "chevron", "Execute")

-- ── settings page ──
UI.settingsPanel = UI.panel("SettingsPanel", SIDEBAR_W + 18, UDim2.new(1, -(SIDEBAR_W + 28), 1, -10), true)
UI.settingsPanel.Visible = false
UI.settingsPanel.ScrollBarThickness = 3
UI.settingsPanel.ScrollBarImageColor3 = C.stroke
UI.settingsPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
UI.settingsPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y
UI.settingsPanel.ScrollingDirection = Enum.ScrollingDirection.Y
mk("UIListLayout", { Parent = UI.settingsPanel, Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder })
pad(18, 18, 18, 18).Parent = UI.settingsPanel

-- ── toasts (top-centre of the screen) ──
UI.toastLayer = mk("Frame", {
    Name = "Toasts", Parent = screen, AnchorPoint = Vector2.new(0.5, 0), BackgroundTransparency = 1,
    Position = UDim2.new(0.5, 0, 0, 64), Size = UDim2.new(0, 460, 0, 200),
}, {
    mk("UIListLayout", {
        HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }),
})

-- ── floating dock: reopens the window (the only way on mobile) ──
UI.dock = mk("TextButton", {
    Name = "Dock", Parent = screen, AutoButtonColor = false, Text = "",
    Size = UDim2.new(0, 54, 0, 54), Position = UDim2.new(0, 18, 0.5, -27),
    BackgroundColor3 = C.surface, BorderSizePixel = 0, Visible = false,
}, { corner(17) })
glass(UI.dock, 0.12)
shadow(UI.dock, 17, 3)
UI.dockStroke = mk("UIStroke", { Parent = UI.dock, Color = WHITE, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
UI.dockStrokeGrad = mk("UIGradient", { Parent = UI.dockStroke, Rotation = 45 })
onTheme(function() UI.dockStrokeGrad.Color = seq({ 0, C.accent }, { 1, C.accent2 }) end)
UI.dockLogo = makeLogo(UI.dock, 34)
UI.dockLogo.AnchorPoint = Vector2.new(0.5, 0.5)
UI.dockLogo.Position = UDim2.new(0.5, 0, 0.5, 0)
UI.dockBadge = mk("TextLabel", {
    Name = "Unseen", Parent = UI.dock, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 6, 0, -6),
    AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 20), BackgroundColor3 = C.danger,
    BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = WHITE, Text = "0", Visible = false,
}, { corner(10), pad(0, 6) })

-- ── resize grip ──
UI.grip = mk("TextButton", {
    Name = "Grip", Parent = UI.root, AutoButtonColor = false, Text = "", AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -4, 1, -4), Size = UDim2.new(0, 22, 0, 22), BackgroundTransparency = 1,
})
drawIcon("grip", UI.grip, C.muted)

-- ============================================================
--  TOASTS / NOTIFY
-- ============================================================
local toasts = {}
local toastSeq = 0
notify = function(text, kind)
    print("[SimpleSpy] " .. text)
    if not UI.toastLayer.Parent then return end
    local col = (kind == "success" and C.incoming) or (kind == "error" and C.danger)
             or (kind == "warn" and C.warning) or C.accent
    if #text > 96 then text = text:sub(1, 96) .. "…" end
    toastSeq = toastSeq + 1
    local t = mk("Frame", {
        Name = "Toast", Parent = UI.toastLayer, LayoutOrder = toastSeq, AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 0, 38), BackgroundColor3 = C.surfaceAlt, BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
    }, {
        corner(12), outline(C.stroke, 1), pad(0, 16, 0, 14),
        mk("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })
    mk("Frame", { Parent = t, LayoutOrder = 1, Size = UDim2.new(0, 8, 0, 8), BackgroundColor3 = col, BorderSizePixel = 0 }, { corner(4) })
    mk("TextLabel", {
        Name = "Text", Parent = t, LayoutOrder = 2, BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 1, 0), Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.text, Text = text,
    })
    local sc = mk("UIScale", { Parent = t, Scale = 0.9 })
    tween(sc, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
    toasts[#toasts + 1] = t
    while #toasts > 3 do
        local old = table.remove(toasts, 1)
        pcall(function() old:Destroy() end)
    end
    task.delay(2.6, function()
        for i, x in ipairs(toasts) do if x == t then table.remove(toasts, i) break end end
        pcall(function() t:Destroy() end)
    end)
end

-- ============================================================
--  HELPERS
-- ============================================================
local CLASS = {
    RemoteEvent           = { letter = "E", key = "remoteEvent" },
    RemoteFunction        = { letter = "F", key = "remoteFunction" },
    UnreliableRemoteEvent = { letter = "U", key = "unreliableEvent" },
}
local function classInfo(cn)
    local ci = CLASS[cn]
    if ci then return ci.letter, C[ci.key] end
    return "?", C.subtext
end
local TYPE_KEY = {
    string = "incoming", number = "warning", boolean = "remoteFunction", ["nil"] = "muted",
    table = "accent2", Instance = "remoteEvent",
}
local function typeColor(t) return C[TYPE_KEY[t] or "unreliableEvent"] end

local function fmtCount(n)
    if n >= 1e6 then return ("x%.1fm"):format(n / 1e6) end
    if n >= 1000 then return ("x%.1fk"):format(n / 1000) end
    return "x" .. n
end
local function ago(sec)
    if sec < 1 then return ("%.1fs ago"):format(math.max(sec, 0)) end
    if sec < 60 then return ("%ds ago"):format(math.floor(sec)) end
    return ("%dm ago"):format(math.floor(sec / 60))
end
local function rowSub(r)
    if r.incoming then return "OnClientEvent  ·  from server" end
    return ":" .. r.method .. "()" .. (r.srcShort and ("  ·  " .. r.srcShort) or "")
end
local function argsPreview(e)
    if not e or e.argCount == 0 then return "(no arguments)" end
    local parts = {}
    for i = 1, math.min(e.argCount, 3) do parts[i] = preview(e.args[i], 1) end
    if e.argCount > 3 then parts[#parts + 1] = "…" end
    return table.concat(parts, ", ")
end

local function saveSettings()
    if not (S.saveSettings and writefile_fn) then return end
    pcall(function()
        local data = { accent = S.accentIndex, width = W, height = H }
        for _, k in ipairs(SAVED_KEYS) do data[k] = S[k] end
        writefile_fn(SAVE_FILE, HttpService:JSONEncode(data))
    end)
end

local function updateCounts()
    local n = { out = 0, ["in"] = 0, ignored = 0 }
    for _, r in pairs(rows) do
        if r.ignored then n.ignored = n.ignored + 1
        elseif r.incoming then n["in"] = n["in"] + 1
        else n.out = n.out + 1 end
    end
    for id, t in pairs(tabs) do
        if t.badge then
            local c = n[id] or 0
            t.badge.Visible = c > 0
            t.badge.Text = c > 999 and "999+" or tostring(c)
        end
    end
    local c = n[currentTab]
    UI.listCount.Text = c and (c .. (c == 1 and " remote" or " remotes")) or ""
end

local function updateDockBadge()
    UI.dockBadge.Visible = unseen > 0
    UI.dockBadge.Text = unseen > 99 and "99+" or tostring(unseen)
end

-- ============================================================
--  CODE VIEW
-- ============================================================
local function setCode(text, generated)
    UI.codeBox.Text = text
    UI.codeView.Text = highlight(text)
    if generated then generatedText = text end
end

local function entryCode(r, e)
    return buildScript(r.remote, r.method, e and e.args or {}, e and e.argCount or 0, e and e.retText, e and e.src)
end

local function buildCode(r)
    r.code = entryCode(r, r.latest)
    r.dirty = false
end

local function currentEntry(r)
    if pinned and pinned.kind == "history" and pinned.row == r then return pinned.entry end
    return r.latest
end

local function updatePinChip()
    if pinned and pinned.kind == "history" then
        UI.pinChip.Text = ("Call #%d  ·  Back to latest"):format(pinned.entry.n)
        UI.pinChip.Visible = true
    elseif pinned and pinned.kind == "edit" then
        UI.pinChip.Text = "Edited  ·  Reset"
        UI.pinChip.Visible = true
    else
        UI.pinChip.Visible = false
    end
    UI.editHint.Visible = not UI.pinChip.Visible
end

-- ============================================================
--  ARGUMENTS + HISTORY PAGES
-- ============================================================
local function renderArgs(e)
    local n = e and e.argCount or 0
    for i = 1, ARG_POOL do
        local slot = UI.argSlots[i]
        if i <= n then
            local v = e.args[i]
            local t = typeof(v)
            local col = typeColor(t)
            slot.typePill.Text = (t == "Instance") and v.ClassName or t
            slot.typePill.TextColor3 = col
            slot.typePill.BackgroundColor3 = col
            slot.value.Text = preview(v)
            slot.frame.Visible = true
        else
            slot.frame.Visible = false
        end
    end
    UI.argsEmpty.Visible = (n == 0)
    UI.argsMore.Visible = n > ARG_POOL
    UI.argsMore.Text = n > ARG_POOL and ("+%d more arguments (see Script)"):format(n - ARG_POOL) or ""
end

local function renderHistory(r)
    local h = r and r.history or {}
    local now = os.clock()
    for i = 1, HIST_POOL do
        local slot = UI.histSlots[i]
        local e = h[#h - i + 1]
        slot.entry = e
        if e then
            slot.num.Text = "#" .. e.n
            slot.age.Text = ago(now - e.t) .. (e.blocked and "  ·  blocked" or "")
            slot.preview.Text = argsPreview(e)
            slot.stroke.Transparency = (pinned and pinned.kind == "history" and pinned.entry == e) and 0 or 1
            slot.frame.Visible = true
        else
            slot.frame.Visible = false
        end
    end
end

-- ============================================================
--  DETAIL + SELECTION
-- ============================================================
local function refreshMeta(r)
    if not r then return end
    local letter, color = classInfo(r.className)
    local live = r.lastTime and (os.clock() - r.lastTime) < 2
    UI.dRate.Text = live and ("%.1f/s"):format(r.rate or 0) or "idle"
    UI.dRate.TextColor3 = live and C.incoming or C.subtext
    UI.dCount.Text = fmtCount(r.count)
    UI.dMeta.Text = r.className .. "  ·  " .. (r.incoming and "OnClientEvent  ·  server -> you" or (":" .. r.method .. "()"))
    if r.incoming then
        UI.dFrom.Text = "Sent by the server"
    elseif r.srcShort then
        local parent = (r.src and #r.src > #r.srcShort) and r.src:sub(1, #r.src - #r.srcShort - 1) or nil
        UI.dFrom.Text = "from " .. r.srcShort .. (parent and ("  ·  " .. parent) or "")
    else
        UI.dFrom.Text = "Calling script unknown"
    end
    UI.dBadge.BackgroundColor3 = color
    UI.dBadgeText.TextColor3 = color
    UI.dBadgeText.Text = letter
end

local function refreshTools(r)
    UI.setIgnoreColor(r.ignored and C.danger or C.subtext)
    UI.ignoreBtn.BackgroundColor3 = r.ignored and C.danger or C.hover
    UI.ignoreBtn.BackgroundTransparency = r.ignored and 0.82 or 0.4
    local blocked = blockedKeys[r.key] == true
    UI.setBlockColor(blocked and C.warning or (r.incoming and C.muted or C.subtext))
    UI.blockBtn.BackgroundColor3 = blocked and C.warning or C.hover
    UI.blockBtn.BackgroundTransparency = blocked and 0.82 or 0.4
    UI.runBtn.BackgroundTransparency = r.incoming and 0.65 or 0
    UI.runLabel.Text = "Execute"
end

local function showDetail(r)
    UI.placeholder.Visible = (r == nil)
    UI.inspector.Visible = (r ~= nil)
    if not r then return end
    UI.dName.Text = r.name
    refreshMeta(r)
    refreshTools(r)
end

local function refreshPages(r)
    if currentPage == "args" then renderArgs(currentEntry(r))
    elseif currentPage == "history" then renderHistory(r) end
end

local function selectRow(key)
    local old = selected and rows[selected]
    if old then
        old.selStroke.Transparency = 1
        old.button.BackgroundColor3 = C.surfaceAlt
    end
    selected = key
    pinned = nil
    updatePinChip()
    local r = key and rows[key] or nil
    if r then
        r.selStroke.Transparency = 0
        r.button.BackgroundColor3 = C.hover
        if r.dirty then buildCode(r) end
        setCode(r.code, true)
        UI.codeBox.Visible, UI.codeView.Visible = false, true
        UI.codeScroll.CanvasPosition = Vector2.new(0, 0)
        refreshPages(r)
    end
    showDetail(r)
end

local refreshPending = false
local function refreshSelected()
    refreshPending = false
    local r = selected and rows[selected]
    if not r then return end
    refreshMeta(r)
    if not pinned and not UI.codeBox:IsFocused() and r.dirty then
        buildCode(r)
        setCode(r.code, true)
    end
    refreshPages(r)
end
local function scheduleRefresh()
    if refreshPending then return end
    refreshPending = true
    task.delay(0.25, refreshSelected)
end

-- ============================================================
--  FILTERING
-- ============================================================
local EMPTY = {
    out     = { "No outgoing remotes yet", "Do something in-game. Nothing showing? Open Settings > Diagnostics.", "send", "accent" },
    ["in"]  = { "No incoming remotes yet", "They appear when the server fires to you.", "receive", "incoming" },
    ignored = { "Nothing ignored", "Select a remote and tap Ignore to park it here.", "ban", "danger" },
}
local emptyIconHolder
local function setEmptyState(tabId, searching)
    local e = EMPTY[tabId] or EMPTY.out
    if searching then
        UI.emptyTitle.Text = "No matches"
        UI.emptyText.Text = ('Nothing matches "%s".'):format(UI.searchBox.Text)
    else
        UI.emptyTitle.Text, UI.emptyText.Text = e[1], e[2]
    end
    if emptyIconHolder then emptyIconHolder:Destroy() end
    local col = C[e[4]] or C.accent
    UI.emptyCircle.BackgroundColor3 = col
    local _, holder = drawIcon(searching and "search" or e[3], UI.emptyCircle, col, 1.2)
    emptyIconHolder = holder
end

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
    UI.empty.Visible = (n == 0)
    if n == 0 then setEmptyState(currentTab, searchText ~= "") end
    if selected and rows[selected] and not rows[selected].button.Visible then selectRow(nil) end
    updateCounts()
end

-- ============================================================
--  ROWS + RECORDING
-- ============================================================
local function pulse(r, now)
    if now - (r.lastPulse or -1) < 0.15 then return end
    r.lastPulse = now
    r.pulseDot.BackgroundTransparency = 0
    tween(r.pulseDot, 0.9, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad)
end

local function makeRow(key, remote, method)
    order = order + 1
    local incoming = (method == "OnClientEvent")
    local cn = remote.ClassName
    local letter, color = classInfo(cn)

    local btn = mk("TextButton", {
        Name = "Row", Parent = UI.list, LayoutOrder = -order, AutoButtonColor = false, Text = "",
        Size = UDim2.new(1, 0, 0, 56), BackgroundColor3 = C.surfaceAlt, BorderSizePixel = 0,
    }, { corner(11) })
    glass(btn, 0.28)
    btn.BackgroundTransparency = 1
    tween(btn, 0.3, { BackgroundTransparency = glassLevel(0.28) })
    local selStroke = mk("UIStroke", {
        Parent = btn, Thickness = 1.5, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Theme = { Color = "accent" },
    })
    local badge = mk("Frame", {
        Parent = btn, Position = UDim2.new(0, 10, 0.5, -17), Size = UDim2.new(0, 34, 0, 34),
        BackgroundColor3 = color, BackgroundTransparency = 0.84, BorderSizePixel = 0,
    }, { corner(10) })
    mk("TextLabel", {
        Parent = badge, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBlack, TextSize = 14, TextColor3 = color, Text = letter,
    })
    local pulseDot = mk("Frame", {
        Name = "Pulse", Parent = badge, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -2, 0, 2),
        Size = UDim2.new(0, 9, 0, 9), BackgroundColor3 = C.incoming, BackgroundTransparency = 1, BorderSizePixel = 0,
    }, { corner(5) })
    mk("TextLabel", {
        Name = "RowName", Parent = btn, BackgroundTransparency = 1, Position = UDim2.new(0, 54, 0, 10),
        Size = UDim2.new(1, -110, 0, 18), Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.text,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = remote.Name,
    })
    local subL = mk("TextLabel", {
        Name = "RowSub", Parent = btn, BackgroundTransparency = 1, Position = UDim2.new(0, 54, 0, 29), Size = UDim2.new(1, -62, 0, 15),
        Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.subtext, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, Text = "",
    })
    local countL = mk("TextLabel", {
        Name = "RowCount", Parent = btn, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10),
        AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 18), BackgroundColor3 = C.counter,
        BackgroundTransparency = 0.85, BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 11,
        TextColor3 = C.counter, Text = "x0",
    }, { corner(9), pad(0, 7) })
    local blockChip = mk("TextLabel", {
        Name = "BlockedChip", Parent = btn, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 31),
        AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 16), BackgroundColor3 = C.warning,
        BackgroundTransparency = 0.82, BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 9,
        TextColor3 = C.warning, Text = "BLOCKED", Visible = false,
    }, { corner(8), pad(0, 6) })

    local r = {
        key = key, remote = remote, method = method, incoming = incoming, className = cn,
        name = remote.Name, count = 0, code = "", dirty = true, ignored = false, history = {},
        button = btn, selStroke = selStroke, subLabel = subL, countLabel = countL,
        pulseDot = pulseDot, blockChip = blockChip,
    }
    rows[key] = r
    uniqueCount = uniqueCount + 1
    subL.Text = rowSub(r)
    btn.MouseButton1Click:Connect(function() selectRow(key) end)
    btn.MouseEnter:Connect(function() if selected ~= key then btn.BackgroundColor3 = C.hover end end)
    btn.MouseLeave:Connect(function() if selected ~= key then btn.BackgroundColor3 = C.surfaceAlt end end)
    pressable(btn, true)

    local vis = rowVisible(r)
    btn.Visible = vis
    if vis then UI.empty.Visible = false end
    if not UI.root.Visible then
        unseen = unseen + 1
        updateDockBadge()
    end
    updateCounts()
    return r
end

local function record(key, remote, method, args, argCount, retText, src, wasBlocked)
    if paused then return end
    local r = rows[key]
    if r and r.ignored then return end
    if not r then
        if uniqueCount >= S.maxRows then return end
        r = makeRow(key, remote, method)
    end

    local now = os.clock()
    if not r.incoming then HOOK.captured = HOOK.captured + 1 end
    r.count = r.count + 1
    r.countLabel.Text = fmtCount(r.count)
    if not r.winStart then r.winStart, r.winCount = now, 0 end
    r.winCount = r.winCount + 1
    if now - r.winStart >= 1 then
        r.rate = r.winCount / (now - r.winStart)
        r.winStart, r.winCount = now, 0
    elseif not r.rate then
        r.rate = r.winCount
    end
    r.lastTime = now

    local srcPath = src and scriptName(src) or nil
    if srcPath and srcPath ~= r.src then
        r.src = srcPath
        r.srcShort = srcPath:match("[^%.]+$") or srcPath
        r.subLabel.Text = rowSub(r)
    end

    local e = {
        n = r.count, t = now, args = args, argCount = argCount, retText = retText,
        src = r.src, blocked = wasBlocked,
    }
    r.latest = e
    local h = r.history
    h[#h + 1] = e
    if #h > S.historySize then table.remove(h, 1) end
    r.dirty = true
    pulse(r, now)

    if selected == key then
        UI.dCount.Text = fmtCount(r.count)
        scheduleRefresh()
    elseif selected == nil and r.button.Visible then
        selectRow(key)
    end
end

-- history slots
for i = 1, HIST_POOL do
    local f = mk("TextButton", {
        Name = "HistoryItem", Parent = UI.historyPage, LayoutOrder = i, AutoButtonColor = false, Text = "",
        Size = UDim2.new(1, -4, 0, 44), BackgroundColor3 = C.surfaceAlt, BorderSizePixel = 0, Visible = false,
    }, { corner(9) })
    glass(f, 0.25)
    local st = mk("UIStroke", {
        Parent = f, Thickness = 1.5, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Theme = { Color = "accent" },
    })
    local num = label({ Name = "Num", Parent = f, Position = UDim2.new(0, 12, 0, 7), Size = UDim2.new(0, 70, 0, 16), Font = Enum.Font.GothamBold, TextSize = 12, Text = "" })
    local age = label({ Name = "Age", Parent = f, Position = UDim2.new(0, 12, 0, 24), Size = UDim2.new(0, 120, 0, 14), TextSize = 10, TextColor3 = C.subtext, Text = "" })
    local prev = label({
        Name = "Preview", Parent = f, Position = UDim2.new(0, 110, 0, 0), Size = UDim2.new(1, -122, 1, 0), Font = Enum.Font.Code,
        TextSize = 11, TextColor3 = C.subtext, TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd, Text = "",
    })
    local slot = { frame = f, num = num, age = age, preview = prev, stroke = st }
    UI.histSlots[i] = slot
    pressable(f)
    connect(f.MouseButton1Click, function()
        local r = selected and rows[selected]
        if not (r and slot.entry) then return end
        pinned = { kind = "history", row = r, entry = slot.entry }
        setCode(entryCode(r, slot.entry), true)
        updatePinChip()
        setPage("script")
    end)
end

-- ============================================================
--  SIDEBAR TABS  (built from the JSON "tabs" list)
-- ============================================================
do
    local y, lastGroup = 14, nil
    for i, t in ipairs(CFG.tabs) do
        local group = (t.id == "settings") and "APP" or "TRAFFIC"
        if group ~= lastGroup then
            if lastGroup then y = y + 8 end
            label({
                Name = "Section", Parent = UI.sidebar, Position = UDim2.new(0, 18, 0, y), Size = UDim2.new(1, -36, 0, 14),
                Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = C.muted, Text = group,
            })
            y = y + 22
            lastGroup = group
        end
        local b = mk("TextButton", {
            Name = "Tab_" .. t.id, Parent = UI.sidebar, LayoutOrder = i, AutoButtonColor = false, Text = "",
            Position = UDim2.new(0, 8, 0, y), Size = UDim2.new(1, -16, 0, 40),
            BackgroundColor3 = C.hover, BackgroundTransparency = 1, BorderSizePixel = 0,
        }, { corner(11) })
        pressable(b)
        local iconHolder = mk("Frame", {
            Parent = b, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0.5, -10), Size = UDim2.new(0, 20, 0, 20),
        })
        local setColor = drawIcon(t.icon, iconHolder, C.subtext)
        local lbl = label({
            Name = "TabLabel", Parent = b, Position = UDim2.new(0, 39, 0, 0), Size = UDim2.new(1, -78, 1, 0),
            Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.subtext,
            TextTruncate = Enum.TextTruncate.AtEnd, Text = t.title,
        })
        local badge
        if t.id ~= "settings" then
            badge = mk("TextLabel", {
                Name = "Count", Parent = b, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -9, 0.5, 0),
                AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 18), BackgroundTransparency = 0.85,
                BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 11, Text = "0", Visible = false,
                Theme = { BackgroundColor3 = t.color, TextColor3 = t.color },
            }, { corner(9), pad(0, 6) })
        end
        tabs[t.id] = { button = b, setColor = setColor, label = lbl, badge = badge, colorKey = t.color, y = y, title = t.title }
        connect(b.MouseButton1Click, function() setTab(t.id) end)
        connect(b.MouseEnter, function()
            if currentTab ~= t.id then tween(b, 0.12, { BackgroundTransparency = 0.55 }) end
        end)
        connect(b.MouseLeave, function()
            if currentTab ~= t.id then tween(b, 0.12, { BackgroundTransparency = 1 }) end
        end)
        y = y + 44
    end
end

setTab = function(id, instant)
    currentTab = id
    local tab = tabs[id]
    for tid, t in pairs(tabs) do
        local on = (tid == id)
        t.button.BackgroundTransparency = 1
        t.setColor(on and (C[t.colorKey] or C.accent) or C.subtext)
        t.label.TextColor3 = on and C.text or C.subtext
        t.label.Font = on and Enum.Font.GothamBold or Enum.Font.GothamMedium
    end
    if tab then
        local col = C[tab.colorKey] or C.accent
        local goal = UDim2.new(0, 8, 0, tab.y)
        if instant then UI.tabPill.Position = goal else tween(UI.tabPill, 0.28, { Position = goal }) end
        tween(UI.tabPill, 0.2, { BackgroundColor3 = col })
        tween(UI.tabPillBar, 0.2, { BackgroundColor3 = col })
        UI.listTitle.Text = tab.title
    end
    local isSettings = (id == "settings")
    UI.settingsPanel.Visible = isSettings
    UI.listPanel.Visible = not isSettings
    UI.detail.Visible = not isSettings
    if not isSettings then refilter() end
end

setPage = function(name)
    currentPage = name
    UI.scriptPage.Visible = (name == "script")
    UI.argsPage.Visible = (name == "args")
    UI.historyPage.Visible = (name == "history")
    for i, sDef in ipairs(SEGS) do
        local on = (sDef.id == name)
        UI.segButtons[i].TextColor3 = on and C.text or C.subtext
        UI.segButtons[i].Font = on and Enum.Font.GothamBold or Enum.Font.GothamMedium
        if on then tween(UI.segPill, 0.24, { Position = UDim2.new(0, 2 + (i - 1) * SEG_W, 0, 2) }) end
    end
    local r = selected and rows[selected]
    if r then refreshPages(r) end
end
for i, sDef in ipairs(SEGS) do
    connect(UI.segButtons[i].MouseButton1Click, function() setPage(sDef.id) end)
end

-- ============================================================
--  SHOW / HIDE, BLUR, DRAG, RESIZE, MINIMIZE
-- ============================================================
local function setBlur(on)
    if on then
        if not blur then
            pcall(function()
                blur = mk("BlurEffect", { Name = "SimpleSpyBlur", Size = S.blurSize, Parent = Lighting })
            end)
        end
        if blur then blur.Enabled = UI.root.Visible end
    elseif blur then
        pcall(function() blur:Destroy() end)
        blur = nil
    end
end

local hideToken = 0
local function setVisible(v)
    hideToken = hideToken + 1
    local token = hideToken
    if v then
        UI.root.Visible = true
        UI.dock.Visible = false
        unseen = 0
        updateDockBadge()
        UI.uiScale.Scale = fitScale * 0.94
        tween(UI.uiScale, 0.32, { Scale = fitScale }, Enum.EasingStyle.Back)
        if blur then blur.Enabled = true end
    else
        tween(UI.uiScale, 0.14, { Scale = fitScale * 0.94 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        if blur then blur.Enabled = false end
        task.delay(0.14, function()
            if hideToken == token then
                UI.root.Visible = false
                UI.dock.Visible = true
            end
        end)
    end
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

makeDraggable(UI.top, UI.root)
local dockWasDragged = makeDraggable(UI.dock, UI.dock)

local minimized = false
do
    local resizing, rStart, rW, rH = false, nil, 0, 0
    connect(UI.grip.InputBegan, function(input)
        if minimized then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            resizing, rStart, rW, rH = true, input.Position, W, H
            local c
            c = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    resizing = false
                    if c then c:Disconnect() end
                    saveSettings()
                end
            end)
        end
    end)
    connect(UserInputService.InputChanged, function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - rStart
            local s = math.max(fitScale, 0.1)
            local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(4000, 4000)
            W = math.floor(clamp(rW + d.X / s, MIN_W, math.max(MIN_W, (vp.X - 20) / s)))
            H = math.floor(clamp(rH + d.Y / s, MIN_H, math.max(MIN_H, (vp.Y - 60) / s)))
            UI.root.Size = UDim2.new(0, W, 0, H)
        end
    end)
end

local function fit(first)
    local cam = workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    fitScale = clamp(math.min(1, (vp.X - 24) / W, (vp.Y - 90) / H), 0.45, 1)
    if UI.root.Visible then UI.uiScale.Scale = fitScale end
    if first then UI.root.Position = UDim2.new(0.5, 0, 0.5, -math.floor(H * fitScale / 2)) end
end

-- ============================================================
--  WIRING
-- ============================================================
local breath
local function setPaused(v, quiet)
    paused = v
    local col = v and C.subtext or C.incoming
    UI.statusBtn.BackgroundColor3 = col
    UI.statusDot.BackgroundColor3 = col
    UI.statusText.TextColor3 = col
    UI.statusText.Text = v and "Paused" or "Live"
    if breath then pcall(function() breath:Cancel() end) breath = nil end
    UI.statusDot.BackgroundTransparency = 0
    if not v then
        pcall(function()
            breath = TweenService:Create(UI.statusDot,
                TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                { BackgroundTransparency = 0.65 })
            breath:Play()
        end)
    end
    if not quiet then notify(v and "Capture paused" or "Capture resumed", v and "warn" or "success") end
end
connect(UI.statusBtn.MouseButton1Click, function() setPaused(not paused) end)

connect(UI.dock.MouseButton1Click, function()
    if dockWasDragged() then return end
    setVisible(true)
end)
connect(UI.closeBtn.MouseButton1Click, function() setVisible(false) end)
connect(UI.minBtn.MouseButton1Click, function()
    minimized = not minimized
    if minimized then
        UI.body.Visible = false
        UI.grip.Visible = false
        tween(UI.root, 0.24, { Size = UDim2.new(0, W, 0, TOP_H) })
    else
        tween(UI.root, 0.24, { Size = UDim2.new(0, W, 0, H) })
        task.delay(0.16, function()
            if not minimized then UI.body.Visible = true; UI.grip.Visible = true end
        end)
    end
end)

connect(UI.searchBox:GetPropertyChangedSignal("Text"), function()
    searchText = string.lower(UI.searchBox.Text)
    UI.searchClear.Visible = UI.searchBox.Text ~= ""
    refilter()
end)
connect(UI.searchBox.Focused, function()
    UI.searchStroke.Color = C.accent
    UI.setSearchIconColor(C.accent)
end)
connect(UI.searchBox.FocusLost, function()
    UI.searchStroke.Color = C.strokeSoft
    UI.setSearchIconColor(C.subtext)
end)
connect(UI.searchClear.MouseButton1Click, function() UI.searchBox.Text = "" end)

-- code: tap to edit, re-highlight when done
connect(UI.codeView.MouseButton1Click, function()
    UI.codeView.Visible = false
    UI.codeBox.Visible = true
    pcall(function() UI.codeBox:CaptureFocus() end)
end)
connect(UI.codeBox.FocusLost, function()
    local r = selected and rows[selected]
    if r and UI.codeBox.Text ~= generatedText then
        pinned = { kind = "edit", row = r }
    end
    UI.codeView.Text = highlight(UI.codeBox.Text)
    UI.codeBox.Visible = false
    UI.codeView.Visible = true
    updatePinChip()
end)
connect(UI.pinChip.MouseButton1Click, function()
    local r = selected and rows[selected]
    pinned = nil
    updatePinChip()
    if r then
        buildCode(r)
        setCode(r.code, true)
        refreshPages(r)
    end
end)

connect(UI.copyBtn.MouseButton1Click, function()
    if not (selected and rows[selected]) then return end
    if setclipboard_fn then
        pcall(setclipboard_fn, UI.codeBox.Text)
        UI.copyLabel.Text = "Copied"
        task.delay(1.2, function() UI.copyLabel.Text = "Copy" end)
        notify("Script copied to clipboard", "success")
    else
        notify("Clipboard isn't available on this executor", "error")
    end
end)

connect(UI.pathBtn.MouseButton1Click, function()
    local r = selected and rows[selected]
    if not r then return end
    local p = instancePath(r.remote) or r.name
    if setclipboard_fn then
        pcall(setclipboard_fn, p)
        notify("Path copied: " .. r.name, "success")
    else
        notify("Clipboard isn't available on this executor", "error")
    end
end)

connect(UI.runBtn.MouseButton1Click, function()
    local r = selected and rows[selected]
    if not r then return end
    if r.incoming then
        notify("Incoming remotes come from the server, so there's nothing to fire. Pick an outgoing one.", "warn")
        return
    end
    UI.runLabel.Text = "Sending…"
    local ran, result
    if loadstring_fn then
        local fn, compileErr = loadstring_fn(UI.codeBox.Text)
        if not fn then
            UI.runLabel.Text = "Execute"
            notify("Compile error: " .. tostring(compileErr), "error")
            return
        end
        executingOwn = true
        ran, result = pcall(fn)
        executingOwn = false
    else
        executingOwn = true
        ran, result = pcall(function()
            local e = currentEntry(r) or {}
            return r.remote[r.method](r.remote, table.unpack(e.args or {}, 1, e.argCount or 0))
        end)
        executingOwn = false
    end
    if ran then
        UI.runLabel.Text = "Sent"
        notify(("Executed :%s() on %s"):format(r.method, r.name), "success")
    else
        UI.runLabel.Text = "Error"
        notify("Execute error: " .. tostring(result), "error")
    end
    task.delay(1.2, function() UI.runLabel.Text = "Execute" end)
end)

connect(UI.ignoreBtn.MouseButton1Click, function()
    local r = selected and rows[selected]
    if not r then return end
    r.ignored = not r.ignored
    notify(r.ignored and ("Ignoring " .. r.name .. " - moved to Ignored") or ("Stopped ignoring " .. r.name), "info")
    refilter()
    if selected == r.key then refreshTools(r) end
end)

connect(UI.blockBtn.MouseButton1Click, function()
    local r = selected and rows[selected]
    if not r then return end
    if r.incoming then
        notify("Only outgoing remotes can be blocked", "warn")
        return
    end
    local now = not blockedKeys[r.key]
    blockedKeys[r.key] = now or nil
    r.blockChip.Visible = now
    refreshTools(r)
    notify(now and ("Blocked " .. r.name .. " - it won't reach the server") or ("Unblocked " .. r.name), now and "warn" or "success")
end)

local toggleKey = Enum.KeyCode.RightShift
pcall(function() toggleKey = Enum.KeyCode[S.toggleKey] end)
connect(UserInputService.InputBegan, function(input, gpe)
    if gpe then return end
    if input.KeyCode == toggleKey then
        setVisible(not UI.root.Visible)
    elseif input.KeyCode == Enum.KeyCode.Slash and UI.root.Visible and not minimized then
        if currentTab == "settings" then setTab(CFG.tabs[1].id) end
        pcall(function() UI.searchBox:CaptureFocus() end)
    end
end)

-- one heartbeat: animated border + live rate / "ago" refresh
do
    local acc = 0
    connect(RunService.Heartbeat, function(dt)
        if S.animatedBorder and UI.root.Visible then
            UI.borderGrad.Rotation = (UI.borderGrad.Rotation + dt * 40) % 360
        end
        acc = acc + dt
        if acc >= 0.5 then
            acc = 0
            local r = selected and rows[selected]
            if r and UI.root.Visible then
                refreshMeta(r)
                if currentPage == "history" then renderHistory(r) end
            end
            if autoTune and autoTune() and repaintSwitches then repaintSwitches() end
            if refreshDiagnostics and UI.settingsPanel.Visible then refreshDiagnostics() end
        end
    end)
end

-- ============================================================
--  CAPTURE: outgoing (__namecall hook) + incoming (OnClientEvent)
-- ============================================================
local installHook, startIncoming, runSelfTest
do
    local FIRE = { FireServer = true, fireServer = true, SendToServer = true }
    local INVK = { InvokeServer = true, invokeServer = true }
    local oldNamecall
    local busy = setmetatable({}, { __mode = "k" })   -- thread -> depth: stops one call being logged by both paths
    local selfTesting, selfTestRemote, selfTestHits = false, nil, {}
    local fnRefs = {}

    local function wrapC(f)
        if newcclosure_fn then
            local ok, w = pcall(newcclosure_fn, f)
            if ok and w then return w end
        end
        return f
    end

    local function serializeReturn(res, from)
        local p = {}
        for i = from, res.n do p[#p + 1] = toLua(res[i], 2) end
        return table.concat(p, ", ")
    end

    -- Was this remote call made by the game (log it) or by an executor script?
    local function passesCaller()
        if selfTesting then return true end
        if checkcaller_fn and checkcaller_fn() then
            if S.logExecutor and not executingOwn then return true end   -- opt-in / compat mode
            HOOK.skipped = HOOK.skipped + 1
            return false
        end
        return true
    end

    -- Shared by both capture paths. IMPORTANT: no :Method() calls before
    -- `original` runs - a method call here would overwrite the pending
    -- namecall method and could turn the game's :FireServer() into another call.
    local function onRemoteCall(original, via, self, m, ...)
        if self == selfTestRemote then
            selfTestHits[via] = true
            return nil
        end
        HOOK.seenRemote = HOOK.seenRemote + 1
        local key = keyFor(self, m)
        local args, count, src = { ... }, select("#", ...), callingScript()
        local isInvoke = INVK[m] == true
        if blockedKeys[key] then
            if S.logOutgoing then
                pcall(record, key, self, m, args, count, isInvoke and "nil --[[ blocked ]]" or nil, src, true)
            end
            return nil
        end
        local co = coroutine.running()
        busy[co] = (busy[co] or 0) + 1
        local res = table.pack(pcall(original, self, ...))
        busy[co] = busy[co] - 1
        if busy[co] <= 0 then busy[co] = nil end
        if not res[1] then error(res[2], 0) end
        if S.logOutgoing then
            local rt
            if isInvoke then
                rt = ""
                pcall(function() rt = serializeReturn(res, 2) end)
            end
            pcall(record, key, self, m, args, count, rt, src, false)
        end
        return table.unpack(res, 2, res.n)
    end

    -- Path 1: __namecall  ->  remote:FireServer(...)
    -- `ref.fn` is the original __namecall this hook sits on top of.
    local function makeNamecallHook(ref)
        return function(self, ...)
            HOOK.seenCalls = HOOK.seenCalls + 1
            if active then
                local m = getnamecallmethod_fn()
                if type(m) ~= "string" then
                    HOOK.noMethod = HOOK.noMethod + 1
                elseif (FIRE[m] or INVK[m]) and typeof(self) == "Instance"
                   and not busy[coroutine.running()] and passesCaller() then
                    return onRemoteCall(ref.fn, "namecall", self, m, ...)
                end
            end
            return ref.fn(self, ...)
        end
    end
    local nc = { fn = nil }

    -- Path 2: the FireServer / InvokeServer functions  ->  remote.FireServer(remote, ...),
    -- task.spawn(remote.FireServer, remote, ...), cached method references, etc.
    local function hookRemoteFunction(cls, m, seen)
        local ok, inst = pcall(Instance.new, cls)
        if not ok or not inst then return end
        local fn
        pcall(function() fn = inst[m] end)
        pcall(function() inst:Destroy() end)
        if type(fn) ~= "function" or seen[fn] then return end
        seen[fn] = true
        local old
        local hooked = wrapC(function(self, ...)
            if active and typeof(self) == "Instance" and not busy[coroutine.running()] and passesCaller() then
                return onRemoteCall(old, "function", self, m, ...)
            end
            return old(self, ...)
        end)
        pcall(function() old = hookfunction_fn(fn, hooked) end)
        if old then
            HOOK.fnHooks = HOOK.fnHooks + 1
            fnRefs[#fnRefs + 1] = { m = m, fn = fn }
        end
    end

    installHook = function()
        if getnamecallmethod_fn and (hookmetamethod_fn or getrawmetatable_fn) then
            local ok, err = pcall(function()
                local raw = makeNamecallHook(nc)
                local hook = wrapC(raw)
                HOOK.wrapped = hook ~= raw
                if hookmetamethod_fn then
                    nc.fn = hookmetamethod_fn(game, "__namecall", hook)
                    HOOK.namecall = "hookmetamethod"
                else
                    local mt = getrawmetatable_fn(game)
                    if setreadonly_fn then setreadonly_fn(mt, false) end
                    nc.fn = mt.__namecall
                    mt.__namecall = hook
                    if setreadonly_fn then setreadonly_fn(mt, true) end
                    HOOK.namecall = "raw metatable"
                end
                oldNamecall = nc.fn
            end)
            if not ok or not oldNamecall then HOOK.namecall = "failed: " .. tostring(err) end
        else
            HOOK.namecall = "unavailable"
        end
        if hookfunction_fn then
            local seen = {}
            pcall(hookRemoteFunction, "RemoteEvent", "FireServer", seen)
            pcall(hookRemoteFunction, "UnreliableRemoteEvent", "FireServer", seen)
            pcall(hookRemoteFunction, "RemoteFunction", "InvokeServer", seen)
        end
        local okAny = (oldNamecall ~= nil) or HOOK.fnHooks > 0
        if not okAny then
            notify("Couldn't hook outgoing remotes on this executor - see Settings > Diagnostics", "warn")
        end
        return okAny
    end

    -- Runs on a timer: works around executor quirks we can detect from the counters.
    autoTune = function()
        -- getnamecallmethod() returns nothing inside the newcclosure wrapper:
        -- stack a second, unwrapped hook on top.
        if HOOK.wrapped and not HOOK.rehooked and hookmetamethod_fn
           and HOOK.seenCalls >= 50 and HOOK.noMethod >= HOOK.seenCalls * 0.9 then
            HOOK.rehooked = true
            local ref = { fn = nil }
            local ok = pcall(function() ref.fn = hookmetamethod_fn(game, "__namecall", makeNamecallHook(ref)) end)
            if ok and ref.fn then
                HOOK.namecall = "hookmetamethod"
                notify("Re-hooked outgoing remotes in compatibility mode", "warn")
            end
        end
        -- checkcaller() flags the game's own calls as executor calls: log them anyway.
        if not S.logExecutor and not HOOK.compat and S.logOutgoing and not paused
           and HOOK.captured == 0 and HOOK.skipped >= 15 then
            HOOK.compat = true
            S.logExecutor = true
            notify("No game remotes were getting through - turned on 'Log executor scripts' (compatibility mode)", "warn")
            return true
        end
        return false
    end

    -- Fires a throwaway remote through both paths (it never reaches the server).
    runSelfTest = function()
        local r = Instance.new("RemoteEvent")
        r.Name = "SimpleSpy_SelfTest"
        selfTestHits, selfTestRemote, selfTesting = {}, r, true
        pcall(function() r:FireServer("self-test") end)
        for _, ref in ipairs(fnRefs) do
            if ref.m == "FireServer" then pcall(ref.fn, r, "self-test") break end
        end
        selfTesting, selfTestRemote = false, nil
        pcall(function() r:Destroy() end)
        HOOK.selfTest = { namecall = selfTestHits.namecall == true, fn = selfTestHits["function"] == true }
        return HOOK.selfTest
    end

    local watched = setmetatable({}, { __mode = "k" })
    local function watchIncoming(remote)
        if watched[remote] then return end
        local cn = remote.ClassName
        if cn == "Actor" then HOOK.actors = HOOK.actors + 1 return end
        if cn ~= "RemoteEvent" and cn ~= "UnreliableRemoteEvent" then return end
        watched[remote] = true
        pcall(function()
            connect(remote.OnClientEvent, function(...)
                if active and S.logIncoming then
                    pcall(record, keyFor(remote, "OnClientEvent"), remote, "OnClientEvent", { ... }, select("#", ...), nil, nil, false)
                end
            end)
        end)
    end

    startIncoming = function()
        pcall(function()
            for _, inst in ipairs(game:GetDescendants()) do watchIncoming(inst) end
        end)
        pcall(function()
            connect(game.DescendantAdded, function(inst) pcall(watchIncoming, inst) end)
        end)
    end
end

-- ============================================================
--  CLEAR / UNLOAD
-- ============================================================
local function clearAll()
    for _, r in pairs(rows) do pcall(function() r.button:Destroy() end) end
    rows = {}
    order, uniqueCount = 0, 0
    selected, pinned = nil, nil
    showDetail(nil)
    refilter()
    notify("Logs cleared", "info")
end

local function unload()
    active = false
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    connections = {}
    if breath then pcall(function() breath:Cancel() end) end
    if blur then pcall(function() blur:Destroy() end) blur = nil end
    pcall(function() screen:Destroy() end)
    if genv.SimpleSpy_GUI == screen then genv.SimpleSpy_GUI = nil end
    print("[SimpleSpy] Unloaded.")
end

do  -- settings page: builders + content (scoped to keep the local count low)
    -- ============================================================
    --  SETTINGS PAGE
    -- ============================================================
    local switches = {}
    local sOrder = 0
    local function nextOrder() sOrder = sOrder + 1; return sOrder end

    local function sHeader(title, subtitle)
        local f = mk("Frame", { Parent = UI.settingsPanel, LayoutOrder = nextOrder(), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40) })
        label({ Name = "SettingsTitle", Parent = f, Size = UDim2.new(1, 0, 0, 22), Font = Enum.Font.GothamBlack, TextSize = 19, Text = title })
        label({ Parent = f, Position = UDim2.new(0, 0, 0, 24), Size = UDim2.new(1, 0, 0, 14), TextSize = 11, TextColor3 = C.subtext, Text = subtitle })
    end

    local function sCard(title)
        local card = mk("Frame", {
            Name = "Card", Parent = UI.settingsPanel, LayoutOrder = nextOrder(), AutomaticSize = Enum.AutomaticSize.Y,
            Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = C.surfaceAlt, BorderSizePixel = 0,
        }, {
            corner(14), outline(C.strokeSoft, 1), pad(14, 16, 14, 16),
            mk("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
        })
        glass(card, 0.3)
        label({
            Parent = card, LayoutOrder = 0, Size = UDim2.new(1, 0, 0, 14), Font = Enum.Font.GothamBold,
            TextSize = 10, TextColor3 = C.muted, Text = string.upper(title),
        })
        return card
    end

    local function sToggle(card, title, desc, getter, setter)
        local rowF = mk("Frame", { Name = "Toggle", Parent = card, LayoutOrder = nextOrder(), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 36) })
        label({ Name = "ToggleTitle", Parent = rowF, Size = UDim2.new(1, -70, 0, 18), Font = Enum.Font.GothamBold, TextSize = 13, Text = title })
        label({
            Parent = rowF, Position = UDim2.new(0, 0, 0, 19), Size = UDim2.new(1, -70, 0, 15), TextSize = 11,
            TextColor3 = C.subtext, TextTruncate = Enum.TextTruncate.AtEnd, Text = desc,
        })
        local track = mk("TextButton", {
            Name = "Switch", Parent = rowF, AutoButtonColor = false, Text = "", AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 44, 0, 24), BorderSizePixel = 0,
        }, { corner(12) })
        local knob = mk("Frame", {
            Parent = track, Size = UDim2.new(0, 20, 0, 20), BackgroundColor3 = WHITE, BorderSizePixel = 0,
        }, { corner(10) })
        local function paintSwitch(animate)
            local on = getter()
            local props = { BackgroundColor3 = on and C.accent or C.stroke }
            local kprops = { Position = on and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10) }
            if animate then
                tween(track, 0.18, props)
                tween(knob, 0.18, kprops, Enum.EasingStyle.Back)
            else
                track.BackgroundColor3 = props.BackgroundColor3
                knob.Position = kprops.Position
            end
        end
        paintSwitch(false)
        switches[#switches + 1] = paintSwitch
        connect(track.MouseButton1Click, function()
            setter(not getter())
            paintSwitch(true)
            saveSettings()
        end)
    end

    repaintSwitches = function() for _, paintSwitch in ipairs(switches) do paintSwitch(false) end end

    local function sButton(parent, name, text, bg, fg, order, width, fn)
        local b = mk("TextButton", {
            Name = name, Parent = parent, LayoutOrder = order, AutoButtonColor = false, Size = width,
            BackgroundColor3 = bg, BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 13,
            TextColor3 = fg, Text = text,
        }, { corner(10) })
        pressable(b)
        connect(b.MouseButton1Click, fn)
        return b
    end

    -- ── settings content (after the functions it calls exist) ──
    sHeader("Settings", "Changes apply instantly and are saved for next time.")

    local capture = sCard("Capture")
    sToggle(capture, "Log outgoing", "FireServer / InvokeServer from your client",
        function() return S.logOutgoing end, function(v) S.logOutgoing = v end)
    sToggle(capture, "Log incoming", "OnClientEvent fired to you by the server",
        function() return S.logIncoming end, function(v) S.logIncoming = v end)
    sToggle(capture, "Log executor scripts", "Also capture remotes fired by scripts you run in your executor",
        function() return S.logExecutor end, function(v) S.logExecutor = v end)

    local look = sCard("Appearance")
    do
        local rowF = mk("Frame", { Parent = look, LayoutOrder = nextOrder(), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 54) })
        label({ Parent = rowF, Size = UDim2.new(1, 0, 0, 18), Font = Enum.Font.GothamBold, TextSize = 13, Text = "Accent" })
        local accentName = label({
            Name = "AccentName", Parent = rowF, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
            Size = UDim2.new(0, 120, 0, 18), TextSize = 11, TextColor3 = C.subtext,
            TextXAlignment = Enum.TextXAlignment.Right,
            Text = S.accentIndex > 0 and ACCENTS[S.accentIndex].name or "From CONFIG_JSON",
        })
        local sw = mk("Frame", {
            Parent = rowF, BackgroundTransparency = 1, Position = UDim2.new(0, 2, 0, 24), Size = UDim2.new(1, -4, 0, 30),
        }, {
            mk("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12),
                VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder,
            }),
        })
        local rings = {}
        for i, a in ipairs(ACCENTS) do
            local b = mk("TextButton", {
                Name = "Swatch_" .. a.name, Parent = sw, LayoutOrder = i, AutoButtonColor = false, Text = "",
                Size = UDim2.new(0, 26, 0, 26), BackgroundColor3 = WHITE, BorderSizePixel = 0,
            }, {
                corner(13),
                mk("UIGradient", { Rotation = 45, Color = seq({ 0, Color3.fromHex(a.a) }, { 1, Color3.fromHex(a.b) }) }),
            })
            pressable(b)
            rings[i] = mk("UIStroke", {
                Parent = b, Color = WHITE, Thickness = 2, Transparency = (S.accentIndex == i) and 0 or 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            })
            connect(b.MouseButton1Click, function()
                S.accentIndex = i
                C.accent = Color3.fromHex(a.a)
                C.accent2 = Color3.fromHex(a.b)
                for j, ring in ipairs(rings) do ring.Transparency = (j == i) and 0 or 1 end
                accentName.Text = a.name
                applyTheme()
                for _, paintSwitch in ipairs(switches) do paintSwitch(false) end
                setTab(currentTab, true)
                saveSettings()
            end)
        end
    end
    sToggle(look, "Acrylic glass", "See-through panels",
        function() return S.acrylic end, function(v) S.acrylic = v; applyAcrylic(v) end)
    sToggle(look, "Animated border", "A slow shimmer around the window",
        function() return S.animatedBorder end, function(v) S.animatedBorder = v end)
    sToggle(look, "Screen blur", "Frosted blur - Roblox blurs the WHOLE screen",
        function() return S.blur end, function(v) S.blur = v; setBlur(v) end)

    local diag = sCard("Diagnostics")
    do
        local function diagRow(name, title)
            local rowF = mk("Frame", { Name = "Diag_" .. name, Parent = diag, LayoutOrder = nextOrder(), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18) })
            label({ Parent = rowF, Size = UDim2.new(0.45, 0, 1, 0), TextSize = 12, TextColor3 = C.subtext, Text = title })
            local dot = mk("Frame", {
                Parent = rowF, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(0, 8, 0, 8), BackgroundColor3 = C.muted, BorderSizePixel = 0,
            }, { corner(4) })
            local val = label({
                Name = "DiagValue", Parent = rowF, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 0),
                Size = UDim2.new(0.55, -16, 1, 0), Font = Enum.Font.GothamMedium, TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, Text = "",
            })
            return function(text, state)
                val.Text = text
                dot.BackgroundColor3 = (state == "ok" and C.incoming) or (state == "bad" and C.danger)
                                    or (state == "warn" and C.warning) or C.muted
            end
        end
        local setExec    = diagRow("Executor", "Executor")
        local setNC      = diagRow("Namecall", "Namecall hook")
        local setFn      = diagRow("Functions", "Function hooks")
        local setActive  = diagRow("Activity", "Hook activity")
        local setSeen    = diagRow("Seen", "Remote calls seen")
        local setSkip    = diagRow("Skipped", "Skipped as executor")
        local setActors  = diagRow("Actors", "Actors in game")
        local setTest    = diagRow("SelfTest", "Self-test")
        local execName = "Unknown"
        pcall(function()
            local n, v = identify_fn()
            if n then execName = tostring(n) .. (v and (" " .. tostring(v)) or "") end
        end)
        refreshDiagnostics = function()
            setExec(execName, "info")
            local ncOk = HOOK.namecall == "hookmetamethod" or HOOK.namecall == "raw metatable"
            setNC(ncOk and ("on (" .. HOOK.namecall .. (HOOK.rehooked and ", re-hooked" or "") .. ")") or HOOK.namecall,
                  ncOk and "ok" or "bad")
            setActive(HOOK.seenCalls .. " method calls", HOOK.seenCalls > 0 and "ok" or "bad")
            setSkip(HOOK.skipped .. (HOOK.compat and "  ·  compat mode on" or ""), HOOK.compat and "warn" or "info")
            setFn(HOOK.fnHooks > 0 and (HOOK.fnHooks .. " hooked") or "none", HOOK.fnHooks > 0 and "ok" or "warn")
            setSeen(("%d seen  ·  %d logged"):format(HOOK.seenRemote, HOOK.captured), HOOK.seenRemote > 0 and "ok" or "warn")
            setActors(HOOK.actors > 0 and (HOOK.actors .. " (parallel scripts can't be hooked)") or "0", HOOK.actors > 0 and "warn" or "ok")
            local t = HOOK.selfTest
            if not t then setTest("not run yet", "info")
            elseif t.namecall and t.fn then setTest("both paths work", "ok")
            elseif t.namecall or t.fn then setTest((t.namecall and "namecall" or "function") .. " path works", "warn")
            else setTest("no path caught it", "bad") end
        end
        local btnRow = mk("Frame", { Parent = diag, LayoutOrder = nextOrder(), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 36) })
        sButton(btnRow, "SelfTest", "Run self-test", C.hover, C.text, 1, UDim2.new(1, 0, 1, 0), function()
            local t = runSelfTest()
            refreshDiagnostics()
            if t.namecall and t.fn then notify("Self-test passed - outgoing capture works", "success")
            elseif t.namecall or t.fn then notify("Self-test: one capture path works", "warn")
            else notify("Self-test failed - this executor's hooks aren't catching remotes", "error") end
        end)
        mk("TextLabel", {
            Parent = diag, LayoutOrder = nextOrder(), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y,
            Size = UDim2.new(1, 0, 0, 0), Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.muted,
            TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
            Text = "If 'Remote calls seen' stays at 0 while you play, the game isn't calling remotes through anything the hook can reach - usually scripts running inside Actors.",
        })
        refreshDiagnostics()
    end

    local dataCard = sCard("Data")
    do
        local rowF = mk("Frame", { Parent = dataCard, LayoutOrder = nextOrder(), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 38) }, {
            mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
        })
        sButton(rowF, "ClearAll", "Clear all logs", C.hover, C.text, 1, UDim2.new(0.5, -5, 1, 0), function() clearAll() end)
        sButton(rowF, "Unload", "Unload SimpleSpy", C.danger, WHITE, 2, UDim2.new(0.5, -5, 1, 0), function() unload() end)
    end

    local about = sCard("About")
    do
        local rowF = mk("Frame", { Parent = about, LayoutOrder = nextOrder(), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40) })
        makeLogo(rowF, 40)
        label({ Parent = rowF, Position = UDim2.new(0, 52, 0, 2), Size = UDim2.new(1, -52, 0, 18), Font = Enum.Font.GothamBlack, TextSize = 15, Text = "SimpleSpy " .. VERSION })
        label({
            Parent = rowF, Position = UDim2.new(0, 52, 0, 22), Size = UDim2.new(1, -52, 0, 16), TextSize = 11,
            TextColor3 = C.subtext, TextTruncate = Enum.TextTruncate.AtEnd,
            Text = "Theme, syntax colours and tabs live in CONFIG_JSON. Press / to search.",
        })
    end

end

-- ============================================================
--  API + GO
-- ============================================================
genv.SimpleSpy_Toggle = function() setVisible(not UI.root.Visible) end
genv.SimpleSpy_Clear  = clearAll
genv.SimpleSpy_Stop   = unload
genv.SimpleSpy_Unload = unload

fit(true)
pcall(function()
    connect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), function() fit(false) end)
end)
setTab(currentTab, true)
setPage("script")
showDetail(nil)
updateCounts()
setBlur(S.blur)
setVisible(true)
setPaused(false, true)

local hooked = installHook()
startIncoming()
if not configOk then notify("CONFIG_JSON couldn't be read - using the default theme", "warn") end
notify(hooked and "SimpleSpy is live - spying both ways" or "Incoming capture is on, but outgoing hooks are unavailable",
       hooked and "success" or "warn")
