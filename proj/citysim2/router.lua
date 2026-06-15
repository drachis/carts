-- router.lua : weighted dijkstra + bfs flood
-- q entries: {x,y,d} positional

function path(x0,y0,x1,y1,pass,cost)
 if x0==x1 and y0==y1 then return {{x=x0,y=y0}} end
 local di={} local fr={}
 local k0=x0+y0*gw
 di[k0]=0 fr[k0]=-1
 local q={{x0,y0,0}} local qi=1
 while qi<=#q do
  local c=q[qi] qi+=1
  local cx,cy,cd=c[1],c[2],c[3]
  local ck=cx+cy*gw
  if cd<=di[ck] then
   if cx==x1 and cy==y1 then break end
   for _,n in pairs(neighbors4(cx,cy)) do
    local nx,ny=n.x,n.y
    if pass(nx,ny) then
     local nk=nx+ny*gw
     local nd=cd+cost(nx,ny)
     if di[nk]==nil or nd<di[nk] then
      di[nk]=nd fr[nk]=ck
      add(q,{nx,ny,nd})
     end
    end
   end
  end
 end
 if fr[x1+y1*gw]==nil then return nil end
 local rv={} local k=x1+y1*gw
 while k~=k0 do
  add(rv,{x=k%gw,y=flr(k/gw)})
  k=fr[k]
 end
 add(rv,{x=x0,y=y0})
 local r={}
 for i=#rv,1,-1 do add(r,rv[i]) end
 return r
end

-- BFS over pass-tiles. optional max caps the number of tiles visited (nearest
-- first), giving e.g. a power plant a finite capacity/reach.
function flood(x0,y0,pass,visit,max)
 if not pass(x0,y0) then return end
 local sn={[x0+y0*gw]=true}
 local q={{x0,y0}} local qi=1
 visit(x0,y0)
 local cnt=1
 while qi<=#q do
  local c=q[qi] qi+=1
  for _,n in pairs(neighbors4(c[1],c[2])) do
   local nk=n.x+n.y*gw
   if pass(n.x,n.y) and not sn[nk] then
    sn[nk]=true visit(n.x,n.y) add(q,{n.x,n.y}) cnt+=1
   end
  end
  if max and cnt>=max then break end
 end
end
