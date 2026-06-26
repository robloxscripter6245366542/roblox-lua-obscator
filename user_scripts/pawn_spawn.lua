if not game:IsLoaded() then
	game.Loaded:Wait()
end

if game:GetService("BadgeService"):UserHasBadgeAsync(game.Players.LocalPlayer.UserId, 2125950512) then
	game:GetService("StarterGui"):SetCore("SendNotification", {
		Title = "Nice!",
		Text = "Congratulations, you got bob ;)",
		Duration = 1000,
		Icon = "rbxthumb://type=Asset&id=9649923610&w=150&h=150",
		Button1 = "OK"
	})
	fireclickdetector(game:GetService("Workspace").Lobby.bob.ClickDetector)
	return
end

local spawnCount = 5
local spawnCooldown = 5 -- seconds between each spawn

fireclickdetector(game:GetService("Workspace").Lobby.Replica.ClickDetector)
wait(.5)

for i = 1, spawnCount do
	game:GetService("ReplicatedStorage").Duplicate:FireServer(unpack({[1] = true}))
	if i < spawnCount then
		task.wait(spawnCooldown)
	end
end

wait(1.4)

--[[serverhop script by Inco]]--
local serverList = {}
for _, v in ipairs(game:GetService("HttpService"):JSONDecode(game:HttpGetAsync("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")).data) do
	if v.playing and type(v) == "table" and v.maxPlayers > v.playing and v.id ~= game.JobId then
		serverList[#serverList + 1] = v.id
	end
end
if #serverList > 0 then
	game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, serverList[math.random(1, #serverList)])
end
