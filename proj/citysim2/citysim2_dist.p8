pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- citysim2 : agent/market city sim, single 8k cart.
-- see DESIGN.md (contract + budget) and ../citysim/LEARNINGS.md.
-- modules are #included in dependency order; add each as it lands.
-- >>> params.lua
-- params.lua : every tuning knob lives in the global p. never shadow it.
-- keep this lean; modules add their own keys as they land.
p={
 grid=32,            -- city is grid x grid tiles (<=32 rows frees the sprite bank)

 -- event loop (sim, see DESIGN s3)
 evt_h=256,          -- timewheel horizon in ticks
 evt_cap=96,         -- events processed per tick (storm guard)
 eval_iv=45,         -- ticks between a tile re-evaluating its needs
 decay_miss=4,       -- consecutive unmet evals before a tile downgrades

 -- zone economy (capacity per density step)
 r_per=4,            -- residents per residential density
 c_per=3,            -- jobs per commercial density
 i_per=4,            -- jobs per industrial density
 grow_rate=0.45,     -- chance a fully-served zone densifies on an eval
 decay_rate=0.15,    -- chance a starved zone downgrades on an eval
 -- satisfaction battery (pl_sat, 0..255): agents top it up by fulfilling the
 -- building's purpose; it decays otherwise. growth needs it; starvation decays.
 sat_seed=200,       -- a new/just-grown building opens with this much goodwill
 sat_decay=10,       -- satisfaction lost each eval (needs go unmet over time)
 sat_grow=60,        -- min satisfaction to densify
 sat_low=24,         -- below this a building loses tenants (decays)
 sat_visit=40,       -- satisfaction an agent delivers (visit / good commute)

 -- agents / visibility (the lively-city knob, DESIGN s10)
 agent_cap=80,       -- max live visible agents
 show=1,             -- visible cars per filled capacity unit (1=all; lower=sample)
 trip_life=600,      -- ticks before a stuck agent gives up
 commute_good=6,     -- a commute this short (road tiles) delights the resident
 commute_ok=14,      -- up to here is tolerable; beyond it sours their building

 -- congestion (router cost feedback, DESIGN s10)
 cong_k=3,           -- router cost added per agent sharing a road tile
 road_reach=2,       -- a zone reaches a road within this many tiles (chebyshev)

 -- economy (money in THOUSANDS of dollars, see LEARNINGS)
 start_money=2,      -- $2k
 tax_rate=2,         -- tax points; income scales with this
 month_frames=600,   -- frames per month (20s @ 30fps)
 road_up=1,          -- $ per road tile per month (upkeep, in dollars)
 plant_up=8,         -- $ per plant per month; a big plant costs 4x this
 plant_sup=60,       -- power UNITS a plant feeds its network
 bigplant_sup=180,   -- a big plant feeds far more units
 brownout_iv=20,     -- frames between rolling-brownout rotations when over capacity
 -- per-zone draw = (density+1) * kind_draw(time)/10. kind_draw lerps day->night
 -- by day_phase: R sips most at night, C most by day, I steady (R,C,I order).
 pwr_day=split"4,11,9",   -- midday draw x10 per kind
 pwr_night=split"11,4,9", -- midnight draw x10 per kind
 pwr_cap=7,          -- a building's power battery (drains 1 per pwr_iv "hour")
 pwr_pkt=4,          -- energy packet size; grabbed only when there's room for one
 pwr_iv=30,          -- frames per power hour (battery drains/refills on this tick)
 res_dist=6,         -- a delivered packet loses 1 charge per this many tiles from
                     --   the nearest plant (line resistance; far buildings dim first)
 job_tax=0.5,        -- jobs taxed at this fraction of the pop rate
 debt_k=-1,          -- debt floor in $k (try_spend won't go below)
 money_cap=32000,    -- $k ceiling (keeps 16.16 fixed-point from flipping)
 start_year=1950,

 -- demand / census (derived rci meter, sim.lua)
 census_iv=30,       -- ticks between census + demand recompute
 dem_rdiv=32,        -- residential demand divisor
 dem_div=24,         -- commercial/industrial demand divisor
 dem_c=0.5,          -- target jobs per resident (commercial)
 dem_i=0.7,          -- target jobs per resident (industrial)
 dem_seed=16,        -- baseline external R demand (lets an empty city bootstrap)

 -- terrain (terrain.lua)
 river_w=2,          -- river width in tiles (one river, no lakes/mountains)

 -- desirability / land value (landval.lua); 128 = neutral
 val_rad=3,          -- influence radius (tiles) for water/pollution
 val_water=6,        -- desirability per nearby water tile (waterfront +)
 val_pol=10,         -- desirability lost per nearby polluter (industry/plant)
 val_cong=2,         -- desirability lost per agent on nearby roads
 val_park=24,        -- desirability per nearby park (service +)
 val_div=30,         -- drain 1/val_div of the dirty land-value queue per frame
                     --   (so the backlog always clears within ~val_div frames)

 -- fire / disasters (disaster.lua)
 fire_chance=0.0006, -- per-frame odds a random developed zone ignites
 fire_int=45,        -- frames between a fire's burn ticks
 burn_ttl=6,         -- burn ticks before a tile collapses to rubble
 fire_spread=0.45,   -- odds a burn tick spreads to a neighbour zone
 fire_rad=4,         -- fire-station coverage radius (chebyshev)
 fire_cover=0.12,    -- spread odds inside station coverage (suppressed)
 wreck_delay=120,    -- frames after rubble forms before a crew is dispatched

 -- render (render.lua)
 cong_show=2,        -- agents on a road before it reads as congested

 day_frames=1800,    -- full day/night cycle (60s @ 30fps)
}

-- build costs in DOLLARS (charged via econ.try_spend, which scales to $k)
cost={road=10,power=5,plant=150,zone=50,park=20,dozer=2,fire=60,recycle=250,bigplant=500}
-- >>> version.lua
-- version.lua : build id (short git hash), stamped by build_cart.py.
ver="eb30c1c"
-- >>> data.lua
-- data.lua : static lookup tables shared by sim + ui. packed with split()
-- so each is ~2 tokens instead of one-per-entry (see LEARNINGS).

-- resources (the things that flow over networks):
--   1 labor  2 jobs  3 goods  4 power  5 coverage
res_name=split"labor,jobs,goods,power,coverage"
-- index 6 (red) is the fire engine's colour (not a real resource, just reuses
-- the agent colour table). 1 R-green 2 C-blue 3 I-orange 4 yellow 5 pink 6 red.
res_col=split"11,12,9,10,14,8"

-- channel: 1 = travels as a VISIBLE road trip (an agent + congestion);
--          0 = resolved abstractly over its network (no car, no congestion).
-- power(4) and coverage(5) are off-road -> the implicit "reserved lanes".
res_road=split"1,1,1,0,0"

-- 0x8000 user-RAM data planes (per-tile bytes, index = x + y*p.grid).
-- one base address per plane; helpers live in map.lua. (DESIGN s7 / manual 6.7)
pl_elev=0x8000      -- elevation 0..255
pl_comp=0x8400      -- road/power network component id
pl_cap=0x8800       -- building capacity N (caps at 255)
pl_fill=0x8c00      -- capacity currently served
pl_cong=0x9000      -- agents currently on this road tile (saturates at 255)
pl_need=0x9400      -- packed need bits | offer bits
pl_val=0x9800       -- desirability 0..255 (128 neutral); land value
pl_fire=0x9c00      -- burn ticks remaining (>0 = on fire); 0 = not burning
pl_cov=0xa000       -- service coverage (>0 = a station/park serves this tile)
pl_wire=0xa400      -- power-line overlay (>0 = a wire crosses this road tile)
pl_sat=0xa800       -- per-building satisfaction battery (0..255); agents refresh it
pl_pow=0xac00       -- power-network component id per carrier tile (supply/demand)
pl_chg=0xb000       -- per-building power battery charge (0..pwr_cap)
pl_pdist=0xb400     -- power-network distance to the nearest plant (hops; 255=none)
pl_cmt=0xb800       -- last commute grade reported here (0 none/1 good/2 ok/3 long)
-- >>> notify.lua
-- notify.lua : event log — the city narrates itself ("the sim explains itself").
-- a small ring of recent notable events; sim/disaster push, hud draws a fading
-- ticker bottom-left. each entry keeps its tile so callers can flag location.
-- api: init_log, notify(msg,col,x,y), draw_log; global: log
log={}

function init_log() log={} end

-- push a notice. col defaults white; x,y optional (the tile it happened on).
function notify(msg,col,x,y)
 add(log,{m=msg,c=col or 7,x=x,y=y,t=0})
 while #log>8 do deli(log,1) end
end

-- fading ticker: newest at the bottom, dimming over ~4s, then dropped.
function draw_log()
 for i=#log,1,-1 do
  log[i].t+=1
  if log[i].t>=120 then deli(log,i) end
 end
 local n=min(#log,4)
 for i=1,n do
  local e=log[#log-i+1]
  print(e.m,2,113-(i-1)*6,e.t>90 and 5 or e.c)
 end
end
-- >>> sound.lua
-- sound.lua : sfx slot names + a muted play wrapper. the actual waveforms live
-- in the cart __sfx__ (authored in gen_gfx.py, reused from citysim1). callers
-- use snd(slot); a pause-menu item toggles sfx_mute.
-- api: snd(n); globals: snd_deny/doze/place/fire/boom, sfx_mute
snd_deny=0
snd_doze=1
snd_place=2
snd_fire=3
snd_boom=4
sfx_mute=false

function snd(n)
 if not sfx_mute then sfx(n) end
end
-- >>> map.lua
-- map.lua : grid helpers, plane accessors, camera
-- tile encoding (range checks only; no fget):
--   0 water (not buildable)   1 grass (buildable)   2 mountain (not buildable)
--   roads    16..31 = 16 + nmask(n=1 e=2 s=4 w=8)
--   powerlines 32..47 = 32 + nmask
--   residential 48..51 = 48 + density(0..3)
--   commercial  52..55 = 52 + density
--   industrial  56..59 = 56 + density

gw=p.grid  -- 32

function in_bounds(x,y)
 return x>=0 and y>=0 and x<gw and y<gw
end

function tile(x,y)
 return in_bounds(x,y) and mget(x,y) or 0
end

function set_tile(x,y,s)
 if in_bounds(x,y) then mset(x,y,s) end
end

-- tile predicates (id-range checks; no fget)
function is_road(x,y)
 local s=tile(x,y) return s>=16 and s<=31
end

function is_zone(x,y)
 local s=tile(x,y) return s>=48 and s<=59
end

function is_buildable(x,y)
 local s=tile(x,y) return s==1
end

function conducts(x,y)
 local s=tile(x,y) return (s>=32 and s<=47) or s==60 or s==65 -- lines + plants
end

-- zone helpers
function zone_kind(x,y)
 if not is_zone(x,y) then return nil end
 return flr((tile(x,y)-48)/4)+1
end

function zone_density(x,y)
 if not is_zone(x,y) then return nil end
 return (tile(x,y)-48)%4
end

function set_zone(x,y,kind,density)
 set_tile(x,y,48+(kind-1)*4+density)
end

-- orthogonal in-bounds neighbours
function neighbors4(x,y)
 local n={}
 if in_bounds(x,y-1) then add(n,{x=x,y=y-1}) end
 if in_bounds(x+1,y) then add(n,{x=x+1,y=y}) end
 if in_bounds(x,y+1) then add(n,{x=x,y=y+1}) end
 if in_bounds(x-1,y) then add(n,{x=x-1,y=y}) end
 return n
end

-- autotile bitmask: n=1 e=2 s=4 w=8 where f(x,y) is predicate
function nmask(x,y,f)
 local m=0
 if f(x,y-1) then m+=1 end
 if f(x+1,y) then m+=2 end
 if f(x,y+1) then m+=4 end
 if f(x-1,y) then m+=8 end
 return m
end

-- 0x8000 plane accessors (index = x + y*gw).
-- named peekp/pokep so they don't shadow pico-8 builtins pget/pset.
function peekp(base,x,y)
 if not in_bounds(x,y) then return 0 end
 return peek(base+x+y*gw)
end

function pokep(base,x,y,v)
 if in_bounds(x,y) then poke(base+x+y*gw,v) end
end

function pclr(base)
 memset(base,0,gw*gw)
end

-- camera (pixel-smooth ease toward cursor)
camx,camy=0,0

-- the playfield is the screen between the top HUD (7px) and bottom toolbar
-- (10px). keep the cursor inside it, and let camy dip to -7 / rise so the edge
-- rows sit just below the HUD / above the toolbar (not hidden under either).
function update_camera(snap)
 local px,py=cur.x*8,cur.y*8
 local tx,ty=camx,camy
 if px-tx<16  then tx=px-16  end
 if px-tx>104 then tx=px-104 end
 if py-ty<16  then ty=py-16  end
 if py-ty>100 then ty=py-100 end
 tx=mid(0,tx,gw*8-128)
 ty=mid(-7,ty,gw*8-118)
 if snap then
  camx,camy=tx,ty
 else
  camx+=mid(-4,tx-camx,4)
  camy+=mid(-4,ty-camy,4)
 end
end

-- init: clear tile grid to grass; zero all planes
function init_map()
 for y=0,gw-1 do
  for x=0,gw-1 do
   mset(x,y,1)
  end
 end
 pclr(pl_elev)
 pclr(pl_comp)
 pclr(pl_cap)
 pclr(pl_fill)
 pclr(pl_cong)
 pclr(pl_need)
 pclr(pl_wire)
 pclr(pl_sat)
 pclr(pl_pow)
 pclr(pl_chg)
 pclr(pl_pdist)
 pclr(pl_cmt)
 camx,camy=0,0
end
-- >>> router.lua
-- router.lua : weighted dijkstra + bfs flood
-- q entries: {x,y,d} positional

function path(x0,y0,x1,y1,pass,cost)
 if x0==x1 and y0==y1 then return {{x=x0,y=y0}} end
 local di={} local fr={}
 local k0=x0+y0*gw
 di[k0]=0 fr[k0]=-1
 local q={{x0,y0,0}} local qi=1
 while qi<=#q do
  local c=q[qi] qi+=1
  local cx,cy,cd=c[1],c[2],c[3]
  local ck=cx+cy*gw
  if cd<=di[ck] then
   if cx==x1 and cy==y1 then break end
   for _,n in pairs(neighbors4(cx,cy)) do
    local nx,ny=n.x,n.y
    if pass(nx,ny) then
     local nk=nx+ny*gw
     local nd=cd+cost(nx,ny)
     if di[nk]==nil or nd<di[nk] then
      di[nk]=nd fr[nk]=ck
      add(q,{nx,ny,nd})
     end
    end
   end
  end
 end
 if fr[x1+y1*gw]==nil then return nil end
 local rv={} local k=x1+y1*gw
 while k~=k0 do
  add(rv,{x=k%gw,y=flr(k/gw)})
  k=fr[k]
 end
 add(rv,{x=x0,y=y0})
 local r={}
 for i=#rv,1,-1 do add(r,rv[i]) end
 return r
end

-- BFS over pass-tiles. optional max caps the number of tiles visited (nearest
-- first), giving e.g. a power plant a finite capacity/reach.
function flood(x0,y0,pass,visit,max)
 if not pass(x0,y0) then return end
 local sn={[x0+y0*gw]=true}
 local q={{x0,y0}} local qi=1
 visit(x0,y0)
 local cnt=1
 while qi<=#q do
  local c=q[qi] qi+=1
  for _,n in pairs(neighbors4(c[1],c[2])) do
   local nk=n.x+n.y*gw
   if pass(n.x,n.y) and not sn[nk] then
    sn[nk]=true visit(n.x,n.y) add(q,{n.x,n.y}) cnt+=1
   end
  end
  if max and cnt>=max then break end
 end
end
-- >>> net.lua
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

-- tiles that carry power: wires/plant (conducts), any zone, the built service
-- depots (fire station 62, recycling/waste 64 — NOT parks), and a wire overlay
-- crossing a road or water (pl_wire).
function power_carries(x,y)
 local s=tile(x,y)
 return conducts(x,y) or is_zone(x,y) or s==62 or s==64 or peekp(pl_wire,x,y)>0
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
-- >>> landval.lua
-- landval.lua : desirability / land value field (pl_val, 0..255, 128 neutral).
-- sim weights zone growth/decay by desir() so the waterfront booms and the
-- factory's edge rots. the per-tile box scan is too heavy to redo wholesale, so
-- recompute is a DIRTY QUEUE: a tile is only re-evaluated when something that
-- feeds it changes (a build, a fire, an agent's congestion). step_val drains a
-- slice of the queue each frame (1/val_div), so a static map costs ~nothing and
-- no dirty tile waits longer than ~val_div frames. update_val does a full sweep
-- for seed/tests.
-- api: update_val, step_val, val_dirty, val_dirty_area, desir

-- desirability at one tile: 128 + waterfront/park bonuses - pollution/congestion.
local function val_at(x,y)
 local rad=p.val_rad
 local v=128
 for dy=-rad,rad do
  for dx=-rad,rad do
   local nx,ny=x+dx,y+dy
   if in_bounds(nx,ny) then
    local t=tile(nx,ny)
    if t==0 then v+=p.val_water
    elseif t==61 then v+=p.val_park
    elseif (t>=56 and t<=59) or t==60 then v-=p.val_pol end
    if is_road(nx,ny) then v-=p.val_cong*peekp(pl_cong,nx,ny) end
   end
  end
 end
 return flr(mid(0,v,255))
end

-- dirty queue: list of tile indices + a dedup set so a tile is queued once.
vq={}
local vqd={}

function val_dirty(x,y)
 if in_bounds(x,y) then
  local i=x+y*gw
  if not vqd[i] then vqd[i]=true add(vq,i) end
 end
end

-- a change at (x,y) feeds the land value of every tile whose box reaches it
-- (within val_rad) — queue that neighbourhood.
function val_dirty_area(x,y)
 local rad=p.val_rad
 for ty=y-rad,y+rad do
  for tx=x-rad,x+rad do
   val_dirty(tx,ty)
  end
 end
end

-- drain a slice of the queue: enough that the whole backlog clears in ~val_div
-- frames regardless of its size (so latency stays ~1s, cost scales with churn).
function step_val()
 for _=1,ceil(#vq/p.val_div) do
  local i=vq[#vq] deli(vq,#vq)
  vqd[i]=nil
  pokep(pl_val,i%gw,flr(i/gw),val_at(i%gw,flr(i/gw)))
 end
end

-- full sweep (seed + tests): recompute everything and empty the queue.
function update_val()
 for y=0,gw-1 do
  for x=0,gw-1 do
   pokep(pl_val,x,y,val_at(x,y))
  end
 end
 vq={} vqd={}
end

function desir(x,y)
 return peekp(pl_val,x,y)
end
-- >>> coverage.lua
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
-- >>> terrain.lua
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
-- >>> agents.lua
-- agents.lua : pooled visible trips that realise sim contracts
-- api: agents, init_agents(), spawn_agent(x0,y0,x1,y1,res), update_agents(), draw_agents()
-- calls: path (router), is_road (map), peekp/pokep/gw (map), pl_cong (data), res_col (data), p (params)

agents={}

function init_agents()
 agents={}
end

-- optional `job`: a closure run once the agent reaches its destination (service
-- vehicles). commuters instead carry ox/oy/dx/dy (set by the caller) and report
-- satisfaction on arrival. returns the agent (so the caller can tag it), or nil.
function spawn_agent(x0,y0,x1,y1,res,job)
 if #agents>=p.agent_cap then return end
 local pa=path(x0,y0,x1,y1,
  is_road,
  function(x,y) return 1+p.cong_k*peekp(pl_cong,x,y) end)
 if pa and #pa>1 then
  -- enter first tile
  pokep(pl_cong,x0,y0,min(255,peekp(pl_cong,x0,y0)+1))
  local a={
   path=pa, i=2,
   px=x0*8+4, py=y0*8+4,
   tx=x0, ty=y0,
   res=res, col=res_col[res],
   life=p.trip_life, job=job
  }
  add(agents,a)
  return a
 end
end

-- nudge a building's satisfaction battery (clamped to a byte).
function sat_add(x,y,dv)
 pokep(pl_sat,x,y,mid(0,peekp(pl_sat,x,y)+dv,255))
end

-- a commuter reached its destination: the destination got a visit/customer/
-- delivery, and the origin home hears how the commute went (good/ok/too long).
function ag_report(a)
 if a.dx then sat_add(a.dx,a.dy,p.sat_visit) end
 if a.ox then
  local t=#a.path
  if t<=p.commute_good then pokep(pl_cmt,a.ox,a.oy,1) sat_add(a.ox,a.oy,p.sat_visit)
  elseif t<=p.commute_ok then pokep(pl_cmt,a.ox,a.oy,2)
  else pokep(pl_cmt,a.ox,a.oy,3) sat_add(a.ox,a.oy,-p.sat_visit) end
 end
end

local function ag_remove(a)
 pokep(pl_cong,a.tx,a.ty,max(0,peekp(pl_cong,a.tx,a.ty)-1))
end

function update_agents()
 local keep={}
 for _,a in pairs(agents) do
  a.life-=1
  -- a road on the trip was bulldozed? the path is broken -> abandon the trip
  -- (no arrival, so no satisfaction report). otherwise it'd drive over grass.
  local alive=a.life>0 and a.i<=#a.path
   and is_road(a.tx,a.ty) and is_road(a.path[a.i].x,a.path[a.i].y)
  if alive then
   -- move 1px toward centre of current target node
   local n=a.path[a.i]
   local tnx=n.x*8+4
   local tny=n.y*8+4
   local dx=tnx-a.px
   local dy=tny-a.py
   -- move one axis at a time; remember heading so we can draw in the right lane
   if dx~=0 then
    a.px+=sgn(dx) a.hx=sgn(dx) a.hy=0
   elseif dy~=0 then
    a.py+=sgn(dy) a.hx=0 a.hy=sgn(dy)
   end
   -- crossed into a new tile?
   local ntx=flr(a.px/8)
   local nty=flr(a.py/8)
   if ntx~=a.tx or nty~=a.ty then
    pokep(pl_cong,a.tx,a.ty,max(0,peekp(pl_cong,a.tx,a.ty)-1))
    pokep(pl_cong,ntx,nty,min(255,peekp(pl_cong,ntx,nty)+1))
    -- congestion just changed here -> land value nearby is stale; queue it.
    if val_dirty_area then val_dirty_area(ntx,nty) end
    a.tx=ntx
    a.ty=nty
   end
   -- reached this node's centre?
   if a.px==tnx and a.py==tny then
    a.i+=1
   end
   if a.i>#a.path then
    -- arrived. a job-carrying vehicle (crew/engine) is done; a commuter turns
    -- around and heads home, so trips are visible round-trips, not one-way.
    if a.job or a.ret then
     alive=false
    else
     ag_report(a)  -- tell home + destination how this trip went
     a.ret=true
     local r={}
     for j=#a.path,1,-1 do add(r,a.path[j]) end
     a.path=r a.i=2
    end
   end
  end
  if alive then
   add(keep,a)
  else
   ag_remove(a)
   if a.job and a.i>#a.path then a.job() end
  end
 end
 agents=keep
end

function draw_agents()
 for _,a in pairs(agents) do
  -- offset to the RIGHT of travel (perp = rotate heading 90deg cw) so opposing
  -- traffic uses opposite lanes instead of overlapping on the centre line
  local px=a.px-(a.hy or 0)*2
  local py=a.py+(a.hx or 0)*2
  pset(px,py,a.col)
  pset(px+1,py,a.col)
  pset(px,py+1,a.col)
  pset(px+1,py+1,a.col)
 end
end
-- >>> sim.lua
-- sim.lua : event-driven rci core (timewheel + grow/decay + commuters)
-- api: init_sim, sim_seed, update_sim, schedule, tile_info, sm_index
--      globals: evq, tick, pop, jobs, demand, idx
-- calls: is_zone, zone_kind, zone_density, set_zone, neighbors4, is_road,
--        rcomp, connected, spawn_agent, p, gw
-- private prefix: sm_

evq={}
tick=0
pop=0
jobs=0
demand={r=0,c=0,i=0}
idx={}  -- offer index: idx[comp][kind] = list of {x,y} developed zone tiles

function init_sim()
 evq={}
 for i=1,p.evt_h do add(evq,{}) end
 tick=0 pop=0 jobs=0
 demand={r=0,c=0,i=0}
 idx={}
end

function schedule(dt,ev)
 add(evq[(tick+dt)%p.evt_h+1],ev)
end

-- rebuild the per-road-component offer index from zones. ALL zones count, even
-- empty (density 0) ones: a zoned-but-unbuilt plot is a promise of jobs/homes,
-- so a fresh R next to a fresh C can bootstrap each other (otherwise nothing
-- ever has a developed complement and the whole city deadlocks at density 0).
function sm_index()
 idx={}
 for y=0,gw-1 do
  for x=0,gw-1 do
   if is_zone(x,y) then
    local c=rcomp(x,y)
    if c~=0 then
     idx[c]=idx[c] or {}
     local k=zone_kind(x,y)
     idx[c][k]=idx[c][k] or {}
     add(idx[c][k],{x=x,y=y})
    end
   end
  end
 end
end

function sim_seed()
 for y=0,gw-1 do
  for x=0,gw-1 do
   if is_zone(x,y) then
    schedule((x+y)%p.eval_iv,{k=1,x=x,y=y})
    pokep(pl_sat,x,y,p.sat_seed)  -- existing/loaded buildings start with goodwill
   end
  end
 end
 sm_index()
 update_val()
 if update_cov then update_cov() end
end

local function sm_adj_road(x,y)
 local rx,ry=near_road(x,y)
 if rx then return {x=rx,y=ry} end
end

-- who each kind wants: R->jobs(C/I); C->customers(R)+goods(I); I->workers(R)+buyers(C)
local sm_wants={[1]={2,3},[2]={1,3},[3]={1,2}}

-- a reachable developed complement of tile (x,y); returns wx,wy or nil
local function sm_complement(x,y,k)
 local c=rcomp(x,y)
 if c==0 or not idx[c] then return end
 for _,wk in pairs(sm_wants[k]) do
  local l=idx[c][wk]
  if l and #l>0 then
   local t=l[1+flr(rnd(#l))]
   return t.x,t.y
  end
 end
end

local function sm_eval(x,y)
 if not is_zone(x,y) then return end
 local k=zone_kind(x,y)
 local d=zone_density(x,y)
 local access=rcomp(x,y)~=0
 local wx,wy=sm_complement(x,y,k)
 local found=wx~=nil
 -- a built building runs on its battery; an empty plot just needs the grid to
 -- reach it (served) before a building (with a battery) appears there.
 local pw=d>0 and powered(x,y) or served(x,y)
 local dv=desir(x,y)  -- 0..255, 128 neutral: weights grow up / decay down
 -- demand for this kind (-1..1): the rci meter actually drives the city.
 local dmd=k==1 and demand.r or k==2 and demand.c or demand.i
 -- service gate: growing TALL (density >=2) needs station/park coverage.
 local svc=(not serviced) or d<1 or serviced(x,y)
 -- satisfaction battery: decays each eval; AGENTS refill it (a good commute home,
 -- a visitor to a shop, freight to a factory). high sat grows; starved decays.
 local sat=max(0,peekp(pl_sat,x,y)-p.sat_decay)
 pokep(pl_sat,x,y,sat)
 if access and found and pw and dmd>0 and svc and sat>=p.sat_grow and d<3 and rnd(1)<p.grow_rate*dv/128 then
  set_zone(x,y,k,d+1)
  pokep(pl_sat,x,y,p.sat_seed)   -- a fresh storey opens with goodwill
  pokep(pl_chg,x,y,p.pwr_cap)    -- ...and its lights come on (battery charged)
  if d+1==3 and notify then notify("district booming",res_col[k],x,y) end
 elseif (not access or not found or not pw or dmd<-0.5 or sat<p.sat_low or (d>=2 and not svc)) and d>0
  and rnd(1)<p.decay_rate*(256-dv)/128 then
  set_zone(x,y,k,d-1)
  if d-1==0 and notify then notify("zone abandoned",5,x,y) end
 end
 -- visible commuter (per p.show, throttled by time-of-day traffic)
 local tf=traffic_factor and traffic_factor() or 1
 if found and d>0 and rnd(1)<p.show*tf then
  local o=sm_adj_road(x,y)
  local w=sm_adj_road(wx,wy)
  if o and w then
   -- colour by ORIGIN zone (R green / C blue / I orange). tag the trip with its
   -- home + destination so on arrival it reports satisfaction to both buildings.
   local a=spawn_agent(o.x,o.y,w.x,w.y,k)
   if a then a.ox=x a.oy=y a.dx=wx a.dy=wy end
  end
 end
 schedule(p.eval_iv,{k=1,x=x,y=y})
end

local sm_cd=0
local sm_id=flr(p.census_iv/2)  -- offset from census so the two don't co-spike
local function sm_census()
 local r,cj,ij=0,0,0
 for y=0,gw-1 do
  for x=0,gw-1 do
   if is_zone(x,y) then
    local k=zone_kind(x,y)
    local d=zone_density(x,y)
    if k==1 then r+=d*p.r_per
    elseif k==2 then cj+=d*p.c_per
    else ij+=d*p.i_per end
   end
  end
 end
 pop=r jobs=cj+ij
 demand.r=mid(-1,(jobs+p.dem_seed-pop)/p.dem_rdiv,1)
 demand.c=mid(-1,(pop*p.dem_c-cj)/p.dem_div,1)
 demand.i=mid(-1,(pop*p.dem_i-ij)/p.dem_div,1)
end

function update_sim()
 tick+=1
 local bi=tick%p.evt_h+1
 local b=evq[bi]
 local n=min(#b,p.evt_cap)
 for i=1,n do
  if b[i].k==1 then sm_eval(b[i].x,b[i].y)
  elseif ev_hook then ev_hook(b[i]) end
 end
 evq[bi]={}
 -- amortized maintenance: land value refreshes a couple rows EVERY frame (no
 -- per-second spike); census + offer index run periodically but on separate
 -- frames so their scans never stack. coverage is event-driven (tools.lua).
 step_val()
 if tick%p.pwr_iv==0 then pwr_tick() end  -- battery drain/refill each power hour
 sm_cd-=1
 if sm_cd<=0 then sm_cd=p.census_iv sm_census() end
 sm_id-=1
 if sm_id<=0 then sm_id=p.census_iv sm_index() end
end

function tile_info(x,y)
 if not is_zone(x,y) then return nil end
 local k=zone_kind(x,y)
 local wx,wy=sm_complement(x,y,k)
 local dn=zone_density(x,y)
 return {kind=k,dens=dn,access=rcomp(x,y)~=0,
  power=dn>0 and powered(x,y) or served(x,y),served=wx~=nil,val=desir(x,y),
  svc=(not serviced) or serviced(x,y),unhappy=peekp(pl_sat,x,y)<p.sat_low,
  commute=peekp(pl_cmt,x,y)}
end
-- >>> disaster.lua
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
 fire_engine(x,y)  -- the fire department responds (if a station can reach it)
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
  if val_dirty_area then val_dirty_area(x,y) end
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

-- the station of type `id` nearest (x,y) by manhattan distance — the depot a
-- vehicle rolls out from (62 fire station for engines, 64 recycling for crews).
local function nearest_station(x,y,id)
 local best,bd
 for sy=0,gw-1 do
  for sx=0,gw-1 do
   if tile(sx,sy)==id then
    local d=abs(sx-x)+abs(sy-y)
    if not bd or d<bd then bd=d best={x=sx,y=sy} end
   end
  end
 end
 return best
end

-- dispatch a responder: roll a vehicle (res colour) out of the nearest depot of
-- type `id` to (tx,ty), running `job` on arrival. one shared path for every
-- emergency service. returns true if a vehicle was actually sent.
local function dispatch(id,tx,ty,res,job)
 local st=nearest_station(tx,ty,id)
 if not st then return end
 local o,w=adj_road(st.x,st.y),adj_road(tx,ty)
 return o and w and spawn_agent(o.x,o.y,w.x,w.y,res,job)
end

-- k=3 event: a wrecking crew clears a rubble tile (on arrival from the depot).
function wreck_dispatch(e)
 local rx,ry=e.x,e.y
 if tile(rx,ry)~=63 then return end  -- already cleared or bulldozed
 local function clear()
  if tile(rx,ry)==63 then
   set_tile(rx,ry,1) update_net()
   if val_dirty_area then val_dirty_area(rx,ry) end
   if notify then notify("crew cleared rubble",11,rx,ry) end
   if fx_burst then fx_burst(rx*8+4,ry*8+4,5,6) end
   if snd then snd(snd_doze) end
  end
 end
 if dispatch(64,rx,ry,4,clear) then return end
 if nearest_station(rx,ry,64) then clear()  -- depot exists but no route: clear anyway
 else schedule(p.wreck_delay*4,{k=3,x=rx,y=ry}) end  -- no depot: retry later
end

-- a red fire engine from the nearest fire station puts a fresh fire out on
-- arrival, saving the building from collapsing to rubble.
function fire_engine(x,y)
 dispatch(62,x,y,6,function()
  if peekp(pl_fire,x,y)>0 then
   unfire(x,y)
   if notify then notify("fire out",12,x,y) end
   if fx_burst then fx_burst(x*8+4,y*8+4,7,6) end
  end
 end)
end
-- >>> tools.lua
-- tools.lua : cursor + a 2D, data-driven tool palette + placement.
-- palette is COLUMNS (left/right = category) of TOOLS (up/down = type). press O
-- to enter pick-mode (dpad drives the palette), O/X to leave. adding a building
-- is one data row. each tool is a POSITIONAL array (keys cost tokens):
--   [1]=name [2]=icon-sprite [3]=cost-key [4]=place-code [5]=arg
--   place-code: z zone(arg=kind) · r road · w power · b building(arg=tile) · d doze
-- api: init_tools, update_tools, apply_tool, cur_tool, select_tool, draw_*,
--      globals: cur, tcat, trow, picking
cats={
 {{"road",16,"road","r"}},                                         -- roads
 {{"r-zone",48,"zone","z",1},{"c-zone",52,"zone","z",2},{"i-zone",56,"zone","z",3}}, -- zones
 {{"power",42,"power","w"},{"plant",60,"plant","b",60},{"big plant",65,"bigplant","b",65}}, -- power
 {{"park",61,"park","b",61},{"fire",62,"fire","b",62},{"recycle",64,"recycle","b",64}}, -- services
 {{"bulldoze",-1,"dozer","d"}},                                    -- bulldozer
}
tcat=1
trow={}  -- selected row per category; filled by init_tools (one per #cats)
picking=false
local tb_lx,tb_ly=-1,-1  -- last tile painted (drag-build)
for i=1,#cats do trow[i]=1 end

function cur_tool() return cats[tcat][trow[tcat]] end

-- focus a tool by name (used by tests + any hotkey)
function select_tool(name)
 for ci=1,#cats do
  for ri=1,#cats[ci] do
   if cats[ci][ri][1]==name then tcat=ci trow[ci]=ri return end
  end
 end
end

function init_tools()
 cur={x=16,y=16}
 tcat=1 picking=false
 for i=1,#cats do trow[i]=1 end
end

function update_tools()
 if picking then
  -- dpad drives the palette: left/right category, up/down type
  if btnp(0) then tcat=max(1,tcat-1) end
  if btnp(1) then tcat=min(#cats,tcat+1) end
  -- up moves UP the fan (toward higher rows, which draw higher on screen)
  if btnp(2) then trow[tcat]=min(#cats[tcat],trow[tcat]+1) end
  if btnp(3) then trow[tcat]=max(1,trow[tcat]-1) end
  if btnp(4) or btnp(5) then picking=false end
 else
  if btnp(0) then cur.x=max(0,cur.x-1) end
  if btnp(1) then cur.x=min(gw-1,cur.x+1) end
  if btnp(2) then cur.y=max(0,cur.y-1) end
  if btnp(3) then cur.y=min(gw-1,cur.y+1) end
  if btnp(4) then picking=true end
  -- apply on press; hold + move to drag-build/bulldoze a line
  if btnp(5) then
   apply_tool() tb_lx,tb_ly=cur.x,cur.y
  elseif btn(5) and (cur.x~=tb_lx or cur.y~=tb_ly) then
   apply_tool() tb_lx,tb_ly=cur.x,cur.y
  end
  update_camera()
 end
end

function apply_tool()
 local x,y=cur.x,cur.y
 local before=tile(x,y)
 local t=cur_tool()
 local pc=t[4]
 if pc=="d" then
  if peekp(pl_wire,x,y)>0 then            -- peel a wire overlay first
   if try_spend(cost.dozer) then pokep(pl_wire,x,y,0) update_net() end
  elseif is_zone(x,y) and zone_density(x,y)>0 then
   -- raze the BUILDING but keep the zoning (v1 lesson); it can rebuild
   if try_spend(cost.dozer) then
    set_zone(x,y,zone_kind(x,y),0) pokep(pl_sat,x,y,p.sat_seed) update_net()
   end
  elseif tile(x,y)>1 and try_spend(cost.dozer) then
   set_tile(x,y,1)                     -- empty zone / road / building -> grass
   -- re-autotile neighbouring roads / power lines so a removed junction resets
   -- (an L-corner left after dozing the rest of a box collapses to a stub).
   for nb in all(neighbors4(x,y)) do
    if is_road(nb.x,nb.y) then set_tile(nb.x,nb.y,16+nmask(nb.x,nb.y,is_road))
    elseif tile(nb.x,nb.y)>=32 and tile(nb.x,nb.y)<=47 then
     set_tile(nb.x,nb.y,32+nmask(nb.x,nb.y,conducts)) end
   end
   update_net()
  end
 elseif pc=="b" then                       -- a building on grass
  if is_buildable(x,y) and try_spend(cost[t[3]]) then
   set_tile(x,y,t[5]) update_net()
  end
 elseif pc=="z" then                       -- a zone plot (settling grace)
  if is_buildable(x,y) and try_spend(cost.zone) then
   set_zone(x,y,t[5],0) pokep(pl_sat,x,y,p.sat_seed)
   update_net() schedule(0,{k=1,x=x,y=y})
  end
 elseif pc=="r" then                       -- road (bridges water)
  if (is_buildable(x,y) or tile(x,y)==0) and try_spend(cost.road) then
   set_tile(x,y,16+nmask(x,y,is_road))
   for nb in all(neighbors4(x,y)) do
    if is_road(nb.x,nb.y) then set_tile(nb.x,nb.y,16+nmask(nb.x,nb.y,is_road)) end
   end
   update_net()
  end
 elseif pc=="w" then                       -- power: wire over road/water else line
  if is_road(x,y) or tile(x,y)==0 then
   if peekp(pl_wire,x,y)==0 and try_spend(cost.power) then pokep(pl_wire,x,y,1) update_net() end
  elseif is_buildable(x,y) and try_spend(cost.power) then
   set_tile(x,y,32+nmask(x,y,conducts))
   for nb in all(neighbors4(x,y)) do
    if tile(nb.x,nb.y)>=32 and tile(nb.x,nb.y)<=47 then
     set_tile(nb.x,nb.y,32+nmask(nb.x,nb.y,conducts))
    end
   end
   update_net()
  end
 end
 -- dust + sound on a real change; deny blip otherwise
 local now=tile(x,y)
 if now~=before then
  if fx_burst then fx_burst(x*8+4,y*8+4,before>1 and 5 or 6,5) end
  if snd then snd(before>1 and snd_doze or snd_place) end
  if val_dirty_area then val_dirty_area(x,y) end
  if update_cov and (before==61 or before==62 or now==61 or now==62) then update_cov() end
 elseif snd and pc~="d" then
  snd(snd_deny)
 end
end

function draw_cursor()
 local x,y=cur.x*8,cur.y*8
 rect(x,y,x+7,y+7,7)
end

local function tb_icon(i,x,y)
 if i>=0 then spr(i,x,y)
 else line(x+1,y+1,x+6,y+6,8) line(x+6,y+1,x+1,y+6,8) end -- bulldoze X
end

-- bottom palette: one slot per category showing its current tool; the active
-- category is boxed and, while picking, its types fan upward (up/down to choose).
function draw_toolbar()
 rectfill(0,118,127,127,0)
 for ci=1,#cats do
  local x=1+(ci-1)*9
  tb_icon(cats[ci][trow[ci]][2],x,119)
  -- chevron hint: this category has more types stacked (up/down to reveal)
  if #cats[ci]>1 then pset(x+3,117,7) pset(x+2,118,7) pset(x+4,118,7) end
  if ci==tcat then rect(x-1,118,x+8,127,7) end
 end
 if picking then
  local x=1+(tcat-1)*9
  for ri=1,#cats[tcat] do
   local y=118-ri*9
   rectfill(x-1,y-1,x+8,y+8,0)
   tb_icon(cats[tcat][ri][2],x,y)
   if ri==trow[tcat] then rect(x-1,y-1,x+8,y+8,7) end
  end
 end
 local t=cur_tool()
 local lbl=t[1]..(cost[t[3]] and " $"..cost[t[3]] or "")
 print(lbl,min(1+#cats*9+2,128-#lbl*4),121,10)
end
-- >>> render.lua
-- render.lua : world drawing. HEADER — draw_world is a STUB for an agent.
-- api: draw_world
-- NOTE sprite id == tile id, so map() renders the tile grid directly.
-- contract (flesh this out):
--   camera(camx,camy)
--   map(0,0,0,0,gw,gw)            -- the tiles (sprites match ids)
--   -- light overlays: e.g. faint congestion on busy roads from
--   --   peekp(pl_cong,x,y) over the visible window, animated water sparkle;
--   --   keep it cheap and don't fight the sprite art.
--   draw_agents()                 -- the moving commuters (agents.lua)
--   draw_cursor()                 -- the cursor outline (tools.lua)
--   camera()                      -- reset so the glue draws hud in screen space
-- congestion is shown on the minimap (minimap.lua), not as a world overlay.
-- the water surface is the cls() colour (see glue _draw); here we just add an
-- animated glint over the visible water tiles.
function draw_water()
 local t=flr((tick or 0)/8)
 local x0,y0=flr(camx/8),flr(camy/8)
 for ty=y0,y0+16 do
  for tx=x0,x0+16 do
   if tile(tx,ty)==0 and (tx*3+ty*7+t)%4==0 then
    pset(tx*8+(tx+t)%6+1,ty*8+(ty*3)%6+1,7)
   end
  end
 end
end

-- flashing lightning bolt over zones that lack power (the v1 "no power" cue).
function draw_alerts()
 if tick%16>=8 then return end           -- blink
 local x0,y0=flr(camx/8),flr(camy/8)
 for ty=y0,y0+16 do
  for tx=x0,x0+16 do
   if is_zone(tx,ty) and zone_density(tx,ty)>0 and not powered(tx,ty) then
    local sx,sy=tx*8,ty*8
    line(sx+4,sy+1,sx+2,sy+4,10)
    line(sx+2,sy+4,sx+5,sy+4,10)
    line(sx+5,sy+4,sx+3,sy+7,10)
   end
  end
 end
end

-- power-line overlay where a wire crosses a road/water (pl_wire); drawn along
-- the axis it actually connects (a vertical run draws vertical, not horizontal).
function draw_wires()
 local x0,y0=flr(camx/8),flr(camy/8)
 for ty=y0,y0+16 do
  for tx=x0,x0+16 do
   if peekp(pl_wire,tx,ty)>0 then
    local sx,sy=tx*8,ty*8
    local v=conducts(tx,ty-1) or peekp(pl_wire,tx,ty-1)>0 or conducts(tx,ty+1) or peekp(pl_wire,tx,ty+1)>0
    local h=conducts(tx-1,ty) or peekp(pl_wire,tx-1,ty)>0 or conducts(tx+1,ty) or peekp(pl_wire,tx+1,ty)>0
    if v then line(sx+3,sy,sx+3,sy+7,0) end
    if h then line(sx,sy+3,sx+7,sy+3,0) end
    if not (v or h) then line(sx,sy+3,sx+7,sy+3,0) end
   end
  end
 end
end

function draw_world()
 camera(camx,camy)
 night_pal()              -- dusk/night colour remap (no-op at midday)
 map(0,0,0,0,gw,gw)
 draw_agents()
 pal()                    -- reset so fire/cursor draw at full brightness
 draw_water()             -- water glints (bright, after the night remap)
 draw_wires()             -- wires crossing roads
 draw_fire()
 draw_alerts()            -- no-power lightning bolts
 draw_cursor()
 camera()
end
-- >>> inspector.lua
-- inspector.lua : the sim explains itself. HEADER — draw_inspector is a STUB.
-- api: draw_inspector
-- shows tile_info(cur.x,cur.y) for the tile under the cursor.
-- contract (flesh this out):
--   local ti=tile_info(cur.x,cur.y)   -- nil if not a zone (then draw nothing)
--   ti = {kind=1/2/3, dens=0..3, access=bool, served=bool}
--   draw a small panel in SCREEN space (camera already reset by draw_world):
--     - rectfill an OPAQUE background first, then a rect border  <-- citysim bug
--       was a panel with no bg; always back panels.
--     - line 1: kind label ("res"/"com"/"ind") + " lv"..dens
--     - line 2: status — "no road" if not access, else "starved" if not served,
--       else "thriving" (served).
--   keep it a few lines, tucked in a corner; readable over the map.
local ins_kinds={"res","com","ind"}
local ins_cols={11,12,10}
-- a factor light: green when healthy, red when it's the thing to fix.
local function f(l,fx,fy,ok)
 print(l,fx,fy,ok and 11 or 8)
end
-- inspector = a tiny diagnostic panel. each factor that feeds a building's
-- health shows green (ok) / red (problem), so "why is it unhappy?" is readable
-- at a glance: road access, power, service coverage, a reachable market (jobs/
-- customers/buyers), commute length, and land-value desirability.
function draw_inspector()
 local ti=tile_info(cur.x,cur.y)
 if not ti then return end
 local x,y=1,8
 rectfill(x,y,x+52,y+23,0)
 rect(x,y,x+52,y+23,5)
 print(ins_kinds[ti.kind].." "..ti.dens,x+2,y+2,ins_cols[ti.kind])
 f("rd",x+2,y+9,ti.access)
 f("pwr",x+20,y+9,ti.power)
 f("svc",x+38,y+9,ti.svc)
 f("job",x+2,y+16,ti.served)
 f("cmt",x+20,y+16,ti.commute~=3)   -- red only when a long commute was reported
 f("des",x+38,y+16,ti.val>=124)
end
-- >>> econ.lua
-- econ.lua : money ($k), tax, time. HEADER — bodies are STUBS for an agent.
-- api: init_econ, update_econ, try_spend, mfmt; globals money, tax_rate, month, year
-- calls: pop, jobs (sim census), p
-- money is stored in THOUSANDS of dollars (16.16 fixed-point flips past 32767),
-- so costs/income are in dollars and scaled /1000 here (see ../citysim/LEARNINGS).

money=2
tax_rate=2
month=1
year=p.start_year
ec_f=0

function init_econ()
 money=p.start_money
 tax_rate=p.tax_rate
 month=1 year=p.start_year
 ec_f=0
end

-- format a $k value: <$1k -> "$NNN", then "$N.Nk", then "$N.Nm". signed.
function mfmt(v)
 local s=v<0 and "-$" or "$"
 local a=abs(v)
 if a<1 then return s..flr(a*1000+0.5) end
 local u="k"
 if a>=1000 then a=a/1000 u="m" end
 local w=flr(a)
 local f=flr((a-w)*10)
 return s..w..(f>0 and "."..f or "")..u
end

-- spend n DOLLARS; allow down to -$1k debt; return true if allowed.
function try_spend(n)
 local d=n/1000
 if money-d>=p.debt_k then money-=d return true end
 return false
end

-- advance time + apply monthly income/upkeep. call every frame from the glue.
function update_econ()
 ec_f+=1
 if ec_f<p.month_frames then return end
 ec_f=0
 month=month%12+1
 if month==1 then year+=1 end
 local income=pop*tax_rate+flr(jobs*tax_rate*p.job_tax)
 local upkeep=0
 for y=0,gw-1 do
  for x=0,gw-1 do
   local s=tile(x,y)
   if is_road(x,y) then upkeep+=p.road_up
   elseif s==60 then upkeep+=p.plant_up
   elseif s==65 then upkeep+=p.plant_up*4 end  -- big plant: high maintenance
  end
 end
 money=min(p.money_cap,money+(income-upkeep)/1000)
end
-- >>> hud.lua
-- hud.lua : top status bar + RCI demand bars.
-- api: draw_hud
-- calls: money/mfmt/month/year (econ), pop/jobs/demand (sim)
-- runs in SCREEN space (called after draw_world reset the camera).
local mon=split"jan,feb,mar,apr,may,jun,jul,aug,sep,oct,nov,dec"
local hd_lbl=split"r,c,i"
local hd_col=split"11,12,10"
local hd_dim=split"3,13,4"

function draw_hud()
 rectfill(0,0,127,6,0)
 -- money
 print(mfmt(money),0,1,money<0 and 8 or 11)
 -- pop (jobs moved to the minimap detail view to free space)
 print("p"..pop,32,1,14)
 -- date
 print(mon[month].." "..year,58,1,7)
 -- rci demand bars (x=104..126, midline y=4)
 local bx=104
 local hd_dv={demand.r,demand.c,demand.i}
 rectfill(bx,4,bx+22,4,5)
 for i=1,3 do
  local lx=bx+(i-1)*8
  print(hd_lbl[i],lx,1,hd_col[i])
  -- bar at lx+4 (1px gap after the 3px letter, for readability)
  local h=mid(-3,flr(hd_dv[i]*3+0.5),3)
  if h>0 then
   rectfill(lx+4,4-h,lx+5,4,hd_col[i])
  elseif h<0 then
   rectfill(lx+4,4,lx+5,4-h,hd_dim[i])
  end
 end
end
-- >>> minimap.lua
-- minimap.lua : whole-city overview. HEADER — draw_minimap is a STUB.
-- api: draw_minimap
-- calls: tile/zone_kind/zone_density/is_road (map), gw, p
-- the player toggles a map mode (glue owns the toggle + calling this); runs in
-- SCREEN space. ALWAYS back the panel with an opaque rect (citysim's overview
-- had no bg and was unreadable).

local mm_ox,mm_oy=16,13  -- nudged up so the detail line clears the toolbar

-- developed zones show their kind colour (R green / C blue / I yellow);
-- empty (density 0) zones show grey so zoned-but-unbuilt land is still visible
-- (an empty R plot used to draw grass-green and vanished on the map).
local mm_zb={11,12,10}
local mm_empty=6

function draw_minimap()
 rectfill(mm_ox-1,mm_oy-1,mm_ox+96,mm_oy+96,0)
 rect(mm_ox-1,mm_oy-1,mm_ox+96,mm_oy+96,5)
 for y=0,gw-1 do
  for x=0,gw-1 do
   local t=tile(x,y)
   local c
   if t==0 then
    c=12
   elseif t==2 then
    c=13
   elseif is_road(x,y) then
    c=peekp(pl_cong,x,y)>p.cong_show and 8 or 5 -- busy roads glow red
   else
    local k=zone_kind(x,y)
    if k then
     c=(zone_density(x,y)>0) and mm_zb[k] or mm_empty
    else
     c=3
    end
   end
   rectfill(mm_ox+x*3,mm_oy+y*3,mm_ox+x*3+2,mm_oy+y*3+2,c)
  end
 end
 rect(mm_ox+flr(camx/8)*3,mm_oy+flr(camy/8)*3,
      mm_ox+flr(camx/8)*3+16*3,mm_oy+flr(camy/8)*3+15*3,7)
 -- detail line: pop / jobs (moved off the top bar) + build version (git hash)
 print("pop"..pop.." job"..jobs,mm_ox,mm_oy+98,7)
 print("v"..ver,mm_ox+72,mm_oy+98,6)
end
-- >>> daynight.lua
-- daynight.lua : day/night cycle via a draw-palette remap (pal), NOT a dither
-- overlay — PICO-8's fill transparency doesn't darken the map, but pal() does
-- (citysim1 lesson). night_pal() darkens every colour to a moodier one while
-- leaving lit-window white (7) bright, so the night city glows. render.lua
-- wraps the map/agents draw in night_pal()..pal().
-- api: day_phase, night_pal; reads sim `tick`, period p.day_frames.

-- 0=noon (brightest) .. 1=midnight (darkest). starts at noon (tick 0).
function day_phase()
 return (1-cos((tick or 0)/p.day_frames))/2
end

-- night LUT: dims structures a notch but KEEPS water blue (12), grass green (3),
-- and the lit windows/lamps (7,10) glowing, so the map stays readable after dark.
local night_lut=split"1,2,3,2,5,5,7,8,4,10,3,12,1,2,4"

-- traffic ebbs at night: ~1 at midday down to ~0.3 at midnight, so the roads
-- visibly breathe with the day/night cycle (sim scales commuter spawns by this).
function traffic_factor()
 return 1-0.7*day_phase()
end

-- two states only: day (no remap) or night. no morning/evening tween.
function night_pal()
 if day_phase()>0.5 then
  for i=1,15 do pal(i,night_lut[i]) end
 end
end
-- >>> save.lua
-- save.lua : save/load via cstore/reload to a companion cart. HEADER — stubs.
-- api: save_city, load_city
-- calls: money/month/year/tax_rate (econ); update_net, init_sim, sim_seed (sim);
--        init_agents (agents); pclr + pl_cong (map/data); gw, mset/mget.
-- layout (manual 6.7): tile grid lives in the map region 0x2000; the sim data
-- planes live at 0x8000 (6 planes x 1024 = 0x1800). companion cart "citysave2.p8"
-- must exist on disk. money is $k (store the integer part).

function save_city()
 local m=flr(money)
 mset(120,0,42)
 mset(121,0,m%256) mset(122,0,flr(m/256))
 mset(123,0,month) mset(124,0,year-1900) mset(125,0,tax_rate)
 cstore(0x2000,0x2000,0x1000,"citysave2.p8")
 cstore(0x0,0x8000,0x1800,"citysave2.p8")
 -- pl_wire (wire-over-road/water overlay) lives past the 0x9800 plane block, so
 -- save it separately into the free file gap at 0x1800 (before the 0x2000 grid).
 cstore(0x1800,pl_wire,0x400,"citysave2.p8")
end

function load_city()
 reload(0x2000,0x2000,0x1000,"citysave2.p8")
 if mget(120,0)~=42 then return end
 reload(0x8000,0x0,0x1800,"citysave2.p8")
 reload(pl_wire,0x1800,0x400,"citysave2.p8")  -- before update_net (it reads pl_wire)
 money=mget(121,0)+mget(122,0)*256
 month=mget(123,0) year=1900+mget(124,0) tax_rate=mget(125,0)
 init_agents() pclr(pl_cong) update_net() init_sim() sim_seed()
end

-- glue owns _init/_update/_draw; modules never define them.
function _init()
 init_map()
 gen_terrain()
 update_net()
 init_agents()
 init_sim()
 sim_seed()
 init_econ()
 init_fire()
 init_log()
 init_tools()
 update_camera(true)
 mapview=false
 menuitem(1,"save city",save_city)
 menuitem(2,"load city",load_city)
 menuitem(3,"map view",function() mapview=not mapview end)
 menuitem(4,"start fire",start_fire)
 menuitem(5,"sound: on",function() sfx_mute=not sfx_mute return true end)
end

function _update()
 update_tools()
 update_sim()
 update_agents()
 update_econ()
 maybe_ignite()
end

function _draw()
 -- water is tile/sprite 0, which map() never draws — so clear to the water
 -- colour (blue by day, navy by night) and the "empty" water tiles read as sea.
 cls(day_phase()>0.5 and 1 or 12)
 draw_world()
 if mapview then draw_minimap() else draw_inspector() end
 draw_log()
 draw_hud()
 draw_toolbar()
end

__gfx__
cccccccc333333333335533300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccc1cccc333b33333357d53300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccc1c33333333355ddd5300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c1cccccc33333b3355d6d6d500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccc1ccc3333b3335d6d6d6500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1cccccccb3333333dddddddd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccc1ccc333333b35d5dd5d500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cc1ccccc333333335555555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666655555566666666665555555666666666555555666666666655555556666666655555556666666665555555566666666555555566666666655555555
65555556655a555665555555655a555565555556655a555665555555655a555555555556555a555655555555555a555555555556555a555655555555555a5555
65555556655555566555555565555555655555566555555665555555655555555555555655555556555555555555555555555556555555565555555555555555
655a5556655a5556655a55a5655a55a5655a5556655a5556655a55a5655a55a55a5a55565a5a55565a5a55a55a5a55a55a5a55565a5a55565a5a55a55a5a55a5
65555556655555566555555565555555655555566555555665555555655555555555555655555556555555555555555555555556555555565555555555555555
65555556655555566555555565555555655555566555555665555555655555555555555655555556555555555555555555555556555555565555555555555555
65555556655555566555555565555555655a5556655a5556655a5555655a555555555556555555565555555555555555555a5556555a5556555a5555555a5555
66666666666666666666666666666666655555566555555665555555655555556666666666666666666666666666666655555556555555565555555555555555
33333333333033333333333333303333333333333330333333333333333033333333333333303333333333333330333333333333333033333333333333303333
33333333333033333333333333303333333333333330333333333333333033333333333333303333333333333330333333333333333033333333333333303333
33333333333033333333333333303333333333333330333333333333333033333333333333303333333333333330333333333333333033333333333333303333
33303333333033333330000033300000333033333330333333300000333000000000333300003333000000000000000000003333000033330000000000000000
33303333333433333334333333343333333433333334333333343333333433333334333333343333333433333334333333343333333433333334333333343333
33333333333333333333333333333333333033333330333333303333333033333333333333333333333333333333333333303333333033333330333333303333
33333333333333333333333333333333333033333330333333303333333033333333333333333333333333333333333333303333333033333330333333303333
33333333333333333333333333333333333033333330333333303333333033333333333333333333333333333333333333303333333033333330333333303333
b3b3b3bb33333333333333333fbbbbf3c3c3c3cc33333333333333333cccccc3a3a3a3aa33333333333333333aaaaaa336333633333333333333333333533533
3333333333333333333333333f7f7ff33333333333333333333333333177771333333333333333333333353334444443343334333bb33bb33666666355656555
b333333b333333333fbbbbf33ffffff3c333333c333333333cccccc331111113a333333a333333333aaaaaa334944443555555553bbb3bb36888888656555655
33333333333333333f7f7ff33f7f7ff33333333333333333317777133177771333333333333335333444444334444443559a955533b3eb336882288665555565
b333333b3fbbbbf33ffffff33ffffff3c333333c3cccccc33111111331111113a333333a3aaaaaa3349444433494444355aaa5553433b3336882288655656556
333333333f7f7ff33f7f7ff33f7f7ff3333333333177771331777713317777133333333334444443344444433444444355595555333bb3b36888888653565555
b333333b3ffffff33ffffff33ffffff3c333333c311111133111111331111113a333333a3494444334944443349444435555555533b333b36777777655555655
b3b3b3b33bbbbbb33bbbbbb33bbbbbb3c3c3c3c33cccccc33cccccc33cccccc3a3a3a3a33aaaaaa33aaaaaa33aaaaaa388888888333333333777777355555555
33333333363336330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3bbbbbb3383338330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b655556b666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b6b33b6b668986660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b6b33b6b669996660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b655556b666866660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3bbbbbb3666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
36666663888888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000800001e15024150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000c6500a650086500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800002413030130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000c0000182501e250182501e25000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000600002c13030130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
