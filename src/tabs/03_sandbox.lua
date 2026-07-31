-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB 3 — SANDBOX BYPASS
--  Bypass tools · Identity elevation · Metatable unlock · Hook spy
-- ═══════════════════════════════════════════════════════════════════════════════
local P3 = newTab("⛓", "Sandbox")
L(P3, "SANDBOX & BYPASS TOOLS", UDim2.new(1,0,0,16), UDim2.new(0,0,0,0), C.TXTS, FB, 11)

local sbOut = statusOut(P3, UDim2.new(1,0,0,44), UDim2.new(0,0,1,-46))

local SBScr = SCR(P3, UDim2.new(1,0,1,-104), UDim2.new(0,0,0,20))
listV(SBScr, 4)

local function uRow(title, desc, btnTxt, btnCol, action)
    local Row = card(SBScr, title, desc, 54)
    stroke(Row, Color3.fromRGB(30,40,70), 1)
    local bc = btnCol or C.ACC
    local hc = Color3.fromRGB(
        math.min(255, bc.R*255+30), math.min(255, bc.G*255+30), math.min(255, bc.B*255+30))
    local btn = B(Row, btnTxt, UDim2.new(0,90,0,26), UDim2.new(1,-98,0.5,-13), bc)
    btn.TextSize = 11; hov(btn, bc, hc)
    btn.MouseButton1Click:Connect(function()
        local ok2, res = pcall(action)
        sbOut(res or (ok2 and "✓ Done." or "✗ Failed."), ok2)
    end)
end

-- ── 12 bypass tools ───────────────────────────────────────────────────────────
uRow("Elevate Thread Identity (8)",
    "setthreadidentity(8) — max executor script context", "Elevate", C.ACC,
    function()
        local fn = setthreadidentity or (syn and syn.set_thread_identity)
        if not fn then return "✗ setthreadidentity not available." end
        fn(8)
        local gid = getthreadidentity or (syn and syn.get_thread_identity)
        return "✓ Identity → 8" .. (gid and " (confirmed: " .. gid() .. ")" or "")
    end)

uRow("Unlock game metatable",
    "setreadonly(getrawmetatable(game), false)", "Unlock", C.BLUE,
    function()
        if not getrawmetatable then return "✗ getrawmetatable missing." end
        if not setreadonly     then return "✗ setreadonly missing." end
        setreadonly(getrawmetatable(game), false)
        return "✓ game metatable is now writable."
    end)

uRow("Hook __namecall (Remote Spy lite)",
    "Logs all FireServer/InvokeServer calls to console", "Hook", C.ORAN,
    function()
        if not hookmetamethod    then return "✗ hookmetamethod missing." end
        if not getnamecallmethod then return "✗ getnamecallmethod missing." end
        local _old; _old = hookmetamethod(game, "__namecall", function(self, ...)
            local m = getnamecallmethod()
            if m == "FireServer" or m == "InvokeServer" then
                warn(("[Nexus Spy] %s → %s"):format(tostring(self), m))
            end
            return _old(self, ...)
        end)
        return "✓ __namecall hooked. All remotes now logged to console."
    end)

uRow("getgenv() inspector",
    "Count + list all shared executor globals", "Open", C.GRN,
    function()
        if not getgenv then return "✗ getgenv not available." end
        local env = getgenv(); local n = 0
        for _ in pairs(env) do n += 1 end
        return "✓ getgenv() → " .. n .. " entries in executor env."
    end)

uRow("getrenv() inspector",
    "Access real Roblox game environment table", "Open", C.PURP,
    function()
        if not getrenv then return "✗ getrenv not available." end
        local env = getrenv(); local n = 0
        for _ in pairs(env) do n += 1 end
        return "✓ getrenv() → " .. n .. " entries in Roblox env."
    end)

uRow("Bypass metatable lock",
    "Strips __index / __newindex guards from game", "Bypass", C.RED,
    function()
        if not getrawmetatable or not setreadonly then return "✗ Missing functions." end
        setreadonly(getrawmetatable(game), false)
        return "✓ Metatable lock stripped from game."
    end)

uRow("Expose _G (setreadonly false)",
    "Makes global table fully writable for hooking", "Expose", C.YELL,
    function()
        if not setreadonly then return "✗ setreadonly not available." end
        setreadonly(_G, false)
        return "✓ _G is now writable."
    end)

uRow("getconnections() probe",
    "Count event connections on Players.PlayerAdded", "Probe", C.TEAL,
    function()
        if not getconnections then return "✗ getconnections not available." end
        local conns = getconnections(Players.PlayerAdded)
        return "✓ PlayerAdded has " .. #conns .. " active connections."
    end)

uRow("newcclosure wrapper test",
    "Wraps a function in a new C-closure", "Test", C.INDI,
    function()
        if not newcclosure then return "✗ newcclosure not available." end
        local fn = newcclosure(function() return true end)
        local ok2 = pcall(fn)
        return ok2 and "✓ newcclosure() works correctly." or "✗ newcclosure returned error."
    end)

uRow("iscclosure / islclosure probe",
    "Determine closure types for common functions", "Probe", C.CYAN,
    function()
        local results = {}
        if iscclosure then
            results[#results+1] = "print is " .. (iscclosure(print) and "C" or "Lua") .. " closure"
        else results[#results+1] = "iscclosure unavailable" end
        if islclosure then
            local fn = function() end
            results[#results+1] = "local fn is " .. (islclosure(fn) and "Lua" or "C") .. " closure"
        else results[#results+1] = "islclosure unavailable" end
        return "✓ " .. table.concat(results, " | ")
    end)

uRow("hookfunction test",
    "Hooks print() to log [HOOKED] prefix to output", "Hook", C.PINK,
    function()
        if not hookfunction and not replaceclosure then return "✗ hookfunction not available." end
        local fn = hookfunction or replaceclosure
        local _old2; _old2 = fn(print, function(...)
            _old2("[Nexus Hook] " .. table.concat({...}, " "))
        end)
        return "✓ print() hooked — calls now prefixed with [Nexus Hook]."
    end)

uRow("setrawmetatable test",
    "Directly set metatable bypassing __metatable guard", "Test", C.ORAN,
    function()
        if not setrawmetatable then return "✗ setrawmetatable not available." end
        local t = setmetatable({}, {__metatable="locked"})
        local ok2 = pcall(setrawmetatable, t, {})
        return ok2 and "✓ setrawmetatable bypassed __metatable lock." or "✗ setrawmetatable failed."
    end)

-- ── Custom snippet area ───────────────────────────────────────────────────────
L(P3, "Custom Snippet:", UDim2.new(0,120,0,14), UDim2.new(0,0,1,-90), C.TXTS, FN, 11)
local SnipBox = IN(P3, "-- Custom bypass snippet…", UDim2.new(1,0,0,42), UDim2.new(0,0,1,-76))
local BSnip = B(P3, "▶ Run", UDim2.new(0,80,0,22), UDim2.new(0,0,1,-28), C.ACC)
BSnip.TextSize = 11; hov(BSnip, C.ACC, C.ACCHV)
BSnip.MouseButton1Click:Connect(function()
    local code = SnipBox.Text
    if trim(code) == "" then sbOut("No snippet entered.", false); return end
    local ok2, err, stage = runCode(code)
    if not ok2 then
        sbOut(stage=="compile" and ("Compile error:\n"..err) or ("✗ "..err), false); return
    end
    sbOut("✓ Snippet executed OK.", true)
end)

-- ── Auto-detect available bypass functions ────────────────────────────────────
task.spawn(function()
    local check = {
        "setthreadidentity","getthreadidentity","setreadonly","getrawmetatable",
        "hookmetamethod","hookfunction","getgenv","getrenv","getnamecallmethod",
        "getconnections","newcclosure","iscclosure","islclosure","setrawmetatable",
    }
    local have, miss = {}, {}
    for _, name in check do
        if hasGlobal(name) then
            have[#have+1] = name
        else
            miss[#miss+1] = name
        end
    end
    sbOut(("%d/%d bypass fns available.\nHave: %s%s"):format(
        #have, #check,
        table.concat(have, ", "),
        #miss > 0 and ("\nMissing: " .. table.concat(miss, ", ")) or ""
    ), #miss == 0)
end)
