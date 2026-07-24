-- Confirms the block send rate during a clash stays SAFE under the game's own
-- rate limiter. The dump's NetRay budget is 120 requests/sec global and 20 per
-- 0.1s burst, shared across ALL remotes; blow it and the block is dropped and a
-- circuit breaker locks it out ~15s - which loses the clash. Spamming can't help
-- anyway (a block is a 0.6s shield on a 1s cooldown; a parry resets it). So the
-- script caps block sends at ~10/s - plenty to keep the shield fresh (proven in
-- yield_clash.lua: 100% coverage) and a tiny slice of the 120/s budget. Here we
-- assert the clash send rate is comfortably under the limit, never a flood.
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

print("=== CLASH block send rate vs the game's rate limit (120/s, 20 per 0.1s) ===")
print("    The rate must stay well under the limit so the block is never dropped;")
print("    ~10/s is plenty to hold the 0.6s shield (coverage proven in yield_clash).")
local worst=0
for _,pg in ipairs({30,90,150,200}) do
  local r=measure(pg) or -1
  worst=math.max(worst,r)
  print(string.format("  ping %3d ms : %6.1f sends/sec", pg, r))
end
-- must be under the 20-per-0.1s burst (i.e. < 200/s) with wide margin, and never
-- near the 120/s global budget it shares with every other remote.
if worst<=30 then print("\nOK: clash send rate is safely under the game's rate limit.")
else print(string.format("\nUNSAFE: clash sent %.0f/s - risks the rate limiter dropping blocks.", worst)); os.exit(1) end
