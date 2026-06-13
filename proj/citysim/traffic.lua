-- traffic.lua : purposeful commuter cars on roads

tr_cars={}

function init_traffic()
 tr_cars={}
end

local tr_cols={7,8,10,12,14}

-- sgn with zero: returns -1, 0, or 1
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
local function tr_find_stop(want_r)
 for _=1,12 do
  local zx=flr(rnd(gridw))
  local zy=flr(rnd(gridh))
  local zk=zone_kind(zx,zy)
  if zk~=nil and zone_density(zx,zy)>0
   and (jobs==0 or (zk==1)==want_r) then
   for _,n in pairs(neighbors4(zx,zy)) do
    if is_road(n.x,n.y) then return n.x,n.y end
   end
  end
 end
 return nil,nil
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

function update_traffic()
 -- spawn commuters
 if frame%32==0 and pop>0 and #tr_cars<min(p.car_cap,2+flr(pop/p.car_pop)) then
  local ox,oy=tr_find_stop(true)
  local dx,dy=tr_find_stop(false)
  if ox~=nil and dx~=nil and not(ox==dx and oy==dy) then
   local path=tr_path(ox,oy,dx,dy)
   if path~=nil and #path>1 then
    add(tr_cars,{
     path=path,
     i=2,
     px=path[1].x*8+3,
     py=path[1].y*8+3,
     dx=0,
     dy=0,
     col=tr_cols[1+flr(rnd(#tr_cols))],
     life=600
    })
   end
  end
 end

 -- move cars; reverse path at destination for continuous round-trips
 local keep={}
 for _,c in pairs(tr_cars) do
  local alive=c.life>0
  if alive then
   c.life-=1
   alive=path_step(c)
   if not alive and c.i>#c.path then
    local rev={}
    for i=#c.path,1,-1 do add(rev,c.path[i]) end
    c.path=rev c.i=2 c.life=600
    alive=true
   end
  end
  if alive then add(keep,c) end
 end
 tr_cars=keep
end

function draw_traffic()
 for _,c in pairs(tr_cars) do
  local ox,oy=0,0
  if c.dx==1 then oy=2
  elseif c.dx==-1 then oy=-2
  elseif c.dy==1 then ox=-2
  elseif c.dy==-1 then ox=2
  end
  rectfill(c.px+ox-1,c.py+oy-1,c.px+ox,c.py+oy,c.col)
 end
end
