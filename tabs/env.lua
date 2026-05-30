local SS = _G._SS
local C  = SS.C
local Frm,Lbl,Btn,Scr,hov,tw = SS.Frm,SS.Lbl,SS.Btn,SS.Scr,SS.hov,SS.tw
local corner,listH,listV,rowBar = SS.corner,SS.listH,SS.listV,SS.rowBar
local FB,FN,FC = SS.FB,SS.FN,SS.FC

local P = SS.newTab("🧪","Environ")

Lbl(P, "ENVIRONMENT DIAGNOSTICS", UDim2.new(1,0,0,16), UDim2.new(0,0,0,0), C.TXTS, FB, 11)

local envRow   = rowBar(P, 18)
local BEnvRun  = Btn(envRow, "Run Check",   UDim2.new(0,116,1,0), nil, C.ACC)
local BEnvCopy = Btn(envRow, "Copy Report", UDim2.new(0,110,1,0), nil, C.GREY)
BEnvRun.LayoutOrder=1; BEnvCopy.LayoutOrder=2
hov(BEnvRun,C.ACC,C.ACCHV); hov(BEnvCopy,C.GREY,C.GRYHV)

local ExecLbl = Lbl(P, "Executor: checking...", UDim2.new(1,0,0,18), UDim2.new(0,0,0,50), C.TXTS, FC, 12)
local EnvScr  = Scr(P, UDim2.new(1,0,1,-72), UDim2.new(0,0,0,72)); listV(EnvScr, 2)

local reportLines = {}

local function clrEnv()
    for _, ch in EnvScr:GetChildren() do
        if not ch:IsA("UIListLayout") then ch:Destroy() end
    end
    reportLines = {}
end

local function catHdr(title)
    local R = Frm(EnvScr, UDim2.new(1,-4,0,20), nil, C.PANEL); corner(R, 5)
    Lbl(R, "  "..title, UDim2.new(1,0,1,0), nil, C.PURP, FB, 11)
    reportLines[#reportLines+1] = "== "..title.." =="
end

local function chkRow(name, ok2, detail)
    local R = Frm(EnvScr, UDim2.new(1,-4,0,20), nil, Color3.fromRGB(0,0,0))
    R.BackgroundTransparency = 1
    local dot = Frm(R, UDim2.new(0,5,0,5), UDim2.new(0,2,0,7), ok2 and C.GREEN or C.RED)
    corner(dot, 3)
    Lbl(R, name, UDim2.new(0.48,0,1,0), UDim2.new(0,10,0,0), ok2 and C.TXT or C.TXTS, FC, 11)
    Lbl(R, detail or (ok2 and "ok" or "missing"),
        UDim2.new(0.52,-8,1,0), UDim2.new(0.48,0,0,0),
        ok2 and C.GREEN or C.RED, FN, 11)
    reportLines[#reportLines+1] = (ok2 and "[✓] " or "[✗] ")..name.." — "..(detail or "")
end

local LP = SS.LP

local function runCheck()
    clrEnv()
    local exec = "Unknown"
    if identifyexecutor then
        pcall(function() exec = tostring(select(1, identifyexecutor())) end)
    elseif getexecutorname then
        pcall(function() exec = tostring(getexecutorname()) end)
    end
    ExecLbl.Text = "Executor: "..exec; ExecLbl.TextColor3 = C.GREEN

    catHdr("Execution Engine")
    chkRow("loadstring",      type(loadstring)=="function", type(loadstring)=="function" and "available" or "DISABLED")
    chkRow("load (fallback)", type(load)=="function")
    chkRow("pcall",           type(pcall)=="function")
    chkRow("LuaU (continue)", (function()
        return (loadstring or load) and pcall((loadstring or load), "local function f() for i=1,1 do continue end end")
    end)(), "Roblox LuaU syntax")
    chkRow("task scheduler",  type(task)=="table" and type(task.wait)=="function")

    catHdr("Environment Functions")
    chkRow("getgenv",    type(getgenv)=="function")
    chkRow("getrenv",    type(getrenv)=="function")
    chkRow("getfenv",    type(getfenv)=="function")
    chkRow("setfenv",    type(setfenv)=="function")
    chkRow("shared",     type(shared)=="table",  type(shared)=="table" and "global shared table" or "missing")
    chkRow("_G",         type(_G)=="table")
    chkRow("game:GetService", (function() return pcall(function() return game:GetService("Players") end) end)())

    catHdr("File System")
    chkRow("writefile",  type(writefile)=="function")
    chkRow("readfile",   type(readfile)=="function")
    chkRow("isfile",     type(isfile)=="function")
    chkRow("makefolder", type(makefolder)=="function")
    chkRow("listfiles",  type(listfiles)=="function")

    catHdr("HTTP")
    chkRow("game:HttpGet",  type(game.HttpGet)=="function")
    chkRow("request",       type(request)=="function" or (http and type(http.request)=="function") or (syn and type(syn.request)=="function"))
    chkRow("HttpService",   (function() return pcall(function() return game:GetService("HttpService") end) end)())

    catHdr("Sandbox / Injection")
    chkRow("getrawmetatable",   type(getrawmetatable)=="function")
    chkRow("setreadonly",       type(setreadonly)=="function")
    chkRow("hookmetamethod",    type(hookmetamethod)=="function")
    chkRow("hookfunction",      type(hookfunction)=="function" or type(replaceclosure)=="function")
    chkRow("setthreadidentity", type(setthreadidentity)=="function")
    chkRow("gethui",            type(gethui)=="function", type(gethui)=="function" and "available" or "PlayerGui fallback")

    catHdr("RemoteEvent / RemoteFunction")
    chkRow("getnamecallmethod", type(getnamecallmethod)=="function")
    chkRow("firesignal",        type(firesignal)=="function")
    chkRow("getconnections",    type(getconnections)=="function")
    chkRow("SS_ExecBridge",     SS.Bridge~=nil, SS.Bridge and "server bridge ready" or "inject SS_Executor.lua server-side")

    catHdr("Game State")
    chkRow("game:IsLoaded()", game:IsLoaded(), game:IsLoaded() and "fully loaded" or "still loading — run scripts after game loads")
    chkRow("LocalPlayer",     LP~=nil)
    chkRow("Character",       LP and LP.Character~=nil, (LP and LP.Character) and "spawned" or "not spawned yet")

    local pass2, total2 = 0, 0
    for _, ln in reportLines do
        if ln:sub(1,4)=="[✓]" then pass2+=1; total2+=1
        elseif ln:sub(1,4)=="[✗]" then total2+=1 end
    end
    local SR = Frm(EnvScr, UDim2.new(1,-4,0,24), nil, C.PANEL); corner(SR, 5)
    Lbl(SR, string.format("  %d / %d checks passed", pass2, total2),
        UDim2.new(1,0,1,0), nil, C.YELL, FB, 12, Enum.TextXAlignment.Center)
end

BEnvRun.MouseButton1Click:Connect(runCheck)
BEnvCopy.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(table.concat(reportLines, "\n"))
        ExecLbl.Text = "Report copied ✓"; ExecLbl.TextColor3 = C.GREEN
    end
end)

runCheck()
