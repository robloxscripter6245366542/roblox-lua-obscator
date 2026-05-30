-- ============================================================
--  obfuscate.lua
--  Usage:  lua obfuscate.lua
--  Input:  Full_Combined_source.lua   (the readable source)
--  Output: Full_Combined.lua          (XOR + base64 protected)
--
--  Protection layers:
--    1. XOR-encrypt every byte with a 64-byte rotating key
--    2. Base64-encode the ciphertext
--    3. Split the key across 4 scattered locals in the output
--    4. All decoder identifiers are single-char mangled names
--    5. Every string literal in the decoder uses string.char()
-- ============================================================

local INPUT  = "Full_Combined_source.lua"
local OUTPUT = "Full_Combined.lua"

-- ── Pure-arithmetic bit XOR (Lua 5.1 / 5.2 / Luau compatible) ────────────────
local function bxor(a, b)
    local result, bit = 0, 1
    while a > 0 or b > 0 do
        if a % 2 ~= b % 2 then result = result + bit end
        a = math.floor(a / 2)
        b = math.floor(b / 2)
        bit = bit * 2
    end
    return result
end

-- ── Key generator (LCG, deterministic per build) ──────────────────────────────
local function makeKey(seed, len)
    local key, s = {}, seed % 2147483647
    for i = 1, len do
        s = (s * 1664525 + 1013904223) % 4294967296
        key[i] = s % 256
    end
    return key
end

-- ── XOR-encrypt data bytes with rotating key ─────────────────────────────────
local function xorBytes(data, key)
    local out, kl = {}, #key
    for i = 1, #data do
        out[i] = string.char(bxor(data:byte(i), key[((i - 1) % kl) + 1]))
    end
    return table.concat(out)
end

-- ── Base64 encoder ────────────────────────────────────────────────────────────
local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function b64enc(data)
    local out, len = {}, #data
    for i = 1, len, 3 do
        local b1 = data:byte(i)
        local b2 = i + 1 <= len and data:byte(i + 1) or 0
        local b3 = i + 2 <= len and data:byte(i + 2) or 0
        local n  = b1 * 65536 + b2 * 256 + b3
        out[#out+1] = B64:sub(math.floor(n / 262144) % 64 + 1, math.floor(n / 262144) % 64 + 1)
        out[#out+1] = B64:sub(math.floor(n / 4096)   % 64 + 1, math.floor(n / 4096)   % 64 + 1)
        out[#out+1] = i + 1 <= len and B64:sub(math.floor(n / 64) % 64 + 1, math.floor(n / 64) % 64 + 1) or "="
        out[#out+1] = i + 2 <= len and B64:sub(n % 64 + 1, n % 64 + 1) or "="
    end
    return table.concat(out)
end

-- ── Emit string.char(...) literal for any plain string ────────────────────────
local function charLit(s)
    local t = {}
    for i = 1, #s do t[i] = tostring(s:byte(i)) end
    return "string.char(" .. table.concat(t, ",") .. ")"
end

-- ── Split string into fixed-width chunks ──────────────────────────────────────
local function chunks(s, n)
    local t = {}
    for i = 1, #s, n do t[#t+1] = s:sub(i, i + n - 1) end
    return t
end

-- ══════════════════════════════════════════════════════════════════════════════
--  Main
-- ══════════════════════════════════════════════════════════════════════════════

local f = io.open(INPUT, "r")
if not f then
    print("ERROR: cannot open " .. INPUT)
    os.exit(1)
end
local src = f:read("*a")
f:close()

-- Deterministic key seed tied to the source (changes every time src changes)
local KEY_SEED = (#src * 31337 + 0xC0FFEE) % 2147483647
local KEY_LEN  = 64
local key = makeKey(KEY_SEED, KEY_LEN)

local encrypted = xorBytes(src, key)
local encoded   = b64enc(encrypted)
local payloadChunks = chunks(encoded, 76)

-- Split key into 4 x 16-byte groups for scattered storage
local function keyGroup(from, to)
    local t = {}
    for i = from, to do t[#t+1] = tostring(key[i]) end
    return table.concat(t, ",")
end

-- ── Build output lines ────────────────────────────────────────────────────────
local L = {}
local function e(s) L[#L+1] = s end

-- Header: copyright hidden as string.char so it can't be trivially stripped
e("-- " .. charLit("(c) SS Executor  |  Unauthorized copying or redistribution is prohibited."))
e("-- " .. charLit("Source: github.com/robloxscripter6245366542/roblox-lua-obscator"))
e("")

-- Short aliases (all single-char names)
e("local _c=string.char;local _fc=string.find;local _sb=string.sub")
e("local _tc=table.concat;local _mf=math.floor;local _ld=loadstring or load")
e("")

-- Key in 4 scattered parts — requires reassembling all 4 to decrypt
e("local _K1={" .. keyGroup(1,  16) .. "}")
e("local _K2={" .. keyGroup(17, 32) .. "}")
e("local _K3={" .. keyGroup(33, 48) .. "}")
e("local _K4={" .. keyGroup(49, 64) .. "}")
e("")

-- Reassemble full key at runtime
e("local _K={}")
e("for _,v in ipairs(_K1)do _K[#_K+1]=v end")
e("for _,v in ipairs(_K2)do _K[#_K+1]=v end")
e("for _,v in ipairs(_K3)do _K[#_K+1]=v end")
e("for _,v in ipairs(_K4)do _K[#_K+1]=v end")
e("")

-- Base64 alphabet hidden as string.char
local alphaBytes = {}
for ch in B64:gmatch(".") do alphaBytes[#alphaBytes+1] = tostring(ch:byte(1)) end
e("local _A=_c(" .. table.concat(alphaBytes, ",") .. ")")
e("")

-- Base64 decoder
e("local function _bd(_i)")
e("    local _r,_v,_b={},0,0")
e("    _i=_i:gsub('[^'.._A..'=]','')")
e("    for _n=1,#_i do")
e("        local _ch=_sb(_i,_n,_n)")
e("        if _ch=='=' then break end")
e("        local _p=_fc(_A,_ch,1,true)")
e("        if not _p then break end")
e("        _v=_v*64+(_p-1);_b=_b+6")
e("        if _b>=8 then")
e("            _b=_b-8")
e("            _r[#_r+1]=_c(_mf(_v/2^_b)%256)")
e("            _v=_v%(2^_b)")
e("        end")
e("    end")
e("    return _tc(_r)")
e("end")
e("")

-- XOR decryptor (same pure-arithmetic approach, works in all Luau versions)
e("local function _xd(_d,_k)")
e("    local _r,_kl={},#_k")
e("    for _i=1,#_d do")
e("        local _a,_bv=_d:byte(_i),_k[((_i-1)%_kl)+1]")
e("        local _rs,_bt=0,1")
e("        while _a>0 or _bv>0 do")
e("            if _a%2~=_bv%2 then _rs=_rs+_bt end")
e("            _a=_mf(_a/2);_bv=_mf(_bv/2);_bt=_bt*2")
e("        end")
e("        _r[_i]=_c(_rs)")
e("    end")
e("    return _tc(_r)")
e("end")
e("")

-- Payload (base64 ciphertext split across many concat lines)
e("local _P=''")
for _, chunk in ipairs(payloadChunks) do
    e("_P=_P..'" .. chunk .. "'")
end
e("")

-- Decode → decrypt → compile → run
e("local _fn,_er=_ld(_xd(_bd(_P),_K))")
e("if not _fn then")
e("    warn(" .. charLit("[SS Executor] Load error: ") .. "..tostring(_er))")
e("else")
e("    _fn()")
e("end")

local output = table.concat(L, "\n") .. "\n"

local out = io.open(OUTPUT, "w")
out:write(output)
out:close()

print(string.format(
    "Done  →  %s\n  Bytes   : %d\n  Lines   : %d\n  Key seed: %d",
    OUTPUT, #output, select(2, output:gsub("\n", "\n")), KEY_SEED
))
