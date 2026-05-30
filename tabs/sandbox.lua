-- TAB: Sandbox Bypass  (standard executor sandbox-escape primitives)
local SS = _G._SS
local C,tw,corner,stroke,pad,listH,listV=SS.C,SS.tw,SS.corner,SS.stroke,SS.pad,SS.listH,SS.listV
local F,L,B,IN,OUT,SCR,hov=SS.F,SS.L,SS.B,SS.IN,SS.OUT,SS.SCR,SS.hov

local P = SS.registerTab("⛓", "Sandbox")

L(P,"SANDBOX BYPASS",UDim2.new(1,0,0,16),nil,C.TXTS,SS.FB,11)

-- ── Console ───────────────────────────────────────────────
local CONS = OUT(P,UDim2.new(1,0,0,118),UDim2.new(0,0,1,-118))
local function log(msg,col) CONS.TextColor3=col or C.GREEN; CONS.Text=tostring(msg) end

-- ── Toggle list of bypass utilities ───────────────────────
local LIST = SCR(P,UDim2.new(1,0,1,-160),UDim2.new(0,0,0,20))
listV(LIST,5)

-- Helper: build a row with a label + action button
local function utilRow(title, desc, btnText, btnCol, action)
    local Row = F(LIST,UDim2.new(1,-6,0,52),nil,C.PANEL)
    corner(Row,7); stroke(Row,Color3.fromRGB(35,35,52),1)

    L(Row,title,UDim2.new(1,-110,0,18),UDim2.new(0,10,0,6),C.TXT,SS.FB,13)
    L(Row,desc, UDim2.new(1,-110,0,16),UDim2.new(0,10,0,26),C.TXTS,SS.FN,11)

    local btn = B(Row,btnText,UDim2.new(0,90,0,28),UDim2.new(1,-100,0.5,-14),btnCol or C.ACC)
    hov(btn, btnCol or C.ACC,
        Color3.fromRGB(
            math.min(255,(btnCol or C.ACC).R*255+25),
            math.min(255,(btnCol or C.ACC).G*255+25),
            math.min(255,(btnCol or C.ACC).B*255+25)))
    btn.MouseButton1Click:Connect(function()
        local ok, res = pcall(action)
        log(res or (ok and "✓ Done." or "✗ Failed."), ok and C.GREEN or C.RED)
    end)
    return Row
end

-- ── 1. Elevate thread identity ────────────────────────────
utilRow(
    "Elevate Thread Identity",
    "setthreadidentity(8) — gain max script context level",
    "Elevate", C.ACC,
    function()
        local fn = setthreadidentity or set_thread_identity or syn and syn.set_thread_identity
        if not fn then return "✗ setthreadidentity not supported." end
        fn(8)
        local getid = getthreadidentity or get_thread_identity
        return "✓ Identity set to 8" .. (getid and (" (now "..tostring(getid())..")") or "")
    end
)

-- ── 2. Disable readonly on a table ────────────────────────
utilRow(
    "Strip Read-Only (game env)",
    "setreadonly(getrawmetatable(game), false)",
    "Unlock", C.BLUE,
    function()
        local grm = getrawmetatable
        local sro = setreadonly or make_writeable
        if not grm or not sro then return "✗ getrawmetatable/setreadonly missing." end
        local mt = grm(game)
        sro(mt, false)
        return "✓ game metatable is now writable."
    end
)

-- ── 3. Access global executor env ─────────────────────────
utilRow(
    "Open Global Env (getgenv)",
    "exposes the shared executor environment",
    "Open", C.GREEN,
    function()
        local gg = getgenv
        if not gg then return "✗ getgenv not supported." end
        local env = gg()
        local n=0; for _ in pairs(env) do n+=1 end
        return "✓ getgenv() ok — "..n.." global entries."
    end
)

-- ── 4. Restore real environment (getrenv) ─────────────────
utilRow(
    "Open Roblox Env (getrenv)",
    "access the untouched game environment",
    "Open", C.ORANGE,
    function()
        local gr = getrenv
        if not gr then return "✗ getrenv not supported." end
        local env = gr()
        return "✓ getrenv() ok — game global accessible."
    end
)

-- ── 5. Hook __namecall to inspect remote traffic ──────────
utilRow(
    "Hook __namecall (metamethod)",
    "hookmetamethod(game,'__namecall',...) — log remote calls",
    "Hook", C.PURPLE,
    function()
        local hmm = hookmetamethod
        local gnm = getnamecallmethod
        if not hmm or not gnm then return "✗ hookmetamethod/getnamecallmethod missing." end
        local logged = 0
        local old
        old = hmm(game, "__namecall", function(self, ...)
            local method = gnm()
            if (method=="FireServer" or method=="InvokeServer") then
                logged += 1
                warn("[SS namecall] "..tostring(self).." :"..method)
            end
            return old(self, ...)
        end)
        return "✓ __namecall hooked — FireServer/InvokeServer now logged to console."
    end
)

-- ── 6. Bypass a custom anti-cheat metatable lock ──────────
utilRow(
    "Bypass Metatable Lock",
    "setrawmetatable + setreadonly false on a target",
    "Bypass", C.RED,
    function()
        local grm = getrawmetatable
        local sro = setreadonly
        if not grm or not sro then return "✗ Required functions missing." end
        local mt = grm(game)
        local ok = pcall(function() sro(mt, false) end)
        return ok and "✓ Metatable lock bypassed." or "✗ Could not unlock."
    end
)

-- ── 7. Custom sandbox-escape snippet runner ───────────────
local SNIP = F(LIST,UDim2.new(1,-6,0,116),nil,C.PANEL)
corner(SNIP,7); stroke(SNIP,Color3.fromRGB(35,35,52),1)
L(SNIP,"Custom Bypass Snippet",UDim2.new(1,-16,0,18),UDim2.new(0,10,0,6),C.TXT,SS.FB,13)

local SNIP_BOX = Instance.new("TextBox")
SNIP_BOX.Size=UDim2.new(1,-20,0,52);SNIP_BOX.Position=UDim2.new(0,10,0,26)
SNIP_BOX.BackgroundColor3=C.EDITOR;SNIP_BOX.BorderSizePixel=0
SNIP_BOX.Text="";SNIP_BOX.PlaceholderText="-- e.g. setreadonly(getrawmetatable(game),false)"
SNIP_BOX.TextColor3=C.TXT;SNIP_BOX.PlaceholderColor3=C.TXTS;SNIP_BOX.Font=SS.FC;SNIP_BOX.TextSize=12
SNIP_BOX.TextXAlignment=Enum.TextXAlignment.Left;SNIP_BOX.TextYAlignment=Enum.TextYAlignment.Top
SNIP_BOX.ClearTextOnFocus=false;SNIP_BOX.MultiLine=true;SNIP_BOX.TextWrapped=true
SNIP_BOX.ClipsDescendants=true;SNIP_BOX.Parent=SNIP
corner(SNIP_BOX,6);stroke(SNIP_BOX,C.BORDER,1);pad(SNIP_BOX,6,8)

local SNIP_RUN = B(SNIP,"Run Bypass",UDim2.new(0,100,0,24),UDim2.new(1,-110,0,82),C.ACC)
hov(SNIP_RUN,C.ACC,C.ACCHV)
SNIP_RUN.MouseButton1Click:Connect(function()
    local code=SNIP_BOX.Text
    if code=="" then log("Enter a snippet.",C.YELLOW); return end
    local fn,ce=loadstring(code)
    if not fn then log("Compile error:\n"..tostring(ce),C.RED); return end
    local ok,re=pcall(fn)
    log(ok and "✓ Bypass snippet ran OK." or "✗ "..tostring(re), ok and C.GREEN or C.RED)
end)

-- ── Capability check at top ───────────────────────────────
task.spawn(function()
    local caps = {
        {"getrawmetatable", getrawmetatable},
        {"setreadonly",     setreadonly},
        {"hookmetamethod",  hookmetamethod},
        {"setthreadidentity", setthreadidentity},
        {"getgenv",         getgenv},
        {"getrenv",         getrenv},
    }
    local have, miss = {}, {}
    for _, c in caps do
        if c[2] then have[#have+1]=c[1] else miss[#miss+1]=c[1] end
    end
    log(("Bypass capabilities: %d/%d available.\nHave: %s\nMissing: %s")
        :format(#have, #caps, table.concat(have,", "),
                #miss>0 and table.concat(miss,", ") or "none"),
        #miss==0 and C.GREEN or C.YELLOW)
end)
