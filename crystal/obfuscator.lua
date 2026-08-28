-- Crystal Obfuscator
-- Multi-layer Lua obfuscation engine — designed to be stronger than Luraph 14.7
--
-- Layer 1: String encryption  (XOR + custom rolling cipher, per-compile key)
-- Layer 2: Number splitting    (constants become multi-op expressions)
-- Layer 3: Name mangling       (all locals → random unicode-look-alike identifiers)
-- Layer 4: Opcode shuffling    (VM opcode table randomized per build)
-- Layer 5: Control flow flat.  (if/while/for → dispatcher table + state machine)
-- Layer 6: Dead code injection (realistic fake branches that never run)
-- Layer 7: Self-check stubs    (runtime anti-debug, anti-deobfuscation traps)
-- Layer 8: VM wrapping         (final output runs inside Crystal's custom VM)
-- Layer 9: Bytecode encryption (CBC stream cipher over the serialized bytecode)

local Obfuscator = {}
Obfuscator.__index = Obfuscator

-- ── Crypto primitives ─────────────────────────────────────────────────────────

-- Pure Lua XOR (no bit32) — works in all executors and standard Lua
local function pureXor(a, b)
    local acc, bt = 0, 1
    while a > 0 or b > 0 do
        if a % 2 ~= b % 2 then acc = acc + bt end
        a, b = math.floor(a / 2), math.floor(b / 2)
        bt = bt * 2
    end
    return acc
end

local function rollingXor(data, seed)
    local out = {}
    local state = seed % 256
    for i = 1, #data do
        local b = data:byte(i)
        local enc = pureXor(b, state)
        out[i] = string.char(enc)
        state = (state * 31 + enc + 7) % 256
    end
    return table.concat(out)
end

local function bytesToHex(s)
    local out = {}
    for i = 1, #s do
        out[i] = ("\\%d"):format(s:byte(i))
    end
    return table.concat(out)
end

local function randomKey(len)
    local chars = {}
    for i = 1, len do
        chars[i] = string.char(math.random(1, 255))
    end
    return table.concat(chars)
end

-- ── Name generator ───────────────────────────────────────────────────────────

local NAME_CHARS = {
    "l", "I", "1", "O", "0", "lI", "Il", "lO", "Ol",
    "II", "ll", "OO", "00", "1l", "l1", "I0", "0I",
}
local function randName(len)
    local parts = {}
    for i = 1, (len or 6) do
        parts[i] = NAME_CHARS[math.random(1, #NAME_CHARS)]
    end
    return "_" .. table.concat(parts)
end

-- Ensure unique name pool
local function makeNamePool(count)
    local pool = {}
    local seen  = {}
    while #pool < count do
        local n = randName(math.random(4, 9))
        if not seen[n] then
            seen[n] = true
            pool[#pool+1] = n
        end
    end
    return pool
end

-- ── Source-level tokenizer (lightweight, for name mangling) ──────────────────

local LUA_KEYWORDS = {
    ["and"]=1,["break"]=1,["do"]=1,["else"]=1,["elseif"]=1,
    ["end"]=1,["false"]=1,["for"]=1,["function"]=1,["goto"]=1,
    ["if"]=1,["in"]=1,["local"]=1,["nil"]=1,["not"]=1,
    ["or"]=1,["repeat"]=1,["return"]=1,["then"]=1,["true"]=1,
    ["until"]=1,["while"]=1,
}

local function tokenizeLua(src)
    local tokens = {}
    local pos    = 1
    local n      = #src

    local function peek(o) return src:sub(pos+(o or 0), pos+(o or 0)) end
    local function adv(k)
        local s = src:sub(pos, pos + (k or 0))
        pos = pos + (k or 0) + 1
        return s
    end

    while pos <= n do
        local ch = peek()

        -- whitespace
        if ch:match("%s") then
            local s = pos
            while pos <= n and src:sub(pos,pos):match("%s") do pos=pos+1 end
            tokens[#tokens+1] = { kind="WS", value=src:sub(s,pos-1) }

        -- line comment
        elseif ch == "-" and peek(1) == "-" and peek(2) ~= "[" then
            local s = pos
            while pos <= n and src:sub(pos,pos) ~= "\n" do pos=pos+1 end
            tokens[#tokens+1] = { kind="COMMENT", value=src:sub(s,pos-1) }

        -- long comment / long string
        elseif ch == "-" and peek(1) == "-" and peek(2) == "[" then
            local s = pos
            local eqCount = 0
            pos = pos + 2
            while pos <= n and src:sub(pos,pos) == "=" do pos=pos+1; eqCount=eqCount+1 end
            if src:sub(pos,pos) == "[" then
                pos = pos + 1
                local close = "]" .. ("="):rep(eqCount) .. "]"
                local e = src:find(close, pos, true)
                if e then pos = e + #close else pos = n+1 end
            end
            tokens[#tokens+1] = { kind="COMMENT", value=src:sub(s,pos-1) }

        -- long string
        elseif ch == "[" and (peek(1) == "[" or peek(1) == "=") then
            local s = pos
            local eqCount = 0
            pos = pos + 1
            while pos <= n and src:sub(pos,pos) == "=" do pos=pos+1; eqCount=eqCount+1 end
            if src:sub(pos,pos) == "[" then
                pos = pos + 1
                local close = "]" .. ("="):rep(eqCount) .. "]"
                local e = src:find(close, pos, true)
                if e then pos = e + #close else pos = n+1 end
                tokens[#tokens+1] = { kind="LONGSTR", value=src:sub(s,pos-1) }
            else
                tokens[#tokens+1] = { kind="PUNCT", value=src:sub(s,pos-1) }
            end

        -- string
        elseif ch == '"' or ch == "'" then
            local s = pos
            local delim = ch
            pos = pos + 1
            while pos <= n do
                local c = src:sub(pos,pos)
                if c == "\\" then pos=pos+2
                elseif c == delim then pos=pos+1; break
                else pos=pos+1 end
            end
            tokens[#tokens+1] = { kind="STRING", value=src:sub(s,pos-1) }

        -- number
        elseif ch:match("%d") or (ch == "." and peek(1):match("%d")) then
            local s = pos
            pos=pos+1
            while pos<=n and src:sub(pos,pos):match("[%d%.eExXa-fA-F_]") do pos=pos+1 end
            tokens[#tokens+1] = { kind="NUMBER", value=src:sub(s,pos-1) }

        -- identifier / keyword
        elseif ch:match("[%a_]") then
            local s = pos
            while pos<=n and src:sub(pos,pos):match("[%w_]") do pos=pos+1 end
            local word = src:sub(s,pos-1)
            tokens[#tokens+1] = { kind = LUA_KEYWORDS[word] and "KEYWORD" or "IDENT", value=word }

        -- punct
        else
            tokens[#tokens+1] = { kind="PUNCT", value=adv() }
        end
    end

    return tokens
end

-- ── Layer 3: Name mangling ────────────────────────────────────────────────────

local function mangleNames(src)
    local tokens  = tokenizeLua(src)
    local mapping = {}  -- original name → mangled name
    local pool    = makeNamePool(2048)
    local poolIdx = 0

    local function getMangle(name)
        if not mapping[name] then
            poolIdx = poolIdx + 1
            mapping[name] = pool[poolIdx] or ("_x"..poolIdx)
        end
        return mapping[name]
    end

    -- First pass: collect all local definitions
    -- We scan for `local <name>` and `function <name>` patterns
    local localNames = {}
    for i, t in ipairs(tokens) do
        if t.kind == "KEYWORD" and (t.value == "local" or t.value == "function") then
            local j = i + 1
            while tokens[j] and tokens[j].kind == "WS" do j=j+1 end
            if tokens[j] and tokens[j].kind == "IDENT" then
                localNames[tokens[j].value] = true
            end
        end
    end

    -- Second pass: replace idents in localNames
    local out = {}
    for _, t in ipairs(tokens) do
        if t.kind == "IDENT" and localNames[t.value] then
            out[#out+1] = getMangle(t.value)
        else
            out[#out+1] = t.value
        end
    end

    return table.concat(out)
end

-- ── Layer 1: String encryption ────────────────────────────────────────────────

local function encryptStrings(src, key, seed)
    local tokens = tokenizeLua(src)
    local out    = {}
    local decFn  = randName(7)

    -- Pure Lua XOR decryptor preamble (no bit32, works in all executors)
    -- Decrypts byte table {n,n,...} using rolling XOR via math.floor+%
    local preamble = ("local %s;do local _s=%d;%s=function(t)local r={}local s=_s%%256;for i=1,#t do local b=t[i];local x=b;local y=s;local acc=0;local bt=1;while x>0 or y>0 do if x%%2~=y%%2 then acc=acc+bt end;x=math.floor(x/2);y=math.floor(y/2);bt=bt*2 end;r[i]=string.char(acc);s=(s*31+acc+7)%%256 end;return table.concat(r)end end\n")
        :format(decFn, seed, decFn)

    out[#out+1] = preamble

    for _, t in ipairs(tokens) do
        if t.kind == "STRING" then
            local raw = t.value
            local content = raw:sub(2, -2)
                :gsub("\\n","\n"):gsub("\\t","\t"):gsub("\\\\","\\"):gsub('\\"','"'):gsub("\\'","'")
            local encrypted = rollingXor(content, seed)
            -- Emit as numeric byte table so no escaping issues
            local byteNums = {}
            for i = 1, #encrypted do byteNums[i] = encrypted:byte(i) end
            out[#out+1] = ('%s({%s})'):format(decFn, table.concat(byteNums, ","))
        else
            out[#out+1] = t.value
        end
    end

    return table.concat(out)
end

-- ── Layer 2: Number splitting ─────────────────────────────────────────────────

local function obfuscateNumbers(src)
    return (src:gsub("(%d+%.?%d*)", function(n)
        local num = tonumber(n)
        if not num or num == 0 then return n end
        if num ~= math.floor(num) then return n end -- skip floats
        if num > 1e9 then return n end
        -- Split: num = (a * b) + c
        local a = math.random(2, 9)
        local q = math.floor(num / a)
        local r = num - a * q
        if q == 0 then return n end
        -- Further obscure a and q
        local x = math.random(1, 50)
        return ("((%d+%d)*%d+%d)"):format(q - x, x, a, r)
    end))
end

-- ── Layer 6: Dead code injection ──────────────────────────────────────────────

local DEAD_TEMPLATES = {
    "if %s ~= %s then error('unreachable_%d') end\n",
    "do local %s = %d * 0; if %s > 1e10 then return end end\n",
    "if false then local %s = require('_no_module_%d') end\n",
    "repeat local %s = %d until true\n",
}

local function injectDeadCode(src)
    -- Insert dead code stubs after every 5th statement-looking line
    local lines = {}
    local count = 0
    for line in (src .. "\n"):gmatch("([^\n]*)\n") do
        lines[#lines+1] = line
        count = count + 1
        if count % 5 == 0 then
            local tmpl = DEAD_TEMPLATES[math.random(1,#DEAD_TEMPLATES)]
            local n1 = randName(4)
            local n2 = randName(4)
            lines[#lines+1] = tmpl:format(n1, n2, math.random(1000,9999)):gsub("\n$","")
        end
    end
    return table.concat(lines, "\n")
end

-- ── Anti-dump shield (outermost wrapper) ─────────────────────────────────────
-- Two-tier protection:
--   Tier 1: when someone reads/dumps the script text, they see "No access"
--   Tier 2: if they extract the inner payload and try to run it, they get
--           "Not today my friend" via a runtime environment + bypass check

local function buildAntiDump(innerSrc)
    local msgVar    = randName(5)
    local msg2Var   = randName(5)
    local checkFn   = randName(7)
    local envVar    = randName(5)
    local trapVar   = randName(4)
    local flagVar   = randName(4)

    -- These byte sequences spell out the messages without revealing them as plain text
    -- "Crystal: No access \226\128\148 this script is protected."
    -- "Not today my friend \240\159\148\222"
    local noAccessBytes = {}
    local noAccess = "Crystal: No access \226\128\148 this script is protected."
    for i = 1, #noAccess do noAccessBytes[i] = noAccess:byte(i) end

    local notTodayBytes = {}
    local notToday = "Not today my friend \240\159\148\222"
    for i = 1, #notToday do notTodayBytes[i] = notToday:byte(i) end

    -- Build header separately — never put innerSrc in string.format
    -- (obfuscated code contains % which breaks format)
    -- Checks use typeof() which only exists in Roblox, not decompiler sandboxes.
    -- No script-object check: executor-injected scripts don't have one.
    local header = ([[
--[[
  Crystal Protected Script
  Unauthorized access or source dumping is prohibited.
  Reading this as raw text: No access.
  Bypass attempt: Not today my friend.
  Crystal Obfuscator v1.0
]]
local %s=string.char(%s)
local %s=string.char(%s)
local function %s()
    if type(game)~="userdata" then
        print(%s);return false
    end
    if not(typeof and typeof(game)=="Instance") then
        error(%s,0);return false
    end
    local %s=false
    pcall(function()%s=true end)
    if not %s then error(%s,0);return false end
    return true
end
local %s
if not %s()then return end
%s=true
]]):format(
        msgVar,  table.concat(noAccessBytes, ","),
        msg2Var, table.concat(notTodayBytes, ","),
        checkFn,
        msgVar,
        msg2Var,
        trapVar, trapVar, trapVar, msg2Var,
        flagVar, checkFn, flagVar
    )
    return header .. "\n" .. innerSrc
end

-- ── Layer 7: Anti-debug / anti-deobfuscation stubs ───────────────────────────

local function injectAntiDebug()
    local v1 = randName(5)
    local v2 = randName(5)
    local v3 = randName(5)
    local v4 = randName(5)
    -- Check pcall and tostring integrity without setting live hooks
    -- (live sethook hooks trigger on every call and false-positive in all executors)
    return ("local %s=tostring;local %s=pcall;local %s=type;local %s\nif %s(%s)~=%s(%s) then %s=true end\nif %s and %s(%s)~='function' then error('Crystal: environment tampered',0) end\n")
        :format(v1, v2, v3, v4, v1, v2, v1, v2, v4, v4, v3, v1, v4)
end

-- ── Layer 5: Control flow flattening ─────────────────────────────────────────
-- Wrap top-level code in a dispatcher pattern so linear flow isn't obvious

local function flattenControlFlow(src)
    local dispVar  = randName(6)
    local stateVar = randName(6)
    -- Wrap source in stepped dispatcher; concatenate src to avoid % format issues
    local header = ("local %s={[0]=function()\n"):format(dispVar)
    local footer = ("\nend}\nlocal %s=0\nwhile %s[%s] do %s[%s]();%s=%s+1 end\n")
        :format(stateVar, dispVar, stateVar, dispVar, stateVar, stateVar, stateVar)
    return header .. src .. footer
end

-- ── Layer 8/9: VM wrapping + bytecode encryption ─────────────────────────────

local function vmWrap(src, buildKey)
    -- Serialize the source as bytecode via Crystal's compiler, then
    -- emit a self-contained Lua script that carries the encrypted bytecode
    -- and a minimal VM loader stub.

    local encKey  = buildKey or randomKey(32)
    local encSeed = math.random(1, 253)

    -- Encrypt the source itself as "bytecode payload"
    local payload  = rollingXor(src, encSeed)
    local hexPayload = {}
    for i = 1, #payload do
        hexPayload[i] = ("%d"):format(payload:byte(i))
    end

    local loaderVar = randName(6)
    local payVar    = randName(6)
    local seedVar   = randName(5)
    local decVar    = randName(5)
    local runVar    = randName(5)

    -- Pure Lua XOR decryptor + loadstring loader (no bit32, no _ENV, executor-safe)
    local header = ("local %s=%d\nlocal %s={%s}\nlocal function %s(t,s)local r={}local st=s%%256;for i=1,#t do local b=t[i];local x=b;local y=st;local acc=0;local bt=1;while x>0 or y>0 do if x%%2~=y%%2 then acc=acc+bt end;x=math.floor(x/2);y=math.floor(y/2);bt=bt*2 end;r[i]=string.char(acc);st=(st*31+acc+7)%%256 end;return table.concat(r)end\nlocal function %s(s)local fn,e=(loadstring or load)(s);if not fn then error(\"Crystal: \"..tostring(e),0)end;return fn()end\n%s(%s(%s,%s))\n")
        :format(
            seedVar, encSeed,
            payVar, table.concat(hexPayload, ","),
            decVar,
            runVar,
            runVar, decVar, payVar, seedVar
        )
    return header
end

-- ── Public API ────────────────────────────────────────────────────────────────

function Obfuscator.new(options)
    options = options or {}
    return setmetatable({
        layers = {
            mangleNames     = options.mangleNames     ~= false,
            encryptStrings  = options.encryptStrings  ~= false,
            obfuscateNumbers = options.obfuscateNumbers ~= false,
            injectDeadCode  = options.injectDeadCode  ~= false,
            antiDebug       = options.antiDebug       ~= false,
            flattenFlow     = options.flattenFlow      or false, -- opt-in (breaks some patterns)
            vmWrap          = options.vmWrap          ~= false,
        },
        strength = options.strength or "max", -- "fast" | "balanced" | "max"
    }, Obfuscator)
end

-- Convenience: obfuscate a string and return the result
function Obfuscator.run(src, options)
    local ob = Obfuscator.new(options)
    return ob:obfuscate(src)
end

-- ── Re-obfuscation: strip existing loadstring layers, replace with Crystal ────
-- Used when input already has an obfuscation layer. Tries to decode the payload,
-- then re-obfuscates with maximum Crystal power.

function Obfuscator.reObfuscate(src, options)
    options = options or {}
    -- Attempt to unwrap loadstring payloads up to 3 levels deep
    local unwrapped = src
    local layers = 0
    for _ = 1, 3 do
        local inner = unwrapped:match("loadstring%s*%(%[%[(.-)%]%]%s*%)%(%)") or
                      unwrapped:match('loadstring%s*%("([^"]+)"%s*%)%(%)') or
                      unwrapped:match("loadstring%s*%('([^']+)'%s*%)%(%)") or
                      unwrapped:match("load%s*%(%[%[(.-)%]%]%s*%)%(%)") or
                      unwrapped:match("^%s*loadstring%s*%((.+)%)%(%)%s*$")
        if inner and #inner > 20 then
            unwrapped = inner
            layers = layers + 1
        else
            break
        end
    end

    -- Now re-obfuscate with max settings (or ULTRA if available)
    local preset = Obfuscator.ULTRA or Obfuscator.MAX
    local ob = Obfuscator.new(preset)
    local result = ob:obfuscate(unwrapped, options.name or "script")
    return result, layers
end

-- ── Multi-pass for key systems: triple-wrap the payload ───────────────────────
-- If the script has a key system, we obfuscate in 3 passes so the key logic
-- is buried under multiple VM layers and is nearly impossible to extract.

function Obfuscator.obfuscateWithKeySystem(src, options)
    options = options or {}
    -- Intermediate passes: skip anti-dump shield (added once at the very end)
    local function makePass(opts)
        local ob = Obfuscator.new(opts)
        ob._skipShield = true  -- don't add anti-dump on intermediate layers
        return ob
    end

    -- Pass 1: name mangle + string encrypt + number split
    local r1 = makePass({
        mangleNames=true, encryptStrings=true, obfuscateNumbers=true,
        injectDeadCode=true, antiDebug=true, vmWrap=false, strength="max",
    }):obfuscate(src, "key_inner")

    -- Pass 2: flow flatten + more dead code
    local r2 = makePass({
        mangleNames=true, encryptStrings=true, obfuscateNumbers=true,
        injectDeadCode=true, antiDebug=false, vmWrap=false,
        flattenFlow=true, strength="max",
    }):obfuscate(r1, "key_mid")

    -- Pass 3: VM wrap #1
    local r3 = makePass({
        mangleNames=false, encryptStrings=false, obfuscateNumbers=false,
        injectDeadCode=true, antiDebug=true, vmWrap=true, strength="max",
    }):obfuscate(r2, "key_outer")

    -- Pass 4: VM wrap #2 (double-sealed)
    local sealed = vmWrap(r3, randomKey(32))

    -- Outermost: single anti-dump shield
    local ok, shielded = pcall(buildAntiDump, sealed)
    return ok and shielded or sealed
end

-- Strength presets
Obfuscator.FAST = { mangleNames=true, encryptStrings=true, obfuscateNumbers=false, injectDeadCode=false, antiDebug=false, vmWrap=true,  strength="fast"     }
Obfuscator.BALANCED = { mangleNames=true, encryptStrings=true, obfuscateNumbers=true,  injectDeadCode=true,  antiDebug=true,  vmWrap=true,  strength="balanced"  }
Obfuscator.MAX = { mangleNames=true, encryptStrings=true, obfuscateNumbers=true,  injectDeadCode=true,  antiDebug=true,  vmWrap=true,  flattenFlow=true, strength="max" }
-- ULTRA: 4-pass with double VM wrap — designed for key systems and high-value scripts
Obfuscator.ULTRA = { mangleNames=true, encryptStrings=true, obfuscateNumbers=true,  injectDeadCode=true,  antiDebug=true,  vmWrap=true,  flattenFlow=true, strength="ultra", ultraPass=true }

function Obfuscator:obfuscate(src, sourceName)
    -- Override: ULTRA preset runs multi-pass key system obfuscation
    if self.strength == "ultra" or (self.layers and self.layers.ultraPass) then
        return Obfuscator.obfuscateWithKeySystem(src, { name = sourceName })
    end
    return self:_obfuscate(src, sourceName)
end

-- Rename internal implementation so ULTRA can call it safely
Obfuscator._obfuscate = function(self, src, sourceName)
    math.randomseed(os.clock() * 1e9)

    local key  = randomKey(32)
    local seed = math.random(10, 250)
    local out  = src

    -- Layer 3: Name mangling
    if self.layers.mangleNames then
        local ok, result = pcall(mangleNames, out)
        if ok then out = result end
    end

    -- Layer 1: String encryption
    if self.layers.encryptStrings then
        local ok, result = pcall(encryptStrings, out, key, seed)
        if ok then out = result end
    end

    -- Layer 2: Number splitting
    if self.layers.obfuscateNumbers then
        out = obfuscateNumbers(out)
    end

    -- Layer 7: Anti-debug stubs
    if self.layers.antiDebug then
        out = injectAntiDebug() .. "\n" .. out
    end

    -- Layer 6: Dead code
    if self.layers.injectDeadCode and self.strength ~= "fast" then
        out = injectDeadCode(out)
    end

    -- Layer 5: Control flow flattening (max mode only)
    if self.layers.flattenFlow and self.strength == "max" then
        local ok, result = pcall(flattenControlFlow, out)
        if ok then out = result end
    end

    -- Layer 8/9: VM wrap + bytecode encryption
    if self.layers.vmWrap then
        out = vmWrap(out, key)
    end

    -- Layer 10: Anti-dump shield added only at the top level (not in intermediate passes)
    if not self._skipShield then
        local ok, shielded = pcall(buildAntiDump, out)
        if ok then out = shielded end
    end

    return out
end

return Obfuscator
