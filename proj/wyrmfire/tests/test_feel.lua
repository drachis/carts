-- test_feel.lua : a pacing map. included by test_feel.p8 in place of
-- test_run.lua; ../../wyrmdeep/feel_map.py runs it and its twin there.
--
-- the scripted dragon of the soak (it heads for a boss, else the nearest
-- ward, then the goal, breathing in bursts and charging now and then) plays
-- for thirty seconds, unhealed, or until it dies. once a
-- second it prints: enemies on screen, kills so far, tiles burning on
-- screen, shots in the air, its health, and where it is.

local held={}
function btn(i) return held[i] end
btnp=btn
function sfx() end
music=sfx
dset=sfx

local function objective()
 if boss then return boss end
 local best,nearest=goal,32000
 for building in all(buildings) do
  local distance=dragon_distance(building.x,building.y)
  if building.home.wards>0 and building.ward and distance<nearest then
   best,nearest=building,distance
  end
 end
 return best
end

local n=0
local game_update,game_draw=_update,_draw

function _draw() end

function _update()
 n+=1
 local target=objective()
 held[0],held[1]=target.x<dragon.x-8,target.x>dragon.x+8
 held[2],held[3]=target.y<dragon.y-8,target.y>dragon.y+8
 held[4]=n%90<60
 held[5]=n%50==0
 state="play"
 game_update()
 game_draw()


 if n%30==0 then
  local seen,burning=0,0
  for unit in all(units) do
   if on_screen(unit.x,unit.y,0) then seen+=1 end
  end
  for ty=cam_y\8,cam_y\8+15 do
   for tx=cam_x\8,cam_x\8+15 do
    if burning_at(tx,ty) then burning+=1 end
   end
  end
  printh("feel "..n\30 ..","..seen..","..kills..","..burning..","..#shots..","..flr(dragon.hp)..","..flr(dragon.x)..","..flr(dragon.y)..",0")
 end
 if state!="play" or n==900 then
  printh("ok feel")
  extcmd("shutdown")
 end
end
