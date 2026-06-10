-- ================================================================
--  ChatForce_Server.lua  —  inject as a SERVER Script (once)
--  This is what makes the bubble + chat visible to EVERYONE.
-- ================================================================
local RS      = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Chat    = game:GetService("Chat")

-- clean up stale bridge
local old = RS:FindFirstChild("ChatForce")
if old then old:Destroy() end

local Bridge      = Instance.new("RemoteFunction")
Bridge.Name       = "ChatForce"
Bridge.Parent     = RS

Bridge.OnServerInvoke = function(_, targetName, message, fakeName)
    local plr  = Players:FindFirstChild(tostring(targetName or ""))
    local char = plr and plr.Character
    if not char then return "player not found" end

    fakeName = (type(fakeName)=="string" and fakeName~="") and fakeName or plr.DisplayName

    -- ✓ Bubble above their head, visible to ALL players
    -- ✓ Appears in legacy chat as that player
    Chat:Chat(char, message, Enum.ChatColor.White)

    -- Also fire every chat RemoteEvent in the game via FireAllClients
    -- so the game's own chat UI shows it with the spoofed name
    local CKWS = {"chat","say","speak","voice","message","talk","text","mic"}
    local fired = 0
    for _, v in game:GetDescendants() do
        if v:IsA("RemoteEvent") then
            local n = v.Name:lower()
            for _, kw in ipairs(CKWS) do
                if n:find(kw) then
                    pcall(function() v:FireAllClients(fakeName, message) end)
                    pcall(function() v:FireAllClients(plr.Name, message, fakeName) end)
                    pcall(function() v:FireAllClients({Name=fakeName, Message=message}) end)
                    fired = fired + 1
                    break
                end
            end
        end
    end

    return "OK — bubble + "..fired.." chat remotes fired as \""..fakeName.."\""
end

warn("[ChatForce] Server ready")
