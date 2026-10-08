-- world.lua : the map, fire, buildings and world generation.
--
-- memory layout. the world is 64x64 tiles but the map is 128 wide,
-- so the left half (x 0..63) holds ground sprites and the right
-- half (x 64..127) holds one byte of state for the same tile:
--   0        nothing
--   1..127   burning, with this many fire visits left
--   128+id   a building stands here (index into all_buildings)
-- no lua tables are needed for fires or occupancy, and neither has
-- a cap. map rows 32..63 share memory with sprites 128..255, so
-- only sprites 0..127 can be used for art.

function tile_state(tx,ty)
 return mget(tx+64,ty)
end

function set_tile_state(tx,ty,value)
 mset(tx+64,ty,value)
end

function burning_at(tx,ty)
 local heat=tile_state(tx,ty)
 return heat>0 and heat<128
end

function building_at(tx,ty)
 return all_buildings[tile_state(tx,ty)-128]
end

---------------------------------------------------------------
-- fire
---------------------------------------------------------------

-- a tile's fuel is its sprite flags: high nibble is how many fire
-- visits it burns for, low nibble its chance in 16 of catching
-- from a neighbour. with `by_chance` the tile has to roll for it.
function ignite(tx,ty,by_chance)
 if tx<0 or ty<0 or tx>63 or ty>63 then return end
 local fuel=fget(mget(tx,ty))
 if by_chance and rnd(16)>=fuel%16 then return end
 local building=building_at(tx,ty)
 if building then
  building.burn=max(building.burn,150)
 elseif fuel>0 and tile_state(tx,ty)==0 then
  set_tile_state(tx,ty,fuel\16)
 end
end

-- fire is a cellular automaton over the state bytes. four rows are
-- visited per frame, so every tile gets a visit each 16 frames: a
-- burning tile tries to light a random neighbour, burns down one
-- step, and at zero becomes its burnt sprite (16 ids later).
function update_fire()
 for i=0,255 do
  local tx,ty=i%64,fire_row+i\64
  local heat=tile_state(tx,ty)
  if heat>0 and heat<128 then
   ignite(tx+flr(rnd(3))-1,ty+flr(rnd(3))-1,true)
   set_tile_state(tx,ty,heat-1)
   if heat==1 then
    -- slow-burning ground (trees, wheat) sometimes pays as it goes
    if fget(mget(tx,ty))>=64 and rnd()<.25 then
     coins(tx*8+4,ty*8+4,1)
    end
    mset(tx,ty,mget(tx,ty)+16)
   end
  end
 end
 fire_row=(fire_row+4)%64
end

function draw_fire()
 local left,top=cam_x\8,cam_y\8
 for ty=top,top+16 do
  for tx=left,min(left+16,63) do
   if burning_at(tx,ty) then
    draw_flames(tx*8,ty*8,8,2)
   end
  end
 end
end

---------------------------------------------------------------
-- buildings
---------------------------------------------------------------

-- places a building with its top-left corner on a tile. returns nil
-- if the footprint is off the map, occupied or over water.
function place_building(kind,tx,ty,home)
 local spec=building_specs[kind]
 local last=spec.size-1
 for y=ty,ty+last do
  for x=tx,tx+last do
   local ground=mget(x,y)
   if x<0 or y<0 or x>63 or y>63 or tile_state(x,y)>0
    or ground==tile.water or ground==tile.bridge then
    return
   end
  end
 end
 local size=spec.size*8
 local building={
  spec=spec,
  x=tx*8,
  y=ty*8,
  size=size,
  center_x=tx*8+size/2,
  center_y=ty*8+size/2,
  hp=spec.hp,
  burn=0,
  spawn_timer=rnd(spec.spawn_rate),
  home=home,
 }
 home.standing+=1
 -- a ward inside the warded city would guard itself forever
 if spec.ward and home.spec.warded==0 then
  wards+=1
  home.wards+=1
 end
 add(buildings,building)
 add(all_buildings,building)
 for y=ty,ty+last do
  for x=tx,tx+last do
   set_tile_state(x,y,128+#all_buildings)
  end
 end
 return building
end

function damage_building(building,amount)
 local spec=building.spec
 -- a warded settlement cannot be harmed while a ward still stands
 if building.home.spec.warded==1 and wards>0 then return end
 building.hp-=amount
 if building.hp>0 then return end
 local tx,ty,last=building.x\8,building.y\8,spec.size-1
 del(buildings,building)
 for y=ty,ty+last do
  for x=tx,tx+last do
   mset(x,y,tile.rubble)
   set_tile_state(x,y,0)
  end
 end
 local x,y,size,home=building.center_x,building.center_y,building.size,building.home
 add_score(spec.score,x,y)
 burst(x,y,size*1.5,size)
 ring(x,y,size*2)
 -- it pays out, and throws fire at its neighbours
 coins(x,y,spec.score\10+2)
 embers(x,y,8,2.5)
 -- the bigger it was, the longer the world holds its breath
 jolt(size/2,size/4)
 sfx(sound.crash)
 if spec.survivor then
  local survivor=spawn_unit(spec.survivor,x,y)
  if survivor then survivor.burn=60 end
 end
 home.standing-=1
 if home.standing==0 then
  announce(home.name.." is ash!",120)
  add_score(home.spec.bounty,x,y-8)
  heal_dragon(25)
  flash=2
  -- jackpot: a fountain of gold and a spin of the boon reel
  coins(x,y,30)
  reel_time=config.reel_frames
  -- and a rest: the realm reels before it sends anyone else
  reinforce_timer=config.lull_frames
 end
 if home.wards>0 and spec.ward then
  wards-=1
  home.wards-=1
  flash=2
  if wards>0 then
   announce(wards.." wards still guard camelot",120)
  else
   -- the finale: nothing is held back any more
   announce("camelot's ward is broken!",150)
   wrath=#wrath_levels
   roar(120,60)
  end
 end
 if spec.goal then end_game("won") end
end

-- a settlement the dragon comes near sounds the alarm, once, and
-- its militia turns out. while the dragon is at a standing
-- settlement it is in `battle`, which quickens the reinforcements
-- and the music; open country is the rest between.
function update_settlements()
 battle=false
 for home in all(settlements) do
  local spec,x,y=home.spec,home.tx*8,home.ty*8
  if home.standing>0 and dragon_distance(x,y)<spec.radius*8+40 then
   battle=true
   if not home.alarmed then
    home.alarmed=true
    announce(home.name.." sounds the alarm!")
    sfx(sound.alarm)
    for i=1,spec.militia do
     spawn_unit(rnd(list(spec.muster)),x+rnd(48)-24,y+rnd(48)-24)
    end
   end
  end
 end
end

function update_buildings()
 for building in all(buildings) do
  local spec,size=building.spec,building.size
  local x,y=building.center_x,building.center_y
  local distance=dragon_distance(x,y)
  -- what a heavy dragon flies over is crushed beneath it
  local harm=distance<dragon.size*6+size/2 and dragon.weight*.15 or 0
  building.spawn_timer-=1
  if building.spawn_timer<=0 and distance<config.alarm_range then
   building.spawn_timer=spec.spawn_rate
   spawn_unit(rnd(list(spec.spawns)),x,y+size/2+3)
  end
  if spec.guardian and not building.guarded
   and building.hp<spec.hp*config.guardian_at then
   building.guarded=true
   spawn_boss(spec.guardian,x,y+size/2+4)
  end
  if building.burn>0 then
   building.burn-=1
   -- a burning building drips gold for as long as it lasts
   if frame%30==0 then coins(x,y,1) end
   if rnd()<.3 then
    add_particle(
     building.x+rnd(size),building.y+rnd(size),
     rnd(.4)-.2,-.4-rnd(.4),14+rnd(10),rnd{"fire","smoke"})
   end
   if rnd()<.02 then
    -- embers land on a neighbouring tile
    local reach=spec.size+2
    ignite(building.x\8+flr(rnd(reach))-1,building.y\8+flr(rnd(reach))-1)
   end
   harm+=.07
  end
  if harm>0 then damage_building(building,harm) end
 end
end

function draw_buildings()
 for building in all(buildings) do
  local x,y,size,spec=building.x,building.y,building.size,building.spec
  if on_screen(x,y,16) then
   spr(spec.sprite,x,y,spec.size,spec.size)
   if building.burn>0 then
    draw_flames(x,y,size,size/4)
   end
   if building.hp<spec.hp then
    line(x,y-2,x+size-1,y-2,0)
    line(x,y-2,x+(size-1)*building.hp/spec.hp,y-2,8)
   end
  end
 end
 -- the ward is a dome over the whole of the goal's settlement
 if wards>0 then
  local home=goal.home
  circ(home.tx*8,home.ty*8,60+frame%8/4,frame%4<2 and 12 or 7)
 end
end

---------------------------------------------------------------
-- world generation
---------------------------------------------------------------

function lay_road(tx,ty)
 local ground=mget(tx,ty)
 local wet=ground==tile.water or ground==tile.bridge
 mset(tx,ty,wet and tile.bridge or tile.road)
end

-- an l-shaped road: along x first, then along y
function connect(from,to)
 if not to then return end
 for x=min(from.tx,to.tx),max(from.tx,to.tx) do
  lay_road(x,from.ty)
 end
 for y=min(from.ty,to.ty),max(from.ty,to.ty) do
  lay_road(to.tx,y)
 end
end

function build_settlement(settlement)
 local spec,cx,cy=settlement.spec,settlement.tx,settlement.ty
 local radius=spec.radius
 for y=-radius,radius do
  for x=-radius,radius do
   if length(x,y)<=radius and mget(cx+x,cy+y)==tile.tree then
    mset(cx+x,cy+y,spec.ground)
   end
  end
 end
 for entry in all(list(spec.fixed)) do
  local kind,x,y=unpack(split(entry,":"))
  local building=place_building(kind,cx+x,cy+y,settlement)
  if building.spec.goal then goal=building end
 end
 for kind in all(list(spec.buildings)) do
  for attempt=1,30 do
   local tx=cx+flr(rnd(radius*2+1))-radius
   local ty=cy+flr(rnd(radius*2+1))-radius
   if place_building(kind,tx,ty,settlement) then break end
  end
 end
 -- wheat fields, each with a sheep, just outside the settlement
 for field=1,spec.fields do
  local angle=rnd()
  local fx=flr(cx+cos(angle)*(radius+2))
  local fy=flr(cy+sin(angle)*(radius+2))
  for y=fy,fy+1+rnd(2) do
   for x=fx,fx+2+rnd(2) do
    -- anything that burns can be ploughed under
    if fget(mget(x,y))>0 and tile_state(x,y)==0 then
     mset(x,y,tile.wheat)
    end
   end
  end
  for sheep=1,spec.flock do
   spawn_unit("sheep",fx*8+rnd(24),fy*8+rnd(16))
  end
 end
end

function generate_world()
 buildings,all_buildings,units,particles,shots={},{},{},{},{}
 fire_row,wards=0,0
 -- the map is two blocks of memory: rows 32..63 at 0x1000 (shared
 -- with the sprite sheet) then rows 0..31 at 0x2000. one memset
 -- clears every tile's state.
 memset(0x1000,0,0x2000)
 for y=0,63 do
  for x=0,63 do
   mset(x,y,rnd()<.1 and tile.flowers or tile.grass)
  end
 end

 -- forests: ragged blobs of trees
 for forest=1,18 do
  local cx,cy=flr(rnd(64)),flr(rnd(64))
  local radius=2+flr(rnd(5))
  for y=cy-radius,cy+radius do
   for x=cx-radius,cx+radius do
    if x>=0 and x<64 and length(x-cx,y-cy)<radius*(.5+rnd(.6)) then
     mset(x,y,tile.tree)
    end
   end
  end
 end

 -- the river meanders down one of the gaps between settlement columns
 local river_base=rnd{19,40}
 local river_x=river_base
 for y=0,63 do
  river_x=mid(river_base-1,river_x+flr(rnd(3))-1,river_base+1)
  mset(river_x,y,tile.water)
  mset(river_x+1,y,tile.water)
 end

 settlements={}
 for i,entry in ipairs(realm) do
  local kind,name=unpack(split(entry,":"))
  add(settlements,{
   spec=settlement_specs[kind],
   name=name,
   standing=0,
   wards=0,
   tx=(i-1)%3*21+9+flr(rnd(4)),
   ty=(i-1)\3*21+9+flr(rnd(4)),
  })
 end
 -- roads to the east and south neighbours, before anything is built
 for i,settlement in ipairs(settlements) do
  if i%3!=0 then connect(settlement,settlements[i+1]) end
  connect(settlement,settlements[i+3])
 end
 foreach(settlements,build_settlement)
end
