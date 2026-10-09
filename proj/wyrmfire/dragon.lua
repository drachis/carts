-- dragon.lua : the player. stats start from dragon_stats (data.lua);
-- the body is drawn procedurally so it can face any direction.

function new_dragon()
 dragon=parse_record(dragon_stats)
 age=1
 tail={}
 for i=1,6 do
  add(tail,{x=dragon.x-i*4,y=dragon.y})
 end
 update_tail()
end

-- a roar is heard `reach` pixels away. everyone there who is not
-- brave is struck with dragonfear and flees for a while.
function roar(reach,frames)
 sfx(snd_roar)
 ring(dragon.x,dragon.y,reach)
 for unit in all(units) do
  if unit.brave==0 and dragon_distance(unit.x,unit.y)<reach then
   unit.fear=frames+rnd(frames)
  end
 end
end

-- add a record of stats to the dragon's own, for good: boons and
-- growth. during an inferno the calm stats must gain them too.
function grant(stats)
 for key,value in pairs(parse_record(stats,"/")) do
  dragon[key]+=value
  if fury_time>0 and calm_stats[key] then
   calm_stats[key]+=value
  end
 end
end

-- how far the dragon has eaten towards its next age, 0 to 1. at
-- the last age there is nothing left to grow into.
function belly_fill()
 local next_age=ages[age+1]
 return next_age and belly/next_age.meals or 0
end

-- a meal reaches the gauge, which pops for a moment
function feed(meal)
 belly+=meal
 belly_pop=8
 sfx(snd_coin)
 if belly_fill()>=1 then grow() end
end

-- it has eaten enough: the dragon comes of age
function grow()
 age+=1
 belly=0
 grant(ages[age].stats)
 announce("you are now a "..ages[age].name.."!",150)
 roar(120,60)
 jolt(8,10)
 flash=2
end

function heal_dragon(amount)
 dragon.hp=min(dragon.max_hp,dragon.hp+amount)
end

-- a heavy blow also has a direction and a `knock`, the distance it
-- throws the dragon back along it
function damage_dragon(amount,dir_x,dir_y,knock)
 -- nothing touches a charging dragon, or one still reeling from
 -- the last blow (flash doubles as its moment of invulnerability)
 if state!="play" or dragon.charge>0 or dragon.flash>0 then return end
 if knock then
  -- knock is how many pixels the dragon is thrown: sliding to a
  -- stop under friction f covers its starting speed over 1-f
  knock*=1-dragon.friction
  dragon.vx+=dir_x*knock
  dragon.vy+=dir_y*knock
 end
 splat(dragon.x,dragon.y)
 dragon.hp-=amount
 dragon.flash=dragon.mercy
 dragon.calm=240
 -- the harder the blow, the harder the screen is shaken and the
 -- longer the game holds on it: a pinprick passes, a lunge lands
 jolt(2+amount/8,amount\12)
 -- and the louder it sounds: the hurt sfx is one fading note
 -- whose second byte is 0x50 plus twice its volume, rewritten for
 -- each blow. a really heavy one has a crash under it too.
 poke(0x3201+snd_hurt*68,0x50+mid(2,amount\3+1,7)*2)
 sfx(snd_hurt)
 if dragon.hp<=0 then
  -- it dies in a storm of its own fire, with a last roar, and
  -- then (see _update) spins away to nothing
  dragon.hp=0
  end_game("dead")
  embers(dragon.x,dragon.y,40,5)
  roar(120,90)
  jolt(14,20)
  flash=4
 end
end

-- each tail segment is dragged a fixed distance behind the last
function update_tail()
 local size=dragon.size
 local prev_x=dragon.x-cos(dragon.angle)*6*size
 local prev_y=dragon.y-sin(dragon.angle)*6*size
 for segment in all(tail) do
  local dx,dy=segment.x-prev_x,segment.y-prev_y
  local distance=max(length(dx,dy),.01)/3.5/size
  segment.x=prev_x+dx/distance
  segment.y=prev_y+dy/distance
  prev_x,prev_y=segment.x,segment.y
 end
 update_body()
end

-- the dragon's body is a list of circles: five along the spine
-- from haunches to snout (body_shape in data.lua), then the tail.
-- it is rebuilt each frame and is both what is drawn and what can
-- be hit, so the two always agree.
function update_body()
 local size=dragon.size
 body={}
 for i=1,9,2 do
  local along=body_shape[i]*size
  add(body,{
   x=dragon.x+cos(dragon.angle)*along,
   y=dragon.y+sin(dragon.angle)*along,
   r=body_shape[i+1]*size,
  })
 end
 for i,segment in ipairs(tail) do
  segment.r=(4-i*.5)*size
  add(body,segment)
 end
end

-- how far a point is from the dragon's skin: zero or less is a
-- touch. far-off points skip the per-circle test.
function dragon_gap(x,y)
 local gap=dragon_distance(x,y)
 if gap<dragon.size*32 then
  for part in all(body) do
   gap=min(gap,length(x-part.x,y-part.y)-part.r)
  end
 end
 return gap
end

-- is a target of this radius inside the cone of fire?
function in_breath(x,y,mouth_x,mouth_y,radius)
 local dx,dy=x-mouth_x,y-mouth_y
 local distance=length(dx,dy)
 if distance>dragon.breath_range*dragon.power+radius or dome_over(x,y) then return false end
 if distance<6+radius then return true end
 return abs(angle_diff(atan2(dx,dy),dragon.angle))<dragon.breath_arc
end

-- a breath is one long exhale: fiercest and longest-reaching on
-- full lungs, guttering as they empty. once empty the dragon is
-- winded and must let go of the button to breathe in.
function breathe_fire(mouth_x,mouth_y)
 local d=dragon
 local power=(.4+d.fire/d.max_fire)*d.rage
 local flames=d.breath_flames
 d.power=power
 d.fire-=d.breath_cost
 d.fire_delay=8
 if d.fire<=0 then d.winded=true end
 if not d.exhaling then
  -- the first gasp is a blast that kicks the dragon back, harder
  -- the fuller its lungs and the greater its age
  d.exhaling=true
  flames*=5
  d.vx-=cos(d.angle)*d.kick*power
  d.vy-=sin(d.angle)*d.kick*power
  jolt(2+d.kick)
  sfx(snd_roar)
 end
 -- it pushes the dragon back
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
 sfx(snd_breath,3)
 -- shots that can burn are eaten by the flames, and feed the fury
 for shot in all(shots) do
  if shot.burns and in_breath(shot.x,shot.y,mouth_x,mouth_y,0) then
   del(shots,shot)
   ring(shot.x,shot.y,6)
   add_fury(3)
  end
 end
 for unit in all(units) do
  if in_breath(unit.x,unit.y,mouth_x,mouth_y,0) then
   local fire_taken=unit.fire_taken
   if unit.guard then
    -- a raised guard throws the fire back, and sprays it aside
    if frame%12==0 then
     shoot(unit,-cos(d.angle),-sin(d.angle),"rebuke")
     embers(unit.x,unit.y,6,2)
    end
   else
    if fire_taken>fireproof then unit.burn=60 end
    damage_unit(unit,d.breath_damage*fire_taken*power)
   end
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
 fury_time=fury_frames
 calm_stats=boost_dragon(parse_record(fury_stats))
 for unit in all(units) do
  if dragon_distance(unit.x,unit.y)<nova_range then
   unit.burn=90
   damage_unit(unit,10)
  end
 end
 for building in all(buildings) do
  if dragon_distance(building.center_x,building.center_y)<nova_range then
   building.burn=300
  end
 end
 embers(x,y,34,4)
 announce("inferno!")
 jolt(8,6)
 flash=3
 roar(90,60)
end

-- while charging the head is a battering ram. each charge has an
-- id so it hits a given target only once.
function charge_impacts(head_x,head_y)
 local d=dragon
 for unit in all(units) do
  if unit.charge_id!=d.charge_id and length(unit.x-head_x,unit.y-head_y)<12*d.size then
   unit.charge_id=d.charge_id
   -- whatever survives the jaws is thrown back
   unit.push_x,unit.push_y=d.vx,d.vy
   jolt(3)
   damage_unit(unit,d.bite_damage,true)
  end
 end
 for building in all(buildings) do
  local x,y=building.center_x,building.center_y
  if building.charge_id!=d.charge_id
   and length(x-head_x,y-head_y)<8*d.size+building.size/2 then
   building.charge_id=d.charge_id
   -- hitting a wall ends the charge
   d.charge=min(d.charge,3)
   jolt(6)
   burst(x,y,8,building.size)
   sfx(snd_crash)
   damage_building(building,d.charge_damage)
  end
 end
end

function update_dragon()
 local d=dragon
 -- buttons 0..3 are left, right, up, down; tonum makes each 1 or 0
 local input_x=tonum(btn(1))-tonum(btn(0))
 local input_y=tonum(btn(3))-tonum(btn(2))

 local forward_x,forward_y=cos(d.angle),sin(d.angle)
 local reach=11*d.size
 local head_x,head_y=d.x+forward_x*reach,d.y+forward_y*reach
 -- wingbeats
 if frame%32==0 then
  sfx(snd_wings)
 end
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
   jolt(4)
   ring(d.x,d.y,16)
   sfx(snd_roar)
  end
 elseif d.charge>0 then
  d.charge-=1
  charge_impacts(head_x,head_y)
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
  -- jaws: whatever is not brave and passes under the head is
  -- snapped up, a mouthful at a time
  d.snap-=1
  for unit in all(units) do
   if d.snap<=0 and unit.brave==0
    and length(unit.x-head_x,unit.y-head_y)<6*d.size then
    d.snap=10
    jolt(2,1)
    damage_unit(unit,d.bite_damage,true)
   end
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
 -- close to death it trails smoke
 if d.hp<d.max_hp/3 and frame%3==0 then
  add_particle(d.x,d.y,0,-.5,14,"smoke")
 end
 update_tail()
end

function draw_dragon()
 local d=dragon
 local x,y=d.x,d.y
 -- the forward and sideways vectors are scaled by the dragon's
 -- size, so every offset below grows with it; radii are scaled
 -- one by one
 local size=d.size
 local fx,fy=cos(d.angle)*size,sin(d.angle)*size
 local sx,sy=-fy,fx
 local charging=d.charge>0
 -- wings swept back in a charge, raised high while coiling for one
 local flap=charging and -1 or d.windup>0 and 1 or sin(frame/16)

 -- shadow: far below when soaring, tight when diving
 local drop=charging and 2 or 7
 fillp(0x5a5a.8)
 circfill(x+drop,y+drop+2,8*size,1)
 circfill(x+drop-fx*8,y+drop+2-fy*8,4*size,1)
 fillp()

 -- drawn in red and purple, then recoloured. it blinks white
 -- while it cannot be hurt.
 local hurt=d.flash%4>1
 pal(8,hurt and 7 or d.body)
 pal(2,hurt and 7 or d.wing)

 -- the tail, tip first (body[6] onwards)
 for i=#body,6,-1 do
  circfill(body[i].x,body[i].y,body[i].r,i%2==0 and 8 or 2)
 end

 for side=-1,1,2 do
  -- wing: a fan of lines from the shoulder makes the membrane,
  -- then three bones over it
  local span,sweep=13+flap*3,3-flap*2
  local shoulder_x,shoulder_y=x+fx*2+sx*side*3,y+fy*2+sy*side*3
  local tip_x,tip_y=x+sx*side*span-fx*sweep,y+sy*side*span-fy*sweep
  local edge_x,edge_y=x-fx*7+sx*side*3-tip_x,y-fy*7+sy*side*3-tip_y
  for i=0,1,.07/size do
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

 -- haunches, chest, neck, head, snout
 for i=1,5 do
  circfill(body[i].x,body[i].y,body[i].r,8)
 end
 for i=-7,5,3 do
  pset(x+fx*i,y+fy*i,2)
 end
 for side=-1,1,2 do
  pset(x+fx*11+sx*side*2,y+fy*11+sy*side*2,10)
 end
 pal()
end
