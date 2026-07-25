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
    Reindent       = true,     -- beautify the clean scripts
    IndentStr      = "    ",
    MaxBlankRun    = 1,
    BytecodeAsHex  = true,
    MaxDecompiles  = 6000,
    SavePerScript  = true,
    SaveCombined   = true,
    CopyClipboard  = true,     -- copy the whole thing (chunk fallback)
    ChunkSize      = 180000,
    YieldEvery     = 20,
    IgnoreRoots    = { "CoreGui", "CorePackages", "RobloxGui", "RobloxReplicatedStorage", "CoreScripts" },
}
-- ──────────────────────────────────────────────────────────

local getgenv_fn      = getgenv or function() return _G end
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

-- ── Decompile with fallbacks ──────────────────────────────
local function getScriptCode(scr)
    if decompile_fn then
        local ok, src = pcall(decompile_fn, scr)
        if ok and type(src) == "string" and #src > 0 then return src, "decompile" end
    end
    if getsource_fn then
        local ok, src = pcall(getsource_fn, scr)
        if ok and type(src) == "string" and #src > 0 then return src, "source" end
    end
    local ok, src = pcall(function() return scr.Source end)
    if ok and type(src) == "string" and #src > 0 then return src, "Source" end
    if getbytecode_fn then
        local okb, bc = pcall(getbytecode_fn, scr)
        if okb and type(bc) == "string" and #bc > 0 then
            return (CONFIG.BytecodeAsHex and toHex(bc) or bc), "bytecode"
        end
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
        if oks and isSrc then scripts[#scripts + 1] = inst end
    end
    local ok, desc = pcall(function() return game:GetDescendants() end)
    if ok then for _, o in ipairs(desc) do consider(o) end end
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

    local out = {}
    out[#out + 1] = "============================================================"
    out[#out + 1] = "  MegaDumper  –  remotes + decompiled + cleaned code"
    out[#out + 1] = ("  %s (PlaceId %s)"):format(game.Name ~= "" and game.Name or "Game", tostring(game.PlaceId))
    out[#out + 1] = ("  Remotes: %d  |  Scripts: %d"):format(#kR, #kS)
    out[#out + 1] = "  Generated: " .. os.date("!%Y-%m-%d %H:%M:%S UTC")
    out[#out + 1] = "============================================================\n"

    -- Remotes
    out[#out + 1] = ("##### REMOTES (%d) #####"):format(#kR)
    for i, r in ipairs(kR) do
        out[#out + 1] = ("[%d] (%s)  %s"):format(i, r.cn, r.path)
        out[#out + 1] = ("    %s:%s()"):format(pathExpr(r.obj), r.info.call)
    end
    out[#out + 1] = ""

    -- Code
    notify(("Decompiling %d scripts..."):format(#kS))
    out[#out + 1] = ("##### CODE (%d scripts) #####\n"):format(#kS)
    local counts = { clean = 0, vm = 0, unavailable = 0 }
    local done, ops = 0, 0
    for i, s in ipairs(kS) do
        local cn = "Script"; pcall(function() cn = s.obj.ClassName end)
        local code, method
        if done < CONFIG.MaxDecompiles then
            code, method = getScriptCode(s.obj); done = done + 1
            ops = ops + 1; if ops % CONFIG.YieldEvery == 0 then task.wait() end
        else method = "skipped (cap)" end

        local cls = classify(code, method)
        counts[cls] = (counts[cls] or 0) + 1

        local body = code or "-- unavailable (protected/empty)"
        if cls == "clean" and CONFIG.Reindent then
            local okB, res = pcall(reindent, body); if okB then body = res end
            body = collapseBlanks(body)
        end

        out[#out + 1] = "------------------------------------------------------------"
        out[#out + 1] = ("[%d] %s  (%s)  [%s | via %s]"):format(i, s.path, cn, cls, tostring(method))
        out[#out + 1] = "------------------------------------------------------------"
        out[#out + 1] = body
        out[#out + 1] = ""

        if CONFIG.SavePerScript and writefile_fn then
            local ext = (cls == "vm") and ".vm.lua" or (cls == "unavailable") and ".missing.lua" or ".lua"
            pcall(writefile_fn, safePath(s.path, cls, ext), body)
        end
    end

    local text = table.concat(out, "\n")

    if CONFIG.SaveCombined and writefile_fn then
        pcall(writefile_fn, ("%s/_ALL_%s.txt"):format(CONFIG.OutputFolder, tostring(game.PlaceId)), text)
    end
    if CONFIG.CopyClipboard then copyAll(text) end

    print(text)
    print(("[MegaDumper] Done. Remotes: %d | Scripts: %d | clean=%d vm=%d unavailable=%d | %d chars.")
        :format(#kR, #kS, counts.clean, counts.vm, counts.unavailable, #text))
    notify(("Done. %d remotes, %d scripts (clean=%d vm=%d). Copied + saved to /%s.")
        :format(#kR, #kS, counts.clean, counts.vm, CONFIG.OutputFolder))
end

local okRun, err = pcall(run)
if not okRun then warn("[MegaDumper] Error: " .. tostring(err)); notify("Error: " .. tostring(err)) end
