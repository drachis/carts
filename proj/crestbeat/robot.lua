function reset_robot()
 robot={lane=0,x=64,vx=0,hp=max_hp,hurt=0,recoil=0,lift=0,shots=0,glow=0,moved=0,trail={}}
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
  robot.moved=clock
  sfx(5)
 end
 local swap=(btnp(5) and 1 or 0)-(btnp(4) and 1 or 0)
 if swap!=0 then
  equip((robot.gun+swap-1)%#guns+1)
  popup(guns[robot.gun].name,robot.x,68-robot.lift,guns[robot.gun].colour)
  sfx(5)
 end
 robot.vx=(robot.vx+(64+robot.lane*40-robot.x)*robot_spring)*robot_damping
 robot.x+=robot.vx
 for ghost in all(robot.trail) do
  ghost.life-=1
  if ghost.life<1 then del(robot.trail,ghost) end
 end
 if abs(robot.vx)>1.5 then add(robot.trail,{x=robot.x,life=6}) end
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
   local spot=titan and titan.rise==1 and not titan.dead and titan.spots[robot.lane+2]
   if spot and spot.hp>0 then
    local x,y=spot_xy(spot)
    add(beams,{x1=robot.x-cam_x,y1=93-robot.lift,x2=x,y2=y,colour=12,width=0,life=3})
    burst(x,y,3,12,1)
    spot.flash=4
   end
  end
 elseif robot.waiting and target and not target.penalty then
  if (clock-robot.waiting)*frames_per_beat<=good_window then
   fire(judgements[2])
  end
  robot.waiting=nil
 end
end

function fire(judgement)
 robot.waiting=nil
 robot.recoil=3
 local gun,lane=guns[robot.gun],robot.lane
 local gun_x,gun_y=robot.x-cam_x,93-robot.lift
 sfx(gun.sound)
 ring(gun_x,gun_y,5,gun.colour)
 combo+=1
 score+=judgement.points*multiplier()
 local target=target_in(lane)
 strike(target,gun.damage,judgement,gun_x,gun_y,gun)
 if gun.splash and not target.open then
  for alien in all(aliens) do
   if alien!=target and abs(alien.t-target.t)<splash_reach and abs(alien.pos-target.pos)<0.5 then
    strike(alien,gun.damage*gun.splash,judgement,gun_x,gun_y,gun)
   end
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
 local top,x=84+(1-pulse)*1.5+robot.recoil-robot.lift,robot.x-cam_x
 if robot.lift>1 then
  for jet=-8,8,16 do
   for step=0,robot.lift do
    circfill(x+jet+rnd(2)-1,top+30+step,2.5*(1-step/(robot.lift+1)),step<4 and 7 or step<9 and 10 or 9)
   end
  end
 end
 from_map(36,function()
  for ghost in all(robot.trail) do
   for colour=1,15 do pal(colour,({2,14,12})[ghost.life\3+1]) end
   sspr(0,0,36,36,ghost.x-cam_x-18,top)
  end
  for colour=1,15 do pal(colour,0) end
  for nudge=-1,1,2 do
   sspr(0,0,36,36,x-18+nudge,top)
   sspr(0,0,36,36,x-18,top+nudge)
  end
  pal()
  if robot.hurt>0 and robot.hurt%4<2 then
   for colour=1,15 do pal(colour,7) end
  elseif robot.glow>0 then
   pal(9,guns[robot.gun].colour)
   pal(10,7)
  end
  sspr(0,0,36,36,x-18,top)
  pal()
 end)
end

function from_map(size,draw)
 for row=0,size-1 do
  memcpy(0x8000+row*64,row*64,size/2)
  memcpy(row*64,0x2000+row*64,size/2)
 end
 draw()
 for row=0,size-1 do
  memcpy(row*64,0x8000+row*64,size/2)
 end
end
