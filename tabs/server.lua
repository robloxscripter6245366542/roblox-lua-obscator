-- TAB: Server Tools  (Server loadstring, require, URL, players)
local SS = _G._SS
local C,tw,corner,stroke,pad,listH,listV=SS.C,SS.tw,SS.corner,SS.stroke,SS.pad,SS.listH,SS.listV
local F,L,B,IN,OUT,SCR,hov=SS.F,SS.L,SS.B,SS.IN,SS.OUT,SS.SCR,SS.hov
local bridge=SS.bridge

local P = SS.registerTab("⚡", "Server")

L(P,"SERVER-SIDE TOOLS",UDim2.new(1,0,0,16),nil,C.TXTS,SS.FB,11)

-- Server editor
local SED = IN(P,
    "-- Code executes on the SERVER\n"..
    "-- Requires SS_Executor.lua running server-side\n"..
    "print('Hello from server!')",
    UDim2.new(1,0,0,185),UDim2.new(0,0,0,20))

-- Top action row
local R1 = F(P,UDim2.new(1,0,0,26),UDim2.new(0,0,0,211),C.SIDE)
R1.BackgroundTransparency=1; listH(R1,4)
local B_SRUN  = B(R1,"▶ Server Run",   UDim2.new(0,138,1,0),nil,C.ACC)
local B_SREQ  = B(R1,"Server Require", UDim2.new(0,136,1,0),nil,C.BLUE)
local B_SURL  = B(R1,"URL Exec",       UDim2.new(0,100,1,0),nil,C.ORANGE)
B_SRUN.LayoutOrder=1; B_SREQ.LayoutOrder=2; B_SURL.LayoutOrder=3
hov(B_SRUN,C.ACC,C.ACCHV)
hov(B_SREQ,C.BLUE,C.BLUEHV)
hov(B_SURL,C.ORANGE,Color3.fromRGB(255,150,50))

-- Bottom utility row
local R2 = F(P,UDim2.new(1,0,0,26),UDim2.new(0,0,0,243),C.SIDE)
R2.BackgroundTransparency=1; listH(R2,4)
local B_PING  = B(R2,"Ping Bridge",  UDim2.new(0,118,1,0),nil,C.GREY)
local B_PLRS  = B(R2,"Get Players",  UDim2.new(0,118,1,0),nil,C.GREY)
local B_SCRS  = B(R2,"List Scripts", UDim2.new(0,118,1,0),nil,C.GREY)
B_PING.LayoutOrder=1; B_PLRS.LayoutOrder=2; B_SCRS.LayoutOrder=3
hov(B_PING,C.GREY,C.GREYHV); hov(B_PLRS,C.GREY,C.GREYHV); hov(B_SCRS,C.GREY,C.GREYHV)

-- Console
L(P,"CONSOLE",UDim2.new(0,80,0,14),UDim2.new(0,0,0,275),C.TXTD,SS.FB,10)
local CONS = OUT(P,UDim2.new(1,0,0,90),UDim2.new(0,0,0,291))

local function log(msg,ok2) CONS.TextColor3=ok2 and C.GREEN or C.RED; CONS.Text=tostring(msg) end

B_SRUN.MouseButton1Click:Connect(function()
    local ok,m=bridge("ls",{code=SED.Text}); log(m or "(no response)",ok)
end)
B_SREQ.MouseButton1Click:Connect(function()
    local id=tonumber(SED.Text:match("%d+"))
    if not id then log("Enter numeric asset ID.",false); return end
    local ok,m=bridge("req",{id=id}); log(m,ok)
end)
B_SURL.MouseButton1Click:Connect(function()
    local url=SED.Text:match("^%s*(.-)%s*$")
    if url=="" then log("Enter a URL.",false); return end
    local ok,m=bridge("ls_url",{url=url}); log(m,ok)
end)
B_PING.MouseButton1Click:Connect(function()
    local ok,m=bridge("ping"); log(m,ok)
end)
B_PLRS.MouseButton1Click:Connect(function()
    local ok,m=bridge("getplrs"); log(m or "No players.",ok)
end)
B_SCRS.MouseButton1Click:Connect(function()
    local ok,m,data=bridge("get_scripts")
    if not ok then log(m,false); return end
    local lines={m or ""}
    if data then for _,l in data do lines[#lines+1]=l end end
    log(table.concat(lines,"\n"),true)
end)
