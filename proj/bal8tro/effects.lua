sparks,shake,chips_bump,mult_bump,heat={},0,0,0,0
flame_colours=split"2,8,8,9,10,7"

function burst(x,y,colour,count)
 for i=1,count do
  local angle,speed=rnd(),.5+rnd(1.5)
  add(sparks,{x=x,y=y,vx=cos(angle)*speed,vy=sin(angle)*speed-1,colour=colour,life=15+rnd(15)})
 end
end

function draw_flames()
 if heat<1 then return end
 local base=boxes_y-1
 for left=chips_x-1,mult_x-1,mult_x-chips_x do
  for x=0,17,2 do
   local height=1+rnd(2+min(heat,4)*2)
   rectfill(left+x,base-height,left+x+1,base,8)
   rectfill(left+x,base-height/2,left+x+1,base,9)
   rectfill(left+x,base-1,left+x+1,base,10)
  end
 end
end

function fan_flames()
 heat=mode=="score" and (score+hand_total(chips,mult))/goal or 0
 if heat<1 then return end
 for left=chips_x,mult_x,mult_x-chips_x do
  for i=1,min(heat,4) do
   add(sparks,{x=left+rnd(16),y=boxes_y,vx=rnd(.6)-.3,vy=-.4-rnd(.6*heat),life=6+rnd(12),flame=true})
  end
 end
end

function update_effects()
 fan_flames()
 for spark in all(sparks) do
  spark.x+=spark.vx
  spark.y+=spark.vy
  if not spark.flame then spark.vy+=.08 end
  spark.life-=1
  if spark.life<0 then del(sparks,spark) end
 end
 shake=shake>.5 and shake*.85 or 0
 chips_bump,mult_bump=max(chips_bump-.25,0),max(mult_bump-.25,0)
end

function draw_swirl(base,stripes,top)
 cls(base)
 fillp(▒)
 local time=t()
 for y=top,127,2 do
  local offset=(sin(y/96+time/10)*24+y/2+time*6)%32
  for x=offset-32,127,32 do rectfill(x,y,x+15,y+1,stripes) end
 end
 fillp()
end

function shake_camera()
 camera(rnd(shake)-shake/2,rnd(shake)-shake/2)
end

function draw_sparks()
 for spark in all(sparks) do
  local colour=spark.life<6 and 5 or spark.colour
  if spark.flame then colour=flame_colours[min(spark.life\3+1,6)] end
  line(spark.x,spark.y,spark.x-spark.vx*2,spark.y-spark.vy*2,colour)
 end
end
