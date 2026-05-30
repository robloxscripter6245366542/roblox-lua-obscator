-- ============================================================
--  FULL SS EXECUTOR  –  Combined Single-Script Loader
--  One file.  Loadstring on SERVER or CLIENT.
--
--  • Runs on SERVER  → sets up loadstring/require bridge AND
--    builds the GUI directly in your PlayerGui
--  • Runs on CLIENT  → builds the full GUI, client-side exec only
--    (server features disabled until SS_ExecBridge is found)
--
--  Mobile (iOS/iPadOS/Android) and PC both supported.
--  Drag the window by its title bar.
-- ============================================================

local RS        = game:GetService("RunService")
local Players   = game:GetService("Players")
local RepStore  = game:GetService("ReplicatedStorage")
local UIS       = game:GetService("UserInputService")
local TweenSvc  = game:GetService("TweenService")
local Http      = game:GetService("HttpService")

local IS_SERVER = RS:IsServer()
local IS_CLIENT = RS:IsClient()
local LP        = IS_CLIENT and Players.LocalPlayer or nil
local REMOTE_NAME = "SS_ExecBridge"

-- ══════════════════════════════════════════════════════════
-- [A]  SERVER HANDLER  (only runs when executed server-side)
-- ══════════════════════════════════════════════════════════
if IS_SERVER then

    local ALLOWED_NAMES = {}  -- {"YourName"}
    local ALLOWED_UIDS  = {}  -- {12345678}

    local function isAllowed(p)
        if #ALLOWED_NAMES==0 and #ALLOWED_UIDS==0 then return true end
        for _,n  in ALLOWED_NAMES do if p.Name   ==n  then return true end end
        for _,id in ALLOWED_UIDS  do if p.UserId ==id then return true end end
        return false
    end

    local old=RepStore:FindFirstChild(REMOTE_NAME)
    if old then old:Destroy() end

    local Bridge=Instance.new("RemoteFunction")
    Bridge.Name=REMOTE_NAME Bridge.Parent=RepStore

    local MALWARE_SIGS={
        "discord%.com/api/webhooks","webhook%.site","requestbin%.com",
        "hookbin%.com","pipedream%.net","hastebin%.com/raw",
        "getfenv%s*%(%)%.loadstring","syn%.request.*webhook",
    }
    local SUSPECT_REMOTES={
        "backdoor","exploit","inject","cmd","execute",
        "admin_bypass","btools","spy","hack","bypass",
    }

    local function serverScan()
        local findings={}
        for _,obj in game:GetDescendants() do
            if obj:IsA("LuaSourceContainer") then
                local src="" ; pcall(function() src=obj.Source end)
                if src~="" then
                    for _,sig in MALWARE_SIGS do
                        if src:lower():find(sig) then
                            table.insert(findings,{path=obj:GetFullName(),kind=obj.ClassName,detail="Sig: "..sig})
                            break
                        end
                    end
                end
            elseif obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                local nl=obj.Name:lower()
                for _,kw in SUSPECT_REMOTES do
                    if nl:find(kw) then
                        table.insert(findings,{path=obj:GetFullName(),kind=obj.ClassName,detail="Name: "..obj.Name})
                        break
                    end
                end
            end
        end
        return findings
    end

    local function destroyPath(path)
        local obj=game
        for part in path:gmatch("[^.]+") do if obj then obj=obj:FindFirstChild(part) end end
        if obj and obj~=game then obj:Destroy() return true end
        return false
    end

    Bridge.OnServerInvoke=function(player,action,payload)
        if not isAllowed(player) then return{ok=false,msg="Unauthorized."} end
        payload=payload or {}

        if action=="ping" then return{ok=true,msg="pong"}

        elseif action=="ls" then
            local fn,err=loadstring(payload.code or "")
            if not fn then return{ok=false,msg="Compile: "..tostring(err)} end
            local ok,e=pcall(fn)
            return ok and{ok=true,msg="Server loadstring OK."}or{ok=false,msg="Runtime: "..tostring(e)}

        elseif action=="req" then
            local id=tonumber(payload.id)
            if not id then return{ok=false,msg="Need numeric asset ID."} end
            local ok,e=pcall(require,id)
            return ok and{ok=true,msg="require("..id..") OK."}or{ok=false,msg=tostring(e)}

        elseif action=="ls_url" then
            local ok,src=pcall(function() return Http:GetAsync(payload.url or "",true) end)
            if not ok then return{ok=false,msg="HTTP: "..tostring(src)} end
            local fn,err=loadstring(src)
            if not fn then return{ok=false,msg="Compile: "..tostring(err)} end
            local ok2,e=pcall(fn)
            return ok2 and{ok=true,msg="URL exec OK."}or{ok=false,msg="Runtime: "..tostring(e)}

        elseif action=="scan" then
            local f=serverScan()
            local lines={}
            for _,v in f do table.insert(lines,v.kind.."|"..v.path.."|"..v.detail) end
            return{ok=true,msg=#f.." finding(s)",data=lines}

        elseif action=="kill" then
            local done=destroyPath(payload.path or "")
            return done and{ok=true,msg="Killed."}or{ok=false,msg="Not found."}

        elseif action=="kill_all" then
            local f=serverScan() local killed=0
            for _,v in f do if destroyPath(v.path) then killed+=1 end end
            return{ok=true,msg="Killed "..killed.." item(s)."}

        elseif action=="block_remote" then
            local obj=game
            for part in (payload.path or ""):gmatch("[^.]+") do if obj then obj=obj:FindFirstChild(part) end end
            if obj and(obj:IsA("RemoteEvent")or obj:IsA("RemoteFunction")) then
                pcall(function()
                    if obj:IsA("RemoteFunction") then obj.OnServerInvoke=function()end
                    else obj.OnServerEvent:Connect(function()end) end
                end)
                return{ok=true,msg="Remote neutered."}
            end
            return{ok=false,msg="Remote not found."}

        elseif action=="getplrs" then
            local names={}
            for _,p in Players:GetPlayers() do table.insert(names,p.Name.." ("..p.UserId..")") end
            return{ok=true,msg=table.concat(names,"\n")}
        end
        return{ok=false,msg="Unknown: "..tostring(action)}
    end

    warn("[SS Executor] Server handler online. Bridge: ReplicatedStorage."..REMOTE_NAME)
end

-- ══════════════════════════════════════════════════════════
-- [B]  CLIENT GUI  (runs on client — or server injects it)
-- ══════════════════════════════════════════════════════════

-- If server-side, find the player to inject into (first player, or owner)
if IS_SERVER then
    local targetPlayer=Players:GetPlayers()[1]
    if not targetPlayer then
        Players.PlayerAdded:Wait()
        targetPlayer=Players:GetPlayers()[1]
    end
    LP=targetPlayer
end

if not LP then return end

local PGui=LP:WaitForChild("PlayerGui")
if PGui:FindFirstChild("SS_ExecGUI") then PGui.SS_ExecGUI:Destroy() end

local Bridge=RepStore:FindFirstChild(REMOTE_NAME)

-- ── Theme ─────────────────────────────────────────────────
local C={
    BG=Color3.fromRGB(8,8,11),PANEL=Color3.fromRGB(16,16,21),
    PANEL2=Color3.fromRGB(20,20,27),INPUT=Color3.fromRGB(11,11,15),
    ACCENT=Color3.fromRGB(105,15,225),ACCHOV=Color3.fromRGB(125,38,248),
    BLUE=Color3.fromRGB(25,120,220),BLUEHOV=Color3.fromRGB(40,145,245),
    DIM=Color3.fromRGB(28,28,38),DIMTXT=Color3.fromRGB(125,125,160),
    WHITE=Color3.new(1,1,1),GREEN=Color3.fromRGB(60,210,75),
    RED=Color3.fromRGB(238,60,60),YELLOW=Color3.fromRGB(255,198,42),
    PURPLE=Color3.fromRGB(185,140,255),STROKE=Color3.fromRGB(70,8,170),
    ORANGE=Color3.fromRGB(240,130,30),
}
local TIF=TweenInfo.new(0.14)
local TIS=TweenInfo.new(0.22,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
local GBOL=Enum.Font.GothamBold
local GNRM=Enum.Font.Gotham
local GCOD=Enum.Font.Code

local function tw(o,p)  TweenSvc:Create(o,TIF,p):Play() end
local function tws(o,p) TweenSvc:Create(o,TIS,p):Play() end
local function rnd(p,r) local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r or 7) c.Parent=p end
local function str(p,col,th) local s=Instance.new("UIStroke") s.Color=col or C.STROKE s.Thickness=th or 1.2 s.Parent=p end
local function lbl(parent,props)
    local l=Instance.new("TextLabel") l.BackgroundTransparency=1
    for k,v in props do pcall(function()l[k]=v end) end l.Parent=parent return l
end
local function btn(parent,props)
    local b=Instance.new("TextButton") b.BorderSizePixel=0 b.AutoButtonColor=false
    for k,v in props do pcall(function()b[k]=v end) end b.Parent=parent return b
end
local function scrollBox(parent,pos,size)
    local sf=Instance.new("ScrollingFrame")
    sf.Position=pos sf.Size=size sf.BackgroundColor3=C.INPUT sf.BorderSizePixel=0
    sf.ScrollBarThickness=4 sf.ScrollBarImageColor3=C.ACCENT
    sf.CanvasSize=UDim2.new(0,0,0,0) sf.AutomaticCanvasSize=Enum.AutomaticSize.Y
    sf.Parent=parent rnd(sf,7) str(sf,Color3.fromRGB(48,4,115),1) return sf
end
local function codeBox(parent,ph)
    local tb=Instance.new("TextBox")
    tb.Size=UDim2.new(1,-10,1,0) tb.Position=UDim2.new(0,5,0,5)
    tb.BackgroundTransparency=1 tb.Text="" tb.PlaceholderText=ph or ""
    tb.PlaceholderColor3=Color3.fromRGB(55,55,78) tb.TextColor3=Color3.fromRGB(215,215,255)
    tb.TextSize=12 tb.Font=GCOD tb.MultiLine=true
    tb.TextXAlignment=Enum.TextXAlignment.Left tb.TextYAlignment=Enum.TextYAlignment.Top
    tb.ClearTextOnFocus=false tb.Parent=parent return tb
end
local function hoverHook(b,norm,hov)
    b.MouseEnter:Connect(function()tw(b,{BackgroundColor3=hov})end)
    b.MouseLeave:Connect(function()tw(b,{BackgroundColor3=norm})end)
end
local function callBridge(action,payload)
    if not Bridge then return{ok=false,msg="Bridge not found."} end
    local ok,res=pcall(Bridge.InvokeServer,Bridge,action,payload or{})
    if not ok then return{ok=false,msg=tostring(res)} end
    return res or{ok=false,msg="nil response"}
end

-- ── UNC / SUNC / MYRIAD lists (abbreviated for space) ────
-- Full 100/100/250 lists identical to executor_gui.lua
-- (see executor_gui.lua in the repository for the complete lists)
local UNC_LIST={
    {"checkcaller","Closure"},{"clonefunction","Closure"},{"getcallingscript","Closure"},{"hookfunction","Closure"},
    {"iscclosure","Closure"},{"islclosure","Closure"},{"newcclosure","Closure"},{"replaceclosure","Closure"},
    {"crypt.base64decode","Crypt"},{"crypt.base64encode","Crypt"},{"crypt.decrypt","Crypt"},{"crypt.encrypt","Crypt"},
    {"crypt.generatebytes","Crypt"},{"crypt.generatekey","Crypt"},{"crypt.hash","Crypt"},
    {"debug.getconstant","Debug"},{"debug.getconstants","Debug"},{"debug.getinfo","Debug"},{"debug.getproto","Debug"},
    {"debug.getprotos","Debug"},{"debug.getstack","Debug"},{"debug.getupvalue","Debug"},{"debug.getupvalues","Debug"},
    {"debug.setconstant","Debug"},{"debug.setupvalue","Debug"},
    {"Drawing","Drawing"},{"cleardrawcache","Drawing"},{"isrenderobj","Drawing"},{"getrenderproperty","Drawing"},{"setrenderproperty","Drawing"},
    {"appendfile","FileSystem"},{"delfile","FileSystem"},{"delfolder","FileSystem"},{"isfile","FileSystem"},{"isfolder","FileSystem"},
    {"listfiles","FileSystem"},{"loadfile","FileSystem"},{"makefolder","FileSystem"},{"readfile","FileSystem"},{"writefile","FileSystem"},
    {"isrbxactive","Input"},{"keypress","Input"},{"keyrelease","Input"},{"mouse1click","Input"},{"mouse1press","Input"},
    {"mouse1release","Input"},{"mouse2click","Input"},{"mouse2press","Input"},{"mouse2release","Input"},
    {"mousemoveabs","Input"},{"mousemoverel","Input"},{"mousescroll","Input"},
    {"fireclickdetector","Instance"},{"fireproximityprompt","Instance"},{"firetouchinterest","Instance"},{"getcustomasset","Instance"},
    {"gethiddenproperty","Instance"},{"gethui","Instance"},{"getinstances","Instance"},{"getnilinstances","Instance"},
    {"isscriptable","Instance"},{"sethiddenproperty","Instance"},{"setscriptable","Instance"},
    {"getrawmetatable","Metatable"},{"hookmetamethod","Metatable"},{"setrawmetatable","Metatable"},{"setreadonly","Metatable"},{"isreadonly","Metatable"},
    {"getexecutorname","Misc"},{"identifyexecutor","Misc"},{"gethwid","Misc"},{"isluau","Misc"},
    {"lz4compress","Misc"},{"lz4decompress","Misc"},{"messagebox","Misc"},{"queue_on_teleport","Misc"},
    {"setfpscap","Misc"},{"getfpscap","Misc"},{"setclipboard","Misc"},{"getclipboard","Misc"},{"saveinstance","Misc"},
    {"getgc","Scripts"},{"getgenv","Scripts"},{"getloadedmodules","Scripts"},{"getrunningscripts","Scripts"},
    {"getscripts","Scripts"},{"getrenv","Scripts"},{"getsenv","Scripts"},
    {"getconnections","Signal"},{"firesignal","Signal"},
    {"getthreadidentity","Thread"},{"setthreadidentity","Thread"},{"getidentity","Thread"},{"setidentity","Thread"},
    {"request","HTTP"},{"http_request","HTTP"},
    {"cache.invalidate","Cache"},{"cache.iscached","Cache"},{"cache.replace","Cache"},
    {"WebSocket","WebSocket"},
    {"rconsoleclose","Console"},{"rconsolecreate","Console"},{"rconsoleinfo","Console"},
    {"rconsoleprint","Console"},{"rconsoleprintdefault","Console"},{"rconsolename","Console"},{"rconsolewarn","Console"},
}
local SUNC_LIST={
    {"getscriptclosure","ScriptEnv"},{"getscriptfunction","ScriptEnv"},{"getscriptenv","ScriptEnv"},{"getscriptbytecode","ScriptEnv"},
    {"getscripthash","ScriptEnv"},{"getscriptname","ScriptEnv"},{"getscriptpath","ScriptEnv"},{"getscriptid","ScriptEnv"},
    {"getscriptguid","ScriptEnv"},{"decompile","ScriptEnv"},
    {"isscriptrunning","ScriptState"},{"isscriptpaused","ScriptState"},{"isscriptenabled","ScriptState"},{"enablescript","ScriptState"},
    {"disablescript","ScriptState"},{"pausescript","ScriptState"},{"resumescript","ScriptState"},{"stopscript","ScriptState"},
    {"restartscript","ScriptState"},{"killscript","ScriptState"},
    {"forkscript","ScriptLife"},{"startscript","ScriptLife"},{"reloadscript","ScriptLife"},{"getscriptstate","ScriptLife"},
    {"setscriptstate","ScriptLife"},{"getscriptmemoryusage","ScriptLife"},{"getscriptcpuusage","ScriptLife"},
    {"getscriptuptime","ScriptLife"},{"getscriptthread","ScriptLife"},{"getscriptactor","ScriptLife"},
    {"getscriptglobals","ScriptVar"},{"getscriptlocals","ScriptVar"},{"getscriptupvalues","ScriptVar"},{"getscriptconstants","ScriptVar"},
    {"getscriptprotos","ScriptVar"},{"setscriptglobal","ScriptVar"},{"setscriptlocal","ScriptVar"},
    {"setscriptupvalue","ScriptVar"},{"setscriptconstant","ScriptVar"},{"setscriptenv","ScriptVar"},
    {"findscriptbyname","ScriptFind"},{"findscriptbypath","ScriptFind"},{"findscriptbyid","ScriptFind"},{"findscriptbytarget","ScriptFind"},
    {"findscriptbyclosure","ScriptFind"},{"getscriptcallers","ScriptFind"},{"getscriptcallstack","ScriptFind"},
    {"getallscripts","ScriptFind"},{"getmodulescripts","ScriptFind"},{"getlocalscripts","ScriptFind"},
    {"getscriptparent","ScriptHier"},{"setscriptparent","ScriptHier"},{"getscriptchildren","ScriptHier"},{"getscriptdescendants","ScriptHier"},
    {"getscriptcategory","ScriptHier"},{"setscriptcategory","ScriptHier"},{"getscriptlevel","ScriptHier"},{"setscriptlevel","ScriptHier"},
    {"getscriptobject","ScriptHier"},{"setscriptobject","ScriptHier"},
    {"getscriptidentity","ScriptID"},{"setscriptidentity","ScriptID"},{"getscriptpermissions","ScriptID"},{"setscriptpermissions","ScriptID"},
    {"getscriptflags","ScriptID"},{"setscriptflags","ScriptID"},{"isscriptprotected","ScriptID"},{"protectscript","ScriptID"},
    {"unprotectscript","ScriptID"},{"isscriptobfuscated","ScriptID"},
    {"clonescript","ScriptMod"},{"patchscript","ScriptMod"},{"injectscript","ScriptMod"},{"hookscript","ScriptMod"},
    {"unhookscript","ScriptMod"},{"wrapscript","ScriptMod"},{"unwrapscript","ScriptMod"},{"validatescript","ScriptMod"},
    {"compressscript","ScriptMod"},{"decompressscript","ScriptMod"},
    {"encryptscript","ScriptCrypt"},{"decryptscript","ScriptCrypt"},{"obfuscatescript","ScriptCrypt"},{"deobfuscatescript","ScriptCrypt"},
    {"getsignature","ScriptCrypt"},{"setsignature","ScriptCrypt"},{"getscriptbytecodemodified","ScriptCrypt"},
    {"redecompile","ScriptCrypt"},{"signalscript","ScriptCrypt"},{"waitforscript","ScriptCrypt"},
    {"getenvtype","ScriptSandbox"},{"setenvtype","ScriptSandbox"},{"getsafeenv","ScriptSandbox"},{"setsafeenv","ScriptSandbox"},
    {"getprotectedenv","ScriptSandbox"},{"setprotectedenv","ScriptSandbox"},{"isolateenv","ScriptSandbox"},
    {"mergeenv","ScriptSandbox"},{"cloneenv","ScriptSandbox"},{"cleanenv","ScriptSandbox"},
}
local MYRIAD_LIST={
    {"Drawing.new","MyrDraw"},{"Drawing.clear","MyrDraw"},{"Drawing.Font","MyrDraw"},{"getdrawobjects","MyrDraw"},{"getdrawcount","MyrDraw"},
    {"renderdraw","MyrDraw"},{"updatedraw","MyrDraw"},{"deletedraw","MyrDraw"},{"clonedraw","MyrDraw"},{"movedraw","MyrDraw"},
    {"rotatedraw","MyrDraw"},{"scaledraw","MyrDraw"},{"setdrawzindex","MyrDraw"},{"getdrawzindex","MyrDraw"},{"setdrawvisibility","MyrDraw"},
    {"getdrawvisibility","MyrDraw"},{"setdrawcolor","MyrDraw"},{"setdrawthickness","MyrDraw"},{"setdrawtransparency","MyrDraw"},{"setdrawfilled","MyrDraw"},
    {"readprocessmemory","MyrMem"},{"writeprocessmemory","MyrMem"},{"getmodulebase","MyrMem"},{"getmodulesize","MyrMem"},{"getprocessid","MyrMem"},
    {"allocatemem","MyrMem"},{"freemem","MyrMem"},{"protectmem","MyrMem"},{"unprotectmem","MyrMem"},{"scanmemory","MyrMem"},
    {"getmemorymap","MyrMem"},{"getmemoryusage","MyrMem"},{"setmemorycap","MyrMem"},{"flushmemorycache","MyrMem"},{"getmemoryregions","MyrMem"},
    {"dumprequest","MyrNet"},{"firelog","MyrNet"},{"blockrequest","MyrNet"},{"filterrequest","MyrNet"},{"capturerequest","MyrNet"},
    {"getwebrequests","MyrNet"},{"clearwebrequests","MyrNet"},{"logrequest","MyrNet"},{"filterresponse","MyrNet"},{"modifyrequest","MyrNet"},
    {"modifyresponse","MyrNet"},{"interceptrequest","MyrNet"},{"forwardrequest","MyrNet"},{"rejectrequest","MyrNet"},{"getnetworkid","MyrNet"},
    {"setnetworkid","MyrNet"},{"gettransferrate","MyrNet"},{"settransferrate","MyrNet"},{"getlatency","MyrNet"},{"simulatelagspike","MyrNet"},
    {"spoofscriptname","MyrAnti"},{"spoofscriptpath","MyrAnti"},{"spoofscriptid","MyrAnti"},{"spoofidentity","MyrAnti"},{"spoofthreadid","MyrAnti"},
    {"protectgui","MyrAnti"},{"disguisescript","MyrAnti"},{"disguiseexecutor","MyrAnti"},{"getdetectionflags","MyrAnti"},{"cleardetectionflags","MyrAnti"},
    {"bypassanticheat","MyrAnti"},{"simulatelegitplayer","MyrAnti"},{"fakescriptactivity","MyrAnti"},{"getanticheatlevel","MyrAnti"},{"setanticheatlevel","MyrAnti"},
    {"disablevanguard","MyrAnti"},{"disablebyfron","MyrAnti"},{"disablehyperion","MyrAnti"},{"whitelistprocess","MyrAnti"},{"setexecutorname","MyrAnti"},
    {"initremotespy","MyrSpy"},{"getrecentremotes","MyrSpy"},{"filterremote","MyrSpy"},{"blockremotespy","MyrSpy"},{"hookremote","MyrSpy"},
    {"unhookremote","MyrSpy"},{"logremotetraffic","MyrSpy"},{"getremotehistory","MyrSpy"},{"clearremotehistory","MyrSpy"},{"getremotecallstack","MyrSpy"},
    {"hookallremotes","MyrSpy"},{"unhookallremotes","MyrSpy"},{"whitelistremote","MyrSpy"},{"blacklistremote","MyrSpy"},{"remotespy_setfilter","MyrSpy"},
    {"remotespy_getfilter","MyrSpy"},{"remotespy_export","MyrSpy"},{"remotespy_import","MyrSpy"},{"getremotecount","MyrSpy"},{"getremoterate","MyrSpy"},
    {"compile","MyrByte"},{"getbytecode","MyrByte"},{"loadbytecode","MyrByte"},{"executebytecode","MyrByte"},{"verifybytecode","MyrByte"},
    {"getbytecodeversion","MyrByte"},{"setbytecodeversion","MyrByte"},{"patchbytecode","MyrByte"},{"hotpatch","MyrByte"},{"getbytecodeinfo","MyrByte"},
    {"setbytecodeinfo","MyrByte"},{"disassemble","MyrByte"},{"reassemble","MyrByte"},{"optimize","MyrByte"},{"minify","MyrByte"},
    {"prettify","MyrByte"},{"tokenize","MyrByte"},{"parse","MyrByte"},{"serialize","MyrByte"},{"deserialize","MyrByte"},
    {"simulateguiclick","MyrUI"},{"simulateguiinput","MyrUI"},{"simulateguitouch","MyrUI"},{"simulateguiscroll","MyrUI"},{"getguiinsets","MyrUI"},
    {"setguiinsets","MyrUI"},{"capturescreen","MyrUI"},{"recordgameplay","MyrUI"},{"stoprecording","MyrUI"},{"getviewportsize","MyrUI"},
    {"setfov","MyrUI"},{"getfov","MyrUI"},{"setrenderquality","MyrUI"},{"getrenderquality","MyrUI"},{"resetrendersettings","MyrUI"},
    {"setphysicsrate","MyrPhys"},{"getphysicsrate","MyrPhys"},{"pausephysics","MyrPhys"},{"resumephysics","MyrPhys"},{"setgravity","MyrPhys"},
    {"getgravity","MyrPhys"},{"setnetworkphysics","MyrPhys"},{"getnetworkphysics","MyrPhys"},{"setphysicsinterpolation","MyrPhys"},{"getphysicsinterpolation","MyrPhys"},
    {"getphysicsjoint","MyrPhys"},{"setphysicsjoint","MyrPhys"},{"getrigid","MyrPhys"},{"setrigid","MyrPhys"},{"applyphysicsimpulse","MyrPhys"},
    {"forcereplicate","MyrRep"},{"blockreplication","MyrRep"},{"setreplicationrate","MyrRep"},{"getreplicationqueue","MyrRep"},{"clearreplicationqueue","MyrRep"},
    {"getnetworkowner","MyrRep"},{"setnetworkowner","MyrRep"},{"getnetworkstats","MyrRep"},{"syncnetwork","MyrRep"},{"getpacketrate","MyrRep"},
    {"setpacketrate","MyrRep"},{"getpacketsize","MyrRep"},{"compress_packet","MyrRep"},{"encrypt_packet","MyrRep"},{"decrypt_packet","MyrRep"},
    {"getworkspacegravity","MyrGame"},{"setworkspacegravity","MyrGame"},{"setphysicssetting","MyrGame"},{"getphysicssetting","MyrGame"},{"getterraindata","MyrGame"},
    {"setterraindata","MyrGame"},{"modifyterrain","MyrGame"},{"getdatamodel","MyrGame"},{"setdatamodel","MyrGame"},{"getserverlocation","MyrGame"},
    {"getserverinfo","MyrGame"},{"getclientinfo","MyrGame"},{"getgameversion","MyrGame"},{"getgameid","MyrGame"},{"getplaceversion","MyrGame"},
    {"getassetrootid","MyrGame"},{"getassetversion","MyrGame"},{"checkasset","MyrGame"},{"cacheasset","MyrGame"},{"uncacheasset","MyrGame"},
    {"debug.readmemory","MyrDebug"},{"debug.writememory","MyrDebug"},{"debug.getregisters","MyrDebug"},{"debug.setregisters","MyrDebug"},{"debug.getflags","MyrDebug"},
    {"debug.setflags","MyrDebug"},{"debug.getmodules","MyrDebug"},{"debug.getthreads","MyrDebug"},{"debug.suspendthread","MyrDebug"},{"debug.resumethread","MyrDebug"},
    {"debug.getthreadinfo","MyrDebug"},{"debug.getip","MyrDebug"},{"debug.setip","MyrDebug"},{"debug.getsp","MyrDebug"},{"debug.setsp","MyrDebug"},
    {"createevent","MyrEvent"},{"destroyevent","MyrEvent"},{"fireevent","MyrEvent"},{"hookevent","MyrEvent"},{"unhookevent","MyrEvent"},
    {"defevent","MyrEvent"},{"filterevent","MyrEvent"},{"prioritizeevent","MyrEvent"},{"getevents","MyrEvent"},{"clearevents","MyrEvent"},
    {"getconnectioncount","MyrEvent"},{"disconnectall","MyrEvent"},{"reconnectall","MyrEvent"},{"getfirecount","MyrEvent"},{"resetfirecount","MyrEvent"},
    {"getexecutorversion","MyrExec"},{"getexecutorbuild","MyrExec"},{"getexecutorlicense","MyrExec"},{"isfeatureenabled","MyrExec"},{"enablefeature","MyrExec"},
    {"disablefeature","MyrExec"},{"getfeaturelist","MyrExec"},{"setperformancemode","MyrExec"},{"getperformancemode","MyrExec"},{"setthreadpriority","MyrExec"},
    {"getthreadpriority","MyrExec"},{"gettaskscheduler","MyrExec"},{"setfpstarget","MyrExec"},{"getfpstarget","MyrExec"},{"getframetime","MyrExec"},
    {"getuptime","MyrExec"},{"getmemorytotal","MyrExec"},{"getmemoryavailable","MyrExec"},{"getexecutorflags","MyrExec"},{"setexecutorflags","MyrExec"},
    {"getlicensekey","MyrLic"},{"setlicensekey","MyrLic"},{"validatelicensekey","MyrLic"},{"getlicensestatus","MyrLic"},{"getlicenseholder","MyrLic"},
    {"getinstancecreationcallbacks","MyrInst"},{"setinstancecreationcallback","MyrInst"},{"interceptinstancecreation","MyrInst"},
    {"interceptpropertyset","MyrInst"},{"getpropertychangedcallbacks","MyrInst"},{"setpropertychangedcallback","MyrInst"},
    {"compareinstances","MyrInst"},{"getspecialinfo","MyrInst"},{"setspecialinfo","MyrInst"},{"getfullpath","MyrInst"},
    {"clonetree","MyrInst"},{"mergetrees","MyrInst"},{"diffinstances","MyrInst"},{"syncinstances","MyrInst"},{"snapshotinstance","MyrInst"},
}

local function hasUNC(name)
    if name:find("%.") then
        local tbl,key=name:match("^(.-)%.(.+)$")
        local t=rawget(_G,tbl)
        if t==nil then local ok,v=pcall(function()return _G[tbl]end) t=ok and v or nil end
        if type(t)=="table" then return rawget(t,key)~=nil end
        return false
    end
    if rawget(_G,name)~=nil then return true end
    local ok,v=pcall(function()
        local env=(getfenv and getfenv())or _G return rawget(env,name)
    end)
    return ok and v~=nil
end

-- Deobfuscator
local function detectObfType(s)
    if s:find("Luraph")or s:find("lura%.ph") then return "Luraph"
    elseif s:find("IronBrew")or s:find("Iron%s*Brew") then return "IronBrew 2"
    elseif s:find("Prometheus") then return "Prometheus"
    elseif s:find("Moonsec") then return "Moonsec"
    elseif s:find("_0x%x+") and #s>500 then return "Hex-var obfuscated"
    elseif s:find("string%.byte")and s:find("string%.char")and #s>2000 then return "String-table VM"
    elseif s:find("local%s+[A-Z][A-Z0-9]*%s*=%s*{")and #s>3000 then return "Custom VM / bytecode"
    end return "Unknown / Custom"
end
local function deobfuscate(src)
    local out,log=src,{}
    local n
    out,n=out:gsub("\\x(%x%x)",function(h)return string.char(tonumber(h,16))end)
    if n>0 then log[#log+1]="Decoded "..n.." hex esc" end
    out,n=out:gsub("\\(%d%d?%d?)",function(d)local v=tonumber(d) if v and v>=32 and v<=126 then return string.char(v) end return "\\"..d end)
    if n>0 then log[#log+1]="Decoded "..n.." dec esc" end
    out=out:gsub("string%.char%(([%d,%s]+)%)",function(args)
        local chars={} for num in args:gmatch("%d+") do local v=tonumber(num) if not v or v<32 or v>126 then return "string.char("..args..")" end chars[#chars+1]=string.char(v) end
        log[#log+1]="Folded string.char"
        return '"'..table.concat(chars):gsub('"','\\"')..'"'
    end)
    local changed,folds=true,0
    while changed do changed=false
        out=out:gsub('"([^"\\]*)"%s*%.%.%s*"([^"\\]*)"',function(a,b)changed=true folds+=1 return '"'..a..b..'"' end)
    end
    if folds>0 then log[#log+1]="Folded "..folds.." concat(s)" end
    out=out:gsub("\n\n\n+","\n\n")
    return out,#log>0 and table.concat(log,"  |  ") or "No simplifications."
end

-- Base64
local B64="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function b64decode(data)
    data=data:gsub("[^"..B64.."=]","")
    return(data:gsub(".",function(x)
        if x=="=" then return "" end
        local r,f="",B64:find(x)-1
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and "1" or "0") end return r
    end):gsub("%d%d%d%d%d%d%d%d",function(x)
        local n=0 for i=1,8 do n=n+(x:sub(i,i)=="1" and 2^(8-i) or 0) end return string.char(n)
    end))
end

-- ── Root GUI ──────────────────────────────────────────────
local SG=Instance.new("ScreenGui")
SG.Name="SS_ExecGUI" SG.ResetOnSpawn=false SG.DisplayOrder=999
SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling SG.Parent=PGui

local WIN_W,WIN_H=520,420
local Win=Instance.new("Frame")
Win.Name="Win" Win.Size=UDim2.new(0,WIN_W,0,WIN_H)
Win.Position=UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2)
Win.BackgroundColor3=C.BG Win.BorderSizePixel=0 Win.ClipsDescendants=true Win.Parent=SG
rnd(Win,10) str(Win,C.STROKE,1.5)

-- Title bar
local TBar=Instance.new("Frame")
TBar.Name="TBar" TBar.Size=UDim2.new(1,0,0,40) TBar.BackgroundColor3=C.PANEL
TBar.BorderSizePixel=0 TBar.ZIndex=4 TBar.Parent=Win rnd(TBar,10)
local TBP=Instance.new("Frame") TBP.Size=UDim2.new(1,0,0.5,0) TBP.Position=UDim2.new(0,0,0.5,0)
TBP.BackgroundColor3=C.PANEL TBP.BorderSizePixel=0 TBP.ZIndex=4 TBP.Parent=TBar
lbl(TBar,{Size=UDim2.new(1,-110,1,0),Position=UDim2.new(0,12,0,0),Text="  Full SS Executor",
    TextColor3=C.PURPLE,TextSize=14,Font=GBOL,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5})
local DotLbl=lbl(Win,{Size=UDim2.new(0,180,0,14),Position=UDim2.new(0,12,0,26),
    Text="● Connecting...",TextColor3=C.YELLOW,TextSize=10,Font=GNRM,TextXAlignment=Enum.TextXAlignment.Left})
local MinBtn=btn(TBar,{Size=UDim2.new(0,30,0,24),Position=UDim2.new(1,-68,0.5,-12),
    BackgroundColor3=C.DIM,Text="—",TextColor3=C.DIMTXT,TextSize=13,Font=GBOL,ZIndex=5})
rnd(MinBtn,5)
local CloseBtn=btn(TBar,{Size=UDim2.new(0,30,0,24),Position=UDim2.new(1,-32,0.5,-12),
    BackgroundColor3=Color3.fromRGB(195,36,52),Text="✕",TextColor3=C.WHITE,TextSize=13,Font=GBOL,ZIndex=5})
rnd(CloseBtn,5)

-- Tab bar
local TABS_Y=40
local TabBar=Instance.new("Frame")
TabBar.Size=UDim2.new(1,-20,0,34) TabBar.Position=UDim2.new(0,10,0,TABS_Y+4)
TabBar.BackgroundColor3=C.PANEL TabBar.BorderSizePixel=0 TabBar.Parent=Win rnd(TabBar,8)
do local l=Instance.new("UIListLayout") l.FillDirection=Enum.FillDirection.Horizontal
   l.HorizontalAlignment=Enum.HorizontalAlignment.Center l.VerticalAlignment=Enum.VerticalAlignment.Center
   l.Padding=UDim.new(0,4) l.Parent=TabBar end

local tabBtns,tabFrames={},{}
local TAB_NAMES={"Execute","Deobfusc.","Malware","UNC/SUNC"}
for _,name in TAB_NAMES do
    local b=btn(TabBar,{Size=UDim2.new(0,112,1,-8),BackgroundColor3=C.DIM,
        Text=name,TextColor3=C.DIMTXT,TextSize=11,Font=GBOL}) rnd(b,5)
    tabBtns[#tabBtns+1]=b
end

local CONTENT_Y=TABS_Y+4+34+4
local Body=Instance.new("Frame")
Body.Name="Body" Body.Size=UDim2.new(1,0,1,-CONTENT_Y) Body.Position=UDim2.new(0,0,0,CONTENT_Y)
Body.BackgroundTransparency=1 Body.Parent=Win

local function makeTabFrame()
    local f=Instance.new("Frame") f.Size=UDim2.new(1,0,1,0)
    f.BackgroundTransparency=1 f.Visible=false f.Parent=Body return f
end

-- ═══════════ TAB 1 – EXECUTE ══════════════════════════════
local T1=makeTabFrame()
local ModeBar=Instance.new("Frame")
ModeBar.Size=UDim2.new(1,-20,0,34) ModeBar.Position=UDim2.new(0,10,0,8)
ModeBar.BackgroundColor3=C.PANEL ModeBar.BorderSizePixel=0 ModeBar.Parent=T1 rnd(ModeBar,8)
local function modeBtn(text,x,off)
    local b=btn(ModeBar,{Size=UDim2.new(0.5,-5,1,-8),Position=UDim2.new(x,off,0,4),
        BackgroundColor3=C.DIM,Text=text,TextColor3=C.DIMTXT,TextSize=12,Font=GBOL}) rnd(b,5) return b
end
local ClientTab=modeBtn("  Client Side",0,4) local ServerTab=modeBtn("  Server Side",0.5,1)
local SubBar=Instance.new("Frame")
SubBar.Size=UDim2.new(1,-20,0,28) SubBar.Position=UDim2.new(0,10,0,48)
SubBar.BackgroundColor3=C.PANEL SubBar.BorderSizePixel=0 SubBar.Visible=false SubBar.Parent=T1 rnd(SubBar,7)
local function subBtn(text,x,off)
    local b=btn(SubBar,{Size=UDim2.new(0.5,-5,1,-6),Position=UDim2.new(x,off,0,3),
        BackgroundColor3=C.DIM,Text=text,TextColor3=C.DIMTXT,TextSize=11,Font=GBOL}) rnd(b,5) return b
end
local SubLS=subBtn("loadstring",0,4) local SubReq=subBtn("require",0.5,1)
local TypeBar=Instance.new("Frame")
TypeBar.Size=UDim2.new(1,-20,0,24) TypeBar.Position=UDim2.new(0,10,0,82)
TypeBar.BackgroundColor3=C.PANEL TypeBar.BorderSizePixel=0 TypeBar.Parent=T1 rnd(TypeBar,6)
do local l=Instance.new("UIListLayout") l.FillDirection=Enum.FillDirection.Horizontal
   l.HorizontalAlignment=Enum.HorizontalAlignment.Center l.VerticalAlignment=Enum.VerticalAlignment.Center
   l.Padding=UDim.new(0,4) l.Parent=TypeBar end
local codeTypeBtns={}
for i,label in {"Normal","URL","Base64"} do
    local b=btn(TypeBar,{Size=UDim2.new(0,95,1,-6),BackgroundColor3=i==1 and C.ACCENT or C.DIM,
        Text=label,TextColor3=i==1 and C.WHITE or C.DIMTXT,TextSize=10,Font=GBOL}) rnd(b,4) codeTypeBtns[i]=b
end
local ExecHint=lbl(T1,{Size=UDim2.new(1,-20,0,14),Position=UDim2.new(0,10,0,112),
    Text="Client Side  →  loadstring(code)()",TextColor3=Color3.fromRGB(90,55,170),
    TextSize=10,Font=GNRM,TextXAlignment=Enum.TextXAlignment.Left})
local ExecScroll=scrollBox(T1,UDim2.new(0,10,0,130),UDim2.new(1,-20,0,140))
local CodeBox=codeBox(ExecScroll,"-- Paste or type script here...")
local ExecStatus=lbl(T1,{Size=UDim2.new(1,-20,0,15),Position=UDim2.new(0,10,0,278),
    Text="Ready.",TextColor3=C.DIMTXT,TextSize=10,Font=GNRM,TextXAlignment=Enum.TextXAlignment.Left})
local ExecRow=Instance.new("Frame")
ExecRow.Size=UDim2.new(1,-20,0,36) ExecRow.Position=UDim2.new(0,10,0,296)
ExecRow.BackgroundTransparency=1 ExecRow.Parent=T1
do local l=Instance.new("UIListLayout") l.FillDirection=Enum.FillDirection.Horizontal
   l.VerticalAlignment=Enum.VerticalAlignment.Center l.Padding=UDim.new(0,7) l.Parent=ExecRow end
local function execBtn(text,bg,w)
    local b=btn(ExecRow,{Size=UDim2.new(0,w,0,32),BackgroundColor3=bg,Text=text,TextColor3=C.WHITE,TextSize=12,Font=GBOL}) rnd(b,6) return b
end
local ExecBtn=execBtn("  Execute",C.ACCENT,120) local ClearBtn=execBtn("Clear",C.DIM,72)
local CopyBtn=execBtn("Copy",C.DIM,66) local URLBtn=execBtn("From URL",C.DIM,82)
ClearBtn.TextColor3=C.DIMTXT CopyBtn.TextColor3=C.DIMTXT URLBtn.TextColor3=C.DIMTXT

local mode,subMode,codeType="client","ls","normal"
local function setExecStatus(msg,col) ExecStatus.Text=msg ExecStatus.TextColor3=col or C.DIMTXT end
local function applyExecMode(m)
    mode=m local isServ=m=="server" SubBar.Visible=isServ
    if isServ then
        tw(ServerTab,{BackgroundColor3=C.BLUE,TextColor3=C.WHITE}) tw(ClientTab,{BackgroundColor3=C.DIM,TextColor3=C.DIMTXT})
        ExecBtn.BackgroundColor3=C.BLUE
        ExecHint.Text=subMode=="ls" and "Server Side  →  loadstring(code)()  [full server perms]" or "Server Side  →  require(assetId)"
    else
        tw(ClientTab,{BackgroundColor3=C.ACCENT,TextColor3=C.WHITE}) tw(ServerTab,{BackgroundColor3=C.DIM,TextColor3=C.DIMTXT})
        ExecBtn.BackgroundColor3=C.ACCENT ExecHint.Text="Client Side  →  loadstring(code)()  [your client]"
    end
end
local function applySubMode(s)
    subMode=s
    if s=="ls" then tw(SubLS,{BackgroundColor3=C.BLUE,TextColor3=C.WHITE}) tw(SubReq,{BackgroundColor3=C.DIM,TextColor3=C.DIMTXT})
    else tw(SubReq,{BackgroundColor3=C.BLUE,TextColor3=C.WHITE}) tw(SubLS,{BackgroundColor3=C.DIM,TextColor3=C.DIMTXT}) end
    if mode=="server" then ExecHint.Text=s=="ls" and "Server Side  →  loadstring(code)()  [full server perms]" or "Server Side  →  require(assetId)" end
end
local function applyCodeType(t)
    codeType=t local names={"Normal","URL","Base64"}
    for i,b in codeTypeBtns do local a=(names[i]:lower()==t) tw(b,{BackgroundColor3=a and C.ACCENT or C.DIM,TextColor3=a and C.WHITE or C.DIMTXT}) end
end
applyExecMode("client") applySubMode("ls") applyCodeType("normal")
ClientTab.MouseButton1Click:Connect(function()applyExecMode("client")end)
ServerTab.MouseButton1Click:Connect(function()applyExecMode("server")end)
SubLS.MouseButton1Click:Connect(function()applySubMode("ls")end)
SubReq.MouseButton1Click:Connect(function()applySubMode("req")end)
codeTypeBtns[1].MouseButton1Click:Connect(function()applyCodeType("normal")end)
codeTypeBtns[2].MouseButton1Click:Connect(function()applyCodeType("url")end)
codeTypeBtns[3].MouseButton1Click:Connect(function()applyCodeType("base64")end)

ExecBtn.MouseButton1Click:Connect(function()
    local raw=CodeBox.Text if raw==""or raw:match("^%s*$") then setExecStatus("Nothing to execute.",C.YELLOW) return end
    setExecStatus("Executing...",C.YELLOW)
    if mode=="client" then
        local code=raw
        if codeType=="url" then local ok,src=pcall(function()return game:HttpGet(raw,true)end) if not ok then setExecStatus("HTTP: "..tostring(src):sub(1,70),C.RED) return end code=src
        elseif codeType=="base64" then local ok,dec=pcall(b64decode,raw) if not ok then setExecStatus("Base64 decode failed.",C.RED) return end code=dec end
        local fn,err=loadstring(code) if not fn then setExecStatus("Compile: "..tostring(err):sub(1,70),C.RED) return end
        local ok,e=pcall(fn) if ok then setExecStatus("Executed on client.",C.GREEN) else setExecStatus("Runtime: "..tostring(e):sub(1,70),C.RED) end
    else
        local action,payload=nil,{}
        if subMode=="req" then action="req" payload.id=raw
        elseif codeType=="url" then action="ls_url" payload.url=raw
        else local code=raw if codeType=="base64" then local ok,dec=pcall(b64decode,raw) if not ok then setExecStatus("Base64 decode failed.",C.RED) return end code=dec end action="ls" payload.code=code end
        local res=callBridge(action,payload) if res.ok then setExecStatus(tostring(res.msg),C.GREEN) else setExecStatus(tostring(res.msg):sub(1,80),C.RED) end
    end
end)
ClearBtn.MouseButton1Click:Connect(function()CodeBox.Text="" setExecStatus("Cleared.",C.DIMTXT)end)
CopyBtn.MouseButton1Click:Connect(function()if setclipboard then setclipboard(CodeBox.Text) setExecStatus("Copied.",C.PURPLE) else setExecStatus("setclipboard unavailable.",C.YELLOW) end end)
URLBtn.MouseButton1Click:Connect(function()applyCodeType("url") CodeBox.Text="" setExecStatus("Paste raw URL and execute.",C.YELLOW)end)
hoverHook(ExecBtn,C.ACCENT,C.ACCHOV) hoverHook(ClearBtn,C.DIM,Color3.fromRGB(40,40,54))
hoverHook(CopyBtn,C.DIM,Color3.fromRGB(40,40,54)) hoverHook(URLBtn,C.DIM,Color3.fromRGB(40,40,54))

-- ═══════════ TAB 2 – DEOBFUSCATE ══════════════════════════
local T2=makeTabFrame()
lbl(T2,{Size=UDim2.new(1,-20,0,14),Position=UDim2.new(0,10,0,6),Text="Obfuscated Input:",TextColor3=C.DIMTXT,TextSize=11,Font=GBOL,TextXAlignment=Enum.TextXAlignment.Left})
local DeobfIn=scrollBox(T2,UDim2.new(0,10,0,24),UDim2.new(1,-20,0,108))
local DeobfInBox=codeBox(DeobfIn,"-- Paste obfuscated script here...")
local DetectRow=Instance.new("Frame") DetectRow.Size=UDim2.new(1,-20,0,30) DetectRow.Position=UDim2.new(0,10,0,138) DetectRow.BackgroundTransparency=1 DetectRow.Parent=T2
do local l=Instance.new("UIListLayout") l.FillDirection=Enum.FillDirection.Horizontal l.VerticalAlignment=Enum.VerticalAlignment.Center l.Padding=UDim.new(0,8) l.Parent=DetectRow end
local DetectBtn=btn(DetectRow,{Size=UDim2.new(0,110,0,28),BackgroundColor3=C.DIM,Text="Detect Type",TextColor3=C.WHITE,TextSize=11,Font=GBOL}) rnd(DetectBtn,6)
local DeobfBtn=btn(DetectRow,{Size=UDim2.new(0,120,0,28),BackgroundColor3=C.ACCENT,Text="Deobfuscate",TextColor3=C.WHITE,TextSize=11,Font=GBOL}) rnd(DeobfBtn,6)
local ObfTypeLbl=lbl(DetectRow,{Size=UDim2.new(0,210,0,28),Text="Type: —",TextColor3=C.YELLOW,TextSize=11,Font=GNRM,TextXAlignment=Enum.TextXAlignment.Left})
local StepsLbl=lbl(T2,{Size=UDim2.new(1,-20,0,14),Position=UDim2.new(0,10,0,174),Text="Steps: —",TextColor3=Color3.fromRGB(80,55,155),TextSize=10,Font=GNRM,TextXAlignment=Enum.TextXAlignment.Left})
lbl(T2,{Size=UDim2.new(1,-20,0,14),Position=UDim2.new(0,10,0,192),Text="Deobfuscated Output:",TextColor3=C.DIMTXT,TextSize=11,Font=GBOL,TextXAlignment=Enum.TextXAlignment.Left})
local DeobfOut=scrollBox(T2,UDim2.new(0,10,0,210),UDim2.new(1,-20,0,96))
local DeobfOutBox=codeBox(DeobfOut,"-- Output appears here...") DeobfOutBox.TextEditable=false
local DeobfBtmRow=Instance.new("Frame") DeobfBtmRow.Size=UDim2.new(1,-20,0,26) DeobfBtmRow.Position=UDim2.new(0,10,0,311) DeobfBtmRow.BackgroundTransparency=1 DeobfBtmRow.Parent=T2
do local l=Instance.new("UIListLayout") l.FillDirection=Enum.FillDirection.Horizontal l.VerticalAlignment=Enum.VerticalAlignment.Center l.Padding=UDim.new(0,8) l.Parent=DeobfBtmRow end
local CopyOutBtn=btn(DeobfBtmRow,{Size=UDim2.new(0,110,0,24),BackgroundColor3=C.DIM,Text="Copy Output",TextColor3=C.DIMTXT,TextSize=11,Font=GBOL}) rnd(CopyOutBtn,5)
local ExecDeobfBtn=btn(DeobfBtmRow,{Size=UDim2.new(0,140,0,24),BackgroundColor3=C.ACCENT,Text="Execute Output",TextColor3=C.WHITE,TextSize=11,Font=GBOL}) rnd(ExecDeobfBtn,5)
DetectBtn.MouseButton1Click:Connect(function()local s=DeobfInBox.Text if s==""then return end ObfTypeLbl.Text="Type: "..detectObfType(s)end)
DeobfBtn.MouseButton1Click:Connect(function()local s=DeobfInBox.Text if s==""or s:match("^%s*$")then return end ObfTypeLbl.Text="Type: "..detectObfType(s) local out,steps=deobfuscate(s) DeobfOutBox.Text=out StepsLbl.Text="Steps: "..steps end)
CopyOutBtn.MouseButton1Click:Connect(function()if setclipboard and DeobfOutBox.Text~=""then setclipboard(DeobfOutBox.Text) ObfTypeLbl.Text="Copied!" task.delay(1.5,function()ObfTypeLbl.Text="Type: —"end)end end)
ExecDeobfBtn.MouseButton1Click:Connect(function()local code=DeobfOutBox.Text if code==""then return end local fn,err=loadstring(code) if not fn then ObfTypeLbl.Text="Compile: "..tostring(err):sub(1,40) return end local ok,e=pcall(fn) ObfTypeLbl.Text=ok and "Executed!" or "Error: "..tostring(e):sub(1,40)end)
hoverHook(DeobfBtn,C.ACCENT,C.ACCHOV) hoverHook(DetectBtn,C.DIM,Color3.fromRGB(40,40,54))
hoverHook(CopyOutBtn,C.DIM,Color3.fromRGB(40,40,54)) hoverHook(ExecDeobfBtn,C.ACCENT,C.ACCHOV)

-- ═══════════ TAB 3 – ANTI-MALWARE ═════════════════════════
local T3=makeTabFrame()
local MalRow=Instance.new("Frame") MalRow.Size=UDim2.new(1,-20,0,34) MalRow.Position=UDim2.new(0,10,0,8) MalRow.BackgroundTransparency=1 MalRow.Parent=T3
do local l=Instance.new("UIListLayout") l.FillDirection=Enum.FillDirection.Horizontal l.VerticalAlignment=Enum.VerticalAlignment.Center l.Padding=UDim.new(0,8) l.Parent=MalRow end
local function malBtn(text,bg,w) local b=btn(MalRow,{Size=UDim2.new(0,w,0,30),BackgroundColor3=bg,Text=text,TextColor3=C.WHITE,TextSize=11,Font=GBOL}) rnd(b,6) return b end
local ScanBtn=malBtn("  Scan Game",C.BLUE,120) local KillAllBtn=malBtn("Kill All",C.RED,80) local BlockRmtBtn=malBtn("Block Remotes",C.ORANGE,110)
local MalStatus=lbl(T3,{Size=UDim2.new(1,-20,0,15),Position=UDim2.new(0,10,0,48),Text="Press Scan to detect threats.",TextColor3=C.DIMTXT,TextSize=10,Font=GNRM,TextXAlignment=Enum.TextXAlignment.Left})
local FindScroll=Instance.new("ScrollingFrame")
FindScroll.Size=UDim2.new(1,-20,0,244) FindScroll.Position=UDim2.new(0,10,0,68)
FindScroll.BackgroundColor3=C.PANEL FindScroll.BorderSizePixel=0 FindScroll.ScrollBarThickness=4
FindScroll.ScrollBarImageColor3=C.ACCENT FindScroll.CanvasSize=UDim2.new(0,0,0,0)
FindScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y FindScroll.Parent=T3
rnd(FindScroll,7) str(FindScroll,Color3.fromRGB(35,5,85),1)
local FindLayout=Instance.new("UIListLayout") FindLayout.Padding=UDim.new(0,2) FindLayout.SortOrder=Enum.SortOrder.LayoutOrder FindLayout.Parent=FindScroll
local FindPad=Instance.new("UIPadding") FindPad.PaddingTop=UDim.new(0,4) FindPad.PaddingLeft=UDim.new(0,4) FindPad.PaddingRight=UDim.new(0,4) FindPad.Parent=FindScroll
local AutoRow=Instance.new("Frame") AutoRow.Size=UDim2.new(1,-20,0,22) AutoRow.Position=UDim2.new(0,10,0,318) AutoRow.BackgroundTransparency=1 AutoRow.Parent=T3
do local l=Instance.new("UIListLayout") l.FillDirection=Enum.FillDirection.Horizontal l.VerticalAlignment=Enum.VerticalAlignment.Center l.Padding=UDim.new(0,8) l.Parent=AutoRow end
local autoMonOn=false
local AutoBtn=btn(AutoRow,{Size=UDim2.new(0,130,0,20),BackgroundColor3=C.DIM,Text="Auto-Monitor: OFF",TextColor3=C.DIMTXT,TextSize=10,Font=GBOL}) rnd(AutoBtn,4)
lbl(AutoRow,{Size=UDim2.new(0,250,0,20),Text="Scans every 30s, kills new threats",TextColor3=Color3.fromRGB(65,65,90),TextSize=9,Font=GNRM,TextXAlignment=Enum.TextXAlignment.Left})
local currentFindings={}
local function clearFindings() currentFindings={} for _,c in FindScroll:GetChildren() do if c:IsA("Frame")then c:Destroy()end end end
local function addFindingRow(finding,i)
    local row=Instance.new("Frame") row.Size=UDim2.new(1,0,0,40) row.BackgroundColor3=C.PANEL2 row.BorderSizePixel=0 row.LayoutOrder=i row.Parent=FindScroll rnd(row,5)
    local kindCol=finding.kind:find("Script")and C.ORANGE or C.RED
    local badge=btn(row,{Size=UDim2.new(0,68,0,20),Position=UDim2.new(0,6,0.5,-10),BackgroundColor3=kindCol,Text=finding.kind:sub(1,10),TextColor3=C.WHITE,TextSize=9,Font=GBOL}) rnd(badge,4)
    lbl(row,{Size=UDim2.new(1,-210,0,14),Position=UDim2.new(0,82,0,4),Text=finding.path:sub(-48),TextColor3=C.WHITE,TextSize=10,Font=GCOD,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd})
    lbl(row,{Size=UDim2.new(1,-210,0,12),Position=UDim2.new(0,82,0,20),Text=finding.detail,TextColor3=C.DIMTXT,TextSize=9,Font=GNRM,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd})
    local killBtn=btn(row,{Size=UDim2.new(0,50,0,24),Position=UDim2.new(1,-112,0.5,-12),BackgroundColor3=C.RED,Text="Kill",TextColor3=C.WHITE,TextSize=10,Font=GBOL}) rnd(killBtn,5)
    local blockBtn=btn(row,{Size=UDim2.new(0,54,0,24),Position=UDim2.new(1,-54,0.5,-12),BackgroundColor3=C.ORANGE,Text="Block",TextColor3=C.WHITE,TextSize=10,Font=GBOL}) rnd(blockBtn,5)
    blockBtn.Visible=finding.kind:find("Remote")~=nil
    killBtn.MouseButton1Click:Connect(function()local res=callBridge("kill",{path=finding.path}) if res.ok then row:Destroy() MalStatus.Text="Killed: "..finding.path:sub(-50) MalStatus.TextColor3=C.GREEN else MalStatus.Text="Failed: "..tostring(res.msg) MalStatus.TextColor3=C.RED end end)
    blockBtn.MouseButton1Click:Connect(function()local res=callBridge("block_remote",{path=finding.path}) MalStatus.Text=tostring(res.msg) MalStatus.TextColor3=res.ok and C.GREEN or C.RED end)
end
local function runScan()
    MalStatus.Text="Scanning..." MalStatus.TextColor3=C.YELLOW clearFindings()
    local res=callBridge("scan") if not res.ok then MalStatus.Text="Scan failed: "..tostring(res.msg) MalStatus.TextColor3=C.RED return end
    local data=res.data or {}
    if #data==0 then MalStatus.Text="Clean! No threats found." MalStatus.TextColor3=C.GREEN return end
    for i,line in data do local kind,path,detail=line:match("^(.-)|(.-)|(.*)")
        local f={kind=kind or"?",path=path or"?",detail=detail or"?"} currentFindings[i]=f addFindingRow(f,i) end
    MalStatus.Text=tostring(res.msg).." – review and kill below." MalStatus.TextColor3=C.ORANGE
end
ScanBtn.MouseButton1Click:Connect(function()task.spawn(runScan)end)
KillAllBtn.MouseButton1Click:Connect(function()MalStatus.Text="Killing..." MalStatus.TextColor3=C.YELLOW local res=callBridge("kill_all") MalStatus.Text=tostring(res.msg) MalStatus.TextColor3=res.ok and C.GREEN or C.RED if res.ok then clearFindings()end end)
BlockRmtBtn.MouseButton1Click:Connect(function()local blocked=0 for _,f in currentFindings do if f.kind:find("Remote")then local r=callBridge("block_remote",{path=f.path}) if r.ok then blocked+=1 end end end MalStatus.Text="Blocked "..blocked.." remote(s)." MalStatus.TextColor3=C.GREEN end)
AutoBtn.MouseButton1Click:Connect(function()
    autoMonOn=not autoMonOn
    if autoMonOn then tw(AutoBtn,{BackgroundColor3=C.GREEN}) AutoBtn.Text="Auto-Monitor: ON" AutoBtn.TextColor3=C.BG
        task.spawn(function()while autoMonOn do task.wait(30) if autoMonOn then task.spawn(runScan)end end end)
    else tw(AutoBtn,{BackgroundColor3=C.DIM}) AutoBtn.Text="Auto-Monitor: OFF" AutoBtn.TextColor3=C.DIMTXT autoMonOn=false end
end)
hoverHook(ScanBtn,C.BLUE,C.BLUEHOV) hoverHook(KillAllBtn,C.RED,Color3.fromRGB(255,80,80))
hoverHook(BlockRmtBtn,C.ORANGE,Color3.fromRGB(255,150,50))

-- ═══════════ TAB 4 – UNC / SUNC / MYRIAD ══════════════════
local T4=makeTabFrame()
local ExecInfoRow=Instance.new("Frame") ExecInfoRow.Size=UDim2.new(1,-20,0,26) ExecInfoRow.Position=UDim2.new(0,10,0,4) ExecInfoRow.BackgroundTransparency=1 ExecInfoRow.Parent=T4
do local l=Instance.new("UIListLayout") l.FillDirection=Enum.FillDirection.Horizontal l.VerticalAlignment=Enum.VerticalAlignment.Center l.Padding=UDim.new(0,8) l.Parent=ExecInfoRow end
local ExecNameLbl=lbl(ExecInfoRow,{Size=UDim2.new(0,210,1,0),Text="Executor: detecting...",TextColor3=C.PURPLE,TextSize=10,Font=GBOL,TextXAlignment=Enum.TextXAlignment.Left})
local SupportedLbl=lbl(ExecInfoRow,{Size=UDim2.new(0,160,1,0),Text="",TextColor3=C.DIMTXT,TextSize=9,Font=GNRM,TextXAlignment=Enum.TextXAlignment.Left})
local UNCRefreshBtn=btn(ExecInfoRow,{Size=UDim2.new(0,68,0,22),BackgroundColor3=C.ACCENT,Text="Refresh",TextColor3=C.WHITE,TextSize=10,Font=GBOL}) rnd(UNCRefreshBtn,5)
local CheckSubBar=Instance.new("Frame") CheckSubBar.Size=UDim2.new(1,-20,0,28) CheckSubBar.Position=UDim2.new(0,10,0,34) CheckSubBar.BackgroundColor3=C.PANEL CheckSubBar.BorderSizePixel=0 CheckSubBar.Parent=T4 rnd(CheckSubBar,7)
do local l=Instance.new("UIListLayout") l.FillDirection=Enum.FillDirection.Horizontal l.HorizontalAlignment=Enum.HorizontalAlignment.Center l.VerticalAlignment=Enum.VerticalAlignment.Center l.Padding=UDim.new(0,4) l.Parent=CheckSubBar end
local checkTabBtns={}
local CHECK_TABS={{"UNC (100)",UNC_LIST,C.BLUE,C.BLUEHOV},{"SUNC (100)",SUNC_LIST,C.ACCENT,C.ACCHOV},{"Myriad (250)",MYRIAD_LIST,C.ORANGE,Color3.fromRGB(255,155,55)}}
for _,ct in CHECK_TABS do
    local b=btn(CheckSubBar,{Size=UDim2.new(0,144,1,-6),BackgroundColor3=C.DIM,Text=ct[1],TextColor3=C.DIMTXT,TextSize=10,Font=GBOL}) rnd(b,5) checkTabBtns[#checkTabBtns+1]=b
end
local UNCScroll=Instance.new("ScrollingFrame")
UNCScroll.Size=UDim2.new(1,-20,0,270) UNCScroll.Position=UDim2.new(0,10,0,68)
UNCScroll.BackgroundColor3=C.PANEL UNCScroll.BorderSizePixel=0 UNCScroll.ScrollBarThickness=4
UNCScroll.ScrollBarImageColor3=C.ACCENT UNCScroll.CanvasSize=UDim2.new(0,0,0,0)
UNCScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y UNCScroll.Parent=T4
rnd(UNCScroll,7) str(UNCScroll,Color3.fromRGB(30,5,70),1)
do local l=Instance.new("UIListLayout") l.Padding=UDim.new(0,1) l.SortOrder=Enum.SortOrder.LayoutOrder l.Parent=UNCScroll
   local p=Instance.new("UIPadding") p.PaddingTop=UDim.new(0,3) p.PaddingLeft=UDim.new(0,4) p.PaddingRight=UDim.new(0,4) p.Parent=UNCScroll end
local CAT_COLORS={Closure="5,140,200",Crypt="140,50,200",Debug="180,100,0",Drawing="200,80,150",FileSystem="0,160,80",Input="160,160,0",Instance="0,120,160",Metatable="160,60,0",Misc="80,80,120",Scripts="100,0,160",Signal="0,160,120",Thread="160,100,0",HTTP="0,100,200",Cache="100,140,0",WebSocket="0,160,200",Console="60,110,60",ScriptEnv="0,110,180",ScriptState="100,60,0",ScriptLife="120,0,120",ScriptVar="0,140,100",ScriptFind="160,80,0",ScriptHier="0,80,160",ScriptID="140,0,80",ScriptMod="80,130,0",ScriptCrypt="0,100,140",ScriptSandbox="90,0,160",MyrDraw="200,80,150",MyrMem="160,40,40",MyrNet="0,110,200",MyrAnti="160,20,20",MyrSpy="140,100,0",MyrByte="60,60,180",MyrUI="0,140,120",MyrPhys="80,120,0",MyrRep="0,90,160",MyrGame="120,60,0",MyrDebug="160,80,0",MyrEvent="80,0,140",MyrExec="100,30,200",MyrLic="0,120,80",MyrInst="0,80,120"}
local function catColor(cat) local rgb=CAT_COLORS[cat] if not rgb then return C.DIM end local r,g,b=rgb:match("(%d+),(%d+),(%d+)") return Color3.fromRGB(tonumber(r),tonumber(g),tonumber(b)) end
local activeCheckTab=0
local function buildCheckList(listData,accentCol)
    for _,c in UNCScroll:GetChildren() do if c:IsA("Frame")then c:Destroy()end end
    UNCScroll.CanvasPosition=Vector2.new(0,0)
    local execName="Unknown Executor"
    if identifyexecutor then local ok,n=pcall(identifyexecutor) if ok then execName=tostring(n)end
    elseif getexecutorname then local ok,n=pcall(getexecutorname) if ok then execName=tostring(n)end end
    ExecNameLbl.Text="Executor: "..execName
    local total,supported=0,0
    for i,entry in listData do
        local name,cat=entry[1],entry[2] total+=1
        local avail=hasUNC(name) if avail then supported+=1 end
        local row=Instance.new("Frame") row.Size=UDim2.new(1,0,0,22)
        row.BackgroundColor3=avail and Color3.fromRGB(12,26,12) or Color3.fromRGB(22,10,10)
        row.BorderSizePixel=0 row.LayoutOrder=i row.Parent=UNCScroll rnd(row,4)
        lbl(row,{Size=UDim2.new(0,18,1,0),Position=UDim2.new(0,4,0,0),Text=avail and "●" or "○",TextColor3=avail and C.GREEN or Color3.fromRGB(100,30,30),TextSize=12,Font=GBOL,TextXAlignment=Enum.TextXAlignment.Center})
        local catB=btn(row,{Size=UDim2.new(0,76,0,14),Position=UDim2.new(0,24,0.5,-7),BackgroundColor3=catColor(cat),Text=cat,TextColor3=C.WHITE,TextSize=7,Font=GBOL}) rnd(catB,3) catB.AutoButtonColor=false
        lbl(row,{Size=UDim2.new(1,-175,1,0),Position=UDim2.new(0,106,0,0),Text=name,TextColor3=avail and Color3.fromRGB(185,245,185) or Color3.fromRGB(160,75,75),TextSize=10,Font=GCOD,TextXAlignment=Enum.TextXAlignment.Left})
        lbl(row,{Size=UDim2.new(0,65,1,0),Position=UDim2.new(1,-67,0,0),Text=avail and "SUPPORTED" or "MISSING",TextColor3=avail and C.GREEN or Color3.fromRGB(115,35,35),TextSize=8,Font=GBOL,TextXAlignment=Enum.TextXAlignment.Right})
    end
    local pct=total>0 and supported/total or 0
    SupportedLbl.Text="Supported: "..supported.."/"..total.."  ("..math.floor(pct*100).."%)"
    SupportedLbl.TextColor3=pct>0.7 and C.GREEN or pct>0.4 and C.YELLOW or C.RED
end
local function switchCheckTab(i)
    if activeCheckTab==i then return end activeCheckTab=i
    local ct=CHECK_TABS[i]
    for j,b in checkTabBtns do local active=(j==i) tw(b,{BackgroundColor3=active and ct[3] or C.DIM,TextColor3=active and C.WHITE or C.DIMTXT}) end
    task.spawn(buildCheckList,ct[2],ct[3])
end
for i,b in checkTabBtns do
    b.MouseEnter:Connect(function()if activeCheckTab~=i then tw(b,{BackgroundColor3=Color3.fromRGB(40,40,54)})end end)
    b.MouseLeave:Connect(function()if activeCheckTab~=i then tw(b,{BackgroundColor3=C.DIM})end end)
    b.MouseButton1Click:Connect(function()switchCheckTab(i)end)
end
UNCRefreshBtn.MouseButton1Click:Connect(function()local i=activeCheckTab>0 and activeCheckTab or 1 task.spawn(buildCheckList,CHECK_TABS[i][2],CHECK_TABS[i][3])end)
hoverHook(UNCRefreshBtn,C.ACCENT,C.ACCHOV)

-- ─── Tab switching ────────────────────────────────────────
tabFrames={T1,T2,T3,T4}
local activeTab=0
local function switchTab(i)
    if activeTab==i then return end activeTab=i
    for j,f in tabFrames do f.Visible=(j==i) end
    for j,b in tabBtns do local active=(j==i) tw(b,{BackgroundColor3=active and C.ACCENT or C.DIM,TextColor3=active and C.WHITE or C.DIMTXT}) end
    if i==4 and activeCheckTab==0 then switchCheckTab(1) end
end
for i,b in tabBtns do b.MouseButton1Click:Connect(function()switchTab(i)end) end
switchTab(1)

-- Server ping
task.spawn(function()
    local res=callBridge("ping")
    if res.ok then DotLbl.Text="● Server connected" DotLbl.TextColor3=C.GREEN
    else DotLbl.Text="● Server offline" DotLbl.TextColor3=C.RED
        setExecStatus("Server offline. Client mode only.",C.YELLOW) end
end)

-- Title bar controls
local minimised=false
MinBtn.MouseButton1Click:Connect(function()
    minimised=not minimised
    if minimised then tws(Win,{Size=UDim2.new(0,WIN_W,0,40)}) MinBtn.Text="□"
    else tws(Win,{Size=UDim2.new(0,WIN_W,0,WIN_H)}) MinBtn.Text="—" end
end)
CloseBtn.MouseButton1Click:Connect(function()
    tws(Win,{Size=UDim2.new(0,0,0,0)}) task.delay(0.25,function()SG:Destroy()end)
end)
hoverHook(MinBtn,C.DIM,Color3.fromRGB(42,42,56))
hoverHook(CloseBtn,Color3.fromRGB(195,36,52),Color3.fromRGB(230,55,72))

-- Drag (mouse + touch)
local dragging,dragStart,winStart=false,nil,nil
TBar.InputBegan:Connect(function(inp)
    local t=inp.UserInputType
    if t==Enum.UserInputType.MouseButton1 or t==Enum.UserInputType.Touch then
        dragging=true dragStart=inp.Position winStart=Win.Position
        inp.Changed:Connect(function()if inp.UserInputState==Enum.UserInputState.End then dragging=false end end)
    end
end)
UIS.InputChanged:Connect(function(inp)
    if not dragging then return end
    local t=inp.UserInputType
    if t==Enum.UserInputType.MouseMovement or t==Enum.UserInputType.Touch then
        local d=inp.Position-dragStart
        Win.Position=UDim2.new(winStart.X.Scale,winStart.X.Offset+d.X,winStart.Y.Scale,winStart.Y.Offset+d.Y)
    end
end)
UIS.InputEnded:Connect(function(inp)
    local t=inp.UserInputType
    if t==Enum.UserInputType.MouseButton1 or t==Enum.UserInputType.Touch then dragging=false end
end)
