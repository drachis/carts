-- main.lua : game states, the wrath director, hud and main loop.
-- state is "title", "play", "dead" or "won".

function new_game()
 generate_world()
 new_dragon()
 score,kills,wrath,heralded=0,0,1,0
 shake,message,message_timer,reinforce_timer=0,"",0,300
 boss=nil
 state="title"
end

function end_game(outcome)
 state,end_frame=outcome,frame
 if score>high_score then
  high_score=score
  dset(0,high_score)
 end
end

-- the more you burn, the harder the realm pushes back
function update_wrath()
 local next_level=wrath_levels[wrath+1]
 if next_level and score>=next_level.score then
  wrath+=1
  announce("the realm is "..next_level.name)
  sfx(sound.fanfare)
 end

 -- newcomers arrive from just off screen
 local angle=rnd()
 local x,y=dragon.x+cos(angle)*95,dragon.y+sin(angle)*95

 -- each level's legend is heralded once, one boss at a time
 if not boss and heralded<wrath then
  heralded+=1
  local legend=wrath_levels[heralded].legend
  if legend then spawn_boss(legend,x,y) end
 end

 reinforce_timer-=1
 if reinforce_timer<=0 then
  reinforce_timer=max(90,330-wrath*50)
  for i=1,1+wrath\2 do
   spawn_unit(rnd(list(wrath_levels[wrath].pool)),x+rnd(16)-8,y+rnd(16)-8)
  end
 end
end

function draw_bar(x,y,width,fraction,color,back)
 rectfill(x,y,x+width,y+2,back)
 rectfill(x,y,x+width*mid(0,fraction,1),y+2,color)
end

function draw_hud()
 -- compass to the goal when it is off screen
 local dx,dy=goal.center_x-cam_x-64,goal.center_y-cam_y-64
 if state=="play" and (abs(dx)>64 or abs(dy)>56) then
  local angle=atan2(dx,dy)
  local x,y=64+cos(angle)*56,68+sin(angle)*52
  circfill(x,y,2,8)
  line(x,y,x+cos(angle)*4,y+sin(angle)*4,10)
 end

 rectfill(0,0,127,8,0)
 draw_bar(2,1,40,dragon.hp/dragon.max_hp,8,2)
 draw_bar(2,5,40,dragon.fire/dragon.max_fire,9,4)
 print(score,47,2,7)
 print("ko "..kills,72,2,6)
 for level=1,#wrath_levels do
  circfill(100+level*5,4,1,level<=wrath and 8 or 5)
 end

 if boss then
  local spec=boss.spec
  rectfill(0,119,127,127,0)
  print(spec.name,2,121,spec.color)
  draw_bar(60,122,65,boss.hp/spec.hp,8,2)
 end
 if message_timer>0 then
  print_centered(message,14,10)
 end
end

function draw_title()
 rectfill(0,24,127,100,0)
 print("\^w\^twyrmfire",33,31,8)
 print_centered("burn the realm. raze camelot.",48,9)
 print_centered("arrows  fly",62,6)
 print_centered("z  breathe fire",70,6)
 print_centered("x  charge & devour",78,6)
 print_centered("press x",90,7)
 if high_score>0 then
  print_centered("best "..high_score,106,10)
 end
end

function draw_game_over()
 local won=state=="won"
 local razed=flr((1-#buildings/#all_buildings)*100)
 rectfill(0,44,127,86,0)
 print_centered(won and "camelot is ash" or "the dragon is slain",50,won and 10 or 8)
 print_centered("score "..score.."  best "..high_score,60,7)
 print_centered(kills.." slain  "..razed.."% razed",68,6)
 if frame-end_frame>45 then
  print_centered("press x",78,5)
 end
end

function _init()
 cartdata("drachis_wyrmfire")
 high_score=dget(0)
 frame=0
 new_game()
end

function _update()
 frame+=1
 local pressed=btnp(4) or btnp(5)
 if state=="play" then
  update_dragon()
  update_units()
  update_shots()
  update_buildings()
  update_wrath()
 elseif state=="title" then
  if pressed then state="play" end
 elseif pressed and frame-end_frame>45 then
  new_game()
 end
 update_fire()
 update_particles()
 shake*=.8
 message_timer-=1
end

function _draw()
 cls()
 cam_x,cam_y=mid(0,dragon.x-64,384),mid(0,dragon.y-64,384)
 camera(cam_x+rnd(shake)-shake/2,cam_y+rnd(shake)-shake/2)
 map(cam_x\8,cam_y\8,cam_x\8*8,cam_y\8*8,17,17)
 draw_fire()
 draw_buildings()
 draw_units()
 draw_shots()
 draw_dragon()
 draw_particles()
 draw_shots(true)

 camera()
 if state=="title" then
  draw_title()
 else
  draw_hud()
  if state!="play" then draw_game_over() end
 end
end
