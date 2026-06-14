-- net.lua : road connected-components + adjacency helpers
-- api: update_net, rcomp, connected, powered
-- private prefix: nt_

ncomp=0  -- number of road components found (global, read by sim)

function update_net()
 pclr(pl_comp)
 ncomp=0
 for y=0,gw-1 do
  for x=0,gw-1 do
   if is_road(x,y) and peekp(pl_comp,x,y)==0 then
    ncomp+=1
    local id=ncomp
    flood(x,y,is_road,function(fx,fy)
     pokep(pl_comp,fx,fy,id)
    end)
   end
  end
 end
end

function rcomp(x,y)
 if is_road(x,y) then return peekp(pl_comp,x,y) end
 local nb=neighbors4(x,y)
 for _,n in pairs(nb) do
  if is_road(n.x,n.y) then return peekp(pl_comp,n.x,n.y) end
 end
 return 0
end

function connected(ax,ay,bx,by)
 local ca=rcomp(ax,ay)
 return ca~=0 and ca==rcomp(bx,by)
end

-- stub: real power network (offer-index over power channel) comes with sim
function powered(x,y) return true end
