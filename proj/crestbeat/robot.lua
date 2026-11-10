function reset_robot()
 robot={lane=0,x=64,hp=max_hp,hurt=0,recoil=0}
 last_shot_beat=nil
end

function update_robot()
 local step=(btnp(1) and 1 or 0)-(btnp(0) and 1 or 0)
 if step!=0 and mid(-1,robot.lane+step,1)!=robot.lane then
  robot.lane+=step
  sfx(5)
 end
 robot.x+=(64+robot.lane*40-robot.x)*0.4
 robot.hurt=max(robot.hurt-1)
 robot.recoil*=0.7
 if btnp(4) or btnp(5) then shoot() end
end

function judge()
 local nearest=flr(clock+0.5)
 local off=abs(clock-nearest)*frames_per_beat
 local grade=nearest!=last_shot_beat and (off<=perfect_window and 1 or off<=good_window and 2) or 3
 if grade<3 then last_shot_beat=nearest end
 return judgements[grade]
end

function shoot()
 local judgement=judge()
 local gun_x,gun_y=robot.x,93
 sfx(judgement.sound)
 popup(judgement.name,robot.x,76,judgement.colour)
 if judgement.points==0 then
  combo=0
  burst(gun_x,gun_y,4,5,1)
  return judgement
 end
 robot.recoil=3
 local alien=front_alien(robot.lane)
 if alien then
  local x,y,scale=alien_centre(alien)
  add(beams,{x1=gun_x,y1=gun_y,x2=x,y2=y,colour=judgement.colour,
   width=judgement.name=="perfect" and 2 or 1,life=5})
  combo+=1
  score+=judgement.points*multiplier()
  hit_alien(alien,judgement)
 end
 return judgement
end

function multiplier()
 return min(combo\4+1,4)
end

function hurt_robot(alien)
 robot.hp-=1
 robot.hurt=20
 shake+=6
 combo=0
 local x,y=project(alien.lane,1)
 burst(x,y,20,8,3)
 sfx(4)
end

function draw_robot()
 local bob=pulse>0.5 and 1 or 0
 local top=84+bob+robot.recoil
 for colour=1,15 do pal(colour,0) end
 for nudge=-1,1,2 do
  sspr(0,64,24,24,robot.x-18+nudge,top,36,36)
  sspr(0,64,24,24,robot.x-18,top+nudge,36,36)
 end
 pal()
 if robot.hurt>0 and robot.hurt%4<2 then
  for colour=1,15 do pal(colour,7) end
 end
 sspr(0,64,24,24,robot.x-18,top,36,36)
 pal()
end
