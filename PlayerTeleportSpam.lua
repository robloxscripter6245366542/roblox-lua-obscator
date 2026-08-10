--[[
============================================================================
 PlayerTeleportSpam.lua  —  Teleport-to-player + virtual-input spammer
============================================================================
 What it does
 ---------------------------------------------------------------------------
  * Locks onto ONE target player (by name, or nearest if left blank).
  * Continuously teleports your character to the target (with a small offset).
  * Fires "virtual input" (mouse click by default, or a key) on a spam loop.
  * The spam only runs while the TARGET is dead (their Humanoid.Health <= 0
    or their character is missing) — set SPAM_ONLY_WHEN_TARGET_DEAD = false
    to spam all the time instead.
  * Keeps running even after YOU die — it re-hooks on every respawn via
    Players.LocalPlayer.CharacterAdded, so the loop survives death.

 Notes
 ---------------------------------------------------------------------------
  * VirtualInputManager only works from an exploit / plugin context, not from
    an ordinary game LocalScript. This is written for that environment.
  * Everything is wrapped in pcall so a missing character / streamed-out part
    never breaks the loop.
  * Press the STOP_KEY (default: K) at any time to fully stop the script.
============================================================================
]]

-- ── Config ──────────────────────────────────────────────────────────────
local CONFIG = {
    TARGET_NAME                 = "",              -- exact/partial player name, or "" for nearest
    TELEPORT_OFFSET             = Vector3.new(0, 0, 3), -- where to stand relative to target
    FOLLOW                      = true,            -- keep teleporting to track the target
    SPAM_ONLY_WHEN_TARGET_DEAD  = true,            -- spam only while target is dead
    SPAM_INPUT                  = "MouseClick",    -- "MouseClick" or "Key"
    SPAM_KEY                    = Enum.KeyCode.E,  -- used when SPAM_INPUT == "Key"
    SPAM_INTERVAL               = 0.05,            -- seconds between spam presses (~20/s)
    STOP_KEY                    = Enum.KeyCode.K,  -- press to stop the whole script
}

-- ── Services ────────────────────────────────────────────────────────────
local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local UserInputService    = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

-- ── State ───────────────────────────────────────────────────────────────
local running     = true
local connections = {}

local function track(conn)
    connections[#connections + 1] = conn
    return conn
end

-- ── Target resolution ───────────────────────────────────────────────────
-- Returns the currently-selected target Player (or nil).
local function getTarget()
    -- 1) explicit name match (case-insensitive, partial ok)
    if CONFIG.TARGET_NAME ~= "" then
        local want = CONFIG.TARGET_NAME:lower()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                if p.Name:lower():find(want, 1, true)
                or (p.DisplayName and p.DisplayName:lower():find(want, 1, true)) then
                    return p
                end
            end
        end
        return nil
    end

    -- 2) otherwise: nearest living player to us
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local best, bestDist
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            if root then
                if myRoot then
                    local d = (root.Position - myRoot.Position).Magnitude
                    if not bestDist or d < bestDist then
                        best, bestDist = p, d
                    end
                else
                    best = best or p
                end
            end
        end
    end
    return best
end

-- Is the given player's character dead / gone?
local function isDead(player)
    local char = player and player.Character
    if not char then return true end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return true end
    return hum.Health <= 0
end

-- ── Teleport ────────────────────────────────────────────────────────────
local function teleportTo(targetPlayer)
    local myChar   = LocalPlayer.Character
    local myRoot   = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local tgtChar  = targetPlayer and targetPlayer.Character
    local tgtRoot  = tgtChar and tgtChar:FindFirstChild("HumanoidRootPart")
    if not (myRoot and tgtRoot) then return false end

    -- stand at target + offset, facing the target
    local destination = tgtRoot.CFrame * CFrame.new(CONFIG.TELEPORT_OFFSET)
    myRoot.CFrame = CFrame.new(destination.Position, tgtRoot.Position)
    return true
end

-- ── Virtual input spam ──────────────────────────────────────────────────
local function spamOnce()
    if CONFIG.SPAM_INPUT == "Key" then
        -- press + release a keyboard key
        VirtualInputManager:SendKeyEvent(true,  CONFIG.SPAM_KEY.Name, false, game)
        VirtualInputManager:SendKeyEvent(false, CONFIG.SPAM_KEY.Name, false, game)
    else
        -- left mouse click at the current cursor / screen centre
        local vp   = Camera and Camera.ViewportSize or Vector2.new(800, 600)
        local x, y = vp.X / 2, vp.Y / 2
        pcall(function()
            local mouse = LocalPlayer:GetMouse()
            if mouse then x, y = mouse.X, mouse.Y end
        end)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true,  game, 0)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
    end
end

-- ── Main loop ───────────────────────────────────────────────────────────
-- One long-lived loop. It survives our own death because it never assumes
-- our character exists — it just re-checks each iteration.
task.spawn(function()
    local lastSpam = 0
    while running do
        local ok = pcall(function()
            local target = getTarget()
            if target then
                if CONFIG.FOLLOW then
                    teleportTo(target)
                end

                local shouldSpam = (not CONFIG.SPAM_ONLY_WHEN_TARGET_DEAD)
                                   or isDead(target)

                if shouldSpam then
                    local now = os.clock()
                    if now - lastSpam >= CONFIG.SPAM_INTERVAL then
                        spamOnce()
                        lastSpam = now
                    end
                end
            end
        end)
        if not ok then
            -- swallow errors (character streamed out, respawning, etc.)
        end
        RunService.Heartbeat:Wait()
    end
end)

-- ── Respawn handling (keep going even if YOU die) ────────────────────────
-- The loop above is character-agnostic, but we re-affirm on respawn so a
-- fresh character is picked up immediately without waiting a frame.
track(LocalPlayer.CharacterAdded:Connect(function(char)
    -- give the new character its root part before the loop uses it
    char:WaitForChild("HumanoidRootPart", 10)
end))

-- ── Stop key ────────────────────────────────────────────────────────────
track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == CONFIG.STOP_KEY then
        running = false
        for _, conn in ipairs(connections) do
            pcall(function() conn:Disconnect() end)
        end
        warn("[PlayerTeleportSpam] stopped.")
    end
end))

warn(("[PlayerTeleportSpam] running — target=%s  spam=%s  stopKey=%s")
    :format(
        CONFIG.TARGET_NAME ~= "" and CONFIG.TARGET_NAME or "<nearest>",
        CONFIG.SPAM_INPUT,
        CONFIG.STOP_KEY.Name
    ))
