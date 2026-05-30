-- ============================================================
--  Full Serverside Executor GUI  (executor_gui.lua)
--  LocalScript  |  Mobile & PC  |  Draggable  |  Premium Black
--
--  Modes:
--    Client Side    → runs code via local  loadstring()
--    Server Side    → sends code to SS_Executor.lua via RemoteFunction
--      Sub-modes:   loadstring (server) | require (asset ID)
--
--  Requires SS_Executor.lua running server-side first.
-- ============================================================

local Players      = game:GetService("Players")
local RepStorage   = game:GetService("ReplicatedStorage")
local UIS          = game:GetService("UserInputService")
local TweenSvc     = game:GetService("TweenService")
local RunService   = game:GetService("RunService")

local LP        = Players.LocalPlayer
local PGui      = LP:WaitForChild("PlayerGui")

-- ── Destroy stale GUI ──────────────────────────────────────
if PGui:FindFirstChild("SS_ExecGUI") then
    PGui.SS_ExecGUI:Destroy()
end

-- ── Wait for server remote ─────────────────────────────────
local REMOTE_NAME = "SS_ExecBridge"
local Bridge      = RepStorage:WaitForChild(REMOTE_NAME, 10)

-- ── Colours / constants ────────────────────────────────────
local C = {
    BG        = Color3.fromRGB(8,   8,  11),
    PANEL     = Color3.fromRGB(16,  16, 21),
    INPUT_BG  = Color3.fromRGB(12,  12, 16),
    ACCENT    = Color3.fromRGB(105, 15, 225),
    ACC_HOV   = Color3.fromRGB(125, 35, 245),
    DIM       = Color3.fromRGB(28,  28, 38),
    DIM_TXT   = Color3.fromRGB(130, 130, 165),
    WHITE     = Color3.new(1, 1, 1),
    GREEN     = Color3.fromRGB(65,  210,  80),
    RED       = Color3.fromRGB(240,  65,  65),
    YELLOW    = Color3.fromRGB(255, 200,  45),
    PURPLE    = Color3.fromRGB(190, 145, 255),
    STROKE    = Color3.fromRGB(75,  10,  175),
    SERVER_A  = Color3.fromRGB(20, 130, 220),
    SERVER_H  = Color3.fromRGB(35, 155, 245),
}
local TI  = TweenInfo.new(0.14)
local TIS = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- ── Helpers ────────────────────────────────────────────────
local function tw(obj, p) TweenSvc:Create(obj, TI, p):Play() end
local function twS(obj, p) TweenSvc:Create(obj, TIS, p):Play() end

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 7)
    c.Parent = p
end

local function uistroke(p, col, thick)
    local s = Instance.new("UIStroke")
    s.Color     = col or C.STROKE
    s.Thickness = thick or 1.2
    s.Parent    = p
end

local function label(parent, props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Font     = props.font  or Enum.Font.Gotham
    l.TextSize = props.size  or 12
    l.TextColor3 = props.color or C.WHITE
    l.TextXAlignment = props.xa or Enum.TextXAlignment.Left
    l.TextYAlignment = props.ya or Enum.TextYAlignment.Center
    for k, v in props do
        if k ~= "font" and k ~= "size" and k ~= "color" and k ~= "xa" and k ~= "ya" then
            pcall(function() l[k] = v end)
        end
    end
    l.Parent = parent
    return l
end

-- ── Root ScreenGui ─────────────────────────────────────────
local SG = Instance.new("ScreenGui")
SG.Name           = "SS_ExecGUI"
SG.ResetOnSpawn   = false
SG.DisplayOrder   = 999
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.Parent         = PGui

-- ── Main window ────────────────────────────────────────────
local WIN_W, WIN_H = 450, 360

local Win = Instance.new("Frame")
Win.Name             = "Win"
Win.Size             = UDim2.new(0, WIN_W, 0, WIN_H)
Win.Position         = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2)
Win.BackgroundColor3 = C.BG
Win.BorderSizePixel  = 0
Win.ClipsDescendants = true
Win.Parent           = SG
corner(Win, 10)
uistroke(Win, C.STROKE, 1.5)

-- ── Title bar ──────────────────────────────────────────────
local TBar = Instance.new("Frame")
TBar.Name             = "TBar"
TBar.Size             = UDim2.new(1, 0, 0, 40)
TBar.BackgroundColor3 = C.PANEL
TBar.BorderSizePixel  = 0
TBar.ZIndex           = 4
TBar.Parent           = Win
corner(TBar, 10)

-- Patch flat bottom edge of title bar
local TBarPatch = Instance.new("Frame")
TBarPatch.Size             = UDim2.new(1, 0, 0.5, 0)
TBarPatch.Position         = UDim2.new(0, 0, 0.5, 0)
TBarPatch.BackgroundColor3 = C.PANEL
TBarPatch.BorderSizePixel  = 0
TBarPatch.ZIndex           = 4
TBarPatch.Parent           = TBar

-- Logo / title
local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size               = UDim2.new(1, -110, 1, 0)
TitleLbl.Position           = UDim2.new(0, 12, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text               = "  Full SS Executor"
TitleLbl.TextColor3         = C.PURPLE
TitleLbl.TextSize           = 14
TitleLbl.Font               = Enum.Font.GothamBold
TitleLbl.TextXAlignment     = Enum.TextXAlignment.Left
TitleLbl.ZIndex             = 5
TitleLbl.Parent             = TBar

-- Server status dot
local DotLbl = Instance.new("TextLabel")
DotLbl.Size               = UDim2.new(0, 90, 0, 14)
DotLbl.Position           = UDim2.new(0, 12, 0, 26)
DotLbl.BackgroundTransparency = 1
DotLbl.Text               = "● Connecting..."
DotLbl.TextColor3         = C.YELLOW
DotLbl.TextSize           = 10
DotLbl.Font               = Enum.Font.Gotham
DotLbl.TextXAlignment     = Enum.TextXAlignment.Left
DotLbl.ZIndex             = 5
DotLbl.Parent             = Win

-- Minimize
local MinBtn = Instance.new("TextButton")
MinBtn.Size             = UDim2.new(0, 30, 0, 24)
MinBtn.Position         = UDim2.new(1, -70, 0.5, -12)
MinBtn.BackgroundColor3 = C.DIM
MinBtn.Text             = "—"
MinBtn.TextColor3       = C.DIM_TXT
MinBtn.TextSize         = 13
MinBtn.Font             = Enum.Font.GothamBold
MinBtn.BorderSizePixel  = 0
MinBtn.AutoButtonColor  = false
MinBtn.ZIndex           = 5
MinBtn.Parent           = TBar
corner(MinBtn, 5)

-- Close
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size             = UDim2.new(0, 30, 0, 24)
CloseBtn.Position         = UDim2.new(1, -34, 0.5, -12)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 38, 55)
CloseBtn.Text             = "✕"
CloseBtn.TextColor3       = C.WHITE
CloseBtn.TextSize         = 13
CloseBtn.Font             = Enum.Font.GothamBold
CloseBtn.BorderSizePixel  = 0
CloseBtn.AutoButtonColor  = false
CloseBtn.ZIndex           = 5
CloseBtn.Parent           = TBar
corner(CloseBtn, 5)

-- ── Content area ───────────────────────────────────────────
local Body = Instance.new("Frame")
Body.Name             = "Body"
Body.Size             = UDim2.new(1, 0, 1, -40)
Body.Position         = UDim2.new(0, 0, 0, 40)
Body.BackgroundTransparency = 1
Body.ClipsDescendants = false
Body.Parent           = Win

-- ── Mode bar  (Client Side / Server Side) ──────────────────
local ModeBar = Instance.new("Frame")
ModeBar.Size             = UDim2.new(1, -20, 0, 36)
ModeBar.Position         = UDim2.new(0, 10, 0, 10)
ModeBar.BackgroundColor3 = C.PANEL
ModeBar.BorderSizePixel  = 0
ModeBar.Parent           = Body
corner(ModeBar, 8)

local function makeTabBtn(text, xScale, xOff)
    local b = Instance.new("TextButton")
    b.Size             = UDim2.new(0.5, -5, 1, -8)
    b.Position         = UDim2.new(xScale, xOff, 0, 4)
    b.BackgroundColor3 = C.DIM
    b.Text             = text
    b.TextColor3       = C.DIM_TXT
    b.TextSize         = 12
    b.Font             = Enum.Font.GothamBold
    b.BorderSizePixel  = 0
    b.AutoButtonColor  = false
    b.Parent           = ModeBar
    corner(b, 5)
    return b
end

local ClientTab = makeTabBtn("  Client Side",  0,   4)
local ServerTab = makeTabBtn("  Server Side",  0.5, 1)

-- ── Sub-mode bar (Server: loadstring / require) ─────────────
local SubBar = Instance.new("Frame")
SubBar.Size             = UDim2.new(1, -20, 0, 30)
SubBar.Position         = UDim2.new(0, 10, 0, 52)
SubBar.BackgroundColor3 = C.PANEL
SubBar.BorderSizePixel  = 0
SubBar.Visible          = false
SubBar.Parent           = Body
corner(SubBar, 7)

local function makeSubBtn(text, xScale, xOff)
    local b = Instance.new("TextButton")
    b.Size             = UDim2.new(0.5, -5, 1, -6)
    b.Position         = UDim2.new(xScale, xOff, 0, 3)
    b.BackgroundColor3 = C.DIM
    b.Text             = text
    b.TextColor3       = C.DIM_TXT
    b.TextSize         = 11
    b.Font             = Enum.Font.GothamBold
    b.BorderSizePixel  = 0
    b.AutoButtonColor  = false
    b.Parent           = SubBar
    corner(b, 5)
    return b
end

local SubLS  = makeSubBtn("loadstring", 0,   4)
local SubReq = makeSubBtn("require",    0.5, 1)

-- ── Hint label ─────────────────────────────────────────────
local HintLbl = Instance.new("TextLabel")
HintLbl.Size               = UDim2.new(1, -20, 0, 15)
HintLbl.Position           = UDim2.new(0, 10, 0, 88)
HintLbl.BackgroundTransparency = 1
HintLbl.TextColor3         = Color3.fromRGB(95, 60, 175)
HintLbl.TextSize           = 10
HintLbl.Font               = Enum.Font.Gotham
HintLbl.TextXAlignment     = Enum.TextXAlignment.Left
HintLbl.Parent             = Body

-- ── Code editor ────────────────────────────────────────────
local EditorScroll = Instance.new("ScrollingFrame")
EditorScroll.Size                = UDim2.new(1, -20, 0, 140)
EditorScroll.Position            = UDim2.new(0, 10, 0, 108)
EditorScroll.BackgroundColor3    = C.INPUT_BG
EditorScroll.BorderSizePixel     = 0
EditorScroll.ScrollBarThickness  = 4
EditorScroll.ScrollBarImageColor3 = C.ACCENT
EditorScroll.CanvasSize          = UDim2.new(0, 0, 0, 0)
EditorScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
EditorScroll.Parent              = Body
corner(EditorScroll, 7)
uistroke(EditorScroll, Color3.fromRGB(50, 5, 120), 1)

local CodeBox = Instance.new("TextBox")
CodeBox.Size               = UDim2.new(1, -12, 1, 0)
CodeBox.Position           = UDim2.new(0, 6, 0, 5)
CodeBox.BackgroundTransparency = 1
CodeBox.Text               = ""
CodeBox.PlaceholderText    = "-- Paste or type your script here..."
CodeBox.PlaceholderColor3  = Color3.fromRGB(60, 60, 80)
CodeBox.TextColor3         = Color3.fromRGB(215, 215, 255)
CodeBox.TextSize           = 12
CodeBox.Font               = Enum.Font.Code
CodeBox.MultiLine          = true
CodeBox.TextXAlignment     = Enum.TextXAlignment.Left
CodeBox.TextYAlignment     = Enum.TextYAlignment.Top
CodeBox.ClearTextOnFocus   = false
CodeBox.Parent             = EditorScroll

-- ── Status label ───────────────────────────────────────────
local StatusLbl = Instance.new("TextLabel")
StatusLbl.Size               = UDim2.new(1, -20, 0, 16)
StatusLbl.Position           = UDim2.new(0, 10, 0, 255)
StatusLbl.BackgroundTransparency = 1
StatusLbl.Text               = "Idle."
StatusLbl.TextColor3         = C.DIM_TXT
StatusLbl.TextSize           = 11
StatusLbl.Font               = Enum.Font.Gotham
StatusLbl.TextXAlignment     = Enum.TextXAlignment.Left
StatusLbl.TextTruncate       = Enum.TextTruncate.AtEnd
StatusLbl.Parent             = Body

-- ── Button row ─────────────────────────────────────────────
local BtnRow = Instance.new("Frame")
BtnRow.Size                = UDim2.new(1, -20, 0, 40)
BtnRow.Position            = UDim2.new(0, 10, 0, 274)
BtnRow.BackgroundTransparency = 1
BtnRow.Parent              = Body

local BtnLayout = Instance.new("UIListLayout")
BtnLayout.FillDirection       = Enum.FillDirection.Horizontal
BtnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
BtnLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
BtnLayout.Padding             = UDim.new(0, 8)
BtnLayout.Parent              = BtnRow

local function actionBtn(text, bg, w)
    local b = Instance.new("TextButton")
    b.Size             = UDim2.new(0, w, 0, 36)
    b.BackgroundColor3 = bg
    b.Text             = text
    b.TextColor3       = C.WHITE
    b.TextSize         = 13
    b.Font             = Enum.Font.GothamBold
    b.BorderSizePixel  = 0
    b.AutoButtonColor  = false
    b.Parent           = BtnRow
    corner(b, 7)
    return b
end

local ExecBtn  = actionBtn("  Execute", C.ACCENT, 130)
local ClearBtn = actionBtn("Clear",     C.DIM,    80)
local CopyBtn  = actionBtn("Copy",      C.DIM,    75)

ClearBtn.TextColor3 = C.DIM_TXT
CopyBtn.TextColor3  = C.DIM_TXT

-- ── State ──────────────────────────────────────────────────
local MODE     = "client"   -- "client" | "server"
local SUB_MODE = "ls"       -- "ls" | "req"  (server sub-mode)
local minimised = false
local serverOK  = false

-- ── Status helper ──────────────────────────────────────────
local function setStatus(msg, col)
    StatusLbl.Text       = msg
    StatusLbl.TextColor3 = col or C.DIM_TXT
end

-- ── Server ping ────────────────────────────────────────────
local function pingServer()
    if not Bridge then
        DotLbl.Text       = "● No bridge found"
        DotLbl.TextColor3 = C.RED
        setStatus("SS_ExecBridge remote not found. Is SS_Executor.lua running?", C.RED)
        return
    end
    local ok, res = pcall(Bridge.InvokeServer, Bridge, "ping")
    if ok and res and res.ok then
        serverOK          = true
        DotLbl.Text       = "● Server connected"
        DotLbl.TextColor3 = C.GREEN
        setStatus("Server online. Ready.", C.GREEN)
    else
        serverOK          = false
        DotLbl.Text       = "● Server offline"
        DotLbl.TextColor3 = C.RED
        setStatus("Server not responding. Check SS_Executor.lua.", C.RED)
    end
end

task.spawn(pingServer)

-- ── Mode switching ─────────────────────────────────────────
local function applyMode(m)
    MODE = m
    if m == "client" then
        tw(ClientTab, { BackgroundColor3 = C.ACCENT,    TextColor3 = C.WHITE    })
        tw(ServerTab, { BackgroundColor3 = C.DIM,       TextColor3 = C.DIM_TXT  })
        SubBar.Visible    = false
        HintLbl.Text      = "Client Side  →  loadstring(code)()  [runs on YOUR client]"
        CodeBox.PlaceholderText = "-- Local script (client-side loadstring)..."
        ExecBtn.BackgroundColor3 = C.ACCENT
    else
        tw(ServerTab, { BackgroundColor3 = C.SERVER_A,  TextColor3 = C.WHITE    })
        tw(ClientTab, { BackgroundColor3 = C.DIM,       TextColor3 = C.DIM_TXT  })
        SubBar.Visible    = true
        ExecBtn.BackgroundColor3 = C.SERVER_A
        -- Apply current sub-mode hint
        if SUB_MODE == "ls" then
            tw(SubLS,  { BackgroundColor3 = C.SERVER_A, TextColor3 = C.WHITE   })
            tw(SubReq, { BackgroundColor3 = C.DIM,      TextColor3 = C.DIM_TXT })
            HintLbl.Text = "Server Side  →  loadstring(code)()  [runs on SERVER]"
            CodeBox.PlaceholderText = "-- Server-side script (full permissions)..."
        else
            tw(SubReq, { BackgroundColor3 = C.SERVER_A, TextColor3 = C.WHITE   })
            tw(SubLS,  { BackgroundColor3 = C.DIM,      TextColor3 = C.DIM_TXT })
            HintLbl.Text = "Server Side  →  require(assetId)  [loads a module server-side]"
            CodeBox.PlaceholderText = "-- Enter numeric Asset ID, e.g. 12345678"
        end
    end
end

local function applySubMode(s)
    SUB_MODE = s
    applyMode("server")
end

applyMode("client")

ClientTab.MouseButton1Click:Connect(function() applyMode("client") end)
ServerTab.MouseButton1Click:Connect(function() applyMode("server") end)
SubLS.MouseButton1Click:Connect(function()    applySubMode("ls")  end)
SubReq.MouseButton1Click:Connect(function()   applySubMode("req") end)

-- ── Execute ────────────────────────────────────────────────
ExecBtn.MouseButton1Click:Connect(function()
    local code = CodeBox.Text
    if code == "" or code:match("^%s*$") then
        setStatus("Nothing to execute.", C.YELLOW)
        return
    end

    setStatus("Executing...", C.YELLOW)

    if MODE == "client" then
        -- Run locally on this client via loadstring
        local fn, compErr = loadstring(code)
        if not fn then
            setStatus("Compile error: " .. tostring(compErr):sub(1, 70), C.RED)
            return
        end
        local ok, runErr = pcall(fn)
        if ok then
            setStatus("Executed on client via loadstring.", C.GREEN)
        else
            setStatus("Runtime: " .. tostring(runErr):sub(1, 70), C.RED)
        end

    else
        -- Send to server
        if not serverOK then
            setStatus("Server not connected. Re-checking...", C.YELLOW)
            task.spawn(pingServer)
            return
        end

        local action  = SUB_MODE == "ls" and "ls" or "req"
        local payload = SUB_MODE == "ls"
            and { code = code }
            or  { id   = code }

        local ok, res = pcall(Bridge.InvokeServer, Bridge, action, payload)
        if not ok then
            setStatus("Remote error: " .. tostring(res):sub(1, 70), C.RED)
            return
        end
        if res and res.ok then
            setStatus(tostring(res.msg), C.GREEN)
        else
            setStatus(tostring(res and res.msg or "Unknown error"):sub(1, 70), C.RED)
        end
    end
end)

-- ── Clear ──────────────────────────────────────────────────
ClearBtn.MouseButton1Click:Connect(function()
    CodeBox.Text = ""
    setStatus("Editor cleared.", C.DIM_TXT)
end)

-- ── Copy to clipboard ──────────────────────────────────────
CopyBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(CodeBox.Text)
        setStatus("Copied to clipboard.", C.PURPLE)
    else
        setStatus("setclipboard not available in this executor.", C.YELLOW)
    end
end)

-- ── Minimize / Close ───────────────────────────────────────
local FULL_H = WIN_H

MinBtn.MouseButton1Click:Connect(function()
    minimised = not minimised
    if minimised then
        twS(Win, { Size = UDim2.new(0, WIN_W, 0, 40) })
        MinBtn.Text = "□"
    else
        twS(Win, { Size = UDim2.new(0, WIN_W, 0, FULL_H) })
        MinBtn.Text = "—"
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    twS(Win, { Size = UDim2.new(0, 0, 0, 0) })
    task.delay(0.25, function() SG:Destroy() end)
end)

-- ── Hover effects ──────────────────────────────────────────
local EXEC_NORMAL = C.ACCENT
local EXEC_HOV    = C.ACC_HOV
local function hookHover(btn, normal, hov)
    btn.MouseEnter:Connect(function() tw(btn, { BackgroundColor3 = hov   }) end)
    btn.MouseLeave:Connect(function() tw(btn, { BackgroundColor3 = normal }) end)
end

hookHover(ClearBtn, C.DIM, Color3.fromRGB(42, 42, 56))
hookHover(CopyBtn,  C.DIM, Color3.fromRGB(42, 42, 56))
hookHover(CloseBtn, Color3.fromRGB(200, 38, 55), Color3.fromRGB(230, 60, 75))
hookHover(MinBtn,   C.DIM, Color3.fromRGB(42, 42, 56))

ExecBtn.MouseEnter:Connect(function()
    tw(ExecBtn, { BackgroundColor3 = (MODE == "client" and C.ACC_HOV or C.SERVER_H) })
end)
ExecBtn.MouseLeave:Connect(function()
    tw(ExecBtn, { BackgroundColor3 = (MODE == "client" and C.ACCENT or C.SERVER_A) })
end)

-- ── Dragging  (mouse + touch) ──────────────────────────────
local dragging   = false
local dragStart  = nil
local winStart   = nil

TBar.InputBegan:Connect(function(inp)
    local t = inp.UserInputType
    if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
        dragging  = true
        dragStart = inp.Position
        winStart  = Win.Position
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
        local d = inp.Position - dragStart
        Win.Position = UDim2.new(
            winStart.X.Scale, winStart.X.Offset + d.X,
            winStart.Y.Scale, winStart.Y.Offset + d.Y
        )
    end
end)

UIS.InputEnded:Connect(function(inp)
    local t = inp.UserInputType
    if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
        dragging = false
    end
end)
