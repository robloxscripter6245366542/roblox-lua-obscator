-- capybara/pack.lua
-- Final layer: encrypt the whole transformed chunk and emit a self-contained
-- bootstrap that decodes, decrypts, compiles and runs it. The loaded chunk is
-- ordinary Lua, so semantics are preserved on any Lua 5.1+/Luau runtime.
--
-- capybara's twist over a plain base64 loader: the base64 alphabet is *shuffled
-- per build* from the seed, so the encoded blob shares no fixed alphabet with
-- any off-the-shelf decoder, and the emitted bootstrap carries its own matching
-- alphabet assembled from string.char (never a plain literal).

local Pack = {}

local BASE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function bxor(a, b)
    local r, p = 0, 1
    while a > 0 or b > 0 do
        local aa, bb = a % 2, b % 2
        if aa ~= bb then r = r + p end
        a = (a - aa) / 2
        b = (b - bb) / 2
        p = p * 2
    end
    return r
end

local function xorStream(data, key)
    local out, st = {}, key % 2147483648
    for i = 1, #data do
        st = (st * 1103515245 + 12345) % 2147483648
        out[i] = string.char(bxor(data:byte(i), st % 256))
    end
    return table.concat(out)
end

-- Fisher-Yates shuffle of the base alphabet driven by the shared PRNG.
local function shuffledAlphabet(rng)
    local a = {}
    for i = 1, #BASE do a[i] = BASE:sub(i, i) end
    for i = #a, 2, -1 do
        local j = rng:range(1, i)
        a[i], a[j] = a[j], a[i]
    end
    return table.concat(a)
end

local function b64encode(data, alpha)
    local out, len = {}, #data
    local function ch(n) return alpha:sub(n + 1, n + 1) end
    for i = 1, len, 3 do
        local b1 = data:byte(i)
        local b2 = i + 1 <= len and data:byte(i + 1) or 0
        local b3 = i + 2 <= len and data:byte(i + 2) or 0
        local n = b1 * 65536 + b2 * 256 + b3
        out[#out + 1] = ch(math.floor(n / 262144) % 64)
        out[#out + 1] = ch(math.floor(n / 4096) % 64)
        out[#out + 1] = i + 1 <= len and ch(math.floor(n / 64) % 64) or "="
        out[#out + 1] = i + 2 <= len and ch(n % 64) or "="
    end
    return table.concat(out)
end

local function chunks(s, n)
    local t = {}
    for i = 1, #s, n do t[#t + 1] = s:sub(i, i + n - 1) end
    return t
end

-- body: the transformed Lua source. rng: the shared deterministic PRNG.
function Pack.wrap(body, rng)
    local alpha = shuffledAlphabet(rng)
    local key = rng:range(1, 2147483000)
    local cipher = xorStream(body, key)
    local encoded = b64encode(cipher, alpha)
    local parts = chunks(encoded, 100)

    local nA = rng:name(6)  -- alphabet
    local nP = rng:name(6)  -- payload chunk table
    local nS = rng:name(6)  -- assembled base64 string
    local nBd = rng:name(7) -- base64 decoder
    local nXd = rng:name(7) -- xor decryptor
    local nSrc = rng:name(6)-- decrypted source
    local nLd = rng:name(6) -- load function
    local nFn = rng:name(6) -- compiled chunk

    local L = {}
    local function e(s) L[#L + 1] = s end

    -- shuffled alphabet assembled from bytes, never a plain string literal
    local bytes = {}
    for ch in alpha:gmatch(".") do bytes[#bytes + 1] = tostring(ch:byte(1)) end
    e("local " .. nA .. "=string.char(" .. table.concat(bytes, ",") .. ")")

    e("local " .. nP .. "={")
    for i, c in ipairs(parts) do
        e("'" .. c .. "'" .. (i < #parts and "," or ""))
    end
    e("}")
    e("local " .. nS .. "=table.concat(" .. nP .. ")")

    -- base64 decoder against the shuffled alphabet
    e("local function " .. nBd .. "(s)")
    e("  local r,v,b={},0,0")
    e("  for i=1,#s do")
    e("    local c=s:sub(i,i)")
    e("    if c=='=' then break end")
    e("    local p=" .. nA .. ":find(c,1,true)")
    e("    if not p then break end")
    e("    v=v*64+(p-1) b=b+6")
    e("    if b>=8 then b=b-8 r[#r+1]=string.char(math.floor(v/2^b)%256) v=v%(2^b) end")
    e("  end")
    e("  return table.concat(r)")
    e("end")

    -- xor decryptor (keystream identical to build-time xorStream)
    e("local function " .. nXd .. "(d,k)")
    e("  local r,st={},k%2147483648")
    e("  for i=1,#d do")
    e("    st=(st*1103515245+12345)%2147483648")
    e("    local a,b=d:byte(i),st%256")
    e("    local x,p=0,1")
    e("    while a>0 or b>0 do")
    e("      local aa,bb=a%2,b%2")
    e("      if aa~=bb then x=x+p end")
    e("      a=(a-aa)/2 b=(b-bb)/2 p=p*2")
    e("    end")
    e("    r[i]=string.char(x)")
    e("  end")
    e("  return table.concat(r)")
    e("end")

    e("local " .. nSrc .. "=" .. nXd .. "(" .. nBd .. "(" .. nS .. ")," .. tostring(key) .. ")")
    e("local " .. nLd .. "=loadstring or load")
    e("local " .. nFn .. "=" .. nLd .. "(" .. nSrc .. ",'@capybara')")
    e("return " .. nFn .. "()")

    return table.concat(L, "\n") .. "\n"
end

return Pack
