-- units.lua : the realm's defenders, their behaviours and shots.
-- what a unit is comes from unit_specs; how it acts is the function
-- in unit_ai named by its spec.

function spawn_unit(kind,x,y,force)
 if #units>=config.max_units and not force then return end
 local spec=unit_specs[kind]
 local unit={
  spec=spec,
  x=mid(4,x,507),
  y=mid(4,y,507),
  hp=spec.hp,
  cooldown=30+rnd(30),
  burn=0,
  flash=0,
  dash=0,
  -- knockback, which decays
  push_x=0,
  push_y=0,
  wander=rnd(),
  -- each unit aims a little off-centre so a mob surrounds the dragon
  offset_x=rnd(16)-8,
  offset_y=rnd(16)-8,
 }
 add(units,unit)
 return unit
end

-- a boss gets a health bar and a herald
function spawn_boss(kind,x,y)
 boss=spawn_unit(kind,x,y,true)
 announce(kind.." rides!",120)
 sfx(sound.fanfare)
end

-- `eaten` is a kill by the dragon's jaws, which makes it a meal
function damage_unit(unit,amount,eaten)
 unit.hp-=amount
 unit.flash=3
 if unit.hp>0 then return end
 local spec=unit.spec
 del(units,unit)
 burst(unit.x,unit.y,4,4)
 if unit==boss then boss=nil end
 if spec.ai=="legend" then
  -- a legend is a feast however it dies
  eaten=true
  announce(spec.name.." has fallen",120)
  jolt(8,8)
  flash=2
  ring(unit.x,unit.y,40)
  coins(unit.x,unit.y,25)
 end
 if eaten then
  heal_dragon(spec.meal)
  sfx(sound.eat)
  -- what is left of it is flung clear
  add_particle(
   unit.x,unit.y,dragon.vx*.5+rnd(2)-1,-2-rnd(2),24,"body").sprite=spec.sprite
 elseif spec.score>0 then
  sfx(sound.die)
 end
 if spec.score>0 then
  kills+=1
  add_score(spec.score,unit.x,unit.y)
  coins(unit.x,unit.y,1)
 end
end

function shoot(unit,dir_x,dir_y)
 local shot=shot_specs[unit.spec.shot]
 add(shots,{
  spec=shot,
  x=unit.x,
  y=unit.y,
  vx=dir_x*shot.speed,
  vy=dir_y*shot.speed,
  -- lobbed shots lead the target; the landing spot is telegraphed
  target_x=dragon.x+dragon.vx*25,
  target_y=dragon.y+dragon.vy*25,
  damage=unit.spec.damage,
  age=0,
 })
 sfx(shot.sound)
end

---------------------------------------------------------------
-- behaviours: each takes the unit, the unit direction to the
-- dragon and its distance, and returns this frame's movement
---------------------------------------------------------------

unit_ai={}

function unit_ai.melee(unit,dir_x,dir_y,distance)
 local spec=unit.spec
 if distance<=11 and unit.cooldown<=0 then
  damage_dragon(spec.damage,dir_x,dir_y,spec.knock)
  unit.cooldown=spec.cooldown
 end
 if distance>10 then
  return dir_x*spec.speed,dir_y*spec.speed
 end
 return 0,0
end

function unit_ai.ranged(unit,dir_x,dir_y,distance)
 local spec=unit.spec
 local range,speed=spec.range,spec.speed
 if distance<range and unit.cooldown<=0 then
  unit.cooldown=spec.cooldown+rnd(20)
  shoot(unit,dir_x,dir_y)
 end
 if distance>range*.8 then
  return dir_x*speed,dir_y*speed
 elseif distance<range*spec.keep_away then
  return -dir_x*speed,-dir_y*speed
 end
 return 0,0
end

-- melee, plus sudden dashes and (with a shot) a ranged attack
function unit_ai.legend(unit,dir_x,dir_y,distance)
 local move_x,move_y=unit_ai.melee(unit,dir_x,dir_y,distance)
 if unit.dash>0 then
  unit.dash-=1
  return unit.dash_x,unit.dash_y
 end
 if distance>20 and distance<70 and rnd()<.04 then
  unit.dash,unit.dash_x,unit.dash_y=12,dir_x*3.5,dir_y*3.5
 end
 if unit.spec.shot and frame%75==0 and distance<100 then
  shoot(unit,dir_x,dir_y)
 end
 return move_x,move_y
end

function unit_ai.sheep(unit,dir_x,dir_y,distance)
 if distance<40 then
  return -dir_x*.7,-dir_y*.7
 end
 if rnd()<.02 then unit.wander=rnd() end
 return cos(unit.wander)*.15,sin(unit.wander)*.15
end

-- anyone on fire runs about, spreading it
function unit_ai.panic(unit)
 unit.burn-=1
 if frame%6==0 then unit.wander=rnd() end
 if rnd()<.05 then ignite(unit.x\8,unit.y\8) end
 if rnd()<.4 then add_particle(unit.x,unit.y-3,0,-.5,8,"fire") end
 damage_unit(unit,.05)
 return cos(unit.wander)*1.2,sin(unit.wander)*1.2
end

function update_units()
 for unit in all(units) do
  local spec=unit.spec
  local dx=dragon.x+unit.offset_x-unit.x
  local dy=dragon.y+unit.offset_y-unit.y
  local distance=max(length(dx,dy),1)
  unit.cooldown-=1
  unit.flash=max(0,unit.flash-1)

  local ai=unit.burn>0 and "panic" or spec.ai
  local move_x,move_y=unit_ai[ai](unit,dx/distance,dy/distance,distance)
  unit.x=mid(4,unit.x+move_x+unit.push_x,507)
  unit.y=mid(4,unit.y+move_y+unit.push_y,507)
  unit.push_x*=.8
  unit.push_y*=.8
  if move_x!=0 then unit.facing_left=move_x<0 end

  if burning_at(unit.x\8,unit.y\8) and spec.fire_taken>config.fireproof then
   unit.burn=max(unit.burn,40)
  end
 end
end

function draw_units()
 for unit in all(units) do
  if on_screen(unit.x,unit.y,8) then
   local spec=unit.spec
   if unit.flash>0 then
    for color=1,15 do pal(color,7) end
   elseif spec.color then
    pal(10,spec.color)
   end
   spr(spec.sprite,unit.x-4,unit.y-4,1,1,unit.facing_left)
   pal()
   if unit.burn>0 then
    pset(unit.x-2+rnd(4),unit.y-5+rnd(3),rnd{9,10})
   end
  end
 end
end

---------------------------------------------------------------
-- shots
---------------------------------------------------------------

function update_shots()
 for shot in all(shots) do
  local spec=shot.spec
  shot.x+=shot.vx
  shot.y+=shot.vy
  shot.age+=1
  local landed=shot.age>=spec.life
  local struck
  if spec.lob then
   -- harmless in the air, a blast where it lands
   struck=landed and dragon_distance(shot.target_x,shot.target_y)<14
   if landed then
    burst(shot.target_x,shot.target_y,8,6)
    jolt(2)
   end
  else
   struck=dragon_distance(shot.x,shot.y)<9
  end
  if struck then damage_dragon(shot.damage) end
  if struck or landed then del(shots,shot) end
 end
end

-- drawn in two passes: `overhead` is above the dragon and the fire
function draw_shots(overhead)
 for shot in all(shots) do
  local spec,x,y=shot.spec,shot.x,shot.y
  local progress=shot.age/spec.life
  if spec.lob then
   if overhead then
    local arc=sin(progress/2)*30
    circfill(
     x+(shot.target_x-x)*progress,
     y+(shot.target_y-y)*progress+arc,spec.size,spec.color)
   else
    -- a closing ring marks where it will land
    circ(shot.target_x,shot.target_y,12-progress*10,8)
   end
  elseif not overhead then
   if spec.size>0 then
    circfill(x,y,spec.size,spec.color)
    pset(x,y,7)
   else
    line(x,y,x-shot.vx*1.5,y-shot.vy*1.5,spec.color)
   end
  end
 end
end
