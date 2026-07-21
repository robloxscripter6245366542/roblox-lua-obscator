-- ============================================================
--  GameFullDumper.lua  –  Dump ALL remotes + ALL game code
--
--  One script that combines RemoteDumper + GameCodeDumper:
--    - Every remote in the whole game (RemoteEvent / RemoteFunction /
--      UnreliableRemoteEvent / BindableEvent / BindableFunction) with a
--      ready-to-use call snippet.
--    - The source of every script the client can reach (LocalScript /
--      ModuleScript / any LuaSourceContainer) via decompile with
--      graceful fallbacks.
--
--  ── IMPORTANT: about "server-side code" ──────────────────
--  True server Scripts live in ServerScriptService / ServerStorage.
--  Roblox NEVER sends those to the client, so an executor (which runs
--  on the client) has no way to read them — this is not a protection
--  you can bypass; the bytes simply are not on your machine.
--
--  What you CAN get, and what this dumps, is every ModuleScript the
--  server SHARES with clients (ReplicatedStorage etc.) plus all the
--  remotes. From those you can see how the server is called and read
--  all shared logic. Any server Script this finds will show its class
--  and path, but its source will read "unavailable" — that's expected.
--
--  Output: clipboard (everything, one block) + a folder of per-script
--  files + combined dumps, so nothing is ever truncated.
--
--  Use it to back up / study your OWN games.
-- ============================================================

local StarterGui = game:GetService("StarterGui")

-- ── Config ────────────────────────────────────────────────
local CONFIG = {
    OutputFolder   = "GameFullDump",

    -- Remotes
    IncludeBindables = true,
    ShowSnippets     = true,

    -- Code
    DecompileCode    = true,
    IncludeNil       = true,   -- also scan nil-parented instances
    UseGetScripts    = true,   -- also pull from the executor's getscripts()
    BytecodeAsHex    = true,   -- hex-encode bytecode fallback (NUL-safe)
    MaxDecompiles    = 4000,

    -- Output
    SavePerScript    = true,
    SaveCombined     = true,
    CopyClipboard    = true,   -- copy the ENTIRE dump (no size cap)

    -- Roblox-internal roots that are not the game's own code/remotes.
    IgnoreRoots      = {
        "CoreGui", "CorePackages", "RobloxGui",
        "RobloxReplicatedStorage", "CoreScripts",
    },

    YieldEvery       = 25,     -- keep the client responsive on big games
    ChunkSize        = 180000, -- clipboard fallback chunk size if one-shot fails
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
local writefile_fn    = rawget(ENV, "writefile")         or writefile
local makefolder_fn   = rawget(ENV, "makefolder")        or makefolder
local isfolder_fn     = rawget(ENV, "isfolder")          or isfolder

local REMOTE_CLASSES = {
    RemoteEvent           = { call = "FireServer",   server = true  },
    UnreliableRemoteEvent = { call = "FireServer",   server = true  },
    RemoteFunction        = { call = "InvokeServer", server = true  },
    BindableEvent         = { call = "Fire",         server = false },
    BindableFunction      = { call = "Invoke",       server = false },
}

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = 6 })
    end)
end

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
    return (s:gsub(".", function(c) return string.format("%02x", string.byte(c)) end))
end
local function lower(s) return (tostring(s):lower()) end

local function isIgnoredPath(path)
    local p = lower(path)
    for _, root in ipairs(CONFIG.IgnoreRoots) do
        local r = lower(root)
        if p == r or p:sub(1, #r + 1) == r .. "." then return true end
    end
    return false
end

local function looksFailed(src)
    if not src then return true end
    local head = lower(src:sub(1, 300))
    return head:find("failed to get script bytecode", 1, true) ~= nil
        or head:find("failed to decompile", 1, true) ~= nil
        or head:find("decompilation failed", 1, true) ~= nil
        or head:find("could not decompile", 1, true) ~= nil
        or head:find("script is protected", 1, true) ~= nil
end

-- Build a copy-pasteable indexed reference (bracket-safe) for a remote.
local function pathExpr(inst)
    local parts, cur = {}, inst
    while cur and cur ~= game do
        local name = cur.Name
        if name:match("^[%a_][%w_]*$") then
            table.insert(parts, 1, "." .. name)
        else
            table.insert(parts, 1, ('["%s"]'):format(name:gsub('"', '\\"')))
        end
        local okp, p = pcall(function() return cur.Parent end)
        if not okp then break end
        cur = p
    end
    if #parts == 0 then return "nil" end
    local first = parts[1]:gsub("^%.", "")
    parts[1] = ('game:GetService("%s")'):format(first)
    return table.concat(parts)
end

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
    local ok, src = pcall(function() return scr.Source end)
    if ok and type(src) == "string" and #src > 0 then return src, "Source" end
    if getbytecode_fn then
        local okb, bc = pcall(getbytecode_fn, scr)
        if okb and type(bc) == "string" and #bc > 0 then
            return (CONFIG.BytecodeAsHex and toHex(bc) or bc), "bytecode(" .. #bc .. "b)"
        end
    end
    return nil, "unavailable"
end

-- ── Collect everything in one pass ────────────────────────
local function collectAll()
    local seen = {}
    local scripts, remotes = {}, {}
    local n = 0
    local function consider(inst)
        if not inst or seen[inst] then return end
        seen[inst] = true
        n = n + 1
        if n % 2000 == 0 then task.wait() end
        local ok, cn = pcall(function() return inst.ClassName end)
        if not ok then return end
        if REMOTE_CLASSES[cn] then
            if CONFIG.IncludeBindables or REMOTE_CLASSES[cn].server then
                remotes[#remotes + 1] = { obj = inst, cn = cn, info = REMOTE_CLASSES[cn] }
            end
        end
        local oks, isSrc = pcall(function() return inst:IsA("LuaSourceContainer") end)
        if oks and isSrc then scripts[#scripts + 1] = inst end
    end

    local ok, desc = pcall(function() return game:GetDescendants() end)
    if ok then for _, obj in ipairs(desc) do consider(obj) end end

    if CONFIG.IncludeNil and getnil_fn then
        local okn, nils = pcall(getnil_fn)
        if okn and type(nils) == "table" then
            for _, obj in ipairs(nils) do
                consider(obj)
                pcall(function() for _, d in ipairs(obj:GetDescendants()) do consider(d) end end)
            end
        end
    end
    if CONFIG.UseGetScripts and getscripts_fn then
        local okg, list = pcall(getscripts_fn)
        if okg and type(list) == "table" then for _, scr in ipairs(list) do consider(scr) end end
    end
    return scripts, remotes
end

local function safeFilePath(path, ext)
    local segs = {}
    for seg in tostring(path):gmatch("[^%.]+") do
        seg = seg:gsub('[<>:"/\\|%?%*]', "_"):gsub("%s+$", "")
        if seg == "" then seg = "_" end
        segs[#segs + 1] = seg
    end
    local dir = CONFIG.OutputFolder .. "/code"
    if makefolder_fn then
        local acc = ""
        for _, part in ipairs({ CONFIG.OutputFolder, "code" }) do
            acc = acc == "" and part or (acc .. "/" .. part)
            pcall(function() if isfolder_fn and not isfolder_fn(acc) then makefolder_fn(acc) end end)
        end
        for i = 1, #segs - 1 do
            dir = dir .. "/" .. segs[i]
            pcall(function() if isfolder_fn and not isfolder_fn(dir) then makefolder_fn(dir) end end)
        end
    end
    return dir .. "/" .. (segs[#segs] or "script") .. ext
end

-- Copy the whole thing; if the executor rejects a huge write, chunk it.
local function copyAll(text)
    if not setclipboard_fn then
        notify("GameFullDumper", "No clipboard fn - use the saved files")
        return
    end
    local safe = text:gsub("%z", "?")
    if pcall(setclipboard_fn, safe) then
        notify("GameFullDumper", ("Copied EVERYTHING to clipboard! (%d chars)"):format(#safe))
        return
    end
    -- Fallback: chunked copy with ] to advance.
    local chunks = {}
    for i = 1, #safe, CONFIG.ChunkSize do chunks[#chunks + 1] = safe:sub(i, i + CONFIG.ChunkSize - 1) end
    local cur = 1
    local function copyChunk(i)
        pcall(setclipboard_fn, ("-- chunk %d/%d\n"):format(i, #chunks) .. chunks[i])
        notify("GameFullDumper", ("Copied chunk %d/%d - paste, then press ] for next"):format(i, #chunks))
    end
    copyChunk(cur)
    getgenv_fn().GameFullDumper_NextChunk = function()
        if cur < #chunks then cur = cur + 1 end; copyChunk(cur)
    end
    local okUIS, UIS = pcall(function() return game:GetService("UserInputService") end)
    if okUIS and UIS then
        UIS.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.RightBracket then
                if cur < #chunks then cur = cur + 1 end; copyChunk(cur)
            elseif input.KeyCode == Enum.KeyCode.LeftBracket then
                if cur > 1 then cur = cur - 1 end; copyChunk(cur)
            end
        end)
    end
end

-- ── Run ───────────────────────────────────────────────────
local function run()
    local placeName = "Game"
    pcall(function()
        placeName = ("%s (PlaceId %s, JobId %s)"):format(
            game.Name ~= "" and game.Name or "Game",
            tostring(game.PlaceId), tostring(game.JobId))
    end)

    notify("GameFullDumper", "Scanning whole game for remotes & code...")
    local scripts, remotes = collectAll()

    -- Filter internals.
    local keptScripts, keptRemotes, skipped = {}, {}, 0
    for _, r in ipairs(remotes) do
        local path = fullPath(r.obj)
        if isIgnoredPath(path) then skipped = skipped + 1
        else r.path = path; keptRemotes[#keptRemotes + 1] = r end
    end
    for _, s in ipairs(scripts) do
        local path = fullPath(s)
        if not isIgnoredPath(path) then keptScripts[#keptScripts + 1] = { obj = s, path = path } end
    end
    table.sort(keptRemotes, function(a, b) return a.path < b.path end)
    table.sort(keptScripts, function(a, b) return a.path < b.path end)

    if makefolder_fn then
        pcall(function() if isfolder_fn and not isfolder_fn(CONFIG.OutputFolder) then makefolder_fn(CONFIG.OutputFolder) end end)
    end

    -- ── SECTION 1: remotes ──
    local out = {}
    out[#out + 1] = "============================================================"
    out[#out + 1] = "  GameFullDumper  –  remotes + all client-reachable code"
    out[#out + 1] = "  " .. placeName
    out[#out + 1] = "  Remotes: " .. #keptRemotes .. "  |  Scripts: " .. #keptScripts
    out[#out + 1] = "  Generated: " .. os.date("!%Y-%m-%d %H:%M:%S UTC")
    out[#out + 1] = "  NOTE: true server Scripts (ServerScriptService/ServerStorage)"
    out[#out + 1] = "  are never sent to the client and cannot be dumped."
    out[#out + 1] = "============================================================\n"

    out[#out + 1] = ("##### REMOTES (%d) #####"):format(#keptRemotes)
    if #keptRemotes == 0 then out[#out + 1] = "  (none found)" end
    for i, r in ipairs(keptRemotes) do
        out[#out + 1] = ("[%d] (%s)  %s"):format(i, r.cn, r.path)
        if CONFIG.ShowSnippets then out[#out + 1] = ("    %s:%s()"):format(pathExpr(r.obj), r.info.call) end
    end
    out[#out + 1] = ""

    -- ── SECTION 2: code ──
    out[#out + 1] = ("##### SCRIPTS (%d) #####\n"):format(#keptScripts)
    local ops, done, failed = 0, 0, 0
    local function breathe()
        ops = ops + 1
        if CONFIG.YieldEvery > 0 and ops % CONFIG.YieldEvery == 0 then task.wait() end
    end
    for i, s in ipairs(keptScripts) do
        local cn = "Script"; pcall(function() cn = s.obj.ClassName end)
        local code, method
        if done < CONFIG.MaxDecompiles then
            code, method = getScriptCode(s.obj); breathe(); done = done + 1
            if not code then failed = failed + 1 end
        else
            method = "skipped (decompile cap reached)"
        end
        local body = code or ("-- code unavailable (protected/empty/server-side) [via " .. tostring(method) .. "]")
        out[#out + 1] = "------------------------------------------------------------"
        out[#out + 1] = ("[%d] %s  (%s)  [via %s]"):format(i, s.path, cn, tostring(method))
        out[#out + 1] = "------------------------------------------------------------"
        out[#out + 1] = body
        out[#out + 1] = ""
        if CONFIG.SavePerScript and writefile_fn then
            local isHex = method and method:find("bytecode")
            pcall(writefile_fn, safeFilePath(s.path, isHex and ".bytecode.hex" or ".lua"), body)
        end
    end

    local text = table.concat(out, "\n")

    -- ── Output ──
    if CONFIG.SaveCombined and writefile_fn then
        pcall(writefile_fn, ("%s/_ALL_%s.txt"):format(CONFIG.OutputFolder, tostring(game.PlaceId)), text)
    end
    if CONFIG.CopyClipboard then copyAll(text) end

    print(text)
    print(("[GameFullDumper] Done. Remotes: %d | Scripts: %d (dumped %d, failed %d) | internal-skipped: %d | %d chars.")
        :format(#keptRemotes, #keptScripts, done, failed, skipped, #text))
    return text
end

local ok, err = pcall(run)
if not ok then
    warn("[GameFullDumper] Error: " .. tostring(err))
    notify("GameFullDumper", "Error: " .. tostring(err))
end
