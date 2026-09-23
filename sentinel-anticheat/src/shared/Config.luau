--!strict
--[[
	Sentinel Anti-Cheat — Shared Configuration
	---------------------------------------------------------------------------
	Every tunable lives here so games can adapt Sentinel without touching logic.
	These values are the "sane defaults"; override per-game as needed.

	Guiding principle: the SERVER is the only authority. Client-side numbers in
	here are hints/friction only — never trust them for a ban decision.
]]

export type ActionKind = "log" | "warn" | "rollback" | "kick" | "ban"

local Config = {
	-- Master switch. Set false to disable all enforcement (detection still logs).
	Enabled = true,

	-- When true, Sentinel never kicks/bans — it only logs what it *would* do.
	-- Run every new game like this for a few days, tune thresholds, THEN enforce.
	DryRun = true,

	-- How verbose server logging is: "silent" | "warn" | "info" | "debug"
	LogLevel = "info",

	---------------------------------------------------------------------------
	-- Suspicion scoring
	---------------------------------------------------------------------------
	-- Every detection adds `weight` to a player's rolling suspicion score.
	-- Score decays over time so isolated false positives never accumulate into
	-- a ban. Actions fire when the score crosses a threshold.
	Score = {
		DecayPerSecond = 2.0, -- points bled off each second
		Thresholds = {
			-- score >= value  ->  action
			{ at = 8, action = "warn" :: ActionKind },
			{ at = 25, action = "kick" :: ActionKind },
			{ at = 60, action = "ban" :: ActionKind },
		},
		-- Hard cap so a single frame of chaos can't fling someone past `ban`.
		MaxGainPerSecond = 40,
	},

	---------------------------------------------------------------------------
	-- Movement (server-authoritative position validation)
	---------------------------------------------------------------------------
	Movement = {
		Enabled = true,
		SampleHz = 12, -- how often per second the server samples each character

		-- Horizontal speed allowance = WalkSpeed * Multiplier + FlatBonus (studs/s)
		SpeedMultiplier = 1.35, -- headroom for latency jitter & downhill sliding
		SpeedFlatBonus = 12, -- absolute cushion for small maps / lag spikes

		-- A single-sample jump farther than this (studs) is treated as a teleport.
		MaxTeleportDistance = 60,

		-- Vertical: sustained "hover" (near-zero Y velocity while airborne) => fly.
		HoverVelocityEpsilon = 3, -- |VelocityY| under this counts as hovering
		MaxAirborneHoverTime = 0.6, -- seconds of hovering-in-air before flagging

		-- Noclip: raycast the travel segment; passing through a collidable solid
		-- that the humanoid could not have legally moved through is a violation.
		NoclipCheck = true,

		-- Grace windows where movement checks are relaxed / skipped:
		SpawnGracePeriod = 3.0, -- seconds after (re)spawn
		TeleportGracePeriod = 1.0, -- seconds after a server-authorized teleport

		Weights = {
			Speed = 6,
			Teleport = 10,
			Fly = 8,
			Noclip = 12,
			InfiniteJump = 4,
		},
	},

	---------------------------------------------------------------------------
	-- Character / Humanoid tampering
	---------------------------------------------------------------------------
	Character = {
		Enabled = true,

		-- Server-side ceilings. Anything the server itself sets above these is
		-- allowed via the exemption API; anything else is corrected + flagged.
		MaxWalkSpeed = 40,
		MaxJumpPower = 60, -- (or JumpHeight; both are checked)
		MaxHipHeight = 6,

		-- Re-assert humanoid props to server truth when tampering is seen.
		Correct = true,

		-- God-mode heuristic: health that refuses to drop after authorized damage.
		GodModeCheck = true,

		Weights = {
			WalkSpeed = 5,
			JumpPower = 4,
			HipHeight = 4,
			GodMode = 8,
		},
	},

	---------------------------------------------------------------------------
	-- Remotes (rate limiting + argument validation)
	---------------------------------------------------------------------------
	Remotes = {
		Enabled = true,

		-- Default budget for any remote registered through Sentinel's Net layer.
		DefaultRatePerMinute = 240, -- 4/sec average
		DefaultBurst = 20, -- token bucket depth

		-- Reject payloads larger than this many "units" (strings/tables counted).
		MaxArgDepth = 6,
		MaxStringLength = 4000,

		Weights = {
			RateLimit = 3,
			BadArgs = 5,
			UnknownRemote = 6,
		},
	},

	---------------------------------------------------------------------------
	-- Stats / economy (server-authoritative value guarding)
	---------------------------------------------------------------------------
	Stats = {
		Enabled = true,

		-- Watched values must only move through Sentinel.Stats API. A raw change
		-- that Sentinel didn't author is treated as external tampering.
		DetectExternalWrites = true,

		-- Reject economy gains faster than this many units/second (anti dupe/inject).
		MaxGainPerSecond = 100000,

		-- Currency can never go below this.
		FloorValue = 0,

		Weights = {
			ExternalWrite = 10,
			ImpossibleRate = 8,
			Underflow = 6,
		},
	},

	---------------------------------------------------------------------------
	-- Client heartbeat / integrity (FRICTION ONLY — client is untrusted)
	---------------------------------------------------------------------------
	Client = {
		Enabled = true,

		HeartbeatInterval = 2.0, -- client pings server this often
		MissedHeartbeatsToFlag = 4, -- missing client script => tampering signal

		Weights = {
			MissingClient = 4, -- low weight: laggy players trip this too
			IntegrityReport = 5, -- client self-reported a known exploit global
		},
	},

	---------------------------------------------------------------------------
	-- Telemetry
	---------------------------------------------------------------------------
	Telemetry = {
		-- Discord webhook for alerts. Leave "" to disable. Store the real URL in a
		-- private place, not source control.
		DiscordWebhook = "",

		-- Post to webhook only for actions at or above this severity.
		WebhookMinAction = "kick" :: ActionKind,

		-- Keep the last N events in memory for an in-game admin panel.
		RingBufferSize = 200,
	},

	---------------------------------------------------------------------------
	-- Bans (persisted via DataStore)
	---------------------------------------------------------------------------
	Bans = {
		DataStoreName = "Sentinel_Bans_v1",
		DefaultDurationSeconds = 0, -- 0 == permanent
		KickMessagePrefix = "[Sentinel] You have been removed: ",
	},
}

return Config
