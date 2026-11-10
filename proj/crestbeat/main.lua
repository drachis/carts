function reset(new_mode)
 mode=new_mode
 clock,next_beat,combo,score,shake,pulse,ended=0,0,0,0,0,0,0
 scroll,travel_speed=0,0
 aliens,sparks,rings,popups,beams={},{},{},{},{}
 make_city()
 reset_robot()
 start_stage(1)
end

function _init()
 reset("title")
end

function start_play()
 reset("play")
 music(0,0,7)
end

function start_stage(number)
 stage_number,stage=number,stages[number]
 stage_beat=next_beat
 hazards,titan={}
 if stage.spot_hp then make_titan(stage) end
 robot.hp=min(robot.hp+(stage.heal or 0),max_hp)
 banner,banner_life=stage.title,60
end

function stage_done()
 if titan then return titan.dead and titan.dead>45 end
 return next_beat-stage_beat>=#stage.chart and #aliens==0
end

function sync_clock()
 local note=stat(50)
 if stat(57) and note!=last_note then
  local wanted=flr(clock/8)*8+note/4
  clock+=((wanted-clock+4)%8-4)/2
 end
 last_note=note
end

function lane_of(code,set)
 for i=1,3 do
  if sub(set,i,i)==code then return i-2 end
 end
end

function on_beat(beat)
 pulse=1
 for hazard in all(hazards) do
  if hazard.land==beat then land_spit(hazard) end
 end
 local chart=stage.chart
 local index=beat-stage_beat
 if titan then index%=#chart end
 local code=sub(chart,index+1,index+1)
 local lane=lane_of(code,"123")
 if lane then send_alien(lane,beat) end
 lane=lane_of(code,"qwe")
 if lane then open_spot(lane,beat) end
 lane=lane_of(code,"asd")
 if lane then spit(lane,beat) end
end

function finish(result)
 mode=result
 ended=0
 music(-1)
 sfx(result=="won" and 6 or 7)
end

function update_play()
 clock+=1/frames_per_beat
 sync_clock()
 while next_beat<=clock do
  on_beat(next_beat)
  next_beat+=1
 end
 travel_speed+=((stage.fly and fly_speed or 0)-travel_speed)*0.1
 robot.lift+=((stage.fly and 14 or 0)-robot.lift)*0.1
 banner_life=max(banner_life-1)
 update_city()
 update_robot()
 update_aliens()
 if titan then update_titan() end
 if robot.hp<=0 then
  finish("lost")
 elseif stage_done() then
  if stage_number==#stages then
   finish("won")
  else
   start_stage(stage_number+1)
  end
 end
end

function _update()
 local pressed=btnp(4) or btnp(5)
 if mode=="play" then
  update_play()
 else
  ended+=1
  clock+=1/frames_per_beat
  if clock%1<1/frames_per_beat then pulse=1 end
  if pressed and ended>15 then start_play() end
 end
 update_effects()
end

function draw_aim()
 local target=target_in(robot.lane)
 if target then
  local x,y,scale
  if target.open then
   x,y=spot_xy(target)
   scale=0.6
  else
   x,y,scale=alien_centre(target)
  end
  local half=12*scale+2+pulse*2
  for side=-1,1,2 do
   for up=-1,1,2 do
    local cx,cy=x+side*half,y+up*half
    line(cx,cy,cx-side*3,cy,10)
    line(cx,cy,cx,cy-up*3,10)
   end
  end
  for i=1,target.hp do
   pset(x-target.hp+i*2-1,y-half-3,8)
  end
 end
end

function draw_hud()
 for i=1,max_hp do
  circfill(i*8-2,6,2,i<=robot.hp and 8 or 5)
 end
 local text=score_text()
 print(text,126-#text*4,3,7)
 if combo>3 then print("x"..multiplier(),56,3,10) end
 local gun=guns[robot.gun]
 rectfill(0,120,127,127,0)
 for k=0,9 do
  local tick=flr(clock*2)/2+k/2
  local x=10+(tick-clock)*26
  if tick%gun.every==0 then
   rectfill(x,121,x+1,127,tick-clock<0.3 and 7 or gun.colour)
  else
   rectfill(x,125,x,127,tick%1==0 and 6 or 5)
  end
 end
 rect(7,120,13,127,pulse>0.5 and 7 or 8)
 rectfill(126-#gun.name*4,120,127,127,0)
 print(gun.name,128-#gun.name*4,121,gun.colour)
 if mode=="play" and banner_life>0 then
  centred(banner,14,banner_life%16<8 and 10 or 7)
 end
end

function centred(text,y,colour)
 print(text,64-#text*2,y,colour)
end

function _draw()
 camera(rnd(shake)-shake/2,rnd(shake)-shake/2)
 draw_sky()
 draw_ground()
 draw_buildings(true)
 if titan then
  clip(0,0,128,crest_y+4)
  draw_titan()
 end
 clip(0,0,128,crest_y)
 draw_aliens(true)
 clip()
 draw_buildings(false)
 draw_hazards()
 draw_aliens(false)
 if mode=="play" then draw_aim() end
 draw_robot()
 draw_effects()
 camera()
 draw_hud()
 if mode=="title" then
  rectfill(10,46,117,90,0)
  centred("crestbeat",50,8)
  centred("aliens pour over the hill",58,11)
  centred("your guns fire on the beat:",64,7)
  centred("be on the right street",70,7)
  centred("left/right street  z/x gun",76,6)
  centred("press z",84,tick_blink() and 10 or 5)
 elseif mode!="play" then
  rectfill(24,50,103,76,0)
  centred(mode=="won" and "city saved!" or "the city falls",54,mode=="won" and 11 or 8)
  centred("score "..score_text(),62,7)
  if ended>15 then centred("press z",70,tick_blink() and 10 or 5) end
 end
end

function tick_blink()
 return clock%1<0.5
end

function score_text()
 return score>0 and score.."0" or "0"
end
