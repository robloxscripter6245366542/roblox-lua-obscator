--[[
╔═══════════════════════════════════════════════════════════════════╗
║                  NEXUS AI  —  Delta Edition                       ║
║  Deep Scan · AI Generate · UNC Tester · Device Info · Output     ║
║  Powered by Pollinations AI  ·  Claude Opus 4.6                  ║
╚═══════════════════════════════════════════════════════════════════╝

TABS
  ⬡ AI Generate  — type any request, tool scans game first so AI
                   uses real paths. Generates analysis + full script.
                   Live output log shows every scan/gen phase.
                   Copy or Execute (loadstring) directly.

  ⬡ UNC Tester   — detects your device, executor, screen size,
                   then tests all 32 UNC functions and shows
                   pass / fail in a color-coded grid.

  ⬡ Scanner      — finds frame-drawing functions in game scripts.
                   Each result: Copy + Execute.
--]]

-- ── Services ──────────────────────────────────────────────────────────────────
local Players  = game:GetService("Players")
local RS       = game:GetService("ReplicatedStorage")
local UIS      = game:GetService("UserInputService")
local TS       = game:GetService("TweenService")
local SG       = game:GetService("StarterGui")
local HS       = game:GetService("HttpService")
local RUN      = game:GetService("RunService")
local LP       = Players.LocalPlayer
local PGUI     = LP:WaitForChild("PlayerGui")
local CAM      = workspace.CurrentCamera

-- ── HTTP abstraction ──────────────────────────────────────────────────────────

-- URL encoder for GET requests
local function urlEnc(s)
    return (tostring(s):gsub("([^%w%-%.%_%~])", function(c)
        return string.format("%%%02X", string.byte(c))
    end))
end

-- GET (works on Delta iOS via game:HttpGet / HttpService:GetAsync)
local function doHttpGet(url)
    local ok1,r1 = pcall(function() return game:HttpGet(url,true) end)
    if ok1 and type(r1)=="string" and #r1>10 then return r1 end
    local ok2,r2 = pcall(function() return HS:GetAsync(url,true) end)
    if ok2 and type(r2)=="string" and #r2>10 then return r2 end
    return nil
end

-- POST (PC/Android executors via HttpService:RequestAsync or UNC request)
local function doHttpPost(url, body, headers)
    local H = headers or {["Content-Type"]="application/json"}
    local ok1,r1 = pcall(function()
        return HS:RequestAsync({Url=url,Method="POST",Headers=H,Body=body})
    end)
    if ok1 and r1 and (r1.StatusCode==200 or r1.Success) then return r1.Body or "" end
    local ok2,r2 = pcall(function()
        if type(request)=="function" then
            return request({Url=url,Method="POST",Headers=H,Body=body})
        end
    end)
    if ok2 and r2 and (r2.StatusCode==200 or r2.status==200) then return r2.Body or r2.body or "" end
    local ok3,r3 = pcall(function()
        if type(syn)=="table" and type(syn.request)=="function" then
            return syn.request({Url=url,Method="POST",Headers=H,Body=body})
        end
    end)
    if ok3 and r3 and (r3.StatusCode==200 or r3.status==200) then return r3.Body or r3.body or "" end
    return nil
end

-- legacy httpReq for UNC tester display
local httpReq
pcall(function()
    if type(request)=="function" then httpReq=request
    elseif type(http)=="table" and type(http.request)=="function" then httpReq=http.request
    elseif type(syn)=="table" and type(syn.request)=="function" then httpReq=syn.request
    end
end)

local clipSet
pcall(function()
    if type(setclipboard) == "function" then clipSet = setclipboard
    elseif type(syn) == "table" and type(syn.set_clipboard) == "function" then clipSet = syn.set_clipboard
    elseif type(Clipboard) == "table" and type(Clipboard.set) == "function" then clipSet = Clipboard.set
    end
end)
clipSet = clipSet or function() end

local getScripts
pcall(function() if type(getscripts) == "function" then getScripts = getscripts end end)
local doDecomp
pcall(function() if type(decompile) == "function" then doDecomp = decompile end end)

-- ── Colors ────────────────────────────────────────────────────────────────────
local C = {
    BG     = Color3.fromRGB(10,  14,  26 ),
    SIDE   = Color3.fromRGB(6,   9,   18 ),
    PANEL  = Color3.fromRGB(18,  24,  42 ),
    CARD   = Color3.fromRGB(14,  20,  36 ),
    EDIT   = Color3.fromRGB(9,   13,  24 ),
    DEEP   = Color3.fromRGB(6,   9,   18 ),
    HDRROW = Color3.fromRGB(14,  19,  36 ),
    ACC    = Color3.fromRGB(59,  130, 246),
    INDIGO = Color3.fromRGB(99,  102, 241),
    GRN    = Color3.fromRGB(34,  197, 94 ),
    RED    = Color3.fromRGB(220, 55,  55 ),
    AMBER  = Color3.fromRGB(245, 158, 11 ),
    TEAL   = Color3.fromRGB(20,  184, 166),
    PURPLE = Color3.fromRGB(168, 85,  247),
    TXT    = Color3.fromRGB(241, 245, 249),
    SUB    = Color3.fromRGB(148, 163, 184),
    MUTED  = Color3.fromRGB(71,  85,  105),
    BORDER = Color3.fromRGB(28,  38,  68 ),
    CODE   = Color3.fromRGB(160, 200, 240),
    LOG    = Color3.fromRGB(100, 220, 130),
}
local FB = Enum.Font.GothamBold
local FN = Enum.Font.Gotham
local FM = Enum.Font.RobotoMono

-- ── Tween ─────────────────────────────────────────────────────────────────────
local TF = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function tw(o, p) TS:Create(o, TF, p):Play() end
local function flash(b, c)
    local orig = b.BackgroundColor3
    tw(b, {BackgroundColor3 = c})
    task.delay(0.22, function() tw(b, {BackgroundColor3 = orig}) end)
end

-- ── UI helpers ────────────────────────────────────────────────────────────────
local function corner(p, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = p; return c
end
local function stroke(p, col, th)
    local s = Instance.new("UIStroke"); s.Color = col or C.BORDER; s.Thickness = th or 1; s.Parent = p; return s
end
local function pad(p, v, h)
    local u = Instance.new("UIPadding")
    u.PaddingTop=UDim.new(0,v); u.PaddingBottom=UDim.new(0,v)
    u.PaddingLeft=UDim.new(0,h); u.PaddingRight=UDim.new(0,h)
    u.Parent=p; return u
end
local function listV(p, sp)
    local l = Instance.new("UIListLayout")
    l.Padding=UDim.new(0,sp or 4)
    l.HorizontalAlignment=Enum.HorizontalAlignment.Left
    l.SortOrder=Enum.SortOrder.LayoutOrder
    l.Parent=p; return l
end
local function listH(p, sp)
    local l = Instance.new("UIListLayout")
    l.Padding=UDim.new(0,sp or 4)
    l.FillDirection=Enum.FillDirection.Horizontal
    l.VerticalAlignment=Enum.VerticalAlignment.Center
    l.SortOrder=Enum.SortOrder.LayoutOrder
    l.Parent=p; return l
end
local function F(par, sz, pos, col)
    local f = Instance.new("Frame"); f.Size=sz
    if pos then f.Position=pos end
    f.BackgroundColor3=col or C.BG; f.BorderSizePixel=0; f.Parent=par; return f
end
local function L(par, txt, sz, pos, col, fnt, ts, xa)
    local l = Instance.new("TextLabel"); l.Size=sz
    if pos then l.Position=pos end
    l.BackgroundTransparency=1; l.Text=txt; l.TextColor3=col or C.TXT
    l.Font=fnt or FN; l.TextSize=ts or 12; l.TextWrapped=true
    l.TextXAlignment=xa or Enum.TextXAlignment.Left; l.Parent=par; return l
end
local function B(par, txt, sz, pos, bg, tc, ts, fnt)
    local b = Instance.new("TextButton"); b.Size=sz
    if pos then b.Position=pos end
    b.BackgroundColor3=bg or C.ACC; b.Text=txt; b.TextColor3=tc or C.TXT
    b.Font=fnt or FB; b.TextSize=ts or 12; b.BorderSizePixel=0; b.Parent=par; return b
end
local function dot(par, sz, pos, col)
    local d = F(par, sz, pos, col or C.MUTED); corner(d,99); return d
end
local function scr(par, sz, pos)
    local s = Instance.new("ScrollingFrame"); s.Size=sz
    if pos then s.Position=pos end
    s.BackgroundColor3=C.PANEL; s.BorderSizePixel=0
    s.ScrollBarThickness=3; s.ScrollBarImageColor3=C.ACC
    s.AutomaticCanvasSize=Enum.AutomaticSize.Y
    s.CanvasSize=UDim2.new(0,0,0,0); s.Parent=par; return s
end

local function notify(t, b, d)
    pcall(function() SG:SetCore("SendNotification",{Title=t,Text=b,Duration=d or 3}) end)
end

-- ── code cleaner: strip fences, JSON wrappers, validate Lua ──────────────────
local function isLua(s)
    -- Must contain at least one Lua keyword/pattern to be considered real code
    return s:find("local ") or s:find("function ") or s:find("game:") or
           s:find("Players") or s:find("workspace") or s:find("%-%-") or
           s:find("require") or s:find("pcall") or s:find("task%.")
end

local function cleanLuaCode(raw)
    if not raw or raw=="" then return "" end
    local s = tostring(raw)
    -- Reject obvious error/HTML responses early
    if s:sub(1,1)=="<" then return "" end  -- HTML error page
    if #s < 30 and (s:lower():find("error") or s:lower():find("limit")) then return "" end
    -- JSON unwrap (OpenAI-format response)
    if s:sub(1,1)=="{" then
        local ok,j = pcall(function() return HS:JSONDecode(s) end)
        if ok and type(j)=="table" then
            -- Check for error field first
            if j.error then return "" end
            local c = (j.choices and j.choices[1] and j.choices[1].message and j.choices[1].message.content)
                   or j.content or j.text or j.response
            if type(c)=="string" then s = c end
        elseif not ok then
            -- Not valid JSON — treat as raw text
        end
    end
    -- Extract LONGEST ```lua...``` block
    local best
    for block in s:gmatch("```[lL]?[uU]?[aA]?%s*(.-)```") do
        if not best or #block>#best then best=block end
    end
    if best and #best>20 then s=best end
    -- Strip remaining fences
    s = s:gsub("```[lL]?[uU]?[aA]?%s*",""):gsub("```","")
    s = s:gsub("^%s+",""):gsub("%s+$","")
    -- Final validation: must look like Lua
    if not isLua(s) then return "" end
    return s
end

-- ── loadstring executor ───────────────────────────────────────────────────────
local function execScript(code)
    if not code or code:gsub("%s","")=="" then notify("Execute","No code to run.",3); return end
    -- Strip markdown fences if present (Scanner results may have them)
    code = code:gsub("```[lL]?[uU]?[aA]?%s*",""):gsub("```",""):gsub("^%s+",""):gsub("%s+$","")
    if code=="" then notify("Execute","Empty after strip.",3); return end
    local fn, err = loadstring(code)
    if not fn then
        notify("Syntax Error", tostring(err):sub(1,140), 6)
        return
    end
    local ok, runErr = pcall(fn)
    if not ok then
        notify("Runtime Error", tostring(runErr):sub(1,140), 6)
    else
        notify("Nexus AI","Script running!",2)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- DEVICE + EXECUTOR DETECTION
-- ═══════════════════════════════════════════════════════════════════════════════
local function detectDevice()
    local touch   = UIS.TouchEnabled
    local kb      = UIS.KeyboardEnabled
    local gamepad = UIS.GamepadEnabled
    local vp      = CAM.ViewportSize
    local deviceType = touch and not kb and "Mobile" or
                       touch and kb     and "Tablet" or
                       gamepad          and "Console" or "Desktop"

    local executor = "Delta"  -- default for this script
    pcall(function()
        if type(getexecutorname) == "function" then
            executor = getexecutorname()
        elseif type(identifyexecutor) == "function" then
            executor = identifyexecutor()
        elseif type(Delta) ~= "nil" then executor = "Delta"
        elseif type(syn) ~= "nil" then executor = "Synapse X"
        elseif type(KRNL_LOADED) ~= "nil" then executor = "KRNL"
        elseif type(fluxus) ~= "nil" then executor = "Fluxus"
        elseif type(Electron) ~= "nil" then executor = "Electron"
        elseif type(Xeno) ~= "nil" then executor = "Xeno"
        end
    end)

    return {
        device   = deviceType,
        executor = executor,
        touch    = touch,
        keyboard = kb,
        gamepad  = gamepad,
        width    = math.floor(vp.X),
        height   = math.floor(vp.Y),
    }
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- UNC FUNCTION TEST
-- ═══════════════════════════════════════════════════════════════════════════════
local UNC_LIST = {
    -- GC / metatable
    {n="getgc",              cat="GC"},
    {n="getrawmetatable",    cat="GC"},
    {n="setrawmetatable",    cat="GC"},
    {n="setreadonly",        cat="GC"},
    {n="isreadonly",         cat="GC"},
    -- Hooks
    {n="hookfunction",       cat="HOOK"},
    {n="newcclosure",        cat="HOOK"},
    {n="hookmetamethod",     cat="HOOK"},
    {n="replaceclosure",     cat="HOOK"},
    -- Scripts
    {n="getscripts",         cat="SCRIPT"},
    {n="getrunningscripts",  cat="SCRIPT"},
    {n="getsenv",            cat="SCRIPT"},
    {n="getscriptenv",       cat="SCRIPT"},
    {n="getscripthash",      cat="SCRIPT"},
    {n="decompile",          cat="SCRIPT"},
    -- Connections
    {n="getconnections",     cat="SIGNAL"},
    {n="firesignal",         cat="SIGNAL"},
    {n="fireclickdetector",  cat="SIGNAL"},
    {n="firetouchinterest",  cat="SIGNAL"},
    {n="fireproximityprompt",cat="SIGNAL"},
    -- Environment
    {n="getfenv",            cat="ENV"},
    {n="setfenv",            cat="ENV"},
    {n="getrenv",            cat="ENV"},
    {n="getgenv",            cat="ENV"},
    -- Debug
    {n="debug.info",         cat="DEBUG"},
    {n="debug.traceback",    cat="DEBUG"},
    -- UI
    {n="gethui",             cat="UI"},
    {n="protect_gui",        cat="UI"},
    {n="Drawing",            cat="UI"},
    -- Misc
    {n="request",            cat="HTTP"},
    {n="setclipboard",       cat="MISC"},
    {n="checkcaller",        cat="MISC"},
    {n="isourclosure",       cat="MISC"},
    {n="clonefunction",      cat="MISC"},
    {n="getnamecallmethod",  cat="MISC"},
}

local function testUNC()
    local results = {}
    for _, entry in ipairs(UNC_LIST) do
        local ok = pcall(function()
            local parts = entry.n:split(".")
            local v = _G[parts[1]]
            if #parts == 2 then
                assert(type(v) == "table")
                v = v[parts[2]]
            end
            assert(v ~= nil)
        end)
        table.insert(results, {name=entry.n, cat=entry.cat, pass=ok})
    end
    return results
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- GAME CONTEXT SCANNER
-- ═══════════════════════════════════════════════════════════════════════════════
local function gatherContext(onLog)
    local out = {}
    local t0 = tick()
    local function emit(s) table.insert(out, s) end
    local function log(s)  onLog(s); emit("-- " .. s) end
    local function timed() return tick()-t0 end

    emit("=== GAME CONTEXT ===")
    emit("PlaceId: " .. tostring(game.PlaceId))

    -- Device context
    local dev = detectDevice()
    emit("Device: " .. dev.device .. "  Executor: " .. dev.executor)
    emit("Screen: " .. dev.width .. "x" .. dev.height)

    -- UNC available (fast check, no decompile)
    local avail = {}
    for _, e in ipairs(UNC_LIST) do
        local ok = pcall(function()
            local parts = e.n:split(".")
            local v = _G[parts[1]]
            if #parts==2 then assert(type(v)=="table"); v=v[parts[2]] end
            assert(v ~= nil)
        end)
        if ok then table.insert(avail, e.n) end
    end
    emit("UNC: " .. table.concat(avail, ","))

    -- Game type (walk only direct children of workspace to stay fast)
    local pcount = #Players:GetPlayers()
    local hasNPC, hasProj, hasBall = false, false, false
    pcall(function()
        for _, v in ipairs(workspace:GetChildren()) do
            if v:IsA("Model") then
                local h = v:FindFirstChildOfClass("Humanoid")
                if h and not Players:GetPlayerFromCharacter(v) then hasNPC=true end
                local n = v.Name:lower()
                if n:find("npc") or n:find("enemy") or n:find("mob") then hasNPC=true end
                if n:find("ball") then hasBall=true end
            end
            if v:IsA("BasePart") then
                local n=v.Name:lower()
                if n:find("bullet") or n:find("proj") then hasProj=true end
                if n:find("ball") then hasBall=true end
            end
        end
    end)
    emit("PLAYERS:"..pcount.." NPC:"..(hasNPC and"YES"or"NO").." PROJ:"..(hasProj or hasBall and"YES"or"NO"))
    emit("PLAYER_ESP_NEEDED: "..(pcount>1 and"YES"or"NO"))
    emit("PROJECTILE_TRACK_NEEDED: "..((hasProj or hasBall) and"YES"or"NO"))
    emit("NPC_ESP_NEEDED: "..(hasNPC and"YES"or"NO"))

    -- Remotes (fast, max 40, depth 5)
    log("Scanning remotes...")
    local remotes = {}
    local function walkR(parent, path, depth)
        if depth>5 or #remotes>=40 then return end
        local ok,ch=pcall(function() return parent:GetChildren() end)
        if not ok then return end
        for _,v in ipairs(ch) do
            local p=path.."."..v.Name
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction")
            or v:IsA("BindableEvent") or v:IsA("BindableFunction") then
                table.insert(remotes, p.." ["..v.ClassName.."]")
            end
            if not v:IsA("BasePart") and not v:IsA("Model") then walkR(v,p,depth+1) end
        end
    end
    for _,sn in ipairs({"ReplicatedStorage","ReplicatedFirst","Lighting"}) do
        pcall(function() walkR(game:GetService(sn),sn,1) end)
    end
    if #remotes>0 then emit("REMOTES:"); for _,r in ipairs(remotes) do emit(" "..r) end end

    -- UI names only (fast, depth 3, max 30)
    log("Scanning UI...")
    local uis={}
    local function walkUI(p,path,d)
        if d>3 or #uis>=30 then return end
        local ok,ch=pcall(function() return p:GetChildren() end)
        if not ok then return end
        for _,v in ipairs(ch) do
            if v.Name~="NexusAI" then
                local pp=path.."."..v.Name
                if v:IsA("ScreenGui") or v:IsA("Frame") or v:IsA("TextButton") then
                    table.insert(uis,pp.."["..v.ClassName.."]")
                end
                walkUI(v,pp,d+1)
            end
        end
    end
    pcall(walkUI,PGUI,"PlayerGui",1)
    if #uis>0 then emit("UI:"); for _,u in ipairs(uis) do emit(" "..u) end end

    -- Scripts: names + .Source only (NO decompile — it's too slow)
    log("Scanning scripts...")
    local scripts = {}
    if getScripts then pcall(function() scripts=getScripts() end) end
    if #scripts==0 then
        pcall(function()
            for _,v in ipairs(game:GetDescendants()) do
                if (v:IsA("LocalScript") or v:IsA("ModuleScript")) then
                    table.insert(scripts,v)
                    if #scripts>=20 then break end
                end
            end
        end)
    end
    local scrLines, fnSeen = {}, {}
    for _,scr in ipairs(scripts) do
        if timed()>8 then break end  -- hard 8s cap on entire scan
        local src=""
        pcall(function() src=scr.Source end)  -- .Source only, never decompile()
        if src and src~="" then
            local sf = pcall(function() return scr:GetFullName() end) and scr:GetFullName() or scr.Name
            local fns, fires, reqs = {}, {}, {}
            for n in src:gmatch("function%s+([%w_%.]+)%s*%(") do
                local k=sf.."::"..n
                if not fnSeen[k] and #fns<15 then fnSeen[k]=true; table.insert(fns,n.."()") end
            end
            for call in src:gmatch(":([%w_]+)%(") do
                if call=="FireServer" or call=="InvokeServer" or call=="Fire" then fires[call]=true end
            end
            for req in src:gmatch("require%s*%((.-)%)") do table.insert(reqs,req); if #reqs>=4 then break end end
            if #fns>0 or next(fires) then
                local line=sf.." ["..scr.ClassName.."] fns:"..table.concat(fns,",")
                if next(fires) then local fl={} for k in pairs(fires) do table.insert(fl,k) end line=line.." uses:"..table.concat(fl,",") end
                if #reqs>0 then line=line.." req:"..table.concat(reqs,",") end
                table.insert(scrLines, line)
            end
        end
        if #scrLines>=40 then break end
    end
    if #scrLines>0 then emit("\nSCRIPT MAP:"); for _,s in ipairs(scrLines) do emit("  "..s) end end

    -- Hookable targets
    log("Building hookable targets list...")
    local hooks={}
    for _, r in ipairs(remotes) do
        local path = r:match("^(.-)%s+%[")
        if r:find("RemoteEvent")   then table.insert(hooks,"LISTEN:"..path..":OnClientEvent") end
        if r:find("RemoteEvent")   then table.insert(hooks,"FIRE:"  ..path..":FireServer()") end
        if r:find("RemoteFunction")then table.insert(hooks,"INVOKE:"..path..":InvokeServer()") end
        if r:find("BindableEvent") then table.insert(hooks,"BIND:"  ..path..":Fire()") end
        if #hooks>=60 then break end
    end
    for _, s in ipairs(scrLines) do
        for fn in s:gmatch("fns:([^%s]+)") do
            for f in fn:gmatch("([^,]+)") do
                table.insert(hooks,"HOOK_FN:"..f)
                if #hooks>=100 then break end
            end
        end
        if #hooks>=100 then break end
    end
    local function walkBtns(p, path, d)
        if d>5 or #hooks>=130 then return end
        local ok,ch=pcall(function() return p:GetChildren() end)
        if not ok then return end
        for _,v in ipairs(ch) do
            if v.Name~="NexusAI" then
                local pp=path.."."..v.Name
                if v:IsA("TextButton") or v:IsA("ImageButton") then
                    table.insert(hooks,"BTN:"..pp..":MouseButton1Click")
                end
                walkBtns(v,pp,d+1)
            end
        end
    end
    pcall(walkBtns, PGUI, "PlayerGui", 1)
    if #hooks>0 then
        emit("\nHOOKABLE TARGETS (hook ALL in generated code):")
        for i,h in ipairs(hooks) do if i>130 then break end emit("  "..h) end
    end

    emit("\n=== END CONTEXT ===")
    return table.concat(out,"\n")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SYSTEM PROMPT
-- ═══════════════════════════════════════════════════════════════════════════════
local SYS = [=[You are an expert Roblox Lua architect for executor environments (Delta, Synapse, KRNL).
You receive a GAME CONTEXT block: full live game hierarchy, game type classification, player/NPC/projectile detection flags, device info, available UNC functions, and a pre-built HOOKABLE TARGETS list.

══ ANALYSIS PHASE (mandatory first) ══
Output before any code:
--[[ ANALYSIS REPORT
  Game: <name + PlaceId>
  Device: <device type, executor, screen>
  UI Structure: which ScreenGuis exist, how menus are laid out
  Gameplay Systems: which RemoteEvents drive which mechanics
  Event Flow: how client→server communication works
  Player ESP Needed: YES/NO — explain why based on PLAYER_ESP_NEEDED flag
  Projectile Tracking Needed: YES/NO — explain why based on PROJECTILE_TRACK_NEEDED flag
  NPC ESP Needed: YES/NO — based on NPC_ESP_NEEDED flag
  Hook Plan: for every HOOKABLE TARGET entry — state what you hook it to and what you gain
  UNC Usage: list every available UNC function you will use and exactly why
  Missing Info: anything that cannot be determined — state explicitly
]]

══ HOOK EVERYTHING (non-negotiable) ══
For EVERY entry in HOOKABLE TARGETS:
  LISTEN  → :OnClientEvent — intercept all server→client traffic, log to output panel
  FIRE    → hookfunction() on the :FireServer call — intercept/log/optionally modify args
  INVOKE  → hookfunction() on :InvokeServer — intercept request + response
  BIND    → :Event connect + hookfunction() on :Fire()
  HOOK_FN → hookfunction(fn, newcclosure(wrapper)) on every game function found
  BTN     → :MouseButton1Click connect on every game UI button

══ SMART FEATURE INCLUSION ══
  PLAYER_ESP_NEEDED=YES  → add DrawingAPI ESP (boxes+names+health+distance) for all players
  PLAYER_ESP_NEEDED=NO   → skip player ESP (no players to track)
  PROJECTILE_TRACK_NEEDED=YES → add projectile tracker (line from screen center + label)
  NPC_ESP_NEEDED=YES     → add NPC/enemy ESP boxes
  For EVERY feature add an on/off toggle — green=on, red=off

══ UNC MAXIMISATION ══
Use ONLY UNC functions listed as available in GAME CONTEXT. For each one used:
  hookfunction()     → intercept game functions (wrap hook in newcclosure())
  getconnections()   → enumerate handlers on Humanoid.HealthChanged, Humanoid.Died, etc.
  firesignal()       → fire signals programmatically
  getgc(true)        → find hidden instances/tables not in instance tree
  getrawmetatable()  → read locked metatables; setreadonly(mt,false) before writing
  hookmetamethod()   → intercept __index/__newindex globally on game objects
  getsenv()          → read a running LocalScript's upvalues and globals
  newcclosure()      → wrap every hook to appear as C closure

══ DRAWING BOT ══
  Drawing.new("Square") for ESP boxes, Drawing.new("Line") for tracers
  Drawing.new("Text") for labels/names, Drawing.new("Circle") for dots
  Update EVERYTHING in RunService.RenderStepped — never loops or Heartbeat
  pos2d, depth, onScreen = Camera:WorldToViewportPoint(part.Position)
  Only set .Visible = true when onScreen == true
  Clean up on toggle-off: set .Visible = false on all drawings

══ OUTPUT LOG PANEL ══
  The UI must have a live output TextLabel (scrollable) that logs:
  • Every hooked remote name when it fires (truncated to 80 chars)
  • Errors caught by pcall
  • Feature on/off state changes
  Keep last 30 lines max — drop oldest when full

══ UI DESIGN ══
  ONE draggable ScreenGui, dark navy theme (BG: RGB(10,14,26))
  Title bar with drag (mouse MouseMovement + touch Touch)
  Feature toggles grouped under section headers (HOOKS / ESP / PLAYER / BOTS)
  Config table at top with all tuneable values (ESP distance, colors, keys)
  All pcall wrapped, task.spawn/task.wait only, one-line WHY comment per block
  Use ONLY instance paths from GAME CONTEXT

OUTPUT FORMAT:
--[[ ANALYSIS REPORT ... ]]
<raw Lua code only — no backticks, no markdown>]=]

-- ═══════════════════════════════════════════════════════════════════════════════
-- AI GENERATION
-- ═══════════════════════════════════════════════════════════════════════════════
-- Pollinations valid model names (NOT Anthropic names):
-- GET+POST: "openai" (GPT-4o), "mistral", "llama", "claude" (Claude 3)
-- POST only: "openai-large" (GPT-4o high), "gemini"

local SYS_SHORT = "Roblox Lua executor script writer. Write complete working Roblox scripts. Use real paths from GAME INFO. Hook remotes, add ESP if multiplayer, toggles, output log. Raw Lua code ONLY. No markdown."

-- Build a brief game summary (under 300 chars) from full context
local function gameSum(ctx)
    local lines = {}
    for l in ctx:gmatch("[^\n]+") do
        local t = l:gsub("^%-%-+%s*",""):gsub("^%s+","")
        if #t>3 and not t:find("^===") and not t:find("^  ") then
            table.insert(lines, t)
            if #lines >= 8 then break end
        end
    end
    -- grab remote names
    for r in ctx:gmatch("REMOTES?:\n(.-)HOOKABLE") do
        for l in r:gmatch("[^\n]+") do
            table.insert(lines, l:gsub("^%s+",""))
            if #lines >= 14 then break end
        end
        break
    end
    return table.concat(lines," | "):sub(1,280)
end

local function aiGenerate(prompt, ctx, onStatus)
    local lastErr = "no response"
    local seed = math.random(1,99999)

    -- GET method: short URL — only user prompt in path, game summary in system
    -- Works on Delta iOS via game:HttpGet(). URL stays under ~800 chars.
    local function tryGET(model)
        local sys = SYS_SHORT.." GAME:"..gameSum(ctx)
        local url = "https://text.pollinations.ai/"..urlEnc(prompt)
            .."?model="..model.."&seed="..seed.."&system="..urlEnc(sys)
        local body = doHttpGet(url)
        if not body or #body<15 then lastErr="GET empty (model="..model..")"; return nil end
        if body:sub(1,1)=="<" then lastErr="GET returned HTML error"; return nil end
        local cleaned = cleanLuaCode(body)
        if #cleaned>30 then return cleaned end
        lastErr="GET not Lua: "..body:sub(1,60)
        return nil
    end

    -- POST method: OpenAI-compatible endpoint with full context
    -- Correct Pollinations POST endpoint: /openai/chat/completions
    local function tryPOST(model)
        local full = ctx.."\n\nREQUEST: "..prompt
        local payload = HS:JSONEncode({
            model=model, seed=seed,
            messages={
                {role="system", content=SYS_SHORT},
                {role="user",   content=full:sub(1,4000)},  -- cap at 4k chars
            },
        })
        -- Try the correct OpenAI-compatible endpoint first, then fallback
        local res = doHttpPost("https://text.pollinations.ai/openai/chat/completions", payload,
            {["Content-Type"]="application/json"})
        if not res or #res<15 then
            res = doHttpPost("https://text.pollinations.ai/", payload,
                {["Content-Type"]="application/json"})
        end
        if not res or #res<15 then lastErr="POST empty (model="..model..")"; return nil end
        local cleaned = cleanLuaCode(res)
        if #cleaned>30 then return cleaned end
        lastErr="POST not Lua: "..res:sub(1,60)
        return nil
    end

    -- Attempt order: GET (Delta iOS works) → POST fallback
    -- Use correct Pollinations model names only
    onStatus("AI: GET openai...")
    local code = tryGET("openai")
    if not code then
        task.wait(1.5); onStatus("AI: GET mistral...")
        code = tryGET("mistral")
    end
    if not code then
        task.wait(1.5); onStatus("AI: GET claude...")
        code = tryGET("claude")  -- Pollinations name for Claude is "claude" not "claude-opus-4-6"
    end
    if not code then
        task.wait(2); onStatus("AI: POST openai...")
        code = tryPOST("openai")
    end
    if not code then
        task.wait(2); onStatus("AI: POST openai-large...")
        code = tryPOST("openai-large")
    end
    if code then return code,nil end
    return nil,lastErr
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SCANNER
-- ═══════════════════════════════════════════════════════════════════════════════
local FPATS = {
    'Instance%.new%s*%(%s*["\']Frame["\']','Instance%.new%s*%(%s*["\']ScreenGui["\']',
    'Instance%.new%s*%(%s*["\']ScrollingFrame["\']','Instance%.new%s*%(%s*["\']SurfaceGui["\']',
    'Drawing%.new%s*%(%s*["\']Square["\']','Drawing%.new%s*%(%s*["\']Circle["\']',
    'Drawing%.new%s*%(%s*["\']Line["\']','DrawingAPI','drawFrame','CreateBox','BoxESP',
}
local function matchFP(c) for _,p in ipairs(FPATS) do if c:find(p) then return true end end return false end
local function extractFns(src, name)
    if not src or src=="" then return {} end
    local res,seen={},{}
    local function tryAdd(sig,n,body)
        if seen[n] then return end
        if matchFP(body) then seen[n]=true; table.insert(res,{name=n,code=sig.."\n"..body.."\nend",source=name}) end
    end
    for s,n,b in src:gmatch("(local%s+function%s+(%w+)%b()%s*)\n(.-)\nend") do tryAdd(s,n,b) end
    for s,n,b in src:gmatch("(function%s+([%w_%.]+)%b()%s*)\n(.-)\nend")     do tryAdd(s,n,b) end
    return res
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- BUILD GUI
-- ═══════════════════════════════════════════════════════════════════════════════
-- Parent target: gethui() > CoreGui > PlayerGui (hidden from game scripts)
local function getGuiParent()
    local ok, hui = pcall(function() return gethui and gethui() end)
    if ok and hui then return hui end
    local ok2, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok2 and cg then return cg end
    return PGUI
end
local GUI_PARENT = getGuiParent()

for _,old in ipairs(GUI_PARENT:GetChildren()) do
    if old.Name=="NexusAI" then pcall(function() old:Destroy() end) end
end
if PGUI:FindFirstChild("NexusAI") then PGUI.NexusAI:Destroy() end

local GUI = Instance.new("ScreenGui")
GUI.Name="NexusAI"; GUI.ResetOnSpawn=false
GUI.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
GUI.DisplayOrder=999
GUI.IgnoreGuiInset=true
pcall(function() GUI.Parent = GUI_PARENT end)
if not GUI.Parent then GUI.Parent = PGUI end
pcall(function() if syn and syn.protect_gui then syn.protect_gui(GUI) end end)
pcall(function() if protect_gui then protect_gui(GUI) end end)

-- Responsive sizing: fit to screen, max 520x692, min 300x420
local _vp = CAM.ViewportSize
local WIN_W = math.min(480, math.max(300, math.floor(_vp.X * 0.92)))
local WIN_H = math.min(520, math.max(400, math.floor(_vp.Y * 0.72)))
print(string.format("[NexusAI] GUI parent=%s viewport=%dx%d window=%dx%d",
    tostring(GUI.Parent and GUI.Parent:GetFullName() or "nil"),
    _vp.X, _vp.Y, WIN_W, WIN_H))

-- Shadow
local SHADOW = F(GUI,UDim2.new(0,WIN_W+20,0,WIN_H+20),
    UDim2.new(0.5,-(WIN_W+20)/2,0.5,-(WIN_H+20)/2),Color3.new(0,0,0))
SHADOW.BackgroundTransparency=0.65; corner(SHADOW,16)

-- Window
local WIN = F(GUI,UDim2.new(0,WIN_W,0,WIN_H),
    UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2),C.BG)
corner(WIN,12); stroke(WIN,C.BORDER,1.5)

-- ── Title bar ─────────────────────────────────────────────────────────────────
local TBAR = F(WIN,UDim2.new(1,0,0,48),UDim2.new(0,0,0,0),C.SIDE)
corner(TBAR,12); F(TBAR,UDim2.new(1,0,0,12),UDim2.new(0,0,1,-12),C.SIDE)

-- Title accent stripe
local STRIPE = F(TBAR,UDim2.new(0,3,0,26),UDim2.new(0,14,0.5,-13),C.ACC); corner(STRIPE,2)

-- Title text
L(TBAR,"Nexus AI",       UDim2.new(0,160,0,20),UDim2.new(0,26,0,6),  C.TXT,  FB,14)
L(TBAR,"Delta  ·  Pollinations AI  ·  Claude Opus 4.6",
        UDim2.new(0,340,0,14),UDim2.new(0,26,0,27), C.MUTED,FN,9)

-- Device badge (top-right of title bar)
local dev0 = detectDevice()
local DEVBADGE = F(TBAR,UDim2.new(0,72,0,18),UDim2.new(1,-118,0.5,-9),Color3.fromRGB(22,32,56))
corner(DEVBADGE,4)
local DEVLBL = L(DEVBADGE,dev0.device,UDim2.new(1,0,1,0),nil,C.TEAL,FB,9)
DEVLBL.TextXAlignment=Enum.TextXAlignment.Center

-- Close
local CLOSE=B(TBAR,"✕",UDim2.new(0,26,0,26),UDim2.new(1,-36,0.5,-13),C.RED,C.TXT,11,FB)
corner(CLOSE,6)
CLOSE.MouseEnter:Connect(function() tw(CLOSE,{BackgroundColor3=Color3.fromRGB(255,70,70)}) end)
CLOSE.MouseLeave:Connect(function() tw(CLOSE,{BackgroundColor3=C.RED}) end)
CLOSE.MouseButton1Click:Connect(function() GUI:Destroy() end)

-- ── Drag ──────────────────────────────────────────────────────────────────────
do
    local drag,dSt,wSt
    local function ss()
        SHADOW.Position=UDim2.new(WIN.Position.X.Scale,WIN.Position.X.Offset-10,
                                   WIN.Position.Y.Scale,WIN.Position.Y.Offset-10)
    end
    TBAR.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then
            drag=true; dSt=i.Position; wSt=WIN.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if not drag then return end
        if i.UserInputType==Enum.UserInputType.MouseMovement
        or i.UserInputType==Enum.UserInputType.Touch then
            local d=i.Position-dSt
            WIN.Position=UDim2.new(wSt.X.Scale,wSt.X.Offset+d.X,wSt.Y.Scale,wSt.Y.Offset+d.Y)
            ss()
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then drag=false end
    end)
    ss()
end

-- ── Tab bar ───────────────────────────────────────────────────────────────────
local TABBAR = F(WIN,UDim2.new(1,-24,0,34),UDim2.new(0,12,0,56),C.PANEL); corner(TABBAR,8)
local function mkTab(txt, xoff, active)
    local w = active and C.ACC or C.CARD
    local tc = active and C.TXT or C.SUB
    local b=B(TABBAR,txt,UDim2.new(0.333,-3,1,-8),UDim2.new(xoff,2,0,4),w,tc,11,FB); corner(b,6); return b
end
local TAB_AI  = mkTab("⬡  AI Generate", 0,     true)
local TAB_UNC = mkTab("⬡  UNC Tester",  0.333, false)
local TAB_SCN = mkTab("⬡  Scanner",     0.666, false)

-- ── Status bar ────────────────────────────────────────────────────────────────
local SBAR = F(WIN,UDim2.new(1,-24,0,26),UDim2.new(0,12,0,98),C.PANEL); corner(SBAR,6)
local SDOT  = dot(SBAR,UDim2.new(0,8,0,8),UDim2.new(0,8,0.5,-4),C.GRN)
local STXT  = L(SBAR,"Ready",UDim2.new(1,-28,1,0),UDim2.new(0,22,0,0),C.SUB,FN,10)
STXT.TextTruncate=Enum.TextTruncate.AtEnd
local function setStatus(msg,col) STXT.Text=msg; tw(SDOT,{BackgroundColor3=col or C.MUTED}) end

-- ═══════════════════════════════════════════════════════════════════════════════
-- PAGE CONTAINER (below status bar)
-- ═══════════════════════════════════════════════════════════════════════════════
local PAGE = F(WIN,UDim2.new(1,-24,1,-138),UDim2.new(0,12,0,132),C.BG)

-- ── AI GENERATE PAGE ──────────────────────────────────────────────────────────
local AI_PAGE = F(PAGE,UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),C.BG)

-- Prompt input (compact: 68px tall)
local PFRAME = F(AI_PAGE,UDim2.new(1,0,0,68),UDim2.new(0,0,0,0),C.PANEL)
corner(PFRAME,8); stroke(PFRAME,C.BORDER)
L(PFRAME,"Prompt:",UDim2.new(1,-12,0,12),UDim2.new(0,10,0,4),C.SUB,FB,9)
local PIN = Instance.new("TextBox")
PIN.Size=UDim2.new(1,-16,0,44); PIN.Position=UDim2.new(0,8,0,18)
PIN.BackgroundColor3=C.EDIT; PIN.Text=""
PIN.PlaceholderText='e.g. "hook all remotes, ESP players, autoparry, toggles"'
PIN.PlaceholderColor3=C.MUTED; PIN.TextColor3=C.TXT
PIN.Font=FM; PIN.TextSize=10; PIN.MultiLine=true
PIN.ClearTextOnFocus=false; PIN.TextXAlignment=Enum.TextXAlignment.Left
PIN.TextYAlignment=Enum.TextYAlignment.Top; PIN.BorderSizePixel=0
PIN.Parent=PFRAME; corner(PIN,6); pad(PIN,4,8)

-- Generate button
local GENBTN=B(AI_PAGE,"⬡  Scan + Generate",UDim2.new(1,0,0,30),UDim2.new(0,0,0,74),C.ACC,C.TXT,12,FB)
corner(GENBTN,8)
GENBTN.MouseEnter:Connect(function() tw(GENBTN,{BackgroundColor3=Color3.fromRGB(80,152,255)}) end)
GENBTN.MouseLeave:Connect(function() tw(GENBTN,{BackgroundColor3=C.ACC}) end)

-- Live output log (compact: 50px)
local LOGLBL = F(AI_PAGE,UDim2.new(1,0,0,14),UDim2.new(0,0,0,110),C.BG)
L(LOGLBL,"LOG",UDim2.new(0,40,1,0),nil,C.MUTED,FB,9)
local LOGCLEAR=B(LOGLBL,"Clear",UDim2.new(0,34,1,0),UDim2.new(1,-36,0,0),C.CARD,C.SUB,8,FN)
corner(LOGCLEAR,4)

local LOGBOX = Instance.new("ScrollingFrame")
LOGBOX.Size=UDim2.new(1,0,0,50); LOGBOX.Position=UDim2.new(0,0,0,126)
LOGBOX.BackgroundColor3=C.DEEP; LOGBOX.BorderSizePixel=0
LOGBOX.ScrollBarThickness=2; LOGBOX.ScrollBarImageColor3=C.MUTED
LOGBOX.AutomaticCanvasSize=Enum.AutomaticSize.Y; LOGBOX.CanvasSize=UDim2.new(0,0,0,0)
LOGBOX.Parent=AI_PAGE; corner(LOGBOX,6); stroke(LOGBOX,C.BORDER); pad(LOGBOX,3,6)
listV(LOGBOX,1)

local logLines = {}
local function addLog(msg, col)
    local lbl = Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,0,0,0); lbl.AutomaticSize=Enum.AutomaticSize.Y
    lbl.BackgroundTransparency=1
    lbl.Text=os.date("%H:%M:%S").." "..tostring(msg):sub(1,100)
    lbl.TextColor3=col or C.LOG; lbl.Font=FM; lbl.TextSize=9
    lbl.TextWrapped=true; lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.LayoutOrder=#logLines+1; lbl.Parent=LOGBOX
    table.insert(logLines,lbl)
    if #logLines>30 then logLines[1]:Destroy(); table.remove(logLines,1) end
    task.defer(function()
        LOGBOX.CanvasPosition=Vector2.new(0,math.max(0,LOGBOX.AbsoluteCanvasSize.Y-LOGBOX.AbsoluteSize.Y))
    end)
end
LOGCLEAR.MouseButton1Click:Connect(function()
    for _,l in ipairs(logLines) do l:Destroy() end; logLines={}
end)

-- Code output section
local OUTLBL=L(AI_PAGE,"GENERATED SCRIPT",UDim2.new(0,160,0,12),UDim2.new(0,0,0,182),C.MUTED,FB,9)
local OUTCNT=L(AI_PAGE,"",               UDim2.new(1,0,0,12),  UDim2.new(0,0,0,182),C.MUTED,FN,9)
OUTCNT.TextXAlignment=Enum.TextXAlignment.Right

-- Code scroll (height = remaining page height minus 198px for fixed elements above + 34px buttons below)
local CSCR=scr(AI_PAGE,UDim2.new(1,0,1,-232),UDim2.new(0,0,0,196))
CSCR.BackgroundColor3=C.DEEP; corner(CSCR,8); pad(CSCR,8,10)

local CLBL = Instance.new("TextLabel")
CLBL.Size=UDim2.new(1,0,0,0); CLBL.AutomaticSize=Enum.AutomaticSize.Y
CLBL.BackgroundTransparency=1
CLBL.Text="← Enter a prompt and press Generate"
CLBL.TextColor3=C.MUTED; CLBL.Font=FM; CLBL.TextSize=10
CLBL.TextWrapped=true; CLBL.TextXAlignment=Enum.TextXAlignment.Left; CLBL.Parent=CSCR

-- Copy + Execute
local COPYBTN=B(AI_PAGE,"⧉  Copy Script",           UDim2.new(0.5,-3,0,32),UDim2.new(0,0,1,-34),  C.INDIGO,C.TXT,11,FB); corner(COPYBTN,8)
local EXECBTN=B(AI_PAGE,"▶  Execute via loadstring", UDim2.new(0.5,-3,0,32),UDim2.new(0.5,3,1,-34),C.GRN,   C.TXT,11,FB); corner(EXECBTN,8)
COPYBTN.MouseEnter:Connect(function() tw(COPYBTN,{BackgroundColor3=Color3.fromRGB(118,122,255)}) end)
COPYBTN.MouseLeave:Connect(function() tw(COPYBTN,{BackgroundColor3=C.INDIGO}) end)
EXECBTN.MouseEnter:Connect(function() tw(EXECBTN,{BackgroundColor3=Color3.fromRGB(50,220,110)}) end)
EXECBTN.MouseLeave:Connect(function() tw(EXECBTN,{BackgroundColor3=C.GRN}) end)

local generatedCode=""
COPYBTN.MouseButton1Click:Connect(function()
    if generatedCode=="" then notify("Nexus AI","Nothing generated yet.",2); return end
    clipSet(generatedCode); flash(COPYBTN,C.GRN)
    COPYBTN.Text="✓  Copied!"; task.delay(1.8,function() COPYBTN.Text="⧉  Copy Script" end)
    addLog("Copied to clipboard ("..#generatedCode.." chars)",C.GRN)
    notify("Nexus AI","Copied!",2)
end)
EXECBTN.MouseButton1Click:Connect(function()
    if generatedCode=="" then notify("Nexus AI","Nothing generated yet.",2); return end
    flash(EXECBTN,C.AMBER); addLog("Executing via loadstring...",C.AMBER)
    task.spawn(function() execScript(generatedCode) end)
end)

local generating=false
GENBTN.MouseButton1Click:Connect(function()
    if generating then return end
    local prompt=PIN.Text
    if not prompt or prompt:gsub("%s","")=="" then notify("Nexus AI","Enter a prompt!",2); return end
    generating=true; generatedCode=""
    CLBL.Text="Scanning game..."; CLBL.TextColor3=C.AMBER; OUTCNT.Text=""
    setStatus("Phase 1 — deep scanning game...",C.AMBER)
    tw(GENBTN,{BackgroundColor3=Color3.fromRGB(38,58,102)}); GENBTN.Text="Scanning..."
    addLog("Starting deep scan...",C.AMBER)

    task.spawn(function()
        local ctx = gatherContext(function(msg)
            setStatus(msg,C.AMBER); addLog(msg,C.SUB)
        end)
        addLog("Context built: "..#ctx.." chars",C.GRN)
        GENBTN.Text="Asking AI..."
        CLBL.Text="AI is writing your script..."
        CLBL.TextColor3=C.AMBER

        -- Live elapsed-time counter so user sees it's working
        local aiStart = tick()
        local timerConn
        local lastLabel = ""
        timerConn = RUN.Heartbeat:Connect(function()
            local s = math.floor(tick()-aiStart)
            local lbl = "AI thinking... "..s.."s (normal: 10-30s)"
            if lbl ~= lastLabel then
                lastLabel = lbl
                setStatus(lbl, C.AMBER)
                GENBTN.Text = "AI... "..s.."s"
            end
        end)

        local code,err = aiGenerate(prompt, ctx, function(msg)
            addLog(msg,C.SUB)
        end)
        timerConn:Disconnect()

        if code and #code>20 then
            generatedCode=code
            CLBL.Text=code; CLBL.TextColor3=C.CODE
            OUTCNT.Text=#code.." chars"
            local elapsed = math.floor(tick()-aiStart)
            setStatus("Done in "..elapsed.."s — "..(#code).." chars · Copy or Execute",C.GRN)
            addLog("Script ready: "..(#code).." chars in "..elapsed.."s",C.GRN)
            notify("Nexus AI","Script ready! ("..elapsed.."s)",3)
        else
            CLBL.Text="Failed:\n"..(err or "unknown error")
            CLBL.TextColor3=C.RED
            setStatus("Failed: "..(err or "?"),C.RED)
            addLog("FAILED: "..(err or "unknown"),C.RED)
            notify("Nexus AI","Failed: "..(err or "?"):sub(1,60),4)
        end
        tw(GENBTN,{BackgroundColor3=C.ACC})
        GENBTN.Text="⬡  Scan + Generate"
        generating=false
    end)
end)

-- ── UNC TESTER PAGE ───────────────────────────────────────────────────────────
local UNC_PAGE = F(PAGE,UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),C.BG)
UNC_PAGE.Visible=false

-- Device info card
local DEVCARD = F(UNC_PAGE,UDim2.new(1,0,0,86),UDim2.new(0,0,0,0),C.PANEL)
corner(DEVCARD,8); stroke(DEVCARD,C.BORDER)
local function mkInfoRow(y, icon, label, value, vcol)
    L(DEVCARD,icon.."  "..label, UDim2.new(0,160,0,18),UDim2.new(0,10,0,y),C.SUB,FN,10)
    L(DEVCARD,value,             UDim2.new(1,-180,0,18),UDim2.new(0,174,0,y),vcol or C.TXT,FB,10)
end

local RUNTESTBTN=B(UNC_PAGE,"⬡  Run UNC Test",UDim2.new(1,0,0,34),UDim2.new(0,0,0,92),C.ACC,C.TXT,13,FB)
corner(RUNTESTBTN,8)
RUNTESTBTN.MouseEnter:Connect(function() tw(RUNTESTBTN,{BackgroundColor3=Color3.fromRGB(80,152,255)}) end)
RUNTESTBTN.MouseLeave:Connect(function() tw(RUNTESTBTN,{BackgroundColor3=C.ACC}) end)

local UNCTITLE=L(UNC_PAGE,"UNC RESULTS",UDim2.new(0,100,0,12),UDim2.new(0,0,0,134),C.MUTED,FB,9)
local UNCPASS =L(UNC_PAGE,"",           UDim2.new(1,0,0,12),  UDim2.new(0,0,0,134),C.GRN,  FN,9)
UNCPASS.TextXAlignment=Enum.TextXAlignment.Right

local UNCSCR=scr(UNC_PAGE,UDim2.new(1,0,1,-150),UDim2.new(0,0,0,150))
UNCSCR.BackgroundColor3=C.PANEL; corner(UNCSCR,8); pad(UNCSCR,8,8)
listV(UNCSCR,4)

local UNCEMPTY=L(UNCSCR,"Press  ⬡ Run UNC Test  to check all functions.",
    UDim2.new(1,0,0,80),nil,C.MUTED,FN,11)
UNCEMPTY.TextXAlignment=Enum.TextXAlignment.Center

local function populateDevInfo()
    -- Clear existing rows
    for _,c in ipairs(DEVCARD:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
    local dev = detectDevice()
    mkInfoRow(6,  "📱","Device",    dev.device,              C.TEAL)
    mkInfoRow(24, "⚙","Executor",  dev.executor,            C.AMBER)
    mkInfoRow(42, "🖥","Screen",    dev.width.."×"..dev.height, C.ACC)
    local caps={}
    if dev.touch    then table.insert(caps,"Touch") end
    if dev.keyboard then table.insert(caps,"Keyboard") end
    if dev.gamepad  then table.insert(caps,"Gamepad") end
    mkInfoRow(60, "⌨","Input",     table.concat(caps,", ") or "None", C.SUB)
end

RUNTESTBTN.MouseButton1Click:Connect(function()
    populateDevInfo()
    setStatus("Running UNC tests...",C.AMBER)
    tw(RUNTESTBTN,{BackgroundColor3=Color3.fromRGB(38,58,102)}); RUNTESTBTN.Text="Testing..."

    task.spawn(function()
        -- Clear old results
        for _,c in ipairs(UNCSCR:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
        UNCEMPTY.Visible=false

        local results = testUNC()
        local passCount = 0
        local catColors = {GC=C.PURPLE,HOOK=C.ACC,SCRIPT=C.TEAL,SIGNAL=C.AMBER,
                           ENV=C.INDIGO,DEBUG=C.SUB,UI=C.GRN,HTTP=C.ACC,MISC=C.MUTED}

        for i, r in ipairs(results) do
            if r.pass then passCount=passCount+1 end
            local ROW = Instance.new("Frame")
            ROW.Size=UDim2.new(1,0,0,24); ROW.BackgroundColor3=r.pass and Color3.fromRGB(14,28,20) or Color3.fromRGB(28,14,14)
            ROW.BorderSizePixel=0; ROW.LayoutOrder=i; ROW.Parent=UNCSCR
            corner(ROW,5)

            -- Category pill
            local CAT=F(ROW,UDim2.new(0,52,0,16),UDim2.new(0,4,0.5,-8),Color3.fromRGB(22,28,46))
            corner(CAT,4)
            local CATL=L(CAT,r.cat,UDim2.new(1,0,1,0),nil,catColors[r.cat] or C.SUB,FM,8)
            CATL.TextXAlignment=Enum.TextXAlignment.Center

            -- Function name
            L(ROW,r.name,UDim2.new(1,-120,1,0),UDim2.new(0,62,0,0),C.TXT,FM,10)

            -- Status
            local statusTxt = r.pass and "✓  available" or "✗  not available"
            local statusCol  = r.pass and C.GRN          or C.RED
            local SL=L(ROW,statusTxt,UDim2.new(0,100,1,0),UDim2.new(1,-106,0,0),statusCol,FB,9)
            SL.TextXAlignment=Enum.TextXAlignment.Right

            task.wait(0.02)
        end

        UNCPASS.Text = passCount.."/"..#results.." available"
        setStatus("UNC test done — "..passCount.."/"..#results.." available",
                  passCount > #results*0.6 and C.GRN or C.AMBER)
        tw(RUNTESTBTN,{BackgroundColor3=C.ACC}); RUNTESTBTN.Text="⬡  Run UNC Test"
    end)
end)

-- Init device info display
populateDevInfo()

-- ── SCANNER PAGE ──────────────────────────────────────────────────────────────
local SCN_PAGE = F(PAGE,UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),C.BG)
SCN_PAGE.Visible=false

local SCANBTN=B(SCN_PAGE,"⬡  Scan Game for Frame Functions",UDim2.new(1,0,0,34),UDim2.new(0,0,0,0),C.ACC,C.TXT,13,FB)
corner(SCANBTN,8)
SCANBTN.MouseEnter:Connect(function() tw(SCANBTN,{BackgroundColor3=Color3.fromRGB(80,152,255)}) end)
SCANBTN.MouseLeave:Connect(function() tw(SCANBTN,{BackgroundColor3=C.ACC}) end)

L(SCN_PAGE,"RESULTS",UDim2.new(0,80,0,12),UDim2.new(0,0,0,42),C.MUTED,FB,9)
local RCNT=L(SCN_PAGE,"",UDim2.new(1,0,0,12),UDim2.new(0,0,0,42),C.SUB,FN,9)
RCNT.TextXAlignment=Enum.TextXAlignment.Right

local RSCR=scr(SCN_PAGE,UDim2.new(1,0,1,-58),UDim2.new(0,0,0,58))
RSCR.BackgroundColor3=C.PANEL; corner(RSCR,8); listV(RSCR,6); pad(RSCR,8,8)

local EMPTY=L(RSCR,"No scripts scanned yet.\nPress Scan to search.",UDim2.new(1,0,0,100),nil,C.MUTED,FN,12)
EMPTY.TextXAlignment=Enum.TextXAlignment.Center; EMPTY.TextYAlignment=Enum.TextYAlignment.Center

local function makeCard(info,idx)
    local CARD=Instance.new("Frame")
    CARD.Size=UDim2.new(1,0,0,0); CARD.AutomaticSize=Enum.AutomaticSize.Y
    CARD.BackgroundColor3=C.CARD; CARD.BorderSizePixel=0
    CARD.LayoutOrder=idx; CARD.Parent=RSCR
    corner(CARD,7); stroke(CARD,C.BORDER,1); listV(CARD,0)

    local HDR=F(CARD,UDim2.new(1,0,0,30),nil,C.HDRROW)
    HDR.LayoutOrder=1; corner(HDR,7)
    F(HDR,UDim2.new(1,0,0,7),UDim2.new(0,0,1,-7),C.HDRROW)
    dot(HDR,UDim2.new(0,7,0,7),UDim2.new(0,9,0.5,-3),C.ACC)
    local NL=L(HDR,info.name,UDim2.new(1,-102,1,0),UDim2.new(0,22,0,0),C.ACC,FM,11)
    NL.TextTruncate=Enum.TextTruncate.AtEnd
    local PIL=F(HDR,UDim2.new(0,86,0,16),UDim2.new(1,-92,0.5,-8),Color3.fromRGB(20,28,52)); corner(PIL,4)
    local PT=L(PIL,info.source or "?",UDim2.new(1,-6,1,0),UDim2.new(0,3,0,0),C.MUTED,FM,9)
    PT.TextXAlignment=Enum.TextXAlignment.Center; PT.TextTruncate=Enum.TextTruncate.AtEnd

    local CR=Instance.new("Frame"); CR.Size=UDim2.new(1,0,0,0); CR.AutomaticSize=Enum.AutomaticSize.Y
    CR.BackgroundColor3=C.DEEP; CR.BorderSizePixel=0; CR.LayoutOrder=2; CR.Parent=CARD; pad(CR,6,10)
    local lines=info.code:split("\n"); local pl={}
    for i=1,math.min(8,#lines) do table.insert(pl,lines[i]) end
    if #lines>8 then table.insert(pl,"  ...("..(#lines-8).." more)") end
    local CT=Instance.new("TextLabel"); CT.Size=UDim2.new(1,0,0,0); CT.AutomaticSize=Enum.AutomaticSize.Y
    CT.BackgroundTransparency=1; CT.Text=table.concat(pl,"\n"); CT.TextColor3=C.CODE
    CT.Font=FM; CT.TextSize=9; CT.TextWrapped=true; CT.TextXAlignment=Enum.TextXAlignment.Left; CT.Parent=CR

    local BR=F(CARD,UDim2.new(1,0,0,32),nil,C.CARD); BR.LayoutOrder=3
    local CP=B(BR,"⧉ Copy",    UDim2.new(0.5,-5,0,24),UDim2.new(0,4,0,4),  C.INDIGO,C.TXT,10,FB); corner(CP,6)
    local EX=B(BR,"▶ Execute", UDim2.new(0.5,-5,0,24),UDim2.new(0.5,3,0,4),C.GRN,   C.TXT,10,FB); corner(EX,6)
    CP.MouseButton1Click:Connect(function()
        clipSet(info.code); flash(CP,C.GRN)
        CP.Text="✓ Copied!"; task.delay(1.5,function() CP.Text="⧉ Copy" end)
        notify("Scanner","Copied: "..info.name,2)
    end)
    EX.MouseButton1Click:Connect(function()
        flash(EX,C.AMBER); task.spawn(function() execScript(info.code) end)
    end)
end

local scanning=false
SCANBTN.MouseButton1Click:Connect(function()
    if scanning then return end; scanning=true
    for _,c in ipairs(RSCR:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    EMPTY.Visible=false; RCNT.Text=""
    setStatus("Scanning...",C.AMBER); tw(SCANBTN,{BackgroundColor3=Color3.fromRGB(38,58,102)}); SCANBTN.Text="Scanning..."
    task.spawn(function()
        local scripts={}
        if getScripts then pcall(function() scripts=getScripts() end) end
        if #scripts==0 then
            for _,v in ipairs(game:GetDescendants()) do
                if v:IsA("LocalScript") or v:IsA("ModuleScript") or v:IsA("Script") then table.insert(scripts,v) end
            end
        end
        local found={}
        for _,s in ipairs(scripts) do
            local src=""
            if doDecomp then pcall(function() src=doDecomp(s) end) end
            if src=="" then pcall(function() src=s.Source end) end
            if src and src~="" then for _,fn in ipairs(extractFns(src,s.Name)) do table.insert(found,fn) end end
        end
        if #found==0 then
            EMPTY.Visible=true; setStatus("0 results",C.RED); RCNT.Text="0"
        else
            RCNT.Text=#found.." found"
            for i,fn in ipairs(found) do if i>20 then break end; makeCard(fn,i); task.wait(0.02) end
            setStatus("Done — "..(#found).." functions",C.GRN)
        end
        tw(SCANBTN,{BackgroundColor3=C.ACC}); SCANBTN.Text="⬡  Scan Again"; scanning=false
    end)
end)

-- ── Tab switching ─────────────────────────────────────────────────────────────
local function showTab(t)
    AI_PAGE.Visible=(t=="ai"); UNC_PAGE.Visible=(t=="unc"); SCN_PAGE.Visible=(t=="scn")
    local function upTab(btn, active)
        tw(btn,{BackgroundColor3=active and C.ACC or C.CARD, TextColor3=active and C.TXT or C.SUB})
    end
    upTab(TAB_AI,  t=="ai")
    upTab(TAB_UNC, t=="unc")
    upTab(TAB_SCN, t=="scn")
end
TAB_AI.MouseButton1Click:Connect(function()  showTab("ai")  end)
TAB_UNC.MouseButton1Click:Connect(function() showTab("unc") end)
TAB_SCN.MouseButton1Click:Connect(function() showTab("scn") end)

-- ── Boot ──────────────────────────────────────────────────────────────────────
setStatus("Ready  ·  "..dev0.device.."  ·  "..dev0.executor, C.GRN)
addLog("Nexus AI loaded — "..dev0.device.." / "..dev0.executor, C.GRN)
addLog("Screen: "..dev0.width.."×"..dev0.height, C.SUB)
notify("Nexus AI","Loaded! AI tab: type any script request. UNC tab: test all functions.",4)
