-- traffic.lua : purposeful commuter cars on roads

tr_cars={}
tr_last_phase=nil

local tr_cols=split"7,8,10,12,14"

local function sgn0(n)
 if n>0 then return 1
 elseif n<0 then return -1
 else return 0 end
end

-- bfs over road tiles; visit cap 500
-- returns path as list of {x=,y=} or nil
function tr_path(x0,y0,x1,y1)
 if not is_road(x0,y0) or not is_road(x1,y1) then return nil end
 if x0==x1 and y0==y1 then return {{x=x0,y=y0}} end
 local from={}
 local q={}
 local qi=1
 add(q,{x=x0,y=y0})
 from[x0+y0*64]=-1  -- sentinel: start
 local found=false
 local visited=0
 while qi<=#q and visited<500 do
  local cur=q[qi]
  qi+=1
  visited+=1
  if cur.x==x1 and cur.y==y1 then
   found=true
   break
  end
  local ns=neighbors4(cur.x,cur.y)
  for _,n in pairs(ns) do
   local k=n.x+n.y*64
   if is_road(n.x,n.y) and from[k]==nil then
    from[k]={x=cur.x,y=cur.y}
    add(q,n)
   end
  end
 end
 if not found then return nil end
 -- reconstruct path
 local path={}
 local cx,cy=x1,y1
 while not (cx==x0 and cy==y0) do
  add(path,{x=cx,y=cy})
  local p=from[cx+cy*64]
  cx=p.x
  cy=p.y
 end
 add(path,{x=x0,y=y0})
 -- reverse
 local rev={}
 for i=#path,1,-1 do
  add(rev,path[i])
 end
 return rev
end

-- find a road tile adjacent to a developed zone.
-- when want_r=true: seek residential; when false: seek workplace.
-- early game (jobs==0): accept any developed zone so cars still spawn.
-- first road tile orthogonally adjacent to x,y (nil if none)
local function adj_road(x,y)
 for _,n in pairs(neighbors4(x,y)) do
  if is_road(n.x,n.y) then return n.x,n.y end
 end
end

local function tr_find_stop(want_r)
 for _=1,12 do
  local zx=flr(rnd(gridw))
  local zy=flr(rnd(gridh))
  local zk=zone_kind(zx,zy)
  if zk~=nil and zone_density(zx,zy)>0
   and (jobs==0 or (zk==1)==want_r) then
   local rx,ry=adj_road(zx,zy)
   if rx then return rx,ry end
  end
 end
end

-- find a road tile adjacent to a school building (sprite 66)
local function tr_find_school()
 for _=1,12 do
  local x=flr(rnd(gridw))
  local y=flr(rnd(gridh))
  if tile(x,y)==66 then return adj_road(x,y) end
 end
end

function init_traffic()
 tr_cars={}
 tr_last_phase=dn_phase()
end

-- advance any path-follower (car, fire engine) one pixel.
-- returns false when the trip is over: arrival, or road gone.
function path_step(c)
 local n=c.path[c.i]
 local tx=n.x*8+3
 local ty=n.y*8+3
 local sx=sgn0(tx-c.px)
 local sy=sgn0(ty-c.py)
 if sx~=0 then
  c.dx,c.dy=sx,0
  c.px+=sx
 elseif sy~=0 then
  c.dx,c.dy=0,sy
  c.py+=sy
 end
 if c.px==tx and c.py==ty then
  if not is_road(n.x,n.y) then return false end
  c.i+=1
  if c.i>#c.path then return false end
 end
 return true
end

-- build a car from ox,oy to dx,dy if the route is valid
function tr_spawn(ox,oy,dx,dy,life)
 if ox==nil or dx==nil or (ox==dx and oy==dy) then return end
 local path=tr_path(ox,oy,dx,dy)
 if path~=nil and #path>1 then
  add(tr_cars,{path=path,i=2,
   px=path[1].x*8+3,py=path[1].y*8+3,
   dx=0,dy=0,sdx=0,sdy=0,
   col=tr_cols[1+flr(rnd(#tr_cols))],life=life})
 end
end

function update_traffic()
 -- spawn a wave of commuters at each day/night transition:
 --   dawn (→day): R zones send workers to C/I (and some to school)
 --   dusk (→night): C/I zones send workers back home to R
 local phase=dn_phase()
 if phase~=tr_last_phase and pop>0 then
  tr_last_phase=phase
  local work=(phase=="day")
  local cap=min(p.car_cap,2+flr(pop/p.car_pop))
  local tries=cap*4
  while tries>0 and #tr_cars<cap do
   tries-=1
   local ox,oy=tr_find_stop(work)
   local dx,dy
   if work and rnd()<0.3 then dx,dy=tr_find_school() end
   if not dx then dx,dy=tr_find_stop(not work) end
   tr_spawn(ox,oy,dx,dy,600)
  end
 end

 -- daytime errands/shopping/deliveries: steady background bustle so the city
 -- feels alive between the dawn/dusk commute waves
 if phase=="day" and frame%p.errand_freq==0 and pop>0
  and #tr_cars<p.car_cap then
  local ox,oy=tr_find_stop(rnd()<0.5)
  local dx,dy=tr_find_stop(rnd()<0.5)
  tr_spawn(ox,oy,dx,dy,400)
 end

 -- move cars; smooth direction lerp kills corner jitter
 local keep={}
 for _,c in pairs(tr_cars) do
  local alive=c.life>0
  if alive then
   c.life-=1
   alive=path_step(c)
   c.sdx+=(c.dx-c.sdx)*0.35
   c.sdy+=(c.dy-c.sdy)*0.35
  end
  if alive then add(keep,c) end
 end
 tr_cars=keep
end

function draw_traffic()
 for _,c in pairs(tr_cars) do
  -- lane offset based on smooth direction: right-hand traffic positioning
  local ox=flr(-c.sdy*2+0.5)
  local oy=flr(c.sdx*2+0.5)
  rectfill(c.px+ox-1,c.py+oy-1,c.px+ox,c.py+oy,c.col)
 end
end
