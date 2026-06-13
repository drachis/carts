-- network.lua : glassbox-lite road component labeling + zone needs

function init_net()
 net={}
 net_rci={}
end

function update_net(force)
 if not force and frame%64~=2 then return end
 net={}
 net_rci={}
 local nid=0
 for y=0,gridh-1 do for x=0,gridw-1 do
  if is_road(x,y) and not net[x+y*64] then
   nid+=1
   nt_flood(x,y,nid)
  end
 end end
end

function nt_flood(x,y,id)
 local q={{x=x,y=y}}
 net[x+y*64]=id
 local qi=1
 while qi<=#q do
  local c=q[qi] qi+=1
  for _,n in pairs(neighbors4(c.x,c.y)) do
   local k=zone_kind(n.x,n.y)
   if k then
    local ki=id*4+k
    net_rci[ki]=(net_rci[ki] or 0)+zone_density(n.x,n.y)
   end
   if is_road(n.x,n.y) and not net[n.x+n.y*64] then
    net[n.x+n.y*64]=id
    add(q,n)
   end
  end
 end
end

function net_ok(x,y,k,dens)
 if dens<1 then return true end
 local id
 for dy=-1,1 do for dx=-1,1 do
  id=id or net[(x+dx)+(y+dy)*64]
 end end
 if not id then return false end
 local r=net_rci[id*4+1] or 0
 local c=net_rci[id*4+2] or 0
 local i=net_rci[id*4+3] or 0
 if k==1 then return c+i>0 end
 if k==2 then return r>0 and i>0 end
 return r>0
end
