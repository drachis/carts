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

function ignite(tx,ty,by_chance)
 if tx<0 or ty<0 or tx>63 or ty>63 or dome_over(tx*8,ty*8) then return end
 local fuel=fget(mget(tx,ty))
 if by_chance and rnd(16)>=fuel%16 then return end
 local building=building_at(tx,ty)
 if building then
  building.burn=max(building.burn,150)
 elseif fuel>0 and tile_state(tx,ty)==0 then
  set_tile_state(tx,ty,fuel\16)
 end
end

function update_fire()
 for i=0,255 do
  local tx,ty=i%64,fire_row+i\64
  local heat=tile_state(tx,ty)
  if heat>0 and heat<128 then
   ignite(tx+flr(rnd(3))-1,ty+flr(rnd(3))-1,true)
   set_tile_state(tx,ty,heat-1)
   if heat==1 then
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

function place_building(kind,tx,ty,home)
 local spec=building_specs[kind]
 local last=spec.tiles-1
 for y=ty,ty+last do
  for x=tx,tx+last do
   local ground=mget(x,y)
   if x<0 or y<0 or x>63 or y>63 or tile_state(x,y)>0
    or ground==tile_water or ground==tile_bridge then
    return
   end
  end
 end
 local size=spec.tiles*8
 local building=setmetatable({
  x=tx*8,
  y=ty*8,
  size=size,
  center_x=tx*8+size/2,
  center_y=ty*8+size/2,
  hp=spec.max_hp,
  burn=0,
  spawn_timer=rnd(spec.spawn_rate),
  home=home,
 },spec)
 home.standing+=1
 if spec.ward and home.warded==0 then
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

function shielded(home)
 return home.hero or home.warded==1 and wards>0
end

function dome_radius(home)
 return home.radius*8+10
end

function dome_over(x,y)
 for home in all(settlements) do
  if shielded(home) and length(x-home.tx*8,y-home.ty*8)<dome_radius(home) then
   return home
  end
 end
end

function damage_building(building,amount)
 if shielded(building.home) then
  building.burn=0
  return
 end
 building.hp-=amount
 if building.hp>0 then return end
 local tx,ty,last=building.x\8,building.y\8,building.tiles-1
 del(buildings,building)
 for y=ty,ty+last do
  for x=tx,tx+last do
   mset(x,y,tile_rubble)
   set_tile_state(x,y,0)
  end
 end
 local x,y,size,home=building.center_x,building.center_y,building.size,building.home
 add_score(building.score,x,y)
 burst(x,y,size*1.5,size)
 ring(x,y,size*2)
 coins(x,y,building.score\10+2)
 embers(x,y,8,2.5)
 jolt(size/2,size/4)
 sfx(snd_crash)
 if building.survivor then
  local survivor=spawn_unit(building.survivor,x,y)
  if survivor then survivor.burn=60 end
 end
 home.standing-=1
 if home.standing==0 then
  announce(home.name.." is ash!",120)
  add_score(home.bounty,x,y-8)
  heal_dragon(25)
  flash=2
  coins(x,y,30)
  reel_time=reel_frames
  reinforce_timer=lull_frames
 end
 if home.wards>0 and building.ward then
  wards-=1
  home.wards-=1
  flash=2
  if wards>0 then
   announce(wards.." wards still guard camelot",120)
  else
   announce("camelot's ward is broken!",150)
   wrath=#wrath_levels
   roar(120,60)
  end
 end
 if building.goal then end_game("won") end
end

function update_settlements()
 battle=false
 for home in all(settlements) do
  local x,y=home.tx*8,home.ty*8
  local distance,dome=dragon_distance(x,y),dome_radius(home)+dragon.size*11
  if shielded(home) and distance<dome then
   dragon.x=x+(dragon.x-x)*dome/distance
   dragon.y=y+(dragon.y-y)*dome/distance
   if frame%4==0 then
    ring(dragon.x,dragon.y,14)
    jolt(2)
    sfx(snd_coin)
   end
  end
  if home.standing>0 and distance<dome+30 then
   battle=true
   if not home.alarmed then
    home.alarmed=true
    announce(home.name.." sounds the alarm!")
    sfx(snd_alarm)
    for i=1,home.militia do
     spawn_unit(rnd(list(home.muster)),x+rnd(48)-24,y+rnd(48)-24)
    end
    if home.hero then
     spawn_boss(home.hero,x,y)
     boss.guards=home
    end
   end
  end
 end
 if frame%150==0 then
  local livestock,home=0,rnd(settlements)
  for unit in all(units) do
   if unit.ai=="sheep" then livestock+=1 end
  end
  if livestock<min_livestock and home.flock>0 then
   local angle,reach=rnd(),dome_radius(home)
   spawn_unit("sheep",home.tx*8+cos(angle)*reach,home.ty*8+sin(angle)*reach)
  end
 end
end

function update_buildings()
 for building in all(buildings) do
  local size=building.size
  local x,y=building.center_x,building.center_y
  local distance=dragon_distance(x,y)
  local harm=distance<dragon.size*6+size/2 and dragon.weight*.15 or 0
  building.spawn_timer-=1
  if building.spawn_timer<=0 and distance<alarm_range then
   building.spawn_timer=building.spawn_rate
   spawn_unit(rnd(list(building.spawns)),x,y+size/2+3)
  end
  if building.guardian and not building.guarded
   and building.hp<building.max_hp*guardian_at then
   building.guarded=true
   spawn_boss(building.guardian,x,y+size/2+4)
  end
  if building.burn>0 then
   building.burn-=1
   if frame%30==0 then coins(x,y,1) end
   if rnd()<.3 then
    add_particle(
     building.x+rnd(size),building.y+rnd(size),
     rnd(.4)-.2,-.4-rnd(.4),14+rnd(10),rnd{"fire","smoke"})
   end
   if rnd()<.02 then
    local reach=building.tiles+2
    ignite(building.x\8+flr(rnd(reach))-1,building.y\8+flr(rnd(reach))-1)
   end
   harm+=.07
  end
  if harm>0 then damage_building(building,harm) end
 end
end

function draw_buildings()
 for building in all(buildings) do
  local x,y,size=building.x,building.y,building.size
  if on_screen(x,y,16) then
   spr(building.sprite,x,y,building.tiles,building.tiles)
   if building.burn>0 then
    draw_flames(x,y,size,size/4)
   end
   if building.hp<building.max_hp then
    line(x,y-2,x+size-1,y-2,0)
    line(x,y-2,x+(size-1)*building.hp/building.max_hp,y-2,8)
   end
  end
 end
 for home in all(settlements) do
  if shielded(home) then
   circ(home.tx*8,home.ty*8,dome_radius(home)+frame\4%2,frame%4<2 and 12 or 7)
  end
 end
end

function lay_road(tx,ty)
 local ground=mget(tx,ty)
 local wet=ground==tile_water or ground==tile_bridge
 mset(tx,ty,wet and tile_bridge or tile_road)
end

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
 local cx,cy,radius=settlement.tx,settlement.ty,settlement.radius
 for y=-radius,radius do
  for x=-radius,radius do
   if length(x,y)<=radius and mget(cx+x,cy+y)==tile_tree then
    mset(cx+x,cy+y,settlement.ground)
   end
  end
 end
 for entry in all(list(settlement.fixed)) do
  local kind,x,y=unpack(split(entry,":"))
  local building=place_building(kind,cx+x,cy+y,settlement)
  if building.goal then goal=building end
 end
 for kind in all(list(settlement.buildings)) do
  for attempt=1,30 do
   local tx=cx+flr(rnd(radius*2+1))-radius
   local ty=cy+flr(rnd(radius*2+1))-radius
   if place_building(kind,tx,ty,settlement) then break end
  end
 end
 for field=1,settlement.fields do
  local angle=rnd()
  local fx=flr(cx+cos(angle)*(radius+2))
  local fy=flr(cy+sin(angle)*(radius+2))
  for y=fy,fy+1+rnd(2) do
   for x=fx,fx+2+rnd(2) do
    if fget(mget(x,y))>0 and tile_state(x,y)==0 then
     mset(x,y,tile_wheat)
    end
   end
  end
  for sheep=1,settlement.flock do
   spawn_unit("sheep",fx*8+rnd(24),fy*8+rnd(16))
  end
 end
end

function generate_world()
 buildings,all_buildings,units,particles,shots={},{},{},{},{}
 fire_row,wards=0,0
 memset(0x1000,0,0x2000)
 for y=0,63 do
  for x=0,63 do
   mset(x,y,rnd()<.1 and tile_flowers or tile_grass)
  end
 end

 for forest=1,18 do
  local cx,cy=7+flr(rnd(50)),flr(rnd(64))
  local radius=2+flr(rnd(5))
  for y=cy-radius,cy+radius do
   for x=cx-radius,cx+radius do
    if length(x-cx,y-cy)<radius*(.5+rnd(.6)) then
     mset(x,y,tile_tree)
    end
   end
  end
 end

 local river_base=rnd{19,40}
 local river_x=river_base
 for y=0,63 do
  river_x=mid(river_base-1,river_x+flr(rnd(3))-1,river_base+1)
  mset(river_x,y,tile_water)
  mset(river_x+1,y,tile_water)
 end

 settlements={}
 for i,entry in ipairs(realm) do
  local kind,name,hero=unpack(split(entry,":"))
  add(settlements,setmetatable({
   name=name,
   hero=hero,
   standing=0,
   wards=0,
   tx=(i-1)%3*21+9+flr(rnd(4)),
   ty=(i-1)\3*21+9+flr(rnd(4)),
  },settlement_specs[kind]))
 end
 for i,settlement in ipairs(settlements) do
  if i%3!=0 then connect(settlement,settlements[i+1]) end
  connect(settlement,settlements[i+3])
 end
 foreach(settlements,build_settlement)
end
