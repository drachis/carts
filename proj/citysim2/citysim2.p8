pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- citysim2 : agent/market city sim, single 8k cart.
-- see DESIGN.md (contract + budget) and ../citysim/LEARNINGS.md.
-- modules are #included in dependency order; add each as it lands.
#include params.lua
#include data.lua

-- glue owns _init/_update/_draw; modules never define them.
function _init()
 t=0
end

function _update()
 t+=1
end

function _draw()
 cls(1)
 print("citysim2: scaffolding",4,4,7)
 print("see design.md",4,12,6)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
