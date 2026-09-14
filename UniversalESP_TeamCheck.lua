--!nocheck
-- ============================================================================
--  Universal ESP  —  Body Outline + Smart Team Detection
-- ----------------------------------------------------------------------------
--  * Outlines every target's body using Roblox Highlight instances
--    (works on any character rig — R6, R15, custom).
--  * Team logic:
--      - If YOU are on a team  -> ESP only players NOT on your team
--        (the opposite / enemy team).
--      - If YOU are on NO team (Neutral or no team assigned)
--        -> ESP EVERYONE (except yourself).
--  * Re-evaluates targets live, so it keeps working after respawns and
--    when players switch teams mid-game.
--
--  Drop this into any executor and run. No Drawing API required.
-- ============================================================================

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- ==================== CONFIG ====================
local CONFIG = {
    Enabled          = true,
    UseTeamColor     = true,                       -- outline uses the target's TeamColor
    EnemyColor       = Color3.fromRGB(255, 60, 60), -- fallback / no-team color
    FillTransparency = 0.75,                        -- 1 = outline only, lower = more fill
    OutlineTransparency = 0,
    MaxDistance      = 0,                            -- 0 = unlimited, else studs from you
}

-- ==================== STATE ====================
local highlights = {}   -- [player] = Highlight
local running    = true

-- ==================== HELPERS ====================

-- Are we (the local player) currently teamless / neutral?
local function localHasNoTeam()
    if LocalPlayer.Neutral then return true end
    return LocalPlayer.Team == nil
end

-- Should this player be ESP'd, given our team rules?
local function isTarget(player)
    if player == LocalPlayer then return false end

    -- No team on our side -> everyone is a target.
    if localHasNoTeam() then
        return true
    end

    -- We have a team: target anyone who ISN'T our teammate.
    -- (Neutral players and players on any other team count as "opposite".)
    if player.Neutral then return true end
    return player.Team ~= LocalPlayer.Team
end

-- Colour to use for a given target's outline.
local function colorFor(player)
    if CONFIG.UseTeamColor and player.Team then
        return player.TeamColor.Color
    end
    return CONFIG.EnemyColor
end

local function withinRange(character)
    if CONFIG.MaxDistance <= 0 then return true end
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local root   = character:FindFirstChild("HumanoidRootPart")
    if not (myRoot and root) then return true end
    return (myRoot.Position - root.Position).Magnitude <= CONFIG.MaxDistance
end

local function removeHighlight(player)
    local h = highlights[player]
    if h then
        h:Destroy()
        highlights[player] = nil
    end
end

local function ensureHighlight(player)
    local character = player.Character
    if not character or not character:FindFirstChildWhichIsA("Humanoid") then
        removeHighlight(player)
        return
    end

    local h = highlights[player]
    if not h or h.Parent ~= character then
        removeHighlight(player)
        h = Instance.new("Highlight")
        h.Name = "UniversalESP"
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- see through walls
        h.Adornee = character
        h.Parent  = character
        highlights[player] = h
    end

    local col = colorFor(player)
    h.FillColor          = col
    h.OutlineColor       = col
    h.FillTransparency   = CONFIG.FillTransparency
    h.OutlineTransparency = CONFIG.OutlineTransparency
end

-- ==================== MAIN REFRESH LOOP ====================
local function refresh()
    for _, player in ipairs(Players:GetPlayers()) do
        if CONFIG.Enabled
            and isTarget(player)
            and player.Character
            and withinRange(player.Character)
        then
            ensureHighlight(player)
        else
            removeHighlight(player)
        end
    end
end

local heartbeat = RunService.Heartbeat:Connect(function()
    if not running then return end
    refresh()
end)

-- Clean up when a player leaves.
Players.PlayerRemoving:Connect(removeHighlight)

-- ==================== PUBLIC TOGGLE ====================
-- Optional global so you can flip it from the console: getgenv().UniversalESP
local api = {
    Config = CONFIG,
    Toggle = function()
        CONFIG.Enabled = not CONFIG.Enabled
        return CONFIG.Enabled
    end,
    Stop = function()
        running = false
        CONFIG.Enabled = false
        if heartbeat then heartbeat:Disconnect() end
        for player in pairs(highlights) do
            removeHighlight(player)
        end
    end,
}

if typeof(getgenv) == "function" then
    getgenv().UniversalESP = api
end

return api
