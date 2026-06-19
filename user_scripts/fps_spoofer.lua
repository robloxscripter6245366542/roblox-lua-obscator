--[[
	FPS Spoofer for Blade Ball
	• Continuously overrides the game's own FPS counter (fpsGui > FPS)
	  so it shows a naturally-drifting spoofed value instead of the real one
	• Same drifted value is reported to the server via nya
	• Live FPS cap (setfpscap / RenderStepped fallback)
	• Draggable UI, numeric-only input, cached remotes
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local Players           = game:GetService("Players")

local player  = Players.LocalPlayer
local evtRecv = ReplicatedStorage:WaitForChild("meow")
local evtSend = ReplicatedStorage:WaitForChild("nya")

-- ── FPS cap ───────────────────────────────────────────────────────────────────

local limiterConn = nil

local function removeLimiter()
	if limiterConn then limiterConn:Disconnect(); limiterConn = nil end
end

local function applyFPSCap(fps)
	removeLimiter()
	if not fps or fps <= 0 then
		if setfpscap then setfpscap(0) end
		return
	end
	if setfpscap then
		setfpscap(fps)
		return
	end
	local interval = 1 / fps
	local last = os.clock()
	limiterConn = RunService.RenderStepped:Connect(function()
		local due = last + interval
		repeat until os.clock() >= due
		last = os.clock()
	end)
end

-- ── natural FPS walk ──────────────────────────────────────────────────────────
-- Spring-damper random walk that drifts below the cap the way real FPS does.

local fpsWalk = { v = nil, vel = 0, lastTarget = nil }

local function naturalFPS(target)
	if fpsWalk.lastTarget ~= target then
		fpsWalk.v          = target * 0.93
		fpsWalk.vel        = 0
		fpsWalk.lastTarget = target
	end
	local pullTo = target * (0.88 + math.random() * 0.08)
	local spring = (pullTo - fpsWalk.v) * 0.13
	local noise  = (math.random() - 0.48) * 4
	fpsWalk.vel  = fpsWalk.vel * 0.70 + spring + noise
	fpsWalk.v    = math.clamp(fpsWalk.v + fpsWalk.vel, target * 0.80, target - 1)
	return math.floor(fpsWalk.v)
end

local function realisticMemory()
	return math.random(358000, 524000)
end

-- ── fpsGui hook ───────────────────────────────────────────────────────────────

local fpsGuiLabel = nil

local function hookFpsGui(char)
	fpsGuiLabel = nil
	local head = char:WaitForChild("Head", 10)
	if not head then return end
	local g = head:WaitForChild("fpsGui", 10)
	if not g then return end
	fpsGuiLabel = g:WaitForChild("FPS", 5)
end

task.spawn(function()
	local char = player.Character or player.CharacterAdded:Wait()
	hookFpsGui(char)
end)
player.CharacterAdded:Connect(function(char)
	task.spawn(hookFpsGui, char)
end)

-- ── continuous spoof loop ─────────────────────────────────────────────────────
-- Runs every frame while enabled; steps the walk ~every 0.15 s so the
-- displayed value drifts naturally and overrides the game's own writes.

local spoofLoop    = nil
local currentSpoof = nil   -- shared between the loop and the meow handler
local stepAccum    = 0
local STEP_RATE    = 0.15  -- seconds between walk steps

local function startSpoofLoop()
	if spoofLoop then spoofLoop:Disconnect() end
	stepAccum    = 0
	currentSpoof = nil

	spoofLoop = RunService.Heartbeat:Connect(function(dt)
		local target = tonumber(textBox and textBox.Text) -- textBox declared below
		if not target or target < 1 then return end
		target = math.clamp(math.floor(target), 1, 50000)

		stepAccum = stepAccum + dt
		if not currentSpoof or stepAccum >= STEP_RATE then
			stepAccum    = 0
			currentSpoof = naturalFPS(target)
		end

		-- Constantly override the game's own FPS label
		if fpsGuiLabel and fpsGuiLabel.Parent then
			fpsGuiLabel.Text = tostring(currentSpoof)
		end
	end)
end

local function stopSpoofLoop()
	if spoofLoop then spoofLoop:Disconnect(); spoofLoop = nil end
	currentSpoof = nil
end

-- ── UI ────────────────────────────────────────────────────────────────────────

local gui = Instance.new("ScreenGui")
gui.Name           = "SpooferUI"
gui.ResetOnSpawn   = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent         = player.PlayerGui

local frame = Instance.new("Frame")
frame.Size             = UDim2.new(0, 200, 0, 148)
frame.Position         = UDim2.new(0.3, 0, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
frame.BorderSizePixel  = 0
frame.Parent           = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 7)

local titleBar = Instance.new("Frame")
titleBar.Size             = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
titleBar.BorderSizePixel  = 0
titleBar.Parent           = frame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 7)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size                   = UDim2.new(1, 0, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text                   = "FPS Spoofer"
titleLabel.TextColor3             = Color3.fromRGB(230, 230, 230)
titleLabel.Font                   = Enum.Font.GothamBold
titleLabel.TextSize               = 13
titleLabel.Parent                 = titleBar

local button = Instance.new("TextButton")
button.Size            = UDim2.new(0.88, 0, 0, 30)
button.Position        = UDim2.new(0.06, 0, 0, 38)
button.BorderSizePixel = 0
button.Text            = "Disabled"
button.TextColor3      = Color3.fromRGB(255, 255, 255)
button.Font            = Enum.Font.GothamBold
button.TextSize        = 13
button.Parent          = frame
Instance.new("UICorner", button).CornerRadius = UDim.new(0, 5)

local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size                   = UDim2.new(0, 40, 0, 28)
fpsLabel.Position               = UDim2.new(0.06, 0, 0, 78)
fpsLabel.BackgroundTransparency = 1
fpsLabel.Text                   = "FPS:"
fpsLabel.TextColor3             = Color3.fromRGB(180, 180, 180)
fpsLabel.Font                   = Enum.Font.Gotham
fpsLabel.TextSize               = 12
fpsLabel.TextXAlignment         = Enum.TextXAlignment.Left
fpsLabel.Parent                 = frame

local textBox = Instance.new("TextBox")
textBox.Size              = UDim2.new(0, 108, 0, 28)
textBox.Position          = UDim2.new(0, 54, 0, 78)
textBox.BackgroundColor3  = Color3.fromRGB(42, 42, 42)
textBox.PlaceholderText   = "e.g. 50000"
textBox.Text              = ""
textBox.TextColor3        = Color3.fromRGB(255, 255, 255)
textBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 110)
textBox.Font              = Enum.Font.Gotham
textBox.TextSize          = 12
textBox.ClearTextOnFocus  = false
textBox.BorderSizePixel   = 0
textBox.Parent            = frame
Instance.new("UICorner", textBox).CornerRadius = UDim.new(0, 5)

local liveLabel = Instance.new("TextLabel")
liveLabel.Size                   = UDim2.new(0.88, 0, 0, 20)
liveLabel.Position               = UDim2.new(0.06, 0, 0, 112)
liveLabel.BackgroundTransparency = 1
liveLabel.Text                   = ""
liveLabel.TextColor3             = Color3.fromRGB(140, 140, 140)
liveLabel.Font                   = Enum.Font.Gotham
liveLabel.TextSize               = 10
liveLabel.Parent                 = frame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size                   = UDim2.new(0.88, 0, 0, 18)
statusLabel.Position               = UDim2.new(0.06, 0, 1, -22)
statusLabel.BackgroundTransparency = 1
statusLabel.Text                   = ""
statusLabel.TextColor3             = Color3.fromRGB(140, 140, 140)
statusLabel.Font                   = Enum.Font.Gotham
statusLabel.TextSize               = 10
statusLabel.Parent                 = frame

-- ── drag ─────────────────────────────────────────────────────────────────────

local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true; dragStart = inp.Position; startPos = frame.Position
	end
end)
titleBar.InputChanged:Connect(function(inp)
	if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
		local d = inp.Position - dragStart
		frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
		                           startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end
end)
titleBar.InputEnded:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

-- ── state ────────────────────────────────────────────────────────────────────

local enabled = false

local function setEnabled(state)
	enabled = state
	if enabled then
		button.BackgroundColor3 = Color3.fromRGB(45, 170, 75)
		button.Text = "Enabled"
		local v = tonumber(textBox.Text)
		if v and v >= 1 then
			local capped = math.clamp(math.floor(v), 1, 50000)
			applyFPSCap(capped)
			liveLabel.Text       = "Cap active: " .. capped .. " FPS"
			liveLabel.TextColor3 = Color3.fromRGB(100, 180, 255)
		end
		startSpoofLoop()
	else
		button.BackgroundColor3 = Color3.fromRGB(190, 45, 45)
		button.Text = "Disabled"
		applyFPSCap(0)
		stopSpoofLoop()
		liveLabel.Text   = ""
		statusLabel.Text = ""
	end
end

setEnabled(false)

button.MouseButton1Click:Connect(function()
	setEnabled(not enabled)
end)

-- Update cap live as the user types
textBox:GetPropertyChangedSignal("Text"):Connect(function()
	local clean = textBox.Text:gsub("[^%d]", "")
	if clean ~= textBox.Text then textBox.Text = clean; return end
	if not enabled then return end
	local v = tonumber(clean)
	if v and v >= 1 then
		local capped = math.clamp(math.floor(v), 1, 50000)
		applyFPSCap(capped)
		liveLabel.Text       = "Cap active: " .. capped .. " FPS"
		liveLabel.TextColor3 = Color3.fromRGB(100, 180, 255)
		-- Reset walk so it re-initialises at the new target
		fpsWalk.lastTarget = nil
		currentSpoof       = nil
	else
		applyFPSCap(0)
		liveLabel.Text = ""
	end
end)

-- ── server spoofing ───────────────────────────────────────────────────────────

local GFX_POOL = {
	Enum.SavedQualitySetting.QualityLevel04,
	Enum.SavedQualitySetting.QualityLevel05,
	Enum.SavedQualitySetting.QualityLevel06,
	Enum.SavedQualitySetting.QualityLevel07,
}

evtRecv.OnClientEvent:Connect(function(data)
	if not enabled then return end

	local target = tonumber(textBox.Text)
	if not target or target < 1 then
		statusLabel.Text       = "Set a valid FPS first"
		statusLabel.TextColor3 = Color3.fromRGB(240, 90, 90)
		return
	end
	target = math.clamp(math.floor(target), 1, 50000)

	-- Use whatever the loop is already showing; fall back to a fresh step
	local spoofedFPS = currentSpoof or naturalFPS(target)
	local viewport   = workspace.CurrentCamera.ViewportSize

	evtSend:FireServer({
		token = data.token,
		fps   = spoofedFPS,
		mem   = realisticMemory(),
		t     = "metrics",
		res   = viewport,
		gfx   = GFX_POOL[math.random(1, #GFX_POOL)],
	})

	statusLabel.Text       = ("Server: %d FPS"):format(spoofedFPS)
	statusLabel.TextColor3 = Color3.fromRGB(90, 210, 110)
end)
