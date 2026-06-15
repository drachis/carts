pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- headless smoke test: pico8 -x tests/smoke.p8
#include ../params.lua
#include ../data.lua
#include ../map.lua
#include ../router.lua
#include ../net.lua
#include ../terrain.lua
#include ../agents.lua
#include ../sim.lua
#include ../tools.lua
#include ../econ.lua
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
set_zone(6,9,1,1)   -- residential beside the road
set_zone(10,9,2,1)  -- commercial beside the road
update_net()
ok(connected(6,9,10,9),"the two zones share a road network")
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

-- tools: placement applies + hooks the sim/net
init_map()
init_sim()
init_tools()
cur={x=8,y=8} tool=1 apply_tool()
ok(is_road(8,8),"road tool places a road")
cur={x=9,y=8} tool=1 apply_tool()
ok(tile(8,8)==18 or tile(8,8)>=16,"road autotiles toward its neighbour")
cur={x=8,y=7} tool=2 apply_tool()
ok(zone_kind(8,7)==1,"r-zone tool places residential")
cur={x=9,y=7} tool=3 apply_tool()
ok(zone_kind(9,7)==2,"c-zone tool places commercial")
set_tile(0,0,0) -- water
ok(tool_put(2,0,0)==nil,"tool_put rejects unbuildable (water)")
cur={x=8,y=8} tool=6 apply_tool()
ok(tile(8,8)==1,"bulldoze clears to grass")

-- econ: $k money formatting + spending
init_econ()
ok(mfmt(0.5)=="$500","mfmt sub-1k shows dollars")
ok(mfmt(2)=="$2k","mfmt whole thousands")
ok(mfmt(1500)=="$1.5m","mfmt millions")
ok(mfmt(-3)=="-$3k","mfmt negative")
money=2
ok(try_spend(1000) and money==1,"try_spend deducts $k")
ok(not try_spend(10000),"try_spend rejects past the debt floor")

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
