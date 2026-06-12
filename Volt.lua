-- Volt  — Network Monitor
-- Cobalt-identical chrome, purple frame
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
    local t = typeof(v); return t=="Instance" and v.ClassName or t
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
    UnreliableRemoteEvent=true, BindableEvent=true, BindableFunction=true,
}
local OutgoingMethods = {
    FireServer=true, InvokeServer=true, fireServer=true, invokeServer=true,
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
    local r=entry.remote; local cls=r and r.ClassName or ""
    return REMOTE_ICON[cls] or { icon="⚡", col=Color3.fromRGB(160,160,160) }
end

-- ── CALLER TYPE ICONS ────────────────────────────────────────────
local CALLER_STYLE = {
    executor = { icon=">_", bg=Color3.fromRGB(110,55,10),  fg=Color3.fromRGB(255,160,65)  },
    module   = { icon="◉",  bg=Color3.fromRGB(18,75,28),   fg=Color3.fromRGB(110,215,88)  },
    local_   = { icon="⊡",  bg=Color3.fromRGB(18,50,108),  fg=Color3.fromRGB(110,175,255) },
    server   = { icon="⬡",  bg=Color3.fromRGB(65,28,108),  fg=Color3.fromRGB(195,138,255) },
    default  = { icon="◈",  bg=Color3.fromRGB(38,28,62),   fg=Color3.fromRGB(168,152,215) },
}
local function callerStyle(entry)
    if entry.isExecutor then return CALLER_STYLE.executor end
    local s = (entry.callerSrc or ""):lower()
    if s:find("module") then return CALLER_STYLE.module end
    if s:find("local")  then return CALLER_STYLE.local_ end
    if s:find("server") then return CALLER_STYLE.server end
    if s~="" and s~="unknown" then return CALLER_STYLE.default end
    return nil
end

-- ── TYPE COLOURS ─────────────────────────────────────────────────
local TYPE_COLS = {
    string=Color3.fromRGB(100,200,100),  number=Color3.fromRGB(100,150,240),
    boolean=Color3.fromRGB(240,180,80),  Instance=Color3.fromRGB(210,130,230),
    Vector3=Color3.fromRGB(80,220,220),  CFrame=Color3.fromRGB(230,230,80),
    table=Color3.fromRGB(240,100,100),   ["nil"]=Color3.fromRGB(110,110,110),
}
local function tc(t) return TYPE_COLS[t] or Color3.fromRGB(180,180,180) end

-- ── PURPLE PALETTE ───────────────────────────────────────────────
local C_WIN     = Color3.fromRGB(18,10,32)   -- window bg
local C_TITLE   = Color3.fromRGB(24,13,44)   -- title bar
local C_TABS    = Color3.fromRGB(20,11,36)   -- tab row
local C_LPANE   = Color3.fromRGB(16,9,28)    -- left pane
local C_RPANE   = Color3.fromRGB(13,7,23)    -- right pane
local C_ROW     = Color3.fromRGB(20,12,34)   -- list row
local C_ROWALT  = Color3.fromRGB(17,10,29)   -- alternate row
local C_SEL     = Color3.fromRGB(46,22,82)   -- selected
local C_ACCENT  = Color3.fromRGB(118,52,218) -- active tab underline / badges
local C_TEXT    = Color3.fromRGB(222,212,252) -- primary text
local C_DIM     = Color3.fromRGB(88,76,118)  -- dim text
local C_BORDER  = Color3.fromRGB(52,28,88)   -- separator lines

-- ── DIMENSIONS ───────────────────────────────────────────────────
local W        = 480
local H        = 340
local TITLE_H  = 28   -- title bar height  (matches Cobalt)
local TAB_H    = 26   -- tab row height
local LEFT_W   = 172  -- left pane width (~36% like Cobalt)
local ITEM_H   = 34   -- list row height

-- ── TOGGLE PILL  (always visible at top of screen) ───────────────
local tSg = Instance.new("ScreenGui")
tSg.Name="VoltToggle"; tSg.ResetOnSpawn=false; tSg.DisplayOrder=10
tSg.Parent=LocalPlayer:WaitForChild("PlayerGui")

local tBtn = Instance.new("TextButton")
tBtn.Size=UDim2.new(0,78,0,22); tBtn.Position=UDim2.new(0.5,-39,0,5)
tBtn.BackgroundColor3=Color3.fromRGB(68,26,138); tBtn.BorderSizePixel=0
tBtn.Text="ϟ  VOLT"; tBtn.TextColor3=C_TEXT
tBtn.Font=Enum.Font.GothamBold; tBtn.TextSize=11; tBtn.Parent=tSg
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,11);c.Parent=tBtn end
do
    local g=Instance.new("UIGradient")
    g.Color=ColorSequence.new{
        ColorSequenceKeypoint.new(0,Color3.fromRGB(105,44,200)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(52,16,108)),
    }
    g.Rotation=90; g.Parent=tBtn
end
do local s=Instance.new("UIStroke");s.Color=Color3.fromRGB(128,68,212);s.Thickness=1;s.Transparency=0.5;s.Parent=tBtn end

-- ── MAIN WINDOW ──────────────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name="Volt"; sg.ResetOnSpawn=false
sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
sg.Parent=LocalPlayer:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Name="Main"; main.Size=UDim2.new(0,W,0,H)
main.Position=UDim2.new(0.5,-W/2,0.5,-H/2)
main.BackgroundColor3=C_WIN; main.BorderSizePixel=0
main.Active=true; main.Draggable=true; main.Parent=sg
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=main end
do local s=Instance.new("UIStroke");s.Color=C_BORDER;s.Thickness=1;s.Transparency=0.3;s.Parent=main end

-- ── TITLE BAR  (bolt-left · VOLT-center · icons-right) ───────────
local titleBar = Instance.new("Frame")
titleBar.Size=UDim2.new(1,0,0,TITLE_H); titleBar.BackgroundColor3=C_TITLE
titleBar.BorderSizePixel=0; titleBar.Parent=main
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=titleBar end

-- bolt badge (far left, matches Cobalt's bolt)
local logoBadge=Instance.new("Frame")
logoBadge.Size=UDim2.new(0,22,0,18); logoBadge.Position=UDim2.new(0,5,0.5,-9)
logoBadge.BackgroundColor3=C_ACCENT; logoBadge.BorderSizePixel=0; logoBadge.Parent=titleBar
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,5);c.Parent=logoBadge end
do
    local g=Instance.new("UIGradient")
    g.Color=ColorSequence.new{
        ColorSequenceKeypoint.new(0,Color3.fromRGB(175,85,255)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(85,18,192)),
    }
    g.Rotation=135; g.Parent=logoBadge
end
local bL=Instance.new("TextLabel"); bL.Size=UDim2.new(1,0,1,0); bL.BackgroundTransparency=1
bL.Text="ϟ"; bL.TextColor3=Color3.fromRGB(255,245,200); bL.Font=Enum.Font.GothamBold; bL.TextSize=12; bL.Parent=logoBadge

-- centered title
local titleLbl=Instance.new("TextLabel")
titleLbl.Size=UDim2.new(1,-160,1,0); titleLbl.Position=UDim2.new(0,30,0,0)
titleLbl.BackgroundTransparency=1; titleLbl.Text="Volt"
titleLbl.TextColor3=C_TEXT; titleLbl.Font=Enum.Font.GothamBold
titleLbl.TextSize=12; titleLbl.TextXAlignment=Enum.TextXAlignment.Center; titleLbl.Parent=titleBar

-- title bar icon buttons (transparent bg, like Cobalt's right-side icons)
local function mkTIcon(xOff, txt, col)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,20,0,20); b.Position=UDim2.new(1,xOff,0.5,-10)
    b.BackgroundTransparency=1; b.BorderSizePixel=0
    b.Text=txt; b.TextColor3=col or C_DIM
    b.Font=Enum.Font.GothamBold; b.TextSize=12; b.Parent=titleBar
    return b
end
local closeBtn  = mkTIcon(-22, "✕", Color3.fromRGB(200,90,90))
local minBtn    = mkTIcon(-44, "─", C_DIM)
local clearBtn  = mkTIcon(-66, "⌫", C_DIM)
local pauseBtn  = mkTIcon(-88, "⏸", C_DIM)
local searchBtn = mkTIcon(-110,"🔍", C_DIM)

-- title bar bottom border
do
    local sep=Instance.new("Frame"); sep.Size=UDim2.new(1,0,0,1); sep.Position=UDim2.new(0,0,1,-1)
    sep.BackgroundColor3=C_BORDER; sep.BorderSizePixel=0; sep.Parent=titleBar
end

-- ── TAB ROW  (flat text + underline, identical to Cobalt) ─────────
local tabBar=Instance.new("Frame")
tabBar.Size=UDim2.new(1,0,0,TAB_H); tabBar.Position=UDim2.new(0,0,0,TITLE_H)
tabBar.BackgroundColor3=C_TABS; tabBar.BorderSizePixel=0; tabBar.Parent=main

-- active tab underline tracker
local tabOutLine, tabInLine

local function mkTab(x, w, txt)
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(0,w,1,-2); btn.Position=UDim2.new(0,x,0,0)
    btn.BackgroundTransparency=1; btn.BorderSizePixel=0
    btn.Text=txt; btn.TextColor3=C_DIM
    btn.Font=Enum.Font.GothamMedium; btn.TextSize=11; btn.Parent=tabBar
    -- underline indicator
    local line=Instance.new("Frame")
    line.Size=UDim2.new(1,0,0,2); line.Position=UDim2.new(0,0,1,-2)
    line.BackgroundColor3=C_ACCENT; line.BorderSizePixel=0; line.Visible=false; line.Parent=btn
    return btn, line
end
local tabOut, _tabOutLine = mkTab(4,   90, "Outgoing")
local tabIn,  _tabInLine  = mkTab(98,  84, "Incoming")
tabOutLine = _tabOutLine; tabInLine = _tabInLine

-- tab row separator
do
    local sep=Instance.new("Frame"); sep.Size=UDim2.new(1,0,0,1); sep.Position=UDim2.new(0,0,1,-1)
    sep.BackgroundColor3=C_BORDER; sep.BorderSizePixel=0; sep.Parent=tabBar
end

-- ── SEARCH BAR  (hidden by default, toggled by 🔍) ───────────────
local SEARCH_H = 26
local searchVisible = false

local searchBar=Instance.new("Frame")
searchBar.Size=UDim2.new(1,0,0,SEARCH_H)
searchBar.Position=UDim2.new(0,0,0,TITLE_H+TAB_H)
searchBar.BackgroundColor3=C_TABS; searchBar.BorderSizePixel=0
searchBar.Visible=false; searchBar.Parent=main

local searchBox=Instance.new("TextBox")
searchBox.Size=UDim2.new(0,LEFT_W-8,0,18); searchBox.Position=UDim2.new(0,4,0.5,-9)
searchBox.BackgroundColor3=Color3.fromRGB(22,12,38); searchBox.BorderSizePixel=0
searchBox.Text=""; searchBox.PlaceholderText="search remote…"
searchBox.TextColor3=C_TEXT; searchBox.PlaceholderColor3=C_DIM
searchBox.Font=Enum.Font.Gotham; searchBox.TextSize=10; searchBox.ClearTextOnFocus=false
searchBox.TextXAlignment=Enum.TextXAlignment.Left; searchBox.Parent=searchBar
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,4);c.Parent=searchBox end
do local p=Instance.new("UIPadding");p.PaddingLeft=UDim.new(0,6);p.Parent=searchBox end

-- filter mode chips (right side of search bar, very compact)
local function mkChip(x, w, txt)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,w,0,18); b.Position=UDim2.new(0,x,0.5,-9)
    b.BackgroundColor3=Color3.fromRGB(28,15,50); b.BorderSizePixel=0
    b.Text=txt; b.TextColor3=C_DIM
    b.Font=Enum.Font.GothamBold; b.TextSize=9; b.Parent=searchBar
    do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,4);c.Parent=b end
    return b
end
local btnAll     = mkChip(LEFT_W+4,  38, "All")
local btnBlocked = mkChip(LEFT_W+46, 52, "Blocked")
local btnIgnored = mkChip(LEFT_W+102,52, "Ignored")

-- ── CONTENT AREA STARTS HERE  (TITLE_H + TAB_H below top) ────────
-- This Y shifts down by SEARCH_H when search is visible
local CONTENT_Y0 = TITLE_H + TAB_H   -- 54

-- ── LEFT PANE ─────────────────────────────────────────────────────
local leftPane=Instance.new("Frame")
leftPane.Size=UDim2.new(0,LEFT_W,0,H-CONTENT_Y0)
leftPane.Position=UDim2.new(0,0,0,CONTENT_Y0)
leftPane.BackgroundColor3=C_LPANE; leftPane.BorderSizePixel=0; leftPane.Parent=main

-- count label (top of left pane, very subtle)
local countLbl=Instance.new("TextLabel")
countLbl.Size=UDim2.new(1,-6,0,14); countLbl.Position=UDim2.new(0,6,0,2)
countLbl.BackgroundTransparency=1; countLbl.Text="0 calls"
countLbl.TextColor3=C_DIM; countLbl.Font=Enum.Font.Gotham
countLbl.TextSize=9; countLbl.TextXAlignment=Enum.TextXAlignment.Left; countLbl.Parent=leftPane

-- remote list scroll
local scroll=Instance.new("ScrollingFrame")
scroll.Size=UDim2.new(1,0,1,-16); scroll.Position=UDim2.new(0,0,0,16)
scroll.BackgroundTransparency=1; scroll.BorderSizePixel=0
scroll.ScrollBarThickness=3; scroll.ScrollBarImageColor3=Color3.fromRGB(60,42,98)
scroll.CanvasSize=UDim2.new(0,0,0,0); scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
scroll.Parent=leftPane

local listLayout=Instance.new("UIListLayout")
listLayout.SortOrder=Enum.SortOrder.LayoutOrder; listLayout.Padding=UDim.new(0,1); listLayout.Parent=scroll

-- ── VERTICAL SEPARATOR ───────────────────────────────────────────
do
    local dv=Instance.new("Frame"); dv.Size=UDim2.new(0,1,0,H-CONTENT_Y0)
    dv.Position=UDim2.new(0,LEFT_W,0,CONTENT_Y0)
    dv.BackgroundColor3=C_BORDER; dv.BorderSizePixel=0; dv.Parent=main
end

-- ── RIGHT PANE ────────────────────────────────────────────────────
local rightPane=Instance.new("Frame")
rightPane.Size=UDim2.new(1,-LEFT_W-1,0,H-CONTENT_Y0)
rightPane.Position=UDim2.new(0,LEFT_W+1,0,CONTENT_Y0)
rightPane.BackgroundColor3=C_RPANE; rightPane.BorderSizePixel=0; rightPane.Parent=main

-- detail header (remote name + action buttons)
local detailBar=Instance.new("Frame")
detailBar.Size=UDim2.new(1,0,0,26); detailBar.BackgroundColor3=Color3.fromRGB(17,9,30)
detailBar.BorderSizePixel=0; detailBar.Parent=rightPane
do
    local sep=Instance.new("Frame"); sep.Size=UDim2.new(1,0,0,1); sep.Position=UDim2.new(0,0,1,-1)
    sep.BackgroundColor3=C_BORDER; sep.BorderSizePixel=0; sep.Parent=detailBar
end

local detailLbl=Instance.new("TextLabel")
detailLbl.Size=UDim2.new(1,-220,1,0); detailLbl.Position=UDim2.new(0,8,0,0)
detailLbl.BackgroundTransparency=1; detailLbl.Text="—"
detailLbl.TextColor3=C_DIM; detailLbl.Font=Enum.Font.GothamMedium
detailLbl.TextSize=10; detailLbl.TextXAlignment=Enum.TextXAlignment.Left; detailLbl.Parent=detailBar

local function mkDBtn(xOff, w, txt, col)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,w,0,18); b.Position=UDim2.new(1,xOff,0.5,-9)
    b.BackgroundColor3=col; b.BorderSizePixel=0
    b.Text=txt; b.TextColor3=C_TEXT
    b.Font=Enum.Font.GothamBold; b.TextSize=9; b.Parent=detailBar
    do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,4);c.Parent=b end
    return b
end
local copyBtn     = mkDBtn(-48,  44, "⎘ Copy",  Color3.fromRGB(50,32,85))
local ignEntBtn   = mkDBtn(-96,  46, "◎ Ignore",Color3.fromRGB(36,20,60))
local blockEntBtn = mkDBtn(-146, 48, "⊘ Block", Color3.fromRGB(112,26,26))
local replayBtn   = mkDBtn(-198, 50, "↺ Replay",Color3.fromRGB(74,28,155))
replayBtn.Visible=false; blockEntBtn.Visible=false; ignEntBtn.Visible=false

-- arg / caller scroll
local argScroll=Instance.new("ScrollingFrame")
argScroll.Size=UDim2.new(1,0,1,-84); argScroll.Position=UDim2.new(0,0,0,26)
argScroll.BackgroundTransparency=1; argScroll.BorderSizePixel=0
argScroll.ScrollBarThickness=3; argScroll.ScrollBarImageColor3=Color3.fromRGB(55,38,88)
argScroll.CanvasSize=UDim2.new(0,0,0,0); argScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
argScroll.Parent=rightPane

local argLayout=Instance.new("UIListLayout")
argLayout.SortOrder=Enum.SortOrder.LayoutOrder; argLayout.Padding=UDim.new(0,0); argLayout.Parent=argScroll

-- horizontal divider above code
do
    local dv=Instance.new("Frame"); dv.Size=UDim2.new(1,0,0,1); dv.Position=UDim2.new(0,0,1,-58)
    dv.BackgroundColor3=C_BORDER; dv.BorderSizePixel=0; dv.Parent=rightPane
end

-- code box (pinned bottom, like Cobalt)
local codeBox=Instance.new("TextBox")
codeBox.Size=UDim2.new(1,-8,0,52); codeBox.Position=UDim2.new(0,4,1,-56)
codeBox.BackgroundTransparency=1; codeBox.Text=""
codeBox.TextColor3=Color3.fromRGB(105,208,128); codeBox.Font=Enum.Font.Code
codeBox.TextSize=10; codeBox.ClearTextOnFocus=false; codeBox.MultiLine=true
codeBox.TextXAlignment=Enum.TextXAlignment.Left; codeBox.TextYAlignment=Enum.TextYAlignment.Top
codeBox.TextWrapped=true; codeBox.Parent=rightPane

-- ── HELPERS: build arg / caller rows ────────────────────────────
local function clearArgScroll()
    for _,c in ipairs(argScroll:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
end

local function addArgRow(lineNum, value, ord)
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,22); row.LayoutOrder=ord
    row.BackgroundColor3=lineNum%2==0 and C_ROWALT or C_RPANE
    row.BorderSizePixel=0; row.Parent=argScroll

    local nL=Instance.new("TextLabel"); nL.Size=UDim2.new(0,26,1,0); nL.BackgroundTransparency=1
    nL.Text=tostring(lineNum); nL.TextColor3=C_DIM
    nL.Font=Enum.Font.Code; nL.TextSize=11; nL.Parent=row

    local typ=argType(value)
    local valCol = typ=="string" and Color3.fromRGB(88,208,198)
        or typ=="number" and Color3.fromRGB(98,148,240)
        or tc(typ)
    local vL=Instance.new("TextLabel"); vL.Size=UDim2.new(1,-106,1,0); vL.Position=UDim2.new(0,28,0,0)
    vL.BackgroundTransparency=1; vL.Text=fmtV(value); vL.TextColor3=valCol
    vL.Font=Enum.Font.Code; vL.TextSize=11
    vL.TextXAlignment=Enum.TextXAlignment.Left; vL.TextTruncate=Enum.TextTruncate.AtEnd; vL.Parent=row

    local tL=Instance.new("TextLabel"); tL.Size=UDim2.new(0,82,1,0); tL.Position=UDim2.new(1,-84,0,0)
    tL.BackgroundTransparency=1; tL.Text=typ; tL.TextColor3=C_DIM
    tL.Font=Enum.Font.Gotham; tL.TextSize=10; tL.TextXAlignment=Enum.TextXAlignment.Right; tL.Parent=row
end

local function addCallerRow(entry, ord)
    local cs=callerStyle(entry)
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,20); row.LayoutOrder=ord
    row.BackgroundColor3=Color3.fromRGB(20,11,36); row.BorderSizePixel=0; row.Parent=argScroll

    if cs then
        local badge=Instance.new("Frame")
        badge.Size=UDim2.new(0,28,0,14); badge.Position=UDim2.new(0,4,0.5,-7)
        badge.BackgroundColor3=cs.bg; badge.BorderSizePixel=0; badge.Parent=row
        do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,3);c.Parent=badge end
        local bL2=Instance.new("TextLabel"); bL2.Size=UDim2.new(1,0,1,0); bL2.BackgroundTransparency=1
        bL2.Text=cs.icon; bL2.TextColor3=cs.fg; bL2.Font=Enum.Font.GothamBold; bL2.TextSize=9; bL2.Parent=badge

        local src=(entry.isExecutor and "Executor") or
            (entry.callerSrc~="unknown" and entry.callerSrc or "unknown")
        if entry.callerLine and entry.callerLine>0 and not entry.isExecutor then
            src=src..":"..entry.callerLine
        end
        local srcL=Instance.new("TextLabel"); srcL.Size=UDim2.new(1,-120,1,0); srcL.Position=UDim2.new(0,36,0,0)
        srcL.BackgroundTransparency=1; srcL.Text=src; srcL.TextColor3=cs.fg
        srcL.Font=Enum.Font.GothamMedium; srcL.TextSize=10
        srcL.TextXAlignment=Enum.TextXAlignment.Left; srcL.Parent=row
    end

    local tL=Instance.new("TextLabel"); tL.Size=UDim2.new(0,88,1,0); tL.Position=UDim2.new(1,-90,0,0)
    tL.BackgroundTransparency=1; tL.Text="Time: "..entry.timeStr; tL.TextColor3=C_DIM
    tL.Font=Enum.Font.Gotham; tL.TextSize=9; tL.TextXAlignment=Enum.TextXAlignment.Right; tL.Parent=row
end

local function addNoArgsRow(ord)
    local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,22); row.LayoutOrder=ord
    row.BackgroundTransparency=1; row.Parent=argScroll
    local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1
    lbl.Text="(no arguments)"; lbl.TextColor3=C_DIM
    lbl.Font=Enum.Font.GothamMedium; lbl.TextSize=10; lbl.Parent=row
end

-- ── ENTRY SELECTION ──────────────────────────────────────────────
local function setSelected(entry)
    if selectedEntry and selectedEntry.rowFrame then
        selectedEntry.rowFrame.BackgroundColor3=C_ROW
    end
    selectedEntry=entry
    clearArgScroll()
    if not entry then
        detailLbl.Text="—"; detailLbl.TextColor3=C_DIM
        codeBox.Text=""
        replayBtn.Visible=false; blockEntBtn.Visible=false; ignEntBtn.Visible=false
        return
    end
    if entry.rowFrame then entry.rowFrame.BackgroundColor3=C_SEL end
    detailLbl.Text=(entry.dir=="OUT" and "↑  " or "↓  ")..entry.shortName
    detailLbl.TextColor3=entry.dir=="OUT" and Color3.fromRGB(190,140,255) or Color3.fromRGB(136,210,255)

    local ord=1
    if #entry.args>0 then
        for i,v in ipairs(entry.args) do addArgRow(i,v,ord); ord=ord+1 end
    else
        addNoArgsRow(ord); ord=ord+1
    end
    addCallerRow(entry,ord)

    codeBox.Text=buildCode(entry)
    replayBtn.Visible=(entry.dir=="OUT")
    blockEntBtn.Visible=true; ignEntBtn.Visible=true
    local isBlocked=blockedNames[entry.name]
    blockEntBtn.Text=isBlocked and "✓ Unblock" or "⊘ Block"
    blockEntBtn.BackgroundColor3=isBlocked and Color3.fromRGB(30,100,40) or Color3.fromRGB(112,26,26)
    local isIgnored=ignoredNames[entry.name]
    ignEntBtn.Text=isIgnored and "● Unign." or "◎ Ignore"
    ignEntBtn.BackgroundColor3=isIgnored and Color3.fromRGB(65,42,105) or Color3.fromRGB(36,20,60)
end

-- ── FILTER HELPERS ───────────────────────────────────────────────
local function nameMatch(e)
    if filterTxt=="" then return true end
    return e.name:lower():find(filterTxt:lower(),1,true)~=nil
end
local function modeMatch(e)
    if filterMode=="ALL"     then return not ignoredNames[e.name] end
    if filterMode=="BLOCKED" then return blockedNames[e.name]==true end
    if filterMode=="IGNORED" then return ignoredNames[e.name]==true end
    return true
end

-- ── BUILD ROW  (compact list entry) ─────────────────────────────
local function buildRow(entry, order)
    if entry.rowFrame then entry.rowFrame:Destroy(); entry.rowFrame=nil end
    if not nameMatch(entry) or not modeMatch(entry) then return end

    local isBlocked=blockedNames[entry.name]
    local isIgnored=ignoredNames[entry.name]
    local ri=remoteIcon(entry)
    local cs=callerStyle(entry)

    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,ITEM_H); row.LayoutOrder=order
    row.BackgroundColor3=(selectedEntry==entry) and C_SEL or C_ROW
    row.BorderSizePixel=0; row.ClipsDescendants=true; row.Parent=scroll
    entry.rowFrame=row

    -- left accent bar
    local accentBar=Instance.new("Frame"); accentBar.Size=UDim2.new(0,2,1,0)
    accentBar.BackgroundColor3=isBlocked and Color3.fromRGB(205,44,44)
        or (isIgnored and Color3.fromRGB(48,40,70) or ri.col)
    accentBar.BorderSizePixel=0; accentBar.Parent=row

    -- type icon badge
    local ir,ig,ib=ri.col.R,ri.col.G,ri.col.B
    local iconBg=Instance.new("Frame")
    iconBg.Size=UDim2.new(0,20,0,20); iconBg.Position=UDim2.new(0,6,0.5,-10)
    iconBg.BackgroundColor3=isBlocked and Color3.fromRGB(90,16,16)
        or Color3.fromRGB(ir*44,ig*44,ib*44)
    iconBg.BackgroundTransparency=0.15; iconBg.BorderSizePixel=0; iconBg.Parent=row
    do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,5);c.Parent=iconBg end
    local iconLbl=Instance.new("TextLabel"); iconLbl.Size=UDim2.new(1,0,1,0); iconLbl.BackgroundTransparency=1
    iconLbl.Text=isBlocked and "⊘" or (isIgnored and "◎" or ri.icon)
    iconLbl.TextColor3=isBlocked and Color3.fromRGB(255,78,78)
        or (isIgnored and Color3.fromRGB(88,78,118) or ri.col)
    iconLbl.Font=Enum.Font.GothamBold; iconLbl.TextSize=11; iconLbl.Parent=iconBg

    -- remote name
    local nameCol=isBlocked and Color3.fromRGB(255,88,88)
        or (isIgnored and Color3.fromRGB(82,72,108)
        or (entry.dir=="OUT" and Color3.fromRGB(188,138,255) or Color3.fromRGB(134,208,255)))
    local nameLbl=Instance.new("TextLabel")
    nameLbl.Size=UDim2.new(1,-70,0,16); nameLbl.Position=UDim2.new(0,32,0,2)
    nameLbl.BackgroundTransparency=1; nameLbl.Text=entry.shortName
    nameLbl.TextColor3=nameCol; nameLbl.Font=Enum.Font.GothamBold; nameLbl.TextSize=11
    nameLbl.TextXAlignment=Enum.TextXAlignment.Left; nameLbl.TextTruncate=Enum.TextTruncate.AtEnd; nameLbl.Parent=row

    -- caller icon + name (second line)
    if cs then
        local cbg=Instance.new("Frame"); cbg.Size=UDim2.new(0,24,0,12); cbg.Position=UDim2.new(0,32,0,19)
        cbg.BackgroundColor3=cs.bg; cbg.BorderSizePixel=0; cbg.Parent=row
        do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,3);c.Parent=cbg end
        local cI=Instance.new("TextLabel"); cI.Size=UDim2.new(1,0,1,0); cI.BackgroundTransparency=1
        cI.Text=cs.icon; cI.TextColor3=cs.fg; cI.Font=Enum.Font.GothamBold; cI.TextSize=8; cI.Parent=cbg

        local srcName=(entry.isExecutor and "Executor") or
            (entry.callerSrc~="unknown" and entry.callerSrc or "")
        if srcName~="" then
            local srcL=Instance.new("TextLabel"); srcL.Size=UDim2.new(1,-100,0,12); srcL.Position=UDim2.new(0,60,0,20)
            srcL.BackgroundTransparency=1; srcL.Text=srcName; srcL.TextColor3=C_DIM
            srcL.Font=Enum.Font.Gotham; srcL.TextSize=9
            srcL.TextXAlignment=Enum.TextXAlignment.Left; srcL.TextTruncate=Enum.TextTruncate.AtEnd; srcL.Parent=row
        end
    end

    -- ×count badge
    if entry.count>1 then
        local bg=Instance.new("Frame"); bg.Size=UDim2.new(0,30,0,13); bg.Position=UDim2.new(1,-36,0,3)
        bg.BackgroundColor3=Color3.fromRGB(82,36,155); bg.BorderSizePixel=0; bg.Parent=row
        do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,6);c.Parent=bg end
        local cL=Instance.new("TextLabel"); cL.Size=UDim2.new(1,0,1,0); cL.BackgroundTransparency=1
        cL.Text="x"..entry.count; cL.TextColor3=Color3.fromRGB(255,255,255)
        cL.Font=Enum.Font.GothamBold; cL.TextSize=8; cL.Parent=bg
    end

    -- ∑ total fires
    local tot=remoteTotals[entry.name] or 0
    if tot>0 then
        local tbg=Instance.new("Frame"); tbg.Size=UDim2.new(0,34,0,13); tbg.Position=UDim2.new(1,-36,0,18)
        tbg.BackgroundColor3=Color3.fromRGB(9,46,56); tbg.BorderSizePixel=0; tbg.Parent=row
        do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,6);c.Parent=tbg end
        local tL2=Instance.new("TextLabel"); tL2.Size=UDim2.new(1,0,1,0); tL2.BackgroundTransparency=1
        tL2.Text="∑"..tot; tL2.TextColor3=Color3.fromRGB(58,188,175)
        tL2.Font=Enum.Font.GothamBold; tL2.TextSize=8; tL2.Parent=tbg
    end

    local click=Instance.new("TextButton"); click.Size=UDim2.new(1,0,1,0)
    click.BackgroundTransparency=1; click.Text=""; click.ZIndex=0; click.Parent=row
    click.MouseButton1Click:Connect(function() setSelected(entry) end)
end

-- ── REBUILD ALL ──────────────────────────────────────────────────
local function rebuildAll()
    for _,ch in ipairs(scroll:GetChildren()) do
        if not ch:IsA("UIListLayout") then ch:Destroy() end
    end
    local list=lists[activeTab]
    for i,e in ipairs(list) do buildRow(e,i) end
    countLbl.Text=#list.." call"..(#list==1 and "" or "s")
end

-- ── RESIZE HELPER (shift content when search bar shown) ───────────
local function applySearchVisible()
    local shift = searchVisible and SEARCH_H or 0
    local y0 = TITLE_H+TAB_H+shift
    leftPane.Position=UDim2.new(0,0,0,y0)
    leftPane.Size=UDim2.new(0,LEFT_W,0,H-y0)
    rightPane.Position=UDim2.new(0,LEFT_W+1,0,y0)
    rightPane.Size=UDim2.new(1,-LEFT_W-1,0,H-y0)
    -- separator
    for _,v in ipairs(main:GetChildren()) do
        if v:IsA("Frame") and v.Size==UDim2.new(0,1,0,H-CONTENT_Y0) then
            v.Size=UDim2.new(0,1,0,H-y0)
            v.Position=UDim2.new(0,LEFT_W,0,y0)
        end
    end
end

-- ── LOG CALL ─────────────────────────────────────────────────────
local function logCall(dir,remote,args,method,callerSrc,callerLine,isExec)
    if paused then return end
    local fullName
    pcall(function() fullName=remote:GetFullName() end)
    fullName=fullName or remote.Name
    remoteTotals[fullName]=(remoteTotals[fullName] or 0)+1
    if ignoredNames[fullName] and filterMode~="IGNORED" then return end

    local parts={}; for p in fullName:gmatch("[^%.]+") do parts[#parts+1]=p end
    local shortName=#parts>=2 and (parts[#parts-1].."."..parts[#parts]) or (parts[#parts] or remote.Name)
    local now=os.date("*t")
    local timeStr=("%02d:%02d:%02d"):format(now.hour,now.min,now.sec)
    local list=lists[dir]

    local last=list[#list]
    if last and last.name==fullName and last.method==method then
        last.count=last.count+1; last.timeStr=timeStr; last.args=args
        if last.rowFrame then buildRow(last,#list) end
        if selectedEntry==last then setSelected(last) end
        return
    end

    if #list>=MAX_LOG then
        local oldest=table.remove(list,1)
        if oldest.rowFrame then oldest.rowFrame:Destroy() end
        if selectedEntry==oldest then setSelected(nil) end
    end

    local entry={
        dir=dir,remote=remote,name=fullName,shortName=shortName,
        method=method,args=args,count=1,timeStr=timeStr,
        callerSrc=callerSrc,callerLine=callerLine,isExecutor=isExec,
        rowFrame=nil,
    }
    table.insert(list,entry)
    if activeTab==dir then
        buildRow(entry,#list)
        countLbl.Text=#list.." call"..(#list==1 and "" or "s")
        task.defer(function()
            scroll.CanvasPosition=Vector2.new(0,scroll.AbsoluteCanvasSize.Y)
        end)
    end
end

-- ── OUTGOING HOOKS ────────────────────────────────────────────────
if hasHookMeta then
    local oldNC
    local hook=function(...)
        local self=...; local m=getnamecallmethod()
        if typeof(self)=="Instance" and TargetClasses[self.ClassName] and OutgoingMethods[m] then
            local n; pcall(function() n=self:GetFullName() end); n=n or self.Name
            if blockedNames[n] then return end
            local src,line=getCallerInfo()
            local isExec=hasCheckCall and checkcaller() or false
            task.defer(logCall,"OUT",self,table.pack(select(2,...)),m,src,line,isExec)
        end
        return oldNC(...)
    end
    oldNC=hookmetamethod(game,"__namecall",hasNewCC and newcclosure(hook) or hook)
end

if hasHookFn and not hasHookMeta then
    local function hookMethod(inst,methodName)
        local origFn=inst[methodName]; if not origFn then return end
        hookfunction(origFn,function(self,...)
            if typeof(self)=="Instance" and TargetClasses[self.ClassName] then
                local n; pcall(function() n=self:GetFullName() end); n=n or self.Name
                if blockedNames[n] then return end
                local src,line=getCallerInfo()
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
    if hookedIn[remote] then return end; hookedIn[remote]=true
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
    activeTab=tab
    tabOut.TextColor3  = tab=="OUT" and C_TEXT or C_DIM
    tabIn.TextColor3   = tab=="IN"  and C_TEXT or C_DIM
    tabOutLine.Visible = (tab=="OUT")
    tabInLine.Visible  = (tab=="IN")
    setSelected(nil); rebuildAll()
end
tabOut.MouseButton1Click:Connect(function() setTab("OUT") end)
tabIn.MouseButton1Click:Connect(function()  setTab("IN")  end)
setTab("OUT")

local function setMode(m)
    filterMode=m
    btnAll.TextColor3     = m=="ALL"     and C_TEXT or C_DIM
    btnBlocked.TextColor3 = m=="BLOCKED" and Color3.fromRGB(255,120,120) or C_DIM
    btnIgnored.TextColor3 = m=="IGNORED" and Color3.fromRGB(180,140,255) or C_DIM
    btnAll.BackgroundColor3     = m=="ALL"     and C_ACCENT              or Color3.fromRGB(28,15,50)
    btnBlocked.BackgroundColor3 = m=="BLOCKED" and Color3.fromRGB(142,36,36) or Color3.fromRGB(28,15,50)
    btnIgnored.BackgroundColor3 = m=="IGNORED" and Color3.fromRGB(105,44,165) or Color3.fromRGB(28,15,50)
    rebuildAll()
end
btnAll.MouseButton1Click:Connect(function()     setMode("ALL")     end)
btnBlocked.MouseButton1Click:Connect(function() setMode("BLOCKED") end)
btnIgnored.MouseButton1Click:Connect(function() setMode("IGNORED") end)
setMode("ALL")

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    filterTxt=searchBox.Text; rebuildAll()
end)

searchBtn.MouseButton1Click:Connect(function()
    searchVisible=not searchVisible
    searchBar.Visible=searchVisible
    searchBtn.TextColor3=searchVisible and C_ACCENT or C_DIM
    applySearchVisible()
end)

pauseBtn.MouseButton1Click:Connect(function()
    paused=not paused
    pauseBtn.Text=paused and "▶" or "⏸"
    pauseBtn.TextColor3=paused and Color3.fromRGB(80,210,110) or C_DIM
end)

clearBtn.MouseButton1Click:Connect(function()
    lists[activeTab]={}; setSelected(nil); rebuildAll()
end)

copyBtn.MouseButton1Click:Connect(function()
    if not selectedEntry then return end
    pcall(function() setclipboard(buildCode(selectedEntry)) end)
    copyBtn.Text="✓ Done"; task.delay(1.5,function() copyBtn.Text="⎘ Copy" end)
end)

replayBtn.MouseButton1Click:Connect(function()
    if not selectedEntry or selectedEntry.dir~="OUT" then return end
    local r=selectedEntry.remote
    if r and r.Parent then
        pcall(function() r:FireServer(table.unpack(selectedEntry.args)) end)
        replayBtn.Text="✓ Fired"; task.delay(1.2,function() replayBtn.Text="↺ Replay" end)
    end
end)

blockEntBtn.MouseButton1Click:Connect(function()
    if not selectedEntry then return end
    local n=selectedEntry.name
    if blockedNames[n] then blockedNames[n]=nil else blockedNames[n]=true end
    setSelected(selectedEntry)
    local list=lists[activeTab]
    for i,e in ipairs(list) do if e==selectedEntry then buildRow(e,i); break end end
end)

ignEntBtn.MouseButton1Click:Connect(function()
    if not selectedEntry then return end
    local n=selectedEntry.name
    if ignoredNames[n] then ignoredNames[n]=nil else ignoredNames[n]=true end
    setSelected(selectedEntry)
    local list=lists[activeTab]
    for i,e in ipairs(list) do if e==selectedEntry then buildRow(e,i); break end end
end)

-- minimize / close
local minimized=false
minBtn.MouseButton1Click:Connect(function()
    minimized=not minimized
    leftPane.Visible=not minimized; rightPane.Visible=not minimized
    searchBar.Visible=false; searchVisible=false
    main.Size=minimized and UDim2.new(0,W,0,TITLE_H) or UDim2.new(0,W,0,H)
    minBtn.Text=minimized and "+" or "─"
end)
closeBtn.MouseButton1Click:Connect(function()
    main.Visible=false; tBtn.Text="ϟ  VOLT  ▸"
end)
tBtn.MouseButton1Click:Connect(function()
    main.Visible=not main.Visible
    if main.Visible then
        tBtn.Text="ϟ  VOLT"; minimized=false; minBtn.Text="─"
        leftPane.Visible=true; rightPane.Visible=true
        main.Size=UDim2.new(0,W,0,H)
    else
        tBtn.Text="ϟ  VOLT  ▸"
    end
end)

print(("[Volt] hookMeta:%s hookFn:%s dbgInfo:%s"):format(
    tostring(hasHookMeta),tostring(hasHookFn),tostring(hasDbgInfo)))
