local game_draw=_draw
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

local function armed(gun,lanes,lane)
 reset("play")
 for i,alien_lane in ipairs(lanes) do send_alien(alien_lane,i-1) end
 robot.lane=lane or 0
 clock=#lanes+2.9
 equip(gun)
 update_aliens()
 return guns[gun].name
end

local function rhythm()
 for gun=1,#guns do
  reset("play")
  equip(gun)
  step_frames(flr(4*frames_per_beat+1))
  check(guns[gun].name.." fires "..(4/guns[gun].every).." times a bar",robot.shots==4/guns[gun].every,robot.shots.." shots")
 end

 local name=armed(2,{0})
 step_to(4.01)
 check(name.." hits the alien in its street on the beat",aliens[1].hp==alien_hp-2,"hp "..aliens[1].hp)
 check("and knocks it back up the hill",aliens[1].born>0,"born "..aliens[1].born)

 armed(2,{0},1)
 step_to(4.01)
 robot.lane=0
 step_frames(good_window-2)
 check("arriving just after the beat still lands a late shot",aliens[1].hp==alien_hp-2,"hp "..aliens[1].hp)

 armed(2,{0},1)
 step_to(4.01)
 step_frames(good_window+2)
 robot.lane=0
 step_frames(2)
 check("arriving too late does not",aliens[1].hp==alien_hp,"hp "..aliens[1].hp)

 armed(2,{0},1)
 step_to(4.01)
 check("a beat with nothing in the street fires nothing",aliens[1].hp==alien_hp and #beams==0,"hp "..aliens[1].hp..", "..#beams.." beams")
 check("and the robot's lights glow instead",robot.glow>0,"glow "..robot.glow)

 name=armed(1,{0})
 step_to(4.01)
 local after_one=aliens[1].hp
 step_to(4.51)
 check(name.." hits once a half beat",after_one==alien_hp-1 and aliens[1].hp==alien_hp-2,after_one.." then "..aliens[1].hp)

 name=armed(2,{0,0})
 step_to(5.01)
 check(name.." hits every alien in the street",aliens[1].hp==alien_hp-2 and aliens[2].hp==alien_hp-2,aliens[1].hp.." and "..aliens[2].hp)

 name=armed(3,{-1,0,1})
 step_to(6.01)
 check(name.." kill their target and splash the streets beside",#aliens==2 and aliens[1].hp==alien_hp-guns[3].splash,#aliens.." left, hp "..aliens[1].hp)

 reset("play")
 send_alien(-1,0)
 clock=walk_beats+1
 update_aliens()
 check("an alien at the bottom costs a point of hp",robot.hp==max_hp-1 and #aliens==0,"hp "..robot.hp)

 reset("play")
 on_beat(4)
 check("the chart sends an alien on its beat",#aliens==1 and aliens[1].lane==-1,#aliens.." sent")

 reset("play")
 start_stage(3)
 local spot=titan.spots[2]
 open_spot(0,4)
 clock=3.9
 equip(2)
 step_to(4.01)
 check("a shot at an open hot spot hurts it",spot.hp==stages[3].spot_hp-2,"hp "..spot.hp)
 reset("play")
 start_stage(3)
 spot=titan.spots[2]
 clock=3.9
 equip(2)
 step_to(4.01)
 check("a closed hot spot cannot be hurt",spot.hp==stages[3].spot_hp,"hp "..spot.hp)

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
 next_beat=#stages[1].chart
 check("a swarm is done when its chart is played and no alien is left",stage_done(),next_beat.." beats")
 start_stage(3)
 for spot in all(titan.spots) do hit_spot(spot,99,judgements[1]) end
 for i=1,46 do update_titan() end
 check("a titan stage is done once its hot spots are all gone",stage_done(),"dead "..tostr(titan.dead))

 reset("play")
 start_stage(#stages)
 titan.rise=1
 clock=10
 send_alien(0,10-0.253)
 update_aliens()
 game_draw()
 local rising=0
 for x=58,70 do
  for y=crest_y-10,crest_y-1 do
   if pget(x,y)==11 then rising+=1 end
  end
 end
 check("an alien rising over the crest is drawn in front of the queen",rising>10,rising.." green pixels")
 local below=pget(64,crest_y+10)
 check("the queen stands behind the crest, not on the road",below!=titan.colour and below!=2,"colour "..below)
 dump_screen("rhythm_queen")

 printh("ok rhythm")
 extcmd("shutdown")
end

local done
function _update()
 if not done then
  done=true
  run_frame(rhythm)
 end
end
function _draw() end
