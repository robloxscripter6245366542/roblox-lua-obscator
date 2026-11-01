-- Replay of REAL miss report #3 (173 ms, Clash Speed 95): a point-blank clash
-- (~9 studs, 270-340 studs/s) that was HOLDING until a ~0.2s lag spike delayed
-- the server's replies. In the report the script stopped SENDING for ~0.16s
-- during the spike, because the cap on blocks waiting for a reply (in flight)
-- was sized at exactly ping x clash speed (16) with no headroom, and the ball got
-- through the gap. Here: yielding Block transport, shield used up per parry (each
-- return needs its own fresh block), and a 0.2s reply delay in the middle.
-- Scores the longest gap between sends during the spike and whether every
-- return was covered. Run: lua lagspike_clash.lua [path-to-autoparry]
local HERE = (arg[0] or ""):match("^(.*[/\\])") or "./"
local SCRIPT = arg[1] or (HERE.."../anime_ball_autoparry.lua")
local SRC = assert(io.open(SCRIPT,"r")):read("*a")
-- the user's setting from the report
SRC = SRC:gsub('setting%("ClashSpeed", 85%)', 'setting("ClashSpeed", 95)')
local build = dofile(HERE.."world.lua").build

local function run(ping, spike)
  local w = assert(build(SRC, ping, {yieldTransport=true}))
  local v3,Instance,Enum,R = w.v3,w.Instance,w.Enum,w.R
  local oneway = ping/1000/2
  local arrivals, used, sends = {}, {}, {}
  local spikeFrom, spikeTo = 1.5, 1.7
  w.server.block = function()
    local t0 = R.VTIME(); sends[#sends+1] = t0
    arrivals[#arrivals+1] = t0 + oneway
    w.server.blocks = w.server.blocks + 1
    local extra = (t0 >= spikeFrom and t0 < spikeTo) and spike or 0   -- replies delayed during the spike
    R.task.wait(oneway*2 + extra)
    return false
  end
  local b=Instance.new("Part"); b.Name="Ball"
  local lv=Instance.new("LinearVelocity"); lv.Enabled=true; lv.RelativeTo=Enum.ActuatorRelativeTo.World
  lv.VelocityConstraintMode=Enum.VelocityConstraintMode.Vector; lv.Parent=b
  b.Parent=w.Balls
  w.clashCtl.Server.StartClash(); w.Eff:SetAttribute("ClashEffect", true)
  local dt=1/60; local nextRet=0.8; local held,total=0,0; local dir=1
  for f=1,60*3 do
    dir=-dir
    b:SetAttribute("Target", dir>0 and "Hero" or "Foe")
    b.Position=v3(0,5,9); b.AssemblyLinearVelocity=v3(0,0,dir*300); lv.VectorVelocity=v3(0,0,dir*300)
    w.RunService.Heartbeat:Fire(); R.advance(dt)
    local now=R.VTIME()
    while now >= nextRet do
      total=total+1
      local ok=false
      for i,a in ipairs(arrivals) do
        if not used[i] and a <= nextRet and a > nextRet-0.6 then used[i]=true; ok=true; break end
      end
      if ok then held=held+1 end
      nextRet=nextRet+0.07
    end
  end
  local gap=0
  for i=2,#sends do
    if sends[i] >= spikeFrom - 0.05 and sends[i-1] <= spikeTo + 0.1 then gap=math.max(gap, sends[i]-sends[i-1]) end
  end
  return held,total,gap
end

print("=== Lag spike during a point-blank clash (Clash Speed 95) ===")
local allOK=true
for _,ping in ipairs({110,170,200}) do
  for _,spike in ipairs({0.15,0.2}) do
    local h,t,gap=run(ping,spike)
    local ok = h==t and gap < 0.06   -- 3 frames at 60 fps = 0.05s
    if not ok then allOK=false end
    print(string.format("  ping %3d  reply delay %.2fs -> held %2d/%2d returns, longest send gap %.3fs  %s", ping, spike, h, t, gap, ok and "OK" or "GAP"))
  end
end
print(allOK and "\nKEPT SENDING THROUGH THE SPIKE" or "\nSENDING STALLED DURING THE SPIKE")
