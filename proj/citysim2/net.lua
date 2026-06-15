-- net.lua : road connected-components + adjacency helpers
-- api: update_net, rcomp, connected, powered
-- private prefix: nt_

ncomp=0  -- number of road components found (global, read by sim)
psup={}  -- supply units per power-network component id
pdem={}  -- demand units (zones drawing) per power-network component id
plants={} -- list of {x,y} plant tiles (smokestack emitters for fx)

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
 -- power: label connected carrier tiles into networks (pl_pow), summing each
 -- network's SUPPLY (plants) and DEMAND (one unit per zone tile). powered() then
 -- compares the two; over capacity -> rolling brownouts. zones carry power too,
 -- so a built-up block conducts without a wire to every lot.
 pclr(pl_pow)
 psup={} pdem={} plants={}
 local pn=0
 for y=0,gw-1 do
  for x=0,gw-1 do
   if power_carries(x,y) and peekp(pl_pow,x,y)==0 then
    pn+=1 local id=pn
    flood(x,y,power_carries,function(fx,fy)
     pokep(pl_pow,fx,fy,id)
     local s=tile(fx,fy)
     if s==60 then psup[id]=(psup[id] or 0)+p.plant_sup add(plants,{x=fx,y=fy})
     elseif s==65 then psup[id]=(psup[id] or 0)+p.bigplant_sup add(plants,{x=fx,y=fy})
     elseif is_zone(fx,fy) then pdem[id]=(pdem[id] or 0)+1 end
    end)
   end
  end
 end
end

-- tiles that carry power: wires/plant (conducts), any zone, service buildings
-- (park 61 / station 62), and a wire overlay crossing a road or water (pl_wire).
function power_carries(x,y)
 local s=tile(x,y)
 return conducts(x,y) or is_zone(x,y) or s==61 or s==62 or s==64 or s==65 or peekp(pl_wire,x,y)>0
end

-- the nearest road tile within p.road_reach (chebyshev), scanned ring by ring,
-- or nil. lets a zone reach a road that's diagonal / up to 2 tiles away.
function near_road(x,y)
 for r=0,p.road_reach do
  for dy=-r,r do
   for dx=-r,r do
    if max(abs(dx),abs(dy))==r and is_road(x+dx,y+dy) then
     return x+dx,y+dy
    end
   end
  end
 end
end

function rcomp(x,y)
 local rx,ry=near_road(x,y)
 return rx and peekp(pl_comp,rx,ry) or 0
end

function connected(ax,ay,bx,by)
 local ca=rcomp(ax,ay)
 return ca~=0 and ca==rcomp(bx,by)
end

-- is (x,y) drawing power right now? its network needs a plant (supply>0); if
-- supply meets demand everyone's lit, else only `supply` of `demand` consumers
-- are served at a time and the served window ROTATES -> rolling brownouts.
function powered(x,y)
 local id=peekp(pl_pow,x,y)
 if id==0 then
  for _,n in pairs(neighbors4(x,y)) do
   id=peekp(pl_pow,n.x,n.y) if id~=0 then break end
  end
 end
 local s=psup[id or 0] or 0
 if s==0 then return false end          -- no plant on this network
 local d=pdem[id] or 0
 if s>=d then return true end           -- supply meets demand: all lit
 return (x+y*gw+flr((tick or 0)/p.brownout_iv))%d<s
end
