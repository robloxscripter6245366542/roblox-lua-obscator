-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║  CLYDE HUB  v1.0  — AI Assistant + Script Loader + Tools            ║
-- ║  Executor: Delta (iPad/iOS) + all PC executors                       ║
-- ║  AI: Google Gemini (free) via request()                              ║
-- ╚══════════════════════════════════════════════════════════════════════╝

local ok, err = pcall(function()

local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")
local TS      = game:GetService("TweenService")
local HS      = game:GetService("HttpService")
local RS      = game:GetService("RunService")
local LP      = Players.LocalPlayer
local PGui    = LP:WaitForChild("PlayerGui", 15)
if not PGui then warn("[Clyde] No PlayerGui"); return end

local old = PGui:FindFirstChild("__ClydeHub__")
if old then old:Destroy() end

local function notify(t, m, d)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification",
            {Title=t, Text=m, Duration=d or 3})
    end)
end

-- ── request() detection (works on Delta iOS) ──────────────────────────────────
local reqFn = (type(request)=="function" and request)
           or (type(syn)=="table" and type(syn.request)=="function" and syn.request)
           or (type(http)=="table" and type(http.request)=="function" and http.request)
           or nil

-- ── Saved settings (API key) ──────────────────────────────────────────────────
local CFG_FILE = "ClydeHub_cfg.json"
local cfg = {apiKey = "", aiName = "Clyde", model = "gemini"}
pcall(function()
    if readfile then
        local raw = readfile(CFG_FILE)
        local dec = HS:JSONDecode(raw)
        for k, v in pairs(dec) do cfg[k] = v end
    end
end)
local function saveCfg()
    pcall(function() if writefile then writefile(CFG_FILE, HS:JSONEncode(cfg)) end end)
end

-- ══════════════════════════════════════════════════════════════════════════════
--  THEME
-- ══════════════════════════════════════════════════════════════════════════════
local C = {
    BG      = Color3.fromRGB(10,  12,  18),
    CARD    = Color3.fromRGB(18,  21,  30),
    CARD2   = Color3.fromRGB(26,  29,  42),
    SIDE    = Color3.fromRGB(14,  16,  24),
    BORDER  = Color3.fromRGB(45,  50,  70),
    ACC1    = Color3.fromRGB(100, 60, 230),
    ACC2    = Color3.fromRGB(55, 130, 255),
    ACC3    = Color3.fromRGB(40, 210, 150),
    YEL     = Color3.fromRGB(255, 200, 50),
    RED     = Color3.fromRGB(235, 65,  65),
    GRN     = Color3.fromRGB(60,  210, 110),
    TX      = Color3.fromRGB(230, 232, 245),
    TX2     = Color3.fromRGB(160, 165, 195),
    TX3     = Color3.fromRGB(100, 108, 145),
    WHITE   = Color3.fromRGB(255, 255, 255),
    USER    = Color3.fromRGB(26,  50,  80),
    AI      = Color3.fromRGB(26,  22,  50),
}

local TF_FAST   = TweenInfo.new(0.15, Enum.EasingStyle.Quad,   Enum.EasingDirection.Out)
local TF_MED    = TweenInfo.new(0.25, Enum.EasingStyle.Quart,  Enum.EasingDirection.Out)
local TF_SLOW   = TweenInfo.new(0.40, Enum.EasingStyle.Quint,  Enum.EasingDirection.Out)
local TF_SPRING = TweenInfo.new(0.35, Enum.EasingStyle.Back,   Enum.EasingDirection.Out)

local function tw(obj, props, info)
    TS:Create(obj, info or TF_MED, props):Play()
end

-- ══════════════════════════════════════════════════════════════════════════════
--  UI HELPERS
-- ══════════════════════════════════════════════════════════════════════════════
local function corner(obj, r)
    local c = Instance.new("UICorner", obj); c.CornerRadius = UDim.new(0, r or 8)
end
local function stroke(obj, col, th)
    local s = Instance.new("UIStroke", obj); s.Color = col or C.BORDER; s.Thickness = th or 1
end
local function pad(obj, t, b, l, r)
    local p = Instance.new("UIPadding", obj)
    p.PaddingTop=UDim.new(0,t or 8); p.PaddingBottom=UDim.new(0,b or 8)
    p.PaddingLeft=UDim.new(0,l or 10); p.PaddingRight=UDim.new(0,r or 10)
end
local function listV(obj, sp)
    local l = Instance.new("UIListLayout", obj)
    l.FillDirection=Enum.FillDirection.Vertical
    l.HorizontalAlignment=Enum.HorizontalAlignment.Left
    l.SortOrder=Enum.SortOrder.LayoutOrder
    l.Padding=UDim.new(0, sp or 6)
    return l
end
local function grad(obj, c1, c2, rot)
    local g = Instance.new("UIGradient", obj)
    g.Color = ColorSequence.new(c1, c2); g.Rotation = rot or 90
end
local function autoSize(frame, ll)
    ll = ll or frame:FindFirstChildOfClass("UIListLayout")
    if not ll then return end
    local function update() frame.Size = UDim2.new(1, 0, 0, ll.AbsoluteContentSize.Y + 14) end
    ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update); update()
end

-- ══════════════════════════════════════════════════════════════════════════════
--  SCREEN / WINDOW
-- ══════════════════════════════════════════════════════════════════════════════
local SCR = Instance.new("ScreenGui", PGui)
SCR.Name = "__ClydeHub__"; SCR.ResetOnSpawn = false; SCR.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SCR.IgnoreGuiInset = true

local SHADOW = Instance.new("Frame", SCR)
SHADOW.Size = UDim2.new(0, 380, 0, 548); SHADOW.Position = UDim2.new(0.5, -194, 0.5, -270)
SHADOW.BackgroundColor3 = Color3.new(0,0,0); SHADOW.BackgroundTransparency = 0.45
SHADOW.BorderSizePixel = 0; corner(SHADOW, 14)

local WIN = Instance.new("Frame", SCR)
WIN.Name = "WIN"; WIN.Size = UDim2.new(0, 376, 0, 544); WIN.Position = UDim2.new(0.5, -188, 0.5, -272)
WIN.BackgroundColor3 = C.BG; WIN.BorderSizePixel = 0; corner(WIN, 12)
stroke(WIN, C.BORDER, 1)
WIN.ClipsDescendants = true

-- Title bar
local TBAR = Instance.new("Frame", WIN)
TBAR.Size = UDim2.new(1, 0, 0, 46); TBAR.BackgroundColor3 = C.SIDE; TBAR.BorderSizePixel = 0
grad(TBAR, C.SIDE, C.BG, 180)

local TLOGO = Instance.new("TextLabel", TBAR)
TLOGO.Size = UDim2.new(1, -100, 1, 0); TLOGO.Position = UDim2.new(0, 14, 0, 0)
TLOGO.BackgroundTransparency = 1; TLOGO.Text = "✦ Clyde Hub"; TLOGO.TextColor3 = C.TX
TLOGO.Font = Enum.Font.GothamBold; TLOGO.TextSize = 16; TLOGO.TextXAlignment = Enum.TextXAlignment.Left

local TSUB = Instance.new("TextLabel", TBAR)
TSUB.Size = UDim2.new(0, 160, 1, 0); TSUB.Position = UDim2.new(1, -170, 0, 0)
TSUB.BackgroundTransparency = 1; TSUB.Text = "v1.0  ·  AI + Scripts"
TSUB.TextColor3 = C.TX3; TSUB.Font = Enum.Font.Gotham; TSUB.TextSize = 10
TSUB.TextXAlignment = Enum.TextXAlignment.Right

local MINBTN = Instance.new("TextButton", TBAR)
MINBTN.Size = UDim2.new(0, 18, 0, 18); MINBTN.Position = UDim2.new(1, -26, 0.5, -9)
MINBTN.BackgroundColor3 = C.YEL; MINBTN.Text = ""; MINBTN.BorderSizePixel = 0; corner(MINBTN, 9)

local CLOSEBTN = Instance.new("TextButton", TBAR)
CLOSEBTN.Size = UDim2.new(0, 18, 0, 18); CLOSEBTN.Position = UDim2.new(1, -48, 0.5, -9)
CLOSEBTN.BackgroundColor3 = C.RED; CLOSEBTN.Text = ""; CLOSEBTN.BorderSizePixel = 0; corner(CLOSEBTN, 9)

-- Sidebar
local SIDE = Instance.new("Frame", WIN)
SIDE.Size = UDim2.new(0, 88, 1, -46); SIDE.Position = UDim2.new(0, 0, 0, 46)
SIDE.BackgroundColor3 = C.SIDE; SIDE.BorderSizePixel = 0
stroke(SIDE, C.BORDER, 1)

local SIDE_LL = Instance.new("UIListLayout", SIDE)
SIDE_LL.FillDirection = Enum.FillDirection.Vertical
SIDE_LL.HorizontalAlignment = Enum.HorizontalAlignment.Center
SIDE_LL.Padding = UDim.new(0, 4)
pad(SIDE, 8, 8, 6, 6)

-- Content area
local BODY = Instance.new("Frame", WIN)
BODY.Size = UDim2.new(1, -90, 1, -46); BODY.Position = UDim2.new(0, 90, 0, 46)
BODY.BackgroundTransparency = 1; BODY.BorderSizePixel = 0; BODY.ClipsDescendants = true

-- ══════════════════════════════════════════════════════════════════════════════
--  TAB SYSTEM
-- ══════════════════════════════════════════════════════════════════════════════
local tabBtns  = {}
local tabPages = {}
local activeTab = nil

local TAB_DATA = {
    {id="ai",      icon="🤖", label="AI"},
    {id="scripts", icon="📜", label="Scripts"},
    {id="tools",   icon="🔧", label="Tools"},
    {id="settings",icon="⚙",  label="Settings"},
}

local function newPage()
    local scr = Instance.new("ScrollingFrame", BODY)
    scr.Size = UDim2.new(1, 0, 1, 0); scr.Position = UDim2.new(0,0,0,0)
    scr.BackgroundTransparency = 1; scr.BorderSizePixel = 0
    scr.ScrollBarThickness = 3; scr.ScrollBarImageColor3 = C.ACC1
    scr.CanvasSize = UDim2.new(0,0,0,0); scr.Visible = false; scr.AutomaticCanvasSize = Enum.AutomaticSize.Y
    pad(scr, 10, 10, 10, 8)
    local ll = listV(scr, 7)
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    return scr
end

for _, td in ipairs(TAB_DATA) do
    -- Page
    local page = newPage()
    tabPages[td.id] = page

    -- Sidebar button
    local btn = Instance.new("TextButton", SIDE)
    btn.Size = UDim2.new(1, 0, 0, 58); btn.BackgroundColor3 = C.CARD2
    btn.BorderSizePixel = 0; btn.Text = ""; corner(btn, 8)

    local ic = Instance.new("TextLabel", btn)
    ic.Size = UDim2.new(1, 0, 0, 26); ic.Position = UDim2.new(0, 0, 0, 8)
    ic.BackgroundTransparency = 1; ic.Text = td.icon
    ic.Font = Enum.Font.GothamBold; ic.TextSize = 20
    ic.TextXAlignment = Enum.TextXAlignment.Center; ic.TextColor3 = C.TX3

    local lbl = Instance.new("TextLabel", btn)
    lbl.Size = UDim2.new(1, 0, 0, 14); lbl.Position = UDim2.new(0, 0, 0, 36)
    lbl.BackgroundTransparency = 1; lbl.Text = td.label
    lbl.Font = Enum.Font.Gotham; lbl.TextSize = 9.5
    lbl.TextXAlignment = Enum.TextXAlignment.Center; lbl.TextColor3 = C.TX3

    tabBtns[td.id] = {btn=btn, ic=ic, lbl=lbl}

    btn.MouseButton1Click:Connect(function()
        if activeTab == td.id then return end
        -- Deactivate old
        if activeTab then
            tabPages[activeTab].Visible = false
            local old2 = tabBtns[activeTab]
            tw(old2.btn, {BackgroundColor3=C.CARD2})
            tw(old2.ic,  {TextColor3=C.TX3}); tw(old2.lbl, {TextColor3=C.TX3})
        end
        -- Activate new
        activeTab = td.id
        tabPages[td.id].Visible = true
        tw(btn, {BackgroundColor3=C.ACC1}, TF_SPRING)
        tw(ic,  {TextColor3=C.WHITE}); tw(lbl, {TextColor3=C.WHITE})
    end)
end

local function showTab(id)
    local btn2 = tabBtns[id]; if not btn2 then return end
    btn2.btn.MouseButton1Click:Fire()
end

-- ══════════════════════════════════════════════════════════════════════════════
--  UI COMPONENTS
-- ══════════════════════════════════════════════════════════════════════════════
local loCount = 0
local function nextLo() loCount=loCount+1; return loCount end

local function secHeader(parent, title)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, 0, 0, 20); f.BackgroundTransparency = 1
    f.LayoutOrder = nextLo()
    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(1, 0, 1, 0); l.BackgroundTransparency = 1
    l.Text = title:upper(); l.TextColor3 = C.TX3
    l.Font = Enum.Font.GothamBold; l.TextSize = 9.5
    l.TextXAlignment = Enum.TextXAlignment.Left
    local d = Instance.new("Frame", f)
    d.Size = UDim2.new(1, 0, 0, 1); d.Position = UDim2.new(0, 0, 1, -1)
    d.BackgroundColor3 = C.BORDER; d.BorderSizePixel = 0
end

local function addButton(parent, title, desc, col, cb)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, 0, 0, 52); f.BackgroundColor3 = C.CARD
    f.BorderSizePixel = 0; corner(f, 8); f.LayoutOrder = nextLo(); stroke(f, C.BORDER)
    local t = Instance.new("TextLabel", f)
    t.Size = UDim2.new(1, -80, 0, 18); t.Position = UDim2.new(0, 12, 0, 9)
    t.BackgroundTransparency = 1; t.Text = title
    t.TextColor3 = C.TX; t.Font = Enum.Font.GothamSemibold; t.TextSize = 12
    t.TextXAlignment = Enum.TextXAlignment.Left
    if desc and desc ~= "" then
        local d = Instance.new("TextLabel", f)
        d.Size = UDim2.new(1, -16, 0, 12); d.Position = UDim2.new(0, 12, 0, 29)
        d.BackgroundTransparency = 1; d.Text = desc
        d.TextColor3 = C.TX3; d.Font = Enum.Font.Gotham; d.TextSize = 9.5
        d.TextXAlignment = Enum.TextXAlignment.Left
    end
    local btn = Instance.new("TextButton", f)
    btn.Size = UDim2.new(0, 60, 0, 24); btn.Position = UDim2.new(1, -70, 0.5, -12)
    btn.BackgroundColor3 = col or C.ACC1; btn.Text = "Run"; btn.TextColor3 = C.WHITE
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 10.5; btn.BorderSizePixel = 0; corner(btn, 6)
    btn.MouseButton1Click:Connect(function()
        tw(btn, {BackgroundColor3=C.WHITE}, TF_FAST)
        task.delay(0.15, function() tw(btn, {BackgroundColor3=col or C.ACC1}) end)
        task.spawn(cb)
    end)
    return f
end

local function addToggle(parent, title, desc, default, cb)
    local on = default or false
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, 0, 0, 52); f.BackgroundColor3 = C.CARD
    f.BorderSizePixel = 0; corner(f, 8); f.LayoutOrder = nextLo(); stroke(f, C.BORDER)
    local t = Instance.new("TextLabel", f)
    t.Size = UDim2.new(1, -64, 0, 18); t.Position = UDim2.new(0, 12, 0, 9)
    t.BackgroundTransparency = 1; t.Text = title
    t.TextColor3 = C.TX; t.Font = Enum.Font.GothamSemibold; t.TextSize = 12
    t.TextXAlignment = Enum.TextXAlignment.Left
    if desc and desc ~= "" then
        local d = Instance.new("TextLabel", f)
        d.Size = UDim2.new(1, -16, 0, 12); d.Position = UDim2.new(0, 12, 0, 29)
        d.BackgroundTransparency = 1; d.Text = desc
        d.TextColor3 = C.TX3; d.Font = Enum.Font.Gotham; d.TextSize = 9.5
        d.TextXAlignment = Enum.TextXAlignment.Left
    end
    -- pill toggle
    local pill = Instance.new("Frame", f)
    pill.Size = UDim2.new(0, 38, 0, 20); pill.Position = UDim2.new(1, -50, 0.5, -10)
    pill.BackgroundColor3 = on and C.ACC1 or C.CARD2
    pill.BorderSizePixel = 0; corner(pill, 10); stroke(pill, C.BORDER)
    local knob = Instance.new("Frame", pill)
    knob.Size = UDim2.new(0, 14, 0, 14); knob.Position = UDim2.new(0, on and 21 or 3, 0.5, -7)
    knob.BackgroundColor3 = C.WHITE; knob.BorderSizePixel = 0; corner(knob, 7)
    local htBtn = Instance.new("TextButton", f)
    htBtn.Size = UDim2.new(1, 0, 1, 0); htBtn.BackgroundTransparency = 1; htBtn.Text = ""
    htBtn.MouseButton1Click:Connect(function()
        on = not on
        tw(pill, {BackgroundColor3=on and C.ACC1 or C.CARD2})
        tw(knob, {Position=UDim2.new(0, on and 21 or 3, 0.5, -7)})
        task.spawn(cb, on)
    end)
end

local function addInfo(parent, text, col)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, 0, 0, 32); f.BackgroundColor3 = C.CARD2
    f.BorderSizePixel = 0; corner(f, 6); f.LayoutOrder = nextLo()
    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(1, -12, 1, 0); l.Position = UDim2.new(0, 10, 0, 0)
    l.BackgroundTransparency = 1; l.Text = text
    l.TextColor3 = col or C.TX2; l.Font = Enum.Font.Gotham; l.TextSize = 10.5
    l.TextXAlignment = Enum.TextXAlignment.Left; l.TextWrapped = true
end

-- ══════════════════════════════════════════════════════════════════════════════
--  TAB: AI CHAT
-- ══════════════════════════════════════════════════════════════════════════════
do
    local P = tabPages["ai"]

    -- Replace P with a non-scrolling Frame for AI tab layout
    P.AutomaticCanvasSize = Enum.AutomaticSize.None
    P.CanvasSize = UDim2.new(0,0,0,0)

    secHeader(P, "AI ASSISTANT  (" .. (reqFn and "request() ready" or "request() not found") .. ")")

    -- Chat history area
    local chatOuter = Instance.new("Frame", P)
    chatOuter.Size = UDim2.new(1, 0, 1, -98)
    chatOuter.BackgroundColor3 = C.CARD; chatOuter.BorderSizePixel = 0
    corner(chatOuter, 8); stroke(chatOuter, C.BORDER)
    chatOuter.LayoutOrder = nextLo(); chatOuter.ClipsDescendants = true

    local chatScroll = Instance.new("ScrollingFrame", chatOuter)
    chatScroll.Size = UDim2.new(1, 0, 1, 0); chatScroll.BackgroundTransparency = 1
    chatScroll.BorderSizePixel = 0; chatScroll.ScrollBarThickness = 3
    chatScroll.ScrollBarImageColor3 = C.ACC1
    chatScroll.CanvasSize = UDim2.new(0,0,0,0); chatScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    pad(chatScroll, 8, 8, 8, 8)
    local chatLL = listV(chatScroll, 6)
    chatLL.SortOrder = Enum.SortOrder.LayoutOrder

    -- Welcome bubble
    local function addBubble(text, isUser)
        local bub = Instance.new("Frame", chatScroll)
        bub.BackgroundColor3 = isUser and C.USER or C.AI
        bub.BorderSizePixel = 0; corner(bub, 10)
        bub.Size = UDim2.new(0.88, 0, 0, 10)
        bub.LayoutOrder = nextLo()
        if isUser then
            bub.AnchorPoint = Vector2.new(1, 0)
            bub.Position = UDim2.new(1, 0, 0, 0)
        else
            bub.AnchorPoint = Vector2.new(0, 0)
            bub.Position = UDim2.new(0, 0, 0, 0)
        end
        stroke(bub, isUser and Color3.fromRGB(60,90,140) or Color3.fromRGB(70,50,120), 1)

        local lbl = Instance.new("TextLabel", bub)
        lbl.Size = UDim2.new(1, -14, 1, -10)
        lbl.Position = UDim2.new(0, 7, 0, 5)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = C.TX; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 11
        lbl.TextWrapped = true; lbl.RichText = false
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.AutomaticSize = Enum.AutomaticSize.Y

        -- Auto-resize bubble to fit text
        task.defer(function()
            local function resize()
                bub.Size = UDim2.new(0.88, 0, 0, lbl.AbsoluteSize.Y + 14)
            end
            lbl:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize); resize()
        end)

        -- Scroll to bottom
        task.defer(function()
            chatScroll.CanvasPosition = Vector2.new(0, chatScroll.AbsoluteCanvasSize.Y)
        end)
        return lbl
    end

    addBubble("Hi! I'm Clyde, your AI assistant. Type a question below and press Send.\n\nAdd your Gemini API key in the Settings tab for best results.", false)

    -- Input area
    local inputRow = Instance.new("Frame", P)
    inputRow.Size = UDim2.new(1, 0, 0, 80); inputRow.BackgroundTransparency = 1
    inputRow.LayoutOrder = nextLo()

    local inputBox = Instance.new("TextBox", inputRow)
    inputBox.Size = UDim2.new(1, -68, 1, -10); inputBox.Position = UDim2.new(0, 0, 0, 5)
    inputBox.BackgroundColor3 = C.CARD2; inputBox.BorderSizePixel = 0
    inputBox.TextColor3 = C.TX; inputBox.Font = Enum.Font.Gotham; inputBox.TextSize = 11
    inputBox.PlaceholderText = "Ask anything..."; inputBox.PlaceholderColor3 = C.TX3
    inputBox.Text = ""; inputBox.MultiLine = true; inputBox.ClearTextOnFocus = false
    corner(inputBox, 8); stroke(inputBox, C.BORDER); pad(inputBox, 8, 8, 10, 10)
    inputBox.TextXAlignment = Enum.TextXAlignment.Left
    inputBox.TextYAlignment = Enum.TextYAlignment.Top

    local sendBtn = Instance.new("TextButton", inputRow)
    sendBtn.Size = UDim2.new(0, 56, 0, 56); sendBtn.Position = UDim2.new(1, -58, 0, 12)
    sendBtn.BackgroundColor3 = C.ACC1; sendBtn.Text = "▶"; sendBtn.TextColor3 = C.WHITE
    sendBtn.Font = Enum.Font.GothamBold; sendBtn.TextSize = 18; sendBtn.BorderSizePixel = 0
    corner(sendBtn, 10)
    grad(sendBtn, C.ACC1, C.ACC2, 135)

    -- AI call history for context
    local history = {}

    local function callAI(userMsg)
        local key = cfg.apiKey
        if not reqFn then
            addBubble("⚠ request() not available on this executor. Cannot call AI.", false)
            return
        end
        if key == "" then
            addBubble("⚠ No API key set. Go to Settings → Gemini API Key and enter your key.\n\nGet a free key at: aistudio.google.com", false)
            return
        end

        addBubble(userMsg, true)
        history[#history+1] = {role="user", parts={{text=userMsg}}}

        local typingLbl = addBubble("...", false)
        local typingBub = typingLbl.Parent

        task.spawn(function()
            local body = HS:JSONEncode({contents = history})
            local url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=" .. key

            local ok2, res = pcall(reqFn, {
                Url    = url,
                Method = "POST",
                Headers = {["Content-Type"]="application/json"},
                Body    = body,
            })

            local reply
            if not ok2 then
                reply = "⚠ Request failed: " .. tostring(res)
            else
                local body2 = type(res)=="table" and (res.Body or res.body) or tostring(res)
                local dec; pcall(function() dec = HS:JSONDecode(body2) end)
                if dec and dec.candidates and dec.candidates[1] then
                    pcall(function()
                        reply = dec.candidates[1].content.parts[1].text
                    end)
                elseif dec and dec.error then
                    reply = "⚠ API error: " .. tostring(dec.error.message or dec.error)
                end
                reply = reply or "⚠ Unexpected response format."
            end

            -- Update typing bubble in-place
            typingLbl.Text = reply
            typingBub.Size = UDim2.new(0.88, 0, 0, 10)
            task.defer(function()
                local function resize()
                    typingBub.Size = UDim2.new(0.88, 0, 0, typingLbl.AbsoluteSize.Y + 14)
                end
                typingLbl:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize); resize()
                task.wait(0.05)
                chatScroll.CanvasPosition = Vector2.new(0, chatScroll.AbsoluteCanvasSize.Y)
            end)

            history[#history+1] = {role="model", parts={{text=reply}}}
            if #history > 20 then table.remove(history, 1); table.remove(history, 1) end
        end)

        inputBox.Text = ""
    end

    sendBtn.MouseButton1Click:Connect(function()
        local msg = inputBox.Text:match("^%s*(.-)%s*$")
        if msg ~= "" then
            tw(sendBtn, {BackgroundColor3=C.WHITE}, TF_FAST)
            task.delay(0.2, function() tw(sendBtn, {BackgroundColor3=C.ACC1}) end)
            callAI(msg)
        end
    end)

    inputBox.FocusLost:Connect(function(enter)
        if enter then
            local msg = inputBox.Text:match("^%s*(.-)%s*$")
            if msg ~= "" then callAI(msg) end
        end
    end)

    -- Clear chat button
    addButton(P, "Clear Chat", "Remove all messages from history", C.TX3, function()
        for _, c in pairs(chatScroll:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        history = {}
        addBubble("Chat cleared. Ask me anything!", false)
    end)
end

-- ══════════════════════════════════════════════════════════════════════════════
--  TAB: SCRIPTS
-- ══════════════════════════════════════════════════════════════════════════════
do
    local P = tabPages["scripts"]
    loCount = 0

    local SCRIPTS = {
        {name="Infinite Yield",    desc="Admin commands fe",
         url="https://raw.githubusercontent.com/EdgeIY/infinite-yield/master/source"},
        {name="Dex Explorer",      desc="Game explorer + remote spy",
         url="https://cdn.wearedevs.net/scripts/Dex%20Explorer.txt"},
        {name="Hydroxide",         desc="Remote spy + decompiler",
         url="https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/MainHub.lua"},
        {name="Dark Dex v3",       desc="Full game hierarchy explorer",
         url="https://raw.githubusercontent.com/LorekeeperZinnia/Dex/master/3.0/init.lua"},
        {name="Remote Spy",        desc="Hook and log all remotes",
         url="https://raw.githubusercontent.com/exxtremestuffs/SimpleSpySource/master/SimpleSpy.lua"},
    }

    secHeader(P, "POPULAR SCRIPTS")

    for _, s in ipairs(SCRIPTS) do
        addButton(P, s.name, s.desc, C.ACC1, function()
            local ok2, src = pcall(game.HttpGet, game, s.url, true)
            if not ok2 or not src or src == "" then
                notify("Scripts", "Failed to load " .. s.name, 3); return
            end
            local fn, ce = loadstring(src)
            if not fn then notify("Scripts", "Compile error: " .. tostring(ce):sub(1,60), 4); return end
            local ok3, e = pcall(fn)
            if ok3 then notify("Scripts", s.name .. " loaded!", 2)
            else notify("Scripts", "Error: " .. tostring(e):sub(1,60), 4) end
        end)
    end

    secHeader(P, "CUSTOM LOADER")

    local customUrl = ""
    local urlBox = Instance.new("TextBox", P)
    urlBox.Size = UDim2.new(1, 0, 0, 36); urlBox.BackgroundColor3 = C.CARD2
    urlBox.BorderSizePixel = 0; urlBox.TextColor3 = C.TX; urlBox.Font = Enum.Font.Gotham
    urlBox.TextSize = 10.5; urlBox.PlaceholderText = "Paste raw script URL..."
    urlBox.PlaceholderColor3 = C.TX3; urlBox.Text = ""; urlBox.ClearTextOnFocus = false
    corner(urlBox, 8); stroke(urlBox, C.BORDER); pad(urlBox, 4, 4, 10, 10)
    urlBox.LayoutOrder = nextLo()
    urlBox:GetPropertyChangedSignal("Text"):Connect(function() customUrl = urlBox.Text end)

    addButton(P, "Load Custom URL", "Fetch + execute script from URL above", C.ACC2, function()
        local url = customUrl:match("^%s*(.-)%s*$")
        if url == "" then notify("Scripts","Enter a URL first",2); return end
        local ok2, src = pcall(game.HttpGet, game, url, true)
        if not ok2 or not src then notify("Scripts","HttpGet failed",3); return end
        local fn, ce = loadstring(src)
        if not fn then notify("Scripts","Compile error: "..tostring(ce):sub(1,60),4); return end
        local ok3, e = pcall(fn)
        if ok3 then notify("Scripts","Loaded ✓",2)
        else notify("Scripts","Runtime error: "..tostring(e):sub(1,60),4) end
    end)
end

-- ══════════════════════════════════════════════════════════════════════════════
--  TAB: TOOLS
-- ══════════════════════════════════════════════════════════════════════════════
do
    local P = tabPages["tools"]
    loCount = 0

    local function getChar() return LP.Character end
    local function getHRP()  local c=getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
    local function getHum()  local c=getChar(); return c and c:FindFirstChildOfClass("Humanoid") end

    secHeader(P, "PLAYER")

    addButton(P, "God Mode", "Lock HP to max every frame", C.GRN, function()
        local hum = getHum()
        if not hum then notify("Tools","No humanoid",2); return end
        RS.Heartbeat:Connect(function()
            pcall(function()
                local h = getHum()
                if h then h.Health = h.MaxHealth end
            end)
        end)
        notify("Tools","God mode ON",2)
    end)

    addButton(P, "Infinite Jump", "Jump while in air", C.ACC2, function()
        UIS.JumpRequest:Connect(function()
            pcall(function()
                local h = getHum()
                if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        end)
        notify("Tools","Infinite jump ON",2)
    end)

    addButton(P, "Speed × 2", "WalkSpeed = 32", C.ACC1, function()
        local h = getHum(); if h then h.WalkSpeed=32 end
        notify("Tools","Speed × 2",2)
    end)

    addButton(P, "Reset Speed", "WalkSpeed back to 16", C.TX3, function()
        local h = getHum(); if h then h.WalkSpeed=16 end
        notify("Tools","Speed reset",2)
    end)

    addToggle(P, "Noclip", "Phase through walls", false, function(on)
        RS.Stepped:Connect(function()
            if on then
                local c = getChar(); if not c then return end
                for _, v in pairs(c:GetDescendants()) do
                    if v:IsA("BasePart") then v.CanCollide=false end
                end
            end
        end)
    end)

    addToggle(P, "Fullbright", "Max ambient + remove fog", false, function(on)
        local L = game:GetService("Lighting")
        L.Brightness = on and 10 or 1
        L.GlobalShadows = not on
        L.FogEnd = on and 1e9 or 100000
        L.Ambient = on and Color3.new(1,1,1) or Color3.new(0,0,0)
        L.OutdoorAmbient = on and Color3.new(1,1,1) or Color3.fromRGB(70,70,70)
    end)

    secHeader(P, "WORLD")

    addButton(P, "Dump All Remotes", "Print remotes to F9 console", C.TX3, function()
        local found = {}
        for _, v in pairs(game:GetDescendants()) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                found[#found+1] = v:GetFullName()
            end
        end
        table.sort(found)
        print("[Clyde] === Remotes (" .. #found .. ") ===")
        for _, n in ipairs(found) do print("  " .. n) end
        notify("Tools","Dumped " .. #found .. " remotes → F9",3)
    end)

    addButton(P, "Toggle Day/Night", "Flip clock time", C.TX3, function()
        local L = game:GetService("Lighting")
        L.ClockTime = L.ClockTime > 6 and 0 or 14
    end)

    addButton(P, "Remove Fog", "FogEnd = 1e9", C.TX3, function()
        game:GetService("Lighting").FogEnd = 1e9
        notify("Tools","Fog removed",2)
    end)

    secHeader(P, "TELEPORT")

    addButton(P, "TP to Spawn", "Teleport to spawn location", C.ACC3, function()
        local hrp = getHRP(); if not hrp then return end
        local sp = workspace:FindFirstChildOfClass("SpawnLocation")
        if sp then hrp.CFrame = CFrame.new(sp.Position + Vector3.new(0,5,0))
        else hrp.CFrame = CFrame.new(0,20,0) end
        notify("Tools","Teleported to spawn",2)
    end)

    addButton(P, "TP to Nearest Player", "Jump beside closest enemy", C.ACC1, function()
        local hrp = getHRP(); if not hrp then return end
        local best, bd = nil, math.huge
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local r2 = p.Character:FindFirstChild("HumanoidRootPart")
                if r2 then
                    local d = (r2.Position-hrp.Position).Magnitude
                    if d < bd then best=r2; bd=d end
                end
            end
        end
        if best then
            hrp.CFrame = CFrame.new(best.Position + Vector3.new(4,0,0))
            notify("Tools","Teleported!",2)
        else notify("Tools","No players found",2) end
    end)
end

-- ══════════════════════════════════════════════════════════════════════════════
--  TAB: SETTINGS
-- ══════════════════════════════════════════════════════════════════════════════
do
    local P = tabPages["settings"]
    loCount = 0

    secHeader(P, "AI CONFIGURATION")

    addInfo(P, "Enter your free Gemini API key below.\nGet one at: aistudio.google.com/apikey")

    -- API key input
    local keyCard = Instance.new("Frame", P)
    keyCard.Size = UDim2.new(1, 0, 0, 72); keyCard.BackgroundColor3 = C.CARD
    keyCard.BorderSizePixel = 0; corner(keyCard, 8); keyCard.LayoutOrder = nextLo()
    stroke(keyCard, C.BORDER)

    local keyLbl = Instance.new("TextLabel", keyCard)
    keyLbl.Size = UDim2.new(1, -16, 0, 16); keyLbl.Position = UDim2.new(0, 10, 0, 8)
    keyLbl.BackgroundTransparency = 1; keyLbl.Text = "Gemini API Key"
    keyLbl.TextColor3 = C.TX; keyLbl.Font = Enum.Font.GothamSemibold; keyLbl.TextSize = 11
    keyLbl.TextXAlignment = Enum.TextXAlignment.Left

    local keyBox = Instance.new("TextBox", keyCard)
    keyBox.Size = UDim2.new(1, -16, 0, 28); keyBox.Position = UDim2.new(0, 8, 0, 30)
    keyBox.BackgroundColor3 = C.CARD2; keyBox.BorderSizePixel = 0
    keyBox.TextColor3 = C.TX; keyBox.Font = Enum.Font.Code; keyBox.TextSize = 9.5
    keyBox.PlaceholderText = "AIza..."; keyBox.PlaceholderColor3 = C.TX3
    keyBox.Text = cfg.apiKey; keyBox.ClearTextOnFocus = false
    corner(keyBox, 6); stroke(keyBox, C.BORDER); pad(keyBox, 4, 4, 8, 8)
    keyBox.TextXAlignment = Enum.TextXAlignment.Left
    keyBox:GetPropertyChangedSignal("Text"):Connect(function()
        cfg.apiKey = keyBox.Text; saveCfg()
    end)

    addButton(P, "Test AI Connection", "Send a test ping to Gemini", C.ACC2, function()
        if not reqFn then
            notify("Settings","request() not available",3); return
        end
        if cfg.apiKey == "" then
            notify("Settings","Enter API key first",3); return
        end
        local url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=" .. cfg.apiKey
        local ok2, res = pcall(reqFn, {
            Url = url, Method = "POST",
            Headers = {["Content-Type"]="application/json"},
            Body = HS:JSONEncode({contents={{role="user",parts={{text="Say: OK"}}}}})
        })
        if ok2 then
            local body = type(res)=="table" and (res.Body or res.body) or ""
            local dec; pcall(function() dec = HS:JSONDecode(body) end)
            if dec and dec.candidates then
                notify("Settings","AI connection ✓",3)
            elseif dec and dec.error then
                notify("Settings","API error: " .. tostring(dec.error.message or ""):sub(1,50),4)
            else
                notify("Settings","Unexpected response",3)
            end
        else
            notify("Settings","Request failed: " .. tostring(res):sub(1,50), 4)
        end
    end)

    secHeader(P, "HUB INFO")

    addInfo(P, "Clyde Hub v1.0\nExecutor: " .. (reqFn and "request() ✓" or "request() ✗") .. "  ·  Delta/iOS compatible")
    addInfo(P, "Load: loadstring(game:HttpGet(\"https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/claude/session-UDpk7/Clyde_Hub.lua\",true))()")

    addButton(P, "Copy Load String", "Print load URL to F9 console", C.ACC1, function()
        local url = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/claude/session-UDpk7/Clyde_Hub.lua",true))()'
        print("[Clyde] " .. url)
        if setclipboard then pcall(function() setclipboard(url) end) end
        notify("Settings","Copied ✓",2)
    end)

    secHeader(P, "EXECUTOR APIs")
    local apiList = {
        {"request()", type(request)=="function"},
        {"game:HttpGet", true},
        {"readfile/writefile", type(readfile)=="function"},
        {"getgc", type(getgc)=="function"},
        {"hookmetamethod", type(hookmetamethod)=="function"},
        {"VirtualUser", (function() local ok2,_=pcall(function() game:GetService("VirtualUser") end); return ok2 end)()},
    }
    for _, a in ipairs(apiList) do
        addInfo(P, (a[2] and "✓  " or "✗  ") .. a[1], a[2] and C.GRN or C.RED)
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
--  DRAG
-- ══════════════════════════════════════════════════════════════════════════════
local dragging=false; local dragStart=nil; local winStart=nil
TBAR.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        dragging=true; dragStart=i.Position; winStart=WIN.Position
    end
end)
TBAR.InputEnded:Connect(function() dragging=false end)
UIS.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
        local d=i.Position-dragStart
        WIN.Position=UDim2.new(winStart.X.Scale,winStart.X.Offset+d.X,winStart.Y.Scale,winStart.Y.Offset+d.Y)
        SHADOW.Position=WIN.Position+UDim2.new(0,-4,0,-4)
    end
end)

-- ══════════════════════════════════════════════════════════════════════════════
--  MINIMIZE / CLOSE
-- ══════════════════════════════════════════════════════════════════════════════
local minimized = false

local ORB = Instance.new("Frame", SCR)
ORB.Size=UDim2.new(0,48,0,48); ORB.Position=UDim2.new(0,20,0.5,-24)
ORB.BackgroundColor3=C.ACC1; ORB.BorderSizePixel=0; ORB.Visible=false; corner(ORB,24)
grad(ORB, C.ACC1, C.ACC2, 135)
local ORBL=Instance.new("TextLabel",ORB); ORBL.Size=UDim2.new(1,0,1,0); ORBL.BackgroundTransparency=1
ORBL.Text="✦"; ORBL.TextColor3=C.WHITE; ORBL.Font=Enum.Font.GothamBold; ORBL.TextSize=20
ORBL.TextXAlignment=Enum.TextXAlignment.Center
local ORB_BTN=Instance.new("TextButton",ORB); ORB_BTN.Size=UDim2.new(1,0,1,0); ORB_BTN.BackgroundTransparency=1; ORB_BTN.Text=""

local orbDrag=false; local orbDS=nil; local orbPS=nil
ORB.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        orbDrag=true; orbDS=i.Position; orbPS=ORB.Position
    end
end)
ORB.InputEnded:Connect(function() orbDrag=false end)
UIS.InputChanged:Connect(function(i)
    if orbDrag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
        local d=i.Position-orbDS
        ORB.Position=UDim2.new(orbPS.X.Scale,orbPS.X.Offset+d.X,orbPS.Y.Scale,orbPS.Y.Offset+d.Y)
    end
end)

local function setMinimized(v)
    minimized=v
    if v then
        tw(WIN,{Size=UDim2.new(0,376,0,0),BackgroundTransparency=1},TF_SLOW)
        tw(SHADOW,{BackgroundTransparency=1},TF_MED)
        task.delay(0.35,function() WIN.Visible=false; SHADOW.Visible=false end)
        ORB.Visible=true; tw(ORB,{Size=UDim2.new(0,48,0,48),BackgroundTransparency=0},TF_SPRING)
    else
        WIN.Visible=true; SHADOW.Visible=true
        WIN.Size=UDim2.new(0,376,0,0); WIN.BackgroundTransparency=1
        tw(WIN,{Size=UDim2.new(0,376,0,544),BackgroundTransparency=0},TF_SLOW)
        tw(SHADOW,{BackgroundTransparency=0.45},TF_MED)
        tw(ORB,{Size=UDim2.new(0,0,0,0)},TF_MED)
        task.delay(0.2,function() ORB.Visible=false end)
    end
end

MINBTN.MouseButton1Click:Connect(function() setMinimized(true) end)
ORB_BTN.MouseButton1Click:Connect(function() if not orbDrag then setMinimized(false) end end)
CLOSEBTN.MouseButton1Click:Connect(function()
    tw(WIN,{BackgroundTransparency=1,Size=UDim2.new(0,376,0,0)},TF_MED)
    task.delay(0.3,function() SCR:Destroy() end)
end)

UIS.InputBegan:Connect(function(i,gpe)
    if not gpe and (i.KeyCode==Enum.KeyCode.Insert or i.KeyCode==Enum.KeyCode.RightShift) then
        setMinimized(not minimized)
    end
end)

-- ══════════════════════════════════════════════════════════════════════════════
--  OPEN ANIMATION + FIRST TAB
-- ══════════════════════════════════════════════════════════════════════════════
WIN.Size=UDim2.new(0,376,0,0); WIN.BackgroundTransparency=1
task.wait(0.05)
WIN.Visible=true
tw(WIN,{Size=UDim2.new(0,376,0,544),BackgroundTransparency=0},TF_SLOW)
task.wait(0.1)
showTab("ai")
notify("Clyde Hub","v1.0 loaded  ·  RShift to hide",3)

end)
if not ok then
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification",
            {Title="Clyde Hub Error",Text=tostring(err):sub(1,120),Duration=8})
    end)
    warn("[Clyde Hub] STARTUP ERROR:", err)
end
