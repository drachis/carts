-- test_boot.lua : the real cart, with nothing stubbed but the buttons, the
-- sound and the save, from its first frame: the title, a start, some
-- seconds of running and jumping, the win at the observatory, all
-- drawn (the game over is in test_things). kept small: this cart holds the
-- whole game, so its size is the game's real token ceiling.

local held,n,game_update,game_draw={},0,_update60,_draw
function btn(i) return held[i] end
function sfx() end
btnp,dset,music,_draw=btn,sfx,sfx,sfx

local shots={[20]="title",[120]="play",[300]="play",[600]="win"}

function _update60()
 run_frame(boot_frame)
end

function boot_frame()
 n+=1
 held={[1]=n>40 and n<400 or n>500 and n<580,[4]=n==40 or n>49 and n<400 and n%50<25}
 if n==500 then
  level=#levels
  start_game()
  hero.x,hero.y=level_w-150,40
  view.x=focus_x(hero,view)
 end
 game_update()
 game_draw()
 if shots[n] then
  dump_screen("boot_"..n)
  assert(mode==shots[n],"mode "..mode..", wanted "..shots[n])
 end
 if n==620 then
  printh("ok boot")
  extcmd("shutdown")
 end
end
