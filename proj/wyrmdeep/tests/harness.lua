-- harness.lua : shared by the test carts, included after the game's modules.
-- scripted buttons, silence, and no saving; each cart then defines step(),
-- which is called once a frame before the game's own update and draw.

held={}
function btn(i) return held[i] or false end
btnp=btn
function sfx() end
music=sfx
dset=sfx

n=0
local game_update,game_draw=_update,_draw

function hold(...)
 held={}
 for button in all{...} do held[button]=true end
end

function _draw() end

function _update()
 n+=1
 if n==1 then state="play" end
 step()
 game_update()
 game_draw()
end
