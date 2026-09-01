--!nocheck
--[[
============================================================================
 MM2_SilentAim.lua  —  gun Silent Aim, single-panel (WindUI)
============================================================================
 A focused, standalone script: ONLY gun silent aim, in one small WindUI
 panel. Nothing else — no farm, no ESP, no movement.

 How it works (from the MM2 dump)
 ---------------------------------------------------------------------------
  The sheriff/hero gun fires  GunServer.ShootStart:FireServer(hitPos)  where
  hitPos is a Vector3 the client normally reads from your mouse. We hook
  __namecall so, when YOU fire, that position is bent to the nearest player
  to your cursor and the camera flicks to them for the shot, then snaps back.
  A manual click always lands.

 Requires an executor with hookmetamethod (you're on Delta — supported) and
 the sheriff/hero role for the shot to register. Choices auto-save.
============================================================================
]]

-- ── Services ────────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")

local lp     = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ── Config + persistence ──────────────────────────────────────────────────
local CONFIG_FILE = "MM2_SilentAim.json"
local Config = {
    Enabled        = true,
    FOV            = 150,       -- px; nearest player to your cursor within this (also the circle size)
    ShowFOV        = true,      -- draw the FOV circle
    TargetPart     = "Head",
    PreferMurderer = true,
    SkipShield     = true,      -- never grab spawn-shielded (ForceField) players
    FlickCamera    = true,      -- flick to target for the shot, then snap back
    VisibleOnly    = true,      -- wall-check: only target players you can see
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

-- ── Target helpers ────────────────────────────────────────────────────────
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

-- nearest player to the cursor within the FOV (px); prefers the murderer
local function nearestToMouse()
    local mp = UserInputService:GetMouseLocation()
    local mouse = Vector2.new(mp.X, mp.Y)
    local best, bestScore
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p.Character and alive(p.Character)
        and not (Config.SkipShield and shielded(p.Character)) then
            local part = partOf(p.Character)
            if part then
                local sp = camera:WorldToViewportPoint(part.Position)
                if sp.Z > 0 then
                    local d = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude
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

-- ── FOV circle (Frames — follows the cursor, sized live by the slider) ─────
-- A square Frame + full UICorner = a circle; UIStroke draws the ring. It sits
-- on the cursor (targeting is measured from the cursor) and never eats clicks.
local RunService = game:GetService("RunService")
local fovFrame
pcall(function()
    local host = game:GetService("CoreGui")
    pcall(function() if gethui then host = gethui() end end)
    if not host then host = lp:WaitForChild("PlayerGui") end
    -- remove a leftover circle from a previous run so they never stack
    pcall(function()
        local old = host:FindFirstChild("SilentAimFOV")
        if old then old:Destroy() end
    end)

    local gui = Instance.new("ScreenGui")
    gui.Name = "SilentAimFOV"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true        -- align offsets with GetMouseLocation
    gui.DisplayOrder = 9999
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
    gui.Parent = host

    fovFrame = Instance.new("Frame")
    fovFrame.Name = "Circle"
    fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    fovFrame.Size = UDim2.fromOffset(Config.FOV * 2, Config.FOV * 2)
    fovFrame.BackgroundTransparency = 1
    fovFrame.BorderSizePixel = 0
    fovFrame.Active = false          -- never intercept the mouse
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
    local mp = UserInputService:GetMouseLocation()
    fovFrame.Position = UDim2.fromOffset(mp.X, mp.Y)   -- follow the cursor
    fovFrame.Size     = UDim2.fromOffset(Config.FOV * 2, Config.FOV * 2)  -- live resize
    fovFrame.Visible  = true
end)

-- ═══════════════════════════════════════════════════════════════════════
--  UI  —  single WindUI panel
-- ═══════════════════════════════════════════════════════════════════════
local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title        = "Silent Aim",
    Icon         = "crosshair",
    Author       = "Gun",
    Folder       = "MM2_SilentAim",
    Size         = UDim2.fromOffset(420, 300),
    Transparent  = true,
    SideBarWidth = 130,
})
pcall(function() Window:SetTransparent(true) end)

local Tab = Window:Tab({ Title = "Silent Aim", Icon = "crosshair" })
Tab:Section({ Title = "Gun" })

Tab:Toggle({
    Title = "Silent Aim", Desc = "Bend your own gun shots to the target near your cursor.",
    Value = Config.Enabled,
    Callback = function(v) Config.Enabled = v queueSave() end,
})
Tab:Toggle({
    Title = "Show FOV Circle", Desc = "Draw the circle on your cursor.",
    Value = Config.ShowFOV,
    Callback = function(v) Config.ShowFOV = v queueSave() end,
})
Tab:Slider({
    Title = "FOV / Circle Size (px)", Desc = "Targeting radius and the circle size.",
    Value = { Min = 30, Max = 1000, Default = Config.FOV },
    Step = 10, Callback = function(v) Config.FOV = v queueSave() end,
})
Tab:Dropdown({
    Title = "Target Part", Values = { "Head", "UpperTorso", "Torso", "HumanoidRootPart" },
    Value = Config.TargetPart,
    Callback = function(v) Config.TargetPart = v queueSave() end,
})
Tab:Toggle({
    Title = "Flick Camera", Desc = "Flick to the target for the shot, then snap back.",
    Value = Config.FlickCamera,
    Callback = function(v) Config.FlickCamera = v queueSave() end,
})
Tab:Toggle({
    Title = "Visible Only", Desc = "Never target players behind walls.",
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

-- ═══════════════════════════════════════════════════════════════════════
--  Silent-aim flick hook
-- ═══════════════════════════════════════════════════════════════════════
local hasHook = (hookmetamethod ~= nil) and (getnamecallmethod ~= nil) and (newcclosure ~= nil)
if not hasHook then
    WindUI:Notify({
        Title = "Silent Aim", Icon = "alert-triangle", Duration = 7,
        Content = "Your executor lacks hookmetamethod — Silent Aim can't run here.",
    })
else
    local fromGame = function()
        if checkcaller then return not checkcaller() end
        return true
    end
    local oldNamecall
    local function flickFire(self, pos, args)
        local restore = camera.CFrame
        if Config.FlickCamera then camera.CFrame = CFrame.new(camera.CFrame.Position, pos) end
        local res = oldNamecall(self, table.unpack(args))
        if Config.FlickCamera then camera.CFrame = restore end
        return res
    end
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local okm, method = pcall(getnamecallmethod)
        if Config.Enabled and okm and method == "FireServer"
        and typeof(self) == "Instance" and self.Name == "ShootStart" and fromGame() then
            local t = nearestToMouse()
            local part = t and partOf(t.Character)
            if part then
                local args = { ... }
                args[1] = part.Position       -- bend the reported hit position
                return flickFire(self, part.Position, args)
            end
        end
        return oldNamecall(self, ...)
    end))
    WindUI:Notify({ Title = "Silent Aim", Icon = "check", Duration = 4, Content = "Loaded. Aim near a player and fire." })
end
