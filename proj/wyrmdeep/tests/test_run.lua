-- test_run.lua : included by test_run.p8 after the game's modules.
--
-- part one measures the whelp's movement on the lair floor (jump height,
-- glide reach), which level.py's reachability check takes on trust.
-- part two burns the lair door and walks out.
-- part three is a soak: the dragon is moved to everything the level
-- places, at every age, breathing and charging, to shake out errors.
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
local floor_y,apex_y,launch_x,land_x
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
  floor_y=d.y
  apex_y=d.y
  for row in all(split(spawn_text,"\n")) do
   local name,x,y=unpack(split(row))
   if name!="" then add(stops,{name=name,x=x,y=y}) end
  end
 end

 -- no horde until the measurements are done
 if n<330 then muster=99 end
 if n<60 then
  -- a full jump straight up
  hold()
  if n>5 and n<40 then hold(2) end
  apex_y=min(apex_y,d.y)
 elseif n==60 then
  printh("jump height "..(floor_y-apex_y).." px")
  launch_x=d.x
 elseif n<160 then
  -- a running jump held into a glide, back to the floor
  hold(1)
  if n>62 then hold(1,2) end
  if n>70 and d.grounded and not land_x then
   land_x=d.x
   printh("jump and glide reach "..(land_x-launch_x).." px on the flat")
  end
  if land_x then hold() end
 elseif n<330 then
  -- to the door, and burn it
  hold(1)
  if n>230 then hold(1,4) end
  if n==260 then dump_screen("fire") end
 elseif n==330 then
  printh("out of the lair at x "..d.x.." (the door was at 232)")
  assert(d.x>232,"the whelp did not burn its way through the lair door")
 else
  -- the soak: a new stop every 40 frames, a new age every lap
  local step=(n-330)\16
  local stop=stops[step%#stops+1]
  if (n-330)%16==0 then
   if step%#stops==0 and step>0 and age<#ages then grow() end
   d.x,d.y,d.vx,d.vy=stop.x,stop.y-8,0,0
  end
  d.hp=d.max_hp
  fury=100
  hold(n%3,4)
  if n%16>10 then hold(n%2,5) end
  if (n-330)%16==10 and stop.name=="sir kay" and age==1 then dump_screen("shot") end
  if step>=#stops*#ages then
   printh("ok run: "..#stops.." stops at "..#ages.." ages, "..kills.." kills")
   extcmd("shutdown")
  end
 end
 if state=="won" then new_game() state="play" end
 game_update()
 game_draw()
end
