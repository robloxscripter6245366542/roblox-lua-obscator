-- Cam Lock — Mobile (draggable on-screen button)
--
-- A touch-friendly version of the cam lock aim-assist. Adds a clean black
-- on-screen button you can:
--   * TAP to toggle the cam lock ON/OFF (turns green when ON).
--   * DRAG anywhere on the screen to reposition it (so it never blocks your view).
--
-- Tap vs. drag is disambiguated automatically: a quick press that doesn't move
-- much counts as a tap (toggle); moving your finger past a small threshold turns
-- it into a drag (reposition) and won't toggle.
--
-- While ON: aim near a player (move your camera by dragging as usual) and the
-- camera auto-locks onto the player closest to screen center, then tracks them
-- until they die, leave, or move out of range. Camera-only — it never moves your
-- character.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ==== Config ======================================================
local CONFIG = {
	ACQUIRE_FOV = 160, -- px from screen center: must aim this close to auto-lock
	RELEASE_FOV = 750, -- px: locked target must leave this radius to release
	TARGET_PART = "HumanoidRootPart", -- or "Head" for headshots
	MAX_DISTANCE = 1000, -- studs; 0 = no limit
	SMOOTHNESS = 0.6, -- 0..1 camera easing (1 = instant snap)

	TEAM_CHECK = false, -- true = never lock teammates
	WALL_CHECK = false, -- true = skip/release when line of sight is blocked
	ALIVE_CHECK = true, -- true = never lock dead players
}
-- ==================================================================

local enabled = false
local currentTarget = nil

-- ---- Targeting logic --------------------------------------------

local function getTargetPart(player)
	local char = player.Character
	if not char then
		return nil
	end
	return char:FindFirstChild(CONFIG.TARGET_PART)
		or char:FindFirstChild("HumanoidRootPart")
		or char:FindFirstChild("Head")
		or char.PrimaryPart
end

local function isBlocked(char, targetPos)
	local origin = Camera.CFrame.Position
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { LocalPlayer.Character, char, Camera }
	params.IgnoreWater = true
	return Workspace:Raycast(origin, targetPos - origin, params) ~= nil
end

local function validate(player)
	if player == LocalPlayer then
		return nil
	end
	local char = player.Character
	if not char then
		return nil
	end
	if CONFIG.ALIVE_CHECK then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then
			return nil
		end
	end
	if CONFIG.TEAM_CHECK and LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team then
		return nil
	end
	local part = getTargetPart(player)
	if not part then
		return nil
	end
	if CONFIG.MAX_DISTANCE > 0 then
		local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		local fromPos = root and root.Position or Camera.CFrame.Position
		if (part.Position - fromPos).Magnitude > CONFIG.MAX_DISTANCE then
			return nil
		end
	end
	if CONFIG.WALL_CHECK and isBlocked(char, part.Position) then
		return nil
	end
	return part
end

local function screenDistance(part)
	local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
	if not onScreen or sp.Z <= 0 then
		return nil
	end
	local center = Camera.ViewportSize / 2
	local dx, dy = sp.X - center.X, sp.Y - center.Y
	return math.sqrt(dx * dx + dy * dy)
end

local function findAcquireTarget()
	local best, bestDist = nil, CONFIG.ACQUIRE_FOV
	for _, player in ipairs(Players:GetPlayers()) do
		local part = validate(player)
		if part then
			local d = screenDistance(part)
			if d and d <= bestDist then
				best, bestDist = player, d
			end
		end
	end
	return best
end

local function shouldKeepTarget()
	if not currentTarget or not currentTarget.Parent then
		return nil
	end
	local part = validate(currentTarget)
	if not part then
		return nil
	end
	local d = screenDistance(part)
	if not d or d > CONFIG.RELEASE_FOV then
		return nil
	end
	return part
end

-- ---- UI ----------------------------------------------------------

local COLOR_OFF = Color3.fromRGB(18, 18, 18) -- near-black
local COLOR_ON = Color3.fromRGB(38, 190, 110) -- green when active

local gui = Instance.new("ScreenGui")
gui.Name = "CamLockMobile"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
-- Prefer CoreGui/gethui so it survives resets and can't be closed by the game.
local parent = LocalPlayer:WaitForChild("PlayerGui")
pcall(function()
	if typeof(gethui) == "function" then
		parent = gethui()
	elseif game:GetService("CoreGui") then
		parent = game:GetService("CoreGui")
	end
end)
gui.Parent = parent

local button = Instance.new("TextButton")
button.Name = "Toggle"
button.Size = UDim2.fromOffset(120, 120)
button.Position = UDim2.fromScale(0.85, 0.5)
button.AnchorPoint = Vector2.new(0.5, 0.5)
button.BackgroundColor3 = COLOR_OFF
button.AutoButtonColor = false
button.Text = "CAM\nLOCK\nOFF"
button.Font = Enum.Font.GothamBold
button.TextSize = 18
button.TextColor3 = Color3.fromRGB(235, 235, 235)
button.TextWrapped = true
button.BorderSizePixel = 0
button.Active = true
button.Draggable = false -- we handle dragging manually (tap vs drag)
button.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0) -- circular button
corner.Parent = button

local stroke = Instance.new("UIStroke")
stroke.Thickness = 2
stroke.Color = Color3.fromRGB(70, 70, 70)
stroke.Transparency = 0.2
stroke.Parent = button

local function refreshVisual()
	if enabled then
		button.BackgroundColor3 = COLOR_ON
		button.Text = "CAM\nLOCK\nON"
		stroke.Color = Color3.fromRGB(120, 255, 180)
	else
		button.BackgroundColor3 = COLOR_OFF
		button.Text = "CAM\nLOCK\nOFF"
		stroke.Color = Color3.fromRGB(70, 70, 70)
		currentTarget = nil
	end
end

-- ---- Tap vs. drag handling --------------------------------------

local DRAG_THRESHOLD = 8 -- px of movement before a press becomes a drag
local dragging = false
local moved = false
local dragInput = nil
local startPos = Vector2.zero
local startBtnPos = UDim2.new()

button.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		moved = false
		dragInput = input
		startPos = input.Position
		startBtnPos = button.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input == dragInput then
		local delta = input.Position - startPos
		if delta.Magnitude > DRAG_THRESHOLD then
			moved = true
		end
		button.Position = UDim2.new(
			startBtnPos.X.Scale,
			startBtnPos.X.Offset + delta.X,
			startBtnPos.Y.Scale,
			startBtnPos.Y.Offset + delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input == dragInput then
		dragging = false
		dragInput = nil
		if not moved then
			-- A tap (no meaningful drag) toggles the lock.
			enabled = not enabled
			refreshVisual()
		end
	end
end)

-- ---- Camera lock -------------------------------------------------
--
-- Split into two rates to keep it light on mobile:
--   * Target *selection* (scanning every player, viewport-projecting each, and
--     validating) is the expensive part, so it runs on a throttle (SCAN_INTERVAL,
--     ~15x/sec) instead of every rendered frame.
--   * The camera rotation itself runs every frame off the cached target part, so
--     the aim stays perfectly smooth even though selection is throttled.

local SCAN_INTERVAL = 1 / 15 -- seconds between target (re)scans
local scanAccum = 0
local lockedPart = nil -- cached part we're currently aiming at

local function rescan()
	local part = shouldKeepTarget()
	if not part then
		currentTarget = nil
		local acquired = findAcquireTarget()
		if acquired then
			currentTarget = acquired
			part = getTargetPart(acquired)
		end
	end
	lockedPart = part
end

RunService.RenderStepped:Connect(function(dt)
	if not enabled then
		lockedPart = nil -- forget the target while off; re-acquire fresh when re-enabled
		return
	end

	scanAccum += dt
	if scanAccum >= SCAN_INTERVAL or lockedPart == nil then
		scanAccum = 0
		rescan()
	end

	-- Drop a cached part that has since been destroyed (e.g. target despawned
	-- between scans) so we don't index a stale instance.
	if lockedPart and not lockedPart.Parent then
		lockedPart = nil
		return
	end
	if not lockedPart then
		return
	end

	local goal = CFrame.new(Camera.CFrame.Position, lockedPart.Position)
	Camera.CFrame = Camera.CFrame:Lerp(goal, math.clamp(CONFIG.SMOOTHNESS, 0, 1))
end)

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	Camera = Workspace.CurrentCamera
end)

Players.PlayerRemoving:Connect(function(player)
	if player == currentTarget then
		currentTarget = nil
	end
end)

refreshVisual()
