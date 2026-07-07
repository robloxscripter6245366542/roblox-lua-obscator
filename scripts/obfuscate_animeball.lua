-- Build the obfuscated Anime Ball payload.
--   Usage:  lua5.1 scripts/obfuscate_animeball.lua   (run from repo root)
--   Input:  user_scripts/anime_ball_autoparry.lua
--   Output: user_scripts/anime_ball_protected.lua  (XOR+base64 self-decoding)
-- Re-run this whenever the source changes, then commit / re-host the output.
local INPUT  = "user_scripts/anime_ball_autoparry.lua"
local OUTPUT = "user_scripts/anime_ball_protected.lua"

local function bxor(a, b)
    local result, bit = 0, 1
    while a > 0 or b > 0 do
        if a % 2 ~= b % 2 then result = result + bit end
        a = math.floor(a / 2); b = math.floor(b / 2); bit = bit * 2
    end
    return result
end
local function makeKey(seed, len)
    local key, s = {}, seed % 2147483647
    for i = 1, len do s = (s * 1664525 + 1013904223) % 4294967296; key[i] = s % 256 end
    return key
end
local function xorBytes(data, key)
    local out, kl = {}, #key
    for i = 1, #data do out[i] = string.char(bxor(data:byte(i), key[((i - 1) % kl) + 1])) end
    return table.concat(out)
end
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
local function charLit(s)
    local t = {}; for i = 1, #s do t[i] = tostring(s:byte(i)) end
    return "string.char(" .. table.concat(t, ",") .. ")"
end
local function chunks(s, n)
    local t = {}; for i = 1, #s, n do t[#t+1] = s:sub(i, i + n - 1) end; return t
end

local f = io.open(INPUT, "r"); if not f then print("ERROR: cannot open " .. INPUT); os.exit(1) end
local src = f:read("*a"); f:close()

local KEY_SEED = (#src * 31337 + 0xC0FFEE) % 2147483647
local key = makeKey(KEY_SEED, 64)
local encoded = b64enc(xorBytes(src, key))
local payloadChunks = chunks(encoded, 76)
local function keyGroup(from, to)
    local t = {}; for i = from, to do t[#t+1] = tostring(key[i]) end; return table.concat(t, ",")
end

local L = {}
local function e(s) L[#L+1] = s end
e("-- " .. charLit("(c) Anime Ball Hub  |  Unauthorized copying or redistribution is prohibited."))
e("")
e("local _c=string.char;local _fc=string.find;local _sb=string.sub")
e("local _tc=table.concat;local _mf=math.floor;local _ld=loadstring or load")
e("")
e("local _K1={" .. keyGroup(1, 16) .. "}")
e("local _K2={" .. keyGroup(17, 32) .. "}")
e("local _K3={" .. keyGroup(33, 48) .. "}")
e("local _K4={" .. keyGroup(49, 64) .. "}")
e("local _K={}")
e("for _,v in ipairs(_K1)do _K[#_K+1]=v end")
e("for _,v in ipairs(_K2)do _K[#_K+1]=v end")
e("for _,v in ipairs(_K3)do _K[#_K+1]=v end")
e("for _,v in ipairs(_K4)do _K[#_K+1]=v end")
e("")
local alphaBytes = {}
for ch in B64:gmatch(".") do alphaBytes[#alphaBytes+1] = tostring(ch:byte(1)) end
e("local _A=_c(" .. table.concat(alphaBytes, ",") .. ")")
e("")
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
e("local _T={")
for i, chunk in ipairs(payloadChunks) do
    e("'" .. chunk .. "'" .. (i < #payloadChunks and "," or ""))
end
e("}")
e("local _P=_tc(_T)")
e("")
e("local _fn,_er=_ld(_xd(_bd(_P),_K))")
e("if not _fn then")
e("    warn(" .. charLit("[Anime Ball] Load error: ") .. "..tostring(_er))")
e("else")
e("    _fn()")
e("end")

local output = table.concat(L, "\n") .. "\n"
local out = io.open(OUTPUT, "w"); out:write(output); out:close()
print(string.format("Done  ->  %s  (%d bytes, key seed %d)", OUTPUT, #output, KEY_SEED))
