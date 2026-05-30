-- TAB: Deobfuscator
local SS = _G._SS
local C,tw,corner,stroke,pad,listH,listV=SS.C,SS.tw,SS.corner,SS.stroke,SS.pad,SS.listH,SS.listV
local F,L,B,IN,OUT,SCR,hov=SS.F,SS.L,SS.B,SS.IN,SS.OUT,SS.SCR,SS.hov

local P = SS.registerTab("🔓", "Deobfusc.")

L(P,"DEOBFUSCATOR",UDim2.new(1,0,0,16),nil,C.TXTS,SS.FB,11)

local D_IN=IN(P,"-- Paste obfuscated Lua here...",UDim2.new(1,0,0,168),UDim2.new(0,0,0,20))

local BR=F(P,UDim2.new(1,0,0,26),UDim2.new(0,0,0,194),Color3.fromRGB(0,0,0))
BR.BackgroundTransparency=1;listH(BR,4)

local B_DET =B(BR,"Detect Type",  UDim2.new(0,118,1,0),nil,C.BLUE)
local B_DEOB=B(BR,"Deobfuscate",  UDim2.new(0,128,1,0),nil,C.ACC)
local B_EXEC=B(BR,"Deob + Run",   UDim2.new(0,112,1,0),nil,C.ORANGE)
B_DET.LayoutOrder=1;B_DEOB.LayoutOrder=2;B_EXEC.LayoutOrder=3
hov(B_DET,C.BLUE,C.BLUEHV);hov(B_DEOB,C.ACC,C.ACCHV);hov(B_EXEC,C.ORANGE,Color3.fromRGB(255,150,48))

L(P,"OUTPUT",UDim2.new(0,60,0,14),UDim2.new(0,0,0,226),C.TXTD,SS.FB,10)
local D_OUT=OUT(P,UDim2.new(1,0,1,-244),UDim2.new(0,0,0,242))
D_OUT.TextEditable=true  -- allow copying from output

local function detectObf(s)
    if s:lower():find("luraph")                                 then return "Luraph VM" end
    if s:lower():find("getfenv") and s:find("0x%x+")           then return "IronBrew 2" end
    if s:lower():find("prometheus")                            then return "Prometheus" end
    if s:lower():find("moonsec")                               then return "Moonsec" end
    if s:lower():find("vm_ot") or s:lower():find("vm_d")       then return "Custom VM" end
    if s:find("\\x%x%x")                                       then return "Hex-escape encoded" end
    if s:find("string%.char%(%d")                              then return "string.char encoded" end
    if s:find("_[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]")          then return "Hex variable names" end
    if #s > 300 and not s:find("function") and not s:find("local ") then return "Possible bytecode/base64" end
    return "Unknown / plain Lua"
end

local function deobfuscate(s)
    -- Hex escapes \xHH
    s = s:gsub("\\x(%x%x)", function(h) return string.char(tonumber(h,16)) end)
    -- Decimal escapes \DDD
    s = s:gsub("\\(%d%d?%d?)", function(d)
        local n=tonumber(d); return (n and n<=255) and string.char(n) or "\\"..d
    end)
    -- string.char(n,n,...) fold
    s = s:gsub("string%.char%(([%d,%s]+)%)", function(args)
        local out={}
        for n in args:gmatch("%d+") do
            local num=tonumber(n); if num then out[#out+1]=string.char(num) end
        end
        return '"'..table.concat(out)..'"'
    end)
    -- Concat fold "a".."b" → "ab"
    for _=1,8 do s=s:gsub('"([^"]*)"%s*%.%.%s*"([^"]*)"','"%1%2"') end
    -- Unicode escapes \u{HHHH} (Luau)
    s = s:gsub("\\u{(%x+)}", function(h)
        local n=tonumber(h,16) or 0
        if n<128 then return string.char(n) end
        return "\\u{"..h.."}"
    end)
    -- Remove redundant not not
    s = s:gsub("not not (%w+)", "%1")
    return s
end

B_DET.MouseButton1Click:Connect(function()
    D_OUT.TextColor3=C.YELLOW
    D_OUT.Text="Obfuscation type: "..detectObf(D_IN.Text)
end)

B_DEOB.MouseButton1Click:Connect(function()
    if D_IN.Text=="" then D_OUT.TextColor3=C.RED;D_OUT.Text="Nothing to deobfuscate.";return end
    local ok2,res=pcall(deobfuscate,D_IN.Text)
    D_OUT.TextColor3=ok2 and C.GREEN or C.RED
    D_OUT.Text=ok2 and res or "Error: "..tostring(res)
end)

B_EXEC.MouseButton1Click:Connect(function()
    if D_IN.Text=="" then D_OUT.TextColor3=C.RED;D_OUT.Text="Nothing to run.";return end
    local ok2,res=pcall(deobfuscate,D_IN.Text)
    if not ok2 then D_OUT.TextColor3=C.RED;D_OUT.Text="Deobfuscate error: "..tostring(res);return end
    local fn,ce=loadstring(res)
    if not fn then D_OUT.TextColor3=C.RED;D_OUT.Text="Compile error:\n"..tostring(ce);return end
    local ok3,re=pcall(fn)
    D_OUT.TextColor3=ok3 and C.GREEN or C.RED
    D_OUT.Text=ok3 and "✓ Deobfuscated + executed OK." or "✗ Runtime error:\n"..tostring(re)
end)
