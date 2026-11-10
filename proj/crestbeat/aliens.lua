function send_alien(lane,beat,kind)
 kind=kind or kinds[1]
 local dir=lane<0 and 1 or -1
 add(aliens,setmetatable({lane=lane,pos=lane,start=-2*dir,dir=dir,born=beat,hp=kind.bars*8,flash=0,t=-1},kind))
end

function update_aliens()
 for alien in all(aliens) do
  local beats=(clock-alien.born)/(alien.track or 1)
  local whole=flr(beats)
  alien.hop=beats-whole
  local step=whole+min(1,alien.hop*3)
  alien.flash=max(alien.flash-1)
  if alien.track then
   alien.t,alien.pos=alien.depth,alien.start+alien.dir*step
   alien.lane=flr(alien.pos+0.5)
  else
   alien.t=(step-1)/alien.walk
  end
  if alien.t>=1 or abs(alien.pos)>2.2 then
   del(aliens,alien)
   if alien.bonus>0 then
    popup("got away",robot.x,70,alien.body)
   elseif not alien.harmless then
    hurt_robot(alien.lane)
   end
  end
 end
 sort_by_t(aliens)
end

function front_alien(lane)
 local front
 for alien in all(aliens) do
  if alien.lane==lane and alien.t>-0.05 then front=alien end
 end
 return front
end

function hit_alien(alien,amount,judgement)
 alien.flash=3
 if alien.penalty then
  score=max(score-alien.penalty)
  combo=0
  local x,y=alien_centre(alien)
  popup("hey! -"..alien.penalty.."0",x,y-10,8)
  sfx(4)
  return
 end
 alien.hp-=amount
 alien.born+=amount*knock_per_damage*judgement.knock
 local x,y,scale=alien_centre(alien)
 burst(x,y,4,judgement.colour,2)
 if alien.hp<0.01 then
  del(aliens,alien)
  burst(x,y,12,alien.body,2)
  shake+=2
  sfx(3)
  if alien.bonus>0 then
   score+=alien.bonus
   popup("+"..alien.bonus.."0",x,y-8,alien.body)
   ring(x,y,16,alien.body)
  end
  local foot_x,foot_y=project(alien.pos,alien.t)
  add(fallen,{x=foot_x,y=foot_y,size=24*scale,age=0,kind=getmetatable(alien)})
 end
end

function kind_colours(kind,dark)
 pal(11,dark and kind.rim or kind.body)
 pal(3,kind.rim)
end

function draw_fallen()
 for body in all(fallen) do
  body.age+=1
  local height=body.size*max(0.15,1-body.age/5)
  kind_colours(body.kind,body.age>4)
  sspr(0,0,16,16,body.x-body.size/2,body.y-height,body.size,height)
  pal()
  if body.age>24 then del(fallen,body) end
 end
end

function alien_centre(alien)
 local x,y,scale=project(alien.pos,alien.t)
 scale*=alien.size
 return x,y-12*scale,scale
end

function draw_aliens(behind)
 for alien in all(aliens) do
  if (alien.t<0)==behind then
   local x,y,scale=project(alien.pos,alien.t)
   local size=24*scale*alien.size
   local lift=alien.hop<0.34 and sin(alien.hop*1.5)*6*scale or 0
   kind_colours(alien)
   if alien.flash>0 then
    for colour=1,15 do pal(colour,7) end
   end
   sspr(alien.sprite+(alien.hop<0.34 and 16 or 0),0,16,16,x-size/2,y-size+lift,size,size)
   pal()
  end
 end
end
