-- TAB: Execute  (Client loadstring / Server LS / Require / URL Exec)
local SS = _G._SS
local C,tw,corner,stroke,pad,listH,listV=SS.C,SS.tw,SS.corner,SS.stroke,SS.pad,SS.listH,SS.listV
local F,L,B,IN,OUT,SCR,hov=SS.F,SS.L,SS.B,SS.IN,SS.OUT,SS.SCR,SS.hov
local bridge=SS.bridge

local P = SS.registerTab("▶", "Execute")

-- Mode bar
local MB = F(P,UDim2.new(1,0,0,26),UDim2.new(0,0,0,0),C.SIDE)
corner(MB,7); listH(MB,3); pad(MB,3,3)

local MODES   = {"Client LS","Server LS","Require","URL Exec"}
local modeBtns= {}
local curMode = 1
local function setMode(i)
    curMode=i
    for j,b in modeBtns do
        b.BackgroundTransparency = j==i and 0 or 1
        tw(b,{BackgroundColor3=j==i and C.BLUE or C.SIDE})
        b.TextColor3 = j==i and C.TXT or C.TXTS
    end
end
for i,name in MODES do
    local b = Instance.new("TextButton")
    b.Size=UDim2.new(0,125,1,-6); b.BackgroundTransparency=1; b.BackgroundColor3=C.BLUE
    b.Text=name; b.TextColor3=C.TXTS; b.Font=SS.FM; b.TextSize=12
    b.AutoButtonColor=false; b.BorderSizePixel=0; b.LayoutOrder=i; b.Parent=MB
    corner(b,5)
    b.MouseButton1Click:Connect(function() setMode(i) end)
    modeBtns[i]=b
end

-- Editor
local EDITOR = IN(P,
    "-- Client LS  → loadstring locally\n"..
    "-- Server LS  → send to server bridge\n"..
    "-- Require    → type the asset ID number\n"..
    "-- URL Exec   → paste a raw Lua URL",
    UDim2.new(1,0,0,190),UDim2.new(0,0,0,32))

-- Button row
local BR = F(P,UDim2.new(1,0,0,26),UDim2.new(0,0,0,228),C.SIDE)
BR.BackgroundTransparency=1; listH(BR,4)
local BExec  = B(BR,"▶  Execute",UDim2.new(0,142,1,0),nil,C.ACC)
local BClear = B(BR,"Clear",     UDim2.new(0,80,1,0),nil,C.GREY)
local BCopy  = B(BR,"Copy",      UDim2.new(0,80,1,0),nil,C.GREY)
BExec.LayoutOrder=1; BClear.LayoutOrder=2; BCopy.LayoutOrder=3
hov(BExec,C.ACC,C.ACCHV); hov(BClear,C.GREY,C.GREYHV); hov(BCopy,C.GREY,C.GREYHV)

-- Console
L(P,"CONSOLE",UDim2.new(0,80,0,14),UDim2.new(0,0,0,260),C.TXTD,SS.FB,10)
local CONS = OUT(P,UDim2.new(1,0,0,95),UDim2.new(0,0,0,276))

local function log(msg,col) CONS.TextColor3=col or C.GREEN; CONS.Text=tostring(msg) end

-- Execute handler
BExec.MouseButton1Click:Connect(function()
    local code=EDITOR.Text; if code=="" then log("No code.",C.YELLOW); return end
    tw(BExec,{BackgroundColor3=C.ACCHV}); task.wait(0.08); tw(BExec,{BackgroundColor3=C.ACC})

    if curMode==1 then
        local fn,ce=loadstring(code)
        if not fn then log("Compile error:\n"..tostring(ce),C.RED); return end
        local ok,re=pcall(fn)
        log(ok and "✓ Executed OK." or "✗ Runtime error:\n"..tostring(re), ok and C.GREEN or C.RED)

    elseif curMode==2 then
        local ok,msg=bridge("ls",{code=code}); log(msg or "(no response)",ok and C.GREEN or C.RED)

    elseif curMode==3 then
        local id=tonumber(code:match("%d+"))
        if not id then log("Enter a numeric asset ID.",C.YELLOW); return end
        local ok,res=pcall(require,id)
        log(ok and "✓ require("..id..") OK." or "✗ "..tostring(res), ok and C.GREEN or C.RED)

    elseif curMode==4 then
        local url=code:match("^%s*(.-)%s*$"); if url=="" then log("Enter a URL.",C.YELLOW); return end
        local ok,src=pcall(game.HttpGet,game,url,true)
        if not ok then log("✗ HTTP: "..tostring(src),C.RED); return end
        local fn,ce=loadstring(src)
        if not fn then log("✗ Compile: "..tostring(ce),C.RED); return end
        local ok2,re=pcall(fn)
        log(ok2 and "✓ URL exec OK." or "✗ "..tostring(re), ok2 and C.GREEN or C.RED)
    end
end)

BClear.MouseButton1Click:Connect(function() EDITOR.Text=""; CONS.Text="" end)
BCopy.MouseButton1Click:Connect(function()
    if setclipboard then setclipboard(EDITOR.Text); log("✓ Copied.",C.GREEN)
    else log("setclipboard unavailable.",C.YELLOW) end
end)

setMode(1)
