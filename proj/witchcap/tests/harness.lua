-- harness.lua : shared by the test carts that script the witch, included
-- after the game's modules. scripted buttons, silence, and no saving; the
-- cart then defines step(), called once a frame before the game's own
-- update and draw.

held={}
function btn(i) return held[i] or false end
btnp=btn
function sfx() end
dset=sfx

local game_update,game_draw=_update60,_draw

function hold(buttons)
 held={}
 for button in all(buttons) do held[button]=true end
end

function _draw() end

function _update60()
 step()
 game_update()
 game_draw()
end
