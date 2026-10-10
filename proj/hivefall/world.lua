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

-- the next corner of a grid line. a shockwave pushes the corners it is
-- passing outward, so the grid ripples.
function grid_point(x,z,colour)
 local sx,sy=project(x,z,0)
 for wave in all(rings) do
  if wave.warp then
   local dx,dy=sx-wave.x,sy-wave.y
   local distance=abs(dx)+abs(dy)+1
   local push=max(8-abs(distance*0.7-wave.radius))*wave.warp/distance
   sx+=dx*push
   sy+=dy*push
  end
 end
 line(sx,sy,colour)
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
  for x=-100,100,20 do grid_point(x,z,colour) end
 end
 for x=-100,100,20 do
  line()
  for z in all(grid_depths) do grid_point(x,z,colour) end
 end
end

-- sparks, rings and popups live in screen space. `fall` is gravity.
function burst(x,y,count,colour,speed,fall)
 for i=1,count do
  if #sparks<240 then
   local angle,velocity=rnd(),speed*(0.2+rnd())
   add(sparks,{
    x=x,y=y,
    vx=cos(angle)*velocity,vy=sin(angle)*velocity,
    life=15+rnd(25),colour=colour,fall=fall or 0
   })
  end
 end
end

-- `warp` is how hard the ring pushes the grid, if it does
function ring(x,y,size,colour,warp)
 add(rings,{x=x,y=y,radius=1,size=size,colour=colour,warp=warp})
end

function update_effects()
 for spark in all(sparks) do
  spark.x+=spark.vx
  spark.y+=spark.vy
  spark.vx*=0.93
  spark.vy=spark.vy*0.93+spark.fall
  spark.life-=1
  if spark.life<0 then del(sparks,spark) end
 end
 for wave in all(rings) do
  wave.radius+=(wave.size-wave.radius)*0.12+0.4
  if wave.radius>=wave.size then del(rings,wave) end
 end
 for popup in all(popups) do
  popup.y-=0.4
  popup.life-=1
  if popup.life<0 then del(popups,popup) end
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
 for popup in all(popups) do
  print(popup.text,popup.x-#popup.text*2,popup.y,popup.life%6<3 and 7 or 10)
 end
end
