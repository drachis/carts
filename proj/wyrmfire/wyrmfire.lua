-- wyrmfire.lua : top-down dragon rampage.
--
-- the world is 64x64 tiles held in map ram (ground only). buildings,
-- units, shots, fires and particles are lua objects drawn over it.
-- angles are pico-8 turns; (cos(a),sin(a)) is always "forward".

---------------------------------------------------------------
-- constants
---------------------------------------------------------------

local MAP_SIZE=64
local TILE_SIZE=8
local WORLD_MAX=MAP_SIZE*TILE_SIZE-1
local SCREEN=128

local STATE={TITLE=0,PLAY=1,DEAD=2,WON=3}

local BTN={LEFT=0,RIGHT=1,UP=2,DOWN=3,FIRE=4,CHARGE=5}

-- sprite ids of ground tiles (see gen_gfx.py)
local GRASS,FLOWERS,TREE,ROAD,WATER=1,2,3,4,5
local SCORCHED,STUMP,WHEAT,BRIDGE,RUBBLE,ASH=6,7,8,9,10,12

local SFX={
 BREATH=0,ROAR=1,CRASH=2,HURT=3,DIE=4,
 ARROW=5,FANFARE=6,CATAPULT=7,EAT=8,
}

local PARTICLE={FIRE=1,SMOKE=2,DEBRIS=3}

local MAX_UNITS=45
local MAX_PARTICLES=320
local MAX_FIRES=220

local DRAGON_MAX_HP=100
local DRAGON_MAX_FIRE=100
local DRAGON_ACCEL=.3
local DRAGON_BREATH_ACCEL=.12 -- slower while breathing
local DRAGON_FRICTION=.88
local DRAGON_TURN_RATE=.04
local CHARGE_SPEED=5
local CHARGE_FRAMES=12
local CHARGE_COOLDOWN=45
local CHARGE_DAMAGE=30
local BREATH_RANGE=44
local BREATH_HALF_ANGLE=.09
local BREATH_COST=.9
local BREATH_DAMAGE=2
local ALARM_RANGE=110 -- buildings this close send defenders
local ROCK_FLIGHT_FRAMES=50

-- flammable ground: chance to spread per attempt, burn time in
-- frames, and the tile left behind
local flammable={
 [GRASS]={spread=.05,time=24,becomes=SCORCHED},
 [FLOWERS]={spread=.05,time=24,becomes=SCORCHED},
 [TREE]={spread=.14,time=90,becomes=STUMP},
 [WHEAT]={spread=.4,time=45,becomes=ASH},
}

-- size is in tiles. spawns names a unit type; the keep sends a mix.
local building_types={
 hut={sprite=16,size=1,hp=10,score=10,spawns={"serf"},spawn_rate=260},
 house={sprite=17,size=1,hp=18,score=25,spawns={"serf"},spawn_rate=200},
 tower={sprite=18,size=1,hp=30,score=50,spawns={"archer"},spawn_rate=170},
 church={sprite=32,size=2,hp=60,score=120,spawns={"champion"},spawn_rate=420},
 keep={sprite=34,size=2,hp=200,score=1000,spawn_rate=150,
  spawns={"knight","knight","archer","ballista","catapult"}},
}

-- range 0 means melee. fire_taken scales breath damage; anything at
-- or below FIREPROOF never catches alight.
local FIREPROOF=.35
local unit_types={
 serf={sprite=64,hp=3,speed=.5,damage=1,range=0,cooldown=30,fire_taken=1,score=5},
 archer={sprite=65,hp=4,speed=.45,damage=2,range=60,cooldown=70,fire_taken=1,score=10,
  shot_speed=2.2,shot_color=4},
 knight={sprite=66,hp=12,speed=.8,damage=4,range=0,cooldown=30,fire_taken=.5,score=25},
 champion={sprite=67,hp=20,speed=.5,damage=4,range=70,cooldown=90,fire_taken=.3,score=50,
  shot_speed=1.6,shot_color=10,shot_big=true},
 ballista={sprite=69,hp=15,speed=.2,damage=8,range=100,cooldown=120,fire_taken=.7,score=40,
  shot_speed=4.5,shot_color=7,siege=true},
 catapult={sprite=70,hp=15,speed=.2,damage=12,range=110,cooldown=150,fire_taken=.7,score=40,
  lobs_rocks=true,siege=true},
 legend={sprite=68,hp=80,speed=1,damage=6,range=0,cooldown=40,fire_taken=.3,score=500},
 sheep={sprite=71,hp=1,speed=.3,damage=0,range=0,cooldown=0,fire_taken=1,score=0},
}

-- arthurian legends, in the order the realm sends them
local legends={
 {name="sir gawain",color=11,hp=60},
 {name="sir percival",color=14,hp=80},
 {name="sir galahad",color=7,hp=100},
 {name="sir lancelot",color=13,hp=120},
 {name="king arthur",color=10,hp=140,damage=10,excalibur=true},
}
local ARTHUR=#legends

-- wrath (1..5) rises with score and picks who reinforces
local wrath_thresholds={0,300,900,2000,3600}
local reinforcements={
 {"serf","serf","archer"},
 {"serf","archer","knight"},
 {"archer","knight","knight","champion"},
 {"knight","knight","champion","ballista","catapult"},
 {"knight","champion","champion","ballista","catapult","catapult"},
}

-- settlement layout on a 3x3 grid, lair in the top-left corner and
-- camelot furthest from it
local settlement_grid={
 "lair","village","village",
 "village","town","town",
 "village","town","camelot",
}
local settlement_buildings={
 lair={},
 village={"house","hut","hut","hut","house","hut"},
 town={"church","tower","tower","house","house","house","house","house","house","hut","hut"},
 camelot={"church","tower","tower","house","house","house","house","house"},
}
local settlement_radius={lair=3,village=4,town=5,camelot=6}

---------------------------------------------------------------
-- state
---------------------------------------------------------------

local state,frame,end_frame,high_score
local dragon,tail,camelot,boss
local buildings,units,particles,shots,rocks,fires
local occupied -- tile index -> building standing on it
local burning  -- tile index -> fire on it
local building_total
local score,kills,wrath,legends_sent,arthur_sent
local shake,message,message_timer,reinforce_timer

---------------------------------------------------------------
-- helpers
---------------------------------------------------------------

-- vector length, scaled so the squares stay inside 16.16 fixed point
local function length(x,y)
 x/=64
 y/=64
 return sqrt(x*x+y*y)*64
end

local function tile_index(tx,ty)
 return tx+ty*MAP_SIZE
end

local function in_map(tx,ty)
 return tx>=0 and ty>=0 and tx<MAP_SIZE and ty<MAP_SIZE
end

-- signed shortest difference between two angles, in turns
local function angle_diff(a,b)
 return (a-b+.5)%1-.5
end

local function on_screen(x,y,cam_x,cam_y,margin)
 return x>cam_x-margin and x<cam_x+SCREEN+margin
  and y>cam_y-margin and y<cam_y+SCREEN+margin
end

local function announce(text,frames)
 message,message_timer=text,frames or 90
end

local function add_particle(x,y,vx,vy,life,kind,ignites)
 if #particles<MAX_PARTICLES then
  add(particles,{x=x,y=y,vx=vx,vy=vy,life=life,kind=kind,ignites=ignites})
 end
end

local function burst(x,y,count,spread)
 for i=1,count do
  add_particle(
   x+rnd(spread)-spread/2,y+rnd(spread)-spread/2,
   rnd(2)-1,rnd(2)-1.5,10+rnd(12),
   rnd{PARTICLE.SMOKE,PARTICLE.DEBRIS,PARTICLE.DEBRIS})
 end
end

local function end_game(new_state)
 state,end_frame=new_state,frame
 if score>high_score then
  high_score=score
  dset(0,high_score)
 end
end

---------------------------------------------------------------
-- fire
---------------------------------------------------------------

local function ignite(tx,ty)
 if not in_map(tx,ty) then return end
 local index=tile_index(tx,ty)
 local building=occupied[index]
 if building then
  building.burn=max(building.burn,150)
  return
 end
 local fuel=flammable[mget(tx,ty)]
 if fuel and not burning[index] and #fires<MAX_FIRES then
  local fire={tx=tx,ty=ty,time=fuel.time,index=index}
  burning[index]=fire
  add(fires,fire)
 end
end

local function update_fires()
 for fire in all(fires) do
  fire.time-=1
  if fire.time%8==0 then
   local tx,ty=fire.tx+rnd{-1,0,1},fire.ty+rnd{-1,0,1}
   local fuel=flammable[mget(tx,ty)]
   local catches=fuel and rnd()<fuel.spread
   if catches or occupied[tile_index(tx,ty)] and rnd()<.1 then
    ignite(tx,ty)
   end
  end
  if rnd()<.04 then
   add_particle(fire.tx*TILE_SIZE+rnd(TILE_SIZE),fire.ty*TILE_SIZE+rnd(TILE_SIZE),0,-.4,16,PARTICLE.SMOKE)
  end
  if fire.time<=0 then
   local fuel=flammable[mget(fire.tx,fire.ty)]
   mset(fire.tx,fire.ty,fuel and fuel.becomes or SCORCHED)
   burning[fire.index]=nil
   del(fires,fire)
  end
 end
end

local function update_particles()
 for p in all(particles) do
  p.x+=p.vx
  p.y+=p.vy
  p.life-=1
  if p.kind==PARTICLE.FIRE then
   p.vx*=.92
   p.vy*=.92
  end
  if p.life<=0 then
   if p.ignites and rnd()<.3 then
    ignite(p.x\TILE_SIZE,p.y\TILE_SIZE)
   end
   del(particles,p)
  end
 end
end

---------------------------------------------------------------
-- units
---------------------------------------------------------------

local function spawn_unit(kind,x,y,force)
 if #units>=MAX_UNITS and not force then return end
 local unit_type=unit_types[kind]
 local unit={
  kind=kind,
  type=unit_type,
  x=mid(4,x,WORLD_MAX-4),
  y=mid(4,y,WORLD_MAX-4),
  hp=unit_type.hp,
  cooldown=30+rnd(30),
  burn=0,
  flash=0,
  dash=0,
  wander_angle=rnd(),
  -- each unit aims a little off-centre so a mob surrounds the dragon
  offset_x=rnd(16)-8,
  offset_y=rnd(16)-8,
 }
 add(units,unit)
 return unit
end

local function spawn_legend(number,x,y)
 local unit=spawn_unit("legend",x,y,true)
 local legend=legends[number]
 unit.legend=legend
 unit.hp,unit.max_hp=legend.hp,legend.hp
 boss=unit
 announce(legend.name.." rides!",120)
 sfx(SFX.FANFARE)
end

local function damage_unit(unit,amount)
 unit.hp-=amount
 unit.flash=3
 if unit.hp>0 then return end
 del(units,unit)
 burst(unit.x,unit.y,4,4)
 if unit.kind=="sheep" then return end
 kills+=1
 score+=unit.type.score
 sfx(SFX.DIE)
 if unit.legend then
  announce(unit.legend.name.." has fallen",120)
  dragon.hp=min(DRAGON_MAX_HP,dragon.hp+30)
  shake=8
  if boss==unit then boss=nil end
 end
end

local function damage_dragon(amount)
 if state!=STATE.PLAY then return end
 -- a charging dragon shrugs off half
 if dragon.charge>0 then amount/=2 end
 dragon.hp-=amount
 dragon.flash=6
 dragon.calm=150
 shake=max(shake,2)
 sfx(SFX.HURT)
 if dragon.hp<=0 then
  dragon.hp=0
  end_game(STATE.DEAD)
 end
end

local function unit_shoot(unit,dir_x,dir_y)
 local unit_type=unit.type
 if unit_type.lobs_rocks then
  -- lead the target; the landing spot is telegraphed
  add(rocks,{
   x=unit.x,y=unit.y,
   target_x=dragon.x+dragon.vx*25,
   target_y=dragon.y+dragon.vy*25,
   age=0,damage=unit_type.damage,
  })
  sfx(SFX.CATAPULT)
 else
  add(shots,{
   x=unit.x,y=unit.y,
   vx=dir_x*unit_type.shot_speed,
   vy=dir_y*unit_type.shot_speed,
   damage=unit_type.damage,
   color=unit_type.shot_color,
   big=unit_type.shot_big,
   life=60,
  })
  sfx(SFX.ARROW)
 end
end

-- returns the unit's movement for this frame
local function unit_melee(unit,dir_x,dir_y,distance)
 local unit_type,legend=unit.type,unit.legend
 local move_x,move_y=0,0
 if unit.dash>0 then
  unit.dash-=1
  move_x,move_y=unit.dash_vx,unit.dash_vy
 elseif distance>10 then
  move_x,move_y=dir_x*unit_type.speed,dir_y*unit_type.speed
 end
 if distance<=11 and unit.cooldown<=0 then
  damage_dragon(legend and legend.damage or unit_type.damage)
  unit.cooldown=unit_type.cooldown
 end
 if legend then
  if distance>20 and distance<70 and unit.dash<=0 and rnd()<.04 then
   unit.dash,unit.dash_vx,unit.dash_vy=12,dir_x*3.5,dir_y*3.5
  end
  if legend.excalibur and frame%75==0 and distance<100 then
   add(shots,{x=unit.x,y=unit.y,vx=dir_x*3,vy=dir_y*3,damage=8,color=12,big=true,life=50})
   sfx(SFX.ARROW)
  end
 end
 return move_x,move_y
end

local function unit_ranged(unit,dir_x,dir_y,distance)
 local unit_type=unit.type
 local move_x,move_y=0,0
 if distance>unit_type.range*.8 then
  move_x,move_y=dir_x*unit_type.speed,dir_y*unit_type.speed
 elseif distance<unit_type.range*.4 and not unit_type.siege then
  move_x,move_y=-dir_x*unit_type.speed,-dir_y*unit_type.speed
 end
 if distance<unit_type.range and unit.cooldown<=0 then
  unit.cooldown=unit_type.cooldown+rnd(20)
  unit_shoot(unit,dir_x,dir_y)
 end
 return move_x,move_y
end

local function update_units()
 for unit in all(units) do
  local unit_type=unit.type
  local dx=dragon.x+unit.offset_x-unit.x
  local dy=dragon.y+unit.offset_y-unit.y
  local distance=max(length(dx,dy),1)
  local dir_x,dir_y=dx/distance,dy/distance
  local move_x,move_y=0,0
  unit.cooldown-=1
  unit.flash=max(0,unit.flash-1)

  if unit.burn>0 then
   -- on fire: run about, spreading it
   unit.burn-=1
   if frame%6==0 then unit.wander_angle=rnd() end
   move_x,move_y=cos(unit.wander_angle)*1.2,sin(unit.wander_angle)*1.2
   if rnd()<.05 then ignite(unit.x\TILE_SIZE,unit.y\TILE_SIZE) end
   if rnd()<.4 then add_particle(unit.x,unit.y-3,0,-.5,8,PARTICLE.FIRE) end
   damage_unit(unit,.05)
  elseif unit.kind=="sheep" then
   if distance<40 then
    move_x,move_y=-dir_x*.7,-dir_y*.7
   else
    if rnd()<.02 then unit.wander_angle=rnd() end
    move_x,move_y=cos(unit.wander_angle)*.15,sin(unit.wander_angle)*.15
   end
  elseif unit_type.range==0 then
   move_x,move_y=unit_melee(unit,dir_x,dir_y,distance)
  else
   move_x,move_y=unit_ranged(unit,dir_x,dir_y,distance)
  end

  unit.x=mid(4,unit.x+move_x,WORLD_MAX-4)
  unit.y=mid(4,unit.y+move_y,WORLD_MAX-4)
  if move_x!=0 then unit.facing_left=move_x<0 end

  local standing_in_fire=burning[tile_index(unit.x\TILE_SIZE,unit.y\TILE_SIZE)]
  if standing_in_fire and unit.burn<=0 and unit_type.fire_taken>FIREPROOF then
   unit.burn=40
  end
 end
end

local function update_projectiles()
 for shot in all(shots) do
  shot.x+=shot.vx
  shot.y+=shot.vy
  shot.life-=1
  if length(shot.x-dragon.x,shot.y-dragon.y)<9 then
   damage_dragon(shot.damage)
   del(shots,shot)
  elseif shot.life<0 then
   del(shots,shot)
  end
 end
 for rock in all(rocks) do
  rock.age+=1
  if rock.age>=ROCK_FLIGHT_FRAMES then
   if length(rock.target_x-dragon.x,rock.target_y-dragon.y)<14 then
    damage_dragon(rock.damage)
   end
   burst(rock.target_x,rock.target_y,8,6)
   shake=max(shake,2)
   del(rocks,rock)
  end
 end
end

---------------------------------------------------------------
-- buildings
---------------------------------------------------------------

-- places a building with its top-left corner on a tile; returns nil
-- if the footprint is blocked
local function place_building(kind,tx,ty)
 local building_type=building_types[kind]
 local size=building_type.size
 for y=ty,ty+size-1 do
  for x=tx,tx+size-1 do
   local tile=mget(x,y)
   if not in_map(x,y) or occupied[tile_index(x,y)]
    or tile==WATER or tile==BRIDGE then
    return
   end
  end
 end
 local building={
  kind=kind,
  type=building_type,
  x=tx*TILE_SIZE,
  y=ty*TILE_SIZE,
  size=size*TILE_SIZE,
  hp=building_type.hp,
  burn=0,
  spawn_timer=rnd(building_type.spawn_rate),
 }
 building.center_x=building.x+building.size/2
 building.center_y=building.y+building.size/2
 for y=ty,ty+size-1 do
  for x=tx,tx+size-1 do
   occupied[tile_index(x,y)]=building
  end
 end
 add(buildings,building)
 return building
end

local function destroy_building(building)
 del(buildings,building)
 local tx,ty,size=building.x\TILE_SIZE,building.y\TILE_SIZE,building.type.size
 for y=ty,ty+size-1 do
  for x=tx,tx+size-1 do
   mset(x,y,RUBBLE)
   occupied[tile_index(x,y)]=nil
  end
 end
 score+=building.type.score
 burst(building.center_x,building.center_y,building.size*1.5,building.size)
 shake=max(shake,building.size/2)
 sfx(SFX.CRASH)
 if building.kind=="hut" or building.kind=="house" then
  -- someone was home
  local survivor=spawn_unit("serf",building.center_x,building.center_y)
  if survivor then survivor.burn=60 end
 end
 if building==camelot then end_game(STATE.WON) end
end

local function update_buildings()
 for building in all(buildings) do
  local building_type=building.type
  local size=building.size
  if building.burn>0 then
   building.burn-=1
   building.hp-=.07
   if rnd()<.3 then
    add_particle(
     building.x+rnd(size),building.y+rnd(size),
     rnd(.4)-.2,-.4-rnd(.4),14+rnd(10),
     rnd{PARTICLE.FIRE,PARTICLE.SMOKE})
   end
   if rnd()<.02 then
    -- embers land on a neighbouring tile
    local reach=building_type.size+2
    ignite(building.x\TILE_SIZE+flr(rnd(reach))-1,building.y\TILE_SIZE+flr(rnd(reach))-1)
   end
  end
  if building.hp<=0 then
   destroy_building(building)
  else
   building.spawn_timer-=1
   local alarmed=length(building.center_x-dragon.x,building.center_y-dragon.y)<ALARM_RANGE
   if building.spawn_timer<=0 and alarmed then
    building.spawn_timer=building_type.spawn_rate
    spawn_unit(rnd(building_type.spawns),building.center_x,building.center_y+size/2+3)
   end
  end
 end
end

---------------------------------------------------------------
-- world generation
---------------------------------------------------------------

local function lay_road(tx,ty)
 local tile=mget(tx,ty)
 mset(tx,ty,(tile==WATER or tile==BRIDGE) and BRIDGE or ROAD)
end

-- an l-shaped road: along x first, then along y
local function connect(from,to)
 for x=min(from.tx,to.tx),max(from.tx,to.tx) do
  lay_road(x,from.ty)
 end
 for y=min(from.ty,to.ty),max(from.ty,to.ty) do
  lay_road(to.tx,y)
 end
end

local function build_settlement(settlement)
 local kind,cx,cy=settlement.kind,settlement.tx,settlement.ty
 local radius=settlement_radius[kind]
 -- clear the woods; the dragon's lair is already scorched
 for y=-radius,radius do
  for x=-radius,radius do
   if length(x,y)<=radius and mget(cx+x,cy+y)==TREE then
    mset(cx+x,cy+y,kind=="lair" and SCORCHED or GRASS)
   end
  end
 end
 if kind=="camelot" then
  camelot=place_building("keep",cx-1,cy-1)
  for corner in all{{-4,-4},{3,-4},{-4,3},{3,3}} do
   place_building("tower",cx+corner[1],cy+corner[2])
  end
 end
 for building_kind in all(settlement_buildings[kind]) do
  for attempt=1,30 do
   local tx=cx+flr(rnd(radius*2+1))-radius
   local ty=cy+flr(rnd(radius*2+1))-radius
   if place_building(building_kind,tx,ty) then break end
  end
 end
 -- wheat fields and sheep around the farming settlements
 if kind=="village" or kind=="town" then
  for field=1,3 do
   local angle=rnd()
   local fx=flr(cx+cos(angle)*(radius+2))
   local fy=flr(cy+sin(angle)*(radius+2))
   for y=fy,fy+1+rnd(2) do
    for x=fx,fx+2+rnd(2) do
     local tile=mget(x,y)
     local open=tile==GRASS or tile==FLOWERS or tile==TREE
     if open and not occupied[tile_index(x,y)] then
      mset(x,y,WHEAT)
     end
    end
   end
   spawn_unit("sheep",fx*TILE_SIZE+4,fy*TILE_SIZE-6)
  end
 end
end

local function generate_world()
 buildings,units,particles,shots,rocks,fires={},{},{},{},{},{}
 occupied,burning={},{}

 for y=0,MAP_SIZE-1 do
  for x=0,MAP_SIZE-1 do
   mset(x,y,rnd()<.1 and FLOWERS or GRASS)
  end
 end

 -- forests: ragged blobs of trees
 for forest=1,18 do
  local cx,cy=flr(rnd(MAP_SIZE)),flr(rnd(MAP_SIZE))
  local radius=2+flr(rnd(5))
  for y=cy-radius,cy+radius do
   for x=cx-radius,cx+radius do
    if length(x-cx,y-cy)<radius*(.5+rnd(.6)) then
     mset(x,y,TREE)
    end
   end
  end
 end

 -- the river meanders down one of the gaps between settlement columns
 local river_base=rnd{19,40}
 local river_x=river_base
 for y=0,MAP_SIZE-1 do
  river_x=mid(river_base-1,river_x+flr(rnd(3))-1,river_base+1)
  mset(river_x,y,WATER)
  mset(river_x+1,y,WATER)
 end

 local settlements={}
 for row=0,2 do
  for col=0,2 do
   add(settlements,{
    kind=settlement_grid[row*3+col+1],
    tx=col*21+9+flr(rnd(4)),
    ty=row*21+9+flr(rnd(4)),
   })
  end
 end
 -- roads to the east and south neighbours, before anything is built
 for i,settlement in ipairs(settlements) do
  if i%3!=0 then connect(settlement,settlements[i+1]) end
  if settlements[i+3] then connect(settlement,settlements[i+3]) end
 end
 foreach(settlements,build_settlement)
 building_total=#buildings
end

---------------------------------------------------------------
-- dragon
---------------------------------------------------------------

local function new_dragon(x,y)
 dragon={
  x=x,y=y,vx=0,vy=0,
  angle=0,
  hp=DRAGON_MAX_HP,
  fire=DRAGON_MAX_FIRE,
  fire_delay=0,    -- frames until the fire gauge refills
  charge=0,        -- frames of charge left
  charge_cooldown=0,
  charge_id=0,     -- so each charge hits a target only once
  flash=0,
  calm=0,          -- frames since last hurt before healing resumes
 }
 tail={}
 for i=1,6 do
  add(tail,{x=x-i*4,y=y})
 end
end

local function heal_dragon(amount)
 dragon.hp=min(DRAGON_MAX_HP,dragon.hp+amount)
end

-- each tail segment is dragged along a fixed distance behind the last
local function update_tail()
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

local function in_breath(x,y,mouth_x,mouth_y,radius)
 local dx,dy=x-mouth_x,y-mouth_y
 local distance=length(dx,dy)
 if distance>BREATH_RANGE+radius then return false end
 if distance<6+radius then return true end
 return abs(angle_diff(atan2(dx,dy),dragon.angle))<BREATH_HALF_ANGLE
end

local function breathe_fire(mouth_x,mouth_y)
 dragon.fire-=BREATH_COST
 dragon.fire_delay=30
 for i=1,3 do
  local angle=dragon.angle+rnd(.1)-.05
  local speed=2.5+rnd(1.5)
  add_particle(
   mouth_x,mouth_y,
   cos(angle)*speed+dragon.vx,sin(angle)*speed+dragon.vy,
   16+rnd(8),PARTICLE.FIRE,true)
 end
 -- the flames are for show; damage is a cone test every few frames
 if frame%4!=0 then return end
 sfx(SFX.BREATH,3)
 for unit in all(units) do
  if in_breath(unit.x,unit.y,mouth_x,mouth_y,0) then
   local fire_taken=unit.type.fire_taken
   if fire_taken>FIREPROOF then unit.burn=60 end
   damage_unit(unit,BREATH_DAMAGE*fire_taken)
  end
 end
 for building in all(buildings) do
  if in_breath(building.center_x,building.center_y,mouth_x,mouth_y,building.size/2) then
   building.hp-=BREATH_DAMAGE
   building.burn=max(building.burn,200)
  end
 end
end

-- while charging the head is a battering ram
local function charge_impacts(head_x,head_y)
 local id=dragon.charge_id
 for unit in all(units) do
  if unit.charge_id!=id and length(unit.x-head_x,unit.y-head_y)<12 then
   unit.charge_id=id
   damage_unit(unit,unit.legend and 15 or 40)
   if unit.hp<=0 and not unit.legend then
    heal_dragon(2)
    sfx(SFX.EAT)
   end
  end
 end
 for building in all(buildings) do
  local reach=8+building.size/2
  if building.charge_id!=id
   and length(building.center_x-head_x,building.center_y-head_y)<reach then
   building.charge_id=id
   building.hp-=CHARGE_DAMAGE
   -- hitting a wall ends the charge
   dragon.charge=min(dragon.charge,3)
   shake=6
   burst(building.center_x,building.center_y,8,building.size)
   sfx(SFX.CRASH)
  end
 end
end

local function update_dragon()
 local d=dragon
 local input_x,input_y=0,0
 if btn(BTN.LEFT) then input_x-=1 end
 if btn(BTN.RIGHT) then input_x+=1 end
 if btn(BTN.UP) then input_y-=1 end
 if btn(BTN.DOWN) then input_y+=1 end

 local forward_x,forward_y=cos(d.angle),sin(d.angle)
 local head_x,head_y=d.x+forward_x*11,d.y+forward_y*11
 local breathing=btn(BTN.FIRE) and d.fire>1 and d.charge<=0

 if d.charge>0 then
  d.charge-=1
  charge_impacts(head_x,head_y)
 else
  if input_x!=0 or input_y!=0 then
   local target_angle=atan2(input_x,input_y)
   local turn=mid(-DRAGON_TURN_RATE,angle_diff(target_angle,d.angle),DRAGON_TURN_RATE)
   d.angle=(d.angle+turn)%1
   local accel=breathing and DRAGON_BREATH_ACCEL or DRAGON_ACCEL
   d.vx+=cos(target_angle)*accel
   d.vy+=sin(target_angle)*accel
  end
  d.vx*=DRAGON_FRICTION
  d.vy*=DRAGON_FRICTION
  if btnp(BTN.CHARGE) and d.charge_cooldown<=0 then
   d.charge=CHARGE_FRAMES
   d.charge_cooldown=CHARGE_COOLDOWN
   d.charge_id+=1
   d.vx,d.vy=forward_x*CHARGE_SPEED,forward_y*CHARGE_SPEED
   shake=3
   sfx(SFX.ROAR)
  end
 end

 d.charge_cooldown-=1
 d.flash=max(0,d.flash-1)
 d.x=mid(8,d.x+d.vx,WORLD_MAX-8)
 d.y=mid(8,d.y+d.vy,WORLD_MAX-8)

 -- a sheep under the jaws is a snack
 for unit in all(units) do
  if unit.kind=="sheep" and length(unit.x-head_x,unit.y-head_y)<9 then
   del(units,unit)
   heal_dragon(8)
   sfx(SFX.EAT)
  end
 end

 if breathing then
  breathe_fire(head_x,head_y)
 else
  d.fire_delay-=1
  if d.fire_delay<=0 then
   d.fire=min(DRAGON_MAX_FIRE,d.fire+.5)
  end
 end

 d.calm-=1
 if d.calm<=0 then heal_dragon(.04) end
 update_tail()
end

---------------------------------------------------------------
-- wrath: the more you burn, the harder the realm pushes back
---------------------------------------------------------------

local function update_wrath()
 local level=1
 for i,threshold in ipairs(wrath_thresholds) do
  if score>=threshold then level=i end
 end
 if level>wrath then
  wrath=level
  announce("wrath "..level.." - the realm rallies")
  sfx(SFX.FANFARE)
 end

 -- newcomers arrive from just off screen
 local angle=rnd()
 local x,y=dragon.x+cos(angle)*95,dragon.y+sin(angle)*95

 -- one knight of the round table per wrath level, one at a time
 if not boss and legends_sent<min(wrath-1,ARTHUR-1) then
  legends_sent+=1
  spawn_legend(legends_sent,x,y)
 end
 -- the king himself rides out to defend his keep
 if not arthur_sent and camelot.hp<camelot.type.hp*.6 then
  arthur_sent=true
  spawn_legend(ARTHUR,camelot.center_x,camelot.center_y+12)
 end

 reinforce_timer-=1
 if reinforce_timer<=0 then
  reinforce_timer=max(90,330-wrath*50)
  for i=1,1+wrath\2 do
   spawn_unit(rnd(reinforcements[wrath]),x+rnd(16)-8,y+rnd(16)-8)
  end
 end
end

---------------------------------------------------------------
-- drawing
---------------------------------------------------------------

local function print_centered(text,y,color)
 local x=64-#text*2
 print(text,x+1,y+1,0)
 print(text,x,y,color)
end

local function draw_flames(x,y,size,count)
 for i=1,count do
  circfill(x+rnd(size),y+rnd(size),rnd(2),rnd{8,9,10})
 end
end

local function draw_dragon()
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
  local segment=tail[i]
  circfill(segment.x,segment.y,4-i*.5,i%2==0 and 2 or 8)
 end

 -- wings: a fan of lines from the shoulder makes the membrane
 for side=-1,1,2 do
  local span=13+flap*3
  local sweep=3-flap*2
  local shoulder_x,shoulder_y=x+fx*2+sx*side*3,y+fy*2+sy*side*3
  local tip_x,tip_y=x+sx*side*span-fx*sweep,y+sy*side*span-fy*sweep
  local root_x,root_y=x-fx*7+sx*side*3,y-fy*7+sy*side*3
  for i=0,1,.07 do
   line(shoulder_x,shoulder_y,tip_x+(root_x-tip_x)*i,tip_y+(root_y-tip_y)*i,2)
  end
  for bone in all{0,.4,.75} do
   line(shoulder_x,shoulder_y,tip_x+(root_x-tip_x)*bone,tip_y+(root_y-tip_y)*bone,8)
  end
 end

 -- haunches, chest, neck, spine
 circfill(x-fx*4,y-fy*4,4,8)
 circfill(x,y,5,8)
 circfill(x+fx*6,y+fy*6,3,8)
 for i=-7,5,3 do
  pset(x+fx*i,y+fy*i,2)
 end

 -- horns, head, snout, eyes
 for side=-1,1,2 do
  line(
   x+fx*9+sx*side*2,y+fy*9+sy*side*2,
   x+fx*5+sx*side*5,y+fy*5+sy*side*5,6)
 end
 circfill(x+fx*10,y+fy*10,3,8)
 circfill(x+fx*13,y+fy*13,2,8)
 for side=-1,1,2 do
  pset(x+fx*11+sx*side*2,y+fy*11+sy*side*2,10)
 end
 pal()
end

local function draw_buildings(cam_x,cam_y)
 for building in all(buildings) do
  local x,y,size=building.x,building.y,building.size
  if on_screen(x,y,cam_x,cam_y,16) then
   local tiles=building.type.size
   spr(building.type.sprite,x,y,tiles,tiles)
   if building.burn>0 then
    draw_flames(x,y,size,size/4)
   end
   local max_hp=building.type.hp
   if building.hp<max_hp then
    line(x,y-2,x+size-1,y-2,0)
    line(x,y-2,x+(size-1)*max(building.hp,0)/max_hp,y-2,8)
   end
  end
 end
end

local function draw_units(cam_x,cam_y)
 for unit in all(units) do
  if on_screen(unit.x,unit.y,cam_x,cam_y,8) then
   if unit.flash>0 then
    for color=1,15 do pal(color,7) end
   elseif unit.legend then
    pal(10,unit.legend.color)
   end
   spr(unit.type.sprite,unit.x-4,unit.y-4,1,1,unit.facing_left)
   pal()
   if unit.burn>0 then
    pset(unit.x-2+rnd(4),unit.y-5+rnd(3),rnd{9,10})
   end
  end
 end
end

local function draw_particles()
 for p in all(particles) do
  local life=p.life
  if p.kind==PARTICLE.FIRE then
   -- white hot, cooling through yellow and red to smoke
   local color=life>18 and 7 or life>12 and 10 or life>7 and 9 or life>3 and 8 or 5
   circfill(p.x,p.y,life\6,color)
  elseif p.kind==PARTICLE.SMOKE then
   circfill(p.x,p.y,1,life>10 and 5 or 6)
  else
   pset(p.x,p.y,life>8 and 6 or 4)
  end
 end
end

local function draw_hud(cam_x,cam_y)
 -- compass to camelot when it is off screen
 local dx=camelot.center_x-cam_x-64
 local dy=camelot.center_y-cam_y-64
 if state==STATE.PLAY and (abs(dx)>64 or abs(dy)>56) then
  local angle=atan2(dx,dy)
  local x,y=64+cos(angle)*56,68+sin(angle)*52
  circfill(x,y,2,8)
  line(x,y,x+cos(angle)*4,y+sin(angle)*4,10)
 end

 rectfill(0,0,127,8,0)
 rectfill(2,1,42,3,2)
 rectfill(2,1,2+dragon.hp/DRAGON_MAX_HP*40,3,8)
 rectfill(2,5,42,7,4)
 rectfill(2,5,2+dragon.fire/DRAGON_MAX_FIRE*40,7,dragon.fire>20 and 9 or 5)
 print(score,47,2,7)
 print("ko "..kills,72,2,6)
 for level=1,#wrath_thresholds do
  circfill(100+level*5,4,1,level<=wrath and 8 or 5)
 end

 if boss then
  rectfill(0,119,127,127,0)
  print(boss.legend.name,2,121,boss.legend.color)
  rectfill(60,121,125,125,2)
  rectfill(60,121,60+65*max(boss.hp,0)/boss.max_hp,125,8)
 end
 if message_timer>0 then
  print_centered(message,14,10)
 end
end

local function draw_title()
 rectfill(0,24,127,100,0)
 print("\^w\^twyrmfire",33,31,8)
 print_centered("burn the realm. raze camelot.",48,9)
 print_centered("arrows  fly",62,6)
 print_centered("z  breathe fire",70,6)
 print_centered("x  charge & devour",78,6)
 print_centered("press x",90,7)
 if high_score>0 then
  print_centered("best "..high_score,106,10)
 end
end

local function draw_game_over()
 local won=state==STATE.WON
 local razed=flr((building_total-#buildings)/building_total*100)
 rectfill(0,44,127,86,0)
 print_centered(won and "camelot is ash" or "the dragon is slain",50,won and 10 or 8)
 print_centered("score "..score.."  best "..high_score,60,7)
 print_centered(kills.." slain  "..razed.."% razed",68,6)
 if frame-end_frame>45 then
  print_centered("press x",78,5)
 end
end

---------------------------------------------------------------
-- main loop
---------------------------------------------------------------

local function new_game()
 generate_world()
 new_dragon(84,84)
 score,kills,wrath,legends_sent,arthur_sent=0,0,1,0,false
 shake,message,message_timer,reinforce_timer=0,"",0,300
 boss=nil
 state=STATE.TITLE
end

function _init()
 cartdata("drachis_wyrmfire")
 high_score=dget(0)
 frame=0
 new_game()
end

function _update()
 frame+=1
 local pressed=btnp(BTN.FIRE) or btnp(BTN.CHARGE)
 if state==STATE.PLAY then
  update_dragon()
  update_units()
  update_projectiles()
  update_buildings()
  update_wrath()
 elseif state==STATE.TITLE then
  if pressed then state=STATE.PLAY end
 elseif pressed and frame-end_frame>45 then
  new_game()
 end
 update_fires()
 update_particles()
 shake*=.8
 message_timer-=1
end

function _draw()
 cls(0)
 local cam_max=MAP_SIZE*TILE_SIZE-SCREEN
 local cam_x=mid(0,dragon.x-64,cam_max)
 local cam_y=mid(0,dragon.y-64,cam_max)
 camera(cam_x+rnd(shake)-shake/2,cam_y+rnd(shake)-shake/2)

 local tx,ty=cam_x\TILE_SIZE,cam_y\TILE_SIZE
 map(tx,ty,tx*TILE_SIZE,ty*TILE_SIZE,17,17)
 for fire in all(fires) do
  local x,y=fire.tx*TILE_SIZE,fire.ty*TILE_SIZE
  if on_screen(x,y,cam_x,cam_y,8) then
   draw_flames(x,y,TILE_SIZE,2)
  end
 end
 draw_buildings(cam_x,cam_y)
 draw_units(cam_x,cam_y)

 for shot in all(shots) do
  if shot.big then
   circfill(shot.x,shot.y,2,shot.color)
   pset(shot.x,shot.y,7)
  else
   line(shot.x,shot.y,shot.x-shot.vx*1.5,shot.y-shot.vy*1.5,shot.color)
  end
 end
 -- a closing ring marks where each rock will land
 for rock in all(rocks) do
  circ(rock.target_x,rock.target_y,2+(ROCK_FLIGHT_FRAMES-rock.age)/5,8)
 end

 draw_dragon()
 draw_particles()
 for rock in all(rocks) do
  local progress=rock.age/ROCK_FLIGHT_FRAMES
  local arc=sin(progress/2)*30
  circfill(
   rock.x+(rock.target_x-rock.x)*progress,
   rock.y+(rock.target_y-rock.y)*progress+arc,2,5)
 end

 camera()
 if state==STATE.TITLE then
  draw_title()
 else
  draw_hud(cam_x,cam_y)
  if state!=STATE.PLAY then draw_game_over() end
 end
end
