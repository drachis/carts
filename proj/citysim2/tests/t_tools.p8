pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- focused tool/power-capacity test (the full smoke cart now overflows 8192 with
-- every module + assert, so tests are split by concern). includes only what the
-- tool + net + power-capacity asserts need.
#include ../params.lua
#include ../data.lua
#include ../notify.lua
#include ../sound.lua
#include ../map.lua
#include ../router.lua
#include ../net.lua
#include ../landval.lua
#include ../coverage.lua
#include ../agents.lua
#include ../sim.lua
#include ../disaster.lua
#include ../tools.lua
#include ../econ.lua

local pass,fail=0,0
function ok(c,n) if c then pass+=1 printh("ok   "..n) else fail+=1 printh("fail "..n) end end

-- the 2D palette + select_tool place each tool type
init_map() init_sim() init_tools() money=99
select_tool("road") cur={x=8,y=8} apply_tool()
ok(is_road(8,8),"road tool places a road")
select_tool("r-zone") cur={x=8,y=7} apply_tool()
ok(zone_kind(8,7)==1,"r-zone places residential")
select_tool("c-zone") cur={x=9,y=7} apply_tool()
ok(zone_kind(9,7)==2,"c-zone places commercial")
select_tool("park") cur={x=20,y=20} apply_tool()
ok(tile(20,20)==61,"park places")
select_tool("fire") cur={x=22,y=20} apply_tool()
ok(tile(22,20)==62,"fire station places")
select_tool("recycle") cur={x=24,y=20} apply_tool()
ok(tile(24,20)==64,"recycle station places")
select_tool("plant") cur={x=26,y=20} apply_tool()
ok(tile(26,20)==60,"plant places")
select_tool("big plant") cur={x=28,y=20} apply_tool()
ok(tile(28,20)==65,"big plant places")
select_tool("bulldoze") cur={x=8,y=8} apply_tool()
ok(tile(8,8)==1,"bulldoze clears road to grass")
-- bulldozing a developed zone razes the building but KEEPS the zoning (v1)
set_zone(14,14,1,2) select_tool("bulldoze") cur={x=14,y=14} money=99 apply_tool()
ok(zone_kind(14,14)==1 and zone_density(14,14)==0,"bulldoze razes building, keeps zone")
apply_tool()
ok(tile(14,14)==1,"a second bulldoze clears the empty zone to grass")
-- bulldozing a road's neighbours re-autotiles it back to a stub
select_tool("road")
cur={x=5,y=5} apply_tool() cur={x=6,y=5} apply_tool() cur={x=5,y=6} apply_tool()
ok(tile(5,5)>16,"the corner road has connections")
select_tool("bulldoze")
cur={x=6,y=5} apply_tool() cur={x=5,y=6} apply_tool()
ok(tile(5,5)==16,"removing the neighbours resets the road to a stub")
-- same for power lines (32..47)
select_tool("power")
cur={x=15,y=15} apply_tool() cur={x=16,y=15} apply_tool() cur={x=15,y=16} apply_tool()
ok(tile(15,15)>32,"the corner power line has connections")
select_tool("bulldoze")
cur={x=16,y=15} apply_tool() cur={x=15,y=16} apply_tool()
ok(tile(15,15)==32,"removing the neighbours resets the power line to a stub")
set_tile(0,0,0) select_tool("r-zone") cur={x=0,y=0} apply_tool()
ok(not is_zone(0,0),"zone tool rejects water")

-- bridges + wires
init_map() init_tools() money=99
set_tile(10,10,0) select_tool("road") cur={x=10,y=10} apply_tool()
ok(is_road(10,10),"road bridges water")
ok(peekp(pl_bridge,10,10)==1,"a road over water is flagged a bridge")
select_tool("bulldoze") apply_tool()
ok(tile(10,10)==0 and peekp(pl_bridge,10,10)==0,"bulldozing a bridge gives the water back")
init_map() init_tools() money=99
set_tile(8,8,60) select_tool("power") cur={x=9,y=8} apply_tool()
ok(tile(8,8)==60,"plant survives an adjacent power line")
ok(tile(9,8)>=32 and tile(9,8)<=47,"the power line was placed")

-- power capacity: flood respects the cap; both plant types power a zone
local cnt=0
flood(2,2,function() return true end,function() cnt+=1 end,5)
ok(cnt<=8,"flood respects the capacity cap ("..cnt..")")
init_map() set_tile(8,8,65) set_zone(8,9,1,1) update_net() pwr_tick()
ok(powered(8,9),"a big plant powers an adjacent built zone")

-- placement charges money; denied when broke
init_map() init_tools() select_tool("r-zone")
money=2 cur={x=5,y=5} apply_tool()
ok(zone_kind(5,5)==1 and money<2,"placing a zone charges money")
money=-1 cur={x=6,y=5} apply_tool()
ok(not is_zone(6,5),"placement denied when broke")

printh("---- "..pass.." passed, "..fail.." failed ----")
if fail>0 then printh("test result: fail") else printh("test result: pass") end
