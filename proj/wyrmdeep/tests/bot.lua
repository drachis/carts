-- bot.lua : the test bot's hands. it flies right, breathes on whatever is
-- ahead, charges anything with a bubble and climbs over a legend's lunge.
-- it does not eat, and it does not dodge ordinary soldiers.

function play()
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
 held[0]=dx<20
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
