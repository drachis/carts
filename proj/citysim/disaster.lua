-- disaster.lua : fire spread, fire engines, tornado

dz_fires={}
dz_fmap={}  -- fast burning-tile lookup keyed by x+y*64

function init_disaster()
 dz_fires={}
 dz_fmap={}
 veh=nil  -- one shared service vehicle: red=fire engine, green=wrecking crew
end

-- ONE service vehicle does both jobs: fires take priority (red, job 1),
-- otherwise it clears rubble (green, job 2). only colour, target and the
-- arrival action differ; movement, drawing and the particle burst are common.
function veh_make(sbx,sby,tx,ty,col,job)
 local sx,sy=find_road_near(sbx,sby,1)
 local ex,ey=find_road_near(tx,ty,p.eng_radius)
 if sx and ex then
  local path=tr_path(sx,sy,ex,ey)
  if path then
   veh={path=path,i=2,px=path[1].x*8+3,py=path[1].y*8+3,
    dx=0,dy=0,tx=tx,ty=ty,col=col,job=job,spray=0}
  end
 end
end

-- advance 2 px-steps: true=reached path end, false=road gone, nil=travelling
function veh_step(v)
 for st=1,2 do
  if not path_step(v) then return v.i>#v.path end
 end
end

function draw_veh(v)
 if not v then return end
 rectfill(v.px-2,v.py-1,v.px+1,v.py+1,v.col)
 pset(v.px-2,v.py,7)
 if v.spray>0 then
  for j=1,4 do
   pset(v.px+rnd(13)-6,v.py-rnd(8),rnd()<0.5 and 12 or 7)
  end
 end
end

function gt_clear(x,y)
 local s=tile(x,y)
 if s>=96 and s<=98 then set_zone(x,y,s-95,0) else set_tile(x,y,1) end
 refresh_around(x,y)
 update_power()
end

-- pick a job: a station drives to the first fire, else a depot to first rubble
function veh_dispatch()
 local f=dz_fires[1]
 if f then
  local bx,by=find_tile(function(x,y) return tile(x,y)==64 end)
  if bx then veh_make(bx,by,f.x,f.y,8,1) end
 else
  local dx,dy=find_tile(function(x,y)
   return tile(x,y)==67 and is_powered(x,y) end)
  local rx,ry=find_tile(function(x,y) return is_rubble(tile(x,y)) end)
  if dx and rx then veh_make(dx,dy,rx,ry,3,2) end
 end
end

function update_veh()
 if veh then
  local v=veh
  if v.spray>0 then          -- only fire engines linger to spray + suppress
   v.spray-=1
   for _,f in pairs(dz_fires) do
    if abs(f.x*8+3-v.px)<=20 and abs(f.y*8+3-v.py)<=20 then f.t-=5 end
   end
   if v.spray<=0 or #dz_fires==0 then veh=nil end
  else
   local arr=veh_step(v)
   if arr then
    add_fx(v.tx,v.ty,4,0.3,-0.2,20,7,12) -- same burst for both jobs
    if v.job==1 then v.spray=120
    else
     if is_rubble(tile(v.tx,v.ty)) then gt_clear(v.tx,v.ty) end
     veh=nil
    end
   elseif arr==false then veh=nil end
  end
 elseif #dz_fires>0 or frame%30==0 then
  veh_dispatch()
 end
end

function dz_covered(x,y)
 local r=p.station_radius
 for yy=max(0,y-r),min(gridh-1,y+r) do
  for xx=max(0,x-r),min(gridw-1,x+r) do
   if tile(xx,yy)==64 and is_powered(xx,yy) then return true end
  end
 end
 return false
end

function dz_ignite(x,y)
 local k=x+y*64
 if dz_fmap[k] then return end
 dz_fmap[k]=true
 local was_empty=#dz_fires==0
 add(dz_fires,{x=x,y=y,
  t=dz_covered(x,y) and p.station_burn_t or p.burn_t,
  zk=zone_kind(x,y),sp=p.spread_delay,si=0})
 if was_empty then
  msg="fire!" msg_t=90
  sfx(3)
 end
end

function dz_pick_fire_tile()
 for pass=1,2 do
  for _=1,30 do
   local x=flr(rnd(gridw))
   local y=flr(rnd(gridh))
   if is_zone(x,y) and (pass==2 or zone_density(x,y)>0) then
    return x,y
   end
  end
 end
end

function start_fire()
 local x,y=dz_pick_fire_tile()
 if x==nil then msg,msg_t="no fuel",60 return false end
 dz_ignite(x,y)
 return true
end

-- nearest road tile within chebyshev radius r of (cx,cy)
function find_road_near(cx,cy,r)
 for dy=-r,r do
  for dx=-r,r do
   if is_road(cx+dx,cy+dy) then return cx+dx,cy+dy end
  end
 end
end

function update_disaster()
 if frame%p.fire_frames==0 and rnd()<p.fire_chance then
  local x,y=dz_pick_fire_tile()
  if x~=nil then dz_ignite(x,y) end
 end

 local keep={}
 for _,f in pairs(dz_fires) do
  f.t-=1
  f.sp-=1
  if f.sp<=0 and f.t>0 then
   f.sp=p.spread_int
   -- spread probability ramps up with each attempt; engine spray suppresses it
   local prob=min(p.spread_max,p.spread_min+f.si*0.15)
   local e=veh
   if e and e.job==1 and e.spray>0
    and abs(f.x*8+3-e.px)<=20 and abs(f.y*8+3-e.py)<=20 then
    prob*=0.25  -- engine spraying this tile: 75% spread reduction
   end
   f.si+=1
   if rnd()<prob and not (dz_covered(f.x,f.y) and rnd()<0.75) then
    local nb=neighbors4(f.x,f.y)
    if #nb>0 then
     local n=nb[1+flr(rnd(#nb))]
     if is_zone(n.x,n.y) or tile(n.x,n.y)==48 then
      dz_ignite(n.x,n.y)
     elseif is_road(n.x,n.y) then
      for _,r in pairs(neighbors4(n.x,n.y)) do
       if is_zone(r.x,r.y) then dz_ignite(r.x,r.y) end
      end
     end
    end
   end
  end
  if f.t<=0 then
   dz_fmap[f.x+f.y*64]=nil
   set_tile(f.x,f.y,f.zk and 95+f.zk or 56)
   update_power()
  else
   add(keep,f)
  end
 end
 dz_fires=keep
end

function draw_fires()
 for _,f in pairs(dz_fires) do
  for _=1,3 do
   pset(f.x*8+rnd(8),f.y*8+rnd(8),rnd()<0.5 and 10 or 9)
  end
 end
end

