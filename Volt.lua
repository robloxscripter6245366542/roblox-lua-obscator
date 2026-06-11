-- Volt  — Network Monitor  (Cobalt-inspired layout)
-- Block • Ignore • BindableEvent/Function • UnreliableRemoteEvent
-- Caller info via debug.info • Dual hook • Toggle button (always visible)

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
    local p={}; for _,v in ipairs(entry.args) do p[#p+1]=codeV(v) end
    local argStr=table.concat(p,", ")
    if entry.dir=="IN" then
        return "-- [INCOMING] "..path..".OnClientEvent fired\n-- args: "..argStr
    end
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

-- ── GUI CONSTANTS ────────────────────────────────────────────────
local W, H      = 500, 490
local ITEM_H    = 36
local ARG_H     = 20
local LOG_H     = 268
local CODE_H    = 160
local CODE_Y    = H - CODE_H   -- 330
local TYPE_COLS = {
    string   = Color3.fromRGB(100,200,100), number  = Color3.fromRGB(100,150,240),
    boolean  = Color3.fromRGB(240,180,80),  Instance= Color3.fromRGB(210,130,230),
    Vector3  = Color3.fromRGB(80,220,220),  CFrame  = Color3.fromRGB(230,230,80),
    table    = Color3.fromRGB(240,100,100), ["nil"] = Color3.fromRGB(110,110,110),
}
local function tc(t) return TYPE_COLS[t] or Color3.fromRGB(180,180,180) end

-- ── TOGGLE BUTTON  (always visible — reopens main window) ────────
local tSg = Instance.new("ScreenGui")
tSg.Name = "VoltToggle"; tSg.ResetOnSpawn = false; tSg.DisplayOrder = 10
tSg.Parent = LocalPlayer:WaitForChild("PlayerGui")

local tBtn = Instance.new("TextButton")
tBtn.Size = UDim2.new(0,82,0,24); tBtn.Position = UDim2.new(0.5,-41,0,6)
tBtn.BackgroundColor3 = Color3.fromRGB(72,30,142); tBtn.BorderSizePixel = 0
tBtn.Text = "ϟ  VOLT"; tBtn.TextColor3 = Color3.fromRGB(210,170,255)
tBtn.Font = Enum.Font.GothamBold; tBtn.TextSize = 11; tBtn.Parent = tSg
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,12);c.Parent=tBtn end
do
    local g=Instance.new("UIGradient")
    g.Color=ColorSequence.new{
        ColorSequenceKeypoint.new(0,Color3.fromRGB(105,46,198)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(56,20,112)),
    }
    g.Rotation=90; g.Parent=tBtn
end
do local s=Instance.new("UIStroke");s.Color=Color3.fromRGB(130,72,210);s.Thickness=1;s.Transparency=0.55;s.Parent=tBtn end

-- ── MAIN GUI ─────────────────────────────────────────────────────
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
        ColorSequenceKeypoint.new(0,Color3.fromRGB(20,13,34)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(9,7,15)),
    }
    g.Rotation=130; g.Parent=main
end

-- title bar  (logo + "VOLT" + tabs inline + window controls)
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1,0,0,34)
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
        ColorSequenceKeypoint.new(0,Color3.fromRGB(175,88,255)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(88,22,195)),
    }
    g.Rotation=135; g.Parent=logoBadge
end
local bL=Instance.new("TextLabel"); bL.Size=UDim2.new(1,0,1,0); bL.BackgroundTransparency=1
bL.Text="ϟ"; bL.TextColor3=Color3.fromRGB(255,245,200); bL.Font=Enum.Font.GothamBold; bL.TextSize=14; bL.Parent=logoBadge
do local s=Instance.new("UIStroke");s.Color=Color3.fromRGB(195,135,255);s.Thickness=1;s.Transparency=0.5;s.Parent=logoBadge end

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(0,44,1,0); titleLbl.Position = UDim2.new(0,36,0,0)
titleLbl.BackgroundTransparency = 1; titleLbl.Text = "VOLT"
titleLbl.TextColor3 = Color3.fromRGB(195,150,255); titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 12; titleLbl.TextXAlignment = Enum.TextXAlignment.Left; titleLbl.Parent = titleBar

-- tabs inline in title bar
local function mkTabBtn(x, w, txt, isActive)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0,w,0,24); b.Position = UDim2.new(0,x,0.5,-12)
    b.BackgroundColor3 = isActive and Color3.fromRGB(92,40,182) or Color3.fromRGB(28,16,50)
    b.BorderSizePixel = 0
    b.Text = txt; b.TextColor3 = Color3.fromRGB(215,195,255)
    b.Font = Enum.Font.GothamBold; b.TextSize = 11; b.Parent = titleBar
    do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,6);c.Parent=b end
    return b
end
local tabOut = mkTabBtn(84,  90, "↑  Outgoing", true)
local tabIn  = mkTabBtn(178, 84, "↓  Incoming", false)

-- window controls
local function mkWinBtn(xOff, txt, col)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0,22,0,22); b.Position = UDim2.new(1,xOff,0.5,-11)
    b.BackgroundColor3 = col; b.BorderSizePixel = 0
    b.Text = txt; b.TextColor3 = Color3.fromRGB(255,255,255)
    b.Font = Enum.Font.GothamBold; b.TextSize = 11; b.Parent = titleBar
    do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,5);c.Parent=b end
    return b
end
local closeBtn = mkWinBtn(-28, "✖", Color3.fromRGB(162,38,38))
local minBtn   = mkWinBtn(-54, "━", Color3.fromRGB(42,26,72))

-- filter bar
local filterBar = Instance.new("Frame")
filterBar.Size = UDim2.new(1,0,0,28); filterBar.Position = UDim2.new(0,0,0,34)
filterBar.BackgroundColor3 = Color3.fromRGB(13,9,21); filterBar.BorderSizePixel = 0; filterBar.Parent = main

local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(0,136,0,20); searchBox.Position = UDim2.new(0,4,0.5,-10)
searchBox.BackgroundColor3 = Color3.fromRGB(20,14,32); searchBox.BorderSizePixel = 0
searchBox.Text = ""; searchBox.PlaceholderText = "search remote…"
searchBox.TextColor3 = Color3.fromRGB(215,215,225); searchBox.PlaceholderColor3 = Color3.fromRGB(72,68,92)
searchBox.Font = Enum.Font.Gotham; searchBox.TextSize = 10; searchBox.ClearTextOnFocus = false
searchBox.Parent = filterBar
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,5);c.Parent=searchBox end

local function mkFBtn(x, w, txt, col)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0,w,0,20); b.Position = UDim2.new(0,x,0.5,-10)
    b.BackgroundColor3 = col; b.BorderSizePixel = 0
    b.Text = txt; b.TextColor3 = Color3.fromRGB(215,195,255)
    b.Font = Enum.Font.GothamBold; b.TextSize = 10; b.Parent = filterBar
    do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,5);c.Parent=b end
    return b
end
local btnAll     = mkFBtn(144, 36, "⋮ All",     Color3.fromRGB(92,40,182))
local btnBlocked = mkFBtn(184, 56, "⊘ Blocked", Color3.fromRGB(36,24,60))
local btnIgnored = mkFBtn(244, 56, "◎ Ignored", Color3.fromRGB(36,24,60))
local pauseBtn   = mkFBtn(W-112, 52, "⏸ Pause",  Color3.fromRGB(122,88,20))
local clearBtn   = mkFBtn(W-56,  52, "⌫ Clear",  Color3.fromRGB(112,30,30))

local countLbl = Instance.new("TextLabel")
countLbl.Size = UDim2.new(0,36,1,0); countLbl.Position = UDim2.new(0,304,0,0)
countLbl.BackgroundTransparency = 1; countLbl.Text = "0"
countLbl.TextColor3 = Color3.fromRGB(62,62,88); countLbl.Font = Enum.Font.Gotham
countLbl.TextSize = 10; countLbl.TextXAlignment = Enum.TextXAlignment.Left; countLbl.Parent = filterBar

-- log scroll  (starts at y=62 = 34+28)
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1,0,0,LOG_H); scroll.Position = UDim2.new(0,0,0,62)
scroll.BackgroundColor3 = Color3.fromRGB(8,6,13); scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3; scroll.ScrollBarImageColor3 = Color3.fromRGB(62,52,92)
scroll.CanvasSize = UDim2.new(0,0,0,0); scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = main

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder; listLayout.Padding = UDim.new(0,1); listLayout.Parent = scroll

-- divider
do
    local dv = Instance.new("Frame"); dv.Size = UDim2.new(1,0,0,1)
    dv.Position = UDim2.new(0,0,0,CODE_Y-1)
    dv.BackgroundColor3 = Color3.fromRGB(36,24,56); dv.BorderSizePixel = 0; dv.Parent = main
end

-- code panel
local codeFrame = Instance.new("Frame")
codeFrame.Size = UDim2.new(1,0,0,CODE_H); codeFrame.Position = UDim2.new(0,0,0,CODE_Y)
codeFrame.BackgroundColor3 = Color3.fromRGB(9,6,16); codeFrame.BorderSizePixel = 0; codeFrame.Parent = main
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=codeFrame end

local codeTop = Instance.new("Frame")
codeTop.Size = UDim2.new(1,0,0,28); codeTop.BackgroundColor3 = Color3.fromRGB(18,11,32)
codeTop.BorderSizePixel = 0; codeTop.Parent = codeFrame
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=codeTop end

local codeTitleLbl = Instance.new("TextLabel")
codeTitleLbl.Size = UDim2.new(1,-210,1,0); codeTitleLbl.Position = UDim2.new(0,8,0,0)
codeTitleLbl.BackgroundTransparency = 1; codeTitleLbl.Text = "⌨  Code"
codeTitleLbl.TextColor3 = Color3.fromRGB(112,104,162); codeTitleLbl.Font = Enum.Font.Gotham
codeTitleLbl.TextSize = 10; codeTitleLbl.TextXAlignment = Enum.TextXAlignment.Left; codeTitleLbl.Parent = codeTop

local function mkCBtn(xOff, w, txt, col)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0,w,0,20); b.Position = UDim2.new(1,xOff,0.5,-10)
    b.BackgroundColor3 = col; b.BorderSizePixel = 0
    b.Text = txt; b.TextColor3 = Color3.fromRGB(255,255,255)
    b.Font = Enum.Font.GothamBold; b.TextSize = 10; b.Parent = codeTop
    do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,5);c.Parent=b end
    return b
end
local replayBtn   = mkCBtn(-194, 62, "↺  Replay", Color3.fromRGB(80,34,165))
local blockEntBtn = mkCBtn(-128, 60, "⊘  Block",  Color3.fromRGB(148,40,40))
local copyBtn     = mkCBtn(-64,  60, "⎘  Copy",   Color3.fromRGB(56,38,90))
replayBtn.Visible = false; blockEntBtn.Visible = false

local codeBox = Instance.new("TextBox")
codeBox.Size = UDim2.new(1,-8,0,CODE_H-34); codeBox.Position = UDim2.new(0,4,0,30)
codeBox.BackgroundTransparency = 1; codeBox.Text = "-- click an entry"
codeBox.TextColor3 = Color3.fromRGB(105,206,126); codeBox.Font = Enum.Font.Code
codeBox.TextSize = 10; codeBox.ClearTextOnFocus = false; codeBox.MultiLine = true
codeBox.TextXAlignment = Enum.TextXAlignment.Left; codeBox.TextYAlignment = Enum.TextYAlignment.Top
codeBox.TextWrapped = true; codeBox.Parent = codeFrame

-- ── ENTRY SELECTION ──────────────────────────────────────────────
local function setSelected(entry)
    if selectedEntry and selectedEntry.rowFrame then
        selectedEntry.rowFrame.BackgroundColor3 = Color3.fromRGB(14,10,22)
    end
    selectedEntry = entry
    if not entry then
        codeBox.Text = "-- click an entry"
        codeTitleLbl.Text = "⌨  Code"
        replayBtn.Visible = false; blockEntBtn.Visible = false
        return
    end
    if entry.rowFrame then entry.rowFrame.BackgroundColor3 = Color3.fromRGB(36,18,62) end
    codeBox.Text = buildCode(entry)
    codeTitleLbl.Text = (entry.dir=="OUT" and "↑ " or "↓ ")..entry.shortName
    replayBtn.Visible = (entry.dir=="OUT")
    blockEntBtn.Visible = true
    local isBlocked = blockedNames[entry.name]
    blockEntBtn.Text = isBlocked and "✓  Unblock" or "⊘  Block"
    blockEntBtn.BackgroundColor3 = isBlocked and Color3.fromRGB(36,112,46) or Color3.fromRGB(148,40,40)
    replayBtn.Text = "↺  Replay"
end

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

-- ── BUILD ROW  (Cobalt-style compact) ────────────────────────────
local function buildRow(entry, order)
    if entry.rowFrame then entry.rowFrame:Destroy(); entry.rowFrame = nil end
    if not nameMatch(entry) or not modeMatch(entry) then return end

    local isBlocked = blockedNames[entry.name]
    local isIgnored = ignoredNames[entry.name]
    local expanded  = entry.expanded
    local argCount  = #entry.args
    local totalH    = ITEM_H + (expanded and math.max(argCount,1)*ARG_H+4 or 0)
    local ri        = remoteIcon(entry)

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,totalH); row.LayoutOrder = order
    row.BackgroundColor3 = (selectedEntry==entry) and Color3.fromRGB(36,18,62) or Color3.fromRGB(14,10,22)
    row.BorderSizePixel = 0; row.ClipsDescendants = true; row.Parent = scroll
    entry.rowFrame = row

    -- left accent bar (type colour, dimmed if ignored, red if blocked)
    local accentBar = Instance.new("Frame"); accentBar.Size = UDim2.new(0,2,1,0)
    accentBar.BackgroundColor3 = isBlocked and Color3.fromRGB(212,46,46)
        or (isIgnored and Color3.fromRGB(52,44,72) or ri.col)
    accentBar.BorderSizePixel = 0; accentBar.Parent = row

    -- type icon badge
    local ir, ig, ib = ri.col.R, ri.col.G, ri.col.B
    local iconBg = Instance.new("Frame")
    iconBg.Size = UDim2.new(0,20,0,20); iconBg.Position = UDim2.new(0,6,0.5,-10)
    iconBg.BackgroundColor3 = isBlocked
        and Color3.fromRGB(96,20,20)
        or Color3.fromRGB(ir*46, ig*46, ib*46)
    iconBg.BackgroundTransparency = 0.15; iconBg.BorderSizePixel = 0; iconBg.Parent = row
    do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,5);c.Parent=iconBg end

    local iconLbl = Instance.new("TextLabel")
    iconLbl.Size = UDim2.new(1,0,1,0); iconLbl.BackgroundTransparency = 1
    iconLbl.Text = isBlocked and "⊘" or (isIgnored and "◎" or ri.icon)
    iconLbl.TextColor3 = isBlocked and Color3.fromRGB(255,82,82)
        or (isIgnored and Color3.fromRGB(92,84,120) or ri.col)
    iconLbl.Font = Enum.Font.GothamBold; iconLbl.TextSize = 11; iconLbl.Parent = iconBg

    -- remote name  (line 1)
    local nameCol = isBlocked and Color3.fromRGB(255,92,92)
        or (isIgnored and Color3.fromRGB(86,76,110)
        or (entry.dir=="OUT" and Color3.fromRGB(190,140,255) or Color3.fromRGB(136,210,255)))
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(0,168,0,18); nameLbl.Position = UDim2.new(0,30,0,2)
    nameLbl.BackgroundTransparency = 1; nameLbl.Text = entry.shortName
    nameLbl.TextColor3 = nameCol; nameLbl.Font = Enum.Font.GothamBold; nameLbl.TextSize = 11
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left; nameLbl.TextTruncate = Enum.TextTruncate.AtEnd; nameLbl.Parent = row

    -- method + caller  (line 2)
    local srcTxt = entry.method
    if entry.callerSrc and entry.callerSrc ~= "unknown" then
        srcTxt = srcTxt.."  ·  "..entry.callerSrc
        if entry.callerLine and entry.callerLine > 0 then srcTxt = srcTxt..":"..entry.callerLine end
    end
    if entry.isExecutor then srcTxt = srcTxt.."  [exec]" end
    local srcLbl = Instance.new("TextLabel")
    srcLbl.Size = UDim2.new(0,168,0,14); srcLbl.Position = UDim2.new(0,30,0,20)
    srcLbl.BackgroundTransparency = 1; srcLbl.Text = srcTxt
    srcLbl.TextColor3 = Color3.fromRGB(66,62,92); srcLbl.Font = Enum.Font.Gotham; srcLbl.TextSize = 9
    srcLbl.TextXAlignment = Enum.TextXAlignment.Left; srcLbl.TextTruncate = Enum.TextTruncate.AtEnd; srcLbl.Parent = row

    -- inline args preview (middle column)
    if #entry.args > 0 then
        local parts = {}
        for i=1, math.min(3,#entry.args) do parts[#parts+1] = fmtV(entry.args[i]) end
        if #entry.args > 3 then parts[#parts+1] = "…" end
        local aLbl = Instance.new("TextLabel")
        aLbl.Size = UDim2.new(0,152,0,34); aLbl.Position = UDim2.new(0,202,0,1)
        aLbl.BackgroundTransparency = 1; aLbl.Text = table.concat(parts,"  ")
        aLbl.TextColor3 = Color3.fromRGB(122,122,152); aLbl.Font = Enum.Font.Code; aLbl.TextSize = 9
        aLbl.TextXAlignment = Enum.TextXAlignment.Left; aLbl.TextWrapped = true; aLbl.Parent = row
    end

    -- burst count badge  x14  (purple)
    if entry.count > 1 then
        local bg = Instance.new("Frame"); bg.Size = UDim2.new(0,30,0,14); bg.Position = UDim2.new(1,-140,0,3)
        bg.BackgroundColor3 = Color3.fromRGB(86,40,158); bg.BorderSizePixel = 0; bg.Parent = row
        do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,7);c.Parent=bg end
        local cL = Instance.new("TextLabel"); cL.Size = UDim2.new(1,0,1,0); cL.BackgroundTransparency = 1
        cL.Text = "x"..entry.count; cL.TextColor3 = Color3.fromRGB(255,255,255)
        cL.Font = Enum.Font.GothamBold; cL.TextSize = 8; cL.Parent = bg
    end

    -- total fires badge  ∑N  (teal)
    local tot = remoteTotals[entry.name] or 0
    if tot > 0 then
        local tbg = Instance.new("Frame"); tbg.Size = UDim2.new(0,34,0,14); tbg.Position = UDim2.new(1,-140,0,19)
        tbg.BackgroundColor3 = Color3.fromRGB(10,50,60); tbg.BorderSizePixel = 0; tbg.Parent = row
        do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,7);c.Parent=tbg end
        local tL2 = Instance.new("TextLabel"); tL2.Size = UDim2.new(1,0,1,0); tL2.BackgroundTransparency = 1
        tL2.Text = "∑ "..tot; tL2.TextColor3 = Color3.fromRGB(60,190,178)
        tL2.Font = Enum.Font.GothamBold; tL2.TextSize = 8; tL2.Parent = tbg
    end

    -- timestamp
    local tLbl = Instance.new("TextLabel"); tLbl.Size = UDim2.new(0,52,0,14); tLbl.Position = UDim2.new(1,-102,0,11)
    tLbl.BackgroundTransparency = 1; tLbl.Text = entry.timeStr
    tLbl.TextColor3 = Color3.fromRGB(58,54,82); tLbl.Font = Enum.Font.Gotham
    tLbl.TextSize = 9; tLbl.TextXAlignment = Enum.TextXAlignment.Right; tLbl.Parent = row

    -- row action buttons  (18×18, right-aligned)
    local BW, BH = 18, 18
    local function mkRowBtn(xOff, txt, col)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0,BW,0,BH); b.Position = UDim2.new(1,xOff,0.5,-BH/2)
        b.BackgroundColor3 = col; b.BorderSizePixel = 0
        b.Text = txt; b.TextColor3 = Color3.fromRGB(255,255,255)
        b.Font = Enum.Font.GothamBold; b.TextSize = 9; b.Parent = row
        do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,4);c.Parent=b end
        return b
    end
    local arrowBtn = mkRowBtn(-4,  expanded and "▴" or "▾",           Color3.fromRGB(32,20,52))
    local ignBtn   = mkRowBtn(-26, isIgnored and "●" or "◎",          Color3.fromRGB(32,20,52))
    local blkBtn   = mkRowBtn(-48, isBlocked and "✓" or "⊘",         isBlocked and Color3.fromRGB(30,95,40) or Color3.fromRGB(122,30,30))
    local cpBtn    = mkRowBtn(-70, "⎘",                                 Color3.fromRGB(50,32,85))
    local replayRowBtn
    if entry.dir == "OUT" then
        replayRowBtn = mkRowBtn(-92, "↺", Color3.fromRGB(75,32,148))
    end

    -- expanded arg rows
    if expanded then
        local displayArgs = argCount>0 and entry.args or {nil}
        for i,v in ipairs(displayArgs) do
            local aRow = Instance.new("Frame")
            aRow.Size = UDim2.new(1,-4,0,ARG_H); aRow.Position = UDim2.new(0,2,0,ITEM_H+(i-1)*ARG_H+2)
            aRow.BackgroundColor3 = Color3.fromRGB(14,9,24); aRow.BorderSizePixel = 0; aRow.Parent = row
            do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,4);c.Parent=aRow end

            local nL = Instance.new("TextLabel"); nL.Size = UDim2.new(0,16,1,0); nL.Position = UDim2.new(0,3,0,0)
            nL.BackgroundTransparency = 1; nL.Text = tostring(i); nL.TextColor3 = Color3.fromRGB(60,60,86)
            nL.Font = Enum.Font.Gotham; nL.TextSize = 10; nL.Parent = aRow

            local vL = Instance.new("TextLabel"); vL.Size = UDim2.new(1,-86,1,0); vL.Position = UDim2.new(0,22,0,0)
            vL.BackgroundTransparency = 1; vL.Text = fmtV(v); vL.TextColor3 = Color3.fromRGB(198,198,212)
            vL.Font = Enum.Font.Code; vL.TextSize = 10; vL.TextXAlignment = Enum.TextXAlignment.Left
            vL.TextTruncate = Enum.TextTruncate.AtEnd; vL.Parent = aRow

            local typ = argType(v)
            local tBg = Instance.new("Frame"); tBg.Size = UDim2.new(0,68,0,14); tBg.Position = UDim2.new(1,-72,0.5,-7)
            tBg.BackgroundColor3 = Color3.fromRGB(18,10,30); tBg.BorderSizePixel = 0; tBg.Parent = aRow
            do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,4);c.Parent=tBg end
            local tL = Instance.new("TextLabel"); tL.Size = UDim2.new(1,0,1,0); tL.BackgroundTransparency = 1
            tL.Text = typ; tL.TextColor3 = tc(typ); tL.Font = Enum.Font.GothamBold; tL.TextSize = 9; tL.Parent = tBg
        end
    end

    -- transparent click zone over the name/args area
    local clickZone = Instance.new("TextButton")
    clickZone.Size = UDim2.new(1,-96,0,ITEM_H); clickZone.BackgroundTransparency = 1
    clickZone.Text = ""; clickZone.Parent = row
    clickZone.MouseButton1Click:Connect(function() setSelected(entry) end)

    -- button events
    arrowBtn.MouseButton1Click:Connect(function()
        entry.expanded = not entry.expanded
        local list = lists[activeTab]
        for i,e in ipairs(list) do if e==entry then buildRow(e,i); break end end
    end)
    blkBtn.MouseButton1Click:Connect(function()
        local n = entry.name
        if blockedNames[n] then blockedNames[n]=nil else blockedNames[n]=true end
        local list = lists[activeTab]
        for i,e in ipairs(list) do if e==entry then buildRow(e,i); break end end
        if selectedEntry==entry then setSelected(entry) end
    end)
    ignBtn.MouseButton1Click:Connect(function()
        local n = entry.name
        if ignoredNames[n] then ignoredNames[n]=nil else ignoredNames[n]=true end
        local list = lists[activeTab]
        for i,e in ipairs(list) do if e==entry then buildRow(e,i); break end end
    end)
    cpBtn.MouseButton1Click:Connect(function()
        pcall(function() setclipboard(buildCode(entry)) end)
        cpBtn.Text = "✓"; task.delay(1.2, function() cpBtn.Text = "⎘" end)
    end)
    if replayRowBtn then
        replayRowBtn.MouseButton1Click:Connect(function()
            local r = entry.remote
            if r and r.Parent then
                pcall(function() r:FireServer(table.unpack(entry.args)) end)
                replayRowBtn.Text = "✓"; task.delay(1, function() replayRowBtn.Text = "↺" end)
            end
        end)
    end
end

-- ── REBUILD ALL ──────────────────────────────────────────────────
local function rebuildAll()
    for _,ch in ipairs(scroll:GetChildren()) do
        if not ch:IsA("UIListLayout") then ch:Destroy() end
    end
    local list = lists[activeTab]
    for i,e in ipairs(list) do buildRow(e,i) end
    countLbl.Text = tostring(#list)
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
        if selectedEntry==last then codeBox.Text = buildCode(last) end
        return
    end

    if #list >= MAX_LOG then
        local oldest = table.remove(list,1)
        if oldest.rowFrame then oldest.rowFrame:Destroy() end
        if selectedEntry==oldest then setSelected(nil) end
    end

    local entry = {
        dir=dir, remote=remote, name=fullName, shortName=shortName,
        method=method, args=args, count=1, timeStr=timeStr, expanded=false,
        callerSrc=callerSrc, callerLine=callerLine, isExecutor=isExec,
        rowFrame=nil,
    }
    table.insert(list, entry)
    local idx = #list

    if activeTab==dir then
        buildRow(entry, idx)
        countLbl.Text = tostring(#list)
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
    pauseBtn.Text = paused and "▶  Resume" or "⏸ Pause"
    pauseBtn.BackgroundColor3 = paused and Color3.fromRGB(36,142,55) or Color3.fromRGB(122,88,20)
end)

clearBtn.MouseButton1Click:Connect(function()
    lists[activeTab] = {}; setSelected(nil); rebuildAll()
end)

copyBtn.MouseButton1Click:Connect(function()
    if not selectedEntry then return end
    pcall(function() setclipboard(buildCode(selectedEntry)) end)
    copyBtn.Text = "✓ Copied!"; task.delay(1.5, function() copyBtn.Text = "⎘  Copy" end)
end)

replayBtn.MouseButton1Click:Connect(function()
    if not selectedEntry or selectedEntry.dir~="OUT" then return end
    local r = selectedEntry.remote
    if r and r.Parent then
        pcall(function() r:FireServer(table.unpack(selectedEntry.args)) end)
        replayBtn.Text = "✓ Fired!"; task.delay(1.2, function() replayBtn.Text = "↺  Replay" end)
    end
end)

blockEntBtn.MouseButton1Click:Connect(function()
    if not selectedEntry then return end
    local n = selectedEntry.name
    if blockedNames[n] then blockedNames[n]=nil else blockedNames[n]=true end
    blockEntBtn.Text = blockedNames[n] and "✓  Unblock" or "⊘  Block"
    setSelected(selectedEntry)
    local list = lists[activeTab]
    for i,e in ipairs(list) do if e==selectedEntry then buildRow(e,i); break end end
end)

-- minimize (title bar button) — collapses to just the title bar
local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    main.Size = minimized and UDim2.new(0,W,0,34) or UDim2.new(0,W,0,H)
    minBtn.Text = minimized and "+" or "━"
end)

-- close hides the window (toggle button brings it back)
closeBtn.MouseButton1Click:Connect(function()
    main.Visible = false
    tBtn.Text = "ϟ  VOLT  ▸"
end)

-- toggle button — show / hide main window
tBtn.MouseButton1Click:Connect(function()
    local vis = main.Visible
    main.Visible = not vis
    if main.Visible then
        tBtn.Text = "ϟ  VOLT"
        minimized = false
        main.Size = UDim2.new(0,W,0,H)
    else
        tBtn.Text = "ϟ  VOLT  ▸"
    end
end)

print(("[Volt] hookMeta:%s hookFn:%s dbgInfo:%s checkcaller:%s"):format(
    tostring(hasHookMeta), tostring(hasHookFn), tostring(hasDbgInfo), tostring(hasCheckCall)))
