function make_titan(spec)
 titan={rise=0,spots={},colour=spec.colour}
 for lane=-1,1 do
  add(titan.spots,{lane=lane,hp=spec.bars*8/3,open=-1,flash=0})
 end
 for building in all(buildings) do
  if building.t<0.45 then building.fall_at=clock+2+rnd(10) end
 end
end

function titan_x()
 return 64+sin(clock/8)*6
end

function titan_y()
 return crest_y-22-(crest_y-horizon)*0.8+(1-titan.rise)*70
end

function spot_xy(spot)
 return titan_x()+spot.lane*22,titan_y()+20-abs(spot.lane)*4
end

function open_spot(lane,beat)
 local spot=titan.spots[lane+2]
 if spot.hp>0 then spot.open=beat+2.5 end
end

function open_spot_in(lane)
 local spot=titan and titan.spots[lane+2]
 if spot and spot.hp>0 and clock<spot.open then return spot end
end

function hit_spot(spot,amount,judgement)
 spot.hp-=amount
 spot.flash=6
 local x,y=spot_xy(spot)
 burst(x,y,8,judgement.colour,2)
 if spot.hp<0.01 then
  spot.hp=0
  burst(x,y,30,9,3)
  ring(x,y,16,10)
  shake+=4
  sfx(3)
  local alive=0
  for other in all(titan.spots) do alive+=other.hp end
  if alive==0 then
   titan.dead=0
   sfx(6)
  end
 end
end

function spit(lane,beat)
 add(hazards,{lane=lane,from=beat,land=beat+2})
end

function land_spit(hazard)
 del(hazards,hazard)
 local x,y=project(hazard.lane,1)
 burst(x,y,16,11,2)
 if robot.lane==hazard.lane then hurt_robot(hazard.lane) end
end

function update_titan()
 titan.rise=min(titan.rise+1/30,1)
 for spot in all(titan.spots) do spot.flash=max(spot.flash-1) end
 if titan.dead then
  titan.dead+=1
  if titan.dead%2==0 then
   burst(titan_x()+rnd(60)-30,titan_y()+rnd(40),6,rnd{8,9,10},2)
   shake+=1
  end
  titan.rise=1-titan.dead/45
 end
end

function draw_titan()
 local x,y=titan_x(),titan_y()
 for side=-1,1,2 do
  for leg=0,2 do
   local knee_x=x+side*(30+leg*10)
   local knee_y=y+6+leg*6+sin(clock/2+leg/3)*3
   line(x+side*12,y+20,knee_x,knee_y,2)
   line(knee_x,knee_y,knee_x+side*8,y+60,2)
  end
 end
 ovalfill(x-36,y+4,x+36,y+40,titan.colour)
 for stripe=0,3 do
  oval(x-30+stripe*4,y+8+stripe*2,x+30-stripe*4,y+38-stripe*2,1)
 end
 ovalfill(x-14,y-10,x+14,y+10,titan.colour)
 circfill(x-6,y-2,2,8)
 circfill(x+6,y-2,2,8)
 line(x-8,y+8,x-3,y+14,11)
 line(x+8,y+8,x+3,y+14,11)
 for spot in all(titan.spots) do
  local sx,sy=spot_xy(spot)
  if spot.hp==0 then
   circfill(sx,sy,3,0)
  elseif clock<spot.open then
   circfill(sx,sy,5+pulse*2,spot.flash>0 and 7 or 9)
   circfill(sx,sy,3,10)
  else
   circfill(sx,sy,3,2)
   circ(sx,sy,4,1)
  end
 end
end

function draw_hazards()
 for hazard in all(hazards) do
  local x,y,scale=project(hazard.lane,1)
  if clock*4%1<0.5 then
   rectfill(x-18,y-2,x+18,y+2,8)
  end
  local along=(clock-hazard.from)/2
  local gx,gy,gscale=project(hazard.lane,along)
  circfill(gx,gy-8*gscale,5*gscale,11)
  circfill(gx,gy-8*gscale,2*gscale,7)
 end
end
