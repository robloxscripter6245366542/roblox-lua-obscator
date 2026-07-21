-- ============================================================
--  GameCodeDumper.lua  –  Copy ALL code from a game
--
--  Walks every service in the game and dumps the source of every
--  script it can reach:
--    - Script / LocalScript / ModuleScript (any LuaSourceContainer)
--    - nil-parented scripts (getnilinstances)
--    - scripts the executor already knows about (getscripts)
--
--  For each script it tries, in order:
--    decompile()  ->  getscriptsource()  ->  .Source  ->  getscriptbytecode() (hex)
--  so it works on full decompiler executors and gracefully falls
--  back to raw bytecode when no decompiler exists (e.g. Xeno).
--
--  Output:
--    - One folder tree on disk mirroring the game hierarchy, one
--      .lua/.txt file per script (nothing ever truncated).
--    - A single combined dump file.
--    - The combined dump copied to your CLIPBOARD (if it fits).
--
--  NOTE: This only reads scripts the executor can already access on
--  the machine running it. Use it to back up / study your OWN games.
-- ============================================================

local StarterGui = game:GetService("StarterGui")

-- ── Config ────────────────────────────────────────────────
local CONFIG = {
    -- Where the per-script files & combined dump are written.
    OutputFolder   = "GameCodeDump",

    IncludeNil     = true,   -- also dump nil-parented scripts
    UseGetScripts  = true,   -- also pull from the executor's getscripts()
    DecompileCode  = true,   -- use decompile() as the primary method

    SavePerScript  = true,   -- write one file per script (folder tree)
    SaveCombined   = true,   -- write one big combined dump file
    CopyClipboard  = true,   -- copy the combined dump to the clipboard
    BytecodeAsHex  = true,   -- hex-encode bytecode fallback (NUL-safe)

    -- Skip Roblox's own internal UI / packages — these are NOT the
    -- game's code and are protected (can't be decompiled anyway).
    IgnoreRoots    = {
        "CoreGui", "CorePackages", "RobloxGui",
        "RobloxReplicatedStorage", "CoreScripts",
    },

    -- ── Performance / safety (prevents freezes & crashes) ──
    MaxDecompiles  = 4000,   -- hard cap on total scripts decompiled
    YieldEvery     = 25,     -- task.wait() after this many heavy ops so
                             -- the client stays responsive (Roblox kills
                             -- clients that block the main thread too long)
    ClipboardLimit = 3000000,-- don't try to copy dumps bigger than this
}
-- ──────────────────────────────────────────────────────────

-- Resolve executor globals safely (names vary between executors).
local getgenv_fn      = getgenv or function() return _G end
local ENV             = getgenv_fn()
local getscripts_fn   = rawget(ENV, "getscripts")        or getscripts
local getnil_fn       = rawget(ENV, "getnilinstances")   or getnilinstances
local decompile_fn    = rawget(ENV, "decompile")         or decompile
local getsource_fn    = rawget(ENV, "getscriptsource")   or getscriptsource
                        or rawget(ENV, "getscriptsrc")   or getscriptsrc
local getbytecode_fn  = rawget(ENV, "getscriptbytecode") or getscriptbytecode
                        or dumpstring
local setclipboard_fn = rawget(ENV, "setclipboard")      or setclipboard
                        or rawget(ENV, "toclipboard")    or toclipboard
                        or rawget(ENV, "set_clipboard")  or set_clipboard
                        or (Clipboard and Clipboard.set)
local writefile_fn    = rawget(ENV, "writefile")         or writefile
local makefolder_fn   = rawget(ENV, "makefolder")        or makefolder
local isfolder_fn     = rawget(ENV, "isfolder")          or isfolder

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title, Text = text, Duration = 6,
        })
    end)
end

-- Full path of an instance, e.g. game.Workspace.Folder.MyScript
local function fullPath(inst)
    if not inst then return "nil" end
    local ok, path = pcall(function() return inst:GetFullName() end)
    if ok and path and path ~= "" then return path end
    local parts, cur = {}, inst
    while cur do
        table.insert(parts, 1, cur.Name)
        local okp, p = pcall(function() return cur.Parent end)
        if not okp then break end
        cur = p
    end
    return table.concat(parts, ".")
end

local function toHex(s)
    return (s:gsub(".", function(c)
        return string.format("%02x", string.byte(c))
    end))
end

local function lower(s) return (tostring(s):lower()) end

-- Is this full path under a Roblox-internal root we want to skip?
local function isIgnoredPath(path)
    local p = lower(path)
    for _, root in ipairs(CONFIG.IgnoreRoots) do
        local r = lower(root)
        if p == r or p:sub(1, #r + 1) == r .. "." then
            return true
        end
    end
    return false
end

-- Decompilers return an *error comment* (not a Lua error) when they can't
-- read a protected script. Detect those so we don't present the failure
-- message as if it were real source.
local function looksFailed(src)
    if not src then return true end
    local head = lower(src:sub(1, 300))
    return head:find("failed to get script bytecode", 1, true) ~= nil
        or head:find("failed to decompile", 1, true) ~= nil
        or head:find("decompilation failed", 1, true) ~= nil
        or head:find("could not decompile", 1, true) ~= nil
        or head:find("script is protected", 1, true) ~= nil
end

-- ── Decompile a single script (with graceful fallbacks) ───
-- Returns: sourceText, methodUsed
local function getScriptCode(scr)
    if CONFIG.DecompileCode and decompile_fn then
        local ok, src = pcall(decompile_fn, scr)
        if ok and type(src) == "string" and #src > 0 and not looksFailed(src) then
            return src, "decompile"
        end
    end
    if getsource_fn then
        local ok, src = pcall(getsource_fn, scr)
        if ok and type(src) == "string" and #src > 0 and not looksFailed(src) then
            return src, "source"
        end
    end
    -- Roblox exposes .Source for some containers under certain executors.
    local ok, src = pcall(function() return scr.Source end)
    if ok and type(src) == "string" and #src > 0 then
        return src, "Source"
    end
    if getbytecode_fn then
        local okb, bc = pcall(getbytecode_fn, scr)
        if okb and type(bc) == "string" and #bc > 0 then
            local body = CONFIG.BytecodeAsHex and toHex(bc) or bc
            return body, "bytecode(" .. #bc .. "b)"
        end
    end
    return nil, "unavailable"
end

-- ── Collect every script in the game ──────────────────────
local function collectScripts()
    local seen, out = {}, {}
    local function add(inst)
        if not inst or seen[inst] then return end
        local ok, isSrc = pcall(function() return inst:IsA("LuaSourceContainer") end)
        if not (ok and isSrc) then return end
        seen[inst] = true
        out[#out + 1] = inst
        if #out % 500 == 0 then task.wait() end
    end

    local ok, desc = pcall(function() return game:GetDescendants() end)
    if ok then
        for i, obj in ipairs(desc) do
            add(obj)
            if i % 4000 == 0 then task.wait() end
        end
    end

    if CONFIG.IncludeNil and getnil_fn then
        local okn, nils = pcall(getnil_fn)
        if okn and type(nils) == "table" then
            for _, obj in ipairs(nils) do
                add(obj)
                pcall(function()
                    for _, d in ipairs(obj:GetDescendants()) do add(d) end
                end)
            end
        end
    end

    if CONFIG.UseGetScripts and getscripts_fn then
        local oks, list = pcall(getscripts_fn)
        if oks and type(list) == "table" then
            for _, scr in ipairs(list) do add(scr) end
        end
    end
    return out
end

-- Turn a full path into a safe on-disk file path under the output folder.
local function safeFilePath(path, ext)
    -- Split on '.' into folder segments, sanitising each one.
    local segs = {}
    for seg in tostring(path):gmatch("[^%.]+") do
        seg = seg:gsub('[<>:"/\\|%?%*]', "_"):gsub("%s+$", "")
        if seg == "" then seg = "_" end
        segs[#segs + 1] = seg
    end
    local dir = CONFIG.OutputFolder
    -- Build nested folders for everything except the last segment.
    if makefolder_fn then
        pcall(function()
            if isfolder_fn and not isfolder_fn(dir) then makefolder_fn(dir) end
        end)
        for i = 1, #segs - 1 do
            dir = dir .. "/" .. segs[i]
            pcall(function()
                if isfolder_fn and not isfolder_fn(dir) then makefolder_fn(dir) end
            end)
        end
    end
    return dir .. "/" .. (segs[#segs] or "script") .. ext
end

-- ── Run ───────────────────────────────────────────────────
local function run()
    local placeName = "Game"
    pcall(function()
        placeName = ("%s (PlaceId %s, JobId %s)"):format(
            game.Name ~= "" and game.Name or "Game",
            tostring(game.PlaceId), tostring(game.JobId))
    end)

    notify("GameCodeDumper", "Collecting scripts...")
    local scripts = collectScripts()
    table.sort(scripts, function(a, b) return fullPath(a) < fullPath(b) end)

    if makefolder_fn then
        pcall(function()
            if isfolder_fn and not isfolder_fn(CONFIG.OutputFolder) then
                makefolder_fn(CONFIG.OutputFolder)
            end
        end)
    end

    local combined = {}
    combined[#combined + 1] = "============================================================"
    combined[#combined + 1] = "  GameCodeDumper  –  full source dump"
    combined[#combined + 1] = "  " .. placeName
    combined[#combined + 1] = "  Scripts found: " .. #scripts
    combined[#combined + 1] = "  Generated: " .. os.date("!%Y-%m-%d %H:%M:%S UTC")
    combined[#combined + 1] = "============================================================\n"

    local ops, done, failed, skipped, savedFiles = 0, 0, 0, 0, 0
    local capHit = false
    local function breathe()
        ops = ops + 1
        if CONFIG.YieldEvery > 0 and ops % CONFIG.YieldEvery == 0 then
            task.wait()
        end
    end

    for i, scr in ipairs(scripts) do
        local path = fullPath(scr)

        if isIgnoredPath(path) then
            skipped = skipped + 1
        else
            local cn = "Script"
            pcall(function() cn = scr.ClassName end)

            local code, method
            if done < CONFIG.MaxDecompiles then
                code, method = getScriptCode(scr)
                breathe()  -- decompile is the heavy op; yield right after
                done = done + 1
                if not code then failed = failed + 1 end
            else
                capHit = true
                method = "skipped (decompile cap reached)"
            end

            local body = code or ("-- code unavailable (empty/protected) [via "
                                  .. tostring(method) .. "]")

            -- Combined dump entry.
            combined[#combined + 1] = "------------------------------------------------------------"
            combined[#combined + 1] = ("[%d] %s  (%s)  [via %s]"):format(
                i, path, cn, tostring(method))
            combined[#combined + 1] = "------------------------------------------------------------"
            combined[#combined + 1] = body
            combined[#combined + 1] = ""

            -- Per-script file.
            if CONFIG.SavePerScript and writefile_fn then
                local isHex = method and method:find("bytecode")
                local ext = isHex and ".bytecode.hex" or ".lua"
                local fp = safeFilePath(path, ext)
                if pcall(writefile_fn, fp, body) then
                    savedFiles = savedFiles + 1
                end
            end
        end
    end

    local text = table.concat(combined, "\n")

    -- ── Output ──
    if CONFIG.SaveCombined and writefile_fn then
        local fname = ("%s/_ALL_%s.txt"):format(
            CONFIG.OutputFolder, tostring(game.PlaceId))
        if pcall(writefile_fn, fname, text) then
            notify("GameCodeDumper", "Saved combined dump to " .. fname)
        end
    end

    if CONFIG.CopyClipboard then
        if not setclipboard_fn then
            notify("GameCodeDumper", "No clipboard fn on this executor - use the saved files")
        elseif #text > CONFIG.ClipboardLimit then
            notify("GameCodeDumper", ("Dump too big for clipboard (%d chars) - use the saved files"):format(#text))
        else
            local safe = text:gsub("%z", "?")  -- strip NULs so clipboard won't truncate
            local ok = pcall(setclipboard_fn, safe)
            notify("GameCodeDumper", ok
                and "Copied full game code to clipboard!"
                or  "Clipboard copy failed - use the saved files")
        end
    end

    print(text)
    print(("[GameCodeDumper] Done. Scripts: %d | dumped: %d | failed: %d | "
           .. "internal-skipped: %d | files saved: %d%s | %d chars.")
        :format(#scripts, done, failed, skipped, savedFiles,
                capHit and (" (cap " .. CONFIG.MaxDecompiles .. " hit)") or "", #text))
    return text
end

local ok, err = pcall(run)
if not ok then
    warn("[GameCodeDumper] Error: " .. tostring(err))
    notify("GameCodeDumper", "Error: " .. tostring(err))
end
