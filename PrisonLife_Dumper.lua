-- ============================================================
--  PrisonLife_Dumper.lua  –  Focused dump of Prison Life (155615604)
--
--  Run this in Prison Life with any executor. It writes a single
--  human-readable report with everything Nexus V2 needs to add or
--  verify features:
--
--    - Every remote in the game (RemoteEvent / RemoteFunction /
--      UnreliableRemoteEvent) with a ready-to-use call snippet.
--    - The workspace.Remote folder (TeamEvent, ItemHandler, arrest
--      remotes, …) called out specifically.
--    - The full workspace.Prison_ITEMS.giver list (every gun / item
--      you can pick up) with its world position.
--    - Teams + their BrickColors (for the Team Changer).
--    - Tools found in the giver tree and in player backpacks/character.
--    - Key spawn / landmark CFrames (for the Teleports menu).
--
--  Output goes to:  NexusDumps/PrisonLife_Dump.txt   (writefile)
--  and to the clipboard (setclipboard) and the console, so nothing
--  is lost. Paste it back and it can be wired straight into Nexus.
--
--  Reads only what the executor can already reach on this client.
--  True server Scripts (ServerScriptService / ServerStorage) are
--  never sent to the client and cannot be dumped from here.
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = workspace
local Teams             = game:GetService("Teams")
local StarterGui        = game:GetService("StarterGui")

-- ── Resolve executor globals safely (names vary between executors) ──
local getgenv_fn      = getgenv or function() return _G end
local ENV             = getgenv_fn()
local setclipboard_fn = rawget(ENV, "setclipboard") or setclipboard
                        or rawget(ENV, "toclipboard") or toclipboard
                        or rawget(ENV, "set_clipboard") or set_clipboard
local writefile_fn    = rawget(ENV, "writefile") or writefile
local makefolder_fn   = rawget(ENV, "makefolder") or makefolder
local isfolder_fn     = rawget(ENV, "isfolder") or isfolder

local ALLOWED_PLACES = {
    [155615604] = true,       -- Prison Life
    [135564683255158] = true, -- Prison Life (VC / voice chat)
}

-- ── Report buffer ─────────────────────────────────────────
local out = {}
local function line(s) out[#out + 1] = s == nil and "" or tostring(s) end
local function header(s)
    line("")
    line("============================================================")
    line("  " .. s)
    line("============================================================")
end

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = 6 })
    end)
end

-- Full dotted path of an instance.
local function fullPath(inst)
    if not inst then return "nil" end
    local ok, path = pcall(function() return inst:GetFullName() end)
    if ok and path and path ~= "" then return path end
    local parts, cur = {}, inst
    while cur do
        table.insert(parts, 1, cur.Name)
        local okp, p = pcall(function() return cur.Parent end)
        if not okp then break end
        cur = p
    end
    return table.concat(parts, ".")
end

-- Copy-pasteable indexed reference, e.g. game:GetService("Workspace").Remote.TeamEvent
local function pathExpr(inst)
    local parts, cur = {}, inst
    while cur and cur ~= game do
        local name = cur.Name
        if name:match("^[%a_][%w_]*$") then
            table.insert(parts, 1, "." .. name)
        else
            table.insert(parts, 1, ('["%s"]'):format(name:gsub('"', '\\"')))
        end
        local okp, p = pcall(function() return cur.Parent end)
        if not okp then break end
        cur = p
    end
    if #parts == 0 then return fullPath(inst) end
    local first = parts[1]:gsub("^%.", "")
    parts[1] = ('game:GetService("%s")'):format(first)
    return table.concat(parts, "")
end

local function vecStr(v)
    if typeof(v) ~= "Vector3" then return tostring(v) end
    return ("%.3f, %.3f, %.3f"):format(v.X, v.Y, v.Z)
end

-- Best-effort world position of an instance (Part / Model / Folder).
local function positionOf(inst)
    if not inst then return nil end
    if inst:IsA("BasePart") then return inst.Position end
    local ok, prim = pcall(function() return inst.PrimaryPart end)
    if ok and prim then return prim.Position end
    local bp = inst:FindFirstChildWhichIsA("BasePart", true)
    if bp then return bp.Position end
    return nil
end

-- ── 0. Environment banner ─────────────────────────────────
header("PRISON LIFE DUMP")
line("PlaceId : " .. tostring(game.PlaceId))
line("JobId   : " .. tostring(game.JobId))
line("Players : " .. tostring(#Players:GetPlayers()) .. " online")
line("Dumped  : client-reachable objects only")

if not ALLOWED_PLACES[game.PlaceId] then
    line("")
    line("!! WARNING: this is not a known Prison Life PlaceId.")
    line("!! The dump will still run but paths may not match Prison Life.")
end

-- ── 1. All remotes in the game ────────────────────────────
local REMOTE_CLASSES = {
    RemoteEvent           = "FireServer",
    UnreliableRemoteEvent = "FireServer",
    RemoteFunction        = "InvokeServer",
}

header("ALL REMOTES (client-reachable)")
do
    local seen, count = {}, 0
    local roots = { Workspace, ReplicatedStorage, Players.LocalPlayer }
    -- also scan ReplicatedFirst / Lighting in case remotes hide there
    pcall(function() table.insert(roots, game:GetService("ReplicatedFirst")) end)

    for _, root in ipairs(roots) do
        if root then
            local ok, descendants = pcall(function() return root:GetDescendants() end)
            if ok then
                for _, d in ipairs(descendants) do
                    local call = REMOTE_CLASSES[d.ClassName]
                    if call and not seen[d] then
                        seen[d] = true
                        count = count + 1
                        line("")
                        line(("[%s] %s"):format(d.ClassName, fullPath(d)))
                        line(("   %s:%s(...)"):format(pathExpr(d), call))
                    end
                end
            end
        end
    end

    if count == 0 then
        line("(none found on the paths scanned)")
    else
        line("")
        line("total remotes: " .. count)
    end
end

-- ── 2. workspace.Remote folder (Prison Life's main remotes) ──
header("workspace.Remote  (core Prison Life remotes)")
do
    local remoteFolder = Workspace:FindFirstChild("Remote")
    if not remoteFolder then
        line("(workspace.Remote not found)")
    else
        for _, r in ipairs(remoteFolder:GetChildren()) do
            local call = REMOTE_CLASSES[r.ClassName] or "(" .. r.ClassName .. ")"
            line(("- %-22s %s  ->  %s:%s(...)"):format(r.Name, r.ClassName, pathExpr(r), call))
        end
    end
end

-- ── 3. ReplicatedStorage remotes (meleeEvent lives here) ──
header("ReplicatedStorage remotes (top-level)")
do
    local any = false
    for _, r in ipairs(ReplicatedStorage:GetChildren()) do
        if REMOTE_CLASSES[r.ClassName] then
            any = true
            line(("- %-22s %s  ->  %s:%s(...)"):format(
                r.Name, r.ClassName, pathExpr(r), REMOTE_CLASSES[r.ClassName]))
        end
    end
    if not any then line("(no top-level remotes in ReplicatedStorage)") end
end

-- ── 4. Prison_ITEMS givers (guns / items you can pick up) ──
header("workspace.Prison_ITEMS.giver  (all pickups + positions)")
do
    local prisonItems = Workspace:FindFirstChild("Prison_ITEMS")
    local giver = prisonItems and prisonItems:FindFirstChild("giver")
    if not giver then
        line("(workspace.Prison_ITEMS.giver not found)")
    else
        local items = giver:GetChildren()
        table.sort(items, function(a, b) return a.Name < b.Name end)
        for _, item in ipairs(items) do
            local pos = positionOf(item)
            line(("- %-24s  pos: %s"):format(item.Name, pos and vecStr(pos) or "?"))
        end
        line("")
        line("Lua table of giver positions (drop into a Teleports menu):")
        line("local GUN_GIVERS = {")
        for _, item in ipairs(items) do
            local pos = positionOf(item)
            if pos then
                line(('    ["%s"] = Vector3.new(%.3f, %.3f, %.3f),'):format(
                    item.Name:gsub('"', '\\"'), pos.X, pos.Y, pos.Z))
            end
        end
        line("}")
    end
end

-- ── 5. Teams + BrickColors (Team Changer) ─────────────────
header("Teams (name -> TeamColor for TeamEvent)")
do
    local ok, teamList = pcall(function() return Teams:GetTeams() end)
    if ok and teamList and #teamList > 0 then
        for _, t in ipairs(teamList) do
            local colorName = "?"
            pcall(function() colorName = t.TeamColor.Name end)
            line(('- %-14s TeamColor = "%s"'):format(t.Name, colorName))
        end
        line("")
        line('Team change:  workspace.Remote.TeamEvent:FireServer("<TeamColor.Name>")')
    else
        line("(no Teams found)")
    end
end

-- ── 6. Tools (weapons) reachable on the client ────────────
header("Tools found (giver tree + your backpack/character)")
do
    local seen = {}
    local function scanTools(root, label)
        if not root then return end
        local ok, desc = pcall(function() return root:GetDescendants() end)
        if not ok then return end
        for _, d in ipairs(desc) do
            if d:IsA("Tool") and not seen[d.Name] then
                seen[d.Name] = true
                line(("- %-24s (%s)"):format(d.Name, label))
            end
        end
    end
    local lp = Players.LocalPlayer
    scanTools(Workspace:FindFirstChild("Prison_ITEMS"), "Prison_ITEMS")
    scanTools(lp and lp:FindFirstChild("Backpack"), "Backpack")
    scanTools(lp and lp.Character, "Character")
    if next(seen) == nil then line("(no Tools reachable right now)") end
end

-- ── 7. Landmarks / spawns (Teleports menu) ────────────────
header("Landmarks & spawns (CFrames for teleports)")
do
    local ok, spawns = pcall(function()
        local t = {}
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("SpawnLocation") then t[#t + 1] = d end
        end
        return t
    end)
    if ok and spawns and #spawns > 0 then
        for _, s in ipairs(spawns) do
            line(("- SpawnLocation %-18s %s"):format(s.Name, vecStr(s.Position)))
        end
    else
        line("(no SpawnLocations found)")
    end

    line("")
    line("Local player position right now:")
    local hrp = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        line("  " .. vecStr(hrp.Position))
        line("  (stand somewhere useful and re-run to capture that spot)")
    else
        line("  (no character loaded)")
    end
end

-- ── Emit report ───────────────────────────────────────────
header("END OF DUMP")
local report = table.concat(out, "\n")

-- console (chunked so long output isn't truncated)
do
    local CHUNK = 3800
    for i = 1, #report, CHUNK do
        print(report:sub(i, i + CHUNK - 1))
    end
end

-- file
local savedPath
if writefile_fn then
    pcall(function()
        if makefolder_fn and isfolder_fn and not isfolder_fn("NexusDumps") then
            makefolder_fn("NexusDumps")
        end
        savedPath = "NexusDumps/PrisonLife_Dump.txt"
        writefile_fn(savedPath, report)
    end)
end

-- clipboard
local copied = false
if setclipboard_fn then
    copied = pcall(function() setclipboard_fn(report) end) and true or false
end

notify("Prison Life Dump",
    (savedPath and ("saved " .. savedPath) or "printed to console")
    .. (copied and " + clipboard" or ""))

print("[PrisonLife Dumper] done."
    .. (savedPath and (" file: " .. savedPath) or "")
    .. (copied and " (also copied to clipboard)" or ""))

return report
