--[[
    Curved Script GUI
    Tabs: LoadString | Module Loader
    Works as a LocalScript inside a ScreenGui, or paste into any executor.
--]]

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- ──────────────────────────────────────────────────────────────────────────────
-- Theme
-- ──────────────────────────────────────────────────────────────────────────────
local T = {
    BG          = Color3.fromRGB(18,  18,  24),
    Surface     = Color3.fromRGB(26,  26,  36),
    Card        = Color3.fromRGB(34,  34,  48),
    Border      = Color3.fromRGB(55,  55,  78),
    Accent      = Color3.fromRGB(120, 87, 255),
    AccentHover = Color3.fromRGB(145, 110, 255),
    Success     = Color3.fromRGB(72,  199, 142),
    Error       = Color3.fromRGB(255,  82,  82),
    Text        = Color3.fromRGB(230, 230, 240),
    SubText     = Color3.fromRGB(130, 130, 155),
    TitleBar    = Color3.fromRGB(22,  22,  30),
    TabActive   = Color3.fromRGB(120, 87, 255),
    TabInactive = Color3.fromRGB(40,  40,  58),
}

-- ──────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ──────────────────────────────────────────────────────────────────────────────
local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color     = color or T.Border
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function tween(obj, props, t, style, dir)
    TweenService:Create(obj,
        TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
        props
    ):Play()
end

local function makeButton(parent, text, size, pos, radius)
    local btn = Instance.new("TextButton")
    btn.Size            = size
    btn.Position        = pos
    btn.BackgroundColor3 = T.Accent
    btn.TextColor3      = T.Text
    btn.Font            = Enum.Font.GothamBold
    btn.TextSize        = 14
    btn.Text            = text
    btn.AutoButtonColor = false
    btn.Parent          = parent
    corner(btn, radius or 8)
    stroke(btn, T.Accent, 1)

    btn.MouseEnter:Connect(function()
        tween(btn, {BackgroundColor3 = T.AccentHover})
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, {BackgroundColor3 = T.Accent})
    end)
    btn.MouseButton1Down:Connect(function()
        tween(btn, {BackgroundColor3 = T.Border})
    end)
    btn.MouseButton1Up:Connect(function()
        tween(btn, {BackgroundColor3 = T.AccentHover})
    end)
    return btn
end

local function label(parent, text, size, pos, textSize, color, font, align)
    local lbl = Instance.new("TextLabel")
    lbl.Size             = size
    lbl.Position         = pos
    lbl.BackgroundTransparency = 1
    lbl.TextColor3       = color or T.Text
    lbl.Font             = font or Enum.Font.Gotham
    lbl.TextSize         = textSize or 14
    lbl.Text             = text
    lbl.TextXAlignment   = align or Enum.TextXAlignment.Left
    lbl.Parent           = parent
    return lbl
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Status bar flash
-- ──────────────────────────────────────────────────────────────────────────────
local statusLabel
local function setStatus(msg, ok)
    if not statusLabel then return end
    statusLabel.Text       = msg
    statusLabel.TextColor3 = ok and T.Success or T.Error
    task.delay(4, function()
        if statusLabel.Text == msg then
            tween(statusLabel, {TextColor3 = T.SubText})
            task.delay(0.3, function()
                if statusLabel.Text == msg then
                    statusLabel.Text = "Ready."
                end
            end)
        end
    end)
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Drag logic
-- ──────────────────────────────────────────────────────────────────────────────
local function makeDraggable(handle, frame)
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
                         input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Build ScreenGui
-- ──────────────────────────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name              = "CurvedScriptGUI"
screenGui.ResetOnSpawn      = false
screenGui.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset    = true
screenGui.Parent            = PlayerGui

-- Main window frame
local win = Instance.new("Frame")
win.Name             = "Window"
win.Size             = UDim2.new(0, 540, 0, 400)
win.Position         = UDim2.new(0.5, -270, 0.5, -200)
win.BackgroundColor3 = T.BG
win.BorderSizePixel  = 0
win.Parent           = screenGui
corner(win, 14)
stroke(win, T.Border, 1.5)

-- Drop shadow (visual trick using a larger frame behind)
local shadow = Instance.new("Frame")
shadow.Name             = "Shadow"
shadow.Size             = UDim2.new(1, 20, 1, 20)
shadow.Position         = UDim2.new(0, -10, 0, 8)
shadow.BackgroundColor3 = Color3.new(0, 0, 0)
shadow.BackgroundTransparency = 0.6
shadow.BorderSizePixel  = 0
shadow.ZIndex           = win.ZIndex - 1
shadow.Parent           = win
corner(shadow, 18)

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Name             = "TitleBar"
titleBar.Size             = UDim2.new(1, 0, 0, 44)
titleBar.BackgroundColor3 = T.TitleBar
titleBar.BorderSizePixel  = 0
titleBar.Parent           = win
corner(titleBar, 14)

-- Fix bottom corners of title bar (make them square to blend with content)
local titleFix = Instance.new("Frame")
titleFix.Size             = UDim2.new(1, 0, 0.5, 0)
titleFix.Position         = UDim2.new(0, 0, 0.5, 0)
titleFix.BackgroundColor3 = T.TitleBar
titleFix.BorderSizePixel  = 0
titleFix.Parent           = titleBar

-- Title icon + text
local titleIcon = label(titleBar, "⚡", UDim2.new(0, 28, 0, 28), UDim2.new(0, 12, 0.5, -14), 18, T.Accent, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
local titleText = label(titleBar, "Script Hub", UDim2.new(0, 160, 1, 0), UDim2.new(0, 42, 0, 0), 15, T.Text, Enum.Font.GothamBold, Enum.TextXAlignment.Left)
local subTitle  = label(titleBar, "LoadString & Module Runner", UDim2.new(0, 220, 1, 0), UDim2.new(0, 42, 0, 0), 11, T.SubText, Enum.Font.Gotham, Enum.TextXAlignment.Left)

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size             = UDim2.new(0, 28, 0, 28)
closeBtn.Position         = UDim2.new(1, -38, 0.5, -14)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
closeBtn.TextColor3       = Color3.new(1,1,1)
closeBtn.Font             = Enum.Font.GothamBold
closeBtn.TextSize         = 14
closeBtn.Text             = "✕"
closeBtn.AutoButtonColor  = false
closeBtn.Parent           = titleBar
corner(closeBtn, 6)
closeBtn.MouseButton1Click:Connect(function()
    tween(win, {Size = UDim2.new(0, 540, 0, 0), BackgroundTransparency = 1}, 0.2)
    task.delay(0.22, function() screenGui:Destroy() end)
end)

-- Minimise button
local minBtn = Instance.new("TextButton")
minBtn.Size             = UDim2.new(0, 28, 0, 28)
minBtn.Position         = UDim2.new(1, -72, 0.5, -14)
minBtn.BackgroundColor3 = Color3.fromRGB(255, 190, 50)
minBtn.TextColor3       = Color3.new(0.15, 0.10, 0)
minBtn.Font             = Enum.Font.GothamBold
minBtn.TextSize         = 14
minBtn.Text             = "─"
minBtn.AutoButtonColor  = false
minBtn.Parent           = titleBar
corner(minBtn, 6)
local minimised = false
minBtn.MouseButton1Click:Connect(function()
    minimised = not minimised
    tween(win, {Size = minimised and UDim2.new(0, 540, 0, 44) or UDim2.new(0, 540, 0, 400)}, 0.22)
end)

makeDraggable(titleBar, win)

-- ──────────────────────────────────────────────────────────────────────────────
-- Tab bar
-- ──────────────────────────────────────────────────────────────────────────────
local tabBar = Instance.new("Frame")
tabBar.Name             = "TabBar"
tabBar.Size             = UDim2.new(1, -24, 0, 34)
tabBar.Position         = UDim2.new(0, 12, 0, 52)
tabBar.BackgroundColor3 = T.Surface
tabBar.BorderSizePixel  = 0
tabBar.Parent           = win
corner(tabBar, 8)
stroke(tabBar, T.Border, 1)

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection      = Enum.FillDirection.Horizontal
tabLayout.SortOrder          = Enum.SortOrder.LayoutOrder
tabLayout.Padding            = UDim.new(0, 4)
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
tabLayout.VerticalAlignment  = Enum.VerticalAlignment.Center
tabLayout.Parent             = tabBar

local tabPad = Instance.new("UIPadding")
tabPad.PaddingLeft  = UDim.new(0, 6)
tabPad.PaddingTop   = UDim.new(0, 4)
tabPad.PaddingBottom = UDim.new(0, 4)
tabPad.Parent       = tabBar

-- Content area
local content = Instance.new("Frame")
content.Name             = "Content"
content.Size             = UDim2.new(1, -24, 1, -108)
content.Position         = UDim2.new(0, 12, 0, 94)
content.BackgroundTransparency = 1
content.Parent           = win

-- Status bar
local statusBar = Instance.new("Frame")
statusBar.Size             = UDim2.new(1, -24, 0, 24)
statusBar.Position         = UDim2.new(0, 12, 1, -30)
statusBar.BackgroundTransparency = 1
statusBar.Parent           = win

statusLabel = label(statusBar, "Ready.", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 12, T.SubText, Enum.Font.GothamMedium, Enum.TextXAlignment.Left)

-- ──────────────────────────────────────────────────────────────────────────────
-- Tab system
-- ──────────────────────────────────────────────────────────────────────────────
local tabs = {}
local activeTab = nil

local function makeTab(name, icon, order)
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(0, 130, 0, 26)
    btn.BackgroundColor3 = T.TabInactive
    btn.TextColor3       = T.SubText
    btn.Font             = Enum.Font.GothamMedium
    btn.TextSize         = 13
    btn.Text             = icon .. "  " .. name
    btn.AutoButtonColor  = false
    btn.LayoutOrder      = order
    btn.Parent           = tabBar
    corner(btn, 6)

    local page = Instance.new("Frame")
    page.Name             = name
    page.Size             = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible          = false
    page.Parent           = content

    local entry = {btn = btn, page = page}
    table.insert(tabs, entry)

    btn.MouseButton1Click:Connect(function()
        for _, t in tabs do
            t.btn.BackgroundColor3 = T.TabInactive
            t.btn.TextColor3       = T.SubText
            t.page.Visible         = false
        end
        btn.BackgroundColor3 = T.TabActive
        btn.TextColor3       = T.Text
        page.Visible         = true
        activeTab            = entry
    end)

    return page
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Tab 1: LoadString
-- ──────────────────────────────────────────────────────────────────────────────
local lsPage = makeTab("LoadString", "❯_", 1)

label(lsPage, "Lua Script", UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 0, 0), 12, T.SubText)

local editorFrame = Instance.new("Frame")
editorFrame.Size             = UDim2.new(1, 0, 1, -60)
editorFrame.Position         = UDim2.new(0, 0, 0, 20)
editorFrame.BackgroundColor3 = T.Card
editorFrame.Parent           = lsPage
corner(editorFrame, 8)
stroke(editorFrame, T.Border, 1)

local scriptBox = Instance.new("TextBox")
scriptBox.Size               = UDim2.new(1, -16, 1, -16)
scriptBox.Position           = UDim2.new(0, 8, 0, 8)
scriptBox.BackgroundTransparency = 1
scriptBox.TextColor3         = Color3.fromRGB(200, 220, 255)
scriptBox.Font               = Enum.Font.Code
scriptBox.TextSize           = 13
scriptBox.Text               = "-- Paste your script here\nprint('Hello from Script Hub!')"
scriptBox.PlaceholderText    = "-- Paste or type Lua code here..."
scriptBox.PlaceholderColor3  = T.SubText
scriptBox.MultiLine          = true
scriptBox.ClearTextOnFocus   = false
scriptBox.TextXAlignment     = Enum.TextXAlignment.Left
scriptBox.TextYAlignment     = Enum.TextYAlignment.Top
scriptBox.TextWrapped        = false
scriptBox.Parent             = editorFrame

-- Scrolling frame overlay for large scripts
local editorScroll = Instance.new("ScrollingFrame")
editorScroll.Size                 = UDim2.new(1, -16, 1, -16)
editorScroll.Position             = UDim2.new(0, 8, 0, 8)
editorScroll.BackgroundTransparency = 1
editorScroll.ScrollBarThickness   = 4
editorScroll.ScrollBarImageColor3 = T.Accent
editorScroll.CanvasSize           = UDim2.new(0, 0, 0, 0)
editorScroll.AutomaticCanvasSize  = Enum.AutomaticSize.Y
editorScroll.Parent               = editorFrame

-- Button row
local lsBtnRow = Instance.new("Frame")
lsBtnRow.Size             = UDim2.new(1, 0, 0, 32)
lsBtnRow.Position         = UDim2.new(0, 0, 1, -34)
lsBtnRow.BackgroundTransparency = 1
lsBtnRow.Parent           = lsPage

local runBtn   = makeButton(lsBtnRow, "▶  Execute",  UDim2.new(0, 120, 0, 30), UDim2.new(0, 0, 0, 0))
local clearBtn = makeButton(lsBtnRow, "Clear",       UDim2.new(0, 80, 0, 30),  UDim2.new(0, 128, 0, 0))
clearBtn.BackgroundColor3 = T.Card
stroke(clearBtn, T.Border, 1)
clearBtn.MouseEnter:Connect(function()  tween(clearBtn, {BackgroundColor3 = T.Border}) end)
clearBtn.MouseLeave:Connect(function() tween(clearBtn, {BackgroundColor3 = T.Card})   end)

-- Copy btn
local copyBtn = makeButton(lsBtnRow, "Copy",         UDim2.new(0, 80, 0, 30),  UDim2.new(0, 216, 0, 0))
copyBtn.BackgroundColor3 = T.Card
stroke(copyBtn, T.Border, 1)
copyBtn.MouseEnter:Connect(function()  tween(copyBtn, {BackgroundColor3 = T.Border}) end)
copyBtn.MouseLeave:Connect(function() tween(copyBtn, {BackgroundColor3 = T.Card})   end)

runBtn.MouseButton1Click:Connect(function()
    local code = scriptBox.Text
    if code == "" then setStatus("Nothing to execute.", false) return end
    local ok, err = pcall(loadstring(code))
    if ok then
        setStatus("Executed successfully.", true)
    else
        setStatus("Error: " .. tostring(err), false)
    end
end)

clearBtn.MouseButton1Click:Connect(function()
    scriptBox.Text = ""
    setStatus("Editor cleared.", true)
end)

copyBtn.MouseButton1Click:Connect(function()
    -- setclipboard available in most exploit environments
    if setclipboard then
        setclipboard(scriptBox.Text)
        setStatus("Copied to clipboard.", true)
    else
        setStatus("setclipboard not available.", false)
    end
end)

-- ──────────────────────────────────────────────────────────────────────────────
-- Tab 2: Module Loader
-- ──────────────────────────────────────────────────────────────────────────────
local modPage = makeTab("Module Loader", "⬡", 2)

label(modPage, "Load by Asset ID  (require via asset ID or ModuleScript path)", UDim2.new(1, 0, 0, 14), UDim2.new(0, 0, 0, 0), 11, T.SubText)

-- Asset ID input
local assetFrame = Instance.new("Frame")
assetFrame.Size             = UDim2.new(1, 0, 0, 38)
assetFrame.Position         = UDim2.new(0, 0, 0, 18)
assetFrame.BackgroundColor3 = T.Card
assetFrame.Parent           = modPage
corner(assetFrame, 8)
stroke(assetFrame, T.Border, 1)

local assetBox = Instance.new("TextBox")
assetBox.Size               = UDim2.new(1, -16, 1, 0)
assetBox.Position           = UDim2.new(0, 8, 0, 0)
assetBox.BackgroundTransparency = 1
assetBox.TextColor3         = T.Text
assetBox.Font               = Enum.Font.Code
assetBox.TextSize            = 14
assetBox.Text               = ""
assetBox.PlaceholderText    = "Asset ID  e.g. 1234567890"
assetBox.PlaceholderColor3  = T.SubText
assetBox.ClearTextOnFocus   = false
assetBox.TextXAlignment     = Enum.TextXAlignment.Left
assetBox.Parent             = assetFrame

-- Path input
label(modPage, "  — or —  ModuleScript path inside game (e.g. game.ReplicatedStorage.MyModule)", UDim2.new(1, 0, 0, 14), UDim2.new(0, 0, 0, 60), 11, T.SubText)

local pathFrame = Instance.new("Frame")
pathFrame.Size             = UDim2.new(1, 0, 0, 38)
pathFrame.Position         = UDim2.new(0, 0, 0, 78)
pathFrame.BackgroundColor3 = T.Card
pathFrame.Parent           = modPage
corner(pathFrame, 8)
stroke(pathFrame, T.Border, 1)

local pathBox = Instance.new("TextBox")
pathBox.Size               = UDim2.new(1, -16, 1, 0)
pathBox.Position           = UDim2.new(0, 8, 0, 0)
pathBox.BackgroundTransparency = 1
pathBox.TextColor3         = T.Text
pathBox.Font               = Enum.Font.Code
pathBox.TextSize            = 14
pathBox.Text               = ""
pathBox.PlaceholderText    = "game.ReplicatedStorage.ModuleName"
pathBox.PlaceholderColor3  = T.SubText
pathBox.ClearTextOnFocus   = false
pathBox.TextXAlignment     = Enum.TextXAlignment.Left
pathBox.Parent             = pathFrame

-- Output box
label(modPage, "Output", UDim2.new(1, 0, 0, 14), UDim2.new(0, 0, 0, 122), 11, T.SubText)

local outFrame = Instance.new("Frame")
outFrame.Size             = UDim2.new(1, 0, 1, -198)
outFrame.Position         = UDim2.new(0, 0, 0, 140)
outFrame.BackgroundColor3 = T.Card
outFrame.Parent           = modPage
corner(outFrame, 8)
stroke(outFrame, T.Border, 1)

local outScroll = Instance.new("ScrollingFrame")
outScroll.Size                 = UDim2.new(1, -12, 1, -10)
outScroll.Position             = UDim2.new(0, 6, 0, 5)
outScroll.BackgroundTransparency = 1
outScroll.ScrollBarThickness   = 4
outScroll.ScrollBarImageColor3 = T.Accent
outScroll.CanvasSize           = UDim2.new(0, 0, 0, 0)
outScroll.AutomaticCanvasSize  = Enum.AutomaticSize.Y
outScroll.Parent               = outFrame

local outLayout = Instance.new("UIListLayout")
outLayout.SortOrder    = Enum.SortOrder.LayoutOrder
outLayout.Padding      = UDim.new(0, 2)
outLayout.Parent       = outScroll

local logIndex = 0
local function logOut(msg, color)
    logIndex += 1
    local line = Instance.new("TextLabel")
    line.Size             = UDim2.new(1, -4, 0, 0)
    line.AutomaticSize    = Enum.AutomaticSize.Y
    line.BackgroundTransparency = 1
    line.TextColor3       = color or T.Text
    line.Font             = Enum.Font.Code
    line.TextSize         = 12
    line.Text             = msg
    line.TextXAlignment   = Enum.TextXAlignment.Left
    line.TextWrapped      = true
    line.LayoutOrder      = logIndex
    line.Parent           = outScroll
    -- auto-scroll
    task.defer(function()
        outScroll.CanvasPosition = Vector2.new(0, math.huge)
    end)
end

-- resolve path string to an instance
local function resolvePath(pathStr)
    local parts = string.split(pathStr, ".")
    local obj = game
    for i = 2, #parts do  -- skip "game"
        obj = obj:FindFirstChild(parts[i])
        if not obj then return nil, "Child '" .. parts[i] .. "' not found" end
    end
    return obj, nil
end

-- Buttons row
local modBtnRow = Instance.new("Frame")
modBtnRow.Size             = UDim2.new(1, 0, 0, 32)
modBtnRow.Position         = UDim2.new(0, 0, 1, -34)
modBtnRow.BackgroundTransparency = 1
modBtnRow.Parent           = modPage

local requireBtn  = makeButton(modBtnRow, "⬡  Require Module", UDim2.new(0, 150, 0, 30), UDim2.new(0, 0, 0, 0))
local clearLogBtn = makeButton(modBtnRow, "Clear Log",          UDim2.new(0, 90, 0, 30),  UDim2.new(0, 158, 0, 0))
clearLogBtn.BackgroundColor3 = T.Card
stroke(clearLogBtn, T.Border, 1)
clearLogBtn.MouseEnter:Connect(function()  tween(clearLogBtn, {BackgroundColor3 = T.Border}) end)
clearLogBtn.MouseLeave:Connect(function() tween(clearLogBtn, {BackgroundColor3 = T.Card})   end)

requireBtn.MouseButton1Click:Connect(function()
    local assetId = assetBox.Text:match("^%s*(.-)%s*$")
    local pathStr = pathBox.Text:match("^%s*(.-)%s*$")

    -- Try asset ID first
    if assetId ~= "" and tonumber(assetId) then
        logOut("→ Requiring asset ID: " .. assetId, T.SubText)
        local ok, result = pcall(function()
            return require(tonumber(assetId))
        end)
        if ok then
            logOut("✓ Success: " .. tostring(result), T.Success)
            setStatus("Module loaded from asset ID.", true)
        else
            logOut("✗ " .. tostring(result), T.Error)
            setStatus("Require failed.", false)
        end
        return
    end

    -- Try path
    if pathStr ~= "" then
        logOut("→ Resolving path: " .. pathStr, T.SubText)
        local obj, err = resolvePath(pathStr)
        if not obj then
            logOut("✗ " .. tostring(err), T.Error)
            setStatus("Path not found.", false)
            return
        end
        if obj.ClassName ~= "ModuleScript" then
            logOut("✗ Instance is " .. obj.ClassName .. ", not a ModuleScript.", T.Error)
            setStatus("Not a ModuleScript.", false)
            return
        end
        local ok, result = pcall(require, obj)
        if ok then
            logOut("✓ Success: " .. tostring(result), T.Success)
            setStatus("Module loaded from path.", true)
        else
            logOut("✗ " .. tostring(result), T.Error)
            setStatus("Require failed.", false)
        end
        return
    end

    setStatus("Enter an Asset ID or path first.", false)
end)

clearLogBtn.MouseButton1Click:Connect(function()
    for _, child in outScroll:GetChildren() do
        if child:IsA("TextLabel") then child:Destroy() end
    end
    logIndex = 0
    setStatus("Log cleared.", true)
end)

-- ──────────────────────────────────────────────────────────────────────────────
-- Activate first tab
-- ──────────────────────────────────────────────────────────────────────────────
tabs[1].btn:MouseButton1Click()   -- fire the click to activate

-- Entrance animation
win.Size                 = UDim2.new(0, 540, 0, 0)
win.BackgroundTransparency = 1
tween(win, {Size = UDim2.new(0, 540, 0, 400), BackgroundTransparency = 0}, 0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
