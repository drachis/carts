-- disaster.lua : fire — the event loop's namesake. zones ignite, burn over
-- timewheel ticks (k=2 events via ev_hook), spread to neighbours, and collapse
-- to rubble (tile 63). a fire station (tile 62) suppresses fire in its radius.
-- api: init_fire, ignite, start_fire, maybe_ignite, draw_fire, fire_covered
--      globals: fires (active burning tiles), ev_hook (sim dispatch target)
-- calls: is_zone, zone_density, neighbors4, peekp/pokep, schedule, update_net, p
-- pl_fire holds burn ticks remaining; fires[] mirrors it for cheap drawing.

fires={}

function init_fire()
 fires={}
 pclr(pl_fire)
 ev_hook=dis_hook  -- sim routes non-eval events here: k=2 burn, k=3 cleanup
end

-- timewheel dispatcher for disaster events.
function dis_hook(e)
 if e.k==2 then fire_handler(e)
 elseif e.k==3 then wreck_dispatch(e) end
end

-- is a fire station within fire_rad (chebyshev) of (x,y)?
function fire_covered(x,y)
 for dy=-p.fire_rad,p.fire_rad do
  for dx=-p.fire_rad,p.fire_rad do
   if tile(x+dx,y+dy)==62 then return true end
  end
 end
end

local function unfire(x,y)
 pokep(pl_fire,x,y,0)
 for i=#fires,1,-1 do
  if fires[i].x==x and fires[i].y==y then deli(fires,i) end
 end
end

-- start a fire on a developed zone tile; schedule its first burn tick.
function ignite(x,y)
 if peekp(pl_fire,x,y)>0 then return end
 if not (is_zone(x,y) and zone_density(x,y)>0) then return end
 pokep(pl_fire,x,y,p.burn_ttl)
 add(fires,{x=x,y=y})
 if notify then notify("fire!",8,x,y) end
 if snd then snd(snd_fire) end
 schedule(p.fire_int,{k=2,x=x,y=y})
end

-- one burn tick (timewheel k=2 event). spreads, then ages toward rubble.
function fire_handler(e)
 local x,y=e.x,e.y
 local t=peekp(pl_fire,x,y)
 if t<=0 then return end  -- already out
 local cov=fire_covered(x,y)
 if cov and rnd(1)<0.6 then unfire(x,y) return end  -- crews knock it down
 local sp=cov and p.fire_cover or p.fire_spread
 for n in all(neighbors4(x,y)) do
  if rnd(1)<sp then ignite(n.x,n.y) end
 end
 t-=1
 if t<=0 then
  unfire(x,y)
  set_tile(x,y,63)  -- collapse to rubble (blocks growth until cleared)
  if notify then notify("burned to rubble",5,x,y) end
  update_net()
  schedule(p.wreck_delay,{k=3,x=x,y=y})  -- summon the wrecking crew
 else
  pokep(pl_fire,x,y,t)
  schedule(p.fire_int,{k=2,x=x,y=y})
 end
end

-- ignite a random developed zone (menu item + random-ignition source).
function start_fire()
 local c={}
 for y=0,gw-1 do
  for x=0,gw-1 do
   if is_zone(x,y) and zone_density(x,y)>0 and peekp(pl_fire,x,y)==0 then
    add(c,{x=x,y=y})
   end
  end
 end
 if #c>0 then local t=c[1+flr(rnd(#c))] ignite(t.x,t.y) end
end

function maybe_ignite()
 if rnd(1)<p.fire_chance then start_fire() end
end

-- flames over burning tiles (caller has set camera to world space).
function draw_fire()
 for f in all(fires) do
  local x,y=f.x*8,f.y*8
  rectfill(x+2,y+3,x+5,y+7,8)
  for i=0,2 do
   pset(x+2+flr(rnd(4)),y+1+flr(rnd(5)),rnd(1)<0.5 and 9 or 10)
  end
 end
end

-- a road tile orthogonally adjacent to (x,y), or nil.
local function adj_road(x,y)
 for n in all(neighbors4(x,y)) do
  if is_road(n.x,n.y) then return n end
 end
end

-- the fire station (tile 62) nearest (x,y) by manhattan distance; the station
-- doubles as the public-works depot the wrecking crew rolls out from.
local function nearest_station(x,y)
 local best,bd
 for sy=0,gw-1 do
  for sx=0,gw-1 do
   if tile(sx,sy)==62 then
    local d=abs(sx-x)+abs(sy-y)
    if not bd or d<bd then bd=d best={x=sx,y=sy} end
   end
  end
 end
 return best
end

-- k=3 event: send a wrecking crew to clear a rubble tile. it drives out from
-- the nearest station and clears the lot on arrival (the trip's on-arrive job).
function wreck_dispatch(e)
 local rx,ry=e.x,e.y
 if tile(rx,ry)~=63 then return end  -- already cleared or bulldozed
 local function clear()
  if tile(rx,ry)==63 then
   set_tile(rx,ry,1) update_net()
   if notify then notify("crew cleared rubble",11,rx,ry) end
   if fx_burst then fx_burst(rx*8+4,ry*8+4,5,6) end
   if snd then snd(snd_doze) end
  end
 end
 local st=nearest_station(rx,ry)
 if st then
  local o,w=adj_road(st.x,st.y),adj_road(rx,ry)
  if o and w and spawn_agent(o.x,o.y,w.x,w.y,4,clear) then return end
  clear()  -- depot exists but no road route: crew clears it anyway
  return
 end
 -- no depot yet: retry later (a station may get built before a bulldozer).
 schedule(p.wreck_delay*4,{k=3,x=rx,y=ry})
end
