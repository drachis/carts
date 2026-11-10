local game_draw=_draw
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

 reset("play")
 send_pickup(0,0)
 at(4,0)
 update_aliens()
 shoot()
 check("shooting a pickup equips its gun",robot.gun==2 and robot.ammo==guns[2].ammo,guns[robot.gun].name.." "..robot.ammo)
 check("pickups come round the guns in turn",(function() send_pickup(0,0) return aliens[1].gun==3 end)(),"next "..tostr(aliens[1] and aliens[1].gun))

 reset("play")
 send_pickup(-1,0)
 at(walk_beats+1,0)
 update_aliens()
 check("a pickup that gets past costs nothing",robot.hp==max_hp and #aliens==0,"hp "..robot.hp)

 local function armed(gun,lanes)
  reset("play")
  robot.gun,robot.ammo=gun,guns[gun].ammo
  for i,lane in ipairs(lanes) do send_alien(lane,i-1) end
  at(#lanes+3,0)
  update_aliens()
  shoot()
  return guns[gun].name
 end
 local name=armed(2,{0})
 check(name.." kills a fresh alien in one shot",#aliens==0 and robot.ammo==guns[2].ammo-1,#aliens.." left, ammo "..robot.ammo)
 name=armed(3,{0,0})
 check(name.." hits every alien in the lane",aliens[1].hp==alien_hp-1 and aliens[2].hp==alien_hp-1,aliens[1].hp.." and "..aliens[2].hp)
 name=armed(4,{-1,0,1})
 check(name.." kills its target and hurts the lanes beside it",#aliens==2 and aliens[1].hp<alien_hp and aliens[2].hp<alien_hp,#aliens.." left")
 armed(2,{0})
 robot.ammo=1
 send_alien(0,4)
 at(8,0)
 update_aliens()
 shoot()
 check("a gun that runs dry goes back to pulse",robot.gun==1,guns[robot.gun].name)

 reset("play")
 start_stage(#stages)
 titan.rise=1
 at(10,0)
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
function _update60()
 if not done then
  done=true
  run_frame(rhythm)
 end
end
function _draw() end
