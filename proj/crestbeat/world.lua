function project(lane,t)
 local near=max(t)
 return 64+lane*(12+28*near)-cam_x*(0.3+0.7*near),
  crest_y+(t<0 and -t*96 or (hill_bottom-crest_y)*(0.35*t+0.65*t*t)),
  0.4+0.6*near
end

function make_city()
 skyline,buildings={},{}
 for x=0,127,9 do
  add(skyline,{x=x,w=6+rnd(6),h=6+rnd(16)})
 end
 for side=-1,1,2 do
  for t=0,1.2,0.15 do
   add(buildings,{side=side,t=t+rnd(0.05),w=18+rnd(14),h=30+rnd(50),gap=rnd(6),glow=rnd{12,14,13}})
  end
 end
 sort_by_t(buildings)
end

function update_city()
 scroll+=travel_speed
 for building in all(buildings) do
  building.t+=travel_speed
  if building.t>1.3 then
   building.t-=1.35
   building.h,building.fall_at=30+rnd(50)
  end
  if building.fall_at and clock>building.fall_at and building.h>6 then
   building.h-=0.5
   if rnd()<0.3 then
    local edge,base,scale=project(building.side*1.5,building.t)
    burst(edge+building.side*(4+building.gap+building.w/2)*scale,base-building.h*scale,1,6,1)
   end
  end
 end
 sort_by_t(buildings)
end

function sort_by_t(list)
 for i=2,#list do
  local j=i
  while j>1 and list[j-1].t>list[j].t do
   list[j],list[j-1]=list[j-1],list[j]
   j-=1
  end
 end
end

function sunset(horizon,sun_x,radius)
 cls(1)
 fillp(0xa5a5)
 rectfill(0,horizon-44,127,horizon-23,0x12)
 fillp()
 rectfill(0,horizon-22,127,horizon,2)
 for star=1,40 do
  local x,y=star*37%128,star*23%50
  if y<horizon-12 and (star+flr(clock*2))%7>0 then pset(x,y,star%3==0 and 7 or 13) end
 end
 local centre=horizon-radius*0.37
 for dy=-radius,radius*0.37 do
  local half,share=sqrt(radius*radius-dy*dy),dy/radius
  if dy<0 or (dy+flr(clock*8))%6>=share*6 then
   line(sun_x-half,centre+dy,sun_x+half,centre+dy,share<-0.47 and 10 or share<-0.07 and 9 or share<0.33 and 8 or 14)
  end
 end
end

function draw_sky()
 sunset(crest_y,64-cam_x*0.1,22)
 for tower in all(skyline) do
  local x=tower.x-cam_x*0.15
  rectfill(x,crest_y-tower.h,x+tower.w,crest_y,0)
  pset(x+2,crest_y-tower.h+3,tower.h%3<1 and 14 or 12)
 end
end

function draw_ground()
 rectfill(0,crest_y,127,127,0)
 for t=scroll%0.1,1.4,0.1 do
  local _,y=project(0,t)
  line(0,y,127,y,2)
 end
 for edge=-1.5,1.5,3 do
  local x1,y1=project(edge,0)
  local x2,y2=project(edge,1.4)
  line(x1,y1,x2,y2,14)
 end
 for t=scroll%0.2,1.4,0.2 do
  for lane=-0.5,0.5,1 do
   local x1,y1,scale=project(lane,t)
   local x2,y2=project(lane,t+0.09)
   for w=0,scale*2 do
    line(x1+w,y1,x2+w,y2,12)
   end
  end
 end
end

function draw_buildings(behind)
 for building in all(buildings) do
  if (building.t<0.03)==behind then
   local edge,base,scale=project(building.side*1.5,building.t)
   local inner=edge+building.side*(4+building.gap)*scale
   local outer=inner+building.side*building.w*scale
   local top=base-building.h*scale
   rectfill(inner,top,outer,base,1)
   rect(inner,top,outer,base,building.glow)
   local window=0
   for y=top+4,base-3,5*scale+1 do
    for x=min(inner,outer)+2,max(inner,outer)-3,3*scale+1 do
     window+=1
     if (window*building.w+building.h)%5<2 then rectfill(x,y,x+scale,y+scale,window%7==0 and 10 or building.glow) end
    end
   end
  end
 end
end

function burst(x,y,count,colour,speed)
 for i=1,count do
  if #sparks<max_sparks then
   local angle,velocity=rnd(),speed*(0.2+rnd())
   add(sparks,{x=x,y=y,vx=cos(angle)*velocity,vy=sin(angle)*velocity,
    life=10+rnd(20),colour=colour})
  end
 end
end

function ring(x,y,size,colour)
 add(rings,{x=x,y=y,radius=1,size=size,colour=colour})
end

function popup(text,x,y,colour)
 add(popups,{text=text,x=x,y=y,colour=colour,life=30})
end

function update_effects()
 for spark in all(sparks) do
  spark.x+=spark.vx
  spark.y+=spark.vy
  spark.vx*=0.9
  spark.vy=spark.vy*0.9+(spark.float or 0.05)
  spark.life-=1
  if spark.life<0 then del(sparks,spark) end
 end
 for wave in all(rings) do
  wave.radius+=(wave.size-wave.radius)*0.15+0.4
  if wave.radius>=wave.size then del(rings,wave) end
 end
 for note in all(popups) do
  note.y-=0.5
  note.life-=1
  if note.life<0 then del(popups,note) end
 end
 for beam in all(beams) do
  beam.life-=1
  if beam.life<0 then del(beams,beam) end
 end
 shake*=0.85
 pulse=(1+cos(clock))/2
 cam_x=(robot.x-64)*camera_lean
end

function draw_effects()
 for beam in all(beams) do
  for w=-beam.width,beam.width do
   line(beam.x1+w,beam.y1,beam.x2,beam.y2,beam.life>2 and beam.colour or 9)
  end
 end
 for wave in all(rings) do
  circ(wave.x,wave.y,wave.radius,wave.colour)
 end
 for spark in all(sparks) do
  line(spark.x,spark.y,spark.x-spark.vx*2,spark.y-spark.vy*2,spark.life<5 and 5 or spark.colour)
 end
 for note in all(popups) do
  print(note.text,note.x-#note.text*2,note.y,note.life%6<3 and 7 or note.colour)
 end
end
