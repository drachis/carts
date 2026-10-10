-- test_run.lua : included by test_run.p8 after the game's modules.
--
-- part one is a playthrough of the shire by a simple bot, at normal speed
-- and with no cheats: it flies right, breathes on whatever is ahead, and
-- charges anything with a bubble. it reports how long the stage and the
-- fight with sir kay took and how the dragon fared, which is the only
-- measure of pacing there is without a person at the controls.
-- part two is a soak: the dragon is moved to everything the level places,
-- stage by stage and at every age, healed throughout, to shake out errors.
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
local soak_from,met_at,lowest

function _draw() end

local function hold(...)
 held={}
 for button in all{...} do held[button]=true end
end

local function play()
 local d=dragon
 local target,nearest
 for unit in all(units) do
  local gap=dragon_distance(unit.x,unit.cy)
  if on_screen(unit.x,unit.y,0) and unit.ai!="sheep" and (not nearest or gap<nearest) then
   target,nearest=unit,gap
  end
 end
 held={}
 if not target then
  held[1]=true
  held[4]=n%60<30
  return
 end
 local dx,dy=target.x-d.x,target.cy-d.y
 held[1]=dx>28
 held[0]=dx<10
 held[2]=dy<-5
 held[3]=dy>5 and not d.grounded
 local lined_up=abs(dy)<12 and dx>0 and dx<50
 -- let go when out of breath, or the dragon never breathes in
 held[4]=lined_up and target.shields==0 and not d.winded and d.fire>4
 held[5]=lined_up and target.shields>0 and n%2==0
 -- climb over a lunge
 if target.windup and target.color then
  held[2],held[3],held[4],held[5]=true,false,false,false
 end
end

local function report(outcome)
 printh("the shire, played by the bot: "..outcome.." after "..n\30 .." seconds")
 if met_at then
  printh(" the fight with sir kay lasted "..(n-met_at)\30 .." seconds")
 end
 printh(" lowest health "..flr(lowest).." of "..dragon.max_hp..", "..kills.." kills, "..hoard.." gold, size "..dragon.size)
 soak_from=n
end

function _update()
 n+=1
 local d=dragon
 if n==1 then
  state="play"
  lowest=d.hp
  for row in all(split(spawn_text,"\n")) do
   local name,x,y=unpack(split(row))
   if name!="" then add(stops,{name=name,x=x,y=y}) end
  end
 end

 if not soak_from then
  play()
  lowest=min(lowest,d.hp)
  if boss and not met_at then
   met_at=n
   printh(" reached sir kay after "..n\30 .." seconds with health "..flr(d.hp).." of "..d.max_hp)
  end
  if n==240 then dump_screen("fire") end
  if met_at and n==met_at+200 then dump_screen("shot") end
  if state=="dead" then
   report("the dragon died")
   respawn()
  elseif advance then
   report("sir kay was devoured")
  elseif n>5400 then
   report("the bot ran out of time at x "..flr(d.x))
  end
 else
  -- the soak: a new stop every 16 frames, a new age every lap
  local step=(n-soak_from)\16
  local stop=stops[step%#stops+1]
  if (n-soak_from)%16==0 then
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
  -- gawain is held in his wind-up, to photograph it
  if stop.name=="sir gawain" and boss then boss.clock=150 end
  if (n-soak_from)%16==12 and step<#stops then
   if stop.name=="sir gawain" then dump_screen("windup") end
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
