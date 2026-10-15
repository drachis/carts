-- test_boot.lua : the one test cart with the whole, real game and nothing
-- else, from its first frame: the title, a press to start, and the deal,
-- drawn and dumped. Every other replay cart includes the shared scripted
-- run (boot_script.lua) and, to fit, copies of the drawing modules with
-- unused screens emptied (make_lite.py); this one keeps its script tiny so
-- the game can grow.

local held,n={},0
function btn(i) return held[i] or false end
btnp=btn
function sfx() end
music=sfx

local game_update,game_draw=_update60,_draw
function _draw() end

function _update60()
 run_frame(function()
  n+=1
  held={[4]=n==40 or n==60}
  game_update()
  game_draw()
  if n==5 then dump_screen("boot_title") end
  if n==55 then dump_screen("boot_select") end
  if n==260 then
   if mode!="play" or #hand!=8 then printh("error: frame 260 is "..tostr(mode).." with "..#hand.." cards") end
   dump_screen("boot_play")
   printh("ok boot")
   extcmd("shutdown")
  end
 end)
end
