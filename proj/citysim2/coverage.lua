-- coverage.lua : the services layer. fire stations (safety) and parks (amenity)
-- project a coverage field into pl_cov; zones need it to grow TALL (density >=2).
-- this makes services matter: a sprawl of lv-1 shacks needs stations/parks to
-- become a real downtown. recomputed on the sim census tick (like land value).
-- api: update_cov, serviced(x,y); reads tile 62 (station) / 61 (park).

function update_cov()
 pclr(pl_cov)
 for y=0,gw-1 do
  for x=0,gw-1 do
   local s=tile(x,y)
   if s==62 or s==61 then
    local r=s==62 and p.fire_rad or p.val_rad
    for dy=-r,r do
     for dx=-r,r do
      pokep(pl_cov,x+dx,y+dy,1)
     end
    end
   end
  end
 end
end

function serviced(x,y)
 return peekp(pl_cov,x,y)>0
end
