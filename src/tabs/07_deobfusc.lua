-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB 7 — DEOBFUSCATOR
--  Detect type · Multi-pass deobfusc · Base64 · Hex · string.char
-- ═══════════════════════════════════════════════════════════════════════════════
local P7 = newTab("👁", "Deobfusc.")
L(P7, "DEOBFUSCATOR", UDim2.new(1,0,0,16), UDim2.new(0,0,0,0), C.TXTS, FB, 11)
L(P7, "Input:", UDim2.new(0,45,0,12), UDim2.new(0,0,0,18), C.TXTS, FN, 11)
local DIn = IN(P7, "-- Paste obfuscated / encoded Lua here…", UDim2.new(1,0,0,150), UDim2.new(0,0,0,32))

local dRow1 = rowBar(P7, 186, 26)
local BDDet  = B(dRow1, "Detect",       UDim2.new(0,90,1,0),  nil, C.BLUE)
local BDDeob = B(dRow1, "Deobfuscate",  UDim2.new(0,116,1,0), nil, C.ACC)
local BDB64  = B(dRow1, "Base64 Dec",   UDim2.new(0,100,1,0), nil, C.GREY)
local BDHex  = B(dRow1, "Hex Dec",      UDim2.new(0,80,1,0),  nil, C.GREY)
local BDChar = B(dRow1, "Chr Dec",      UDim2.new(0,80,1,0),  nil, C.GREY)
styleRow({BDDet,BDDeob,BDB64,BDHex,BDChar})
hov(BDDet,  C.BLUE, C.BLHV); hov(BDDeob, C.ACC,  C.ACCHV)
hov(BDB64,  C.GREY, C.GRYHV); hov(BDHex,  C.GREY, C.GRYHV)
hov(BDChar, C.GREY, C.GRYHV)

local dRow2  = rowBar(P7, 216, 26)
local BDSwap = B(dRow2, "Swap I↔O",  UDim2.new(0,96,1,0),  nil, C.GREY)
local BDCopy = B(dRow2, "Copy Out",   UDim2.new(0,90,1,0),  nil, C.GREY)
local BDSave = B(dRow2, "Save Out",   UDim2.new(0,90,1,0),  nil, C.GREY)
local BDRun  = B(dRow2, "▶ Run Out",  UDim2.new(0,90,1,0),  nil, C.GRN)
styleRow({BDSwap,BDCopy,BDSave,BDRun})
hov(BDSwap, C.GREY, C.GRYHV); hov(BDCopy, C.GREY, C.GRYHV)
hov(BDSave, C.GREY, C.GRYHV); hov(BDRun,  C.GRN,  C.GRNHV)

L(P7, "Output:", UDim2.new(0,55,0,12), UDim2.new(0,0,0,248), C.TXTS, FN, 11)
local DOut = OUT(P7, UDim2.new(1,0,1,-262), UDim2.new(0,0,0,262))

-- ── Detection ─────────────────────────────────────────────────────────────────
local DETECTORS = {
    {pat="luraph",                            lbl="Luraph VM obfuscation"},
    {pat="getfenv",   pat2="0x%x+",          lbl="IronBrew 2"},
    {pat="prometheus",                        lbl="Prometheus"},
    {pat="moonsec",                           lbl="Moonsec"},
    {pat="bytecode",  pat2="\\x",            lbl="Custom bytecode VM"},
    {pat="\\x%x%x",                           lbl="Hex-escape encoded"},
    {pat="string%.char%(%d",                  lbl="string.char encoded"},
    {pat="[A-Za-z0-9+/]+=?=?$",              lbl="Possible Base64"},
    {pat="_[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]",lbl="Hex variable names"},
    {pat="\\%d%d%d",                          lbl="Decimal-escape encoded"},
    {pat="xor_key",                           lbl="XOR key obfuscation"},
    {pat="rot%d",                             lbl="ROT cipher"},
    {pat="bitwise",                           lbl="Bitwise obfuscation"},
}

local function detectType(s)
    s = s:lower()
    for _, d in DETECTORS do
        local match = s:find(d.pat)
        if match and (not d.pat2 or s:find(d.pat2)) then
            return d.lbl
        end
    end
    return "Unknown / plain Lua"
end

-- ── Base64 decode ─────────────────────────────────────────────────────────────
local B64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function b64decode(s)
    s = s:gsub("[^" .. B64_CHARS .. "=]", "")
    return (s:gsub(".", function(x)
        if x == "=" then return "" end
        local r, f = "", B64_CHARS:find(x) - 1
        for i = 6, 1, -1 do
            r = r .. (f % 2^i - f % 2^(i-1) > 0 and "1" or "0")
        end
        return r
    end):gsub("%d%d%d%d%d%d%d%d", function(x)
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i,i)=="1" and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

-- ── Hex decode ────────────────────────────────────────────────────────────────
local function hexdecode(s)
    local out = {}
    for hex in s:gmatch("%x%x") do
        out[#out+1] = string.char(tonumber(hex, 16))
    end
    return table.concat(out)
end

-- ── string.char decode ────────────────────────────────────────────────────────
local function chardecode(s)
    return (s:gsub("string%.char%(([%d,%s]+)%)", function(args)
        local out = {}
        for n in args:gmatch("%d+") do
            local num = tonumber(n)
            if num then out[#out+1] = string.char(num) end
        end
        return '"' .. table.concat(out) .. '"'
    end))
end

-- ── Multi-pass deobfuscate ────────────────────────────────────────────────────
local function deobfuscate(s)
    -- pass 1: hex escapes
    s = s:gsub("\\x(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
    -- pass 2: decimal escapes
    s = s:gsub("\\(%d%d?%d?)", function(d)
        local n = tonumber(d)
        return (n and n <= 255) and string.char(n) or "\\" .. d
    end)
    -- pass 3: string.char patterns
    s = chardecode(s)
    -- pass 4: string concat collapse
    for _ = 1, 16 do
        s = s:gsub('"([^"]*)"%s*%.%.%s*"([^"]*)"', '"%1%2"')
    end
    -- pass 5: remove redundant local blocks
    s = s:gsub("do%s+local%s+([%w_]+)%s*=%s*([^\n]+)\n%s*end",
        function(v, e) return "local " .. v .. " = " .. e end)
    -- pass 6: unpack tostring wraps
    s = s:gsub("tostring%(\"([^\"]+)\"%)", '"%1"')
    -- pass 7: collapse double negations
    s = s:gsub("not not ", "")
    return s
end

-- ── Handlers ──────────────────────────────────────────────────────────────────
BDDet.MouseButton1Click:Connect(function()
    local t = detectType(DIn.Text)
    DOut.TextColor3 = C.YELL; DOut.Text = "Detected: " .. t
end)

BDDeob.MouseButton1Click:Connect(function()
    if trim(DIn.Text) == "" then DOut.TextColor3=C.RED; DOut.Text="Nothing to deobfuscate."; return end
    local ok2, res = pcall(deobfuscate, DIn.Text)
    DOut.TextColor3 = ok2 and C.GRN or C.RED
    DOut.Text = ok2 and res or "Error: " .. tostring(res)
end)

BDB64.MouseButton1Click:Connect(function()
    local ok2, res = pcall(b64decode, trim(DIn.Text))
    DOut.TextColor3 = ok2 and C.GRN or C.RED
    DOut.Text = ok2 and res or "Base64 decode failed: " .. tostring(res)
end)

BDHex.MouseButton1Click:Connect(function()
    local res = hexdecode(DIn.Text)
    if res == "" then DOut.TextColor3=C.RED; DOut.Text="No hex bytes found."
    else DOut.TextColor3=C.GRN; DOut.Text=res end
end)

BDChar.MouseButton1Click:Connect(function()
    local ok2, res = pcall(chardecode, DIn.Text)
    DOut.TextColor3 = ok2 and C.GRN or C.RED
    DOut.Text = ok2 and res or "Error: " .. tostring(res)
end)

BDSwap.MouseButton1Click:Connect(function()
    local tmp = DIn.Text; DIn.Text = DOut.Text; DOut.Text = tmp
end)

BDCopy.MouseButton1Click:Connect(function()
    if setclipboard then setclipboard(DOut.Text); DOut.TextColor3=C.GRN
    else DOut.TextColor3=C.RED; DOut.Text="setclipboard unavailable." end
end)

BDSave.MouseButton1Click:Connect(function()
    if not writefile then DOut.TextColor3=C.RED; DOut.Text="writefile unavailable."; return end
    local fname = "nexus_deobf_" .. os.time() .. ".lua"
    writefile(fname, DOut.Text)
    DOut.TextColor3 = C.GRN; DOut.Text = "Saved → " .. fname .. "\n" .. DOut.Text
end)

BDRun.MouseButton1Click:Connect(function()
    local code = DOut.Text
    if trim(code) == "" then DOut.TextColor3=C.RED; DOut.Text="Output is empty."; return end
    local ok2, err, stage = runCode(code)
    DOut.TextColor3 = ok2 and C.GRN or C.RED
    if not ok2 then
        DOut.Text = (stage=="compile" and "Compile error:\n" or "Runtime error:\n")..err; return
    end
    DOut.Text = "Output executed OK."
end)
