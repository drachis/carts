pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- headless systems/feel tests: pico8 -x tests/test_feel.p8
-- (core sim tests live in test_sim.p8)
#include ../params.lua
#include ../map.lua
#include ../power.lua
#include ../econ.lua
#include ../landval.lua
#include ../network.lua
#include ../tools.lua
#include ../traffic.lua
#include ../disaster.lua
#include ../savegame.lua
#include ../achievements.lua
#include ../daynight.lua
#include ../effects.lua
-- ui.lua intentionally omitted: drawing is trusted (see DESIGN.md "what we
-- test, what we trust"); ui logic worth testing (mfmt) lives in econ.lua.

-- growth.lua not included (token budget); stub what others touch
function init_growth()
 pop=0
 jobs=0
 demand={r=0,c=0,i=0}
 milestone=0
 city_name="testville"
end

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

-- recreate sprite flags as bitfields (no __gff__ in this cart):
-- bit0 road, bit1 zone, bit2 conducts, bit3 buildable (matches gen_gfx)
fset(1,8) fset(2,8) fset(4,8)
for i=16,31 do fset(i,1) end
for i=32,43 do fset(i,6) end
fset(48,4)
for i=53,54 do fset(i,5) end
fset(59,1) fset(60,1) fset(61,4) fset(62,4)
for i=64,66 do fset(i,4) end
for i=80,95 do fset(i,4) end

srand(1)
init_map()
init_tools()
init_power()
init_econ()
init_growth()
init_landval()
init_net()
init_disaster()
init_achv()
init_fx()
frame=0

-- traffic v2: commuters need a home, a workplace, and a road between
for x=5,35 do set_tile(x,20,16) end
for x=5,35 do refresh_tile(x,20) end
for x=5,18 do
 set_zone(x,19,1,2)
 set_zone(x,21,1,2)
end
for x=25,35 do
 set_zone(x,19,2,2)
 set_zone(x,21,2,2)
end
for x=10,14 do set_tile(x,10,16) end
for x=10,14 do refresh_tile(x,10) end
local pth=tr_path(5,20,35,20)
ok(pth~=nil and #pth==31,"tr_path finds the straight route")
ok(tr_path(5,20,12,10)==nil,"tr_path returns nil when disconnected")
pop=100
local spawned,on_road=false,true
for f=1,19200 do
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

-- fire burns a zone: tile stays visible, tracked in dz_fmap
set_zone(12,11,1,2)
dz_ignite(12,11)
ok(dz_fmap[12+11*64],"ignite records burning tile")
for f=1,340 do
 frame=19300+f
 update_disaster()
end
ok(tile(12,11)==96,"burned zone becomes r-rubble (sprite 96)")

-- fire stations: coverage requires power
set_tile(44,29,48)   -- plant adjacent to station
update_power()
set_tile(44,30,64)   -- station (now powered via plant)
update_power()
ok(dz_covered(44,32),"powered station covers nearby tiles")
ok(not dz_covered(20,5),"no coverage far away")

-- fire engine: dispatches from a station and arrives to spray
init_disaster()
set_tile(10,9,64) -- station beside the road row at y=10
set_zone(14,11,1,2)
frame=1
dz_ignite(14,11)
ok(dz_eng~=nil,"fire engine dispatched")
local arrived=false
for i=1,600 do
 update_disaster()
 if dz_eng and dz_eng.spray>0 then arrived=true end
end
ok(arrived,"engine arrived and sprayed")
draw_engine()

-- day/night phases
frame=0
ok(dn_phase()=="day","cycle starts in daytime")
frame=flr(p.day_frames*0.75)
ok(dn_phase()=="night","late cycle is night")
dn_dark()
pal()
draw_window_lights(5,5,1,2)
frame=0

-- achievements
pop=150
for i=1,10 do
 frame=128
 update_achv()
end
ok(achv_count()>=1,"population achievement awarded")
ok(achv_total()==8,"eight achievements defined")

-- particles spawn and expire
init_fx()
add_fx(5,5,4,0.5,0,20,7,10)   -- sparkle
add_fx(5,5,3,0.2,-0.3,25,5,6) -- debris smoke
add_smoke(5,5)                  -- stack smoke
ok(#fx_list>=8,"fx particles spawn")
for i=1,60 do update_fx() end
ok(#fx_list==0,"fx particles expire")
draw_fx()

-- save / load / new city
money=777 month=3 year=1963 tax_rate=2 milestone=50
save_city()
money=1 month=1 year=1950 milestone=0
load_city()
ok(money==777 and month==3 and year==1963 and milestone==50,
   "save/load restores scalars")
ok(mget(49,0)==42,"save magic present")
new_city()
ok(money==2 and pop==0,"new city resets the books")

printh("---- "..pass.." passed, "..failed.." failed ----")
if failed>0 then printh("test result: fail") else printh("test result: pass") end
