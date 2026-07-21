-- ============================================================
--  RemoteDumper.lua  –  Collect ALL remotes in the whole game
--
--  Scans every service (plus nil-parented instances) and lists
--  every remote object it finds:
--    - RemoteEvent
--    - UnreliableRemoteEvent
--    - RemoteFunction
--    - BindableEvent
--    - BindableFunction
--
--  For each one it reports the full path, class, and a ready-to-use
--  call snippet (FireServer / InvokeServer / Fire / Invoke) so you
--  can drop it straight into your own script.
--
--  Everything is copied to your CLIPBOARD in one block and also
--  saved to a file so nothing is ever truncated.
--
--  NOTE: reads only what the executor can already reach on this
--  machine. Use it to study / back up your OWN games.
-- ============================================================

local StarterGui = game:GetService("StarterGui")

-- ── Config ────────────────────────────────────────────────
local CONFIG = {
    IncludeBindables = true,   -- also list BindableEvent / BindableFunction
    IncludeNil       = true,   -- also scan nil-parented instances
    CopyClipboard    = true,   -- copy the report to the clipboard
    SaveToFile       = true,   -- writefile the report as a backup
    ShowSnippets     = true,   -- print a Fire/Invoke call snippet per remote

    -- Skip Roblox's own internal remotes — not the game's own.
    IgnoreRoots      = {
        "CoreGui", "CorePackages", "RobloxGui",
        "RobloxReplicatedStorage", "CoreScripts",
    },

    -- ── Performance / safety (prevents freezes & crashes) ──
    YieldEvery       = 2000,   -- task.wait() while collecting huge trees
}
-- ──────────────────────────────────────────────────────────

-- Resolve executor globals safely (names vary between executors).
local getgenv_fn      = getgenv or function() return _G end
local ENV             = getgenv_fn()
local getnil_fn       = rawget(ENV, "getnilinstances") or getnilinstances
local setclipboard_fn = rawget(ENV, "setclipboard")    or setclipboard
                        or rawget(ENV, "toclipboard")  or toclipboard
                        or rawget(ENV, "set_clipboard")or set_clipboard
                        or (Clipboard and Clipboard.set)
local writefile_fn    = rawget(ENV, "writefile")       or writefile

-- Which classes count as "remotes" (and how you call them).
local REMOTE_CLASSES = {
    RemoteEvent           = { call = "FireServer",  server = true  },
    UnreliableRemoteEvent = { call = "FireServer",  server = true  },
    RemoteFunction        = { call = "InvokeServer",server = true  },
    BindableEvent         = { call = "Fire",        server = false },
    BindableFunction      = { call = "Invoke",      server = false },
}

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

-- Build a copy-pasteable reference to the remote via its full path.
-- e.g. game:GetService("ReplicatedStorage").Remotes.Buy
local function pathExpr(inst)
    local ok, svc = pcall(function() return inst:FindFirstAncestorWhichIsA("ServiceProvider") end)
    -- Walk up to the top-level service and rebuild an indexed path.
    local parts, cur = {}, inst
    while cur and cur ~= game do
        local name = cur.Name
        -- Use bracket indexing when the name isn't a plain identifier.
        if name:match("^[%a_][%w_]*$") then
            table.insert(parts, 1, "." .. name)
        else
            table.insert(parts, 1, ('["%s"]'):format(name:gsub('"', '\\"')))
        end
        local okp, p = pcall(function() return cur.Parent end)
        if not okp then break end
        cur = p
    end
    -- The first segment is a top-level service: express it via GetService.
    if #parts > 0 then
        local first = parts[1]:gsub("^%.", "")
        parts[1] = ('game:GetService("%s")'):format(first)
    else
        return "nil"
    end
    return table.concat(parts)
end

-- ── Collect every remote in the game ──────────────────────
local function collectRemotes()
    local seen, out = {}, {}
    local count = 0
    local function consider(inst)
        if not inst or seen[inst] then return end
        seen[inst] = true
        count = count + 1
        if count % CONFIG.YieldEvery == 0 then task.wait() end
        local ok, cn = pcall(function() return inst.ClassName end)
        if not ok then return end
        local info = REMOTE_CLASSES[cn]
        if not info then return end
        if not CONFIG.IncludeBindables and not info.server then return end
        out[#out + 1] = { obj = inst, cn = cn, info = info }
    end

    local ok, desc = pcall(function() return game:GetDescendants() end)
    if ok then for _, obj in ipairs(desc) do consider(obj) end end

    if CONFIG.IncludeNil and getnil_fn then
        local okn, nils = pcall(getnil_fn)
        if okn and type(nils) == "table" then
            for _, obj in ipairs(nils) do
                consider(obj)
                pcall(function()
                    for _, d in ipairs(obj:GetDescendants()) do consider(d) end
                end)
            end
        end
    end
    return out
end

-- ── Run ───────────────────────────────────────────────────
local function run()
    local placeName = "Game"
    pcall(function()
        placeName = ("%s (PlaceId %s, JobId %s)"):format(
            game.Name ~= "" and game.Name or "Game",
            tostring(game.PlaceId), tostring(game.JobId))
    end)

    notify("RemoteDumper", "Scanning the whole game for remotes...")
    local remotes = collectRemotes()

    -- Filter out Roblox-internal remotes, then group by class.
    local kept, skipped = {}, 0
    for _, r in ipairs(remotes) do
        local path = fullPath(r.obj)
        if isIgnoredPath(path) then
            skipped = skipped + 1
        else
            r.path = path
            kept[#kept + 1] = r
        end
    end
    table.sort(kept, function(a, b) return a.path < b.path end)

    -- Count per class for the summary.
    local perClass = {}
    for _, r in ipairs(kept) do perClass[r.cn] = (perClass[r.cn] or 0) + 1 end

    -- ── Assemble text ──
    local report = {}
    report[#report + 1] = "============================================================"
    report[#report + 1] = "  RemoteDumper Report"
    report[#report + 1] = "  " .. placeName
    report[#report + 1] = "  Remotes found: " .. #kept
    for _, cn in ipairs({ "RemoteEvent", "UnreliableRemoteEvent", "RemoteFunction",
                          "BindableEvent", "BindableFunction" }) do
        if perClass[cn] then
            report[#report + 1] = ("    %-22s %d"):format(cn, perClass[cn])
        end
    end
    report[#report + 1] = "  Roblox-internal skipped: " .. skipped
    report[#report + 1] = "  Generated: " .. os.date("!%Y-%m-%d %H:%M:%S UTC")
    report[#report + 1] = "============================================================\n"

    if #kept == 0 then report[#report + 1] = "  (no remotes found)\n" end

    for i, r in ipairs(kept) do
        report[#report + 1] = ("[%d] (%s)  %s"):format(i, r.cn, r.path)
        if CONFIG.ShowSnippets then
            report[#report + 1] = ("    %s:%s()"):format(pathExpr(r.obj), r.info.call)
        end
    end
    report[#report + 1] = ""

    local text = table.concat(report, "\n")

    -- ── Output ──
    if CONFIG.CopyClipboard then
        if not setclipboard_fn then
            notify("RemoteDumper", "No clipboard fn on this executor - use the saved file")
        else
            local safe = text:gsub("%z", "?")  -- strip NULs so clipboard won't truncate
            local ok = pcall(setclipboard_fn, safe)
            notify("RemoteDumper", ok
                and ("Copied %d remotes to clipboard!"):format(#kept)
                or  "Clipboard copy failed - use the saved file")
        end
    end

    if CONFIG.SaveToFile and writefile_fn then
        local fname = ("RemoteDumper_%s.txt"):format(tostring(game.PlaceId))
        if pcall(writefile_fn, fname, text) then
            notify("RemoteDumper", "Saved remote list to " .. fname)
        end
    end

    print(text)
    print(("[RemoteDumper] Done. Remotes: %d | internal-skipped: %d | %d chars.")
        :format(#kept, skipped, #text))
    return text
end

local ok, err = pcall(run)
if not ok then
    warn("[RemoteDumper] Error: " .. tostring(err))
    notify("RemoteDumper", "Error: " .. tostring(err))
end
