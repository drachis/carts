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
 printh("ok giant2")
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
