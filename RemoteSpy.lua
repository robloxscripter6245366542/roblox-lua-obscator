-- Remote Spy  v2  — Cobalt-style
-- Outgoing / Incoming tabs, grouped repeats with counter, arg type labels
-- Click entry to expand args + see code  •  Replay  •  Copy
-- Requires hookmetamethod + getnamecallmethod for outgoing capture

local Players  = game:GetService("Players")
local TweenSvc = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- ───────────────────────────────────────────────────────────────
--  STATE
-- ───────────────────────────────────────────────────────────────
local MAX_LOG  = 150
local paused   = false
local activeTab = "OUT"  -- "OUT" | "IN"
local hasHook  = type(hookmetamethod) == "function"
local hookedIn = {}

-- Separate lists for each tab
local lists = { OUT = {}, IN = {} }
-- Each entry: { remote, name, shortName, method, args, count, lastTime, timeStr, rowFrame, expanded }

-- ───────────────────────────────────────────────────────────────
--  ARG FORMATTERS
-- ───────────────────────────────────────────────────────────────
local function argType(v)
    local t = typeof(v)
    if t == "Instance" then return v.ClassName end
    return t
end

local function argVal(v)
    local t = typeof(v)
    if     t == "nil"     then return "nil"
    elseif t == "boolean" then return tostring(v)
    elseif t == "number"  then
        return v == math.floor(v) and tostring(math.floor(v)) or ("%.4g"):format(v)
    elseif t == "string"  then
        local s = v:sub(1,40):gsub("[%c]","·")
        return '"'..s..(#v>40 and "…" or "")..'"'
    elseif t == "Instance"  then return v:GetFullName()
    elseif t == "Vector3"   then return ("Vector3.new(%g, %g, %g)"):format(v.X,v.Y,v.Z)
    elseif t == "Vector2"   then return ("Vector2.new(%g, %g)"):format(v.X,v.Y)
    elseif t == "CFrame"    then local p=v.Position; return ("CFrame.new(%g, %g, %g)"):format(p.X,p.Y,p.Z)
    elseif t == "Color3"    then return ("Color3.fromRGB(%d, %d, %d)"):format(v.R*255,v.G*255,v.B*255)
    elseif t == "EnumItem"  then return tostring(v)
    elseif t == "table"     then
        local n = 0; for _ in pairs(v) do n=n+1 end
        return "table ["..n.."]"
    else return tostring(v):sub(1,30) end
end

-- full Lua code generation
local function codeVal(v, d)
    d = d or 0
    if d > 3 then return "nil" end
    local t = typeof(v)
    if     t=="nil"     then return "nil"
    elseif t=="boolean" then return tostring(v)
    elseif t=="number"  then return tostring(v)
    elseif t=="string"  then
        return '"'..v:gsub("\\","\\\\"):gsub('"','\\"'):gsub("\n","\\n")..'"'
    elseif t=="Instance" then
        local p=v:GetFullName()
        return p:gsub("^game%.([^%.]+)",function(s) return 'game:GetService("'..s..'")' end)
    elseif t=="Vector3"  then return ("Vector3.new(%g, %g, %g)"):format(v.X,v.Y,v.Z)
    elseif t=="Vector2"  then return ("Vector2.new(%g, %g)"):format(v.X,v.Y)
    elseif t=="CFrame"   then
        local c={v:GetComponents()}; local s={}
        for _,n in ipairs(c) do s[#s+1]=tostring(n) end
        return "CFrame.new("..table.concat(s,", ")..")"
    elseif t=="Color3"   then return ("Color3.fromRGB(%d, %d, %d)"):format(v.R*255,v.G*255,v.B*255)
    elseif t=="UDim2"    then return ("UDim2.new(%g, %g, %g, %g)"):format(v.X.Scale,v.X.Offset,v.Y.Scale,v.Y.Offset)
    elseif t=="EnumItem" then return "Enum."..tostring(v.EnumType).."."..v.Name
    elseif t=="table"    then
        local p={}
        for k,u in pairs(v) do
            if type(k)=="number" then p[#p+1]=codeVal(u,d+1)
            else p[#p+1]='["'..tostring(k)..'"]='..codeVal(u,d+1) end
        end
        return "{"..table.concat(p,", ").."}"
    else return "--[["..t.."]]" end
end

local function buildCode(entry)
    local r = entry.remote
    local path
    if r and r.Parent then
        path = r:GetFullName():gsub("^game%.([^%.]+)",function(s) return 'game:GetService("'..s..'")' end)
    else
        path = "-- (remote destroyed) "..entry.name
    end
    local p={}; for _,v in ipairs(entry.args) do p[#p+1]=codeVal(v) end
    if entry.method == "OnClientEvent" then
        return "-- [INCOMING] "..path..".OnClientEvent\n-- args: "..table.concat(p,", ")
    end
    return path..":"..entry.method.."("..table.concat(p,", ")..")"
end

-- ───────────────────────────────────────────────────────────────
--  GUI CONSTANTS
-- ───────────────────────────────────────────────────────────────
local W, H      = 440, 520
local ITEM_H    = 44   -- collapsed row height
local ARG_H     = 20   -- per-arg row height
local ARG_TYPE_COLORS = {
    string   = Color3.fromRGB(100,180,100),
    number   = Color3.fromRGB(100,140,220),
    boolean  = Color3.fromRGB(220,160,80),
    nil      = Color3.fromRGB(120,120,120),
    Instance = Color3.fromRGB(200,120,200),
    Vector3  = Color3.fromRGB(100,200,200),
    CFrame   = Color3.fromRGB(200,200,100),
    table    = Color3.fromRGB(220,100,100),
}
local function typeColor(t)
    return ARG_TYPE_COLORS[t] or Color3.fromRGB(180,180,180)
end

-- ───────────────────────────────────────────────────────────────
--  GUI CONSTRUCTION
-- ───────────────────────────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name="RemoteSpy2"; sg.ResetOnSpawn=false
sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
sg.Parent=LocalPlayer:WaitForChild("PlayerGui")

local main=Instance.new("Frame")
main.Name="Main"; main.Size=UDim2.new(0,W,0,H)
main.Position=UDim2.new(0.5,-W/2,0.5,-H/2)
main.BackgroundColor3=Color3.fromRGB(22,22,28)
main.BorderSizePixel=0; main.Active=true; main.Draggable=true; main.Parent=sg
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,10);c.Parent=main end

-- Title bar
local titleBar=Instance.new("Frame")
titleBar.Size=UDim2.new(1,0,0,36); titleBar.BackgroundColor3=Color3.fromRGB(30,30,38)
titleBar.BorderSizePixel=0; titleBar.Parent=main
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,10);c.Parent=titleBar end

local titleLbl=Instance.new("TextLabel")
titleLbl.Size=UDim2.new(1,-80,1,0); titleLbl.Position=UDim2.new(0,12,0,0)
titleLbl.BackgroundTransparency=1
titleLbl.Text="⚡  Remote Spy" .. (hasHook and "" or "  (IN only)")
titleLbl.TextColor3=Color3.fromRGB(230,230,230); titleLbl.Font=Enum.Font.GothamBold
titleLbl.TextSize=13; titleLbl.TextXAlignment=Enum.TextXAlignment.Left; titleLbl.Parent=titleBar

local function mkBtn(parent, x, w, txt, col)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,w,0,24); b.Position=UDim2.new(1,x,0.5,-12)
    b.BackgroundColor3=col; b.BorderSizePixel=0
    b.Text=txt; b.TextColor3=Color3.fromRGB(255,255,255)
    b.Font=Enum.Font.GothamBold; b.TextSize=11; b.Parent=parent
    do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,6);c.Parent=b end
    return b
end
local closeBtn=mkBtn(titleBar,-30,24,"✕",Color3.fromRGB(180,50,50))
local minBtn  =mkBtn(titleBar,-58,24,"−",Color3.fromRGB(50,50,65))

-- Tab bar
local tabBar=Instance.new("Frame")
tabBar.Size=UDim2.new(1,0,0,32); tabBar.Position=UDim2.new(0,0,0,36)
tabBar.BackgroundColor3=Color3.fromRGB(18,18,24); tabBar.BorderSizePixel=0; tabBar.Parent=main

local function mkTab(txt, xPct)
    local t=Instance.new("TextButton")
    t.Size=UDim2.new(0.22,0,1,-4); t.Position=UDim2.new(xPct,-2,0,2)
    t.BackgroundColor3=Color3.fromRGB(35,35,45); t.BorderSizePixel=0
    t.Text=txt; t.TextColor3=Color3.fromRGB(200,200,200)
    t.Font=Enum.Font.GothamBold; t.TextSize=12; t.Parent=tabBar
    do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,6);c.Parent=t end
    return t
end
local tabOut = mkTab("Outgoing", 0.01)
local tabIn  = mkTab("Incoming", 0.24)

-- controls row
local ctrlRow=Instance.new("Frame")
ctrlRow.Size=UDim2.new(1,0,0,30); ctrlRow.Position=UDim2.new(0,0,0,68)
ctrlRow.BackgroundColor3=Color3.fromRGB(18,18,24); ctrlRow.BorderSizePixel=0; ctrlRow.Parent=main

local searchBox=Instance.new("TextBox")
searchBox.Size=UDim2.new(0,170,0,22); searchBox.Position=UDim2.new(0,6,0.5,-11)
searchBox.BackgroundColor3=Color3.fromRGB(28,28,38); searchBox.BorderSizePixel=0
searchBox.Text=""; searchBox.PlaceholderText="Search remote…"
searchBox.TextColor3=Color3.fromRGB(220,220,220); searchBox.PlaceholderColor3=Color3.fromRGB(90,90,110)
searchBox.Font=Enum.Font.Gotham; searchBox.TextSize=11; searchBox.ClearTextOnFocus=false
searchBox.Parent=ctrlRow
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,5);c.Parent=searchBox end

local pauseBtn = mkBtn(ctrlRow,-148,60, "⏸ Pause", Color3.fromRGB(160,120,30))
local clearBtn = mkBtn(ctrlRow,-84, 50, "🗑 Clear", Color3.fromRGB(140,40,40))
local countLbl2=Instance.new("TextLabel")
countLbl2.Size=UDim2.new(0,70,1,0); countLbl2.Position=UDim2.new(1,-76,0,0)
countLbl2.BackgroundTransparency=1; countLbl2.Text="0"
countLbl2.TextColor3=Color3.fromRGB(90,90,110); countLbl2.Font=Enum.Font.Gotham
countLbl2.TextSize=10; countLbl2.TextXAlignment=Enum.TextXAlignment.Right; countLbl2.Parent=ctrlRow

local divBar=Instance.new("Frame")
divBar.Size=UDim2.new(1,0,0,1); divBar.Position=UDim2.new(0,0,0,98)
divBar.BackgroundColor3=Color3.fromRGB(38,38,50); divBar.BorderSizePixel=0; divBar.Parent=main

-- scroll frame for entries
local LOG_SCROLL_H = H - 99 - 130
local scroll=Instance.new("ScrollingFrame")
scroll.Size=UDim2.new(1,0,0,LOG_SCROLL_H); scroll.Position=UDim2.new(0,0,0,99)
scroll.BackgroundColor3=Color3.fromRGB(18,18,24); scroll.BorderSizePixel=0
scroll.ScrollBarThickness=3; scroll.ScrollBarImageColor3=Color3.fromRGB(80,80,110)
scroll.CanvasSize=UDim2.new(0,0,0,0); scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
scroll.Parent=main

local layout=Instance.new("UIListLayout")
layout.SortOrder=Enum.SortOrder.LayoutOrder; layout.Padding=UDim.new(0,1); layout.Parent=scroll

-- Code panel at bottom
local CODE_Y = H - 128
local codePanel=Instance.new("Frame")
codePanel.Size=UDim2.new(1,0,0,128); codePanel.Position=UDim2.new(0,0,0,CODE_Y)
codePanel.BackgroundColor3=Color3.fromRGB(14,14,20); codePanel.BorderSizePixel=0; codePanel.Parent=main

local codePanelTop=Instance.new("Frame")
codePanelTop.Size=UDim2.new(1,0,0,26); codePanelTop.BackgroundColor3=Color3.fromRGB(22,22,32)
codePanelTop.BorderSizePixel=0; codePanelTop.Parent=codePanel
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,6);c.Parent=codePanelTop end

local codeTitle=Instance.new("TextLabel")
codeTitle.Size=UDim2.new(1,-180,1,0); codeTitle.Position=UDim2.new(0,8,0,0)
codeTitle.BackgroundTransparency=1; codeTitle.Text="Code"
codeTitle.TextColor3=Color3.fromRGB(140,140,180); codeTitle.Font=Enum.Font.Gotham
codeTitle.TextSize=10; codeTitle.TextXAlignment=Enum.TextXAlignment.Left; codeTitle.Parent=codePanelTop

local replayBtn=mkBtn(codePanelTop,-172,70,"▶ Replay",Color3.fromRGB(35,90,180))
local copyBtn  =mkBtn(codePanelTop,-98, 64,"📋 Copy", Color3.fromRGB(55,55,80))
replayBtn.Visible=false

local codeBox=Instance.new("TextBox")
codeBox.Size=UDim2.new(1,-10,0,92); codeBox.Position=UDim2.new(0,5,0,30)
codeBox.BackgroundTransparency=1
codeBox.Text="-- select an entry"
codeBox.TextColor3=Color3.fromRGB(120,200,130); codeBox.Font=Enum.Font.Code
codeBox.TextSize=11; codeBox.ClearTextOnFocus=false; codeBox.MultiLine=true
codeBox.TextXAlignment=Enum.TextXAlignment.Left; codeBox.TextYAlignment=Enum.TextYAlignment.Top
codeBox.TextWrapped=true; codeBox.Parent=codePanel

do
    local dv=Instance.new("Frame")
    dv.Size=UDim2.new(1,0,0,1); dv.Position=UDim2.new(0,0,0,CODE_Y-1)
    dv.BackgroundColor3=Color3.fromRGB(38,38,50); dv.BorderSizePixel=0; dv.Parent=main
end
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,10);c.Parent=codePanel end

-- ───────────────────────────────────────────────────────────────
--  SELECTED ENTRY STATE
-- ───────────────────────────────────────────────────────────────
local selectedEntry = nil

local function setSelected(entry)
    -- deselect old
    if selectedEntry and selectedEntry.rowFrame then
        selectedEntry.rowFrame.BackgroundColor3 = Color3.fromRGB(24,24,32)
    end
    selectedEntry = entry
    if not entry then
        codeBox.Text = "-- select an entry"
        codeTitle.Text = "Code"
        replayBtn.Visible = false
        return
    end
    if entry.rowFrame then
        entry.rowFrame.BackgroundColor3 = Color3.fromRGB(38,38,58)
    end
    codeBox.Text = buildCode(entry)
    codeTitle.Text = (entry.method=="OnClientEvent" and "◀ IN  " or "▶ OUT  ") .. entry.shortName
    replayBtn.Visible = (entry.method ~= "OnClientEvent")
end

-- ───────────────────────────────────────────────────────────────
--  BUILD / REBUILD ENTRY ROW
-- ───────────────────────────────────────────────────────────────
local filterText = ""
local function nameMatches(entry)
    if filterText == "" then return true end
    return entry.name:lower():find(filterText:lower(), 1, true) ~= nil
end

local function buildRow(entry, order)
    if entry.rowFrame then entry.rowFrame:Destroy() end
    if not nameMatches(entry) then entry.rowFrame = nil; return end

    local args = entry.args
    local expanded = entry.expanded

    local totalH = ITEM_H + (expanded and math.max(#args,1)*ARG_H + 4 or 0)

    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,totalH); row.LayoutOrder=order
    row.BackgroundColor3 = (selectedEntry == entry) and Color3.fromRGB(38,38,58) or Color3.fromRGB(24,24,32)
    row.BorderSizePixel=0; row.ClipsDescendants=true; row.Parent=scroll
    entry.rowFrame = row

    -- lightning icon
    local icon=Instance.new("TextLabel")
    icon.Size=UDim2.new(0,20,0,ITEM_H); icon.Position=UDim2.new(0,4,0,0)
    icon.BackgroundTransparency=1; icon.Text="⚡"
    icon.TextColor3=Color3.fromRGB(255,200,50); icon.Font=Enum.Font.GothamBold
    icon.TextSize=14; icon.Parent=row

    -- remote name
    local nameLbl=Instance.new("TextLabel")
    nameLbl.Size=UDim2.new(1,-130,0,22); nameLbl.Position=UDim2.new(0,28,0,4)
    nameLbl.BackgroundTransparency=1; nameLbl.Text=entry.shortName
    nameLbl.TextColor3=Color3.fromRGB(220,220,230); nameLbl.Font=Enum.Font.GothamBold
    nameLbl.TextSize=12; nameLbl.TextXAlignment=Enum.TextXAlignment.Left
    nameLbl.TextTruncate=Enum.TextTruncate.AtEnd; nameLbl.Parent=row

    -- method label
    local mLbl=Instance.new("TextLabel")
    mLbl.Size=UDim2.new(1,-130,0,14); mLbl.Position=UDim2.new(0,28,0,26)
    mLbl.BackgroundTransparency=1; mLbl.Text=entry.method
    mLbl.TextColor3=Color3.fromRGB(90,90,120); mLbl.Font=Enum.Font.Gotham
    mLbl.TextSize=9; mLbl.TextXAlignment=Enum.TextXAlignment.Left; mLbl.Parent=row

    -- count badge
    if entry.count > 1 then
        local cb=Instance.new("Frame")
        cb.Size=UDim2.new(0,34,0,18); cb.Position=UDim2.new(1,-80,0,6)
        cb.BackgroundColor3=Color3.fromRGB(50,80,160); cb.BorderSizePixel=0; cb.Parent=row
        do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,9);c.Parent=cb end
        local cLbl=Instance.new("TextLabel")
        cLbl.Size=UDim2.new(1,0,1,0); cLbl.BackgroundTransparency=1
        cLbl.Text="x"..entry.count; cLbl.TextColor3=Color3.fromRGB(255,255,255)
        cLbl.Font=Enum.Font.GothamBold; cLbl.TextSize=10; cLbl.Parent=cb
    end

    -- time label
    local tLbl=Instance.new("TextLabel")
    tLbl.Size=UDim2.new(0,70,0,14); tLbl.Position=UDim2.new(1,-75,0,25)
    tLbl.BackgroundTransparency=1; tLbl.Text=entry.timeStr
    tLbl.TextColor3=Color3.fromRGB(80,80,100); tLbl.Font=Enum.Font.Gotham
    tLbl.TextSize=9; tLbl.TextXAlignment=Enum.TextXAlignment.Right; tLbl.Parent=row

    -- arg count hint
    local argHint=Instance.new("TextLabel")
    argHint.Size=UDim2.new(0,60,0,14); argHint.Position=UDim2.new(1,-140,0,25)
    argHint.BackgroundTransparency=1
    argHint.Text=#args.." arg"..(#args==1 and "" or "s")
    argHint.TextColor3=Color3.fromRGB(80,80,100); argHint.Font=Enum.Font.Gotham
    argHint.TextSize=9; argHint.TextXAlignment=Enum.TextXAlignment.Right; argHint.Parent=row

    -- expand arrow
    local arrow=Instance.new("TextLabel")
    arrow.Size=UDim2.new(0,16,0,ITEM_H); arrow.Position=UDim2.new(1,-18,0,0)
    arrow.BackgroundTransparency=1; arrow.Text=expanded and "▲" or "▼"
    arrow.TextColor3=Color3.fromRGB(80,80,110); arrow.Font=Enum.Font.GothamBold
    arrow.TextSize=10; arrow.Parent=row

    -- expanded arg rows
    if expanded then
        local argList = #args > 0 and args or { nil }
        for i, v in ipairs(argList) do
            local aRow=Instance.new("Frame")
            aRow.Size=UDim2.new(1,-6,0,ARG_H); aRow.Position=UDim2.new(0,3,0,ITEM_H+(i-1)*ARG_H+2)
            aRow.BackgroundColor3=Color3.fromRGB(18,18,26); aRow.BorderSizePixel=0; aRow.Parent=row
            do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,4);c.Parent=aRow end

            local numLbl=Instance.new("TextLabel")
            numLbl.Size=UDim2.new(0,16,1,0); numLbl.Position=UDim2.new(0,3,0,0)
            numLbl.BackgroundTransparency=1; numLbl.Text=tostring(i)
            numLbl.TextColor3=Color3.fromRGB(80,80,100); numLbl.Font=Enum.Font.Gotham
            numLbl.TextSize=10; numLbl.Parent=aRow

            local valLbl=Instance.new("TextLabel")
            valLbl.Size=UDim2.new(1,-90,1,0); valLbl.Position=UDim2.new(0,22,0,0)
            valLbl.BackgroundTransparency=1; valLbl.Text=argVal(v)
            valLbl.TextColor3=Color3.fromRGB(200,200,210); valLbl.Font=Enum.Font.Code
            valLbl.TextSize=10; valLbl.TextXAlignment=Enum.TextXAlignment.Left
            valLbl.TextTruncate=Enum.TextTruncate.AtEnd; valLbl.Parent=aRow

            -- type badge
            local typ = argType(v)
            local typBadge=Instance.new("Frame")
            typBadge.Size=UDim2.new(0,66,0,14); typBadge.Position=UDim2.new(1,-70,0.5,-7)
            typBadge.BackgroundColor3=Color3.fromRGB(28,28,40); typBadge.BorderSizePixel=0; typBadge.Parent=aRow
            do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,4);c.Parent=typBadge end
            local typLbl=Instance.new("TextLabel")
            typLbl.Size=UDim2.new(1,0,1,0); typLbl.BackgroundTransparency=1; typLbl.Text=typ
            typLbl.TextColor3=typeColor(typ); typLbl.Font=Enum.Font.GothamBold; typLbl.TextSize=9
            typLbl.Parent=typBadge
        end
    end

    -- click to select / expand
    local clickTarget=Instance.new("TextButton")
    clickTarget.Size=UDim2.new(1,-18,0,ITEM_H); clickTarget.BackgroundTransparency=1
    clickTarget.Text=""; clickTarget.Parent=row
    clickTarget.MouseButton1Click:Connect(function()
        setSelected(entry)
    end)

    -- arrow click to expand/collapse
    local arrowBtn=Instance.new("TextButton")
    arrowBtn.Size=UDim2.new(0,18,0,ITEM_H); arrowBtn.Position=UDim2.new(1,-18,0,0)
    arrowBtn.BackgroundTransparency=1; arrowBtn.Text=""; arrowBtn.Parent=row
    arrowBtn.MouseButton1Click:Connect(function()
        entry.expanded = not entry.expanded
        -- rebuild this entry
        local list = lists[activeTab]
        for i, e in ipairs(list) do
            if e == entry then buildRow(e, i); break end
        end
        task.defer(function()
            scroll.CanvasPosition = Vector2.new(0, scroll.AbsoluteCanvasSize.Y)
        end)
    end)
end

-- ───────────────────────────────────────────────────────────────
--  REBUILD ALL ROWS
-- ───────────────────────────────────────────────────────────────
local function rebuildAll()
    -- destroy all existing rows
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") then child:Destroy() end
    end
    local list = lists[activeTab]
    for i, e in ipairs(list) do
        buildRow(e, i)
    end
    countLbl2.Text = #list .. ""
end

-- ───────────────────────────────────────────────────────────────
--  LOG FUNCTION
-- ───────────────────────────────────────────────────────────────
local function logCall(dir, remote, args, method)
    if paused then return end
    local list = lists[dir]

    local now = os.date("*t")
    local timeStr = ("Time: %02d:%02d:%02d"):format(now.hour,now.min,now.sec)
    local fullName = pcall(function() return remote:GetFullName() end) and remote:GetFullName() or remote.Name
    local parts={}; for p in fullName:gmatch("[^%.]+") do parts[#parts+1]=p end
    local shortName = #parts>=2 and (parts[#parts-1].."."..parts[#parts]) or (parts[#parts] or remote.Name)

    -- check if same remote fired recently (group repeats)
    local last = list[#list]
    if last and last.method==method and last.name==fullName then
        last.count = last.count + 1
        last.timeStr = timeStr
        last.args = args  -- update to latest args
        -- rebuild only that row
        buildRow(last, #list)
        if selectedEntry == last then
            codeBox.Text = buildCode(last)
        end
        return
    end

    -- trim oldest
    if #list >= MAX_LOG then
        local oldest = table.remove(list, 1)
        if oldest.rowFrame then oldest.rowFrame:Destroy() end
        if selectedEntry == oldest then setSelected(nil) end
    end

    local entry = {
        remote    = remote,
        name      = fullName,
        shortName = shortName,
        method    = method,
        args      = args,
        count     = 1,
        timeStr   = timeStr,
        expanded  = false,
        rowFrame  = nil,
    }
    table.insert(list, entry)

    if activeTab == dir then
        buildRow(entry, #list)
        countLbl2.Text = #list..""
        task.defer(function()
            scroll.CanvasPosition = Vector2.new(0, scroll.AbsoluteCanvasSize.Y)
        end)
    end
end

-- ───────────────────────────────────────────────────────────────
--  OUTGOING HOOK
-- ───────────────────────────────────────────────────────────────
if hasHook then
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local m = getnamecallmethod()
        if m=="FireServer" or m=="InvokeServer" then
            if typeof(self)=="Instance" and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
                task.defer(logCall, "OUT", self, {...}, m)
            end
        end
        return oldNamecall(self, ...)
    end))
end

-- ───────────────────────────────────────────────────────────────
--  INCOMING HOOK
-- ───────────────────────────────────────────────────────────────
local function hookIn(remote)
    if hookedIn[remote] then return end
    hookedIn[remote] = true
    if remote:IsA("RemoteEvent") then
        remote.OnClientEvent:Connect(function(...)
            logCall("IN", remote, {...}, "OnClientEvent")
        end)
    elseif remote:IsA("RemoteFunction") then
        -- can't easily hook OnClientInvoke without overwriting it
    end
end

task.spawn(function()
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then hookIn(v) end
    end
    game.DescendantAdded:Connect(function(v)
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then task.defer(hookIn, v) end
    end)
end)

-- ───────────────────────────────────────────────────────────────
--  TAB + CONTROL HANDLERS
-- ───────────────────────────────────────────────────────────────
local function setTab(tab)
    activeTab = tab
    tabOut.BackgroundColor3 = tab=="OUT" and Color3.fromRGB(52,90,200) or Color3.fromRGB(35,35,45)
    tabIn.BackgroundColor3  = tab=="IN"  and Color3.fromRGB(35,140,80)  or Color3.fromRGB(35,35,45)
    tabOut.TextColor3 = tab=="OUT" and Color3.fromRGB(255,255,255) or Color3.fromRGB(160,160,160)
    tabIn.TextColor3  = tab=="IN"  and Color3.fromRGB(255,255,255) or Color3.fromRGB(160,160,160)
    setSelected(nil)
    rebuildAll()
end

tabOut.MouseButton1Click:Connect(function() setTab("OUT") end)
tabIn.MouseButton1Click:Connect(function()  setTab("IN")  end)
setTab("OUT")  -- default

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    filterText = searchBox.Text
    rebuildAll()
end)

pauseBtn.MouseButton1Click:Connect(function()
    paused = not paused
    pauseBtn.Text = paused and "▶ Resume" or "⏸ Pause"
    pauseBtn.BackgroundColor3 = paused
        and Color3.fromRGB(46,160,60)
        or  Color3.fromRGB(160,120,30)
end)

clearBtn.MouseButton1Click:Connect(function()
    lists[activeTab] = {}
    setSelected(nil)
    rebuildAll()
end)

copyBtn.MouseButton1Click:Connect(function()
    if not selectedEntry then return end
    local code = buildCode(selectedEntry)
    pcall(function() setclipboard(code) end)
    copyBtn.Text = "✓ Copied!"
    task.delay(1.5, function() copyBtn.Text = "📋 Copy" end)
end)

replayBtn.MouseButton1Click:Connect(function()
    if not selectedEntry or selectedEntry.method=="OnClientEvent" then return end
    local r = selectedEntry.remote
    if r and r.Parent then
        pcall(function() r:FireServer(table.unpack(selectedEntry.args)) end)
        replayBtn.Text = "✓ Fired!"
        task.delay(1.2, function() replayBtn.Text = "▶ Replay" end)
    end
end)

-- ── Minimize / Close ──────────────────────────────────────────
local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    main.Size = minimized and UDim2.new(0,W,0,36) or UDim2.new(0,W,0,H)
    minBtn.Text = minimized and "+" or "−"
end)
closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

print("[RemoteSpy v2] Hook:" .. (hasHook and "✓" or "✗"))
