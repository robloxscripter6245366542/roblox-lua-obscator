--!nocheck
-- ============================================================================
--  Phantom Ball sandbox — test epilogue
--
--  Concatenated AFTER phantom_ballz.lua, so it sits in the same chunk scope and
--  can call the script's file-scope locals directly (cfg / setSpam / setVis /
--  setFx / updIcons / mob). Drives the real integration and asserts behaviour.
--  _MODE ("fresh" | "restore") is injected by the runner ahead of the harness.
-- ============================================================================

local PASS, FAIL = 0, 0
local function check(name, cond, extra)
	if cond then
		PASS = PASS + 1
		print(("  PASS  %s"):format(name))
	else
		FAIL = FAIL + 1
		print(("  FAIL  %s%s"):format(name, extra and ("  (" .. tostring(extra) .. ")") or ""))
	end
end
local CFG_FILE = "Leviathan/Phantom_config.json"
local function savedCfg()
	local raw = _DISK[CFG_FILE]
	if not raw then return nil end
	local ok, d = pcall(function() return game:GetService("HttpService"):JSONDecode(raw) end)
	return ok and d or nil
end

print("=== Phantom Ball sandbox  [mode: " .. tostring(_MODE) .. "] ===")

-- The UI must have built for the integration to work at all.
check("script loaded and Leviathan UI built (mob assigned)", mob ~= nil)

if _MODE == "restore" then
	-- Disk was pre-seeded with {spam=true, vis=false, fx=false}. On load the UI
	-- block should have applied those through the real feature setters.
	DRAIN(8)
	check("restore: cfg.spam == true", cfg.spam == true, tostring(cfg.spam))
	check("restore: cfg.vis == false", cfg.vis == false, tostring(cfg.vis))
	check("restore: cfg.fx == false", cfg.fx == false, tostring(cfg.fx))
	check("restore: spam feature actually enabled (live parry connection)",
		RUN.PostSimulation.live >= 1, "live=" .. tostring(RUN.PostSimulation.live))
	local sc = savedCfg()
	check("restore: config re-persisted with restored values",
		sc ~= nil and sc.spam == true and sc.vis == false and sc.fx == false,
		sc and ("spam=" .. tostring(sc.spam) .. " vis=" .. tostring(sc.vis) .. " fx=" .. tostring(sc.fx)) or "nil")
else
	-- Fresh load: defaults are spam=false, vis=true, fx=true.
	check("fresh defaults: spam=false", cfg.spam == false, tostring(cfg.spam))
	check("fresh defaults: vis=true", cfg.vis == true, tostring(cfg.vis))
	check("fresh defaults: fx=true", cfg.fx == true, tostring(cfg.fx))

	-- Auto-save: enabling spam persists within the save loop. Measure the
	-- connection delta immediately around each setSpam (the parry watchdog also
	-- uses PostSimulation across DRAINs, so only the synchronous delta is ours).
	local preOn = RUN.PostSimulation.live
	setSpam(true)
	check("setSpam(true) sets cfg.spam", cfg.spam == true)
	check("setSpam(true) opens a live parry connection", RUN.PostSimulation.live == preOn + 1,
		"delta=" .. tostring(RUN.PostSimulation.live - preOn))
	DRAIN(4)
	local sc = savedCfg()
	check("auto-save wrote config after toggle", sc ~= nil)
	check("auto-save persisted spam=true", sc ~= nil and sc.spam == true, sc and tostring(sc.spam) or "nil")
	check("auto-save created the Leviathan folder", isfolder("Leviathan"))

	-- Disabling spam closes the connection and re-saves.
	local preOff = RUN.PostSimulation.live
	setSpam(false)
	check("setSpam(false) closes the parry connection", RUN.PostSimulation.live == preOff - 1,
		"delta=" .. tostring(RUN.PostSimulation.live - preOff))
	DRAIN(4)
	check("auto-save persisted spam=false", (savedCfg() or {}).spam == false)

	-- Visualizer + FX toggles persist too.
	setVis(false)
	DRAIN(4)
	check("auto-save persisted vis=false", (savedCfg() or {}).vis == false, tostring((savedCfg() or {}).vis))
	setFx(false)
	DRAIN(4)
	check("auto-save persisted fx=false", (savedCfg() or {}).fx == false, tostring((savedCfg() or {}).fx))

	-- FX clean: a ball-hit effect added to workspace is destroyed when fx is on;
	-- an unrelated instance is left alone.
	setFx(true)
	DRAIN(2)
	local hit = { Name = "BallHit", Parent = workspace, destroyed = false }
	function hit:IsDescendantOf() return true end
	function hit:Destroy() self.destroyed = true self.Parent = nil end
	local keep = { Name = "Chair", Parent = workspace, destroyed = false }
	function keep:IsDescendantOf() return true end
	function keep:Destroy() self.destroyed = true self.Parent = nil end
	WORKSPACE.DescendantAdded:Fire(hit)
	WORKSPACE.DescendantAdded:Fire(keep)
	DRAIN(3)
	check("FX clean destroyed the ball-hit effect", hit.destroyed == true)
	check("FX clean left an unrelated instance alone", keep.destroyed == false)

	-- No recursion / re-entrancy blow-ups while toggling repeatedly.
	for _ = 1, 10 do setSpam(not cfg.spam) end
	DRAIN(2)
	check("rapid toggling did not error or hang", true)

	-- ── Clash detection (speed + distance + trajectory) ──────────────────────
	-- clashAnalyze(ballPos, vel, hrpPos, targeting) -> inClash, ...
	local origin = Vector3.new(0, 0, 0)
	local function V(x, y, z) return Vector3.new(x, y, z) end

	-- Head-on: fast ball 30 studs away heading straight at us -> CLASH.
	do
		local inClash = clashAnalyze(V(30, 0, 0), V(-120, 0, 0), origin, true)
		check("clash: fast ball heading straight at player -> IN CLASH", inClash == true)
	end
	-- Going by: fast ball approaching at an angle but missing ~25 studs -> NO clash.
	do
		local inClash, _, _, miss = clashAnalyze(V(40, 0, 25), V(-150, 0, 0), origin, true)
		check("no-false-clash: fast ball flying past (wide miss) -> NOT a clash",
			inClash == false, "miss=" .. tostring(math.floor(miss)))
	end
	-- Pure sideways ball near the player -> not approaching -> NO clash.
	do
		local inClash = clashAnalyze(V(20, 0, 0), V(0, 0, 140), origin, true)
		check("no-false-clash: ball moving sideways (not approaching) -> NOT a clash", inClash == false)
	end
	-- Point-blank on-course ball -> always a clash (never vetoed).
	do
		local inClash = clashAnalyze(V(6, 0, 0), V(-40, 0, 0), origin, true)
		check("clash: point-blank ball on course -> IN CLASH", inClash == true)
	end
	-- Not targeting us -> never a clash, even head-on.
	do
		local inClash = clashAnalyze(V(30, 0, 0), V(-120, 0, 0), origin, false)
		check("no-false-clash: ball not targeting us -> NOT a clash", inClash == false)
	end
	-- Ball moving away -> NO clash.
	do
		local inClash = clashAnalyze(V(30, 0, 0), V(120, 0, 0), origin, true)
		check("no-false-clash: ball moving away -> NOT a clash", inClash == false)
	end
	-- Slow ball -> NO clash.
	do
		local inClash = clashAnalyze(V(15, 0, 0), V(-3, 0, 0), origin, true)
		check("no-false-clash: slow ball -> NOT a clash", inClash == false)
	end
	-- Too far to arrive within the time window -> NO clash.
	do
		local inClash, _, parryRad, _, tImp = clashAnalyze(V(200, 0, 0), V(-60, 0, 0), origin, true)
		check("no-false-clash: on-course but too far / too slow to arrive in time -> NOT a clash",
			inClash == false, "tImp=" .. tostring(tImp) .. " parryRad=" .. tostring(math.floor(parryRad)))
	end
end

-- Surface any errors captured from spawned/deferred/signal handlers.
if #_ERRORS > 0 then
	print("  --- captured runtime errors ---")
	for _, e in ipairs(_ERRORS) do print("   ! " .. e) end
end
check("no runtime errors captured", #_ERRORS == 0, (#_ERRORS > 0) and (tostring(#_ERRORS) .. " errors") or nil)

print(("=== %s: %d passed, %d failed ==="):format(tostring(_MODE), PASS, FAIL))
if FAIL > 0 then print("SANDBOX_RESULT=FAIL") else print("SANDBOX_RESULT=PASS") end
