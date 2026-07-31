-- ╔══════════════════════════════════════════════════════════════════╗
-- ║   KeyBypass  —  Universal Key System Remover                     ║
-- ║   Paste BEFORE any script that has a key gate.                   ║
-- ║   Also hooks Mana remote events discovered via Cobalt spy.       ║
-- ╚══════════════════════════════════════════════════════════════════╝

-- ═══════════════════════════════════════════════════════════════════
--  1. GETGENV BLANKET BYPASS
--     Covers every common variable name key systems check.
-- ═══════════════════════════════════════════════════════════════════
local bypassVars = {
    -- generic
    "KEY", "key", "Key",
    "SCRIPT_KEY", "ScriptKey", "scriptkey",
    "LICENSE", "License", "license",
    "LICENSE_KEY", "LicenseKey",
    "HWID", "hwid", "HwidKey",
    "TOKEN", "Token", "token",
    "WHITELIST", "whitelist",
    "AUTH", "auth", "Auth",
    "AUTHENTICATED", "authenticated",
    "VERIFIED", "verified",
    "UNLOCKED", "unlocked",
    "KEYLESS", "keyless",
    -- values that mean "no key needed"
}

local bypassValues = {
    "KEYLESS", "BYPASS", "FREE", "UNLOCKED",
    "verified", "true", "",
}

-- set common boolean flags
getgenv().KEYLESS          = true
getgenv().keyless          = true
getgenv().UNLOCKED         = true
getgenv().KEY_SYSTEM       = false
getgenv().key_system       = false
getgenv().KeySystem        = false
getgenv().HAS_KEY          = true
getgenv().has_key          = true
getgenv().AUTHENTICATED    = true
getgenv().VERIFIED         = true
getgenv().verified         = true

-- set string key vars to a generic bypass value
for _, name in ipairs(bypassVars) do
    if getgenv()[name] == nil then     -- don't overwrite already-set values
        getgenv()[name] = "KEYLESS"
    end
end

print("[KeyBypass] getgenv bypass variables set.")

-- ═══════════════════════════════════════════════════════════════════
--  2. HOOK Mana remote events
--     Discovered with Cobalt:
--       ReplicatedStorage.Signals.Mana.ModifyLocalManaEvent
--       ReplicatedStorage.Signals.Mana.ManaRemoteEvent
--
--     Any connection that checks a key value before processing
--     will be wrapped — if the handler would error or return false
--     we swallow the error and return a success-like value.
-- ═══════════════════════════════════════════════════════════════════
local RS = game:GetService("ReplicatedStorage")

local function hookEvent(event)
    if not event then return end
    local ok, conns = pcall(getconnections, event.OnClientEvent)
    if not ok or not conns then return end
    local hooked = 0
    for _, conn in ipairs(conns) do
        if conn and conn.Function then
            local old; old = hookfunction(conn.Function, newcclosure(function(...)
                local args = { ... }
                -- If the first arg looks like a key-check boolean, force it true
                if type(args[1]) == "boolean" then args[1] = true end
                -- If first arg is a string that might be a key response, keep it
                local ok2, result = pcall(old, table.unpack(args))
                if not ok2 then
                    -- swallow key-validation errors silently
                    return
                end
                return result
            end))
            hooked += 1
        end
    end
    print(("[KeyBypass] Hooked %d connection(s) on %s"):format(hooked, event.Name))
end

-- wait for the Signals.Mana folder then hook both events
task.spawn(function()
    local Signals = RS:FindFirstChild("Signals")
    if not Signals then
        -- wait up to 15 s for the folder to appear
        Signals = RS:WaitForChild("Signals", 15)
    end
    if not Signals then
        warn("[KeyBypass] ReplicatedStorage.Signals not found — skipping Mana hooks.")
        return
    end

    local Mana = Signals:FindFirstChild("Mana")
    if not Mana then
        Mana = Signals:WaitForChild("Mana", 10)
    end
    if not Mana then
        warn("[KeyBypass] Signals.Mana not found — skipping Mana hooks.")
        return
    end

    -- Hook both events found by Cobalt
    hookEvent(Mana:FindFirstChild("ModifyLocalManaEvent"))
    hookEvent(Mana:FindFirstChild("ManaRemoteEvent"))

    -- Also hook any new children added later
    Mana.ChildAdded:Connect(function(child)
        task.wait(0.1)
        if child:IsA("RemoteEvent") then
            hookEvent(child)
        end
    end)

    print("[KeyBypass] Mana event hooks installed.")
end)

-- ═══════════════════════════════════════════════════════════════════
--  3. HOOK __namecall  —  intercept FireServer / InvokeServer calls
--     that look like key-validation remotes and force a truthy reply.
-- ═══════════════════════════════════════════════════════════════════
local KEY_WORDS = {
    "key", "auth", "verify", "license", "unlock",
    "whitelist", "valid", "check", "activate",
}

local function looksLikeKeyRemote(name)
    local n = name:lower()
    for _, kw in ipairs(KEY_WORDS) do
        if n:find(kw, 1, true) then return true end
    end
    return false
end

if hookmetamethod and getrawmetatable and getnamecallmethod and newcclosure then
    local mt = getrawmetatable(game)
    if setreadonly then pcall(setreadonly, mt, false) end

    local _old; _old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()

        if (method == "InvokeServer") then
            local ok2, isRemote = pcall(function() return self:IsA("RemoteFunction") end)
            if ok2 and isRemote and looksLikeKeyRemote(self.Name) then
                -- Return a bypass value instead of hitting the server
                print(("[KeyBypass] Blocked InvokeServer on: %s"):format(self.Name))
                return true, "KEYLESS"
            end
        end

        if method == "FireServer" then
            local ok2, isRemote = pcall(function() return self:IsA("RemoteEvent") end)
            if ok2 and isRemote and looksLikeKeyRemote(self.Name) then
                print(("[KeyBypass] Blocked FireServer on: %s"):format(self.Name))
                return   -- swallow key-submission fires
            end
        end

        return _old(self, ...)
    end))

    if setreadonly then pcall(setreadonly, mt, true) end
    print("[KeyBypass] __namecall hook installed (key remote interception active).")
else
    warn("[KeyBypass] hookmetamethod unavailable — __namecall hook skipped.")
end

-- ═══════════════════════════════════════════════════════════════════
--  4. PATCH loadstring  —  strip inline key checks before execution
--     Some scripts check the key at the top of their loadstring body.
-- ═══════════════════════════════════════════════════════════════════
if loadstring then
    local _origLS = loadstring
    getgenv().loadstring = function(src, chunkname)
        if type(src) == "string" then
            -- Remove common key-gate patterns:
            --   if key ~= "XYZ" then error("invalid key") end
            --   if not (key == "XYZ") then return end
            src = src:gsub('if%s+[%w_%.]+%s*~=%s*"[^"]*"%s*then[^\n]*\n?', '')
            src = src:gsub("if%s+[%w_%.]+%s*~=%s*'[^']*'%s*then[^\n]*\n?", '')
            src = src:gsub('if%s+not%s*%([%w_%.]+%s*==%s*"[^"]*"%s*%)%s*then[^\n]*\n?', '')
        end
        return _origLS(src, chunkname)
    end
    print("[KeyBypass] loadstring patched — inline key checks stripped.")
end

print("[KeyBypass] Ready. Run your script now — key gates are bypassed.")
