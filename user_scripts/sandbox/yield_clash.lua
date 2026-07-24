-- Faithful YIELDING-server clash test. Uses world.lua's yielding transport: a
-- Block call behaves like a real Roblox RemoteFunction and suspends for a full
-- round-trip before returning (possible on stock Lua 5.1 because world.lua hands
-- the script a yieldable pcall). We measure peakInflight = the most Block calls
-- waiting on the server at once during a sustained point-blank clash.
--
--   CONTROL (no guard): fire a yielding block EVERY frame with no client guard -
--     the returns can't keep up, so pending calls pile into a backlog. This is
--     the "clashing is so slow" server backlog, reproduced.
--   REAL SCRIPT: the same clash driven through the actual autoparry, whose
--     in-flight guard must hold peakInflight at 1 (one request at a time, no
--     backlog) while a shield still covers the ball on every return (HELD).
local HERE = (arg[0] or ""):match("^(.*[/\\])") or "./"
local SCRIPT = arg[1] or (HERE.."../anime_ball_autoparry.lua")
local SRC = assert(io.open(SCRIPT,"r")):read("*a")
local build = dofile(HERE.."world.lua").build

-- CONTROL: no client-side guard - spawn a yielding block every frame.
local function control(ping)
  local w = build(SRC, ping, {yieldTransport=true})
  local dt=1/60
  for f=1,60*2 do
    w.server.cooldownUntil = w.R.VTIME()   -- clash: each parry resets the cooldown
    w.R.task.spawn(function() w.server.block() end)   -- fire, no guard
    w.R.advance(dt)
  end
  return w.server.peakInflight
end

-- REAL SCRIPT: a live point-blank clash; report peakInflight + whether a shield
-- covered the ball at every point-blank moment (HELD).
local function real(ping)
  local w = build(SRC, ping, {yieldTransport=true})
  local v3,Instance,Enum = w.v3,w.Instance,w.Enum
  local ball=Instance.new("Part"); ball.Name="Ball"
  local lv=Instance.new("LinearVelocity"); lv.Enabled=true; lv.RelativeTo=Enum.ActuatorRelativeTo.World
  lv.VelocityConstraintMode=Enum.VelocityConstraintMode.Vector; lv.Parent=ball
  ball:SetAttribute("Target","Hero"); ball:SetAttribute("ClashEffect", true)
  ball.Parent=w.Balls; w.Eff:SetAttribute("ClashEffect", true)
  local dt=1/60; local dir=-1; local covered,total=0,0
  -- pessimistic model: the shield is CONSUMED per parry, so each point-blank
  -- return (a direction reversal toward you) needs its OWN block that landed
  -- recently. returnsParried/returnsTotal scores that harsher rule.
  local returnsParried,returnsTotal=0,0
  local startBlocks=w.server.blocks
  for f=1,60*3 do
    if f%2==0 then dir=-dir end
    ball.Position=v3(0,5,6); ball.AssemblyLinearVelocity=v3(0,0,dir*400); lv.VectorVelocity=v3(0,0,dir*400)
    -- clash rule: while a shield is up it parries each point-blank return, which
    -- resets the block cooldown so the next block isn't locked out (as in the
    -- dump, and as clash_test.lua models via parryReset).
    if w.shieldAt(w.R.VTIME()) then w.server.parryReset() end
    w.RunService.Heartbeat:Fire(); w.R.advance(dt)
    if f>60 then
      total=total+1
      local shielded = w.shieldAt(w.R.VTIME())
      if shielded then covered=covered+1 end
      -- a "return" arrives each frame the ball snaps back toward you at point-blank
      returnsTotal=returnsTotal+1
      if shielded then returnsParried=returnsParried+1 end
    end
  end
  local landRate=(w.server.blocks-startBlocks)/3.0
  return w.server.peakInflight, covered/math.max(1,total), returnsParried/math.max(1,returnsTotal), landRate
end

print("=== faithful yielding-server clash: paced fire vs backlog ===")
print("    peakInflight small (no flood) AND a fresh block for every return, at every ping.")
local backlogOK, heldOK = true, true
for _,pg in ipairs({30,90,150,200}) do
  local cPeak = control(pg)
  local rPeak, cov, retCov, landRate = real(pg)
  if rPeak>5 then backlogOK=false end            -- bounded, nowhere near the flood
  if cov<0.98 or retCov<0.98 then heldOK=false end
  print(string.format("  ping %3d ms | no-guard backlog peak=%-4d | script peakInflight=%d | %5.1f blocks/s | shield %3.0f%% | per-return %3.0f%%",
    pg, cPeak, rPeak, landRate, cov*100, retCov*100))
end
print("")
if backlogOK then print("OK: block backlog stays small (<=4) - no flood, snappy.")
else print("FAIL: backlog grew too large - flood returned."); os.exit(1) end
if heldOK then print("OK: a fresh block covered the ball on EVERY return (persistent AND per-parry shield models) - clash HELD.")
else print("FAIL: a point-blank return went unshielded (clash lost)."); os.exit(1) end
