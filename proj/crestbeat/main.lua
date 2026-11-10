function reset(new_mode)
 mode=new_mode
 clock,next_beat,combo,score,shake,pulse,ended=0,0,0,0,0,0,0
 scroll,travel_speed,crest_y=0,0,horizon
 aliens,sparks,rings,popups,beams,fallen={},{},{},{},{},{}
 reset_stats()
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
 if stage.bars then make_titan(stage) end
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

function plan_lane(beat,route)
 local index=beat-stage_beat
 if titan then index%=#stage.chart end
 local code=ord(route or stage.plan,index+1)
 if code and code>48 then return code-50 end
end

function chevron(lane,y,colour)
 local x=64+lane*40
 for nudge=0,1 do
  line(x-5,y-4+nudge,x,y+nudge,colour)
  line(x,y+nudge,x+5,y-4+nudge,colour)
 end
end

function draw_plan()
 for ahead=2,0,-1 do
  local beat,y=flr(clock)+1+ahead,117-ahead*9
  local lane,golden=plan_lane(beat),plan_lane(beat,stage.golden)
  if lane then chevron(lane,y,({11,3,1})[ahead+1]) end
  if golden and golden!=lane then chevron(golden,y-2,ahead==0 and 10 or 9) end
 end
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
 for kind in all(kinds) do
  local lane=lane_of(code,kind.keys)
  if lane then send_alien(lane,beat,kind) end
 end
 local lane=lane_of(code,"qwe")
 if lane then open_spot(lane,beat) end
 lane=lane_of(code,"asd")
 if lane then spit(lane,beat) end
end

function finish(result)
 mode=result
 ended=0
 music(-1)
 sfx(result=="won" and 6 or 7)
 start_payout(result=="won")
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
 crest_y+=((titan and not titan.dead and titan_horizon or horizon)-crest_y)*0.08
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
  if mode!="title" then update_payout() end
  if pressed and ended>15 and (mode=="title" or payout_done()) then start_play() end
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
  local half,colour=12*scale+2+pulse*2,target.penalty and 8 or 10
  for side=-1,1,2 do
   for up=-1,1,2 do
    local cx,cy=x+side*half,y+up*half
    line(cx,cy,cx-side*3,cy,colour)
    line(cx,cy,cx,cy-up*3,colour)
   end
  end
  if target.penalty then
   print("!",x-1,y-half-7,8)
  else
   local pips=ceil(target.hp/4)
   for i=1,pips do
    pset(x-pips+i*2-1,y-half-3,8)
   end
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
 rectfill(0,123,127,127,0)
 for k=0,9 do
  local tick=flr(clock*2)/2+k/2
  local x=6+(tick-clock)*20
  if fires_on(gun,tick*2) then
   rectfill(x,125,x,127,gun.colour)
  elseif tick%1==0 then
   pset(x,127,1)
  end
 end
 line(5,124,5,127,5)
 print(gun.name,128-#gun.name*4,122,gun.colour)
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
 draw_fallen()
 draw_aliens(false)
 if mode=="play" then draw_aim() end
 draw_robot()
 if mode=="play" and btn(3) then draw_plan() end
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
  draw_payout()
 end
end

function tick_blink()
 return clock%1<0.5
end

function score_text()
 return score>0 and score.."0" or "0"
end
