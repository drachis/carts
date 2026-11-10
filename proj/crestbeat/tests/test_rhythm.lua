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
