function reset_robot()
 robot={lane=0,x=64,hp=max_hp,hurt=0,recoil=0,lift=0,shots=0,glow=0}
 equip(start_gun)
end

function equip(gun)
 robot.gun=gun
 robot.last_tick=flr(clock*2)
 robot.waiting=nil
end

function fires_on(gun,eighth)
 local slot=eighth%8+1
 return sub(gun.pattern,slot,slot)=="x"
end

function update_robot()
 local step=(btnp(1) and 1 or 0)-(btnp(0) and 1 or 0)
 if step!=0 and mid(-1,robot.lane+step,1)!=robot.lane then
  robot.lane+=step
  sfx(5)
 end
 local swap=(btnp(5) and 1 or 0)-(btnp(4) and 1 or 0)
 if swap!=0 then
  equip((robot.gun+swap-1)%#guns+1)
  popup(guns[robot.gun].name,robot.x,68-robot.lift,guns[robot.gun].colour)
  sfx(5)
 end
 robot.x+=(64+robot.lane*40-robot.x)*0.6
 robot.hurt=max(robot.hurt-1)
 robot.glow=max(robot.glow-1)
 robot.recoil*=0.5
 update_gun()
end

function target_in(lane)
 return front_alien(lane) or open_spot_in(lane)
end

function update_gun()
 local tick,target=flr(clock*2),target_in(robot.lane)
 if tick!=robot.last_tick and fires_on(guns[robot.gun],tick) then
  robot.last_tick=tick
  robot.shots+=1
  if target then
   fire(judgements[1])
  else
   robot.waiting=clock
   if #aliens>0 then combo=0 end
   robot.glow=4
  end
 elseif robot.waiting and target and not target.penalty then
  if (clock-robot.waiting)*frames_per_beat<=good_window then
   fire(judgements[2])
   popup("late",robot.x,76-robot.lift,10)
  end
  robot.waiting=nil
 end
end

function fire(judgement)
 robot.waiting=nil
 robot.recoil=3
 local gun,lane=guns[robot.gun],robot.lane
 local gun_x,gun_y=robot.x,93-robot.lift
 sfx(gun.sound)
 combo+=1
 score+=judgement.points*multiplier()
 strike(target_in(lane),gun.damage,judgement,gun_x,gun_y,gun)
 if gun.splash then
  for side=-1,1,2 do
   local alien=front_alien(lane+side)
   if alien then strike(alien,gun.splash,judgement,gun_x,gun_y,gun) end
  end
 end
end

function strike(target,amount,judgement,gun_x,gun_y,gun)
 local x,y
 if target.open then x,y=spot_xy(target) else x,y=alien_centre(target) end
 add(beams,{x1=gun_x,y1=gun_y,x2=x,y2=y,colour=judgement==judgements[1] and gun.colour or 10,
  width=amount\2,life=4})
 if gun.splash then ring(x,y,amount*3,9) end
 if target.open then hit_spot(target,amount,judgement) else hit_alien(target,amount,judgement) end
end

function multiplier()
 return min(combo\8+1,4)
end

function hurt_robot(lane)
 robot.hp-=1
 robot.hurt=10
 shake+=6
 combo=0
 local x,y=project(lane,1)
 burst(x,y,20,8,3)
 sfx(4)
end

function draw_robot()
 local top=84+(pulse>0.5 and 1 or 0)+robot.recoil-robot.lift
 if robot.lift>1 then
  for jet=-8,8,16 do
   for step=0,robot.lift do
    circfill(robot.x+jet+rnd(2)-1,top+30+step,2.5*(1-step/(robot.lift+1)),step<4 and 7 or step<9 and 10 or 9)
   end
  end
 end
 for colour=1,15 do pal(colour,0) end
 for nudge=-1,1,2 do
  sspr(0,64,24,24,robot.x-18+nudge,top,36,36)
  sspr(0,64,24,24,robot.x-18,top+nudge,36,36)
 end
 pal()
 if robot.hurt>0 and robot.hurt%4<2 then
  for colour=1,15 do pal(colour,7) end
 elseif robot.glow>0 then
  pal(9,guns[robot.gun].colour)
  pal(10,7)
 end
 sspr(0,64,24,24,robot.x-18,top,36,36)
 pal()
end
