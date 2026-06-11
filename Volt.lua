-- Volt  — Network Monitor
-- Block • Ignore • BindableEvent/Function • UnreliableRemoteEvent
-- Caller source + line via debug.info • Executor-call badge • Dual hook

local Players  = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ───────────────────────────────────────────────────────────────
--  EXECUTOR CAPABILITY CHECK
-- ───────────────────────────────────────────────────────────────
local hasHookMeta  = type(hookmetamethod)  == "function"
local hasHookFn    = type(hookfunction)    == "function"
local hasNewCC     = type(newcclosure)     == "function"
local hasCheckCall = type(checkcaller)     == "function"
local hasDbgInfo   = type(debug) == "table" and type(debug.info) == "function"

-- ───────────────────────────────────────────────────────────────
--  BLOCKED / IGNORED STATE  (keyed by remote full-name string)
-- ───────────────────────────────────────────────────────────────
local blockedNames = {}   -- [fullName] = true  → call is suppressed
local ignoredNames = {}   -- [fullName] = true  → not logged

-- ───────────────────────────────────────────────────────────────
--  CALLER INFO  (best effort via debug.info)
-- ───────────────────────────────────────────────────────────────
local function getCallerInfo()
    if not hasDbgInfo then return "unknown", -1 end
    local base = (hasHookMeta or hasHookFn) and 4 or 2
    for i = base, 12 do
        local src, line = debug.info(i, "sl")
        if not src then break end
        if src ~= "[C]" then
            -- strip long paths, keep last segment
            src = src:match("[^%.%/]+$") or src
            return src, line or -1
        end
    end
    return "unknown", -1
end

-- ───────────────────────────────────────────────────────────────
--  SERIALISER  (compact display)
-- ───────────────────────────────────────────────────────────────
local function fmtV(v, d)
    d = d or 0
    if d > 2 then return "…" end
    local t = typeof(v)
    if     t=="nil"     then return "nil"
    elseif t=="boolean" then return tostring(v)
    elseif t=="number"  then return v==math.floor(v) and tostring(math.floor(v)) or ("%.4g"):format(v)
    elseif t=="string"  then
        local s=v:sub(1,35):gsub("[%c]","·")
        return '"'..s..(#v>35 and "…" or "")..'"'
    elseif t=="Instance"  then return "["..v.ClassName..":"..v.Name.."]"
    elseif t=="Vector3"   then return ("V3(%g,%g,%g)"):format(v.X,v.Y,v.Z)
    elseif t=="Vector2"   then return ("V2(%g,%g)"):format(v.X,v.Y)
    elseif t=="CFrame"    then local p=v.Position; return ("CF(%g,%g,%g)"):format(p.X,p.Y,p.Z)
    elseif t=="Color3"    then return ("RGB(%d,%d,%d)"):format(v.R*255,v.G*255,v.B*255)
    elseif t=="EnumItem"  then return tostring(v)
    elseif t=="table"     then
        local p,i={},0
        for k,u in pairs(v) do
            i=i+1; if i>4 then p[#p+1]="…"; break end
            p[#p+1]=type(k)=="number" and fmtV(u,d+1) or (tostring(k).."="..fmtV(u,d+1))
        end
        return "{"..table.concat(p,",").."}"
    else return tostring(v):sub(1,22) end
end

local function argType(v)
    local t=typeof(v)
    return t=="Instance" and v.ClassName or t
end

-- ───────────────────────────────────────────────────────────────
--  CODE GENERATOR  (full Lua)
-- ───────────────────────────────────────────────────────────────
local function codeV(v, d)
    d=d or 0; if d>3 then return "nil" end
    local t=typeof(v)
    if     t=="nil"     then return "nil"
    elseif t=="boolean" then return tostring(v)
    elseif t=="number"  then return tostring(v)
    elseif t=="string"  then return '"'..v:gsub("\\","\\\\"):gsub('"','\\"'):gsub("\n","\\n")..'"'
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

-- ───────────────────────────────────────────────────────────────
--  STATE
-- ───────────────────────────────────────────────────────────────
local MAX_LOG   = 200
local paused    = false
local activeTab = "OUT"   -- "OUT" | "IN"
local filterTxt = ""
local filterMode= "ALL"   -- "ALL" | "BLOCKED" | "IGNORED"
local lists     = { OUT={}, IN={} }
local hookedIn  = {}
local selectedEntry = nil

-- ───────────────────────────────────────────────────────────────
--  TARGET CLASS LOOKUP
-- ───────────────────────────────────────────────────────────────
local TargetClasses = {
    RemoteEvent=true, RemoteFunction=true,
    UnreliableRemoteEvent=true,
    BindableEvent=true, BindableFunction=true,
}
local OutgoingMethods = {
    FireServer=true, InvokeServer=true,
    fireServer=true, invokeServer=true,
    Fire=true, Invoke=true,
    fire=true, invoke=true,
}

-- ───────────────────────────────────────────────────────────────
--  GUI CONSTANTS
-- ───────────────────────────────────────────────────────────────
local W, H       = 510, 560
local ITEM_H     = 46
local ARG_H      = 20
local LOG_H      = 300
local CODE_Y     = H - 140
local TYPE_COLS  = {
    string=Color3.fromRGB(100,200,100), number=Color3.fromRGB(100,150,240),
    boolean=Color3.fromRGB(240,180,80), Instance=Color3.fromRGB(210,130,230),
    Vector3=Color3.fromRGB(80,220,220), CFrame=Color3.fromRGB(230,230,80),
    table=Color3.fromRGB(240,100,100),  ["nil"]=Color3.fromRGB(110,110,110),
}
local function tc(t) return TYPE_COLS[t] or Color3.fromRGB(180,180,180) end

-- ───────────────────────────────────────────────────────────────
--  GUI BUILD
-- ───────────────────────────────────────────────────────────────
local sg=Instance.new("ScreenGui")
sg.Name="Volt"; sg.ResetOnSpawn=false
sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
sg.Parent=LocalPlayer:WaitForChild("PlayerGui")

local main=Instance.new("Frame")
main.Name="Main"; main.Size=UDim2.new(0,W,0,H)
main.Position=UDim2.new(0.5,-W/2,0.5,-H/2)
main.BackgroundColor3=Color3.fromRGB(13,11,20)
main.BorderSizePixel=0; main.Active=true; main.Draggable=true; main.Parent=sg
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,10);c.Parent=main end

do
    local g=Instance.new("UIGradient")
    g.Color=ColorSequence.new{
        ColorSequenceKeypoint.new(0,Color3.fromRGB(26,18,42)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(11,9,18)),
    }
    g.Rotation=130; g.Parent=main
end

-- Title bar
local titleBar=Instance.new("Frame")
titleBar.Size=UDim2.new(1,0,0,36)
titleBar.BackgroundColor3=Color3.fromRGB(28,16,50); titleBar.BorderSizePixel=0; titleBar.Parent=main
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,10);c.Parent=titleBar end

-- ϟ logo badge
local logoBadge=Instance.new("Frame")
logoBadge.Size=UDim2.new(0,32,0,26); logoBadge.Position=UDim2.new(0,6,0.5,-13)
logoBadge.BackgroundColor3=Color3.fromRGB(130,50,230); logoBadge.BorderSizePixel=0; logoBadge.Parent=titleBar
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,7);c.Parent=logoBadge end
do
    local g=Instance.new("UIGradient")
    g.Color=ColorSequence.new{
        ColorSequenceKeypoint.new(0,Color3.fromRGB(190,100,255)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(100,30,210)),
    }
    g.Rotation=135; g.Parent=logoBadge
end
local boltL=Instance.new("TextLabel"); boltL.Size=UDim2.new(1,0,1,0)
boltL.BackgroundTransparency=1; boltL.Text="ϟ"
boltL.TextColor3=Color3.fromRGB(255,255,220); boltL.Font=Enum.Font.GothamBold
boltL.TextSize=17; boltL.Parent=logoBadge
-- inner glow stroke
do local s=Instance.new("UIStroke");s.Color=Color3.fromRGB(220,160,255);s.Thickness=1;s.Transparency=0.5;s.Parent=logoBadge end

local titleLbl=Instance.new("TextLabel")
titleLbl.Size=UDim2.new(1,-105,1,0); titleLbl.Position=UDim2.new(0,44,0,0)
titleLbl.BackgroundTransparency=1
local cap = hasHookMeta and "OUT+IN" or (hasHookFn and "OUT+IN" or "IN only")
titleLbl.Text="VOLT  ·  "..cap
titleLbl.TextColor3=Color3.fromRGB(210,160,255); titleLbl.Font=Enum.Font.GothamBold
titleLbl.TextSize=13; titleLbl.TextXAlignment=Enum.TextXAlignment.Left; titleLbl.Parent=titleBar

local function mkBtn(par,x,w,txt,col)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,w,0,24); b.Position=UDim2.new(1,x,0.5,-12)
    b.BackgroundColor3=col; b.BorderSizePixel=0
    b.Text=txt; b.TextColor3=Color3.fromRGB(255,255,255)
    b.Font=Enum.Font.GothamBold; b.TextSize=11; b.Parent=par
    do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,6);c.Parent=b end
    return b
end
local closeBtn=mkBtn(titleBar,-30,24,"✖",Color3.fromRGB(180,50,50))
local minBtn  =mkBtn(titleBar,-58,24,"━",Color3.fromRGB(55,35,85))

-- Tab bar
local tabBar=Instance.new("Frame")
tabBar.Size=UDim2.new(1,0,0,30); tabBar.Position=UDim2.new(0,0,0,36)
tabBar.BackgroundColor3=Color3.fromRGB(18,12,30); tabBar.BorderSizePixel=0; tabBar.Parent=main

local tabOut=mkBtn(tabBar,-W+8,100,"↑  Outgoing",Color3.fromRGB(110,50,200))
tabOut.Position=UDim2.new(0,4,0.5,-12)
local tabIn=mkBtn(tabBar,-W+116,90,"↓  Incoming",Color3.fromRGB(40,30,65))
tabIn.Position=UDim2.new(0,108,0.5,-12)

-- mode filter row
local modeBar=Instance.new("Frame")
modeBar.Size=UDim2.new(1,0,0,28); modeBar.Position=UDim2.new(0,0,0,66)
modeBar.BackgroundColor3=Color3.fromRGB(14,10,22); modeBar.BorderSizePixel=0; modeBar.Parent=main

local searchBox=Instance.new("TextBox")
searchBox.Size=UDim2.new(0,150,0,22); searchBox.Position=UDim2.new(0,4,0.5,-11)
searchBox.BackgroundColor3=Color3.fromRGB(24,24,34); searchBox.BorderSizePixel=0
searchBox.Text=""; searchBox.PlaceholderText="search remote…"
searchBox.TextColor3=Color3.fromRGB(220,220,220); searchBox.PlaceholderColor3=Color3.fromRGB(80,80,100)
searchBox.Font=Enum.Font.Gotham; searchBox.TextSize=11; searchBox.ClearTextOnFocus=false
searchBox.Parent=modeBar
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,5);c.Parent=searchBox end

local function mkModeBtn(x,w,txt,col)
    local b=mkBtn(modeBar,0,w,txt,col); b.Position=UDim2.new(0,x,0.5,-11); b.Size=UDim2.new(0,w,0,22); return b
end
local btnAll     = mkModeBtn(158, 38,"⋮ All",    Color3.fromRGB(110,50,200))
local btnBlocked = mkModeBtn(200, 62,"⊘ Blocked",Color3.fromRGB(55,40,75))
local btnIgnored = mkModeBtn(266, 60,"◎ Ignored",Color3.fromRGB(55,40,75))
local pauseBtn   = mkModeBtn(W-128,58,"⏸ Pause",Color3.fromRGB(150,110,30))
local clearBtn   = mkModeBtn(W-66, 60,"⌫ Clear",Color3.fromRGB(130,40,40))

local countLbl=Instance.new("TextLabel")
countLbl.Size=UDim2.new(0,50,1,0); countLbl.Position=UDim2.new(0,323,0,0)
countLbl.BackgroundTransparency=1; countLbl.Text="0"
countLbl.TextColor3=Color3.fromRGB(80,80,100); countLbl.Font=Enum.Font.Gotham
countLbl.TextSize=10; countLbl.TextXAlignment=Enum.TextXAlignment.Left; countLbl.Parent=modeBar

-- scroll
local scroll=Instance.new("ScrollingFrame")
scroll.Size=UDim2.new(1,0,0,LOG_H); scroll.Position=UDim2.new(0,0,0,94)
scroll.BackgroundColor3=Color3.fromRGB(9,7,14); scroll.BorderSizePixel=0
scroll.ScrollBarThickness=3; scroll.ScrollBarImageColor3=Color3.fromRGB(70,70,100)
scroll.CanvasSize=UDim2.new(0,0,0,0); scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
scroll.Parent=main

local listLayout=Instance.new("UIListLayout")
listLayout.SortOrder=Enum.SortOrder.LayoutOrder; listLayout.Padding=UDim.new(0,1); listLayout.Parent=scroll

-- divider
do
    local dv=Instance.new("Frame"); dv.Size=UDim2.new(1,0,0,1)
    dv.Position=UDim2.new(0,0,0,CODE_Y-2)
    dv.BackgroundColor3=Color3.fromRGB(35,35,50); dv.BorderSizePixel=0; dv.Parent=main
end

-- code panel
local codeFrame=Instance.new("Frame")
codeFrame.Size=UDim2.new(1,0,0,H-CODE_Y); codeFrame.Position=UDim2.new(0,0,0,CODE_Y)
codeFrame.BackgroundColor3=Color3.fromRGB(11,8,18); codeFrame.BorderSizePixel=0; codeFrame.Parent=main
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,10);c.Parent=codeFrame end

local codeTop=Instance.new("Frame")
codeTop.Size=UDim2.new(1,0,0,26); codeTop.BackgroundColor3=Color3.fromRGB(24,14,40)
codeTop.BorderSizePixel=0; codeTop.Parent=codeFrame
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=codeTop end

local codeTitleLbl=Instance.new("TextLabel")
codeTitleLbl.Size=UDim2.new(1,-200,1,0); codeTitleLbl.Position=UDim2.new(0,8,0,0)
codeTitleLbl.BackgroundTransparency=1; codeTitleLbl.Text="⌨  Code"
codeTitleLbl.TextColor3=Color3.fromRGB(130,130,180); codeTitleLbl.Font=Enum.Font.Gotham
codeTitleLbl.TextSize=10; codeTitleLbl.TextXAlignment=Enum.TextXAlignment.Left; codeTitleLbl.Parent=codeTop

local replayBtn=mkBtn(codeTop,-196,64,"↺  Replay",Color3.fromRGB(90,40,180))
local blockEntBtn=mkBtn(codeTop,-128,60,"⊘  Block",Color3.fromRGB(160,50,50))
local copyBtn=mkBtn(codeTop,-64,60,"⎘  Copy",Color3.fromRGB(65,45,100))
replayBtn.Visible=false; blockEntBtn.Visible=false

local codeBox=Instance.new("TextBox")
codeBox.Size=UDim2.new(1,-10,0,H-CODE_Y-32); codeBox.Position=UDim2.new(0,5,0,28)
codeBox.BackgroundTransparency=1; codeBox.Text="-- click an entry"
codeBox.TextColor3=Color3.fromRGB(120,210,130); codeBox.Font=Enum.Font.Code
codeBox.TextSize=11; codeBox.ClearTextOnFocus=false; codeBox.MultiLine=true
codeBox.TextXAlignment=Enum.TextXAlignment.Left; codeBox.TextYAlignment=Enum.TextYAlignment.Top
codeBox.TextWrapped=true; codeBox.Parent=codeFrame

-- ───────────────────────────────────────────────────────────────
--  ENTRY SELECTION
-- ───────────────────────────────────────────────────────────────
local function setSelected(entry)
    if selectedEntry and selectedEntry.rowFrame then
        selectedEntry.rowFrame.BackgroundColor3 = Color3.fromRGB(18,18,25)
    end
    selectedEntry = entry
    if not entry then
        codeBox.Text="-- click an entry"
        codeTitleLbl.Text="⌨  Code"
        replayBtn.Visible=false; blockEntBtn.Visible=false
        return
    end
    if entry.rowFrame then entry.rowFrame.BackgroundColor3=Color3.fromRGB(44,24,72) end
    codeBox.Text = buildCode(entry)
    codeTitleLbl.Text = (entry.dir=="OUT" and "↑ " or "↓ ") .. entry.shortName
    replayBtn.Visible = (entry.dir=="OUT")
    blockEntBtn.Visible = true
    local isBlocked = blockedNames[entry.name]
    blockEntBtn.Text = isBlocked and "✓  Unblock" or "⊘  Block"
    blockEntBtn.BackgroundColor3 = isBlocked and Color3.fromRGB(40,120,50) or Color3.fromRGB(160,50,50)
    replayBtn.Text = "↺  Replay"
end

-- ───────────────────────────────────────────────────────────────
--  BUILD ROW
-- ───────────────────────────────────────────────────────────────
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

local function buildRow(entry, order)
    if entry.rowFrame then entry.rowFrame:Destroy(); entry.rowFrame=nil end
    if not nameMatch(entry) or not modeMatch(entry) then return end

    local isBlocked = blockedNames[entry.name]
    local isIgnored = ignoredNames[entry.name]
    local expanded  = entry.expanded
    local argCount  = #entry.args
    local totalH    = ITEM_H + (expanded and math.max(argCount,1)*ARG_H+4 or 0)

    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,totalH); row.LayoutOrder=order
    row.BackgroundColor3 = (selectedEntry==entry) and Color3.fromRGB(44,24,72) or Color3.fromRGB(16,12,24)
    row.BorderSizePixel=0; row.ClipsDescendants=true; row.Parent=scroll
    entry.rowFrame=row

    -- blocked red left bar
    if isBlocked then
        local bar=Instance.new("Frame"); bar.Size=UDim2.new(0,3,1,0)
        bar.BackgroundColor3=Color3.fromRGB(220,60,60); bar.BorderSizePixel=0; bar.Parent=row
    end

    -- lightning icon
    local icon=Instance.new("TextLabel")
    icon.Size=UDim2.new(0,18,0,ITEM_H); icon.Position=UDim2.new(0,6,0,0)
    icon.BackgroundTransparency=1
    icon.Text = isBlocked and "🚫" or (isIgnored and "👁" or "ϟ")
    icon.TextColor3=Color3.fromRGB(190,120,255); icon.Font=Enum.Font.GothamBold
    icon.TextSize=13; icon.Parent=row

    -- name
    local nameLbl=Instance.new("TextLabel")
    nameLbl.Size=UDim2.new(1,-200,0,22); nameLbl.Position=UDim2.new(0,28,0,3)
    nameLbl.BackgroundTransparency=1; nameLbl.Text=entry.shortName
    local nameCol = isBlocked and Color3.fromRGB(255,110,110)
        or (isIgnored and Color3.fromRGB(100,90,120)
        or (entry.dir=="OUT" and Color3.fromRGB(200,150,255) or Color3.fromRGB(150,220,255)))
    nameLbl.TextColor3=nameCol; nameLbl.Font=Enum.Font.GothamBold; nameLbl.TextSize=12
    nameLbl.TextXAlignment=Enum.TextXAlignment.Left; nameLbl.TextTruncate=Enum.TextTruncate.AtEnd; nameLbl.Parent=row

    -- caller source (second line)
    local srcLbl=Instance.new("TextLabel")
    srcLbl.Size=UDim2.new(1,-200,0,14); srcLbl.Position=UDim2.new(0,28,0,26)
    srcLbl.BackgroundTransparency=1
    local srcTxt = entry.method
    if entry.callerSrc and entry.callerSrc~="unknown" then
        srcTxt = srcTxt .. "  ·  " .. entry.callerSrc
        if entry.callerLine and entry.callerLine>0 then
            srcTxt = srcTxt .. ":" .. entry.callerLine
        end
    end
    if entry.isExecutor then srcTxt = srcTxt .. "  [exec]" end
    srcLbl.Text=srcTxt; srcLbl.TextColor3=Color3.fromRGB(80,80,110)
    srcLbl.Font=Enum.Font.Gotham; srcLbl.TextSize=9
    srcLbl.TextXAlignment=Enum.TextXAlignment.Left; srcLbl.TextTruncate=Enum.TextTruncate.AtEnd; srcLbl.Parent=row

    -- count badge
    if entry.count>1 then
        local bg=Instance.new("Frame"); bg.Size=UDim2.new(0,32,0,16); bg.Position=UDim2.new(1,-168,0,5)
        bg.BackgroundColor3=Color3.fromRGB(100,50,180); bg.BorderSizePixel=0; bg.Parent=row
        do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=bg end
        local cL=Instance.new("TextLabel"); cL.Size=UDim2.new(1,0,1,0); cL.BackgroundTransparency=1
        cL.Text="x"..entry.count; cL.TextColor3=Color3.fromRGB(255,255,255)
        cL.Font=Enum.Font.GothamBold; cL.TextSize=9; cL.Parent=bg
    end

    -- timestamp
    local tLbl=Instance.new("TextLabel"); tLbl.Size=UDim2.new(0,60,0,14); tLbl.Position=UDim2.new(1,-125,0,26)
    tLbl.BackgroundTransparency=1; tLbl.Text=entry.timeStr
    tLbl.TextColor3=Color3.fromRGB(70,70,95); tLbl.Font=Enum.Font.Gotham
    tLbl.TextSize=9; tLbl.TextXAlignment=Enum.TextXAlignment.Right; tLbl.Parent=row

    -- per-row action buttons  [▶][🚫][👁][▼]
    local BW,BH=20,20
    local bBase=UDim2.new(1,-BW*4-6,0.5,-BH/2)
    local function mkRowBtn(xOff,txt,col)
        local b=Instance.new("TextButton")
        b.Size=UDim2.new(0,BW,0,BH)
        b.Position=UDim2.new(1,xOff,0.5,-BH/2)
        b.BackgroundColor3=col; b.BorderSizePixel=0
        b.Text=txt; b.TextColor3=Color3.fromRGB(255,255,255)
        b.Font=Enum.Font.GothamBold; b.TextSize=10; b.Parent=row
        do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,4);c.Parent=b end
        return b
    end

    local arrowBtn = mkRowBtn(-4,  expanded and "▴" or "▾", Color3.fromRGB(40,28,65))
    local ignBtn   = mkRowBtn(-28, isIgnored and "●" or "◎", Color3.fromRGB(40,28,65))
    local blkBtn   = mkRowBtn(-52, isBlocked and "✓" or "⊘", isBlocked and Color3.fromRGB(40,110,50) or Color3.fromRGB(140,40,40))
    local cpBtn    = mkRowBtn(-76, "⎘", Color3.fromRGB(65,40,100))

    local replayRowBtn
    if entry.dir=="OUT" then
        replayRowBtn = mkRowBtn(-100, "↺", Color3.fromRGB(90,40,170))
    end

    -- arg rows (expanded)
    if expanded then
        local displayArgs = argCount>0 and entry.args or {nil}
        for i,v in ipairs(displayArgs) do
            local aRow=Instance.new("Frame")
            aRow.Size=UDim2.new(1,-4,0,ARG_H); aRow.Position=UDim2.new(0,2,0,ITEM_H+(i-1)*ARG_H+2)
            aRow.BackgroundColor3=Color3.fromRGB(18,12,28); aRow.BorderSizePixel=0; aRow.Parent=row
            do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,4);c.Parent=aRow end

            local nL=Instance.new("TextLabel"); nL.Size=UDim2.new(0,16,1,0); nL.Position=UDim2.new(0,3,0,0)
            nL.BackgroundTransparency=1; nL.Text=tostring(i); nL.TextColor3=Color3.fromRGB(70,70,95)
            nL.Font=Enum.Font.Gotham; nL.TextSize=10; nL.Parent=aRow

            local vL=Instance.new("TextLabel"); vL.Size=UDim2.new(1,-90,1,0); vL.Position=UDim2.new(0,22,0,0)
            vL.BackgroundTransparency=1; vL.Text=fmtV(v); vL.TextColor3=Color3.fromRGB(210,210,220)
            vL.Font=Enum.Font.Code; vL.TextSize=10; vL.TextXAlignment=Enum.TextXAlignment.Left
            vL.TextTruncate=Enum.TextTruncate.AtEnd; vL.Parent=aRow

            local typ=argType(v)
            local tBg=Instance.new("Frame"); tBg.Size=UDim2.new(0,70,0,14); tBg.Position=UDim2.new(1,-74,0.5,-7)
            tBg.BackgroundColor3=Color3.fromRGB(26,16,40); tBg.BorderSizePixel=0; tBg.Parent=aRow
            do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,4);c.Parent=tBg end
            local tL=Instance.new("TextLabel"); tL.Size=UDim2.new(1,0,1,0); tL.BackgroundTransparency=1
            tL.Text=typ; tL.TextColor3=tc(typ); tL.Font=Enum.Font.GothamBold; tL.TextSize=9; tL.Parent=tBg
        end
    end

    -- click handlers
    local clickZone=Instance.new("TextButton")
    clickZone.Size=UDim2.new(1,-110,0,ITEM_H); clickZone.BackgroundTransparency=1
    clickZone.Text=""; clickZone.Parent=row
    clickZone.MouseButton1Click:Connect(function() setSelected(entry) end)

    arrowBtn.MouseButton1Click:Connect(function()
        entry.expanded = not entry.expanded
        local list=lists[activeTab]
        for i,e in ipairs(list) do if e==entry then buildRow(e,i); break end end
    end)

    blkBtn.MouseButton1Click:Connect(function()
        local n=entry.name
        if blockedNames[n] then blockedNames[n]=nil else blockedNames[n]=true end
        -- rebuild this row and update code panel
        local list=lists[activeTab]
        for i,e in ipairs(list) do if e==entry then buildRow(e,i); break end end
        if selectedEntry==entry then setSelected(entry) end
    end)

    ignBtn.MouseButton1Click:Connect(function()
        local n=entry.name
        if ignoredNames[n] then ignoredNames[n]=nil else ignoredNames[n]=true end
        local list=lists[activeTab]
        for i,e in ipairs(list) do if e==entry then buildRow(e,i); break end end
    end)

    cpBtn.MouseButton1Click:Connect(function()
        pcall(function() setclipboard(buildCode(entry)) end)
        cpBtn.Text="✓"; task.delay(1.2,function() cpBtn.Text="⎘" end)
    end)

    if replayRowBtn then
        replayRowBtn.MouseButton1Click:Connect(function()
            local r=entry.remote
            if r and r.Parent then
                pcall(function() r:FireServer(table.unpack(entry.args)) end)
                replayRowBtn.Text="✓"; task.delay(1,function() replayRowBtn.Text="▶" end)
            end
        end)
    end
end

-- ───────────────────────────────────────────────────────────────
--  REBUILD ALL
-- ───────────────────────────────────────────────────────────────
local function rebuildAll()
    for _, ch in ipairs(scroll:GetChildren()) do
        if not ch:IsA("UIListLayout") then ch:Destroy() end
    end
    local list=lists[activeTab]
    for i,e in ipairs(list) do buildRow(e,i) end
    countLbl.Text=tostring(#list)
end

-- ───────────────────────────────────────────────────────────────
--  LOG CALL
-- ───────────────────────────────────────────────────────────────
local function logCall(dir, remote, args, method, callerSrc, callerLine, isExec)
    if paused then return end
    local fullName
    pcall(function() fullName=remote:GetFullName() end)
    fullName = fullName or remote.Name
    if ignoredNames[fullName] and filterMode~="IGNORED" then return end

    local parts={}; for p in fullName:gmatch("[^%.]+") do parts[#parts+1]=p end
    local shortName=#parts>=2 and (parts[#parts-1].."."..parts[#parts]) or (parts[#parts] or remote.Name)
    local now=os.date("*t")
    local timeStr=("%02d:%02d:%02d"):format(now.hour,now.min,now.sec)
    local list=lists[dir]

    -- group repeats (same remote + same method)
    local last=list[#list]
    if last and last.name==fullName and last.method==method then
        last.count=last.count+1; last.timeStr=timeStr; last.args=args
        -- if args changed, refresh row
        if last.rowFrame then
            local idx=#list; buildRow(last,idx)
        end
        if selectedEntry==last then codeBox.Text=buildCode(last) end
        return
    end

    -- trim oldest
    if #list>=MAX_LOG then
        local oldest=table.remove(list,1)
        if oldest.rowFrame then oldest.rowFrame:Destroy() end
        if selectedEntry==oldest then setSelected(nil) end
    end

    local entry={
        dir=dir, remote=remote, name=fullName, shortName=shortName,
        method=method, args=args, count=1, timeStr=timeStr, expanded=false,
        callerSrc=callerSrc, callerLine=callerLine, isExecutor=isExec,
        rowFrame=nil,
    }
    table.insert(list, entry)
    local idx=#list

    if activeTab==dir then
        buildRow(entry, idx)
        countLbl.Text=tostring(#list)
        task.defer(function()
            scroll.CanvasPosition=Vector2.new(0, scroll.AbsoluteCanvasSize.Y)
        end)
    end
end

-- ───────────────────────────────────────────────────────────────
--  OUTGOING HOOKS
-- ───────────────────────────────────────────────────────────────
-- Primary: hookmetamethod on __namecall
if hasHookMeta then
    local oldNC
    local hook = function(...)
        local self = ...
        local m = getnamecallmethod()
        if typeof(self)=="Instance" and TargetClasses[self.ClassName] and OutgoingMethods[m] then
            local n; pcall(function() n=self:GetFullName() end); n=n or self.Name
            if blockedNames[n] then return end  -- BLOCK the call
            local src, line = getCallerInfo()
            local isExec = hasCheckCall and checkcaller() or false
            task.defer(logCall, "OUT", self, table.pack(select(2,...)), m, src, line, isExec)
        end
        return oldNC(...)
    end
    oldNC = hookmetamethod(game, "__namecall", hasNewCC and newcclosure(hook) or hook)
end

-- Fallback / supplemental: hookfunction on specific method instances
if hasHookFn and not hasHookMeta then
    local function hookMethod(inst, methodName)
        local origFn = inst[methodName]
        if not origFn then return end
        hookfunction(origFn, function(self, ...)
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

-- ───────────────────────────────────────────────────────────────
--  INCOMING HOOKS
-- ───────────────────────────────────────────────────────────────
local function hookIncoming(remote)
    if hookedIn[remote] then return end
    hookedIn[remote]=true
    if remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent") then
        remote.OnClientEvent:Connect(function(...)
            logCall("IN", remote, {...}, "OnClientEvent", nil, -1, false)
        end)
    elseif remote:IsA("BindableEvent") then
        remote.Event:Connect(function(...)
            logCall("IN", remote, {...}, "Event", nil, -1, false)
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
    -- scan nil instances too
    if getnilinstances then
        for _,v in ipairs(getnilinstances()) do
            if TargetClasses[v.ClassName] then hookIncoming(v) end
        end
    end
end)

-- ───────────────────────────────────────────────────────────────
--  CONTROL HANDLERS
-- ───────────────────────────────────────────────────────────────
local function setTab(tab)
    activeTab=tab
    tabOut.BackgroundColor3 = tab=="OUT" and Color3.fromRGB(110,50,200) or Color3.fromRGB(40,28,65)
    tabIn.BackgroundColor3  = tab=="IN"  and Color3.fromRGB(70,30,160)  or Color3.fromRGB(40,28,65)
    tabOut.Text = tab=="OUT" and "↑  Outgoing" or "↑  Outgoing"
    tabIn.Text  = tab=="IN"  and "↓  Incoming" or "↓  Incoming"
    setSelected(nil); rebuildAll()
end
tabOut.MouseButton1Click:Connect(function() setTab("OUT") end)
tabIn.MouseButton1Click:Connect(function()  setTab("IN")  end)
setTab("OUT")

local function setMode(m)
    filterMode=m
    btnAll.BackgroundColor3     = m=="ALL"     and Color3.fromRGB(110,50,200) or Color3.fromRGB(45,32,70)
    btnBlocked.BackgroundColor3 = m=="BLOCKED" and Color3.fromRGB(160,50,50)  or Color3.fromRGB(45,32,70)
    btnIgnored.BackgroundColor3 = m=="IGNORED" and Color3.fromRGB(120,60,180) or Color3.fromRGB(45,32,70)
    btnAll.Text     = "⋮ All"
    btnBlocked.Text = "⊘ Blocked"
    btnIgnored.Text = "◎ Ignored"
    rebuildAll()
end
btnAll.MouseButton1Click:Connect(function()     setMode("ALL")     end)
btnBlocked.MouseButton1Click:Connect(function() setMode("BLOCKED") end)
btnIgnored.MouseButton1Click:Connect(function() setMode("IGNORED") end)
setMode("ALL")

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    filterTxt=searchBox.Text; rebuildAll()
end)

pauseBtn.MouseButton1Click:Connect(function()
    paused=not paused
    pauseBtn.Text=paused and "▶  Resume" or "⏸ Pause"
    pauseBtn.BackgroundColor3=paused and Color3.fromRGB(40,150,60) or Color3.fromRGB(150,110,30)
end)

clearBtn.MouseButton1Click:Connect(function()
    lists[activeTab]={}; setSelected(nil); rebuildAll()
end)

copyBtn.MouseButton1Click:Connect(function()
    if not selectedEntry then return end
    pcall(function() setclipboard(buildCode(selectedEntry)) end)
    copyBtn.Text="✓ Copied!"; task.delay(1.5,function() copyBtn.Text="⎘  Copy" end)
end)

replayBtn.MouseButton1Click:Connect(function()
    if not selectedEntry or selectedEntry.dir~="OUT" then return end
    local r=selectedEntry.remote
    if r and r.Parent then
        pcall(function() r:FireServer(table.unpack(selectedEntry.args)) end)
        replayBtn.Text="✓ Fired!"; task.delay(1.2,function() replayBtn.Text="↺  Replay" end)
    end
end)

blockEntBtn.MouseButton1Click:Connect(function()
    if not selectedEntry then return end
    local n=selectedEntry.name
    if blockedNames[n] then blockedNames[n]=nil else blockedNames[n]=true end
    blockEntBtn.Text = blockedNames[n] and "✓  Unblock" or "⊘  Block"
    setSelected(selectedEntry)  -- refresh UI
    local list=lists[activeTab]
    for i,e in ipairs(list) do if e==selectedEntry then buildRow(e,i); break end end
end)

-- Minimize / Close
local minimized=false
minBtn.MouseButton1Click:Connect(function()
    minimized=not minimized
    main.Size=minimized and UDim2.new(0,W,0,36) or UDim2.new(0,W,0,H)
    minBtn.Text=minimized and "+" or "━"
end)
closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

print(("[Volt] hookMeta:%s hookFn:%s dbgInfo:%s checkcaller:%s"):format(
    tostring(hasHookMeta), tostring(hasHookFn), tostring(hasDbgInfo), tostring(hasCheckCall)))
