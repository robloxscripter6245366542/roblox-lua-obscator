-- ============================================================
--  Deobfuscator.lua  –  Split + classify + beautify a code dump
--
--  Feed it a GameCodeDumper / GameFullDumper / ServerRecon dump (the
--  big _ALL_*.txt or the "Jjs" file) and it will:
--
--    1. SPLIT   the one giant blob back into one file per script,
--               in a folder tree — so you get 900+ readable files
--               instead of a 7 MB wall of text.
--    2. CLASSIFY each script:
--                 clean       – ordinary decompiled Lua (readable)
--                 vm          – VM-obfuscated (Luraph-style) blob
--                 unavailable – protected / empty at dump time
--    3. BEAUTIFY the CLEAN ones: consistent re-indentation, collapse
--               runaway blank lines, and normalise decompiler noise.
--    4. MANIFEST everything to _index.txt so you can jump straight to
--               the real code and skip the VM blobs.
--
--  Honest scope: this makes readable code readable and TELLS YOU which
--  files are VM blobs. It does NOT devirtualise Luraph — that needs a
--  per-VM lifter, not a text pass. Nothing here pretends otherwise.
--
--  Run inside an executor (uses readfile/writefile/makefolder).
-- ============================================================

-- ── Config ────────────────────────────────────────────────
local CONFIG = {
    InputFile    = "Jjs",              -- the dump to process (readfile path)
    OutputFolder = "Deobf",            -- where cleaned files are written
    Reindent     = true,               -- re-indent the clean scripts
    IndentStr    = "    ",             -- 4 spaces per level
    MaxBlankRun  = 1,                  -- collapse >N consecutive blank lines
    YieldEvery   = 30,                 -- keep the client responsive
}
-- ──────────────────────────────────────────────────────────

local getgenv_fn   = getgenv or function() return _G end
local ENV          = getgenv_fn()
local readfile_fn  = rawget(ENV, "readfile")   or readfile
local writefile_fn = rawget(ENV, "writefile")  or writefile
local makefolder_fn= rawget(ENV, "makefolder") or makefolder
local isfolder_fn  = rawget(ENV, "isfolder")   or isfolder
local StarterGui   = game:GetService("StarterGui")

local function notify(text)
    print("[Deobfuscator] " .. text)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = "Deobfuscator", Text = text, Duration = 6 })
    end)
end

if not readfile_fn then return notify("This executor has no readfile - can't load the dump.") end
if not writefile_fn then return notify("This executor has no writefile - nowhere to save output.") end

-- ── Load the dump ─────────────────────────────────────────
local ok, blob = pcall(readfile_fn, CONFIG.InputFile)
if not ok or type(blob) ~= "string" or #blob == 0 then
    return notify("Couldn't read '" .. CONFIG.InputFile .. "'. Run GameCodeDumper first, or set CONFIG.InputFile.")
end

-- ── Split into entries ────────────────────────────────────
-- Header line looks like:  [12] Some.Path  (ClassName)  [via decompile]
local function splitEntries(text)
    local entries = {}
    local lines = {}
    for line in (text .. "\n"):gmatch("(.-)\n") do lines[#lines + 1] = line end

    local cur = nil
    local i = 1
    while i <= #lines do
        local line = lines[i]
        local idx, path, class, method =
            line:match("^%[(%d+)%]%s+(.-)%s+%((.-)%)%s+%[via%s+(.-)%]%s*$")
        if idx then
            if cur then entries[#entries + 1] = cur end
            cur = { idx = tonumber(idx), path = path, class = class, method = method, body = {} }
            -- Drop the delimiter line that usually follows the header.
            if lines[i + 1] and lines[i + 1]:match("^%-%-%-%-+$") then i = i + 1 end
        elseif cur then
            -- Skip pure delimiter lines around headers.
            if not line:match("^%=%=%=%=+$") then
                cur.body[#cur.body + 1] = line
            end
        end
        i = i + 1
    end
    if cur then entries[#entries + 1] = cur end
    return entries
end

-- ── Classify ──────────────────────────────────────────────
local function classify(entry)
    if entry.method == "unavailable" or #entry.body == 0 then return "unavailable" end
    local body = table.concat(entry.body, "\n")
    if body:match("^%s*%-%- code unavailable") then return "unavailable" end
    if entry.method:find("bytecode") then return "vm" end
    -- VM heuristic: lots of numbered register writes like p6[36] = ...
    local regHits = 0
    for _ in body:gmatch("[%a_][%w_]*%[%d+%]%s*=") do regHits = regHits + 1 end
    local dispatch = body:find("task%.spawn%(function%(%.%.%.%)") and body:find("repeat") and body:find("until")
    if regHits > 25 or (dispatch and regHits > 8) then return "vm" end
    return "clean"
end

-- ── Beautify: strip strings/comments per line, track depth ─
-- Remove quoted spans and line comments so brace/keyword counting is safe.
local function stripCode(line)
    line = line:gsub('"[^"]*"', '""'):gsub("'[^']*'", "''")
    line = line:gsub("%-%-.*$", "")
    return line
end

local OPENERS = { ["then"] = true, ["do"] = true, ["function"] = true, ["repeat"] = true }
local function reindent(bodyLines)
    local out, depth = {}, 0
    local inLong = false                 -- inside a [[ ... ]] long string/comment
    for _, raw in ipairs(bodyLines) do
        local line = raw:gsub("^%s+", ""):gsub("%s+$", "")
        if inLong then
            out[#out + 1] = raw          -- leave long-string interiors untouched
            if line:find("%]%]") then inLong = false end
        else
            local code = stripCode(line)
            -- Dedent when the line *starts* with a closer.
            if code:match("^end") or code:match("^else") or code:match("^elseif")
               or code:match("^until") or code:match("^[%)%}%]]") then
                depth = math.max(0, depth - 1)
            end
            out[#out + 1] = (line == "") and "" or (CONFIG.IndentStr:rep(depth) .. line)

            -- Net opener/closer delta on the rest of the line.
            local opens = 0
            for w in code:gmatch("[%a_]+") do if OPENERS[w] then opens = opens + 1 end end
            -- 'function' followed later by 'end' already counted; parens/braces:
            local _, po = code:gsub("[%({%[]", "")
            local _, pc = code:gsub("[%)}%]]", "")
            local _, ends = code:gsub("%f[%a]end%f[%A]", "")
            -- elseif/else keep depth net-zero (we dedented, now re-indent once)
            if code:match("^else") or code:match("^elseif") then depth = depth + 1 end
            local delta = opens + po - pc - ends
            -- 'repeat'..'until' handled by opener + closer keyword
            if code:match("^until") then delta = delta end
            depth = math.max(0, depth + delta)
            if code:find("%[%[") and not code:find("%]%]") then inLong = true end
        end
    end
    return out
end

local function collapseBlanks(lines)
    local out, run = {}, 0
    for _, l in ipairs(lines) do
        if l:match("^%s*$") then
            run = run + 1
            if run <= CONFIG.MaxBlankRun then out[#out + 1] = "" end
        else
            run = 0
            out[#out + 1] = l
        end
    end
    return out
end

-- ── Safe on-disk path ─────────────────────────────────────
local function ensureFolders(segs)
    local dir = CONFIG.OutputFolder
    pcall(function() if isfolder_fn and not isfolder_fn(dir) then makefolder_fn(dir) end end)
    for i = 1, #segs - 1 do
        dir = dir .. "/" .. segs[i]
        pcall(function() if isfolder_fn and not isfolder_fn(dir) then makefolder_fn(dir) end end)
    end
    return dir
end
local function safePath(path, cls, ext)
    local segs = {}
    for seg in tostring(path):gmatch("[^%.]+") do
        seg = seg:gsub('[<>:"/\\|%?%*]', "_"):gsub("%s+$", "")
        segs[#segs + 1] = seg ~= "" and seg or "_"
    end
    -- Group by class of result so VM blobs are easy to skip.
    table.insert(segs, 1, cls)
    local dir = ensureFolders(segs)
    return dir .. "/" .. (segs[#segs] or "script") .. ext
end

-- ── Run ───────────────────────────────────────────────────
local function run()
    notify("Reading & splitting '" .. CONFIG.InputFile .. "' (" .. #blob .. " bytes)...")
    local entries = splitEntries(blob)
    notify("Found " .. #entries .. " scripts. Cleaning...")

    local counts = { clean = 0, vm = 0, unavailable = 0 }
    local manifest = { "# Deobfuscator index  (" .. #entries .. " scripts)", "" }

    for n, e in ipairs(entries) do
        local cls = classify(e)
        counts[cls] = counts[cls] + 1

        local bodyLines = e.body
        if cls == "clean" and CONFIG.Reindent then
            local okB, res = pcall(reindent, bodyLines)
            if okB then bodyLines = res end
        end
        bodyLines = collapseBlanks(bodyLines)

        local header = ("-- %s  (%s)  [%s | via %s]\n\n"):format(e.path, e.class, cls, e.method)
        local ext = (cls == "vm") and ".vm.lua" or (cls == "unavailable") and ".missing.lua" or ".lua"
        pcall(writefile_fn, safePath(e.path, cls, ext), header .. table.concat(bodyLines, "\n"))

        manifest[#manifest + 1] = ("[%s] %s  (%s)"):format(cls:upper():sub(1, 5), e.path, e.class)

        if n % CONFIG.YieldEvery == 0 then task.wait() end
    end

    manifest[#manifest + 1] = ""
    manifest[#manifest + 1] = ("Totals: clean=%d  vm=%d  unavailable=%d")
        :format(counts.clean, counts.vm, counts.unavailable)
    pcall(writefile_fn, CONFIG.OutputFolder .. "/_index.txt", table.concat(manifest, "\n"))

    notify(("Done. clean=%d  vm=%d  unavailable=%d  ->  /%s")
        :format(counts.clean, counts.vm, counts.unavailable, CONFIG.OutputFolder))
    print(("[Deobfuscator] Wrote %d files. Read /%s/_index.txt first; the CLEAN ones are your real code.")
        :format(#entries, CONFIG.OutputFolder))
end

local okRun, err = pcall(run)
if not okRun then warn("[Deobfuscator] Error: " .. tostring(err)); notify("Error: " .. tostring(err)) end
