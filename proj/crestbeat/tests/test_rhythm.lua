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

 name=armed(3,{-1,0,0,1})
 step_to(8.01)
 local splashed,spared=0,0
 for alien in all(aliens) do
  if alien.lane==0 then splashed=alien_hp-alien.hp else spared+=alien_hp-alien.hp end
 end
 check(name.." kill their target and splash only the alien close behind it",#aliens==3 and splashed==guns[3].damage*guns[3].splash and spared==0,#aliens.." left, splash "..splashed..", other streets lost "..spared)
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
 on_beat(4)
 local charted=lane_of(sub(stages[1].chart,5,5),kinds.alien.keys)
 check("the chart sends an alien on its beat",#aliens==1 and aliens[1].lane==charted,#aliens.." sent")


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
