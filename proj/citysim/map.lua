-- map.lua : grid helpers, terrain gen, camera, world draw
-- the grid lives in pico-8 map ram: sprite id = tile state (see design.md)

gridw,gridh=48,48

-- sprite id -> class id; one table feeds the census, minimap colors,
-- tile names, and upkeep instead of several if-chains.
-- 1 grass 2 trees 3 water 4 highland 5 rock 6 road 7 zone 8 crossing
-- 9 bridge 10 pylon 11 line 12 plant 13 service 14 park 15 fire 16 rubble
tcl={1,2,3,4,5,[44]=14,[48]=12,[53]=8,[54]=8,[56]=16,
 [59]=9,[60]=9,[61]=10,[62]=10,[96]=16,[97]=16,[98]=16}
for i=16,31 do tcl[i]=6 end
for i=32,43 do tcl[i]=7 end
for i=64,67 do tcl[i]=13 end
for i=80,95 do tcl[i]=11 end

function in_bounds(x,y)
 return x>=0 and y>=0 and x<gridw and y<gridh
end

function tile(x,y)
 return in_bounds(x,y) and mget(x,y) or 0
end

function set_tile(x,y,s)
 if in_bounds(x,y) then mset(x,y,s) end
end

function is_road(x,y) return fget(tile(x,y),0) end
function is_zone(x,y) return fget(tile(x,y),1) end
function conducts(x,y) return fget(tile(x,y),2) end
function is_buildable(x,y) return fget(tile(x,y),3) end

zone_base=split"32,36,40"

function zone_kind(x,y)
 if not is_zone(x,y) then return nil end
 return flr((tile(x,y)-32)/4)+1
end

function zone_density(x,y)
 if not is_zone(x,y) then return nil end
 return (tile(x,y)-32)%4
end

function set_zone(x,y,kind,density)
 set_tile(x,y,zone_base[kind]+density)
end

function has_road_access(x,y)
 local r=p.road_radius
 for dy=-r,r do
  for dx=-r,r do
   if is_road(x+dx,y+dy) then return true end
  end
 end
 return false
end

function neighbors4(x,y)
 local n={}
 if in_bounds(x-1,y) then add(n,{x=x-1,y=y}) end
 if in_bounds(x+1,y) then add(n,{x=x+1,y=y}) end
 if in_bounds(x,y-1) then add(n,{x=x,y=y-1}) end
 if in_bounds(x,y+1) then add(n,{x=x,y=y+1}) end
 return n
end

-- autotile bitmask of neighbors passing test f (n=1 e=2 s=4 w=8)
function nmask(x,y,f)
 local m=0
 if f(x,y-1) then m+=1 end
 if f(x+1,y) then m+=2 end
 if f(x,y+1) then m+=4 end
 if f(x-1,y) then m+=8 end
 return m
end

-- first grid tile where pred(x,y) is true (scan order); nil if none.
-- the vehicle pathfinds anyway, so "first" is fine and cheaper than "nearest".
function find_tile(pred)
 for y=0,gridh-1 do
  for x=0,gridw-1 do
   if pred(x,y) then return x,y end
  end
 end
end

function is_rubble(s) return s==56 or s>=96 and s<=98 end

function init_map()
 for y=0,gridh-1 do
  for x=0,gridw-1 do
   set_tile(x,y,rnd()<0.12 and 2 or 1)
  end
 end
 -- sometimes one side of the map is open sea
 local oc=rnd()<p.ocean_chance and flr(rnd(2)) or nil
 if oc then
  for y=0,gridh-1 do
   for i=0,1+flr(rnd(3)) do
    set_tile(oc==0 and i or gridw-1-i,y,3)
   end
  end
 end
 -- mountain ranges, then a lone mesa (same drunken walk, new paint)
 for m=1,p.ranges+flr(rnd(2)) do
  rough(4+flr(rnd(40)),4+flr(rnd(40)),24+flr(rnd(16)),5,true)
 end
 rough(6+flr(rnd(36)),6+flr(rnd(36)),30,4,false)
 -- highland fringes climb the foothills
 for y=0,gridh-1 do
  for x=0,gridw-1 do
   if tile(x,y)<3 then
    for d in all(neighbors4(x,y)) do
     if tile(d.x,d.y)==5 and rnd()<0.7 then set_tile(x,y,4) end
    end
   end
  end
 end
 -- main river, top to bottom: narrow source, wide mouth, momentum
 -- meanders. it carves straight through rock (canyons)
 local rx=10+flr(rnd(28))
 local v=0
 for y=0,gridh-1 do
  local w=1+flr(y/20)
  if rnd()<0.15 then w+=1 end
  for i=0,w-1 do
   set_tile(rx+i,y,3)
  end
  v=mid(-1.2,v+rnd(1)-0.5,1.2)
  rx=mid(2,rx+flr(v+0.5),gridw-6)
 end
 -- a tributary winds in from the west until it meets water
 local ty=10+flr(rnd(28))
 local tx,tv=0,0
 while tx<gridw and tile(tx,ty)~=3 do
  set_tile(tx,ty,3)
  tv=mid(-1,tv+rnd(0.8)-0.4,1)
  ty=mid(1,ty+flr(tv+0.5),gridh-2)
  tx+=1
 end
 calc_flow()
 camx,camy=0,0
end

-- drunken-walk painter for terrain blobs
function rough(x,y,n,s,over)
 for i=1,n do
  if over or tile(x,y)<3 then set_tile(x,y,s) end
  x=mid(1,x+flr(rnd(3))-1,gridw-2)
  y=mid(1,y+flr(rnd(3))-1,gridh-2)
 end
end

-- per-row flow vector from the channel's actual curve, so ripples
-- drift sideways along bends. recomputed after load too.
function calc_flow()
 flow={}
 local prev=nil
 for y=0,gridh-1 do
  local l=nil
  for x=0,gridw-1 do
   if l==nil and tile(x,y)==3 then l=x end
  end
  flow[y]=0
  if prev~=nil and l~=nil and y>0 then
   flow[y-1]=mid(-1,l-prev,1)
  end
  prev=l
 end
end

-- view: hud rows 0..7, world fills y 8..127 (16x15 tiles).
-- the camera eases toward its target a few px/frame so scrolling glides
-- per-pixel instead of jumping a whole tile when the cursor hits an edge.
function update_camera(snap)
 local px,py=cur.x*8,cur.y*8
 local tx,ty=camx,camy
 if px-tx<16 then tx=px-16 end
 if px-tx>104 then tx=px-104 end
 if py-ty<16 then ty=py-16 end
 if py-ty>96 then ty=py-96 end
 tx=mid(0,tx,gridw*8-128)
 ty=mid(0,ty,gridh*8-120)
 if snap then
  camx,camy=tx,ty
 else
  camx+=mid(-4,tx-camx,4)
  camy+=mid(-4,ty-camy,4)
 end
end

function draw_world()
 clip(0,8,128,120)
 camera(camx,camy-8)
 -- night darkens the world
 if dn_phase()=="night" then dn_dark() end
 local cx,cy=flr(camx/8),flr(camy/8)
 map(cx,cy,cx*8,cy*8,17,16)
 -- per-tile overlays: flowing water, unpowered bolts, pollution haze
 local bl=t()%1<0.5
 for y=cy,min(gridh-1,cy+15) do
  for x=cx,min(gridw-1,cx+16) do
   local s=tile(x,y)
   if s==3 then
    -- two animated layers: light sparkle + dark dot, both following flow
    local fx=flow[y] or 0
    local dt=flr(t()*10)
    local dt2=flr(t()*6)
    local xx=(x*5+y*3+(fx~=0 and dt*fx or 0))%6+1
    local yy=(x*3+y*5+(fx==0 and dt or 0))%8
    pset(x*8+xx,y*8+yy,6)
    local xx2=(x*7+y*11+(fx~=0 and dt2*fx or 0))%6+1
    local yy2=(x*11+y*7+(fx==0 and dt2 or 0))%8
    pset(x*8+xx2,y*8+yy2,1)
   elseif is_zone(x,y) or s>=64 and s<=67 then
    -- unpowered buildings flash a bolt; powered dense zones light windows
    if not is_powered(x,y) then
     if bl then spr(52,x*8,y*8) end
    elseif is_zone(x,y) and zone_density(x,y)>0 then
     draw_window_lights(x,y,zone_kind(x,y),zone_density(x,y))
    end
   end
   -- industrial/plant stacks emit puffy smoke particles
   if s>=41 and s<=43 or s==48 then
    if (frame+x*3+y*7)%12==0 then
     add_smoke(x,y)
    end
   end
  end
 end
 pal()
 draw_traffic()
 draw_fires()
 draw_veh(veh)
 draw_fx()
 if mode~="map" then
  local px,py=cur.x*8,cur.y*8
  local e=tools_list[tool]
  -- ghost preview: what the tool would build, dithered until placed
  if mode=="play" and not e.spd and not e.insp and e.name~="map" then
   local put=not (e.name=="bulldoze") and tool_put(e,cur.x,cur.y)
   if put then
    spr(put,px,py)
    fillp(0x5a5a+0x.8)
    rectfill(px,py,px+7,py+7,0)
    fillp()
   elseif e.name~="bulldoze" or tile(cur.x,cur.y)>3 then
    line(px+2,py+2,px+5,py+5,8)
    line(px+5,py+2,px+2,py+5,8)
   end
  end
  rect(px,py,px+7,py+7,t()%0.4<0.2 and 7 or 10)
 end
 camera()
 clip()
end
