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
 local npowered=#q
 -- bfs through conductive neighbors up to cap
 while qi<=#q do
  if npowered>=cap then
   -- check if any unpowered reachable tiles remain
   local c=q[qi]
   local nb=neighbors4(c.x,c.y)
   for i=1,#nb do
    local n=nb[i]
    if conducts(n.x,n.y) and not powered[n.x+n.y*64] then
     power_short=true
    end
   end
   qi=qi+1
  else
   local c=q[qi]
   qi=qi+1
   local nb=neighbors4(c.x,c.y)
   for i=1,#nb do
    local n=nb[i]
    if conducts(n.x,n.y) then
     local k=n.x+n.y*64
     if not powered[k] then
      if npowered<cap then
       powered[k]=true
       npowered=npowered+1
       add(q,{x=n.x,y=n.y})
      else
       power_short=true
      end
     end
    end
   end
  end
 end
end

function is_powered(x,y)
 return powered[x+y*64]==true
end
