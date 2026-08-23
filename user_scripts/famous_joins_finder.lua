-- ============================================================
--  famous_joins_finder.lua  –  "Famous People / Joins" finder GUI
--
--  A draggable GUI that lists only *famous* players (high-follower
--  devs, celebrities, etc.) who currently have their JOINS turned ON
--  (i.e. their in-game presence is public and joinable).
--
--  How "joins on / off" is detected:
--    Roblox exposes each user's presence through the presence API.
--    If a user has their join / presence privacy set so that others
--    can follow them, the API returns their gameId + placeId and the
--    server is joinable. If they turn joins OFF (privacy set to
--    "no one" / friends only that you aren't, or presence hidden),
--    the API returns NO gameId -> we simply don't list them.
--
--  How "famous" is decided:
--    Every candidate's follower count is fetched. Only users at or
--    above CONFIG.MinFollowers are treated as famous. A curated seed
--    list of well-known devs is also included and can be edited.
--
--  Candidate sources (deduped):
--    1. CONFIG.FamousList  (hand-picked famous userIds, editable)
--    2. Your friends list  (catches famous people you follow)
--    3. Players in your current server
--
--  Clicking a listed player teleports you into their server via
--  TeleportService:TeleportToPlayerInstance (the normal "join" path).
--
--  Works on executors exposing an HTTP request function
--  (request / http_request / syn.request / fluxus.request ...).
-- ============================================================

--// Services
local Players          = game:GetService("Players")
local TeleportService   = game:GetService("TeleportService")
local StarterGui        = game:GetService("StarterGui")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")
local HttpService        = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- ── Config ────────────────────────────────────────────────
local CONFIG = {
    MinFollowers   = 50000,   -- a player must have >= this many followers to count as "famous"
    AutoRefresh    = false,   -- automatically re-scan on an interval
    RefreshEvery   = 30,      -- seconds between auto refreshes
    ScanFriends    = true,    -- include your friends as candidates
    ScanServer     = true,    -- include players in your current server as candidates
    MaxCandidates  = 180,     -- hard cap so we never hammer the web API

    -- Curated famous userIds (editable). The follower check still applies,
    -- so junk IDs here are harmless. Add the devs / celebs you care about.
    FamousList = {
        1,        -- Roblox
        156,      -- builderman
        261,      -- Shedletsky (Telamon)
        13268404, -- example dev slot – replace with your own
    },
}
-- ──────────────────────────────────────────────────────────

--// ── HTTP request wrapper (executor-agnostic) ─────────────
local httpRequest =
    (syn and syn.request)
    or (fluxus and fluxus.request)
    or (http and http.request)
    or http_request
    or request
    or (getgenv and getgenv().request)

local function apiRequest(method, url, body)
    if not httpRequest then return nil, "no http request function available" end
    local opts = {
        Url = url,
        Method = method,
        Headers = { ["Content-Type"] = "application/json" },
    }
    if body ~= nil then opts.Body = HttpService:JSONEncode(body) end
    local ok, res = pcall(httpRequest, opts)
    if not ok then return nil, tostring(res) end
    if not res then return nil, "empty response" end
    local code = res.StatusCode or res.status_code or 0
    if code < 200 or code >= 300 then
        return nil, "http " .. tostring(code)
    end
    local decoded
    local dok = pcall(function()
        decoded = HttpService:JSONDecode(res.Body or res.body or "")
    end)
    if not dok then return nil, "bad json" end
    return decoded
end

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = 5 })
    end)
end

--// ── Roblox web helpers ───────────────────────────────────

-- Follower count for one user.
local function getFollowerCount(userId)
    local data = apiRequest("GET", "https://friends.roblox.com/v1/users/" .. userId .. "/followers/count")
    if data and type(data.count) == "number" then return data.count end
    return nil
end

-- Friends of a user -> array of {id, name}.
local function getFriends(userId)
    local out = {}
    local data = apiRequest("GET", "https://friends.roblox.com/v1/users/" .. userId .. "/friends")
    if data and data.data then
        for _, f in ipairs(data.data) do
            if f.id then out[#out + 1] = { id = f.id, name = f.name or f.displayName } end
        end
    end
    return out
end

-- Batch presence lookup. Returns map userId -> presence entry.
-- presence.userPresenceType: 0 Offline, 1 Online (website), 2 InGame, 3 InStudio
local function getPresences(userIds)
    local result = {}
    for i = 1, #userIds, 100 do
        local batch = {}
        for j = i, math.min(i + 99, #userIds) do batch[#batch + 1] = userIds[j] end
        local data = apiRequest("POST", "https://presence.roblox.com/v1/presence/users", { userIds = batch })
        if data and data.userPresences then
            for _, p in ipairs(data.userPresences) do
                result[p.userId] = p
            end
        end
    end
    return result
end

-- Batch username / display name lookup. Returns map userId -> {name, displayName}.
local function getUserInfos(userIds)
    local result = {}
    for i = 1, #userIds, 100 do
        local batch = {}
        for j = i, math.min(i + 99, #userIds) do batch[#batch + 1] = userIds[j] end
        local data = apiRequest("POST", "https://users.roblox.com/v1/users",
            { userIds = batch, excludeBannedUsers = false })
        if data and data.data then
            for _, u in ipairs(data.data) do
                result[u.id] = { name = u.name, displayName = u.displayName }
            end
        end
    end
    return result
end

--// ── State ────────────────────────────────────────────────
local scanning = false
local rows = {}        -- current UI rows
local lastResults = {} -- last scan's joinable famous players

--// ── Build candidate pool ─────────────────────────────────
local function collectCandidates()
    local seen, ids = {}, {}
    local function add(id)
        id = tonumber(id)
        if id and not seen[id] and id ~= LocalPlayer.UserId then
            seen[id] = true
            ids[#ids + 1] = id
        end
    end

    for _, id in ipairs(CONFIG.FamousList) do add(id) end

    if CONFIG.ScanServer then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then add(plr.UserId) end
        end
    end

    if CONFIG.ScanFriends then
        for _, f in ipairs(getFriends(LocalPlayer.UserId)) do add(f.id) end
    end

    -- Cap the pool.
    while #ids > CONFIG.MaxCandidates do table.remove(ids) end
    return ids
end

--// ── GUI ──────────────────────────────────────────────────
local COLORS = {
    bg      = Color3.fromRGB(24, 25, 33),
    header  = Color3.fromRGB(34, 36, 48),
    row     = Color3.fromRGB(32, 34, 45),
    rowAlt  = Color3.fromRGB(38, 40, 53),
    accent  = Color3.fromRGB(88, 128, 255),
    good    = Color3.fromRGB(80, 200, 120),
    text    = Color3.fromRGB(235, 237, 245),
    subtext = Color3.fromRGB(160, 165, 180),
}

-- Clean up an old copy if the script is re-run.
pcall(function()
    local old = (gethui and gethui() or game:GetService("CoreGui")):FindFirstChild("FamousJoinsFinder")
    if old then old:Destroy() end
end)

local parentGui = (gethui and gethui()) or game:GetService("CoreGui")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FamousJoinsFinder"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = parentGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 360, 0, 420)
Main.Position = UDim2.new(0.5, -180, 0.5, -210)
Main.BackgroundColor3 = COLORS.bg
Main.BorderSizePixel = 0
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke", Main)
stroke.Color = COLORS.accent
stroke.Thickness = 1
stroke.Transparency = 0.4

-- Header (drag handle)
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundColor3 = COLORS.header
Header.BorderSizePixel = 0
Header.Parent = Main
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 12, 0, 0)
Title.Size = UDim2.new(1, -80, 1, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = "★ Famous Players — Joinable"
Title.TextColor3 = COLORS.text
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -34, 0, 6)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 70, 80)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = COLORS.text
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.Parent = Header
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

-- Status / control bar
local StatusLabel = Instance.new("TextLabel")
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 12, 0, 44)
StatusLabel.Size = UDim2.new(1, -24, 0, 18)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Text = "Ready. Press Refresh to scan."
StatusLabel.TextColor3 = COLORS.subtext
StatusLabel.TextSize = 12
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = Main

local RefreshBtn = Instance.new("TextButton")
RefreshBtn.Size = UDim2.new(0, 100, 0, 26)
RefreshBtn.Position = UDim2.new(0, 12, 0, 66)
RefreshBtn.BackgroundColor3 = COLORS.accent
RefreshBtn.Text = "⟳ Refresh"
RefreshBtn.TextColor3 = COLORS.text
RefreshBtn.Font = Enum.Font.GothamSemibold
RefreshBtn.TextSize = 13
RefreshBtn.Parent = Main
Instance.new("UICorner", RefreshBtn).CornerRadius = UDim.new(0, 6)

local AutoBtn = Instance.new("TextButton")
AutoBtn.Size = UDim2.new(0, 110, 0, 26)
AutoBtn.Position = UDim2.new(0, 120, 0, 66)
AutoBtn.BackgroundColor3 = COLORS.row
AutoBtn.Text = "Auto: OFF"
AutoBtn.TextColor3 = COLORS.subtext
AutoBtn.Font = Enum.Font.GothamSemibold
AutoBtn.TextSize = 13
AutoBtn.Parent = Main
Instance.new("UICorner", AutoBtn).CornerRadius = UDim.new(0, 6)

-- Follower threshold display / cycle
local FollowerBtn = Instance.new("TextButton")
FollowerBtn.Size = UDim2.new(0, 108, 0, 26)
FollowerBtn.Position = UDim2.new(1, -120, 0, 66)
FollowerBtn.BackgroundColor3 = COLORS.row
FollowerBtn.Text = "≥ 50k"
FollowerBtn.TextColor3 = COLORS.subtext
FollowerBtn.Font = Enum.Font.GothamSemibold
FollowerBtn.TextSize = 13
FollowerBtn.Parent = Main
Instance.new("UICorner", FollowerBtn).CornerRadius = UDim.new(0, 6)

-- Scrolling list
local List = Instance.new("ScrollingFrame")
List.Name = "List"
List.Position = UDim2.new(0, 10, 0, 102)
List.Size = UDim2.new(1, -20, 1, -112)
List.BackgroundColor3 = Color3.fromRGB(18, 19, 26)
List.BorderSizePixel = 0
List.ScrollBarThickness = 5
List.ScrollBarImageColor3 = COLORS.accent
List.CanvasSize = UDim2.new(0, 0, 0, 0)
List.AutomaticCanvasSize = Enum.AutomaticSize.Y
List.Parent = Main
Instance.new("UICorner", List).CornerRadius = UDim.new(0, 8)

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 4)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Parent = List
local ListPad = Instance.new("UIPadding", List)
ListPad.PaddingTop = UDim.new(0, 4)
ListPad.PaddingLeft = UDim.new(0, 4)
ListPad.PaddingRight = UDim.new(0, 4)

--// ── Draggable ────────────────────────────────────────────
do
    local dragging, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
end

--// ── Row rendering ────────────────────────────────────────
local function clearRows()
    for _, r in ipairs(rows) do r:Destroy() end
    rows = {}
end

local function fmtNum(n)
    if n >= 1e6 then return string.format("%.1fM", n / 1e6) end
    if n >= 1e3 then return string.format("%.1fk", n / 1e3) end
    return tostring(n)
end

local function makeRow(entry, index)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, -8, 0, 52)
    Row.BackgroundColor3 = (index % 2 == 0) and COLORS.rowAlt or COLORS.row
    Row.BorderSizePixel = 0
    Row.LayoutOrder = index
    Row.Parent = List
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 6)

    local Name = Instance.new("TextLabel")
    Name.BackgroundTransparency = 1
    Name.Position = UDim2.new(0, 10, 0, 6)
    Name.Size = UDim2.new(1, -90, 0, 20)
    Name.Font = Enum.Font.GothamSemibold
    Name.Text = (entry.displayName or entry.name or ("User " .. entry.id))
    Name.TextColor3 = COLORS.text
    Name.TextSize = 14
    Name.TextXAlignment = Enum.TextXAlignment.Left
    Name.TextTruncate = Enum.TextTruncate.AtEnd
    Name.Parent = Row

    local Sub = Instance.new("TextLabel")
    Sub.BackgroundTransparency = 1
    Sub.Position = UDim2.new(0, 10, 0, 26)
    Sub.Size = UDim2.new(1, -90, 0, 18)
    Sub.Font = Enum.Font.Gotham
    Sub.Text = "@" .. (entry.name or "?") .. "  •  " .. fmtNum(entry.followers) .. " followers"
    Sub.TextColor3 = COLORS.subtext
    Sub.TextSize = 12
    Sub.TextXAlignment = Enum.TextXAlignment.Left
    Sub.TextTruncate = Enum.TextTruncate.AtEnd
    Sub.Parent = Row

    local JoinBtn = Instance.new("TextButton")
    JoinBtn.Size = UDim2.new(0, 66, 0, 30)
    JoinBtn.Position = UDim2.new(1, -74, 0.5, -15)
    JoinBtn.BackgroundColor3 = COLORS.good
    JoinBtn.Text = "Join"
    JoinBtn.TextColor3 = Color3.fromRGB(15, 30, 20)
    JoinBtn.Font = Enum.Font.GothamBold
    JoinBtn.TextSize = 13
    JoinBtn.Parent = Row
    Instance.new("UICorner", JoinBtn).CornerRadius = UDim.new(0, 6)

    JoinBtn.MouseButton1Click:Connect(function()
        JoinBtn.Text = "..."
        local ok, err = pcall(function()
            TeleportService:TeleportToPlayerInstance(entry.placeId, entry.gameId, LocalPlayer)
        end)
        if not ok then
            JoinBtn.Text = "Failed"
            notify("Join failed", tostring(err))
            task.wait(1.5)
            JoinBtn.Text = "Join"
        end
    end)

    rows[#rows + 1] = Row
end

--// ── The scan ─────────────────────────────────────────────
local function runScan()
    if scanning then return end
    scanning = true
    RefreshBtn.Text = "Scanning..."
    StatusLabel.Text = "Collecting candidates..."

    task.spawn(function()
        local candidates = collectCandidates()
        StatusLabel.Text = "Checking followers for " .. #candidates .. " players..."

        -- Filter to famous (high follower) users first.
        local famous = {}
        for _, id in ipairs(candidates) do
            local fc = getFollowerCount(id)
            if fc and fc >= CONFIG.MinFollowers then
                famous[#famous + 1] = { id = id, followers = fc }
            end
            task.wait(0.03) -- gentle on the web API
        end

        if #famous == 0 then
            clearRows()
            lastResults = {}
            StatusLabel.Text = "No famous players found in candidate pool."
            RefreshBtn.Text = "⟳ Refresh"
            scanning = false
            return
        end

        -- Presence: only those with joins ON (public, joinable game) survive.
        local ids = {}
        for _, f in ipairs(famous) do ids[#ids + 1] = f.id end
        StatusLabel.Text = "Checking who has joins ON..."
        local presences = getPresences(ids)
        local infos = getUserInfos(ids)

        local joinable = {}
        for _, f in ipairs(famous) do
            local p = presences[f.id]
            -- InGame (2) AND a gameId returned => joins are ON and server is joinable.
            if p and p.userPresenceType == 2 and p.gameId and p.placeId then
                local info = infos[f.id] or {}
                joinable[#joinable + 1] = {
                    id          = f.id,
                    followers   = f.followers,
                    name        = info.name,
                    displayName = info.displayName,
                    gameId      = p.gameId,
                    placeId     = p.placeId,
                    lastLocation = p.lastLocation,
                }
            end
        end

        -- Sort by followers, descending (biggest names first).
        table.sort(joinable, function(a, b) return a.followers > b.followers end)

        clearRows()
        for i, entry in ipairs(joinable) do makeRow(entry, i) end
        lastResults = joinable

        StatusLabel.Text = string.format(
            "%d famous player(s) with joins ON  (of %d famous, %d scanned)",
            #joinable, #famous, #candidates)
        RefreshBtn.Text = "⟳ Refresh"
        scanning = false
    end)
end

--// ── Button wiring ────────────────────────────────────────
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)
RefreshBtn.MouseButton1Click:Connect(runScan)

AutoBtn.MouseButton1Click:Connect(function()
    CONFIG.AutoRefresh = not CONFIG.AutoRefresh
    AutoBtn.Text = "Auto: " .. (CONFIG.AutoRefresh and "ON" or "OFF")
    AutoBtn.TextColor3 = CONFIG.AutoRefresh and COLORS.text or COLORS.subtext
    AutoBtn.BackgroundColor3 = CONFIG.AutoRefresh and COLORS.accent or COLORS.row
end)

local FOLLOWER_STEPS = { 10000, 50000, 100000, 500000, 1000000 }
FollowerBtn.MouseButton1Click:Connect(function()
    -- cycle to next threshold
    local idx = 1
    for i, v in ipairs(FOLLOWER_STEPS) do
        if v == CONFIG.MinFollowers then idx = i break end
    end
    idx = (idx % #FOLLOWER_STEPS) + 1
    CONFIG.MinFollowers = FOLLOWER_STEPS[idx]
    FollowerBtn.Text = "≥ " .. fmtNum(CONFIG.MinFollowers)
end)
FollowerBtn.Text = "≥ " .. fmtNum(CONFIG.MinFollowers)

--// ── Auto refresh loop ────────────────────────────────────
task.spawn(function()
    local acc = 0
    while ScreenGui.Parent do
        task.wait(1)
        if CONFIG.AutoRefresh and not scanning then
            acc = acc + 1
            if acc >= CONFIG.RefreshEvery then
                acc = 0
                runScan()
            end
        else
            acc = 0
        end
    end
end)

--// ── Startup ──────────────────────────────────────────────
if not httpRequest then
    StatusLabel.Text = "⚠ Your executor has no HTTP request function."
    StatusLabel.TextColor3 = Color3.fromRGB(230, 120, 120)
    notify("Famous Joins Finder", "No HTTP request function found — can't query Roblox APIs.")
else
    notify("Famous Joins Finder", "Loaded. Press Refresh to scan for joinable famous players.")
    runScan()
end
