-- map.lua : grid helpers, terrain gen, camera, world draw
-- the grid lives in pico-8 map ram: sprite id = tile state (see design.md)

gridw,gridh=48,48

function in_bounds(x,y)
 return x>=0 and y>=0 and x<gridw and y<gridh
end

function tile(x,y)
 if not in_bounds(x,y) then return 0 end
 return mget(x,y)
end

function set_tile(x,y,s)
 if in_bounds(x,y) then mset(x,y,s) end
end

function is_road(x,y) return fget(tile(x,y),0) end
function is_zone(x,y) return fget(tile(x,y),1) end
function conducts(x,y) return fget(tile(x,y),2) end
function is_buildable(x,y) return fget(tile(x,y),3) end

zone_base={32,36,40}

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

function init_map()
 for y=0,gridh-1 do
  for x=0,gridw-1 do
   set_tile(x,y,rnd()<0.12 and 2 or 1)
  end
 end
 -- a river wandering top to bottom: narrow source, wide mouth downstream
 local rx=8+flr(rnd(32))
 for y=0,gridh-1 do
  local w=1+flr(y/20)
  for i=0,w-1 do
   set_tile(rx+i,y,3)
  end
  rx=mid(1,rx+flr(rnd(3))-1,gridw-5)
 end
 camx,camy=0,0
end

-- view: hud rows 0..7, world fills y 8..127 (16x15 tiles)
function update_camera()
 local px,py=cur.x*8,cur.y*8
 if px-camx<16 then camx=px-16 end
 if px-camx>104 then camx=px-104 end
 if py-camy<16 then camy=py-16 end
 if py-camy>96 then camy=py-96 end
 camx=mid(0,camx,gridw*8-128)
 camy=mid(0,camy,gridh*8-120)
end

function draw_world()
 clip(0,8,128,120)
 camera(camx,camy-8)
 local cx,cy=flr(camx/8),flr(camy/8)
 map(cx,cy,cx*8,cy*8,17,16)
 -- per-tile overlays: flowing water, unpowered bolts, pollution haze
 local bl=t()%1<0.5
 for y=cy,min(gridh-1,cy+15) do
  for x=cx,min(gridw-1,cx+16) do
   local s=tile(x,y)
   if s==3 then
    -- ripples drift downstream (the river flows to its mouth at the bottom)
    local yy=(flr(t()*16)+x*3)%8
    pset(x*8+(x*5+y*3)%6+1,y*8+yy,(x+y)%2==0 and 7 or 6)
   elseif is_zone(x,y) then
    if bl and not is_powered(x,y) then
     spr(52,x*8,y*8)
    elseif zone_density(x,y)>0 and is_powered(x,y) then
     draw_window_lights(x,y,zone_kind(x,y),zone_density(x,y))
    end
   end
   local v=land_value(x,y)
   if v<=-4 then
    spr(58,x*8,y*8)
   elseif v<=-2 then
    spr(57,x*8,y*8)
   end
  end
 end
 draw_traffic()
 draw_fires()
 if mode~="map" then
  rect(cur.x*8,cur.y*8,cur.x*8+7,cur.y*8+7,t()%0.4<0.2 and 7 or 10)
 end
 camera()
 clip()
end
