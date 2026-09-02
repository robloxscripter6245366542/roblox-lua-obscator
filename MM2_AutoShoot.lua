--!nocheck
--[[
============================================================================
 MM2_AutoShoot.lua  —  gun auto-shoot (no silent aim), single WindUI panel
============================================================================
 Auto-shoot ONLY. No __namecall hook, no silent aim — it just fires the real
 gun remote at the player inside the FOV circle, on its own.

 How it works (from the MM2 dump)
 ---------------------------------------------------------------------------
  The sheriff/hero gun fires  GunServer.ShootStart:FireServer(hitPos)  with
  hitPos a Vector3. This fires that remote automatically at the closest
  player to the screen centre inside the FOV, at their exact part position
  (100% accuracy). No hookmetamethod needed, so it runs on any executor.

 Requires the gun equipped (sheriff/hero) for the shot to register — a client
 can't self-assign the role. Choices auto-save.
============================================================================
]]

-- ── Services ────────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")

local lp     = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ── Config + persistence ──────────────────────────────────────────────────
local CONFIG_FILE = "MM2_AutoShoot.json"
local Config = {
    Enabled        = true,      -- auto-shoot on/off
    FOV            = 150,       -- px; only players within the circle are shot
    ShowFOV        = true,
    TargetPart     = "Head",
    FireInterval   = 0.1,       -- seconds between shots (server also gates ammo/cooldown)
    PreferMurderer = true,
    SkipShield     = true,      -- skip spawn-shielded (ForceField) players
    VisibleOnly    = true,      -- wall-check: don't shoot through walls
    ShiftLock      = false,     -- lock the mouse to centre + face the camera
}
local function fsOk() return (writefile ~= nil) and (readfile ~= nil) and (isfile ~= nil) end
local saveQueued = false
local function saveConfig()
    if not fsOk() then return end
    pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(Config)) end)
end
local function queueSave()
    if saveQueued then return end
    saveQueued = true
    task.delay(0.5, function() saveQueued = false saveConfig() end)
end
pcall(function()
    if fsOk() and isfile(CONFIG_FILE) then
        local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
        if type(data) == "table" then
            for k, v in pairs(data) do if Config[k] ~= nil then Config[k] = v end end
        end
    end
end)

-- ── Helpers ────────────────────────────────────────────────────────────────
local function partOf(char)
    if not char then return nil end
    return char:FindFirstChild(Config.TargetPart)
        or char:FindFirstChild("Head")
        or char:FindFirstChild("UpperTorso")
        or char:FindFirstChild("HumanoidRootPart")
end
local function alive(char)
    local h = char and char:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end
local function shielded(char)
    return char and char:FindFirstChildOfClass("ForceField") ~= nil
end
local function isMurderer(p)
    local c = p.Character
    if not c then return false end
    for _, t in ipairs(c:GetChildren()) do
        if t:IsA("Tool") and t:FindFirstChild("KnifeServer") then return true end
    end
    return false
end
local function findGun()
    for _, container in ipairs({ lp.Character, lp:FindFirstChildOfClass("Backpack") }) do
        if container then
            for _, t in ipairs(container:GetChildren()) do
                if t:IsA("Tool") then
                    local gs = t:FindFirstChild("GunServer")
                    local sh = gs and gs:FindFirstChild("ShootStart")
                    if sh then return sh, t.Parent == lp.Character end
                end
            end
        end
    end
end
local function canSee(targetChar, worldPos)
    if not Config.VisibleOnly then return true end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { lp.Character, camera }
    local origin = camera.CFrame.Position
    local hit = workspace:Raycast(origin, (worldPos - origin), params)
    if not hit then return true end
    return hit.Instance:IsDescendantOf(targetChar)
end

-- nearest player to the screen centre (crosshair) within the FOV; prefers murderer
local function nearestToCenter()
    local center = camera.ViewportSize / 2
    local best, bestScore
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p.Character and alive(p.Character)
        and not (Config.SkipShield and shielded(p.Character)) then
            local part = partOf(p.Character)
            if part then
                local sp = camera:WorldToViewportPoint(part.Position)
                if sp.Z > 0 then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d <= Config.FOV and canSee(p.Character, part.Position) then
                        local score = d - (Config.PreferMurderer and isMurderer(p) and 1e5 or 0)
                        if not bestScore or score < bestScore then best, bestScore = p, score end
                    end
                end
            end
        end
    end
    return best
end

-- ── FOV circle (Frames — fixed at screen centre, sized by the slider) ─────
local fovFrame
pcall(function()
    local host = game:GetService("CoreGui")
    pcall(function() if gethui then host = gethui() end end)
    if not host then host = lp:WaitForChild("PlayerGui") end
    pcall(function()
        local old = host:FindFirstChild("AutoShootFOV")
        if old then old:Destroy() end
    end)

    local gui = Instance.new("ScreenGui")
    gui.Name = "AutoShootFOV"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = false
    gui.DisplayOrder = 9999
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
    gui.Parent = host

    fovFrame = Instance.new("Frame")
    fovFrame.Name = "Circle"
    fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    fovFrame.Position = UDim2.fromScale(0.5, 0.5)
    fovFrame.Size = UDim2.fromOffset(Config.FOV * 2, Config.FOV * 2)
    fovFrame.BackgroundTransparency = 1
    fovFrame.BorderSizePixel = 0
    fovFrame.Active = false
    fovFrame.Visible = false
    fovFrame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = fovFrame

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.5
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.1
    stroke.Parent = fovFrame
end)

RunService.RenderStepped:Connect(function()
    if not fovFrame then return end
    if not (Config.ShowFOV and Config.Enabled) then
        if fovFrame.Visible then fovFrame.Visible = false end
        return
    end
    fovFrame.Size    = UDim2.fromOffset(Config.FOV * 2, Config.FOV * 2)
    fovFrame.Visible = true
end)

-- ── Shift lock ─────────────────────────────────────────────────────────────
local shiftActive = false
local function setShiftLock(on)
    local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
    if on then
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        if hum then hum.AutoRotate = false end
        pcall(function() lp:SetAttribute("ShiftlockEnabled", true) end)
    else
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        if hum then hum.AutoRotate = true end
        pcall(function() lp:SetAttribute("ShiftlockEnabled", false) end)
    end
end
RunService:BindToRenderStep("AS_ShiftLock", Enum.RenderPriority.Camera.Value + 1, function()
    if not Config.ShiftLock then
        if shiftActive then setShiftLock(false) shiftActive = false end
        return
    end
    shiftActive = true
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    local char = lp.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hrp and hum then
        hum.AutoRotate = false
        local look = camera.CFrame.LookVector
        local flat = Vector3.new(look.X, 0, look.Z)
        if flat.Magnitude > 1e-4 then
            hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + flat)
        end
    end
end)
lp.CharacterAdded:Connect(function()
    task.wait(0.5)
    if not Config.ShiftLock then setShiftLock(false) end
end)

-- ── Auto-shoot loop ─────────────────────────────────────────────────────────
local lastShot = 0
RunService.Heartbeat:Connect(function()
    if not Config.Enabled then return end
    if os.clock() - lastShot < Config.FireInterval then return end
    local shoot, equipped = findGun()
    if not (shoot and equipped) then return end
    local t = nearestToCenter()
    local part = t and partOf(t.Character)
    if not part then return end
    lastShot = os.clock()
    pcall(function() shoot:FireServer(part.Position) end)   -- exact position = 100% accuracy
end)

-- ═══════════════════════════════════════════════════════════════════════
--  UI  —  single WindUI panel
-- ═══════════════════════════════════════════════════════════════════════
local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title        = "Auto Shoot",
    Icon         = "crosshair",
    Author       = "Gun",
    Folder       = "MM2_AutoShoot",
    Size         = UDim2.fromOffset(420, 300),
    Transparent  = true,
    SideBarWidth = 130,
})
pcall(function() Window:SetTransparent(true) end)

local Tab = Window:Tab({ Title = "Auto Shoot", Icon = "crosshair" })
Tab:Section({ Title = "Gun" })

Tab:Toggle({
    Title = "Auto Shoot", Desc = "Fire at the player in the circle automatically — no clicking.",
    Value = Config.Enabled,
    Callback = function(v) Config.Enabled = v queueSave() end,
})
Tab:Slider({
    Title = "Fire Rate (ms)", Desc = "Delay between shots (server also gates ammo/cooldown).",
    Value = { Min = 30, Max = 500, Default = math.floor(Config.FireInterval * 1000) },
    Step = 10, Callback = function(v) Config.FireInterval = v / 1000 queueSave() end,
})
Tab:Toggle({
    Title = "Show FOV Circle", Desc = "Draw the circle at screen centre.",
    Value = Config.ShowFOV,
    Callback = function(v) Config.ShowFOV = v queueSave() end,
})
Tab:Slider({
    Title = "FOV / Circle Size (px)", Desc = "Only players inside get shot.",
    Value = { Min = 30, Max = 1000, Default = Config.FOV },
    Step = 10, Callback = function(v) Config.FOV = v queueSave() end,
})
Tab:Dropdown({
    Title = "Target Part", Values = { "Head", "UpperTorso", "Torso", "HumanoidRootPart" },
    Value = Config.TargetPart,
    Callback = function(v) Config.TargetPart = v queueSave() end,
})
Tab:Toggle({
    Title = "Visible Only", Desc = "Never shoot players behind walls.",
    Value = Config.VisibleOnly,
    Callback = function(v) Config.VisibleOnly = v queueSave() end,
})
Tab:Toggle({
    Title = "Prefer Murderer", Desc = "Prioritise the knife holder.",
    Value = Config.PreferMurderer,
    Callback = function(v) Config.PreferMurderer = v queueSave() end,
})
Tab:Toggle({
    Title = "Skip Shielded", Desc = "Skip spawn-protected (ForceField) players.",
    Value = Config.SkipShield,
    Callback = function(v) Config.SkipShield = v queueSave() end,
})
Tab:Toggle({
    Title = "Shift Lock", Desc = "Lock the mouse to centre and face the camera.",
    Value = Config.ShiftLock,
    Callback = function(v) Config.ShiftLock = v setShiftLock(v) queueSave() end,
})

WindUI:Notify({ Title = "Auto Shoot", Icon = "check", Duration = 4,
    Content = "Loaded. Enable Auto Shoot — a target in the circle gets fired on." })
