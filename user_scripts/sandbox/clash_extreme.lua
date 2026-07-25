-- EXTREME clash stress test: a point-blank clash ~1 stud away at absurd ball
-- speeds (400k studs/s and up). At that speed the ball reverses hundreds of
-- thousands of times a second - no client could ever click per-return - so the
-- only thing that can hold it is the persistent 0.6s SHIELD blanketing every
-- return. We verify: (1) the script doesn't choke on the huge velocity value
-- (no NaN/crash), (2) it keeps firing (clicks), and (3) a shield covers the ball
-- the whole time. Reports clicks/sec and coverage per speed.
local HERE = (arg[0] or ""):match("^(.*[/\\])") or "./"
local SCRIPT = arg[1] or (HERE.."../anime_ball_autoparry.lua")
local SRC = assert(io.open(SCRIPT,"r")):read("*a")
local build = dofile(HERE.."world.lua").build

local function stress(speed, ping, dist)
  local w = build(SRC, ping)
  local v3,Instance,Enum = w.v3,w.Instance,w.Enum
  local hl=Instance.new("Highlight"); hl.Name="Highlight"; hl.Parent=w.heroF
  -- opponent overlapping you (the stack), 1 stud away
  local foe=Instance.new("Model"); foe.Name="Foe"
  local fhrp=Instance.new("Part"); fhrp.Name="HumanoidRootPart"; fhrp.Position=v3(0,5,dist)
  fhrp.AssemblyLinearVelocity=v3(0,0,0); fhrp.Parent=foe
  Instance.new("Humanoid").Parent=foe
  local FOE=Instance.new("Player"); FOE.Name="Foe"; FOE.Character=foe
  FOE.CharacterAdded=w.R.newSignal(); FOE.CharacterRemoving=w.R.newSignal()
  table.insert(w.players, FOE); w.Players.PlayerAdded:Fire(FOE)
  -- the clash ball, point-blank, reversing at the given (absurd) speed
  local ball=Instance.new("Part"); ball.Name="Ball"
  local lv=Instance.new("LinearVelocity"); lv.Enabled=true; lv.RelativeTo=Enum.ActuatorRelativeTo.World
  lv.VelocityConstraintMode=Enum.VelocityConstraintMode.Vector; lv.Parent=ball
  ball:SetAttribute("Target","Hero"); ball:SetAttribute("ClashEffect", true)
  ball.Parent=w.Balls; w.Eff:SetAttribute("ClashEffect", true)

  local dt=1/60; local dir=-1; local start=w.server.blocks; local covered,total=0,0
  local ok = pcall(function()
    for f=1,60*3 do
      dir=-dir
      ball.Position=v3(0,5,dist); ball.AssemblyLinearVelocity=v3(0,0,dir*speed); lv.VectorVelocity=v3(0,0,dir*speed)
      w.Eff:SetAttribute("ClashEffect", true)
      if w.shieldAt(w.R.VTIME()) then w.server.parryReset() end
      w.RunService.Heartbeat:Fire(); w.R.advance(dt)
      total=total+1; if w.shieldAt(w.R.VTIME()) then covered=covered+1 end
    end
  end)
  if not ok then return nil end
  return (w.server.blocks-start)/3.0, covered/math.max(1,total)
end

print("=== EXTREME point-blank clash: 1 stud away, absurd ball speeds ===")
print("    clicks/sec is FRAME-bound (you can't click per-return at these speeds);")
print("    the 0.6s shield is what blankets every return - coverage is what matters.")
local allOK = true
for _,sp in ipairs({400000, 1000000, 10000000, 100000000}) do
  local rate, cov = stress(sp, 60, 1)
  if not rate then print(string.format("  speed %-12d -> CRASHED", sp)); allOK=false
  else
    local held = cov >= 0.98
    if not held then allOK=false end
    print(string.format("  speed %-12d -> %6.1f clicks/sec | shield %3.0f%% | %s",
      sp, rate, cov*100, held and "HELD" or "GAP"))
  end
end
print("")
if allOK then print("OK: no crash at any speed, and the shield held the clash at every one.")
else print("FAIL: a speed crashed or left a coverage gap."); os.exit(1) end
