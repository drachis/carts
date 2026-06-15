pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- headless smoke test: pico8 -x tests/smoke.p8
#include ../params.lua
#include ../data.lua
#include ../notify.lua
#include ../sound.lua
#include ../map.lua
#include ../router.lua
#include ../net.lua
#include ../landval.lua
#include ../coverage.lua
#include ../terrain.lua
#include ../agents.lua
#include ../sim.lua
#include ../disaster.lua
#include ../fx.lua
#include ../econ.lua
#include ../daynight.lua
#include ../save.lua

local pass,fail=0,0
function ok(c,n)
 if c then pass+=1 printh("ok   "..n) else fail+=1 printh("fail "..n) end
end

srand(1)
init_map()
gen_terrain()
local w,g,m=0,0,0
for y=0,gw-1 do for x=0,gw-1 do
 local s=tile(x,y)
 if s==0 then w+=1 elseif s==2 then m+=1 elseif s==1 then g+=1 end
end end
ok(g>0,"terrain has grass ("..g..")")
ok(w>0,"terrain has water ("..w..")")
ok(g>w and g>m,"mostly grass (g="..g.." w="..w.." m="..m..")")

local hi=0
for y=0,gw-1 do for x=0,gw-1 do hi=max(hi,peekp(pl_elev,x,y)) end end
ok(hi>0,"elevation plane filled (max "..hi..")")

-- road network on grass
for x=4,20 do set_tile(x,8,16) end
update_net()
ok(ncomp>=1,"road component found ("..ncomp..")")
ok(connected(4,8,20,8),"road ends connected")
ok(not connected(4,8,4,20),"off-road tiles not connected")

-- agents: spawn, move, congestion bookkeeping
init_agents()
spawn_agent(4,8,20,8,1)
ok(#agents==1,"agent spawned")
ok(peekp(pl_cong,4,8)==1,"congestion +1 at start tile")
local moved=false
for i=1,300 do
 update_agents()
 if #agents>0 and (agents[1].px~=36 or agents[1].py~=68) then moved=true end
end
ok(moved,"agent moved along the road")
ok(#agents==0,"agent expired/arrived and was removed")
local cong=0
for y=0,gw-1 do for x=0,gw-1 do cong+=peekp(pl_cong,x,y) end end
ok(cong==0,"congestion fully released after agents gone (sum "..cong..")")

-- sim core: R + C zones joined by a road grow and generate commuters
init_map()
for x=4,12 do set_tile(x,10,16) end
for x=6,10 do set_tile(x,8,32) end -- power line above the zones
set_tile(8,7,60)                    -- power plant feeding the line
set_zone(6,9,1,1)   -- residential beside the road + line
set_zone(10,9,2,1)  -- commercial beside the road + line
set_tile(8,11,62)   -- fire station: service coverage unlocks tall growth
update_net()
ok(connected(6,9,10,9),"the two zones share a road network")
ok(powered(6,9) and powered(10,9),"zones beside a plant-fed line are powered")
init_sim()
init_agents()
sim_seed()
local spawned=false
for i=1,2000 do
 update_sim()
 update_agents()
 if #agents>0 then spawned=true end
end
ok(zone_density(6,9)>1 or zone_density(10,9)>1,"connected zones grew (r="..zone_density(6,9).." c="..zone_density(10,9)..")")
ok(pop>0 and jobs>0,"census: pop="..pop.." jobs="..jobs)
ok(spawned,"commuters spawned between home and work")
local ti=tile_info(6,9)
ok(ti~=nil and ti.kind==1,"tile_info reports the zone")

-- BOOTSTRAP: a minimal city zoned at density 0 (as the tool places it) must
-- grow from nothing — R/C/I in a row, powered, road below. (regression for the
-- density-0 deadlock where nothing had a developed complement.)
init_map()
set_zone(5,5,1,0) set_zone(6,5,2,0) set_zone(7,5,3,0)
for x=5,7 do set_tile(x,6,16) end
set_tile(4,5,60)   -- plant beside R; power conducts through the zone row
update_net()
ok(powered(5,5) and powered(7,5),"minimal city is powered")
ok(rcomp(5,5)~=0,"minimal city has road access")
init_sim() init_agents() sim_seed()
local built,cars=false,false
for i=1,3000 do
 update_sim() update_agents()
 if zone_density(5,5)+zone_density(6,5)+zone_density(7,5)>0 then built=true end
 if #agents>0 then cars=true end
end
ok(built,"a density-0 minimal city bootstraps into buildings")
ok(cars,"commuters appear once buildings develop")

-- service gate: the SAME setup with no station/park caps growth at lv1
init_map()
for x=4,12 do set_tile(x,10,16) end
for x=6,10 do set_tile(x,8,32) end set_tile(8,7,60)
set_zone(6,9,1,1) set_zone(10,9,2,1)
update_net() init_sim() init_agents() sim_seed()
for i=1,2000 do update_sim() update_agents() end
ok(zone_density(6,9)<=1 and zone_density(10,9)<=1,"no service -> growth caps at lv1")

-- (tool placement asserts live in t_tools.p8 — splitting keeps each cart < 8192)

-- econ: $k money formatting + spending
init_econ()
ok(mfmt(0.5)=="$500","mfmt sub-1k shows dollars")
ok(mfmt(2)=="$2k","mfmt whole thousands")
ok(mfmt(1500)=="$1.5m","mfmt millions")
ok(mfmt(-3)=="-$3k","mfmt negative")
money=2
ok(try_spend(1000) and money==1,"try_spend deducts $k")
ok(not try_spend(10000),"try_spend rejects past the debt floor")

-- goods chain: connected industry + commercial run freight (res 3)
init_map()
for x=4,12 do set_tile(x,10,16) end
for x=6,10 do set_tile(x,8,32) end set_tile(8,7,60)
set_zone(6,9,3,1)   -- industry
set_zone(10,9,2,1)  -- commercial
update_net()
init_sim() init_agents() sim_seed()
local freight=false
for i=1,2000 do
 update_sim() update_agents()
 for _,a in pairs(agents) do if a.res==3 then freight=true end end
end
ok(freight,"industry<->commercial run goods freight (res 3)")

-- desirability: water raises land value, industry lowers it
init_map()
init_agents()
set_tile(5,5,0)    -- water
set_tile(25,5,56)  -- industry
update_val()
ok(desir(7,5)>128,"waterfront raises desirability ("..desir(7,5)..")")
ok(desir(27,5)<128,"industry lowers desirability ("..desir(27,5)..")")
ok(desir(15,20)==128,"neutral away from everything")
set_tile(15,15,61) -- park
update_val()
ok(desir(16,15)>128,"a park raises desirability ("..desir(16,15)..")")

-- dirty queue: a change only recomputes its neighbourhood, drained over time
init_map()
update_val()
ok(#vq==0,"full sweep empties the dirty queue")
set_tile(5,5,0)        -- new water, not yet reflected
val_dirty_area(5,5)
ok(#vq>0,"a change queues dirty tiles")
for i=1,p.val_div*2 do step_val() end
ok(#vq==0,"the queue drains (cost scales with backlog)")
ok(desir(7,5)>128,"drained recompute sees the new water ("..desir(7,5)..")")

-- power gating: an unpowered (no plant) zone never grows
init_map()
for x=4,12 do set_tile(x,14,16) end
set_zone(6,13,1,1) set_zone(10,13,2,1)
update_net()
ok(not powered(6,13),"no plant -> not powered")
init_sim() sim_seed()
for i=1,2000 do update_sim() end
ok(zone_density(6,13)<2 and zone_density(10,13)<2,"unpowered zones never grow")

-- bridges + wires over roads: roads cross water; a wired road carries power
init_map()
set_tile(8,8,60)   -- plant
set_tile(8,9,32)   -- wire down to the road
for x=4,12 do set_tile(x,10,16) end -- a road crossing the wire's path
set_tile(8,11,32)  -- wire continues on the far side
update_net()
ok(not powered(8,11),"plain road blocks power (no crossing yet)")
pokep(pl_wire,8,10,1) -- lay a wire across the road tile
update_net()
ok(power_carries(8,10),"a wired road carries power")
ok(powered(8,11),"power crosses the road through the wire")

-- service buildings carry power; wires cross water too
init_map()
set_tile(8,8,60) set_tile(8,9,62) set_zone(8,10,1,0) -- plant-station-zone
update_net()
ok(powered(8,10),"power flows through a service building")
init_map()
set_tile(10,10,0) pokep(pl_wire,10,10,1)
ok(power_carries(10,10),"a wire crosses water")

-- (placement-cost asserts live in t_tools.p8)

-- fire: a developed zone ignites and burns down to rubble
init_map()
init_sim()
init_fire()
set_zone(10,10,1,2) -- developed residential
ignite(10,10)
ok(peekp(pl_fire,10,10)>0,"ignited zone is on fire")
for i=1,600 do update_sim() end
ok(tile(10,10)==63,"fire burned the zone to rubble")
ok(not is_buildable(10,10),"rubble blocks rebuild until cleared")

-- coverage: stations + parks project a service field; zones need it to grow tall
init_map()
set_tile(10,10,62)  -- fire station
update_cov()
ok(serviced(10,10),"fire station provides coverage")
ok(serviced(12,12),"coverage reaches within fire_rad")
ok(not serviced(24,24),"far tiles are uncovered")
set_tile(24,24,61)  -- park
update_cov()
ok(serviced(24,24),"a park provides coverage too")

-- wrecking crew: rubble near a station gets a crew dispatched that clears it
init_map() init_sim() init_fire() init_agents()
for x=4,12 do set_tile(x,10,16) end
set_tile(5,9,64)    -- recycling station (depot) beside the road
set_tile(9,9,63)    -- rubble beside the road, reachable from the depot
update_net()
schedule(1,{k=3,x=9,y=9})
for i=1,800 do update_sim() update_agents() end
ok(tile(9,9)==1,"wrecking crew cleared the rubble")

-- a fire station suppresses fire within its radius (no rubble)
init_map()
init_sim()
init_fire()
set_tile(12,12,62)   -- fire station
set_zone(12,13,1,2)  -- developed zone in coverage
ok(fire_covered(12,13),"zone is inside station coverage")
ignite(12,13)
for i=1,600 do update_sim() end
ok(tile(12,13)~=63,"fire station suppressed the fire")

-- event log: notify pushes a notice; the ring caps at 8
init_log()
notify("hello",7,1,2)
ok(#log==1 and log[1].x==1 and log[1].y==2,"notify records an event with its tile")
for i=1,12 do notify("spam",7) end
ok(#log==8,"event log ring caps at 8")

-- day/night: phase stays in 0..1; noon (tick 0) is brightest
tick=0
ok(day_phase()<0.01,"noon is brightest (phase ~0)")
tick=flr(p.day_frames/2)
ok(day_phase()>0.99,"midnight is darkest (phase ~1)")

-- fx: a burst spawns particles that then age out
init_map() init_fire() init_fx()
fx_burst(80,80,7,5)
ok(#parts==5,"fx_burst spawns particles")
for i=1,30 do update_fx() end
ok(#parts==0,"particles age out")

-- save / load round-trip (grid + scalars via companion cart)
init_map()
for x=4,10 do set_tile(x,5,16) end
set_zone(6,4,1,1)
money=7 month=5 year=1963 tax_rate=3
save_city()
money=1 month=1 year=1950 set_tile(6,4,1)
load_city()
ok(money==7 and month==5 and year==1963 and tax_rate==3,"save/load restores scalars")
ok(zone_kind(6,4)==1,"save/load restores the grid")

printh("---- "..pass.." passed, "..fail.." failed ----")
if fail>0 then printh("test result: fail") else printh("test result: pass") end
