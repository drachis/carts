pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- headless draw-path compile check: pico8 -x tests/draw.p8
-- the logic smoke test skips the draw modules; this exercises them once so a
-- syntax/runtime error in render/inspector/hud/minimap/daynight is caught.
#include ../params.lua
#include ../version.lua
#include ../data.lua
#include ../notify.lua
#include ../sound.lua
#include ../map.lua
#include ../router.lua
#include ../net.lua
#include ../landval.lua
#include ../coverage.lua
#include ../terrain.lua
#include ../agents.lua
#include ../sim.lua
#include ../disaster.lua
#include ../tools.lua
#include ../render.lua
#include ../inspector.lua
#include ../econ.lua
#include ../hud.lua
#include ../minimap.lua
#include ../daynight.lua
#include ../save.lua

srand(1)
init_map() gen_terrain() update_net()
init_agents() init_sim() sim_seed()
init_econ() init_fire() init_log() init_tools()
-- lay a little city so the draw paths touch real state
for x=4,10 do set_tile(x,8,16) end
set_zone(5,7,1,1) set_zone(9,7,2,1)
set_tile(7,6,60) set_tile(20,20,61) set_tile(22,20,62)
update_net() ignite(5,7)
cur={x=8,y=8} select_tool("road") picking=true
camx=0 camy=0
tick=900  -- midnight-ish, so the night pal path runs

-- run each draw function; any error aborts -x with a message.
draw_world()
draw_inspector()
mapview=true draw_minimap()
draw_hud()
draw_log()
draw_toolbar()
printh("draw ok")
printh("test result: pass")
