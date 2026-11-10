held={}
function btn(i) return held[i] or false end
btnp=btn
function sfx() end
dset=sfx
music=sfx

function danger(lane)
 for hazard in all(hazards) do
  if hazard.lane==lane and hazard.land-clock<1.4 then return true end
 end
end

function bot(frame)
 local want
 for alien in all(aliens) do
  if alien.t>-0.05 then want=alien.lane end
 end
 if not want and titan then
  for spot in all(titan.spots) do
   if open_spot_in(spot.lane) then want=spot.lane end
  end
 end
 if danger(robot.lane) or want and danger(want) then
  want=nil
  for lane=-1,1 do
   if not danger(lane) then want=lane end
  end
 end
 if want and want!=robot.lane and frame%2==0 then
  held[want<robot.lane and 0 or 1]=true
 end
end

updates_per_frame=8
