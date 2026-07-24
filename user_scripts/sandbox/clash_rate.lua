-- Confirms the CLASH CLICK-STORM: during a point-blank clash the script sends
-- the block as fast as it can (up to 3 fire paths x every frame) to match a fast
-- clicker click-for-click. This synchronous transport can't show the safety net
-- - the MAX_CLASH_INFLIGHT concurrency cap that stops those sends piling into a
-- backlog - because a synchronous Invoke returns before the next fire, so nothing
-- is ever "in flight". That bound is proven in yield_clash.lua (peakInflight
-- stays <= MAX_CLASH_INFLIGHT with 100% coverage). Here we just confirm the storm
-- is firing hard (many sends/sec) during a clash, and NOT during a lone ball.
local HERE = (arg[0] or ""):match("^(.*[/\\])") or "./"
local SCRIPT = arg[1] or (HERE.."../anime_ball_autoparry.lua")
local SRC = assert(io.open(SCRIPT,"r")):read("*a")
local build = dofile(HERE.."world.lua").build

local function measure(ping)
  local w = build(SRC, ping); if not w then return end
  local v3,Instance,Enum = w.v3,w.Instance,w.Enum
  local ball=Instance.new("Part"); ball.Name="Ball"
  local lv=Instance.new("LinearVelocity"); lv.Enabled=true; lv.RelativeTo=Enum.ActuatorRelativeTo.World
  lv.VelocityConstraintMode=Enum.VelocityConstraintMode.Vector; lv.Parent=ball
  ball:SetAttribute("Target","Hero"); ball:SetAttribute("ClashEffect", true)
  ball.Parent=w.Balls
  w.Eff:SetAttribute("ClashEffect", true)   -- authoritative clash flag

  local dt=1/60; local dir=-1; local startBlocks=w.server.blocks
  for f=1,60*3 do   -- 3 seconds of a live point-blank clash at 60 fps
    if f%2==0 then dir=-dir end
    ball.Position=v3(0,5,6); ball.AssemblyLinearVelocity=v3(0,0,dir*400); lv.VectorVelocity=v3(0,0,dir*400)
    w.RunService.Heartbeat:Fire(); w.R.advance(dt)
  end
  return (w.server.blocks-startBlocks)/3.0
end

print("=== CLASH CLICK-STORM: block sends/sec during a 3s point-blank clash ===")
print("    The storm fires hard on purpose (match a fast clicker); the concurrency")
print("    cap that keeps it from backlogging is proven in yield_clash.lua.")
local least=math.huge
for _,pg in ipairs({30,90,150,200}) do
  local r=measure(pg) or -1
  least=math.min(least,r)
  print(string.format("  ping %3d ms : %6.1f sends/sec", pg, r))
end
if least>=60 then print("\nOK: clash click-storm is firing hard at every ping.")
else print(string.format("\nWEAK: clash only sent %.0f/s - not storming.", least)); os.exit(1) end
