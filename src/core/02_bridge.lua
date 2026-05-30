-- ── Server Bridge ────────────────────────────────────────────────────────────
-- Communicates with SS_Executor.lua (server-side RemoteFunction)

local Bridge = RS:FindFirstChild("SS_ExecBridge")

-- Watch for bridge appearing/disappearing
RS.ChildAdded:Connect(function(ch)
    if ch.Name == "SS_ExecBridge" then Bridge = ch end
end)
RS.ChildRemoved:Connect(function(ch)
    if ch.Name == "SS_ExecBridge" then Bridge = nil end
end)

-- Ping — returns true if bridge is alive
local function pingBridge()
    if not Bridge then return false end
    local ok, r = pcall(function() return Bridge:InvokeServer("ping") end)
    return ok and r and r.ok == true
end

-- callBridge — invoke an action on the server
-- Returns: ok (bool), msg (string), data (table|nil)
local function callBridge(action, payload)
    if not Bridge then
        return false, "No bridge — inject SS_Executor.lua server-side first."
    end
    local ok, r = pcall(function()
        return Bridge:InvokeServer(action, payload or {})
    end)
    if not ok then return false, tostring(r), nil end
    if type(r) ~= "table" then return false, "Bridge returned invalid data.", nil end
    return r.ok == true, r.msg or "", r.data
end

-- callBridgeAsync — fire and forget (no wait)
local function callBridgeAsync(action, payload)
    task.spawn(callBridge, action, payload)
end

-- bridgeStatus — returns detailed status string
local function bridgeStatus()
    if not Bridge then return false, "SS_ExecBridge not found in ReplicatedStorage" end
    local ok, msg = callBridge("ping")
    if ok then return true, "Bridge online ✓"
    else return false, "Bridge found but not responding: " .. tostring(msg) end
end

-- runOnServer — convenience wrapper for server-side loadstring
local function runOnServer(code)
    return callBridge("ls", { code = code })
end

-- runUrlOnServer — fetch URL server-side then execute
local function runUrlOnServer(url)
    return callBridge("ls_url", { url = url })
end

-- requireOnServer — server-side require by asset ID
local function requireOnServer(id)
    return callBridge("req", { id = id })
end

-- getServerPlayers — fetch player list from server
local function getServerPlayers()
    local ok, msg, data = callBridge("getplrs")
    return ok, msg, data
end

-- getServerScripts — fetch script list from server
local function getServerScripts()
    local ok, msg, data = callBridge("get_scripts")
    return ok, msg, data
end

-- killAllScripts — kill all server LocalScripts
local function killAllScripts()
    return callBridge("kill_all")
end

-- killScript — kill a specific script by name
local function killScript(name)
    return callBridge("kill", { name = name })
end

-- blockRemote — block a specific RemoteEvent/Function
local function blockRemote(name)
    return callBridge("block_remote", { name = name })
end

-- serverScan — scan server for suspicious scripts
local function serverScan()
    return callBridge("scan")
end

-- kickPlayer — kick a player by name
local function kickPlayer(name, reason)
    return callBridge("kick", { name = name, reason = reason or "Kicked by executor." })
end
