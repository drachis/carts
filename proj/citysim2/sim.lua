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
 local pw=powered(x,y)
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
  pokep(pl_sat,x,y,p.sat_seed)  -- a fresh storey opens with goodwill
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
 return {kind=k,dens=zone_density(x,y),access=rcomp(x,y)~=0,
  power=powered(x,y),served=wx~=nil,val=desir(x,y),
  svc=(not serviced) or serviced(x,y),unhappy=peekp(pl_sat,x,y)<p.sat_low}
end
