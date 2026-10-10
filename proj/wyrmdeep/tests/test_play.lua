-- test_play.lua : the shire, played by a simple bot at normal speed with no
-- cheats. it flies right, breathes on whatever is ahead, charges anything
-- with a bubble and climbs over a legend's lunge. it reports how long the
-- stage and the fight with sir kay took and how the dragon fared: the only
-- measure of pacing there is without a person at the controls.

local met_at
local lowest=999


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
