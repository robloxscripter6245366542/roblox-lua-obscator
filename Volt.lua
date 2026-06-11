-- Volt  — Network Monitor  (Cobalt-style two-pane layout)
-- Block • Ignore • BindableEvent/Function • UnreliableRemoteEvent
-- Caller info via debug.info • Dual hook • Persistent toggle button

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
    d = d or 0
    if d > 2 then return "…" end
    local t = typeof(v)
    if     t=="nil"      then return "nil"
    elseif t=="boolean"  then return tostring(v)
    elseif t=="number"   then return v==math.floor(v) and tostring(math.floor(v)) or ("%.4g"):format(v)
    elseif t=="string"   then
        local s=v:sub(1,35):gsub("[%c]","·")
        return '"'..s..(#v>35 and "…" or "")..'"'
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
    else return tostring(v):sub(1,22) end
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
        local p={}; for _,v in ipairs(entry.args) do p[#p+1]="    "..codeV(v) end
        local body = #p>0 and ("\n"..table.concat(p,",\n").."\n") or ""
        return "--  INCOMING  ·  "..entry.method.."\n"..
               "--  fired by the server, args:\nlocal args = {"..body.."}"
    end
    local p={}; for _,v in ipairs(entry.args) do p[#p+1]=codeV(v) end
    local argStr = table.concat(p,", ")
    return path..":"..entry.method.."("..argStr..")"
end

-- ── STATE ────────────────────────────────────────────────────────
local MAX_LOG       = 200
local paused        = false
local activeTab     = "OUT"
local filterTxt     = ""
local filterMode    = "ALL"
local lists         = { OUT={}, IN={} }
local remoteTotals  = {}   -- cumulative fire count, survives Clear
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

-- ── REMOTE TYPE ICONS  (Cobalt-style per-type) ───────────────────
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

-- ── GUI CONSTANTS ────────────────────────────────────────────────
local W, H    = 640, 460
local TITLE_H = 34
local LEFT_W  = 252        -- remote-list column width
local ITEM_H  = 38
local TYPE_COLS = {
    string   = Color3.fromRGB(100,200,100), number  = Color3.fromRGB(100,150,240),
    boolean  = Color3.fromRGB(240,180,80),  Instance= Color3.fromRGB(210,130,230),
    Vector3  = Color3.fromRGB(80,220,220),  CFrame  = Color3.fromRGB(230,230,80),
    table    = Color3.fromRGB(240,100,100), ["nil"] = Color3.fromRGB(110,110,110),
}
local function tc(t) return TYPE_COLS[t] or Color3.fromRGB(180,180,180) end

-- ── PERSISTENT TOGGLE BUTTON  (always visible) ───────────────────
local tSg = Instance.new("ScreenGui")
tSg.Name = "VoltToggle"; tSg.ResetOnSpawn = false; tSg.DisplayOrder = 10
tSg.Parent = LocalPlayer:WaitForChild("PlayerGui")

local tBtn = Instance.new("TextButton")
tBtn.Size = UDim2.new(0,86,0,24); tBtn.Position = UDim2.new(0.5,-43,0,6)
tBtn.BackgroundColor3 = Color3.fromRGB(72,30,142); tBtn.BorderSizePixel = 0
tBtn.Text = "ϟ  VOLT"; tBtn.TextColor3 = Color3.fromRGB(215,180,255)
tBtn.Font = Enum.Font.GothamBold; tBtn.TextSize = 11; tBtn.Parent = tSg
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,12);c.Parent=tBtn end
do
    local g=Instance.new("UIGradient")
    g.Color=ColorSequence.new{
        ColorSequenceKeypoint.new(0,Color3.fromRGB(108,46,202)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(56,20,112)),
    }
    g.Rotation=90; g.Parent=tBtn
end
do local s=Instance.new("UIStroke");s.Color=Color3.fromRGB(135,78,215);s.Thickness=1;s.Transparency=0.5;s.Parent=tBtn end

-- ── MAIN WINDOW ──────────────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name = "Volt"; sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = LocalPlayer:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Name = "Main"; main.Size = UDim2.new(0,W,0,H)
main.Position = UDim2.new(0.5,-W/2,0.5,-H/2)
main.BackgroundColor3 = Color3.fromRGB(10,8,16)
main.BorderSizePixel = 0; main.Active = true; main.Draggable = true; main.Parent = sg
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,10);c.Parent=main end
do
    local g=Instance.new("UIGradient")
    g.Color=ColorSequence.new{
        ColorSequenceKeypoint.new(0,Color3.fromRGB(19,12,32)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(8,6,14)),
    }
    g.Rotation=130; g.Parent=main
end
do local s=Instance.new("UIStroke");s.Color=Color3.fromRGB(48,28,80);s.Thickness=1;s.Transparency=0.4;s.Parent=main end

-- title bar ------------------------------------------------------
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1,0,0,TITLE_H)
titleBar.BackgroundColor3 = Color3.fromRGB(22,13,40)
titleBar.BorderSizePixel = 0; titleBar.Parent = main
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,10);c.Parent=titleBar end

local logoBadge = Instance.new("Frame")
logoBadge.Size = UDim2.new(0,26,0,22); logoBadge.Position = UDim2.new(0,6,0.5,-11)
logoBadge.BackgroundColor3 = Color3.fromRGB(105,38,205); logoBadge.BorderSizePixel = 0; logoBadge.Parent = titleBar
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,6);c.Parent=logoBadge end
do
    local g=Instance.new("UIGradient")
    g.Color=ColorSequence.new{
        ColorSequenceKeypoint.new(0,Color3.fromRGB(178,90,255)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(88,22,195)),
    }
    g.Rotation=135; g.Parent=logoBadge
end
local bL=Instance.new("TextLabel"); bL.Size=UDim2.new(1,0,1,0); bL.BackgroundTransparency=1
bL.Text="ϟ"; bL.TextColor3=Color3.fromRGB(255,245,200); bL.Font=Enum.Font.GothamBold; bL.TextSize=14; bL.Parent=logoBadge
do local s=Instance.new("UIStroke");s.Color=Color3.fromRGB(198,138,255);s.Thickness=1;s.Transparency=0.5;s.Parent=logoBadge end

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(0,120,1,0); titleLbl.Position = UDim2.new(0,36,0,0)
titleLbl.BackgroundTransparency = 1
local cap = (hasHookMeta or hasHookFn) and "OUT + IN" or "IN only"
titleLbl.Text = "VOLT"
titleLbl.TextColor3 = Color3.fromRGB(198,152,255); titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 13; titleLbl.TextXAlignment = Enum.TextXAlignment.Left; titleLbl.Parent = titleBar

local capLbl = Instance.new("TextLabel")
capLbl.Size = UDim2.new(0,80,1,0); capLbl.Position = UDim2.new(0,78,0,1)
capLbl.BackgroundTransparency = 1; capLbl.Text = cap
capLbl.TextColor3 = Color3.fromRGB(96,86,128); capLbl.Font = Enum.Font.Gotham
capLbl.TextSize = 10; capLbl.TextXAlignment = Enum.TextXAlignment.Left; capLbl.Parent = titleBar

local function mkWinBtn(xOff, w, txt, col)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0,w,0,22); b.Position = UDim2.new(1,xOff,0.5,-11)
    b.BackgroundColor3 = col; b.BorderSizePixel = 0
    b.Text = txt; b.TextColor3 = Color3.fromRGB(255,255,255)
    b.Font = Enum.Font.GothamBold; b.TextSize = 10; b.Parent = titleBar
    do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,5);c.Parent=b end
    return b
end
local closeBtn = mkWinBtn(-28,  22, "✖",       Color3.fromRGB(162,38,38))
local minBtn   = mkWinBtn(-54,  22, "━",       Color3.fromRGB(42,26,72))
local clearBtn = mkWinBtn(-120, 62, "⌫ Clear", Color3.fromRGB(108,30,30))
local pauseBtn = mkWinBtn(-186, 62, "⏸ Pause", Color3.fromRGB(118,86,20))

-- ════════════════  LEFT PANE : remote list  ════════════════════
local leftPane = Instance.new("Frame")
leftPane.Size = UDim2.new(0,LEFT_W,0,H-TITLE_H); leftPane.Position = UDim2.new(0,0,0,TITLE_H)
leftPane.BackgroundColor3 = Color3.fromRGB(11,8,18); leftPane.BorderSizePixel = 0; leftPane.Parent = main

-- tab row
local function mkTabBtn(x, w, txt)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0,w,0,24); b.Position = UDim2.new(0,x,0,5)
    b.BackgroundColor3 = Color3.fromRGB(28,16,50); b.BorderSizePixel = 0
    b.Text = txt; b.TextColor3 = Color3.fromRGB(215,195,255)
    b.Font = Enum.Font.GothamBold; b.TextSize = 11; b.Parent = leftPane
    do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,6);c.Parent=b end
    return b
end
local tabOut = mkTabBtn(6,   118, "↑  Outgoing")
local tabIn  = mkTabBtn(128, 118, "↓  Incoming")

-- search
local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(0,LEFT_W-12,0,22); searchBox.Position = UDim2.new(0,6,0,34)
searchBox.BackgroundColor3 = Color3.fromRGB(20,14,32); searchBox.BorderSizePixel = 0
searchBox.Text = ""; searchBox.PlaceholderText = "🔍  search remote…"
searchBox.TextColor3 = Color3.fromRGB(215,215,225); searchBox.PlaceholderColor3 = Color3.fromRGB(74,70,96)
searchBox.Font = Enum.Font.Gotham; searchBox.TextSize = 11; searchBox.ClearTextOnFocus = false
searchBox.TextXAlignment = Enum.TextXAlignment.Left; searchBox.Parent = leftPane
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,5);c.Parent=searchBox end
do local pad=Instance.new("UIPadding");pad.PaddingLeft=UDim.new(0,6);pad.Parent=searchBox end

-- mode segmented control
local function mkModeBtn(x, w, txt)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0,w,0,20); b.Position = UDim2.new(0,x,0,60)
    b.BackgroundColor3 = Color3.fromRGB(32,20,54); b.BorderSizePixel = 0
    b.Text = txt; b.TextColor3 = Color3.fromRGB(205,188,240)
    b.Font = Enum.Font.GothamBold; b.TextSize = 10; b.Parent = leftPane
    do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,5);c.Parent=b end
    return b
end
local btnAll     = mkModeBtn(6,   48, "⋮ All")
local btnBlocked = mkModeBtn(58,  90, "⊘ Blocked")
local btnIgnored = mkModeBtn(152, 92, "◎ Ignored")

-- count label
local countLbl = Instance.new("TextLabel")
countLbl.Size = UDim2.new(0,LEFT_W-12,0,14); countLbl.Position = UDim2.new(0,6,0,84)
countLbl.BackgroundTransparency = 1; countLbl.Text = "0 calls"
countLbl.TextColor3 = Color3.fromRGB(78,72,104); countLbl.Font = Enum.Font.Gotham
countLbl.TextSize = 9; countLbl.TextXAlignment = Enum.TextXAlignment.Left; countLbl.Parent = leftPane

-- list scroll
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1,-4,1,-104); scroll.Position = UDim2.new(0,2,0,100)
scroll.BackgroundColor3 = Color3.fromRGB(8,6,13); scroll.BackgroundTransparency = 0.3
scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = Color3.fromRGB(64,54,96)
scroll.CanvasSize = UDim2.new(0,0,0,0); scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = leftPane
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,6);c.Parent=scroll end

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder; listLayout.Padding = UDim.new(0,1); listLayout.Parent = scroll

-- vertical divider
do
    local dv = Instance.new("Frame"); dv.Size = UDim2.new(0,1,1,-TITLE_H-8)
    dv.Position = UDim2.new(0,LEFT_W,0,TITLE_H+4)
    dv.BackgroundColor3 = Color3.fromRGB(40,26,62); dv.BorderSizePixel = 0; dv.Parent = main
end

-- ════════════════  RIGHT PANE : code view  ═════════════════════
local rightPane = Instance.new("Frame")
rightPane.Size = UDim2.new(1,-LEFT_W-1,0,H-TITLE_H); rightPane.Position = UDim2.new(0,LEFT_W+1,0,TITLE_H)
rightPane.BackgroundColor3 = Color3.fromRGB(9,6,15); rightPane.BorderSizePixel = 0; rightPane.Parent = main

-- code header
local codeTop = Instance.new("Frame")
codeTop.Size = UDim2.new(1,0,0,30); codeTop.BackgroundColor3 = Color3.fromRGB(18,11,32)
codeTop.BorderSizePixel = 0; codeTop.Parent = rightPane

local codeTitleLbl = Instance.new("TextLabel")
codeTitleLbl.Size = UDim2.new(1,-220,1,0); codeTitleLbl.Position = UDim2.new(0,10,0,0)
codeTitleLbl.BackgroundTransparency = 1; codeTitleLbl.Text = "⌨  generated code"
codeTitleLbl.TextColor3 = Color3.fromRGB(120,110,168); codeTitleLbl.Font = Enum.Font.GothamMedium
codeTitleLbl.TextSize = 11; codeTitleLbl.TextXAlignment = Enum.TextXAlignment.Left; codeTitleLbl.Parent = codeTop

local function mkCBtn(xOff, w, txt, col)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0,w,0,20); b.Position = UDim2.new(1,xOff,0.5,-10)
    b.BackgroundColor3 = col; b.BorderSizePixel = 0
    b.Text = txt; b.TextColor3 = Color3.fromRGB(255,255,255)
    b.Font = Enum.Font.GothamBold; b.TextSize = 10; b.Parent = codeTop
    do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,5);c.Parent=b end
    return b
end
local copyBtn     = mkCBtn(-58,  52, "⎘ Copy",   Color3.fromRGB(56,38,90))
local ignEntBtn   = mkCBtn(-112, 52, "◎ Ignore", Color3.fromRGB(40,26,66))
local blockEntBtn = mkCBtn(-170, 56, "⊘ Block",  Color3.fromRGB(122,34,34))
local replayBtn   = mkCBtn(-230, 58, "↺ Replay", Color3.fromRGB(80,34,165))
replayBtn.Visible = false; blockEntBtn.Visible = false; ignEntBtn.Visible = false

-- line-number gutter + code box
local gutter = Instance.new("TextLabel")
gutter.Size = UDim2.new(0,30,1,-36); gutter.Position = UDim2.new(0,0,0,34)
gutter.BackgroundColor3 = Color3.fromRGB(13,9,22); gutter.BorderSizePixel = 0
gutter.Text = "1"; gutter.TextColor3 = Color3.fromRGB(64,58,90)
gutter.Font = Enum.Font.Code; gutter.TextSize = 11
gutter.TextXAlignment = Enum.TextXAlignment.Right; gutter.TextYAlignment = Enum.TextYAlignment.Top
gutter.Parent = rightPane
do local pad=Instance.new("UIPadding");pad.PaddingRight=UDim.new(0,5);pad.PaddingTop=UDim.new(0,2);pad.Parent=gutter end

local codeBox = Instance.new("TextBox")
codeBox.Size = UDim2.new(1,-38,1,-40); codeBox.Position = UDim2.new(0,34,0,36)
codeBox.BackgroundTransparency = 1; codeBox.Text = "-- select a remote on the left"
codeBox.TextColor3 = Color3.fromRGB(108,210,130); codeBox.Font = Enum.Font.Code
codeBox.TextSize = 11; codeBox.ClearTextOnFocus = false; codeBox.MultiLine = true
codeBox.TextXAlignment = Enum.TextXAlignment.Left; codeBox.TextYAlignment = Enum.TextYAlignment.Top
codeBox.TextWrapped = true; codeBox.Parent = rightPane

local function setCode(text)
    codeBox.Text = text
    local n = 1
    for _ in text:gmatch("\n") do n = n + 1 end
    local g = table.create(n)
    for i = 1, n do g[i] = tostring(i) end
    gutter.Text = table.concat(g, "\n")
end

-- ── ENTRY SELECTION ──────────────────────────────────────────────
local function setSelected(entry)
    if selectedEntry and selectedEntry.rowFrame then
        selectedEntry.rowFrame.BackgroundColor3 = Color3.fromRGB(14,10,22)
    end
    selectedEntry = entry
    if not entry then
        setCode("-- select a remote on the left")
        codeTitleLbl.Text = "⌨  generated code"
        replayBtn.Visible = false; blockEntBtn.Visible = false; ignEntBtn.Visible = false
        return
    end
    if entry.rowFrame then entry.rowFrame.BackgroundColor3 = Color3.fromRGB(36,18,62) end
    setCode(buildCode(entry))
    codeTitleLbl.Text = (entry.dir=="OUT" and "↑ " or "↓ ")..entry.shortName
    replayBtn.Visible = (entry.dir=="OUT")
    blockEntBtn.Visible = true
    ignEntBtn.Visible = true
    local isBlocked = blockedNames[entry.name]
    blockEntBtn.Text = isBlocked and "✓ Unblock" or "⊘ Block"
    blockEntBtn.BackgroundColor3 = isBlocked and Color3.fromRGB(34,108,44) or Color3.fromRGB(122,34,34)
    local isIgnored = ignoredNames[entry.name]
    ignEntBtn.Text = isIgnored and "● Unignore" or "◎ Ignore"
    ignEntBtn.BackgroundColor3 = isIgnored and Color3.fromRGB(70,48,110) or Color3.fromRGB(40,26,66)
    replayBtn.Text = "↺ Replay"
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

-- ── BUILD ROW  (compact card in the narrow left column) ──────────
local function buildRow(entry, order)
    if entry.rowFrame then entry.rowFrame:Destroy(); entry.rowFrame = nil end
    if not nameMatch(entry) or not modeMatch(entry) then return end

    local isBlocked = blockedNames[entry.name]
    local isIgnored = ignoredNames[entry.name]
    local ri        = remoteIcon(entry)

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,ITEM_H); row.LayoutOrder = order
    row.BackgroundColor3 = (selectedEntry==entry) and Color3.fromRGB(36,18,62) or Color3.fromRGB(14,10,22)
    row.BorderSizePixel = 0; row.ClipsDescendants = true; row.Parent = scroll

    entry.rowFrame = row

    -- left accent bar
    local accentBar = Instance.new("Frame"); accentBar.Size = UDim2.new(0,2,1,0)
    accentBar.BackgroundColor3 = isBlocked and Color3.fromRGB(212,46,46)
        or (isIgnored and Color3.fromRGB(52,44,72) or ri.col)
    accentBar.BorderSizePixel = 0; accentBar.Parent = row

    -- type icon badge
    local ir, ig, ib = ri.col.R, ri.col.G, ri.col.B
    local iconBg = Instance.new("Frame")
    iconBg.Size = UDim2.new(0,22,0,22); iconBg.Position = UDim2.new(0,6,0.5,-11)
    iconBg.BackgroundColor3 = isBlocked and Color3.fromRGB(96,20,20)
        or Color3.fromRGB(ir*46, ig*46, ib*46)
    iconBg.BackgroundTransparency = 0.15; iconBg.BorderSizePixel = 0; iconBg.Parent = row
    do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,6);c.Parent=iconBg end
    local iconLbl = Instance.new("TextLabel")
    iconLbl.Size = UDim2.new(1,0,1,0); iconLbl.BackgroundTransparency = 1
    iconLbl.Text = isBlocked and "⊘" or (isIgnored and "◎" or ri.icon)
    iconLbl.TextColor3 = isBlocked and Color3.fromRGB(255,82,82)
        or (isIgnored and Color3.fromRGB(92,84,120) or ri.col)
    iconLbl.Font = Enum.Font.GothamBold; iconLbl.TextSize = 12; iconLbl.Parent = iconBg

    -- name (line 1)
    local nameCol = isBlocked and Color3.fromRGB(255,92,92)
        or (isIgnored and Color3.fromRGB(86,76,110)
        or (entry.dir=="OUT" and Color3.fromRGB(192,142,255) or Color3.fromRGB(138,212,255)))
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(1,-78,0,16); nameLbl.Position = UDim2.new(0,34,0,4)
    nameLbl.BackgroundTransparency = 1; nameLbl.Text = entry.shortName
    nameLbl.TextColor3 = nameCol; nameLbl.Font = Enum.Font.GothamBold; nameLbl.TextSize = 11
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left; nameLbl.TextTruncate = Enum.TextTruncate.AtEnd; nameLbl.Parent = row

    -- method + caller (line 2)
    local srcTxt = entry.method
    if entry.callerSrc and entry.callerSrc ~= "unknown" then
        srcTxt = srcTxt.."  ·  "..entry.callerSrc
        if entry.callerLine and entry.callerLine > 0 then srcTxt = srcTxt..":"..entry.callerLine end
    end
    if entry.isExecutor then srcTxt = srcTxt.."  [exec]" end
    local srcLbl = Instance.new("TextLabel")
    srcLbl.Size = UDim2.new(1,-78,0,12); srcLbl.Position = UDim2.new(0,34,0,21)
    srcLbl.BackgroundTransparency = 1; srcLbl.Text = srcTxt
    srcLbl.TextColor3 = Color3.fromRGB(70,64,96); srcLbl.Font = Enum.Font.Gotham; srcLbl.TextSize = 9
    srcLbl.TextXAlignment = Enum.TextXAlignment.Left; srcLbl.TextTruncate = Enum.TextTruncate.AtEnd; srcLbl.Parent = row

    -- burst count badge  x14
    if entry.count > 1 then
        local bg = Instance.new("Frame"); bg.Size = UDim2.new(0,32,0,15); bg.Position = UDim2.new(1,-38,0,4)
        bg.BackgroundColor3 = Color3.fromRGB(88,40,160); bg.BorderSizePixel = 0; bg.Parent = row
        do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,7);c.Parent=bg end
        local cL = Instance.new("TextLabel"); cL.Size = UDim2.new(1,0,1,0); cL.BackgroundTransparency = 1
        cL.Text = "x"..entry.count; cL.TextColor3 = Color3.fromRGB(255,255,255)
        cL.Font = Enum.Font.GothamBold; cL.TextSize = 9; cL.Parent = bg
    end

    -- total fires badge  ∑N
    local tot = remoteTotals[entry.name] or 0
    if tot > 0 then
        local tbg = Instance.new("Frame"); tbg.Size = UDim2.new(0,36,0,14); tbg.Position = UDim2.new(1,-38,0,21)
        tbg.BackgroundColor3 = Color3.fromRGB(10,50,60); tbg.BorderSizePixel = 0; tbg.Parent = row
        do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,7);c.Parent=tbg end
        local tL2 = Instance.new("TextLabel"); tL2.Size = UDim2.new(1,0,1,0); tL2.BackgroundTransparency = 1
        tL2.Text = "∑ "..tot; tL2.TextColor3 = Color3.fromRGB(62,192,180)
        tL2.Font = Enum.Font.GothamBold; tL2.TextSize = 8; tL2.Parent = tbg
    end

    -- click to select
    local clickZone = Instance.new("TextButton")
    clickZone.Size = UDim2.new(1,0,1,0); clickZone.BackgroundTransparency = 1
    clickZone.Text = ""; clickZone.Parent = row
    clickZone.ZIndex = 0
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
        if selectedEntry==last then setCode(buildCode(last)) end
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
    local idx = #list

    if activeTab==dir then
        buildRow(entry, idx)
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
        local origFn = inst[methodName]
        if not origFn then return end
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
    tabOut.BackgroundColor3 = tab=="OUT" and Color3.fromRGB(92,40,182) or Color3.fromRGB(28,16,50)
    tabIn.BackgroundColor3  = tab=="IN"  and Color3.fromRGB(65,26,150) or Color3.fromRGB(28,16,50)
    setSelected(nil); rebuildAll()
end
tabOut.MouseButton1Click:Connect(function() setTab("OUT") end)
tabIn.MouseButton1Click:Connect(function()  setTab("IN")  end)
setTab("OUT")

local function setMode(m)
    filterMode = m
    btnAll.BackgroundColor3     = m=="ALL"     and Color3.fromRGB(92,40,182)  or Color3.fromRGB(32,20,54)
    btnBlocked.BackgroundColor3 = m=="BLOCKED" and Color3.fromRGB(150,42,42)  or Color3.fromRGB(32,20,54)
    btnIgnored.BackgroundColor3 = m=="IGNORED" and Color3.fromRGB(110,50,170) or Color3.fromRGB(32,20,54)
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
    pauseBtn.BackgroundColor3 = paused and Color3.fromRGB(34,140,54) or Color3.fromRGB(118,86,20)
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

-- minimize: collapse to the title bar
local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    leftPane.Visible  = not minimized
    rightPane.Visible = not minimized
    main.Size = minimized and UDim2.new(0,W,0,TITLE_H) or UDim2.new(0,W,0,H)
    minBtn.Text = minimized and "+" or "━"
end)

-- close: hide the window (toggle button restores it)
closeBtn.MouseButton1Click:Connect(function()
    main.Visible = false
    tBtn.Text = "ϟ  VOLT  ▸"
end)

-- toggle button: show / hide the window
tBtn.MouseButton1Click:Connect(function()
    main.Visible = not main.Visible
    if main.Visible then
        tBtn.Text = "ϟ  VOLT"
        minimized = false; minBtn.Text = "━"
        leftPane.Visible = true; rightPane.Visible = true
        main.Size = UDim2.new(0,W,0,H)
    else
        tBtn.Text = "ϟ  VOLT  ▸"
    end
end)

print(("[Volt] hookMeta:%s hookFn:%s dbgInfo:%s checkcaller:%s"):format(
    tostring(hasHookMeta), tostring(hasHookFn), tostring(hasDbgInfo), tostring(hasCheckCall)))
