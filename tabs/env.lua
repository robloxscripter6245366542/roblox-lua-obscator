-- TAB: Environment Diagnostics  (verifies executor capability checklist)
local SS = _G._SS
local C,tw,corner,stroke,pad,listH,listV=SS.C,SS.tw,SS.corner,SS.stroke,SS.pad,SS.listH,SS.listV
local F,L,B,IN,OUT,SCR,hov=SS.F,SS.L,SS.B,SS.IN,SS.OUT,SS.SCR,SS.hov

local P = SS.registerTab("🧪", "Environ")

L(P,"ENVIRONMENT DIAGNOSTICS",UDim2.new(1,0,0,16),nil,C.TXTS,SS.FB,11)

-- Header / executor identity
local HEAD = F(P,UDim2.new(1,0,0,40),UDim2.new(0,0,0,20),C.CONSOLE)
corner(HEAD,7); stroke(HEAD,C.BORDER,1)
local HeadLbl = L(HEAD,"  Detecting executor...",UDim2.new(1,-8,1,0),UDim2.new(0,6,0,0),
    C.YELLOW,SS.FC,12)

-- Re-run button
local BR = F(P,UDim2.new(1,0,0,26),UDim2.new(0,0,0,64),Color3.fromRGB(0,0,0))
BR.BackgroundTransparency=1; listH(BR,4)
local B_RUN  = B(BR,"Run Full Check",UDim2.new(0,140,1,0),nil,C.ACC)
local B_COPY = B(BR,"Copy Report",   UDim2.new(0,110,1,0),nil,C.GREY)
B_RUN.LayoutOrder=1; B_COPY.LayoutOrder=2
hov(B_RUN,C.ACC,C.ACCHV); hov(B_COPY,C.GREY,C.GREYHV)

-- Results scroll
local SCROLL = SCR(P,UDim2.new(1,0,1,-98),UDim2.new(0,0,0,96))
listV(SCROLL,3)

local lastReport = {}

local function clear()
    for _,ch in SCROLL:GetChildren() do
        if not ch:IsA("UIListLayout") then ch:Destroy() end
    end
    lastReport = {}
end

-- Add a category header row
local function catRow(title)
    local R=F(SCROLL,UDim2.new(1,-6,0,22),nil,C.PANEL); corner(R,5)
    L(R,"  "..title,UDim2.new(1,0,1,0),nil,C.PURPLE,SS.FB,12)
    lastReport[#lastReport+1] = "== "..title.." =="
end

-- Add a check row: name, ok?, detail
local function checkRow(name, ok, detail)
    local R=F(SCROLL,UDim2.new(1,-6,0,22),nil,Color3.fromRGB(0,0,0))
    R.BackgroundTransparency=1
    local dot=F(R,UDim2.new(0,6,0,6),UDim2.new(0,2,0,8),ok and C.GREEN or C.RED); corner(dot,3)
    L(R,name,UDim2.new(0.5,-14,1,0),UDim2.new(0,12,0,0),ok and C.TXT or C.TXTS,SS.FC,12)
    L(R,detail or (ok and "supported" or "missing"),
        UDim2.new(0.5,-8,1,0),UDim2.new(0.5,0,0,0),
        ok and C.GREEN or C.RED,SS.FN,11)
    lastReport[#lastReport+1] = (ok and "[OK] " or "[--] ")..name.." — "..(detail or "")
end

local function has(name) return rawget(getfenv(0) or _G, name) ~= nil or _G[name]~=nil or (getgenv and getgenv()[name]~=nil) end

local function runCheck()
    clear()

    -- Executor identity
    local exec = "Unknown"
    if identifyexecutor then
        local ok,n,v = pcall(identifyexecutor)
        if ok then exec = tostring(n)..(v and (" "..tostring(v)) or "") end
    elseif getexecutorname then
        local ok,n = pcall(getexecutorname); if ok then exec=tostring(n) end
    end
    HeadLbl.Text = "  Executor: "..exec
    HeadLbl.TextColor3 = C.GREEN
    lastReport[#lastReport+1] = "Executor: "..exec

    -- ── Execution engine ──────────────────────────────────
    catRow("Execution Engine")
    checkRow("loadstring", type(loadstring)=="function",
        type(loadstring)=="function" and "available" or "DISABLED — most scripts will fail")
    checkRow("pcall",      type(pcall)=="function")
    checkRow("LuaU dialect (continue)",
        (function() return (loadstring and select(1,loadstring("local function f() for i=1,1 do continue end end")) ~= nil) end)(),
        "Roblox LuaU syntax")
    checkRow("task scheduler", type(task)=="table" and type(task.wait)=="function")

    -- ── Environment functions ─────────────────────────────
    catRow("Environment Functions")
    checkRow("getgenv",     type(getgenv)=="function")
    checkRow("getrenv",     type(getrenv)=="function")
    checkRow("shared",      type(shared)=="table", type(shared)=="table" and "global table ok" or "missing")
    checkRow("game:GetService", (function() return pcall(function() return game:GetService("Players") end) end)())
    checkRow("getfenv/setfenv", type(getfenv)=="function" and type(setfenv)=="function")
    checkRow("_G global",   type(_G)=="table")

    -- ── File support ──────────────────────────────────────
    catRow("File System")
    checkRow("writefile",  type(writefile)=="function")
    checkRow("readfile",   type(readfile)=="function")
    checkRow("isfile",     type(isfile)=="function")
    checkRow("makefolder", type(makefolder)=="function")
    checkRow("listfiles",  type(listfiles)=="function")

    -- ── HTTP support ──────────────────────────────────────
    catRow("HTTP")
    checkRow("game:HttpGet", type(game.HttpGet)=="function")
    checkRow("request/http.request",
        type(request)=="function" or (http and type(http.request)=="function") or (syn and type(syn.request)=="function"))
    checkRow("HttpService:GetAsync",
        (function() return pcall(function() return game:GetService("HttpService") end) end)())

    -- ── Sandbox / injection primitives ────────────────────
    catRow("Sandbox / Injection")
    checkRow("getrawmetatable", type(getrawmetatable)=="function")
    checkRow("setreadonly",     type(setreadonly)=="function")
    checkRow("hookmetamethod",  type(hookmetamethod)=="function")
    checkRow("hookfunction",    type(hookfunction)=="function" or type(replaceclosure)=="function")
    checkRow("setthreadidentity", type(setthreadidentity)=="function")
    checkRow("gethui",          type(gethui)=="function", type(gethui)=="function" and "safe GUI parent" or "fallback to CoreGui")

    -- ── Remote handling ───────────────────────────────────
    catRow("Remote Events / Functions")
    checkRow("getnamecallmethod", type(getnamecallmethod)=="function")
    checkRow("firesignal",        type(firesignal)=="function")
    checkRow("getconnections",    type(getconnections)=="function")
    checkRow("SS bridge present",
        game:GetService("ReplicatedStorage"):FindFirstChild("SS_ExecBridge")~=nil,
        game:GetService("ReplicatedStorage"):FindFirstChild("SS_ExecBridge")~=nil
            and "server-side ready" or "inject SS_Executor.lua")

    -- ── Game load state ───────────────────────────────────
    catRow("Game State (why scripts fail)")
    checkRow("game:IsLoaded()", game:IsLoaded(), game:IsLoaded() and "fully loaded" or "still loading — run scripts later")
    checkRow("LocalPlayer ready", SS.LP~=nil)
    checkRow("Character spawned", SS.LP and SS.LP.Character~=nil,
        (SS.LP and SS.LP.Character) and "spawned" or "not spawned yet")

    -- Summary
    local okCount, total = 0, 0
    for _, line in lastReport do
        if line:sub(1,4)=="[OK]" then okCount+=1; total+=1
        elseif line:sub(1,4)=="[--]" then total+=1 end
    end
    local SR=F(SCROLL,UDim2.new(1,-6,0,26),nil,C.PANEL); corner(SR,5)
    L(SR,string.format("  %d / %d checks passed", okCount, total),
        UDim2.new(1,0,1,0),nil,C.YELLOW,SS.FB,12,Enum.TextXAlignment.Center)
end

B_RUN.MouseButton1Click:Connect(runCheck)
B_COPY.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(table.concat(lastReport,"\n"))
        HeadLbl.Text="  ✓ Report copied to clipboard."
        HeadLbl.TextColor3=C.GREEN
    end
end)

-- Auto-run on open
runCheck()
