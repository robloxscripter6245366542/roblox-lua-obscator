-- Server-hook test: the game's BallController.Server.ChangeBallColor is called
-- as ChangeBallColor(ballNAME, targetName, color). When the round has
-- NoHighlight on (or the ball is invisible) the game returns BEFORE writing the
-- ball's Target attribute, so the attribute goes stale and the script's hook is
-- the only source of truth. Also checks Block's nil/false/true return handling
-- and the SwordController.Server.BlockSuccess hook.
-- Run: lua hook_test.lua [path-to-autoparry]
local HERE = (arg[0] or ""):match("^(.*[/\\])") or "./"
local SCRIPT = arg[1] or (HERE.."../anime_ball_autoparry.lua")
local SRC = assert(io.open(SCRIPT,"r")):read("*a")
local build = dofile(HERE.."world.lua").build

local pass,fail = 0,0
local function ok(n) pass=pass+1; print("  ok   "..n) end
local function bad(n,w) fail=fail+1; print("  FAIL "..n.."  ("..w..")") end

local function settle(w) for _=1,30 do w.RunService.Heartbeat:Fire(); w.R.advance(1/60) end end

-- A ball with a STALE Target attribute; the server's retarget arrives only
-- through ChangeBallColor (NoHighlight round). Returns blocks sent + parried?
local function run(ping, staleTarget, realTarget, approach)
  local w = assert(build(SRC, ping))
  local v3,Instance,Enum = w.v3,w.Instance,w.Enum
  settle(w)  -- let the lazy hooks install
  w.Balls.Parent:SetAttribute("NoHighlight", true)
  local ball=Instance.new("Part"); ball.Name="Ball7"
  local lv=Instance.new("LinearVelocity"); lv.Enabled=true; lv.RelativeTo=Enum.ActuatorRelativeTo.World
  lv.VelocityConstraintMode=Enum.VelocityConstraintMode.Vector; lv.Parent=ball
  ball:SetAttribute("Target", staleTarget)
  local pos = approach and v3(0,5,140) or v3(30,5,140)
  local vel = v3(0,0,-160)
  ball.Position=pos; ball.AssemblyLinearVelocity=vel; lv.VectorVelocity=vel
  ball.Parent=w.Balls
  w.ballCtl.Server.ChangeBallColor("Ball7", realTarget)   -- server retarget (by NAME)
  local blocks0 = w.server.blocks
  local dt=1/60; local hit, parried = false, nil
  for _=1,60*3 do
    pos = pos + v3(vel.X*dt, vel.Y*dt, vel.Z*dt)
    ball.Position=pos
    w.RunService.Heartbeat:Fire(); w.R.advance(dt)
    if approach and not hit and (w.hrp.Position-pos).Magnitude <= 8 then
      hit=true; parried=w.shieldAt(w.R.VTIME()); break
    end
  end
  return w.server.blocks - blocks0, parried, w
end

-- Decoy layout under NoHighlight: a stationary ball whose STALE attribute says
-- "Hero" (really aimed at Other) sits nearer than the fast ball coming for me,
-- whose stale attribute says "Other". Only the server retarget calls tell the
-- truth. If the script trusts the stale attributes it tracks the decoy and
-- fires on my real ball too late.
local function decoy(ping, decoyDist, speed)
  local w = assert(build(SRC, ping))
  local v3,Instance,Enum = w.v3,w.Instance,w.Enum
  settle(w)
  w.Balls.Parent:SetAttribute("NoHighlight", true)
  local function mk(name, pos, vel, stale)
    local b=Instance.new("Part"); b.Name=name
    local lv=Instance.new("LinearVelocity"); lv.Enabled=true; lv.RelativeTo=Enum.ActuatorRelativeTo.World
    lv.VelocityConstraintMode=Enum.VelocityConstraintMode.Vector; lv.Parent=b
    b:SetAttribute("Target", stale); b.Position=pos; b.AssemblyLinearVelocity=vel; lv.VectorVelocity=vel
    b.Parent=w.Balls; return b, lv
  end
  mk("Decoy", v3(decoyDist,5,0), v3(0,0,0), "Hero")
  w.ballCtl.Server.ChangeBallColor("Decoy", "Other")
  local vel=v3(0,0,-speed); local truePos=v3(0,5,120)
  local B, lvB = mk("Mine", truePos, vel, "Other")
  w.ballCtl.Server.ChangeBallColor("Mine", "Hero")
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

print("=== ChangeBallColor(ballName, target) hook vs stale Target attributes ===")
for _,ping in ipairs({90,150}) do
  for _,c in ipairs({{25,300},{30,400}}) do
    local tag=string.format("NoHighlight decoy @%d near=%d s=%d", ping, c[1], c[2])
    local r = decoy(ping, c[1], c[2])
    if r then ok(tag.." -> my ball PARRIED") else bad(tag, r==nil and "never hit" or "MISSED") end
  end
end

print("=== Clash with the game's Clash visual setting OFF ===")
-- A ball sits 28 studs away (outside point-blank) aimed at the OTHER clasher (not an imminent threat
-- by itself). The server says a clash started, but with the visual setting off
-- the game never sets ClashEffect. The script must still hold the clash (fire),
-- then stop once the server ends it.
for _,ping in ipairs({60,180}) do
  local w = assert(build(SRC, ping))
  local v3,Instance = w.v3,w.Instance
  settle(w)
  local b=Instance.new("Part"); b.Name="ClashBall"; b:SetAttribute("Target","Other")
  b.Position=v3(0,5,28); b.AssemblyLinearVelocity=v3(0,0,0); b.Parent=w.Balls
  local function frames(n) for _=1,n do w.RunService.Heartbeat:Fire(); w.R.advance(1/60) end end
  frames(60); local idle = w.server.blocks
  w.clashCtl.Server.StartClash()
  frames(60); local during = w.server.blocks - idle
  w.clashCtl.Server.EndClash()
  frames(90); local mark = w.server.blocks; frames(60); local after = w.server.blocks - mark
  local tag = "clash @"..ping.." (effects off)"
  if idle == 0 and during > 0 and after == 0 then ok(tag.." -> idle 0, held "..during..", stopped after EndClash")
  else bad(tag, string.format("idle=%d during=%d after=%d", idle, during, after)) end
end

print("=== GetBallAsync connection leak ===")
do
  local w = assert(build(SRC, 60)); settle(w)
  local b=w.Instance.new("Part"); b.Name="LeakBall"; b.Parent=w.Balls
  for _=1,200 do w.ballCtl.GetBallAsync("LeakBall") end
  if w.ballCtl.conns == 1 and w.ballCtl.CurrentBall == b then ok("200 lookups -> 1 connection (was 200)")
  else bad("GetBallAsync leak", w.ballCtl.conns.." connections") end
end

print("=== Game's server AutoParryService toggle ===")
do
  -- The toggle is off by default: the script must never call the service on its own.
  local w = assert(build(SRC, 60)); settle(w)
  if w.apService.calls == 0 then ok("off by default -> service never called") else bad("default", w.apService.calls.." calls") end
  -- Saved setting ON + server refuses -> asks once, stays off, no crash.
  local w2 = assert(build(SRC:gsub('GameAP.want         = setting%("GameAutoParry", false%)', 'GameAP.want = true'), 60)); settle(w2)
  if w2.apService.calls == 1 and not w2.apService.enabled then ok("refused by server -> asked once, stays off") else bad("refused", w2.apService.calls.." calls, enabled="..tostring(w2.apService.enabled)) end
end

print("=== Auto-Dash Away ===")
local function dashCase(enabled, foeSpeed, startDist, heroVelX, clash)
  local src = enabled and SRC:gsub('AutoDash.enabled    = setting%("AutoDash", false%)', 'AutoDash.enabled = true') or SRC
  local w = assert(build(src, 80)); settle(w)
  local v3,Instance = w.v3,w.Instance
  local foe=Instance.new("Player"); foe.Name="Foe"
  local fchar=Instance.new("Model"); fchar.Name="Foe"
  local fhrp=Instance.new("Part"); fhrp.Name="HumanoidRootPart"; fhrp.Position=v3(0,5,startDist)
  fhrp.AssemblyLinearVelocity=v3(0,0,-foeSpeed); fhrp.Parent=fchar
  foe.Character=fchar; foe.CharacterAdded=w.R.newSignal(); foe.CharacterRemoving=w.R.newSignal()
  w.players[#w.players+1]=foe; w.Players.PlayerAdded:Fire(foe)
  w.hrp.AssemblyLinearVelocity=v3(heroVelX or 0,0,0)
  if clash then
    -- a real clash always has a ball in play between you
    local b=Instance.new("Part"); b.Name="ClashBall"; b:SetAttribute("Target","Foe")
    b.Position=v3(0,5,10); b.AssemblyLinearVelocity=v3(0,0,0); b.Parent=w.Balls
    w.clashCtl.Server.StartClash()
  end
  local dt=1/60
  for _=1,90 do
    fhrp.Position=fhrp.Position+v3(0,0,-foeSpeed*dt)
    if fhrp.Position.Z < 2 then foeSpeed=0; fhrp.AssemblyLinearVelocity=v3(0,0,0) end
    w.RunService.Heartbeat:Fire(); w.R.advance(dt)
  end
  return w.movement.dashCount
end
local n = dashCase(true, 90, 25)
if n == 1 then ok("foe dashes in at 90 studs/s -> auto-dashed once (cooldown respected)") else bad("dash-in", n.." dashes") end
n = dashCase(false, 90, 25)
if n == 0 then ok("toggle off -> never dashes") else bad("off", n.." dashes") end
n = dashCase(true, 90, 25, 0, true)
if n == 0 then ok("in a clash (server StartClash) -> never dashes out of it") else bad("clash", n.." dashes") end
n = dashCase(true, 8, 10)
if n == 0 then ok("foe just walking nearby (8 studs/s) -> no dash") else bad("walk", n.." dashes") end
-- Direction: foe rushes in from +Z while you move toward +X. Straight away is
-- -Z; at the default 45 deg it leans toward the side you're moving (+X):
-- expected Move(dir) = (0.707, 0, -0.707).
do
  local captured
  local function run()
    local src = SRC:gsub('AutoDash.enabled    = setting%("AutoDash", false%)', 'AutoDash.enabled = true')
    local w = assert(build(src, 80)); settle(w)
    local hum = w.char:FindFirstChild("Humanoid")
    hum.Move = function(_, d) captured = d end
    local v3,Instance = w.v3,w.Instance
    local foe=Instance.new("Player"); foe.Name="Foe"
    local fchar=Instance.new("Model"); fchar.Name="Foe"
    local fhrp=Instance.new("Part"); fhrp.Name="HumanoidRootPart"; fhrp.Position=v3(0,5,20)
    fhrp.AssemblyLinearVelocity=v3(0,0,-90); fhrp.Parent=fchar
    foe.Character=fchar; foe.CharacterAdded=w.R.newSignal(); foe.CharacterRemoving=w.R.newSignal()
    w.players[#w.players+1]=foe; w.Players.PlayerAdded:Fire(foe)
    w.hrp.AssemblyLinearVelocity=v3(10,0,0)
    for _=1,20 do fhrp.Position=fhrp.Position+v3(0,0,-1.5); w.RunService.Heartbeat:Fire(); w.R.advance(1/60) end
  end
  run()
  if captured and math.abs(captured.X-0.7071)<0.02 and math.abs(captured.Z+0.7071)<0.02 and math.abs(captured.Y)<1e-6 then
    ok(string.format("dash angle 45 deg away + toward your movement -> (%.2f, %.2f, %.2f)", captured.X, captured.Y, captured.Z))
  else bad("dash direction", captured and string.format("(%.2f, %.2f, %.2f)", captured.X, captured.Y, captured.Z) or "Move never called") end
end

print("=== Block result + BlockSuccess hook ===")
do
  local _, _, w = run(60, "Other", "Hero", true)
  local before = w.server.blocks
  w.swordCtl.Server.BlockSuccess(2)
  -- unload must restore the game's own functions
  local hooked = w.swordCtl.Server.BlockSuccess
  w.genv.AnimeBallHubUnload()
  if w.swordCtl.Server.BlockSuccess ~= hooked and w.ballCtl.Server.ChangeBallColor ~= nil
     and w.clashCtl.Server.StartClash == w.clashCtl.Server.StartClash then
    ok("unload restores BlockSuccess / ChangeBallColor")
  else bad("unload restore", "hook left installed") end
  if before >= 1 then ok("blocks fired before unload ("..before..")") else bad("blocks", "none") end
end

print(string.format("\n=== %d passed, %d failed ===", pass, fail))
if fail == 0 then print("ALL HOOK CASES OK") end
