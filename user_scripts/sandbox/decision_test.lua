-- Decision-logic test: the RIGHT ball must drive the parry. The case is a DECOY
-- - a ball aimed at someone ELSE sitting nearer than the ball aimed at YOU. The
-- nearest ball is the decoy, but the arc prediction / shield-window must track
-- the ball actually coming for you (chosen by preferring a threatening ball over
-- a merely-nearer one), or your real threat is fired on too late (a miss at
-- higher ping). The dash-in clash (clash_test.lua) covers the opposite need -
-- when NOTHING is aimed at you, the nearest ball of any target is still used.
local HERE = (arg[0] or ""):match("^(.*[/\\])") or "./"
local SCRIPT = arg[1] or (HERE.."../anime_ball_autoparry.lua")
local SRC = assert(io.open(SCRIPT,"r")):read("*a")
local build = dofile(HERE.."world.lua").build

local pass,fail = 0,0
local function ok(n) pass=pass+1; print("  ok   "..n) end
local function bad(n,w) fail=fail+1; print("  FAIL "..n.."  ("..w..")") end

-- spawn a ball; spec = {pos=v3, vel=v3, target=str}. Returns a stepper handle.
local function spawn(w, spec)
  local v3,Instance,Enum = w.v3,w.Instance,w.Enum
  local ball=Instance.new("Part"); ball.Name="Ball"
  local lv=Instance.new("LinearVelocity"); lv.Enabled=true; lv.RelativeTo=Enum.ActuatorRelativeTo.World
  lv.VelocityConstraintMode=Enum.VelocityConstraintMode.Vector; lv.Parent=ball
  if spec.target then ball:SetAttribute("Target", spec.target) end
  ball.Parent=w.Balls
  local truePos=spec.pos; local vel=spec.vel; local hist={}
  return {
    ball=ball, hit=false, parried=nil,
    step=function(dt,t)
      truePos = truePos + v3(vel.X*dt,vel.Y*dt,vel.Z*dt)
      hist[#hist+1]={t=t,pos=truePos,vel=vel}
      local tgt=t-w.oneway; local sp,sv=truePos,vel
      for i=#hist,1,-1 do if hist[i].t<=tgt then sp=hist[i].pos; sv=hist[i].vel; break end end
      ball.Position=sp; ball.AssemblyLinearVelocity=sv; lv.VectorVelocity=sv
      return (w.hrp.Position - truePos).Magnitude
    end,
  }
end

-- decoy case: a stationary ball aimed at "Other" sits at decoyDist (inside the
-- look but > point-blank, so it can't mask the bug via pointBlank), while a fast
-- ball aimed at "Hero" rushes straight in. Score: is MY ball parried?
local function decoy(ping, decoyDist, threatSpeed)
  local w = build(SRC, ping); if not w then return bad("decoy","LOADERR") end
  local v3 = w.v3
  local hl=w.Instance.new("Highlight"); hl.Name="Highlight"; hl.Parent=w.heroF
  local A = spawn(w, {pos=v3(decoyDist,5,0), vel=v3(0,0,0), target="Other"})   -- decoy, someone else's
  local B = spawn(w, {pos=v3(0,5,120), vel=v3(0,0,-threatSpeed), target="Hero"}) -- my real threat
  local dt=1/60; local t=0; local parried,hit=nil,false
  for f=1,60*6 do
    t=t+dt
    A.step(dt,t)
    local dB=B.step(dt,t)
    w.RunService.Heartbeat:Fire(); w.R.advance(dt)
    if not hit and dB<=8 then hit=true; parried=w.shieldAt(w.R.VTIME()); break end
  end
  local unblockable = hit and not parried and ((120-8)/threatSpeed) < (2*w.oneway + 1/60)
  local tag=string.format("decoy@%d d=%d s=%d",ping,decoyDist,threatSpeed)
  if not hit then bad(tag,"my ball never reached me?")
  elseif parried then ok(tag.." -> my ball PARRIED")
  elseif unblockable then ok(tag.." -> unblockable (latency wall, not the bug)")
  else bad(tag,"my ball MISSED while decoy was closest") end
end

print("=== decoy: someone else's ball is nearer than the one aimed at me ===")
for _,pg in ipairs({30,90,150}) do
  decoy(pg, 26, 200)   -- decoy just outside point-blank
  decoy(pg, 30, 300)   -- faster threat, decoy a bit further
end

-- Two balls BOTH aimed at me: a slow one sitting nearer (drifting sideways, not
-- arriving) and a FAST one farther out rushing straight in. The nearest is the
-- slow one, but the fast one arrives first - the arc/shield-window must track
-- the most imminent threat, or the fast ball is fired on too late.
local function twoThreat(ping, nearDist, threatSpeed)
  local w = build(SRC, ping); if not w then return bad("twoThreat","LOADERR") end
  local v3 = w.v3
  local hl=w.Instance.new("Highlight"); hl.Name="Highlight"; hl.Parent=w.heroF
  -- slow near ball aimed at me, drifting sideways (X) so it never actually lands
  local A = spawn(w, {pos=v3(nearDist,5,0), vel=v3(20,0,0), target="Hero"})
  local B = spawn(w, {pos=v3(0,5,120), vel=v3(0,0,-threatSpeed), target="Hero"})
  local dt=1/60; local t=0; local parried,hit=nil,false
  for f=1,60*6 do
    t=t+dt
    A.step(dt,t); local dB=B.step(dt,t)
    w.RunService.Heartbeat:Fire(); w.R.advance(dt)
    if not hit and dB<=8 then hit=true; parried=w.shieldAt(w.R.VTIME()); break end
  end
  local unblockable = hit and not parried and ((120-8)/threatSpeed) < (2*w.oneway + 1/60)
  local tag=string.format("twoThreat@%d near=%d s=%d",ping,nearDist,threatSpeed)
  if not hit then bad(tag,"fast ball never reached me?")
  elseif parried then ok(tag.." -> fast ball PARRIED")
  elseif unblockable then ok(tag.." -> unblockable (latency wall)")
  else bad(tag,"fast ball MISSED behind a nearer slow one") end
end

print("=== two threats: a nearer SLOW ball must not shadow a farther FAST one ===")
for _,pg in ipairs({30,90,150}) do
  twoThreat(pg, 25, 300)
  twoThreat(pg, 30, 400)
end

print(string.format("\n=== %d passed, %d failed ===", pass, fail))
if fail>0 then os.exit(1) else print("ALL DECISION CASES OK") end
