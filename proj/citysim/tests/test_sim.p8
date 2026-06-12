pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- headless sim tests: pico8 -x tests/test_sim.p8
#include ../map.lua
#include ../power.lua
#include ../growth.lua
#include ../econ.lua
#include ../tools.lua
#include ../traffic.lua
#include ../ui.lua

local pass,failed=0,0
function ok(cond,name)
 if cond then
  pass+=1
  printh("ok   "..name)
 else
  failed+=1
  printh("fail "..name)
 end
end

-- this cart has no __gff__, so recreate the sprite flags from design.md
fset(1,3,true)
fset(2,3,true)
for i=16,31 do fset(i,0,true) end
for i=32,43 do
 fset(i,1,true)
 fset(i,2,true)
end
fset(48,2,true)
for i=49,51 do fset(i,2,true) end
for i=53,54 do
 fset(i,0,true)
 fset(i,2,true)
end

srand(1)
init_map()
init_tools()
init_power()
init_econ()
init_growth()
frame=0

-- hand-build a powered block: road row, zones under it, plant at the end
for x=10,14 do set_tile(x,10,16) end
for x=10,14 do refresh_tile(x,10) end
ok(tile(12,10)==26,"road autotile picks e+w sprite")
ok(tile(10,10)==18,"road end picks e-only sprite")

for x=10,14 do set_zone(x,11,1,0) end
set_tile(15,11,48)
update_power()
ok(is_powered(15,11),"plant is powered")
ok(is_powered(14,11),"zone next to plant powered")
ok(is_powered(10,11),"power conducts along zone row")
ok(not is_powered(20,20),"far tile not powered")
ok(has_road_access(12,11),"zone has road access")
ok(zone_kind(12,11)==1 and zone_density(12,11)==0,"zone kind/density")

-- run the sim a while: residential should develop
for f=1,9000 do
 frame=f
 update_growth()
end
local grew=false
for x=10,14 do
 if zone_density(x,11)>0 then grew=true end
end
ok(grew,"zones grow with power+road+demand")
ok(pop and pop>0,"population counted")
ok(demand.r~=nil and demand.c~=nil and demand.i~=nil,"demand table populated")

-- unpowered zones don't grow
set_zone(30,30,2,0)
set_tile(30,29,16)
refresh_tile(30,29)
for f=9001,12000 do
 frame=f
 update_growth()
end
ok(zone_density(30,30)==0,"unpowered zone stays density 0")

-- econ
money=500
ok(try_spend(100) and money==400,"try_spend deducts")
ok(not try_spend(10000),"try_spend rejects when broke")
ok(money==400,"failed spend leaves money alone")
local m0,y0=month,year
for i=1,300 do update_econ() end
ok(month~=m0 or year~=y0,"month advances after 300 frames")

-- power line crosses a straight road via apply_tool
money=1000
mode="play"
tool=5 -- power line
cur={x=12,y=10}
apply_tool()
ok(tile(12,10)==53,"line over h-road makes crossing")
ok(is_road(12,10) and conducts(12,10),"crossing is road and conducts")
refresh_tile(12,10)
ok(tile(12,10)==53,"autotile leaves crossing alone")
update_power()

-- traffic: cars appear on a road network once there's population
init_traffic()
for x=5,35 do
 set_tile(x,20,16)
end
for x=5,35 do
 refresh_tile(x,20)
end
pop=100
for f=12001,13200 do
 frame=f
 update_traffic()
end
ok(#tr_cars>0,"cars spawn on roads")
local on_road=true
for c in all(tr_cars) do
 if not is_road(flr(c.px/8),flr(c.py/8)) then on_road=false end
end
ok(on_road,"all cars are on roads")
draw_traffic()

-- ui smoke test: just make sure nothing crashes when drawing
camx,camy=0,0
draw_hud()
mode="menu"
draw_menu()
mode="map"
draw_minimap()
msg,msg_t="hello",10
draw_msg()
mode="play"
draw_world()
ok(true,"ui draws without error")

printh("---- "..pass.." passed, "..failed.." failed ----")
if failed>0 then printh("test result: fail") else printh("test result: pass") end
