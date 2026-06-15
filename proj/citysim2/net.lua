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
     elseif is_zone(fx,fy) and zone_density(fx,fy)>0 then
      -- only BUILT buildings draw power (an empty plot conducts but sips nothing).
      -- demand per kind = sum of (density+1); time-of-day weight applied in served.
      local pd=pdem[id] if not pd then pd={0,0,0} pdem[id]=pd end
      pd[zone_kind(fx,fy)]+=zone_density(fx,fy)+1
     end
    end)
   end
  end
 end
 -- power-network distance from the nearest plant: multi-source BFS over the
 -- carriers (same router substrate as road pathing, just a different network).
 -- a packet loses 1 charge per res_dist hops, so the far end of the line dims
 -- first and the loss follows the actual wires around lakes (not a straight line).
 memset(pl_pdist,255,gw*gw)
 local q,qi={},1
 for pl in all(plants) do pokep(pl_pdist,pl.x,pl.y,0) add(q,pl) end
 while qi<=#q do
  local c=q[qi] qi+=1
  local nd=peekp(pl_pdist,c.x,c.y)+1
  for n in all(neighbors4(c.x,c.y)) do
   if power_carries(n.x,n.y) and peekp(pl_pdist,n.x,n.y)>nd then
    pokep(pl_pdist,n.x,n.y,nd) add(q,{x=n.x,y=n.y})
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

-- is the GRID delivering to (x,y) this instant? network needs a plant (supply>0);
-- if supply meets demand everyone's served, else only `supply` of `demand`
-- consumers at a time and the served window ROTATES (rolling brownouts). demand
-- is per-kind tier units weighted by time of day.
function served(x,y)
 local id=peekp(pl_pow,x,y)
 if id==0 then
  for _,n in pairs(neighbors4(x,y)) do
   id=peekp(pl_pow,n.x,n.y) if id~=0 then break end
  end
 end
 local s=psup[id or 0] or 0
 if s==0 then return false end
 local pd,d=pdem[id],0
 if pd then
  local dp=day_phase and day_phase() or 0
  for k=1,3 do d+=pd[k]*(p.pwr_day[k]+(p.pwr_night[k]-p.pwr_day[k])*dp) end
  d=flr(d/10)
 end
 if s>=d then return true end
 return (x+y*gw+flr((tick or 0)/p.brownout_iv))%d<s
end

-- hourly battery pass: every building drains 1, and grabs a full packet only
-- when it has room for one AND the grid is serving it. a building that misses a
-- packet coasts on its battery, then goes dark -> blackouts roll out of phase.
function pwr_tick()
 for y=0,gw-1 do
  for x=0,gw-1 do
   if is_zone(x,y) and zone_density(x,y)>0 then  -- empty plots store no power
    local c=max(0,peekp(pl_chg,x,y)-1)
    -- a delivered packet arrives weakened by line resistance (distance loss)
    if c<=p.pwr_cap-p.pwr_pkt and served(x,y) then
     c=min(p.pwr_cap,c+max(0,p.pwr_pkt-flr(peekp(pl_pdist,x,y)/p.res_dist)))
    end
    pokep(pl_chg,x,y,c)
   end
  end
 end
end

-- a building is powered if its battery has charge.
function powered(x,y)
 return peekp(pl_chg,x,y)>0
end
