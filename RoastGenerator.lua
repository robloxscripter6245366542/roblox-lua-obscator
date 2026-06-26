-- ╔══════════════════════════════════════════════════════════════╗
-- ║      🍎  SIRI ROAST GENERATOR  v2.0  |  LocalScript         ║
-- ║      Hey Siri — say something mean  🔊                       ║
-- ╚══════════════════════════════════════════════════════════════╝

local Players    = game:GetService("Players")
local UIS        = game:GetService("UserInputService")
local TweenSvc   = game:GetService("TweenService")
local RunSvc     = game:GetService("RunService")

local LP   = Players.LocalPlayer
local PGui = LP:WaitForChild("PlayerGui", 10)
local Cam  = game:GetService("Workspace").CurrentCamera

if PGui:FindFirstChild("RoastGeneratorGUI") then
    PGui.RoastGeneratorGUI:Destroy()
end

-- ── Siri roasts ───────────────────────────────────────────────────────────────
local ROASTS = {
    "I'd roast you, but my mom says I'm not allowed to burn trash.",
    "You're the reason shampoo has instructions.",
    "I'd explain it to you, but I left my crayons at home.",
    "Somewhere out there a tree is working very hard to make oxygen for you. You owe it an apology.",
    "You're not stupid — you just have bad luck thinking.",
    "I'd call you a tool, but tools are actually useful.",
    "If your brain was dynamite, there wouldn't be enough to blow your hat off.",
    "You bring everyone so much joy — when you leave the room.",
    "I'm not saying you're dumb, but the trash took itself out because it saw you coming.",
    "You're like a cloud. When you disappear, it's a beautiful day.",
    "I'd roast you harder, but I don't want to overwhelm what's left of your processing power.",
    "You are living proof that evolution can go in reverse.",
    "If I had a dollar for every smart thing you said, I'd be bankrupt.",
    "There are two things in this world I truly hate: lists, irony, and you.",
    "You're the human equivalent of a participation trophy.",
    "I told a joke about you today — don't worry, no one laughed.",
    "Error 404: Intelligence not found.",
    "You're so dense, light bends around you.",
    "I've seen better brains in a zombie movie.",
    "Your WiFi password is probably your personality — nonexistent.",
    "You must have been born on a highway. That's where most accidents happen.",
    "I asked Siri what two plus two was. She said 'not you'.",
    "You're like a software update. Every time I see you, I think 'not now'.",
    "Roses are red, violets are blue, I have five fingers and the middle one's for you.",
    "You're the type of person that makes people glad they have a mute button.",
    "I thought I had seen it all. Then I met you. Still not impressed.",
    "You're proof that even nature makes mistakes.",
    "Your future called. It hung up.",
    "Keep rolling your eyes — maybe you'll find a brain back there.",
    "I'd give you a nasty look, but you've already got one.",
    "You're not even worth the calories it takes to talk to you.",
    "I'm not saying you're old, but your birth certificate is in Latin.",
    "If stupidity was currency, you'd be a billionaire.",
    "I'm glad I roast people — otherwise I'd have nothing to say to you.",
    "You're the reason we have warning labels.",
    "You're so slow, it takes you an hour to watch 60 Minutes.",
    "Some day you'll go far — and I really hope you stay there.",
    "I've met rocks with better ideas.",
    "Calling you an idiot would be an insult to idiots everywhere.",
    "Even Google can't find a reason to like you.",
}

-- ── Siri colour palette ───────────────────────────────────────────────────────
local C = {
    BG      = Color3.fromRGB(  8,   8,  18),
    PANEL   = Color3.fromRGB( 14,  14,  28),
    CARD    = Color3.fromRGB( 18,  18,  36),
    BORDER  = Color3.fromRGB( 38,  38,  80),
    BLUE    = Color3.fromRGB( 10, 132, 255),   -- iOS blue
    PURPLE  = Color3.fromRGB(175,  82, 222),   -- iOS purple
    TEAL    = Color3.fromRGB( 48, 209, 138),   -- Siri teal
    CYAN    = Color3.fromRGB( 90, 200, 250),   -- Siri wave colour
    WHITE   = Color3.fromRGB(242, 242, 247),   -- iOS label
    TEXT    = Color3.fromRGB(200, 200, 225),
    MUTED   = Color3.fromRGB( 88,  88, 128),
    COPY    = Color3.fromRGB( 22,  22,  42),
    COPYHOV = Color3.fromRGB( 30,  30,  58),
}

local TF  = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TFS = TweenInfo.new(0.30, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function tw(obj, props)  TweenSvc:Create(obj, TF,  props):Play() end
local function tws(obj, props) TweenSvc:Create(obj, TFS, props):Play() end

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = p
end

local function stroke(p, col, thick)
    local s = Instance.new("UIStroke")
    s.Color     = col   or C.BORDER
    s.Thickness = thick or 1
    s.Parent    = p
end

-- ── Responsive sizing ─────────────────────────────────────────────────────────
local vp    = Cam.ViewportSize
local WIN_W = math.min(420, vp.X - 24)
local WIN_H = 390
local WIN_X = math.floor((vp.X - WIN_W) / 2)
local WIN_Y = math.floor((vp.Y - WIN_H) / 2)

-- ── Build ScreenGui ───────────────────────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name           = "RoastGeneratorGUI"
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.ResetOnSpawn   = false
sg.Parent         = PGui

-- ── Main window ───────────────────────────────────────────────────────────────
local win = Instance.new("Frame")
win.Name             = "Window"
win.Size             = UDim2.new(0, WIN_W, 0, WIN_H)
win.Position         = UDim2.new(0, WIN_X, 0, WIN_Y)
win.BackgroundColor3 = C.BG
win.BorderSizePixel  = 0
win.Parent           = sg
corner(win, 14)
stroke(win, C.BORDER, 1.5)

-- Siri-wave gradient on window
local winGrad = Instance.new("UIGradient")
winGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(12, 10, 30)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB( 8,  8, 20)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(10, 14, 26)),
})
winGrad.Rotation = 135
winGrad.Parent   = win

-- ── Title bar ─────────────────────────────────────────────────────────────────
local titleBar = Instance.new("Frame")
titleBar.Name             = "TitleBar"
titleBar.Size             = UDim2.new(1, 0, 0, 52)
titleBar.BackgroundColor3 = C.BG
titleBar.BorderSizePixel  = 0
titleBar.ZIndex           = 2
titleBar.Parent           = win
corner(titleBar, 14)

-- Siri gradient on title bar
local tbGrad = Instance.new("UIGradient")
tbGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,    Color3.fromRGB( 10, 132, 255)),  -- Siri blue
    ColorSequenceKeypoint.new(0.45, Color3.fromRGB(175,  82, 222)),  -- Siri purple
    ColorSequenceKeypoint.new(1,    Color3.fromRGB( 48, 209, 138)),  -- Siri teal
})
tbGrad.Rotation = 90
tbGrad.Parent   = titleBar

-- Patch bottom rounded corners of title bar
local tbPatch = Instance.new("Frame")
tbPatch.Size             = UDim2.new(1, 0, 0, 14)
tbPatch.Position         = UDim2.new(0, 0, 1, -14)
tbPatch.BackgroundColor3 = Color3.fromRGB(10, 8, 28)
tbPatch.BorderSizePixel  = 0
tbPatch.ZIndex           = 2
tbPatch.Parent           = titleBar

-- Apple logo + title
local titleLbl = Instance.new("TextLabel")
titleLbl.Text              = "🍎  Hey Siri — Roast Generator"
titleLbl.Size              = UDim2.new(1, -56, 1, 0)
titleLbl.Position          = UDim2.new(0, 14, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Font              = Enum.Font.GothamBold
titleLbl.TextSize          = 16
titleLbl.TextColor3        = C.WHITE
titleLbl.TextXAlignment    = Enum.TextXAlignment.Left
titleLbl.ZIndex            = 3
titleLbl.TextStrokeColor3  = Color3.fromRGB(0, 0, 0)
titleLbl.TextStrokeTransparency = 0.6
titleLbl.Parent            = titleBar

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Text             = "✕"
closeBtn.Size             = UDim2.new(0, 32, 0, 32)
closeBtn.Position         = UDim2.new(1, -42, 0.5, -16)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 59, 48)
closeBtn.Font             = Enum.Font.GothamBold
closeBtn.TextSize         = 13
closeBtn.TextColor3       = C.WHITE
closeBtn.AutoButtonColor  = false
closeBtn.ZIndex           = 4
closeBtn.Parent           = titleBar
corner(closeBtn, 16)

closeBtn.MouseEnter:Connect(function()
    tw(closeBtn, { BackgroundColor3 = Color3.fromRGB(255, 80, 70) })
end)
closeBtn.MouseLeave:Connect(function()
    tw(closeBtn, { BackgroundColor3 = Color3.fromRGB(255, 59, 48) })
end)
closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

-- Siri wave decoration bar
local waveBar = Instance.new("Frame")
waveBar.Size             = UDim2.new(1, 0, 0, 3)
waveBar.Position         = UDim2.new(0, 0, 0, 52)
waveBar.BackgroundColor3 = C.BG
waveBar.BorderSizePixel  = 0
waveBar.Parent           = win
local waveGrad = Instance.new("UIGradient")
waveGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,    C.BLUE),
    ColorSequenceKeypoint.new(0.33, C.PURPLE),
    ColorSequenceKeypoint.new(0.66, C.CYAN),
    ColorSequenceKeypoint.new(1,    C.TEAL),
})
waveGrad.Rotation = 0
waveGrad.Parent   = waveBar

-- Subtitle
local subtitle = Instance.new("TextLabel")
subtitle.Text              = "Powered by Siri  •  " .. #ROASTS .. " roasts loaded"
subtitle.Size              = UDim2.new(1, -28, 0, 22)
subtitle.Position          = UDim2.new(0, 14, 0, 62)
subtitle.BackgroundTransparency = 1
subtitle.Font              = Enum.Font.Gotham
subtitle.TextSize          = 12
subtitle.TextColor3        = C.MUTED
subtitle.TextXAlignment    = Enum.TextXAlignment.Left
subtitle.Parent            = win

-- ── Roast card ────────────────────────────────────────────────────────────────
local card = Instance.new("Frame")
card.Name             = "RoastCard"
card.Size             = UDim2.new(1, -28, 0, 164)
card.Position         = UDim2.new(0, 14, 0, 90)
card.BackgroundColor3 = C.CARD
card.BorderSizePixel  = 0
card.Parent           = win
corner(card, 12)
stroke(card, C.BORDER, 1)

-- Subtle card gradient
local cardGrad = Instance.new("UIGradient")
cardGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 20, 46)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 16, 32)),
})
cardGrad.Rotation = 135
cardGrad.Parent   = card

-- Accent bar on left edge of card
local accentBar = Instance.new("Frame")
accentBar.Size             = UDim2.new(0, 3, 1, -20)
accentBar.Position         = UDim2.new(0, 0, 0, 10)
accentBar.BackgroundColor3 = C.BLUE
accentBar.BorderSizePixel  = 0
accentBar.Parent           = card
corner(accentBar, 2)
local accentGrad = Instance.new("UIGradient")
accentGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   C.BLUE),
    ColorSequenceKeypoint.new(0.5, C.PURPLE),
    ColorSequenceKeypoint.new(1,   C.TEAL),
})
accentGrad.Rotation = 90
accentGrad.Parent   = accentBar

-- Quote mark
local quoteLbl = Instance.new("TextLabel")
quoteLbl.Text              = "\u{201C}"
quoteLbl.Size              = UDim2.new(0, 36, 0, 44)
quoteLbl.Position          = UDim2.new(0, 10, 0, -4)
quoteLbl.BackgroundTransparency = 1
quoteLbl.Font              = Enum.Font.GothamBold
quoteLbl.TextSize          = 52
quoteLbl.TextColor3        = C.BLUE
quoteLbl.TextTransparency  = 0.45
quoteLbl.ZIndex            = 2
quoteLbl.Parent            = card

-- Roast text
local roastLbl = Instance.new("TextLabel")
roastLbl.Name              = "RoastText"
roastLbl.Text              = "Press  \" Generate Roast \"  below..."
roastLbl.Size              = UDim2.new(1, -30, 1, -30)
roastLbl.Position          = UDim2.new(0, 16, 0, 14)
roastLbl.BackgroundTransparency = 1
roastLbl.Font              = Enum.Font.GothamSemibold
roastLbl.TextSize          = 15
roastLbl.TextColor3        = C.TEXT
roastLbl.TextWrapped       = true
roastLbl.TextXAlignment    = Enum.TextXAlignment.Left
roastLbl.TextYAlignment    = Enum.TextYAlignment.Top
roastLbl.ZIndex            = 3
roastLbl.Parent            = card

-- Siri credit
local siriCredit = Instance.new("TextLabel")
siriCredit.Text            = "— Siri  🍎"
siriCredit.Size            = UDim2.new(1, -16, 0, 18)
siriCredit.Position        = UDim2.new(0, 8, 1, -22)
siriCredit.BackgroundTransparency = 1
siriCredit.Font            = Enum.Font.GothamBold
siriCredit.TextSize        = 11
siriCredit.TextColor3      = C.PURPLE
siriCredit.TextXAlignment  = Enum.TextXAlignment.Right
siriCredit.ZIndex          = 3
siriCredit.Parent          = card

-- ── Copy bar ──────────────────────────────────────────────────────────────────
local copyBar = Instance.new("TextButton")
copyBar.Name              = "CopyBar"
copyBar.Text              = "📋  Copy Roast"
copyBar.Size              = UDim2.new(1, -28, 0, 36)
copyBar.Position          = UDim2.new(0, 14, 0, 262)
copyBar.BackgroundColor3  = C.COPY
copyBar.Font              = Enum.Font.GothamSemibold
copyBar.TextSize          = 13
copyBar.TextColor3        = C.MUTED
copyBar.AutoButtonColor   = false
copyBar.Parent            = win
corner(copyBar, 8)
stroke(copyBar, C.BORDER, 1)

copyBar.MouseEnter:Connect(function()
    tw(copyBar, { BackgroundColor3 = C.COPYHOV, TextColor3 = C.TEXT })
end)
copyBar.MouseLeave:Connect(function()
    tw(copyBar, { BackgroundColor3 = C.COPY, TextColor3 = C.MUTED })
end)

-- ── Count label ───────────────────────────────────────────────────────────────
local countLbl = Instance.new("TextLabel")
countLbl.Name              = "CountLabel"
countLbl.Text              = "Tap Generate to start"
countLbl.Size              = UDim2.new(1, -28, 0, 18)
countLbl.Position          = UDim2.new(0, 14, 0, 304)
countLbl.BackgroundTransparency = 1
countLbl.Font              = Enum.Font.Gotham
countLbl.TextSize          = 11
countLbl.TextColor3        = C.MUTED
countLbl.TextXAlignment    = Enum.TextXAlignment.Left
countLbl.Parent            = win

-- ── Generate button ───────────────────────────────────────────────────────────
local genBtn = Instance.new("TextButton")
genBtn.Name              = "GenerateBtn"
genBtn.Text              = "🔊  Generate Roast"
genBtn.Size              = UDim2.new(1, -28, 0, 48)
genBtn.Position          = UDim2.new(0, 14, 0, 326)
genBtn.BackgroundColor3  = C.BLUE
genBtn.Font              = Enum.Font.GothamBold
genBtn.TextSize          = 16
genBtn.TextColor3        = C.WHITE
genBtn.AutoButtonColor   = false
genBtn.Parent            = win
corner(genBtn, 12)

-- Siri gradient on generate button (blue → purple)
local genGrad = Instance.new("UIGradient")
genGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,    Color3.fromRGB( 10, 132, 255)),
    ColorSequenceKeypoint.new(0.55, Color3.fromRGB(100,  80, 240)),
    ColorSequenceKeypoint.new(1,    Color3.fromRGB(175,  82, 222)),
})
genGrad.Rotation = 90
genGrad.Parent   = genBtn

genBtn.MouseEnter:Connect(function()
    tw(genBtn, { BackgroundColor3 = Color3.fromRGB(30, 155, 255) })
end)
genBtn.MouseLeave:Connect(function()
    tw(genBtn, { BackgroundColor3 = C.BLUE })
end)

-- ── Roast logic ───────────────────────────────────────────────────────────────
local lastIndex  = 0
local roastCount = 0

local function pickRoast()
    local idx
    repeat idx = math.random(1, #ROASTS) until idx ~= lastIndex
    lastIndex = idx
    return ROASTS[idx]
end

genBtn.MouseButton1Click:Connect(function()
    roastCount += 1
    local roast = pickRoast()

    -- Siri pulse flash on card
    tws(card, { BackgroundColor3 = Color3.fromRGB(14, 18, 50) })
    task.delay(0.3, function()
        tws(card, { BackgroundColor3 = C.CARD })
    end)

    -- Fade text out → swap → fade in
    tw(roastLbl, { TextTransparency = 1 })
    task.delay(0.15, function()
        roastLbl.Text = roast
        tw(roastLbl, { TextTransparency = 0 })
    end)

    countLbl.Text      = string.format("Roast #%d of %d", roastCount, #ROASTS)
    copyBar.Text       = "📋  Copy Roast"
    copyBar.TextColor3 = C.MUTED
end)

-- ── Copy logic ────────────────────────────────────────────────────────────────
copyBar.MouseButton1Click:Connect(function()
    local text = roastLbl.Text
    if text == "Press  \" Generate Roast \"  below..." then return end

    local ok = pcall(function() setclipboard(text) end)
    if not ok then
        pcall(function()
            local tb = Instance.new("TextBox")
            tb.Text   = text
            tb.Parent = sg
            tb:CaptureFocus()
            tb:ReleaseFocus(false)
            tb:Destroy()
        end)
    end

    copyBar.Text       = "✅  Copied to clipboard!"
    copyBar.TextColor3 = C.TEAL
    task.delay(2.5, function()
        copyBar.Text       = "📋  Copy Roast"
        copyBar.TextColor3 = C.MUTED
    end)
end)

-- ── Drag / touch logic ────────────────────────────────────────────────────────
local dragging, dragStart, startPos

local function onDragBegan(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        dragging  = true
        dragStart = inp.Position
        startPos  = win.Position
        inp.Changed:Connect(function()
            if inp.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end

titleBar.InputBegan:Connect(onDragBegan)

UIS.InputChanged:Connect(function(inp)
    if not dragging then return end
    if inp.UserInputType ~= Enum.UserInputType.MouseMovement
    and inp.UserInputType ~= Enum.UserInputType.Touch then return end

    local delta = inp.Position - dragStart
    local vp2   = Cam.ViewportSize

    -- clamp so the window stays on-screen
    local newX = math.clamp(startPos.X.Offset + delta.X, 0, vp2.X - WIN_W)
    local newY = math.clamp(startPos.Y.Offset + delta.Y, 0, vp2.Y - WIN_H)

    win.Position = UDim2.new(0, newX, 0, newY)
end)

-- ── Notification ──────────────────────────────────────────────────────────────
pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title    = "🍎 Siri Roast Generator",
        Text     = "Hey Siri — tap Generate Roast!",
        Duration = 4,
    })
end)
