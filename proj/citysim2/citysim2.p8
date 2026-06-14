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

-- glue owns _init/_update/_draw; modules never define them.
function _init()
 t=0
 cur={x=16,y=16}
 init_map()
 gen_terrain()
 update_net()
 init_agents()
 update_camera(true)
end

function _update()
 t+=1
 update_agents()
end

-- temporary colour-block render (render.lua will replace this).
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
 for y=0,gw-1 do
  for x=0,gw-1 do
   rectfill(x*4,y*4,x*4+3,y*4+3,tcol(tile(x,y)))
  end
 end
 draw_agents()
 print("citysim2",1,1,7)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
