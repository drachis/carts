-- power.lua : bfs power propagation
-- provides: init_power(), update_power(), is_powered(x,y)

function init_power()
 powered={}
end

function update_power()
 powered={}
 local q={}
 local qi=1
 -- scan full grid for power plants (sprite 48)
 for y=0,gridh-1 do
  for x=0,gridw-1 do
   if tile(x,y)==48 then
    local k=x+y*64
    if not powered[k] then
     powered[k]=true
     add(q,{x=x,y=y})
    end
   end
  end
 end
 -- bfs through conductive neighbors
 while qi<=#q do
  local c=q[qi]
  qi=qi+1
  local nb=neighbors4(c.x,c.y)
  for i=1,#nb do
   local n=nb[i]
   if conducts(n.x,n.y) then
    local k=n.x+n.y*64
    if not powered[k] then
     powered[k]=true
     add(q,{x=n.x,y=n.y})
    end
   end
  end
 end
end

function is_powered(x,y)
 return powered[x+y*64]==true
end
