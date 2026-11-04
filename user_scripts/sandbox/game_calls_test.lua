-- Game calls test: the LIVE game's Framework dispatcher calls a copy of each
-- controller's Server functions made when the game loaded, so a script's later
-- BallController.Server.X = ... replacement never runs there (real match log:
-- 0 HitEffect calls in 186 hits; BlockSuccess never fired in any real miss
-- report). Every call does arrive over Framework.RemoteEvent.OnClientEvent.
-- Here every server call is delivered that way (w.serverCall: the ORIGINAL
-- function + the remote event), and the script must still:
--  * know the real target of a ball whose Target attribute is stale
--    (NoHighlight round: ChangeBallColor) and parry it;
--  * hold a clash the server started (StartClash) with the game's Clash
--    effects off, and stop when it ends (EndClash);
--  * log the ability played (AbilityController) and the server's parry
--    confirmation (BlockSuccess) in a miss report;
--  * log the server's hit effects (HitEffect) in the Ball Hit Log;
--  * and handle a call once when it arrives BOTH ways (an executor/game where
--    the Server table is used too).
-- Run: lua game_calls_test.lua [script]
local HERE = (arg[0] or ""):match("^(.*[/\\])") or "./"
local SCRIPT = arg[1] or (HERE.."../anime_ball_autoparry.lua")
local SRC = assert(io.open(SCRIPT,"r")):read("*a")
local build = dofile(HERE.."world.lua").build
local pass, fail = 0, 0
local function ok(n) pass=pass+1; print("  ok   "..n) end
local function bad(n,w) fail=fail+1; print("  FAIL "..n.."  ("..w..")") end
local function frames(w, n) for _=1,n do w.RunService.Heartbeat:Fire(); w.R.advance(1/60) end end

print("=== Stale Target attribute: the real target only comes as ChangeBallColor ===")
-- NoHighlight round: a stationary decoy whose stale attribute says "Hero" sits
-- nearer than the fast ball really coming for me (stale attribute "Other").
local function decoy(ping, decoyDist, speed)
  local w = assert(build(SRC, ping, {liveDispatch=true}))
  local v3,Instance,Enum = w.v3,w.Instance,w.Enum
  frames(w, 30)
  w.Balls.Parent:SetAttribute("NoHighlight", true)
  local function mk(name, pos, vel, stale)
    local b=Instance.new("Part"); b.Name=name
    local lv=Instance.new("LinearVelocity"); lv.Enabled=true; lv.RelativeTo=Enum.ActuatorRelativeTo.World
    lv.VelocityConstraintMode=Enum.VelocityConstraintMode.Vector; lv.Parent=b
    b:SetAttribute("Target", stale); b.Position=pos; b.AssemblyLinearVelocity=vel; lv.VectorVelocity=vel
    b.Parent=w.Balls; return b
  end
  mk("Decoy", v3(decoyDist,5,0), v3(0,0,0), "Hero")
  w.serverCall("BallController", "ChangeBallColor", "Decoy", "Other")
  local vel=v3(0,0,-speed); local truePos=v3(0,5,120)
  local B = mk("Mine", truePos, vel, "Other")
  w.serverCall("BallController", "ChangeBallColor", "Mine", "Hero")
  local dt=1/60; local t=0; local hist={}
  for _=1,60*6 do
    t=t+dt
    truePos = truePos + v3(vel.X*dt, vel.Y*dt, vel.Z*dt)
    hist[#hist+1]={t=t,pos=truePos}
    local sp=truePos
    for i=#hist,1,-1 do if hist[i].t<=t-w.oneway then sp=hist[i].pos break end end
    B.Position=sp
    w.RunService.Heartbeat:Fire(); w.R.advance(dt)
    if (w.hrp.Position-truePos).Magnitude <= 8 then return w.shieldAt(w.R.VTIME()) end
  end
  return nil
end
for _,ping in ipairs({90,150}) do
  for _,c in ipairs({{25,300},{30,400}}) do
    local tag=string.format("NoHighlight decoy @%d near=%d s=%d", ping, c[1], c[2])
    local r = decoy(ping, c[1], c[2])
    if r then ok(tag.." -> my ball PARRIED") else bad(tag, r==nil and "never hit" or "MISSED") end
  end
end

print("=== Clash the server started, with the game's Clash effects off ===")
for _,ping in ipairs({60,180}) do
  local w = assert(build(SRC, ping, {liveDispatch=true}))
  local v3,Instance = w.v3,w.Instance
  frames(w, 30)
  local b=Instance.new("Part"); b.Name="ClashBall"; b:SetAttribute("Target","Other")
  b.Position=v3(0,5,28); b.AssemblyLinearVelocity=v3(0,0,0); b.Parent=w.Balls
  frames(w, 60); local idle = w.server.blocks
  w.serverCall("ClashController", "StartClash")
  local during0 = w.server.blocks
  for i=1,60 do
    if i % 18 == 1 then b:SetAttribute("Target", (math.floor(i/18) % 2 == 0) and "Hero" or "Other") end
    frames(w, 1)
  end
  b:SetAttribute("Target","Other")
  local during = w.server.blocks - during0
  w.serverCall("ClashController", "EndClash")
  frames(w, 90); local mark = w.server.blocks; frames(w, 60); local after = w.server.blocks - mark
  local tag = "clash @"..ping
  if idle == 0 and during > 0 and after == 0 then ok(tag.." -> idle 0, held "..during..", stopped after EndClash")
  else bad(tag, string.format("idle=%d during=%d after=%d", idle, during, after)) end
end

print("=== Miss report: the ability played and the server's parry confirmation ===")
do
  local w = assert(build(SRC, 200, {liveDispatch=true})); frames(w, 30)
  local v3,Instance,Enum = w.v3,w.Instance,w.Enum
  local hum = w.char:FindFirstChild("Humanoid")
  w.serverCall("SwordController", "BlockSuccess", 1)
  frames(w, 5)
  local b=Instance.new("Part"); b.Name="MissBall"
  local lv=Instance.new("LinearVelocity"); lv.Enabled=true; lv.RelativeTo=Enum.ActuatorRelativeTo.World
  lv.VelocityConstraintMode=Enum.VelocityConstraintMode.Vector; lv.Parent=b
  b:SetAttribute("Target","Hero"); b.Position=v3(0,5,40); b.AssemblyLinearVelocity=v3(0,0,-150); lv.VectorVelocity=v3(0,0,-150); b.Parent=w.Balls
  w.serverCall("AbilityController", "Explode", "Villain", "ChronoStasis Activate", true)
  for _=1,10 do b.Position=b.Position+v3(0,0,-2.5); frames(w, 1) end
  hum.Health = 0; hum.HealthChanged:Fire(0)
  local rep = w.files["AnimeBallHub/miss_reports.txt"] or ""
  if rep:find("ABILITY Explode(Villain, ChronoStasis Activate", 1, true) then ok("ability logged in the miss report")
  else bad("ability", "not in the report") end
  if rep:find("PARRY CONFIRMED by server", 1, true) then ok("server parry confirmation logged")
  else bad("BlockSuccess", "not in the report") end
end

print("=== Ball Hit Log: the server's hit effects ===")
do
  local w = assert(build(SRC, 120, {liveDispatch=true})); frames(w, 30)
  local v3,Instance = w.v3,w.Instance
  local b=Instance.new("Part"); b.Name="FxBall"; b.Parent=w.Balls
  b:SetAttribute("Target","Hero"); b.Position=v3(0,5,40); b.AssemblyLinearVelocity=v3(0,0,0)
  frames(w, 10)
  local dir=1
  for i=1,8 do   -- 8 hits back and forth, each with the server's HitEffect
    local who = (i % 2 == 1) and "Hero" or "Foe"
    b:SetAttribute("Target", (i % 2 == 1) and "Foe" or "Hero")
    w.serverCall("BallController", "HitEffect", who, "Katana", "FxBall", 1.2, nil)
    dir=-dir
    for _=1,18 do b.AssemblyLinearVelocity=v3(0,0,60*dir); b.Position=b.Position+v3(0,0,dir); frames(w, 1) end
  end
  frames(w, 60)
  local rep = w.genv.AnimeBallHubHitLog and w.genv.AnimeBallHubHitLog() or ""
  local seen = tonumber(rep:match("game HitEffect calls seen: (%d+)"))
  local listening = rep:match("Framework remote: listening") ~= nil
  if seen == 8 and listening then ok("8 HitEffect calls reached the log (remote listening)")
  else bad("hit log", "HitEffect seen "..tostring(seen)..", listening "..tostring(listening)) end
end

print("=== A call that arrives BOTH ways is handled once ===")
do
  local w = assert(build(SRC, 200)); frames(w, 30)
  local v3,Instance,Enum = w.v3,w.Instance,w.Enum
  local hum = w.char:FindFirstChild("Humanoid")
  -- the Server table IS used here (the hook fires) and the remote fires too
  w.swordCtl.Server.BlockSuccess(1)
  w.fwRemote.OnClientEvent:Fire("SwordController", "BlockSuccess", {n=1, 1})
  frames(w, 30)
  w.fwRemote.OnClientEvent:Fire("SwordController", "BlockSuccess", {n=1, 1})
  w.swordCtl.Server.BlockSuccess(1)
  frames(w, 5)
  local b=Instance.new("Part"); b.Name="MissBall"
  local lv=Instance.new("LinearVelocity"); lv.Enabled=true; lv.RelativeTo=Enum.ActuatorRelativeTo.World
  lv.VelocityConstraintMode=Enum.VelocityConstraintMode.Vector; lv.Parent=b
  b:SetAttribute("Target","Hero"); b.Position=v3(0,5,40); b.AssemblyLinearVelocity=v3(0,0,-150); lv.VectorVelocity=v3(0,0,-150); b.Parent=w.Balls
  for _=1,10 do b.Position=b.Position+v3(0,0,-2.5); frames(w, 1) end
  hum.Health = 0; hum.HealthChanged:Fire(0)
  local rep = w.files["AnimeBallHub/miss_reports.txt"] or ""
  local _, n = rep:gsub("PARRY CONFIRMED by server", "")
  if n == 2 then ok("2 parries, each sent both ways -> logged 2 times")
  else bad("dedupe", "logged "..n.." times (want 2)") end
end

print(string.format("\n=== %d passed, %d failed ===", pass, fail))
print(fail == 0 and "ALL GAME CALL CASES OK" or "SOME GAME CALL CASES FAILED")
