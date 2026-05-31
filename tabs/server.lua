local SS = _G._SS
local C  = SS.C
local Frm,Lbl,Btn,Inp,Con,hov,tw = SS.Frm,SS.Lbl,SS.Btn,SS.Inp,SS.Con,SS.hov,SS.tw
local listH,rowBar = SS.listH,SS.rowBar
local callBridge,pingBridge = SS.callBridge,SS.pingBridge
local FN = SS.FN

local P = SS.newTab("⚙","Server")

Lbl(P, "SERVER COMMANDS", UDim2.new(1,0,0,16), UDim2.new(0,0,0,0), C.TXTS, SS.FB, 11)

local SrvOut = Con(P, UDim2.new(1,0,0,80), UDim2.new(0,0,1,-82))
local function srvOut(msg, isErr)
    SrvOut.TextColor3 = isErr and C.RED or C.GREEN; SrvOut.Text = tostring(msg)
end
local function bridgeOut(action, payload)
    local ok2, msg2, data = callBridge(action, payload)
    local lines = {msg2 or ""}
    if data then for _,l in data do lines[#lines+1] = l end end
    srvOut(table.concat(lines, "\n"), not ok2)
end

-- Server script editor
Lbl(P, "Server Loadstring:", UDim2.new(1,0,0,14), UDim2.new(0,0,0,20), C.TXTS, FN, 11)
local SrvEdit = Inp(P, "-- Code to run server-side...", UDim2.new(1,0,0,85), UDim2.new(0,0,0,36))

local sRow1   = rowBar(P, 127)
local BSrvRun = Btn(sRow1, "▶ Run Server-Side", UDim2.new(0,150,1,0), nil, C.BLUE)
local BSrvURL = Btn(sRow1, "Run URL Server",    UDim2.new(0,130,1,0), nil, C.GREY)
BSrvRun.LayoutOrder=1; BSrvURL.LayoutOrder=2
hov(BSrvRun,C.BLUE,C.BLHV); hov(BSrvURL,C.GREY,C.GRYHV)

BSrvRun.MouseButton1Click:Connect(function()
    local code = SrvEdit.Text
    if code == "" then srvOut("No code entered.", true); return end
    bridgeOut("ls", {code=code})
end)
BSrvURL.MouseButton1Click:Connect(function()
    local url = SrvEdit.Text:match("^%s*(.-)%s*$")
    if url == "" then srvOut("Enter a URL.", true); return end
    bridgeOut("ls_url", {url=url})
end)

-- Utility buttons
local sRow2    = rowBar(P, 161)
local BGetPlrs = Btn(sRow2, "Players",    UDim2.new(0,90,1,0),  nil, C.GREY)
local BGetScr  = Btn(sRow2, "Scripts",    UDim2.new(0,90,1,0),  nil, C.GREY)
local BPing    = Btn(sRow2, "Ping Bridge",UDim2.new(0,110,1,0), nil, C.ACC)
local BReq     = Btn(sRow2, "Require ID", UDim2.new(0,100,1,0), nil, C.GREY)
BGetPlrs.LayoutOrder=1; BGetScr.LayoutOrder=2; BPing.LayoutOrder=3; BReq.LayoutOrder=4
hov(BGetPlrs,C.GREY,C.GRYHV); hov(BGetScr,C.GREY,C.GRYHV); hov(BPing,C.ACC,C.ACCHV); hov(BReq,C.GREY,C.GRYHV)

BGetPlrs.MouseButton1Click:Connect(function() bridgeOut("getplrs") end)
BGetScr.MouseButton1Click:Connect(function()  bridgeOut("get_scripts") end)
BPing.MouseButton1Click:Connect(function()
    local alive = pingBridge()
    srvOut(alive and "Bridge responded: pong ✓" or "Bridge offline. Inject SS_Executor.lua first.", not alive)
end)
BReq.MouseButton1Click:Connect(function()
    local id = tonumber(SrvEdit.Text:match("%d+"))
    if not id then srvOut("Paste a numeric asset ID into the editor.", true); return end
    bridgeOut("req", {id=id})
end)
