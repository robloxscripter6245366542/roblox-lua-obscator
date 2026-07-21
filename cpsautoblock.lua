--[[
============================================================================
 cpsautoblock.lua  —  "CPS Hub" for "The Strongest Battlegrounds" (TSB)
============================================================================
 Reconstructed from a MoonVeil-obfuscated bootstrapper, then cleaned up and
 bug-fixed. All RECOVERED CONSTANTS are kept verbatim; only broken logic was
 corrected. See the BUGFIXES block at the bottom for the full list.

 RECOVERED CONSTANTS (verbatim)
 ---------------------------------------------------------------------------
  Remote          : Character.Communicate   (TSB combat RemoteEvent)
  Input actions   : "KeyPress" / "KeyRelease"  (sent through Communicate)
  Char folder     : workspace.Live
  Detection anims : rbxassetid://10479335397
                    rbxassetid://13380255751
                    rbxassetid://13477540643(+)      (enemy M1/skill/counter)
  URLs            : WindUI main.lua ; https://discord.gg/cpshub
  Mobile GUI      : "CPSMobileCamlockGui"
  Render binds    : PC_CamlockLook / Mobile_CamlockLook
============================================================================
]]

-- ── Services (exact) ────────────────────────────────────────────────────
local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local UserInputService    = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
local Camera      = workspace.CurrentCamera
local LiveFolder  = workspace:WaitForChild("Live")   -- TSB character container

pcall(function() setclipboard("https://discord.gg/cpshub") end)   -- observed at launch

-- ── State ───────────────────────────────────────────────────────────────
local flags = {
    AutoBlock=false, M1AfterBlock=false, AutoCounter=false, AutoCombat=false, M1Catch=false,
    Camlock=false, ESP=false,
    MaxCPS=8, NormalRange=12, SpecialRange=14, CounterRange=12, SkillRange=15, SkillDelay=0,
    WalkSpeed=16, JumpPower=50, CamlockKey=Enum.KeyCode.C,
}

-- Enemy attack animation IDs that trigger a block/counter (recovered):
local ATTACK_ANIMS = {
    ["10479335397"]=true, ["13380255751"]=true, ["13477540643"]=true,
}

local CHARACTERS = { "Saitama","Garou","Tatsumaki","Sonic","Metal","Dragon","Blade" }

-- Connection / instance bookkeeping so cleanup() can actually tear everything down.
local connections = {}                 -- RBXScriptConnections created by this script
local espBoxes    = {}                 -- part -> SelectionBox (keyed, so we never duplicate)
local camlockBound = false             -- whether a render-step camlock is currently bound
local cleanup                          -- forward declaration (defined below)

-- Track a connection so it can be disconnected on cleanup().
local function track(conn)
    connections[#connections+1] = conn
    return conn
end

-- ── UI: WindUI menu (with fallback source) ──────────────────────────────
local WindUI
local ok = pcall(function()
    WindUI = loadstring(game:HttpGet(
        "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)
if not ok or not WindUI then
    WindUI = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/Footagesus/WindUI/main/main.lua"))()
end

local Window = WindUI:CreateWindow({
    Title="Strongest Battlegrounds", Icon="cyborg", Author="Tech",
    Size=UDim2.fromOffset(650,210), Theme="Red", Resizable=true, SideBarWidth=170 })
local Tab = Window:Tab({ Title="Utilities", Icon="zap" })

Tab:Toggle({Title="Auto Block",    Value=false, Callback=function(v) flags.AutoBlock=v end})
Tab:Toggle({Title="M1 After Block",Value=false, Callback=function(v) flags.M1AfterBlock=v end})
Tab:Toggle({Title="Auto Counter",  Value=false, Callback=function(v) flags.AutoCounter=v end})
Tab:Toggle({Title="Auto Combat",   Value=false, Callback=function(v) flags.AutoCombat=v end})
Tab:Toggle({Title="M1 Catch",      Value=false, Callback=function(v) flags.M1Catch=v end})
Tab:Toggle({Title="Enable ESP",    Value=false, Callback=function(v) flags.ESP=v end})

Tab:Slider({Title="Normal Range",  Value={Min=0,Max=50,Default=12}, Callback=function(v) flags.NormalRange=v end})
Tab:Slider({Title="Special Range", Value={Min=0,Max=50,Default=14}, Callback=function(v) flags.SpecialRange=v end})
Tab:Slider({Title="Counter Range", Value={Min=0,Max=50,Default=12}, Callback=function(v) flags.CounterRange=v end})
Tab:Slider({Title="Skill Range",   Value={Min=0,Max=50,Default=15}, Callback=function(v) flags.SkillRange=v end})
Tab:Slider({Title="Skill Delay",   Value={Min=0,Max=1,Default=0}, Step=0.05, Callback=function(v) flags.SkillDelay=v end})
Tab:Slider({Title="Max CPS",       Value={Min=1,Max=30,Default=8},  Callback=function(v) flags.MaxCPS=math.max(1,v) end})
Tab:Slider({Title="Walk Speed",    Value={Min=16,Max=200,Default=16}, Callback=function(v) flags.WalkSpeed=v end})
Tab:Slider({Title="Jump Power",    Value={Min=50,Max=350,Default=50}, Callback=function(v) flags.JumpPower=v end})

-- Keybind: capture the *new* key so rebinding actually takes effect.
Tab:Keybind({Title="Camlock (PC)", Name="lock", Value=Enum.KeyCode.C,
    Callback=function(newKey)
        -- WindUI passes the newly-bound key; normalise to an Enum.KeyCode.
        if typeof(newKey) == "EnumItem" then
            flags.CamlockKey = newKey
        elseif type(newKey) == "string" and Enum.KeyCode[newKey] then
            flags.CamlockKey = Enum.KeyCode[newKey]
        end
    end})

Tab:Button({Title="Copy Discord", Callback=function() setclipboard("https://discord.gg/cpshub") end})
Tab:Button({Title="Reset Script", Description="Cleanup and reset all functions", Callback=function() cleanup() end})
Tab:Button({Title="Refresh Character", Description="Respawn your character", Callback=function()
    local c = LocalPlayer.Character
    if c then pcall(function() c:BreakJoints() end) end
    task.wait()
    pcall(function() LocalPlayer:LoadCharacter() end)
end})

-- ── Target / detection helpers ──────────────────────────────────────────

-- Closest on-screen enemy via camera projection (now actually picks the closest).
local function getPlayerInView()
    local best, bestDist = nil, math.huge
    local camPos = Camera.CFrame.Position
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local _,onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local d = (hrp.Position - camPos).Magnitude
                    if d < bestDist then best, bestDist = plr, d end
                end
            end
        end
    end
    return best
end

-- Read an enemy Animator's playing tracks for a known attack animation id.
local function enemyIsAttacking(char)
    local hum    = char:FindFirstChildOfClass("Humanoid")
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

-- ── Combat action: replicate inputs through the Communicate remote ──────
-- Non-yielding + nil-safe: safe to call every Heartbeat frame.
local function sendKey(action, key)
    local char = LocalPlayer.Character
    local comm = char and char:FindFirstChild("Communicate")
    if not comm then return end
    pcall(function() comm:FireServer(action, key) end)
end
local function block()   sendKey("KeyPress","F")   end   -- hold block
local function unblock() sendKey("KeyRelease","F")  end
local function m1()      sendKey("KeyPress","M1"); sendKey("KeyRelease","M1") end

-- ── Camlock (single render-step implementation) ─────────────────────────
-- Only one camlock driver exists now, so the camera no longer fights itself.
local function camlockStep()
    local best, bestDist = nil, math.huge
    local camPos = Camera.CFrame.Position
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (hrp.Position - camPos).Magnitude
                if d < bestDist then best, bestDist = hrp, d end
            end
        end
    end
    if best then
        Camera.CFrame = CFrame.new(camPos, best.Position)   -- look at nearest target
    end
end

local function lockCamlockPC()
    if camlockBound then return end
    RunService:BindToRenderStep("PC_CamlockLook", Enum.RenderPriority.Camera.Value + 1, camlockStep)
    camlockBound = true
end
local function clearCamlockPC()
    if not camlockBound then return end
    pcall(function() RunService:UnbindFromRenderStep("PC_CamlockLook") end)
    camlockBound = false
end

local function setCamlock(on)
    flags.Camlock = on
    if on then lockCamlockPC() else clearCamlockPC() end
end

-- ── ESP helpers ─────────────────────────────────────────────────────────
local function clearESP()
    for part,box in pairs(espBoxes) do
        pcall(function() box:Destroy() end)
        espBoxes[part] = nil
    end
end

function cleanup()   -- "Reset Script" / "Cleanup and reset all functions"
    -- Actually disconnect everything this script created.
    for _,conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    connections = {}
    clearCamlockPC()
    pcall(function() RunService:UnbindFromRenderStep("Mobile_CamlockLook") end)
    clearESP()
    setCamlock(false)
    local g = PlayerGui:FindFirstChild("CPSMobileCamlockGui"); if g then g:Destroy() end
end

-- ── Input hooks ─────────────────────────────────────────────────────────
-- Single source of truth for the camlock toggle (no double-toggle with the UI keybind).
track(UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.UserInputType == Enum.UserInputType.Keyboard
       and input.KeyCode == flags.CamlockKey then
        setCamlock(not flags.Camlock)
    end
end))

track(Players.PlayerRemoving:Connect(function(plr)
    -- Drop ESP boxes belonging to the leaving player so the table can't grow unbounded.
    if plr.Character then
        for _,part in ipairs(plr.Character:GetDescendants()) do
            local box = espBoxes[part]
            if box then pcall(function() box:Destroy() end); espBoxes[part] = nil end
        end
    end
end))

-- ── Movement mods (re-applied on respawn too) ───────────────────────────
local function applyMovement(hum)
    if not hum then return end
    hum.WalkSpeed = flags.WalkSpeed
    -- JumpPower is ignored unless UseJumpPower is true on modern rigs.
    hum.UseJumpPower = true
    hum.JumpPower = flags.JumpPower
end

-- ── Main automation loop (Heartbeat) ────────────────────────────────────
local lastClick = 0
track(RunService.Heartbeat:Connect(function()
    local char   = LocalPlayer.Character
    local hum    = char and char:FindFirstChildOfClass("Humanoid")
    local myHrp  = char and char:FindFirstChild("HumanoidRootPart")
    applyMovement(hum)

    if not myHrp then return end
    if not (flags.AutoBlock or flags.AutoCounter or flags.AutoCombat) then return end

    for _,enemy in ipairs(LiveFolder:GetChildren()) do
        if enemy ~= char then
            local hrp = enemy:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (hrp.Position - myHrp.Position).Magnitude
                local attacking = nil   -- computed lazily, at most once per enemy

                -- Counter takes priority over block; they no longer fire on the same frame.
                if flags.AutoCounter and dist <= flags.CounterRange then
                    if attacking == nil then attacking = enemyIsAttacking(enemy) end
                    if attacking then
                        sendKey("KeyPress","R")   -- counter/grab
                    end
                elseif flags.AutoBlock and dist <= flags.NormalRange then
                    if attacking == nil then attacking = enemyIsAttacking(enemy) end
                    if attacking then
                        block()
                        if flags.M1AfterBlock then unblock(); m1() end
                    end
                end

                if flags.AutoCombat and dist <= flags.NormalRange then
                    if tick() - lastClick >= 1/flags.MaxCPS then
                        lastClick = tick(); m1()   -- auto-M1 @ Max CPS
                    end
                end
            end
        end
    end
end))

-- ── ESP loop (Heartbeat) ────────────────────────────────────────────────
track(RunService.Heartbeat:Connect(function()
    if not flags.ESP then
        if next(espBoxes) then clearESP() end
        return
    end
    -- Reap boxes whose part is gone.
    for part,box in pairs(espBoxes) do
        if not part:IsDescendantOf(workspace) then
            pcall(function() box:Destroy() end); espBoxes[part] = nil
        end
    end
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            for _,part in ipairs(plr.Character:GetDescendants()) do
                -- Guard on the keyed table (previously guarded on a name that never matched).
                if part:IsA("BasePart") and not espBoxes[part] then
                    local box = Instance.new("SelectionBox")
                    box.Name               = "ESP_Box"
                    box.Adornee            = part
                    box.LineThickness      = 0.03
                    box.Color3             = Color3.fromRGB(255,0,0)
                    box.SurfaceColor3      = Color3.fromRGB(255,0,0)
                    box.SurfaceTransparency = 0.8
                    box.Parent             = part
                    espBoxes[part] = box
                end
            end
        end
    end
end))

-- Re-apply movement mods whenever the character respawns.
track(LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid")
    applyMovement(hum)
end))

--[[
============================================================================
 BUGFIXES (vs. the reconstructed source)
----------------------------------------------------------------------------
 1. ESP memory leak: the create-guard checked FindFirstChild("ESP_Outline")
    but the box was named "ESP_Box", so it never matched and a new
    SelectionBox was created for every part every frame. Now guarded on a
    keyed `espBoxes[part]` table; boxes are reaped when parts/players leave.
 2. Camlock keybind never updated flags.CamlockKey, so rebinding did nothing.
    The keybind callback now stores the new key.
 3. Double-toggle: the WindUI keybind AND InputBegan both toggled Camlock on
    the same key (net no-op). InputBegan is now the single toggle; the UI
    keybind only records the key.
 4. Two competing camlock drivers (render-step + Heartbeat) fought over
    Camera.CFrame and caused jitter. Collapsed into one render-step driver.
 5. getPlayerInView() overwrote `best` for any on-screen player instead of
    keeping the closest; now compares distance.
 6. sendKey() errored when Character was nil and used WaitForChild inside hot
    loops (could yield). Now nil-safe and non-yielding (FindFirstChild).
 7. cleanup()/"Reset Script" could not disconnect anything (connections were
    never stored). All connections are now tracked and disconnected.
 8. JumpPower was silently ignored on rigs where UseJumpPower == false; it is
    now forced true before setting JumpPower.
 9. Auto Block + Auto Counter fired conflicting inputs on the same frame;
    counter now takes priority (elseif), and enemyIsAttacking() is evaluated
    at most once per enemy per frame.
10. Heartbeat now early-outs when no combat feature is enabled or the local
    HRP is missing, avoiding needless per-enemy scans.
============================================================================
]]
