-- net.lua : road connected-components + adjacency helpers
-- api: update_net, rcomp, connected, powered
-- private prefix: nt_

ncomp=0  -- number of road components found (global, read by sim)
pwr={}   -- set of powered tiles (on a power network fed by a plant)
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
 -- power: flood from each plant (tile 60) over power-carrying tiles. zones carry
 -- power too (a built-up block conducts), so you don't need a wire to every lot.
 pwr={}
 plants={}
 for y=0,gw-1 do
  for x=0,gw-1 do
   if tile(x,y)==60 then
    add(plants,{x=x,y=y})
    flood(x,y,power_carries,function(fx,fy) pwr[fx+fy*gw]=true end)
   end
  end
 end
end

-- tiles that carry power: wires/plant (conducts), any zone, service buildings
-- (park 61 / station 62), and a wire overlay crossing a road or water (pl_wire).
function power_carries(x,y)
 local s=tile(x,y)
 return conducts(x,y) or is_zone(x,y) or s==61 or s==62 or s==64 or peekp(pl_wire,x,y)>0
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

-- a tile is powered if it (or an orthogonal neighbour, e.g. a zone beside a
-- power line) is on a plant-fed power network.
function powered(x,y)
 if pwr[x+y*gw] then return true end
 for _,n in pairs(neighbors4(x,y)) do
  if pwr[n.x+n.y*gw] then return true end
 end
 return false
end
