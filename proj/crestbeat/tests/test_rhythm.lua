local game_draw=_draw
local alien_hp,walk_beats=kinds.alien.hp,kinds.alien.walk
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
  clock=-0.1
  equip(gun)
  local heard=split("........","")
  while clock<3.95 do
   local before=robot.shots
   step_frames(1)
   if robot.shots>before then heard[flr(clock*2)+1]="x" end
  end
  local played=""
  for slot in all(heard) do played..=slot end
  check(guns[gun].name.." fires on its pattern",played==guns[gun].pattern,played.." for "..guns[gun].pattern)
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
 check(name.." hits only the front alien in the street",aliens[1].hp==alien_hp and aliens[2].hp==alien_hp-2,aliens[1].hp.." behind, "..aliens[2].hp.." in front")

 name=armed(3,{-1,0,1})
 step_to(6.01)
 check(name.." kill their target and splash the streets beside",#aliens==2 and aliens[1].hp==alien_hp-guns[3].splash,#aliens.." left, hp "..aliens[1].hp)
 check("a killed alien is knocked down where it stood",#fallen==1 and fallen[1].x==64,#fallen.." down")
 game_draw()
 game_draw()
 dump_screen("rhythm_knockdown")
 fallen[1].age=0
 for i=1,6 do draw_fallen() end
 check("and lies flat after a few frames",fallen[1] and fallen[1].age==6,"age "..tostr(fallen[1] and fallen[1].age))

 reset("play")
 send_alien(-1,0)
 clock=walk_beats+1
 update_aliens()
 check("an alien at the bottom costs a point of hp",robot.hp==max_hp-1 and #aliens==0,"hp "..robot.hp)

 reset("play")
 send_alien(1,0,kinds.gold)
 clock=12
 update_aliens()
 local stayed=#aliens
 clock=13
 update_aliens()
 check("a golden alien stays on screen for 12 beats",stayed==1 and #aliens==0,stayed.." at beat 12, "..#aliens.." at 13")
 check("and getting away costs nothing",robot.hp==max_hp,"hp "..robot.hp)
 reset("play")
 send_alien(0,0,kinds.gold)
 clock=3
 update_aliens()
 for i=1,kinds.gold.hp/2 do
  hit_alien(aliens[1] or {},2,judgements[1])
 end
 check("a golden alien takes twice the hits and pays its bonus",#aliens==0 and score==kinds.gold.bonus,"score "..score)
 reset("play")
 send_alien(-1,0,kinds.gold)
 local streets=""
 for beat=1,8,kinds.gold.track do
  clock=beat
  update_aliens()
  streets..=aliens[1].lane.." "
 end
 check("a golden alien crosses the streets halfway up the hill",streets=="-1 0 1 " and aliens[1].t==kinds.gold.depth,"streets "..streets.."at depth "..aliens[1].t)
 reset("play")
 send_alien(-1,0,kinds.gold)
 send_alien(0,-2)
 clock=4
 update_aliens()
 check("and an alien nearer in its street shields it",front_alien(0) and not front_alien(0).harmless and #aliens==2,"front is "..(front_alien(0).harmless and "gold" or "an alien"))

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
 start_stage(3)
 for i=1,60 do update_play() end
 check("in a titan fight the road comes down to the bottom third",crest_y>=titan_horizon-2 and 128-crest_y<=128/3+4,"crest at "..flr(crest_y))
 local head=titan_y()-10
 check("and the titan stands against the sky",head>=16 and head<crest_y-40,"head at "..flr(head))
 for spot in all(titan.spots) do hit_spot(spot,99,judgements[1]) end
 for i=1,60 do update_play() end
 check("after it the road goes back up",crest_y<horizon+3,"crest at "..flr(crest_y))

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
