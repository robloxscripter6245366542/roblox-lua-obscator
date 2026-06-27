-- Crystal Script Analyzer & Auto-Fixer
-- Before obfuscating or running a script, Crystal:
--   1. Scans for what features it already uses (HTTP, pcall, etc.)
--   2. Injects missing features only if they aren't already present
--   3. Auto-fixes common Lua bugs so broken scripts become runnable

local Analyzer = {}
Analyzer.__index = Analyzer

-- ── Feature detection ─────────────────────────────────────────────────────────

local FEATURE_PATTERNS = {
    https       = { "HttpService", "HttpGet", "HttpPost", "RequestAsync", "GetAsync",
                    "http://", "https://", "request%(", "HTTP%.get", "HTTP%.post" },
    pcall       = { "pcall%s*%(", "xpcall%s*%(" },
    coroutine   = { "coroutine%.", "task%.spawn", "task%.defer" },
    events      = { "%.Connect%(", "%.Once%(", "RBXScriptConnection" },
    remotes     = { "RemoteEvent", "RemoteFunction", "BindableEvent" },
    datastore   = { "DataStoreService", "GetDataStore", "SetAsync", "GetAsync" },
    ui          = { "ScreenGui", "Frame", "TextLabel", "TextButton", "ImageLabel" },
    tween       = { "TweenService", "TweenInfo", "TweenInfo%.new" },
    physics     = { "BodyVelocity", "BodyForce", "VectorForce", "LinearVelocity" },
    animation   = { "Animator", "AnimationTrack", "LoadAnimation" },
}

function Analyzer.detectFeatures(src)
    local found = {}
    for feature, patterns in pairs(FEATURE_PATTERNS) do
        for _, pat in ipairs(patterns) do
            if src:find(pat) then
                found[feature] = true
                break
            end
        end
    end
    return found
end

-- Check if a specific string/pattern is already present
function Analyzer.hasFeature(src, feature)
    local patterns = FEATURE_PATTERNS[feature]
    if not patterns then return false end
    for _, pat in ipairs(patterns) do
        if src:find(pat) then return true end
    end
    return false
end

-- ── HTTP injection ────────────────────────────────────────────────────────────
-- Only injects if HTTP isn't already present in the script.

local HTTP_ROBLOX_STUB = [[
-- [Crystal] HTTPS auto-injected
local _CrystalHTTP = (function()
    local hs = game:GetService("HttpService")
    local function _req(method, url, opts)
        opts = opts or {}
        local ok, res = pcall(function()
            return hs:RequestAsync({
                Url     = url,
                Method  = method,
                Headers = opts.headers or {["Content-Type"]="application/json"},
                Body    = opts.body and (type(opts.body)=="table" and hs:JSONEncode(opts.body) or tostring(opts.body)) or nil,
            })
        end)
        if not ok then return {ok=false,status=0,body=nil,error=tostring(res)} end
        local body = res.Body
        if body and (res.Headers["Content-Type"] or ""):find("application/json") then
            local jok,j=pcall(function()return hs:JSONDecode(body)end)
            if jok then body=j end
        end
        return {ok=res.Success,status=res.StatusCode,headers=res.Headers,body=body,raw=res.Body}
    end
    return {
        get    = function(u,o)      return _req("GET",u,o)          end,
        post   = function(u,b,o)    o=o or{};o.body=b;return _req("POST",u,o) end,
        put    = function(u,b,o)    o=o or{};o.body=b;return _req("PUT",u,o)  end,
        delete = function(u,o)      return _req("DELETE",u,o)       end,
        json   = function(u,o)
            local r=_req("GET",u,o)
            if type(r.body)=="table" then return r.body end
            local ok2,j=pcall(function()return hs:JSONDecode(r.raw or "")end)
            return ok2 and j or nil
        end,
        encode = function(t) return hs:JSONEncode(t) end,
        decode = function(s) return hs:JSONDecode(s) end,
    }
end)()
]]

function Analyzer.injectHTTPS(src)
    -- Don't inject if already present
    if Analyzer.hasFeature(src, "https") then
        return src, false  -- unchanged, already has HTTP
    end
    return HTTP_ROBLOX_STUB .. "\n" .. src, true  -- injected
end

-- ── Auto-fixer ────────────────────────────────────────────────────────────────
-- Fixes common Lua/Crystal scripting mistakes automatically.

local function countOccurrences(s, pattern)
    local count = 0
    for _ in s:gmatch(pattern) do count = count + 1 end
    return count
end

local FIXES = {}

-- Fix 1: Missing 'end' for if/for/while/do/function blocks
table.insert(FIXES, {
    name = "balance_ends",
    fix = function(src)
        -- Count openers vs closers
        local opens  = countOccurrences(src, "%f[%w]if%f[%W]")
                     + countOccurrences(src, "%f[%w]for%f[%W]")
                     + countOccurrences(src, "%f[%w]while%f[%W]")
                     + countOccurrences(src, "%f[%w]do%f[%W]")
                     + countOccurrences(src, "%f[%w]function%f[%W]")
                     + countOccurrences(src, "%f[%w]repeat%f[%W]")
        local ends   = countOccurrences(src, "%f[%w]end%f[%W]")
                     + countOccurrences(src, "%f[%w]until%f[%W]")
        -- then/else don't count as openers (they're already inside if)
        local thens  = countOccurrences(src, "%f[%w]then%f[%W]")
                     + countOccurrences(src, "%f[%w]else%f[%W]")
                     + countOccurrences(src, "%f[%w]elseif%f[%W]")
        opens = opens - thens  -- adjust: then/else don't open new blocks

        local diff = opens - ends
        if diff > 0 then
            src = src .. ("\nend"):rep(diff)
        end
        return src, diff > 0
    end,
})

-- Fix 2: Replace common typos in Roblox API names
local TYPO_MAP = {
    ["Players.LocalPlayers"]    = "Players.LocalPlayer",
    ["game%.Workspace"]         = "workspace",
    ["Game%.Players"]           = "game.Players",
    ["workspace.CurrentCamera"] = "workspace.CurrentCamera",
    ["HumanoidRootPart%.CFrame"] = "HumanoidRootPart.CFrame",
    ["charater"]                = "character",
    ["Charater"]                = "Character",
    ["Humaniod"]                = "Humanoid",
    ["LocalScipt"]              = "LocalScript",
    ["Scipt"]                   = "Script",
    ["primt"]                   = "print",
    ["prnit"]                   = "print",
    ["lcoal"]                   = "local",
    ["fucntion"]                = "function",
    ["functoin"]                = "function",
    ["retrun"]                  = "return",
    ["ture"]                    = "true",
    ["flase"]                   = "false",
}
table.insert(FIXES, {
    name = "typo_corrections",
    fix = function(src)
        local changed = false
        for wrong, right in pairs(TYPO_MAP) do
            local new = src:gsub(wrong, right)
            if new ~= src then changed = true; src = new end
        end
        return src, changed
    end,
})

-- Fix 3: Unclosed string literals (basic heuristic)
table.insert(FIXES, {
    name = "unclosed_strings",
    fix = function(src)
        local lines    = {}
        local changed  = false
        for line in (src .. "\n"):gmatch("([^\n]*)\n") do
            -- Count unescaped quotes; if odd, close the string
            local function countQ(s, q)
                local n = 0
                local i = 1
                while i <= #s do
                    if s:sub(i,i) == "\\" then i=i+2
                    elseif s:sub(i,i) == q then n=n+1; i=i+1
                    else i=i+1 end
                end
                return n
            end
            -- Strip comments first
            local stripped = line:gsub("%-%-.*$","")
            local dq = countQ(stripped, '"')
            local sq = countQ(stripped, "'")
            if dq % 2 ~= 0 then line = line .. '"';  changed = true end
            if sq % 2 ~= 0 then line = line .. "'";  changed = true end
            lines[#lines+1] = line
        end
        return table.concat(lines, "\n"), changed
    end,
})

-- Fix 4: Replace print() with no args → print("")
table.insert(FIXES, {
    name = "empty_print",
    fix = function(src)
        local new = src:gsub("print%(%s*%)", 'print("")')
        return new, new ~= src
    end,
})

-- Fix 5: local x = nil followed immediately by x = value → collapse
table.insert(FIXES, {
    name = "collapse_nil_init",
    fix = function(src)
        local new = src:gsub(
            "local%s+([%w_]+)%s*=%s*nil%s*\n(%s*)%1%s*=",
            function(name, indent)
                return ("local %s =\n%s%s ="):format(name, indent, name)
            end
        )
        return new, new ~= src
    end,
})

-- Fix 6: Remove duplicate requires
table.insert(FIXES, {
    name = "dedupe_requires",
    fix = function(src)
        local seen    = {}
        local changed = false
        local out     = {}
        for line in (src .. "\n"):gmatch("([^\n]*)\n") do
            local req = line:match("require%s*%((.-)%)")
            if req then
                if seen[req] then
                    changed = true
                    -- comment it out
                    out[#out+1] = "-- [Crystal auto-fixed duplicate require] " .. line
                else
                    seen[req] = true
                    out[#out+1] = line
                end
            else
                out[#out+1] = line
            end
        end
        return table.concat(out, "\n"), changed
    end,
})

-- Fix 7: Roblox: wrap top-level yields in task.spawn (prevent threading issues)
table.insert(FIXES, {
    name = "wrap_top_yields",
    fix = function(src)
        -- Only if script uses wait() at top level but not inside functions
        if src:find("^wait%(") or src:find("\nwait%(") then
            if not src:find("task%.spawn") then
                -- Simple check: if first statement is wait, wrap all in spawn
                local changed = false
                src = src:gsub("^wait%(", "task.wait(")
                src = src:gsub("\nwait%(", "\ntask.wait(")
                return src, changed
            end
        end
        return src, false
    end,
})

-- Fix 8: Convert legacy wait() → task.wait()
table.insert(FIXES, {
    name = "modernize_wait",
    fix = function(src)
        local new = src:gsub("%f[%w]wait%(", "task.wait(")
        return new, new ~= src
    end,
})

-- Fix 9: Convert spawn() → task.spawn()
table.insert(FIXES, {
    name = "modernize_spawn",
    fix = function(src)
        local new = src:gsub("%f[%w]spawn%(", "task.spawn(")
        return new, new ~= src
    end,
})

-- Fix 10: Wrap entire script in pcall if it has no error handling at all
table.insert(FIXES, {
    name = "add_error_wrapper",
    fix = function(src)
        if src:find("pcall") or src:find("xpcall") then return src, false end
        -- Don't wrap if it's already a module (returns something at top level)
        if src:match("^return%s") then return src, false end
        local new = ([[
local __ok, __err = pcall(function()
%s
end)
if not __ok then
    warn("[Crystal] Script error: " .. tostring(__err))
end]]):format(src)
        return new, true
    end,
})

-- ── Polyglot converter: JSON / JS / other languages → Lua ────────────────────
-- If the script contains JSON objects, JS arrow functions, JS-style code, etc.
-- Crystal converts them automatically so the script still works in Lua.

local PolyConvert = {}

-- Convert a JSON value (string) to its Lua literal equivalent
local function jsonValueToLua(v)
    v = v:match("^%s*(.-)%s*$") -- trim
    if v == "true"  then return "true"
    elseif v == "false" then return "false"
    elseif v == "null"  then return "nil"
    elseif v:match("^%-?%d+%.?%d*$") then return v  -- number
    elseif v:sub(1,1) == '"' then
        -- string: convert to Lua single-quoted or double-quoted
        return v  -- JSON strings are already valid Lua strings
    end
    return v
end

-- Convert JSON object { "key": value, ... } to Lua table { key = value, ... }
local function jsonObjectToLua(json)
    local result = {}
    -- Strip outer { }
    local inner = json:match("^%s*{(.+)}%s*$")
    if not inner then return json end

    -- Simple key:value parser (handles one level, not nested)
    for key, val in inner:gmatch('"([^"]+)"%s*:%s*([^,}]+)') do
        val = val:match("^%s*(.-)%s*$")
        result[#result+1] = ("[%q] = %s"):format(key, jsonValueToLua(val))
    end

    if #result == 0 then return json end
    return "{ " .. table.concat(result, ", ") .. " }"
end

-- Convert JSON array [ val, val, ... ] to Lua table { val, val, ... }
local function jsonArrayToLua(json)
    local inner = json:match("^%s*%[(.+)%]%s*$")
    if not inner then return json end
    local items = {}
    for val in (inner .. ","):gmatch("([^,]+),") do
        items[#items+1] = jsonValueToLua(val:match("^%s*(.-)%s*$"))
    end
    return "{ " .. table.concat(items, ", ") .. " }"
end

-- Detect and convert standalone JSON blocks embedded in Lua comments or strings
-- Pattern: -- json: { ... } or embedded as a variable assignment
function PolyConvert.convertJSON(src)
    local changed = false

    -- Pattern 1: local x = { "key": value } (JSON-style table assignment)
    local new = src:gsub('(local%s+%w+%s*=%s*)({[^{}]*"[^"]+"%s*:[^{}]*})', function(prefix, json)
        local converted = jsonObjectToLua(json)
        if converted ~= json then changed = true; return prefix .. converted end
        return prefix .. json
    end)
    if new ~= src then src = new end

    -- Pattern 2: JSON arrays used as assignments
    new = src:gsub('(local%s+%w+%s*=%s*)(%[[^%[%]]+%])', function(prefix, arr)
        -- Only if it contains comma-separated values (not Lua index access)
        if arr:find(",") then
            local converted = jsonArrayToLua(arr)
            if converted ~= arr then changed = true; return prefix .. converted end
        end
        return prefix .. arr
    end)
    if new ~= src then src = new end

    -- Pattern 3: null → nil (JSON null used outside strings)
    new = src:gsub("%f[%w]null%f[%W]", "nil")
    if new ~= src then changed = true; src = new end

    -- Pattern 4: true/false are already valid Lua, skip

    -- Pattern 5: JSON-style string keys in tables: {"key": val} → {["key"] = val}
    new = src:gsub('"([%w_]+)"%s*:', function(key)
        -- Only convert if it looks like a table key context (preceded by { or ,)
        changed = true
        return ("[%q] = "):format(key)
    end)
    if new ~= src then src = new end

    return src, changed
end

-- Convert JS arrow functions to Lua functions
-- x => x + 1  →  function(x) return x + 1 end
-- (x, y) => x + y  →  function(x, y) return x + y end
function PolyConvert.convertArrowFunctions(src)
    local changed = false

    -- (params) => expr
    local new = src:gsub("%(([^%)]+)%)%s*=>%s*([^\n,%)%]]+)", function(params, expr)
        expr = expr:match("^%s*(.-)%s*$")
        changed = true
        return ("function(%s) return %s end"):format(params, expr)
    end)
    if new ~= src then changed = true; src = new end

    -- single param => expr
    new = src:gsub("([%w_]+)%s*=>%s*([^\n,%)%]]+)", function(param, expr)
        if param == "then" or param == "else" or param == "end" or param == "do" then return end
        expr = expr:match("^%s*(.-)%s*$")
        changed = true
        return ("function(%s) return %s end"):format(param, expr)
    end)
    if new ~= src then changed = true; src = new end

    return src, changed
end

-- Convert JS console.log / Python print() style calls
function PolyConvert.convertPrintCalls(src)
    local changed = false
    -- console.log(...) → print(...)
    local new = src:gsub("console%.log%(", "print(")
    if new ~= src then changed = true; src = new end
    -- console.warn(...) → warn(...)
    new = src:gsub("console%.warn%(", "warn(")
    if new ~= src then changed = true; src = new end
    -- console.error(...) → warn(...)
    new = src:gsub("console%.error%(", "warn(")
    if new ~= src then changed = true; src = new end
    return src, changed
end

-- Convert JS-style variable declarations: var x = / const x = / let x =  → local x =
function PolyConvert.convertJSVars(src)
    local changed = false
    local new = src:gsub("%f[%w]var%s+([%w_]+)%s*=", function(name)
        changed = true
        return "local " .. name .. " ="
    end)
    if new ~= src then src = new end
    new = src:gsub("%f[%w]const%s+([%w_]+)%s*=", function(name)
        -- Only if it's not already "local const" — skip Lua keywords
        changed = true
        return "local " .. name .. " ="
    end)
    if new ~= src then changed = true; src = new end
    new = src:gsub("%f[%w]let%s+([%w_]+)%s*=", function(name)
        changed = true
        return "local " .. name .. " ="
    end)
    if new ~= src then changed = true; src = new end
    return src, changed
end

-- Convert JS === / !== → == / ~=
function PolyConvert.convertJSOperators(src)
    local changed = false
    local new = src:gsub("===", "==")
    if new ~= src then changed = true; src = new end
    new = src:gsub("!==", "~=")
    if new ~= src then changed = true; src = new end
    new = src:gsub("!=([^=])", "~=%1")
    if new ~= src then changed = true; src = new end
    -- JS && → and,  || → or,  ! → not
    new = src:gsub("&&", " and ")
    if new ~= src then changed = true; src = new end
    new = src:gsub("||", " or ")
    if new ~= src then changed = true; src = new end
    return src, changed
end

-- Convert Python-style string formatting: f"Hello {name}" → "Hello " .. tostring(name)
-- (Crystal already handles f-strings in its parser, this handles raw embedded ones)
function PolyConvert.convertFStrings(src)
    local changed = false
    local new = src:gsub('f"([^"]*)"', function(content)
        local parts = {}
        local last = 1
        for expr_start, expr, expr_end in content:gmatch("()%{([^}]+)%}()") do
            local literal = content:sub(last, expr_start - 1)
            if literal ~= "" then
                parts[#parts+1] = ('"' .. literal .. '"')
            end
            parts[#parts+1] = ("tostring(%s)"):format(expr)
            last = expr_end
        end
        local tail = content:sub(last)
        if tail ~= "" then parts[#parts+1] = ('"' .. tail .. '"') end
        if #parts == 0 then return '""' end
        changed = true
        return table.concat(parts, " .. ")
    end)
    if new ~= src then src = new end
    return src, changed
end

-- Master polyglot converter — run all conversions
function PolyConvert.convert(src)
    local log = {}
    local changed = false
    local function run(name, fn)
        local ok, result, c = pcall(fn, src)
        if ok and c then
            log[#log+1] = "[Crystal Polyglot] Converted: " .. name
            changed = true
            src = result
        end
    end
    run("JSON objects/arrays",   function(s) return PolyConvert.convertJSON(s)           end)
    run("JS arrow functions",    function(s) return PolyConvert.convertArrowFunctions(s) end)
    run("JS var/let/const",      function(s) return PolyConvert.convertJSVars(s)         end)
    run("JS operators (&&,||,===)", function(s) return PolyConvert.convertJSOperators(s)  end)
    run("console.log/warn/error",function(s) return PolyConvert.convertPrintCalls(s)    end)
    run("f-strings",             function(s) return PolyConvert.convertFStrings(s)       end)
    return src, log, changed
end

Analyzer.PolyConvert = PolyConvert

-- ── Run all fixes ─────────────────────────────────────────────────────────────

function Analyzer.autoFix(src, options)
    options = options or {}
    local log      = {}
    local modified = false

    for _, fixer in ipairs(FIXES) do
        if options[fixer.name] ~= false then  -- allow disabling specific fixes
            local ok, result, changed = pcall(fixer.fix, src)
            if ok then
                if changed then
                    log[#log+1] = "[Crystal AutoFix] Applied: " .. fixer.name
                    modified = true
                    src = result
                end
            else
                log[#log+1] = "[Crystal AutoFix] Skipped " .. fixer.name .. ": " .. tostring(result)
            end
        end
    end

    return src, log, modified
end

-- ── Load-time validator ───────────────────────────────────────────────────────
-- Try to load the script via Lua's load() to catch syntax errors before obfuscating.

function Analyzer.validate(src)
    local fn, err = load(src, "@crystal_validate", "t", {})
    if fn then
        return true, nil
    end
    return false, err
end

-- ── Full pipeline ─────────────────────────────────────────────────────────────
-- analyze → auto-fix → optionally inject HTTPS → return ready-to-run src

function Analyzer.prepare(src, options)
    options = options or {}

    -- 0. Polyglot conversion: JSON/JS/f-strings → Lua (runs before anything else)
    local polyLog     = {}
    local polyChanged = false
    if options.polyConvert ~= false then
        local converted
        converted, polyLog, polyChanged = PolyConvert.convert(src)
        src = converted
    end

    -- 1. Detect features
    local features = Analyzer.detectFeatures(src)

    -- 2. Auto-fix bugs
    local fixedSrc, fixLog, wasFixed = Analyzer.autoFix(src, options.fixes)

    -- Merge poly log into fix log
    if polyChanged then
        for _, msg in ipairs(polyLog) do
            table.insert(fixLog, 1, msg)
        end
        wasFixed = true
    end

    -- 3. Inject HTTPS only if requested AND not already present
    local httpsInjected = false
    if options.injectHTTPS ~= false then
        fixedSrc, httpsInjected = Analyzer.injectHTTPS(fixedSrc)
    end

    -- 4. Validate syntax
    local valid, syntaxErr = Analyzer.validate(fixedSrc)

    return {
        source         = fixedSrc,
        originalSource = src,
        features       = features,
        fixLog         = fixLog,
        wasFixed       = wasFixed,
        polyConverted  = polyChanged,
        httpsInjected  = httpsInjected,
        valid          = valid,
        syntaxError    = syntaxErr,
    }
end

return Analyzer
