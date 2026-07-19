-- ============================================================
--  GameFinder.lua  –  Universal Game Dumper (Xeno edition)
--
--  Copies EVERYTHING to your clipboard in one block:
--    - All remotes  (RemoteEvent / RemoteFunction / bindables) w/ full paths
--    - Full script list (Script / LocalScript / ModuleScript) w/ locations
--    - Bytecode dump for each script (getscriptbytecode)
--  Also saves the full report to a file (never truncated).
--
--  Built for Xeno. No decompiler required (Xeno has none) — the
--  script grabs bytecode instead of readable Lua source.
-- ============================================================

local StarterGui = game:GetService("StarterGui")

-- ── Config ────────────────────────────────────────────────
local CONFIG = {
    DumpRemotes   = true,   -- list all remotes + bindables
    ListScripts   = true,   -- list every Script/LocalScript/ModuleScript
    DumpBytecode  = true,   -- include getscriptbytecode for each script
    IncludeNil    = true,   -- also scan nil-parented instances
    CopyClipboard = true,   -- setclipboard(report)
    SaveToFile    = true,   -- writefile("GameFinder_<PlaceId>.txt", report)
    BytecodeAsHex = false,  -- true = hex-encode bytecode (safe to paste), false = raw
}
-- ──────────────────────────────────────────────────────────

-- Resolve Xeno globals safely.
local getgenv_fn        = getgenv or function() return _G end
local ENV               = getgenv_fn()
local getscripts_fn     = rawget(ENV, "getscripts") or getscripts
local getnil_fn         = rawget(ENV, "getnilinstances") or getnilinstances
local getbytecode_fn    = rawget(ENV, "getscriptbytecode") or getscriptbytecode
                          or dumpstring
local setclipboard_fn   = rawget(ENV, "setclipboard") or setclipboard or toclipboard
local writefile_fn      = rawget(ENV, "writefile") or writefile

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
    -- getscripts() can surface running scripts not in the tree.
    if getscripts_fn then
        local ok, list = pcall(getscripts_fn)
        if ok and type(list) == "table" then
            for _, scr in ipairs(list) do add(scr) end
        end
    end
    return out
end

-- ── Remote / Bindable discovery ───────────────────────────
local function dumpRemotes(instances)
    local buckets = {
        RemoteEvent = {}, UnreliableRemoteEvent = {}, RemoteFunction = {},
        BindableEvent = {}, BindableFunction = {},
    }
    for _, obj in ipairs(instances) do
        local ok, cn = pcall(function() return obj.ClassName end)
        if ok and buckets[cn] then
            buckets[cn][#buckets[cn] + 1] = fullPath(obj)
        end
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

-- ── Script list + bytecode ────────────────────────────────
local function dumpScripts(instances)
    local scripts = {}
    for _, obj in ipairs(instances) do
        local ok, isSrc = pcall(function() return obj:IsA("LuaSourceContainer") end)
        if ok and isSrc then scripts[#scripts + 1] = obj end
    end
    table.sort(scripts, function(a, b) return fullPath(a) < fullPath(b) end)

    local lines, count, bcOk, bcFail = {}, 0, 0, 0
    for _, scr in ipairs(scripts) do
        count = count + 1
        lines[#lines + 1] = ("[%d] %s  (%s)"):format(count, fullPath(scr), scr.ClassName)
        if CONFIG.DumpBytecode and getbytecode_fn then
            local ok, bc = pcall(getbytecode_fn, scr)
            if ok and type(bc) == "string" and #bc > 0 then
                bcOk = bcOk + 1
                local body = CONFIG.BytecodeAsHex and toHex(bc) or bc
                lines[#lines + 1] = ("    bytecode (%d bytes):"):format(#bc)
                lines[#lines + 1] = "    " .. body
            else
                bcFail = bcFail + 1
                lines[#lines + 1] = "    -- bytecode unavailable (empty/protected)"
            end
        end
    end
    return lines, count, bcOk, bcFail
end

-- ── Build the report ──────────────────────────────────────
local function run()
    local placeName = "Game"
    pcall(function()
        placeName = ("%s (PlaceId %d, JobId %s)"):format(
            game.Name ~= "" and game.Name or "Game",
            game.PlaceId, tostring(game.JobId))
    end)

    notify("GameFinder", "Scanning game...")
    local instances = collectInstances()

    local report = {}
    report[#report + 1] = "============================================================"
    report[#report + 1] = "  GameFinder Report  (Xeno)"
    report[#report + 1] = "  " .. placeName
    report[#report + 1] = "  Instances scanned: " .. #instances
    report[#report + 1] = "  Generated: " .. os.date("!%Y-%m-%d %H:%M:%S UTC")
    report[#report + 1] = "============================================================\n"

    if CONFIG.DumpRemotes then
        local rl, rtotal = dumpRemotes(instances)
        report[#report + 1] = "##### REMOTES & BINDABLES (" .. rtotal .. ") #####\n"
        for _, l in ipairs(rl) do report[#report + 1] = l end
    end

    if CONFIG.ListScripts then
        local sl, scount, bcOk, bcFail = dumpScripts(instances)
        report[#report + 1] = ("##### SCRIPTS (%d found | bytecode: %d ok, %d failed) #####\n")
            :format(scount, bcOk, bcFail)
        for _, l in ipairs(sl) do report[#report + 1] = l end
    end

    local text = table.concat(report, "\n")

    if CONFIG.CopyClipboard and setclipboard_fn then
        local ok = pcall(setclipboard_fn, text)
        if ok then notify("GameFinder", "Copied everything to clipboard!") end
    end

    if CONFIG.SaveToFile and writefile_fn then
        local fname = ("GameFinder_%s.txt"):format(tostring(game.PlaceId))
        local okw = pcall(writefile_fn, fname, text)
        if okw then notify("GameFinder", "Saved full dump to " .. fname) end
    end

    print(text)
    print(("[GameFinder] Done. %d chars. Clipboard: %s | File: %s"):format(
        #text,
        (CONFIG.CopyClipboard and setclipboard_fn) and "yes" or "no",
        (CONFIG.SaveToFile and writefile_fn) and "yes" or "no"))
    return text
end

local ok, err = pcall(run)
if not ok then
    warn("[GameFinder] Error: " .. tostring(err))
    notify("GameFinder", "Error: " .. tostring(err))
end
