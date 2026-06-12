-- power.lua : bfs power propagation
-- provides: init_power(), update_power(), is_powered(x,y)
-- global: power_short (true when cap hit with reachable tiles remaining)

function init_power()
 powered={}
 power_short=false
end

function update_power()
 powered={}
 power_short=false
 local q={}
 local qi=1
 local nplants=0
 -- scan full grid for power plants (sprite 48), count them
 for y=0,gridh-1 do
  for x=0,gridw-1 do
   if tile(x,y)==48 then
    nplants=nplants+1
    local k=x+y*64
    if not powered[k] then
     powered[k]=true
     add(q,{x=x,y=y})
    end
   end
  end
 end
 local cap=nplants*p.plant_cap
 local used=0
 -- bfs: anything conductive carries power, but only buildings
 -- (developed zones, services) draw plant capacity. once the grid is
 -- maxed out, further buildings stay dark while power flows past them.
 while qi<=#q do
  local c=q[qi]
  qi=qi+1
  local nb=neighbors4(c.x,c.y)
  for i=1,#nb do
   local n=nb[i]
   if conducts(n.x,n.y) and not powered[n.x+n.y*64] then
    local draw=pw_draw(n.x,n.y)
    if draw>0 and used>=cap then
     power_short=true
    else
     used=used+draw
     powered[n.x+n.y*64]=true
     add(q,{x=n.x,y=n.y})
    end
   end
  end
 end
end

-- capacity drawn by the tile: 1 for an occupied building, 0 for
-- carriers (wires, pylons, crossings, empty zone plots, plants)
function pw_draw(x,y)
 local s=tile(x,y)
 if (s>=64 and s<=66) or (is_zone(x,y) and (s-32)%4>0) then
  return 1
 end
 return 0
end

function is_powered(x,y)
 return powered[x+y*64]==true
end
