-- test_run.lua : included by test_run.p8 after the game's modules.
--
-- part one flies the whelp right through the shire, breathing and charging,
-- and checks that the screen follows and never lets it back.
-- part two is a soak: the dragon is moved to everything the level places,
-- stage by stage and at every age, to shake out errors.
--
-- it runs inside pico-8's own loop by wrapping the game's _update.

local held={}
function btn(i) return held[i] or false end
btnp=btn
function sfx() end
music=sfx
dset=sfx

local n=0
local game_update,game_draw=_update,_draw
local stops={}
local furthest=0

function _draw() end

local function hold(...)
 held={}
 for button in all{...} do held[button]=true end
end

function _update()
 n+=1
 local d=dragon
 if n==1 then
  state="play"
  for row in all(split(spawn_text,"\n")) do
   local name,x,y=unpack(split(row))
   if name!="" then add(stops,{name=name,x=x,y=y}) end
  end
 end

 if n<300 then
  hold(1,4)
  if n%40>30 then hold(1,5) end
  -- now and then it tries to turn back
  if n%100>85 then hold(0) end
  d.hp=d.max_hp
  assert(cam_x>=furthest,"the screen went back")
  assert(d.x>=cam_x,"the dragon got behind the screen")
  furthest=cam_x
  if n==150 then dump_screen("fire") end
 elseif n==300 then
  printh("the screen followed the whelp "..cam_x.." px into the shire")
  assert(cam_x>200,"the whelp did not get far")
 else
  -- the soak: a new stop every 16 frames, a new age every lap
  local step=(n-300)\16
  local stop=stops[step%#stops+1]
  if (n-300)%16==0 then
   if step%#stops==0 and step>0 and age<#ages then grow() end
   if stop.y\128!=stage then enter_stage(stop.y\128) end
   d.x,d.y,d.vx,d.vy=stop.x-12,stop.y-8,0,0
   cam_x=mid(0,d.x-44,896)
  end
  d.hp=d.max_hp
  fury=100
  advance=nil
  hold(n%4,4)
  if n%16>10 then hold(n%2,5) end
  if (n-300)%16==12 and age==1 then
   if stop.name=="sir kay" then dump_screen("shot") end
   if stop.name=="merlin" then dump_screen("aura") end
  end
  if step>=#stops*#ages then
   printh("ok run: "..#stops.." stops at "..#ages.." ages, "..kills.." kills")
   extcmd("shutdown")
  end
 end
 if state=="won" then new_game() state="play" end
 game_update()
 game_draw()
end
