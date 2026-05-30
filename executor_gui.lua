-- Premium Black Executor GUI
-- Mobile & PC | Draggable | Client Side (loadstring) / Non-Client Side (require)

local Players       = game:GetService("Players")
local UIS           = game:GetService("UserInputService")
local TweenService  = game:GetService("TweenService")

local LP         = Players.LocalPlayer
local PlayerGui  = LP:WaitForChild("PlayerGui")

-- Remove any existing instance
if PlayerGui:FindFirstChild("PremiumExec") then
    PlayerGui.PremiumExec:Destroy()
end

-- ─────────────────────────────────────────────
-- Colours
-- ─────────────────────────────────────────────
local C = {
    BG         = Color3.fromRGB(10,  10,  13),
    PANEL      = Color3.fromRGB(18,  18,  23),
    INPUT_BG   = Color3.fromRGB(14,  14,  18),
    ACCENT     = Color3.fromRGB(100,  20, 220),
    ACCENT_HOV = Color3.fromRGB(120,  40, 240),
    DIM        = Color3.fromRGB(30,   30,  40),
    DIM_TEXT   = Color3.fromRGB(140, 140, 170),
    WHITE      = Color3.new(1, 1, 1),
    GREEN      = Color3.fromRGB(70,  210,  90),
    RED        = Color3.fromRGB(240,  70,  70),
    YELLOW     = Color3.fromRGB(255, 200,  50),
    TITLE_TEXT = Color3.fromRGB(200, 160, 255),
    STROKE     = Color3.fromRGB(80,   10, 180),
}

local FONT_BOLD   = Enum.Font.GothamBold
local FONT_NORMAL = Enum.Font.Gotham
local FONT_CODE   = Enum.Font.Code
local TWEEN_FAST  = TweenInfo.new(0.15)

-- ─────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────
local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or C.STROKE
    s.Thickness = thickness or 1.2
    s.Parent = parent
    return s
end

local function tween(obj, props)
    TweenService:Create(obj, TWEEN_FAST, props):Play()
end

-- ─────────────────────────────────────────────
-- Root
-- ─────────────────────────────────────────────
local SG = Instance.new("ScreenGui")
SG.Name            = "PremiumExec"
SG.ResetOnSpawn    = false
SG.DisplayOrder    = 999
SG.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
SG.Parent          = PlayerGui

-- ─────────────────────────────────────────────
-- Main window  (420 × 310)
-- ─────────────────────────────────────────────
local Main = Instance.new("Frame")
Main.Name              = "Main"
Main.Size              = UDim2.new(0, 420, 0, 310)
Main.Position          = UDim2.new(0.5, -210, 0.5, -155)
Main.BackgroundColor3  = C.BG
Main.BorderSizePixel   = 0
Main.ClipsDescendants  = true
Main.Parent            = SG
corner(Main, 9)
stroke(Main, C.STROKE, 1.4)

-- ─────────────────────────────────────────────
-- Title bar
-- ─────────────────────────────────────────────
local TBar = Instance.new("Frame")
TBar.Name             = "TitleBar"
TBar.Size             = UDim2.new(1, 0, 0, 38)
TBar.BackgroundColor3 = C.PANEL
TBar.BorderSizePixel  = 0
TBar.ZIndex           = 2
TBar.Parent           = Main
corner(TBar, 9)

-- Flat bottom on title bar
local TBarFix = Instance.new("Frame")
TBarFix.Size             = UDim2.new(1, 0, 0.5, 0)
TBarFix.Position         = UDim2.new(0, 0, 0.5, 0)
TBarFix.BackgroundColor3 = C.PANEL
TBarFix.BorderSizePixel  = 0
TBarFix.ZIndex           = 2
TBarFix.Parent           = TBar

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size               = UDim2.new(1, -100, 1, 0)
TitleLbl.Position           = UDim2.new(0, 12, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text               = "  Premium Executor"
TitleLbl.TextColor3         = C.TITLE_TEXT
TitleLbl.TextSize           = 14
TitleLbl.Font               = FONT_BOLD
TitleLbl.TextXAlignment     = Enum.TextXAlignment.Left
TitleLbl.ZIndex             = 3
TitleLbl.Parent             = TBar

-- Minimize
local MinBtn = Instance.new("TextButton")
MinBtn.Size             = UDim2.new(0, 28, 0, 22)
MinBtn.Position         = UDim2.new(1, -64, 0.5, -11)
MinBtn.BackgroundColor3 = C.DIM
MinBtn.Text             = "—"
MinBtn.TextColor3       = C.DIM_TEXT
MinBtn.TextSize         = 13
MinBtn.Font             = FONT_BOLD
MinBtn.BorderSizePixel  = 0
MinBtn.AutoButtonColor  = false
MinBtn.ZIndex           = 3
MinBtn.Parent           = TBar
corner(MinBtn, 5)

-- Close
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size             = UDim2.new(0, 28, 0, 22)
CloseBtn.Position         = UDim2.new(1, -32, 0.5, -11)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 55)
CloseBtn.Text             = "✕"
CloseBtn.TextColor3       = C.WHITE
CloseBtn.TextSize         = 12
CloseBtn.Font             = FONT_BOLD
CloseBtn.BorderSizePixel  = 0
CloseBtn.AutoButtonColor  = false
CloseBtn.ZIndex           = 3
CloseBtn.Parent           = TBar
corner(CloseBtn, 5)

-- ─────────────────────────────────────────────
-- Content wrapper (below title bar)
-- ─────────────────────────────────────────────
local Content = Instance.new("Frame")
Content.Name             = "Content"
Content.Size             = UDim2.new(1, 0, 1, -38)
Content.Position         = UDim2.new(0, 0, 0, 38)
Content.BackgroundTransparency = 1
Content.ClipsDescendants = false
Content.Parent           = Main

-- ─────────────────────────────────────────────
-- Mode toggle  (Client Side / Non-Client Side)
-- ─────────────────────────────────────────────
local ModeBar = Instance.new("Frame")
ModeBar.Size             = UDim2.new(1, -20, 0, 34)
ModeBar.Position         = UDim2.new(0, 10, 0, 8)
ModeBar.BackgroundColor3 = C.PANEL
ModeBar.BorderSizePixel  = 0
ModeBar.Parent           = Content
corner(ModeBar, 7)

local function modeBtn(text, xPos)
    local b = Instance.new("TextButton")
    b.Size             = UDim2.new(0.5, -5, 1, -8)
    b.Position         = UDim2.new(xPos, xPos == 0 and 4 or 1, 0, 4)
    b.BackgroundColor3 = C.DIM
    b.Text             = text
    b.TextColor3       = C.DIM_TEXT
    b.TextSize         = 12
    b.Font             = FONT_BOLD
    b.BorderSizePixel  = 0
    b.AutoButtonColor  = false
    b.Parent           = ModeBar
    corner(b, 5)
    return b
end

local ClientBtn    = modeBtn("Client Side",     0)
local NonClientBtn = modeBtn("Non-Client Side", 0.5)

-- ─────────────────────────────────────────────
-- Mode hint label
-- ─────────────────────────────────────────────
local HintLbl = Instance.new("TextLabel")
HintLbl.Size               = UDim2.new(1, -20, 0, 16)
HintLbl.Position           = UDim2.new(0, 10, 0, 48)
HintLbl.BackgroundTransparency = 1
HintLbl.TextColor3         = Color3.fromRGB(110, 70, 190)
HintLbl.TextSize           = 11
HintLbl.Font               = FONT_NORMAL
HintLbl.TextXAlignment     = Enum.TextXAlignment.Left
HintLbl.Parent             = Content

-- ─────────────────────────────────────────────
-- Code input
-- ─────────────────────────────────────────────
local InputScroll = Instance.new("ScrollingFrame")
InputScroll.Name                = "InputScroll"
InputScroll.Size                = UDim2.new(1, -20, 0, 118)
InputScroll.Position            = UDim2.new(0, 10, 0, 68)
InputScroll.BackgroundColor3    = C.INPUT_BG
InputScroll.BorderSizePixel     = 0
InputScroll.ScrollBarThickness  = 4
InputScroll.ScrollBarImageColor3 = C.ACCENT
InputScroll.CanvasSize          = UDim2.new(0, 0, 0, 0)
InputScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
InputScroll.Parent              = Content
corner(InputScroll, 7)
stroke(InputScroll, Color3.fromRGB(55, 5, 130), 1)

local CodeBox = Instance.new("TextBox")
CodeBox.Name               = "CodeBox"
CodeBox.Size               = UDim2.new(1, -10, 1, 0)
CodeBox.Position           = UDim2.new(0, 5, 0, 4)
CodeBox.BackgroundTransparency = 1
CodeBox.Text               = ""
CodeBox.PlaceholderText    = "-- Paste or type your script here..."
CodeBox.PlaceholderColor3  = Color3.fromRGB(65, 65, 85)
CodeBox.TextColor3         = Color3.fromRGB(215, 215, 255)
CodeBox.TextSize           = 12
CodeBox.Font               = FONT_CODE
CodeBox.MultiLine          = true
CodeBox.TextXAlignment     = Enum.TextXAlignment.Left
CodeBox.TextYAlignment     = Enum.TextYAlignment.Top
CodeBox.ClearTextOnFocus   = false
CodeBox.Parent             = InputScroll

-- ─────────────────────────────────────────────
-- Status label
-- ─────────────────────────────────────────────
local StatusLbl = Instance.new("TextLabel")
StatusLbl.Size               = UDim2.new(1, -20, 0, 16)
StatusLbl.Position           = UDim2.new(0, 10, 0, 192)
StatusLbl.BackgroundTransparency = 1
StatusLbl.Text               = "Ready."
StatusLbl.TextColor3         = C.GREEN
StatusLbl.TextSize           = 11
StatusLbl.Font               = FONT_NORMAL
StatusLbl.TextXAlignment     = Enum.TextXAlignment.Left
StatusLbl.Parent             = Content

-- ─────────────────────────────────────────────
-- Button row
-- ─────────────────────────────────────────────
local BtnRow = Instance.new("Frame")
BtnRow.Size                = UDim2.new(1, -20, 0, 38)
BtnRow.Position            = UDim2.new(0, 10, 0, 212)
BtnRow.BackgroundTransparency = 1
BtnRow.Parent              = Content

local BtnLayout = Instance.new("UIListLayout")
BtnLayout.FillDirection        = Enum.FillDirection.Horizontal
BtnLayout.HorizontalAlignment  = Enum.HorizontalAlignment.Left
BtnLayout.VerticalAlignment    = Enum.VerticalAlignment.Center
BtnLayout.Padding              = UDim.new(0, 8)
BtnLayout.Parent               = BtnRow

local function actionBtn(text, bgColor, w)
    local b = Instance.new("TextButton")
    b.Size             = UDim2.new(0, w, 0, 34)
    b.BackgroundColor3 = bgColor
    b.Text             = text
    b.TextColor3       = C.WHITE
    b.TextSize         = 13
    b.Font             = FONT_BOLD
    b.BorderSizePixel  = 0
    b.AutoButtonColor  = false
    b.Parent           = BtnRow
    corner(b, 6)
    return b
end

local ExecBtn  = actionBtn("  Execute", C.ACCENT, 128)
local ClearBtn = actionBtn("Clear",     C.DIM,    80)

-- Tweak clear button text colour
ClearBtn.TextColor3 = C.DIM_TEXT

-- ─────────────────────────────────────────────
-- State
-- ─────────────────────────────────────────────
local mode       = "client"   -- "client" | "nonclient"
local minimised  = false

local function setStatus(msg, colour)
    StatusLbl.Text       = msg
    StatusLbl.TextColor3 = colour or C.GREEN
end

-- ─────────────────────────────────────────────
-- Mode switching
-- ─────────────────────────────────────────────
local function applyMode(m)
    mode = m
    if m == "client" then
        tween(ClientBtn,    { BackgroundColor3 = C.ACCENT,  TextColor3 = C.WHITE     })
        tween(NonClientBtn, { BackgroundColor3 = C.DIM,     TextColor3 = C.DIM_TEXT  })
        HintLbl.Text       = "Mode: Client Side   |   Runs: loadstring(code)()"
        CodeBox.PlaceholderText = "-- Paste client-side script here (loadstring)..."
    else
        tween(NonClientBtn, { BackgroundColor3 = C.ACCENT, TextColor3 = C.WHITE    })
        tween(ClientBtn,    { BackgroundColor3 = C.DIM,    TextColor3 = C.DIM_TEXT })
        HintLbl.Text       = "Mode: Non-Client Side   |   Runs: require(id)"
        CodeBox.PlaceholderText = "-- Enter numeric Asset ID for require()..."
    end
    setStatus("Mode switched.", C.TITLE_TEXT)
end

applyMode("client")

ClientBtn.MouseButton1Click:Connect(function()    applyMode("client")    end)
NonClientBtn.MouseButton1Click:Connect(function() applyMode("nonclient") end)

-- ─────────────────────────────────────────────
-- Execute
-- ─────────────────────────────────────────────
ExecBtn.MouseButton1Click:Connect(function()
    local code = CodeBox.Text
    if code == "" or code:match("^%s*$") then
        setStatus("Nothing to execute.", C.YELLOW)
        return
    end

    if mode == "client" then
        -- Client Side: loadstring only
        local fn, compErr = loadstring(code)
        if not fn then
            setStatus("Compile error: " .. tostring(compErr):sub(1, 55), C.RED)
            return
        end
        local ok, runErr = pcall(fn)
        if ok then
            setStatus("Executed via loadstring.", C.GREEN)
        else
            setStatus("Runtime error: " .. tostring(runErr):sub(1, 55), C.RED)
        end
    else
        -- Non-Client Side: require only
        local id = tonumber(code:match("^%s*(.-)%s*$"))
        if not id then
            setStatus("Non-client mode requires a numeric Asset ID.", C.YELLOW)
            return
        end
        local ok, err = pcall(require, id)
        if ok then
            setStatus("Executed via require(" .. id .. ").", C.GREEN)
        else
            setStatus("require error: " .. tostring(err):sub(1, 55), C.RED)
        end
    end
end)

-- ─────────────────────────────────────────────
-- Clear
-- ─────────────────────────────────────────────
ClearBtn.MouseButton1Click:Connect(function()
    CodeBox.Text = ""
    setStatus("Editor cleared.", C.DIM_TEXT)
end)

-- ─────────────────────────────────────────────
-- Close / Minimise
-- ─────────────────────────────────────────────
CloseBtn.MouseButton1Click:Connect(function()
    tween(Main, { Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(
        Main.Position.X.Scale,
        Main.Position.X.Offset + 210,
        Main.Position.Y.Scale,
        Main.Position.Y.Offset + 155
    )})
    task.delay(0.2, function() SG:Destroy() end)
end)

MinBtn.MouseButton1Click:Connect(function()
    minimised = not minimised
    if minimised then
        tween(Main, { Size = UDim2.new(0, 420, 0, 38) })
        MinBtn.Text = "□"
    else
        tween(Main, { Size = UDim2.new(0, 420, 0, 310) })
        MinBtn.Text = "—"
    end
end)

-- ─────────────────────────────────────────────
-- Hover effects on Execute / Minimize / Close
-- ─────────────────────────────────────────────
ExecBtn.MouseEnter:Connect(function()  tween(ExecBtn,  { BackgroundColor3 = C.ACCENT_HOV }) end)
ExecBtn.MouseLeave:Connect(function()  tween(ExecBtn,  { BackgroundColor3 = C.ACCENT     }) end)
CloseBtn.MouseEnter:Connect(function() tween(CloseBtn, { BackgroundColor3 = Color3.fromRGB(230, 60, 75) }) end)
CloseBtn.MouseLeave:Connect(function() tween(CloseBtn, { BackgroundColor3 = Color3.fromRGB(200, 40, 55) }) end)
MinBtn.MouseEnter:Connect(function()   tween(MinBtn,   { BackgroundColor3 = Color3.fromRGB(50, 50, 65)  }) end)
MinBtn.MouseLeave:Connect(function()   tween(MinBtn,   { BackgroundColor3 = C.DIM                       }) end)

-- ─────────────────────────────────────────────
-- Dragging  (mouse + touch, both handled via
-- InputBegan / InputChanged / InputEnded)
-- ─────────────────────────────────────────────
local dragging   = false
local dragInput  = nil
local dragStart  = nil
local frameStart = nil

TBar.InputBegan:Connect(function(inp)
    local t = inp.UserInputType
    if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
        dragging   = true
        dragInput  = inp
        dragStart  = inp.Position
        frameStart = Main.Position
        inp.Changed:Connect(function()
            if inp.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UIS.InputChanged:Connect(function(inp)
    if not dragging then return end
    local t = inp.UserInputType
    if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
        local delta = inp.Position - dragStart
        Main.Position = UDim2.new(
            frameStart.X.Scale,
            frameStart.X.Offset + delta.X,
            frameStart.Y.Scale,
            frameStart.Y.Offset + delta.Y
        )
    end
end)

UIS.InputEnded:Connect(function(inp)
    local t = inp.UserInputType
    if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
        dragging = false
    end
end)
