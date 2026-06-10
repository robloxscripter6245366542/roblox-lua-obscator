-- ================================================================
--  ChatForce_Client.lua  —  run in Delta executor (client-side)
--  Requires ChatForce_Server.lua to be running server-side first.
--
--  Usage after loading:
--    _G.say("PlayerName", "message")
--    _G.say("PlayerName", "message", "FakeDisplayName")
-- ================================================================
local RS      = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LP      = Players.LocalPlayer

-- Wait up to 10s for the server bridge
local Bridge = RS:WaitForChild("ChatForce", 10)
if not Bridge then
    warn("[ChatForce] Server bridge not found — run ChatForce_Server.lua first!")
    return
end

_G.say = function(targetName, message, fakeName)
    local ok, result = pcall(function()
        return Bridge:InvokeServer(targetName, message, fakeName)
    end)
    if ok then
        print("[ChatForce] "..tostring(result))
    else
        warn("[ChatForce] error: "..tostring(result))
    end
end

print("[ChatForce] Ready!")
print('  Usage: _G.say("PlayerName", "message")')
print('  Spoof: _G.say("PlayerName", "message", "FakeName")')
