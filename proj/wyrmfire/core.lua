function length(x,y)
 x/=64
 y/=64
 return sqrt(x*x+y*y)*64
end

function dragon_distance(x,y)
 return length(x-dragon.x,y-dragon.y)
end

function angle_diff(a,b)
 return (a-b+.5)%1-.5
end

function on_screen(x,y,margin)
 return x>cam_x-margin and x<cam_x+128+margin
  and y>cam_y-margin and y<cam_y+128+margin
end

function announce(text,frames)
 message,message_timer=text,frames or 90
end

function print_centered(text,y,color)
 local x=64-#text*2
 print(text,x+1,y+1,0)
 print(text,x,y,color or fire_ramp[2+frame\2%4])
end

function jolt(amount,stop)
 shake=max(shake,amount)
 freeze=max(freeze,stop or 0)
end

fire_ramp=split"5,8,9,10,7"

function add_particle(x,y,vx,vy,life,kind,ember)
 local p={x=x,y=y,vx=vx,vy=vy,life=life,span=life,kind=kind,ember=ember}
 if #particles<max_particles then
  add(particles,p)
 end
 return p
end

function ring(x,y,size)
 add_particle(x,y,0,0,10,"ring").size=size
end

function splat(x,y)
 ring(x,y,8)
 for i=1,6 do
  add_particle(x,y,rnd(4)-2,rnd(4)-2,12,"debris").color=8
 end
end

function coins(x,y,count)
 for i=1,count do
  add_particle(x,y,rnd(6)-3,rnd(6)-3,600,"coin")
 end
end

function embers(x,y,count,speed)
 for i=1,count do
  add_particle(x,y,cos(i/count)*speed,sin(i/count)*speed,14+rnd(8),"fire",true)
 end
end

function burst(x,y,count,spread)
 for i=1,count do
  add_particle(
   x+rnd(spread)-spread/2,y+rnd(spread)-spread/2,
   rnd(2)-1,rnd(2)-1.5,10+rnd(12),
   rnd{"smoke","debris","debris"})
 end
end

function update_particles()
 for p in all(particles) do
  p.x+=p.vx
  p.y+=p.vy
  p.life-=1
  if p.kind=="fire" then
   p.vx*=.92
   p.vy*=.92
   local home=p.ember and frame%4==0 and dome_over(p.x,p.y)
   if home then
    p.vx=p.vx*.3+(p.x-home.tx*8)/40
    p.vy=p.vy*.3+(p.y-home.ty*8)/40
   end
  elseif p.kind=="coin" then
   p.vx*=.9
   p.vy*=.9
   if p.span-p.life>12 then
    local dx,dy=dragon.x-p.x,dragon.y-p.y
    if p.meal then
     dx,dy=cam_x+34-p.x,cam_y+4-p.y
    end
    local distance=max(length(dx,dy),1)
    p.vx+=dx/distance*.8
    p.vy+=dy/distance*.8
    if distance<8 then
     p.life=0
     if p.meal then
      feed(p.meal)
     else
      collect_coin()
     end
    end
   end
  end
  if p.life<=0 then
   if p.ember and rnd()<.3 then
    ignite(p.x\8,p.y\8)
   end
   del(particles,p)
  end
 end
end

function draw_particles()
 for p in all(particles) do
  local life=p.life
  if p.kind=="fire" then
   circfill(p.x,p.y,life/(p.ramp and 5/dragon.size or 6),(p.ramp or fire_ramp)[min(life\4+1,5)])
  elseif p.kind=="smoke" then
   circfill(p.x,p.y,1,life>10 and 5 or 6)
  elseif p.kind=="ring" then
   circ(p.x,p.y,p.size*(p.span-life)\p.span,life>4 and 7 or 9)
  elseif p.meal then
   local tumbling=life%6<3
   spr(p.sprite,p.x-4,p.y-4,1,1,tumbling,tumbling)
  elseif p.kind=="coin" then
   circfill(p.x,p.y,1,life%6<3 and 10 or 9)
   pset(p.x,p.y-1,7)
  elseif p.kind=="text" then
   print(p.text,p.x-#p.text*2,p.y,life%4<2 and 7 or 10)
  else
   circfill(p.x,p.y,p.color and 1 or 0,p.color or life>8 and 6 or 4)
  end
 end
end

function draw_flames(x,y,size,count)
 for i=1,count do
  circfill(x+rnd(size),y+rnd(size),rnd(2),rnd{8,9,10})
 end
end
