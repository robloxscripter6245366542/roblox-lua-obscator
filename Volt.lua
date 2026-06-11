-- Volt  — Network Monitor
-- Two-pane Cobalt-style layout · purple theme · caller-type icons
-- Block • Ignore • BindableEvent/Function • UnreliableRemoteEvent

local Players     = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ── EXECUTOR CAPABILITY CHECK ────────────────────────────────────
local hasHookMeta  = type(hookmetamethod) == "function"
local hasHookFn    = type(hookfunction)   == "function"
local hasNewCC     = type(newcclosure)    == "function"
local hasCheckCall = type(checkcaller)    == "function"
local hasDbgInfo   = type(debug) == "table" and type(debug.info) == "function"

-- ── BLOCKED / IGNORED STATE ──────────────────────────────────────
local blockedNames = {}
local ignoredNames = {}

-- ── CALLER INFO ──────────────────────────────────────────────────
local function getCallerInfo()
    if not hasDbgInfo then return "unknown", -1 end
    local base = (hasHookMeta or hasHookFn) and 4 or 2
    for i = base, 12 do
        local src, line = debug.info(i, "sl")
        if not src then break end
        if src ~= "[C]" then
            src = src:match("[^%.%/]+$") or src
            return src, line or -1
        end
    end
    return "unknown", -1
end

-- ── SERIALISER ───────────────────────────────────────────────────
local function fmtV(v, d)
    d = d or 0; if d > 2 then return "…" end
    local t = typeof(v)
    if     t=="nil"      then return "nil"
    elseif t=="boolean"  then return tostring(v)
    elseif t=="number"   then return v==math.floor(v) and tostring(math.floor(v)) or ("%.4g"):format(v)
    elseif t=="string"   then local s=v:sub(1,40):gsub("[%c]","·"); return '"'..s..(#v>40 and "…" or "")..'"'
    elseif t=="Instance" then return "["..v.ClassName..":"..v.Name.."]"
    elseif t=="Vector3"  then return ("V3(%g,%g,%g)"):format(v.X,v.Y,v.Z)
    elseif t=="Vector2"  then return ("V2(%g,%g)"):format(v.X,v.Y)
    elseif t=="CFrame"   then local p=v.Position; return ("CF(%g,%g,%g)"):format(p.X,p.Y,p.Z)
    elseif t=="Color3"   then return ("RGB(%d,%d,%d)"):format(v.R*255,v.G*255,v.B*255)
    elseif t=="EnumItem" then return tostring(v)
    elseif t=="table"    then
        local p,i={},0
        for k,u in pairs(v) do
            i=i+1; if i>4 then p[#p+1]="…"; break end
            p[#p+1]=type(k)=="number" and fmtV(u,d+1) or (tostring(k).."="..fmtV(u,d+1))
        end
        return "{"..table.concat(p,",").."}"
    else return tostring(v):sub(1,24) end
end

local function argType(v)
    local t = typeof(v)
    return t=="Instance" and v.ClassName or t
end

-- ── CODE GENERATOR ───────────────────────────────────────────────
local function codeV(v, d)
    d=d or 0; if d>3 then return "nil" end
    local t=typeof(v)
    if     t=="nil"      then return "nil"
    elseif t=="boolean"  then return tostring(v)
    elseif t=="number"   then return tostring(v)
    elseif t=="string"   then return '"'..v:gsub("\\","\\\\"):gsub('"','\\"'):gsub("\n","\\n")..'"'
    elseif t=="Instance" then
        local p=v:GetFullName()
        return p:gsub("^game%.([^%.]+)",function(s) return 'game:GetService("'..s..'")' end)
    elseif t=="Vector3"  then return ("Vector3.new(%g, %g, %g)"):format(v.X,v.Y,v.Z)
    elseif t=="Vector2"  then return ("Vector2.new(%g, %g)"):format(v.X,v.Y)
    elseif t=="CFrame"   then
        local c={v:GetComponents()}; local s={}
        for _,n in ipairs(c) do s[#s+1]=tostring(n) end
        return "CFrame.new("..table.concat(s,", ")..")"
    elseif t=="Color3"   then return ("Color3.fromRGB(%d,%d,%d)"):format(v.R*255,v.G*255,v.B*255)
    elseif t=="UDim2"    then return ("UDim2.new(%g,%g,%g,%g)"):format(v.X.Scale,v.X.Offset,v.Y.Scale,v.Y.Offset)
    elseif t=="EnumItem" then return "Enum."..tostring(v.EnumType).."."..v.Name
    elseif t=="table"    then
        local p={}
        for k,u in pairs(v) do
            if type(k)=="number" then p[#p+1]=codeV(u,d+1)
            else p[#p+1]='["'..tostring(k)..'"]='..codeV(u,d+1) end
        end
        return "{"..table.concat(p,", ").."}"
    else return "--[["..t.."]]" end
end

local function buildCode(entry)
    local path
    local r=entry.remote
    if r and r.Parent then
        path=r:GetFullName():gsub("^game%.([^%.]+)",function(s) return 'game:GetService("'..s..'")' end)
    else path="--[["..entry.name.."]]" end
    if entry.dir=="IN" then
        local p={}; for _,v in ipairs(entry.args) do p[#p+1]=codeV(v) end
        return "-- incoming: "..path.." ("..table.concat(p,", ")..")"
    end
    local p={}; for _,v in ipairs(entry.args) do p[#p+1]=codeV(v) end
    return path..":"..entry.method.."("..table.concat(p,", ")..")"
end

-- ── STATE ────────────────────────────────────────────────────────
local MAX_LOG       = 200
local paused        = false
local activeTab     = "OUT"
local filterTxt     = ""
local filterMode    = "ALL"
local lists         = { OUT={}, IN={} }
local remoteTotals  = {}
local hookedIn      = {}
local selectedEntry = nil

-- ── TARGET CLASSES ───────────────────────────────────────────────
local TargetClasses = {
    RemoteEvent=true, RemoteFunction=true,
    UnreliableRemoteEvent=true,
    BindableEvent=true, BindableFunction=true,
}
local OutgoingMethods = {
    FireServer=true, InvokeServer=true,
    fireServer=true, invokeServer=true,
    Fire=true, Invoke=true, fire=true, invoke=true,
}

-- ── REMOTE TYPE ICONS ────────────────────────────────────────────
local REMOTE_ICON = {
    RemoteEvent           = { icon="⚡", col=Color3.fromRGB(80,160,255)  },
    RemoteFunction        = { icon="ƒ",  col=Color3.fromRGB(160,100,255) },
    UnreliableRemoteEvent = { icon="≈",  col=Color3.fromRGB(80,210,180)  },
    BindableEvent         = { icon="◈",  col=Color3.fromRGB(255,180,60)  },
    BindableFunction      = { icon="⬡",  col=Color3.fromRGB(255,120,80)  },
}
local function remoteIcon(entry)
    local r   = entry.remote
    local cls = r and r.ClassName or ""
    return REMOTE_ICON[cls] or { icon="⚡", col=Color3.fromRGB(160,160,160) }
end

-- ── CALLER TYPE ICONS  (like Cobalt's LocalScript / >_ Delta) ────
-- icon, bg colour, text colour
local CALLER_STYLE = {
    executor  = { icon=">_",  bg=Color3.fromRGB(120,60,10),   fg=Color3.fromRGB(255,165,70)  },
    module    = { icon="◉",   bg=Color3.fromRGB(20,80,30),    fg=Color3.fromRGB(110,215,90)  },
    local_    = { icon="⊡",   bg=Color3.fromRGB(20,55,110),   fg=Color3.fromRGB(110,175,255) },
    server    = { icon="⬡",   bg=Color3.fromRGB(70,30,110),   fg=Color3.fromRGB(195,140,255) },
    default   = { icon="◈",   bg=Color3.fromRGB(40,30,65),    fg=Color3.fromRGB(170,155,215) },
}
local function callerStyle(entry)
    if entry.isExecutor then return CALLER_STYLE.executor end
    local s = (entry.callerSrc or ""):lower()
    if s:find("module") then return CALLER_STYLE.module  end
    if s:find("local")  then return CALLER_STYLE.local_  end
    if s:find("server") then return CALLER_STYLE.server  end
    if s ~= "" and s ~= "unknown" then return CALLER_STYLE.default end
    return nil
end

-- ── TYPE COLOURS (for arg type labels) ───────────────────────────
local TYPE_COLS = {
    string   = Color3.fromRGB(100,200,100), number  = Color3.fromRGB(100,150,240),
    boolean  = Color3.fromRGB(240,180,80),  Instance= Color3.fromRGB(210,130,230),
    Vector3  = Color3.fromRGB(80,220,220),  CFrame  = Color3.fromRGB(230,230,80),
    table    = Color3.fromRGB(240,100,100), ["nil"] = Color3.fromRGB(110,110,110),
}
local function tc(t) return TYPE_COLS[t] or Color3.fromRGB(180,180,180) end

-- ── GUI DIMENSIONS ───────────────────────────────────────────────
local W, H      = 640, 460
local TITLE_H   = 32
local LEFT_W    = 232
local ITEM_H    = 36
-- purple palette
local C_BG      = Color3.fromRGB(14,9,24)
local C_LPANE   = Color3.fromRGB(17,11,30)
local C_RPANE   = Color3.fromRGB(11,7,20)
local C_TITLE   = Color3.fromRGB(26,15,48)
local C_ROW     = Color3.fromRGB(19,12,32)
local C_SEL     = Color3.fromRGB(42,20,74)
local C_ACCENT  = Color3.fromRGB(115,48,210)
local C_DIM     = Color3.fromRGB(75,65,105)
local C_TEXT    = Color3.fromRGB(220,210,250)

-- ── TOGGLE BUTTON  (always visible) ─────────────────────────────
local tSg = Instance.new("ScreenGui")
tSg.Name = "VoltToggle"; tSg.ResetOnSpawn = false; tSg.DisplayOrder = 10
tSg.Parent = LocalPlayer:WaitForChild("PlayerGui")

local tBtn = Instance.new("TextButton")
tBtn.Size = UDim2.new(0,84,0,24); tBtn.Position = UDim2.new(0.5,-42,0,6)
tBtn.BackgroundColor3 = Color3.fromRGB(70,28,140); tBtn.BorderSizePixel = 0
tBtn.Text = "ϟ  VOLT"; tBtn.TextColor3 = Color3.fromRGB(215,180,255)
tBtn.Font = Enum.Font.GothamBold; tBtn.TextSize = 11; tBtn.Parent = tSg
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,12);c.Parent=tBtn end
do
    local g=Instance.new("UIGradient")
    g.Color=ColorSequence.new{
        ColorSequenceKeypoint.new(0,Color3.fromRGB(108,46,204)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(54,18,110)),
    }
    g.Rotation=90; g.Parent=tBtn
end
do local s=Instance.new("UIStroke");s.Color=Color3.fromRGB(130,72,215);s.Thickness=1;s.Transparency=0.5;s.Parent=tBtn end

-- ── MAIN WINDOW ──────────────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name = "Volt"; sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = LocalPlayer:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Name = "Main"; main.Size = UDim2.new(0,W,0,H)
main.Position = UDim2.new(0.5,-W/2,0.5,-H/2)
main.BackgroundColor3 = C_BG; main.BorderSizePixel = 0
main.Active = true; main.Draggable = true; main.Parent = sg
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,10);c.Parent=main end
do local s=Instance.new("UIStroke");s.Color=Color3.fromRGB(60,32,100);s.Thickness=1;s.Transparency=0.35;s.Parent=main end

-- title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1,0,0,TITLE_H); titleBar.BackgroundColor3 = C_TITLE
titleBar.BorderSizePixel = 0; titleBar.Parent = main
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,10);c.Parent=titleBar end

-- ϟ logo badge
local logoBadge = Instance.new("Frame")
logoBadge.Size = UDim2.new(0,24,0,20); logoBadge.Position = UDim2.new(0,6,0.5,-10)
logoBadge.BackgroundColor3 = C_ACCENT; logoBadge.BorderSizePixel = 0; logoBadge.Parent = titleBar
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,6);c.Parent=logoBadge end
do
    local g=Instance.new("UIGradient")
    g.Color=ColorSequence.new{
        ColorSequenceKeypoint.new(0,Color3.fromRGB(178,90,255)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(86,20,192)),
    }
    g.Rotation=135; g.Parent=logoBadge
end
local bL=Instance.new("TextLabel"); bL.Size=UDim2.new(1,0,1,0); bL.BackgroundTransparency=1
bL.Text="ϟ"; bL.TextColor3=Color3.fromRGB(255,245,200); bL.Font=Enum.Font.GothamBold; bL.TextSize=13; bL.Parent=logoBadge
do local s=Instance.new("UIStroke");s.Color=Color3.fromRGB(200,138,255);s.Thickness=1;s.Transparency=0.5;s.Parent=logoBadge end

-- title text (centered)
local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1,-180,1,0); titleLbl.Position = UDim2.new(0,36,0,0)
titleLbl.BackgroundTransparency = 1; titleLbl.Text = "VOLT"
titleLbl.TextColor3 = Color3.fromRGB(200,156,255); titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 13; titleLbl.TextXAlignment = Enum.TextXAlignment.Left; titleLbl.Parent = titleBar

-- window control buttons (title bar right side)
local function mkWinBtn(xOff, w, txt, col)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0,w,0,20); b.Position = UDim2.new(1,xOff,0.5,-10)
    b.BackgroundColor3 = col; b.BorderSizePixel = 0
    b.Text = txt; b.TextColor3 = C_TEXT
    b.Font = Enum.Font.GothamBold; b.TextSize = 10; b.Parent = titleBar
    do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,5);c.Parent=b end
    return b
end
local closeBtn = mkWinBtn(-26,  20, "✖",       Color3.fromRGB(155,36,36))
local minBtn   = mkWinBtn(-50,  20, "━",       Color3.fromRGB(40,24,70))
local clearBtn = mkWinBtn(-118, 64, "⌫ Clear", Color3.fromRGB(105,28,28))
local pauseBtn = mkWinBtn(-186, 64, "⏸ Pause", Color3.fromRGB(115,84,18))

-- ════════════  LEFT PANE — remote list  ═════════════════════════
local leftPane = Instance.new("Frame")
leftPane.Size = UDim2.new(0,LEFT_W,1,-TITLE_H); leftPane.Position = UDim2.new(0,0,0,TITLE_H)
leftPane.BackgroundColor3 = C_LPANE; leftPane.BorderSizePixel = 0; leftPane.Parent = main

-- tab row
local function mkTabBtn(x, w, txt)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0,w,0,22); b.Position = UDim2.new(0,x,0,5)
    b.BackgroundColor3 = Color3.fromRGB(26,14,48); b.BorderSizePixel = 0
    b.Text = txt; b.TextColor3 = C_TEXT
    b.Font = Enum.Font.GothamBold; b.TextSize = 11; b.Parent = leftPane
    do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,6);c.Parent=b end
    return b
end
local tabOut = mkTabBtn(5,   108, "↑  Outgoing")
local tabIn  = mkTabBtn(117, 108, "↓  Incoming")

-- search
local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(0,LEFT_W-10,0,22); searchBox.Position = UDim2.new(0,5,0,31)
searchBox.BackgroundColor3 = Color3.fromRGB(22,14,36); searchBox.BorderSizePixel = 0
searchBox.Text = ""; searchBox.PlaceholderText = "search remote…"
searchBox.TextColor3 = C_TEXT; searchBox.PlaceholderColor3 = C_DIM
searchBox.Font = Enum.Font.Gotham; searchBox.TextSize = 11; searchBox.ClearTextOnFocus = false
searchBox.TextXAlignment = Enum.TextXAlignment.Left; searchBox.Parent = leftPane
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,5);c.Parent=searchBox end
do local p=Instance.new("UIPadding");p.PaddingLeft=UDim.new(0,7);p.Parent=searchBox end

-- filter buttons
local function mkFBtn(x, w, txt)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0,w,0,18); b.Position = UDim2.new(0,x,0,57)
    b.BackgroundColor3 = Color3.fromRGB(30,18,52); b.BorderSizePixel = 0
    b.Text = txt; b.TextColor3 = Color3.fromRGB(205,188,240)
    b.Font = Enum.Font.GothamBold; b.TextSize = 9; b.Parent = leftPane
    do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,5);c.Parent=b end
    return b
end
local btnAll     = mkFBtn(5,   44, "⋮ All")
local btnBlocked = mkFBtn(53,  82, "⊘ Blocked")
local btnIgnored = mkFBtn(139, 88, "◎ Ignored")

-- call count label
local countLbl = Instance.new("TextLabel")
countLbl.Size = UDim2.new(1,-10,0,14); countLbl.Position = UDim2.new(0,5,0,78)
countLbl.BackgroundTransparency = 1; countLbl.Text = "0 calls"
countLbl.TextColor3 = C_DIM; countLbl.Font = Enum.Font.Gotham
countLbl.TextSize = 9; countLbl.TextXAlignment = Enum.TextXAlignment.Left; countLbl.Parent = leftPane

-- remote list scroll
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1,-3,1,-96); scroll.Position = UDim2.new(0,2,0,94)
scroll.BackgroundColor3 = Color3.fromRGB(10,6,18); scroll.BackgroundTransparency = 0.2
scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = Color3.fromRGB(70,52,105)
scroll.CanvasSize = UDim2.new(0,0,0,0); scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = leftPane
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,5);c.Parent=scroll end

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder; listLayout.Padding = UDim.new(0,1); listLayout.Parent = scroll

-- vertical separator
do
    local dv = Instance.new("Frame"); dv.Size = UDim2.new(0,1,1,-TITLE_H-8)
    dv.Position = UDim2.new(0,LEFT_W,0,TITLE_H+4)
    dv.BackgroundColor3 = Color3.fromRGB(55,30,90); dv.BorderSizePixel = 0; dv.Parent = main
end

-- ════════════  RIGHT PANE — detail view  ════════════════════════
local rightPane = Instance.new("Frame")
rightPane.Size = UDim2.new(1,-LEFT_W-1,1,-TITLE_H); rightPane.Position = UDim2.new(0,LEFT_W+1,0,TITLE_H)
rightPane.BackgroundColor3 = C_RPANE; rightPane.BorderSizePixel = 0; rightPane.Parent = main

-- detail header (remote name + action buttons)
local detailHeader = Instance.new("Frame")
detailHeader.Size = UDim2.new(1,0,0,28); detailHeader.BackgroundColor3 = Color3.fromRGB(20,12,36)
detailHeader.BorderSizePixel = 0; detailHeader.Parent = rightPane

local detailLbl = Instance.new("TextLabel")
detailLbl.Size = UDim2.new(1,-225,1,0); detailLbl.Position = UDim2.new(0,10,0,0)
detailLbl.BackgroundTransparency = 1; detailLbl.Text = "select a remote →"
detailLbl.TextColor3 = C_DIM; detailLbl.Font = Enum.Font.GothamMedium
detailLbl.TextSize = 11; detailLbl.TextXAlignment = Enum.TextXAlignment.Left; detailLbl.Parent = detailHeader

local function mkDBtn(xOff, w, txt, col)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0,w,0,20); b.Position = UDim2.new(1,xOff,0.5,-10)
    b.BackgroundColor3 = col; b.BorderSizePixel = 0
    b.Text = txt; b.TextColor3 = C_TEXT
    b.Font = Enum.Font.GothamBold; b.TextSize = 10; b.Parent = detailHeader
    do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,5);c.Parent=b end
    return b
end
local copyBtn     = mkDBtn(-56,  50, "⎘ Copy",  Color3.fromRGB(54,36,90))
local ignEntBtn   = mkDBtn(-112, 52, "◎ Ignore",Color3.fromRGB(38,24,64))
local blockEntBtn = mkDBtn(-170, 54, "⊘ Block", Color3.fromRGB(118,30,30))
local replayBtn   = mkDBtn(-232, 58, "↺ Replay",Color3.fromRGB(78,32,162))
replayBtn.Visible=false; blockEntBtn.Visible=false; ignEntBtn.Visible=false

-- arg / caller scroll (main content area)
local argScroll = Instance.new("ScrollingFrame")
argScroll.Size = UDim2.new(1,0,1,-90); argScroll.Position = UDim2.new(0,0,0,28)
argScroll.BackgroundTransparency = 1; argScroll.BorderSizePixel = 0
argScroll.ScrollBarThickness = 3; argScroll.ScrollBarImageColor3 = Color3.fromRGB(60,44,90)
argScroll.CanvasSize = UDim2.new(0,0,0,0); argScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
argScroll.Parent = rightPane

local argLayout = Instance.new("UIListLayout")
argLayout.SortOrder = Enum.SortOrder.LayoutOrder; argLayout.Padding = UDim.new(0,0); argLayout.Parent = argScroll

-- horizontal divider above code box
do
    local dv = Instance.new("Frame"); dv.Size = UDim2.new(1,0,0,1)
    dv.Position = UDim2.new(0,0,1,-62)
    dv.BackgroundColor3 = Color3.fromRGB(48,26,80); dv.BorderSizePixel = 0; dv.Parent = rightPane
end

-- generated code box (pinned at bottom, like Cobalt)
local codeBox = Instance.new("TextBox")
codeBox.Size = UDim2.new(1,-8,0,56); codeBox.Position = UDim2.new(0,4,1,-60)
codeBox.BackgroundTransparency = 1; codeBox.Text = ""
codeBox.TextColor3 = Color3.fromRGB(105,208,128); codeBox.Font = Enum.Font.Code
codeBox.TextSize = 10; codeBox.ClearTextOnFocus = false; codeBox.MultiLine = true
codeBox.TextXAlignment = Enum.TextXAlignment.Left; codeBox.TextYAlignment = Enum.TextYAlignment.Top
codeBox.TextWrapped = true; codeBox.Parent = rightPane

-- ── HELPERS: populate arg scroll ────────────────────────────────
local function clearArgScroll()
    for _,c in ipairs(argScroll:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
end

local function addArgRow(lineNum, value, ord)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,24); row.LayoutOrder = ord
    row.BackgroundColor3 = lineNum%2==0 and Color3.fromRGB(15,9,26) or Color3.fromRGB(18,11,30)
    row.BorderSizePixel = 0; row.Parent = argScroll

    local nL = Instance.new("TextLabel"); nL.Size = UDim2.new(0,28,1,0); nL.Position = UDim2.new(0,0,0,0)
    nL.BackgroundTransparency = 1; nL.Text = tostring(lineNum)
    nL.TextColor3 = C_DIM; nL.Font = Enum.Font.Code; nL.TextSize = 11; nL.Parent = row

    local typ = argType(value)
    local vL = Instance.new("TextLabel"); vL.Size = UDim2.new(1,-110,1,0); vL.Position = UDim2.new(0,30,0,0)
    vL.BackgroundTransparency = 1; vL.Text = fmtV(value)
    -- string values shown in teal like Cobalt; other types use TYPE_COLS
    local valCol = typ=="string" and Color3.fromRGB(90,210,200)
        or typ=="number" and Color3.fromRGB(100,150,240)
        or TYPE_COLS[typ] or Color3.fromRGB(200,200,215)
    vL.TextColor3 = valCol; vL.Font = Enum.Font.Code; vL.TextSize = 11
    vL.TextXAlignment = Enum.TextXAlignment.Left; vL.TextTruncate = Enum.TextTruncate.AtEnd; vL.Parent = row

    -- type label right-aligned (dim, like Cobalt)
    local tL = Instance.new("TextLabel"); tL.Size = UDim2.new(0,80,1,0); tL.Position = UDim2.new(1,-84,0,0)
    tL.BackgroundTransparency = 1; tL.Text = typ
    tL.TextColor3 = C_DIM; tL.Font = Enum.Font.Gotham; tL.TextSize = 10
    tL.TextXAlignment = Enum.TextXAlignment.Right; tL.Parent = row
end

local function addCallerRow(entry, ord)
    local cs = callerStyle(entry)
    if not cs then return end

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,22); row.LayoutOrder = ord
    row.BackgroundColor3 = Color3.fromRGB(22,13,38); row.BorderSizePixel = 0; row.Parent = argScroll

    -- caller type icon badge
    local badge = Instance.new("Frame")
    badge.Size = UDim2.new(0,30,0,16); badge.Position = UDim2.new(0,6,0.5,-8)
    badge.BackgroundColor3 = cs.bg; badge.BorderSizePixel = 0; badge.Parent = row
    do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,4);c.Parent=badge end
    local badgeLbl = Instance.new("TextLabel")
    badgeLbl.Size = UDim2.new(1,0,1,0); badgeLbl.BackgroundTransparency = 1
    badgeLbl.Text = cs.icon; badgeLbl.TextColor3 = cs.fg
    badgeLbl.Font = Enum.Font.GothamBold; badgeLbl.TextSize = 10; badgeLbl.Parent = badge

    -- source name
    local src = (entry.isExecutor and "Executor")
        or (entry.callerSrc ~= "unknown" and entry.callerSrc)
        or "unknown"
    if entry.callerLine and entry.callerLine > 0 and not entry.isExecutor then
        src = src..":"..entry.callerLine
    end
    local srcLbl = Instance.new("TextLabel")
    srcLbl.Size = UDim2.new(1,-130,1,0); srcLbl.Position = UDim2.new(0,40,0,0)
    srcLbl.BackgroundTransparency = 1; srcLbl.Text = src
    srcLbl.TextColor3 = cs.fg; srcLbl.Font = Enum.Font.GothamMedium; srcLbl.TextSize = 10
    srcLbl.TextXAlignment = Enum.TextXAlignment.Left; srcLbl.Parent = row

    -- time
    local tL = Instance.new("TextLabel")
    tL.Size = UDim2.new(0,85,1,0); tL.Position = UDim2.new(1,-88,0,0)
    tL.BackgroundTransparency = 1; tL.Text = "Time: "..entry.timeStr
    tL.TextColor3 = C_DIM; tL.Font = Enum.Font.Gotham; tL.TextSize = 9
    tL.TextXAlignment = Enum.TextXAlignment.Right; tL.Parent = row
end

local function addNoArgsRow(ord)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,24); row.LayoutOrder = ord
    row.BackgroundTransparency = 1; row.BorderSizePixel = 0; row.Parent = argScroll
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1
    lbl.Text = "(no arguments)"; lbl.TextColor3 = C_DIM
    lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 10; lbl.Parent = row
end

-- ── ENTRY SELECTION ──────────────────────────────────────────────
local function setSelected(entry)
    if selectedEntry and selectedEntry.rowFrame then
        selectedEntry.rowFrame.BackgroundColor3 = C_ROW
    end
    selectedEntry = entry
    clearArgScroll()
    if not entry then
        detailLbl.Text = "select a remote →"
        detailLbl.TextColor3 = C_DIM
        codeBox.Text = ""
        replayBtn.Visible=false; blockEntBtn.Visible=false; ignEntBtn.Visible=false
        return
    end
    if entry.rowFrame then entry.rowFrame.BackgroundColor3 = C_SEL end
    detailLbl.Text = (entry.dir=="OUT" and "↑  " or "↓  ")..entry.shortName
    detailLbl.TextColor3 = entry.dir=="OUT" and Color3.fromRGB(192,142,255) or Color3.fromRGB(138,212,255)

    -- populate arg rows (Cobalt style: numbered, value, type)
    local ord = 1
    if #entry.args > 0 then
        for i,v in ipairs(entry.args) do
            addArgRow(i, v, ord); ord = ord + 1
        end
    else
        addNoArgsRow(ord); ord = ord + 1
    end
    addCallerRow(entry, ord); ord = ord + 1

    -- code box at bottom
    codeBox.Text = buildCode(entry)

    replayBtn.Visible = (entry.dir=="OUT")
    blockEntBtn.Visible = true; ignEntBtn.Visible = true
    local isBlocked = blockedNames[entry.name]
    blockEntBtn.Text = isBlocked and "✓ Unblock" or "⊘ Block"
    blockEntBtn.BackgroundColor3 = isBlocked and Color3.fromRGB(32,105,42) or Color3.fromRGB(118,30,30)
    local isIgnored = ignoredNames[entry.name]
    ignEntBtn.Text = isIgnored and "● Unignore" or "◎ Ignore"
    ignEntBtn.BackgroundColor3 = isIgnored and Color3.fromRGB(68,45,108) or Color3.fromRGB(38,24,64)
end

-- ── FILTER HELPERS ───────────────────────────────────────────────
local function nameMatch(e)
    if filterTxt=="" then return true end
    return e.name:lower():find(filterTxt:lower(),1,true) ~= nil
end
local function modeMatch(e)
    if filterMode=="ALL"     then return not ignoredNames[e.name] end
    if filterMode=="BLOCKED" then return blockedNames[e.name]==true end
    if filterMode=="IGNORED" then return ignoredNames[e.name]==true end
    return true
end

-- ── BUILD ROW  (compact left-column card) ────────────────────────
local function buildRow(entry, order)
    if entry.rowFrame then entry.rowFrame:Destroy(); entry.rowFrame = nil end
    if not nameMatch(entry) or not modeMatch(entry) then return end

    local isBlocked = blockedNames[entry.name]
    local isIgnored = ignoredNames[entry.name]
    local ri        = remoteIcon(entry)
    local cs        = callerStyle(entry)

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,ITEM_H); row.LayoutOrder = order
    row.BackgroundColor3 = (selectedEntry==entry) and C_SEL or C_ROW
    row.BorderSizePixel = 0; row.ClipsDescendants = true; row.Parent = scroll
    entry.rowFrame = row

    -- left accent bar (type colour)
    local accentBar = Instance.new("Frame"); accentBar.Size = UDim2.new(0,2,1,0)
    accentBar.BackgroundColor3 = isBlocked and Color3.fromRGB(210,46,46)
        or (isIgnored and Color3.fromRGB(50,42,72) or ri.col)
    accentBar.BorderSizePixel = 0; accentBar.Parent = row

    -- remote type icon badge
    local ir, ig, ib = ri.col.R, ri.col.G, ri.col.B
    local iconBg = Instance.new("Frame")
    iconBg.Size = UDim2.new(0,22,0,22); iconBg.Position = UDim2.new(0,6,0.5,-11)
    iconBg.BackgroundColor3 = isBlocked and Color3.fromRGB(94,18,18)
        or Color3.fromRGB(ir*45, ig*45, ib*45)
    iconBg.BackgroundTransparency = 0.15; iconBg.BorderSizePixel = 0; iconBg.Parent = row
    do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,6);c.Parent=iconBg end
    local iconLbl = Instance.new("TextLabel")
    iconLbl.Size = UDim2.new(1,0,1,0); iconLbl.BackgroundTransparency = 1
    iconLbl.Text = isBlocked and "⊘" or (isIgnored and "◎" or ri.icon)
    iconLbl.TextColor3 = isBlocked and Color3.fromRGB(255,80,80)
        or (isIgnored and Color3.fromRGB(90,80,120) or ri.col)
    iconLbl.Font = Enum.Font.GothamBold; iconLbl.TextSize = 12; iconLbl.Parent = iconBg

    -- remote name (line 1)
    local nameCol = isBlocked and Color3.fromRGB(255,90,90)
        or (isIgnored and Color3.fromRGB(84,74,110)
        or (entry.dir=="OUT" and Color3.fromRGB(190,140,255) or Color3.fromRGB(136,210,255)))
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(1,-72,0,16); nameLbl.Position = UDim2.new(0,34,0,3)
    nameLbl.BackgroundTransparency = 1; nameLbl.Text = entry.shortName
    nameLbl.TextColor3 = nameCol; nameLbl.Font = Enum.Font.GothamBold; nameLbl.TextSize = 11
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left; nameLbl.TextTruncate = Enum.TextTruncate.AtEnd; nameLbl.Parent = row

    -- caller type icon + name (line 2)
    if cs then
        local cbg = Instance.new("Frame")
        cbg.Size = UDim2.new(0,24,0,14); cbg.Position = UDim2.new(0,34,0,20)
        cbg.BackgroundColor3 = cs.bg; cbg.BorderSizePixel = 0; cbg.Parent = row
        do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,3);c.Parent=cbg end
        local cIco = Instance.new("TextLabel")
        cIco.Size = UDim2.new(1,0,1,0); cIco.BackgroundTransparency = 1
        cIco.Text = cs.icon; cIco.TextColor3 = cs.fg
        cIco.Font = Enum.Font.GothamBold; cIco.TextSize = 9; cIco.Parent = cbg

        local srcName = (entry.isExecutor and "Executor")
            or (entry.callerSrc ~= "unknown" and entry.callerSrc or "")
        if srcName ~= "" then
            local srcL = Instance.new("TextLabel")
            srcL.Size = UDim2.new(1,-100,0,14); srcL.Position = UDim2.new(0,62,0,20)
            srcL.BackgroundTransparency = 1; srcL.Text = srcName
            srcL.TextColor3 = C_DIM; srcL.Font = Enum.Font.Gotham; srcL.TextSize = 9
            srcL.TextXAlignment = Enum.TextXAlignment.Left; srcL.TextTruncate = Enum.TextTruncate.AtEnd; srcL.Parent = row
        end
    end

    -- burst count badge  x14
    if entry.count > 1 then
        local bg = Instance.new("Frame"); bg.Size = UDim2.new(0,32,0,14); bg.Position = UDim2.new(1,-38,0,3)
        bg.BackgroundColor3 = Color3.fromRGB(86,38,158); bg.BorderSizePixel = 0; bg.Parent = row
        do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,7);c.Parent=bg end
        local cL = Instance.new("TextLabel"); cL.Size = UDim2.new(1,0,1,0); cL.BackgroundTransparency = 1
        cL.Text = "x"..entry.count; cL.TextColor3 = Color3.fromRGB(255,255,255)
        cL.Font = Enum.Font.GothamBold; cL.TextSize = 8; cL.Parent = bg
    end

    -- total fires  ∑N
    local tot = remoteTotals[entry.name] or 0
    if tot > 0 then
        local tbg = Instance.new("Frame"); tbg.Size = UDim2.new(0,36,0,14); tbg.Position = UDim2.new(1,-38,0,19)
        tbg.BackgroundColor3 = Color3.fromRGB(10,48,58); tbg.BorderSizePixel = 0; tbg.Parent = row
        do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,7);c.Parent=tbg end
        local tL2 = Instance.new("TextLabel"); tL2.Size = UDim2.new(1,0,1,0); tL2.BackgroundTransparency = 1
        tL2.Text = "∑ "..tot; tL2.TextColor3 = Color3.fromRGB(60,190,178)
        tL2.Font = Enum.Font.GothamBold; tL2.TextSize = 8; tL2.Parent = tbg
    end

    -- click to select
    local clickZone = Instance.new("TextButton")
    clickZone.Size = UDim2.new(1,0,1,0); clickZone.BackgroundTransparency = 1
    clickZone.Text = ""; clickZone.ZIndex = 0; clickZone.Parent = row
    clickZone.MouseButton1Click:Connect(function() setSelected(entry) end)
end

-- ── REBUILD ALL ──────────────────────────────────────────────────
local function rebuildAll()
    for _,ch in ipairs(scroll:GetChildren()) do
        if not ch:IsA("UIListLayout") then ch:Destroy() end
    end
    local list = lists[activeTab]
    for i,e in ipairs(list) do buildRow(e,i) end
    countLbl.Text = #list.." call"..(#list==1 and "" or "s")
end

-- ── LOG CALL ─────────────────────────────────────────────────────
local function logCall(dir, remote, args, method, callerSrc, callerLine, isExec)
    if paused then return end
    local fullName
    pcall(function() fullName = remote:GetFullName() end)
    fullName = fullName or remote.Name
    remoteTotals[fullName] = (remoteTotals[fullName] or 0) + 1
    if ignoredNames[fullName] and filterMode~="IGNORED" then return end

    local parts={}; for p in fullName:gmatch("[^%.]+") do parts[#parts+1]=p end
    local shortName = #parts>=2 and (parts[#parts-1].."."..parts[#parts]) or (parts[#parts] or remote.Name)
    local now = os.date("*t")
    local timeStr = ("%02d:%02d:%02d"):format(now.hour,now.min,now.sec)
    local list = lists[dir]

    local last = list[#list]
    if last and last.name==fullName and last.method==method then
        last.count = last.count+1; last.timeStr = timeStr; last.args = args
        if last.rowFrame then buildRow(last, #list) end
        if selectedEntry==last then setSelected(last) end
        return
    end

    if #list >= MAX_LOG then
        local oldest = table.remove(list,1)
        if oldest.rowFrame then oldest.rowFrame:Destroy() end
        if selectedEntry==oldest then setSelected(nil) end
    end

    local entry = {
        dir=dir, remote=remote, name=fullName, shortName=shortName,
        method=method, args=args, count=1, timeStr=timeStr,
        callerSrc=callerSrc, callerLine=callerLine, isExecutor=isExec,
        rowFrame=nil,
    }
    table.insert(list, entry)
    if activeTab==dir then
        buildRow(entry, #list)
        countLbl.Text = #list.." call"..(#list==1 and "" or "s")
        task.defer(function()
            scroll.CanvasPosition = Vector2.new(0, scroll.AbsoluteCanvasSize.Y)
        end)
    end
end

-- ── OUTGOING HOOKS ────────────────────────────────────────────────
if hasHookMeta then
    local oldNC
    local hook = function(...)
        local self = ...
        local m = getnamecallmethod()
        if typeof(self)=="Instance" and TargetClasses[self.ClassName] and OutgoingMethods[m] then
            local n; pcall(function() n=self:GetFullName() end); n=n or self.Name
            if blockedNames[n] then return end
            local src,line = getCallerInfo()
            local isExec = hasCheckCall and checkcaller() or false
            task.defer(logCall,"OUT",self,table.pack(select(2,...)),m,src,line,isExec)
        end
        return oldNC(...)
    end
    oldNC = hookmetamethod(game,"__namecall", hasNewCC and newcclosure(hook) or hook)
end

if hasHookFn and not hasHookMeta then
    local function hookMethod(inst, methodName)
        local origFn = inst[methodName]; if not origFn then return end
        hookfunction(origFn, function(self,...)
            if typeof(self)=="Instance" and TargetClasses[self.ClassName] then
                local n; pcall(function() n=self:GetFullName() end); n=n or self.Name
                if blockedNames[n] then return end
                local src,line = getCallerInfo()
                task.defer(logCall,"OUT",self,{...},methodName,src,line,false)
            end
            return origFn(self,...)
        end)
    end
    pcall(function()
        local re=Instance.new("RemoteEvent"); hookMethod(re,"FireServer"); re:Destroy()
        local rf=Instance.new("RemoteFunction"); hookMethod(rf,"InvokeServer"); rf:Destroy()
        local be=Instance.new("BindableEvent"); hookMethod(be,"Fire"); be:Destroy()
        local bf=Instance.new("BindableFunction"); hookMethod(bf,"Invoke"); bf:Destroy()
    end)
end

-- ── INCOMING HOOKS ────────────────────────────────────────────────
local function hookIncoming(remote)
    if hookedIn[remote] then return end
    hookedIn[remote] = true
    if remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent") then
        remote.OnClientEvent:Connect(function(...)
            logCall("IN",remote,{...},"OnClientEvent",nil,-1,false)
        end)
    elseif remote:IsA("BindableEvent") then
        remote.Event:Connect(function(...)
            logCall("IN",remote,{...},"Event",nil,-1,false)
        end)
    end
end

task.spawn(function()
    for _,v in ipairs(game:GetDescendants()) do
        if TargetClasses[v.ClassName] then hookIncoming(v) end
    end
    game.DescendantAdded:Connect(function(v)
        if TargetClasses[v.ClassName] then task.defer(hookIncoming,v) end
    end)
    if getnilinstances then
        for _,v in ipairs(getnilinstances()) do
            if TargetClasses[v.ClassName] then hookIncoming(v) end
        end
    end
end)

-- ── CONTROL HANDLERS ─────────────────────────────────────────────
local function setTab(tab)
    activeTab = tab
    tabOut.BackgroundColor3 = tab=="OUT" and C_ACCENT or Color3.fromRGB(26,14,48)
    tabIn.BackgroundColor3  = tab=="IN"  and Color3.fromRGB(62,24,148) or Color3.fromRGB(26,14,48)
    setSelected(nil); rebuildAll()
end
tabOut.MouseButton1Click:Connect(function() setTab("OUT") end)
tabIn.MouseButton1Click:Connect(function()  setTab("IN")  end)
setTab("OUT")

local function setMode(m)
    filterMode = m
    btnAll.BackgroundColor3     = m=="ALL"     and C_ACCENT              or Color3.fromRGB(30,18,52)
    btnBlocked.BackgroundColor3 = m=="BLOCKED" and Color3.fromRGB(148,40,40) or Color3.fromRGB(30,18,52)
    btnIgnored.BackgroundColor3 = m=="IGNORED" and Color3.fromRGB(108,48,168) or Color3.fromRGB(30,18,52)
    rebuildAll()
end
btnAll.MouseButton1Click:Connect(function()     setMode("ALL")     end)
btnBlocked.MouseButton1Click:Connect(function() setMode("BLOCKED") end)
btnIgnored.MouseButton1Click:Connect(function() setMode("IGNORED") end)
setMode("ALL")

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    filterTxt = searchBox.Text; rebuildAll()
end)

pauseBtn.MouseButton1Click:Connect(function()
    paused = not paused
    pauseBtn.Text = paused and "▶ Resume" or "⏸ Pause"
    pauseBtn.BackgroundColor3 = paused and Color3.fromRGB(32,138,52) or Color3.fromRGB(115,84,18)
end)

clearBtn.MouseButton1Click:Connect(function()
    lists[activeTab] = {}; setSelected(nil); rebuildAll()
end)

copyBtn.MouseButton1Click:Connect(function()
    if not selectedEntry then return end
    pcall(function() setclipboard(buildCode(selectedEntry)) end)
    copyBtn.Text = "✓ Copied"; task.delay(1.5, function() copyBtn.Text = "⎘ Copy" end)
end)

replayBtn.MouseButton1Click:Connect(function()
    if not selectedEntry or selectedEntry.dir~="OUT" then return end
    local r = selectedEntry.remote
    if r and r.Parent then
        pcall(function() r:FireServer(table.unpack(selectedEntry.args)) end)
        replayBtn.Text = "✓ Fired"; task.delay(1.2, function() replayBtn.Text = "↺ Replay" end)
    end
end)

blockEntBtn.MouseButton1Click:Connect(function()
    if not selectedEntry then return end
    local n = selectedEntry.name
    if blockedNames[n] then blockedNames[n]=nil else blockedNames[n]=true end
    setSelected(selectedEntry)
    local list = lists[activeTab]
    for i,e in ipairs(list) do if e==selectedEntry then buildRow(e,i); break end end
end)

ignEntBtn.MouseButton1Click:Connect(function()
    if not selectedEntry then return end
    local n = selectedEntry.name
    if ignoredNames[n] then ignoredNames[n]=nil else ignoredNames[n]=true end
    setSelected(selectedEntry)
    local list = lists[activeTab]
    for i,e in ipairs(list) do if e==selectedEntry then buildRow(e,i); break end end
end)

-- minimize / close
local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    leftPane.Visible = not minimized; rightPane.Visible = not minimized
    main.Size = minimized and UDim2.new(0,W,0,TITLE_H) or UDim2.new(0,W,0,H)
    minBtn.Text = minimized and "+" or "━"
end)
closeBtn.MouseButton1Click:Connect(function()
    main.Visible = false; tBtn.Text = "ϟ  VOLT  ▸"
end)
tBtn.MouseButton1Click:Connect(function()
    main.Visible = not main.Visible
    if main.Visible then
        tBtn.Text = "ϟ  VOLT"; minimized = false; minBtn.Text = "━"
        leftPane.Visible = true; rightPane.Visible = true
        main.Size = UDim2.new(0,W,0,H)
    else
        tBtn.Text = "ϟ  VOLT  ▸"
    end
end)

print(("[Volt] hookMeta:%s hookFn:%s dbgInfo:%s checkcaller:%s"):format(
    tostring(hasHookMeta), tostring(hasHookFn), tostring(hasDbgInfo), tostring(hasCheckCall)))
