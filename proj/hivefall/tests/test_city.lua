-- test_city.lua : the city drawn at four states of health, with nothing on
-- the hill, for screenshots (city_100.png .. city_10.png), and what a full
-- screen of towers costs. it checks the drawing runs at every state; whether
-- the damage reads is for looking at the pictures.

function btn() return false end
btnp=btn
function sfx() end
music=sfx
function update_waves() end

local n=0
local game_update,game_draw=_update60,_draw
local states={100,70,40,10}

function _draw() end

function _update60()
 n+=1
 if n==1 then
  reset()
  state="play"
 end
 local shot=n\40+1
 city=states[shot] or 10
 game_update()
 game_draw()
 if n%40==30 and states[shot] then
  printh("city at "..city..": cpu "..stat(1))
  dump_screen("city_"..city)
 end
 if n==170 then
  printh("ok city")
  extcmd("shutdown")
 end
end
