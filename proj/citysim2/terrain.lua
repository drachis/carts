-- terrain.lua : a calm, buildable map — all grass with ONE meandering river.
-- (Replaced the percentile lakes + mountains, which scattered obstacles that
-- didn't read well or play well.) The river flows top->bottom, wandering a
-- little, width p.river_w; bridge it with roads / cross it with wires.
function gen_terrain()
 for y=0,gw-1 do
  for x=0,gw-1 do set_tile(x,y,1) end
 end
 local rx=flr(gw/3)+flr(rnd(gw/3))
 for ry=0,gw-1 do
  for w=0,p.river_w-1 do set_tile(min(rx+w,gw-1),ry,0) end
  rx=mid(1,rx+flr(rnd(3))-1,gw-1-p.river_w)
 end
end
