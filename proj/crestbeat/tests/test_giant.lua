local game_draw=_draw
local alien_hp,walk_beats,spot_hp=kinds.alien.bars*8,kinds.alien.walk,stages[3].bars*8/3
function sfx() end
music=sfx

local function check(name,passed,detail)
 printh((passed and "pass: " or "error: ")..name.." ("..tostr(detail)..")")
end

local function step_frames(count)
 for i=1,count do
  clock+=1/frames_per_beat
  update_aliens()
  update_gun()
 end
end

local function step_to(beat)
 while clock<beat do step_frames(1) end
end

local function giant()
 reset("play")
 start_stage(3)
 local spot=titan.spots[2]
 open_spot(0,4)
 clock=3.9
 equip(2)
 step_to(4.01)
 check("a shot at an open hot spot hurts it",spot.hp==spot_hp-2,"hp "..spot.hp)

 reset("play")
 start_stage(3)
 spot=titan.spots[2]
 clock=3.9
 equip(2)
 step_to(4.01)
 check("a closed hot spot cannot be hurt",spot.hp==spot_hp,"hp "..spot.hp)

 reset("play")
 start_stage(3)
 spit(1,0)
 robot.lane=1
 on_beat(2)
 check("spit hurts the robot in its lane",robot.hp==max_hp-1,"hp "..robot.hp)
 spit(1,2)
 robot.lane=0
 on_beat(4)
 check("spit misses a robot that moved",robot.hp==max_hp-1,"hp "..robot.hp)

 reset("play")
 start_stage(3)
 titan.rise,robot.lane,robot.moved=1,1,0
 clock=idle_beats-1
 on_beat(idle_beats-1)
 local early=#hazards
 clock=idle_beats
 on_beat(idle_beats)
 check("standing still in a giant fight draws spit at your street",early==0 and #hazards==1 and hazards[1].lane==1,#hazards.." spat, "..early.." early")

 reset("play")
 next_beat=#stages[1].chart
 check("a swarm is done when its chart is played and no alien is left",stage_done(),next_beat.." beats")
 start_stage(3)
 for spot in all(titan.spots) do hit_spot(spot,99,judgements[1]) end
 for i=1,46 do update_titan() end
 check("a titan stage is done once its hot spots are all gone",stage_done(),"dead "..tostr(titan.dead))

 reset("play")
 start_stage(3)
 for i=1,60 do update_play() end
 check("in a titan fight the road comes down to the bottom third",crest_y>=titan_horizon-2 and 128-crest_y<=128/3+4,"crest at "..flr(crest_y))
 local head=titan_y()-10
 check("and the titan stands against the sky",head>=16 and head<crest_y-40,"head at "..flr(head))
 for spot in all(titan.spots) do hit_spot(spot,99,judgements[1]) end
 for i=1,60 do update_play() end
 check("after it the road goes back up",crest_y<horizon+3,"crest at "..flr(crest_y))
 reset("play")
 start_stage(3)
 titan.rise,crest_y=1,titan_horizon
 local dead=titan.spots[1]
 dead.hp=0
 for i=1,30 do update_titan() end
 local smoke=0
 for spark in all(sparks) do if spark.float then smoke+=1 end end
 cls()
 draw_titan()
 local sx,sy=spot_xy(dead)
 check("a destroyed street smokes and shows a crack",smoke>3 and pget(sx-1,sy)==0,smoke.." puffs, crack colour "..pget(sx-1,sy))
 reset("play")
 send_alien(0,0)
 send_alien(0,2,kinds.civilian)
 clock=5.9
 equip(2)
 update_aliens()
 local overtaken=front_alien(0).penalty
 step_to(6.01)
 check("a fleeing civilian overtakes an alien and blocks its street",overtaken and front_alien(0).penalty,"front is "..(front_alien(0).penalty and "the civilian" or "the alien"))
 local alien=aliens[1].penalty and aliens[2] or aliens[1]
 check("a shot into the civilian costs points and spares the alien",alien.hp==alien_hp and score==0 and combo==0,"alien hp "..alien.hp..", score "..score)
 clock=2+kinds.civilian.walk+1
 update_aliens()
 check("a civilian who reaches the bottom costs nothing",robot.hp==max_hp and not front_alien(0).penalty,"hp "..robot.hp)

 reset("play")
 send_alien(0,0)
 send_alien(0,2.2,kinds.civilian)
 score,robot.lane,clock=100,1,5.9
 equip(2)
 step_to(6.01)
 robot.lane=0
 step_frames(2)
 check("passing through a civilian's street just after a beat does not shoot them",score==100 and front_alien(0).penalty,"score "..score)

 reset("play")
 start_stage(3)
 local lit=""
 for lane in all({-1,1,0}) do
  hit_spot(titan.spots[lane+2],1,judgements[1])
  lit..=lamps_lit().." "
 end
 check("one shot on each hot spot rings the bell",lit=="1 2 3 " and score==bell_bonus and titan.rung,"lamps "..lit.."score "..score)
 for spot in all(titan.spots) do spot.lit=nil end
 for spot in all(titan.spots) do hit_spot(spot,1,judgements[1]) end
 check("the bell rings only once a giant",stats.bells==1,stats.bells.." bells")
 reset("play")
 start_stage(3)
 hit_spot(titan.spots[1],1,judgements[1])
 hit_spot(titan.spots[1],1,judgements[1])
 check("a second shot on a lit spot puts the lamps out",lamps_lit()==0,"lamps "..lamps_lit())
 hit_spot(titan.spots[2],1,judgements[1])
 hit_spot(titan.spots[1],99,judgements[1])
 hit_spot(titan.spots[3],1,judgements[1])
 check("destroying a hot spot before the bell takes the bell away",stats.bells==0 and titan.bell_lost,stats.bells.." bells")
 printh("ok giant")
 extcmd("shutdown")
end

local done
function _update()
 if not done then
  done=true
  run_frame(giant)
 end
end
function _draw() end
