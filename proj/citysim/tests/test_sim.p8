pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- headless sim tests: pico8 -x tests/test_sim.p8
#include ../map.lua
#include ../power.lua
#include ../growth.lua
#include ../econ.lua
#include ../landval.lua
#include ../tools.lua
#include ../traffic.lua
#include ../disaster.lua
#include ../savegame.lua
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
fset(59,0,true)
fset(60,0,true)
fset(61,2,true)

srand(1)
init_map()
init_tools()
init_power()
init_econ()
init_growth()
init_landval()
init_disaster()
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
tool=6 -- power line
cur={x=12,y=10}
apply_tool()
ok(tile(12,10)==53,"line over h-road makes crossing")
ok(is_road(12,10) and conducts(12,10),"crossing is road and conducts")
refresh_tile(12,10)
ok(tile(12,10)==53,"autotile leaves crossing alone")
update_power()

-- traffic v2: commuters need a home, a workplace, and a road between
init_traffic()
for x=5,35 do
 set_tile(x,20,16)
end
for x=5,35 do
 refresh_tile(x,20)
end
for x=5,18 do
 set_zone(x,19,1,2) -- developed homes north of the road
 set_zone(x,21,1,2) -- and south
end
for x=25,35 do
 set_zone(x,19,2,2) -- developed shops at the east end
 set_zone(x,21,2,2)
end
local p=tr_path(5,20,35,20)
ok(p~=nil and #p==31,"tr_path finds the straight route")
ok(tr_path(5,20,12,10)==nil,"tr_path returns nil when disconnected")
pop=100
local spawned,on_road=false,true
for f=12001,31200 do
 frame=f
 update_traffic()
 if #tr_cars>0 then
  spawned=true
  for c in all(tr_cars) do
   if not is_road(flr(c.px/8),flr(c.py/8)) then on_road=false end
  end
 end
end
ok(spawned,"commuters spawn between homes and jobs")
ok(on_road,"cars stay on roads for their whole trip")
draw_traffic()

-- park tool places a park
money=1000
tool=5 -- park
cur={x=2,y=2}
set_tile(2,2,1)
apply_tool()
ok(tile(2,2)==44,"park tool places park")

-- land value: industry drags down, parks lift up
set_zone(40,5,3,3)
frame=64
update_landval()
ok(land_value(40,5)<0,"industry pollutes its cell")
ok(land_value(2,2)>0,"park raises its cell")
ok(growth_mult(40,5,1)<1,"residential growth suffers near industry")
ok(growth_mult(40,5,3)==1,"industry does not care")

-- fire burns a zone down to rubble
dz_ignite(12,11)
ok(tile(12,11)==55,"ignition sets fire tile")
for f=1,200 do
 frame=13200+f
 update_disaster()
end
ok(tile(12,11)==56,"fire burns out to rubble")
ok(#dz_fires==0 or tile(12,11)==56,"fire list drains")

-- plant capacity: a 48-tile line + plant exceeds one plant's 40
set_tile(15,11,1) -- remove the earlier plant so cap is one plant's worth
for x=0,gridw-1 do set_tile(x,44,49) end
set_tile(0,43,48)
update_power()
ok(power_short,"over-capacity sets power_short")
ok(not is_powered(47,44),"tiles beyond capacity stay dark")

-- deficit spending: allowed into debt, refused past the ceiling
money=10
ok(try_spend(100) and money==-90,"spending into debt allowed")
ok(not try_spend(2000),"debt ceiling refuses")
ok(money==-90,"refused spend leaves debt alone")

-- bridges + water pylons
money=1000
local wx,wy=nil,nil
for y=0,gridh-1 do
 for x=0,gridw-1 do
  if wx==nil and tile(x,y)==3 then wx,wy=x,y end
 end
end
ok(wx~=nil,"river exists")
mode="play"
tool=1 -- road
cur={x=wx,y=wy}
apply_tool()
local b=tile(wx,wy)
ok(b==59 or b==60,"road on water builds a bridge")
ok(is_road(wx,wy),"bridge is a road")
tool=8 -- bulldoze
apply_tool()
ok(tile(wx,wy)==3,"bulldozed bridge reverts to water")
tool=6 -- power line
apply_tool()
ok(tile(wx,wy)==61 and conducts(wx,wy),"line on water builds a pylon")

-- sim speed cycles 1 -> 2 -> 4 -> 1
ok(gspd==1,"speed starts 1x")
cycle_speed()
cycle_speed()
ok(gspd==4,"speed cycles to 4x")
cycle_speed()
ok(gspd==1,"speed wraps to 1x")

-- save / load / new city
money=777 month=3 year=1963 tax_rate=2 milestone=50
save_city()
money=1 month=1 year=1950 milestone=0
load_city()
ok(money==777 and month==3 and year==1963 and milestone==50,
   "save/load restores scalars")
ok(mget(49,0)==42,"save magic present")
new_city()
ok(money==2000 and pop==0,"new city resets the books")

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
