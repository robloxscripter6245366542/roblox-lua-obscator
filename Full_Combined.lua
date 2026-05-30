-- ============================================================
--  FULL SS EXECUTOR  –  Single Loadstring Script
--  Paste into any Roblox executor (PC or Mobile / iOS / Android)
--  Server features require SS_Executor.lua injected server-side.
-- ============================================================

local ok, err = pcall(function()

-- ── Services ──────────────────────────────────────────────
local Players     = game:GetService("Players")
local RepStore    = game:GetService("ReplicatedStorage")
local UIS         = game:GetService("UserInputService")
local TweenSvc    = game:GetService("TweenService")

-- ── Player / GUI root ─────────────────────────────────────
local LP = Players.LocalPlayer
if not LP then
    -- fallback: wait up to 5 s
    local t = 0
    repeat task.wait(0.1) t = t + 0.1 LP = Players.LocalPlayer until LP or t >= 5
end
if not LP then warn("[SS] No LocalPlayer found.") return end

-- Prefer CoreGui/gethui so the GUI survives game resets
local function getGuiParent()
    if gethui then return gethui() end
    local ok2, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok2 and cg then return cg end
    return LP:WaitForChild("PlayerGui")
end
local GuiRoot = getGuiParent()

-- Remove stale GUI
local old = GuiRoot:FindFirstChild("SS_ExecGUI")
if old then old:Destroy() end

-- Optional server bridge (nil if SS_Executor.lua not running)
local Bridge = RepStore:FindFirstChild("SS_ExecBridge")

-- ── Theme ─────────────────────────────────────────────────
local C = {
    BG      = Color3.fromRGB(8,   8,  11),
    PANEL   = Color3.fromRGB(16,  16, 21),
    PANEL2  = Color3.fromRGB(20,  20, 27),
    INPUT   = Color3.fromRGB(11,  11, 15),
    ACCENT  = Color3.fromRGB(105, 15, 225),
    ACCHOV  = Color3.fromRGB(125, 38, 248),
    BLUE    = Color3.fromRGB(25,  120, 220),
    BLUEHOV = Color3.fromRGB(40,  145, 245),
    DIM     = Color3.fromRGB(28,  28,  38),
    DIMTXT  = Color3.fromRGB(125, 125, 160),
    WHITE   = Color3.new(1, 1, 1),
    GREEN   = Color3.fromRGB(60,  210,  75),
    RED     = Color3.fromRGB(238,  60,  60),
    YELLOW  = Color3.fromRGB(255, 198,  42),
    PURPLE  = Color3.fromRGB(185, 140, 255),
    STROKE  = Color3.fromRGB(70,    8, 170),
    ORANGE  = Color3.fromRGB(240, 130,  30),
}
local TIF  = TweenInfo.new(0.14)
local TIS  = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local GBOL = Enum.Font.GothamBold
local GNRM = Enum.Font.Gotham
local GCOD = Enum.Font.Code

-- ── Helpers ───────────────────────────────────────────────
local function tw(o, p)  TweenSvc:Create(o, TIF, p):Play() end
local function tws(o, p) TweenSvc:Create(o, TIS, p):Play() end

local function rnd(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 7)
    c.Parent = p
end

local function str(p, col, th)
    local s = Instance.new("UIStroke")
    s.Color     = col or C.STROKE
    s.Thickness = th or 1.2
    s.Parent    = p
end

local function lbl(parent, props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    for k, v in props do pcall(function() l[k] = v end) end
    l.Parent = parent
    return l
end

local function btn(parent, props)
    local b = Instance.new("TextButton")
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    for k, v in props do pcall(function() b[k] = v end) end
    b.Parent = parent
    return b
end

local function makeScrollFrame(parent, pos, size)
    local sf = Instance.new("ScrollingFrame")
    sf.Position              = pos
    sf.Size                  = size
    sf.BackgroundColor3      = C.INPUT
    sf.BorderSizePixel       = 0
    sf.ScrollBarThickness    = 4
    sf.ScrollBarImageColor3  = C.ACCENT
    sf.CanvasSize            = UDim2.new(0, 0, 0, 0)
    sf.AutomaticCanvasSize   = Enum.AutomaticSize.Y
    sf.Parent                = parent
    rnd(sf, 7)
    str(sf, Color3.fromRGB(48, 4, 115), 1)
    return sf
end

local function makeCodeBox(parent, placeholder)
    local tb = Instance.new("TextBox")
    tb.Size               = UDim2.new(1, -10, 1, 0)
    tb.Position           = UDim2.new(0, 5, 0, 5)
    tb.BackgroundTransparency = 1
    tb.Text               = ""
    tb.PlaceholderText    = placeholder or ""
    tb.PlaceholderColor3  = Color3.fromRGB(55, 55, 78)
    tb.TextColor3         = Color3.fromRGB(215, 215, 255)
    tb.TextSize           = 12
    tb.Font               = GCOD
    tb.MultiLine          = true
    tb.TextXAlignment     = Enum.TextXAlignment.Left
    tb.TextYAlignment     = Enum.TextYAlignment.Top
    tb.ClearTextOnFocus   = false
    tb.Parent             = parent
    return tb
end

local function hookHover(b, norm, hov)
    b.MouseEnter:Connect(function() tw(b, {BackgroundColor3 = hov})  end)
    b.MouseLeave:Connect(function() tw(b, {BackgroundColor3 = norm}) end)
end

local function callBridge(action, payload)
    if not Bridge then return {ok=false, msg="Bridge not found. Inject SS_Executor.lua server-side."} end
    local ok2, res = pcall(Bridge.InvokeServer, Bridge, action, payload or {})
    if not ok2 then return {ok=false, msg=tostring(res)} end
    return res or {ok=false, msg="nil response"}
end

-- ── Base64 decode ─────────────────────────────────────────
local B64CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function b64decode(data)
    data = data:gsub("[^" .. B64CHARS .. "=]", "")
    return (data:gsub(".", function(x)
        if x == "=" then return "" end
        local r, f = "", B64CHARS:find(x) - 1
        for i = 6, 1, -1 do
            r = r .. (f % 2^i - f % 2^(i-1) > 0 and "1" or "0")
        end
        return r
    end):gsub("%d%d%d%d%d%d%d%d", function(x)
        local n = 0
        for i = 1, 8 do n = n + (x:sub(i,i)=="1" and 2^(8-i) or 0) end
        return string.char(n)
    end))
end

-- ── Deobfuscator ──────────────────────────────────────────
local function detectObfType(s)
    if s:find("Luraph") or s:find("lura%.ph") then return "Luraph"
    elseif s:find("IronBrew") or s:find("Iron%s*Brew") then return "IronBrew 2"
    elseif s:find("Prometheus") then return "Prometheus"
    elseif s:find("Moonsec")   then return "Moonsec"
    elseif s:find("_0x%x+") and #s > 500 then return "Hex-var obfuscated"
    elseif s:find("string%.byte") and s:find("string%.char") and #s > 2000 then return "String-table VM"
    elseif s:find("local%s+[A-Z][A-Z0-9]*%s*=%s*{") and #s > 3000 then return "Custom VM/bytecode"
    end
    return "Unknown / Custom"
end

local function deobfuscate(src)
    local out = src
    local log = {}
    local n

    out, n = out:gsub("\\x(%x%x)", function(h)
        return string.char(tonumber(h, 16))
    end)
    if n > 0 then table.insert(log, "Decoded "..n.." hex esc") end

    out, n = out:gsub("\\(%d%d?%d?)", function(d)
        local v = tonumber(d)
        if v and v >= 32 and v <= 126 then return string.char(v) end
        return "\\" .. d
    end)
    if n > 0 then table.insert(log, "Decoded "..n.." dec esc") end

    out = out:gsub("string%.char%(([%d,%s]+)%)", function(args)
        local chars = {}
        for num in args:gmatch("%d+") do
            local v = tonumber(num)
            if not v or v < 32 or v > 126 then return "string.char("..args..")" end
            table.insert(chars, string.char(v))
        end
        table.insert(log, "Folded string.char")
        return '"' .. table.concat(chars):gsub('"', '\\"') .. '"'
    end)

    local changed, folds = true, 0
    while changed do
        changed = false
        out = out:gsub('"([^"\\]*)"%s*%.%.%s*"([^"\\]*)"', function(a, b)
            changed = true ; folds = folds + 1
            return '"' .. a .. b .. '"'
        end)
    end
    if folds > 0 then table.insert(log, "Folded "..folds.." concat(s)") end

    out = out:gsub("\n\n\n+", "\n\n")
    return out, #log > 0 and table.concat(log, "  |  ") or "Nothing simplified."
end

-- ── UNC / SUNC / Myriad lists ─────────────────────────────
local UNC_LIST = {
    {"checkcaller","Closure"},    {"clonefunction","Closure"},
    {"getcallingscript","Closure"},{"hookfunction","Closure"},
    {"iscclosure","Closure"},     {"islclosure","Closure"},
    {"newcclosure","Closure"},    {"replaceclosure","Closure"},
    {"crypt.base64decode","Crypt"},{"crypt.base64encode","Crypt"},
    {"crypt.decrypt","Crypt"},    {"crypt.encrypt","Crypt"},
    {"crypt.generatebytes","Crypt"},{"crypt.generatekey","Crypt"},
    {"crypt.hash","Crypt"},
    {"debug.getconstant","Debug"},{"debug.getconstants","Debug"},
    {"debug.getinfo","Debug"},    {"debug.getproto","Debug"},
    {"debug.getprotos","Debug"},  {"debug.getstack","Debug"},
    {"debug.getupvalue","Debug"}, {"debug.getupvalues","Debug"},
    {"debug.setconstant","Debug"},{"debug.setupvalue","Debug"},
    {"Drawing","Drawing"},        {"cleardrawcache","Drawing"},
    {"isrenderobj","Drawing"},    {"getrenderproperty","Drawing"},
    {"setrenderproperty","Drawing"},
    {"appendfile","FileSystem"},  {"delfile","FileSystem"},
    {"delfolder","FileSystem"},   {"isfile","FileSystem"},
    {"isfolder","FileSystem"},    {"listfiles","FileSystem"},
    {"loadfile","FileSystem"},    {"makefolder","FileSystem"},
    {"readfile","FileSystem"},    {"writefile","FileSystem"},
    {"isrbxactive","Input"},      {"keypress","Input"},
    {"keyrelease","Input"},       {"mouse1click","Input"},
    {"mouse1press","Input"},      {"mouse1release","Input"},
    {"mouse2click","Input"},      {"mouse2press","Input"},
    {"mouse2release","Input"},    {"mousemoveabs","Input"},
    {"mousemoverel","Input"},     {"mousescroll","Input"},
    {"fireclickdetector","Instance"},{"fireproximityprompt","Instance"},
    {"firetouchinterest","Instance"},{"getcustomasset","Instance"},
    {"gethiddenproperty","Instance"},{"gethui","Instance"},
    {"getinstances","Instance"},  {"getnilinstances","Instance"},
    {"isscriptable","Instance"},  {"sethiddenproperty","Instance"},
    {"setscriptable","Instance"},
    {"getrawmetatable","Metatable"},{"hookmetamethod","Metatable"},
    {"setrawmetatable","Metatable"},{"setreadonly","Metatable"},
    {"isreadonly","Metatable"},
    {"getexecutorname","Misc"},   {"identifyexecutor","Misc"},
    {"gethwid","Misc"},           {"isluau","Misc"},
    {"lz4compress","Misc"},       {"lz4decompress","Misc"},
    {"messagebox","Misc"},        {"queue_on_teleport","Misc"},
    {"setfpscap","Misc"},         {"getfpscap","Misc"},
    {"setclipboard","Misc"},      {"getclipboard","Misc"},
    {"saveinstance","Misc"},
    {"getgc","Scripts"},          {"getgenv","Scripts"},
    {"getloadedmodules","Scripts"},{"getrunningscripts","Scripts"},
    {"getscripts","Scripts"},     {"getrenv","Scripts"},
    {"getsenv","Scripts"},
    {"getconnections","Signal"},  {"firesignal","Signal"},
    {"getthreadidentity","Thread"},{"setthreadidentity","Thread"},
    {"getidentity","Thread"},     {"setidentity","Thread"},
    {"request","HTTP"},           {"http_request","HTTP"},
    {"cache.invalidate","Cache"}, {"cache.iscached","Cache"},
    {"cache.replace","Cache"},    {"WebSocket","WebSocket"},
    {"rconsoleclose","Console"},  {"rconsolecreate","Console"},
    {"rconsoleinfo","Console"},   {"rconsoleprint","Console"},
    {"rconsoleprintdefault","Console"},{"rconsolename","Console"},
    {"rconsolewarn","Console"},
}

local SUNC_LIST = {
    {"getscriptclosure","ScriptEnv"},  {"getscriptfunction","ScriptEnv"},
    {"getscriptenv","ScriptEnv"},      {"getscriptbytecode","ScriptEnv"},
    {"getscripthash","ScriptEnv"},     {"getscriptname","ScriptEnv"},
    {"getscriptpath","ScriptEnv"},     {"getscriptid","ScriptEnv"},
    {"getscriptguid","ScriptEnv"},     {"decompile","ScriptEnv"},
    {"isscriptrunning","ScriptState"}, {"isscriptpaused","ScriptState"},
    {"isscriptenabled","ScriptState"}, {"enablescript","ScriptState"},
    {"disablescript","ScriptState"},   {"pausescript","ScriptState"},
    {"resumescript","ScriptState"},    {"stopscript","ScriptState"},
    {"restartscript","ScriptState"},   {"killscript","ScriptState"},
    {"forkscript","ScriptLife"},       {"startscript","ScriptLife"},
    {"reloadscript","ScriptLife"},     {"getscriptstate","ScriptLife"},
    {"setscriptstate","ScriptLife"},   {"getscriptmemoryusage","ScriptLife"},
    {"getscriptcpuusage","ScriptLife"},{"getscriptuptime","ScriptLife"},
    {"getscriptthread","ScriptLife"},  {"getscriptactor","ScriptLife"},
    {"getscriptglobals","ScriptVar"},  {"getscriptlocals","ScriptVar"},
    {"getscriptupvalues","ScriptVar"}, {"getscriptconstants","ScriptVar"},
    {"getscriptprotos","ScriptVar"},   {"setscriptglobal","ScriptVar"},
    {"setscriptlocal","ScriptVar"},    {"setscriptupvalue","ScriptVar"},
    {"setscriptconstant","ScriptVar"}, {"setscriptenv","ScriptVar"},
    {"findscriptbyname","ScriptFind"}, {"findscriptbypath","ScriptFind"},
    {"findscriptbyid","ScriptFind"},   {"findscriptbytarget","ScriptFind"},
    {"findscriptbyclosure","ScriptFind"},{"getscriptcallers","ScriptFind"},
    {"getscriptcallstack","ScriptFind"},{"getallscripts","ScriptFind"},
    {"getmodulescripts","ScriptFind"}, {"getlocalscripts","ScriptFind"},
    {"getscriptparent","ScriptHier"},  {"setscriptparent","ScriptHier"},
    {"getscriptchildren","ScriptHier"},{"getscriptdescendants","ScriptHier"},
    {"getscriptcategory","ScriptHier"},{"setscriptcategory","ScriptHier"},
    {"getscriptlevel","ScriptHier"},   {"setscriptlevel","ScriptHier"},
    {"getscriptobject","ScriptHier"},  {"setscriptobject","ScriptHier"},
    {"getscriptidentity","ScriptID"},  {"setscriptidentity","ScriptID"},
    {"getscriptpermissions","ScriptID"},{"setscriptpermissions","ScriptID"},
    {"getscriptflags","ScriptID"},     {"setscriptflags","ScriptID"},
    {"isscriptprotected","ScriptID"},  {"protectscript","ScriptID"},
    {"unprotectscript","ScriptID"},    {"isscriptobfuscated","ScriptID"},
    {"clonescript","ScriptMod"},       {"patchscript","ScriptMod"},
    {"injectscript","ScriptMod"},      {"hookscript","ScriptMod"},
    {"unhookscript","ScriptMod"},      {"wrapscript","ScriptMod"},
    {"unwrapscript","ScriptMod"},      {"validatescript","ScriptMod"},
    {"compressscript","ScriptMod"},    {"decompressscript","ScriptMod"},
    {"encryptscript","ScriptCrypt"},   {"decryptscript","ScriptCrypt"},
    {"obfuscatescript","ScriptCrypt"}, {"deobfuscatescript","ScriptCrypt"},
    {"getsignature","ScriptCrypt"},    {"setsignature","ScriptCrypt"},
    {"getscriptbytecodemodified","ScriptCrypt"},
    {"redecompile","ScriptCrypt"},     {"signalscript","ScriptCrypt"},
    {"waitforscript","ScriptCrypt"},
    {"getenvtype","ScriptSandbox"},    {"setenvtype","ScriptSandbox"},
    {"getsafeenv","ScriptSandbox"},    {"setsafeenv","ScriptSandbox"},
    {"getprotectedenv","ScriptSandbox"},{"setprotectedenv","ScriptSandbox"},
    {"isolateenv","ScriptSandbox"},    {"mergeenv","ScriptSandbox"},
    {"cloneenv","ScriptSandbox"},      {"cleanenv","ScriptSandbox"},
}

local MYRIAD_LIST = {
    {"Drawing.new","MyrDraw"},{"Drawing.clear","MyrDraw"},{"Drawing.Font","MyrDraw"},
    {"getdrawobjects","MyrDraw"},{"getdrawcount","MyrDraw"},{"renderdraw","MyrDraw"},
    {"updatedraw","MyrDraw"},{"deletedraw","MyrDraw"},{"clonedraw","MyrDraw"},{"movedraw","MyrDraw"},
    {"rotatedraw","MyrDraw"},{"scaledraw","MyrDraw"},{"setdrawzindex","MyrDraw"},{"getdrawzindex","MyrDraw"},
    {"setdrawvisibility","MyrDraw"},{"getdrawvisibility","MyrDraw"},{"setdrawcolor","MyrDraw"},
    {"setdrawthickness","MyrDraw"},{"setdrawtransparency","MyrDraw"},{"setdrawfilled","MyrDraw"},
    {"readprocessmemory","MyrMem"},{"writeprocessmemory","MyrMem"},{"getmodulebase","MyrMem"},
    {"getmodulesize","MyrMem"},{"getprocessid","MyrMem"},{"allocatemem","MyrMem"},
    {"freemem","MyrMem"},{"protectmem","MyrMem"},{"unprotectmem","MyrMem"},{"scanmemory","MyrMem"},
    {"getmemorymap","MyrMem"},{"getmemoryusage","MyrMem"},{"setmemorycap","MyrMem"},
    {"flushmemorycache","MyrMem"},{"getmemoryregions","MyrMem"},
    {"dumprequest","MyrNet"},{"firelog","MyrNet"},{"blockrequest","MyrNet"},{"filterrequest","MyrNet"},
    {"capturerequest","MyrNet"},{"getwebrequests","MyrNet"},{"clearwebrequests","MyrNet"},
    {"logrequest","MyrNet"},{"filterresponse","MyrNet"},{"modifyrequest","MyrNet"},
    {"modifyresponse","MyrNet"},{"interceptrequest","MyrNet"},{"forwardrequest","MyrNet"},
    {"rejectrequest","MyrNet"},{"getnetworkid","MyrNet"},{"setnetworkid","MyrNet"},
    {"gettransferrate","MyrNet"},{"settransferrate","MyrNet"},{"getlatency","MyrNet"},
    {"simulatelagspike","MyrNet"},
    {"spoofscriptname","MyrAnti"},{"spoofscriptpath","MyrAnti"},{"spoofscriptid","MyrAnti"},
    {"spoofidentity","MyrAnti"},{"spoofthreadid","MyrAnti"},{"protectgui","MyrAnti"},
    {"disguisescript","MyrAnti"},{"disguiseexecutor","MyrAnti"},{"getdetectionflags","MyrAnti"},
    {"cleardetectionflags","MyrAnti"},{"bypassanticheat","MyrAnti"},{"simulatelegitplayer","MyrAnti"},
    {"fakescriptactivity","MyrAnti"},{"getanticheatlevel","MyrAnti"},{"setanticheatlevel","MyrAnti"},
    {"disablevanguard","MyrAnti"},{"disablebyfron","MyrAnti"},{"disablehyperion","MyrAnti"},
    {"whitelistprocess","MyrAnti"},{"setexecutorname","MyrAnti"},
    {"initremotespy","MyrSpy"},{"getrecentremotes","MyrSpy"},{"filterremote","MyrSpy"},
    {"blockremotespy","MyrSpy"},{"hookremote","MyrSpy"},{"unhookremote","MyrSpy"},
    {"logremotetraffic","MyrSpy"},{"getremotehistory","MyrSpy"},{"clearremotehistory","MyrSpy"},
    {"getremotecallstack","MyrSpy"},{"hookallremotes","MyrSpy"},{"unhookallremotes","MyrSpy"},
    {"whitelistremote","MyrSpy"},{"blacklistremote","MyrSpy"},{"remotespy_setfilter","MyrSpy"},
    {"remotespy_getfilter","MyrSpy"},{"remotespy_export","MyrSpy"},{"remotespy_import","MyrSpy"},
    {"getremotecount","MyrSpy"},{"getremoterate","MyrSpy"},
    {"compile","MyrByte"},{"getbytecode","MyrByte"},{"loadbytecode","MyrByte"},
    {"executebytecode","MyrByte"},{"verifybytecode","MyrByte"},{"getbytecodeversion","MyrByte"},
    {"setbytecodeversion","MyrByte"},{"patchbytecode","MyrByte"},{"hotpatch","MyrByte"},
    {"getbytecodeinfo","MyrByte"},{"setbytecodeinfo","MyrByte"},{"disassemble","MyrByte"},
    {"reassemble","MyrByte"},{"optimize","MyrByte"},{"minify","MyrByte"},
    {"prettify","MyrByte"},{"tokenize","MyrByte"},{"parse","MyrByte"},
    {"serialize","MyrByte"},{"deserialize","MyrByte"},
    {"simulateguiclick","MyrUI"},{"simulateguiinput","MyrUI"},{"simulateguitouch","MyrUI"},
    {"simulateguiscroll","MyrUI"},{"getguiinsets","MyrUI"},{"setguiinsets","MyrUI"},
    {"capturescreen","MyrUI"},{"recordgameplay","MyrUI"},{"stoprecording","MyrUI"},
    {"getviewportsize","MyrUI"},{"setfov","MyrUI"},{"getfov","MyrUI"},
    {"setrenderquality","MyrUI"},{"getrenderquality","MyrUI"},{"resetrendersettings","MyrUI"},
    {"setphysicsrate","MyrPhys"},{"getphysicsrate","MyrPhys"},{"pausephysics","MyrPhys"},
    {"resumephysics","MyrPhys"},{"setgravity","MyrPhys"},{"getgravity","MyrPhys"},
    {"setnetworkphysics","MyrPhys"},{"getnetworkphysics","MyrPhys"},
    {"setphysicsinterpolation","MyrPhys"},{"getphysicsinterpolation","MyrPhys"},
    {"getphysicsjoint","MyrPhys"},{"setphysicsjoint","MyrPhys"},{"getrigid","MyrPhys"},
    {"setrigid","MyrPhys"},{"applyphysicsimpulse","MyrPhys"},
    {"forcereplicate","MyrRep"},{"blockreplication","MyrRep"},{"setreplicationrate","MyrRep"},
    {"getreplicationqueue","MyrRep"},{"clearreplicationqueue","MyrRep"},{"getnetworkowner","MyrRep"},
    {"setnetworkowner","MyrRep"},{"getnetworkstats","MyrRep"},{"syncnetwork","MyrRep"},
    {"getpacketrate","MyrRep"},{"setpacketrate","MyrRep"},{"getpacketsize","MyrRep"},
    {"compress_packet","MyrRep"},{"encrypt_packet","MyrRep"},{"decrypt_packet","MyrRep"},
    {"getworkspacegravity","MyrGame"},{"setworkspacegravity","MyrGame"},
    {"setphysicssetting","MyrGame"},{"getphysicssetting","MyrGame"},{"getterraindata","MyrGame"},
    {"setterraindata","MyrGame"},{"modifyterrain","MyrGame"},{"getdatamodel","MyrGame"},
    {"setdatamodel","MyrGame"},{"getserverlocation","MyrGame"},{"getserverinfo","MyrGame"},
    {"getclientinfo","MyrGame"},{"getgameversion","MyrGame"},{"getgameid","MyrGame"},
    {"getplaceversion","MyrGame"},{"getassetrootid","MyrGame"},{"getassetversion","MyrGame"},
    {"checkasset","MyrGame"},{"cacheasset","MyrGame"},{"uncacheasset","MyrGame"},
    {"debug.readmemory","MyrDbg"},{"debug.writememory","MyrDbg"},{"debug.getregisters","MyrDbg"},
    {"debug.setregisters","MyrDbg"},{"debug.getflags","MyrDbg"},{"debug.setflags","MyrDbg"},
    {"debug.getmodules","MyrDbg"},{"debug.getthreads","MyrDbg"},{"debug.suspendthread","MyrDbg"},
    {"debug.resumethread","MyrDbg"},{"debug.getthreadinfo","MyrDbg"},{"debug.getip","MyrDbg"},
    {"debug.setip","MyrDbg"},{"debug.getsp","MyrDbg"},{"debug.setsp","MyrDbg"},
    {"createevent","MyrEvt"},{"destroyevent","MyrEvt"},{"fireevent","MyrEvt"},
    {"hookevent","MyrEvt"},{"unhookevent","MyrEvt"},{"defevent","MyrEvt"},
    {"filterevent","MyrEvt"},{"prioritizeevent","MyrEvt"},{"getevents","MyrEvt"},
    {"clearevents","MyrEvt"},{"getconnectioncount","MyrEvt"},{"disconnectall","MyrEvt"},
    {"reconnectall","MyrEvt"},{"getfirecount","MyrEvt"},{"resetfirecount","MyrEvt"},
    {"getexecutorversion","MyrExec"},{"getexecutorbuild","MyrExec"},{"getexecutorlicense","MyrExec"},
    {"isfeatureenabled","MyrExec"},{"enablefeature","MyrExec"},{"disablefeature","MyrExec"},
    {"getfeaturelist","MyrExec"},{"setperformancemode","MyrExec"},{"getperformancemode","MyrExec"},
    {"setthreadpriority","MyrExec"},{"getthreadpriority","MyrExec"},{"gettaskscheduler","MyrExec"},
    {"setfpstarget","MyrExec"},{"getfpstarget","MyrExec"},{"getframetime","MyrExec"},
    {"getuptime","MyrExec"},{"getmemorytotal","MyrExec"},{"getmemoryavailable","MyrExec"},
    {"getexecutorflags","MyrExec"},{"setexecutorflags","MyrExec"},
    {"getlicensekey","MyrLic"},{"setlicensekey","MyrLic"},{"validatelicensekey","MyrLic"},
    {"getlicensestatus","MyrLic"},{"getlicenseholder","MyrLic"},
    {"getinstancecreationcallbacks","MyrInst"},{"setinstancecreationcallback","MyrInst"},
    {"interceptinstancecreation","MyrInst"},{"interceptpropertyset","MyrInst"},
    {"getpropertychangedcallbacks","MyrInst"},{"setpropertychangedcallback","MyrInst"},
    {"compareinstances","MyrInst"},{"getspecialinfo","MyrInst"},{"setspecialinfo","MyrInst"},
    {"getfullpath","MyrInst"},{"clonetree","MyrInst"},{"mergetrees","MyrInst"},
    {"diffinstances","MyrInst"},{"syncinstances","MyrInst"},{"snapshotinstance","MyrInst"},
}

local function hasUNC(name)
    if name:find("%.") then
        local tbl, key = name:match("^(.-)%.(.+)$")
        local t = rawget(_G, tbl)
        if t == nil then
            local ok2, v = pcall(function() return _G[tbl] end)
            t = ok2 and v or nil
        end
        if type(t) == "table" then return rawget(t, key) ~= nil end
        return false
    end
    if rawget(_G, name) ~= nil then return true end
    local ok2, v = pcall(function()
        local env = (getfenv and getfenv()) or _G
        return rawget(env, name)
    end)
    return ok2 and v ~= nil
end

-- ── Root ScreenGui ────────────────────────────────────────
local SG = Instance.new("ScreenGui")
SG.Name           = "SS_ExecGUI"
SG.ResetOnSpawn   = false
SG.DisplayOrder   = 999
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.IgnoreGuiInset = true
SG.Parent         = GuiRoot

local WIN_W, WIN_H = 520, 420

local Win = Instance.new("Frame")
Win.Name             = "Win"
Win.Size             = UDim2.new(0, WIN_W, 0, WIN_H)
Win.Position         = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2)
Win.BackgroundColor3 = C.BG
Win.BorderSizePixel  = 0
Win.ClipsDescendants = true
Win.Parent           = SG
rnd(Win, 10)
str(Win, C.STROKE, 1.5)

-- ── Title bar ─────────────────────────────────────────────
local TBar = Instance.new("Frame")
TBar.Name             = "TBar"
TBar.Size             = UDim2.new(1, 0, 0, 40)
TBar.BackgroundColor3 = C.PANEL
TBar.BorderSizePixel  = 0
TBar.ZIndex           = 4
TBar.Parent           = Win
rnd(TBar, 10)

local TBarPatch = Instance.new("Frame")
TBarPatch.Size             = UDim2.new(1, 0, 0.5, 0)
TBarPatch.Position         = UDim2.new(0, 0, 0.5, 0)
TBarPatch.BackgroundColor3 = C.PANEL
TBarPatch.BorderSizePixel  = 0
TBarPatch.ZIndex           = 4
TBarPatch.Parent           = TBar

lbl(TBar, {
    Size = UDim2.new(1, -110, 1, 0),
    Position = UDim2.new(0, 12, 0, 0),
    Text = "  Full SS Executor",
    TextColor3 = C.PURPLE,
    TextSize = 14,
    Font = GBOL,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 5,
})

local DotLbl = lbl(Win, {
    Size = UDim2.new(0, 200, 0, 14),
    Position = UDim2.new(0, 12, 0, 26),
    Text = "● Connecting...",
    TextColor3 = C.YELLOW,
    TextSize = 10,
    Font = GNRM,
    TextXAlignment = Enum.TextXAlignment.Left,
})

local MinBtn = btn(TBar, {
    Size = UDim2.new(0, 30, 0, 24),
    Position = UDim2.new(1, -68, 0.5, -12),
    BackgroundColor3 = C.DIM,
    Text = "—",
    TextColor3 = C.DIMTXT,
    TextSize = 13,
    Font = GBOL,
    ZIndex = 5,
})
rnd(MinBtn, 5)

local CloseBtn = btn(TBar, {
    Size = UDim2.new(0, 30, 0, 24),
    Position = UDim2.new(1, -32, 0.5, -12),
    BackgroundColor3 = Color3.fromRGB(195, 36, 52),
    Text = "✕",
    TextColor3 = C.WHITE,
    TextSize = 13,
    Font = GBOL,
    ZIndex = 5,
})
rnd(CloseBtn, 5)

-- ── Main tab bar ──────────────────────────────────────────
local TabBar = Instance.new("Frame")
TabBar.Size             = UDim2.new(1, -20, 0, 34)
TabBar.Position         = UDim2.new(0, 10, 0, 44)
TabBar.BackgroundColor3 = C.PANEL
TabBar.BorderSizePixel  = 0
TabBar.Parent           = Win
rnd(TabBar, 8)

do
    local l = Instance.new("UIListLayout")
    l.FillDirection       = Enum.FillDirection.Horizontal
    l.HorizontalAlignment = Enum.HorizontalAlignment.Center
    l.VerticalAlignment   = Enum.VerticalAlignment.Center
    l.Padding             = UDim.new(0, 4)
    l.Parent              = TabBar
end

local tabBtns   = {}
local tabFrames = {}
local TAB_NAMES = {"Execute", "Deobfusc.", "Malware", "UNC/SUNC"}

for _, name in TAB_NAMES do
    local b = btn(TabBar, {
        Size             = UDim2.new(0, 112, 1, -8),
        BackgroundColor3 = C.DIM,
        Text             = name,
        TextColor3       = C.DIMTXT,
        TextSize         = 11,
        Font             = GBOL,
    })
    rnd(b, 5)
    table.insert(tabBtns, b)
end

local BODY_Y = 82
local Body = Instance.new("Frame")
Body.Size               = UDim2.new(1, 0, 1, -BODY_Y)
Body.Position           = UDim2.new(0, 0, 0, BODY_Y)
Body.BackgroundTransparency = 1
Body.Parent             = Win

local function makeTabFrame()
    local f = Instance.new("Frame")
    f.Size    = UDim2.new(1, 0, 1, 0)
    f.BackgroundTransparency = 1
    f.Visible = false
    f.Parent  = Body
    return f
end

-- ══════════════════════════════════════════════════════════
-- TAB 1 – EXECUTE
-- ══════════════════════════════════════════════════════════
local T1 = makeTabFrame()

local ModeBar = Instance.new("Frame")
ModeBar.Size             = UDim2.new(1, -20, 0, 34)
ModeBar.Position         = UDim2.new(0, 10, 0, 8)
ModeBar.BackgroundColor3 = C.PANEL
ModeBar.BorderSizePixel  = 0
ModeBar.Parent           = T1
rnd(ModeBar, 8)

local function modeTabBtn(text, xScale, xOff)
    local b = btn(ModeBar, {
        Size             = UDim2.new(0.5, -5, 1, -8),
        Position         = UDim2.new(xScale, xOff, 0, 4),
        BackgroundColor3 = C.DIM,
        Text             = text,
        TextColor3       = C.DIMTXT,
        TextSize         = 12,
        Font             = GBOL,
    })
    rnd(b, 5)
    return b
end

local ClientTab = modeTabBtn("  Client Side", 0,   4)
local ServerTab = modeTabBtn("  Server Side", 0.5, 1)

local SubBar = Instance.new("Frame")
SubBar.Size             = UDim2.new(1, -20, 0, 28)
SubBar.Position         = UDim2.new(0, 10, 0, 48)
SubBar.BackgroundColor3 = C.PANEL
SubBar.BorderSizePixel  = 0
SubBar.Visible          = false
SubBar.Parent           = T1
rnd(SubBar, 7)

local function subModeBtn(text, xScale, xOff)
    local b = btn(SubBar, {
        Size             = UDim2.new(0.5, -5, 1, -6),
        Position         = UDim2.new(xScale, xOff, 0, 3),
        BackgroundColor3 = C.DIM,
        Text             = text,
        TextColor3       = C.DIMTXT,
        TextSize         = 11,
        Font             = GBOL,
    })
    rnd(b, 5)
    return b
end

local SubLS  = subModeBtn("loadstring", 0,   4)
local SubReq = subModeBtn("require",    0.5, 1)

local TypeBar = Instance.new("Frame")
TypeBar.Size             = UDim2.new(1, -20, 0, 24)
TypeBar.Position         = UDim2.new(0, 10, 0, 82)
TypeBar.BackgroundColor3 = C.PANEL
TypeBar.BorderSizePixel  = 0
TypeBar.Parent           = T1
rnd(TypeBar, 6)

do
    local l = Instance.new("UIListLayout")
    l.FillDirection       = Enum.FillDirection.Horizontal
    l.HorizontalAlignment = Enum.HorizontalAlignment.Center
    l.VerticalAlignment   = Enum.VerticalAlignment.Center
    l.Padding             = UDim.new(0, 4)
    l.Parent              = TypeBar
end

local codeTypeBtns = {}
for i, label in {"Normal", "URL", "Base64"} do
    local b = btn(TypeBar, {
        Size             = UDim2.new(0, 95, 1, -6),
        BackgroundColor3 = i == 1 and C.ACCENT or C.DIM,
        Text             = label,
        TextColor3       = i == 1 and C.WHITE or C.DIMTXT,
        TextSize         = 10,
        Font             = GBOL,
    })
    rnd(b, 4)
    table.insert(codeTypeBtns, b)
end

local ExecHint = lbl(T1, {
    Size             = UDim2.new(1, -20, 0, 14),
    Position         = UDim2.new(0, 10, 0, 112),
    Text             = "Client Side  →  loadstring(code)()",
    TextColor3       = Color3.fromRGB(90, 55, 170),
    TextSize         = 10,
    Font             = GNRM,
    TextXAlignment   = Enum.TextXAlignment.Left,
})

local EditorScroll = makeScrollFrame(T1, UDim2.new(0, 10, 0, 130), UDim2.new(1, -20, 0, 140))
local CodeBox      = makeCodeBox(EditorScroll, "-- Paste or type your script here...")

local ExecStatus = lbl(T1, {
    Size           = UDim2.new(1, -20, 0, 15),
    Position       = UDim2.new(0, 10, 0, 278),
    Text           = "Ready.",
    TextColor3     = C.DIMTXT,
    TextSize       = 10,
    Font           = GNRM,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate   = Enum.TextTruncate.AtEnd,
})

local BtnRow = Instance.new("Frame")
BtnRow.Size               = UDim2.new(1, -20, 0, 36)
BtnRow.Position           = UDim2.new(0, 10, 0, 296)
BtnRow.BackgroundTransparency = 1
BtnRow.Parent             = T1

do
    local l = Instance.new("UIListLayout")
    l.FillDirection      = Enum.FillDirection.Horizontal
    l.VerticalAlignment  = Enum.VerticalAlignment.Center
    l.Padding            = UDim.new(0, 7)
    l.Parent             = BtnRow
end

local function makeExecBtn(text, bg, w)
    local b = btn(BtnRow, {
        Size             = UDim2.new(0, w, 0, 32),
        BackgroundColor3 = bg,
        Text             = text,
        TextColor3       = C.WHITE,
        TextSize         = 12,
        Font             = GBOL,
    })
    rnd(b, 6)
    return b
end

local ExecBtn  = makeExecBtn("  Execute", C.ACCENT, 120)
local ClearBtn = makeExecBtn("Clear",     C.DIM,    72)
local CopyBtn  = makeExecBtn("Copy",      C.DIM,    66)
local URLBtn   = makeExecBtn("From URL",  C.DIM,    82)
ClearBtn.TextColor3 = C.DIMTXT
CopyBtn.TextColor3  = C.DIMTXT
URLBtn.TextColor3   = C.DIMTXT

local execMode    = "client"
local execSubMode = "ls"
local execCodeType= "normal"

local function setStatus(msg, col)
    ExecStatus.Text       = msg
    ExecStatus.TextColor3 = col or C.DIMTXT
end

local function applyMode(m)
    execMode = m
    if m == "server" then
        tw(ServerTab, {BackgroundColor3 = C.BLUE,   TextColor3 = C.WHITE  })
        tw(ClientTab, {BackgroundColor3 = C.DIM,    TextColor3 = C.DIMTXT })
        SubBar.Visible = true
        ExecBtn.BackgroundColor3 = C.BLUE
        ExecHint.Text = execSubMode == "ls"
            and "Server Side  →  loadstring(code)()  [full server perms]"
            or  "Server Side  →  require(assetId)  [numeric ID]"
    else
        tw(ClientTab, {BackgroundColor3 = C.ACCENT, TextColor3 = C.WHITE  })
        tw(ServerTab, {BackgroundColor3 = C.DIM,    TextColor3 = C.DIMTXT })
        SubBar.Visible = false
        ExecBtn.BackgroundColor3 = C.ACCENT
        ExecHint.Text = "Client Side  →  loadstring(code)()  [your client]"
    end
end

local function applySubMode(s)
    execSubMode = s
    if s == "ls" then
        tw(SubLS,  {BackgroundColor3 = C.BLUE, TextColor3 = C.WHITE  })
        tw(SubReq, {BackgroundColor3 = C.DIM,  TextColor3 = C.DIMTXT })
    else
        tw(SubReq, {BackgroundColor3 = C.BLUE, TextColor3 = C.WHITE  })
        tw(SubLS,  {BackgroundColor3 = C.DIM,  TextColor3 = C.DIMTXT })
    end
    if execMode == "server" then
        ExecHint.Text = s == "ls"
            and "Server Side  →  loadstring(code)()  [full server perms]"
            or  "Server Side  →  require(assetId)  [numeric ID]"
    end
end

local function applyCodeType(t)
    execCodeType = t
    local names = {"Normal", "URL", "Base64"}
    for i, b in codeTypeBtns do
        local active = names[i]:lower() == t
        tw(b, {BackgroundColor3 = active and C.ACCENT or C.DIM,
               TextColor3       = active and C.WHITE  or C.DIMTXT})
    end
end

applyMode("client")
applySubMode("ls")
applyCodeType("normal")

ClientTab.MouseButton1Click:Connect(function() applyMode("client") end)
ServerTab.MouseButton1Click:Connect(function() applyMode("server") end)
SubLS.MouseButton1Click:Connect(function()     applySubMode("ls")  end)
SubReq.MouseButton1Click:Connect(function()    applySubMode("req") end)
codeTypeBtns[1].MouseButton1Click:Connect(function() applyCodeType("normal") end)
codeTypeBtns[2].MouseButton1Click:Connect(function() applyCodeType("url")    end)
codeTypeBtns[3].MouseButton1Click:Connect(function() applyCodeType("base64") end)

ExecBtn.MouseButton1Click:Connect(function()
    local raw = CodeBox.Text
    if raw == "" or raw:match("^%s*$") then
        setStatus("Nothing to execute.", C.YELLOW)
        return
    end
    setStatus("Executing...", C.YELLOW)

    if execMode == "client" then
        local code = raw
        if execCodeType == "url" then
            local ok2, src = pcall(function() return game:HttpGet(raw, true) end)
            if not ok2 then setStatus("HTTP error: " .. tostring(src):sub(1,70), C.RED) return end
            code = src
        elseif execCodeType == "base64" then
            local ok2, dec = pcall(b64decode, raw)
            if not ok2 then setStatus("Base64 decode failed.", C.RED) return end
            code = dec
        end
        local fn, compErr = loadstring(code)
        if not fn then setStatus("Compile: " .. tostring(compErr):sub(1,70), C.RED) return end
        local ok2, runErr = pcall(fn)
        if ok2 then setStatus("Executed on client.", C.GREEN)
        else         setStatus("Runtime: " .. tostring(runErr):sub(1,70), C.RED) end

    else
        local action, payload = nil, {}
        if execSubMode == "req" then
            action = "req" ; payload.id = raw
        elseif execCodeType == "url" then
            action = "ls_url" ; payload.url = raw
        else
            local code = raw
            if execCodeType == "base64" then
                local ok2, dec = pcall(b64decode, raw)
                if not ok2 then setStatus("Base64 decode failed.", C.RED) return end
                code = dec
            end
            action = "ls" ; payload.code = code
        end
        local res = callBridge(action, payload)
        if res.ok then setStatus(tostring(res.msg), C.GREEN)
        else           setStatus(tostring(res.msg):sub(1,80), C.RED) end
    end
end)

ClearBtn.MouseButton1Click:Connect(function()
    CodeBox.Text = ""
    setStatus("Cleared.", C.DIMTXT)
end)

CopyBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(CodeBox.Text)
        setStatus("Copied to clipboard.", C.PURPLE)
    else
        setStatus("setclipboard not available.", C.YELLOW)
    end
end)

URLBtn.MouseButton1Click:Connect(function()
    applyCodeType("url")
    CodeBox.Text = ""
    setStatus("Paste a raw script URL and press Execute.", C.YELLOW)
end)

hookHover(ExecBtn,  C.ACCENT,                    C.ACCHOV)
hookHover(ClearBtn, C.DIM,    Color3.fromRGB(40, 40, 54))
hookHover(CopyBtn,  C.DIM,    Color3.fromRGB(40, 40, 54))
hookHover(URLBtn,   C.DIM,    Color3.fromRGB(40, 40, 54))

-- ══════════════════════════════════════════════════════════
-- TAB 2 – DEOBFUSCATE
-- ══════════════════════════════════════════════════════════
local T2 = makeTabFrame()

lbl(T2, {Size=UDim2.new(1,-20,0,14),Position=UDim2.new(0,10,0,6),
    Text="Obfuscated Input:",TextColor3=C.DIMTXT,TextSize=11,Font=GBOL,
    TextXAlignment=Enum.TextXAlignment.Left})

local D_InScroll = makeScrollFrame(T2, UDim2.new(0,10,0,24), UDim2.new(1,-20,0,108))
local D_InBox    = makeCodeBox(D_InScroll, "-- Paste obfuscated script here...")

local D_CtrlRow = Instance.new("Frame")
D_CtrlRow.Size               = UDim2.new(1,-20,0,30)
D_CtrlRow.Position           = UDim2.new(0,10,0,138)
D_CtrlRow.BackgroundTransparency = 1
D_CtrlRow.Parent             = T2
do
    local l=Instance.new("UIListLayout") l.FillDirection=Enum.FillDirection.Horizontal
    l.VerticalAlignment=Enum.VerticalAlignment.Center l.Padding=UDim.new(0,8) l.Parent=D_CtrlRow
end

local D_DetectBtn = btn(D_CtrlRow, {Size=UDim2.new(0,110,0,28),BackgroundColor3=C.DIM,
    Text="Detect Type",TextColor3=C.WHITE,TextSize=11,Font=GBOL}) ; rnd(D_DetectBtn,6)
local D_DeobfBtn  = btn(D_CtrlRow, {Size=UDim2.new(0,120,0,28),BackgroundColor3=C.ACCENT,
    Text="Deobfuscate",TextColor3=C.WHITE,TextSize=11,Font=GBOL}) ; rnd(D_DeobfBtn,6)
local D_TypeLbl   = lbl(D_CtrlRow, {Size=UDim2.new(0,210,0,28),Text="Type: —",
    TextColor3=C.YELLOW,TextSize=11,Font=GNRM,TextXAlignment=Enum.TextXAlignment.Left})

local D_StepsLbl = lbl(T2, {Size=UDim2.new(1,-20,0,14),Position=UDim2.new(0,10,0,174),
    Text="Steps: —",TextColor3=Color3.fromRGB(80,55,155),TextSize=10,Font=GNRM,
    TextXAlignment=Enum.TextXAlignment.Left})

lbl(T2, {Size=UDim2.new(1,-20,0,14),Position=UDim2.new(0,10,0,192),
    Text="Deobfuscated Output:",TextColor3=C.DIMTXT,TextSize=11,Font=GBOL,
    TextXAlignment=Enum.TextXAlignment.Left})

local D_OutScroll = makeScrollFrame(T2, UDim2.new(0,10,0,210), UDim2.new(1,-20,0,96))
local D_OutBox    = makeCodeBox(D_OutScroll, "-- Output appears here...")
D_OutBox.TextEditable = false

local D_BtmRow = Instance.new("Frame")
D_BtmRow.Size               = UDim2.new(1,-20,0,26)
D_BtmRow.Position           = UDim2.new(0,10,0,311)
D_BtmRow.BackgroundTransparency = 1
D_BtmRow.Parent             = T2
do
    local l=Instance.new("UIListLayout") l.FillDirection=Enum.FillDirection.Horizontal
    l.VerticalAlignment=Enum.VerticalAlignment.Center l.Padding=UDim.new(0,8) l.Parent=D_BtmRow
end

local D_CopyBtn = btn(D_BtmRow,{Size=UDim2.new(0,110,0,24),BackgroundColor3=C.DIM,
    Text="Copy Output",TextColor3=C.DIMTXT,TextSize=11,Font=GBOL}) ; rnd(D_CopyBtn,5)
local D_ExecBtn = btn(D_BtmRow,{Size=UDim2.new(0,140,0,24),BackgroundColor3=C.ACCENT,
    Text="Execute Output",TextColor3=C.WHITE,TextSize=11,Font=GBOL}) ; rnd(D_ExecBtn,5)

D_DetectBtn.MouseButton1Click:Connect(function()
    local s = D_InBox.Text
    if s == "" then return end
    D_TypeLbl.Text = "Type: " .. detectObfType(s)
end)
D_DeobfBtn.MouseButton1Click:Connect(function()
    local s = D_InBox.Text
    if s == "" or s:match("^%s*$") then return end
    D_TypeLbl.Text = "Type: " .. detectObfType(s)
    local out, steps = deobfuscate(s)
    D_OutBox.Text  = out
    D_StepsLbl.Text = "Steps: " .. steps
end)
D_CopyBtn.MouseButton1Click:Connect(function()
    if setclipboard and D_OutBox.Text ~= "" then
        setclipboard(D_OutBox.Text)
        D_TypeLbl.Text = "Copied!"
        task.delay(1.5, function() D_TypeLbl.Text = "Type: —" end)
    end
end)
D_ExecBtn.MouseButton1Click:Connect(function()
    local code = D_OutBox.Text
    if code == "" then return end
    local fn, e = loadstring(code)
    if not fn then D_TypeLbl.Text = "Compile error." return end
    local ok2, e2 = pcall(fn)
    D_TypeLbl.Text = ok2 and "Executed!" or "Error: " .. tostring(e2):sub(1,40)
end)

hookHover(D_DeobfBtn,  C.ACCENT, C.ACCHOV)
hookHover(D_DetectBtn, C.DIM,    Color3.fromRGB(40,40,54))
hookHover(D_CopyBtn,   C.DIM,    Color3.fromRGB(40,40,54))
hookHover(D_ExecBtn,   C.ACCENT, C.ACCHOV)

-- ══════════════════════════════════════════════════════════
-- TAB 3 – ANTI-MALWARE
-- ══════════════════════════════════════════════════════════
local T3 = makeTabFrame()

local M_BtnRow = Instance.new("Frame")
M_BtnRow.Size               = UDim2.new(1,-20,0,34)
M_BtnRow.Position           = UDim2.new(0,10,0,8)
M_BtnRow.BackgroundTransparency = 1
M_BtnRow.Parent             = T3
do
    local l=Instance.new("UIListLayout") l.FillDirection=Enum.FillDirection.Horizontal
    l.VerticalAlignment=Enum.VerticalAlignment.Center l.Padding=UDim.new(0,8) l.Parent=M_BtnRow
end

local function malBtn(text,bg,w)
    local b=btn(M_BtnRow,{Size=UDim2.new(0,w,0,30),BackgroundColor3=bg,Text=text,TextColor3=C.WHITE,TextSize=11,Font=GBOL})
    rnd(b,6) return b
end
local M_ScanBtn    = malBtn("  Scan Game",    C.BLUE,   120)
local M_KillAll    = malBtn("Kill All",       C.RED,    80)
local M_BlockRmt   = malBtn("Block Remotes",  C.ORANGE, 110)

local M_StatusLbl = lbl(T3,{Size=UDim2.new(1,-20,0,15),Position=UDim2.new(0,10,0,48),
    Text="Press Scan to detect threats.",TextColor3=C.DIMTXT,TextSize=10,Font=GNRM,
    TextXAlignment=Enum.TextXAlignment.Left})

local M_Scroll = Instance.new("ScrollingFrame")
M_Scroll.Size                = UDim2.new(1,-20,0,244)
M_Scroll.Position            = UDim2.new(0,10,0,68)
M_Scroll.BackgroundColor3    = C.PANEL
M_Scroll.BorderSizePixel     = 0
M_Scroll.ScrollBarThickness  = 4
M_Scroll.ScrollBarImageColor3 = C.ACCENT
M_Scroll.CanvasSize          = UDim2.new(0,0,0,0)
M_Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
M_Scroll.Parent              = T3
rnd(M_Scroll,7) str(M_Scroll,Color3.fromRGB(35,5,85),1)

do
    local l=Instance.new("UIListLayout") l.Padding=UDim.new(0,2) l.SortOrder=Enum.SortOrder.LayoutOrder l.Parent=M_Scroll
    local p=Instance.new("UIPadding") p.PaddingTop=UDim.new(0,4) p.PaddingLeft=UDim.new(0,4) p.PaddingRight=UDim.new(0,4) p.Parent=M_Scroll
end

local M_AutoRow = Instance.new("Frame")
M_AutoRow.Size               = UDim2.new(1,-20,0,22)
M_AutoRow.Position           = UDim2.new(0,10,0,318)
M_AutoRow.BackgroundTransparency = 1
M_AutoRow.Parent             = T3
do
    local l=Instance.new("UIListLayout") l.FillDirection=Enum.FillDirection.Horizontal
    l.VerticalAlignment=Enum.VerticalAlignment.Center l.Padding=UDim.new(0,8) l.Parent=M_AutoRow
end
local autoMonOn = false
local M_AutoBtn = btn(M_AutoRow,{Size=UDim2.new(0,130,0,20),BackgroundColor3=C.DIM,
    Text="Auto-Monitor: OFF",TextColor3=C.DIMTXT,TextSize=10,Font=GBOL}) ; rnd(M_AutoBtn,4)
lbl(M_AutoRow,{Size=UDim2.new(0,260,0,20),Text="Scans every 30s and kills new threats",
    TextColor3=Color3.fromRGB(60,60,85),TextSize=9,Font=GNRM,TextXAlignment=Enum.TextXAlignment.Left})

local currentFindings = {}

local function clearFindings()
    currentFindings = {}
    for _, c in M_Scroll:GetChildren() do
        if c:IsA("Frame") then c:Destroy() end
    end
end

local function addFindingRow(finding, i)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1,0,0,40)
    row.BackgroundColor3 = C.PANEL2
    row.BorderSizePixel  = 0
    row.LayoutOrder      = i
    row.Parent           = M_Scroll
    rnd(row,5)

    local kindCol = finding.kind:find("Script") and C.ORANGE or C.RED
    local badge = btn(row,{Size=UDim2.new(0,68,0,20),Position=UDim2.new(0,6,0.5,-10),
        BackgroundColor3=kindCol,Text=finding.kind:sub(1,10),TextColor3=C.WHITE,TextSize=9,Font=GBOL})
    rnd(badge,4)

    lbl(row,{Size=UDim2.new(1,-210,0,14),Position=UDim2.new(0,82,0,4),
        Text=finding.path:sub(-48),TextColor3=C.WHITE,TextSize=10,Font=GCOD,
        TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd})
    lbl(row,{Size=UDim2.new(1,-210,0,12),Position=UDim2.new(0,82,0,20),
        Text=finding.detail,TextColor3=C.DIMTXT,TextSize=9,Font=GNRM,
        TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd})

    local killBtn = btn(row,{Size=UDim2.new(0,50,0,24),Position=UDim2.new(1,-112,0.5,-12),
        BackgroundColor3=C.RED,Text="Kill",TextColor3=C.WHITE,TextSize=10,Font=GBOL}) ; rnd(killBtn,5)
    local blockBtn = btn(row,{Size=UDim2.new(0,54,0,24),Position=UDim2.new(1,-54,0.5,-12),
        BackgroundColor3=C.ORANGE,Text="Block",TextColor3=C.WHITE,TextSize=10,Font=GBOL}) ; rnd(blockBtn,5)
    blockBtn.Visible = finding.kind:find("Remote") ~= nil

    killBtn.MouseButton1Click:Connect(function()
        local res = callBridge("kill", {path=finding.path})
        M_StatusLbl.Text       = res.ok and "Killed: "..finding.path:sub(-50) or "Failed: "..tostring(res.msg)
        M_StatusLbl.TextColor3 = res.ok and C.GREEN or C.RED
        if res.ok then row:Destroy() end
    end)
    blockBtn.MouseButton1Click:Connect(function()
        local res = callBridge("block_remote", {path=finding.path})
        M_StatusLbl.Text       = tostring(res.msg)
        M_StatusLbl.TextColor3 = res.ok and C.GREEN or C.RED
    end)
end

local function runScan()
    M_StatusLbl.Text       = "Scanning..."
    M_StatusLbl.TextColor3 = C.YELLOW
    clearFindings()
    local res = callBridge("scan")
    if not res.ok then
        M_StatusLbl.Text       = "Scan failed: " .. tostring(res.msg)
        M_StatusLbl.TextColor3 = C.RED
        return
    end
    local data = res.data or {}
    if #data == 0 then
        M_StatusLbl.Text       = "Clean! No threats found."
        M_StatusLbl.TextColor3 = C.GREEN
        return
    end
    for i, line in data do
        local kind, path, detail = line:match("^(.-)|(.-)|(.*)")
        local f = {kind=kind or"?", path=path or"?", detail=detail or"?"}
        currentFindings[i] = f
        addFindingRow(f, i)
    end
    M_StatusLbl.Text       = tostring(res.msg) .. " – review below."
    M_StatusLbl.TextColor3 = C.ORANGE
end

M_ScanBtn.MouseButton1Click:Connect(function() task.spawn(runScan) end)
M_KillAll.MouseButton1Click:Connect(function()
    M_StatusLbl.Text = "Killing all..." M_StatusLbl.TextColor3 = C.YELLOW
    local res = callBridge("kill_all")
    M_StatusLbl.Text = tostring(res.msg) M_StatusLbl.TextColor3 = res.ok and C.GREEN or C.RED
    if res.ok then clearFindings() end
end)
M_BlockRmt.MouseButton1Click:Connect(function()
    local n = 0
    for _, f in currentFindings do
        if f.kind:find("Remote") then
            local r = callBridge("block_remote", {path=f.path})
            if r.ok then n = n + 1 end
        end
    end
    M_StatusLbl.Text = "Blocked " .. n .. " remote(s)." M_StatusLbl.TextColor3 = C.GREEN
end)
M_AutoBtn.MouseButton1Click:Connect(function()
    autoMonOn = not autoMonOn
    if autoMonOn then
        tw(M_AutoBtn, {BackgroundColor3 = C.GREEN}) M_AutoBtn.Text = "Auto-Monitor: ON" M_AutoBtn.TextColor3 = C.BG
        task.spawn(function()
            while autoMonOn do task.wait(30) if autoMonOn then task.spawn(runScan) end end
        end)
    else
        tw(M_AutoBtn, {BackgroundColor3 = C.DIM}) M_AutoBtn.Text = "Auto-Monitor: OFF" M_AutoBtn.TextColor3 = C.DIMTXT autoMonOn = false
    end
end)

hookHover(M_ScanBtn,  C.BLUE,   C.BLUEHOV)
hookHover(M_KillAll,  C.RED,    Color3.fromRGB(255,80,80))
hookHover(M_BlockRmt, C.ORANGE, Color3.fromRGB(255,150,50))

-- ══════════════════════════════════════════════════════════
-- TAB 4 – UNC / SUNC / MYRIAD
-- ══════════════════════════════════════════════════════════
local T4 = makeTabFrame()

local U_TopRow = Instance.new("Frame")
U_TopRow.Size               = UDim2.new(1,-20,0,26)
U_TopRow.Position           = UDim2.new(0,10,0,4)
U_TopRow.BackgroundTransparency = 1
U_TopRow.Parent             = T4
do
    local l=Instance.new("UIListLayout") l.FillDirection=Enum.FillDirection.Horizontal
    l.VerticalAlignment=Enum.VerticalAlignment.Center l.Padding=UDim.new(0,8) l.Parent=U_TopRow
end

local U_ExecName = lbl(U_TopRow,{Size=UDim2.new(0,210,1,0),Text="Executor: detecting...",
    TextColor3=C.PURPLE,TextSize=10,Font=GBOL,TextXAlignment=Enum.TextXAlignment.Left})
local U_CountLbl = lbl(U_TopRow,{Size=UDim2.new(0,160,1,0),Text="",
    TextColor3=C.DIMTXT,TextSize=9,Font=GNRM,TextXAlignment=Enum.TextXAlignment.Left})
local U_Refresh  = btn(U_TopRow,{Size=UDim2.new(0,68,0,22),BackgroundColor3=C.ACCENT,
    Text="Refresh",TextColor3=C.WHITE,TextSize=10,Font=GBOL}) ; rnd(U_Refresh,5)

local U_SubBar = Instance.new("Frame")
U_SubBar.Size             = UDim2.new(1,-20,0,28)
U_SubBar.Position         = UDim2.new(0,10,0,34)
U_SubBar.BackgroundColor3 = C.PANEL
U_SubBar.BorderSizePixel  = 0
U_SubBar.Parent           = T4
rnd(U_SubBar,7)
do
    local l=Instance.new("UIListLayout") l.FillDirection=Enum.FillDirection.Horizontal
    l.HorizontalAlignment=Enum.HorizontalAlignment.Center l.VerticalAlignment=Enum.VerticalAlignment.Center
    l.Padding=UDim.new(0,4) l.Parent=U_SubBar
end

local CHECK_TABS = {
    {"UNC (100)",    UNC_LIST,    C.BLUE,   C.BLUEHOV },
    {"SUNC (100)",   SUNC_LIST,   C.ACCENT, C.ACCHOV  },
    {"Myriad (250)", MYRIAD_LIST, C.ORANGE, Color3.fromRGB(255,155,55)},
}
local U_SubBtns = {}
for _, ct in CHECK_TABS do
    local b = btn(U_SubBar,{Size=UDim2.new(0,144,1,-6),BackgroundColor3=C.DIM,
        Text=ct[1],TextColor3=C.DIMTXT,TextSize=10,Font=GBOL}) ; rnd(b,5)
    table.insert(U_SubBtns, b)
end

local U_List = Instance.new("ScrollingFrame")
U_List.Size                = UDim2.new(1,-20,0,270)
U_List.Position            = UDim2.new(0,10,0,68)
U_List.BackgroundColor3    = C.PANEL
U_List.BorderSizePixel     = 0
U_List.ScrollBarThickness  = 4
U_List.ScrollBarImageColor3 = C.ACCENT
U_List.CanvasSize          = UDim2.new(0,0,0,0)
U_List.AutomaticCanvasSize = Enum.AutomaticSize.Y
U_List.Parent              = T4
rnd(U_List,7) str(U_List,Color3.fromRGB(30,5,70),1)
do
    local l=Instance.new("UIListLayout") l.Padding=UDim.new(0,1) l.SortOrder=Enum.SortOrder.LayoutOrder l.Parent=U_List
    local p=Instance.new("UIPadding") p.PaddingTop=UDim.new(0,3) p.PaddingLeft=UDim.new(0,4) p.PaddingRight=UDim.new(0,4) p.Parent=U_List
end

local CAT_COLORS = {
    Closure="5,140,200",   Crypt="140,50,200",    Debug="180,100,0",
    Drawing="200,80,150",  FileSystem="0,160,80", Input="160,160,0",
    Instance="0,120,160",  Metatable="160,60,0",  Misc="80,80,120",
    Scripts="100,0,160",   Signal="0,160,120",    Thread="160,100,0",
    HTTP="0,100,200",      Cache="100,140,0",     WebSocket="0,160,200",
    Console="60,110,60",
    ScriptEnv="0,110,180", ScriptState="100,60,0",ScriptLife="120,0,120",
    ScriptVar="0,140,100", ScriptFind="160,80,0", ScriptHier="0,80,160",
    ScriptID="140,0,80",   ScriptMod="80,130,0",  ScriptCrypt="0,100,140",
    ScriptSandbox="90,0,160",
    MyrDraw="200,80,150",  MyrMem="160,40,40",    MyrNet="0,110,200",
    MyrAnti="160,20,20",   MyrSpy="140,100,0",    MyrByte="60,60,180",
    MyrUI="0,140,120",     MyrPhys="80,120,0",    MyrRep="0,90,160",
    MyrGame="120,60,0",    MyrDbg="160,80,0",     MyrEvt="80,0,140",
    MyrExec="100,30,200",  MyrLic="0,120,80",     MyrInst="0,80,120",
}

local function catColor(cat)
    local rgb = CAT_COLORS[cat]
    if not rgb then return C.DIM end
    local r, g, b = rgb:match("(%d+),(%d+),(%d+)")
    return Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
end

local activeCheckTab = 0

local function buildCheckList(listData, accentCol)
    for _, c in U_List:GetChildren() do
        if c:IsA("Frame") then c:Destroy() end
    end
    U_List.CanvasPosition = Vector2.new(0, 0)

    local execName = "Unknown Executor"
    if identifyexecutor then
        local ok2, n = pcall(identifyexecutor)
        if ok2 then execName = tostring(n) end
    elseif getexecutorname then
        local ok2, n = pcall(getexecutorname)
        if ok2 then execName = tostring(n) end
    end
    U_ExecName.Text = "Executor: " .. execName

    local total, supported = 0, 0
    for i, entry in listData do
        local name, cat = entry[1], entry[2]
        total = total + 1
        local avail = hasUNC(name)
        if avail then supported = supported + 1 end

        local row = Instance.new("Frame")
        row.Size             = UDim2.new(1, 0, 0, 22)
        row.BackgroundColor3 = avail and Color3.fromRGB(12,26,12) or Color3.fromRGB(22,10,10)
        row.BorderSizePixel  = 0
        row.LayoutOrder      = i
        row.Parent           = U_List
        rnd(row, 4)

        lbl(row,{Size=UDim2.new(0,18,1,0),Position=UDim2.new(0,4,0,0),
            Text=avail and "●" or "○",
            TextColor3=avail and C.GREEN or Color3.fromRGB(100,30,30),
            TextSize=12,Font=GBOL,TextXAlignment=Enum.TextXAlignment.Center})

        local catBadge = btn(row,{Size=UDim2.new(0,76,0,14),Position=UDim2.new(0,24,0.5,-7),
            BackgroundColor3=catColor(cat),Text=cat,TextColor3=C.WHITE,TextSize=7,Font=GBOL})
        rnd(catBadge,3) catBadge.AutoButtonColor=false

        lbl(row,{Size=UDim2.new(1,-175,1,0),Position=UDim2.new(0,106,0,0),Text=name,
            TextColor3=avail and Color3.fromRGB(185,245,185) or Color3.fromRGB(160,75,75),
            TextSize=10,Font=GCOD,TextXAlignment=Enum.TextXAlignment.Left})

        lbl(row,{Size=UDim2.new(0,65,1,0),Position=UDim2.new(1,-67,0,0),
            Text=avail and "SUPPORTED" or "MISSING",
            TextColor3=avail and C.GREEN or Color3.fromRGB(115,35,35),
            TextSize=8,Font=GBOL,TextXAlignment=Enum.TextXAlignment.Right})
    end

    local pct = total > 0 and supported/total or 0
    U_CountLbl.Text       = "Supported: " .. supported .. "/" .. total .. "  (" .. math.floor(pct*100) .. "%)"
    U_CountLbl.TextColor3 = pct > 0.7 and C.GREEN or pct > 0.4 and C.YELLOW or C.RED
end

local function switchCheckTab(i)
    if activeCheckTab == i then return end
    activeCheckTab = i
    local ct = CHECK_TABS[i]
    for j, b in U_SubBtns do
        local active = j == i
        tw(b, {BackgroundColor3 = active and ct[3] or C.DIM,
               TextColor3       = active and C.WHITE or C.DIMTXT})
    end
    task.spawn(buildCheckList, ct[2], ct[3])
end

for i, b in U_SubBtns do
    local ct = CHECK_TABS[i]
    b.MouseEnter:Connect(function() if activeCheckTab ~= i then tw(b,{BackgroundColor3=Color3.fromRGB(40,40,54)}) end end)
    b.MouseLeave:Connect(function() if activeCheckTab ~= i then tw(b,{BackgroundColor3=C.DIM}) end end)
    b.MouseButton1Click:Connect(function() switchCheckTab(i) end)
end
U_Refresh.MouseButton1Click:Connect(function()
    local i = activeCheckTab > 0 and activeCheckTab or 1
    task.spawn(buildCheckList, CHECK_TABS[i][2], CHECK_TABS[i][3])
end)
hookHover(U_Refresh, C.ACCENT, C.ACCHOV)

-- ── Tab switching ─────────────────────────────────────────
tabFrames = {T1, T2, T3, T4}
local activeTab = 0

local function switchTab(i)
    if activeTab == i then return end
    activeTab = i
    for j, f in tabFrames do
        f.Visible = j == i
    end
    for j, b in tabBtns do
        local active = j == i
        tw(b, {BackgroundColor3 = active and C.ACCENT or C.DIM,
               TextColor3       = active and C.WHITE  or C.DIMTXT})
    end
    if i == 4 and activeCheckTab == 0 then
        switchCheckTab(1)
    end
end

for i, b in tabBtns do
    b.MouseButton1Click:Connect(function() switchTab(i) end)
end
switchTab(1)

-- ── Server ping ───────────────────────────────────────────
task.spawn(function()
    local res = callBridge("ping")
    if res.ok then
        DotLbl.Text       = "● Server connected"
        DotLbl.TextColor3 = C.GREEN
    else
        DotLbl.Text       = "● Server offline  (client mode only)"
        DotLbl.TextColor3 = C.RED
    end
end)

-- ── Window controls ───────────────────────────────────────
local minimised = false

MinBtn.MouseButton1Click:Connect(function()
    minimised = not minimised
    if minimised then
        tws(Win, {Size = UDim2.new(0, WIN_W, 0, 40)})
        MinBtn.Text = "□"
    else
        tws(Win, {Size = UDim2.new(0, WIN_W, 0, WIN_H)})
        MinBtn.Text = "—"
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    tws(Win, {Size = UDim2.new(0, 0, 0, 0)})
    task.delay(0.25, function() SG:Destroy() end)
end)

hookHover(MinBtn,   C.DIM,                     Color3.fromRGB(42,42,56))
hookHover(CloseBtn, Color3.fromRGB(195,36,52),  Color3.fromRGB(230,55,72))

-- ── Drag  (mouse + touch) ─────────────────────────────────
local dragging, dragStart, winStart = false, nil, nil

TBar.InputBegan:Connect(function(inp)
    local t = inp.UserInputType
    if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
        dragging  = true
        dragStart = inp.Position
        winStart  = Win.Position
        inp.Changed:Connect(function()
            if inp.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UIS.InputChanged:Connect(function(inp)
    if not dragging then return end
    local t = inp.UserInputType
    if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
        local d = inp.Position - dragStart
        Win.Position = UDim2.new(
            winStart.X.Scale, winStart.X.Offset + d.X,
            winStart.Y.Scale, winStart.Y.Offset + d.Y
        )
    end
end)

UIS.InputEnded:Connect(function(inp)
    local t = inp.UserInputType
    if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
        dragging = false
    end
end)

warn("[SS Executor] GUI loaded successfully.")

end) -- end pcall

if not ok then
    warn("[SS Executor] STARTUP ERROR: " .. tostring(err))
end
