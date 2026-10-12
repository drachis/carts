-- test_city.lua : the city drawn at four states of health, with nothing on
-- the hill, for screenshots (city_100.png .. city_10.png), and what a full
-- screen of towers costs. it checks the drawing runs at every state; whether
-- the damage reads is for looking at the pictures.
--
-- then, at the capitol where towers are tallest, it rolls the city on
-- and counts the tower pixels in a strip at the bottom of the screen
-- every frame. a row of towers leaving the bottom should slide out of
-- that strip; if the count ever falls by more than 15% in one frame,
-- the towers popped out, and the test fails.

function btn() return false end
btnp=btn
function sfx() end
music=sfx
function update_waves() end

local n=0
local game_update,game_draw=_update60,_draw
local states={100,70,40,10}
-- a foe parked behind the crest keeps the city rolling for the pictures
local parked
local before,worst_drop=nil,0

function _draw() end

-- how many pixels in the bottom strip are not grass, road or tree
function towers_at_bottom()
 local count=0
 for y=100,127,3 do
  for x=0,127,2 do
   local colour=pget(x,y)
   if colour!=3 and colour!=5 and colour!=11 then count+=1 end
  end
 end
 return count
end

function _update60()
 n+=1
 if n==1 then
  reset()
  state="play"
  parked=spawn_foe(enemy_specs.skitter,0,far_z+2,0)
 end
 local shot=n\40+1
 city=states[shot] or 100
 parked.z=far_z+2
 -- the suburbs untouched, then the capitol at three states of ruin
 wave=shot==1 and 1 or 8
 -- the mech is moved aside so it is not counted as a tower
 if n>170 then player.x=-200 end
 game_update()
 game_draw()
 if n%40==30 and states[shot] then
  printh("city at "..city..": cpu "..stat(1).." fps "..stat(7))
  dump_screen("city_"..city)
 end
 if n>180 then
  local now=towers_at_bottom()
  if before and before>60 then
   worst_drop=max(worst_drop,(before-now)/before)
  end
  before=now
 end
 if n==460 then
  printh("largest one-frame loss of towers at the bottom: "..flr(worst_drop*100).."%")
  if worst_drop>0.15 then
   printh("error: towers popped out at the bottom of the screen")
  end
  printh("ok city")
  extcmd("shutdown")
 end
end
