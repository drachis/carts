-- test_scenes.lua : two pictures of each of the level's eight sections
-- (scene_1 and scene_2 are the first), with Loretta standing in each, for looking at the set pieces. it checks nothing
-- but that each draws without an error.

function sfx() end
music=sfx
dset=sfx

local section,game_draw=0,_draw

function _update60()
 run_frame(function()
  if section==0 then
   start_level()
   mode="play"
  end
  if section<16 then
   hero=new_loretta(section*128+40,0)
   for i=1,40 do update_loretta(hero,0) end
   view.x=section*128
   game_draw()
   section+=1
   dump_screen("scene_"..section)
  else
   printh("ok scenes")
   extcmd("shutdown")
  end
 end)
end

function _draw() end
