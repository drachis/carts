function spawn_unit(kind,x,y)
 local spec=unit_specs[kind]
 return add(units,setmetatable({
  x=x,
  y=y,
  vy=0,
  hp=spec.max_hp,
  cooldown=30+rnd(30),
  burn=0,
  flash=0,
  clock=0,
  fear=0,
  push_x=0,
  heading=rnd{-1,1},
  wander=0,
  offset_x=rnd(12)-6,
 },spec))
end

function damage_unit(unit,amount,eaten)
 unit.hp-=amount
 unit.flash=3
 if unit.hp>0 then return end
 del(units,unit)
 burst(unit.x,unit.y,4,4)
 coins(unit.x,unit.y,1)
 if unit.color then
  eaten=true
  slain[unit.name]=true
  announce(unit.name.." is devoured",120)
  jolt(8,8)
  flash=2
  ring(unit.x,unit.y,40)
  coins(unit.x,unit.y,25)
  if unit.ward then break_ward(unit.ward) end
  if unit.grants then grow() end
  if unit.crown then end_game("won") end
 end
 if eaten then
  heal_dragon(unit.meal)
  sfx(snd_eat+rnd(3))
  splat(unit.x,unit.y)
 else
  sfx(snd_die+rnd(3))
 end
 kills+=1
 combo+=1
 combo_timer=combo_frames
 add_fury(unit.max_hp/2)
 if streaks[combo] then
  announce(streaks[combo])
  roar(70,30)
 end
end

function update_horde()
 muster-=1
 if muster>0 or crowd>=horde_size+age*4 then return end
 muster=muster_frames
 local side=rnd{-1,1}
 local x=cam_x+64+side*74
 local pool=split(hordes[dragon.y\128+1].pool,"/")
 for y=dragon.y\8*8-28,dragon.y+44,8 do
  if not solid(x,y) and solid(x,y+8) then
   for i=1,1+age do
    spawn_unit(rnd(pool),x+rnd(8)-4,y).heading=-side
   end
   return
  end
 end
end

function shoot(unit,dir_x,dir_y,kind)
 local spec=shot_specs[kind or unit.shot]
 local volley=unit.volley or 1
 for i=1,volley do
  local angle=atan2(dir_x,dir_y)+(i-(volley+1)/2)*spec.fan
  local shot=add(shots,setmetatable({
   x=unit.x,
   y=unit.y,
   vx=cos(angle)*spec.speed,
   vy=sin(angle)*spec.speed,
   target_x=dragon.x+dragon.vx*25,
   target_y=dragon.y,
   damage=unit.damage,
   drop=0,
   age=0,
  },spec))
  if spec.lob then
   shot.drop=.1
   shot.vx=(dragon.x-unit.x)/spec.lob
   shot.vy=(dragon.y-unit.y)/spec.lob-spec.lob*.05
  end
 end
 sfx(spec.sound)
end

function patrol(unit)
 if unit.hit_x or not unit.flies and not solid(unit.x+unit.heading*5,unit.y+5) then
  unit.heading=-unit.heading
 end
 return unit.heading*unit.speed/2,0
end

unit_ai={}

function unit_ai.melee(unit,dir_x,dir_y,distance)
 if distance<=4 and unit.cooldown<=0 then
  damage_dragon(unit.damage,dir_x,unit.knock)
  unit.cooldown=unit.reload
 end
 if not unit.sees then return patrol(unit) end
 if distance>2 then
  return dir_x*unit.speed,dir_y*unit.speed
 end
 return 0,0
end

function unit_ai.ranged(unit,dir_x,dir_y,distance)
 local range,speed=unit.range,unit.speed
 if not unit.sees then return 0,0 end
 if distance<range and unit.cooldown<=0 then
  unit.cooldown=unit.reload+rnd(20)
  shoot(unit,dir_x,dir_y)
 end
 local step=distance>range*.8 and sgn(dir_x) or distance<range*unit.keep_away and -sgn(dir_x) or 0
 if unit.flies then
  return step*speed,sin(frame/90)*.3
 elseif solid(unit.x+step*5,unit.y+5) then
  return step*speed,0
 end
 return 0,0
end

function unit_ai.legend(unit,dir_x,dir_y,distance)
 if not unit.sees and unit.clock<=110 then return patrol(unit) end
 unit.clock=(unit.clock+1)%200
 local clock=unit.clock
 unit.guard=clock>110 and clock<160
 unit.reeling=clock<40
 if unit.reeling then
  return 0,0
 elseif clock<=110 then
  if unit.shot and clock==60 then
   shoot(unit,dir_x,dir_y)
  end
  return unit_ai.melee(unit,dir_x,dir_y,distance)
 elseif clock<185 then
  if clock>=160 then
   unit.flash=2
   unit.dash=sgn(dir_x)*4
  end
  return 0,0
 end
 if distance<=4 then
  damage_dragon(unit.damage*3,dir_x,unit.knock*2)
 end
 return unit.dash,0
end

function unit_ai.sheep(unit,dir_x,dir_y,distance)
 if distance<40 then
  return -sgn(dir_x)*.7,0
 end
 return patrol(unit)
end

function unit_ai.flee(unit,dir_x)
 unit.fear-=1
 return -sgn(dir_x)*unit.speed*2,0
end

function unit_ai.panic(unit)
 unit.burn-=1
 if frame%6==0 then unit.wander=rnd{-1,1} end
 if rnd()<.05 then ignite(unit.x\8,unit.y\8) end
 if rnd()<.4 then add_particle(unit.x,unit.y-3,0,-.5,8,"fire") end
 damage_unit(unit,.05)
 return unit.wander*1.2,0
end

function update_units()
 boss=nil
 crowd=0
 for unit in all(units) do
  if on_screen(unit.x,unit.y,40) then
   crowd+=1
   local dx=dragon.x+unit.offset_x-unit.x
   local dy=dragon.y-unit.y
   local distance=max(length(dx,dy),1)
   local dir_x,dir_y=dx/distance,dy/distance
   distance=dragon_gap(unit.x,unit.y)
   unit.cooldown-=1
   unit.flash=max(0,unit.flash-1)
   unit.sees=distance<sight_range and sight(unit.x,unit.y,dragon.x,dragon.y)
   if unit.sees then
    if unit.color then boss=unit end
    if unit.brave==0 and distance<dragon.dread then
     unit.fear=max(unit.fear,20)
    end
   end

   local ai=unit.burn>0 and "panic" or unit.fear>0 and "flee" or unit.ai
   local move_x,move_y=unit_ai[ai](unit,dir_x,dir_y,distance)
   local grounded=blocked(unit.x,unit.y+1)
   if unit.flies then
    unit.vy=move_y
   else
    unit.vy=min(unit.vy+gravity,fall_speed)
    if unit.hit_x and grounded and move_x!=0 then unit.vy=-2.6 end
   end
   local hit_x,hit_y=slide(unit,move_x+unit.push_x,unit.vy)
   if hit_y then unit.vy=0 end
   unit.hit_x=hit_x
   unit.push_x*=.8
   if move_x!=0 then unit.facing_left=move_x<0 end

   local tile=mget(unit.x\8,unit.y\8)
   if tile==tile_fire and unit.fire_taken>fireproof then
    unit.burn=max(unit.burn,40)
   end
   if fget(tile,3) then damage_unit(unit,1) end
  end
 end
end

function draw_units()
 for unit in all(units) do
  if on_screen(unit.x,unit.y,8) then
   if unit.guard then
    circ(unit.x,unit.y,7,frame%4<2 and 12 or 7)
   end
   if unit.flash>0 then
    for color=1,15 do pal(color,7) end
   elseif unit.color then
    pal(10,unit.color)
   end
   spr(unit.sprite,unit.x-4,unit.y-4,1,1,unit.facing_left)
   pal()
   if unit.reeling then
    print("\146",unit.x-3,unit.y-11+frame%8\4,10)
   elseif unit.burn>0 then
    pset(unit.x-2+rnd(4),unit.y-5+rnd(3),rnd{9,10})
   elseif unit.fear>0 then
    print("!",unit.x-1,unit.y-11,8)
   end
  end
 end
end

function update_shots()
 for shot in all(shots) do
  shot.x+=shot.vx
  shot.y+=shot.vy
  shot.vy+=shot.drop
  shot.age+=1
  local landed=shot.age>=shot.life or solid(shot.x,shot.y)
  if shot.seek then
   shot.vx+=(shot.target_x-shot.x)*.003
   shot.vy+=(shot.target_y-shot.y)*.003
  end
  local distance=dragon_gap(shot.x,shot.y)
  local struck=distance<=0
  if struck then
   splat(shot.x,shot.y,shot.color)
   damage_dragon(shot.damage,sgn(shot.vx),2)
  elseif distance<10 and not shot.grazed then
   shot.grazed=true
   add_fury(2)
  end
  if landed then burst(shot.x,shot.y,2,4) end
  if struck or landed then del(shots,shot) end
 end
end

function draw_shots()
 for shot in all(shots) do
  local x,y=shot.x,shot.y
  if shot.size>0 then
   circfill(x,y,shot.size+1,0)
   circfill(x,y,shot.size,shot.color)
  else
   line(x,y,x-shot.vx*3,y-shot.vy*3,shot.color)
  end
 end
end
