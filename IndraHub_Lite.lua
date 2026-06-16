local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local VirtualInputManager = nil
pcall(function()
    VirtualInputManager = game:GetService("VirtualInputManager")
end)

local player = Players.LocalPlayer
local running = true
local sessionId = {}

_G.IndraHubLiteRunning = true
_G.IndraHubLiteSession = sessionId

local autoTeleport = false
local autoSkills = {}
local selectedAutoSkills = { Z = true }
local nativeAutoSkill = nil
local safePotato = false
local potatoQueue = {}
local queuedPotato = setmetatable({}, { __mode = "k" })

local autoTeleportDelay = 0.8
local autoSkillDelay = 0.7
local skillRange = 35
local hoverDistance = 4
local hoverHeight = -7
local moveMode = "Teleport"
local tweenSpeed = 120
local currentTween = nil
local currentTarget = nil
local targetInstanceIndex = 1
local lastNativeRefresh = 0
local lastHeartbeat = os.clock()
local enemyScanCache = {}
local lastEnemyScan = 0
local enemyScanInterval = 1.25
local maxPotatoQueue = 2500

local skillKeys = { "Z", "X", "C", "V", "R" }
local skillPriority = { "R", "V", "C", "Z", "X" }
local skillSlots = { Z = 1, X = 2, C = 3, V = 4, R = 5 }
local skillKeyCodes = {
    Z = Enum.KeyCode.Z,
    X = Enum.KeyCode.X,
    C = Enum.KeyCode.C,
    V = Enum.KeyCode.V,
    R = Enum.KeyCode.R,
}

local enemyNames = {
    "[Lv.10] Sailor",
    "[Lv.150] NameLess Hero",
    "[Lv.750] Moraros",
    "[Lv.1000] Flame Minion",
    "[Lv.2500] Magador",
    "[Lv.4000] Frost Minion",
    "[Lv.6000] Velik",
    "[Lv.8500] Nivaron",
    "[Lv.13000] Frost Soldier",
    "[Lv.13000] Thunder Soldier",
    "[Lv.3000] Black Swordsman",
    "[Lv.15000] Hraegon",
    "[Lv.15000] Niflor",
    "[Lv.15000] Struggler",
    "[Lv.15000] Surtrik",
    "[Lv.15000] Thorvak",
    "[Lv.15000] Space Invader",
    "[Nightmare] Mad Dog",
    "[Nightmare]Headless Knight",
    "[Lv.???]Dummy",
    "[Lv.???] Gelaros",
}
local selectedEnemies = {}

local function dumpError(tag, err)
    warn("[IndraHubLite] " .. tostring(tag) .. ": " .. tostring(err))
end

local function getChildPath(root, path)
    local current = root
    for _, name in ipairs(path) do
        if not current then return nil end
        current = current:FindFirstChild(name)
    end
    return current
end

local executorName = ""
pcall(function()
    if type(identifyexecutor) == "function" then executorName = tostring(identifyexecutor()) end
end)
local isXeno = string.find(string.lower(executorName), "xeno", 1, true) ~= nil
local isVelocity = string.find(string.lower(executorName), "velocity", 1, true) ~= nil
local isDelta = string.find(string.lower(executorName), "delta", 1, true) ~= nil
local isFragileExecutor = isVelocity or isDelta
if isFragileExecutor then
    autoTeleportDelay = 1.5
    autoSkillDelay = 1.2
    enemyScanInterval = 2.25
    maxPotatoQueue = 1200
    moveMode = "Teleport"
end

local oldRequire = require
local function findTableByKeys(keys)
    if isXeno or isFragileExecutor or type(getgc) ~= "function" then return nil end
    local ok, objects = pcall(getgc, true)
    if not ok or type(objects) ~= "table" then return nil end
    for _, value in ipairs(objects) do
        if type(value) == "table" then
            local matched = true
            for _, key in ipairs(keys) do
                local gotOk, got = pcall(function() return rawget(value, key) end)
                if not gotOk or got == nil then
                    matched = false
                    break
                end
            end
            if matched then return value end
        end
    end
    return nil
end

local function safeRequire(module)
    if typeof(module) ~= "Instance" or not module:IsA("ModuleScript") then return {} end
    local found = nil
    if module.Name == "Controller" then
        found = findTableByKeys({ "StopAutoSkill", "GetCombatSlotActionIds", "RequestDrawWeapon" })
    end
    if found then return found end

    local getidentity = getthreadidentity or getidentity or getthreadcontext or (syn and syn.get_thread_identity)
    local setidentity = setthreadidentity or setidentity or setthreadcontext or (syn and syn.set_thread_identity)
    if not isXeno and type(getidentity) == "function" and type(setidentity) == "function" then
        local old = getidentity()
        if pcall(setidentity, 2) then
            local ok, result = pcall(oldRequire, module)
            pcall(setidentity, old)
            if ok then return result end
        end
    end

    local ok, result = pcall(oldRequire, module)
    if ok then return result end
    dumpError("require", result)
    return {}
end

local Player3CController = safeRequire(getChildPath(ReplicatedStorage, { "Client", "System", "Player3C", "Internal", "Controller" }))

local function fetchAndCache(url, cacheName)
    if type(readfile) == "function" then
        local ok, cached = pcall(readfile, cacheName)
        if ok and type(cached) == "string" and #cached > 1000 then return cached end
    end
    local okFetch, source = pcall(function() return game:HttpGet(url) end)
    if not okFetch or type(source) ~= "string" then error("Failed to fetch " .. tostring(url)) end
    if type(writefile) == "function" then
        pcall(writefile, cacheName, source)
    end
    return source
end

local function loadWindUI()
    local source = fetchAndCache("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua", "IndraHub_WindUI_Cache.lua")
    return loadstring(source)()
end

local okWindUI, WindUI = pcall(loadWindUI)
if not okWindUI or type(WindUI) ~= "table" then
    _G.IndraHubLiteError = "WINDUI FAIL"
    warn("[IndraHubLite] WindUI failed: " .. tostring(WindUI))
    return
end


local function isSessionActive()
    return running and _G.IndraHubLiteRunning and _G.IndraHubLiteSession == sessionId
end

local function notify(title, content, icon)
    pcall(function()
        WindUI:Notify({ Title = title, Content = content, Icon = icon or "info", Duration = 2 })
    end)
end

local function safeWait(seconds)
    task.wait(math.max(tonumber(seconds) or 0, isFragileExecutor and 0.08 or 0.03))
end

local function markHeartbeat()
    lastHeartbeat = os.clock()
    _G.IndraHubLiteLastHeartbeat = lastHeartbeat
end

local function getRoot()
    local character = player.Character
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso") or character.PrimaryPart
end

local function getEnemyRoot(enemy)
    return enemy and (enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Torso") or enemy:FindFirstChild("UpperTorso") or enemy.PrimaryPart)
end

local function getEnemyHealth(enemy)
    local humanoid = enemy and (enemy:FindFirstChildOfClass("Humanoid") or enemy:FindFirstChild("Humanoid", true))
    if humanoid then return humanoid.Health end
    for _, name in ipairs({ "Health", "HP", "Hp", "Life", "CurrentHealth", "CurrentHP" }) do
        local attr = enemy and enemy:GetAttribute(name)
        if tonumber(attr) then return tonumber(attr) end
        local child = enemy and enemy:FindFirstChild(name, true)
        if child and (child:IsA("NumberValue") or child:IsA("IntValue")) then return tonumber(child.Value) end
    end
    return nil
end

local function isEnemyAlive(enemy)
    if not enemy or not enemy.Parent then return false end
    if not enemy:IsA("Model") then return false end
    if not selectedEnemies[enemy.Name] then return false end
    if not getEnemyRoot(enemy) then return false end
    local humanoid = enemy:FindFirstChildOfClass("Humanoid") or enemy:FindFirstChild("Humanoid", true)
    if not humanoid or humanoid:GetState() == Enum.HumanoidStateType.Dead then return false end
    local health = getEnemyHealth(enemy)
    return health == nil or health > 0.05
end

local function moveCharacterByParts(targetCFrame)
    local character = player.Character
    local root = getRoot()
    if not character or not root then return false end
    local offset = targetCFrame.Position - root.Position
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                part.AssemblyLinearVelocity = Vector3.zero
                part.AssemblyAngularVelocity = Vector3.zero
                part.CFrame = part == root and targetCFrame or part.CFrame + offset
            end)
        end
    end
    return true
end

local function moveToCFrame(root, targetCFrame)
    if currentTween then pcall(function() currentTween:Cancel() end) currentTween = nil end
    if moveMode == "Tween" then
        local distance = (root.Position - targetCFrame.Position).Magnitude
        currentTween = TweenService:Create(root, TweenInfo.new(math.clamp(distance / tweenSpeed, 0.15, 3), Enum.EasingStyle.Linear), { CFrame = targetCFrame })
        currentTween:Play()
    elseif moveMode == "Part Teleport" then
        moveCharacterByParts(targetCFrame)
    else
        root.CFrame = targetCFrame
    end
end

local function getSelectedEnemyInstances()
    if os.clock() - lastEnemyScan < enemyScanInterval then
        return enemyScanCache
    end

    local result = {}
    local folder = workspace:FindFirstChild("EnemyService")
    if not folder then
        enemyScanCache = result
        lastEnemyScan = os.clock()
        return result
    end

    for _, enemy in ipairs(folder:GetDescendants()) do
        if selectedEnemies[enemy.Name] and isEnemyAlive(enemy) then table.insert(result, enemy) end
    end
    table.sort(result, function(a, b) return a.Name == b.Name and tostring(a) < tostring(b) or a.Name < b.Name end)
    enemyScanCache = result
    lastEnemyScan = os.clock()
    return result
end

local function teleportSelected()
    if currentTarget and isEnemyAlive(currentTarget) then return true end
    currentTarget = nil
    local root = getRoot()
    if not root then return false end

    local instances = getSelectedEnemyInstances()
    if #instances == 0 then return false end
    if targetInstanceIndex > #instances then targetInstanceIndex = 1 end

    for i = 1, #instances do
        local index = ((targetInstanceIndex + i - 2) % #instances) + 1
        local enemy = instances[index]
        local enemyRoot = getEnemyRoot(enemy)
        if enemyRoot and isEnemyAlive(enemy) then
            currentTarget = enemy
            targetInstanceIndex = index + 1
            moveToCFrame(root, enemyRoot.CFrame * CFrame.new(0, hoverHeight, hoverDistance))
            return true
        end
    end
    return false
end

local function hoverBehindSelected()
    local root = getRoot()
    if not root then return false end
    if not isEnemyAlive(currentTarget) then currentTarget = nil return false end
    local enemyRoot = getEnemyRoot(currentTarget)
    local targetCFrame = enemyRoot.CFrame * CFrame.new(0, hoverHeight, hoverDistance)
    moveToCFrame(root, CFrame.lookAt(targetCFrame.Position, enemyRoot.Position))
    root.AssemblyLinearVelocity = Vector3.zero
    return true
end

local function getSlotActionId(slot)
    if type(Player3CController.GetCombatSlotActionIds) ~= "function" then return nil end
    local ok, actionIds = pcall(Player3CController.GetCombatSlotActionIds)
    if ok and type(actionIds) == "table" then return actionIds[slot] or actionIds["Skill" .. tostring(slot)] end
    return nil
end

local function isSkillReady(skillKey)
    local slot = skillSlots[skillKey]
    local actionId = slot and getSlotActionId(slot)
    if type(actionId) ~= "string" or actionId == "" or type(Player3CController.GetAbilityCooldown) ~= "function" then return true end
    local ok, cooldown = pcall(Player3CController.GetAbilityCooldown, actionId)
    return not ok or type(cooldown) ~= "table" or tonumber(cooldown.remaining) == nil or cooldown.remaining <= 0
end

local function setControllerAutoSkill(skillKey, enabled)
    local slot = skillSlots[skillKey]
    if not slot then return false end
    if not enabled then
        return pcall(function()
            if type(Player3CController.StopAutoSkill) == "function" then Player3CController.StopAutoSkill() end
        end)
    end
    local ok, result = pcall(function()
        if type(Player3CController.IsDrawn) == "function" and not Player3CController.IsDrawn() and type(Player3CController.RequestDrawWeapon) == "function" then
            Player3CController.RequestDrawWeapon()
            task.wait(0.2)
        end
        local actionName = "Skill" .. tostring(slot)
        local actionId = getSlotActionId(slot)
        if type(actionId) == "string" and actionId ~= "" and type(Player3CController.SetAutoMappedAction) == "function" then
            return Player3CController.SetAutoMappedAction(actionName, actionId)
        end
        if type(Player3CController.ToggleAutoMappedAction) == "function" then return Player3CController.ToggleAutoMappedAction(actionName) end
        return false
    end)
    return ok and result == true
end

local function hasControllerAutoSkill()
    return type(Player3CController.SetAutoMappedAction) == "function" or type(Player3CController.ToggleAutoMappedAction) == "function" or type(Player3CController.ActivateMappedAction) == "function"
end

local function rebuildNativeAutoSkill()
    nativeAutoSkill = nil
    pcall(function()
        if type(Player3CController.StopAutoSkill) == "function" then Player3CController.StopAutoSkill() end
    end)
    if isXeno then return end
    for _, skillKey in ipairs(skillKeys) do
        if autoSkills[skillKey] then
            nativeAutoSkill = skillKey
            setControllerAutoSkill(skillKey, true)
            return
        end
    end
end

local function hasSelectedEnemyInRange()
    local root = getRoot()
    local enemyRoot = getEnemyRoot(currentTarget)
    return root and enemyRoot and isEnemyAlive(currentTarget) and (root.Position - enemyRoot.Position).Magnitude <= skillRange
end

local function useSkill(skillKey)
    local slot = skillSlots[skillKey]
    if not slot then return false end
    if not isXeno then
        local ok, used = pcall(function()
            if type(Player3CController.IsDrawn) == "function" and not Player3CController.IsDrawn() and type(Player3CController.RequestDrawWeapon) == "function" then
                Player3CController.RequestDrawWeapon()
                task.wait(0.2)
            end
            if type(Player3CController.ActivateMappedAction) ~= "function" then return false end
            local actionName = "Skill" .. tostring(slot)
            Player3CController.ActivateMappedAction(actionName)
            task.wait(0.08)
            if type(Player3CController.ReleaseMappedAction) == "function" then Player3CController.ReleaseMappedAction(actionName) end
            return true
        end)
        if ok and used then return true end
    end

    local keyCode = skillKeyCodes[skillKey]
    if VirtualInputManager and keyCode then
        return pcall(function()
            VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
            task.wait(0.08)
            VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
        end)
    end
    return false
end

local function cacheProperty(instance, property)
end

local function setCachedProperty(instance, property, value)
    pcall(function() instance[property] = value end)
end

local function shouldUltraPotatoTouch(instance)
    return instance:IsA("Decal")
        or instance:IsA("Texture")
        or instance:IsA("ParticleEmitter")
        or instance:IsA("Trail")
        or instance:IsA("Beam")
        or instance:IsA("Fire")
        or instance:IsA("Smoke")
        or instance:IsA("Sparkles")
        or instance:IsA("PointLight")
        or instance:IsA("SpotLight")
        or instance:IsA("SurfaceLight")
        or instance:IsA("PostEffect")
        or instance:IsA("Sound")
        or instance:IsA("BillboardGui")
        or instance:IsA("SurfaceGui")
end

local function applySafePotatoTo(instance)
    if instance:IsA("Decal") or instance:IsA("Texture") then
        setCachedProperty(instance, "Transparency", 1)
    elseif instance:IsA("ParticleEmitter") or instance:IsA("Trail") or instance:IsA("Beam") or instance:IsA("Fire") or instance:IsA("Smoke") or instance:IsA("Sparkles") then
        setCachedProperty(instance, "Enabled", false)
    elseif instance:IsA("PointLight") or instance:IsA("SpotLight") or instance:IsA("SurfaceLight") or instance:IsA("PostEffect") then
        setCachedProperty(instance, "Enabled", false)
    elseif instance:IsA("Sound") then
        setCachedProperty(instance, "Volume", 0)
    elseif instance:IsA("BillboardGui") or instance:IsA("SurfaceGui") then
        setCachedProperty(instance, "Enabled", false)
    end
end

local function setSafePotato(enabled)
    safePotato = enabled
    if enabled then
        setCachedProperty(Lighting, "GlobalShadows", false)
        setCachedProperty(Lighting, "Brightness", 1)
        setCachedProperty(Lighting, "EnvironmentDiffuseScale", 0)
        setCachedProperty(Lighting, "EnvironmentSpecularScale", 0)
        setCachedProperty(Lighting, "FogEnd", 100000)
        pcall(function()
            local rendering = settings().Rendering
            rendering.QualityLevel = Enum.QualityLevel.Level01
            rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
            if type(setfpscap) == "function" then setfpscap(60) end
        end)
        potatoQueue = {}
        queuedPotato = setmetatable({}, { __mode = "k" })
        for _, item in ipairs(workspace:GetDescendants()) do
            if #potatoQueue >= maxPotatoQueue then break end
            if shouldUltraPotatoTouch(item) and not queuedPotato[item] then
                queuedPotato[item] = true
                table.insert(potatoQueue, item)
            end
        end
    else
        potatoQueue = {}
        queuedPotato = setmetatable({}, { __mode = "k" })
    end
end

if _G.IndraHubLiteWindUI then
    pcall(function() _G.IndraHubLiteWindUI:Destroy() end)
end
if _G.IndraHubLiteConnections then
    for _, connection in ipairs(_G.IndraHubLiteConnections) do pcall(function() connection:Disconnect() end) end
end
_G.IndraHubLiteConnections = {}

task.spawn(function()
    while isSessionActive() do
        markHeartbeat()
        safeWait(isFragileExecutor and 0.35 or 0.12)
        if safePotato and #potatoQueue > 0 then
            local batch = isFragileExecutor and 30 or 140
            for _ = 1, math.min(batch, #potatoQueue) do
                local instance = table.remove(potatoQueue)
                if instance and instance.Parent then pcall(applySafePotatoTo, instance) end
            end
        end
    end
end)

local Window = WindUI:CreateWindow({
    Title = "IndraHub Lite",
    Icon = "swords",
    Author = "Teleport + Auto Skill + Safe Potato",
    Folder = "IndraHubLite",
    Size = UDim2.fromOffset(520, 390),
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 150,
})
_G.IndraHubLiteWindUI = Window


Window:SetToggleKey(Enum.KeyCode.RightControl)
Window:EditOpenButton({ Title = "IH", Icon = "swords", Draggable = true })

local Tabs = {
    Teleport = Window:Tab({ Title = "Teleport", Icon = "target" }),
    Skills = Window:Tab({ Title = "Skills", Icon = "zap" }),
    FPS = Window:Tab({ Title = "FPS", Icon = "cpu" }),
}

Tabs.Teleport:Dropdown({
    Title = "Enemy Selector",
    Desc = "Multi-select target enemy.",
    Values = enemyNames,
    Multi = true,
    Callback = function(values)
        selectedEnemies = {}
        currentTarget = nil
        enemyScanCache = {}
        lastEnemyScan = 0
        targetInstanceIndex = 1
        for _, value in ipairs(values or {}) do selectedEnemies[value] = true end
        notify("Targets", tostring(#(values or {})) .. " selected", "target")
    end,
})

Tabs.Teleport:Button({
    Title = "Boss Preset",
    Desc = "Select common bosses.",
    Callback = function()
        selectedEnemies = {}
        for _, enemyName in ipairs({ "[Lv.150] NameLess Hero", "[Lv.750] Moraros", "[Lv.2500] Magador", "[Lv.6000] Velik", "[Lv.3000] Black Swordsman", "[Lv.15000] Hraegon", "[Lv.15000] Niflor", "[Lv.15000] Struggler", "[Lv.15000] Surtrik", "[Lv.15000] Thorvak", "[Nightmare] Mad Dog", "[Nightmare]Headless Knight", "[Lv.???] Gelaros" }) do
            selectedEnemies[enemyName] = true
        end
        currentTarget = nil
        enemyScanCache = {}
        lastEnemyScan = 0
        notify("Boss Preset", "Selected", "crown")
    end,
})

Tabs.Teleport:Button({
    Title = "Teleport Once",
    Desc = "Teleport to first selected live enemy.",
    Callback = function()
        notify("Teleport", teleportSelected() and "Moved" or "No target", "map-pin")
    end,
})

Tabs.Teleport:Toggle({
    Title = "Auto Teleport",
    Desc = "Follow selected target, switch after death.",
    Value = false,
    Callback = function(value)
        autoTeleport = value
        if not value then currentTarget = nil end
        notify("Auto Teleport", value and "ON" or "OFF", "navigation")
    end,
})

Tabs.Teleport:Dropdown({
    Title = "Move Mode",
    Values = { "Teleport", "Part Teleport", "Tween" },
    Value = moveMode,
    Callback = function(value) moveMode = value or "Teleport" end,
})

Tabs.Teleport:Slider({
    Title = "Teleport Delay",
    Value = { Min = 0.2, Max = 5, Default = autoTeleportDelay },
    Step = 0.1,
    Callback = function(value) autoTeleportDelay = value end,
})

Tabs.Teleport:Slider({
    Title = "Hover Distance",
    Value = { Min = 1, Max = 100, Default = hoverDistance },
    Step = 1,
    Callback = function(value) hoverDistance = value end,
})

Tabs.Teleport:Slider({
    Title = "Hover Height",
    Value = { Min = -15, Max = 15, Default = hoverHeight },
    Step = 1,
    Callback = function(value) hoverHeight = value end,
})

Tabs.Skills:Dropdown({
    Title = "Skill Keys",
    Desc = "Multi-select skills.",
    Values = skillKeys,
    Value = { "Z" },
    Multi = true,
    Callback = function(values)
        selectedAutoSkills = {}
        for _, skillKey in ipairs(values or {}) do selectedAutoSkills[skillKey] = true end
        if next(autoSkills) then
            autoSkills = {}
            for _, skillKey in ipairs(skillKeys) do if selectedAutoSkills[skillKey] then autoSkills[skillKey] = true end end
            rebuildNativeAutoSkill()
        end
        notify("Auto Skill", "Selected " .. tostring(#(values or {})), "zap")
    end,
})

Tabs.Skills:Toggle({
    Title = "Auto Skill",
    Desc = "Uses selected skills near target.",
    Value = false,
    Callback = function(value)
        autoSkills = {}
        if value then
            for _, skillKey in ipairs(skillKeys) do if selectedAutoSkills[skillKey] then autoSkills[skillKey] = true end end
        end
        rebuildNativeAutoSkill()
        notify("Auto Skill", value and "ON" or "OFF", "zap")
    end,
})

Tabs.Skills:Slider({
    Title = "Auto Skill Delay",
    Value = { Min = 0.2, Max = 5, Default = autoSkillDelay },
    Step = 0.1,
    Callback = function(value) autoSkillDelay = value end,
})

Tabs.Skills:Slider({
    Title = "Skill Range",
    Value = { Min = 5, Max = 150, Default = skillRange },
    Step = 1,
    Callback = function(value) skillRange = value end,
})

Tabs.FPS:Toggle({
    Title = "Safe Potato",
    Desc = "Stable FPS: disables effects, lights, sounds, decals, GUI clutter.",
    Value = false,
    Callback = function(value)
        setSafePotato(value)
        notify("Safe Potato", value and "ON" or "OFF", "cpu")
    end,
})

Tabs.FPS:Button({
    Title = "Stop Everything",
    Desc = "Disable auto teleport and auto skill.",
    Callback = function()
        autoTeleport = false
        autoSkills = {}
        nativeAutoSkill = nil
        running = false
        _G.IndraHubLiteRunning = false
        pcall(function()
            if type(Player3CController.StopAutoSkill) == "function" then Player3CController.StopAutoSkill() end
        end)
        notify("Stopped", "Re-run script to restart", "square")
    end,
})

Window:SelectTab(1)
notify("IndraHub Lite", "Loaded. Toggle UI: RightControl", "flame")

local descendantAddedConnection = workspace.DescendantAdded:Connect(function(instance)
    if isSessionActive() and safePotato and #potatoQueue < maxPotatoQueue and shouldUltraPotatoTouch(instance) and not queuedPotato[instance] then
        queuedPotato[instance] = true
        table.insert(potatoQueue, instance)
    end
end)
table.insert(_G.IndraHubLiteConnections, descendantAddedConnection)

task.spawn(function()
    while isSessionActive() do
        markHeartbeat()
        safeWait(math.max(autoTeleportDelay, isFragileExecutor and 1.0 or 0.2))
        if autoTeleport then
            local ok, err = pcall(function()
                if not hoverBehindSelected() then teleportSelected() end
            end)
            if not ok then dumpError("auto teleport", err) end
        end
    end
end)

task.spawn(function()
    while isSessionActive() do
        markHeartbeat()
        safeWait(math.max(autoSkillDelay, isFragileExecutor and 1.0 or 0.2))
        local ok, err = pcall(function()
            if nativeAutoSkill and autoSkills[nativeAutoSkill] and os.clock() - lastNativeRefresh > 5 then
                setControllerAutoSkill(nativeAutoSkill, true)
                lastNativeRefresh = os.clock()
            end
            if hasSelectedEnemyInRange() then
                for _, skillKey in ipairs(skillPriority) do
                    if autoSkills[skillKey] and isSkillReady(skillKey) then
                        local didSet = false
                        if not isXeno then didSet = setControllerAutoSkill(skillKey, true) end
                        if isXeno or not didSet or not hasControllerAutoSkill() then useSkill(skillKey) end
                        safeWait(math.max(autoSkillDelay, isFragileExecutor and 1.0 or 0.4))
                    end
                end
            end
        end)
        if not ok then dumpError("auto skill", err) end
    end
end)

task.spawn(function()
    while isSessionActive() do
        markHeartbeat()
        safeWait(20)
        if #potatoQueue > maxPotatoQueue then
            potatoQueue = {}
            queuedPotato = setmetatable({}, { __mode = "k" })
        end
        for index = #enemyScanCache, 1, -1 do
            local enemy = enemyScanCache[index]
            if not isEnemyAlive(enemy) then table.remove(enemyScanCache, index) end
        end
    end
end)