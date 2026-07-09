-- ferret/run_tests.lua
-- Validates the obfuscation pipeline against a corpus of Lua programs.
--
-- Usage:
--   lua ferret/run_tests.lua <suite_dir> [--seed N] [--layers a,b,c] [--limit N]
--   lua ferret/run_tests.lua <suite_dir> --roundtrip   (emit only, no obfuscation)
--
-- For each program it runs the original twice; if the two runs disagree the
-- program is inherently non-deterministic and is reported as SKIP (we cannot
-- meaningfully diff it). Otherwise it obfuscates the program and checks the
-- obfuscated output matches the original exactly.

local here = arg[0]:match("^(.*)/[^/]*$") or "."
package.path = here .. "/?.lua;" .. package.path

local Ferret = require("ferret")

local suite = arg[1]
if not suite then
    io.stderr:write("usage: lua run_tests.lua <suite_dir> [options]\n")
    os.exit(2)
end

local opts = { seed = 1, layers = nil, roundtrip = false, limit = nil, verbose = false }
local i = 2
while arg[i] do
    local a = arg[i]
    if a == "--roundtrip" then opts.roundtrip = true
    elseif a == "--verbose" then opts.verbose = true
    elseif a == "--seed" then i = i + 1; opts.seed = tonumber(arg[i])
    elseif a == "--limit" then i = i + 1; opts.limit = tonumber(arg[i])
    elseif a == "--layers" then i = i + 1; opts.layers = {}
        for l in arg[i]:gmatch("[^,]+") do opts.layers[#opts.layers + 1] = l end
    end
    i = i + 1
end

local LUA = os.getenv("LUA_BIN") or "lua5.4"

local function listLuaFiles(dir)
    local files = {}
    local p = io.popen("find '" .. dir .. "' -type f -name '*.lua' | sort")
    for line in p:lines() do files[#files + 1] = line end
    p:close()
    return files
end

local function readFile(path)
    local f = io.open(path, "rb"); if not f then return nil end
    local s = f:read("*a"); f:close(); return s
end

local function writeFile(path, data)
    local f = assert(io.open(path, "wb")); f:write(data); f:close()
end

-- Run a lua file, capture combined stdout+stderr and exit status.
local function runLua(path)
    local cmd = LUA .. " '" .. path .. "' 2>&1"
    local p = io.popen(cmd)
    local out = p:read("*a")
    local ok, kind, code = p:close()
    return out, code or 0
end

-- Error tracebacks embed the chunk path and line numbers, both of which
-- legitimately change under obfuscation (temp filename + minified lines).
-- Normalize them so the harness compares program semantics, not tracebacks.
local function normalize(s)
    s = s:gsub("%S*%.lua", "CHUNK")
    s = s:gsub("CHUNK:%d+", "CHUNK:L")
    -- The pack loader runs the chunk via a tail call, which adds a structural
    -- "(...tail calls...)" frame to tracebacks. Strip it like a line number.
    s = s:gsub("%s*%(%.%.%.tail calls%.%.%.%)\n?", "\n")
    return s
end

local TMP = os.getenv("TMPDIR") or "/tmp"
local tmpObf = TMP .. "/ferret_obf_" .. tostring(os.time()) .. ".lua"

local files = listLuaFiles(suite)
local total, pass, fail, skip, obfErr = 0, 0, 0, 0, 0
local failures = {}

for _, path in ipairs(files) do
    if opts.limit and total >= opts.limit then break end
    total = total + 1

    local src = readFile(path)
    local out1 = normalize(runLua(path))
    local out2 = normalize(runLua(path))

    if out1 ~= out2 then
        skip = skip + 1
        if opts.verbose then print("SKIP (nondeterministic): " .. path) end
    else
        local obf
        local okc, e = pcall(function()
            if opts.roundtrip then
                obf = Ferret.roundtrip(src)
            else
                obf = Ferret.obfuscate(src, { seed = opts.seed, layers = opts.layers, chunkname = path })
            end
        end)
        if not okc then
            obfErr = obfErr + 1
            fail = fail + 1
            failures[#failures + 1] = { path = path, reason = "OBFUSCATE ERROR: " .. tostring(e) }
        else
            writeFile(tmpObf, obf)
            local outObf = normalize(runLua(tmpObf))
            if outObf == out1 then
                pass = pass + 1
                if opts.verbose then print("PASS: " .. path) end
            else
                fail = fail + 1
                failures[#failures + 1] = {
                    path = path,
                    reason = "OUTPUT MISMATCH",
                    expected = out1,
                    got = outObf,
                }
            end
        end
    end
end

print(string.rep("=", 60))
print(string.format("Corpus: %s", suite))
print(string.format("Mode: %s   Seed: %s   Layers: %s",
    opts.roundtrip and "roundtrip" or "obfuscate",
    tostring(opts.seed),
    opts.layers and table.concat(opts.layers, ",") or "(default)"))
print(string.format("Total: %d   Pass: %d   Fail: %d   Skip(nondeterministic): %d   ObfErrors: %d",
    total, pass, fail, skip, obfErr))
local denom = pass + fail
if denom > 0 then
    print(string.format("Pass rate (of comparable): %.1f%%", 100 * pass / denom))
end
print(string.rep("=", 60))

if #failures > 0 then
    print("\nFAILURES (first 25):")
    for k = 1, math.min(25, #failures) do
        local f = failures[k]
        print("  " .. f.path .. "  -- " .. f.reason)
        if f.expected and opts.verbose then
            print("    expected: " .. (f.expected:gsub("\n", "\\n")):sub(1, 200))
            print("    got     : " .. (f.got:gsub("\n", "\\n")):sub(1, 200))
        end
    end
end

os.remove(tmpObf)
os.exit(fail == 0 and 0 or 1)
