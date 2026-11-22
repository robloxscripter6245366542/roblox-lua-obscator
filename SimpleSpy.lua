-- ============================================================
--  SimpleSpy.lua  —  a clean, SimpleSpy-style remote spy
--
--  Classic layout: a scrolling LIST of remote calls down the left,
--  the generated code on the right, with Copy / Execute / Clear.
--
--  De-dupe: if the SAME remote keeps firing ("fluffing"), it does NOT
--  add a new row every time — the existing row's  xN  counter ticks up
--  and the code refreshes with the latest arguments. A remote that fires
--  500 times stays ONE row, not 500.
--
--  For studying your OWN game's client<->server traffic. It reads the
--  interface the client already uses; it can't read server source.
--
--  Executor: Delta and anything with hookmetamethod + getnamecallmethod.
--  Hotkey: RightShift toggles the window.
-- ============================================================

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui       = game:GetService("StarterGui")

--// Config
local CONFIG = {
    LogOutgoing  = true,    -- remotes YOU send to the server (FireServer/InvokeServer)
    LogIncoming  = true,    -- remotes the SERVER fires to you (FireClient/FireAllClients)
    MaxRows      = 250,     -- hard cap on unique rows (dedupe keeps it low)
    MaxStringLen = 5000,
    MaxDepth     = 6,
    ToggleKey    = Enum.KeyCode.RightShift,
    Acrylic      = true,    -- translucent, see-through glass panels
    Blur         = false,   -- frosted blur. NOTE: Roblox can only blur the WHOLE
                            -- screen (global BlurEffect), not just behind the
                            -- window, so this fogs the game too. Off by default.
    BlurSize     = 12,      -- strength of the frosted blur (if Blur = true)
}

--// Executor fns (safe)
local genv              = (getgenv and getgenv()) or _G
local hookmetamethod_fn = hookmetamethod
local getnamecallmethod_fn = getnamecallmethod
local checkcaller_fn    = checkcaller
local setclipboard_fn   = setclipboard or toclipboard or writeclipboard
local loadstring_fn     = loadstring
local gethui_fn         = gethui
local LocalPlayer       = Players.LocalPlayer

local function notify(t)
    print("[SimpleSpy] " .. t)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = "SimpleSpy", Text = t, Duration = 4 })
    end)
end

-- ============================================================
--  value -> runnable Lua
-- ============================================================
local function instancePath(inst)
    local ok, full = pcall(function() return inst:GetFullName() end)
    if not ok or not full then return nil end
    local segs = {}
    for seg in full:gmatch("[^%.]+") do segs[#segs + 1] = seg end
    if #segs == 0 then return nil end
    local services = {
        ReplicatedStorage=1, ReplicatedFirst=1, Workspace=1, Players=1, Lighting=1,
        StarterGui=1, StarterPack=1, StarterPlayer=1, SoundService=1, Teams=1, Chat=1,
    }
    local out = services[segs[1]] and ('game:GetService("%s")'):format(segs[1])
                                   or ('game:FindFirstChild("%s")'):format(segs[1])
    for i = 2, #segs do out = out .. (':WaitForChild("%s")'):format(segs[i]) end
    return out
end

local toLua
local function keyToLua(k)
    if type(k) == "string" and k:match("^[%a_][%w_]*$") then return k, true end
    return "[" .. toLua(k, 0) .. "]", false
end
toLua = function(v, depth)
    depth = depth or 0
    local t = typeof(v)
    if t == "string" then
        if #v > CONFIG.MaxStringLen then
            return ("%q"):format(v:sub(1, CONFIG.MaxStringLen)) .. " --[[ truncated ]]"
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
        if depth >= CONFIG.MaxDepth then return "{ --[[ max depth ]] }" end
        local pieces, isArray, n = {}, true, 0
        for k in pairs(v) do if type(k) ~= "number" then isArray = false end n = n + 1 if n > 200 then break end end
        local pad, closePad = string.rep("    ", depth + 2), string.rep("    ", depth + 1)
        local c = 0
        for k, val in pairs(v) do
            c = c + 1
            if c > 200 then pieces[#pieces + 1] = pad .. "-- ...(truncated)" break end
            if isArray then
                pieces[#pieces + 1] = pad .. toLua(val, depth + 1) .. ","
            else
                local ks = keyToLua(k)
                pieces[#pieces + 1] = pad .. ks .. " = " .. toLua(val, depth + 1) .. ","
            end
        end
        if #pieces == 0 then return "{}" end
        return "{\n" .. table.concat(pieces, "\n") .. "\n" .. closePad .. "}"
    else
        return ('nil --[[ <%s> %s ]]'):format(t, tostring(v))
    end
end

local function buildScript(remote, method, args, count, retText)
    local path = instancePath(remote) or ('nil --[[ "%s" ]]'):format(remote.Name)

    -- Incoming: the SERVER fired this remote to us (FireClient/FireAllClients),
    -- received on OnClientEvent. Show the args it sent + a listener you can run.
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
    local lines = { "-- " .. remote.ClassName .. "  |  :" .. method .. "()", "" }
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
--  UI
-- ============================================================
local C = {
    bg     = Color3.fromRGB(22, 23, 28),
    panel  = Color3.fromRGB(30, 32, 40),
    row    = Color3.fromRGB(38, 40, 50),
    rowSel = Color3.fromRGB(64, 86, 190),
    accent = Color3.fromRGB(96, 125, 255),
    good   = Color3.fromRGB(90, 200, 130),
    text   = Color3.fromRGB(235, 237, 245),
    sub    = Color3.fromRGB(150, 155, 170),
    badge  = Color3.fromRGB(255, 160, 70),
}
-- acrylic transparency levels (0 = opaque when Acrylic is off)
local T = {
    main  = CONFIG.Acrylic and 0.22 or 0,   -- window body
    bar   = CONFIG.Acrylic and 0.15 or 0,   -- title bar
    panel = CONFIG.Acrylic and 0.28 or 0,   -- list + code panels
    row   = CONFIG.Acrylic and 0.12 or 0,   -- call rows
}
local function mk(cls, props, kids)
    local o = Instance.new(cls)
    for k, v in pairs(props or {}) do o[k] = v end
    for _, c in ipairs(kids or {}) do c.Parent = o end
    return o
end
local function corner(r) return mk("UICorner", { CornerRadius = UDim.new(0, r or 6) }) end
local function padding(p) return mk("UIPadding", {
    PaddingTop = UDim.new(0, p), PaddingBottom = UDim.new(0, p),
    PaddingLeft = UDim.new(0, p), PaddingRight = UDim.new(0, p) }) end

if genv.SimpleSpy_GUI then pcall(function() genv.SimpleSpy_GUI:Destroy() end) end

local screen = mk("ScreenGui", {
    Name = "SimpleSpy", ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 9999,
})
genv.SimpleSpy_GUI = screen
pcall(function()
    screen.Parent = (gethui_fn and gethui_fn())
        or game:GetService("CoreGui")
        or LocalPlayer:WaitForChild("PlayerGui")
end)
if not screen.Parent then screen.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- frosted blur behind the window (lives in Lighting; toggled with visibility, removed on Stop)
local Lighting = game:GetService("Lighting")
local blur
pcall(function()  -- clear a blur left by a previous run
    local old = Lighting:FindFirstChild("SimpleSpyBlur")
    if old then old:Destroy() end
end)
if CONFIG.Blur then
    pcall(function()
        blur = mk("BlurEffect", { Name = "SimpleSpyBlur", Size = CONFIG.BlurSize, Parent = Lighting })
    end)
end

local main = mk("Frame", {
    Name = "Main", Parent = screen,
    Size = UDim2.new(0, 580, 0, 360), Position = UDim2.new(0.5, -290, 0.5, -180),
    BackgroundColor3 = C.bg, BackgroundTransparency = T.main, BorderSizePixel = 0, Active = true,
}, { corner(12) })
mk("UIStroke", { Color = C.rowSel, Thickness = 1.5, Transparency = 0.3, Parent = main })

-- show/hide helper that also drives the blur
local function setVisible(v)
    main.Visible = v
    if blur then blur.Enabled = v end
end

-- title bar
local bar = mk("Frame", { Parent = main, Size = UDim2.new(1, 0, 0, 36),
    BackgroundColor3 = C.panel, BackgroundTransparency = T.bar, BorderSizePixel = 0 }, { corner(12) })
mk("Frame", { Parent = bar, Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 1, -12),
    BackgroundColor3 = C.panel, BackgroundTransparency = T.bar, BorderSizePixel = 0 })
-- accent line under the title bar
mk("Frame", { Parent = bar, Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, 0),
    BackgroundColor3 = C.accent, BorderSizePixel = 0 })
-- accent dot before the title
mk("Frame", { Parent = bar, Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(0, 12, 0.5, -5),
    BackgroundColor3 = C.accent, BorderSizePixel = 0 }, { corner(5) })
mk("TextLabel", { Parent = bar, BackgroundTransparency = 1,
    Position = UDim2.new(0, 30, 0, 0), Size = UDim2.new(0.5, 0, 1, 0),
    Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = C.text,
    TextXAlignment = Enum.TextXAlignment.Left, Text = "SimpleSpy" })
local counter = mk("TextLabel", { Parent = bar, BackgroundTransparency = 1,
    Position = UDim2.new(1, -312, 0, 0), Size = UDim2.new(0, 150, 1, 0),
    Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.sub,
    TextXAlignment = Enum.TextXAlignment.Right, Text = "0 remotes" })
local function topBtn(txt, xoff, col)
    return mk("TextButton", { Parent = bar, AutoButtonColor = true,
        Size = UDim2.new(0, 46, 0, 22), Position = UDim2.new(1, xoff, 0.5, -11),
        BackgroundColor3 = col or C.row, BorderSizePixel = 0,
        Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = C.text, Text = txt },
        { corner(6) })
end
local recvBtn  = topBtn("Recv",  -156, CONFIG.LogIncoming and C.good or C.row)
local clearBtn = topBtn("Clear", -106)
local hideBtn  = topBtn("Hide",  -56)

-- body
local body = mk("Frame", { Parent = main, BackgroundTransparency = 1,
    Position = UDim2.new(0, 0, 0, 38), Size = UDim2.new(1, 0, 1, -38) })

-- left: list of calls
local list = mk("ScrollingFrame", { Name = "List", Parent = body,
    Position = UDim2.new(0, 8, 0, 6), Size = UDim2.new(0, 210, 1, -14),
    BackgroundColor3 = C.panel, BackgroundTransparency = T.panel, BorderSizePixel = 0, ScrollBarThickness = 4,
    ScrollBarImageColor3 = C.accent, CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y },
    { corner(8), padding(6),
      mk("UIStroke", { Color = C.row, Thickness = 1 }),
      mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })

-- right: code + buttons
local right = mk("Frame", { Parent = body, BackgroundTransparency = 1,
    Position = UDim2.new(0, 226, 0, 6), Size = UDim2.new(1, -234, 1, -14) })

-- code viewer: a clipping, scrolling container so long remotes never spill out
local codeScroll = mk("ScrollingFrame", { Parent = right, BackgroundColor3 = C.panel,
    BackgroundTransparency = T.panel,
    BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 1, -34),
    ClipsDescendants = true, ScrollBarThickness = 5, ScrollBarImageColor3 = C.accent,
    CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y },
    { corner(8), padding(8), mk("UIStroke", { Color = C.row, Thickness = 1 }) })
local codeBox = mk("TextBox", { Parent = codeScroll, BackgroundTransparency = 1, BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
    Font = Enum.Font.Code, TextSize = 13, TextColor3 = C.text,
    TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    MultiLine = true, ClearTextOnFocus = false, TextWrapped = true,
    Text = "-- fire a remote in-game and it shows up here", TextEditable = true })

local function actBtn(txt, scaleX, posX, col, tcol)
    return mk("TextButton", { Parent = right, AutoButtonColor = true,
        Size = UDim2.new(scaleX, -4, 0, 28), Position = UDim2.new(posX, 0, 1, -28),
        BackgroundColor3 = col, BorderSizePixel = 0, Font = Enum.Font.GothamBold,
        TextSize = 13, TextColor3 = tcol or C.text, Text = txt }, { corner(6) })
end
local copyBtn = actBtn("Copy",    0.5, 0,   C.accent)
local runBtn  = actBtn("Execute", 0.5, 0.5, C.good, Color3.fromRGB(12, 30, 18))

-- dragging
do
    local dragging, startIn, startPos
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging, startIn, startPos = true, i.Position, main.Position
            i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - startIn
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

-- ============================================================
--  rows (dedupe heart)
-- ============================================================
local rows = {}         -- key -> { button, badge, count, code, remote, method, args, argCount, shortName }
local order = 0
local selected = nil
local unique = 0

local function refreshCounter()
    counter.Text = unique .. (unique == 1 and " remote" or " remotes")
end

local function selectRow(key)
    selected = key
    local r = rows[key]
    if not r then return end
    codeBox.Text = r.code
    for k, v in pairs(rows) do v.button.BackgroundColor3 = (k == key) and C.rowSel or C.row end
end

local function makeRow(key, name, method)
    order = order + 1
    unique = unique + 1
    local btn = mk("TextButton", { Parent = list, LayoutOrder = -order, AutoButtonColor = true,
        Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = C.row, BackgroundTransparency = T.row,
        BorderSizePixel = 0, Text = "" },
        { corner(6) })
    local incoming = (method == "OnClientEvent")
    mk("TextLabel", { Parent = btn, BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 5), Size = UDim2.new(1, -48, 0, 16),
        Font = Enum.Font.GothamBold, TextSize = 12,
        TextColor3 = incoming and C.good or C.accent,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = incoming and ("RECV  " .. method) or (":" .. method .. "()") })
    mk("TextLabel", { Parent = btn, BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 22), Size = UDim2.new(1, -48, 0, 15),
        Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.text,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = name })
    local badge = mk("TextLabel", { Parent = btn, BackgroundColor3 = C.badge, BorderSizePixel = 0,
        Position = UDim2.new(1, -40, 0.5, -10), Size = UDim2.new(0, 34, 0, 20),
        Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Color3.fromRGB(25, 20, 10), Text = "x1" },
        { corner(10) })
    local r = { button = btn, badge = badge, count = 0, method = method, shortName = name,
                code = "", incoming = incoming }
    rows[key] = r
    btn.MouseButton1Click:Connect(function() selectRow(key) end)
    refreshCounter()
    return r
end

local function record(remote, method, args, argCount, retText)
    local ok, key = pcall(function() return remote:GetDebugId(0) .. "::" .. method end)
    if not ok then key = tostring(remote) .. "::" .. method end
    local r = rows[key]
    if not r then
        if unique >= CONFIG.MaxRows then return end
        r = makeRow(key, remote.Name, method)
    end
    r.count = r.count + 1
    r.badge.Text = r.count > 9999 and "9k+" or ("x" .. r.count)
    r.code = buildScript(remote, method, args, argCount, retText)
    r.remote, r.args, r.argCount = remote, args, argCount
    r.button.LayoutOrder = -(order + r.count)   -- bump most-recently-fired toward the top
    if selected == key then codeBox.Text = r.code end
    if selected == nil then selectRow(key) end
end

-- ============================================================
--  hook
-- ============================================================
local FIRE = { FireServer = true, fireServer = true, SendToServer = true }
local INVK = { InvokeServer = true, invokeServer = true }
local active, oldNamecall = true, nil

local function serializeReturn(res)
    local n = select("#", table.unpack(res))
    if n == 0 then return "" end
    local p = {}
    for i = 1, n do p[i] = toLua(res[i], 2) end
    return table.concat(p, ", ")
end

local function installHook()
    if not (hookmetamethod_fn and getnamecallmethod_fn) then
        notify("Executor lacks hookmetamethod/getnamecallmethod — capture unavailable.")
        return false
    end
    local ok, err = pcall(function()
        oldNamecall = hookmetamethod_fn(game, "__namecall", function(self, ...)
            if active and CONFIG.LogOutgoing and not (checkcaller_fn and checkcaller_fn()) then
                local m = getnamecallmethod_fn()
                if FIRE[m] and typeof(self) == "Instance" then
                    local a, c = { ... }, select("#", ...)
                    pcall(record, self, m, a, c, nil)
                    return oldNamecall(self, ...)
                elseif INVK[m] and typeof(self) == "Instance" then
                    local a, c = { ... }, select("#", ...)
                    local res = { oldNamecall(self, ...) }
                    local rt = ""
                    pcall(function() rt = serializeReturn(res) end)
                    pcall(record, self, m, a, c, rt)
                    return table.unpack(res)
                end
            end
            return oldNamecall(self, ...)
        end)
    end)
    if not ok then notify("Hook failed: " .. tostring(err)) return false end
    return true
end

-- ============================================================
--  incoming capture  (remotes the SERVER fires to you)
--
--  FireServer/InvokeServer are things YOU send, caught by __namecall above.
--  FireClient / FireAllClients arrive on each remote's OnClientEvent, which
--  __namecall never sees. So we connect a listener to every RemoteEvent and
--  log when the server fires it — this is the half that catches remotes that
--  "run on their own" / are driven by the server or other scripts.
--  (RemoteFunction OnClientInvoke allows only one callback, so it can't be
--  watched passively without hijacking the game's own handler; skipped.)
-- ============================================================
local connectedIncoming = setmetatable({}, { __mode = "k" })  -- remote -> true

local function connectIncoming(remote)
    if connectedIncoming[remote] then return end
    local cn = remote.ClassName
    if cn ~= "RemoteEvent" and cn ~= "UnreliableRemoteEvent" then return end
    connectedIncoming[remote] = true
    pcall(function()
        remote.OnClientEvent:Connect(function(...)
            if active and CONFIG.LogIncoming then
                local a, c = { ... }, select("#", ...)
                pcall(record, remote, "OnClientEvent", a, c, nil)
            end
        end)
    end)
end

local function startIncoming()
    -- existing remotes
    pcall(function()
        for _, inst in ipairs(game:GetDescendants()) do
            local cn = inst.ClassName
            if cn == "RemoteEvent" or cn == "UnreliableRemoteEvent" then
                connectIncoming(inst)
            end
        end
    end)
    -- remotes created later
    pcall(function()
        game.DescendantAdded:Connect(function(inst)
            local ok2, cn = pcall(function() return inst.ClassName end)
            if ok2 and (cn == "RemoteEvent" or cn == "UnreliableRemoteEvent") then
                connectIncoming(inst)
            end
        end)
    end)
end

-- ============================================================
--  buttons / api / hotkey
-- ============================================================
local function doClear()
    for _, r in pairs(rows) do pcall(function() r.button:Destroy() end) end
    rows, selected, unique = {}, nil, 0
    codeBox.Text = "-- fire a remote in-game and it shows up here"
    refreshCounter()
end
clearBtn.MouseButton1Click:Connect(doClear)

copyBtn.MouseButton1Click:Connect(function()
    if setclipboard_fn and selected and rows[selected] then
        pcall(setclipboard_fn, codeBox.Text)
        copyBtn.Text = "Copied"
        task.delay(1, function() if copyBtn then copyBtn.Text = "Copy" end end)
    else
        notify("Clipboard not available on this executor.")
    end
end)

runBtn.MouseButton1Click:Connect(function()
    if not (selected and rows[selected]) then return end
    local r = rows[selected]

    -- Incoming (RECV) rows are server->you; there's nothing to fire from here.
    if r.incoming then
        notify("This is an INCOMING remote (server->you). Nothing to fire here - pick a blue :FireServer() row to replay.")
        runBtn.Text = "RECV only"
        task.delay(1.4, function() if runBtn then runBtn.Text = "Execute" end end)
        return
    end

    runBtn.Text = "..."
    local ran, result
    if loadstring_fn then
        local fn, cErr = loadstring_fn(codeBox.Text)
        if not fn then notify("Compile error: " .. tostring(cErr)) runBtn.Text = "Execute" return end
        ran, result = pcall(fn)
    else
        ran, result = pcall(function()
            local n = r.argCount or 0
            if r.method:lower():find("invoke") then
                return r.remote[r.method](r.remote, table.unpack(r.args or {}, 1, n))
            else
                r.remote[r.method](r.remote, table.unpack(r.args or {}, 1, n))
            end
        end)
    end
    if ran then runBtn.Text = "Sent"; notify(("Executed :%s() on %s"):format(r.method, r.shortName))
    else runBtn.Text = "Error"; notify("Execute error: " .. tostring(result)) end
    task.delay(1.2, function() if runBtn then runBtn.Text = "Execute" end end)
end)

recvBtn.MouseButton1Click:Connect(function()
    CONFIG.LogIncoming = not CONFIG.LogIncoming
    recvBtn.BackgroundColor3 = CONFIG.LogIncoming and C.good or C.row
    notify("Incoming (server->you) logging " .. (CONFIG.LogIncoming and "ON" or "OFF"))
end)

hideBtn.MouseButton1Click:Connect(function() setVisible(false) end)
UserInputService.InputBegan:Connect(function(i, gpe)
    if not gpe and i.KeyCode == CONFIG.ToggleKey then setVisible(not main.Visible) end
end)

genv.SimpleSpy_Toggle = function() setVisible(not main.Visible) end
genv.SimpleSpy_Clear  = doClear
genv.SimpleSpy_Stop   = function()
    active = false
    pcall(function() screen:Destroy() end)
    if blur then pcall(function() blur:Destroy() end) end
    notify("Stopped.")
end

-- ============================================================
refreshCounter()
local ok = installHook()
startIncoming()   -- catch server->client remotes (the half __namecall can't see)
notify(ok and "Spying both ways: FireServer (you) + OnClientEvent (server). Spam collapses into xN. RightShift to toggle."
           or "GUI up (incoming capture active), but this executor can't hook namecall for outgoing.")
