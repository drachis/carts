-- test_powers.lua : one thing at a time, alone, with what happened printed.
-- every case starts in an empty arena: a stage wiped of buildings, units,
-- relics and shots, with the director held off, so that nothing random can
-- reach in. the cases, 100 frames each:
--   1    flying into a wooden wall takes the dragon through it, no charge
--   2-4  a charge with the nose already on a stone wall, as a small, a
--        middling and a full-grown dragon: through, and never slowed
--   5    a tower with its foot knocked out comes down, all of it
--   6    merlin, his bubbles popped, burns

local wall_x=320
local sizes={0.6,1,1.5}
local slowest,from_x,merlin

local function arena(number)
 enter_stage(number)
 for tx=8,126 do
  for ty=0,12 do mset(tx,stage*16+ty,ty==0 and 51 or 0) end
 end
 units,relics,shots,falls,fires={},{},{},{},{}
 built,razed,freeze=9999,0,0
end

local function wall(tile,height)
 for ty=13-height,12 do mset(wall_x\8,stage*16+ty,tile) end
end

local function standing_at(tx)
 local count=0
 for ty=1,12 do
  if fget(mget(tx,stage*16+ty),0) then count+=1 end
 end
 return count
end

function step()
 local d=dragon
 local case,t=(n-1)\100+1,(n-1)%100
 d.hp=d.max_hp
 muster=99
 hold()
 if t==0 then
  arena(case==6 and 2 or 0)
  d.vx,d.vy,d.angle,d.facing,d.charge_cooldown=0,0,0,1,0
 end

 if case==1 then
  if t==0 then
   wall(1,4)
   d.x,d.y=wall_x-40,cam_y+100
  end
  hold(1)
  if t==60 then
   printh("flight: flew from "..wall_x-40 .." to "..flr(d.x).." through a wooden wall at "..wall_x)
   assert(d.x>wall_x+16,"flying did not carry the dragon through wood")
  end
 elseif case<=4 then
  local size=sizes[case-1]
  if t==0 then
   d.size=size
   wall(6,8)
   d.x,d.y=wall_x-9*size-2,cam_y+100
   from_x,slowest=d.x,99
  end
  if t>0 and t<6 then hold(5) end
  if d.charge>0 then slowest=min(slowest,d.vx) end
  if t==14 then dump_screen("charge"..case-1) end
  if t==60 then
   printh("charge at size "..size..": nose to a stone wall at "..wall_x..", went from "..flr(from_x).." to "..flr(d.x)
    ..", slowest "..slowest.." px a frame of "..d.charge_speed)
   assert(d.x>wall_x+8,"the charge did not carry a dragon of size "..size.." through stone")
   assert(slowest>d.charge_speed-.5,"the charge was checked on its way through at size "..size)
   d.size=0.6
  end
 elseif case==5 then
  if t==0 then
   wall(6,8)
   mset(wall_x\8-1,stage*16+5,1)
   mset(wall_x\8+1,stage*16+5,1)
   d.x,d.y=wall_x-80,cam_y+60
   ram(wall_x+4,cam_y+100,true)
  end
  if t==20 then dump_screen("fall") end
  if t==90 then
   local left=standing_at(wall_x\8)+standing_at(wall_x\8-1)+standing_at(wall_x\8+1)
   printh("collapse: of a tower of 8 with its foot knocked out, and what leaned on it, "..left.." tiles still stand")
   assert(left==0,"the tower did not all come down")
  end
 else
  if t==0 then
   merlin=spawn_unit("merlin",wall_x,cam_y+60)
  end
  d.x,d.y,d.vx,d.vy=merlin.x-30,merlin.cy,0,0
  d.fire=d.max_fire
  merlin.shields,merlin.stun=0,50
  hold(4)
  if t==90 then
   printh("merlin, staggered and burnt for 3 seconds: "..flr(merlin.hp).." of "..merlin.max_hp.." health left")
   assert(merlin.hp<merlin.max_hp,"fire does not hurt a staggered legend")
   printh("ok powers")
   extcmd("shutdown")
  end
 end
end
