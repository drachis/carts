-- test_powers.lua : one thing at a time, alone, with what happened printed.
--
-- 1. flying into a wooden wall takes the dragon through it without a charge.
-- 2. a charge with the nose already on a stone wall goes through at full
--    speed: the report gives the slowest it got and how far it travelled.
-- 3. a tower with its foot knocked out comes down, all of it.
-- 4. a legend with its bubbles popped must burn: merlin, at arm's length.

local slowest,from_x=99
local merlin

-- a clear stretch of the shire with a wall of `tile` at column 24
local function wall(tile,height)
 units,falls,fires={},{},{}
 for tx=8,43 do
  for ty=1,12 do mset(tx,stage*16+ty,0) end
 end
 for ty=13-height,12 do mset(24,stage*16+ty,tile) end
end

local function column_left()
 local left=0
 for ty=1,12 do
  if fget(mget(24,ty),0) then left+=1 end
 end
 return left
end

function step()
 local d=dragon
 d.hp=d.max_hp
 muster=99
 hold()
 if n<50 then
  if n==1 then
   wall(1,3)
   d.x,d.y,d.vx,d.vy,d.angle,d.facing=150,100,0,0,0,1
  end
  hold(1)
  if n==49 then
   printh("flight: the dragon flew from 150 to "..flr(d.x).." through a wooden wall at 192")
   assert(d.x>208,"flying did not carry the dragon through wood")
  end
 elseif n<110 then
  if n==50 then
   wall(6,3)
   d.x,d.y,d.vx,d.vy,d.angle,d.facing=181,100,0,0,0,1
   d.charge_cooldown=0
   from_x=d.x
  end
  if n==51 then hold(5) end
  if d.charge>0 then slowest=min(slowest,d.vx) end
  if n==70 then dump_screen("charge") end
  if n==109 then
   printh("charge: nose to a stone wall at 192, went from "..from_x.." to "..flr(d.x)
    ..", slowest "..slowest.." px a frame of "..d.charge_speed)
   assert(d.x>200,"the charge did not carry the dragon through stone")
   assert(slowest>d.charge_speed-.5,"the charge was checked on its way through")
  end
 elseif n<200 then
  if n==110 then
   wall(6,8)
   mset(23,5,1)
   mset(25,5,1)
   d.x,d.y,d.vx,d.vy=120,60,0,0
   ram(196,100,true)
  end
  if n==130 then dump_screen("fall") end
  if n==199 then
   printh("collapse: of a tower of 8 with its foot knocked out, "..column_left().." tiles still stand")
   assert(column_left()==0,"the tower did not all come down")
   assert(not fget(mget(23,5),0) and not fget(mget(25,5),0),"what leaned on the tower did not fall")
  end
 else
  if n==200 then
   enter_stage(2)
   units={}
   wall(0,0)
   merlin=spawn_unit("merlin",cam_x+90,cam_y+60)
  end
  d.x,d.y,d.angle,d.facing,d.vx,d.vy=merlin.x-30,merlin.cy,0,1,0,0
  d.fire=d.max_fire
  merlin.shields,merlin.stun=0,50
  hold(4)
  if n==290 then
   printh("merlin, staggered and burnt for 3 seconds: "..flr(merlin.hp).." of "..merlin.max_hp.." health left")
   assert(merlin.hp<merlin.max_hp,"fire does not hurt a staggered legend")
   printh("ok powers")
   extcmd("shutdown")
  end
 end
end
