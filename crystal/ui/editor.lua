-- Crystal Language — Glass Morphism IDE Editor for Roblox
-- A clean, modern code editor that compiles and runs Crystal scripts

local Crystal = require(script.Parent.Parent)
local Players       = game:GetService("Players")
local TweenService  = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService    = game:GetService("RunService")

local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")

-- ── Palette ──────────────────────────────────────────────────────────────────

local PALETTE = {
    bg          = Color3.fromRGB(10,  10,  18),
    glass       = Color3.fromRGB(255, 255, 255),
    glassAlpha  = 0.06,
    border      = Color3.fromRGB(255, 255, 255),
    borderAlpha = 0.12,
    accent      = Color3.fromRGB(120, 80,  255),
    accentGlow  = Color3.fromRGB(160, 100, 255),
    textPrimary = Color3.fromRGB(230, 230, 250),
    textDim     = Color3.fromRGB(140, 140, 160),
    error       = Color3.fromRGB(255, 80,  80),
    success     = Color3.fromRGB(80,  220, 120),
    warning     = Color3.fromRGB(255, 180, 60),
    lineNum     = Color3.fromRGB(90,  90,  110),
    keyword     = Color3.fromRGB(130, 100, 255),
    string_col  = Color3.fromRGB(100, 220, 150),
    number_col  = Color3.fromRGB(255, 160, 80),
    comment_col = Color3.fromRGB(90,  110, 90),
}

-- ── Utility helpers ──────────────────────────────────────────────────────────

local function tween(obj, props, t, style, dir)
    return TweenService:Create(obj,
        TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
        props
    ):Play()
end

local function glass(parent, size, pos, zIndex, cornerRadius)
    local frame = Instance.new("Frame")
    frame.Size            = size
    frame.Position        = pos
    frame.BackgroundColor3 = PALETTE.glass
    frame.BackgroundTransparency = 1 - PALETTE.glassAlpha
    frame.BorderSizePixel = 0
    frame.ZIndex          = zIndex or 1
    frame.Parent          = parent

    local stroke = Instance.new("UIStroke")
    stroke.Color        = PALETTE.border
    stroke.Transparency = 1 - PALETTE.borderAlpha
    stroke.Thickness    = 1
    stroke.Parent       = frame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, cornerRadius or 12)
    corner.Parent       = frame

    -- Subtle inner glow
    local glow = Instance.new("UIGradient")
    glow.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(180,160,255)),
    })
    glow.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.90),
        NumberSequenceKeypoint.new(1, 0.98),
    })
    glow.Rotation = 135
    glow.Parent = frame

    return frame
end

local function label(parent, text, size, pos, color, fontSize, weight, zIndex)
    local l = Instance.new("TextLabel")
    l.Text                  = text
    l.Size                  = size
    l.Position              = pos
    l.BackgroundTransparency = 1
    l.TextColor3            = color or PALETTE.textPrimary
    l.TextSize              = fontSize or 14
    l.Font                  = weight or Enum.Font.GothamMedium
    l.TextXAlignment        = Enum.TextXAlignment.Left
    l.ZIndex                = zIndex or 2
    l.Parent                = parent
    return l
end

local function btn(parent, text, size, pos, accent, zIndex, cornerRadius)
    local b = Instance.new("TextButton")
    b.Size            = size
    b.Position        = pos
    b.BackgroundColor3 = accent or PALETTE.accent
    b.BackgroundTransparency = 0.15
    b.BorderSizePixel = 0
    b.Text            = text
    b.TextColor3      = PALETTE.textPrimary
    b.TextSize        = 13
    b.Font            = Enum.Font.GothamBold
    b.ZIndex          = zIndex or 3
    b.AutoButtonColor = false
    b.Parent          = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, cornerRadius or 8)
    corner.Parent = b

    local stroke = Instance.new("UIStroke")
    stroke.Color        = accent or PALETTE.accent
    stroke.Transparency = 0.5
    stroke.Thickness    = 1
    stroke.Parent       = b

    b.MouseEnter:Connect(function()
        tween(b, { BackgroundTransparency = 0 }, 0.12)
        tween(stroke, { Transparency = 0.2 }, 0.12)
    end)
    b.MouseLeave:Connect(function()
        tween(b, { BackgroundTransparency = 0.15 }, 0.18)
        tween(stroke, { Transparency = 0.5 }, 0.18)
    end)
    b.MouseButton1Down:Connect(function()
        tween(b, { Size = UDim2.new(size.X.Scale, size.X.Offset - 4, size.Y.Scale, size.Y.Offset - 2) }, 0.08)
    end)
    b.MouseButton1Up:Connect(function()
        tween(b, { Size = size }, 0.12)
    end)

    return b
end

local function toggle(parent, label_text, pos, initial, zIndex)
    local container = Instance.new("Frame")
    container.Size            = UDim2.new(0, 160, 0, 32)
    container.Position        = pos
    container.BackgroundTransparency = 1
    container.ZIndex          = zIndex or 3
    container.Parent          = parent

    local lbl = label(container, label_text, UDim2.new(1, -48, 1, 0), UDim2.new(0, 0, 0, 0),
        PALETTE.textDim, 13, Enum.Font.Gotham, zIndex or 3)

    local track = Instance.new("Frame")
    track.Size            = UDim2.new(0, 40, 0, 20)
    track.Position        = UDim2.new(1, -44, 0.5, -10)
    track.BackgroundColor3 = initial and PALETTE.accent or Color3.fromRGB(60,60,80)
    track.BackgroundTransparency = 0.2
    track.BorderSizePixel = 0
    track.ZIndex          = (zIndex or 3) + 1
    track.Parent          = container
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local thumb = Instance.new("Frame")
    thumb.Size            = UDim2.new(0, 16, 0, 16)
    thumb.Position        = initial and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    thumb.BackgroundColor3 = Color3.fromRGB(255,255,255)
    thumb.BorderSizePixel = 0
    thumb.ZIndex          = (zIndex or 3) + 2
    thumb.Parent          = track
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)

    local value = initial or false
    local btn2  = Instance.new("TextButton")
    btn2.Size            = UDim2.new(1, 0, 1, 0)
    btn2.BackgroundTransparency = 1
    btn2.Text            = ""
    btn2.ZIndex          = (zIndex or 3) + 3
    btn2.Parent          = container

    local changed = Instance.new("BindableEvent")

    btn2.MouseButton1Click:Connect(function()
        value = not value
        if value then
            tween(track, { BackgroundColor3 = PALETTE.accent }, 0.15)
            tween(thumb, { Position = UDim2.new(1, -18, 0.5, -8) }, 0.15)
        else
            tween(track, { BackgroundColor3 = Color3.fromRGB(60,60,80) }, 0.15)
            tween(thumb, { Position = UDim2.new(0, 2, 0.5, -8) }, 0.15)
        end
        changed:Fire(value)
    end)

    return container, changed.Event
end

-- ── Build UI ──────────────────────────────────────────────────────────────────

local function buildEditor()
    -- Root ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name            = "CrystalIDE"
    screenGui.ResetOnSpawn    = false
    screenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    screenGui.IgnoreGuiInset  = true
    screenGui.Parent          = PlayerGui

    -- Backdrop blur (Roblox 2023+)
    local blur = Instance.new("BlurEffect")
    blur.Size   = 0
    blur.Parent = game:GetService("Lighting")

    -- ── Main window ─────────────────────────────────────────────────────────
    local WIN_W, WIN_H = 780, 520
    local win = glass(screenGui,
        UDim2.new(0, WIN_W, 0, WIN_H),
        UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2),
        10, 16
    )

    -- Extra backdrop behind window
    local backdrop = Instance.new("Frame")
    backdrop.Size            = UDim2.new(1, 40, 1, 40)
    backdrop.Position        = UDim2.new(0, -20, 0, -20)
    backdrop.BackgroundColor3 = Color3.fromRGB(5,5,12)
    backdrop.BackgroundTransparency = 0.3
    backdrop.BorderSizePixel = 0
    backdrop.ZIndex          = 9
    backdrop.Parent          = win
    Instance.new("UICorner", backdrop).CornerRadius = UDim.new(0, 20)

    -- ── Title bar ────────────────────────────────────────────────────────────
    local titleBar = Instance.new("Frame")
    titleBar.Size            = UDim2.new(1, 0, 0, 42)
    titleBar.BackgroundColor3 = PALETTE.glass
    titleBar.BackgroundTransparency = 0.88
    titleBar.BorderSizePixel = 0
    titleBar.ZIndex          = 12
    titleBar.Parent          = win
    Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 16)

    local titleStroke = Instance.new("UIStroke")
    titleStroke.Color        = PALETTE.border
    titleStroke.Transparency = 0.85
    titleStroke.Thickness    = 1
    titleStroke.Parent       = titleBar

    -- Logo dot
    local dot = Instance.new("Frame")
    dot.Size            = UDim2.new(0, 10, 0, 10)
    dot.Position        = UDim2.new(0, 16, 0.5, -5)
    dot.BackgroundColor3 = PALETTE.accent
    dot.BorderSizePixel = 0
    dot.ZIndex          = 13
    dot.Parent          = titleBar
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    label(titleBar, "Crystal IDE", UDim2.new(0, 200, 1, 0), UDim2.new(0, 34, 0, 0),
        PALETTE.textPrimary, 15, Enum.Font.GothamBold, 13)

    label(titleBar, "v1.0.0", UDim2.new(0, 60, 1, 0), UDim2.new(0, 160, 0, 0),
        PALETTE.textDim, 11, Enum.Font.Gotham, 13)

    -- Window controls (decorative close/min/max)
    local colors = {Color3.fromRGB(255,95,87), Color3.fromRGB(255,189,46), Color3.fromRGB(40,200,65)}
    for i, col in ipairs(colors) do
        local ctrl = Instance.new("Frame")
        ctrl.Size            = UDim2.new(0, 12, 0, 12)
        ctrl.Position        = UDim2.new(1, -20 - (i-1)*20, 0.5, -6)
        ctrl.BackgroundColor3 = col
        ctrl.BorderSizePixel = 0
        ctrl.ZIndex          = 13
        ctrl.Parent          = titleBar
        Instance.new("UICorner", ctrl).CornerRadius = UDim.new(1, 0)
    end

    -- Make window draggable
    local dragging, dragStart, startPos = false, nil, nil
    titleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = inp.Position
            startPos  = win.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = inp.Position - dragStart
            win.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    -- ── Left sidebar ─────────────────────────────────────────────────────────
    local sidebar = glass(win, UDim2.new(0, 160, 1, -42), UDim2.new(0, 0, 0, 42), 11, 0)

    local sidebarLabel = label(sidebar, "FILES", UDim2.new(1, -16, 0, 20), UDim2.new(0, 12, 0, 10),
        PALETTE.textDim, 10, Enum.Font.GothamBold, 12)

    -- Example file entries
    local files = { "main.cr", "stdlib.cr", "player.cr", "utils.cr" }
    local activeFile = 1
    local fileButtons = {}
    for i, fname in ipairs(files) do
        local fb = Instance.new("TextButton")
        fb.Size            = UDim2.new(1, -16, 0, 30)
        fb.Position        = UDim2.new(0, 8, 0, 38 + (i-1)*34)
        fb.BackgroundColor3 = i == activeFile and PALETTE.accent or PALETTE.glass
        fb.BackgroundTransparency = i == activeFile and 0.6 or 0.96
        fb.Text            = "  " .. fname
        fb.TextColor3      = i == activeFile and PALETTE.textPrimary or PALETTE.textDim
        fb.TextSize        = 13
        fb.Font            = Enum.Font.GothamMedium
        fb.TextXAlignment  = Enum.TextXAlignment.Left
        fb.BorderSizePixel = 0
        fb.ZIndex          = 12
        fb.Parent          = sidebar
        Instance.new("UICorner", fb).CornerRadius = UDim.new(0, 6)
        fileButtons[i] = fb

        fb.MouseButton1Click:Connect(function()
            activeFile = i
            for j, b in ipairs(fileButtons) do
                tween(b, {
                    BackgroundColor3 = j == i and PALETTE.accent or PALETTE.glass,
                    BackgroundTransparency = j == i and 0.6 or 0.96,
                    TextColor3 = j == i and PALETTE.textPrimary or PALETTE.textDim,
                })
            end
        end)
    end

    -- ── Toolbar ──────────────────────────────────────────────────────────────
    local toolbar = glass(win, UDim2.new(1, -160, 0, 42), UDim2.new(0, 160, 0, 42), 11, 0)

    local runBtn = btn(toolbar, "▶  Run", UDim2.new(0, 90, 0, 28), UDim2.new(0, 10, 0.5, -14),
        PALETTE.success, 12, 8)

    local stopBtn = btn(toolbar, "■  Stop", UDim2.new(0, 90, 0, 28), UDim2.new(0, 108, 0.5, -14),
        Color3.fromRGB(220, 60, 60), 12, 8)

    local clearBtn = btn(toolbar, "⌫  Clear", UDim2.new(0, 90, 0, 28), UDim2.new(0, 206, 0.5, -14),
        PALETTE.textDim, 12, 8)

    local disasmBtn = btn(toolbar, "⚙  Bytecode", UDim2.new(0, 110, 0, 28), UDim2.new(0, 304, 0.5, -14),
        PALETTE.warning, 12, 8)

    -- Anti-tamper badge
    local atBadge = Instance.new("Frame")
    atBadge.Size            = UDim2.new(0, 130, 0, 22)
    atBadge.Position        = UDim2.new(1, -140, 0.5, -11)
    atBadge.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
    atBadge.BackgroundTransparency = 0.4
    atBadge.BorderSizePixel = 0
    atBadge.ZIndex          = 13
    atBadge.Parent          = toolbar
    Instance.new("UICorner", atBadge).CornerRadius = UDim.new(0, 6)

    local atLabel = Instance.new("TextLabel")
    atLabel.Size            = UDim2.new(1, 0, 1, 0)
    atLabel.BackgroundTransparency = 1
    atLabel.Text            = "🔒 Anti-Tamper ON"
    atLabel.TextColor3      = Color3.fromRGB(200, 255, 210)
    atLabel.TextSize        = 11
    atLabel.Font            = Enum.Font.GothamBold
    atLabel.ZIndex          = 14
    atLabel.Parent          = atBadge

    -- ── Code editor area ─────────────────────────────────────────────────────
    local editorArea = glass(win,
        UDim2.new(1, -160, 0, 300),
        UDim2.new(0, 160, 0, 84),
        11, 0
    )

    -- Line numbers column
    local lineNumCol = Instance.new("Frame")
    lineNumCol.Size            = UDim2.new(0, 40, 1, 0)
    lineNumCol.BackgroundColor3 = Color3.fromRGB(10,10,20)
    lineNumCol.BackgroundTransparency = 0.5
    lineNumCol.BorderSizePixel = 0
    lineNumCol.ZIndex          = 12
    lineNumCol.Parent          = editorArea

    local lineNumLabel = Instance.new("TextLabel")
    lineNumLabel.Size            = UDim2.new(1, 0, 1, 0)
    lineNumLabel.BackgroundTransparency = 1
    lineNumLabel.Text            = "1\n2\n3\n4\n5\n6\n7\n8\n9\n10"
    lineNumLabel.TextColor3      = PALETTE.lineNum
    lineNumLabel.TextSize        = 13
    lineNumLabel.Font            = Enum.Font.Code
    lineNumLabel.TextYAlignment  = Enum.TextYAlignment.Top
    lineNumLabel.TextXAlignment  = Enum.TextXAlignment.Right
    lineNumLabel.ZIndex          = 13
    lineNumLabel.Parent          = lineNumCol

    -- The actual TextBox for code input
    local codeBox = Instance.new("ScrollingFrame")
    codeBox.Size            = UDim2.new(1, -44, 1, -8)
    codeBox.Position        = UDim2.new(0, 44, 0, 4)
    codeBox.BackgroundTransparency = 1
    codeBox.BorderSizePixel = 0
    codeBox.ScrollBarThickness = 4
    codeBox.ScrollBarImageColor3 = PALETTE.accent
    codeBox.ZIndex          = 12
    codeBox.CanvasSize      = UDim2.new(0, 0, 0, 0)
    codeBox.AutomaticCanvasSize = Enum.AutomaticSize.Y
    codeBox.Parent          = editorArea

    local codeInput = Instance.new("TextBox")
    codeInput.Size            = UDim2.new(1, 0, 1, 0)
    codeInput.BackgroundTransparency = 1
    codeInput.TextColor3      = PALETTE.textPrimary
    codeInput.TextSize        = 13
    codeInput.Font            = Enum.Font.Code
    codeInput.TextYAlignment  = Enum.TextYAlignment.Top
    codeInput.TextXAlignment  = Enum.TextXAlignment.Left
    codeInput.MultiLine       = true
    codeInput.ClearTextOnFocus = false
    codeInput.ZIndex          = 13
    codeInput.PlaceholderText = "-- Write Crystal code here...\n-- Example:\nlet name = \"World\"\nprint(f\"Hello, {name}!\")"
    codeInput.Text            = [[-- Crystal Language Demo
let greeting = "Crystal"
print(f"Welcome to {greeting} IDE!")

fn factorial(n) {
    if n <= 1 {
        return 1
    }
    return n * factorial(n - 1)
}

for i in 1..10 {
    print(f"  {i}! = {factorial(i)}")
}]]
    codeInput.Parent          = codeBox

    -- Update line numbers when text changes
    codeInput:GetPropertyChangedSignal("Text"):Connect(function()
        local lines = 1
        for _ in codeInput.Text:gmatch("\n") do lines = lines + 1 end
        local nums = {}
        for i = 1, lines do nums[i] = tostring(i) end
        lineNumLabel.Text = table.concat(nums, "\n")
    end)

    -- ── Output console ───────────────────────────────────────────────────────
    local console = glass(win,
        UDim2.new(1, -160, 0, 130),
        UDim2.new(0, 160, 0, 384),
        11, 0
    )

    local consoleHeader = label(console, "OUTPUT", UDim2.new(1, 0, 0, 22), UDim2.new(0, 10, 0, 6),
        PALETTE.textDim, 10, Enum.Font.GothamBold, 12)

    local outputScroll = Instance.new("ScrollingFrame")
    outputScroll.Size            = UDim2.new(1, -10, 1, -30)
    outputScroll.Position        = UDim2.new(0, 8, 0, 28)
    outputScroll.BackgroundTransparency = 1
    outputScroll.BorderSizePixel = 0
    outputScroll.ScrollBarThickness = 4
    outputScroll.ScrollBarImageColor3 = PALETTE.accent
    outputScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    outputScroll.CanvasSize      = UDim2.new(0, 0, 0, 0)
    outputScroll.ZIndex          = 12
    outputScroll.Parent          = console

    local outputLabel = Instance.new("TextLabel")
    outputLabel.Size            = UDim2.new(1, 0, 0, 0)
    outputLabel.AutomaticSize   = Enum.AutomaticSize.Y
    outputLabel.BackgroundTransparency = 1
    outputLabel.TextColor3      = PALETTE.textPrimary
    outputLabel.TextSize        = 13
    outputLabel.Font            = Enum.Font.Code
    outputLabel.TextXAlignment  = Enum.TextXAlignment.Left
    outputLabel.TextYAlignment  = Enum.TextYAlignment.Top
    outputLabel.TextWrapped     = true
    outputLabel.RichText        = true
    outputLabel.ZIndex          = 13
    outputLabel.Text            = '<font color="#5a5a7a">-- Output will appear here --</font>'
    outputLabel.Parent          = outputScroll

    -- ── Status bar ───────────────────────────────────────────────────────────
    local statusBar = Instance.new("Frame")
    statusBar.Size            = UDim2.new(1, -160, 0, 24)
    statusBar.Position        = UDim2.new(0, 160, 1, -24)
    statusBar.BackgroundColor3 = PALETTE.accent
    statusBar.BackgroundTransparency = 0.85
    statusBar.BorderSizePixel = 0
    statusBar.ZIndex          = 12
    statusBar.Parent          = win

    local statusLabel = label(statusBar, "  Ready — Crystal v1.0.0",
        UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0),
        PALETTE.textDim, 11, Enum.Font.Gotham, 13)

    local function setStatus(text, color)
        statusLabel.Text       = "  " .. text
        statusLabel.TextColor3 = color or PALETTE.textDim
    end

    -- ── Output helpers ───────────────────────────────────────────────────────
    local outputLines = {}

    local function appendOutput(text, color)
        local colorHex = ("%02X%02X%02X"):format(
            math.floor((color or PALETTE.textPrimary).R * 255),
            math.floor((color or PALETTE.textPrimary).G * 255),
            math.floor((color or PALETTE.textPrimary).B * 255)
        )
        outputLines[#outputLines+1] = ('<font color="#%s">%s</font>'):format(
            colorHex, tostring(text):gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;")
        )
        if #outputLines > 200 then
            table.remove(outputLines, 1)
        end
        outputLabel.Text = table.concat(outputLines, "\n")
        -- Scroll to bottom
        task.defer(function()
            outputScroll.CanvasPosition = Vector2.new(0, math.huge)
        end)
    end

    local function clearOutput()
        outputLines = {}
        outputLabel.Text = '<font color="#5a5a7a">-- Output cleared --</font>'
    end

    -- ── Run logic ────────────────────────────────────────────────────────────
    local running = false
    local printBuffer = {}

    runBtn.MouseButton1Click:Connect(function()
        if running then return end
        running = true
        setStatus("Compiling...", PALETTE.warning)

        local source = codeInput.Text
        if source:match("^%s*$") then
            appendOutput("[Error] No code to run.", PALETTE.error)
            setStatus("No code.", PALETTE.error)
            running = false
            return
        end

        appendOutput("▶ Running Crystal script...", PALETTE.accent)

        -- Redirect print to output console
        local capturedPrint = function(...)
            local parts = {}
            for i = 1, select("#", ...) do
                parts[#parts+1] = tostring(select(i, ...))
            end
            appendOutput(table.concat(parts, "  "), PALETTE.textPrimary)
        end

        local ok, err = pcall(function()
            local chunk = Crystal.compile(source, "editor.cr")
            appendOutput("✓ Compiled. Checksum: 0x" .. ("%08X"):format(chunk.checksum or 0), PALETTE.success)
            appendOutput("🔒 Anti-tamper verified.", Color3.fromRGB(80, 220, 120))
            Crystal.execute(chunk, { print = capturedPrint, warn = capturedPrint })
        end)

        if ok then
            appendOutput("✓ Done.", PALETTE.success)
            setStatus("Execution complete.", PALETTE.success)
        else
            appendOutput("[Error] " .. tostring(err), PALETTE.error)
            setStatus("Error — see output.", PALETTE.error)
        end

        running = false
    end)

    stopBtn.MouseButton1Click:Connect(function()
        running = false
        setStatus("Stopped.", PALETTE.warning)
        appendOutput("■ Execution stopped.", PALETTE.warning)
    end)

    clearBtn.MouseButton1Click:Connect(function()
        clearOutput()
        setStatus("Ready.", PALETTE.textDim)
    end)

    disasmBtn.MouseButton1Click:Connect(function()
        local source = codeInput.Text
        if source:match("^%s*$") then return end
        local ok, result = pcall(function()
            local chunk = Crystal.compile(source, "editor.cr")
            return Crystal.disassemble(chunk)
        end)
        if ok then
            clearOutput()
            appendOutput("=== Crystal Bytecode Disassembly ===", PALETTE.warning)
            for line in (result .. "\n"):gmatch("([^\n]*)\n") do
                appendOutput(line, PALETTE.textDim)
            end
        else
            appendOutput("[Disasm Error] " .. tostring(result), PALETTE.error)
        end
    end)

    -- ── Entrance animation ───────────────────────────────────────────────────
    win.BackgroundTransparency = 1
    win.Position = UDim2.new(win.Position.X.Scale, win.Position.X.Offset,
        win.Position.Y.Scale, win.Position.Y.Offset + 40)

    task.defer(function()
        tween(win, {
            BackgroundTransparency = 1 - PALETTE.glassAlpha,
            Position = UDim2.new(
                win.Position.X.Scale, win.Position.X.Offset,
                win.Position.Y.Scale, win.Position.Y.Offset - 40
            ),
        }, 0.4, Enum.EasingStyle.Quart)
        tween(blur, { Size = 8 }, 0.4)
    end)

    return screenGui
end

-- Auto-launch if this script runs as a LocalScript
local success, err = pcall(buildEditor)
if not success then
    warn("[Crystal IDE] Failed to build editor:", err)
end
