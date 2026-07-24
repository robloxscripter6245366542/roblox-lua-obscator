-- Advanced ball-detection tests: cases where the old event-only path would have
-- gone "no block", and the new discovery + reconcile + motion-velocity layer
-- must still detect and block the ball.
--   1. DIFFERENT FOLDER  - balls live in "GameBalls", not "Balls".
--   2. MISSED EVENT      - a ball is placed into the folder in a way the
--                          ChildAdded hook doesn't see; the reconcile sweep must
--                          still pick it up.
--   3. KINEMATIC BALL    - moved by Position each frame with NO LinearVelocity
--                          and ~0 AssemblyLinearVelocity; velocity must be
--                          recovered from motion so its arrival is predicted.
local HERE = (arg[0] or ""):match("^(.*[/\\])") or "./"
local SCRIPT = arg[1] or (HERE.."../anime_ball_autoparry.lua")
local SRC = assert(io.open(SCRIPT,"r")):read("*a")
local build = dofile(HERE.."world.lua").build

local pass, fail = 0, 0
local function ok(n) pass=pass+1; print("  ok   "..n) end
local function bad(n,w) fail=fail+1; print("  FAIL "..n.."  ("..w..")") end

-- drive a straight ball to impact; `mk` builds the ball however the case needs
-- and returns a stepper(dt,t)->trueZ. Scores whether it gets blocked.
local function runCase(name, ping, mk)
  local w = build(SRC, ping); if not w then return bad(name,"LOADERR") end
  local hl=w.Instance.new("Highlight"); hl.Name="Highlight"; hl.Parent=w.heroF
  local step = mk(w)
  local dt=1/60; local t=0; local parried,hit=nil,false
  for f=1,600 do
    t=t+dt
    local z = step(dt,t)
    w.RunService.Heartbeat:Fire(); w.R.advance(dt)
    if not hit and z<=8 then hit=true; parried=w.shieldAt(w.R.VTIME()); break end
  end
  if not hit then bad(name,"ball never reached me")
  elseif parried then ok(name.." -> BLOCKED")
  else bad(name,"NO BLOCK") end
end

-- helper: make a folder under workspace with a given name
local function folder(w, name) local f=w.Instance.new("Folder"); f.Name=name; f.Parent=w.workspace or w.WS; return f end

-- 1. balls in a differently-named container
runCase("balls in 'GameBalls' folder", 100, function(w)
  local v3=w.v3
  local gb=w.Instance.new("Folder"); gb.Name="GameBalls"
  -- parent it under workspace via the world's workspace handle
  gb.Parent = w.Balls.Parent   -- same parent as the real Balls folder (workspace)
  local ball=w.Instance.new("Part"); ball.Name="Ball"
  local lv=w.Instance.new("LinearVelocity"); lv.Enabled=true; lv.RelativeTo=w.Enum.ActuatorRelativeTo.World
  lv.VelocityConstraintMode=w.Enum.VelocityConstraintMode.Vector; lv.Parent=ball
  ball:SetAttribute("Target","Hero"); ball.Parent=gb
  local z=120; local hist={}
  return function(dt,t)
    z=z-200*dt; hist[#hist+1]={t=t,z=z}
    local sz=z; for i=#hist,1,-1 do if hist[i].t<=t-w.oneway then sz=hist[i].z break end end
    ball.Position=v3(0,5,sz); ball.AssemblyLinearVelocity=v3(0,0,-200); lv.VectorVelocity=v3(0,0,-200)
    return z
  end
end)

-- 2. a ball whose ChildAdded the hook 'missed' - we drop it straight into the
--    reconcile-swept container without relying on the event (simulated by
--    inserting into a freshly discovered container after load).
runCase("ball events missed (reconcile picks up)", 100, function(w)
  local v3=w.v3
  local gb=w.Instance.new("Folder"); gb.Name="Balls2"; gb.Parent=w.Balls.Parent
  local ball=w.Instance.new("Part"); ball.Name="Ball"; ball:SetAttribute("Target","Hero")
  -- parent BEFORE the script discovers the container, so only the reconcile
  -- sweep (not a live ChildAdded) can find it
  ball.Parent=gb
  local z=120; local hist={}
  return function(dt,t)
    z=z-200*dt; hist[#hist+1]={t=t,z=z}
    local sz=z; for i=#hist,1,-1 do if hist[i].t<=t-w.oneway then sz=hist[i].z break end end
    ball.Position=v3(0,5,sz); ball.AssemblyLinearVelocity=v3(0,0,-200)
    return z
  end
end)

-- 3. kinematic ball: no LinearVelocity, AssemblyLinearVelocity left at 0, moved
--    only by Position. Velocity must be recovered from motion.
runCase("kinematic ball (Position-driven, 0 physics vel)", 100, function(w)
  local v3=w.v3
  local ball=w.Instance.new("Part"); ball.Name="Ball"; ball:SetAttribute("Target","Hero")
  ball.AssemblyLinearVelocity=v3(0,0,0)  -- physics says: not moving
  ball.Parent=w.Balls
  local z=120; local hist={}
  return function(dt,t)
    z=z-180*dt; hist[#hist+1]={t=t,z=z}
    local sz=z; for i=#hist,1,-1 do if hist[i].t<=t-w.oneway then sz=hist[i].z break end end
    ball.Position=v3(0,5,sz)  -- ONLY position changes; velocity stays 0
    return z
  end
end)

-- 4. FALSE-POSITIVE guard: a PLAYER whose username contains "ball" has a
--    character Model in workspace. It must NOT be treated as a ball container
--    (that would add their body parts to the ball cache and parry a person).
--    With no real ball present, the script must send ~0 blocks.
do
  local w = build(SRC, 100)
  local v3 = w.v3
  -- a second player's character named with "ball" in it, standing point-blank
  local ch = w.Instance.new("Model"); ch.Name = "Ballzy99"
  local hum = w.Instance.new("Humanoid"); hum.Parent = ch
  local hrp = w.Instance.new("Part"); hrp.Name="HumanoidRootPart"; hrp.Position=v3(0,5,4)
  hrp.AssemblyLinearVelocity=v3(0,0,0); hrp.Parent=ch
  ch.Parent = w.Balls.Parent   -- workspace
  local hl=w.Instance.new("Highlight"); hl.Name="Highlight"; hl.Parent=w.heroF
  local start = w.server.blocks
  local dt=1/60
  for f=1,120 do w.RunService.Heartbeat:Fire(); w.R.advance(dt) end
  local fired = w.server.blocks - start
  if fired <= 1 then ok(string.format("player named 'Ballzy99' not parried as a ball (%d blocks)", fired))
  else bad("player-as-ball false positive", string.format("%d blocks fired at a person", fired)) end
end

print(string.format("\n=== %d passed, %d failed ===", pass, fail))
if fail>0 then os.exit(1) else print("ALL DETECTION CASES OK") end
