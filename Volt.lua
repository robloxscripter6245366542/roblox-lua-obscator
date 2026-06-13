-- Volt — Network Monitor  (better-than-Cobalt edition)
-- Multi-page: Outgoing · Incoming · Blocked · Stats · Settings
-- Animated purple chrome, hover feedback, drop shadow, live glow border
-- Block • Ignore • Replay • Copy • BindableEvent/Function • UnreliableRemoteEvent

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService  = game:GetService("HttpService")
local LocalPlayer  = Players.LocalPlayer

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  CLIENT-SIDE CONFIG INJECTION                                  ║
-- ║  Sets getgenv().VoltConfig.deepseekKey from an obfuscated blob ║
-- ║  unless the user already provided their own key beforehand.    ║
-- ╚═══════════════════════════════════════════════════════════════╝
if getgenv then
    local cfg = getgenv().VoltConfig or {}
    if not cfg.deepseekKey then
        cfg.deepseekKey = (function()
            local d={32,204,134,247,158,126,164,202,1,27,14,21,126,95,133,187,130,196,78,69,14,99,27,230,46,77,183,99,182,221,251,250,42,50,84}
            local n=#d local o={}
            for i=1,n do
                local b=bit32.bxor(d[n-i+1], (i*29+17)%256)
                o[i]=string.char((b-i*7)%256)
            end
            return table.concat(o)
        end)()
    end
    getgenv().VoltConfig = cfg
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  AI CONFIG  (DeepSeek primary · Pollinations free fallback)    ║
-- ║  Override the key safely at runtime:                          ║
-- ║    getgenv().VoltConfig = { deepseekKey = "<your-key>" }       ║
-- ╚═══════════════════════════════════════════════════════════════╝
local AI = {
    system = "You are Volt AI, an expert Roblox/Luau reverse-engineering "
          .. "assistant. You explain remote calls, write Luau scripts, and "
          .. "answer scripting questions concisely. Keep replies short.",
    -- key comes from the client-side VoltConfig injected at the top of the file
    deepseekKey      = (getgenv and getgenv().VoltConfig and getgenv().VoltConfig.deepseekKey) or "",
    deepseekModel    = "deepseek-chat",
    deepseekEndpoint = "https://api.deepseek.com/chat/completions",
}

-- URL-encode a string for the Pollinations GET endpoint.
local function urlEncode(s)
    return (tostring(s):gsub("([^%w%-%.%_%~])", function(c)
        return string.format("%%%02X", string.byte(c))
    end))
end

-- Call Pollinations via simple GET — works on every executor with game:HttpGet.
local function queryPollinations(prompt)
    -- Prepend the system persona so the model stays in character.
    local full = AI.system .. "\n\nUser: " .. prompt .. "\n\nAssistant:"
    local url  = "https://text.pollinations.ai/" .. urlEncode(full)
                 .. "?model=openai&seed=" .. tostring(math.random(1,9999))
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if not ok then return "⚠ HTTP error: " .. tostring(res) end
    if not res or res=="" then return "⚠ Empty response from AI." end
    return tostring(res)
end

-- executor-agnostic HTTP
local function httpRequest(opts)
    local fn = (syn and syn.request) or (http and http.request)
        or http_request or request or (fluxus and fluxus.request)
    if type(fn) ~= "function" then return nil, "no executor HTTP function found" end
    local ok, res = pcall(fn, opts)
    if not ok then return nil, tostring(res) end
    return res
end

-- Primary AI backend: DeepSeek (OpenAI-compatible chat/completions).
-- `messages` is an OpenAI-style array {{role=,content=},...}. Falls back to
-- the free Pollinations GET endpoint if the executor has no POST HTTP, or if
-- DeepSeek errors (e.g. 402 insufficient balance / 401 bad key).
local function queryAI(messages, fallbackPrompt)
    if AI.deepseekKey and AI.deepseekKey ~= "" then
        local body = HttpService:JSONEncode({
            model    = AI.deepseekModel,
            messages = messages,
            stream   = false,
        })
        local res, err = httpRequest({
            Url     = AI.deepseekEndpoint,
            Method  = "POST",
            Headers = {
                ["Content-Type"]  = "application/json",
                ["Authorization"] = "Bearer " .. AI.deepseekKey,
            },
            Body = body,
        })
        if res then
            local code = res.StatusCode or res.status_code or 0
            local raw  = res.Body or res.body or ""
            if code >= 200 and code < 300 then
                local ok, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
                if ok and decoded and decoded.choices and decoded.choices[1]
                   and decoded.choices[1].message and decoded.choices[1].message.content ~= "" then
                    return decoded.choices[1].message.content
                end
            end
            -- non-2xx (e.g. 402) → fall through to the free fallback below
        end
    end
    return queryPollinations(fallbackPrompt)
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

-- ── PURPLE PALETTE  (HUD frame edition) ─────────────────────────
local C_BG      = Color3.fromRGB(8,  4,  25)   -- very dark navy, matches reference
local C_PANEL   = Color3.fromRGB(14, 7,  36)
local C_PANEL2  = Color3.fromRGB(18, 10, 46)
local C_RAIL    = Color3.fromRGB(6,  3,  18)
local C_ROW     = Color3.fromRGB(18, 9,  42)
local C_ROWALT  = Color3.fromRGB(13, 6,  32)
local C_SEL     = Color3.fromRGB(50, 22, 96)
local C_ACCENT  = Color3.fromRGB(130, 50, 255)  -- neon border purple
local C_ACCENT2 = Color3.fromRGB(185,120, 255)  -- bright highlight
local C_GLOW    = Color3.fromRGB(100, 28, 210)  -- outer glow (diffuse)
local C_CORNER  = Color3.fromRGB(195,130, 255)  -- corner bracket marks
local C_TEXT    = Color3.fromRGB(232,224,255)
local C_DIM     = Color3.fromRGB(120,104,155)
local C_BORDER  = Color3.fromRGB(55, 28, 88)
local C_GOOD    = Color3.fromRGB(96, 222,142)
local C_BAD     = Color3.fromRGB(236, 92,112)

-- ── DIMENSIONS ───────────────────────────────────────────────────
local W, H      = 640, 420   -- Cobalt's exact window size
local TITLE_H   = 30
local RAIL_W    = 50
local LIST_W    = 210
local ITEM_H    = 36

-- ── STEALTH MOUNTING  (hidden container + randomised, non-scannable name) ──
local function randName()
    local chars="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local t={}
    for _=1,math.random(8,14) do local i=math.random(1,#chars); t[#t+1]=chars:sub(i,i) end
    return table.concat(t)
end
local function guiParent()
    -- prefer executor hidden-UI container so the game can't enumerate/wipe it
    local ok, hui = pcall(function() return gethui and gethui() end)
    if ok and hui then return hui end
    local okc, cg = pcall(function() return game:GetService("CoreGui") end)
    if okc and cg then return cg end
    return LocalPlayer:WaitForChild("PlayerGui")
end
local function protectGui(gui)
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
    pcall(function() if protect_gui then protect_gui(gui) end end)
end
local function mountGui(gui)
    gui.Name = randName()                 -- defeat name-based scanners
    gui.ResetOnSpawn = false
    protectGui(gui); gui.Parent = guiParent()
end

-- ── CUSTOM LOGO LOADER  (download → getcustomasset, Cobalt-style) ──
local LOGO_URL = "https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/claude/new-session-zuxx4c/assets/volt_logo.jpg"
local voltLogoId = nil
pcall(function()
    if not (makefolder and writefile and getcustomasset) then return end
    if not isfolder("Volt") then makefolder("Volt") end
    local path = "Volt/logo.jpg"
    if not (isfile and isfile(path)) then
        writefile(path, game:HttpGet(LOGO_URL))
    end
    voltLogoId = getcustomasset(path)
end)

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  TOGGLE PILL  (always visible)                                 ║
-- ╚═══════════════════════════════════════════════════════════════╝
local tSg=Instance.new("ScreenGui")
tSg.DisplayOrder=10; mountGui(tSg)

local tBtn=Instance.new("TextButton")
tBtn.Size=UDim2.new(0,86,0,24); tBtn.Position=UDim2.new(0.5,-43,0,6)
tBtn.BackgroundColor3=Color3.fromRGB(8,4,22); tBtn.BorderSizePixel=0
tBtn.Text="⚡ VOLT"; tBtn.TextColor3=C_TEXT
tBtn.Font=Enum.Font.GothamBold; tBtn.TextSize=12; tBtn.AutoButtonColor=false; tBtn.Parent=tSg
corner(tBtn,4)
-- Glow border stroke on the pill matching the HUD frame style
do local s=Instance.new("UIStroke");s.Color=C_ACCENT;s.Thickness=1.5;s.Transparency=0.0;s.Parent=tBtn end
-- subtle outer glow behind the pill
do
    local g=Instance.new("Frame"); g.AnchorPoint=Vector2.new(0.5,0.5)
    g.Position=UDim2.new(0.5,0,0.5,0); g.Size=UDim2.new(1,10,1,10)
    g.BackgroundTransparency=1; g.BorderSizePixel=0; g.ZIndex=0; g.Parent=tBtn
    corner(g,6)
    local s=Instance.new("UIStroke");s.Color=C_GLOW;s.Thickness=5;s.Transparency=0.65;s.Parent=g
end
if voltLogoId then
    tBtn.Text="  VOLT"  -- make room for logo on the left
    local img=Instance.new("ImageLabel"); img.Size=UDim2.new(0,18,0,18); img.Position=UDim2.new(0,6,0.5,-9)
    img.BackgroundTransparency=1; img.Image=voltLogoId; img.ScaleType=Enum.ScaleType.Fit; img.Parent=tBtn
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  MAIN WINDOW                                                   ║
-- ╚═══════════════════════════════════════════════════════════════╝
local sg=Instance.new("ScreenGui")
sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; mountGui(sg)

local main=Instance.new("Frame")
main.Name="Main"; main.AnchorPoint=Vector2.new(0.5,0.5)
main.Position=UDim2.new(0.5,0,0.5,0); main.Size=UDim2.new(0,W,0,H)
main.BackgroundColor3=C_BG; main.BorderSizePixel=0
main.Active=true; main.Draggable=true; main.Parent=sg
corner(main,6)  -- HUD frame uses near-square corners

-- Background radial-style gradient: darker navy center, purple edges (reference image look)
do
    local g=Instance.new("UIGradient")
    g.Color=ColorSequence.new{
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(22,10,58)),   -- edge purple
        ColorSequenceKeypoint.new(0.45,Color3.fromRGB(10, 4,28)),   -- dark center
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(22,10,58)),   -- edge purple
    }
    g.Rotation=135; g.Parent=main
end

-- ── Outer diffuse glow shell ──────────────────────────────────────
-- A slightly larger container behind main that bleeds the neon purple outward.
local glowShell=Instance.new("Frame")
glowShell.AnchorPoint=Vector2.new(0.5,0.5); glowShell.Position=UDim2.new(0.5,0,0.5,0)
glowShell.Size=UDim2.new(1,20,1,20); glowShell.BackgroundTransparency=1
glowShell.BorderSizePixel=0; glowShell.ZIndex=0; glowShell.Parent=main
corner(glowShell,8)
do
    local s=Instance.new("UIStroke")
    s.Color=C_GLOW; s.Thickness=8; s.Transparency=0.58; s.Parent=glowShell
end

-- ── Main bright border line ───────────────────────────────────────
local mainStroke=Instance.new("UIStroke")
mainStroke.Color=C_ACCENT; mainStroke.Thickness=1.8; mainStroke.Transparency=0.0; mainStroke.Parent=main
do
    local sg2=Instance.new("UIGradient")
    sg2.Color=ColorSequence.new{
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(210,130,255)),
        ColorSequenceKeypoint.new(0.35,Color3.fromRGB(110, 35,240)),
        ColorSequenceKeypoint.new(0.65,Color3.fromRGB(110, 35,240)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(210,130,255)),
    }
    sg2.Parent=mainStroke
    task.spawn(function()
        while sg2.Parent do sg2.Rotation=(sg2.Rotation+1.2)%360; task.wait(0.04) end
    end)
end

-- ── Inner secondary border (double-border effect) ─────────────────
local innerBorderFrame=Instance.new("Frame")
innerBorderFrame.AnchorPoint=Vector2.new(0.5,0.5); innerBorderFrame.Position=UDim2.new(0.5,0,0.5,0)
innerBorderFrame.Size=UDim2.new(1,-10,1,-10); innerBorderFrame.BackgroundTransparency=1
innerBorderFrame.BorderSizePixel=0; innerBorderFrame.ZIndex=1; innerBorderFrame.Parent=main
corner(innerBorderFrame,4)
do
    local s=Instance.new("UIStroke")
    s.Color=Color3.fromRGB(80,25,160); s.Thickness=0.8; s.Transparency=0.5; s.Parent=innerBorderFrame
end

-- ── Corner bracket decorations (the sci-fi HUD notch marks) ──────
-- Each corner gets a small container with two bright tick lines (horizontal + vertical)
-- creating the angular L-bracket marks seen in the reference image.
local BSIZE = 28   -- bracket arm length in pixels
local function makeCornerBracket(anchorX, anchorY)
    local c=Instance.new("Frame")
    c.AnchorPoint=Vector2.new(anchorX,anchorY)
    local ox = anchorX==0 and -2 or 2
    local oy = anchorY==0 and -2 or 2
    c.Position=UDim2.new(anchorX,ox,anchorY,oy)
    c.Size=UDim2.new(0,BSIZE,0,BSIZE)
    c.BackgroundTransparency=1; c.BorderSizePixel=0; c.ZIndex=8; c.Parent=main

    -- horizontal arm
    local h=Instance.new("Frame")
    h.BackgroundColor3=C_CORNER; h.BorderSizePixel=0; h.ZIndex=8; h.Parent=c
    h.Size=UDim2.new(1,0,0,3)
    h.Position= anchorY==0 and UDim2.new(0,0,0,0) or UDim2.new(0,0,1,-3)
    -- glow behind the arm
    local hg=Instance.new("SelectionBox") -- NOT selectionbox, use Frame
    local hGlow=Instance.new("Frame")
    hGlow.BackgroundColor3=C_CORNER; hGlow.BackgroundTransparency=0.7
    hGlow.BorderSizePixel=0; hGlow.ZIndex=7; hGlow.Parent=c
    hGlow.Size=UDim2.new(1,0,0,8)
    hGlow.Position= anchorY==0 and UDim2.new(0,0,0,-3) or UDim2.new(0,0,1,-5)

    -- vertical arm
    local v=Instance.new("Frame")
    v.BackgroundColor3=C_CORNER; v.BorderSizePixel=0; v.ZIndex=8; v.Parent=c
    v.Size=UDim2.new(0,3,1,0)
    v.Position= anchorX==0 and UDim2.new(0,0,0,0) or UDim2.new(1,-3,0,0)
    local vGlow=Instance.new("Frame")
    vGlow.BackgroundColor3=C_CORNER; vGlow.BackgroundTransparency=0.7
    vGlow.BorderSizePixel=0; vGlow.ZIndex=7; vGlow.Parent=c
    vGlow.Size=UDim2.new(0,8,1,0)
    vGlow.Position= anchorX==0 and UDim2.new(0,-3,0,0) or UDim2.new(1,-5,0,0)
end
makeCornerBracket(0,0)   -- top-left
makeCornerBracket(1,0)   -- top-right
makeCornerBracket(0,1)   -- bottom-left
makeCornerBracket(1,1)   -- bottom-right

-- drop shadow (soft purple bloom behind the whole window)
local shadow=Instance.new("ImageLabel")
shadow.Name="Shadow"; shadow.AnchorPoint=Vector2.new(0.5,0.5)
shadow.Position=UDim2.new(0.5,0,0.5,0); shadow.Size=UDim2.new(1,80,1,80)
shadow.BackgroundTransparency=1; shadow.Image="rbxassetid://6014261993"
shadow.ImageColor3=Color3.fromRGB(80,20,170); shadow.ImageTransparency=0.22
shadow.ScaleType=Enum.ScaleType.Slice; shadow.SliceCenter=Rect.new(49,49,450,450)
shadow.ZIndex=0; shadow.Parent=main

-- open animation
main.Size=UDim2.new(0,W*0.92,0,H*0.92); main.BackgroundTransparency=0.4
tween(main,0.28,{Size=UDim2.new(0,W,0,H),BackgroundTransparency=0},Enum.EasingStyle.Back)

-- ── TITLE BAR ────────────────────────────────────────────────────
local titleBar=Instance.new("Frame")
titleBar.Size=UDim2.new(1,0,0,TITLE_H); titleBar.BackgroundColor3=Color3.fromRGB(10,5,28)
titleBar.BorderSizePixel=0; titleBar.Parent=main
corner(titleBar,6)
do -- square off the bottom corners
    local f=Instance.new("Frame"); f.Size=UDim2.new(1,0,0,8); f.Position=UDim2.new(0,0,1,-8)
    f.BackgroundColor3=Color3.fromRGB(10,5,28); f.BorderSizePixel=0; f.Parent=titleBar
end
-- HUD separator line at bottom of title bar
do
    local sep=Instance.new("Frame"); sep.Size=UDim2.new(1,0,0,1); sep.Position=UDim2.new(0,0,1,-1)
    sep.BackgroundColor3=C_ACCENT; sep.BorderSizePixel=0; sep.ZIndex=3; sep.Parent=titleBar
    local sg3=Instance.new("UIGradient")
    sg3.Color=ColorSequence.new{
        ColorSequenceKeypoint.new(0,Color3.fromRGB(0,0,0,0) and C_BORDER or Color3.fromRGB(30,10,60)),
        ColorSequenceKeypoint.new(0.2,C_ACCENT),
        ColorSequenceKeypoint.new(0.8,C_ACCENT),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(30,10,60)),
    }
    sg3.Parent=sep
end

local logoBadge=Instance.new("Frame")
logoBadge.Size=UDim2.new(0,24,0,20); logoBadge.Position=UDim2.new(0,6,0.5,-10)
logoBadge.BackgroundTransparency=1; logoBadge.ZIndex=2; logoBadge.Parent=titleBar
corner(logoBadge,6)
if voltLogoId then
    -- custom downloaded logo
    local img=Instance.new("ImageLabel"); img.Size=UDim2.new(1,2,1,2); img.Position=UDim2.new(0.5,0,0.5,0)
    img.AnchorPoint=Vector2.new(0.5,0.5); img.BackgroundTransparency=1; img.Image=voltLogoId
    img.ScaleType=Enum.ScaleType.Fit; img.ZIndex=3; img.Parent=logoBadge
else
    logoBadge.BackgroundColor3=C_ACCENT; logoBadge.BackgroundTransparency=0
    local g=Instance.new("UIGradient")
    g.Color=ColorSequence.new{
        ColorSequenceKeypoint.new(0,Color3.fromRGB(184,98,255)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(92,22,200)),
    }
    g.Rotation=135; g.Parent=logoBadge
    local bL=Instance.new("TextLabel"); bL.Size=UDim2.new(1,0,1,0); bL.BackgroundTransparency=1
    bL.Text="ϟ"; bL.TextColor3=Color3.fromRGB(255,246,205); bL.Font=Enum.Font.GothamBold
    bL.TextSize=13; bL.ZIndex=3; bL.Parent=logoBadge
end

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
statusDot.BackgroundColor3=Color3.fromRGB(240,180,70); statusDot.BorderSizePixel=0; statusDot.ZIndex=2; statusDot.Parent=titleBar
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

-- Neon glow icon button — matches the purple neon circular-arrow reference.
-- Creates a dark background button with a bright glowing stroke + outer bloom.
local function mkNeonIcon(xOff, txt, col, size)
    size = size or 24
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,size,0,size); b.Position=UDim2.new(1,xOff-(size/2),0.5,-size/2)
    b.BackgroundColor3=Color3.fromRGB(8,4,22); b.BackgroundTransparency=0.15
    b.BorderSizePixel=0; b.Text=txt; b.TextColor3=col or C_ACCENT2
    b.AutoButtonColor=false; b.Font=Enum.Font.GothamBold; b.TextSize=14
    b.ZIndex=3; b.Parent=titleBar
    corner(b, size/2)  -- fully round

    -- inner bright stroke (the neon ring)
    local stroke=Instance.new("UIStroke")
    stroke.Color=col or C_ACCENT; stroke.Thickness=1.4; stroke.Transparency=0.05
    stroke.Parent=b

    -- outer diffuse bloom (wider, very transparent — the glow halo)
    local bloom=Instance.new("Frame")
    bloom.AnchorPoint=Vector2.new(0.5,0.5); bloom.Position=UDim2.new(0.5,0,0.5,0)
    bloom.Size=UDim2.new(1,14,1,14); bloom.BackgroundTransparency=1
    bloom.BorderSizePixel=0; bloom.ZIndex=2; bloom.Parent=b
    corner(bloom, (size+14)/2)
    local bloomStroke=Instance.new("UIStroke")
    bloomStroke.Color=col or C_ACCENT; bloomStroke.Thickness=5; bloomStroke.Transparency=0.7
    bloomStroke.Parent=bloom

    -- hover: intensify glow
    b.MouseEnter:Connect(function()
        tween(stroke,0.12,{Transparency=0, Color=C_ACCENT2})
        tween(bloomStroke,0.12,{Transparency=0.4})
        tween(b,0.12,{BackgroundTransparency=0})
    end)
    b.MouseLeave:Connect(function()
        tween(stroke,0.18,{Transparency=0.05, Color=col or C_ACCENT})
        tween(bloomStroke,0.18,{Transparency=0.7})
        tween(b,0.18,{BackgroundTransparency=0.15})
    end)
    -- click flash
    b.MouseButton1Down:Connect(function()
        tween(b,0.06,{BackgroundColor3=Color3.fromRGB(40,16,90)})
    end)
    b.MouseButton1Up:Connect(function()
        tween(b,0.12,{BackgroundColor3=Color3.fromRGB(8,4,22)})
    end)
    return b, stroke, bloomStroke
end

local closeBtn = mkTIcon(-24, "✕", C_BAD)
local minBtn   = mkTIcon(-50, "─", C_DIM)
local pauseBtn = mkTIcon(-76, "⏸", C_DIM)
-- Clear/refresh button — neon glow ↻ matching the reference image
local clearBtn = (function()
    local b = mkNeonIcon(-104, "↻", C_ACCENT, 22)
    local spinning = false
    b.MouseEnter:Connect(function()
        if spinning then return end; spinning=true
        task.spawn(function()
            for i=1,12 do
                if not b.Parent then spinning=false; return end
                b.Rotation=(i/12)*360; task.wait(0.016)
            end
            b.Rotation=0; spinning=false
        end)
    end)
    return b
end)()

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
    {id="EXPLORER", icon="⛁", name="Remotes"},
    {id="BLOCKED",  icon="⊘", name="Blocked"},
    {id="STATS",    icon="◷", name="Stats"},
    {id="AI",       icon="✦", name="AI Chat"},
    {id="SETTINGS", icon="⚙", name="Settings"},
}
local switchPage  -- forward declare
local function mkRailBtn(def, order)
    local holder=Instance.new("Frame")
    holder.Size=UDim2.new(0,RAIL_W,0,46); holder.BackgroundTransparency=1
    holder.LayoutOrder=order; holder.Parent=rail

    -- left active indicator bar
    local indic=Instance.new("Frame")
    indic.Size=UDim2.new(0,3,0,24); indic.Position=UDim2.new(0,0,0.5,-12)
    indic.BackgroundColor3=C_ACCENT2; indic.BorderSizePixel=0; indic.Visible=false; indic.Parent=holder
    corner(indic,2)
    -- glow on indicator
    local indicGlow=Instance.new("Frame")
    indicGlow.Size=UDim2.new(0,10,1,8); indicGlow.Position=UDim2.new(0,-4,0,-4)
    indicGlow.BackgroundTransparency=1; indicGlow.BorderSizePixel=0; indicGlow.Parent=indic
    local indicStroke=Instance.new("UIStroke")
    indicStroke.Color=C_ACCENT2; indicStroke.Thickness=4; indicStroke.Transparency=0.65
    indicStroke.Parent=indicGlow

    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,40,0,40); b.Position=UDim2.new(0.5,-20,0.5,-20)
    -- inactive: visible dark background so icons are easy to see
    b.BackgroundColor3=Color3.fromRGB(22,12,48); b.BackgroundTransparency=0.35
    b.BorderSizePixel=0; b.Text=def.icon
    b.TextColor3=Color3.fromRGB(160,140,200)   -- brighter inactive colour
    b.AutoButtonColor=false; b.Font=Enum.Font.GothamBold; b.TextSize=18; b.Parent=holder
    corner(b,10)
    -- subtle inactive border so the button shape is always clear
    local bStroke=Instance.new("UIStroke")
    bStroke.Color=Color3.fromRGB(70,40,120); bStroke.Thickness=1; bStroke.Transparency=0.5
    bStroke.Parent=b

    local tip=Instance.new("TextLabel")  -- hover tooltip
    tip.Size=UDim2.new(0,76,0,20); tip.Position=UDim2.new(1,6,0.5,-10)
    tip.BackgroundColor3=Color3.fromRGB(28,14,54); tip.BorderSizePixel=0
    tip.Text=def.name; tip.TextColor3=C_TEXT; tip.Font=Enum.Font.GothamMedium
    tip.TextSize=10; tip.Visible=false; tip.ZIndex=20; tip.Parent=b
    corner(tip,6)
    do local ts=Instance.new("UIStroke");ts.Color=C_ACCENT;ts.Thickness=1;ts.Transparency=0.5;ts.Parent=tip end

    b.MouseEnter:Connect(function()
        tip.Visible=true
        if currentPage~=def.id then
            tween(b,0.12,{BackgroundColor3=Color3.fromRGB(50,24,100),BackgroundTransparency=0.1})
            tween(bStroke,0.12,{Color=C_ACCENT,Transparency=0.2})
        end
    end)
    b.MouseLeave:Connect(function()
        tip.Visible=false
        if currentPage~=def.id then
            tween(b,0.18,{BackgroundColor3=Color3.fromRGB(22,12,48),BackgroundTransparency=0.35})
            tween(bStroke,0.18,{Color=Color3.fromRGB(70,40,120),Transparency=0.5})
        end
    end)
    b.MouseButton1Click:Connect(function() switchPage(def.id) end)
    railBtns[def.id]={btn=b, indic=indic, stroke=bStroke}
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

-- empty state card — shown when no calls captured yet
local emptyCard=Instance.new("Frame")
emptyCard.Size=UDim2.new(1,-16,0,80); emptyCard.Position=UDim2.new(0,8,0,26)
emptyCard.BackgroundColor3=Color3.fromRGB(16,8,38); emptyCard.BackgroundTransparency=0.3
emptyCard.BorderSizePixel=0; emptyCard.Visible=true; emptyCard.Parent=leftPane
corner(emptyCard,10)
do local s=Instance.new("UIStroke");s.Color=C_BORDER;s.Thickness=1;s.Transparency=0.3;s.Parent=emptyCard end
local emptyIcon=Instance.new("TextLabel")
emptyIcon.Size=UDim2.new(1,0,0,32); emptyIcon.Position=UDim2.new(0,0,0,10)
emptyIcon.BackgroundTransparency=1; emptyIcon.Text="⚡"
emptyIcon.TextColor3=C_ACCENT; emptyIcon.Font=Enum.Font.GothamBold; emptyIcon.TextSize=22
emptyIcon.Parent=emptyCard
-- pulse the icon while waiting
task.spawn(function()
    while emptyIcon.Parent do
        tween(emptyIcon,1.1,{TextTransparency=0.6}); task.wait(1.1)
        tween(emptyIcon,1.1,{TextTransparency=0}); task.wait(1.1)
    end
end)
local emptyLbl=Instance.new("TextLabel")
emptyLbl.Size=UDim2.new(1,-12,0,18); emptyLbl.Position=UDim2.new(0,6,0,44)
emptyLbl.BackgroundTransparency=1; emptyLbl.Text="Waiting for remote traffic…"
emptyLbl.TextColor3=C_DIM; emptyLbl.Font=Enum.Font.GothamMedium; emptyLbl.TextSize=10
emptyLbl.Parent=emptyCard

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
    emptyCard.Visible=(shown==0)   -- hide empty hint as soon as calls arrive
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

-- ── AI INTELLIGENCE quick-action bar ─────────────────────────────
local aiQuickBar=Instance.new("Frame")
aiQuickBar.Size=UDim2.new(1,0,0,28); aiQuickBar.Position=UDim2.new(0,0,0,30)
aiQuickBar.BackgroundColor3=C_BG; aiQuickBar.BackgroundTransparency=0.3
aiQuickBar.BorderSizePixel=0; aiQuickBar.Parent=aiPage
local aiQuickLay=Instance.new("UIListLayout"); aiQuickLay.FillDirection=Enum.FillDirection.Horizontal
aiQuickLay.Padding=UDim.new(0,6); aiQuickLay.VerticalAlignment=Enum.VerticalAlignment.Center
aiQuickLay.Parent=aiQuickBar; pad(aiQuickBar,8,0,8,0)
local aiQuick={}   -- {key=button}
local function mkQuick(key, label)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,0,0,20); b.AutomaticSize=Enum.AutomaticSize.X
    b.BackgroundColor3=Color3.fromRGB(40,24,70); b.BorderSizePixel=0
    b.Text="  "..label.."  "; b.TextColor3=C_ACCENT2; b.AutoButtonColor=false
    b.Font=Enum.Font.GothamBold; b.TextSize=9; b.Parent=aiQuickBar
    corner(b,5)
    local st=Instance.new("UIStroke");st.Color=C_BORDER;st.Thickness=1;st.Transparency=0.5;st.Parent=b
    b.MouseEnter:Connect(function() tween(b,0.12,{BackgroundColor3=C_ACCENT}); b.TextColor3=Color3.fromRGB(255,255,255) end)
    b.MouseLeave:Connect(function() tween(b,0.16,{BackgroundColor3=Color3.fromRGB(40,24,70)}); b.TextColor3=C_ACCENT2 end)
    aiQuick[key]=b
    return b
end
mkQuick("summary","◷ Summarize Traffic")
mkQuick("patterns","⧉ Detect Patterns")
mkQuick("anomaly","⚠ Find Anomalies")
mkQuick("docs","▤ Generate Docs")
mkQuick("classify","✦ Classify Remotes")

-- message scroll
local aiScroll=Instance.new("ScrollingFrame")
aiScroll.Size=UDim2.new(1,0,1,-102); aiScroll.Position=UDim2.new(0,0,0,58)
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
        task.wait(0.15)
        -- Trimmed OpenAI-style message array for DeepSeek: system + recent turns.
        local msgs = { aiHistory[1] }                 -- system prompt
        local start = math.max(2, #aiHistory - 11)
        for i = start, #aiHistory do msgs[#msgs+1] = aiHistory[i] end
        -- Flattened context string for the Pollinations GET fallback.
        local ctx = ""
        for i = start, #aiHistory do
            local m = aiHistory[i]
            if m.role == "user" then ctx = ctx .. "User: " .. m.content .. "\n"
            elseif m.role == "assistant" then ctx = ctx .. "Assistant: " .. m.content .. "\n" end
        end
        local reply = queryAI(msgs, ctx)
        -- strip leading/trailing whitespace
        reply = reply:match("^%s*(.-)%s*$") or reply
        if reply ~= "" then
            table.insert(aiHistory, {role="assistant", content=reply})
        end
        thinking.Text = (reply ~= "") and reply or "⚠ Empty response."
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

-- ── AI INTELLIGENCE quick-action prompt builders ─────────────────
local function topRemotesText(n)
    local arr={}
    for name,cnt in pairs(remoteTotals) do arr[#arr+1]={name=name,cnt=cnt} end
    table.sort(arr,function(a,b) return a.cnt>b.cnt end)
    local out={}
    for i=1,math.min(n or 12,#arr) do out[#out+1]=("%d. %s — %d calls"):format(i,arr[i].name,arr[i].cnt) end
    return table.concat(out,"\n"), #arr
end
local function recentCallsText(limit)
    local out={}
    local function add(list,tag)
        local start=math.max(1,#list-(limit or 10)+1)
        for i=#list,start,-1 do
            local e=list[i]; if e then out[#out+1]=("[%s] %s:%s(%s)"):format(tag,e.name,e.method,(e.args and e.args[1]~=nil) and fmtV(e.args[1]) or "") end
        end
    end
    add(lists.OUT,"OUT"); add(lists.IN,"IN")
    return table.concat(out,"\n")
end
if aiQuick.summary then aiQuick.summary.MouseButton1Click:Connect(function()
    local top,uniq=topRemotesText(12)
    aiSendMessage(("Summarize this Roblox game's network traffic. %d total calls across %d unique remotes. Top remotes:\n%s\n\nGive a short high-level summary of what this game is doing over the network."):format(statGrand,uniq,top))
end) end
if aiQuick.patterns then aiQuick.patterns.MouseButton1Click:Connect(function()
    aiSendMessage("Analyze these recent Roblox remote calls for communication PATTERNS (polling loops, request/response pairs, heartbeats, batching). Recent traffic:\n\n"..recentCallsText(20))
end) end
if aiQuick.anomaly then aiQuick.anomaly.MouseButton1Click:Connect(function()
    local top=topRemotesText(15)
    aiSendMessage("Act as a security analyst. Inspect these remote call frequencies for ANOMALIES or suspicious behaviour (anti-cheat pings, kick triggers, abnormally high call rates, exploit-detection remotes). Data:\n"..top)
end) end
if aiQuick.docs then aiQuick.docs.MouseButton1Click:Connect(function()
    aiSendMessage("Generate concise markdown DOCUMENTATION for these captured Roblox remotes — name, likely purpose, and example arguments. Remotes:\n\n"..recentCallsText(18))
end) end
if aiQuick.classify then aiQuick.classify.MouseButton1Click:Connect(function()
    local top=topRemotesText(15)
    aiSendMessage("Classify each of these Roblox remotes by purpose (Combat, Economy, Movement, Anti-Cheat, UI, Data, Misc). Output a short categorized list:\n"..top)
end) end

-- greeting
aiAddBubble("assistant","Hey — I'm Volt AI, running free on Pollinations. Ask me to explain a captured remote, write Luau, or debug a script. Hit “Explain remote” to analyse your current selection.")

-- ╔════════════════ REMOTES EXPLORER PAGE (Dex-style) ════════════╗
-- Lists EVERY remote in the game (fired or not, including nil-parented
-- and admin remotes) so you can find and fire them manually.
local explorerPage=Instance.new("Frame")
explorerPage.Size=UDim2.new(1,0,1,0); explorerPage.BackgroundTransparency=1; explorerPage.Visible=false; explorerPage.Parent=content

local expBar=Instance.new("Frame")
expBar.Size=UDim2.new(1,0,0,30); expBar.BackgroundColor3=C_PANEL; expBar.BorderSizePixel=0; expBar.Parent=explorerPage
do local sep=Instance.new("Frame");sep.Size=UDim2.new(1,0,0,1);sep.Position=UDim2.new(0,0,1,-1)
   sep.BackgroundColor3=C_BORDER;sep.BorderSizePixel=0;sep.Parent=expBar end
local expSearch=Instance.new("TextBox")
expSearch.Size=UDim2.new(1,-150,0,20); expSearch.Position=UDim2.new(0,8,0.5,-10)
expSearch.BackgroundColor3=Color3.fromRGB(26,16,44); expSearch.BorderSizePixel=0
expSearch.Text=""; expSearch.PlaceholderText="🔍 search all remotes…"
expSearch.TextColor3=C_TEXT; expSearch.PlaceholderColor3=C_DIM
expSearch.Font=Enum.Font.Gotham; expSearch.TextSize=11; expSearch.ClearTextOnFocus=false
expSearch.TextXAlignment=Enum.TextXAlignment.Left; expSearch.Parent=expBar
corner(expSearch,5); pad(expSearch,8,0,0,0)
local expCount=Instance.new("TextLabel")
expCount.Size=UDim2.new(0,80,1,0); expCount.Position=UDim2.new(1,-138,0,0)
expCount.BackgroundTransparency=1; expCount.Text="0 found"; expCount.TextColor3=C_DIM
expCount.Font=Enum.Font.GothamMedium; expCount.TextSize=10; expCount.TextXAlignment=Enum.TextXAlignment.Right; expCount.Parent=expBar
local expRefresh=Instance.new("TextButton")
expRefresh.Size=UDim2.new(0,52,0,20); expRefresh.Position=UDim2.new(1,-56,0.5,-10)
expRefresh.BackgroundColor3=C_ACCENT; expRefresh.BorderSizePixel=0
expRefresh.Text="↻ Scan"; expRefresh.TextColor3=Color3.fromRGB(255,255,255); expRefresh.AutoButtonColor=false
expRefresh.Font=Enum.Font.GothamBold; expRefresh.TextSize=9; expRefresh.Parent=expBar
corner(expRefresh,5)

local expScroll=Instance.new("ScrollingFrame")
expScroll.Size=UDim2.new(1,0,1,-30); expScroll.Position=UDim2.new(0,0,0,30)
expScroll.BackgroundTransparency=1; expScroll.BorderSizePixel=0
expScroll.ScrollBarThickness=3; expScroll.ScrollBarImageColor3=C_ACCENT
expScroll.CanvasSize=UDim2.new(0,0,0,0); expScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; expScroll.Parent=explorerPage
local expLayout=Instance.new("UIListLayout"); expLayout.Padding=UDim.new(0,2); expLayout.SortOrder=Enum.SortOrder.LayoutOrder; expLayout.Parent=expScroll
pad(expScroll,4,4,4,4)

local allRemotes, expFilter = {}, ""
local pinnedRemotes = {}   -- [fullName]=true ; pinned float to top
local function scanAllRemotes()
    local found, seen = {}, {}
    local function add(v)
        if v and TargetClasses[v.ClassName] and not seen[v] then
            seen[v]=true; found[#found+1]=v
        end
    end
    for _,v in ipairs(game:GetDescendants()) do add(v) end
    if getnilinstances then
        local ok,nils=pcall(getnilinstances)
        if ok then for _,v in ipairs(nils) do pcall(add,v) end end
    end
    table.sort(found,function(a,b)
        local pa,pb=a.Name,b.Name
        pcall(function() pa=a:GetFullName() end); pcall(function() pb=b:GetFullName() end)
        return pa<pb
    end)
    return found
end

local function fireRemoteInstance(r)
    pcall(function()
        if r:IsA("RemoteEvent") or r:IsA("UnreliableRemoteEvent") then r:FireServer()
        elseif r:IsA("RemoteFunction") then r:InvokeServer()
        elseif r:IsA("BindableEvent") then r:Fire()
        elseif r:IsA("BindableFunction") then r:Invoke() end
    end)
end

local function buildExplorer()
    for _,c in ipairs(expScroll:GetChildren()) do
        if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
    end
    local shown=0
    for i,r in ipairs(allRemotes) do
        local full=r.Name; pcall(function() full=r:GetFullName() end)
        if expFilter=="" or full:lower():find(expFilter:lower(),1,true) then
            shown=shown+1
            local ri=REMOTE_ICON[r.ClassName] or {icon="⚡",col=C_DIM}
            local isPin=pinnedRemotes[full]
            local row=Instance.new("Frame")
            row.Size=UDim2.new(1,0,0,30)
            row.LayoutOrder=(isPin and -100000 or 0)+i   -- pinned float to top
            row.BackgroundColor3=isPin and C_SEL or C_ROW
            row.BorderSizePixel=0; row.Parent=expScroll
            corner(row,5)
            -- type icon
            local ic=Instance.new("Frame"); ic.Size=UDim2.new(0,20,0,20); ic.Position=UDim2.new(0,6,0.5,-10)
            ic.BackgroundColor3=ri.col; ic.BackgroundTransparency=0.82; ic.BorderSizePixel=0; ic.Parent=row
            corner(ic,5)
            if ri.img then
                local im=Instance.new("ImageLabel");im.Size=UDim2.new(0,14,0,14);im.Position=UDim2.new(0.5,-7,0.5,-7)
                im.BackgroundTransparency=1;im.Image=ri.img;im.ImageColor3=ri.col;im.Parent=ic
            else
                local il=Instance.new("TextLabel");il.Size=UDim2.new(1,0,1,0);il.BackgroundTransparency=1
                il.Text=ri.icon;il.TextColor3=ri.col;il.Font=Enum.Font.GothamBold;il.TextSize=11;il.Parent=ic
            end
            -- path (short)
            local short=full:gsub("^game%.","")
            local nameLbl=Instance.new("TextLabel")
            nameLbl.Size=UDim2.new(1,-176,1,0); nameLbl.Position=UDim2.new(0,32,0,0)
            nameLbl.BackgroundTransparency=1; nameLbl.Text=short; nameLbl.TextColor3=C_TEXT
            nameLbl.Font=Enum.Font.Gotham; nameLbl.TextSize=10
            nameLbl.TextXAlignment=Enum.TextXAlignment.Left; nameLbl.TextTruncate=Enum.TextTruncate.AtEnd; nameLbl.Parent=row
            -- call-frequency badge (how often this remote has fired this session)
            local freq=remoteTotals[full] or 0
            if freq>0 then
                local fb=Instance.new("TextLabel")
                fb.Size=UDim2.new(0,42,0,16); fb.Position=UDim2.new(1,-172,0.5,-8)
                fb.BackgroundColor3=C_ACCENT; fb.BackgroundTransparency=0.78; fb.BorderSizePixel=0
                fb.Text="×"..freq; fb.TextColor3=C_ACCENT2; fb.Font=Enum.Font.GothamBold; fb.TextSize=9
                fb.Parent=row; corner(fb,8)
            end
            -- pin/favourite star
            local pinBtn=Instance.new("TextButton")
            pinBtn.Size=UDim2.new(0,22,0,20); pinBtn.Position=UDim2.new(1,-128,0.5,-10)
            pinBtn.BackgroundTransparency=1; pinBtn.Text=isPin and "★" or "☆"
            pinBtn.TextColor3=isPin and Color3.fromRGB(255,205,90) or C_DIM
            pinBtn.Font=Enum.Font.GothamBold; pinBtn.TextSize=15; pinBtn.AutoButtonColor=false; pinBtn.Parent=row
            pinBtn.MouseButton1Click:Connect(function()
                if pinnedRemotes[full] then pinnedRemotes[full]=nil else pinnedRemotes[full]=true end
                buildExplorer()
            end)
            -- copy + fire buttons
            local function mkB(xOff,w,txt,col,fn)
                local b=Instance.new("TextButton"); b.Size=UDim2.new(0,w,0,20); b.Position=UDim2.new(1,xOff,0.5,-10)
                b.BackgroundColor3=col; b.BorderSizePixel=0; b.Text=txt; b.TextColor3=C_TEXT
                b.Font=Enum.Font.GothamBold; b.TextSize=9; b.AutoButtonColor=false; b.Parent=row
                corner(b,4)
                b.MouseEnter:Connect(function() tween(b,0.12,{BackgroundColor3=col:Lerp(Color3.new(1,1,1),0.2)}) end)
                b.MouseLeave:Connect(function() tween(b,0.16,{BackgroundColor3=col}) end)
                b.MouseButton1Click:Connect(fn)
            end
            mkB(-86,40,"⎘ Copy",Color3.fromRGB(54,34,90),function()
                local path=full:gsub("^game%.([^%.]+)",function(s) return 'game:GetService("'..s..'")' end)
                local call=(r:IsA("RemoteFunction") and ":InvokeServer()") or (r:IsA("BindableFunction") and ":Invoke()")
                    or (r:IsA("BindableEvent") and ":Fire()") or ":FireServer()"
                pcall(function() setclipboard(path..call) end)
            end)
            mkB(-44,40,"▶ Fire",Color3.fromRGB(80,32,168),function() fireRemoteInstance(r) end)
        end
    end
    expCount.Text=shown.." / "..#allRemotes
end

expRefresh.MouseButton1Click:Connect(function()
    expRefresh.Text="…"; allRemotes=scanAllRemotes(); buildExplorer(); expRefresh.Text="↻ Scan"
end)
expSearch:GetPropertyChangedSignal("Text"):Connect(function() expFilter=expSearch.Text; buildExplorer() end)

-- ── PAGE SWITCHING ───────────────────────────────────────────────
switchPage=function(id)
    currentPage=id
    for pid,o in pairs(railBtns) do
        local on=(pid==id)
        o.indic.Visible=on
        tween(o.btn,0.15,{
            BackgroundTransparency = on and 0 or 0.35,
            BackgroundColor3 = on and C_ACCENT or Color3.fromRGB(22,12,48),
        })
        tween(o.stroke,0.15,{
            Color = on and C_ACCENT2 or Color3.fromRGB(70,40,120),
            Transparency = on and 0 or 0.5,
        })
        o.btn.TextColor3 = on and Color3.fromRGB(255,255,255) or Color3.fromRGB(160,140,200)
    end
    local isBrowser=(id=="OUT" or id=="IN" or id=="BLOCKED")
    browser.Visible=isBrowser
    statsPage.Visible=(id=="STATS")
    setPage.Visible=(id=="SETTINGS")
    aiPage.Visible=(id=="AI")
    explorerPage.Visible=(id=="EXPLORER")
    if isBrowser then
        local titles={OUT="OUTGOING ↑", IN="INCOMING ↓", BLOCKED="BLOCKED ⊘"}
        pageTitle.Text=titles[id]
        setSelected(nil); rebuildAll()
    elseif id=="STATS" then refreshStats()
    elseif id=="EXPLORER" then
        if #allRemotes==0 then allRemotes=scanAllRemotes(); buildExplorer() end
    end
end

-- ── LOG CALL ─────────────────────────────────────────────────────
-- ── EXTERNAL BRIDGE  (streams capture to the C++ Volt.exe over a .jsonl) ──
-- The external UI tails VoltStream/stream.jsonl. We append one JSON line per
-- captured call. Any executor with writefile/appendfile feeds the desktop app.
local VBridge do
    local FOLDER, PATH = "VoltStream", "VoltStream/stream.jsonl"
    local hasAppend = type(appendfile)=="function"
    local hasWrite  = type(writefile)=="function"
    VBridge = { enabled = (hasAppend or hasWrite) }
    if type(makefolder)=="function" then
        pcall(function() if not (type(isfolder)=="function" and isfolder(FOLDER)) then makefolder(FOLDER) end end)
    end
    pcall(function() if hasWrite then writefile(PATH,"") end end)
    local function esc(s)
        s=tostring(s):gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n'):gsub('\r','\\r'):gsub('\t','\\t')
        return (s:gsub('[%z\1-\8\11\12\14-\31]',' '))
    end
    local function argStr(a)
        if type(a)~="table" then return "(no args)" end
        local n=a.n or #a; if n==0 then return "(no args)" end
        local p={}
        for i=1,math.min(n,6) do
            local v=a[i]; local t=typeof and typeof(v) or type(v); local r
            if t=="string" then r='"'..(#v>40 and v:sub(1,37).."..." or v)..'"'
            elseif t=="Instance" then r=v.ClassName.."("..v.Name..")"
            elseif t=="Vector3" then r=string.format("Vector3(%.1f, %.1f, %.1f)",v.X,v.Y,v.Z)
            elseif t=="table" then r="{...}" elseif v==nil then r="nil" else r=tostring(v) end
            p[#p+1]=r
        end
        if n>6 then p[#p+1]=string.format("…(+%d)",n-6) end
        return table.concat(p,", ")
    end
    function VBridge.emit(dir,remote,args,method,isExec,source)
        if not VBridge.enabled then return end
        local name,rtype="Unknown","RemoteEvent"
        if remote then
            pcall(function() name=remote:GetFullName() end)
            pcall(function() rtype=remote.ClassName end)
        end
        local line=string.format(
            '{"dir":"%s","name":"%s","method":"%s","rtype":"%s","args":"%s","source":"%s","count":1,"exec":%s,"t":%.3f}\n',
            dir=="IN" and "in" or "out", esc(name), esc(method or "?"), esc(rtype),
            esc(argStr(args)), esc(source or ""), isExec and "true" or "false",
            (os.clock and os.clock()) or 0)
        if hasAppend then pcall(appendfile,PATH,line)
        elseif hasWrite then
            local prev=""; if type(isfile)=="function" and isfile(PATH) then pcall(function() prev=readfile(PATH) end) end
            pcall(writefile,PATH,prev..line)
        end
    end
end

local function logCall(dir,remote,args,method,callerSrc,callerLine,isExec,returns)
    if paused then return end
    if dir=="OUT" and not settings.captureOut then return end
    if dir=="IN"  and not settings.captureIn  then return end
    if remote and BindClasses[remote.ClassName] and not settings.captureBind then return end

    -- stream to the external C++ UI (best-effort; never blocks capture)
    pcall(function()
        VBridge.emit(dir, remote, args, method, isExec,
                     callerSrc and (tostring(callerSrc)..":"..tostring(callerLine)) or "")
    end)

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

-- ── HOOK INSTALLERS  (deferred — installed after a stealth delay) ──
local InvokeMethods = { InvokeServer=true, Invoke=true, invokeServer=true, invoke=true }

local function installOutgoingHooks()
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
end  -- installOutgoingHooks

-- ── INCOMING HOOKS ───────────────────────────────────────────────
local function hookIncoming(remote)
    if hookedIn[remote] then return end; hookedIn[remote]=true
    if remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent") then
        remote.OnClientEvent:Connect(function(...) logCall("IN",remote,table.pack(...),"OnClientEvent",nil,-1,false) end)
    elseif remote:IsA("BindableEvent") then
        remote.Event:Connect(function(...) logCall("IN",remote,table.pack(...),"Event",nil,-1,false) end)
    end
end
local function installIncomingHooks()
    for _,v in ipairs(game:GetDescendants()) do if TargetClasses[v.ClassName] then hookIncoming(v) end end
    game.DescendantAdded:Connect(function(v) if TargetClasses[v.ClassName] then task.defer(hookIncoming,v) end end)
    if getnilinstances then
        for _,v in ipairs(getnilinstances()) do if TargetClasses[v.ClassName] then hookIncoming(v) end end
    end
end

-- ── DEFERRED STEALTH INSTALL ──────────────────────────────────────
-- Wait for the game to finish loading + an extra delay so the
-- anti-cheat's startup integrity scan passes BEFORE we hook anything.
-- Override with:  getgenv().VoltConfig = { hookDelay = 10 }
local HOOK_DELAY = (getgenv and getgenv().VoltConfig and getgenv().VoltConfig.hookDelay) or 6
task.spawn(function()
    if not game:IsLoaded() then game.Loaded:Wait() end
    task.wait(HOOK_DELAY)
    pcall(installIncomingHooks)
    pcall(installOutgoingHooks)
    -- subtle status cue: dot flips to accent once hooks are live
    pcall(function() tween(statusDot,0.3,{BackgroundColor3=C_GOOD}) end)
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

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  VOLT v3 — TELEMETRY · NOTIFICATIONS · COMMAND PALETTE · THEMES ║
-- ║  Wrapped in a function so it gets its own local-variable budget ║
-- ╚═══════════════════════════════════════════════════════════════╝
local function initV3()
local UserInputService = game:GetService("UserInputService")
local sessionStart = os.time()
local notify              -- forward (used by palette + shortcuts)
local applyTheme          -- forward (theme switcher)

-- overlay ScreenGui — renders toasts + command palette above the window
local overlay = Instance.new("ScreenGui")
overlay.DisplayOrder = 50
mountGui(overlay)

-- ── THEME ENGINE  (7 accent themes, live recolour) ───────────────
local THEMES = {
    {name="Neon Purple", accent=Color3.fromRGB(130,50,255),  accent2=Color3.fromRGB(190,120,255), glow=Color3.fromRGB(100,28,210)},
    {name="Aurora",      accent=Color3.fromRGB(0,200,180),    accent2=Color3.fromRGB(80,240,220),  glow=Color3.fromRGB(0,150,140)},
    {name="Obsidian",    accent=Color3.fromRGB(170,175,200),  accent2=Color3.fromRGB(220,225,245), glow=Color3.fromRGB(90,95,120)},
    {name="Cosmic",      accent=Color3.fromRGB(255,160,50),   accent2=Color3.fromRGB(255,205,110), glow=Color3.fromRGB(190,110,30)},
    {name="Royal",       accent=Color3.fromRGB(220,160,60),   accent2=Color3.fromRGB(245,205,120), glow=Color3.fromRGB(150,100,30)},
    {name="Phantom",     accent=Color3.fromRGB(180,60,240),   accent2=Color3.fromRGB(215,130,255), glow=Color3.fromRGB(120,30,180)},
    {name="Cyberpunk",   accent=Color3.fromRGB(0,220,255),    accent2=Color3.fromRGB(120,245,255), glow=Color3.fromRGB(0,150,190)},
}
local themeTargets = {}   -- instances that follow the active accent
local function themed(inst, prop, kind)
    themeTargets[#themeTargets+1] = {inst=inst, prop=prop, kind=kind}  -- kind: accent|accent2|glow
end
applyTheme = function(th)
    C_ACCENT, C_ACCENT2, C_GLOW = th.accent, th.accent2, th.glow
    pcall(function() mainStroke.Color = th.accent end)
    pcall(function()
        local gs = glowShell:FindFirstChildOfClass("UIStroke"); if gs then gs.Color = th.glow end
    end)
    for _,t in ipairs(themeTargets) do
        if t.inst and t.inst.Parent then
            local c = (t.kind=="accent2" and th.accent2) or (t.kind=="glow" and th.glow) or th.accent
            pcall(function() tween(t.inst, 0.25, {[t.prop]=c}) end)
        end
    end
end

-- ── THEME PICKER  (visual grid injected into the Settings page) ──
do
    pcall(function() mkSectionHdr("THEME", 11) end)
    local activeIdx = 1
    local cards = {}
    local function repaintCards()
        for i,c in ipairs(cards) do
            local on = (i==activeIdx)
            tween(c.stroke,0.18,{Transparency=on and 0 or 0.65, Color=on and c.theme.accent2 or C_BORDER})
            c.check.Visible = on
        end
    end
    for i,th in ipairs(THEMES) do
        local row=Instance.new("TextButton")
        row.Size=UDim2.new(1,0,0,40); row.BackgroundColor3=C_PANEL
        row.BorderSizePixel=0; row.AutoButtonColor=false; row.Text=""
        row.LayoutOrder=11+i; row.Parent=setPage
        corner(row,7)
        local stroke=Instance.new("UIStroke"); stroke.Thickness=1.5; stroke.Color=C_BORDER; stroke.Transparency=0.65; stroke.Parent=row
        local sw1=Instance.new("Frame"); sw1.Size=UDim2.new(0,20,0,20); sw1.Position=UDim2.new(0,12,0.5,-10)
        sw1.BackgroundColor3=th.accent; sw1.BorderSizePixel=0; sw1.Parent=row; corner(sw1,5)
        local sw2=Instance.new("Frame"); sw2.Size=UDim2.new(0,20,0,20); sw2.Position=UDim2.new(0,34,0.5,-10)
        sw2.BackgroundColor3=th.accent2; sw2.BorderSizePixel=0; sw2.Parent=row; corner(sw2,5)
        local nm=Instance.new("TextLabel"); nm.Size=UDim2.new(1,-120,1,0); nm.Position=UDim2.new(0,64,0,0)
        nm.BackgroundTransparency=1; nm.Text=th.name; nm.TextColor3=C_TEXT; nm.Font=Enum.Font.GothamBold
        nm.TextSize=12; nm.TextXAlignment=Enum.TextXAlignment.Left; nm.Parent=row
        local check=Instance.new("TextLabel"); check.Size=UDim2.new(0,24,1,0); check.Position=UDim2.new(1,-32,0,0)
        check.BackgroundTransparency=1; check.Text="✓"; check.TextColor3=th.accent2; check.Font=Enum.Font.GothamBold
        check.TextSize=16; check.Visible=(i==1); check.Parent=row
        cards[i]={stroke=stroke, check=check, theme=th}
        row.MouseButton1Click:Connect(function()
            activeIdx=i; applyTheme(th); repaintCards()
            if notify then notify("Theme", th.name.." applied", "success") end
        end)
        row.MouseEnter:Connect(function() if activeIdx~=i then tween(stroke,0.12,{Transparency=0.3}) end end)
        row.MouseLeave:Connect(function() if activeIdx~=i then tween(stroke,0.16,{Transparency=0.65}) end end)
    end
    repaintCards()
end

-- ── NOTIFICATION TOASTS  (bottom-right, auto-dismiss) ────────────
do
    local box = Instance.new("Frame")
    box.Size = UDim2.new(0,300,1,-20); box.Position = UDim2.new(1,-312,0,10)
    box.BackgroundTransparency = 1; box.Parent = overlay
    local lay = Instance.new("UIListLayout")
    lay.VerticalAlignment = Enum.VerticalAlignment.Bottom
    lay.HorizontalAlignment = Enum.HorizontalAlignment.Right
    lay.Padding = UDim.new(0,8); lay.SortOrder = Enum.SortOrder.LayoutOrder; lay.Parent = box

    notify = function(title, msg, kind)
        local cols = {info=C_ACCENT, success=C_GOOD, warn=Color3.fromRGB(255,196,80), error=C_BAD}
        local col = cols[kind or "info"] or C_ACCENT
        local card = Instance.new("Frame")
        card.Size = UDim2.new(0,290,0,0); card.AutomaticSize = Enum.AutomaticSize.Y
        card.BackgroundColor3 = Color3.fromRGB(16,9,38); card.BackgroundTransparency = 0.08
        card.BorderSizePixel = 0; card.Parent = box
        corner(card,9); pad(card,12,9,12,9)
        local s = Instance.new("UIStroke"); s.Color=col; s.Thickness=1.4; s.Transparency=0.25; s.Parent=card
        local bar = Instance.new("Frame"); bar.Size=UDim2.new(0,3,1,-12); bar.Position=UDim2.new(0,-8,0,6)
        bar.BackgroundColor3=col; bar.BorderSizePixel=0; bar.Parent=card; corner(bar,2)
        local tl = Instance.new("TextLabel"); tl.Size=UDim2.new(1,0,0,16); tl.BackgroundTransparency=1
        tl.Text=title; tl.TextColor3=col; tl.Font=Enum.Font.GothamBold; tl.TextSize=12
        tl.TextXAlignment=Enum.TextXAlignment.Left; tl.Parent=card
        local ml = Instance.new("TextLabel"); ml.Size=UDim2.new(1,0,0,0); ml.Position=UDim2.new(0,0,0,18)
        ml.AutomaticSize=Enum.AutomaticSize.Y; ml.BackgroundTransparency=1; ml.Text=msg
        ml.TextColor3=C_TEXT; ml.Font=Enum.Font.Gotham; ml.TextSize=11; ml.TextWrapped=true
        ml.TextXAlignment=Enum.TextXAlignment.Left; ml.Parent=card
        card.Position = UDim2.new(1,20,0,0)
        tween(card,0.3,{Position=UDim2.new(0,0,0,0)},Enum.EasingStyle.Back)
        task.delay(4.2,function()
            tween(card,0.3,{BackgroundTransparency=1})
            tween(s,0.3,{Transparency=1}); tween(tl,0.3,{TextTransparency=1})
            tween(ml,0.3,{TextTransparency=1}); tween(bar,0.3,{BackgroundTransparency=1})
            task.delay(0.32,function() card:Destroy() end)
        end)
    end
end

-- ── LIVE TELEMETRY PANEL  (CPS · session · 40-bar traffic graph) ─
do
    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0,200,0,150)
    panel.Position = UDim2.new(0.5,W/2+16,0.5,-75)   -- floats to the right of main
    panel.AnchorPoint = Vector2.new(0,0)
    panel.BackgroundColor3 = Color3.fromRGB(12,6,30); panel.BackgroundTransparency=0.12
    panel.BorderSizePixel=0; panel.Active=true; panel.Draggable=true; panel.Parent=main
    corner(panel,10)
    local ps = Instance.new("UIStroke"); ps.Color=C_ACCENT; ps.Thickness=1.4; ps.Transparency=0.3; ps.Parent=panel
    themed(ps,"Color","accent")

    local hdr = Instance.new("TextLabel")
    hdr.Size=UDim2.new(1,-16,0,16); hdr.Position=UDim2.new(0,12,0,8); hdr.BackgroundTransparency=1
    hdr.Text="◷ TELEMETRY"; hdr.TextColor3=C_ACCENT2; hdr.Font=Enum.Font.GothamBold; hdr.TextSize=10
    hdr.TextXAlignment=Enum.TextXAlignment.Left; hdr.Parent=panel
    themed(hdr,"TextColor3","accent2")

    local function statBlock(x, lbl)
        local big = Instance.new("TextLabel")
        big.Size=UDim2.new(0,62,0,22); big.Position=UDim2.new(0,x,0,26); big.BackgroundTransparency=1
        big.Text="0"; big.TextColor3=C_TEXT; big.Font=Enum.Font.GothamBold; big.TextSize=18
        big.TextXAlignment=Enum.TextXAlignment.Left; big.Parent=panel
        local cap = Instance.new("TextLabel")
        cap.Size=UDim2.new(0,62,0,12); cap.Position=UDim2.new(0,x,0,48); cap.BackgroundTransparency=1
        cap.Text=lbl; cap.TextColor3=C_DIM; cap.Font=Enum.Font.Gotham; cap.TextSize=9
        cap.TextXAlignment=Enum.TextXAlignment.Left; cap.Parent=panel
        return big
    end
    local cpsLbl  = statBlock(12,  "CALLS/SEC")
    local totLbl  = statBlock(78,  "TOTAL")
    local sessLbl = statBlock(140, "SESSION")
    sessLbl.TextSize=14; sessLbl.Position=UDim2.new(0,140,0,30)

    -- 40-bar rolling graph
    local graph = Instance.new("Frame")
    graph.Size=UDim2.new(1,-24,0,56); graph.Position=UDim2.new(0,12,0,72)
    graph.BackgroundColor3=Color3.fromRGB(8,4,20); graph.BackgroundTransparency=0.3
    graph.BorderSizePixel=0; graph.ClipsDescendants=true; graph.Parent=panel
    corner(graph,6)
    local NBARS=40
    local bars, hist = {}, {}
    for i=1,NBARS do hist[i]=0 end
    for i=1,NBARS do
        local b=Instance.new("Frame")
        b.AnchorPoint=Vector2.new(0,1)
        b.Position=UDim2.new((i-1)/NBARS,1,1,-2)
        b.Size=UDim2.new(1/NBARS,-1,0,2)
        b.BackgroundColor3=C_GOOD; b.BorderSizePixel=0; b.Parent=graph
        corner(b,1); bars[i]=b
    end

    local lastTotal = 0
    task.spawn(function()
        while panel.Parent do
            task.wait(1)
            local cps = math.max(0, statGrand - lastTotal)
            lastTotal = statGrand
            table.remove(hist,1); hist[#hist+1]=cps
            local peak=1
            for _,v in ipairs(hist) do if v>peak then peak=v end end
            for i,v in ipairs(hist) do
                local frac = v/peak
                local h = math.max(2, frac*52)
                local col = frac<0.4 and C_GOOD or (frac<0.75 and Color3.fromRGB(255,196,80) or C_BAD)
                tween(bars[i],0.45,{Size=UDim2.new(1/NBARS,-1,0,h),BackgroundColor3=col})
            end
            cpsLbl.Text=tostring(cps); totLbl.Text=tostring(statGrand)
            local el=os.time()-sessionStart
            sessLbl.Text=string.format("%d:%02d", math.floor(el/60), el%60)
            cpsLbl.TextColor3 = cps>0 and C_ACCENT2 or C_TEXT
        end
    end)
end

-- ── COMMAND PALETTE  (Ctrl+K) ────────────────────────────────────
local toggleCmd
do
    local dim = Instance.new("Frame")
    dim.Size=UDim2.new(1,0,1,0); dim.BackgroundColor3=Color3.new(0,0,0)
    dim.BackgroundTransparency=0.55; dim.BorderSizePixel=0; dim.Visible=false; dim.ZIndex=90; dim.Parent=overlay

    local pal = Instance.new("Frame")
    pal.Size=UDim2.new(0,560,0,360); pal.AnchorPoint=Vector2.new(0.5,0.5)
    pal.Position=UDim2.new(0.5,0,0.42,0); pal.BackgroundColor3=Color3.fromRGB(14,8,34)
    pal.BorderSizePixel=0; pal.ZIndex=91; pal.Parent=dim
    corner(pal,12)
    local pst=Instance.new("UIStroke"); pst.Color=C_ACCENT; pst.Thickness=1.6; pst.Transparency=0.1; pst.Parent=pal
    themed(pst,"Color","accent")

    local input = Instance.new("TextBox")
    input.Size=UDim2.new(1,-24,0,40); input.Position=UDim2.new(0,12,0,12)
    input.BackgroundColor3=Color3.fromRGB(20,11,46); input.BorderSizePixel=0
    input.Text=""; input.PlaceholderText="⌘  Type a command…"; input.ClearTextOnFocus=false
    input.TextColor3=C_TEXT; input.PlaceholderColor3=C_DIM; input.Font=Enum.Font.Gotham
    input.TextSize=14; input.TextXAlignment=Enum.TextXAlignment.Left; input.ZIndex=92; input.Parent=pal
    corner(input,8); pad(input,12,0,12,0)

    local list = Instance.new("ScrollingFrame")
    list.Size=UDim2.new(1,-24,1,-66); list.Position=UDim2.new(0,12,0,60)
    list.BackgroundTransparency=1; list.BorderSizePixel=0; list.ScrollBarThickness=3
    list.ScrollBarImageColor3=C_ACCENT; list.CanvasSize=UDim2.new(0,0,0,0)
    list.AutomaticCanvasSize=Enum.AutomaticSize.Y; list.ZIndex=92; list.Parent=pal
    local ll=Instance.new("UIListLayout"); ll.Padding=UDim.new(0,4); ll.Parent=list

    local function clearList() lists.OUT={}; lists.IN={}; setSelected(nil); rebuildAll() end
    local function exportLog()
        local out={}
        for _,e in ipairs(lists.OUT) do out[#out+1]="[OUT] "..e.name.." :"..e.method end
        for _,e in ipairs(lists.IN)  do out[#out+1]="[IN]  "..e.name.." :"..e.method end
        pcall(function() setclipboard(table.concat(out,"\n")) end)
        if notify then notify("Exported", #out.." calls copied to clipboard","success") end
    end

    local CMDS = {
        {n="Go to Outgoing",  a=function() switchPage("OUT") end},
        {n="Go to Incoming",  a=function() switchPage("IN") end},
        {n="Go to Explorer",  a=function() switchPage("EXPLORER") end},
        {n="Go to AI Chat",   a=function() switchPage("AI") end},
        {n="Go to Stats",     a=function() switchPage("STATS") end},
        {n="Go to Settings",  a=function() switchPage("SETTINGS") end},
        {n="Clear Log",       a=clearList},
        {n="Export Log",      a=exportLog},
        {n="Pause / Resume Capture", a=function() paused=not paused; if notify then notify("Capture",paused and "Paused" or "Resumed","info") end end},
    }
    for _,th in ipairs(THEMES) do
        CMDS[#CMDS+1] = {n="Theme: "..th.name, a=function() applyTheme(th); if notify then notify("Theme",th.name.." applied","success") end end}
    end

    local function render(q)
        for _,c in ipairs(list:GetChildren()) do if not c:IsA("UIListLayout") then c:Destroy() end end
        q=(q or ""):lower()
        for i,cmd in ipairs(CMDS) do
            if q=="" or cmd.n:lower():find(q,1,true) then
                local row=Instance.new("TextButton")
                row.Size=UDim2.new(1,0,0,34); row.BackgroundColor3=Color3.fromRGB(22,13,50)
                row.BackgroundTransparency=0.35; row.BorderSizePixel=0; row.Text=""
                row.AutoButtonColor=false; row.LayoutOrder=i; row.ZIndex=92; row.Parent=list
                corner(row,7)
                local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,-40,1,0); lbl.Position=UDim2.new(0,14,0,0)
                lbl.BackgroundTransparency=1; lbl.Text=cmd.n; lbl.TextColor3=C_TEXT; lbl.Font=Enum.Font.Gotham
                lbl.TextSize=12; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=93; lbl.Parent=row
                local ic=Instance.new("TextLabel"); ic.Size=UDim2.new(0,28,1,0); ic.Position=UDim2.new(1,-32,0,0)
                ic.BackgroundTransparency=1; ic.Text="↵"; ic.TextColor3=C_DIM; ic.Font=Enum.Font.GothamBold
                ic.TextSize=12; ic.ZIndex=93; ic.Parent=row
                row.MouseEnter:Connect(function() tween(row,0.12,{BackgroundColor3=C_ACCENT,BackgroundTransparency=0.1}) end)
                row.MouseLeave:Connect(function() tween(row,0.16,{BackgroundColor3=Color3.fromRGB(22,13,50),BackgroundTransparency=0.35}) end)
                row.MouseButton1Click:Connect(function() toggleCmd(false); cmd.a() end)
            end
        end
    end

    toggleCmd = function(show)
        if show == nil then show = not dim.Visible end
        dim.Visible = show
        if show then input.Text=""; render(""); task.defer(function() pcall(function() input:CaptureFocus() end) end) end
    end
    input:GetPropertyChangedSignal("Text"):Connect(function() render(input.Text) end)
    input.FocusLost:Connect(function(enter)
        if enter then
            local q=input.Text:lower()
            for _,cmd in ipairs(CMDS) do
                if cmd.n:lower():find(q,1,true) then toggleCmd(false); cmd.a(); break end
            end
        end
    end)
end

-- ── KEYBOARD SHORTCUTS ───────────────────────────────────────────
do
    local pageKeys = {
        [Enum.KeyCode.One]="OUT", [Enum.KeyCode.Two]="IN", [Enum.KeyCode.Three]="EXPLORER",
        [Enum.KeyCode.Four]="AI", [Enum.KeyCode.Five]="STATS", [Enum.KeyCode.Six]="SETTINGS",
    }
    UserInputService.InputBegan:Connect(function(inp, gp)
        if gp then return end
        local ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
        if ctrl and inp.KeyCode==Enum.KeyCode.K then
            toggleCmd(nil)  -- nil => flip current visibility
        elseif inp.KeyCode==Enum.KeyCode.Escape then
            toggleCmd(false)
        elseif ctrl and inp.KeyCode==Enum.KeyCode.P then
            paused=not paused; if notify then notify("Capture",paused and "Paused" or "Resumed","info") end
        elseif not ctrl and pageKeys[inp.KeyCode] then
            switchPage(pageKeys[inp.KeyCode])
        end
    end)
end

switchPage("OUT")
if notify then notify("Volt v3.0", "Loaded. Ctrl+K for commands · 1-6 to switch pages.", "success") end
end
initV3()

-- (no console output — avoid leaving an identifiable signature)
