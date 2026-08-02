-- ============================================================
--  MegaDumper.lua  –  All-in-one: decompile + remotes + clean up
--
--  One run does the whole automatable pipeline, live, in memory:
--
--    1. REMOTES  – every remote in the game + a call snippet.
--    2. DECOMPILE – source of every client-reachable script
--                   (decompile -> getscriptsource -> .Source -> bytecode).
--    3. CLEAN UP  – for each script, classify and BEAUTIFY what's
--                   readable:
--                     clean       -> re-indented, de-noised Lua
--                     vm          -> Luraph-style VM blob (flagged, kept
--                                    as-is; cannot be devirtualised by a
--                                    text pass)
--                     unavailable -> protected / empty
--    4. COPY      – the ENTIRE combined report to your clipboard (with a
--                   chunked fallback), plus per-script files + a manifest.
--
--  Honest scope: it decompiles and cleans everything it CAN, and clearly
--  marks the VM blobs it can't. It does not devirtualise Luraph (that is
--  a per-sample lifter, not a bulk button) and never pretends to.
--
--  Use it to back up / study your OWN games.
-- ============================================================

local StarterGui = game:GetService("StarterGui")

-- ── Config ────────────────────────────────────────────────
local CONFIG = {
    OutputFolder   = "MegaDump",
    IncludeBindables = true,
    IncludeNil     = true,
    UseGetScripts  = true,

    -- Scope: nil = whole game. Set a list of service names to scan ONLY
    -- those (far fewer scripts; survivable on low-RAM devices like iPad):
    --   getgenv().MegaDumper_Config = { Scope = {"ReplicatedStorage"} }
    Scope          = nil,

    -- Important = true: keep ALL remotes, but only dump the code that
    -- actually matters (shared modules, client logic, anti-cheat, network,
    -- data) and drop the useless noise (character Animate/emote scripts,
    -- default health/sound, cutscene rigs & asset previews). Auto-scopes to
    -- the client + shared services, so it's also much lighter on an iPad.
    Important      = false,
    ImportantScope = { "ReplicatedStorage", "ReplicatedFirst",
                       "StarterPlayer", "StarterGui", "StarterPack", "Lighting" },
    -- Case-insensitive path substrings that mark a script as useless noise.
    UselessPatterns = {
        "%.animate", "playemote", "emotes?%.", "%.health$",
        "cutscene", "%.rigs?%.", "assets%.", "preview",
        "defaultsound", "%.sound$", "animsaves", "animatecontroller",
    },

    -- Master switch. Set to false (or run in NoDecompile mode below) on
    -- games whose decompiler crashes the client (e.g. TSB): we then NEVER
    -- call decompile() and only dump raw bytecode/source, which cannot
    -- trigger the native decompiler crash.
    Decompile      = true,

    Reindent       = true,     -- beautify the clean scripts
    IndentStr      = "    ",
    MaxBlankRun    = 1,
    BytecodeAsHex  = true,
    MaxDecompiles  = 4000,     -- hard cap on scripts decompiled per run
    SavePerScript  = true,     -- the COMPLETE output (streamed to disk)
    CopyClipboard  = true,     -- copy the combined report (capped, see below)
    ChunkSize      = 180000,

    -- ── Anti-crash (these keep big games from OOM-killing the client) ──
    -- The combined in-memory report is CAPPED. Per-script files always hold
    -- everything; the combined blob is only for clipboard convenience and
    -- stops growing past this many bytes so we never balloon memory.
    CombinedCap    = 6000000,  -- ~6 MB clipboard/combined cap
    YieldEvery     = 3,        -- task.wait() after this many decompiles
    TimeBudget     = 0.008,    -- ...and yield if a step ran longer than this (s)
    MaxBeautify    = 150000,   -- skip re-indent on bodies bigger than this

    -- ── Crash-proofing (heavy/protected scripts crash decompilers) ──
    -- SafeDecompile size-gates the decompiler: scripts whose bytecode is
    -- bigger than this are NOT decompiled (that's what kills the client on
    -- TSB-style protected games) - we dump their raw bytecode hex instead.
    SafeDecompile  = true,
    MaxDecompileBC = 200000,   -- bytecode bytes above which we skip decompile
    -- Resume makes it self-healing: it records each script before touching
    -- it, so if a NATIVE decompiler crash still kills the client, re-running
    -- skips the offender and every script already done, and finishes.
    Resume         = true,

    IgnoreRoots    = { "CoreGui", "CorePackages", "RobloxGui", "RobloxReplicatedStorage", "CoreScripts" },
}
-- ──────────────────────────────────────────────────────────

local getgenv_fn      = getgenv or function() return _G end
-- Let users override any CONFIG value WITHOUT editing the file, e.g.:
--   getgenv().MegaDumper_Config = { Decompile = false }   -- TSB-safe mode
--   loadstring(game:HttpGet(".../MegaDumper.lua"))()
do
    local ov = rawget(getgenv_fn(), "MegaDumper_Config")
    if type(ov) == "table" then for k, v in pairs(ov) do CONFIG[k] = v end end
end
local ENV             = getgenv_fn()
local getscripts_fn   = rawget(ENV, "getscripts")        or getscripts
local getnil_fn       = rawget(ENV, "getnilinstances")   or getnilinstances
local decompile_fn    = rawget(ENV, "decompile")         or decompile
local getsource_fn    = rawget(ENV, "getscriptsource")   or getscriptsource or getscriptsrc
local getbytecode_fn  = rawget(ENV, "getscriptbytecode") or getscriptbytecode or dumpstring
local setclipboard_fn = rawget(ENV, "setclipboard")      or setclipboard or toclipboard or set_clipboard
local writefile_fn    = rawget(ENV, "writefile")         or writefile
local makefolder_fn   = rawget(ENV, "makefolder")        or makefolder
local isfolder_fn     = rawget(ENV, "isfolder")          or isfolder
local readfile_fn     = rawget(ENV, "readfile")          or readfile
local isfile_fn       = rawget(ENV, "isfile")            or isfile
local appendfile_fn   = rawget(ENV, "appendfile")        or appendfile

local REMOTE_CLASSES = {
    RemoteEvent = { call = "FireServer", server = true },
    UnreliableRemoteEvent = { call = "FireServer", server = true },
    RemoteFunction = { call = "InvokeServer", server = true },
    BindableEvent = { call = "Fire", server = false },
    BindableFunction = { call = "Invoke", server = false },
}

local function notify(text)
    print("[MegaDumper] " .. text)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = "MegaDumper", Text = text, Duration = 6 })
    end)
end

local function fullPath(inst)
    if typeof(inst) ~= "Instance" then return tostring(inst) end
    local ok, p = pcall(function() return inst:GetFullName() end)
    return (ok and p) or inst.Name
end
local function lower(s) return (tostring(s):lower()) end
local function isIgnored(path)
    local p = lower(path)
    for _, r in ipairs(CONFIG.IgnoreRoots) do
        r = lower(r)
        if p == r or p:sub(1, #r + 1) == r .. "." then return true end
    end
    return false
end

-- In Important mode, drop scripts whose path matches known-useless noise.
local function isUseless(path)
    if not CONFIG.Important then return false end
    local p = lower(path)
    for _, pat in ipairs(CONFIG.UselessPatterns) do
        if p:find(pat) then return true end
    end
    return false
end
local function toHex(s) return (s:gsub(".", function(c) return string.format("%02x", string.byte(c)) end)) end

local function pathExpr(inst)
    local parts, cur = {}, inst
    while cur and cur ~= game do
        parts[#parts + 1] = cur.Name
        local okp, p = pcall(function() return cur.Parent end)
        if not okp then break end
        cur = p
    end
    if #parts == 0 then return "nil" end
    local out = ('game:GetService("%s")'):format(parts[#parts])
    for i = #parts - 1, 1, -1 do
        local n = parts[i]
        out = out .. (n:match("^[%a_][%w_]*$") and ("." .. n) or ('["%s"]'):format(n))
    end
    return out
end

-- ── Decompile with fallbacks (size-gated to avoid crashes) ──
-- Getting bytecode is cheap and rarely crashes; decompiling a giant
-- protected script is what kills the client. So we fetch bytecode FIRST,
-- and only hand the decompiler scripts small enough to be safe.
local function getScriptCode(scr)
    local bc
    if getbytecode_fn then
        local okb, b = pcall(getbytecode_fn, scr)
        if okb and type(b) == "string" and #b > 0 then bc = b end
    end

    local tooBig = CONFIG.SafeDecompile and bc and #bc > CONFIG.MaxDecompileBC
    if decompile_fn and CONFIG.Decompile and not tooBig then
        local ok, src = pcall(decompile_fn, scr)
        if ok and type(src) == "string" and #src > 0 then return src, "decompile" end
    end
    if getsource_fn then
        local ok, src = pcall(getsource_fn, scr)
        if ok and type(src) == "string" and #src > 0 then return src, "source" end
    end
    local ok, src = pcall(function() return scr.Source end)
    if ok and type(src) == "string" and #src > 0 then return src, "Source" end
    if bc then
        return (CONFIG.BytecodeAsHex and toHex(bc) or bc),
               tooBig and ("bytecode(too big to decompile: " .. #bc .. "b)") or "bytecode"
    end
    return nil, "unavailable"
end

-- ── Classify + beautify ───────────────────────────────────
local function classify(code, method)
    if not code then return "unavailable" end
    if method == "bytecode" then return "vm" end
    local regHits = 0
    for _ in code:gmatch("[%a_][%w_]*%[%d+%]%s*=") do regHits = regHits + 1 end
    local dispatch = code:find("task%.spawn%(function%(%.%.%.%)") and code:find("repeat") and code:find("until")
    if regHits > 25 or (dispatch and regHits > 8) then return "vm" end
    return "clean"
end

local function stripCode(line)
    line = line:gsub('"[^"]*"', '""'):gsub("'[^']*'", "''")
    return (line:gsub("%-%-.*$", ""))
end
local OPENERS = { ["then"] = true, ["do"] = true, ["function"] = true, ["repeat"] = true }
local function reindent(code)
    local lines = {}
    for l in (code .. "\n"):gmatch("(.-)\n") do lines[#lines + 1] = l end
    local out, depth, inLong = {}, 0, false
    for _, raw in ipairs(lines) do
        local line = raw:gsub("^%s+", ""):gsub("%s+$", "")
        if inLong then
            out[#out + 1] = raw
            if line:find("%]%]") then inLong = false end
        else
            local c = stripCode(line)
            if c:match("^end") or c:match("^else") or c:match("^elseif")
               or c:match("^until") or c:match("^[%)%}%]]") then
                depth = math.max(0, depth - 1)
            end
            out[#out + 1] = (line == "") and "" or (CONFIG.IndentStr:rep(depth) .. line)
            if c:match("^else") or c:match("^elseif") then depth = depth + 1 end
            local opens = 0
            for w in c:gmatch("[%a_]+") do if OPENERS[w] then opens = opens + 1 end end
            local _, po = c:gsub("[%({%[]", "")
            local _, pc = c:gsub("[%)}%]]", "")
            local _, ends = c:gsub("%f[%a]end%f[%A]", "")
            depth = math.max(0, depth + opens + po - pc - ends)
            if c:find("%[%[") and not c:find("%]%]") then inLong = true end
        end
    end
    return table.concat(out, "\n")
end

local function collapseBlanks(code)
    local out, run = {}, 0
    for l in (code .. "\n"):gmatch("(.-)\n") do
        if l:match("^%s*$") then
            run = run + 1
            if run <= CONFIG.MaxBlankRun then out[#out + 1] = "" end
        else run = 0; out[#out + 1] = l end
    end
    return table.concat(out, "\n")
end

-- ── Collect remotes + scripts ─────────────────────────────
local function collect()
    local seen, remotes, scripts = {}, {}, {}
    local n = 0
    local function consider(inst)
        if not inst or seen[inst] then return end
        seen[inst] = true
        n = n + 1
        if n % 2000 == 0 then task.wait() end
        local ok, cn = pcall(function() return inst.ClassName end)
        if not ok then return end
        if REMOTE_CLASSES[cn] and (CONFIG.IncludeBindables or REMOTE_CLASSES[cn].server) then
            remotes[#remotes + 1] = { obj = inst, cn = cn, info = REMOTE_CLASSES[cn] }
        end
        local oks, isSrc = pcall(function() return inst:IsA("LuaSourceContainer") end)
        if oks and isSrc and not isUseless(fullPath(inst)) then scripts[#scripts + 1] = inst end
    end
    -- Scope: when CONFIG.Scope is a list of service names, only walk those
    -- services (far fewer scripts -> survivable on low-RAM devices like an
    -- iPad). Otherwise walk the whole game.
    local roots = {}
    -- Explicit Scope wins; else Important mode auto-scopes to client+shared
    -- services; else the whole game.
    local scopeList = CONFIG.Scope
    if (not scopeList) and CONFIG.Important then scopeList = CONFIG.ImportantScope end
    if type(scopeList) == "table" and #scopeList > 0 then
        for _, name in ipairs(scopeList) do
            local okS, svc = pcall(function() return game:GetService(name) end)
            if okS and svc then roots[#roots + 1] = svc
            else
                local okF, f = pcall(function() return game:FindFirstChild(name) end)
                if okF and f then roots[#roots + 1] = f end
            end
        end
    else
        roots[1] = game
    end
    for _, root in ipairs(roots) do
        local ok, desc = pcall(function() return root:GetDescendants() end)
        if ok then for _, o in ipairs(desc) do consider(o) end end
    end
    if CONFIG.IncludeNil and getnil_fn then
        local okn, nils = pcall(getnil_fn)
        if okn and type(nils) == "table" then
            for _, o in ipairs(nils) do consider(o)
                pcall(function() for _, d in ipairs(o:GetDescendants()) do consider(d) end end)
            end
        end
    end
    if CONFIG.UseGetScripts and getscripts_fn then
        local okg, list = pcall(getscripts_fn)
        if okg and type(list) == "table" then for _, s in ipairs(list) do consider(s) end end
    end
    return remotes, scripts
end

-- ── File path helper ──────────────────────────────────────
local function safePath(path, cls, ext)
    local segs = {}
    for seg in tostring(path):gmatch("[^%.]+") do
        seg = seg:gsub('[<>:"/\\|%?%*]', "_"):gsub("%s+$", "")
        segs[#segs + 1] = seg ~= "" and seg or "_"
    end
    table.insert(segs, 1, cls)
    local dir = CONFIG.OutputFolder
    pcall(function() if isfolder_fn and not isfolder_fn(dir) then makefolder_fn(dir) end end)
    for i = 1, #segs - 1 do
        dir = dir .. "/" .. segs[i]
        pcall(function() if isfolder_fn and not isfolder_fn(dir) then makefolder_fn(dir) end end)
    end
    return dir .. "/" .. (segs[#segs] or "script") .. ext
end

-- ── Clipboard (whole thing, chunk fallback) ───────────────
local function copyAll(text)
    if not setclipboard_fn then return notify("No clipboard fn - use the saved files") end
    local safe = text:gsub("%z", "?")
    if pcall(setclipboard_fn, safe) then
        return notify(("Copied EVERYTHING to clipboard! (%d chars)"):format(#safe))
    end
    local chunks = {}
    for i = 1, #safe, CONFIG.ChunkSize do chunks[#chunks + 1] = safe:sub(i, i + CONFIG.ChunkSize - 1) end
    local cur = 1
    local function copyChunk(i)
        pcall(setclipboard_fn, ("-- chunk %d/%d\n"):format(i, #chunks) .. chunks[i])
        notify(("Copied chunk %d/%d - paste, press ] for next"):format(i, #chunks))
    end
    copyChunk(cur)
    getgenv_fn().MegaDumper_NextChunk = function() if cur < #chunks then cur = cur + 1 end copyChunk(cur) end
    local okU, UIS = pcall(function() return game:GetService("UserInputService") end)
    if okU and UIS then
        UIS.InputBegan:Connect(function(i, g)
            if g then return end
            if i.KeyCode == Enum.KeyCode.RightBracket then if cur < #chunks then cur = cur + 1 end copyChunk(cur)
            elseif i.KeyCode == Enum.KeyCode.LeftBracket then if cur > 1 then cur = cur - 1 end copyChunk(cur) end
        end)
    end
end

-- ── Run ───────────────────────────────────────────────────
local function run()
    notify("Scanning game...")
    local remotes, scripts = collect()

    local kR, kS, skipped = {}, {}, 0
    for _, r in ipairs(remotes) do
        local p = fullPath(r.obj)
        if isIgnored(p) then skipped = skipped + 1 else r.path = p; kR[#kR + 1] = r end
    end
    for _, s in ipairs(scripts) do
        local p = fullPath(s)
        if not isIgnored(p) then kS[#kS + 1] = { obj = s, path = p } end
    end
    table.sort(kR, function(a, b) return a.path < b.path end)
    table.sort(kS, function(a, b) return a.path < b.path end)

    -- The combined blob is CAPPED so memory never balloons on huge games.
    -- Per-script files (below) always hold the complete output.
    local out, outBytes, capped = {}, 0, false
    local function add(line)
        if capped then return end
        out[#out + 1] = line
        outBytes = outBytes + #line + 1
        if outBytes >= CONFIG.CombinedCap then
            out[#out + 1] = "\n-- [combined report capped here to protect memory; "
                            .. "the full output is in the per-script files under /"
                            .. CONFIG.OutputFolder .. "] --"
            capped = true
        end
    end

    add("============================================================")
    add("  MegaDumper  –  remotes + decompiled + cleaned code")
    add(("  %s (PlaceId %s)"):format(game.Name ~= "" and game.Name or "Game", tostring(game.PlaceId)))
    add(("  Remotes: %d  |  Scripts: %d"):format(#kR, #kS))
    add("  Generated: " .. os.date("!%Y-%m-%d %H:%M:%S UTC"))
    add("============================================================\n")

    -- Remotes
    add(("##### REMOTES (%d) #####"):format(#kR))
    for _, r in ipairs(kR) do
        add(("[%d] (%s)  %s"):format(_, r.cn, r.path))
        add(("    %s:%s()"):format(pathExpr(r.obj), r.info.call))
    end
    add("")

    -- Code — decompile, clean, and STREAM each script straight to disk so
    -- we never hold thousands of sources in memory at once.
    notify(("Decompiling %d scripts (this can take a while - don't panic)..."):format(#kS))
    add(("##### CODE (%d scripts) #####\n"):format(#kS))
    local counts = { clean = 0, vm = 0, unavailable = 0 }
    local done = 0
    local lastClock = os.clock()
    local function breathe()
        -- Yield on a time budget so a heavy decompile can never block the
        -- main thread long enough for Roblox to kill the client.
        if os.clock() - lastClock >= CONFIG.TimeBudget then
            task.wait()
            lastClock = os.clock()
        end
    end

    -- ── Resume / crash-skip ──────────────────────────────────
    -- Before touching a script we record it in _current. If a NATIVE
    -- decompiler crash kills the client, the next run reads _current, adds
    -- that one to the skip list, reads _progress to skip everything already
    -- done, and carries on - so you always finish within a rerun or two.
    if makefolder_fn then
        pcall(function() if isfolder_fn and not isfolder_fn(CONFIG.OutputFolder) then makefolder_fn(CONFIG.OutputFolder) end end)
    end
    local progressPath = CONFIG.OutputFolder .. "/_progress.txt"
    local currentPath  = CONFIG.OutputFolder .. "/_current.txt"
    local doneSet, skipSet, resumed = {}, {}, 0
    if CONFIG.Resume and readfile_fn then
        -- A non-empty _current means the last run crashed mid-script => resume.
        -- Empty/absent means the last run finished cleanly => start fresh.
        local crashed
        pcall(function()
            if isfile_fn and isfile_fn(currentPath) then
                local c = readfile_fn(currentPath)
                if c and c ~= "" then crashed = c end
            end
        end)
        if crashed then
            skipSet[crashed] = true
            warn("[MegaDumper] Skipping script that crashed a previous run: " .. crashed)
            pcall(function()
                if isfile_fn and isfile_fn(progressPath) then
                    for line in (readfile_fn(progressPath) .. "\n"):gmatch("(.-)\n") do
                        if line ~= "" then doneSet[line] = true; resumed = resumed + 1 end
                    end
                end
            end)
            notify(("Resuming after a crash - skipping %d done + 1 bad script."):format(resumed))
        else
            -- Fresh run: wipe the previous progress log so nothing is skipped.
            if writefile_fn then pcall(writefile_fn, progressPath, "") end
        end
    end
    local function markCurrent(p) if CONFIG.Resume and writefile_fn then pcall(writefile_fn, currentPath, p) end end
    local function clearCurrent() if CONFIG.Resume and writefile_fn then pcall(writefile_fn, currentPath, "") end end
    local function markDone(p)
        if not (CONFIG.Resume and writefile_fn) then return end
        if appendfile_fn then pcall(appendfile_fn, progressPath, p .. "\n") end
    end

    for i, s in ipairs(kS) do
        local cn = "Script"; pcall(function() cn = s.obj.ClassName end)
        local code, method

        if doneSet[s.path] then
            -- Already dumped in a previous run; don't touch it again.
            method = "done (previous run)"
        elseif skipSet[s.path] then
            -- This one crashed the decompiler last time; never retry it.
            method = "skipped (crashed a previous run)"
        elseif done < CONFIG.MaxDecompiles then
            markCurrent(s.path)                       -- record BEFORE the risky call
            local ok, c, m = pcall(getScriptCode, s.obj)
            clearCurrent()                            -- survived it
            if ok then code, method = c, m else method = "error" end
            markDone(s.path)
            done = done + 1
            if done % CONFIG.YieldEvery == 0 then task.wait(); lastClock = os.clock() end
        else method = "skipped (cap)" end
        breathe()

        local cls = classify(code, method)
        counts[cls] = (counts[cls] or 0) + 1

        local body = code or "-- unavailable (protected/empty)"
        -- Only beautify readable, reasonably-sized bodies; skip giant/VM ones.
        if cls == "clean" and CONFIG.Reindent and #body <= CONFIG.MaxBeautify then
            local okB, res = pcall(reindent, body); if okB then body = res end
            local okC, res2 = pcall(collapseBlanks, body); if okC then body = res2 end
            breathe()
        end

        local header = ("[%d] %s  (%s)  [%s | via %s]"):format(i, s.path, cn, cls, tostring(method))

        -- Stream to its own file (complete output, unaffected by the cap).
        -- Never overwrite a file that a previous run already dumped good code to.
        if CONFIG.SavePerScript and writefile_fn and method ~= "done (previous run)" then
            local ext = (cls == "vm") and ".vm.lua" or (cls == "unavailable") and ".missing.lua" or ".lua"
            pcall(writefile_fn, safePath(s.path, cls, ext), "-- " .. header .. "\n\n" .. body)
        end

        -- Add to the capped combined blob for the clipboard.
        add("------------------------------------------------------------")
        add(header)
        add("------------------------------------------------------------")
        add(body)
        add("")

        body = nil  -- let it GC before the next iteration
    end

    local text = table.concat(out, "\n")
    out = nil

    if writefile_fn then
        pcall(writefile_fn, ("%s/_ALL_%s.txt"):format(CONFIG.OutputFolder, tostring(game.PlaceId)), text)
    end
    if CONFIG.CopyClipboard then copyAll(text) end

    print(("[MegaDumper] Done. Remotes: %d | Scripts: %d | clean=%d vm=%d unavailable=%d | %d chars%s.")
        :format(#kR, #kS, counts.clean, counts.vm, counts.unavailable, #text,
                capped and " (combined capped; files complete)" or ""))
    notify(("Done. %d remotes, %d scripts (clean=%d vm=%d). Saved to /%s%s.")
        :format(#kR, #kS, counts.clean, counts.vm, CONFIG.OutputFolder,
                capped and " (clipboard capped - use files)" or " + clipboard"))
end

local okRun, err = pcall(run)
if not okRun then warn("[MegaDumper] Error: " .. tostring(err)); notify("Error: " .. tostring(err)) end
