-- scene_main.lua : stands in for main.lua in test_scenes, which only draws
-- the play screen: the same start_level and the same drawing order, so the
-- game's screens and modes do not count against the cart's 8192 tokens.
-- keep it the same as main.lua's start_level and _draw.

function game_over() end
function win() end

function start_level()
 load_level()
 hearts,respawn,mode_frames=max_hearts,0,0
 barks,puffs,floaters={},{},{}
 hero,respawn_x,respawn_y=new_loretta(16,82),16,82
 view=new_camera(hero)
end

function _draw()
 cls()
 local cam=camera_x()
 draw_backdrop(cam)
 camera(cam,-view_drop)
 draw_things(1)
 draw_level(cam)
 draw_things()
 draw_barks()
 draw_loretta(hero)
 draw_effects()
 camera()
end

function _init()
 set_palette()
 level,score,coins=1,0,0
 start_level()
end
