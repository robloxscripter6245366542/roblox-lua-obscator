-- Remote Spy  v1
-- Intercepts ALL incoming/outgoing RemoteEvent + RemoteFunction calls
-- Click an entry → see generated Lua code  |  Replay outgoing calls
-- Requires hookmetamethod + getnamecallmethod (executor privilege) for outgoing

local Players  = game:GetService("Players")
local TweenSvc = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- ───────────────────────────────────────────────────────────────
--  STATE
-- ───────────────────────────────────────────────────────────────
local MAX_LOG    = 200
local logData    = {}      -- array of entry tables
local entryUI    = {}      -- parallel array of Frame objects
local showOut    = true
local showIn     = true
local paused     = false
local filterText = ""
local selected   = nil     -- currently selected entry index
local hasHook    = type(hookmetamethod) == "function"

-- ───────────────────────────────────────────────────────────────
--  VALUE FORMATTER  — compact display in list
-- ───────────────────────────────────────────────────────────────
local function fmtV(v, d)
    d = d or 0
    if d > 2 then return "…" end
    local t = typeof(v)
    if     t == "nil"      then return "nil"
    elseif t == "boolean"  then return tostring(v)
    elseif t == "number"   then
        return v == math.floor(v) and tostring(math.floor(v)) or ("%.3g"):format(v)
    elseif t == "string"   then
        local s = v:sub(1,30):gsub("[%c]","·")
        return '"' .. s .. (#v>30 and "…" or "") .. '"'
    elseif t == "Instance" then return "["..v.ClassName..":"..v.Name.."]"
    elseif t == "Vector3"  then return ("V3(%g,%g,%g)"):format(v.X,v.Y,v.Z)
    elseif t == "Vector2"  then return ("V2(%g,%g)"):format(v.X,v.Y)
    elseif t == "CFrame"   then
        local p = v.Position
        return ("CF(%g,%g,%g)"):format(p.X,p.Y,p.Z)
    elseif t == "Color3"   then
        return ("RGB(%d,%d,%d)"):format(v.R*255,v.G*255,v.B*255)
    elseif t == "EnumItem" then return tostring(v)
    elseif t == "table"    then
        local p, i = {}, 0
        for k,u in pairs(v) do
            i=i+1; if i>4 then p[#p+1]="…"; break end
            p[#p+1] = type(k)=="number" and fmtV(u,d+1) or (tostring(k).."="..fmtV(u,d+1))
        end
        return "{"..table.concat(p,",").."}"
    else return tostring(v):sub(1,20) end
end

local function fmtArgs(args)
    if #args == 0 then return "()" end
    local p = {}
    for _,v in ipairs(args) do p[#p+1] = fmtV(v) end
    local s = "("..table.concat(p,", ")..")"
    return #s > 70 and s:sub(1,70).."…)" or s
end

-- ───────────────────────────────────────────────────────────────
--  CODE GENERATOR  — full copy-pasteable Lua
-- ───────────────────────────────────────────────────────────────
local function codeVal(v, d)
    d = d or 0
    if d > 3 then return "nil --[[deep]]" end
    local t = typeof(v)
    if     t == "nil"     then return "nil"
    elseif t == "boolean" then return tostring(v)
    elseif t == "number"  then return tostring(v)
    elseif t == "string"  then
        return '"' .. v:gsub("\\","\\\\"):gsub('"','\\"'):gsub("\n","\\n") .. '"'
    elseif t == "Instance" then
        local path = v:GetFullName()
        path = path:gsub("^game%.([^%.]+)", function(s)
            return 'game:GetService("'..s..'")'
        end)
        return path
    elseif t == "Vector3"  then return ("Vector3.new(%g, %g, %g)"):format(v.X,v.Y,v.Z)
    elseif t == "Vector2"  then return ("Vector2.new(%g, %g)"):format(v.X,v.Y)
    elseif t == "CFrame"   then
        local c = {v:GetComponents()}
        local s = {}; for _,n in ipairs(c) do s[#s+1]=tostring(n) end
        return "CFrame.new("..table.concat(s,", ")..")"
    elseif t == "Color3"   then
        return ("Color3.fromRGB(%d, %d, %d)"):format(v.R*255,v.G*255,v.B*255)
    elseif t == "UDim2"    then
        return ("UDim2.new(%g, %g, %g, %g)"):format(v.X.Scale,v.X.Offset,v.Y.Scale,v.Y.Offset)
    elseif t == "EnumItem" then
        return "Enum."..tostring(v.EnumType).."."..v.Name
    elseif t == "table"    then
        local p = {}
        for k,u in pairs(v) do
            if type(k)=="number" then p[#p+1] = codeVal(u,d+1)
            else p[#p+1] = '["'..tostring(k)..'"] = '..codeVal(u,d+1) end
        end
        return "{"..table.concat(p,", ").."}"
    else return "--[["..t.."]]" end
end

local function buildCode(entry)
    local r = entry.remote
    if not r or not r.Parent then
        -- remote gone; still show what we captured
        local p = {}
        for _,v in ipairs(entry.args) do p[#p+1] = codeVal(v) end
        if entry.dir == "IN" then
            return "-- [INCOMING] "..entry.name.."\n-- args: "..table.concat(p,", ")
        end
        return "-- remote destroyed\n-- "..entry.name..":"..entry.method.."("..table.concat(p,", ")..")"
    end
    local path = r:GetFullName()
    path = path:gsub("^game%.([^%.]+)", function(s)
        return 'game:GetService("'..s..'")'
    end)
    local p = {}
    for _,v in ipairs(entry.args) do p[#p+1] = codeVal(v) end
    local argStr = table.concat(p, ", ")
    if entry.dir == "IN" then
        return "-- [INCOMING] fired by server\n"..path..".OnClientEvent:Connect(function("
            .. (argStr~="" and "..." or "") ..")\n    -- args: "..argStr.."\nend)"
    else
        return path..":"..entry.method.."("..argStr..")"
    end
end

-- ───────────────────────────────────────────────────────────────
--  GUI
-- ───────────────────────────────────────────────────────────────
local W, H = 520, 570
local LOG_H = 310
local CODE_Y = 38 + 4 + 36 + 4 + LOG_H + 8   -- 400
local CODE_H = H - CODE_Y - 6                  -- 164

local sg = Instance.new("ScreenGui")
sg.Name="RemoteSpy"; sg.ResetOnSpawn=false
sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
sg.Parent = LocalPlayer:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Name="Main"; main.Size=UDim2.new(0,W,0,H)
main.Position=UDim2.new(0.5,-W/2,0.5,-H/2)
main.BackgroundColor3=Color3.fromRGB(11,11,15)
main.BorderSizePixel=0; main.Active=true; main.Draggable=true; main.Parent=sg
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,12);c.Parent=main end

-- gradient overlay
do
    local g=Instance.new("UIGradient")
    g.Color=ColorSequence.new{
        ColorSequenceKeypoint.new(0,Color3.fromRGB(20,20,28)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(11,11,15)),
    }
    g.Rotation=120; g.Parent=main
end

-- ── Title Bar ──────────────────────────────────────────────────
local titleBar=Instance.new("Frame")
titleBar.Size=UDim2.new(1,0,0,38); titleBar.BackgroundColor3=Color3.fromRGB(17,17,24)
titleBar.BorderSizePixel=0; titleBar.Parent=main
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,12);c.Parent=titleBar end

local titleLbl=Instance.new("TextLabel")
titleLbl.Size=UDim2.new(1,-90,1,0); titleLbl.Position=UDim2.new(0,12,0,0)
titleLbl.BackgroundTransparency=1
titleLbl.Text = hasHook and "🔍  Remote Spy" or "🔍  Remote Spy  ⚠️ no hook — IN only"
titleLbl.TextColor3=Color3.fromRGB(210,210,255); titleLbl.Font=Enum.Font.GothamBold
titleLbl.TextSize=13; titleLbl.TextXAlignment=Enum.TextXAlignment.Left; titleLbl.Parent=titleBar

local function mkTitleBtn(xOff, txt, col)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,26,0,26); b.Position=UDim2.new(1,xOff,0.5,-13)
    b.BackgroundColor3=col; b.BorderSizePixel=0
    b.Text=txt; b.TextColor3=Color3.fromRGB(255,255,255)
    b.Font=Enum.Font.GothamBold; b.TextSize=12; b.Parent=titleBar
    do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,7);c.Parent=b end
    return b
end
local closeBtn = mkTitleBtn(-30, "✕", Color3.fromRGB(180,50,50))
local minBtn   = mkTitleBtn(-60, "−", Color3.fromRGB(38,38,55))

-- ── Filter / Control Bar ───────────────────────────────────────
local ctrlBar=Instance.new("Frame")
ctrlBar.Size=UDim2.new(1,-10,0,36); ctrlBar.Position=UDim2.new(0,5,0,42)
ctrlBar.BackgroundColor3=Color3.fromRGB(16,16,22); ctrlBar.BorderSizePixel=0
ctrlBar.Parent=main
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=ctrlBar end

local searchBox=Instance.new("TextBox")
searchBox.Size=UDim2.new(0,155,0,24); searchBox.Position=UDim2.new(0,6,0.5,-12)
searchBox.BackgroundColor3=Color3.fromRGB(24,24,33); searchBox.BorderSizePixel=0
searchBox.Text=""; searchBox.PlaceholderText="filter name…"
searchBox.TextColor3=Color3.fromRGB(220,220,230); searchBox.PlaceholderColor3=Color3.fromRGB(90,90,110)
searchBox.Font=Enum.Font.Gotham; searchBox.TextSize=11; searchBox.ClearTextOnFocus=false
searchBox.Parent=ctrlBar
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,5);c.Parent=searchBox end

local ctrlBtnData = {
    {txt="▶ OUT", x=167, w=46, col=Color3.fromRGB(40,90,180)},
    {txt="◀ IN",  x=217, w=40, col=Color3.fromRGB(35,140,80)},
    {txt="⏸",     x=261, w=28, col=Color3.fromRGB(160,110,30)},
    {txt="🗑",     x=293, w=28, col=Color3.fromRGB(140,40,40)},
}
local ctrlBtns = {}
for _, d in ipairs(ctrlBtnData) do
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,d.w,0,24); b.Position=UDim2.new(0,d.x,0.5,-12)
    b.BackgroundColor3=d.col; b.BorderSizePixel=0
    b.Text=d.txt; b.TextColor3=Color3.fromRGB(255,255,255)
    b.Font=Enum.Font.GothamBold; b.TextSize=11; b.Parent=ctrlBar
    do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,5);c.Parent=b end
    table.insert(ctrlBtns, b)
end
local btnToggleOut, btnToggleIn, btnPause, btnClearLog = table.unpack(ctrlBtns)

local countLbl=Instance.new("TextLabel")
countLbl.Size=UDim2.new(0,100,1,0); countLbl.Position=UDim2.new(1,-105,0,0)
countLbl.BackgroundTransparency=1; countLbl.Text="0 entries"
countLbl.TextColor3=Color3.fromRGB(90,90,110); countLbl.Font=Enum.Font.Gotham
countLbl.TextSize=10; countLbl.TextXAlignment=Enum.TextXAlignment.Right
countLbl.Parent=ctrlBar

-- ── Log Scroll ─────────────────────────────────────────────────
local logScroll=Instance.new("ScrollingFrame")
logScroll.Size=UDim2.new(1,-10,0,LOG_H); logScroll.Position=UDim2.new(0,5,0,82)
logScroll.BackgroundColor3=Color3.fromRGB(9,9,12); logScroll.BorderSizePixel=0
logScroll.ScrollBarThickness=4; logScroll.ScrollBarImageColor3=Color3.fromRGB(70,70,100)
logScroll.CanvasSize=UDim2.new(0,0,0,0); logScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
logScroll.ElasticBehavior=Enum.ElasticBehavior.Never; logScroll.Parent=main
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=logScroll end

local listLayout=Instance.new("UIListLayout")
listLayout.SortOrder=Enum.SortOrder.LayoutOrder; listLayout.Padding=UDim.new(0,1)
listLayout.Parent=logScroll

-- ── Code Panel ─────────────────────────────────────────────────
local codeFrame=Instance.new("Frame")
codeFrame.Size=UDim2.new(1,-10,0,CODE_H); codeFrame.Position=UDim2.new(0,5,0,CODE_Y)
codeFrame.BackgroundColor3=Color3.fromRGB(13,13,18); codeFrame.BorderSizePixel=0
codeFrame.Parent=main
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=codeFrame end

local codeTopBar=Instance.new("Frame")
codeTopBar.Size=UDim2.new(1,0,0,26); codeTopBar.BackgroundColor3=Color3.fromRGB(19,19,28)
codeTopBar.BorderSizePixel=0; codeTopBar.Parent=codeFrame
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=codeTopBar end

local codeTitleLbl=Instance.new("TextLabel")
codeTitleLbl.Size=UDim2.new(1,-160,1,0); codeTitleLbl.Position=UDim2.new(0,8,0,0)
codeTitleLbl.BackgroundTransparency=1; codeTitleLbl.Text="📄 Code  —  click an entry"
codeTitleLbl.TextColor3=Color3.fromRGB(130,130,170); codeTitleLbl.Font=Enum.Font.Gotham
codeTitleLbl.TextSize=10; codeTitleLbl.TextXAlignment=Enum.TextXAlignment.Left
codeTitleLbl.Parent=codeTopBar

local function mkCodeBtn(xOff, txt, col)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,70,0,20); b.Position=UDim2.new(1,xOff,0.5,-10)
    b.BackgroundColor3=col; b.BorderSizePixel=0
    b.Text=txt; b.TextColor3=Color3.fromRGB(255,255,255)
    b.Font=Enum.Font.GothamBold; b.TextSize=10; b.Parent=codeTopBar
    do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,5);c.Parent=b end
    return b
end
local codeReplayBtn = mkCodeBtn(-154, "▶ Replay", Color3.fromRGB(40,130,200))
local codeCopyBtn   = mkCodeBtn(-80,  "📋 Copy",  Color3.fromRGB(60,60,100))

local codeBox=Instance.new("TextBox")
codeBox.Size=UDim2.new(1,-8,1,-30); codeBox.Position=UDim2.new(0,4,0,28)
codeBox.BackgroundTransparency=1
codeBox.Text="-- click a log entry to view generated code"
codeBox.TextColor3=Color3.fromRGB(130,200,140); codeBox.Font=Enum.Font.Code
codeBox.TextSize=11; codeBox.ClearTextOnFocus=false; codeBox.MultiLine=true
codeBox.TextXAlignment=Enum.TextXAlignment.Left; codeBox.TextYAlignment=Enum.TextYAlignment.Top
codeBox.TextWrapped=true; codeBox.Parent=codeFrame

-- divider between scroll and code
do
    local dv=Instance.new("Frame")
    dv.Size=UDim2.new(1,-10,0,1); dv.Position=UDim2.new(0,5,0,CODE_Y-4)
    dv.BackgroundColor3=Color3.fromRGB(35,35,50); dv.BorderSizePixel=0; dv.Parent=main
end

-- ───────────────────────────────────────────────────────────────
--  ENTRY CREATION
-- ───────────────────────────────────────────────────────────────
local OUT_COL   = Color3.fromRGB(50,100,220)
local IN_COL    = Color3.fromRGB(40,170,100)
local SEL_COL   = Color3.fromRGB(35,35,55)
local NORM_COL  = Color3.fromRGB(14,14,18)
local ALT_COL   = Color3.fromRGB(16,16,22)
local entryCount = 0

local function selectEntry(idx)
    -- deselect old
    if selected and entryUI[selected] then
        entryUI[selected].BackgroundColor3 = (selected%2==0) and ALT_COL or NORM_COL
    end
    selected = idx
    if not idx then
        codeBox.Text = "-- click a log entry to view generated code"
        codeTitleLbl.Text = "📄 Code  —  click an entry"
        codeReplayBtn.Visible = false
        return
    end
    if entryUI[idx] then entryUI[idx].BackgroundColor3 = SEL_COL end
    local e = logData[idx]
    codeBox.Text = buildCode(e)
    codeTitleLbl.Text = "📄 " .. (e.dir=="OUT" and "▶ OUT" or "◀ IN") .. "  " .. e.name
    codeReplayBtn.Visible = (e.dir == "OUT")
end

local function makeEntryRow(idx, entry)
    local row=Instance.new("TextButton")
    row.Name="Entry"..idx; row.Size=UDim2.new(1,0,0,36)
    row.LayoutOrder=idx; row.BorderSizePixel=0
    row.BackgroundColor3 = (idx%2==0) and ALT_COL or NORM_COL
    row.AutoButtonColor=false; row.Text=""; row.Parent=logScroll

    -- direction badge
    local badge=Instance.new("Frame")
    badge.Size=UDim2.new(0,34,1,-6); badge.Position=UDim2.new(0,3,0,3)
    badge.BackgroundColor3=entry.dir=="OUT" and OUT_COL or IN_COL
    badge.BorderSizePixel=0; badge.Parent=row
    do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,5);c.Parent=badge end

    local badgeLbl=Instance.new("TextLabel")
    badgeLbl.Size=UDim2.new(1,0,0.5,0); badgeLbl.Position=UDim2.new(0,0,0,0)
    badgeLbl.BackgroundTransparency=1
    badgeLbl.Text=entry.dir=="OUT" and "OUT" or " IN"
    badgeLbl.TextColor3=Color3.fromRGB(255,255,255); badgeLbl.Font=Enum.Font.GothamBold
    badgeLbl.TextSize=9; badgeLbl.Parent=badge

    local timeLbl=Instance.new("TextLabel")
    timeLbl.Size=UDim2.new(1,0,0.5,0); timeLbl.Position=UDim2.new(0,0,0.5,0)
    timeLbl.BackgroundTransparency=1; timeLbl.Text=entry.timeStr
    timeLbl.TextColor3=Color3.fromRGB(200,200,200); timeLbl.Font=Enum.Font.Gotham
    timeLbl.TextSize=8; timeLbl.Parent=badge

    -- remote name
    local nameLbl=Instance.new("TextLabel")
    nameLbl.Size=UDim2.new(0,145,0,17); nameLbl.Position=UDim2.new(0,41,0,2)
    nameLbl.BackgroundTransparency=1; nameLbl.Text=entry.shortName
    nameLbl.TextColor3=entry.dir=="OUT" and Color3.fromRGB(150,190,255) or Color3.fromRGB(130,220,160)
    nameLbl.Font=Enum.Font.GothamBold; nameLbl.TextSize=11
    nameLbl.TextXAlignment=Enum.TextXAlignment.Left; nameLbl.TextTruncate=Enum.TextTruncate.AtEnd
    nameLbl.Parent=row

    -- method label (e.g. FireServer / InvokeServer)
    local methLbl=Instance.new("TextLabel")
    methLbl.Size=UDim2.new(0,145,0,13); methLbl.Position=UDim2.new(0,41,0,19)
    methLbl.BackgroundTransparency=1; methLbl.Text=entry.method
    methLbl.TextColor3=Color3.fromRGB(90,90,120); methLbl.Font=Enum.Font.Gotham
    methLbl.TextSize=9; methLbl.TextXAlignment=Enum.TextXAlignment.Left; methLbl.Parent=row

    -- args summary
    local argsLbl=Instance.new("TextLabel")
    argsLbl.Size=UDim2.new(1,-235,1,0); argsLbl.Position=UDim2.new(0,190,0,0)
    argsLbl.BackgroundTransparency=1; argsLbl.Text=entry.argStr
    argsLbl.TextColor3=Color3.fromRGB(190,190,200); argsLbl.Font=Enum.Font.Code
    argsLbl.TextSize=10; argsLbl.TextXAlignment=Enum.TextXAlignment.Left
    argsLbl.TextTruncate=Enum.TextTruncate.AtEnd; argsLbl.Parent=row

    -- replay btn (OUT only)
    if entry.dir == "OUT" then
        local rb=Instance.new("TextButton")
        rb.Size=UDim2.new(0,22,0,22); rb.Position=UDim2.new(1,-48,0.5,-11)
        rb.BackgroundColor3=Color3.fromRGB(35,80,160); rb.BorderSizePixel=0
        rb.Text="▶"; rb.TextColor3=Color3.fromRGB(255,255,255)
        rb.Font=Enum.Font.GothamBold; rb.TextSize=11; rb.Parent=row
        do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,5);c.Parent=rb end
        rb.MouseButton1Click:Connect(function()
            local r=entry.remote
            if r and r.Parent then
                pcall(function() r:FireServer(table.unpack(entry.args)) end)
            end
        end)
    end

    -- select on click
    row.MouseButton1Click:Connect(function() selectEntry(idx) end)

    return row
end

-- ───────────────────────────────────────────────────────────────
--  LOG FUNCTION
-- ───────────────────────────────────────────────────────────────
local function shouldShow(entry)
    if paused then return false end
    if entry.dir=="OUT" and not showOut then return false end
    if entry.dir=="IN"  and not showIn  then return false end
    if filterText ~= "" then
        if not entry.name:lower():find(filterText:lower(), 1, true) then return false end
    end
    return true
end

local function logRemote(dir, remote, args, method)
    if paused then return end

    local now = os.date("*t")
    local timeStr = ("%02d:%02d:%02d"):format(now.hour, now.min, now.sec)
    local fullName = pcall(function() return remote:GetFullName() end) and remote:GetFullName() or remote.Name
    -- shorten: show last 2 path segments
    local parts = {}
    for p in fullName:gmatch("[^%.]+") do parts[#parts+1] = p end
    local shortName = #parts >= 2 and (parts[#parts-1].."."..parts[#parts]) or parts[#parts] or remote.Name

    local entry = {
        dir      = dir,
        remote   = remote,
        args     = args,
        method   = method,
        name     = fullName,
        shortName= shortName,
        timeStr  = timeStr,
        argStr   = fmtArgs(args),
    }

    -- trim oldest if over limit
    if #logData >= MAX_LOG then
        local oldest = entryUI[1]
        if oldest then oldest:Destroy() end
        table.remove(logData, 1)
        table.remove(entryUI, 1)
        -- reindex layout orders
        for i, f in ipairs(entryUI) do
            f.LayoutOrder = i
            f.BackgroundColor3 = (i%2==0) and ALT_COL or NORM_COL
        end
        if selected then selected = selected - 1 end
    end

    table.insert(logData, entry)
    local idx = #logData

    if shouldShow(entry) then
        local row = makeEntryRow(idx, entry)
        entryUI[idx] = row
        -- auto-scroll to bottom
        task.defer(function()
            logScroll.CanvasPosition = Vector2.new(0, logScroll.AbsoluteCanvasSize.Y)
        end)
    else
        -- insert placeholder so indices stay aligned
        local placeholder = Instance.new("Frame")
        placeholder.Size=UDim2.new(1,0,0,0); placeholder.Visible=false
        placeholder.LayoutOrder=idx; placeholder.BackgroundTransparency=1
        placeholder.Parent=logScroll
        entryUI[idx] = placeholder
    end

    entryCount = entryCount + 1
    countLbl.Text = #logData .. " entries"
end

-- ───────────────────────────────────────────────────────────────
--  OUTGOING HOOK  (hookmetamethod)
-- ───────────────────────────────────────────────────────────────
if hasHook then
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local m = getnamecallmethod()
        if (m == "FireServer" or m == "InvokeServer") then
            if typeof(self) == "Instance" and
               (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
                task.defer(logRemote, "OUT", self, {...}, m)
            end
        end
        return oldNamecall(self, ...)
    end))
end

-- ───────────────────────────────────────────────────────────────
--  INCOMING HOOK  (connect to all RemoteEvents)
-- ───────────────────────────────────────────────────────────────
local hookedIn = {}

local function hookIncoming(remote)
    if hookedIn[remote] then return end
    hookedIn[remote] = true
    if remote:IsA("RemoteEvent") then
        remote.OnClientEvent:Connect(function(...)
            logRemote("IN", remote, {...}, "OnClientEvent")
        end)
    end
end

task.spawn(function()
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            hookIncoming(v)
        end
    end
    game.DescendantAdded:Connect(function(v)
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            task.defer(hookIncoming, v)
        end
    end)
end)

-- ───────────────────────────────────────────────────────────────
--  FILTER REBUILD  (called when search/toggle changes)
-- ───────────────────────────────────────────────────────────────
local function rebuildLog()
    for _, f in ipairs(entryUI) do f:Destroy() end
    entryUI = {}
    selected = nil
    codeBox.Text = "-- click a log entry to view generated code"
    codeTitleLbl.Text = "📄 Code  —  click an entry"

    for i, entry in ipairs(logData) do
        if shouldShow(entry) then
            local row = makeEntryRow(i, entry)
            entryUI[i] = row
        else
            local ph = Instance.new("Frame")
            ph.Size=UDim2.new(1,0,0,0); ph.Visible=false
            ph.LayoutOrder=i; ph.BackgroundTransparency=1; ph.Parent=logScroll
            entryUI[i] = ph
        end
    end
    countLbl.Text = #logData .. " entries"
end

-- ───────────────────────────────────────────────────────────────
--  CONTROL HANDLERS
-- ───────────────────────────────────────────────────────────────
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    filterText = searchBox.Text
    rebuildLog()
end)

btnToggleOut.MouseButton1Click:Connect(function()
    showOut = not showOut
    btnToggleOut.BackgroundColor3 = showOut
        and Color3.fromRGB(40,90,180)
        or  Color3.fromRGB(50,50,60)
    btnToggleOut.Text = showOut and "▶ OUT" or "▶ ---"
    rebuildLog()
end)

btnToggleIn.MouseButton1Click:Connect(function()
    showIn = not showIn
    btnToggleIn.BackgroundColor3 = showIn
        and Color3.fromRGB(35,140,80)
        or  Color3.fromRGB(50,50,60)
    btnToggleIn.Text = showIn and "◀ IN" or "◀ ---"
    rebuildLog()
end)

btnPause.MouseButton1Click:Connect(function()
    paused = not paused
    btnPause.Text = paused and "▶" or "⏸"
    btnPause.BackgroundColor3 = paused
        and Color3.fromRGB(46,160,80)
        or  Color3.fromRGB(160,110,30)
end)

btnClearLog.MouseButton1Click:Connect(function()
    logData = {}
    for _, f in ipairs(entryUI) do f:Destroy() end
    entryUI = {}
    selected = nil
    entryCount = 0
    countLbl.Text = "0 entries"
    codeBox.Text = "-- click a log entry to view generated code"
    codeTitleLbl.Text = "📄 Code  —  click an entry"
    codeReplayBtn.Visible = false
end)

codeCopyBtn.MouseButton1Click:Connect(function()
    local code = codeBox.Text
    if code == "" or code:find("^%-%-") then return end
    pcall(function() setclipboard(code) end)
    codeCopyBtn.Text = "✓ Copied!"
    task.delay(1.5, function() codeCopyBtn.Text = "📋 Copy" end)
end)

codeReplayBtn.MouseButton1Click:Connect(function()
    if not selected then return end
    local e = logData[selected]
    if not e or e.dir ~= "OUT" then return end
    local r = e.remote
    if r and r.Parent then
        pcall(function() r:FireServer(table.unpack(e.args)) end)
        codeReplayBtn.Text = "✓ Fired!"
        task.delay(1, function() codeReplayBtn.Text = "▶ Replay" end)
    end
end)

codeReplayBtn.Visible = false

-- ── Minimize / Close ───────────────────────────────────────────
local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    main.Size = minimized and UDim2.new(0,W,0,38) or UDim2.new(0,W,0,H)
    minBtn.Text = minimized and "+" or "−"
end)
closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

print("[RemoteSpy] Loaded. Hook: " .. (hasHook and "✓ OUT+IN" or "✗ IN only"))
