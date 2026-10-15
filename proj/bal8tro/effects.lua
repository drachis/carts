particles,timers,shake,freeze,flash_frames,chips_bump,mult_bump,heat={},{},0,0,0,0,0,0

function emit(name,x,y,colour,amount)
 local spec=vfx_specs[name]
 for i=1,amount or spec.count do
  local angle,speed=rnd(),rnd(spec.speed)
  local life=spec.life*(.5+rnd(.5))
  add(particles,{
   x=x+rnd(spec.width),y=y,
   vx=cos(angle)*speed,vy=sin(angle)*speed-spec.rise*(.5+rnd()),
   life=life,full=life,spec=spec,colour=colour
  })
 end
end

function kick(thing,amount)
 thing.kick,thing.juice=amount,0
end

function turn_over(card)
 card.flip=0
end

function after(frames,action)
 add(timers,{frames=frames,action=action})
end

function hitstop(frames)
 freeze=max(freeze,frames)
end

function flash(frames)
 flash_frames=max(flash_frames,frames)
end

function jiggle(thing)
 local age=thing.juice or juice_frames
 thing.swell=0
 if age>=juice_frames then return 0,0 end
 thing.juice+=1
 local left=1-age/juice_frames
 thing.swell=-thing.kick*sin(age*.135)*left*left*left
 return thing.kick*sin(age*.108)*left*left/2,0
end

function flame_band(left,right,base,height)
 for x=left,right,2 do
  local tall=1+rnd(height)
  rectfill(x,base-tall,x+1,base,8)
  rectfill(x,base-tall/2,x+1,base,9)
  rectfill(x,base-1,x+1,base,10)
 end
end

function draw_flames()
 if heat<1 then return end
 flame_band(chips_x-1,mult_x+16,boxes_y-1,2+min(heat,4)*2)
end

function draw_floor_fire()
 if heat>=2 then flame_band(0,heat>=3 and 127 or 37,127,min(heat*3,20)) end
end

function fan_flames()
 local target=mode=="score" and hand_total(chips,mult)/goal or 0
 heat=target>heat and target or heat*.96
 if heat<1 then return end
 for left=chips_x,mult_x,mult_x-chips_x do emit("flame",left,boxes_y,nil,min(heat,4)) end
 if heat>=4 then emit("flame",rnd(112),127,nil,min(heat\2,6)) end
end

function update_effects()
 for timer in all(timers) do
  timer.frames-=1
  if timer.frames<=0 then
   del(timers,timer)
   timer.action()
  end
 end
 fan_flames()
 for p in all(particles) do
  p.x+=p.vx
  p.y+=p.vy
  p.vy+=p.spec.gravity
  p.life-=1
  if p.life<0 then del(particles,p) end
 end
 shake=shake>.5 and shake*.85 or 0
 chips_bump,mult_bump=max(chips_bump-.25,0),max(mult_bump-.25,0)
end

function draw_swirl(base,stripes,top)
 cls(base)
 fillp(▒)
 local time=t()
 for y=top,127,2 do
  local offset=(sin(y/96+time/10)*24+y/2+time*6)%32
  for x=offset-32,127,32 do rectfill(x,y,x+15,y+1,stripes) end
 end
 fillp()
end

function shake_camera()
 camera(rnd(shake)-shake/2,rnd(shake)-shake/2)
end

function draw_particles()
 for p in all(particles) do
  local ramp,colour=p.spec.ramp,p.life<6 and 5 or p.colour
  if ramp then colour=ramp[ceil(p.life/p.full*#ramp)] end
  line(p.x,p.y,p.x-p.vx*2,p.y-p.vy*2,colour)
 end
 if flash_frames>0 then
  flash_frames-=1
  fillp(▒)
  rectfill(40,0,127,127,7)
  fillp()
 end
end

function panel_at(y)
 return {glide_x=0,glide_y=y,wait=0}
end
