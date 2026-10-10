-- world.lua : the 2.5d projection, the scenery, and the effects.

camera_x=0
tick=0

-- world (x across, z depth, h height) to screen. x and h are in pixels as
-- they appear at the mech's line; things shrink and close up toward the
-- crest, and the crest sags at the edges so the ground reads as a hill.
function project(x,z,h)
 local near=mid(0,(far_z/z-1)/(far_z-1),1)
 local scale=0.3+0.9*near
 local sx=64+(x-camera_x)*(0.7+0.3*near)
 local sy=crest_y+74*near+(sx-64)^2/700*(1-near)-h*scale
 return sx,sy,scale
end

function draw_sky()
 cls()
 rectfill(0,16,127,60,1)
 fillp(0b1010010110100101)
 rectfill(0,30,127,37,0x1d)
 fillp()
 rectfill(0,38,127,60,13)
 for i=1,#stars,2 do
  pset(stars[i],stars[i+1],6)
 end
end

-- the city and the hill are drawn over anything still behind the crest
function draw_hill()
 for i,height in ipairs(skyline) do
  local x=i*8-24-camera_x*0.4
  local base=crest_y+(x-60)^2/700
  rectfill(x,base-height,x+6,base+3,0)
  for row=1,height\3 do
   pset(x+1+(i+row)%4,base-row*3,(i*7+row*3)%5<2 and 10 or 5)
  end
 end
 circfill(64,crest_y+350,350,0)
 rectfill(0,crest_y+12,127,127,0)

 local colour=grid_flash>0 and 13 or 1
 for z in all(grid_depths) do
  line()
  for x=-100,100,25 do
   local sx,sy=project(x,z,0)
   line(sx,sy,colour)
  end
 end
 for x=-100,100,20 do
  local x1,y1=project(x,far_z,0)
  local x2,y2=project(x,1,0)
  line(x1,y1,x2,y2,colour)
 end
end

-- sparks and rings live in screen space
function burst(x,y,count,colour,speed)
 for i=1,count do
  if #sparks<220 then
   local angle,velocity=rnd(),speed*(0.2+rnd())
   add(sparks,{
    x=x,y=y,
    vx=cos(angle)*velocity,vy=sin(angle)*velocity,
    life=15+rnd(25),colour=colour
   })
  end
 end
end

function ring(x,y,size,colour)
 add(rings,{x=x,y=y,radius=1,size=size,colour=colour})
end

function update_effects()
 for spark in all(sparks) do
  spark.x+=spark.vx
  spark.y+=spark.vy
  spark.vx*=0.93
  spark.vy*=0.93
  spark.life-=1
  if spark.life<0 then del(sparks,spark) end
 end
 for wave in all(rings) do
  wave.radius+=(wave.size-wave.radius)*0.2+0.3
  if wave.radius>=wave.size then del(rings,wave) end
 end
 shake*=0.88
 if shake<0.3 then shake=0 end
 grid_flash=max(grid_flash-1)
 white=max(white-1)
end

function draw_effects()
 for wave in all(rings) do
  circ(wave.x,wave.y,wave.radius,wave.colour)
 end
 for spark in all(sparks) do
  line(spark.x,spark.y,spark.x-spark.vx*2,spark.y-spark.vy*2,
   spark.life<6 and 5 or spark.colour)
 end
end
