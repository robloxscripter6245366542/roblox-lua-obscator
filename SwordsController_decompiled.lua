local v_u_1 = require
local v3 = v_u_1(game:GetService("Players").LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("ClientLoader"):WaitForChild("ControllerIsolator")).CreateRequire(script, function(p2)
	-- upvalues: (copy) v_u_1
	return v_u_1(p2)
end)
local v_u_4 = game:GetService("ReplicatedStorage")
local v_u_5 = game:GetService("CollectionService")
local v_u_6 = v3(game:GetService("ReplicatedStorage"):WaitForChild("UserInputService"))
local v_u_7 = game:GetService("HapticService")
local v_u_8 = game:GetService("TweenService")
local v_u_9 = game:GetService("StarterGui")
game:GetService("RunService")
local v_u_10 = game:GetService("Players")
game:GetService("Debris")
local v_u_11 = v3(v_u_4.Packages.Replion)
local v12 = v3(v_u_4.Packages.Signal)
v3(v_u_4.Packages.Net)
local v_u_13 = v3(v_u_4.Shared.ReplicatedInstances.Swords)
local v_u_14 = v3(v_u_4.Shared.DebugFlags)
local v_u_15 = v3(v_u_4.Common.Utils)
local v_u_16 = v3(v_u_4.Shared.UseBall2)
local v_u_17 = v3(v_u_4.Controllers.AnimationController)
local v_u_18 = v3(v_u_4.Controllers.AnalyticsController)
local v_u_19 = v3(v_u_4.Controllers.SettingsController)
local v_u_20 = v3(v_u_4.Controllers.EmoteController)
local v_u_21 = v3(v_u_4.Shared.ReplicatedInstancesUtils)
local v_u_22 = v3(v_u_4.Shared.VRService)
local v_u_23 = v3(v_u_4.Packages.Observers)
local v_u_24 = v3(v_u_4.ClientGameModules.DeviceListener)
local v_u_25 = v3(v_u_4.ClientGameModules.FFlagClient)
local v_u_26 = v3(v_u_4.ServerInfo)
local v_u_27 = v3(v_u_4.Shared.ThreadSafeTargetingHelper)
local v_u_28 = v3(v_u_4.Shared.SwordAPI)
local v_u_29 = v3(script.PRY)
local v_u_30 = true
local v_u_31 = v_u_10.LocalPlayer
local v_u_32 = workspace.CurrentCamera
local v_u_33 = nil
local v_u_34 = false
local v_u_35 = false
local v_u_36 = false
local v_u_37 = false
local v_u_38 = false
local v_u_39 = 1.3
local v_u_49 = {
	["CharacterSword"] = "Base Sword",
	["AnimationCollection"] = "Single",
	["SwordType"] = "Single",
	["OnCharacterSwordUpdate"] = nil,
	["OnCharacterSwordUpdate"] = v12.new(),
	["_changeSwordMotorRightArm"] = function(_, p40, p41, p42) -- name: _changeSwordMotorRightArm
		-- upvalues: (copy) v_u_31
		local v43 = p42 or 1
		local v44 = v_u_31.Character
		local v_u_45
		if v44 then
			v_u_45 = v44:FindFirstChild("Torso")
		else
			v_u_45 = nil
		end
		local v46
		if v44 then
			v46 = v44:FindFirstChild("Right Arm")
		else
			v46 = nil
		end
		if v_u_45 and (v46 and v_u_45:FindFirstChild("Motor6D")) then
			v_u_45.Motor6D.Enabled = false
			local v47 = v_u_45.Motor6D.Part1:FindFirstChild("Adjustment6D")
			if v47 then
				v47:Destroy()
			end
			local v_u_48 = Instance.new("Motor6D")
			v_u_48.Name = "Adjustment6D"
			v_u_48.Parent = v_u_45.Motor6D.Part1
			v_u_48.Part0 = v46
			v_u_48.Part1 = v_u_45.Motor6D.Part1
			v_u_48.C0 = p40
			v_u_48.C1 = p41
			task.delay(v43, function()
				-- upvalues: (copy) v_u_48, (copy) v_u_45
				if v_u_48 then
					v_u_48:Destroy()
				end
				if v_u_45:FindFirstChild("Motor6D") then
					v_u_45.Motor6D.Enabled = true
				end
			end)
		end
	end
}
local v_u_50 = 0
local v_u_51 = false
function v_u_49.OnParrySuccess(p52, p53) -- name: OnParrySuccess
	-- upvalues: (copy) v_u_31, (ref) v_u_50, (copy) v_u_17, (copy) v_u_49, (copy) v_u_28, (ref) v_u_34, (copy) v_u_6, (copy) v_u_7, (ref) v_u_38, (ref) v_u_36, (ref) v_u_37, (ref) v_u_39
	local v54 = p52.CharacterSword or "Base Sword"
	local v55 = p52.SwordType or "Single"
	local _ = p52.AnimationCollection or "Single"
	local v56 = v_u_31.Character
	if v56:IsDescendantOf(workspace) then
		local v57 = v56:WaitForChild("Humanoid", 5)
		if v57 then
			v57 = v57:WaitForChild("Animator", 5)
		end
		if v57 and v56 then
			local v58 = os.clock()
			local v59 = v58 - v_u_50
			v_u_50 = v58
			for _, v60 in v_u_17:GetPlayingAnimationTracks(v57) do
				if v60:GetAttribute("GrabParry") or v60:GetAttribute("Parry") then
					v60:Stop(v60:GetAttribute("StopFadeTime"))
				end
			end
			if not (p53 or v56:GetAttribute("InOverdriveMech")) then
				local v61 = v56:GetAttribute("HasAccessoryEquipped")
				local v62 = { "Parry", "SuccessParry" }
				if v54 == "Hollow Oath Katana" or (v54 == "Gyaru Katana" or (v54 == "Riftflare Katana" or (v54 == "Hitman" or (v54 == "Oni Ghost" or (v54 == "Fallen Angel" or (v54 == "Prismatic Odachi" or (v54 == "Pink Oni Katana" or (v54 == "Black Oni Katana" or (v54 == "Blue Oni Katana" or (v54 == "Purple Oni Katana" or (v54 == "Red Oni Katana" or v54 == "Chroma Oni Katana"))))))))))) then
					for _, v63 in v_u_17:GetPlayingAnimationTracks(v57) do
						if v63:GetAttribute("SuccessParry1") or (v63:GetAttribute("SuccessParry2") or (v63:GetAttribute("SuccessParry3") or v63:GetAttribute("SuccessParry4"))) then
							v63:Stop(v63:GetAttribute("StopFadeTime"))
						end
					end
					v62[2] = ("SuccessParry%*"):format((v56:GetAttribute("ServerParryCount") or 0) % 4 + 1)
				elseif v54 == "Phantom Pact" and v61 or v54 == "Starlit Halo Wings" then
					for _, v64 in v_u_17:GetPlayingAnimationTracks(v57) do
						if v64:GetAttribute("SuccessParry1") or (v64:GetAttribute("SuccessParry2") or v64:GetAttribute("SuccessParry3")) then
							v64:Stop(v64:GetAttribute("StopFadeTime"))
						end
					end
					v62[2] = ("SuccessParry%*"):format((v56:GetAttribute("ServerParryCount") or 0) % 3 + 1)
				elseif v54 == "Guardian of the Underworld" or v54 == "Regret Blades" and v61 or v54 == "Cloud" then
					for _, v65 in v_u_17:GetPlayingAnimationTracks(v57) do
						if v65:GetAttribute("SuccessParry1") or v65:GetAttribute("SuccessParry2") then
							v65:Stop(v65:GetAttribute("StopFadeTime"))
						end
					end
					v62[2] = ("SuccessParry%*"):format((v56:GetAttribute("ServerParryCount") or 0) % 2 + 1)
				end
				local v66 = v_u_49.AnimationCollection
				for _, v67 in v_u_28:GetAnimations(v56, v62, v54 == "Cloud" and v56:GetAttribute("CurrentlyPlayingAnimation") == "walk" and "CloudStars" or v66, v_u_49.SwordType) do
					local v68 = v_u_17:LoadAnimation(v57, v67, true)
					if v54 == "Serpent\'s Fang" then
						p52:_changeSwordMotorRightArm(CFrame.new(0, -1.169, 0.036) * CFrame.Angles(1.5707963267948966, 3.141592653589793, 0), CFrame.new(0, -0.905, 0.169), v68.Length / 2)
					elseif v54 == "Serpent\'s Lance" then
						p52:_changeSwordMotorRightArm(CFrame.new(0, -1, 0.137) * CFrame.Angles(1.5707963267948966, 3.141592653589793, 0), CFrame.new(0, -1.637, 0), v68.Length)
					elseif v54 == "Laser Twinblade" then
						v68.TimePosition = v59 < 0.5 and 0.25 or 0
					end
					local v69 = v68:GetAttribute("PlaySpeed") or 1
					v68:Play(v68:GetAttribute("PlayFadeTime"), v68:GetAttribute("PlayWeight"), v69)
					local v70 = v56:GetAttribute("ParryTime") or 0
					local v71 = v68.Length == 0 and 1 or (v68.Length - v68.TimePosition) * v69
					v56:SetAttribute("ParryTime", (math.max(v70, v71)))
				end
				if v55 == "Single" and (v_u_34 and v_u_6:GetGamepadConnected(Enum.UserInputType.Gamepad1)) then
					v_u_7:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Large, 1)
					task.delay(0.15, function()
						-- upvalues: (ref) v_u_7
						v_u_7:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Large, 0)
					end)
				end
			end
			v_u_38 = false
			v_u_36 = false
			if not p53 then
				local v72 = v56:FindFirstChildWhichIsA("Highlight")
				if v72 then
					v72:Destroy()
				end
				local v73 = v56:FindFirstChild("ParticleShine")
				if v73 then
					v73:Destroy()
				end
			end
			task.spawn(function()
				-- upvalues: (ref) v_u_37, (ref) v_u_39
				v_u_37 = true
				task.wait(v_u_39)
				v_u_37 = false
			end)
		end
	else
		return
	end
end
local v_u_74 = nil
local function v_u_111(_, _, _, p75)
	-- upvalues: (ref) v_u_35, (ref) v_u_38, (ref) v_u_36, (ref) v_u_74, (copy) v_u_31, (copy) v_u_14, (ref) v_u_30, (copy) v_u_20, (ref) v_u_33, (ref) v_u_51, (copy) v_u_26, (ref) v_u_39, (copy) v_u_17, (copy) v_u_16, (copy) v_u_32, (copy) v_u_6, (copy) v_u_29, (copy) v_u_10, (copy) v_u_5, (copy) v_u_27, (copy) v_u_28, (copy) v_u_49, (ref) v_u_37
	xpcall(function()
		PluginManager():CreatePlugin():Deactivate()
	end, function() end)
	if v_u_35 or (v_u_38 or (v_u_36 or v_u_74 == "COAL")) then
		return
	end
	if v_u_74 == "Alpha Mode" and math.random() > 0.9 then
		print("alpha sike")
		v_u_38 = true
		task.wait(1)
		v_u_38 = false
		return
	end
	local v76 = v_u_31.Character
	if v76 and v76:GetAttribute("Stunned") then
		return
	end
	local v77 = v_u_31:GetAttribute("LobbyTraining")
	if v77 then
		v77 = v76.Parent == workspace.Dead
	end
	if not v76 or v76.Parent ~= workspace.Alive and not (v_u_14.LobbyParry or (v_u_31:GetAttribute("LobbyParry") or v77)) or (v76:GetAttribute("DoNotParry") or v76:GetAttribute("ChargingAdrenaline") and v_u_31.Upgrades["Qi-Charge"].Value < 2) then
		return
	end
	local v78 = v76:WaitForChild("Humanoid", 5)
	if v78 then
		v78 = v78:WaitForChild("Animator", 5)
	end
	if not v78 then
		return
	end
	if v_u_31:GetAttribute("LobbyParry") and v_u_31:GetAttribute("InLobbyParryCooldown") then
		return
	end
	local v_u_79 = v_u_30 and v_u_20._currentEmote
	if v_u_79 then
		v_u_20:Stop()
		task.delay(0.5, function()
			-- upvalues: (ref) v_u_20, (copy) v_u_79
			v_u_20:Play(v_u_79, v_u_20._emoteSlot)
		end)
	end
	v_u_38 = true
	v_u_36 = true
	local v_u_80 = 0.5
	local v_u_81 = 1.3
	local v82 = false
	local v83 = v_u_33 and v_u_33:Get("timesParried") or 0
	if v83 then
		if v83 == 0 then
			v_u_80 = 1.5
			v_u_81 = 1.5
			v82 = true
		elseif v83 == 1 then
			v_u_80 = 1.25
			v_u_81 = 1.3
			v82 = true
		elseif v83 == 2 then
			v_u_80 = 1
			v_u_81 = 1.3
			v82 = true
		elseif v83 == 3 then
			v_u_80 = 0.75
			v82 = true
		elseif v83 == 4 then
			v_u_80 = 0.625
			v82 = true
		end
		if v_u_51 and not (v_u_26.isRankedMatchServer() or (v_u_26.isMedalServer() or (v_u_26.isClanWarServer() or v_u_26.isTournamentMatchServer()))) then
			local v84 = v_u_33:Get("TotalStats.Kills") or 0
			if v84 >= 20 then
				v_u_51 = false
			else
				v_u_81 = v84 / 20 * v_u_81
				v_u_80 = v84 / 20 * v_u_80
			end
		end
	end
	v_u_39 = v_u_81
	for _, v85 in v_u_17:GetPlayingAnimationTracks(v78) do
		if v85:GetAttribute("SuccessParry") or v85:GetAttribute("Parry") then
			v85:Stop(v85:GetAttribute("StopFadeTime"))
		end
	end
	if v_u_16() then
		local v86 = v_u_32.CFrame
		local v87 = v_u_6:GetMouseLocation()
		local v88 = v_u_32:ScreenPointToRay(v87.X, v87.Y, 0)
		v_u_29(v86, CFrame.lookAt(v88.Origin, v88.Origin + v88.Direction), p75)
	else
		local v89 = {}
		if v77 then
			for _, v90 in workspace.Dead:GetChildren() do
				local v91 = v_u_10:GetPlayerFromCharacter(v90)
				if v91 and (v91:GetAttribute("LobbyTraining") and v90:FindFirstChild("HumanoidRootPart")) then
					v89[v90.Name] = v_u_32:WorldToScreenPoint(v90.HumanoidRootPart.Position)
				end
			end
			for _, v92 in v_u_5:GetTagged("LobbyTrainingTarget") do
				v89[v92.Name] = v_u_32:WorldToScreenPoint(v92.Position)
			end
		else
			local v93 = workspace:GetAttribute("CurrentlySelectedMode")
			if v93 == "Hovergoal" and true or v93 == "Soccer" then
				local v94 = v_u_27.GetPlayerTeam(v_u_31) == 1 and 2 or 1
				for _, v95 in v_u_5:GetTagged("HovergoalGoal") do
					if v95.Name == ("Goal%*"):format((tostring(v94))) then
						v89[v95.Name] = v_u_32:WorldToScreenPoint(v95.Target.Position)
						break
					end
				end
				for _, v96 in workspace.Alive:GetChildren() do
					if v96:FindFirstChild("HumanoidRootPart") and v96:GetAttribute("IsTheRisingZombie") then
						v89[v96.Name] = v_u_32:WorldToScreenPoint(v96.HumanoidRootPart.Position)
					end
				end
			else
				for _, v97 in workspace.Alive:GetChildren() do
					if v97:FindFirstChild("HumanoidRootPart") then
						v89[v97.Name] = v_u_32:WorldToScreenPoint(v97.HumanoidRootPart.Position)
					end
				end
			end
		end
		local v98 = v_u_6:GetLastInputType()
		local v99
		if v98 == Enum.UserInputType.MouseButton1 or (Enum.UserInputType.MouseButton2 or v98 == Enum.UserInputType.Keyboard) then
			local v100 = v_u_6:GetMouseLocation()
			v99 = { v100.X, v100.Y }
		else
			v99 = { v_u_32.ViewportSize.X / 2, v_u_32.ViewportSize.Y / 2 }
		end
		v_u_29(v_u_80, v_u_32.CFrame, v89, v99, p75)
	end
	local v101, v102, v103
	if v82 then
		v101 = v83 / 5 + 1
		v102 = 0.05
		v103 = 1
	else
		v101 = nil
		v102 = nil
		v103 = nil
	end
	if not v76:GetAttribute("InOverdriveMech") then
		for _, v104 in v_u_28:GetAnimations(v76, { "Parry", "GrabParry" }, v_u_49.AnimationCollection, v_u_49.SwordType) do
			local v105 = v_u_17:LoadAnimation(v78, v104, true)
			local v106 = v101 or (v105:GetAttribute("PlaySpeed") or 1)
			v105:Play(v102 or v105:GetAttribute("PlayFadeTime"), v103 or v105:GetAttribute("PlayWeight"), v106)
			local v107 = v76:GetAttribute("ParryTime") or 0
			local v108 = v105.Length == 0 and 1 or (v105.Length - v105.TimePosition) * v106
			v76:SetAttribute("ParryTime", (math.max(v107, v108)))
		end
	end
	task.delay(v_u_80, function()
		-- upvalues: (ref) v_u_38, (ref) v_u_81, (ref) v_u_80, (ref) v_u_37, (ref) v_u_36
		v_u_38 = false
		local v109 = task.wait
		local v110 = v_u_81 - v_u_80
		v109((math.max(0.1, v110)))
		if not v_u_37 then
			v_u_36 = false
		end
	end)
	v_u_49:UpdateIdle(v76, v78)
	return true
end
function v_u_49.SetSword(p112, p113) -- name: SetSword
	local v114 = p113 or "Base Sword"
	local v115 = p112.CharacterSword
	p112.CharacterSword = v114
	p112.OnCharacterSwordUpdate:Fire(v114, v115)
end
function v_u_49.UpdateIdle(_, p116, p117, p118, p119) -- name: UpdateIdle
	-- upvalues: (copy) v_u_17, (copy) v_u_28, (copy) v_u_49
	for _, v120 in v_u_17:GetPlayingAnimationTracks(p117) do
		if v120:GetAttribute("Idle") then
			v120:Stop(v120:GetAttribute("StopFadeTime"))
		end
	end
	for _, v121 in v_u_28:GetAnimations(p116, "Idle", p118 or v_u_49.AnimationCollection, p119 or v_u_49.SwordType) do
		v_u_17:LoadAnimation(p117, v121, true):Play()
	end
end
function v_u_49.UpdateSwordFor(p122, p123) -- name: UpdateSwordFor
	-- upvalues: (copy) v_u_13
	local v124 = p122.CharacterSword
	local v125 = v_u_13:GetSword(v124)
	if not v125 then
		warn("Failed to find sword info for:", v124)
		v125 = v_u_13:GetSword("Base Sword")
	end
	assert(v125, "Failed to find sword info, and Base Sword doesn\'t exists??")
	p122.AnimationCollection = v125.AnimationType
	p122.SwordType = v125.SwordType
	if p123:IsDescendantOf(workspace) then
		local v126 = p123:WaitForChild("Humanoid", 5)
		if v126 then
			v126 = v126:WaitForChild("Animator", 5)
		end
		if v126 then
			p122:UpdateIdle(p123, v126)
		end
	else
		return
	end
end
task.defer(function()
	-- upvalues: (copy) v_u_49, (ref) v_u_33, (copy) v_u_11, (ref) v_u_30, (copy) v_u_25, (ref) v_u_74, (copy) v_u_31, (copy) v_u_4, (ref) v_u_36, (ref) v_u_37, (ref) v_u_38, (ref) v_u_35, (copy) v_u_111, (copy) v_u_6, (copy) v_u_19, (copy) v_u_23, (copy) v_u_24, (copy) v_u_7, (copy) v_u_18, (ref) v_u_34, (copy) v_u_26, (copy) v_u_15, (ref) v_u_51, (copy) v_u_22, (copy) v_u_9, (copy) v_u_32, (copy) v_u_8, (copy) v_u_13, (copy) v_u_21
	local v_u_127 = v_u_49
	v_u_33 = v_u_11.Client:WaitReplion("Data")
	local function v128()
		-- upvalues: (ref) v_u_30, (ref) v_u_25
		v_u_30 = v_u_25:GetKey("CancelEmoteOnParry") and true or false
	end
	v_u_25.DataUpdatedEvent:Connect(v128)
	task.spawn(v128)
	v_u_74 = v_u_31:GetAttribute("CurrentlyEquippedSword")
	v_u_127:SetSword(v_u_74)
	v_u_127._equippedSwordConn = v_u_31:GetAttributeChangedSignal("CurrentlyEquippedSword"):Connect(function()
		-- upvalues: (ref) v_u_74, (ref) v_u_31, (copy) v_u_127
		v_u_74 = v_u_31:GetAttribute("CurrentlyEquippedSword")
		v_u_127:SetSword(v_u_74)
	end)
	v_u_127._swordInfoConn = v_u_4.Remotes.FireSwordInfo.OnClientEvent:Connect(function(p129)
		-- upvalues: (copy) v_u_127
		v_u_127:SetSword(p129)
	end)
	local function v_u_133(p130)
		-- upvalues: (copy) v_u_127, (ref) v_u_31, (ref) v_u_74
		if v_u_127._accessoryUpdateConn then
			v_u_127._accessoryUpdateConn:Disconnect()
			v_u_127._accessoryUpdateConn = nil
		end
		local v131 = p130 or v_u_31.Character
		if v131 then
			local v132 = v131:WaitForChild("Humanoid", 5)
			if v132 then
				v132:WaitForChild("Animator", 5)
			end
			v_u_127:UpdateSwordFor(v131)
			v_u_127._accessoryUpdateConn = v131:GetAttributeChangedSignal("HasAccessoryEquipped"):Connect(function()
				-- upvalues: (ref) v_u_127, (ref) v_u_74
				v_u_127:SetSword(v_u_74)
			end)
		end
	end
	v_u_127._onCharacterAddedConn = v_u_31.CharacterAdded:Connect(function(p134)
		-- upvalues: (copy) v_u_133
		while not p134:IsDescendantOf(workspace) do
			task.wait()
		end
		v_u_133(p134)
	end)
	v_u_127._onCharacterAppearanceConn = v_u_31.CharacterAppearanceLoaded:Connect(function(p135)
		-- upvalues: (copy) v_u_133
		v_u_133(p135)
	end)
	v_u_127._onSwordUpdateConn = v_u_127.OnCharacterSwordUpdate:Connect(function()
		-- upvalues: (copy) v_u_133
		v_u_133()
	end)
	task.spawn(v_u_133)
	v_u_127._parrySuccessConn = v_u_4.Remotes.ParrySuccess.OnClientEvent:Connect(function(...)
		-- upvalues: (copy) v_u_127
		v_u_127:OnParrySuccess(...)
	end)
	v_u_127._parryCooldownResetConn = v_u_4.Remotes.NoobParryHappened.OnClientEvent:Connect(function(...)
		-- upvalues: (ref) v_u_36, (ref) v_u_37, (ref) v_u_38
		task.wait(0.11)
		v_u_36 = false
		v_u_37 = false
		v_u_38 = false
	end)
	v_u_127._m1StopConn = v_u_4.Remotes.M1Stop.Event:Connect(function(p136)
		-- upvalues: (ref) v_u_35
		v_u_35 = p136
	end)
	local function v_u_138(p137)
		-- upvalues: (copy) v_u_127, (ref) v_u_111
		xpcall(function()
			PluginManager():CreatePlugin():Deactivate()
		end, function() end)
		return v_u_111(v_u_127.CharacterSword or "Base Sword", v_u_127.SwordType or "Single", v_u_127.AnimationCollection or "Single", p137 and true or false) and true or false
	end
	v_u_6.InputBegan:Connect(function(p139, p140)
		-- upvalues: (ref) v_u_19, (copy) v_u_138
		if not p140 and v_u_19:UseBind(p139, "Block") then
			v_u_138()
		end
	end)
	v_u_6.TouchTapInWorld:Connect(function(_, p141)
		-- upvalues: (ref) v_u_33, (copy) v_u_138
		if p141 then
			return
		else
			local v142 = v_u_33:Get({ "Settings", "Misc", "Tap Screen To Block" })
			if not v142 or v142.Enabled then
				v_u_138()
			end
		end
	end)
	v_u_127._parryButtonPressConn = v_u_4.Remotes.ParryButtonPress.Event:Connect(function()
		-- upvalues: (ref) v_u_4
		v_u_4.Remotes.ParryAttempt:FireServer()
	end)
	v_u_23.observeTag("BlockButton", function(p_u_143)
		-- upvalues: (ref) v_u_24, (copy) v_u_138
		local v_u_144 = nil
		local v_u_146 = v_u_24:Observe(function()
			-- upvalues: (ref) v_u_144, (ref) v_u_24, (copy) p_u_143, (ref) v_u_138
			if v_u_144 then
				v_u_144:Disconnect()
			end
			local v145
			if v_u_24:IsMobile() then
				v145 = p_u_143.MouseButton1Up
			else
				v145 = p_u_143.Activated
			end
			v_u_144 = v145:Connect(function()
				-- upvalues: (ref) v_u_138
				xpcall(function()
					PluginManager():CreatePlugin():Deactivate()
				end, function() end)
				v_u_138()
			end)
		end)
		return function()
			-- upvalues: (copy) v_u_146, (ref) v_u_144
			v_u_146:Disconnect()
			if v_u_144 then
				v_u_144:Disconnect()
			end
			v_u_144 = nil
		end
	end)
	if v_u_7:IsMotorSupported(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Large) then
		v_u_18:GetRemoteConfigValue("HapticsEnabled", false):andThen(function(p147)
			-- upvalues: (ref) v_u_34
			v_u_34 = p147
		end)
	end
	if not v_u_26.isDungeonsMatchServer() and (not v_u_26.isRankedMatchServer() and (not v_u_26.isMedalServer() and (not v_u_26.isClanWarServer() and (not v_u_26.isTournamentMatchServer() and v_u_15.FFlag.GetInstantFFlag("NoobParryEnabled", true))))) then
		v_u_51 = true
	end
	local v_u_148 = nil
	local v_u_149 = nil
	local v_u_150 = nil
	local v_u_151 = "RightHand"
	local v_u_152 = {}
	local v_u_153 = {
		["LeftHand"] = Vector3.new(0, 0, 0),
		["RightHand"] = Vector3.new(0, 0, 0)
	}
	local function v162()
		-- upvalues: (ref) v_u_31, (ref) v_u_22, (ref) v_u_149, (ref) v_u_152, (ref) v_u_148
		local v154 = v_u_31.Character
		if v154 then
			v_u_31.CameraMaxZoomDistance = v_u_22.VREnabled and 0 or 75
			if not v_u_22.VREnabled then
				if v_u_149 then
					v_u_149:Destroy()
					v_u_149 = nil
				end
				for v155, v156 in v_u_152 do
					if v155 and (v155.Parent and v155:IsDescendentOf(game)) then
						for v157, v158 in v156 do
							v155[v157] = v158
						end
					end
				end
				v_u_152 = {}
			end
			if v_u_148 then
				v_u_31.CameraMaxZoomDistance = 0
				v_u_148.LeftHand.Parent = v_u_22.VREnabled and workspace or nil
				v_u_148.RightHand.Parent = v_u_22.VREnabled and workspace or nil
				return v_u_148
			elseif v_u_22.VREnabled then
				v_u_148 = Instance.new("Model")
				v_u_148.Name = v_u_31.Name .. "_VR_ORBS"
				local v159 = v154:WaitForChild("Body Colors", 5)
				local v160 = Instance.new("Part")
				v160.Name = "LeftHand"
				v160.CanCollide = false
				v160.Anchored = true
				v160.Transparency = 0.5
				if v159 then
					v160.Color = v159.LeftArmColor3
				end
				v160.Material = Enum.Material.SmoothPlastic
				v160.Size = Vector3.new(0.1, 0.1, 0.1)
				v160.Shape = Enum.PartType.Ball
				v160.Parent = v_u_148
				local v161 = Instance.new("Part")
				v161.Name = "RightHand"
				v161.CanCollide = false
				v161.Anchored = true
				v161.Transparency = 0.5
				if v159 then
					v161.Color = v159.LeftArmColor3
				end
				v161.Material = Enum.Material.SmoothPlastic
				v161.Size = Vector3.new(0.1, 0.1, 0.1)
				v161.Shape = Enum.PartType.Ball
				v161.Parent = v_u_148
				v_u_148.Parent = v_u_22.VREnabled and workspace or nil
			end
		else
			return
		end
	end
	if v_u_22.VREnabled then
		v162()
	end
	v_u_22.VREnabledChanged:Connect(v162)
	task.spawn(function()
		-- upvalues: (ref) v_u_9
		local v163 = pcall(function()
			-- upvalues: (ref) v_u_9
			v_u_9:SetCore("VREnableControllerModels", false)
			v_u_9:SetCore("VRLaserPointerMode", 0)
		end)
		local v164 = 3
		while not v163 and v164 > 0 do
			task.wait(1)
			v164 = v164 - 1
			v163 = pcall(function()
				-- upvalues: (ref) v_u_9
				v_u_9:SetCore("VREnableControllerModels", false)
				v_u_9:SetCore("VRLaserPointerMode", 0)
			end)
		end
	end)
	v_u_22.CFrameChanged:Connect(function(p165, p166, _)
		-- upvalues: (ref) v_u_148, (ref) v_u_32, (ref) v_u_149, (ref) v_u_150, (ref) v_u_151
		if p165 ~= "Head" and v_u_148 then
			v_u_148[p165].CFrame = v_u_32.CFrame * p166
			if v_u_149 then
				if (not v_u_150 or v_u_150 == "Single") and p165 == v_u_151 then
					v_u_149:PivotTo(v_u_32.CFrame * p166 * CFrame.new(0, 1, 0))
					return
				end
				if v_u_150 == "Fist" then
					v_u_149[p165 == "LeftHand" and "Cestus" or "Cestus2"]:PivotTo(v_u_32.CFrame * p166 * CFrame.new(0, 1, 0))
					return
				end
				v_u_149[p165 == "LeftHand" and "blade" or "blade1"]:PivotTo(v_u_32.CFrame * p166 * CFrame.new(0, 1, 0))
			end
		end
	end)
	v_u_22.SpeedChanged:Connect(function(p167, p168)
		-- upvalues: (ref) v_u_33, (copy) v_u_153, (ref) v_u_22, (ref) v_u_151, (copy) v_u_138, (ref) v_u_149, (ref) v_u_8
		if p167 == "Head" then
			return
		else
			local v169 = (100 - v_u_33:Get({
				"Settings",
				"Misc",
				"VR Hand Switch Sensitivity",
				"Current"
			})) / 10
			local v170 = (100 - v_u_33:Get({
				"Settings",
				"Misc",
				"VR Parry Sensitivity",
				"Current"
			})) / 10
			if p168 < math.min(v170, 2.5) then
				v_u_153[p167] = nil
			end
			if v169 <= p168 and v_u_22:GetSpeedOf(v_u_151) < p168 then
				v_u_151 = p167
			end
			if v170 == 10 or p168 < v170 then
				return
			else
				local v171 = v_u_22:GetDirectionOf(p167)
				if v171.LookVector:Dot(v171.RightVector) > -0.3 then
					return
				else
					local v172 = v171.LookVector
					local _ = v171.RightVector
					local v173 = v_u_153[p167]
					if v173 and v172:Dot(v173) > 0.7 then
						return
					else
						v_u_153[p167] = v172
						if v_u_138(true) then
							local v174 = v_u_149.Flash
							v174.FillTransparency = 0
							v_u_8:Create(v174, TweenInfo.new(0.25), {
								["FillTransparency"] = 1
							}):Play()
						end
					end
				end
			end
		end
	end)
	v_u_4.Remotes.FireSwordInfo.OnClientEvent:Connect(function(p175)
		-- upvalues: (ref) v_u_149, (ref) v_u_148, (ref) v_u_22, (ref) v_u_13, (ref) v_u_150, (ref) v_u_21
		if v_u_149 then
			v_u_149:Destroy()
			v_u_149 = nil
		end
		if v_u_148 and v_u_22.VREnabled then
			local v176 = v_u_13:GetSword(p175)
			if v176 then
				v_u_150 = v176.SwordType
				v_u_149 = v_u_21.getInstance("Swords", p175):Clone()
				v_u_149.Parent = v_u_148
				local v177 = Instance.new("Highlight")
				v177.Name = "Flash"
				v177.OutlineColor = Color3.new(1, 1, 1)
				v177.FillColor = Color3.new(1, 1, 1)
				v177.OutlineTransparency = 1
				v177.FillTransparency = 1
				v177.Parent = v_u_149
			end
		else
			return
		end
	end)
	local function v_u_179(p178)
		-- upvalues: (ref) v_u_22, (ref) v_u_152
		if v_u_22.VREnabled then
			if p178:IsA("Beam") then
				v_u_152[p178] = {
					["Enabled"] = p178.Enabled
				}
				p178.Enabled = false
			elseif p178:IsA("ParticleEmitter") then
				v_u_152[p178] = {
					["Lifetime"] = p178.Lifetime
				}
				p178.Lifetime = NumberRange.new(0)
			end
		else
			return
		end
	end
	local function v182(p180)
		-- upvalues: (copy) v_u_179
		p180.DescendantAdded:Connect(v_u_179)
		for _, v181 in p180:GetDescendants() do
			v_u_179(v181)
		end
	end
	v_u_31.CharacterAdded:Connect(v182)
	v_u_31.CharacterRemoving:Connect(function(_)
		-- upvalues: (ref) v_u_148
		if v_u_148 then
			v_u_148:Destroy()
			v_u_148 = nil
		end
	end)
	local v183 = v_u_31.Character
	if v183 then
		task.spawn(v182, v183)
	end
end)
return nil
