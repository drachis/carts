-- disaster.lua : fire spread, rubble, tornado

dz_fires={}
dz_tor=nil

function init_disaster()
 dz_fires={}
 dz_tor=nil
end

-- a fire station nearby shortens burns and slows spread
function dz_covered(x,y)
 local r=p.station_radius
 for yy=max(0,y-r),min(gridh-1,y+r) do
  for xx=max(0,x-r),min(gridw-1,x+r) do
   if tile(xx,yy)==64 then return true end
  end
 end
 return false
end

function dz_ignite(x,y)
 local was_empty=#dz_fires==0
 set_tile(x,y,55)
 add(dz_fires,{x=x,y=y,t=dz_covered(x,y) and p.station_burn_t or p.burn_t})
 if was_empty then
  msg="fire!" msg_t=90
  sfx(3)
 end
end

function dz_pick_fire_tile(need_density)
 for _=1,30 do
  local x=flr(rnd(gridw))
  local y=flr(rnd(gridh))
  if is_zone(x,y) then
   if (not need_density) or zone_density(x,y)>0 then
    return x,y
   end
  end
 end
 return nil,nil
end

function start_fire()
 local x,y=dz_pick_fire_tile(true)
 if x==nil then
  x,y=dz_pick_fire_tile(false)
 end
 if x==nil then
  msg="no fuel for a fire" msg_t=60
  return false
 end
 dz_ignite(x,y)
 return true
end

-- tornado helpers
function dz_spawn_tornado()
 local tx,ty,tdx,tdy
 if rnd()<0.5 then
  -- spawn from left edge
  tx=0
  ty=rnd(48)
  tdx=0.1+rnd(0.1)
  tdy=rnd(0.2)-0.1
 else
  -- spawn from right edge
  tx=47
  ty=rnd(48)
  tdx=-(0.1+rnd(0.1))
  tdy=rnd(0.2)-0.1
 end
 dz_tor={x=tx,y=ty,dx=tdx,dy=tdy,t=240}
 msg="tornado!" msg_t=90
 sfx(3)
end

function start_tornado()
 if dz_tor~=nil then return false end
 dz_spawn_tornado()
 return true
end

function update_disaster()
 -- random fire ignition
 if frame%p.fire_frames==0 and rnd()<p.fire_chance then
  local x,y=dz_pick_fire_tile(true)
  if x==nil then x,y=dz_pick_fire_tile(false) end
  if x~=nil then dz_ignite(x,y) end
 end

 -- random tornado spawning
 if frame%1800==0 and rnd()<0.15 and dz_tor==nil then
  dz_spawn_tornado()
 end

 -- fire tick
 local keep={}
 for _,f in pairs(dz_fires) do
  f.t-=1
  if f.t%30==0 and f.t>0
   and not (dz_covered(f.x,f.y) and rnd()<0.75) then
   local nb=neighbors4(f.x,f.y)
   if #nb>0 then
    local n=nb[1+flr(rnd(#nb))]
    local t=tile(n.x,n.y)
    if is_zone(n.x,n.y) or t==48 then
     dz_ignite(n.x,n.y)
    end
   end
  end
  if f.t<=0 then
   set_tile(f.x,f.y,56)
  else
   add(keep,f)
  end
 end
 dz_fires=keep

 -- tornado tick
 if dz_tor~=nil then
  local tor=dz_tor
  tor.x+=tor.dx
  tor.y+=tor.dy
  tor.dy+=rnd(0.06)-0.03
  tor.dy=mid(-0.3,tor.dy,0.3)
  tor.t-=1

  local tx=flr(tor.x)
  local ty=flr(tor.y)
  if in_bounds(tx,ty) then
   local s=tile(tx,ty)
   local ns=-1
   if is_zone(tx,ty) or s==48 or (s>=64 and s<=66) then
    ns=56
   elseif (s>=16 and s<=31) or (s>=80 and s<=95) or s==53 or s==54 or s==44 or s==2 then
    ns=1
   elseif s>=59 and s<=62 then
    ns=3
   end
   if ns>=0 and s~=ns then
    set_tile(tx,ty,ns)
    refresh_around(tx,ty)
    update_power()
   end
  end

  if tor.t<=0 or tor.x<-2 or tor.x>50 or tor.y<-2 or tor.y>50 then
   dz_tor=nil
  end
 end
end

function draw_fires()
 for _,f in pairs(dz_fires) do
  for _=1,3 do
   pset(f.x*8+flr(rnd(8)),f.y*8+flr(rnd(8)),rnd()<0.5 and 10 or 9)
  end
 end
end

function draw_tornado()
 if dz_tor==nil then return end
 local wx=dz_tor.x*8+4
 local wy=dz_tor.y*8
 circfill(wx,wy+6,2,6)
 circfill(wx+rnd(2)-1,wy+3,3,5)
 circfill(wx+rnd(3)-1,wy,4,6)
 -- debris
 pset(wx+rnd(14)-7,wy+rnd(14)-7,4)
 pset(wx+rnd(14)-7,wy+rnd(14)-7,4)
end
