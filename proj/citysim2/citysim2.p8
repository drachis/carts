pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- citysim2 : agent/market city sim, single 8k cart.
-- see DESIGN.md (contract + budget) and ../citysim/LEARNINGS.md.
-- modules are #included in dependency order; add each as it lands.
#include params.lua
#include data.lua
#include map.lua
#include router.lua
#include net.lua
#include terrain.lua
#include agents.lua
#include sim.lua
#include tools.lua

-- glue owns _init/_update/_draw; modules never define them.
function _init()
 init_map()
 gen_terrain()
 update_net()
 init_agents()
 init_sim()
 sim_seed()
 init_tools()
 update_camera(true)
end

function _update()
 update_tools()
 update_sim()
 update_agents()
end

-- temporary colour-block render (8px tiles, camera-relative; render.lua replaces)
function tcol(s)
 if s==0 then return 1 end
 if s==2 then return 13 end
 if s>=16 and s<=31 then return 5 end
 if s>=48 and s<=51 then return 11 end
 if s>=52 and s<=55 then return 12 end
 if s>=56 and s<=59 then return 10 end
 return 3
end

function _draw()
 cls(0)
 camera(camx,camy)
 for y=0,gw-1 do
  for x=0,gw-1 do
   rectfill(x*8,y*8,x*8+7,y*8+7,tcol(tile(x,y)))
  end
 end
 draw_agents()
 draw_cursor()
 camera()
 print("pop "..pop.." jobs "..jobs,1,1,7)
 print(tools_list[tool],1,121,10)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
