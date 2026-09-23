--!strict
--[[
	Sentinel Punish — enforcement actions + persistent bans.
	Actions escalate: log -> warn -> rollback -> kick -> ban.
	DryRun turns every enforcing action into a log so you can tune safely.
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.SentinelShared.Config)
local Logger = require(script.Parent.Logger)
local Profile = require(script.Parent.Profile)

local Punish = {}

local banStore = DataStoreService:GetDataStore(Config.Bans.DataStoreName)

type BanRecord = { reason: string, at: number, until_: number } -- until_ == 0 => permanent

---------------------------------------------------------------------------
-- Ban persistence
---------------------------------------------------------------------------
local banCache: { [number]: BanRecord? } = {}

function Punish.isBanned(userId: number): (boolean, string?)
	local record = banCache[userId]
	if record == nil then
		local ok, value = pcall(function()
			return banStore:GetAsync(tostring(userId))
		end)
		if ok and value then
			record = value :: BanRecord
			banCache[userId] = record
		else
			banCache[userId] = nil
			return false, nil
		end
	end
	if not record then
		return false, nil
	end
	if record.until_ ~= 0 and os.time() >= record.until_ then
		-- expired
		banCache[userId] = nil
		pcall(function()
			banStore:RemoveAsync(tostring(userId))
		end)
		return false, nil
	end
	return true, record.reason
end

function Punish.ban(player: Player, reason: string, durationSeconds: number?)
	local dur = durationSeconds or Config.Bans.DefaultDurationSeconds
	local record: BanRecord = {
		reason = reason,
		at = os.time(),
		until_ = dur > 0 and (os.time() + dur) or 0,
	}
	if Config.DryRun then
		Logger.warn(("[DRYRUN] would BAN %s (%d): %s"):format(player.Name, player.UserId, reason))
		return
	end
	banCache[player.UserId] = record
	task.spawn(function()
		pcall(function()
			banStore:SetAsync(tostring(player.UserId), record)
		end)
	end)
	Logger.warn(("BAN %s (%d): %s"):format(player.Name, player.UserId, reason))
	player:Kick(Config.Bans.KickMessagePrefix .. reason)
end

function Punish.unban(userId: number)
	banCache[userId] = nil
	pcall(function()
		banStore:RemoveAsync(tostring(userId))
	end)
end

---------------------------------------------------------------------------
-- Live enforcement
---------------------------------------------------------------------------
function Punish.kick(player: Player, reason: string)
	if Config.DryRun then
		Logger.warn(("[DRYRUN] would KICK %s: %s"):format(player.Name, reason))
		return
	end
	Logger.warn(("KICK %s: %s"):format(player.Name, reason))
	player:Kick(Config.Bans.KickMessagePrefix .. reason)
end

-- Snap a character back to its last server-validated position and kill velocity.
function Punish.rollback(player: Player, reason: string)
	local prof = Profile.get(player)
	local character = player.Character
	if not prof or not character then
		return
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp or not hrp:IsA("BasePart") then
		return
	end
	if Config.DryRun then
		Logger.warn(("[DRYRUN] would ROLLBACK %s: %s"):format(player.Name, reason))
		return
	end
	local target = prof.lastGoodCFrame
	if target then
		hrp.CFrame = target
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
		Logger.debug(("ROLLBACK %s: %s"):format(player.Name, reason))
	end
end

-- Dispatch a threshold action by name. Returns the action actually taken.
function Punish.apply(player: Player, action: string, reason: string): string
	if not Config.Enabled then
		return "log"
	end
	if action == "warn" then
		Logger.info(("WARN %s: %s"):format(player.Name, reason))
	elseif action == "rollback" then
		Punish.rollback(player, reason)
	elseif action == "kick" then
		Punish.kick(player, reason)
	elseif action == "ban" then
		Punish.ban(player, reason, nil)
	end
	return action
end

return Punish
