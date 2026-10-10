function new_dragon()
 dragon=parse_record(dragon_stats)
 age=1
 tail={}
 for i=1,6 do
  add(tail,{x=0,y=0})
 end
end

function next_block()
 block+=1
 block_from=block_to
 block_to=block<3 and block*44 or 128
 build_block()
 built,razed=0,0
 for tx=block_from,block_to-1 do
  for ty=1,12 do
   if standing(mget(tx,stage*16+ty)) then built+=1 end
  end
 end
end

function enter_stage(number)
 stage=number
 cam_x,cam_y,razed,muster,advance=0,stage*128,0,60
 dragon.x,dragon.y,dragon.vx,dragon.vy=start_x,cam_y+start_y,0,0
 units,shots,relics,fires,falls,summoned={},{},{},{},{}
 block,block_to=0,0
 next_block()
 update_tail()
 announce(split(stage_names)[stage+1],120)
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

function feed(meal)
 heal_dragon(meal)
 dragon.belly+=meal
 if dragon.belly>=belly_size then
  dragon.belly-=belly_size
  grant(growth)
  announce("the dragon grows")
  sfx(snd_fanfare)
  ring(dragon.x,dragon.y,24)
 end
end

function damage_dragon(amount,dir_x,knock)
 local d=dragon
 if state!="play" or d.charge>0 or d.flash>0 then return end
 if d.guarding then
  ring(d.x,d.y,12*d.size)
  add_fury(3)
  d.flash=8
  return
 end
 if knock then
  d.vx+=dir_x*knock
  d.vy-=2
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

function in_breath(x,y,mouth_x,mouth_y,reach)
 local dx,dy=x-mouth_x,y-mouth_y
 local distance=length(dx,dy)-(reach or 0)
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
  local stormed=d.storm>0 and dragon_distance(unit.x,unit.cy)<storm_range and sight(d.x,d.y,unit.x,unit.cy)
  if stormed and frame%8==0 then
   ring(unit.x,unit.cy,6)
  end
  if stormed or in_breath(unit.x,unit.cy,mouth_x,mouth_y,unit.reach) then
   local fire_taken=unit.fire_taken
   if unit.shields>0 then
    if frame%12==0 then
     shoot(unit,-cos(d.angle),-sin(d.angle),"rebuke")
     embers(unit.x,unit.y,6,2)
    end
   else
    if fire_taken>fireproof then unit.burn=60 end
    damage_unit(unit,d.breath_damage*fire_taken*power*(unit.stun>0 and 3 or 1))
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
   damage_unit(unit,2.5)
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
 for offset=-6*d.size,6*d.size,4 do
  for along=7,9*d.size+13,6 do
   ram(d.x+d.charge_x*along-d.charge_y*offset,d.y+d.charge_y*along+d.charge_x*offset,true)
  end
 end
 for unit in all(units) do
  if unit.charge_id!=d.charge_id and length(unit.x-head_x,unit.cy-head_y)<12*d.size+unit.reach then
   unit.charge_id=d.charge_id
   unit.push_x=d.vx
   jolt(3)
   if unit.shields>0 then
    unit.shields-=1
    for color in all{12,1,7} do
     splat(unit.x,unit.cy,color)
    end
    ring(unit.x,unit.cy,14)
    sfx(snd_crash)
    if unit.shields==0 then
     unit.stun=stagger_frames
     jolt(5,4)
    end
   else
    damage_unit(unit,d.bite_damage,true)
   end
  end
 end
end

function update_dragon()
 local d=dragon
 local input_x=tonum(btn(1))-tonum(btn(0))
 local input_y=tonum(btn(3))-tonum(btn(2))
 d.grounded=blocked(d.x,d.y+1)
 if not btn(4) then d.winded=false end
 local breathing=btn(4) and not d.winded and d.charge<=0 and d.windup<=0

 if fury_time>0 then
  fury_time-=1
  if fury_time==0 then boost_dragon(calm_stats) end
 end

 if d.charge<=0 and d.windup<=0 and not breathing then
  if input_x!=0 then d.facing=input_x end
  local aim_x=input_x
  local aim_y=d.grounded and min(input_y) or input_y
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
  if d.grounded and input_y>=0 then
   accel*=d.run
   if not d.landed then
    burst(d.x,d.y+3,2,4)
    jolt(d.size*3-2.4)
   end
   if input_x!=0 and frame%4==0 then
    add_particle(d.x,d.y+3,0,-.3,6,"smoke")
   end
  elseif frame%24==0 then
   sfx(snd_wings)
  end
  d.landed=d.grounded
  d.guarding=d.guard>0 and d.grounded and input_x==0 and input_y>=0 and not breathing
  d.vx=(d.vx+input_x*accel)*d.friction
  d.vy=(d.vy+input_y*d.accel+d.sink)*d.friction
  if btnp(5) then
   if btn(4) and fury>=100 then inferno() end
   if d.charge_speed>0 and d.charge_cooldown<=0 then
    d.charge_x,d.charge_y=forward_x,forward_y
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
 d.charge_cooldown-=1
 d.flash=max(0,d.flash-1)

 ram(head_x+d.vx,head_y+d.vy)
 for across=-3,3,3 do
  for down=-3,3,3 do
   ram(d.x+d.vx+across,d.y+d.vy+down)
  end
 end
 if d.charge<=0 and not solid(head_x,head_y) then
  if solid(head_x+d.vx,head_y) then d.vx,d.charge=0,0 end
  if solid(head_x,head_y+d.vy) then d.vy,d.charge=0,0 end
 end
 local hit_x,hit_y=slide(d,d.vx,d.vy)
 if hit_x then d.vx=0 end
 if hit_y then d.vy=0 end
 if (hit_x or hit_y) and d.charge>0 then
  d.charge=0
  jolt(3)
 end


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

 local floor_y,belly=32000,32000
 if d.grounded then
  floor_y=y+3
  belly=floor_y-2.5*size
  y=min(y,belly-4*size)
 end
 local function segment(part,rest_y,color)
  local px,py,reach=part.x,min(part.y,rest_y-part.r),part.r/size
  local base_x,base_y=px+ux*reach,py+uy*reach
  line(base_x,base_y,base_x+ux*2-fx,base_y+uy*2-fy,6)
  circfill(px,py,part.r,color)
 end
 for i=#body,6,-1 do
  segment(body[i],floor_y,i%2==0 and 8 or 2)
 end
 for i=1,2 do
  local part=body[i]
  local hip_y=min(part.y,belly-part.r)+part.r/2
  local foot_x=part.x+d.facing*(i*5-8)*size
  local foot_y=hip_y+4*size
  if d.grounded then
   foot_x,foot_y=part.x+sin(frame/12+i/2)*abs(d.vx)*size,floor_y
  end
  local knee_x,knee_y=(part.x+foot_x)/2-d.facing*1.5*size,(hip_y+foot_y)/2
  for thick=0,size do
   line(part.x+thick,hip_y,knee_x+thick,knee_y,2)
   line(foot_x+thick,foot_y)
  end
  line(foot_x,foot_y,foot_x+d.facing*2*size,foot_y,10)
 end

 local flap=d.charge>0 and -1 or d.grounded and -.8 or sin(frame/8)
 if d.guarding then
  circ(x,y,12*size,frame%4<2 and 12 or 7)
 end
 local span=9+flap*6
 local wrist_x,wrist_y=x+ux*span/2+fx*2,y+uy*span/2+fy*2
 local tips={}
 for finger=0,3 do
  local back,rise=finger*5-3,span*(1.1-finger*.33)
  add(tips,{x-fx*back+ux*rise,y-fy*back+uy*rise})
 end
 for finger=1,3 do
  local from_x,from_y=unpack(tips[finger])
  local to_x,to_y=unpack(tips[finger+1])
  for along=0,1,.12/size do
   local scallop=1+sin(along/2)*.3
   line(wrist_x,wrist_y,
    wrist_x+(from_x+(to_x-from_x)*along-wrist_x)*scallop,
    wrist_y+(from_y+(to_y-from_y)*along-wrist_y)*scallop,2)
  end
 end
 line(x,y,wrist_x,wrist_y,8)
 for tip in all(tips) do
  line(wrist_x,wrist_y,tip[1],tip[2],8)
 end

 for i=1,4 do
  segment(body[i],belly,8)
 end
 circfill(body[5].x,min(body[5].y,belly-body[5].r),body[5].r,8)
 line(x+fx*7+ux*3,y+fy*7+uy*3,x+fx*4+ux*5,y+fy*4+uy*5,6)
 local head=body[4]
 circfill(head.x+ux,min(head.y,belly-head.r)+uy,size/2,10)
 pal()
end
