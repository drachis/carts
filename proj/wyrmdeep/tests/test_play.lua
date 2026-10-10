-- test_play.lua : the shire, played by a simple bot at normal speed with no
-- cheats. it flies right, breathes on whatever is ahead, charges anything
-- with a bubble and climbs over a legend's lunge. it reports how long the
-- stage and the fight with sir kay took and how the dragon fared: the only
-- measure of pacing there is without a person at the controls.

local met_at
local lowest=999

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
 printh("ok play")
 extcmd("shutdown")
end

function step()
 local d=dragon
 play()
 lowest=min(lowest,d.hp)
 if boss and not met_at then
  met_at=n
  printh(" reached sir kay after "..n\30 .." seconds with health "..flr(d.hp).." of "..d.max_hp)
 end
 if n==240 then dump_screen("fire") end
 if met_at and n==met_at+100 then dump_screen("shot") end
 if state=="dead" then
  report("the dragon died")
 elseif advance then
  report("sir kay was devoured")
 elseif n>5400 then
  report("the bot ran out of time at x "..flr(d.x))
 end
end
