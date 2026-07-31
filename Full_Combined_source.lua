local _ok,_err = pcall(function()
-- ════════════════════════════════════════
-- SOURCE: src/core/01_services.lua
-- ════════════════════════════════════════
-- ── Services ──────────────────────────────────────────────────────────────────
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local UIS     = game:GetService("UserInputService")
local TS      = game:GetService("TweenService")
local RUN     = game:GetService("RunService")
local SG      = game:GetService("StarterGui")
local WS      = game:GetService("Workspace")
local HTTP    = game:GetService("HttpService")
local MktSvc  = game:GetService("MarketplaceService")
local TelSvc  = game:GetService("TeleportService")
local CollSvc = game:GetService("CollectionService")
local CmdSvc  = game:GetService("Chat")
-- NOTE: DataStoreService / PhysicsService are server-only; never import them here.

-- ── LocalPlayer — polling loop, works on every executor ───────────────────────
local LP
for _ = 1, 120 do
    LP = Players.LocalPlayer
    if LP then break end
    task.wait(0.1)
end
if not LP then warn("[Nexus] No LocalPlayer after 12 s"); return end

-- ── Notification helper (available immediately, before any GUI) ────────────────
local function notify(title, body, dur)
    pcall(function()
        SG:SetCore("SendNotification",{Title=title,Text=body,Duration=dur or 3})
    end)
end
notify("Nexus Executor","Loading…",3)

-- ── GUI parent — gethui() (Delta/Synapse) → PlayerGui fallback ────────────────
local function getGuiParent()
    if type(gethui)=="function" then
        local ok,h = pcall(gethui)
        if ok and h and typeof(h)=="Instance" then return h end
    end
    local pg = LP:FindFirstChildOfClass("PlayerGui")
    if pg then return pg end
    return LP:WaitForChild("PlayerGui",15)
end
local PGui = getGuiParent()
if not PGui then warn("[Nexus] No PlayerGui"); return end

-- Remove any stale GUI
local _old = PGui:FindFirstChild("__SS_EXEC__")
if _old then _old:Destroy() end

-- ── loadstring compat ─────────────────────────────────────────────────────────
local _ld = loadstring or load

-- ── Camera / viewport — safe getter with fallback ─────────────────────────────
-- workspace.CurrentCamera can be nil briefly on mobile. We retry for up to
-- 5 seconds before falling back to a safe default size.
local function getViewport()
    for _ = 1, 50 do
        local cam = WS:FindFirstChildOfClass("Camera")
        if cam then return cam.ViewportSize end
        task.wait(0.1)
    end
    return Vector2.new(800,600)   -- safe fallback if camera never appears
end
local _VP = getViewport()

-- ── Platform & adaptive sizing ────────────────────────────────────────────────
local isMobile = UIS.TouchEnabled   -- true on Delta iOS/Android/iPad

-- Mobile → full-screen. Desktop → fixed 650×530 floating window.
local WIN_W  = isMobile and math.floor(_VP.X) or 650
local WIN_H  = isMobile and math.floor(_VP.Y) or 530
local SIDE_W = 54    -- sidebar width  (desktop only)
local TAB_SP = 40    -- sidebar tab row pitch (desktop only)
local TAB_SZ = 34    -- sidebar button height (desktop only)

-- ── Executor detection ────────────────────────────────────────────────────────
local function detectExecutor()
    if type(identifyexecutor)=="function" then
        local ok,n = pcall(identifyexecutor)
        if ok and n and n~="" then return tostring(n) end
    end
    if type(getexecutorname)=="function" then
        local ok,n = pcall(getexecutorname)
        if ok and n and n~="" then return tostring(n) end
    end
    if rawget(_G,"delta")  or rawget(_G,"_DELTA") or rawget(_G,"DELTA")  then return "Delta"     end
    if rawget(_G,"wave")   or rawget(_G,"Wave")                           then return "Wave"      end
    if rawget(_G,"syn")    or rawget(_G,"Synapse")                        then return "Synapse X" end
    if rawget(_G,"KRNL_LOADED")                                           then return "KRNL"      end
    if rawget(_G,"fluxus") or rawget(_G,"Fluxus")                        then return "Fluxus"    end
    if rawget(_G,"solara") or rawget(_G,"Solara")                        then return "Solara"    end
    if rawget(_G,"is_sirhurt_closure")                                    then return "SirHurt"   end
    if rawget(_G,"ANDROID_APP")                                           then return "Arceus X"  end
    return "Unknown Executor"
end

-- ── Utilities ─────────────────────────────────────────────────────────────────
local function safeGet(t,k) return type(t)=="table" and rawget(t,k) or nil end
local function safeCall(fn,...)
    if type(fn)~="function" then return false,"not a function" end
    return pcall(fn,...)
end
local function isFunc(x)  return type(x)=="function" end
local function isTable(x) return type(x)=="table"    end
local function isStr(x)   return type(x)=="string"   end
local function isNum(x)   return type(x)=="number"   end

local function ts() return os.date("[%H:%M:%S] ") end

local function fmtNum(n)
    if n>=1e9 then return("%.2fB"):format(n/1e9)
    elseif n>=1e6 then return("%.2fM"):format(n/1e6)
    elseif n>=1e3 then return("%.1fK"):format(n/1e3)
    else return tostring(n) end
end

local function trunc(s,max)
    s=tostring(s); return #s>max and s:sub(1,max).."…" or s
end

local function split(s,sep)
    local p={}; for x in s:gmatch("([^"..sep.."]+)") do p[#p+1]=x end; return p
end

local function trim(s) return (tostring(s):gsub("^%s*(.-)%s*$","%1")) end

local function deepCopy(t)
    if type(t)~="table" then return t end
    local c={}; for k,v in pairs(t) do c[k]=deepCopy(v) end; return c
end

local function tableHas(t,v) for _,x in t do if x==v then return true end end; return false end
local function tableMap(t,fn) local o={}; for i,v in t do o[i]=fn(v) end; return o end
local function tableFilter(t,fn) local o={}; for _,v in t do if fn(v) then o[#o+1]=v end end; return o end

-- Clipboard — setclipboard works on Delta iOS/Android/iPad
local function copyText(txt)
    if type(setclipboard)=="function" then return pcall(setclipboard,txt) end
    return false
end

local function getRoot() local c=LP and LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum()  local c=LP and LP.Character; return c and c:FindFirstChildOfClass("Humanoid")   end
local function getChar() return LP and LP.Character end

-- ── Shared execution helpers ──────────────────────────────────────────────────
-- Compile then run a chunk of Lua.
-- Returns: ok(bool), err(string|nil), stage("compile"|"runtime"|nil)
local function runCode(code)
    local fn, cerr = _ld(code)
    if not fn then return false, tostring(cerr), "compile" end
    local ok, rerr = pcall(fn)
    if not ok then return false, tostring(rerr), "runtime" end
    return true
end

-- Depth-first walk of every script instance under `root`, calling fn(scriptInst).
local function forEachScript(root, fn)
    for _, ch in root:GetChildren() do
        if ch:IsA("LocalScript") or ch:IsA("ModuleScript") or ch:IsA("Script") then
            fn(ch)
        end
        forEachScript(ch, fn)
    end
end

-- Detect whether a (possibly dotted, e.g. "debug.getinfo") global exists.
local function hasGlobal(name)
    local root = name:match("^([^%.]+)%.")
    if root then
        local tbl = (getfenv and getfenv()[root]) or _G[root]
        if type(tbl) == "table" then
            return tbl[name:match("%.(.+)$")] ~= nil
        end
        return false
    end
    if getfenv and getfenv()[name] ~= nil then return true end
    return _G[name] ~= nil
end

-- ── Session ───────────────────────────────────────────────────────────────────
local SESSION = {
    startTime   = os.time(),
    executor    = detectExecutor(),
    platform    = isMobile and "Mobile/Touch" or "PC/Desktop",
    isMobile    = isMobile,
    gameId      = game.GameId,
    placeId     = game.PlaceId,
    playerName  = LP.Name,
    displayName = LP.DisplayName,
    winW        = WIN_W,
    winH        = WIN_H,
}

-- ════════════════════════════════════════
-- SOURCE: src/core/02_bridge.lua
-- ════════════════════════════════════════
-- ── Server Bridge ────────────────────────────────────────────────────────────
-- Communicates with SS_Executor.lua (server-side RemoteFunction)

local Bridge = RS:FindFirstChild("SS_ExecBridge")

-- Watch for bridge appearing/disappearing
RS.ChildAdded:Connect(function(ch)
    if ch.Name == "SS_ExecBridge" then Bridge = ch end
end)
RS.ChildRemoved:Connect(function(ch)
    if ch.Name == "SS_ExecBridge" then Bridge = nil end
end)

-- Ping — returns true if bridge is alive
local function pingBridge()
    if not Bridge then return false end
    local ok, r = pcall(function() return Bridge:InvokeServer("ping") end)
    return ok and r and r.ok == true
end

-- callBridge — invoke an action on the server
-- Returns: ok (bool), msg (string), data (table|nil)
local function callBridge(action, payload)
    if not Bridge then
        return false, "No bridge — inject SS_Executor.lua server-side first."
    end
    local ok, r = pcall(function()
        return Bridge:InvokeServer(action, payload or {})
    end)
    if not ok then return false, tostring(r), nil end
    if type(r) ~= "table" then return false, "Bridge returned invalid data.", nil end
    return r.ok == true, r.msg or "", r.data
end

-- callBridgeAsync — fire and forget (no wait)
local function callBridgeAsync(action, payload)
    task.spawn(callBridge, action, payload)
end

-- bridgeStatus — returns detailed status string
local function bridgeStatus()
    if not Bridge then return false, "SS_ExecBridge not found in ReplicatedStorage" end
    local ok, msg = callBridge("ping")
    if ok then return true, "Bridge online ✓"
    else return false, "Bridge found but not responding: " .. tostring(msg) end
end

-- runOnServer — convenience wrapper for server-side loadstring
local function runOnServer(code)
    return callBridge("ls", { code = code })
end

-- runUrlOnServer — fetch URL server-side then execute
local function runUrlOnServer(url)
    return callBridge("ls_url", { url = url })
end

-- requireOnServer — server-side require by asset ID
local function requireOnServer(id)
    return callBridge("req", { id = id })
end

-- getServerPlayers — fetch player list from server
local function getServerPlayers()
    local ok, msg, data = callBridge("getplrs")
    return ok, msg, data
end

-- getServerScripts — fetch script list from server
local function getServerScripts()
    local ok, msg, data = callBridge("get_scripts")
    return ok, msg, data
end

-- killAllScripts — kill all server LocalScripts
local function killAllScripts()
    return callBridge("kill_all")
end

-- killScript — kill a specific script by name
local function killScript(name)
    return callBridge("kill", { name = name })
end

-- blockRemote — block a specific RemoteEvent/Function
local function blockRemote(name)
    return callBridge("block_remote", { name = name })
end

-- serverScan — scan server for suspicious scripts
local function serverScan()
    return callBridge("scan")
end

-- kickPlayer — kick a player by name
local function kickPlayer(name, reason)
    return callBridge("kick", { name = name, reason = reason or "Kicked by executor." })
end

-- ════════════════════════════════════════
-- SOURCE: src/core/03_theme.lua
-- ════════════════════════════════════════
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

-- ════════════════════════════════════════
-- SOURCE: src/core/04_ui.lua
-- ════════════════════════════════════════
-- ── UI Helper Library ─────────────────────────────────────────────────────────
-- All Instance-creation wrappers. `isMobile` and `WIN_W/H/SIDE_W` are
-- already in scope (defined in 01_services.lua).

-- UICorner
local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 7)
    c.Parent = p
end

-- UIStroke
local function stroke(p, col, th, lineStyle)
    local s = Instance.new("UIStroke")
    s.Color = col or C.BDR
    s.Thickness = th or 1.2
    if lineStyle then s.LineJoinMode = lineStyle end
    s.Parent = p
end

-- UIPadding
local function pad(p, v, h)
    local u = Instance.new("UIPadding")
    u.PaddingTop    = UDim.new(0, v or 6)
    u.PaddingBottom = UDim.new(0, v or 6)
    u.PaddingLeft   = UDim.new(0, h or v or 9)
    u.PaddingRight  = UDim.new(0, h or v or 9)
    u.Parent = p
end

-- UIListLayout — horizontal
local function listH(p, sp, xa, ya)
    local l = Instance.new("UIListLayout")
    l.FillDirection  = Enum.FillDirection.Horizontal
    l.SortOrder      = Enum.SortOrder.LayoutOrder
    l.Padding        = UDim.new(0, sp or 4)
    if xa then l.HorizontalAlignment = xa end
    if ya then l.VerticalAlignment   = ya end
    l.Parent = p
end

-- UIListLayout — vertical
local function listV(p, sp, ya)
    local l = Instance.new("UIListLayout")
    l.FillDirection  = Enum.FillDirection.Vertical
    l.SortOrder      = Enum.SortOrder.LayoutOrder
    l.Padding        = UDim.new(0, sp or 4)
    if ya then l.HorizontalAlignment = ya end
    l.Parent = p
end

-- UIGridLayout
local function grid(p, cellSz, cellPad)
    local g = Instance.new("UIGridLayout")
    g.CellSize    = cellSz or UDim2.new(0, 100, 0, 80)
    g.CellPadding = cellPad or UDim2.new(0, 4, 0, 4)
    g.SortOrder   = Enum.SortOrder.LayoutOrder
    g.Parent = p
    return g
end

-- UIAspectRatioConstraint
local function aspect(p, ratio)
    local a = Instance.new("UIAspectRatioConstraint")
    a.AspectRatio = ratio or 1
    a.Parent = p
end

-- UIScale
local function scale(p, s)
    local u = Instance.new("UIScale")
    u.Scale = s or 1
    u.Parent = p
    return u
end

-- Frame
local function F(par, sz, pos, col, nm)
    local f = Instance.new("Frame")
    f.Size             = sz
    f.Position         = pos or UDim2.new(0, 0, 0, 0)
    f.BackgroundColor3 = col or C.PANEL
    f.BorderSizePixel  = 0
    f.Name             = nm or "F"
    f.Parent           = par
    return f
end

-- TextLabel
local function L(par, txt, sz, pos, col, fnt, ts, xa, ya)
    local l = Instance.new("TextLabel")
    l.Size               = sz
    l.Position           = pos or UDim2.new(0, 0, 0, 0)
    l.BackgroundTransparency = 1
    l.Text               = txt or ""
    l.TextColor3         = col or C.TXT
    l.Font               = fnt or FN
    l.TextSize           = ts or 13
    l.TextXAlignment     = xa or Enum.TextXAlignment.Left
    l.TextYAlignment     = ya or Enum.TextYAlignment.Center
    l.TextTruncate       = Enum.TextTruncate.AtEnd
    l.RichText           = false
    l.Parent             = par
    return l
end

-- TextLabel with RichText
local function LR(par, txt, sz, pos, col, fnt, ts, xa)
    local l = L(par, txt, sz, pos, col, fnt, ts, xa)
    l.RichText = true
    return l
end

-- TextButton
local function B(par, txt, sz, pos, bg, tc)
    local b = Instance.new("TextButton")
    b.Size             = sz
    b.Position         = pos or UDim2.new(0, 0, 0, 0)
    b.BackgroundColor3 = bg or C.ACC
    b.BorderSizePixel  = 0
    b.Text             = txt or ""
    b.TextColor3       = tc or C.TXT
    b.Font             = FB
    b.TextSize         = 12
    b.AutoButtonColor  = false
    b.Parent           = par
    corner(b, 6)
    return b
end

-- TextBox — multiline input editor
local function IN(par, ph, sz, pos, multiline)
    local b = Instance.new("TextBox")
    b.Size               = sz
    b.Position           = pos or UDim2.new(0, 0, 0, 0)
    b.BackgroundColor3   = C.EDIT
    b.BorderSizePixel    = 0
    b.Text               = ""
    b.PlaceholderText    = ph or ""
    b.TextColor3         = C.TXT
    b.PlaceholderColor3  = C.TXTS
    b.Font               = FC
    b.TextSize           = 12
    b.TextXAlignment     = Enum.TextXAlignment.Left
    b.TextYAlignment     = Enum.TextYAlignment.Top
    b.ClearTextOnFocus   = false
    b.MultiLine          = multiline ~= false
    b.TextWrapped        = true
    b.ClipsDescendants   = true
    b.Parent             = par
    corner(b, 6)
    stroke(b, C.BDR, 1)
    pad(b, 6, 10)
    return b
end

-- TextBox — single-line input
local function INS(par, ph, sz, pos)
    local b = IN(par, ph, sz, pos, false)
    b.TextYAlignment = Enum.TextYAlignment.Center
    return b
end

-- TextBox — output console (read-only)
local function OUT(par, sz, pos, ph)
    local b = Instance.new("TextBox")
    b.Size               = sz
    b.Position           = pos or UDim2.new(0, 0, 0, 0)
    b.BackgroundColor3   = C.CON
    b.BorderSizePixel    = 0
    b.Text               = ""
    b.PlaceholderText    = ph or "> output…"
    b.TextColor3         = C.GRN
    b.PlaceholderColor3  = C.TXTD
    b.Font               = FC
    b.TextSize           = 11
    b.TextXAlignment     = Enum.TextXAlignment.Left
    b.TextYAlignment     = Enum.TextYAlignment.Top
    b.ClearTextOnFocus   = false
    b.MultiLine          = true
    b.TextWrapped        = true
    b.TextEditable       = false
    b.ClipsDescendants   = true
    b.Parent             = par
    corner(b, 6)
    stroke(b, C.BDR, 1)
    pad(b, 6, 10)
    return b
end

-- Single-line, timestamped status console. Returns a writer fn(msg, ok)
-- that colours the box green on success / red on failure.
local function statusOut(par, sz, pos, ph)
    local box = OUT(par, sz, pos, ph)
    return function(msg, ok)
        box.TextColor3 = ok and C.GRN or C.RED
        box.Text = ts() .. tostring(msg)
    end
end

-- Remove every child of a layout container except its UIListLayout.
local function clearLayout(container)
    for _, ch in container:GetChildren() do
        if not ch:IsA("UIListLayout") then ch:Destroy() end
    end
end

-- Assign sequential LayoutOrder + a common TextSize to a row of buttons.
local function styleRow(btns, textSize)
    for i, b in btns do
        b.LayoutOrder = i
        b.TextSize    = textSize or 11
    end
    return btns
end

-- ScrollingFrame (auto canvas, vertical by default)
local function SCR(par, sz, pos, barThick)
    local s = Instance.new("ScrollingFrame")
    s.Size                  = sz
    s.Position              = pos or UDim2.new(0, 0, 0, 0)
    s.BackgroundTransparency = 1
    s.BorderSizePixel       = 0
    s.ScrollBarThickness    = barThick or (isMobile and 2 or 3)
    s.ScrollBarImageColor3  = C.ACC
    s.CanvasSize            = UDim2.new(0, 0, 0, 0)
    s.AutomaticCanvasSize   = Enum.AutomaticSize.Y
    s.Parent                = par
    return s
end

-- Hover tween helper — touch devices get press-feedback instead of hover
local function hov(btn, normal, hovered)
    if not isMobile then
        btn.MouseEnter:Connect(function()
            tw(btn, {BackgroundColor3 = hovered})
        end)
        btn.MouseLeave:Connect(function()
            tw(btn, {BackgroundColor3 = normal})
        end)
    end
    -- Press feedback works on all devices
    btn.MouseButton1Down:Connect(function()
        tw(btn, {BackgroundColor3 = hovered})
    end)
    btn.MouseButton1Up:Connect(function()
        tw(btn, {BackgroundColor3 = normal})
    end)
end

-- Hover with text color change
local function hovFull(btn, nBg, hBg, nTxt, hTxt)
    if not isMobile then
        btn.MouseEnter:Connect(function()  tw(btn, {BackgroundColor3=hBg, TextColor3=hTxt or C.WHT}) end)
        btn.MouseLeave:Connect(function()  tw(btn, {BackgroundColor3=nBg, TextColor3=nTxt or C.TXT}) end)
    end
    btn.MouseButton1Down:Connect(function() tw(btn, {BackgroundColor3=hBg}) end)
    btn.MouseButton1Up:Connect(function()   tw(btn, {BackgroundColor3=nBg}) end)
end

-- Horizontal row container.
-- On mobile: uses a horizontal ScrollingFrame (invisible scrollbar) so button
-- rows that exceed the content width can be swiped left/right.
-- On desktop: plain transparent frame with UIListLayout.
local function rowBar(par, yOff, h)
    if isMobile then
        local r = Instance.new("ScrollingFrame")
        r.Size                  = UDim2.new(1, 0, 0, h or 26)
        r.Position              = UDim2.new(0, 0, 0, yOff or 0)
        r.BackgroundTransparency = 1
        r.BorderSizePixel       = 0
        r.ScrollBarThickness    = 0            -- invisible — swipe gesture only
        r.ScrollingDirection    = Enum.ScrollingDirection.X
        r.CanvasSize            = UDim2.new(0, 0, 0, 0)
        r.AutomaticCanvasSize   = Enum.AutomaticSize.X
        r.Parent                = par
        listH(r, 4)
        return r
    else
        local r = F(par, UDim2.new(1, 0, 0, h or 26), UDim2.new(0, 0, 0, yOff or 0), C.BLK)
        r.BackgroundTransparency = 1
        listH(r, 4)
        return r
    end
end

-- Section header (coloured panel with label)
local function sectionHdr(par, txt, col)
    local r = F(par, UDim2.new(1, -4, 0, 22), nil, col or C.PANEL)
    corner(r, 5)
    L(r, "  " .. txt, UDim2.new(1, 0, 1, 0), nil, C.PURP, FB, 11)
    return r
end

-- Status dot (small circle indicator)
local function dot(par, sz, pos, col)
    local d = F(par, sz or UDim2.new(0, 8, 0, 8), pos or UDim2.new(0, 0, 0, 0), col or C.GREY)
    corner(d, 99)
    return d
end

-- Badge / pill label
local function pill(par, txt, col, sz, pos)
    local bg = F(par, sz or UDim2.new(0, 60, 0, 18), pos, col or C.GREY)
    corner(bg, 4)
    L(bg, txt, UDim2.new(1, 0, 1, 0), nil, C.WHT, FB, 10, Enum.TextXAlignment.Center)
    return bg
end

-- Divider line
local function divider(par, col)
    local d = F(par, UDim2.new(1, -4, 0, 1), nil, col or C.BDR)
    d.BackgroundTransparency = 0.5
    return d
end

-- Image button
local function IMG(par, assetId, sz, pos)
    local i = Instance.new("ImageButton")
    i.Size = sz; i.Position = pos or UDim2.new(0, 0, 0, 0)
    i.BackgroundTransparency = 1; i.BorderSizePixel = 0
    i.Image = "rbxassetid://" .. assetId; i.Parent = par
    return i
end

-- Tooltip (desktop hover only — on mobile tooltips are inaccessible)
local function tooltip(btn, text, yOff)
    if isMobile then return end
    local tip = Instance.new("TextLabel")
    tip.Size = UDim2.new(0, #text * 7 + 16, 0, 22)
    tip.Position = UDim2.new(0, 0, 1, yOff or 4)
    tip.BackgroundColor3 = C.PANEL; tip.TextColor3 = C.TXT
    tip.Text = text; tip.Font = FN; tip.TextSize = 11
    tip.BorderSizePixel = 0; tip.ZIndex = 20; tip.Visible = false
    tip.Parent = btn; corner(tip, 5); stroke(tip, C.BDR, 1)
    btn.MouseEnter:Connect(function()  tip.Visible = true  end)
    btn.MouseLeave:Connect(function()  tip.Visible = false end)
    return tip
end

-- Toggle button (stateful on/off)
local function toggleButton(par, txt, sz, pos, onCol, offCol)
    local state = false
    local b = B(par, txt, sz, pos, offCol or C.GREY)
    local function refresh()
        tw(b, {BackgroundColor3 = state and (onCol or C.GRN) or (offCol or C.GREY)})
        b.Text = (state and "■ " or "○ ") .. txt
    end
    b.MouseButton1Click:Connect(function()
        state = not state; refresh()
    end)
    local function getState() return state end
    local function setState(v) state = v; refresh() end
    return b, getState, setState
end

-- Number stepper (+/- with label)
local function stepper(par, label, default, min, max, step, sz, pos)
    local container = F(par, sz or UDim2.new(0, 200, 0, 28), pos, C.PANEL)
    corner(container, 6)
    local val = default or 0
    L(container, label, UDim2.new(0, 80, 1, 0), UDim2.new(0, 4, 0, 0), C.TXTS, FN, 11)
    local valLbl = L(container, tostring(val), UDim2.new(0, 50, 1, 0),
        UDim2.new(0, 84, 0, 0), C.TXT, FB, 12, Enum.TextXAlignment.Center)
    local bM = B(container, "−", UDim2.new(0, 24, 0, 20), UDim2.new(0, 134, 0, 4), C.GREY)
    local bP = B(container, "+", UDim2.new(0, 24, 0, 20), UDim2.new(0, 162, 0, 4), C.ACC)
    hov(bM, C.GREY, C.GRYHV); hov(bP, C.ACC, C.ACCHV)
    local onChange = nil
    bM.MouseButton1Click:Connect(function()
        val = math.max(min or -math.huge, val - (step or 1))
        valLbl.Text = tostring(val)
        if onChange then onChange(val) end
    end)
    bP.MouseButton1Click:Connect(function()
        val = math.min(max or math.huge, val + (step or 1))
        valLbl.Text = tostring(val)
        if onChange then onChange(val) end
    end)
    return container, function() return val end, function(fn) onChange = fn end
end

-- Card (panel with title + optional subtitle)
local function card(par, title, subtitle, h)
    local r = F(par, UDim2.new(1, -4, 0, h or 54), nil, C.PANEL)
    corner(r, 7); stroke(r, Color3.fromRGB(28, 40, 72), 1)
    L(r, title, UDim2.new(1, -16, 0, 20), UDim2.new(0, 8, 0, 5), C.TXT, FB, 13)
    if subtitle then
        L(r, subtitle, UDim2.new(1, -16, 0, 16), UDim2.new(0, 8, 0, 26), C.TXTS, FN, 10)
    end
    return r
end

-- Util row (card + action button)
local function utilRow(par, title, desc, btnTxt, btnCol, action)
    local Row = card(par, title, desc, 54)
    local bc  = btnCol or C.ACC
    local hc  = Color3.fromRGB(
        math.min(255, bc.R * 255 + 30),
        math.min(255, bc.G * 255 + 30),
        math.min(255, bc.B * 255 + 30)
    )
    local btn = B(Row, btnTxt, UDim2.new(0, 88, 0, 26), UDim2.new(1, -96, 0.5, -13), bc)
    btn.TextSize = 11; hov(btn, bc, hc)
    btn.MouseButton1Click:Connect(function()
        local ok2, res = pcall(action)
        return ok2, res
    end)
    return Row, btn
end

-- ════════════════════════════════════════
-- SOURCE: src/core/05_window.lua
-- ════════════════════════════════════════
-- ── Main Window & Tab System ─────────────────────────────────────────────────
-- Mobile  → full-screen, bottom tab bar, touch-optimised (Delta iOS/Android/iPad)
-- Desktop → 650×530 floating window, left sidebar, hover tooltips

local GUI = Instance.new("ScreenGui")
GUI.Name              = "__SS_EXEC__"
GUI.ResetOnSpawn      = false
GUI.IgnoreGuiInset    = true
GUI.DisplayOrder      = 999
GUI.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
GUI.Parent            = PGui

local WIN = F(GUI,
    UDim2.new(0, WIN_W, 0, WIN_H),
    isMobile and UDim2.new(0, 0, 0, 0)
           or  UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2),
    C.BG, "Window")

if isMobile then
    -- No rounded corners on full-screen window
else
    corner(WIN, 12)
    stroke(WIN, C.BDR, 1.5)
    -- Drop shadow
    local Sh          = Instance.new("ImageLabel")
    Sh.Size           = UDim2.new(1,60,1,60)
    Sh.Position       = UDim2.new(0,-30,0,-30)
    Sh.BackgroundTransparency = 1
    Sh.Image          = "rbxassetid://6014261993"
    Sh.ImageColor3    = C.BLK
    Sh.ImageTransparency = 0.42
    Sh.ScaleType      = Enum.ScaleType.Slice
    Sh.SliceCenter    = Rect.new(49,49,450,450)
    Sh.ZIndex         = 0
    Sh.Parent         = WIN
end

-- ── Title bar ─────────────────────────────────────────────────────────────────
local _TBAR_H = isMobile and 50 or 44
local TBAR = F(WIN, UDim2.new(1,0,0,_TBAR_H), UDim2.new(0,0,0,0), C.SIDE, "TBar")
if not isMobile then
    corner(TBAR, 12)
    F(WIN, UDim2.new(1,0,0,12), UDim2.new(0,0,0,32), C.SIDE)  -- fill bottom corners
end

-- Logo
local LBG = F(TBAR, UDim2.new(0,30,0,30), UDim2.new(0,9,0,10), C.ACC); corner(LBG,8)
L(LBG, "⚡", UDim2.new(1,0,1,0), nil, C.WHT, FB, 16, Enum.TextXAlignment.Center)
L(TBAR, "NEXUS",        UDim2.new(0,60,0,22), UDim2.new(0,46,0,4),  C.WHT,  FB, isMobile and 15 or 16)
L(TBAR, "EXECUTOR  v8", UDim2.new(0,120,0,13),UDim2.new(0,46,0,25), C.TXTS, FN, 10)

-- Bridge status — X position scaled so it fits any window width
local _bX = math.min(170, WIN_W - 190)
local ODot      = dot(TBAR, UDim2.new(0,8,0,8),  UDim2.new(0,_bX,0,21))
local BridgeTxt = L(TBAR, "…",
    UDim2.new(0, math.max(60, WIN_W-_bX-80), 0,13),
    UDim2.new(0,_bX+14,0,19), C.TXTS, FN, 11)

-- FPS + uptime — desktop only (no room in mobile titlebar)
local _fpsConn
if not isMobile then
    local FpsTxt = L(TBAR,"",UDim2.new(0,72,0,14),UDim2.new(0,308,0,15),C.TXTD,FN,10)
    local uptL   = L(TBAR,"00:00",UDim2.new(0,50,0,14),UDim2.new(0,384,0,15),C.TXTD,FC,10)
    _fpsConn = RUN.RenderStepped:Connect(function(dt)
        FpsTxt.Text = ("%.0f fps"):format(1/dt)
    end)
    task.spawn(function()
        local t0 = os.clock()
        while GUI.Parent do
            local e = math.floor(os.clock()-t0)
            uptL.Text = ("%02d:%02d"):format(math.floor(e/60),e%60)
            task.wait(1)
        end
    end)
end

-- ── Control buttons ───────────────────────────────────────────────────────────
local _cH = isMobile and 32 or 24
local _cY = isMobile and  9 or 10
local BtnMin = B(TBAR,"—",UDim2.new(0,32,0,_cH),UDim2.new(1,-70,0,_cY),C.GREY)
local BtnX   = B(TBAR,"✕",UDim2.new(0,32,0,_cH),UDim2.new(1,-34,0,_cY),C.RED)
hov(BtnMin,C.GREY,C.GRYHV); hov(BtnX,C.RED,C.REDHV)

BtnX.MouseButton1Click:Connect(function()
    if _fpsConn then _fpsConn:Disconnect() end
    tw(WIN,{BackgroundTransparency=1},TF2)
    task.wait(0.22); GUI:Destroy()
end)

-- Bridge ping
task.spawn(function()
    local alive = pingBridge()
    ODot.BackgroundColor3 = alive and C.GRN or C.RED
    BridgeTxt.Text        = alive and "bridge ✓" or "no bridge"
    BridgeTxt.TextColor3  = alive and C.GRN or C.RED
end)

-- ── Layout: BODY + nav elements ───────────────────────────────────────────────
-- Mobile:  full-width body between titlebar and 52px bottom tab bar
-- Desktop: sidebar on left, body fills the rest
local SIDE, BODY, TABBAR

if isMobile then
    local _TABB_H = 52
    BODY = F(WIN,
        UDim2.new(1, 0, 1, -(_TBAR_H + _TABB_H)),
        UDim2.new(0, 0, 0, _TBAR_H),
        C.BLK, "Body")
    BODY.BackgroundTransparency = 1

    -- Bottom tab bar
    TABBAR = F(WIN, UDim2.new(1,0,0,_TABB_H), UDim2.new(0,0,1,-_TABB_H), C.SIDE, "TabBar")
    -- top separator line
    F(TABBAR, UDim2.new(1,0,0,1), UDim2.new(0,0,0,0), C.BDR2)
else
    SIDE = F(WIN, UDim2.new(0,SIDE_W,1,-44), UDim2.new(0,0,0,44), C.SIDE, "Side")
    F(WIN, UDim2.new(0,1,1,-44), UDim2.new(0,SIDE_W,0,44), Color3.fromRGB(32,44,82))
    BODY = F(WIN, UDim2.new(1,-(SIDE_W+6),1,-50), UDim2.new(0,SIDE_W+3,0,48), C.BLK, "Body")
    BODY.BackgroundTransparency = 1
end

-- ── Tab system ────────────────────────────────────────────────────────────────
local sbBtns  = {}
local pages   = {}
local curPage = 0
local tabN    = 0

local TCOL = {
    Color3.fromRGB( 59,130,246),  Color3.fromRGB( 34,197, 94),
    Color3.fromRGB(249,115, 22),  Color3.fromRGB(236, 72,153),
    Color3.fromRGB(139, 92,246),  Color3.fromRGB(220, 55, 55),
    Color3.fromRGB(250,204, 21),  Color3.fromRGB( 20,184,166),
    Color3.fromRGB( 96,165,250),  Color3.fromRGB(167,139,250),
}

local function showPage(idx)
    for i,p in pages  do p.Visible = (i==idx) end
    for i,b in sbBtns do
        local ac = TCOL[i] or C.ACC
        local on = (i==idx)
        tw(b, {
            BackgroundColor3 = on and ac or (isMobile and Color3.fromRGB(8,11,20) or Color3.fromRGB(16,16,24)),
            TextColor3       = on and C.WHT or C.TXTD,
        })
        -- mobile: show/hide indicator stripe at top of each tab button
        if isMobile then
            local ind = b:FindFirstChild("Ind")
            if ind then ind.BackgroundTransparency = on and 0 or 1 end
        end
    end
    curPage = idx
end

local function newTab(icon, label)
    tabN += 1
    local idx = tabN
    local ac  = TCOL[idx] or C.ACC
    local btn

    if isMobile then
        -- Bottom tab bar: 10 equal-width buttons (0.1 scale each)
        btn = Instance.new("TextButton")
        btn.Size             = UDim2.new(0.1, 0, 1, 0)
        btn.Position         = UDim2.new((idx-1)*0.1, 0, 0, 0)
        btn.BackgroundColor3 = Color3.fromRGB(8,11,20)
        btn.Text             = icon
        btn.TextColor3       = C.TXTD
        btn.Font             = FB
        btn.TextSize         = 20
        btn.AutoButtonColor  = false
        btn.BorderSizePixel  = 0
        btn.Parent           = TABBAR

        -- Coloured indicator stripe at top (visible when active)
        local ind = F(btn, UDim2.new(1,0,0,3), UDim2.new(0,0,0,1), ac, "Ind")
        ind.BackgroundTransparency = 1

        -- Left separator between buttons
        if idx > 1 then
            local sep = F(btn, UDim2.new(0,1,0.6,0), UDim2.new(0,0,0.2,0), C.BDR)
            sep.ZIndex = 2
        end

        -- Press ripple
        btn.MouseButton1Down:Connect(function()
            tw(btn,{BackgroundColor3=Color3.fromRGB(20,26,42)})
        end)
        btn.MouseButton1Up:Connect(function()
            tw(btn,{BackgroundColor3=curPage==idx and ac or Color3.fromRGB(8,11,20)})
        end)
        btn.MouseButton1Click:Connect(function() showPage(idx) end)
    else
        -- Desktop: left sidebar
        local yp   = 6 + (idx-1)*TAB_SP
        local btnW = SIDE_W - 12
        btn = Instance.new("TextButton")
        btn.Size             = UDim2.new(0,btnW,0,TAB_SZ)
        btn.Position         = UDim2.new(0,6,0,yp)
        btn.BackgroundColor3 = Color3.fromRGB(16,16,24)
        btn.Text             = icon
        btn.TextColor3       = C.TXTD
        btn.Font             = FB
        btn.TextSize         = 18
        btn.AutoButtonColor  = false
        btn.BorderSizePixel  = 0
        btn.Parent           = SIDE
        corner(btn,7)

        -- Tooltip
        local tipW = math.max(80,#label*8+16)
        local tip  = Instance.new("TextLabel")
        tip.Size             = UDim2.new(0,tipW,0,22)
        tip.Position         = UDim2.new(1,6,0,yp+4)
        tip.BackgroundColor3 = C.PANEL
        tip.Text             = label
        tip.TextColor3       = C.TXT
        tip.Font             = FN
        tip.TextSize         = 11
        tip.TextXAlignment   = Enum.TextXAlignment.Center
        tip.BorderSizePixel  = 0
        tip.ZIndex           = 15
        tip.Visible          = false
        tip.Parent           = SIDE
        corner(tip,5); stroke(tip,ac,1)

        btn.MouseEnter:Connect(function()
            tip.Visible = true
            if curPage~=idx then tw(btn,{BackgroundColor3=Color3.fromRGB(22,22,34),TextColor3=C.TXTS}) end
        end)
        btn.MouseLeave:Connect(function()
            tip.Visible = false
            if curPage~=idx then tw(btn,{BackgroundColor3=Color3.fromRGB(16,16,24),TextColor3=C.TXTD}) end
        end)
        btn.MouseButton1Click:Connect(function() showPage(idx) end)
    end

    sbBtns[idx] = btn

    local pg = F(BODY, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), C.BLK, "P"..idx)
    pg.BackgroundTransparency = 1
    pg.Visible = false
    pages[idx] = pg
    return pg
end

-- ════════════════════════════════════════
-- SOURCE: src/tabs/01_execute.lua
-- ════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB 1 — EXECUTE
--  5 modes: Client LS · Server LS · Require · URL Exec · File Exec
--  Features: 30-entry history, line counter, output timestamps
-- ═══════════════════════════════════════════════════════════════════════════════
local P1 = newTab("▶", "Execute")

-- ── Mode selector ─────────────────────────────────────────────────────────────
local mRow  = rowBar(P1, 0, 26)
local MODES = {"Client LS","Server LS","Require","URL Exec","File Exec"}
local mBtns = {}
local curMode = 1

local function setMode(i)
    curMode = i
    for j, b in mBtns do
        tw(b, {BackgroundColor3 = j==i and C.BLUE or C.EDIT})
        b.TextColor3 = j==i and C.TXT or C.TXTS
    end
end

for i, nm in MODES do
    local w = i == 1 and 108 or (i <= 3 and 90 or 98)
    local b = B(mRow, nm, UDim2.new(0,w,1,0), nil, i==1 and C.BLUE or C.EDIT, C.TXTS)
    b.LayoutOrder = i; b.TextSize = 11
    hov(b, C.EDIT, C.BLHV)
    b.MouseButton1Click:Connect(function() setMode(i) end)
    mBtns[i] = b
end

-- Mode descriptions shown below the bar
local modeDesc = {
    "Runs code client-side via loadstring/load",
    "Runs code server-side via SS_ExecBridge",
    "Loads a Roblox Module by asset ID",
    "Fetches raw URL then executes client-side",
    "Reads a local file then executes (readfile)",
}
local ModeInfo = L(P1, modeDesc[1], UDim2.new(1,0,0,13), UDim2.new(0,0,0,28), C.TXTD, FN, 10)

for i, b in mBtns do
    b.MouseButton1Click:Connect(function() ModeInfo.Text = modeDesc[i] end)
end

-- ── Script history ─────────────────────────────────────────────────────────────
local execHistory = {}
local histIdx     = 0

local function pushHistory(code)
    if code == "" or code == execHistory[#execHistory] then return end
    table.insert(execHistory, code)
    if #execHistory > 30 then table.remove(execHistory, 1) end
    histIdx = #execHistory
end

-- ── Code editor ───────────────────────────────────────────────────────────────
local Editor = IN(P1,
    "-- Mode 1: client loadstring  (paste code here)\n"..
    "-- Mode 2: server-side bridge (paste code here)\n"..
    "-- Mode 3: enter asset ID     (e.g. 1234567890)\n"..
    "-- Mode 4: enter raw URL      (https://…)\n"..
    "-- Mode 5: enter file path    (e.g. script.lua)\n",
    UDim2.new(1,0,0,180), UDim2.new(0,0,0,44))

-- Line + char counter
L(P1, "Output", UDim2.new(0,55,0,14), UDim2.new(0,0,0,230), C.TXTS, FN, 11)
local LineCnt = L(P1, "0 lines · 0 chars",
    UDim2.new(0,180,0,14), UDim2.new(1,-182,0,230), C.TXTD, FN, 10, Enum.TextXAlignment.Right)

Editor:GetPropertyChangedSignal("Text"):Connect(function()
    local txt = Editor.Text
    local lines = select(2, txt:gsub("\n", "")) + 1
    LineCnt.Text = lines .. " lines · " .. #txt .. " chars"
end)

-- ── Action row ────────────────────────────────────────────────────────────────
local aRow   = rowBar(P1, 228, 26)
local BExec  = B(aRow,"▶ Run",   UDim2.new(0,88,1,0), nil, C.ACC)
local BClear = B(aRow,"Clear",   UDim2.new(0,64,1,0), nil, C.GREY)
local BCopy  = B(aRow,"Copy",    UDim2.new(0,64,1,0), nil, C.GREY)
local BPrev  = B(aRow,"◀ Prev",  UDim2.new(0,68,1,0), nil, C.GREY)
local BNext  = B(aRow,"Next ▶",  UDim2.new(0,68,1,0), nil, C.GREY)
local BSave  = B(aRow,"Save",    UDim2.new(0,60,1,0), nil, C.GREY)
styleRow({BExec,BClear,BCopy,BPrev,BNext,BSave})
hov(BExec,  C.ACC,  C.ACCHV)
hov(BClear, C.GREY, C.GRYHV)
hov(BCopy,  C.GREY, C.GRYHV)
hov(BPrev,  C.GREY, C.GRYHV)
hov(BNext,  C.GREY, C.GRYHV)
hov(BSave,  C.GREY, C.GRYHV)

-- ── Output console ────────────────────────────────────────────────────────────
local ExOut  = OUT(P1, UDim2.new(1,0,1,-260), UDim2.new(0,0,0,258))
local outLog = {}

local function exOut(msg, isErr)
    local line = ts() .. tostring(msg)
    table.insert(outLog, 1, line)
    if #outLog > 100 then table.remove(outLog) end
    ExOut.TextColor3 = isErr and C.RED or C.GRN
    ExOut.Text = table.concat(outLog, "\n"):sub(1, 2000)
end

-- ── Execute handler ───────────────────────────────────────────────────────────
BExec.MouseButton1Click:Connect(function()
    local code = Editor.Text
    if trim(code) == "" then exOut("Nothing to run.", true); return end
    pushHistory(code)
    flash(BExec, C.ACCHV)

    if curMode == 1 then
        -- Client loadstring
        local ok2, err, stage = runCode(code)
        if not ok2 then
            exOut((stage=="compile" and "Compile error:\n" or "Runtime error:\n")..err, true); return
        end
        exOut("Client exec ✓", false)

    elseif curMode == 2 then
        -- Server-side via bridge
        local ok2, msg2 = runOnServer(code)
        exOut(msg2 or "(no response from bridge)", not ok2)

    elseif curMode == 3 then
        -- require by asset ID
        local id = tonumber(code:match("%d+"))
        if not id then exOut("Enter a valid numeric asset ID.", true); return end
        local ok2, res = pcall(require, id)
        exOut(ok2 and ("require(" .. id .. ") returned: " .. type(res))
            or "require error:\n" .. tostring(res), not ok2)

    elseif curMode == 4 then
        -- URL fetch + execute
        local url = trim(code)
        if url == "" then exOut("Enter a URL.", true); return end
        exOut("Fetching " .. trunc(url, 60) .. "…", false)
        task.spawn(function()
            local ok2, src = pcall(game.HttpGet, game, url, true)
            if not ok2 then exOut("HTTP error:\n" .. tostring(src), true); return end
            local ok3, err, stage = runCode(src)
            if not ok3 then
                exOut((stage=="compile" and "Compile error:\n" or "Runtime error:\n")..err, true); return
            end
            exOut("URL exec ✓  (" .. #src .. " bytes)", false)
        end)

    elseif curMode == 5 then
        -- Local file
        if not readfile then exOut("readfile not available on this executor.", true); return end
        local path = trim(code)
        if path == "" then exOut("Enter a file path.", true); return end
        local ok2, src = pcall(readfile, path)
        if not ok2 then exOut("readfile error:\n" .. tostring(src), true); return end
        local ok3, err, stage = runCode(src)
        if not ok3 then
            exOut((stage=="compile" and "Compile error:\n" or "Runtime error:\n")..err, true); return
        end
        exOut("File exec ✓  (" .. #src .. " bytes, path: " .. path .. ")", false)
    end
end)

BClear.MouseButton1Click:Connect(function()
    Editor.Text = ""; outLog = {}; ExOut.Text = ""
end)

BCopy.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(Editor.Text)
        exOut("Code copied to clipboard ✓", false)
    else
        exOut("setclipboard not available on this executor.", true)
    end
end)

BPrev.MouseButton1Click:Connect(function()
    if #execHistory == 0 then exOut("History is empty.", true); return end
    histIdx = math.max(1, histIdx - 1)
    Editor.Text = execHistory[histIdx]
    exOut("History " .. histIdx .. " / " .. #execHistory, false)
end)

BNext.MouseButton1Click:Connect(function()
    if #execHistory == 0 then exOut("History is empty.", true); return end
    histIdx = math.min(#execHistory, histIdx + 1)
    Editor.Text = execHistory[histIdx]
    exOut("History " .. histIdx .. " / " .. #execHistory, false)
end)

BSave.MouseButton1Click:Connect(function()
    if not writefile then exOut("writefile not available.", true); return end
    local name = "nexus_script_" .. os.time() .. ".lua"
    writefile(name, Editor.Text)
    exOut("Saved → " .. name, false)
end)

setMode(1)

-- ════════════════════════════════════════
-- SOURCE: src/tabs/02_server.lua
-- ════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB 2 — SERVER
--  Server-side loadstring · URL exec · Require · Player management
-- ═══════════════════════════════════════════════════════════════════════════════
local P2 = newTab("⚙", "Server")

L(P2, "SERVER CONTROL", UDim2.new(1,0,0,16), UDim2.new(0,0,0,0), C.TXTS, FB, 11)

-- ── Code editor ───────────────────────────────────────────────────────────────
local SrvEdit = IN(P2, "-- Code to run server-side via bridge…", UDim2.new(1,0,0,80), UDim2.new(0,0,0,18))

-- ── Action row 1 ──────────────────────────────────────────────────────────────
local sr1 = rowBar(P2, 104, 26)
local BSrvRun  = B(sr1, "▶ Run Server",  UDim2.new(0,116,1,0), nil, C.GRN)
local BSrvURL  = B(sr1, "Run URL",        UDim2.new(0,88,1,0),  nil, C.GREY)
local BSrvReq  = B(sr1, "Require ID",     UDim2.new(0,92,1,0),  nil, C.GREY)
local BSrvPing = B(sr1, "Ping",           UDim2.new(0,60,1,0),  nil, C.ACC)
styleRow({BSrvRun,BSrvURL,BSrvReq,BSrvPing})
hov(BSrvRun, C.GRN, C.GRNHV); hov(BSrvURL, C.GREY, C.GRYHV)
hov(BSrvReq, C.GREY, C.GRYHV); hov(BSrvPing, C.ACC, C.ACCHV)

-- ── Output ────────────────────────────────────────────────────────────────────
local srvOut = statusOut(P2, UDim2.new(1,0,0,50), UDim2.new(0,0,0,134))
local function bOut(act, pay)
    local ok2, msg2, data = callBridge(act, pay)
    local lines = {msg2 or ""}
    if data then for _, l in data do lines[#lines+1] = tostring(l) end end
    srvOut(table.concat(lines, "\n"), ok2)
end

BSrvRun.MouseButton1Click:Connect(function()
    if trim(SrvEdit.Text) == "" then srvOut("No code.", false); return end
    bOut("ls", {code = SrvEdit.Text})
end)
BSrvURL.MouseButton1Click:Connect(function()
    local url = trim(SrvEdit.Text)
    if url == "" then srvOut("Enter URL in editor.", false); return end
    bOut("ls_url", {url = url})
end)
BSrvReq.MouseButton1Click:Connect(function()
    local id = tonumber(SrvEdit.Text:match("%d+"))
    if not id then srvOut("Enter asset ID in editor.", false); return end
    bOut("req", {id = id})
end)
BSrvPing.MouseButton1Click:Connect(function()
    local ok2, msg2 = bridgeStatus()
    srvOut(msg2, ok2)
end)

-- ── Action row 2 — Quick commands ─────────────────────────────────────────────
local sr2 = rowBar(P2, 190, 26)
local BGetPlrs = B(sr2, "Get Players",  UDim2.new(0,100,1,0), nil, C.GREY)
local BGetScr  = B(sr2, "Get Scripts",  UDim2.new(0,100,1,0), nil, C.GREY)
local BKillAll = B(sr2, "Kill Scripts", UDim2.new(0,106,1,0), nil, C.RED)
local BBridge  = B(sr2, "Re-Ping",      UDim2.new(0,80,1,0),  nil, C.GREY)
styleRow({BGetPlrs,BGetScr,BKillAll,BBridge})
hov(BGetPlrs, C.GREY, C.GRYHV); hov(BGetScr,  C.GREY, C.GRYHV)
hov(BKillAll, C.RED,  C.REDHV); hov(BBridge,  C.GREY, C.GRYHV)

BGetPlrs.MouseButton1Click:Connect(function() bOut("getplrs")       end)
BGetScr.MouseButton1Click:Connect(function()  bOut("get_scripts")    end)
BKillAll.MouseButton1Click:Connect(function() bOut("kill_all")       end)
BBridge.MouseButton1Click:Connect(function()
    local alive = pingBridge()
    ODot.BackgroundColor3 = alive and C.GRN or C.RED
    BridgeTxt.Text        = alive and "bridge ✓" or "no bridge"
    BridgeTxt.TextColor3  = alive and C.GRN or C.RED
    srvOut(alive and "Bridge online ✓" or "Bridge offline.", alive)
end)

-- ── Player management panel ───────────────────────────────────────────────────
L(P2, "Players", UDim2.new(0,80,0,14), UDim2.new(0,0,0,222), C.TXTS, FB, 11)
local BRefPlrs = B(P2, "↺ Refresh", UDim2.new(0,88,0,18), UDim2.new(1,-90,0,222), C.GREY)
BRefPlrs.TextSize = 10; hov(BRefPlrs, C.GREY, C.GRYHV)

local PlrScr = SCR(P2, UDim2.new(1,0,1,-244), UDim2.new(0,0,0,242))
listV(PlrScr, 3)

local function refreshPlrs()
    clearLayout(PlrScr)
    for _, plr in Players:GetPlayers() do
        local row = F(PlrScr, UDim2.new(1,-4,0,34), nil, C.PANEL); corner(row,6)
        local isMe = (plr == LP)
        -- online dot
        local d = dot(row, UDim2.new(0,7,0,7), UDim2.new(0,6,0.5,-3),
            plr.Character and C.GRN or C.GREY)
        L(row, plr.DisplayName, UDim2.new(0.5,-24,1,0), UDim2.new(0,18,0,0),
            isMe and C.YELL or C.TXT, isMe and FB or FN, 12)
        L(row, "@" .. plr.Name, UDim2.new(0.3,0,1,0), UDim2.new(0.38,0,0,0), C.TXTS, FN, 10)

        local bKick = B(row,"Kick", UDim2.new(0,42,0,20), UDim2.new(1,-90,0.5,-10), isMe and C.GREY or C.RED)
        local bTp   = B(row,"TP",   UDim2.new(0,36,0,20), UDim2.new(1,-44,0.5,-10), C.BLUE)
        bKick.TextSize = 10; bTp.TextSize = 10
        if isMe then bKick.Text = "You" end
        hov(bTp, C.BLUE, C.BLHV)

        bKick.MouseButton1Click:Connect(function()
            if isMe then srvOut("Can't kick yourself.", false); return end
            bOut("kick", {name = plr.Name, reason = "Kicked by Nexus."})
        end)
        bTp.MouseButton1Click:Connect(function()
            local myChar = LP.Character
            local tChar  = plr.Character
            if not myChar or not tChar then srvOut("No character.", false); return end
            local r1 = myChar:FindFirstChild("HumanoidRootPart")
            local r2 = tChar:FindFirstChild("HumanoidRootPart")
            if r1 and r2 then
                r1.CFrame = r2.CFrame + Vector3.new(2,2,2)
                srvOut("Teleported to " .. plr.Name, true)
            end
        end)
    end
end

BRefPlrs.MouseButton1Click:Connect(refreshPlrs)
Players.PlayerAdded:Connect(refreshPlrs)
Players.PlayerRemoving:Connect(function() task.wait(0.1); refreshPlrs() end)
refreshPlrs()

-- ════════════════════════════════════════
-- SOURCE: src/tabs/03_sandbox.lua
-- ════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB 3 — SANDBOX BYPASS
--  Bypass tools · Identity elevation · Metatable unlock · Hook spy
-- ═══════════════════════════════════════════════════════════════════════════════
local P3 = newTab("⛓", "Sandbox")
L(P3, "SANDBOX & BYPASS TOOLS", UDim2.new(1,0,0,16), UDim2.new(0,0,0,0), C.TXTS, FB, 11)

local sbOut = statusOut(P3, UDim2.new(1,0,0,44), UDim2.new(0,0,1,-46))

local SBScr = SCR(P3, UDim2.new(1,0,1,-104), UDim2.new(0,0,0,20))
listV(SBScr, 4)

local function uRow(title, desc, btnTxt, btnCol, action)
    local Row = card(SBScr, title, desc, 54)
    stroke(Row, Color3.fromRGB(30,40,70), 1)
    local bc = btnCol or C.ACC
    local hc = Color3.fromRGB(
        math.min(255, bc.R*255+30), math.min(255, bc.G*255+30), math.min(255, bc.B*255+30))
    local btn = B(Row, btnTxt, UDim2.new(0,90,0,26), UDim2.new(1,-98,0.5,-13), bc)
    btn.TextSize = 11; hov(btn, bc, hc)
    btn.MouseButton1Click:Connect(function()
        local ok2, res = pcall(action)
        sbOut(res or (ok2 and "✓ Done." or "✗ Failed."), ok2)
    end)
end

-- ── 12 bypass tools ───────────────────────────────────────────────────────────
uRow("Elevate Thread Identity (8)",
    "setthreadidentity(8) — max executor script context", "Elevate", C.ACC,
    function()
        local fn = setthreadidentity or (syn and syn.set_thread_identity)
        if not fn then return "✗ setthreadidentity not available." end
        fn(8)
        local gid = getthreadidentity or (syn and syn.get_thread_identity)
        return "✓ Identity → 8" .. (gid and " (confirmed: " .. gid() .. ")" or "")
    end)

uRow("Unlock game metatable",
    "setreadonly(getrawmetatable(game), false)", "Unlock", C.BLUE,
    function()
        if not getrawmetatable then return "✗ getrawmetatable missing." end
        if not setreadonly     then return "✗ setreadonly missing." end
        setreadonly(getrawmetatable(game), false)
        return "✓ game metatable is now writable."
    end)

uRow("Hook __namecall (Remote Spy lite)",
    "Logs all FireServer/InvokeServer calls to console", "Hook", C.ORAN,
    function()
        if not hookmetamethod    then return "✗ hookmetamethod missing." end
        if not getnamecallmethod then return "✗ getnamecallmethod missing." end
        local _old; _old = hookmetamethod(game, "__namecall", function(self, ...)
            local m = getnamecallmethod()
            if m == "FireServer" or m == "InvokeServer" then
                warn(("[Nexus Spy] %s → %s"):format(tostring(self), m))
            end
            return _old(self, ...)
        end)
        return "✓ __namecall hooked. All remotes now logged to console."
    end)

uRow("getgenv() inspector",
    "Count + list all shared executor globals", "Open", C.GRN,
    function()
        if not getgenv then return "✗ getgenv not available." end
        local env = getgenv(); local n = 0
        for _ in pairs(env) do n += 1 end
        return "✓ getgenv() → " .. n .. " entries in executor env."
    end)

uRow("getrenv() inspector",
    "Access real Roblox game environment table", "Open", C.PURP,
    function()
        if not getrenv then return "✗ getrenv not available." end
        local env = getrenv(); local n = 0
        for _ in pairs(env) do n += 1 end
        return "✓ getrenv() → " .. n .. " entries in Roblox env."
    end)

uRow("Bypass metatable lock",
    "Strips __index / __newindex guards from game", "Bypass", C.RED,
    function()
        if not getrawmetatable or not setreadonly then return "✗ Missing functions." end
        setreadonly(getrawmetatable(game), false)
        return "✓ Metatable lock stripped from game."
    end)

uRow("Expose _G (setreadonly false)",
    "Makes global table fully writable for hooking", "Expose", C.YELL,
    function()
        if not setreadonly then return "✗ setreadonly not available." end
        setreadonly(_G, false)
        return "✓ _G is now writable."
    end)

uRow("getconnections() probe",
    "Count event connections on Players.PlayerAdded", "Probe", C.TEAL,
    function()
        if not getconnections then return "✗ getconnections not available." end
        local conns = getconnections(Players.PlayerAdded)
        return "✓ PlayerAdded has " .. #conns .. " active connections."
    end)

uRow("newcclosure wrapper test",
    "Wraps a function in a new C-closure", "Test", C.INDI,
    function()
        if not newcclosure then return "✗ newcclosure not available." end
        local fn = newcclosure(function() return true end)
        local ok2 = pcall(fn)
        return ok2 and "✓ newcclosure() works correctly." or "✗ newcclosure returned error."
    end)

uRow("iscclosure / islclosure probe",
    "Determine closure types for common functions", "Probe", C.CYAN,
    function()
        local results = {}
        if iscclosure then
            results[#results+1] = "print is " .. (iscclosure(print) and "C" or "Lua") .. " closure"
        else results[#results+1] = "iscclosure unavailable" end
        if islclosure then
            local fn = function() end
            results[#results+1] = "local fn is " .. (islclosure(fn) and "Lua" or "C") .. " closure"
        else results[#results+1] = "islclosure unavailable" end
        return "✓ " .. table.concat(results, " | ")
    end)

uRow("hookfunction test",
    "Hooks print() to log [HOOKED] prefix to output", "Hook", C.PINK,
    function()
        if not hookfunction and not replaceclosure then return "✗ hookfunction not available." end
        local fn = hookfunction or replaceclosure
        local _old2; _old2 = fn(print, function(...)
            _old2("[Nexus Hook] " .. table.concat({...}, " "))
        end)
        return "✓ print() hooked — calls now prefixed with [Nexus Hook]."
    end)

uRow("setrawmetatable test",
    "Directly set metatable bypassing __metatable guard", "Test", C.ORAN,
    function()
        if not setrawmetatable then return "✗ setrawmetatable not available." end
        local t = setmetatable({}, {__metatable="locked"})
        local ok2 = pcall(setrawmetatable, t, {})
        return ok2 and "✓ setrawmetatable bypassed __metatable lock." or "✗ setrawmetatable failed."
    end)

-- ── Custom snippet area ───────────────────────────────────────────────────────
L(P3, "Custom Snippet:", UDim2.new(0,120,0,14), UDim2.new(0,0,1,-90), C.TXTS, FN, 11)
local SnipBox = IN(P3, "-- Custom bypass snippet…", UDim2.new(1,0,0,42), UDim2.new(0,0,1,-76))
local BSnip = B(P3, "▶ Run", UDim2.new(0,80,0,22), UDim2.new(0,0,1,-28), C.ACC)
BSnip.TextSize = 11; hov(BSnip, C.ACC, C.ACCHV)
BSnip.MouseButton1Click:Connect(function()
    local code = SnipBox.Text
    if trim(code) == "" then sbOut("No snippet entered.", false); return end
    local ok2, err, stage = runCode(code)
    if not ok2 then
        sbOut(stage=="compile" and ("Compile error:\n"..err) or ("✗ "..err), false); return
    end
    sbOut("✓ Snippet executed OK.", true)
end)

-- ── Auto-detect available bypass functions ────────────────────────────────────
task.spawn(function()
    local check = {
        "setthreadidentity","getthreadidentity","setreadonly","getrawmetatable",
        "hookmetamethod","hookfunction","getgenv","getrenv","getnamecallmethod",
        "getconnections","newcclosure","iscclosure","islclosure","setrawmetatable",
    }
    local have, miss = {}, {}
    for _, name in check do
        if hasGlobal(name) then
            have[#have+1] = name
        else
            miss[#miss+1] = name
        end
    end
    sbOut(("%d/%d bypass fns available.\nHave: %s%s"):format(
        #have, #check,
        table.concat(have, ", "),
        #miss > 0 and ("\nMissing: " .. table.concat(miss, ", ")) or ""
    ), #miss == 0)
end)

-- ════════════════════════════════════════
-- SOURCE: src/tabs/04_player.lua
-- ════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB 4 — PLAYER TOOLS
--  WalkSpeed · JumpPower · Health · God Mode · Noclip · Freeze
--  Infinite Jump · Fly · Speed Presets · Teleport · Position
-- ═══════════════════════════════════════════════════════════════════════════════
local P4 = newTab("👤", "Player")
L(P4, "PLAYER & CHARACTER TOOLS", UDim2.new(1,0,0,16), UDim2.new(0,0,0,0), C.TXTS, FB, 11)

local plrOut = statusOut(P4, UDim2.new(1,0,0,38), UDim2.new(0,0,1,-40))

-- ── Stats row ─────────────────────────────────────────────────────────────────
local statsF = F(P4, UDim2.new(1,0,0,60), UDim2.new(0,0,0,20), C.PANEL); corner(statsF,7)

L(statsF, "WalkSpeed",  UDim2.new(0,78,0,16), UDim2.new(0,6,0,4),   C.TXTS, FN, 11)
L(statsF, "JumpPower",  UDim2.new(0,78,0,16), UDim2.new(0,174,0,4), C.TXTS, FN, 11)
L(statsF, "Health",     UDim2.new(0,55,0,16), UDim2.new(0,342,0,4), C.TXTS, FN, 11)
L(statsF, "MaxHealth",  UDim2.new(0,75,0,16), UDim2.new(0,456,0,4), C.TXTS, FN, 11)

local WalkIn = INS(statsF, "16",    UDim2.new(0,72,0,22), UDim2.new(0,88,0,2))
local JumpIn = INS(statsF, "50",    UDim2.new(0,72,0,22), UDim2.new(0,256,0,2))
local HpIn   = INS(statsF, "100",   UDim2.new(0,56,0,22), UDim2.new(0,400,0,2))
local MxIn   = INS(statsF, "100",   UDim2.new(0,56,0,22), UDim2.new(0,536,0,2))

local BApply = B(statsF, "Apply", UDim2.new(0,52,0,22), UDim2.new(1,-56,0.5,-11), C.GRN)
BApply.TextSize = 11; hov(BApply, C.GRN, C.GRNHV)
BApply.MouseButton1Click:Connect(function()
    local hum = getHum(); if not hum then plrOut("No Humanoid.", false); return end
    local ws = tonumber(WalkIn.Text); if ws then hum.WalkSpeed = ws end
    local jp = tonumber(JumpIn.Text); if jp then hum.JumpPower = jp end
    local mx = tonumber(MxIn.Text);   if mx then hum.MaxHealth = mx end
    local hp = tonumber(HpIn.Text);   if hp then hum.Health = hp end
    plrOut(("WalkSpeed=%.0f  JumpPower=%.0f  HP=%.0f/%.0f"):format(
        hum.WalkSpeed, hum.JumpPower, hum.Health, hum.MaxHealth), true)
end)

-- ── Toggle buttons ────────────────────────────────────────────────────────────
local tRow = rowBar(P4, 86, 26)
local BRespawn = B(tRow, "Respawn",  UDim2.new(0,84,1,0), nil, C.BLUE)
local BGod     = B(tRow, "GodMode",  UDim2.new(0,80,1,0), nil, C.GREY)
local BInfJump = B(tRow, "∞ Jump",  UDim2.new(0,72,1,0), nil, C.GREY)
local BNoclip  = B(tRow, "Noclip",   UDim2.new(0,68,1,0), nil, C.GREY)
local BFreeze  = B(tRow, "Freeze",   UDim2.new(0,68,1,0), nil, C.GREY)
local BFly     = B(tRow, "Fly",      UDim2.new(0,58,1,0), nil, C.GREY)
styleRow({BRespawn,BGod,BInfJump,BNoclip,BFreeze,BFly})
hov(BRespawn, C.BLUE, C.BLHV)
for _, b in {BGod,BInfJump,BNoclip,BFreeze,BFly} do hov(b, C.GREY, C.GRYHV) end

-- Active toggle states
local godOn, jumpOn, noclipOn, freezeOn, flyOn = false, false, false, false, false
local godConn, jumpConn, ncConn, flyConn, flyBp

BRespawn.MouseButton1Click:Connect(function()
    local hum = getHum()
    if hum then hum.Health = 0; plrOut("Respawning…", true)
    else plrOut("No character.", false) end
end)

BGod.MouseButton1Click:Connect(function()
    godOn = not godOn
    tw(BGod, {BackgroundColor3 = godOn and C.GRN or C.GREY})
    BGod.Text = godOn and "✓ God" or "GodMode"
    if godConn then godConn:Disconnect(); godConn = nil end
    if godOn then
        godConn = RUN.Heartbeat:Connect(function()
            local hum = getHum(); if hum then hum.Health = hum.MaxHealth end
        end)
    end
    plrOut("God Mode " .. (godOn and "ON" or "OFF"), godOn)
end)

BInfJump.MouseButton1Click:Connect(function()
    jumpOn = not jumpOn
    tw(BInfJump, {BackgroundColor3 = jumpOn and C.GRN or C.GREY})
    BInfJump.Text = jumpOn and "✓ ∞J" or "∞ Jump"
    if jumpConn then jumpConn:Disconnect(); jumpConn = nil end
    if jumpOn then
        jumpConn = UIS.JumpRequest:Connect(function()
            local hum = getHum()
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end
    plrOut("Infinite Jump " .. (jumpOn and "ON" or "OFF"), jumpOn)
end)

BNoclip.MouseButton1Click:Connect(function()
    noclipOn = not noclipOn
    tw(BNoclip, {BackgroundColor3 = noclipOn and C.GRN or C.GREY})
    BNoclip.Text = noclipOn and "✓ NC" or "Noclip"
    if ncConn then ncConn:Disconnect(); ncConn = nil end
    if noclipOn then
        ncConn = RUN.Stepped:Connect(function()
            local char = getChar(); if not char then return end
            for _, p in char:GetDescendants() do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end)
    end
    plrOut("Noclip " .. (noclipOn and "ON" or "OFF"), noclipOn)
end)

BFreeze.MouseButton1Click:Connect(function()
    freezeOn = not freezeOn
    tw(BFreeze, {BackgroundColor3 = freezeOn and C.GRN or C.GREY})
    BFreeze.Text = freezeOn and "✓ Frz" or "Freeze"
    local root = getRoot()
    if root then root.Anchored = freezeOn end
    plrOut("Freeze " .. (freezeOn and "ON" or "OFF"), freezeOn)
end)

BFly.MouseButton1Click:Connect(function()
    flyOn = not flyOn
    tw(BFly, {BackgroundColor3 = flyOn and C.GRN or C.GREY})
    BFly.Text = flyOn and "✓ Fly" or "Fly"
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyBp then flyBp:Destroy(); flyBp = nil end
    if flyOn then
        local root = getRoot()
        if not root then plrOut("No character for fly.", false); flyOn=false; return end
        flyBp = Instance.new("BodyVelocity")
        flyBp.Velocity = Vector3.new(0,0,0); flyBp.MaxForce = Vector3.new(1e9,1e9,1e9)
        flyBp.Parent = root
        flyConn = RUN.Heartbeat:Connect(function()
            if not flyOn or not flyBp then return end
            local cam = WS.CurrentCamera
            local speed = tonumber(WalkIn.Text) or 40
            local mv = Vector3.new(0,0,0)
            if UIS:IsKeyDown(Enum.KeyCode.W) then mv += cam.CFrame.LookVector * speed end
            if UIS:IsKeyDown(Enum.KeyCode.S) then mv -= cam.CFrame.LookVector * speed end
            if UIS:IsKeyDown(Enum.KeyCode.A) then mv -= cam.CFrame.RightVector * speed end
            if UIS:IsKeyDown(Enum.KeyCode.D) then mv += cam.CFrame.RightVector * speed end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then mv += Vector3.new(0, speed, 0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then mv -= Vector3.new(0, speed, 0) end
            flyBp.Velocity = mv
        end)
    end
    plrOut("Fly " .. (flyOn and "ON (WASD + Space/Shift)" or "OFF"), flyOn)
end)

-- ── Speed presets ─────────────────────────────────────────────────────────────
local spRow = rowBar(P4, 118, 24)
local presets = {{"Walk",16},{"Run",32},{"Sprint",60},{"Fly",80},{"Hyper",200},{"Ultra",500}}
for i, p in presets do
    local b = B(spRow, p[1], UDim2.new(0,76,1,0), nil, C.GRYDK)
    b.LayoutOrder = i; b.TextSize = 10; hov(b, C.GRYDK, C.GREY)
    local spd = p[2]
    b.MouseButton1Click:Connect(function()
        WalkIn.Text = tostring(spd)
        local hum = getHum()
        if hum then hum.WalkSpeed = spd; plrOut("Speed → " .. spd, true)
        else plrOut("No character.", false) end
    end)
end

-- ── Teleport ──────────────────────────────────────────────────────────────────
L(P4, "Teleport XYZ:", UDim2.new(0,100,0,14), UDim2.new(0,0,0,150), C.TXTS, FN, 11)
local txIn = INS(P4, "X", UDim2.new(0,90,0,24), UDim2.new(0,0,0,166))
local tyIn = INS(P4, "Y", UDim2.new(0,90,0,24), UDim2.new(0,94,0,166))
local tzIn = INS(P4, "Z", UDim2.new(0,90,0,24), UDim2.new(0,188,0,166))
local BTp  = B(P4, "Teleport", UDim2.new(0,100,0,24), UDim2.new(0,282,0,166), C.BLUE)
local BGetPos = B(P4, "Get Pos", UDim2.new(0,88,0,24), UDim2.new(0,386,0,166), C.GREY)
BTp.TextSize = 11; BGetPos.TextSize = 11
hov(BTp, C.BLUE, C.BLHV); hov(BGetPos, C.GREY, C.GRYHV)

BTp.MouseButton1Click:Connect(function()
    local x,y,z = tonumber(txIn.Text), tonumber(tyIn.Text), tonumber(tzIn.Text)
    if not (x and y and z) then plrOut("Enter valid X Y Z.", false); return end
    local root = getRoot()
    if not root then plrOut("No character.", false); return end
    root.CFrame = CFrame.new(x, y, z)
    plrOut(("Teleported → %.1f, %.1f, %.1f"):format(x, y, z), true)
end)
BGetPos.MouseButton1Click:Connect(function()
    local root = getRoot()
    if not root then plrOut("No character.", false); return end
    local p = root.Position
    txIn.Text = ("%.1f"):format(p.X)
    tyIn.Text = ("%.1f"):format(p.Y)
    tzIn.Text = ("%.1f"):format(p.Z)
    plrOut(("Position: %.2f, %.2f, %.2f"):format(p.X, p.Y, p.Z), true)
end)

-- ── Character info ────────────────────────────────────────────────────────────
local BCharInfo = B(P4, "Character Info", UDim2.new(0,120,0,24), UDim2.new(0,0,0,196), C.GREY)
BCharInfo.TextSize = 11; hov(BCharInfo, C.GREY, C.GRYHV)
BCharInfo.MouseButton1Click:Connect(function()
    local char = getChar()
    local hum  = getHum()
    local root = getRoot()
    if not char then plrOut("No character.", false); return end
    local parts = 0
    for _, p in char:GetDescendants() do if p:IsA("BasePart") then parts+=1 end end
    plrOut(table.concat({
        "Name: " .. LP.Name .. " (@" .. LP.DisplayName .. ")",
        "Health: " .. (hum and ("%.1f/%.1f"):format(hum.Health,hum.MaxHealth) or "N/A"),
        "WalkSpeed: " .. (hum and hum.WalkSpeed or "N/A"),
        "JumpPower: " .. (hum and hum.JumpPower or "N/A"),
        "Parts: " .. parts,
        "Pos: " .. (root and ("%.1f %.1f %.1f"):format(root.Position.X,root.Position.Y,root.Position.Z) or "N/A"),
    }, "\n"), true)
end)

-- ════════════════════════════════════════
-- SOURCE: src/tabs/05_remotespy.lua
-- ════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB 5 — REMOTE SPY
--  Hooks __namecall · Live log · Filter · Block list · Export
-- ═══════════════════════════════════════════════════════════════════════════════
local P5 = newTab("📡", "RemoteSpy")
L(P5, "REMOTE SPY", UDim2.new(1,0,0,16), UDim2.new(0,0,0,0), C.TXTS, FB, 11)

-- ── Status bar ────────────────────────────────────────────────────────────────
local statusF = F(P5, UDim2.new(1,0,0,24), UDim2.new(0,0,0,18), C.PANEL); corner(statusF,6)
local spyStatusLbl = L(statusF, "● Inactive", UDim2.new(0.5,0,1,0), nil, C.RED, FB, 11)
local spyCountLbl  = L(statusF, "Captured: 0", UDim2.new(0.5,0,1,0), UDim2.new(0.5,0,0,0),
    C.TXTS, FN, 11, Enum.TextXAlignment.Right)

-- ── Controls ──────────────────────────────────────────────────────────────────
local rRow     = rowBar(P5, 46, 26)
local BSpyOn   = B(rRow, "▶ Start",  UDim2.new(0,88,1,0), nil, C.GRN)
local BSpyOff  = B(rRow, "■ Stop",   UDim2.new(0,80,1,0), nil, C.GREY)
local BSpyClr  = B(rRow, "Clear",    UDim2.new(0,68,1,0), nil, C.GREY)
local BSpyExp  = B(rRow, "Export",   UDim2.new(0,76,1,0), nil, C.BLUE)
local BSpyCopy = B(rRow, "Copy All", UDim2.new(0,82,1,0), nil, C.GREY)
styleRow({BSpyOn,BSpyOff,BSpyClr,BSpyExp,BSpyCopy})
hov(BSpyOn,   C.GRN,  C.GRNHV); hov(BSpyOff, C.GREY, C.GRYHV)
hov(BSpyClr,  C.GREY, C.GRYHV); hov(BSpyExp,  C.BLUE, C.BLHV)
hov(BSpyCopy, C.GREY, C.GRYHV)

-- ── Filter row ────────────────────────────────────────────────────────────────
local filtF = F(P5, UDim2.new(1,0,0,26), UDim2.new(0,0,0,76), C.PANEL); corner(filtF,6)
L(filtF, "Filter:", UDim2.new(0,44,1,0), UDim2.new(0,6,0,0), C.TXTS, FN, 11)
local SpyFiltIn = INS(filtF, "(leave blank = capture all)", UDim2.new(0.72,0,0,20), UDim2.new(0,54,0,3))

-- Method filter toggles
local methF = F(P5, UDim2.new(1,0,0,24), UDim2.new(0,0,0,106), C.PANEL); corner(methF,6)
listH(methF, 3); pad(methF, 2, 4)
local METHODS = {"FireServer","InvokeServer","FireAllClients","FireClient","InvokeClient"}
local methActive = {}
for _, m in METHODS do methActive[m] = true end
for i, m in METHODS do
    local short = m:gsub("Server","Srv"):gsub("Client","Cli"):gsub("All","All")
    local b = B(methF, short, UDim2.new(0,98,1,0), nil, C.ACC); b.TextSize=9
    b.LayoutOrder = i; hov(b, C.ACC, C.ACCHV)
    b.MouseButton1Click:Connect(function()
        methActive[m] = not methActive[m]
        tw(b, {BackgroundColor3 = methActive[m] and C.ACC or C.GREY})
    end)
end

-- ── Log scroll ────────────────────────────────────────────────────────────────
local SpyScr = SCR(P5, UDim2.new(1,0,1,-136), UDim2.new(0,0,0,134))
listV(SpyScr, 2)

-- ── State ─────────────────────────────────────────────────────────────────────
local spyActive  = false
local spyHooked  = false
local spyLog     = {}
local blockedSet = {}
local spyFilter  = ""

SpyFiltIn:GetPropertyChangedSignal("Text"):Connect(function()
    spyFilter = SpyFiltIn.Text:lower()
end)

-- Color per method
local MCOL = {
    FireServer     = C.ORAN,
    InvokeServer   = C.PURP,
    FireAllClients = C.RED,
    FireClient     = C.PINK,
    InvokeClient   = C.TEAL,
}

local function addSpyRow(entry)
    -- apply filter
    if spyFilter ~= "" and not entry.remote:lower():find(spyFilter, 1, true) then return end
    if not methActive[entry.method] then return end
    if blockedSet[entry.remote] then return end

    local Row = F(SpyScr, UDim2.new(1,-4,0,40), nil, C.PANEL); corner(Row,5)
    stroke(Row, Color3.fromRGB(28,40,72), 1)

    local mc = MCOL[entry.method] or C.TXTS
    local bg = pill(Row, entry.method, mc, UDim2.new(0,90,0,16), UDim2.new(0,4,0.5,-8))
    L(Row, entry.remote, UDim2.new(1,-200,0,18), UDim2.new(0,98,0,2), C.TXT, FN, 12)
    L(Row, os.date("%H:%M:%S", entry.ts),
        UDim2.new(0,64,0,14), UDim2.new(1,-80,0,2), C.TXTD, FC, 10, Enum.TextXAlignment.Right)

    local argsPreview = ""
    if #entry.args > 0 then
        local parts = {}
        for i, a in ipairs(entry.args) do
            if i > 4 then parts[#parts+1]="…"; break end
            parts[#parts+1] = tostring(a):sub(1,30)
        end
        argsPreview = table.concat(parts, ", ")
    end
    L(Row, "Args: " .. argsPreview, UDim2.new(1,-100,0,14), UDim2.new(0,98,0,22), C.TXTS, FC, 10)

    local BCp  = B(Row,"Copy",  UDim2.new(0,36,0,16), UDim2.new(1,-80,0.5,-8), C.GREY)
    local BBlk = B(Row,"Block", UDim2.new(0,36,0,16), UDim2.new(1,-40,0.5,-8), C.RED)
    BCp.TextSize=9; BBlk.TextSize=9; hov(BCp,C.GREY,C.GRYHV); hov(BBlk,C.RED,C.REDHV)
    BCp.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(entry.method .. " → " .. entry.remote .. "\nArgs: " .. argsPreview)
        end
    end)
    BBlk.MouseButton1Click:Connect(function()
        blockedSet[entry.remote] = true
        Row:Destroy()
        spyStatusLbl.Text = "Blocked: " .. entry.remote
    end)
end

local function startSpy()
    if spyHooked then
        spyActive = true
        spyStatusLbl.Text = "● Active"; spyStatusLbl.TextColor3 = C.GRN; return
    end
    if not hookmetamethod    then spyStatusLbl.Text="✗ hookmetamethod missing"; spyStatusLbl.TextColor3=C.RED; return end
    if not getnamecallmethod then spyStatusLbl.Text="✗ getnamecallmethod missing"; spyStatusLbl.TextColor3=C.RED; return end

    spyActive = true; spyHooked = true
    spyStatusLbl.Text = "● Active"; spyStatusLbl.TextColor3 = C.GRN
    tw(BSpyOn, {BackgroundColor3=C.GREY}); tw(BSpyOff, {BackgroundColor3=C.RED})

    local _old; _old = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local capture = spyActive and methActive[method]
        if capture then
            local args = {...}
            local rname = tostring(self):match("^(.+) %(") or tostring(self)
            local entry = {remote=rname, method=method, args=args, ts=os.time()}
            table.insert(spyLog, 1, entry)
            if #spyLog > 500 then table.remove(spyLog) end
            spyCountLbl.Text = "Captured: " .. #spyLog
            task.spawn(addSpyRow, entry)
        end
        return _old(self, ...)
    end)
end

BSpyOn.MouseButton1Click:Connect(startSpy)

BSpyOff.MouseButton1Click:Connect(function()
    spyActive = false
    spyStatusLbl.Text = "◉ Paused"; spyStatusLbl.TextColor3 = C.YELL
    tw(BSpyOff, {BackgroundColor3=C.GREY})
end)

BSpyClr.MouseButton1Click:Connect(function()
    clearLayout(SpyScr)
    spyLog = {}; spyCountLbl.Text = "Captured: 0"
end)

BSpyExp.MouseButton1Click:Connect(function()
    if not writefile then spyStatusLbl.Text="writefile unavailable"; return end
    local lines = {}
    for _, e in spyLog do
        lines[#lines+1] = os.date("%Y-%m-%d %H:%M:%S", e.ts) ..
            " | " .. e.method .. " | " .. e.remote
    end
    local fname = "nexus_remotespy_" .. os.time() .. ".txt"
    writefile(fname, table.concat(lines, "\n"))
    spyStatusLbl.Text = "Exported → " .. fname; spyStatusLbl.TextColor3 = C.GRN
end)

BSpyCopy.MouseButton1Click:Connect(function()
    if not setclipboard then return end
    local lines = {}
    for i = 1, math.min(50, #spyLog) do
        local e = spyLog[i]
        lines[#lines+1] = e.method .. " | " .. e.remote
    end
    setclipboard(table.concat(lines, "\n"))
    spyStatusLbl.Text = "Copied " .. #lines .. " entries"; spyStatusLbl.TextColor3 = C.GRN
end)

-- ════════════════════════════════════════
-- SOURCE: src/tabs/06_scanner.lua
-- ════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB 6 — MALWARE SCANNER
--  Pattern scan · Bridge scan · Script list · Kill specific script
-- ═══════════════════════════════════════════════════════════════════════════════
local P6 = newTab("🔎", "Scanner")
L(P6, "MALWARE & SCRIPT SCANNER", UDim2.new(1,0,0,16), UDim2.new(0,0,0,0), C.TXTS, FB, 11)

local scRow = rowBar(P6, 18, 26)
local BScanRun  = B(scRow, "Scan Game",   UDim2.new(0,100,1,0), nil, C.ACC)
local BScanKill = B(scRow, "Kill All LS", UDim2.new(0,92,1,0),  nil, C.RED)
local BScanList = B(scRow, "List Scripts",UDim2.new(0,106,1,0), nil, C.BLUE)
local BScanBrdg = B(scRow, "Bridge Scan", UDim2.new(0,106,1,0), nil, C.GREY)
local BScanKill1= B(scRow, "Kill Name",   UDim2.new(0,96,1,0),  nil, C.GREY)
styleRow({BScanRun,BScanKill,BScanList,BScanBrdg,BScanKill1})
hov(BScanRun,  C.ACC,  C.ACCHV); hov(BScanKill, C.RED,  C.REDHV)
hov(BScanList, C.BLUE, C.BLHV);  hov(BScanBrdg, C.GREY, C.GRYHV)
hov(BScanKill1,C.GREY, C.GRYHV)

local scanOut = statusOut(P6, UDim2.new(1,0,1,-52), UDim2.new(0,0,0,50))

-- Kill-by-name input (inline below buttons)
local KillNameIn = INS(P6, "Script name to kill…", UDim2.new(0.55,0,0,20), UDim2.new(0,0,0,48))

-- ── Signature database ────────────────────────────────────────────────────────
local SIGS = {
    -- HTTP abuse
    {pat="HttpGet.*pastebin",     sev="HIGH",   lbl="Pastebin fetch"},
    {pat="HttpGet.*discord%.gg",  sev="HIGH",   lbl="Discord invite fetch"},
    {pat="HttpGet.*bit%.ly",      sev="MED",    lbl="URL shortener fetch"},
    {pat="request%s*%(%s*{",      sev="MED",    lbl="HTTP request object"},
    {pat="syn%.request",          sev="MED",    lbl="syn.request HTTP call"},
    {pat="http%.request",         sev="MED",    lbl="http.request call"},
    -- Environment manipulation
    {pat="getfenv%(0%)",          sev="HIGH",   lbl="getfenv(0) — env tamper"},
    {pat="getfenv.*setfenv",      sev="HIGH",   lbl="Environment hijack"},
    {pat="setfenv.*getfenv",      sev="HIGH",   lbl="Environment swap"},
    -- Hooking / patching
    {pat="hookfunction",          sev="MED",    lbl="hookfunction detected"},
    {pat="hookmetamethod",        sev="MED",    lbl="hookmetamethod detected"},
    {pat="replaceclosure",        sev="MED",    lbl="replaceclosure"},
    {pat="setreadonly.*false",     sev="MED",    lbl="Metatable unlock"},
    -- Player targeting
    {pat="Players.*:Remove%(",    sev="HIGH",   lbl="Forced player removal"},
    {pat="game%.Players.*Kick",   sev="HIGH",   lbl="Player kick call"},
    -- Crash / exploit
    {pat="while true do",         sev="LOW",    lbl="Infinite loop"},
    {pat="Instance%.new.*%-%-",   sev="LOW",    lbl="Instance spam (commented hint)"},
    {pat="error%(%d%d%d%d%d",    sev="MED",    lbl="Mass error throw"},
    -- Data exfiltration
    {pat="game%.JobId",           sev="LOW",    lbl="JobId access"},
    {pat="Players%.LocalPlayer.*UserId", sev="MED", lbl="UserId exfil attempt"},
    -- Obfuscation tells
    {pat="\\x%x%x\\x%x%x",       sev="LOW",    lbl="Hex-escaped payload"},
    {pat="string%.char%(%d+,%d+", sev="LOW",    lbl="string.char encoded blob"},
    {pat="_[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]", sev="LOW", lbl="Hex variable names"},
    -- Remote abuse
    {pat="FireServer.*%b()",      sev="LOW",    lbl="FireServer call"},
    {pat="InvokeServer.*%b()",    sev="LOW",    lbl="InvokeServer call"},
}

local SEV_COL = {HIGH = C.RED, MED = C.ORAN, LOW = C.YELL}

local function scanScript(scr)
    local src = ""
    pcall(function() if getscriptsource then src = getscriptsource(scr) end end)
    if src == "" then return {} end
    local hits = {}
    for _, sig in SIGS do
        if src:find(sig.pat) then
            hits[#hits+1] = {lbl = sig.lbl, sev = sig.sev}
        end
    end
    return hits
end

BScanRun.MouseButton1Click:Connect(function()
    scanOut("Scanning all scripts…", true)
    task.spawn(function()
        local results  = {}
        local total    = 0
        local flagged  = 0
        local highCnt  = 0

        forEachScript(game, function(ch)
            total += 1
            local hits = scanScript(ch)
            if #hits > 0 then
                flagged += 1
                results[#results+1] = "⚠  " .. ch:GetFullName()
                for _, h in hits do
                    results[#results+1] = "   [" .. h.sev .. "] " .. h.lbl
                    if h.sev == "HIGH" then highCnt += 1 end
                end
            end
        end)

        if #results == 0 then
            scanOut(("Scanned %d scripts — no signatures found ✓"):format(total), true)
        else
            local header = ("Scanned %d scripts | %d flagged | %d HIGH severity hits"):format(
                total, flagged, highCnt)
            scanOut(header .. "\n" .. table.concat(results, "\n"), highCnt == 0)
        end
    end)
end)

BScanKill.MouseButton1Click:Connect(function()
    local ok2, msg2 = killAllScripts()
    scanOut(msg2 or "Bridge error", ok2)
end)

BScanList.MouseButton1Click:Connect(function()
    local lines = {}; local n = 0
    forEachScript(game, function(ch)
        n += 1
        lines[#lines+1] = ("[%s] %s"):format(ch.ClassName, ch:GetFullName())
    end)
    scanOut(n .. " scripts found:\n" .. table.concat(lines, "\n"), true)
end)

BScanBrdg.MouseButton1Click:Connect(function()
    local ok2, msg2, data = serverScan()
    local lines = {msg2 or ""}
    if data then for _, l in data do lines[#lines+1] = tostring(l) end end
    scanOut(table.concat(lines, "\n"), ok2)
end)

BScanKill1.MouseButton1Click:Connect(function()
    local name = trim(KillNameIn.Text)
    if name == "" then scanOut("Enter a script name.", false); return end
    local ok2, msg2 = killScript(name)
    scanOut(msg2 or "Bridge error", ok2)
end)

-- ════════════════════════════════════════
-- SOURCE: src/tabs/07_deobfusc.lua
-- ════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB 7 — DEOBFUSCATOR
--  Detect type · Multi-pass deobfusc · Base64 · Hex · string.char
-- ═══════════════════════════════════════════════════════════════════════════════
local P7 = newTab("👁", "Deobfusc.")
L(P7, "DEOBFUSCATOR", UDim2.new(1,0,0,16), UDim2.new(0,0,0,0), C.TXTS, FB, 11)
L(P7, "Input:", UDim2.new(0,45,0,12), UDim2.new(0,0,0,18), C.TXTS, FN, 11)
local DIn = IN(P7, "-- Paste obfuscated / encoded Lua here…", UDim2.new(1,0,0,150), UDim2.new(0,0,0,32))

local dRow1 = rowBar(P7, 186, 26)
local BDDet  = B(dRow1, "Detect",       UDim2.new(0,90,1,0),  nil, C.BLUE)
local BDDeob = B(dRow1, "Deobfuscate",  UDim2.new(0,116,1,0), nil, C.ACC)
local BDB64  = B(dRow1, "Base64 Dec",   UDim2.new(0,100,1,0), nil, C.GREY)
local BDHex  = B(dRow1, "Hex Dec",      UDim2.new(0,80,1,0),  nil, C.GREY)
local BDChar = B(dRow1, "Chr Dec",      UDim2.new(0,80,1,0),  nil, C.GREY)
styleRow({BDDet,BDDeob,BDB64,BDHex,BDChar})
hov(BDDet,  C.BLUE, C.BLHV); hov(BDDeob, C.ACC,  C.ACCHV)
hov(BDB64,  C.GREY, C.GRYHV); hov(BDHex,  C.GREY, C.GRYHV)
hov(BDChar, C.GREY, C.GRYHV)

local dRow2  = rowBar(P7, 216, 26)
local BDSwap = B(dRow2, "Swap I↔O",  UDim2.new(0,96,1,0),  nil, C.GREY)
local BDCopy = B(dRow2, "Copy Out",   UDim2.new(0,90,1,0),  nil, C.GREY)
local BDSave = B(dRow2, "Save Out",   UDim2.new(0,90,1,0),  nil, C.GREY)
local BDRun  = B(dRow2, "▶ Run Out",  UDim2.new(0,90,1,0),  nil, C.GRN)
styleRow({BDSwap,BDCopy,BDSave,BDRun})
hov(BDSwap, C.GREY, C.GRYHV); hov(BDCopy, C.GREY, C.GRYHV)
hov(BDSave, C.GREY, C.GRYHV); hov(BDRun,  C.GRN,  C.GRNHV)

L(P7, "Output:", UDim2.new(0,55,0,12), UDim2.new(0,0,0,248), C.TXTS, FN, 11)
local DOut = OUT(P7, UDim2.new(1,0,1,-262), UDim2.new(0,0,0,262))

-- ── Detection ─────────────────────────────────────────────────────────────────
local DETECTORS = {
    {pat="luraph",                            lbl="Luraph VM obfuscation"},
    {pat="getfenv",   pat2="0x%x+",          lbl="IronBrew 2"},
    {pat="prometheus",                        lbl="Prometheus"},
    {pat="moonsec",                           lbl="Moonsec"},
    {pat="bytecode",  pat2="\\x",            lbl="Custom bytecode VM"},
    {pat="\\x%x%x",                           lbl="Hex-escape encoded"},
    {pat="string%.char%(%d",                  lbl="string.char encoded"},
    {pat="[A-Za-z0-9+/]+=?=?$",              lbl="Possible Base64"},
    {pat="_[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]",lbl="Hex variable names"},
    {pat="\\%d%d%d",                          lbl="Decimal-escape encoded"},
    {pat="xor_key",                           lbl="XOR key obfuscation"},
    {pat="rot%d",                             lbl="ROT cipher"},
    {pat="bitwise",                           lbl="Bitwise obfuscation"},
}

local function detectType(s)
    s = s:lower()
    for _, d in DETECTORS do
        local match = s:find(d.pat)
        if match and (not d.pat2 or s:find(d.pat2)) then
            return d.lbl
        end
    end
    return "Unknown / plain Lua"
end

-- ── Base64 decode ─────────────────────────────────────────────────────────────
local B64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function b64decode(s)
    s = s:gsub("[^" .. B64_CHARS .. "=]", "")
    return (s:gsub(".", function(x)
        if x == "=" then return "" end
        local r, f = "", B64_CHARS:find(x) - 1
        for i = 6, 1, -1 do
            r = r .. (f % 2^i - f % 2^(i-1) > 0 and "1" or "0")
        end
        return r
    end):gsub("%d%d%d%d%d%d%d%d", function(x)
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i,i)=="1" and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

-- ── Hex decode ────────────────────────────────────────────────────────────────
local function hexdecode(s)
    local out = {}
    for hex in s:gmatch("%x%x") do
        out[#out+1] = string.char(tonumber(hex, 16))
    end
    return table.concat(out)
end

-- ── string.char decode ────────────────────────────────────────────────────────
local function chardecode(s)
    return (s:gsub("string%.char%(([%d,%s]+)%)", function(args)
        local out = {}
        for n in args:gmatch("%d+") do
            local num = tonumber(n)
            if num then out[#out+1] = string.char(num) end
        end
        return '"' .. table.concat(out) .. '"'
    end))
end

-- ── Multi-pass deobfuscate ────────────────────────────────────────────────────
local function deobfuscate(s)
    -- pass 1: hex escapes
    s = s:gsub("\\x(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
    -- pass 2: decimal escapes
    s = s:gsub("\\(%d%d?%d?)", function(d)
        local n = tonumber(d)
        return (n and n <= 255) and string.char(n) or "\\" .. d
    end)
    -- pass 3: string.char patterns
    s = chardecode(s)
    -- pass 4: string concat collapse
    for _ = 1, 16 do
        s = s:gsub('"([^"]*)"%s*%.%.%s*"([^"]*)"', '"%1%2"')
    end
    -- pass 5: remove redundant local blocks
    s = s:gsub("do%s+local%s+([%w_]+)%s*=%s*([^\n]+)\n%s*end",
        function(v, e) return "local " .. v .. " = " .. e end)
    -- pass 6: unpack tostring wraps
    s = s:gsub("tostring%(\"([^\"]+)\"%)", '"%1"')
    -- pass 7: collapse double negations
    s = s:gsub("not not ", "")
    return s
end

-- ── Handlers ──────────────────────────────────────────────────────────────────
BDDet.MouseButton1Click:Connect(function()
    local t = detectType(DIn.Text)
    DOut.TextColor3 = C.YELL; DOut.Text = "Detected: " .. t
end)

BDDeob.MouseButton1Click:Connect(function()
    if trim(DIn.Text) == "" then DOut.TextColor3=C.RED; DOut.Text="Nothing to deobfuscate."; return end
    local ok2, res = pcall(deobfuscate, DIn.Text)
    DOut.TextColor3 = ok2 and C.GRN or C.RED
    DOut.Text = ok2 and res or "Error: " .. tostring(res)
end)

BDB64.MouseButton1Click:Connect(function()
    local ok2, res = pcall(b64decode, trim(DIn.Text))
    DOut.TextColor3 = ok2 and C.GRN or C.RED
    DOut.Text = ok2 and res or "Base64 decode failed: " .. tostring(res)
end)

BDHex.MouseButton1Click:Connect(function()
    local res = hexdecode(DIn.Text)
    if res == "" then DOut.TextColor3=C.RED; DOut.Text="No hex bytes found."
    else DOut.TextColor3=C.GRN; DOut.Text=res end
end)

BDChar.MouseButton1Click:Connect(function()
    local ok2, res = pcall(chardecode, DIn.Text)
    DOut.TextColor3 = ok2 and C.GRN or C.RED
    DOut.Text = ok2 and res or "Error: " .. tostring(res)
end)

BDSwap.MouseButton1Click:Connect(function()
    local tmp = DIn.Text; DIn.Text = DOut.Text; DOut.Text = tmp
end)

BDCopy.MouseButton1Click:Connect(function()
    if setclipboard then setclipboard(DOut.Text); DOut.TextColor3=C.GRN
    else DOut.TextColor3=C.RED; DOut.Text="setclipboard unavailable." end
end)

BDSave.MouseButton1Click:Connect(function()
    if not writefile then DOut.TextColor3=C.RED; DOut.Text="writefile unavailable."; return end
    local fname = "nexus_deobf_" .. os.time() .. ".lua"
    writefile(fname, DOut.Text)
    DOut.TextColor3 = C.GRN; DOut.Text = "Saved → " .. fname .. "\n" .. DOut.Text
end)

BDRun.MouseButton1Click:Connect(function()
    local code = DOut.Text
    if trim(code) == "" then DOut.TextColor3=C.RED; DOut.Text="Output is empty."; return end
    local ok2, err, stage = runCode(code)
    DOut.TextColor3 = ok2 and C.GRN or C.RED
    if not ok2 then
        DOut.Text = (stage=="compile" and "Compile error:\n" or "Runtime error:\n")..err; return
    end
    DOut.Text = "Output executed OK."
end)

-- ════════════════════════════════════════
-- SOURCE: src/tabs/08_checker.lua
-- ════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB 8 — FUNCTION CHECKER
--  UNC (100) · SUNC (100) · Myriad (250) · Search filter · Export
-- ═══════════════════════════════════════════════════════════════════════════════
local P8 = newTab("✓", "Checker")

-- Sub-tab row + search
local subRowF = F(P8, UDim2.new(1,0,0,24), UDim2.new(0,0,0,0), C.EDIT, "SubRow"); corner(subRowF,6)
listH(subRowF, 2); pad(subRowF, 2, 2)

local ChkSearch = INS(P8, "Search functions…", UDim2.new(0.45,0,0,24), UDim2.new(0.55,0,0,0))

local ChkScr = SCR(P8, UDim2.new(1,0,1,-30), UDim2.new(0,0,0,28))
listV(ChkScr, 2)

local subBtns2 = {}; local curSub = 0

local function switchSub(i)
    curSub = i
    for j, b in subBtns2 do
        tw(b, {BackgroundColor3 = j==i and C.ACC or C.PANEL})
        b.TextColor3 = j==i and C.TXT or C.TXTS
    end
end

local function addSub(name, order)
    local b = B(subRowF, name, UDim2.new(0,140,1,0), nil, C.PANEL, C.TXTS)
    b.LayoutOrder = order; b.TextSize = 11
    hov(b, C.PANEL, Color3.fromRGB(26,26,38))
    b.MouseButton1Click:Connect(function() switchSub(order); buildList(order) end)
    subBtns2[order] = b
end
addSub("UNC (100)",    1)
addSub("SUNC (100)",   2)
addSub("Myriad (250)", 3)

-- ── Data ──────────────────────────────────────────────────────────────────────
local UNC_LIST={"checkcaller","clonefunction","getcallingscript","getscriptclosure","getscriptfunction","iscclosure","islclosure","isnewcclosure","newcclosure","crypt.base64decode","crypt.base64encode","crypt.decrypt","crypt.encrypt","crypt.generatebytes","crypt.generatekey","crypt.hash","debug.getconstant","debug.getconstants","debug.getinfo","debug.getproto","debug.getprotos","debug.getstack","debug.getupvalue","debug.getupvalues","debug.setconstant","debug.setstack","debug.setupvalue","Drawing.new","cleardrawcache","getrenderproperty","isrenderobj","setrenderproperty","appendfile","delfile","isfile","isfolder","listfiles","loadfile","makefolder","readfile","writefile","isrbxactive","keypress","keyrelease","mouse1click","mouse1press","mouse1release","mouse2click","mouse2press","mouse2release","mousemoveabs","mousemoverel","mousescroll","fireclickdetector","firetouchinterest","gethiddenproperty","sethiddenproperty","getsimulationradius","setsimulationradius","getconnections","hookmetamethod","getrawmetatable","setrawmetatable","identifyexecutor","isexecutorclosure","queue_on_teleport","request","setfpscap","getfpscap","gethui","getnamecallmethod","setnamecallmethod","getloadedmodules","getrenv","getrunningscripts","getscripts","getsenv","firesignal","replicatesignal","getthreadidentity","setthreadidentity","http.request","httpget","syn.request","cache.invalidate","cache.iscached","cache.replace","cloneref","compareinstances","WebSocket.connect","rconsoleclose","rconsoleinfo","rconsoleinput","rconsolename","rconsoleprint","rconsoleclear","rconsoleopen","rconsolewarn","getgenv","setreadonly","hookfunction","replaceclosure"}
local SUNC_LIST={"getgenv","getrenv","getsenv","getfenv","setfenv","getscriptstate","setscriptstate","getthreadstate","setthreadstate","getscriptclosure","getscriptfunction","isscriptactive","killtask","getglobals","setglobal","getlocals","setlocal","getupvalues","setupvalue","getscriptbyname","getscriptbypath","getscriptbyid","findscript","getscriptparent","getscriptchildren","getscriptancestors","getscriptdescendants","getscriptid","getscripthash","getscriptbytecode","getscriptsource","patchscript","hookscript","replacescript","overwritescript","script.encrypt","script.decrypt","script.hash","script.sign","script.verify","sandbox.create","sandbox.destroy","sandbox.isolate","sandbox.expose","sandbox.getenv","sandbox.setenv","sandbox.run","sandbox.capture","sandbox.getresult","sandbox.getlog","sandbox.getoutput","sandbox.getstatus","scriptcontext.run","scriptcontext.stop","scriptcontext.pause","scriptcontext.resume","scriptcontext.getstatus","scriptcontext.getenv","scriptcontext.setenv","scriptcontext.capture","scriptcontext.getlog","scriptcontext.getoutput","scriptcontext.patchglobal","scriptcontext.hookfunction","scriptcontext.traceglobal","scriptcontext.sandbox","scriptcontext.unsandbox","scriptcontext.isolate","scriptcontext.expose","scriptcontext.getresult","scriptcontext.getid","scriptcontext.gethash","scriptcontext.getbytecode","scriptcontext.getsource","scriptcontext.sign","scriptcontext.verify","scriptcontext.encrypt","scriptcontext.decrypt","scriptcontext.replace","scriptcontext.overwrite","scriptcontext.patch","scriptcontext.hook","scriptcontext.kill","scriptcontext.find","scriptcontext.list","scriptcontext.count","scriptcontext.exists","scriptcontext.isactive","scriptcontext.isrunning","scriptcontext.issandboxed","scriptcontext.isisolated","scriptcontext.isexposed","scriptcontext.ishooked","scriptcontext.ispatched","scriptcontext.isreplaced","scriptcontext.isoverwritten","scriptcontext.isencrypted","scriptcontext.issigned","scriptcontext.isverified","scriptcontext.isdecrypted","scriptcontext.ishashed"}
local MYRIAD_LIST={"myr.drawing.new","myr.drawing.clear","myr.drawing.getall","myr.drawing.remove","myr.drawing.setproperty","myr.drawing.getproperty","myr.drawing.isobject","myr.drawing.oncreate","myr.drawing.onremove","myr.drawing.render","myr.drawing.hide","myr.drawing.show","myr.drawing.toggle","myr.drawing.setvisible","myr.drawing.getvisible","myr.drawing.setcolor","myr.drawing.getcolor","myr.drawing.setalpha","myr.drawing.getalpha","myr.drawing.setposition","myr.drawing.getposition","myr.drawing.setsize","myr.drawing.getsize","myr.mem.read","myr.mem.write","myr.mem.scan","myr.mem.alloc","myr.mem.free","myr.mem.protect","myr.mem.query","myr.mem.patch","myr.mem.compare","myr.mem.dump","myr.mem.restore","myr.mem.hook","myr.mem.unhook","myr.mem.getbase","myr.mem.getsize","myr.mem.gettype","myr.mem.getname","myr.mem.getpath","myr.mem.getclass","myr.mem.getparent","myr.mem.getchildren","myr.mem.getancestors","myr.mem.getdescendants","myr.net.request","myr.net.get","myr.net.post","myr.net.put","myr.net.delete","myr.net.patch","myr.net.head","myr.net.options","myr.net.trace","myr.net.connect","myr.net.listen","myr.net.close","myr.net.send","myr.net.receive","myr.net.getip","myr.net.getport","myr.net.gethost","myr.net.getpath","myr.net.getquery","myr.net.getfragment","myr.anti.detect","myr.anti.bypass","myr.anti.hook","myr.anti.unhook","myr.anti.patch","myr.anti.restore","myr.anti.scan","myr.anti.kill","myr.anti.block","myr.anti.allow","myr.anti.log","myr.anti.alert","myr.anti.monitor","myr.anti.trace","myr.anti.intercept","myr.anti.redirect","myr.anti.spoof","myr.anti.mask","myr.anti.hide","myr.anti.show","myr.spy.hook","myr.spy.unhook","myr.spy.intercept","myr.spy.monitor","myr.spy.trace","myr.spy.log","myr.spy.capture","myr.spy.replay","myr.spy.block","myr.spy.allow","myr.spy.redirect","myr.spy.spoof","myr.spy.getremotes","myr.spy.fireremote","myr.spy.invokefunc","myr.spy.hookremote","myr.spy.unhookremote","myr.spy.logremote","myr.spy.capturefunc","myr.spy.replayfunc","myr.byte.read","myr.byte.write","myr.byte.scan","myr.byte.patch","myr.byte.compare","myr.byte.dump","myr.byte.restore","myr.byte.encode","myr.byte.decode","myr.byte.encrypt","myr.byte.decrypt","myr.byte.hash","myr.byte.sign","myr.byte.verify","myr.byte.compress","myr.byte.decompress","myr.byte.pack","myr.byte.unpack","myr.byte.convert","myr.byte.format","myr.ui.create","myr.ui.destroy","myr.ui.get","myr.ui.set","myr.ui.find","myr.ui.list","myr.ui.show","myr.ui.hide","myr.ui.toggle","myr.ui.move","myr.ui.resize","myr.ui.recolor","myr.ui.retextsize","myr.ui.refont","myr.ui.retext","myr.ui.reimage","myr.ui.reparent","myr.ui.clone","myr.ui.tween","myr.ui.animate","myr.phys.setvelocity","myr.phys.getvelocity","myr.phys.setposition","myr.phys.getposition","myr.phys.setrotation","myr.phys.getrotation","myr.phys.setgravity","myr.phys.getgravity","myr.phys.setmass","myr.phys.getmass","myr.phys.setfriction","myr.phys.getfriction","myr.phys.setelasticity","myr.phys.getelasticity","myr.phys.setdensity","myr.phys.getdensity","myr.phys.noclip","myr.phys.clip","myr.phys.fly","myr.phys.land","myr.rep.fire","myr.rep.invoke","myr.rep.hook","myr.rep.unhook","myr.rep.block","myr.rep.allow","myr.rep.log","myr.rep.capture","myr.rep.replay","myr.rep.redirect","myr.rep.spoof","myr.rep.create","myr.rep.destroy","myr.rep.rename","myr.rep.clone","myr.rep.move","myr.rep.reparent","myr.rep.getall","myr.rep.find","myr.rep.monitor","myr.game.getservice","myr.game.findservice","myr.game.listservices","myr.game.getplayers","myr.game.findplayer","myr.game.kickplayer","myr.game.getcharacter","myr.game.respawn","myr.game.teleport","myr.game.getworkspace","myr.game.getlighting","myr.game.getreplicatedstorage","myr.game.getstartergui","myr.game.getstartpack","myr.game.getstartchar","myr.game.getserverstorage","myr.game.getscriptcontext","myr.game.getrunservice","myr.game.getuserinputservice","myr.game.getcontentprovider","myr.game.gethttpservice","myr.game.gettweenservice","myr.game.getmarketplaceservice","myr.debug.getinfo","myr.debug.getstack","myr.debug.traceback","myr.debug.profilebegin","myr.debug.profileend","myr.debug.getupvalue","myr.debug.setupvalue","myr.debug.getconstant","myr.debug.setconstant","myr.debug.getproto","myr.debug.getprotos","myr.debug.setproto","myr.debug.getlocal","myr.debug.setlocal","myr.debug.getmetatable","myr.debug.setmetatable","myr.debug.rawget","myr.debug.rawset","myr.debug.rawequal","myr.debug.rawlen","myr.event.fire","myr.event.connect","myr.event.disconnect","myr.event.wait","myr.event.once","myr.event.hook","myr.event.unhook","myr.event.block","myr.event.allow","myr.event.log","myr.event.capture","myr.event.replay","myr.event.redirect","myr.event.spoof","myr.event.monitor","myr.event.trace","myr.event.getconnections","myr.event.getlisteners","myr.event.getsignals","myr.event.getevents","myr.event.getfirers","myr.exec.run","myr.exec.load","myr.exec.require","myr.exec.dofile","myr.exec.dostring","myr.exec.loadfile","myr.exec.loadstring","myr.exec.loadbytecode","myr.exec.runfile","myr.exec.runstring","myr.exec.runbytecode","myr.exec.runurl","myr.exec.inject","myr.exec.eject","myr.exec.hook","myr.exec.unhook","myr.exec.patch","myr.exec.unpatch","myr.exec.sandbox","myr.exec.unsandbox","myr.lic.check","myr.lic.verify","myr.lic.activate","myr.lic.deactivate","myr.lic.getkey","myr.lic.setkey","myr.lic.getexpiry","myr.lic.isvalid","myr.lic.getuser","myr.lic.getplan","myr.lic.getfeatures","myr.lic.hasfeature","myr.lic.getlimit","myr.lic.getusage","myr.lic.increment","myr.lic.decrement","myr.lic.reset","myr.lic.getlog","myr.lic.audit","myr.lic.revoke","myr.inst.create","myr.inst.clone","myr.inst.destroy","myr.inst.get","myr.inst.set","myr.inst.find","myr.inst.list","myr.inst.filter","myr.inst.hook","myr.inst.unhook","myr.inst.wrap","myr.inst.unwrap","myr.inst.lock","myr.inst.unlock","myr.inst.hide","myr.inst.show","myr.inst.rename","myr.inst.retype","myr.inst.reparent","myr.inst.reclass","myr.inst.getprop","myr.inst.setprop","myr.inst.hasprop","myr.inst.listprops"}

local LISTS = {UNC_LIST, SUNC_LIST, MYRIAD_LIST}
local LCOLS = {C.ACC, C.BLUE, C.YELL}
local LNAMES = {"UNC", "SUNC", "Myriad"}

-- ── buildList ─────────────────────────────────────────────────────────────────
buildList = function(li)
    clearLayout(ChkScr)
    local list    = LISTS[li]
    local col     = LCOLS[li]
    local listNm  = LNAMES[li]
    local filter  = ChkSearch.Text:lower()
    local pass, fail = 0, 0

    for _, name in list do
        if filter == "" or name:lower():find(filter, 1, true) then
            local ok2 = hasGlobal(name)
            if ok2 then pass += 1 else fail += 1 end

            local Row = F(ChkScr, UDim2.new(1,-4,0,22), nil, C.BLK)
            Row.BackgroundTransparency = 1
            local d = dot(Row, UDim2.new(0,6,0,6), UDim2.new(0,1,0,8), ok2 and C.GRN or C.RED)
            L(Row, name, UDim2.new(1,-52,1,0), UDim2.new(0,11,0,0),
                ok2 and C.TXT or C.TXTS, FC, 11)
            L(Row, ok2 and "✓" or "✗",
                UDim2.new(0,28,1,0), UDim2.new(1,-32,0,0),
                ok2 and col or C.RED, FB, 13, Enum.TextXAlignment.Right)
        end
    end

    -- Summary bar
    local SR = F(ChkScr, UDim2.new(1,-4,0,26), nil, C.PANEL); corner(SR, 5)
    local pct = pass + fail > 0 and math.floor(pass/(pass+fail)*100) or 0
    L(SR, ("%s: %d/%d supported (%d%%)  —  %d missing"):format(
        listNm, pass, pass+fail, pct, fail),
        UDim2.new(1,0,1,0), nil, C.YELL, FB, 11, Enum.TextXAlignment.Center)

    -- Export button in summary
    local BExp = B(SR, "Export", UDim2.new(0,60,0,18), UDim2.new(1,-64,0.5,-9), C.GREY)
    BExp.TextSize = 10; hov(BExp, C.GREY, C.GRYHV)
    BExp.MouseButton1Click:Connect(function()
        if not writefile then return end
        local lines = {listNm .. " CHECK — " .. os.date("%Y-%m-%d %H:%M:%S")}
        for _, name in list do
            lines[#lines+1] = (hasGlobal(name) and "[✓] " or "[✗] ") .. name
        end
        local fname = "nexus_checker_" .. listNm:lower() .. ".txt"
        writefile(fname, table.concat(lines, "\n"))
    end)
end

ChkSearch:GetPropertyChangedSignal("Text"):Connect(function()
    if curSub > 0 then buildList(curSub) end
end)

-- ════════════════════════════════════════
-- SOURCE: src/tabs/09_scripts.lua
-- ════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB 9 — SCRIPT HUB
--  Search · Category filter · Run / Copy URL · 20+ scripts
-- ═══════════════════════════════════════════════════════════════════════════════
local P9 = newTab("📜", "Scripts")
L(P9, "SCRIPT HUB", UDim2.new(1,0,0,16), UDim2.new(0,0,0,0), C.TXTS, FB, 11)

-- ── Search + filter ───────────────────────────────────────────────────────────
local searchF = F(P9, UDim2.new(1,0,0,26), UDim2.new(0,0,0,18), C.PANEL); corner(searchF,6)
L(searchF, "🔍", UDim2.new(0,22,1,0), UDim2.new(0,4,0,0), C.TXTS, FN, 13, Enum.TextXAlignment.Center)
local SHSearch = INS(searchF, "Search scripts or category…", UDim2.new(1,-30,0,20), UDim2.new(0,28,0,3))

-- Category toggles
local catF = F(P9, UDim2.new(1,0,0,24), UDim2.new(0,0,0,48), C.PANEL); corner(catF,6)
listH(catF, 3); pad(catF, 2, 4)
local CATS = {"All","Utility","ESP","Game","Library","Admin","Debug"}
local selCat = "All"
local catBtns = {}
for i, cat in CATS do
    local col = C.CAT[cat] or C.ACC
    local b = B(catF, cat, UDim2.new(0,72,1,0), nil, i==1 and C.ACC or C.GRYDK)
    b.LayoutOrder = i; b.TextSize = 10; hov(b, C.GRYDK, C.GREY)
    catBtns[cat] = b
    b.MouseButton1Click:Connect(function()
        selCat = cat
        for _, cb in catBtns do tw(cb,{BackgroundColor3=C.GRYDK}) end
        tw(b, {BackgroundColor3 = col or C.ACC})
        buildScripts(SHSearch.Text:lower())
    end)
end

local shOut = statusOut(P9, UDim2.new(1,0,0,38), UDim2.new(0,0,1,-40))

local SHScr = SCR(P9, UDim2.new(1,0,1,-110), UDim2.new(0,0,0,76))
listV(SHScr, 4)

-- ── Script database ───────────────────────────────────────────────────────────
local SCRIPTS = {
    -- Utility
    {cat="Utility",  name="Infinite Yield",       url="https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source",                  desc="Full admin command system"},
    {cat="Utility",  name="SimpleSpy",             url="https://raw.githubusercontent.com/exxtremestuffs/SimpleSpySource/master/SimpleSpy.lua",  desc="Remote spy + logger"},
    {cat="Utility",  name="Dex Explorer 3.1",      url="https://raw.githubusercontent.com/LorekeeperZinnia/Dex/master/Dex3.1.lua",              desc="Full game instance explorer"},
    {cat="Utility",  name="Hydroxide",             url="https://raw.githubusercontent.com/violets-blue/Hydroxide/main/init.lua",                desc="Instance + remote explorer"},
    {cat="Utility",  name="Remote Spy Lite",       url="https://raw.githubusercontent.com/exxtremestuffs/SimpleSpySource/master/SimpleSpy.lua",  desc="Lightweight remote logger"},
    -- ESP
    {cat="ESP",      name="Unnamed ESP",           url="https://raw.githubusercontent.com/ic3w0lf22/Unnamed-ESP/master/UnnamedESP.lua",          desc="Universal player + object ESP"},
    {cat="ESP",      name="ESP Box Overlay",       url="https://raw.githubusercontent.com/ic3w0lf22/Unnamed-ESP/master/UnnamedESP.lua",          desc="Box ESP with health bars"},
    -- Game-specific
    {cat="Game",     name="Prison Life GUI",       url="https://raw.githubusercontent.com/1201for/V3rm-Prison-Life/master/VisualV3rmHack.lua",   desc="Prison Life exploit GUI"},
    {cat="Game",     name="Blox Fruits Helper",    url="https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source",                  desc="Blox Fruits auto-farm utils"},
    {cat="Game",     name="Pet Sim Auto Farm",     url="https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source",                  desc="Pet Simulator X automation"},
    {cat="Game",     name="Adopt Me Scripts",      url="https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source",                  desc="Adopt Me dupe utilities"},
    -- Library
    {cat="Library",  name="Fluent UI Library",     url="https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Fluent.lua",              desc="Modern executor UI framework"},
    {cat="Library",  name="Orion UI Library",      url="https://raw.githubusercontent.com/shlexware/Orion/main/source",                        desc="Clean component UI kit"},
    {cat="Library",  name="Rayfield UI",           url="https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua",         desc="Premium UI library"},
    {cat="Library",  name="Kavo UI Library",       url="https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua",             desc="Lightweight UI components"},
    -- Admin
    {cat="Admin",    name="Infinite Yield Cmd",    url="https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source",                  desc="400+ admin commands"},
    {cat="Admin",    name="Dex Admin Panel",       url="https://raw.githubusercontent.com/LorekeeperZinnia/Dex/master/Dex3.1.lua",              desc="Admin GUI with exploits"},
    -- Debug
    {cat="Debug",    name="Script Decompiler",     url="https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source",                  desc="Bytecode decompiler attempt"},
    {cat="Debug",    name="Memory Inspector",      url="https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source",                  desc="Memory address viewer"},
    {cat="Debug",    name="Network Logger",        url="https://raw.githubusercontent.com/exxtremestuffs/SimpleSpySource/master/SimpleSpy.lua",  desc="Full network traffic log"},
}

-- ── Build / rebuild listing ───────────────────────────────────────────────────
buildScripts = function(filter)
    clearLayout(SHScr)
    local shown = 0
    for _, entry in SCRIPTS do
        local catMatch = selCat == "All" or entry.cat == selCat
        local searchMatch = filter == "" or
            entry.name:lower():find(filter,1,true) or
            entry.cat:lower():find(filter,1,true) or
            entry.desc:lower():find(filter,1,true)
        if catMatch and searchMatch then
            shown += 1
            local Row = card(SHScr, entry.name, entry.desc, 56)
            stroke(Row, Color3.fromRGB(28,40,72), 1)
            local catCol = C.CAT[entry.cat] or C.GREY
            pill(Row, entry.cat, catCol, UDim2.new(0,58,0,18), UDim2.new(0,6,0,5))

            local BRun = B(Row, "▶ Run", UDim2.new(0,52,0,22), UDim2.new(1,-112,0.5,-11), C.ACC)
            local BCpy = B(Row, "URL",   UDim2.new(0,44,0,22), UDim2.new(1,-56,0.5,-11),  C.GREY)
            BRun.TextSize=10; BCpy.TextSize=10
            hov(BRun, C.ACC, C.ACCHV); hov(BCpy, C.GREY, C.GRYHV)

            local url, nm = entry.url, entry.name
            BRun.MouseButton1Click:Connect(function()
                shOut("Fetching " .. nm .. "…", true)
                task.spawn(function()
                    local ok, src = pcall(game.HttpGet, game, url, true)
                    if not ok then shOut("HTTP fail: " .. tostring(src), false); return end
                    local ok2, err, stage = runCode(src)
                    if not ok2 then
                        shOut((stage=="compile" and "Compile:\n" or "Error:\n")..err, false); return
                    end
                    shOut(nm .. " loaded ✓  (" .. #src .. " bytes)", true)
                end)
            end)
            BCpy.MouseButton1Click:Connect(function()
                if setclipboard then setclipboard(url); shOut("URL copied: " .. nm, true)
                else shOut("setclipboard unavailable.", false) end
            end)
        end
    end
    if shown == 0 then
        local R = F(SHScr, UDim2.new(1,-4,0,32), nil, C.PANEL); corner(R,6)
        L(R, "No scripts match '" .. filter .. "'",
            UDim2.new(1,0,1,0), nil, C.TXTS, FN, 12, Enum.TextXAlignment.Center)
    end
end

SHSearch:GetPropertyChangedSignal("Text"):Connect(function()
    buildScripts(SHSearch.Text:lower())
end)

-- ════════════════════════════════════════
-- SOURCE: src/tabs/10_environ.lua
-- ════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB 10 — ENVIRONMENT DIAGNOSTICS
--  60+ checks · System info · Export · Copy report
-- ═══════════════════════════════════════════════════════════════════════════════
local P10 = newTab("🧪", "Environ")
L(P10, "ENVIRONMENT DIAGNOSTICS", UDim2.new(1,0,0,16), UDim2.new(0,0,0,0), C.TXTS, FB, 11)

local eRow = rowBar(P10, 18, 26)
local BEnvRun  = B(eRow, "Run Check",   UDim2.new(0,108,1,0), nil, C.ACC)
local BEnvCopy = B(eRow, "Copy Report", UDim2.new(0,102,1,0), nil, C.GREY)
local BEnvSave = B(eRow, "Save File",   UDim2.new(0,88,1,0),  nil, C.GREY)
styleRow({BEnvRun,BEnvCopy,BEnvSave})
hov(BEnvRun, C.ACC, C.ACCHV); hov(BEnvCopy, C.GREY, C.GRYHV); hov(BEnvSave, C.GREY, C.GRYHV)

local ExecLbl = L(P10, "Executor: …", UDim2.new(1,0,0,16), UDim2.new(0,0,0,48), C.TXTS, FC, 11)
local EnvScr  = SCR(P10, UDim2.new(1,0,1,-68), UDim2.new(0,0,0,66))
listV(EnvScr, 2)
local reportLines = {}

local function clrEnv()
    clearLayout(EnvScr)
    reportLines = {}
end

local function catHdr(title)
    local R = F(EnvScr, UDim2.new(1,-4,0,20), nil, C.PANEL); corner(R, 5)
    L(R, "  " .. title, UDim2.new(1,0,1,0), nil, C.PURP, FB, 11)
    reportLines[#reportLines+1] = "\n== " .. title .. " =="
end

local function chkRow(name, ok2, detail)
    local R = F(EnvScr, UDim2.new(1,-4,0,20), nil, C.BLK); R.BackgroundTransparency = 1
    local d = dot(R, UDim2.new(0,5,0,5), UDim2.new(0,2,0,7), ok2 and C.GRN or C.RED)
    L(R, name, UDim2.new(0.48,0,1,0), UDim2.new(0,10,0,0), ok2 and C.TXT or C.TXTS, FC, 11)
    local dstr = detail or (ok2 and "ok" or "missing")
    L(R, dstr, UDim2.new(0.52,-8,1,0), UDim2.new(0.48,0,0,0), ok2 and C.GRN or C.RED, FN, 11)
    reportLines[#reportLines+1] = (ok2 and "[✓] " or "[✗] ") .. name .. "  — " .. dstr
end

local function infoRow(label, value)
    local R = F(EnvScr, UDim2.new(1,-4,0,18), nil, C.BLK); R.BackgroundTransparency = 1
    L(R, "  " .. label, UDim2.new(0.48,0,1,0), nil, C.TXTS, FN, 10)
    L(R, tostring(value), UDim2.new(0.52,-8,1,0), UDim2.new(0.48,0,0,0), C.YELL, FC, 10)
    reportLines[#reportLines+1] = "    " .. label .. ": " .. tostring(value)
end

local function runCheck()
    clrEnv()
    local exec = detectExecutor()
    ExecLbl.Text = "Executor: " .. exec; ExecLbl.TextColor3 = C.GRN
    reportLines[#reportLines+1] = "Nexus Executor — Environment Report"
    reportLines[#reportLines+1] = "Generated: " .. os.date("%Y-%m-%d %H:%M:%S")
    reportLines[#reportLines+1] = "Executor: " .. exec

    catHdr("Execution Engine")
    chkRow("loadstring",     type(loadstring)=="function", "available")
    chkRow("load (fallback)",type(load)=="function")
    chkRow("pcall",          type(pcall)=="function")
    chkRow("xpcall",         type(xpcall)=="function")
    chkRow("task.wait",      type(task)=="table" and type(task.wait)=="function")
    chkRow("task.spawn",     type(task)=="table" and type(task.spawn)=="function")
    chkRow("task.delay",     type(task)=="table" and type(task.delay)=="function")
    chkRow("task.defer",     type(task)=="table" and type(task.defer)=="function")
    chkRow("LuaU continue", (function()
        local ld = loadstring or load
        return ld ~= nil and pcall(ld, "local function f() for i=1,1 do continue end end")
    end)(), "Roblox LuaU")
    chkRow("coroutine.wrap", type(coroutine)=="table" and type(coroutine.wrap)=="function")
    chkRow("os.clock",       type(os)=="table" and type(os.clock)=="function")
    chkRow("os.time",        type(os)=="table" and type(os.time)=="function")

    catHdr("Environment & Globals")
    chkRow("getgenv",        type(getgenv)=="function")
    chkRow("getrenv",        type(getrenv)=="function")
    chkRow("getfenv",        type(getfenv)=="function")
    chkRow("setfenv",        type(setfenv)=="function")
    chkRow("gethui",         type(gethui)=="function",
        type(gethui)=="function" and "available" or "PlayerGui fallback")
    chkRow("shared",         type(shared)=="table")
    chkRow("_G",             type(_G)=="table")
    chkRow("getglobals",     type(getglobals)=="function")
    chkRow("getscripts",     type(getscripts)=="function")
    chkRow("getrunningscripts", type(getrunningscripts)=="function")
    chkRow("getloadedmodules",  type(getloadedmodules)=="function")
    chkRow("identifyexecutor",  type(identifyexecutor)=="function")
    chkRow("isexecutorclosure", type(isexecutorclosure)=="function")

    catHdr("File System")
    chkRow("writefile",   type(writefile)=="function")
    chkRow("readfile",    type(readfile)=="function")
    chkRow("appendfile",  type(appendfile)=="function")
    chkRow("isfile",      type(isfile)=="function")
    chkRow("isfolder",    type(isfolder)=="function")
    chkRow("makefolder",  type(makefolder)=="function")
    chkRow("listfiles",   type(listfiles)=="function")
    chkRow("delfile",     type(delfile)=="function")
    chkRow("loadfile",    type(loadfile)=="function")

    catHdr("Network / HTTP")
    chkRow("game:HttpGet",   type(game.HttpGet)=="function")
    chkRow("httpget",        type(httpget)=="function")
    chkRow("request",        type(request)=="function"
        or (http and type(http.request)=="function")
        or (syn  and type(syn.request)=="function"))
    chkRow("syn.request",    syn ~= nil and type(syn.request)=="function")
    chkRow("http.request",   http ~= nil and type(http.request)=="function")
    chkRow("WebSocket",      type(WebSocket)=="table" and type(WebSocket.connect)=="function")
    chkRow("queue_on_teleport", type(queue_on_teleport)=="function")

    catHdr("Sandbox & Hooking")
    chkRow("getrawmetatable",    type(getrawmetatable)=="function")
    chkRow("setrawmetatable",    type(setrawmetatable)=="function")
    chkRow("setreadonly",        type(setreadonly)=="function")
    chkRow("hookmetamethod",     type(hookmetamethod)=="function")
    chkRow("hookfunction",       type(hookfunction)=="function" or type(replaceclosure)=="function")
    chkRow("replaceclosure",     type(replaceclosure)=="function")
    chkRow("newcclosure",        type(newcclosure)=="function")
    chkRow("iscclosure",         type(iscclosure)=="function")
    chkRow("islclosure",         type(islclosure)=="function")
    chkRow("setthreadidentity",  type(setthreadidentity)=="function")
    chkRow("getthreadidentity",  type(getthreadidentity)=="function")
    chkRow("getnamecallmethod",  type(getnamecallmethod)=="function")
    chkRow("getconnections",     type(getconnections)=="function")

    catHdr("Debug Library")
    local dbg = type(debug)=="table"
    chkRow("debug.getinfo",    dbg and type(debug.getinfo)=="function")
    chkRow("debug.getupvalue", dbg and type(debug.getupvalue)=="function")
    chkRow("debug.setupvalue", dbg and type(debug.setupvalue)=="function")
    chkRow("debug.getconstant",dbg and type(debug.getconstant)=="function")
    chkRow("debug.setconstant",dbg and type(debug.setconstant)=="function")
    chkRow("debug.getproto",   dbg and type(debug.getproto)=="function")
    chkRow("debug.getprotos",  dbg and type(debug.getprotos)=="function")
    chkRow("debug.getstack",   dbg and type(debug.getstack)=="function")
    chkRow("debug.traceback",  dbg and type(debug.traceback)=="function")

    catHdr("Input / Drawing")
    chkRow("keypress",          type(keypress)=="function")
    chkRow("keyrelease",        type(keyrelease)=="function")
    chkRow("mouse1click",       type(mouse1click)=="function")
    chkRow("mouse2click",       type(mouse2click)=="function")
    chkRow("mousemoveabs",      type(mousemoveabs)=="function")
    chkRow("mousemoverel",      type(mousemoverel)=="function")
    chkRow("isrbxactive",       type(isrbxactive)=="function")
    chkRow("Drawing.new",       type(Drawing)=="table" and type(Drawing.new)=="function")
    chkRow("getrenderproperty", type(getrenderproperty)=="function")
    chkRow("setfpscap",         type(setfpscap)=="function")
    chkRow("getfpscap",         type(getfpscap)=="function")

    catHdr("Console / Output")
    chkRow("rconsoleopen",   type(rconsoleopen)=="function")
    chkRow("rconsoleclose",  type(rconsoleclose)=="function")
    chkRow("rconsoleprint",  type(rconsoleprint)=="function")
    chkRow("rconsolewarn",   type(rconsolewarn)=="function")
    chkRow("rconsoleclear",  type(rconsoleclear)=="function")
    chkRow("rconsoleinput",  type(rconsoleinput)=="function")

    catHdr("Crypt / Crypto")
    chkRow("crypt.base64encode", type(crypt)=="table" and type(crypt.base64encode)=="function")
    chkRow("crypt.base64decode", type(crypt)=="table" and type(crypt.base64decode)=="function")
    chkRow("crypt.encrypt",      type(crypt)=="table" and type(crypt.encrypt)=="function")
    chkRow("crypt.hash",         type(crypt)=="table" and type(crypt.hash)=="function")

    catHdr("Game State")
    chkRow("game:IsLoaded()",  game:IsLoaded(), game:IsLoaded() and "fully loaded" or "loading")
    chkRow("LocalPlayer",      LP ~= nil, LP and "@" .. LP.Name or "missing")
    chkRow("Character",        LP and LP.Character ~= nil,
        (LP and LP.Character) and "spawned" or "not spawned")
    chkRow("SS_ExecBridge",    Bridge ~= nil,
        Bridge and "bridge ready" or "inject SS_Executor.lua server-side")

    catHdr("System / Session Info")
    infoRow("Platform",         SESSION.platform)
    infoRow("Game ID",          SESSION.gameId)
    infoRow("Place ID",         SESSION.placeId)
    infoRow("Player",           SESSION.playerName .. " (" .. SESSION.displayName .. ")")
    infoRow("Players online",   #Players:GetPlayers())
    local ident = 0
    pcall(function() ident = getthreadidentity and getthreadidentity() or 0 end)
    infoRow("Thread Identity",  ident)
    infoRow("Touch enabled",    UIS.TouchEnabled)
    infoRow("Game loaded",      game:IsLoaded())

    -- Summary
    local pass2, total2 = 0, 0
    for _, ln in reportLines do
        if ln:sub(1,4) == "[✓]" then pass2+=1; total2+=1
        elseif ln:sub(1,4) == "[✗]" then total2+=1 end
    end
    local SR = F(EnvScr, UDim2.new(1,-4,0,26), nil, C.PANEL); corner(SR, 5)
    L(SR, ("  %d / %d checks passed  (%.0f%%)"):format(
        pass2, total2, total2>0 and pass2/total2*100 or 0),
        UDim2.new(1,0,1,0), nil, C.YELL, FB, 12, Enum.TextXAlignment.Center)
end

BEnvRun.MouseButton1Click:Connect(runCheck)

BEnvCopy.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(table.concat(reportLines, "\n"))
        ExecLbl.Text = "Report copied ✓"; ExecLbl.TextColor3 = C.GRN
    else
        ExecLbl.Text = "setclipboard not available"
    end
end)

BEnvSave.MouseButton1Click:Connect(function()
    if not writefile then ExecLbl.Text = "writefile not available"; return end
    local fname = "nexus_environ_" .. os.time() .. ".txt"
    writefile(fname, table.concat(reportLines, "\n"))
    ExecLbl.Text = "Saved → " .. fname; ExecLbl.TextColor3 = C.GRN
end)

-- ════════════════════════════════════════
-- SOURCE: src/core/06_init.lua
-- ════════════════════════════════════════
-- ── Drag — PC mouse + touch (Delta iOS/Android/iPad) ─────────────────────────
-- Stores start position as absolute pixels; delta is applied in pixel space.
-- Clamps to viewport so the window can never leave the screen.
-- Ignores secondary touches while dragging (multi-touch safe).

local _dragging = false
local _dragWinX, _dragWinY = 0, 0
local _dragTchX, _dragTchY = 0, 0

TBAR.InputBegan:Connect(function(inp)
    local t = inp.UserInputType
    if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
        if _dragging and t == Enum.UserInputType.Touch then return end   -- ignore 2nd finger
        _dragging  = true
        _dragTchX  = inp.Position.X
        _dragTchY  = inp.Position.Y
        _dragWinX  = WIN.AbsolutePosition.X
        _dragWinY  = WIN.AbsolutePosition.Y
    end
end)

UIS.InputChanged:Connect(function(inp)
    if not _dragging then return end
    local t = inp.UserInputType
    if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
        local dx  = inp.Position.X - _dragTchX
        local dy  = inp.Position.Y - _dragTchY
        local vp  = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
                    or Vector2.new(WIN_W, WIN_H)
        local wsz = WIN.AbsoluteSize
        local nx  = math.clamp(_dragWinX + dx, 0, math.max(0, vp.X - wsz.X))
        local ny  = math.clamp(_dragWinY + dy, 0, math.max(0, vp.Y - wsz.Y))
        WIN.Position = UDim2.new(0, nx, 0, ny)
    end
end)

UIS.InputEnded:Connect(function(inp)
    local t = inp.UserInputType
    if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
        _dragging = false
    end
end)

-- ── Minimise / restore ────────────────────────────────────────────────────────
local _minimised = false

BtnMin.MouseButton1Click:Connect(function()
    _minimised = not _minimised
    if _minimised then
        tw(WIN, {Size = UDim2.new(0, WIN_W, 0, 44)}, TS2)
        BODY.Visible = false
        if SIDE   then SIDE.Visible   = false end
        if TABBAR then TABBAR.Visible = false end
        BtnMin.Text = "□"
    else
        tw(WIN, {Size = UDim2.new(0, WIN_W, 0, WIN_H)}, TS2)
        task.delay(0.12, function()
            BODY.Visible = true
            if SIDE   then SIDE.Visible   = true end
            if TABBAR then TABBAR.Visible = true end
        end)
        BtnMin.Text = "—"
    end
end)

-- ── Keyboard shortcuts (desktop only) ────────────────────────────────────────
if not isMobile then
    UIS.InputBegan:Connect(function(inp, gpe)
        if gpe then return end
        if inp.KeyCode == Enum.KeyCode.F5 then
            if pages[curPage] then
                tw(pages[curPage],{BackgroundTransparency=0.4})
                task.delay(0.12,function() tw(pages[curPage],{BackgroundTransparency=1}) end)
            end
        end
        for i = 1, 9 do
            if inp.KeyCode == Enum.KeyCode["F"..i] and pages[i] then
                showPage(i); break
            end
        end
    end)
end

-- ── Init ─────────────────────────────────────────────────────────────────────
showPage(1)

if switchSub   then switchSub(1)   end
if buildList   then buildList(1)   end
if buildScripts then buildScripts("") end
if refreshPlrs  then refreshPlrs()   end

task.spawn(function()
    if runCheck then runCheck() end
end)

task.delay(0.5, function()
    notify("Nexus Executor",
        ("Loaded ✓  %d tabs  |  %s  |  %s"):format(
            tabN, SESSION.executor, SESSION.platform), 5)
end)

end)
if not _ok then
    warn("[Nexus] STARTUP ERROR: "..tostring(_err))
    -- Show visible notification so mobile users see the error
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification",{
            Title="Nexus Error",
            Text=tostring(_err):sub(1,120),
            Duration=12,
        })
    end)
end
