-- test_powers.lua : one ability at a time, alone, with what happened printed.
--
-- 1. a whelp charges a hut's wooden wall with its nose already on it. it should go
--    through at full speed: the report gives the slowest it got during the
--    charge and how far it travelled.
-- 2. a legend with its bubbles popped must burn: merlin, at arm's length,
--    for three seconds.
-- 3. flying runs the stamina down and the dragon is then brought to ground.

local wall_x,wall_y
local slowest,from_x=99
local merlin

local function find(name)
 for unit in all(units) do
  if unit.name==name then return unit end
 end
end

function step()
 local d=dragon
 d.hp=d.max_hp
 if n<70 then
  -- 1: the charge
  if n==1 then
   -- the first wooden wall of the shire, and a clear run at it
   for tx=5,60 do
    if not wall_x and fget(mget(tx,12),2) then wall_x,wall_y=tx*8,100 end
   end
   units={}
   -- nose to the wall: the hard case, with no run-up
   d.x,d.y,d.angle,d.facing=wall_x-11,wall_y,0,1
   cam_x=mid(0,d.x-44,896)
   from_x=d.x
  end
  hold()
  if n==2 then hold(5) end
  if d.charge>0 then slowest=min(slowest,d.vx) end
  if n==20 then dump_screen("charge") end
  if n==69 then
   printh("charge: wall at x "..wall_x..", dragon went from "..from_x.." to "..flr(d.x)
    ..", slowest "..slowest.." px a frame of "..d.charge_speed)
   assert(d.x>wall_x+8,"the charge did not carry the dragon through a wooden wall")
   assert(slowest>d.charge_speed-.5,"the charge was checked on its way through the wall")
  end
 elseif n<160 then
  -- 2: burning a staggered legend
  if n==70 then
   enter_stage(2)
   merlin=find("merlin")
   cam_x=896
  end
  d.x,d.y,d.angle,d.facing=merlin.x-30,merlin.cy,0,1
  d.fire=d.max_fire
  merlin.shields,merlin.stun=0,50
  hold(4)
  if n==159 then
   printh("merlin, staggered and burnt for 3 seconds: "..flr(merlin.hp).." of "..merlin.max_hp.." health left")
   assert(merlin.hp<merlin.max_hp,"fire does not hurt a staggered legend")
  end
 else
  -- 3: stamina
  if n==160 then
   enter_stage(0)
   units={}
   d.y,d.stamina,d.spent=cam_y+40,d.max_stamina
  end
  hold(1,2)
  if d.spent and not d.fell_at then d.fell_at=n end
  if d.fell_at and d.grounded then
   printh("stamina: flew for "..(d.fell_at-160)\30 .." seconds, then was on the ground "..(n-d.fell_at).." frames later")
   printh("ok powers")
   extcmd("shutdown")
  end
  assert(n<900,"the dragon never tired and landed")
 end
end
