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

    -- WholeGame = true walks the ENTIRE game instead of just the folders
    -- above. Heavier - only sane because the light protections below
    -- (size-skip, streaming, yielding) still apply, but on a weak device a
    -- huge game can still lag/crash. IncludeNil adds nil-parented scripts.
    WholeGame      = false,
    IncludeNil     = false,

    -- Decompile is OFF by default. Decompiling tens of thousands of scripts
    -- (Phantom Ball ~27k, TSB, etc.) crashes phones/tablets. With it off we
    -- read source/bytecode instead - far cheaper, no decompiler crash. Turn
    -- it on only on a strong PC executor with a small game.
    Decompile      = false,

    MaxScriptBytes = 2000000,    -- skip reading scripts whose bytecode is
                                 -- bigger than this (set huge to read ALL)
    BytecodeAsHex  = true,
    YieldEvery     = 2,          -- task.wait() after this many script reads
    CopyRemotes    = true,       -- copy the remote list to clipboard

    -- CombinedFile streams EVERY script's code into one file (_ALL.txt) as
    -- it goes, using appendfile so memory stays flat - this is the single
    -- "whole game code" file. CopyCode then copies that whole file to the
    -- clipboard IF it fits under ClipboardCap (clipboards can't hold tens of
    -- MB; over the cap, use the file).
    CombinedFile   = true,
    CopyCode       = true,
    ClipboardCap   = 6000000,

    -- PerScriptFiles = false: don't write one file per script (writing tens
    -- of thousands of files in nested folders is what makes huge games look
    -- frozen on a phone). Everything goes into the single _ALL.txt instead.
    -- Auto-forced ON only if the executor has no appendfile.
    PerScriptFiles = false,

    -- Upload: when the code is too big for the clipboard, POST it to a paste
    -- host and copy a RAW LINK instead. 0x0.st returns a direct raw URL and
    -- needs no API key. Skipped if the dump is bigger than UploadCap (the
    -- whole thing has to fit in memory to POST it).
    Upload         = true,
    UploadUrl      = "https://0x0.st",
    UploadCap      = 25000000,   -- ~25 MB max to upload
}
-- ──────────────────────────────────────────────────────────

local getgenv_fn      = getgenv or function() return _G end
local ENV             = getgenv_fn()
-- Override any CONFIG value at runtime without editing the file, e.g.:
--   getgenv().MobileDumper_Config = { WholeGame = true }
do
    local ov = rawget(getgenv_fn(), "MobileDumper_Config")
    if type(ov) == "table" then for k, v in pairs(ov) do CONFIG[k] = v end end
end
local decompile_fn    = rawget(ENV, "decompile")         or decompile
local getsource_fn    = rawget(ENV, "getscriptsource")   or getscriptsource
local getbytecode_fn  = rawget(ENV, "getscriptbytecode") or getscriptbytecode or dumpstring
local setclipboard_fn = rawget(ENV, "setclipboard")      or setclipboard or toclipboard
local writefile_fn    = rawget(ENV, "writefile")         or writefile
local appendfile_fn   = rawget(ENV, "appendfile")        or appendfile
local readfile_fn     = rawget(ENV, "readfile")          or readfile
local makefolder_fn   = rawget(ENV, "makefolder")        or makefolder
local isfolder_fn     = rawget(ENV, "isfolder")          or isfolder
local http_request_fn = (syn and syn.request) or (http and http.request)
                        or rawget(ENV, "http_request") or http_request
                        or (fluxus and fluxus.request) or request

-- Upload text to a paste host and return a raw link. Uses a multipart POST
-- to 0x0.st, whose response body IS the direct raw URL. All pcall-guarded.
local function uploadPaste(text)
    if not http_request_fn then return nil, "no http request function on this executor" end
    local boundary = "----MobileDump" .. tostring(math.random(100000, 999999))
    local body = table.concat({
        "--" .. boundary,
        'Content-Disposition: form-data; name="file"; filename="dump.txt"',
        "Content-Type: text/plain", "", text,
        "--" .. boundary .. "--", "",
    }, "\r\n")
    local ok, res = pcall(http_request_fn, {
        Url = CONFIG.UploadUrl, Method = "POST",
        Headers = { ["Content-Type"] = "multipart/form-data; boundary=" .. boundary },
        Body = body,
    })
    if not ok then return nil, tostring(res) end
    local b = res and (res.Body or res.body)
    if type(b) == "string" then
        local url = b:match("(https?://%S+)")
        if url then return url end
        return nil, "unexpected response: " .. b:sub(1, 120)
    end
    return nil, "no response body"
end

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
-- Decompiling is OFF by default: decompiling tens of thousands of scripts
-- on a phone crashes the client. Bytecode/source reads are ~100x cheaper.
local function readScript(scr)
    if CONFIG.Decompile and decompile_fn then
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

-- ── Gather the roots to scan ──────────────────────────────
local function roots()
    -- Whole-game mode: just walk the entire game tree.
    if CONFIG.WholeGame then return { game } end

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
    notify(CONFIG.WholeGame and "Scanning the WHOLE game..." or "Scanning important folders...")

    local scripts, remotes = {}, {}
    local seen, n = {}, 0
    local function consider(o)
        if not o or seen[o] then return end
        seen[o] = true
        n = n + 1
        if n % 1500 == 0 then task.wait() end   -- yield while collecting big trees
        local okc, cn = pcall(function() return o.ClassName end)
        if not okc then return end
        if REMOTE_CLASSES[cn] and (CONFIG.IncludeBindables or SERVER_REMOTE[cn]) then
            remotes[#remotes + 1] = { obj = o, cn = cn }
        end
        local oks, isSrc = pcall(function() return o:IsA("LuaSourceContainer") end)
        if oks and isSrc then scripts[#scripts + 1] = o end
    end

    for _, root in ipairs(roots()) do
        local ok, desc = pcall(function() return root:GetDescendants() end)
        if ok then for _, o in ipairs(desc) do consider(o) end end
        task.wait()
    end

    if CONFIG.IncludeNil then
        local getnil_fn = rawget(ENV, "getnilinstances") or getnilinstances
        if getnil_fn then
            local okn, nils = pcall(getnil_fn)
            if okn and type(nils) == "table" then
                for _, o in ipairs(nils) do
                    consider(o)
                    pcall(function() for _, d in ipairs(o:GetDescendants()) do consider(d) end end)
                end
            end
        end
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
    -- Remotes go to clipboard only if we're not going to copy the code instead.
    if CONFIG.CopyRemotes and setclipboard_fn and not (CONFIG.CopyCode and CONFIG.CombinedFile) then
        pcall(setclipboard_fn, rtext)
    end

    -- ── Combined "whole game code" file, streamed with appendfile ──
    local combinedPath = CONFIG.OutputFolder .. "/_ALL.txt"
    local combinedBytes, combinedOK = 0, false
    if CONFIG.CombinedFile and appendfile_fn then
        combinedOK = pcall(writefile_fn, combinedPath,
            ("-- Whole game code dump  |  %s (PlaceId %s)  |  %s\n\n")
            :format(game.Name ~= "" and game.Name or "Game", tostring(game.PlaceId),
                    os.date("!%Y-%m-%d %H:%M:%S UTC")))
    end

    -- Writing tens of thousands of individual files (each in nested folders)
    -- is what makes huge games look frozen ("does nothing") on a phone. So
    -- per-script files are OFF by default: we stream everything into the one
    -- combined _ALL.txt instead. If the executor lacks appendfile we have no
    -- combined target, so we fall back to per-script files.
    local perFile = CONFIG.PerScriptFiles or not combinedOK

    -- ── Scripts (streamed) ──
    notify(("Dumping %d scripts%s..."):format(#scripts, perFile and " (per-file)" or " -> _ALL.txt"))
    table.sort(scripts, function(a, b) return fullPath(a) < fullPath(b) end)
    local index, got, skipped = {}, 0, 0
    for i, scr in ipairs(scripts) do
        local path = fullPath(scr)
        local cn = "Script"; pcall(function() cn = scr.ClassName end)
        local body, how = readScript(scr)
        if body then got = got + 1 else skipped = skipped + 1 end
        local block = ("-- %s  (%s)  [%s]\n\n%s"):format(path, cn, how, body or ("-- " .. how))
        if perFile then pcall(writefile_fn, safePath(path), block) end
        if combinedOK then
            local chunk = "\n------------------------------------------------------------\n" .. block .. "\n"
            if pcall(appendfile_fn, combinedPath, chunk) then combinedBytes = combinedBytes + #chunk end
        end
        index[#index + 1] = ("[%s] %s  (%s)"):format(how, path, cn)
        body, block = nil, nil
        if i % CONFIG.YieldEvery == 0 then task.wait() end
        -- Progress ping so a long run never looks frozen.
        if i % 2000 == 0 then notify(("Dumping... %d/%d"):format(i, #scripts)) end
    end

    index[#index + 1] = ""
    index[#index + 1] = ("Remotes: %d | Scripts: %d (read %d, skipped %d)")
        :format(#remotes, #scripts, got, skipped)
    pcall(writefile_fn, CONFIG.OutputFolder .. "/_index.txt", table.concat(index, "\n"))

    -- ── Copy the whole code to clipboard if it fits ──
    if CONFIG.CopyCode and setclipboard_fn then
        if combinedOK and combinedBytes <= CONFIG.ClipboardCap and readfile_fn then
            local okR, all = pcall(readfile_fn, combinedPath)
            if okR and type(all) == "string" then
                if pcall(setclipboard_fn, (all:gsub("%z", "?"))) then
                    notify(("Copied ALL game code to clipboard! (%d chars)"):format(#all))
                end
            end
        elseif combinedOK and combinedBytes > CONFIG.ClipboardCap then
            -- Too big to copy: upload it and hand back a RAW LINK instead.
            if CONFIG.Upload and readfile_fn and combinedBytes <= CONFIG.UploadCap then
                notify(("Code too big to copy (%d bytes) - uploading for a raw link..."):format(combinedBytes))
                local okR, all = pcall(readfile_fn, combinedPath)
                if okR and type(all) == "string" then
                    local url, uerr = uploadPaste(all)
                    if url then
                        pcall(setclipboard_fn, url)
                        notify("Raw code link copied to clipboard: " .. url)
                        print("[MobileDumper] Raw code link: " .. url)
                    else
                        notify("Upload failed (" .. tostring(uerr) .. ") - it's all in " .. CONFIG.OutputFolder .. "/_ALL.txt")
                    end
                end
            else
                notify(("Code too big for clipboard/upload (%d bytes) - it's all in %s/_ALL.txt"):format(combinedBytes, CONFIG.OutputFolder))
            end
        elseif CONFIG.CombinedFile and not appendfile_fn then
            notify("No appendfile on this executor - per-script files hold the code; no combined copy.")
        end
    end

    notify(("Done. %d remotes, %d scripts -> /%s"):format(#remotes, #scripts, CONFIG.OutputFolder))
    print(("[MobileDumper] Done. Remotes: %d | Scripts: %d (read %d, skipped %d). See /%s/_index.txt")
        :format(#remotes, #scripts, got, skipped, CONFIG.OutputFolder))
end

local ok, err = pcall(run)
if not ok then warn("[MobileDumper] Error: " .. tostring(err)); notify("Error: " .. tostring(err)) end
