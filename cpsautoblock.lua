--[[
============================================================================
 cpsautoblock.lua  —  "CPS Hub"  for  "The Strongest Battlegrounds" (TSB)
============================================================================
 v3.0  —  full rewrite.  Reconstructed from a MoonVeil-obfuscated bootstrap,
 bug-fixed (see v2), then re-architected for performance, safety and features.

 RECOVERED CONSTANTS (verbatim, unchanged)
 ---------------------------------------------------------------------------
  Remote          : Character.Communicate        (TSB combat RemoteEvent)
  Input actions   : "KeyPress" / "KeyRelease"     (sent through Communicate)
  Char folder     : workspace.Live
  Detection anims : rbxassetid://10479335397
                    rbxassetid://13380255751
                    rbxassetid://13477540643(+)   (enemy M1 / skill / counter)
  URLs            : WindUI main.lua ; https://discord.gg/cpshub
  Mobile GUI      : "CPSMobileCamlockGui"
  Render binds    : PC_CamlockLook / Mobile_CamlockLook

 WHAT'S NEW IN v3
 ---------------------------------------------------------------------------
  * Event-driven ESP: one Highlight + name/health/distance billboard per
    character (was: a SelectionBox per BasePart rebuilt every frame).
  * Camlock: smoothed (lerp), FOV-gated, optional on-screen FOV circle,
    dead-target rejection, single render-step driver.
  * Remote layer caches Character.Communicate per-spawn; never yields in loops.
  * Humanized CPS (jitter) so auto-M1 isn't a perfect metronome.
  * Alive / team / self checks everywhere; graceful respawn handling.
  * Config persistence via writefile/readfile when the executor supports it.
  * Maid-style teardown: Reset Script truly disconnects everything.
  * Multi-tab WindUI (Combat / Aimbot / Visuals / Movement / Config).
============================================================================
]]

--============================================================================
-- 0. Executor / environment compatibility shims
--============================================================================
local function envget(name) return (getgenv and getgenv()[name]) or rawget(getfenv(), name) end

-- Prevent double-execution stacking: if a previous instance is live, tear it down.
if envget("__CPSHUB_ACTIVE") and type(envget("__CPSHUB_CLEANUP")) == "function" then
    pcall(envget("__CPSHUB_CLEANUP"))
end

local clipboard  = (setclipboard or (syn and syn.write_clipboard) or toclipboard or function() end)
local httpGet    = function(url) return game:HttpGet(url) end
local has_write  = type(writefile) == "function" and type(readfile) == "function"
local has_isfile = type(isfile) == "function"
local DrawingAPI = (type(Drawing) == "table" and Drawing) or nil   -- optional FOV circle

pcall(function() clipboard("https://discord.gg/cpshub") end)   -- observed at launch

--============================================================================
-- 1. Services & top-level references
--============================================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
local Camera      = workspace.CurrentCamera
local LiveFolder  = workspace:WaitForChild("Live")   -- TSB character container

--============================================================================
-- 2. Configuration (defaults + persistence)
--============================================================================
local CONFIG_FILE = "CPSHub_TSB.json"

local flags = {
    -- combat
    AutoBlock=false, M1AfterBlock=false, AutoCounter=false, AutoCombat=false, M1Catch=false,
    -- aim
    Camlock=false, CamlockSmooth=0.35, CamlockFOV=120, CamlockShowFOV=false, CamlockDeadCheck=true,
    -- visuals
    ESP=false, ESPNames=true, ESPHealth=true, ESPDistance=true, ESPTeamColor=false,
    -- ranges / tuning
    MaxCPS=8, CPSJitter=true, NormalRange=12, SpecialRange=14, CounterRange=12, SkillRange=15, SkillDelay=0,
    -- movement
    MovementEnabled=false, WalkSpeed=16, JumpPower=50,
    -- misc
    TeamCheck=false, CamlockKey=Enum.KeyCode.C,
}

-- KeyCode <-> string helpers so the bound key survives save/load.
local function keyToStr(kc) return (typeof(kc)=="EnumItem" and kc.Name) or tostring(kc) end
local function strToKey(s)  return (type(s)=="string" and Enum.KeyCode[s]) or Enum.KeyCode.C end

local NON_PERSISTED = { CamlockKey=true }   -- stored separately as a string

local function saveConfig()
    if not has_write then return false end
    local out = {}
    for k,v in pairs(flags) do if not NON_PERSISTED[k] then out[k] = v end end
    out.CamlockKey = keyToStr(flags.CamlockKey)
    local ok, encoded = pcall(HttpService.JSONEncode, HttpService, out)
    if ok then pcall(writefile, CONFIG_FILE, encoded); return true end
    return false
end

local function loadConfig()
    if not has_write then return end
    if has_isfile and not isfile(CONFIG_FILE) then return end
    local ok, raw = pcall(readfile, CONFIG_FILE); if not ok then return end
    local decoded; ok, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
    if not ok or type(decoded) ~= "table" then return end
    for k,v in pairs(decoded) do
        if k == "CamlockKey" then flags.CamlockKey = strToKey(v)
        elseif flags[k] ~= nil and type(v) == type(flags[k]) then flags[k] = v end
    end
end
loadConfig()

-- Enemy attack animation IDs that trigger a block / counter (recovered):
local ATTACK_ANIMS = { ["10479335397"]=true, ["13380255751"]=true, ["13477540643"]=true }
local CHARACTERS   = { "Saitama","Garou","Tatsumaki","Sonic","Metal","Dragon","Blade" }

--============================================================================
-- 3. Maid — centralised teardown for connections / instances / binds
--============================================================================
local Maid = { _conns = {}, _insts = {}, _binds = {}, _destroyed = false }
function Maid:give(conn)  self._conns[#self._conns+1] = conn; return conn end
function Maid:giveInst(i) self._insts[#self._insts+1] = i;    return i end
function Maid:bind(name, prio, fn)
    RunService:BindToRenderStep(name, prio, fn)
    self._binds[name] = true
end
function Maid:unbind(name)
    if self._binds[name] then pcall(function() RunService:UnbindFromRenderStep(name) end); self._binds[name]=nil end
end
function Maid:cleanAll()
    for _,c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
    self._conns = {}
    for name in pairs(self._binds) do pcall(function() RunService:UnbindFromRenderStep(name) end) end
    self._binds = {}
    for _,i in ipairs(self._insts) do pcall(function() i:Destroy() end) end
    self._insts = {}
end

--============================================================================
-- 4. Small utilities
--============================================================================
local function getHumanoid(char) return char and char:FindFirstChildOfClass("Humanoid") end
local function getHRP(char)      return char and char:FindFirstChild("HumanoidRootPart") end

local function isAlive(char)
    local hum = getHumanoid(char)
    return hum ~= nil and hum.Health > 0
end

-- A valid enemy: not us, has a live character with an HRP, passes team check.
local function isValidEnemy(plr)
    if plr == LocalPlayer or not plr.Character then return false end
    if not getHRP(plr.Character) or not isAlive(plr.Character) then return false end
    if flags.TeamCheck and plr.Team and plr.Team == LocalPlayer.Team then return false end
    return true
end

local function myHRP() return getHRP(LocalPlayer.Character) end

--============================================================================
-- 5. Remote layer — Character.Communicate (cached, non-yielding, nil-safe)
--============================================================================
local Combat = { _char=nil, _remote=nil }

-- Refresh the cached remote whenever the character changes. Never yields.
function Combat:remote()
    local char = LocalPlayer.Character
    if not char then return nil end
    if char ~= self._char or not (self._remote and self._remote.Parent) then
        self._char   = char
        self._remote = char:FindFirstChild("Communicate")
    end
    return self._remote
end

function Combat:send(action, key)
    local r = self:remote()
    if not r then return false end
    return pcall(function() r:FireServer(action, key) end)
end

function Combat:block()   self:send("KeyPress",  "F")  end
function Combat:unblock() self:send("KeyRelease","F")  end
function Combat:counter() self:send("KeyPress",  "R")  end
function Combat:m1()      self:send("KeyPress","M1"); self:send("KeyRelease","M1") end

--============================================================================
-- 6. Enemy attack detection (Animator playing tracks)
--============================================================================
local function enemyIsAttacking(char)
    local hum    = getHumanoid(char)
    local animtr = hum and hum:FindFirstChildOfClass("Animator")
    if not animtr then return false end
    for _,track in ipairs(animtr:GetPlayingAnimationTracks()) do
        local anim = track.Animation
        if anim then
            local id = tostring(anim.AnimationId):match("%d+")
            if id and ATTACK_ANIMS[id] then return true end
        end
    end
    return false
end

--============================================================================
-- 7. Target selection
--============================================================================
-- Nearest valid enemy to our HRP (world distance). Used by combat + camlock.
local function nearestEnemy()
    local origin = myHRP(); origin = origin and origin.Position or Camera.CFrame.Position
    local best, bestDist = nil, math.huge
    for _,plr in ipairs(Players:GetPlayers()) do
        if isValidEnemy(plr) then
            local hrp = getHRP(plr.Character)
            local d = (hrp.Position - origin).Magnitude
            if d < bestDist then best, bestDist = plr, d end
        end
    end
    return best, bestDist
end

-- Nearest valid enemy inside the camlock FOV cone (screen-space), preferring
-- the target closest to the crosshair. Rejects dead targets when enabled.
local function nearestInFOV()
    local vp = Camera.ViewportSize
    local center = Vector2.new(vp.X/2, vp.Y/2)
    local limit = flags.CamlockFOV
    local best, bestScore = nil, math.huge
    for _,plr in ipairs(Players:GetPlayers()) do
        if isValidEnemy(plr) and (not flags.CamlockDeadCheck or isAlive(plr.Character)) then
            local hrp = getHRP(plr.Character)
            local sp, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                local delta = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                if delta <= limit and delta < bestScore then best, bestScore = hrp, delta end
            end
        end
    end
    return best
end

--============================================================================
-- 8. Camlock  (single render-step driver, smoothed, FOV-gated)
--============================================================================
local fovCircle
local function ensureFOVCircle()
    if not (DrawingAPI and flags.CamlockShowFOV) then return end
    if not fovCircle then
        fovCircle = DrawingAPI.new("Circle")
        fovCircle.Thickness = 1.5
        fovCircle.NumSides  = 64
        fovCircle.Filled    = false
        fovCircle.Color     = Color3.fromRGB(255, 60, 60)
    end
    local vp = Camera.ViewportSize
    fovCircle.Radius   = flags.CamlockFOV
    fovCircle.Position = Vector2.new(vp.X/2, vp.Y/2)
    fovCircle.Visible  = flags.Camlock
end
local function hideFOVCircle() if fovCircle then fovCircle.Visible = false end end

local function camlockStep()
    ensureFOVCircle()
    local target = nearestInFOV()
    if not target then return end
    local camPos = Camera.CFrame.Position
    local goal   = CFrame.new(camPos, target.Position)
    -- Smooth toward the goal so the lock glides instead of snapping.
    local a = math.clamp(1 - flags.CamlockSmooth, 0.05, 1)
    Camera.CFrame = Camera.CFrame:Lerp(goal, a)
end

local function setCamlock(on)
    flags.Camlock = on
    if on then
        Maid:bind("PC_CamlockLook", Enum.RenderPriority.Camera.Value + 1, camlockStep)
    else
        Maid:unbind("PC_CamlockLook")
        hideFOVCircle()
    end
end

--============================================================================
-- 9. ESP  (event-driven: one Highlight + billboard per character)
--============================================================================
-- espData[player] = { highlight=..., billboard=..., conns={...} }
local espData = {}

local function destroyESP(plr)
    local d = espData[plr]; if not d then return end
    for _,c in ipairs(d.conns) do pcall(function() c:Disconnect() end) end
    pcall(function() if d.highlight then d.highlight:Destroy() end end)
    pcall(function() if d.billboard then d.billboard:Destroy() end end)
    espData[plr] = nil
end

local function clearAllESP()
    for plr in pairs(espData) do destroyESP(plr) end
end

local function espColor(plr)
    if flags.ESPTeamColor and plr.Team then return plr.TeamColor.Color end
    return Color3.fromRGB(255, 0, 0)
end

-- Build (or rebuild) the ESP visuals for one player's current character.
local function buildESP(plr)
    destroyESP(plr)
    local char = plr.Character
    local hrp  = getHRP(char)
    local hum  = getHumanoid(char)
    if not (char and hrp and hum) then return end

    local d = { conns = {} }

    local hl = Instance.new("Highlight")
    hl.Name             = "ESP_Highlight"
    hl.Adornee          = char
    hl.FillTransparency = 0.75
    hl.OutlineTransparency = 0
    hl.FillColor        = espColor(plr)
    hl.OutlineColor     = espColor(plr)
    hl.Enabled          = flags.ESP
    hl.Parent           = char
    d.highlight = hl

    local bb = Instance.new("BillboardGui")
    bb.Name          = "ESP_Info"
    bb.Adornee       = hrp
    bb.Size          = UDim2.fromOffset(200, 44)
    bb.StudsOffset   = Vector3.new(0, 3.2, 0)
    bb.AlwaysOnTop   = true
    bb.MaxDistance   = 1000
    bb.Enabled       = flags.ESP
    bb.Parent        = hrp
    d.billboard = bb

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size          = UDim2.fromScale(1, 1)
    label.Font          = Enum.Font.GothamBold
    label.TextSize      = 14
    label.TextColor3    = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0.4
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.Parent        = bb

    -- Keep the label text fresh without a global per-frame scan.
    local function refresh()
        if not flags.ESP then return end
        local parts = {}
        if flags.ESPNames    then parts[#parts+1] = plr.DisplayName or plr.Name end
        if flags.ESPHealth   then parts[#parts+1] = string.format("HP %d", math.floor(hum.Health)) end
        if flags.ESPDistance then
            local o = myHRP()
            if o then parts[#parts+1] = string.format("%dm", math.floor((hrp.Position - o.Position).Magnitude)) end
        end
        label.Text = table.concat(parts, "  |  ")
        hl.FillColor, hl.OutlineColor = espColor(plr), espColor(plr)
    end
    refresh()
    d.conns[#d.conns+1] = hum.HealthChanged:Connect(refresh)
    -- Throttled distance refresh (~5 Hz) so text follows the target smoothly.
    local acc = 0
    d.conns[#d.conns+1] = RunService.Heartbeat:Connect(function(dt)
        acc = acc + dt
        if acc >= 0.2 then acc = 0; refresh() end
    end)
    d.conns[#d.conns+1] = hum.Died:Connect(function() destroyESP(plr) end)

    espData[plr] = d
end

local function watchPlayerESP(plr)
    if plr == LocalPlayer then return end
    Maid:give(plr.CharacterAdded:Connect(function()
        task.wait(0.2)   -- let the rig assemble
        if flags.ESP then buildESP(plr) end
    end))
    if plr.Character and flags.ESP then buildESP(plr) end
end

local function setESP(on)
    flags.ESP = on
    if on then
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and not espData[plr] then buildESP(plr) end
        end
    else
        clearAllESP()
    end
end

--============================================================================
-- 10. Movement  (applied on demand + on respawn)
--============================================================================
local function applyMovement(hum)
    if not (hum and flags.MovementEnabled) then return end
    hum.WalkSpeed    = flags.WalkSpeed
    hum.UseJumpPower = true               -- JumpPower is ignored otherwise on modern rigs
    hum.JumpPower    = flags.JumpPower
end

--============================================================================
-- 11. Combat automation  (throttled Heartbeat; humanized CPS)
--============================================================================
local lastClick = 0
local function nextClickReady()
    local base = 1 / math.max(1, flags.MaxCPS)
    local jitter = flags.CPSJitter and (math.random() * base * 0.35) or 0
    return (tick() - lastClick) >= (base + jitter)
end

Maid:give(RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    applyMovement(getHumanoid(char))

    local origin = getHRP(char)
    if not origin then return end
    if not (flags.AutoBlock or flags.AutoCounter or flags.AutoCombat) then return end
    origin = origin.Position

    for _,enemy in ipairs(LiveFolder:GetChildren()) do
        if enemy ~= char then
            local hrp = getHRP(enemy)
            if hrp and isAlive(enemy) then
                local dist = (hrp.Position - origin).Magnitude
                local attacking   -- lazy: at most one Animator read per enemy per frame
                local function attacks()
                    if attacking == nil then attacking = enemyIsAttacking(enemy) end
                    return attacking
                end

                -- Counter takes priority over block; they can't fire together.
                if flags.AutoCounter and dist <= flags.CounterRange and attacks() then
                    Combat:counter()
                elseif flags.AutoBlock and dist <= flags.NormalRange and attacks() then
                    Combat:block()
                    if flags.M1AfterBlock then Combat:unblock(); Combat:m1() end
                end

                if flags.AutoCombat and dist <= flags.NormalRange and nextClickReady() then
                    lastClick = tick(); Combat:m1()
                end
            end
        end
    end
end))

--============================================================================
-- 12. Input hooks  (single source of truth for the camlock toggle)
--============================================================================
Maid:give(UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == flags.CamlockKey then
        setCamlock(not flags.Camlock)
    end
end))

Maid:give(Players.PlayerAdded:Connect(function(plr) watchPlayerESP(plr) end))
Maid:give(Players.PlayerRemoving:Connect(function(plr) destroyESP(plr) end))
for _,plr in ipairs(Players:GetPlayers()) do watchPlayerESP(plr) end

Maid:give(LocalPlayer.CharacterAdded:Connect(function(char)
    Combat._char, Combat._remote = nil, nil          -- invalidate cached remote
    local hum = char:WaitForChild("Humanoid")
    applyMovement(hum)
end))

--============================================================================
-- 13. Teardown
--============================================================================
local function cleanup()
    Maid._destroyed = true
    setCamlock(false)
    clearAllESP()
    Maid:cleanAll()
    Maid:unbind("Mobile_CamlockLook")
    if fovCircle then pcall(function() fovCircle:Remove() end); fovCircle = nil end
    local g = PlayerGui:FindFirstChild("CPSMobileCamlockGui"); if g then g:Destroy() end
    if getgenv then getgenv().__CPSHUB_ACTIVE = false end
end
if getgenv then
    getgenv().__CPSHUB_ACTIVE  = true
    getgenv().__CPSHUB_CLEANUP = cleanup
end

--============================================================================
-- 14. UI  (WindUI, multi-tab)  — with fallback source
--============================================================================
local WindUI
local ok = pcall(function()
    WindUI = loadstring(httpGet(
        "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)
if not ok or not WindUI then
    WindUI = loadstring(httpGet(
        "https://raw.githubusercontent.com/Footagesus/WindUI/main/main.lua"))()
end

local Window = WindUI:CreateWindow({
    Title="Strongest Battlegrounds", Icon="cyborg", Author="Tech",
    Size=UDim2.fromOffset(680, 460), Theme="Red", Resizable=true, SideBarWidth=180 })

local function notify(title, content)
    pcall(function() WindUI:Notify({ Title=title, Content=content, Duration=3 }) end)
end

local CombatTab = Window:Tab({ Title="Combat",   Icon="swords"  })
local AimTab    = Window:Tab({ Title="Aimbot",   Icon="crosshair" })
local VisualTab = Window:Tab({ Title="Visuals",  Icon="eye"     })
local MoveTab   = Window:Tab({ Title="Movement", Icon="footprints" })
local ConfigTab = Window:Tab({ Title="Config",   Icon="settings" })

-- ── Combat ──────────────────────────────────────────────────────────────
CombatTab:Toggle({Title="Auto Block",     Value=flags.AutoBlock,    Callback=function(v) flags.AutoBlock=v end})
CombatTab:Toggle({Title="M1 After Block", Value=flags.M1AfterBlock, Callback=function(v) flags.M1AfterBlock=v end})
CombatTab:Toggle({Title="Auto Counter",   Value=flags.AutoCounter,  Callback=function(v) flags.AutoCounter=v end})
CombatTab:Toggle({Title="Auto Combat",    Value=flags.AutoCombat,   Callback=function(v) flags.AutoCombat=v end})
CombatTab:Toggle({Title="M1 Catch",       Value=flags.M1Catch,      Callback=function(v) flags.M1Catch=v end})
CombatTab:Toggle({Title="Team Check",     Value=flags.TeamCheck,    Callback=function(v) flags.TeamCheck=v end})
CombatTab:Slider({Title="Normal Range",  Value={Min=0,Max=50,Default=flags.NormalRange},  Callback=function(v) flags.NormalRange=v end})
CombatTab:Slider({Title="Special Range", Value={Min=0,Max=50,Default=flags.SpecialRange}, Callback=function(v) flags.SpecialRange=v end})
CombatTab:Slider({Title="Counter Range", Value={Min=0,Max=50,Default=flags.CounterRange}, Callback=function(v) flags.CounterRange=v end})
CombatTab:Slider({Title="Skill Range",   Value={Min=0,Max=50,Default=flags.SkillRange},   Callback=function(v) flags.SkillRange=v end})
CombatTab:Slider({Title="Skill Delay",   Value={Min=0,Max=1,Default=flags.SkillDelay}, Step=0.05, Callback=function(v) flags.SkillDelay=v end})
CombatTab:Slider({Title="Max CPS",       Value={Min=1,Max=30,Default=flags.MaxCPS},       Callback=function(v) flags.MaxCPS=math.max(1,v) end})
CombatTab:Toggle({Title="Humanize CPS",  Value=flags.CPSJitter,   Callback=function(v) flags.CPSJitter=v end})

-- ── Aimbot ──────────────────────────────────────────────────────────────
AimTab:Toggle({Title="Camlock", Value=flags.Camlock, Callback=function(v) setCamlock(v) end})
AimTab:Keybind({Title="Camlock Key", Name="lock", Value=keyToStr(flags.CamlockKey),
    Callback=function(newKey)
        if typeof(newKey) == "EnumItem" then flags.CamlockKey = newKey
        elseif type(newKey)=="string" and Enum.KeyCode[newKey] then flags.CamlockKey = Enum.KeyCode[newKey] end
    end})
AimTab:Slider({Title="Smoothness", Value={Min=0,Max=0.95,Default=flags.CamlockSmooth}, Step=0.05,
    Callback=function(v) flags.CamlockSmooth=v end})
AimTab:Slider({Title="FOV (px)", Value={Min=20,Max=600,Default=flags.CamlockFOV},
    Callback=function(v) flags.CamlockFOV=v end})
AimTab:Toggle({Title="Show FOV Circle", Value=flags.CamlockShowFOV,
    Callback=function(v) flags.CamlockShowFOV=v; if not v then hideFOVCircle() end end})
AimTab:Toggle({Title="Ignore Dead Targets", Value=flags.CamlockDeadCheck,
    Callback=function(v) flags.CamlockDeadCheck=v end})

-- ── Visuals ─────────────────────────────────────────────────────────────
VisualTab:Toggle({Title="Enable ESP",     Value=flags.ESP,          Callback=function(v) setESP(v) end})
VisualTab:Toggle({Title="Show Names",      Value=flags.ESPNames,     Callback=function(v) flags.ESPNames=v end})
VisualTab:Toggle({Title="Show Health",     Value=flags.ESPHealth,    Callback=function(v) flags.ESPHealth=v end})
VisualTab:Toggle({Title="Show Distance",   Value=flags.ESPDistance,  Callback=function(v) flags.ESPDistance=v end})
VisualTab:Toggle({Title="Use Team Color",  Value=flags.ESPTeamColor, Callback=function(v)
    flags.ESPTeamColor=v; if flags.ESP then for plr in pairs(espData) do buildESP(plr) end end
end})

-- ── Movement ────────────────────────────────────────────────────────────
MoveTab:Toggle({Title="Enable Movement Mods", Value=flags.MovementEnabled, Callback=function(v)
    flags.MovementEnabled=v
    if not v then
        local hum = getHumanoid(LocalPlayer.Character)
        if hum then hum.WalkSpeed=16; hum.JumpPower=50 end
    end
end})
MoveTab:Slider({Title="Walk Speed", Value={Min=16,Max=200,Default=flags.WalkSpeed}, Callback=function(v) flags.WalkSpeed=v end})
MoveTab:Slider({Title="Jump Power", Value={Min=50,Max=350,Default=flags.JumpPower}, Callback=function(v) flags.JumpPower=v end})
MoveTab:Button({Title="Refresh Character", Description="Respawn your character", Callback=function()
    local c = LocalPlayer.Character
    if c then pcall(function() c:BreakJoints() end) end
    task.wait()
    pcall(function() LocalPlayer:LoadCharacter() end)
end})

-- ── Config ──────────────────────────────────────────────────────────────
ConfigTab:Button({Title="Save Config", Description=has_write and "Persist settings to disk" or "Executor has no file access",
    Callback=function() if saveConfig() then notify("CPS Hub","Config saved.") else notify("CPS Hub","Save unsupported by executor.") end end})
ConfigTab:Button({Title="Copy Discord", Callback=function() pcall(function() clipboard("https://discord.gg/cpshub") end); notify("CPS Hub","Discord link copied.") end})
ConfigTab:Button({Title="Reset Script", Description="Cleanup and reset all functions", Callback=function()
    cleanup(); pcall(function() Window:Destroy() end); notify("CPS Hub","Reset complete.")
end})

-- Restore visual/aim state that was loaded from disk (toggles only set flags).
if flags.ESP     then setESP(true) end
if flags.Camlock then setCamlock(true) end
notify("CPS Hub", "Loaded — discord.gg/cpshub")

--[[
============================================================================
 CHANGELOG  (v2 -> v3)
----------------------------------------------------------------------------
 * ESP rewritten from per-part SelectionBox (rebuilt every frame) to one
   Highlight + name/health/distance BillboardGui per character, driven by
   PlayerAdded/CharacterAdded/Died events. Massive perf win, no leaks.
 * Camlock: FOV-gated target pick, smoothing via CFrame:Lerp, optional FOV
   circle (Drawing API), dead-target rejection, single render-step driver.
 * Combat: cached Communicate remote, humanized CPS, alive/team checks,
   counter>block priority, one Animator read per enemy per frame.
 * Config persistence (writefile/readfile) with graceful no-op fallback.
 * Maid teardown so "Reset Script" disconnects everything; guards against
   double-execution via getgenv sentinel.
 * Multi-tab UI (Combat / Aimbot / Visuals / Movement / Config) + notifs.
============================================================================
]]
