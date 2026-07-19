-- ============================================================
--  GameFinder.lua  –  Universal Game Dumper
--  Finds & decompiles ALL scripts, lists ALL remotes, and
--  copies the full report to your clipboard.
--
--  Client-side utility. Run in an executor.
--  Executor functions used (with graceful fallbacks):
--    decompile / getscriptbytecode / getscripts
--    getnilinstances (optional), setclipboard, writefile
-- ============================================================

local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")

-- ── Config ────────────────────────────────────────────────
local CONFIG = {
    DecompileScripts = true,   -- decompile Script/LocalScript/ModuleScript source
    DumpRemotes      = true,   -- list RemoteEvent/Function + Bindables
    IncludeNil       = true,   -- also scan nil-parented instances (getnilinstances)
    CopyToClipboard  = true,   -- setclipboard(report)
    SaveToFile       = true,   -- writefile("GameFinder/<place>.txt", report)
    MaxSourceChars   = 0,      -- 0 = no limit per script; >0 truncates each dump
}
-- ──────────────────────────────────────────────────────────

-- Resolve executor globals safely (names differ across executors).
local getgenv_fn   = rawget(getfenv(), "getgenv")   and getgenv   or function() return _G end
local ENV          = getgenv_fn()
local decompile_fn = rawget(ENV, "decompile") or decompile
                     or (getscriptbytecode and function(s)
                            return "-- bytecode only (no decompiler)\n"
                                .. tostring(getscriptbytecode(s))
                        end)
local getscripts_fn   = rawget(ENV, "getscripts")   or getscripts
local getnil_fn       = rawget(ENV, "getnilinstances") or getnilinstances
local setclipboard_fn = rawget(ENV, "setclipboard") or setclipboard
                        or (rawget(ENV, "toclipboard")) or (rawget(ENV, "set_clipboard"))
local writefile_fn    = rawget(ENV, "writefile") or writefile

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title, Text = text, Duration = 6,
        })
    end)
end

-- Full path of an instance, e.g. game.ReplicatedStorage.Remotes.Buy
local function fullPath(inst)
    if not inst then return "nil" end
    local ok, path = pcall(function() return inst:GetFullName() end)
    if ok and path and path ~= "" then return path end
    -- Fallback for nil-parented instances.
    local parts, cur = {}, inst
    while cur do
        table.insert(parts, 1, cur.Name)
        local okp, p = pcall(function() return cur.Parent end)
        if not okp then break end
        cur = p
    end
    return table.concat(parts, ".")
end

-- ── Collect every instance we can reach ───────────────────
local function collectInstances()
    local seen, out = {}, {}
    local function add(inst)
        if inst and not seen[inst] then
            seen[inst] = true
            out[#out + 1] = inst
        end
    end
    for _, obj in ipairs(game:GetDescendants()) do add(obj) end
    if CONFIG.IncludeNil and getnil_fn then
        local ok, nils = pcall(getnil_fn)
        if ok and type(nils) == "table" then
            for _, obj in ipairs(nils) do
                add(obj)
                pcall(function()
                    for _, d in ipairs(obj:GetDescendants()) do add(d) end
                end)
            end
        end
    end
    return out
end

-- ── Script decompilation ──────────────────────────────────
local function dumpScripts(instances)
    local lines, count, failed = {}, 0, 0
    local sources = {}   -- collected here so getscripts() can add extras

    local function tryDump(scr)
        if sources[scr] then return end
        sources[scr] = true
        count = count + 1
        local className = scr.ClassName
        local header = ("[%d] %s  (%s)"):format(count, fullPath(scr), className)
        local src
        if decompile_fn then
            local ok, res = pcall(decompile_fn, scr)
            if ok and res and res ~= "" then
                src = res
            else
                failed = failed + 1
                src = "-- decompile failed: " .. tostring(res)
            end
        else
            -- No decompiler: ModuleScript/Script .Source is readable in Studio only,
            -- but try it anyway for local test rigs.
            local ok, res = pcall(function() return scr.Source end)
            src = (ok and res ~= "" and res)
                  or "-- no decompiler available and Source is empty/protected"
        end
        if CONFIG.MaxSourceChars > 0 and #src > CONFIG.MaxSourceChars then
            src = src:sub(1, CONFIG.MaxSourceChars) .. "\n-- ... [truncated]"
        end
        lines[#lines + 1] = ("-- %s\n%s\n%s\n"):format(
            header, string.rep("-", 60), src)
    end

    for _, obj in ipairs(instances) do
        if obj:IsA("LuaSourceContainer") then tryDump(obj) end
    end
    -- getscripts() may surface running scripts not in the tree.
    if getscripts_fn then
        local ok, list = pcall(getscripts_fn)
        if ok and type(list) == "table" then
            for _, scr in ipairs(list) do
                pcall(function()
                    if scr:IsA("LuaSourceContainer") then tryDump(scr) end
                end)
            end
        end
    end

    return lines, count, failed
end

-- ── Remote / Bindable discovery ───────────────────────────
local function dumpRemotes(instances)
    local buckets = {
        RemoteEvent      = {},
        RemoteFunction   = {},
        BindableEvent    = {},
        BindableFunction = {},
        UnreliableRemoteEvent = {},
    }
    for _, obj in ipairs(instances) do
        local b = buckets[obj.ClassName]
        if b then b[#b + 1] = fullPath(obj) end
    end
    local lines, total = {}, 0
    for _, kind in ipairs({
        "RemoteEvent", "UnreliableRemoteEvent", "RemoteFunction",
        "BindableEvent", "BindableFunction",
    }) do
        local paths = buckets[kind]
        table.sort(paths)
        lines[#lines + 1] = ("== %s (%d) =="):format(kind, #paths)
        for _, p in ipairs(paths) do
            lines[#lines + 1] = "  " .. p
            total = total + 1
        end
        lines[#lines + 1] = ""
    end
    return lines, total
end

-- ── Build the report ──────────────────────────────────────
local function run()
    local placeName = "Unknown"
    pcall(function()
        placeName = ("%s (PlaceId %d, JobId %s)"):format(
            game.Name ~= "" and game.Name or "Game",
            game.PlaceId, tostring(game.JobId))
    end)

    notify("GameFinder", "Scanning game...")
    local instances = collectInstances()

    local report = {}
    report[#report + 1] = "============================================================"
    report[#report + 1] = "  GameFinder Report"
    report[#report + 1] = "  " .. placeName
    report[#report + 1] = "  Instances scanned: " .. #instances
    report[#report + 1] = "  Generated: " .. os.date("!%Y-%m-%d %H:%M:%S UTC")
    report[#report + 1] = "============================================================\n"

    if CONFIG.DumpRemotes then
        local rl, rtotal = dumpRemotes(instances)
        report[#report + 1] = "##### REMOTES & BINDABLES (" .. rtotal .. ") #####\n"
        for _, l in ipairs(rl) do report[#report + 1] = l end
    end

    if CONFIG.DecompileScripts then
        local sl, scount, sfailed = dumpScripts(instances)
        report[#report + 1] = ("##### SCRIPTS (%d found, %d failed to decompile) #####\n")
            :format(scount, sfailed)
        for _, l in ipairs(sl) do report[#report + 1] = l end
    end

    local text = table.concat(report, "\n")

    if CONFIG.CopyToClipboard and setclipboard_fn then
        local ok = pcall(setclipboard_fn, text)
        if ok then notify("GameFinder", "Report copied to clipboard!") end
    end

    if CONFIG.SaveToFile and writefile_fn then
        local fname = ("GameFinder_%s.txt"):format(tostring(game.PlaceId))
        pcall(writefile_fn, fname, text)
        notify("GameFinder", "Saved to " .. fname)
    end

    print(text)
    print(("[GameFinder] Done. %d chars. Clipboard: %s | File: %s"):format(
        #text,
        (CONFIG.CopyToClipboard and setclipboard_fn) and "yes" or "no",
        (CONFIG.SaveToFile and writefile_fn) and "yes" or "no"))
    return text
end

local ok, err = pcall(run)
if not ok then
    warn("[GameFinder] Error: " .. tostring(err))
    notify("GameFinder", "Error: " .. tostring(err))
end
