-- test_boot.lua : the real cart, nothing stubbed but input and sound, from
-- its first frame: the title, a start, fifteen seconds of a bot holding
-- fire and pacing, both endings and a restart, all drawn.

local held={}
function btn(i) return held[i] or false end
btnp=btn
function sfx() end
music=sfx

local n=0
local game_update,game_draw=_update60,_draw

function _draw() end

function _update60()
 n+=1
 held={}
 if n==20 or n==1000 then held[4]=true end
 if n>20 and n<900 then
  held[n\120%2]=true
  held[4]=n%90<60
  held[5]=n%200==0
 end
 if n==900 then end_game(false) end
 if n==1100 then end_game(true) end
 game_update()
 game_draw()
 if n==5 then dump_screen("boot_title") end
 if n==880 then dump_screen("boot_play") end
 if n==950 then dump_screen("boot_lost") end
 if n==1150 then dump_screen("boot_won") end
 if n==1200 then
  printh("ok boot")
  extcmd("shutdown")
 end
end
