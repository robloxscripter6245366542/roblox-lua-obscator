-- ================================================================
--  ForceChat.lua
--  Run in Delta executor (client-side).
--  Scans every game remote / script / model, wires all found vectors,
--  then exposes:
--
--    _G.forceChat(playerName, message, fakeName)
--
--  fakeName is optional — defaults to that player's DisplayName.
--  Message will appear for ALL players through every found path.
-- ================================================================

local Players  = game:GetService("Players")
local RS       = game:GetService("ReplicatedStorage")
local Chat     = game:GetService("Chat")
local LP       = Players.LocalPlayer

-- ── 1. Scan entire game for exploitable remotes ──────────────────
local CHAT_KW = {
    "chat","say","speak","voice","message","talk","text",
    "mic","send","post","submit","input","type","bubble",
}
local SUSP_KW = {
    "admin","exec","cmd","eval","kick","ban","promote","demote",
    "setrank","give","grant","money","currency","bypass","inject",
}

local function nameMatches(name, list)
    local n = name:lower()
    for _, kw in ipairs(list) do if n:find(kw) then return true end end
    return false
end

local chatRemotes    = {}   -- keyword-name match
local suspectRemotes = {}   -- suspicious-name match (may have no validation)
local seen           = {}

for _, v in game:GetDescendants() do
    if not seen[v] and v:IsA("RemoteEvent") then
        seen[v] = true
        if nameMatches(v.Name, CHAT_KW)  then table.insert(chatRemotes,    v) end
        if nameMatches(v.Name, SUSP_KW)  then table.insert(suspectRemotes, v) end
    end
end

-- ── 2. Active probe — find remotes that echo back (LIVE) ─────────
local liveRemotes = {}
local token       = "FC_"..tostring(math.random(1e5, 9e5))
local probeConns  = {}

for _, v in game:GetDescendants() do
    if v:IsA("RemoteEvent") then
        local r = v
        local ok, c = pcall(function()
            return r.OnClientEvent:Connect(function(...)
                if liveRemotes[r] then return end
                for _, arg in ipairs({...}) do
                    if type(arg)=="string" and arg:find(token,1,true) then
                        liveRemotes[r] = true
                        table.insert(liveRemotes, r)   -- ordered list
                        break
                    end
                end
            end)
        end)
        if ok then table.insert(probeConns, c) end
        -- fire probe payloads
        pcall(function() v:FireServer(token) end)
        pcall(function() v:FireServer(LP.Name, token) end)
        pcall(function() v:FireServer({Message=token}) end)
    end
end

task.wait(2.5)  -- wait for server round-trips
for _, c in ipairs(probeConns) do pcall(function() c:Disconnect() end) end

-- ── 3. Build master list (LIVE first, then chat-kw, then suspect) ─
local masterRemotes = {}
local inMaster      = {}
local function addMaster(r)
    if inMaster[r] then return end
    inMaster[r] = true
    table.insert(masterRemotes, r)
end
for _, r in ipairs(liveRemotes)    do addMaster(r) end
for _, r in ipairs(chatRemotes)    do addMaster(r) end
for _, r in ipairs(suspectRemotes) do addMaster(r) end

-- ── 4. Report ─────────────────────────────────────────────────────
print(string.format("[ForceChat] LIVE=%d  chat-kw=%d  suspect=%d  total=%d",
    #liveRemotes, #chatRemotes, #suspectRemotes, #masterRemotes))

for _, r in ipairs(liveRemotes) do
    print("  [LIVE] "..r:GetFullName())
end

-- ── 5. forceChat ─────────────────────────────────────────────────
--  Fires every found remote with 6 arg patterns + SS bridge (if online).
--  Called as: _G.forceChat("PlayerName", "hello world", "FakeName")
_G.forceChat = function(playerName, message, fakeName)
    local plr = Players:FindFirstChild(playerName)
    if not plr then
        warn("[ForceChat] player not found: "..tostring(playerName))
        return false
    end

    fakeName = (type(fakeName)=="string" and fakeName~="") and fakeName or plr.DisplayName
    local uname = plr.Name
    local char  = plr.Character

    -- a) Chat:Chat bubble (client-side, local only — still shows above head locally)
    if char then
        pcall(function() Chat:Chat(char, message, Enum.ChatColor.White) end)
    end

    -- b) Fire every found remote with all arg patterns
    local fired = 0
    for _, remote in ipairs(masterRemotes) do
        local r = remote
        pcall(function() r:FireServer(message) end)
        pcall(function() r:FireServer(fakeName, message) end)
        pcall(function() r:FireServer(uname, message) end)
        pcall(function() r:FireServer(uname, message, fakeName) end)
        pcall(function() r:FireServer(fakeName, message, uname) end)
        pcall(function() r:FireServer({Message=message, Type="Say"}) end)
        pcall(function() r:FireServer({name=fakeName, text=message}) end)
        pcall(function() r:FireServer({displayName=fakeName, message=message}) end)
        fired = fired + 1
    end

    -- c) SS bridge — server-side FireAllClients (100% visible to all if bridge is up)
    local bridge = RS:FindFirstChild("SS_ExecBridge")
    if bridge then
        local paths = {}
        for _, r in ipairs(masterRemotes) do
            table.insert(paths, r:GetFullName())
        end
        pcall(function()
            bridge:InvokeServer("chat", {
                target  = uname,
                message = message,
                display = fakeName,
                paths   = paths,
            })
        end)
        print(string.format("[ForceChat] SS bridge fired %d paths as \"%s\"", #paths, fakeName))
    end

    print(string.format("[ForceChat] Fired %d remote(s) as \"%s\" → \"%s\"",
        fired, fakeName, message))
    return true
end

print("[ForceChat] Ready.  Usage:  _G.forceChat('PlayerName', 'message', 'FakeName')")
