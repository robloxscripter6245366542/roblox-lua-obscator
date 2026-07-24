-- Clash DIAGNOSTIC: reproduces exactly what your in-game HUD shows (Blocks Sent /
-- Landed / Rejected) plus shield Coverage, across every realistic clash condition,
-- so we can tell WHICH of the three failure modes is happening:
--
--   [1] Sent = 0            -> the script never fires: a DETECTION/TARGETING bug.
--   [2] Sent > 0, Landed=0  -> the server refuses every block: remote/requirement bug.
--   [3] Landed > 0, Cov<100 -> blocks land but leave gaps: timing / ping.
--       Landed > 0, Cov=100 -> the script is doing its job; losses are pure ping/spacing.
--
-- Run: lua-5.1.5/src/lua diag_test.lua        (uses your real-ish ping, 22-75ms)
local HERE = (arg[0] or ""):match("^(.*[/\\])") or "./"
local SCRIPT = arg[1] or (HERE.."../anime_ball_autoparry.lua")
local SRC = assert(io.open(SCRIPT,"r")):read("*a")
local build = dofile(HERE.."world.lua").build

-- Drive a point-blank clash under one set of conditions and return the HUD-style
-- counters. opts: target(str/false), highlight(bool), clashEffect(bool),
-- folderName(str), opponent(bool dash-in), pings.
local function clash(cond)
  local w = build(SRC, cond.ping)
  local v3,Instance,Enum = w.v3,w.Instance,w.Enum
  if cond.highlight ~= false then
    local hl=Instance.new("Highlight"); hl.Name="Highlight"; hl.Parent=w.heroF
  end
  -- optional opponent who dashes into you (the real clash setup)
  if cond.opponent then
    local foe=Instance.new("Model"); foe.Name="Foe"
    local fhrp=Instance.new("Part"); fhrp.Name="HumanoidRootPart"; fhrp.Position=v3(0,5,30)
    fhrp.AssemblyLinearVelocity=v3(0,0,0); fhrp.Parent=foe
    local fhum=Instance.new("Humanoid"); fhum.Parent=foe
    local FOE=Instance.new("Player"); FOE.Name="Foe"; FOE.Character=foe
    table.insert(w.players, FOE)
    w._foe=fhrp
  end
  -- ball container (default the real Balls folder)
  local container = w.Balls
  if cond.folderName then
    container=Instance.new("Folder"); container.Name=cond.folderName; container.Parent=w.Balls.Parent
  end
  local ball=Instance.new("Part"); ball.Name="Ball"
  local lv=Instance.new("LinearVelocity"); lv.Enabled=true; lv.RelativeTo=Enum.ActuatorRelativeTo.World
  lv.VelocityConstraintMode=Enum.VelocityConstraintMode.Vector; lv.Parent=ball
  if cond.target ~= false then ball:SetAttribute("Target", cond.target or "Hero") end
  if cond.clashEffect then ball:SetAttribute("ClashEffect", true) end
  ball.Parent=container

  local dt=1/60; local dir=-1; local covered,total=0,0
  local warm=0.8
  for f=1,60*3 do
    local t=f*dt
    -- opponent dashes in during warmup, then holds point-blank
    if cond.opponent and w._foe then
      local d = (t<warm) and 30 or math.max(3, 30 - (t-warm)*90)
      w._foe.Position=v3(0,5,d)
      w._foe.AssemblyLinearVelocity=v3(0,0, t>=warm and -90 or 0)
    end
    if cond.clashEffect then w.Eff:SetAttribute("ClashEffect", true) end
    if f%2==0 then dir=-dir end
    ball.Position=v3(0,5,6); ball.AssemblyLinearVelocity=v3(0,0,dir*300); lv.VectorVelocity=v3(0,0,dir*300)
    if w.shieldAt(w.R.VTIME()) then w.server.parryReset() end
    w.RunService.Heartbeat:Fire(); w.R.advance(dt)
    if t>warm then total=total+1; if w.shieldAt(w.R.VTIME()) then covered=covered+1 end end
  end
  local s=w.server
  return s.blocks, s.landed, s.rejected, covered/math.max(1,total)
end

local function verdict(sent, landed, cov)
  if sent == 0 then return "[1] NOT FIRING (detection/targeting bug)" end
  if landed == 0 then return "[2] server REFUSED all (remote/requirement)" end
  if cov < 0.98 then return "[3] lands but GAPS (timing/ping)" end
  return "OK - fires, lands, 100% covered (losses = ping/spacing)"
end

-- Every realistic condition, at the user's real ping band.
local conds = {
  {name="normal: Target=Hero + highlight + ClashEffect", target="Hero", highlight=true, clashEffect=true},
  {name="no highlight (attribute only)",                 target="Hero", highlight=false, clashEffect=true},
  {name="no ClashEffect (proximity only)",               target="Hero", highlight=true,  clashEffect=false},
  {name="Target is a userId number, no highlight",        target=12345,  highlight=false, clashEffect=true},
  {name="Target names the OPPONENT (dash-in clash)",      target="Foe",  highlight=false, clashEffect=false, opponent=true},
  {name="no Target at all, no highlight",                 target=false,  highlight=false, clashEffect=true},
  {name="balls in a 'GameBalls' folder",                  target="Hero", highlight=true,  clashEffect=true, folderName="GameBalls"},
}

print("=== CLASH DIAGNOSTIC - what your HUD would read, per condition ===")
for _,pg in ipairs({22, 60, 90}) do
  print(string.format("\n--- ping %d ms ---", pg))
  for _,c in ipairs(conds) do
    c.ping = pg
    local sent, landed, rej, cov = clash(c)
    print(string.format("  Sent %-4d Landed %-4d Rej %-4d Cov %3.0f%%  | %s\n      -> %s",
      sent, landed, rej, cov*100, c.name, verdict(sent, landed, cov)))
  end
end
