-- Measure how many block calls the script SENDS per second during a sustained
-- point-blank clash. During a clash three fire paths (executeParry, the burst,
-- and Auto Spam) each fire the block remote every frame, so the same frame used
-- to send it ~3 times over - ~180 remote calls a second. In real Roblox the
-- block goes through a RemoteFunction whose InvokeServer YIELDS a full round-
-- trip, so those triple-per-frame sends pile into a serial server backlog and
-- the shield lands later and later behind the exchange ("the clashing is so
-- slow"). A block is a 0.6s shield, so one send per frame already holds it. The
-- per-frame dedup (plus the in-flight guard) collapses each frame to a single
-- send. At 60 fps that is ~60/s, not ~180/s. (Stock Lua 5.1 can't yield across
-- the script's pcall, so the sandbox can't model the round-trip itself - it
-- measures the send RATE, which is the flood the dedup removes.)
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

print("=== block-send RATE during a 3s point-blank clash at 60 fps (fires/sec) ===")
print("    one send per frame ~= 60/s is healthy; ~180/s is the triple-per-frame flood.")
local worst=0
for _,pg in ipairs({30,90,150,200}) do
  local r=measure(pg) or -1
  worst=math.max(worst,r)
  print(string.format("  ping %3d ms : %5.1f fires/sec", pg, r))
end
if worst<=75 then print("\nOK: ~one send per frame - no flood.")
else print(string.format("\nFLOOD: %.0f/s (>1 per frame) - the block remote is over-sent.", worst)); os.exit(1) end
