-- Volt — Network Monitor  (better-than-Cobalt edition)
-- Multi-page: Outgoing · Incoming · Blocked · Stats · Settings
-- Animated purple chrome, hover feedback, drop shadow, live glow border
-- Block • Ignore • Replay • Copy • BindableEvent/Function • UnreliableRemoteEvent

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService  = game:GetService("HttpService")
local LocalPlayer  = Players.LocalPlayer

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  AI CONFIG  (Pollinations.ai — free, no API key)              ║
-- ╚═══════════════════════════════════════════════════════════════╝
local AI = {
    model    = "openai",                 -- smartest free model; alt: mistral, openai-large
    endpoint = "https://text.pollinations.ai/openai",
    system   = "You are Volt AI, an expert Roblox/Luau reverse-engineering "
            .. "assistant embedded in a remote-spy tool. You explain remote "
            .. "calls, write Luau, and answer scripting questions concisely.",
}

-- executor-agnostic HTTP
local function httpRequest(opts)
    local fn = (syn and syn.request) or (http and http.request)
        or http_request or request or (fluxus and fluxus.request)
    if type(fn) ~= "function" then return nil, "no executor HTTP function found" end
    local ok, res = pcall(fn, opts)
    if not ok then return nil, tostring(res) end
    return res
end

-- ── EXECUTOR CAPABILITY CHECK ────────────────────────────────────
local hasHookMeta  = type(hookmetamethod) == "function"
local hasHookFn    = type(hookfunction)   == "function"
local hasNewCC     = type(newcclosure)    == "function"
local hasCheckCall = type(checkcaller)    == "function"
local hasDbgInfo   = type(debug) == "table" and type(debug.info) == "function"

-- ── TWEEN HELPERS ────────────────────────────────────────────────
local function tween(obj, time, props, style, dir)
    local ti = TweenInfo.new(time, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out)
    local t = TweenService:Create(obj, ti, props); t:Play(); return t
end
local function hoverFX(obj, rest, hot, prop)
    prop = prop or "BackgroundColor3"
    obj[prop] = rest
    obj.MouseEnter:Connect(function() tween(obj,0.13,{[prop]=hot}) end)
    obj.MouseLeave:Connect(function() tween(obj,0.18,{[prop]=rest}) end)
end
local function corner(obj, r) local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r);c.Parent=obj; return c end
local function pad(obj, l,t,r,b)
    local p=Instance.new("UIPadding")
    p.PaddingLeft=UDim.new(0,l or 0); p.PaddingTop=UDim.new(0,t or 0)
    p.PaddingRight=UDim.new(0,r or 0); p.PaddingBottom=UDim.new(0,b or 0); p.Parent=obj; return p
end

-- ── SETTINGS / STATE ─────────────────────────────────────────────
local settings = {
    captureOut   = true,
    captureIn    = true,
    captureBind  = true,
    mergeRepeats = true,
    autoScroll   = true,
    maxLog       = 200,
}
local blockedNames = {}
local ignoredNames = {}
local paused        = false
local currentPage   = "OUT"          -- OUT · IN · BLOCKED · STATS · SETTINGS
local filterTxt     = ""
local lists         = { OUT={}, IN={} }
local remoteTotals  = {}
local hookedIn      = {}
local selectedEntry = nil
local statGrand     = 0               -- total calls ever captured

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
local function argCount(args) return (type(args)=="table" and args.n) or #args end

local function fmtV(v, d)
    d = d or 0; if d > 2 then return "…" end
    local t = typeof(v)
    if     t=="nil"      then return "nil"
    elseif t=="boolean"  then return tostring(v)
    elseif t=="number"   then return v==math.floor(v) and tostring(math.floor(v)) or ("%.4g"):format(v)
    elseif t=="string"   then local s=v:sub(1,46):gsub("[%c]","·"); return '"'..s..(#v>46 and "…" or "")..'"'
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
local function argType(v) local t=typeof(v); return t=="Instance" and v.ClassName or t end

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
    local n=argCount(entry.args)
    if entry.dir=="IN" then
        local p={}; for i=1,n do p[i]=codeV(entry.args[i]) end
        return "-- incoming: "..path.." ("..table.concat(p,", ")..")"
    end
    local p={}; for i=1,n do p[i]=codeV(entry.args[i]) end
    return path..":"..entry.method.."("..table.concat(p,", ")..")"
end

-- ── TARGET CLASSES ───────────────────────────────────────────────
local TargetClasses = {
    RemoteEvent=true, RemoteFunction=true,
    UnreliableRemoteEvent=true, BindableEvent=true, BindableFunction=true,
}
local OutgoingMethods = {
    FireServer=true, InvokeServer=true, fireServer=true, invokeServer=true,
    Fire=true, Invoke=true, fire=true, invoke=true,
}
local BindClasses = { BindableEvent=true, BindableFunction=true }

-- ── ICONS / COLOURS  (img = Cobalt's official remote asset IDs) ──
local REMOTE_ICON = {
    RemoteEvent           = { icon="⚡", img="rbxassetid://110803789420086", col=Color3.fromRGB(120,150,255) },
    RemoteFunction        = { icon="ƒ",  img="rbxassetid://108537517159060", col=Color3.fromRGB(180,120,255) },
    UnreliableRemoteEvent = { icon="≈",  img="rbxassetid://126244162339059", col=Color3.fromRGB(90,220,190)  },
    BindableEvent         = { icon="◈",  img="rbxassetid://116839398727495", col=Color3.fromRGB(255,190,80)  },
    BindableFunction      = { icon="⬡",  img="rbxassetid://112264959079193", col=Color3.fromRGB(255,135,95)  },
}
local function remoteIcon(entry)
    local r=entry.remote; local cls=r and r.ClassName or ""
    return REMOTE_ICON[cls] or { icon="⚡", col=Color3.fromRGB(160,160,160) }
end
local CALLER_STYLE = {
    executor = { icon=">_", bg=Color3.fromRGB(110,55,10),  fg=Color3.fromRGB(255,170,75)  },
    module   = { icon="◉",  bg=Color3.fromRGB(18,80,30),   fg=Color3.fromRGB(120,225,95)  },
    local_   = { icon="⊡",  bg=Color3.fromRGB(20,55,115),  fg=Color3.fromRGB(120,185,255) },
    server   = { icon="⬡",  bg=Color3.fromRGB(70,30,115),  fg=Color3.fromRGB(200,145,255) },
    default  = { icon="◈",  bg=Color3.fromRGB(42,30,68),   fg=Color3.fromRGB(175,158,222) },
}
local function callerStyle(entry)
    if entry.isExecutor then return CALLER_STYLE.executor end
    local s=(entry.callerSrc or ""):lower()
    if s:find("module") then return CALLER_STYLE.module end
    if s:find("local")  then return CALLER_STYLE.local_ end
    if s:find("server") then return CALLER_STYLE.server end
    if s~="" and s~="unknown" then return CALLER_STYLE.default end
    return nil
end
local TYPE_COLS = {
    string=Color3.fromRGB(90,210,170),   number=Color3.fromRGB(110,160,250),
    boolean=Color3.fromRGB(240,185,90),  Instance=Color3.fromRGB(215,140,235),
    Vector3=Color3.fromRGB(95,225,225),  CFrame=Color3.fromRGB(235,225,95),
    table=Color3.fromRGB(240,115,115),   ["nil"]=Color3.fromRGB(120,120,120),
}
local function tc(t) return TYPE_COLS[t] or Color3.fromRGB(185,185,185) end

-- ── PURPLE PALETTE ───────────────────────────────────────────────
local C_BG      = Color3.fromRGB(15,9,24)
local C_PANEL   = Color3.fromRGB(19,12,32)
local C_PANEL2  = Color3.fromRGB(23,14,40)
local C_RAIL    = Color3.fromRGB(12,7,20)
local C_ROW     = Color3.fromRGB(24,15,40)
local C_ROWALT  = Color3.fromRGB(20,12,34)
local C_SEL     = Color3.fromRGB(52,26,92)
local C_ACCENT  = Color3.fromRGB(140,70,240)
local C_ACCENT2 = Color3.fromRGB(184,116,255)
local C_TEXT    = Color3.fromRGB(232,224,255)
local C_DIM     = Color3.fromRGB(124,108,154)
local C_BORDER  = Color3.fromRGB(48,28,80)
local C_GOOD    = Color3.fromRGB(96,222,142)
local C_BAD     = Color3.fromRGB(236,92,112)

-- ── DIMENSIONS ───────────────────────────────────────────────────
local W, H      = 640, 420   -- Cobalt's exact window size
local TITLE_H   = 30
local RAIL_W    = 50
local LIST_W    = 210
local ITEM_H    = 36

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  TOGGLE PILL  (always visible)                                 ║
-- ╚═══════════════════════════════════════════════════════════════╝
local tSg=Instance.new("ScreenGui")
tSg.Name="VoltToggle"; tSg.ResetOnSpawn=false; tSg.DisplayOrder=10
tSg.Parent=LocalPlayer:WaitForChild("PlayerGui")

local tBtn=Instance.new("TextButton")
tBtn.Size=UDim2.new(0,86,0,24); tBtn.Position=UDim2.new(0.5,-43,0,6)
tBtn.BackgroundColor3=Color3.fromRGB(68,26,138); tBtn.BorderSizePixel=0
tBtn.Text="ϟ  VOLT"; tBtn.TextColor3=C_TEXT
tBtn.Font=Enum.Font.GothamBold; tBtn.TextSize=12; tBtn.AutoButtonColor=false; tBtn.Parent=tSg
corner(tBtn,12)
do
    local g=Instance.new("UIGradient")
    g.Color=ColorSequence.new{
        ColorSequenceKeypoint.new(0,Color3.fromRGB(118,52,214)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(58,18,118)),
    }
    g.Rotation=90; g.Parent=tBtn
end
do local s=Instance.new("UIStroke");s.Color=C_ACCENT2;s.Thickness=1;s.Transparency=0.45;s.Parent=tBtn end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  MAIN WINDOW                                                   ║
-- ╚═══════════════════════════════════════════════════════════════╝
local sg=Instance.new("ScreenGui")
sg.Name="Volt"; sg.ResetOnSpawn=false; sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
sg.Parent=LocalPlayer:WaitForChild("PlayerGui")

local main=Instance.new("Frame")
main.Name="Main"; main.AnchorPoint=Vector2.new(0.5,0.5)
main.Position=UDim2.new(0.5,0,0.5,0); main.Size=UDim2.new(0,W,0,H)
main.BackgroundColor3=C_BG; main.BorderSizePixel=0
main.Active=true; main.Draggable=true; main.Parent=sg
corner(main,11)
do
    local g=Instance.new("UIGradient")
    g.Color=ColorSequence.new{
        ColorSequenceKeypoint.new(0,Color3.fromRGB(27,16,46)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(13,7,23)),
    }
    g.Rotation=120; g.Parent=main
end

-- drop shadow
local shadow=Instance.new("ImageLabel")
shadow.Name="Shadow"; shadow.AnchorPoint=Vector2.new(0.5,0.5)
shadow.Position=UDim2.new(0.5,0,0.5,0); shadow.Size=UDim2.new(1,54,1,54)
shadow.BackgroundTransparency=1; shadow.Image="rbxassetid://6014261993"
shadow.ImageColor3=Color3.fromRGB(92,36,180); shadow.ImageTransparency=0.32
shadow.ScaleType=Enum.ScaleType.Slice; shadow.SliceCenter=Rect.new(49,49,450,450)
shadow.ZIndex=0; shadow.Parent=main

-- animated glow border
local mainStroke=Instance.new("UIStroke")
mainStroke.Color=C_ACCENT; mainStroke.Thickness=1.4; mainStroke.Transparency=0.15; mainStroke.Parent=main
do
    local sg2=Instance.new("UIGradient")
    sg2.Color=ColorSequence.new{
        ColorSequenceKeypoint.new(0,Color3.fromRGB(170,96,255)),
        ColorSequenceKeypoint.new(0.5,Color3.fromRGB(98,42,192)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(170,96,255)),
    }
    sg2.Parent=mainStroke
    task.spawn(function()
        while sg2.Parent do sg2.Rotation=(sg2.Rotation+2)%360; task.wait(0.03) end
    end)
end

-- open animation
main.Size=UDim2.new(0,W*0.92,0,H*0.92); main.BackgroundTransparency=0.4
tween(main,0.28,{Size=UDim2.new(0,W,0,H),BackgroundTransparency=0},Enum.EasingStyle.Back)

-- ── TITLE BAR ────────────────────────────────────────────────────
local titleBar=Instance.new("Frame")
titleBar.Size=UDim2.new(1,0,0,TITLE_H); titleBar.BackgroundColor3=C_PANEL2
titleBar.BorderSizePixel=0; titleBar.Parent=main
corner(titleBar,11)
do -- square off the bottom corners
    local f=Instance.new("Frame"); f.Size=UDim2.new(1,0,0,12); f.Position=UDim2.new(0,0,1,-12)
    f.BackgroundColor3=C_PANEL2; f.BorderSizePixel=0; f.Parent=titleBar
end

local logoBadge=Instance.new("Frame")
logoBadge.Size=UDim2.new(0,24,0,20); logoBadge.Position=UDim2.new(0,6,0.5,-10)
logoBadge.BackgroundColor3=C_ACCENT; logoBadge.BorderSizePixel=0; logoBadge.ZIndex=2; logoBadge.Parent=titleBar
corner(logoBadge,6)
do
    local g=Instance.new("UIGradient")
    g.Color=ColorSequence.new{
        ColorSequenceKeypoint.new(0,Color3.fromRGB(184,98,255)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(92,22,200)),
    }
    g.Rotation=135; g.Parent=logoBadge
end
local bL=Instance.new("TextLabel"); bL.Size=UDim2.new(1,0,1,0); bL.BackgroundTransparency=1
bL.Text="ϟ"; bL.TextColor3=Color3.fromRGB(255,246,205); bL.Font=Enum.Font.GothamBold
bL.TextSize=13; bL.ZIndex=3; bL.Parent=logoBadge

local titleLbl=Instance.new("TextLabel")
titleLbl.Size=UDim2.new(0,90,1,0); titleLbl.Position=UDim2.new(0,36,0,0)
titleLbl.BackgroundTransparency=1; titleLbl.Text="Volt"
titleLbl.TextColor3=C_TEXT; titleLbl.Font=Enum.Font.GothamBold
titleLbl.TextSize=14; titleLbl.TextXAlignment=Enum.TextXAlignment.Left; titleLbl.ZIndex=2; titleLbl.Parent=titleBar

local verPill=Instance.new("TextLabel")
verPill.Size=UDim2.new(0,40,0,14); verPill.Position=UDim2.new(0,78,0.5,-7)
verPill.BackgroundColor3=Color3.fromRGB(40,22,68); verPill.BorderSizePixel=0
verPill.Text="v2.0"; verPill.TextColor3=C_ACCENT2; verPill.Font=Enum.Font.GothamBold
verPill.TextSize=9; verPill.ZIndex=2; verPill.Parent=titleBar
corner(verPill,7)

-- live status dot
local statusDot=Instance.new("Frame")
statusDot.Size=UDim2.new(0,8,0,8); statusDot.Position=UDim2.new(0,126,0.5,-4)
statusDot.BackgroundColor3=C_GOOD; statusDot.BorderSizePixel=0; statusDot.ZIndex=2; statusDot.Parent=titleBar
corner(statusDot,4)
task.spawn(function()
    while statusDot.Parent do
        tween(statusDot,0.7,{BackgroundTransparency=0.6}); task.wait(0.7)
        tween(statusDot,0.7,{BackgroundTransparency=0}); task.wait(0.7)
    end
end)

local function mkTIcon(xOff, txt, col)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,22,0,22); b.Position=UDim2.new(1,xOff,0.5,-11)
    b.BackgroundColor3=C_PANEL2; b.BackgroundTransparency=1; b.BorderSizePixel=0
    b.Text=txt; b.TextColor3=col or C_DIM; b.AutoButtonColor=false
    b.Font=Enum.Font.GothamBold; b.TextSize=12; b.ZIndex=2; b.Parent=titleBar
    corner(b,5)
    b.MouseEnter:Connect(function() tween(b,0.12,{BackgroundTransparency=0.4}) end)
    b.MouseLeave:Connect(function() tween(b,0.16,{BackgroundTransparency=1}) end)
    return b
end
local closeBtn = mkTIcon(-24, "✕", C_BAD)
local minBtn   = mkTIcon(-48, "─", C_DIM)
local clearBtn = mkTIcon(-72, "⌫", C_DIM)
local pauseBtn = mkTIcon(-96, "⏸", C_DIM)

do
    local sep=Instance.new("Frame"); sep.Size=UDim2.new(1,0,0,1); sep.Position=UDim2.new(0,0,1,-1)
    sep.BackgroundColor3=C_BORDER; sep.BorderSizePixel=0; sep.ZIndex=2; sep.Parent=titleBar
end

-- ── NAV RAIL  (vertical icon tabs) ───────────────────────────────
local rail=Instance.new("Frame")
rail.Size=UDim2.new(0,RAIL_W,0,H-TITLE_H); rail.Position=UDim2.new(0,0,0,TITLE_H)
rail.BackgroundColor3=C_RAIL; rail.BorderSizePixel=0; rail.Parent=main

local railLayout=Instance.new("UIListLayout")
railLayout.SortOrder=Enum.SortOrder.LayoutOrder; railLayout.Padding=UDim.new(0,4)
railLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center; railLayout.Parent=rail
pad(rail,0,8,0,0)

local railBtns={}
local PAGES={
    {id="OUT",      icon="↑", name="Outgoing"},
    {id="IN",       icon="↓", name="Incoming"},
    {id="BLOCKED",  icon="⊘", name="Blocked"},
    {id="STATS",    icon="◷", name="Stats"},
    {id="AI",       icon="✦", name="AI Chat"},
    {id="SETTINGS", icon="⚙", name="Settings"},
}
local switchPage  -- forward declare
local function mkRailBtn(def, order)
    local holder=Instance.new("Frame")
    holder.Size=UDim2.new(0,RAIL_W,0,42); holder.BackgroundTransparency=1
    holder.LayoutOrder=order; holder.Parent=rail

    local indic=Instance.new("Frame")  -- left active indicator
    indic.Size=UDim2.new(0,3,0,22); indic.Position=UDim2.new(0,0,0.5,-11)
    indic.BackgroundColor3=C_ACCENT2; indic.BorderSizePixel=0; indic.Visible=false; indic.Parent=holder
    corner(indic,2)

    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,38,0,38); b.Position=UDim2.new(0.5,-19,0.5,-19)
    b.BackgroundColor3=C_PANEL; b.BackgroundTransparency=1; b.BorderSizePixel=0
    b.Text=def.icon; b.TextColor3=C_DIM; b.AutoButtonColor=false
    b.Font=Enum.Font.GothamBold; b.TextSize=18; b.Parent=holder
    corner(b,9)

    local tip=Instance.new("TextLabel")  -- hover tooltip
    tip.Size=UDim2.new(0,72,0,18); tip.Position=UDim2.new(1,4,0.5,-9)
    tip.BackgroundColor3=Color3.fromRGB(34,20,56); tip.BorderSizePixel=0
    tip.Text=def.name; tip.TextColor3=C_TEXT; tip.Font=Enum.Font.GothamMedium
    tip.TextSize=10; tip.Visible=false; tip.ZIndex=20; tip.Parent=b
    corner(tip,5)

    b.MouseEnter:Connect(function()
        tip.Visible=true
        if currentPage~=def.id then tween(b,0.12,{BackgroundTransparency=0.45}) end
    end)
    b.MouseLeave:Connect(function()
        tip.Visible=false
        if currentPage~=def.id then tween(b,0.16,{BackgroundTransparency=1}) end
    end)
    b.MouseButton1Click:Connect(function() switchPage(def.id) end)
    railBtns[def.id]={btn=b, indic=indic}
    return b
end
for i,def in ipairs(PAGES) do mkRailBtn(def,i) end

-- ── CONTENT HOST ─────────────────────────────────────────────────
local content=Instance.new("Frame")
content.Size=UDim2.new(1,-RAIL_W,0,H-TITLE_H); content.Position=UDim2.new(0,RAIL_W,0,TITLE_H)
content.BackgroundTransparency=1; content.Parent=main

-- ╔══════════════ BROWSER PAGE (list + detail) ═══════════════════╗
local browser=Instance.new("Frame")
browser.Size=UDim2.new(1,0,1,0); browser.BackgroundTransparency=1; browser.Parent=content

-- search bar across top of browser
local searchBar=Instance.new("Frame")
searchBar.Size=UDim2.new(1,0,0,30); searchBar.BackgroundColor3=C_PANEL
searchBar.BorderSizePixel=0; searchBar.Parent=browser
do local sep=Instance.new("Frame");sep.Size=UDim2.new(1,0,0,1);sep.Position=UDim2.new(0,0,1,-1)
   sep.BackgroundColor3=C_BORDER;sep.BorderSizePixel=0;sep.Parent=searchBar end

local searchIcon=Instance.new("TextLabel")
searchIcon.Size=UDim2.new(0,20,1,0); searchIcon.Position=UDim2.new(0,6,0,0)
searchIcon.BackgroundTransparency=1; searchIcon.Text="🔍"; searchIcon.TextColor3=C_DIM
searchIcon.Font=Enum.Font.Gotham; searchIcon.TextSize=11; searchIcon.Parent=searchBar

local searchBox=Instance.new("TextBox")
searchBox.Size=UDim2.new(0,LIST_W-52,0,20); searchBox.Position=UDim2.new(0,26,0.5,-10)
searchBox.BackgroundColor3=Color3.fromRGB(26,16,44); searchBox.BorderSizePixel=0
searchBox.Text=""; searchBox.PlaceholderText="filter remotes…"
searchBox.TextColor3=C_TEXT; searchBox.PlaceholderColor3=C_DIM
searchBox.Font=Enum.Font.Gotham; searchBox.TextSize=11; searchBox.ClearTextOnFocus=false
searchBox.TextXAlignment=Enum.TextXAlignment.Left; searchBox.Parent=searchBar
corner(searchBox,5); pad(searchBox,8,0,0,0)

local pageTitle=Instance.new("TextLabel")
pageTitle.Size=UDim2.new(1,-LIST_W-12,1,0); pageTitle.Position=UDim2.new(0,LIST_W+8,0,0)
pageTitle.BackgroundTransparency=1; pageTitle.Text="OUTGOING"
pageTitle.TextColor3=C_ACCENT2; pageTitle.Font=Enum.Font.GothamBold
pageTitle.TextSize=11; pageTitle.TextXAlignment=Enum.TextXAlignment.Left; pageTitle.Parent=searchBar

-- list pane
local leftPane=Instance.new("Frame")
leftPane.Size=UDim2.new(0,LIST_W,1,-30); leftPane.Position=UDim2.new(0,0,0,30)
leftPane.BackgroundColor3=C_PANEL; leftPane.BorderSizePixel=0; leftPane.Parent=browser

local countLbl=Instance.new("TextLabel")
countLbl.Size=UDim2.new(1,-8,0,16); countLbl.Position=UDim2.new(0,8,0,3)
countLbl.BackgroundTransparency=1; countLbl.Text="0 calls"
countLbl.TextColor3=C_DIM; countLbl.Font=Enum.Font.GothamMedium
countLbl.TextSize=9; countLbl.TextXAlignment=Enum.TextXAlignment.Left; countLbl.Parent=leftPane

local scroll=Instance.new("ScrollingFrame")
scroll.Size=UDim2.new(1,0,1,-18); scroll.Position=UDim2.new(0,0,0,18)
scroll.BackgroundTransparency=1; scroll.BorderSizePixel=0
scroll.ScrollBarThickness=3; scroll.ScrollBarImageColor3=C_ACCENT
scroll.CanvasSize=UDim2.new(0,0,0,0); scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; scroll.Parent=leftPane
local listLayout=Instance.new("UIListLayout")
listLayout.SortOrder=Enum.SortOrder.LayoutOrder; listLayout.Padding=UDim.new(0,2); listLayout.Parent=scroll
pad(scroll,4,0,4,4)

local vDiv=Instance.new("Frame"); vDiv.Size=UDim2.new(0,1,1,-30); vDiv.Position=UDim2.new(0,LIST_W,0,30)
vDiv.BackgroundColor3=C_BORDER; vDiv.BorderSizePixel=0; vDiv.Parent=browser

-- detail pane
local rightPane=Instance.new("Frame")
rightPane.Size=UDim2.new(1,-LIST_W-1,1,-30); rightPane.Position=UDim2.new(0,LIST_W+1,0,30)
rightPane.BackgroundColor3=C_BG; rightPane.BackgroundTransparency=0.4; rightPane.BorderSizePixel=0; rightPane.Parent=browser

local detailBar=Instance.new("Frame")
detailBar.Size=UDim2.new(1,0,0,28); detailBar.BackgroundColor3=C_PANEL
detailBar.BorderSizePixel=0; detailBar.Parent=rightPane
do local sep=Instance.new("Frame");sep.Size=UDim2.new(1,0,0,1);sep.Position=UDim2.new(0,0,1,-1)
   sep.BackgroundColor3=C_BORDER;sep.BorderSizePixel=0;sep.Parent=detailBar end

local detailLbl=Instance.new("TextLabel")
detailLbl.Size=UDim2.new(1,-230,1,0); detailLbl.Position=UDim2.new(0,10,0,0)
detailLbl.BackgroundTransparency=1; detailLbl.Text="—"
detailLbl.TextColor3=C_DIM; detailLbl.Font=Enum.Font.GothamBold
detailLbl.TextSize=11; detailLbl.TextXAlignment=Enum.TextXAlignment.Left; detailLbl.Parent=detailBar

local function mkDBtn(xOff, w, txt, col)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,w,0,19); b.Position=UDim2.new(1,xOff,0.5,-9)
    b.BackgroundColor3=col; b.BorderSizePixel=0
    b.Text=txt; b.TextColor3=C_TEXT; b.AutoButtonColor=false
    b.Font=Enum.Font.GothamBold; b.TextSize=9; b.Parent=detailBar
    corner(b,5)
    local r=col
    b.MouseEnter:Connect(function() tween(b,0.12,{BackgroundColor3=r:Lerp(Color3.new(1,1,1),0.18)}) end)
    b.MouseLeave:Connect(function() tween(b,0.16,{BackgroundColor3=r}) end)
    return b
end
local copyBtn     = mkDBtn(-50,  46, "⎘ Copy",  Color3.fromRGB(54,34,90))
local ignEntBtn   = mkDBtn(-100, 48, "◎ Ignore",Color3.fromRGB(40,24,66))
local blockEntBtn = mkDBtn(-152, 50, "⊘ Block", Color3.fromRGB(120,30,30))
local replayBtn   = mkDBtn(-206, 52, "↺ Replay",Color3.fromRGB(80,32,168))
replayBtn.Visible=false; blockEntBtn.Visible=false; ignEntBtn.Visible=false

local argScroll=Instance.new("ScrollingFrame")
argScroll.Size=UDim2.new(1,0,1,-90); argScroll.Position=UDim2.new(0,0,0,28)
argScroll.BackgroundTransparency=1; argScroll.BorderSizePixel=0
argScroll.ScrollBarThickness=3; argScroll.ScrollBarImageColor3=C_ACCENT
argScroll.CanvasSize=UDim2.new(0,0,0,0); argScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; argScroll.Parent=rightPane
local argLayout=Instance.new("UIListLayout")
argLayout.SortOrder=Enum.SortOrder.LayoutOrder; argLayout.Padding=UDim.new(0,1); argLayout.Parent=argScroll

do local dv=Instance.new("Frame");dv.Size=UDim2.new(1,0,0,1);dv.Position=UDim2.new(0,0,1,-62)
   dv.BackgroundColor3=C_BORDER;dv.BorderSizePixel=0;dv.Parent=rightPane end

local codeBox=Instance.new("TextBox")
codeBox.Size=UDim2.new(1,-10,0,56); codeBox.Position=UDim2.new(0,5,1,-60)
codeBox.BackgroundTransparency=1; codeBox.Text=""
codeBox.TextColor3=C_GOOD; codeBox.Font=Enum.Font.Code
codeBox.TextSize=10; codeBox.ClearTextOnFocus=false; codeBox.MultiLine=true
codeBox.TextXAlignment=Enum.TextXAlignment.Left; codeBox.TextYAlignment=Enum.TextYAlignment.Top
codeBox.TextWrapped=true; codeBox.Parent=rightPane

-- ── ARG / CALLER ROWS ────────────────────────────────────────────
local function clearArgScroll()
    for _,c in ipairs(argScroll:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
end
local function addArgRow(lineNum, value, ord)
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,23); row.LayoutOrder=ord
    row.BackgroundColor3=lineNum%2==0 and C_ROWALT or C_ROW
    row.BackgroundTransparency=0.3; row.BorderSizePixel=0; row.Parent=argScroll

    local nL=Instance.new("TextLabel"); nL.Size=UDim2.new(0,28,1,0); nL.BackgroundTransparency=1
    nL.Text=tostring(lineNum); nL.TextColor3=C_ACCENT2; nL.Font=Enum.Font.Code; nL.TextSize=11; nL.Parent=row

    local typ=argType(value)
    local vL=Instance.new("TextLabel"); vL.Size=UDim2.new(1,-110,1,0); vL.Position=UDim2.new(0,30,0,0)
    vL.BackgroundTransparency=1; vL.Text=fmtV(value); vL.TextColor3=tc(typ)
    vL.Font=Enum.Font.Code; vL.TextSize=11
    vL.TextXAlignment=Enum.TextXAlignment.Left; vL.TextTruncate=Enum.TextTruncate.AtEnd; vL.Parent=row

    local tL=Instance.new("TextLabel"); tL.Size=UDim2.new(0,84,1,0); tL.Position=UDim2.new(1,-86,0,0)
    tL.BackgroundTransparency=1; tL.Text=typ; tL.TextColor3=C_DIM
    tL.Font=Enum.Font.Gotham; tL.TextSize=10; tL.TextXAlignment=Enum.TextXAlignment.Right; tL.Parent=row
end
local function addCallerRow(entry, ord)
    local cs=callerStyle(entry)
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,22); row.LayoutOrder=ord
    row.BackgroundColor3=C_PANEL; row.BackgroundTransparency=0.3; row.BorderSizePixel=0; row.Parent=argScroll
    if cs then
        local badge=Instance.new("Frame")
        badge.Size=UDim2.new(0,28,0,14); badge.Position=UDim2.new(0,6,0.5,-7)
        badge.BackgroundColor3=cs.bg; badge.BorderSizePixel=0; badge.Parent=row
        corner(badge,3)
        local bL2=Instance.new("TextLabel"); bL2.Size=UDim2.new(1,0,1,0); bL2.BackgroundTransparency=1
        bL2.Text=cs.icon; bL2.TextColor3=cs.fg; bL2.Font=Enum.Font.GothamBold; bL2.TextSize=9; bL2.Parent=badge
        local src=(entry.isExecutor and "Executor") or (entry.callerSrc~="unknown" and entry.callerSrc or "unknown")
        if entry.callerLine and entry.callerLine>0 and not entry.isExecutor then src=src..":"..entry.callerLine end
        local srcL=Instance.new("TextLabel"); srcL.Size=UDim2.new(1,-130,1,0); srcL.Position=UDim2.new(0,40,0,0)
        srcL.BackgroundTransparency=1; srcL.Text=src; srcL.TextColor3=cs.fg
        srcL.Font=Enum.Font.GothamMedium; srcL.TextSize=10
        srcL.TextXAlignment=Enum.TextXAlignment.Left; srcL.Parent=row
    end
    local tL=Instance.new("TextLabel"); tL.Size=UDim2.new(0,96,1,0); tL.Position=UDim2.new(1,-98,0,0)
    tL.BackgroundTransparency=1; tL.Text="⏱ "..entry.timeStr; tL.TextColor3=C_DIM
    tL.Font=Enum.Font.Gotham; tL.TextSize=9; tL.TextXAlignment=Enum.TextXAlignment.Right; tL.Parent=row
end
local function addNoArgsRow(ord)
    local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,24); row.LayoutOrder=ord
    row.BackgroundTransparency=1; row.Parent=argScroll
    local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1
    lbl.Text="∅  no arguments"; lbl.TextColor3=C_DIM
    lbl.Font=Enum.Font.GothamMedium; lbl.TextSize=10; lbl.Parent=row
end
local function addSectionRow(txt, ord)
    local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,18); row.LayoutOrder=ord
    row.BackgroundColor3=Color3.fromRGB(16,9,28); row.BorderSizePixel=0; row.Parent=argScroll
    local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,-8,1,0); lbl.Position=UDim2.new(0,8,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=txt; lbl.TextColor3=C_GOOD
    lbl.Font=Enum.Font.GothamBold; lbl.TextSize=9; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=row
end

-- ── ENTRY SELECTION ──────────────────────────────────────────────
local function setSelected(entry)
    if selectedEntry and selectedEntry.rowFrame then
        tween(selectedEntry.rowFrame,0.15,{BackgroundColor3=C_ROW})
    end
    selectedEntry=entry
    clearArgScroll()
    if not entry then
        detailLbl.Text="—"; detailLbl.TextColor3=C_DIM; codeBox.Text=""
        replayBtn.Visible=false; blockEntBtn.Visible=false; ignEntBtn.Visible=false
        return
    end
    if entry.rowFrame then tween(entry.rowFrame,0.15,{BackgroundColor3=C_SEL}) end
    detailLbl.Text=(entry.dir=="OUT" and "↑  " or "↓  ")..entry.shortName
    detailLbl.TextColor3=entry.dir=="OUT" and C_ACCENT2 or Color3.fromRGB(136,210,255)

    local ord,n=1,argCount(entry.args)
    if n>0 then for i=1,n do addArgRow(i,entry.args[i],ord); ord=ord+1 end
    else addNoArgsRow(ord); ord=ord+1 end
    -- server return values (RemoteFunction / BindableFunction invokes)
    if entry.returns then
        local rn=argCount(entry.returns)
        addSectionRow("↩  RETURNS ("..rn..")", ord); ord=ord+1
        if rn>0 then for i=1,rn do addArgRow(i,entry.returns[i],ord); ord=ord+1 end
        else
            local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,20); row.LayoutOrder=ord
            row.BackgroundTransparency=1; row.Parent=argScroll
            local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1
            lbl.Text="(void)"; lbl.TextColor3=C_DIM; lbl.Font=Enum.Font.GothamMedium; lbl.TextSize=10; lbl.Parent=row
            ord=ord+1
        end
    end
    addCallerRow(entry,ord)

    codeBox.Text=buildCode(entry)
    replayBtn.Visible=(entry.dir=="OUT")
    blockEntBtn.Visible=true; ignEntBtn.Visible=true
    local isB=blockedNames[entry.name]
    blockEntBtn.Text=isB and "✓ Unblock" or "⊘ Block"
    blockEntBtn.BackgroundColor3=isB and Color3.fromRGB(32,104,44) or Color3.fromRGB(120,30,30)
    local isI=ignoredNames[entry.name]
    ignEntBtn.Text=isI and "● Unign." or "◎ Ignore"
    ignEntBtn.BackgroundColor3=isI and Color3.fromRGB(68,44,108) or Color3.fromRGB(40,24,66)
end

-- ── FILTER / ROW BUILD ───────────────────────────────────────────
local function nameMatch(e)
    if filterTxt=="" then return true end
    return e.name:lower():find(filterTxt:lower(),1,true)~=nil
end
local function pageMatch(e)
    if currentPage=="BLOCKED" then return blockedNames[e.name]==true end
    return not ignoredNames[e.name]
end

local function buildRow(entry, order)
    if entry.rowFrame then entry.rowFrame:Destroy(); entry.rowFrame=nil end
    if not nameMatch(entry) or not pageMatch(entry) then return end

    local isB=blockedNames[entry.name]; local isI=ignoredNames[entry.name]
    local ri=remoteIcon(entry); local cs=callerStyle(entry)

    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,ITEM_H); row.LayoutOrder=order
    row.BackgroundColor3=(selectedEntry==entry) and C_SEL or C_ROW
    row.BorderSizePixel=0; row.ClipsDescendants=true; row.Parent=scroll
    corner(row,6)
    entry.rowFrame=row

    local accentBar=Instance.new("Frame"); accentBar.Size=UDim2.new(0,3,1,0)
    accentBar.BackgroundColor3=isB and C_BAD or (isI and Color3.fromRGB(50,42,72) or ri.col)
    accentBar.BorderSizePixel=0; accentBar.Parent=row

    local iconBg=Instance.new("Frame")
    iconBg.Size=UDim2.new(0,22,0,22); iconBg.Position=UDim2.new(0,8,0.5,-11)
    iconBg.BackgroundColor3=isB and Color3.fromRGB(90,16,16) or ri.col
    iconBg.BackgroundTransparency=0.82; iconBg.BorderSizePixel=0; iconBg.Parent=row
    corner(iconBg,6)
    if ri.img and not isB and not isI then
        -- Cobalt's official remote-type image
        local img=Instance.new("ImageLabel"); img.Size=UDim2.new(0,15,0,15); img.Position=UDim2.new(0.5,-7,0.5,-7)
        img.BackgroundTransparency=1; img.Image=ri.img; img.ImageColor3=ri.col; img.Parent=iconBg
    else
        local iconLbl=Instance.new("TextLabel"); iconLbl.Size=UDim2.new(1,0,1,0); iconLbl.BackgroundTransparency=1
        iconLbl.Text=isB and "⊘" or (isI and "◎" or ri.icon)
        iconLbl.TextColor3=isB and C_BAD or (isI and C_DIM or ri.col)
        iconLbl.Font=Enum.Font.GothamBold; iconLbl.TextSize=11; iconLbl.Parent=iconBg
    end

    local nameCol=isB and C_BAD or (isI and Color3.fromRGB(90,80,118)
        or (entry.dir=="OUT" and C_ACCENT2 or Color3.fromRGB(134,208,255)))
    local nameLbl=Instance.new("TextLabel")
    nameLbl.Size=UDim2.new(1,-78,0,16); nameLbl.Position=UDim2.new(0,36,0,3)
    nameLbl.BackgroundTransparency=1; nameLbl.Text=entry.shortName
    nameLbl.TextColor3=nameCol; nameLbl.Font=Enum.Font.GothamBold; nameLbl.TextSize=11
    nameLbl.TextXAlignment=Enum.TextXAlignment.Left; nameLbl.TextTruncate=Enum.TextTruncate.AtEnd; nameLbl.Parent=row

    if cs then
        local cbg=Instance.new("Frame"); cbg.Size=UDim2.new(0,22,0,12); cbg.Position=UDim2.new(0,36,0,20)
        cbg.BackgroundColor3=cs.bg; cbg.BorderSizePixel=0; cbg.Parent=row
        corner(cbg,3)
        local cI=Instance.new("TextLabel"); cI.Size=UDim2.new(1,0,1,0); cI.BackgroundTransparency=1
        cI.Text=cs.icon; cI.TextColor3=cs.fg; cI.Font=Enum.Font.GothamBold; cI.TextSize=8; cI.Parent=cbg
        local srcName=(entry.isExecutor and "Executor") or (entry.callerSrc~="unknown" and entry.callerSrc or "")
        if srcName~="" then
            local srcL=Instance.new("TextLabel"); srcL.Size=UDim2.new(1,-104,0,12); srcL.Position=UDim2.new(0,62,0,20)
            srcL.BackgroundTransparency=1; srcL.Text=srcName; srcL.TextColor3=C_DIM
            srcL.Font=Enum.Font.Gotham; srcL.TextSize=9
            srcL.TextXAlignment=Enum.TextXAlignment.Left; srcL.TextTruncate=Enum.TextTruncate.AtEnd; srcL.Parent=row
        end
    end

    if entry.count>1 then
        local bg=Instance.new("Frame"); bg.Size=UDim2.new(0,30,0,13); bg.Position=UDim2.new(1,-38,0,4)
        bg.BackgroundColor3=C_ACCENT; bg.BorderSizePixel=0; bg.Parent=row
        corner(bg,6)
        local cL=Instance.new("TextLabel"); cL.Size=UDim2.new(1,0,1,0); cL.BackgroundTransparency=1
        cL.Text="×"..entry.count; cL.TextColor3=Color3.fromRGB(255,255,255)
        cL.Font=Enum.Font.GothamBold; cL.TextSize=8; cL.Parent=bg
    end
    local tot=remoteTotals[entry.name] or 0
    if tot>0 then
        local tbg=Instance.new("Frame"); tbg.Size=UDim2.new(0,34,0,13); tbg.Position=UDim2.new(1,-38,0,19)
        tbg.BackgroundColor3=Color3.fromRGB(9,52,62); tbg.BorderSizePixel=0; tbg.Parent=row
        corner(tbg,6)
        local tL2=Instance.new("TextLabel"); tL2.Size=UDim2.new(1,0,1,0); tL2.BackgroundTransparency=1
        tL2.Text="∑"..tot; tL2.TextColor3=Color3.fromRGB(64,198,184)
        tL2.Font=Enum.Font.GothamBold; tL2.TextSize=8; tL2.Parent=tbg
    end

    local click=Instance.new("TextButton"); click.Size=UDim2.new(1,0,1,0)
    click.BackgroundTransparency=1; click.Text=""; click.ZIndex=2; click.Parent=row
    click.MouseEnter:Connect(function() if selectedEntry~=entry then tween(row,0.12,{BackgroundColor3=C_ROWALT}) end end)
    click.MouseLeave:Connect(function() if selectedEntry~=entry then tween(row,0.16,{BackgroundColor3=C_ROW}) end end)
    click.MouseButton1Click:Connect(function() setSelected(entry) end)
end

local function activeList()
    if currentPage=="IN" then return lists.IN end
    return lists.OUT  -- BLOCKED page pulls from OUT list, filtered
end
local function rebuildAll()
    for _,ch in ipairs(scroll:GetChildren()) do
        if not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then ch:Destroy() end
    end
    local list=activeList()
    for i,e in ipairs(list) do buildRow(e,i) end
    local shown=0
    for _,e in ipairs(list) do if nameMatch(e) and pageMatch(e) then shown=shown+1 end end
    countLbl.Text=shown.." call"..(shown==1 and "" or "s")
end

-- ╔══════════════════════ STATS PAGE ═════════════════════════════╗
local statsPage=Instance.new("ScrollingFrame")
statsPage.Size=UDim2.new(1,0,1,0); statsPage.BackgroundTransparency=1; statsPage.BorderSizePixel=0
statsPage.ScrollBarThickness=3; statsPage.ScrollBarImageColor3=C_ACCENT
statsPage.CanvasSize=UDim2.new(0,0,0,0); statsPage.AutomaticCanvasSize=Enum.AutomaticSize.Y
statsPage.Visible=false; statsPage.Parent=content
local statsLayout=Instance.new("UIListLayout"); statsLayout.Padding=UDim.new(0,8); statsLayout.Parent=statsPage
pad(statsPage,14,14,14,14)

local function mkStatCard(order)
    local card=Instance.new("Frame")
    card.Size=UDim2.new(1,0,0,58); card.BackgroundColor3=C_PANEL; card.BorderSizePixel=0; card.LayoutOrder=order; card.Parent=statsPage
    corner(card,8)
    do local s=Instance.new("UIStroke");s.Color=C_BORDER;s.Thickness=1;s.Transparency=0.4;s.Parent=card end
    return card
end
local function refreshStats()
    for _,c in ipairs(statsPage:GetChildren()) do
        if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
    end
    -- top metrics card
    local top=mkStatCard(1)
    local metrics={
        {"⚡ Total captured", tostring(statGrand), C_ACCENT2},
        {"↑ Outgoing", tostring(#lists.OUT), Color3.fromRGB(150,110,255)},
        {"↓ Incoming", tostring(#lists.IN), Color3.fromRGB(134,208,255)},
        {"⊘ Blocked", tostring((function() local n=0 for _ in pairs(blockedNames) do n=n+1 end return n end)()), C_BAD},
    }
    local mLayout=Instance.new("UIListLayout"); mLayout.FillDirection=Enum.FillDirection.Horizontal
    mLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center; mLayout.VerticalAlignment=Enum.VerticalAlignment.Center
    mLayout.Padding=UDim.new(0,4); mLayout.Parent=top
    for i,m in ipairs(metrics) do
        local cell=Instance.new("Frame"); cell.Size=UDim2.new(0.25,-3,1,-12); cell.BackgroundTransparency=1; cell.LayoutOrder=i; cell.Parent=top
        local v=Instance.new("TextLabel"); v.Size=UDim2.new(1,0,0,24); v.Position=UDim2.new(0,0,0,8)
        v.BackgroundTransparency=1; v.Text=m[2]; v.TextColor3=m[3]; v.Font=Enum.Font.GothamBold; v.TextSize=20; v.Parent=cell
        local k=Instance.new("TextLabel"); k.Size=UDim2.new(1,0,0,14); k.Position=UDim2.new(0,0,0,32)
        k.BackgroundTransparency=1; k.Text=m[1]; k.TextColor3=C_DIM; k.Font=Enum.Font.GothamMedium; k.TextSize=9; k.Parent=cell
    end
    -- top remotes header
    local hdr=Instance.new("TextLabel"); hdr.Size=UDim2.new(1,0,0,18); hdr.BackgroundTransparency=1
    hdr.Text="MOST ACTIVE REMOTES"; hdr.TextColor3=C_DIM; hdr.Font=Enum.Font.GothamBold
    hdr.TextSize=10; hdr.TextXAlignment=Enum.TextXAlignment.Left; hdr.LayoutOrder=2; hdr.Parent=statsPage
    -- sorted totals
    local arr={}
    for name,cnt in pairs(remoteTotals) do arr[#arr+1]={name,cnt} end
    table.sort(arr,function(a,b) return a[2]>b[2] end)
    local maxC=arr[1] and arr[1][2] or 1
    for i=1,math.min(#arr,12) do
        local item=arr[i]
        local short=item[1]:match("[^%.]+%.?[^%.]*$") or item[1]
        local bar=Instance.new("Frame"); bar.Size=UDim2.new(1,0,0,26); bar.BackgroundColor3=C_PANEL
        bar.BorderSizePixel=0; bar.LayoutOrder=2+i; bar.Parent=statsPage
        corner(bar,5)
        local fill=Instance.new("Frame"); fill.Size=UDim2.new(0,0,1,0); fill.BackgroundColor3=C_ACCENT
        fill.BackgroundTransparency=0.55; fill.BorderSizePixel=0; fill.Parent=bar
        corner(fill,5)
        tween(fill,0.5,{Size=UDim2.new(math.clamp(item[2]/maxC,0.04,1),0,1,0)})
        local nm=Instance.new("TextLabel"); nm.Size=UDim2.new(1,-60,1,0); nm.Position=UDim2.new(0,8,0,0)
        nm.BackgroundTransparency=1; nm.Text=short; nm.TextColor3=C_TEXT; nm.Font=Enum.Font.GothamMedium
        nm.TextSize=10; nm.TextXAlignment=Enum.TextXAlignment.Left; nm.TextTruncate=Enum.TextTruncate.AtEnd; nm.ZIndex=2; nm.Parent=bar
        local ct=Instance.new("TextLabel"); ct.Size=UDim2.new(0,52,1,0); ct.Position=UDim2.new(1,-56,0,0)
        ct.BackgroundTransparency=1; ct.Text="∑"..item[2]; ct.TextColor3=C_ACCENT2; ct.Font=Enum.Font.GothamBold
        ct.TextSize=10; ct.TextXAlignment=Enum.TextXAlignment.Right; ct.ZIndex=2; ct.Parent=bar
    end
    if #arr==0 then
        local empty=Instance.new("TextLabel"); empty.Size=UDim2.new(1,0,0,40); empty.BackgroundTransparency=1
        empty.Text="No traffic captured yet…"; empty.TextColor3=C_DIM; empty.Font=Enum.Font.GothamMedium
        empty.TextSize=11; empty.LayoutOrder=3; empty.Parent=statsPage
    end
end

-- ╔════════════════════ SETTINGS PAGE ════════════════════════════╗
local setPage=Instance.new("ScrollingFrame")
setPage.Size=UDim2.new(1,0,1,0); setPage.BackgroundTransparency=1; setPage.BorderSizePixel=0
setPage.ScrollBarThickness=3; setPage.ScrollBarImageColor3=C_ACCENT
setPage.CanvasSize=UDim2.new(0,0,0,0); setPage.AutomaticCanvasSize=Enum.AutomaticSize.Y
setPage.Visible=false; setPage.Parent=content
local setLayout=Instance.new("UIListLayout"); setLayout.Padding=UDim.new(0,6); setLayout.Parent=setPage
pad(setPage,14,14,14,14)

local function mkSectionHdr(txt, order)
    local h=Instance.new("TextLabel"); h.Size=UDim2.new(1,0,0,18); h.BackgroundTransparency=1
    h.Text=txt; h.TextColor3=C_ACCENT2; h.Font=Enum.Font.GothamBold; h.TextSize=10
    h.TextXAlignment=Enum.TextXAlignment.Left; h.LayoutOrder=order; h.Parent=setPage
end
local function mkToggle(label, desc, key, order)
    local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,44); row.BackgroundColor3=C_PANEL
    row.BorderSizePixel=0; row.LayoutOrder=order; row.Parent=setPage
    corner(row,7)
    local nm=Instance.new("TextLabel"); nm.Size=UDim2.new(1,-70,0,18); nm.Position=UDim2.new(0,12,0,5)
    nm.BackgroundTransparency=1; nm.Text=label; nm.TextColor3=C_TEXT; nm.Font=Enum.Font.GothamBold
    nm.TextSize=11; nm.TextXAlignment=Enum.TextXAlignment.Left; nm.Parent=row
    local ds=Instance.new("TextLabel"); ds.Size=UDim2.new(1,-70,0,14); ds.Position=UDim2.new(0,12,0,23)
    ds.BackgroundTransparency=1; ds.Text=desc; ds.TextColor3=C_DIM; ds.Font=Enum.Font.Gotham
    ds.TextSize=9; ds.TextXAlignment=Enum.TextXAlignment.Left; ds.Parent=row

    local track=Instance.new("TextButton"); track.Size=UDim2.new(0,40,0,20); track.Position=UDim2.new(1,-52,0.5,-10)
    track.BorderSizePixel=0; track.Text=""; track.AutoButtonColor=false; track.Parent=row
    corner(track,10)
    local knob=Instance.new("Frame"); knob.Size=UDim2.new(0,16,0,16); knob.BorderSizePixel=0; knob.Parent=track
    corner(knob,8)
    local function paint()
        local on=settings[key]
        tween(track,0.18,{BackgroundColor3=on and C_ACCENT or Color3.fromRGB(40,26,62)})
        tween(knob,0.18,{Position=on and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8),
            BackgroundColor3=on and Color3.fromRGB(255,255,255) or Color3.fromRGB(140,124,168)})
    end
    paint()
    track.MouseButton1Click:Connect(function() settings[key]=not settings[key]; paint() end)
    return row
end
local function mkMaxLogRow(order)
    local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,44); row.BackgroundColor3=C_PANEL
    row.BorderSizePixel=0; row.LayoutOrder=order; row.Parent=setPage
    corner(row,7)
    local nm=Instance.new("TextLabel"); nm.Size=UDim2.new(1,-180,0,18); nm.Position=UDim2.new(0,12,0,5)
    nm.BackgroundTransparency=1; nm.Text="Max log size"; nm.TextColor3=C_TEXT; nm.Font=Enum.Font.GothamBold
    nm.TextSize=11; nm.TextXAlignment=Enum.TextXAlignment.Left; nm.Parent=row
    local ds=Instance.new("TextLabel"); ds.Size=UDim2.new(1,-180,0,14); ds.Position=UDim2.new(0,12,0,23)
    ds.BackgroundTransparency=1; ds.Text="entries kept per tab"; ds.TextColor3=C_DIM; ds.Font=Enum.Font.Gotham
    ds.TextSize=9; ds.TextXAlignment=Enum.TextXAlignment.Left; ds.Parent=row
    local opts={100,200,500,1000}; local chips={}
    local function repaint()
        for val,c in pairs(chips) do
            local on=settings.maxLog==val
            tween(c,0.15,{BackgroundColor3=on and C_ACCENT or Color3.fromRGB(34,22,54)})
            c.TextColor3=on and Color3.fromRGB(255,255,255) or C_DIM
        end
    end
    for i,val in ipairs(opts) do
        local c=Instance.new("TextButton"); c.Size=UDim2.new(0,38,0,22); c.Position=UDim2.new(1,-12-(#opts-i+1)*42,0.5,-11)
        c.BorderSizePixel=0; c.Text=tostring(val); c.Font=Enum.Font.GothamBold; c.TextSize=10; c.AutoButtonColor=false; c.Parent=row
        corner(c,5); chips[val]=c
        c.MouseButton1Click:Connect(function() settings.maxLog=val; repaint() end)
    end
    repaint()
end

mkSectionHdr("CAPTURE", 1)
mkToggle("Capture outgoing", "Log FireServer / InvokeServer calls", "captureOut", 2)
mkToggle("Capture incoming", "Log OnClientEvent / Event signals", "captureIn", 3)
mkToggle("Capture bindables", "Include Bindable Event/Function traffic", "captureBind", 4)
mkSectionHdr("BEHAVIOUR", 5)
mkToggle("Merge repeats", "Collapse identical consecutive calls into ×N", "mergeRepeats", 6)
mkToggle("Auto-scroll", "Follow newest entries as they arrive", "autoScroll", 7)
mkMaxLogRow(8)
mkSectionHdr("MAINTENANCE", 9)
do
    local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,40); row.BackgroundTransparency=1; row.LayoutOrder=10; row.Parent=setPage
    local function actBtn(x,w,txt,col,fn)
        local b=Instance.new("TextButton"); b.Size=UDim2.new(0,w,0,30); b.Position=UDim2.new(0,x,0,4)
        b.BackgroundColor3=col; b.BorderSizePixel=0; b.Text=txt; b.TextColor3=C_TEXT
        b.Font=Enum.Font.GothamBold; b.TextSize=10; b.AutoButtonColor=false; b.Parent=row
        corner(b,6)
        b.MouseEnter:Connect(function() tween(b,0.12,{BackgroundColor3=col:Lerp(Color3.new(1,1,1),0.18)}) end)
        b.MouseLeave:Connect(function() tween(b,0.16,{BackgroundColor3=col}) end)
        b.MouseButton1Click:Connect(fn)
    end
    actBtn(0,   120, "⌫ Clear all logs", Color3.fromRGB(60,30,90), function()
        lists.OUT={}; lists.IN={}; selectedEntry=nil; setSelected(nil); rebuildAll()
    end)
    actBtn(128, 120, "✕ Reset blocks", Color3.fromRGB(120,30,30), function()
        blockedNames={}; ignoredNames={}; rebuildAll(); if selectedEntry then setSelected(selectedEntry) end
    end)
    actBtn(256, 120, "↺ Reset totals", Color3.fromRGB(40,24,66), function()
        remoteTotals={}; statGrand=0; rebuildAll()
    end)
end

-- ╔══════════════════════ AI CHAT PAGE ═══════════════════════════╗
local aiPage=Instance.new("Frame")
aiPage.Size=UDim2.new(1,0,1,0); aiPage.BackgroundTransparency=1; aiPage.Visible=false; aiPage.Parent=content

-- header strip
local aiHdr=Instance.new("Frame")
aiHdr.Size=UDim2.new(1,0,0,30); aiHdr.BackgroundColor3=C_PANEL; aiHdr.BorderSizePixel=0; aiHdr.Parent=aiPage
do local sep=Instance.new("Frame");sep.Size=UDim2.new(1,0,0,1);sep.Position=UDim2.new(0,0,1,-1)
   sep.BackgroundColor3=C_BORDER;sep.BorderSizePixel=0;sep.Parent=aiHdr end
local aiTitle=Instance.new("TextLabel")
aiTitle.Size=UDim2.new(1,-200,1,0); aiTitle.Position=UDim2.new(0,10,0,0)
aiTitle.BackgroundTransparency=1; aiTitle.Text="✦  VOLT AI  ·  Pollinations"
aiTitle.TextColor3=C_ACCENT2; aiTitle.Font=Enum.Font.GothamBold; aiTitle.TextSize=11
aiTitle.TextXAlignment=Enum.TextXAlignment.Left; aiTitle.Parent=aiHdr

-- "explain selected remote" quick action
local aiCtxBtn=Instance.new("TextButton")
aiCtxBtn.Size=UDim2.new(0,116,0,20); aiCtxBtn.Position=UDim2.new(1,-180,0.5,-10)
aiCtxBtn.BackgroundColor3=Color3.fromRGB(54,34,90); aiCtxBtn.BorderSizePixel=0
aiCtxBtn.Text="⎘ Explain remote"; aiCtxBtn.TextColor3=C_TEXT; aiCtxBtn.AutoButtonColor=false
aiCtxBtn.Font=Enum.Font.GothamBold; aiCtxBtn.TextSize=9; aiCtxBtn.Parent=aiHdr
corner(aiCtxBtn,5)
local aiClearBtn=Instance.new("TextButton")
aiClearBtn.Size=UDim2.new(0,52,0,20); aiClearBtn.Position=UDim2.new(1,-58,0.5,-10)
aiClearBtn.BackgroundColor3=Color3.fromRGB(60,30,90); aiClearBtn.BorderSizePixel=0
aiClearBtn.Text="⌫ Clear"; aiClearBtn.TextColor3=C_TEXT; aiClearBtn.AutoButtonColor=false
aiClearBtn.Font=Enum.Font.GothamBold; aiClearBtn.TextSize=9; aiClearBtn.Parent=aiHdr
corner(aiClearBtn,5)

-- message scroll
local aiScroll=Instance.new("ScrollingFrame")
aiScroll.Size=UDim2.new(1,0,1,-74); aiScroll.Position=UDim2.new(0,0,0,30)
aiScroll.BackgroundTransparency=1; aiScroll.BorderSizePixel=0
aiScroll.ScrollBarThickness=3; aiScroll.ScrollBarImageColor3=C_ACCENT
aiScroll.CanvasSize=UDim2.new(0,0,0,0); aiScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; aiScroll.Parent=aiPage
local aiLayout=Instance.new("UIListLayout"); aiLayout.Padding=UDim.new(0,8)
aiLayout.SortOrder=Enum.SortOrder.LayoutOrder; aiLayout.Parent=aiScroll
pad(aiScroll,10,10,10,10)

-- input bar
local aiInputBar=Instance.new("Frame")
aiInputBar.Size=UDim2.new(1,0,0,44); aiInputBar.Position=UDim2.new(0,0,1,-44)
aiInputBar.BackgroundColor3=C_PANEL; aiInputBar.BorderSizePixel=0; aiInputBar.Parent=aiPage
do local sep=Instance.new("Frame");sep.Size=UDim2.new(1,0,0,1)
   sep.BackgroundColor3=C_BORDER;sep.BorderSizePixel=0;sep.Parent=aiInputBar end
local aiInput=Instance.new("TextBox")
aiInput.Size=UDim2.new(1,-70,0,30); aiInput.Position=UDim2.new(0,10,0.5,-15)
aiInput.BackgroundColor3=Color3.fromRGB(26,16,44); aiInput.BorderSizePixel=0
aiInput.Text=""; aiInput.PlaceholderText="Ask Volt AI anything…"
aiInput.TextColor3=C_TEXT; aiInput.PlaceholderColor3=C_DIM
aiInput.Font=Enum.Font.Gotham; aiInput.TextSize=11; aiInput.ClearTextOnFocus=false
aiInput.TextXAlignment=Enum.TextXAlignment.Left; aiInput.ClipsDescendants=true; aiInput.Parent=aiInputBar
corner(aiInput,6); pad(aiInput,8,0,8,0)
local aiSend=Instance.new("TextButton")
aiSend.Size=UDim2.new(0,50,0,30); aiSend.Position=UDim2.new(1,-58,0.5,-15)
aiSend.BackgroundColor3=C_ACCENT; aiSend.BorderSizePixel=0
aiSend.Text="➤"; aiSend.TextColor3=Color3.fromRGB(255,255,255); aiSend.AutoButtonColor=false
aiSend.Font=Enum.Font.GothamBold; aiSend.TextSize=14; aiSend.Parent=aiInputBar
corner(aiSend,6)
hoverFX(aiSend, C_ACCENT, C_ACCENT2)

local aiHistory = { {role="system", content=AI.system} }
local aiBusy = false

local function aiAddBubble(role, text)
    local isUser = (role=="user")
    local holder=Instance.new("Frame")
    holder.Size=UDim2.new(1,0,0,0); holder.AutomaticSize=Enum.AutomaticSize.Y
    holder.BackgroundTransparency=1; holder.LayoutOrder=#aiScroll:GetChildren(); holder.Parent=aiScroll

    local bubble=Instance.new("Frame")
    bubble.AnchorPoint=Vector2.new(isUser and 1 or 0,0)
    bubble.Position=UDim2.new(isUser and 1 or 0,0,0,0)
    bubble.Size=UDim2.new(0.86,0,0,0); bubble.AutomaticSize=Enum.AutomaticSize.Y
    bubble.BackgroundColor3=isUser and Color3.fromRGB(58,32,104) or C_PANEL
    bubble.BorderSizePixel=0; bubble.Parent=holder
    corner(bubble,8)
    do local s=Instance.new("UIStroke");s.Color=isUser and C_ACCENT or C_BORDER;s.Thickness=1;s.Transparency=0.5;s.Parent=bubble end
    pad(bubble,10,7,10,7)

    local who=Instance.new("TextLabel"); who.Size=UDim2.new(1,0,0,12); who.BackgroundTransparency=1
    who.Text=isUser and "you" or "✦ volt ai"; who.TextColor3=isUser and C_ACCENT2 or C_GOOD
    who.Font=Enum.Font.GothamBold; who.TextSize=9; who.TextXAlignment=Enum.TextXAlignment.Left; who.Parent=bubble
    local msg=Instance.new("TextLabel"); msg.Size=UDim2.new(1,0,0,0); msg.Position=UDim2.new(0,0,0,14)
    msg.AutomaticSize=Enum.AutomaticSize.Y; msg.BackgroundTransparency=1
    msg.Text=text; msg.TextColor3=C_TEXT; msg.Font=Enum.Font.Gotham; msg.TextSize=11
    msg.TextWrapped=true; msg.TextXAlignment=Enum.TextXAlignment.Left; msg.TextYAlignment=Enum.TextYAlignment.Top; msg.Parent=bubble
    task.defer(function() aiScroll.CanvasPosition=Vector2.new(0,aiScroll.AbsoluteCanvasSize.Y) end)
    return msg
end

local function aiSendMessage(promptText)
    if aiBusy or promptText=="" then return end
    aiBusy=true
    aiAddBubble("user", promptText)
    table.insert(aiHistory, {role="user", content=promptText})
    local thinking = aiAddBubble("assistant", "thinking…")
    aiInput.Text=""

    task.spawn(function()
        local body = HttpService:JSONEncode({
            model    = AI.model,
            messages = aiHistory,
            stream   = false,
        })
        local res, err = httpRequest({
            Url     = AI.endpoint,
            Method  = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body    = body,
        })
        local reply
        if not res then
            reply = "⚠ HTTP error: "..tostring(err)
        else
            local code = res.StatusCode or res.status_code or 0
            local raw  = res.Body or res.body or ""
            if code>=200 and code<300 then
                -- Pollinations may reply as OpenAI-JSON or as plain text
                local ok, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
                if ok and type(decoded)=="table" and decoded.choices and decoded.choices[1] then
                    reply = decoded.choices[1].message and decoded.choices[1].message.content
                        or decoded.choices[1].text
                elseif raw~="" then
                    reply = raw   -- plain-text completion
                end
                if reply and reply~="" then
                    table.insert(aiHistory, {role="assistant", content=reply})
                else
                    reply = "⚠ Empty response from AI."
                end
            else
                reply = ("⚠ API %d:\n%s"):format(code, raw:sub(1,400))
            end
        end
        thinking.Text = reply
        task.defer(function() aiScroll.CanvasPosition=Vector2.new(0,aiScroll.AbsoluteCanvasSize.Y) end)
        aiBusy=false
    end)
end

aiSend.MouseButton1Click:Connect(function() aiSendMessage(aiInput.Text) end)
aiInput.FocusLost:Connect(function(enter) if enter then aiSendMessage(aiInput.Text) end end)
aiCtxBtn.MouseButton1Click:Connect(function()
    if not selectedEntry then aiAddBubble("assistant","Select a remote in the Outgoing/Incoming tab first, then I'll explain it."); return end
    aiSendMessage("Explain this Roblox remote call and what it likely does:\n\n"..buildCode(selectedEntry))
end)
aiClearBtn.MouseButton1Click:Connect(function()
    for _,c in ipairs(aiScroll:GetChildren()) do
        if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
    end
    aiHistory = { {role="system", content=AI.system} }
end)
-- greeting
aiAddBubble("assistant","Hey — I'm Volt AI, running free on Pollinations. Ask me to explain a captured remote, write Luau, or debug a script. Hit “Explain remote” to analyse your current selection.")

-- ── PAGE SWITCHING ───────────────────────────────────────────────
switchPage=function(id)
    currentPage=id
    for pid,o in pairs(railBtns) do
        local on=(pid==id)
        o.indic.Visible=on
        tween(o.btn,0.15,{BackgroundTransparency=on and 0 or 1,
            BackgroundColor3=on and C_ACCENT or C_PANEL})
        o.btn.TextColor3=on and Color3.fromRGB(255,255,255) or C_DIM
    end
    local isBrowser=(id=="OUT" or id=="IN" or id=="BLOCKED")
    browser.Visible=isBrowser
    statsPage.Visible=(id=="STATS")
    setPage.Visible=(id=="SETTINGS")
    aiPage.Visible=(id=="AI")
    if isBrowser then
        local titles={OUT="OUTGOING ↑", IN="INCOMING ↓", BLOCKED="BLOCKED ⊘"}
        pageTitle.Text=titles[id]
        setSelected(nil); rebuildAll()
    elseif id=="STATS" then refreshStats() end
end

-- ── LOG CALL ─────────────────────────────────────────────────────
local function logCall(dir,remote,args,method,callerSrc,callerLine,isExec,returns)
    if paused then return end
    if dir=="OUT" and not settings.captureOut then return end
    if dir=="IN"  and not settings.captureIn  then return end
    if remote and BindClasses[remote.ClassName] and not settings.captureBind then return end

    local fullName
    pcall(function() fullName=remote:GetFullName() end)
    fullName=fullName or remote.Name
    remoteTotals[fullName]=(remoteTotals[fullName] or 0)+1
    statGrand=statGrand+1
    if ignoredNames[fullName] then return end

    local parts={}; for p in fullName:gmatch("[^%.]+") do parts[#parts+1]=p end
    local shortName=#parts>=2 and (parts[#parts-1].."."..parts[#parts]) or (parts[#parts] or remote.Name)
    local now=os.date("*t")
    local timeStr=("%02d:%02d:%02d"):format(now.hour,now.min,now.sec)
    local list=lists[dir]

    local last=list[#list]
    if settings.mergeRepeats and last and last.name==fullName and last.method==method then
        last.count=last.count+1; last.timeStr=timeStr; last.args=args; last.returns=returns
        local onPage=(dir==currentPage) or (currentPage=="BLOCKED" and dir=="OUT")
        if last.rowFrame and onPage then buildRow(last,#list) end
        if selectedEntry==last then setSelected(last) end
        return
    end

    if #list>=settings.maxLog then
        local oldest=table.remove(list,1)
        if oldest.rowFrame then oldest.rowFrame:Destroy() end
        if selectedEntry==oldest then setSelected(nil) end
    end

    local entry={
        dir=dir,remote=remote,name=fullName,shortName=shortName,
        method=method,args=args,count=1,timeStr=timeStr,returns=returns,
        callerSrc=callerSrc,callerLine=callerLine,isExecutor=isExec,rowFrame=nil,
    }
    table.insert(list,entry)
    local onPage=(dir==currentPage) or (currentPage=="BLOCKED" and dir=="OUT")
    if onPage then
        buildRow(entry,#list)
        local shown=0
        for _,e in ipairs(list) do if nameMatch(e) and pageMatch(e) then shown=shown+1 end end
        countLbl.Text=shown.." call"..(shown==1 and "" or "s")
        if settings.autoScroll then
            task.defer(function() scroll.CanvasPosition=Vector2.new(0,scroll.AbsoluteCanvasSize.Y) end)
        end
    end
end

-- ── OUTGOING HOOKS ───────────────────────────────────────────────
local InvokeMethods = { InvokeServer=true, Invoke=true, invokeServer=true, invoke=true }
if hasHookMeta then
    local oldNC
    local hook=function(...)
        local self=...; local m=getnamecallmethod()
        if typeof(self)=="Instance" and TargetClasses[self.ClassName] and OutgoingMethods[m] then
            local n; pcall(function() n=self:GetFullName() end); n=n or self.Name
            if blockedNames[n] then return end
            local src,line=getCallerInfo()
            local isExec=hasCheckCall and checkcaller() or false
            local packed=table.pack(select(2,...))
            if InvokeMethods[m] then
                -- function call: run it, capture what the server returns
                local rets=table.pack(oldNC(...))
                task.defer(logCall,"OUT",self,packed,m,src,line,isExec,rets)
                return table.unpack(rets,1,rets.n)
            end
            task.defer(logCall,"OUT",self,packed,m,src,line,isExec)
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
                task.defer(logCall,"OUT",self,table.pack(...),methodName,src,line,false)
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

-- ── INCOMING HOOKS ───────────────────────────────────────────────
local function hookIncoming(remote)
    if hookedIn[remote] then return end; hookedIn[remote]=true
    if remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent") then
        remote.OnClientEvent:Connect(function(...) logCall("IN",remote,table.pack(...),"OnClientEvent",nil,-1,false) end)
    elseif remote:IsA("BindableEvent") then
        remote.Event:Connect(function(...) logCall("IN",remote,table.pack(...),"Event",nil,-1,false) end)
    end
end
task.spawn(function()
    for _,v in ipairs(game:GetDescendants()) do if TargetClasses[v.ClassName] then hookIncoming(v) end end
    game.DescendantAdded:Connect(function(v) if TargetClasses[v.ClassName] then task.defer(hookIncoming,v) end end)
    if getnilinstances then
        for _,v in ipairs(getnilinstances()) do if TargetClasses[v.ClassName] then hookIncoming(v) end end
    end
end)

-- ── CONTROL HANDLERS ─────────────────────────────────────────────
searchBox:GetPropertyChangedSignal("Text"):Connect(function() filterTxt=searchBox.Text; rebuildAll() end)

pauseBtn.MouseButton1Click:Connect(function()
    paused=not paused
    pauseBtn.Text=paused and "▶" or "⏸"
    pauseBtn.TextColor3=paused and C_GOOD or C_DIM
    tween(statusDot,0.2,{BackgroundColor3=paused and Color3.fromRGB(240,180,70) or C_GOOD})
end)
clearBtn.MouseButton1Click:Connect(function()
    if currentPage=="OUT" or currentPage=="BLOCKED" then lists.OUT={} elseif currentPage=="IN" then lists.IN={} end
    setSelected(nil); rebuildAll()
end)
copyBtn.MouseButton1Click:Connect(function()
    if not selectedEntry then return end
    pcall(function() setclipboard(buildCode(selectedEntry)) end)
    copyBtn.Text="✓ Done"; task.delay(1.4,function() copyBtn.Text="⎘ Copy" end)
end)
replayBtn.MouseButton1Click:Connect(function()
    if not selectedEntry or selectedEntry.dir~="OUT" then return end
    local r=selectedEntry.remote; local a=selectedEntry.args
    if r and r.Parent then
        pcall(function() r:FireServer(table.unpack(a,1,argCount(a))) end)
        replayBtn.Text="✓ Fired"; task.delay(1.1,function() replayBtn.Text="↺ Replay" end)
    end
end)
blockEntBtn.MouseButton1Click:Connect(function()
    if not selectedEntry then return end
    local n=selectedEntry.name
    blockedNames[n]=(not blockedNames[n]) or nil
    setSelected(selectedEntry); rebuildAll()
end)
ignEntBtn.MouseButton1Click:Connect(function()
    if not selectedEntry then return end
    local n=selectedEntry.name
    ignoredNames[n]=(not ignoredNames[n]) or nil
    setSelected(selectedEntry); rebuildAll()
end)

-- minimize / close / toggle
local minimized=false
minBtn.MouseButton1Click:Connect(function()
    minimized=not minimized
    content.Visible=not minimized; rail.Visible=not minimized
    tween(main,0.2,{Size=minimized and UDim2.new(0,W,0,TITLE_H) or UDim2.new(0,W,0,H)})
    minBtn.Text=minimized and "+" or "─"
end)
closeBtn.MouseButton1Click:Connect(function()
    tween(main,0.18,{Size=UDim2.new(0,W*0.9,0,H*0.9),BackgroundTransparency=0.5})
    task.delay(0.18,function() main.Visible=false; main.BackgroundTransparency=0 end)
    tBtn.Text="ϟ  VOLT  ▸"
end)
tBtn.MouseButton1Click:Connect(function()
    if main.Visible then
        tween(main,0.18,{Size=UDim2.new(0,W*0.9,0,H*0.9),BackgroundTransparency=0.5})
        task.delay(0.18,function() main.Visible=false; main.BackgroundTransparency=0 end)
        tBtn.Text="ϟ  VOLT  ▸"
    else
        main.Visible=true; minimized=false; minBtn.Text="─"
        content.Visible=true; rail.Visible=true
        main.Size=UDim2.new(0,W*0.92,0,H*0.92); main.BackgroundTransparency=0.4
        tween(main,0.26,{Size=UDim2.new(0,W,0,H),BackgroundTransparency=0},Enum.EasingStyle.Back)
        tBtn.Text="ϟ  VOLT"
    end
end)
tBtn.MouseEnter:Connect(function() tween(tBtn,0.12,{Size=UDim2.new(0,92,0,26),Position=UDim2.new(0.5,-46,0,5)}) end)
tBtn.MouseLeave:Connect(function() tween(tBtn,0.16,{Size=UDim2.new(0,86,0,24),Position=UDim2.new(0.5,-43,0,6)}) end)

switchPage("OUT")

print(("[Volt v2] hookMeta:%s hookFn:%s dbgInfo:%s"):format(
    tostring(hasHookMeta),tostring(hasHookFn),tostring(hasDbgInfo)))
