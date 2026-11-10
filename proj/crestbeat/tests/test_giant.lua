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
