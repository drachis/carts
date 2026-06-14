pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- headless core-sim tests: pico8 -x tests/test_sim.p8
-- (systems/feel tests live in test_feel.p8 - together all modules
--  plus test code exceed the 8192 token cart limit)
#include ../params.lua
#include ../map.lua
#include ../power.lua
#include ../growth.lua
#include ../econ.lua
#include ../landval.lua
#include ../network.lua
#include ../tools.lua

-- effects.lua not included here; tools/growth call this
function add_fx() end

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
fset(4,3,true)
for i=16,31 do fset(i,0,true) end
for i=32,43 do
 fset(i,1,true)
 fset(i,2,true)
end
fset(48,2,true)
for i=53,54 do
 fset(i,0,true)
 fset(i,2,true)
end
fset(59,0,true)
fset(60,0,true)
fset(61,2,true)
fset(62,2,true)
for i=64,66 do fset(i,2,true) end
for i=80,95 do fset(i,2,true) end

srand(1)
init_map()
init_tools()
init_power()
init_econ()
init_growth()
init_landval()
init_net()
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
ok(not is_powered(12,10),"plain roads do not carry power")
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

-- econ (money is stored in thousands of dollars; try_spend takes dollars)
money=2 -- $2000
ok(try_spend(1000) and money==1,"try_spend deducts")
ok(not try_spend(10000),"try_spend rejects when broke")
ok(money==1,"failed spend leaves money alone")
local m0,y0=month,year
for i=1,300 do update_econ() end
ok(month~=m0 or year~=y0,"month advances after 300 frames")

-- mfmt: $k value -> abbreviated string (dollars / k / m, signed)
ok(mfmt(0)=="$0","mfmt zero")
ok(mfmt(0.5)=="$500","mfmt sub-1k shows dollars")
ok(mfmt(2)=="$2k","mfmt whole thousands")
ok(mfmt(1.5)=="$1.5k","mfmt one decimal k")
ok(mfmt(1000)=="$1m","mfmt millions")
ok(mfmt(2500)=="$2.5m","mfmt one decimal m")
ok(mfmt(-3)=="-$3k","mfmt negative")

-- power line crosses a straight road via apply_tool
money=1000
mode="play"
tool=7 -- power line
cur={x=12,y=10}
apply_tool()
ok(tile(12,10)==53,"line over h-road makes crossing")
ok(is_road(12,10) and conducts(12,10),"crossing is road and conducts")
ok(started==true,"building starts the clock")
refresh_tile(12,10)
ok(tile(12,10)==53,"autotile leaves crossing alone")
update_power()

-- park tool places a park
money=1000
tool=6 -- park
cur={x=2,y=2}
set_tile(2,2,1)
apply_tool()
ok(tile(2,2)==44,"park tool places park")

-- bulldoze restores developed zones (any density) to their empty plot
money=1000
tool=12 -- bulldoze
set_zone(2,4,1,3) -- dense residential
cur={x=2,y=4}
apply_tool()
ok(tile(2,4)==32,"bulldoze dense zone restores empty r-plot")
set_zone(3,4,3,2) -- mid industrial
cur={x=3,y=4}
apply_tool()
ok(tile(3,4)==40,"bulldoze dense zone restores empty i-plot")
cur={x=2,y=4}
apply_tool() -- second pass on empty plot clears to grass
ok(tile(2,4)==1,"bulldoze empty plot clears to grass")

-- land value: industry drags down, parks lift up
set_zone(40,5,3,3)
frame=32
update_growth()
ok(land_value(40,5)<0,"industry pollutes its cell")
ok(land_value(2,2)>0,"park raises its cell")
ok(growth_mult(40,5,1)<1,"residential growth suffers near industry")
ok(growth_mult(40,5,3)==1,"industry does not care")

-- plant capacity: carriers are free, buildings draw from the plant
set_tile(15,11,1) -- remove the earlier plant so cap is one plant's worth
for x=0,gridw-1 do set_tile(x,44,80) end
set_tile(0,43,48)
update_power()
ok(is_powered(47,44),"wires transfer without consuming capacity")
ok(not power_short,"carriers alone cause no shortage")
for x=0,gridw-1 do set_zone(x,44,1,1) end
update_power()
ok(power_short,"48 buildings exceed one plant's 40")
ok(not is_powered(47,44),"buildings beyond capacity stay dark")

-- glassbox needs: zones grow past level 1 only when their road
-- network reaches what they need
for x=2,8 do set_tile(x,46,16) end
set_zone(2,45,1,1)
update_net(true)
ok(not net_ok(2,45,1,1),"lone homes find no jobs on their network")
ok(net_ok(2,45,1,0),"pioneers settle anywhere")
set_zone(5,45,2,1)
set_zone(6,45,3,1)
update_net(true)
ok(net_ok(2,45,1,1),"homes find jobs along the road")
ok(net_ok(5,45,2,1),"shops reach customers and freight")
ok(net_ok(6,45,3,1),"factories reach workers")

-- terrain: the generator raises mountains and highland
local rocks,high=0,0
for y=0,gridh-1 do
 for x=0,gridw-1 do
  if tile(x,y)==5 then rocks+=1 end
  if tile(x,y)==4 then high+=1 end
 end
end
ok(rocks>10,"mountain ranges generated")
ok(high>5,"highland fringes generated")
set_tile(8,40,5)
ok(not is_buildable(8,40),"mountains are unbuildable")
money=1 -- $1000
mode="play"
tool=12 -- bulldoze
cur={x=8,y=40}
apply_tool()
ok(tile(8,40)==1 and money==1-cost.blast/1000,"blasting a mountain costs $25")

-- river bends carry a flow vector for the ripples
local has_flow=false
for y=0,gridh-1 do
 local f=flow[y]
 if f==nil or f<-1 or f>1 then has_flow=nil break end
 if f~=0 then has_flow=true end
end
ok(has_flow~=nil,"flow vector defined for every row")
ok(has_flow==true,"river actually bends somewhere")

-- deficit spending: allowed into debt, refused past the ceiling
money=0
ok(try_spend(100) and money==-100/1000,"spending into debt allowed")
ok(not try_spend(2000),"debt ceiling refuses")
ok(money==-100/1000,"refused spend leaves debt alone")

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
tool=2 -- road
cur={x=wx,y=wy}
apply_tool()
local b=tile(wx,wy)
ok(b==59 or b==60,"road on water builds a bridge")
ok(is_road(wx,wy),"bridge is a road")
tool=12 -- bulldoze
apply_tool()
ok(tile(wx,wy)==3,"bulldozed bridge reverts to water")
tool=7 -- power line
apply_tool()
local py=tile(wx,wy)
ok((py==61 or py==62) and conducts(wx,wy),"line on water builds a pylon")

-- pylons face along the wire crossing the river
set_tile(30,5,3)
set_tile(29,5,80)
set_tile(31,5,80)
cur={x=30,y=5}
apply_tool()
ok(tile(30,5)==62,"east-west crossing uses the horizontal pylon")
set_tile(30,5,3)
set_tile(29,5,1)
set_tile(31,5,1)
set_tile(30,4,80)
cur={x=30,y=5}
apply_tool()
ok(tile(30,5)==61,"north-south crossing uses the vertical pylon")

-- wire autotile: two adjacent lines bend toward each other
set_tile(40,30,80)
set_tile(41,30,80)
refresh_tile(40,30)
refresh_tile(41,30)
ok(tile(40,30)==82 and tile(41,30)==88,"wires autotile e/w")

-- building over power lines
set_tile(40,28,85) -- vertical wire
mode="play"
tool=2 -- road
cur={x=40,y=28}
apply_tool()
ok(tile(40,28)==53,"road over vertical line makes crossing")
set_tile(42,28,80)
tool=3 -- house zone
cur={x=42,y=28}
apply_tool()
ok(zone_kind(42,28)==1,"zone replaces a power line without bulldozing")

-- ghost preview shares the placement rules
set_tile(44,2,1)
set_tile(45,2,3)
local g1,gc1=tool_put(tools_list[2],44,2)
local g2,gc2=tool_put(tools_list[2],45,2)
ok(g1==16 and gc1==cost.road,"ghost: road on grass")
ok(g2==59 and gc2==cost.bridge,"ghost: bridge over water")
ok(tool_put(tools_list[8],45,2)==nil,"ghost: no plant on water")

-- inspect tool reports on tiles
mode="play"
tool=1 -- inspect (the default cursor)
cur={x=42,y=28} -- the house zone placed above
msg=""
apply_tool()
ok(#msg>0,"inspect reports on a zone")
cur={x=8,y=40} -- blasted to grass earlier
msg=""
apply_tool()
ok(#msg>0,"inspect reports on terrain")

-- sim speed cycles 1 -> 2 -> 4 -> 1
ok(gspd==1,"speed starts 1x")
cycle_speed()
cycle_speed()
ok(gspd==4,"speed cycles to 4x")
cycle_speed()
ok(gspd==1,"speed wraps to 1x")

printh("---- "..pass.." passed, "..failed.." failed ----")
if failed>0 then printh("test result: fail") else printh("test result: pass") end
