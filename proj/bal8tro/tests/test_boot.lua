-- test_boot.lua : the one test cart with the whole, real game and nothing
-- else, from its first frame: the title, a press to start, the select
-- screen, a press to select, and the deal, checked at frame 340. It dumps
-- no screens (screen.lua is left out to keep the game's room); test_deal
-- dumps the title, and the replay carts the rest. Every other replay cart
-- includes the shared scripted run (boot_script.lua) and, to fit, copies of
-- the drawing modules with unused screens emptied (make_lite.py).

local n=0
function btn(i) return i==4 and (n==120 or n==140) end
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
  if n==340 then
   printh(mode=="play" and #hand==8 and "ok boot" or "error: no deal by frame 340")
   extcmd("shutdown")
  end
 end)
end
