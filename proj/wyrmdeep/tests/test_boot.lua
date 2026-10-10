-- test_boot.lua : the real cart, with nothing emptied out, from the title
-- screen: it draws the title, presses the button, and plays ten seconds
-- with every screen and the hud drawn. the other test carts use a main.lua
-- with its drawing stubbed, so this is the only one that would catch an
-- error in the title, the hud or the endings.
-- (the harness is not used: it starts the game past the title.)

local held={}
function btn(i) return held[i] or false end
btnp=btn
function sfx() end
music=sfx
dset=sfx

local n=0
local game_update,game_draw=_update,_draw

function _draw() end

function _update()
 n+=1
 held={}
 if n==10 then held[5]=true end
 if n>10 then
  held[1],held[4]=true,n%60<40
  dragon.hp=dragon.max_hp
 end
 if n==200 then end_game("dead") end
 if n==280 then
  end_game("won")
 end
 game_update()
 game_draw()
 if n==360 then
  printh("ok boot")
  extcmd("shutdown")
 end
end
