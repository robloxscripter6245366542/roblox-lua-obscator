-- ═══════════════════════════════════════════════════════════════════════
--  SPELLING BEE  —  NerdZone  |  Delta iOS/iPad + PC
--  No external HTTP — pure native Roblox GUI
-- ═══════════════════════════════════════════════════════════════════════

local function main()

-- ── Services ──────────────────────────────────────────────────────────
local Players     = game:GetService("Players")
local UIS         = game:GetService("UserInputService")
local RunService  = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local RS          = game:GetService("ReplicatedStorage")
local TW          = game:GetService("TweenService")
local StarterGui  = game:GetService("StarterGui")
local LP          = Players.LocalPlayer
local PGui        = LP:WaitForChild("PlayerGui")

local isMobile = UIS.TouchEnabled

pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "Spelling Bee  |  NerdZone",
        Text  = "Loading" .. (isMobile and " (iPad)..." or "..."),
        Duration = 3,
    })
end)

-- ── State ─────────────────────────────────────────────────────────────
local botEnabled   = true
local submitDelay  = 0.05
local delayMs      = 50
local currentWord  = ""
local answerRemote = nil
local antiAFK      = false
local infJump      = false
local walkSpd      = 16
local jumpPwr      = 50

-- ═══════════════════════════════════════════════════════════════════════
--  HOOK HELPERS
-- ═══════════════════════════════════════════════════════════════════════

local function looksLikeWord(s)
    return type(s) == "string" and #s >= 3 and #s <= 30 and s:match("^%a+$") ~= nil
end

local ANSWER_KEYS = {"submit","answer","spell","type","guess","check"}
local function isAnswerRemote(name)
    local n = name:lower()
    for _, k in ipairs(ANSWER_KEYS) do
        if n:find(k, 1, true) then return true end
    end
    return false
end

local function findAnswerRemote()
    if answerRemote and answerRemote.Parent then return answerRemote end
    answerRemote = nil
    for _, r in ipairs(RS:GetDescendants()) do
        if r:IsA("RemoteEvent") and isAnswerRemote(r.Name) then
            answerRemote = r; return r
        end
    end
end

local function fireAnswer(word)
    local r = findAnswerRemote()
    if r then pcall(function() r:FireServer(word) end); return true end
    return false
end

local function boxSubmit(word)
    for _, obj in ipairs(PGui:GetDescendants()) do
        if obj:IsA("TextBox") and obj.TextEditable and obj.Visible then
            obj.Text = word; obj:CaptureFocus(); task.wait(0.03); obj:ReleaseFocus(true)
            return true
        end
    end
    return false
end

local function submitAnswer(word)
    if word == "" then return end
    if not fireAnswer(word) then boxSubmit(word) end
end

local wordLblRef  -- UI label, set after GUI builds
local function onWordFound(w)
    w = w:lower()
    if w == currentWord then return end
    currentWord = w
    if wordLblRef then wordLblRef.Text = "Word:  " .. w end
    if botEnabled then task.delay(submitDelay, function() submitAnswer(w) end) end
end

-- ── Hook 1: OnClientEvent (deduplicated) ──────────────────────────────
local _hooked = {}
local function hookOne(remote)
    if _hooked[remote] then return end
    _hooked[remote] = true
    remote.OnClientEvent:Connect(function(...)
        for _, v in ipairs({...}) do
            if looksLikeWord(v) then onWordFound(v); return
            elseif type(v) == "table" then
                for _, tv in pairs(v) do
                    if looksLikeWord(tv) then onWordFound(tv); return end
                end
            end
        end
    end)
end
local function hookIncoming()
    for _, r in ipairs(RS:GetDescendants()) do
        if r:IsA("RemoteEvent") then hookOne(r) end
    end
end

-- ── Hook 2: __namecall ────────────────────────────────────────────────
local namecallHook
local hookStatusText = "Hook: partial (events only)"
local function installNamecallHook()
    if not hookmetamethod or not newcclosure or not getnamecallmethod then return false end
    local ok = pcall(function()
        namecallHook = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if (method == "FireServer" or method == "InvokeServer")
            and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction"))
            and isAnswerRemote(self.Name) then
                if self:IsA("RemoteEvent") and not answerRemote then answerRemote = self end
                if botEnabled and currentWord ~= "" then return namecallHook(self, currentWord) end
            end
            return namecallHook(self, ...)
        end))
    end)
    return ok
end

-- ── Hook 3: Screen label poll ─────────────────────────────────────────
local function findWordLabel()
    for _, name in ipairs({"Word","CurrentWord","SpellWord","WordToSpell","TargetWord","Prompt","Question"}) do
        local obj = PGui:FindFirstChild(name, true)
        if obj and obj:IsA("TextLabel") and obj.Visible and obj.Text ~= "" then return obj end
    end
    local best, bestLen = nil, -1
    for _, obj in ipairs(PGui:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Visible and obj.Text ~= "" then
            local t = obj.Text
            if t:match("^%a+$") and #t >= 3 and #t <= 30 and #t > bestLen then best = obj; bestLen = #t end
        end
    end
    return best
end

local function getHumanoid()
    local c = LP.Character; return c and c:FindFirstChildOfClass("Humanoid")
end

-- ═══════════════════════════════════════════════════════════════════════
--  NATIVE GUI  (no external library — works on Delta iOS)
-- ═══════════════════════════════════════════════════════════════════════

-- Remove any previous instance
local old = PGui:FindFirstChild("__SpellingBeeHub__")
if old then old:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name             = "__SpellingBeeHub__"
ScreenGui.ResetOnSpawn     = false
ScreenGui.IgnoreGuiInset   = true
ScreenGui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder     = 999
ScreenGui.Parent           = PGui

local WIN_W = isMobile and 310 or 320
local WIN_H = isMobile and 460 or 440

-- Main window frame
local WIN = Instance.new("Frame")
WIN.Name                = "Window"
WIN.Size                = UDim2.new(0, WIN_W, 0, WIN_H)
WIN.Position            = isMobile
    and UDim2.new(0.5, -WIN_W/2, 0, 60)
    or  UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2)
WIN.BackgroundColor3    = Color3.fromRGB(15, 15, 24)
WIN.BorderSizePixel     = 0
WIN.Active              = true
WIN.Parent              = ScreenGui
Instance.new("UICorner", WIN).CornerRadius = UDim.new(0, 12)

-- Drop stroke
local stroke = Instance.new("UIStroke", WIN)
stroke.Color      = Color3.fromRGB(60, 60, 100)
stroke.Thickness  = 1.5

-- Title bar
local TBAR = Instance.new("Frame")
TBAR.Size            = UDim2.new(1, 0, 0, 46)
TBAR.BackgroundColor3= Color3.fromRGB(25, 25, 40)
TBAR.BorderSizePixel = 0
TBAR.Parent          = WIN
local tc = Instance.new("UICorner", TBAR); tc.CornerRadius = UDim.new(0, 12)
-- fill bottom-rounded gap
local tfill = Instance.new("Frame", TBAR)
tfill.Size = UDim2.new(1,0,0,12); tfill.Position = UDim2.new(0,0,1,-12)
tfill.BackgroundColor3 = Color3.fromRGB(25,25,40); tfill.BorderSizePixel = 0

local titleTxt = Instance.new("TextLabel", TBAR)
titleTxt.Size = UDim2.new(1,-80,1,0); titleTxt.Position = UDim2.new(0,14,0,0)
titleTxt.BackgroundTransparency = 1
titleTxt.Text = "🐝  Spelling Bee  |  NerdZone"
titleTxt.TextColor3 = Color3.fromRGB(255,255,255)
titleTxt.Font = Enum.Font.GothamBold; titleTxt.TextSize = 14
titleTxt.TextXAlignment = Enum.TextXAlignment.Left

local btnClose = Instance.new("TextButton", TBAR)
btnClose.Size = UDim2.new(0,30,0,24); btnClose.Position = UDim2.new(1,-38,0,11)
btnClose.BackgroundColor3 = Color3.fromRGB(200,50,50)
btnClose.Text = "✕"; btnClose.TextColor3 = Color3.fromRGB(255,255,255)
btnClose.Font = Enum.Font.GothamBold; btnClose.TextSize = 13; btnClose.BorderSizePixel = 0
Instance.new("UICorner", btnClose).CornerRadius = UDim.new(0,6)
btnClose.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Drag (touch + mouse)
local _drag, _dragX, _dragY, _winX, _winY = false,0,0,0,0
TBAR.InputBegan:Connect(function(inp)
    local t = inp.UserInputType
    if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
        if _drag and t == Enum.UserInputType.Touch then return end
        _drag = true; _dragX = inp.Position.X; _dragY = inp.Position.Y
        _winX = WIN.AbsolutePosition.X; _winY = WIN.AbsolutePosition.Y
    end
end)
UIS.InputChanged:Connect(function(inp)
    if not _drag then return end
    local t = inp.UserInputType
    if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
        WIN.Position = UDim2.new(0, _winX + inp.Position.X - _dragX, 0, _winY + inp.Position.Y - _dragY)
    end
end)
UIS.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        _drag = false
    end
end)

-- Scrollable content
local SCROLL = Instance.new("ScrollingFrame", WIN)
SCROLL.Size = UDim2.new(1,-6,1,-52); SCROLL.Position = UDim2.new(0,3,0,49)
SCROLL.BackgroundTransparency = 1; SCROLL.BorderSizePixel = 0
SCROLL.ScrollBarThickness = 3; SCROLL.ScrollBarImageColor3 = Color3.fromRGB(80,80,140)
SCROLL.CanvasSize = UDim2.new(0,0,0,0); SCROLL.AutomaticCanvasSize = Enum.AutomaticSize.Y
local LIST = Instance.new("UIListLayout", SCROLL)
LIST.Padding = UDim.new(0,5); LIST.SortOrder = Enum.SortOrder.LayoutOrder
local pad = Instance.new("UIPadding", SCROLL); pad.PaddingTop = UDim.new(0,4)
pad.PaddingLeft = UDim.new(0,2); pad.PaddingRight = UDim.new(0,2)

-- ── UI component builders ─────────────────────────────────────────────
local function mkSection(txt)
    local f = Instance.new("Frame", SCROLL)
    f.Size = UDim2.new(1,0,0,22); f.BackgroundColor3 = Color3.fromRGB(35,35,58)
    f.BorderSizePixel = 0
    Instance.new("UICorner", f).CornerRadius = UDim.new(0,5)
    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(1,-8,1,0); l.Position = UDim2.new(0,8,0,0)
    l.BackgroundTransparency=1; l.Text=txt
    l.TextColor3=Color3.fromRGB(140,140,200); l.Font=Enum.Font.GothamBold
    l.TextSize=11; l.TextXAlignment=Enum.TextXAlignment.Left
    return f
end

local function mkLabel(txt, col)
    local f = Instance.new("Frame", SCROLL)
    f.Size = UDim2.new(1,0,0,30); f.BackgroundColor3 = Color3.fromRGB(22,22,36)
    f.BorderSizePixel = 0
    Instance.new("UICorner", f).CornerRadius = UDim.new(0,6)
    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(1,-10,1,0); l.Position = UDim2.new(0,10,0,0)
    l.BackgroundTransparency=1; l.Text=txt
    l.TextColor3= col or Color3.fromRGB(200,200,230)
    l.Font=Enum.Font.Gotham; l.TextSize=12; l.TextXAlignment=Enum.TextXAlignment.Left
    return l  -- return the TextLabel so caller can update .Text
end

local function mkToggle(txt, default, cb)
    local f = Instance.new("Frame", SCROLL)
    f.Size = UDim2.new(1,0,0,38); f.BackgroundColor3 = Color3.fromRGB(22,22,36)
    f.BorderSizePixel = 0
    Instance.new("UICorner", f).CornerRadius = UDim.new(0,6)
    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(1,-62,1,0); l.Position = UDim2.new(0,10,0,0)
    l.BackgroundTransparency=1; l.Text=txt
    l.TextColor3=Color3.fromRGB(210,210,235); l.Font=Enum.Font.Gotham
    l.TextSize=12; l.TextXAlignment=Enum.TextXAlignment.Left
    local state = default
    local pill = Instance.new("TextButton", f)
    pill.Size=UDim2.new(0,46,0,24); pill.Position=UDim2.new(1,-52,0.5,-12)
    pill.BackgroundColor3= state and Color3.fromRGB(70,200,110) or Color3.fromRGB(70,70,100)
    pill.Text=""; pill.BorderSizePixel=0
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1,0)
    local knob = Instance.new("Frame", pill)
    knob.Size=UDim2.new(0,18,0,18)
    knob.Position= state and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9)
    knob.BackgroundColor3=Color3.fromRGB(255,255,255); knob.BorderSizePixel=0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
    local ti = TweenInfo.new(0.15)
    pill.MouseButton1Click:Connect(function()
        state = not state
        TW:Create(pill,ti,{BackgroundColor3=state and Color3.fromRGB(70,200,110) or Color3.fromRGB(70,70,100)}):Play()
        TW:Create(knob,ti,{Position=state and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9)}):Play()
        cb(state)
    end)
end

local function mkButton(txt, col, cb)
    local btn = Instance.new("TextButton", SCROLL)
    btn.Size=UDim2.new(1,0,0,38)
    btn.BackgroundColor3= col or Color3.fromRGB(55,75,160)
    btn.Text=txt; btn.TextColor3=Color3.fromRGB(255,255,255)
    btn.Font=Enum.Font.GothamBold; btn.TextSize=13; btn.BorderSizePixel=0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    btn.MouseButton1Click:Connect(cb)
    return btn
end

local function mkStepper(txt, val, min, max, step, fmt, cb)
    local f = Instance.new("Frame", SCROLL)
    f.Size=UDim2.new(1,0,0,38); f.BackgroundColor3=Color3.fromRGB(22,22,36)
    f.BorderSizePixel=0
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,6)
    local lbl = Instance.new("TextLabel",f)
    lbl.Size=UDim2.new(0.55,0,1,0); lbl.Position=UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=fmt(val)
    lbl.TextColor3=Color3.fromRGB(210,210,235); lbl.Font=Enum.Font.Gotham
    lbl.TextSize=12; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local function mkSB(sign, xp)
        local b = Instance.new("TextButton",f)
        b.Size=UDim2.new(0,32,0,26); b.Position=xp
        b.BackgroundColor3=Color3.fromRGB(45,55,100); b.Text=sign
        b.TextColor3=Color3.fromRGB(255,255,255); b.Font=Enum.Font.GothamBold
        b.TextSize=16; b.BorderSizePixel=0
        Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
        b.MouseButton1Click:Connect(function()
            val = math.clamp(val + (sign=="-" and -step or step), min, max)
            lbl.Text = fmt(val); cb(val)
        end)
    end
    mkSB("-", UDim2.new(0.58,0,0.5,-13))
    mkSB("+", UDim2.new(0.78,0,0.5,-13))
end

-- ── Build UI ──────────────────────────────────────────────────────────
mkSection("📡  HOOK STATUS")
local hookLbl = mkLabel("Hook: connecting...", Color3.fromRGB(255,200,60))
local wordLbl = mkLabel("Word:  waiting...",   Color3.fromRGB(100,210,255))
mkLabel("Platform:  " .. (isMobile and "iPad / Mobile (Delta)" or "PC"), Color3.fromRGB(140,180,255))

wordLblRef = wordLbl  -- link to onWordFound

mkSection("🤖  AUTO SUBMIT")
mkToggle("Auto-Bot  (instant answer on word receive)", true, function(v) botEnabled = v end)
mkStepper("Submit Delay: ", delayMs, 0, 2000, 10, function(v) return "Submit Delay: "..v.."ms" end,
    function(v) submitDelay = v/1000 end)

mkSection("🔧  CONTROLS")
mkButton("▶  Submit Current Word Now", Color3.fromRGB(40,160,80), function()
    if currentWord == "" then return end
    submitAnswer(currentWord)
end)
mkButton("🔄  Re-scan Remotes", Color3.fromRGB(55,75,160), function()
    answerRemote = nil; hookIncoming()
    hookLbl.Text = "Hooks refreshed ✓"
    task.delay(2, function() hookLbl.Text = "Hook: ACTIVE" end)
end)

mkSection("🏃  PLAYER")
mkToggle("Infinite Jump", false, function(v) infJump = v end)
mkToggle("Anti-AFK",      false, function(v) antiAFK = v end)
mkStepper("Walk Speed: ", walkSpd, 1, 300, 5, function(v) return "Walk Speed: "..v end, function(v)
    walkSpd = v; local h = getHumanoid(); if h then pcall(function() h.WalkSpeed=v end) end
end)
mkStepper("Jump Power: ", jumpPwr, 1, 300, 5, function(v) return "Jump Power: "..v end, function(v)
    jumpPwr = v; local h = getHumanoid()
    if h then pcall(function() h.JumpPower=v; h.JumpHeight=v*0.36 end) end
end)
mkButton("💀  Reset Character", Color3.fromRGB(160,50,50), function()
    local h = getHumanoid(); if h then pcall(function() h.Health=0 end) end
end)

-- ═══════════════════════════════════════════════════════════════════════
--  INSTALL HOOKS — immediately
-- ═══════════════════════════════════════════════════════════════════════
hookIncoming()
local hook2ok = installNamecallHook()
if hook2ok then
    hookLbl.Text = "Hook: ACTIVE  (__namecall + events)"
    hookLbl.TextColor3 = Color3.fromRGB(80,220,120)
else
    hookLbl.Text = "Hook: partial  (events only)"
    hookLbl.TextColor3 = Color3.fromRGB(255,180,60)
end

RS.DescendantAdded:Connect(function(obj)
    if obj:IsA("RemoteEvent") then task.wait(); hookOne(obj) end
end)

-- ═══════════════════════════════════════════════════════════════════════
--  BACKGROUND LOOPS
-- ═══════════════════════════════════════════════════════════════════════
UIS.JumpRequest:Connect(function()
    if infJump then
        local h = getHumanoid()
        if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
    end
end)

local _afkTick = 0
RunService.Heartbeat:Connect(function()
    if antiAFK then
        _afkTick += 1
        if _afkTick >= 3600 then _afkTick = 0; pcall(function() VirtualUser:CaptureController() end) end
    end
end)

LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local h = char:FindFirstChildOfClass("Humanoid"); if not h then return end
    pcall(function() h.WalkSpeed=walkSpd; h.JumpPower=jumpPwr; h.JumpHeight=jumpPwr*0.36 end)
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        if botEnabled then
            local lbl = findWordLabel()
            if lbl then
                local w = lbl.Text:lower():match("^%s*(.-)%s*$")
                if w and looksLikeWord(w) then onWordFound(w) end
            end
        end
    end
end)

pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "Spelling Bee  |  NerdZone",
        Text  = "Ready  |  " .. (isMobile and "iPad" or "PC") .. "  |  Auto-Bot ON",
        Duration = 4,
    })
end)

end  -- main()

main()
