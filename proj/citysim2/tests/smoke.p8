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

printh("---- "..pass.." passed, "..fail.." failed ----")
if fail>0 then printh("test result: fail") else printh("test result: pass") end
