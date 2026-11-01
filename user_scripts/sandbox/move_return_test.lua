-- You JUMP and DASH while the opponent hits the ball back at you (not a clash).
-- The opponent stands GAP studs away; the ball comes at them from the side; as
-- it reaches them they return it at you 1.2x faster. Meanwhile you jump (a real
-- gravity arc, FloorMaterial = Air) and fire a dash (90 studs/s for 0.3s,
-- MovementController.Dashing = true) at different moments around the hit.
-- The return chases your TRUE position (it's homing on you). Scored with the
-- usual model: 0.6s shield registering half a ping after firing, 1s cooldown.
-- Run: lua move_return_test.lua [path-to-autoparry]
local HERE = (arg[0] or ""):match("^(.*[/\\])") or "./"
local SCRIPT = arg[1] or (HERE.."../anime_ball_autoparry.lua")
local SRC = assert(io.open(SCRIPT,"r")):read("*a")
local build = dofile(HERE.."world.lua").build

-- dashDir: unit-ish x/z of the dash; dashAt: seconds relative to the hit (negative = before)
local function run(ping, gap, speed, dashDirX, dashDirZ, dashAt, jump)
  local w = assert(build(SRC, ping))
  local v3,Instance,Enum,R = w.v3,w.Instance,w.Enum,w.R
  for _=1,30 do w.RunService.Heartbeat:Fire(); R.advance(1/60) end
  local hum = w.char:FindFirstChild("Humanoid")
  local foe=Instance.new("Player"); foe.Name="Foe"
  local fchar=Instance.new("Model"); fchar.Name="Foe"
  local fhrp=Instance.new("Part"); fhrp.Name="HumanoidRootPart"; fhrp.Position=v3(0,5,gap); fhrp.AssemblyLinearVelocity=v3(0,0,0); fhrp.Parent=fchar
  foe.Character=fchar; foe.CharacterAdded=R.newSignal(); foe.CharacterRemoving=R.newSignal()
  w.players[#w.players+1]=foe; w.Players.PlayerAdded:Fire(foe)
  local b=Instance.new("Part"); b.Name="MvBall"
  local lv=Instance.new("LinearVelocity"); lv.Enabled=true; lv.RelativeTo=Enum.ActuatorRelativeTo.World
  lv.VelocityConstraintMode=Enum.VelocityConstraintMode.Vector; lv.Parent=b
  local truePos=v3(70,5,gap); local vel=v3(-speed,0,0)
  b:SetAttribute("Target","Foe"); b.Parent=w.Balls
  local hitT = (70-8)/speed            -- when the ball reaches the foe
  local myPos=v3(0,5,0); local myVel=v3(0,0,0); local vy=0; local airborne=false
  local jumpAt = jump and (hitT-0.25) or 1e9
  local hist={}; local dt=1/60; local t=0; local returned=false; local retSpeed=speed*1.2
  for _=1,60*4 do
    t=t+dt
    -- my movement: jump arc + dash burst
    if t>=jumpAt and not airborne then airborne=true; vy=50 end
    local dx,dz=0,0
    local dashing = (t>=hitT+dashAt and t<hitT+dashAt+0.3)
    if dashing then dx,dz=dashDirX*90,dashDirZ*90 end
    if airborne then vy=vy-196.2*dt end
    myPos=myPos+v3(dx*dt, vy*dt, dz*dt)
    if myPos.Y<=5 and airborne and vy<0 then myPos=v3(myPos.X,5,myPos.Z); airborne=false; vy=0 end
    myVel=v3(dx,vy,dz)
    w.hrp.Position=myPos; w.hrp.AssemblyLinearVelocity=myVel
    hum.FloorMaterial = airborne and Enum.Material.Air or Enum.Material.Plastic
    w.movement.Dashing = dashing
    -- ball
    if not returned and (truePos-fhrp.Position).Magnitude<=8 then
      returned=true; b:SetAttribute("Target","Hero"); w.ballCtl.Server.ChangeBallColor("MvBall","Hero")
    end
    if returned then
      local to=myPos-truePos; local d=to.Magnitude
      vel = d>1e-3 and v3(to.X/d*retSpeed,to.Y/d*retSpeed,to.Z/d*retSpeed) or vel   -- homes on my TRUE position
    end
    truePos=truePos+v3(vel.X*dt,vel.Y*dt,vel.Z*dt)
    hist[#hist+1]={t=t,p=truePos,v=vel}
    local sp,sv=truePos,vel
    for i=#hist,1,-1 do if hist[i].t<=t-w.oneway then sp=hist[i].p; sv=hist[i].v break end end
    b.Position=sp; b.AssemblyLinearVelocity=sv; lv.VectorVelocity=sv
    w.RunService.Heartbeat:Fire(); R.advance(dt)
    if returned and (myPos-truePos).Magnitude<=8 then return w.shieldAt(R.VTIME()), w.server.blocks end
  end
  return nil, w.server.blocks
end

print("=== You jump + dash while the opponent hits it back (not a clash) ===")
local held,lost,tot=0,0,0
local dashes={{"sideways",1,0},{"toward them",0,1},{"away",0,-1}}
for _,ping in ipairs({60,130,200}) do
  for _,gap in ipairs({30,45}) do
    for _,dd in ipairs(dashes) do
      for _,dashAt in ipairs({-0.2,0.0}) do
        local ok,blocks=run(ping,gap,180,dd[2],dd[3],dashAt,true)
        tot=tot+1
        if ok then held=held+1 else lost=lost+1
          print(string.format("  MISS ping %3d gap %2d dash %-11s at %+.1fs (jumping) (%d blocks)",ping,gap,dd[1],dashAt,blocks))
        end
      end
    end
  end
end
print(string.format("\n=== %d/%d parried, %d missed ===",held,tot,lost))
