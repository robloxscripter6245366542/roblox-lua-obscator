-- ═══════════════════════════════════════════════════════════════════════════════
--  TAB 10 — ENVIRONMENT DIAGNOSTICS
--  60+ checks · System info · Export · Copy report
-- ═══════════════════════════════════════════════════════════════════════════════
local P10 = newTab("🧪", "Environ")
L(P10, "ENVIRONMENT DIAGNOSTICS", UDim2.new(1,0,0,16), UDim2.new(0,0,0,0), C.TXTS, FB, 11)

local eRow = rowBar(P10, 18, 26)
local BEnvRun  = B(eRow, "Run Check",   UDim2.new(0,108,1,0), nil, C.ACC)
local BEnvCopy = B(eRow, "Copy Report", UDim2.new(0,102,1,0), nil, C.GREY)
local BEnvSave = B(eRow, "Save File",   UDim2.new(0,88,1,0),  nil, C.GREY)
styleRow({BEnvRun,BEnvCopy,BEnvSave})
hov(BEnvRun, C.ACC, C.ACCHV); hov(BEnvCopy, C.GREY, C.GRYHV); hov(BEnvSave, C.GREY, C.GRYHV)

local ExecLbl = L(P10, "Executor: …", UDim2.new(1,0,0,16), UDim2.new(0,0,0,48), C.TXTS, FC, 11)
local EnvScr  = SCR(P10, UDim2.new(1,0,1,-68), UDim2.new(0,0,0,66))
listV(EnvScr, 2)
local reportLines = {}

local function clrEnv()
    clearLayout(EnvScr)
    reportLines = {}
end

local function catHdr(title)
    local R = F(EnvScr, UDim2.new(1,-4,0,20), nil, C.PANEL); corner(R, 5)
    L(R, "  " .. title, UDim2.new(1,0,1,0), nil, C.PURP, FB, 11)
    reportLines[#reportLines+1] = "\n== " .. title .. " =="
end

local function chkRow(name, ok2, detail)
    local R = F(EnvScr, UDim2.new(1,-4,0,20), nil, C.BLK); R.BackgroundTransparency = 1
    local d = dot(R, UDim2.new(0,5,0,5), UDim2.new(0,2,0,7), ok2 and C.GRN or C.RED)
    L(R, name, UDim2.new(0.48,0,1,0), UDim2.new(0,10,0,0), ok2 and C.TXT or C.TXTS, FC, 11)
    local dstr = detail or (ok2 and "ok" or "missing")
    L(R, dstr, UDim2.new(0.52,-8,1,0), UDim2.new(0.48,0,0,0), ok2 and C.GRN or C.RED, FN, 11)
    reportLines[#reportLines+1] = (ok2 and "[✓] " or "[✗] ") .. name .. "  — " .. dstr
end

local function infoRow(label, value)
    local R = F(EnvScr, UDim2.new(1,-4,0,18), nil, C.BLK); R.BackgroundTransparency = 1
    L(R, "  " .. label, UDim2.new(0.48,0,1,0), nil, C.TXTS, FN, 10)
    L(R, tostring(value), UDim2.new(0.52,-8,1,0), UDim2.new(0.48,0,0,0), C.YELL, FC, 10)
    reportLines[#reportLines+1] = "    " .. label .. ": " .. tostring(value)
end

local function runCheck()
    clrEnv()
    local exec = detectExecutor()
    ExecLbl.Text = "Executor: " .. exec; ExecLbl.TextColor3 = C.GRN
    reportLines[#reportLines+1] = "Nexus Executor — Environment Report"
    reportLines[#reportLines+1] = "Generated: " .. os.date("%Y-%m-%d %H:%M:%S")
    reportLines[#reportLines+1] = "Executor: " .. exec

    catHdr("Execution Engine")
    chkRow("loadstring",     type(loadstring)=="function", "available")
    chkRow("load (fallback)",type(load)=="function")
    chkRow("pcall",          type(pcall)=="function")
    chkRow("xpcall",         type(xpcall)=="function")
    chkRow("task.wait",      type(task)=="table" and type(task.wait)=="function")
    chkRow("task.spawn",     type(task)=="table" and type(task.spawn)=="function")
    chkRow("task.delay",     type(task)=="table" and type(task.delay)=="function")
    chkRow("task.defer",     type(task)=="table" and type(task.defer)=="function")
    chkRow("LuaU continue", (function()
        local ld = loadstring or load
        return ld ~= nil and pcall(ld, "local function f() for i=1,1 do continue end end")
    end)(), "Roblox LuaU")
    chkRow("coroutine.wrap", type(coroutine)=="table" and type(coroutine.wrap)=="function")
    chkRow("os.clock",       type(os)=="table" and type(os.clock)=="function")
    chkRow("os.time",        type(os)=="table" and type(os.time)=="function")

    catHdr("Environment & Globals")
    chkRow("getgenv",        type(getgenv)=="function")
    chkRow("getrenv",        type(getrenv)=="function")
    chkRow("getfenv",        type(getfenv)=="function")
    chkRow("setfenv",        type(setfenv)=="function")
    chkRow("gethui",         type(gethui)=="function",
        type(gethui)=="function" and "available" or "PlayerGui fallback")
    chkRow("shared",         type(shared)=="table")
    chkRow("_G",             type(_G)=="table")
    chkRow("getglobals",     type(getglobals)=="function")
    chkRow("getscripts",     type(getscripts)=="function")
    chkRow("getrunningscripts", type(getrunningscripts)=="function")
    chkRow("getloadedmodules",  type(getloadedmodules)=="function")
    chkRow("identifyexecutor",  type(identifyexecutor)=="function")
    chkRow("isexecutorclosure", type(isexecutorclosure)=="function")

    catHdr("File System")
    chkRow("writefile",   type(writefile)=="function")
    chkRow("readfile",    type(readfile)=="function")
    chkRow("appendfile",  type(appendfile)=="function")
    chkRow("isfile",      type(isfile)=="function")
    chkRow("isfolder",    type(isfolder)=="function")
    chkRow("makefolder",  type(makefolder)=="function")
    chkRow("listfiles",   type(listfiles)=="function")
    chkRow("delfile",     type(delfile)=="function")
    chkRow("loadfile",    type(loadfile)=="function")

    catHdr("Network / HTTP")
    chkRow("game:HttpGet",   type(game.HttpGet)=="function")
    chkRow("httpget",        type(httpget)=="function")
    chkRow("request",        type(request)=="function"
        or (http and type(http.request)=="function")
        or (syn  and type(syn.request)=="function"))
    chkRow("syn.request",    syn ~= nil and type(syn.request)=="function")
    chkRow("http.request",   http ~= nil and type(http.request)=="function")
    chkRow("WebSocket",      type(WebSocket)=="table" and type(WebSocket.connect)=="function")
    chkRow("queue_on_teleport", type(queue_on_teleport)=="function")

    catHdr("Sandbox & Hooking")
    chkRow("getrawmetatable",    type(getrawmetatable)=="function")
    chkRow("setrawmetatable",    type(setrawmetatable)=="function")
    chkRow("setreadonly",        type(setreadonly)=="function")
    chkRow("hookmetamethod",     type(hookmetamethod)=="function")
    chkRow("hookfunction",       type(hookfunction)=="function" or type(replaceclosure)=="function")
    chkRow("replaceclosure",     type(replaceclosure)=="function")
    chkRow("newcclosure",        type(newcclosure)=="function")
    chkRow("iscclosure",         type(iscclosure)=="function")
    chkRow("islclosure",         type(islclosure)=="function")
    chkRow("setthreadidentity",  type(setthreadidentity)=="function")
    chkRow("getthreadidentity",  type(getthreadidentity)=="function")
    chkRow("getnamecallmethod",  type(getnamecallmethod)=="function")
    chkRow("getconnections",     type(getconnections)=="function")

    catHdr("Debug Library")
    local dbg = type(debug)=="table"
    chkRow("debug.getinfo",    dbg and type(debug.getinfo)=="function")
    chkRow("debug.getupvalue", dbg and type(debug.getupvalue)=="function")
    chkRow("debug.setupvalue", dbg and type(debug.setupvalue)=="function")
    chkRow("debug.getconstant",dbg and type(debug.getconstant)=="function")
    chkRow("debug.setconstant",dbg and type(debug.setconstant)=="function")
    chkRow("debug.getproto",   dbg and type(debug.getproto)=="function")
    chkRow("debug.getprotos",  dbg and type(debug.getprotos)=="function")
    chkRow("debug.getstack",   dbg and type(debug.getstack)=="function")
    chkRow("debug.traceback",  dbg and type(debug.traceback)=="function")

    catHdr("Input / Drawing")
    chkRow("keypress",          type(keypress)=="function")
    chkRow("keyrelease",        type(keyrelease)=="function")
    chkRow("mouse1click",       type(mouse1click)=="function")
    chkRow("mouse2click",       type(mouse2click)=="function")
    chkRow("mousemoveabs",      type(mousemoveabs)=="function")
    chkRow("mousemoverel",      type(mousemoverel)=="function")
    chkRow("isrbxactive",       type(isrbxactive)=="function")
    chkRow("Drawing.new",       type(Drawing)=="table" and type(Drawing.new)=="function")
    chkRow("getrenderproperty", type(getrenderproperty)=="function")
    chkRow("setfpscap",         type(setfpscap)=="function")
    chkRow("getfpscap",         type(getfpscap)=="function")

    catHdr("Console / Output")
    chkRow("rconsoleopen",   type(rconsoleopen)=="function")
    chkRow("rconsoleclose",  type(rconsoleclose)=="function")
    chkRow("rconsoleprint",  type(rconsoleprint)=="function")
    chkRow("rconsolewarn",   type(rconsolewarn)=="function")
    chkRow("rconsoleclear",  type(rconsoleclear)=="function")
    chkRow("rconsoleinput",  type(rconsoleinput)=="function")

    catHdr("Crypt / Crypto")
    chkRow("crypt.base64encode", type(crypt)=="table" and type(crypt.base64encode)=="function")
    chkRow("crypt.base64decode", type(crypt)=="table" and type(crypt.base64decode)=="function")
    chkRow("crypt.encrypt",      type(crypt)=="table" and type(crypt.encrypt)=="function")
    chkRow("crypt.hash",         type(crypt)=="table" and type(crypt.hash)=="function")

    catHdr("Game State")
    chkRow("game:IsLoaded()",  game:IsLoaded(), game:IsLoaded() and "fully loaded" or "loading")
    chkRow("LocalPlayer",      LP ~= nil, LP and "@" .. LP.Name or "missing")
    chkRow("Character",        LP and LP.Character ~= nil,
        (LP and LP.Character) and "spawned" or "not spawned")
    chkRow("SS_ExecBridge",    Bridge ~= nil,
        Bridge and "bridge ready" or "inject SS_Executor.lua server-side")

    catHdr("System / Session Info")
    infoRow("Platform",         SESSION.platform)
    infoRow("Game ID",          SESSION.gameId)
    infoRow("Place ID",         SESSION.placeId)
    infoRow("Player",           SESSION.playerName .. " (" .. SESSION.displayName .. ")")
    infoRow("Players online",   #Players:GetPlayers())
    local ident = 0
    pcall(function() ident = getthreadidentity and getthreadidentity() or 0 end)
    infoRow("Thread Identity",  ident)
    infoRow("Touch enabled",    UIS.TouchEnabled)
    infoRow("Game loaded",      game:IsLoaded())

    -- Summary
    local pass2, total2 = 0, 0
    for _, ln in reportLines do
        if ln:sub(1,4) == "[✓]" then pass2+=1; total2+=1
        elseif ln:sub(1,4) == "[✗]" then total2+=1 end
    end
    local SR = F(EnvScr, UDim2.new(1,-4,0,26), nil, C.PANEL); corner(SR, 5)
    L(SR, ("  %d / %d checks passed  (%.0f%%)"):format(
        pass2, total2, total2>0 and pass2/total2*100 or 0),
        UDim2.new(1,0,1,0), nil, C.YELL, FB, 12, Enum.TextXAlignment.Center)
end

BEnvRun.MouseButton1Click:Connect(runCheck)

BEnvCopy.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(table.concat(reportLines, "\n"))
        ExecLbl.Text = "Report copied ✓"; ExecLbl.TextColor3 = C.GRN
    else
        ExecLbl.Text = "setclipboard not available"
    end
end)

BEnvSave.MouseButton1Click:Connect(function()
    if not writefile then ExecLbl.Text = "writefile not available"; return end
    local fname = "nexus_environ_" .. os.time() .. ".txt"
    writefile(fname, table.concat(reportLines, "\n"))
    ExecLbl.Text = "Saved → " .. fname; ExecLbl.TextColor3 = C.GRN
end)
