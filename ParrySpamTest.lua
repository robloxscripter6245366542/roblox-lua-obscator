-- Parry Spam Test
-- Spams ParryAttempt:FireServer() as fast as possible

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local Remotes          = ReplicatedStorage:WaitForChild("Remotes", 10)
local ParryAttempt     = Remotes and Remotes:FindFirstChild("ParryAttempt")
local ParryAttemptAll  = Remotes and Remotes:FindFirstChild("ParryAttemptAll")
local ParryButtonPress = Remotes and Remotes:FindFirstChild("ParryButtonPress")

local spamming  = false
local fireCount = 0
local interval  = 0.05  -- 50ms = 20/sec

-- ParticleShine for local VFX
local cachedShine = nil
local function getShine()
    if cachedShine and cachedShine.Parent == nil then return cachedShine end
    if not getnilinstances then return nil end
    for _, o in ipairs(getnilinstances()) do
        if o.Name == "ParticleShine" then cachedShine = o; return o end
    end
end

local function fireOnce()
    local char = LocalPlayer.Character
    if not char then return end
    if ParryAttempt then
        pcall(function() ParryAttempt:FireServer() end)
    elseif ParryButtonPress then
        pcall(function() ParryButtonPress:Fire() end)
    end
    if ParryAttemptAll and type(firesignal) == "function" then
        pcall(function() firesignal(ParryAttemptAll.OnClientEvent, getShine(), char) end)
    end
    fireCount = fireCount + 1
end

-- Spam loop
local last = 0
RunService.Heartbeat:Connect(function()
    if not spamming then return end
    local now = tick()
    if now - last >= interval then
        last = now
        fireOnce()
    end
end)

-- ── GUI ──────────────────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name = "ParrySpamTest"; sg.ResetOnSpawn = false
sg.Parent = LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 130)
frame.Position = UDim2.new(0.5, -110, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(15,15,15)
frame.BorderSizePixel = 0; frame.Active = true; frame.Draggable = true
frame.Parent = sg
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,12);c.Parent=frame end

local title = Instance.new("TextLabel")
title.Size=UDim2.new(1,0,0,30); title.BackgroundTransparency=1
title.Text="⚡ PARRY SPAM TEST"; title.TextColor3=Color3.fromRGB(255,220,50)
title.Font=Enum.Font.GothamBold; title.TextSize=13; title.Parent=frame

local statusLbl = Instance.new("TextLabel")
statusLbl.Size=UDim2.new(1,-10,0,20); statusLbl.Position=UDim2.new(0,5,0,32)
statusLbl.BackgroundTransparency=1; statusLbl.Text="Idle"
statusLbl.TextColor3=Color3.fromRGB(150,150,150); statusLbl.Font=Enum.Font.Gotham
statusLbl.TextSize=11; statusLbl.Parent=frame

local counterLbl = Instance.new("TextLabel")
counterLbl.Size=UDim2.new(1,-10,0,18); counterLbl.Position=UDim2.new(0,5,0,54)
counterLbl.BackgroundTransparency=1; counterLbl.Text="Fires: 0"
counterLbl.TextColor3=Color3.fromRGB(100,100,100); counterLbl.Font=Enum.Font.Gotham
counterLbl.TextSize=10; counterLbl.Parent=frame

local btn = Instance.new("TextButton")
btn.Size=UDim2.new(1,-20,0,36); btn.Position=UDim2.new(0,10,0,82)
btn.BackgroundColor3=Color3.fromRGB(46,204,113); btn.BorderSizePixel=0
btn.Text="▶  START SPAM"; btn.TextColor3=Color3.fromRGB(255,255,255)
btn.Font=Enum.Font.GothamBold; btn.TextSize=14; btn.Parent=frame
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=btn end

btn.MouseButton1Click:Connect(function()
    spamming = not spamming
    if spamming then
        fireCount = 0
        btn.Text = "■  STOP SPAM"
        btn.BackgroundColor3 = Color3.fromRGB(231,76,60)
        statusLbl.Text = "SPAMMING at "..math.floor(1/interval).." fires/sec"
        statusLbl.TextColor3 = Color3.fromRGB(255,60,60)
    else
        btn.Text = "▶  START SPAM"
        btn.BackgroundColor3 = Color3.fromRGB(46,204,113)
        statusLbl.Text = "Stopped. Total: "..fireCount.." fires"
        statusLbl.TextColor3 = Color3.fromRGB(150,150,150)
    end
end)

-- counter updater
task.spawn(function()
    while task.wait(0.1) do
        if not sg.Parent then break end
        if spamming then
            counterLbl.Text = "Fires: "..fireCount
        end
    end
end)

print("[ParrySpamTest] ParryAttempt:" .. (ParryAttempt and "✓" or "✗")
    .. " ParryAttemptAll:" .. (ParryAttemptAll and "✓" or "✗"))
