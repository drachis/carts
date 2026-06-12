-- disaster.lua : fire spread and rubble

dz_fires={}

function init_disaster()
 dz_fires={}
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

function update_disaster()
 if frame%p.fire_frames==0 and rnd()<p.fire_chance then
  local x,y=dz_pick_fire_tile(true)
  if x==nil then x,y=dz_pick_fire_tile(false) end
  if x~=nil then dz_ignite(x,y) end
 end
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
end

function draw_fires()
 for _,f in pairs(dz_fires) do
  for _=1,3 do
   pset(f.x*8+flr(rnd(8)),f.y*8+flr(rnd(8)),rnd()<0.5 and 10 or 9)
  end
 end
end
