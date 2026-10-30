-- test_scenes.lua : two pictures of each of the sixteen chunks, played as
-- one level in chunk order (scene_1 and scene_2 are chunk 0), with
-- Loretta standing in each, for looking at the set pieces; of those it
-- checks only that each draws.
-- then it checks that the backdrop's dither stays put on the screen as
-- the camera moves (test_body had no room for it).

function sfx() end
music=sfx
dset=sfx

local section,game_draw=0,_draw

function _update60()
 run_frame(function()
  if section==0 then
   levels[1],level=split"0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15",1
   start_level()
   mode="play"
  end
  if section<32 then
   hero=new_loretta(section*128+40,0)
   for i=1,40 do update_loretta(hero,0) end
   view.x=section*128
   game_draw()
   section+=1
   dump_screen("scene_"..section)
  else
   local function backdrop_row(cam_x,shift)
    view.x=cam_x
    camera()
    draw_backdrop(cam_x)
    local row=""
    for y in all{25,122} do
     for x=8,23 do row..=pget(x+shift,y) end
    end
    return row
   end
   local still,moved,shifted=backdrop_row(300,0),backdrop_row(301,0),backdrop_row(300,1)
   printh((still==moved and still!=shifted and "pass: " or "error: ").."the backdrop's dither stays put on the screen as the camera moves (same at camera 300 and 301: "..tostr(still==moved)..", the rows are dithered: "..tostr(still!=shifted)..")")
   printh("ok scenes")
   extcmd("shutdown")
  end
 end)
end

function _draw() end
