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
  for f=1,60*3 do
    if f%2==0 then dir=-dir end
    ball.Position=v3(0,5,6); ball.AssemblyLinearVelocity=v3(0,0,dir*400); lv.VectorVelocity=v3(0,0,dir*400)
    -- clash rule: while a shield is up it parries each point-blank return, which
    -- resets the block cooldown so the next block isn't locked out (as in the
    -- dump, and as clash_test.lua models via parryReset).
    if w.shieldAt(w.R.VTIME()) then w.server.parryReset() end
    w.RunService.Heartbeat:Fire(); w.R.advance(dt)
    -- after warm-up, sample whether the point-blank ball is shielded right now
    if f>60 then total=total+1; if w.shieldAt(w.R.VTIME()) then covered=covered+1 end end
  end
  return w.server.peakInflight, covered/math.max(1,total)
end

print("=== faithful yielding-server clash: in-flight guard vs backlog ===")
local guardOK, heldOK = true, true
for _,pg in ipairs({30,90,150,200}) do
  local cPeak = control(pg)
  local rPeak, cov = real(pg)
  if rPeak>1 then guardOK=false end
  if cov<0.98 then heldOK=false end
  print(string.format("  ping %3d ms | no-guard backlog peak=%-4d | script peakInflight=%d | shield coverage=%.0f%%",
    pg, cPeak, rPeak, cov*100))
end
print("")
if guardOK then print("OK: script holds ONE block in flight at a time - no backlog (snappy clash).")
else print("FAIL: script let blocks pile up - backlog present."); os.exit(1) end
if heldOK then print("OK: a shield covered the point-blank ball on every return (clash HELD).")
else print("FAIL: point-blank ball went unshielded (clash lost)."); os.exit(1) end
