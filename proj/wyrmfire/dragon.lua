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

-- a heavy blow also has a direction and a `knock` that throws the
-- dragon back along it
function damage_dragon(amount,dir_x,dir_y,knock)
 -- nothing touches a charging dragon, or one still reeling from
 -- the last blow (flash doubles as its moment of invulnerability)
 if state!="play" or dragon.charge>0 or dragon.flash>0 then return end
 if knock then
  dragon.vx+=dir_x*knock
  dragon.vy+=dir_y*knock
  jolt(5,2)
 end
 dragon.hp-=amount
 dragon.flash=dragon.mercy
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
 if distance>dragon.breath_range*dragon.power+radius then return false end
 if distance<6+radius then return true end
 return abs(angle_diff(atan2(dx,dy),dragon.angle))<dragon.breath_arc
end

-- a breath is one long exhale: fiercest and longest-reaching on
-- full lungs, guttering as they empty. once empty the dragon is
-- winded and must let go of the button to breathe in.
function breathe_fire(mouth_x,mouth_y)
 local d=dragon
 local power=.4+d.fire/d.max_fire
 local flames=d.breath_flames
 d.power=power
 d.fire-=d.breath_cost
 d.fire_delay=8
 if d.fire<=0 then d.winded=true end
 if not d.exhaling then
  -- the first gasp is a blast
  d.exhaling=true
  flames*=5
  jolt(4)
  sfx(sound.roar)
 end
 -- it rumbles, and pushes the dragon back
 jolt(1)
 d.vx-=cos(d.angle)*d.recoil*power
 d.vy-=sin(d.angle)*d.recoil*power
 for i=1,flames do
  local angle=d.angle+rnd(.1)-.05
  local speed=(d.breath_speed+rnd(1.5))*power
  add_particle(
   mouth_x,mouth_y,
   cos(angle)*speed+d.vx,sin(angle)*speed+d.vy,
   16+rnd(8),"fire",true).ramp=split(d.flame)
 end
 -- the flames are for show; damage is a cone test every few frames
 if frame%4!=0 then return end
 sfx(sound.breath,3)
 -- shots that can burn are eaten by the flames, and feed the fury
 for shot in all(shots) do
  if shot.spec.burns and in_breath(shot.x,shot.y,mouth_x,mouth_y,0) then
   del(shots,shot)
   ring(shot.x,shot.y,6)
   add_fury(3)
  end
 end
 for unit in all(units) do
  if in_breath(unit.x,unit.y,mouth_x,mouth_y,0) then
   local fire_taken=unit.spec.fire_taken
   ring(unit.x,unit.y,5)
   if fire_taken>config.fireproof then unit.burn=60 end
   damage_unit(unit,d.breath_damage*fire_taken*power)
  end
 end
 for building in all(buildings) do
  if in_breath(building.center_x,building.center_y,mouth_x,mouth_y,building.size/2) then
   building.burn=max(building.burn,200)
   damage_building(building,d.breath_damage*power)
  end
 end
end

-- lay a record of stats over the dragon's own, returning what they
-- replaced so the change can be undone the same way
function boost_dragon(stats)
 local before={}
 for key,value in pairs(stats) do
  before[key]=dragon[key]
  dragon[key]=value
 end
 return before
end

-- spend a full fury meter: a nova of fire, then a spell as a
-- greater dragon (fury_stats in data.lua)
function inferno()
 local x,y=dragon.x,dragon.y
 fury=0
 fury_time=config.fury_frames
 calm_stats=boost_dragon(parse_record(fury_stats))
 for unit in all(units) do
  if dragon_distance(unit.x,unit.y)<config.nova_range then
   unit.burn=90
   damage_unit(unit,10)
  end
 end
 for building in all(buildings) do
  if dragon_distance(building.center_x,building.center_y)<config.nova_range then
   building.burn=300
  end
 end
 embers(x,y,34,4)
 ring(x,y,config.nova_range)
 announce("inferno!")
 jolt(8,6)
 flash=3
 sfx(sound.roar)
end

-- while charging the head is a battering ram. each charge has an
-- id so it hits a given target only once.
function charge_impacts(head_x,head_y)
 local d=dragon
 for unit in all(units) do
  if unit.charge_id!=d.charge_id and length(unit.x-head_x,unit.y-head_y)<12 then
   unit.charge_id=d.charge_id
   -- whatever survives the jaws is thrown back
   unit.push_x,unit.push_y=d.vx,d.vy
   jolt(3,1)
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
 if not btn(4) then d.winded=false end
 local breathing=btn(4) and not d.winded and d.charge<=0 and d.windup<=0

 if fury_time>0 then
  fury_time-=1
  if fury_time==0 then boost_dragon(calm_stats) end
 end

 -- the dragon turns to face the way it flies, except mid-charge,
 -- and while breathing: then its aim is locked and it strafes
 local target=(input_x!=0 or input_y!=0) and atan2(input_x,input_y)
 if target and d.charge<=0 and not breathing then
  d.angle=(d.angle+mid(-d.turn_rate,angle_diff(target,d.angle),d.turn_rate))%1
 end

 if d.windup>0 then
  -- coil back for a moment, then burst forward
  d.windup-=1
  d.vx,d.vy=-forward_x,-forward_y
  if d.windup==0 then
   d.charge=d.charge_frames
   d.charge_id+=1
   d.vx,d.vy=forward_x*d.charge_speed,forward_y*d.charge_speed
   jolt(4,1)
   ring(d.x,d.y,16)
   sfx(sound.roar)
  end
 elseif d.charge>0 then
  d.charge-=1
  charge_impacts(head_x,head_y)
  add_particle(tail[3].x,tail[3].y,0,0,8,"fire")
 else
  if target then
   local accel=breathing and d.breath_accel or d.accel
   d.vx+=cos(target)*accel
   d.vy+=sin(target)*accel
  end
  d.vx*=d.friction
  d.vy*=d.friction
  if btnp(5) and d.charge_cooldown<=0 then
   -- charging with the fire held and fury full is an inferno
   if btn(4) and fury>=100 then inferno() end
   d.windup=d.charge_windup
   d.charge_cooldown=d.charge_recover
  end
 end

 d.charge_cooldown-=1
 d.flash=max(0,d.flash-1)
 d.x=mid(8,d.x+d.vx,503)
 d.y=mid(8,d.y+d.vy,503)

 if breathing then
  breathe_fire(head_x,head_y)
 else
  d.exhaling=false
  d.fire_delay-=1
  if d.fire_delay<=0 and d.fire<d.max_fire then
   -- breathe in: a deep gulp at first, slowing as the lungs fill
   d.fire=min(d.max_fire,d.fire+d.fire_regen+(d.max_fire-d.fire)*d.inhale)
   -- air is drawn in to the mouth
   local angle=rnd()
   add_particle(
    head_x+cos(angle)*12,head_y+sin(angle)*12,
    -cos(angle)*2+d.vx,-sin(angle)*2+d.vy,6,"smoke")
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
 -- wings swept back in a charge, raised high while coiling for one
 local flap=charging and -1 or d.windup>0 and 1 or sin(frame/16)

 -- shadow: far below when soaring, tight when diving
 local drop=charging and 2 or 7
 fillp(0x5a5a.8)
 circfill(x+drop,y+drop+2,8,1)
 circfill(x+drop-fx*8,y+drop+2-fy*8,4,1)
 fillp()

 -- drawn in red and purple, then recoloured. it blinks white
 -- while it cannot be hurt.
 local hurt=d.flash%4>1
 pal(8,hurt and 7 or d.body)
 pal(2,hurt and 7 or d.wing)

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
 -- while breathing, show the heart: the only part shots can hit
 if d.exhaling then
  circfill(x,y,2,frame%4<2 and 12 or 1)
  pset(x,y,7)
 end
end
