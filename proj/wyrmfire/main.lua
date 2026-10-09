function new_game()
 generate_world()
 new_dragon()
 score,kills,wrath,heralded=0,0,1,0
 combo,combo_timer,fury,fury_time=0,0,0,0
 shown_score,coin_run,reel_time=0,0,0
 belly,belly_pop,battle_time=0,0,0
 shake,freeze,flash=0,0,0
 message,message_timer,reinforce_timer="",0,300
 cam_x,cam_y=dragon.x-64,dragon.y-64
 boss=nil
 state="title"
 update_music()
end

function end_game(outcome)
 state,end_frame=outcome,frame
 if score>high_score then
  high_score=score
  dset(0,high_score)
 end
end

function update_music()
 if battle then battle_time=8 end
 battle_time-=1
 local track=battle_time>0 and 4 or 0
 if track!=playing then
  playing=track
  music(track,300,3)
 end
end

function multiplier()
 return min(1+combo\combo_step,max_multiplier)
end

function points(tens)
 return flr(tens).."0"
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

function add_score(worth,x,y)
 combo+=1
 combo_timer=combo_frames
 local gained=worth*multiplier()
 score+=gained/10
 add_fury(worth/6)
 if gained>=100 then
  add_particle(x,y-6,0,-.5,30,"text").text="+"..gained
 end
 if streaks[combo] then
  announce(streaks[combo])
  roar(70,30)
 end
end

function collect_coin()
 coin_run+=1
 score+=coin_value*multiplier()/10
 combo_timer=combo_frames
 add_fury(.3)
 poke(0x3200+snd_coin*68,24+coin_run%32)
 sfx(snd_coin)
end

function update_reel()
 if reel_time==0 then return end
 reel_time-=1
 if reel_time%3==0 then
  reel=rnd(boons)
  announce(reel.name,20)
  sfx(snd_coin)
 end
 if reel_time==0 then
  grant(reel.stats)
  announce("boon: "..reel.name,120)
  sfx(snd_fanfare)
 end
end

function update_wrath()
 local next_level=wrath_levels[wrath+1]
 if next_level and score>=next_level.score then
  wrath+=1
  announce("the realm is "..next_level.name)
  sfx(snd_fanfare)
 end
 if frame%30==0 then update_music() end

 local angle=rnd()
 local x,y=dragon.x+cos(angle)*95,dragon.y+sin(angle)*95

 if not boss and heralded<wrath then
  heralded+=1
  local legend=wrath_levels[heralded].legend
  if legend then spawn_boss(legend,x,y) end
 end

 reinforce_timer-=battle and battle_rush or 1
 if reinforce_timer<=0 then
  reinforce_timer=700-wrath*100
  for i=1,1+wrath\2 do
   spawn_unit(rnd(list(wrath_levels[wrath].pool)),x+rnd(16)-8,y+rnd(16)-8)
  end
 end
end

function draw_gauge(glyph,x,fraction,color,back)
 rectfill(x,0,x+8,8,back)
 if fraction>0 then
  rectfill(x,9-9*min(fraction,1),x+8,8,color)
 end
 print(chr(glyph),x+1,2,7)
end

function draw_compass()
 local target,nearest=goal.home,32000
 for home in all(settlements) do
  local distance=dragon_distance(home.tx*8,home.ty*8)
  if home.wards>0 and distance<nearest then
   target,nearest=home,distance
  end
 end
 local angle=atan2(target.tx*8-dragon.x,target.ty*8-dragon.y)
 circfill(121,4,4,1)
 line(121,4,121+cos(angle)*4,4+sin(angle)*4,wards>0 and 12 or 10)
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
 local blink=frame%8<4
 local low=dragon.hp<dragon.max_hp/3
 if state=="play" then
  if fury_time>0 then draw_blaze() end
  if combo>1 then
   local text=combo.." hits"
   print(text,126-#text*4,12,blink and 10 or 9)
  end
  if low and frame%20<10 then
   rect(0,10,127,127,8)
  end
  if fury>=100 and blink then
   print_centered("\142+\151 unleash your fury",112,10)
  end
 end

 rectfill(0,0,127,9,0)
 draw_gauge(135,0,dragon.hp/dragon.max_hp,low and blink and 7 or 8,2)
 draw_gauge(133,10,dragon.fire/dragon.max_fire,9,4)
 if fury_time>0 then
  draw_gauge(146,20,fury_time/fury_frames,12,1)
 else
  draw_gauge(146,20,fury/100,fury<100 and 10 or blink and 7 or 12,5)
 end
 belly_pop-=1
 draw_gauge(32,30,belly_fill(),belly_pop>0 and 7 or 11,3)
 spr(71,30,1)
 if belly_pop>0 then
  circ(34,4,14-belly_pop,10)
 end
 print(points(shown_score),43,2,shown_score<flr(score) and 10 or 7)
 if combo>1 then
  print("x"..multiplier(),76,2,blink and 10 or 9)
  line(76,8,76+combo_timer/combo_frames*8,8,10)
 end
 for ward=1,wards do
  circ(86+ward*7,4,2,12)
 end
 draw_compass()

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
 rectfill(0,0,127,76,0)
 print("\^w\^twyrmfire",33,4,8)
 print_centered("burn the churches. raze camelot.",19,9)
 local y=27
 if high_score>0 then
  print_centered("best "..points(high_score),y,10)
  y+=8
 end
 print("eat",27,y+2,11)
 spr(71,41,y)
 spr(82,50,y)
 spr(81,59,y)
 print("to grow",70,y+2,11)
 print("\142\n\151\n\142+\151\n\139\145\148\131",14,y+12,7)
 print("breathe fire\ncharge & devour\nunleash your fury\nfly",52,y+12,6)
 if frame%30<20 then
  print_centered("press \151 to play",118,7)
 end
end

function draw_game_over()
 local won=state=="won"
 local razed=flr((1-#buildings/#all_buildings)*100)
 rectfill(0,44,127,86,0)
 print_centered(won and "camelot is ash" or "the dragon is slain",50,won and 10 or 8)
 print_centered("score "..points(score).."  best "..points(high_score),60,7)
 print_centered(kills.." slain  "..razed.."% razed",68,6)
 print_centered("press \151",78,5)
end

function _init()
 cartdata("drachis_wyrmfire")
 high_score=dget(0)
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
  update_buildings()
  update_settlements()
  update_wrath()
  update_reel()
  combo_timer-=1
  if combo_timer<=0 then combo,coin_run=0,0 end
 elseif state=="title" then
  local turn=frame/240
  dragon.x=84+cos(turn)*30
  dragon.y=84+sin(turn)*14
  dragon.angle=atan2(sin(turn)*30,-cos(turn)*14)
  update_tail()
  if pressed then state="play" end
 elseif frame-end_frame<60 then
  if state=="dead" then
   dragon.size*=.95
   dragon.angle+=.04
   update_tail()
  end
 elseif pressed then
  new_game()
 end
 update_fire()
 update_particles()
 shown_score+=ceil((flr(score)-shown_score)/6)
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
 local lead=dragon.breath_range/2
 cam_x+=(mid(0,dragon.x+cos(dragon.angle)*lead-64,384)-cam_x)*.15
 cam_y+=(mid(0,dragon.y+sin(dragon.angle)*lead-64,384)-cam_y)*.15
 if state=="title" then
  cam_x,cam_y=20,-18
 end
 camera(cam_x+rnd(shake)-shake/2,cam_y+rnd(shake)-shake/2)
 map(cam_x\8,cam_y\8,cam_x\8*8,cam_y\8*8,17,17)
 draw_fire()
 draw_buildings()
 draw_units()
 draw_dragon()
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
