--[[
╔══════════════════════════════════════════════════════════════╗
║              NEXUS AI — Delta Edition                        ║
║  Scan game → build real context → AI writes working script  ║
║  Powered by Pollinations AI  ·  Claude Opus 4.6             ║
╚══════════════════════════════════════════════════════════════╝

HOW IT WORKS
  1. Press Generate — the tool first scans the live game:
       • All RemoteEvents / RemoteFunctions (exact paths)
       • All UI elements in PlayerGui (real names)
       • All Workspace objects
       • Decompiled function names from every script
  2. That real game context is sent to Claude Opus 4.6 alongside
     your prompt — so the AI uses ACTUAL names, not invented ones.
  3. The generated script is shown in the code box.
  4. Press Copy or Execute (loadstring) — done.

SCANNER TAB
  Scans scripts for frame-drawing functions, each with Copy + Execute.
--]]

-- ── Services ──────────────────────────────────────────────────────────────────
local Players  = game:GetService("Players")
local RS       = game:GetService("ReplicatedStorage")
local UIS      = game:GetService("UserInputService")
local TS       = game:GetService("TweenService")
local SG       = game:GetService("StarterGui")
local HS       = game:GetService("HttpService")
local LP       = Players.LocalPlayer
local PGUI     = LP:WaitForChild("PlayerGui")

-- ── Executor APIs ─────────────────────────────────────────────────────────────
local httpReq    = (syn and syn.request) or (http and http.request) or request
local clipSet    = setclipboard or (syn and syn.set_clipboard) or (function() end)
local getScripts = getscripts or nil
local doDecomp   = decompile  or nil

-- ── Colors ────────────────────────────────────────────────────────────────────
local C = {
    BG     = Color3.fromRGB(13,  17,  30 ),
    SIDE   = Color3.fromRGB(8,   11,  20 ),
    PANEL  = Color3.fromRGB(22,  28,  46 ),
    EDIT   = Color3.fromRGB(12,  16,  28 ),
    DEEP   = Color3.fromRGB(7,   10,  20 ),
    HDRROW = Color3.fromRGB(16,  22,  42 ),
    ACC    = Color3.fromRGB(59,  130, 246),
    INDIGO = Color3.fromRGB(99,  102, 241),
    GRN    = Color3.fromRGB(34,  197, 94 ),
    RED    = Color3.fromRGB(220, 55,  55 ),
    AMBER  = Color3.fromRGB(245, 158, 11 ),
    TXT    = Color3.fromRGB(241, 245, 249),
    SUB    = Color3.fromRGB(148, 163, 184),
    MUTED  = Color3.fromRGB(71,  85,  105),
    BORDER = Color3.fromRGB(30,  42,  75 ),
    CODE   = Color3.fromRGB(160, 200, 240),
}
local FB = Enum.Font.GothamBold
local FN = Enum.Font.Gotham
local FM = Enum.Font.RobotoMono

-- ── Tween helpers ─────────────────────────────────────────────────────────────
local TF = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function tw(o, p)    TS:Create(o, TF, p):Play() end
local function flash(b, c)
    local orig = b.BackgroundColor3
    tw(b, {BackgroundColor3 = c})
    task.delay(0.22, function() tw(b, {BackgroundColor3 = orig}) end)
end

-- ── UI primitives ─────────────────────────────────────────────────────────────
local function corner(p, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = p; return c
end
local function stroke(p, col, th)
    local s = Instance.new("UIStroke"); s.Color = col or C.BORDER; s.Thickness = th or 1; s.Parent = p; return s
end
local function pad(p, v, h)
    local u = Instance.new("UIPadding")
    u.PaddingTop = UDim.new(0,v); u.PaddingBottom = UDim.new(0,v)
    u.PaddingLeft= UDim.new(0,h); u.PaddingRight  = UDim.new(0,h)
    u.Parent = p; return u
end
local function listV(p, sp)
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, sp or 4)
    l.HorizontalAlignment = Enum.HorizontalAlignment.Left
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = p; return l
end
local function F(par, sz, pos, col)
    local f = Instance.new("Frame"); f.Size = sz
    if pos then f.Position = pos end
    f.BackgroundColor3 = col or C.BG; f.BorderSizePixel = 0; f.Parent = par; return f
end
local function L(par, txt, sz, pos, col, fnt, ts, xa)
    local l = Instance.new("TextLabel"); l.Size = sz
    if pos then l.Position = pos end
    l.BackgroundTransparency = 1; l.Text = txt; l.TextColor3 = col or C.TXT
    l.Font = fnt or FN; l.TextSize = ts or 12; l.TextWrapped = true
    l.TextXAlignment = xa or Enum.TextXAlignment.Left; l.Parent = par; return l
end
local function B(par, txt, sz, pos, bg, tc, ts, fnt)
    local b = Instance.new("TextButton"); b.Size = sz
    if pos then b.Position = pos end
    b.BackgroundColor3 = bg or C.ACC; b.Text = txt; b.TextColor3 = tc or C.TXT
    b.Font = fnt or FB; b.TextSize = ts or 12; b.BorderSizePixel = 0; b.Parent = par; return b
end
local function dot(par, sz, pos, col)
    local d = F(par, sz, pos, col or C.MUTED); corner(d, 99); return d
end
local function notify(title, body, dur)
    pcall(function()
        SG:SetCore("SendNotification", {Title = title, Text = body, Duration = dur or 3})
    end)
end

-- ── loadstring executor ───────────────────────────────────────────────────────
local function execScript(code)
    if not code or code:gsub("%s","") == "" then notify("Execute","No script loaded.",2); return end
    local fn, err = loadstring(code)
    if not fn then notify("Syntax Error", tostring(err):sub(1,90), 5); return end
    local ok, runErr = pcall(fn)
    if not ok then notify("Runtime Error", tostring(runErr):sub(1,90), 5)
    else notify("Nexus AI","Script is running!",2) end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- GAME CONTEXT SCANNER
-- Walks the live game and builds a structured summary for the AI prompt.
-- ═══════════════════════════════════════════════════════════════════════════════
local function gatherContext(onProgress)
    local out = {}
    local function emit(s) table.insert(out, s) end

    -- ── Header ────────────────────────────────────────────────────────────────
    emit("=== GAME CONTEXT (EXACT paths only — do not invent names) ===")
    emit("PlaceId: " .. tostring(game.PlaceId))
    pcall(function()
        local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
        emit("Place Name: " .. (info and info.Name or "Unknown"))
    end)

    -- ── Available UNC / executor functions ────────────────────────────────────
    onProgress("Checking UNC / executor functions...")
    local UNC_CANDIDATES = {
        -- GC / metatable
        "getgc","getrawmetatable","setrawmetatable","setreadonly","isreadonly",
        -- Hooks
        "hookfunction","newcclosure","hookmetamethod","replaceclosure",
        -- Script env
        "getscripts","getrunningscripts","getsenv","getscriptenv","getscripthash",
        -- Decompile
        "decompile",
        -- Connections / signals
        "getconnections","firesignal","fireclickdetector","firetouchinterest",
        "fireproximityprompt",
        -- Remote helpers
        "getremotes",
        -- Environment
        "getfenv","setfenv","getrenv","getgenv",
        -- Debug
        "debug.info","debug.traceback","debug.getinfo","debug.profilebegin",
        -- UI / drawing
        "gethui","protect_gui","Drawing",
        -- Misc
        "isluau","setidentity","getidentity","request","syn.request",
        "setclipboard","loadstring","checkcaller","isourclosure",
        "clonefunction","getnamecallmethod",
    }
    local avail, unavail = {}, {}
    for _, fn in ipairs(UNC_CANDIDATES) do
        local ok = pcall(function()
            local parts = fn:split(".")
            local v = _G[parts[1]]
            if #parts == 2 then v = type(v)=="table" and v[parts[2]] or nil end
            assert(type(v) == "function" or type(v) == "table")
        end)
        if ok then table.insert(avail, fn) else table.insert(unavail, fn) end
    end
    emit("\nUNC FUNCTIONS AVAILABLE (" .. #avail .. "):")
    emit("  " .. table.concat(avail, ", "))
    emit("UNC FUNCTIONS NOT AVAILABLE (" .. #unavail .. "):")
    emit("  " .. table.concat(unavail, ", "))

    -- ── RemoteEvents / RemoteFunctions across all key services ────────────────
    onProgress("Scanning RemoteEvents across all services...")
    local remotes = {}
    local function walkRemotes(parent, path, depth)
        if depth > 7 or #remotes >= 100 then return end
        local ok, children = pcall(function() return parent:GetChildren() end)
        if not ok then return end
        for _, v in ipairs(children) do
            local p = path .. "." .. v.Name
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                table.insert(remotes, p .. " [" .. v.ClassName .. "]")
            elseif v:IsA("BindableEvent") or v:IsA("BindableFunction") then
                table.insert(remotes, p .. " [" .. v.ClassName .. " — bindable]")
            end
            if not v:IsA("BasePart") then
                walkRemotes(v, p, depth + 1)
            end
        end
    end
    local scanServices = {
        "ReplicatedStorage","ReplicatedFirst","ServerStorage",
        "Players","Lighting","SoundService",
    }
    for _, svcName in ipairs(scanServices) do
        pcall(function()
            walkRemotes(game:GetService(svcName), svcName, 1)
        end)
    end
    if #remotes > 0 then
        emit("\nREMOTES & BINDABLES:")
        for _, r in ipairs(remotes) do emit("  " .. r) end
    end

    -- ── Module dependency map ─────────────────────────────────────────────────
    onProgress("Mapping ModuleScript hierarchy...")
    local modules = {}
    pcall(function()
        for _, v in ipairs(game:GetDescendants()) do
            if v:IsA("ModuleScript") then
                table.insert(modules, v:GetFullName() .. " [ModuleScript]")
                if #modules >= 40 then break end
            end
        end
    end)
    if #modules > 0 then
        emit("\nMODULE SCRIPTS (require targets):")
        for _, m in ipairs(modules) do emit("  " .. m) end
    end

    -- ── Full UI hierarchy ─────────────────────────────────────────────────────
    onProgress("Scanning full UI hierarchy...")
    local uis = {}
    local GUI_TYPES = {
        ScreenGui=true, Frame=true, ScrollingFrame=true, TextButton=true,
        TextLabel=true, ImageLabel=true, ImageButton=true,
        BillboardGui=true, SurfaceGui=true, TextBox=true,
        ViewportFrame=true,
    }
    local function walkUI(parent, path, depth)
        if depth > 6 or #uis >= 80 then return end
        local ok, children = pcall(function() return parent:GetChildren() end)
        if not ok then return end
        for _, v in ipairs(children) do
            if v.Name ~= "NexusAI" then
                local p = path .. "." .. v.Name
                if GUI_TYPES[v.ClassName] then
                    table.insert(uis, p .. " [" .. v.ClassName .. "]")
                end
                walkUI(v, p, depth + 1)
            end
        end
    end
    pcall(walkUI, PGUI, "PlayerGui", 1)
    pcall(function()
        walkUI(game:GetService("CoreGui"), "CoreGui", 1)
    end)
    if #uis > 0 then
        emit("\nUI HIERARCHY (PlayerGui + CoreGui):")
        for _, u in ipairs(uis) do emit("  " .. u) end
    end

    -- ── Workspace hierarchy (full, with class) ────────────────────────────────
    onProgress("Scanning workspace hierarchy...")
    local ws = {}
    local function walkWS(parent, path, depth)
        if depth > 4 or #ws >= 80 then return end
        local ok, children = pcall(function() return parent:GetChildren() end)
        if not ok then return end
        for _, v in ipairs(children) do
            if not v:IsA("Terrain") and not v:IsA("Camera") then
                local p = path .. "." .. v.Name
                table.insert(ws, p .. " [" .. v.ClassName .. "]")
                if v:IsA("Model") or v:IsA("Folder") then
                    walkWS(v, p, depth + 1)
                end
            end
        end
    end
    pcall(walkWS, workspace, "workspace", 1)
    if #ws > 0 then
        emit("\nWORKSPACE HIERARCHY:")
        for _, w in ipairs(ws) do emit("  " .. w) end
    end

    -- ── Script inventory + decompiled function signatures ────────────────────
    onProgress("Decompiling scripts — tracing functions & events...")
    local scripts = {}
    if getScripts then pcall(function() scripts = getScripts() end) end
    if #scripts == 0 then
        pcall(function()
            for _, v in ipairs(game:GetDescendants()) do
                if v:IsA("LocalScript") or v:IsA("ModuleScript") or v:IsA("Script") then
                    table.insert(scripts, v)
                end
            end
        end)
    end

    local scrLines = {}
    local fnSeen   = {}
    for _, scr in ipairs(scripts) do
        local src = ""
        if doDecomp then pcall(function() src = doDecomp(scr) end) end
        if src == "" then pcall(function() src = scr.Source end) end
        if src and src ~= "" then
            local scrFull = pcall(function() return scr:GetFullName() end) and scr:GetFullName() or scr.Name
            local fns, fires, requires = {}, {}, {}
            -- function declarations
            for n in src:gmatch("function%s+([%w_%.]+)%s*%(") do
                local key = scrFull .. "::" .. n
                if not fnSeen[key] and #fns < 20 then fnSeen[key]=true; table.insert(fns, n.."()") end
            end
            -- :FireServer / :InvokeServer calls → reveals which remotes this script uses
            for call in src:gmatch(":([%w_]+)%(") do
                if call == "FireServer" or call == "InvokeServer"
                or call == "FireClient" or call == "InvokeClient"
                or call == "Fire" then
                    if not fires[call] then fires[call]=true end
                end
            end
            -- require() calls
            for req in src:gmatch("require%s*%((.-)%)") do
                table.insert(requires, req)
                if #requires >= 5 then break end
            end
            if #fns > 0 or next(fires) or #requires > 0 then
                local line = scrFull .. " ["..scr.ClassName.."]"
                if #fns > 0 then
                    line = line .. "\n    functions: " .. table.concat(fns, ", ")
                end
                if next(fires) then
                    local flist = {}
                    for k in pairs(fires) do table.insert(flist, k) end
                    line = line .. "\n    uses: " .. table.concat(flist, ", ")
                end
                if #requires > 0 then
                    line = line .. "\n    require(): " .. table.concat(requires, ", ")
                end
                table.insert(scrLines, line)
            end
        end
        if #scrLines >= 40 then break end
    end
    if #scrLines > 0 then
        emit("\nSCRIPT INVENTORY + FUNCTION MAP:")
        for _, s in ipairs(scrLines) do emit("  " .. s) end
    end

    emit("\n=== END CONTEXT ===")
    return table.concat(out, "\n")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- POLLINATIONS AI  —  context-aware script generation
-- ═══════════════════════════════════════════════════════════════════════════════
local SYS = [[You are an expert Roblox Lua architect for executor environments (Delta, Synapse, KRNL).
You will receive a GAME CONTEXT block containing the live game's full hierarchy: RemoteEvents, BindableEvents, ModuleScript paths, UI elements, workspace objects, script function maps, and which UNC/executor functions are available.

══ ANALYSIS PHASE (always first) ══
Before writing any code, produce a concise technical report inside a Lua block comment:
  --[[ ANALYSIS REPORT
    Game: <name>
    UI Structure: describe how PlayerGui is organized, which ScreenGuis exist, what menus are present
    Gameplay Systems: identify which RemoteEvents drive which mechanics, which LocalScripts own which features
    Event Flow: trace how client→server communication works (which scripts fire which remotes)
    Module Dependencies: list require() chains found
    Hooks Available: list which UNC functions from GAME CONTEXT you will use and WHY
    Missing Info: explicitly state anything that could not be determined from GAME CONTEXT
  ]]

══ IMPLEMENTATION RULES ══
1. Use ONLY paths and names from GAME CONTEXT — never invent instance paths.
2. Use all available UNC functions listed in GAME CONTEXT to maximise feature power:
     hookfunction() → intercept existing game functions without replacing them
     getconnections() → inspect/disconnect existing signal handlers
     firesignal() → trigger signals programmatically
     getgc() → locate hidden instances/tables the game doesn't expose publicly
     getrawmetatable() / setrawmetatable() / setreadonly() → bypass __index/__newindex locks
     hookmetamethod() → intercept __index/__newindex on game objects
     getsenv() / getscriptenv() → access another script's closed-over variables
     newcclosure() → wrap hooks so they appear as C closures to anti-cheat checks
3. Hook ALL relevant RemoteEvents found in GAME CONTEXT — connect listeners to log/modify traffic.
4. For bots and trackers: use Drawing API (Drawing.new("Square"/"Line"/"Circle"/"Text")).
     Update every frame via RunService.RenderStepped.
     Convert 3D to screen: Camera:WorldToViewportPoint(pos) → Vector2.
     Check visibility with Camera:WorldToViewportPoint returning onScreen bool.
5. Build ONE draggable ScreenGui.
     Title-bar drag works with both mouse (MouseMovement) and touch (Touch).
     Every feature has its own color-coded toggle: green = on, red = off.
     Group related toggles under section headers.
6. Integrate cleanly — check if an existing UI element from GAME CONTEXT is already present before creating a duplicate.
7. Add a one-line comment above every major block explaining WHY it exists.
8. Wrap every remote call and instance lookup in pcall.
9. Use task.spawn / task.wait only — no coroutine / wait.
10. Include all helper functions, utility tables, and config constants inline.

OUTPUT FORMAT — always this exact structure:
--[[ ANALYSIS REPORT
...
]]
<raw Lua code — no backticks, no markdown outside the analysis block>]]

local function aiGenerate(userPrompt, gameContext, onStatus)
    if not httpReq then return nil, "No HTTP function available in this executor." end

    local fullPrompt = gameContext .. "\n\n[USER REQUEST]\n" .. userPrompt

    local payload = HS:JSONEncode({
        messages = {
            {role = "system", content = SYS       },
            {role = "user",   content = fullPrompt },
        },
        model = "claude-opus-4-6",
        seed  = math.random(1, 99999),
    })

    onStatus("Sending to Claude Opus 4.6...")

    for _, model in ipairs({"claude-opus-4-6", "openai"}) do
        local body = (model == "claude-opus-4-6") and payload or HS:JSONEncode({
            messages = {
                {role = "system", content = SYS       },
                {role = "user",   content = fullPrompt },
            },
            model = model, seed = 42,
        })
        if model ~= "claude-opus-4-6" then onStatus("Retrying with fallback model...") end
        local ok, res = pcall(httpReq, {
            Url     = "https://text.pollinations.ai/",
            Method  = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body    = body,
        })
        if ok and res then
            local status = res.StatusCode or res.status or 0
            if status == 200 then
                local text = (res.Body or res.body or "")
                    :gsub("^```lua%s*",""):gsub("^```%s*",""):gsub("```%s*$","")
                    :gsub("^%s+",""):gsub("%s+$","")
                if #text > 20 then return text, nil end
            end
        end
    end
    return nil, "AI request failed — check internet connection."
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SCANNER  (frame-drawing function extractor)
-- ═══════════════════════════════════════════════════════════════════════════════
local FPATS = {
    'Instance%.new%s*%(%s*["\']Frame["\']',
    'Instance%.new%s*%(%s*["\']ScreenGui["\']',
    'Instance%.new%s*%(%s*["\']ScrollingFrame["\']',
    'Instance%.new%s*%(%s*["\']SurfaceGui["\']',
    'Instance%.new%s*%(%s*["\']BillboardGui["\']',
    'Instance%.new%s*%(%s*["\']ImageLabel["\']',
    'Drawing%.new%s*%(%s*["\']Square["\']',
    'Drawing%.new%s*%(%s*["\']Circle["\']',
    'Drawing%.new%s*%(%s*["\']Triangle["\']',
    'Drawing%.new%s*%(%s*["\']Line["\']',
    'DrawingAPI','drawFrame','drawRect','renderFrame',
    'CreateBox','BoxESP','drawESP','UICorner','UIStroke',
}
local function matchesFP(code)
    for _, p in ipairs(FPATS) do if code:find(p) then return true end end
    return false
end
local function extractFunctions(src, name)
    if not src or src == "" then return {} end
    local res, seen = {}, {}
    local function tryAdd(sig, n, body)
        if seen[n] then return end
        if matchesFP(body) then
            seen[n] = true
            table.insert(res, {name=n, code=sig.."\n"..body.."\nend", source=name})
        end
    end
    for s,n,b in src:gmatch("(local%s+function%s+(%w+)%b()%s*)\n(.-)\nend") do tryAdd(s,n,b) end
    for s,n,b in src:gmatch("(function%s+([%w_%.]+)%b()%s*)\n(.-)\nend")       do tryAdd(s,n,b) end
    return res
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- BUILD GUI
-- ═══════════════════════════════════════════════════════════════════════════════
if PGUI:FindFirstChild("NexusAI") then PGUI.NexusAI:Destroy() end

local GUI = Instance.new("ScreenGui")
GUI.Name = "NexusAI"; GUI.ResetOnSpawn = false
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GUI.DisplayOrder = 999; GUI.Parent = PGUI

local SHADOW = F(GUI, UDim2.new(0,510,0,652), UDim2.new(0.5,-255,0.5,-326), Color3.new(0,0,0))
SHADOW.BackgroundTransparency = 0.62; corner(SHADOW,16)

local WIN = F(GUI, UDim2.new(0,490,0,632), UDim2.new(0.5,-245,0.5,-316), C.BG)
corner(WIN,12); stroke(WIN,C.BORDER,1.5)

-- Title bar
local TBAR = F(WIN, UDim2.new(1,0,0,46), UDim2.new(0,0,0,0), C.SIDE)
corner(TBAR,12); F(TBAR, UDim2.new(1,0,0,12), UDim2.new(0,0,1,-12), C.SIDE)
local STRIPE = F(TBAR, UDim2.new(0,3,0,24), UDim2.new(0,14,0.5,-12), C.ACC); corner(STRIPE,2)
L(TBAR,"Nexus AI",    UDim2.new(0,220,0,20), UDim2.new(0,25,0,7),  C.TXT,  FB,14)
L(TBAR,"Delta  ·  Pollinations AI  ·  Claude Opus 4.6",
        UDim2.new(0,340,0,14), UDim2.new(0,25,0,27), C.MUTED,FN,9)

local CLOSE = B(TBAR,"✕",UDim2.new(0,26,0,26),UDim2.new(1,-36,0.5,-13),C.RED,C.TXT,11,FB)
corner(CLOSE,6)
CLOSE.MouseEnter:Connect(function()  tw(CLOSE,{BackgroundColor3=Color3.fromRGB(255,70,70)}) end)
CLOSE.MouseLeave:Connect(function()  tw(CLOSE,{BackgroundColor3=C.RED}) end)
CLOSE.MouseButton1Click:Connect(function() GUI:Destroy() end)

-- Drag
do
    local drag,dSt,wSt
    local function syncShadow()
        SHADOW.Position=UDim2.new(WIN.Position.X.Scale,WIN.Position.X.Offset-10,
                                   WIN.Position.Y.Scale,WIN.Position.Y.Offset-10)
    end
    TBAR.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            drag=true; dSt=i.Position; wSt=WIN.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if not drag then return end
        if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then
            local d=i.Position-dSt
            WIN.Position=UDim2.new(wSt.X.Scale,wSt.X.Offset+d.X,wSt.Y.Scale,wSt.Y.Offset+d.Y)
            syncShadow()
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end
    end)
    syncShadow()
end

-- Tab bar
local TABBAR = F(WIN,UDim2.new(1,-24,0,32),UDim2.new(0,12,0,54),C.PANEL); corner(TABBAR,8)
local TAB_AI  = B(TABBAR,"⬡  AI Generate",UDim2.new(0.5,-3,1,-8),UDim2.new(0,4,0,4),   C.ACC,  C.TXT,11,FB); corner(TAB_AI,6)
local TAB_SCN = B(TABBAR,"⬡  Scanner",    UDim2.new(0.5,-3,1,-8),UDim2.new(0.5,3,0,4), C.PANEL,C.SUB,11,FB); corner(TAB_SCN,6)

-- Status bar
local SBAR = F(WIN,UDim2.new(1,-24,0,26),UDim2.new(0,12,0,94),C.PANEL); corner(SBAR,6)
local SDOT  = dot(SBAR,UDim2.new(0,8,0,8),UDim2.new(0,8,0.5,-4),C.GRN)
local STXT  = L(SBAR,"Ready",UDim2.new(1,-28,1,0),UDim2.new(0,22,0,0),C.SUB,FN,10)
STXT.TextTruncate = Enum.TextTruncate.AtEnd
local function setStatus(msg, col) STXT.Text=msg; tw(SDOT,{BackgroundColor3=col or C.MUTED}) end

-- ═══════════════════════════════════════════════════════════════════════════════
-- AI GENERATE PAGE
-- ═══════════════════════════════════════════════════════════════════════════════
local AI_PAGE = F(WIN,UDim2.new(1,-24,1,-130),UDim2.new(0,12,0,128),C.BG)

-- Prompt box
local PFRAME = F(AI_PAGE,UDim2.new(1,0,0,96),UDim2.new(0,0,0,0),C.PANEL)
corner(PFRAME,8); stroke(PFRAME,C.BORDER)
L(PFRAME,"Describe the script you want — AI scans the game first, then writes it:",
  UDim2.new(1,-12,0,14),UDim2.new(0,10,0,6),C.SUB,FB,9)

local PIN = Instance.new("TextBox")
PIN.Size=UDim2.new(1,-16,0,64); PIN.Position=UDim2.new(0,8,0,22)
PIN.BackgroundColor3=C.EDIT; PIN.Text=""
PIN.PlaceholderText='e.g. "hook all remotes, add ESP drawing bot, all emotes, toggle UI for every feature, use all available UNC functions"'
PIN.PlaceholderColor3=C.MUTED; PIN.TextColor3=C.TXT
PIN.Font=FM; PIN.TextSize=10; PIN.MultiLine=true
PIN.ClearTextOnFocus=false; PIN.TextXAlignment=Enum.TextXAlignment.Left
PIN.TextYAlignment=Enum.TextYAlignment.Top; PIN.BorderSizePixel=0
PIN.Parent=PFRAME; corner(PIN,6); pad(PIN,5,8)

-- Generate button
local GENBTN = B(AI_PAGE,"⬡  Deep Scan + Analyse + Generate",UDim2.new(1,0,0,36),UDim2.new(0,0,0,102),C.ACC,C.TXT,13,FB)
corner(GENBTN,8)
GENBTN.MouseEnter:Connect(function() tw(GENBTN,{BackgroundColor3=Color3.fromRGB(80,152,255)}) end)
GENBTN.MouseLeave:Connect(function() tw(GENBTN,{BackgroundColor3=C.ACC}) end)
-- Reset button text after generation


-- Context summary strip
local CTXLBL = L(AI_PAGE,"Context: none yet",UDim2.new(1,0,0,14),UDim2.new(0,0,0,144),C.MUTED,FM,9)

-- Code output label row
local OUTLBL = L(AI_PAGE,"GENERATED SCRIPT",UDim2.new(0,160,0,12),UDim2.new(0,0,0,162),C.MUTED,FB,9)
local OUTCNT = L(AI_PAGE,"",                UDim2.new(1,0,0,12),  UDim2.new(0,0,0,162),C.MUTED,FN,9)
OUTCNT.TextXAlignment=Enum.TextXAlignment.Right

-- Scrollable code preview
local CSCR = Instance.new("ScrollingFrame")
CSCR.Size=UDim2.new(1,0,1,-218); CSCR.Position=UDim2.new(0,0,0,178)
CSCR.BackgroundColor3=C.DEEP; CSCR.BorderSizePixel=0
CSCR.ScrollBarThickness=3; CSCR.ScrollBarImageColor3=C.ACC
CSCR.AutomaticCanvasSize=Enum.AutomaticSize.Y
CSCR.CanvasSize=UDim2.new(0,0,0,0)
CSCR.Parent=AI_PAGE; corner(CSCR,8); pad(CSCR,8,10)

local CLBL = Instance.new("TextLabel")
CLBL.Size=UDim2.new(1,0,0,0); CLBL.AutomaticSize=Enum.AutomaticSize.Y
CLBL.BackgroundTransparency=1
CLBL.Text="← Type your request above, then press  ⬡ Scan Game + Generate"
CLBL.TextColor3=C.MUTED; CLBL.Font=FM; CLBL.TextSize=10
CLBL.TextWrapped=true; CLBL.TextXAlignment=Enum.TextXAlignment.Left
CLBL.Parent=CSCR

-- Copy + Execute buttons
local COPYBTN = B(AI_PAGE,"⧉  Copy Script",            UDim2.new(0.5,-3,0,32),UDim2.new(0,0,1,-34),  C.INDIGO,C.TXT,11,FB); corner(COPYBTN,8)
local EXECBTN = B(AI_PAGE,"▶  Execute via loadstring",  UDim2.new(0.5,-3,0,32),UDim2.new(0.5,3,1,-34),C.GRN,   C.TXT,11,FB); corner(EXECBTN,8)

COPYBTN.MouseEnter:Connect(function() tw(COPYBTN,{BackgroundColor3=Color3.fromRGB(118,122,255)}) end)
COPYBTN.MouseLeave:Connect(function() tw(COPYBTN,{BackgroundColor3=C.INDIGO}) end)
EXECBTN.MouseEnter:Connect(function() tw(EXECBTN,{BackgroundColor3=Color3.fromRGB(50,220,110)}) end)
EXECBTN.MouseLeave:Connect(function() tw(EXECBTN,{BackgroundColor3=C.GRN}) end)

local generatedCode = ""

COPYBTN.MouseButton1Click:Connect(function()
    if generatedCode=="" then notify("Nexus AI","Nothing generated yet.",2); return end
    clipSet(generatedCode); flash(COPYBTN,C.GRN)
    COPYBTN.Text="✓  Copied!"; task.delay(1.8,function() COPYBTN.Text="⧉  Copy Script" end)
    notify("Nexus AI","Script copied to clipboard!",2)
end)
EXECBTN.MouseButton1Click:Connect(function()
    if generatedCode=="" then notify("Nexus AI","Nothing generated yet.",2); return end
    flash(EXECBTN,C.AMBER); task.spawn(function() execScript(generatedCode) end)
end)

local generating = false
GENBTN.MouseButton1Click:Connect(function()
    if generating then return end
    local prompt = PIN.Text
    if not prompt or prompt:gsub("%s","")=="" then notify("Nexus AI","Enter a prompt first!",2); return end
    generating=true; generatedCode=""
    CLBL.Text="Scanning game..."; CLBL.TextColor3=C.AMBER
    OUTCNT.Text=""; CTXLBL.Text="Scanning..."
    setStatus("Phase 1 — scanning live game...",C.AMBER)
    tw(GENBTN,{BackgroundColor3=Color3.fromRGB(38,58,102)}); GENBTN.Text="Scanning game..."

    task.spawn(function()
        -- Phase 1: gather live game context
        local gameContext = gatherContext(function(msg)
            setStatus(msg, C.AMBER)
            CTXLBL.Text = msg
        end)

        local ctxLen = #gameContext
        CTXLBL.Text = "Context: " .. ctxLen .. " chars  ·  remotes + ui + ws + functions"
        setStatus("Phase 2 — generating with Claude Opus 4.6...", C.AMBER)
        GENBTN.Text = "Asking AI..."
        CLBL.Text = "Claude Opus 4.6 is writing your script..."
        CLBL.TextColor3 = C.AMBER

        -- Phase 2: AI generation with full context
        local code, err = aiGenerate(prompt, gameContext, function(msg)
            setStatus(msg, C.AMBER)
        end)

        if code and #code > 20 then
            generatedCode = code
            CLBL.Text = code; CLBL.TextColor3 = C.CODE
            OUTCNT.Text = #code .. " chars"
            setStatus("Done — " .. #code .. " chars  ·  Copy or Execute below", C.GRN)
            notify("Nexus AI","Script ready! Press Copy or Execute.",3)
        else
            CLBL.Text = "Generation failed:\n" .. (err or "unknown error")
            CLBL.TextColor3 = C.RED
            setStatus("Generation failed",C.RED)
            notify("Nexus AI", err or "AI request failed.",4)
        end

        tw(GENBTN,{BackgroundColor3=C.ACC})
        GENBTN.Text="⬡  Deep Scan + Analyse + Generate"
        generating=false
    end)
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- SCANNER PAGE
-- ═══════════════════════════════════════════════════════════════════════════════
local SCN_PAGE = F(WIN,UDim2.new(1,-24,1,-130),UDim2.new(0,12,0,128),C.BG)
SCN_PAGE.Visible=false

local SCANBTN = B(SCN_PAGE,"⬡  Scan Game for Frame Functions",UDim2.new(1,0,0,36),UDim2.new(0,0,0,0),C.ACC,C.TXT,13,FB)
corner(SCANBTN,8)
SCANBTN.MouseEnter:Connect(function() tw(SCANBTN,{BackgroundColor3=Color3.fromRGB(80,152,255)}) end)
SCANBTN.MouseLeave:Connect(function() tw(SCANBTN,{BackgroundColor3=C.ACC}) end)

local RLBL = L(SCN_PAGE,"RESULTS",UDim2.new(0,80,0,12),UDim2.new(0,0,0,44),C.MUTED,FB,9)
local RCNT = L(SCN_PAGE,"",       UDim2.new(1,0,0,12), UDim2.new(0,0,0,44),C.SUB,  FN,9)
RCNT.TextXAlignment=Enum.TextXAlignment.Right

local RSCR = Instance.new("ScrollingFrame")
RSCR.Size=UDim2.new(1,0,1,-60); RSCR.Position=UDim2.new(0,0,0,58)
RSCR.BackgroundColor3=C.PANEL; RSCR.BorderSizePixel=0
RSCR.ScrollBarThickness=3; RSCR.ScrollBarImageColor3=C.ACC
RSCR.AutomaticCanvasSize=Enum.AutomaticSize.Y; RSCR.CanvasSize=UDim2.new(0,0,0,0)
RSCR.Parent=SCN_PAGE; corner(RSCR,8); listV(RSCR,6); pad(RSCR,8,8)

local EMPTY=L(RSCR,"No scripts scanned yet.\nPress Scan to search for frame-drawing functions.",
    UDim2.new(1,0,0,110),nil,C.MUTED,FN,12)
EMPTY.TextXAlignment=Enum.TextXAlignment.Center
EMPTY.TextYAlignment=Enum.TextYAlignment.Center

local function makeCard(info, idx)
    local CARD=Instance.new("Frame")
    CARD.Size=UDim2.new(1,0,0,0); CARD.AutomaticSize=Enum.AutomaticSize.Y
    CARD.BackgroundColor3=C.EDIT; CARD.BorderSizePixel=0
    CARD.LayoutOrder=idx; CARD.Parent=RSCR
    corner(CARD,7); stroke(CARD,C.BORDER,1); listV(CARD,0)

    local HDR=F(CARD,UDim2.new(1,0,0,32),nil,C.HDRROW)
    HDR.LayoutOrder=1; corner(HDR,7)
    F(HDR,UDim2.new(1,0,0,7),UDim2.new(0,0,1,-7),C.HDRROW)
    dot(HDR,UDim2.new(0,7,0,7),UDim2.new(0,9,0.5,-3),C.ACC)
    local NL=L(HDR,info.name,UDim2.new(1,-104,1,0),UDim2.new(0,22,0,0),C.ACC,FM,11)
    NL.TextTruncate=Enum.TextTruncate.AtEnd
    local PIL=F(HDR,UDim2.new(0,88,0,17),UDim2.new(1,-94,0.5,-8),Color3.fromRGB(22,32,58)); corner(PIL,4)
    local PT=L(PIL,info.source or "?",UDim2.new(1,-6,1,0),UDim2.new(0,3,0,0),C.MUTED,FM,9)
    PT.TextXAlignment=Enum.TextXAlignment.Center; PT.TextTruncate=Enum.TextTruncate.AtEnd

    local CR=Instance.new("Frame"); CR.Size=UDim2.new(1,0,0,0); CR.AutomaticSize=Enum.AutomaticSize.Y
    CR.BackgroundColor3=C.DEEP; CR.BorderSizePixel=0; CR.LayoutOrder=2; CR.Parent=CARD; pad(CR,6,10)
    local lines=info.code:split("\n"); local pl={}
    for i=1,math.min(8,#lines) do table.insert(pl,lines[i]) end
    if #lines>8 then table.insert(pl,"  ...("..(#lines-8).." more lines)") end
    local CT=Instance.new("TextLabel"); CT.Size=UDim2.new(1,0,0,0); CT.AutomaticSize=Enum.AutomaticSize.Y
    CT.BackgroundTransparency=1; CT.Text=table.concat(pl,"\n"); CT.TextColor3=C.CODE
    CT.Font=FM; CT.TextSize=9; CT.TextWrapped=true; CT.TextXAlignment=Enum.TextXAlignment.Left; CT.Parent=CR

    local BR=F(CARD,UDim2.new(1,0,0,34),nil,C.EDIT); BR.LayoutOrder=3
    local CP=B(BR,"⧉ Copy",    UDim2.new(0.5,-5,0,26),UDim2.new(0,4,0,4),  C.INDIGO,C.TXT,10,FB); corner(CP,6)
    local EX=B(BR,"▶ Execute", UDim2.new(0.5,-5,0,26),UDim2.new(0.5,3,0,4),C.GRN,   C.TXT,10,FB); corner(EX,6)
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
    setStatus("Collecting scripts...",C.AMBER)
    tw(SCANBTN,{BackgroundColor3=Color3.fromRGB(38,58,102)}); SCANBTN.Text="Scanning..."
    task.spawn(function()
        local scripts={}
        if getScripts then pcall(function() scripts=getScripts() end) end
        if #scripts==0 then
            for _,v in ipairs(game:GetDescendants()) do
                if v:IsA("LocalScript") or v:IsA("ModuleScript") or v:IsA("Script") then table.insert(scripts,v) end
            end
        end
        setStatus("Found "..#scripts.." scripts — extracting...",C.AMBER)
        local found={}
        for _,scr in ipairs(scripts) do
            local src=""
            if doDecomp then pcall(function() src=doDecomp(scr) end) end
            if src=="" then pcall(function() src=scr.Source end) end
            if src and src~="" then
                for _,fn in ipairs(extractFunctions(src,scr.Name)) do table.insert(found,fn) end
            end
        end
        if #found==0 then
            EMPTY.Visible=true; EMPTY.Text="No frame-drawing functions found."
            setStatus("0 results",C.RED); RCNT.Text="0 found"
        else
            RCNT.Text=#found.." found"
            for i,fn in ipairs(found) do
                if i>20 then break end; makeCard(fn,i); task.wait(0.03)
            end
            setStatus("Done — "..(#found).." frame functions found",C.GRN)
        end
        tw(SCANBTN,{BackgroundColor3=C.ACC}); SCANBTN.Text="⬡  Scan Again"; scanning=false
    end)
end)

-- ── Tab switching ─────────────────────────────────────────────────────────────
local function showTab(t)
    if t=="ai" then
        AI_PAGE.Visible=true;  SCN_PAGE.Visible=false
        tw(TAB_AI, {BackgroundColor3=C.ACC,   TextColor3=C.TXT})
        tw(TAB_SCN,{BackgroundColor3=C.PANEL, TextColor3=C.SUB})
    else
        AI_PAGE.Visible=false; SCN_PAGE.Visible=true
        tw(TAB_SCN,{BackgroundColor3=C.ACC,   TextColor3=C.TXT})
        tw(TAB_AI, {BackgroundColor3=C.PANEL, TextColor3=C.SUB})
    end
end
TAB_AI.MouseButton1Click:Connect(function()  showTab("ai")      end)
TAB_SCN.MouseButton1Click:Connect(function() showTab("scanner") end)

-- Boot
setStatus("Ready — type a prompt and press  ⬡ Scan Game + Generate", C.GRN)
notify("Nexus AI","Loaded! Describe what you want and hit Generate — AI scans the game first.",4)
