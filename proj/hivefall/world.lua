-- world.lua : the 2.5d projection, the scenery, and the effects.

camera_x=0
tick=0
-- how far the mech has advanced over the city, wrapping every five deep
travel=0
scroll_rate=0

-- world (x across, z depth, h height) to screen. x and h are in pixels as
-- they appear at the mech's line; things shrink and close up toward the
-- crest, and the crest sags at the edges so the ground reads as a hill.
function project(x,z,h)
 local near=max((far_z/z-1)/(far_z-1))
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

-- the hill is drawn over anything still behind its crest. its slope is
-- the city, sliding toward the mech as it advances and on under it to the
-- bottom of the screen. streets run along every second grid line, so the
-- cube houses stand in blocks of four. the more of the swarm has got
-- through, the more of the houses are burnt-out wrecks.
function draw_hill()
 circfill(64,crest_y+350,350,0)
 rectfill(0,crest_y+12,127,127,0)

 local colour=grid_flash>0 and 13 or 1
 local slide=travel/0.625%1
 local turn=travel\0.625
 local depths={far_z}
 for k=8,0,-1 do
  local z=1+(k-slide)*0.625
  if (k+turn)%2==0 and z>0.9 then add(depths,z) end
 end
 add(depths,0.9)
 for z in all(depths) do
  line()
  for x=-100,100,20 do grid_point(x,z,colour) end
 end
 for x=-100,100,40 do
  line()
  for z in all(depths) do grid_point(x,z,colour) end
 end

 for k=8,-1,-1 do
  local row=(k+turn)%8
  local front=1+(k-slide)*0.625
  local back=min(front+0.625,far_z)
  -- a gap for the street on the block's outer sides only
  if row%2==0 then front+=0.12 else back-=0.12 end
  front=max(front,0.9)
  if back>front then
   for column=0,9 do
    local left=column*20-100
    local right=left+20
    if column%2==0 then left+=4 else right-=4 end
    local seed=(column*7+row*13)%20
    local wrecked=seed<(100-city)/5
    local height=wrecked and 2 or 4+seed%9
    local x1,top,scale=project(left,front,height)
    local x2=project(right,front,height)
    local _,far_top=project(left,back,height)
    local roof,wall=1,5
    if wrecked then roof,wall=2,0 end
    if city_flash>0 and k<3 and tick%4<2 then roof,wall=8,2 end
    rectfill(x1,far_top,x2,top,roof)
    rectfill(x1,top+1,x2,top+height*scale,wall)
    if wrecked then
     pset(x1+seed%4,far_top+1,(tick\6+seed)%3==0 and 9 or 8)
     pset(x2-seed%3,top-1,(tick\5+seed)%3==0 and 10 or 0)
     if rnd()<0.01 then
      burst((x1+x2)/2,far_top,1,rnd{8,9,6},0.5,-0.04)
     end
    elseif scale>0.5 then
     -- a lit window, and something on the roof to fly over
     pset(x1+1+seed%3,top+2,10)
     rectfill(x1+2,far_top+2,x1+2+scale*3,far_top+1+scale*2,13)
    end
   end
  end
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

-- a fireball: it swells white to red over a quarter second, then the
-- spot burns for a moment more. size is its radius on screen.
function blast(x,y,size)
 add(blasts,{x=x,y=y,size=size,age=0})
end

function update_effects()
 for fire in all(blasts) do
  fire.age+=1
  if fire.age%2==0 then
   burst(fire.x+rnd(fire.size)-fire.size/2,fire.y+rnd(fire.size/2),
    1,rnd{8,9,10},1,-0.1)
  end
  if fire.age>36 then del(blasts,fire) end
 end
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
 city_flash=max(city_flash-1)
 -- the city rolls while there is something to advance on, faster under
 -- boost, and eases to a stop when the hill is clear
 local rate=0
 if state=="play" then
  rate=(#foes>0 and scroll_speed or 0)+boost*4
 end
 scroll_rate+=(rate-scroll_rate)*0.05
 travel=(travel+scroll_rate)%5
 white=max(white-1)
end

function draw_effects()
 for fire in all(blasts) do
  if fire.age<15 then
   circfill(fire.x,fire.y,fire.size*min(1,fire.age/4),
    blast_colours[fire.age\3+1])
  end
 end
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
