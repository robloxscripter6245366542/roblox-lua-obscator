-- ============================================================
--  MobileDumper.lua  –  Light, no-lag dumper for phones/tablets
--
--  Built for weak devices (Delta on an iPad, etc.) where the big
--  dumpers OOM-crash. It stays tiny by design:
--
--    - Scans ONLY the important folders (shared + client code); skips
--      the 20k+ character / animation / asset scripts that cause lag.
--    - Streams every script straight to its OWN file - it never builds
--      a giant in-memory report, so memory stays flat.
--    - Skips reading the huge VM modules (over MaxScriptBytes) that
--      spike memory; it just lists them instead.
--    - Dumps ALL remotes (cheap) to one file.
--    - Yields constantly so the game never freezes.
--
--  Output goes to /MobileDump in your executor's workspace folder:
--    MobileDump/_remotes.txt   – every remote + a call snippet
--    MobileDump/_index.txt     – list of every script + its status
--    MobileDump/<path>.txt     – one file per script (source/bytecode)
--
--  IMPORTANT FOLDERS it extracts (edit CONFIG.Folders to change):
--    ReplicatedStorage, ReplicatedFirst, StarterPlayer, StarterGui,
--    StarterPack, and your LocalPlayer's PlayerScripts + PlayerGui.
--  These hold the shared modules, client logic and remotes - the parts
--  that actually matter. Workspace/characters/animations are skipped.
-- ============================================================

local Players    = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

-- ── Config ────────────────────────────────────────────────
local CONFIG = {
    OutputFolder   = "MobileDump",
    Folders        = { "ReplicatedStorage", "ReplicatedFirst",
                       "StarterPlayer", "StarterGui", "StarterPack" },
    IncludeLocalPlayer = true,   -- also scan LocalPlayer PlayerScripts+PlayerGui
    IncludeBindables   = true,   -- list bindables too (they're cheap)
    MaxScriptBytes = 60000,      -- skip reading scripts whose bytecode is
                                 -- bigger than this (the memory spikers)
    BytecodeAsHex  = true,
    YieldEvery     = 2,          -- task.wait() after this many script reads
    CopyRemotes    = true,       -- also copy the remote list to clipboard
}
-- ──────────────────────────────────────────────────────────

local getgenv_fn      = getgenv or function() return _G end
local ENV             = getgenv_fn()
local decompile_fn    = rawget(ENV, "decompile")         or decompile
local getsource_fn    = rawget(ENV, "getscriptsource")   or getscriptsource
local getbytecode_fn  = rawget(ENV, "getscriptbytecode") or getscriptbytecode or dumpstring
local setclipboard_fn = rawget(ENV, "setclipboard")      or setclipboard or toclipboard
local writefile_fn    = rawget(ENV, "writefile")         or writefile
local makefolder_fn   = rawget(ENV, "makefolder")        or makefolder
local isfolder_fn     = rawget(ENV, "isfolder")          or isfolder

if not writefile_fn then
    pcall(function() StarterGui:SetCore("SendNotification",
        { Title = "MobileDumper", Text = "This executor has no writefile - can't save.", Duration = 6 }) end)
    return
end

local REMOTE_CLASSES = {
    RemoteEvent = "FireServer", UnreliableRemoteEvent = "FireServer",
    RemoteFunction = "InvokeServer", BindableEvent = "Fire", BindableFunction = "Invoke",
}
local SERVER_REMOTE = { RemoteEvent = true, UnreliableRemoteEvent = true, RemoteFunction = true }

local function notify(text)
    print("[MobileDumper] " .. text)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = "MobileDumper", Text = text, Duration = 5 })
    end)
end

local function fullPath(inst)
    if typeof(inst) ~= "Instance" then return tostring(inst) end
    local ok, p = pcall(function() return inst:GetFullName() end)
    return (ok and p) or inst.Name
end
local function toHex(s) return (s:gsub(".", function(c) return string.format("%02x", string.byte(c)) end)) end

local function pathExpr(inst)
    local parts, cur = {}, inst
    while cur and cur ~= game do
        parts[#parts + 1] = cur.Name
        local okp, p = pcall(function() return cur.Parent end); if not okp then break end
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

-- Read a script cheaply: source if the executor has it, else bytecode,
-- but NEVER read anything bigger than MaxScriptBytes (that's what lags).
local function readScript(scr)
    if decompile_fn then
        local ok, src = pcall(decompile_fn, scr)
        if ok and type(src) == "string" and #src > 0 and #src <= CONFIG.MaxScriptBytes * 4 then
            return src, "decompile"
        end
    end
    if getsource_fn then
        local ok, src = pcall(getsource_fn, scr)
        if ok and type(src) == "string" and #src > 0 then return src, "source" end
    end
    if getbytecode_fn then
        local ok, bc = pcall(getbytecode_fn, scr)
        if ok and type(bc) == "string" and #bc > 0 then
            if #bc > CONFIG.MaxScriptBytes then
                return nil, ("skipped (too big: " .. #bc .. "b)")
            end
            return (CONFIG.BytecodeAsHex and toHex(bc) or bc), "bytecode"
        end
    end
    return nil, "unavailable"
end

-- Safe on-disk path under the output folder.
local function safePath(path)
    local segs = {}
    for seg in tostring(path):gmatch("[^%.]+") do
        seg = seg:gsub('[<>:"/\\|%?%*]', "_"):gsub("%s+$", "")
        segs[#segs + 1] = seg ~= "" and seg or "_"
    end
    local dir = CONFIG.OutputFolder
    pcall(function() if isfolder_fn and not isfolder_fn(dir) then makefolder_fn(dir) end end)
    for i = 1, #segs - 1 do
        dir = dir .. "/" .. segs[i]
        pcall(function() if isfolder_fn and not isfolder_fn(dir) then makefolder_fn(dir) end end)
    end
    return dir .. "/" .. (segs[#segs] or "s") .. ".txt"
end

-- ── Gather the important roots ────────────────────────────
local function roots()
    local out = {}
    for _, name in ipairs(CONFIG.Folders) do
        local ok, svc = pcall(function() return game:GetService(name) end)
        if ok and svc then out[#out + 1] = svc end
    end
    if CONFIG.IncludeLocalPlayer then
        local lp = Players.LocalPlayer
        if lp then
            for _, child in ipairs({ "PlayerScripts", "PlayerGui" }) do
                local c = lp:FindFirstChild(child)
                if c then out[#out + 1] = c end
            end
        end
    end
    return out
end

-- ── Run ───────────────────────────────────────────────────
local function run()
    pcall(function() if isfolder_fn and not isfolder_fn(CONFIG.OutputFolder) then makefolder_fn(CONFIG.OutputFolder) end end)
    notify("Scanning important folders...")

    local scripts, remotes = {}, {}
    local seen = {}
    for _, root in ipairs(roots()) do
        local ok, desc = pcall(function() return root:GetDescendants() end)
        if ok then
            for _, o in ipairs(desc) do
                if not seen[o] then
                    seen[o] = true
                    local okc, cn = pcall(function() return o.ClassName end)
                    if okc then
                        if REMOTE_CLASSES[cn] and (CONFIG.IncludeBindables or SERVER_REMOTE[cn]) then
                            remotes[#remotes + 1] = { obj = o, cn = cn }
                        end
                        local oks, isSrc = pcall(function() return o:IsA("LuaSourceContainer") end)
                        if oks and isSrc then scripts[#scripts + 1] = o end
                    end
                end
            end
        end
        task.wait()
    end

    -- ── Remotes (cheap) ──
    table.sort(remotes, function(a, b) return fullPath(a.obj) < fullPath(b.obj) end)
    local rlines = { ("##### REMOTES (%d) #####"):format(#remotes) }
    for i, r in ipairs(remotes) do
        rlines[#rlines + 1] = ("[%d] (%s)  %s"):format(i, r.cn, fullPath(r.obj))
        rlines[#rlines + 1] = ("    %s:%s()"):format(pathExpr(r.obj), REMOTE_CLASSES[r.cn])
    end
    local rtext = table.concat(rlines, "\n")
    pcall(writefile_fn, CONFIG.OutputFolder .. "/_remotes.txt", rtext)
    if CONFIG.CopyRemotes and setclipboard_fn then pcall(setclipboard_fn, rtext) end

    -- ── Scripts (streamed, size-limited) ──
    notify(("Dumping %d scripts (light mode)..."):format(#scripts))
    table.sort(scripts, function(a, b) return fullPath(a) < fullPath(b) end)
    local index, got, skipped = {}, 0, 0
    for i, scr in ipairs(scripts) do
        local path = fullPath(scr)
        local cn = "Script"; pcall(function() cn = scr.ClassName end)
        local body, how = readScript(scr)
        if body then got = got + 1 else skipped = skipped + 1 end
        pcall(writefile_fn, safePath(path),
              ("-- %s  (%s)  [%s]\n\n%s"):format(path, cn, how, body or ("-- " .. how)))
        index[#index + 1] = ("[%s] %s  (%s)"):format(how, path, cn)
        body = nil
        if i % CONFIG.YieldEvery == 0 then task.wait() end
    end

    index[#index + 1] = ""
    index[#index + 1] = ("Remotes: %d | Scripts: %d (read %d, skipped %d)")
        :format(#remotes, #scripts, got, skipped)
    pcall(writefile_fn, CONFIG.OutputFolder .. "/_index.txt", table.concat(index, "\n"))

    notify(("Done. %d remotes, %d scripts -> /%s"):format(#remotes, #scripts, CONFIG.OutputFolder))
    print(("[MobileDumper] Done. Remotes: %d | Scripts: %d (read %d, skipped %d). See /%s/_index.txt")
        :format(#remotes, #scripts, got, skipped, CONFIG.OutputFolder))
end

local ok, err = pcall(run)
if not ok then warn("[MobileDumper] Error: " .. tostring(err)); notify("Error: " .. tostring(err)) end
