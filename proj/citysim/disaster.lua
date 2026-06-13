-- disaster.lua : fire spread, fire engines, tornado

dz_fires={}
dz_fmap={}  -- fast burning-tile lookup keyed by x+y*64

function init_disaster()
 dz_fires={}
 dz_fmap={}
 dz_eng=nil
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
  zk=zone_kind(x,y)})
 if was_empty then
  msg="fire!" msg_t=90
  sfx(3)
 end
 dz_dispatch(x,y)
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

-- pathfind from nearest station → road near fire; no station = no engine
function dz_dispatch(fx,fy)
 if dz_eng then return end
 local bx,by,bd=nil,nil,9999
 for y=0,gridh-1 do
  for x=0,gridw-1 do
   if tile(x,y)==64 then
    local d=abs(x-fx)+abs(y-fy)
    if d<bd then bx,by,bd=x,y,d end
   end
  end
 end
 if not bx then return end
 local sx,sy=find_road_near(bx,by,1)
 local ex,ey=find_road_near(fx,fy,p.eng_radius)
 if not sx or not ex then return end
 local path=tr_path(sx,sy,ex,ey)
 if not path then return end
 dz_eng={path=path,i=2,px=path[1].x*8+3,py=path[1].y*8+3,
  dx=0,dy=0,spray=0}
end

function update_disaster()
 if frame%p.fire_frames==0 and rnd()<p.fire_chance then
  local x,y=dz_pick_fire_tile()
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
    if is_zone(n.x,n.y) or tile(n.x,n.y)==48 then
     dz_ignite(n.x,n.y)
    elseif is_road(n.x,n.y) then
     -- fire jumps across roads to zones on the far side
     for _,r in pairs(neighbors4(n.x,n.y)) do
      if is_zone(r.x,r.y) then dz_ignite(r.x,r.y) end
     end
    end
   end
  end
  if f.t<=0 then
   dz_fmap[f.x+f.y*64]=nil
   -- zone: zone-specific rubble (96=r,97=c,98=i); non-zone: generic rubble
   set_tile(f.x,f.y,f.zk and 95+f.zk or 56)
  else
   add(keep,f)
  end
 end
 dz_fires=keep

 if dz_eng then
  local e=dz_eng
  if e.spray>0 then
   e.spray-=1
   for _,f in pairs(dz_fires) do
    if abs(f.x*8+3-e.px)<=20 and abs(f.y*8+3-e.py)<=20 then
     f.t-=5
    end
   end
   if e.spray<=0 or #dz_fires==0 then dz_eng=nil end
  else
   for st=1,2 do
    if dz_eng and e.spray==0 and not path_step(e) then
     if e.i>#e.path then e.spray=120 else dz_eng=nil end
    end
   end
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

function draw_engine()
 local e=dz_eng
 if not e then return end
 rectfill(e.px-2,e.py-1,e.px+1,e.py+1,8)
 pset(e.px-2,e.py,7)
 if e.spray>0 then
  for j=1,4 do
   pset(e.px+flr(rnd(13))-6,e.py-flr(rnd(8)),rnd()<0.5 and 12 or 7)
  end
 end
end
