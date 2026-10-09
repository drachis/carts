-- test_run.lua : included by test_run.p8 after the game's modules.
--
-- part one flies the whelp to the lair door and burns through it.
-- part two is a soak: the dragon is moved to everything the level places,
-- at every age, breathing and charging, to shake out errors.
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

 if n<160 then
  hold(1)
  if n>40 then hold(1,4) end
  if n==70 then dump_screen("fire") end
 elseif n==160 then
  printh("out of the lair at x "..d.x.." (the door was at 104)")
  assert(d.x>112,"the whelp did not burn its way through the lair door")
 else
  -- the soak: a new stop every 16 frames, a new age every lap
  local step=(n-160)\16
  local stop=stops[step%#stops+1]
  if (n-160)%16==0 then
   if step%#stops==0 and step>0 and age<#ages then grow() end
   lock_arena()
   d.x,d.y,d.vx,d.vy=stop.x,stop.y-8,0,0
  end
  d.hp=d.max_hp
  fury=100
  hold(n%4,4)
  if n%16>10 then hold(n%2,5) end
  if (n-160)%16==10 and stop.name=="sir kay" and age==1 then dump_screen("shot") end
  if step>=#stops*#ages then
   printh("ok run: "..#stops.." stops at "..#ages.." ages, "..kills.." kills")
   extcmd("shutdown")
  end
 end
 if state=="won" then new_game() state="play" end
 game_update()
 game_draw()
end
