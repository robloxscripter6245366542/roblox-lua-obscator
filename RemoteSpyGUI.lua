-- ============================================================
--  RemoteSpyGUI.lua  —  Tabbed remote spy with de-duplication
--
--  WHAT IT DOES
--    Hooks __namecall so that whenever the game fires a RemoteEvent /
--    RemoteFunction (:FireServer / :InvokeServer and the Unreliable /
--    Signal variants), it captures the remote, the method, the arguments
--    and the return value, then rebuilds a READY-TO-RUN Lua snippet.
--
--    Each UNIQUE remote gets ONE tab down the left side. If the same
--    remote keeps firing ("fluffing" / spamming), the tab is NOT
--    duplicated — its fire-counter ticks up and the code panel refreshes
--    with the most recent arguments. So a remote that fires 500 times is
--    still just one clean tab, not 500 of them.
--
--    Built for studying YOUR OWN game's client<->server protocol. It
--    reads the interface the client already uses; it cannot read server
--    source (that never leaves the server).
--
--  EXECUTOR
--    Made for Delta (and any executor exposing hookmetamethod +
--    getnamecallmethod). Degrades gracefully if a function is missing.
--
--  HOTKEYS / API (getgenv)
--    RemoteSpy_Toggle()  -> show / hide the window
--    RemoteSpy_Clear()   -> wipe all tabs
--    RemoteSpy_Stop()    -> unhook + destroy the GUI
--    RightShift          -> toggle the window
-- ============================================================

--// Services
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui       = game:GetService("StarterGui")

--// Config -------------------------------------------------------------
local CONFIG = {
    LogFire       = true,   -- FireServer / fireServer / SendToServer
    LogInvoke     = true,   -- InvokeServer / invokeServer (captures return)
    IgnoreSelf    = true,   -- never log remotes YOU fire from the executor
    MaxTabs       = 300,    -- hard cap on unique tabs (dedup keeps this low)
    MaxStringLen  = 5000,   -- truncate huge strings in generated code
    MaxDepth      = 6,      -- table serialization depth
    StartVisible  = true,
    ToggleKey     = Enum.KeyCode.RightShift,
}
-----------------------------------------------------------------------

--// Executor function resolution (safe)
local genv = (getgenv and getgenv()) or _G
local hookmetamethod_fn    = hookmetamethod
local getnamecallmethod_fn = getnamecallmethod
local checkcaller_fn       = checkcaller
local setclipboard_fn      = setclipboard or toclipboard or (writeclipboard)
local gethui_fn            = gethui
local LocalPlayer          = Players.LocalPlayer

local function notify(text)
    print("[RemoteSpy] " .. text)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = "Remote Spy", Text = text, Duration = 4 })
    end)
end

-- ====================================================================
--  VALUE  ->  VALID LUA
--  Rebuild arguments as runnable Lua literals wherever possible.
-- ====================================================================
local function instancePath(inst)
    -- Build:  game:GetService("ReplicatedStorage"):WaitForChild("A"):WaitForChild("B")
    local ok, full = pcall(function() return inst:GetFullName() end)
    if not ok or not full then return nil end
    local segs = {}
    for seg in full:gmatch("[^%.]+") do segs[#segs + 1] = seg end
    if #segs == 0 then return nil end
    -- The first segment is the service / DataModel child.
    local topServices = {
        ReplicatedStorage = true, ReplicatedFirst = true, Workspace = true,
        Players = true, Lighting = true, StarterGui = true, StarterPack = true,
        StarterPlayer = true, SoundService = true, Teams = true, Chat = true,
        ServerStorage = true, ServerScriptService = true, MaterialService = true,
    }
    local out
    if topServices[segs[1]] then
        out = ('game:GetService("%s")'):format(segs[1])
    else
        out = ('game:FindFirstChild("%s")'):format(segs[1])
    end
    for i = 2, #segs do
        out = out .. (':WaitForChild("%s")'):format(segs[i])
    end
    return out
end

local toLua -- forward decl

local function keyToLua(k)
    if type(k) == "string" and k:match("^[%a_][%w_]*$") then
        return k, true           -- bare identifier key  ->  k = v
    end
    return "[" .. toLua(k, 0) .. "]", false
end

toLua = function(v, depth)
    depth = depth or 0
    local t = typeof(v)

    if t == "string" then
        local s = v
        if #s > CONFIG.MaxStringLen then
            s = s:sub(1, CONFIG.MaxStringLen)
            return ("%q"):format(s) .. " --[[ truncated " .. tostring(#v) .. " chars ]]"
        end
        return ("%q"):format(s)

    elseif t == "number" then
        if v ~= v then return "0/0 --[[ nan ]]" end
        if v == math.huge then return "math.huge" end
        if v == -math.huge then return "-math.huge" end
        return tostring(v)

    elseif t == "boolean" or t == "nil" then
        return tostring(v)

    elseif t == "Vector3" then
        return ("Vector3.new(%s, %s, %s)"):format(v.X, v.Y, v.Z)
    elseif t == "Vector2" then
        return ("Vector2.new(%s, %s)"):format(v.X, v.Y)
    elseif t == "CFrame" then
        return ("CFrame.new(%s)"):format(table.concat({ v:GetComponents() }, ", "))
    elseif t == "Color3" then
        return ("Color3.new(%s, %s, %s)"):format(v.R, v.G, v.B)
    elseif t == "UDim2" then
        return ("UDim2.new(%s, %s, %s, %s)"):format(v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset)
    elseif t == "UDim" then
        return ("UDim.new(%s, %s)"):format(v.Scale, v.Offset)
    elseif t == "BrickColor" then
        return ('BrickColor.new("%s")'):format(v.Name)
    elseif t == "EnumItem" then
        return tostring(v)                       -- e.g. Enum.KeyCode.E
    elseif t == "Enum" then
        return "Enum." .. tostring(v)
    elseif t == "NumberRange" then
        return ("NumberRange.new(%s, %s)"):format(v.Min, v.Max)
    elseif t == "Instance" then
        local p = instancePath(v)
        if p then return p end
        return ('nil --[[ Instance <%s> "%s" (unresolved path) ]]'):format(v.ClassName, v.Name)

    elseif t == "table" then
        if depth >= CONFIG.MaxDepth then return "{ --[[ max depth ]] }" end
        local pieces = {}
        local pad    = string.rep("    ", depth + 2)
        local closePad = string.rep("    ", depth + 1)
        -- array part first for readability
        local n = 0
        local isArray = true
        for k in pairs(v) do
            if type(k) ~= "number" then isArray = false end
            n = n + 1
            if n > 200 then break end
        end
        local count = 0
        for k, val in pairs(v) do
            count = count + 1
            if count > 200 then
                pieces[#pieces + 1] = pad .. "-- ... (truncated)"
                break
            end
            if isArray then
                pieces[#pieces + 1] = pad .. toLua(val, depth + 1) .. ","
            else
                local ks, bare = keyToLua(k)
                if bare then
                    pieces[#pieces + 1] = pad .. ks .. " = " .. toLua(val, depth + 1) .. ","
                else
                    pieces[#pieces + 1] = pad .. ks .. " = " .. toLua(val, depth + 1) .. ","
                end
            end
        end
        if #pieces == 0 then return "{}" end
        return "{\n" .. table.concat(pieces, "\n") .. "\n" .. closePad .. "}"

    else
        -- userdata we can't rebuild (Ray, Region3, etc.)
        return ('nil --[[ <%s> %s ]]'):format(t, tostring(v))
    end
end

-- Build the full runnable snippet for a captured call.
local function buildScript(remote, method, argList, argCount, retText)
    local path = instancePath(remote) or ('nil --[[ could not resolve "%s" ]]'):format(remote.Name)
    local lines = {}

    lines[#lines + 1] = "-- " .. remote.ClassName .. "  |  :" .. method .. "()"
    lines[#lines + 1] = ""

    if argCount == 0 then
        lines[#lines + 1] = "local remote = " .. path
        if method:lower():find("invoke") then
            lines[#lines + 1] = "local result = remote:" .. method .. "()"
        else
            lines[#lines + 1] = "remote:" .. method .. "()"
        end
    else
        lines[#lines + 1] = "local args = {"
        for i = 1, argCount do
            lines[#lines + 1] = "    " .. toLua(argList[i], 0) .. ","
        end
        lines[#lines + 1] = "}"
        lines[#lines + 1] = ""
        lines[#lines + 1] = "local remote = " .. path
        if method:lower():find("invoke") then
            lines[#lines + 1] = "local result = remote:" .. method .. "(unpack(args))"
        else
            lines[#lines + 1] = "remote:" .. method .. "(unpack(args))"
        end
    end

    if retText and retText ~= "" then
        lines[#lines + 1] = ""
        lines[#lines + 1] = "--[[ server returned: " .. retText .. " ]]"
    end

    return table.concat(lines, "\n")
end

-- ====================================================================
--  GUI
-- ====================================================================
local COLOR = {
    bg      = Color3.fromRGB(24, 25, 31),
    panel   = Color3.fromRGB(31, 33, 41),
    panel2  = Color3.fromRGB(38, 40, 50),
    accent  = Color3.fromRGB(96, 125, 255),
    accent2 = Color3.fromRGB(70, 95, 220),
    text    = Color3.fromRGB(235, 237, 245),
    sub     = Color3.fromRGB(150, 155, 170),
    good    = Color3.fromRGB(90, 200, 130),
    badge   = Color3.fromRGB(255, 160, 70),
}

local function mk(class, props, children)
    local o = Instance.new(class)
    for k, val in pairs(props or {}) do o[k] = val end
    for _, c in ipairs(children or {}) do c.Parent = o end
    return o
end
local function corner(r) return mk("UICorner", { CornerRadius = UDim.new(0, r or 6) }) end
local function pad(p) return mk("UIPadding", {
    PaddingTop = UDim.new(0, p), PaddingBottom = UDim.new(0, p),
    PaddingLeft = UDim.new(0, p), PaddingRight = UDim.new(0, p) }) end

-- Destroy any previous instance
if genv.RemoteSpy_GUI then pcall(function() genv.RemoteSpy_GUI:Destroy() end) end

local screen = mk("ScreenGui", {
    Name = "RemoteSpyGUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 9999,
})
genv.RemoteSpy_GUI = screen

-- Parent to the safest available container
pcall(function()
    if gethui_fn then
        screen.Parent = gethui_fn()
    elseif game:GetService("CoreGui") then
        screen.Parent = game:GetService("CoreGui")
    else
        screen.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end)
if not screen.Parent then
    screen.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local main = mk("Frame", {
    Name = "Main", Parent = screen,
    Size = UDim2.new(0, 560, 0, 360),
    Position = UDim2.new(0.5, -280, 0.5, -180),
    BackgroundColor3 = COLOR.bg,
    BorderSizePixel = 0,
    Active = true,
    Visible = CONFIG.StartVisible,
}, { corner(10) })
mk("UIStroke", { Color = COLOR.panel2, Thickness = 1, Parent = main })

-- Title bar ----------------------------------------------------------
local bar = mk("Frame", {
    Name = "Bar", Parent = main,
    Size = UDim2.new(1, 0, 0, 36),
    BackgroundColor3 = COLOR.panel,
    BorderSizePixel = 0,
}, { corner(10) })
mk("Frame", { Parent = bar, Size = UDim2.new(1, 0, 0, 12),
    Position = UDim2.new(0, 0, 1, -12), BackgroundColor3 = COLOR.panel, BorderSizePixel = 0 })

local title = mk("TextLabel", {
    Parent = bar, BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -220, 1, 0),
    Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = COLOR.text,
    TextXAlignment = Enum.TextXAlignment.Left, Text = "Remote Spy",
})

local counter = mk("TextLabel", {
    Parent = bar, BackgroundTransparency = 1,
    Position = UDim2.new(1, -210, 0, 0), Size = UDim2.new(0, 110, 1, 0),
    Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = COLOR.sub,
    TextXAlignment = Enum.TextXAlignment.Right, Text = "0 remotes",
})

local function barBtn(text, xOff, color)
    return mk("TextButton", {
        Parent = bar, AutoButtonColor = true,
        Size = UDim2.new(0, 46, 0, 24), Position = UDim2.new(1, xOff, 0.5, -12),
        BackgroundColor3 = color or COLOR.panel2, BorderSizePixel = 0,
        Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = COLOR.text, Text = text,
    }, { corner(6) })
end
local clearBtn = barBtn("Clear", -96)
local hideBtn  = barBtn("Hide",  -46)

-- Body: left tab list + right code panel -----------------------------
local body = mk("Frame", {
    Parent = main, BackgroundTransparency = 1,
    Position = UDim2.new(0, 0, 0, 36), Size = UDim2.new(1, 0, 1, -36),
})

local list = mk("ScrollingFrame", {
    Name = "List", Parent = body,
    Position = UDim2.new(0, 8, 0, 6), Size = UDim2.new(0, 190, 1, -14),
    BackgroundColor3 = COLOR.panel, BorderSizePixel = 0,
    ScrollBarThickness = 4, ScrollBarImageColor3 = COLOR.accent,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
}, { corner(8), pad(6),
    mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })

local right = mk("Frame", {
    Parent = body, BackgroundTransparency = 1,
    Position = UDim2.new(0, 206, 0, 6), Size = UDim2.new(1, -214, 1, -14),
})

local header = mk("TextLabel", {
    Parent = right, BackgroundColor3 = COLOR.panel, BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 30), Font = Enum.Font.GothamMedium, TextSize = 13,
    TextColor3 = COLOR.text, TextXAlignment = Enum.TextXAlignment.Left,
    Text = "  Select a remote on the left",
}, { corner(8) })

local copyBtn = mk("TextButton", {
    Parent = header, AutoButtonColor = true,
    Size = UDim2.new(0, 60, 0, 22), Position = UDim2.new(1, -66, 0.5, -11),
    BackgroundColor3 = COLOR.accent, BorderSizePixel = 0,
    Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = COLOR.text, Text = "Copy",
    Visible = false,
}, { corner(6) })

local codeBox = mk("TextBox", {
    Parent = right, BackgroundColor3 = COLOR.panel, BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 0, 36), Size = UDim2.new(1, 0, 1, -36),
    Font = Enum.Font.Code, TextSize = 13, TextColor3 = COLOR.text,
    TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    MultiLine = true, ClearTextOnFocus = false, TextWrapped = false,
    Text = "", TextEditable = false,
}, { corner(8), pad(8) })

-- Dragging -----------------------------------------------------------
do
    local dragging, dragStart, startPos
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                      startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

-- ====================================================================
--  TAB STORE  (the de-dup heart)
--  tabs[key] = { button, badge, count, code, remote, method }
-- ====================================================================
local tabs = {}
local tabOrder = 0
local selectedKey = nil
local uniqueCount = 0

local function refreshCounter()
    counter.Text = uniqueCount .. (uniqueCount == 1 and " remote" or " remotes")
end

local function selectTab(key)
    selectedKey = key
    local t = tabs[key]
    if not t then return end
    header.Text = ("  %s   :%s()   x%d"):format(t.shortName, t.method, t.count)
    copyBtn.Visible = true
    codeBox.Text = t.code
    -- highlight
    for k, v in pairs(tabs) do
        v.button.BackgroundColor3 = (k == key) and COLOR.accent2 or COLOR.panel2
    end
end

local function makeTab(key, shortName, method)
    tabOrder = tabOrder + 1
    uniqueCount = uniqueCount + 1

    local btn = mk("TextButton", {
        Parent = list, LayoutOrder = tabOrder, AutoButtonColor = true,
        Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = COLOR.panel2, BorderSizePixel = 0,
        Text = "", AutomaticSize = Enum.AutomaticSize.None,
    }, { corner(6) })

    local name = mk("TextLabel", {
        Parent = btn, BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 4), Size = UDim2.new(1, -46, 0, 18),
        Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = COLOR.text,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        Text = shortName,
    })
    mk("TextLabel", {
        Parent = btn, BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 21), Size = UDim2.new(1, -46, 0, 15),
        Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = COLOR.sub,
        TextXAlignment = Enum.TextXAlignment.Left, Text = ":" .. method .. "()",
    })

    local badge = mk("TextLabel", {
        Parent = btn, BackgroundColor3 = COLOR.badge, BorderSizePixel = 0,
        Position = UDim2.new(1, -40, 0.5, -10), Size = UDim2.new(0, 34, 0, 20),
        Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Color3.fromRGB(25, 20, 10),
        Text = "x1",
    }, { corner(10) })

    local t = {
        button = btn, badge = badge, nameLabel = name, count = 0,
        code = "", method = method, shortName = shortName,
    }
    tabs[key] = t

    btn.MouseButton1Click:Connect(function() selectTab(key) end)
    refreshCounter()
    return t
end

-- ====================================================================
--  RECORD  (called from the hook)
-- ====================================================================
local function record(remote, method, argList, argCount, retText)
    local ok, key = pcall(function() return remote:GetDebugId(0) .. "::" .. method end)
    if not ok then key = tostring(remote) .. "::" .. method end

    local t = tabs[key]
    if not t then
        if uniqueCount >= CONFIG.MaxTabs then return end   -- safety cap
        t = makeTab(key, remote.Name, method)
    end

    t.count = t.count + 1
    t.badge.Text = t.count > 9999 and "9k+" or ("x" .. t.count)
    t.code = buildScript(remote, method, argList, argCount, retText)

    -- Only repaint the code panel if this tab is the one on screen.
    if selectedKey == key then
        header.Text = ("  %s   :%s()   x%d"):format(t.shortName, method, t.count)
        codeBox.Text = t.code
    end

    -- First ever capture: auto-select so the user sees something immediately.
    if selectedKey == nil then selectTab(key) end
end

-- ====================================================================
--  THE HOOK
-- ====================================================================
local FIRE = {
    FireServer = true, fireServer = true,
    SendToServer = true,   -- UnreliableRemoteEvent alt name on some engines
}
local INVK = { InvokeServer = true, invokeServer = true }

local active = true
local oldNamecall

local function serializeReturn(results)
    local n = select("#", table.unpack(results))
    if n == 0 then return "" end
    local parts = {}
    for i = 1, n do parts[i] = toLua(results[i], 2) end
    return table.concat(parts, ", ")
end

local function installHook()
    if not (hookmetamethod_fn and getnamecallmethod_fn) then
        notify("Executor lacks hookmetamethod/getnamecallmethod — passive capture unavailable.")
        return false
    end
    local ok, err = pcall(function()
        oldNamecall = hookmetamethod_fn(game, "__namecall", function(self, ...)
            if active and not (CONFIG.IgnoreSelf and checkcaller_fn and checkcaller_fn()) then
                local method = getnamecallmethod_fn()

                if CONFIG.LogFire and FIRE[method] and typeof(self) == "Instance" then
                    local args, count = { ... }, select("#", ...)
                    pcall(record, self, method, args, count, nil)
                    return oldNamecall(self, ...)
                end

                if CONFIG.LogInvoke and INVK[method] and typeof(self) == "Instance" then
                    local args, count = { ... }, select("#", ...)
                    local results = { oldNamecall(self, ...) }
                    local retText = ""
                    pcall(function() retText = serializeReturn(results) end)
                    pcall(record, self, method, args, count, retText)
                    return table.unpack(results)
                end
            end
            return oldNamecall(self, ...)
        end)
    end)
    if not ok then
        notify("Failed to install hook: " .. tostring(err))
        return false
    end
    return true
end

-- ====================================================================
--  BUTTONS / API / HOTKEY
-- ====================================================================
local function doClear()
    for _, t in pairs(tabs) do pcall(function() t.button:Destroy() end) end
    tabs, selectedKey, uniqueCount = {}, nil, 0
    header.Text = "  Select a remote on the left"
    copyBtn.Visible = false
    codeBox.Text = ""
    refreshCounter()
end
clearBtn.MouseButton1Click:Connect(doClear)

copyBtn.MouseButton1Click:Connect(function()
    if setclipboard_fn and selectedKey and tabs[selectedKey] then
        pcall(setclipboard_fn, tabs[selectedKey].code)
        copyBtn.Text = "Copied"
        task.delay(1, function() if copyBtn then copyBtn.Text = "Copy" end end)
    else
        notify("Clipboard not available on this executor.")
    end
end)

local function setVisible(v) main.Visible = v end
hideBtn.MouseButton1Click:Connect(function() setVisible(false) end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == CONFIG.ToggleKey then setVisible(not main.Visible) end
end)

genv.RemoteSpy_Toggle = function() setVisible(not main.Visible) end
genv.RemoteSpy_Clear  = function() doClear() end
genv.RemoteSpy_Stop   = function()
    active = false
    pcall(function() screen:Destroy() end)
    notify("Stopped. (Hook left in place but inert.)")
end

-- ====================================================================
--  GO
-- ====================================================================
refreshCounter()
local installed = installHook()
notify(installed
    and "Capturing remotes. One tab per remote; spam collapses into a counter. RightShift to toggle."
    or  "GUI is up, but this executor can't hook namecall — no passive capture.")
