--!strict
--[[
	Sentinel Telemetry — in-memory event ring buffer + optional Discord webhook.
	The ring buffer feeds an in-game admin panel; the webhook alerts staff to
	high-severity actions. HttpService must be enabled for webhooks.
]]

local HttpService = game:GetService("HttpService")
local Config = require(game:GetService("ReplicatedStorage").SentinelShared.Config)
local Logger = require(script.Parent.Logger)

local Telemetry = {}

export type Event = {
	at: number,
	userId: number,
	name: string,
	category: string,
	detail: string,
	score: number,
	action: string?,
}

local ring: { Event } = {}

function Telemetry.record(event: Event)
	table.insert(ring, event)
	local overflow = #ring - Config.Telemetry.RingBufferSize
	if overflow > 0 then
		for _ = 1, overflow do
			table.remove(ring, 1)
		end
	end
end

function Telemetry.recent(): { Event }
	return ring
end

local ACTION_RANK = { log = 0, warn = 1, rollback = 1, kick = 2, ban = 3 }

-- Fire-and-forget Discord alert for actions at/above the configured severity.
function Telemetry.webhook(event: Event)
	local url = Config.Telemetry.DiscordWebhook
	if url == "" then
		return
	end
	local minRank = ACTION_RANK[Config.Telemetry.WebhookMinAction] or 2
	if (ACTION_RANK[event.action or "log"] or 0) < minRank then
		return
	end
	task.spawn(function()
		local payload = {
			content = ("**Sentinel** `%s` on **%s** (`%d`)\n> %s — %s\nscore: `%.1f`"):format(
				string.upper(event.action or "flag"),
				event.name,
				event.userId,
				event.category,
				event.detail,
				event.score
			),
		}
		local ok, err = pcall(function()
			HttpService:PostAsync(url, HttpService:JSONEncode(payload), Enum.HttpContentType.ApplicationJson)
		end)
		if not ok then
			Logger.warn("webhook post failed: " .. tostring(err))
		end
	end)
end

return Telemetry
