-- world.lua : the 2.5d projection, the scenery, and the effects.

camera_x=0
tick=0
-- how far the mech has advanced over the city, wrapping every five deep
travel=0
scroll_rate=0

-- world (x across, z depth, h height) to screen. x and h are in pixels as
-- they appear at the mech's line; things shrink and close up toward the
-- crest, and the crest sags at the edges so the ground reads as a globe.
function project(x,z,h)
 local near=max((far_z/z-1)/(far_z-1))
 local scale=0.3+0.9*near
 local sx=64+(x-camera_x)*(0.7+0.3*near)
 -- the sag is only on the hill; below the mech's line x runs far enough
 -- off screen that squaring it overflows
 local sag=near<1 and (sx-64)*(sx-64)/350*(1-near) or 0
 local sy=crest_y+74*near+sag-h*scale
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
-- bottom of the screen.
--
-- the ground is cut into cells 20 across and 0.625 deep. roads run on
-- both diagonals of that grid (a road moves 20 across for each cell of
-- depth), which leaves diamonds between them; each diamond holds a block
-- of two towers, in the cells where column+row is even.
function draw_hill()
 -- the land is the top of a globe, with the light catching its rim
 circfill(64,crest_y+globe,globe,3)
 rectfill(0,crest_y+12,127,127,3)
 circ(64,crest_y+globe,globe,11)

 local colour=grid_flash>0 and 7 or 5
 for lane=-11,11 do
  for lean=-1,1,2 do
   line()
   for z in all(road_depths) do
    local x=lane*40+10-lean*10+lean*32*(z-1+travel)
    if abs(x)<125 then
     grid_point(x,z,colour)
    else
     line()
    end
   end
  end
 end

 local slide=travel/0.625%1
 local turn=travel\0.625
 for k=8,-1,-1 do
  -- the front edge runs on off the bottom of the screen. 0.45 is far
  -- enough for the tallest tower to leave it, and keeps depth well away
  -- from 0, where the projection has no answer
  local front=max(1.1+(k-slide)*0.625,0.45)
  local back=min(1.525+(k-slide)*0.625,far_z)
  if back>front then
   local row=(k+turn)%8
   for column=row%2,9,2 do
    local left=column*20-98
    local seed=(column*7+row*13)%20
    if seed%5==2 then
     -- a park: three trees, burnt black once the city has fallen this far
     for tree=0,2 do
      local sx,sy,scale=project(left+3+tree*5,front+(back-front)*(tree%2*0.5+0.25),0)
      circfill(sx,sy-scale*3,scale*2.5,seed<(100-city)/5 and 0 or 11)
      pset(sx,sy,4)
     end
    else
     draw_tower(left,left+8,front,back,seed,k<3)
     draw_tower(left+8,left+16,front,back,(seed+9)%20,k<3)
    end
   end
  end
 end
end

-- one tower: a roof and a front wall of windows. `seed` (0..19) fixes its
-- height, colours and roof, and its turn to suffer. as the city falls a
-- tower is first damaged (windows out, a few lit by fire, a bite out of
-- its top), then a ruin: half the height, burnt brown, gutted (a rim
-- round a dark inside), its top edge broken, smoking. nothing on a tower flashes
-- or moves fast, so it is not mistaken for something to dodge.
function draw_tower(left,right,front,back,seed,near_row)
 local harm=(100-city)/5-seed
 local ruined=harm>0
 -- low in the suburbs, three times the height by the capitol
 local height=(6+seed%8*2)*(0.4+wave*0.15)
 if ruined then height/=3 end
 local x1,top,scale=project(left,front,height)
 local x2=x1+(right-left)*(0.6+scale/3)
 local _,far_top=project(left,back,height)
 local base=top+height*scale
 local wall,roof=tower_tints[seed%4*2+1],tower_tints[seed%4*2+2]
 if ruined then wall,roof=0,5 end
 if city_flash>0 and near_row and tick%4<2 then wall,roof=2,8 end
 rectfill(x1,far_top,x2,top,roof)
 rectfill(x1,top+1,x2,base,wall)

 if ruined then
  rect(x1,top+1,x2,base,5)
  -- gutted: seen from above, a rim round a dark inside
  if top-far_top>4 then
   rectfill(x1+2,far_top+2,x2-2,top-1,0)
   pset(x1+3+seed%3,far_top+3,5)
  end
  -- and bites out of the top edge of the wall
  for bite=0,1 do
   local x=x1+(seed*3+bite*7)%(x2-x1)
   rectfill(x,top,x+scale*2,top+(base-top)*(bite+1)/4,0)
  end
  if rnd()<0.03 then
   burst((x1+x2)/2,top,1,rnd{5,6},0.4,-0.04)
  end
 end
 if scale>0.6 then
  local damaged=harm>-4 and city<100
  local glass=window_tints[seed%3+1]
  for across=0,(x2-x1-2)\4 do
   for down=0,min(6,(base-top-4)\3) do
    local pane=across*3+down*5+seed
    local colour=pane%4>0 and glass
    if ruined then
     colour=pane%2==0 and 0
    elseif damaged then
     colour=pane%5==0 and 9 or 0
    end
    if colour then pset(x1+1+across*4,top+3+down*3,colour) end
   end
  end
  if ruined then
  elseif damaged then
   rectfill(x2-(x2-x1)/3,top-scale*2,x2,top+scale*3,0)
  elseif seed%5==0 then
   -- a mast with a light
   line(x1+3,far_top,x1+3,far_top-scale*5,6)
   pset(x1+3,far_top-scale*5,8)
  else
   rectfill(x1+2,far_top+2,x1+2+scale*3,far_top+1+scale*2,13)
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
