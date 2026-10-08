-- dragon.lua : the player. stats start from dragon_stats (data.lua);
-- the body is drawn procedurally so it can face any direction.

function new_dragon()
 dragon=parse_record(dragon_stats)
 tail={}
 for i=1,6 do
  add(tail,{x=dragon.x-i*4,y=dragon.y})
 end
end

function heal_dragon(amount)
 dragon.hp=min(dragon.max_hp,dragon.hp+amount)
end

function damage_dragon(amount)
 if state!="play" then return end
 -- a charging dragon shrugs off half
 if dragon.charge>0 then amount/=2 end
 dragon.hp-=amount
 dragon.flash=6
 dragon.calm=150
 jolt(2)
 sfx(sound.hurt)
 if dragon.hp<=0 then
  dragon.hp=0
  end_game("dead")
 end
end

-- each tail segment is dragged a fixed distance behind the last
function update_tail()
 local prev_x=dragon.x-cos(dragon.angle)*6
 local prev_y=dragon.y-sin(dragon.angle)*6
 for segment in all(tail) do
  local dx,dy=segment.x-prev_x,segment.y-prev_y
  local distance=max(length(dx,dy),.01)
  segment.x=prev_x+dx/distance*3.5
  segment.y=prev_y+dy/distance*3.5
  prev_x,prev_y=segment.x,segment.y
 end
end

-- is a target of this radius inside the cone of fire?
function in_breath(x,y,mouth_x,mouth_y,radius)
 local dx,dy=x-mouth_x,y-mouth_y
 local distance=length(dx,dy)
 if distance>dragon.breath_range+radius then return false end
 if distance<6+radius then return true end
 return abs(angle_diff(atan2(dx,dy),dragon.angle))<dragon.breath_arc
end

function breathe_fire(mouth_x,mouth_y)
 local d=dragon
 d.fire-=d.breath_cost
 d.fire_delay=30
 for i=1,3 do
  local angle=d.angle+rnd(.1)-.05
  local speed=2.5+rnd(1.5)
  add_particle(
   mouth_x,mouth_y,
   cos(angle)*speed+d.vx,sin(angle)*speed+d.vy,
   16+rnd(8),"fire",true)
 end
 -- the flames are for show; damage is a cone test every few frames
 if frame%4!=0 then return end
 sfx(sound.breath,3)
 for unit in all(units) do
  if in_breath(unit.x,unit.y,mouth_x,mouth_y,0) then
   local fire_taken=unit.spec.fire_taken
   if fire_taken>config.fireproof then unit.burn=60 end
   damage_unit(unit,d.breath_damage*fire_taken)
  end
 end
 for building in all(buildings) do
  if in_breath(building.center_x,building.center_y,mouth_x,mouth_y,building.size/2) then
   building.burn=max(building.burn,200)
   damage_building(building,d.breath_damage)
  end
 end
end

-- while charging the head is a battering ram. each charge has an
-- id so it hits a given target only once.
function charge_impacts(head_x,head_y)
 local d=dragon
 for unit in all(units) do
  if unit.charge_id!=d.charge_id and length(unit.x-head_x,unit.y-head_y)<12 then
   unit.charge_id=d.charge_id
   damage_unit(unit,d.bite_damage,true)
  end
 end
 for building in all(buildings) do
  local x,y=building.center_x,building.center_y
  if building.charge_id!=d.charge_id
   and length(x-head_x,y-head_y)<8+building.size/2 then
   building.charge_id=d.charge_id
   -- hitting a wall ends the charge
   d.charge=min(d.charge,3)
   jolt(6)
   burst(x,y,8,building.size)
   sfx(sound.crash)
   damage_building(building,d.charge_damage)
  end
 end
end

function update_dragon()
 local d=dragon
 local input_x,input_y=0,0
 if btn(0) then input_x-=1 end
 if btn(1) then input_x+=1 end
 if btn(2) then input_y-=1 end
 if btn(3) then input_y+=1 end

 local forward_x,forward_y=cos(d.angle),sin(d.angle)
 local head_x,head_y=d.x+forward_x*11,d.y+forward_y*11
 -- button 4 (z) breathes, button 5 (x) charges
 local breathing=btn(4) and d.fire>1 and d.charge<=0

 if d.charge>0 then
  d.charge-=1
  charge_impacts(head_x,head_y)
 else
  if input_x!=0 or input_y!=0 then
   local target=atan2(input_x,input_y)
   d.angle=(d.angle+mid(-d.turn_rate,angle_diff(target,d.angle),d.turn_rate))%1
   local accel=breathing and d.breath_accel or d.accel
   d.vx+=cos(target)*accel
   d.vy+=sin(target)*accel
  end
  d.vx*=d.friction
  d.vy*=d.friction
  if btnp(5) and d.charge_cooldown<=0 then
   d.charge=d.charge_frames
   d.charge_cooldown=d.charge_recover
   d.charge_id+=1
   d.vx,d.vy=forward_x*d.charge_speed,forward_y*d.charge_speed
   jolt(3)
   sfx(sound.roar)
  end
 end

 d.charge_cooldown-=1
 d.flash=max(0,d.flash-1)
 d.x=mid(8,d.x+d.vx,503)
 d.y=mid(8,d.y+d.vy,503)

 if breathing then
  breathe_fire(head_x,head_y)
 else
  d.fire_delay-=1
  if d.fire_delay<=0 then
   d.fire=min(d.max_fire,d.fire+d.fire_regen)
  end
 end

 d.calm-=1
 if d.calm<=0 then heal_dragon(d.regen) end
 update_tail()
end

function draw_dragon()
 local d=dragon
 local x,y=d.x,d.y
 local fx,fy=cos(d.angle),sin(d.angle) -- forward
 local sx,sy=-fy,fx                    -- sideways
 local charging=d.charge>0
 local flap=charging and -1 or sin(frame/16)

 -- shadow: far below when soaring, tight when diving
 local drop=charging and 2 or 7
 fillp(0x5a5a.8)
 circfill(x+drop,y+drop+2,8,1)
 circfill(x+drop-fx*8,y+drop+2-fy*8,4,1)
 fillp()

 if d.flash>0 then
  pal(8,7)
  pal(2,7)
 end

 for i=#tail,1,-1 do
  circfill(tail[i].x,tail[i].y,4-i*.5,i%2==0 and 2 or 8)
 end

 for side=-1,1,2 do
  -- wing: a fan of lines from the shoulder makes the membrane,
  -- then three bones over it
  local span,sweep=13+flap*3,3-flap*2
  local shoulder_x,shoulder_y=x+fx*2+sx*side*3,y+fy*2+sy*side*3
  local tip_x,tip_y=x+sx*side*span-fx*sweep,y+sy*side*span-fy*sweep
  local edge_x,edge_y=x-fx*7+sx*side*3-tip_x,y-fy*7+sy*side*3-tip_y
  for i=0,1,.07 do
   line(shoulder_x,shoulder_y,tip_x+edge_x*i,tip_y+edge_y*i,2)
  end
  for bone in all{0,.4,.75} do
   line(shoulder_x,shoulder_y,tip_x+edge_x*bone,tip_y+edge_y*bone,8)
  end
  -- horn
  line(
   x+fx*9+sx*side*2,y+fy*9+sy*side*2,
   x+fx*5+sx*side*5,y+fy*5+sy*side*5,6)
 end

 -- body: haunches, chest, neck, head, snout. each is a circle at
 -- some distance along the spine.
 for part in all{{-4,4},{0,5},{6,3},{10,3},{13,2}} do
  circfill(x+fx*part[1],y+fy*part[1],part[2],8)
 end
 for i=-7,5,3 do
  pset(x+fx*i,y+fy*i,2)
 end
 for side=-1,1,2 do
  pset(x+fx*11+sx*side*2,y+fy*11+sy*side*2,10)
 end
 pal()
end
