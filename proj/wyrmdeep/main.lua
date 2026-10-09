function new_game()
 reload()
 slain,taken,visited,fires,particles={},{},{},{},{}
 kills,deaths,seconds,relic_count=0,0,0,0
 fury,fury_time,combo,combo_timer,muster=0,0,0,0,90
 shake,freeze,flash=0,0,0
 message,message_timer="",0
 new_dragon()
 populate()
 cam_x,cam_y=dragon.x-64,dragon.y-64
 state="title"
 update_music()
end

function end_game(outcome)
 state,end_frame=outcome,frame
 if outcome=="won" and (best_time==0 or seconds<best_time) then
  best_time=seconds
  dset(0,best_time)
 end
end

function respawn()
 local d=dragon
 d.x,d.y,d.vx,d.vy=nest_x,nest_y,0,0
 d.hp,d.fire,d.flash=d.max_hp,d.max_fire,60
 deaths+=1
 populate()
 state="play"
end

function update_music()
 local track=boss and 4 or 0
 if track!=playing then
  playing=track
  music(track,300,3)
 end
end

function add_fury(amount)
 if fury_time==0 and fury<100 then
  fury=min(100,fury+amount)
  if fury==100 then
   announce("fury is full! \142+\151",120)
   sfx(snd_fanfare)
  end
 end
end

function collect_coin()
 add_fury(.5)
 sfx(snd_coin)
end

function clock_text(time)
 local second=time%60
 return time\60 ..":"..(second<10 and "0" or "")..second
end

function draw_gauge(glyph,x,fraction,color,back)
 rectfill(x,0,x+8,8,back)
 if fraction>0 then
  rectfill(x,9-9*min(fraction,1),x+8,8,color)
 end
 print(chr(glyph),x+1,2,7)
end

function draw_blaze()
 local ramp=split(dragon.flame)
 for i=0,127,2 do
  local reach=3+rnd(4)+sin(i/50+frame/40)*3
  local color=ramp[2+flr(rnd(3))]
  line(i,127,i,127-reach,color)
  if i>9 then
   line(0,i,reach,i,color)
   line(127,i,127-reach,i,color)
  end
 end
end

function draw_hud()
 local d=dragon
 local blink=frame%8<4
 local low=d.hp<d.max_hp/3
 if state=="play" then
  if fury_time>0 then draw_blaze() end
  if low and frame%20<10 then
   rect(0,10,127,127,8)
  end
  if combo>1 then
   local text=combo.." burnt"
   print(text,126-#text*4,12,blink and 10 or 9)
  end
  if fury>=100 and blink then
   print_centered("\142+\151 unleash your fury",112,10)
  end
 end

 rectfill(0,0,127,9,0)
 draw_gauge(135,0,d.hp/d.max_hp,low and blink and 7 or 8,2)
 draw_gauge(133,10,d.fire/d.max_fire,9,4)
 if fury_time>0 then
  draw_gauge(146,20,fury_time/fury_frames,12,1)
 else
  draw_gauge(146,20,fury/100,fury<100 and 10 or blink and 7 or 12,5)
 end
 print(ages[age].name,32,2,7)
 spr(95,82,1)
 print(relic_count.."/"..relic_total,91,2,7)

 local here=d.x\128+d.y\128*8
 visited[here]=true
 for room=0,31 do
  if visited[room] then
   local x,y=111+room%8*2,room\8*2
   rectfill(x,y,x+1,y+1,room==here and blink and 7 or 13)
  end
 end

 if boss then
  rectfill(0,121,127,127,2)
  rectfill(0,121,127*boss.hp/boss.max_hp,127,8)
  print(boss.name,2,122,7)
 end
 if message_timer>0 then
  print_centered(message,22)
 end
end

function draw_title()
 rectfill(0,0,127,72,0)
 print("\^w\^twyrmdeep",33,4,8)
 print_centered("devour the round table.",19,9)
 print_centered("take the throne.",26,9)
 if best_time>0 then
  print_centered("best "..clock_text(best_time),35,10)
 end
 print("\142\n\151\n\142+\151\n\139\145\n\148",14,42,7)
 print("breathe fire\ncharge & devour\nunleash your fury\nwalk\njump, glide, fly",52,42,6)
 if frame%30<20 then
  print_centered("press \151 to play",118,7)
 end
end

function draw_game_over()
 local won=state=="won"
 rectfill(0,44,127,86,0)
 print_centered(won and "the crown is devoured" or "the dragon is slain",50,won and 10 or 8)
 if won then
  print_centered("time "..clock_text(seconds).."  best "..clock_text(best_time),60,7)
  print_centered(relic_count.."/"..relic_total.." relics  "..deaths.." deaths",68,6)
 else
  print_centered("it wakes again in its nest",60,6)
 end
 print_centered("press \151",78,5)
end

function _init()
 cartdata("drachis_wyrmdeep")
 best_time=dget(0)
 frame=0
 new_game()
end

function _update()
 if freeze>0 then
  freeze-=1
  return
 end
 frame+=1
 local pressed=btnp(4) or btnp(5)
 if state=="play" then
  update_dragon()
  update_units()
  update_shots()
  update_relics()
  update_horde()
  combo_timer-=1
  if combo_timer<=0 then combo=0 end
  if frame%30==0 then
   seconds+=1
   update_music()
  end
 elseif state=="title" then
  if pressed then state="play" end
 elseif frame-end_frame>=60 and pressed then
  if state=="dead" then
   respawn()
  else
   new_game()
  end
 end
 update_fire()
 update_particles()
 shake*=.8
 message_timer-=1
end

function _draw()
 if flash>0 then
  flash-=1
  cls(7)
  return
 end
 cls()
 local d=dragon
 cam_x+=(mid(0,d.x+d.facing*24-64,896)-cam_x)*.2
 cam_y+=(mid(0,d.y-68,384)-cam_y)*.15
 camera(cam_x+rnd(shake)-shake/2,cam_y+rnd(shake)-shake/2)
 rectfill(0,0,1023,231,1)
 pal(12,frame%8<4 and 7 or 12)
 map(cam_x\8,cam_y\8,cam_x\8*8,cam_y\8*8,17,17)
 pal()
 draw_fire()
 draw_relics()
 draw_units()
 if state!="dead" then draw_dragon() end
 draw_particles()
 draw_shots()

 camera()
 if state=="title" then
  draw_title()
 else
  draw_hud()
  if state!="play" and frame-end_frame>=60 then draw_game_over() end
 end
end
