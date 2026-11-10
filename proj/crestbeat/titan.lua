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
 return crest_y-14-(crest_y-horizon)*0.8+(1-titan.rise)*80
end

function spot_xy(spot)
 return titan_x()+spot.lane*12,titan_y()+14-abs(spot.lane)*4
end

function draw_limb(x0,y0,x1,y1,from_radius,to_radius,colour)
 for pass=0,1 do
  for share=0,1,0.1 do
   circfill(x0+(x1-x0)*share,y0+(y1-y0)*share,
    from_radius+(to_radius-from_radius)*share-pass,pass==0 and 1 or colour)
  end
 end
end

function open_spot(lane,beat)
 local spot=titan.spots[lane+2]
 if spot.hp>0 then spot.open=beat+2.5 end
end

function lamps_lit()
 local lit=0
 for spot in all(titan.spots) do
  if spot.lit then lit+=1 end
 end
 return lit
end

function ring_lamp(spot)
 if titan.rung then return end
 if spot.lit then
  for other in all(titan.spots) do other.lit=nil end
  sfx(2)
  return
 end
 spot.lit=true
 sfx(13)
 if lamps_lit()==3 then
  titan.rung=true
  award("bells")
  score+=bell_bonus
  popup("ding! +"..bell_bonus.."0",titan_x(),titan_y()-20,10)
  ring(titan_x(),titan_y()-14,30,10)
  shake+=3
  sfx(14)
 end
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
 ring_lamp(spot)
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
   award("titans")
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
 local x,y,colour=titan_x(),titan_y(),titan.colour
 local back,beat=(x-64)*0.4,clock%1
 pal(3,colour)
 local flap=sin(clock/2)
 for side=-1,1,2 do
  local shoulder_x,shoulder_y=x-back+side*14,y+2
  local wrist_x,wrist_y=shoulder_x+side*12,shoulder_y-12+flap*6
  local tips={}
  for finger=0,3 do
   add(tips,{wrist_x+side*(4+finger*7),wrist_y-14+finger*9-flap*(3-finger)*3})
  end
  for finger=1,3 do
   local from,to=tips[finger],tips[finger+1]
   for along=0,1,0.03 do
    local scallop=1+sin(along/2)*0.3
    line(wrist_x,wrist_y,wrist_x+(from[1]+(to[1]-from[1])*along-wrist_x)*scallop,
     wrist_y+(from[2]+(to[2]-from[2])*along-wrist_y)*scallop,2)
   end
  end
  for tip in all(tips) do line(wrist_x,wrist_y,tip[1],tip[2],colour) end
  draw_limb(shoulder_x,shoulder_y,wrist_x,wrist_y,3,2,colour)
 end
 for side=-1,1,2 do
  local lift=flr(clock)%2==(side+1)/2 and (1-beat)*(1-beat)*6 or 0
  local hip_x,foot_x,foot_y=x+side*9,x+side*15,y+45-lift
  local knee_x,knee_y=x+side*17,y+35-lift/2
  draw_limb(hip_x,y+22,knee_x,knee_y,7,5,colour)
  draw_limb(knee_x,knee_y,foot_x,foot_y,5,4,colour)
  sspr(88,72,16,8,foot_x-8,foot_y-3)
 end
 local bob=pulse>0.5 and 1 or 0
 sspr(0,96,40,32,x-20,y-4+bob)
 for side=-1,1,2 do
  local swing=sin(clock/2+side/4)*3
  local hand_x,hand_y=x+side*25,y+22+swing
  draw_limb(x+side*17,y+2+bob,x+side*28,y+12,5,4,colour)
  draw_limb(x+side*28,y+12,hand_x,hand_y,4,3,colour)
  sspr(80,72,8,8,hand_x-4,hand_y-1)
 end
 local spat
 for hazard in all(hazards) do
  if clock-hazard.from<1 then spat=true end
 end
 sspr(spat and 64 or 40,96,24,20,x-12+(robot.x-64)*0.05,y-21+bob*2)
 pal()
 for spot in all(titan.spots) do
  local lamp_x=x+spot.lane*7
  circfill(lamp_x,y+1,2,spot.lit and 10 or 1)
  circ(lamp_x,y+1,2,spot.lit and 7 or 5)
 end
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
  local along=(clock-hazard.from)/2
  if clock*4%1<0.5 then rectfill(x-18,y-2,x+18,y+2,8) end
  print(ceil(hazard.land-clock),x-1,y-9,8)
  local gx,gy,gscale=project(hazard.lane,along)
  circfill(gx,gy-8*gscale,5*gscale,11)
  circfill(gx,gy-8*gscale,2*gscale,7)
 end
end
