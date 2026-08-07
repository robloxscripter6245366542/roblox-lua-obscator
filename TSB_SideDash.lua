-- ============================================================
--  TSB SIDE DASH  –  The Strongest Battlegrounds
--
--  What it does (that's it):
--    * Watches the closest enemy.
--    * When that enemy is within DISTANCE studs, it fires a
--      SIDE DASH (left / right) using the game's dash buttons.
--    * Alternates left and right so you keep juking.
--
--  How the "buttons" work in TSB:
--    A dash is the character's "Communicate" remote firing
--      { Dash = <direction key>, Key = Q, Goal = "KeyPress" }
--    Dash = A  -> dash LEFT    (the left side button)
--    Dash = D  -> dash RIGHT   (the right side button)
--    Key  = Q  -> the dash key itself
--
--  Toggle with the keybind below (default: G).
-- ============================================================

--============================= CONFIG =============================--
local DISTANCE   = 18            -- only side dash when an enemy is this close (studs)
local COOLDOWN   = 0.55          -- seconds between dashes (TSB dash has its own cd)
local TOGGLE_KEY = Enum.KeyCode.G
local DASH_KEY   = Enum.KeyCode.Q   -- the dash button
--=================================================================--

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local enabled  = false
local lastDash = 0
local dashLeft = true            -- flip each dash: left, right, left, ...

-- Grab the local character bits we need.
local function getSelf()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    local comm = char:FindFirstChild("Communicate")   -- the dash/input remote
    if hrp and hum and hum.Health > 0 and comm then
        return char, hrp, comm
    end
    return nil
end

-- Find the closest living enemy player and how far away they are.
local function getClosestEnemy(myHrp)
    local closest, closestDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local d = (hrp.Position - myHrp.Position).Magnitude
                if d < closestDist then
                    closest, closestDist = plr, d
                end
            end
        end
    end
    return closest, closestDist
end

-- Fire a single side dash through the dash buttons.
local function sideDash(comm)
    local dir = dashLeft and Enum.KeyCode.A or Enum.KeyCode.D  -- A = left, D = right
    comm:FireServer({
        Dash = dir,
        Key  = DASH_KEY,
        Goal = "KeyPress",
    })
    dashLeft = not dashLeft   -- alternate sides for the next one
end

-- Main loop: check distance, dash when in range.
RunService.Heartbeat:Connect(function()
    if not enabled then return end

    local _, hrp, comm = getSelf()
    if not hrp then return end

    local _, dist = getClosestEnemy(hrp)
    if dist > DISTANCE then return end            -- distance check: only dash when close

    if os.clock() - lastDash < COOLDOWN then return end
    lastDash = os.clock()

    sideDash(comm)
end)

-- Toggle on / off.
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == TOGGLE_KEY then
        enabled = not enabled
        print(("[TSB Side Dash] %s"):format(enabled and "ON" or "OFF"))
    end
end)

print("[TSB Side Dash] Loaded. Press " .. TOGGLE_KEY.Name .. " to toggle. Dashes when an enemy is within " .. DISTANCE .. " studs.")
