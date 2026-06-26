-- ╔══════════════════════════════════════════════════════════════╗
-- ║         🔥 SIRI ROAST GENERATOR  v1.0  |  LocalScript       ║
-- ║         Press "Generate Roast" for the best Siri burns       ║
-- ╚══════════════════════════════════════════════════════════════╝

local Players    = game:GetService("Players")
local UIS        = game:GetService("UserInputService")
local TweenSvc   = game:GetService("TweenService")

local LP   = Players.LocalPlayer
local PGui = LP:WaitForChild("PlayerGui", 10)

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
    "I thought I had seen it all. Then I met you. I still hadn't seen enough to find a single interesting thing.",
    "You're proof that even nature makes mistakes.",
    "Your future called. It hung up.",
    "Keep rolling your eyes — maybe you'll find a brain back there.",
    "I'd give you a nasty look, but you've already got one.",
    "You're not even worth the calories it takes to talk to you.",
    "I'm not saying you're old, but your birth certificate is written in Latin.",
    "If stupidity was currency, you'd be a billionaire.",
    "I'm glad I roast people — otherwise I'd have nothing to say to you.",
    "You're the reason we have warning labels.",
    "You're so slow, it takes you an hour to watch 60 Minutes.",
    "Some day you'll go far — and I really hope you stay there.",
    "The only way you'll ever get laid is if you crawl up a chicken's backside and wait.",
    "I've met rocks with better ideas.",
    "Calling you an idiot would be an insult to idiots everywhere.",
}

-- ── Colour palette ────────────────────────────────────────────────────────────
local C = {
    BG     = Color3.fromRGB(10,  10, 16),
    PANEL  = Color3.fromRGB(18,  18, 26),
    CARD   = Color3.fromRGB(24,  24, 36),
    BORDER = Color3.fromRGB(50,  50, 75),
    ACCENT = Color3.fromRGB(255, 80,  80),
    ACC2   = Color3.fromRGB(255,140,  60),
    WHITE  = Color3.fromRGB(240, 240, 255),
    TEXT   = Color3.fromRGB(200, 200, 220),
    MUTED  = Color3.fromRGB( 90,  90, 120),
    BTN    = Color3.fromRGB(200,  40,  40),
    BTNHOV = Color3.fromRGB(230,  60,  60),
}

local TF = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function tw(obj, props)
    TweenSvc:Create(obj, TF, props):Play()
end

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
end

local function stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or C.BORDER
    s.Thickness = thickness or 1
    s.Parent = parent
end

-- ── Build GUI ─────────────────────────────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name            = "RoastGeneratorGUI"
sg.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
sg.ResetOnSpawn    = false
sg.Parent          = PGui

-- Main window
local win = Instance.new("Frame")
win.Name            = "Window"
win.Size            = UDim2.new(0, 420, 0, 340)
win.Position        = UDim2.new(0.5, -210, 0.5, -170)
win.BackgroundColor3 = C.BG
win.BorderSizePixel  = 0
win.Parent           = sg
corner(win, 12)
stroke(win, C.BORDER, 1.5)

-- Gradient overlay at top
local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 10, 10)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 16)),
})
grad.Rotation = 90
grad.Parent = win

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Name              = "TitleBar"
titleBar.Size              = UDim2.new(1, 0, 0, 48)
titleBar.BackgroundColor3  = Color3.fromRGB(16, 8, 8)
titleBar.BorderSizePixel   = 0
titleBar.ZIndex            = 2
titleBar.Parent            = win
corner(titleBar, 12)

-- Patch bottom corners of title bar
local patch = Instance.new("Frame")
patch.Size              = UDim2.new(1, 0, 0, 12)
patch.Position          = UDim2.new(0, 0, 1, -12)
patch.BackgroundColor3  = Color3.fromRGB(16, 8, 8)
patch.BorderSizePixel   = 0
patch.ZIndex            = 2
patch.Parent            = titleBar

-- Fire emoji + title
local titleLbl = Instance.new("TextLabel")
titleLbl.Text              = "🔥  Siri Roast Generator"
titleLbl.Size              = UDim2.new(1, -60, 1, 0)
titleLbl.Position          = UDim2.new(0, 16, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Font              = Enum.Font.GothamBold
titleLbl.TextSize          = 17
titleLbl.TextColor3        = C.WHITE
titleLbl.TextXAlignment    = Enum.TextXAlignment.Left
titleLbl.ZIndex            = 3
titleLbl.Parent            = titleBar

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Text              = "✕"
closeBtn.Size              = UDim2.new(0, 30, 0, 30)
closeBtn.Position          = UDim2.new(1, -38, 0.5, -15)
closeBtn.BackgroundColor3  = Color3.fromRGB(50, 20, 20)
closeBtn.Font              = Enum.Font.GothamBold
closeBtn.TextSize          = 14
closeBtn.TextColor3        = C.ACCENT
closeBtn.ZIndex            = 4
closeBtn.Parent            = titleBar
corner(closeBtn, 6)

closeBtn.MouseButton1Click:Connect(function()
    sg:Destroy()
end)

-- Subtitle
local subtitle = Instance.new("TextLabel")
subtitle.Text              = "Click below for the most savage Siri burns 🔥"
subtitle.Size              = UDim2.new(1, -32, 0, 24)
subtitle.Position          = UDim2.new(0, 16, 0, 58)
subtitle.BackgroundTransparency = 1
subtitle.Font              = Enum.Font.Gotham
subtitle.TextSize          = 13
subtitle.TextColor3        = C.MUTED
subtitle.TextXAlignment    = Enum.TextXAlignment.Left
subtitle.Parent            = win

-- Roast display card
local card = Instance.new("Frame")
card.Name              = "RoastCard"
card.Size              = UDim2.new(1, -32, 0, 160)
card.Position          = UDim2.new(0, 16, 0, 92)
card.BackgroundColor3  = C.CARD
card.BorderSizePixel   = 0
card.Parent            = win
corner(card, 10)
stroke(card, C.BORDER, 1)

-- Quote icon
local quoteLbl = Instance.new("TextLabel")
quoteLbl.Text              = "\""
quoteLbl.Size              = UDim2.new(0, 40, 0, 50)
quoteLbl.Position          = UDim2.new(0, 8, 0, -8)
quoteLbl.BackgroundTransparency = 1
quoteLbl.Font              = Enum.Font.GothamBold
quoteLbl.TextSize          = 60
quoteLbl.TextColor3        = C.ACCENT
quoteLbl.TextTransparency  = 0.6
quoteLbl.ZIndex            = 2
quoteLbl.Parent            = card

-- Roast text
local roastLbl = Instance.new("TextLabel")
roastLbl.Name              = "RoastText"
roastLbl.Text              = "Press  \" Generate Roast \"  to get started..."
roastLbl.Size              = UDim2.new(1, -28, 1, -20)
roastLbl.Position          = UDim2.new(0, 14, 0, 14)
roastLbl.BackgroundTransparency = 1
roastLbl.Font              = Enum.Font.GothamSemibold
roastLbl.TextSize          = 15
roastLbl.TextColor3        = C.TEXT
roastLbl.TextWrapped       = true
roastLbl.TextXAlignment    = Enum.TextXAlignment.Left
roastLbl.TextYAlignment    = Enum.TextYAlignment.Top
roastLbl.ZIndex            = 3
roastLbl.Parent            = card

-- Siri credit label
local siriLbl = Instance.new("TextLabel")
siriLbl.Text              = "— Siri  🍎"
siriLbl.Size              = UDim2.new(1, -16, 0, 20)
siriLbl.Position          = UDim2.new(0, 8, 1, -24)
siriLbl.BackgroundTransparency = 1
siriLbl.Font              = Enum.Font.GothamBold
siriLbl.TextSize          = 12
siriLbl.TextColor3        = C.ACCENT
siriLbl.TextXAlignment    = Enum.TextXAlignment.Right
siriLbl.ZIndex            = 3
siriLbl.Parent            = card

-- Roast count label
local countLbl = Instance.new("TextLabel")
countLbl.Name              = "CountLabel"
countLbl.Text              = #ROASTS .. " roasts loaded"
countLbl.Size              = UDim2.new(1, -32, 0, 18)
countLbl.Position          = UDim2.new(0, 16, 0, 260)
countLbl.BackgroundTransparency = 1
countLbl.Font              = Enum.Font.Gotham
countLbl.TextSize          = 11
countLbl.TextColor3        = C.MUTED
countLbl.TextXAlignment    = Enum.TextXAlignment.Left
countLbl.Parent            = win

-- Generate button
local genBtn = Instance.new("TextButton")
genBtn.Name               = "GenerateBtn"
genBtn.Text               = "🔥  Generate Roast"
genBtn.Size               = UDim2.new(1, -32, 0, 46)
genBtn.Position           = UDim2.new(0, 16, 0, 282)
genBtn.BackgroundColor3   = C.BTN
genBtn.Font               = Enum.Font.GothamBold
genBtn.TextSize           = 16
genBtn.TextColor3         = C.WHITE
genBtn.AutoButtonColor    = false
genBtn.Parent             = win
corner(genBtn, 10)

-- Gradient on button
local btnGrad = Instance.new("UIGradient")
btnGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(230, 50, 50)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 80, 20)),
})
btnGrad.Rotation = 90
btnGrad.Parent = genBtn

-- Button hover/click effects
genBtn.MouseEnter:Connect(function()
    tw(genBtn, { BackgroundColor3 = C.BTNHOV })
end)
genBtn.MouseLeave:Connect(function()
    tw(genBtn, { BackgroundColor3 = C.BTN })
end)

-- ── Roast logic ───────────────────────────────────────────────────────────────
local lastIndex  = 0
local roastCount = 0

local function pickRoast()
    local idx
    repeat
        idx = math.random(1, #ROASTS)
    until idx ~= lastIndex
    lastIndex = idx
    return ROASTS[idx]
end

genBtn.MouseButton1Click:Connect(function()
    roastCount += 1
    local roast = pickRoast()

    -- flash card red briefly
    tw(card, { BackgroundColor3 = Color3.fromRGB(50, 16, 16) })
    task.delay(0.25, function()
        tw(card, { BackgroundColor3 = C.CARD })
    end)

    -- animate text fade
    tw(roastLbl, { TextTransparency = 1 })
    task.delay(0.15, function()
        roastLbl.Text = roast
        tw(roastLbl, { TextTransparency = 0 })
    end)

    countLbl.Text = string.format("Roast #%d of %d  🔥", roastCount, #ROASTS)
end)

-- ── Drag logic ────────────────────────────────────────────────────────────────
local dragging, dragStart, startPos

titleBar.InputBegan:Connect(function(inp)
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
end)

UIS.InputChanged:Connect(function(inp)
    if dragging and (
        inp.UserInputType == Enum.UserInputType.MouseMovement or
        inp.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = inp.Position - dragStart
        win.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- ── Notification ──────────────────────────────────────────────────────────────
pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title    = "🔥 Roast Generator",
        Text     = "Siri Roast Generator loaded! Press the button!",
        Duration = 4,
    })
end)
