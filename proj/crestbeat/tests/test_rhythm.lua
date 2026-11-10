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
 check("and knocks it back up the hill",aliens[1].born+aliens[1].knock>0,"born "..aliens[1].born..", knock "..aliens[1].knock)

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
 check(name.." kill their target and splash the streets beside",#aliens==2 and aliens[1].hp==alien_hp-guns[3].damage*guns[3].splash,#aliens.." left, hp "..aliens[1].hp)
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
 local on_streets=0
 for beat=0,20 do
  clock=beat
  update_aliens()
  if aliens[1] and abs(aliens[1].lane)<=1 then on_streets+=1 end
 end
 check("a golden alien is on the streets for 12 beats",on_streets==12 and #aliens==0,on_streets.." beats")
 check("and getting away costs nothing",robot.hp==max_hp,"hp "..robot.hp)
 for kind in all(kinds) do
  if not kind.penalty then
   local counts,wanted="",""
   for gun in all(guns) do
    reset("play")
    send_alien(0,0,kind)
    local shots=0
    while #aliens>0 and shots<99 do
     hit_alien(aliens[1],gun.damage,judgements[1])
     shots+=1
    end
    counts..=shots.." "
    wanted..=ceil(kind.bars*gun.shots-0.001).." "
   end
   check("a "..kind.name.." lives for "..kind.bars.." bars of any gun's fire",counts==wanted,"shots "..counts.."for "..wanted)
  end
 end
 reset("play")
 send_alien(0,0,kinds.gold)
 hit_alien(aliens[1],99,judgements[1])
 check("a golden alien pays its bonus",score==kinds.gold.bonus and stats.golds==1 and stats.kills==0,"score "..score)

 reset("play")
 for i=1,10 do award("kills") end
 award("golds")
 award("civilians")
 award("civilians")
 start_payout(true)
 local lowest=panel_y
 for i=1,200 do
  update_payout()
  lowest=min(lowest,panel_y)
 end
 local expected=10*payouts.kills.each+payouts.golds.each+2*payouts.civilians.each+payouts.saved.each
 check("the payout adds up each row at level one",tickets==expected and #rows==4,tickets.." tickets in "..#rows.." rows, expected "..expected)
 check("and dispenses every one",dispensed==expected and flr(shown_tickets)==expected and payout_done(),dispensed.." dispensed")
 check("its panel springs up past its rest and settles",lowest<payout_rest-1 and abs(panel_y-payout_rest)<0.5,"lowest "..lowest..", rests at "..panel_y)
 reset("play")
 start_payout(false)
 check("a run with nothing pays one ticket",tickets==1,tickets.." tickets")

 reset("play")
 start_stage(#stages)
 local shots=0
 for spot in all(titan.spots) do
  spot.open=99
  while spot.hp>0 do
   hit_spot(spot,guns[2].damage,judgements[1])
   shots+=1
  end
 end
 printh("the queen takes "..shots.." shock rifle shots, "..(shots/guns[2].shots).." bars (asked for "..stages[#stages].bars..")")
 reset("play")
 send_alien(-1,0,kinds.gold)
 local streets=""
 for beat=4,12,kinds.gold.track do
  clock=beat
  update_aliens()
  streets..=aliens[1].lane.." "
 end
 check("a golden alien crosses the streets halfway up the hill",streets=="-1 0 1 " and aliens[1].t==kinds.gold.depth,"streets "..streets.."at depth "..aliens[1].t)
 clock=6.5
 update_aliens()
 check("straddling two streets it can be shot from either",front_alien(-1)==aliens[1] and front_alien(0)==aliens[1] and front_alien(1)==nil,"at "..aliens[1].pos)
 reset("play")
 send_alien(-1,0,kinds.gold)
 send_alien(0,-2)
 clock=4
 update_aliens()
 check("and an alien nearer in its street shields it",front_alien(0) and not front_alien(0).harmless and #aliens==2,"front is "..(front_alien(0).harmless and "gold" or "an alien"))

 reset("play")
 send_alien(-1,0,kinds.weaver)
 streets=""
 for beat=-0.6,7.5,2 do
  clock=beat
  update_aliens()
  streets..=aliens[1].lane.." "
 end
 check("a weaver walks down sweeping across the streets every two beats",streets=="-1 0 1 0 -1 ","streets "..streets)

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
 on_beat(4)
 local charted=lane_of(sub(stages[1].chart,5,5),kinds.alien.keys)
 check("the chart sends an alien on its beat",#aliens==1 and aliens[1].lane==charted,#aliens.." sent")

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
 start_stage(#stages)
 titan.rise=1
 clock=10
 send_alien(0,10-0.85)
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
 local function wing_rows()
  local top
  for y=0,crest_y do
   for x=30,48 do
    if pget(x,y)==2 and not top then top=y end
   end
  end
  return top or -1
 end
 aliens={}
 clock=10.5
 game_draw()
 local up=wing_rows()
 clock=11.5
 game_draw()
 local down=wing_rows()
 check("the giant's wings flap",up>=0 and down>=0 and abs(up-down)>=4,"wing tops at "..up.." and "..down)

 reset("play")
 local before=""
 for y=0,35,5 do for x=0,35,5 do before..=sget(x,y) end end
 cls()
 robot.recoil,robot.lift,pulse=0,0,0
 draw_robot()
 local after,red=""
 for y=0,35,5 do for x=0,35,5 do after..=sget(x,y) end end
 for y=84,119 do for x=46,81 do if pget(x,y)==8 then red=true end end end
 check("the robot is drawn from the map at its full size",red,"red found: "..tostr(red))
 check("and the sprite sheet it borrowed is put back",before==after,"sheet "..(before==after and "restored" or "changed"))

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
