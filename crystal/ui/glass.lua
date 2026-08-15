-- Crystal Glass UI Framework
-- Built-in UI system for Crystal programs.
-- Crystal scripts call these functions to create beautiful glass-morphism UI automatically.
-- Usage from Crystal: UI.Window(...), UI.Button(...), UI.Switch(...), UI.Input(...), etc.

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- ── Design tokens ─────────────────────────────────────────────────────────────

local T = {
    -- Backgrounds
    bg       = Color3.fromRGB(8,   8,  16),
    surface  = Color3.fromRGB(18,  18,  30),
    glass    = Color3.fromRGB(255, 255, 255),
    -- Accents
    accent   = Color3.fromRGB(108,  80, 255),
    accentHi = Color3.fromRGB(140, 110, 255),
    green    = Color3.fromRGB(60,  210, 120),
    red      = Color3.fromRGB(255,  70,  70),
    yellow   = Color3.fromRGB(255, 190,  50),
    -- Text
    text     = Color3.fromRGB(235, 235, 250),
    textMid  = Color3.fromRGB(160, 160, 185),
    textDim  = Color3.fromRGB(90,   90, 115),
    -- Border
    border   = Color3.fromRGB(255, 255, 255),
    -- Radii
    radiusLg = 16,
    radiusMd = 10,
    radiusSm = 6,
    -- Transparency levels
    glassBg  = 0.88,   -- frame background (lower = more opaque)
    glassBd  = 0.82,   -- border
    -- Font
    fontBold = Enum.Font.GothamBold,
    fontMed  = Enum.Font.GothamMedium,
    fontReg  = Enum.Font.Gotham,
    fontMono = Enum.Font.Code,
}

-- ── Tween shorthand ───────────────────────────────────────────────────────────

local function tw(obj, props, t, style, dir)
    TweenService:Create(obj,
        TweenInfo.new(t or 0.16, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
        props
    ):Play()
end

-- ── Low-level primitives ──────────────────────────────────────────────────────

local function applyCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or T.radiusMd)
    c.Parent = parent
    return c
end

local function applyStroke(parent, color, alpha, thickness)
    local s = Instance.new("UIStroke")
    s.Color        = color or T.border
    s.Transparency = alpha or T.glassBd
    s.Thickness    = thickness or 1
    s.Parent       = parent
    return s
end

local function applyGradient(parent, rot, colorSeq, alphaSeq)
    local g = Instance.new("UIGradient")
    g.Rotation    = rot or 135
    g.Color       = colorSeq or ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(160,140,255)),
    })
    g.Transparency = alphaSeq or NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.88),
        NumberSequenceKeypoint.new(1, 0.96),
    })
    g.Parent = parent
    return g
end

local function makePad(parent, x, y)
    local p = Instance.new("UIPadding")
    p.PaddingLeft   = UDim.new(0, x or 10)
    p.PaddingRight  = UDim.new(0, x or 10)
    p.PaddingTop    = UDim.new(0, y or 6)
    p.PaddingBottom = UDim.new(0, y or 6)
    p.Parent        = parent
    return p
end

local function makeList(parent, dir, pad, align)
    local l = Instance.new("UIListLayout")
    l.FillDirection  = dir  or Enum.FillDirection.Vertical
    l.Padding        = UDim.new(0, pad or 8)
    l.HorizontalAlignment = align or Enum.HorizontalAlignment.Left
    l.SortOrder      = Enum.SortOrder.LayoutOrder
    l.Parent         = parent
    return l
end

-- glass frame base
local function glassFrame(parent, size, pos, z, radius)
    local f = Instance.new("Frame")
    f.Size                   = size
    f.Position               = pos or UDim2.new(0,0,0,0)
    f.BackgroundColor3       = T.glass
    f.BackgroundTransparency = T.glassBg
    f.BorderSizePixel        = 0
    f.ZIndex                 = z or 2
    f.Parent                 = parent
    applyCorner(f, radius or T.radiusMd)
    applyStroke(f)
    applyGradient(f)
    return f
end

-- ── Root ScreenGui ────────────────────────────────────────────────────────────

local function getRoot(name)
    local existing = PlayerGui:FindFirstChild(name)
    if existing then return existing end
    local sg = Instance.new("ScreenGui")
    sg.Name           = name or "CrystalUI"
    sg.ResetOnSpawn   = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.IgnoreGuiInset = true
    sg.Parent         = PlayerGui
    return sg
end

-- ── UI module (returned as Crystal globals) ───────────────────────────────────

local Glass = {}

-- ── Window ────────────────────────────────────────────────────────────────────
--   UI.Window(title, width, height) -> window object
--   window:add(element)
--   window:show() / window:hide() / window:destroy()

function Glass.Window(title, width, height)
    width  = width  or 460
    height = height or 380

    local root = getRoot("CrystalUI_" .. (title or "Window"))

    -- Dim backdrop
    local dim = Instance.new("Frame")
    dim.Size                   = UDim2.new(1, 0, 1, 0)
    dim.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
    dim.BackgroundTransparency = 0.55
    dim.BorderSizePixel        = 0
    dim.ZIndex                 = 10
    dim.Parent                 = root

    -- Main window glass frame
    local win = glassFrame(root,
        UDim2.new(0, width, 0, height),
        UDim2.new(0.5, -width/2, 0.5, -height/2 - 20),
        11, T.radiusLg
    )
    win.BackgroundTransparency = 1
    win.Position = UDim2.new(0.5, -width/2, 0.5, -height/2 + 30)

    -- Entrance animation
    task.defer(function()
        tw(win, {
            BackgroundTransparency = T.glassBg,
            Position = UDim2.new(0.5, -width/2, 0.5, -height/2),
        }, 0.35, Enum.EasingStyle.Quart)
    end)

    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Size                   = UDim2.new(1, 0, 0, 46)
    titleBar.BackgroundColor3       = T.glass
    titleBar.BackgroundTransparency = 0.92
    titleBar.BorderSizePixel        = 0
    titleBar.ZIndex                 = 12
    titleBar.Parent                 = win
    applyCorner(titleBar, T.radiusLg)
    applyStroke(titleBar, T.border, 0.88)

    -- Accent dot
    local dot = Instance.new("Frame")
    dot.Size            = UDim2.new(0, 9, 0, 9)
    dot.Position        = UDim2.new(0, 14, 0.5, -4)
    dot.BackgroundColor3 = T.accent
    dot.BorderSizePixel = 0
    dot.ZIndex          = 13
    dot.Parent          = titleBar
    applyCorner(dot, 9)

    -- Title label
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size                   = UDim2.new(1, -90, 1, 0)
    titleLbl.Position               = UDim2.new(0, 30, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text                   = title or "Crystal Window"
    titleLbl.TextColor3             = T.text
    titleLbl.TextSize               = 14
    titleLbl.Font                   = T.fontBold
    titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
    titleLbl.ZIndex                 = 13
    titleLbl.Parent                 = titleBar

    -- Traffic-light controls (decorative)
    local ctrlColors = { Color3.fromRGB(255,95,87), Color3.fromRGB(255,190,47), Color3.fromRGB(40,205,65) }
    for i, col in ipairs(ctrlColors) do
        local c = Instance.new("Frame")
        c.Size            = UDim2.new(0, 11, 0, 11)
        c.Position        = UDim2.new(1, -16 - (i-1)*18, 0.5, -5)
        c.BackgroundColor3 = col
        c.BorderSizePixel = 0
        c.ZIndex          = 13
        c.Parent          = titleBar
        applyCorner(c, 11)
    end

    -- Close (X) is the red dot
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size                   = UDim2.new(0, 11, 0, 11)
    closeBtn.Position               = UDim2.new(1, -16 - 36, 0.5, -5)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text                   = ""
    closeBtn.ZIndex                 = 14
    closeBtn.Parent                 = titleBar

    -- Scroll content area
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size                   = UDim2.new(1, -16, 1, -54)
    scroll.Position               = UDim2.new(0, 8, 0, 50)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel        = 0
    scroll.ScrollBarThickness     = 3
    scroll.ScrollBarImageColor3   = T.accent
    scroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    scroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
    scroll.ZIndex                 = 12
    scroll.Parent                 = win

    local contentList = makeList(scroll, Enum.FillDirection.Vertical, 8)
    makePad(scroll, 4, 6)

    -- Draggable
    local dragging, dragStart, startPos = false
    titleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = inp.Position; startPos = win.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local d = inp.Position - dragStart
            win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                     startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    local self = {
        _frame  = win,
        _scroll = scroll,
        _root   = root,
        _dim    = dim,
        visible = true,
    }

    closeBtn.MouseButton1Click:Connect(function() self:destroy() end)

    function self:add(element)
        if element and element._frame then
            element._frame.Parent = scroll
        end
        return self
    end

    function self:show()
        self.visible = true
        tw(win, { BackgroundTransparency = T.glassBg }, 0.2)
        dim.Visible = true
    end

    function self:hide()
        self.visible = false
        tw(win, { BackgroundTransparency = 1 }, 0.2)
        dim.Visible = false
    end

    function self:setTitle(t)
        titleLbl.Text = t
    end

    function self:destroy()
        tw(win, { BackgroundTransparency = 1, Position = UDim2.new(
            win.Position.X.Scale, win.Position.X.Offset,
            win.Position.Y.Scale, win.Position.Y.Offset + 20
        ) }, 0.25)
        task.delay(0.28, function() root:Destroy() end)
    end

    return self
end

-- ── Button ────────────────────────────────────────────────────────────────────
--   UI.Button(text, color?)  -> { _frame, onClick(fn) }
--   color: "accent" | "green" | "red" | "yellow" | "ghost"

function Glass.Button(text, color)
    local bgColor = T.accent
    if     color == "green"  then bgColor = T.green
    elseif color == "red"    then bgColor = T.red
    elseif color == "yellow" then bgColor = T.yellow
    elseif color == "ghost"  then bgColor = T.glass end

    local frame = Instance.new("Frame")
    frame.Size                   = UDim2.new(1, 0, 0, 42)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel        = 0
    frame.ZIndex                 = 12

    local btn = Instance.new("TextButton")
    btn.Size                   = UDim2.new(1, 0, 1, 0)
    btn.BackgroundColor3       = bgColor
    btn.BackgroundTransparency = color == "ghost" and 0.88 or 0.18
    btn.BorderSizePixel        = 0
    btn.Text                   = text or "Button"
    btn.TextColor3             = T.text
    btn.TextSize               = 14
    btn.Font                   = T.fontBold
    btn.AutoButtonColor        = false
    btn.ZIndex                 = 13
    btn.Parent                 = frame
    applyCorner(btn, T.radiusMd)
    applyStroke(btn, bgColor, color == "ghost" and 0.7 or 0.55, 1)

    btn.MouseEnter:Connect(function()
        tw(btn, { BackgroundTransparency = color == "ghost" and 0.75 or 0 }, 0.12)
    end)
    btn.MouseLeave:Connect(function()
        tw(btn, { BackgroundTransparency = color == "ghost" and 0.88 or 0.18 }, 0.18)
    end)
    btn.MouseButton1Down:Connect(function()
        tw(btn, { Size = UDim2.new(0.97, 0, 0.92, 0), Position = UDim2.new(0.015, 0, 0.04, 0) }, 0.08)
    end)
    btn.MouseButton1Up:Connect(function()
        tw(btn, { Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0) }, 0.12)
    end)

    local self = { _frame = frame, _btn = btn }

    function self:onClick(fn)
        btn.MouseButton1Click:Connect(fn)
        return self
    end

    function self:setText(t)
        btn.Text = t
    end

    function self:setEnabled(v)
        btn.Active              = v
        btn.BackgroundTransparency = v and 0.18 or 0.7
        btn.TextTransparency    = v and 0 or 0.5
    end

    return self
end

-- ── Switch / Toggle ───────────────────────────────────────────────────────────
--   UI.Switch(label, default?)  -> { _frame, onChange(fn), getValue(), setValue(v) }

function Glass.Switch(labelText, default)
    local value = default == true

    local frame = Instance.new("Frame")
    frame.Size                   = UDim2.new(1, 0, 0, 40)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel        = 0
    frame.ZIndex                 = 12

    local lbl = Instance.new("TextLabel")
    lbl.Size                   = UDim2.new(1, -60, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text                   = labelText or "Toggle"
    lbl.TextColor3             = T.text
    lbl.TextSize               = 14
    lbl.Font                   = T.fontMed
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.ZIndex                 = 13
    lbl.Parent                 = frame

    local track = Instance.new("Frame")
    track.Size            = UDim2.new(0, 46, 0, 24)
    track.Position        = UDim2.new(1, -50, 0.5, -12)
    track.BackgroundColor3 = value and T.accent or T.surface
    track.BackgroundTransparency = value and 0.1 or 0.3
    track.BorderSizePixel = 0
    track.ZIndex          = 13
    track.Parent          = frame
    applyCorner(track, 24)
    applyStroke(track, value and T.accent or T.border, value and 0.5 or 0.75)

    local thumb = Instance.new("Frame")
    thumb.Size            = UDim2.new(0, 18, 0, 18)
    thumb.Position        = value and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
    thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    thumb.BorderSizePixel = 0
    thumb.ZIndex          = 14
    thumb.Parent          = track
    applyCorner(thumb, 18)

    -- Shadow under thumb
    local thumbShadow = Instance.new("UIStroke")
    thumbShadow.Color       = Color3.fromRGB(0,0,0)
    thumbShadow.Transparency = 0.7
    thumbShadow.Thickness   = 2
    thumbShadow.Parent      = thumb

    local hitbox = Instance.new("TextButton")
    hitbox.Size                   = UDim2.new(1, 0, 1, 0)
    hitbox.BackgroundTransparency = 1
    hitbox.Text                   = ""
    hitbox.ZIndex                 = 15
    hitbox.Parent                 = frame

    local handlers = {}

    local function setVal(v, silent)
        value = v
        if v then
            tw(track, { BackgroundColor3 = T.accent, BackgroundTransparency = 0.1 })
            tw(thumb, { Position = UDim2.new(1, -21, 0.5, -9) })
        else
            tw(track, { BackgroundColor3 = T.surface, BackgroundTransparency = 0.3 })
            tw(thumb, { Position = UDim2.new(0, 3, 0.5, -9) })
        end
        if not silent then
            for _, fn in ipairs(handlers) do fn(v) end
        end
    end

    hitbox.MouseButton1Click:Connect(function() setVal(not value) end)

    local self = { _frame = frame }

    function self:onChange(fn)
        handlers[#handlers+1] = fn
        return self
    end

    function self:getValue() return value end

    function self:setValue(v) setVal(v, false) end

    return self
end

-- ── Input / TextBox ───────────────────────────────────────────────────────────
--   UI.Input(placeholder, password?)  -> { _frame, getValue(), setValue(v), onChange(fn) }

function Glass.Input(placeholder, password)
    local frame = Instance.new("Frame")
    frame.Size                   = UDim2.new(1, 0, 0, 44)
    frame.BackgroundColor3       = T.glass
    frame.BackgroundTransparency = 0.92
    frame.BorderSizePixel        = 0
    frame.ZIndex                 = 12
    applyCorner(frame, T.radiusMd)
    local stroke = applyStroke(frame, T.border, 0.78)

    local box = Instance.new("TextBox")
    box.Size                   = UDim2.new(1, -20, 1, -12)
    box.Position               = UDim2.new(0, 10, 0, 6)
    box.BackgroundTransparency = 1
    box.Text                   = ""
    box.PlaceholderText        = placeholder or "Type here..."
    box.PlaceholderColor3      = T.textDim
    box.TextColor3             = T.text
    box.TextSize               = 14
    box.Font                   = T.fontMed
    box.TextXAlignment         = Enum.TextXAlignment.Left
    box.ClearTextOnFocus       = false
    box.ZIndex                 = 13
    box.Parent                 = frame

    if password then
        -- mask input characters
        local real = ""
        box:GetPropertyChangedSignal("Text"):Connect(function()
            if #box.Text > #real then
                real = real .. box.Text:sub(#real + 1)
            else
                real = real:sub(1, #box.Text)
            end
            box.Text = ("•"):rep(#real)
            box.CursorPosition = #box.Text + 1
        end)
    end

    box.Focused:Connect(function()
        tw(stroke, { Color = T.accent, Transparency = 0.35 })
        tw(frame,  { BackgroundTransparency = 0.85 })
    end)
    box.FocusLost:Connect(function()
        tw(stroke, { Color = T.border, Transparency = 0.78 })
        tw(frame,  { BackgroundTransparency = 0.92 })
    end)

    local self = { _frame = frame, _box = box, _password = password, _real = "" }

    function self:getValue()
        return password and self._real or box.Text
    end

    function self:setValue(v)
        if password then
            self._real = v
            box.Text   = ("•"):rep(#v)
        else
            box.Text = v
        end
    end

    function self:onChange(fn)
        box:GetPropertyChangedSignal("Text"):Connect(function()
            fn(self:getValue())
        end)
        return self
    end

    function self:onSubmit(fn)
        box.FocusLost:Connect(function(enter)
            if enter then fn(self:getValue()) end
        end)
        return self
    end

    return self
end

-- ── Slider ────────────────────────────────────────────────────────────────────
--   UI.Slider(label, min, max, default)  -> { _frame, getValue(), onChange(fn) }

function Glass.Slider(labelText, minVal, maxVal, default)
    minVal  = minVal  or 0
    maxVal  = maxVal  or 100
    default = default or minVal
    local value = math.clamp(default, minVal, maxVal)

    local frame = Instance.new("Frame")
    frame.Size                   = UDim2.new(1, 0, 0, 52)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel        = 0
    frame.ZIndex                 = 12

    local lbl = Instance.new("TextLabel")
    lbl.Size                   = UDim2.new(1, -60, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text                   = labelText or "Slider"
    lbl.TextColor3             = T.text
    lbl.TextSize               = 13
    lbl.Font                   = T.fontMed
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.ZIndex                 = 13
    lbl.Parent                 = frame

    local valLbl = Instance.new("TextLabel")
    valLbl.Size                   = UDim2.new(0, 55, 0, 20)
    valLbl.Position               = UDim2.new(1, -58, 0, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Text                   = tostring(value)
    valLbl.TextColor3             = T.accent
    valLbl.TextSize               = 13
    valLbl.Font                   = T.fontBold
    valLbl.TextXAlignment         = Enum.TextXAlignment.Right
    valLbl.ZIndex                 = 13
    valLbl.Parent                 = frame

    local track = Instance.new("Frame")
    track.Size            = UDim2.new(1, 0, 0, 6)
    track.Position        = UDim2.new(0, 0, 0, 34)
    track.BackgroundColor3 = T.surface
    track.BackgroundTransparency = 0.2
    track.BorderSizePixel = 0
    track.ZIndex          = 12
    track.Parent          = frame
    applyCorner(track, 6)

    local fill = Instance.new("Frame")
    fill.Size            = UDim2.new((value - minVal) / (maxVal - minVal), 0, 1, 0)
    fill.BackgroundColor3 = T.accent
    fill.BorderSizePixel = 0
    fill.ZIndex          = 13
    fill.Parent          = track
    applyCorner(fill, 6)

    local handle = Instance.new("Frame")
    handle.Size            = UDim2.new(0, 18, 0, 18)
    handle.Position        = UDim2.new((value - minVal) / (maxVal - minVal), -9, 0.5, -9)
    handle.BackgroundColor3 = Color3.fromRGB(255,255,255)
    handle.BorderSizePixel = 0
    handle.ZIndex          = 14
    handle.Parent          = track
    applyCorner(handle, 18)
    applyStroke(handle, T.accent, 0.4, 2)

    local handlers = {}
    local dragging = false

    local hitbox = Instance.new("TextButton")
    hitbox.Size                   = UDim2.new(1, 0, 0, 24)
    hitbox.Position               = UDim2.new(0, 0, 0, 28)
    hitbox.BackgroundTransparency = 1
    hitbox.Text                   = ""
    hitbox.ZIndex                 = 15
    hitbox.Parent                 = frame

    local function updateFromMouse(x)
        local abs     = track.AbsolutePosition.X
        local width   = track.AbsoluteSize.X
        local t       = math.clamp((x - abs) / width, 0, 1)
        value         = math.floor(minVal + t * (maxVal - minVal) + 0.5)
        valLbl.Text   = tostring(value)
        tw(fill,   { Size = UDim2.new(t, 0, 1, 0) }, 0.05)
        tw(handle, { Position = UDim2.new(t, -9, 0.5, -9) }, 0.05)
        for _, fn in ipairs(handlers) do fn(value) end
    end

    hitbox.MouseButton1Down:Connect(function(x)
        dragging = true
        updateFromMouse(x)
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromMouse(inp.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    local self = { _frame = frame }

    function self:getValue() return value end

    function self:onChange(fn)
        handlers[#handlers+1] = fn
        return self
    end

    return self
end

-- ── Label ─────────────────────────────────────────────────────────────────────
--   UI.Label(text, style?)  -> { _frame, setText(t) }
--   style: "title" | "heading" | "body" | "dim" | "code"

function Glass.Label(text, style)
    local frame = Instance.new("Frame")
    frame.Size                   = UDim2.new(1, 0, 0, 28)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel        = 0
    frame.AutomaticSize          = Enum.AutomaticSize.Y
    frame.ZIndex                 = 12

    local lbl = Instance.new("TextLabel")
    lbl.Size                   = UDim2.new(1, 0, 1, 0)
    lbl.AutomaticSize          = Enum.AutomaticSize.Y
    lbl.BackgroundTransparency = 1
    lbl.Text                   = text or ""
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.TextWrapped            = true
    lbl.ZIndex                 = 13
    lbl.Parent                 = frame

    if style == "title" then
        lbl.TextSize   = 22
        lbl.Font       = T.fontBold
        lbl.TextColor3 = T.text
    elseif style == "heading" then
        lbl.TextSize   = 16
        lbl.Font       = T.fontBold
        lbl.TextColor3 = T.text
    elseif style == "dim" then
        lbl.TextSize   = 13
        lbl.Font       = T.fontReg
        lbl.TextColor3 = T.textDim
    elseif style == "code" then
        lbl.TextSize   = 12
        lbl.Font       = T.fontMono
        lbl.TextColor3 = Color3.fromRGB(140, 210, 255)
    else -- "body" default
        lbl.TextSize   = 14
        lbl.Font       = T.fontMed
        lbl.TextColor3 = T.textMid
    end

    local self = { _frame = frame, _lbl = lbl }

    function self:setText(t) lbl.Text = t end

    function self:setColor(c) lbl.TextColor3 = c end

    return self
end

-- ── Divider ───────────────────────────────────────────────────────────────────

function Glass.Divider()
    local frame = Instance.new("Frame")
    frame.Size                   = UDim2.new(1, 0, 0, 14)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel        = 0
    frame.ZIndex                 = 12

    local line = Instance.new("Frame")
    line.Size            = UDim2.new(1, 0, 0, 1)
    line.Position        = UDim2.new(0, 0, 0.5, 0)
    line.BackgroundColor3 = T.border
    line.BackgroundTransparency = 0.82
    line.BorderSizePixel = 0
    line.ZIndex          = 13
    line.Parent          = frame

    return { _frame = frame }
end

-- ── Badge ─────────────────────────────────────────────────────────────────────
--   UI.Badge(text, color?)  -> { _frame }

function Glass.Badge(text, color)
    local bgColor = T.accent
    if     color == "green"  then bgColor = T.green
    elseif color == "red"    then bgColor = T.red
    elseif color == "yellow" then bgColor = T.yellow end

    local frame = Instance.new("Frame")
    frame.Size                   = UDim2.new(0, 0, 0, 24)
    frame.AutomaticSize          = Enum.AutomaticSize.X
    frame.BackgroundColor3       = bgColor
    frame.BackgroundTransparency = 0.25
    frame.BorderSizePixel        = 0
    frame.ZIndex                 = 12
    applyCorner(frame, 6)
    applyStroke(frame, bgColor, 0.55)
    makePad(frame, 10, 4)

    local lbl = Instance.new("TextLabel")
    lbl.Size                   = UDim2.new(0, 0, 1, 0)
    lbl.AutomaticSize          = Enum.AutomaticSize.X
    lbl.BackgroundTransparency = 1
    lbl.Text                   = text or "Badge"
    lbl.TextColor3             = T.text
    lbl.TextSize               = 12
    lbl.Font                   = T.fontBold
    lbl.ZIndex                 = 13
    lbl.Parent                 = frame

    local self = { _frame = frame }
    function self:setText(t) lbl.Text = t end
    function self:setColor(c)
        frame.BackgroundColor3 = c
        applyStroke(frame, c, 0.55)
    end
    return self
end

-- ── Notification / Toast ─────────────────────────────────────────────────────
--   UI.notify(text, type?, duration?)
--   type: "info" | "success" | "error" | "warning"

function Glass.notify(text, notifType, duration)
    duration = duration or 3.5
    local bgColor = T.accent
    local icon    = "ℹ"
    if     notifType == "success" then bgColor = T.green;  icon = "✓"
    elseif notifType == "error"   then bgColor = T.red;    icon = "✕"
    elseif notifType == "warning" then bgColor = T.yellow; icon = "⚠" end

    local root = getRoot("CrystalNotifications")
    local existing = root:FindFirstChild("Stack")
    if not existing then
        existing = Instance.new("Frame")
        existing.Name                = "Stack"
        existing.Size                = UDim2.new(0, 320, 1, 0)
        existing.Position            = UDim2.new(1, -330, 0, 0)
        existing.BackgroundTransparency = 1
        existing.BorderSizePixel     = 0
        existing.ZIndex              = 50
        existing.Parent              = root
        local list = makeList(existing, Enum.FillDirection.Vertical, 8)
        list.VerticalAlignment = Enum.VerticalAlignment.Bottom
        makePad(existing, 0, 16)
    end
    local stack = existing

    local card = Instance.new("Frame")
    card.Size                   = UDim2.new(1, 0, 0, 56)
    card.BackgroundColor3       = T.glass
    card.BackgroundTransparency = 0.82
    card.BorderSizePixel        = 0
    card.ZIndex                 = 51
    card.LayoutOrder            = os.clock()
    card.Parent                 = stack
    applyCorner(card, T.radiusMd)
    applyStroke(card, bgColor, 0.55)

    local accent = Instance.new("Frame")
    accent.Size            = UDim2.new(0, 4, 0.7, 0)
    accent.Position        = UDim2.new(0, 8, 0.15, 0)
    accent.BackgroundColor3 = bgColor
    accent.BorderSizePixel = 0
    accent.ZIndex          = 52
    accent.Parent          = card
    applyCorner(accent, 4)

    local iconLbl = Instance.new("TextLabel")
    iconLbl.Size                   = UDim2.new(0, 28, 1, 0)
    iconLbl.Position               = UDim2.new(0, 18, 0, 0)
    iconLbl.BackgroundTransparency = 1
    iconLbl.Text                   = icon
    iconLbl.TextColor3             = bgColor
    iconLbl.TextSize               = 18
    iconLbl.Font                   = T.fontBold
    iconLbl.ZIndex                 = 52
    iconLbl.Parent                 = card

    local textLbl = Instance.new("TextLabel")
    textLbl.Size                   = UDim2.new(1, -58, 1, 0)
    textLbl.Position               = UDim2.new(0, 50, 0, 0)
    textLbl.BackgroundTransparency = 1
    textLbl.Text                   = text or ""
    textLbl.TextColor3             = T.text
    textLbl.TextSize               = 13
    textLbl.Font                   = T.fontMed
    textLbl.TextXAlignment         = Enum.TextXAlignment.Left
    textLbl.TextWrapped            = true
    textLbl.ZIndex                 = 52
    textLbl.Parent                 = card

    -- Slide in
    card.Position = UDim2.new(1, 20, card.Position.Y.Scale, card.Position.Y.Offset)
    tw(card, { Position = UDim2.new(0, 0, card.Position.Y.Scale, card.Position.Y.Offset) }, 0.3)

    task.delay(duration, function()
        tw(card, { BackgroundTransparency = 1 }, 0.25)
        tw(textLbl, { TextTransparency = 1 }, 0.2)
        tw(iconLbl, { TextTransparency = 1 }, 0.2)
        task.delay(0.28, function() card:Destroy() end)
    end)
end

-- ── Progress bar ──────────────────────────────────────────────────────────────
--   UI.Progress(label, value 0-1)  -> { _frame, setValue(v), getValue() }

function Glass.Progress(labelText, initVal)
    local value = math.clamp(initVal or 0, 0, 1)

    local frame = Instance.new("Frame")
    frame.Size                   = UDim2.new(1, 0, 0, 44)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel        = 0
    frame.ZIndex                 = 12

    local lbl = Instance.new("TextLabel")
    lbl.Size                   = UDim2.new(1, -50, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text                   = labelText or "Progress"
    lbl.TextColor3             = T.text
    lbl.TextSize               = 13
    lbl.Font                   = T.fontMed
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.ZIndex                 = 13
    lbl.Parent                 = frame

    local pctLbl = Instance.new("TextLabel")
    pctLbl.Size                   = UDim2.new(0, 45, 0, 20)
    pctLbl.Position               = UDim2.new(1, -48, 0, 0)
    pctLbl.BackgroundTransparency = 1
    pctLbl.Text                   = math.floor(value * 100) .. "%"
    pctLbl.TextColor3             = T.accent
    pctLbl.TextSize               = 13
    pctLbl.Font                   = T.fontBold
    pctLbl.TextXAlignment         = Enum.TextXAlignment.Right
    pctLbl.ZIndex                 = 13
    pctLbl.Parent                 = frame

    local track = Instance.new("Frame")
    track.Size            = UDim2.new(1, 0, 0, 8)
    track.Position        = UDim2.new(0, 0, 0, 30)
    track.BackgroundColor3 = T.surface
    track.BackgroundTransparency = 0.2
    track.BorderSizePixel = 0
    track.ZIndex          = 12
    track.Parent          = frame
    applyCorner(track, 8)

    local fill = Instance.new("Frame")
    fill.Size            = UDim2.new(value, 0, 1, 0)
    fill.BackgroundColor3 = T.accent
    fill.BorderSizePixel = 0
    fill.ZIndex          = 13
    fill.Parent          = track
    applyCorner(fill, 8)

    -- Shimmer
    local shimmer = Instance.new("Frame")
    shimmer.Size            = UDim2.new(0.3, 0, 1, 0)
    shimmer.BackgroundColor3 = Color3.fromRGB(255,255,255)
    shimmer.BackgroundTransparency = 0.7
    shimmer.BorderSizePixel = 0
    shimmer.ZIndex          = 14
    shimmer.ClipsDescendants = false
    shimmer.Parent          = fill
    applyCorner(shimmer, 8)

    local shimmerLoop = RunService.Heartbeat:Connect(function()
        local t  = (os.clock() % 1.5) / 1.5
        shimmer.Position = UDim2.new(t - 0.3, 0, 0, 0)
    end)

    local self = { _frame = frame, _shimmer = shimmerLoop }

    function self:getValue() return value end

    function self:setValue(v)
        value = math.clamp(v, 0, 1)
        pctLbl.Text = math.floor(value * 100) .. "%"
        tw(fill, { Size = UDim2.new(value, 0, 1, 0) }, 0.3)
    end

    function self:destroy()
        shimmerLoop:Disconnect()
        frame:Destroy()
    end

    return self
end

-- ── Dropdown / Select ─────────────────────────────────────────────────────────
--   UI.Dropdown(label, options[])  -> { _frame, getValue(), onChange(fn) }

function Glass.Dropdown(labelText, options)
    options = options or {}
    local selected = options[1] or ""
    local open     = false
    local handlers = {}

    local frame = Instance.new("Frame")
    frame.Size                   = UDim2.new(1, 0, 0, 44)
    frame.BackgroundColor3       = T.glass
    frame.BackgroundTransparency = 0.92
    frame.BorderSizePixel        = 0
    frame.ZIndex                 = 12
    applyCorner(frame, T.radiusMd)
    local stroke = applyStroke(frame, T.border, 0.78)
    frame.ClipsDescendants = false

    local mainBtn = Instance.new("TextButton")
    mainBtn.Size                   = UDim2.new(1, 0, 1, 0)
    mainBtn.BackgroundTransparency = 1
    mainBtn.Text                   = ""
    mainBtn.ZIndex                 = 13
    mainBtn.Parent                 = frame

    local selectedLbl = Instance.new("TextLabel")
    selectedLbl.Size                   = UDim2.new(1, -44, 1, 0)
    selectedLbl.Position               = UDim2.new(0, 12, 0, 0)
    selectedLbl.BackgroundTransparency = 1
    selectedLbl.Text                   = selected
    selectedLbl.TextColor3             = T.text
    selectedLbl.TextSize               = 14
    selectedLbl.Font                   = T.fontMed
    selectedLbl.TextXAlignment         = Enum.TextXAlignment.Left
    selectedLbl.ZIndex                 = 14
    selectedLbl.Parent                 = frame

    local arrow = Instance.new("TextLabel")
    arrow.Size                   = UDim2.new(0, 30, 1, 0)
    arrow.Position               = UDim2.new(1, -34, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text                   = "▾"
    arrow.TextColor3             = T.textDim
    arrow.TextSize               = 14
    arrow.Font                   = T.fontBold
    arrow.ZIndex                 = 14
    arrow.Parent                 = frame

    -- Dropdown list (hidden initially)
    local listFrame = glassFrame(frame,
        UDim2.new(1, 0, 0, #options * 36 + 8),
        UDim2.new(0, 0, 1, 4),
        20, T.radiusMd
    )
    listFrame.Visible = false
    makeList(listFrame, Enum.FillDirection.Vertical, 2)
    makePad(listFrame, 4, 4)

    for _, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size                   = UDim2.new(1, 0, 0, 32)
        optBtn.BackgroundColor3       = T.glass
        optBtn.BackgroundTransparency = 0.95
        optBtn.Text                   = opt
        optBtn.TextColor3             = T.textMid
        optBtn.TextSize               = 13
        optBtn.Font                   = T.fontMed
        optBtn.BorderSizePixel        = 0
        optBtn.ZIndex                 = 21
        optBtn.Parent                 = listFrame
        applyCorner(optBtn, 6)

        optBtn.MouseEnter:Connect(function()
            tw(optBtn, { BackgroundTransparency = 0.75, TextColor3 = T.text })
        end)
        optBtn.MouseLeave:Connect(function()
            tw(optBtn, { BackgroundTransparency = 0.95, TextColor3 = T.textMid })
        end)
        optBtn.MouseButton1Click:Connect(function()
            selected        = opt
            selectedLbl.Text = opt
            listFrame.Visible = false
            open = false
            tw(arrow, { Rotation = 0 })
            for _, fn in ipairs(handlers) do fn(opt) end
        end)
    end

    mainBtn.MouseButton1Click:Connect(function()
        open = not open
        listFrame.Visible = open
        tw(arrow, { Rotation = open and 180 or 0 })
        if open then
            tw(stroke, { Color = T.accent, Transparency = 0.4 })
        else
            tw(stroke, { Color = T.border, Transparency = 0.78 })
        end
    end)

    local self = { _frame = frame }

    function self:getValue() return selected end

    function self:onChange(fn)
        handlers[#handlers+1] = fn
        return self
    end

    return self
end

-- ── Export ────────────────────────────────────────────────────────────────────

return Glass
