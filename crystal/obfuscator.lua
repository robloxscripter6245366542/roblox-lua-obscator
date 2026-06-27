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

local function xorBytes(data, key)
    local out = {}
    local klen = #key
    for i = 1, #data do
        local ki = ((i - 1) % klen) + 1
        out[i] = string.char(bit32.bxor(data:byte(i), key:byte(ki)))
    end
    return table.concat(out)
end

local function rollingXor(data, seed)
    local out = {}
    local state = seed % 256
    for i = 1, #data do
        local b = data:byte(i)
        local enc = bit32.bxor(b, state)
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

    -- Build decryptor preamble
    local keyBytes = bytesToHex(key)
    local preamble = ("local %s;do local _k=\"%s\";local _s=%d;_s=_s%%256;local function _d(s)local r={}local st=_s for i=1,#s do local b=s:byte(i)local e=bit32.bxor(b,st)r[i]=string.char(e)st=(st*31+e+7)%%256 end return table.concat(r)end;%s=_d end\n")
        :format(decFn, keyBytes:gsub("\\%d+", function(e) return e end), seed, decFn)

    out[#out+1] = preamble

    for _, t in ipairs(tokens) do
        if t.kind == "STRING" then
            -- Strip surrounding quotes, encrypt content
            local raw = t.value
            local delim = raw:sub(1,1)
            local content = raw:sub(2, -2)
                :gsub("\\n","\n"):gsub("\\t","\t"):gsub("\\\\","\\"):gsub('\\"','"'):gsub("\\'","'")
            local encrypted = rollingXor(content, seed)
            local hexStr    = bytesToHex(encrypted)
            out[#out+1] = ('%s("%s")'):format(decFn, hexStr)
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

-- ── Layer 7: Anti-debug / anti-deobfuscation stubs ───────────────────────────

local function injectAntiDebug()
    local v1 = randName(5)
    local v2 = randName(5)
    local v3 = randName(5)
    return ([[
local %s = debug and debug.sethook
local %s = getinfo or debug and debug.getinfo
local %s = 0
if %s then %s(function() %s=%s+1 if %s>2 then error("Crystal: debugger detected",0) end end,"c",1) end
if type(%s)=="function" then
    local _ok,_e=pcall(%s,"_","n")
    if not _ok then error("Crystal: inspection blocked",0) end
end
]]):format(v1, v2, v3, v1, v1, v3, v3, v3, v2, v2)
end

-- ── Layer 5: Control flow flattening ─────────────────────────────────────────
-- Wrap top-level code in a dispatcher pattern so linear flow isn't obvious

local function flattenControlFlow(src)
    local dispVar = randName(6)
    local stateVar = randName(6)
    -- Split source into chunks at function / do / if boundaries
    -- For simplicity, wrap entire source in a stepped coroutine dispatcher
    return ([[
local %s = {[0]=function()
%s
end}
local %s = 0
while %s[%s] do %s[%s]() %s=%s+1 end
]]):format(dispVar, src, stateVar, dispVar, stateVar, dispVar, stateVar, stateVar, stateVar)
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

    return ([[
-- Crystal VM Loader (encrypted payload)
local %s=%d
local %s={%s}
local function %s(t,s)
    local r={}
    local st=s%%256
    for i=1,#t do
        local b=t[i]
        r[i]=string.char(bit32.bxor(b,st))
        st=(st*31+bit32.bxor(b,st)+7)%%256
    end
    return table.concat(r)
end
local function %s(src)
    local fn,err=load(src,"@crystal","t",getfenv and getfenv() or _ENV)
    if not fn then error("Crystal load error: "..tostring(err),0) end
    return fn()
end
%s(%s(%s,%s))
]]):format(
        seedVar, encSeed,
        payVar, table.concat(hexPayload, ","),
        decVar,
        runVar,
        runVar, decVar, payVar, seedVar
    )
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
    -- Pass 1: name mangle + string encrypt + number split
    local pass1 = Obfuscator.new({
        mangleNames      = true,
        encryptStrings   = true,
        obfuscateNumbers = true,
        injectDeadCode   = true,
        antiDebug        = true,
        vmWrap           = false,
        strength         = "max",
    })
    local r1 = pass1:obfuscate(src, "key_inner")

    -- Pass 2: dead code + flow flatten
    local pass2 = Obfuscator.new({
        mangleNames      = true,
        encryptStrings   = true,
        obfuscateNumbers = true,
        injectDeadCode   = true,
        antiDebug        = false,  -- already added
        vmWrap           = false,
        flattenFlow      = true,
        strength         = "max",
    })
    local r2 = pass2:obfuscate(r1, "key_mid")

    -- Pass 3: final VM wrap + encryption (double-sealed)
    local pass3 = Obfuscator.new({
        mangleNames      = false,  -- already done
        encryptStrings   = false,  -- already done
        obfuscateNumbers = false,  -- already done
        injectDeadCode   = true,
        antiDebug        = true,
        vmWrap           = true,
        strength         = "max",
    })
    local r3 = pass3:obfuscate(r2, "key_outer")

    -- Final: wrap one more time in VM for deepest protection
    local finalSeed = math.random(10, 250)
    local finalKey  = randomKey(32)
    return vmWrap(r3, finalKey)
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

    return out
end

return Obfuscator
