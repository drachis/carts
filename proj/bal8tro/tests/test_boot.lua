-- test_boot.lua : the real game from its first frame: Balatro's intro
-- (intro.lua, 834 frames), the title, a press to start, the select screen,
-- a press to select, and the deal, checked at frame 1180. Screens the boot
-- never reaches are emptied (make_lite.py, boot). It dumps the intro at
-- the moments balatro_ref's screenshots show (boot_intro_<frame>) and the
-- title after it. Every other replay cart
-- includes the shared scripted run (boot_script.lua) and, to fit, copies of
-- the drawing modules with unused screens emptied (make_lite.py).

local n=0
function btn(i) return i==4 and (n==960 or n==980) end
btnp=btn
function sfx() end
music=sfx

local game_update,game_draw=_update60,_draw
function _draw() end

function _update60()
 run_frame(function()
  n+=1
  game_update()
  game_draw()
  for frame in all(split"90,200,330,480,640,720,800,860,950,1060") do
   if n==frame then dump_screen("boot_intro_"..n) end
  end
  if n==1180 then
   printh(mode=="play" and #hand==8 and "ok boot" or "error: no deal by frame 1180")
   extcmd("shutdown")
  end
 end)
end
