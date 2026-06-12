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

-- find a road tile adjacent to a zone matching kind(s)
-- kinds is a table of zone_kind values to accept
local function tr_find_stop(kinds)
 for _=1,12 do
  local zx=flr(rnd(gridw))
  local zy=flr(rnd(gridh))
  local zk=zone_kind(zx,zy)
  local ok=false
  if zk~=nil and zone_density(zx,zy)>0 then
   for _,k in pairs(kinds) do
    if k==zk then ok=true end
   end
  end
  if ok then
   local ns=neighbors4(zx,zy)
   for _,n in pairs(ns) do
    if is_road(n.x,n.y) then
     return n.x,n.y
    end
   end
  end
 end
 return nil,nil
end

function update_traffic()
 -- spawn commuters
 if frame%32==0 and pop>0 and #tr_cars<min(12,2+flr(pop/12)) then
  local ox,oy=tr_find_stop({1})
  local dx,dy=tr_find_stop({2,3})
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

 -- move cars
 local keep={}
 for _,c in pairs(tr_cars) do
  local alive=true
  if c.life>0 then
   c.life-=1
   local n=c.path[c.i]
   local tx=n.x*8+3
   local ty=n.y*8+3
   local sx=sgn0(tx-c.px)
   local sy=sgn0(ty-c.py)
   if sx~=0 then
    c.dx=sx
    c.dy=0
    c.px+=sx
   elseif sy~=0 then
    c.dx=0
    c.dy=sy
    c.py+=sy
   end
   -- check arrival at node
   if c.px==tx and c.py==ty then
    if not is_road(n.x,n.y) then
     alive=false
    else
     c.i+=1
     if c.i>#c.path then
      alive=false
     end
    end
   end
  else
   alive=false
  end
  if alive then
   add(keep,c)
  end
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
