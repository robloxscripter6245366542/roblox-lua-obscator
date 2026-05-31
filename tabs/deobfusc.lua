local SS = _G._SS
local C  = SS.C
local Frm,Lbl,Btn,Inp,Con,hov,tw = SS.Frm,SS.Lbl,SS.Btn,SS.Inp,SS.Con,SS.hov,SS.tw
local listH,rowBar = SS.listH,SS.rowBar
local FB,FN = SS.FB,SS.FN

local P = SS.newTab("👁","Deobfusc.")

Lbl(P, "DEOBFUSCATOR", UDim2.new(1,0,0,16), UDim2.new(0,0,0,0), C.TXTS, FB, 11)
Lbl(P, "Input:",       UDim2.new(0,45,0,12), UDim2.new(0,0,0,18), C.TXTS, FN, 11)

local DIn   = Inp(P, "-- Paste obfuscated Lua here...", UDim2.new(1,0,0,152), UDim2.new(0,0,0,32))
local dRow  = rowBar(P, 190)
local BDDet  = Btn(dRow, "Detect Type",  UDim2.new(0,116,1,0), nil, C.BLUE)
local BDDeob = Btn(dRow, "Deobfuscate",  UDim2.new(0,128,1,0), nil, C.ACC)
BDDet.LayoutOrder=1; BDDeob.LayoutOrder=2
hov(BDDet,C.BLUE,C.BLHV); hov(BDDeob,C.ACC,C.ACCHV)

Lbl(P, "Output:", UDim2.new(0,55,0,12), UDim2.new(0,0,0,222), C.TXTS, FN, 11)
local DOut = Con(P, UDim2.new(1,0,1,-236), UDim2.new(0,0,0,236))

local function detectType(s)
    if s:lower():find("luraph")                        then return "Luraph VM" end
    if s:lower():find("getfenv") and s:find("0x%x+")  then return "IronBrew 2" end
    if s:lower():find("prometheus")                    then return "Prometheus" end
    if s:lower():find("moonsec")                       then return "Moonsec" end
    if s:lower():find("bytecode")                      then return "Bytecode (custom VM)" end
    if s:find("\\x%x%x")                              then return "Hex-escape encoded" end
    if s:find("string%.char%(%d")                     then return "string.char encoded" end
    if s:find("_[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]") then return "Hex-variable names" end
    if s:find("^%s*local%s+[a-zA-Z_][a-zA-Z0-9_]*%s*=%s*{")
        and #s > 5000                                  then return "Table-encoded VM (custom)" end
    return "Unknown / plain Lua"
end

local function deobfuscate(s)
    -- Decode \xHH hex escapes
    s = s:gsub("\\x(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
    -- Decode \DDD decimal escapes
    s = s:gsub("\\(%d%d?%d?)", function(d)
        local n = tonumber(d)
        return (n and n<=255) and string.char(n) or "\\"..d
    end)
    -- Resolve string.char(...) calls
    s = s:gsub("string%.char%(([%d,%s]+)%)", function(args)
        local out = {}
        for n in args:gmatch("%d+") do
            local num = tonumber(n); if num then out[#out+1] = string.char(num) end
        end
        return '"'..table.concat(out)..'"'
    end)
    -- Collapse string concatenation
    for _ = 1, 8 do s = s:gsub('"([^"]*)"%s*%.%.%s*"([^"]*)"', '"%1%2"') end
    return s
end

BDDet.MouseButton1Click:Connect(function()
    DOut.TextColor3 = C.YELL; DOut.Text = "Type: "..detectType(DIn.Text)
end)
BDDeob.MouseButton1Click:Connect(function()
    if DIn.Text == "" then DOut.TextColor3 = C.RED; DOut.Text = "Nothing to deobfuscate."; return end
    local ok2, res = pcall(deobfuscate, DIn.Text)
    DOut.TextColor3 = ok2 and C.GREEN or C.RED
    DOut.Text = ok2 and res or ("Error: "..tostring(res))
end)
