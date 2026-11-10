function send_alien(lane,beat,kind)
 kind=kind or kinds[1]
 local dir=lane<0 and 1 or -1
 add(aliens,setmetatable({lane=lane,first=lane,pos=lane,start=-2.125*dir,dir=dir,born=beat,hp=kind.bars*8,flash=0,t=-1,knock=0},kind))
end

function update_aliens()
 for alien in all(aliens) do
  local push=alien.knock/4
  alien.born+=push
  alien.knock-=push
  local beats=clock-alien.born
  alien.hop=beats%1
  alien.flash=max(alien.flash-1)
  if alien.track then
   alien.t,alien.pos=alien.depth,alien.start+alien.dir*beats/alien.track
  else
   local step=beats-surge*sin(beats)
   alien.t=(step-1)/alien.walk
   if alien.weave then
    alien.pos=-cos((step/alien.weave+alien.first+1)/4)
   end
  end
  alien.lane=flr(alien.pos+0.5)
  if alien.t>=1 or alien.pos*alien.dir>1.6 then
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
  if alien.t>-0.05 and (alien.lane==lane or alien.track and abs(alien.pos-lane)<straddle) then front=alien end
 end
 return front
end

function hit_alien(alien,amount,judgement)
 alien.flash=3
 if alien.penalty then
  score=max(score-alien.penalty)
  combo=0
  award("civilians")
  local x,y=alien_centre(alien)
  popup("hey! -"..alien.penalty.."0",x,y-10,8)
  sfx(4)
  return
 end
 alien.hp-=amount
 if not alien.track then alien.knock+=amount*knock_per_damage*judgement.knock end
 local x,y,scale=alien_centre(alien)
 burst(x,y,4,judgement.colour,2)
 if alien.hp<0.01 then
  del(aliens,alien)
  burst(x,y,12,alien.body,2)
  shake+=2
  sfx(3)
  if alien.bonus>0 then
   award("golds")
   score+=alien.bonus
   popup("+"..alien.bonus.."0",x,y-8,alien.body)
   ring(x,y,16,alien.body)
  else
   award("kills",alien.bars*2)
  end
  local foot_x,foot_y=project(alien.pos,alien.t)
  add(fallen,{x=foot_x,y=foot_y,size=24*scale,age=0,kind=getmetatable(alien)})
 end
end

function kind_colours(kind,dark)
 pal(11,dark and kind.rim or kind.body)
 pal(3,kind.rim)
end

function swarm_sprite(size,sizes)
 sizes=sizes or swarm_sprites
 local best=sizes[1]
 for entry in all(sizes) do
  if entry[1]<=size then best=entry end
 end
 return unpack(best)
end

function draw_fallen()
 for body in all(fallen) do
  body.age+=1
  local size,sx,sy=swarm_sprite(body.size)
  local height=size*max(0.15,1-body.age/5)
  kind_colours(body.kind,body.age>4)
  sspr(sx,sy,size,size,body.x-size/2,body.y-height,size,height)
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
   local lift=(cos(alien.hop)-1)*2*scale
   kind_colours(alien)
   if alien.flash>0 then
    for colour=1,15 do pal(colour,7) end
   end
   local frame=alien.hop<0.5 and 1 or 0
   if alien.sprite>0 then
    local width,sx,sy=swarm_sprite(size,civilian_sprites)
    sspr(sx,sy,width,width,x-width/2,y-width-frame,width,width)
   else
    local width,sx,sy=swarm_sprite(size)
    sspr(sx+frame*width,sy,width,width,x-width/2,y-width+lift,width,width)
   end
   pal()
  end
 end
end
