-- test_boot.lua : the real cart, nothing stubbed but input and sound, from
-- its first frame: the title, a start, a bot holding fire and pacing, the
-- shop, the boss arriving and dying, both endings and a restart, all drawn.

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
 if n==20 or n==2200 then held[4]=true end
 if n>20 and n<2100 then
  held[n\120%2]=true
  held[4]=n%90<60
  held[5]=n%200==0
 end
 if n==1500 then open_shop() end
 if n==1700 then
  state="play"
  spawn_group("tyrant",1)
 end
 if n==1800 then
  boss.z=2.5
  charge=alpha_cost
  held[5]=true
 end
 if n==1830 then hurt_foe(boss,9999) end
 if n==2100 then end_game(false) end
 if n==2300 then end_game(true) end
 game_update()
 game_draw()
 if n==5 then dump_screen("boot_title") end
 if n==880 then dump_screen("boot_play") end
 if n==1520 then dump_screen("boot_shop") end
 if n==1825 then dump_screen("boot_boss") end
 if n==1900 then dump_screen("boot_dying") end
 if n==2150 then dump_screen("boot_lost") end
 if n==2350 then dump_screen("boot_won") end
 if n==2400 then
  printh("ok boot")
  extcmd("shutdown")
 end
end
