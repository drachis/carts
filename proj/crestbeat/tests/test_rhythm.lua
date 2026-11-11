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
