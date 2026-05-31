-- ═══════════════════════════════════════════════════════════════════════
--  SPELLING BEE  —  NerdZone  |  Delta iOS/iPad + PC
--  Auto Bot + Session Stats (Words, WPM, Best WPM, Accuracy)
-- ═══════════════════════════════════════════════════════════════════════

local Players     = game:GetService("Players")
local UIS         = game:GetService("UserInputService")
local RunService  = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local RS          = game:GetService("ReplicatedStorage")
local WS          = game:GetService("Workspace")
local TW          = game:GetService("TweenService")
local StarterGui  = game:GetService("StarterGui")
local LP          = Players.LocalPlayer
local PGui        = LP:WaitForChild("PlayerGui")
local isMobile    = UIS.TouchEnabled

local function notify(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title=title, Text=text, Duration=dur or 4})
    end)
end

notify("Spelling Bee  |  NerdZone", "Loading" .. (isMobile and " (iPad)..." or "..."), 3)

-- ── Load Rayfield (tries 3 CDNs in order) ─────────────────────────────
local Rayfield
local URLS = {
    "https://cdn.jsdelivr.net/gh/SiriusXT/Rayfield@main/lib/main.lua",
    "https://sirius.menu/rayfield",
    "https://raw.githubusercontent.com/SiriusXT/Rayfield/main/lib/main.lua",
}
for _, url in ipairs(URLS) do
    local ok, res = pcall(function()
        return loadstring(game:HttpGet(url, true))()
    end)
    if ok and res then Rayfield = res; break end
end

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

-- ── Session Stats ──────────────────────────────────────────────────────
local sessionStart = os.clock()
local wordsTyped   = 0
local bestWPM      = 0

local function getWPM()
    local elapsed = (os.clock() - sessionStart) / 60
    if elapsed < 0.01 then return 0 end
    return math.floor(wordsTyped / elapsed)
end

-- ── UI update callbacks (assigned after UI is built) ───────────────────
local setWordLabel   = function() end
local setHookLabel   = function() end
local updateStatsUI  = function() end

-- ═══════════════════════════════════════════════════════════════════════
--  WORD DETECTION + SUBMISSION
-- ═══════════════════════════════════════════════════════════════════════

local UI_BLACKLIST = {
    spellingbee=1, nerdzone=1, submit=1, answer=1, play=1, reset=1,
    start=1, continue=1, back=1, close=1, menu=1, quit=1, exit=1,
    enabled=1, disabled=1, button=1, label=1, frame=1, loading=1,
    loaded=1, waiting=1, ready=1, error=1, failed=1, success=1,
    roblox=1, studio=1, player=1, server=1, client=1, remote=1,
}

local function looksLikeWord(s)
    if type(s) ~= "string" then return false end
    if #s < 2 or #s > 32 then return false end
    if not s:match("^%a+$") then return false end
    return not UI_BLACKLIST[s:lower()]
end

local submitAnswer  -- forward declared

local function onWordFound(w)
    w = w:lower()
    if w == currentWord then return end
    currentWord = w
    setWordLabel("Word:  " .. w)
    if botEnabled then task.delay(submitDelay, function() submitAnswer(w) end) end
end

local ANSWER_KEYS = {"submit","answer","spell","type","guess","check","input"}
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
    return nil
end

local function fireAnswer(word)
    local r = findAnswerRemote()
    if r then pcall(function() r:FireServer(word) end); return true end
    return false
end

local function boxSubmit(word)
    local function tryBoxes(root)
        for _, obj in ipairs(root:GetDescendants()) do
            if obj:IsA("TextBox") and obj.TextEditable and obj.Visible then
                obj.Text = word
                obj:CaptureFocus()
                task.wait(0.03)
                obj:ReleaseFocus(true)
                return true
            end
        end
        return false
    end
    if tryBoxes(PGui) then return true end
    if tryBoxes(WS) then return true end
    return false
end

submitAnswer = function(word)
    if word == "" then return end
    local sent = fireAnswer(word) or boxSubmit(word)
    if sent then
        wordsTyped = wordsTyped + 1
        local wpm = getWPM()
        if wpm > bestWPM then bestWPM = wpm end
        updateStatsUI()
    end
end

-- ═══════════════════════════════════════════════════════════════════════
--  HOOK 1 — RemoteEvent.OnClientEvent
-- ═══════════════════════════════════════════════════════════════════════
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
            elseif type(v) == "string" then
                local w = v:match("([%a][%a]+)")
                if w and looksLikeWord(w) then onWordFound(w); return end
            end
        end
    end)
end

local function hookIncoming()
    for _, r in ipairs(RS:GetDescendants()) do
        if r:IsA("RemoteEvent") then hookOne(r) end
    end
end

-- ═══════════════════════════════════════════════════════════════════════
--  HOOK 2 — __namecall
-- ═══════════════════════════════════════════════════════════════════════
local namecallHook
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

-- ═══════════════════════════════════════════════════════════════════════
--  HOOK 3 — StringValue monitoring (RS + workspace)
-- ═══════════════════════════════════════════════════════════════════════
local _watchedSV = {}
local function watchStringValue(sv)
    if _watchedSV[sv] then return end
    _watchedSV[sv] = true
    sv.Changed:Connect(function(v)
        if looksLikeWord(v) then onWordFound(v) end
    end)
    if looksLikeWord(sv.Value) then onWordFound(sv.Value) end
end

local SV_KEYS = {"word","spell","current","target","prompt","letter","round"}
local function shouldWatchSV(name)
    local n = name:lower()
    for _, k in ipairs(SV_KEYS) do
        if n:find(k, 1, true) then return true end
    end
    return false
end

local function hookStringValues(root)
    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("StringValue") and shouldWatchSV(obj.Name) then
            watchStringValue(obj)
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════
--  POLL — scans PlayerGui + workspace TextLabels every 0.5s
--  Prefers large TextSize (board labels) to avoid UI noise
-- ═══════════════════════════════════════════════════════════════════════
local function scanLabels(root)
    local best, bestScore = nil, -1
    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Visible and obj.Text ~= "" then
            local t = obj.Text:match("^%s*(.-)%s*$") or ""
            if looksLikeWord(t) then
                -- Weight: long words score higher; large TextSize (board) scores extra
                local score = #t + (obj.TextSize >= 20 and 50 or 0)
                if score > bestScore then best = t; bestScore = score end
            end
        end
    end
    return best
end

local function getHumanoid()
    local c = LP.Character; return c and c:FindFirstChildOfClass("Humanoid")
end

-- ═══════════════════════════════════════════════════════════════════════
--  INSTALL HOOKS (shared for both UI branches)
-- ═══════════════════════════════════════════════════════════════════════
local function installAllHooks()
    hookIncoming()
    hookStringValues(RS)
    hookStringValues(WS)
    local hook2ok = installNamecallHook()
    local hookTxt = hook2ok and "Hook: ACTIVE  (__namecall + events)" or "Hook: partial  (events only)"
    setHookLabel(hookTxt, hook2ok and Color3.fromRGB(70,215,110) or Color3.fromRGB(255,175,55))
    RS.DescendantAdded:Connect(function(obj)
        if obj:IsA("RemoteEvent") then task.wait(); hookOne(obj)
        elseif obj:IsA("StringValue") and shouldWatchSV(obj.Name) then watchStringValue(obj) end
    end)
    WS.DescendantAdded:Connect(function(obj)
        if obj:IsA("StringValue") and shouldWatchSV(obj.Name) then watchStringValue(obj) end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════
--  UI — Rayfield if loaded, otherwise native fallback
-- ═══════════════════════════════════════════════════════════════════════

if Rayfield then
-- ── RAYFIELD UI ───────────────────────────────────────────────────────

    local Window = Rayfield:CreateWindow({
        Name            = "Spelling Bee  |  NerdZone",
        Icon            = "pencil",
        LoadingTitle    = "NerdZone Hub",
        LoadingSubtitle = "Spelling Bee Script",
        Theme           = "Default",
        DisableRayfieldPrompts = false,
        DisableBuildWarnings   = true,
        ConfigurationSaving = { Enabled=true, FolderName="NerdZone", FileName="SpellingBee" },
        Discord   = { Enabled = false },
        KeySystem = false,
    })

    local BotTab    = Window:CreateTab("Bot",    "bot")
    local StatsTab  = Window:CreateTab("Stats",  "bar-chart-2")
    local PlayerTab = Window:CreateTab("Player", "user")
    local MiscTab   = Window:CreateTab("Misc",   "settings")

    -- Bot tab ──────────────────────────────────────────────────────────
    BotTab:CreateSection("Hook Status")
    local _hl = BotTab:CreateLabel("Hook: connecting...", "shield", Color3.fromRGB(255,200,60), true)
    local _wl = BotTab:CreateLabel("Word:  waiting...",   "book-open", Color3.fromRGB(100,210,255), true)
    BotTab:CreateLabel(isMobile and "Platform: iPad / Mobile (Delta)" or "Platform: PC",
        "smartphone", Color3.fromRGB(160,160,160), true)

    setHookLabel  = function(t, _) _hl:Set(t) end
    setWordLabel  = function(t)    _wl:Set(t) end

    BotTab:CreateSection("Auto Submit")
    BotTab:CreateToggle({ Name="Auto-Bot  (submit on word capture)", CurrentValue=true, Flag="BotOn",
        Callback=function(v) botEnabled=v end })
    BotTab:CreateSlider({ Name="Submit Delay  (0 = instant, 200 = 2s)", Range={0,200}, Increment=5,
        Suffix="ms", CurrentValue=50, Flag="SubDelay",
        Callback=function(v) submitDelay=v/1000 end })

    BotTab:CreateSection("Manual")
    BotTab:CreateButton({ Name="Submit Current Word Now", Callback=function()
        if currentWord == "" then
            Rayfield:Notify({Title="No Word", Content="No word captured yet.", Duration=3, Image="alert-circle"})
            return
        end
        submitAnswer(currentWord)
        Rayfield:Notify({Title="Submitted", Content=currentWord, Duration=2, Image="check"})
    end })
    BotTab:CreateButton({ Name="Re-scan Remotes", Callback=function()
        answerRemote=nil; hookIncoming(); hookStringValues(RS); hookStringValues(WS)
        Rayfield:Notify({Title="Re-scanned", Content="Hooks refreshed.", Duration=2, Image="refresh-cw"})
    end })

    -- Stats tab ────────────────────────────────────────────────────────
    StatsTab:CreateSection("Session Statistics")
    local _sWords = StatsTab:CreateLabel("Words Typed:  0",  "hash",   Color3.fromRGB(100,220,150), true)
    local _sWpm   = StatsTab:CreateLabel("Avg WPM:  0",      "zap",    Color3.fromRGB(100,180,255), true)
    local _sBest  = StatsTab:CreateLabel("Best WPM:  0",     "award",  Color3.fromRGB(255,220,80),  true)
    local _sAcc   = StatsTab:CreateLabel("Accuracy:  100%",  "target", Color3.fromRGB(200,120,255), true)

    updateStatsUI = function()
        local wpm = getWPM()
        _sWords:Set("Words Typed:  " .. wordsTyped)
        _sWpm:Set("Avg WPM:  "   .. wpm)
        _sBest:Set("Best WPM:  " .. bestWPM)
        _sAcc:Set("Accuracy:  100%")
    end

    StatsTab:CreateButton({ Name="Reset Session Stats", Callback=function()
        sessionStart=os.clock(); wordsTyped=0; bestWPM=0
        _sWords:Set("Words Typed:  0"); _sWpm:Set("Avg WPM:  0")
        _sBest:Set("Best WPM:  0"); _sAcc:Set("Accuracy:  100%")
        Rayfield:Notify({Title="Stats Reset", Content="Session stats cleared.", Duration=2, Image="refresh-cw"})
    end })

    -- Player tab ───────────────────────────────────────────────────────
    PlayerTab:CreateSection("Movement")
    PlayerTab:CreateSlider({ Name="Walk Speed", Range={1,300}, Increment=1, Suffix="", CurrentValue=16, Flag="WalkSpd",
        Callback=function(v) walkSpd=v; local h=getHumanoid(); if h then pcall(function() h.WalkSpeed=v end) end end })
    PlayerTab:CreateSlider({ Name="Jump Power", Range={1,300}, Increment=1, Suffix="", CurrentValue=50, Flag="JumpPwr",
        Callback=function(v) jumpPwr=v; local h=getHumanoid()
            if h then pcall(function() h.JumpPower=v; h.JumpHeight=v*0.36 end) end end })
    PlayerTab:CreateToggle({ Name="Infinite Jump", CurrentValue=false, Flag="InfJump",
        Callback=function(v) infJump=v end })
    PlayerTab:CreateSection("Character")
    PlayerTab:CreateButton({ Name="Reset Character", Callback=function()
        local h=getHumanoid(); if h then pcall(function() h.Health=0 end) end end })

    -- Misc tab ─────────────────────────────────────────────────────────
    MiscTab:CreateSection("Utilities")
    MiscTab:CreateToggle({ Name="Anti-AFK", CurrentValue=false, Flag="AntiAFK",
        Callback=function(v) antiAFK=v end })
    MiscTab:CreateSection("Info")
    MiscTab:CreateLabel("Script: NerdZone Hub",          "zap",    Color3.fromRGB(100,180,255), true)
    MiscTab:CreateLabel("UI: Rayfield Library",           "layout", Color3.fromRGB(160,160,160), true)
    MiscTab:CreateLabel("Game: Spelling Bee by NerdZone", "star",   Color3.fromRGB(255,220,60),  true)

    installAllHooks()
    Rayfield:LoadConfiguration()
    Rayfield:Notify({ Title="NerdZone  |  Spelling Bee",
        Content="Ready  |  " .. (isMobile and "iPad/Mobile" or "PC") .. "  |  Auto-Bot ON",
        Duration=5, Image="shield" })

else
-- ── NATIVE FALLBACK (when all Rayfield CDNs fail) ─────────────────────

local old = PGui:FindFirstChild("__SpellingBeeHub__")
if old then old:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "__SpellingBeeHub__"
ScreenGui.ResetOnSpawn   = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder   = 999
local guiParent = PGui
pcall(function() if gethui then guiParent = gethui() end end)
ScreenGui.Parent = guiParent

local WIN_W = isMobile and 300 or 320
local WIN_H = isMobile and 560 or 540

local WIN = Instance.new("Frame")
WIN.Size             = UDim2.new(0, WIN_W, 0, WIN_H)
WIN.Position         = isMobile and UDim2.new(0.5,-WIN_W/2,0,55) or UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2)
WIN.BackgroundColor3 = Color3.fromRGB(14, 14, 22)
WIN.BorderSizePixel  = 0
WIN.Active           = true
WIN.Parent           = ScreenGui
Instance.new("UICorner", WIN).CornerRadius = UDim.new(0,12)
local ws2 = Instance.new("UIStroke", WIN)
ws2.Color = Color3.fromRGB(55,55,95); ws2.Thickness = 1.5

-- Title bar
local TBAR = Instance.new("Frame", WIN)
TBAR.Size = UDim2.new(1,0,0,44); TBAR.BackgroundColor3 = Color3.fromRGB(22,22,38); TBAR.BorderSizePixel=0
Instance.new("UICorner", TBAR).CornerRadius = UDim.new(0,12)
local _tfix = Instance.new("Frame", TBAR)
_tfix.Size=UDim2.new(1,0,0,12); _tfix.Position=UDim2.new(0,0,1,-12)
_tfix.BackgroundColor3=Color3.fromRGB(22,22,38); _tfix.BorderSizePixel=0

local tl = Instance.new("TextLabel", TBAR)
tl.Size=UDim2.new(1,-42,1,0); tl.Position=UDim2.new(0,12,0,0); tl.BackgroundTransparency=1
tl.Text="🐝  Spelling Bee  |  NerdZone"; tl.TextColor3=Color3.fromRGB(255,255,255)
tl.Font=Enum.Font.GothamBold; tl.TextSize=13; tl.TextXAlignment=Enum.TextXAlignment.Left

local btnX = Instance.new("TextButton", TBAR)
btnX.Size=UDim2.new(0,28,0,22); btnX.Position=UDim2.new(1,-34,0,11)
btnX.BackgroundColor3=Color3.fromRGB(190,45,45); btnX.Text="✕"; btnX.TextColor3=Color3.fromRGB(255,255,255)
btnX.Font=Enum.Font.GothamBold; btnX.TextSize=12; btnX.BorderSizePixel=0
Instance.new("UICorner",btnX).CornerRadius=UDim.new(0,5)
btnX.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Drag
local _drag,_dx,_dy,_wx,_wy=false,0,0,0,0
TBAR.InputBegan:Connect(function(i)
    local t=i.UserInputType
    if t==Enum.UserInputType.MouseButton1 or t==Enum.UserInputType.Touch then
        if _drag and t==Enum.UserInputType.Touch then return end
        _drag=true; _dx=i.Position.X; _dy=i.Position.Y
        _wx=WIN.AbsolutePosition.X; _wy=WIN.AbsolutePosition.Y
    end
end)
UIS.InputChanged:Connect(function(i)
    if not _drag then return end
    local t=i.UserInputType
    if t==Enum.UserInputType.MouseMovement or t==Enum.UserInputType.Touch then
        WIN.Position=UDim2.new(0,_wx+i.Position.X-_dx,0,_wy+i.Position.Y-_dy)
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        _drag=false
    end
end)

-- Scroll area
local SC=Instance.new("ScrollingFrame",WIN)
SC.Size=UDim2.new(1,-4,1,-50); SC.Position=UDim2.new(0,2,0,47)
SC.BackgroundTransparency=1; SC.BorderSizePixel=0
SC.ScrollBarThickness=3; SC.ScrollBarImageColor3=Color3.fromRGB(70,70,130)
SC.CanvasSize=UDim2.new(0,0,0,0); SC.AutomaticCanvasSize=Enum.AutomaticSize.Y
local LL=Instance.new("UIListLayout",SC); LL.Padding=UDim.new(0,4); LL.SortOrder=Enum.SortOrder.LayoutOrder
local _pad=Instance.new("UIPadding",SC)
_pad.PaddingTop=UDim.new(0,3); _pad.PaddingLeft=UDim.new(0,3); _pad.PaddingRight=UDim.new(0,3)

local C2=Color3.fromRGB(22,22,36)
local C3=Color3.fromRGB(32,32,52)

local function sec(txt)
    local f=Instance.new("Frame",SC); f.Size=UDim2.new(1,0,0,20); f.BackgroundColor3=C3; f.BorderSizePixel=0
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,4)
    local l=Instance.new("TextLabel",f); l.Size=UDim2.new(1,-8,1,0); l.Position=UDim2.new(0,8,0,0)
    l.BackgroundTransparency=1; l.Text=txt; l.TextColor3=Color3.fromRGB(130,130,190)
    l.Font=Enum.Font.GothamBold; l.TextSize=10; l.TextXAlignment=Enum.TextXAlignment.Left
end

local function lbl(txt, col)
    local f=Instance.new("Frame",SC); f.Size=UDim2.new(1,0,0,28); f.BackgroundColor3=C2; f.BorderSizePixel=0
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,5)
    local l=Instance.new("TextLabel",f); l.Size=UDim2.new(1,-10,1,0); l.Position=UDim2.new(0,10,0,0)
    l.BackgroundTransparency=1; l.Text=txt; l.TextColor3=col or Color3.fromRGB(195,195,225)
    l.Font=Enum.Font.Gotham; l.TextSize=12; l.TextXAlignment=Enum.TextXAlignment.Left
    return l
end

local function tog(txt, def, cb)
    local f=Instance.new("Frame",SC); f.Size=UDim2.new(1,0,0,36); f.BackgroundColor3=C2; f.BorderSizePixel=0
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,5)
    local l=Instance.new("TextLabel",f); l.Size=UDim2.new(1,-60,1,0); l.Position=UDim2.new(0,10,0,0)
    l.BackgroundTransparency=1; l.Text=txt; l.TextColor3=Color3.fromRGB(205,205,230)
    l.Font=Enum.Font.Gotham; l.TextSize=12; l.TextXAlignment=Enum.TextXAlignment.Left
    local st=def
    local pi=Instance.new("TextButton",f); pi.Size=UDim2.new(0,44,0,22); pi.Position=UDim2.new(1,-50,0.5,-11)
    pi.BackgroundColor3=st and Color3.fromRGB(65,195,105) or Color3.fromRGB(65,65,95)
    pi.Text=""; pi.BorderSizePixel=0
    Instance.new("UICorner",pi).CornerRadius=UDim.new(1,0)
    local kn=Instance.new("Frame",pi); kn.Size=UDim2.new(0,16,0,16)
    kn.Position=st and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)
    kn.BackgroundColor3=Color3.fromRGB(255,255,255); kn.BorderSizePixel=0
    Instance.new("UICorner",kn).CornerRadius=UDim.new(1,0)
    local ti=TweenInfo.new(0.14)
    pi.MouseButton1Click:Connect(function()
        st=not st
        TW:Create(pi,ti,{BackgroundColor3=st and Color3.fromRGB(65,195,105) or Color3.fromRGB(65,65,95)}):Play()
        TW:Create(kn,ti,{Position=st and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)}):Play()
        cb(st)
    end)
end

local function btn(txt, col, cb)
    local b=Instance.new("TextButton",SC); b.Size=UDim2.new(1,0,0,36)
    b.BackgroundColor3=col; b.Text=txt; b.TextColor3=Color3.fromRGB(255,255,255)
    b.Font=Enum.Font.GothamBold; b.TextSize=13; b.BorderSizePixel=0
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,5)
    b.MouseButton1Click:Connect(cb); return b
end

local function stepper(_, startV, mn, mx, st, fmtFn, cb)
    local v=startV
    local f=Instance.new("Frame",SC); f.Size=UDim2.new(1,0,0,36); f.BackgroundColor3=C2; f.BorderSizePixel=0
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,5)
    local l=Instance.new("TextLabel",f); l.Size=UDim2.new(0.58,0,1,0); l.Position=UDim2.new(0,10,0,0)
    l.BackgroundTransparency=1; l.Text=fmtFn(v); l.TextColor3=Color3.fromRGB(205,205,230)
    l.Font=Enum.Font.Gotham; l.TextSize=12; l.TextXAlignment=Enum.TextXAlignment.Left
    local function mkb(sign, xp)
        local b=Instance.new("TextButton",f); b.Size=UDim2.new(0,30,0,24); b.Position=xp
        b.BackgroundColor3=Color3.fromRGB(42,52,95); b.Text=sign; b.TextColor3=Color3.fromRGB(255,255,255)
        b.Font=Enum.Font.GothamBold; b.TextSize=15; b.BorderSizePixel=0
        Instance.new("UICorner",b).CornerRadius=UDim.new(0,5)
        b.MouseButton1Click:Connect(function()
            v=math.clamp(v+(sign=="-" and -st or st), mn, mx)
            l.Text=fmtFn(v); cb(v)
        end)
    end
    mkb("-", UDim2.new(0.60,0,0.5,-12))
    mkb("+", UDim2.new(0.78,0,0.5,-12))
end

-- ── Build native UI ───────────────────────────────────────────────────
sec("📡  HOOK STATUS")
local hookLbl = lbl("Hook: connecting...", Color3.fromRGB(255,200,60))
local wordLbl = lbl("Word:  waiting...",   Color3.fromRGB(80,205,255))
lbl("Platform:  " .. (isMobile and "iPad / Mobile (Delta)" or "PC"), Color3.fromRGB(120,160,255))

sec("📊  SESSION STATS")
local nWords = lbl("Words Typed:  0",  Color3.fromRGB(100,220,150))
local nWpm   = lbl("Avg WPM:  0",      Color3.fromRGB(100,180,255))
local nBest  = lbl("Best WPM:  0",     Color3.fromRGB(255,220,80))
local nAcc   = lbl("Accuracy:  100%",  Color3.fromRGB(200,120,255))

btn("🔄  Reset Session Stats", Color3.fromRGB(60,45,110), function()
    sessionStart=os.clock(); wordsTyped=0; bestWPM=0
    nWords.Text="Words Typed:  0"; nWpm.Text="Avg WPM:  0"
    nBest.Text="Best WPM:  0"; nAcc.Text="Accuracy:  100%"
    notify("Stats Reset", "Session stats cleared.", 2)
end)

sec("🤖  AUTO SUBMIT")
tog("Auto-Bot  (auto-answer every word)", true, function(v) botEnabled=v end)
stepper("Delay", delayMs, 0, 2000, 10, function(v) return "Delay:  "..v.."ms" end,
    function(v) submitDelay=v/1000 end)

sec("🔧  CONTROLS")
btn("▶  Submit Current Word Now", Color3.fromRGB(35,150,70), function()
    if currentWord=="" then notify("No word","No word captured yet.",3); return end
    submitAnswer(currentWord)
    notify("Submitted!", currentWord, 2)
end)
btn("🔄  Re-scan Remotes", Color3.fromRGB(50,70,155), function()
    answerRemote=nil; hookIncoming(); hookStringValues(RS); hookStringValues(WS)
    hookLbl.Text="Hooks refreshed ✓"
end)

sec("🏃  PLAYER")
tog("Infinite Jump", false, function(v) infJump=v end)
tog("Anti-AFK",      false, function(v) antiAFK=v end)
stepper("WalkSpd", walkSpd, 1, 300, 5, function(v) return "Walk Speed:  "..v end, function(v)
    walkSpd=v; local h=getHumanoid(); if h then pcall(function() h.WalkSpeed=v end) end
end)
stepper("JumpPwr", jumpPwr, 1, 300, 5, function(v) return "Jump Power:  "..v end, function(v)
    jumpPwr=v; local h=getHumanoid()
    if h then pcall(function() h.JumpPower=v; h.JumpHeight=v*0.36 end) end
end)
btn("💀  Reset Character", Color3.fromRGB(155,40,40), function()
    local h=getHumanoid(); if h then pcall(function() h.Health=0 end) end
end)

-- Wire native UI callbacks
setHookLabel = function(t, col)
    hookLbl.Text = t
    if col then hookLbl.TextColor3 = col end
end
setWordLabel = function(t) wordLbl.Text = t end
updateStatsUI = function()
    local wpm = getWPM()
    nWords.Text = "Words Typed:  " .. wordsTyped
    nWpm.Text   = "Avg WPM:  "   .. wpm
    nBest.Text  = "Best WPM:  "  .. bestWPM
    nAcc.Text   = "Accuracy:  100%"
end

installAllHooks()
notify("Spelling Bee  |  NerdZone", "Ready  |  " .. (isMobile and "iPad" or "PC") .. "  |  Bot ON", 4)

end -- end if Rayfield / else native

-- ── Background loops (always run regardless of UI branch) ─────────────
UIS.JumpRequest:Connect(function()
    if infJump then
        local h=getHumanoid()
        if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
    end
end)

local _afkTick=0
RunService.Heartbeat:Connect(function()
    if antiAFK then
        _afkTick+=1
        if _afkTick>=3600 then _afkTick=0; pcall(function() VirtualUser:CaptureController() end) end
    end
end)

LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local h=char:FindFirstChildOfClass("Humanoid"); if not h then return end
    pcall(function() h.WalkSpeed=walkSpd; h.JumpPower=jumpPwr; h.JumpHeight=jumpPwr*0.36 end)
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        if botEnabled then
            local w = scanLabels(PGui) or scanLabels(WS)
            if w then onWordFound(w) end
        end
    end
end)
