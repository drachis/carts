function sfx() end
music=sfx

local function check(name,passed,detail)
 printh((passed and "pass: " or "error: ")..name.." ("..tostr(detail)..")")
end

local function at(beat,frames)
 clock=beat+frames/frames_per_beat
end

local function fresh_alien(lane)
 reset("play")
 send_alien(lane,0)
 at(4,0)
 update_aliens()
 return aliens[1]
end

local function rhythm()
 reset("play")
 at(3,0)
 check("a shot on the beat is perfect",judge().name=="perfect","0 frames")
 reset("play")
 at(3,-perfect_window)
 check("a shot just inside the perfect window is perfect",judge().name=="perfect",perfect_window.." frames early")
 reset("play")
 at(3,perfect_window+1)
 check("a shot just outside it is good",judge().name=="good",(perfect_window+1).." frames late")
 reset("play")
 at(3,good_window+1)
 check("a shot outside the good window misses",judge().name=="miss",(good_window+1).." frames late")
 reset("play")
 at(3,0)
 judge()
 check("a second shot on the same beat misses",judge().name=="miss","beat 3 twice")

 local alien=fresh_alien(0)
 local before=alien.t
 shoot()
 update_aliens()
 check("a perfect shot hurts the front alien",alien.hp==alien_hp-1,"hp "..alien.hp)
 check("and knocks it back up the hill",alien.t<before,before.." to "..alien.t)

 alien=fresh_alien(0)
 at(4,good_window+2)
 shoot()
 check("a miss does no harm",alien.hp==alien_hp,"hp "..alien.hp)

 alien=fresh_alien(1)
 shoot()
 check("a shot in another lane does no harm",alien.hp==alien_hp,"hp "..alien.hp)

 alien=fresh_alien(0)
 shoot()
 at(5,0)
 shoot()
 check("two hits kill",#aliens==0,#aliens.." left")

 fresh_alien(-1)
 at(walk_beats+1,0)
 update_aliens()
 check("an alien at the bottom costs a point of hp",robot.hp==max_hp-1 and #aliens==0,"hp "..robot.hp)

 reset("play")
 on_beat(4)
 check("the chart sends an alien on its beat",#aliens==1 and aliens[1].lane==-1,#aliens.." sent")

 reset("play")
 start_stage(3)
 local spot=titan.spots[2]
 open_spot(0,4)
 at(4,0)
 shoot()
 check("a shot at an open hot spot hurts it",spot.hp==stages[3].spot_hp-1,"hp "..spot.hp)
 at(8,0)
 shoot()
 check("a closed hot spot cannot be hurt",spot.hp==stages[3].spot_hp-1,"hp "..spot.hp)

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
 for spot in all(titan.spots) do hit_spot(spot,9,judgements[1]) end
 for i=1,91 do update_titan() end
 check("a titan stage is done once its hot spots are all gone",stage_done(),"dead "..tostr(titan.dead))

 printh("ok rhythm")
 extcmd("shutdown")
end

local done
function _update60()
 if not done then
  done=true
  run_frame(rhythm)
 end
end
function _draw() end
