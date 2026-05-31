local SS = _G._SS
local C  = SS.C
local Frm,Lbl,Btn,Inp,Con,hov,tw = SS.Frm,SS.Lbl,SS.Btn,SS.Inp,SS.Con,SS.hov,SS.tw
local listH,rowBar = SS.listH,SS.rowBar
local callBridge   = SS.callBridge
local FN = SS.FN

local P = SS.newTab("▶","Execute")

-- Mode strip
local mRow = rowBar(P, 0)
local modes = {"Client LS","Server LS","Require","URL Exec"}
local mBtns = {}; local curMode = 1

local function setMode(i)
    curMode = i
    for j,b in mBtns do
        tw(b, {BackgroundColor3=j==i and C.BLUE or C.EDIT})
        b.TextColor3 = j==i and C.TXT or C.TXTS
    end
end

for i,nm in modes do
    local b = Btn(mRow, nm, UDim2.new(0,120,1,0), nil, i==1 and C.BLUE or C.EDIT, C.TXTS)
    b.LayoutOrder = i; b.TextSize = 12
    hov(b, i==1 and C.BLUE or C.EDIT, C.BLHV)
    b.MouseButton1Click:Connect(function() setMode(i) end)
    mBtns[i] = b
end

local Editor = Inp(P,
    "-- Paste or type Lua here\n-- Client LS  : runs locally via loadstring\n-- Server LS  : runs server-side via bridge\n-- Require    : enter asset ID number\n-- URL Exec   : enter a raw script URL",
    UDim2.new(1,0,0,188), UDim2.new(0,0,0,32))

local aRow  = rowBar(P, 226)
local BExec  = Btn(aRow, "▶ Execute", UDim2.new(0,130,1,0), nil, C.ACC)
local BClear = Btn(aRow, "Clear",     UDim2.new(0,76,1,0),  nil, C.GREY)
local BCopy  = Btn(aRow, "Copy",      UDim2.new(0,76,1,0),  nil, C.GREY)
BExec.LayoutOrder=1; BClear.LayoutOrder=2; BCopy.LayoutOrder=3
hov(BExec,C.ACC,C.ACCHV); hov(BClear,C.GREY,C.GRYHV); hov(BCopy,C.GREY,C.GRYHV)

Lbl(P, "Output", UDim2.new(0,55,0,14), UDim2.new(0,0,0,258), C.TXTS, FN, 11)
local ExOut = Con(P, UDim2.new(1,0,0,82), UDim2.new(0,0,0,274))

local function exOut(msg, isErr)
    ExOut.TextColor3 = isErr and C.RED or C.GREEN
    ExOut.Text = tostring(msg)
end

BExec.MouseButton1Click:Connect(function()
    local code = Editor.Text
    if code == "" then exOut("No code entered.", true); return end
    tw(BExec,{BackgroundColor3=C.ACCHV}); task.wait(0.07); tw(BExec,{BackgroundColor3=C.ACC})

    if curMode == 1 then
        local ld = loadstring or load
        local fn, ce = ld(code)
        if not fn then exOut("Compile error:\n"..tostring(ce), true); return end
        local ok2, re = pcall(fn)
        exOut(ok2 and "Client exec OK." or "Runtime error:\n"..tostring(re), not ok2)

    elseif curMode == 2 then
        local ok2, msg2 = callBridge("ls", {code=code})
        exOut(msg2 or "(no response)", not ok2)

    elseif curMode == 3 then
        local id = tonumber(code:match("%d+"))
        if not id then exOut("Enter a numeric Roblox asset ID.", true); return end
        local ok2, res = pcall(require, id)
        exOut(ok2 and ("require("..id..") OK.") or ("Error:\n"..tostring(res)), not ok2)

    elseif curMode == 4 then
        local url = code:match("^%s*(.-)%s*$")
        if url == "" then exOut("Enter a raw script URL.", true); return end
        local ok2, src = pcall(game.HttpGet, game, url, true)
        if not ok2 then exOut("HTTP error:\n"..tostring(src), true); return end
        local ld = loadstring or load
        local fn, ce = ld(src)
        if not fn then exOut("Compile error:\n"..tostring(ce), true); return end
        local ok3, re = pcall(fn)
        exOut(ok3 and "URL exec OK." or ("Runtime error:\n"..tostring(re)), not ok3)
    end
end)

BClear.MouseButton1Click:Connect(function() Editor.Text = ""; exOut("", false) end)
BCopy.MouseButton1Click:Connect(function()
    if setclipboard then setclipboard(Editor.Text); exOut("Copied.", false)
    else exOut("setclipboard not available.", true) end
end)

setMode(1)
