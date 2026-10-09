function spawn_unit(kind,x,y,force)
 if #units>=max_units and not force then return end
 local spec=unit_specs[kind]
 local unit=setmetatable({
  x=mid(4,x,507),
  y=mid(4,y,507),
  hp=spec.max_hp,
  cooldown=30+rnd(30),
  burn=0,
  flash=0,
  clock=flr(rnd(100)),
  fear=0,
  push_x=0,
  push_y=0,
  wander=rnd(),
  offset_x=rnd(16)-8,
  offset_y=rnd(16)-8,
 },spec)
 add(units,unit)
 return unit
end

function spawn_boss(kind,x,y)
 boss=spawn_unit(kind,x,y,true)
 announce(kind.." rides!",120)
 sfx(snd_fanfare)
end

function damage_unit(unit,amount,eaten)
 unit.hp-=amount
 unit.flash=3
 if unit.hp>0 then return end
 del(units,unit)
 burst(unit.x,unit.y,4,4)
 if unit==boss then boss=nil end
 if unit.guards then unit.guards.hero=nil end
 if unit.color then
  eaten=true
  announce(unit.name.." has fallen",120)
  jolt(8,8)
  flash=2
  ring(unit.x,unit.y,40)
  coins(unit.x,unit.y,25)
 end
 if eaten then
  heal_dragon(unit.meal)
  sfx(snd_eat+rnd(3))
  splat(unit.x,unit.y)
  add(particles,{
   x=unit.x,y=unit.y,vx=rnd(4)-2,vy=-3,
   life=600,span=600,kind="coin",
   meal=unit.meal,sprite=74,
  })
 elseif unit.score>0 then
  sfx(snd_die+rnd(3))
 end
 if unit.score>0 then
  kills+=1
  add_score(unit.score,unit.x,unit.y)
  coins(unit.x,unit.y,1)
 end
end

function shoot(unit,dir_x,dir_y,kind)
 local spec=shot_specs[kind or unit.shot]
 local volley=unit.volley or 1
 for i=1,volley do
  local angle=atan2(dir_x,dir_y)+(i-(volley+1)/2)*spec.fan
  add(shots,setmetatable({
   x=unit.x,
   y=unit.y,
   vx=cos(angle)*spec.speed,
   vy=sin(angle)*spec.speed,
   target_x=dragon.x+dragon.vx*25,
   target_y=dragon.y+dragon.vy*25,
   damage=unit.damage,
   age=0,
  },spec))
 end
 sfx(spec.sound)
end

unit_ai={}

function unit_ai.melee(unit,dir_x,dir_y,distance)
 if distance<=4 and unit.cooldown<=0 then
  damage_dragon(unit.damage,dir_x,dir_y,unit.knock)
  unit.cooldown=unit.reload
 end
 if distance>2 then
  return dir_x*unit.speed,dir_y*unit.speed
 end
 return 0,0
end

function unit_ai.ranged(unit,dir_x,dir_y,distance)
 local range,speed=unit.range,unit.speed
 if distance<range and unit.cooldown<=0 then
  unit.cooldown=unit.reload+rnd(20)
  shoot(unit,dir_x,dir_y)
 end
 if distance>range*.8 then
  return dir_x*speed,dir_y*speed
 elseif distance<range*unit.keep_away then
  return -dir_x*speed,-dir_y*speed
 end
 return 0,0
end

function unit_ai.legend(unit,dir_x,dir_y,distance)
 unit.clock=(unit.clock+1)%200
 local clock=unit.clock
 unit.guard=clock>110 and clock<160
 if clock<=110 then
  if unit.shot and clock==60 then
   shoot(unit,dir_x,dir_y)
  end
  return unit_ai.melee(unit,dir_x,dir_y,distance)
 elseif clock<185 then
  if clock>=160 then
   unit.flash=2
   unit.dash_x,unit.dash_y=dir_x*5,dir_y*5
  end
  return 0,0
 end
 if distance<=4 then
  damage_dragon(unit.damage*3,dir_x,dir_y,unit.knock*2)
 end
 return unit.dash_x,unit.dash_y
end

function unit_ai.sheep(unit,dir_x,dir_y,distance)
 if distance<40 then
  return -dir_x*.7,-dir_y*.7
 end
 if rnd()<.02 then unit.wander=rnd() end
 return cos(unit.wander)*.15,sin(unit.wander)*.15
end

function unit_ai.flee(unit,dir_x,dir_y)
 unit.fear-=1
 local speed=unit.speed*2
 return -dir_x*speed,-dir_y*speed
end

function unit_ai.panic(unit)
 unit.burn-=1
 if frame%6==0 then unit.wander=rnd() end
 if rnd()<.05 then ignite(unit.x\8,unit.y\8) end
 if rnd()<.4 then add_particle(unit.x,unit.y-3,0,-.5,8,"fire") end
 damage_unit(unit,.05)
 return cos(unit.wander)*1.2,sin(unit.wander)*1.2
end

function update_units()
 memset(0x4300,0,0x1000)
 for unit in all(units) do
  local cell=0x4300+unit.x\8+unit.y\8*64
  if peek(cell)>0 then
   unit.push_x+=rnd(2)-1
   unit.push_y+=rnd(2)-1
  end
  poke(cell,1)
  local dx=dragon.x+unit.offset_x-unit.x
  local dy=dragon.y+unit.offset_y-unit.y
  local distance=max(length(dx,dy),1)
  local dir_x,dir_y=dx/distance,dy/distance
  distance=dragon_gap(unit.x,unit.y)
  unit.cooldown-=1
  unit.flash=max(0,unit.flash-1)

  if unit.brave==0 and distance<dragon.weight*12 then
   unit.fear=max(unit.fear,20)
  end
  local ai=unit.burn>0 and "panic" or unit.fear>0 and "flee" or unit.ai
  local move_x,move_y=unit_ai[ai](unit,dir_x,dir_y,distance)
  unit.x=mid(4,unit.x+move_x+unit.push_x,507)
  unit.y=mid(4,unit.y+move_y+unit.push_y,507)
  unit.push_x*=.8
  unit.push_y*=.8
  if move_x!=0 then unit.facing_left=move_x<0 end

  if burning_at(unit.x\8,unit.y\8) and unit.fire_taken>fireproof then
   unit.burn=max(unit.burn,40)
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
   if unit.burn>0 then
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
  shot.age+=1
  local landed=shot.age>=shot.life
  local struck
  if shot.seek then
   shot.vx+=(shot.target_x-shot.x)*.003
   shot.vy+=(shot.target_y-shot.y)*.003
  end
  if shot.lob then
   struck=landed and dragon_gap(shot.target_x,shot.target_y)<8
   if landed then
    burst(shot.target_x,shot.target_y,8,6)
   end
  else
   local distance=dragon_gap(shot.x,shot.y)
   struck=distance<=0
   if struck then splat(shot.x,shot.y,shot.color) end
   if distance<10 and not shot.grazed then
    shot.grazed=true
    add_fury(2)
   end
  end
  if struck then damage_dragon(shot.damage) end
  if struck or landed then del(shots,shot) end
 end
end

function draw_shots()
 for shot in all(shots) do
  local x,y=shot.x,shot.y
  local progress=shot.age/shot.life
  if shot.lob then
   circ(shot.target_x,shot.target_y,12-shot.age*10\shot.life,8)
   circfill(
    x+(shot.target_x-x)*progress,
    y+(shot.target_y-y)*progress+sin(progress/2)*30,shot.size,shot.color)
  else
   if shot.size>0 then
    circfill(x,y,shot.size+1,0)
    circfill(x,y,shot.size,shot.color)
   else
    line(x,y,x-shot.vx*3,y-shot.vy*3,shot.color)
   end
  end
 end
end
