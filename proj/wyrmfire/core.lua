-- core.lua : maths, particles and text shared by every module.

-- vector length, scaled so the squares stay inside 16.16 fixed point
function length(x,y)
 x/=64
 y/=64
 return sqrt(x*x+y*y)*64
end

-- how far the dragon is from a point
function dragon_distance(x,y)
 return length(x-dragon.x,y-dragon.y)
end

-- signed shortest difference between two angles, in turns
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
 print(text,x,y,color)
end

function jolt(amount)
 shake=max(shake,amount)
end

-- kind is "fire", "smoke" or "debris". embers ignite where they die.
function add_particle(x,y,vx,vy,life,kind,ember)
 if #particles<config.max_particles then
  add(particles,{x=x,y=y,vx=vx,vy=vy,life=life,kind=kind,ember=ember})
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
   -- white hot, cooling through yellow and red to smoke
   local color=life>18 and 7 or life>12 and 10 or life>7 and 9 or life>3 and 8 or 5
   circfill(p.x,p.y,life\6,color)
  elseif p.kind=="smoke" then
   circfill(p.x,p.y,1,life>10 and 5 or 6)
  else
   pset(p.x,p.y,life>8 and 6 or 4)
  end
 end
end

function draw_flames(x,y,size,count)
 for i=1,count do
  circfill(x+rnd(size),y+rnd(size),rnd(2),rnd{8,9,10})
 end
end
