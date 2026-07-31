--!strict
--[[
	Sentinel Client (LocalScript) — heartbeat + best-effort integrity self-report.
	Place under StarterPlayer > StarterPlayerScripts.

	Reality check: this runs in the untrusted client. A serious exploiter can
	delete or spoof it. Its job is only to (a) prove the client is alive so the
	server's MissingClient signal means something, and (b) voluntarily surface
	obvious exploit globals from lazy cheaters. All real enforcement is server-side.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotesFolder = ReplicatedStorage:WaitForChild("SentinelRemotes", 30)
if not remotesFolder then
	return
end
local heartbeat = remotesFolder:WaitForChild("SentinelHeartbeat", 30)
if not heartbeat or not heartbeat:IsA("RemoteEvent") then
	return
end

local HEARTBEAT_INTERVAL = 2.0

-- Names commonly injected into the global environment by exploit runtimes.
-- Presence is a *hint*, trivially hidden — never treat absence as "clean".
local SUSPECT_GLOBALS = {
	"getgenv", "getrenv", "hookfunction", "hookmetamethod",
	"getrawmetatable", "setreadonly", "islclosure", "getnamecallmethod",
	"syn", "KRNL_LOADED", "fluxus", "identifyexecutor",
}

local function selfCheck(): (boolean, string?)
	for _, name in ipairs(SUSPECT_GLOBALS) do
		if (rawget(getfenv(0), name :: any) ~= nil) or (typeof((_G :: any)[name]) ~= "nil") then
			return false, name
		end
	end
	return true, nil
end

while true do
	local ok, reason = selfCheck()
	local report = { integrity = ok, reason = reason }
	pcall(function()
		heartbeat:FireServer(report)
	end)
	task.wait(HEARTBEAT_INTERVAL)
end
