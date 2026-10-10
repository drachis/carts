-- bot.lua : the test bot's hands. it sweeps back and forth across the block
-- it is in, low enough to plough through the buildings, breathing in bursts
-- and charging often; it turns on whatever comes near, charges anything
-- with a bubble, and climbs over a legend's lunge. it does not eat.

local heading=1

function play()
 local d=dragon
 local target,nearest
 for unit in all(units) do
  local gap=dragon_distance(unit.x,unit.cy)
  if gap<60 and unit.ai!="sheep" and (not nearest or gap<nearest) then
   target,nearest=unit,gap
  end
 end
 held={}
 if not target then
  if d.x>block_to*8-24 then heading=-1 end
  if d.x<block_from*8+40 then heading=1 end
  held[heading>0 and 1 or 0]=true
  held[2]=d.y>cam_y+92
  held[3]=d.y<cam_y+76
  held[4]=n%60<40
  held[5]=n%30==0
  return
 end
 local dx,dy=target.x-d.x,target.cy-d.y
 local ahead=abs(dx)
 held[1]=dx>0
 held[0]=dx<0
 held[2]=dy<-5
 held[3]=dy>5 and not d.grounded
 local lined_up=abs(dy)<12 and ahead<50 and ahead>12
 -- let go when out of breath, or the dragon never breathes in
 held[4]=lined_up and target.shields==0 and not d.winded and d.fire>4
 held[5]=lined_up and target.shields>0 and n%2==0
 if target.windup and target.color then
  held[2],held[3],held[4],held[5]=true,false,false,false
 end
end
