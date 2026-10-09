function new_dragon()
 dragon=parse_record(dragon_stats)
 dragon.x,dragon.y=start_x,start_y
 nest_x,nest_y=start_x,start_y
 age=1
 tail={}
 for i=1,6 do
  add(tail,{x=dragon.x-i*2,y=dragon.y})
 end
 update_tail()
end

function roar(reach,frames)
 sfx(snd_roar)
 ring(dragon.x,dragon.y,reach)
 for unit in all(units) do
  if unit.brave==0 and dragon_distance(unit.x,unit.y)<reach then
   unit.fear=frames+rnd(frames)
  end
 end
end

function grant(stats)
 for key,value in pairs(parse_record(stats,"/")) do
  dragon[key]+=value
  if fury_time>0 and calm_stats[key] then
   calm_stats[key]+=value
  end
 end
end

function grow()
 age+=1
 local row=ages[age]
 grant(row.stats)
 announce(row.name..": "..row.tip,240)
 roar(120,60)
 jolt(8,10)
 flash=2
end

function heal_dragon(amount)
 dragon.hp=min(dragon.max_hp,dragon.hp+amount)
end

function rest()
 nest_x,nest_y=dragon.x,dragon.y
 dragon.hp=dragon.max_hp
 populate()
 announce("the dragon rests")
 sfx(snd_coin)
 ring(nest_x,nest_y,20)
end

function damage_dragon(amount,dir_x,knock)
 local d=dragon
 if state!="play" or d.charge>0 or d.flash>0 then return end
 if knock then
  d.vx+=dir_x*knock
  if d.flight==0 then d.vy=-2 end
 end
 splat(d.x,d.y)
 d.hp-=amount
 d.flash=d.mercy
 d.calm=240
 jolt(2+amount/8,amount\12)
 poke(0x3201+snd_hurt*68,0x50+mid(2,amount\3+1,7)*2)
 sfx(snd_hurt)
 if d.hp<=0 then
  d.hp=0
  end_game("dead")
  embers(d.x,d.y,40,5)
  sfx(snd_crash)
  jolt(14,20)
  flash=4
 end
end

function update_tail()
 local size=dragon.size
 local prev_x=dragon.x-cos(dragon.angle)*6*size
 local prev_y=dragon.y-sin(dragon.angle)*6*size
 for segment in all(tail) do
  if not solid(segment.x,segment.y+3) then segment.y+=1 end
  local dx,dy=segment.x-prev_x,segment.y-prev_y
  local distance=max(length(dx,dy),.01)/3.5/size
  segment.x=prev_x+dx/distance
  segment.y=prev_y+dy/distance
  prev_x,prev_y=segment.x,segment.y
 end
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
  segment.r=(3-i*.4)*size
  add(body,segment)
 end
end

function dragon_gap(x,y)
 local gap=dragon_distance(x,y)
 if gap<dragon.size*32 then
  for part in all(body) do
   gap=min(gap,length(x-part.x,y-part.y)-part.r)
  end
 end
 return gap
end

function in_breath(x,y,mouth_x,mouth_y)
 local dx,dy=x-mouth_x,y-mouth_y
 local distance=length(dx,dy)
 if distance>dragon.breath_range*dragon.power then return false end
 return (distance<6 or abs(angle_diff(atan2(dx,dy),dragon.angle))<dragon.breath_arc)
  and sight(dragon.x,dragon.y,x,y)
end

function breathe_fire(mouth_x,mouth_y)
 local d=dragon
 local power=(.4+d.fire/d.max_fire)*d.rage
 local flames=d.breath_flames
 d.power=power
 d.fire-=d.breath_cost
 d.fire_delay=8
 if d.fire<=0 then d.winded=true end
 if not d.exhaling then
  d.exhaling=true
  flames*=5
  d.vx-=cos(d.angle)*d.kick*power
  d.vy-=sin(d.angle)*d.kick*power
  jolt(1+d.kick)
  sfx(snd_roar)
 end
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
 if frame%4!=0 then return end
 sfx(snd_breath,3)
 for shot in all(shots) do
  if shot.burns and in_breath(shot.x,shot.y,mouth_x,mouth_y) then
   del(shots,shot)
   ring(shot.x,shot.y,6)
   add_fury(3)
  end
 end
 for unit in all(units) do
  if in_breath(unit.x,unit.y,mouth_x,mouth_y) then
   local fire_taken=unit.fire_taken
   if unit.guard then
    if frame%12==0 then
     shoot(unit,-cos(d.angle),-sin(d.angle),"rebuke")
     embers(unit.x,unit.y,6,2)
    end
   else
    if fire_taken>fireproof then unit.burn=60 end
    damage_unit(unit,d.breath_damage*fire_taken*power*(unit.reeling and 3 or 1))
   end
  end
 end
end

function boost_dragon(stats)
 local before={}
 for key,value in pairs(stats) do
  before[key]=dragon[key]
  dragon[key]=value
 end
 return before
end

function inferno()
 fury=0
 fury_time=fury_frames
 calm_stats=boost_dragon(parse_record(fury_stats))
 for unit in all(units) do
  if dragon_distance(unit.x,unit.y)<nova_range then
   unit.burn=90
   damage_unit(unit,10)
  end
 end
 embers(dragon.x,dragon.y,34,4)
 announce("inferno!")
 jolt(8,6)
 flash=3
 roar(90,60)
end

function charge_impacts(head_x,head_y)
 local d=dragon
 for offset=-3,3,3 do
  ram(d.x+d.charge_x*7-d.charge_y*offset,d.y+d.charge_y*7+d.charge_x*offset)
 end
 for unit in all(units) do
  if unit.charge_id!=d.charge_id and length(unit.x-head_x,unit.y-head_y)<12*d.size then
   unit.charge_id=d.charge_id
   unit.push_x=d.vx
   jolt(3)
   damage_unit(unit,d.bite_damage,true)
  end
 end
end

function update_dragon()
 local d=dragon
 local input_x=tonum(btn(1))-tonum(btn(0))
 local input_y=tonum(btn(3))-tonum(btn(2))
 local up=btn(2)
 local flying=d.flight>0
 d.grounded=blocked(d.x,d.y+1)
 if not btn(4) then d.winded=false end
 local breathing=btn(4) and not d.winded and d.charge<=0 and d.windup<=0

 if fury_time>0 then
  fury_time-=1
  if fury_time==0 then boost_dragon(calm_stats) end
 end

 if d.charge<=0 and d.windup<=0 and not breathing then
  if input_x!=0 then d.facing=input_x end
  local aim_x,aim_y=input_x,input_y
  if not flying and aim_x!=0 then aim_y=max(aim_y) end
  if aim_x==0 and aim_y==0 then aim_x=d.facing end
  d.angle=(d.angle+mid(-d.turn_rate,angle_diff(atan2(aim_x,aim_y),d.angle),d.turn_rate))%1
 end
 local forward_x,forward_y=cos(d.angle),sin(d.angle)
 local reach=9*d.size
 local head_x,head_y=d.x+forward_x*reach,d.y+forward_y*reach

 if d.windup>0 then
  d.windup-=1
  d.vx,d.vy=-d.charge_x,-d.charge_y
  if d.windup==0 then
   d.charge=d.charge_frames
   d.charge_id+=1
   d.vx,d.vy=d.charge_x*d.charge_speed,d.charge_y*d.charge_speed
   jolt(4)
   ring(d.x,d.y,16)
   sfx(snd_roar)
  end
 elseif d.charge>0 then
  d.charge-=1
  charge_impacts(head_x,head_y)
  add_particle(tail[3].x,tail[3].y,0,0,8,"fire")
 else
  local accel=breathing and d.breath_accel or d.accel
  d.vx=(d.vx+input_x*accel)*d.friction
  if flying then
   d.vy=(d.vy+input_y*accel)*d.friction
   if frame%32==0 then sfx(snd_wings) end
  else
   if d.grounded then
    d.flaps_left=d.flaps
    if d.coyote<4 then
     burst(d.x,d.y+3,2,4)
     jolt(d.size*3-2.4)
    end
    d.coyote=6
   end
   d.coyote-=1
   d.vy=min(d.vy+gravity*(up and abs(d.vy)<1 and .5 or 1),fall_speed)
   d.hop=up and not d.was_up and 5 or d.hop-1
   if d.hop>0 and (d.coyote>0 or d.flaps_left>0) then
    if d.coyote<=0 then
     d.flaps_left-=1
     burst(d.x,d.y+4,3,6)
    end
    d.vy=-d.jump
    d.hop,d.coyote=0,0
    sfx(snd_wings)
   end
   if not up and d.vy<0 then d.vy*=.5 end
   d.gliding=up and d.vy>d.glide
   if d.gliding then d.vy=d.glide end
  end
  if btnp(5) then
   if btn(4) and fury>=100 then inferno() end
   if d.charge_speed>0 and d.charge_cooldown<=0 then
    d.charge_x,d.charge_y=d.facing,0
    if flying then d.charge_x,d.charge_y=forward_x,forward_y end
    d.angle=atan2(d.charge_x,d.charge_y)
    d.windup=d.charge_windup
    d.charge_cooldown=d.charge_recover
   end
  end
  d.snap-=1
  for unit in all(units) do
   if d.snap<=0 and unit.brave==0
    and length(unit.x-head_x,unit.y-head_y)<7*d.size then
    d.snap=10
    jolt(2,1)
    damage_unit(unit,d.bite_damage,true)
   end
  end
 end
 d.was_up=up
 d.charge_cooldown-=1
 d.flash=max(0,d.flash-1)

 local hit_x,hit_y=slide(d,d.vx,d.vy)
 if hit_x then d.vx=0 end
 if hit_y then d.vy=0 end
 if (hit_x or hit_y) and d.charge>0 then
  d.charge=0
  jolt(3)
 end

 if fget(mget(d.x\8,(d.y+2)\8),3) then
  d.vy=-3
  damage_dragon(8)
 end
 local nested=mget(d.x\8,d.y\8)==tile_nest
 if nested and not d.nested then rest() end
 d.nested=nested

 if breathing then
  breathe_fire(head_x,head_y)
 else
  d.exhaling=false
  d.fire_delay-=1
  if d.fire_delay<=0 and d.fire<d.max_fire then
   d.fire=min(d.max_fire,d.fire+d.fire_regen+(d.max_fire-d.fire)*d.inhale)
   local angle=rnd()
   add_particle(
    head_x+cos(angle)*12,head_y+sin(angle)*12,
    -cos(angle)*2+d.vx,-sin(angle)*2+d.vy,6,"smoke")
  end
 end

 d.calm-=1
 if d.calm<=0 then heal_dragon(d.regen) end
 if d.hp<d.max_hp/3 and frame%3==0 then
  add_particle(d.x,d.y,0,-.5,14,"smoke")
 end
 update_tail()
end

function draw_dragon()
 local d=dragon
 local x,y,size=d.x,d.y,d.size
 local fx,fy=cos(d.angle)*size,sin(d.angle)*size
 local ux,uy=fy,-fx
 if uy>0 then ux,uy=-ux,-uy end

 local hurt=d.flash%4>1
 pal(8,hurt and 7 or d.body)
 pal(2,hurt and 7 or d.wing)

 for i=#body,6,-1 do
  circfill(body[i].x,body[i].y,body[i].r,i%2==0 and 8 or 2)
 end
 if d.grounded then
  for i=1,2 do
   local part=body[i]
   line(part.x,part.y,part.x+sin(frame/12+i/2)*abs(d.vx),part.y+part.r+1,2)
  end
 end

 local flap=d.charge>0 and -1 or d.grounded and -.8 or d.gliding and .7 or sin(frame/8)
 local span,sweep=7+flap*5,4-flap*2
 local tip_x,tip_y=x+ux*span-fx*sweep,y+uy*span-fy*sweep
 local edge_x,edge_y=x-fx*8-tip_x,y-fy*8-tip_y
 for i=0,1,.1/size do
  line(x,y,tip_x+edge_x*i,tip_y+edge_y*i,2)
 end
 line(x,y,tip_x,tip_y,8)

 for i=1,5 do
  circfill(body[i].x,body[i].y,body[i].r,8)
 end
 line(x+fx*7+ux*3,y+fy*7+uy*3,x+fx*4+ux*5,y+fy*4+uy*5,6)
 pset(x+fx*8+ux*1.5,y+fy*8+uy*1.5,10)
 pal()
end
