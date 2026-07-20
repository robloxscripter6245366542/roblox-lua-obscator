-- ============================================================
--  NameBlockFinder.lua  –  Name-Block Remote / Code Grabber
--
--  Scans the Workspace (and, optionally, the whole game) for
--  anything related to a "name block" / "nametag" feature:
--    - Remotes  (RemoteEvent / RemoteFunction / bindables)
--    - Scripts  (Script / LocalScript / ModuleScript)
--    - GUI / BillboardGui labels that render a player's name
--  whose *name* OR *source code* matches your keyword list.
--
--  For every matching script it tries to DECOMPILE the source:
--    decompile()  ->  getscriptsource()  ->  getscriptbytecode() (hex)
--  in that order, so it works on decompiler-equipped executors and
--  gracefully falls back to bytecode when none exists (e.g. Xeno).
--
--  Everything is copied to your CLIPBOARD in one block and also
--  saved to a file so nothing is ever truncated.
-- ============================================================

local StarterGui = game:GetService("StarterGui")
local Workspace  = game:GetService("Workspace")

-- ── Config ────────────────────────────────────────────────
local CONFIG = {
    -- Case-insensitive substrings that mark something as "name block".
    -- Matched against instance names AND decompiled/source text.
    Keywords = {
        "nameblock", "name_block", "name block",
        "nametag",  "name_tag",  "name tag",
        "displayname", "username", "overhead", "namelabel",
        "playername", "setname",  "changename", "namegui",
    },
    ScanWholeGame  = true,   -- false = Workspace only; true = every service
    IncludeNil     = true,   -- also scan nil-parented instances
    MatchOnSource  = true,   -- also match on decompiled/source text, not just names
    DumpRemotes    = true,   -- list matching remotes + bindables
    DecompileCode  = true,   -- decompile / dump every matching script
    CopyClipboard  = true,   -- setclipboard(report)
    SaveToFile     = true,   -- writefile("NameBlockFinder_<PlaceId>.txt", report)
    BytecodeAsHex  = true,   -- hex-encode bytecode fallback (NUL-safe clipboard)
}
-- ──────────────────────────────────────────────────────────

-- Resolve executor globals safely (names vary between executors).
local getgenv_fn     = getgenv or function() return _G end
local ENV            = getgenv_fn()
local getscripts_fn  = rawget(ENV, "getscripts")       or getscripts
local getnil_fn      = rawget(ENV, "getnilinstances")  or getnilinstances
local decompile_fn   = rawget(ENV, "decompile")        or decompile
local getsource_fn   = rawget(ENV, "getscriptsource")  or getscriptsource
                       or rawget(ENV, "getscriptsrc")  or getscriptsrc
local getbytecode_fn = rawget(ENV, "getscriptbytecode") or getscriptbytecode
                       or dumpstring
local setclipboard_fn = rawget(ENV, "setclipboard")    or setclipboard
                       or rawget(ENV, "toclipboard")   or toclipboard
                       or rawget(ENV, "set_clipboard") or set_clipboard
                       or (Clipboard and Clipboard.set)
local writefile_fn    = rawget(ENV, "writefile")       or writefile

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title, Text = text, Duration = 6,
        })
    end)
end

-- Full path of an instance, e.g. game.Workspace.NameBlock.Remote
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

-- Does `text` contain any configured keyword?
local function matchesKeyword(text)
    if not text then return false end
    local hay = lower(text)
    for _, kw in ipairs(CONFIG.Keywords) do
        if hay:find(kw:lower(), 1, true) then
            return true, kw
        end
    end
    return false
end

-- ── Decompile a single script (with graceful fallbacks) ───
-- Returns: sourceText, methodUsed
local function getScriptCode(scr)
    if CONFIG.DecompileCode and decompile_fn then
        local ok, src = pcall(decompile_fn, scr)
        if ok and type(src) == "string" and #src > 0 then
            return src, "decompile"
        end
    end
    if getsource_fn then
        local ok, src = pcall(getsource_fn, scr)
        if ok and type(src) == "string" and #src > 0 then
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

-- ── Collect every instance we care about ──────────────────
local function collectInstances()
    local seen, out = {}, {}
    local function add(inst)
        if inst and not seen[inst] then
            seen[inst] = true
            out[#out + 1] = inst
        end
    end

    local roots = {}
    if CONFIG.ScanWholeGame then
        roots[#roots + 1] = game
    else
        roots[#roots + 1] = Workspace
    end
    for _, root in ipairs(roots) do
        local ok, desc = pcall(function() return root:GetDescendants() end)
        if ok then for _, obj in ipairs(desc) do add(obj) end end
    end

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

    if getscripts_fn then
        local ok, list = pcall(getscripts_fn)
        if ok and type(list) == "table" then
            for _, scr in ipairs(list) do add(scr) end
        end
    end
    return out
end

-- ── Build the report ──────────────────────────────────────
local function run()
    local placeName = "Game"
    pcall(function()
        placeName = ("%s (PlaceId %d, JobId %s)"):format(
            game.Name ~= "" and game.Name or "Game",
            game.PlaceId, tostring(game.JobId))
    end)

    notify("NameBlockFinder", "Scanning for name-block remotes & code...")
    local instances = collectInstances()

    local remoteClasses = {
        RemoteEvent = true, UnreliableRemoteEvent = true, RemoteFunction = true,
        BindableEvent = true, BindableFunction = true,
    }

    local matchedRemotes, matchedScripts, matchedOther = {}, {}, {}

    for _, obj in ipairs(instances) do
        local okc, cn = pcall(function() return obj.ClassName end)
        if not okc then cn = "" end

        local nameHit = select(1, matchesKeyword(fullPath(obj)))
                        or select(1, matchesKeyword(obj.Name))

        local isScript = false
        pcall(function() isScript = obj:IsA("LuaSourceContainer") end)

        if isScript then
            local code, method = getScriptCode(obj)
            local hit = nameHit
            if not hit and CONFIG.MatchOnSource and code and method ~= "unavailable"
               and not method:find("bytecode") then
                hit = select(1, matchesKeyword(code))
            end
            if hit then
                matchedScripts[#matchedScripts + 1] = {
                    obj = obj, cn = cn, code = code, method = method,
                }
            end
        elseif remoteClasses[cn] then
            if nameHit then
                matchedRemotes[#matchedRemotes + 1] = { path = fullPath(obj), cn = cn }
            end
        elseif nameHit and (cn == "BillboardGui" or cn == "TextLabel"
               or cn == "SurfaceGui" or cn:find("Gui")) then
            matchedOther[#matchedOther + 1] = { path = fullPath(obj), cn = cn }
        end
    end

    table.sort(matchedRemotes, function(a, b) return a.path < b.path end)
    table.sort(matchedScripts, function(a, b) return fullPath(a.obj) < fullPath(b.obj) end)
    table.sort(matchedOther,  function(a, b) return a.path < b.path end)

    -- ── Assemble text ──
    local report = {}
    report[#report + 1] = "============================================================"
    report[#report + 1] = "  NameBlockFinder Report"
    report[#report + 1] = "  " .. placeName
    report[#report + 1] = "  Scope: " .. (CONFIG.ScanWholeGame and "Whole game" or "Workspace only")
    report[#report + 1] = "  Instances scanned: " .. #instances
    report[#report + 1] = "  Generated: " .. os.date("!%Y-%m-%d %H:%M:%S UTC")
    report[#report + 1] = "============================================================\n"

    if CONFIG.DumpRemotes then
        report[#report + 1] = ("##### NAME-BLOCK REMOTES (%d) #####"):format(#matchedRemotes)
        if #matchedRemotes == 0 then report[#report + 1] = "  (none found)" end
        for _, r in ipairs(matchedRemotes) do
            report[#report + 1] = ("  [%s]  %s"):format(r.cn, r.path)
        end
        report[#report + 1] = ""
    end

    if #matchedOther > 0 then
        report[#report + 1] = ("##### NAME-BLOCK GUI / LABELS (%d) #####"):format(#matchedOther)
        for _, g in ipairs(matchedOther) do
            report[#report + 1] = ("  [%s]  %s"):format(g.cn, g.path)
        end
        report[#report + 1] = ""
    end

    report[#report + 1] = ("##### NAME-BLOCK SCRIPTS (%d) #####\n"):format(#matchedScripts)
    if #matchedScripts == 0 then report[#report + 1] = "  (none found)\n" end
    for i, s in ipairs(matchedScripts) do
        report[#report + 1] = ("------------------------------------------------------------")
        report[#report + 1] = ("[%d] %s  (%s)  [via %s]"):format(
            i, fullPath(s.obj), s.cn, s.method)
        report[#report + 1] = ("------------------------------------------------------------")
        report[#report + 1] = s.code or "-- code unavailable (empty/protected)"
        report[#report + 1] = ""
    end

    local text = table.concat(report, "\n")

    -- ── Output ──
    if CONFIG.CopyClipboard then
        if not setclipboard_fn then
            notify("NameBlockFinder", "No clipboard fn on this executor - use the saved file")
            warn("[NameBlockFinder] setclipboard not available; report saved to file instead.")
        else
            local safe = text:gsub("%z", "?")   -- strip NULs so clipboard won't truncate
            local ok = pcall(setclipboard_fn, safe)
            notify("NameBlockFinder", ok
                and "Copied name-block code to clipboard!"
                or  "Clipboard copy failed - use the saved file")
        end
    end

    if CONFIG.SaveToFile and writefile_fn then
        local fname = ("NameBlockFinder_%s.txt"):format(tostring(game.PlaceId))
        if pcall(writefile_fn, fname, text) then
            notify("NameBlockFinder", "Saved dump to " .. fname)
        end
    end

    print(text)
    print(("[NameBlockFinder] Done. Remotes: %d | Scripts: %d | GUI: %d | %d chars.")
        :format(#matchedRemotes, #matchedScripts, #matchedOther, #text))
    return text
end

local ok, err = pcall(run)
if not ok then
    warn("[NameBlockFinder] Error: " .. tostring(err))
    notify("NameBlockFinder", "Error: " .. tostring(err))
end
