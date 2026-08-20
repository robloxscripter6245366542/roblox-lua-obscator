--!strict
-- =============================================================================
--  Ouroboros Hub  /  stealanegg.lua  -- BEHAVIORAL RECONSTRUCTION
-- =============================================================================
--  This is a READABLE reconstruction of the deobfuscated program, rebuilt from
--  the recovered constant pool (every helper name, remote name and UI label was
--  stored in cleartext -- see StealAnEgg_constants.txt) and from unflattening the
--  control-flow state machines described in StealAnEgg_Deobfuscated.md.
--
--  It is NOT a byte-exact recompile of all 352 embedded functions. It captures
--  the architecture, the remotes it drives, and the shape of the main loops, so
--  the script can be understood and audited. Bodies marked "[reconstructed]" are
--  faithful to the recovered names/flow but are not guaranteed line-identical to
--  the original source.
-- =============================================================================

--#region services -----------------------------------------------------------
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local TeleportService    = game:GetService("TeleportService")
local HttpService        = game:GetService("HttpService")
local Workspace          = game:GetService("Workspace")
local Lighting           = game:GetService("Lighting")
local GuiService         = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
--#endregion

--#region config (defaults for the menu -- see FeaturesGroup labels) ----------
local Config = {
    -- Egg stealing
    AutoStealEgg          = false,
    AutoStealAll          = false,
    StealBigEggs          = false,
    StealBigEggScale      = 0,
    StealPriority         = { "PrioritySlot1", "PrioritySlot2", "PrioritySlot3", "PrioritySlot4" },
    StealMutations        = {},          -- rarity/mutation filters
    MAX_INVENTORY         = 0,           -- inventory cap guard

    -- Pets / economy
    AutoSellPets          = false,  SellRarities = {}, SellMutations = {},
    SellKeepEquipped      = true,   SellKeepMutated = true,  SellInterval = 0,
    AutoFusePets          = false,  FuseRarities = {}, FuseMutations = {},
    FuseKeepEquipped      = true,   FuseKeepMutated = true,  FuseInterval = 0,
    AutoEquipBest         = false,  AutoEquipBestGear = false, AutoEquipBestTrail = false,
    AutoBuyTrail          = false,  AutoUpgrades = false,
    AutoClaimOffline      = false,  AutoClaimGroupReward = false,
    AutoTreadmill         = false,
    AutoOpenReadyEggs     = false,
    AutoPlaceAll          = false,  AutoDropEgg = false,
    AutoReturn            = false,  ReturnPace = 0,

    -- ESP
    EspWorldEggs = false, EspCarriedEggs = false, EspPets = false,
    EspGuards = false, EspMachines = false, EspPlots = false, EspPlayers = false,
    EspDistance = 0,

    -- Movement / rendering
    Fly = false, FlySpeed = 0, NoClip = false, InfJump = false,
    WalkSpeedEnabled = false, WalkSpeed = 16, JumpPowerEnabled = false, JumpPower = 50,
    AntiAfk = true, FpsBoost = false, FpsCap = 0, DisableRendering = false,
    AntiGameplayPause = false,

    -- Server hop / reconnect
    AutoServerHop = false, HopMode = "No Matching Eggs", HopValue = 0,
    AutoReconnect = false,

    -- Webhook (opt-in telemetry)
    WebhookEnabled = false, WebhookUrl = "", WebhookInterval = 0,
    WebhookDisconnectAlerts = false, WebhookEggSpawns = false,
    WebhookRarities = {}, WebhookPingId = "",

    -- Misc
    AutoExecute = false, AutoHideUi = false, MenuKeybind = Enum.KeyCode.RightControl,
}
--#endregion

-- =============================================================================
--  NETWORKING  (netCall / netInvoke / netRemote)                    [recovered]
-- =============================================================================
-- Thin wrappers around the game's RemoteEvents/RemoteFunctions in
-- ReplicatedStorage. The original resolves remotes lazily and caches them.
local Net = {}

function Net.remote(name: string): Instance?
    -- resolves e.g. "RequestCarryAreaEgg", "SELL_ASSET", "START_FUSE", ...
    return ReplicatedStorage:FindFirstChild(name, true)
end

function Net.call(name: string, ...)          -- RemoteEvent:FireServer
    local r = Net.remote(name)
    if r and r:IsA("RemoteEvent") then r:FireServer(...) end
end

function Net.invoke(name: string, ...)        -- RemoteFunction:InvokeServer
    local r = Net.remote(name)
    if r and r:IsA("RemoteFunction") then return r:InvokeServer(...) end
    return nil
end

-- Remotes the script drives (from the constant pool):
--   RequestCarryAreaEgg, RequestDropHeldAreaEgg, RequestPlaceEgg,
--   RequestHatchEgg, RequestCompleteHatchEgg, RequestAreaEggSnapshot,
--   RequestEquipTool, REQUEST_EQUIP_STATIC, REQUEST_UNEQUIP, REQUEST_SELECT,
--   SELL_ASSET, START_FUSE, EQUIP_BEST, REQUEST_PURCHASE, REQUEST_UPGRADE,
--   REQUEST_BASE_UPGRADE, REQUEST_CLAIM_ALL, REQUEST_REDEEM, CLAIM_REWARD,
--   GET_SUMMARY, GetPlotData, GetAreaEggSnapshot, GetRuntimeSnapshot, INSERT_MOB

-- =============================================================================
--  SMALL HELPERS  (hand-decoded from the flattened bodies)
-- =============================================================================

-- Worked example from the report: the player-by-UserId lookup.
local function findPlayerByUserId(userId: number): Player?
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.UserId == userId then return plr end
    end
    return nil
end

local function getRoot(): BasePart?          -- getRoot / getHumanoid / getSave
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function getHumanoid(): Humanoid?
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

-- number formatting used all over the UI/webhook (formatNumber / formatElapsed)
local function formatNumber(n: number): string
    local suffixes = { "", "K", "M", "B", "T" }
    local i = 1
    while n >= 1000 and i < #suffixes do n /= 1000; i += 1 end
    return string.format("%.2f%s", n, suffixes[i])
end

-- =============================================================================
--  EGG STEALING CORE                                                [recovered]
-- =============================================================================
local Steal = {}

function Steal.eggInventoryFull(): boolean
    return Steal.eggInventoryCount() >= Config.MAX_INVENTORY
end

function Steal.isStealCandidate(eggRecord): boolean
    -- filters: rarity / mutation / "big egg" scale, and ownership/plot checks
    if not Steal.matchesEggFilters(eggRecord) then return false end
    if Config.StealBigEggs and eggRecord.Scale < Config.StealBigEggScale then
        return false
    end
    return true
end

function Steal.pickStealTarget(areaEggs)
    -- walks StealPriority slots in order, returns first record passing filters
    for _, record in ipairs(areaEggs) do
        if Steal.isStealCandidate(record) then return record end
    end
    return nil
end

function Steal.tryCarryEgg(record): boolean
    if Steal.eggInventoryFull() then
        Steal.stealBlockedByInventory = true
        return false
    end
    Movement.tryTeleportTo(record.Position)          -- teleport / pathing to egg
    Net.call("RequestCarryAreaEgg", record.Uid)
    return true
end

-- Main loop, spawned as a task and gated by Config.AutoStealEgg / GameplayPaused.
function Steal.runAutoSteal()
    while true do
        if Config.AutoStealEgg and not Steal.gameplayPaused() then
            local snapshot = Net.invoke("GetAreaEggSnapshot")
            local target = Steal.pickStealTarget(Steal.getAreaEggs(snapshot))
            if target then
                Steal.tryCarryEgg(target)
                Steal.eggsStolen += 1                 -- tracked for the webhook
            elseif Config.AutoServerHop and Config.HopMode == "No Matching Eggs" then
                Hop.request("No matching eggs in this server")
            end
        end
        task.wait(Config.GrabDelay or 0.1)
    end
end

-- Companion loops (same structure, different remotes):
--   runAutoPlaceEggs   -> RequestPlaceEgg / getUnplacedEggUids
--   runAutoDropEgg     -> RequestDropHeldAreaEgg
--   runAutoOpenReadyEggs -> RequestHatchEgg / RequestCompleteHatchEgg
--   runAutoReturn      -> returnToBase (waypoint pathing back to plot)

-- =============================================================================
--  ECONOMY AUTOMATION                                               [recovered]
-- =============================================================================
local Economy = {}

function Economy.runAutoSellPets()
    for _, uid in ipairs(Economy.getSellablePets()) do
        Net.call("SELL_ASSET", uid)
    end
end

function Economy.runAutoFusePets()
    local group = Economy.pickFuseGroup(Economy.fuseGroups())
    if group and Economy.canAffordFuse(group) then
        Net.call("START_FUSE", group)
    end
end

function Economy.runAutoEquipBest()      Net.call("EQUIP_BEST")               end
function Economy.runAutoBuyTrail()       Net.call("REQUEST_PURCHASE", "Trail") end
function Economy.runAutoUpgrades()       Net.call("REQUEST_UPGRADE")          end
function Economy.runClaimOfflineEarnings() Net.call("REQUEST_CLAIM_ALL")      end
function Economy.runAutoClaimGroupReward() Net.call("CLAIM_REWARD")           end
-- runAutoTreadmillTraining -> mount/dismount + treadmill upgrade remotes

-- =============================================================================
--  ESP / VISUALS                                                    [recovered]
-- =============================================================================
local Esp = {}   -- entries keyed by object -> {Highlight=..., Billboard=...}

function Esp.withinRange(pos: Vector3): boolean
    local root = getRoot()
    return root ~= nil and (root.Position - pos).Magnitude <= Config.EspDistance
end

function Esp.drawEspAt(obj, label, color) --[[ BillboardGui + Highlight ]] end

function Esp.runEsp()
    while true do
        Esp.clearAll()
        if Config.EspWorldEggs  then Esp.collectEggEsp()     end
        if Config.EspCarriedEggs then Esp.collectCarriedEsp() end
        if Config.EspPets       then Esp.collectPetEsp()     end
        if Config.EspGuards     then Esp.collectGuardEsp()   end
        if Config.EspMachines   then Esp.collectMachineEsp() end
        if Config.EspPlots      then Esp.collectPlotEsp()    end
        if Config.EspPlayers    then Esp.collectPlayerEsp()  end
        RunService.RenderStepped:Wait()
    end
end

-- =============================================================================
--  MOVEMENT / RENDER EXPLOITS                                       [recovered]
-- =============================================================================
local Movement = {}
function Movement.applyFpsBoost()  --[[ set_fps_cap + strip Lighting/effects ]] end
function Movement.applyRendering() --[[ toggle Workspace 3D render off        ]] end
function Movement.tryTeleportTo(pos: Vector3) --[[ CFrame/tween/queue path    ]] end
-- Fly, NoClip, InfJump, WalkSpeed/JumpPower overrides bound to Humanoid + input.

-- Anti-AFK: defeats the idle kick via VirtualUser (recovered flow).
local VirtualUser = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- Anti-Gameplay-Pause: suppress RobloxNetworkPauseNotification (setEffectEnabled).

-- =============================================================================
--  SERVER HOP / RECONNECT                                           [recovered]
-- =============================================================================
local Hop = {}
local SERVER_LIST_URL =
    "https://games.roblox.com/v1/games/%d/servers/Public"
    .. "?sortOrder=Asc&excludeFullGames=true&limit=100"

function Hop.fetchServerPage(cursor: string?)
    local url = string.format(SERVER_LIST_URL, game.PlaceId)
    if cursor then url ..= "&cursor=" .. cursor end
    return HttpService:JSONDecode((game :: any):HttpGet(url))
end

function Hop.pickHopTargets()
    -- pages through servers, skips full ones and already-visited JobIds
    local page = Hop.fetchServerPage()
    for _, s in ipairs(page.data) do
        if s.playing < s.maxPlayers and not Hop.visited[s.id] then
            return s.id
        end
    end
    return nil
end

function Hop.serverHop()
    local jobId = Hop.pickHopTargets()
    if jobId then
        -- re-queue this same script into the next server, then teleport
        if syn and syn.queue_on_teleport then
            syn.queue_on_teleport(
                'loadstring(game:HttpGet("' ..
                "https://raw.githubusercontent.com/joustingmatch/Ouroboros/main/games/stealanegg.lua" ..
                '"))()')
        end
        TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
    else
        warn("Server hop failed, retrying in 10s")
    end
end

function Hop.request(reason: string) --[[ arms serverHop per HopMode/HopValue ]] end

-- Auto Reconnect: on TeleportInitFailed / disconnect -> rejoinServer().

-- =============================================================================
--  WEBHOOK TELEMETRY  (opt-in -- streams identity + stats off client)  [recovered]
-- =============================================================================
local Webhook = {}

function Webhook.httpPost(url: string, body: string)
    local req = (syn and syn.request) or (http and http.request) or request
    req({
        Url = url, Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = body,
    })
end

function Webhook.buildSummaryEmbed()
    -- reports player identity, current server JobId, and session counters
    return {
        title = "Session Summary",
        description = string.format(
            "**Player** `%s`\n**Server** `%s`\n**Runtime** `%s`",
            string.format("%s [%s]", LocalPlayer.Name, LocalPlayer.UserId),
            game.JobId,
            Webhook.formatElapsed()),
        fields = {
            { name = "Eggs stolen",   value = string.format("**%d**", Steal.eggsStolen),  inline = true },
            { name = "Pets obtained", value = string.format("**%d**", Steal.petsObtained), inline = true },
            { name = "Rebirths",      value = string.format("**%d**", Steal.rebirths),     inline = true },
        },
    }
end

function Webhook.sendWebhookEmbed(embed)
    if not Config.WebhookEnabled or Config.WebhookUrl == "" then return end
    local content = Config.WebhookPingId ~= "" and ("<@" .. Config.WebhookPingId .. ">") or nil
    Webhook.httpPost(Config.WebhookUrl,
        HttpService:JSONEncode({ content = content, embeds = { embed } }))
end

function Webhook.runWebhookSummary()   -- fires every Config.WebhookInterval minutes
    while true do
        Webhook.sendWebhookEmbed(Webhook.buildSummaryEmbed())
        task.wait((Config.WebhookInterval or 5) * 60)
    end
end
-- Also: disconnect alerts and egg-spawn alerts (WebhookDisconnectAlerts /
-- WebhookEggSpawns) with the same POST path.

-- =============================================================================
--  BOOTSTRAP  (what runs on execute)                                [recovered]
-- =============================================================================
-- 1. Pull the UI library + SaveManager/ThemeManager live from GitHub:
--      loadstring(game:HttpGet(
--        "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/Library.lua"))()
-- 2. Build the tabbed menu (Features / Movement / Visuals / Performance /
--    Webhooks / Socials / Donations / FAQ) and bind Config to the widgets.
-- 3. Spawn the always-on loops:
local function main()
    task.spawn(Steal.runAutoSteal)
    task.spawn(Economy.runAutoSellPets)
    task.spawn(Economy.runAutoFusePets)
    task.spawn(Esp.runEsp)
    task.spawn(Webhook.runWebhookSummary)
    -- ...plus every other runAuto* / claim / hop loop, each gated by its toggle.
end

return main
