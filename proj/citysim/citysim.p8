pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- citysim : a tiny rci city builder
-- see design.md for the module contract

#include map.lua
#include power.lua
#include growth.lua
#include econ.lua
#include tools.lua
#include ui.lua

function _init()
 frame=0
 init_map()
 init_tools()
 init_power()
 init_econ()
 init_growth()
 update_power()
end

function _update()
 frame+=1
 update_tools()
 update_growth()
 update_econ()
 if frame%16==0 then update_power() end
end

function _draw()
 cls()
 draw_world()
 draw_hud()
 if mode=="menu" then draw_menu() end
 if mode=="map" then draw_minimap() end
 draw_msg()
end
