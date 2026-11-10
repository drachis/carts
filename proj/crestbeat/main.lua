function reset(new_mode)
 mode=new_mode
 clock,next_beat,combo,score,shake,pulse,ended=0,0,0,0,0,0,0
 aliens,sparks,rings,popups,beams={},{},{},{},{}
 reset_robot()
end

function _init()
 make_city()
 reset("title")
 scroll=0
end

function start_play()
 reset("play")
 music(0,0,7)
end

function sync_clock()
 local note=stat(50)
 if stat(57) and note!=last_note then
  local wanted=flr(clock/8)*8+note/4
  clock+=((wanted-clock+4)%8-4)/2
 end
 last_note=note
end

function on_beat(beat)
 pulse=1
 local code=ord(wave_chart,beat+1)
 if code and code>=49 and code<=51 then send_alien(code-50,beat) end
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
 update_robot()
 update_aliens()
 if robot.hp<=0 then
  finish("lost")
 elseif next_beat>#wave_chart and #aliens==0 then
  finish("won")
 end
end

function _update60()
 local pressed=btnp(4) or btnp(5)
 if mode=="play" then
  update_play()
 else
  ended+=1
  clock+=1/frames_per_beat
  if clock%1<1/frames_per_beat then pulse=1 end
  if pressed and ended>30 then start_play() end
 end
 update_effects()
end

function draw_aim()
 local alien=front_alien(robot.lane)
 if alien then
  local x,y,scale=alien_centre(alien)
  local half=12*scale+2+pulse*2
  for side=-1,1,2 do
   for up=-1,1,2 do
    local cx,cy=x+side*half,y+up*half
    line(cx,cy,cx-side*3,cy,10)
    line(cx,cy,cx,cy-up*3,10)
   end
  end
  for i=1,alien.hp do
   circfill(x-alien.hp*3+i*6-3,y-half-4,1,8)
  end
 end
end

function draw_hud()
 for i=1,max_hp do
  circfill(i*8-2,6,2,i<=robot.hp and 8 or 5)
 end
 local text=tostr(score)
 print(text,126-#text*4,3,7)
 if combo>3 then print("x"..multiplier(),56,3,10) end
 rectfill(0,121,127,127,0)
 local fraction=clock%1
 for k=0,4 do
  local distance=k-fraction
  if distance>-0.15 then
   local colour=distance<0.25 and 10 or 6
   for side=-1,1,2 do
    rectfill(64+side*distance*16-1,122,64+side*distance*16,126,colour)
   end
  end
 end
 rect(61,121,67,127,pulse>0.5 and 7 or 8)
end

function centred(text,y,colour)
 print(text,64-#text*2,y,colour)
end

function _draw()
 camera(rnd(shake)-shake/2,rnd(shake)-shake/2)
 draw_sky()
 draw_aliens(true)
 draw_ground()
 draw_buildings()
 draw_aliens(false)
 if mode=="play" then draw_aim() end
 draw_robot()
 draw_effects()
 camera()
 draw_hud()
 if mode=="title" then
  rectfill(10,46,117,84,0)
  centred("crestbeat",50,8)
  centred("aliens pour over the hill",58,11)
  centred("shoot them on the beat",64,7)
  centred("left/right lane  z/x fire",72,6)
  centred("press z",78,tick_blink() and 10 or 5)
 elseif mode!="play" then
  rectfill(24,50,103,76,0)
  centred(mode=="won" and "hill clear!" or "the city falls",54,mode=="won" and 11 or 8)
  centred("score "..score,62,7)
  if ended>30 then centred("press z",70,tick_blink() and 10 or 5) end
 end
end

function tick_blink()
 return clock%1<0.5
end
