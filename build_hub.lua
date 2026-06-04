-- build_hub.lua
-- Minify + XOR/Base64 obfuscate Claude_Hub.lua → Claude_Hub_protected.lua
-- Usage: lua5.4 build_hub.lua

local INPUT  = "Claude_Hub.lua"
local OUTPUT = "Claude_Hub_protected.lua"

-- ── 1. Read source ─────────────────────────────────────────────────────────────
local fh = io.open(INPUT, "r")
if not fh then error("Cannot open "..INPUT) end
local src = fh:read("*a"); fh:close()

-- ── 2. Minify: strip comments and collapse blank lines ─────────────────────────
-- We process char-by-char to correctly handle strings / long-strings / comments
local function minify(s)
    local out = {}
    local i, n = 1, #s
    local prevBlank = false

    local function peek(off) return s:sub(i+off, i+off) end
    local function cur() return s:sub(i,i) end

    while i <= n do
        local c = cur()

        -- long string / long comment  --[[ ... ]] or [[ ... ]]
        if c == '-' and peek(1) == '-' and peek(2) == '[' then
            local lvl = 0
            local j = i + 2
            while s:sub(j,j) == '[' do lvl=lvl+1; j=j+1 end
            if lvl > 0 then
                -- skip long comment
                local close = "]"..string.rep("=",lvl-1).."]"
                local e2 = s:find(close, j, true)
                if e2 then i = e2 + #close
                else i = n+1 end
                -- emit nothing (skip comment)
            else
                -- single-line comment: skip to end of line
                local e2 = s:find("\n", i, true)
                if e2 then i = e2  -- keep the newline handled below
                else i = n+1 end
            end

        -- single-line comment  --
        elseif c == '-' and peek(1) == '-' then
            local e2 = s:find("\n", i, true)
            if e2 then i = e2  -- keep newline
            else i = n+1 end

        -- long string literal  [[ ... ]] or [==[ ... ]==]
        elseif c == '[' and (peek(1) == '[' or peek(1) == '=') then
            local lvl = 0
            local j = i + 1
            while s:sub(j,j) == '=' do lvl=lvl+1; j=j+1 end
            if s:sub(j,j) == '[' then
                -- it's a long string — copy verbatim until close
                local close = "]"..string.rep("=",lvl).."]"
                local e2 = s:find(close, j+1, true)
                if e2 then
                    out[#out+1] = s:sub(i, e2 + #close - 1)
                    i = e2 + #close
                else
                    out[#out+1] = s:sub(i)
                    i = n+1
                end
            else
                out[#out+1] = c; i=i+1
            end

        -- double-quoted string  " ... "
        elseif c == '"' then
            local j = i+1
            while j <= n do
                local ch = s:sub(j,j)
                if ch == '\\' then j=j+2
                elseif ch == '"' then j=j+1; break
                else j=j+1 end
            end
            out[#out+1] = s:sub(i, j-1); i = j

        -- single-quoted string  ' ... '
        elseif c == "'" then
            local j = i+1
            while j <= n do
                local ch = s:sub(j,j)
                if ch == '\\' then j=j+2
                elseif ch == "'" then j=j+1; break
                else j=j+1 end
            end
            out[#out+1] = s:sub(i, j-1); i = j

        -- newline
        elseif c == '\n' then
            out[#out+1] = '\n'; i=i+1

        -- multiple spaces → single space
        elseif c == ' ' or c == '\t' then
            -- collapse runs of whitespace (but not newlines) to one space
            while i <= n and (cur() == ' ' or cur() == '\t') do i=i+1 end
            out[#out+1] = ' '

        else
            out[#out+1] = c; i=i+1
        end
    end

    -- join, then remove blank lines
    local result = table.concat(out)
    -- collapse 3+ consecutive newlines to 2
    result = result:gsub("\n\n\n+", "\n\n")
    -- remove lines that are only whitespace
    local lines = {}
    for line in (result.."\n"):gmatch("([^\n]*)\n") do
        local trimmed = line:match("^%s*(.-)%s*$")
        if trimmed ~= "" then
            lines[#lines+1] = line
        end
    end
    return table.concat(lines, "\n")
end

local mini = minify(src)
print(string.format("Minified: %d bytes → %d bytes (%.0f%%)",
    #src, #mini, #mini/#src*100))

-- ── 3. XOR + Base64 obfuscate ─────────────────────────────────────────────────
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
    for i = 1, len do
        s = (s * 1664525 + 1013904223) % 4294967296
        key[i] = s % 256
    end
    return key
end

local function xorBytes(data, key)
    local out, kl = {}, #key
    for i = 1, #data do
        out[i] = string.char(bxor(data:byte(i), key[((i - 1) % kl) + 1]))
    end
    return table.concat(out)
end

local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function b64enc(data)
    local out, len = {}, #data
    for i = 1, len, 3 do
        local b1 = data:byte(i)
        local b2 = i+1<=len and data:byte(i+1) or 0
        local b3 = i+2<=len and data:byte(i+2) or 0
        local nv = b1*65536 + b2*256 + b3
        out[#out+1] = B64:sub(math.floor(nv/262144)%64+1, math.floor(nv/262144)%64+1)
        out[#out+1] = B64:sub(math.floor(nv/4096)%64+1,   math.floor(nv/4096)%64+1)
        out[#out+1] = i+1<=len and B64:sub(math.floor(nv/64)%64+1,math.floor(nv/64)%64+1) or "="
        out[#out+1] = i+2<=len and B64:sub(nv%64+1, nv%64+1) or "="
    end
    return table.concat(out)
end

local function charLit(s)
    local t = {}
    for i = 1, #s do t[i] = tostring(s:byte(i)) end
    return "string.char("..table.concat(t,",")..")"
end

local KEY_SEED = (#mini * 31337 + 0xDEAD) % 2147483647
local KEY_LEN  = 64
local key = makeKey(KEY_SEED, KEY_LEN)
local encrypted = xorBytes(mini, key)
local encoded   = b64enc(encrypted)

-- split into lines of 120 chars (fewer lines than 76)
local CHUNK = 120
local payloadLines = {}
for i = 1, #encoded, CHUNK do
    payloadLines[#payloadLines+1] = encoded:sub(i, i+CHUNK-1)
end

local function kg(from, to)
    local t = {}
    for i = from, to do t[#t+1] = tostring(key[i]) end
    return table.concat(t,",")
end

local alphaBytes = {}
for ch in B64:gmatch(".") do alphaBytes[#alphaBytes+1] = tostring(ch:byte(1)) end

-- ── 4. Emit output ─────────────────────────────────────────────────────────────
local L = {}
local function e(s) L[#L+1] = s end

e("-- "..charLit("Claude Hub | (c) 2025 | Unauthorized redistribution prohibited"))
e("local _c=string.char;local _fc=string.find;local _sb=string.sub")
e("local _tc=table.concat;local _mf=math.floor;local _ld=loadstring or load")
e("local _K1={"..kg(1,16).."};local _K2={"..kg(17,32).."}")
e("local _K3={"..kg(33,48).."};local _K4={"..kg(49,64).."}")
e("local _K={}")
e("for _,v in ipairs(_K1)do _K[#_K+1]=v end;for _,v in ipairs(_K2)do _K[#_K+1]=v end")
e("for _,v in ipairs(_K3)do _K[#_K+1]=v end;for _,v in ipairs(_K4)do _K[#_K+1]=v end")
e("local _A=_c("..table.concat(alphaBytes,",")..")")
e("local function _bd(_i) local _r,_v,_b={},0,0;_i=_i:gsub('[^'.._A..'=]','')")
e("for _n=1,#_i do local _ch=_sb(_i,_n,_n);if _ch=='='then break end")
e("local _p=_fc(_A,_ch,1,true);if not _p then break end")
e("_v=_v*64+(_p-1);_b=_b+6;if _b>=8 then _b=_b-8;_r[#_r+1]=_c(_mf(_v/2^_b)%256);_v=_v%(2^_b)end end")
e("return _tc(_r) end")
e("local function _xd(_d,_k) local _r,_kl={},#_k")
e("for _i=1,#_d do local _a,_bv=_d:byte(_i),_k[((_i-1)%_kl)+1]")
e("local _rs,_bt=0,1;while _a>0 or _bv>0 do if _a%2~=_bv%2 then _rs=_rs+_bt end")
e("_a=_mf(_a/2);_bv=_mf(_bv/2);_bt=_bt*2 end;_r[_i]=_c(_rs)end;return _tc(_r)end")
-- payload table
e("local _T={")
for i, chunk in ipairs(payloadLines) do
    e("'"..chunk.."'"..(i < #payloadLines and "," or ""))
end
e("};local _P=_tc(_T)")
e("local _fn,_er=_ld(_xd(_bd(_P),_K))")
e("if not _fn then warn("..charLit("[Claude Hub] Load error: ").."..tostring(_er))")
e("else _fn() end")

local output = table.concat(L, "\n").."\n"
local outf = io.open(OUTPUT, "w")
outf:write(output); outf:close()

local lines = select(2, output:gsub("\n","\n"))
print(string.format("Output : %s\n  Bytes : %d\n  Lines : %d", OUTPUT, #output, lines))
print("Done!")
