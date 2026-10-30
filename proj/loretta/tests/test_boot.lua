-- test_boot.lua : the real cart, with nothing stubbed but the buttons, the
-- sound and the save, from its first frame: the title, a start, some
-- seconds of running and jumping, the win at the observatory and a game
-- over, all drawn.

local held={}
function btn(i) return held[i] or false end
btnp=btn
function sfx() end
dset=sfx
music=sfx

local n=0
local game_update,game_draw=_update60,_draw

local function expect_mode(wanted)
 if mode!=wanted then
  printh("error: frame "..n.." is in mode "..tostr(mode)..", wanted "..wanted)
 end
end

function _draw() end

function _update60()
 run_frame(boot_frame)
end

function boot_frame()
 n+=1
 held={}
 if n==40 then held[4]=true end
 if n>40 and n<400 then held[1],held[4]=true,n%50<25 end
 if n>=400 and n<440 then held[3]=true end
 if n==460 then held[5]=true end
 if n==500 then
  level=#levels
  start_game()
  hero.x,hero.y=level_w-150,40
  view.x=focus_x(hero,view)
 end
 if n>500 and n<580 then held[1]=true end
 game_update()
 game_draw()
 if n==20 then dump_screen("boot_title") expect_mode("title") end
 if n==120 then dump_screen("boot_start") expect_mode("play") end
 if n==300 then dump_screen("boot_play") end
 if n==462 then dump_screen("boot_bark") end
 if n==600 then dump_screen("boot_win") expect_mode("win") end
 btnp=n==700 and function(i) return i==4 end or btn
 if n==702 then
  expect_mode("title")
  start_game()
  hearts=1
  hurt_loretta(hero,hero.x+20)
 end
 if n==790 then dump_screen("boot_over") expect_mode("over") end
 if n==800 then
  printh("ok boot")
  extcmd("shutdown")
 end
end
