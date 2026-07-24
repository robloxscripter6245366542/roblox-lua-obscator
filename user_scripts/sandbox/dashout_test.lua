-- Auto-dash-out test: when an opponent STACKS inside you (overlapping) with a
-- ball in play, the script must trigger the game's ForceDash to break the stack -
-- but NOT when players are merely near (not overlapping), and never faster than
-- the dash cooldown. It also must not dash when the feature can't help (no ball).
local HERE = (arg[0] or ""):match("^(.*[/\\])") or "./"
local SCRIPT = arg[1] or (HERE.."../anime_ball_autoparry.lua")
local SRC = assert(io.open(SCRIPT,"r")):read("*a")
local build = dofile(HERE.."world.lua").build

local pass, fail = 0, 0
local function ok(n) pass=pass+1; print("  ok   "..n) end
local function bad(n,w) fail=fail+1; print("  FAIL "..n.."  ("..w..")") end

-- place a second player's HRP at distance `foeDist` (with velocity `foeVel`
-- toward you), optionally a ball nearby, run `secs`; report ForceDash calls.
local function run(foeDist, ballNear, secs, foeVel)
  local w = build(SRC, 60)
  local v3,Instance,Enum = w.v3,w.Instance,w.Enum
  local hl=Instance.new("Highlight"); hl.Name="Highlight"; hl.Parent=w.heroF
  local foe=Instance.new("Model"); foe.Name="Foe"
  local fhrp=Instance.new("Part"); fhrp.Name="HumanoidRootPart"; fhrp.Position=v3(0,5,foeDist)
  fhrp.AssemblyLinearVelocity=v3(0,0,0); fhrp.Parent=foe
  local fhum=Instance.new("Humanoid"); fhum.Parent=foe
  local FOE=Instance.new("Player"); FOE.Name="Foe"; FOE.Character=foe
  FOE.CharacterAdded=w.R.newSignal(); FOE.CharacterRemoving=w.R.newSignal()
  table.insert(w.players, FOE)
  w.Players.PlayerAdded:Fire(FOE)   -- let the script bind the opponent's HRP
  local ball
  if ballNear then
    ball=Instance.new("Part"); ball.Name="Ball"; ball:SetAttribute("Target","Hero")
    ball.AssemblyLinearVelocity=v3(0,0,-100); ball.Parent=w.Balls
  end
  local dt=1/60
  for f=1,60*secs do
    if ball then ball.Position=v3(0,5,10) end   -- ball hovering point-blank-ish
    fhrp.Position=v3(0,5,foeDist)               -- opponent holds position
    fhrp.AssemblyLinearVelocity=v3(0,0, foeVel or 0)  -- toward you = negative Z
    w.RunService.Heartbeat:Fire(); w.R.advance(dt)
  end
  return w.movement.dashCount
end

print("=== auto-dash-out of a stack ===")
-- opponent overlapping (3 studs) + ball in play, over 3s: should dash out, and
-- (throttled to the ~1.1-1.2s dash cooldown) about 2-3 times, not every frame.
do
  local n = run(3, true, 3)
  if n >= 1 and n <= 4 then ok(string.format("stacked+ball: dashed out %d time(s) (throttled)", n))
  else bad("stacked+ball", string.format("dashed %d times (want 1-4, cooldown-throttled)", n)) end
end
-- PREEMPTIVE: opponent at 11 studs RUSHING in (closing ~60/s) + ball: should
-- dash out NOW, before they fully overlap (this is the "it's slow" fix).
do
  local n = run(11, true, 3, -60)
  if n >= 1 then ok(string.format("rushing in (not yet overlapping): preemptive dash (%d)", n))
  else bad("preemptive rush", "did not dash while opponent rushed in") end
end
-- opponent NEARBY, standing still, not overlapping (14 studs) + ball: must NOT dash.
do
  local n = run(14, true, 3, 0)
  if n == 0 then ok("near, standing still: no dash")
  else bad("near standing still", string.format("dashed %d times (should be 0)", n)) end
end
-- overlapping but NO ball in play: not a clash, must NOT auto-dash.
do
  local n = run(3, false, 3)
  if n == 0 then ok("stacked but no ball: no dash")
  else bad("stacked no ball", string.format("dashed %d times (should be 0)", n)) end
end

print(string.format("\n=== %d passed, %d failed ===", pass, fail))
if fail>0 then os.exit(1) else print("ALL DASH-OUT CASES OK") end
