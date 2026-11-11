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
 local name
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
 on_beat(4)
 local charted=lane_of(sub(stages[1].chart,5,5),kinds.alien.keys)
 check("the chart sends an alien on its beat",#aliens==1 and aliens[1].lane==charted,#aliens.." sent")


 printh("ok rhythm2")
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
