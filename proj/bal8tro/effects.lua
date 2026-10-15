sparks,shake,chips_bump,mult_bump={},0,0,0

function burst(x,y,colour,count)
 for i=1,count do
  local angle,speed=rnd(),.5+rnd(1.5)
  add(sparks,{x=x,y=y,vx=cos(angle)*speed,vy=sin(angle)*speed-1,colour=colour,life=15+rnd(15)})
 end
end

function update_effects()
 for spark in all(sparks) do
  spark.x+=spark.vx
  spark.y+=spark.vy
  spark.vy+=.08
  spark.life-=1
  if spark.life<0 then del(sparks,spark) end
 end
 shake=shake>.5 and shake*.85 or 0
 chips_bump,mult_bump=max(chips_bump-.25,0),max(mult_bump-.25,0)
end

function shake_camera()
 camera(rnd(shake)-shake/2,rnd(shake)-shake/2)
end

function draw_sparks()
 for spark in all(sparks) do
  line(spark.x,spark.y,spark.x-spark.vx*2,spark.y-spark.vy*2,spark.life<6 and 5 or spark.colour)
 end
end
