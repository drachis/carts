screen_palette=split"0,129,130,3,4,141,6,7,8,9,10,11,12,13,14,143"

sky_bands=split"0,1,0,20,1,2,30,2,0,44,2,5,52,5,0,60,5,14,66,14,0,76,14,15,82,15,0,90,15,9"

haze_ramp=split"15,14,13,5,2,1"

ray_ramp=split"15,9,14,8,2"

function set_palette()
 for colour=0,15 do pal(colour,screen_palette[colour+1],1) end
end

function progress()
 return mid(0,(level-1+view.x/(level_w-128))/#levels,1)
end

function haze_fill(layer_near,top_fn,parallax,cam_x)
 local place=mid(1,layer_near+progress()*1.5,#haze_ramp)
 local base=flr(place)
 local colour,next_colour=haze_ramp[base],haze_ramp[min(base+1,#haze_ramp)]
 local blend=place-base
 fillp(blend<0.33 and 0 or blend<0.66 and 0x5a5a or 0xfafa)
 for x=0,127 do
  local top=top_fn(x+cam_x*parallax)
  line(x,top,x,127,colour+next_colour*16)
 end
 fillp()
 return colour
end

function far_hill(world_x)
 return 64+sin(world_x/170)*6+sin(world_x/61)*3
end

function near_hill(world_x)
 return 84+sin(world_x/130)*7+sin(world_x/47)*3
end

function draw_backdrop(cam_x)
 local dusk=progress()
 for i=1,#sky_bands,3 do
  local other=sky_bands[i+2]
  fillp(other>0 and 0x5a5a or 0)
  rectfill(0,sky_bands[i]+dusk*8,127,(sky_bands[i+3] or 128)+dusk*8,sky_bands[i+1]+other*16)
 end
 rectfill(0,0,127,dusk*8,1)
 fillp()
 for star=1,24 do
  if star<6+dusk*18 and (t()/3+star/7)%1<0.85 then
   pset(star*37%128,star*23%(30+dusk*20),star%3==0 and 7 or 13)
  end
 end
 local sun_x,sun_y=92-cam_x*0.02,48+dusk*30
 local shade=flr(dusk*3.99)+1
 for ray=1,16 do
  local wide=ray%2
  local angle,width,reach=ray/16+t()/90*(wide*2-1),0.006+wide*0.012+sin(t()/3+ray/5)*0.005,170+ray*29%50
  fillp(wide>0 and 0xa5f5.8 or 0x5a5a.8)
  tri(sun_x,sun_y,sun_x+cos(angle-width)*reach,sun_y+sin(angle-width)*reach,sun_x+cos(angle+width)*reach,sun_y+sin(angle+width)*reach,ray_ramp[shade+wide])
 end
 fillp()
 circfill(sun_x,sun_y,14,9)
 circfill(sun_x,sun_y,12,15)
 for y=sun_y+2,sun_y+14,3 do
  local half=sqrt(max(196-(y-sun_y)*(y-sun_y)))
  line(sun_x-half,y,sun_x+half,y,9)
 end
 local far=haze_fill(3,far_hill,0.1,cam_x)
 draw_far_observatory(cam_x,far)
 local sign_x,peak=34-dusk*14,40-dusk*14
 for dx=-34,34 do
  line(sign_x+dx,peak+abs(dx)*0.7,sign_x+dx,90,far)
 end
 print("hollywood",sign_x-17,peak+7,6)
 haze_fill(4,near_hill,0.25,cam_x)
 for x=0,127,3 do
  local world_x=flr(x+cam_x*0.25)
  if world_x*13%7==0 and (t()*2+world_x)%9>0.4 then
   pset(x,near_hill(world_x)+3+world_x%5*3,world_x%3==0 and 10 or 9)
  end
 end
 draw_palms(cam_x)
end

function draw_far_observatory(cam_x,colour)
 local size=1+progress()*2
 local x=104-progress()*40
 local y=far_hill(x+cam_x*0.1)+1
 circfill(x,y-6*size,4*size,colour)
 rectfill(x-9*size,y-6*size,x+9*size,y,colour)
 circfill(x-8*size,y-6*size,2*size,colour)
 circfill(x+8*size,y-6*size,2*size,colour)
end

function draw_palms(cam_x)
 local scroll=cam_x*0.5
 for palm=flr(scroll/90)-1,flr(scroll/90)+2 do
  local seed=(palm+100)*37%17
  local height,lean=40+seed%4*8,(seed%3-1)*0.2
  local base_x=palm*90+seed*3-scroll
  local top_x,top_y=base_x+lean*height,108-height
  for rise=0,height,2 do
   circfill(base_x+lean*rise+sin(rise/(height*2))*3,108-rise,1,1)
  end
  for frond=0,6 do
   local angle=frond/7+0.04
   local last_x,last_y=top_x,top_y
   for reach=2,16,2 do
    local x,y=top_x+cos(angle)*reach,top_y+sin(angle)*reach*0.4+reach*reach*0.03
    line(last_x,last_y,x,y,1)
    last_x,last_y=x,y
   end
  end
 end
end
