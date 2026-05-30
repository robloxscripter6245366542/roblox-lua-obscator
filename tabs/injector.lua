-- TAB: Injector  (Auto-inject server bridge + hook remotes to run SS)
local SS = _G._SS
local C,tw,corner,stroke,pad,listH,listV=SS.C,SS.tw,SS.corner,SS.stroke,SS.pad,SS.listH,SS.listV
local F,L,B,IN,OUT,SCR,hov=SS.F,SS.L,SS.B,SS.IN,SS.OUT,SS.SCR,SS.hov
local bridge=SS.bridge
local LP=SS.LP

local P = SS.registerTab("💉", "Injector")

L(P,"SS INJECTOR",UDim2.new(1,0,0,16),nil,C.TXTS,SS.FB,11)

-- Status box
local StatusBox = F(P,UDim2.new(1,0,0,48),UDim2.new(0,0,0,20),C.CONSOLE)
corner(StatusBox,7); stroke(StatusBox,C.BORDER,1)
local StatusLbl = L(StatusBox,
    "  Status: checking bridge...",
    UDim2.new(1,-8,1,0),UDim2.new(0,4,0,0),
    C.YELLOW,SS.FC,12)

-- Update status
task.spawn(function()
    local ok = bridge("ping")
    StatusLbl.Text = ok
        and "  ✓ Bridge active — server-side ready."
        or  "  ✗ Bridge offline — inject SS_Executor.lua server-side."
    StatusLbl.TextColor3 = ok and C.GREEN or C.RED
end)

-- Info box
local INFO = F(P,UDim2.new(1,0,0,88),UDim2.new(0,0,0,74),C.PANEL)
corner(INFO,7); stroke(INFO,C.BORDER,1); pad(INFO,10,12)

L(INFO,"How to inject the server bridge:",UDim2.new(1,0,0,18),nil,C.TXT,SS.FB,13)
L(INFO,"1. Open Roblox Studio or a game with script injection.",
    UDim2.new(1,0,0,16),UDim2.new(0,0,0,22),C.TXTS,SS.FN,12)
L(INFO,"2. Insert a Script (server) and paste SS_Executor.lua.",
    UDim2.new(1,0,0,16),UDim2.new(0,0,0,40),C.TXTS,SS.FN,12)
L(INFO,"3. Once running, this executor can push code to the server.",
    UDim2.new(1,0,0,16),UDim2.new(0,0,0,58),C.TXTS,SS.FN,12)

-- Auto-inject: try to create the bridge remote from the client
-- (works on executors with elevated permissions)
local R1 = F(P,UDim2.new(1,0,0,26),UDim2.new(0,0,0,168),C.SIDE)
R1.BackgroundTransparency=1; listH(R1,4)
local B_INJECT = B(R1,"Auto-Inject Bridge",UDim2.new(0,168,1,0),nil,C.ACC)
local B_RECHECK= B(R1,"Re-check",          UDim2.new(0,100,1,0),nil,C.GREY)
local B_SSURL  = B(R1,"Get SS_Executor.lua",UDim2.new(0,160,1,0),nil,C.BLUE)
B_INJECT.LayoutOrder=1; B_RECHECK.LayoutOrder=2; B_SSURL.LayoutOrder=3
hov(B_INJECT,C.ACC,C.ACCHV); hov(B_RECHECK,C.GREY,C.GREYHV); hov(B_SSURL,C.BLUE,C.BLUEHV)

-- Remote hook injector — fires an existing remote with a custom payload
L(P,"REMOTE HOOK EXEC",UDim2.new(1,0,0,14),UDim2.new(0,0,0,202),C.TXTD,SS.FB,10)

local R2 = F(P,UDim2.new(1,0,0,26),UDim2.new(0,0,0,218),C.SIDE)
R2.BackgroundTransparency=1; listH(R2,4)
local B_HOOK_SCAN  = B(R2,"Scan Remotes",  UDim2.new(0,120,1,0),nil,C.GREY)
local B_HOOK_BLOCK = B(R2,"Block Remote",  UDim2.new(0,120,1,0),nil,C.RED)
B_HOOK_SCAN.LayoutOrder=1; B_HOOK_BLOCK.LayoutOrder=2
hov(B_HOOK_SCAN,C.GREY,C.GREYHV); hov(B_HOOK_BLOCK,C.RED,C.REDHV)

local REMOTE_IN = IN(P,"Paste remote full path (e.g. ReplicatedStorage.RemoteName)",
    UDim2.new(1,0,0,28),UDim2.new(0,0,0,250))
REMOTE_IN.MultiLine=false

L(P,"LOG",UDim2.new(0,40,0,12),UDim2.new(0,0,0,284),C.TXTD,SS.FB,10)
local CONS = OUT(P,UDim2.new(1,0,0,80),UDim2.new(0,0,0,298))

local function log(msg,ok2)
    CONS.TextColor3=ok2 and C.GREEN or C.RED; CONS.Text=tostring(msg)
end

B_INJECT.MouseButton1Click:Connect(function()
    log("Attempting auto-inject...",true)
    -- Try to create SS_ExecBridge remote from client
    local RS=game:GetService("ReplicatedStorage")
    local existing=RS:FindFirstChild("SS_ExecBridge")
    if existing then
        log("✓ SS_ExecBridge already exists.",true); return
    end
    -- Some executors allow creating instances with elevated permissions
    local ok2,err2=pcall(function()
        local remote=Instance.new("RemoteFunction")
        remote.Name="SS_ExecBridge"; remote.Parent=RS
    end)
    log(ok2 and "✓ Remote created — now inject SS_Executor.lua to wire the handler."
             or "✗ Cannot create remote from client — inject server-side manually.\n"..tostring(err2),
        ok2)
end)

B_RECHECK.MouseButton1Click:Connect(function()
    local ok2=bridge("ping")
    StatusLbl.Text = ok2 and "  ✓ Bridge active — server-side ready."
                          or "  ✗ Bridge offline."
    StatusLbl.TextColor3 = ok2 and C.GREEN or C.RED
    log(ok2 and "Bridge is live." or "Bridge not responding.",ok2)
end)

B_SSURL.MouseButton1Click:Connect(function()
    local ssURL="https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/claude/session-UDpk7/SS_Executor.lua"
    if setclipboard then
        setclipboard(ssURL)
        log("✓ SS_Executor.lua URL copied — paste into a server Script.",true)
    else
        log(ssURL,true)
    end
end)

B_HOOK_SCAN.MouseButton1Click:Connect(function()
    local ok2,m,data=bridge("scan"); if not ok2 then log(m,false); return end
    local lines={m or ""}
    if data then for _,l in data do lines[#lines+1]=l end end
    log(table.concat(lines,"\n"),true)
end)

B_HOOK_BLOCK.MouseButton1Click:Connect(function()
    local path=REMOTE_IN.Text:match("^%s*(.-)%s*$")
    if path=="" then log("Enter a remote path.",false); return end
    local ok2,m=bridge("block_remote",{path=path}); log(m,ok2)
end)
